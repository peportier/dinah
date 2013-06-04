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
    if {[::dinah::dbIsADim $dimName]} {
        return [::dinah::dbLGet $dimName $segIndex]
    } else {
        error "dbGetSegment: $dimName is not a dimension"
    }
}

proc dbGetSegIndex {d dbid} {
    set found [::dinah::dbFindInDim $d $dbid]
    if {$found != {}} {
        return [lindex $found 0]
    } else {
        return ""
    }
}

proc dbGetFragment {dimName segIndex fragIndex} {
    if {[::dinah::dbIsADim $dimName]} {
        return [::dinah::dbLGet $dimName [list $segIndex $fragIndex]]
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
    set found [::dinah::dbFindInDim $dimName $fragId]
    if {$found != {}} {
        set segIndex [lindex $found 0]
        set fragIndex [lindex $found 1]
        _dbRemFragFromSeg $dimName $segIndex $fragIndex
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

proc dbGetDimForId {dbid} {
    set r {}
    foreach d [::dinah::dbGet dimensions] {
        if {( [::dinah::editable $d]            ) &&
            ( $d ni {d.clipboard d.noticeLevel} ) &&
            ( ! [string match q* $d]            ) &&
            ( [set found [::dinah::dbFindInDim $d $dbid]] != {} )} {
                lappend r $d [lindex $found 0] [lindex $found 1]
        }
    }
    return $r
}

proc dbIsADim {dimName} {
    expr { [lsearch [::dinah::dbGet "dimensions"] $dimName] > -1}
}

# dbInsertNodeIntoDim: insert node srcId into dimension
# trgDim at the right or at the left of node trgId
# $direction is either "right" or "left"
proc dbInsertNodeIntoDim {srcId direction trgDim trgId} {
    if {! [::dinah::editable $trgDim]} {return 0}
    set found [::dinah::dbFindInDim $trgDim $trgId]
    if {$found != {}} {
        set segIndex [lindex $found 0]
        set fragIndex [lindex $found 1]
        set seg [::dinah::dbGetSegment $trgDim $segIndex]
        if {![::dinah::dbNodeBelongsToDim $trgDim $srcId]} {
            if {$direction eq "right"} { incr fragIndex }
            set newSegment [linsert $seg $fragIndex $srcId]
            ::dinah::dbReplaceSegment $trgDim $segIndex $newSegment
            return 1
        } else {
            return 0
        }
    } else {
        set found [::dinah::dbFindInDim $trgDim $srcId]
        if {$found == {}} {
            if {$direction eq "right"} {
                ::dinah::dbAppendSegmentToDim $trgDim [list $trgId $srcId]
            } else {
                ::dinah::dbAppendSegmentToDim $trgDim [list $srcId $trgId]
            }
            return 1
        } else {
            set segIndex [lindex $found 0]
            set fragIndex [lindex $found 1]
            set seg [::dinah::dbGetSegment $trgDim $segIndex]
            if {$direction eq "left"} { incr fi }
            set newSegment [linsert $seg $fragIndex $trgId]
            ::dinah::dbReplaceSegment $trgDim $segIndex $newSegment
            return 1
        }
    }
}

proc dbMoveNodeBetweenDims {srcDim srcId direction trgDim trgId} {
    if {! [::dinah::editable $srcDim]} {return 0}
    if {$srcDim eq $trgDim} {
        ::dinah::dbRemFragFromDim $srcDim $srcId
        puts [::dinah::dbInsertNodeIntoDim $srcId $direction $trgDim $trgId]
        return 1
    } elseif {[::dinah::dbInsertNodeIntoDim $srcId $direction $trgDim $trgId ]} {
        ::dinah::dbRemFragFromDim $srcDim $srcId
        return 1
    } else {
        return 0
    }
}

proc dbClone {id} {
    set attributes {}
    foreach {k v} [::dinah::dbAGet $id,*] {
        regexp {^.*,(.*)} $k -> attName
        lappend attributes $attName $v
    }
    set clone [::dinah::dbNew $attributes]
    set found [::dinah::dbFindInDim $::dinah::dimClone $id]
    if {$found != {}} {
        set segIndex [lindex $found 0]
        ::dinah::dbAppendToSegment $::dinah::dimClone $segIndex $clone
    } else {
        ::dinah::dbAppendSegmentToDim $::dinah::dimClone [list $id $clone]
    }
}

proc dbNewEmptyNode {type {label ""}} {
    if {$type eq "Txt"} {
        return [::dinah::dbNew [list isa Txt txt {} label $label]]
    }
    if {$type eq "Date"} {
        return [::dinah::dbNew [list isa Date day "" month "" year "" hour "" minute "" certain 0 label $label]]
    }
    if {$type eq "Struct"} {
        return [::dinah::dbNew [list isa Struct label $label]]
    }
    if {$type eq "Link"} {
        return [::dinah::dbNew [list isa Link label $label]]
    }
}

proc dbNewDim {dim} {
    if {![::dinah::dbExists $dim] && [regexp {^d\..*} $dim]} {
        ::dinah::dbAppend "dimensions" $dim
        ::dinah::dbSetDim $dim {}
        return 1
    }
    if {[regexp {^q\.(.*)} $dim -> match]} {
        set terms [split $match]
        if {![::dinah::dbExists $dim]} {
            ::dinah::dbAppend dimensions $dim
        }
        ::dinah::dbSetDim $dim [list [::dinah::keywords $terms]]
        return 1
    }
    return 0
}

proc dbNodeBelongsToDim {dim id} {
    set found [::dinah::dbFindInDim $dim $id]
    if {$found != {}} { return 1 }
    return 0
}

proc dbFindInDim {dim id} {
    if {[::dinah::dbExists $dim]} {
        for {set i 0} {$i < [llength [::dinah::dbGet $dim]]} {incr i} {
            set j [lsearch [::dinah::dbLGet $dim $i] $id]
            if {$j > -1} {
                return [list $i $j]
            }
        }
    }
    return {}
}

