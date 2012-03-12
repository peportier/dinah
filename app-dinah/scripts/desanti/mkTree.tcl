package require Tk
package require Itcl

namespace eval ::dinah {

    set dbFile "../data/db"
    source -encoding utf-8 $dbFile
    source ../db/db.tcl
    source ../common.tcl
    #init_seashell
    init_portable_windows
    #init_home
    source ../canvas/canvas.tcl
    source ../autocomplete/autocomplete.tcl
    source ../img/img.tcl
    source ../img/page.tcl
    source ../img/zone.tcl
    source ../txt/txt.tcl
    source ../date/date.tcl

    set src $db(base)collections/
    
    set archiveId [::dinah::db'new {isa Txt txt {text ARCHIVE 1.0} label ARCHIVE}]
    set inserts [list $archiveId]

    proc dir {name} {
        variable ::dinah::db
        variable ::dinah::inserts
        puts $name
        set archive {}
        regexp {^.*(collections.*)$} $name -> colName
        #set colId [::dinah::db'new [list isa Txt txt [list text $colName 1.0] label $colName]]
        #lappend archive $colId
        foreach i [glob -nocomplain -directory $name *_high.jpeg] {
            regexp {^.*(collections.*)_high.*$} $i -> path
            set pageId [::dinah::db'new [list isa Page path $path label ""]]
            lappend archive $pageId
        }
        set colId [lindex $archive 0]
        set db($colId,label) $colName
        lappend db(d.archive) $archive
        set firstSibling 1
        set sameLevel {}
        foreach subdir [lsort -dictionary -decreasing [glob -nocomplain -directory $name -type d \[0-9_\]*]] {
            if {! $firstSibling} {
                if {[llength $inserts] > 1} { lappend db(d.insert) $inserts }
                set inserts {}  
            }
            set siblingId [dir $subdir]
            set inserts [linsert $inserts 0 $siblingId]
            set sameLevel [linsert $sameLevel 0 $siblingId]
            #lappend sameLevel $siblingId
            set firstSibling 0
        }
        if {[llength $sameLevel] > 1} { lappend db(d.sameLevel) $sameLevel }
        return $colId
    }
    
    dir $src
    
    ::dinah::db'save $::dinah::dbFile

}
