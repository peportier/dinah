itcl::class Link {
    inherit Obj

    private variable linkSymbol ""

    constructor {id} { set dbid $id }

    destructor {
        destroy $frame
        destroy $standalone
    }

    public method setBindings {}
    public method unsetBindings {}
    public method specificLayout {}
}

itcl::body Link::specificLayout {} {
    set main [frame $center.main]
    set linkSymbol [label $main.linkSymbol -text "+" -bg green -font "$::dinah::font 15 underline" -justify center]
    pack $linkSymbol
}

itcl::body Link::setBindings {} {
    bind $linkSymbol <Control-Key-e> [list $this unsetBindings]
    focus $linkSymbol
}

itcl::body Link::unsetBindings {} {
    if {$container ne ""} {
        $container setBindings
    }
    focus [winfo toplevel $frame]
}
