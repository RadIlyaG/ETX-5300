# ***************************************************************************
# SaveInit
# ***************************************************************************
proc SaveInit {} {
  global gaSet
  if ![file exists [pwd]/[info hostname]] {
    file mkdir [pwd]/[info hostname]
  }
  set id [open [pwd]/[info hostname]/init$gaSet(tester).tcl w]
    puts $id "global gaGui gaSet"
    puts $id "set gaGui(xy) +[winfo x .]+[winfo y .]"
    if {[info exists gaSet(iprelay)]} {
      puts $id "set gaSet(iprelay)   \"$gaSet(iprelay)\""
    }
    
    
    if [info exists gaSet(uutOpt)] {
      puts $id "set gaSet(uutOpt) \"$gaSet(uutOpt)\""
    }
    
    if {![info exists gaSet(logPath)] || ![file exists $gaSet(logPath)]} {
      set gaSet(logPath) c:/logs
    }
    puts $id "set gaSet(logPath) \"$gaSet(logPath)\""
  
  close $id
  
}
# ***************************************************************************
# SaveUutInit
# ***************************************************************************
proc SaveUutInit {fil} {
  global gaSet
  set id [open $fil w]
  puts $id "global gaGui gaSet"
    puts $id "set gaSet(sw)            \"$gaSet(sw)\""
    puts $id "set gaSet(hw)            \"$gaSet(hw)\""
    puts $id "set gaSet(fw)            \"$gaSet(fw)\""
    puts $id "set gaSet(sp)            \"$gaSet(sp)\""
    puts $id "set gaSet(u17)           \"$gaSet(u17)\""
    puts $id "set gaSet(pwrC)          \"$gaSet(pwrC)\""
    puts $id "set gaSet(etx220cnf)     \"$gaSet(etx220cnf)\""
    puts $id "set gaSet(etx5300cnf1)   \"$gaSet(etx5300cnf1)\""
    foreach xfp {1 2 3 4} {
       puts $id "set gaSet(xfp$xfp)  \"$gaSet(xfp$xfp)\""
    }
    puts $id "set gaSet(pageFile)   \"$gaSet(pageFile)\""
    puts $id "set gaSet(boot)            \"$gaSet(boot)\""
    
  
  #puts $id "set gaSet(macIC)      \"$gaSet(macIC)\""
  close $id
}  

#***************************************************************************
#** MyTime
#***************************************************************************
proc MyTime {} {
  return [clock format [clock seconds] -format "%T  %d/%m/%Y"]
}

# ***************************************************************************
# Status
# ***************************************************************************
proc Status {txt {color white}} {
  global gaSet gaGui
  set gaSet(status) $txt
  $gaGui(labStatus) configure -bg $color
  #$gaSet(sstatus) configure -bg $color  -text $txt
  if {$txt!=""} {
    puts "\n ..... $txt ..... /* [MyTime] */ \n"
  }
  update
}

# ***************************************************************************
# OpenRL
# ***************************************************************************
proc OpenRL {} {
  global gaSet
  set gaSet(fail) ""
  CloseRL
  
  RLTime::Delay 1
  
  RLEH::Open

  Status "Opening RelayBox..." 
  Open[set gaSet(pioType)]Pio
    
  Status "Opening DXC..."
  set gaSet(idDxc) [RLDxc4::Open $gaSet(comDXC) -package RLCom]
  if {$gaSet(idDxc)<0} {set gaSet(fail) "Can't open Dxc4 COM-$gaSet(comDXC)"; return $gaSet(idDxc)}
  Status "Opening EtxGen..."
  
#   set gaSet(id204) [RLEtxGen::Open $gaSet(com204) -package RLSerial]
#   if {$gaSet(id204)<0} {set gaSet(fail) "Cann't open Etx-204 COM-$gaSet(com204)"; return $ret}  
  
  set ret [ComOpen]
  if {$ret!=0} {return $ret}
  
  Status "Opening COM-$gaSet(com220)..."
  set gaSet(id220)  [RL10GbGen::Open $gaSet(com220)]
  set ret [RL10GbGen::Init $gaSet(id220)]
#   set ret [RLSerial::Open $gaSet(com220) 115200 n 8 1]
  if {$ret!=0} {set gaSet(fail) "Can't open COM-$gaSet(com220)"; return $ret}
  
  return $ret
  
}
# ***************************************************************************
# CloseRL
# ***************************************************************************
proc CloseRL {} {
  global gaSet
  catch {RL[set gaSet(pioType)]Pio::Close $gaSet(idRB1)}
  catch {RL[set gaSet(pioType)]Pio::Close $gaSet(idRB2)}
  catch {RLDxc4::CloseAll}
  ComClose  
  catch {RLEtxGen::CloseAll}
#   catch {RLSerial::Close $gaSet(com220)}
  catch {RL10GbGen::CloseAll}
  catch {RLEH::Close}
}
# ***************************************************************************
# ComOpen
# ***************************************************************************
proc ComOpen {} {
  global gaSet
  foreach chs {1 2} {
    set ::DavicomBuffer$chs ""
    foreach mc {1 2 d} {
      Status "Opening COM-$gaSet(comMC.$chs.$mc) of Chassis-$chs MC-$mc ..."
      set ret [RLSerial::Open $gaSet(comMC.$chs.$mc) 9600 n 8 1]
      if {$ret!=0} {
        set gaSet(fail) "Can't open COM-$gaSet(comMC.$chs.$mc) of Chassis-$chs MC-$mc"
        return $ret
      }
    }
  }
  return $ret
}
# ***************************************************************************
# ComClose
# ***************************************************************************
proc ComClose {} {
  global gaSet
  foreach chs {1 2} {
    foreach mc {1 2 d} {
      catch {RLSerial::Close $gaSet(comMC.$chs.$mc)}
    }
  }
}
# ***************************************************************************
# OpenExPio
# ***************************************************************************
proc OpenExPio {} {
  global gaSet
  foreach rb {1 2} {    
    set gaSet(idRB$rb)  [RL[set gaSet(pioType)]Pio::Open $gaSet(pioRB$rb) RBA]
    if {$gaSet(idRB$rb)<0} {set gaSet(fail) "Can't open RL[set gaSet(pioType)]Pio-$gaSet(pioRB$rb) "; return $ret}
    #after 1000
    RL[set gaSet(pioType)]Pio::Set $gaSet(idRB$rb) 1
  }
}
# ***************************************************************************
# OpenUsbPio
# ***************************************************************************
proc OpenUsbPio {} {
  global gaSet descript
  set channel [RetriveUsbChannel]
  if {$channel=="-1"} {
    return -1
  }
  foreach rb {1 2} {
    set gaSet(idRB$rb) [RLUsbPio::Open $rb RBA $channel]
  }
return 0
}
# ***************************************************************************
# RetriveUsbChannel
# ***************************************************************************
proc RetriveUsbChannel {} {
  global gaSet
  # parray ::RLUsbPio::description *Ser*
  set boxL [lsort -dict [array names ::RLUsbPio::description]]
  if {[llength $boxL]!=7} {
    set gaSet(fail) "Not all USB ports are open. Please close and open the GUIs again"
    return -1
  }
  foreach nam $boxL {
    if [string match *Ser*Num* $nam] {
      foreach {usbChan serNum} [split $nam ,] {}
      set serNum $::RLUsbPio::description($nam)
      puts "usbChan:$usbChan serNum: $serNum"      
      if {$serNum==$gaSet(pioBoxSerNum)} {
        set channel $usbChan
        break
      }
    }  
  }
  puts "serNum:$serNum channel:$channel"
  return $channel
}

# ***************************************************************************
# AddToLog
# ***************************************************************************
proc AddToLog {line} {
  global gaSet
  set logFileID [open $gaSet(logFile) a+]
  puts $logFileID "..[MyTime]..$line"
  close $logFileID
}
# ***************************************************************************
# ShowLog
# ***************************************************************************
proc ShowLog {} {
	global gaSet
	exec notepad $gaSet(logFile) &
}

# ***************************************************************************
# mparray
# ***************************************************************************
proc mparray {a {pattern *}} {
  upvar 1 $a array
  if {![array exists array]} {
	  error "\"$a\" isn't an array"
  }
  set maxl 0
  foreach name [lsort -dict [array names array $pattern]] {
	  if {[string length $name] > $maxl} {
	    set maxl [string length $name]
  	}
  }
  set maxl [expr {$maxl + [string length $a] + 2}]
  foreach name [lsort -dict [array names array $pattern]] {
	  set nameString [format %s(%s) $a $name]
	  puts stdout [format "%-*s = %s" $maxl $nameString $array($name)]
  }
  update
}

#***************************************************************************
#** Power
#***************************************************************************
proc Power {ps state} {
  global gaSet 
  Status "PS-$ps POWER [string toupper $state]" 
  set ret 0
  set rb $ps
  #$gaSet(tbrun)  configure -state disabled  
  #$gaSet(tbstop) configure -state disabled 
  switch -exact -- $state {
    on  {
	    #puts "PS-$ps POWER ON"	   
      RL[set gaSet(pioType)]Pio::Set $gaSet(idRB$rb) 1
      #set ret [Wait $gaSet(modemBoot) [WaitText cardReset]]
      if {$ret!=0} {return $ret}
    } 
	  off {
	    #puts "PS-$ps POWER OFF"
	    RL[set gaSet(pioType)]Pio::Set $gaSet(idRB$rb) 0
		  set ret 0
    }
    fast  {
	    #puts "PS-$ps POWER ON"	   
	    RL[set gaSet(pioType)]Pio::Set $gaSet(idRB$rb) 1     
    }
  }
  #$gaSet(tbrun)  configure -state disabled 
  #$gaSet(tbstop) configure -state normal
  Status ""
  update
  #exec C:\\RLFiles\\Btl\\beep.exe &
  return $ret
}

#***************************************************************************
#** ToolPower
#***************************************************************************
proc ToolPower {rbL mode} {
  global gaSet
  Tool[set gaSet(pioType)]Power $rbL $mode
}
# ***************************************************************************
# ToolUsbPower
# ***************************************************************************
proc ToolUsbPower {rbL mode} {
  global gaSet
  RLEH::Open
  RLUsbPio::GetUsbChannels descript
  set channel [RetriveUsbChannel]
  if {$channel!="-1"} {
    foreach rb $rbL {
      set gaSet(idRB$rb) [RLUsbPio::Open $rb RBA $channel]
      puts "rb:<$rb> id:<$gaSet(idRB$rb)>"
      Power $rb $mode
      RLUsbPio::Close $gaSet(idRB$rb)
    }   
  }
  RLEH::Close
  
  after 3000
}
# ***************************************************************************
# ToolExPower
# ***************************************************************************
proc ToolExPower {rbL mode} {
  global gaSet
  foreach rb $rbL {
    set gaSet(idRB$rb) [RL[set gaSet(pioType)]Pio::Open $gaSet(pioRB$rb) RBA]
    Power $rb $mode 
    catch {RL[set gaSet(pioType)]Pio::Close $gaSet(idRB$rb)}
  } 
  after 3000
}

# ***************************************************************************
# Send
# ***************************************************************************
proc Send {com sent expected {timeOut 8}} {
  global buffer gaSet
  if {$gaSet(act)==0} {return -2}

  #set cmd [list RLSerial::SendSlow $com $sent 100 buffer $expected $timeOut]
  set cmd [list RLSerial::Send     $com $sent buffer $expected $timeOut]
  ##set cmd [list RLCom::Send $com $sent buffer $expected $timeOut]
  foreach car [split $sent ""] {
    set asc [scan $car %c]
    #puts "car:$car asc:$asc" ; update
    if {[scan $car %c]=="13"} {
      append sentNew "\\r"
    } else {
      append sentNew $car
    }
  }
  set sent $sentNew
  set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
  if {([string match {*command not recognized*} $buffer]) && \
      ([string match {*logon debug*} $sent]==0) && \
      ($com==$gaSet(comMC.1.1) || $com==$gaSet(comMC.1.2) ||\
      $com==$gaSet(comMC.2.1) || $com==$gaSet(comMC.2.2) || \
      $com==$gaSet(comMC.1.d)|| $com==$gaSet(comMC.2.d))} {
    regsub -all [format %c 0] $buffer "" buffer
    regsub -all -- {\x1B\x5B..\;..H} $buffer " " b1
    regsub -all -- {\x1B\x5B..\;..r} $b1 " " b1
    regsub -all -- {\x1B\x5B.J} $b1 " " b1
    set re \[\x1B\x0D\]
    regsub -all -- $re $b1 " " b2
    #regsub -all -- ..\;..H $b1 " " b2
    regsub -all {\s+} $b2 " " b3
    puts "\nsend: com:$com, sent=$sent, expected=$expected,  ret:$ret, tt:$tt, \[Send $com $sent $expected $timeOut\] buffer=$b3\n"
    update
    puts "\nSECOND SEND !!!\n"
    update
    after 1000
    RLSerial::Send  $com \r buffer stam 1
    after 1000
    set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
    if {[string match {*command not recognized*} $buffer]} {
      set ret -1
    }
  } 
  regsub -all [format %c 0] $buffer "" buffer
  regsub -all -- {\x1B\x5B..\;..H} $buffer " " b1
  regsub -all -- {\x1B\x5B..\;..r} $b1 " " b1
  regsub -all -- {\x1B\x5B.J} $b1 " " b1
  set re \[\x1B\x0D\]
  regsub -all -- $re $b1 " " b2
  #regsub -all -- ..\;..H $b1 " " b2
  regsub -all {\s+} $b2 " " b3
  
  #puts "\nsend: ----------------------------------------"
  puts "\n\[Send $com \"$sent\" \"$expected\" $timeOut\] ret:$ret, tt:$tt, buffer=$b3\n"
  #puts "send: ----------------------------------------\n"
  update
  
  RLTime::Delayms 50
  return $ret
}
# ***************************************************************************
# WaitFor
# ***************************************************************************
proc WaitFor {com buffN expected  {timeout 10}} {
  global $buffN gaSet
  if {$gaSet(act)==0} {return -2}
  #if [file exists RLSerial::vaSerial($com.id)] { }
    set cmd [list RLSerial::Waitfor $com $buffN $expected $timeout]
    set tt [expr [lindex [time {set ret [eval $cmd]}] 0]/1000000.0]
    puts "\[WaitFor $com $buffN $expected $timeout\] , [MyTime] ,tt:${tt}sec, ret:$ret Received:<[set $buffN]>" ; update
  
  return $ret    
}
# ***************************************************************************
# InitEtxGen
# ***************************************************************************
proc InitEtxGen {} {
  global gaSet
  Status "Opening EtxGen..."
  set gaSet(id204) [RLEtxGen::Open $gaSet(com204) -package RLSerial]
  ConfigEtxGen
  Status Done
  catch {RLEtxGen::CloseAll}
}


# ***************************************************************************
# Wait
# ***************************************************************************
proc Wait {txt count color} {
  global gaSet
  puts "\nStart Wait $txt $count.....[MyTime]"; update
  Status "$txt ($count sec)" $color 
  for {set i $count} {$i > 0} {incr i -1} {
    if {$gaSet(act)==0} {return -2}
    if {$gaSet(waitBreak)==1} {set gaSet(waitBreak) 0; break}
	  $gaSet(runTime) configure -text $i
	  RLTime::Delay 1
  }
  $gaSet(runTime) configure -text ""
  Status "" 
  puts "Finish Wait $txt $count.....[MyTime]\n"; update
  return 0
}


# ***************************************************************************
# WaitBreak
# ***************************************************************************
proc WaitBreak {} {
  global gaSet
  set gaSet(waitBreak) 1
}


# ***************************************************************************
# ShortRunDxc4
# ***************************************************************************
proc ShortRunDxc4 {txt port} {
  global gaSet
  set id $gaSet(idDxc)
  RLDxc4::Start $gaSet(idDxc)  bert 
  RLDxc4::Clear $gaSet(idDxc)  bert $port
  after 3000
  RLDxc4::Clear $gaSet(idDxc)  bert $port
  set short 10
  #Status "Power inlet A OFF. Run $short sec."
  set ret [Wait "$txt Run $short sec.." $short white]
  if {$ret!=0} {return $ret}
  set ret [Dxc4Check $port $txt]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# Dxc4Check
# ***************************************************************************
proc Dxc4Check {port txt} {
  global gaSet aRes
  set id $gaSet(idDxc)
  set ret 0
  RLDxc4::Stop $id bert
  after 1000
  RLDxc4::GetStatistics $gaSet(idDxc)  aRes  -statistic bertStatis -port $port
    
  mparray aRes *Port$port
  foreach stat {errorBits errorSec syncLoss} {
    set res $aRes(id$id,[set stat],Port$port)
    if {$res!=0} {
      set gaSet(fail) "$txt The $stat in Port-$port is $res. Should be 0"
      return -1
    }
  }
  foreach stat {runTime} {
    set res $aRes(id$id,[set stat],Port$port)
    if {$res==0} {
      set gaSet(fail) "$txt The $stat in Port-$port is 0. Should be more"
      return -1
    }
  }
 
  return $ret
}
# ***************************************************************************
# ExtClockMC
# ***************************************************************************
proc ExtClockMC {} {
  global gaSet
  foreach chs {1 2} mc {1 2} {
    if {$chs=="1"} {
      set bertBal 1
      set bertUnBal 2    
    } elseif {$chs=="2"} {
      set bertBal 3
      set bertUnBal 4
    }
    set comMC $gaSet(comMC.$chs.$mc)
    RLDxc4::PortConfig $gaSet(idDxc) E1 -balanced yes 
    set ret [StationClk $chs $mc balanced]
    if {$ret!=0} {return $ret}  
    set ret [ShortRunDxc4 "Chassis-$chs MC-$mc ExtClock Balanced." $bertBal]
    if {$ret!=0} {return $ret}  
  
    RLDxc4::PortConfig $gaSet(idDxc) E1 -balanced no 
    set ret [StationClk $chs $mc unbalanced]
    if {$ret!=0} {return $ret}  
    set ret [ShortRunDxc4 "Chassis-$chs MC-$mc ExtClock UnBalanced." $bertUnBal]
    if {$ret!=0} {return $ret}
  }     
  return $ret
}
# ***************************************************************************
# DavicomStartCapture
# ***************************************************************************
proc _DavicomStartCapture {} {
  global gaSet
  
  set gaSet(DavicomCaptureEn) 1
  foreach chs {1 2} {
    set ::DavicomBuffer$chs ""      
  } 
  set ret [DavicomRead]
  return $ret
}
# ***************************************************************************
# DavicomRead
# ***************************************************************************
proc DavicomRead {} {
  global gaSet davBuff
  if {$gaSet(DavicomCaptureEn)=="1"} {
    foreach chs {1 2} {
      set com $gaSet(comMC.$chs.d)
      WaitFor $com davBuff stam 1
      append ::DavicomBuffer$chs $davBuff      
    } 
  }    
  #set gaSet(DavicomCaptureAfterId) [after 10000 DavicomRead]
}

# ***************************************************************************
# DavicomStopCapture
# ***************************************************************************
proc DavicomStopCapture {testName} {
  global gaSet davBuff davBuff1 davBuff2  
  puts "DavicomStopCapture $testName"
  
  #DialogBox -icon [pwd]/images/info.ico -type ok -message "Switch the card"
  
  switch -glob -- $testName {
    *Factory* - *aSetup* - *Redun* - *Exter* - *BP* - *Led* - *Pages* - *TdmBus* - *Cpu* -\
    *Volt* - *Mem* - *ID* - *Temp* - *IOcard* - *PowerCo* - *TimeDate* - *Pages* - *Bridge*  {
      ## don't check Davicom, just clear the COM's buffer    
      foreach chs {1 2} {
        set com $gaSet(comMC.$chs.d)
        WaitFor $com davBuff$chs stam 1
      }
      if {[string match *Factory* $testName]==1} {
        foreach chs {1 2} {
          puts "dav $chs len:[string length [set davBuff$chs]]" ; update
          if {[string length [set davBuff$chs]]==0} {
            set gaSet(fail) "The DAVICOM of Chassis-$chs doesn't work"
            return -1
          }
        }
      } else {
        return 0
      }
    }
  }
  #set gaSet(DavicomCaptureEn) 0  
  #after cancel $gaSet(DavicomCaptureAfterId)
  
  if ![file exists c:/tmpDir] {
    catch {file mkdir c:/tmpDir}
  }
  foreach chs {1 2} {
    set buffeFile$chs c:/tmpDir/[set ::davicomTime]_Davicom$chs.txt
    if {![file exists [set buffeFile$chs]]} {
      set id [open c:/tmpDir/[set ::davicomTime]_Davicom$chs.txt w+]
      close $id
      after 250  
    }
  }
  
  foreach chs {1 2} {
    set com $gaSet(comMC.$chs.d)
    WaitFor $com davBuff stam 1
    append ::DavicomBuffer$chs $davBuff 
    set id [open [set buffeFile$chs] a]
      puts $id "\n[MyTime] After test \'$testName\'"
      puts $id [set ::DavicomBuffer$chs]
    close $id
    puts "::DavicomBuffer${chs}\n[set ::DavicomBuffer$chs]"  
  }
  foreach chs {1 2} {  
    foreach fail {"I2C line"  "HW-CON - INT_HANDLER_DISP_IRQ3_UNMASK 50001" \
                      "HW-CON - INT_HANDLER_DISP_IRQ3_UNMASK 50002" \
                      "HW-CON - INT_HANDLER_DISP_IRQ3_UNMASK 50003" \
                      "HW-CON - INT_HANDLER_DISP_IRQ3_UNMASK 50004" \
                      "HW-CON - INT_HANDLER_DISP_IRQ3_UNMASK 60001" \
                      "HW-CON - INT_HANDLER_DISP_IRQ3_UNMASK 60002" \
                      "HW-CON - INT_HANDLER_DISP_IRQ3_UNMASK 60003" \
                      "HW-CON - INT_HANDLER_DISP_IRQ3_UNMASK 60004"} {                                         
      if {[string match "*$fail*" [set ::DavicomBuffer$chs] ] == 1} {
        set gaSet(fail) "The \'$fail\' message is appearing at Chassis-$chs"
        return -1
      }                  
    }    
  }
  return 0
}

# ***************************************************************************
# GetDbrName
# ***************************************************************************
proc GetDbrName {chs mc} {
  global gaSet gaGui
  set uut $mc
  #set barcode $gaSet(barcode$uut)
  set barcode [set gaSet(barcode$uut) [string toupper $gaSet(barcode$uut)]] ; update
  Status "Get DBR name of the Chassis-$chs MC-$mc ($barcode)"
  
  if [file exists MarkNam_$barcode.txt] {
    file delete -force MarkNam_$barcode.txt
  }
  wm title . "$gaSet(tester) : "
  after 500
  
  catch {exec java -jar $::RadAppsPath/OI4Barcode.jar $barcode} b
  set fileName MarkNam_$barcode.txt
  after 1000
  if ![file exists MarkNam_$barcode.txt] {
    set gaSet(fail) "File $fileName is not created. Verify the Barcode"
    #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
    RLSound::Play failbeep
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  
  set fileId [open "$fileName"]
    seek $fileId 0
    set res [read $fileId]    
  close $fileId
  
  #set txt "$barcode $res"
  set txt "[string trim $res]"
  #set gaSet(entDUT) $txt
  set gaSet(entDUT) ""
  puts <$txt>
  
  set initName [regsub -all / $res .]
  set gaSet(DutFullName.$mc) $res
  set gaSet(DutInitName.$mc) $initName.tcl
  
  file delete -force MarkNam_$barcode.txt
  #file mkdir [regsub -all / $res .]
  
  return 0
}

# ***************************************************************************
# RetriveDutFam
# ***************************************************************************
proc RetriveDutFam {} {
  global gaSet 
  set gaSet(dutFam) GA 
  
  puts "DutFam:$gaSet(dutFam)" ; update
}                               
# ***************************************************************************
# OpenTeraTerm
# ***************************************************************************
proc OpenTeraTerm {comName} {
  global gaSet
  puts "OpenTeraTerm \'$comName\'"
  set path1 C:\\Program\ Files\\teraterm\\ttermpro.exe
  set path2 C:\\Program\ Files\ \(x86\)\\teraterm\\ttermpro.exe
  if [file exist $path1] {
    set path $path1
  } elseif [file exist $path2] {
    set path $path2  
  } else {
    puts "no teraterm installed"
    return {}
  }
  if {[string match *comMC* $comName] || [string match *Dls* $comName]} {
    set baud 9600
  } else {
    set baud 115200
  }
  set tit Com
  regexp {com([\d\w\.]+)\)} $comName ma tit
  exec $path /c=[set $comName] /baud=$baud /W="$tit" &
  return {}
}  
# *********

# ***************************************************************************
# UpdateInitsToTesters
# ***************************************************************************
proc UpdateInitsToTesters {} {
  global gaSet
  set sdl [list]
  set unUpdatedHostsL [list]
  set hostsL [list at-5300-1-w10 at-5300-2-w10 soldlogsrv1-10]
  set initsPath ETX5300A-MC-4XFP/software/uutInits
#   set usDefPath ""
  
  set s1 c:/$initsPath
#   set s2 c:/$usDefPath
  foreach host $hostsL {
    if {$host!=[info host]} {
      set dest //$host/c$/$initsPath
      if [file exists $dest] {
        lappend sdl $s1 $dest
      } else {
        lappend unUpdatedHostsL $host        
      }
      
#       set dest //$host/c$/$usDefPath
#       if [file exists $dest] {
#         lappend sdl $s2 $dest
#       } else {
#         lappend unUpdatedHostsL $host        
#       }
    }
  }
  
  set msg ""
  set unUpdatedHostsL [lsort -unique $unUpdatedHostsL]
  if {$unUpdatedHostsL!=""} {
    append msg "The following PCs are not reachable:\n"
    foreach h $unUpdatedHostsL {
      append msg "$h\n"
    }  
    append msg \n
  }
  if {$sdl!=""} {
    if {$gaSet(radNet)} {
      set emailL {ilya_g@rad.com}
    } else {
      set emailL [list]
    }
    set ret [RLAutoUpdate::AutoUpdate $sdl]
    set updFileL    [lsort -unique $RLAutoUpdate::updFileL]
    set newestFileL [lsort -unique $RLAutoUpdate::newestFileL]
    if {$ret==0} {
      if {$updFileL==""} {
        ## no files to update
        append msg "All files are equal, no update is needed"
      } else {
        append msg "Update is done"
        if {[llength $emailL]>0} {
          RLAutoUpdate::SendMail $emailL $updFileL  "file://R:\\IlyaG\\5300"
          if ![file exists R:/IlyaG/5300] {
            file mkdir R:/IlyaG/5300
          }
          foreach fi $updFileL {
            catch {file copy -force $s1/$fi R:/IlyaG/5300 } res
            puts $res
          }
        }
      }
      tk_messageBox -message $msg -type ok -icon info -title "Tester update" ; #DialogBox icon /images/info
    }
  } else {
    tk_messageBox -message $msg -type ok -icon info -title "Tester update"
  } 
}


