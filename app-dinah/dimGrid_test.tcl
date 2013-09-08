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

    $grid mkGrid
    puts [$grid getGridWidth]
    puts [$grid getGridHeight]
    puts [$grid getColumn 0]
    puts "$nbFailures test(s) failed"
}
