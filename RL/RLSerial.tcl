
package provide RLSerial 1.2
namespace eval RLSerial { 
namespace export Open Close Send SendSlow Waitfor

proc Open {{comPort 1} {rate 9600} {parity n} {bits 8} {stop 1}} {
  variable vaSerial
  set vaSerial($comPort.comPort) $comPort
	if {$comPort > 9} {
    set com \\\\.\\com$comPort
	} else {
      set com COM$comPort
  }
  if [catch {open $com RDWR} handle] {
    return -1
  } else {
	  set vaSerial($comPort.id) $handle
    fconfigure $vaSerial($comPort.id) -blocking 0 -buffering none \
       -mode [set rate],[set parity ],[set bits],[set stop] \
       -translation binary -eofchar {} -sysbuffer {32768 4096}
    set vaSerial($comPort.buffer) ""
    return 0 ; #$vaSerial($comPort.id)
  }
}


#****************************************************************************
#** Send
#****************************************************************************
proc Send {comPort outStr {buff  ""} {inStr  ""} {timeout 10}} {
  return [RLSerial::_Send $comPort $outStr -1 $buff $inStr $timeout] 
}

#***************************************************************************
#** SendSlow
#***************************************************************************
proc SendSlow {comPort outStr {ip_LetterDelay 0} {buff  ""} {inStr  ""} {timeout 10}} {
  return [RLSerial::_Send $comPort $outStr $ip_LetterDelay $buff $inStr $timeout ]  
}


#***************************************************************************
#** _Send
#***************************************************************************
proc _Send {comPort outStr ip_LetterDelay buff inStr timeout} {
  variable vaSerial
  update idletasks
  #flush $vaSerial($comPort.id)
  catch {read $vaSerial($comPort.id)} 
  upvar #0 $buff localBuffer
  set localBuffer ""
  
  #set re \[\]\[\)\(\]
  regsub -all {([][)($\\])} $inStr {\\\1} inStr
  
  if {$ip_LetterDelay=="-1"} {
    puts -nonewline $vaSerial($comPort.id) $outStr
  } else {
    foreach ch [split $outStr {}] {
      puts -nonewline $vaSerial($comPort.id) $ch
      after [expr $ip_LetterDelay+2]
    }
  }
  flush $vaSerial($comPort.id)
  set RLSerial::vaSerial($comPort.sent) 0  
  #after 10
  if {$inStr != ""} {
    set startTime [clock seconds]
    while 1 {
      after 10
      set RLSerial::vaSerial($comPort.sent) -1
      if {[eof $vaSerial($comPort.id)]} {
        close $vaSerial($comPort.id)
        return -1
      }  
      if [catch {read $vaSerial($comPort.id)} readBuffer] {
        puts "[fconfigure $vaSerial($comPort.id) -lasterror]"
      } else {
        append localBuffer $readBuffer
      }

      set re [regexp $inStr $localBuffer]
      set re2 [string match {*[set inStr]*} $localBuffer]
      #puts "\n_PiRe re:$re  re2:$re2 \n" ; update
      if {$re==1} {
        after 20
        if [catch {read $vaSerial($comPort.id)} readBuffer] {
          puts "[fconfigure $vaSerial($comPort.id) -lasterror]"
        } else {
          append localBuffer $readBuffer
        }
        set RLSerial::vaSerial($comPort.sent) 0
        break
      }
      
      set timeNow [clock seconds]
      set runTime [expr $timeNow - $startTime]
      if {$runTime>$timeout} {
        break
      }
    }
  }
  #puts "\n______ outStr:__[set outStr]__ inStr:__[set inStr]__\
         ret of Send: __[set RLSerial::vaSerial($comPort.sent)]__\n\
         localBuffer:__[set localBuffer]__\n" ; update
  return $RLSerial::vaSerial($comPort.sent)
}

# ***************************************************************************
# Waitfor
# ***************************************************************************
proc Waitfor {comPort {buff  ""} {inStr  ""} {timeout 10}} {
  return [RLSerial::_Waitfor $comPort $buff $inStr $timeout] 
}
# ***************************************************************************
# _Waitfor
# ***************************************************************************
proc _Waitfor {comPort buff inStr timeout} {
  variable vaSerial
  update idletasks
  upvar #0 $buff localBuffer
  set localBuffer ""
  set startTime [clock seconds]
  while 1 {
    after 10
    set RLSerial::vaSerial($comPort.sent) -1
    if {[eof $vaSerial($comPort.id)]} {
      close $vaSerial($comPort.id)
      return -1
    }  
    if [catch {read $vaSerial($comPort.id)} readBuffer] {
      puts "[fconfigure $vaSerial($comPort.id) -lasterror]"
    } else {
      append localBuffer $readBuffer
    }

    set re [regexp $inStr $localBuffer]
    #set re2 [string match {*[set inStr]*} $localBuffer]
    #puts "\n_PiRe re:$re  re2:$re2 \n" ; update
    if {$re==1} {
      after 20
      if [catch {read $vaSerial($comPort.id)} readBuffer] {
        puts "[fconfigure $vaSerial($comPort.id) -lasterror]"
      } else {
        append localBuffer $readBuffer
      }
      set RLSerial::vaSerial($comPort.sent) 0
      break
    }
    
    set timeNow [clock seconds]
    set runTime [expr $timeNow - $startTime]
    if {$runTime>$timeout} {
      break
    }
  }
  return $RLSerial::vaSerial($comPort.sent)
}

#***************************************************************************
#** Close
#***************************************************************************
proc Close {comPort} {
  variable vaSerial
  fileevent $vaSerial($comPort.id) readable {}
  catch [list close $vaSerial($comPort.id)]
  foreach v [array names vaSerial $comPort.*] {
    #catch [list unset vaSerial($v)]
  }
}

# RLSerial namespace end
}

#regexp {Source[ ]+IP[ ]+1[ ]+...[ ]+\(([0-9\.]+)\)} $bb m val
#regexp {Vlan[ ]+X\[1 - 1468\][ ]+...[ ]+\(([0-9])\)} $bb m val

proc hhh {} {
  ComOpen 115200
  Send 1 \r ff 1
  
  puts [MyTime] ; update
  set startTime [clock seconds]
  for {set i 1} {$i<=180} {incr i} {
    set ret [RLSerial::Waitfor 1 buffer user 1]
    set nowTime [clock seconds]; set runTime [expr {$nowTime - $startTime}] 
    puts "i:$i runTime:$runTime ret:$ret buffer:_${buffer}_" ; update
    if {$ret==0} {break}
  }
  puts [MyTime] ; update
  
}