itcl::class Date {
    inherit Obj

    private variable min
    private variable h
    private variable d
    private variable m
    private variable y
    private variable certain

    constructor {id} { set dbid $id }

    destructor {}

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
    $d delete 0 end
    $d insert 0 [::dinah::dbGet $dbid,day]
    $m delete 0 end
    $m insert 0 [::dinah::dbGet $dbid,month]
    $y delete 0 end
    $y insert 0 [::dinah::dbGet $dbid,year]
    $h delete 0 end
    $h insert 0 [::dinah::dbGet $dbid,hour]
    $min delete 0 end
    $min insert 0 [::dinah::dbGet $dbid,minute]
    $certain configure -variable ::dinah::db($dbid,certain)
    if {[::dinah::dbGet $dbid,certain]} {$certain select} else {$certain deselect}
}

itcl::body Date::save {} {
    set valid [valid? [$y get] [$m get] [$d get] [$h get] [$min get]]
    set color "white"
    if {[::dinah::dbGet $dbid,certain]} {
        if {! $valid} { set color "red" }
    }
    foreach e [list $d $m $y $h $min] {$e configure -bg $color}
    if {! [::dinah::dbGet $dbid,certain] || $valid} {
        ::dinah::dbSet $dbid,day [$d get]
        ::dinah::dbSet $dbid,month [$m get]
        ::dinah::dbSet $dbid,year [$y get]
        ::dinah::dbSet $dbid,hour [$h get]
        ::dinah::dbSet $dbid,minute [$min get]
        if {$valid} {
            ::dinah::dbSet $dbid,seconds [clock scan [::dinah::dbGet $dbid,day]/[::dinah::dbGet $dbid,month]/[::dinah::dbGet $dbid,year]/[::dinah::dbGet $dbid,hour]/[::dinah::dbGet $dbid,minute] -format %d/%m/%Y/%k/%M]
        } elseif {[hour? [::dinah::dbGet $dbid,hour]] && [day? [::dinah::dbGet $dbid,year] [::dinah::dbGet $dbid,month] [::dinah::dbGet $dbid,day]] && [month? [::dinah::dbGet $dbid,month]] && [year? [::dinah::dbGet $dbid,year]]} {
            ::dinah::dbSet $dbid,seconds [clock scan [::dinah::dbGet $dbid,day]/[::dinah::dbGet $dbid,month]/[::dinah::dbGet $dbid,year]/[::dinah::dbGet $dbid,hour]/00 -format %d/%m/%Y/%k/%M]
        } elseif {[day? [::dinah::dbGet $dbid,year] [::dinah::dbGet $dbid,month] [::dinah::dbGet $dbid,day]] && [month? [::dinah::dbGet $dbid,month]] && [year? [::dinah::dbGet $dbid,year]]} {
            ::dinah::dbSet $dbid,seconds [clock scan [::dinah::dbGet $dbid,day]/[::dinah::dbGet $dbid,month]/[::dinah::dbGet $dbid,year]/00/00 -format %d/%m/%Y/%k/%M]
        } elseif {[month? [::dinah::dbGet $dbid,month]] && [year? [::dinah::dbGet $dbid,year]]} {
            ::dinah::dbSet $dbid,seconds [clock scan 01/[::dinah::dbGet $dbid,month]/[::dinah::dbGet $dbid,year]/00/00 -format %d/%m/%Y/%k/%M]
        } elseif {[year? [::dinah::dbGet $dbid,year]]} {
            ::dinah::dbSet $dbid,seconds [clock scan 01/01/[::dinah::dbGet $dbid,year]/00/00 -format %d/%m/%Y/%k/%M]
        }
        if {[::dinah::dbExists $dbid,seconds]} {
            set dates {}
            foreach dateId [::dinah::dbLGet $::dinah::dimChrono 0] {
                if {$dateId != $dbid} {
                    lappend dates [list $dateId [::dinah::dbGet $dateId,seconds]] 
                }
            }
            lappend dates [list $dbid [::dinah::dbGet $dbid,seconds]]
            set chronology {}
            foreach pair [lsort -real -index 1 $dates] {
                lappend chronology [lindex $pair 0]
            }
            ::dinah::dbSet $::dinah::dimChrono [list $chronology]
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
