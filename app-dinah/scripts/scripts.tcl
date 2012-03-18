proc remove_img_frag {} {
    set i 0
    for {set i 0} {$i < [llength $::dinah::db($::dinah::dimFragments)]} {incr i} {
	set s [lindex $::dinah::db($::dinah::dimFragments) $i]
	if {$::dinah::db([lindex $s 0],isa) eq "Page"} {
	    puts "s: $s"
	    set ::dinah::db($::dinah::dimFragments) [lreplace $::dinah::db($::dinah::dimFragments) $i $i]
	}
    }
}

proc img_to_page {} {
    foreach {k v} [array get ::dinah::db *,isa] {
        if {$v eq "Img"} { set ::dinah::db($k) "Page" }
    }
}
