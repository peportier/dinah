namespace eval ::dinah::agreg {

#should be OK:
#set X {{{k d e}}}
#set p {{a b} {c d e f} {g h}}
#
#should be KO:
#set X {{{k e d}}}
#set p {{a b} {c d e f} {g h}}
#
#should be OK:
#set X {{{k d g}}}
#set p {{a b} {c d e} {f g h}}
#set X {}
set p {}

proc run {dimAgreg X} {
    variable ::dinah::agreg::p
    set p $dimAgreg
    for {set XIndex 0} {$XIndex < [llength $X]} {incr XIndex} {
        set d [lindex $X $XIndex]
        foreach x $d {
            set temp {}
            set pos {}
            foreach e $x {
                if {$e ni [concat {*}$p]} {
                    if {$pos == {}} {
                        lappend temp $e
                    } else {
                        addAfterToP [lindex $pos 0] [lindex $pos 1] [list $e]
                        lset pos 1 [expr {[lindex $pos 1] + 1}]
                    }
                } else {
                    set prevPos $pos
                    set pos [getPos $e]
                    if {$temp != {}} {
                        addBeforeToP [lindex $pos 0] [lindex $pos 1] $temp
                        lset pos 1 [expr {[lindex $pos 1] + [llength $temp]}]
                        set temp {}
                    }
                    if {$prevPos != {}} {
                        if {[lindex $prevPos 0] != [lindex $pos 0]} {
                            addAfterToP [lindex $prevPos 0] [lindex $prevPos 1] [lindex $p [lindex $pos 0]]      
                            set p [lreplace $p [lindex $pos 0] [lindex $pos 0]]
                            lset prevPos 1 [expr {[lindex $prevPos 1] + [lindex $pos 1] + 1}]
                            if {[lindex $pos 0] < [lindex $prevPos 0]} {
                                lset prevPos 0 [expr {[lindex $prevPos 0] - 1}]
                            }
                            set pos $prevPos
                        } else {
                            if {[lindex $prevPos 1] > [lindex $pos 1]} {
                                # résolution de cycle intra-dimensionnel
                                return [list 0 [lindex $p [lindex $pos 0] [lindex $pos 1]] $XIndex $p]
                            }
                        }
                    }
                }
            }
            if {$temp != {}} {
                lappend p $temp
            }
        }
    }
    return [list 1 $p]
}

proc addToP {offset segPos fragPos es} {
    variable ::dinah::agreg::p
    set seg [lindex $p $segPos]
    set newseg [linsert $seg [expr {$fragPos + $offset}] {*}$es]
    lset p $segPos $newseg
}

proc addAfterToP {segPos fragPos es} { addToP 1 $segPos $fragPos $es }

proc addBeforeToP {segPos fragPos es} { addToP 0 $segPos $fragPos $es }

proc getPos {e} {
    variable ::dinah::agreg::p
    for {set i 0} {$i < [llength $p]} {incr i} {
        set j [lsearch [lindex $p $i] $e]
        if {$j > -1} {
            return [list $i $j]
        }
    }
    error "algo_dim_agreg: element not present in the agregated dimension" 
}

}
