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

    public method setX {dim} {
        if {[::dinah::dbExists $dim]} {
            set x $dim
            return 1
        } else {
            return 0
        }
    }
    public method getX {} { set x }
    public method setY {dim} {
        if {[::dinah::dbExists $dim]} {
            set y $dim
            return 1
        } else {
            return 0
        }
    }
    public method getY {} { set y }

    public method updateEntries {} {
        $x_entry blank
        $x_entry pushText $x
        $y_entry blank
        $y_entry pushText $y
    }

    public method buildAndGrid {id} {
        if {[catch {buildBoard $id} errorMsg]} {
            tk_messageBox -message $errorMsg -icon error
            blank
        } else {
            mkGrid
        }
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
        ::dinah::dbNewDim $xEntryValue
        ::dinah::dbNewDim $yEntryValue
        setX $xEntryValue
        setY $yEntryValue
        updateEntries
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
            [$objects($sc) cget -frame] configure \
                -borderwidth $::dinah::fragmentBorderWidth \
                -bg $::dinah::selectionCursorColor
            cursorWasRedrawn
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
        cursorWasRedrawn
    }

    public method clickBtnY {} {
        switchScDimsY
        cursorWasRedrawn
    }

    public method clickBtnOK {} {
        query
        cursorWasRedrawn
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
        setX "d.nil"
        setY "d.nil"
        updateEntries
        setWWidth 4
        setWHeight 4
        initBoard
        initGrid
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
            buildAndGrid [::dinah::dbLGet $x \
                [list [expr { ([scDimIndex] + $direction) % \
                              [::dinah::dbGetDimSize $x]       }] 0]]
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
                set newId [::dinah::dbNewEmptyFragment $type]
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
                    # if the grid is composed of only one column
                    lappend newX [linsert [list $dbid] $delta $newId]
                }
                ::dinah::dbSetDim $x $newX
                buildAndGrid $newId
                return 1
            } else {
                return 0
            }
        } else {
            tk_messageBox -message "dim $x is read only" -icon error
            return 0
        }
    }

    public method copySegmentToClipboard {} {
        ::dinah::dbAddSegmentToEmptyClipboard $x [scDimIndex]
    }

    public method pasteClipboardIntoNewSegment {} {
        if {[::dinah::editable $x]} {
            if {![::dinah::dbClipboardIsEmpty]} {
                set row {}
                foreach frag [::dinah::dbGetClipboard] {
                    if {![::dinah::dbFragmentBelongsToDim $x $frag]} {
                        lappend row $frag
                    } else {
                        tk_messageBox -message "clipboard cannot be pasted \
                                                since object $frag already \
                                                belongs to dim $x" \
                                      -icon error
                        return 0
                    }
                }
                if {$row != {}} {
                    ::dinah::dbAppendSegmentToDim $x $row
                    buildAndGrid [lindex $row 0]
                    return 1
                } else {
                    error "pasteClipboardIntoNewSegment: should never happen"
                }
            } else {
                tk_messageBox -message "Cannot paste clipboard: \
                                        clipboard is empty." \
                              -icon error
                return 0

            }
        } else {
            tk_messageBox -message "dim $x is read only" -icon error
            return 0
        }
    }

    public method deleteSegment {} {
        if {[::dinah::editable $x] && [scRow] != {}} {
            ::dinah::dbRemoveSegment $x [scDimIndex]
            blank
            return 1
        } else {
            tk_messageBox -message "the row cannot be removed since \
                                    dimension $x is read only" \
                          -icon error
        }
    }

    public method updateInfo {} {
        set path ""
        if {[::dinah::dbExists [scId],path]} {
            set path [::dinah::dbGet [scId],path]
        }
        set label [::dinah::dbGet [scId],label]
        set scId [scId]
        wm title [winfo toplevel $t] "x: $x ; y: $y ; id: $scId ; \
                                      wWidth: $wWidth ; wHeight: $wHeight ; \
                                      $label ; $path"
        scDim
        eval $onMoveCursor
    }

    public method dropmenu {target src xcoord ycoord op type data} {
        set srcId [lindex $data end]
        set found [::dinah::dbFindInDim $x $srcId]
        if {[::dinah::dbFragmentBelongsToDim $x $srcId]} {
            buildAndGrid $srcId
        } else {
            tk_messageBox -message "object $srcId does not belong to \
                                    dimension $x" \
                          -icon error
        }
    }

    public method copy {} {
        if {[scId] neq {}} {
            ::dinah::dbAddFragmentToEmptyClipboard [scId]
            return 1
        } else {
            tk_messageBox -message "copy impossible: no object under the \
                                    selection cursor" \
                          -icon error
            return 0
        }
    }

    public method copycat {} {
        if {[scId] neq {}} {
            ::dinah::dbAddFragmentToClipboard [scId]
            return 1
        } else {
            tk_messageBox -message "copy impossible: no object under the \
                                    selection cursor" \
                          -icon error
            return 0
        }
    }

    public method pasteBefore {} {
        if {[pasteGuard]} {
            set newScRow [linsert [scRow] [scItemIndex] \
                                  [::dinah::dbClipboardLastItem]]
            ::dinah::dbReplaceSegment $x [scDimIndex] $newScRow
            buildAndGrid [scId]
            return 1
        } else {
            return 0
        }
    }

    public method pasteAfter {} {
        if {[pasteGuard]} {
            if {[scOnLastItem]} {
                set newItemIndex end
            } else {
                set newItemIndex [expr {[scItemIndex] + 1}]
            }
            set newScRow [linsert [scRow] $newItemIndex \
                                  [::dinah::dbClipboardLastItem]]
            ::dinah::dbReplaceSegment $x [scDimIndex] $newScRow
            buildAndGrid [scId]
            return 1
        } else {
            return 0
        }
    }

    public method method cut {} {copycat; delete}

    public method delete {} {
        if {[deleteGuard]} {
            set scRow [scRow]
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
            return 1
        } else {
            return 0
        }
    }

    public method updateNumModifier {k} {
        set numModifier [join [list $numModifier $k] ""]
    }

    # only used by Txt click method. Should do it another way (with a handler).
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
        set f [frame $t.frame -borderwidth 1 -bg black -highlightcolor green \
                              -highlightthickness 1]
        pack $f -side top -fill both -expand yes
        frame $f.menu
        pack $f.menu -side top -fill x
        menubutton $f.menu.navigation -text "Nav" -menu $f.menu.navigation.m \
                                      -underline 0
        pack $f.menu.navigation -side left -padx 4 -pady 4
        menu $f.menu.navigation.m
        $f.menu.navigation.m add command -label "First" \
            -command [list $this gotoRowStart] -underline 0
        $f.menu.navigation.m add command -label "Last" \
            -command [list $this gotoRowEnd] -underline 0
        $f.menu.navigation.m add command -label "Extend window width" \
            -command [list $this incrWWidth 1]
        $f.menu.navigation.m add command -label "Reduce window width" \
            -command [list $this incrWWidth -1]
        $f.menu.navigation.m add command -label "Extend window height" \
            -command [list $this incrWHeight 1]
        $f.menu.navigation.m add command -label "Reduce window height" \
            -command [list $this incrWHeight -1]
        $f.menu.navigation.m add command -label "Previous history" \
            -command [list $this prevHistory] -underline 0
        $f.menu.navigation.m add command -label "Next history" \
            -command [list $this nextHistory] -underline 0
        $f.menu.navigation.m add command -label "Goto label" \
            -command [list $this msgGoto] -underline 0
        $f.menu.navigation.m add command -label "Reload" \
            -command [list $this reload] -underline 0
        menubutton $f.menu.edition -text "Edit" -menu $f.menu.edition.m \
            -underline 0
        pack $f.menu.edition -side left -padx 4 -pady 4
        menu $f.menu.edition.m
        $f.menu.edition.m add command -label "Clear view" \
            -command [list $this blank] -underline 6
        $f.menu.edition.m add command -label "Swap dimensions" \
            -command [list $this swapDim] -underline 0
        $f.menu.edition.m add command -label "Next segment" \
            -command [list $this nextList 1] -underline 0
        $f.menu.edition.m add command -label "Previous segment" \
            -command [list $this nextList -1] -underline 0
        $f.menu.edition.m add command -label "New text node" \
            -command [list $this new Txt] -underline 4
        $f.menu.edition.m add command -label "Copy segment to clipboard" \
            -command [list $this copySegmentToClipboard]
        $f.menu.edition.m add command -label "Paste clipboard into \
                                              a new segment" \
            -command [list $this pasteClipboardIntoNewSegment]
        $f.menu.edition.m add command -label "Delete Segment" \
            -command [list $this deleteSegment]
        $f.menu.edition.m add command -label "Copy selection to \
                                              clipboard (Ctrl+c)" \
            -command [list $this copycat]
        $f.menu.edition.m add command -label "Paste before selection (Ctrl+V)" \
            -command [list $this pasteBefore]
        $f.menu.edition.m add command -label "Paste after selection (Ctrl+v)" \
            -command [list $this pasteAfter]
        $f.menu.edition.m add command -label "Cut selection to clipboard \
                                              (Ctrl+x)" \
            -command [list $this cut]
        $f.menu.edition.m add command -label "Delete selection from fragment \
                                              (Ctrl+d)" \
            -command [list $this delete]
        button $f.menu.btnX -text "X:" -command [list $this clickBtnX]
        pack $f.menu.btnX -side left -padx 4 -pady 4
        set x_entry [::dinah::Autocomplete x_entry#auto $f.menu.x_entry \
            [::dinah::dbGet dimensions]]
        pack $f.menu.x_entry -side left -padx 4 -pady 4
        button $f.menu.btnY -text "Y:" -command [list $this clickBtnY]
        pack $f.menu.btnY -side left -padx 4 -pady 4
        set y_entry [::dinah::Autocomplete y_entry#auto $f.menu.y_entry \
            [::dinah::dbGet dimensions]]
        pack $f.menu.y_entry -side left -padx 4 -pady 4
        button $f.menu.ok -text "OK" -command [list $this clickBtnOK]
        pack $f.menu.ok -side left -padx 4 -pady 4
        set g [frame $f.grid -bg $::dinah::backgroundColor]
        pack $g -side top -fill both -expand yes

        bind $f.menu <1> [list focus $t]

        DropSite::register $f.menu -dropcmd [list $this dropmenu] \
            -droptypes {Obj copy}

        initGrid
        setBindings
        focus $t
        return $t
    }

    # used by Obj for adding a menu to an object when visible in a dim view and
    # appearing on multiple dims. With this menu, a user selects a dim on which 
    # the object appears,
    # and this dim will be set as the current x-dim for the dim container.
    public method setXAndUpdate {dim} {
        setX $dim
        updateEntries
        buildAndGrid [scId]
    }

    public method forEachObject {msg} {
        foreach {xy o} [array get objects] {
            catch {$o {*}$msg}
        }
    }

    public method reload {} { buildAndGrid [scId] }

    public method wRight {} { wHoriz 1 }

    public method wLeft {} { wHoriz -1 }

    public method wDown {} { wVertic 1 }

    public method wUp {} { wVertic -1 }

    ###################
    # PRIVATE METHODS #
    ###################

    private method guardXEmpty {} {
        if {$x eq ""} {
            tk_messageBox -message "action impossible: no dimension set \
                                    on axis x" \
                          -icon error
            return 0
        } else {
            return 1
        }
    }

    private method guardXReadOnly {} {
        if {![::dinah::editable $x]} {
            tk_messageBox -message "action impossible: dimension $x \
                                    is readonly" \
                          -icon error
            return 0
        } else {
            return 1
        }
    }

    private method guardClipboardEmpty {} {
        if {[::dinah::dbClipboardIsEmpty]} {
            tk_messageBox -message "action impossible: the clipboard is empty" \
                          -icon error
            return 0
        } else {
            return 1
        }
    }

    private method guardScRowEmpty {} {
        if {[scRow] eq {}} {
            tk_messageBox -message "action impossible: the main row is empty" \
                          -icon error
            return 0
        } else {
            return 1
        }
    }

    private method guardCycleOrDuplicate {} {
        if {![noCycleOrDuplicate]} {
            tk_messageBox -message "action impossible: the object to be \
                                    pasted already belongs to dimension $x" \
                          -icon error
            return 0
        } else {
            return 1
        }
    }

    private method pasteGuard {} {
        if { [guardXEmpty] && [guardXReadOnly] && [guardClipboardEmpty] && \
             [guardScRowEmpty] && [guardCycleOrDuplicate] } {
            return 1
        } else {
            return 0
        }
    }

    private method deleteGuard {} {
        if { [guardXEmpty] && [guardXReadOnly] && [guardScRowEmpty] } {
            return 1
        } else {
            return 0
        }
    }

    private method addToHistory {} {
        # if we went back some action in current history
        # and we want to initiate a new action
        # then we forget the part of history we explored back.
        # e.g. history is a1 a2 a3 a4 a5
        #                       ^
        # and we initiate a new action a6, then history becomes
        # a1 a2 a3 a6
        #          ^
        if {([llength $history] > 0) && \
            ($historyIndex != [expr {[llength $history] - 1}])} {
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
        # in case no modifier has been entered,
        # we consider it to be 1
        # e.g. scLeft will move the cursor 1 step to the left
        if {$numModifier eq ""} {return "1"}
        return $numModifier
    }

    private method setBindings {} {
        bind $t <Key-Right> [list $this scRight]
        bind $t <Key-Left> [list $this scLeft]
        bind $t <Key-Down> [list $this scDown]
        bind $t <Key-Up> [list $this scUp]
        bind $t <Shift-Key-Right> [list $this wHorizByOneScreen 1]
        bind $t <Shift-Key-Left> [list $this wHorizByOneScreen -1]
        bind $t <Control-Key-Left> [list $this wLeft]
        bind $t <Control-Key-Right> [list $this wRight]
        bind $t <Control-Key-Up> [list $this wUp]
        bind $t <Control-Key-Down> [list $this wDown]
        bind $t <Control-Key-c> [list $this copycat]
        bind $t <Control-Key-V> [list $this pasteBefore]
        bind $t <Control-Key-v> [list $this pasteAfter]
        bind $t <Control-Key-x> [list $this cut]
        bind $t <Control-Key-d> [list $this delete]
        foreach k {0 1 2 3 4 5 6 7 8 9} {
            bind $t <Key-$k> [list $this updateNumModifier $k]
        }
    }

    private method initScDim {} {
        set scDim {}
    }

    private method scDim {} {
        # store in scDim the list of the dimensions on which
        # the selection cursor (sc) appears
        initScDim
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

    private method scDimAfter {dim} {
        # return the element of $scDim coming after $dim,
        # considering $scDim a circular list
        # if $dim is not an element of $scDim,
        # return the first element of $scDim
        # if $scDim is empty, return -1
        set scDimLength [llength $scDim]
        if {$scDimLength > 0} {
            set dimIndex [lsearch -exact $scDim $dim]
            if {$dimIndex == -1} {
                return [lindex $scDim 0]
            } else {
                set nextDim [lindex $scDim [expr {$dimIndex + 1}]]
                if {$nextDim eq {}} {
                    return [lindex $scDim 0]
                } else {
                    return $nextDim
                }
            }
        } else {
            return -1
        }
    }

    private method switchScDimsX {} {
        # switch the x-axis to one of the other dims that the
        # selection cursor (sc) belongs to
        set nextDim [scDimAfter [getX]]
        if {$nextDim == -1} {
            return 0
        } else {
            setX $nextDim
            updateEntries
            buildAndGrid [scId]
            return 1
        }
    }

    private method switchScDimsY {} {
        # switch the y-axis to one of the other dims that the
        # selection cursor (sc) belongs to
        set nextDim [scDimAfter [getY]]
        if {$nextDim == -1} {
            return 0
        } else {
            setY $nextDim
            updateEntries
            buildAndGrid [scId]
            return 1
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

    private method wVertic {i} {
        if {(($wRow + $i) >= 0) && (($wRow + $i) < $gridHeight)} {
            incr wRow $i
            mkGrid
            return 1
        }
        return 0
    }

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
            if {[string match -nocase *$match* [::dinah::dbGet \
                    [lindex $row $i],label]]} {
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
                [$objects($sc) cget -frame] configure \
                    -borderwidth $::dinah::fragmentBorderWidth \
                    -bg $::dinah::selectionCursorColor
            }
            cursorWasRedrawn
        }
    }

    private method scVertic {i} {
        if {![insideW [scRowIndex] [scColumnIndex]]} {return}
        set newScRow [expr {[scRowIndex] + $i}]
        set exist [info exists grid($newScRow,[scColumnIndex])]
        if {$exist && !( [cell $newScRow [scColumnIndex]] eq {} )} {
            buildAndGrid [id [cell $newScRow [scColumnIndex]]]
            mkGrid
        }
    }

    private method initInfo {} {
        wm title [winfo toplevel $t] "x: $x ; y: $y ; \
                                      wWidth: $wWidth ; wHeight: $wHeight"
    }

    private method initBoard {} {
        array unset grid
        array set grid {}
        set sc {}
        initInfo
        initScDim
    }

    private method buildBoard {{center {}}} {
        # center is the id of an object on which the selection cursor (sc)
        # will be set
        set mainRow {}
        set mainRowSegIndex {}
        set cols {}
        initBoard
        if {$center eq {}} {
            set center [::dinah::dbLGet $x {0 0}]
            if {$center eq {}} {
                error "the board cannot be built because no center was given \
                       and the first fragment of the dim $x is empty \
                       which implies that the dim $x is empty since a dim \
                       should never have empty fragments"
            }
        }
        #
        # From now on, $center refers to the id of an object
        #
        set centerFoundOnX [::dinah::dbFindInDim $x $center]
        if {[llength $centerFoundOnX] == 0} {
            set centerFoundOnY [::dinah::dbFindInDim $y $center]
            if {[llength $centerFoundOnY] != 0} {
                # the grid will consist of only one column
                set segIndex [lindex $centerFoundOnY 0]
                set fragIndex [lindex $centerFoundOnY 1]
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
                return 1
            } else {
                error "the grid cannot be build since $center belongs \
                       to neither the dim $x nor the dim $y"
            }
        } else {
            # building the main row:
            set segIndex [lindex $centerFoundOnX 0]
            set fragIndex [lindex $centerFoundOnX 1]
            set seg [::dinah::dbGetSegment $x $segIndex]
            set mainRowSegIndex $segIndex
            set mainRow $seg
            # For now we are only able to set the column index of
            # the selection cursor (sc). The row index will be set later.
            set sc [list $fragIndex]
            set gridWidth [llength $mainRow]

            # building the columns:
            foreach k $mainRow {
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

        # complete columns with bottom distances:
        # for a given column, top    is the number of objects above the main row
        # for a given column, bottom is the number of objects below the main row
        # for a given column, fragIndex ([lindex $col 2]) is the value of top
        # maxTop and maxBottom are used to compute the height of the grid
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
        # We can now complete the position of the selection cursor (sc)
        # with its row index which is $maxTop since the first row of the
        # grid is numbered 0
        set sc [linsert $sc 0 $maxTop]
        set cols $newCols

        # grid:
        for {set i 0} {$i < [llength $mainRow]} {incr i} {
            # the line number of the mainRow is $maxTop
            set grid($maxTop,$i) [list $x $mainRowSegIndex $i]
        }
        for {set i 0} {$i < [llength $cols]} {incr i} {
            if {[lindex $cols $i] eq {}} {
                # case of an empty column
                for {set j 0} {$j < $maxTop} {incr j} {
                    set grid($j,$i) {}
                }
                for {set j 0} {$j < $maxBottom} {incr j} {
                    set grid([expr {$maxTop + 1 + $j}],$i) {}
                }
            } else {
                # case of a non empty column
                set segIndex [lindex $cols $i 1]
                set top [lindex $cols $i 2]
                set bottom [lindex $cols $i 3]
                set deltaTop [expr {$maxTop - $top}]
                set deltaBottom [expr {$maxBottom - $bottom}]
                for {set j 0} {$j < $deltaTop} {incr j} {
                    set grid($j,$i) {}
                }
                for {set j 0} {$j < $top} {incr j} {
                    set grid([expr {$j + $deltaTop}],$i) [list $y $segIndex $j]
                }
                for {set j 0} {$j < $bottom} {incr j} {
                    set grid([expr {$maxTop + 1 + $j}],$i) \
                        [list $y $segIndex [expr {$top + 1 + $j}]]
                }
                for {set j 0} {$j < $deltaBottom} {incr j} {
                    set grid([expr {$maxTop + 1 + $bottom + $j}],$i) {}
                }
            }
        }
        setWRow [lindex $sc 0]
        setWCol  [lindex $sc 1]
        return 1
    }

    # given the width of the grid (gridWidth) and the
    # maximum number of visible columns (wWidth),
    # the (manual) choice of the first visible column (wCol) can be unoptimal
    # i.e. more could be seen. Therefore, this method change the value of wCol
    # if necessary.
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

    # given the height of the grid (gridHeight) and the
    # maximum number of visible rows (wHeight),
    # the (manual) choice of the first visible row (wRow) can be unoptimal
    # i.e. more could be seen. Therefore, this method change the value of wRow
    # if necessary.
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
        # if there is no current selection cursor (sc),
        # there is no point in drawing the grid
        if {$sc eq {}} { return 0 }

        set busy 1
        initGrid
        array unset objects
        array set pos {}

        optimizeScreenSpace
        array set id2obj {}

        # special cases of grids of sizes 2x1 or 1x2
        # the two windows of such grids will be inserted in a paned window
        # for allowing the user to resize the windows
        set twoVertic [expr {(($wHeight == 2) && ($wWidth == 1)) ? 1 : 0}]
        set twoHoriz [expr {(($wHeight == 1) && ($wWidth == 2)) ? 1 : 0}]
        set usePanedwin 1
        if {$twoVertic} {
            set panedwin [panedwindow $g.pan -orient vertical -handlesize 10 \
                -showhandle 1]
        } elseif {$twoHoriz} {
            set panedwin [panedwindow $g.pan -orient horizontal -handlesize 10 \
                -showhandle 1]
        } else {
            set usePanedwin 0
        }

        for {set i 0} {$i < $wHeight} {incr i} {
            for {set j 0} {$j < $wWidth} {incr j} {
                set absoluteI [expr {$wRow + $i}]
                set absoluteJ [expr {$wCol + $j}]
                set absolutePos [list $absoluteI $absoluteJ]
                set objId [id [cell $absoluteI $absoluteJ]]
                if {! ($objId eq {})} {
                    # In case of the use of a paned window
                    # (i.e. shapes 2x1 and 1x2), the parent window
                    # of the window associated to the object at position
                    # ($absoluteI,$absoluteJ) of the grid data structure
                    # must be the paned window.
                    # Otherwise, the parent window is the frame $g
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
                    # for the presentation of dimensions in shape H,
                    # if two objects are juxtaposed vertically,
                    # they are always connected.
                    # Thus the call to openNS
                    $o openNS
                    if {[scRowIndex] == $absoluteI} {
                        # for the presentation of dimensions in shape H,
                        # if two objects are juxtaposed horizontally,
                        # they are connected only if
                        # they belong to the main row.
                        # Thus the calls to openEW and closeEW
                        $o openEW
                        if {[scColumnIndex] == $absoluteJ} {
                            $w configure \
                                -borderwidth $::dinah::fragmentBorderWidth \
                                -bg $::dinah::selectionCursorColor
                        }
                    } else {
                        $o closeEW
                    }
                    if {$usePanedwin} {
                        $panedwin add $w -stretch always
                    } else {
                        grid $w -column $j -row $i -sticky news
                    }
                }
            }
        }
        # if the same object appears more than once on the current view,
        # add a color to its menu bar to show the user that it is the same
        # object appearing multiple times (given the definition of a dimension,
        # it cannot appear more than twice on a given view).
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
        cursorWasRedrawn
        update

        foreach {xy o} [array get objects] {
            $o z
        }

        # if the main row (i.e. the row on which is the selection cursor)
        # is visible, ask each object (o) of the main row to write on its
        # notification zone:
        # "row : u/v"
        # where v is the length of the segment corresponding to the main row and
        # u is the position of object o in this segment
        if {[insideW [scRowIndex] $wCol]} {
            if {$twoVertic} {
                set mainRowPathnames [lindex [$panedwin panes] \
                    [expr {[scRowIndex]-$wRow}]]
            } elseif {$twoHoriz} {
                set mainRowPathnames [$panedwin panes]
            } else {
                set mainRowPathnames [lreverse [grid slaves $g -row \
                    [expr {[scRowIndex]-$wRow}]]]
            }
            set leftMostPathname [lindex $mainRowPathnames 0]
            set firstVisibleCol [expr {[lindex $pos($leftMostPathname) 1] + 1}]
            for {set i 0} {$i < [llength $mainRowPathnames]} {incr i} {
                $objects($pos([lindex $mainRowPathnames $i])) notificate \
                    [concat "row :" [expr {$firstVisibleCol + $i}] \
                            "/$gridWidth ; "]
            }
        }
        # ask each object (o) of each visible column to write on its
        # notification zone:
        # "col: u/v"
        # where v is the length of the segment corresponding to this column,
        # and u is the position of object o in this segment
        for {set j 0} {$j < $wWidth} {incr j} {
            set absoluteJ [expr {$wCol + $j}]
            set col [getGridColumn $absoluteJ]
            set colHeight [llength $col]
            if {$twoVertic} {
                set colPathnames [$panedwin panes]
            } elseif {$twoHoriz} {
                # Obviously, in this case the length of $colPathnames is
                # at most 1.
                set colPathnames [lindex [$panedwin panes] $j]
            } else {
                set colPathnames [lreverse [grid slaves $g -col $j]]
            }
            if {[llength $colPathnames] != 0} {
                set firstVisibleRow [expr {[lsearch -exact $col \
                    [lindex $pos([lindex $colPathnames 0]) 0]] + 1}]
                for {set i 0} {$i < [llength $colPathnames]} {incr i} {
                    $objects($pos([lindex $colPathnames $i])) notificate \
                        [concat "col :" [expr {$firstVisibleRow + $i}] \
                                "/$colHeight ; "]
                }
            }
        }
        focus $t
        set busy 0
        return 1
    }

    private method getGridColumn {j} {
        set col {}
        foreach {k v} [array get grid *,$j] {
            if {$v ne {}} {lappend col [regsub {,.*$} $k ""]}
        }
        set col [lsort -integer $col]
        return $col
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
            return [::dinah::dbLGet [lindex $cell 0] \
                [list [lindex $cell 1] [lindex $cell 2]]]
        } else {
            return {}
        }
    }

    private method insideW {row col} {
        return [expr {( ($wCol <= $col) && ($col < ($wCol + $wWidth) )) && \
                      ( ($wRow <= $row) && ($row < ($wRow + $wHeight)))}]
    }

    private method scCell {} { return [cell [scRowIndex] [scColumnIndex]] }
    private method scDimName {} { return [lindex [scCell] 0] }
    private method scDimIndex {} { return [lindex [scCell] 1] }
    private method scItemIndex {} { return [lindex [scCell] 2] }

    # if {[scDimName] ne $x} it means that [scDimName] comes from the
    # vertical/Y dim
    # therefore in that case the selection cursor row is empty.
    private method scRowEmpty {} {
        return [expr {[scDimName] ne $x}]
    }

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

    private method noCycleOrDuplicate {} {
        return [expr {(! [dimXIsNil])  && (! [::dinah::dbClipboardIsEmpty]) && \
                      (! [scRowEmpty]) && (! [pastingCycle]) && \
                      (! [pastingDuplicate])}]
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
                if {[::dinah::dbClipboardLastItem] in \
                    [::dinah::dbLGet [scDimName] $i]} {
                    # item appearing twice in a dimension
                    return 1
                }
            }
        }
        return 0
    }

    private method dimXIsNil {} {
        if {$x eq "d.nil"} {
            return 1
        } else {
            return 0
        }
    }

    private method pasteIntoNewSegment {} {
        if {(! [dimXIsNil]) && (! [::dinah::dbClipboardIsEmpty])} {
            ::dinah::dbAppendSegmentToDim $x \
                [list [::dinah::dbClipboardLastItem]]
            buildAndGrid [::dinah::dbClipboardLastItem]
        }
    }

    private method newListWithTxtNode {} {
        if {! [dimXIsNil]} {
            set txtId [::dinah::dbNewEmptyFragment Txt]
            ::dinah::dbAppendSegmentToDim $x [list $txtId]
            buildAndGrid $txtId
        }
    }

    private method cursorWasRedrawn {} {
        updateInfo
        addToHistory
    }
}
