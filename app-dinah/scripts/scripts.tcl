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

proc cleanImageNodesWithNoExistingAssociatedFile {} {
    foreach seg [::dinah::dbGet $::dinah::dimFragments] {
        foreach frag [lrange $seg 1 end] {
            set aFileExists 0
            set isaPage 0
            foreach filepath [::dinah::imageFilepaths $frag] {
                set isaPage 1
                set aFileExists [expr {$aFileExists || [file exists $filepath]}]
                if {$aFileExists} {break}
            }
            if {($isaPage) && (! $aFileExists)} {
                foreach {dim seg2 frag2} [::dinah::dimForId $frag] {
                    puts "$dim : $seg2 : $frag2"
                    ::dinah::remFragFromSeg $dim $frag2
                }
            }
        }
    }
}
