package require Itcl

namespace eval ::dinah {
    ########
    # INIT #
    ########

    source commonDB.tcl

    set writePermission 1
    set dimClone "d.clone"
    set dimClipboard "d.clipboard"
    set dbFile "/tmp/db.dinah"
    array set db {}
    set db(lastid) 0
    set db(dimensions) {"d.nil"}

    proc editable {dimName} {
        return [expr {($dimName ni {"" "d.nil"}) && \
            ($dimName in [dbGetDimensions])}]
    }

    set nbFailures 0

    #########
    # TESTS #
    #########

    dbNewDim "d.1"
    if {[dbGetDimensions] ne {d.nil d.1}} {
        incr nbFailures
        puts "T1 KO"
    }

    dbNewDim "d.2"
    if {[dbGetDimensions] ne {d.nil d.1 d.2}} {
        incr nbFailures
        puts "T2 KO"
    }

    if {[dbGetDim "d.1"] ne {}} {
        incr nbFailures
        puts "T3 KO"
    }

    if {[dbGetDimSize "d.1"] != 0} {
        incr nbFailures
        puts "T4 KO"
    }

    if {[dbIsADim "d.1"] == 0} {
        incr nbFailures
        puts "T5 KO"
    }

    if {[dbIsADim "d.3"] == 1} {
        incr nbFailures
        puts "T6 KO"
    }

    dbAppendSegmentToDim "d.1" [list [dbNewEmptyFragment Txt text1]]
    if {[dbGetDim "d.1"] ne {1}} {
        incr nbFailures
        puts "T7 KO"
    }

    dbAppendSegmentToDim "d.1" [list [dbNewEmptyFragment Txt text2]]
    if {[dbGetDim "d.1"] ne {1 2}} {
        incr nbFailures
        puts "T8 KO"
    }

    dbAppendToSegment "d.1" 0 [dbNewEmptyFragment Txt text3]
    if { [dbGetDim "d.1"] ne {{1 3} 2} } {
        incr nbFailures
        puts "T9 KO"
    }

    if {[catch {dbAppendToSegment "d.1" 1 3} errorMsg]} {
        if {$errorMsg ne "::dinah::dbAppendToSegment --> the fragment 3\
                          already belongs to the dimension d.1, and the\
                          same fragment cannot appear twice in a given\
                          dimension."} {
            incr nbFailures
            puts "T10 KO"
        }
    } else {
        incr nbFailures
        puts "T10 KO"
    }

    dbNewEmptyFragment Txt text4
    dbReplaceSegment "d.1" 1 {2 4}
    if { [dbGetDim "d.1"] ne {{1 3} {2 4}} } {
        incr nbFailures
        puts "T11 KO"
    }

    if {[catch {dbReplaceSegment "d.1" 1 {2 4 1}} errorMsg]} {
        if {$errorMsg ne "::dinah::dbReplaceSegment --> the fragment 1\
                       from the segment to be inserted into dimension d.1\
                       in place of another segment (call it s1) of dimension\
                       d.1, already appears in dimension d.1 inside\
                       a segment different from s1, and the same fragment\
                       cannot appear twice in a given dimension."} {
            incr nbFailures
            puts "T12 KO"
        }
    } else {
        incr nbFailures
        puts "T12 KO"
    }

    if {[catch {dbReplaceSegment "d.1" 1 {2 4 2}} errorMsg]} {
        if {$errorMsg ne "::dinah::dbReplaceSegment --> the fragment 2\
                   appears at least twice in the segment to be inserted into\
                   dimension d.1 in place of another segment of dimension\
                   d.1, and the same fragment cannot appear\
                   twice in a given dimension."} {
            incr nbFailures
            puts "T13 KO"
        }
    } else {
        incr nbFailures
        puts "T13 KO"
    }

    if {[catch {dbNewDim "d3"} errorMsg]} {
        if {$errorMsg ne "::dinah::dbNewDim --> the dimension d3 already\
                          exists and is not a query (i.e. it does not start\
                          with 'q.'), or it does not exist but it also does\
                          not start with 'd.' or 'q.'"} {
            incr nbFailures
            puts "T14 KO"
        }
    } else {
        incr nbFailures
        puts "T14 KO"
    }

    if { [dbGetDimSize "d.1"] != 2 } {
        incr nbFailures
        puts "T15 KO"
    }

    dbAppendSegmentToDim "d.2" {1}
    if { [dbGetDimForId 1] ne {d.1 0 0 d.2 0 0} } {
        incr nbFailures
        puts "T16 KO"
    }

    dbSetDim "d.2" {{1} {4 3}}
    if { [dbGetDim "d.2"] ne {{1} {4 3}} } {
        incr nbFailures
        puts "T17 KO"
    }

    if {[catch {dbSetDim "d.2" {{1 3} {4 3}}} errorMsg]} {
        if {$errorMsg ne "::dinah::dbSetDim --> the fragment 3 would\
                          appear twice in the dimension d.2."} {
            incr nbFailures
            puts "T18 KO"
        }
    } else {
        incr nbFailures
        puts "T18 KO"
    }

    if {[catch {dbSetDim "d.2" {{1 3} {4 5}}} errorMsg]} {
        if {$errorMsg ne "::dinah::dbSetDim --> the database entry with id\
                          5 is not a fragment"} {
            incr nbFailures
            puts "T19 KO"
        }
    } else {
        incr nbFailures
        puts "T19 KO"
    }

    if {[catch {dbReplaceSegment "d.2" 0 {1 5}} errorMsg]} {
        if {$errorMsg ne "::dinah::dbReplaceSegment --> the database entry\
                          with id 5 is not a fragment."} {
            incr nbFailures
            puts "T20 KO"
        }
    } else {
        incr nbFailures
        puts "T20 KO"
    }

    if {[catch {dbAppendToSegment "d.2" 0 5} errorMsg]} {
        if {$errorMsg ne "::dinah::dbAppendToSegment --> the database entry\
                          with id 5 is not a fragment"} {
            incr nbFailures
            puts "T21 KO"
        }
    } else {
        incr nbFailures
        puts "T21 KO"
    }

    puts "$nbFailures test(s) failed"
}
