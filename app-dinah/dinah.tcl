package provide app-dinah 1.0

package require Tk
package require Img
package require Itcl
package require BWidget

namespace eval ::dinah {

    set dbFile "db.dinah"
    source -encoding utf-8 $dbFile
    #source $starkit::topdir/lib/app-dinah/db.tcl
    source $starkit::topdir/lib/app-dinah/algo_dim_agreg.tcl
    source $starkit::topdir/lib/app-dinah/zonemaker.tcl
    source $starkit::topdir/lib/app-dinah/common.tcl
    #source $starkit::topdir/lib/app-dinah/bouvard.tcl
    source $starkit::topdir/lib/app-dinah/desanti.tcl
    #load_conf
    source $starkit::topdir/lib/app-dinah/canvas.tcl
    source $starkit::topdir/lib/app-dinah/autocomplete.tcl
    source $starkit::topdir/lib/app-dinah/obj.tcl
    source $starkit::topdir/lib/app-dinah/page.tcl
    source $starkit::topdir/lib/app-dinah/txt.tcl
    source $starkit::topdir/lib/app-dinah/date.tcl
    source $starkit::topdir/lib/app-dinah/dim.tcl
    source $starkit::topdir/lib/app-dinah/edges.tcl
    source $starkit::topdir/lib/app-dinah/whiteboard.tcl
    source $starkit::topdir/lib/app-dinah/tree.tcl
    source $starkit::topdir/lib/app-dinah/debug.tcl
    #source $starkit::topdir/lib/app-dinah/struct.tcl
    source $starkit::topdir/lib/app-dinah/link.tcl
    source $starkit::topdir/lib/app-dinah/container.tcl
    source $starkit::topdir/lib/app-dinah/scripts/scripts.tcl

    bind . <F1> {catch {console show}}

    bind . <Destroy> {
        # Test if the toplevel (in this case ".")
        # received the event.
        if {"%W" == "."} {
            ::dinah::userDisconnect
            ::dinah::dbSave
        }
    }

    #console show
    ::dinah::init
}
