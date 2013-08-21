itcl::class Dim {
    private variable x ""; # name of the x dimension
    private variable y ""; # name of the y dimension
    private variable x_entry {};
    private variable y_entry {};
    private variable wWidth 4; # visible window width
    private variable wHeight 4;
    private variable wRow 0;
    private variable wCol 0;
    private variable grid; # grid data structure
    private variable gridWidth 0;
    private variable gridHeight 0;
    private variable sc {}; # selection cursor: {line_of_grid column_of_grid}
    private variable t {}; #toplevel
    private variable f {}; # frame
    private variable g {}; # grid frame
    private variable objects; # visible objects
    private variable scDim {}
    private variable scDimXCursor 0
    private variable scDimYCursor 0
    private variable busy 0
    private variable numModifier ""
    private variable container ""
    private variable onMoveCursor ""
    private variable history {}
    private variable historyIndex 0
    private variable dimMenu ""
    private variable btnMenu ""

    constructor {} {}


    ##################
    # PUBLIC METHODS #
    ##################

    public method setX {dim} { set x $dim }
    public method getX {} { set x }
    public method setY {dim} { set y $dim }
    public method getY {} { set y }

    public method updateEntries {} {
        $x_entry blank
        $x_entry pushText $x
        $y_entry blank
        $y_entry pushText $y
    }

    public method buildAndGrid {id} {
        buildBoard $id
        mkGrid
    }

    public method scRight {} {
        if {! $busy} {
            scHoriz [getNumModifier]
            initNumModifier
        }
    }

    public method scLeft {} {
        if {! $busy} {
            scHoriz -[getNumModifier]
            initNumModifier
        }
    }

    public method scDown {} {
        if {! $busy} {
            scVertic [getNumModifier]
            initNumModifier
        }
    }

    public method scUp {} {
        if {! $busy} {
            scVertic -[getNumModifier]
            initNumModifier
        }
    }

    public method query {} {
        set xEntryValue [$x_entry getValue]
        set yEntryValue [$y_entry getValue]
        if {[regexp {^q\..*} $xEntryValue] || [regexp {^q\..*} $yEntryValue]} {
            blank
        }
        setX $xEntryValue
        setY $yEntryValue
        updateEntries
        ::dinah::dbNewDim $x
        ::dinah::dbNewDim $y
        buildAndGrid [scId]
    }

    public method scId {} { return [id [scCell]] }

    public method setWWidth {nbColumns} {
        if {$nbColumns > 0} {
            set wWidth $nbColumns
        }
    }

    public method setWHeight {nbRows} {
        if {$nbRows > 0} {
            set wHeight $nbRows
        }
    }

    public method getFocus {} { focus $t }

    public method showBtnMenu {} {
        tk_popup $dimMenu [winfo rootx $btnMenu] [winfo rooty $btnMenu]
    }

    public method gotoRowEnd {} { gotoRowEnds "end" }

    public method gotoRowStart {} { gotoRowEnds 0 }

    public method wHorizByOneScreen {{direction 1}} {
        if { $busy } { return }
        if {[wHoriz [expr {$direction * $wWidth}]]} {
            set sc [list [scRowIndex] $wCol]
            [$objects($sc) cget -frame] configure -borderwidth $::dinah::fragmentBorderWidth -bg red
            updateInfo
        }
    }

    public method incrWWidth {i} {
        setWWidth [expr {$wWidth + $i}]
        mkGrid
    }

    public method incrWHeight {i} {
        setWHeight [expr {$wHeight + $i}]
        mkGrid
    }

    public method clickBtnX {} {
        switchScDimsX
        addToHistory
    }

    public method clickBtnY {} {
        switchScDimsY
        addToHistory
    }

    public method clickBtnOK {} {
        query
        addToHistory
    }

    public method prevHistory {} {
        if {$historyIndex != 0} {
            incr historyIndex -1
            gotoHistory $historyIndex
        }
    }

    public method nextHistory {} {
        if {  ([llength $history] > 0) &&
              ($historyIndex != [expr {[llength $history] - 1}])  } {
            incr historyIndex
            gotoHistory $historyIndex
        }
    }

    public method blank {} {
        set sc {}
        setX "d.nil"
        setY "d.nil"
        updateEntries
        setWWidth 4
        setWHeight 4
        query
    }

    public method swapDim {} {
        set oldY $y
        setY $x
        setX $oldY
        updateEntries
        buildAndGrid [scId]
    }

    public method nextList {{direction 1}} {
        if {![scRowEmpty]} {
            buildAndGrid [::dinah::dbLGet $x [list [expr {([scDimIndex] + $direction) % [llength [::dinah::dbGet $x]]}] 0]]
        }
    }

    public method msgGoto {} {
        global gotoEntryValue
        toplevel .tGoto
        label .tGoto.msg -text "Rejoindre la page :"
        entry .tGoto.e -textvariable gotoEntryValue -borderwidth 3 -width 50
        button .tGoto.ok -text "OK" -command [list $this msgGotoOK]
        pack .tGoto.msg -expand 1 -fill x
        pack .tGoto.e -fill x
        pack .tGoto.ok -fill x
        focus -force .tGoto.e
    }

    public method msgGotoOK {} {
        global gotoEntryValue
        goto $gotoEntryValue
        destroy .tGoto
    }

    public method new {type {delta 1}} {
        if { [::dinah::editable $x] } {
            if { !( $sc eq {} ) } {
                set dbid [scId]
                set newX {}
                set newId [::dinah::dbNewEmptyNode $type]
                set found 0
                foreach l [::dinah::dbGet $x] {
                    set i [lsearch $l $dbid]
                    if {$i > -1} {
                        lappend newX [linsert $l [expr {$i + $delta}] $newId]
                        set found 1
                    } else {
                        lappend newX $l
                    }
                }
                if {! $found} {
                    lappend newX [linsert [list $dbid] $delta $newId]
                }
                ::dinah::dbSetDim $x $newX
            } else {
                set newId [::dinah::dbNewEmptyNode $type]
                ::dinah::dbAppendSegmentToDim $x [list $newId]
            }
            buildAndGrid $newId
        }
    }

    public method copySegmentToClipboard {} {
        ::dinah::dbClearClipboard
        ::dinah::dbAppendSegmentToDim $::dinah::dimClipboard [::dinah::dbLGet $x [scDimIndex]]
    }

    public method pasteClipboard {} {
        if {[::dinah::editable $x]} {
            set row {}
            foreach frag [::dinah::dbGetSegment $::dinah::dimClipboard 0] {
                if {![::dinah::dbNodeBelongsToDim $x $frag]} {
                    lappend row $frag
                } else {
                    return 0
                }
            }
            if {$row != {}} {
                ::dinah::dbAppendSegmentToDim $x $row
                buildAndGrid [lindex $row 0]
                return 1
            } else {
                return 0
            }
        }
    }

    public method deleteRow {} {
        if {[::dinah::editable $x] && [scRow] != {}} {
            set cursor [scId]
            ::dinah::dbRemoveSegment $x [scDimIndex]
            buildAndGrid $cursor
        }
    }

    public method updateInfo {} {
        set path ""
        if {[::dinah::dbExists [scId],path]} {
            set path [::dinah::dbGet [scId],path]
        }
        $f.menu.label configure -textvariable ::dinah::db([scId],label)
        set scId [scId]
        #set modeLabel [lindex $modes(names) $modes(current)]
        wm title [winfo toplevel $t] "x: $x ; y: $y ; id: $scId ; wWidth: $wWidth ; wHeight: $wHeight ; $path"
        scDim
        eval $onMoveCursor
    }

    public method dropmenu {target src xcoord ycoord op type data} {
        set srcId [lindex $data end]
        set found [::dinah::dbFindInDim $x $srcId]
        if {[::dinah::dbNodeBelongsToDim $x $srcId]} {
            buildAndGrid $srcId
        } elseif {[::dinah::dbAppendSegmentToDim $x [list $srcId]]} {
            buildAndGrid $srcId
        }
    }

    public method copy {} {
        ::dinah::dbClearClipboard
        ::dinah::dbAppendSegmentToDim $::dinah::dimClipboard [list [scId]]
    }

    public method copycat {} {
        set l [::dinah::dbLGet $::dinah::dimClipboard 0]
        lappend l [scId]
        ::dinah::dbSetDim $::dinah::dimClipboard [list $l]
    }

    public method pasteBefore {} {
        if {[::dinah::editable $x]} {
            if {[newRow?]} {
                newRowFromPasteBefore
                buildAndGrid [scId]
            } elseif {[noCycleOrDuplicate]} {
                set newScRow [linsert [scRow] [scItemIndex] [::dinah::dbClipboardLastItem]]
                ::dinah::dbReplaceSegment $x [scDimIndex] $newScRow
                buildAndGrid [scId]
            }
        }
    }

    public method pasteAfter {} {
        if {[::dinah::editable $x]} {
            if {[newRow?]} {
                newRowFromPasteAfter
                buildAndGrid [scId]
            } elseif {[noCycleOrDuplicate]} {
                if {[scOnLastItem]} {
                    set newItemIndex end
                } else {
                    set newItemIndex [expr {[scItemIndex] + 1}]
                }
                set newScRow [linsert [scRow] $newItemIndex [::dinah::dbClipboardLastItem]]
                ::dinah::dbReplaceSegment $x [scDimIndex] $newScRow
                buildAndGrid [scId]
            }
        }
    }

    public method method cut {} {copycat; delete}

    public method delete {} {
        set scRow [scRow]
        if {[::dinah::editable $x] && [scRow] != {}} {
            if {[llength [scRow]] == 1} {
                set newScId {}
                ::dinah::dbRemoveSegment $x [scDimIndex]
            } else {
                if {[scOnLastItem]} {
                    set newScId [lindex [scRow] end-1]
                } else {
                    set newScId [lindex [scRow] [expr {[scItemIndex] + 1}]]
                }
                set newScRow [lreplace [scRow] [scItemIndex] [scItemIndex]]
                ::dinah::dbReplaceSegment $x [scDimIndex] $newScRow
            }
            buildAndGrid $newScId
        }
    }

    public method updateNumModifier {k} {
        set numModifier [join [list $numModifier $k] ""]
    }

    # only used by Txt click method. Should do it another way.
    public method getTopFrame {} {
        return $t
    }

    public method setContainer {c} {
        set container $c
    }

    public method getContainer {} {
        return $container
    }

    public method mkWindow {{parent {}}} {
        if {$parent == {}} {
            set t [::dinah::newToplevel .t[::dinah::objname $this]]
        } else {
            set t $parent
        }
        set f [frame $t.frame -borderwidth 1 -bg black -highlightcolor green -highlightthickness 1]
        frame $f.menu

        set btnMenu [button $f.menu.btnMenu -text "M" -command [list $this showBtnMenu]]
        set btnBegin [button $f.menu.btnBegin -text "|" -command [list $this gotoRowStart]]
        set btnLeftLeft [button $f.menu.btnLeftLeft -text "<<" -command [list $this wHorizByOneScreen -1]]
        set btnLeft [button $f.menu.btnLeft -text "<" -command [list $this scLeft]]
        set btnDown [button $f.menu.btnDown -text "v" -command [list $this scDown]]
        set btnUp [button $f.menu.btnUp -text "^" -command [list $this scUp]]
        set btnRight [button $f.menu.btnRight -text ">" -command [list $this scRight]]
        set btnRightRight [button $f.menu.btnRightRight -text ">>" -command [list $this wHorizByOneScreen 1]]
        set btnEnd [button $f.menu.btnEnd -text "|" -command [list $this gotoRowEnd]]
        set btnExtendX [button $f.menu.btnExtendX -text "+X" -command [list $this incrWWidth 1]]
        set btnReduceX [button $f.menu.btnReduceX -text "-X" -command [list $this incrWWidth -1]]
        set btnExtendY [button $f.menu.btnExtendY -text "+Y" -command [list $this incrWHeight 1]]
        set btnReduceY [button $f.menu.btnReduceY -text "-Y" -command [list $this incrWHeight -1]]
        set btnX [button $f.menu.btnX -text "X:" -command [list $this clickBtnX]]
        set x_entry [::dinah::Autocomplete x_entry#auto $f.menu.x_entry [::dinah::dbGet dimensions]]
        set btnY [button $f.menu.btnY -text "Y:" -command [list $this clickBtnY]]
        set y_entry [::dinah::Autocomplete y_entry#auto $f.menu.y_entry [::dinah::dbGet dimensions]]
        button $f.menu.ok -text "OK" -command [list $this clickBtnOK]
        button $f.menu.prevHistory -text "<-" -command [list $this prevHistory]
        button $f.menu.nextHistory -text "->" -command [list $this nextHistory]
        entry $f.menu.label
        bindtags $f.menu.label [list $f.menu.label [winfo class $f.menu.label] all]
        bind $f.menu.label <Key-Escape> [list focus $t]
        pack $btnMenu -side left -padx 4 -pady 4
        pack $btnBegin -side left -padx 4 -pady 4
        pack $btnLeftLeft -side left -padx 4 -pady 4
        pack $btnLeft -side left -padx 4 -pady 4
        pack $btnDown -side left -padx 4 -pady 4
        pack $btnUp -side left -padx 4 -pady 4
        pack $btnRight -side left -padx 4 -pady 4
        pack $btnRightRight -side left -padx 4 -pady 4
        pack $btnEnd -side left -padx 4 -pady 4
        pack $btnExtendX -side left -padx 4 -pady 4
        pack $btnReduceX -side left -padx 4 -pady 4
        pack $btnExtendY -side left -padx 4 -pady 4
        pack $btnReduceY -side left -padx 4 -pady 4
        pack $btnX -side left -padx 4 -pady 4
        pack $f.menu.x_entry -side left -padx 4 -pady 4
        pack $btnY -side left -padx 4 -pady 4
        pack $f.menu.y_entry -side left -padx 4 -pady 4
        pack $f.menu.ok -side left -padx 4 -pady 4
        pack $f.menu.prevHistory -side left -padx 4 -pady 4
        pack $f.menu.nextHistory -side left -padx 4 -pady 4
        pack $f.menu.label -side left -padx 4 -pady 4
        pack $f.menu -side top -fill x
        set g [frame $f.grid -bg $::dinah::backgroundColor]
        pack $g -side top -fill both -expand yes

        set dimMenu [menu $f.dimMenu]
        $dimMenu add command -label "clear view (b)" -command [list $this blank]
        $dimMenu add command -label "swap dim (s)" -command [list $this swapDim]
        $dimMenu add command -label "next segment (o)" -command [list $this nextList 1]
        $dimMenu add command -label "prev segment (O)" -command [list $this nextList -1]
        $dimMenu add command -label "goto label" -command [list $this msgGoto]
        $dimMenu add command -label "new Txt (n)" -command [list $this new Txt]
        $dimMenu add command -label "segment -> clipboard" -command [list $this copySegmentToClipboard]
        $dimMenu add command -label "paste clipboard" -command [list $this pasteClipboard]
        $dimMenu add command -label "delete segment" -command [list $this deleteRow]
        bind $f.menu $::dinah::mouse(B3) [list tk_popup $dimMenu %X %Y]
        bind $f.menu <1> [list focus $t]
        bind $f.menu <1> +[list $this updateInfo]

        DropSite::register $f.menu -dropcmd [list $this dropmenu] -droptypes {Obj copy}

        initGrid

        setBindings

        focus $t
        pack $f -side top -fill both -expand yes
        return $t
    }

    # used by Obj for adding a menu to an object when visible in a dim view and
    # appearing on multiple dims. With this menu, a user selects a dim on which the object appears,
    # and this dim will be set as the current y-dim for the dim container.
    public method setYAndUpdate {yDim} {
        setY $yDim
        updateEntries
        buildAndGrid [scId]
    }

    public method forEachObject {msg} {
        foreach {xy o} [array get objects] {
            catch {$o {*}$msg}
        }
    }

    public method reload {} { buildAndGrid [scId] }

    ###################
    # PRIVATE METHODS #
    ###################

    private method addToHistory {} {
        if {([llength $history] > 0) && ($historyIndex != [expr {[llength $history] - 1}])} {
            set history [lrange $history 0 $historyIndex]
            set historyIndex [expr {[llength $history] - 1}]
        }
        set lastStep [lindex $history end]
        if { ([lindex $lastStep 0] ne [scId]) ||
             ([lindex $lastStep 1] ne [getX]) ||
             ([lindex $lastStep 2] ne [getY]) } {
            lappend history [list [scId] [getX] [getY]]
            incr historyIndex
        }
    }

    private method gotoHistory {index} {
        setX [lindex [lindex $history $index] 1]
        setY [lindex [lindex $history $index] 2]
        updateEntries
        buildAndGrid [lindex [lindex $history $index] 0]
    }

    private method setOnMoveCursor {code} {
        set onMoveCursor $code
    }

    private method gotoRowEnds {where} {
        set r [scRow]
        if {$r != {}} {
            buildAndGrid [lindex $r $where]
        }
    }

    private method initNumModifier {} {
        set numModifier ""
    }

    private method getNumModifier {} {
        if {$numModifier eq ""} {return "1"}
        return $numModifier
    }

    private method setBindings {} {
        if {[info exists objects($sc)]} {
            [$objects($sc) cget -frame] configure -borderwidth $::dinah::fragmentBorderWidth -bg red
        }

        bind $t <Key-g> [list $this msgGoto]
        bind $t <Key-Right> [list $this scRight]
        bind $t <Key-Left> [list $this scLeft]
        bind $t <Key-Down> [list $this scDown]
        bind $t <Key-Up> [list $this scUp]
        bind $t <Shift-Key-Right> [list $this wHorizByOneScreen 1]
        bind $t <Shift-Key-Left> [list $this wHorizByOneScreen -1]
        bind $t <Return> [list $this query]
        bind $t <Key-n> [list $this new Txt]
        bind $t <Control-Key-C> [list $this copy]
        bind $t <Control-Key-c> [list $this copycat]
        bind $t <Control-Key-V> [list $this pasteBefore]
        bind $t <Control-Key-v> [list $this pasteAfter]
        bind $t <Control-Key-x> [list $this cut]
        bind $t <Control-Key-d> [list $this delete]
        bind $t <Key-s> [list $this swapDim]
        bind $t <Key-o> [list $this nextList 1]
        bind $t <Key-O> [list $this nextList -1]
        bind $t <Control-Key-b> [list $this blank]
        foreach k {0 1 2 3 4 5 6 7 8 9} {
            bind $t <Key-$k> [list $this updateNumModifier $k]
        }
    }

    private method scDim {} {
        set scDim {}
        set id [scId]
        set found 0
        if {$id ne {}} {
            foreach d [::dinah::dbGet dimensions] {
                foreach l [::dinah::dbGet $d] {
                    foreach i $l {
                        if {$id eq $i} {
                            lappend scDim $d
                            set found 1
                            break
                        }
                    }
                    if {$found} {set found 0; break}
                }
            }
        }
    }

    private method switchScDimsX {} {
        set scDimLength [llength $scDim]
        if {$scDimLength > 0} {
            setX [lindex $scDim [expr {$scDimXCursor % $scDimLength}]]
            updateEntries
            incr scDimXCursor
            buildAndGrid [scId]
        }
    }

    private method switchScDimsY {} {
        set scDimLength [llength $scDim]
        if {$scDimLength > 0} {
            setY [lindex $scDim [expr {$scDimYCursor % $scDimLength}]]
            updateEntries
            incr scDimYCursor
            buildAndGrid [scId]
        }
    }

    private method initGrid {} {
        grid rowconfigure $g all -uniform {} -weight 0
        grid columnconfigure $g all -uniform {} -weight 0
        foreach slave [grid slaves $g] { grid forget $slave ; destroy $slave }
        foreach {pos o} [array get objects] { itcl::delete object $o }
    }

    private method setWRow {i} { set wRow $i }

    private method setWCol {j} { set wCol $j }

    private method wHoriz {i} {
        if {(($wCol + $i) >= 0) && (($wCol + $i) < $gridWidth)} {
            incr wCol $i
            mkGrid
            return 1
        }
        return 0
    }

    private method wRight {} { wHoriz 1 }

    private method wLeft {} { wHoriz -1 }

    private method wVertic {i} {
        if {(($wRow + $i) >= 0) && (($wRow + $i) < $gridHeight)} {
            incr wRow $i
            mkGrid
        }
    }

    private method wDown {} { wVertic 1 }

    private method wUp {} { wVertic -1 }

    private method scRowIndex {} {
        if {[llength $sc] == 2} {
            return [lindex $sc 0]
        } else {
            return {}
        }
    }

    private method scColumnIndex {} {
        if {[llength $sc] == 2} {
            return [lindex $sc 1]
        } else {
            return {}
        }
    }

    private method goto {match} {
        set row [::dinah::dbLGet [scDimName] [scDimIndex]]
        for {set i 0} {$i < [llength $row]} {incr i} {
            if {[string match -nocase *$match* [::dinah::dbGet [lindex $row $i],label]]} {
                scHoriz [expr {$i - [scColumnIndex]}]
                return
            }
        }
    }

    private method scHoriz {i} {
        if {![insideW [scRowIndex] [scColumnIndex]]} {return}
        set newScCol [expr {[scColumnIndex] + $i}]
        set exist [info exists grid([scRowIndex],$newScCol)]
        if {$exist && !( [cell [scRowIndex] $newScCol] eq {} )} {
            set row [scRowIndex]
            set col $newScCol
            set oldSc $sc
            set sc [list $row $col] 
            if {! [insideW $row $col]} {
                wHoriz $i
            } else {
                [$objects($oldSc) cget -frame] configure -borderwidth 0
                [$objects($sc) cget -frame] configure -borderwidth $::dinah::fragmentBorderWidth -bg red
            }
            updateInfo
            addToHistory
            set scDimXCursor 0
            set scDimYCursor 0
        }
    }

    private method scVertic {i} {
        if {![insideW [scRowIndex] [scColumnIndex]]} {return}
        set newScRow [expr {[scRowIndex] + $i}]
        set exist [info exists grid($newScRow,[scColumnIndex])]
        if {$exist && !( [cell $newScRow [scColumnIndex]] eq {} )} {
            buildAndGrid [id [cell $newScRow [scColumnIndex]]]
            mkGrid
            addToHistory
            set scDimXCursor 0
            set scDimYCursor 0
        }
    }

    private method buildBoard {{center {}}} {
        set mainRow {}
        set mainRowIndex {}
        set cols {}
        array unset grid
        array set grid {}
        set sc {}
        if {[::dinah::dbExists $x]} {
            if {$center eq {}} {
                set center [::dinah::dbLGet $x {0 0}]
            }
            if {$center eq {}} {
                return
            }
            # main row:
            set found [::dinah::dbFindInDim $x $center]
            if {[llength $found] != 0} {
                set segIndex [lindex $found 0]
                set fragIndex [lindex $found 1]
                set seg [::dinah::dbGetSegment $x $segIndex]
                set mainRowIndex $segIndex
                set mainRow $seg
                set sc [list $fragIndex]
            }
            set gridWidth [llength $mainRow]
            # cols:
            if {[::dinah::dbExists $y]} {
                if {$mainRow eq {}} {
                    set found [::dinah::dbFindInDim $y $center]
                    if {[llength $found] != 0} {
                        set segIndex [lindex $found 0]
                        set fragIndex [lindex $found 1]
                        set seg [::dinah::dbGetSegment $y $segIndex]
                        set segLength [llength $seg]
                        for {set k 0} {$k < $segLength} {incr k} {
                            set grid($k,0) [list $y $segIndex $k]
                        }
                        set sc [list $fragIndex 0]
                        set gridWidth 1
                        set gridHeight $segLength
                        setWRow [lindex $sc 0]
                        setWCol [lindex $sc 1]
                        return
                    }
                    set sc {0 0}
                    set gridWidth 1
                    set gridHeight 1
                    set grid(0,0) $center
                    setWRow 0
                    setWCol 0
                    return
                } else {
                    foreach k $mainRow {
                        set j -1
                        set found [::dinah::dbFindInDim $y $k]
                        if {[llength $found] != 0} {
                            set segIndex [lindex $found 0]
                            set fragIndex [lindex $found 1]
                            set seg [::dinah::dbGetSegment $y $segIndex]
                            lappend cols [list $seg $segIndex $fragIndex]
                        } else {
                            lappend cols {}
                        }
                    }
                }
            }

            # complete columns with bottom distances:
            # for a given column, top    is the number of objects above the main row
            # for a given column, bottom is the number of objects below the main row
            # for a given column, fragIndex (i.e. [lindex $col 2]) is the value of top
            # maxTop and maxBottom are used to compute the necessary height of the grid
            set maxTop 0;    # will store the biggest top distance
            set maxBottom 0; # will store the biggest bottom distance
            set newCols {}
            foreach col $cols {
                if {! ($col eq {})} {
                    set top [lindex $col 2]
                    set maxTop [expr {max($maxTop,$top)}]
                    set bottom [expr {[llength [lindex $col 0]] - $top - 1}]
                    set maxBottom [expr {max($maxBottom,$bottom)}]
                    lappend newCols [linsert $col end $bottom]
                } else {
                    lappend newCols {}
                }
            }
            set gridHeight [expr {$maxBottom + $maxTop + 1}]
            set sc [linsert $sc 0 $maxTop]
            set cols $newCols

            # grid:
            for {set i 0} {$i < [llength $mainRow]} {incr i} {
                set grid($maxTop,$i) [list $x $mainRowIndex $i]
            }
            for {set i 0} {$i < [llength $cols]} {incr i} {
                if {[lindex $cols $i] eq {}} {
                    for {set j 0} {$j < $maxTop} {incr j} {
                        set grid($j,$i) {}
                    }
                    for {set j 0} {$j < $maxBottom} {incr j} {
                        set grid([expr {$maxTop + 1 + $j}],$i) {}
                    }
                } else {
                    set top [lindex $cols $i 2]
                    set bottom [lindex $cols $i 3]
                    set deltaTop [expr {$maxTop - $top}]
                    set deltaBottom [expr {$maxBottom - $bottom}]
                    for {set j 0} {$j < $deltaTop} {incr j} {
                        set grid($j,$i) {}
                    }
                    for {set j 0} {$j < $top} {incr j} {
                        set grid([expr {$j + $deltaTop}],$i) [list $y [lindex $cols $i 1] $j]
                    }
                    for {set j 0} {$j < $bottom} {incr j} {
                        set grid([expr {$maxTop + 1 + $j}],$i) [list $y [lindex $cols $i 1] [expr {$top + 1 + $j}]]
                    }
                    for {set j 0} {$j < $deltaBottom} {incr j} {
                        set grid([expr {$maxTop + 1 + $bottom + $j}],$i) {}
                    }
                }
            }
        } else {
            set sc {0 0}
        }
        setWRow [lindex $sc 0]
        setWCol  [lindex $sc 1]
    }

    private method focusLeft {} {
        set left $wCol
        set right [expr {$gridWidth - ($left + $wWidth)}]
        if {$right < 0} {
            if {($left + $right) < 0} {
                incr wCol [expr {- $left}]
            } else {
                incr wCol $right
            }
        }
    }

    private method focusUp {} {
        set down [expr {$gridHeight - ($wRow + $wHeight)}] 
        if {$down < 0} {
            set top 0
            for {set i [expr {$wRow - 1}]} {$i >= 0} {incr i -1} {
                for {set j $wCol} {$j < ($wCol + $wWidth)} {incr j} {
                    if {! ([cell $i $j] eq {})} {
                        set top [expr {$wRow - $i}]
                        break
                    }
                }
            }
            if {($top + $down) < 0} {
                incr wRow [expr {- $top}]
            } else {
                incr wRow $down
            }
        }
    }

    private method optimizeScreenSpace {} { focusLeft; focusUp }

    private method mkGrid {} {
        set busy 1
        initGrid
        array unset objects
        array set pos {}

        optimizeScreenSpace
        set lastScreenRow 0
        set lastScreenCol 0
        array set id2obj {}
        set twoVertic [expr {(($wHeight == 2) && ($wWidth == 1)) ? 1 : 0}]
        set twoHoriz [expr {(($wHeight == 1) && ($wWidth == 2)) ? 1 : 0}]
        set usePanedwin 1
        if {$twoVertic} {
            set panedwin [panedwindow $g.pan -orient vertical -handlesize 10 -showhandle 1]
        } elseif {$twoHoriz} {
            set panedwin [panedwindow $g.pan -orient horizontal -handlesize 10 -showhandle 1]
        } else {
            set usePanedwin 0
        }
        for {set i 0} {$i < $wHeight} {incr i} {
            set nbCols 0
            for {set j 0} {$j < $wWidth} {incr j} {
                set absoluteI [expr {$wRow + $i}]
                set absoluteJ [expr {$wCol + $j}]
                set absolutePos [list $absoluteI $absoluteJ]
                set objId [id [cell $absoluteI $absoluteJ]]
                if {! ($objId eq {})} {
                    if {$usePanedwin} {
                        set o [::dinah::mkObj $objId $panedwin]
                    } else {
                        set o [::dinah::mkObj $objId $g]
                    }
                    lappend id2obj($objId) $o
                    $o configure -container $this
                    set objects($absolutePos) $o
                    set w [$o cget -frame]
                    set pos($w) $absolutePos
                    $o openNS
                    if {[scRowIndex] == $absoluteI} {
                        $o openEW
                        if {[scColumnIndex] == $absoluteJ} {
                            $w configure -borderwidth $::dinah::fragmentBorderWidth -bg red
                        }
                    } else {
                        $o closeEW
                    }
                    if {$usePanedwin} {
                        $panedwin add $w -stretch always
                    } else {
                        grid $w -column $j -row $i -sticky news
                    }
                    incr nbCols
                    set lastScreenRow $i
                }
            }
            set lastScreenCol [expr {max($lastScreenCol,$nbCols)}]
        }
        foreach {id objs} [array get id2obj] {
            if {[llength $objs] > 1} {
                set color [::dinah::randomColor]
                foreach o $objs {$o setMenuColor $color}
            }
        }
        if {$usePanedwin} {
            grid $panedwin -sticky news
        }
        grid rowconfigure $g all -uniform 1 -weight 1
        grid columnconfigure $g all -uniform 1 -weight 1
        updateInfo
        update

        foreach {xy o} [array get objects] {
            $o z
        }

        if {$twoVertic} {

        } elseif {$twoHoriz} {

        } elseif {[scRowIndex] ne {} && [insideW [scRowIndex] $wCol]} {
            set mainRowPathnames [lreverse [grid slaves $g -row [expr {[scRowIndex]-$wRow}]]]
            set leftMostPathname [lindex $mainRowPathnames 0]
            set firstVisibleCol [expr {[lindex $pos($leftMostPathname) 1] + 1}]
            for {set i 0} {$i < [llength $mainRowPathnames]} {incr i} {
                $objects($pos([lindex $mainRowPathnames $i])) notificate [concat "row :" [expr {$firstVisibleCol + $i}] "/$gridWidth ; "] 
            }
            for {set j 0} {$j < $wWidth} {incr j} {
                set absoluteJ [expr {$wCol + $j}]
                set col {}
                foreach {k v} [array get grid *,$absoluteJ] {
                    if {$v ne {}} {lappend col [regsub {,.*$} $k ""]}
                }
                set col [lsort -integer $col]
                set colHeight [llength $col]
                if {$colHeight > 1} {
                    set colPathnames [lreverse [grid slaves $g -col $j]]
                    set firstVisibleRow [expr {[lsearch -exact $col [lindex $pos([lindex $colPathnames 0]) 0]] + 1}]
                    for {set i 0} {$i < [llength $colPathnames]} {incr i} {
                        $objects($pos([lindex $colPathnames $i])) notificate [concat "col :" [expr {$firstVisibleRow + $i}] "/$colHeight ; "]
                    }
                }
            }
        }
        focus $t
        set busy 0
    }

    private method z {} {
        foreach {pos o} [array get objects] {
            $o z
        }
    }

    private method cell {rowIndex columnIndex} {
        if {[info exists grid($rowIndex,$columnIndex)]} {
            return $grid($rowIndex,$columnIndex)
        } else {
            return {}
        }
    }

    private method id {cell} {
        if {! ($cell eq {})} {
            if {[llength $cell] == 3} {
                return [::dinah::dbLGet [lindex $cell 0] [list [lindex $cell 1] [lindex $cell 2]]]
            } else {
                return $cell; # the grid has only one cell which is not on the x and y dimensions
            }
        }
        return {}
    }

    private method insideW {row col} {
        return [expr {( ( $wCol  <= $col  ) && ( $col  < ($wCol + $wWidth)   ) ) &&
                      ( ( $wRow <= $row ) && ( $row < ($wRow + $wHeight) ) )}]
    }

    private method scCell {} { return [cell [scRowIndex] [scColumnIndex]] }
    private method scDimName {} { return [lindex [scCell] 0] }
    private method scDimIndex {} { return [lindex [scCell] 1] }
    private method scItemIndex {} { return [lindex [scCell] 2] }

    # if """[scDimName] ne $x""" it means that [scDimName] comes from the vertical/Y dim
    # therefore in that case the selection cursor row is empty.
    private method scRowEmpty {} { return [expr {([llength [scCell]] != 3) || ([scDimName] ne $x)}] }

    private method scRow {} {
        if {! [scRowEmpty]} {
            return [::dinah::dbLGet $x [scDimIndex]]
        } else {
            return {}
        }
    }

    private method scOnLastItem {} {
        return [expr {[scItemIndex] == ([llength [scRow]] - 1)}]
    }

    private method newRow? {} { return [expr {(! [dimIsNil]) && (! [::dinah::dbClipboardEmpty]) && [scRowEmpty]}] }

    private method noCycleOrDuplicate {} {
        return [expr {(! [dimIsNil]) && (! [::dinah::dbClipboardEmpty]) && (! [scRowEmpty]) && (! [pastingCycle]) && (! [pastingDuplicate])}]
    }

    private method pastingCycle {} {
        if {[::dinah::dbClipboardLastItem] in [scRow]} {
            return 1
        } else {
            return 0
        }
    }

    private method pastingDuplicate {} {
        set scDimLength [llength [::dinah::dbGet [scDimName]]]
        for {set i 0} {$i < $scDimLength} {incr i} {
            if {$i != [scDimIndex]} {
                if {[::dinah::dbClipboardLastItem] in [::dinah::dbLGet [scDimName] $i]} {
                    # item appearing twice in a dimension
                    return 1
                }
            }
        }
        return 0
    }

    private method dimIsNil {} {
        if {$x eq "d.nil"} {
            return 1
        } else {
            return 0
        }
    }

    private method pasteIntoNewList {} {
        if {(! [dimIsNil]) && (! [::dinah::dbClipboardEmpty])} {
            ::dinah::dbAppendSegmentToDim $x [list [::dinah::dbClipboardLastItem]]
            buildAndGrid [::dinah::dbClipboardLastItem]
        }
    }

    private method newListWithTxtNode {} {
        if {! [dimIsNil]} {
            set txtId [::dinah::dbNewEmptyNode Txt]
            ::dinah::dbAppendSegmentToDim $x [list $txtId]
            buildAndGrid $txtId
        }
    }

    private method newRowFromPasteBefore {} {
        if {![::dinah::dbNodeBelongsToDim $x [::dinah::dbClipboardLastItem]} {
            set newSegment [::dinah::removeEmptyFromList [list [::dinah::dbClipboardLastItem] [scId]]]
            ::dinah::dbAppendSegmentToDim $x $newSegment
        }
    }

    private method newRowFromPasteAfter {} {
        if {![::dinah::dbNodeBelongsToDim $x [::dinah::dbClipboardLastItem]} {
            set newSegment [::dinah::removeEmptyFromList [list [scId] [::dinah::dbClipboardLastItem]]]
            ::dinah::dbAppendSegmentToDim $x $newSegment
        }
    }
}
