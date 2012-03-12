proc canvas'new { c args } {
	frame $c
	set resize [frame $c.resize -background black]
	eval {canvas $c.canvas \
      -xscrollcommand [list $c.xscroll set] \
      -yscrollcommand [list $c.yscroll set] \
      -highlightthickness 0 \
      -borderwidth 0} $args
	scrollbar $c.xscroll -orient horizontal \
      -command [list $c.canvas xview]
	scrollbar $c.yscroll -orient vertical \
      -command [list $c.canvas yview]
	grid $c.canvas $c.yscroll -sticky news
	grid $c.xscroll $resize -sticky ew
	grid $resize -sticky news
	grid rowconfigure $c 0 -weight 1
	grid columnconfigure $c 0 -weight 1
	#bind $c.canvas <ButtonPress-1> {%W scan mark %x %y}
	#bind $c.canvas <B1-Motion> {%W scan dragto %x %y 1}
	return $c.canvas
}

proc canvas'resize {c n x1 y1} {
    variable db
	global x0 y0
	$db($c) itemconfigure $db($n,window) \
		-width [expr [winfo width $db($n,frame)] + [expr $x1 - $x0]]
	$db($c) itemconfigure $db($n,window) \
		-height [expr [winfo height $db($n,frame)] + [expr $y1 - $y0]]
}

proc canvas'move {c n x1 y1} {
    variable db
	global x0 y0
	$db($c) move $db($n,window) [expr $x1 - $x0] [expr $y1 - $y0]
    canvas'updateEdges $c
}

proc canvas'updateEdges {c} {
    variable db
    $db($c) delete withtag edge
    foreach i $db($c,edges) {
        eval edge'new $c $i
    }
}
