set ::dinah::dimAlternative "d.alternative"
set ::dinah::dimArchive "d.archive"
set ::dinah::dimAttribute "d.attribute"
set ::dinah::dimChrono "d.chrono"
set ::dinah::dimClipboard "d.clipboard"
set ::dinah::dimClone "d.clone"
set ::dinah::dimFragments "d.fragments"
set ::dinah::dimInfo "d.info"
set ::dinah::dimInit "d.init"
set ::dinah::dimInsert "d.insert"
set ::dinah::dimNil "d.nil"
set ::dinah::dimNote "d.note"
set ::dinah::dimNoticeElement "d.noticeElement"
set ::dinah::dimNoticeLevel "d.noticeLevel"
set ::dinah::dimSameLevel "d.sameLevel"
set ::dinah::dimTemp "d.temp"
set ::dinah::dimTranscription "d.transcription"
set ::dinah::dim0 "d.0"
set ::dinah::dim1 "d.1"
set ::dinah::dim2 "d.2"
set ::dinah::dim3 "d.3"
set ::dinah::dimAuteur "d.auteur"
set ::dinah::dimConcept "d.concept"
set ::dinah::dimRotate "d.rotate"

set ::dinah::roots "roots"
set ::dinah::separatorSize 5
set ::dinah::fragmentBorderWidth 2
set ::dinah::selectionCursorColor red
set ::dinah::backgroundColor antiqueWhite
set ::dinah::closeColor blue
set ::dinah::openColor black
set ::dinah::font helvetica
set ::dinah::fontsize 10
set ::dinah::resolutions_suffix {"_low" "_high"}

proc specific_init_preamble {} {
    ::dinah::dbNewDim $::dinah::dimAlternative
    ::dinah::dbNewDim $::dinah::dimArchive
    ::dinah::dbNewDim $::dinah::dimAttribute
    ::dinah::dbNewDim $::dinah::dimChrono
    ::dinah::dbNewDim $::dinah::dimClipboard
    ::dinah::dbNewDim $::dinah::dimClone
    ::dinah::dbNewDim $::dinah::dimFragments
    ::dinah::dbNewDim $::dinah::dimInfo
    ::dinah::dbNewDim $::dinah::dimInit
    ::dinah::dbNewDim $::dinah::dimInsert
    ::dinah::dbNewDim $::dinah::dimNil
    ::dinah::dbNewDim $::dinah::dimNote
    ::dinah::dbNewDim $::dinah::dimNoticeElement
    ::dinah::dbNewDim $::dinah::dimNoticeLevel
    ::dinah::dbNewDim $::dinah::dimSameLevel
    ::dinah::dbNewDim $::dinah::dimTemp
    ::dinah::dbNewDim $::dinah::dimTranscription
    ::dinah::dbNewDim $::dinah::dim0
    ::dinah::dbNewDim $::dinah::dim1
    ::dinah::dbNewDim $::dinah::dim2
    ::dinah::dbNewDim $::dinah::dim3
    ::dinah::dbNewDim $::dinah::dimAuteur
    ::dinah::dbNewDim $::dinah::dimConcept
    ::dinah::dbNewDim $::dinah::dimRotate
    if {! [::dinah::dbExists $::dinah::roots]} {
        ::dinah::dbSet $::dinah::roots ""
    }
    ::dinah::addToTxtMenu "gras" "-font" "$::dinah::font $::dinah::fontsize bold"
    ::dinah::addToTxtMenu "italique" "-font" "$::dinah::font $::dinah::fontsize italic"
    ::dinah::addToTxtMenu "exposant" "-offset" "6"
    ::dinah::addToTxtMenu "indice" "-offset" "-6"
    ::dinah::addToTxtMenu "soulign\u00E9" "-underline" "1"
    ::dinah::addToTxtMenu "ray\u00E9" "-overstrike" "1"
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
    ::dinah::addToTxtMenu "mentioned" "-background" "blue" "-foreground" "black"
    ::dinah::addToTxtMenu "quote" "-background" "azure" "-foreground" "black" "-underline" "1"
}

proc desanti_navigation_win {{parentWin ""} {noticeWin 0}} {
    set c0 [::dinah::Container #auto]
    focus [$c0 mkWindow $parentWin]
    $c0 initTopLeftVisible
    set win [$c0 quart 1]
    $win setX $::dinah::dimInsert
    $win setY $::dinah::dimSameLevel
    $win updateEntries
    $win buildAndGrid [::dinah::dbGet archiveId]
    $win newTreeOnCursor
    $win setTreeNavDim $::dinah::dimArchive
    $win scRight
    $win setX $::dinah::dimArchive
    $win setY $::dinah::dimNil
    $win updateEntries
    $win query
    if {$noticeWin} {
        $win setOnMoveCursor [list ::dinah::navWinOnMoveCursor $c0]
    }
}

proc navWinOnMoveCursor {container} {
    set quart1 [$container quart 1]
    set quart2 [$container quart 2]
    set quart3 [$container quart 3]
    set quart1ScId [$quart1 scId]
    if {[$quart1 getX] eq $::dinah::dimArchive} {
        set found [::dinah::dbFindInDim $::dinah::dimArchive $quart1ScId]
        if { ($found != {}) && ([lindex $found 1] == 0) } {
            $quart3 setX $::dinah::dimArchive
            $quart3 setY $::dinah::dimNil
            $quart3 updateEntries
            $quart3 setWWidth 1
            $quart3 setWHeight 1
            $quart3 buildAndGrid $quart1ScId
            $quart3 setModeNotice
        }
    }
    if {![::dinah::dbNodeBelongsToDim $::dinah::dimTranscription $quart1ScId]} {
        set transcriptionId [::dinah::dbNewEmptyNode Txt "transcription ($quart1ScId)"]
        set newSegment [list $quart1ScId $transcriptionId]
        ::dinah::dbAppendSegmentToDim $::dinah::dimTranscription $newSegment
    }
    $quart2 buildAndGrid $quart1ScId
    $quart2 setModeTranscription
    $quart1 getFocus
}

proc specific_init_postamble {} {
    ::dinah::desanti_navigation_win "." 1
    ::dinah::dbSetDim $::dinah::dimTemp {}
}

proc editable {d} {
    return [expr {( $d ni {"" $::dinah::dimNil $::dinah::dimArchive $::dinah::dimSameLevel\
                           $::dinah::dimInsert $::dinah::dimChrono} ) &&\
                  ( $d in $::dinah::db(dimensions) )}]
}

::dinah::dbSet imgExtension {.jpeg}
