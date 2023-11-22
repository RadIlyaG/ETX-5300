# ***************************************************************************
# RegBC
# ***************************************************************************
proc RegBC {lPassPair} {
  global gaSet gaDBox
  Status "BarCode Registration"
  puts "RegBC \"$lPassPair\"" ;  update
  set ret  -1
  set res1 -1
  set res2 -1
#   while {$ret != "0" } {
#     set ret [CheckBcOk $lPassPair]
#     puts "CheckBcOk res:$ret"
#     if { $ret == "-2" } {
#       foreach pair $lPassPair {
#         PairPerfLab $pair red
#       }
#       set logFileID [open c://logs//logFile-$gaSet(pair).txt a+]
#       puts $logFileID "User stop..[MyTime].."
#       close $logFileID
#       return $ret
#     }
# 	}	 	
  
  #set pairIndx -1
  foreach {ent1 ent2} [lsort -dict [array names gaDBox entVal*]] { }
  foreach pair $lPassPair {
    #incr pairIndx
    #set pair [lindex $lPassPair $pairIndx]
    foreach la {1 2} {
      set mac $gaSet($pair.mac$la)
      set barcode $gaSet($pair.barcode$la)
      set barcode$la $barcode
      #puts "pairIndx:$pairIndx pair:$pair"
      Status "Registration the LA110-${la}'s MAC. Pair $pair"
      set mr [file mtime $::RadAppsPath/MACReg.exe]
      set prevMr [clock scan "Wed Jan 22 23:20:40 2020"] ; # last working version, with 1 MAC
      if {$mr>$prevMr} {
        ## the newest MacReg
        set str "$::RadAppsPath/MACReg.exe /$mac / /$barcode /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE"
      } else {
        set str "$::RadAppsPath/MACReg.exe /$mac /$barcode /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE"
      } 
      puts "mr:<[clock format $mr]> prevMr:<[clock format $prevMr]> \n str<$str>"
      set res$la [string trim [catch {eval exec $str} retVal$la]]
      #set res$la [catch {exec c://MACReg.exe /$mac /$barcode /DISABLE /DISABLE /DISABLE /DISABLE} retVal$la]
      puts "Pair:$pair LA110-$la mac:$mac barcode:$barcode res$la:[set res$la] retVal$la:[set retVal$la] res$la:[set res$la]"
      update
      after 1000
      if {[set res$la]!=0} {
        set ret -1
        break
      }
    } 
#     if {$res1==0 && $res2==0} {
#       PairPerfLab $pair green
#       set txt "Pair $pair Pass Barcode (MAC:$gaSet($pair.mac1) barcode:$barcode1) (MAC:$gaSet($pair.mac2) barcode:$barcode2)"
#     } else {
#       PairPerfLab $pair red
#       set txt "Pair $pair Fail Barcode (MAC:$gaSet($pair.mac1) barcode:$barcode1) (MAC:$gaSet($pair.mac2) barcode:$barcode2)"
#     }
#     set logFileID [open c://logs//logFile-$gaSet(pair).txt a+]
#     puts $logFileID "Barcode-1 - $barcode1"
#     puts $logFileID "Barcode-2 - $barcode2"
#     close $logFileID 
    AddToLog "Barcode-1 - $barcode1 \nBarcode-2 - $barcode2"
    
    if ![file exists c://logs//macHistory.txt] {
      set id [open c://logs//macHistory.txt w]
      after 100
      close $id
    }
    set id [open c://logs//macHistory.txt a]
    foreach la {1 2} {
      puts $id "[MyTime] Tester:$gaSet(pair) Pair:$pair LA110-$la MAC:$gaSet($pair.mac$la) BarCode:[set barcode$la] res:[set res$la]"
    }      
    close $id
  
    if {$ret!=0} {
      break
    } 
  }  
  Status ""	  

  if {$res1 != 0 || $res2 != 0} {
	  set gaSet(fail)  "Fail to update Data-Base"
	  return -1 
	} else {
 		return 0 
  }
} 

# ***************************************************************************
# CheckBcOk
# ***************************************************************************
proc CheckBcOk {} {
	global  gaDBox  gaSet
  puts "CheckBcOk" ;  update
  if {$gaSet(useExistBarcode)==0} {
#     exec C:\\RLFiles\\tools\\Btl\\beep.exe
    set ret [DialogBox -title "BarCode" -text "Enter the MainCards' BarCodes" \
        -type "Ok Cancel" -entQty 2 -entPerRow 1 -entLab [list "Chassis 1 MC-A" "Chassis 2 MC-B"] \
        -icon [pwd]/images/info.ico] 
  	if {$ret != "Ok" } {
  	  return -2 
  	} else {
      foreach {ent1 ent2} [lsort -dict [array names gaDBox entVal*]] {
        set barcode1 [string toupper $gaDBox($ent1)]  
        set barcode2 [string toupper $gaDBox($ent2)]  
        puts "barcode1 == $barcode1 barcode2 == $barcode2"
  	    if {$barcode1 == $barcode2} {
  		    return -1 
  		  }
        if {[string length $barcode1]!=11 && [string length $barcode1]!=12} {
          return -1
        }
        if {[string length $barcode2]!=11 && [string length $barcode2]!=12} {
          return -1
        }
      }
      return 0  	
  	}
  } elseif {$gaSet(useExistBarcode)==1} {
    foreach la {1 2} {
      if ![info exists gaSet(barcode$la)] {
        set gaSet(useExistBarcode) 0
        return -1
      }
    }
    
    set gaSet(useExistBarcode) 0
    return 0
  }  
}
# ***************************************************************************
# ReadBarcode
# ***************************************************************************
proc ReadBarcode {} {
  global gaSet gaDBox
  puts "ReadBarcode" ;  update
  set ret -1
  catch {array unset gaDBox}
  while {$ret != "0" } {
    set ret [CheckBcOk]
    puts "CheckBcOk res:$ret"
    if { $ret == "-2" } {
      AddToLog "User stop..."
      #close $logFileID
      return $ret
    }
	}	
  set pairIndx -1
  foreach {ent1 ent2} [lsort -dict [array names gaDBox entVal*]] {
    incr pairIndx
    foreach ba {1 2} uut {1 2} {
      set barcode [string toupper $gaDBox([set ent$ba])]  
      set gaSet(barcode$uut) $barcode
      
      
      set res [catch {exec $gaSet(javaLocation)/java.exe -jar $::RadAppsPath/checkmac.jar $barcode AABBCCFFEEDD} retChk]
      puts "CheckMac res:<$res> retChk:<$retChk>" ; update
      if {$res=="1" && $retChk=="0"} {
        puts "No Id-MAC link"
        set gaSet(barcode$ba.IdMacLink) "noLink"
      } else {
        puts "Id-Mac link or error"
        set gaSet(barcode$ba.IdMacLink) "link"
      }
    }
  }    
  return $ret
}