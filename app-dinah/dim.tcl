itcl::class Dim {
    private variable x ""; # name of the x dimension 
    private variable y ""; # name of the y dimension 
    private variable x_entry {};
    private variable y_entry {};
    private variable wWidth 4; # visible window width
    private variable wHeight 4;
    private variable wRow 0;
    private variable wCol 0;
    private variable grid;
    private variable gridWidth 0;
    private variable gridHeight 0;
    private variable sc {}; # selection cursor: {line_of_grid column_of_grid}
    private variable t {}; #toplevel
    private variable f {}; # frame
    private variable g {}; # grid
    private variable objects; # visible objects
    private variable scDim {}
    private variable scDimXCursor 0
    private variable scDimYCursor 0
    private variable modes
    private variable busy 0
    private variable resolutionLabel ""
    public variable states {}; # states of the objects presented on this view (zoom level...)
    private variable tree ""
    private variable numModifier ""
    private variable container ""
    private variable onMoveCursor ""
    private variable history {}
    private variable historyIndex 0
    private variable listOfTreesMenu ""
    private variable dimMenu ""
    private variable btnMenu ""

    constructor {} {
        set modes(names) {nil navigation transcription notice}
        set modes(current) 0
        set modes(index) 0
        set modes(nil) {{1 1 {d.nil d.nil}}}
        set modes(navigation) {{4 4 {d.insert d.sameLevel} {hookNbArchivePages} {hookInitNavigation}} {1 4 {d.archive d.sameLevel}}}
        set modes(transcription) {{1 2 {d.transcription d.archive}}}
        set modes(notice) {{1 1 {d.archive d.nil} {} {hookInitNotice}} {4 4 {d.noticeLevel d.noticeElement}}}
    }


    method setTreeNavDim {d} { $tree setNavDim $d}

    method addToHistory {} {
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

    method prevHistory {} {
        if {$historyIndex != 0} {
            incr historyIndex -1
            gotoHistory $historyIndex
        }
    }

    method nextHistory {} {
        if {  ([llength $history] > 0) &&
              ($historyIndex != [expr {[llength $history] - 1}])  } {
            incr historyIndex
            gotoHistory $historyIndex
        }
    }

    method gotoHistory {index} {
        setX [lindex [lindex $history $index] 1]
        setY [lindex [lindex $history $index] 2]
        updateEntries
        buildAndGrid [lindex [lindex $history $index] 0]
    }

    method getTopFrame {} { 
        return $t
    }

    method setOnMoveCursor {code} { 
        set onMoveCursor $code
    }

    method getFocus {} { focus $t }

    method buildAndGrid {id} {
        buildBoard $id
        mkGrid
    }

    method setContainer {c} {
        set container $c
    }

    method getContainer {} {
        return $container
    }

    method gotoRowEnds {where} {
        set r [scRow]
        if {$r != {}} {
            buildBoard [lindex $r $where]
            mkGrid
        }
    }

    method gotoRowEnd {} { gotoRowEnds "end" }

    method gotoRowStart {} { gotoRowEnds 0 }

    method initNumModifier {} {
        set numModifier ""
    }

    method getNumModifier {} {
        if {$numModifier eq ""} {return "1"}
        return $numModifier
    }

    method updateNumModifier {k} {
        set numModifier [join [list $numModifier $k] ""] 
    }

    method clickBtnX {} {
        switchScDimsX
        addToHistory
    }

    method clickBtnY {} {
        switchScDimsY
        addToHistory
    }

    method clickBtnOK {} {
        query
        addToHistory
    }

    method mkWindow {{parent {}}} {
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
        set resolutionLabel [label $f.menu.resolution -text ""]
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
        pack $resolutionLabel -side left -padx 4 -pady 4
        pack $f.menu -side top -fill x
        set main [panedwindow $f.main -handlesize 10 -showhandle 1]
        pack $main -side top -fill both -expand yes
        set tree [::dinah::Tree #auto]
        set treeFrame [$tree mkWindow $main]
        $tree bindDblClick [list $this openTreeItem]
        $main add $treeFrame
        set g [frame $main.grid -bg $::dinah::backgroundColor]
        $main add $g

        set dimMenu [menu $f.dimMenu]
        set treeMenu [menu $dimMenu.treeMenu]
        set listOfTreesMenu [menu $treeMenu.listOfTreesMenu]
        updateListOfTreesMenu
        #$treeMenu add command -label "build tree (a)" -command [list $this newTreeOnCursor]
        $treeMenu add command -label "new tree" -command [list $this newTree]
        $treeMenu add cascade -label "list of trees" -menu $listOfTreesMenu
        $dimMenu add cascade -label "trees" -menu $treeMenu
        $dimMenu add command -label "clear view (b)" -command [list $this blank]
        $dimMenu add command -label "swap dim (s)" -command [list $this swapDim]
        $dimMenu add command -label "next segment (o)" -command [list $this nextList 1]
        $dimMenu add command -label "prev segment (O)" -command [list $this nextList -1]
        $dimMenu add command -label "goto label" -command [list $this msgGoto]
        $dimMenu add command -label "new Txt (n)" -command [list $this new Txt]
        $dimMenu add command -label "segment -> clipboard" -command [list $this copySegmentToClipboard]
        $dimMenu add command -label "paste clipboard" -command [list $this pasteClipboard]
        $dimMenu add command -label "delete segment" -command [list $this deleteRow]
        $dimMenu add command -label "nouvelle fenetre avec navigation" -command { ::dinah::desanti_navigation_win }
        $dimMenu add command -label "nouvelle fenetre (Ctrl-n)" -command [list $this newWindow]
        $dimMenu add command -label "exit (Ctrl-q)" -command {exit}
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

    method showBtnMenu {} {
        tk_popup $dimMenu [winfo rootx $btnMenu] [winfo rooty $btnMenu]
    }

    method updateListOfTreesMenu {} {
        $listOfTreesMenu delete 0 end
        $listOfTreesMenu add command -label navigation -command [list $this showNavTree]
        set rootDic {}
        foreach rootId [::dinah::dbGet $::dinah::roots] {
            set rootName [::dinah::dbGet $rootId,label]
            lappend rootDic [list $rootId $rootName]
        }
        foreach {rootId rootName} [join [lsort -dictionary -index 1 $rootDic]] {
            $listOfTreesMenu add command -label $rootName -command [list $this showTree $rootId]
        }

    }

    method newTree {} {
        set newRootId [::dinah::newTree "tree"]
        updateListOfTreesMenu
        showTree $newRootId
    }

    method showTree {rootId} {
        $tree writable
        $tree setNavDim [::dinah::treeDimName $rootId]
        [[$tree setRoot $rootId] setDim $::dinah::dim0 $::dinah::dim1] load
        setX [::dinah::treeDimName $rootId]
        setY $::dinah::dimNil
        updateEntries
        buildAndGrid $rootId
    }

    method showNavTree {} {
        $tree readOnly
        $tree setNavDim $::dinah::dimArchive
        [[$tree setRoot [::dinah::dbGet archiveId]] setDim \
          $::dinah::dimInsert $::dinah::dimSameLevel] load
    }

    method dropmenu {target src xcoord ycoord op type data} {
        set srcId [lindex $data end]
        set found [::dinah::findInDim $x $srcId]
        if {$found != {}} {
            buildAndGrid $srcId
        } elseif {[::dinah::editable $x]} {
            ::dinah::dbAppend $x [list $srcId]
            buildAndGrid $srcId
        }
    }

    method openTreeItem {item} { 
        setX [$tree getNavDim]
        setY $::dinah::dimNil
        updateEntries
        buildAndGrid [$tree itemId $item] 
    }

    method hookInitNotice {} {
        if {([scId] ne "") && ([::dinah::dbGet [scId],isa] eq "Page")} {
            set found [::dinah::findInDim $::dinah::dimNoticeLevel [scId]]
            if {[llength $found] == 0} {
                set fragment {}
                lappend fragment [scId] 
                set titrePropre [::dinah::emptyNode Txt "titre propre"]
                ::dinah::dbSet $titrePropre,txt "text {titre propre :\n} 1.0"
                lappend fragment $titrePropre
                ::dinah::dbAppend $::dinah::dimNoticeLevel $fragment
                set fragment {}
                lappend fragment $titrePropre
                set titreForge [::dinah::emptyNode Txt "titre forg\u00E9"]
                ::dinah::dbSet $titreForge,txt "text {titre forg\u00E9 :\n} 1.0"
                lappend fragment $titreForge
                lappend fragment [::dinah::emptyNode Date "date"]
                set notesDatation [::dinah::emptyNode Txt "notes datation"]
                ::dinah::dbSet $notesDatation,txt "text {notes datation :\n} 1.0"
                lappend fragment $notesDatation
                set descriptionIntellectuelle [::dinah::emptyNode Txt "description intellectuelle"]
                ::dinah::dbSet $descriptionIntellectuelle,txt "text {description intellectuelle :\n} 1.0"
                lappend fragment $descriptionIntellectuelle
                set sommaire [::dinah::emptyNode Txt "sommaire"]
                ::dinah::dbSet $sommaire,txt "text {sommaire :\n} 1.0"
                lappend fragment $sommaire
                set notesSciPub [::dinah::emptyNode Txt "notes scientifiques publiques"]
                ::dinah::dbSet $notesSciPub,txt "text {notes scientifiques publiques :\n} 1.0"
                lappend fragment $notesSciPub
                set notesSciPriv [::dinah::emptyNode Txt "notes scientifiques priv\u00E9es"]
                ::dinah::dbSet $notesSciPriv,txt "text {notes scientifiques priv\u00E9es :\n} 1.0"
                lappend fragment $notesSciPriv
                set notesArchPub [::dinah::emptyNode Txt "notes archivistiques publiques"]
                ::dinah::dbSet $notesArchPub,txt "text {notes archivistiques publiques :\n} 1.0"
                lappend fragment $notesArchPub
                set notesArchPriv [::dinah::emptyNode Txt "notes archivistiques priv\u00E9es"]
                ::dinah::dbSet $notesArchPriv,txt "text {notes archivistiques priv\u00E9es :\n} 1.0"
                lappend fragment $notesArchPriv
                set autresNotesPub [::dinah::emptyNode Txt "autres notes publiques"]
                ::dinah::dbSet $autresNotesPub,txt "text {autres notes publiques :\n} 1.0"
                lappend fragment $autresNotesPub
                set autresNotesPriv [::dinah::emptyNode Txt "autres notes priv\u00E9es"]
                ::dinah::dbSet $autresNotesPriv,txt "text {autres notes priv\u00E9es :\n} 1.0"
                lappend fragment $autresNotesPriv
                ::dinah::dbAppend $::dinah::dimNoticeElement $fragment
            }
            [[$tree setRoot [scId]] setDim $::dinah::dimNoticeLevel $::dinah::dimNoticeElement] load
        }
    }

    method hookInitNavigation {} {
        if {[::dinah::dbGet [scId],isa] eq "Page"} {
            [[$tree setRoot [scId]] setDim "d.insert" "d.sameLevel"] load
        }
    }

    method hookNbArchivePages {obj} {
        set dbid [$obj cget -dbid]
        set found [::dinah::findInDim "d.archive" $dbid]
        if {[llength $found] != 0} {
            set nbPages [llength [::dinah::dbLGet $::dinah::dimArchive [lindex $found 0]]
            $obj notificate "$nbPages page(s)"
        }
    }

    method storeState {id cmd args} {
        lappend states [list $id $cmd $args]
    }

    method updateState {obj} {
        foreach {id cmd args} [concat {*}[lsearch -all -inline -exact -index 0 $states [$obj cget -dbid]]] {
            eval $obj $cmd {*}$args
        }
    }

    method setBindings {} {
        if {[info exists objects($sc)]} { 
            [$objects($sc) cget -frame] configure -borderwidth $::dinah::fragmentBorderWidth -bg red
        }

        bind $t <Key-g> [list $this msgGoto]
        #bind $t <Control-Key-l> [list $this incrWWidth 1]
        #bind $t <Control-Key-Right> [list $this incrWWidth 1]
        #bind $t <Control-Key-j> [list $this incrWWidth -1]
        #bind $t <Control-Key-Left> [list $this incrWWidth -1]
        #bind $t <Control-Key-i> [list $this incrWHeight 1]
        #bind $t <Control-Key-Up> [list $this incrWHeight 1]
        #bind $t <Control-Key-k> [list $this incrWHeight -1]
        #bind $t <Control-Key-Down> [list $this incrWHeight -1]
        bind $t <Key-l> [list $this scRight]
        bind $t <Key-Right> [list $this scRight]
        bind $t <Key-j> [list $this scLeft]
        bind $t <Key-Left> [list $this scLeft]
        bind $t <Key-k> [list $this scDown]
        bind $t <Key-Down> [list $this scDown]
        bind $t <Key-i> [list $this scUp]
        bind $t <Key-Up> [list $this scUp]
        #bind $t <Control-Key-L> [list $this wRight]
        #bind $t <Control-Key-J> [list $this wLeft]
        #bind $t <Control-Key-K> [list $this wDown]
        #bind $t <Control-Key-I> [list $this wUp]
        bind $t <Key-L> [list $this wHorizByOneScreen 1]
        bind $t <Shift-Key-Right> [list $this wHorizByOneScreen 1]
        bind $t <Key-J> [list $this wHorizByOneScreen -1]
        bind $t <Shift-Key-Left> [list $this wHorizByOneScreen -1]
        bind $t <Key-X> [list focus [$x_entry w]]
        bind $t <Key-x> [list $this switchScDimsX]
        bind $t <Key-Y> [list focus [$y_entry w]]
        bind $t <Key-y> [list $this switchScDimsY]
        bind $t <Return> [list $this query]
        #bind $t <Key-Z> [list $this z]
        bind $t <Key-n> [list $this new Txt]
        #bind $t <Key-N> [list $this new Date]
        #bind $t <Control-Key-N> [list $this new Struct]
        #bind $t <Control-Key-r> [list $this new Link]
        bind $t <Control-Key-C> [list $this copy]
        bind $t <Control-Key-c> [list $this copycat]
        bind $t <Control-Key-V> [list $this pasteBefore]
        bind $t <Control-Key-v> [list $this pasteAfter]
        bind $t <Control-Key-x> [list $this cut]
        bind $t <Control-Key-d> [list $this delete]
        #bind $t <Key-t> [list $this newWhiteboard]
        bind $t <Control-Key-n> [list $this newWindow]
        #bind $t <Key-W> [list $this newWindowOnCursor]
        bind $t <Key-a> [list $this newTreeOnCursor]
        bind $t <Key-s> [list $this swapDim]
        bind $t <Control-Key-q> {exit}
        #bind $t <Control-Key-w> [list ::dinah::destroyToplevel $t]
        #bind $t <Control-Key-n> {::dinah::switchFocus+} 
        #bind $t <Control-Key-p> {::dinah::switchFocus-} 
        #bind $t <Key-m> [list $this nextMode]
        #bind $t <space> [list $this nextModeDim]
        bind $t <Key-o> [list $this nextList 1]
        bind $t <Key-O> [list $this nextList -1]
        #bind $t <Control-Key-o> [list $this pasteIntoNewList]
        #bind $t <Control-Key-O> [list $this newListWithTxtNode]
        #bind $t <Control-Key-a> [list $this pasteClipboard]
        bind $t <Control-Key-b> [list $this blank]
        foreach k {0 1 2 3 4 5 6 7 8 9} {
            bind $t <Key-$k> [list $this updateNumModifier $k]
        }
        #bind $t <Key-dollar> [list $this gotoRowEnd]
    }

    method blank {} {
        set sc {}
        setX "d.nil"
        setY "d.nil"
        updateEntries
        setWWidth 4
        setWHeight 4
        query
    }

    method swapDim {} {
        set oldY $y
        setY $x
        setX $oldY
        $this updateEntries
        buildAndGrid [scId]
    }

    method setYAndUpdate {yDim} {
        setY $yDim
        updateEntries
        buildAndGrid [scId]
    }

    method scDim {} {
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
            $x_entry setSecondaryList $scDim
            $y_entry setSecondaryList $scDim
        }
    }

    method switchScDimsX {} {
        set scDimLength [llength $scDim]
        if {$scDimLength > 0} {
            setX [lindex $scDim [expr {$scDimXCursor % $scDimLength}]]
            updateEntries
            incr scDimXCursor
            buildAndGrid [scId]
        }
    }

    method switchScDimsY {} {
        set scDimLength [llength $scDim]
        if {$scDimLength > 0} {
            setY [lindex $scDim [expr {$scDimYCursor % $scDimLength}]]
            updateEntries
            incr scDimYCursor
            buildAndGrid [scId]
        }
    }

    method query {} {
        set xEntryValue [[$x_entry w] get]
        set yEntryValue [[$y_entry w] get]
        if {[regexp {^q\..*} $xEntryValue] || [regexp {^q\..*} $yEntryValue]} {
            blank
        }
        setX $xEntryValue
        setY $yEntryValue
        updateEntries
        ::dinah::newDim? $x
        ::dinah::newDim? $y
        buildAndGrid [scId]
    }

    method initGrid {} {
        grid rowconfigure $g all -uniform {} -weight 0
        grid columnconfigure $g all -uniform {} -weight 0
        foreach slave [grid slaves $g] { grid forget $slave ; destroy $slave }
        foreach {pos o} [array get objects] { itcl::delete object $o }
    }

    method setX {dim} { set x $dim }

    method getX {} { set x }

    method setY {dim} { set y $dim }

    method getY {} { set y }

    method setWRow {i} { set wRow $i }

    method setWCol {j} { set wCol $j }

    method setWWidth {nbColumns} {
        if {$nbColumns > 0} {
            set wWidth $nbColumns
        }
    }

    method setWHeight {nbRows} {
        if {$nbRows > 0} {
            set wHeight $nbRows
        }
    }

    method incrWWidth {i} {
        setWWidth [expr {$wWidth + $i}]
        mkGrid
    }

    method incrWHeight {i} {
        setWHeight [expr {$wHeight + $i}]
        mkGrid
    }

    method wHorizByOneScreen {{direction 1}} {
        if { $busy } { return }
        if {[wHoriz [expr {$direction * $wWidth}]]} {
            set sc [list [scRowIndex] $wCol]
            [$objects($sc) cget -frame] configure -borderwidth $::dinah::fragmentBorderWidth -bg red
            updateInfo
        }
    }

    method wHoriz {i} {
        if {(($wCol + $i) >= 0) && (($wCol + $i) < $gridWidth)} {
            incr wCol $i
            mkGrid
            return 1
        }
        return 0
    }

    method wRight {} { wHoriz 1 }

    method wLeft {} { wHoriz -1 }

    method wVertic {i} {
        if {(($wRow + $i) >= 0) && (($wRow + $i) < $gridHeight)} {
            incr wRow $i
            mkGrid
        }
    }

    method wDown {} { wVertic 1 }

    method wUp {} { wVertic -1 }

    method scRowIndex {} {
        if {[llength $sc] == 2} {
            return [lindex $sc 0]
        } else {
            return {}
        }
    }

    method scColumnIndex {} {
        if {[llength $sc] == 2} {
            return [lindex $sc 1]
        } else {
            return {}
        }
    }

    method updateInfo {} {
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

    method setMode {modeIndex} {
        set modes(current) $modeIndex
        set modes(index) 0
        setModeDim
        applyInitHooks
    }

    method setModeNil {} { setMode 0}
    method setModeNotice {} { setMode 3}
    method setModeTranscription {} { setMode 2}

    method nextMode {} {
        if {$modes(current) + 1 == [llength $modes(names)]} {
            setMode 0
            set modes(current) 0
        } else {
            setMode [expr {$modes(current) + 1}]
        }
    }

    method nextModeDim {} {
        set modeName [lindex $modes(names) $modes(current)]
        if {$modes(index) + 1 == [llength $modes($modeName)]} {
            set modes(index) 0
        } else {
            incr modes(index)
        }
        setModeDim
    }

    method setModeDim {} {
        set modeName [lindex $modes(names) $modes(current)]
        set newDims [lindex $modes($modeName) $modes(index) 2]
        setX [lindex $newDims 0]
        setY [lindex $newDims 1]
        updateEntries
        setWWidth [lindex $modes($modeName) $modes(index) 1]
        setWHeight [lindex $modes($modeName) $modes(index) 0]
        query
    }

    method getModeHooks {hookType} {
        set modeName [lindex $modes(names) $modes(current)]
        set hooks [lindex $modes($modeName) $modes(index) $hookType]
    }

    method applyNormalHooks {obj} {
        foreach h [getModeHooks 3] {
            eval $h $obj
        }
    }

    method applyInitHooks {} {
        foreach h [getModeHooks 4] {
            eval $h
        }
    }

    method msgGoto {} {
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

    method msgGotoOK {} {
        global gotoEntryValue
        goto $gotoEntryValue
        destroy .tGoto
    }

    method goto {match} {
        set row [::dinah::dbLGet [scDimName] [scDimIndex]]
        for {set i 0} {$i < [llength $row]} {incr i} {
            if {[string match -nocase *$match* [::dinah::dbGet [lindex $row $i],label]]} {
                scHoriz [expr {$i - [scColumnIndex]}]
                return
            }
        }
    }

    method scHoriz {i} {
        if {![insideW [scRowIndex] [scColumnIndex]]} {return}
        set newScCol [expr {[scColumnIndex] + $i}]
        set exist [info exists grid([scRowIndex],$newScCol)]
        if {$exist && !( $grid([scRowIndex],$newScCol) eq {} )} {
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

    method scRight {} {
        if {! $busy} { 
            scHoriz [getNumModifier] 
            initNumModifier 
        }
    }

    method scLeft {} {
        if {! $busy} { 
            scHoriz -[getNumModifier] 
            initNumModifier 
        }
    }

    method scVertic {i} {
        if {![insideW [scRowIndex] [scColumnIndex]]} {return}
        set newScRow [expr {[scRowIndex] + $i}]
        set exist [info exists grid($newScRow,[scColumnIndex])]
        if {$exist && !( $grid($newScRow,[scColumnIndex]) eq {} )} {
            buildAndGrid [id [cell [list $newScRow [scColumnIndex]]]]
            mkGrid
            addToHistory
            set scDimXCursor 0
            set scDimYCursor 0
        }
    }

    method scDown {} {
        if {! $busy} { 
            scVertic [getNumModifier] 
            initNumModifier 
        }
    }

    method scUp {} {
        if {! $busy} { 
            scVertic -[getNumModifier] 
            initNumModifier 
        }
    }

    method buildBoard {{center {}}} {
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
            set found [::dinah::findInDim $x $center]
            if {[llength $found] != 0} {
                set mainRowIndex [lindex $found 0]
                set mainRow [::dinah::dbLGet $x $mainRowIndex]
                set sc [list [lindex $found 1]]
            }
            set gridWidth [llength $mainRow]
            # cols:
            if {[::dinah::dbExists $y]} {
                if {$mainRow eq {}} {
                    set found [::dinah::findInDim $y $center]
                    if {[llength $found] != 0} {
                        set foundRow [lindex $found 0]
                        set foundRowLength [llength [::dinah::dbLGet $y $foundRow]]
                        for {set k 0} {$k < $foundRowLength} {incr k} {
                            set grid($k,0) [list $y $foundRow $k]
                        }
                        set sc [list [lindex $found 1] 0]
                        set gridWidth 1
                        set gridHeight $foundRowLength
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
                        set found [::dinah::findInDim $y $k]
                        if {[llength $found] != 0} {
                            set foundRow [lindex $found 0]
                            lappend cols [list [::dinah::dbLGet $y $foundRow] $foundRow [lindex $found 1]]
                        } else {
                            lappend cols {}
                        }
                    }
                }
            }

            # complete columns with bottom distance:
            # top is the distance from the first value of the col to the main row
            # bottom etc.
            set maxTop 0; # on all the rows, biggest top distance
            set maxBottom 0;
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

    method focusLeft {} {
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

    method focusUp {} {
        set down [expr {$gridHeight - ($wRow + $wHeight)}] 
        if {$down < 0} {
            set top 0
            for {set i [expr {$wRow - 1}]} {$i >= 0} {incr i -1} {
                for {set j $wCol} {$j < ($wCol + $wWidth)} {incr j} {
                    if {! ([cell [list $i $j]] eq {})} {
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

    method optimizeScreenSpace {} { focusLeft; focusUp }

    method mkGrid {} {
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
                set objId [id [cell $absolutePos]] 
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
            updateState $o
            applyNormalHooks $o
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

    method forEachObject {msg} {
        foreach {xy o} [array get objects] {
            catch {$o {*}$msg}
        }
    }

    method z {} {
        foreach {pos o} [array get objects] {
            $o z
        }
    }

    method cell {gridPos} {
        if {[info exists grid([lindex $gridPos 0],[lindex $gridPos 1])]} {
            return $grid([lindex $gridPos 0],[lindex $gridPos 1])
        } else {
            return {}
        }
    }

    method id {cell} {
        if {! ($cell eq {})} {
            if {[llength $cell] == 3} {
                return [::dinah::dbLGet [lindex $cell 0] [list [lindex $cell 1] [lindex $cell 2]]]
            } else {
                return $cell; # the grid has only one cell which is not on the x and y dimensions
            }
        }
        return {}
    }

    method insideW {row col} {
        return [expr {( ( $wCol  <= $col  ) && ( $col  < ($wCol + $wWidth)   ) ) &&
                      ( ( $wRow <= $row ) && ( $row < ($wRow + $wHeight) ) )}]
    }

    method new {type {delta 1}} {
        if { [::dinah::editable $x] } {
            if { !( $sc eq {} ) } {
                set dbid [scId]
                set newX {}
                set newId [::dinah::emptyNode $type]
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
                ::dinah::dbSet $x $newX
            } else {
                set newId [::dinah::emptyNode $type]
                ::dinah::dbAppend $x [list $newId]
            }
            buildAndGrid $newId
        }
    }

    method reload {} { buildAndGrid [scId] }

    method updateEntries {} {
        [$x_entry w] delete 0 end
        [$x_entry w] insert end $x
        [$y_entry w] delete 0 end
        [$y_entry w] insert end $y
    }

    method copy {} {
        clearClipboard
        ::dinah::dbAppend $::dinah::dimClipboard [list [scId]]
    }

    method copycat {} {
        set l [::dinah::dbLGet $::dinah::dimClipboard 0]
        lappend l [scId]
        ::dinah::dbSet $::dinah::dimClipboard [list $l]
    }

    method scCell {} { return [cell [list [scRowIndex] [scColumnIndex]]] }
    method scDimName {} { return [lindex [scCell] 0] }
    method scDimIndex {} { return [lindex [scCell] 1] }
    method scItemIndex {} { return [lindex [scCell] 2] }
    method scId {} { return [id [scCell]] }

    method scRowEmpty {} { return [expr {([llength [scCell]] != 3) || ([scDimName] ne $x)}] }

    method scRow {} {
        if {! [scRowEmpty]} {
            return [::dinah::dbLGet $x [scDimIndex]]
        } else {
            return {}
        }
    }

    method scOnLastItem {} {
        return [expr {[scItemIndex] == ([llength [scRow]] - 1)}]
    }

    method deleteRow {} {
        if {[::dinah::editable $x] && [scRow] != {}} {
            set cursor [scId]
            ::dinah::dbSet $x [lreplace [::dinah::dbGet $x] [scDimIndex] [scDimIndex]]
            buildAndGrid $cursor
        }
    }

    method delete {} {
        set scRow [scRow]
        if {[::dinah::editable $x] && [scRow] != {}} {
            if {[llength [scRow]] == 1} {
                set newScId {}
                ::dinah::dbSet $x [lreplace [::dinah::dbGet $x] [scDimIndex] [scDimIndex]]
            } else {
                if {[scOnLastItem]} {
                    set newScId [lindex [scRow] end-1]
                } else {
                    set newScId [lindex [scRow] [expr {[scItemIndex] + 1}]]
                }
                set newScRow [lreplace [scRow] [scItemIndex] [scItemIndex]]
                ::dinah::dbLSet $x [scDimIndex] $newScRow
            }
            buildAndGrid $newScId
        }
    }

    method clipboardLastItem {} {
        return [::dinah::dbLGet $::dinah::dimClipboard {0 end}]
    }

    method newRow? {} { return [expr {(! [dimIsNil]) && (! [clipboardEmpty]) && [scRowEmpty]}] }

    method noCycleOrDuplicate {} {
        return [expr {(! [dimIsNil]) && (! [clipboardEmpty]) && (! [scRowEmpty]) && (! [pastingCycle]) && (! [pastingDuplicate])}]
    }

    method pastingCycle {} {
        if {[clipboardLastItem] in [scRow]} {
            return 1
        } else {
            return 0
        }
    }

    method pastingDuplicate {} {
        set scDimLength [llength [::dinah::dbGet [scDimName]]]
        for {set i 0} {$i < $scDimLength} {incr i} {
            if {$i != [scDimIndex]} {
                if {[clipboardLastItem] in [::dinah::dbLGet [scDimName] $i]} {
                    # item appearing twice in a dimension
                    return 1
                }
            }
        }
        return 0
    }

    method dimIsNil {} {
        if {$x eq "d.nil"} {
            return 1
        } else {
            return 0
        }
    }

    method clipboardEmpty {} {
        return [expr {[clipboardLastItem] == {}}]
    }

    method pasteIntoNewList {} {
        if {(! [dimIsNil]) && (! [clipboardEmpty])} {
            ::dinah::dbAppend $x [list [clipboardLastItem]]
            buildAndGrid [clipboardLastItem]
        }
    }
 
    method newListWithTxtNode {} {
        if {! [dimIsNil]} {
            set txtId [::dinah::emptyNode Txt]
            ::dinah::dbAppend $x [list $txtId]
            buildAndGrid $txtId
        }
    }

    method newRowFromPasteBefore {} {
        if {[::dinah::findInDim $x [clipboardLastItem]] == {}} {
            ::dinah::dbAppend $x [lsearch -not -exact -all -inline [list [clipboardLastItem] [scId]] {}]
        }
    }

    method newRowFromPasteAfter {} {
        if {[::dinah::findInDim $x [clipboardLastItem]] == {}} {
            ::dinah::dbAppend $x [lsearch -not -exact -all -inline [list [scId] [clipboardLastItem]] {}]
        }
    }

    method pasteClipboard {} {
        if {[::dinah::editable $x]} {
            set row {}
            foreach frag [::dinah::dbLGet $::dinah::dimClipboard 0] {
                if {[::dinah::findInDim $x $frag] == {}} {
                    lappend row $frag
                } else {
                    return
                }
            }
            if {$row != {}} {
                ::dinah::dbAppend $x $row
                buildAndGrid [lindex $row 0]
            }
        }
    }

    method clearClipboard {} {
        ::dinah::dbSet $::dinah::dimClipboard {}
    }

    method copySegmentToClipboard {} {
        clearClipboard
        ::dinah::dbAppend $::dinah::dimClipboard [::dinah::dbLGet $x [scDimIndex]]
    }

    method pasteBefore {} {
        if {[::dinah::editable $x]} {
            if {[newRow?]} {
                newRowFromPasteBefore
                buildAndGrid [scId]
            } elseif {[noCycleOrDuplicate]} {
                set newScRow [linsert [scRow] [scItemIndex] [clipboardLastItem]]
                ::dinah::dbLSet $x [scDimIndex] $newScRow
                buildAndGrid [scId]
            }
        }
    }

    method pasteAfter {} {
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
                set newScRow [linsert [scRow] $newItemIndex [clipboardLastItem]]
                ::dinah::dbLSet $x [scDimIndex] $newScRow
                buildAndGrid [scId]
            }
        }
    }

    method cut {} {copycat; delete}

    method newWindow {} { focus [[::dinah::Container #auto] mkWindow] }

    method newWhiteboard {} {
        set d [::dinah::Whiteboard #auto]
        focus [$d mkWindow]
    }

    method newWindowOnCursor {} {
        ::dinah::dimWin [scId]
    }

    method newTreeOnCursor {} {
        if {([scId] != {}) && ($x ne "") && ($y ne "")} {
            [[$tree setRoot [scId]] setDim $x $y] load
        }
    }

    method nextList {{direction 1}} {
        if {![scRowEmpty]} {
            buildAndGrid [::dinah::dbLGet $x [list [expr {([scDimIndex] + $direction) % [llength [::dinah::dbGet $x]]}] 0]]
        }
    }
}
