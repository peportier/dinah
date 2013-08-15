set TEST 1

###############
# FOR TESTING #
###############

if {$TEST} {
    package require Tk
    package require Itcl
}

########
# CODE #
########

itcl::class Autocomplete {
    private variable suggestions {}
    private variable currentSuggestionIndex 0
    private variable cursorPosition 0
    private variable listOfNames {}
    private variable w

    constructor {windowName autocompleteList} {
        set w $windowName
        set listOfNames [lsort -dictionary $autocompleteList]
        entry $w
        updateSuggestions
        bind $w <Key-Tab> {focus {}}
        bind $w <Key-Down> [list $this switch 1]
        bind $w <Key-Down> +{break}
        bind $w <Key-Up> [list $this switch -1]
        bind $w <Key-Up> +{break}
        bind $w <Key-BackSpace> [list $this backspace]
        bind $w <Key-BackSpace> +{break}
        bind $w <KeyPress> [list $this keypress %A]
        bind $w <KeyPress> +{break}
        bind $w <Return> [list $this validate]
        bind $w <Return> +{break}
        bind $w <Key-Escape> [list $this giveupFocus]
    }

    method getFocus {} {
        focus $w
    }

    method giveupFocus {} {
        focus [winfo toplevel $w]
    }

    method getValue {} {
        return [$w get]
    }

    method blank {} {
        $w delete 0 end
    }

    method pushText {someText} {
        $w insert end $someText
    }

    private method completeEntryText {} {
        if {$suggestions != {}} {
            blank
            $w insert end [lindex $suggestions $currentSuggestionIndex]
            $w selection range $cursorPosition end
            $w icursor $cursorPosition
        }
    }

    private method updateSuggestions {} {
        set suggestions [lsearch -inline -all $listOfNames [$w get]*]
        set currentSuggestionIndex 0
    }

    method keypress {char} {
        if {$char != {}} {
            $w delete $cursorPosition end
            $w insert end $char
            set cursorPosition [string length [$w get]]
            updateSuggestions
            completeEntryText
        }
    }


    method switch {delta} {
        set newIndex [expr {$currentSuggestionIndex + $delta}]
        if {(0 <= $newIndex) && ($newIndex < [llength $suggestions])} {
            incr currentSuggestionIndex $delta
            completeEntryText
        }
    }

    method backspace {} {
        if {[$w selection present]} {
            $w delete $cursorPosition end
        } else {
            $w delete [expr [string length [$w get]] - 1]
        }
        set cursorPosition [string length [$w get]]
        updateSuggestions
    }

    method validate {} {
        if {[$w selection present]} {
            $w selection clear
            set cursorPosition [string length [$w get]]
            $w icursor $cursorPosition
        }
    }
}

###############
# FOR TESTING #
###############

if {$TEST} {
    set a [Autocomplete #auto .a {"abcd" "abdc" "acbd" "acdb" "adbc" "adcb" "bacd" "badc" "bcad" "bcda" "bdac" "bdca"}]
    pack .a
}
