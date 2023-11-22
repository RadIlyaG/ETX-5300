#===============================================================
#
#  FileName:   RLTcp.tcl
#
#  Written by: Ohad / 8.4.1999 updated 8.2.2000	;update by semion 1.9.2002
#
#  Abstract: This file handle the SNMP, TFTP, TELNET procedures.  
#
#  Procedures:    -SnmpOpen      -TelnetOpen         -TftpOpen
#                 -SnmpFile      -Send               -TftpPutFile
#                 -SnmpGet       -Waitfor            -TftpGetFile
#                 -SnmpSet       -TelnetClose        -TftpClose
#									-SnmpMultiSet	                     -TftpBeHost
#                 -SnmpClose                         -TftpHostClose
#                 -SnmpGetNext                       
#					        -SnmpSetByStep
#									-Ping
#===============================================================

# Snmp Error Codes:

#The MIB File in Open function doesn't exist                        -200	
#There is not Free Location to Open New Session                     -201
#The Openning Process has been Fault                                -202
#Session With This ID has been Not Opened                           -203
#There is not Such Parameter in MIB File                            -204
#The Rewuest has been Fault                                         -205
#The INI File dosn't contain any Sections                           -206
#Allocation Memory has been Fault                                   -207
#File Command Request not Found                                     -208
#Could Not open MIB File                                            -209
#MIB File is Empty                                                  -210
#Enumerator for this Parameter doesn't Found in MIB File            -211
#The object's value cann't be read from "set" section of ini file   -212
#Time Out is Expired                                                -213


package require RLDTcp 4.0
package require RLTime

package require RLEH 1.0

package provide RLTcp 4.0
  
global gExcepHandleTcp
set gExcepHandleTcp continue
  
namespace eval RLTcp {  

  namespace export SnmpOpen SnmpFile SnmpGet SnmpSet SnmpMultiSet SnmpClose SnmpGetNext SnmpSetByStep	Ping
  namespace export TelnetOpen Send Waitfor TelnetClose 
  namespace export TftpOpen TftpPutFile TftpGetFile TftpClose TftpBeHost TftpHostClose

    
  ##################################################################
  ###                     SNMP - PROCEDURES                      ###
  ##################################################################
  
  
  #***************************************************************
  #** SnmpOpen
  #**
  #** Abstract: Open SNMP session.
  #**
  #** Inputs: 1. 'ip_mibFile' the relevant MIB file to load. Full PATH !!
  #**
  #** Outputs: return the ID of the SNMP session if O.K.
  #**          
  #** Usage:  RLTcp::SnmpOpen 'ip_mibFile' 
  #**                  
  #***************************************************************

  proc SnmpOpen { ip_mibFile } {

    global ERRMSG
    global gMessage
   	global gExcepHandleTcp
    set gMessage ""
				#added by semion
    if ![file exist $ip_mibFile] {
      set gMessage "The $ip_mibFile file doesn't exist"
      RLEH::Handle SAsystem gMessage
    }

				#added by semion
    set idFile [ open $ip_mibFile r ]
				set line [gets	$idFile]
				if ![string match "*Rad ATE Department*" $line] {
				  close $idFile
      set gMessage "The $ip_mibFile file is wrong"
      RLEH::Handle SAsystem gMessage
				} else {
  				  close $idFile
				}
    
    set snmpId  [ RLDLLOpenSNMP $ip_mibFile ]  
    if { $snmpId < 1 } {
      append gMessage "$ERRMSG\n\nCan't open SNMP session"
      RLEH::Handle SAsystem gMessage
    } 
    return $snmpId
  }
                            

  #*************************************************************** 
  #** SnmpFile
  #**
  #** Abstract: Send the specified file to the remote device.
  #**
  #** Inputs: 1. 'ip_snmpId'  the SNMP session ID. 
  #**         2. 'ip_ipAddress'  the remote device IP Address.
  #**         3. 'ip_file' the file (*.ini) to be send. Full PATH!!
  #**          
  #** Outputs: return '0' if O.K. , '-1' if command was not done.
  #**          or 'abort' if there is a memory problem (DLL problem)
  #**
  #** Usage: RLTcp::SnmpFile 'ip_snmpId' 'ip_ipAddress' 'ip_file'
  #**        
  #** Remarks: File format: [set]
  #**                       ObjectName=NewValue
  #**                       .
  #**                       .
  #**
  #**                       [get]
  #**                       ObjectName=
  #**                       .
  #**                       .
  #**
  #**                       [community]
  #**                       set= 'SNMP Write Community' (defualt = private)
  #**                       get= 'SNMP Read Community'  (defualt = public)
  #**
  #**
  #**          If the proc. successful the 'ip_file' contents new value for [get] 
  #**          section.
  #**
  #*************************************************************** 

  proc SnmpFile { ip_snmpId  ip_ipAddress  ip_file } {
 
    global ERRMSG
    global gMessage
   	global gExcepHandleTcp
    set gMessage ""
    
    # syntax
    
    set fileResult [ RLDLLFileRequestSNMP $ip_snmpId $ip_ipAddress $ip_file ]
    switch -exact -- $fileResult {
    
#        -207 {
#            append gMessage "$ERRMSG\n\nCan't send File  $ip_file  to device  $ip_ipAddress"
#            RLEH::Handle FatalSystem gMessage 
#        }
#    
#        -205 {
#            return -1
#        }
#        
        0 {
            return 0
        }     
    
        default {
            append gMessage "$ERRMSG\n\nCan't send File  $ip_file  to device  $ip_ipAddress"
												if {$gExcepHandleTcp == "abort"} {
              RLEH::Handle FatalSystem gMessage 
												}
            return $fileResult
        }
    
    }
  }   
    
  
  #*************************************************************** 
  #** SnmpGet
  #**
  #** Abstract: Read information from device.
  #**
  #** Inputs: 1. 'ip_snmpId'  the SNMP session ID. 
  #**         2. 'ip_ipAddress'  the remote device IP Address.
  #**         3. 'ip_commandName' the command name to be send to device.
  #**         4. 'ip_readCommu' the Read community name.( Defualt = public )
  #**          
  #** Outputs: return the value for the specific ip_commandName if O.K.
  #**          '-1' if command was not done, or 'abort' if there is 
  #**           a memory problem (DLL problem).
  #**
  #** Usage: RLTcp::SnmpGet 'ip_snmpId' 'ip_ipAddress' 'ip_commandName' 'ip_readCommu'
  #**        RLTcp::SnmpGet 'ip_snmpId' 'ip_ipAddress' 'ip_commandName' 
  #**
  #*************************************************************** 

  proc SnmpGet {ip_snmpId ip_ipAddress ip_commandName {ip_readCommu 1} } {

    global ERRMSG
    global gMessage
   	global gExcepHandleTcp
    set gMessage ""
    
    #syntax
    
    
    if { $ip_readCommu == 1 } {
      set ip_readCommu public
    }
  
    set getResult [RLDLLGetRequestSNMP $ip_snmpId $ip_ipAddress $ip_readCommu $ip_commandName getBuffer]
    switch -exact -- $getResult {
    
        0 {
            return $getBuffer
        }     
    
        default {
            append gMessage "$ERRMSG\n\nCan't get any value from device  $ip_ipAddress"
												if {$gExcepHandleTcp == "abort"} {
              RLEH::Handle FatalSystem gMessage 
												}
            return $getResult
        }
    
    }
  } 
    
    
  #*************************************************************** 
  #** SnmpGetNext
  #**
  #** Abstract: Read the next parameter (after a given parameter) value.
  #**
  #** Inputs: 1. 'ip_snmpId'  the SNMP session ID. 
  #**         2. 'ip_ipAddress'  the remote device IP Address.
  #**         3. 'ip_commandName' the parameter befor the desirable parameter.
  #**         4. 'ip_nextParameter' to store the next parameter attribute to the return value.
  #**         5. 'ip_readCommu' the Read community name.( Defualt = public )
  #**          
  #** Outputs: return the value for the next parameter and set the 'ip_nextParameter'
  #**          with the parameter name if O.K.
  #**          '-1' if command was not done, or 'abort' if there is 
  #**           a memory problem (DLL problem).
  #**
  #** Usage: RLTcp::SnmpGetNext 'ip_snmpId' 'ip_ipAddress' 'ip_commandName' 'ip_nextParameter' 'ip_readCommu'
  #**        RLTcp::SnmpGetNext 'ip_snmpId' 'ip_ipAddress' 'ip_commandName' 'ip_nextParameter'
  #**
  #*************************************************************** 

  proc SnmpGetNext {ip_snmpId ip_ipAddress ip_commandName ip_nextParameter {ip_readCommu 1} } {

    global ERRMSG
    global gMessage
   	global gExcepHandleTcp
    set gMessage ""
    upvar $ip_nextParameter getNextParameter
    #syntax
    
    set notDotCod 1
    if { $ip_readCommu == 1 } {
      set ip_readCommu public
    }
				#added by semion
				#check if command name is dot notation or string name
				if ![regexp {[^0-9.]+} $ip_commandName res] {
      set notDotCod 0
				}
  
    set getNextResult [RLDLLGetNextRequestSNMP $ip_snmpId $ip_ipAddress $ip_readCommu $ip_commandName getNextValue getNextParameter $notDotCod]
    switch -exact -- $getNextResult {
    
        
        0 {
           #set ip_nextParameter $getNextParameter
			        return $getNextValue
        }     
    
        default {
            append gMessage "$ERRMSG\n\nCan't get any value from device  $ip_ipAddress"
												if {$gExcepHandleTcp == "abort"} {
              RLEH::Handle FatalSystem gMessage 
												}
            return $getNextResult
        }
    
    }
  } 
   
  #*************************************************************** 
  #** SnmpSet
  #**
  #** Abstract: Write information to device.
  #**           If error, display an error message box.
  #**
  #** Inputs: 1. 'ip_snmpId'  the SNMP session ID. 
  #**         2. 'ip_ipAddress'  the remote device IP Address.
  #**         3. 'ip_commandName' the command name to be send to device.
  #**         4. 'ip_value' value of the specific command.
  #**         5. 'ip_writeCommu' the Write community name.( Defualt = private )
  #**          
  #** Outputs: return '0' if O.K. , '-1' if command was not done.
  #**          or 'abort' if there is a memory problem (DLL problem)
  #**
  #** Usage: RLTcp::SnmpSet 'ip_snmpId' 'ip_ipAddress' 'ip_commandName' 'ip_value' 'ip_writeCommu'
  #**        RLTcp::SnmpSet 'ip_snmpId' 'ip_ipAddress' 'ip_commandName' 'ip_value'
  #**
  #*************************************************************** 

  proc SnmpSet {ip_snmpId ip_ipAddress ip_commandName ip_value {ip_writeCommu 1} } {

    global ERRMSG
    global gMessage
   	global gExcepHandleTcp
    set gMessage ""
    set setResult ""
    
    #syntax
    
    if { $ip_writeCommu == 1 } {
      set ip_writeCommu private
    }
  
    set setResult [RLDLLSetRequestSNMP $ip_snmpId $ip_ipAddress $ip_writeCommu $ip_commandName $ip_value]
    switch -exact -- $setResult {
    
        0 {
            return 0
        }     
    
        default {
            append gMessage "$ERRMSG\n\nCan't set command '$ip_commandName' to device  $ip_ipAddress"
												if {$gExcepHandleTcp == "abort"} {
              RLEH::Handle FatalSystem gMessage 
												}
            return $setResult
        }
    
    }
  } 
  

  #*************************************************************** 
  #** SnmpMultiSet
  #**
  #** Abstract: Write information to device with Multiple object in PDU.
  #**           If error, display an error message box.
  #**
  #** Inputs: 1. 'ip_snmpId'  the SNMP session ID. 
  #**         2. 'ip_ipAddress'  the remote device IP Address.
  #**         3. 'ip_commandNameList' the command name to be send to device.
  #**         4. 'ip_valueList' value of the specific command.
  #**         5. 'ip_writeCommu' the Write community name.( Defualt = private )
  #**          
  #** Outputs: return '0' if O.K. , '-1' if command was not done.
  #**          or 'abort' if there is a memory problem (DLL problem)
  #**
  #** Usage: RLTcp::SnmpSet 'ip_snmpId' 'ip_ipAddress' 'ip_commandNameList' 'ip_valueList' 'ip_writeCommu'
  #**        RLTcp::SnmpSet 'ip_snmpId' 'ip_ipAddress' 'ip_commandNameList' 'ip_valueList'
  #**
  #*************************************************************** 

  proc SnmpMultiSet {ip_snmpId ip_ipAddress ip_commandNameList ip_valueList {ip_writeCommu 1} } {

    global ERRMSG
    global gMessage
   	global gExcepHandleTcp
    set gMessage ""
    set setResult ""
    
    #syntax
    
    if { $ip_writeCommu == 1 } {
      set ip_writeCommu private
    }

  		if {[set numbObj [llength $ip_commandNameList]] != [llength $ip_valueList]} {
      set gMessage "ERROR MultiSet : The number of OBJECTS and number values into value list MUST be same"
      RLEH::Handle FatalSystem gMessage 
				}

    set setResult [RLDLLSetMultiRequestSNMP $ip_snmpId  $ip_ipAddress $ip_writeCommu \
				                                        $ip_commandNameList $ip_valueList $numbObj]
    switch -exact -- $setResult {
    
        0 {
            return 0
        }     
    
        default {
            append gMessage "$ERRMSG\n\nCan't MultiSet command '$ip_commandNameList' to device  $ip_ipAddress"
												if {$gExcepHandleTcp == "abort"} {
              RLEH::Handle FatalSystem gMessage 
												}
            return $setResult
        }
    
    }
  } 
  

#*************************************************************** 
#** SnmpSetByStep
#**
#** Abstract: Write information to device step by step from ini file.
#**           If error, display an error message box.
#**
#** Inputs: 1. ip_snmpId           the SNMP session ID.
#**			  2. ip_file	          the ini file path.
#**         3. ip_ipAddress        the remote device IP Address.
#**         4. ip_delay            the delay in ms between commands 
#**         
#**          
#** Outputs: return '0' if O.K. 
#**			   exception EH message if error
#**          or 'abort' if there is a memory problem (DLL problem)
#**
#** Usage: RLTcp::SnmpSetByStep ip_snmpId ip_file ip_ipAddress ip_delay
#**
#*************************************************************** 

#New procedure added by Shay and Semion
proc SnmpSetByStep {ip_snmpId ip_file ip_ipAddress {ip_delay 0}} {
  global ERRMSG
  global gMessage
 	global gExcepHandleTcp
  set gMessage ""
		set res      0
	 if {[set validIp [ProcCheckValidIp $ip_ipAddress]] == -1} {
   	set gMessage "The IP address doesn't valid"
 	  RLEH::Handle SAsystem gMessage
  }
  if { [ file exist $ip_file]!=1 } {
    set gMessage "The Ini file $ip_file doesn't found"
    RLEH::Handle SAsystem gMessage
  }
  if {[RLFile::Inigetitem $ip_file community set communName errorVal]!=0} {
	   set gMessage " The 'set' item in  community section doesn't found"
    RLEH::Handle SAsystem gMessage
  }
  set communName [lindex $communName 0]
	 set fileId [open $ip_file r ]
		update
  while {[eof $fileId] != 1} {
    set line [gets $fileId]
    if	{[ llength $line ]>1} {
  	   set variable [ lindex $line 0 ]
	     set value [ lrange $line 2 end ]
			   RLTime::CviDelayms $ip_delay
			   #RLTime::Delayms $ip_delay
						if {[set res [RLTcp::SnmpSet $ip_snmpId $validIp "$variable" "$value" $communName]]} {
  	    	break
						}
		  }	elseif {[ string first "\[community\]" $line ] != -1} {
  	    	break
				}
	 }
  close $fileId
  return $res
} 
  

  #***************************************************************
  #** Ping
  #**
  #** Abstract: Ping to device that his addres marked.
  #**
  #** Inputs: 1. 'ip_addr' the addres of the device.
  #**
  #** Outputs: return '0' if O.K. , 'abort' if the device do not reply.
  #**          
  #** Usage:  RLSnmp::Ping 'ip_addr' 
  #**        
  #**         
  #***************************************************************

 proc Ping {time_out ip_addr } {

    global ERRMSG
    global gMessage
   	global gExcepHandleTcp
    set gMessage ""

  	 if {[set validIp [ProcCheckValidIp $ip_addr]] == -1} {
     	set gMessage "The IP address doesn't valid"
 	    RLEH::Handle SAsystem gMessage
    }
    
   	set ping1 [exec  ping -w $time_out -a $validIp]
	   set indx [string match *Reply* $ping1]
	   if { $indx == 0 } {
	     append gMessage "$ERRMSG\n\nThe device at $ip_addr is not Reply" 
						if {$gExcepHandleTcp == "abort"} {
        RLEH::Handle FatalSystem gMessage 
						}
      return -1 		     
    } 
    return 0
 }

     
  #***************************************************************
  #** SnmpClose
  #**
  #** Abstract: Close SNMP session.
  #**
  #** Inputs: 1. 'ip_snmpId' the snmp session ID.
  #**
  #** Outputs: return '0' if O.K. 
  #**          
  #** Usage:  RLTcp::SnmpClose 'ip_snmpId'
  #**
  #***************************************************************

  proc SnmpClose {ip_snmpId} {
    
    global ERRMSG
    global gMessage
   	global gExcepHandleTcp
    set gMessage ""
    
    if { [set res [RLDLLCloseSNMP $ip_snmpId]] != 0 } {
      append gMessage "$ERRMSG\n\nCan't close SNMP session for ID:$ip_snmpId"
						if {$gExcepHandleTcp == "abort"} {
         RLEH::Handle FatalSystem gMessage 
						}
						return	$res
    } else {
        return 0
      }  
  }
  
  
  ##################################################################
  ###                     TELNET - PROCEDURES                    ###
  ##################################################################

     
  #***************************************************************
  #** TelnetOpen
  #**
  #** Abstract: Open TELNET session.
  #**           
  #** Inputs: 1. 'ip_ipAddr' IP Address for TELNET session in the FORMAT: xxx.xxx.xxx.xxx
  #**
  #** Outputs: return telnetId if O.K.
  #**
  #** Usage:  RLTcp::TelnetOpen xxx.xxx.xxx.xxx
  #**
  #***************************************************************

  proc TelnetOpen {ip_ipAddr} {

    global ERRMSG
    global gMessage
   	global gExcepHandleTcp
    set gMessage ""
    
    #syntax
    
    set telnetId  [ RLDLLOpenTelnet $ip_ipAddr ]  
    if { $telnetId <= 0 } {
      append gMessage "$ERRMSG\n\nCan't open TELNET session for IP:$ip_ipAddr"
						if {$gExcepHandleTcp == "abort"} {
         RLEH::Handle FatalSystem gMessage 
						}
    } 
    return $telnetId       
  }


  #*************************************************************** 
  #** Send
  #**
  #** Abstract: Send the specified string to device.
  #**
  #** Inputs: 1. 'ip_telnetId' the TELNET ID of the device.
  #**         2. 'ip_string'  the string to be send. 
  #**         
  #** Outputs: return '0' if O.K. , '-1' if Send was not performed.
  #**
  #** Usage: RLTcp::Send 'ip_telnetId' 'ip_string'
  #**       
  #*************************************************************** 

  proc Send { ip_telnetId  ip_string } {
 
    global ERRMSG
    global gMessage  
   	global gExcepHandleTcp
    set gMessage ""
    
    #syntax
    
    set sendResult [ RLDLLSendTelnet $ip_telnetId $ip_string ]
    if { $sendResult != 0 } {
      append gMessage "$ERRMSG\n\nIn TelnetSend procedure"
						if {$gExcepHandleTcp == "abort"} {
         RLEH::Handle FatalSystem gMessage 
						}
    }
				return $sendResult
  }


  #*************************************************************** 
  #** Waitfor
  #**
  #** Abstract: Waits for the specified string for no more 
  #**           then the ip_timeOut value.
  #**
  #** Inputs: 1. 'ip_telnetId' the remote device ID.
  #**         2. 'ip_string' the string to wait for. 
  #**         3. 'ip_buffer' name of buffer to save the data in.(defualt='telnetBuffer')
  #**         4. 'nip_timeOut' time to wait in sec.(defualt=10)  
  #**         
  #**
  #** Outputs: return '0' if found 'ip_string' , '-1' if not found.
  #**
  #** Usage: RLTcp::Waitfor 'ip_telnetId' 'string' 'ip_buffer' 'nip_timeOut' 
  #**        RLTcp::Waitfor 'ip_telnetId' 'string'
  #**        
  #**
  #** Remarks: TelnetWaitfor searche the data that was enterd since the
  #**          last TelnetSend.
  #**
  #**          IMPORTANT!! When there is a need to work with the buffer
  #**                      inside a procedure you must note inside the
  #**                      procedure the name of buffer as a global variable.
  #**                      If you chose to work with the defualt buffer name
  #**                      then note 'global telnetBuffer'. 
  #**
  #*************************************************************** 

  proc Waitfor { ip_telnetId  ip_string {ip_buffer telnetBuffer} {nip_timeOut 10} } {
  
    global ERRMSG
    global gMessage
   	global gExcepHandleTcp
    global $ip_buffer
    set gMessage ""
    set $ip_buffer ""    
    
    #syntax
    
    for {set stringFound 0} {($nip_timeOut >= 0) && ($stringFound != 1)} {incr nip_timeOut -1 } {
      if {[ RLDLLReadTelnet  $ip_telnetId  $ip_buffer ] != 0} {
        append gMessage "$ERRMSG\n\nIn TelnetWaitfor procedure"
  						if {$gExcepHandleTcp == "abort"} {
           RLEH::Handle FatalSystem gMessage 
				  		}
      }
      
      set stringMatch [ string first $ip_string [set $ip_buffer] ]
      if { $stringMatch != -1 } {
        set stringFound 1
      }
      if {!$stringFound} {
        set wait 0
        after 1000 { set wait 1 }
        vwait wait
      }
    }
    
    if { $stringFound == 1 } {
      return 0
    } else {
        return -1
      }
  }

  
  #***************************************************************
  #** TelnetClose
  #**
  #** Abstract: Close TELNET session.
  #**           
  #** Inputs: 1. 'ip_telnetId' the remote device ID to be closed.
  #**
  #** Outputs: return '0' if O.K.
  #**
  #** Usage:  RLTcp::TelnetClose 'ip_telnetId'
  #**
  #***************************************************************

  proc TelnetClose {ip_telnetId} {

    global ERRMSG
    global gMessage
   	global gExcepHandleTcp
    set gMessage ""
    
    #syntax
    
    if {[set res [ RLDLLCloseTelnet $ip_telnetId ]] != 0 } {
      append gMessage "$ERRMSG\n\nCan't close TELNET session $ip_telnetId"
						if {$gExcepHandleTcp == "abort"} {
         RLEH::Handle FatalSystem gMessage 
						}
				}
    return $res
  }

   
  ##################################################################
  ###                     TFTP - PROCEDURES                      ###
  ##################################################################

  #***************************************************************
  #** TftpOpen
  #**
  #** Abstract: Open TFTP session.
  #**
  #** Inputs: 
  #**
  #** Outputs: return tftpId if O.K.
  #**          
  #** Usage:  RLTcp::TftpOpen
  #**
  #***************************************************************
   
  proc TftpOpen {} {

    global ERRMSG
    global gMessage
    set gMessage ""
    
    set tftpId  [ RLDLLOpenTFTP ]
    if { $tftpId <= 0 } { 
      append gMessage "$ERRMSG\n\nCan't open TFTP session "
      RLEH::Handle SAsystem gMessage
    } 
    return $tftpId
  }
                            

  #***************************************************************
  #** TftpPutFile
  #**
  #** Abstract: Send file to remote device.
  #**
  #** Inputs: 1. 'ip_tftpId'TFTP session ID.
  #**         2. 'ip_ipAdrr' Remote device ip address. FORMAT: xxx.xxx.xxx.xxx
  #**         3. 'ip_locFile' File to be send to device.
  #**         4. 'ip_remFile' File to recive from device.
  #**         5. 'ip_asciBin' '1' for ascii, '0' for binary.(defualt=0)
  #**
  #** Outputs: return '0' if O.K.
  #**          
  #** Usage:  RLTcp::TftpPutFile 'ip_tftpId' 'ip_ipAddr' 'ip_locFile' 'ip_remFile' 'ip_AsciBin'
  #**         RLTcp::TftpPutFile 'ip_tftpId' 'ip_ipAddr' 'ip_locFile' 'ip_remFile'
  #**
  #** Remarks: Remote/Local file names should have FULL PATH !
  #**
  #***************************************************************
   
  proc TftpPutFile {ip_tftpId  ip_ipAddr  ip_locFile  ip_remFile  {ip_AsciBin 0} } {

    global ERRMSG
    global gMessage
    set gMessage ""
    
    #syntax
    
    if { [RLDLLPutFileTFTP $ip_tftpId $ip_ipAddr $ip_locFile $ip_remFile $ip_AsciBin] != 0 } {
      append gMessage "$ERRMSG\n\nCan't send file to device $ip_ipAddr  (TFTP)"
      RLEH::Handle SAsystem gMessage
    } else {
        return 0
      }  
  }
  

  #***************************************************************
  #** TftpGetFile
  #**
  #** Abstract: Recive file from remote device.
  #**
  #** Inputs: 1. 'ip_tftpId'TFTP session ID.
  #**         2. 'ip_ipAdrr' Remote device ip address. FORMAT: xxx.xxx.xxx.xxx
  #**         3. 'ip_locFile' FileName to be save as.
  #**         4. 'ip_remFile' File to recive from device.
  #**         5. 'ip_asciBin' '1' for ascii, '0' for binary.(defualt=0)
  #**
  #** Outputs: return '0' if O.K.
  #**          
  #** Usage:  RLTcp::TftpGetFile 'ip_tftpId' 'ip_ipAddr' 'ip_locFile' 'ip_remFile' 'ip_AsciBin'
  #**         RLTcp::TftpGetFile 'ip_tftpId' 'ip_ipAddr' 'ip_locFile' 'ip_remFile'
  #**
  #** Remarks: Remote/Local file names should have FULL PATH !
  #**
  #***************************************************************
   
  proc TftpGetFile {ip_tftpId  ip_ipAddr  ip_locFile  ip_remFile  {ip_AsciBin 0} } {

    global ERRMSG
    global gMessage
    set gMessage ""
    
    if { [RLDLLGetFileTFTP $ip_tftpId $ip_ipAddr $ip_locFile $ip_remFile $ip_AsciBin] != 0 } {
      append gMessage "$ERRMSG\n\nCan't get file from device $ip_ipAddr  (TFTP)"
      RLEH::Handle SAsystem gMessage
    } else {
        return 0
      }  
  }

 
  #***************************************************************
  #** TftpClose
  #**
  #** Abstract: Close TFTP session.
  #**           
  #** Inputs: 'ip_tftpId' the TFTP session ID to be closed.
  #**
  #** Outputs: return '0' if O.K.
  #**
  #** Usage:  RLTcp::TftpClose 'ip_tftpId'
  #**
  #***************************************************************

  proc TftpClose {ip_tftpId} {

    global ERRMSG
    global gMessage
    set gMessage ""
    
    if { [ RLDLLCloseSessionTFTP $ip_tftpId ] != 0 } {
      append gMessage "$ERRMSG\n\nCan't close TFTP session $ip_tftpId"
      RLEH::Handle SAsystem gMessage
    } else {
        return 0
      }  
  }
  
  #***************************************************************
  #** TftpBeHost
  #**
  #** Abstract: open session and set it to work as HOST.
  #**
  #** Inputs: 'ip_userProc' name of procedure that the user provide
  #**                       that will be up to date with the status of test.
  #**
  #** Outputs: return session ID if O.K. or error code (see remark).
  #**          
  #** Usage:  RLTcp::TftpBeHost "userProc Name"
  #**
  #***************************************************************
   
  proc TftpBeHost {ip_userProc} {

    global gMessage
    global gOpenFlag
	 global gUserProc
	 global gPresentCode
	 global gTftpHostId

	 set gMessage ""
	 set gOpenFlag 0
    set gPresentCode 0
	 
	 set sessionId  [ RLDLLBeHostTFTP StatusProc]
    
	 if {$sessionId == -109} {
	   return
	 } else {
	     for {set i 1} {($gOpenFlag == 0) && ($i < 50)} {incr i} {
		    set x 0
			 after 100 {set x 1}
			 vwait x
		  }
		  if {$i >= 50} {
		    set gMessage "\nTimed out while waiting for session to open."
			 RLEH::Handle SAsystem gMessage
	     } else {
		      set gUserProc $ip_userProc
		      set gTftpHostId $sessionId
				return $sessionId
			 }
		}
  }
  
  
  #***************************************************************
  #** TftpHostClose
  #**
  #** Abstract: Closing a host session.
  #**
  #** Inputs: 'ip_sessionId' ID of the session that will be closed.
  #**
  #** Outputs: return '0' if O.K. or EH is activated if error.
  #**          
  #** Usage:  RLTcp::TftpHostClose $ID
  #**
  #***************************************************************
   
  proc TftpHostClose {ip_sessionId} {

    global gMessage
    set gMessage ""
	 set gCloseFlag 0  

	 set closeResult  [ RLDLLCloseHostTFTP $ip_sessionId]
    
	 switch -exact -- $closeResult {

	    -110 {
             set gMessage "\nTrying to close an unopened session !"
			    RLEH::Handle SAsystem gMessage
	         }

 		 0    { return 0 }
				
    }
  }
# end of namespace
}

proc StatusProc {ip_code} {

  global gOpenFlag
  global gCloseFlag
  global gUserProc
  global gMessage
  global gPresentCode
  global gTftpHostId

  set gMessage ""

  
  #puts "Code = $ip_code"
  
  if {($ip_code == 15) || (($ip_code >= 17) && ($ip_code <= 21)) } {
    
	 RLDLLCloseHostTFTP $gTftpHostId
	 set gMessage "General Error occurred."
	 RLEH::Handle SAsystem gMessage
 }
  switch -exact -- $ip_code {

	  
     -111 { set gOpenFlag 1
            puts "seting gOpenFlag to '1' (-111)"}    
	  -112 { eval "$gUserProc STARTTFTP" }
	  -113 { eval "$gUserProc ENDTFTP" }
	  #-114 { set gCloseFlag 1 
	  #       puts "seting gCloseFlag to '1' (-114)"}
	  16   { eval "$gUserProc NOFILETFTP" }
	  
  }
}



  #***************************************************************
  #** ProcCheckValidIp
  #***************************************************************

		proc ProcCheckValidIp {ip_ipAddress} {
				global	gMessage
		  set fail -1

    set lIp	[split $ip_ipAddress	.]
	   if {[llength $lIp] != 4} {
 	    set gMessage "The IP address doesn't valid"
 	    return $fail
    }
    foreach dev	$lIp {
						if {[set len [string length $dev]] > 3} {
 	      set gMessage "The IP address doesn't valid"
 	      return $fail
      } elseif {$dev == 0} {
          set ndev	0
						} else {
          set ndev	[string trimleft $dev 0]
						}
      if {[catch "expr int($ndev)" res] || $ndev > 255} {
  	     set gMessage "The IP address doesn't valid"
   	    return $fail
      } else {
	         append newIp " $ndev"
      }											
    }
    set newIp [join $newIp .]
				return $newIp
		}
