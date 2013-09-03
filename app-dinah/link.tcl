itcl::class Link {
    inherit Obj

    private variable linkSymbol ""

    constructor {id} { set dbid $id }

    destructor {}

    public method specificLayout {}
}

itcl::body Link::specificLayout {} {
    set main [frame $center.main]
    set linkSymbol [label $main.linkSymbol -text "+" -bg green -font "$::dinah::font 15 underline" -justify center]
    pack $linkSymbol
}
