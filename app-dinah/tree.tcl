itcl::class Tree {
    private variable parentw ""
    private variable tree ""
    private variable siblingDim ""
    private variable hierarchyDim ""
    private variable navDim ""
    private variable readOnly 1
    private variable rootId ""
    constructor {} {}

    method bindDblClick {script} {
        $tree bindText <Double-ButtonRelease-1> $script
    }

    method setRoot {id} {
        set rootId $id
        return $this
    }

    method setDim {x y} {
        set hierarchyDim $x
        set siblingDim $y
        return $this
    }

    method setNavDim {d} {
        set navDim $d
        return $this
    }

    method getNavDim {} {
        return $navDim
    }

    method readOnly {} { set readOnly 1; return $this }
    method writable {} { set readOnly 0; return $this }

    method load {} {
        $tree delete [$tree nodes root]
        loadTree [insert root $rootId]
        return $this
    }

    method mkWindow {{parentWindow ""}} {
        if {$parentWindow eq ""} {
            set parentw [::dinah::newToplevel .t[::dinah::objname $this]]
        } else {
            set parentw $parentWindow
        }
        set f [frame $parentw.f -borderwidth 1 -bg black]
        set tree [Tree $f.tree -selectcommand [list $this onSelect] -xscrollcommand [list $f.xscroll set] -yscrollcommand [list $f.yscroll set] -width 15 -deltax 10 -deltay 30]
        set xscroll [scrollbar $f.xscroll -orient horizontal -command [list $tree xview]]
        set yscroll [scrollbar $f.yscroll -orient vertical -command [list $tree yview]]
        #pack $f -side top -fill both -expand yes
        grid $tree $yscroll -sticky news
        grid $xscroll -sticky news
        grid rowconfigure $f 0 -weight 1
        grid columnconfigure $f 0 -weight 1
        return $f
    }

    method itemId {item} {
        return [lindex [$tree itemcget $item -data] 0]
    }

    method itemIsVirgin {item} {
        return [lindex [$tree itemcget $item -data] 1]
    }

    method loadTree {item} {
        if {! [itemIsVirgin $item]} { return }
        $tree itemconfigure $item -data [lreplace [$tree itemcget $item -data] 1 1 0] -fill black
        set found [::dinah::dbFindInDim $hierarchyDim [itemId $item]]
        if {$found != {}} {
            set segIndex [lindex $found 0]
            set fragIndex [lindex $found 1]
            set nextFragIndex [expr {$fragIndex + 1}]
            set sonId [::dinah::dbGetFragment $hierarchyDim $segIndex $nextFragIndex]
            if {$sonId != {}} {
                set son [insert $item $sonId]
                loadSiblings $item $son
            }
        }
    }

    method loadSiblings {father item} {
        set found [::dinah::dbFindInDim $siblingDim [itemId $item]]
        if {$found != {}} {
            set segIndex [lindex $found 0]
            set fragIndex [lindex $found 1]
            set nextFragIndex [expr {$fragIndex + 1}]
            set siblings [lrange [::dinah::dbLGet $siblingDim $segIndex] $nextFragIndex end]
            if {$siblings != {}} {
                foreach siblingId $siblings {
                    insert $father $siblingId
                }
            }
        }
    }

    method insert {item id {position end}} {
        set r [$tree insert $position $item n#auto -data [list $id 1] -fill blue]
        if {[::dinah::dbGet $id,label] ne ""} {
            #$tree itemconfigure $r -text [string range $::dinah::db($id,label) end-10 end]
            $tree itemconfigure $r -text [::dinah::dbGet $id,label]
        } else {
            $tree itemconfigure $r -text [::dinah::dbGet $id,isa]
        }
        $tree bindText $::dinah::mouse(B3) [list $this popup %X %Y]
        return $r
    }

    method popup {x y nodeId} {
        if {! $readOnly } {
            destroy $parentw.f.menu
            set menu [menu $parentw.f.menu]
            $menu add command -label "rename" -command [list $this updateLabel $nodeId]
            $menu add command -label "new son" -command [list $this newSon $nodeId]
            $menu add command -label "new sibling" -command [list $this newSibling $nodeId]
            tk_popup $menu $x $y
        }
    }

    method newSon {nodeId} {
        set newDbId [::dinah::dbNewEmptyFragment Txt "label"]
        set fatherDbId [itemId $nodeId]
        set found [::dinah::dbFindInDim $hierarchyDim $fatherDbId]
        if {$found != {}} {
            set fatherSegmentIndex [lindex $found 0]
            set fatherPos [lindex $found 1]
            set lastItem [::dinah::dbLGet $hierarchyDim [list $fatherSegmentIndex end]]
            if {$lastItem eq $fatherDbId} {
                ::dinah::dbAppendToSegment $hierarchyDim $fatherSegmentIndex $newDbId
            } else {
                set fatherRightSibling [::dinah::dbLGet $hierarchyDim [list $fatherSegmentIndex [expr {$fatherPos + 1}]]]
                set found [::dinah::dbFindInDim $siblingDim $fatherRightSibling]
                if {$found != {}} {
                    set fatherSiblingSegmentIndex [lindex $found 0]
                    ::dinah::dbAppendToSegment $siblingDim $fatherSiblingSegmentIndex $newDbId
                } else {
                    ::dinah::dbAppendSegmentToDim $siblingDim [list $fatherRightSibling $newDbId]
                }
            }
        } else {
            ::dinah::dbAppendSegmentToDim $hierarchyDim [list $fatherDbId $newDbId]
        }
        updateLabel [insert $nodeId $newDbId]
    }

    method newSibling {nodeId} {
        set newDbId [::dinah::dbNewEmptyFragment Txt "label"]
        set siblingDbId [itemId $nodeId]
        set found [::dinah::dbFindInDim $siblingDim $siblingDbId]
        if {$found != {}} {
            set siblingSegmentIndex [lindex $found 0]
            set siblingSegment [::dinah::dbGetSegment $siblingDim $siblingSegmentIndex]
            set siblingPos [lindex $found 1]
            set insertIndex [expr {$siblingPos + 1}]
            set newSiblingSegment [linsert $siblingSegment $insertIndex $newDbId]
            ::dinah::dbReplaceSegment $siblingDim $siblingSegmentIndex $newSiblingSegment
        } else {
            set insertIndex end
            ::dinah::dbAppendSegmentToDim $siblingDim [list $siblingDbId $newDbId]
        }
        updateLabel [insert [$tree parent $nodeId] $newDbId $insertIndex]
    }

    method updateLabel {nodeId} {
        set r [$tree edit $nodeId [::dinah::dbGet [itemId $nodeId],label]]
        if {$r ne ""} {
            ::dinah::dbSetAttribute [itemId $nodeId] label $r
            $tree itemconfigure $nodeId -text $r
        }
    }

    method onSelect {tree node} {
        if {$node != {}} { 
            loadTree $node 
        }
    }
}
