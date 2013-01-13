itcl::class Txt {
    inherit Obj

    public variable txtWindow
    private variable tagNameLabel ""
    private variable deleteMenu ""

    constructor {id} { set dbid $id }

    destructor {
        destroy $frame
        destroy $standalone
    }


    method reload {} {
        load $txtWindow
    }

    method zoomFont {{delta 1}} {
        incr ::dinah::fontsize $delta
        $txtWindow configure -font [list -size $::dinah::fontsize]
        puts $txtWindow
    }

    method inRange {index start end} {
        return [expr {($start <= $index) && ($index < $end)}]
    }

    method dbIdFromTagName {tagName} {
        if {[regexp {^interval(.*)} $tagName -> dbId]} {
            return $dbId
        } else {
            return ""
        }
    }

    method removeTagFromDB {tagDBId} {
        foreach d [list $::dinah::dimNote] {
            set segIndex [::dinah::getSegIndex $d $tagDBId]
            if {$segIndex ne ""} {
                ::dinah::remSeg $d $segIndex
            }
        }
        ::dinah::remfrag $::dinah::dimFragments $tagDBId
    }

    method removeTag {tagName insideIndex} {
        foreach {tagToBeRemovedStart tagToBeRemovedStop} [$txtWindow tag ranges $tagName] {
            if {[inRange $insideIndex $tagToBeRemovedStart $tagToBeRemovedStop]} {
                break
            }
        }
        foreach tagName [$txtWindow tag names $insideIndex] {
            foreach {start stop} [$txtWindow tag ranges $tagName] {
                if {($start eq $tagToBeRemovedStart) && ($stop eq $tagToBeRemovedStop)} {
                    $txtWindow tag remove $tagName $start $stop
                    set tagDBId [dbIdFromTagName $tagName]
                    if {$tagDBId ne ""} {
                        removeTagFromDB $tagDBId
                    }
                    $txtWindow edit modified 1
                }
            }
        }
    }

    method click {w x y} {
        $tagNameLabel configure -text ""
        $deleteMenu delete 0 end
        foreach t [$txtWindow tag names @$x,$y] {
            if {! [regexp {^interval.*} $t]} {
                $tagNameLabel configure -text $t
                $deleteMenu add command -label "$t" -command [list $this removeTag $t [$txtWindow index @$x,$y]]
            }
            set id ""
            regexp {^interval(.*)} $t -> id
            if {$id ne "" && $container ne ""} {
                set topFrame [$container getTopFrame]
                set c [$container getContainer]
                foreach quartPair {{1 3} {2 4}} {
                    if {[$c frameOfQuart [lindex $quartPair 0]] eq $topFrame} {
                        foreach {quartIndex dim} [list [lindex $quartPair 1] $::dinah::dimNote] {
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
    }

    method contextualMenu {} {
        set menu [menu $frame.contextualMenu]
        set deleteMenu [menu $frame.contextualMenu.deleteMenu]
        set names {}
        foreach {k pairs} [array get ::dinah::txtClick *,option] {
            regexp {(.*),option} $k -> name
            lappend names $name
        }
        $menu add cascade -label "delete" -menu $deleteMenu
        foreach name [lsort -dictionary $names] {
            $menu add command -label $name -command [list $this execMenuCmd $name]
        }
        $menu add command -label save -command [list $this save]
        bind $txtWindow $::dinah::mouse(B3) [list $this click %w %x %y]
        bind $txtWindow $::dinah::mouse(B3) +[list tk_popup $menu %X %Y]
    }

    method execMenuCmd {name} {
        if {[$txtWindow tag ranges sel] != {}} {
            set intervalId [newInterval $name]
        } elseif {[$txtWindow tag ranges sel] == {} && $name in {cb lb gap}} {
            set intervalId [newStone $name]
        }
        if {$intervalId ne ""} {
            initNewInterval $name $intervalId
            $txtWindow edit modified 1
        }
    }

    method initNewInterval {name fragId} {
        set noteId [::dinah::emptyNode Txt "note ($fragId)"]
        ::dinah::dbAppend $::dinah::dimNote [list $fragId $noteId]
    }

    method setStyle {style} {
        set sel [$txtWindow tag ranges sel]
        if {$sel ne ""} {
            if {[lsearch -exact [$txtWindow tag names [lindex $sel 0]] $style] < 0} {
                $txtWindow tag add $style {*}$sel
            } else {
                $txtWindow tag remove $style {*}$sel
            }
            $txtWindow edit modified 1
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

    method selToDBId {} {
        foreach {selStart selStop} [$txtWindow tag ranges sel] {}
        foreach tagName [$txtWindow tag names] {
            set selDBId [dbIdFromTagName $tagName]
            if {$selDBId ne ""} {
                foreach {start stop} [$txtWindow tag ranges $tagName] {
                    if {($start eq $selStart) && ($stop eq $selStop)} {
                        return $selDBId
                    }
                }
            }
        }
        return ""
    }

    method newInterval {{tagName ""}} {
        if {[selToDBId] eq ""} { 
            set intervalId [::dinah::dbNew [list isa Txt txt [$txtWindow dump -all {*}[$txtWindow tag ranges sel]] label [$txtWindow get {*}[$txtWindow tag ranges sel]]]]
            ::dinah::copy $intervalId "after" $::dinah::dimFragments $dbid
            set intervalName "interval$intervalId"
            set intervalRange [$txtWindow tag ranges sel]
            eval $txtWindow tag add interval {*}$intervalRange
            eval $txtWindow tag add  $intervalName {*}$intervalRange
            if {$tagName ne ""} {$txtWindow tag add $tagName {*}$intervalRange}
            return $intervalId
        } else {
            return ""
        }
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
        set zPlus [button $center.menu.zPlus -text "+" -command [list $this zoomFont 1]]
        set zMinus [button $center.menu.zMinus -text "-" -command [list $this zoomFont -1]]
        pack $zPlus -side left -padx 4 -pady 4
        pack $zMinus -side left -padx 4 -pady 4
        set tagNameLabel [label $center.menu.tagNameLabel -text ""]
        pack $tagNameLabel -side right -padx 4 -pady 4

        frame $center.main
        text $center.main.text \
          -yscrollcommand [list $center.main.yscroll set] \
          -highlightthickness 0 -borderwidth 0\
          -width 50 -height 20 -wrap word -undo 1\
          -font "$::dinah::font $::dinah::fontsize normal"
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
        events
        contextualMenu
    }

    method load {w} {
        set current 1.0
        array set tag {}
        $w delete 1.0 end
        foreach {key value index} [::dinah::dbGet $dbid,txt] {
            switch $key {
                text    { $w insert $index $value }
                mark    { if {$value == "current"} {set current $index} }
                tagon   { set tag($value) $index }
                tagoff  { $w tag add $value $tag($value) $index }
            }
        }
        $w mark set current $current
        $w edit modified 0
    }

    method save {} {
        # a bug (or feature?) of the tk text widget when using the dump command adds
        # a newline at the end of the dump text:
        syncIntervals
        set dump [$txtWindow dump -text -tag 1.0 end]
        set splitdump [split $dump "\n"]
        if { [regexp {(.*)text \{$} [lindex $splitdump end-1] -> match] && \
             [regexp {\}.*$} [lindex $splitdump end]] } {
            set dump [join [concat [lrange $splitdump 0 end-2] [list $match]] "\n"]
        }
        ::dinah::dbSet $dbid,txt $dump
        $txtWindow edit modified 0
    }

    method newBindings {} {
        foreach seq [bind Text] {bind modText $seq [bind Text $seq]}
        bind modText <KeyPress> {::dinah::Txt::insert %W %A}
        bind modText <KeyPress> +{break}
        bind modText <Return> +{break}
        #bind modText <Return> {::dinah::Txt::cr %W}
        bindtags $txtWindow [list $txtWindow modText all]
        bind $txtWindow <Control-Key-E> [list $this interpretLine]
    }

    # slightly modified from ::tk::TextInsert
    proc insert {w s} {
        if {$s eq "" || [$w cget -state] eq "disabled"} {
            return
        }
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
        $w edit modified 1
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
        $txtWindow tag configure P -font "$::dinah::font $::dinah::fontsize normal" -lmargin1 30 -spacing3 30
        $txtWindow tag configure STRONG -font "$::dinah::font $::dinah::fontsize bold" 
        $txtWindow tag configure EM -font "$::dinah::font $::dinah::fontsize italic" 
        $txtWindow tag configure UNDERLINE -font "$::dinah::font $::dinah::fontsize underline" 
        $txtWindow tag configure OVERSTRIKE -font "$::dinah::font $::dinah::fontsize overstrike" 
        $txtWindow tag configure SUB -font "$::dinah::font $::dinah::fontsize normal" -offset -6
        $txtWindow tag configure SUP -font "$::dinah::font $::dinah::fontsize normal" -offset 6
        $txtWindow tag configure TITLE1 -font [list $::dinah::font [expr {$::dinah::fontsize + 6}] underline]
        $txtWindow tag configure TITLE2 -font [list $::dinah::font [expr {$::dinah::fontsize + 4}] underline]
        $txtWindow tag configure TITLE3 -font [list $::dinah::font [expr {$::dinah::fontsize + 2}] underline italic]
        foreach {k pairs} [array get ::dinah::txtClick *,option] {
            regexp {(.*),option} $k -> name
            foreach {optionName optionValue} $pairs {
                $txtWindow tag configure $name $optionName $optionValue 
            }
        }
    }

    method events {} {
        $txtWindow tag bind interval <1> [list $this click %w %x %y]
        bind $txtWindow <<Modified>> [list $this onModified]
    }

    method isModified {} {
        $txtWindow edit modified
    }

    method onModified {} {
        if {[$this isModified]} { $this save }
    }

    # delete from the DB intervals no more present in the text
    # this can happen because a user can erase a portion of text containing intervals
    # with no explicit call to the 'tag delete' command the name of the tag stays
    # even if no characters are tagged by it
    method syncIntervals {} {
        foreach t [$txtWindow tag names] {
            set intervalId [dbIdFromTagName $t]
            if {($intervalId ne "") && ([$txtWindow tag ranges $t] eq "")} {
                removeTagFromDB $intervalId
                $txtWindow tag delete $t
            }
        }
    }
}
