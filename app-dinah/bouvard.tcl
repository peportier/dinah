set ::dinah::dimNote "d.note"
set ::dinah::dimArchive "d.archive"
set ::dinah::dimSameLevel "d.sameLevel"
set ::dinah::dimFragments "d.fragments"
set ::dinah::dimInit "d.init"
set ::dinah::dimNil "d.nil"
set ::dinah::dimClipboard "d.clipboard"
set ::dinah::dimChrono "d.chrono"
set ::dinah::dimInfo "d.info"
set ::dinah::dimContains "d.contains"
set ::dinah::separatorSize 5
set ::dinah::fragmentBorderWidth 2
set ::dinah::backgroundColor antiqueWhite
set ::dinah::closeColor blue
set ::dinah::openColor black
set ::dinah::font helvetica

proc specific_init_preamble {} {
    ::dinah::newDim? $::dinah::dimNote
    ::dinah::newDim? $::dinah::dimArchive
    ::dinah::newDim? $::dinah::dimSameLevel
    ::dinah::newDim? $::dinah::dimFragments
    ::dinah::newDim? $::dinah::dimInit
    ::dinah::newDim? $::dinah::dimNil
    ::dinah::newDim? $::dinah::dimClipboard
    ::dinah::newDim? $::dinah::dimChrono
    ::dinah::newDim? $::dinah::dimInfo
    ::dinah::newDim? $::dinah::dimContains
    ::dinah::addToTxtMenu "auteur" "-background" "orange" "-foreground" "black"
    ::dinah::addToTxtMenu "concept" "-background" "forest green" "-foreground" "black"
    ::dinah::addToTxtMenu titre1 -font "$::dinah::font 15 underline"
    ::dinah::addToTxtMenu titre2 -font "$::dinah::font 13 underline"
    ::dinah::addToTxtMenu titre3 -font "$::dinah::font 11 underline"
    ::dinah::addToTxtMenu sub -offset -6
    ::dinah::addToTxtMenu sup -offset 6
    ::dinah::Page::high
}

proc specific_init_postamble {} {
    set c0 [::dinah::Container #auto]
    focus [$c0 mkWindow .]
    set quart1 [$c0 quart 1]
    $quart1 setX $::dinah::dimContains
    $quart1 setY $::dinah::dimSameLevel
    $quart1 updateEntries
    $quart1 buildAndGrid $::dinah::db(root)
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
    set found [::dinah::findInDim $::dinah::dimNote $id]
    if {$found == {}} {
        set note [::dinah::emptyNode Txt]
        lappend ::dinah::db($::dinah::dimNote) [list $id $note]
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

set db(imgExtension) {.jpg}
