source commonDB.tcl

set writePermission 1
set dimClone "d.clone"
set dimClipboard "d.clipboard"
set dimNil "d.nil"
set dbFile "/tmp/db.dinah"
array set db {}
set db(lastid) 0
set db(dimensions) [list $::dinah::dimNil "d.readonly"]
set db(d.nil) {}
set db(d.readonly) {{2}}

proc editable {dimName} {
    return [expr {($dimName ni [list "" $::dinah::dimNil "d.readonly"]) && \
        ($dimName in [dbGetDimensions])}]
}

