itcl::class Txt {
    inherit Obj

    public variable txtWindow
    private variable fontsize "10"
    private variable saveStateLabel ""
    private variable tagNameLabel ""

    constructor {id} { set dbid $id }

    destructor {
        destroy $frame
        destroy $standalone
    }

    public method save {}
    public method showSavedState {}
    public method isSaved {}
    private method load {w}
    private method events {}
    private method newBindings {}
    private method defaultTags {}
    public method newInterval {{tagName ""}}
    public method openInterval {}
    public method interpretLine {}
    public method interpretBuffer {}
    public method setStyle {style}
    public method contextualMenu {}
    public method execMenuCmd {name}
    public method afterLayout {}
    public method specificLayout {}
    public method click {w x y}
    public method deleteSelection {}
    public method initNewInterval {name fragId}
    public method newStone {tagName}
    public proc cr {w}
    public proc insert {w s}
}

itcl::body Txt::deleteSelection {} {
    set tags [$txtWindow tag names current]
    set sel [$txtWindow tag ranges sel]
    if {$sel eq ""} {return}
    foreach t $tags {
        set id ""
        regexp {^interval(.*)} $t -> id
        if {$id ne "" && $container ne ""} {
            foreach t $tags {
                $txtWindow tag remove $t {*}$sel
            }
            if {[$txtWindow tag ranges "interval$id"] eq ""} {
                foreach d [list $::dinah::dimAttribute $::dinah::dimNote $::dinah::dimAlternative] {
                    set found [::dinah::findInDim $d $id]
                    if {$found != {}} {
                        set si [lindex $found 0]
                        set ::dinah::db($d) [lreplace $::dinah::db($d) $si $si]
                    }
                }
                ::dinah::remfrag $::dinah::dimFragments $id
            }
        }
    }
}

itcl::body Txt::click {w x y} {
    $tagNameLabel configure -text "" 
    foreach t [$txtWindow tag names @$x,$y] {
        if {! [regexp {^interval.*} $t]} {
            $tagNameLabel configure -text $t
        }
        set id ""
        regexp {^interval(.*)} $t -> id
        if {$id ne "" && $container ne ""} {
            set t [$container getTopFrame]
            set c [$container getContainer]
            if {[$c frameOfQuart 1] eq $t} {
                foreach {quartIndex dim} [list 2 $::dinah::dimAttribute 3 $::dinah::dimNote 4 $::dinah::dimAlternative] {
                    set quart [$c quart $quartIndex]
                    $quart setX $dim
                    $quart setY $::dinah::dimNil
                    $quart updateEntries
                    $quart setWWidth 1
                    $quart buildAndGrid $id
                    $quart scRight
                }
                $container getFocus
            }
        }
    }
}

itcl::body Txt::contextualMenu {} {
    set menu [menu $frame.contextualMenu]
    set names {}
    foreach {k pairs} [array get ::dinah::txtClick *,option] {
        regexp {(.*),option} $k -> name
        lappend names $name
    }
    $menu add command -label delete -command [list $this deleteSelection]
    foreach name [lsort -dictionary $names] {
        $menu add command -label $name -command [list $this execMenuCmd $name]
    }
    bind $txtWindow $::dinah::mouse(B3) [list tk_popup $menu %X %Y]
}

itcl::body Txt::execMenuCmd {name} {
    if {![isSaved]} {return ""}
    if {[$txtWindow tag ranges sel] != {}} {
        set intervalId [newInterval $name]
    } elseif {[$txtWindow tag ranges sel] == {} && $name in {cb lb gap}} {
        set intervalId [newStone $name]
    }
    if {$intervalId ne ""} {
        initNewInterval $name $intervalId
    }
}

itcl::body Txt::initNewInterval {name fragId} {
    if {[::dinah::findInDim $::dinah::dimAttribute $fragId] eq ""} {
        set structId [::dinah::emptyNode "Struct"]
        lappend ::dinah::db($::dinah::dimAttribute) [list $fragId $structId] 
    }
    if {$name in {abbr sic orig}} {
        if {[::dinah::findInDim $::dinah::dimAlternative $fragId] eq ""} {
            set alternativeId [::dinah::emptyNode "Txt" "Alternative pour $fragId"]
            lappend ::dinah::db($::dinah::dimAlternative) [list $fragId $alternativeId] 
        }
    }
    set noteId [::dinah::emptyNode Txt "note ($fragId)"]
    lappend ::dinah::db($::dinah::dimNote) [list $fragId $noteId]
}

itcl::body Txt::setStyle {style} {
    set sel [$txtWindow tag ranges sel]
    if {$sel ne ""} {
        if {[lsearch -exact [$txtWindow tag names [lindex $sel 0]] $style] < 0} {
            $txtWindow tag add $style {*}$sel
        } else {
            $txtWindow tag remove $style {*}$sel
        }
    }
}

itcl::body Txt::interpretLine {} {
    regexp {^(.*)\..*$} [$txtWindow index insert] -> l
    set i0 "$l.0"
    set i1 "$l.end"
    set currentLine [$txtWindow get -- $i0 $i1]
    eval $currentLine
}

itcl::body Txt::interpretBuffer {} {
    set t [text .temptext]
    load $t
    eval [$t get -- 1.0 end]
    destroy $t
}

itcl::body Txt::newInterval {{tagName ""}} {
    variable ::dinah::db
    set intervalId [::dinah::db'new [list isa Txt txt [$txtWindow dump -all {*}[$txtWindow tag ranges sel]] label [$txtWindow get {*}[$txtWindow tag ranges sel]]]]
    ::dinah::copy $intervalId "after" $::dinah::dimFragments $dbid
    set intervalName "interval$intervalId"
    set intervalRange [$txtWindow tag ranges sel]
    eval $txtWindow tag add interval {*}$intervalRange
    eval $txtWindow tag add  $intervalName {*}$intervalRange
    if {$tagName ne ""} {$txtWindow tag add $tagName {*}$intervalRange}
    set noteId [::dinah::emptyNode Txt "note ($intervalId)"]
    lappend ::dinah::db($::dinah::dimNote) [list $intervalId $noteId]
    save
    return $intervalId
}

itcl::body Txt::newStone {tagName} {
    set intervalId [::dinah::emptyNode Txt $tagName]
    ::dinah::copy $intervalId "after" $::dinah::dimFragments $dbid
    set intervalName "interval$intervalId"
    $txtWindow insert insert "$tagName\n" [list interval $intervalName $tagName]
    return $intervalId
}

itcl::body Txt::openInterval {} {
    foreach t [$txtWindow tag names insert] {
        set id ""
        regexp {^interval(.*)} $t -> id
        if {$id ne ""} {
            ::dinah::dimWin $id
        }
    }
}

itcl::body Txt::specificLayout {} {
    variable ::dinah::db

    set btnSave [button $center.menu.btnSave -text "save" -command [list $this save]]
    set saveStateLabel [label $center.menu.saveState -text ""]
    pack $saveStateLabel -side left -padx 4 -pady 4
    pack $btnSave -side left -padx 4 -pady 4
    set tagNameLabel [label $center.menu.tagNameLabel -text ""]
    pack $tagNameLabel -side right -padx 4 -pady 4

    frame $center.main
    text $center.main.text \
      -yscrollcommand [list $center.main.yscroll set] \
      -highlightthickness 0 -borderwidth 0\
      -width 50 -height 20 -wrap word -undo 1\
      -font "$::dinah::font $fontsize normal"
    scrollbar $center.main.yscroll -orient vertical \
      -command [list $center.main.text yview]
    pack $center.main.yscroll -side right -fill y
    pack $center.main.text -side right -fill both -expand 1

}

itcl::body Txt::afterLayout {} {
    set txtWindow $center.main.text

    defaultTags
    newBindings
    load $txtWindow
    showSavedState
    events
    contextualMenu
    $txtWindow edit modified 0
    #::dinah::desactivateMouse $txtWindow
}

itcl::body Txt::load {w} {
    variable ::dinah::db
    set current 1.0
    array set tag {}
    $w delete 1.0 end
    foreach {key value index} $db($dbid,txt) {
        switch $key {
            text    { $w insert $index $value }
            mark    { if {$value == "current"} {set current $index} }
            tagon   { set tag($value) $index }
            tagoff  { $w tag add $value $tag($value) $index }
        }
    }
    $w mark set current $current
}

itcl::body Txt::save {} {
    variable ::dinah::db
    # a bug (or feature?) of the tk text widget when using the dump command adds
    # a newline at the end of the dump text:
    set dump [$txtWindow dump -text -tag 1.0 end]
    set splitdump [split $dump "\n"]
    if { [regexp {(.*)text \{$} [lindex $splitdump end-1] -> match] && \
         [regexp {\}.*$} [lindex $splitdump end]] } {
        set dump [join [concat [lrange $splitdump 0 end-2] [list $match]] "\n"]
    }
    set db($dbid,txt) $dump
    $txtWindow edit modified 0
}

itcl::body Txt::newBindings {} {
    foreach seq [bind Text] {bind modText $seq [bind Text $seq]}
    bind modText <KeyPress> {::dinah::Txt::insert %W %A}
    bind modText <KeyPress> +{break}
    bind modText <Return> +{break}
    #bind modText <Return> {::dinah::Txt::cr %W}
    bindtags $txtWindow [list $txtWindow modText all]
}

# slightly modified from ::tk::TextInsert
itcl::body Txt::insert {w s} {
    if {$s eq "" || [$w cget -state] eq "disabled"} {
        return
    }
    $w edit modified 1
    set compound 0
    if {[::tk::TextCursorInSelection $w]} {
        set compound [$w cget -autoseparators]
        if {$compound} {
            $w configure -autoseparators 0
            $w edit separator
        }
        $w delete sel.first sel.last
    }
    $w insert insert $s [$w tag names insert-1c]
    $w see insert
    if {$compound} {
        $w edit separator
        $w configure -autoseparators 1
    }
}

itcl::body Txt::cr {w} {
    ::dinah::Txt::insert $w \n
    set prange [$w tag prevrange P insert]
    $w tag remove P [lindex $prange 0] [lindex $prange 1]
    $w tag add P [lindex $prange 0] insert-1c
    $w tag add P insert-1c [lindex $prange 1]
    if {[$w cget -autoseparators]} {
        $w edit separator
    }
}

itcl::body Txt::defaultTags {} {
    $txtWindow tag configure P -font "$::dinah::font $fontsize normal" -lmargin1 30 -spacing3 30
    $txtWindow tag configure STRONG -font "$::dinah::font $fontsize bold"
    $txtWindow tag configure EM -font "$::dinah::font $fontsize italic"
    $txtWindow tag configure UNDERLINE -font "$::dinah::font $fontsize underline"
    $txtWindow tag configure OVERSTRIKE -font "$::dinah::font $fontsize overstrike"
    $txtWindow tag configure SUB -font "$::dinah::font $fontsize normal" -offset -6
    $txtWindow tag configure SUP -font "$::dinah::font $fontsize normal" -offset 6
    $txtWindow tag configure TITLE1 -font "$::dinah::font 15 underline"
    $txtWindow tag configure TITLE2 -font "$::dinah::font 13 underline"
    $txtWindow tag configure TITLE3 -font "$::dinah::font 11 underline italic"
    #$txtWindow tag configure interval -background yellow
    foreach {k pairs} [array get ::dinah::txtClick *,option] {
        regexp {(.*),option} $k -> name
        foreach {optionName optionValue} $pairs {
            $txtWindow tag configure $name $optionName $optionValue
        }
    }
}

itcl::body Txt::showSavedState {} {
    if {[isSaved]} {
        $saveStateLabel configure -text ""
    } else {
        $saveStateLabel configure -text "modified"
    }
}

itcl::body Txt::isSaved {} {
    return [expr {! [$txtWindow edit modified]}]
}

itcl::body Txt::events {} {
    bind $txtWindow <<Modified>> [list $this showSavedState]
    bind $txtWindow <Control-Key-s> [list $this save]
    bind $txtWindow <Control-Key-s> +{break}
    bind $txtWindow <Control-Key-n> [list $this newInterval]
    bind $txtWindow <Control-Key-n> +{break}
    bind $txtWindow <Control-Key-g> [list $this openInterval]
    bind $txtWindow <Control-Key-g> +{break}
    bind $txtWindow <Control-Key-E> [list $this interpretLine]
    bind $txtWindow <Control-Key-E> +{break}
    bind $txtWindow <Control-Key-b> [list $this setStyle STRONG]
    bind $txtWindow <Control-Key-b> +{break}
    bind $txtWindow <Control-Key-i> [list $this setStyle EM]
    bind $txtWindow <Control-Key-i> +{break}
    bind $txtWindow <Control-Key-u> [list $this setStyle UNDERLINE]
    bind $txtWindow <Control-Key-u> +{break}
    bind $txtWindow <Control-Key-o> [list $this setStyle OVERSTRIKE]
    bind $txtWindow <Control-Key-o> +{break}
    bind $txtWindow <Control-Key-t> [list $this setStyle SUP]
    bind $txtWindow <Control-Key-t> +{break}
    bind $txtWindow <Control-Key-d> [list $this setStyle SUB]
    bind $txtWindow <Control-Key-d> +{break}
    bind $txtWindow <Control-Key-$::dinah::keyboard(under1)> [list $this setStyle TITLE1]
    bind $txtWindow <Control-Key-$::dinah::keyboard(under1)> +{break}
    bind $txtWindow <Control-Key-$::dinah::keyboard(under2)> [list $this setStyle TITLE2]
    bind $txtWindow <Control-Key-$::dinah::keyboard(under2)> +{break}
    bind $txtWindow <Control-Key-$::dinah::keyboard(under3)> [list $this setStyle TITLE3]
    bind $txtWindow <Control-Key-$::dinah::keyboard(under3)> +{break}
    $txtWindow tag bind interval <1> [list $this click %w %x %y]
}
