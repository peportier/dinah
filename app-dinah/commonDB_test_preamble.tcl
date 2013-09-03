source commonDB.tcl
set writePermission 1
set dimClone "d.clone"
set dimClipboard "d.clipboard"
set dbFile "/tmp/db.dinah"
array set db {}
set db(lastid) 0
set db(dimensions) {"d.nil"}

proc editable {dimName} {
    return [expr {($dimName ni {"" "d.nil"}) && \
        ($dimName in [dbGetDimensions])}]
}
