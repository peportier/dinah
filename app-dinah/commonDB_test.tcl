package require Itcl

namespace eval ::dinah {
    ########
    # INIT #
    ########

    source commonDB_test_preamble.tcl

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

    if {[catch {dbAppendSegmentToDim "d.2" {2 5}} errorMsg]} {
        if {$errorMsg ne "::dinah::dbAppendSegmentToDim --> the database entry\
            with id 5 is not a fragment"} {
            incr nbFailures
            puts "T22 KO"
        }
    } else {
        incr nbFailures
        puts "T22 KO"
    }

    if {[catch {dbAppendSegmentToDim "d.nil" {2}} errorMsg]} {
        if {$errorMsg ne "::dinah::dbAppendSegmentToDim --> dimension d.nil\
                          is read only, or it does not exist"} {
            incr nbFailures
            puts "T23 KO"
        }
    } else {
        incr nbFailures
        puts "T23 KO"
    }

    if {[catch {dbAppendSegmentToDim "d.3" {2 1}} errorMsg]} {
        if {$errorMsg ne "::dinah::dbAppendSegmentToDim --> dimension d.3\
                          is read only, or it does not exist"} {
            incr nbFailures
            puts "T24 KO"
        }
    } else {
        incr nbFailures
        puts "T24 KO"
    }

    if {[catch {dbAppendSegmentToDim "" {2 1}} errorMsg]} {
        if {$errorMsg ne "::dinah::dbAppendSegmentToDim --> dimension \
                          is read only, or it does not exist"} {
            incr nbFailures
            puts "T25 KO"
        }
    } else {
        incr nbFailures
        puts "T25 KO"
    }

    if {[catch {dbAppendSegmentToDim "d.2" {2 2}} errorMsg]} {
        if {$errorMsg ne "::dinah::dbAppendSegmentToDim --> the fragment 2\
                   appears at least twice in the segment to be appended to\
                   dimension d.2, and the same fragment cannot appear\
                   twice in a given dimension."} {
            incr nbFailures
            puts "T26 KO"
        }
    } else {
        incr nbFailures
        puts "T26 KO"
    }

    if {[catch {dbAppendSegmentToDim "d.2" {2 3}} errorMsg]} {
        if {$errorMsg ne "::dinah::dbAppendSegmentToDim --> The segment to be\
                   appended to \
                   dimension d.2 contains a fragment 3 that\
                   already belongs to the dimension d.2, and the same\
                   fragment cannot appear twice in a given dimension."} {
            incr nbFailures
            puts "T27 KO"
        }
    } else {
        incr nbFailures
        puts "T27 KO"
    }

    dbInsertFragmentIntoDim 2 after "d.2" 4
    if {[dbGetDim "d.2"] ne {1 {4 2 3}}} {
        incr nbFailures
        puts "T28 KO"
    }

    dbRemoveFragmentFromDim "d.2" 2
    if {[dbGetDim "d.2"] ne {1 {4 3}}} {
        incr nbFailures
        puts "T29 KO"
    }

    dbInsertFragmentIntoDim 2 before "d.2" 3
    if {[dbGetDim "d.2"] ne {1 {4 2 3}}} {
        incr nbFailures
        puts "T30 KO"
    }

    dbRemoveFragmentFromDim "d.2" 2
    dbInsertFragmentIntoDim 2 before "d.2" 1
    if {[dbGetDim "d.2"] ne {{2 1} {4 3}}} {
        incr nbFailures
        puts "T31 KO"
    }

    dbRemoveFragmentFromDim "d.2" 2
    dbInsertFragmentIntoDim 2 after "d.2" 3
    if {[dbGetDim "d.2"] ne {1 {4 3 2}}} {
        incr nbFailures
        puts "T32 KO"
    }

    if {[catch {dbRemoveFragmentFromDim "d.nil" 1} errorMsg]} {
        if {$errorMsg ne "::dinah::dbRemoveFragmentFromDim --> dimension\
            d.nil is read only, or does not exist"} {
            incr nbFailures
            puts "T33 KO"
        }
    } else {
        incr nbFailures
        puts "T33 KO"
    }

    dbRemoveFragmentFromDim "d.2" 2
    if {[catch {dbRemoveFragmentFromDim "d.2" 2} errorMsg]} {
        if {$errorMsg ne "::dinah::dbRemoveFragmentFromDim --> fragment\
            2 does not belong to dimension d.2"} {
            incr nbFailures
            puts "T34 KO"
        }
    } else {
        incr nbFailures
        puts "T34 KO"
    }

    if {[catch {dbInsertFragmentIntoDim 5 after "d.2" 3} errorMsg]} {
        if {$errorMsg ne "the database entry with id 5 is not a fragment"} {
            incr nbFailures
            puts "T35 KO"
        }
    } else {
        incr nbFailures
        puts "T35 KO"
    }

    if {[catch {dbInsertFragmentIntoDim 2 right "d.2" 3} errorMsg]} {
        if {$errorMsg ne "::dinah::dbInsertFragmentIntoDim --> 'right' is not\
                          a valid value for the direction parameter (it should\
                          be 'before' or 'after')"} {
            incr nbFailures
            puts "T36 KO"
        }
    } else {
        incr nbFailures
        puts "T36 KO"
    }

    if {[catch {dbInsertFragmentIntoDim 2 after "d.nil" 3} errorMsg]} {
        if {$errorMsg ne "::dinah::dbInsertFragmentIntoDim --> target dimension\
                          d.nil is read only, or does not exist"} {
            incr nbFailures
            puts "T37 KO"
        }
    } else {
        incr nbFailures
        puts "T37 KO"
    }

    dbNewEmptyFragment Txt text5
    if {[catch {dbInsertFragmentIntoDim 5 after "d.2" 2} errorMsg]} {
        if {$errorMsg ne "::dinah::dbInsertFragmentIntoDim --> target fragment\
                          2 not found in target dimension d.2"} {
            incr nbFailures
            puts "T38 KO"
        }
    } else {
        incr nbFailures
        puts "T38 KO"
    }

    if {[catch {dbInsertFragmentIntoDim 1 after "d.2" 3} errorMsg]} {
        if {$errorMsg ne "::dinah::dbInsertFragmentIntoDim --> The source\
                          fragment 1 already belongs to the target dimension\
                          d.2, and the same fragment cannot appear twice in a\
                          given dimension."} {
            incr nbFailures
            puts "T39 KO"
        }
    } else {
        incr nbFailures
        puts "T39 KO"
    }

    dbMoveFragmentBetweenDims "d.1" 2 after "d.2" 1
    if {[dbGetDim "d.2"] ne {{1 2} {4 3}} && [dbGetDim "d.1"] ne {{1 3} 4}} {
        incr nbFailures
        puts "T40 KO"
    }

    dbMoveFragmentBetweenDims "d.2" 2 before "d.2" 4
    if {[dbGetDim "d.2"] ne {1 {2 4 3}}} {
        incr nbFailures
        puts "T41 KO"
    }

    if {[dbGetFragment "d.1" 1 0] ne 4} {
        incr nbFailures
        puts "T42 KO"
    }

    if {[catch {dbGetFragment "d.4" 0 0} errorMsg]} {
        if {$errorMsg ne "::dinah::dbGetFragment --> d.4 is not a dimension"} {
            incr nbFailures
            puts "T43 KO"
        }
    } else {
        incr nbFailures
        puts "T43 KO"
    }

    if {[catch {dbGetFragment "d.1" 1 1} errorMsg]} {
        if {$errorMsg ne "::dinah::dbGetFragment --> segment 1 of\
               dimension d.1 has no fragment at index 1"} {
            incr nbFailures
            puts "T44 KO"
        }
    } else {
        incr nbFailures
        puts "T44 KO"
    }

    if {[catch {dbGetFragment "d.1" 0 -1} errorMsg]} {
        if {$errorMsg ne "::dinah::dbGetFragment --> index -1 is not a proper\
                          index, it should be an integer"} {
            incr nbFailures
            puts "T45 KO"
        }
    } else {
        incr nbFailures
        puts "T45 KO"
    }

    dbRemoveFragmentFromSegment "d.2" 1 4
    if {[dbGetDim "d.2"] ne {1 {2 3}}} {
        incr nbFailures
        puts "T46 KO"
    }

    if {[catch {dbRemoveFragmentFromSegment "d.2" 1 4} errorMsg]} {
        if {$errorMsg ne "::dinah::dbRemoveFragmentFromSegment --> fragment\
                          4 is not an element of segment 1 of dimension\
                          d.2"} {
            incr nbFailures
            puts "T47 KO"
        }
    } else {
        incr nbFailures
        puts "T47 KO"
    }

    dbRemoveFragmentFromSegmentByIndex "d.2" 1 1
    if {[dbGetDim "d.2"] ne {1 2}} {
        incr nbFailures
        puts "T48 KO"
    }

    if {[catch {dbRemoveFragmentFromSegmentByIndex "d.2" 1 1} errorMsg]} {
        if {$errorMsg ne "::dinah::dbRemoveFragmentFromSegmentByIndex -->\
               segment 1 of dimension d.2 has no fragment at index 1"} {
            incr nbFailures
            puts "T49 KO"
        }
    } else {
        incr nbFailures
        puts "T49 KO"
    }

    dbInitClipboard

    if {[dbGetClipboard] ne {}} {
        incr nbFailures
        puts "T50 KO"
    }

    if {[dbClipboardIsEmpty] == 0} {
        incr nbFailures
        puts "T51 KO"
    }

    dbAddFragmentToClipboard 1
    if {[dbGetClipboard] ne {1}} {
        incr nbFailures
        puts "T52 KO"
    }

    if {[catch {dbAddFragmentToClipboard 6} errorMsg]} {
        if {$errorMsg ne "::dinah::dbAddFragmentToClipboard --> 6 is not a\
               fragment identifier"} {
            incr nbFailures
            puts "T53 KO"
        }
    } else {
        incr nbFailures
        puts "T53 KO"
    }

    dbAddFragmentToEmptyClipboard 5
    if {[dbGetClipboard] ne {5}} {
        incr nbFailures
        puts "T54 KO"
    }

    if {[catch {dbAddFragmentToEmptyClipboard 6} errorMsg]} {
        if {$errorMsg ne "::dinah::dbAddFragmentToEmptyClipboard --> 6 is not a\
               fragment identifier"} {
            incr nbFailures
            puts "T55 KO"
        }
    } else {
        incr nbFailures
        puts "T55 KO"
    }

    if {[dbClipboardLastItem] ne {5}} {
        incr nbFailures
        puts "T56 KO"
    }

    dbAddSegmentToEmptyClipboard "d.1" 0
    if {[dbGetClipboard] ne {1 3}} {
        incr nbFailures
        puts "T57 KO"
    }

    dbRemoveSegment "d.1" 0
    if {[dbGetDim "d.1"] ne {4}} {
        incr nbFailures
        puts "T58 KO"
    }

    if {[catch {dbRemoveSegment "d.1" 1} errorMsg]} {
        if {$errorMsg ne "::dinah::dbRemoveSegment --> d.1 has no segment with\
               index 1"} {
            incr nbFailures
            puts "T59 KO"
        }
    } else {
        incr nbFailures
        puts "T59 KO"
    }

    if {[dbGetSegmentIndex "d.2" 1] ne 0} {
        incr nbFailures
        puts "T60 KO"
    }

    if {[catch {dbGetSegmentIndex "d.3" 1} errorMsg]} {
        if {$errorMsg ne "::dinah::dbGetSegmentIndex --> d.3 is not a\
                          dimension"} {
            incr nbFailures
            puts "T61 KO"
        }
    } else {
        incr nbFailures
        puts "T61 KO"
    }

    if {[catch {dbGetSegmentIndex "d.1" 6} errorMsg]} {
        if {$errorMsg ne "::dinah::dbGetSegmentIndex --> there is no fragment\
                          with id 6"} {
            incr nbFailures
            puts "T62 KO"
        }
    } else {
        incr nbFailures
        puts "T62 KO"
    }

    if {[dbGetSegment "d.2" 0] ne {1}} {
        incr nbFailures
        puts "T63 KO"
    }

    if {[catch {dbGetSegment "d.2" 2} errorMsg]} {
        if {$errorMsg ne "::dinah::dbGetSegment --> d.2 has no segment with\
                          index 2"} {
            incr nbFailures
            puts "T64 KO"
        }
    } else {
        incr nbFailures
        puts "T64 KO"
    }

    if {[catch {dbGetSegment "d.3" 2} errorMsg]} {
        if {$errorMsg ne "::dinah::dbGetSegment --> d.3 is not a dimension, or\
                          it does not exist"} {
            incr nbFailures
            puts "T65 KO"
        }
    } else {
        incr nbFailures
        puts "T65 KO"
    }

    dbAppend "d.1" {3 5}
    if {[dbGetDim "d.1"] ne {4 {3 5}}} {
        incr nbFailures
        puts "T66 KO"
    }

    if {[catch {dbAppend "d.3" 1} errorMsg]} {
        if {$errorMsg ne "::dinah::dbAppend --> key d.3 does not exist"} {
            incr nbFailures
            puts "T67 KO"
        }
    } else {
        incr nbFailures
        puts "T67 KO"
    }

    dbSetAttribute 1 txt "abc def ghi"
    if {[dbGetAttribute 1 txt] ne "abc def ghi"} {
        incr nbFailures
        puts "T68 KO"
    }

    if {[catch {dbSetAttribute 6 txt ""} errorMsg]} {
        if {$errorMsg ne "::dinah::dbSetAttribute --> there is no fragment with\
                          id 6"} {
            incr nbFailures
            puts "T69 KO"
        }
    } else {
        incr nbFailures
        puts "T69 KO"
    }

    if {[catch {dbSetAttribute 1 tag "aTag"} errorMsg]} {
        if {$errorMsg ne "::dinah::dbSetAttribute --> the fragment 1 has no\
                          attribute tag"} {
            incr nbFailures
            puts "T70 KO"
        }
    } else {
        incr nbFailures
        puts "T70 KO"
    }

    if {[catch {dbGetAttribute 6 txt} errorMsg]} {
        if {$errorMsg ne "::dinah::dbGetAttribute --> there is no fragment with\
                          id 6"} {
            incr nbFailures
            puts "T71 KO"
        }
    } else {
        incr nbFailures
        puts "T71 KO"
    }

    if {[catch {dbGetAttribute 1 tag} errorMsg]} {
        if {$errorMsg ne "::dinah::dbGetAttribute --> the fragment 1 has no\
                          attribute tag"} {
            incr nbFailures
            puts "T72 KO"
        }
    } else {
        incr nbFailures
        puts "T72 KO"
    }

    dbNewAttribute 1 tag "aTag"
    if {[dbGetAttribute 1 tag] ne "aTag"} {
        incr nbFailures
        puts "T73 KO"
    }

    if {[catch {dbNewAttribute 6 tag} errorMsg]} {
        if {$errorMsg ne "::dinah::dbNewAttribute --> there is no fragment with\
                          id 6"} {
            incr nbFailures
            puts "T74 KO"
        }
    } else {
        incr nbFailures
        puts "T74 KO"
    }

    if {[dbGetAttributesNames 1] ne {isa label tag txt}} {
        incr nbFailures
        puts "T75 KO"
    }

    if {[catch {dbGetAttributesNames 6} errorMsg]} {
        if {$errorMsg ne "::dinah::dbGetAttributesNames --> there is no\
                          fragment with id 6"} {
            incr nbFailures
            puts "T76 KO"
        }
    } else {
        incr nbFailures
        puts "T76 KO"
    }

    if {[dbLGet dimensions 0] ne "d.nil"} {
        incr nbFailures
        puts "T77 KO"
    }

    if {[catch {dbLGet dimensions end} errorMsg]} {
        if {$errorMsg ne "::dinah::dbLGet --> index end is not a proper\
                          index, it should be an integer"} {
            incr nbFailures
            puts "T78 KO"
        }
    } else {
        incr nbFailures
        puts "T78 KO"
    }

    if {[catch {dbLGet dimensions 4} errorMsg]} {
        if {$errorMsg ne "::dinah::dbLGet --> object at key dimensions has no\
                          element at index 4"} {
            incr nbFailures
            puts "T79 KO"
        }
    } else {
        incr nbFailures
        puts "T79 KO"
    }

    if {[catch {dbGetSegment "d.2" end} errorMsg]} {
        if {$errorMsg ne "::dinah::dbGetSegment --> index end is not a proper\
                          index, it should be an integer"} {
            incr nbFailures
            puts "T80 KO"
        }
    } else {
        incr nbFailures
        puts "T80 KO"
    }

    if {[catch {dbRemoveSegment "d.1" end} errorMsg]} {
        if {$errorMsg ne "::dinah::dbRemoveSegment --> index end is not a proper\
                          index, it should be an integer"} {
            incr nbFailures
            puts "T81 KO"
        }
    } else {
        incr nbFailures
        puts "T81 KO"
    }

    if {[catch {dbRemoveFragmentFromSegmentByIndex "d.1" 1 end} errorMsg]} {
        if {$errorMsg ne "::dinah::dbRemoveFragmentFromSegmentByIndex --> index\
                          end is not a proper index, it should be an integer"} {
            incr nbFailures
            puts "T82 KO"
        }
    } else {
        incr nbFailures
        puts "T82 KO"
    }

    dbLSet "d.1" 1 {3 2}
    if {[dbGetDim "d.1"] ne {4 {3 2}}} {
        incr nbFailures
        puts "T83 KO"
    }

    if {[catch {dbLSet "d.1" 2 5} errorMsg]} {
        if {$errorMsg ne "::dinah::dbLSet --> object at key d.1 has no element\
                          at index 2"} {
            incr nbFailures
            puts "T84 KO"
        }
    } else {
        incr nbFailures
        puts "T84 KO"
    }

    if {[catch {dbLSet "d.1" end 5} errorMsg]} {
        if {$errorMsg ne "::dinah::dbLSet --> index end is not a proper\
                          index, it should be an integer"} {
            incr nbFailures
            puts "T85 KO"
        }
    } else {
        incr nbFailures
        puts "T85 KO"
    }

    dbSave
    array set ::dinah::db {}
    dbLoad
    if {[dbGetAttribute 1 txt] ne "abc def ghi"} {
        incr nbFailures
        puts "T86 KO"
    }

    dbSetAttribute 2 txt "def abc jkl"

    if {[dbSearch "gh"] ne {1}} {
        incr nbFailures
        puts "T87 KO"
    }

    if {[dbSearch "abc"] ne {1 2}} {
        incr nbFailures
        puts "T88 KO"
    }

    dbNewDim "q.abc hi"
    if {[dbGetDim "q.abc hi"] ne {1}} {
        incr nbFailures
        puts "T89 KO"
    }

    if {[catch {dbNewEmptyFragment Unknown "unknown1"} errorMsg]} {
        if {$errorMsg ne "::dinah::dbNewEmptyFragment --> the type Unknown is\
                          not a valid type (viz. Txt, Date, Link or Label)"} {
            incr nbFailures
            puts "T90 KO"
        }
    } else {
        incr nbFailures
        puts "T90 KO"
    }

    puts "$nbFailures test(s) failed"
}
