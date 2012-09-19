set ::dinah::dimTemp "d.temp"
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
set ::dinah::dimTranscription "d.transcription"
set ::dinah::dimClone "d.clone"
set ::dinah::separatorSize 5
set ::dinah::fragmentBorderWidth 2
set ::dinah::backgroundColor antiqueWhite
set ::dinah::closeColor blue
set ::dinah::openColor black
set ::dinah::font helvetica
set ::dinah::fontsize 10
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
    ::dinah::newDim? $::dinah::dimTranscription
    ::dinah::newDim? $::dinah::dimClone
    ::dinah::newDim? $::dinah::dimTemp
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
        set found [::dinah::findInDim $::dinah::dimArchive $quart1ScId]
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
    set found [::dinah::findInDim $::dinah::dimTranscription $quart1ScId]
    if {$found == {}} {
        set transcriptionId [::dinah::emptyNode Txt "transcription ($quart1ScId)"]
        ::dinah::dbAppend $::dinah::dimTranscription [list $quart1ScId $transcriptionId]
    }
    $quart2 buildAndGrid $quart1ScId
    $quart2 setModeTranscription
    $quart1 getFocus
}

proc specific_init_postamble {} {
    ::dinah::desanti_navigation_win "." 1
    ::dinah::dbSet $::dinah::dimTemp {}
}

proc editable {d} {
    return [expr {$d ni {"" "d.nil" "d.archive" "d.sibling" "d.sameLevel" "d.insert" "d.chrono"}}]
}

::dinah::dbSet imgExtension {.jpeg}
