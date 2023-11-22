
#.........................................................................................
#   File name: RLCom.tcl 
#   Written by yakov  14.12.1998 updated by Evgeni: 28/03/99	update by Semion 3.3.02 
# 															 update by Semion 28.3.04
#																 update by Eitan 22.1.09 ;update by Semion 13.01.2010
#   Abstract: This file operate with pc-com, use RLStubCom.dll (written by Semion)
#   To use this Librery you must load General one.
#   Librery Contents:
#           - Open
#           - Close 
#           - Send & Waitfor
#           - SendSlow & Waitfor 
#           - Waitfor
#           - Read
#           - FlushBuf
#           - DownLoad
#						- CtrlSet
#						- HwCtrlSet
#						- CtrlGet
#					  - GetOutQLen
#					  - ComFromFile
#
#   Examples: 
#                                 
#     RLCom::Open 2								                 Open COM by default
#                                 
#     RLCom::Open 2 9600 8 NONE 1	                 Open COM with parameters
#                                 
#     RLCom::Close 2							                 Close COM
#                                 
#     RLCom::Send 2 "dsp as\r" buffer ">"	         Send string with default delay time and waitfor option
#                                 
#     RLCom::Waitfor 2 "string we look for" buf 5	 Waitfor: resive string from Com in definite time
#                                 
#     RLCom::SendSlow 2 "dsp rev\r" 350 buf ">" 	 SendSlow: delay between characters 350 mSec
#                                 
#     RLCom::Read 2 buf														 Read: resive data from Com
#                                 
#     RLCom::FlushBuf 2														 FlushBuf: clear Com
#                                 
#     RLCom::DownLoad 1 autoexec.bat							 DownLoad: send file to COM
#
#     RLCom::HwCtrlSet 1 RTS 											 Set hardware control RTS&CTS
#																																	
#     RLCom::CtrlSet 7 -dtr OFF -rts ON					   Set controls DTR off RTS on
#																																	
#     set status [RLCom::CtrlGet 3]  							 Obtain statuses of controls DSR,DCD,CTS,RI
#
#		  RLCom::GetOutQLen 1												   Returns the number of characters in the output queue of the com port
#
#     RLCom::ComFromFile 1  test.txt							 Reads from the specified file and writes to the output queue of a COM port.
#
#..........................................................................................

package require RLEH 1.0
package require RLDCom 4.2 ;#Input local buffer added to 128k
package provide RLCom 4.21  

# set env(MYWORK) "c:\\program Files\\tcl\\work"
#                                 Opene namespace RLCom
 namespace eval RLCom { 
 namespace export Open Close Send SendSlow Waitfor Read FlushBuf DownLoad CtrlSet HwCtrlSet	CtrlGet GetOutQLen	ComFromFile
 
 global gMessage
 set gMessage ""                   

  #                               valid com 1-32
 variable gMaxComNum 
 variable gMinComNum
#                                 set internal globals variables (scope RLCom)
 set gMaxComNum 32                           
 set gMinComNum 1
  
#............................... Open ......................................
# 
#   Abstract: Open procedure use RLDLLOpenCom Port  dll to define com. 
#  
#   Inputs:Port [BaudRate][DataBits][Parity][StopBit] 
#     ___________________________________________________________   
#    : Port:  BaudRate  :  DataBits  :   Parity                  : 
#    :_____:____________:____________:___________________________:
#    : 1-8:  100-115.2 :     7,8    :   NONE,ODD,EVEN,MARK,SPACE:
#     
#   Outputs:  OK (0)   
#                                 
#   Example:   RLCom::Open 2 9600 8 NONE 1                     
#           
#.............................................................................

proc Open {args} {
#                                 global (import) from RLCom.dll
 global ERRMSG
#                                 Message to be send to EH 
 global gMessage
 
 variable gMaxComNum 
 variable gMinComNum

#                                 open COM with default parameters
 set gCOMdefault 1 
#                                 parameters number for COM open process
 set gCOMparamNumber 5 
 set indexNull 0
 set indexFirst 1
 set indexSecond 2
 set indexThird 3
 set indexFourth 4
 set parNONE 0
 set parODD 1
 set parEVEN 2
 set parMARK 3
 set parSPACE 4
 set OK 0
 
 #                                COM's number              
 set prtCom [lindex $args $indexNull]
 set rate [lindex $args $indexFirst]
 set data [lindex $args $indexSecond]
 set stpBit [lindex $args $indexFourth]
 set arrleng [llength $args]
  #                               sanity cheak
 if {($prtCom > $gMaxComNum)||($prtCom < $gMinComNum)|| \
     (($arrleng != $gCOMdefault) && ($arrleng != $gCOMparamNumber))} {
  set gMessage "Open: incorrect Com's number or wrong number of parameters"
  return [RLEH::Handle SAsyntax gMessage]
#                                      open Com 
#                                      ======== 
 } else {
#                                 open Com by default 
    if {$arrleng == $gCOMdefault} {  
     set err [RLDLLOpenCom $prtCom ]
#                                 open Com by diffolt      
#                                 from -13 to -44; 10000,10001 - syntax errors
     if {(-44 <= $err && $err <= -13) || (-10001 <= $err && $err <= -10000)} {
#                                 get error message from DLL     
      set gMessage $ERRMSG
      append gMessage "\nOpen: incorrect syntax while opend Com."
      return [RLEH::Handle SAsyntax gMessage]
#                                 from -511 to -90 and from -12 to -1 system errors      
     } elseif {(-511 <= $err && $err <= -90) || (-12 <= $err && $err <= -1)} {
        set gMessage $ERRMSG
        append gMessage "\nOpen: system error while opend Com."
        return [RLEH::Handle SAsystem gMessage]
     } elseif {$err == -516} {
        set gMessage $ERRMSG
        append gMessage "\n while open Com."
        return [RLEH::Handle SAsystem gMessage]
     } else {
        return $OK
     } 
 #                                     open Com with parameters      
    } else  {
       switch -- [lindex $args $indexThird] {
         NONE    { set parity $parNONE }
         ODD     { set parity $parODD  }
         EVEN    { set parity $parEVEN }
         MARK    { set parity $parMARK }
         SPACE   { set parity $parSPACE}
         default { set gMessage "Open: parity error while opend Com."
                   return [RLEH::Handle SAsyntax gMessage]
         } 
       }
#                                 opene Com with parameters                 
       set err [RLDLLOpenCom $prtCom $rate $data $parity $stpBit]
       if {(-44 <= $err && $err <= -13) || (-10001 <= $err && $err <= -10000)} {
        set gMessage $ERRMSG
        append gMessage "\nOpen: incorrect syntax while opend Com."
        return [RLEH::Handle SAsyntax gMessage]      
        } elseif {(-511 <= $err && $err <= -90) || (-12 <= $err && $err <= -1)} {
           set gMessage $ERRMSG
           append gMessage "\nOpen: system error while opend Com."
           return [RLEH::Handle SAsystem gMessage]
        } elseif {$err == -516} {
            set gMessage $ERRMSG
            append gMessage "\n while open Com."
            return [RLEH::Handle SAsystem gMessage]
        } else {
            return $OK
        }         
      }   
   }
}

 
# .............................. Close .....................................
#    
#   Abstract: Close procedure use RLDLLCloseCom dll to close com.
#       
#   Inputs: Number of Port to close (1-8).
#                  
#   Outputs: ERRMSG from RLDLLCloseCom.dll if bad, else OK = 0.
#   
# ..........................................................................

proc Close {args} {

#                                 global (import) from RLCom.dll
 global ERRMSG
#                                 Message to be send to EH 
 global gMessage

 variable gMaxComNum 
 variable gMinComNum
  
 set indexNull 0
 set noCOMnumber 0 
 set OK 0
 
 set port [lindex $args $indexNull]
  
 if {($port > $gMaxComNum) || ($port < $gMinComNum) || ($port == $noCOMnumber)} {
  set gMessage "Close: incorrect Com's number\n Com's range : $gMinComNum - $gMaxComNum."
  return [RLEH::Handle SAsyntax gMessage]
 } else {                               
    set err [RLDLLCloseCom $port]
    
    if {(-44 <= $err && $err <= -13) || (-10001 <= $err && $err <= -10000)} {
    set gMessage $ERRMSG
    append gMessage "\nClose: incorrect syntax while close Com."
    return [RLEH::Handle SAsyntax gMessage]
    } elseif {(-511 <= $err && $err <= -90) || (-12 <= $err && $err <= -1)} {
       set gMessage $ERRMSG
       append gMessage "\nClose: system error while close Com."
       return [RLEH::Handle SAsystem gMessage]
      } else {
         return $OK
        } 
   }
}


# .................................... Send ...................................
# 
#  Abstract: Send()-send string to COM 
#       
#  Inputs: -comNumber; 
#          -string to send;     
#          -receive buffer;
#          -pattern string for waitfor;          
#          -delay.
#       
#  Outputs: send only - if successed 0 - OK
#
#       send & waitfor: exit()- if syntax or system error
#                          -1 - didn't receive waitfor string in delay time (fail)
#                           0 - OK
# ................................................................................

proc Send {ip_ComNumber ip_TrString {op_Buffer buffer} {ip_RcvString ""} \
                                                          {ip_DelayTime 10}} {
#                                 global (import) from RLCom.dll
 global ERRMSG
#                                 Message to be send to EH 
 global gMessage

 variable gMaxComNum 
 variable gMinComNum
 
 set notInTime -510
 set OK 0
 set FAIL -1

 upvar $op_Buffer buf
 
 if {($ip_ComNumber > $gMaxComNum) || ($ip_ComNumber < $gMinComNum)} {
  set gMessage "Send: incorrect Com's number\n range: $gMinComNum - $gMaxComNum"
  return [RLEH::Handle SAsyntax gMessage]
 }         
 #                                      Send without waitfor 
 #                                      ====================
 if {$ip_RcvString == ""} {
 
  set err [ RLDLLFlushInQCom $ip_ComNumber ]          
  
  if {(-511 <= $err && $err <= -90) || (-12 <= $err && $err <= -1)} {
    #The windows 7 in FlushInQCom command some time mistakenly return err code, since ERRMSG =  "The operation completed successfully"
    if {[string match "*The operation completed successfully*" $ERRMSG]} {
      puts "mistakenly returned err code: $err"
    } else {  
       set gMessage $ERRMSG
       append gMessage "\nSend: system error while RLDLLFlushInQCom. Error code: $err"
       return [RLEH::Handle SAsystem gMessage]
    }
  }
   
  set err [ RLDLLSendCom $ip_ComNumber $ip_TrString ]
  if {(-44 <= $err && $err <= -13) || (-10001 <= $err && $err <= -10000)} {
#                                 get error message from DLL     
   set gMessage $ERRMSG
   append gMessage "\nSend: incorrect syntax while Send(no waitfor)"
   return [RLEH::Handle SAsyntax gMessage]
#                                 from -511 to -90 and from -12 to -1 system errors      
  } elseif {(-511 <= $err && $err <= -90) || (-12 <= $err && $err <= -1)} {
     set gMessage $ERRMSG
     append gMessage "\nSend: system error while Send(no waitfor)."
     return [RLEH::Handle SAsystem gMessage]
			#add by semion
		} elseif {$err == -515} {
							return $err

    } else {
#                                 Send without waitfor- successed        
       return $OK
      }
 #                                Send & waitfor 
 #                                ==============
 } else {
    set err [RLDLLFlushInQCom $ip_ComNumber]
    
    if {(-511 <= $err && $err <= -90) || (-12 <= $err && $err <= -1)} {
      #The windows 7 in FlushInQCom command some time mistakenly return err code, since ERRMSG =  "The operation completed successfully"
      if {[string match "*The operation completed successfully*" $ERRMSG]} {
        puts "mistakenly returned err code: $err"
      } else {  
         set gMessage $ERRMSG
         append gMessage "\nSend: system error while RLDLLFlushInQCom. Error code: $err"
         return [RLEH::Handle SAsystem gMessage]
      }
    }
    	#change by semion
    set err [ RLDLLSendCom $ip_ComNumber $ip_TrString ]
    if {(-44 <= $err && $err <= -13) || (-10001 <= $err && $err <= -10000)} {
#                                 get error message from DLL     
      set gMessage $ERRMSG
      append gMessage "\nSend: incorrect syntax while Send(with waitfor)"
      return [RLEH::Handle SAsyntax gMessage]
#                                 from -511 to -90 and from -12 to -1 system errors      
    } elseif {(-511 <= $err && $err <= -90) || (-12 <= $err && $err <= -1)} {
        set gMessage $ERRMSG
        append gMessage "\nSend: system error while Send(with waitfor)."
        return [RLEH::Handle SAsystem gMessage]
			   #add by semion
		  } elseif {$err == -515} {
				 			return $err

    } 
    set err [RLDLLWaitCom $ip_ComNumber buf $ip_RcvString $ip_DelayTime ]
    
    if {(-44 <= $err && $err <= -13) || (-10001 <= $err && $err <= -10000)} {
     set gMessage $ERRMSG
     append gMessage "\nSend&Waitfor: incorrect syntax while Send & waitfor"
     return [RLEH::Handle SAsyntax gMessage]
    } elseif {(-508 <= $err && $err <= -90) || (-12 <= $err && $err <= -1) || \
              ($err == -511)} {
       set gMessage $ERRMSG
       append gMessage "\nSend&Waitfor: system error while Send & waitfor."
       return [RLEH::Handle SAsystem gMessage]
      } elseif {$err == $notInTime} { 
         return $FAIL
        } else {
           return $OK 
          } 
   }
}

# ............................. SendSlow .............................
# 
#  Abstract: send string to com with delay between the letters
#            the buffer get only the content of the last letter 
#       
#  Inputs: -comNumber; 
#          -string to send; 
#          -delay between letters in mSec (range 0 - 10000)   
#          -receive buffer;
#          -pattern string for waitfor;          
#          -delay for waitfor.
#       
#  Outputs: send only  :   exit - if syntax or system error
#                           0   - OK 
#
#       send & waitfor :   exit - if syntax or system error
#                          -1   - didn't receive waitfor string in delay time (fail)
#                           0   - OK
# .......................................................................
proc SendSlow {ip_ComNumber ip_TrString {ip_LetterDelay 0} {op_Buffer buffer} {ip_RcvString ""} \
                                                          {ip_DelayTime 10}} {
#                                 global (import) from RLCom.dll
 global ERRMSG
#                                 Message to be send to EH 
 global gMessage

 variable gMaxComNum 
 variable gMinComNum
 
 set notInTime -510
 set OK 0
 set FAIL -1
 set lengthString [ string length $ip_TrString]
 
 upvar $op_Buffer buf

 if {(0 > $ip_LetterDelay) || $ip_LetterDelay > 10000} {
  set gMessage "SendSlow: incorrect letter's delay\nrange:(0-10000)mSec"
  return [RLEH::Handle SAsyntax gMessage]  
 }
   
 if {($ip_ComNumber > $gMaxComNum) || ($ip_ComNumber < $gMinComNum)} {
  set gMessage "SendSlow: incorrect Com's number\nrange:$gMinComNum-$gMaxComNum"
  return [RLEH::Handle SAsyntax gMessage]
 }         
 #                                SendSlow without waitfor 
 #                                ========================
 if {$ip_RcvString == ""} {
 
  set err [ RLDLLFlushInQCom $ip_ComNumber ]          
  
  if {(-511 <= $err && $err <= -90) || (-12 <= $err && $err <= -1)} {
    #The windows 7 in FlushInQCom command some time mistakenly return err code, since ERRMSG =  "The operation completed successfully"
    if {[string match "*The operation completed successfully*" $ERRMSG]} {
      puts "mistakenly returned err code: $err"
    } else {  
       set gMessage $ERRMSG
       append gMessage "\nSend: system error while RLDLLFlushInQCom. Error code: $err"
       return [RLEH::Handle SAsystem gMessage]
    }
  }
  
  for {set n 0} {$n < [expr $lengthString]} {incr n} {
     RLDLLSendCom $ip_ComNumber [string index $ip_TrString $n]
     set x 0
     after [expr $ip_LetterDelay+1] {set x 1}
     vwait x
  }

  if {(-44 <= $err && $err <= -13) || (-10001 <= $err && $err <= -10000)} {
#                                 get error message from DLL     
   set gMessage $ERRMSG
   append gMessage "\nSendSlow: syntax error while SendSlow(no waitfor)"
   return [RLEH::Handle SAsyntax gMessage]
#                                 from -511 to -90 and from -12 to -1 system errors      
  } elseif {(-511 <= $err && $err <= -90) || (-12 <= $err && $err <= -1)} {
     set gMessage $ERRMSG
     append gMessage "\nSendSlow: system error while SendSlow(no waitfor)."
     return [RLEH::Handle SAsystem gMessage]
    } else {
#                                 Send without waitfor- successed        
       return $OK
      }
 #                                SendSlow & waitfor 
 #                                ==================
 } else {
    set err [RLDLLFlushInQCom $ip_ComNumber]
    
    if {(-511 <= $err && $err <= -90) || (-12 <= $err && $err <= -1)} {
      #The windows 7 in FlushInQCom command some time mistakenly return err code, since ERRMSG =  "The operation completed successfully"
      if {[string match "*The operation completed successfully*" $ERRMSG]} {
        puts "mistakenly returned err code: $err"
      } else {  
         set gMessage $ERRMSG
         append gMessage "\nSend: system error while RLDLLFlushInQCom. Error code: $err"
         return [RLEH::Handle SAsystem gMessage]
      }
    }
    for {set n 0} {$n < [expr $lengthString-1]} {incr n} {
     RLDLLSendCom $ip_ComNumber [string index $ip_TrString $n]
     set x 0
     after [expr $ip_LetterDelay+1] {set x 1}
     vwait x
    }
    RLDLLWaitCom $ip_ComNumber buf "" 0
    RLDLLFlushInQCom $ip_ComNumber
 	 set buf ""
    RLDLLSendCom $ip_ComNumber [string index $ip_TrString [expr $lengthString-1]]
    set err [RLDLLWaitCom $ip_ComNumber buf $ip_RcvString $ip_DelayTime]
    
    if {(-44 <= $err && $err <= -13) || (-10001 <= $err && $err <= -10000)} {
     set gMessage $ERRMSG
     append gMessage "\nSendSlow&Waitfor: syntax error while SendSlow & waitfor"
     return [RLEH::Handle SAsyntax gMessage]
    } elseif {(-508 <= $err && $err <= -90) || (-12 <= $err && $err <= -1) || \
              ($err == -511)} {
       set gMessage $ERRMSG
       append gMessage "\nSendSlow&Waitfor: system error while SendSlow & waitfor."
       return [RLEH::Handle SAsystem gMessage]
      } elseif {$err == $notInTime} { 
         return $FAIL
        } else {
           return $OK 
          } 
   }
}


# .................................... Waitfor ...................................
# 
#  Abstract: Waitfor()-wait for string from COM 
#       
#  Inputs: -comNumber; 
#          -receive buffer;
#          -pattern string for waitfor;          
#          -delay.
#       
#  Outputs:  waitfor:  exit()- if syntax or system error
#                         -1 - didn't receive waitfor string in delay time (fail)
#                          0 - OK
# ................................................................................

proc Waitfor {ip_ComNumber {op_Buffer buffer} {ip_RcvString ""} {ip_DelayTime 10}} {
                                                          
#                                 global (import) from RLCom.dll
 global ERRMSG
#                                 Message to be send to EH 
 global gMessage

 variable gMaxComNum 
 variable gMinComNum
 
 set notInTime -510
 set OK 0
 set FAIL -1
 
 upvar $op_Buffer buf
 
 if {($ip_ComNumber > $gMaxComNum) || ($ip_ComNumber < $gMinComNum)} {
  set gMessage "Waitfor: incorrect Com's number\n range: $gMinComNum - $gMaxComNum"
  return [RLEH::Handle SAsyntax gMessage]
 }         
  
 set err [RLDLLWaitCom $ip_ComNumber buf $ip_RcvString $ip_DelayTime ]
    
 if {(-44 <= $err && $err <= -13) || (-10001 <= $err && $err <= -10000)} {
  set gMessage $ERRMSG
  append gMessage "\nWaitfor: incorrect syntax while Waitfor"
  return [RLEH::Handle SAsyntax gMessage]
 } elseif {(-508 <= $err && $err <= -90) || (-12 <= $err && $err <= -1) || \
           ($err == 511)} {
    set gMessage $ERRMSG
    append gMessage "\nWaitfor: system error while Waitfor."
    return [RLEH::Handle SAsystem gMessage]
   } elseif {$err == $notInTime} { 
      return $FAIL
     } else {
        return $OK 
       } 
}

# .................................... Read ...................................
# 
#  Abstract: Read()-read data from COM 
#       
#  Inputs: -comNumber; 
#          -receive buffer;
#                 
#  Outputs:  Read:    exit()- if fail read Com
#                         0 - OK
# .............................................................................

proc Read {ip_ComNumber {op_Buffer buffer}} {
                                                          
#                                 global (import) from RLCom.dll
 global ERRMSG
#                                 Message to be send to EH 
 global gMessage

 variable gMaxComNum 
 variable gMinComNum
 
 set OK 0
 
 upvar $op_Buffer buf
 
 if {($ip_ComNumber > $gMaxComNum) || ($ip_ComNumber < $gMinComNum)} {
  set gMessage "Read: incorrect Com's number\n range: $gMinComNum - $gMaxComNum"
  return [RLEH::Handle SAsyntax gMessage]
 }         
 set err [RLDLLReadCom $ip_ComNumber buf]
    
 if {(-44 <= $err && $err <= -13) || (-10001 <= $err && $err <= -10000)} {
  set gMessage $ERRMSG
  append gMessage "\nRead: incorrect syntax while read Com."
  return [RLEH::Handle SAsyntax gMessage]
 } elseif {(-511 <= $err && $err <= -90) || (-12 <= $err && $err <= -1)} {
    set gMessage $ERRMSG
    append gMessage "\nRead: system error while read Com."
    return [RLEH::Handle SAsystem gMessage]
   } else {
      return $OK                         
     } 
}


# .................................... FlushBuf .................................
# 
#  Abstract: FlushBuf()-clear data from COM buffer
#       
#  Inputs: -comNumber; 
#
#  Outputs:  waitfor: exit()- if fail clear buffer
#                     0- ok
# ...............................................................................

proc FlushBuf {ip_ComNumber} {
                                                          
#                                 global (import) from RLCom.dll
 global ERRMSG
#                                 Message to be send to EH 
 global gMessage

 variable gMaxComNum 
 variable gMinComNum
 
 set OK 0
 
 if {($ip_ComNumber > $gMaxComNum) || ($ip_ComNumber < $gMinComNum)} {
  set gMessage "FlushBuf: incorrect Com's number\n range: $gMinComNum - $gMaxComNum"
  return [RLEH::Handle SAsyntax gMessage]
 }         
 set err [RLDLLFlushInQCom $ip_ComNumber]
 if {(-511 <= $err && $err <= -90) || (-12 <= $err && $err <= -1)} {
    #The windows 7 in FlushInQCom command some time mistakenly return err code, since ERRMSG =  "The operation completed successfully"
    if {[string match "*The operation completed successfully*" $ERRMSG]} {
      puts "mistakenly returned err code: $err"
    } else {  
       set gMessage $ERRMSG
       append gMessage "\nSend: system error while RLDLLFlushInQCom. Error code: $err"
       return [RLEH::Handle SAsystem gMessage]
    }
 } else {
    return $OK
   } 
}
# .................................... DownLoad .................................
# 
#  Abstract: DownLoad()- send file to COM 
#       
#  Inputs: -comNumber, fileName 
#
#  Outputs: exit()- if syntax or system error
#               0 - OK
#   Example: 
#           RLCom::DownLoad 1 autoexec.bat
#
# ................................................................................

proc DownLoad {ip_ComNumber ip_FileName} {

#                                 global (import) from RLCom.dll
 global ERRMSG
#                                 Message to be send to EH 
 global gMessage
 
 variable gMaxComNum 
 variable gMinComNum

 set prtCom $ip_ComNumber
 set FALSE 0
 set OK 0
 
#                                 sanity cheak
 if {($prtCom > $gMaxComNum) || ($prtCom < $gMinComNum)} {
  set gMessage "DownLoad: incorrect Com's number."
  return [RLEH::Handle SAsyntax gMessage]
 }
#                                 check if file exist 
 if {[set res [file exists $ip_FileName]] == $FALSE} {
  set gMessage "DownLoad: File not found:  incorrect path"
  return [RLEH::Handle SAsyntax gMessage]
 }
 set err [RLDLLXmDownLoadCom $prtCom $ip_FileName]
#                                 from -13 to -44; 10000,10001 - syntax errors
 if {(-44 <= $err && $err <= -13) || (-10001 <= $err && $err <= -10000)} {
#                                 get error message from DLL     
  set gMessage $ERRMSG
  append gMessage "\nDownLoad: incorrect syntax while DownLoad file via Com."
  return [RLEH::Handle SAsyntax gMessage]
#                                 from -511 to -90 and from -12 to -1 system errors      
 } elseif {(-511 <= $err && $err <= -90) || (-12 <= $err && $err <= -1)} {
    set gMessage $ERRMSG
    append gMessage "\nDownLoad: system error while DownLoad file via Com."
    return [RLEH::Handle SAsystem gMessage]
   } else {
      return $OK
     } 
}

#*************************************************************************
#**                        CtrlSet
#** 
#** Absrtact: Set DTR or RTS of any com to ON or OFF
#**   
#**   Inputs:  
#**            args   parameters and their value
#**  											ip_com:	1-32.
#**            -dtr   : OFF;ON.
#**            -rts   : OFF;ON.
#**  
#**   Outputs: 
#**           return  0                    if success 
#**           error message be RLEH        if error                  
#** Example:                        
#**         RLCom::CtrlSet 1 -dtr OFF 
#**         RLCom::CtrlSet 7 -dtr OFF -rts ON
#**                              
#*************************************************************************

proc CtrlSet { args } {

  global ERRMSG
  #Message to be send to EH 
  global gMessage


  set arrleng      [llength $args]
  set maxarg       5
  set minarg       3
  set ok           0
  set fail        -1
  
  if { $arrleng > $maxarg|| $arrleng < $minarg }  {
    set gMessage "Set CtrlCom:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  } 

  set com [ lindex $args 0 ]
  #remove com and insert command line to variable lCommandLine
  set lCommandLine [ lrange $args 1 end ] 

  foreach {param val}   $lCommandLine   {
   
    switch -exact -- $param  {
    
      -dtr {															
             if { $val == "ON"}  {
													  set idValue 1	
													} elseif	{$val == "OFF"} {
													    set idValue 0
													} else {
                 set gMessage "RLDLLSetDTRCom:  Wrong value of parameter $val (must be ON or OFF)"
                 return [RLEH::Handle SAsyntax gMessage]
             }
             if {[set err [RLDLLSetDTRCom $com $idValue]]}  {
               set gMessage $ERRMSG
               append gMessage "\nERROR while RLDLLSetDTRCom."
               return [RLEH::Handle SAsyntax gMessage]
             }
         
      }

      -rts {															
             if { $val == "ON"}  {
													  set idValue 1	
													} elseif	{$val == "OFF"} {
													    set idValue 0
													} else {
                 set gMessage "RLDLLSetRTSCom:  Wrong value of parameter $val (must be ON or OFF)"
                 return [RLEH::Handle SAsyntax gMessage]
             }
             if {[set err [RLDLLSetRTSCom $com $idValue]]}  {
               set gMessage $ERRMSG
               append gMessage "\nERROR while RLDLLSetRTSCom."
               return [RLEH::Handle SAsyntax gMessage]
             }
         
      }
    
      default {
                set gMessage "CtrlSet:  Wrong name of parameter $param"
                return [RLEH::Handle SAsyntax gMessage]
      }
    
    }
  }
  return $ok
}


#**************************************************************************
#**                        CtrlGet
#** 
#** Absrtact: Obtain status of signals: DSR,CTS,DCD,RI
#**   
#**   Inputs:  
#**            args   parameters and their value
#**  											ip_comPort:	        com port 1-32
#**  
#**   Outputs: 
#**           return  Controls status                    if success 
#**           error message be RLEH                      if error                  
#** Example:                        
#**         set status [RLCom::CtrlGet 3]  
#**                              
#**************************************************************************

proc CtrlGet { args } {

  global ERRMSG
  #Message to be send to EH 
  global gMessage


  set arrleng      [llength $args]
  
  if { $arrleng != 1}  {
    set gMessage "CtrlGet:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  } 

  set comAddr     [ lindex $args 0 ]

  if {[set err [RLDLLGetStCtrlCom $comAddr aCtrlState]]}  {
    set gMessage $ERRMSG
    append gMessage "\nERROR while RLDLLGetStCtrlCom."
    return [RLEH::Handle SAsyntax gMessage]
  }

  return [array get aCtrlState]
}


#*************************************************************************
#**                        HwCtrlSet
#** 
#** Absrtact: Set or clear Hardware control of com
#**   
#**   Inputs:  
#**            args   parameters  and their value
#**  										ip_com:	1-32.
#**            hwCtrl: NONE, RTS, RTS_DTR
#**  
#**   Outputs: 
#**           return  0                    if success 
#**           error message be RLEH        if error                  
#** Example:                        
#**         RLCom::HwCtrlSet 1 RTS 
#**         RLCom::HwCtrlSet 2 RTS_DTR
#**         RLCom::HwCtrlSet 7 NONE
#**                              
#*************************************************************************

proc HwCtrlSet { args } {

  global ERRMSG
  #Message to be send to EH 
  global gMessage


  set arrleng      [llength $args]
  set ok           0
  set fail        -1
  
  if { $arrleng != 2 }  {
    set gMessage "HwCtrlSet:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  } 

  set com    [ lindex $args 0 ]
  set hwCtrl [ lindex $args 1 ]

  if { $hwCtrl == "NONE"}  {
				set idValue 0	
		} elseif	{$hwCtrl == "RTS"} {
						set idValue 1
		} elseif {$hwCtrl == "RTS_DTR"} {
 					set idValue 2
		} else {
      set gMessage "HwCtrlSet:  Wrong value of parameter $hwCtrl (must be NONE or RTS or RTS_DTR)"
      return [RLEH::Handle SAsyntax gMessage]
  }
  if {[set err [RLDLLSetHwCtrlCom $com $idValue]]}  {
    set gMessage $ERRMSG
    append gMessage "\nERROR while HwCtrlSet."
    return [RLEH::Handle SAsyntax gMessage]
  }
         
  return $ok
}

# .................................... GetOutQlen ................................
# 
#  Abstract: Returns the number of characters in the output queue of the com port
#       
#  Inputs:  ip_ComNumber (1-32); 
#
#  Outputs: len - success
#						ERRMSG - fail 
# Example:                        
#         RLCom::GetOutQLen 1  
# ................................................................................

proc GetOutQLen {ip_ComNumber} {
                                                          
#	global (import) from RLCom.dll
	global ERRMSG
#	Message to be send to EH 
	global gMessage

	variable gMaxComNum 
	variable gMinComNum
  
	if {($ip_ComNumber > $gMaxComNum) || ($ip_ComNumber < $gMinComNum)} {
		set gMessage "GetOutQlen: incorrect Com's number\n range: $gMinComNum - $gMaxComNum"
		return [RLEH::Handle SAsyntax gMessage]
	} 
        
	set res [RLDLLGetOutQLenCom $ip_ComNumber byteCount]
	if {$res == -2} {
		set gMessage $ERRMSG
		append gMessage "\nGetOutQlen: Invalid Port Number."
		return [RLEH::Handle SAsystem gMessage]
	} elseif {$res == -3} {
		set gMessage $ERRMSG
		append gMessage "\nGetOutQlen: Port Is Not Open."
		return [RLEH::Handle SAsystem gMessage]
	} else {
		return $byteCount
	} 
}

# .................................... ComFromFile .....................................
# 
#  Abstract: Reads from the specified file and writes to the output queue of a COM port.
#       
#  Inputs: ip_ComNumber (1-32);
#					 ip_File (full file path)
#					 ip_FileType (ascii(1)/binary(0))
#
#  Outputs: 0 - success
#						ERRMSG - fail 
# Example:                        
#         RLCom::ComFromFile 1  test.txt
#         RLCom::ComFromFile 2  test.asm	binary
# ......................................................................................

proc ComFromFile {ip_ComNumber ip_FileName {ip_FileType ascii}} {
                                                          
#	global (import) from RLCom.dll
	global ERRMSG
#	Message to be send to EH 
	global gMessage

	variable gMaxComNum 
	variable gMinComNum
  set fail        -1
  
	if {($ip_ComNumber > $gMaxComNum) || ($ip_ComNumber < $gMinComNum)} {
		set gMessage "ComFromFile: incorrect Com's number\n range: $gMinComNum - $gMaxComNum"
		return [RLEH::Handle SAsyntax gMessage]
	}
  if {[file exists $ip_FileName] == 0} {
		set gMessage "ComFromFile: The File $ip_FileName Does Not Exist"
		return [RLEH::Handle SAsyntax gMessage]
  }
	set ip_FileType [string tolower $ip_FileType]
	if {$ip_FileType == "ascii"} {
		set fileType 1
	} elseif {$ip_FileType == "binary"} {
		set fileType 0
	} else {
		set gMessage "ComFromFile: Ilegal File Type - File Type Should be ascii or binary"
		return [RLEH::Handle SAsyntax gMessage]
	}
  set fileSize [file size $ip_FileName]  
  #puts "tclfileSize: $fileSize" 
	set res [RLDLLComFromFile $ip_ComNumber $ip_FileName $fileType len]
  #puts "sent bytes by RLDLL: $len" 
	if {$res < 0} {
		set gMessage $ERRMSG"
		if {$res == -3} {
			append gMessage "\ComFromFile: Port Is Not Open"
			return [RLEH::Handle SAsystem gMessage]
		} elseif {$res == -13} {
			append gMessage "\ComFromFile: Invalid Parameter"
			return [RLEH::Handle SAsystem gMessage]
		} else {
			if {$res == -91} {
				append gMessage "\ComFromFile: File Read Error Occured"
			} elseif {$res == -99} {
				append gMessage "\ComFromFile: I/O Operation Timed Out"
			} elseif {$res == -1} {
				append gMessage "\ComFromFile: Error While Open File"
			} elseif {$res == -999} {
				#append gMessage "\ComFromFile: The file was not fully transfered"
			}
			return [$fail]
		}
	} else {
		set loop 0
		while {[GetOutQLen $ip_ComNumber] != 0} {
		  incr loop
			if {$loop == 10} {
				break
			}
		}
		return $res
	} 
}

 
#                                 RLCom namespace end
}

