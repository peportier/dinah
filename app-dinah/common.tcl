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
set ::dinah::writePermission 1

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
    if {! [::dinah::editable $key]} {
        return 0
    } else {
        set ::dinah::db($key) $value
        return 1
    }
}

proc dbGet {key} {
    return $::dinah::db($key)
}

proc dbExists {key} {
    info exists ::dinah::db($key)
}

proc dbLSet {key index elem} {
    if {! [::dinah::editable $key]} {
        return 0
    } else {
        lset ::dinah::db($key) $index $elem
        return 1
    }
}

proc dbLGet {key index} {
    lindex $::dinah::db($key) $index
}

proc dbAppend {key value} {
    if {! [::dinah::editable $key]} {
        return 0
    } else {
        lappend ::dinah::db($key) $value
        return 1
    }
}

proc dbAGet {pattern} {
    array get ::dinah::db $pattern
}

if {![::dinah::dbExists "notAlone"]} {
    ::dinah::dbSet "notAlone" 0
}

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
    set o [eval {::dinah::[::dinah::dbGet $id,isa] #auto $id}]
    $o mkWindow $parentW
    return ::dinah::$o
}

proc findInDim {dim id} {
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

proc setBase {path} {
    if {[file isdirectory $path]} {
        ::dinah::dbSet "base" $path
    }
}

proc setConvert {path} {
    if {[file exists $path]} {
        set ::dinah::zonemaker::convert $path
    }
}

proc newDim? {dim} {
    if {![::dinah::dbExists $dim] && [regexp {^d\..*} $dim]} {
        ::dinah::dbAppend "dimensions" $dim
        ::dinah::dbSet $dim {}
    }
    if {[regexp {^q\.(.*)} $dim -> match]} {
        set terms [split $match]
        if {![::dinah::dbExists $dim]} {
            ::dinah::dbAppend dimensions $dim
        }
        ::dinah::dbSet $dim [list [::dinah::keywords $terms]]
    }
}

proc keywords {qs} {
    set r "all"
    foreach q $qs { set r [::dinah::keyword $q $r] }
    return $r
}

proc keyword {q {ids all}} {
    set id ""
    set r {}
    foreach s {label txt} {
        if {$ids eq "all"} {
            foreach {k v} [::dinah::dbAGet *,$s] {
                if {[string match -nocase *$q* $v]} {
                    regexp {(.*),.*} $k -> id
                    if {$id ni $r} {
                        lappend r $id
                    }
                }
            }

        } else {
            foreach id $ids {
                set v [::dinah::dbAGet $id,$s]
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

proc userConnect {} {
    if {[::dinah::dbGet "notAlone"]} {
        set ::dinah::writePermission 0
        tk_messageBox -message "Mode lecture seule..."
    } else {
        set ::dinah::writePermission 1
        ::dinah::dbSet "notAlone" 1
        ::dinah::dbSave
    }
}

proc userDisconnect {} {
    ::dinah::dbSet "notAlone" 0
}

proc init {} {
    set ::dinah::toplevels {}
    ::dinah::userConnect
    ::dinah::initMouseBindings
    ::dinah::specific_init_preamble
    foreach s [::dinah::dbGet $::dinah::dimInit] {
        foreach f $s {
            if {[::dinah::dbGet $f,isa] eq "Txt"} {
                set t [Txt #auto $f]
                $t interpretBuffer
                itcl::delete object $t
            }
        }
    }
    foreach x  {0 1 2 3 4 5 6 7 8 9} {
        if {! [::dinah::dbExists board$x,A] } {
            foreach y {A B C D E F G H I J K L M N O P Q R S T U V W X Y Z} {
                ::dinah::dbSet board$x,$y {}
            }
        }
    }
    catch {::dinah::load_conf}
    ::dinah::specific_init_postamble
}

proc subDim {d ds} {
    ::dinah::newDim? $d
    ::dinah::dbSet $d {}
    set X {}
    foreach dimName $ds {
        if {[::dinah::dbExists $dimName]} {
            lappend X [::dinah::dbGet $dimName]
        } else {
            ::dinah::newDim? $dimName
            #error "common.tcl: $dimName dimension doesn't exist"
        }
    }
    set r [::dinah::agreg::run [::dinah::dbGet $d] $X]
    ::dinah::dbSet $d [lindex $r end]
    if {![lindex $r 0]} {
        set pbDimName [lindex $ds [lindex $r 2]]
        tk_messageBox -message "Given the following configuration, $pbDimName cannot be a subdim of $d anymore."
        dimWin [lindex $r 1] $d $pbDimName
    }
}

proc emptyNode {type {label ""}} {
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
        if {[::dinah::dbExists $key]} {
            set id ""
            foreach s [::dinah::dbGet $key] {
                foreach f $s {
                    if {[::dinah::dbGet $f,label] eq $value} {
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
            ::dinah::dbLSet $trgDim $si [linsert [::dinah::dbLGet $trgDim $si] $fi $srcId]
            return 1
        }
        return 0
    } else {
        set found [::dinah::findInDim $trgDim $srcId]
        if {$found == {}} {
            if {$direction eq "after"} {
                ::dinah::dbAppend $trgDim [list $trgId $srcId]
            } else {
                ::dinah::dbAppend $trgDim [list $srcId $trgId]
            }
            return 1
        } else {
            set si [lindex $found 0]; set fi [lindex $found 1]
            set segment [::dinah::dbLGet $trgDim $si]
            if {$direction eq "before"} {
                set newFragmentIndex [expr {$fi + 1}]
            } else {
                set newFragmentIndex $fi
            }
            set newSegment [linsert $segment $newFragmentIndex $trgId]
            ::dinah::dbLSet $trgDim $si $newSegment
            return 1
        }
    }
}

proc clone {id} {
    set attributes {}
    foreach {k v} [::dinah::dbAGet $id,*] {
        regexp {^.*,(.*)} $k -> attName
        lappend attributes $attName $v
    }
    set clone [::dinah::dbNew $attributes]
    set found [::dinah::findInDim $::dinah::dimClone $id]
    if {$found != {}} {
        set si [lindex $found 0]
        ::dinah::dbLSet $::dinah::dimClone $si [linsert [::dinah::dbLGet $::dinah::dimClone $si] end $clone]
    } else {
        ::dinah::dbAppend $::dinah::dimClone [list $id $clone]
    }
}

proc move {srcDim srcId direction trgDim trgId} {
    if {! [::dinah::editable $srcDim]} {return 0}
    if {$srcDim eq $trgDim} {
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
        set newS [lreplace [::dinah::dbLGet $d $si] $fi $fi]
        if {[llength $newS] == 0} {
            ::dinah::dbSet $d [lreplace [::dinah::dbGet $d] $si $si]
        } else {
            ::dinah::dbLSet $d $si $newS
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
    ::dinah::dbSet $d [lreplace [::dinah::dbGet $d] $segIndex $segIndex]
}

proc order {dimIndex dimLinear newDim} {
    if  { (! [::dinah::dbExists $dimIndex]) || (! [::dinah::dbExists $dimLinear]) || \
          (! [::dinah::editable $newDim]) } {
        return 0
    }
    ::dinah::newDim? $newDim
    ::dinah::dbSet $newDim {}
    foreach s [::dinah::dbGet $dimLinear] {
        set newS {}
        foreach f $s {
            set found [findInDim $dimIndex $f]
            if {$found != {}} {
                set segIndex [lindex $found 0]
                set fragIndex [lindex $found 1]
                set id ""
                if {$fragIndex == 0} { set id [::dinah::dbLGet $dimIndex [list $segIndex 1]] }
                if {$fragIndex == 1} { set id [::dinah::dbLGet $dimIndex [list $segIndex 0]] }
                if { ($id ne "") && ($id ni $newS) && ([::dinah::findInDim $newDim $id] == {}) } {
                    lappend newS $id
                } else {
                    tk_messageBox -message "The following fragment is indexed twice by $dimIndex."
                    ::dinah::dbSet $newDim {}
                    dimWin $id $dimLinear $dimIndex 
                    return 0
                }
            }
        }
        ::dinah::dbAppend $newDim $newS
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

proc autosave {} {
    foreach txt [itcl::find object * -class ::dinah::Txt] {
        $txt save
    }
    ::dinah::dbSave
}

proc backup {} {
    ::dinah::dbSaveTo backup/[clock format [clock seconds] -format %y_%m_%d_%H_%M_%S]
}

proc every {t body} {
    uplevel #0 $body
    after $t [list ::dinah::every $t $body]
}
