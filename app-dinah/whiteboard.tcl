itcl::class Whiteboard {
    private variable t ""
    private variable c ""
    private variable f ""
    private variable milliseconds {}
    private variable movefactor 1
    private variable sizeOfCanvas 10000
    private variable alphabeta {A B C D E F G H I J K L M N O P Q R S T U V W X Y Z}
    private variable boardNumber 0
    private variable b
    private variable d
    private variable edges {}
    private variable colors
    private variable currentDim
    private variable menu ""

    constructor {} {
        array set b {}
        array set d {}
        array set colors {1 black 2 red 3 green 4 orange 5 blue}
    }

    public method mkWindow {{parent {}}}
    public method setBindings {}
    public method unsetBindings {}
    public method add {id {x 20} {y 20}}
    public method delete {{id ""}}
    public method move {x y}
    public method moveItem {w x y}
    public method scan {x y {gain 3}}
    public method setCursor {k}
    public method setCursorOnId {id}
    public method removeCursor {}
    public method resize {x y}
    public method getIndiceFromItem {w}
    public method getIdFromItem {w}
    public method getItemFromIndice {k}
    public method getItemFromId {id}
    public method centerCoord {view}
    public method center {}
    public method storeState {id cmd args}
    public method itemO {k}
    public method paste {}
    public method dimWinOnCursor {}
    public method gotoBoard {k}
    public method loadItem {k id x y {width ""} {height ""}}
    public method savePosition {}
    public method saveSize {}
    public method newText {}
    public method high {}
    public method low {}
    public method reload {}
    public method okDim {i}
    public method addEdge {from to {options {}}}
    public method computeEdges {item}
    public method updateEdges {item}
    public method updateEdge {i}
    public method saveDim {i}
    public method getCurrentDim {}
    public method cleanBoard {}
    public method dragAndDrop {}
    public method dropcmd {target src x y op type data}
    public method getFreeLetter {}
    public method expand {id offset}
    public method next {id}
    public method prev {id}
    public method getCanvas {}
    public method boardx {x}
    public method boardy {y}
    public method newNode {type x y}
    public method newNodeAtClick {type}
    public method backgroundMenu {x y}
}

itcl::body Whiteboard::getCanvas {} {
    return $c
}

itcl::body Whiteboard::expand {id offset} {
    puts "expand"
    set found [::dinah::findInDim $currentDim $id]
    if {$found ne {}} {
        puts "found: $found"
        set si [lindex $found 0]; set fi [lindex $found 1]
        set otherId [lindex [lindex $::dinah::db($currentDim) $si] [expr {$fi + $offset}]]
        puts "otherId: $otherId"
        if {$otherId ne "" && [getItemFromId $otherId] eq ""} {
            set item [getItemFromId $id]
            puts "item: $item"
            set coords [$c coords $item]
            puts "coords: $coords"
            set bbox [$c bbox $item]
            set width [expr {[lindex $bbox 2] - [lindex $bbox 0]}]
            add $otherId [expr {[lindex $coords 0] + $offset * ($width + 20)}] [lindex $coords 1]
        }
    }
}

itcl::body Whiteboard::next {id} {
    expand $id 1
}

itcl::body Whiteboard::prev {id} {
    expand $id -1
}

itcl::body Whiteboard::dragAndDrop {} {
    DropSite::register $c -dropcmd [list $this dropcmd] -droptypes {Obj copy}
}

itcl::body Whiteboard::boardx {x} {
    expr {[$c canvasx $x] - [winfo rootx $c]}
}

itcl::body Whiteboard::boardy {y} {
    expr {[$c canvasx $y] - [winfo rooty $c]}
}

itcl::body Whiteboard::dropcmd {target src x y op type data} {
    set id [lindex $data end]
    if {[getItemFromId $id] eq ""} {
        add $id [boardx $x] [boardy $y]
    }
}

itcl::body Whiteboard::saveDim {i} {
    set ::dinah::db(board$boardNumber,dim$i) [$d($i) get]
}

itcl::body Whiteboard::computeEdges {item} {
    foreach {k entry} [array get d] {
        set color $colors($k)
        set dim [$entry get]
        set found [::dinah::findInDim $dim [getIdFromItem $item]]
        if {$found ne ""} {
            set s [lindex $::dinah::db($dim) [lindex $found 0]]
            set itemIndice [lindex $found 1]
            foreach other [$c find withtag object] {
                if {$other ne $item} {
                    set otherIndice [lsearch $s [getIdFromItem $other]]
                    if {$otherIndice > -1} {
                        if {$itemIndice == $otherIndice - 1} {
                            addEdge $item $other [list -fill $color]
                        } elseif {$itemIndice == $otherIndice + 1} {
                            addEdge $other $item [list -fill $color]
                        } elseif {$itemIndice < $otherIndice} {
                            addEdge $item $other [list -fill $color -dash -]
                        } elseif {$itemIndice > $otherIndice} {
                            addEdge $other $item [list -fill $color -dash -]
                        }
                    }
                }
            }
        }
    }
}

itcl::body Whiteboard::updateEdges {item} {
    foreach e [lsearch -index 1 -exact -all $edges $item] {
        updateEdge $e
    }
    foreach e [lsearch -index 2 -exact -all $edges $item] {
        updateEdge $e
    }
}

itcl::body Whiteboard::updateEdge {i} {
    set l [lindex $edges $i]
    set edges [lreplace $edges $i $i]
    $c delete [lindex $l 0]
    addEdge [lindex $l 1] [lindex $l 2] [lindex $l 3]
}

itcl::body Whiteboard::addEdge {from to {options {}}} {
    variable ::dinah::db
    foreach {x0 y0 x2 y2} [$c bbox $from] break
    set x1 [expr {($x0+$x2)/2.}]
    set y1 [expr {($y0+$y2)/2.}]
    foreach {x3 y3 x5 y5} [$c bbox $to] break
    set x4 [expr {($x3+$x5)/2.}]
    set y4 [expr {($y3+$y5)/2.}]
    if {$x1<$x2 && $x4>$x2} {set x1 $x2} ;# crop coordinates
    if {$x4>$x3 && $x1<$x3} {set x4 $x3}
    if {$y1<$y2 && $y4>$y2} {set y1 $y2}
    if {$y4>$y3 && $y1<$y3} {set y4 $y3}
    if {$x1>$x0 && $x4<$x0} {set x1 $x0}
    if {$x4<$x5 && $x1>$x5} {set x4 $x5}
    if {$y1>$y0 && $y4<$y0} {set y1 $y0}
    if {$y4<$y5 && $y1>$y5} {set y4 $y5}
    set line [$c create line $x1 $y1 $x4 $y4 -tag edge -arrow last {*}$options]
    ::dinah::ladd edges [list $line $from $to $options]
    return $line
}

itcl::body Whiteboard::okDim {i} {
    saveDim $i
    reload
    set currentDim [$d($i) get]
}

itcl::body Whiteboard::getCurrentDim {} { set currentDim }

itcl::body Whiteboard::mkWindow {{parent {}}} {
    if {$parent == {}} {
        set t [::dinah::newToplevel .t[::dinah::objname $this]] 
    } else {
        set t $parent
    }
    set f [frame $t.f -borderwidth 1 -bg black]
    set m [frame $t.m -borderwidth 1 -bg black]
    foreach i {1 2 3 4 5} {
        ::dinah::Autocomplete #auto $m.dim$i $::dinah::db(dimensions)
        set d($i) $m.dim$i
        pack $m.dim$i -side left -padx 4 -pady 4
        set b($i) [button $m.color$i -text "__?__" -background $colors($i)]
        $b($i) configure -command [list $this okDim $i]
        pack $b($i) -side left -padx 4 -pady 4
    }
    pack $m -side top -fill x
    set c [canvas $f.c -xscrollcommand [list $f.xscroll set] -yscrollcommand [list $f.yscroll set] -highlightthickness 0 -borderwidth 0 -scrollregion [list 0 0 $sizeOfCanvas $sizeOfCanvas] -xscrollincrement 1 -yscrollincrement 1] 
    set xscroll [scrollbar $f.xscroll -orient horizontal -command [list $c xview]]
    set yscroll [scrollbar $f.yscroll -orient vertical -command [list $c yview]]
    #wm attributes $t -fullscreen 1
    pack $f -side top -fill both -expand yes
    grid $c $yscroll -sticky news
    grid $xscroll -sticky news
    grid rowconfigure $f 0 -weight 1
    grid columnconfigure $f 0 -weight 1
    setBindings
    set halfSizeOfCanvas [expr {$sizeOfCanvas / 2}]
    #$c xview scroll $halfSizeOfCanvas units
    #$c yview scroll $halfSizeOfCanvas units
    gotoBoard 0

    set menu [menu $f.genericMenu]
    set boardsMenu [menu $menu.boards]
    $menu add command -label clean -command [list $this cleanBoard]
    $menu add cascade -label "tableau" -menu $boardsMenu
    foreach k {0 1 2 3 4 5 6 7 8 9} {
        $boardsMenu add command -label "tableau $k" -command [list $this gotoBoard $k]
    }
    set newItemMenu [menu $menu.newItem]
    $menu add cascade -label "new" -menu $newItemMenu
    foreach type {Txt Struct Date Link} {
        $newItemMenu add command -label $type -command [list $this newNodeAtClick $type] 
    }
    bind $c $::dinah::mouse(B3) [list $this backgroundMenu %X %Y]

    bind $m <1> [list focus $t]

    dragAndDrop

    return $t
}

itcl::body Whiteboard::backgroundMenu {x y} {
    set ::dinah::memx $x
    set ::dinah::memy $y
    tk_popup $menu $x $y
}

itcl::body Whiteboard::newNode {type x y} {
    set id [::dinah::emptyNode $type]
    add $id [boardx $x] [boardy $y]
}

itcl::body Whiteboard::newNodeAtClick {type} {
    newNode $type $::dinah::memx $::dinah::memy
}

itcl::body Whiteboard::setBindings {} {
    variable ::dinah::db
    foreach k {0 1 2 3 4 5 6 7 8 9} {
        bind $t {*}<Key-$k> [list $this gotoBoard $k]
    }
    bind $t <Control-Key-e> [list $this unsetBindings]
    bind $t <Control-Key-q> {exit}
    bind $t <Control-Key-w> [list ::dinah::destroyToplevel $t]
    bind $t <Control-Key-n> {::dinah::switchFocus+} 
    bind $t <Control-Key-p> {::dinah::switchFocus-} 
    bind $t <Key-l> [list $this move 10 0]
    bind $t <Key-j> [list $this move -10 0]
    bind $t <Key-k> [list $this move 0 10]
    bind $t <Key-i> [list $this move 0 -10]
    bind $t <Control-Key-l> [list $this resize 10 0]
    bind $t <Control-Key-j> [list $this resize -10 0]
    bind $t <Control-Key-k> [list $this resize 0 10]
    bind $t <Control-Key-i> [list $this resize 0 -10]
    bind $t <Escape> [list $this removeCursor]
    bind $t <Control-Key-v> [list $this paste]
    bind $t <Key-w> [list $this dimWinOnCursor]
    bind $t <Key-d> [list $this delete]
    bind $t <Key-n> [list $this newText]
    bind $t <Key-h> [list $this high]
    bind $t <Key-b> [list $this low]
    bind $t <Key-r> [list $this reload]

    foreach k $alphabeta {
        if {$db(board$boardNumber,$k) != {}} {
            bind $t {*}<Key-$k> [list $this setCursor $k]
        }
    }

    set found [$c find withtag cursor]
    foreach w $found {
        [$c itemcget $w -window] configure -borderwidth 1 -bg red
    }
}

itcl::body Whiteboard::unsetBindings {} {
    set found [$c find withtag cursor]
    foreach w $found {
        [$c itemcget $w -window] configure -borderwidth 1 -bg green
        [itemO [getIndiceFromItem $w]] setBindings
        foreach tag [bind $t] {
            bind $t $tag ""
        }
    }
}

itcl::body Whiteboard::storeState {id cmd args} {}

itcl::body Whiteboard::gotoBoard {k} {
    variable ::dinah::db
    $c delete all
    set edges {}
    set boardNumber $k
    foreach n {1 2 3 4 5} {
        $d($n) delete 0 end
        catch {$d($n) insert end $db(board$boardNumber,dim$n)}
    }
    foreach x $alphabeta {
        set i $db(board$boardNumber,$x)
        if {$i ne {}} {
            loadItem $x [lindex $i 0] [lindex $i 1] [lindex $i 2] [lindex $i 3] [lindex $i 4] 
        }
    }
    set currentDim "d.nil"
    foreach o [$c find withtag object] {
        updateEdges $o
    }
}

itcl::body Whiteboard::cleanBoard {} {
    foreach x $alphabeta {
        set ::dinah::db(board$boardNumber,$x) {}
    }
    foreach n {1 2 3 4 5} {
        set ::dinah::db(board$boardNumber,dim$n) ""
    }
    reload
}

itcl::body Whiteboard::paste {} {
    variable ::dinah::db
    if {[llength [lindex $db(d.clipboard) 0]] > 0} {
        add [lindex $db(d.clipboard) 0 end]
    }
}

itcl::body Whiteboard::dimWinOnCursor {} {
    set found [$c find withtag cursor]
    foreach w $found {
        ::dinah::dimWin [[itemO [getIndiceFromItem $w]] cget -dbid]
    }
}

itcl::body Whiteboard::resize {x y} {
    set found [$c find withtag cursor]
    foreach w $found {
        $c itemconfigure $w -width [expr {[winfo width [$c itemcget $w -window]] + $x}]
        $c itemconfigure $w -height [expr {[winfo height [$c itemcget $w -window]] + $y}]
    }
    saveSize
}

itcl::body Whiteboard::getFreeLetter {} {
    set place ""
    foreach k $alphabeta {
        if {$::dinah::db(board$boardNumber,$k) == {}} {
            set place $k 
            break 
        }
    }
    return $place
}

itcl::body Whiteboard::add {id {x 20} {y 20}} {
    variable ::dinah::db
    set place [getFreeLetter] 
    if {$place ne ""} {
        set o [loadItem $place $id $x $y]
        set db(board$boardNumber,$place) [list $id $x $y "" "" $o]
    }
}

itcl::body Whiteboard::delete {{id ""}} {
    variable ::dinah::db
    if {$id eq ""} {
        set found [$c find withtag cursor]
        foreach w $found {
            set db(board$boardNumber,[getIndiceFromItem $w]) {}
            reload
        }
    } else {
        set w [getItemFromId $id]
        if {$w ne ""} {
            set db(board$boardNumber,[getIndiceFromItem $w]) {}
            reload
        }
    }
}

itcl::body Whiteboard::loadItem {k id x y {width ""} {height ""}} {
    variable ::dinah::db
    set o [::dinah::mkObj $id $c]
    if {$db(board$boardNumber,$k) != {}} { lset db(board$boardNumber,$k) end $o }
    $o notificate $k
    $o notificate $::dinah::db($id,label)
    $o setContainer $this
    $o openNS; $o openEW
    set w [$c create window $x $y -window [$o cget -frame] -anchor nw -tag [list item$k id$id object]]
    if {$width ne ""} {
        $c itemconfigure $w -width $width
        $c itemconfigure $w -height $height
    }
    bind $t {*}<Key-$k> [list $this setCursor $k]
    computeEdges $w
    return $o
}

itcl::body Whiteboard::itemO {k} {
    variable ::dinah::db
    return [lindex $db(board$boardNumber,$k) end]
}

itcl::body Whiteboard::getIndiceFromItem {w} {
    regexp {^item(.*)} [lsearch -inline [$c gettags $w] item*] -> k
    return $k
}

itcl::body Whiteboard::getIdFromItem {w} {
    regexp {^id(.*)} [lsearch -inline [$c gettags $w] id*] -> id
    return $id
}

itcl::body Whiteboard::getItemFromId {id} {
    set found [$c find withtag id$id]
    foreach w $found {return $w}
    return ""
}

itcl::body Whiteboard::getItemFromIndice {k} {
    set found [$c find withtag item$k]
    foreach w $found {return $w}
    return ""
}

itcl::body Whiteboard::setCursorOnId {id} {
    set w [getItemFromId $id]
    if {$w ne ""} {
        removeCursor
        $c addtag cursor withtag $w
        [$c itemcget $w -window] configure -borderwidth 1 -bg red
    }
}

itcl::body Whiteboard::setCursor {k} {
    removeCursor
    set w [getItemFromIndice $k]
    if {$w ne ""} {
        $c addtag cursor withtag $w
        [$c itemcget $w -window] configure -borderwidth 1 -bg red
        if {! [winfo viewable [$c itemcget $w -window]]} {
            set bbox [$c bbox $w]
            $c scan mark [lindex $bbox 0] [lindex $bbox 1]
            $c scan dragto  {*}[center] 1
        }
    }
}

itcl::body Whiteboard::removeCursor {} {
    foreach w [$c find withtag cursor] {
        $c dtag $w cursor
        [$c itemcget $w -window] configure -borderwidth 1 -bg black
    }
}

itcl::body Whiteboard::centerCoord {view} {
    set l [$c $view]
    set left [lindex $l 0]
    set right [lindex $l 1]
    set x0 [expr {$left * $sizeOfCanvas}]
    set w  [expr {($right - $left) * $sizeOfCanvas}]
    return [expr {round($x0 + ($w / 2))}]
}

itcl::body Whiteboard::center {} {
    return [list [centerCoord xview] [centerCoord yview]]
}

itcl::body Whiteboard::scan {x y {gain 3}} {
    $c scan mark 10 10
    $c scan dragto [expr {10 + $x}] [expr {10 + $y}] $gain
}

itcl::body Whiteboard::move {x y} {
    lappend milliseconds [clock milliseconds]
    if {[llength $milliseconds] > 10} {
        if {([lindex $milliseconds end] - [lindex $milliseconds end-10]) < 500} {
            if {[llength $milliseconds] > 50} {
                set movefactor 10
            } else {
                set movefactor 5
            }
        } else {
            set milliseconds {}
            set movefactor 1
        }
    } else {
        if {[llength $milliseconds] > 1 && ([lindex $milliseconds end] - [lindex $milliseconds end-1]) > 500} {
            set milliseconds {}
            set movefactor 1
        }
    }
    set x [expr {$movefactor * $x}]
    set y [expr {$movefactor * $y}]
    set found [$c find withtag cursor]
    foreach w $found { moveItem $w $x $y }
    if {[llength $found] == 0} {
        scan [expr {-$x}] [expr {-$y}]
    }
}

itcl::body Whiteboard::moveItem {w x y} {
    set bbox [$c bbox $w]
    set offset 10
    if {((([lindex $bbox 0] + $x) < $offset) && ($x < 0)) || \
        ((([lindex $bbox 1] + $y) < $offset) && ($y < 0)) || \
        ((([lindex $bbox 2] + $x) > ($sizeOfCanvas - $offset)) && ($x > 0)) || \
        ((([lindex $bbox 3] + $y) > ($sizeOfCanvas - $offset)) && ($y > 0))} {
        return
    }
    $c move $w $x $y
    updateEdges $w
    savePosition
    if {! [winfo viewable [$c itemcget $w -window]]} {
        set direction [expr {($x + $y)>0 ? 1 : -1}]
        if {$y == 0} {
            scan [expr {- $direction * [winfo width $f]}] 0 1
        } else {
            scan 0 [expr {- $direction * [winfo height $f]}] 1
        }
    }
}

itcl::body Whiteboard::savePosition {} {
    variable ::dinah::db
    set found [$c find withtag cursor]
    foreach w $found {
        set bbox [$c bbox $w]
        lset db(board$boardNumber,[getIndiceFromItem $w]) 1 [lindex $bbox 0]
        lset db(board$boardNumber,[getIndiceFromItem $w]) 2 [lindex $bbox 1]
    }
}

itcl::body Whiteboard::saveSize {} {
    variable ::dinah::db
    set found [$c find withtag cursor]
    foreach w $found {
        lset db(board$boardNumber,[getIndiceFromItem $w]) 3 [winfo width [$c itemcget $w -window]]
        lset db(board$boardNumber,[getIndiceFromItem $w]) 4 [winfo height [$c itemcget $w -window]]
    }
}

itcl::body Whiteboard::newText {} {
    add [::dinah::emptyNode Txt]
}

itcl::body Whiteboard::high {} {
    ::dinah::Page::high
    reload
}

itcl::body Whiteboard::low {} {
    ::dinah::Page::low
    reload
}

itcl::body Whiteboard::reload {} {
    gotoBoard $boardNumber
}
