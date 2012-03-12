set in "C:/Users/peportier/Desktop/text.csv"
set out "C:/Users/peportier/Desktop/text.html"

proc urltoutf8 {text} {
   return [encoding convertfrom utf-8 [subst [regsub -all {%} $text "\\u00"]]]
}

set fdin [open $in "r"]
set fdout [open $out "w"]

set i 0
while {[gets $fdin line] >= 0} {
    incr i
    set fields [split $line ,]
    puts -nonewline $fdout "<h1>$i- DEBUT DU FRAGMENT: " 
    puts -nonewline $fdout [lindex $fields 0] 
    puts $fdout "</h1>"
    puts $fdout [urltoutf8 [lindex $fields 1]] 
    puts $fdout "<br /><br />"
}

close $fdin
close $fdout
