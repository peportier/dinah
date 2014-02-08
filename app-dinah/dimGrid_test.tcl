package require Itcl

namespace eval ::dinah {
    ########
    # INIT #
    ########

    source dimGrid_test_preamble.tcl

    set nbFailures 0

    dbNewDim "d.1"
    dbNewDim "d.2"
    dbNewDim "d.3"

    set label1 [dbNewEmptyFragment Label "1"]
    set label2 [dbNewEmptyFragment Label "2"]
    set label3 [dbNewEmptyFragment Label "3"]
    set label4 [dbNewEmptyFragment Label "4"]
    set label5 [dbNewEmptyFragment Label "5"]
    set label6 [dbNewEmptyFragment Label "6"]
    set label7 [dbNewEmptyFragment Label "7"]
    set label8 [dbNewEmptyFragment Label "8"]
    set label9 [dbNewEmptyFragment Label "9"]
    set label10 [dbNewEmptyFragment Label "10"]
    set label11 [dbNewEmptyFragment Label "11"]
    set label12 [dbNewEmptyFragment Label "12"]
    set label13 [dbNewEmptyFragment Label "13"]
    set label14 [dbNewEmptyFragment Label "14"]
    set label15 [dbNewEmptyFragment Label "15"]
    set label16 [dbNewEmptyFragment Label "16"]
    set label17 [dbNewEmptyFragment Label "17"]
    set label18 [dbNewEmptyFragment Label "18"]
    set label19 [dbNewEmptyFragment Label "19"]
    set label20 [dbNewEmptyFragment Label "20"]
    set label21 [dbNewEmptyFragment Label "21"]
    set label22 [dbNewEmptyFragment Label "22"]
    set label23 [dbNewEmptyFragment Label "23"]
    set label24 [dbNewEmptyFragment Label "24"]
    set label25 [dbNewEmptyFragment Label "25"]
    set label26 [dbNewEmptyFragment Label "26"]

    ::dinah::dbAppendSegmentToDim "d.1" [list $label1 $label2 $label3 $label4\
        $label5 $label6 $label7 $label8]

    ::dinah::dbAppendSegmentToDim "d.1" [list $label9 $label10 $label11\
        $label12 $label13 $label14 $label15 $label16]

    ::dinah::dbAppendSegmentToDim "d.2" [list $label17 $label1 $label18 $label9\
        $label19 $label3 $label20 $label15 $label21]

    ::dinah::dbAppendSegmentToDim "d.2" [list $label22 $label8 $label23\
        $label14]

    ::dinah::dbAppendSegmentToDim "d.3" [list $label4 $label10 $label19 $label8]

    # x = d.1 ; y = d.2 ; sc = {5 0}
    #
    # 0          17
    # 1           1
    # 2          18
    # 3           9
    # 4    17    19
    # 5     1  2  3  4  5  6  7  8
    # 6    18    20
    # 7     9    15
    # 8    19    21
    # 9     3
    #10    20
    #11    15
    #12    21
    #
    #       0  1  2  3  4  5  6  7
    #
    # SWAP
    # x = d.2 ; y = d.1 ; sc = {6 5} test T25
    #
    # 0                          9
    # 1                         10
    # 2                         11
    # 3                         12
    # 4                    1    13                 
    # 5                    2    14
    # 6    17  1 18  9 19  3 20 15 21
    # 7        2    10     4    16
    # 8        3    11     5
    # 9        4    12     6
    #10        5    13     7
    #11        6    14     8
    #12        7    15
    #13        8    16
    #
    #       0  1  2  3  4  5  6  7  8

    #########
    # TESTS #
    #########

    set grid [DimGrid #auto]

    $grid setX "d.1"
    if {[$grid getX] ne "d.1"} {
        incr nbFailures
        puts "T1 KO"
    }

    if {[catch {$grid setX "d.4"} errorMsg]} {
        if {$errorMsg ne "DimGrid::setX --> dimension d.4 does not exist"} {
            incr nbFailures
            puts "T2 KO"
        }
    } else {
        incr nbFailures
        puts "T2 KO"
    }

    $grid setY "d.2"
    if {[$grid getY] ne "d.2"} {
        incr nbFailures
        puts "T3 KO"
    }

    if {[catch {$grid setY "d.4"} errorMsg]} {
        if {$errorMsg ne "DimGrid::setY --> dimension d.4 does not exist"} {
            incr nbFailures
            puts "T4 KO"
        }
    } else {
        incr nbFailures
        puts "T4 KO"
    }

    if {[$grid getNumModifier] != 1} {
        incr nbFailures
        puts "T5 KO"
    }

    $grid setNumModifier 2
    if {[$grid getNumModifier] != 2} {
        incr nbFailures
        puts "T6 KO"
    }
    $grid setNumModifier 1

    if {[catch {$grid setNumModifier 0} errorMsg]} {
        if {$errorMsg ne "DimGrid::setNumModifier --> modifier's value (0)\
                          should be a positive integer"} {
            incr nbFailures
            puts "T7 KO"
        }
    } else {
        incr nbFailures
        puts "T7 KO"
    }

    if {[catch {$grid setNumModifier a} errorMsg]} {
        if {$errorMsg ne "DimGrid::setNumModifier --> modifier's value (a)\
                          should be a positive integer"} {
            incr nbFailures
            puts "T8 KO"
        }
    } else {
        incr nbFailures
        puts "T8 KO"
    }

    $grid mkGridAndCenterWindow

    if {[$grid getGridWidth] ne 8} {
        incr nbFailures
        puts "T9 KO"
    }

    if {[$grid getGridHeight] ne 13} {
        incr nbFailures
        puts "T10 KO"
    }

    if {[$grid getColumn 0] ne {{4 17} {5 1} {6 18} {7 9} {8 19} {9 3} {10 20}\
            {11 15} {12 21}}} {
        incr nbFailures
        puts "T11 KO"
    }

    if {[$grid scRowIndex] ne 5} {
        incr nbFailures
        puts "T12 KO"
    }

    if {[$grid scColumnIndex] ne 0} {
        incr nbFailures
        puts "T13 KO"
    }

    if {[$grid scDimName] ne "d.1"} {
        incr nbFailures
        puts "T14 KO"
    }

    if {[$grid scSegIndex] != 0} {
        incr nbFailures
        puts "T15 KO"
    }

    if {[$grid scFragIndex] != 0} {
        incr nbFailures
        puts "T16 KO"
    }

    if {[$grid fragPositionInGrid 15] ne {{11 0} {7 2}}} {
        incr nbFailures
        puts "T17 KO"
    }

    if {[$grid fragBelongsToGrid 15] != 1} {
        incr nbFailures
        puts "T18 KO"
    }

    if {[$grid fragBelongsToGrid 16] != 0} {
        incr nbFailures
        puts "T19 KO"
    }

    if {[$grid getRow [$grid scRowIndex]] ne {{0 1} {1 2} {2 3} {3 4}\
                                              {4 5} {5 6} {6 7} {7 8}}} {

        incr nbFailures
        puts "T20 KO"
    }

    if {[$grid getRowIndicesForColumn 0] ne {4 5 6 7 8 9 10 11 12}} {
        incr nbFailures
        puts "T21 KO"
    }
    $grid scRight
    $grid scRight
    $grid scUp
    $grid scDown
    $grid scDown
    $grid scUp
    $grid scLeft

    if {[$grid scRowIndex] ne 5} {
        incr nbFailures
        puts "T22 KO"
    }

    if {[$grid scColumnIndex] ne 1} {
        incr nbFailures
        puts "T23 KO"
    }

    if {[$grid scId] ne 2} {
        incr nbFailures
        puts "T24 KO"
    }

    $grid scRight
    $grid swapDim
    if {[$grid scRowIndex] ne 6} {
        incr nbFailures
        puts "T25 KO"
    }
    if {[$grid scColumnIndex] ne 5} {
        incr nbFailures
        puts "T26 KO"
    }
    if {[$grid getGridWidth] ne 9} {
        incr nbFailures
        puts "T27 KO"
    }
    if {[$grid getGridHeight] ne 14} {
        incr nbFailures
        puts "T28 KO"
    }

    $grid prevHistory
    if {[$grid getX] ne "d.1"} {
        incr nbFailures
        puts "T29 KO"
    }
    if {[$grid getY] ne "d.2"} {
        incr nbFailures
        puts "T30 KO"
    }
    if {[$grid scRowIndex] ne 5} {
        incr nbFailures
        puts "T31 KO"
    }
    if {[$grid scColumnIndex] ne 0} {
        incr nbFailures
        puts "T32 KO"
    }
    if {[$grid getGridWidth] ne 8} {
        incr nbFailures
        puts "T33 KO"
    }
    if {[$grid getGridHeight] ne 13} {
        incr nbFailures
        puts "T34 KO"
    }

    $grid nextHistory
    if {[$grid getX] ne "d.2"} {
        incr nbFailures
        puts "T35 KO"
    }
    if {[$grid getY] ne "d.1"} {
        incr nbFailures
        puts "T36 KO"
    }
    if {[$grid scRowIndex] ne 6} {
        incr nbFailures
        puts "T37 KO"
    }
    if {[$grid scColumnIndex] ne 5} {
        incr nbFailures
        puts "T38 KO"
    }
    if {[$grid getGridWidth] ne 9} {
        incr nbFailures
        puts "T39 KO"
    }
    if {[$grid getGridHeight] ne 14} {
        incr nbFailures
        puts "T40 KO"
    }

    puts "$nbFailures test(s) failed"
}
