itcl::class Dim {
    private variable x ""; # name of the x dimension 
    private variable y ""; # name of the y dimension 
    private variable clipboard "d.clipboard"
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

    constructor {} {
        set modes(names) {nil navigation transcription notice}
        set modes(current) 0
        set modes(index) 0
        set modes(nil) {{1 1 {d.nil d.nil}}}
        set modes(navigation) {{4 4 {d.insert d.sameLevel} {hookNbArchivePages} {hookInitNavigation}} {1 4 {d.archive d.sameLevel}}}
        set modes(transcription) {{1 2 {d.transcription d.archive}}}
        set modes(notice) {{1 1 {d.nil d.nil} {} {hookInitNotice}} {4 4 {d.noticeLevel d.noticeElement}}}
    }

    public method mkWindow {{parent {}}}
    public method query {}
    public method setX {dimension}
    public method getX {}
    public method setY {dimension}
    public method getY {}
    public method setWCol {j}
    public method setWRow {i}
    public method setWWidth {nbColumns}
    public method setWHeight {nbRows}
    public method incrWWidth {delta}
    public method incrWHeight {delta}
    private method wHoriz {delta}
    private method wVertic {delta}
    public method wRight {}
    public method wLeft {}
    public method wUp {}
    public method wDown {}
    private method scHoriz {delta}
    public method scRight {}
    public method scLeft {}
    private method scVertic {delta}
    public method scDown {}
    public method scUp {}
    public method buildBoard {{cid {}}}
    public method mkGrid {}
    public method reload {}
    public method updateEntries {}
    public method new {type}
    public method copy {}
    public method copycat {}
    public method delete {}
    public method newWindow {}
    public method newWhiteboard {}
    public method newWindowOnCursor {}
    private method optimizeScreenSpace {}
    private method focusLeft {}
    private method focusUp {}
    public method scRowIndex {}
    public method scRow {}
    public method scColumnIndex {}
    private method initGrid {}
    private method id {cell}
    private method cell {gridPos}
    private method insideW {row col}
    public method updateInfo {}
    private method scCell {}
    private method scDimName {}
    private method scDimIndex {}
    private method scItemIndex {}
    public method scId {}
    private method scRowEmpty {}
    public method pasteBefore {}
    public method pasteAfter {}
    private method clipboardEmpty {}
    private method dimIsNil {}
    private method pastingDuplicate {}
    private method pastingCycle {}
    private method noCycleOrDuplicate {}
    private method newRow? {}
    private method newRowFromPasteBefore {}
    private method newRowFromPasteAfter {}
    private method clipboardLastItem {}
    private method scOnLastItem {}
    public method cut {}
    public method deleteRow {}
    private method scDim {}
    public method wHorizByOneScreen {{direction 1}}
    public method swapDim {}
    public method switchScDimsX {}
    public method switchScDimsY {}
    public method nextMode {}
    public method setMode {modeIndex}
    public method nextModeDim {}
    public method setModeDim {}
    public method getModeHooks {hookType}
    public method applyNormalHooks {o}
    public method applyInitHooks {}
    public method nextList {{direction 1}}
    public method pasteIntoNewList {}
    public method newListWithTxtNode {}
    public method setBindings {}
    public method unsetBindings {}
    public method storeState {id cmd args}
    public method updateState {obj}
    public method hookNbArchivePages {id}
    public method hookInitNotice {}
    public method hookInitNavigation {}
    public method pasteClipboard {}
    public method newTreeOnCursor {}
    public method openTreeItem {item}
    public method blank {}
    public method quickZoom {}
    public method editZones {}
    public method z {}
    public method updateNumModifier {k}
    public method getNumModifier {}
    public method zeroKey {}
    public method gotoRowEnds {where}
    public method gotoRowStart {}
    public method gotoRowEnd {}
    public method initNumModifier {}
    public method dropmenu {target src x y op type data}
    public method setContainer {c}
    public method getContainer {}
    public method buildAndGrid {id}
    public method getFocus {}
    public method setOnMoveCursor {code}
    public method getTopFrame {}
    public method msgGoto {}
    public method msgGotoOK {}
    public method goto {match}
}

itcl::body Dim::getTopFrame {} { 
    return $t
}

itcl::body Dim::setOnMoveCursor {code} { 
    set onMoveCursor $code
}

itcl::body Dim::getFocus {} { focus $t }

itcl::body Dim::buildAndGrid {id} {
    buildBoard $id
    mkGrid
}

itcl::body Dim::setContainer {c} {
    set container $c
}

itcl::body Dim::getContainer {} {
    return $container
}

itcl::body Dim::gotoRowEnds {where} {
    set r [scRow]
    if {$r != {}} {
        buildBoard [lindex $r $where]
        mkGrid
    }
}

itcl::body Dim::gotoRowEnd {} { gotoRowEnds "end" }

itcl::body Dim::gotoRowStart {} { gotoRowEnds 0 }

itcl::body Dim::zeroKey {} {
    if {$numModifier ne ""} {updateNumModifier "0"} else {gotoRowStart}
}

itcl::body Dim::initNumModifier {} {
    set numModifier ""
}

itcl::body Dim::getNumModifier {} {
    if {$numModifier eq ""} {return "1"}
    return $numModifier
}

itcl::body Dim::updateNumModifier {k} {
    set numModifier [join [list $numModifier $k] ""] 
}

itcl::body Dim::quickZoom {} {
    if {[info exists objects($sc)]} {
        catch {$objects($sc) quickZoom}
    }
}

itcl::body Dim::editZones {} {
    if {[info exists objects($sc)]} {
        catch {$objects($sc) editZones}
    }
}

itcl::body Dim::mkWindow {{parent {}}} {
    variable ::dinah::db
    if {$parent == {}} {
        set t [::dinah::newToplevel .t[::dinah::objname $this]] 
    } else {
        set t $parent
    }
    set f [frame $t.frame -borderwidth 1 -bg black -highlightcolor green -highlightthickness 1]
    frame $f.menu
    label $f.menu.x_label -text "X: "
    set x_entry [::dinah::Autocomplete x_entry#auto $f.menu.x_entry $db(dimensions)]
    label $f.menu.y_label -text "Y: "
    set y_entry [::dinah::Autocomplete y_entry#auto $f.menu.y_entry $db(dimensions)]
    button $f.menu.ok -text "OK" -command [list $this query]
    entry $f.menu.label
    bindtags $f.menu.label [list $f.menu.label [winfo class $f.menu.label] all]
    bind $f.menu.label <Key-Escape> [list focus $t]
    set resolutionLabel [label $f.menu.resolution -text ""]
    pack $f.menu.x_label -side left -padx 4 -pady 4
    pack $f.menu.x_entry -side left -padx 4 -pady 4
    pack $f.menu.y_label -side left -padx 4 -pady 4
    pack $f.menu.y_entry -side left -padx 4 -pady 4
    pack $f.menu.ok -side left -padx 4 -pady 4
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
    set modeMenu [menu $dimMenu.modeMenu]
    $dimMenu add command -label "swap dim" -command [list $this swapDim]
    $dimMenu add cascade -label "mode" -menu $modeMenu
    $modeMenu add command -label "nil" -command [list $this setMode 0]
    $modeMenu add command -label "navigation" -command [list $this setMode 1]
    $modeMenu add command -label "transcription" -command [list $this setMode 2]
    $modeMenu add command -label "notice" -command [list $this setMode 3]
    $dimMenu add command -label "exit" -command {exit}
    $dimMenu add command -label "nouvelle fenetre" -command {
        set c0 [::dinah::Container #auto]
        focus [$c0 mkWindow]
    }
    bind $f.menu $::dinah::mouse(B3) [list tk_popup $dimMenu %X %Y]
    bind $f.menu <1> [list focus $t]
    bind $f.menu <1> +[list $this updateInfo]

    DropSite::register $f.menu -dropcmd [list $this dropmenu] -droptypes {Obj copy}

    initGrid

    setBindings

    #wm attributes $t -fullscreen 1
    focus $t
    pack $f -side top -fill both -expand yes
    return $t
}

itcl::body Dim::dropmenu {target src xcoord ycoord op type data} {
    set srcId [lindex $data end]
    set found [::dinah::findInDim $x $srcId]
    if {$found != {}} {
        buildBoard $srcId
        mkGrid
    } else {
        if {[::dinah::editable $x]} {
            lappend ::dinah::db($x) [list $srcId]
            buildBoard $srcId
            mkGrid
        }
    }
}

itcl::body Dim::openTreeItem {item} {
    set id [$tree itemId $item]
    buildBoard $id
    mkGrid
}

itcl::body Dim::hookInitNotice {} {
    variable ::dinah::db
    if {$::dinah::db([scId],isa) eq "Page"} {
        set found [::dinah::findInDim $::dinah::dimNoticeLevel [scId]]
        if {[llength $found] == 0} {
            set fragment {}
            lappend fragment [scId] 
            set titrePropre [::dinah::emptyNode Txt "titre propre"]
            lappend fragment $titrePropre
            lappend ::dinah::db($::dinah::dimNoticeLevel) $fragment
            set fragment {}
            lappend fragment $titrePropre
            lappend fragment [::dinah::emptyNode Txt "titre forgé"]
            lappend fragment [::dinah::emptyNode Date "date"]
            lappend fragment [::dinah::emptyNode Txt "notes datation"]
            lappend fragment [::dinah::emptyNode Txt "description intellectuelle"]
            lappend fragment [::dinah::emptyNode Txt "sommaire"]
            lappend fragment [::dinah::emptyNode Txt "notes scientifiques publiques"]
            lappend fragment [::dinah::emptyNode Txt "notes scientifiques privées"]
            lappend fragment [::dinah::emptyNode Txt "notes archivistiques publiques"]
            lappend fragment [::dinah::emptyNode Txt "notes archivistiques privées"]
            lappend fragment [::dinah::emptyNode Txt "autres notes publiques"]
            lappend fragment [::dinah::emptyNode Txt "autres notes privées"]
            lappend ::dinah::db($::dinah::dimNoticeElement) $fragment
        }
        [[$tree setRoot [scId]] setDim $::dinah::dimNoticeLevel $::dinah::dimNoticeElement] load
    }
}

itcl::body Dim::hookInitNavigation {} {
    variable ::dinah::db
    if {$::dinah::db([scId],isa) eq "Page"} {
        [[$tree setRoot [scId]] setDim "d.insert" "d.sameLevel"] load
    }
}

itcl::body Dim::hookNbArchivePages {obj} {
    variable ::dinah::db
    set dbid [$obj cget -dbid]
    set found [::dinah::findInDim "d.archive" $dbid]
    if {[llength $found] != 0} {
        set nbPages [llength [lindex $db(d.archive) [lindex $found 0]]]
        $obj notificate "$nbPages page(s)"
    }
}

itcl::body Dim::storeState {id cmd args} {
    lappend states [list $id $cmd $args]
}

itcl::body Dim::updateState {obj} {
    foreach {id cmd args} [concat {*}[lsearch -all -inline -exact -index 0 $states [$obj cget -dbid]]] {
        eval $obj $cmd {*}$args
    }
}

itcl::body Dim::setBindings {} {
    if {[info exists objects($sc)]} { 
        [$objects($sc) cget -frame] configure -borderwidth $::dinah::fragmentBorderWidth -bg red
    }

    bind $t <Key-g> [list $this msgGoto]
    bind $t <Control-Key-e> [list $this unsetBindings]
    bind $t <Key-r> [list $this reload]
    bind $t <Control-Key-l> [list $this incrWWidth 1]
    bind $t <Control-Key-Right> [list $this incrWWidth 1]
    bind $t <Control-Key-j> [list $this incrWWidth -1]
    bind $t <Control-Key-Left> [list $this incrWWidth -1]
    bind $t <Control-Key-i> [list $this incrWHeight 1]
    bind $t <Control-Key-Up> [list $this incrWHeight 1]
    bind $t <Control-Key-k> [list $this incrWHeight -1]
    bind $t <Control-Key-Down> [list $this incrWHeight -1]
    bind $t <Key-l> [list $this scRight]
    bind $t <Key-Right> [list $this scRight]
    bind $t <Key-j> [list $this scLeft]
    bind $t <Key-Left> [list $this scLeft]
    bind $t <Key-k> [list $this scDown]
    bind $t <Key-Down> [list $this scDown]
    bind $t <Key-i> [list $this scUp]
    bind $t <Key-Up> [list $this scUp]
    bind $t <Control-Key-L> [list $this wRight]
    bind $t <Control-Key-J> [list $this wLeft]
    bind $t <Control-Key-K> [list $this wDown]
    bind $t <Control-Key-I> [list $this wUp]
    bind $t <Key-L> [list $this wHorizByOneScreen 1]
    bind $t <Shift-Key-Right> [list $this wHorizByOneScreen 1]
    bind $t <Key-J> [list $this wHorizByOneScreen -1]
    bind $t <Shift-Key-Left> [list $this wHorizByOneScreen -1]
    bind $t <Key-X> [list focus [$x_entry w]]
    bind $t <Key-x> [list $this switchScDimsX]
    bind $t <Key-Y> [list focus [$y_entry w]]
    bind $t <Key-y> [list $this switchScDimsY]
    bind $t <Return> [list $this query]
    bind $t <Key-z> [list $this quickZoom]
    bind $t <Control-Key-z> [list $this editZones]
    bind $t <Key-Z> [list $this z]
    bind $t <Key-n> [list $this new Txt]
    bind $t <Key-N> [list $this new Date]
    bind $t <Control-Key-N> [list $this new Struct]
    bind $t <Control-Key-r> [list $this new Link]
    bind $t <Control-Key-C> [list $this copy]
    bind $t <Control-Key-c> [list $this copycat]
    bind $t <Control-Key-V> [list $this pasteBefore]
    bind $t <Control-Key-v> [list $this pasteAfter]
    bind $t <Control-Key-x> [list $this cut]
    bind $t <Key-t> [list $this newWhiteboard]
    bind $t <Key-W> [list $this newWindow]
    bind $t <Key-w> [list $this newWindowOnCursor]
    bind $t <Key-a> [list $this newTreeOnCursor]
    bind $t <Key-d> [list $this deleteRow]
    bind $t <Key-s> [list $this swapDim]
    bind $t <Control-Key-q> {exit}
    #bind $t <Control-Key-w> [list ::dinah::destroyToplevel $t]
    bind $t <Control-Key-n> {::dinah::switchFocus+} 
    bind $t <Control-Key-p> {::dinah::switchFocus-} 
    bind $t <Key-m> [list $this nextMode]
    bind $t <space> [list $this nextModeDim]
    bind $t <Key-o> [list $this nextList 1]
    bind $t <Key-O> [list $this nextList -1]
    bind $t <Control-Key-o> [list $this pasteIntoNewList]
    bind $t <Control-Key-O> [list $this newListWithTxtNode]
    bind $t <Control-Key-a> [list $this pasteClipboard]
    bind $t <Control-Key-b> [list $this blank]
    foreach k {1 2 3 4 5 6 7 8 9} {
        bind $t <Key-$k> [list $this updateNumModifier $k]
    }
    bind $t <Key-0> [list $this zeroKey]
    bind $t <Key-dollar> [list $this gotoRowEnd]
}

itcl::body Dim::blank {} {
    set sc {}
    setX "d.nil"
    setY "d.nil"
    updateEntries
    setWWidth 4
    setWHeight 4
    query
}

itcl::body Dim::unsetBindings {} {
    foreach tag [bind $t] {
        bind $t $tag ""
    }
    if {[info exists objects($sc)]} {
        $objects($sc) setBindings
        [$objects($sc) cget -frame] configure -borderwidth $::dinah::fragmentBorderWidth -bg green
    }
}

itcl::body Dim::swapDim {} {
    set oldY $y
    setY $x
    setX $oldY
    $this updateEntries
    buildBoard [scId]
    mkGrid
}

itcl::body Dim::scDim {} {
    variable ::dinah::db
    set scDim {}
    set id [scId]
    set found 0
    if {$id ne {}} {
        foreach d $db(dimensions) {
            foreach l $db($d) {
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

itcl::body Dim::switchScDimsX {} {
    set scDimLength [llength $scDim]
    if {$scDimLength > 0} {
        setX [lindex $scDim [expr {$scDimXCursor % $scDimLength}]]
        updateEntries
        incr scDimXCursor
        buildBoard [scId]
        mkGrid
    }
}

itcl::body Dim::switchScDimsY {} {
    set scDimLength [llength $scDim]
    if {$scDimLength > 0} {
        setY [lindex $scDim [expr {$scDimYCursor % $scDimLength}]]
        updateEntries
        incr scDimYCursor
        buildBoard [scId]
        mkGrid
    }
}

itcl::body Dim::query {} {
    variable ::dinah::db
    setX [[$x_entry w] get]
    setY [[$y_entry w] get]
    ::dinah::newDim? $x
    ::dinah::newDim? $y
    buildBoard [scId]
    mkGrid
    #wm title $t "x: $x ; y: $y"
}

itcl::body Dim::initGrid {} {
    grid rowconfigure $g all -uniform {} -weight 0
    grid columnconfigure $g all -uniform {} -weight 0
    foreach {pos o} [array get objects] {
        grid forget [$o cget -frame]
        $o destructor
    }
}

itcl::body Dim::setX {dim} { set x $dim }
itcl::body Dim::getX {} { set x }

itcl::body Dim::setY {dim} { set y $dim }
itcl::body Dim::getY {} { set y }

itcl::body Dim::setWRow {i} { set wRow $i }

itcl::body Dim::setWCol {j} { set wCol $j }

itcl::body Dim::setWWidth {nbColumns} {
    if {$nbColumns > 0} {
        set wWidth $nbColumns
    }
}

itcl::body Dim::setWHeight {nbRows} {
    if {$nbRows > 0} {
        set wHeight $nbRows
    }
}

itcl::body Dim::incrWWidth {i} {
    setWWidth [expr {$wWidth + $i}]
    mkGrid
}

itcl::body Dim::incrWHeight {i} {
    setWHeight [expr {$wHeight + $i}]
    mkGrid
}

itcl::body Dim::wHorizByOneScreen {{direction 1}} {
    if { $busy } { return }
    if {[wHoriz [expr {$direction * $wWidth}]]} {
        set sc [list [scRowIndex] $wCol]
        [$objects($sc) cget -frame] configure -borderwidth $::dinah::fragmentBorderWidth -bg red
        updateInfo
    }
}

itcl::body Dim::wHoriz {i} {
    if {(($wCol + $i) >= 0) && (($wCol + $i) < $gridWidth)} {
        incr wCol $i
        mkGrid
        return 1
    }
    return 0
}

itcl::body Dim::wRight {} {
    wHoriz 1
}

itcl::body Dim::wLeft {} {
    wHoriz -1
}

itcl::body Dim::wVertic {i} {
    if {(($wRow + $i) >= 0) && (($wRow + $i) < $gridHeight)} {
        incr wRow $i
        mkGrid
    }
}

itcl::body Dim::wDown {} {
    wVertic 1
}

itcl::body Dim::wUp {} {
    wVertic -1
}

itcl::body Dim::scRowIndex {} {
    if {[llength $sc] == 2} {
        return [lindex $sc 0]
    } else {
        return {}
    }
}

itcl::body Dim::scColumnIndex {} {
    if {[llength $sc] == 2} {
        return [lindex $sc 1]
    } else {
        return {}
    }
}

itcl::body Dim::updateInfo {} {
    variable ::dinah::db
    set path ""
    if {[info exists db([scId],path)]} {
        set path $db([scId],path)
    }    
    $f.menu.label configure -textvariable ::dinah::db([scId],label)
    set scId [scId]
    set modeLabel [lindex $modes(names) $modes(current)]
    wm title [winfo toplevel $t] "x: $x ; y: $y ; id: $scId ; wWidth: $wWidth ; wHeight: $wHeight ; mode: $modeLabel ; $path"
    scDim
    eval $onMoveCursor
}

itcl::body Dim::setMode {modeIndex} {
    set modes(current) $modeIndex
    set modes(index) 0
    setModeDim
    applyInitHooks
}

itcl::body Dim::nextMode {} {
    if {$modes(current) + 1 == [llength $modes(names)]} {
        setMode 0
        set modes(current) 0
    } else {
        setMode [expr {$modes(current) + 1}]
    }
}

itcl::body Dim::nextModeDim {} {
    set modeName [lindex $modes(names) $modes(current)]
    if {$modes(index) + 1 == [llength $modes($modeName)]} {
        set modes(index) 0
    } else {
        incr modes(index)
    }
    setModeDim
}

itcl::body Dim::setModeDim {} {
    set modeName [lindex $modes(names) $modes(current)]
    set newDims [lindex $modes($modeName) $modes(index) 2]
    setX [lindex $newDims 0]
    setY [lindex $newDims 1]
    updateEntries
    setWWidth [lindex $modes($modeName) $modes(index) 1]
    setWHeight [lindex $modes($modeName) $modes(index) 0]
    query
}

itcl::body Dim::getModeHooks {hookType} {
    set modeName [lindex $modes(names) $modes(current)]
    set hooks [lindex $modes($modeName) $modes(index) $hookType]
}

itcl::body Dim::applyNormalHooks {obj} {
    foreach h [getModeHooks 3] {
        eval $h $obj
    }
}

itcl::body Dim::applyInitHooks {} {
    foreach h [getModeHooks 4] {
        eval $h
    }
}

itcl::body Dim::msgGoto {} {
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

itcl::body Dim::msgGotoOK {} {
    global gotoEntryValue
    goto $gotoEntryValue
    destroy .tGoto
}

itcl::body Dim::goto {match} {
    set row [lindex $::dinah::db([scDimName]) [scDimIndex]]
    for {set i 0} {$i < [llength $row]} {incr i} {
        if {[string match -nocase *$match* $::dinah::db([lindex $row $i],label)]} {
	    scHoriz [expr {$i - [scColumnIndex]}]
            return
        }
    }
}

itcl::body Dim::scHoriz {i} {
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
        set scDimXCursor 0
        set scDimYCursor 0
    }
}

itcl::body Dim::scRight {} {
    if {! $busy} { scHoriz [getNumModifier] ; initNumModifier }
}

itcl::body Dim::scLeft {} {
    if {! $busy} { scHoriz -[getNumModifier] ; initNumModifier }
}

itcl::body Dim::scVertic {i} {
    if {![insideW [scRowIndex] [scColumnIndex]]} {return}
    set newScRow [expr {[scRowIndex] + $i}]
    set exist [info exists grid($newScRow,[scColumnIndex])]
    if {$exist && !( $grid($newScRow,[scColumnIndex]) eq {} )} {
        buildBoard [id [cell [list $newScRow [scColumnIndex]]]]
        mkGrid
        set scDimXCursor 0
        set scDimYCursor 0
    }
}

itcl::body Dim::scDown {} {
    if {! $busy} { scVertic [getNumModifier] ; initNumModifier }
}

itcl::body Dim::scUp {} {
    if {! $busy} { scVertic -[getNumModifier] ; initNumModifier }
}

itcl::body Dim::buildBoard {{center {}}} {
    variable ::dinah::db
    set mainRow {}
    set mainRowIndex {}
    set cols {}
    array unset grid
    array set grid {}
    set sc {}
    if {[info exists db($x)]} {
        if {$center eq {}} {
            set center [lindex $db($x) 0 0]
        }
        if {$center eq {}} {
            return
        }
        # main row:
        set found [::dinah::findInDim $x $center]
        if {[llength $found] != 0} {
            set mainRowIndex [lindex $found 0]
            set mainRow [lindex $db($x) $mainRowIndex]
            set sc [list [lindex $found 1]]
        }
        set gridWidth [llength $mainRow]
        # cols:
        if {[info exists db($y)]} {
            if {$mainRow eq {}} {
                set found [::dinah::findInDim $y $center]
                if {[llength $found] != 0} {
                    set foundRow [lindex $found 0]
                    for {set k 0} {$k < [llength [lindex $db($y) $foundRow]]} {incr k} {
                        set grid($k,0) [list $y $foundRow $k]
                    }
                    set sc [list [lindex $found 1] 0]
                    set gridWidth 1
                    set gridHeight [llength [lindex $db($y) $foundRow]]
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
                        lappend cols [list [lindex $db($y) $foundRow] $foundRow [lindex $found 1]]
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

itcl::body Dim::focusLeft {} {
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

itcl::body Dim::focusUp {} {
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

itcl::body Dim::optimizeScreenSpace {} { focusLeft; focusUp }

itcl::body Dim::mkGrid {} {
    variable ::dinah::db
    set busy 1
    initGrid
    array unset objects
    array set pos {}

    optimizeScreenSpace
    set lastScreenRow 0
    set lastScreenCol 0
    array set id2obj {}
    for {set i 0} {$i < $wHeight} {incr i} {
        set nbCols 0
        for {set j 0} {$j < $wWidth} {incr j} {
            set absoluteI [expr {$wRow + $i}]
            set absoluteJ [expr {$wCol + $j}]
            set absolutePos [list $absoluteI $absoluteJ]
            set objId [id [cell $absolutePos]] 
            if {! ($objId eq {})} {
                set o [::dinah::mkObj $objId $g]
                lappend id2obj($objId) $o
                $o configure -container $this
                set objects($absolutePos) $o
                set pos([$o cget -frame]) $absolutePos
                set w [$o cget -frame]
                $o openNS
                if {[scRowIndex] == $absoluteI} {
                    $o openEW
                    if {[scColumnIndex] == $absoluteJ} {
                        $w configure -borderwidth $::dinah::fragmentBorderWidth -bg red
                    }
                } else {
                    $o closeEW
                }
                grid $w -column $j -row $i -sticky news
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

    grid rowconfigure $g all -uniform 1 -weight 1
    grid columnconfigure $g all -uniform 1 -weight 1
    updateInfo
    update

    foreach {xy o} [array get objects] {
        $o z
        updateState $o
        applyNormalHooks $o
    }

    if {[scRowIndex] ne {} && [insideW [scRowIndex] $wCol]} {
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

itcl::body Dim::z {} {
    foreach {pos o} [array get objects] {
        $o z
    }
}

itcl::body Dim::cell {gridPos} {
    if {[info exists grid([lindex $gridPos 0],[lindex $gridPos 1])]} {
        return $grid([lindex $gridPos 0],[lindex $gridPos 1])
    } else {
        return {}
    }
}

itcl::body Dim::id {cell} {
    variable ::dinah::db
    if {! ($cell eq {})} {
        if {[llength $cell] == 3} {
            return [lindex $db([lindex $cell 0]) [lindex $cell 1] [lindex $cell 2]]
        } else {
            return $cell; # the grid has only one cell which is not on the x and y dimensions
        }
    }
    return {}
}

itcl::body Dim::insideW {row col} {
    return [expr {( ( $wCol  <= $col  ) && ( $col  < ($wCol + $wWidth)   ) ) &&
                  ( ( $wRow <= $row ) && ( $row < ($wRow + $wHeight) ) )}]
}

itcl::body Dim::new {type} {
    variable ::dinah::db
    if { [::dinah::editable $x] } {
        if { !( $sc eq {} ) } {
            set dbid [scId]
            set newX {}
            set newId [::dinah::emptyNode $type]
            set found 0
            foreach l $db($x) {
                set i [lsearch $l $dbid]
                if {$i > -1} {
                    lappend newX [linsert $l [expr {$i + 1}] $newId]
                    set found 1
                } else {
                    lappend newX $l 
                }
            }
            if {! $found} {
                lappend newX [list $dbid $newId]
            }
            set db($x) $newX
        } else {
            set newId [::dinah::emptyNode $type]
            lappend db($x) [list $newId]
        }
        buildBoard $newId
        mkGrid
        unsetBindings
    }
}

itcl::body Dim::reload {} {
    buildBoard [scId]
    mkGrid
}

itcl::body Dim::updateEntries {} {
    [$x_entry w] delete 0 end
    [$x_entry w] insert end $x
    [$y_entry w] delete 0 end
    [$y_entry w] insert end $y
}

itcl::body Dim::copy {} {
    variable ::dinah::db
    set db($clipboard) {}
    lappend db($clipboard) [list [scId]]
}

itcl::body Dim::copycat {} {
    variable ::dinah::db
    set l [lindex $db($clipboard) 0]
    lappend l [scId]
    set db($clipboard) [list $l]
}

itcl::body Dim::scCell {} { return [cell [list [scRowIndex] [scColumnIndex]]] }
itcl::body Dim::scDimName {} { return [lindex [scCell] 0] }
itcl::body Dim::scDimIndex {} { return [lindex [scCell] 1] }
itcl::body Dim::scItemIndex {} { return [lindex [scCell] 2] }
itcl::body Dim::scId {} { return [id [scCell]] }

itcl::body Dim::scRowEmpty {} {
    return [expr {([llength [scCell]] != 3) || ([scDimName] ne $x)}]
}

itcl::body Dim::scRow {} {
    variable ::dinah::db
    if {! [scRowEmpty]} {
        return [lindex $db($x) [scDimIndex]]
    } else {
        return {}
    }
}

itcl::body Dim::scOnLastItem {} {
    return [expr {[scItemIndex] == ([llength [scRow]] - 1)}]
}

itcl::body Dim::deleteRow {} {
    variable ::dinah::db
    if {[::dinah::editable $x] && [scRow] != {}} {
        set cursor [scId]
        set db($x) [lreplace $db($x) [scDimIndex] [scDimIndex]]
        buildBoard $cursor
        mkGrid
    }
}

itcl::body Dim::delete {} {
    variable ::dinah::db
    set scRow [scRow]
    if {[::dinah::editable $x] && [scRow] != {}} {
        if {[llength [scRow]] == 1} {
            set newScId {}
            set db($x) [lreplace $db($x) [scDimIndex] [scDimIndex]]
        } else {
            if {[scOnLastItem]} {
                set newScId [lindex [scRow] end-1]
            } else {
                set newScId [lindex [scRow] [expr {[scItemIndex] + 1}]]
            }
            set newScRow [lreplace [scRow] [scItemIndex] [scItemIndex]]
            lset db($x) [scDimIndex] $newScRow
        }
        buildBoard $newScId
        mkGrid
    }
}

itcl::body Dim::clipboardLastItem {} {
    variable ::dinah::db
    return [lindex [lindex $db($clipboard) 0] end]
}

itcl::body Dim::newRow? {} {
    return [expr {(! [dimIsNil]) && (! [clipboardEmpty]) && [scRowEmpty]}]
}

itcl::body Dim::noCycleOrDuplicate {} {
    return [expr {(! [dimIsNil]) && (! [clipboardEmpty]) && (! [scRowEmpty]) && (! [pastingCycle]) && (! [pastingDuplicate])}]
}

itcl::body Dim::pastingCycle {} {
    if {[clipboardLastItem] in [scRow]} {
        # cycle
        puts "cycle"
        return 1
    }
    return 0
}

itcl::body Dim::pastingDuplicate {} {
    variable ::dinah::db
    set scDimLength [llength $db([scDimName])]
    for {set i 0} {$i < $scDimLength} {incr i} {
        if {$i != [scDimIndex]} {
            if {[clipboardLastItem] in [lindex $db([scDimName]) $i]} {
                # item appearing twice in a dimension
                puts "item appearing twice in a dimension"
                return 1
            }
        }
    }
    return 0
}

itcl::body Dim::dimIsNil {} {
    if {$x eq "d.nil"} {
        puts "dim is d.nil"
        return 1
    }
    return 0
}

itcl::body Dim::clipboardEmpty {} {
    return [expr {[clipboardLastItem] == {}}]
}

itcl::body Dim::pasteIntoNewList {} {
    variable ::dinah::db
    if {(! [dimIsNil]) && (! [clipboardEmpty])} {
        lappend db($x) [list [clipboardLastItem]]
        buildBoard [clipboardLastItem]
        mkGrid
    }
}
 
itcl::body Dim::newListWithTxtNode {} {
    variable ::dinah::db
    if {! [dimIsNil]} {
        set txtId [::dinah::emptyNode Txt]
        lappend db($x) [list $txtId]
        buildBoard $txtId
        mkGrid
    }
}

itcl::body Dim::newRowFromPasteBefore {} {
    variable ::dinah::db
    if {[::dinah::findInDim $x [clipboardLastItem]] == {}} {
        lappend db($x) [lsearch -not -exact -all -inline [list [clipboardLastItem] [scId]] {}]
    }
}

itcl::body Dim::newRowFromPasteAfter {} {
    variable ::dinah::db
    if {[::dinah::findInDim $x [clipboardLastItem]] == {}} {
        lappend db($x) [lsearch -not -exact -all -inline [list [scId] [clipboardLastItem]] {}]
    }
}

itcl::body Dim::pasteClipboard {} {
    variable ::dinah::db
    if {[::dinah::editable $x] && [newRow?] && ([scId] == {})} {
        set row {}
        foreach frag [lindex $db($clipboard) 0] {
            if {[::dinah::findInDim $x $frag] == {}} {
                lappend row $frag
            } else {
                return
            }
        }
        if {$row != {}} {
            lappend db($x) $row
            buildBoard [lindex $db($clipboard) 0 0]
            mkGrid
        }
    }
}

itcl::body Dim::pasteBefore {} {
    variable ::dinah::db
    if {[::dinah::editable $x]} {
        if {[newRow?]} {
            newRowFromPasteBefore
            buildBoard [scId]
            mkGrid
        } elseif {[noCycleOrDuplicate]} {
            set newScRow [linsert [scRow] [scItemIndex] [clipboardLastItem]]
            lset db($x) [scDimIndex] $newScRow
            buildBoard [scId]
            mkGrid
        }
    }
}

itcl::body Dim::pasteAfter {} {
    variable ::dinah::db
    if {[::dinah::editable $x]} {
        if {[newRow?]} {
            newRowFromPasteAfter
            buildBoard [scId]
            mkGrid
        } elseif {[noCycleOrDuplicate]} {
            if {[scOnLastItem]} {
                set newItemIndex end
            } else {
                set newItemIndex [expr {[scItemIndex] + 1}]
            }
            set newScRow [linsert [scRow] $newItemIndex [clipboardLastItem]]
            lset db($x) [scDimIndex] $newScRow
            buildBoard [scId]
            mkGrid
        }
    }
}

itcl::body Dim::cut {} {copycat; delete}

itcl::body Dim::newWindow {} {
    set d [::dinah::Dim dim#auto]
    focus [$d mkWindow]
}

itcl::body Dim::newWhiteboard {} {
    set d [::dinah::Whiteboard #auto]
    focus [$d mkWindow]
}

itcl::body Dim::newWindowOnCursor {} {
    ::dinah::dimWin [scId]
}

itcl::body Dim::newTreeOnCursor {} {
    if {([scId] != {}) && ($x ne "") && ($y ne "")} {
        [[$tree setRoot [scId]] setDim $x $y] load
    }
}

itcl::body Dim::nextList {{direction 1}} {
    variable ::dinah::db
    if {![scRowEmpty]} {
        buildBoard [lindex $db($x) [expr {([scDimIndex] + $direction) % [llength $db($x)]}] 0]
        mkGrid
    }
}
