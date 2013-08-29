set ::dinah::dimAlternative "d.alternative"
set ::dinah::dimArchive "d.archive"
set ::dinah::dimAttribute "d.attribute"
set ::dinah::dimChrono "d.chrono"
set ::dinah::dimClipboard "d.clipboard"
set ::dinah::dimClone "d.clone"
set ::dinah::dimContains "d.contains"
set ::dinah::dimFragments "d.fragments"
set ::dinah::dimInfo "d.info"
set ::dinah::dimInit "d.init"
set ::dinah::dimNil "d.nil"
set ::dinah::dimNote "d.note"
set ::dinah::dimSameLevel "d.sameLevel"
set ::dinah::dimTemp "d.temp"
set ::dinah::dimTranscription "d.transcription"

set ::dinah::separatorSize 5
set ::dinah::fragmentBorderWidth 2
set ::dinah::selectionCursorColor red
set ::dinah::backgroundColor antiqueWhite
set ::dinah::closeColor blue
set ::dinah::openColor black
set ::dinah::font helvetica
set ::dinah::fontsize 10

set ::dinah::resolutions_suffix {""}

proc specific_init_preamble {} {
    ::dinah::dbNewDim $::dinah::dimAlternative
    ::dinah::dbNewDim $::dinah::dimArchive
    ::dinah::dbNewDim $::dinah::dimAttribute
    ::dinah::dbNewDim $::dinah::dimChrono
    ::dinah::dbNewDim $::dinah::dimClipboard
    ::dinah::dbNewDim $::dinah::dimClone
    ::dinah::dbNewDim $::dinah::dimContains
    ::dinah::dbNewDim $::dinah::dimFragments
    ::dinah::dbNewDim $::dinah::dimInfo
    ::dinah::dbNewDim $::dinah::dimInit
    ::dinah::dbNewDim $::dinah::dimNil
    ::dinah::dbNewDim $::dinah::dimNote
    ::dinah::dbNewDim $::dinah::dimSameLevel
    ::dinah::dbNewDim $::dinah::dimTemp
    ::dinah::dbNewDim $::dinah::dimTranscription
    ::dinah::addToTxtMenu "auteur" "-background" "orange" "-foreground" "black"
    ::dinah::addToTxtMenu "concept" "-background" "forest green" "-foreground" "black"
    ::dinah::addToTxtMenu titre1 -font "$::dinah::font 15 underline"
    ::dinah::addToTxtMenu titre2 -font "$::dinah::font 13 underline"
    ::dinah::addToTxtMenu titre3 -font "$::dinah::font 11 underline"
    ::dinah::addToTxtMenu sub -offset -6
    ::dinah::addToTxtMenu sup -offset 6
}

proc specific_init_postamble {} {
    set c0 [::dinah::Container #auto]
    focus [$c0 mkWindow .]
    $c0 initLeftVisible
    set quart1 [$c0 quart 1]
    $quart1 setX $::dinah::dimContains
    $quart1 setY $::dinah::dimSameLevel
    $quart1 updateEntries
    $quart1 buildAndGrid [::dinah::dbGet root]
    $quart1 newTreeOnCursor
    $quart1 scRight
    $quart1 setX $::dinah::dimArchive
    $quart1 setY $::dinah::dimNil
    $quart1 updateEntries
    $quart1 query
    $quart1 setOnMoveCursor [list ::dinah::quart1OnMoveCursor $c0]
    [$c0 quart 3] setOnMoveCursor [list ::dinah::quart3OnMoveCursor $c0]
}

proc quart3OnMoveCursor {container} {
    set quart3 [$container quart 3]
    set quart4 [$container quart 4]
    set cursorId [$quart3 scId]
    ::dinah::bouvard:newNote $cursorId
    $quart4 setX $::dinah::dimNote
    $quart4 setY $::dinah::dimNil
    $quart4 updateEntries
    $quart4 setWWidth 1
    $quart4 buildAndGrid $cursorId
    $quart4 scRight
    $quart3 getFocus
}

proc bouvard:newNote {id} {
    if {![::dinah::dbFragmentBelongsToDim $::dinah::dimNote $id]} {
        set note [::dinah::dbNewEmptyFragment Txt]
        ::dinah::dbAppendSegmentToDim $::dinah::dimNote [list $id $note]
    }
}

proc quart1OnMoveCursor {container} {
    set quart1 [$container quart 1]
    set quart2 [$container quart 2]
    set quart3 [$container quart 3]
    set cursorId [$quart1 scId]
    $quart3 setX $::dinah::dimFragments
    $quart3 setY $::dinah::dimNil
    $quart3 updateEntries
    $quart3 buildAndGrid $cursorId
    ::dinah::bouvard:newNote $cursorId
    $quart2 setX $::dinah::dimNote
    $quart2 setY $::dinah::dimNil
    $quart2 updateEntries
    $quart2 setWWidth 1
    $quart2 buildAndGrid $cursorId
    $quart2 scRight
    $quart1 getFocus
}

proc editable {d} {
    return [expr {$d ni {"" "d.nil" "d.archive" "d.sameLevel" "d.chrono"}}]
}

::dinah::dbSet imgExtension {.jpg}
