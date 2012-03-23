set ::dinah::dimAlternative "d.alternative"
set ::dinah::dimAttribute "d.attribute"
set ::dinah::dimArchive "d.archive"
set ::dinah::dimInsert "d.insert"
set ::dinah::dimSameLevel "d.sameLevel"
set ::dinah::dimNote "d.note"
set ::dinah::dimFragments "d.fragments"
set ::dinah::dimNoticeElement "d.noticeElement"
set ::dinah::dimNoticeLevel "d.noticeLevel"
set ::dinah::dimInit "d.init"
set ::dinah::dimNil "d.nil"
set ::dinah::dimClipboard "d.clipboard"
set ::dinah::dimChrono "d.chrono"
set ::dinah::dimInfo "d.info"
set ::dinah::separatorSize 5
set ::dinah::fragmentBorderWidth 2
set ::dinah::backgroundColor antiqueWhite
set ::dinah::closeColor blue
set ::dinah::openColor black
set ::dinah::font helvetica

set ::dinah::resolutions_suffix {"_low" "_high"}

proc specific_init_preamble {} {
    ::dinah::newDim? $::dinah::dimAlternative
    ::dinah::newDim? $::dinah::dimAttribute
    ::dinah::newDim? $::dinah::dimArchive
    ::dinah::newDim? $::dinah::dimInsert
    ::dinah::newDim? $::dinah::dimSameLevel
    ::dinah::newDim? $::dinah::dimNote
    ::dinah::newDim? $::dinah::dimFragments
    ::dinah::newDim? $::dinah::dimNoticeElement
    ::dinah::newDim? $::dinah::dimNoticeLevel
    ::dinah::newDim? $::dinah::dimInit
    ::dinah::newDim? $::dinah::dimNil
    ::dinah::newDim? $::dinah::dimClipboard
    ::dinah::newDim? $::dinah::dimChrono
    ::dinah::newDim? $::dinah::dimInfo
    ::dinah::addToTxtMenu "auteur" "-background" "orange" "-foreground" "black"
    ::dinah::addToTxtMenu "concept" "-background" "forest green" "-foreground" "black"
    ::dinah::addToTxtMenu "cb" "-background" "yellow" "-foreground" "black"
    ::dinah::addToTxtMenu "lb" "-background" "yellow" "-foreground" "black"
    ::dinah::addToTxtMenu "gap" "-background" "yellow" "-foreground" "black"
    ::dinah::addToTxtMenu "abbr" "-background" "green" "-foreground" "black"
    ::dinah::addToTxtMenu "sic" "-background" "green" "-foreground" "black"
    ::dinah::addToTxtMenu "orig" "-background" "green" "-foreground" "black"
    ::dinah::addToTxtMenu "add" "-background" "purple" "-foreground" "black"
    ::dinah::addToTxtMenu "date" "-background" "magenta" "-foreground" "black"
    ::dinah::addToTxtMenu "del" "-overstrike" "1"
    ::dinah::addToTxtMenu "foreign" "-background" "cyan" "-foreground" "black"
    ::dinah::addToTxtMenu "head" "-font" "$::dinah::font 13 underline"
    ::dinah::addToTxtMenu "underline" "-underline" "1"
    ::dinah::addToTxtMenu "mentioned" "-background" "blue" "-foreground" "black"
    ::dinah::addToTxtMenu "quote" "-background" "azure" "-foreground" "black" "-underline" "1"
    ::dinah::addToTxtMenu sub -offset -6
    ::dinah::addToTxtMenu sup -offset 6
}

proc desanti_navigation_win {{parentWin ""}} {
    set c0 [::dinah::Container #auto]
    focus [$c0 mkWindow $parentWin]
    $c0 initTopLeftVisible
    set win [$c0 quart 1]
    $win setX $::dinah::dimInsert
    $win setY $::dinah::dimSameLevel
    $win updateEntries
    $win buildAndGrid $::dinah::db(archiveId)
    $win newTreeOnCursor
    $win scRight
    $win setX $::dinah::dimArchive
    $win setY $::dinah::dimNil
    $win updateEntries
    $win query
}

proc specific_init_postamble {} {
    ::dinah::desanti_navigation_win "."
    set ::dinah::db(d.temp) {}
}

proc editable {d} {
    return [expr {$d ni {"" "d.nil" "d.archive" "d.sibling" "d.sameLevel" "d.insert" "d.chrono"}}]
}

set db(imgExtension) {.jpeg}
