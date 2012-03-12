itcl::class Img {
    inherit Obj

    # name of the window for the original size image
    private variable original 
    # name of the window for the displayed image
    private variable copy
    private variable factor 1
    public  variable width
    public  variable height
    private variable canvas     
    private variable zonesAreVisible 0

    constructor {id} {
        set dbid $id
        mkImage
    }

    destructor {
        destroy $frame
        image delete $original
        image delete $copy
	destroy $standalone
    }

    # 'mkImage' makes an image referenced by 'original' from the file
    # found at '[path]'. 'width' and 'weight' are and remain the true
    # dimensions of the image (before any scaling).
    public method mkImage {}
    # returns the file path of the image
    public method path {}
    public method zoom {k}
    public method setBindings {}
    public method unsetBindings {}
    public method z {}
    private method rem {n m}
    public method sample {factor}
    public method scan {x y}
    public method setView {xFraction yFraction}
    public method editZones {}
    public method quickZoom {}
    public method scanQuickZoom {c x y}
    public method specificLayout {}
    public method afterLayout {}
    proc high {}
    proc low {}
}

itcl::body Img::quickZoom {} {
    set t [::dinah::newToplevel .tQuickZoom] 
    frame $t.f
    set c [canvas $t.f.c -width 320 -height 320 -bg white -xscrollcommand [list $t.f.xscroll set] -yscrollcommand [list $t.f.yscroll set]]
    scrollbar $t.f.xscroll -orient horizontal -command [list $c xview]
    scrollbar $t.f.yscroll -orient vertical -command [list $c yview]
    grid $c -row 0 -column 0 -sticky news
    grid $t.f.yscroll -row 0 -column 1 -sticky ns
    grid $t.f.xscroll -row 1 -column 0 -sticky ew
    grid rowconfigure $t.f 0 -weight 1
    grid columnconfigure $t.f 0 -weight 1
    pack $t.f -fill both -expand 1
    set highres "_high"
    set fn $::dinah::db(base)[::dinah::db'get $dbid path]$highres$::dinah::db(imgExtension)
    if {! [file exists $fn]} {
        set fn $::dinah::db(base)[::dinah::db'get $dbid path]$::dinah::db(imgExtension)
    }
    set img [image create photo -file $fn]
    $c configure -scrollregion [list 0 0 [image width $img] [image height $img]]
    $c create image 0 0 -image $img -tag "img" -anchor nw
    bind $t <Key-z> [list ::dinah::destroyToplevel $t]
    bind $t <Key-l> [list $this scanQuickZoom $c -1 0]
    bind $t <Key-j> [list $this scanQuickZoom $c 1 0]
    bind $t <Key-i> [list $this scanQuickZoom $c 0 1]
    bind $t <Key-k> [list $this scanQuickZoom $c 0 -1]
    bind $t <Key-L> [list $this scanQuickZoom $c -5 0]
    bind $t <Key-J> [list $this scanQuickZoom $c 5 0]
    bind $t <Key-I> [list $this scanQuickZoom $c 0 5]
    bind $t <Key-K> [list $this scanQuickZoom $c 0 -5]
    wm attributes $t -fullscreen 1
    focus -force $t
}

itcl::body Img::setBindings {} {
    focus $frame
    bind $frame <Control-Key-e> [list $this unsetBindings]
    bind $frame <Key-l> [list $this scan -1 0]
    bind $frame <Key-j> [list $this scan 1 0]
    bind $frame <Key-i> [list $this scan 0 1]
    bind $frame <Key-k> [list $this scan 0 -1]
    bind $frame <Key-L> [list $this scan -5 0]
    bind $frame <Key-J> [list $this scan 5 0]
    bind $frame <Key-I> [list $this scan 0 5]
    bind $frame <Key-K> [list $this scan 0 -5]
    bind $frame <Control-Key-i> [list $this zoom 1]
    bind $frame <Control-Key-k> [list $this zoom -1]
    bind $frame <Control-Key-z> [list $this editZones]
}

itcl::body Img::editZones {} {
    ::dinah::zonemaker::run $dbid $container
}

itcl::body Img::unsetBindings {} {
    foreach tag [bind $frame] {
        bind $frame $tag ""
    }
    if {$container ne ""} {
        $container setBindings
    }
}

itcl::body Img::mkImage {} {
    if { [catch {image create photo -file [path]} original] } {
	puts stderr "Could not open image"
    }
    set copy [image create photo]
    $copy copy $original
    set width   [image width $original]
    set height  [image height $original]
}

itcl::body Img::specificLayout {} {
    set canvas [::dinah::canvas'new $center.main -width 300 -height 300 \
        -scrollregion [list 0 0 $width $height]]
}

itcl::body Img::afterLayout {} {
    $canvas create image 0 0 -image $copy -anchor nw

    bind $canvas <ButtonPress-1> {%W scan mark %x %y}
    bind $canvas <B1-Motion> {%W scan dragto %x %y 1}

    $genericMenu add command -label zones -command [list $this editZones]
}

itcl::body Img::scanQuickZoom {c x y} {
    $c scan mark 10 10
    $c scan dragto [expr {10 + $x}] [expr {10 + $y}]
}

itcl::body Img::scan {x y} {
    $canvas scan mark 10 10
    $canvas scan dragto [expr {10 + $x}] [expr {10 + $y}]
    if {$container ne {}} {
        $container storeState $dbid "setView" [list [lindex [$canvas xview] 0] [lindex [$canvas yview] 0]]
    }
}

itcl::body Img::setView {xFraction yFraction} {
    $canvas xview moveto $xFraction
    $canvas yview moveto $yFraction
}

itcl::body Img::rem {n m} {
    expr {$n>$m ? int($n/$m) : 1}
}

itcl::body Img::z {} {
    set canvasHeight [winfo height $canvas]
    set canvasWidth [winfo width $canvas]
    for {set k [rem $width $canvasWidth]} {$width / $k - $canvasWidth > 100} {incr k} {}
    for {} {$height / $k - $canvasHeight > 200} {incr k} {}
    sample $k
}

itcl::body Img::sample {k} {
    if {$k > 0} {
        set factor $k
        $copy copy $original -shrink -subsample $factor $factor
        $canvas configure -scrollregion [list 0 0 [image width $copy] [image height $copy]]
    }
}

itcl::body Img::zoom {k} {
    sample [expr {$factor - $k}]
    if {$container ne {}} {
        $container storeState $dbid "sample" [list $factor]
    }
}

itcl::body Img::path {} {
    return $::dinah::db(base)[::dinah::db'get $dbid path]$::dinah::db(imgExtension)
}

itcl::body Img::high {} {}
itcl::body Img::low {} {}
