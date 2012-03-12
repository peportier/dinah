itcl::class Container {
    private variable quart
    private variable dim

    public method mkWindow {{parent {}}}
    public method quart {i}
    public method frameOfQuart {i}
}

itcl::body Container::mkWindow {{parent {}}} {
    if {$parent == {}} {
        set t [::dinah::newToplevel .t[::dinah::objname $this]] 
    } else {
        set t $parent
    }
    set f [frame $t.frame]
    set main [panedwindow $f.main -orient vertical -handlesize 10 -showhandle 1]
    pack $main -side top -fill both -expand yes
    set top [frame $main.top -highlightcolor green -highlightthickness 1]
    set bottom [panedwindow $main.bottom -orient horizontal -handlesize 10 -showhandle 1]
    $main add $top $bottom
    set left [panedwindow $bottom.left -orient vertical -handlesize 10 -showhandle 1]
    set right [panedwindow $bottom.right -orient vertical -handlesize 10 -showhandle 1]
    $bottom add $left
    $bottom add $right
    set quart(1) [frame $left.top -highlightcolor green -highlightthickness 1]
    $left add $quart(1)
    set quart(3) [frame $left.bottom -highlightcolor green -highlightthickness 1]
    $left add $quart(3)
    set quart(2) [frame $right.top -highlightcolor green -highlightthickness 1]
    $right add $quart(2)
    set quart(4) [frame $right.bottom -highlightcolor green -highlightthickness 1]
    $right add $quart(4)
    pack $f -side top -fill both -expand yes
    foreach i {1 2 3 4} {
        set d [::dinah::dimWin {} $::dinah::dimNil $::dinah::dimNil $quart($i)]
        set dim($i) ::dinah::$d
        $dim($i) setContainer $this 
    }
    [::dinah::Whiteboard #auto] mkWindow $top

    bind $t <Control-Key-q> {exit}

    return $t
}

itcl::body Container::quart {i} {
    return $dim($i)
}

itcl::body Container::frameOfQuart {i} {
    return $quart($i)
}
