namespace eval ::dinah::zonemaker {

    set img {}
    set imageId ""
    array set ::dinah::zonemaker::polydraw {}
    #set convert "C:/Program Files (x86)/ImageMagick-6.7.2-Q16/convert"
    set c ""
    set fs ""

    proc polydraw {w} {
      #-- add bindings for drawing/editing polygons to a canvas
      bind $w <1>                      {::dinah::zonemaker::polydraw'mark   %W %x %y}
      bind $w <Double-1>               {::dinah::zonemaker::polydraw'insert %W}
      bind $w <B1-Motion>              {::dinah::zonemaker::polydraw'move   %W %x %y}
      bind $w <Shift-B1-Motion>        {::dinah::zonemaker::polydraw'move   %W %x %y 1}
      bind $w $::dinah::mouse(B3)       {::dinah::zonemaker::polydraw'delete %W}
      bind $w $::dinah::mouse(Shift-B3) {::dinah::zonemaker::polydraw'delete %W 1}
      interp alias {} tags$w {} $w itemcget current -tags
    }
    proc polydraw'add {w x y} {
      #-- start or extend a line, turn it into a polygon if closed
      variable ::dinah::zonemaker::polydraw
      if {![info exists polydraw(item$w)]} {
          set coords [list [expr {$x-2}] [expr {$y-2}] $x $y]
          set polydraw(item$w) [$w create line $coords -fill red -tag poly0 -width 2]
      } else {
          set item $polydraw(item$w)
          foreach {x0 y0} [$w coords $item] break
          if {hypot($x-$x0,$y-$y0) < 5} {
              set coo [lrange [$w coords $item] 2 end]
	      if {[llength $coo] > 4} {
		  $w delete $item
		  unset polydraw(item$w)
		  set new [$w create poly $coo -fill {} -tag poly -outline red -width 2]
		  polydraw'markNodes $w $new
		  set polydraw(modified) 1
	      }
          } else {
              $w coords $item [concat [$w coords $item] $x $y]
          }
      }
    }
    proc polydraw'delete {w {all 0}} {
      variable ::dinah::zonemaker::polydraw
      #-- delete a node of, or a whole polygon
      set tags [tags$w]
      if {[regexp {of:([^ ]+)} $tags -> poly]} {
          if {$all} {
              $w delete $poly of:$poly
          } else {
              regexp {at:([^ ]+)} $tags -> pos
              $w coords $poly [lreplace [$w coords $poly] $pos [incr pos]]
              polydraw'markNodes $w $poly
          }
          set polydraw(modified) 1
      }
      $w delete poly0 ;# possibly clean up unfinished polygon
      catch {unset polydraw(item$w)}
    }
    proc polydraw'insert {w} {
      #-- create a new node halfway to the previous node
      variable ::dinah::zonemaker::polydraw
      set tags [tags$w]
      if {[has $tags node]} {
          regexp {of:([^ ]+)} $tags -> poly
          regexp {at:([^ ]+)} $tags -> pos
          set coords [$w coords $poly]
          set pos2 [expr {$pos==0? [llength $coords]-2 : $pos-2}]
          foreach {x0 y0} [lrange $coords $pos end] break
          foreach {x1 y1} [lrange $coords $pos2 end] break
          set x [expr {($x0 + $x1) / 2}]
          set y [expr {($y0 + $y1) / 2}]
          $w coords $poly [linsert $coords $pos $x $y]
          polydraw'markNodes $w $poly
          set polydraw(modified) 1
      }
    }
    proc polydraw'mark {w x y} {
      #-- extend a line, or prepare a node for moving
      variable ::dinah::zonemaker::polydraw
      set x [$w canvasx $x]; set y [$w canvasy $y]
      catch {unset polydraw(current$w)}
      if {[has [tags$w] node]} {
          set polydraw(current$w) [$w find withtag current]
          set polydraw(x$w)       $x
          set polydraw(y$w)       $y
      } else {
          polydraw'add $w $x $y
      }
    }
    proc polydraw'markNodes {w item} {
      #-- decorate a polygon with square marks at its nodes
      $w delete of:$item
      set pos 0
      foreach {x y} [$w coords $item] {
          set coo [list [expr $x-2] [expr $y-2] [expr $x+2] [expr $y+2]]
          $w create rect $coo -fill red -tag "node of:$item at:$pos"
          incr pos 2
      }
    }
    proc polydraw'move {w x y {all 0}} {
      #-- move a node of, or a whole polygon
      variable ::dinah::zonemaker::polydraw
      set x [$w canvasx $x]; set y [$w canvasy $y]
      if {[info exists polydraw(current$w)]} {
          set dx [expr {$x - $polydraw(x$w)}]
          set dy [expr {$y - $polydraw(y$w)}]
          set polydraw(x$w) $x
          set polydraw(y$w) $y
          if {!$all} {
              polydraw'redraw $w $dx $dy
              $w move $polydraw(current$w) $dx $dy
          } elseif [regexp {of:([^ ]+)} [tags$w] -> poly] {
              $w move $poly    $dx $dy
              $w move of:$poly $dx $dy
          }
          set polydraw(modified) 1
      }
    }
    proc polydraw'redraw {w dx dy} {
      #-- update a polygon when one node was moved
      set tags [tags$w]
      if [regexp {of:([^ ]+)} $tags -> poly] {
          regexp {at:([^ ]+)} $tags -> from
          set coords [$w coords $poly]
          set to [expr {$from + 1}]
          set x [expr {[lindex $coords $from] + $dx}]
          set y [expr {[lindex $coords $to]   + $dy}]
          $w coords $poly [lreplace $coords $from $to $x $y]
      }
    }
    #--------------------------------------- more general routines
    proc has {list element} {expr {[lsearch $list $element]>=0}}
    proc int x  { expr int($x) }
    #--------------------------------------- application
    proc getZones {} {
        variable ::dinah::db
        variable ::dinah::zonemaker::imageId
        variable ::dinah::zonemaker::fs
        set fs {}
        set found [::dinah::findInDim $::dinah::dimFragments $imageId]
        if {$found != {}} {
            if {[lindex $found 1] == 0} {
                set fs [lrange [lindex $db($::dinah::dimFragments) [lindex $found 0]] 1 end]
            } else {
                error "an image fragment cannot be decomposed in fragments"
            }
        }
        return $fs
    }

    proc loadImage {} {
        variable ::dinah::db
        variable ::dinah::zonemaker::polydraw
        variable ::dinah::zonemaker::img
        variable ::dinah::zonemaker::imageId
        variable ::dinah::zonemaker::c
        catch {image delete $img}
        set resolution "_high"
        set fn $db(base)[::dinah::db'get $imageId path]$resolution$db(imgExtension)
        if {! [file exists $fn]} {
            set fn $db(base)[::dinah::db'get $imageId path]$db(imgExtension)
        }
        set img [image create photo -file $fn]
        $c configure -scrollregion [list 0 0 [image width $img] [image height $img]]
        $c create image 0 0 -image $img -tag "img" -anchor nw
        $c delete poly0 poly of:*
        foreach f [getZones] {
            polydraw'markNodes $c [$c create poly $db($f,coords) -fill {} -tag "poly id_$f" -outline red -width 2]
        }
        set polydraw(modified) 0
    }

    proc update_poly {id coords} {
        variable ::dinah::db
        variable ::dinah::zonemaker::polydraw
        variable ::dinah::zonemaker::img
        variable ::dinah::zonemaker::c
        set db($id,coords) $coords 
        rebuild_poly_images $id
    }

    proc delete_poly_images {id} {
        variable ::dinah::db
        foreach resolution {high low} {
            set fn $db(base)[::dinah::db'get $id path]_$resolution$db(imgExtension)
            file delete $fn
        }
    }

    proc rebuild_poly_images {id} {
        variable ::dinah::db
        variable ::dinah::zonemaker::polydraw
        variable ::dinah::zonemaker::img
        variable ::dinah::zonemaker::c
        variable ::dinah::zonemaker::convert
        set pts ""; set xs {}; set ys {}
        set scale 40%
        set imgPath [$img cget -file]
        delete_poly_images $id
        foreach resolution {high low} {
            set $resolution $db(base)[::dinah::db'get $id path]_$resolution$db(imgExtension)
        }
        foreach {x y} $db($id,coords) {
            set x [int $x]; set y [int $y]
            set pts [concat $pts "$x,$y"]
            lappend xs $x
            lappend ys $y
        }
        set xmax [lindex [lsort -integer -decreasing $xs] 0]
        set xmin [lindex [lsort -integer $xs] 0]
        set ymax [lindex [lsort -integer -decreasing $ys] 0]
        set ymin [lindex [lsort -integer $ys] 0]
        set croprect [expr $xmax - $xmin]x[expr $ymax - $ymin]+$xmin+$ymin
        exec $convert -size [image width $img]x[image height $img] xc:white \
            -fill $imgPath -draw "polygon $pts" polygon.jpeg
        exec $convert polygon.jpeg -crop $croprect +repage $high
        file delete polygon.jpeg
        exec -ignorestderr $convert $high -scale $scale $low
    }

    proc create_poly {coords} {
        variable ::dinah::db
        variable ::dinah::zonemaker::imageId
        set id [::dinah::db'new {isa Page label ""}]
        set db($id,path) $db($imageId,path)_frag$id
        set db($id,coords) $coords
        set found [::dinah::findInDim $::dinah::dimFragments $imageId]
        if {$found == {}} {
            lappend db($::dinah::dimFragments) [list $imageId $id]
        } else {
            set row [lindex $db($::dinah::dimFragments) [lindex $found 0]]
            lappend row $id
            lset db($::dinah::dimFragments) [lindex $found 0] $row
        }
        rebuild_poly_images $id
    }

    proc delete_poly {id} {
        variable ::dinah::db
        set found [::dinah::findInDim $::dinah::dimFragments $id]
        set row [lindex $db($::dinah::dimFragments) [lindex $found 0]]
        if {[llength $row] == 2} {
            set db($::dinah::dimFragments) [lreplace $db($::dinah::dimFragments) [lindex $found 0] [lindex $found 0]]
        } else {
            set row [lreplace $row [lindex $found 1] [lindex $found 1]]
            lset db($::dinah::dimFragments) [lindex $found 0] $row
        }
    }

    proc save {} {
        variable ::dinah::db
        variable ::dinah::zonemaker::polydraw
        variable ::dinah::zonemaker::img
        variable ::dinah::zonemaker::c
        variable ::dinah::zonemaker::fs
        set seen {}
        foreach p [$c find withtag poly] {
            set id ""
            foreach t [$c gettags $p] {
                regexp {^id_(.*)} $t -> id
                if {$id ne ""} {break}
            }
            if {$id ne ""} {
                if {$db($id,coords) != [$c coords $p]} {
                    update_poly $id [$c coords $p]
                }
                lappend seen $id
            } else {
                create_poly [$c coords $p]
            }
        }
        foreach f $fs {
            if {$f ni $seen} {
                delete_poly $f
            }
        }
        set polydraw(modified) 0
    }

    proc wq {t container} {
        variable ::dinah::zonemaker::polydraw
        if {$polydraw(modified)} {::dinah::zonemaker::save}
        if {$container ne ""} {$container reload}
        ::dinah::destroyToplevel $t
    }

    proc run {id container} {
        variable ::dinah::zonemaker::c
        variable ::dinah::zonemaker::imageId
        variable ::dinah::zonemaker::polydraw
        array set polydraw {}
        set imageId $id
        set t [::dinah::newToplevel .tFragmentEditor] 
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
        
        set polydraw(modified) 0
        polydraw $c
        
        #catch {console show}
        
        bind $t <Key-Escape> [list ::dinah::zonemaker::wq $t $container]

        loadImage 
        wm attributes $t -fullscreen 1
        focus -force $t
    }
}
