itcl::class Date {
    inherit Obj

    private variable min
    private variable h
    private variable d
    private variable m
    private variable y
    private variable certain

    constructor {id} { set dbid $id }

    destructor {
        destroy $frame
        destroy $standalone
    }

    private method valid? {y m d h min}
    private method hour? {h}
    private method minute? {min}
    private method year? {y}
    private method month? {m}
    private method day? {y m d}
    private method days {y m}
    private method otherdays {m}
    private method leapdays {y}
    private method leap? {y}

    private method load {} {}

    public method save {}
    public method specificLayout {}
    public method afterLayout {}
}

itcl::body Date::specificLayout {} {
    set main [frame $center.main]
    set d [entry $main.day -width 2]
    set m [entry $main.month -width 2]
    set y [entry $main.year -width 4]
    set h [entry $main.hour -width 2]
    set min [entry $main.min -width 2]
    set certain [checkbutton $main.certain -text "certaine"]
    pack $main.day -side left -padx 4 -pady 4
    pack $main.month -side left -padx 4 -pady 4
    pack $main.year -side left -padx 4 -pady 4
    pack $main.hour -side left -padx 4 -pady 4
    pack $main.min -side left -padx 4 -pady 4
    pack $main.certain -side left -padx 4 -pady 4
}

itcl::body Date::afterLayout {} {
    load
}

itcl::body Date::load {} {
    variable ::dinah::db
    $d delete 0 end
    $d insert 0 $db($dbid,day)
    $m delete 0 end
    $m insert 0 $db($dbid,month)
    $y delete 0 end
    $y insert 0 $db($dbid,year)
    $h delete 0 end
    $h insert 0 $db($dbid,hour)
    $min delete 0 end
    $min insert 0 $db($dbid,minute)
    $certain configure -variable ::dinah::db($dbid,certain)
    if {$db($dbid,certain)} {$certain select} else {$certain deselect}
}

itcl::body Date::save {} {
    variable ::dinah::db
    set valid [valid? [$y get] [$m get] [$d get] [$h get] [$min get]]
    set color "white"
    if {$db($dbid,certain)} {
        if {! $valid} { set color "red" }
    }
    foreach e [list $d $m $y $h $min] {$e configure -bg $color}
    if {! $db($dbid,certain) || $valid} {
        set db($dbid,day) [$d get]
        set db($dbid,month) [$m get]
        set db($dbid,year) [$y get]
        set db($dbid,hour) [$h get]
        set db($dbid,minute) [$min get]
        if {$valid} {
            set db($dbid,seconds) [clock scan $db($dbid,day)/$db($dbid,month)/$db($dbid,year)/$db($dbid,hour)/$db($dbid,minute) -format %d/%m/%Y/%k/%M]
        } elseif {[hour? $db($dbid,hour)] && [day? $db($dbid,year) $db($dbid,month) $db($dbid,day)] && [month? $db($dbid,month)] && [year? $db($dbid,year)]} {
            set db($dbid,seconds) [clock scan $db($dbid,day)/$db($dbid,month)/$db($dbid,year)/$db($dbid,hour)/00 -format %d/%m/%Y/%k/%M]
        } elseif {[day? $db($dbid,year) $db($dbid,month) $db($dbid,day)] && [month? $db($dbid,month)] && [year? $db($dbid,year)]} {
            set db($dbid,seconds) [clock scan $db($dbid,day)/$db($dbid,month)/$db($dbid,year)/00/00 -format %d/%m/%Y/%k/%M]
        } elseif {[month? $db($dbid,month)] && [year? $db($dbid,year)]} {
            set db($dbid,seconds) [clock scan 01/$db($dbid,month)/$db($dbid,year)/00/00 -format %d/%m/%Y/%k/%M]
        } elseif {[year? $db($dbid,year)]} {
            set db($dbid,seconds) [clock scan 01/01/$db($dbid,year)/00/00 -format %d/%m/%Y/%k/%M]
        }
        if {[info exists db($dbid,seconds)]} {
            set dates {}
            foreach dateId [lindex $db(d.chrono) 0] {
                if {$dateId != $dbid} {
                    lappend dates [list $dateId $db($dateId,seconds)] 
                }
            }
            lappend dates [list $dbid $db($dbid,seconds)]
            set chronology {}
            foreach pair [lsort -real -index 1 $dates] {
                lappend chronology [lindex $pair 0]
            }
            set db(d.chrono) [list $chronology]
        }
    } 
}

itcl::body Date::valid? {y m d h min} {expr {[year? $y] && [month? $m] && [day? $y $m $d] && [hour? $h] && [minute? $min]}}

itcl::body Date::hour? {h} {expr {0<=$h && $h<=23}}

itcl::body Date::minute? {min} {expr {0<=$min && $min<=59}}

itcl::body Date::year? {y} {expr {1700<=$y && $y<=2050}}

itcl::body Date::month? {m} {expr {1<=$m && $m<=12}}

itcl::body Date::day? {y m d} {expr {1<=$d && $d<=[days $y $m]}}

itcl::body Date::days {y m} {if {$m==2} {leapdays $y} else {otherdays $m}}

itcl::body Date::otherdays {m} {expr {$m in {4 6 9 11} ? 30 : 31}}

itcl::body Date::leapdays {y} {expr {[leap? $y] ? 29 : 28}}

itcl::body Date::leap? {y} {expr {($y%4==0 && $y%100!=0) || $y%400==0}}
