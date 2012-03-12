itcl::class Struct {
    inherit Obj

    private variable leftSelectedItem ""
    private variable leftSelectedItemPreviousColor ""
    private variable lbright ""
    private variable lbleft "" 

    constructor {id} { 
        variable ::dinah::db
        set dbid $id 
    }

    destructor {
        destroy $frame
        destroy $standalone
    }

    public method setBindings {}
    public method unsetBindings {}
    public method remDim {d}
    public method addFrag {d fid}
    public method remFrag {d fid}
    public method initLbleft {}
    public method lbleftClick1 {item}
    public method lbleftClick3 {item}
    public method lbrightClick1 {item}
    public method lbrightClick3 {item}
    public method selectedDim {}
    public method selectedDimHasSelectedFragments {}
    public method updateLeftSelectedItem {newItem}
    public method specificLayout {}
    public method afterLayout {}
}

itcl::body Struct::specificLayout {} {
    set main [frame $center.main]
    set swleft [ScrolledWindow $main.swleft]
    pack $swleft -fill both -expand 1 -side left
    set lbleft [ListBox $swleft.lbleft]
    $swleft setwidget $lbleft
    set swright [ScrolledWindow $main.swright]
    pack $swright -fill both -expand 1 -side left
    set lbright [ListBox $swright.lbright]
    $swright setwidget $lbright
}

itcl::body Struct::afterLayout {} {
    initLbleft

    $lbleft bindText <1> [list $this lbleftClick1]
    $lbleft bindText $::dinah::mouse(B3) [list $this lbleftClick3]
    $lbright bindText <1> [list $this lbrightClick1]
    $lbright bindText $::dinah::mouse(B3) [list $this lbrightClick3]
}

itcl::body Struct::initLbleft {} {
    variable ::dinah::db
    foreach d $db(dimensions) {
        if {$d ni {d.archive d.nil d.clipboard d.sameLevel d.insert d.transcription d.chrono d.fragments d.init} && [regexp {^d\..*} $d]} {
            set item [$lbleft insert end d#auto -text $d -fill black]
            if {[info exists db($dbid,$d)]} {
                $lbleft itemconfigure $item -fill blue 
            }
        }
    }
}

itcl::body Struct::updateLeftSelectedItem {newItem} {
    if {$leftSelectedItem ne ""} {
        $lbleft itemconfigure $leftSelectedItem -fill $leftSelectedItemPreviousColor
    }
    set leftSelectedItemPreviousColor [$lbleft itemcget $newItem -fill]
    set leftSelectedItem $newItem
    $lbleft itemconfigure $newItem -fill red
}

itcl::body Struct::lbleftClick1 {item} {
    variable ::dinah::db
    updateLeftSelectedItem $item
    set d [selectedDim]
    $lbright delete [$lbright items]
    foreach s $db($d) {
        foreach f $s {
            set rightItem [$lbright insert end f#auto -data $f -fill black -text [expr {$db($f,label) ne "" ? $db($f,label) : $db($f,isa)}]]
            if {[selectedDimHasSelectedFragments] && [lsearch $db($dbid,$d) $f] != -1} {
                $lbright itemconfigure $rightItem -fill blue
            }
        }
    }
}

itcl::body Struct::lbleftClick3 {item} {
    variable ::dinah::db
    updateLeftSelectedItem $item
    set d [selectedDim]
    set leftSelectedItemPreviousColor black
    if {[selectedDimHasSelectedFragments]} {
        remDim $d
        lbleftClick1 $item
    }
}

itcl::body Struct::selectedDim {} {
    $lbleft itemcget $leftSelectedItem -text
}

itcl::body Struct::selectedDimHasSelectedFragments {} {
    variable ::dinah::db
    info exists db($dbid,[selectedDim])
}

itcl::body Struct::lbrightClick1 {item} {
    variable ::dinah::db
    if {![selectedDimHasSelectedFragments]} {
        set leftSelectedItemPreviousColor blue
    }
    $lbright itemconfigure $item -fill blue
    addFrag [selectedDim] [$lbright itemcget $item -data]
}

itcl::body Struct::lbrightClick3 {item} {
    variable ::dinah::db
    $lbright itemconfigure $item -fill black
    remFrag [selectedDim] [$lbright itemcget $item -data]
    if {[selectedDimHasSelectedFragments] && [llength $db($dbid,[selectedDim])] == 0} {
        set leftSelectedItemPreviousColor black
        remDim [selectedDim]
    }
}

itcl::body Struct::setBindings {} {
    focus $frame
    bind $frame <Control-Key-e> [list $this unsetBindings]
}

itcl::body Struct::unsetBindings {} {
    if {$container ne ""} { $container setBindings }
    focus [winfo toplevel $frame]
}

itcl::body Struct::remDim {d} {
    array unset ::dinah::db $dbid,$d 
}

itcl::body Struct::addFrag {d fid} {
    ::dinah::ladd ::dinah::db($dbid,$d) $fid
}

itcl::body Struct::remFrag {d fid} {
    ::dinah::lrem ::dinah::db($dbid,$d) $fid
}
