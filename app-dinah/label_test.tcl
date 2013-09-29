package require Tk
package require BWidget
package require Itcl

namespace eval ::dinah {

    ########
    # INIT #
    ########
    source label_test_preamble.tcl

    #########
    # TESTS #
    #########

    set label1Id [dbNewEmptyFragment Label label1]
    set label1 [Label #auto $label1Id]
    $label1 mkWindow
    $label1 setMenuColor yellow
    $label1 closeEW
    $label1 notificate "a message, "
    $label1 notificate "another one"
}
