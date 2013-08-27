itcl::class Obj {
    public variable dbid ""
    public variable container ""
    public variable frame ""

    # is the image inside a standalone window?
    # IF it is THEN $standalone is the name of the toplevel window
    # containing the image ELSE $standalone is ""
    protected variable standalone ""
    protected variable notificationLabel ""
    protected variable inDim
    protected variable center ""
    protected variable left ""
    protected variable right ""
    protected variable top ""
    protected variable bottom ""
    protected variable genericMenu ""
    protected variable inDimMenu ""

    method select {} {catch {$container buildAndGrid $dbid}}

    method newNodeOnRight {type} {
        if {[catch {$container buildAndGrid $dbid}]} {return}
        $container new $type
    }

    method newNodeOnLeft {type} {
        if {[catch {$container buildAndGrid $dbid}]} {return}
        $container new $type 0
    }

    method getContainer {} {return $container}

    method z {} {return ""}

    method specificLayout {} {return ""}

    method afterLayout {} {return ""}

    method mkWindow {{parentw ""}} {
        if {$parentw == ""} {
            set parentw [toplevel .t[::dinah::objname $this]]
            set standalone $parentw
        }

        set frame [frame $parentw.[::dinah::objname $this] -borderwidth 0]
        set left [frame $frame.left -width $::dinah::separatorSize]
        set top [frame $frame.top -height $::dinah::separatorSize]
        set center [frame $frame.center]
        set bottom [frame $frame.bottom -height $::dinah::separatorSize]
        set right [frame $frame.right -width $::dinah::separatorSize]
        entry $center.foldedEntry -textvariable ::dinah::db($dbid,label) -font "$::dinah::font 15 underline" -justify center
        frame $center.menu
        set notificationLabel [label $center.menu.notification -text ""]
        set inDim [label $center.menu.inDim -text "?"]

        set inDimMenu [menu $frame.inDimMenu]
        set genericMenu [menu $frame.genericMenu]
        $genericMenu add command -label "delete (Ctrl-d)" -command [list $this delete]
        $genericMenu add command -label fold -command [list $this fold]
        $genericMenu add command -label clone -command [list $this makeClone]
        bind $center.menu $::dinah::mouse(B3) [list tk_popup $genericMenu %X %Y]
        bind $center.menu <Double-1> [list $this select]
        bind $center.menu <1> [list $this menu1 %X %Y]
        bind $center.menu.inDim <1> [list $this menuInDim %X %Y]
        bind $center.menu.notification <1> [list $this menu1 %X %Y]
        bind $center.menu.notification <B1-Motion> [list $this menu1motion %X %Y]
        bind $center.foldedEntry <Double-1> [list $this unfold]

        set rightMenu [menu $frame.rightMenu]
        $rightMenu add command -label "new txt" -command [list $this newNodeOnRight Txt]
        bind $right $::dinah::mouse(B3) [list tk_popup $rightMenu %X %Y]

        set leftMenu [menu $frame.leftMenu]
        $leftMenu add command -label "new txt" -command [list $this newNodeOnLeft Txt]
        bind $left $::dinah::mouse(B3) [list tk_popup $leftMenu %X %Y]

        specificLayout
        layout
        afterLayout
        dragAndDrop
    }

    method menu1 {X Y} {
        if {! [catch {$container isa Whiteboard} isaWhiteboard]} {if {$isaWhiteboard} {
            $container getFocus
            $container setCursorOnId $dbid
            set ::dinah::memx [[$container getCanvas] canvasx $X]
            set ::dinah::memy [[$container getCanvas] canvasx $Y]
        }}
    }

    method menu1motion {X Y} {
        if {! [catch {$container isa Whiteboard} isaWhiteboard]} {if {$isaWhiteboard} {
            set x [[$container getCanvas] canvasx $X]
            set y [[$container getCanvas] canvasy $Y]
            set dx [expr {$X - $::dinah::memx}]
            set dy [expr {$Y - $::dinah::memy}]
            $container moveItem [$container getItemFromId $dbid] $dx $dy 
            set ::dinah::memx $X
            set ::dinah::memy $Y
        }}
    }

    method fold {} {
        unsetBindings
        pack forget $center.menu $center.main
        pack $center.foldedEntry -side top -fill x -expand 1 -padx 4 -pady 4
        focus $center.foldedEntry
    }

    method unfold {} {
        pack forget $center.foldedEntry
        pack $center.menu -side top -fill x -padx 4 -pady 4
        pack $center.main -side top -fill both -expand true -padx 4 -pady 4
    }

    method menuInDim {X Y} {
        if {! [catch {$container isa Dim} isaDim]} {if {$isaDim} {
            $inDimMenu delete 0 end
            set dims [::dinah::dbGetDimForId $dbid]
            if {[llength $dims] > 0} {
                foreach {dim segIndex fragIndex} $dims {
                    $inDimMenu add command -label $dim -command [list $this setXDim $dim]
                }
                tk_popup $inDimMenu $X $Y
            }
        }}
    }

    method setXDim {dim} {
        if {! [catch {$container isa Dim} isaDim]} {if {$isaDim} {
            $container setXAndUpdate $dim
        }}
    }

    method layout {} {
        if {[llength [::dinah::dbGetDimForId $dbid]] > 0} {
            pack $inDim -side left -padx 4 -pady 4
        }
        pack $notificationLabel -side left -padx 4 -pady 4
        pack $center.menu -side top -fill x -padx 4 -pady 4
        pack $center.main -side top -fill both -expand true -padx 4 -pady 4
        grid $top -sticky ew -column 0 -row 0 -columnspan 3
        grid $left -sticky ns -column 0 -row 1
        grid $center -sticky news -column 1 -row 1
        grid $right -sticky ns -column 2 -row 1
        grid $bottom -sticky ew -column 0 -row 2 -columnspan 3
        grid rowconfigure $frame 0 -minsize $::dinah::separatorSize -weight 0
        grid rowconfigure $frame 1 -weight 1
        grid rowconfigure $frame 2 -minsize $::dinah::separatorSize -weight 0
        grid columnconfigure $frame 0 -minsize $::dinah::separatorSize -weight 0
        grid columnconfigure $frame 1 -weight 1
        grid columnconfigure $frame 2 -minsize $::dinah::separatorSize -weight 0
        pack $frame -fill both -expand 1
    }

    method dragAndDrop {} {
        DragSite::register $center.menu -dragevent 1 -draginitcmd [list $this draginitcmd] -dragendcmd [list $this dragendcmd]
        foreach e [list $right $bottom $left $top] {
            DropSite::register $e -dropcmd [list $this dropcmd] -dropovercmd [list $this dropovercmd] -droptypes {Obj copy Obj {move control}}
        }
    }

    method notificate {txt} {
        $notificationLabel configure -text [concat [$notificationLabel cget -text] $txt]
    }

    method openNS {} {
        $top configure -bg $::dinah::openColor
        $bottom configure -bg $::dinah::openColor
    }

    method closeNS {} {
        $top configure -bg $::dinah::closeColor
        $bottom configure -bg $::dinah::closeColor
    }

    method openEW {} {
        $left configure -bg $::dinah::openColor
        $right configure -bg $::dinah::openColor
    }

    method closeEW {} {
        $left configure -bg $::dinah::closeColor
        $right configure -bg $::dinah::closeColor
    }

    method setMenuColor {color} {
        $frame.center.menu configure -background $color
    }

    method setContainer {c} {
        set container $c
        if {! [catch {$container isa Whiteboard} isaWhiteboard]} {if {$isaWhiteboard} {
            $genericMenu add command -label "remove from board" -command [list $container delete $dbid]
            $genericMenu add command -label next -command [list $container next $dbid]
            $genericMenu add command -label prev -command [list $container prev $dbid]
        }}
    }

    method draginitcmd {src x y toplevelSymbol} {
        if {! [catch {$container isa Dim} isaDim]} {if {$isaDim} {
            if {$dbid in [$container scRow]} {
                set data [list [$container getX] $dbid]
            } else {
                set data [list [$container getY] $dbid]
            }
        }} else {
            set data $dbid
        }
        return [list Obj {copy move} $data]
    }

    method dragendcmd {src target op type data dropResult} {
        if {! [catch {$container isa Dim} isaDim]} {if {$isaDim} { $container reload }}
        if {! [catch {$dropResult isa Dim} isaDim]} {if {$isaDim} { $dropResult reload }}
        if {! [catch {$dropResult isa Whiteboard} isaWhiteboard]} {if {$isaWhiteboard} { $dropResult reload }}
    }

    method dropcmd {target src x y op type data} {
        if {! [catch {$container isa Dim} isaDim]} {if {$isaDim} {
            set srcDim [lindex $data 0]
            set srcId [lindex $data end]
            if {$op eq "move" && [::dinah::editable $srcDim]} {
                if {$target eq $right && [::dinah::editable [$container getX]]} {
                    ::dinah::dbMoveNodeBetweenDims $srcDim $srcId after [$container getX] $dbid
                } elseif {$target eq $left && [::dinah::editable [$container getX]]} {
                    ::dinah::dbMoveNodeBetweenDims $srcDim $srcId before [$container getX] $dbid
                } elseif {$target eq $bottom && [::dinah::editable [$container getY]]} {
                    ::dinah::dbMoveNodeBetweenDims $srcDim $srcId after [$container getY] $dbid
                } elseif {$target eq $bottom && [::dinah::editable [$container getY]]} {
                    ::dinah::dbMoveNodeBetweenDims $srcDim $srcId before [$container getY] $dbid
                }
            } elseif {$op eq "force"} {
                if {$target eq $right && [::dinah::editable [$container getX]]} {
                    ::dinah::dbInsertNodeIntoDim $srcId after [$container getX] $dbid
                } elseif {$target eq $left && [::dinah::editable [$container getX]]} {
                    ::dinah::dbInsertNodeIntoDim $srcId before [$container getX] $dbid
                } elseif {$target eq $bottom && [::dinah::editable [$container getY]]} {
                    ::dinah::dbInsertNodeIntoDim $srcId after [$container getY] $dbid
                } elseif {$target eq $bottom && [::dinah::editable [$container getY]]} {
                    ::dinah::dbInsertNodeIntoDim $srcId before [$container getY] $dbid
                }
            }
        }}
        if {! [catch {$container isa Whiteboard} isaWhiteboard]} {if {$isaWhiteboard} {
            ::dinah::dbInsertNodeIntoDim $data before [$container getCurrentDim] $dbid
        }}
        $target configure -bg $::dinah::targetColor($target)
        return $container
    }

    method dropovercmd {target src evt x y op type data} {
        if {$evt eq "enter"} {
            set ::dinah::targetColor($target) [$target cget -bg]
            $target configure -bg pink
        }
        if {$evt eq "leave"} {
            $target configure -bg $::dinah::targetColor($target)
        }
        return 3
    }

    method delete {} {
        if {! [catch {$container isa Dim} isaDim]} {if {$isaDim} {
            $container delete
        }}
        if {! [catch {$container isa Whiteboard} isaWhiteboard]} {if {$isaWhiteboard} {
            ::dinah::dbRemFragFromDim [$container getCurrentDim] $dbid
            $container reload
        }}
    }

    method makeClone {} {
        ::dinah::dbClone $dbid
        $container reload
    }

}
