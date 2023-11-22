# ***************************************************************************
# BuildTests
# ***************************************************************************
proc BuildTests {} {
  global gaSet gaGui glTests
  
  puts "\n[MyTime] BuildTests DutInitName:$gaSet(uutOpt)\n"
  
  RetriveDutFam 
   
  
  set lRunTestNames [list FactoryDefault CpuPhyRGMII Voltage Memory ID  \
      Temperature IOcard PowerController TdmBusIO DataSetup DataRun \
      RedundancySetup  RedundancyRun \
      ExternalClock BP-Chassis1 BP-Chassis2 TdmBusFAN1 TdmBusFAN2 \
      Led1 Led2 BridgeSetup BridgeRun TimeDate FinalFactoryDefault Pages]    
  set glTests ""
  for {set i 0; set k 1} {$i<[llength $lRunTestNames]} {incr i; incr k} {
    if {$gaSet(UUTREF)=="UUTREF" && [string index [lindex $lRunTestNames $i] end]==2} {
      ## dont add test of chassis 2 if it REF
      continue
    }
    if {$gaSet(UUTREF)=="REFUUT" && [string index [lindex $lRunTestNames $i] end]==1} {
      ## dont add test of chassis 1 if it REF
      continue
    }
    lappend glTests "$k..[lindex $lRunTestNames $i]"  
  }
  
  set gaSet(startFrom) [lindex $glTests 0]
  $gaGui(startFrom) configure -values $glTests -height [llength $glTests]
                       
} 

# ***************************************************************************
# Testing
# ***************************************************************************
proc Testing {} {
  global gaSet glTests dutBuffer

  set startTime [$gaSet(startTime) cget -text]
  set stTestIndx [lsearch $glTests $gaSet(startFrom)]
  set lRunTests [lrange $glTests $stTestIndx end]   
  
  Status "Test start"
  set gaSet(curTest) ""
  set ret 0
  
  AddToLog "********* Start testing *********"
  puts "RunTests1 gaSet(startFrom):$gaSet(startFrom)"
  set ::davicomTime [clock format [clock seconds] -format %Y.%m.%d_%H%M]
  foreach numberedTest $lRunTests {
    if {$gaSet(act)==0} {set ret -2;  break}
    set testName [lindex [split $numberedTest ..] end]
    $gaSet(startTime) configure -text "$startTime ."
    set gaSet(curTest) $numberedTest
    Status $numberedTest
    set gaSet(fail) ""
    set dutBuffer ""
    #DavicomStartCapture
    AddToLog "Test \'$testName\' started"
    set ret [$testName 1]
#     if {$ret!=0 && $ret!="-2" && $testName!="Mac_BarCode"} {
#       AddToLog "Test $numberedTest fail and rechecked. Reason: $gaSet(fail)"
#       puts "\n **** Rerun - Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n"
#       $gaSet(startTime) configure -text "$startTime .."
#       ##set ret [$testName 2]
#     } 
    puts "\n **** Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n" 
    update
    if {$ret!=0} {
      #break
    }
    if {$ret=="-2"} {
      set gaSet(fail) "User stop"
    }
    
    set retD 0
    if {$ret==0} {
      ## 19/05/2020 12:59:56 
      ## just in case a test finished OK, I will check the Davicom
      set ret [DavicomStopCapture $testName]
    }
    if {$ret!=0 || $retD!=0} {
      if {$retD!=0} {
        set ret $retD
      }
      if {$ret==0} {
        set retTxt "PASS."
      } else {
        set retTxt "FAIL. Reason: $gaSet(fail)"
      }
      AddToLog "Test \'$testName\' $retTxt"
      break    
    }
    if {$gaSet(oneTest)==1} {
      set ret 1
      break
    }
  } 
  if {$ret==0} {
    set logText "All tests pass"
    set retTxt PASS
  } else {
    set logText "Test $numberedTest fail. Reason: $gaSet(fail)" 
    set retTxt FAIL
  } 
  AddToLog "$logText \n    *********   $retTxt   *********\n"
  puts "********* Test finish *********..[MyTime]..\n\n"
    
  set gaSet(oneTest) 0  
  
  return $ret
}      

# ***************************************************************************
# FactoryDefault
# ***************************************************************************
proc FactoryDefault {run} {
  set ret 0

#   25/05/2020 09:12:57
#   set ret [TimeDateSet]
#   if {$ret!=0} {return $ret}
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
  }
  
  set ret [Set2Default not "1 2"]
  if {$ret!=0} {return $ret}
  foreach chs {1 2} {
    set ret [WaitForUp $chs]
    if {$ret<0} {return $ret}
    set mc $ret
    set ret [Login $chs $mc]
    if {$ret!=0} {return $ret}
    
#     25/05/2020 09:13:12
#     set ret [TerminalTimeOut $chs $mc]
#     if {$ret!=0} {return $ret}
  }
  
  return $ret
} 
# ***************************************************************************
# Memory
# ***************************************************************************
proc Memory {run} {
  global gaSet
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
  }
  set ret [MemoryTest]
  if {$ret!=0} {return $ret}
#   Power 1 off
#   Power 2 off
#   after 1000
#   Power 1 on
#   Power 2 on
#   set ret [Wait "Wait for reboot" 40 white]
  return $ret
} 
# ***************************************************************************
# Voltage
# ***************************************************************************
proc Voltage {run} {
  global gaSet
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
  }
  set ret [VoltageTest]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# ID
# ***************************************************************************
proc ID {run} {
  global gaSet
#   foreach chs {1 2} mc {1 2} {
#     set ret [SetPrimaryMC $chs $mc]
#     if {$ret!=0} {return $ret}
#   }
#   set ret [TimeDateSet]
#   if {$ret!=0} {return $ret}
  
  set ret [IDTest]
  if {$ret!=0} {return $ret}
  
#   foreach chs {1 2} mc {1 2} {
#     set ret [Login $chs $mc]
#     if {$ret!=0} {return $ret}
#     set ret [TimeDateCheck $chs $mc]
#     if {$ret!=0} {return $ret}
#   }

  return $ret  
} 
# ***************************************************************************
# TimeDate
# ***************************************************************************
proc TimeDate {run} {
  global gRelayState 
#   set gRelayState red
#   IPRelay-LoopRed
#   set ret [DialogBox -title "TimeDate Test" -message "Remove the REF cards from both chassises" -type "OK Abort" -icon [pwd]/images/info.ico]
#   if {$ret!="OK"} {return -2}
#   IPRelay-Green
#   Power 1 off
#   Power 2 off
#   after 3000
#   Power 1 on
#   Power 2 on
#   set ret [Wait "Wait for reboot" 120 white]
#   if {$ret!=0} {return $ret}
  foreach chs {1 2} mc {1 2} {
#     set ret [SetPrimaryMC $chs $mc]
#     if {$ret!=0} {return $ret}
    set ret [WaitForUp $chs]
    if {$ret<0} {return $ret}
    set mc $ret
    set ret [Login $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [TimeDateCheck $chs $mc]
    if {$ret!=0} {return $ret}
  }
#   set gRelayState red
#   IPRelay-LoopRed
#   set ret [DialogBox -title "TimeDate Test" -message "Insert the REF cards in both chassises" -type "OK Abort" -icon [pwd]/images/info.ico]
#   if {$ret=="OK"} {
#     set ret 0
#   } elseif {$ret!="OK"} {
#     set ret -2
#   } 
  return $ret
} 
# ***************************************************************************
# TimeDateNonStop
# ***************************************************************************
proc TimeDateNonStop {run} {
  global gRelayState 
  foreach chs {1 2} mc {1 2} {
#     set ret [SetPrimaryMC $chs $mc]
#     if {$ret!=0} {return $ret}
    set ret [Login $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [TimeDateCheck $chs $mc]
    if {$ret!=0} {return $ret}
  }
  
  return $ret
} 
# ***************************************************************************
# TdmBus
# ***************************************************************************
proc TdmBusIO {run} {
  global gaSet
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
  }
  set ret [TdmBusTest]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# TdmBusFAN1
# ***************************************************************************
proc TdmBusFAN1 {run} {
  global gaSet
  set ret [SetPrimaryMC 1 1]
  if {$ret!=0} {return $ret}
 
  set ret [TdmBusFanTest 1 1 B]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# TdmBusFAN2
# ***************************************************************************
proc TdmBusFAN2 {run} {
  global gaSet
  set ret [SetPrimaryMC 2 2]
  if {$ret!=0} {return $ret}
 
  set ret [TdmBusFanTest 2 2 A]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# ExternalClock
# ***************************************************************************
proc ExternalClock {run} {
  global gaSet
  RLDxc4::SysConfig $gaSet(idDxc) -srcClk int
  RLDxc4::PortConfig $gaSet(idDxc) E1  -updPort all -frameE1 g732n -balanced yes  
  RLDxc4::BertConfig $gaSet(idDxc) -updPort all -linkType E1 -enabledBerts all\
      -pattern qrss -inserrRate none -inserrBerts all 
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
  }
  set ret [ExtClockMC]
  if {$ret!=0} {return $ret}
   
  return $ret
} 
# ***************************************************************************
# Temperature
# ***************************************************************************
proc Temperature {run} {
  global gaSet
  global gaSet
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
  }
  set ret [TemperatureTest]
  return $ret  
} 
# ***************************************************************************
# Data
# ***************************************************************************
proc DataSetup {run} {
  global gaSet buffer
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
  }
  set ret [ConfigMC]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Wait for IO slots coming up" 30 white]
  if {$ret!=0} {return $ret}
  
  set ret [ConfigEtx220]
  if {$ret!=0} {return $ret}
  
  set ret [ConfigEtxGen]
  if {$ret!=0} {return $ret}
  after 1000
  
  return $ret
}
  
# ***************************************************************************
# DataRun
# ***************************************************************************
proc DataRun {run} {
  global gaSet buffer  aRes
  
  Power 1 on
  Power 2 on
  
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
    set gaSet(fail) ""
    set ret [DisableAlarms $chs $mc]
    if {$ret!=0} {
      if {$gaSet(fail)==""} {
        set gaSet(fail) "Chassis-$chs MC-$mc. Disable Alarms fail"
      }
      return $ret
    }
    set gaSet(fail) ""
    set ret [ClearAlarms $chs $mc]
    if {$ret!=0} {
      if {$gaSet(fail)==""} {
        set gaSet(fail) "Chassis-$chs MC-$mc. Clear Alarms fail"
      }
      return $ret
    }
  }
  
  #DavicomStartCapture

  Etx220Start; #Etx204Start  
  set ret [Etx220ShortLongRun 1 2]  
  if {$ret!=0} {
    #set ret [IoCardsReset]
    #if {$ret!=0} {return $ret}
    #set ret [Etx204ShortLongRun 1]
    if {$ret!=0} {return $ret}
  }
  foreach chs {1 2} mc {1 2} {
    set gaSet(fail) ""
    set ret [ReadAlarms $chs $mc]
    if {$ret!=0} {
      if {$gaSet(fail)==""} {
        set gaSet(fail) "Chassis-$chs MC-$mc. Read Alarms fail"
      }
      return $ret
    }
  } 
  
  Power 1 off
  after 1000
  set ret [Etx220ShortRun "Power inlet A is OFF."]
  if {$ret!=0} {return $ret}
  
  Power 1 on
  after 5000
  Power 2 off
  after 1000
  set ret [Etx220ShortRun "Power inlet B is OFF."]
  if {$ret!=0} {return $ret}
  Etx220Stop ; #Etx204Stop  
  Power 2 on
  after 5000
  
#   set ret [DavicomStopCapture]
#   if {$ret!=0} {return $ret}
  
  set ret [MainActiveStandbyStatus 1 1 2 24 60 A0 A1]
  if {$ret!=0} {return $ret}
  set ret [MainActiveStandbyStatus 2 2 1 24 A0 A0 61]
  if {$ret!=0} {return $ret}
  
#   foreach chs {1 2} mc {1 2} {
#     set ret [Login $chs $mc]
#     if {$ret!=0} {return $ret}
#     set ret [TimeDateCheck $chs $mc]
#     if {$ret!=0} {return $ret}
#   }
  
  return $ret
} 
# ***************************************************************************
# Redundancy
# ***************************************************************************
proc RedundancySetup {run} {
  global gaSet buffer gRelayState
  set ret 0
  set ret [ConfigEtxGen]
  if {$ret!=0} {return $ret}
  
  foreach chs {1 2} mc {2 1} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [SlotsState $chs $mc "shutdown"]
    if {$ret!=0} {return $ret}
    set ret [SlotsState $chs $mc "no shutdown"]
    if {$ret!=0} {return $ret}
  }
  
  Wait "Wait for card's up" 30 white
  
  foreach chs {1 2} mc {2 1} {
    set ret [IoCardsShowStatus $chs $mc]
    if {$ret!=0} {return $ret}
  }
  
  return $ret
}  
  
# ***************************************************************************
# RedundancyRun
# ***************************************************************************
proc RedundancyRun {run} {
  global gaSet buffer gRelayState
  set ret 0
    
  Etx220Start; #Etx204Start  

  foreach chs {1 2} mc {2 1} {
    set ret [DisableAlarms $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [ClearAlarms $chs $mc]
    if {$ret!=0} {return $ret} 
  }   
  set ret [Etx220ShortLongRun 2 1]
  if {$ret!=0} {return $ret} 
  foreach chs {1 2} mc {2 1} {
    set ret [ReadAlarms $chs $mc]
    if {$ret!=0} {return $ret} 
  } 
  Etx220Stop ; #Etx204Stop
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
  }
  Etx220Start; #Etx204Start
  set ret [Etx220ShortRun ""]
  if {$ret!=0} {return $ret}
  Etx220Stop ; #Etx204Stop
  
  return $ret
} 
# ***************************************************************************
# Led
# ***************************************************************************
proc Led {run} {
  global gaSet buffer
  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX5300A-MC-4XFP" "Manual Test"
  
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [LedTest $chs $mc]
    if {$ret!=0} {return $ret}
  }
  
  Etx220Start; #Etx204Start
  set ret [DialogBox -title "Led Test" -message "Verify that ACT and LINK leds at both Main Cards are ON (ACT-YELLOW, LINK=GREEN)" \
      -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret=="Abort"} {return -2}
  
  set ret [DialogBox -title "Led Test" -message "Disconnect from both Main Cards all the cables, except CONTROL and POWER.\n\
      Verify that ACT and LINK leds at both Main Cards are OFF" -type "OK Abort" \
      -icon [pwd]/images/info.ico]
  if {$ret=="Abort"} {return -2}
 
  set ret [Set2Default yes "1 2]   
  return $ret
} 
# ***************************************************************************
# Led1
# ***************************************************************************
proc Led1 {run} {
  global gaSet buffer
  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX5300A-MC-4XFP" "Manual Test"
  
  foreach chs {1} mc {1} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [ActiveMngPort $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [LedTest $chs $mc]
    if {$ret!=0} {return $ret}
  }
 
  
  #Etx220Start; #Etx204Start
  Etx220StartMng
  set ret [DialogBox -title "Chassis-1 MainCard-A Led Test" \
      -message "Verify on 10GbE ports and MNG-ETH port that ACT and LINK leds at\n\
      Chassis-1 MainCard-A are ON (ACT-YELLOW, LINK=GREEN)" \
      -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret=="Abort"} {
    set ret -2
  } else {
    set ret 0
  }
  Etx220StopMng
  
  
#   set ret [DialogBox -title "Led Test" -message "Disconnect from both Main Cards all the cables, except CONTROL and POWER.\n\
#       Verify that ACT and LINK leds at both Main Cards are OFF" -type "OK Abort" \
#       -icon [pwd]/images/info.ico]
#   if {$ret=="Abort"} {return -2}
 
#   Etx220StartMng
#   set ret [ActiveMngPort 1 1]
#   if {$ret!=0} {return $ret}
#   #set ret [Set2Default yes "1"]
#   
#   set ret [DialogBox -title "Led Test" -message "Chassis-1 MC-1. Verify MNG-ETH port's LINK is Green ON and ACT is Orange blinking " -type "OK Abort" \
#       -icon [pwd]/images/info.ico]
#   if {$ret=="Abort"} {return -2}   
  return $ret
} 
# ***************************************************************************
# Led2
# ***************************************************************************
proc Led2 {run} {
  global gaSet buffer
  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX5300A-MC-4XFP" "Manual Test"
  
  foreach chs {2} mc {2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [ActiveMngPort $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [LedTest $chs $mc]
    if {$ret!=0} {return $ret}
  }
  
  #Etx220Start; #Etx204Start
  Etx220StartMng
  #set ret [DialogBox -title "Led Test" -message "Verify that ACT and LINK leds at both Main Cards are ON (ACT-YELLOW, LINK=GREEN)" \
      -type "OK Abort" -icon [pwd]/images/info.ico]
  set ret [DialogBox -title "Chassis-2 MainCard-B Led Test" \
      -message "Verify on 10GbE ports and MNG-ETH port that ACT and LINK leds at\n\
      Chassis-2 MainCard-B are ON (ACT-YELLOW, LINK=GREEN)" \
      -type "OK Abort" -icon [pwd]/images/info.ico]    
  if {$ret=="Abort"} {return -2}
  
  set ret [DialogBox -title "Led Test" -message "Disconnect from both Main Cards all the cables, except CONTROL and POWER.\n\
      Verify that ACT and LINK leds at both Main Cards are OFF" -type "OK Abort" \
      -icon [pwd]/images/info.ico]
  if {$ret=="Abort"} {
    set ret -2
  } else {
    set ret 0
  }
  Etx220StopMng
  
 
#   Etx220StartMng
#   set ret [ActiveMngPort 2 2]
#   if {$ret!=0} {return $ret}
#   #set ret [Set2Default yes "2"]
#   
#   set ret [DialogBox -title "Led Test" -message "Chassis-2 MC-2. Verify MNG-ETH port's LINK is Green ON and ACT is Orange blinking " -type "OK Abort" \
#       -icon [pwd]/images/info.ico]
#   if {$ret=="Abort"} {return -2}   
  return $ret
} 
# ***************************************************************************
# BP
# ***************************************************************************
proc BP-Chassis1 {run} {
  global gaSet buffer
  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX5300A-MC-4XFP" "Manual Test"
  set ret [BpTest 1 1]
  if {$ret!=0} {return $ret}
  return $ret
} 
# ***************************************************************************
# BP-Chassis2
# ***************************************************************************
proc BP-Chassis2 {run} {
  global gaSet buffer
  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX5300A-MC-4XFP" "Manual Test"
  set ret [BpTest 2 2]
  if {$ret!=0} {return $ret}
  return $ret
} 
# ***************************************************************************
# Pages
# ***************************************************************************
proc Pages {run} {
  global gaSet buffer gaGet
  set ret 0
  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX5300A-MC-4XFP" "Manual Test"
  
#   set ret [DialogBox -message "Verify that ACT and LINK leds at both Main Cards are ON (ACT-YELLOW, LINK=GREEN)" -type "OK Abort"]
#   if {$ret=="Abort"} {return -2}
#   
  set ret [DialogBox -title "SW1 init" -message "In both DUTs set SW1,2 to ON (Debug Mode)" -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret=="Abort"} {return -2}
  
  Power 1 off
  Power 2 off
  after 3000
  Power 1 on
  Power 2 on
  
  ## 18/05/2020 12:31:26
#   set ret [ReadBarcode]
#   if {$ret!=0} {return $ret}
  
#  BarcodeOnly -variable gaSet(PageSetupType)  AllPagesWithBarcode
  if {$gaSet(PageSetupType)=="AllPagesWithBarcode"} {
    set ret [GetPageFile]
    if {$ret!=0} {return $ret}
    set p3 $gaGet(page3)
  }
  
  foreach chs {1 2} mc {1 2} {
    set ret [BootDebugMode $chs $mc debug-mode]
    if {$ret!=0} {return $ret}
    
    set ret [CheckBootID $chs $mc]
    if {$ret!=0} {return $ret}
        
    if {[string length $gaSet(barcode$chs)]==11} {
      set gaSet(barcode$chs) ${gaSet(barcode$chs)}0
    }
    
    if {$gaSet(PageSetupType)=="AllPagesWithBarcode"} {
      set p3b [eval lreplace {$p3} 0 13 00 02 [AsciiToHex_Convert_Split $gaSet(barcode$chs)]]      
    } elseif {$gaSet(PageSetupType)=="BarcodeOnly"} {
      set p3b [concat 00 02 [AsciiToHex_Convert_Split $gaSet(barcode$chs)]] 
    }
    puts "MC-$chs. $gaSet(PageSetupType) $p3b"
    set gaGet(page3) $p3b
    
    set ret [WritePages $chs $mc debug-mode]
    if {$ret!=0} {return $ret}
  }
  
  foreach chs {1 2} mc {1 2} {
    foreach mode {bpn1 bpn2 ina inb fan} {
      set ret [BootDebugMode $chs $mc $mode]
      if {$ret!=0} {return $ret}
      set gaGet(page0) [list 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00]
      set gaGet(page3) [set gaGet(page2) [set gaGet(page1) $gaGet(page0)]]
      set ret [WritePages $chs $mc $mode]
      if {$ret!=0} {return $ret}
      set gaGet(page0) [list 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F 20]
      set gaGet(page3) [set gaGet(page2) [set gaGet(page1) $gaGet(page0)]]
      set ret [WritePages $chs $mc $mode]
      if {$ret!=0} {return $ret}
    }
  }
  
  set ret [DialogBox -title "SW1 init" -message "In borh Main Cards set SW1,2 to OFF (Normal Mode)" -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret=="Abort"} {return -2}
  if {$ret=="OK"} {set ret 0}  
  return $ret
}       

# ***************************************************************************
# CpuPhyRGMII
# ***************************************************************************
proc _via5300_CpuPhyRGMII {run} {
  global gaSet
  foreach chs {1 2} {
    set ret [SetPrimaryMC $chs 1]
    if {$ret!=0} {return $ret}  
    set ret [CpuPhyRGMIISet $chs 1]
    if {$ret!=0} {return $ret}
  }  
  foreach chs {1 2} {
    set ret [SetPrimaryMC $chs 2]
    if {$ret!=0} {return $ret}
    set ret [CpuPhyRGMIISet $chs 2]
    if {$ret!=0} {return $ret}
  }
  set ret [CpuPhyRGMIITest 2]
  if {$ret!=0} {return $ret}
  foreach chs {1 2} {
    set ret [SetPrimaryMC $chs 1]
    if {$ret!=0} {return $ret}
    set com $gaSet(comMC.$chs.1)
    set ret [ExitToShell $com $chs 1]
    if {$ret!=0} {return $ret}
  }  
  set ret [CpuPhyRGMIITest 1]
  if {$ret!=0} {return $ret}
  return $ret
} 
# ***************************************************************************
# CpuPhyRGMII
# ***************************************************************************
proc CpuPhyRGMII {run} {
  global gaSet
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}  
  }  
  set ret [CpuPhyRGMIITest]
  if {$ret!=0} {return $ret}
  
  return $ret
} 

# ***************************************************************************
# IOcard
# ***************************************************************************
proc IOcard {run} {
  global gaSet
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}  
  }  
  set ret [IOcardTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# PowerController
# ***************************************************************************
proc PowerController {run} {
  global gaSet
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}  
  }  
  set ret [PowerControllerTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# BridgeSetup
# ***************************************************************************
proc BridgeSetup {run} {
  global gaSet buffer
  foreach chs {1 2} {
    set ret [WaitForUp $chs]
    if {$ret<0} {return $ret}
    set mc $ret
#    set ret [SetPrimaryMC $chs $mc]
#     if {$ret!=0} {return $ret} 
     set ret [Login $chs $mc]
     if {$ret!=0} {return $ret} 
  }
#   foreach chs {1 2} mc {1 2} {
#     set ret [SetPrimaryMC $chs $mc no]
#     if {$ret!=0} {return $ret}  
#   }
  
  set ret [Set2Default not "1 2"]
  if {$ret!=0} {return $ret}
  set ret [Wait "Wait for reboot" 40 white]
  if {$ret!=0} {return $ret}
  
  Power 1 off
  Power 2 off
  after 3000
  Power 1 on
  Power 2 on
  set ret [Wait "Wait for reboot" 240 white]
  if {$ret!=0} {return $ret}
  
  
  set ret [DialogBox -title "Bridge Test" \
      -message "Remove MAIN-B from Chassis-1 and MAIN-A from Chassis-2\n\
      Connect the setup accordingly to FTI's \'Brifge Test\' step" \
      -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret=="Abort"} {return -2}
  
  foreach chs {1 2} {
    set ret [WaitForUp $chs]
    if {$ret<0} {return $ret}
    set mc $ret
    set ret [Login $chs $mc]
    if {$ret!=0} {return $ret} 
  }
#   foreach chs {1 2} mc {1 2} {
#     set ret [SetPrimaryMC $chs $mc]
#     if {$ret!=0} {return $ret}
#   }
  set ret [TimeDateSet]
  if {$ret!=0} {return $ret}
  
  foreach chs {1 2} mc {1 2} {
    set com $gaSet(comMC.$chs.$mc)  
    Status "Chassis-$chs MC-$mc. Download Bridge configuration file ..."
    
    set confFile c:/download/BRIDGE.$mc.txt
    if ![file exists $confFile] {
      set gaSet(fail) "The configuration file confFile doesn't exist"
      return -1
    }
    set s1 [clock seconds]
    set id [open $confFile r]
    set c 0
    while {[gets $id line]>=0} {
      if {$gaSet(act)==0} {close $id ; return -2}
      if {[string length $line]>1 && [string index $line 0]!="#"} {
        incr c
        #puts "line:<$line>"
        set ret [Send $com $line\r [Prompt] 60]
        if {$ret!=0} {
          set gaSet(fail) "Config of MC-$mc at Chassis-$chs failed"
          break
        }
      }
    }
    close $id  
    if {$ret==0} {
      set ret [Send $com "exit all\r" "[Prompt]"]
      set ret [Send $com "save\r" "[Prompt]"]
    
      set s2 [clock seconds]
      puts "[expr {$s2-$s1}] sec c:$c" ; update
    } else {
      return $ret
    }
  }
  
  set ret [ConfigEtxGenBridge]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# BridgeRun
# ***************************************************************************
proc BridgeRun {run} {
#   set ret [ConfigEtxGenBridge]
#   if {$ret!=0} {return $ret}
  
  Etx220StartBridge
  set ret [Etx220ShortLongRunBridge]  
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# FinalFactoryDefault
# ***************************************************************************
proc FinalFactoryDefault {run} {
  set ret [Set2Default not "1 2"]
 return $ret
} 