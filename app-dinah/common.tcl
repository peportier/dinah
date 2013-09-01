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

proc dimWin {{id {}} {x "d.nil"} {y "d.nil"} {parent {}}} {
    set d [::dinah::Dim #auto]
    focus [$d mkWindow $parent]
    $d setX $x; $d setY $y
    $d updateEntries
    $d buildAndGrid $id
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
    ::dinah::dbNewDim $d
    ::dinah::dbSetDim $d {}
    set X {}
    foreach dimName $ds {
        if {[::dinah::dbExists $dimName]} {
            lappend X [::dinah::dbGet $dimName]
        } else {
            ::dinah::dbNewDim $dimName
            #error "common.tcl: $dimName dimension doesn't exist"
        }
    }
    set r [::dinah::agreg::run [::dinah::dbGet $d] $X]
    ::dinah::dbSetDim $d [lindex $r end]
    if {![lindex $r 0]} {
        set pbDimName [lindex $ds [lindex $r 2]]
        tk_messageBox -message "Given the following configuration, $pbDimName cannot be a subdim of $d anymore."
        dimWin [lindex $r 1] $d $pbDimName
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
        if {$key in {-background -foreground -overstrike -underline -font -offset}} {
            lappend ::dinah::txtClick($name,option) $key $value 
        }
    }
}

proc randomColor {} {format #%06x [expr {int(rand() * 0xFFFFFF)}]}

proc order {dimIndex dimLinear newDim} {
    if  { (! [::dinah::dbExists $dimIndex]) || (! [::dinah::dbExists $dimLinear]) || \
          (! [::dinah::editable $newDim]) } {
        return 0
    }
    ::dinah::dbNewDim $newDim
    ::dinah::dbSetDim $newDim {}
    foreach s [::dinah::dbGet $dimLinear] {
        set newS {}
        foreach f $s {
            set found [dbFindInDim $dimIndex $f]
            if {$found != {}} {
                set segIndex [lindex $found 0]
                set fragIndex [lindex $found 1]
                set id ""
                if {$fragIndex == 0} { set id [::dinah::dbGetFragment $dimIndex $segIndex 1] }
                if {$fragIndex == 1} { set id [::dinah::dbGetFragment $dimIndex $segIndex 0] }
                if { ($id ne "") && ($id ni $newS) && (![::dinah::dbFragmentBelongsToDim $newDim $id]) } {
                    lappend newS $id
                } else {
                    tk_messageBox -message "The following fragment is indexed twice by $dimIndex."
                    ::dinah::dbSetDim $newDim {}
                    dimWin $id $dimLinear $dimIndex 
                    return 0
                }
            }
        }
        ::dinah::dbAppendSegmentToDim $newDim $newS
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
    #foreach txt [itcl::find object * -class ::dinah::Txt] {
    #    $txt save
    #}
    ::dinah::dbSave
}

proc backup {} {
    ::dinah::dbSaveTo backup/[clock format [clock seconds] -format %y_%m_%d_%H_%M_%S]
}

proc every {t body} {
    uplevel #0 $body
    after $t [list ::dinah::every $t $body]
}

proc newTree {rootName} {
    set rootId [::dinah::dbNewEmptyFragment Txt $rootName]
    ::dinah::dbSetAttribute $rootId txt "text {$rootName\n} 1.0"
    ::dinah::dbAppendSegmentToDim $::dinah::dim0 [list $rootId]
    ::dinah::dbAppendSegmentToDim $::dinah::roots $rootId
    ::dinah::dbNewDim [::dinah::treeDimName $rootId]
    return $rootId
}

proc treeDimName {rootId} { return "d.t.$rootId" }

proc imageFilepaths {dbid} {
    set r {}
    if {!( [::dinah::dbGet $dbid,isa] eq "Page" )} { return {} }
    foreach suffix $::dinah::resolutions_suffix {
        lappend r [::dinah::dbGet base][::dinah::dbGet $dbid,path]$suffix[::dinah::dbGet imgExtension]
    }
    return r
}

proc removeEmptyFromList {list} {
    return [lsearch -not -exact -all -inline $list {}]
}
