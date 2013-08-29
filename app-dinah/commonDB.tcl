###################
# FILE MANAGEMENT #
###################

proc dbSaveTo {fn} {
    if {$::dinah::writePermission} {
        set fp [open $fn w]
        puts $fp [list array set ::dinah::db [array get ::dinah::db]]
        close $fp
    }
}

proc dbSave {} { ::dinah::dbSaveTo $::dinah::dbFile }

#############
# LOW LEVEL #
#############

proc dbExists {key} {
    info exists ::dinah::db($key)
}

proc dbGet {key} {
    if {![::dinah::dbExists $key]} {
        error "::dinah::dbGet --> key $key does not exist"
    }
    return $::dinah::db($key)
}

proc dbGetDimensions {} {
    if {[catch {::dinah::dbGet dimensions} dimNames]} {
        error "::dinah::dbGetDimensions --> $dimNames"
    }
    return $dimNames
}

proc dbSet {key value} {
    set ::dinah::db($key) $value
}

proc dbAGet {pattern} {
    array get ::dinah::db $pattern
}

proc dbOSet {id o} {
    foreach {k v} $o {
        ::dinah::dbSet $id,$k $v
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

proc dbLSet {key index elem} {
    if {![::dinah::dbExists $key]} {
        error "::dinah::dbLSet --> key $key does not exist"
    }
    if {[catch {lset ::dinah::db($key) $index $elem} errorMsg]} {
        error "::dinah::dbLSet --> there is no index $index for the key \
               $key"
    }
}

proc dbSetAttribute {dbid att value} {
    if {![::dinah::dbExists $dbid,isa]} {
        error "::dinah::dbSetAttribute --> there is no object with id $dbid"
    }
    ::dinah::dbSet $dbid,$att $value
}

proc dbAppend {key value} {
    if {![::dinah::dbExists $key]} {
        error "::dinah::dbAppend --> key $key does not exist"
    }
    lappend ::dinah::db($key) $value
}

proc dbNew {o} {
    set id [incr ::dinah::db(lastid)]
    dbOSet $id $o
    return $id
}

##############
# DIMENSIONS #
##############

proc dbGetDim {dimName} {
    if {![::dinah::dbIsADim $dimName]} {
        error "::dinah::dbGetDim --> $dimName is not a dimension"
    }
    if {[catch {::dinah::dbGet $dimName} dim]} {
        error "::dinah::dbGetDim --> $dim"
    }
    return $dim
}

proc dbIsADim {dimName} {
    if {[catch {::dinah::dbGetDimensions} dims]} {
        error "::dinah::dbIsADim --> $dims (SHOULD NEVER HAPPEN...)"
    }
    return [expr { [lsearch $dims $dimName] > -1}]
}

proc dbSetDim {dimName dimValue} {
    if {! [::dinah::editable $dimName]} {
        error "::dinah::dbSetDim --> $dimName is read only or it does not exist"
    }
    ::dinah::dbSet $dimName $dimValue
}

proc dbGetDimForId {dbid} {
    # return a list of shape: {dim segIndex fragIndex dim segIndex fragIndex...}
    set r {}
    if {[catch {::dinah::dbGetDimensions} dims} {
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

proc dbNewDim {dim} {
    if {![::dinah::dbExists $dim] && [regexp {^d\..*} $dim]} {
        if {[catch {::dinah::dbAppend dimensions $dim} errorMsg]} {
            error "::dinah::dbNewDim --> $errorMsg"
        }
        if {[catch {::dinah::dbSetDim $dim {}} errorMsg]} {
            error "::dinah::dbNewDim --> (will never happen) $errorMsg"
        }
    } elseif {[regexp {^q\.(.*)} $dim -> match]} {
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
    } else {
        error "::dinah::dbNewDim --> the dimension $dim already exists and is \
               not a query (i.e. it does not start with 'q.'), or it does not \
               exist but it also does not start with 'd.' or 'q.'"
    }
}

proc dbGetDimSize {dimName} {
    if {[catch {::dinah::dbGetDim $dimName} dim]} {
        error "::dinah::dbGetDimSize --> $dim"
    }
    return [llength $dim]
}

############
# SEGMENTS #
############

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

proc dbGetSegmentIndex {dimName dbid} {
    if {![::dinah::dbIsADim $dimName]} {
        error "::dinah::dbGetSegmentIndex --> $dimName is not a dimension"
    }
    if {![::dinah::dbExists $dbid,isa]} {
        error "::dinah::dbGetSegmentIndex --> there is no object with id $dbid"
    }
    set found [::dinah::dbFindInDim $dimName $dbid]
    if {$found != {}} {
        return [lindex $found 0]
    } else {
        return ""
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

proc dbAppendToSegment {dimName segIndex fragId} {
    if {[catch {::dinah::dbReplaceSegment $dimName $segIndex \
            [linsert [::dinah::dbGetSegment $dimName $segIndex] end $fragId]} \
            errorMsg]} {
        error "::dinah::dbAppendToSegment --> $errorMsg"
    }
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

proc dbRemoveSegment {dimName segIndex} {
    # segIndex must be an integer (e.g. no 'end')
    if {[catch {::dinah::dbGetDim $dimName} dim]} {
        error "::dinah::dbRemoveSegment --> $dim"
    }
    if {! [::dinah::editable $dimName]} {
        # dimName must exist because of the successful dbGetDim (see above)
        error "::dinah::dbRemoveSegment --> $dimName is read only"
    }
    if {($segIndex < 0) || ($segIndex >= [llength $dim])} {
        error "::dinah::dbRemoveSegment --> $dimName has no segment with \
               index $segIndex"
    }
    if {[catch {::dinah::dbSetDim $dimName [lreplace [::dinah::dbGetDim $dimName] \
        $segIndex $segIndex]} errorMsg]} {
        error "::dinah::dbRemoveSegment --> will never happen since we already \
               checked if dimName was existing... $errorMsg"
    }
}

#############
# FRAGMENTS #
#############

# dbInsertFragmentIntoDim: insert node srcId into dimension
# trgDim to the right or to the left of node trgId
# $direction is either "before" or "after"
proc dbInsertFragmentIntoDim {srcId direction trgDim trgId} {
    if {$direction ni {before after}} {
        error "::dinah::dbInsertFragmentIntoDim --> '$direction' is not a valid \
               value for the direction parameter (it should be 'before' \
               or 'after')"
    }
    if {! [::dinah::editable $trgDim]} {
        error "::dinah::dbInsertFragmentIntoDim --> target dimension $trgDim is \
               read only, or does not exist"
    }
    set found [::dinah::dbFindInDim $trgDim $trgId]
    if {$found == {}} {
        error "::dinah::dbInsertFragmentIntoDim --> target fragment $trgId not \
               found in target dimension $trgDim"
    }
    set segIndex [lindex $found 0]
    set fragIndex [lindex $found 1]
    if {[catch {::dinah::dbGetSegment $trgDim $segIndex} seg]} {
        error "::dinah::dbInsertFragmentIntoDim --> $seg"
    }
    if {![::dinah::dbFragmentBelongsToDim $trgDim $srcId]} {
        if {$direction eq "after"} { incr fragIndex }
        set newSegment [linsert $seg $fragIndex $srcId]
        if {[catch {::dinah::dbReplaceSegment $trgDim $segIndex $newSegment} \
                errorMsg]} {
            error "::dinah::dbInsertFragmentIntoDim --> $errorMsg"
        }
    } else {
        error "::dinah::dbInsertFragmentIntoDim --> the source fragment $srcId \
            already belongs to the target dimension $trgDim"
    }
}

proc dbMoveFragmentBetweenDims {srcDim srcId direction trgDim trgId} {
    if {! [::dinah::editable $srcDim]} {
        error "::dinah::dbMoveFragmentBetweenDims --> the source dimension \
               $srcDim from which the fragment $srcId would be removed is \
               read only or does not exist"
    }
    if {$srcDim eq $trgDim} {
        # in this case the fragment $srcId is moved from one place of $srcDim
        # to another place of $srcDim, maybe from one segment of srcDim to
        # another segment of $srcDim, or from its current location to another
        # location in the same segment
        if {[catch {::dinah::dbRemoveFragmentFromDim $srcDim $srcId} \
                errorMsg]} {
            error "::dinah::dbMoveFragmentBetweenDims --> $errorMsg"
        }
        if {[catch {::dinah::dbInsertFragmentIntoDim $srcId $direction \
                $trgDim $trgId} errorMsg]} {
            error "::dinah::dbMoveFragmentBetweenDims --> $errorMsg"
        }
    } else {
        if {[catch {::dinah::dbInsertFragmentIntoDim $srcId $direction \
                $trgDim $trgId} errorMsg]} {
            error "::dinah::dbMoveFragmentBetweenDims --> $errorMsg"
        }
        if {[catch {::dinah::dbRemoveFragmentFromDim $srcDim $srcId} \
                errorMsg]} {
            if {[catch {::dinah::dbRemoveFragmentFromDim $trgDim $srcId} \
                    errorMsg2]} {
                error "::dinah::dbMoveFragmentBetweenDims --> should never \
                    happen since we simply cancel the last successful action. \
                    In a concurrent environment the call to \
                    dbMoveFragmentBetweenDims \ should be design as a \
                    transaction. $errorMsg2"
            }
            error "::dinah::dbMoveFragmentBetweenDims --> $errorMsg"
        }
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

proc dbRemoveFragmentFromDim {dimName fragId} {
    if {! [::dinah::editable $dimName]} {
        error "::dinah::dbRemoveFragmentFromDim --> dimension $dimName is \
               read only, or does not exist"
    }
    set found [::dinah::dbFindInDim $dimName $fragId]
    if {$found eq {}} {
        error "::dinah::dbRemoveFragmentFromDim --> fragment $fragId does not \
               belong to dimension $dimName"
    }
    set segIndex [lindex $found 0]
    set fragIndex [lindex $found 1]
    if {[catch {::dinah::dbRemoveFragmentFromSegmentByIndex $dimName $segIndex \
            $fragIndex} errorMsg]} {
        error "::dinah::dbRemoveFragmentFromDim --> $errorMsg"
    }
}

proc dbRemoveFragmentFromSegment {dimName segIndex fragId} {
    if {[catch {::dinah::dbGetSegment $dimName $segIndex} seg]} {
        error "::dinah::dbRemoveFragmentFromSegment --> $seg"
    }
    set fragIndex [lsearch $seg $fragId]
    if {$fragIndex == -1} {
        error "::dinah::dbRemoveFragmentFromSegment --> fragment $fragId is not\
               an element of segment $segIndex of dimension $dimName"
    }
    if {[catch {::dinah::dbRemoveFragmentFromSegmentByIndex $dimName $segIndex \
            $fragIndex} errorMsg]} {
        error "::dinah::dbRemoveFragmentFromSegment --> $errorMsg"
    }
}

proc dbRemoveFragmentFromSegmentByIndex {dimName segIndex fragIndex} {
    if {[catch {::dinah::dbGetSegment $dimName $segIndex} seg]} {
        error "::dinah::dbRemoveFragmentFromSegmentByIndex --> $seg"
    }
    if {($fragIndex < 0) || ($fragIndex >= [llength $seg])} {
        error "::dinah::dbRemoveFragmentFromSegmentByIndex --> segment \
               $segIndex of dimension $dimName has no fragment at index \
               $fragIndex"
    }
    set newSeg [lreplace $seg $fragIndex $fragIndex]
    if {[llength $newSeg] == 0} {
        if {[catch {::dinah::dbRemoveSegment $dimName $segIndex} \
            errorMsg]} {
            error "::dinah::dbRemoveFragmentFromSegmentByIndex --> $errorMsg"
        }
    } else {
        if {[catch {::dinah::dbReplaceSegment $dimName $segIndex \
                $newSeg} errorMsg]} {
            error "::dinah::dbRemoveFragmentFromSegmentByIndex --> $errorMsg"
        }
    }
}

proc dbNewEmptyFragment {type {label ""}} {
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

proc dbFragmentBelongsToDim {dim id} {
    set found [::dinah::dbFindInDim $dim $id]
    if {$found != {}} { return 1 }
    return 0
}

proc dbFindInDim {dimName id} {
    if {[::dinah::dbExists $dimName]} {
        for {set i 0} {$i < [::dinah::dbGetDimSize $dimName]} {incr i} {
            set j [lsearch [::dinah::dbGetSegment $dimName $i] $id]
            if {$j > -1} {
                return [list $i $j]
            }
        }
    }
    return {}
}

#########
# CLONE #
#########

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

#############
# CLIPBOARD #
#############

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

proc dbAddFragmentToEmptyClipboard {dbId} {
    if {![::dinah::dbExists $dbId,isa]} {
        error "::dinah::dbAddFragmentToEmptyClipboard --> $dbId is not \
               an object identifier"
    }
    if {[catch {::dinah::dbClearClipboard} errorMsg]} {
        error "::dinah::dbAddFragmentToEmptyClipboard --> $errorMsg"
    }
    if {[catch {::dinah::dbAppendToSegment $::dinah::dimClipboard 0 $dbId} \
            errorMsg]} {
        error "::dinah::dbAddFragmentToEmptyClipboard --> $errorMsg"
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

proc dbAddSegmentToEmptyClipboard {dimName segIndex} {
    if {[catch {::dinah::dbRemoveSegment $::dinah::dimClipboard 0} errorMsg]} {
        error "::dinah::dbAddSegmentToEmptyClipboard --> $errorMsg"
    }
    if {[catch {::dinah::dbGetSegment $dimName $segIndex} seg]} {
        error "::dinah::dbAddSegmentToEmptyClipboard --> $seg"
    }
    if {[catch {::dinah::dbAppendSegmentToDim $::dinah::dimClipboard $seg} \
            errorMsg]} {
        error "::dinah::dbAddSegmentToEmptyClipboard --> $errorMsg"
    }
}
