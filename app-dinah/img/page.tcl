itcl::class Page {
    inherit Img

    private common resolution "_low"

    constructor {pageid} {
	Img::constructor $pageid 
    } {
    }

    method path {} {
	variable ::dinah::db
        return $db(base)[::dinah::db'get $dbid path]$resolution$db(imgExtension)
    }

    proc high {} {
        set resolution "_high"
    }
    proc low {} {
        set resolution "_low"
    }
}
