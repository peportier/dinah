itcl::class Autocomplete {
    private variable currentNames {}
    private variable currentNameIndex 0
    private variable cursorPosition 0
    private variable currentList {}
    private variable primaryList {}
    private variable secondaryList {}
    private variable mode "primary"
    private variable listNames {}
    private variable w

    constructor {windowName autocompleteList} {
        set w $windowName
        set primaryList [lsort -dictionary $autocompleteList]
	set currentList $primaryList
        entry $w
        mkNames
        bind $w <Key-Tab> {focus {}}
        bind $w <Key-Down> [list $this primarySwitch]
        bind $w <Key-Down> +{break}
        bind $w <Key-Up> [list $this primarySwitch -1]
        bind $w <Key-Up> +{break}
        bind $w <Control-Key-Down> [list $this secondarySwitch]
        bind $w <Control-Key-Down> +{break}
        bind $w <Control-Key-Up> [list $this secondarySwitch -1]
        bind $w <Control-Key-Up> +{break}
        bind $w <Key-BackSpace> [list $this backspace]
        bind $w <Key-BackSpace> +{break}
        bind $w <KeyPress> [list $this keypress %A]
        bind $w <KeyPress> +{break}
        bind $w <Return> [list $this validate]
        bind $w <Return> +{break}
        bind $w <Key-Escape> [list $this giveupFocus]
    }

    private method completeEntryText {}
    private method mkNames {}
    public method validate {}
    public method keypress {UnicodeChar}
    public method switch {delta}
    public method primarySwitch {{delta 1}}
    public method secondarySwitch {{delta 1}}
    public method backspace {}
    public method w {}
    public method giveupFocus {}
    public method nextFocus {}
    public method prevFocus {}
    public method setSecondaryList {autocompleteList}
}

itcl::body Autocomplete::setSecondaryList {autocompleteList} {
    set secondaryList [lsort -dictionary $autocompleteList]
    set mode "primary"
    set currentList $primaryList
    $this mkNames
}

itcl::body Autocomplete::giveupFocus {} {
    focus [winfo toplevel $w]
}

itcl::body Autocomplete::w {} { return $w }

itcl::body Autocomplete::completeEntryText {} {
    if {$currentNames != {}} {
        $w delete 0 end
        $w insert end [lindex $currentNames [expr $currentNameIndex % [llength $currentNames]]]
        $w selection range $cursorPosition end
        $w icursor $cursorPosition
    }
}

itcl::body Autocomplete::mkNames {} {
    set currentNames [lsearch -inline -all $currentList [$w get]*]
    set currentNameIndex 0
}

itcl::body Autocomplete::keypress {char} {
    if {$char != {}} {
        $w delete $cursorPosition end
        $w insert end $char
        set cursorPosition [string length [$w get]]
        $this mkNames
        $this completeEntryText
    } 
}

itcl::body Autocomplete::primarySwitch {{delta 1}} {
	if {$mode ne "primary"} {
        set mode "primary"
        set currentList $primaryList
        $this mkNames
    }
    $this switch $delta
}

itcl::body Autocomplete::secondarySwitch {{delta 1}} {
	if {$mode ne "secondary"} {
        set mode "secondary"
        set currentList $secondaryList
        $this mkNames
    }
    $this switch $delta
}

itcl::body Autocomplete::switch {delta} {
    incr currentNameIndex $delta
    $this completeEntryText
}

itcl::body Autocomplete::backspace {} {
    if {[$w selection present]} {
        $w delete $cursorPosition end
    } else {
        $w delete [expr [string length [$w get]] - 1]
    }
    set cursorPosition [string length [$w get]]
    $this mkNames
}

itcl::body Autocomplete::validate {} {
    if {[$w selection present]} {
        $w selection clear
        set cursorPosition [string length [$w get]]
        $w icursor $cursorPosition
    }
}
