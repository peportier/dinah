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

    puts "$nbFailures test(s) failed"
}
