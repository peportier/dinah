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


    method reload {} {
        load $txtWindow
    }

    method zoom {{delta 1}} {
        incr fontsize $delta
        $txtWindow configure -font [list -size $fontsize]
    }

    method deleteSelection {} {
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

    method click {w x y} {
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

    method contextualMenu {} {
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

    method execMenuCmd {name} {
        if {![isSaved]} {save}
        if {[$txtWindow tag ranges sel] != {}} {
            set intervalId [newInterval $name]
        } elseif {[$txtWindow tag ranges sel] == {} && $name in {cb lb gap}} {
            set intervalId [newStone $name]
        }
        if {$intervalId ne ""} {
            initNewInterval $name $intervalId
        }
    }

    method initNewInterval {name fragId} {
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

    method setStyle {style} {
        set sel [$txtWindow tag ranges sel]
        if {$sel ne ""} {
            if {[lsearch -exact [$txtWindow tag names [lindex $sel 0]] $style] < 0} {
                $txtWindow tag add $style {*}$sel
            } else {
                $txtWindow tag remove $style {*}$sel
            }
        }
    }

    method interpretLine {} {
        regexp {^(.*)\..*$} [$txtWindow index insert] -> l
        set i0 "$l.0"
        set i1 "$l.end"
        set currentLine [$txtWindow get -- $i0 $i1]
        eval $currentLine
    }

    method interpretBuffer {} {
        set t [text .temptext]
        load $t
        eval [$t get -- 1.0 end]
        destroy $t
    }

    method newInterval {{tagName ""}} {
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

    method newStone {tagName} {
        set intervalId [::dinah::emptyNode Txt $tagName]
        ::dinah::copy $intervalId "after" $::dinah::dimFragments $dbid
        set intervalName "interval$intervalId"
        $txtWindow insert insert "$tagName\n" [list interval $intervalName $tagName]
        return $intervalId
    }

    method openInterval {} {
        foreach t [$txtWindow tag names insert] {
            set id ""
            regexp {^interval(.*)} $t -> id
            if {$id ne ""} {
                ::dinah::dimWin $id
            }
        }
    }

    method specificLayout {} {
        variable ::dinah::db

        set btnSave [button $center.menu.btnSave -text "save" -command [list $this save]]
        set saveStateLabel [label $center.menu.saveState -text ""]
        pack $saveStateLabel -side left -padx 4 -pady 4
        pack $btnSave -side left -padx 4 -pady 4
        set zPlus [button $center.menu.zPlus -text "+" -command [list $this zoom 1]]
        set zMinus [button $center.menu.zMinus -text "-" -command [list $this zoom -1]]
        pack $zPlus -side left -padx 4 -pady 4
        pack $zMinus -side left -padx 4 -pady 4
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

    method afterLayout {} {
        set txtWindow $center.main.text

        defaultTags
        newBindings
        load $txtWindow
        showSavedState
        events
        contextualMenu
        $txtWindow edit modified 0
    }

    method load {w} {
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

    method save {} {
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

    method newBindings {} {
        foreach seq [bind Text] {bind modText $seq [bind Text $seq]}
        bind modText <KeyPress> {::dinah::Txt::insert %W %A}
        bind modText <KeyPress> +{break}
        bind modText <Return> +{break}
        #bind modText <Return> {::dinah::Txt::cr %W}
        bindtags $txtWindow [list $txtWindow modText all]
    }

    # slightly modified from ::tk::TextInsert
    proc insert {w s} {
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

    proc cr {w} {
        ::dinah::Txt::insert $w \n
        set prange [$w tag prevrange P insert]
        $w tag remove P [lindex $prange 0] [lindex $prange 1]
        $w tag add P [lindex $prange 0] insert-1c
        $w tag add P insert-1c [lindex $prange 1]
        if {[$w cget -autoseparators]} {
            $w edit separator
        }
    }

    method defaultTags {} {
        $txtWindow tag configure P -font "$::dinah::font $fontsize normal" -lmargin1 30 -spacing3 30
        $txtWindow tag configure STRONG -font "$::dinah::font $fontsize bold"
        $txtWindow tag configure EM -font "$::dinah::font $fontsize italic"
        $txtWindow tag configure UNDERLINE -font "$::dinah::font $fontsize underline"
        $txtWindow tag configure OVERSTRIKE -font "$::dinah::font $fontsize overstrike"
        $txtWindow tag configure SUB -font "$::dinah::font $fontsize normal" -offset -6
        $txtWindow tag configure SUP -font "$::dinah::font $fontsize normal" -offset 6
        $txtWindow tag configure TITLE1 -font [list $::dinah::font [expr {$fontsize + 6}] underline]
        $txtWindow tag configure TITLE2 -font [list $::dinah::font [expr {$fontsize + 4}] underline]
        $txtWindow tag configure TITLE3 -font [list $::dinah::font [expr {$fontsize + 2}] underline italic]
        #$txtWindow tag configure interval -background yellow
        foreach {k pairs} [array get ::dinah::txtClick *,option] {
            regexp {(.*),option} $k -> name
            foreach {optionName optionValue} $pairs {
                $txtWindow tag configure $name $optionName $optionValue 
            }
        }
    }

    method showSavedState {} {
        if {[isSaved]} {
            $saveStateLabel configure -text ""
        } else {
            $saveStateLabel configure -text "modified"
        }
    }

    method isSaved {} {
        return [expr {! [$txtWindow edit modified]}]
    }

    method events {} {
        bind $txtWindow <<Modified>> [list $this showSavedState]
        $txtWindow tag bind interval <1> [list $this click %w %x %y]
    }
}
