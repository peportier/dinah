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
    }
    set ::dinah::db($dimName) $dimValue
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
    }
}

proc dbSetAttribute {dbid att value} {
    if {![::dinah::dbExists $dbid,isa]} {
        error "::dinah::dbSetAttribute --> there is no object with id $dbid"
    }
    ::dinah::dbSet $dbid,$att $value
}

proc dbGet {key} {
    if {![::dinah::dbExists $key]} {
        error "::dinah::dbGet --> key $key does not exist"
    }
    return $::dinah::db($key)
}

proc dbExists {key} {
    info exists ::dinah::db($key)
}

proc dbLSet {key index elem} {
    if {![::dinah::dbExists $key]} {
        error "::dinah::dbLSet --> key $key does not exist"
    }
    if {[catch {lset ::dinah::db($key) $index $elem} errorMsg]} {
        error "::dinah::dbLSet --> there is no index $index for the key \
               $key"
    }
}

proc dbReplaceSegment {dimName segIndex segValue} {
    if {! [::dinah::editable $dimName]} {
        error "::dinah::dbReplaceSegment --> $dimName is read only or \
               it does not exist"
    }
    if {[catch {::dinah::dbLSet $dimName $segIndex $segValue} errorMsg]} {
        error "::dinah::dbReplaceSegment --> $errorMsg"
    }
}

proc dbLGet {key index} {
    # index must be an integer (e.g. no 'end', no multidim indexation with
    # a list of integers, ...)
    if {[catch {::dinah::dbGet $key} atKey]} {
        error "::dinah::dbLGet --> $atKey"
    }
    if {($index < 0) || ($index >= [llength $atKey])} {
        error "::dinah::dbLGet --> object at key $key has no element at \
               index $index"
    }
    return [lindex $atKey $index]
}

proc dbGetSegment {dimName segIndex} {
    if {![::dinah::dbIsADim $dimName]} {
        error "::dinah::dbGetSegment --> $dimName is not a dimension, or it \
               does not exist"
    }
    if {[catch {::dinah::dbLGet $dimName $segIndex} res]} {
        error "::dinah::dbGetSegment --> $res"
    }
    return $res
}

proc dbAppendToSegment {dimName segIndex fragId} {
    if {[catch {::dinah::dbReplaceSegment $dimName $segIndex \
            [linsert [::dinah::dbGetSegment $dimName $segIndex] end $fragId]} \
            errorMsg]} {
        error "::dinah::dbAppendToSegment --> $errorMsg"
    }
}

proc dbGetSegIndex {dimName dbid} {
    if {![::dinah::dbIsADim $dimName]} {
        error "::dinah::dbGetSegIndex --> $dimName is not a dimension"
    }
    if {![::dinah::dbExists $dbid,isa]} {
        error "::dinah::dbGetSegIndex --> there is no object with id $dbid"
    }
    set found [::dinah::dbFindInDim $dimName $dbid]
    if {$found != {}} {
        return [lindex $found 0]
    } else {
        return ""
    }
}

proc dbGetFragment {dimName segIndex fragIndex} {
    if {![::dinah::dbIsADim $dimName]} {
        error "::dinah::dbGetFragment --> $dimName is not a dimension"
    }
    if {[catch {::dinah::dbGetSegment $dimName $segIndex $fragIndex} \
            seg]} {
        error "::dinah::dbGetFragment --> $seg"
    }
    if {($fragIndex < 0) || ($fragIndex >= [llength $seg])} {
        error "::dinah::dbGetFragment --> segment $segIndex of \
               dimension $dimName has no fragment at index $fragIndex"
    } else {
        return [lindex $seg $fragIndex]
    }
}

proc dbAppend {key value} {
    if {![::dinah::dbExists $key]} {
        error "::dinah::dbAppend --> key $key does not exist"
    }
    lappend ::dinah::db($key) $value
}

proc dbAppendSegmentToDim {dimName seg} {
    if {! [::dinah::editable $dimName]} {
        error "::dinah::dbAppendSegmentToDim --> dimension $dimName is \
               read only, or it does not exist"
    }
    if {[catch {::dinah::dbAppend $dimName $seg} errorMsg]} {
        error "::dinah::dbAppendSegmentToDim --> $errorMsg"
    }
}

proc dbAGet {pattern} {
    array get ::dinah::db $pattern
}

proc dbRemFragFromDim {dimName fragId} {
    if {! [::dinah::editable $dimName]} {
        error "::dinah::dbRemFragFromDim --> dimension $dimName is read only,\
               or does not exist"
    }
    set found [::dinah::dbFindInDim $dimName $fragId]
    if {$found eq {}} {
        error "::dinah::dbRemFragFromDim --> fragment $fragId does not \
               belong to dimension $dimName"
    }
    set segIndex [lindex $found 0]
    set fragIndex [lindex $found 1]
    if {[catch {::dinah::dbRemFragFromSegByIndex $dimName $segIndex \
            $fragIndex} errorMsg]} {
        error "::dinah::dbRemFragFromDim --> $errorMsg"
    }
}

proc dbRemFragFromSeg {dimName segIndex fragId} {
    if {[catch {::dinah::dbGetSegment $dimName $segIndex} seg]} {
        error "::dinah::dbRemFragFromSeg --> $seg"
    }
    set fragIndex [lsearch $seg $fragId]
    if {$fragIndex == -1} {
        error "::dinah::dbRemFragFromSeg --> fragment $fragId is not an \
               element of segment $segIndex of dimension $dimName"
    }
    if {[catch {::dinah::dbRemFragFromSegByIndex $dimName $segIndex \
            $fragIndex} errorMsg]} {
        error "::dinah::dbRemFragFromSeg --> $errorMsg"
    }
}

proc dbRemFragFromSegByIndex {dimName segIndex fragIndex} {
    if {[catch {::dinah::dbGetSegment $dimName $segIndex} seg]} {
        error "::dinah::dbRemFragFromSegByIndex --> $seg"
    }
    if {($fragIndex < 0) || ($fragIndex >= [llength $seg])} {
        error "::dinah::dbRemFragFromSegByIndex --> segment $segIndex of \
               dimension $dimName has no fragment at index $fragIndex"
    }
    set newSeg [lreplace $seg $fragIndex $fragIndex]
    if {[llength $newSeg] == 0} {
        if {[catch {::dinah::dbRemoveSegment $dimName $segIndex} \
            errorMsg]} {
            error "::dinah::dbRemFragFromSegByIndex --> $errorMsg"
        }
    } else {
        if {[catch {::dinah::dbReplaceSegment $dimName $segIndex \
                $newSeg} errorMsg]} {
            error "::dinah::dbRemFragFromSegByIndex --> $errorMsg"
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
    if {[catch {::dinah::dbGet dimensions} dims} {
        error "::dinah::dbIsADim --> $dims (SHOULD NEVER HAPPEN...)"
    }
    return [expr { [lsearch $dims $dimName] > -1}]
}

# dbInsertNodeIntoDim: insert node srcId into dimension
# trgDim to the right or to the left of node trgId
# $direction is either "before" or "after"
proc dbInsertNodeIntoDim {srcId direction trgDim trgId} {
    if {$direction ni {before after}} {
        error "::dinah::dbInsertNodeIntoDim --> '$direction' is not a valid \
               value for the direction parameter (it should be 'before' \
               or 'after')"
    }
    if {! [::dinah::editable $trgDim]} {
        error "::dinah::dbInsertNodeIntoDim --> target dimension $trgDim is \
               read only, or does not exist"
    }
    set found [::dinah::dbFindInDim $trgDim $trgId]
    if {$found == {}} {
        error "::dinah::dbInsertNodeIntoDim --> target fragment $trgId not \
               found in target dimension $trgDim"
    }
    set segIndex [lindex $found 0]
    set fragIndex [lindex $found 1]
    if {[catch {::dinah::dbGetSegment $trgDim $segIndex} seg]} {
        error "::dinah::dbInsertNodeIntoDim --> $seg"
    }
    if {![::dinah::dbNodeBelongsToDim $trgDim $srcId]} {
        if {$direction eq "after"} { incr fragIndex }
        set newSegment [linsert $seg $fragIndex $srcId]
        if {[catch {::dinah::dbReplaceSegment $trgDim $segIndex $newSegment} \
                errorMsg]} {
            error "::dinah::dbInsertNodeIntoDim --> $errorMsg"
        }
    } else {
        error "::dinah::dbInsertNodeIntoDim --> the source fragment $srcId \
            already belongs to the target dimension $trgDim"
    }
}

proc dbMoveNodeBetweenDims {srcDim srcId direction trgDim trgId} {
    if {! [::dinah::editable $srcDim]} {
        error "::dinah::dbMoveNodeBetweenDims --> the source dimension \
               $srcDim from which the fragment $srcId would be removed is \
               read only or does not exist"
    }
    if {$srcDim eq $trgDim} {
        # in this case the fragment $srcId is moved from one place of $srcDim
        # to another place of $srcDim, maybe from one segment of srcDim to
        # another segment of $srcDim, or from its current place to another one
        # in the same segment
        if {[catch {::dinah::dbRemFragFromDim $srcDim $srcId} errorMsg]} {
            error "::dinah::dbMoveNodeBetweenDims --> $errorMsg"
        }
        if {[catch {::dinah::dbInsertNodeIntoDim $srcId $direction \
                $trgDim $trgId} errorMsg]} {
            error "::dinah::dbMoveNodeBetweenDims --> $errorMsg"
        }
    } else {
        if {[catch {::dinah::dbInsertNodeIntoDim $srcId $direction \
                $trgDim $trgId} errorMsg]} {
            error "::dinah::dbMoveNodeBetweenDims --> $errorMsg"
        }
        if {[catch {::dinah::dbRemFragFromDim $srcDim $srcId} errorMsg]} {
            if {[catch {::dinah::dbRemFragFromDim $trgDim $srcId} errorMsg2]} {
                error "::dinah::dbMoveNodeBetweenDims --> should never happen \
                    since we simply cancel the last successful action. In a \
                    a concurrent environment the call to dbMoveNodeBetweenDims \
                    should be design as a transaction. $errorMsg2"
            }
            error "::dinah::dbMoveNodeBetweenDims --> $errorMsg"
        }
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
    if {$type eq "Link"} {
        return [::dinah::dbNew [list isa Link label $label]]
    }
}

proc dbNewDim {dim} {
    if {![::dinah::dbExists $dim] && [regexp {^d\..*} $dim]} {
        if {[catch {::dinah::dbAppend "dimensions" $dim} errorMsg]} {
            error "::dinah::dbNewDim --> $errorMsg"
        }
        if {[catch {::dinah::dbSetDim $dim {}} errorMsg]} {
            error "::dinah::dbNewDim --> (will never happen) $errorMsg"
        }
    }
    if {[regexp {^q\.(.*)} $dim -> match]} {
        set terms [split $match]
        if {![::dinah::dbExists $dim]} {
            if {[catch {::dinah::dbAppend dimensions $dim} errorMsg]} {
                error "::dinah::dbNewDim --> $errorMsg"
            }
        }
        if {[catch {::dinah::dbSetDim $dim [list [::dinah::keywords $terms]]} \
                errorMsg]} {
            error "::dinah::dbNewDim --> $errorMsg"
        }
    }
    error "::dinah::dbNewDim --> the dimension $dim already exists, or it \
           does not start with 'd.'"
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
    # we only use the first segment of the clipboard dimension.
    # this first segment must exist. thus the value '{{}}' we use to
    # clear the clipboard
    if {[catch {::dinah::dbSetDim $::dinah::dimClipboard {{}}} errorMsg]} {
        error "::dinah::dbClearClipboard --> $errorMsg"
    }
}

proc dbClipboardLastItem {} {
    if {[catch {::dinah::dbGetClipboard} seg]} {
        error "::dinah::dbClipboardLastItem --> $seg"
    }
    return [lindex $seg end]
}

proc dbClipboardIsEmpty {} {
    if {[catch {::dinah::dbClipboardLastItem} lastItem]} {
        error "::dinah::dbClipboardIsEmpty --> $lastItem"
    }
    return [expr {$lastItem == {}}]
}

proc dbGetClipboard {} {
    if {[catch {::dinah::dbGetSegment $::dinah::dimClipboard 0} seg]} {
        error "::dinah::dbGetClipboard --> $seg"
    }
    return $seg
}

proc dbAddFragmentToCleanClipboard {dbId} {
    if {![::dinah::dbExists $dbId,isa]} {
        error "::dinah::dbAddFragmentToCleanClipboard --> $dbId is not \
               an object identifier"
    }
    if {[catch {::dinah::dbClearClipboard} errorMsg]} {
        error "::dinah::dbAddFragmentToCleanClipboard --> $errorMsg"
    }
    if {[catch {::dinah::dbAppendToSegment $::dinah::dimClipboard 0 $dbId} \
            errorMsg]} {
        error "::dinah::dbAddFragmentToCleanClipboard --> $errorMsg"
    }
}

proc dbAddFragmentToClipboard {dbId} {
    if {![::dinah::dbExists $dbId,isa]} {
        error "::dinah::dbAddFragmentToClipboard --> $dbId is not an \
               object identifier"
    }
    if {[catch {::dinah::dbAppendToSegment $::dinah::dimClipboard 0 $dbId} \
            errorMsg]} {
        error "::dinah::dbAddFragmentToClipboard --> $errorMsg"
    }
}

proc dbAddSegmentToCleanClipboard {dimName segIndex} {
    if {[catch {::dinah::dbRemoveSegment $::dinah::dimClipboard 0} errorMsg]} {
        error "::dinah::dbAddSegmentToCleanClipboard --> $errorMsg"
    }
    if {[catch {::dinah::dbGetSegment $dimName $segIndex} seg]} {
        error "::dinah::dbAddSegmentToCleanClipboard --> $seg"
    }
    if {[catch {::dinah::dbAppendSegmentToDim $::dinah::dimClipboard $seg} \
            errorMsg]} {
        error "::dinah::dbAddSegmentToCleanClipboard --> $errorMsg"
    }
}

proc dbGetDimSize {dimName} {
    if {![::dinah::dbIsADim $dimName]} {
        error "::dinah::dbGetDimSize --> $dimName is not a dimension"
    }
    if {[catch {::dinah::dbGet $dimName} dim]} {
        error "::dinah::dbGetDimSize --> $dim"
    }
    return [llength $dim]
}
