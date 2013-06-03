proc dbSaveTo {fn} {
    if {$::dinah::writePermission} {
        set fp [open $fn w]
        puts $fp [list array set ::dinah::db [array get ::dinah::db]]
        close $fp
    }
}

proc dbSave {} { ::dinah::dbSaveTo $::dinah::dbFile }

proc dbNew {o} {
    set id [incr ::dinah::db(lastid)]
    dbOSet $id $o
    return $id
}

proc dbOSet {id o} {
    foreach {k v} $o {
        ::dinah::dbSet $id,$k $v
    }
}

proc dbSet {key value} {
    set ::dinah::db($key) $value
    return 1
}

proc dbSetDim {dimName dimValue} {
    if {! [::dinah::editable $dimName]} {
        return 0
    } else {
        set ::dinah::db($dimName) $dimValue
        return 1
    }

}

proc dbRemoveSegment {dimName segIndex} {
    ::dinah::dbSetDim $dimName [lreplace [::dinah::dbGet $dimName] $segIndex $segIndex]
}

proc dbSetAttribute {dbid att value} {
    if {[info exists ::dinah::db($dbid,isa)]} {
        ::dinah::dbSet $dbid,$att $value
        return 1
    } else {
        return 0
    }
}

proc dbGet {key} {
    return $::dinah::db($key)
}

proc dbExists {key} {
    info exists ::dinah::db($key)
}

#the element [dbLGet $key $index] must exist or
#error "list index out of range" will be raised
proc dbLSet {key index elem} {
    lset ::dinah::db($key) $index $elem
    return 1
}

proc dbReplaceSegment {dimName segIndex segValue} {
    if {! [::dinah::editable $dimName]} {
        return 0
    } else {
        ::dinah::dbLSet $dimName $segIndex $segValue
        return 1
    }
}

proc dbAppendToSegment {dimName segIndex fragId} {
    ::dinah::dbReplaceSegment $dimName $segIndex [linsert [::dinah::dbGetSegment $dimName $segIndex] end $fragId]
}

proc dbLGet {key index} {
    lindex $::dinah::db($key) $index
}

proc dbGetSegment {dimName segIndex} {
    if {[::dinah::isADim $dimName]} {
        return [::dinah::dbLGet $dimName $segIndex]
    } else {
        error "dbGetSegment: $dimName is not a dimension"
    }
}

proc dbAppend {key value} {
    lappend ::dinah::db($key) $value
    return 1
}

proc dbAppendSegmentToDim {dimName seg} {
    if {! [::dinah::editable $dimName]} {
        return 0
    } else {
        ::dinah::dbAppend $dimName $seg
        return 1
    }
}

proc dbAGet {pattern} {
    array get ::dinah::db $pattern
}

proc dbRemFragFromDim {dimName fragId} {
    if {! [::dinah::editable $dimName]} {return 0}
    set found [::dinah::findInDim $dimName $fragId]
    if {$found != {}} {
        set si [lindex $found 0]; set fi [lindex $found 1]
        _dbRemFragFromSeg $dimName $si $fi
    } else {
        return 0
    }
}

proc dbRemFragFromSeg {d s dbid} {
    if {! [::dinah::editable $d]} {return 0}
    set fragIndex [lsearch [::dinah::dbLGet $d $s] $dbid]
    if {$fragIndex > -1} {
        return [_dbRemFragFromSeg $d $s $fragIndex]
    } else {
        return 0
    }
}

#_dbRemFragFromSeg : d, s, and f must be correct
# i.e. at index f of segment s of dimension d, there is something
# and this something will be removed
proc _dbRemFragFromSeg {d s f} {
    set newS [lreplace [::dinah::dbLGet $d $s] $f $f]
    if {[llength $newS] == 0} {
        ::dinah::dbRemoveSegment $d $s
    } else {
        ::dinah::dbReplaceSegment $d $s $newS
    }
    return 1
}

proc dbGetSegIndex {d dbid} {
    set found [::dinah::findInDim $d $dbid]
    if {$found != {}} {
        return [lindex $found 0]
    } else {
        return ""
    }
}

