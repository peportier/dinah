itcl::class Label {
    inherit Obj

    constructor {id} { set dbid $id }

    destructor {}

    public method specificLayout {} {
        set main [frame $center.main]
        set dbLabel [label $main.dbLabel -textvariable ::dinah::db($dbid,label)\
            -bg green -font "$::dinah::font 15 underline" -justify center]
        pack $dbLabel
    }
}
