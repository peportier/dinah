namespace eval ::dinah {
    proc db'save {fn} {
        variable db
        if {$::dinah::writePermission} {
            set fp [open $fn w]
            puts $fp [list array set db [array get db]]
            close $fp
        }
    }

    proc db'fields {} {
        variable db
        foreach i [array names db *,*] {
            set tmp([lindex [split $i ,] 1]) ""
        }
        lsort [array names tmp]
    }

    proc db'newIntervalId {} {
        variable db
        set id [incr db(lastIntervalId)]
        return $id
    }

    proc db'newEdge {s p o} {
        variable db
        db'new [list "isa" "edge" "$s->$p->$o" ""]
    }

    proc db'new {o} {
        variable db
        set id [incr db(lastid)]
        db'set $id $o
        return $id
    }

    proc db'set {id o} {
        variable db
        foreach {k v} $o {
            set db($id,$k) $v
        }
    }

    proc db'get {id k} {
        variable db
        if {[info exists db($id,$k)]} {
            return $db($id,$k)
        } else {return ""}
    }

    proc db'getall {id} {
        variable db
        array get db $id,*
    }

    proc db'filter {i k v} {
        variable db
        set id [lindex [split $i ,] 0]
        if {([regexp $k $i] && [regexp $v $db($i)]) ||
            ($k eq "id:$id")} {
            return $id
        }
        return {}
    }

    proc db'find {k v {ids all}} {
        variable db
        set res {}
        if {[string equal $ids "all"]} {
            foreach i [array names db *,*] {
                set res [concat $res [db'filter $i $k $v]]
            }
        } else {
            foreach id $ids {
                foreach i [array names db $id,*] {
                    set res [concat $res [db'filter $i $k $v]]
                }
            }
        }
        lsort -unique $res
    }

    proc db'or {pairs} {
        variable db
        set res {}
        foreach {k v} $pairs {
            set res [concat $res [db'find $k $v]]
        }
        lsort -unique $res
    }

    proc db'and {pairs} {
        variable db
        set res "all"
        foreach {k v} $pairs {
            set res [db'find $k $v $res]
            if {$res == {}} { break }
        }
        lsort -unique $res
    }
}
