itcl::class DimGrid {
    private variable x $::dinah::dimNil; # name of the x dimension
    private variable y $::dinah::dimNil; # name of the y dimension
    private variable grid; # grid data structure
    private variable gridWidth 0
    private variable gridHeight 0
    private variable sc {}; # selection cursor: {rowIndex columnIndex}
    private variable scDim {}
    private variable history {}
    private variable historyIndex 0
    private variable numModifier 1

    constructor {} {}

    ##################
    # PUBLIC METHODS #
    ##################

    public method setX {dim} {
        if {[::dinah::dbExists $dim]} {
            set x $dim
            return 1
        } else {
            error "DimGrid::setX --> dimension $dim does not exist"
        }
    }
    public method getX {} { set x }
    public method setY {dim} {
        if {[::dinah::dbExists $dim]} {
            set y $dim
            return 1
        } else {
            error "DimGrid::setY --> dimension $dim does not exist"
        }
    }
    public method getY {} { set y }

    public method getNumModifier {} { set numModifier }

    public method setNumModifier {n} {
    if {(![regexp {^\d*$} $n]) || ($n < 1)} {
        error "DimGrid::setNumModifier --> modifier's value ($n) should be\
               a positive integer"
    }
        set numModifier $n
    }

    public method initNumModifier {} { setNumModifier 1 }

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
        initGrid
        cursorMoved
    }

    public method swapDim {} {
        set oldY $y
        setY $x
        setX $oldY
        mkGrid [scId]
        cursorMoved
    }

    public method nextSegment {{direction 1}} {
        if {![scRowEmpty]} {
            set newSegIndex [expr { ([scSegIndex] + $direction) % \
                                    [::dinah::dbGetDimSize $x] }]
            if {$newSegIndex != [scSegIndex]} {
                if {[catch {::dinah::dbGetFragment $x $newSegIndex 0} fragId]} {
                    error "DimGrid::nextSegment --> $fragId"
                }
                mkGrid $fragId
                cursorMoved
            }
        }
    }

    public method insertFragIntoGrid {fragId {direction after} {srcId ""}} {
        if {![::dinah::dbIsAFragment $fragId]} {
            error "DimGrid::insertFragIntoGrid --> $fragId is not the\
                   identifier of a valid fragment"
        }
        if {$srcId eq ""} { set srcId [scId] }
        if {! [fragBelongsToGrid $srcId]} {
            error "DimGrid::insertFragIntoGrid --> there is no fragment $srcId\
                   in the grid"
        }
        if {$direction in {before after}} {
            if { ![::dinah::editable $x] } {
                error "DimGrid::insertFragIntoGrid --> dimension $x is\
                       read only"
            }
            if {[::dinah::dbFragmentBelongsToDim $x $srcId]} {
                ::dinah::dbInsertFragmentIntoDim \
                    $fragId $direction $x $srcId
            } else {
                if {$direction eq "after"} {
                    ::dinah::dbAppendSegmentToDim $x \
                        [list $srcId $fragId]
                } else {
                    ::dinah::dbAppendSegmentToDim $x \
                        [list $fragId $srcId]
                }
            }
            mkGrid $srcId
        } elseif {$direction in {above below}} {
            if { ![::dinah::editable $y] } {
                error "DimGrid::insertFragIntoGrid --> dimension $y is\
                       read only"
            }
            if {[::dinah::dbFragmentBelongsToDim $y $srcId]} {
                if {$direction eq "above"} {
                    ::dinah::dbInsertFragmentIntoDim \
                        $fragId before $y $srcId
                } else {
                    ::dinah::dbInsertFragmentIntoDim \
                        $fragId after $y $srcId
                }
            } else {
                if {$direction eq "above"} {
                    ::dinah::dbAppendSegmentToDim $y \
                        [list $srcId $fragId]
                } else {
                    ::dinah::dbAppendSegmentToDim $y \
                        [list $fragId $srcId]
                }
            }
            mkGrid $srcId
        } else {
            error "DimGrid::insertFragIntoGrid --> $direction is not a valid\
                   direction, should be 'before', 'after', 'above' or 'below'"
        }
    }

    public method new {type {direction after} {srcId ""}} {
        set newFragmentId [::dinah::dbNewEmptyFragment $type]
        if {[catch {insertFragIntoGrid $newFragmentId $direction $srcId}\
                errorMsg]} {
            ::dinah::dbRemoveFragment $newFragmentId
            error "DimGrid::new --> $errorMsg"
        }
    }

    public method copySegmentToClipboard {} {
        if {![scRowEmpty]} {
            ::dinah::dbAddSegmentToEmptyClipboard $x [scSegIndex]
        } else {
            error "DimGrid::copySegmentToClipboard --> the row is empty"
        }
    }

    public method pasteClipboardIntoNewSegment {} {
        if {![::dinah::editable $x]} {
            error "DimGrid::pasteClipboardIntoNewSegment --> X dimension $x\
                   is read only"
        }
        if {[::dinah::dbClipboardIsEmpty]} {
            error "DimGrid::pasteClipboardIntoNewSegment --> clipboard is\
                   empty"
        }
        if {[catch {::dinah::dbAppendSegmentToDim $x [::dinah::dbGetClipboard]}\
                errorMsg]} {
            error "DimGrid::pasteClipboardIntoNewSegment --> $errorMsg"
        }
        mkGrid [lindex [::dinah::dbGetClipboard] 0]
        cursorMoved
    }

    public method pasteClipboardLastItemIntoNewSegment {} {
        if {[::dinah::dbClipboardIsEmpty]} {
            error "DimGrid::pasteClipboardLastItemIntoNewSegment -->\
                   clipboard is empty"
        }
        if {[catch {newSegmentWith [::dinah::dbClipboardLastItem]} errorMsg]} {
            error "DimGrid::pasteClipboardLastItemIntoNewSegment --> $errorMsg"
        }
    }

    public method newSegmentWithNew {typeOfFrag} {
        if {[catch {::dinah::dbNewEmptyFragment $typeOfFrag} newFrag]} {
            error "DimGrid::newSegmentWithNew --> $newFrag"
        }
        if {[catch {newSegmentWith $newFrag} errorMsg]} {
            ::dinah::dbRemoveFragment $newFrag
            error "DimGrid::newSegmentWithNew --> $errorMsg"
        }
    }

    public method deleteSegment {} {
        if {![::dinah::editable $x]} {
            error "DimGrid::deleteSegment --> X dimension $x is read only"
        }
        if {[scRowEmpty]} {
            error "DimGrid::deleteSegment --> the row is empty"
        }
        ::dinah::dbRemoveSegment $x [scSegIndex]
        blank
    }

    public method copy {} {
        if {[scId] eq {}} {
            error "DimGrid::copy --> no fragment under selection cursor"
        }
        ::dinah::dbAddFragmentToEmptyClipboard [scId]
    }

    public method copycat {} {
        if {[scId] eq {}} {
            error "DimGrid::copy --> no fragment under selection cursor"
        }
        if {[catch {::dinah::dbAddFragmentToClipboard [scId]} errorMsg]} {
            error "DimGrid::copycat --> $errorMsg"
        }
    }

    public method paste {direction} {
        if {[::dinah::dbClipboardIsEmpty]} {
            error "DimGrid::paste --> clipboard is empty"
        }
        insertFragIntoGrid [::dinah::dbClipboardLastItem] $direction
    }

    public method cut {} {copycat; delete}

    public method deleteScFromRow {} {
        if {[scRowEmpty]} {
            error "DimGrid::deleteScFromRow --> the row is empty"
        }
        if {![::dinah::editable $x]} {
            error "DimGrid::deleteScFromRow --> Dimension $x is read only"
        }
        ::dinah::dbRemoveFragmentFromSegment $x [scSegIndex] [scId]
        if {[llength [getScRow] == 1} {
            blank
        } elseif {[scOnLastItem]} {
            mkGrid [lindex [getScRow] end-1]
            cursorMoved
        } else {
            mkGrid [lindex [getScRow] [expr {[scFragIndex] + 1}]]
            cursorMoved
        }
    }

    public method getRowIndicesForColumn {j} {
        set col {}
        foreach subList [getColumn $j] {
            lappend col [lindex $subList 0]
        }
        return $col
    }

    public method getColumn {j} {
        if {($j < 0) || ($j >= [getGridWidth])} {
            return {}
        }
        set rowIndices {}
        foreach {k v} [array get grid *,$j] {
            if {$v ne {}} {lappend rowIndices [regsub {,.*$} $k ""]}
        }
        set rowIndices [lsort -integer $rowIndices]
        set col {}
        foreach i $rowIndices { lappend col [list $i [cellId $i $j]] }
        return $col
    }

    public method getScRow {} {
        if {! [scRowEmpty]} {
            return [::dinah::dbGetSegment [scDimName] [scSegIndex]]
        } else {
            return {}
        }
    }


    ###################
    # PRIVATE METHODS #
    ###################

    # private --> testing
    method fragPositionInGrid {fragId} {
        set fragPositions {}
        for {set j 0} {$j < [getGridWidth]} {incr j} {
            set i [lindex\
                [lsearch -index 1 -exact -inline [getColumn $j] $fragId] 0]
            if {$i ne ""} {
                lappend fragPositions [list $i $j]
            }
        }
        return $fragPositions
    }

    # private --> testing
    method fragBelongsToGrid {fragId} {
        expr {[fragPositionInGrid $fragId] ne {}}
    }

    # private --> testing
    method cursorMoved {} {
        addToHistory
        mkScDim
    }

    # private --> testing
    method addToHistory {} {
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

    # private --> testing
    method gotoHistory {index} {
        setX [lindex [lindex $history $index] 1]
        setY [lindex [lindex $history $index] 2]
        mkGrid [lindex [lindex $history $index] 0]
        # we don't call cursorMoved when going back in history
        # but we have to call explicitly mkScDim (which would otherwise be
        # called by cursorMoved
        mkScDim
    }

    # private --> testing
    method gotoRowEnds {where} {
        if {![scRowEmpty]} {
            mkGrid [lindex [getScRow] $where]
        }
    }

    # private --> testing
    method initScDim {} {
        set scDim {}
    }

    # private --> testing
    method mkScDim {} {
        # store in scDim the list of the dimensions on which
        # the selection cursor (sc) appears
        initScDim
        set id [scId]
        if {[scId] ne {}} {
            foreach dim [::dinah::dbGetDimensions] {
                if {[::dinah::dbFragmentBelongsToDim $dim [scId]]} {
                    lappend scDim $dim
                }
            }
        }
    }

    # private --> testing
    method scDimAfter {dim} {
        # return the element of $scDim coming after $dim,
        # considering $scDim a circular list
        # if $dim is not an element of $scDim,
        # return the first element of $scDim
        # if $scDim is empty, return {}
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
            return {}
        }
    }

    # private --> testing
    method switchScDimsX {} {
        # switch the x-axis to one of the other dims that the
        # selection cursor (sc) belongs to
        set nextDim [scDimAfter [getX]]
        if {$nextDim eq {}} {
            return 0
        } else {
            setX $nextDim
            mkGrid [scId]
            cursorMoved
            return 1
        }
    }

    # private --> testing
    method switchScDimsY {} {
        # switch the y-axis to one of the other dims that the
        # selection cursor (sc) belongs to
        set nextDim [scDimAfter [getY]]
        if {$nextDim eq {}} {
            return 0
        } else {
            setY $nextDim
            mkGrid [scId]
            cursorMoved
            return 1
        }
    }

    # private --> testing
    method scRowIndex {} {
        if {![scRowEmpty]} {
            return [lindex $sc 0]
        } else {
            return {}
        }
    }

    # private --> testing
    method scColumnIndex {} {
        if {![scRowEmpty]} {
            return [lindex $sc 1]
        } else {
            return {}
        }
    }

    # private --> testing
    method goto {match} {
        if {![scRowEmpty]} {
            set row [getScRow]
            for {set i 0} {$i < [llength $row]} {incr i} {
                set fragId [lindex $row $i]
                set fragLabel [::dinah::dbGetAttribute $fragId "label"
                if {[string match -nocase *$match* $fragLabel]} {
                    scHoriz [expr {$i - [scColumnIndex]}]
                    return
                }
            }
        }
    }

    # private --> testing
    method scHoriz {i} {
        set newScCol [expr {[scColumnIndex] + $i}]
        if {![cellIsEmpty [scRowIndex] $newScCol]} {
            set sc [list [scRowIndex] $newScCol]
            cursorMoved
            return 1
        } else {
            return 0
        }
    }

    # private --> testing
    method scVertic {i} {
        set newScRow [expr {[scRowIndex] + $i}]
        if {![cellIsEmpty $newScRow [scColumnIndex]]} {
            mkGrid [cellId $newScRow [scColumnIndex]]
            cursorMoved
            return 1
        } else {
            return 0
        }
    }

    # private --> testing
    method initGrid {} {
        array unset grid
        array set grid {}
        set sc {}
        initScDim
    }

    # private --> testing
    method mkGrid {{center {}}} {
        # center is the id of a fragment on which the selection cursor (sc)
        # will be set
        set mainRow {}
        set mainRowSegIndex {}
        set cols {}
        initGrid
        if {$center eq {}} {
            if {[catch {::dinah::dbGetFragment $x 0 0} center]} {
                error "DimGrid::mkGrid --> dimension $x is empty"
            }
        }
        #
        # From now on, $center refers to the id of a fragment on which
        # the selection cursor (sc) will be set.
        #
        set centerFoundOnX [::dinah::dbFindInDim $x $center]
        if {[llength $centerFoundOnX] == 0} {
            error "DimGrid::mkGrid --> $center is not a fragment of $x"
        } else {
            # building the main row:
            set mainRowSegIndex [lindex $centerFoundOnX 0]
            set fragIndex [lindex $centerFoundOnX 1]
            set mainRow [::dinah::dbGetSegment $x $mainRowSegIndex]
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
    }

    # private --> testing
    method getGridWidth {} {
        set gridWidth
    }

    # private --> testing
    method getGridHeight {} {
        set gridHeight
    }

    # private --> testing
    method cell {rowIndex columnIndex} {
        if {[info exists grid($rowIndex,$columnIndex)]} {
            return $grid($rowIndex,$columnIndex)
        } else {
            return {}
        }
    }

    # private --> testing
    method cellIsEmpty {rowIndex colIndex} {
        expr {[cell $rowIndex $colIndex] eq {}}
    }


    # private --> testing
    method cellDimName {rowIndex columnIndex} {
        lindex [cell $rowIndex $columnIndex] 0
    }
    # private --> testing
    method cellSegIndex {rowIndex columnIndex} {
        lindex [cell $rowIndex $columnIndex] 1
    }
    # private --> testing
    method cellFragIndex {rowIndex columnIndex} {
        lindex [cell $rowIndex $columnIndex] 2
    }
    # private --> testing
    method cellId {rowIndex columnIndex} {
        lindex [cell $rowIndex $columnIndex] 3
    }

    # private --> testing
    method scCell {} { return [cell [scRowIndex] [scColumnIndex]] }
    # private --> testing
    method scDimName {} { cellDimName [scRowIndex] [scColumnIndex] }
    # private --> testing
    method scSegIndex {} { cellSegIndex [scRowIndex] [scColumnIndex] }
    # private --> testing
    method scFragIndex {} { cellFragIndex [scRowIndex] [scColumnIndex] }

    # private --> testing
    method scRowLength {} {
        if {$sc eq {}} {
            return -1
        } else {
            set scRowLength 0
            foreach {k v} [array get grid [lindex $sc 0],*] {
                incr scRowLength
            }
            return $scRowLength
        }
    }

    # private --> testing
    method scRowEmpty {} {
        if {[scRowLength] <= 1} {
            return 1
        } else {
            return 0
        }
    }

    # private --> testing
    method scOnLastItem {} {
        if {[scRowEmpty]} {
            return 0
        }
        expr {[scFragIndex] == ([scRowLength] - 1)}
    }

    # private --> testing
    method newSegmentWith {fragId} {
        if {![::dinah::editable $x]} {
            error "DimGrid::newSegmentWith --> X dimension $x is read only"
        }
        if {![::dinah::dbIsAFragment $fragId]} {
            error "DimGrid::newSegmentWith --> $fragId is not a\
                   fragment's identifier"
        }
        if {[catch {::dinah::dbAppendSegmentToDim $x [list $fragId]}\
                errorMsg]} {
            error "DimGrid::newSegmentWith --> $errorMsg"
        }
        mkGrid $fragId
        cursorMoved
    }
}
