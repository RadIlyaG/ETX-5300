# ***************************************************************************
# Login
# ***************************************************************************
proc Login {chs mc} {
  puts "Login $chs $mc [MyTime]" ; update
  global gaSet buffer
  set ret -1
  Status "Login to MC-$mc of Chassis-$chs"
  $gaSet(amc) configure -text $chs.$mc
  set com $gaSet(comMC.$chs.$mc)
  Send $com "exit\r" stam 0.5
  Send $com "exit\r\r" stam 0.5
  Send $com "exit\r\r" stam 0.5
  foreach taam {1 2} {
    foreach paam {1 2 3 4 5} {
      puts "login: $taam $paam" ; update 
      Send $com "\r" stam 1
      if {[string match {*ogin failed*} $buffer]==1} {
        set ret [Send $com "su\r" password 1]
        if {$ret==0} {
          set ret [Send $com "1234\r" [Prompt] 1]
          break        
        }
      }
      if {[string match {*password*} $buffer]==1 || [string match {*user>*} $buffer]==1} {
        set ret [Send $com "\rsu\r" password 1]
        if {$ret==0} {
          set ret [Send $com "1234\r" [Prompt] 1]  
          break      
        }
      }
      if {[string match *[Prompt]* $buffer]==1} {
        set ret [Send $com "exit all\r\r" [Prompt] 4]
        break
      }
    }
    if {$ret==0} {break}
    set ret [Wait "Wait for Login" 15 white]
    if {$ret!=0} {break}
  }
  
  if {$gaSet(act)==0} {return -2}
  if {$ret!=0} {
    set gaSet(fail) "Can't Login to MC-$mc of Chassis-$chs"
    return $ret
  }
  
  return $ret
}
# ***************************************************************************
# ExitToShell
# ***************************************************************************
proc ExitToShell {com chs mc} {
  global gaSet buffer
  puts "ExitToShell $com $chs $mc [MyTime]" ; update
  set ret [Send $com "exit\r\r\r" [Prompt]]
  if {[string match *[Prompt]* $buffer]==1} {
    Send $com "logon debug\r" "ode" 2
    if {[string match {*cli error: command not recognized*} $buffer]==1} {
      ## the mc is after logon step, so don't do anything
      set ret 0
    } else {
      regexp {code:\s+(\d+)\s} $buffer - keyCode
      catch {exec $::RadAppsPath/atedecryptor.exe $keyCode pass} password
      set ret [Send $com "$password\r" [Prompt] 1]
      if {[string match {*Login failed*} $buffer]==1} {
        set ret -1
      }
    } 
    if {$ret==0} {
      set ret [Send $com "debug shell\r\r\r" >] 
      set ret [Send $com "\r" >]
      set ret [Send $com "\r" >]
    }
    #set ret 0
  }
  if {$ret!=0} {
    set gaSet(fail) "Communication with Chassis-$chs MC-$mc fail"
  }
  return $ret
}
# ***************************************************************************
# Login220
# ***************************************************************************
proc Login220 {} {
  global gaSet buffer
  puts "Login220 [MyTime]" ; update
  set ret -1
  Status "Login to ETX-220"
  set com $gaSet(com220)
  Send $com "exit\r" user 0.5
  Send $com "\r" user 0.5
  if {[string match {*ogin failed*} $buffer]==1} {
    set ret [Send $com "su\r" password 1]
    if {$ret==0} {
      set ret [Send $com "1234\r" 220 1]        
    }
  }
  if {[string match {*password*} $buffer]==1} {
    set ret [Send $com "\rsu\r" password 1]
    if {$ret==0} {
      set ret [Send $com "1234\r" 220 1]        
    }
  }
  if {[string match *220* $buffer]==1} {
    set ret [Send $com "exit all\r" 220 1]
    set ret 0
  }
  
  if {$gaSet(act)==0} {return -2}
  if {$ret!=0} {
    set gaSet(fail) "Can't Login to ETX-220"
    break
  }

  return $ret
}

# ***************************************************************************
# VoltageTest
# ***************************************************************************
proc VoltageTest {} {
  global gaSet buffer
  puts "VoltageTest [MyTime]" ; update
  
  foreach chs {1 2} mc {1 2} {
    set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
    Status "Voltage Test of MC-$mc at Chassis-$chs"
    set com $gaSet(comMC.$chs.$mc)
    set ret [ExitToShell $com $chs $mc]
    if {$ret!=0} {
      set ret [ExitFromShell $com $chs $mc]
      if {$ret==0} {
        set ret [ExitToShell $com $chs $mc]
        if {$ret!=0} {return $ret}
      } else {
        return $ret
      }
    }
    set ret [Send $com "rd8_add 0xf8100069\r" >]
    if {$ret!=0} {return $ret}
    set ret [regexp {data =\s+(\w+)\s} $buffer - dutVal]
    if {$ret==0 || $dutVal!="ff"} {
      set gaSet(fail) "Chassis-$chs MC-$mc. The data of 0xf8100069 is $dutVal. Should be ff" ; # ff
      return -1
    }
    
    set ret [Send $com "rd8_add 0xf810006A\r" >]
    if {$ret!=0} {return $ret}
    set ret [regexp {data =\s+(\w+)\s} $buffer - dutVal]
    if {$ret==0 || $dutVal!="ff"} {
      set gaSet(fail) "Chassis-$chs MC-$mc. The data of 0xf810006A is $dutVal. Should be ff" ; # ff
      return -1
    }
    
    set ret [Send $com "rd8_add 0xf810006B\r" >]
    if {$ret!=0} {return $ret}
    set ret [regexp {data =\s+(\w+)\s} $buffer - dutVal]
    if {$ret==0 || $dutVal!="7"} {
      set gaSet(fail) "Chassis-$chs MC-$mc. The data of 0xf810006B is $dutVal. Should be 7" ; # 7
      return -1
    }  
    
    set ret [ExitFromShell $com $chs  $mc]
    if {$ret!=0} {return $ret}                   
    
  }  
  return $ret  
}

# ***************************************************************************
# proc IDTest
# ***************************************************************************
proc IDTest {} {
  puts "IDTest [MyTime]" ; update  
  global gaSet buffer buf
  foreach chs {1 2} mc {1 2} mcn {a b} {
    set com $gaSet(comMC.$chs.$mc)  
    
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
  
    Status "ID Test of MC-$mc at Chassis-$chs"
    set ret [Send $com "exit all\r" "[Prompt]"]
    if {$ret!=0} {
      set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
      return $ret
    }
    set ret [Send $com "config\r" "config"]
    if {$ret!=0} {
      set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
      return $ret
    }
    set ret [Send $com "chassis\r" "chassis"]
    if {$ret!=0} {
      set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
      return $ret
    }
    set ret [Send $com "show summary-inventory\r\r\r\r\r" "chassis#" 15]  
    if {$ret!=0} {
      set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
      return $ret
    }
    regexp { Main Card A\s+([\w\.\/\-]+)\s+([\w\.\)\(]+)\s+([\w\.]+)[\s\w]+Main Card B\s+([\w\.\/\-]+)\s+([\w\.\)\(]+)\s+([\w\.]+)\s } $buffer - hw1 sw1 fw1 hw2 sw2 fw2
    if {[set hw$mc] != [string trim $gaSet(hw)]} {
      set gaSet(fail) "Chassis-$chs MC-$mc. The \'HW\' is [set hw$mc]. Should be [string trim $gaSet(hw)]"
      set ret -1
    } else {
      if {[set sw$mc]!=[string trim $gaSet(sw)]} {
        set gaSet(fail) "Chassis-$chs MC-$mc. The \'SW\' is [set sw$mc]. Should be [string trim $gaSet(sw)]"
        set ret -1
      } else {
        if {[set fw$mc]!=[string trim $gaSet(fw)]} {
          set gaSet(fail) "Chassis-$chs MC-$mc. The \'FW\' is [set fw$mc]. Should be [string trim $gaSet(fw)]"
          set ret -1
        } else {
          set ret 0
        }
      }
    }
    if {$ret==0} {
      set ret [Send $com "exit\r" "config"]
      if {$ret!=0} {
        set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
        return $ret
      }
      set ret [Send $com "port\r" "port"]
      if {$ret==0} {
        for {set eth 1} {$eth<=4} {incr eth} {
          set ret [Send $com "eth main-$mcn/$eth\r" "main-$mcn"]
          if {$ret==0} {
            set buf ""
            set ret [Send $com "show sfp-status\r" more]
            append buf $buffer
            set ret [Send $com "\r" [Prompt]]
            if {$ret!=0} {}
            if 1 {
              for {set sss 1} {$sss<=10} {incr sss} {
                puts "[MyTime] sss:$sss" ; update
                Send $com "\r\r" [Prompt] 2
                Send $com "\r\r" [Prompt] 2
                set buf ""
                set ret [Send $com "show sfp-status\r" more]
                append buf $buffer
                set ret [Send $com "\r" [Prompt]]
                if {$ret==0 && [string match *Fiber* $buf]} {break}
                set ret [Wait "Wait for IO-$eth up" 10 white]
                if {$ret!=0} {return $ret}
              }
              puts "after sss loop ret:<$ret> sss:<$sss>"; update
            }
            if {$ret==0} {
              puts "buf:<$buf>" ; update
              set ret [regexp {Meter\)[\:\s]+(\d+)[\w\s\(\)]+:\s+([\s\w\d\.]+)\s+Fiber[\w\s]+\:\s+(\w+)} $buf - ra le fi]
              if {$ret==1} {
                set ret 0
                set ra [string trim $ra]
                set le [string trim $le]
                set fi [string trim $fi]
                set xfp$eth [set ra]_[set le]_[set fi]
                puts "mc-$mc eth:$eth ra:$ra le:$le fi:$fi xfp$eth:[set xfp$eth] gaSet(xfp$eth):$gaSet(xfp$eth)"
                if {[set xfp$eth] != $gaSet(xfp$eth)} {
                  set gaSet(fail) "Chassis-$chs MC-$mc. Eth port $eth. XFP is [set xfp$eth]. Should be $gaSet(xfp$eth)"
                  set ret -1
                  break
                }
                Send $com "\r\r" [Prompt] 2
                Send $com "\r\r" [Prompt] 2
                Send $com "\r\r" [Prompt] 2
                Send $com "exit\r" "port" 2   
              } else {
                set xfp$eth "No SFP status"
                set gaSet(fail) "Chassis-$chs MC-$mc. Eth port $eth. XFP is [set xfp$eth]. Should be $gaSet(xfp$eth)"
                set ret -1
                break
              }
            } else {
              set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
              return $ret
            }           
          } 
        }  
      }
    }
    if {$ret!=0} {return $ret}
    
    set ret [GetDbrName $chs $mc]
    if {$ret!=0} {return $ret}
    if {[string match *.H.tcl* $gaSet(DutInitName.$mc)]} {
      set dbrHarden "YES"
    } else {
      set dbrHarden "NO"
    }
    
    Send $com "exit all\r" "[Prompt]" 2
    Send $com "config chassis\r" "[Prompt]" 2
    Send $com "show manufacture-info all\r" "stam" 2
    set buff $buffer
    Send $com "\r" "[Prompt]" 2
    append buffer $buff
    
    if {$mc==1} {
      set res [regexp {Main-A\s+Main (10GEx4|SFP\+x4)\s+([A-Za-z]+)\s} $buffer ma mai val] 
    } elseif {$mc==2} {
      set res [regexp {Main-B\s+Main (10GEx4|SFP\+x4)\s+([A-Za-z]+)\s} $buffer ma mai val] 
    }
    if {$res==0} {
      set gaSet(fail) "Chassis-$chs MC-$mc. Read manufacture-info all fail"
      return -1
    }
    set val [string toupper $val]
    puts "Chassis-$chs MC-$mc. dbrHarden:<$dbrHarden>  val:<$val> DutInitName.$mc:<$gaSet(DutInitName.$mc)> mai:<$mai>"
    
    if {$dbrHarden != $val} {
      set gaSet(fail) "Chassis-$chs MC-$mc. Harden is $val. Should be $dbrHarden"
      return -1
    }
    if {[string match *.4SFP-P.* $gaSet(DutInitName.$mc)] && $mai!="SFP+x4"} {
      set gaSet(fail) "Chassis-$chs MC-$mc. XFP is $mai. Should be SFP+x4"
      return -1
    } elseif {[string match *.4XFP.* $gaSet(DutInitName.$mc)] && $mai!="10GEx4"} {
      set gaSet(fail) "Chassis-$chs MC-$mc. XFP is $mai. Should be 10GEx4"
      return -1
    }
    
    Send $com "exit all\r" "[Prompt]" 2
    Send $com "file\r" "[Prompt]" 2
    Send $com "show sw-pack\r" "[Prompt]" 2
    set dutVal xxx
    regexp {sw-pack-1\s+([\w\.\)\(]+)\s+} $buffer - dutVal
    if {$dutVal!=[string trim $gaSet(sp)]} {
      set gaSet(fail) "Chassis-$chs MC-$mc. The \'sw-pack\' is $dutVal. Should be [string trim $gaSet(sp)]"
      return -1
    }
    set swPackQty [regexp -all {sw-pack-} $buffer]
    if {$swPackQty!=2} {
      set gaSet(fail) "Chassis-$chs MC-$mc. The \'sw-pack-\' appears  $swPackQty time. Should be 2"
      return -1
    }
    regexp {\s(\w+)\s+sw-pack-1\s+Size} $buffer - actual
    if {$actual!="active"} {
      set ret [SetActiveSwPack $chs]
      if {$ret!=0} {return $ret}
      set ret [SetPrimaryMC $chs $mc]
      if {$ret!=0} {return $ret}
      Send $com "exit all\r" "[Prompt]" 2
      Send $com "file\r" "[Prompt]" 2
      Send $com "show sw-pack\r" "[Prompt]" 2
      regexp {\s(\w+)\s+sw-pack-1\s+Size} $buffer - actual
      if {$actual!="active"} {
        set gaSet(fail) "Chassis-$chs MC-$mc. The \'Actual\' field is \'$actual\'. Should be \'active\'"
        return -1
      }  
    }
    Send $com "exit all\r" "[Prompt]" 2 
    set ret [ExitToShell $com $chs $mc]
    if {$ret==0} {
      set ret [ReadBP $chs $mc 0xf8100060  [expr round( [expr {10*$gaSet(u17)}] ) ] ]
      if {$ret!=0} {return $ret}
      set ret [ExitFromShell $com $chs $mc]
    }
    if {$ret!=0} {return $ret}    
  }    
  return $ret    
}    
  
# ***************************************************************************
# TimeDateSet
# ***************************************************************************
proc TimeDateSet {} {
  puts "TimeDateSet [MyTime]" ; update
  global gaSet buffer
  foreach chs {1 2} mc {1 2} {    
    #set ret [SetPrimaryMC $chs $mc]
    #if {$ret!=0} {return $ret}
    Status "Time Date Set at Chassis-$chs MC-$mc"
    set com $gaSet(comMC.$chs.$mc)
    set ret [Send $com "config\r" "config"]
    if {$ret==0} {
      set ret [Send $com "system\r" "system"]
      if {$ret==0} {
        set ret [Send $com "date-and-time\r" "date-time"]
        if {$ret==0} {          
          set y  [clock format [clock seconds] -format %Y]
          set mo [clock format [clock seconds] -format %m]
          set d  [clock format [clock seconds] -format %d]
          set h  [clock format [clock seconds] -format %H]
          set mi [clock format [clock seconds] -format %M]
          set s  [clock format [clock seconds] -format %S]
          set ret [Send $com "date [set y]-[set mo]-[set d]\r" "date-time"]
          set ret [Send $com "time [set h]:[set mi]:[set s]\r" "date-time"]
          set ret [Send $com "save\r" "successfully" 60]            
        }
      }
    }
    if {$ret!=0} {
      set gaSet(fail) "Chassis-$chs MC-$mc. Can't set data-time"
      return $ret
    }
  
    set ret [TimeDateCheck $chs $mc]
    if {$ret!=0} {return $ret}
  }
  return $ret
}  
  
# ***************************************************************************
# TimeDateCheck
# ***************************************************************************
proc TimeDateCheck {chs mc} {
  puts "TimeDateCheck $chs $mc [MyTime]" ; update
  global gaSet buffer
  Status "Time Date Check of MC-$mc Chassis-$chs"
  set com $gaSet(comMC.$chs.$mc)
  set gaSet(fail) "Communication with Chassis-$chs MC-$mc fail"
  set ret [Send $com "exit all\r" "[Prompt]"]
  set ret [Send $com "config\r" "config"]
  if {$ret==0} {
    set ret [Send $com "system\r" "system"]
    if {$ret==0} {
      set ret [Send $com "show system-date\r" "system#"]
      if {$ret==0} {          
        regexp {system-date\s+(\d+)-(\d+)-(\d+)\s+(\d+):(\d+)} $buffer - dY dM dD dh dm
        regexp {system-date\s+([\d\s\-\:]+)\s} $buffer - dutVal
        set PCval [clock seconds]
        set dutVal [clock scan $dutVal] 
        set y [clock format [clock seconds] -format %Y]
        set mo [clock format [clock seconds] -format %m]
        set d [clock format [clock seconds] -format %d]
        set h [clock format [clock seconds] -format %H]
        set mi [clock format [clock seconds] -format %M]
        set diff [expr abs($PCval-$dutVal)]
        puts "PCval:$PCval dutVal:$dutVal diff:$diff"
        AddToLog "Chassis-$chs MC-$mc. The difference is $diff"
        if {$diff>60} {
          #set gaSet(fail) "Chassis-$chs MC-$mc. The date-and-time is $dutVal. Should be around $PCval"
          set gaSet(fail) "Chassis-$chs MC-$mc. The difference between the PC's time and the MC's time is $diff. Should be less then 60"
          set ret -1
        }
      }
    }
  }
  return $ret      
}

# ***************************************************************************
# WaitForUp
# ***************************************************************************
proc WaitForUp {chs} {
  global gaSet buffer
  puts "WaitForUp $chs [MyTime]" ; update
  foreach mc {1 2} {
    Status "Chassis-$chs MC-$mc. Wait for up."
    set com  $gaSet(comMC.$chs.$mc)
    Send $com \r\r\r stam 1
    Send $com \r\r\r stam 1
    if {[string match *>* $buffer] || [string match *user* $buffer] || \
        [string match *password* $buffer] || [string match *[Prompt]* $buffer] || \
        [string match *rClockSele* $buffer] || [string match *ktProcessin* $buffer]} {
      return $mc 
    }

    if {[string match *debug-mode* $buffer]} {
      set gaSet(fail) "Chassis-$chs MC-$mc in debug mode"
      return -1
    } 
    if {[string match *I2C* $buffer]} {
      set gaSet(fail) "Chassis-$chs MC-$mc. There is an I2C error at MC-$mc"
      return -1
    } 
  }
  set maxWait 1200
  set start [clock seconds]
  while 1 {    
    set now [clock seconds]
    set running [expr {$now - $start}]
    Status "Chassis-$chs. Wait for up. $running sec from $maxWait passed"
    if {$running>$maxWait} {
      set gaSet(fail) "No communication with  MC-$mc of Chassis-$chs"
      set ret -1
      break
    }
    
    foreach mc {1 2} {
      $gaSet(amc) configure -text "$chs.$mc"
      set com  $gaSet(comMC.$chs.$mc)
      Status "Chassis-$chs MC-$mc. Wait for up. $running sec from $maxWait passed"
      if {$running>$maxWait} {
        set gaSet(fail) "No communication with  MC-$mc of Chassis-$chs"
        set ret -1
        break
      }
      
      set boot x 
#       set keySentence "Received DB_MIRRORING_BINARY_PASSED_TO_STANDBY"
#       set keySentence "HW-CON - INT_HANDLER_DISP_IRQ3_UNMASK 50004"
      set keySentence "user"
      set ret [WaitFor $com buffer $keySentence 5]
     
      if {$ret==0} {
        puts "\nboot==[string range $keySentence 0 15]\n" ; update; set boot done
        #return $mc
      }    
      if {$gaSet(act)==0} {set ret -2;  break}
      if {[string match *A>* $buffer]} {
        puts "\n$chs.$mc boot==A>\n" ; update; set boot done
      } elseif {[string match *user* $buffer]} {
        puts "\n$chs.$mc boot==user\n" ; update; set boot done
      } elseif {[string match *password* $buffer]} {
        puts "\n$chs.$mc boot==password\n" ; update; set boot done
      } elseif {[string match *[Prompt]* $buffer]} {
        puts "\n$chs.$mc boot==[Prompt]\n" ; update; set boot done
      }
      if {$boot=="done"} {
        ## the MC sends a big text of boot menu. 
        ## To avoid exit from [while] loop,  I wait 10sec, send a few Enters and 
        ## then check the buffer again 
        after 10000
        Send $com \r\r\r stam 1
        after 1000
        Send $com \r\r\r stam 1
        if {[string match *>* $buffer] || [string match *user* $buffer] || \
            [string match *password* $buffer] || [string match *[Prompt]* $buffer]} {
          return $mc
        }
      }
      if {[string match *debug-mode* $buffer]} {
        set gaSet(fail) "Chassis-$chs MC-$mc in debug mode"
        set ret -1
        break
      }
    }
    if {$gaSet(act)==0} {set ret -2;  break}
    #if {$ret!=0} {break}
  }
  return $ret
}

# ***************************************************************************
# TemperatureTest
# ***************************************************************************
proc TemperatureTest {} {
  puts "TemperatureTest [MyTime]" ; update
  global gaSet buffer
  foreach chs {1 2} mc {1 2} {
    Status "Temperature Test of MC-$mc"
    set com $gaSet(comMC.$chs.$mc)
    set ret [ExitToShell $com $chs $mc]
    if {$ret==0} {
      set ret [Send $com "rd8_add 0xf810006c\r" >]
      if {$ret==0} {
        set ret [Temp $chs $mc 1 20 60 "10GIGA Sensor"]
        if {$ret==0} {
          set ret [Send $com "rd8_add 0xf810006d\r" >]
          if {$ret==0} {
            set ret [Temp $chs $mc 1 20 60 "U39"]
            if {$ret==0} {
              set ret [Send $com "rd8_add 0xf810006e\r" >]
              if {$ret==0} {
                set ret [Temp $chs $mc 1 20 60 "U56"]
                if {$ret==0} {
                  set ret [Send $com "rd8_add 0xf810006f\r" >]
                  if {$ret==0} {
                    set ret [Temp $chs $mc 1 20 60 "U8"]
                    if {$ret==0} {
                      set ret [Send $com "rtsens 0,0x01\r" >]
                      if {$ret==0} {
                        set ret [Temp $chs $mc 2 20 60 "Network Processor"]
                        if {$ret==0} {
                          set ret [ExitFromShell $com $chs  $mc]
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    if {$ret!=0} {return $ret}   
  } 
  return $ret   
}

# ***************************************************************************
# Temp
# ***************************************************************************
proc Temp {chs mc mode min max point} {
  global buffer gaSet
  puts "Temp $mode $min $max $point [MyTime]" ; update
  if {$mode=="1"} {
    set minus 100
    set ret [regexp {data =\s+(\w+)\s} $buffer - dutVal]
  } elseif {$mode=="2"} {
    set minus 0
    set ret [regexp {Value =\s+(\w+),} $buffer - dutVal]
  }
  
  set decDutVal [scan $dutVal %x]
  set tmp [expr {$decDutVal - $minus}]
  puts "dutVal:$dutVal decDutVal:$decDutVal min:$min tmp:$tmp max:$max"
  
  if {$tmp<$min || $tmp>$max} {
    set gaSet(fail) "The temperature of $point at Chassis-$chs MC-$mc is $tmp. Should be between $min and $max"  
    set ret -1
  } else {
    set ret 0
  }
  return $ret
}

# ***************************************************************************
# StationClk
#  balanced unbalanced
# ***************************************************************************
proc StationClk {chs mc mode} {
  global gaSet buffer
  puts "StationClk $chs $mc $mode [MyTime]" ; update
  Status "Set Station clock of MC-$mc at Chassis-$chs to $mode"
  set com $gaSet(comMC.$chs.$mc)
  if {$mc==1} {
    set enM a
    set disM b
  } elseif {$mc==2} {
    set enM b
    set disM a
  }
  
  ## On the disM (disabled MainCard) I perform [shutdown] only
  ## On the enM (enabled MainCard) I confugure parameters and then [no shutdown]
  foreach m "$disM $enM" conf {no yes} {
    set ret [Send $com "exit all\r" "[Prompt]"]
    set ret [Send $com "config\r" "config"]
    if {$ret==0} {
      set ret [Send $com "system clock station main-$m/1\r" "main"]
      if {$ret==0} {
        set ret [Send $com "shutdown\r" "main"]
        if {$ret==0 && $conf=="yes"} {    
          set ret [Send $com "interface-type e1\r" "main"]
          if {$ret==0} {
            set ret [Send $com "impedance $mode\r" "main"]
            if {$ret==0} {
              set ret [Send $com "tx-clock-source station-rclk\r" "main"]
              if {$ret==0} {
                set ret [Send $com "line-type g732n\r" "main"]
                if {$ret==0} {
                  set ret [Send $com "no shutdown\r" "main"]
                }
              }
            }
          }  
        }
      }
    }
  }
  if {$ret!=0} {
    set gaSet(fail) "Chassis-$chs MC-$mc. Can't set Station Clock"
  }
  return $ret
}

# ***************************************************************************
# SwitchMC
# ***************************************************************************
proc SwitchMC {} {
  global gaSet buffer
  puts "SwitchMC [MyTime]" ; update
  Status "Switch MC"
  set ret [ReadPrimaryMC]
  puts "ret1 of ReadPrimaryMC: $ret"
  if {$ret=="A" || $ret=="B"} {  
    if {$ret=="A"} {
      set com $gaSet(comMC1)
    } elseif {$ret=="B"} {
      set com $gaSet(comMC2)
    }
    set pc $ret 
    set ret [Send $com "exit all\r" "[Prompt]"]
    set ret [Send $com "config\r" "config"]
    if {$ret==0} {
      set ret [ManualSwitch $com]
      if {$ret==0} {   
        set ret [ReadPrimaryMC]
        puts "ret2 of ReadPrimaryMC: $ret"
        if {$ret=="A" || $ret=="B"} {   
          set pcNow $ret
          set ret 0
          puts "pc:$pc pcNow:$pcNow"
          if {$pc==$pcNow} {
            set ret -1
            set gaSet(fail) "Main Card isn't switched"
          }
        }  
      }      
    } 
  }   
  if {$ret!=0} {
    set gaSet(fail) "Can't view Main-card status"
  }
  return $ret
}
# ***************************************************************************
# ManualSwitch
# ***************************************************************************
proc ManualSwitch {chs com} {
  puts "ManualSwitch $chs $com [MyTime]" ; update
  global gaSet buffer 
  if {$com==$gaSet(comMC.$chs.1)} {
    set mcnSw B
    set mcSw 2  
    set mcn A  
    set mc 1    
  } elseif {$com==$gaSet(comMC.$chs.2)} {
    set mcnSw A
    set mcSw 1
    set mcn B
    set mc 2
  }
  Status "Manual Switch from MC-$mc to MC-$mcSw at Chassis-$chs"
  #set com $gaSet(comMC1)
  set ret [Send $com "exit all\r" "[Prompt]"]
  #set ret [Send $com "config\r" "config"]
  set ret [Send $com "config protection main-card\r" "main-card"]
  if {$ret==0} {
    set ret [Send $com "manual-switch\r\r" "Allowed" 30]
    if {$ret==0} {   
      Wait "Wait for switch from MC-$mc to MC-$mcSw at Chassis-$chs" 7 white 
      $gaSet(amc) configure -text $chs.$mcSw
      set ret [Login $chs $mcSw] 
      if {$ret!=0} {
        Wait "Wait for switch from MC-$mc to MC-$mcSw at Chassis-$chs" 5 white
        set ret [Login $chs $mcSw] 
      }
    }
  }
  if {$ret!=0} {
    set gaSet(fail) "Can't switch Primary Main Card at Chassis-$chs"
  }        
  return $ret
}

# ***************************************************************************
# ReadPrimaryMC
# ***************************************************************************
proc ReadPrimaryMC {chs} {
  global gaSet buffer 
  puts "ReadPrimaryMC $chs [MyTime]" ; update
  Status "Read Primary MC at chassis $chs"
  set ret [WaitForUp $chs]
  if {$ret<0} {return $ret}
  set mc $ret
  set ret [Login $chs $mc]
  if {$ret!=0} {return $ret}
  set com $gaSet(comMC.$chs.$mc)
  set ret [Send $com "exit all\r" "[Prompt]"]
  set ret [Send $com "config protection main-card\r" "main-card"]
  if {$ret==0} {
   set ret [Send $com "show status\r" "OK"]
   if {$ret!=0} {
     for {set i 1} {$i<=32} {incr i} {
       Wait "Chassis-$chs. Wait ($i) for the second MC" 15 white
       set ret [Send $com "show status\r" "OK" 2]
       if {$ret==0} {break}
     }
   }
   if {$ret==0} {
      set ret [regexp {Card\s+: Main\s+([AB]).+Status\s+:\s+(\w+)\s} $buffer - pc st]
      if {$ret==1} {
        set ret $pc
      }
    }
  }
  Send $com "exit all\r" "[Prompt]"
  if {$ret<=0} {                                             
    set gaSet(fail) "Chassis-$chs MC-$mc. Can't view Main-card status"
  } else {
    puts "PrimaryMC: $ret" ; update
    $gaSet(amc) configure -text $chs.$ret
  }
  return $ret
}

# ***************************************************************************
# ReadBP
# ***************************************************************************
proc ReadBP {chs mc reg val} {
  global gaSet buffer
  #puts "ReadBP $chs $mc $reg $val [MyTime]" ; update
  puts "Read register $reg ($val) at MC-$mc of Chassis-$chs [MyTime]"
  set gaSet(fail) ""
  set com $gaSet(comMC.$chs.$mc)
  set ret 0
  if {$ret==0} {
    set ret [Send $com "rd8_add $reg\r" >]   
    if [string match {*command not recognized*} $buffer] {
      set ret [Send $com "rd8_add $reg\r" >]
    } 
    if {$ret==0} {
      set dutVal NA
      set ret [regexp {data =\s+(\w+)\s} $buffer - dutVal]
      if {$ret==1 && [string toupper $dutVal]==[string toupper $val]} {
        set ret 0
      } else {
        set ret -1
        set gaSet(fail) "Chassis-$chs MC-$mc. The value of $reg is $dutVal. Should be $val"
      }
    } else {
      set gaSet(fail) "Chassis-$chs MC-$mc. rd8_add $reg fail"
    }
  }
  puts "[MyTime] Ret of ReadBP:<$ret> gaSet(fail):<$gaSet(fail)>"
  return $ret
}    
      
# ***************************************************************************
# Set2Default
# ***************************************************************************
proc Set2Default {verifyRMV li} {
  puts "Set2Default $verifyRMV  $li [MyTime]" ; update
  global gaSet buffer
#   set ret [WaitForUp]
#   if {$ret<0} {return $ret}
#   set ret [Login $ret]
#   if {$ret!=0} {return $ret}
  foreach chs $li mc $li {
#     set ret [WaitForUp $chs]
#     if {$ret<0} {return $ret}
    set ret [Login $chs $mc]
    if {$ret!=0} {return $ret}
    
    set com $gaSet(comMC.$chs.$mc)
    set ret [Send $com "exit all\r" "[Prompt]"]
    if {$ret!=0} {
      set gaSet(fail) "Chassis-$chs MC-$mc. Can't get \'[Prompt]\'"
      return $ret
    }
    set ret [Send $com "admin factory-default\r" "no"]
    if {$ret!=0} {
      set gaSet(fail) "Chassis-$chs MC-$mc. Can't activate admin factory-default"
      return $ret
    }
    set ret [Send $com "yes\r" "success"]
    if {$ret!=0} {
      set gaSet(fail) "Chassis-$chs MC-$mc. Can't get \'success\'"
      return $ret
    }
    if {$verifyRMV=="yes"} {
      set ret [DialogBox -title "Led Test" -message "Chassis-$chs. Verify RMV are blinking at both MainCards.\n\
          Verify green leds LINK and yellow leds ACT are turning ON for a second at both MNG-ETH ports."\
          -type "OK Abort"  -icon [pwd]/images/info.ico]
      if {$ret=="OK"} {
        set ret 0
      } else {
        set ret -1
      }
    }
    if {$ret!=0} {
      set gaSet(fail) "Chassis-$chs MC-$mc. Leds problem"
      return $ret
    }
  } 
  if {$verifyRMV!="yes"} {  
    set ret [Wait "Wait for reboot" 20 white]
  }
  return $ret
}

# ***************************************************************************
# BootDebugMode
# ***************************************************************************
proc BootDebugMode {chs mc mode} {
  global gaSet buffer
  puts "BootDebugMode $chs $mc $mode [MyTime]" ; update
  Status "Chassis-$chs MC-$mc.Wait for debug-mode menu ..."
  set com $gaSet(comMC.$chs.$mc)
  set max 30
  for {set i 1} {$i<=$max} {incr i} {    
     puts "attempts: $i"; update
     set ret [Send $com "\r" "\[boot" 3]
     if {[string match {*boot (*} $buffer]==1 || [string match {*boot(*} $buffer]==1} {
       set ret 0
     }
     if {$ret==0} {break}
     if {$gaSet(act)=="-2"} {return -2} 
     #Delay_Sec 120
     #GuiRemainTimeCuont 60
  }
  puts "attempts: $i"
  if {$i>$max} {
    #puts stderr "fail to get \"debug-mode menu\" after $i attempts"
    set gaSet(fail) "Chassis-$chs MC-$mc. Enter to \'debug-mode\' menu fail" ; update   
    return -1
  }
  if {$mode!="debug-mode"} {
    set ret [Send $com "shelfmac $mode\r" "$mode" 3]
    if {$ret!=0} {return $ret}
  }
  return 0
}
# ***************************************************************************
# ConfigMC
# ***************************************************************************
proc ConfigMC {} {
  puts "ConfigMC [MyTime]" ; update
  global gaSet 
  foreach chs {1 2} mc {1 2} {
    set com $gaSet(comMC.$chs.$mc)
    set ret [Send $com "exit all\r" "[Prompt]"]
    if {$ret!=0} {return $ret}
        
    foreach sl {1 2 3 4} {
      Status "Config of IO-$sl at Chassis-$chs"
      set gaSet(fail) "Config of IO-$sl at Chassis-$chs failed"
      set ret [Send $com "configure slot $sl\r" [Prompt] 60]
      if {$ret!=0} {return $ret}
      set ret [Send $com "card-type eth 10g-2-xfp\r"  [Prompt] 60 ]
      if {$ret!=0} {return $ret}
      set ret [Send $com "no shutdown\r" [Prompt]]
      if {$ret!=0} {return $ret}
      set ret [Send $com "exit all\r" [Prompt]]
      if {$ret!=0} {return $ret}
    }
  }  
  
  foreach chs {1 2} mc {1 2} {
    set ret [IoCardsShowStatus $chs $mc]
    if {$ret!=0} {return $ret}
  }
  
  foreach chs {1 2} mc {1 2} {
    set com $gaSet(comMC.$chs.$mc)  
    Status "Chassis-$chs MC-$mc. Download configuration file ..."
    
    if ![file exists $gaSet(etx5300cnf1)] {
      set gaSet(fail) "The configuration file ($gaSet(etx5300cnf1)) doesn't exist"
      return -1
    }
    set s1 [clock seconds]
    set id [open $gaSet(etx5300cnf1) r]
    set c 0
    while {[gets $id line]>=0} {
      if {$gaSet(act)==0} {close $id ; return -2}
      if {[string length $line]>2 && [string index $line 0]!="#"} {
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
  foreach chs {1 2} mc {1 2} {
    set ret [SetPrimaryMC $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [SlotsState $chs $mc "shutdown"]
    if {$ret!=0} {return $ret}
    set ret [SlotsState $chs $mc "no shutdown"]
    if {$ret!=0} {return $ret}
  }  
  Wait "Wait for card's up" 30 white
  
  foreach chs {1 2} mc {1 2} {
    set ret [IoCardsShowStatus $chs $mc]
    if {$ret!=0} {return $ret}
  }
  return $ret
}

# ***************************************************************************
# DisableAlarms
# ***************************************************************************
proc DisableAlarms {chs mc} {
  puts "DisableAlarms $chs $mc [MyTime]" ; update
  global gaSet buffer
  Status "Disable alarms at MC-$mc of Chassis-$chs"
  set ret [Login $chs $mc]
  if {$ret!=0} {return $ret}
  set com $gaSet(comMC.$chs.$mc)
  Status "Disable alarms at MC-$mc of Chassis-$chs"
  set ret [Send $com "config port mng-ethernet main-a/0\r" "main-a"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "shutdown\r" "main-a"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" "port"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mng-ethernet main-b/0\r" "main-b"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "shutdown\r" "main-b"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit all\r" "[Prompt]"]
  if {$ret!=0} {return $ret}
  
  ## 19/05/2020 14:21:25
#   set ret [Send $com "config system clock domain 1\r" "domain(1)"]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "sync-network-type 1\r" "domain(1)"]
#   if {$ret!=0} {return $ret}

#   set ret [Send $com "mode free-run\r" "domain(1)"]
#   if {$ret!=0} {return $ret}
    
  return $ret
}
# ***************************************************************************
# ClearAlarms
# ***************************************************************************
proc ClearAlarms {chs mc} {
  puts "ClearAlarms $chs $mc [MyTime]" ; update
  global gaSet buffer
  Status "Clear alarms at MC-$mc of Chassis-$chs"
  set ret [Login $chs $mc]
  if {$ret!=0} {return $ret}
  set com $gaSet(comMC.$chs.$mc)
  set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
  Status "Clear alarms at MC-$mc of Chassis-$chs"
  set ret [Send $com "config\r" "config"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "reporting\r" "reporting"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "clear-alarm-log all-logs\r" "reporting"]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# ReadAlarms
# ***************************************************************************
proc ReadAlarms {chs mc} {
  puts "ReadAlarms $chs $mc [MyTime]" ; update
  global gaSet buffer dutBuffer
  set ret [Login $chs $mc]
  if {$ret!=0} {return $ret}
  Status "Read alarms at MC-$mc"
  set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
  set com $gaSet(comMC.$chs.$mc)
  set ret [Send $com "configure reporting\r" "reporting"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show active-alarms\r" "reporting"]
  if {$ret!=0} {return $ret}
  set res [regexp {Critical[\s\:]+(\d+)\s+Major[\s\:]+(\d+)\s+Minor[\s\:]+(\d+)\s} $buffer - Critical Major Minor]
  if {$res!=1} {
    set gaSet(fail) "Chassis-$chs MC-$mc. Can't read alarms"
  }
  set ethLosQty [regexp -all {Ethernet \d/\d.+?los\s+Maj} $buffer ma]
  foreach val {Critical Major Minor ethLosQty} {
    set valVal [set $val]
    puts "$val:<$valVal>"
  }
  foreach alm {Critical Major Minor} {
    if {[set $alm]!=0} {
#       ## 02/06/2020 15:58:58
      if {[regexp {Domain 1\s+station_clock_unlock\s+Maj} $buffer]} {
        continue
      }
      
#       04/06/2020 08:55:04
      if {[regexp -all {Ethernet \d/\d.+?los\s+Maj} $buffer ma]} {
        continue
      }
      set gaSet(fail) "Chassis-$chs MC-$mc. The $alm alarm is [set $alm]. Should be 0"
      return -1
    }
  }
  set ret [Send $com "show log\r\33\r" "reporting"]
  if {$ret!=0} {return $ret}
  set klumQty [regexp -all { \-{2} } $buffer]
  puts klumQty:$klumQty
  if {$klumQty!=2} {
    set gaSet(fail) "Chassis-$chs MC-$mc. There is alarm at log of MC-$mc"
    return -1
  }
  
  if {[string match *I2C* $dutBuffer]} {
    set gaSet(fail) "Chassis-$chs MC-$mc. There is an I2C error at MC-$mc"
    puts "\ndutBuffer:<$dutBuffer>\n" ; update
    return -1
  }
  return 0
}

# ***************************************************************************
# IoCardsResetTool
# ***************************************************************************
proc IoCardsResetTool {} {
  global gaSet gaGui
  pack forget $gaGui(frFailStatus) ; update
  puts "IoCardsResetTool [MyTime]" ; update
  set gaSet(act) 1
  catch {RLEH::Close}
  catch {RLSerial::Close $gaSet(comMC.1.1)}
  catch {RLSerial::Close $gaSet(comMC.2.1)}
  catch {RLSerial::Close $gaSet(comMC.1.2)}
  catch {RLSerial::Close $gaSet(comMC.2.2)}
  
  RLEH::Open
  set ret [ComOpen]
  if {$ret!=0} {return $ret}

  foreach chs {1 2} { 
    set ret [ReadPrimaryMC $chs]
    puts "ret1 of ReadPrimaryMC chs-$chs: $ret"
    if {$ret=="A"} {
      set mc$chs 1
    } elseif {$ret=="B"} {
      set mc$chs 2
    } else {
      return $ret
    }
    
    set ret [IoCardsReset $chs [set mc$chs]]
    if {$ret!=0} {return $ret}
  }
  foreach chs {1 2} {
    set ret [IoCardsShowStatus $chs [set mc$chs]]
    if {$ret!=0} {return $ret}
  }
                    
  catch {RLSerial::Close $gaSet(comMC.1.1)}
  catch {RLSerial::Close $gaSet(comMC.2.1)}
  catch {RLSerial::Close $gaSet(comMC.1.2)}
  catch {RLSerial::Close $gaSet(comMC.2.2)}
  catch {RLEH::Close}
  return $ret
}

# ***************************************************************************
# IoCardsReset
# ***************************************************************************
proc IoCardsReset {chs mc} {
  global gaSet
  puts "IoCardsReset $chs $mc [MyTime]" ; update
  set gaSet(fail) "Reset of IO slot at Chassis-$chs fail"
  set ret [SetPrimaryMC $chs $mc]
  if {$ret!=0} {return $ret}
  set com $gaSet(comMC.$chs.$mc)
  set ret [Send $com "exit all\r" "[Prompt]"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "config\r" "config"]
  if {$ret!=0} {return $ret}
  foreach sl {1 2 3 4} {
    Status "Reset slot $sl at Chassis-$chs"
    set ret [Send $com "slot $sl\r" "slot($sl)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "reset\r" "yes/no"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "y\r" "slot($sl)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "exit\r" "config"]
    if {$ret!=0} {return $ret}
  }
  set ret [Send $com "save\r" "config"]
  if {$ret!=0} {return $ret}
  
  
  return $ret
}

# ***************************************************************************
# IoCardsShowStatus
# ***************************************************************************
proc IoCardsShowStatus {chs mc} {
  puts "IoCardsShowStatus $chs $mc [MyTime]" ; update
  global gaSet buffer
  set com $gaSet(comMC.$chs.$mc)
  set ret [Send $com "exit all\r" "[Prompt]" 16]
  if {$ret!=0} {return $ret}
  set ret [Send $com "config\r" "config" 16]
  if {$ret!=0} {return $ret}
  
  set slotsReady 0
  foreach sl {1 2 3 4} {
    set slReady$sl 0
  }
  set startSec [clock seconds]
  set maxSec 300; #180
  while 1 {
    set nowSec [clock seconds]
    set runSec [expr {$nowSec - $startSec}]
    $gaSet(runTime) configure -text $runSec
    if {$runSec > $maxSec} {
      set gaSet(fail) "IO cards at Chassis-$chs are not ready after $maxSec sec."
      break
    }
    if {$gaSet(waitBreak)==1} {set gaSet(waitBreak) 0; break}      
    foreach sl {1 2 3 4} {
      if {$gaSet(waitBreak)==1} {set gaSet(waitBreak) 0; break}      
      Status "Read status slot $sl at Chassis-$chs"
      set ret [Send $com "slot $sl\r" "slot($sl)" 40]
      if {$ret!=0} {return $ret}
      set ret [Send $com "show status\r" "slot($sl)" 40]
      if {$ret!=0} {return $ret}
      set resA [regexp -all {10Gx2 XFP} $buffer]
      set resB [ regexp -all {Up} $buffer]
      set resC [ regexp -all {OK} $buffer]
      set resD [ regexp -all {Ready} $buffer]
      if {$resA==2 && $resB==2 && $resC==1 && $resD==1} {
        set slReady$sl 1
      }
      set ret [Send $com "exit\r" "config" 40]
      if {$ret!=0} {return $ret}
      
      puts "RunSec:$runSec slReady$sl:[set slReady$sl] at Chassis-$chs"  ; update
      after 5000
    }
    if {$slReady1==1 && $slReady2==1 && $slReady3==1 && $slReady4==1} {
      set slotsReady 1
      break
    }
  }
  if {$slotsReady==0} {
    set ret -1
  } elseif {$slotsReady==1} {
    set ret 0
    set ret [Send $com "exit all\r" "[Prompt]" 16]
    if {$ret!=0} {return $ret}
  }
  Status "Done at Chassis-$chs"
  return $ret
}

# ***************************************************************************
# CheckBootID
# ***************************************************************************
proc CheckBootID {chs mc} {
  puts "CheckBootID $chs $mc [MyTime]" ; update
   global gaSet buffer
  
#   set ret [WaitForUp 1]
#   if {$ret!=0} {return $ret}
#   set ret [WaitForUp 2]
#   if {$ret!=0} {return $ret}
#   set ret [Login]
#   if {$ret!=0} {return $ret}
  
  set com $gaSet(comMC.$chs.$mc)
  set ret [Send $com "v\r" "debug-mode"]
  if {$ret!=0} {
    set gaSet(fail) "Chassis-$chs MC-$mc. Can't view the Boot"
    return $ret
  }
  set res [regexp {Boot version:\s+(\d+\.\d+)\s} $buffer - boot]
  if {$res!=1} {
    set gaSet(fail) "Chassis-$chs MC-$mc. Can't view the Boot"
    return $ret
  }
  if {[set boot]!=[string trim $gaSet(boot)]} {
    set gaSet(fail) "Chassis-$chs MC-$mc. The \'BOOT\' is $boot. Should be [string trim $gaSet(boot)]"
    set ret -1
  } else {
    set ret 0
  }  
  return $ret
}

# ***************************************************************************
# MemoryTest
# ***************************************************************************
proc MemoryTest {} {
  puts "MemoryTest [MyTime]" ; update
  global gaSet buffer
  Status "Memory Test"
  foreach chs {1 2} mc {1 2} {
    set com $gaSet(comMC.$chs.$mc)
    set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
    set ret [ExitToShell $com $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [Send $com "cmd\r" "orks"] 
    if {$ret!=0} {return $ret}
    set ret [Send $com "rtp\r" "flat"]
    if {$ret!=0} {return $ret}
    set ret [regexp {PktProcessing.vxe\s+(\w+)\s} $buffer - id]
    if {$ret==0} {return -1}
    set ret [Send $com "attach $id\r" "cessing"] 
    if {$ret!=0} {return $ret}
    set ret [Send $com "task spawn &SetDefaultTerminal 0\r" "cessing"]
    if {$ret!=0} {return $ret}
  } 
  # "task spawn &qdr_test" 2000
  foreach memTst {"task spawn &qdr_test" "task spawn &fpga_mem_test 0" "task spawn &ddr_test 2" \
                  "task spawn &fpga_mem_test 1" "task spawn &fpga_mem_test 2"} \
                  tstDur {2400 40 160 500 500} u {QDR U92 U76-87 U91 U93} \
                  exp {"succeeded" "assed" "assed" "assed" "assed"} {}
  foreach memTst {"task spawn &fpga_mem_test 0" "task spawn &ddr_test 2" \
                  "task spawn &fpga_mem_test 1" "task spawn &fpga_mem_test 2"} \
                  tstDur {40 160 500 500} u {U92 U76-87 U91 U93} \
                  exp {"assed" "assed" "assed" "assed"} {               
    Status "\'[lrange $memTst 2 end]\' memory test"              
    foreach chs {1 2} mc {1 2} {
      set com $gaSet(comMC.$chs.$mc)
      set ret [Send $com "\r\r" "ktProcessing" 2]
      if {$ret!=0} {return $ret}
      Send $com "$memTst\r" stam 1
      if {[string match {*QDR Memory test failed*} $buffer]} {
        set gaSet(fail) "\'[lrange $memTst 2 end]\' memory test of MC-$mc of Chassis-$chs is fail"
        return -1
      }
    }     
    set ret [MemoryTestPerf $tstDur $exp $u]   ; ##assed 
    if {$ret!=0} {return $ret}
  }
  
#   foreach chs {1 2} {
#     set com $gaSet(comMC.$chs.$mc)
#     set ret [Send $com "\r\r" "ktProcessing" 2]
#     if {$ret!=0} {return $ret}
#     Send $com "task spawn &qdr_test\r" stam 3
#     if {[string match {*QDR Memory test failed*} $buffer]} {
#       set gaSet(fail) "Memory test of MC-$mc of Chassis-$chs is fail"
#       return -1
#     }
#   }   
#   set ret [MemoryTestPerf $mc 2000 "assed"]    
#   if {$ret!=0} {return $ret}
  
#   foreach chs {1 2} {
#     set com $gaSet(comMC.$chs.$mc)
#     set ret [Send $com "\r\r" "ktProcessing" 2]
#     if {$ret!=0} {return $ret}
#     Send $com "task spawn &fpga_mem_test 0\r" stam 3
#     if {[string match {*QDR Memory test failed*} $buffer]} {
#       set gaSet(fail) "Memory test of MC-$mc of Chassis-$chs is fail"
#       return -1
#     }
#   }   
#   set ret [MemoryTestPerf $mc 40 "assed"]   
#   puts "res of MemoryTestPerf is $ret [MyTime]" ; update 
#   if {$ret!=0} {return $ret}
  
#   foreach chs {1 2} {
#     set com $gaSet(comMC.$chs.$mc)
#     set ret [Send $com "\r\r" "ktProcessing" 2]
#     if {$ret!=0} {return $ret}
#     Send $com "task spawn &fpga_mem_test 1\r" stam 3
#     if {[string match {*QDR Memory test failed*} $buffer]} {
#       set gaSet(fail) "Memory test of MC-$mc of Chassis-$chs is fail"
#       return -1
#     }
#   }   
#   set ret [MemoryTestPerf $mc 600 "assed"]   
#   puts "res of MemoryTestPerf is $ret [MyTime]" ; update 
#   if {$ret!=0} {return $ret}
 
#   foreach chs {1 2} {
#     set com $gaSet(comMC.$chs.$mc)
#     set ret [Send $com "\r\r" "ktProcessing" 2]
#     if {$ret!=0} {return $ret}
#     Send $com "task spawn &fpga_mem_test 2\r" stam 3
#     if {[string match {*QDR Memory test failed*} $buffer]} {
#       set gaSet(fail) "Memory test of MC-$mc of Chassis-$chs is fail"
#       return -1
#     }
#   }   
#   set ret [MemoryTestPerf $mc 600 "assed"]   
#   puts "res of MemoryTestPerf is $ret [MyTime]" ; update 
#   if {$ret!=0} {return $ret} 
  
  return $ret    
}
# ***************************************************************************
# MemoryTestPerf
# ***************************************************************************
proc MemoryTestPerf {maxWait exp u} {
  puts "MemoryTestPerf $maxWait $exp $u [MyTime]" ; update
  global gaSet buffer
  set res1 -1
  set res2 -1    
  set maxWait $maxWait
  set start [clock seconds]  
  while 1 {    
    set now [clock seconds]
    set running [expr {$now - $start}]
    $gaSet(runTime) configure -text $running
    if {$running>$maxWait} {
      set ret -1
      break
    }
    if {$res1==0 && $res2==0} {break}
    foreach chs {1 2} mc {1 2} {      
      #puts "$running sec. chs:$chs" ; update
      set com $gaSet(comMC.$chs.$mc)
      if {$gaSet(act)==0} {
        Send $com "\r\r" "ktProcessing" 2
        return -2
      }
      if {[set res$chs]=="-1"} {        
        set ret [WaitFor $com buffer $exp 5]
        if {$ret==0} {
          set res$chs 0 
          Send $com "\r\r" "ktProcessing" 2           
        } else {
          puts "chs:$chs maxWait:$maxWait running:$running"; update 
        }        
      }
    }
  } 
  
  if {$res1!=0 && $res2==0} {
    set gaSet(fail) "Memory test of $u at MC-1 of Chassis-1 is fail"
    set ret -1
  } elseif {$res2!=0 && $res1==0} {
    set gaSet(fail) "Memory test of $u at MC-2 of Chassis-2 is fail"
    set ret -1
  } elseif {$res1!=0 && $res2!=0} {
    set gaSet(fail) "Memory test of $u at MC-1 of Chassis-1 and MC-2 of Chassis-2 is fail"
    set ret -1
  } elseif {$res1==0 && $res2==0} {
    set ret 0
  }
  return $ret
}

# ***************************************************************************
# TdmBusTest
# ***************************************************************************
proc TdmBusTest {} {
  puts "TdmBusTest [MyTime]" ; update
  global gaSet buffer
  foreach chs {1 2} mc {1 2} {
    set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
    Status "TdmBus Test of MC-$mc at Chassis-$chs"
    set com $gaSet(comMC.$chs.$mc)
    set ret [ExitToShell $com $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [Send $com "wgil(1,0xa0,0xff)\r" >]
    if {$ret!=0} {return $ret}
    set ret [ReadBP $chs $mc 0xf8100030 0]
    if {$ret!=0} {return $ret}
    set ret [ReadBP $chs $mc 0xf8100032 0]
    if {$ret!=0} {return $ret}
    
    set 10secLoopQty 2
    set IObusDisWait 15
    
    foreach io {1 2 3 4} reg {34 36 38 3a} {    
      set ret [Send $com "wgil($io,0xa0,0xf3)\r" >]  ; # 0011
      if {$ret!=0} {return $ret}
      Wait "Wait $IObusDisWait sec for IO-$io BUS disable at Chassis-$chs" $IObusDisWait white
      set ret [ReadBP $chs $mc 0xf81000[set reg] 80]
      if {$ret!=0} {return $ret}
      set ret [Send $com "wgil($io,0xa0,0xfb)\r" >]  ; # 1011
      if {$ret!=0} {return $ret}
      set ret [ReadIO $chs $mc 0xf81000[set reg] 0 $10secLoopQty $io enable]
      if {$ret!=0} {return $ret}
      
      set ret [Send $com "wgil($io,0xa0,0xf3)\r" >]  ; # 0011
      if {$ret!=0} {return $ret}
      Wait "Wait $IObusDisWait sec for IO-$io BUS disable at Chassis-$chs" $IObusDisWait white
      set ret [ReadBP $chs $mc 0xf81000[set reg] 80]
      if {$ret!=0} {return $ret}
      set ret [Send $com "wgil($io,0xa0,0xf7)\r" >]  ; # 0111
      if {$ret!=0} {return $ret}
      set ret [ReadIO $chs $mc 0xf81000[set reg] 0 $10secLoopQty $io enable]
      if {$ret!=0} {return $ret}
      set ret [Send $com "wgil($io,0xa0,0xff)\r" >]  ; # ff11
      if {$ret!=0} {return $ret}
      set ret [ReadIO $chs $mc 0xf81000[set reg] 0 $10secLoopQty $io enable]
      if {$ret!=0} {return $ret}
      after 5000
    }
    
#     set ret [Send $com "wgil(2,0xa0,0xf3)\r" >]
#     if {$ret!=0} {return $ret}
#     Wait "Wait $IObusDisWait sec for IO-BUS disable" $IObusDisWait white
#     set ret [ReadBP $chs $mc 0xf8100036 80]
#     if {$ret!=0} {return $ret}
#     set ret [Send $com "wgil(2,0xa0,0xfb)\r" >]
#     if {$ret!=0} {return $ret}
#     set ret [ReadIO $chs $mc 0xf8100036 0 $10secLoopQty]
#     if {$ret!=0} {return $ret}
#     set ret [Send $com "wgil(2,0xa0,0xf7)\r" >]
#     if {$ret!=0} {return $ret}
#     set ret [ReadIO $chs $mc 0xf8100036 0 $10secLoopQty]
#     if {$ret!=0} {return $ret}
#     
#     set ret [Send $com "wgil(3,0xa0,0xf3)\r" >]
#     if {$ret!=0} {return $ret}
#     Wait "Wait $IObusDisWait sec for IO-BUS disable" $IObusDisWait white
#     set ret [ReadBP $chs $mc 0xf8100038 80]
#     if {$ret!=0} {return $ret}
#     set ret [Send $com "wgil(3,0xa0,0xfb)\r" >]
#     if {$ret!=0} {return $ret}
#     set ret [ReadIO $chs $mc 0xf8100038 0 $10secLoopQty]
#     if {$ret!=0} {return $ret}
#     set ret [Send $com "wgil(3,0xa0,0xf7)\r" >]
#     if {$ret!=0} {return $ret}
#     set ret [ReadIO $chs $mc 0xf8100038 0 $10secLoopQty]
#     if {$ret!=0} {return $ret}
#     
#     set ret [Send $com "wgil(4,0xa0,0xf3)\r" >]
#     if {$ret!=0} {return $ret}
#     Wait "Wait $IObusDisWait sec for IO-BUS disable" $IObusDisWait white
#     set ret [ReadBP $chs $mc 0xf810003a 80]
#     if {$ret!=0} {return $ret}
#     set ret [Send $com "wgil(4,0xa0,0xfb)\r" >]
#     if {$ret!=0} {return $ret}
#     set ret [ReadIO $chs $mc 0xf810003a 0 $10secLoopQty]
#     if {$ret!=0} {return $ret}
#     set ret [Send $com "wgil(4,0xa0,0xf7)\r" >]
#     if {$ret!=0} {return $ret}
#     set ret [ReadIO $chs $mc 0xf810003a 0 $10secLoopQty]
#     if {$ret!=0} {return $ret}
#     set ret [ExitFromShell $com]
#     if {$ret!=0} {return $ret}
  }
  return $ret
}
# ***************************************************************************
# ExitFromShell
# ***************************************************************************
proc ExitFromShell {com chs  mc} {
  puts "ExitFromShell $com $chs  $mc [MyTime]" ; update
  global gaSet buffer
  set ret [Send $com "exit\r" revoir 5]
  if {$ret!=0} {
    set ret [Send $com "exit\r" [Prompt]]
    if {$ret!=0} {
      after 2000
      set ret [Send $com "exit\r" [Prompt]]
    }
  }
  if {$ret==0} {
    set ret [Send $com "\r" [Prompt]]
  } else {
    set gaSet(fail) "Communication with Chassis-$chs MC-$mc fail"
  }
  return $ret
}
  
# ***************************************************************************
# LedTest
# ***************************************************************************
proc LedTest {chs mc} {
  puts "LedTest $chs $mc [MyTime]" ; update
  global gaSet buffer
  set com $gaSet(comMC.$chs.$mc) 
  set ret [ExitToShell $com $chs $mc]  
  if {$ret!=0} {return $ret}
  set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
    
  set ret [Send $com "wr8_add 0xf8100083,0xff\r" >]
  set ret [DialogBox -title "Led Test" -message "Chassis-$chs. MC-$mc. Verify PRI+FLT+RMV are OFF" -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret!="OK"} {return -2}
  
  set ret [Send $com "wr8_add 0xf8100083,0xef\r" >]
  set ret [DialogBox -title "Led Test" -message "Chassis-$chs. MC-$mc. Verify PRI+FLT+RMV are ON" -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret!="OK"} {return -2}
  
  set ret [Send $com "wr8_add 0xf8100083,0xbf\r" >]
  set ret [DialogBox -title "Led Test" -message "Chassis-$chs. MC-$mc. Verify only PRI is ON" -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret!="OK"} {return -2}
  
  set ret [Send $com "cmd\r" "orks"] 
  set ret [Send $com "rtp\r" "flat"]
  if {$ret!=0} {return $ret}
  set ret [regexp {ClockSelection.vxe\s+(\w+)\s} $buffer - id]
  if {$ret!=1} {return -1}
  
  set ret [Send $com "attach $id\r" "ction"] 
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "task spawn &SetDefaultTerminal 0\r" "ction"]
  if {$ret!=0} {return $ret} 
  
  set ret [Send $com "task spawn &SYNCLOCK_WR16 0X20 0X8FF\r" "ction"]
  if {$ret!=0} {return $ret} 
  set ret [DialogBox -title "Led Test" -message "Chassis-$chs. MC-$mc. Verify CLK is OFF" -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret!="OK"} {return -2}
 
  set ret [Send $com "task spawn &SYNCLOCK_WR16 0X20 0X8FE\r" "ction"] 
  if {$ret!=0} {return $ret} 
  set ret [DialogBox -title "Led Test" -message "Chassis-$chs. MC-$mc. Verify CLK is ON" -type "OK Abort" -icon [pwd]/images/info.ico]                        
  if {$ret!="OK"} {return -2}
  Send $com "task spawn &SYNCLOCK_WR16 0X20 0X8FF\r" "ction"
 
 set ret [ExitFromShell $com $chs  $mc] 
  return $ret
} 
# ***************************************************************************
# CpuPhyRGMIISet
# ***************************************************************************
proc _via5300_CpuPhyRGMIISet {chs mc} {
  global gaSet buffer
  switch -exact -- $mc {
    A - 1 {set ip 1}
    B - 2 {set ip 2}
  }
  
  Status "Cpu-Phy RGMII Set of MC-$mc at Chassis-$chs"
  set com $gaSet(comMC.$chs.$mc)
  set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
  set ret [ExitToShell $com $chs $mc]
  if {$ret!=0} {return $ret}
  set ret [Send $com "tipcConfig \"l\" \r" "0x0"] 
  if {$ret!=0} {return $ret}
  set ret [Send $com "ifconfig \"motetsec0 inet 1.1.1.$ip/24\"\r" "0x0"] 
  if {$ret!=0} {return $ret}
#   set ret [ExitFromShell $com] 
#   if {$ret!=0} {return $ret}
 
  return 0
}
# ***************************************************************************
# CpuPhyRGMIITest
# ***************************************************************************
proc _via5300_CpuPhyRGMIITest {mc} {
  global gaSet buffer
  foreach chs {1 2} {
    switch -exact -- $mc {
      1 {set ip 2}
      2 {set ip 1}
    }
    Status "Cpu-Phy RGMII Test of MC-$mc at Chassis-$chs"
    set com $gaSet(comMC.$chs.$mc)
    set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
    
    set ret [Send $com "ping \"1.1.1.$ip\",20\r" "min/avg/max" 60] 
    if {$ret!=0} {return $ret}
    regexp {\r(\d+).*tted} $buffer - xmt
    regexp {ed\.\s+(\d+).*ved} $buffer - rcv
    regexp {ed,\s+(\d+)%} $buffer - loss
    if {$xmt!=$rcv} {
      set gaSet(fail) "Chassis-$chs MC-$mc. Transmitted $xmt packets, received $rcv packets"  
      return -1
    }
    if {$loss!=0} {
      set gaSet(fail) "Chassis-$chs MC-$mc. ${loss}% packets loss"  
      return -1
    }
  }
  return $ret
}   
# ***************************************************************************
# CpuPhyRGMIITest
# ***************************************************************************
proc CpuPhyRGMIITest {} {
  puts "CpuPhyRGMIITest [MyTime]" ; update
  global gaSet buffer
  foreach chs {1 2} mc1 {1 2} mc2 {2 1} {
    set mc $mc1
    Status "Cpu-Phy RGMII Set of MC-$mc at Chassis-$chs"
    set com $gaSet(comMC.$chs.$mc)
    set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
    set ret [ExitToShell $com $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [Send $com "tipcConfig \"l\" \r" "0x0"] 
    if {$ret!=0} {return $ret}
    set ret [Send $com "ifconfig \"motetsec0 inet 1.1.1.$mc1/24\"\r" "0x0"] 
    if {$ret!=0} {return $ret}  
    set ret [Send $com "HW_CONNECTION_DebugOpenMateCardShell\r" "0x0"]   
    if {$ret!=0} {return $ret}
    set mc $mc2
    Status "Cpu-Phy RGMII Set of MC-$mc at Chassis-$chs"
    set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
    set com $gaSet(comMC.$chs.$mc)
    set ret [Send $com "\r\r" ">"] 
    if {$ret!=0} {
      Send $com "exit\r\r" "revoir"
      Send $com "exit\r\r" "revoir"
      return $ret
    }
    set ret [Send $com "tipcConfig \"l\" \r" "0x0"] 
    if {$ret!=0} {
      Send $com "exit\r\r" "revoir"
      Send $com "exit\r\r" "revoir"
      return $ret
    }
    set ret [Send $com "ifconfig \"motetsec0 inet 1.1.1.$mc2/24\"\r" "0x0"] 
    if {$ret!=0} {
      Send $com "exit\r\r" "revoir"
      Send $com "exit\r\r" "revoir"
      return $ret
    }
    Status "Cpu-Phy RGMII Test of MC-$mc at Chassis-$chs"
    set ret [Send $com "ping \"1.1.1.$mc1\",20\r" "min/avg/max" 30] 
    if {$ret!=0} {
      set gaSet(fail) "Chassis-$chs MC-$mc. 0 packets received"
      Send $com "exit\r\r" "revoir"
      Send $com "exit\r\r" "revoir"
      return $ret
    }
    regexp {ed,\s+(\d+)%} $buffer - loss
    if {$loss!=0} {
      set gaSet(fail) "Chassis-$chs MC-$mc. ${loss}% packet loss"  
      return -1
    }
#     set ret [Send $com "exit\r\r" "revoir"]   
#     if {$ret!=0} {
#       set ret [Send $com "exit\r\r" "revoir"]   
#       if {$ret!=0} {return $ret}
#     }
    Send $com "exit\r\r" "revoir"
    
    set mc $mc1
    Status "Cpu-Phy RGMII Test of MC-$mc at Chassis-$chs"
    set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
    set com $gaSet(comMC.$chs.$mc)
    set ret [Send $com "ping \"1.1.1.$mc2\",20\r" "min/avg/max" 30] 
    if {$ret!=0} {
      set gaSet(fail) "Chassis-$chs MC-$mc. 0 packets received"
      return $ret
    }
    regexp {ed,\s+(\d+)%} $buffer - loss
    if {$loss!=0} {
      set gaSet(fail) "Chassis-$chs MC-$mc. ${loss}% packet loss"  
      return -1
    }
  }
  return $ret
}
# ***************************************************************************
# BpTest
# ***************************************************************************
proc BpTest {chs mc} {
  puts "BpTest $chs [MyTime]" ; update
  global gaSet
  Power 1 on
  Power 2 on
  
  set ret [SetPrimaryMC $chs $mc]
  if {$ret!=0} {return $ret}    
  Status "BP Test of MC-$mc at Chassis-$chs"
  set com $gaSet(comMC.$chs.$mc)
  #set comSw $gaSet(comMC$mcSw)
  set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
  set ret [ExitToShell $com $chs $mc] 
  if {$ret!=0} {return $ret} 
  
  set ret [ReadBP $chs $mc 0xf8100062 d4]
  if {$ret!=0} {return $ret}
  
  Power 1 off
  after 1000
  set ret [ReadBP $chs $mc 0xf8100065 af]
  if {$ret!=0} {return $ret}
  Power 1 on
  after 5000
  Power 2 off
  after 1000
  set ret [ReadBP $chs $mc 0xf8100065 5f]
  if {$ret!=0} {return $ret}
  Power 2 on
  after 1000
  
  set ret [DialogBox -title "BP Test" -message "Chassis-$chs. Disconnect the FAN unit" -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret!="OK"} {return -2}
  after 3000
  set ret [ReadBP $chs $mc 0xf8100062 d7]
  if {$ret!=0} {return $ret}
  Power 1 off
  set ret [DialogBox -title "BP Test" -message "Chassis-$chs. Remove the Power Inlet-A" -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret!="OK"} {return -2}
  after 2000
  set ret [ReadBP $chs $mc 0xf8100062 f7]
  if {$ret!=0} {return $ret}
  set ret [DialogBox -title "BP Test" -message "Chassis-$chs. Insert the Power Inlet-A and the FAN unit" -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret!="OK"} {return -2}
  Power 1 on
  after 5000
  Power 2 off
  set ret [DialogBox -title "BP Test" -message "Chassis-$chs. Remove the Power Inlet-B" -type "OK Abort" -icon [pwd]/images/info.ico] 
  if {$ret!="OK"} {return -2}  
  after 2000           
  set ret [ReadBP $chs $mc 0xf8100062 dc]
  if {$ret!=0} {return $ret} 
  set ret [DialogBox -title "BP Test" -message "Chassis-$chs. Insert the Power Inlet-B" -type "OK Abort" -icon [pwd]/images/info.ico] 
  Power 2 on
  if {$ret!="OK"} {return -2}    
  after 5000         
  set ret [ReadBP $chs $mc 0xf8100065 f]
  if {$ret!=0} {return $ret}
  
  
  return $ret
} 
# ***************************************************************************
# MainActiveStandbyStatus
# ***************************************************************************
proc MainActiveStandbyStatus {chs mc1 mc2 v1 v2 v3 v4} {
  puts "MainActiveStandbyStatus $chs $mc1 $mc2 $v1 $v2 $v3 $v4 [MyTime]" ; update
  global gaSet
  set mc $mc1
  set ret [SetPrimaryMC $chs $mc]
  if {$ret!=0} {return $ret}    
  set com $gaSet(comMC.$chs.$mc)
  #set comSw $gaSet(comMC$mcSw)
  set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
  set ret [ExitToShell $com $chs $mc] 
  if {$ret!=0} {return $ret} 
  
  set ret [ReadBP $chs $mc 0xf8100067 $v1]
  if {$ret!=0} {return $ret}
  set ret [ReadBP $chs $mc 0xf8100064 $v2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "HW_CONNECTION_DebugOpenMateCardShell\r" "0x0"]   
  if {$ret!=0} {set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail" ; return $ret}
  
  set mc $mc2
  set com $gaSet(comMC.$chs.$mc)
  set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
  set ret [Send $com "\r\r" ">"]  
  if {$ret!=0} {
    Send $com "exit\r\r" "revoir"
    Send $com "exit\r\r" "revoir"
    return $ret
  } 
  set ret [ReadBP $chs $mc 0xf8100067 $v3]
  if {$ret!=0} {
    Send $com "exit\r\r" "revoir"
    Send $com "exit\r\r" "revoir"
    return $ret
  }
  set ret [ReadBP $chs $mc 0xf8100064 $v4]
  if {$ret!=0} {
    Send $com "exit\r\r" "revoir"
    Send $com "exit\r\r" "revoir"
    return $ret
  }
  
  set ret [Send $com "exit\r\r" "revoir"]
  if {$ret!=0} {
    set ret [Send $com "exit\r\r" "revoir"]
  }
  if {$ret!=0} {
    set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
  }
  return $ret
} 

# ***************************************************************************
# SetPrimaryMC
# ***************************************************************************
proc SetPrimaryMC {chs mcSet} {
  global gaSet buffer 
  puts "SetPrimaryMC $chs $mcSet [MyTime]" ; update
  Status "Set MC-$mcSet to Primary at chassis $chs"
  
  set ret [ReadPrimaryMC $chs]
  puts "ret1 of ReadPrimaryMC chs-$chs: $ret"
  if {$ret=="A"} {
    set com $gaSet(comMC.$chs.1)
    set mcEx 1
  } elseif {$ret=="B"} {
    set com $gaSet(comMC.$chs.2)
    set mcEx 2
  } else {
    return $ret
  }
  
  if {$mcSet==$mcEx} {
    set ret 0
  } else {
    set ret [ManualSwitch $chs $com]
  }
  
  if {$ret==0 } {
    set ret [ReadMainState $chs]
  }
  
  return $ret
}
# ***************************************************************************
# SlotsState
# ***************************************************************************
proc SlotsState {chs mc state} {
  global gaSet buffer
  puts "SlotsState $chs $mc \"$state\" [MyTime]"
  set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
  set com $gaSet(comMC.$chs.$mc)
  set ret [Send $com "exit all\r" "[Prompt]"] 
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure\r" "[Prompt]"] 
  if {$ret!=0} {return $ret}  
  foreach slot {1 2 3 4} {
    set ret [Send $com "slot $slot $state\r" "[Prompt]" 20] 
    if {$ret!=0} {
      set gaSet(fail) "Chassis-$chs MC-$mc. Can't change slot's $slot state to $state."
      return $ret
    }
  }
  set ret [Send $com "exit all\r" "[Prompt]"] 
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# IOcardTest
# ***************************************************************************
proc IOcardTest {} {
  puts "IOcardTest [MyTime]" ; update
  global gaSet buffer
  foreach chs {1 2} mc {1 2} {
    Status "IOcard Test of MC-$mc at Chassis-$chs"
    set com $gaSet(comMC.$chs.$mc)
    set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
    set ret [ExitToShell $com $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [Send $com "malloc 1 \r" "stam" 1] 
    #if {$ret!=0} {return $ret}
    set ret [regexp {value\s+=\s+\d+\s+=\s+(\w+)} $buffer - val]
    puts va:$val
    if {$ret==0} {return -1}
    foreach line {0 1} {
      set ret [Send $com "IPMC_I2C_Read_data (1,1,$line,$val,1)\r" "stam" 1] 
      #if {$ret!=0} {return $ret}
      set ret [Send $com "d $val,1\r" "f..."] 
      if {$ret!=0} {return $ret}
      set ret [regexp {:\s+66[\w]+} $buffer - 66val]
      if {$ret==0} {
        set gaSet(fail) "Chassis-$chs MC-$mc. I2C_Line$line is not 66"
        return -1
      } elseif {$ret==1} { 
        set ret 0
      }
    }
  }
  return $ret
}   
# ***************************************************************************
# PowerControllerTest
# ***************************************************************************
proc PowerControllerTest {} {
  puts "PowerControllerTest [MyTime]" ; update
  global gaSet buffer
  foreach chs {1 2} mc {1 2} {
    Status "PowerController Test of MC-$mc at Chassis-$chs"
    set com $gaSet(comMC.$chs.$mc)
    set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
    set ret [ExitToShell $com $chs $mc]
    if {$ret!=0} {return $ret}
    set ret [Send $com "wr8_add 0xf810008b,0xe3\r" ">"] 
    if {$ret!=0} {return $ret}
    set ret [Send $com "rd8_add 0xf8100070\r" ">"] 
    if {$ret!=0} {return $ret}
    set ret [regexp {data =\s+(\w+)\s} $buffer - dutVal]
    puts dutVal:$dutVal
    if {$ret==0} {return -1}
    if {$dutVal!=$gaSet(pwrC)} {
      set gaSet(fail) "Chassis-$chs MC-$mc. PowerController is $dutVal. Should be $gaSet(pwrC)"  
      return -1
    }
    set ret [Send $com "wr8_add 0xf810008b,0xc5\r" ">"] 
    if {$ret!=0} {return $ret}
    set ret [Send $com "wr8_add 0xf810008b,0x00\r" ">"] 
    if {$ret!=0} {return $ret}
  }
  return $ret
}   
# ***************************************************************************
# TerminalTimeOut
# ***************************************************************************
proc TerminalTimeOut {chs mc} {
  global gaSet buffer
  puts "TerminalTimeOut $chs $mc [MyTime]" ; update
  Status "Set of Terminal Time Out at MC-$mc of Chassis-$chs"
  set com $gaSet(comMC.$chs.$mc)
  set gaSet(fail) "Communication with MC-$mc of Chassis-$chs fail"
  set ret [Send $com "exit all\r" [Prompt]]
  if {$ret!=0} {return $ret}
  set ret [Send $com "config terminal\r" [Prompt]]
  if {$ret!=0} {return $ret}
  for {set i 1} {$i<=24} {incr i} {
    set ret [Send $com "timeout forever\r" [Prompt]]
    if {$ret!=0} {return $ret}
    if {[string match {*DB is locked for configuration*} $buffer]==1} {
      puts "TimeOut at MC-$mc of Chassis-$chs i:$i"
      set ret [Wait "Wait for the DB unlocking at Chassis-$chs MC-$mc" 15 white]
      if {$ret!=0} {return $ret} 
      set gaSet(fail) "Chassis-$chs MC-$mc. Can't set the terminal timeout"
      set ret -1 
    } else {
      break
    }
  }
  return $ret
}  
# ***************************************************************************
# ManualSwitchTool
# ***************************************************************************
proc ManualSwitchTool {} {
  global gaSet gaGui
  pack forget $gaGui(frFailStatus) ; update
  puts "ManualSwitchTool [MyTime]" ; update
  set gaSet(act) 1
  catch {RLEH::Close}
  catch {RLSerial::Close $gaSet(comMC.1.1)}
  catch {RLSerial::Close $gaSet(comMC.2.1)}
  catch {RLSerial::Close $gaSet(comMC.1.2)}
  catch {RLSerial::Close $gaSet(comMC.2.2)}
  
  RLEH::Open
  set ret [ComOpen]
  if {$ret!=0} {return $ret}
  
  foreach chs {1 2} { 
    set ret [ReadPrimaryMC $chs]
    puts "ret1 of ReadPrimaryMC chs-$chs: $ret"
    if {$ret=="A"} {
      set mc 1
      set com $gaSet(comMC.$chs.1)
    } elseif {$ret=="B"} {
      set mc 2
      set com $gaSet(comMC.$chs.2)
    } else {
      return $ret
    }
    
    set ret [ManualSwitch $chs $com]
    if {$ret!=0} {return $ret}
  }
                      
  catch {RLSerial::Close $gaSet(comMC.1.1)}
  catch {RLSerial::Close $gaSet(comMC.2.1)}
  catch {RLSerial::Close $gaSet(comMC.1.2)}
  catch {RLSerial::Close $gaSet(comMC.2.2)}
  catch {RLEH::Close}
  Status "Done"
  return $ret
}

# ***************************************************************************
# SlotsStateTool
# ***************************************************************************
proc SlotsStateTool {} {
  global gaSet gaGui
  pack forget $gaGui(frFailStatus) ; update
  puts "SlotsStateTool [MyTime]" ; update
  
  catch {RLEH::Close}
  catch {RLSerial::Close $gaSet(comMC.1.1)}
  catch {RLSerial::Close $gaSet(comMC.2.1)}
  catch {RLSerial::Close $gaSet(comMC.1.2)}
  catch {RLSerial::Close $gaSet(comMC.2.2)}
  
  RLEH::Open
  set ret [ComOpen]
  if {$ret!=0} {return $ret}

  foreach chs {1 2} { 
    set ret [ReadPrimaryMC $chs]
    puts "ret1 of ReadPrimaryMC chs-$chs: $ret"
    if {$ret=="A"} {
      set mc$chs 1
    } elseif {$ret=="B"} {
      set mc$chs 2
    } else {
      return $ret
    }
    
    set ret [SlotsState $chs [set mc$chs] "shutdown"]
    if {$ret!=0} {return $ret}
#     set ret [SlotsState $chs $mc "no shutdown"]
#     if {$ret!=0} {return $ret}
  }
  foreach chs {1 2} { 
    set ret [SlotsState $chs [set mc$chs] "no shutdown"]
    if {$ret!=0} {return $ret}
  }
    
  Wait "Wait for card's up" 30 white
  
  foreach chs {1 2} {
    set ret [IoCardsShowStatus $chs [set mc$chs]]
    if {$ret!=0} {return $ret}
  }
                   
  catch {RLSerial::Close $gaSet(comMC.1.1)}
  catch {RLSerial::Close $gaSet(comMC.2.1)}
  catch {RLSerial::Close $gaSet(comMC.1.2)}
  catch {RLSerial::Close $gaSet(comMC.2.2)}
  catch {RLEH::Close}
  return $ret
}

# ***************************************************************************
# ClearAlarmTool
# ***************************************************************************
proc ClearAlarmTool {} {
  global gaSet gaGui
  set gaSet(act) 1
  pack forget $gaGui(frFailStatus) ; update
  puts "ClearAlarmTool [MyTime]" ; update
  
  catch {RLEH::Close}
  ComClose
  
  RLEH::Open
  set ret [ComOpen]
  if {$ret!=0} {return $ret}
  
  foreach chs {1 2} { 
    set ret [ReadPrimaryMC $chs]
    puts "ret1 of ReadPrimaryMC chs-$chs: $ret"
    if {$ret=="A"} {
      set mc 1
      set com $gaSet(comMC.$chs.1)
    } elseif {$ret=="B"} {
      set mc 2
      set com $gaSet(comMC.$chs.2)
    } else {
      return $ret
    }
    
    set ret [ClearAlarms $chs $mc]
    if {$ret!=0} {return $ret}
  }
                      
  ComClose
  catch {RLEH::Close}
  Status "Done"
  return $ret
}

# ***************************************************************************
# ReadAlarmsTool
# ***************************************************************************
proc ReadAlarmsTool {} {
  global gaSet gaGui
  pack forget $gaGui(frFailStatus) ; update
  puts "ReadAlarmsTool [MyTime]" ; update
  set gaSet(act) 1
  catch {RLEH::Close}
  ComClose
  
  RLEH::Open
  set ret [ComOpen]
  if {$ret!=0} {return $ret}
  
  foreach chs {1 2} { 
    set ret [ReadPrimaryMC $chs]
    puts "ret1 of ReadPrimaryMC chs-$chs: $ret"
    if {$ret=="A"} {
      set mc 1
      set com $gaSet(comMC.$chs.1)
    } elseif {$ret=="B"} {
      set mc 2
      set com $gaSet(comMC.$chs.2)
    } else {
      return $ret
    }
    
    set ret [ReadAlarms $chs $mc]
    
  }
                      
  ComClose
  catch {RLEH::Close}
  Status "Done"
  return $ret
}

# ***************************************************************************
# TdmBusFanTest
# ***************************************************************************
proc TdmBusFanTest {chs actMc rmvMc} {
  puts "TdmBusFanTest $chs $actMc $rmvMc [MyTime]" ; update
  global gaSet buffer
  global gRelayState 
  set gRelayState red
  IPRelay-LoopRed

  set gaSet(fail) "Communication with MC-$actMc at Chassis-$chs fail"
  Status "TdmBusFanTest Test of MC-$rmvMc at Chassis-$chs"
  set com $gaSet(comMC.$chs.$actMc)
  set ret [ExitToShell $com $chs $actMc]
  if {$ret!=0} {return $ret}
  
  set ret [DialogBox -title "TdmBusFan Test" -message "Disconnect MC-$rmvMc from Chassis-$chs." -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret!="OK"} {return -2}
  after 5000
  
  set ret [ReadFan $chs $actMc 66]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "wr8_add(0xf8100020,0x3f)\r" >]
  if {$ret!=0} {return $ret}
  set ret [ReadFan $chs $actMc ff]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "wr8_add(0xf8100020,0x1f)\r" >]
  if {$ret!=0} {return $ret}
  set ret [ReadFan $chs $actMc 66]
  if {$ret!=0} {return $ret}
  
  set ret [DialogBox -title "TdmBusFan Test" -message "Reconnect MC-$rmvMc to Chassis-$chs." -type "OK Abort" -icon [pwd]/images/info.ico]
  if {$ret!="OK"} {
    return -2
  } elseif {$ret=="OK"} {
    set gaSet(fail) ""
    set ret 0
  }  
  return $ret
}
# ***************************************************************************
# ReadFan
# ***************************************************************************
proc ReadFan {chs mc val} {
  global gaSet buffer
  puts "ReadFan $chs $mc $val [MyTime]" ; update
  puts "Read fan register ($val) at MC-$mc of Chassis-$chs [MyTime]"
  set com $gaSet(comMC.$chs.$mc)
  set ret 0
  if {$ret==0} {
    set ret [Send $com "rfan(1,1)\r" >]   
    if [string match {*command not recognized*} $buffer] {
      set ret [Send $com "rfan(1,1)\r" >]
    } 
    if {$ret==0} {
      set dutVal NA
      set ret [regexp {Value\s+=\s+0x(\w+),\s} $buffer - dutVal]
      if {$ret==1 && [string toupper $dutVal]==[string toupper $val]} {
        set ret 0
      } else {
        set ret -1
        set gaSet(fail) "Chassis-$chs MC-$mc. The value is $dutVal. Should be $val"
      }
    }
  }
  return $ret
} 
# ***************************************************************************
# ReadIO
# ***************************************************************************
proc ReadIO {chs mc reg val 10secLoopQty io state} {
  global gaSet buffer
  #puts "ReadBP $chs $mc $reg $val [MyTime]" ; update
  puts "Read register $reg ($val) at MC-$mc IO-$io ($state) of Chassis-$chs [MyTime]"
  set com $gaSet(comMC.$chs.$mc)
  set ret 0
  for {set i 1} {$i<=$10secLoopQty} {incr i} {
    if {$gaSet(act)==0} {return -2}  
    set ret [Send $com "rd8_add $reg\r" >]   
    if [string match {*command not recognized*} $buffer] {
      set ret [Send $com "rd8_add $reg\r" >]
    } 
    if {$ret==0} {
      set dutVal NA
      set ret [regexp {data =\s+(\w+)\s} $buffer - dutVal]
      if {$ret==1 && [string toupper $dutVal]==[string toupper $val]} {
        set ret 0
        break
      } else {
        set ret -1
        #puts "[MyTime] The value of $reg is $dutVal. Should be $val "
        Wait "Wait for IO-$io BUS $state at Chassis-$chs ($i)" 10 white
        #set gaSet(fail) "Chassis-$chs MC-$mc. The value of $reg is $dutVal. Should be $val"
      }
    }
  }
  if {$ret==0} {
    set gaSet(fail) ""
  } elseif {$ret=="-1"} {  
    set gaSet(fail) "Chassis-$chs MC-$mc IO-$io. The value of $reg is $dutVal. Should be $val"
  }  
  return $ret
} 

# ***************************************************************************
# ReadMainState
# ***************************************************************************
proc ReadMainState {chs} {
  global gaSet buffer 
  Status "Read MCs' state at chassis $chs"
  set ret [WaitForUp $chs]
  if {$ret<0} {return $ret}
  set mc $ret
  set ret [Login $chs $mc]
  if {$ret!=0} {return $ret}
  set com $gaSet(comMC.$chs.$mc)
  set ret [Send $com "exit all\r" "[Prompt]"]
  set ret [Send $com "configure\r" "config"]
  if {$ret==0} {    
    for {set i 1} {$i<=32} {incr i} {            
      set ret [Send $com "show cards-summary\r" "Fan"]
      set gaSet(fail) "Fail in read \'show cars-summary\' at chassis $chs" 
      if {$ret!=0} {return $ret}
   
      regexp {Main-A.+Main-B} $buffer matA
      set upQtyA [regexp -all {Up} $matA]
      regexp {Main-B.+1\s+10G} $buffer matB
      set upQtyB [regexp -all {Up} $matB]
          
      if {$upQtyA==2 && $upQtyB==2} {break}
      
      set ret [Wait "Chassis-$chs. Wait ($i) for Up Up" 15 white]
      if {$ret!=0} {return $ret}
      if {$upQtyA!=2} {
        set ret -1
        set gaSet(fail) "\'Admin\' or \'Oper\' state of Main-A at chassis $chs  is Down" 
      }
      if {$upQtyB!=2} {
        set ret -1
        set gaSet(fail) "\'Admin\' or \'Oper\' state of Main-B at chassis $chs  is Down" 
      }
    }   
  }
  Send $com "exit all\r" "[Prompt]"
  if {$ret<=0} {                                             
    set gaSet(fail) "MC-$mc. Can't view Main-card status"
  } else {
    puts "PrimaryMC: $ret" ; update
    $gaSet(amc) configure -text $chs.$ret
  }
  return $ret
}

# ***************************************************************************
# Prompt
# ***************************************************************************
proc Prompt {} {
  global gaSet
  switch -exact -- $gaSet(uutOpt) {
    Regular - Telmex - LY_SYSTELE {return 5300}
    MSCEM {return MSCEM}   
    default {return 5300}
  }
}

# ***************************************************************************
# SetActiveSwPack
# ***************************************************************************
proc SetActiveSwPack {chs} {
  global gaSet buffer
  if {$chs=="1"} {
    set mcL [list 1 2]
  } elseif {$chs=="2"} {
    set mcL [list 2 1]
  }
  foreach mc $mcL {
    set com $gaSet(comMC.$chs.$mc)
    Power "1" off
    Power "2" off
    after 1000
    Power "1" on
    Power "2" on
    set startSec  [clock seconds]
    while 1 {
      after 1000
      set nowSec [clock seconds]
      set runSec [expr {$nowSec - $startSec}]
      if {$runSec> 120} {
        set gaSet(fail) "Login to Boot fail"
        return -1
      }
      set ret [Send $com "\r" "\[boot" 3]
      if {[string match {*boot (*} $buffer]==1 || [string match {*boot(*} $buffer]==1} {
        set ret 0
      }
      if {$ret==0} {break}
      if {$gaSet(act)=="-2"} {return -2} 
    }
    Status "Waiting for \"set-active 1 completed successfully\" in CH-$chs MC-$mc"
    set ret [Send $com "set-active 1\r" "completed successfully" 360] 
    if {$ret!=0} {
      set gaSet(fail) "Set active sw-pack to 1 in CH-$chs MC-$mc fail"
      return -1 
    }
  }
    
  set ret [Send $com "run\r" "validation" 20] 
  if {$ret!=0} {
    set gaSet(fail) "Run process of CH-$chs MC-$mc fail"
    return -1 
  }
  return 0
}  
# ***************************************************************************
# ActiveMngPort
# ***************************************************************************
proc ActiveMngPort {chs mc} {
  global gaSet buffer
  puts "[MyTime] ActiveMngPort $chs $mc"
  set com $gaSet(comMC.$chs.$mc)  
  set ret [Send $com "exit all\r\r" "[Prompt]"]
  if {$ret!=0} {
    set ret [Send $com "exit all\r\r" "[Prompt]"]
    if {$ret!=0} {
      set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
      return $ret
    }
  }
  set ret [Send $com "config\r" "config"]
  if {$ret!=0} {
    set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
    return $ret
  } 
  set ret [Send $com "port\r" "port"]
  if {$ret!=0} {
    set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
    return $ret
  } 
  if {$mc==1} {
    set mai main-a/0
  } elseif {$mc==2} {
    set mai main-b/0
  }
  set ret [Send $com "mng-ethernet $mai\r" "/0"]
  if {$ret!=0} {
    set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
    return $ret
  } 
  set ret [Send $com "no shutdown\r" "/0"]
  if {$ret!=0} {
    set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
    return $ret
  }
  set ret [Send $com "exit all\r\r" "[Prompt]"]
  if {$ret!=0} {
    set gaSet(fail) "Communication with MC-$mc at Chassis-$chs fail"
    return $ret
  }
  return $ret
}