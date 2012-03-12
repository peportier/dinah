set src "K:/nouvelles_images_desanti/jpeg/"

proc dir {name} {
    global src
    puts $name
    foreach i [glob -nocomplain -directory $name *.jpeg] {
        if {! [string match *low* $i]} {
            file rename $i [regsub {\.jpeg$} $i "_high.jpeg"]
        }
    }
    foreach subdir [lsort -dictionary [glob -nocomplain -directory $name -type d \[0-9_\]*]] {
        dir $subdir
    }
}

dir $src
