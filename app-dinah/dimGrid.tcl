itcl::class DimGrid {
    private variable x ""; # name of the x dimension
    private variable y ""; # name of the y dimension
    private variable grid; # grid data structure
    private variable gridWidth 0
    private variable gridHeight 0
    private variable sc {}; # selection cursor: {rowIndex columnIndex}
    private variable shapeH 1;
    private variable mainAxisIndex {}; # is a row index if $shapeH and a
                                       # column index if not $shapeH.
    private variable mainAxisSegIndex {}
    private variable mainAxisDimName {}
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

    public method scId {} { cellId [scRowIndex] [scColumnIndex] }

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
        initGrid
        addToHistory
        cursorMoved
    }

    public method swapDim {} {
        if {![gridEmpty]} {
            set oldY $y
            setY $x
            setX $oldY
            mkGrid [scId]
            addToHistory
            cursorMoved
        }
    }

    public method nextSegment {{direction 1}} {
        if {![mainAxisEmpty]} {
            set newSegIndex [expr { ([getMainAxisSegIndex] + $direction) % \
                                [::dinah::dbGetDimSize [getMainAxisDimName]] }]
            if {$newSegIndex != [getMainAxisSegIndex]} {
                if {[catch {::dinah::dbGetFragment [getMainAxisDimName] \
                        $newSegIndex 0} fragId]} {
                    error "DimGrid::nextSegment --> $fragId"
                }
                mkGrid $fragId
                addToHistory
                cursorMoved
            }
        }
    }

    public method insertFragIntoGrid {fragId {direction right} {srcId ""}} {
        if {![::dinah::dbIsAFragment $fragId]} {
            error "DimGrid::insertFragIntoGrid --> $fragId is not the\
                   identifier of a valid fragment"
        }
        if {$srcId eq ""} { set srcId [scId] }
        if {! [fragBelongsToGrid $srcId]} {
            error "DimGrid::insertFragIntoGrid --> there is no fragment $srcId\
                   in the grid"
        }
        if {$direction in {left right}} {
            if { ![::dinah::editable $x] } {
                error "DimGrid::insertFragIntoGrid --> dimension $x is\
                       read only"
            }
            if {[::dinah::dbFragmentBelongsToDim $x $srcId]} {
                if {$direction eq "left"} {
                    ::dinah::dbInsertFragmentIntoDim \
                        $fragId before $x $srcId
                } else {
                    ::dinah::dbInsertFragmentIntoDim \
                        $fragId after $x $srcId
                }
            } else {
                if {$direction eq "left"} {
                    ::dinah::dbAppendSegmentToDim $x \
                        [list $fragId $srcId]
                } else {
                    ::dinah::dbAppendSegmentToDim $x \
                        [list $srcId $fragId]
                }
            }
            mkGrid $srcId
        } elseif {$direction in {up down}} {
            if { ![::dinah::editable $y] } {
                error "DimGrid::insertFragIntoGrid --> dimension $y is\
                       read only"
            }
            if {[::dinah::dbFragmentBelongsToDim $y $srcId]} {
                if {$direction eq "up"} {
                    ::dinah::dbInsertFragmentIntoDim \
                        $fragId before $y $srcId
                } else {
                    ::dinah::dbInsertFragmentIntoDim \
                        $fragId after $y $srcId
                }
            } else {
                if {$direction eq "up"} {
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

    public method new {type {direction right} {srcId ""}} {
        set newFragmentId [::dinah::dbNewEmptyFragment $type]
        if {[catch {insertFragIntoGrid $newFragmentId $direction $srcId}\
                errorMsg]} {
            ::dinah::dbRemoveFragment $newFragmentId
            error "DimGrid::new --> $errorMsg"
        }
    }

    public method copyRowSegmentToClipboard {} {
        if {[gridEmpty]} {
            error "DimGrid::copyRowSegmentToClipboard --> the grid is empty."
        }
        if {$shapeH} {
            if {[scRowIndex] ne [getMainAxisIndex]} {
                error "DimGrid::copyRowSegmentToClipboard --> the selection\
                    cursor is not on the main row."
            }
            if {[catch {::dinah::dbAddSegmentToEmptyClipboard \
                    [getMainAxisDimName] [getMainAxisSegIndex]} errorMsg]} {
                error "DimGrid::copyRowSegmentToClipboard --> $errorMsg"
            }
        } else {
            if {! [::dinah::dbFragmentBelongsToDim $x [scId]]} {
                error "DimGrid::copyRowSegmentToClipboard --> selection\
                    cursor's fragment does not belong to dimension $x"
            }
            if {[catch {::dinah::dbAddSegmentToEmptyClipboard $x \
                    [::dinah::dbGetSegmentIndex $x [scId]]} errorMsg]} {
                error "DimGrid::copyRowSegmentToClipboard --> $errorMsg"
            }
        }
    }

    public method copyColumnSegmentToClipboard {} {
        if {[gridEmpty]} {
            error "DimGrid::copyColumnSegmentToClipboard --> the grid is empty."
        }
        if {$shapeH} {
            if {! [::dinah::dbFragmentBelongsToDim $y [scId]]} {
                error "DimGrid::copyColumnSegmentToClipboard --> selection\
                    cursor's fragment does not belong to dimension $y"
            }
            if {[catch {::dinah::dbAddSegmentToEmptyClipboard $y \
                    [::dinah::dbGetSegmentIndex $y [scId]]} errorMsg]} {
                error "DimGrid::copyColumnSegmentToClipboard --> $errorMsg"
            }
        } else {
            if {[scColumnIndex] ne [getMainAxisIndex]} {
                error "DimGrid::copyColumnSegmentToClipboard --> the selection\
                    cursor is not on the main column."
            }
            if {[catch {::dinah::dbAddSegmentToEmptyClipboard \
                    [getMainAxisDimName] [getMainAxisSegIndex]} errorMsg]} {
                error "DimGrid::copyColumnSegmentToClipboard --> $errorMsg"
            }
        }
    }

    public method pasteClipboardIntoNewSegment {} {
        if {![::dinah::editable [getMainAxisDimName]]} {
            error "DimGrid::pasteClipboardIntoNewSegment --> dimension\
                   $mainAxisDimName is read only"
        }
        if {[::dinah::dbClipboardIsEmpty]} {
            error "DimGrid::pasteClipboardIntoNewSegment --> clipboard is\
                   empty"
        }
        if {[catch {::dinah::dbAppendSegmentToDim [getMainAxisDimName] \
                [::dinah::dbGetClipboard]} errorMsg]} {
            error "DimGrid::pasteClipboardIntoNewSegment --> $errorMsg"
        }
        mkGrid [lindex [::dinah::dbGetClipboard] 0]
        addToHistory
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

    public method deleteRowSegment {} {
        if {[gridEmpty]} {
            error "DimGrid::deleteRowSegment --> the grid is empty"
        }
        if {$shapeH} {
            if {[scRowIndex] ne [getMainAxisIndex]} {
                error "DimGrid::deleteRowSegment --> the selection cursor\
                    is not on the main row."
            }
            if {[catch {::dinah::dbRemoveSegment [getMainAxisDimName]\
                    [getMainAxisSegIndex]} errorMsg]} {
                error "DimGrid::deleteRowSegment --> $errorMsg"
            }
            blank
        } else {
            set xDimScSegIndex [::dinah::dbGetSegmentIndex $x [scId]]
            if {$xDimScSegIndex eq ""} {
                error "DimGrid::deleteRowSegment --> the selection cursor\
                    does not belong to dimension $x"
            }
            if {[catch {::dinah::dbRemoveSegment $x $xDimScSegIndex} \
                    errorMsg]} {
                error "DimGrid::deleteRowSegment --> $errorMsg"
            }
            mkGrid [scRowIndex] [getMainAxisIndex]
        }
    }

    public method deleteColumnSegment {} {
        if {[gridEmpty]} {
            error "DimGrid::deleteColumnSegment --> the grid is empty"
        }
        if {$shapeH} {
            set yDimScSegIndex [::dinah::dbGetSegmentIndex $y [scId]]
            if {$yDimScSegIndex eq ""} {
                error "DimGrid::deleteColumnSegment --> the selection cursor\
                    does not belong to dimension $y"
            }
            if {[catch {::dinah::dbRemoveSegment $y $yDimScSegIndex} \
                    errorMsg]} {
                error "DimGrid::deleteColumnSegment --> $errorMsg"
            }
            mkGrid [getMainAxisIndex] [scColumnIndex]
        } else {
            if {[scColumnIndex] ne [getMainAxisIndex]} {
                error "DimGrid::deleteColumnSegment --> the selection cursor\
                    is not on the main column."
            }
            if {[catch {::dinah::dbRemoveSegment [getMainAxisDimName]\
                    [getMainAxisSegIndex]} errorMsg]} {
                error "DimGrid::deleteColumnSegment --> $errorMsg"
            }
            blank
        }
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

    public method deleteScFromRow {} {
        if {[gridEmpty]} {
            error "DimGrid::deleteScFromRow --> the grid is empty"
        }
        if {$shapeH} {
            if {[scRowIndex] ne [getMainAxisIndex]} {
                error "DimGrid::deleteScFromRow --> the selection cursor is\
                    not on the main row"
            }
            if {[catch {::dinah::dbRemoveFragmentFromSegment \
                    [getMainAxisDimName] [getMainAxisSegIndex] [scId]} \
                    errorMsg]} {
                error "DimGrid::deleteScFromRow --> $errorMsg"
            }
            if {[getMainAxisLength] == 1} {
                blank
            } elseif {[scColumnIndex] == ([getGridWidth] - 1)} {
                mkGrid [cellId [scRowIndex] [expr {[scColumnIndex] - 1}]]
            } else {
                mkGrid [cellId [scRowIndex] [expr {[scColumnIndex] + 1}]]
            }
        } else {
            if {![::dinah::dbFragmentBelongsToDim $x [scId]]} {
                error "DimGrid::deleteScFromRow --> the selection cursor's\
                    fragment does not belong to dimension $x"
            }
            if {[catch {::dinah::dbRemoveFragmentFromDim $x [scId]} errorMsg]} {
                error "DimGrid::deleteScFromRow --> $errorMsg"
            }
            mkGrid [cellId [scRowIndex] [getMainAxisIndex]]
        }
    }

    public method deleteScFromColumn {} {
        if {[gridEmpty]} {
            error "DimGrid::deleteScFromColumn --> the grid is empty"
        }
        if {$shapeH} {
            if {![::dinah::dbFragmentBelongsToDim $y [scId]]} {
                error "DimGrid::deleteScFromColumn --> the selection cursor's\
                    fragment does not belong to dimension $y"
            }
            if {[catch {::dinah::dbRemoveFragmentFromDim $y [scId]} errorMsg]} {
                error "DimGrid::deleteScFromColumn --> $errorMsg"
            }
            mkGrid [cellId [getMainAxisIndex] [scColumnIndex]]
        } else {
            if {[scColumnIndex] ne [getMainAxisIndex]} {
                error "DimGrid::deleteScFromColumn --> the selection cursor is\
                    not on the main column"
            }
            if {[catch {::dinah::dbRemoveFragmentFromSegment \
                    [getMainAxisDimName] [getMainAxisSegIndex] [scId]} \
                    errorMsg]} {
                error "DimGrid::deleteScFromColumn --> $errorMsg"
            }
            if {[getMainAxisLength] == 1} {
                blank
            } elseif {[scRowIndex] == ([getGridHeight] - 1)} {
                mkGrid [cellId [expr {[scRowIndex] - 1}] [scColumnIndex]]
            } else {
                mkGrid [cellId [expr {[scRowIndex] + 1}] [scColumnIndex]]
            }
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

    public method getMainAxis {} {
        if {! [mainAxisEmpty]} {
            return [::dinah::dbGetSegment [getMainAxisDimName] \
                [getMainAxisSegIndex]]
        } else {
            return {}
        }
    }

    public method scFarRight {} {
        if {$sc ne {}} {
            for {set j [scColumnIndex]} {$j < [getGridWidth]} {incr j} {
                if {$grid([scRowIndex],$j) eq {}} {
                    incr j -1
                    break
                }
            }
            if {$j ne [scColumnIndex]} {
                set sc [list [scRowIndex] $j]
            }
        }
    }

    public method scFarLeft {} {
        if {$sc ne {}} {
            for {set j [scColumnIndex]} {$j >= 0} {incr j -1} {
                if {$grid([scRowIndex],$j) eq {}} {
                    incr j
                    break
                }
            }
            if {$j ne [scColumnIndex]} {
                set sc [list [scRowIndex] $j]
            }
        }
    }

    public method scFarUp {} {
        if {$sc ne {}} {
            for {set i [scRowIndex]} {$i >= 0} {incr i -1} {
                if {$grid($i,[scColumnIndex]) eq {}} {
                    incr i
                    break
                }
            }
            if {$i ne [scRowIndex]} {
                set sc [list $i [scColumnIndex]]
            }
        }
    }

    public method scFarDown {} {
        if {$sc ne {}} {
            for {set i [scRowIndex]} {$i < [getGridHeight]} {incr i} {
                if {$grid($i,[scColumnIndex]) eq {}} {
                    incr i -1
                    break
                }
            }
            if {$i ne [scRowIndex]} {
                set sc [list $i [scColumnIndex]]
            }
        }
    }

    public method setShapeH {} {
        if {! $shapeH} {
            if {[switchHI]} { addToHistory }
        }
    }

    public method setShapeI {} {
        if {$shapeH} {
            if {[switchHI]} { addToHistory }
        }
    }

    public method getGridWidth {} {
        set gridWidth
    }

    public method getGridHeight {} {
        set gridHeight
    }

    public method getMainAxisIndex {} {
        set mainAxisIndex
    }

    public method getMainAxisSegIndex {} {
        set mainAxisSegIndex
    }

    public method getMainAxisDimName {} {
        set mainAxisDimName
    }

    ###################
    # PRIVATE METHODS #
    ###################

    # private --> testing
    method setMainAxisDimName {v} {
        set mainAxisDimName $v
    }

    # private --> testing
    method setMainAxisSegIndex {v} {
        set mainAxisSegIndex $v
    }

    # private --> testing
    method setMainAxisIndex {v} {
        set mainAxisIndex $v
    }

    # private --> testing
    method setGridWidth {v} {
        set gridWidth $v
    }

    # private --> testing
    method setGridHeight {v} {
        set gridHeight $v
    }

    # private --> testing
    method gridEmpty {} {
        expr {([getGridWidth] == 0) && ([getGridHeight] == 0)}
    }

    # private --> testing
    method switchHI {} {
        if {![gridEmpty]} {
            transposeGrid
            set shapeH [expr {! $shapeH}]
            set oldX $x
            set x $y
            set y $oldX
            set sc [list [scColumnIndex] [scRowIndex]]
            set oldGridWidth [getGridWidth]
            setGridWidth [getGridHeight]
            setGridHeight $oldGridWidth
            return 1
        } else {
            return 0
        }
    }

    # private --> testing
    method transposeGrid {} {
        array set oldGrid [array get grid]
        array unset grid
        array set grid {}
        for {set i 0} {$i < [getGridHeight]} {incr i} {
            for {set j 0} {$j < [getGridWidth]} {incr j} {
                set grid($j,$i) $oldGrid($i,$j)
            }
        }
    }

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
             ([lindex $lastStep 2] ne [getY]) ||
             ([lindex $lastStep 3] ne [$shapeH])} {
            lappend history [list [scId] [getX] [getY] [shapeH]]
            incr historyIndex
        }
    }

    # private --> testing
    method gotoHistory {index} {
        if {$historyIndex != 0} {
            incr historyIndex -1
            gotoHistory $historyIndex
        }

        if {  ([llength $history] > 0) &&
              ($historyIndex != [expr {[llength $history] - 1}])  } {
            incr historyIndex
            gotoHistory $historyIndex
        }

        set historyScId [lindex [lindex $history $index] 0]
        set historyDimX [lindex [lindex $history $index] 1]
        set historyDimY [lindex [lindex $history $index] 2]
        set historyShapeH [lindex [lindex $history $index] 3]
        if {$historyShapeH} {

        } else {

        }
        setX [lindex [lindex $history $index] 1]
        setY [lindex [lindex $history $index] 2]
        # we call initGrid before setShapeH because we don't want to compute
        # the transpose of non empty matrix for nothing
        initGrid
        if {[lindex [lindex $history $index] 3]} {
            setShapeH
        } else {
            setShapeI
        }
        mkGrid [lindex [lindex $history $index] 0]
        # we don't call cursorMoved when going back in history
        # but we have to call explicitly mkScDim (which would otherwise be
        # called by cursorMoved
        mkScDim
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
            addToHistory
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
            addToHistory
            cursorMoved
            return 1
        }
    }

    # private --> testing
    method scRowIndex {} {
        if {!($sc eq {})} {
            return [lindex $sc 0]
        } else {
            return {}
        }
    }

    # private --> testing
    method scColumnIndex {} {
        if {!($sc eq {})} {
            return [lindex $sc 1]
        } else {
            return {}
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
            set sc [list $newScRow [scColumnIndex]]
            cursorMoved
            return 1
        } else {
            return 0
        }
    }

    # private --> testing
    method getMainAxisLength {} {
        if {$shapeH} {
            return [getGridWidth]
        } else {
            return [getGridHeight]
        }
    }

    # private --> testing
    method mainAxisEmpty {} { expr {[getMainAxisLength] == 0} }

    # private --> testing
    method initGrid {} {
        array unset grid
        array set grid {}
        set sc {}
        setGridHeight 0
        setGridWidth 0
        setMainAxisIndex {}
        setMainAxisDimName {}
        setMainAxisSegIndex {}
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
        if {! $shapeH} {
            set goBackToShapeI 1
            setShapeH
        } else {
            set goBackToShapeI 0
        }
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
            setMainAxisDimName $x
            set mainRowSegIndex [lindex $centerFoundOnX 0]
            setMainAxisSegIndex $mainRowSegIndex
            set fragIndex [lindex $centerFoundOnX 1]
            set mainRow [::dinah::dbGetSegment $x $mainRowSegIndex]
            # For now we are only able to set the column index of
            # the selection cursor (sc). The row index will be set later.
            set sc [list $fragIndex]
            setGridWidth [llength $mainRow]

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
        setGridHeight [expr {$maxBottom + $maxTop + 1}]
        # We can now complete the position of the selection cursor (sc)
        # with its row index which is $maxTop since the first row of the
        # grid is numbered 0
        set sc [linsert $sc 0 $maxTop]
        setMainAxisIndex $maxTop
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
        if {$goBackToShapeI} {
            setShapeI
        }
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
    method scDimName {} { cellDimName [scRowIndex] [scColumnIndex] }
    # private --> testing
    method scSegIndex {} { cellSegIndex [scRowIndex] [scColumnIndex] }
    # private --> testing
    method scFragIndex {} { cellFragIndex [scRowIndex] [scColumnIndex] }

    # private --> testing
    method newSegmentWith {fragId} {
        if {![::dinah::editable [getMainAxisDimName]]} {
            error "DimGrid::newSegmentWith --> dimension $mainAxisDimName\
                is read only"
        }
        if {![::dinah::dbIsAFragment $fragId]} {
            error "DimGrid::newSegmentWith --> $fragId is not a\
                   fragment's identifier"
        }
        if {[catch {::dinah::dbAppendSegmentToDim [getMainAxisDimName] \
                [list $fragId]} errorMsg]} {
            error "DimGrid::newSegmentWith --> $errorMsg"
        }
        mkGrid $fragId
        cursorMoved
    }
}
