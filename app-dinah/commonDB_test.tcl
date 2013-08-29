package require Itcl

namespace eval ::dinah {
    ########
    # INIT #
    ########

    set writePermission 1
    set dimClone "d.clone"
    set dimClipboard "d.clipboard"
    set dbFile "/tmp/db.dinah"
    array set db {}
    set db(lastid) 0
    set db(dimensions) {}
}
