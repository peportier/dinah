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
        error "::dinah::dbSetDim --> $dimName is read only or it does not exist"
    } else {
        set ::dinah::db($dimName) $dimValue
    }

}

proc dbRemoveSegment {dimName segIndex} {
    # segIndex must be an integer (e.g. no 'end')
    if {[catch {::dinah::dbGet $dimName} dim]} {
        error "::dinah::dbRemoveSegment --> $dim"
    }
    if {! [::dinah::editable $dimName]} {
        # dimName must exist because of the successful dbGet (see above)
        error "::dinah::dbRemoveSegment --> $dimName is read only"
    }
    if {($segIndex < 0) || ($segIndex >= [llength $dim])} {
        error "::dinah::dbRemoveSegment --> $dimName has no segment with \
               index $segIndex"
    }
    if {[catch {::dinah::dbSetDim $dimName [lreplace [::dinah::dbGet $dimName] \
        $segIndex $segIndex]} errorMsg]} {
        error "::dinah::dbRemoveSegment --> will never happen since we already \
               checked if dimName was existing... $errorMsg"
    } else {
        return
    }
}

proc dbSetAttribute {dbid att value} {
    if {[::dinah::dbExists $dbid,isa]} {
        ::dinah::dbSet $dbid,$att $value
    } else {
        error "::dinah::dbSetAttribute --> there is no object with id $dbid"
    }
}

proc dbGet {key} {
    if {[::dinah::dbExists $key]} {
        return $::dinah::db($key)
    } else {
        error "::dinah::dbGet --> key $key does not exist"
    }
}

proc dbExists {key} {
    info exists ::dinah::db($key)
}

proc dbLSet {key index elem} {
    if {[::dinah::dbExists $key]} {
        if {[catch {lset ::dinah::db($key) $index $elem} errorMsg]} {
            error "::dinah::dbLSet --> there is no index $index for the key \
                   $key"
        } else {
            return
        }
    } else {
        error "::dinah::dbLSet --> key $key does not exist"
    }
}

proc dbReplaceSegment {dimName segIndex segValue} {
    if {! [::dinah::editable $dimName]} {
        error "::dinah::dbReplaceSegment --> $dimName is read only or \
               it does not exist"
    } else {
        if {[catch {::dinah::dbLSet $dimName $segIndex $segValue} errorMsg]} {
            error "::dinah::dbReplaceSegment --> $errorMsg"
        } else {
            return
        }
    }
}

proc dbLGet {key index} {
    # index must be an integer (e.g. no 'end', no multidim indexation with
    # a list of integers, ...)
    if {[catch {::dinah::dbGet $key} atKey]} {
        error "::dinah::dbLGet --> $atKey"
    } else {
        if {($index < 0) || ($index >= [llength $atKey])} {
            error "::dinah::dbLGet --> object at key $key has no element at \
                   index $index"
        } else {
            return [lindex $atKey $index]
        }
    }
}

proc dbGetSegment {dimName segIndex} {
    if {[::dinah::dbIsADim $dimName]} {
        if {[catch {::dinah::dbLGet $dimName $segIndex} res]} {
            error "::dinah::dbGetSegment --> $res"
        } else {
            return $res
        }
    } else {
        error "::dinah::dbGetSegment --> $dimName is not a dimension"
    }
}

proc dbAppendToSegment {dimName segIndex fragId} {
    if {[catch {::dinah::dbReplaceSegment $dimName $segIndex \
            [linsert [::dinah::dbGetSegment $dimName $segIndex] end $fragId]} \
            errorMsg]} {
        error "::dinah::dbAppendToSegment --> $errorMsg"
    } else {
        return
    }
}

proc dbGetSegIndex {dimName dbid} {
    if {[::dinah::dbIsADim $dimName]} {
        if {[::dinah::dbExists $dbid,isa]} {
            set found [::dinah::dbFindInDim $dimName $dbid]
            if {$found != {}} {
                return [lindex $found 0]
            } else {
                return ""
            }
        } else {
            error "::dinah::dbGetSegIndex --> there is no object with id $dbid"
        }
    } else {
        error "::dinah::dbGetSegIndex --> $dimName is not a dimension"
    }
}

proc dbGetFragment {dimName segIndex fragIndex} {
    if {[::dinah::dbIsADim $dimName]} {
        if {[catch {::dinah::dbGetSegment $dimName $segIndex $fragIndex} \
                seg]} {
            error "::dinah::dbGetFragment --> $seg"
        } else {
            if {($fragIndex < 0) || ($fragIndex >= [llength $seg])} {
                error "::dinah::dbGetFragment --> segment $segIndex of \
                       dimension $dimName has no fragment at index $fragIndex"
            } else {
                return [lindex $seg $fragIndex]
            }
        }
    } else {
        error "::dinah::dbGetFragment --> $dimName is not a dimension"
    }
}

proc dbAppend {key value} {
    if {[::dinah::dbExists $key]} {
        lappend ::dinah::db($key) $value
    } else {
        error "::dinah::dbAppend --> key $key does not exist"
    }
}

proc dbAppendSegmentToDim {dimName seg} {
    if {! [::dinah::editable $dimName]} {
        error "::dinah::dbAppendSegmentToDim --> dimension $dimName is \
               read only, or it does not exist"
    } else {
        if {[catch {::dinah::dbAppend $dimName $seg} errorMsg]} {
            error "::dinah::dbAppendSegmentToDim --> $errorMsg"
        } else {
            return
        }
    }
}

proc dbAGet {pattern} {
    array get ::dinah::db $pattern
}

proc dbRemFragFromDim {dimName fragId} {
    if {! [::dinah::editable $dimName]} {
        error "::dinah::dbRemFragFromDim --> dimension $dimName is read only,\
               or does not exist"
    } else {
        set found [::dinah::dbFindInDim $dimName $fragId]
        if {$found != {}} {
            set segIndex [lindex $found 0]
            set fragIndex [lindex $found 1]
            if {[catch {::dinah::dbRemFragFromSegByIndex $dimName $segIndex \
                    $fragIndex} errorMsg]} {
                error "::dinah::dbRemFragFromDim --> $errorMsg"
            } else {
                return
            }
        } else {
            error "::dinah::dbRemFragFromDim --> fragment $fragId does not \
                   belong to dimension $dimName"
        }
    }
}

proc dbRemFragFromSeg {dimName segIndex fragId} {
    if {[catch {::dinah::dbGetSegment $dimName $segIndex} seg]} {
        error "::dinah::dbRemFragFromSeg --> $seg"
    } else {
        set fragIndex [lsearch $seg $fragId]
        if {$fragIndex > -1} {
            if {[catch {::dinah::dbRemFragFromSegByIndex $dimName $segIndex \
                    $fragIndex} errorMsg]} {
                error "::dinah::dbRemFragFromSeg --> $errorMsg"
            } else {
                return
            }
        } else {
            error "::dinah::dbRemFragFromSeg --> fragment $fragId is not an \
                   element of segment $segIndex of dimension $dimName"
        }
    }
}

proc dbRemFragFromSegByIndex {dimName segIndex fragIndex} {
    if {[catch {::dinah::dbGetSegment $dimName $segIndex} seg]} {
        error "::dinah::dbRemFragFromSegByIndex --> $seg"
    } else {
        if {($fragIndex < 0) || ($fragIndex >= [llength $seg])} {
            error "::dinah::dbRemFragFromSegByIndex --> segment $segIndex of \
                   dimension $dimName has no fragment at index $fragIndex"
        } else {
            set newSeg [lreplace $seg $fragIndex $fragIndex]
            if {[llength $newSeg] == 0} {
                if {[catch {::dinah::dbRemoveSegment $dimName $segIndex} \
                    errorMsg]} {
                    error "::dinah::dbRemFragFromSegByIndex --> $errorMsg"
                } else {
                    return
                }
            } else {
                if {[catch {::dinah::dbReplaceSegment $dimName $segIndex \
                        $newSeg} errorMsg]} {
                    error "::dinah::dbRemFragFromSegByIndex --> $errorMsg"
                } else {
                    return
                }
            }
        }
    }
}

proc dbGetDimForId {dbid} {
    # return a list of shape: {dim segIndex fragIndex dim segIndex fragIndex...}
    set r {}
    if {[catch {::dinah::dbGet dimensions} dims} {
        error "::dinah::dbGetDimForId --> $dims (SHOULD NEVER HAPPEN...)"
    } else {
        foreach d $dims {
            if {( [::dinah::editable $d]            ) &&
                ( ! [string match q* $d]            ) &&
                ( [set found [::dinah::dbFindInDim $d $dbid]] != {} )} {
                    lappend r $d [lindex $found 0] [lindex $found 1]
            }
        }
        return $r
    }
}

proc dbIsADim {dimName} {
    # will not catch error from dbGet: ::dinah::db(dimensions) must exist
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


proc dbClearClipboard {} {
    ::dinah::dbSetDim $::dinah::dimClipboard {}
}

proc dbClipboardLastItem {} {
    return [::dinah::dbLGet $::dinah::dimClipboard {0 end}]
}

proc dbClipboardIsEmpty {} {
    return [expr {[::dinah::dbClipboardLastItem] == {}}]
}

proc dbGetClipboard {} {
    return [::dinah::dbGetSegment $::dinah::dimClipboard 0]
}

proc dbAddFragmentToCleanClipboard {dbId} {
    if {::dinah::dbExists $dbId,isa} {
        ::dinah::dbClearClipboard
        ::dinah::dbAppendSegmentToDim $::dinah::dimClipboard [list $dbId]
    } else {
        error "::dinah::dbAddFragmentToCleanClipboard $dbId --> $dbId is not \
               an object identifier"
    }
}

proc dbAddFragmentToClipboard {dbId} {
    if {::dinah::dbExists $dbId,isa} {
        ::dinah::dbAppendToSegment $::dinah::dimClipboard 0 $dbId
    } else {
        error "::dinah::dbAddFragmentToClipboard $dbId --> $dbId is not an \
               object identifier"
    }
}

proc dbAddSegmentToCleanClipboard {dim segIndex} {
    ::dinah::dbClearClipboard
    ::dinah::dbAppendSegmentToDim $::dinah::dimClipboard \
        [::dinah::dbGetSegment $dim $segIndex]
}

proc dbGetDimSize {dim} {
    if {[::dinah::dbIsADim $dimName]} {
        return [llength [::dinah::dbGet $dimName]]
    } else {
        error "::dinah::dbGetDimSize $dim --> $dim is not a dimension"
    }
}
