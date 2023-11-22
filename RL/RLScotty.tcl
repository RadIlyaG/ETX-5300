#===============================================================
#
#  FileName:   RLScotty.tcl
#
#  Written by: Semion 01.4.04 , updated 23.05.10
#
#  Abstract: This file handle the SNMP procedures by scotty package.  
#
#  Procedures: 
#                 -SnmpOpen     
#								  -SnmpConfig
#                 -SnmpSet   
#                 -SnmpGet  
#                 -SnmpGetNext                       
#                 -SnmpClose  
#                 -SnmpCloseAll  
#                 -SnmpOpenTrap     
#								  -SnmpConfigTrap
#                 -SnmpCloseTrap  
#                 -SnmpCloseAllTrap
#                 -SnmpMibs  
#                 -SnmpWalk  
#									-Ping
#===============================================================


###############################################################################################
##
## This procedure is called whenever an SNMP trap is received.
##
###############################################################################################
proc Traphandler {op_trapMsg ip pdu args} {
    global        gMessage $op_trapMsg
    variable      vaAppStatuses 
  
	  #puts $op_trapMsg
		set msgTime [clock format [clock seconds] -format "%Y.%m.%d %H.%M.%S"]
		append $op_trapMsg "=============================================================\n"
		append $op_trapMsg "$msgTime\n"
    append $op_trapMsg "$pdu from $ip:\n"
    foreach vb $args {
    	append $op_trapMsg "\n [Tnm::mib name [lindex $vb 0]]=\"[lindex $vb 2]\""
    }
		append $op_trapMsg "\n=============================================================\n\n"
}

package require Tnm 3.0
package require TnmSnmp     3.0 
package require TnmMap    	3.0
package require TnmMib    	3.0
package require TnmDialog 	3.0
package require TnmTerm   	3.0
package require TnmInet	  	3.0
package require RLEH  
#package require RLTime
package provide RLScotty  1.2


#namespace import Tnm::dns
#namespace import Tnm::icmp
#namespace import Tnm::ined
#namespace import Tnm::job
#namespace import Tnm::map
#namespace import Tnm::mib
#namespace import Tnm::netdb
#namespace import Tnm::ntp
#namespace import Tnm::smx
#namespace import Tnm::snmp 
#namespace import Tnm::sunrpc
#namespace import Tnm::syslog
#namespace import Tnm::udp

source c:\\rlfiles\\scotty\\mibs\\miblist.tcl
#RLEH::Open
foreach file $lMibFiles {
 #update
 #puts "\n [RLTime::TimeDate]"
 if {[catch {Tnm::mib load $file} msg]} { 
   	set gMessage "Loading MIBs : $msg"
 	  RLEH::Handle SAsystem gMessage
 }
}

  
namespace eval RLScotty {  

  namespace export SnmpOpen SnmpConfig SnmpGet SnmpSet SnmpClose SnmpCloseAll SnmpGetNext Ping
  namespace export SnmpOpenTrap SnmpConfigTrap SnmpCloseTrap SnmpCloseAllTrap SnmpMibs SnmpWalk
	variable vaAppStatuses
    
  ##################################################################
  ###                     SNMP - PROCEDURES                      ###
  ##################################################################
  
  
#.......................................................................
#                        ***** SnmpOpen *****
#   Abstract :
#     Open Snmp session and make community public
#   Arguments :
#     ip_ipAdd -  ip address (like 192.168.243.90)
#   Retval :
#     session ID - 1-32.
#     Error code     - otherwise
#   Example:
#     RLScotty::SnmpOpen 192.168.243.90
#     This example opens snmp session with ip add 192.168.243.90 .
#     Befor you execute this function you have to set the agent this ip address 
#......................................................................
proc SnmpOpen {ip_ipAdd} {
	global	 gMessage RLScotty
  variable vaAppStatuses

  if {[set validIp [ProcCheckValidIp $ip_ipAdd]] == -1} {
   	set gMessage "The IP address doesn't valid"
 	  RLEH::Handle SAsystem gMessage
  }

	#check that there aren't maximum(32) opened sessions.
	for {set i 1} {$i <33} {incr i} {
		if {![info exists vaAppStatuses($i,sessionID)]} {
		  break
		}
	}
	if {$i >32} {
		set	gMessage "Open procedure: It is impossible to open more than 32 scotty applications with one TCL wish process"
    return [RLEH::Handle SAsyntax gMessage]
	}
	set appIndex $i
  #create session
	if {[catch {Tnm::snmp  generator -address $validIp} res]} {
		set	gMessage "Open procedure failed: $res"
    return -1
	} else {
      set vaAppStatuses($appIndex,sessionID) $res
			set RLScotty($appIndex) $res
	}
  if {[catch {$vaAppStatuses($appIndex,sessionID) configure -community public -timeout 5 -retries 1} res]} {
		set	gMessage "Open procedure failed: $res"
  	return -1
	} else {
	    set gMessage ""
	    return $appIndex
	}
}


#**********************************************************************
#                        ***** SnmpConfig *****
#   Abstract :
#     configures snmp session
#   Arguments :
#		  ip_sessionID - session ID returned by Open procedure.
#     args parameters:
#
#							 -address
#							 -port
#							 -version
#							 -community
#							 -user
#							 -context
#							 -engineID
#							 -authKey
#							 -privKey
#							 -authPassWord
#							 -privPassWord
#							 -security
#							 -alias
#							 -transport
#							 -timeout
#							 -retries
#							 -window
#							 -delay
#							 -tag
#   Retval :	 0                             if ok
#							 current configuration				 if args = 0
#              error cod                     otherwise.
#   Example:
#    RLScotty::SnmpConfig 1 -community public -timeout 5 -port 161
#    set listConfig [RLScotty::SnmpConfig 1] 
#......................................................................

proc SnmpConfig {ip_sessionID args} {
	global	gMessage RLScotty
  variable vaAppStatuses
  set ok     0
  set fail  -1
	#check that sesionn ID from command line stored in vaAppStatuses array variable of this name space.
	if {$ip_sessionID >0 && $ip_sessionID < 33} {
  	if {![info exists vaAppStatuses($ip_sessionID,sessionID)]} {
  		set	gMessage "SnmpConfig procedure: The session with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
		}
	} else {
  		set	gMessage "SnmpConfig procedure: The session with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
	}
	if {![llength $args]} {
	  return [$vaAppStatuses($ip_sessionID,sessionID) configure]
	}
  if {[catch {eval "$vaAppStatuses($ip_sessionID,sessionID) configure $args"} msg]} {
    set	gMessage "SnmpConfig procedure Failed: $msg"
    return $fail
  } else {
     set gMessage ""
     return $ok
  }
}


#**********************************************************************
#                        ***** SnmpSet *****
#   Abstract :
#     set parameter to snmp session
#   Arguments :
#		  ip_sessionID - session ID returned by Open procedure.
#     ip_lVarbind  - varbind list of mibs and values
#   Retval :	 0                if ok
#              error cod        otherwise.
#   Example:
#    RLScotty::SnmpSet 1 "agnSDateCmd.0 1999/11/23"
#    RLScotty::SnmpSet 2 "agnSTimeCmd.0 10:07:00"
#    RLScotty::SnmpSet 1 "modmPrtDteRate.11011 r128Kbps prtMlTiming.255.301 dce"
#......................................................................

proc SnmpSet {ip_sessionID ip_lVarbind} {
	global	gMessage RLScotty
  variable vaAppStatuses
  set ok     0
  set fail  -1
	#check that sesionn ID from command line stored in vaAppStatuses array variable of this name space.
	if {$ip_sessionID >0 && $ip_sessionID < 33} {
  	if {![info exists vaAppStatuses($ip_sessionID,sessionID)]} {
  		set	gMessage "SnmpSet procedure: The session with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
		}
	} else {
  		set	gMessage "SnmpSet procedure: The session with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
	}
	#prepare varbind list for scotty procedure.
	foreach {mib val} $ip_lVarbind {
		lappend	lVarbind  [list $mib $val]
	}
  if {[catch {$vaAppStatuses($ip_sessionID,sessionID) set $lVarbind} msg]} {
    set	gMessage "SnmpSet procedure Failed: $msg"
    return $fail
  } else {
	   set gMessage ""
     return $ok
  }
}

#**********************************************************************
#                        ***** SnmpGet *****
#   Abstract :
#     get parameter from snmp session
#   Arguments :
#		  ip_sessionID - session ID returned by Open procedure.
#     ip_lVarbind  - varbind list of mibs. 
#   Retval :
#     mib list values.
#     error cod                     otherwise.
#
#   Example:
#    RLScotty::SnmpGet 1 sysObjectID.0
#    RLScotty::SnmpGet 1 "agnSDateCmd.0 modmPrtDteRate.11011"
#.....................................................................

proc SnmpGet {ip_sessionID ip_lVarbind} {
	global	gMessage RLScotty
  variable vaAppStatuses
  set ok     0
  set fail  -1
	#check that application ID from command line stored in vaAppStatuses array variable of this name space.
	if {$ip_sessionID >0 && $ip_sessionID < 33} {
  	if {![info exists vaAppStatuses($ip_sessionID,sessionID)]} {
  		set	gMessage "SnmpGet procedure: The session with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
		}
	} else {
  		set	gMessage "SnmpGet procedure: The session with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
	}
  if {[catch {$vaAppStatuses($ip_sessionID,sessionID) get $ip_lVarbind} allmsg]} {
    set	gMessage "SnmpGet procedure Failed: $allmsg"
    return $fail
  } else {
	    #puts "msglen: [llength $allmsg]"
	    #puts $allmsg
	    set len [llength $allmsg]
			for {set i 0} {$i < $len} {incr i} {
   	    #obtain the  i mib  message from all message.
				set msg($i) [lindex $allmsg $i]
				#handle i mib message.
 	      #Get the 3rd token 
  	    set msg($i) [lindex $msg($i) 2]
 	      #If there is a prefix like: RAD4050-MIB!..., delete it
	      if {[string first ! $msg($i)]>0} {
  	      set msg($i) [list [split $msg($i) !]]
 	        set msg($i) [lindex $msg($i) 0]
 	        set msg($i) [lindex $msg($i) 1]
   	    }
				lappend retmsg $msg($i)
			}
	    set gMessage ""
      return $retmsg
  }
}

#**********************************************************************
#                        ***** SnmpGetNext *****
#   Abstract :
#     get next parameter from snmp session
#   Arguments :
#		  ip_sessionID - session ID returned by Open procedure.
#     ip_lVarbind  - varbind list of mibs. 
#   Retval :
#     next parameter that referring to ip_lVarbind.
#     error cod                        otherwise.
#
#   Example:
#    RLScotty::SnmpGetNext sysObjectID.0
#    RLScotty::SnmpGetNext agnSDateCmd.0 modmPrtDteRate.11011
#.....................................................................

proc SnmpGetNext {ip_sessionID ip_lVarbind} {
	global	gMessage RLScotty
  variable vaAppStatuses
  set ok     0
  set fail  -1
	#check that application ID from command line stored in vaAppStatuses array variable of this name space.
	if {$ip_sessionID >0 && $ip_sessionID < 33} {
  	if {![info exists vaAppStatuses($ip_sessionID,sessionID)]} {
  		set	gMessage "SnmpGetNext procedure: The session with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
		}
	} else {
  		set	gMessage "SnmpGetNext procedure: The session with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
	}
  if {[catch {$vaAppStatuses($ip_sessionID,sessionID) getnext $ip_lVarbind} msg]} {
    set	gMessage "SnmpGetNext procedure Failed: $msg"
    return $fail
  } else {
	    set gMessage ""
      return $msg
  }
}

#**********************************************************************
#                        ***** SnmpWalk *****
#   Abstract :
#    	retrieves a MIB subtree from a SNMP agent and shows the
#     instance names with their values.
#   Arguments :
#		  ip_sessionID - session ID returned by Open procedure.
#     ip_subtree  - The object identifier used to identify the MIB subtree.. 
#   Retval :
#     instance names with their values  in a multi-line text.
#     error cod                                    otherwise.
#
#   Example:
#    RLScotty::SnmpWalk sysObjectID
#    RLScotty::SnmpWalk prtT1E1LineMode
#.....................................................................
proc SnmpWalk {ip_sessionID ip_subtree} {
	global	gMessage RLScotty
  variable vaAppStatuses
  set ok     0
  set fail  -1

	#check that application ID from command line stored in vaAppStatuses array variable of this name space.
	if {$ip_sessionID >0 && $ip_sessionID < 33} {
  	if {![info exists vaAppStatuses($ip_sessionID,sessionID)]} {
  		set	gMessage "SnmpWalk procedure: The session with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
		}
	} else {
  		set	gMessage "SnmpWalk procedure: The session with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
	}

  set ip [$vaAppStatuses($ip_sessionID,sessionID) cget -address]
  set port [$vaAppStatuses($ip_sessionID,sessionID) cget -port]
  set txt "\[$ip:$port\] \[[clock format [clock seconds]]\]:\n"

  set maxl 0
  if {[catch {
	    set n 0
	    $vaAppStatuses($ip_sessionID,sessionID) walk vbl $ip_subtree {
	      foreach vb $vbl {

			    set oidname [Tnm::mib name [lindex $vb 0]]
			    set status [catch {Tnm::mib unpack $oid} xxx]
			    if {$status == 0} {
			      foreach v $xxx {
				      append oidname ".$v"
			      }
					}
		      set name($n) $oidname
		      set value($n) [lindex $vb 2]
		      if {$maxl < [string length $name($n)]} {
		        set maxl [string length $name($n)]
		      }
		      incr n
	      }
	    }
    } msg]} {
	    puts stderr $msg
			return $fail
  }

  for {set i 0} {$i < $n} {incr i} {
	  append txt [format "  %-*s : %s\n" $maxl $name($i) $value($i)]
  }

  return $txt
}
#***************************************************************************
#**                        RLScotty::SnmpClose
#** 
#** Absrtact:
#**   Close the specific scotty snmp session . 
#**
#**   Inputs:  ip_sessionID                :	  session ID returned by Open procedure 
#**                              
#**   Outputs: 
#**            0                       :        if success . 
#**            error message by RLEH 	 :				Otherwise.
#**                              
#** Example:                        
#**	  RLScotty::SnmpClose 1 
#***************************************************************************

proc SnmpClose {ip_sessionID} {
  global        gMessage RLScotty
  variable      vaAppStatuses 

	set false          0
	set true           1

	#check that application ID from command line stored in vaAppStatuses array variable of this name space.
	if {$ip_sessionID >0 && $ip_sessionID < 33} {
  	if {![info exists vaAppStatuses($ip_sessionID,sessionID)]} {
  		set	gMessage "SnmpClose procedure: The session with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
		}
	} else {
  		set	gMessage "SnmpClose procedure: The session with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
	}
	if {[catch {$vaAppStatuses($ip_sessionID,sessionID) destroy} res]} {
  	#unset	 vaAppStatuses($ip_sessionID,sessionID)
  	set	gMessage "SnmpClose procedure failed: $res"
		return -1
	} else {
    	unset	 vaAppStatuses($ip_sessionID,sessionID)
			unset RLScotty($ip_sessionID)
	    set gMessage ""
	    return 0
	}
}

#***************************************************************************
#**                        RLScotty::SnmpCloseAll
#** 
#** Absrtact:
#**   Close all oppened snmp sessions . 
#**
#**                              
#**   Outputs: 
#**            0                       :        if success . 
#**            error message by RLEH 	 :				Otherwise.
#**                              
#** Example:                        
#**	  RLScotty::SnmpCloseAll 
#***************************************************************************

proc SnmpCloseAll {} {
  global        gMessage RLScotty
  variable      vaAppStatuses 

	#check opened sessions.
	for {set i 1} {$i <33} {incr i} {
		if {[info exists vaAppStatuses($i,sessionID)]} {
		  if {[SnmpClose $i]} {
    		set	gMessage "SnmpCloseAll procedure failed: $gMessage"
				return -1
			}
		}
	}
	return 0
}

#.......................................................................
#                        ***** SnmpOpenTrap *****
#   Abstract :
#     Open Snmp listener session for listening traps from agents
#   Arguments :
#	  Inputs :
# 		op_trapMsg  variable name by which will be returned trap message
#   Retval :
#     session ID - 1-32.
#     Error code     - otherwise
#   Example:
#     RLScotty::OpenSnmpTrap 
#
#    SCOTTY's BUGS "
#
#    -  The Tcl arithmetic is not platform independent and does
#       not support unsigned numbers. It is therefore complicated
#       to write portable scripts that work correctly with large
#       SNMP numbers.
#
#    -  It is not possible to receive SNMP traps by more than one
#       application on the Windows platform.
#
#    -  The SNMPv3   implementation  currently  only  supports
#       noAuth/noPriv communication.
#......................................................................
proc SnmpOpenTrap {op_trapMsg} {
	global	 gMessage $op_trapMsg RLScotty
  variable vaAppStatuses

	set $op_trapMsg "Trap messages: \n\n"
	#check that there aren't maximum(32) opened trap sessions.
	for {set i 1} {$i <33} {incr i} {
		if {![info exists vaAppStatuses($i,trapsessionID)]} {
		  break
		}
	}
	if {$i >32} {
		set	gMessage "OpenTrap procedure: It is impossible to open more than 32 trap scotty sessions with one TCL wish process"
    return [RLEH::Handle SAsyntax gMessage]
	}
	set appIndex $i
  #create session
	if {[catch {Tnm::snmp  listener -version SNMPv1} res]} {
		set	gMessage "OpenTrap procedure failed: $res"
    return -1
	} else {
      set vaAppStatuses($appIndex,trapsessionID) $res
			$vaAppStatuses($appIndex,trapsessionID) bind trap "Traphandler $op_trapMsg %A %T %V"
	}
	set gMessage ""
	return $appIndex
}


#**********************************************************************
#                        ***** SnmpConfigTrap *****
#   Abstract :
#     configures snmp trap session
#   Arguments :
#		  ip_trapsessionID - session ID returned by OpenTrap procedure.
#     args parameters:
#
#							 -port
#							 -version
#							 -user
#							 -context
#							 -engineID
#							 -authKey
#							 -privKey
#							 -authPassWord
#							 -privPassWord
#							 -security
#							 -alias
#							 -transport
#							 -tag
#   Retval :	 0                             if ok
#							 current configuration				 if args = 0
#              error cod                     otherwise.
#   Example:
#    RLScotty::SnmpConfigTrap 1 -port 161 -version SNMPv3
#    set trapConfig [RLScotty::SnmpConfigTrap 1] 
#......................................................................

proc SnmpConfigTrap {ip_trapsessionID args} {
	global	gMessage	RLScotty
  variable vaAppStatuses
  set ok     0
  set fail  -1
	#check that sesionn ID from command line stored in vaAppStatuses array variable of this name space.
	if {$ip_trapsessionID >0 && $ip_trapsessionID < 33} {
  	if {![info exists vaAppStatuses($ip_trapsessionID,trapsessionID)]} {
  		set	gMessage "SnmpConfigTrap procedure: The session with ID=$ip_trapsessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
		}
	} else {
  		set	gMessage "SnmpConfigTrap procedure: The session with ID=$ip_trapsessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
	}
	if {![llength $args]} {
	  return [$vaAppStatuses($ip_trapsessionID,trapsessionID) configure]
	}
  if {[catch {eval "$vaAppStatuses($ip_trapsessionID,trapsessionID) configure $args"} msg]} {
    set	gMessage "SnmpCongigTrap procedure Failed: $msg"
    return $fail
  } else {
	   set gMessage ""
     return $ok
  }
}


#***************************************************************************
#**                        RLScotty::SnmpCloseTrap
#** 
#** Absrtact:
#**   Close the specific scotty  snmp listener trap session . 
#**
#**   Inputs:  ip_trapsessionID                :	  session ID returned by OpenTrap procedure 
#**                              
#**   Outputs: 
#**            0                       :        if success . 
#**            error message by RLEH 	 :				Otherwise.
#**                              
#** Example:                        
#**	  RLScotty::SnmpCloseTrap 1 
#***************************************************************************

proc SnmpCloseTrap {ip_trapsessionID} {
  global        gMessage RLScotty
  variable      vaAppStatuses 

	set false          0
	set true           1

	#check that application ID from command line stored in vaAppStatuses array variable of this name space.
	if {$ip_trapsessionID >0 && $ip_trapsessionID < 33} {
  	if {![info exists vaAppStatuses($ip_trapsessionID,trapsessionID)]} {
  		set	gMessage "SnmpCloseTrap procedure: The session with ID=$ip_trapsessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
		}
	} else {
  		set	gMessage "SnmpCloseTrap procedure: The session with ID=$ip_trapsessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
	}
	if {[catch {$vaAppStatuses($ip_trapsessionID,trapsessionID) destroy} res]} {
  	#unset	 vaAppStatuses($ip_trapsessionID,trapsessionID)
  	set	gMessage "SnmpCloseTrap procedure failed: $res"
		return -1
	} else {
    	unset	 vaAppStatuses($ip_trapsessionID,trapsessionID)
	    set gMessage ""
	    return 0
	}
}

#***************************************************************************
#**                        RLScotty::SnmpCloseAllTrap
#** 
#** Absrtact:
#**   Close all oppened snmp listener trap sessions . 
#**
#**                              
#**   Outputs: 
#**            0                       :        if success . 
#**            error message by RLEH 	 :				Otherwise.
#**                              
#** Example:                        
#**	  RLScotty::SnmpCloseAllTrap 
#***************************************************************************

proc SnmpCloseAllTrap {} {
  global        gMessage RLScotty
  variable      vaAppStatuses 

	#check opened sessions.
	for {set i 1} {$i <33} {incr i} {
		if {[info exists vaAppStatuses($i,trapsessionID)]} {
		  if {[SnmpCloseTrap $i]} {
    		set	gMessage "SnmpCloseAllTrap procedure failed: $gMessage"
				return -1
			}
		}
	}
	return 0
}


#**********************************************************************
#                        ***** SnmpMibs *****
#   Abstract :
#     obtain information from mib files.
#   Arguments :
#     first argument  :
#
#							 -access
#							 -description
#              -enums
#							 -exists
#							 -file
#							 -format
#							 -length
#							 -load
#							 -macro
#							 -name
#							 -oid
#							 -parent
#							 -scan
#							 -syntax
#							 -status
#
#     second argument : mib name or mib oid or file name 
#		  third argument  : mib value
#
#   Retval :	 info accordance to quires parameters.
#              error cod                     otherwise.
#   Example:
#    RLScotty::SnmpMibs -access prtMlTiming.255.301
#    RLScotty::SnmpMibs -syntax prtMlTiming.255.301
#    RLScotty::SnmpMibs -name 1.3.5.65.2.6
#    RLScotty::SnmpMibs -load c:\\rad0505.mib
#    RLScotty::SnmpMibs -scan prtMlSpeed.255.301 bps512000
#    RLScotty::SnmpMibs -format prtMlSpeed.255.301 3
#    RLScotty::SnmpMibs -enums prtMlSpeed.255.301
#......................................................................

proc SnmpMibs {args} {
	  global	gMessage RLScotty
    variable vaAppStatuses
    set ok     0
    set fail  -1

		#processing command line parameters
    set act   [lindex $args 0]
    set param [lindex $args 1]
    set val   [lindex $args 2]

    switch -exact -- $act  {
    

						-access {
                     if {[catch {Tnm::mib access $param} msg]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $msg"
                       return $fail
                     } else {
                         return $msg
                     }
						 }

						-description {
                     if {[catch {Tnm::mib description $param} msg]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $msg"
                       return $fail
                     } else {
                         return $msg
                     }
						 }

						-enums {
                     if {[catch {Tnm::mib type $param} restype]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $restype"
                       return $fail
                     } elseif {[catch {Tnm::mib enums $restype} msg]} {
                         set	gMessage "SnmpMibs procedure failed while $act: $msg"
                         return $fail
                     } else {
                         return $msg
                     }
						 }

						-exists {
                     if {[catch {Tnm::mib exists $param} msg]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $msg"
                       return $fail
                     } else {
                         return $msg
                     }
						 }

						-file {
                     if {[catch {Tnm::mib file $param} msg]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $msg"
                       return $fail
                     } else {
                         return $msg
                     }
						 }

						-format {
                     if {[catch {expr int($val)} res]} {
                       set	gMessage "SnmpMibs procedure failed while $act: The $val isn't integer"
                       return $fail
                     } elseif {[catch {Tnm::mib format $param $val} msg]} {
                         set	gMessage "SnmpMibs procedure failed while $param: $msg"
                         return $fail
                     } else {
                         return $msg
                     }
						 }

						-length {
                     if {[catch {Tnm::mib length $param} msg]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $msg"
                       return $fail
                     } else {
                         return $msg
                     }
						 }

						-load {
                     if {[catch {Tnm::mib load $param} msg]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $msg"
                       return $fail
                     } else {
                         return $msg
                     }
						 }

						-macro {
                     if {[catch {Tnm::mib macro $param} msg]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $msg"
                       return $fail
                     } else {
                         return $msg
                     }
						 }

						-name {
                     if {[catch {Tnm::mib name $param} msg]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $msg"
                       return $fail
                     } else {
                         return $msg
                     }
						 }

						-oid {
                     if {[catch {Tnm::mib oid $param} msg]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $msg"
                       return $fail
                     } else {
                         return $msg
                     }
						 }

						-parent {
                     if {[catch {Tnm::mib parent $param} msg]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $msg"
                       return $fail
                     } else {
                         return $msg
                     }
						 }

						-scan {
                     if {[catch {Tnm::mib scan $param $val} msg]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $msg"
                       return $fail
                     } else {
                         return $msg
                     }
						 }

						-syntax {
                     if {[catch {Tnm::mib syntax $param} msg]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $msg"
                       return $fail
                     } else {
                         return $msg
                     }
						 }

						-status {
                     if {[catch {Tnm::mib status $param} msg]} {
                       set	gMessage "SnmpMibs procedure failed while $act: $msg"
                       return $fail
                     } else {
                         return $msg
                     }
						 }



             default {
                      set gMessage "RLScotty::SnmpMibs :  Wrong name of parameter $act"
                      return $fail
             }
	 }



}


#**********************************************************************
#                        ***** Ping *****
#   Abstract :
#     send message to agent and wait for replay
#   Arguments :
#             ip_sessionID
#   Retval :
#     0 for o.k
#		 -1 for fail
#   Example:
#    Ping 1
#......................................................................

proc Ping {ip_sessionID} {
  global        gMessage RLScotty
  variable      vaAppStatuses 
	#check that application ID from command line stored in vaAppStatuses array variable of this name space.
	if {$ip_sessionID >0 && $ip_sessionID < 33} {
  	if {![info exists vaAppStatuses($ip_sessionID,sessionID)]} {
  		set	gMessage "Ping procedure: The session with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
		}
	} else {
  		set	gMessage "Ping procedure: The Application with ID=$ip_sessionID doesn't exist"
      return [RLEH::Handle SAsyntax gMessage]
	}

	set ipAdd [$vaAppStatuses($ip_sessionID,sessionID) cget -address]
	set irtt [lindex [Tnm::icmp -retries 1 -timeout 1 echo $ipAdd] 1]
	#puts $irtt

	if {$irtt > 0} {
    return 0
  } else {
				return -1
  }
}

#***************************************************************
#** ProcCheckValidIp
#***************************************************************

proc ProcCheckValidIp {ip_ipAddress} {
	global	gMessage RLScotty
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

#end name space
}
