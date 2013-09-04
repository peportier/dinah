itcl::class DimGrid {
    private variable x ""; # name of the x dimension
    private variable y ""; # name of the y dimension
    private variable grid; # grid data structure
    private variable gridWidth 0;
    private variable gridHeight 0;
    private variable sc {}; # selection cursor: {line_of_grid column_of_grid}
    private variable scDim {}
    private variable history {}
    private variable historyIndex 0
    private variable numModifier ""

    constructor {} {}

    ##################
    # PUBLIC METHODS #
    ##################

    public method setX {dim} {
        if {[::dinah::dbExists $dim]} {
            set x $dim
            return 1
        } else {
            return 0
        }
    }
    public method getX {} { set x }
    public method setY {dim} {
        if {[::dinah::dbExists $dim]} {
            set y $dim
            return 1
        } else {
            return 0
        }
    }
    public method getY {} { set y }

    public method scRight {} {
        scHoriz [getNumModifier]
        initNumModifier
    }

    public method scLeft {} {
        scHoriz -[getNumModifier]
        initNumModifier
    }

    public method scDown {} {
        scVertic [getNumModifier]
        initNumModifier
    }

    public method scUp {} {
        scVertic -[getNumModifier]
        initNumModifier
    }

    public method scId {} { return [lindex [scCell] 3] }

    public method gotoRowEnd {} { gotoRowEnds "end" }

    public method gotoRowStart {} { gotoRowEnds 0 }

    public method prevHistory {} {
        if {$historyIndex != 0} {
            incr historyIndex -1
            gotoHistory $historyIndex
        }
    }

    public method nextHistory {} {
        if {  ([llength $history] > 0) &&
              ($historyIndex != [expr {[llength $history] - 1}])  } {
            incr historyIndex
            gotoHistory $historyIndex
        }
    }

    public method blank {} {
        setX $::dinah::dimNil
        setY $::dinah::dimNil
        initBoard
    }

    public method swapDim {} {
        set oldY $y
        setY $x
        setX $oldY
        buildAndGrid [scId]
    }

    public method nextList {{direction 1}} {
        if {![scRowEmpty]} {
            buildAndGrid [::dinah::dbLGet $x \
                [list [expr { ([scSegIndex] + $direction) % \
                              [::dinah::dbGetDimSize $x]       }] 0]]
        }
    }

    public method new {type {delta 1}} {
        if { [::dinah::editable $x] } {
            if { !( $sc eq {} ) } {
                set dbid [scId]
                set newX {}
                set newId [::dinah::dbNewEmptyFragment $type]
                set found 0
                foreach l [::dinah::dbGet $x] {
                    set i [lsearch $l $dbid]
                    if {$i > -1} {
                        lappend newX [linsert $l [expr {$i + $delta}] $newId]
                        set found 1
                    } else {
                        lappend newX $l
                    }
                }
                if {! $found} {
                    # if the grid is composed of only one column
                    lappend newX [linsert [list $dbid] $delta $newId]
                }
                ::dinah::dbSetDim $x $newX
                buildAndGrid $newId
                return 1
            } else {
                return 0
            }
        } else {
            tk_messageBox -message "dim $x is read only" -icon error
            return 0
        }
    }

    public method copySegmentToClipboard {} {
        ::dinah::dbAddSegmentToEmptyClipboard $x [scSegIndex]
    }

    public method pasteClipboardIntoNewSegment {} {
        if {[::dinah::editable $x]} {
            if {![::dinah::dbClipboardIsEmpty]} {
                set row {}
                foreach frag [::dinah::dbGetClipboard] {
                    if {![::dinah::dbFragmentBelongsToDim $x $frag]} {
                        lappend row $frag
                    } else {
                        tk_messageBox -message "clipboard cannot be pasted \
                                                since object $frag already \
                                                belongs to dim $x" \
                                      -icon error
                        return 0
                    }
                }
                if {$row != {}} {
                    ::dinah::dbAppendSegmentToDim $x $row
                    buildAndGrid [lindex $row 0]
                    return 1
                } else {
                    error "pasteClipboardIntoNewSegment: should never happen"
                }
            } else {
                tk_messageBox -message "Cannot paste clipboard: \
                                        clipboard is empty." \
                              -icon error
                return 0

            }
        } else {
            tk_messageBox -message "dim $x is read only" -icon error
            return 0
        }
    }

    public method deleteSegment {} {
        if {[::dinah::editable $x] && [scRow] != {}} {
            ::dinah::dbRemoveSegment $x [scSegIndex]
            blank
            return 1
        } else {
            tk_messageBox -message "the row cannot be removed since \
                                    dimension $x is read only" \
                          -icon error
        }
    }

    public method copy {} {
        if {[scId] neq {}} {
            ::dinah::dbAddFragmentToEmptyClipboard [scId]
            return 1
        } else {
            tk_messageBox -message "copy impossible: no object under the \
                                    selection cursor" \
                          -icon error
            return 0
        }
    }

    public method copycat {} {
        if {[scId] neq {}} {
            ::dinah::dbAddFragmentToClipboard [scId]
            return 1
        } else {
            tk_messageBox -message "copy impossible: no object under the \
                                    selection cursor" \
                          -icon error
            return 0
        }
    }

    public method pasteBefore {} {
        if {[pasteGuard]} {
            set newScRow [linsert [scRow] [scItemIndex] \
                                  [::dinah::dbClipboardLastItem]]
            ::dinah::dbReplaceSegment $x [scSegIndex] $newScRow
            buildAndGrid [scId]
            return 1
        } else {
            return 0
        }
    }

    public method pasteAfter {} {
        if {[pasteGuard]} {
            if {[scOnLastItem]} {
                set newItemIndex end
            } else {
                set newItemIndex [expr {[scItemIndex] + 1}]
            }
            set newScRow [linsert [scRow] $newItemIndex \
                                  [::dinah::dbClipboardLastItem]]
            ::dinah::dbReplaceSegment $x [scSegIndex] $newScRow
            buildAndGrid [scId]
            return 1
        } else {
            return 0
        }
    }

    public method method cut {} {copycat; delete}

    public method delete {} {
        if {[deleteGuard]} {
            set scRow [scRow]
            if {[llength [scRow]] == 1} {
                set newScId {}
                ::dinah::dbRemoveSegment $x [scSegIndex]
            } else {
                if {[scOnLastItem]} {
                    set newScId [lindex [scRow] end-1]
                } else {
                    set newScId [lindex [scRow] [expr {[scItemIndex] + 1}]]
                }
                set newScRow [lreplace [scRow] [scItemIndex] [scItemIndex]]
                ::dinah::dbReplaceSegment $x [scSegIndex] $newScRow
            }
            buildAndGrid $newScId
            return 1
        } else {
            return 0
        }
    }

    ###################
    # PRIVATE METHODS #
    ###################

    private method cursorMoved {} {
        addToHistory
    }

    private method addToHistory {} {
        # if we went back some action in current history
        # and we want to initiate a new action
        # then we forget the part of history we explored back.
        # e.g. history is a1 a2 a3 a4 a5
        #                       ^
        # and we initiate a new action a6, then history becomes
        # a1 a2 a3 a6
        #          ^
        if {([llength $history] > 0) && \
            ($historyIndex != [expr {[llength $history] - 1}])} {
            set history [lrange $history 0 $historyIndex]
            set historyIndex [expr {[llength $history] - 1}]
        }
        set lastStep [lindex $history end]
        if { ([lindex $lastStep 0] ne [scId]) ||
             ([lindex $lastStep 1] ne [getX]) ||
             ([lindex $lastStep 2] ne [getY]) } {
            lappend history [list [scId] [getX] [getY]]
            incr historyIndex
        }
    }

    private method gotoHistory {index} {
        setX [lindex [lindex $history $index] 1]
        setY [lindex [lindex $history $index] 2]
        updateEntries
        buildAndGrid [lindex [lindex $history $index] 0]
    }

    private method gotoRowEnds {where} {
        set r [scRow]
        if {$r != {}} {
            buildAndGrid [lindex $r $where]
        }
    }

    private method initScDim {} {
        set scDim {}
    }

    private method scDim {} {
        # store in scDim the list of the dimensions on which
        # the selection cursor (sc) appears
        initScDim
        set id [scId]
        set found 0
        if {$id ne {}} {
            foreach d [::dinah::dbGet dimensions] {
                foreach l [::dinah::dbGet $d] {
                    foreach i $l {
                        if {$id eq $i} {
                            lappend scDim $d
                            set found 1
                            break
                        }
                    }
                    if {$found} {set found 0; break}
                }
            }
        }
    }

    private method scDimAfter {dim} {
        # return the element of $scDim coming after $dim,
        # considering $scDim a circular list
        # if $dim is not an element of $scDim,
        # return the first element of $scDim
        # if $scDim is empty, return -1
        set scDimLength [llength $scDim]
        if {$scDimLength > 0} {
            set dimIndex [lsearch -exact $scDim $dim]
            if {$dimIndex == -1} {
                return [lindex $scDim 0]
            } else {
                set nextDim [lindex $scDim [expr {$dimIndex + 1}]]
                if {$nextDim eq {}} {
                    return [lindex $scDim 0]
                } else {
                    return $nextDim
                }
            }
        } else {
            return -1
        }
    }

    private method switchScDimsX {} {
        # switch the x-axis to one of the other dims that the
        # selection cursor (sc) belongs to
        set nextDim [scDimAfter [getX]]
        if {$nextDim == -1} {
            return 0
        } else {
            setX $nextDim
            updateEntries
            buildAndGrid [scId]
            return 1
        }
    }

    private method switchScDimsY {} {
        # switch the y-axis to one of the other dims that the
        # selection cursor (sc) belongs to
        set nextDim [scDimAfter [getY]]
        if {$nextDim == -1} {
            return 0
        } else {
            setY $nextDim
            updateEntries
            buildAndGrid [scId]
            return 1
        }
    }

    private method scRowIndex {} {
        if {[llength $sc] == 2} {
            return [lindex $sc 0]
        } else {
            return {}
        }
    }

    private method scColumnIndex {} {
        if {[llength $sc] == 2} {
            return [lindex $sc 1]
        } else {
            return {}
        }
    }

    private method goto {match} {
        set row [scRow]
        if {$row ne {}} {
            for {set i 0} {$i < [llength $row]} {incr i} {
                if {[string match -nocase *$match* [::dinah::dbGet \
                        [lindex $row $i],label]]} {
                    scHoriz [expr {$i - [scColumnIndex]}]
                    return
                }
            }
        }
    }

    private method scHoriz {i} {
        if {![insideW [scRowIndex] [scColumnIndex]]} {return}
        set newScCol [expr {[scColumnIndex] + $i}]
        set exist [info exists grid([scRowIndex],$newScCol)]
        if {$exist && !( [cell [scRowIndex] $newScCol] eq {} )} {
            set row [scRowIndex]
            set col $newScCol
            set oldSc $sc
            set sc [list $row $col]
            if {! [insideW $row $col]} {
                wHoriz $i
            } else {
                [$objects($oldSc) cget -frame] configure -borderwidth 0
                [$objects($sc) cget -frame] configure \
                    -borderwidth $::dinah::fragmentBorderWidth \
                    -bg $::dinah::selectionCursorColor
            }
            cursorWasRedrawn
        }
    }

    private method scVertic {i} {
        if {![insideW [scRowIndex] [scColumnIndex]]} {return}
        set newScRow [expr {[scRowIndex] + $i}]
        set exist [info exists grid($newScRow,[scColumnIndex])]
        if {$exist && !( [cell $newScRow [scColumnIndex]] eq {} )} {
            buildAndGrid [id [cell $newScRow [scColumnIndex]]]
            mkGrid
        }
    }

    private method initBoard {} {
        array unset grid
        array set grid {}
        set sc {}
        initInfo
        initScDim
    }

    private method buildBoard {{center {}}} {
        # center is the id of an object on which the selection cursor (sc)
        # will be set
        set mainRow {}
        set mainRowSegIndex {}
        set cols {}
        initBoard
        if {$center eq {}} {
            set center [::dinah::dbLGet $x {0 0}]
            if {$center eq {}} {
                error "the board cannot be built because no center was given \
                       and the first fragment of the dim $x is empty \
                       which implies that the dim $x is empty since a dim \
                       should never have empty fragments"
            }
        }
        #
        # From now on, $center refers to the id of an object
        #
        set centerFoundOnX [::dinah::dbFindInDim $x $center]
        if {[llength $centerFoundOnX] == 0} {
            set centerFoundOnY [::dinah::dbFindInDim $y $center]
            if {[llength $centerFoundOnY] != 0} {
                # the grid will consist of only one column
                set segIndex [lindex $centerFoundOnY 0]
                set fragIndex [lindex $centerFoundOnY 1]
                set seg [::dinah::dbGetSegment $y $segIndex]
                set segLength [llength $seg]
                for {set k 0} {$k < $segLength} {incr k} {
                    set grid($k,0) [list $y $segIndex $k [lindex $seg $k]]
                }
                set sc [list $fragIndex 0]
                set gridWidth 1
                set gridHeight $segLength
                setWRow [lindex $sc 0]
                setWCol [lindex $sc 1]
                return 1
            } else {
                error "the grid cannot be build since $center belongs \
                       to neither the dim $x nor the dim $y"
            }
        } else {
            # building the main row:
            set segIndex [lindex $centerFoundOnX 0]
            set fragIndex [lindex $centerFoundOnX 1]
            set seg [::dinah::dbGetSegment $x $segIndex]
            set mainRowSegIndex $segIndex
            set mainRow $seg
            # For now we are only able to set the column index of
            # the selection cursor (sc). The row index will be set later.
            set sc [list $fragIndex]
            set gridWidth [llength $mainRow]

            # building the columns:
            foreach k $mainRow {
                set found [::dinah::dbFindInDim $y $k]
                if {[llength $found] != 0} {
                    set segIndex [lindex $found 0]
                    set fragIndex [lindex $found 1]
                    set seg [::dinah::dbGetSegment $y $segIndex]
                    lappend cols [list $seg $segIndex $fragIndex]
                } else {
                    lappend cols {}
                }
            }
        }

        # complete columns with bottom distances:
        # for a given column, top    is the number of objects above the main row
        # for a given column, bottom is the number of objects below the main row
        # for a given column, fragIndex ([lindex $col 2]) is the value of top
        # maxTop and maxBottom are used to compute the height of the grid
        set maxTop 0;    # will store the biggest top distance
        set maxBottom 0; # will store the biggest bottom distance
        set newCols {}
        foreach col $cols {
            if {! ($col eq {})} {
                set top [lindex $col 2]
                set maxTop [expr {max($maxTop,$top)}]
                set bottom [expr {[llength [lindex $col 0]] - $top - 1}]
                set maxBottom [expr {max($maxBottom,$bottom)}]
                lappend newCols [linsert $col end $bottom]
            } else {
                lappend newCols {}
            }
        }
        set gridHeight [expr {$maxBottom + $maxTop + 1}]
        # We can now complete the position of the selection cursor (sc)
        # with its row index which is $maxTop since the first row of the
        # grid is numbered 0
        set sc [linsert $sc 0 $maxTop]
        set cols $newCols

        # grid:
        for {set i 0} {$i < [llength $mainRow]} {incr i} {
            # the line number of the mainRow is $maxTop
            set grid($maxTop,$i) [list $x $mainRowSegIndex $i \
                [lindex $mainRow $i]]
        }
        for {set i 0} {$i < [llength $cols]} {incr i} {
            if {[lindex $cols $i] eq {}} {
                # case of an empty column
                for {set j 0} {$j < $maxTop} {incr j} {
                    set grid($j,$i) {}
                }
                for {set j 0} {$j < $maxBottom} {incr j} {
                    set grid([expr {$maxTop + 1 + $j}],$i) {}
                }
            } else {
                # case of a non empty column
                set seg [lindex $cols $i 0]
                set segIndex [lindex $cols $i 1]
                set top [lindex $cols $i 2]
                set bottom [lindex $cols $i 3]
                set deltaTop [expr {$maxTop - $top}]
                set deltaBottom [expr {$maxBottom - $bottom}]
                for {set j 0} {$j < $deltaTop} {incr j} {
                    set grid($j,$i) {}
                }
                for {set j 0} {$j < $top} {incr j} {
                    set grid([expr {$j + $deltaTop}],$i) \
                        [list $y $segIndex $j [lindex $seg $j]]
                }
                for {set j 0} {$j < $bottom} {incr j} {
                    set fragIndex [expr {$top + 1 + $j}]
                    set grid([expr {$maxTop + 1 + $j}],$i) \
                        [list $y $segIndex $fragIndex [lindex $seg $fragIndex]]
                }
                for {set j 0} {$j < $deltaBottom} {incr j} {
                    set grid([expr {$maxTop + 1 + $bottom + $j}],$i) {}
                }
            }
        }
        setWRow [lindex $sc 0]
        setWCol  [lindex $sc 1]
        return 1
    }

    private method getGridColumn {j} {
        set col {}
        foreach {k v} [array get grid *,$j] {
            if {$v ne {}} {lappend col [regsub {,.*$} $k ""]}
        }
        set col [lsort -integer $col]
        return $col
    }

    private method cell {rowIndex columnIndex} {
        if {[info exists grid($rowIndex,$columnIndex)]} {
            return $grid($rowIndex,$columnIndex)
        } else {
            return {}
        }
    }

    private method scCell {} { return [cell [scRowIndex] [scColumnIndex]] }
    private method scDimName {} { return [lindex [scCell] 0] }
    private method scSegIndex {} { return [lindex [scCell] 1] }
    private method scItemIndex {} { return [lindex [scCell] 2] }

    # if {[scDimName] ne $x} it means that [scDimName] comes from the
    # vertical/Y dim
    # therefore in that case the selection cursor row is empty.
    private method scRowEmpty {} {
        return [expr {[scDimName] ne $x}]
    }

    private method scRow {} {
        if {! [scRowEmpty]} {
            return [::dinah::dbGetSegment [scDimName] [scSegIndex]]
        } else {
            return {}
        }
    }

    private method scOnLastItem {} {
        return [expr {[scItemIndex] == ([llength [scRow]] - 1)}]
    }

    private method noCycleOrDuplicate {} {
        return [expr {(! [dimXIsNil])  && (! [::dinah::dbClipboardIsEmpty]) && \
                      (! [scRowEmpty]) && (! [pastingCycle]) && \
                      (! [pastingDuplicate])}]
    }

    private method pastingCycle {} {
        if {[::dinah::dbClipboardLastItem] in [scRow]} {
            return 1
        } else {
            return 0
        }
    }

    private method pastingDuplicate {} {
        set scDimLength [llength [::dinah::dbGet [scDimName]]]
        for {set i 0} {$i < $scDimLength} {incr i} {
            if {$i != [scSegIndex]} {
                if {[::dinah::dbClipboardLastItem] in \
                    [::dinah::dbLGet [scDimName] $i]} {
                    # item appearing twice in a dimension
                    return 1
                }
            }
        }
        return 0
    }

    private method dimXIsNil {} {
        if {$x eq $::dinah::dimNil} {
            return 1
        } else {
            return 0
        }
    }

    private method pasteIntoNewSegment {} {
        if {(! [dimXIsNil]) && (! [::dinah::dbClipboardIsEmpty])} {
            ::dinah::dbAppendSegmentToDim $x \
                [list [::dinah::dbClipboardLastItem]]
            buildAndGrid [::dinah::dbClipboardLastItem]
        }
    }

    private method newListWithTxtNode {} {
        if {! [dimXIsNil]} {
            set txtId [::dinah::dbNewEmptyFragment Txt]
            ::dinah::dbAppendSegmentToDim $x [list $txtId]
            buildAndGrid $txtId
        }
    }
}
