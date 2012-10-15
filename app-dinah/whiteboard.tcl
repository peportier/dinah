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
    private variable idsOnBoard {}
    private variable edges
    private variable colors
    private variable menu ""

    constructor {} {
        array set b {}
        array set d {}
        array set colors {1 black 2 red 3 green 4 orange 5 blue}
        set edges [::dinah::Edges #auto]
    }

    method getFocus {} {
        focus $t
    }

    method getCanvas {} {
        return $c
    }

    method expand {id offset} {
        set found [::dinah::findInDim [getCurrentDim] $id]
        if {$found ne {}} {
            set si [lindex $found 0]; set fi [lindex $found 1]
            set otherId [::dinah::dbLGet [getCurrentDim] [list $si [expr {$fi + $offset}]]]
            if {$otherId ne "" && [getItemFromId $otherId] eq ""} {
                set item [getItemFromId $id]
                set coords [$c coords $item]
                set bbox [$c bbox $item]
                set width [expr {[lindex $bbox 2] - [lindex $bbox 0]}]
                add $otherId [expr {[lindex $coords 0] + $offset * ($width + 20)}] [lindex $coords 1]
            }
        }
    }

    method next {id} {
        expand $id 1
    }

    method prev {id} {
        expand $id -1
    }

    method dragAndDrop {} {
        DropSite::register $c -dropcmd [list $this dropcmd] -droptypes {Obj copy}
    }

    method boardx {x} {
        expr {[$c canvasx $x] - [winfo rootx $c]}
    }

    method boardy {y} {
        expr {[$c canvasx $y] - [winfo rooty $c]}
    }

    method dropcmd {target src x y op type data} {
        set id [lindex $data end]
        if {[getItemFromId $id] eq ""} {
            add $id [boardx $x] [boardy $y]
        }
    }

    method saveDim {i} {
        ::dinah::dbSet board$boardNumber,dim$i [$d($i) get]
    }

    method updateEdges {} {
        $edges deleteAll
        foreach {k entry} [array get d] {
            set color $colors($k)
            set dim [$entry get]
            foreach id $idsOnBoard {
                updateEdgesForId $id $id $color $dim
                set found [::dinah::findInDim $::dinah::dimClone $id]
                if {$found ne ""} {
                    set s [::dinah::dbLGet $::dinah::dimClone [lindex $found 0]]
                    foreach clone $s {
                        if {$s ne $id} {
                            updateEdgesForId $id $clone $color $dim
                        }
                    }
                }
            }
        }
    }

    method updateEdgesForId {id cloneId color dim} {
        set found [::dinah::findInDim $dim $cloneId]
        if {$found ne ""} {
            set s [::dinah::dbLGet $dim [lindex $found 0]]
            set itemIndice [lindex $found 1]
            foreach other $idsOnBoard {
                if {$other ne $id} {
                    set otherIndice [lsearch $s $other]
                    if {$otherIndice > -1} {
                        set e [::dinah::Edge #auto]
                        if {$itemIndice == $otherIndice - 1} {
                            $e setFromId $id
                            $e setToId $other
                            $e setLineColor $color
                            $e setDirect
                            $edges add [namespace current]::$e
                        } elseif {$itemIndice == $otherIndice + 1} {
                            $e setFromId $other
                            $e setToId $id
                            $e setLineColor $color
                            $e setDirect
                            $edges add [namespace current]::$e
                        } elseif {$itemIndice < $otherIndice} {
                            set interItems 0
                            for {set i [expr {$itemIndice + 1}]} {$i < $otherIndice} {incr i} {
                                if {[lindex $s $i] in $idsOnBoard} {
                                    set interItems 1
                                    break
                                }
                            }
                            if {! $interItems} {
                                $e setFromId $id
                                $e setToId $other
                                $e setLineColor $color
                                $e setIndirect
                                $edges add [namespace current]::$e
                            }
                        } elseif {$itemIndice > $otherIndice} {
                            set interItems 0
                            for {set i [expr {$otherIndice + 1}]} {$i < $itemIndice} {incr i} {
                                if {[lindex $s $i] in $idsOnBoard} {
                                    set interItems 1
                                    break
                                }
                            }
                            if {! $interItems} {
                                $e setFromId $other
                                $e setToId $id
                                $e setLineColor $color
                                $e setIndirect
                                $edges add [namespace current]::$e
                            }
                        }
                    }
                }
            }
        }
    }

    method drawEdges {item} {
        foreach e [$edges fromId [getIdFromItem $item]] {
            drawEdge $e
        }
        foreach e [$edges toId [getIdFromItem $item]] {
            drawEdge $e
        }
    }

    method updateAndDrawAllEdges {} {
        updateEdges
        $c delete edge
        foreach o [$c find withtag object] {
            drawEdges $o
        }
    }

    method drawEdge {e} {
        $c delete [$e getLineItem]
        foreach {x0 y0 x2 y2} [$c bbox [getItemFromId [$e getFromId]]] break
        set x1 [expr {($x0+$x2)/2.}]
        set y1 [expr {($y0+$y2)/2.}]
        foreach {x3 y3 x5 y5} [$c bbox [getItemFromId [$e getToId]]] break
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
        set options [$e getLineOptions]
        $e setLineItem [$c create line $x1 $y1 $x4 $y4 {*}$options]
    }

    method okDim {i} {
        saveDim $i
        reload
        setCurrentDim [$d($i) get]
        foreach j {1 2 3 4 5} {
            $b($j) configure -borderwidth 1
        }
        $b($i) configure -borderwidth 4
    }

    method getCurrentDim {} { 
        if {[::dinah::dbExists board$boardNumber,currentDim]} {
            return [::dinah::dbGet board$boardNumber,currentDim]
        } else {
            return $::dinah::dimNil
        }
    }

    method setCurrentDim {dimName} {
        ::dinah::dbSet board$boardNumber,currentDim $dimName
    }

    method mkWindow {{parent {}}} {
        if {$parent == {}} {
            set t [::dinah::newToplevel .t[::dinah::objname $this]] 
        } else {
            set t $parent
        }
        set f [frame $t.f -borderwidth 1 -bg black]
        set m [frame $t.m -borderwidth 1]
        foreach i {1 2 3 4 5} {
            ::dinah::Autocomplete #auto $m.dim$i [::dinah::dbGet dimensions]
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

    method backgroundMenu {x y} {
        set ::dinah::memx $x
        set ::dinah::memy $y
        tk_popup $menu $x $y
    }

    method newNode {type x y} {
        set id [::dinah::emptyNode $type]
        add $id [boardx $x] [boardy $y]
    }

    method newNodeAtClick {type} {
        newNode $type $::dinah::memx $::dinah::memy
    }

    method setBindings {} {
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
            if {[::dinah::dbGet board$boardNumber,$k] != {}} {
                bind $t {*}<Key-$k> [list $this setCursor $k]
            }
        }

        set found [$c find withtag cursor]
        foreach w $found {
            [$c itemcget $w -window] configure -borderwidth 1 -bg red
        }
    }

    method unsetBindings {} {
        set found [$c find withtag cursor]
        foreach w $found {
            [$c itemcget $w -window] configure -borderwidth 1 -bg green
            [itemO [getIndiceFromItem $w]] setBindings
            foreach tag [bind $t] {
                bind $t $tag ""
            }
        }
    }

    method storeState {id cmd args} {}

    method deleteBoard {} {
        $c delete all
        foreach o [$c find withtag object] {
            itcl::delete object $o
        }
        $edges deleteAll
    }

    method gotoBoard {k} {
        deleteBoard
        set boardNumber $k
        foreach n {1 2 3 4 5} {
            $d($n) delete 0 end
            catch {$d($n) insert end [::dinah::dbGet board$boardNumber,dim$n]}
        }
        foreach x $alphabeta {
            set i [::dinah::dbGet board$boardNumber,$x]
            if {$i ne {}} {
                ::dinah::ladd idsOnBoard [lindex $i 0]
                pinItem $x [lindex $i 0] [lindex $i 1] [lindex $i 2] [lindex $i 3] [lindex $i 4]
            }
        }
        updateAndDrawAllEdges
    }

    method cleanBoard {} {
        foreach x $alphabeta {
            ::dinah::dbSet board$boardNumber,$x {}
        }
        foreach n {1 2 3 4 5} {
            ::dinah::dbSet board$boardNumber,dim$n ""
        }
        reload
    }

    method paste {} {
        if {[llength [::dinah::dbLGet $::dinah::dimClipboard 0]] > 0} {
            add [::dinah::dbLGet $::dinah::dimClipboard [list 0 end]]
        }
    }

    method dimWinOnCursor {} {
        set found [$c find withtag cursor]
        foreach w $found {
            ::dinah::dimWin [[itemO [getIndiceFromItem $w]] cget -dbid]
        }
    }

    method resize {x y} {
        set found [$c find withtag cursor]
        foreach w $found {
            $c itemconfigure $w -width [expr {[winfo width [$c itemcget $w -window]] + $x}]
            $c itemconfigure $w -height [expr {[winfo height [$c itemcget $w -window]] + $y}]
        }
        saveSize
    }

    method getFreeLetter {} {
        set place ""
        foreach k $alphabeta {
            if {[::dinah::dbGet board$boardNumber,$k] == {}} {
                set place $k
                break
            }
        }
        return $place
    }

    method add {id {x 20} {y 20}} {
        set place [getFreeLetter] 
        if {$place ne ""} {
            ::dinah::ladd idsOnBoard $id
            set o [pinItem $place $id $x $y]
            ::dinah::dbSet board$boardNumber,$place [list $id $x $y "" "" $o]
            updateAndDrawAllEdges
        }
    }

    method delete {{id ""}} {
        if {$id eq ""} {
            set found [$c find withtag cursor]
            foreach w $found {
                ::dinah::lrem idsOnBoard [getIdFromItem $w]
                ::dinah::dbSet board$boardNumber,[getIndiceFromItem $w] {}
                reload
            }
        } else {
            set w [getItemFromId $id]
            if {$w ne ""} {
                ::dinah::lrem idsOnBoard $id
                ::dinah::dbSet board$boardNumber,[getIndiceFromItem $w] {}
                reload
            }
        }
    }

    method pinItem {k id x y {width ""} {height ""}} {
        set o [::dinah::mkObj $id $c]
        if {[::dinah::dbGet board$boardNumber,$k] != {}} { 
            ::dinah::dbLSet board$boardNumber,$k end $o
        }
        $o notificate $k
        $o notificate [::dinah::dbGet $id,label]
        $o setContainer $this
        $o openNS; $o openEW
        set w [$c create window $x $y -window [$o cget -frame] -anchor nw -tag [list item$k id$id object]]
        if {$width ne ""} {
            $c itemconfigure $w -width $width
            $c itemconfigure $w -height $height
        }
        bind $t {*}<Key-$k> [list $this setCursor $k]
        return $o
    }

    method itemO {k} {
        return [::dinah::dbLGet board$boardNumber,$k end]
    }

    method getIndiceFromItem {w} {
        regexp {^item(.*)} [lsearch -inline [$c gettags $w] item*] -> k
        return $k
    }

    method getIdFromItem {w} {
        regexp {^id(.*)} [lsearch -inline [$c gettags $w] id*] -> id
        return $id
    }

    method getItemFromId {id} {
        set found [$c find withtag id$id]
        foreach w $found {return $w}
        return ""
    }

    method getItemFromIndice {k} {
        set found [$c find withtag item$k]
        foreach w $found {return $w}
        return ""
    }

    method setCursorOnId {id} {
        set w [getItemFromId $id]
        if {$w ne ""} {
            removeCursor
            $c addtag cursor withtag $w
            [$c itemcget $w -window] configure -borderwidth 1 -bg red
        }
    }

    method setCursor {k} {
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

    method removeCursor {} {
        foreach w [$c find withtag cursor] {
            $c dtag $w cursor
            [$c itemcget $w -window] configure -borderwidth 1 -bg black
        }
    }

    method centerCoord {view} {
        set l [$c $view]
        set left [lindex $l 0]
        set right [lindex $l 1]
        set x0 [expr {$left * $sizeOfCanvas}]
        set w  [expr {($right - $left) * $sizeOfCanvas}]
        return [expr {round($x0 + ($w / 2))}]
    }

    method center {} {
        return [list [centerCoord xview] [centerCoord yview]]
    }

    method scan {x y {gain 3}} {
        $c scan mark 10 10
        $c scan dragto [expr {10 + $x}] [expr {10 + $y}] $gain
    }

    method move {x y} {
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

    method moveItem {w x y} {
        set bbox [$c bbox $w]
        set offset 10
        if {((([lindex $bbox 0] + $x) < $offset) && ($x < 0)) || \
            ((([lindex $bbox 1] + $y) < $offset) && ($y < 0)) || \
            ((([lindex $bbox 2] + $x) > ($sizeOfCanvas - $offset)) && ($x > 0)) || \
            ((([lindex $bbox 3] + $y) > ($sizeOfCanvas - $offset)) && ($y > 0))} {
            return
        }
        $c move $w $x $y
        drawEdges $w
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

    method savePosition {} {
        set found [$c find withtag cursor]
        foreach w $found {
            set bbox [$c bbox $w]
            ::dinah::dbLSet board$boardNumber,[getIndiceFromItem $w] 1 [lindex $bbox 0]
            ::dinah::dbLSet board$boardNumber,[getIndiceFromItem $w] 2 [lindex $bbox 1]
        }
    }

    method saveSize {} {
        set found [$c find withtag cursor]
        foreach w $found {
            ::dinah::dbLSet board$boardNumber,[getIndiceFromItem $w] 3 [winfo width [$c itemcget $w -window]]
            ::dinah::dbLSet board$boardNumber,[getIndiceFromItem $w] 4 [winfo height [$c itemcget $w -window]]
        }
    }

    method newText {} {
        add [::dinah::emptyNode Txt]
    }

    method high {} {
        ::dinah::Page::high
        reload
    }

    method low {} {
        ::dinah::Page::low
        reload
    }

    method reload {} {
        gotoBoard $boardNumber
    }
}

