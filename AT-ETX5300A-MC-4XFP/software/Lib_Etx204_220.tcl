# ***************************************************************************
# ConfigEtxGen
# ***************************************************************************
proc ConfigEtxGen {} {
  global gaSet
  Status "EtxGen::GenConfig"
  RL10GbGen::Config $gaSet(id220) 1 1 -size 2000 -lineRate 70% -vlan1 100
  #RL10GbGen::Config $gaSet(id220) 1 1 -sizeType fixed -size 2000 -lineRate 70% -vlan1 100 ; # -cfi1 Reset
#   RLEtxGen::GenConfig $id -updGen all -factory yes -genMode GE -minLen 64 -maxLen 64 \
#       -chain 1 -packRate 125000
#   Status "EtxGen::PortsConfig"
#   RLEtxGen::PortsConfig $id -updGen all -autoneg enbl -maxAdvertize 1000-f \
#       -admStatus up 
#   Status "EtxGen::PacketConfig"
#   RLEtxGen::PacketConfig $id VLAN -updGen all -vlanType onetagged -cvlanid 100 \
#       -cvlanp 0 -cvlanincr 0
    
}
# ***************************************************************************
# ConfigEtxGenBridge
# ***************************************************************************
proc ConfigEtxGenBridge {} {
  global gaSet
#   22/02/2021 15:42:12 35%
  Status "ConfigEtxGenBridge 1 1"
  RL10GbGen::Config $gaSet(id220) 1 1 -IPG 31 -size 64 -lineRate 20% -vlan1 10
  Status "ConfigEtxGenBridge 2 2"
  RL10GbGen::Config $gaSet(id220) 2 2 -IPG 31 -size 64 -lineRate 20% -vlan1 11
  return 0
}  
# ***************************************************************************
# ConfigEtxGenMng
# ***************************************************************************
proc ConfigEtxGenMng {} {
  global gaSet
  Status "ConfigEtxGenMng 1 1"
  RL10GbGen::Config $gaSet(id220) 1 1 -size 64 -lineRate 5%   -vlan1 100
  Status "ConfigEtxGenMng 5 5"
  RL10GbGen::Config $gaSet(id220) 5 5 -size 64 -lineRate 5% 
  Status "ConfigEtxGenMng 6 6"
  RL10GbGen::Config $gaSet(id220) 6 6 -size 64 -lineRate 5% 
  return 0
} 
# ***************************************************************************
# ConfigEtx220
# ***************************************************************************
proc ConfigEtx220 {} {
  return 0
  global gaSet 
  Status "Etx220. Download configuration file ..."
  
  set ret [Login220]
  if {$ret!=0} {return $ret}
  
  set com $gaSet(com220)
  set ret [Send $com "exit all\r" 220]
  if {$ret!=0} {return $ret}
  set ret [Send $com "config flow\r" 220]
  if {$ret!=0} {return $ret}
  
  if ![file exists $gaSet(etx220cnf)] {
    set gaSet(fail) "The configuration file ($gaSet(etx220cnf)) doesn't exist"
    return -1
  }
  set s1 [clock seconds]
  set id [open $gaSet(etx220cnf) r]
  set c 0
  while {[gets $id line]>=0} {
    if {$gaSet(act)==0} {return -2}
    if {[string length $line]>2 && [string index $line 0]!="#"} {
      incr c
      #puts "line:<$line>"
      set ret [Send $com $line\r 220]
    }
  }
  close $id  

  set s2 [clock seconds]
  puts "[expr {$s2-$s1}] sec c:$c" ; update
  
  return $ret
}

# ***************************************************************************
# Etx220Start
# ***************************************************************************
proc Etx220Start {} {
  global gaSet
  puts "Etx220Start .. [MyTime]" ; update
  ConfigEtxGen
  Status "Etx220Start 1 1"
  RL10GbGen::Start $gaSet(id220) 1 1
}
# ***************************************************************************
# Etx220StartBridge
# ***************************************************************************
proc Etx220StartBridge {} {
  global gaSet
  puts "Etx220Start .. [MyTime]" ; update
  ConfigEtxGenBridge
  Status "Etx220StartBridge 1 1"
  RL10GbGen::Start $gaSet(id220) 1 1
  Status "Etx220StartBridge 2 2"
  RL10GbGen::Start $gaSet(id220) 2 2
}

# ***************************************************************************
# Etx220StartMng
# ***************************************************************************
proc Etx220StartMng {} {
  global gaSet
  puts "Etx220Start .. [MyTime]" ; update
  ConfigEtxGenMng
  Status "Etx220StartMng  1 1"
  RL10GbGen::Start $gaSet(id220) 1 1
  Status "Etx220StartMng  5 5"
  RL10GbGen::Start $gaSet(id220) 5 5
  Status "Etx220StartMng  6 6"
  RL10GbGen::Start $gaSet(id220) 6 6
}
# ***************************************************************************
# Etx204Start
# ***************************************************************************
proc _Etx204Start {} {
  global gaSet buffer
  set id $gaSet(id204)
  puts "Etx204Start .. [MyTime]" ; update
  RLEtxGen::Start $id 
  after 1000
  RLEtxGen::Clear $id
  after 1000
  RLEtxGen::Start $id 
  after 1000
  RLEtxGen::Clear $id
  return 0
}  
# ***************************************************************************
# Etx204ShortLongRun
# ***************************************************************************
proc Etx220ShortLongRun {mc1 mc2} {
  global gaSet dutBuffer
  puts "Etx220ShortLongRun .. [MyTime]" ; update 
  set short 10
   set ret [Wait "Short run $short sec." $short white]
  if {$ret!=0} {return $ret}
  
  Etx220Stop
  set ret [Etx220Check]
  #set ret [Etx204Check]
  if {$ret!=0} {
    after 1000
    #RLEtxGen::Clear $id
    Etx220Start
    set ret [Wait "Short run $short sec.." $short white]
    if {$ret!=0} {return $ret}
    Etx220Stop
    set ret [Etx220Check]
    #set ret [Etx204Check]
    if {$ret!=0} {return $ret}
  }  
  
  
  foreach chs {1 2} mc "$mc1 $mc2" {
    set gaSet(fail) ""
    set ret [ReadAlarms $chs $mc]
    if {$ret!=0} {
      if {$gaSet(fail)==""} {
        set gaSet(fail) "Chassis-$chs MC-$mc. Read Alarms fail"
      }
      return $ret
    }
  } 
  
  
  set long 300
  Etx220Start  
  set ret [Wait "Run $long sec." $long white]
  if {$ret!=0} {return $ret}
  Etx220Stop
  set ret [Etx220Check]
  #set ret [Etx204Check]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# Etx220ShortLongRunBridge
# ***************************************************************************
proc Etx220ShortLongRunBridge {} {
  global gaSet dutBuffer
  puts "Etx220ShortLongRun .. [MyTime]" ; update 
  set short 10
   set ret [Wait "Short run $short sec." $short white]
  if {$ret!=0} {return $ret}
  
  Etx220StopBridge
  set ret [Etx220CheckBridge]
  #set ret [Etx204Check]
  if {$ret!=0} {
    after 1000
    #RLEtxGen::Clear $id
    Etx220StartBridge
    set ret [Wait "Short run $short sec.." $short white]
    if {$ret!=0} {return $ret}
    Etx220StopBridge
    set ret [Etx220CheckBridge]
    #set ret [Etx204Check]
    if {$ret!=0} {return $ret}
  }  
  
  set long 120
  Etx220StartBridge  
  set ret [Wait "Run $long sec." $long white]
  if {$ret!=0} {return $ret}
  Etx220StopBridge
  set ret [Etx220CheckBridge]
  #set ret [Etx204Check]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# Etx204ShortRun
# ***************************************************************************
proc Etx220ShortRun {txt} {
  global gaSet
  puts "Etx220ShortRun .. [MyTime]" ; update
  set short 10
  Etx220Start
  set ret [Wait "$txt Run $short sec.." $short white]
  if {$ret!=0} {return $ret}
  Etx220Stop
  set ret [Etx220Check]
  #set ret [Etx204Check]
  if {$ret!=0} {return $ret}
  return $ret
}

# ***************************************************************************
# Etx204Check
# ***************************************************************************
proc _Etx204Check {} {
  global gaSet aRes
  puts "Etx204Check .. [MyTime]" ; update
  set id $gaSet(id204)
  set ret 0
#   RLEtxGen::Stop $id
#   after 1000
  RLEtxGen::GetStatistics $id aRes 
  
  foreach gen {1 2} {
    mparray aRes *Gen$gen
    foreach stat {ERR_CNT FRAME_ERR FRAME_NOT_RECOGN PRBS_ERR SEQ_ERR} {
      set res $aRes(id$id,[set stat],Gen$gen)
      if {$res!=0} {
        set gaSet(fail) "The $stat in Generator-$gen is $res. Should be 0"
        return -1
      }
    }
    foreach stat {PRBS_OK RCV_BPS RCV_PPS} {
      set res $aRes(id$id,[set stat],Gen$gen)
      if {$res==0} {
        set gaSet(fail) "The $stat in Generator-$gen is 0. Should be more"
        return -1
      }
    }
  }
  return $ret
}

# ***************************************************************************
# Etx220Check
# ***************************************************************************
proc Etx220Check {} {
  global gaSet gMessage aRes
  Status "Etx220Check"
  RL10GbGen::Read $gaSet(id220) 1 1 aRes
  set ret [RL10GbGen::Check $gaSet(id220) 1 1 aRes]
  puts Checksret:$ret
  parray aRes
  if {$ret!=0} {
    set gaSet(fail) "There are errors in 10Gb-Generator"
    tk_messageBox -type ok -message $gMessage
  }
  return $ret
}
# ***************************************************************************
# Etx220CheckBridge
# ***************************************************************************
proc Etx220CheckBridge {} {
  global gaSet gMessage aRes
  Status "Etx220CheckBridge"
  RL10GbGen::Read $gaSet(id220) 1 1 aRes
  set ret [RL10GbGen::Check $gaSet(id220) 1 1 aRes]
  puts Checksret1:$ret
  parray aRes
  if {$ret!=0} {
    set gaSet(fail) "There are errors in 10Gb-Generator Port-1"
    tk_messageBox -type ok -message $gMessage
  } else {
    RL10GbGen::Read $gaSet(id220) 2 2 aRes
    set ret [RL10GbGen::Check $gaSet(id220) 2 2 aRes]
    puts Checksret2:$ret
    parray aRes
    if {$ret!=0} {
      set gaSet(fail) "There are errors in 10Gb-Generator Port-2"
      tk_messageBox -type ok -message $gMessage
    }
  }
  return $ret
}

# ***************************************************************************
# Etx204Stop
# ***************************************************************************
proc _Etx204Stop {} {
  global gaSet
  puts "Etx204Stop .. [MyTime]" ; update
  set id $gaSet(id204)
  RLEtxGen::Stop $id
  return 0
}
# ***************************************************************************
# Etx220Stop
# ***************************************************************************
proc Etx220Stop {} {
  global gaSet
  puts "Etx220Stop .. [MyTime]" ; update
  RL10GbGen::Stop $gaSet(id220) 1 1
  return 0
}
# ***************************************************************************
# Etx220StopBridge
# ***************************************************************************
proc Etx220StopBridge {} {
  global gaSet
  puts "Etx220Stop .. [MyTime]" ; update
  Status "Etx220StopBridge  1 1"
  RL10GbGen::Stop $gaSet(id220) 1 1
  Status "Etx220StopBridge  2 2"
  RL10GbGen::Stop $gaSet(id220) 2 2
  return 0
}

# ***************************************************************************
# Etx220StopMng
# ***************************************************************************
proc Etx220StopMng {} {
  global gaSet
  Status "Etx220StopMng  1 1"
  RL10GbGen::Stop $gaSet(id220) 1 1
  Status "Etx220StopMng  5 5"
  RL10GbGen::Stop $gaSet(id220) 5 5
  Status "Etx220StopMng  6 6"
  RL10GbGen::Stop $gaSet(id220) 6 6
  return 0
}
