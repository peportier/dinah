itcl::class Struct {
    inherit Obj

    private variable leftSelectedItem ""
    private variable leftSelectedItemPreviousColor ""
    private variable lbright ""
    private variable lbleft "" 

    constructor {id} {
        set dbid $id
    }

    destructor {}

    method specificLayout {} {
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

    method afterLayout {} {
        initLbleft

        $lbleft bindText <1> [list $this lbleftClick1]
        $lbleft bindText $::dinah::mouse(B3) [list $this lbleftClick3]
        $lbright bindText <1> [list $this lbrightClick1]
        $lbright bindText $::dinah::mouse(B3) [list $this lbrightClick3]
    }

    method initLbleft {} {
        foreach d [::dinah::dbGet dimensions] {
            if {$d ni {d.archive d.nil d.clipboard d.sameLevel d.insert d.transcription d.chrono d.fragments d.init} && [regexp {^d\..*} $d]} {
                set item [$lbleft insert end d#auto -text $d -fill black]
                if {[::dinah::dbExists $dbid,$d]} {
                    $lbleft itemconfigure $item -fill blue 
                }
            }
        }
    }

    method updateLeftSelectedItem {newItem} {
        if {$leftSelectedItem ne ""} {
            $lbleft itemconfigure $leftSelectedItem -fill $leftSelectedItemPreviousColor
        }
        set leftSelectedItemPreviousColor [$lbleft itemcget $newItem -fill]
        set leftSelectedItem $newItem
        $lbleft itemconfigure $newItem -fill red
    }

    method lbleftClick1 {item} {
        updateLeftSelectedItem $item
        set d [selectedDim]
        $lbright delete [$lbright items]
        foreach s [::dinah::dbGet $d] {
            foreach f $s {
                set rightItem [$lbright insert end f#auto -data $f -fill black -text [expr {[::dinah::dbGet $f,label] ne "" ? [::dinah::dbGet $f,label] : [::dinah::dbGet $f,isa]}]]
                if {[selectedDimHasSelectedFragments] && [lsearch [::dinah::dbGet $dbid,$d] $f] != -1} {
                    $lbright itemconfigure $rightItem -fill blue
                }
            }
        }
    }

    method lbleftClick3 {item} {
        updateLeftSelectedItem $item
        set d [selectedDim]
        set leftSelectedItemPreviousColor black
        if {[selectedDimHasSelectedFragments]} {
            remDim $d
            lbleftClick1 $item
        }
    }

    method selectedDim {} {
        $lbleft itemcget $leftSelectedItem -text
    }

    method selectedDimHasSelectedFragments {} {
        ::dinah::dbExists $dbid,[selectedDim]
    }

    method lbrightClick1 {item} {
        if {![selectedDimHasSelectedFragments]} {
            set leftSelectedItemPreviousColor blue
        }
        $lbright itemconfigure $item -fill blue
        addFrag [selectedDim] [$lbright itemcget $item -data]
    }

    method lbrightClick3 {item} {
        $lbright itemconfigure $item -fill black
        remFrag [selectedDim] [$lbright itemcget $item -data]
        if {[selectedDimHasSelectedFragments] && [llength [::dinah::dbGet $dbid,[selectedDim]]] == 0} {
            set leftSelectedItemPreviousColor black
            remDim [selectedDim]
        }
    }

    method remDim {d} {
        array unset ::dinah::db $dbid,$d 
    }

    method addFrag {d fid} {
        ::dinah::ladd ::dinah::db($dbid,$d) $fid
    }

    method remFrag {d fid} {
        ::dinah::lrem ::dinah::db($dbid,$d) $fid
    }

}
