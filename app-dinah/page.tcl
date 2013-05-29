itcl::class Page {
    inherit Obj

    # name of the window for the original size image
    private variable original
    # name of the window for the displayed image
    private variable copy
    private variable factor 1
    private variable canvas
    private variable zonesAreVisible 0
    # $resolutions($dbid) is of the form {2 {"_low" $maxLowWidth $maxLowHeight} {"_high" $maxHighWidth $maxHighHeight}}
    common resolutions

    constructor {id} {
        set dbid $id
        if {[array names resolutions -exact $id] eq ""} {
            set resolutions($id) [list 1]
            foreach suffix $::dinah::resolutions_suffix  {
                lappend resolutions($id) [list $suffix 0 0]
            }
        }
        mkImage
    }

    destructor {
        destroy $frame
        deleteImage
        destroy $standalone
    }

    method quickZoom {} {
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
        set highres [lindex $::dinah::resolutions_suffix end]
        set fn [::dinah::dbGet base][::dinah::dbGet $dbid,path]$highres[::dinah::dbGet imgExtension]
        set img [image create photo -file $fn]
        $c configure -scrollregion [list 0 0 [image width $img] [image height $img]]
        $c create image 0 0 -image $img -tag "img$dbid" -anchor nw
        bind $t <Key-Escape> [list ::dinah::destroyToplevel $t]
        bind $c <ButtonPress-1> {%W scan mark %x %y}
        bind $c <B1-Motion> {%W scan dragto %x %y 1}
        wm attributes $t -fullscreen 1
        focus -force $t
    }

    method quickZoomMove {c direction} {

    }

    method editZones {} {
        ::dinah::zonemaker::run $dbid $container
    }

    method mkImage {} {
        if { [catch {image create photo -file [path]} original] } {
            puts stderr "Could not open image"
        }
        set copy [image create photo]
        $copy copy $original
        setCurrentResolutionMaxWidth [image width $original]
        setCurrentResolutionMaxHeight [image height $original]
    }

    method reloadImage {} {
        deleteImage
        mkImage 
        set factor 1
        $canvas create image 0 0 -image $copy -anchor nw
    }

    method deleteImage {} {
        image delete $original
        image delete $copy
    }

    method specificLayout {} {
        set canvas [::dinah::canvas'new $center.main -width 300 -height 300 \
            -scrollregion [list 0 0 [currentResolutionMaxWidth] [currentResolutionMaxHeight]]]
        set zPlus [button $center.menu.zPlus -text "+" -command [list $this zoomOnClick 1]]
        set zMinus [button $center.menu.zMinus -text "-" -command [list $this zoomOnClick -1]]
        set rotate90 [button $center.menu.rotate90 -text "r" -command [list $this rotate90]]
        set quickZoom [button $center.menu.quickZoom -text "z" -command [list $this quickZoom]]
        pack $zPlus -side left -padx 4 -pady 4
        pack $zMinus -side left -padx 4 -pady 4
        pack $rotate90 -side left -padx 4 -pady 4
        pack $quickZoom -side left -padx 4 -pady 4
    }

    method afterLayout {} {
        $canvas create image 0 0 -image $copy -anchor nw
        bind $canvas <ButtonPress-1> {%W scan mark %x %y}
        bind $canvas <B1-Motion> {%W scan dragto %x %y 1}
        $genericMenu add command -label zones -command [list $this editZones]
    }

    method rem {n m} {
        expr {$n>$m ? int($n/$m) : 1}
    }

    method scaleInsideRect {rectWidth rectHeight} {
        for {set k [rem [currentResolutionMaxWidth] $rectWidth]} {[currentResolutionMaxWidth] / $k - $rectWidth > 0} {incr k} {}
        for {} {[currentResolutionMaxHeight] / $k - $rectHeight > 0} {incr k} {}
        sample $k
    }

    method z {} {
        set canvasHeight [winfo height $canvas]
        set canvasWidth [winfo width $canvas]
        scaleInsideRect [expr {$canvasWidth + 100}] [expr {$canvasHeight + 200}]
    }

    method sample {k} {
        if {$k > 0} {
            set factor $k
            $copy copy $original -shrink -subsample $factor $factor
            $canvas configure -scrollregion [list 0 0 [image width $copy] [image height $copy]]
            if {[currentResolutionIndex] != 1} {
                if {([image width $copy] < [prevResolutionMaxWidth]) || ([image height $copy] < [prevResolutionMaxHeight])} {
                    prevResolution
                    reloadImage
                    $canvas configure -scrollregion [list 0 0 [currentResolutionMaxWidth] [currentResolutionMaxHeight]]
                }
            }
        } elseif {[nextResolution]} {
            reloadImage
            scaleInsideRect [prevResolutionMaxWidth] [prevResolutionMaxHeight]
        }
    }

    method zoomOnClick {k} {
        if {! [catch {$container isa Dim} isaDim]} {if {$isaDim} {
            $container forEachObject [list zoom $k]
        }} else {
            zoom $k
        }
    }

    method zoom {k} {
        sample [expr {$factor - $k}]
    }

    # returns the file path of the image
    method path {} {
        return [::dinah::dbGet base][::dinah::dbGet $dbid,path][currentResolutionSuffix][::dinah::dbGet imgExtension]
    }

    method currentResolutionIndex {} {
        lindex $resolutions($dbid) 0
    }

    method currentResolutionSuffix {} {
        lindex $resolutions($dbid) [currentResolutionIndex] 0
    }

    method resolutionMaxWidth {index} {
        lindex $resolutions($dbid) $index 1
    }

    method resolutionMaxHeight {index} {
        lindex $resolutions($dbid) $index 2
    }

    method currentResolutionMaxWidth {} { resolutionMaxWidth [currentResolutionIndex] }

    method currentResolutionMaxHeight {} { resolutionMaxHeight [currentResolutionIndex] }

    # contract: [currentResolutionIndex] > 1
    method prevResolutionMaxWidth {} { resolutionMaxWidth [expr {[currentResolutionIndex] - 1}] }

    # contract: [currentResolutionIndex] > 1
    method prevResolutionMaxHeight {} { resolutionMaxHeight [expr {[currentResolutionIndex] - 1}] }

    method setCurrentResolutionMaxWidth {newWidth} {
        lset resolutions($dbid) [currentResolutionIndex] 1 $newWidth
    }

    method setCurrentResolutionMaxHeight {newHeight} {
        lset resolutions($dbid) [currentResolutionIndex] 2 $newHeight
    }

    method nextResolution {} {
        if {[currentResolutionIndex] < ([llength $resolutions($dbid)] - 1)} {
            lset resolutions($dbid) 0 [expr {[currentResolutionIndex] + 1}]
            return 1
        }
        return 0
    }

    method prevResolution {} {
        if {[currentResolutionIndex] > 1} {
            lset resolutions($dbid) 0 [expr {[currentResolutionIndex] - 1}]
            return 1
        }
        return 0
    }

    method rotate90 {} {
        set oldpath [::dinah::dbGet $dbid,path]
        if {[::dinah::inDim $::dinah::dimRotate $dbid]} {
            set newpath $oldpath
        } else {
            set newpath [join [list $oldpath _rot] ""]
            ::dinah::dbSet $dbid,path $newpath
        }
        foreach suffix $::dinah::resolutions_suffix  {
            set oldfilepath [::dinah::dbGet base]$oldpath$suffix[::dinah::dbGet imgExtension]
            set newfilepath [::dinah::dbGet base]$newpath$suffix[::dinah::dbGet imgExtension]
            exec -ignorestderr $::dinah::zonemaker::convert $oldfilepath -rotate 90 $newfilepath
        }
        updateDimRotate
        reloadImage
    }

    method updateDimRotate {} {
        if {[llength [::dinah::dbGet $::dinah::dimRotate]] = 0} {
            ::dinah::dbAppend $::dinah::dimRotate [list $dbid]
        } else {
            ::dinah::remFragFromDim $::dinah::dimRotate $dbid
            ::dinah::dbLSet $::dinah::dimRotate 0 [linsert [::dinah::dbLGet $::dinah::dimRotate 0] 0 $dbid]
        }
    }
}
