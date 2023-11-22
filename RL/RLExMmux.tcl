#***************************************************************************
#** Filename: RLExMmux.tcl 
#** Written by Semion 24.10.2007 
#** 
#** Absrtact: This file activate the MultiMux
#**
#   Procedures names in this file:
#           - Open
#           - AllNC
#           - ChCon
#           - ChsCon
#           - ChDis
#           - ChsDis
#           - Close
#           - ChOnly
#** Examples: 
#     set id [RLExMmux::Open 8 2]
#     RLExMmux::AllNC $id
#     RLExMmux::ChCon $id 3
#     RLExMmux::ChDis $id 3
#     RLExMmux::ChsCon $id 1-5
#     RLExMmux::ChsCon $id 1,5
#     RLExMmux::ChsCon $id 1-5,7,11-13,15
#     RLExMmux::ChsDis $id 1-5
#     RLExMmux::ChOnly $id 5
#**
#***************************************************************************

package require RLEH
package require RLExPio
package provide RLExMmux 0.0
namespace eval RLExMmux    { 
  namespace export Open Close AllNC ChCon ChsCon ChDis ChsDis ChOnly
  global gMessage

  # ***************************************************************************
  # Open
  # set id [RLExMmux::Open 8 2]
  # ***************************************************************************
  proc Open {portNumber {card 1}} {
	  global gMessage	 ERRMSG
	  if {[set idMmux [RLExPio::Open $portNumber PORT $card]] <= 0}  {
	    set gMessage $ERRMSG
	    append gMessage "\nERROR while open ExMmux."
	    return [RLEH::Handle SAsystem gMessage]
	  }
		#Config Pio to OUT 
	  if {[RLExPio::SetConfig $idMmux out out]}  {
	    set gMessage $ERRMSG
	    append gMessage "\nERROR while open ExMmux."
	    return [RLEH::Handle SAsystem gMessage]
	  }
	  return $idMmux
  }
  # ***************************************************************************
  # Close
  # RLExMmux::Close $id
  # ***************************************************************************
  proc Close {id} {
    RLExPio::Close $id
	  return 0
  }
  # ***************************************************************************
  # AllNC
  # Disconnect all chanels
  # RLExMmux::AllNC $id
  # ***************************************************************************
  proc AllNC {id} {
    RLExPio::Set $id 10000000
    return 0
  }

  # ***************************************************************************
  # ChCon
  # Connect specific chanel. State of other chanels doesn't changed.
  # RLExMmux::ChCon $id 3
  # ***************************************************************************
  proc ChCon {id ch} {
    set w [Ch2Pio $ch]
    if {$w=="-1"} {return $w}
    RLExPio::Set $id 111$w
    RLExPio::Set $id 011$w
    RLExPio::Set $id 111$w  
    return 0
  }

  # ***************************************************************************
  # ChDis
  # Disconnect specific chanel. State of other chanels doesn't changed.
  # RLExMmux::ChDis $id 3
  # ***************************************************************************
  proc ChDis {id ch} {
    set w [Ch2Pio $ch]  
    if {$w=="-1"} {return $w}
    RLExPio::Set $id 110$w
    RLExPio::Set $id 010$w
    RLExPio::Set $id 110$w
    return 0
  }

  # ***************************************************************************
  # Ch2Pio
  # Internal proc, converts chanel's number to PIO's word 
  # ***************************************************************************
  proc Ch2Pio {ch} {
    global gMessage
    if {$ch<=7} {
      set grBits 00
    } elseif {$ch>7 && $ch<=15} {
      set grBits 01
    } elseif {$ch>15 && $ch<=23} {
      set grBits 10
    } elseif {$ch>23 && $ch<=28} {
      set grBits 11
    } else {
      set gMessage "Wrong Chanel's number: $ch"
      return [RLEH::Handle SAsyntax gMessage]
    }
    
    switch -- $ch {
      8  - 16 - 24      {set chBits 000}
      1  -  9 - 17 - 25 {set chBits 001}
      2  - 10 - 18 - 26 {set chBits 010}
      3  - 11 - 19 - 27 {set chBits 011}
      4  - 12 - 20 - 28 {set chBits 100}
      5  - 13 - 21      {set chBits 101}
      6  - 14 - 22      {set chBits 110}
      7  - 15 - 23      {set chBits 111}
      default {
        set gMessage "Wrong Chanel's number: $ch"
        return [RLEH::Handle SAsyntax gMessage]
      }
    }
    return "${grBits}${chBits}"
  }
  
  # ***************************************************************************
  # ChsCon
  # Connect range of chanels. State of other chanels doesn't changed.
  # The range may be defined in a few methods:
  # RLExMmux::ChsCon $id 1-5 : chanles 1,2,3,4 and 5 will be connected
  # RLExMmux::ChsCon $id 1,5 : chanles 1 and 5 will be connected
  # RLExMmux::ChsCon $id 1-5,7,11-13,15 : chanles 1,2,3,4,5,7,11,12,13 and 15 
  #     will be connected
  # ***************************************************************************
  proc ChsCon {id chs} {
    set lChs [Chs2List $chs]
    #puts "ChsCon lChs:$lChs"
    foreach ch $lChs {
      #puts "ChsCon ch:$ch"
      set ret [ChCon $id $ch]
      if {$ret!=0} {return $ret}
    }
    return 0
  }
  
  # ***************************************************************************
  # ChsDis
  # Same as ChsCon
  # RLExMmux::ChsDis $id 1-5
  # ***************************************************************************
  proc ChsDis {id chs} {
    set lChs [Chs2List $chs]
    foreach ch $lChs {
      set ret [ChDis $id $ch]
      if {$ret!=0} {return $ret}
    }
    return 0
  }
  
  # ***************************************************************************
  # Chs2List
  # Internal proc. Convert chanels' range to list
  # ***************************************************************************
  proc Chs2List {chs} {
    global gMessage
    #puts $chs
    #set res [regexp -all -inline -- {[^0-9\,\-]+} $chs]
    #if {$res!=""} {
    #  set gMessage "Wrong character/s: $res"
    #  return [RLEH::Handle SAsyntax gMessage]	
    #}
    set lPorts [split $chs ,-]
    foreach port $lPorts {
      if {$port>28} {
        set gMessage "Wrong Chanel's number: $port"
        return [RLEH::Handle SAsyntax gMessage]
      }
    }
    
    set lChs [split $chs ,]
    foreach ll $lChs {
      if [string match *-* $ll] {
        set f [lindex [split $ll -] 0]
        set l [lindex [split $ll -] 1]
        for {set i $f} {$i<=$l} {incr i} {
          lappend lstChs $i
        }
      } else {
        lappend lstChs $ll
      }    
    }
    #puts lstChs=$lstChs
    return $lstChs
  }
  
  # ***************************************************************************
  # ChOnly
  # Disconnect all chanels and connect the specific chanel
  # RLExMmux::ChOnly $id 5
  # ***************************************************************************
  proc ChOnly {id ch} {
    set ret [AllNC $id]
    if {$ret!=0} {return $ret}
    set ret [ChCon $id $ch]
    if {$ret!=0} {return $ret}
    return 0
  }
}
  