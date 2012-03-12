itcl::class Tree {
    private variable parentw ""
    private variable tree ""
    private variable siblingDim ""
    private variable hierarchyDim ""
    private variable rootId ""
    constructor {} {}
    public method mkWindow {{parentw ""}}
    public method loadTree {item}
    public method loadSiblings {father son}
    public method insert {item id}
    public method onSelect {tree node}
    public method itemId {item}
    public method itemIsVirgin {item}
    public method setRoot {id}
    public method setDim {hierarchyDim siblingDim}
    public method load {}
    public method bindDblClick {script}
}

itcl::body Tree::bindDblClick {script} {
    $tree bindText <Double-ButtonRelease-1> $script
}

itcl::body Tree::setRoot {id} { 
    set rootId $id 
    return $this
}

itcl::body Tree::setDim {x y} { 
    set hierarchyDim $x
    set siblingDim $y
    return $this
}

itcl::body Tree::load {} { 
    $tree delete [$tree nodes root]
    loadTree [insert root $rootId]
    return $this
}

itcl::body Tree::mkWindow {{parentw ""}} {
    variable ::dinah::db
    if {$parentw == ""} { 
        set parentw [::dinah::newToplevel .t[::dinah::objname $this]] 
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

itcl::body Tree::itemId {item} {
    return [lindex [$tree itemcget $item -data] 0]
}

itcl::body Tree::itemIsVirgin {item} {
    return [lindex [$tree itemcget $item -data] 1]
}

itcl::body Tree::loadTree {item} {
    variable ::dinah::db
    if {! [itemIsVirgin $item]} { return }
    $tree itemconfigure $item -data [lreplace [$tree itemcget $item -data] 1 1 0] -fill black
    set found [::dinah::findInDim $hierarchyDim [itemId $item]]
    if {$found != {}} {
        set sonId [lindex $::dinah::db($hierarchyDim) [lindex $found 0] [expr {[lindex $found 1] + 1}]]
        if {$sonId != {}} {
            set son [insert $item $sonId]
            loadSiblings $item $son
        }
    }
}

itcl::body Tree::loadSiblings {father item} {
    variable ::dinah::db
    set found [::dinah::findInDim $siblingDim [itemId $item]]
    if {$found != {}} {
        set siblings [lrange [lindex $::dinah::db($siblingDim) [lindex $found 0]] [expr {[lindex $found 1] + 1}] end]
        if {$siblings != {}} {
            foreach siblingId $siblings {
                insert $father $siblingId
            }
        }
    }
}

itcl::body Tree::insert {item id} {
    variable ::dinah::db
    set r [$tree insert end $item n#auto -data [list $id 1] -fill blue]
    if {$::dinah::db($id,label) ne ""} {
        #$tree itemconfigure $r -text [string range $::dinah::db($id,label) end-10 end]
        $tree itemconfigure $r -text $::dinah::db($id,label)
    } else {
        $tree itemconfigure $r -text $::dinah::db($id,isa)
    } 
    return $r
}

itcl::body Tree::onSelect {tree node} {
    if {$node != {}} { 
        loadTree $node 
    }
}
