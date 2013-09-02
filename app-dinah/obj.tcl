itcl::class Obj {
    protected variable dbid ""
    protected variable container ""
    protected variable frame ""
    # if the object is not managed by a container (i.e. a dimensional view,
    # a whiteboard, ...) then $standalone is the name of the toplevel that
    # contains the representation of the object. Otherwise the value of
    # $standalone is "":
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
    protected variable whiteboardX ""
    protected variable whiteboardY ""

    ##################
    # PUBLIC METHODS #
    ##################

    public method select {} {catch {$container buildAndGrid $dbid}}

    public method newNodeOnRight {type} {
        if {[catch {$container buildAndGrid $dbid}]} {return}
        $container new $type
    }

    public method newNodeOnLeft {type} {
        if {[catch {$container buildAndGrid $dbid}]} {return}
        $container new $type 0
    }

    public method z {} {return ""}

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
        entry $center.foldedEntry -textvariable ::dinah::db($dbid,label) \
            -font "$::dinah::font 15 underline" -justify center
        frame $center.menu
        set notificationLabel [label $center.menu.notification -text ""]
        set inDim [label $center.menu.inDim -text "?"]

        set inDimMenu [menu $frame.inDimMenu]
        set genericMenu [menu $frame.genericMenu]
        $genericMenu add command -label fold -command [list $this fold]
        bind $center.menu $::dinah::mouse(B3) [list tk_popup $genericMenu %X %Y]
        bind $center.menu <Double-1> [list $this select]
        bind $center.menu <1> [list $this storeCoordinates %X %Y]
        bind $center.menu.inDim <1> [list $this menuInDim %X %Y]
        bind $center.menu.notification <1> [list $this storeCoordinates %X %Y]
        bind $center.menu.notification <B1-Motion> [list $this moveItem %X %Y]
        bind $center.foldedEntry <Double-1> [list $this unfold]

        set rightMenu [menu $frame.rightMenu]
        $rightMenu add command -label "new txt" \
            -command [list $this newNodeOnRight Txt]
        bind $right $::dinah::mouse(B3) [list tk_popup $rightMenu %X %Y]

        set leftMenu [menu $frame.leftMenu]
        $leftMenu add command -label "new txt" \
            -command [list $this newNodeOnLeft Txt]
        bind $left $::dinah::mouse(B3) [list tk_popup $leftMenu %X %Y]

        specificLayout
        layout
        afterLayout
        dragAndDrop
    }

    public method storeCoordinates {X Y} {
        if {! [catch {$container isa Whiteboard} isaWhiteboard]} {
        if {$isaWhiteboard} {
            $container getFocus
            $container setCursorOnId $dbid
            set whiteboardX [[$container getCanvas] canvasx $X]
            set whiteboardY [[$container getCanvas] canvasy $Y]
        }}
    }

    public method moveItem {X Y} {
        if {! [catch {$container isa Whiteboard} isaWhiteboard]} {
        if {$isaWhiteboard} {
            set x [[$container getCanvas] canvasx $X]
            set y [[$container getCanvas] canvasy $Y]
            set dx [expr {$X - $whiteboardX}]
            set dy [expr {$Y - $whiteboardY}]
            $container moveItem [$container getItemFromId $dbid] $dx $dy
            set whiteboardX $X
            set whiteboardY $Y
        }}
    }

    public method fold {} {
        pack forget $center.menu $center.main
        pack $center.foldedEntry -side top -fill x -expand 1 -padx 4 -pady 4
        focus $center.foldedEntry
    }

    public method unfold {} {
        pack forget $center.foldedEntry
        pack $center.menu -side top -fill x -padx 4 -pady 4
        pack $center.main -side top -fill both -expand true -padx 4 -pady 4
    }

    public method menuInDim {X Y} {
        if {! [catch {$container isa Dim} isaDim]} {
        if {$isaDim} {
            $inDimMenu delete 0 end
            set dims [::dinah::dbGetDimForId $dbid]
            foreach {dim segIndex fragIndex} $dims {
                $inDimMenu add command -label $dim \
                    -command [list $this setXDim $dim]
            }
            tk_popup $inDimMenu $X $Y
        }}
    }

    public method setXDim {dim} {
        if {! [catch {$container isa Dim} isaDim]} {if {$isaDim} {
            $container setXAndUpdate $dim
        }}
    }

    public method notificate {txt} {
        $notificationLabel configure -text \
            [concat [$notificationLabel cget -text] $txt]
    }

    # an object is circled by 4 thin borders
    # each border can be thought as either opened or closed
    # each border can take one of two colors ($::dinah::openColor &
    # $::dinah::closeColor)
    # in the context of a dimensional view a closed border means that if
    # another object can be seen adjacent along this border it doesn't mean
    # that the two objects are related by the current dimension
    # (viz. X-Dimension for EW borders, and Y-Dimension for NS borders)
    public method openNS {} {
        $top configure -bg $::dinah::openColor
        $bottom configure -bg $::dinah::openColor
    }

    public method closeNS {} {
        $top configure -bg $::dinah::closeColor
        $bottom configure -bg $::dinah::closeColor
    }

    public method openEW {} {
        $left configure -bg $::dinah::openColor
        $right configure -bg $::dinah::openColor
    }

    public method closeEW {} {
        $left configure -bg $::dinah::closeColor
        $right configure -bg $::dinah::closeColor
    }

    public method setMenuColor {color} {
        $frame.center.menu configure -background $color
    }

    public method getContainer {} { return $container }

    public method setContainer {c} { set container $c }

    public method draginitcmd {src x y toplevelBitmap} {
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

    public method dragendcmd {src target op type data dropResult} {
        # if the drop action failed, dropResult is set to 0 (false):
        if {!$dropResult} { return }
        # if the drop action succeeded, dropResult is set to the container
        # of the drop target:
        if {! [catch {$container isa Dim} isaDim]} {
        if {$isaDim} {
            $container reload
        }}
        if {! [catch {$dropResult isa Dim} isaDim]} {
        if {$isaDim} {
            $dropResult reload
        }}
        if {! [catch {$dropResult isa Whiteboard} isaWhiteboard]} {
        if {$isaWhiteboard} {
            $dropResult reload
        }}
    }

    public method dropcmd {target src x y op type data} {
        if {! [catch {$container isa Dim} isaDim]} {
        if {$isaDim} {
            set srcDim [lindex $data 0]
            set srcId [lindex $data end]
            if {$op eq "move"} {
                if {$target eq $right} {
                    if {[catch {::dinah::dbMoveFragmentBetweenDims \
                            $srcDim $srcId after \
                            [$container getX] $dbid} errorMsg]} {
                        tk_messageBox -message $errorMsg -icon error
                        return 0
                    }
                } elseif {$target eq $left} {
                    if {[catch {::dinah::dbMoveFragmentBetweenDims \
                            $srcDim $srcId before \
                            [$container getX] $dbid} errorMsg]} {
                        tk_messageBox -message $errorMsg -icon error
                        return 0
                    }

                } elseif {$target eq $bottom} {
                    if {[catch {::dinah::dbMoveFragmentBetweenDims \
                            $srcDim $srcId after \
                            [$container getY] $dbid} errorMsg]} {
                        tk_messageBox -message $errorMsg -icon error
                        return 0
                    }
                } elseif {$target eq $top} {
                    if {[catch {::dinah::dbMoveFragmentBetweenDims \
                            $srcDim $srcId before \
                            [$container getY] $dbid} errorMsg]} {
                        tk_messageBox -message $errorMsg -icon error
                        return 0
                    }
                }
            } elseif {$op eq "copy"} {
                if {$target eq $right} {
                    if {[catch {::dinah::dbInsertFragmentIntoDim $srcId after \
                            [$container getX] $dbid} errorMsg]} {
                        tk_messageBox -message $errorMsg -icon error
                        return 0
                    }
                } elseif {$target eq $left} {
                    if {[catch {::dinah::dbInsertFragmentIntoDim $srcId before \
                            [$container getX] $dbid} errorMsg]} {
                        tk_messageBox -message $errorMsg -icon error
                        return 0
                    }
                } elseif {$target eq $bottom} {
                    if {[catch {::dinah::dbInsertFragmentIntoDim $srcId after \
                            [$container getY] $dbid} errorMsg]} {
                        tk_messageBox -message $errorMsg -icon error
                        return 0
                    }
                } elseif {$target eq $top} {
                    if {[catch {::dinah::dbInsertFragmentIntoDim $srcId before \
                            [$container getY] $dbid} errorMsg]} {
                        tk_messageBox -message $errorMsg -icon error
                        return 0
                    }
                }
            }
        }}
        if {! [catch {$container isa Whiteboard} isaWhiteboard]} {
        if {$isaWhiteboard} {
            if {[catch {::dinah::dbInsertFragmentIntoDim $data before \
                    [$container getCurrentDim] $dbid} errorMsg]} {
                tk_messageBox -message $errorMsg -icon error
                return 0
            }
        }}
        $target configure -bg $::dinah::targetColor($target)
        return $container
    }

    public method dropovercmd {target src evt x y op type data} {
        if {$evt eq "enter"} {
            set ::dinah::targetColor($target) [$target cget -bg]
            $target configure -bg pink
        }
        if {$evt eq "leave"} {
            $target configure -bg $::dinah::targetColor($target)
        }
        return 3
    }

    #####################
    # PROTECTED METHODS #
    #####################

    protected method specificLayout {} {return ""}

    protected method afterLayout {} {return ""}

    ###################
    # PRIVATE METHODS #
    ###################

    private method layout {} {
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

    private method dragAndDrop {} {
        DragSite::register $center.menu -dragevent 1 \
            -draginitcmd [list $this draginitcmd] \
            -dragendcmd [list $this dragendcmd]
        foreach e [list $right $bottom $left $top] {
            DropSite::register $e -dropcmd [list $this dropcmd] \
                -dropovercmd [list $this dropovercmd] \
                -droptypes {Obj {copy none} Obj {move control}}
        }
    }

}
