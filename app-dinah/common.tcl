# can be redefined in a d.init text node
set ::dinah::keyboard(under1) "ampersand"
set ::dinah::keyboard(under2) "eacute"
set ::dinah::keyboard(under3) "quotedbl"
set ::dinah::keyboard(under4) "quoteright"
set ::dinah::keyboard(under5) "parenleft"
set ::dinah::keyboard(under6) "minus"
set ::dinah::keyboard(under7) "egrave"
set ::dinah::keyboard(under8) "underscore"
set ::dinah::keyboard(under9) "ccedilla"
set ::dinah::keyboard(under0) "agrave"

# 'ladd' adds 'what' to '_list' if 'what' isn't an element
# of '_list'
proc ladd {_list what} {
    upvar $_list list
    if {![info exists list] || [lsearch $list $what] == -1} {
	lappend list $what
    }
}

proc lrem {_list what} {
    upvar $_list list
    if {[info exists list]} {
        set i [lsearch $list $what]
        if {$i != -1} {
            set list [lreplace $list $i $i]
        }
    }
}

proc lpop listVar {
    upvar 1 $listVar l
    set r [lindex $l end]
    set l [lreplace $l [set l end] end] ; # Make sure [lreplace] operates on unshared object
    return $r
}

# 'objname'
proc objname {n} { regsub -all {::} $n "" }

proc mkObj {id parentW} {
    variable ::dinah::db
    set o [eval {::dinah::$db($id,isa) #auto $id}]
    $o mkWindow $parentW
    return ::dinah::$o
}

proc findInDim {dim id} {
    variable ::dinah::db
    if {[info exists db($dim)]} {
        for {set i 0} {$i < [llength $db($dim)]} {incr i} {
            set j [lsearch [lindex $db($dim) $i] $id]
            if {$j > -1} {
                return [list $i $j]
            }
        }
    }
    return {}
}

proc dimWin {{id {}} {x "d.nil"} {y "d.nil"} {parent {}}} {
    set d [::dinah::Dim #auto]
    focus [$d mkWindow $parent]
    $d setX $x; $d setY $y
    $d updateEntries
    $d buildBoard $id
    $d mkGrid
    return $d
}

proc newToplevel {pathname} {
    set t [toplevel $pathname] 
    lappend ::dinah::toplevels $t
    return $t
}

proc destroyToplevel {t} {
    variable ::dinah::toplevels
    set ::dinah::toplevels [lsearch -all -inline -not -exact $::dinah::toplevels $t]
    destroy $t
}

proc switchFocus+ {} {
    variable ::dinah::toplevels
    set ::dinah::toplevels [concat [lindex $::dinah::toplevels end] [lrange $::dinah::toplevels 0 end-1]]
    raise [lindex $::dinah::toplevels end]
    focus [lindex $::dinah::toplevels end]
}

proc switchFocus- {} {
    variable ::dinah::toplevels
    set ::dinah::toplevels [concat [lrange $::dinah::toplevels 1 end] [lindex $::dinah::toplevels 0]]
    raise [lindex $::dinah::toplevels end]
    focus [lindex $::dinah::toplevels end]
}

proc load_conf {} {
    variable ::dinah::db
    if {[file exists dinah.conf]} {
        set fd [open dinah.conf "r"]
        while {[gets $fd line] >= 0} {
            eval $line       
        }
        close $fd
    } else {
        exit
    }
}

proc newDim? {dim} {
    variable ::dinah::db
    if {![info exists db($dim)] && [regexp {^d\..*} $dim]} {
        lappend db(dimensions) $dim
        set db($dim) {}
    }
    if {[regexp {^q\.(.*)} $dim -> match]} {
        set terms [split $match]
        if {![info exists db($dim)]} {
            lappend db(dimensions) $dim
        }
        set db($dim) [list [::dinah::keywords $terms]]
    }
}

proc keywords {qs} {
    set r "all"
    foreach q $qs { set r [::dinah::keyword $q $r] }
    return $r
}

proc keyword {q {ids all}} {
    variable ::dinah::db
    set id ""
    set r {}
    foreach s {label txt} {
        if {$ids eq "all"} {
            foreach {k v} [array get ::dinah::db *,$s] {
                if {[string match -nocase *$q* $v]} {
                    regexp {(.*),.*} $k -> id
                    if {$id ni $r} {
                        lappend r $id
                    }
                }
            }

        } else {
            foreach id $ids {
                set v [array get ::dinah::db $id,$s]    
                if {[string match -nocase *$q* $v]} {
                    if {$id ni $r} {
                        lappend r $id
                    }
                }
            }
        }
    }
    set r [lsort -dictionary $r]
    return $r
}

proc init {} {
    variable ::dinah::db
    set ::dinah::toplevels {}
    ::dinah::initMouseBindings
    ::dinah::specific_init_preamble
    foreach s $db($::dinah::dimInit) {
        foreach f $s {
            if {$db($f,isa) eq "Txt"} {
                set t [Txt #auto $f]
                $t interpretBuffer
                $t destructor
            }
        }
    }
    foreach x  {0 1 2 3 4 5 6 7 8 9} {
        if {! [info exists db(board$x,A)]} {
            foreach y {A B C D E F G H I J K L M N O P Q R S T U V W X Y Z} {
                set db(board$x,$y) {}
            }
        }
    }
    catch {::dinah::load_conf}
    ::dinah::specific_init_postamble
}

proc subDim {d ds} {
    variable ::dinah::db
    ::dinah::newDim? $d
    set ::dinah::db($d) {}
    set X {}
    foreach dimName $ds {
        if {[info exists db($dimName)]} {
            lappend X $db($dimName)
        } else {
            error "common.tcl: $dimName dimension doesn't exist"
        }
    }
    set r [::dinah::agreg::run $db($d) $X]
    set db($d) [lindex $r end]
    if {![lindex $r 0]} {
        set pbDimName [lindex $ds [lindex $r 2]]
        tk_messageBox -message "Given the following configuration, $pbDimName cannot be a subdim of $d anymore."
        dimWin [lindex $r 1] $d $pbDimName 
    }
}

proc emptyNode {type {label ""}} {
    if {$type eq "Txt"} {
        return [::dinah::db'new [list isa Txt txt {} label $label]]
    }
    if {$type eq "Date"} {
        return [::dinah::db'new [list isa Date day "" month "" year "" hour "" minute "" certain 0 label $label]]
    }
    if {$type eq "Struct"} {
        return [::dinah::db'new [list isa Struct label $label]]
    }
    if {$type eq "Link"} {
        return [::dinah::db'new [list isa Link label $label]]
    }
}

proc desactivateMouse {w} {
    foreach i {1 2 3} {
        set ::dinah::mouse($w,$i) [bind $w <$i>]
        bind $w <$i> {break}
    }
}

proc activateMouse {w} {
    foreach i {1 2 3} {bind $w <$i> $::dinah::mouse($w,$i)}
}

proc addToTxtMenu {name args} {
    array unset ::dinah::txtClick $name,*
    foreach {key value} $args {
        if {[info exists ::dinah::db($key)]} {
            set id ""
            foreach s $::dinah::db($key) {
                foreach f $s {
                    if {$::dinah::db($f,label) eq $value} {
                        set id $f
                        break
                    }
                }
                if {$id ne ""} {break}
            }
            lappend ::dinah::txtClick($name,dim) $key $id
        } elseif {$key in {-background -foreground -overstrike -underline -font -offset}} {
            lappend ::dinah::txtClick($name,option) $key $value 
        }
    }
}

proc randomColor {} {format #%06x [expr {int(rand() * 0xFFFFFF)}]}

proc copy {srcId direction trgDim trgId} {
    if {! [::dinah::editable $trgDim]} {return 0}
    set found [::dinah::findInDim $trgDim $trgId]
    if {$found != {}} {
        set si [lindex $found 0]; set fi [lindex $found 1]
        set found [::dinah::findInDim $trgDim $srcId]
        if {$found == {}} {
            if {$direction eq "after"} { incr fi }
            lset ::dinah::db($trgDim) $si [linsert [lindex $::dinah::db($trgDim) $si] $fi $srcId]
            return 1
        }
        return 0
    } else {
        set found [::dinah::findInDim $trgDim $srcId]
        if {$found == {}} {
            if {$direction eq "after"} {
                lappend ::dinah::db($trgDim) [list $trgId $srcId]
            } else {
                lappend ::dinah::db($trgDim) [list $srcId $trgId]
            }
            return 1
        }
    }
}

proc move {srcDim srcId direction trgDim trgId} {
    if {! [::dinah::editable $srcDim]} {return 0}
    if {$srcDim eq $trgDim} {
        puts "ok"
        ::dinah::remfrag $srcDim $srcId
        puts [::dinah::copy $srcId $direction $trgDim $trgId]
    } elseif {[::dinah::copy $srcId $direction $trgDim $trgId ]} {
        ::dinah::remfrag $srcDim $srcId
    }
}

proc remfrag {d f} {
    if {! [::dinah::editable $d]} {return 0}
    set found [::dinah::findInDim $d $f]
    if {$found != {}} {
        set si [lindex $found 0]; set fi [lindex $found 1]
        set newS [lreplace [lindex $::dinah::db($d) $si] $fi $fi]
        if {[llength $newS] == 0} {
            set ::dinah::db($d) [lreplace $::dinah::db($d) $si $si]
        } else {
            lset ::dinah::db($d) $si $newS
        }
    }
}

proc getSegIndex {d dbid} {
    set found [::dinah::findInDim $d $dbid]
    if {$found != {}} {
        return [lindex $found 0]
    } else {
        return ""
    }
}

proc remSeg {d segIndex} {
    set ::dinah::db($d) [lreplace $::dinah::db($d) $segIndex $segIndex]
}

proc order {dimIndex dimLinear newDim} {
    if  { (! [info exists ::dinah::db($dimIndex)]) || (! [info exists ::dinah::db($dimLinear)]) || \
          (! [::dinah::editable $newDim]) } {
        return 0
    }
    ::dinah::newDim? $newDim
    set ::dinah::db($newDim) {}
    foreach s $::dinah::db($dimLinear) {
        set newS {}
        foreach f $s {
            set found [findInDim $dimIndex $f]
            if {$found != {}} {
                set segIndex [lindex $found 0]
                set fragIndex [lindex $found 1]
                set id ""
                if {$fragIndex == 0} { set id [lindex $::dinah::db($dimIndex) $segIndex 1] }
                if {$fragIndex == 1} { set id [lindex $::dinah::db($dimIndex) $segIndex 0] }
                if { ($id ne "") && ($id ni $newS) && ([::dinah::findInDim $newDim $id] == {}) } {
                    lappend newS $id
                } else {
                    tk_messageBox -message "The following fragment is indexed twice by $dimIndex."
                    set ::dinah::db($newDim) {}
                    dimWin $id $dimLinear $dimIndex 
                    return 0
                }
            }
        }
        lappend ::dinah::db($newDim) $newS
    }
}

proc initMouseBindings {} {
    if {[tk windowingsystem] eq "aqua"} {
        set ::dinah::mouse(B3) "<Control-1>"
        set ::dinah::mouse(Shift-B3) "<Shift-Control-1>"
    } else {
        set ::dinah::mouse(B3) "<3>"
        set ::dinah::mouse(Shift-B3) "<Shift-3>"
    }
}

