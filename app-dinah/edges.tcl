itcl::class Edges {
    private variable edges {}

    method add {edge} {
        ::dinah::ladd edges $edge
    }

    method delete {edge} {
        ::dinah::lrem edges $edge
    }

    method all {} { return $edges }

    method deleteAll {} {
        foreach e $edges {
            delete $e
            itcl::delete object $e
        }
    }

    method fromId {id} {
        set r {}
        foreach e $edges {
            if {[$e getFromId] eq $id} {
                lappend r $e
            }
        }
        return $r
    }

    method toId {id} {
        set r {}
        foreach e $edges {
            if {[$e getToId] eq $id} {
                lappend r $e
            }
        }
        return $r
    }

}

itcl::class Edge {
    private variable fromId ""
    private variable toId ""
    private variable dim ""
    private variable lineItem ""
    private variable lineColor ""
    private variable direct 1

    method getFromId {} {set fromId}
    method setFromId {id} {set fromId $id}
    method getToId {} {set toId}
    method setToId {id} {set toId $id}
    method getDim {} {set dim}
    method setDim {dim} {set dim $dim}
    method getLineItem {} {set lineItem}
    method setLineItem {item} {set lineItem $item}
    method setLineColor {color} {set lineColor $color}
    method setDirect {} {set direct 1}
    method setIndirect {} {set direct 0}
    method getLineOptions {} {
        if {$direct} {
            return [list -fill $lineColor]
        } else {
            return [list -fill $lineColor -dash -]
        }
    }
}
