#.........................................................................................
#   File name: RLEtxGen.tcl
#   Written by Semion 31.4.2011 Updated by Semion 
#
#   Abstract: This file activate the product Etx-204A with specific software for running Ethernet generator,
#              This Etx-204A has 4 generators , every one may be configured indepandly.
#   Procedures names in this file:
#           - Open
#           - PortsConfig
#           - GenConfig
#           - PacketConfig
#           - RawPacketConfig
#           - GetConfig
#           - Start
#           - Stop
#           - GetStatistics
#           - ShowGui
#           - Clear
#           - ChkConnect
#           - GoToMain
#           - Close
#           - CloseAll
#
#.........................................................................................

package require BWidget
package require RLEH 
package provide RLEtxGen 1.21
global gEtxGenBufferDebug
set gEtxGenBufferDebug 0
global gMessage

namespace eval RLEtxGen {
  namespace export Open PortsConfig GenConfig PacketConfig RawPacketConfig GetConfig Start Stop \
	GetStatistics ShowGui Clear ChkConnect GoToMain Close CloseAll 
 
  global gMessage
  global    gEtxGenBuffer
  global    gEtxGenBufferDebug
  variable  vaEtxGenGui
  variable  vaEtxGenSet
  variable  vaEtxGenCfg
  variable  vaEtxGenStatuses 
  variable  vOpenedEtxGenHistoryCounter
  
	set vaEtxGenSet(closeByDestroy) 0
	set vaEtxGenSet(startTime) 0
  set vaEtxGenSet(EmailSum) 10
  set vOpenedEtxGenHistoryCounter  0

  set vaEtxGenStatuses(lMenuGenmode)      "stam fe ge"
  set vaEtxGenStatuses(lMenuPackType)     "stam mac vlan ip raw"
  set vaEtxGenStatuses(lMenuVlanType)     "stam oneTagged stacked"
  set vaEtxGenStatuses(lMenuSvlanType)    "stam 8100 9100 88a8"
#***************************************************************************
#***************************************************************************
#
#                  EXPORT FUNCTIONs
#
#***************************************************************************
#***************************************************************************

#***************************************************************************
#**                        RLEtxGen::Open
#** 
#**  Abstract: Open the RLEtxGen by com or telnet
#**            Check if the RLEtxGen is ready to be activate
#**
#**   Inputs:
#**            ip_address             :	        Com number or IP address.
#**                              
#**            args   parameters and their value:
#**                              
#**                              
#**  					 -package  	             :	      RLCom/RLSerial/RLTcp/RLPlink (default rlcom).
#**                              
#**                              
#**   Outputs: 
#**            IDApp                   :        ID of opened  RLEtxGen . 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	1. set id1  [RLEtxGen::Open 1 -package RLSerial]
#**	2. set id2  [RLEtxGen::Open 172.18.124.102 -package RLTcp]
#**	2. set id3  [RLEtxGen::Open 172.18.124.102 -package RLTcp -config factory]
#***************************************************************************

proc Open {ip_address args } {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  set gMessage ""                   
	set package 		 RLCom
  set config         none
	set fail          -1
	set ok             0

	#processing command line parameters
  foreach {param val}   $args   {
   
    switch -exact -- $param  {
    

						-package {
                          set package $val
                          if {[lsearch  "RLCom RLSerial RLTcp RLPlink" $package] == -1} {
         					            set	gMessage "RLEtxGen Open:  Wrong value of parameter $param (must be RLCom/RLSerial/RLTcp/RLPlink)"
                              return [RLEH::Handle SAsyntax gMessage]
      										}
						 }

						-config {
                          set config $val
                          if {$config != "factory"} {
         					            set	gMessage "RLEtxGen Open:  Wrong value of parameter $param (must be factory)"
                              return [RLEH::Handle SAsyntax gMessage]
      										}
						 }

             default {
                      set gMessage "RLEtxGen Open:  Wrong name of parameter $param (must be -package/-config)"
                      return [RLEH::Handle SAsyntax gMessage]
             }
		}
	}

  #processing address
  if {[regexp {([0-9]+).([0-9]+).([0-9]+).([0-9]+)} $ip_address match subip1 subip2 subip3 subip4]} {
     if {$subip1 > 255 || $subip2 > 255 || $subip3 > 255 || $subip4 > 255} {
        set gMessage "RLEtxGen Open:  Wrong IP address"
        return [RLEH::Handle SAsyntax gMessage]
     }
      set connection telnet
  } elseif {$ip_address > 333 || $ip_address < 1} {
      set gMessage "RLEtxGen Open:  Wrong Com number or IP address"
      return [RLEH::Handle SAsyntax gMessage]
  } else {
      set connection com
  }
	#check empty place in Opened EtxGen array
	for {set i 1} {$i <= $vOpenedEtxGenHistoryCounter} {incr i} {
		if {![info exists vaEtxGenStatuses($i,EtxGenID)]} {
		  break
		}
	}

	set EtxGenIndex $i
  #open EtxGen
  set  vaEtxGenStatuses($i,connection) $connection
  set  vaEtxGenStatuses($i,package) $package
  set  vaEtxGenStatuses($i,address) $ip_address

  if {![OpenEtxGen $ip_address $connection $package $i]} {
    set  vaEtxGenStatuses($i,EtxGenID) $i
  	if {$i > $vOpenedEtxGenHistoryCounter} {
      incr vOpenedEtxGenHistoryCounter
    }
  	if {[string match -nocase $config "factory"]} {
      GenConfig $vaEtxGenStatuses($i,EtxGenID) -factory yes
    }
    return $vaEtxGenStatuses($i,EtxGenID)
  } else {
      append gMessage "\nCann't open Etx-204A"
      #return [RLEH::Handle SAsyntax gMessage]
			return $fail
  }
} 

#***************************************************************************
#**                        RLEtxGen::PortsConfig
#** 
#**  Abstract: Configure ports parameters of Etx204A by com or telnet
#**
#**   Inputs:
#**            ip_ID                   :	        ID of Etx204A  returned by Open procedure .
#**                              
#**                              
#**            args   parameters and their value:
#**                              
#**                              
#**  					 -updGen  	             :	      1-4 or All
#**                              
#**  					 -admStatus 	           :	      up/down.
#**                              
#**  					 -autoneg    	           :	      Enbl/Dsbl.
#**                              
#**  					 -maxAdvertize    	     :	      10-f/100-f/1000-f/1000-x.
#**                              
#**  					 -speed   	             :	      10-f/100-f/1000-f/1000-x.
#**                              
#**  					 -factory    	           :	      yes/no.
#**                              
#**  					 -save      	           :	      yes/no.
#**                              
#**  					 -reset      	           :	      yes/no.
#**                              
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**  RLEtxGen::PortsConfig $id -updGen all -factory yes -save yes
#**	 RLEtxGen::PortsConfig $id -updGen all -autoneg enbl  -maxAdvertize 1000 -admStatus up
#**  RLEtxGen::PortsConfig $id -updGen 2 -autoneg dsbl -speed 100
#***************************************************************************

proc PortsConfig {ip_ID args } {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  set gMessage "" 
  set updGen   all             
	set fail          -1
	set ok             0

  if {$ip_ID == "?"} {
    return "arguments options:  -updGen , -admStatus , -autoneg , -maxAdvertize , -speed , -factory , -save -reset"
  }

  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set	gMessage "PortsConfig procedure: The EtxGen with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaEtxGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "PortsConfig procedure: The plink process doesn't exist for EtxGen with ID=$ip_ID"
      return $fail
    }
  }


	#processing command line parameters
  foreach {param val}   $args   {
   
    switch -exact -- $param  {
    

						-updGen {
                      if {$val == "?"} {
                        return "updated port options:  1-4/all.........."
                      }

											if {[regexp -nocase {all} $val]} {
  											    set updGen $val
											} elseif {$val == 1 || $val == 2} {
  											  set updGen $val
											} elseif {$val == 3 || $val == 4} {
  											  set updGen [expr $val + 2]
											}	else {
                  		    set	gMessage "PortsConfig procedure: The value $val of parameter $param wrong"
                          return [RLEH::Handle SAsyntax gMessage]
											}
											set vaEtxGenStatuses($ip_ID,updGen) $val
						 }

						-admStatus {
                    if {$val == "?"} {
                      return "Administrative status options:  up , down"
                    }
										if {[string match -nocase $val "up"]} {
											set admStatus "no shut"
										} elseif {[string match -nocase $val "down"]} {
											   set admStatus "shutdown"
										} else {
   					            set	gMessage "PortsConfig procedure:  Wrong value: $val of parameter $param (must be up/down)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }

						-autoneg {
                    if {$val == "?"} {
                      return "Autonegotiation options:  enbl , dsbl"
                    }
										if {[string match -nocase $val "enbl"]} {
											set autoneg auto-neg
										} elseif {[string match -nocase $val "dsbl"]} {
											   set autoneg "no auto-neg"
										} else {
   					            set	gMessage "PortsConfig procedure:  Wrong value: $val of parameter $param (must be yes/no)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }


						-maxAdvertize {
                      if {$val == "?"} {
                        return "maxAdvertize options:  10-f , 100-f , 1000-f 1000-x"
                      }
 						          if {$val != "10-f" && $val != "100-f" && $val != "1000-f" && $val != "1000-x"} {
                		    set	gMessage "PortsConfig procedure: The maxAdvertize value $val of parameter $param wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set maxAdvertize $val
											}
											if {[info exists autoneg] && $autoneg == "no auto-neg"} {
                		    set	gMessage "PortsConfig procedure: Conflict between parameters autoneg and maxAdvertize"
                        return [RLEH::Handle SAsyntax gMessage]
											}
						 }

						-speed {
                      if {$val == "?"} {
                        return "speed options:  10-f , 100-f , 1000-f 1000-x"
                      }
 						          if {$val != "10-f" && $val != "100-f" && $val != "1000-f" && $val != "1000-x"} {
                		    set	gMessage "PortsConfig procedure: The speed value $val of parameter $param wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set speed $val
											}
											if {[info exists autoneg] && $autoneg == "auto-neg"} {
                		    set	gMessage "PortsConfig procedure: Conflict between parameters autoneg and speed"
                        return [RLEH::Handle SAsyntax gMessage]
											}
						 }

						-factory {
                    if {$val == "?"} {
                      return "factory options:  yes , no (or 1 , 0)"
                    }
										if {[string match -nocase $val "yes"] || $val == 1} {
											set factory $val
										} elseif {[string match -nocase $val "no"] || $val == 0} {
											   #set factory $val
										} else {
   					            set	gMessage "PortsConfig procedure:  Wrong value: $val of parameter $param (must be yes/no)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }

						-save {
                    if {$val == "?"} {
                      return "save options:  yes , no (or 1 , 0)"
                    }
										if {[string match -nocase $val "yes"] || $val == 1} {
											set save $val
										} elseif {[string match -nocase $val "no"] || $val == 0} {
											   #set save $val
										} else {
   					            set	gMessage "PortsConfig procedure:  Wrong value: $val of parameter $param (must be yes/no)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }

						-reset {
                    if {$val == "?"} {
                      return "save options:  yes , no"
                    }
										if {[string match -nocase $val "yes"]} {
											set reset $val
										} elseif {[string match -nocase $val "no"]} {
											   set reset $val
										} else {
   					            set	gMessage "PortsConfig procedure:  Wrong value: $val of parameter $param (must be yes/no)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }

             default {
                      set gMessage "PortsConfig procedure:   Wrong name of parameter $param"
                      return [RLEH::Handle SAsyntax gMessage]
             }
		}
	}
	set ret 0
	set ret [SendToEtxGen $ip_ID "\r" "ETX-204A-" 4]
	set ret [SendToEtxGen $ip_ID "\r" "ETX-204A-" 6]
	if {!$ret} {
		if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_ID)] || [string match "*ETX-204A-*\[AD\]C>*" $gEtxGenBuffer(id$ip_ID)]} {
			set vaEtxGenStatuses($ip_ID,currScreen) "Cli"
		  set ret [SendToEtxGen $ip_ID "\r" "ETX-204A-" 4]
			if {$ret} {
				set vaEtxGenStatuses($ip_ID,currScreen) "na"
	      set gMessage "PortsConfig procedure: Can't recognize current screen Etx204A($ip_ID)"
				return $fail
		  }
		} elseif {[string match "*menu*" $gEtxGenBuffer(id$ip_ID)]} {
	      set ret [SendToEtxGen $ip_ID "!" "Kernel Objects" 6]
		    DelayMs 10
	      set ret [expr [SendToEtxGen $ip_ID "7\r" "ETX-204A-" 6] | $ret]
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while switch to CLI Etx204A($ip_ID)"
					return $fail
				}
				if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_ID)] == 0} {
		      set gMessage "PortsConfig procedure: Fail while switch to CLI Etx204A($ip_ID)"
					return $fail
				}

		}
	} else {
	    set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "PortsConfig procedure: There isn't connection to Etx204A($ip_ID)"
			return $fail
	}

  if {[info exists admStatus]} {
	  set ret [SendToEtxGen $ip_ID "exit all\r" "ETX-204A-" 6] 
		DelayMs 20
		if {$updGen == "all"} {
      foreach port {1 2 5 6} {
	      set ret [expr [SendToEtxGen $ip_ID "conf port eth $port $admStatus\r" "ETX-204A-" 6] | $ret]
		    DelayMs 20
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $port $admStatus Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $port $admStatus Etx204A($ip_ID)"
					return $fail
				}
			}
		} else {
	      set ret [expr [SendToEtxGen $ip_ID "conf port eth $updGen $admStatus\r" "ETX-204A-" 6] | $ret]
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $updGen $admStatus Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $updGen $admStatus Etx204A($ip_ID)"
					return $fail
				}
		}
	}

  if {[info exists factory]} {
	  set ret [SendToEtxGen $ip_ID "exit all\r" "ETX-204A-" 6]
		DelayMs 20
		if {$updGen == "all"} {
      foreach port {1 2 5 6} {
	      set ret [expr [SendToEtxGen $ip_ID "conf port eth $port no shut\r" "ETX-204A-" 6] | $ret]
		    DelayMs 10
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $port no shut (factory) Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $port no shut (factory) Etx204A($ip_ID)"
					return $fail
				}
		    DelayMs 10
	      set ret [SendToEtxGen $ip_ID "conf port eth $port auto-neg\r" "ETX-204A-" 6]
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $port auto-neg (factory) Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $port auto-neg (factory) Etx204A($ip_ID)"
					return $fail
				}
		    DelayMs 10
	      set ret [SendToEtxGen $ip_ID "conf port eth $port max-cap 1000-full\r" "ETX-204A-" 6]
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $port max-cap 1000-full (factory) Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $port max-cap 1000-full (factory) Etx204A($ip_ID)"
					return $fail
				}
			}
		} else {
	      set ret [SendToEtxGen $ip_ID "conf port eth $updGen no shut\r" "ETX-204A-" 6]
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $updGen no shut (factory) Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $updGen no shut (factory) Etx204A($ip_ID)"
					return $fail
				}
	      DelayMs 10
	      set ret [SendToEtxGen $ip_ID "conf port eth $updGen auto-neg\r" "ETX-204A-" 6]
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $updGen auto-neg (factory) Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $updGen auto-neg (factory) Etx204A($ip_ID)"
					return $fail
				}
	      DelayMs 10
	      set ret [SendToEtxGen $ip_ID "conf port eth $updGen max-cap 1000-full\r" "ETX-204A-" 6]
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $updGen max-cap 1000-full (factory) Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $updGen max-cap 1000-full (factory) Etx204A($ip_ID)"
					return $fail
				}
		}
	}

  if {[info exists autoneg]} {
	  set ret [SendToEtxGen $ip_ID "exit all\r" "ETX-204A-" 6]
		DelayMs 20
		if {$updGen == "all"} {
      foreach port {1 2 5 6} {
	      set ret [expr [SendToEtxGen $ip_ID "conf port eth $port $autoneg\r" "ETX-204A-" 6] | $ret]
		    DelayMs 20
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $port $autoneg Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $port $autoneg Etx204A($ip_ID)"
					return $fail
				}
			}
		} else {
	      set ret [expr [SendToEtxGen $ip_ID "conf port eth $updGen $autoneg\r" "ETX-204A-" 6] | $ret]
		    DelayMs 20
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $updGen $autoneg Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $updGen $autoneg Etx204A($ip_ID)"
					return $fail
				}
		}
	}

  if {[info exists maxAdvertize]} {
	  set ret [SendToEtxGen $ip_ID "exit all\r" "ETX-204A-" 6] 
		DelayMs 20
		if {$updGen == "all"} {
      foreach port {1 2 5 6} {
	      set ret [expr [SendToEtxGen $ip_ID "conf port eth $port max-cap $maxAdvertize\r" "ETX-204A-" 6] | $ret]
		    DelayMs 20
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $port max-cap $maxAdvertize Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $port max-cap $maxAdvertize Etx204A($ip_ID)"
					return $fail
				}
			}
		} else {
	      set ret [expr [SendToEtxGen $ip_ID "conf port eth $updGen max-cap $maxAdvertize\r" "ETX-204A-" 6] | $ret]
		    DelayMs 20
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $updGen max-cap $maxAdvertize Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $updGen max-cap $maxAdvertize Etx204A($ip_ID)"
					return $fail
				}
		}
	}

  if {[info exists speed]} {
	  set ret [expr [SendToEtxGen $ip_ID "exit all\r" "ETX-204A-" 6] | $ret]
		DelayMs 20
		if {$updGen == "all"} {
      foreach port {1 2 5 6} {
	      set ret [expr [SendToEtxGen $ip_ID "conf port eth $port speed $speed\r" "ETX-204A-" 6] | $ret]
		    DelayMs 20
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $port speed $speed Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $port speed $speed Etx204A($ip_ID)"
					return $fail
				}
			}
		} else {
	      set ret [expr [SendToEtxGen $ip_ID "conf port eth $updGen speed $speed\r" "ETX-204A-" 6] | $ret]
		    DelayMs 20
				if {$ret} {
		      set gMessage "PortsConfig procedure: Fail while conf port eth $updGen speed $speed Etx204A($ip_ID)"
					return $fail
				}
	      if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
		      set gMessage "PortsConfig procedure: cli error while conf port eth $updGen speed $speed Etx204A($ip_ID)"
					return $fail
				}
		}
	}

  if {[info exists save]} {
		DelayMs 20
	  set ret [SendToEtxGen $ip_ID "admin save\r" "has been successfuly written to flash" 8]
		if {$ret} {
      set gMessage "PortsConfig procedure: Fail while admin save (save) Etx204A($ip_ID)"
			return $fail
		}
    if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
      set gMessage "PortsConfig procedure: cli error while admin save (save) Etx204A($ip_ID)"
			return $fail
		}
	}

  if {[info exists reset]} {
		DelayMs 20
	  set ret [SendToEtxGen $ip_ID "admin reboot\r" "Device will reboot" 8]
		if {$ret} {
      set gMessage "PortsConfig procedure: Fail while admin reboot  Etx204A($ip_ID)"
			return $fail
		}
    if {[string match "*cli error*" $gEtxGenBuffer(id$ip_ID)]} {
      set gMessage "PortsConfig procedure: cli error while admin reboot Etx204A($ip_ID)"
			return $fail
		}
	  set ret [SendToEtxGen $ip_ID "y\r" "ETX-204A-" 8]
		if {$ret} {
      set gMessage "PortsConfig procedure: Fail while admin reboot send \"Y\"  Etx204A($ip_ID)"
			return $fail
		} else {
		   set vaEtxGenStatuses($ip_ID,currScreen) "na"
       return $ret
		}
		if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_ID)] == 0} {
      set gMessage "PortsConfig procedure: Fail while admin reboot send \"Y\"  Etx204A($ip_ID)"
			return $fail
		}
	}
  if {$ret} {
		set vaEtxGenStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}
							 
#*************************************************************************
#**                        RLEtxGen::GenConfig
#** 
#**  Abstract: Configure Gen ports parameters of Etx204A Generator by com or telnet
#**
#**   Inputs:
#**            ip_ID                   :	        ID of Etx204A Gen returned by Open procedure .
#**                              
#**                              
#**            args   parameters and their value:
#**                              
#**                              
#**  					 -updGen  	         :	      1-4/all.
#**                              
#**  					 -packType    	     :	      MAC/VLAN/SVLAN/IP/RAW.
#**                              
#**  					 -factory    	       :	      yes/no.
#**                              
#**  					 -genMode    	       :	      FE/GE.
#**                              
#**  					 -minLen    	       :	      64-1600.
#**                              
#**  					 -maxLen    	       :	      64-1600.
#**                              
#**  					 -chain       	     :	      1-20.
#**                              
#**  					 -stream       	     :	      1-256.
#**                              
#**  					 -packRate    	     :	      1-1500000.
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLEtxGen::GenConfig 1 -updGen all -factory yes -genMode GE -minLen  120	-maxLen 550 -chain 3 -packRate 20000
#***************************************************************************

proc GenConfig {ip_ID args } {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0

  if {$ip_ID == "?"} {
    return "arguments options:  -updGen , -genMode , -minLen , -maxLen ,-chain -stream -packRate"
  }

  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set	gMessage "GenConfig procedure: The EtxGen with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaEtxGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "GenConfig procedure: The plink process doesn't exist for EtxGen with ID=$ip_ID"
      return $fail
    }
  }


	#processing command line parameters
  foreach {param val}   $args   {
   
    switch -exact -- $param  {
    

						-updGen {
                      if {$val == "?"} {
                        return "updated port options:  1-4/all."
                      }

											if {[regexp -nocase {all} $val]} {
  											    set updGen 5
											} elseif {$val > 0 && $val < 5} {
  											  set updGen $val
											}	else {
                  		    set	gMessage "GenConfig procedure: The value $val of parameter $param wrong"
                          return [RLEH::Handle SAsyntax gMessage]
											}
											set vaEtxGenStatuses($ip_ID,updGen) $val

						 }

						-packType {
                    if {$val == "?"} {
                      return "packType options:  MAC, VLAN ,SVLAN, IP , RAW"
                    }
										if {[string match -nocase  "*MAC*" $val]} {
											set packType 1
										} elseif {[string match -nocase "*SVLAN*" $val]} {
											   set packType 2
												 set vlanType 2
										} elseif {[string match -nocase "*VLAN*" $val]} {
											   set packType 2
												 set vlanType 1
										} elseif {[string match -nocase  "*IP*" $val]} {
											   set packType 3
										} elseif {[string match -nocase  "*RAW*" $val]} {
											   set packType 4
										} else {
   					            set	gMessage "GenConfig procedure:  Wrong value: $val of parameter $param (MAC/VLAN/IP/RAW)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }
						-factory {
                    if {$val == "?"} {
                      return "factory options:  yes"
                    }
										if {[string match -nocase $val "yes"] || $val == 1} {
											set factory $val
										} else {
   					            set	gMessage "GenConfig procedure:  Wrong value: $val of parameter $param (must be yes)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }



						-genMode {
                    if {$val == "?"} {
                      return "genMode options:  FE , GE"
                    }
										if {[string match -nocase $val "fe"]} {
											set genMode FE
										} elseif {[string match -nocase $val "ge"]} {
											   set genMode GE
										} else {
   					            set	gMessage "GenConfig procedure:  Wrong value: $val of parameter $param (must be FE/GE)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }

						-minLen {
                      if {$val == "?"} {
                        return "minLen options:  64-1600"
                      }
										  if {$val < 64 || $val > 1600} {
										    set	gMessage "GenConfig procedure: minLen must be: 64-1600"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set minLen $val
											}
						 }

						-maxLen {
                      if {$val == "?"} {
                        return "maxLen options:  64-1600"
                      }
										  if {$val < 64 || $val > 1600} {
										    set	gMessage "GenConfig procedure: maxLen must be: 64-1600"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set maxLen $val
											}
						 }
						-chain {
                      if {$val == "?"} {
                        return "chain options:  1-20"
                      }
										  if {$val < 1 || $val > 20} {
										    set	gMessage "GenConfig procedure: chain must be: 1-20"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set chain $val
											}
						 }

						-stream {
                      if {$val == "?"} {
                        return "stream options:  1-256"
                      }
										  if {$val < 1 || $val > 256} {
										    set	gMessage "GenConfig procedure: stream must be: 1-256"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set stream $val
											}
						 }
						-packRate {
                      if {$val == "?"} {
                        return "packRate options:  1-1500000"
                      }
										  if {$val < 1 || $val > 1500000} {
										    set	gMessage "GenConfig procedure: packRate must be: 1-1500000"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set packRate $val
											}
						 }

             default {
                      set gMessage "GenConfig procedure:   Wrong name of parameter $param"
                      return [RLEH::Handle SAsyntax gMessage]
             }
		}
	}

	set ret 0
	set ret [SendToEtxGen $ip_ID "\r\r" "ETX-204A-" 6]
	#puts 1----$gEtxGenBuffer(id$ip_ID)
	if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_ID)] || [string match "*ETX-204A-*\[AD\]C>*" $gEtxGenBuffer(id$ip_ID)]} {
		SendToEtxGen $ip_ID "ch\r\r" "Switch to CLI" 6
		set ret [expr [SendToEtxGen $ip_ID "\r\r" "Switch to CLI" 6] | $ret]
	  #puts 2----$gEtxGenBuffer(id$ip_ID)
		DelayMs 20
		set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
	  #puts 3----$gEtxGenBuffer(id$ip_ID)
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "GenConfig procedure: Fail switch from CLI to Generator screen Etx204A($ip_ID)"
			return $fail
		}
		set vaEtxGenStatuses($ip_ID,currScreen) "Gen"
	} else {
			if {$vaEtxGenStatuses($ip_ID,currScreen) != "Gen"} {
			  set ret [SendToEtxGen $ip_ID "!" "Kernel Objects" 6]
		 	  DelayMs 20
			  set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
				if {$ret} {
					set vaEtxGenStatuses($ip_ID,currScreen) "na"
		      set gMessage "GenConfig procedure: Fail while get Generator screen from main menu Etx204A($ip_ID)"
					return $fail
				}
				set vaEtxGenStatuses($ip_ID,currScreen) "Gen"
		  } else {
			    set ret [SendToEtxGen $ip_ID "\r" "Generator Factory" 6]
					if {$ret} {
						set vaEtxGenStatuses($ip_ID,currScreen) "na"
			      set gMessage "GenConfig procedure: Fail while get Generator screen Etx204A($ip_ID)"
						return $fail
					}
			}
	}

  #updated updGen
  if {[info exists updGen]} {
    set ret [SendToEtxGen $ip_ID "1\r" "All" 6]
		DelayMs	 20
    set ret [expr [SendToEtxGen $ip_ID "$updGen\r" "Generator Factory" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "GenConfig procedure: Fail while set generator number Etx204A($ip_ID)"
			return $fail
		}
		#puts $gEtxGenBuffer(id$ip_ID)
  }


   #handling factory
  if {[info exists factory]} {
    set ret [SendToEtxGen $ip_ID "\r" "Generator Factory" 6]
	  set line [FindLine $ip_ID "Generator Factory"]
		if {$line == -1} {
      set gMessage "GenConfig procedure: Fail while set generator factory (FindLine = -1) Etx204A($ip_ID)"
			return $fail
		}
    set ret [SendToEtxGen $ip_ID "$line\r" "Generator Factory" 6]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "GenConfig procedure: Fail while set generator factory Etx204A($ip_ID)"
			return $fail
		}
  }

  if {[info exists packType]} {
	  set ret [SendToEtxGen $ip_ID "3\r" "RAW" 6]
		DelayMs	 20
	  set ret [expr [SendToEtxGen $ip_ID "$packType\r" "Generator Factory" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
	    set gMessage "GenConfig procedure: Fail while set packType Etx204A($ip_ID)"
			return $fail
		}
		#puts $gEtxGenBuffer(id$ip_ID)
	}
  #update vlanType
  if {[info exists vlanType]} {
    set ret [SendToEtxGen $ip_ID "12\r" "C-Vlan incr idle" 6]
 	  DelayMs	 20
	  if {$vlanType == 1 && ![string match "*One tag*" $gEtxGenBuffer(id$ip_ID)]} {
      set ret [expr [SendToEtxGen $ip_ID "2\r" "C-Vlan incr idle" 6] | $ret]
	  }
	  if {$vlanType == 2  && ![string match "*Two tags*" $gEtxGenBuffer(id$ip_ID)]} {
      set ret [expr [SendToEtxGen $ip_ID "2\r" "C-Vlan incr idle" 6] | $ret]
	  }
 	  if {$ret} {
 		  set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "GenConfig procedure: Fail while set vlanType Etx204A($ip_ID)"
 		  return $fail
 	  } else {
			  SendToEtxGen $ip_ID "\33" "Generator Factory" 6
 	  }
 	 #puts $gEtxGenBuffer(id$ip_ID)
  }
  #handling genMode
  if {[info exists genMode]} {
    if {![string match -nocase "*($genMode)*" $gEtxGenBuffer(id$ip_ID)]} {
      set ret [SendToEtxGen $ip_ID "2\r" "Generator Factory" 6]
			if {$ret} {
				set vaEtxGenStatuses($ip_ID,currScreen) "na"
	      set gMessage "GenConfig procedure: Fail while set generator mode Etx204A($ip_ID)"
				return $fail
			}
    }
  }

	foreach {item itemNumber} {minLen 4 maxLen 5 chain 6 stream 7 packRate 8} {

	  if {[info exists $item]} {
	    set ret [SendToEtxGen $ip_ID "$itemNumber\r" "H" 6]
			DelayMs	 20
	    set ret [expr [SendToEtxGen $ip_ID "[set $item]\r" "Generator Factory" 6] | $ret]
			if {$ret} {
				set vaEtxGenStatuses($ip_ID,currScreen) "na"
	      set gMessage "GenConfig procedure: Fail while set $item Etx204A($ip_ID)"
				return $fail
			}
			#puts $gEtxGenBuffer(id$ip_ID)
	  }
	}

	SendToEtxGen $ip_ID "S\r" "item"
  if {$ret} {
		set vaEtxGenStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}


#*************************************************************************
#**                        RLEtxGen::PacketConfig
#** 
#**  Abstract: Configure Gen ports packet parameters of Etx204A Generator by com or telnet
#**
#**   Inputs:
#**            ip_ID                   :	        ID of Etx204A Gen returned by Open procedure .
#**                              
#**            ip_packetType           :         MAC/VLAN/IP  
#**                              
#**            args   parameters and their value:
#**                              
#**                              
#**  					 -updGen  	         :	      1-4/all.
#**                              
#**  					 -DA        	       :	      Destination MAC.
#**                              
#**  					 -SA        	       :	      Source MAC.
#**                              
#**  					 -clrUdf             :	      clear udf fields.
#**                              
#**  					 -DAincrval          :	      increment DA value.
#**                              
#**  					 -DAincrsteps    	   :	      increment DA steps.
#**                              
#**  					 -DAincridle    	   :	      increment DA steps.
#**                              
#**  					 -SAincrval          :	      increment SA value.
#**                              
#**  					 -SAincrsteps    	   :	      increment SA steps.
#**                              
#**  					 -SAincridle    	   :	      increment SA steps.
#**                              
#**            -ethType            :        Ethernet packet type(0806,2380,....)                 
#**                              
#**            -vlanType          :        onetagged/stacked                  
#**                              
#**            -cvlanid           :        1-4094
#**                              
#**            -cvlanp            :        0-7     
#**                              
#**            -cvlanincr         :        incriment c-vlan id           
#**                              
#**            -cvlanincrsteps    :        incriment c-vlan id steps          
#**                              
#**            -cvlanincridle     :        incriment c-vlan id idle          
#**                              
#**            -svlanid           :        1-4094
#**                              
#**            -svlantype         :        8100/9100/88A8
#**                              
#**            -svlanp            :        0-7     
#**                              
#**            -svlanincr         :        incriment s-vlan id           
#**                              
#**            -svlanincrsteps    :        incriment s-vlan id steps          
#**                              
#**            -svlanincridle     :        incriment s-vlan id idle          
#**                              
#**            -tos                : 			  type of service Ip packet
#**                              
#**            -ttl                : 			  time to live Ip packet
#**                              
#**            -identif            :        identification Ip packet
#**                              
#**            -protocol           :        protocol	Ip packet
#**                              
#**            -sourceip           :        source IP
#**                              
#**            -destinip           :        destination IP
#**                              
#**            -payload            :      	payload of first 44 bytes
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLEtxGen::PacketConfig 1 MAC -updGen all -DA 000000000011 -SA 000000000022 -DAincrval 1 DAincrsteps 20 -clrUdf yes
#**	 RLEtxGen::PacketConfig 1 VLAN -updGen all -vlanType onetagged -c_vlanid 5 -cvlanp  3 -cvlanincr 2
#**	 RLEtxGen::PacketConfig 1 IP -updGen all -tos 11 -ttl 32 -identif 222 -sourceip 1.1.1.1 -destinip 2.2.2.2
#***************************************************************************

proc PacketConfig {ip_ID ip_packType args } {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0
  set vlanType       1
  set subre (\\d|\[1-9\]\\d|1\\d\\d|2\[0-4\]\\d|25\[0-5\])
	set re "^$subre\\.$subre\\.$subre\\.$subre$"

  if {$ip_ID == "?"} {
    return "arguments options:  -updGen , -DA , -SA , -DAincrval ,-DAincrsteps -DAincridle -SAincrval ,-SAincrsteps , -SAincridle\
		-ethType , -vlanType , -cvlanid , -cvlanp  , -cvlanincr , -cvlanincrsteps , -cvlanincridle , -svlanid, -svlantype , -svlanp\
	  -svlanincr , -svlanincrsteps , -svlanincridle , -tos , -ttl , -identif , -protocol , -sourceip , -destinip , -payload"
  }

  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set	gMessage "PacketConfig procedure: The EtxGen with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaEtxGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "PacketConfig procedure: The plink process doesn't exist for EtxGen with ID=$ip_ID"
      return $fail
    }
  }

	if {[regexp {(mac|vlan|ip)} [string tolower $ip_packType] match type] == 0} {
	  set	gMessage "PacketConfig procedure: Wrong packet type: must be MAC or VLAN or IP Etx204A($ip_ID)"
    return $fail
	} else {
	    switch -exact -- $type {
				 mac {set packType 1}
				 vlan {set packType 2}
				 ip {set packType 3}
			}
	}
	#processing command line parameters
  foreach {param val}   $args   {
   
    switch -exact -- $param  {
    

						-updGen {
                      if {$val == "?"} {
                        return "updated port options:  1-4/all."
                      }

											if {[regexp -nocase {all} $val]} {
  											    set updGen 5
											} elseif {$val > 0 && $val < 5} {
  											  set updGen $val
											}	else {
                  		    set gMessage "PacketConfig procedure: The value $val of parameter $param wrong"
                          return [RLEH::Handle SAsyntax gMessage]
											}
											set vaEtxGenStatuses($ip_ID,updGen) $val

						 }

						-DA {
										  if {[regexp -nocase {([0-9a-f]{2}){6}} $val] == 0} {
										    set gMessage "PacketConfig procedure: DA is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set DA $val
											}
						 }


						-clrUdf {
													set clrUdf $val
						 }

						-DAincrval {
										  if {[regexp {^[\d]+$} $val] == 0} {
										    set gMessage "PacketConfig procedure: DAincrval is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set DAincrval $val
											}
						 }

						-DAincrsteps {
										  if {[regexp {^[\d]+$} $val] == 0} {
										    set gMessage "PacketConfig procedure: DAincrsteps is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set DAincrsteps $val
											}
						 }

						 						
						-DAincridle {
										  if {[regexp {^[\d]+$} $val] == 0} {
										    set gMessage "PacketConfig procedure: DAincridle is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set DAincridle $val
											}
						 }

						-SA {
										  if {[regexp -nocase {([0-9a-f]{2}){6}} $val] == 0} {
										    set gMessage "PacketConfig procedure: SA is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set SA $val
											}
						 }


						-SAincrval {
										  if {[regexp {^[\d]+$} $val] == 0} {
										    set gMessage "PacketConfig procedure: SAincrval is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set SAincrval $val
											}
						 }

						-SAincrsteps {
										  if {[regexp {^[\d]+$} $val] == 0} {
										    set gMessage "PacketConfig procedure: SAincrsteps is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set SAincrsteps $val
											}
						 }

						 						
						-SAincridle {
										  if {[regexp {^[\d]+$} $val] == 0} {
										    set gMessage "PacketConfig procedure: SAincridle is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set SAincridle $val
											}
						 }

						-ethType {
										  if {[regexp {[0-9a-f]{4}} $val] == 0} {
										    set gMessage "PacketConfig procedure: ethType is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set ethType $val
											}
						 }

	      	 -vlanType {
											if {$packType != 2} {
										    set gMessage "PacketConfig procedure: vlanType is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {[regexp -nocase {onetagged|stacked} $val] == 0} {
											    set gMessage "PacketConfig procedure: vlanType is wrong must be onetagged/stacked"
	                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {$val == "onetagged"} {
											    set vlanType 1
											} else {
											    set vlanType 2
											}

					 }

	      	 -cvlanid {
											if {$packType != 2} {
										    set gMessage "PacketConfig procedure: cvlanid is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {$val < 1 || $val > 4094} {
											    set	gMessage "PacketConfig procedure: cvlanid = $val is wrong must be 1-4094"
	                        return [RLEH::Handle SAsyntax gMessage]
											} else {
											    set cvlanid $val
											}

					 }

	      	 -cvlanp  {
											if {$packType != 2} {
										    set gMessage "PacketConfig procedure: cvlanp  is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {$val < 0 || $val > 7} {
											    set gMessage "PacketConfig procedure: cvlanp  = $val is wrong must be 0-7"
	                        return [RLEH::Handle SAsyntax gMessage]
											} else {
											    set cvlanp  $val
											}

					 }

	      	 -cvlanincr {
											if {$packType != 2} {
										    set gMessage "PacketConfig procedure: cvlanincr is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {[regexp {^[\d]+$} $val] == 0} {
											    set	gMessage "PacketConfig procedure: cvlanincr = $val is wrong"
	                        return [RLEH::Handle SAsyntax gMessage]
											} else {
											    set cvlanincr $val
											}

					 }

	      	 -cvlanincrsteps {
											if {$packType != 2} {
										    set gMessage "PacketConfig procedure: cvlanincrsteps is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {[regexp {^[\d]+$} $val] == 0} {
											    set gMessage "PacketConfig procedure: cvlanincrsteps = $val is wrong"
	                        return [RLEH::Handle SAsyntax gMessage]
											} else {
											    set cvlanincrsteps $val
											}

					 }

	      	 -cvlanincridle {
											if {$packType != 2} {
										    set gMessage "PacketConfig procedure: cvlanincridle is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {[regexp {^[\d]+$} $val] == 0} {
											    set gMessage "PacketConfig procedure: cvlanincridle = $val is wrong"
	                        return [RLEH::Handle SAsyntax gMessage]
											} else {
											    set cvlanincridle $val
											}

					 }

	      	 -svlanid {
											if {$packType != 2} {
										    set gMessage "PacketConfig procedure: svlanid conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {$vlanType != 2} {
										    set gMessage "PacketConfig procedure: svlanid conflicted with vlan type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {$val < 1 || $val > 4094} {
											    set	gMessage "PacketConfig procedure: svlanid = $val is wrong must be 1-4094"
	                        return [RLEH::Handle SAsyntax gMessage]
											} else {
											    set svlanid $val
											}

					 }

	      	 -svlantype {
											if {$packType != 2} {
										    set gMessage "PacketConfig procedure: svlantype is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {$vlanType != 2} {
										    set gMessage "PacketConfig procedure: svlantype is conflicted with vlan type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {$val == "8100"} {
											    set svlantype 1
											} elseif {$val == "9100"} {
											    set svlantype 2
											} elseif {$val == "88A8"} {
											    set svlantype 3
											} else {
											    set gMessage "PacketConfig procedure: svlantype is wrong must be 8100/9100/88A8"
	                        return [RLEH::Handle SAsyntax gMessage]
											}

					 }

	      	 -svlanp {
											if {$packType != 2} {
										    set gMessage "PacketConfig procedure: svlanp is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {$vlanType != 2} {
										    set gMessage "PacketConfig procedure: svlanp is conflicted with vlan type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {$val < 0 || $val > 7} {
											    set gMessage "PacketConfig procedure: svlanp = $val is wrong must be 0-7"
	                        return [RLEH::Handle SAsyntax gMessage]
											} else {
											    set svlanp $val
											}

					 }

	      	 -svlanincr {
											if {$packType != 2} {
										    set gMessage "PacketConfig procedure: svlanincr is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {$vlanType != 2} {
										    set gMessage "PacketConfig procedure: svlanincr is conflicted with vlan type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {[regexp {^[\d]+$} $val] == 0} {
											    set gMessage "PacketConfig procedure: svlanincr = $val is wrong"
	                        return [RLEH::Handle SAsyntax gMessage]
											} else {
											    set svlanincr $val
											}

					 }

	      	 -svlanincrsteps {
											if {$packType != 2} {
										    set gMessage "PacketConfig procedure: svlanincrsteps is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {$vlanType != 2} {
										    set gMessage "PacketConfig procedure: svlanincrsteps is conflicted with vlan type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {[regexp {^[\d]+$} $val] == 0} {
											    set gMessage "PacketConfig procedure: svlanincrsteps = $val is wrong"
	                        return [RLEH::Handle SAsyntax gMessage]
											} else {
											    set svlanincrsteps $val
											}

					 }

	      	 -svlanincridle {
											if {$packType != 2} {
										    set gMessage "PacketConfig procedure: svlanincridle is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {$vlanType != 2} {
										    set gMessage "PacketConfig procedure: svlanincridle is conflicted with vlan type"
                        return [RLEH::Handle SAsyntax gMessage]
											} elseif {[regexp {^[\d]+$} $val] == 0} {
											    set gMessage "PacketConfig procedure: svlanincridle = $val is wrong"
	                        return [RLEH::Handle SAsyntax gMessage]
											} else {
											    set svlanincridle $val
											}

					 }

						-tos {
											if {$packType != 3} {
										    set gMessage "PacketConfig procedure: tos is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
										  } elseif {[regexp {^[\d]+$} $val] == 0} {
										    set gMessage "PacketConfig procedure: tos is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set tos $val
											}
						 }

						-ttl {
											if {$packType != 3} {
										    set gMessage "PacketConfig procedure: ttl is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
										  } elseif {[regexp {^[\d]+$} $val] == 0} {
										    set gMessage "PacketConfig procedure: ttl is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set ttl $val
											}
						 }

						-identif {
											if {$packType != 3} {
										    set gMessage "PacketConfig procedure: identif is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
										  } elseif {[regexp {^[\d]+$} $val] == 0} {
										    set gMessage "PacketConfig procedure: identif is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set identif $val
											}
						 }


						-protocol {
											if {$packType != 3} {
										    set gMessage "PacketConfig procedure: protocol is conflicted with Packet type"
                        return [RLEH::Handle SAsyntax gMessage]
										  } elseif {[regexp {^[\d]+$} $val] == 0} {
										    set gMessage "PacketConfig procedure: protocol is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set protocol $val
											}
						 }

						-destinip {
										  #if {[regexp $re $val] == 0} {}
						          if {[ChkIPValid $val]} {
										    set gMessage "PacketConfig procedure: destinip $val is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set destinip $val
											}
						 }

						-sourceip {
										  #if {[regexp $re $val] == 0} {}
						          if {[ChkIPValid $val]} {
										    set gMessage "PacketConfig procedure: sourceip $val is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set sourceip $val
											}
						 }

						-payload {
						          set len [string length $val]
						          if {[expr $len%2]} {
										    set gMessage "PacketConfig procedure: payload data is wrong(is ODD)"
                        return [RLEH::Handle SAsyntax gMessage]
											}
											set re "(\[0-9a-f\]{2}){[expr $len/2]}"
										  if {[regexp $re $val] == 0} {
										    set gMessage "PacketConfig procedure: payload data is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set payload $val
											}
						 }


             default {
                      set gMessage "PacketConfig procedure:   Wrong name of parameter $param"
                      return [RLEH::Handle SAsyntax gMessage]
             }
		}
	}

	set ret 0
	set ret [SendToEtxGen $ip_ID "\r" "ETX-204A-" 6]
	if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_ID)] || [string match "*ETX-204A-*\[AD\]C>*" $gEtxGenBuffer(id$ip_ID)]} {
		SendToEtxGen $ip_ID "ch\r\r" "Switch to CLI" 6
		set ret [expr [SendToEtxGen $ip_ID "\r\r" "Switch to CLI" 6] | $ret]
		DelayMs 20
		set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "PacketConfig procedure: Fail switch from CLI to Generator screen Etx204A($ip_ID)"
			return $fail
		}
		set vaEtxGenStatuses($ip_ID,currScreen) "Gen"
	} else {
			if {$vaEtxGenStatuses($ip_ID,currScreen) != "Gen"} {
			  set ret [SendToEtxGen $ip_ID "!" "Kernel Objects" 6]
		 	  DelayMs 20
			  set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
				if {$ret} {
					set vaEtxGenStatuses($ip_ID,currScreen) "na"
		      set gMessage "PacketConfig procedure: Fail while get Generator screen from main menu Etx204A($ip_ID)"
					return $fail
				}
				set vaEtxGenStatuses($ip_ID,currScreen) "Gen"
		  } else {
			    set ret [SendToEtxGen $ip_ID "\r" "Generator Factory" 6]
					if {$ret} {
						set vaEtxGenStatuses($ip_ID,currScreen) "na"
			      set gMessage "PacketConfig procedure: Fail while get Generator screen Etx204A($ip_ID)"
						return $fail
					}
			}
	}

  #updated updGen
  if {[info exists updGen]} {
    set ret [SendToEtxGen $ip_ID "1\r" "All" 6]
		DelayMs	 20
    set ret [expr [SendToEtxGen $ip_ID "$updGen\r" "Generator Factory" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "PacketConfig procedure: Fail while set generator number Etx204A($ip_ID)"
			return $fail
		}
		#puts $gEtxGenBuffer(id$ip_ID)
  }

  #updated packType
  set ret [SendToEtxGen $ip_ID "3\r" "RAW" 6]
	DelayMs	 20
  set ret [expr [SendToEtxGen $ip_ID "$packType\r" "Generator Factory" 6] | $ret]
	if {$ret} {
		set vaEtxGenStatuses($ip_ID,currScreen) "na"
    set gMessage "PacketConfig procedure: Fail while set packType Etx204A($ip_ID)"
		return $fail
	}
	#puts $gEtxGenBuffer(id$ip_ID)

	if {[info exists clrUdf]} {
		if {$vaEtxGenStatuses($ip_ID,currScreen) != "Basedasa"} {
	    set ret [SendToEtxGen $ip_ID "11\r" "UDF fields" 6]
		  DelayMs	 20
	  }
	  set ret [expr [SendToEtxGen $ip_ID "12\r" "UDF fields" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
	    set gMessage "PacketConfig procedure: Fail while set clrUdf Etx204A($ip_ID)"
			return $fail
		} else {
		    set vaEtxGenStatuses($ip_ID,currScreen) "Basedasa"
		}
		#puts $gEtxGenBuffer(id$ip_ID)
 }

################################################################################
#									  MAC Parameters
#
################################################################################

 foreach {item itemNumber} {DA 2 SA 3 DAincrval 5 DAincrsteps 7 DAincridle 6 SAincrval 8 SAincrsteps 10 SAincridle 9} {

	 if {[info exists $item]} {
		if {$vaEtxGenStatuses($ip_ID,currScreen) != "Basedasa"} {
	    set ret [SendToEtxGen $ip_ID "11\r" "UDF fields" 6]
		  DelayMs	 20
	  }
	  set ret [expr [SendToEtxGen $ip_ID "$itemNumber\r" "H" 6] | $ret]
		DelayMs	 20
	  set ret [expr [SendToEtxGen $ip_ID "[set $item]\r" "UDF fields" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
	    set gMessage "PacketConfig procedure: Fail while set $item Etx204A($ip_ID)"
			return $fail
		} else {
		    set vaEtxGenStatuses($ip_ID,currScreen) "Basedasa"
		}
		#puts $gEtxGenBuffer(id$ip_ID)
	 }
 }

 #update ethType
 if {[info exists ethType] && $packType == 1} {
	if {$vaEtxGenStatuses($ip_ID,currScreen) != "Basedasa"} {
    set ret [SendToEtxGen $ip_ID "11\r" "UDF fields" 6]
	  DelayMs	 20
  }
  set ret [expr [SendToEtxGen $ip_ID "4\r" "H" 6] | $ret]
	DelayMs	 20
  set ret [expr [SendToEtxGen $ip_ID "$ethType\r" "UDF fields" 6] | $ret]
	if {$ret} {
		set vaEtxGenStatuses($ip_ID,currScreen) "na"
    set gMessage "PacketConfig procedure: Fail while set ethType Etx204A($ip_ID)"
		return $fail
	} else {
	    set vaEtxGenStatuses($ip_ID,currScreen) "Basedasa"
	}
	#puts $gEtxGenBuffer(id$ip_ID)
 }

 if {[info exists payload] && $packType == 1} {
	if {$vaEtxGenStatuses($ip_ID,currScreen) != "Basedasa"} {
    set ret [SendToEtxGen $ip_ID "11\r" "UDF fields" 6]
	  DelayMs	 20
  }
  set ret [expr [SendToEtxGen $ip_ID "11\r" "H" 6] | $ret]
	DelayMs	 20
  set ret [expr [SendToEtxGen $ip_ID "$payload\r" "UDF fields" 6] | $ret]
	if {$ret} {
		set vaEtxGenStatuses($ip_ID,currScreen) "na"
    set gMessage "PacketConfig procedure: Fail while set payload Etx204A($ip_ID)"
		return $fail
	} else {
	    set vaEtxGenStatuses($ip_ID,currScreen) "Basedasa"
	}
	#puts $gEtxGenBuffer(id$ip_ID)
 }

 #here the screen may be or Gen or Basedasa 
 set ret [SendToEtxGen $ip_ID "\r" "Switch to CLI" 6]
 if {[string match "*Payload data*" $gEtxGenBuffer(id$ip_ID)]} {
    set ret [expr [SendToEtxGen $ip_ID "\33" "Generator Factory" 6] | $ret]
 }
################################################################################
#									  VLAN Parameters
#
################################################################################

 #update vlanType
 if {[info exists vlanType] && $packType == 2} {
 	if {$vaEtxGenStatuses($ip_ID,currScreen) != "Vlan"} {
    set ret [expr [SendToEtxGen $ip_ID "12\r" "C-Vlan incr idle" 6] | $ret]
 	  DelayMs	 20
  }
  set ret [expr [SendToEtxGen $ip_ID "\r" "C-Vlan incr idle" 6] | $ret]
	if {$vlanType == 1  && ![string match "*One tag*" $gEtxGenBuffer(id$ip_ID)]} {
    set ret [expr [SendToEtxGen $ip_ID "2\r" "C-Vlan incr idle" 6] | $ret]
	}
	if {$vlanType == 2  && ![string match "*Two tags*" $gEtxGenBuffer(id$ip_ID)]} {
    set ret [expr [SendToEtxGen $ip_ID "2\r" "C-Vlan incr idle" 6] | $ret]
	}
 	if {$ret} {
 		set vaEtxGenStatuses($ip_ID,currScreen) "na"
    set gMessage "PacketConfig procedure: Fail while set vlanType Etx204A($ip_ID)"
 		return $fail
 	} else {
 	    set vaEtxGenStatuses($ip_ID,currScreen) "Vlan"
 	}
 	#puts $gEtxGenBuffer(id$ip_ID)
 }

 #update svlantype
 if {[info exists svlantype]} {
 	if {$vaEtxGenStatuses($ip_ID,currScreen) != "Vlan"} {
    set ret [SendToEtxGen $ip_ID "12\r" "S-Vlan incr" 6]
 	  DelayMs	 20
  }
  set ret [expr [SendToEtxGen $ip_ID "9\r" "88a8" 6] | $ret]
  set ret [expr [SendToEtxGen $ip_ID "$svlantype\r" "S-Vlan incr" 6] | $ret]
 	if {$ret} {
 		set vaEtxGenStatuses($ip_ID,currScreen) "na"
    set gMessage "PacketConfig procedure: Fail while set svlantype Etx204A($ip_ID)"
 		return $fail
 	} else {
 	    set vaEtxGenStatuses($ip_ID,currScreen) "Vlan"
 	}
 	#puts $gEtxGenBuffer(id$ip_ID)
 }


 foreach {item itemNumber} {cvlanid 4 cvlanp 5 cvlanincr 6 cvlanincrsteps 7 cvlanincridle 8\
                            svlanid 10 svlanp 11 svlanincr 12 svlanincrsteps 13 svlanincridle 14} {

	 if {[info exists $item]} {
	 	if {$vaEtxGenStatuses($ip_ID,currScreen) != "Vlan"} {
	    set ret [SendToEtxGen $ip_ID "12\r" "C-Vlan incr idle" 6]
	 	  DelayMs	 20
	  }
	  set ret [expr [SendToEtxGen $ip_ID "$itemNumber\r" "H" 6] | $ret]
	 	DelayMs	 20
	  set ret [expr [SendToEtxGen $ip_ID "[set $item]\r" "C-Vlan incr idle" 6] | $ret]
	 	if {$ret} {
	 		set vaEtxGenStatuses($ip_ID,currScreen) "na"
	    set gMessage "PacketConfig procedure: Fail while set $item Etx204A($ip_ID)"
	 		return $fail
	 	} else {
	 	    set vaEtxGenStatuses($ip_ID,currScreen) "Vlan"
	 	}
	 	#puts $gEtxGenBuffer(id$ip_ID)
	 }
 }

 if {[info exists payload] && $packType == 2} {
	if {$vaEtxGenStatuses($ip_ID,currScreen) != "Vlan"} {
    set ret [SendToEtxGen $ip_ID "12\r" "C-Vlan incr idle" 6]
	  DelayMs	 20
  }
  set ret [SendToEtxGen $ip_ID "\r" "C-Vlan incr idle" 6]
	if {[string match "*S-Vlan*" $gEtxGenBuffer(id$ip_ID)]} {
    set ret [expr [SendToEtxGen $ip_ID "15\r" "H" 6] | $ret]
	} else {
      set ret [expr [SendToEtxGen $ip_ID "9\r" "H" 6] | $ret]
	}
	DelayMs	 20
  set ret [expr [SendToEtxGen $ip_ID "$payload\r" "Switch to CLI" 6] | $ret]
	if {$ret} {
		set vaEtxGenStatuses($ip_ID,currScreen) "na"
    set gMessage "PacketConfig procedure: Fail while set payload Etx204A($ip_ID)"
		return $fail
	} else {
	    set vaEtxGenStatuses($ip_ID,currScreen) "Vlan"
	}
	#puts $gEtxGenBuffer(id$ip_ID)
 }
 #update ethType
 if {[info exists ethType] && $packType == 2} {
	if {$vaEtxGenStatuses($ip_ID,currScreen) != "Vlan"} {
    set ret [SendToEtxGen $ip_ID "12\r" "C-Vlan incr idle" 6]
	  DelayMs	 20
  }
  set ret [expr [SendToEtxGen $ip_ID "3\r" "H" 6] | $ret]
	DelayMs	 20
  set ret [expr [SendToEtxGen $ip_ID "$ethType\r" "C-Vlan incr idle" 6] | $ret]
	if {$ret} {
		set vaEtxGenStatuses($ip_ID,currScreen) "na"
    set gMessage "PacketConfig procedure: Fail while set ethType Etx204A($ip_ID)"
		return $fail
	} else {
	    set vaEtxGenStatuses($ip_ID,currScreen) "Vlan"
	}
	#puts $gEtxGenBuffer(id$ip_ID)
 }


 #here the screen may be or Gen or Basedasa or Vlan
 SendToEtxGen $ip_ID "\r" "Switch to CLI" 1
 if {[string match "*VLAN type*" $gEtxGenBuffer(id$ip_ID)] || [string match "*Payload data*" $gEtxGenBuffer(id$ip_ID)]} {
    set ret [expr [SendToEtxGen $ip_ID "\33" "Generator Factory" 6] | $ret]
 }
################################################################################
#									  IP Parameters
#
################################################################################
 foreach {item itemNumber} {tos 2 ttl 3 identif 4 protocol 5 destinip 6 sourceip 7 } {

	 if {[info exists $item]} {
		 if {$vaEtxGenStatuses($ip_ID,currScreen) != "Ip"} {
	     set ret [SendToEtxGen $ip_ID "12\r" "Switch to CLI" 6]
		   DelayMs	 20
	   }
	   set ret [expr [SendToEtxGen $ip_ID "$itemNumber\r" "H" 6] | $ret]
		 DelayMs	 20
	   set ret [expr [SendToEtxGen $ip_ID "[set $item]\r" "Switch to CLI" 6] | $ret]
		 if {$ret} {
			 set vaEtxGenStatuses($ip_ID,currScreen) "na"
	     set gMessage "PacketConfig procedure: Fail while set $item Etx204A($ip_ID)"
			 return $fail
		 } else {
		     set vaEtxGenStatuses($ip_ID,currScreen) "Ip"
		 }
		#puts $gEtxGenBuffer(id$ip_ID)
	 }
 }

 if {[info exists payload] && $packType == 3} {
	if {$vaEtxGenStatuses($ip_ID,currScreen) != "Ip"} {
    set ret [SendToEtxGen $ip_ID "12\r" "Switch to CLI" 6]
	  DelayMs	 20
  }
  set ret [expr [SendToEtxGen $ip_ID "8\r" "H" 6] | $ret]
	DelayMs	 20
  set ret [expr [SendToEtxGen $ip_ID "$payload\r" "Switch to CLI" 6] | $ret]
	if {$ret} {
		set vaEtxGenStatuses($ip_ID,currScreen) "na"
    set gMessage "PacketConfig procedure: Fail while set payload Etx204A($ip_ID)"
		return $fail
	} else {
	    set vaEtxGenStatuses($ip_ID,currScreen) "Ip"
	}
	#puts $gEtxGenBuffer(id$ip_ID)
 }

 SendToEtxGen $ip_ID "S\r" "item"
 set vaEtxGenStatuses($ip_ID,currScreen) "na"
 return $ret
}

#*************************************************************************
#**                        RLEtxGen::RawPacketConfig
#** 
#**  Abstract: Configure Gen ports raw packet of Etx204A Generator by com or telnet
#**
#**   Inputs:
#**            ip_ID                   :	        ID of Etx204A Gen returned by Open procedure .
#**                              
#**                              
#**            args   parameters and their value:
#**                              
#**                              
#**  					 -updGen  	         :	      1-4/all.
#**                              
#**  					 -DA        	       :	      Destination MAC.
#**                              
#**  					 -SA        	       :	      Source MAC.
#**                              
#**  					 -field1     	       :	      Four bytes 13-16 of packet.
#**                              
#**  					 -field2     	       :	      Four bytes 17-20 of packet.
#**                              
#**  					 -field3     	       :	      Four bytes 21-24 of packet.
#**                              
#**  					 -field4     	       :	      Four bytes 25-28 of packet.
#**                              
#**  					 -field5     	       :	      Four bytes 29-32 of packet.
#**                              
#**  					 -field6     	       :	      Four bytes 33-36 of packet.
#**                              
#**  					 -field7     	       :	      Four bytes 37-40 of packet.
#**                              
#**  					 -field8     	       :	      Four bytes 41-44 of packet.
#**                              
#**  					 -udf         	     :	      1-6.
#**                              
#**  					 -clrUdf         	   :	      clear udf fields.
#**                              
#**  					 -offset         	   :	      0-43.
#**                              
#**  					 -width         	   :	      0/8/16/32 (if width == 0 , the udf doesn't affected).
#**                              
#**  					 -bvalue         	   :	      udf base value.
#**                              
#**  					 -incr         	     :	      udf increment value.
#**                              
#**  					 -steps         	   :	      udf steps number value.
#**                              
#**  					 -idle         	     :	      udf increment idle value.
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLEtxGen::RawPacketConfig 1 -updGen all -field1 445533 -field3  2120	-field7 11223344 -field8 11223344\
#**                              -udf 3 -offset 20 -width 16 -bvalue 554678 -incr 4 -steps 25 -idle 4
#***************************************************************************

proc RawPacketConfig {ip_ID args } {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0

  if {$ip_ID == "?"} {
    return "arguments options:  -updGen ,-DA, -SA -field1 , -field2,.... , -field8 ,-udf ,-width ,-offset ,-bvalue ,-incr ,-steps ,-idle"
  }

  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set gMessage "RawPacketConfig procedure: The EtxGen with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaEtxGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set gMessage "RawPacketConfig procedure: The plink process doesn't exist for EtxGen with ID=$ip_ID"
      return $fail
    }
  }


	#processing command line parameters
  foreach {param val}   $args   {
   
    switch -exact -- $param  {
    

						-updGen {
                      if {$val == "?"} {
                        return "updated port options:  1-4/all."
                      }

											if {[regexp -nocase {all} $val]} {
  											    set updGen 5
											} elseif {$val > 0 && $val < 5} {
  											  set updGen $val
											}	else {
                  		    set gMessage "RawPacketConfig procedure: The value $val of parameter $param wrong"
                          return [RLEH::Handle SAsyntax gMessage]
											}
											set vaEtxGenStatuses($ip_ID,updGen) $val

						 }

						-DA {
										  if {[regexp -nocase {([0-9a-f]{2}){6}} $val] == 0} {
										    set gMessage "RawPacketConfig procedure: DA is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set DA $val
											}
						 }

						-SA {
										  if {[regexp -nocase {([0-9a-f]{2}){6}} $val] == 0} {
										    set gMessage "RawPacketConfig procedure: SA is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set SA $val
											}
						 }

						-field1 -
						-field2 -
						-field3 -
						-field4 -
						-field5 -
						-field6 -
						-field7 -
						-field8 {
						          set len [string length $val]
						          if {[expr $len%2]} {
										    set gMessage "RawPacketConfig procedure: $param data is wrong(is ODD)"
                        return [RLEH::Handle SAsyntax gMessage]
											}
											set re "(\[0-9a-f\]{2}){[expr $len/2]}"
										  if {[regexp $re $val] == 0} {
										    set gMessage "RawPacketConfig procedure: $param data is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set [string trim $param -] $val
													#puts "$param  = $val"
											}

						 }

						-udf {
                      if {$val == "?"} {
                        return "udf options:  1-6"
                      }
										  if {$val < 1 || $val > 6} {
										    set gMessage "RawPacketConfig procedure: udf must be: 1-6"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set udf $val
											}
						 }

						-clrUdf {
                      if {$val == "?"} {
													set clrUdf $val
											}
						 }

						-width {
                      if {$val == "?"} {
                        return "width options:  0/8/16/32"
                      }
										  if {$val != 8 && $val != 16 && $val != 32 && $val != 0} {
										    set gMessage "RawPacketConfig procedure: width must be: 0/8/16/32"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } elseif {$val == 8} {
													set width 1
							     	  } elseif {$val == 16} {
													set width 2
							     	  } elseif {$val == 32} {
													set width 3
											} else {
													set width 4
											}
						 }


						-offset {
                      if {$val == "?"} {
                        return "offset options:  0-43"
                      }
										  if {$val < 0 || $val > 43} {
										    set gMessage "RawPacketConfig procedure: offset must be: 0-43"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set offset $val
											}
						 }

						-incr -
						-steps -
						-idle -
						-bvalue {
										  if {[regexp {^[\d]+$} $val] == 0} {
										    set gMessage "RawPacketConfig procedure: $param is wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set [string trim $param -] $val
													#puts "$param  = $val"
											}
						 }

             default {
                      set gMessage "RawPacketConfig procedure:   Wrong name of parameter $param"
                      return [RLEH::Handle SAsyntax gMessage]
             }
		 }
   }

	set ret 0
	set ret [SendToEtxGen $ip_ID "\r" "ETX-204A-" 6]
	if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_ID)] || [string match "*ETX-204A-*\[AD\]C>*" $gEtxGenBuffer(id$ip_ID)]} {
		SendToEtxGen $ip_ID "ch\r\r" "Switch to CLI" 6
		set ret [expr [SendToEtxGen $ip_ID "\r\r" "Switch to CLI" 6] | $ret]
		DelayMs 20
		set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "RawPacketConfig procedure: Fail switch from CLI to Generator screen Etx204A($ip_ID)"
			return $fail
		}
		set vaEtxGenStatuses($ip_ID,currScreen) "Gen"
	} else {
			if {$vaEtxGenStatuses($ip_ID,currScreen) != "Gen"} {
			  set ret [SendToEtxGen $ip_ID "!" "Kernel Objects" 6]
		 	  DelayMs 20
			  set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
				if {$ret} {
					set vaEtxGenStatuses($ip_ID,currScreen) "na"
		      set gMessage "RawPacketConfig procedure: Fail while get Generator screen from main menu Etx204A($ip_ID)"
					return $fail
				}
				set vaEtxGenStatuses($ip_ID,currScreen) "Gen"
		  } else {
			    set ret [SendToEtxGen $ip_ID "\r" "Generator Factory" 6]
					if {$ret} {
						set vaEtxGenStatuses($ip_ID,currScreen) "na"
			      set gMessage "RawPacketConfig procedure: Fail while get Generator screen Etx204A($ip_ID)"
						return $fail
					}
			}
	}

  #updated updGen
  if {[info exists updGen]} {
    set ret [SendToEtxGen $ip_ID "1\r" "All" 6]
		DelayMs	 20
    set ret [expr [SendToEtxGen $ip_ID "$updGen\r" "Generator Factory" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "RawPacketConfig procedure: Fail while set generator number Etx204A($ip_ID)"
			return $fail
		}
		#puts $gEtxGenBuffer(id$ip_ID)
  }

  #updated packType
  set ret [SendToEtxGen $ip_ID "3\r" "RAW" 6]
	DelayMs	 20
  set ret [expr [SendToEtxGen $ip_ID "4\r" "Generator Factory" 6] | $ret]
	if {$ret} {
		set vaEtxGenStatuses($ip_ID,currScreen) "na"
    set gMessage "RawPacketConfig procedure: Fail while set packType Etx204A($ip_ID)"
		return $fail
	}
	#puts $gEtxGenBuffer(id$ip_ID)

  foreach {item itemNumber} {DA 2 SA 3} {

	  if {[info exists $item]} {
		  if {$vaEtxGenStatuses($ip_ID,currScreen) != "Basedasa"} {
	      set ret [SendToEtxGen $ip_ID "11\r" "Switch to CLI" 6]
		    DelayMs	 20
	    }
	    set ret [expr [SendToEtxGen $ip_ID "$itemNumber\r" "H" 6] | $ret]
		  DelayMs	 20
	    set ret [expr [SendToEtxGen $ip_ID "[set $item]\r" "Switch to CLI" 6] | $ret]
		  if {$ret} {
			  set vaEtxGenStatuses($ip_ID,currScreen) "na"
	      set gMessage "RawPacketConfig procedure: Fail while set $item Etx204A($ip_ID)"
			  return $fail
		  } else {
		      set vaEtxGenStatuses($ip_ID,currScreen) "Basedasa"
		  }
		  #puts $gEtxGenBuffer(id$ip_ID)
	  }
  }

	if {$vaEtxGenStatuses($ip_ID,currScreen) == "Basedasa"} {
	  set ret [SendToEtxGen $ip_ID "\33" "Generator Factory" 6]
	  if {$ret} {
		  set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "RawPacketConfig procedure: Fail while send escape Etx204A($ip_ID)"
		  return $fail
		}
	}
	
	foreach {item} {field1 field2 field3 field4 field5 field6 field7 field8} {
	 if {[info exists $item]} {
		if {$vaEtxGenStatuses($ip_ID,currScreen) != "Raw"} {
	    set ret [SendToEtxGen $ip_ID "12\r" "Switch to CLI" 6]
		  DelayMs	 20
	  }
	  set ret [expr [SendToEtxGen $ip_ID "2\r" "41-44" 6] | $ret]
		DelayMs	 20
	  set ret [expr [SendToEtxGen $ip_ID "[string index $item end]\r" "Switch to CLI" 6] | $ret]
		DelayMs	 20
	  set ret [expr [SendToEtxGen $ip_ID "3\r" "H" 6] | $ret]
		DelayMs	 20
	  set ret [expr [SendToEtxGen $ip_ID "[set $item]\r" "Switch to CLI" 6] | $ret]
		DelayMs	 20
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
	    set gMessage "RawPacketConfig procedure: Fail while set $item Etx204A($ip_ID)"
			return $fail
		} else {
		    set vaEtxGenStatuses($ip_ID,currScreen) "Raw"
		}
		#puts $gEtxGenBuffer(id$ip_ID)
	 }

	}

	if {[info exists clrUdf]} {
		if {$vaEtxGenStatuses($ip_ID,currScreen) != "Raw"} {
	    set ret [SendToEtxGen $ip_ID "12\r" "Switch to CLI" 6]
		  DelayMs	 20
	  }
	  set ret [expr [SendToEtxGen $ip_ID "5\r" "UDF fields" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
	    set gMessage "RawPacketConfig procedure: Fail while set clrUdf Etx204A($ip_ID)"
			return $fail
		} else {
		    set vaEtxGenStatuses($ip_ID,currScreen) "Raw"
		}
		#puts $gEtxGenBuffer(id$ip_ID)
	}


  #updated udf
  if {[info exists udf]} {
		if {$vaEtxGenStatuses($ip_ID,currScreen) != "Raw"} {
	    set ret [SendToEtxGen $ip_ID "12\r" "Switch to CLI" 6]
		  DelayMs	 20
	  }
    set ret [SendToEtxGen $ip_ID "4\r" "Idle number" 6]
	  set ret [expr [SendToEtxGen $ip_ID "1\r" "UDF 6" 6] | $ret]
	  set ret [expr [SendToEtxGen $ip_ID "$udf\r" "Idle number" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "RawPacketConfig procedure: Fail while set UDF number $udf Etx204A($ip_ID)"
			return $fail
		}
		DelayMs	 20
    if {[info exists width]} {
	    set ret [expr [SendToEtxGen $ip_ID "3\r" "Width 32" 6] | $ret]
			DelayMs	 20
      set ret [expr [SendToEtxGen $ip_ID "$width\r" "Idle number" 6] | $ret]
			if {$ret} {
				set vaEtxGenStatuses($ip_ID,currScreen) "na"
	      set gMessage "RawPacketConfig procedure: Fail while set width of UDF$udf Etx204A($ip_ID)"
				return $fail
			}
		}
	  foreach {item itemNumber} {offset 2 bvalue 4 incr 5 steps 6 idle 7} {
	    if {[info exists $item]} {
			  #puts $item
			  set ret [SendToEtxGen $ip_ID "$itemNumber\r" "H" 6]
				DelayMs	 20
			  set ret [expr [SendToEtxGen $ip_ID "[set $item]\r" "Switch to CLI" 6] | $ret]
				DelayMs	 20
				if {$ret} {
					set vaEtxGenStatuses($ip_ID,currScreen) "na"
		      set gMessage "RawPacketConfig procedure: Fail while set $item of UDF$udf Etx204A($ip_ID)"
					return $fail
				}
		  }
		}

		#puts $gEtxGenBuffer(id$ip_ID)
  }
	SendToEtxGen $ip_ID "S\r" "item"
	SendToEtxGen $ip_ID "\33" 
	set vaEtxGenStatuses($ip_ID,currScreen) "na" ;#importance
  return $ret


}

#***************************************************************************
#**                        RLEtxGen::GetConfig
#** 
#**  Abstract: Gets Configuration of all Etx204A's generators
#**
#**   Inputs:
#**            ip_ID                   :	        ID of Etx204A returned by Open procedure .
#**                              
#**            op_results              :          Array of results.
#**                              
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLEtxGen::GetConfig 1  res
#***************************************************************************

proc GetConfig {ip_ID op_results} {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  variable      vaEtxGenCfg
  set gMessage ""                   
	set fail          -1
	set ok             0


  upvar $op_results  results
  catch {unset results}

  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set	gMessage "GetConfig procedure: The Etx204A with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaEtxGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "GetConfig procedure: The plink process doesn't exist for Etx204A with ID=$ip_ID"
      return $fail
    }
  }

	if {$vaEtxGenStatuses($ip_ID,package) == "RLSerial"} {
	  #RLSerial is problematic when current screen is refreshed statistics
		SendToEtxGen $ip_ID "\33" "menu" 1
		set vaEtxGenStatuses($ip_ID,currScreen) "na"
		DelayMs 20
	}
	set ret 0
	set ret [SendToEtxGen $ip_ID "\r" "ETX-204A-" 6]
	if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_ID)] || [string match "*ETX-204A-*\[AD\]C>*" $gEtxGenBuffer(id$ip_ID)]} {
		SendToEtxGen $ip_ID "ch\r\r" "Switch to CLI" 6
		set ret [expr [SendToEtxGen $ip_ID "\r\r" "Switch to CLI" 6] | $ret]
		DelayMs 10
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "GetConfig procedure: Fail switch from CLI to Main screen Etx204A($ip_ID)"
			return $fail
		}
		set vaEtxGenStatuses($ip_ID,currScreen) "Main"
	} else {
			if {$vaEtxGenStatuses($ip_ID,currScreen) != "Main"} {
			  set ret [SendToEtxGen $ip_ID "!" "Kernel Objects" 6]
		    DelayMs 20
			  set ret [expr [SendToEtxGen $ip_ID "\r" "Kernel Objects" 6] | $ret]
				if {$ret} {
					set vaEtxGenStatuses($ip_ID,currScreen) "na"
		      set gMessage "GetConfig procedure: Fail while get Main screen Etx204A($ip_ID)"
					return $fail
				}
				set vaEtxGenStatuses($ip_ID,currScreen) "Main"
		  } else {
			    set ret [SendToEtxGen $ip_ID "\r" "Current configured" 6]
					if {$ret} {
						set vaEtxGenStatuses($ip_ID,currScreen) "na"
			      set gMessage "GetConfig procedure: Fail while get Main screen Etx204A($ip_ID)"
						return $fail
					}
			}
	}

  if {![regexp {Host IP Address[\t\. ]+\(([\d\.]+)\)} $gEtxGenBuffer(id$ip_ID) match res]} {
  	set	gMessage "GetConfig procedure: Cann't get Host IP from Etx204A with ID=$ip_ID"
    return $fail
  } else {
      set results(id$ip_ID,hostIP) $res
  }

  if {![regexp {Run State  Run,Stop\][\t\. ]+\((Run|Stop+)\)} $gEtxGenBuffer(id$ip_ID) match res]} {
  	set	gMessage "GetConfig procedure: Cann't get Run/Stop state from Etx204A with ID=$ip_ID"
    return $fail
  } elseif {$res == "Run"} {
      set results(id$ip_ID,etxRun) 1
  } else {
      set results(id$ip_ID,etxRun) 0
	}
  set ret [SendToEtxGen $ip_ID "4\r" ">" 6]
  lappend tempbuffer $gEtxGenBuffer(id$ip_ID)
  DelayMs 50
  set ret [expr [SendToEtxGen $ip_ID "\004" ">" 6] | $ret]
  lappend tempbuffer $gEtxGenBuffer(id$ip_ID)
  DelayMs 50
  set ret [expr [SendToEtxGen $ip_ID "\004" ">" 6] | $ret]
  lappend tempbuffer $gEtxGenBuffer(id$ip_ID)
  set gEtxGenBuffer(id$ip_ID) $tempbuffer
	if {$ret} {
		set vaEtxGenStatuses($ip_ID,currScreen) "na"
    set gMessage "GetConfig procedure: Fail while get Current configuration screens Etx204A($ip_ID)"
		return $fail
	}



	foreach param {"AdminStatus" "Autonegotiat" "GeneratorMode" "PacketType" "PacketMinLen"\
                 "PacketMaxLen" "ChainLength" "PacketRate" "EthFrameType" "DA" "DA_incr" "DA_StationNum"} {

     if {![regexp "$param\[^\n\]+" $gEtxGenBuffer(id$ip_ID) match]} {
        set vaEtxGenStatuses($ip_ID,currScreen) "na"
      	set	gMessage "GetConfig procedure: Can't get parameter $param from Etx204A with ID=$ip_ID"
        return $fail
		 }
		 foreach {gener} {1 2 3 4} {
			 set results(id$ip_ID,$param,Gen$gener) [lindex $match $gener]
		 }
  }

	foreach param {"MaxAdvSpeed" "EthSpeed"} {

     if {![regexp "$param\[^\n\]+" $gEtxGenBuffer(id$ip_ID) match]} {
        set vaEtxGenStatuses($ip_ID,currScreen) "na"
      	set	gMessage "GetConfig procedure: Can't get parameter $param from Etx204A with ID=$ip_ID"
        return $fail
		 }
		 foreach {gener} {1 2 3 4} {
			 set results(id$ip_ID,$param,Gen$gener) [lindex $match $gener]
			 if {[string match -nocase "*10-tf*" $results(id$ip_ID,$param,Gen$gener)]} {
			   set results(id$ip_ID,$param,Gen$gener) "10-f"
			 } elseif {[string match -nocase "*100-tf*" $results(id$ip_ID,$param,Gen$gener)]} {
			     set results(id$ip_ID,$param,Gen$gener) "100-f"
			 } elseif {[string match -nocase "*1000-tf*" $results(id$ip_ID,$param,Gen$gener)]} {
			     set results(id$ip_ID,$param,Gen$gener) "1000-f"
			 } elseif {[string match -nocase "*1000-xf*" $results(id$ip_ID,$param,Gen$gener)]} {
			     set results(id$ip_ID,$param,Gen$gener) "1000-x"
			 } else {
	      	set	gMessage "GetConfig procedure: Wrong value of parameter $param Gen$gener from Etx204A with ID=$ip_ID"
	        return $fail
			 }
			 
		 }
  }

	foreach param {"DA_incrIdle" "SA" "SA_incr" "SA_StationNum" "SA_incrIdle" "VLAN_type" "C_VLANID"\
                 "C_VLANPbits" "C_VLANincr" "C_VLANincrNum" "C_VLANincrIdle" "S_VLANID" "S_VLANPbits" "S_VLANincr"} {

     if {![regexp "$param\[^\n\]+" $gEtxGenBuffer(id$ip_ID) match]} {
        set vaEtxGenStatuses($ip_ID,currScreen) "na"
      	set	gMessage "GetConfig procedure: Can't get parameter $param from Etx204A with ID=$ip_ID"
        return $fail
		 }
		 foreach {gener} {1 2 3 4} {
			 set results(id$ip_ID,$param,Gen$gener) [lindex $match $gener]
		 }
  }

	foreach param {"S_VLANincrNum" "S_VLANincrIdle" "IPtos" "IPttl" "IPidentific" "IPprotocol"\
                 "IPdestination" "IPsource" "Payload1" "Payload2" "Payload3" "Payload4" "Payload5"} {

     if {![regexp "$param\[^\n\]+" $gEtxGenBuffer(id$ip_ID) match]} {
        set vaEtxGenStatuses($ip_ID,currScreen) "na"
      	set	gMessage "GetConfig procedure: Can't get parameter $param from Etx204A with ID=$ip_ID"
        return $fail
		 }
		 foreach {gener} {1 2 3 4} {
			 set results(id$ip_ID,$param,Gen$gener) [lindex $match $gener]
		 }
  }
	set results(id$ip_ID,updGen) $vaEtxGenStatuses($ip_ID,updGen)

  set ret [expr [SendToEtxGen $ip_ID "\33" "Kernel Objects" 6] | $ret]
	DelayMs	 25
  set vaEtxGenStatuses($ip_ID,currScreen) "Main"
	if {$ret} {
    set vaEtxGenStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}


#***************************************************************************
#**                        RLEtxGen::GetStatistics
#** 
#**  Abstract: Gets Statistics of all Etx204A's generators
#**
#**   Inputs:
#**            ip_ID                   :	        ID of Etx204A returned by Open procedure .
#**                              
#**            op_results              :          Array of results.
#**                              
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLEtxGen::GetStatistics 1  res
#***************************************************************************

proc GetStatistics {ip_ID op_results} {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  variable      vaEtxGenCfg
  set gMessage ""                   
	set fail          -1
	set ok             0


  upvar $op_results  results
  catch {unset results}

  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set	gMessage "GetStatistics procedure: The Etx204A with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaEtxGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "GetStatistics procedure: The plink process doesn't exist for Etx204A with ID=$ip_ID"
      return $fail
    }
  }

	if {$vaEtxGenStatuses($ip_ID,package) == "RLSerial"} {
	  #RLSerial is problematic when current screen is refreshed statistics
		SendToEtxGen $ip_ID "\33" "menu" 1
		set vaEtxGenStatuses($ip_ID,currScreen) "na"
	}
	set ret 0
	set ret [SendToEtxGen $ip_ID "\r" "ETX-204A-" 6]
	if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_ID)] || [string match "*ETX-204A-*\[AD\]C>*" $gEtxGenBuffer(id$ip_ID)]} {
		SendToEtxGen $ip_ID "ch\r\r" "Switch to CLI" 6
		set ret [expr [SendToEtxGen $ip_ID "\r\r" "Switch to CLI" 6] | $ret]
		DelayMs 20
		set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
		DelayMs 20
		set ret [expr [SendToEtxGen $ip_ID "9\r" "RCV_BPS" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "GetStatistics procedure: Fail switch from CLI to Statistics screen Etx204A($ip_ID)"
			return $fail
		}
		set vaEtxGenStatuses($ip_ID,currScreen) "Statis"
	} else {
			if {$vaEtxGenStatuses($ip_ID,currScreen) != "Statis"} {
			  set ret [SendToEtxGen $ip_ID "!" "Kernel Objects" 6]
				DelayMs 20
				set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
				DelayMs 20
				set ret [expr [SendToEtxGen $ip_ID "9\r" "RCV_BPS" 6] | $ret]
				if {$ret} {
					set vaEtxGenStatuses($ip_ID,currScreen) "na"
		      set gMessage "GetStatistics procedure: Fail while get Statistics screen(from Main) Etx204A($ip_ID)"
					return $fail
				}
				set vaEtxGenStatuses($ip_ID,currScreen) "Statis"
		  } else {
			    set ret [SendToEtxGen $ip_ID "\r" "RCV_BPS" 6]
					if {$ret} {
						set vaEtxGenStatuses($ip_ID,currScreen) "na"
			      set gMessage "GetStatistics procedure: Fail while get Statistics screen Etx204A($ip_ID)"
						return $fail
					}
			}
	}


	foreach param {"PRBS_OK" "PRBS_ERR" "FRAME_ERR" "FRAME_NOT_RECOGN" "SEQ_ERR" "ERR_CNT"\
                 "LINK_STATE" "SPEED" "TIME" "RCV_PPS" "RCV_BPS"} {

     if {![regexp "$param\[^\n\]+" $gEtxGenBuffer(id$ip_ID) match]} {
        set vaEtxGenStatuses($ip_ID,currScreen) "na"
      	set	gMessage "GetStatistics procedure: Can't get parameter $param from Etx204A with ID=$ip_ID"
        return $fail
		 }
		 foreach {gener} {1 2 3 4} {
			 set results(id$ip_ID,$param,Gen$gener) [lindex $match $gener]
		 }
  }

  return $ret
}


#***************************************************************************
#**                        RLEtxGen::Start
#** 
#**  Abstract: Start Etx generators.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Etx204A returned by Open procedure .
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLEtxGen::Start 1  
#***************************************************************************

proc Start {ip_ID} {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set	gMessage "Start procedure: The Etx204A with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaEtxGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "Start procedure: The plink process doesn't exist for Etx204A with ID=$ip_ID"
      return $fail
    }
  }

	set ret 0
	set ret [SendToEtxGen $ip_ID "\r" "ETX-204A-" 6]
	if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_ID)] || [string match "*ETX-204A-*\[AD\]C>*" $gEtxGenBuffer(id$ip_ID)]} {
		SendToEtxGen $ip_ID "ch\r\r" "Switch to CLI" 6
		set ret [expr [SendToEtxGen $ip_ID "\r\r" "Switch to CLI" 6] | $ret]
		DelayMs 20
		set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "Start procedure: Fail switch from CLI to Generator screen Etx204A($ip_ID)"
			return $fail
		}
		set vaEtxGenStatuses($ip_ID,currScreen) "Gen"
	} else {
			if {$vaEtxGenStatuses($ip_ID,currScreen) != "Gen"} {
			  set ret [SendToEtxGen $ip_ID "!" "Kernel Objects" 6]
		 	  DelayMs 20
			  set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
				if {$ret} {
					set vaEtxGenStatuses($ip_ID,currScreen) "na"
		      set gMessage "Start procedure: Fail while get Generator screen from main menu Etx204A($ip_ID)"
					return $fail
				}
				set vaEtxGenStatuses($ip_ID,currScreen) "Gen"
		  } else {
			    set ret [SendToEtxGen $ip_ID "\r" "Generator Factory" 6]
					if {$ret} {
						set vaEtxGenStatuses($ip_ID,currScreen) "na"
			      set gMessage "Start procedure: Fail while get Generator screen Etx204A($ip_ID)"
						return $fail
					}
			}
	}

  if {[string match "*(Stop)*" $gEtxGenBuffer(id$ip_ID)]} {
    set ret [expr [SendToEtxGen $ip_ID "10\r" "Generator Factory" 6] | $ret]
  }
	if {$ret} {
    set vaEtxGenStatuses($ip_ID,currScreen) "na"
	}
  set  vaEtxGenStatuses($ip_ID,etxRun) 1

  return $ret
}


#***************************************************************************
#**                        RLEtxGen::Stop
#** 
#**  Abstract: Stop Etx generators.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Etx204A returned by Open procedure .
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLEtxGen::Stop 1  
#***************************************************************************

proc Stop {ip_ID} {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set	gMessage "Stop procedure: The Etx204A with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaEtxGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "Stop procedure: The plink process doesn't exist for Etx204A with ID=$ip_ID"
      return $fail
    }
  }

	set ret 0
	set ret [SendToEtxGen $ip_ID "\r" "ETX-204A-" 6]
	if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_ID)] || [string match "*ETX-204A-*\[AD\]C>*" $gEtxGenBuffer(id$ip_ID)]} {
		SendToEtxGen $ip_ID "ch\r\r" "Switch to CLI" 6
		set ret [expr [SendToEtxGen $ip_ID "\r\r" "Switch to CLI" 6] | $ret]
		DelayMs 20
		set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "Stop procedure: Fail switch from CLI to Generator screen Etx204A($ip_ID)"
			return $fail
		}
		set vaEtxGenStatuses($ip_ID,currScreen) "Gen"
	} else {
			if {$vaEtxGenStatuses($ip_ID,currScreen) != "Gen"} {
			  set ret [SendToEtxGen $ip_ID "!" "Kernel Objects" 6]
		 	  DelayMs 20
			  set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
				if {$ret} {
					set vaEtxGenStatuses($ip_ID,currScreen) "na"
		      set gMessage "Stop procedure: Fail while get Generator screen from main menu Etx204A($ip_ID)"
					return $fail
				}
				set vaEtxGenStatuses($ip_ID,currScreen) "Gen"
		  } else {
			    set ret [SendToEtxGen $ip_ID "\r" "Generator Factory" 6]
					if {$ret} {
						set vaEtxGenStatuses($ip_ID,currScreen) "na"
			      set gMessage "Stop procedure: Fail while get Generator screen Etx204A($ip_ID)"
						return $fail
					}
			}
	}

  if {[string match "*(Run)*" $gEtxGenBuffer(id$ip_ID)]} {
    set ret [expr [SendToEtxGen $ip_ID "10\r" "Generator Factory" 6] | $ret]
  }
	if {$ret} {
    set vaEtxGenStatuses($ip_ID,currScreen) "na"
	}
  set  vaEtxGenStatuses($ip_ID,etxRun) 0
	set RLEtxGen::vaEtxGenSet(id$ip_ID,start) 0

  return $ret
}


#***************************************************************************
#**                        RLEtxGen::Clear
#** 
#**  Abstract: Clear  errors.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Etx204A returned by Open procedure .
#**            [ip_port]               :         ports will be cleared
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLEtxGen::Clear 1   
#**	 RLEtxGen::Clear 1 4  
#***************************************************************************

proc Clear {ip_ID {ip_port ""}} {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set	gMessage "Clear procedure: The Etx204A with ID=$ip_ID doesn't opened"
    return $fail
  }

  if {$vaEtxGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "Clear procedure: The plink process doesn't exist for Etx204A with ID=$ip_ID"
      return $fail
    }
  }

	set ret 0
	set ret [SendToEtxGen $ip_ID "\r" "ETX-204A-" 6]
	if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_ID)] || [string match "*ETX-204A-*\[AD\]C>*" $gEtxGenBuffer(id$ip_ID)]} {
		SendToEtxGen $ip_ID "ch\r\r" "Switch to CLI" 6
		set ret [expr [SendToEtxGen $ip_ID "\r\r" "Switch to CLI" 6] | $ret]
		DelayMs 20
		set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
		if {$ret} {
			set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set gMessage "Clear procedure: Fail switch from CLI to Generator screen Etx204A($ip_ID)"
			return $fail
		}
		set vaEtxGenStatuses($ip_ID,currScreen) "Gen"
	} else {
			if {$vaEtxGenStatuses($ip_ID,currScreen) != "Gen" && $vaEtxGenStatuses($ip_ID,currScreen) != "Statis"} {
			  set ret [SendToEtxGen $ip_ID "!" "Kernel Objects" 6]
		 	  DelayMs 20
			  set ret [expr [SendToEtxGen $ip_ID "3\r" "Generator Factory" 6] | $ret]
				if {$ret} {
					set vaEtxGenStatuses($ip_ID,currScreen) "na"
		      set gMessage "Clear procedure: Fail while get Generator screen from main menu Etx204A($ip_ID)"
					return $fail
				}
				set vaEtxGenStatuses($ip_ID,currScreen) "Gen"
		  }
	}

	if {$ip_port != ""} {
    set ret [expr [SendToEtxGen $ip_ID "F\r" "menu" 6] | $ret]
		DelayMs	 20
    if {$ret} {
      set vaEtxGenStatuses($ip_ID,currScreen) "na"
      set	gMessage "Clear procedure: Fail while clear port: $ip_port Etx204A($ip_ID)"
      return $fail
    }
	} else {
      set ret [expr [SendToEtxGen $ip_ID "C" "menu" 6] | $ret]
	}
	if {$ret} {
    set vaEtxGenStatuses($ip_ID,currScreen) "na"
    set	gMessage "Clear procedure: Fail while clear statistics Etx204A($ip_ID)"
    return $fail
	}
  Delay 1
  return $ret
}

#***************************************************************************
#**                        RLEtxGen::ChkConnect
#** 
#**  Abstract: Checks the connection to Etx204A.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Etx204A returned by Open procedure .
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLEtxGen::ChkConnect 1   
#***************************************************************************

proc ChkConnect {ip_ID } {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  variable      vaEtxGenCfg
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set	gMessage "ChkConnect procedure: The Etx204A with ID=$ip_ID doesn't opened"
    return $fail
  }

  if {$vaEtxGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "ChkConnect procedure: The plink process doesn't exist for Etx204A with ID=$ip_ID"
      return $fail
    }
  }

  for {set i 1} {$i <= 2} {incr i} {
    set ret [SendToEtxGen $ip_ID "\r" "ETX-204A-" 2]
    if {!$ret} {
      break
    }
  }
  if {$ret} {
    set gMessage "ChkConnect procedure: Etx204A with id=$ip_ID isn't connected to Host.\nIt's recommended after CHASSIS RESET or POWER OFF disconnect and again connect the chassis in resources pane."
    set vaEtxGenStatuses($ip_ID,currScreen) "na"
    return $fail
	} else {
			if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_ID)] || [string match "*ETX-204A-*\[AD\]C>*" $gEtxGenBuffer(id$ip_ID)]} {
        set vaEtxGenStatuses($ip_ID,currScreen) "Cli"
			} elseif {[string match "*Kernel Objects*" $gEtxGenBuffer(id$ip_ID)]} {
          set vaEtxGenStatuses($ip_ID,currScreen) "Main"
			}

	}
  return $ret
}


#***************************************************************************
#**                        RLEtxGen::GoToMain
#** 
#**  Abstract: Go to Main menu or to Cli  of Etx204A.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Etx204A returned by Open procedure .
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLEtxGen::GoToMain 1   
#***************************************************************************

proc GoToMain {ip_ID } {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  variable      vaEtxGenCfg
  set gMessage ""                   
	set fail          -1
	set ok             0

  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set	gMessage "GoToMain procedure: The Etx204A with ID=$ip_ID doesn't opened"
    return $fail
  }

  if {$vaEtxGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "GoToMain procedure: The plink process doesn't exist for Etx204A with ID=$ip_ID"
      return $fail
    }
  }

  set ret [SendToEtxGen $ip_ID "\r\r" "ETX-204A-" 4]
	if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_ID)] || [string match "*ETX-204A-*\[AD\]C>*" $gEtxGenBuffer(id$ip_ID)]} {
		if {!$ret} {
      set vaEtxGenStatuses($ip_ID,currScreen) "Cli"
		}
	} elseif {[string match "*menu*" $gEtxGenBuffer(id$ip_ID)]} {
      SendToEtxGen $ip_ID "!" "Kernel Objects" 4
      set ret [expr [SendToEtxGen $ip_ID "!" "Kernel Objects" 4] | $ret]
			if {!$ret} {
        set vaEtxGenStatuses($ip_ID,currScreen) "Main"
			}
	} else {
  	  set	gMessage "GoToMain procedure: Can't recognize screen of  Etx204A with ID=$ip_ID"
      return $fail
	}
  return $ret
}


#*******************************************************************************
#**                        RLEtxGen::Close
#** 
#**  Abstract: Close Etx204A.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Etx204A returned by Open procedure .
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLEtxGen::Close 1   
#******************************************************************************

proc Close {ip_ID} {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set	gMessage "Close procedure: The Etx204A with ID=$ip_ID doesn't opened"
    return $fail
  }

  switch -exact -- $vaEtxGenStatuses($ip_ID,connection)  {
    

			com {
          if {$vaEtxGenStatuses($ip_ID,package) == "RLCom"} {
            RLCom::Close $vaEtxGenStatuses($ip_ID,EtxGenHandle)
          } else {
              RLSerial::Close $vaEtxGenStatuses($ip_ID,EtxGenHandle)
          }
      }

			telnet {
        if {$vaEtxGenStatuses($ip_ID,package) == "RLTcp"} {
           RLTcp::TelnetClose  $vaEtxGenStatuses($ip_ID,EtxGenHandle)
        } elseif {$vaEtxGenStatuses($ip_ID,package) == "RLPlink"} {
				    RLPlink::Close $vaEtxGenStatuses($ip_ID,EtxGenHandle)
        }
      }
  }

  unset vaEtxGenStatuses($ip_ID,EtxGenID)
  unset vaEtxGenStatuses($ip_ID,EtxGenHandle)
  unset vaEtxGenStatuses($ip_ID,connection)
  unset vaEtxGenStatuses($ip_ID,package)

  return $ok
}


#***************************************************************************
#**                        RLEtxGen::CloseAll
#** 
#**  Abstract: Close all Etx204A.
#**
#**   Inputs:
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLEtxGen::CloseAll  
#***************************************************************************

proc CloseAll {} {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0

	for {set i 1} {$i <= $vOpenedEtxGenHistoryCounter} {incr i} {
		if {[info exists vaEtxGenStatuses($i,EtxGenID)]} {
		  RLEtxGen::Close $vaEtxGenStatuses($i,EtxGenID)
		}
	}
  set  vOpenedEtxGenHistoryCounter 0
}


#***************************************************************************
#**                        RLEtxGen::ShowGui
#** 
#**  Abstract: Show Gui of generator.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of EGate-100 returned by Open procedure will be into resource entry in select mode.
#**                              
#**            args   parameters and their value:
#**
#**                -idlist                       IDs of others EGate-100 returned by Open procedure will be into resource entry.
#**								 -showHide										 SHOW/HIDE/ICONIFY
#**								 -closeChassis								 yes/no close chassis while destroy
#**
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLEtxGen::ShowGui 1 -idlist "2 3" -showHide	SHOW	-closeChassis no
#***************************************************************************

proc ShowGui {ip_ID args} {

  global        gEtxGenBuffer
  global        gMessage
  variable      vaEtxGenStatuses 
  variable      vaEtxGenGui
  variable      vaEtxGenSet
  variable      vaEtxGenCfg

	set	showHide	 0
	set statistics 4
	set base       .topEtxGenGui
	set fail -1

  if {$ip_ID == "?"} {
    return "arguments options:  -idlist , -showHide"
  }

  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set	gMessage "ShowGui procedure: The Egate-100 with ID=$ip_ID doesn't opened"
		tk_messageBox -icon error -type ok -message $gMessage -title "Etx204A Generator"
    return $fail
    #return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaEtxGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "ShowGui procedure: The plink process doesn't exist for Etx204A Generator with ID=$ip_ID"
      return $fail
    }
  }

	#processing command line parameters
  foreach {param val}   $args   {
   
    switch -exact -- $param  {

		        -showHide {
		              if {$val == "SHOW"} {
		                set showHide 1
		              } elseif {$val == "HIDE"} {
		                  set showHide	0
		              } elseif {$val == "ICONIFY"} {
		                  set showHide	2
		              }	else {
		                  set showHide 1
									}
		        }

    
						-idlist {
                      if {$val == "?"} {
                        return "list ID options:  e.g. {1 5 8}"
                      }
                   	  foreach ind $val {
												if {[catch {expr int($ind)}]} {
	                		    set	gMessage "ShowGui procedure: The list  $val of parameter $param isn't list of integers"
										  		tk_messageBox -icon error -type ok -message $gMessage -title "Etx204A Generator"
										      return $fail
	                       # return [RLEH::Handle SAsyntax gMessage]
												}
											  if {![info exists vaEtxGenStatuses($ind,EtxGenID)]} {
											  	set	gMessage "ShowGui procedure: The Etx204A Generator with ID=$ind of idlist: $val doesn't opened"
										  		tk_messageBox -icon error -type ok -message $gMessage -title "Etx204A Generator"
										      return $fail
											    #return [RLEH::Handle SAsyntax gMessage]
											  }
											}
											set idlist $val
						 }


						 -closeChassis {
                      if {$val == "?"} {
                        return "-closeChassis options:  yes , no"
                      }
                      if {$val == "yes"} {
                		    set	closeChassis	1
                      } elseif {$val == "no"} {
                		      set	closeChassis	0
							     	  } else {
	                		    set	gMessage "ShowGui procedure: The  value $val of parameter $param wrong"
	                        return [RLEH::Handle SAsyntax gMessage]
											}
						 }

             default {
                      set gMessage "ShowGui procedure:   Wrong name of parameter $param"
                      return [RLEH::Handle SAsyntax gMessage]
             }
		}
	}
	if {$showHide== 0} {
	  if [winfo exists $base] {
			  destroy $base
		} 
		return {}
	}	
	if [winfo exists $base] return


  RLEtxGen::MakeEtxGenGui
  RLEtxGen::OkConnChassis $vaEtxGenStatuses($ip_ID,EtxGenHandle) $vaEtxGenStatuses($ip_ID,package) $ip_ID

	if {[info exists idlist]} {
	  foreach chass $idlist {
      RLEtxGen::OkConnChassis $vaEtxGenStatuses($chass,EtxGenHandle) $vaEtxGenStatuses($chass,package) $chass
      #$vaEtxGenGui(resources,list) insert end  chassis:$chass -text  "chassis $chass" -fill red -indent 10 -font {times 14}
		}
	}
	#$vaEtxGenGui(notebook) raise [$vaEtxGenGui(notebook) page statistics]

	if {[info exists closeChassis]} {
	  set vaEtxGenSet(closeByDestroy) $closeChassis
	}

}

#***************************************************************************
#***************************************************************************
#
#                  INTERNAL FUNCTIONs
#
#***************************************************************************
#***************************************************************************

#***************************************************************************
#**                        OpenEtxGen
#** 
#**  Abstract: The internal procedure Open the EGate-100 by com or telnet
#**            Check if it is ready to be activate
#**
#**   Inputs:
#**            ip_address           :	        Com number or IP address.
#**                              
#**  					 ip_connection        :	        com/telnet.
#**                              
#**  					 ip_package           :	        RLCom/RLSerial/RLTcp/RLPlink.
#**                              
#**            ip_place             :         location into vaEtxGenStatuses array
#**                              
#**   Outputs: 
#**            0                    :         If success. 
#**            Negativ error cod    :         Otherwise.     
#***************************************************************************
proc OpenEtxGen {ip_address ip_connection ip_package ip_place} {

  global        gMessage
  global        gEtxGenBuffer
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
  set gMessage ""                   

	set fail          -1
	set ok             0

  switch -exact -- $ip_connection  {
    

			com {
            package require $ip_package
            if {$ip_package == "RLCom"} {
						  if [catch {RLCom::Open $ip_address 115200 8 NONE 1 } msg] {
						    set gMessage "OpenEtxGen:  Cann't open com by RLCom: $msg"
						    return $fail
							}
            } else {
                if {[RLSerial::Open $ip_address 115200 n 8 1]} {
							    set gMessage "OpenEtxGen:  Cann't open com$ip_address by RLSerial"
							    return $fail
								}
            }
            set  vaEtxGenStatuses($ip_place,EtxGenHandle) $ip_address

      }

			telnet {
        package require $ip_package
        if {$ip_package == "RLTcp"} {
            set handle [RLTcp::TelnetOpen $ip_address]
        } else {
            set handle [RLPlink::Open $ip_address -protocol telnet]
        }
        set  vaEtxGenStatuses($ip_place,EtxGenHandle) $handle

      }
  }

	set ret 0
  SendToEtxGen $ip_place "ns\33" "menu" 1 
  for {set i 1} {$i <= 3} {incr i} {
    set ret [SendToEtxGen $ip_place "\r" "ETX-204A-" 2]
				#puts 1_$ret
    DelayMs 200
    if {!$ret} {
			if {[string match "*ETX-204A-*\[AD\]C#*" $gEtxGenBuffer(id$ip_place)] || [string match "*ETX-204A-*\[AD\]C>*" $gEtxGenBuffer(id$ip_place)]} {
        set ret [expr [SendToEtxGen $ip_place "ch\r" "Kernel Objects" 1] | $ret]
				#puts 2
			} elseif {[string match "*menu*" $gEtxGenBuffer(id$ip_place)]} {
				#puts 3
          set ret [expr [SendToEtxGen $ip_place "!" "Kernel Objects" 2] | $ret]
			}
    }
    if {!$ret} {
		  break
		}
  }
  if {$ret} {
    switch -exact -- $ip_connection  {
      
  
  			com {
            if {$ip_package == "RLCom"} {
              RLCom::Close $ip_address
            } else {
                RLSerial::Close $ip_address
            }
        }
  
  			telnet {
          if {$ip_package == "RLTcp"} {
             RLTcp::TelnetClose  $handle
          } elseif {$ip_package == "RLPlink" } {
              RLPlink::Close $handle
          }
        }
    }
    set vaEtxGenStatuses($ip_place,currScreen) "na"
    set gMessage "OpenEtxGen:  Can't connect to ETX204A($ip_place) device"
    return $fail
  }
  set ret [expr [SendToEtxGen $ip_place "3\r" "Generator Factory" 6] | $ret]
  if {[string match "*(Stop)*" $gEtxGenBuffer(id$ip_place)]} {
    set  vaEtxGenStatuses($ip_place,etxRun) 0
  } elseif {[string match "*(Run)*" $gEtxGenBuffer(id$ip_place)]} {
      set  vaEtxGenStatuses($ip_place,etxRun) 1
  } else {
      set vaEtxGenStatuses($ip_place,currScreen) "na"
      set gMessage "OpenEtxGen:  Can't recognize ETX204A($ip_place) generator running state"
	    switch -exact -- $ip_connection  {
	      
	  
	  			com {
	            if {$ip_package == "RLCom"} {
	              RLCom::Close $ip_address
	            } else {
	                RLSerial::Close $ip_address
	            }
	        }
	  
	  			telnet {
	          if {$ip_package == "RLTcp"} {
	             RLTcp::TelnetClose  $handle
	          } elseif {$ip_package == "RLPlink" } {
	              RLPlink::Close $handle
	          }
	        }
	    }
      return $fail
  }
  set ret [SendToEtxGen $ip_place "1\r" "All" 6] 
  DelayMs 20
  set ret [expr [SendToEtxGen $ip_place "5\r" "Generator Factory" 6] | $ret]
  DelayMs 20
	#disable refresh statistics
	SendToEtxGen $ip_place "Q\r" "Generator Factory" 3
  DelayMs 20
  set ret [expr [SendToEtxGen $ip_place "S" "Generator Factory" 6] | $ret]

	if {$ret} {
    set vaEtxGenStatuses($ip_place,currScreen) "na"
    set gMessage "OpenEtxGen:  Fail while define port number ETX204A($ip_place)"
	} else {
      set vaEtxGenStatuses($ip_place,currScreen) "Gen"
      set vaEtxGenStatuses($ip_place,updGen) "All"
	}
  return $ret
}




#***************************************************************************
#**                        SendToEtxGen
#** 
#**  Abstract: The internal procedure send string to ETX204A by com or telnet
#**
#**   Inputs:
#**            ip_ID                :	        ID of ETX204A.
#**                              
#**  					 ip_sended            :	        sended string.
#**                              
#**  					 ip_expected          :	        expected string.
#**                              
#**  					 ip_timeout           :	        time out for waiting expected string.
#**                              
#**                              
#**   Outputs: 
#**            0                    :         If success. 
#**            Negativ error cod    :         Otherwise.     
#***************************************************************************

proc SendToEtxGen {ip_ID ip_sended {ip_expected stamstam} {ip_timeout 10}} {

  global        gMessage gEtxGenBuffer gEtxGenBufferDebug telnetBuffer$ip_ID
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
	set fail          -1
	set ok             0

  if {$gEtxGenBufferDebug} {
    puts "\n---- SendToEtxGen -------\nSended to EtxGen ID $ip_ID : $ip_sended" 
  }
  update

  switch -exact -- $vaEtxGenStatuses($ip_ID,connection)  {
    

			com {

           switch -exact -- $vaEtxGenStatuses($ip_ID,package) {

             RLCom {
                     if {$ip_expected=="stamstam" } {
                        RLCom::SendSlow $vaEtxGenStatuses($ip_ID,EtxGenHandle) $ip_sended 30
                        set ret 0
                     } else {
                         set ret [RLCom::SendSlow $vaEtxGenStatuses($ip_ID,EtxGenHandle) $ip_sended 30 gEtxGenBuffer(id$ip_ID) $ip_expected $ip_timeout]
                         if {$ret} {
                           set gMessage "SendToEtxGen procedure:   Return cod = $ret while (RLCom::SendSlow $vaEtxGenStatuses($ip_ID,EtxGenHandle) $ip_sended 30 gEtxGenBuffer(id$ip_ID) $ip_expected $ip_timeout)"
                         }
                     }
             }

             RLSerial {
                     if {$ip_expected=="stamstam" } {
                        RLSerial::SendSlow $vaEtxGenStatuses($ip_ID,EtxGenHandle) $ip_sended 30
                        set ret 0
                     } else {
                         set ret [RLSerial::SendSlow $vaEtxGenStatuses($ip_ID,EtxGenHandle) $ip_sended 30 gEtxGenBuffer(id$ip_ID) $ip_expected $ip_timeout]
                         if {$ret} {
                           set gMessage "SendToEtxGen procedure:   Return cod = $ret while (RLSerial::SendSlow $vaEtxGenStatuses($ip_ID,EtxGenHandle) $ip_sended 30 gEtxGenBuffer(id$ip_ID) $ip_expected $ip_timeout)"
                         }
                     }
             }
           }
      }

			telnet {

           switch -exact -- $vaEtxGenStatuses($ip_ID,package) {
             																																					  
             RLTcp {
                     set len [string length $ip_sended]
                     for {set ind 0} {$ind < $len} {incr ind} {
                       RLTcp::Send $vaEtxGenStatuses($ip_ID,EtxGenHandle) [string index $ip_sended $ind]
                       DelayMs 30
                     }
                     set ret 0
                     if {$ip_expected != "stamstam" } {
                       DelayMs 300
                       set ret [RLTcp::Waitfor  $vaEtxGenStatuses($ip_ID,EtxGenHandle)  $ip_expected  telnetBuffer$ip_ID  $ip_timeout]
                       set gEtxGenBuffer(id$ip_ID) [set telnetBuffer$ip_ID]
                       if {$ret} {
                         set gMessage "SendToEtxGen procedure:   Return cod = $ret while (RLTcp::Waitfor $vaEtxGenStatuses($ip_ID,EtxGenHandle) $ip_expected  gEtxGenBuffer(id$ip_ID)  $ip_timeout)"
                       }
                     }

             }
             RLPlink {

                     if {$ip_expected=="stamstam" } {
                        RLPlink::SendSlow $vaEtxGenStatuses($ip_ID,EtxGenHandle) $ip_sended 30
                        set ret 0
                     } else {
                         set ret [RLPlink::SendSlow $vaEtxGenStatuses($ip_ID,EtxGenHandle) $ip_sended 30 gEtxGenBuffer(id$ip_ID) $ip_expected $ip_timeout]
                         if {$ret} {
                           set gMessage "SendToEtxGen procedure:   Return cod = $ret while (RLPlink::SendSlow $vaEtxGenStatuses($ip_ID,EtxGenHandle) $ip_sended 30 gEtxGenBuffer(id$ip_ID) $ip_expected $ip_timeout)"
                         }
                     }


             }

           }
      }
  }
  FilterBuffer $ip_ID
  if {$gEtxGenBufferDebug} {
    puts "Expected : $ip_expected .  Received : \n$gEtxGenBuffer(id$ip_ID)\n---- SendToEtxGen ------" 
  }
  update
  return $ret
}

# ................................................................................
#  Abstract: Checks if plink process exists for opened ETX204A by  plink package
#
#**            ip_ID                :	        ID of ETX204A.
#**                              
#**   Outputs: 
#**            0                    :         If success. 
#**            Negativ error cod    :         Otherwise.     
# ................................................................................
proc CheckPlinkExist {ip_ID} {
  global        gMessage gEtxGenBuffer gEtxGenBufferDebug telnetBuffer$ip_ID
  variable      vaEtxGenStatuses 
  variable      vOpenedEtxGenHistoryCounter
	set fail          -1
	set ok             0

  if {![info exists vaEtxGenStatuses($ip_ID,EtxGenID)]} {
  	set	gMessage "CheckPlinkExist procedure: The EtxGen with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  set pids [pid $vaEtxGenStatuses($ip_ID,EtxGenHandle)]
  catch {exec tasklist.exe  /fi "PID eq $pids" /fo "csv" /nh} info
  if {[regexp "\"plink.exe\",\"$pids\"" $info]} {
    return $ok
  } else {
      return $fail
  }
}
# ................................................................................
#  Abstract: perform delay
#
#  Inputs: <seconds>
#
#  Outputs:  none
# ................................................................................
proc Delay {TimeSec} {
  set x 0
  after [expr $TimeSec * 1000] {set x 1}
  vwait x
}

# ................................................................................
#  Abstract: perform delay
#
#  Inputs: <milliseconds>
#
#  Outputs:  none
# ................................................................................
proc DelayMs {TimeMlSec} {
  set x 0
  after $TimeMlSec {set x 1}
  vwait x
}

# ...............................................................................
#  Abstract: clean buffer from junk after read EtxGen by com or telnet
#
#  Inputs: 
#
#  Outputs: 
# ..............................................................................
proc FilterBuffer {ip_ID} {
  global gEtxGenBuffer
  variable      vaEtxGenStatuses 
  set re \[\x1B\x08\[\]
  regsub -all -- $re         $gEtxGenBuffer(id$ip_ID) " " 1
  #regsub -all -- .1C       $1      " " 2
  
  #set gEtxGenBuffer(id$ip_ID) $2
  set gEtxGenBuffer(id$ip_ID) $1
}

# ...............................................................................
#  Abstract: 
#
#  Inputs: 
#
#  Outputs: 
# ..............................................................................
proc FindLine {ip_ID lineName} {
  global gEtxGenBuffer
  variable      vaEtxGenStatuses 
  set re "(\[0-9\]+).\[ \]+$lineName" ;
  set ret [regexp $re $gEtxGenBuffer(id$ip_ID) match lineNum]
  
  if {$ret==0} {
		return -1
	} else {
		  return $lineNum
	}
}

# .................................................................................
#  Abstract:  Build EtxGen GUI.
#
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc MakeEtxGenGui {} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
 
  set rundir [file dirname [info script]]  
	if {[regexp -nocase {EtxGen.exe} $rundir match]} {
    #for starpacks applications
		set dir [string range $rundir 0 [string last / $rundir]]
    set   vaEtxGenSet(rundir) [append dir EtxGen]
		set 	vaEtxGenSet(starpack) 1
	} else {
      set   vaEtxGenSet(rundir) C:/RLFiles/EtxGen
		  set 	vaEtxGenSet(starpack) 0
	}

  #set vaEtxGenSet(rundir) [pwd]
	set vaEtxGenSet(hexcodes) "00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F \
													 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F \
													 20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F \
													 30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F \
													 40 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F \
													 50 51 52 53 54 55 56 57 58 59 5A 5B 5C 5D 5E 5F \
													 60 61 62 63 64 65 66 67 68 69 6A 6B 6C 6D 6E 6F \
													 70 71 72 73 74 75 76 77 78 79 7A 7B 7C 7D 7E 7F \
													 80 81 82 83 84 85 86 87 88 89 8A 8B 8C 8D 8E 8F \
													 90 91 92 93 94 95 96 97 98 99 9A 9B 9C 9D 9E 9F \
													 A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 AA AB AC AD AE AF \
													 B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 BA BB BC BD BE BF \
													 C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 CA CB CC CD CE CF \
													 D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 DA DB DC DD DE DF \
													 E0 E1 E2 E3 E4 E5 E6 E7 E8 E9 EA EB EC ED EE EF \
													 F0 F1 F2 F3 F4 F5 F6 F7 F8 F9 FA FB FC FD FE FF "

  set vaEtxGenSet(listIP)	 ""
	set vaEtxGenSet(connect,com) ""
	set vaEtxGenSet(connect,telnet) ""
	if {$vaEtxGenSet(starpack)} {
		set vaEtxGenSet(comPackage)	 RLSerial
	} else {
    	set vaEtxGenSet(comPackage)	 RLCom
	}
#	set vaEtxGenSet(PacketType) MAC


	set base .topEtxGenGui
	toplevel $base -class Toplevel		
  wm focusmodel $base passive
	wm overrideredirect $base 0
  wm title $base "GE/FE ETX204A PRBS"
  wm protocol $base WM_DELETE_WINDOW { RLEtxGen::CloseEtxGenGui}
  #wm geometry . +180+25
  #wm geometry $base 292x240+$shiftX+$shiftY
  #wm geometry $base 292x260+$shiftX+$shiftY
  #wm resizable $base 0 0

	if {$vaEtxGenSet(starpack)} {
    wm geometry $base 900x650
	} else {
      wm geometry $base 900x630
	}
	bind .topEtxGenGui <F1> {set gConsole show; console show} 

  variable notebook
  variable mainframe

  set vaEtxGenSet(prgtext) "Please wait while loading font..."
  set vaEtxGenSet(prgindic) -1
  _create_intro
  update
  SelectFont::loadfont
	set vaEtxGenSet(currentid) ""

  set descmenu {
    "&File" {} {} 0 {		
	     {cascad "&Console" {} console 0 {
		      {radiobutton "console show" {} "Console Show" {} \
		       -command "console show" -value show -variable gConsole}
		      {radiobutton "console hide" {} "Console Hide" {} \
		       -command "console hide" -value hide -variable gConsole}
		     }
		    }
						{command	"Get Configuration from file..." {getcfgfile} {} {} -command {RLEtxGen::GetConfigFromFile cfg}}
						{command	"Save Configuration to file..." {savecfgfile} {} {} -command {RLEtxGen::SaveConfigToFile cfg}}
						{command	"Set Configuration to chassis" {savecfgchass} {} {} -command {RLEtxGen::SaveConfigToChassis}}
	          {separator}
						{command	"Save GUI config to file..." {saveguicfgfile} {} {} -command {RLEtxGen::SaveConfigToFile ini}}
						{command	"Get GUI config from file..." {getguicfgfile} {} {} -command {RLEtxGen::GetConfigFromFile ini}}
	     {separator}
	     {command "Destroy" {exit} {Exit} {} -command {RLEtxGen::CloseEtxGenGui}}		
	     {command "Quit" {quit} {Exit} {} -command {RLEtxGen::Quit}}		
	   }	
 	  "&Run" {} {} 0 {
 	      {command "Run Generator" {run} {} {} -command {RLEtxGen::RunCurrentChassis $RLEtxGen::vaEtxGenSet(currentid)}}
		  }
 	  "&Connection" {} {} 0 {
	      {command "Connect Chassis..." {connect} {} {} -command {RLEtxGen::ConnectChassis}}
	      {command "Disconnect Chassis" {disconnect} {} {} -command {RLEtxGen::DelEtxGenResource}}
		  }
 	  "&Tools" {} {} 0 {
  	    {command "Etx204 reset" {reset} {} {} -command {RLEtxGen::FactoryEtx -reset yes}}
  	    {command "E-mail setting" {email} {} {} -command {RLEtxGen::EtxGenEmailSet .mail}}
		  }
    "&Help" {} {} 0 {
         {command "&Index" {} {} {} -command {RLEtxGen::GetHelp}}
         {command "&About GE/FE ETX204A PRBS" {} {} {} -command {tk_messageBox \
           -icon info -type ok -message "GE/FE ETX-204A-AC/DC/HAC/HDC PRBS\n Ver. 1.1\n Copyright © 2011, Rad Data Communications"\
							 -title "About GE/FE ETX-204A PRBS"}}
			 }
  } 
  set mainframe [MainFrame $base.mainframe -menu $descmenu -textvariable vaEtxGenGui(status) -progressvar  vaEtxGenGui(prgindic)]
  set vaEtxGenGui(startTime) [$mainframe addindicator]
  set vaEtxGenGui(runTime) [$mainframe addindicator]
  set vaEtxGenGui(runStatus) [$mainframe addindicator]
  
 	#$base.mainframe setmenustate results disabled

 # toolbar  creation
  incr vaEtxGenSet(prgindic)
  set tb  [$mainframe addtoolbar]
  set bbox [ButtonBox $tb.bbox1 -spacing 0 -padx 1 -pady 1]
  set vaEtxGenGui(tb,new) [$bbox add -image [Bitmap::get $vaEtxGenSet(rundir)/Images/new] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLEtxGen::SaveConfigToFile cfg} \
      -helptext "Save configuration  to a file"]
  set vaEtxGenGui(tb,open) [$bbox add -image [Bitmap::get $vaEtxGenSet(rundir)/Images/open] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLEtxGen::GetConfigFromFile cfg} \
      -helptext "Get configuration from a existing file"]
  set vaEtxGenGui(tb,save) [$bbox add -image [Bitmap::get $vaEtxGenSet(rundir)/Images/save] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLEtxGen::SaveConfigToChassis} \
      -helptext "Set configuration from GUI to chassis"]

	lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(tb,new) $vaEtxGenGui(tb,open) $vaEtxGenGui(tb,save)

  pack $bbox -side left -anchor w
  set sep [Separator $tb.sep1 -orient vertical]
  pack $sep -side left -fill y -padx 4 -anchor w

  set bbox [ButtonBox $tb.bbox2 -spacing 0 -padx 1 -pady 1]
  set vaEtxGenGui(tb,connect) [$bbox add -image [Bitmap::get $vaEtxGenSet(rundir)/Images/connect] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLEtxGen::ConnectChassis} \
      -helptext "Connect a chassis"]
  set vaEtxGenGui(tb,help) [$bbox add -image [Bitmap::get $vaEtxGenSet(rundir)/Images/help] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLEtxGen::GetHelp} \
      -helptext "Help topics"]

  pack $bbox -side left -anchor w
  set sep [Separator $tb.sep2 -orient vertical]
  pack $sep -side left -fill y -padx 4 -anchor w

  set bbox [ButtonBox $tb.bbox4 -spacing 0 -padx 1 -pady 1]
  set vaEtxGenGui(tb,run) [$bbox add -image [Bitmap::get $vaEtxGenSet(rundir)/Images/run] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLEtxGen::RunCurrentChassis  $RLEtxGen::vaEtxGenSet(currentid)} \
      -helptext "Run the current chassis"]
  set vaEtxGenGui(tb,stop) [$bbox add -image [Bitmap::get $vaEtxGenSet(rundir)/Images/stop] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLEtxGen::StopCurrentChassis  $RLEtxGen::vaEtxGenSet(currentid)} \
      -helptext "Stop the current chassis"]

  pack $bbox -side left -anchor w
  set sep [Separator $tb.sep3 -orient vertical]
  pack $sep -side left -fill y -padx 4 -anchor w

  set bbox [ButtonBox $tb.bbox3 -spacing 0 -padx 1 -pady 1]
  set vaEtxGenGui(tb,multirun) [$bbox add -image [Bitmap::get $vaEtxGenSet(rundir)/Images/mulrun] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLEtxGen::RunAllChassis} \
      -helptext "Run all chassis"]
  set vaEtxGenGui(tb,multistop) [$bbox add -image [Bitmap::get $vaEtxGenSet(rundir)/Images/mulstop] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLEtxGen::StopAllChassis} \
      -helptext "Stop all chassis"]

  pack $bbox -side left -anchor w

  #Resource pane creation
  set frame    [$mainframe getframe]

  set pw    [PanedWindow $frame.pw -side top]

  set pane  [$pw add -weight 1]
  set title [TitleFrame $pane.lf -text "Resources"]
  set vaEtxGenGui(resources,sw)  [ScrolledWindow [$title getframe].sw -relief sunken -borderwidth 2]

  set vaEtxGenGui(resources,list) [ListBox::create $vaEtxGenGui(resources,sw).lb \
                -relief flat -borderwidth 0 \
                -dragevent 3 \
                -dropenabled 1 \
                -width 20 -highlightthickness 0 -bg white\
                -redraw 0 -dragenabled 0 \
                -droptypes {
                    TREE_NODE    {copy {} move {} link {}}
                    LISTBOX_ITEM {copy {} move {} link {}}}]

  $vaEtxGenGui(resources,sw) setwidget $vaEtxGenGui(resources,list)
	set vaEtxGenSet(resources,list) ""

  pack $vaEtxGenGui(resources,sw) -fill both -expand yes
  pack $title -fill both  -expand yes


  $vaEtxGenGui(resources,list) bindText  <ButtonPress-1>        "RLEtxGen::SelectEtxGenResource"
  #$vaEtxGenGui(resources,list) bindText  <ButtonPress-3> "RLEtxGen::DelEtxGenResource"
 # $vaEtxGenGui(resources,list) bindImage <Double-ButtonPress-1> "DemoTree::select list 2 $tree $list"

#===========================================================================================
# NoteBook creation
#===========================================================================================
  set framenb    [frame $frame.framenb]
  set notebook [NoteBook $framenb.nb]
  set vaEtxGenGui(notebook) $notebook

	#General setup page creation
  #===========================================================================================
  set vaEtxGenGui(general_setup) [$notebook insert end GenSetup -text "General Setup"]
	  #Ports setup creation 
    set vaEtxGenGui(general_setup,ports) [TitleFrame $vaEtxGenGui(general_setup).ports -text "Ports"]
  		  set tfAdminState  [TitleFrame [$vaEtxGenGui(general_setup,ports) getframe].tfAdminState -text "Admin state"]
		      set vaEtxGenGui(general_setup,ports,admin) [ComboBox [$tfAdminState getframe].cbadmin  -justify center\
                   -textvariable RLEtxGen::vaEtxGenSet(AdminStatus) -width 10 -modifycmd {RLEtxGen::SaveChanges ports AdminStatus}  \
                   -values {"up" "down"} -helptext "This is the Admin status"]
          set RLEtxGen::vaEtxGenSet(AdminStatus) up
			    pack $vaEtxGenGui(general_setup,ports,admin) -anchor w
  		  set tfAutonegot  [TitleFrame [$vaEtxGenGui(general_setup,ports) getframe].tfAutonegot -text "Autoneg"]
		      set vaEtxGenGui(general_setup,ports,autoneg_yes) [radiobutton [$tfAutonegot getframe].frautoneg_yes  -justify center\
               -variable RLEtxGen::vaEtxGenSet(Autonegotiat) -command {RLEtxGen::SaveChanges ports Autonegotiat ;RLEtxGen::ChangeAutoneg} -value enbl]
		      set vaEtxGenGui(general_setup,ports,autoneg_no) [radiobutton [$tfAutonegot getframe].frautoneg_no  -justify center\
               -variable RLEtxGen::vaEtxGenSet(Autonegotiat) -command {RLEtxGen::SaveChanges ports Autonegotiat ;RLEtxGen::ChangeAutoneg} -value dsbl]
			    pack $vaEtxGenGui(general_setup,ports,autoneg_yes) $vaEtxGenGui(general_setup,ports,autoneg_no) -side left
					set vaEtxGenSet(Autonegotiat) "enbl"
  		  set tfMaxAdvSpeed  [TitleFrame [$vaEtxGenGui(general_setup,ports) getframe].tfMaxAdvSpeed -text "Max adver speed"]
		      set vaEtxGenGui(general_setup,ports,maxadv) [ComboBox [$tfMaxAdvSpeed getframe].maxadv  -justify center\
                   -textvariable RLEtxGen::vaEtxGenSet(MaxAdvSpeed) -width 12 -modifycmd {RLEtxGen::SaveChanges ports MaxAdvSpeed}  \
                   -values {10-f 100-f 1000-f 1000-x} -helptext "This is the Maximal advertise speed"]
			    pack $vaEtxGenGui(general_setup,ports,maxadv) -anchor w
  		  set tfEthSpeed  [TitleFrame [$vaEtxGenGui(general_setup,ports) getframe].tfEthSpeed -text "Ethernet port speed"]
		      set vaEtxGenGui(general_setup,ports,ethspeed) [ComboBox [$tfEthSpeed getframe].ethspeed  -justify center\
                   -textvariable RLEtxGen::vaEtxGenSet(EthSpeed) -width 12 -modifycmd {RLEtxGen::SaveChanges ports EthSpeed}  \
                   -values {10-f 100-f 1000-f 1000-x} -helptext "This is the Ethernet port speed"]
			    pack $vaEtxGenGui(general_setup,ports,ethspeed) -anchor w

		      set vaEtxGenGui(general_setup,ports,factory) [checkbutton [$vaEtxGenGui(general_setup,ports) getframe].factory  -justify center\
               -variable RLEtxGen::vaEtxGenSet(portfactory) -command {RLEtxGen::SaveChanges ports portfactory} -text "Ports factory"]
		      set vaEtxGenGui(general_setup,ports,save) [checkbutton [$vaEtxGenGui(general_setup,ports) getframe].save  -justify center\
               -variable RLEtxGen::vaEtxGenSet(save) -command {RLEtxGen::SaveChanges ports save} -text "Save"]

			 pack $tfAdminState $tfAutonegot $tfMaxAdvSpeed $tfEthSpeed $vaEtxGenGui(general_setup,ports,factory)\
		        $vaEtxGenGui(general_setup,ports,save)  -side left -padx 6

	     lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general_setup,ports,admin) $vaEtxGenGui(general_setup,ports,autoneg_yes)
			 lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general_setup,ports,autoneg_no) $vaEtxGenGui(general_setup,ports,maxadv)
			 lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general_setup,ports,ethspeed) $vaEtxGenGui(general_setup,ports,factory)
			 lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general_setup,ports,save)
		pack $vaEtxGenGui(general_setup,ports) -anchor w -fill x -pady 4


	  #Generator setup creation 
    set vaEtxGenGui(general_setup,generator) [TitleFrame $vaEtxGenGui(general_setup).generator -text "Generator"]
      set frBaseParam [frame [$vaEtxGenGui(general_setup,generator) getframe].frBaseParam]
  		  set tfPacketType  [TitleFrame $frBaseParam.tfPacketType -text "Packet type"]
		      set vaEtxGenGui(general_setup,generator,packet) [ComboBox [$tfPacketType getframe].cbpacket  -justify center\
                   -textvariable RLEtxGen::vaEtxGenSet(PacketType) -width 7 -modifycmd {RLEtxGen::SaveChanges packet_setup PacketType ;RLEtxGen::SetPacketType}  \
                   -values {"MAC" "VLAN" "SVLAN" "IP" "RAW"} -helptext "This is the Packet type"]
			    pack $vaEtxGenGui(general_setup,generator,packet) -anchor w
  		  set tfGeneratMode  [TitleFrame $frBaseParam.tfGeneratMode -text "Generator Mode"]
		      set vaEtxGenGui(general_setup,generator,mode) [ComboBox [$tfGeneratMode getframe].cbmode  -justify center\
                   -textvariable RLEtxGen::vaEtxGenSet(GeneratorMode) -width 10 -modifycmd {RLEtxGen::SaveChanges generator GeneratorMode}  \
                   -values {"GE" "FE"} -helptext "This is the Generator Mode"]
			    pack $vaEtxGenGui(general_setup,generator,mode) -anchor w
  		  set tfPacketRate  [TitleFrame $frBaseParam.tfPacketRate -text "Packet Rate"]
		      set vaEtxGenGui(general_setup,generator,rate) [SpinBox [$tfPacketRate getframe].cbrate \
				              -textvariable RLEtxGen::vaEtxGenSet(PacketRate) -modifycmd {RLEtxGen::SaveChanges generator PacketRate}\
				              -range {1 1500000 5}  -width 8 -justify center -helptext "This is the Generator Mode"]
			    pack $vaEtxGenGui(general_setup,generator,rate) -anchor w
					$vaEtxGenGui(general_setup,generator,rate) bind <1> {RLEtxGen::SaveChanges generator PacketRate}
  		  set tfStreamNum  [TitleFrame $frBaseParam.tfStreamNum -text "Stream numbers"]
		      set vaEtxGenGui(general_setup,generator,stream) [SpinBox [$tfStreamNum getframe].cbstream \
				              -textvariable RLEtxGen::vaEtxGenSet(stream) -modifycmd {RLEtxGen::SaveChanges generator stream}\
				              -range {1 1 1}  -width 11 -justify center -helptext "This is the Stream numbers"]
			    pack $vaEtxGenGui(general_setup,generator,stream) -anchor w
					$vaEtxGenGui(general_setup,generator,stream) bind <1> {RLEtxGen::SaveChanges generator stream}
  		  set tfMinLen  [TitleFrame $frBaseParam.tfMinLen -text "Min Pack Len"]
		      set vaEtxGenGui(general_setup,generator,minlen) [SpinBox [$tfMinLen getframe].cbminlen \
				              -textvariable RLEtxGen::vaEtxGenSet(PacketMinLen) -modifycmd {RLEtxGen::SaveChanges generator PacketMinLen}\
				              -range {64 1600 1}  -width 10 -justify center -helptext "This is the Minimal packet length"]
			    pack $vaEtxGenGui(general_setup,generator,minlen) -anchor w
					$vaEtxGenGui(general_setup,generator,minlen) bind <1> {RLEtxGen::SaveChanges generator PacketMinLen}
  		  set tfMaxLen  [TitleFrame $frBaseParam.tfMaxLen -text "Max Pack Len"]
		      set vaEtxGenGui(general_setup,generator,maxlen) [SpinBox [$tfMaxLen getframe].cbmaxlen \
				              -textvariable RLEtxGen::vaEtxGenSet(PacketMaxLen) -modifycmd {RLEtxGen::SaveChanges generator PacketMaxLen}\
				              -range {64 1600 1}  -width 10 -justify center -helptext "This is the Maximal packet length"]
			    pack $vaEtxGenGui(general_setup,generator,maxlen) -anchor w
					$vaEtxGenGui(general_setup,generator,maxlen) bind <1> {RLEtxGen::SaveChanges generator PacketMaxLen}
  		  set tfChainLen  [TitleFrame $frBaseParam.tfChainLen -text "Chain Len"]
		      set vaEtxGenGui(general_setup,generator,chainlen) [SpinBox [$tfChainLen getframe].cbchainlen \
				              -textvariable RLEtxGen::vaEtxGenSet(ChainLength) -modifycmd {RLEtxGen::SaveChanges generator ChainLength}\
				              -range {1 20 1}  -width 7 -justify center -helptext "This is the Chain length"]
			    pack $vaEtxGenGui(general_setup,generator,chainlen) -anchor w
					$vaEtxGenGui(general_setup,generator,chainlen) bind <1> {RLEtxGen::SaveChanges generator ChainLength}

			  pack $tfPacketType $tfGeneratMode  $tfPacketRate  $tfStreamNum  $tfMinLen  $tfMaxLen  $tfChainLen -side left -padx 4
				lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general_setup,generator,packet) $vaEtxGenGui(general_setup,generator,mode)
				lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general_setup,generator,rate) $vaEtxGenGui(general_setup,generator,stream)
				lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general_setup,generator,minlen) $vaEtxGenGui(general_setup,generator,maxlen)
				lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general_setup,generator,chainlen)
			pack $frBaseParam	-anchor w

      set vaEtxGenGui(general_setup,generator,baseSaDa) [TitleFrame [$vaEtxGenGui(general_setup,generator) getframe].frbaseSaDa -text "Base DA/SA"]
        set frBaseDA [frame [$vaEtxGenGui(general_setup,generator,baseSaDa) getframe].frBaseDA]
  		    set tfDA  [TitleFrame $frBaseDA.tfDA -text "DA"]
		        set vaEtxGenGui(general_setup,generator,DA) [Entry [$tfDA getframe].enDA  -justify center -command {}\
                   -textvariable RLEtxGen::vaEtxGenSet(DA) -width 15 -relief ridge -editable 1]
			      pack $vaEtxGenGui(general_setup,generator,DA)	-anchor w
			      bind $vaEtxGenGui(general_setup,generator,DA) <1> {
						  RLEtxGen::SaveChanges packet_setup DA
							#puts "DA changed"
						}

  		    set tfincrDA  [TitleFrame $frBaseDA.tfincrDA -text "incr DA"]
		        set vaEtxGenGui(general_setup,generator,incrDA) [SpinBox [$tfincrDA getframe].sbincrDA \
				              -textvariable RLEtxGen::vaEtxGenSet(DA_incr) -modifycmd {RLEtxGen::SaveChanges packet_setup DA_incr}\
				              -range {0 2000000 1}  -width 10 -justify center]
			      pack $vaEtxGenGui(general_setup,generator,incrDA)	-anchor w
				  	$vaEtxGenGui(general_setup,generator,incrDA) bind <1> {RLEtxGen::SaveChanges packet_setup DA_incr}

  		    set tfstationDA  [TitleFrame $frBaseDA.tfstationDA -text "stations DA"]
		        set vaEtxGenGui(general_setup,generator,stationsDA) [SpinBox [$tfstationDA getframe].sbstationsDA \
				              -textvariable RLEtxGen::vaEtxGenSet(DA_StationNum) -modifycmd {RLEtxGen::SaveChanges packet_setup DA_StationNum}\
				              -range {0 2000000 1}  -width 10 -justify center]
			      pack $vaEtxGenGui(general_setup,generator,stationsDA)	-anchor w
				  	$vaEtxGenGui(general_setup,generator,stationsDA) bind <1> {RLEtxGen::SaveChanges packet_setup DA_StationNum}

  		    set tfincrDAidle  [TitleFrame $frBaseDA.tfincrDAidle -text "incr idle DA"]
		        set vaEtxGenGui(general_setup,generator,incrDAidle) [SpinBox [$tfincrDAidle getframe].sbincrDAidle \
				              -textvariable RLEtxGen::vaEtxGenSet(DA_incrIdle) -modifycmd {RLEtxGen::SaveChanges packet_setup DA_incrIdle}\
				              -range {0 2000000 1}  -width 10 -justify center]
			      pack $vaEtxGenGui(general_setup,generator,incrDAidle)	-anchor w
				  	$vaEtxGenGui(general_setup,generator,incrDAidle) bind <1> {RLEtxGen::SaveChanges packet_setup DA_incrIdle}


				    lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general_setup,generator,DA) $vaEtxGenGui(general_setup,generator,incrDA)
				    lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general_setup,generator,stationsDA) $vaEtxGenGui(general_setup,generator,incrDAidle)
			    pack $tfDA $tfincrDA $tfstationDA $tfincrDAidle -side left -padx 6

 			  pack $frBaseDA	-anchor w -pady 4

        set frBaseSA [frame [$vaEtxGenGui(general_setup,generator,baseSaDa) getframe].frBaseSA]
  		    set tfSA  [TitleFrame $frBaseSA.tfSA -text "SA"]
		        set vaEtxGenGui(general_setup,generator,SA) [Entry [$tfSA getframe].enSA  -justify center -command {}\
                   -textvariable RLEtxGen::vaEtxGenSet(SA) -width 15 -relief ridge -editable 1]
			      pack $vaEtxGenGui(general_setup,generator,SA)	-anchor w
			      bind $vaEtxGenGui(general_setup,generator,SA) <1> {
						  RLEtxGen::SaveChanges packet_setup SA
						}

  		    set tfincrSA  [TitleFrame $frBaseSA.tfincrSA -text "incr SA"]
		        set vaEtxGenGui(general_setup,generator,incrSA) [SpinBox [$tfincrSA getframe].sbincrSA \
				              -textvariable RLEtxGen::vaEtxGenSet(SA_incr) -modifycmd {RLEtxGen::SaveChanges packet_setup SA_incr}\
				              -range {0 2000000 1}  -width 10 -justify center]
			      pack $vaEtxGenGui(general_setup,generator,incrSA)	-anchor w
				  	$vaEtxGenGui(general_setup,generator,incrSA) bind <1> {RLEtxGen::SaveChanges packet_setup SA_incr}

  		    set tfstationSA  [TitleFrame $frBaseSA.tfstationSA -text "stations SA"]
		        set vaEtxGenGui(general_setup,generator,stationsSA) [SpinBox [$tfstationSA getframe].sbstationsSA \
				              -textvariable RLEtxGen::vaEtxGenSet(SA_StationNum) -modifycmd {RLEtxGen::SaveChanges packet_setup SA_StationNum}\
				              -range {0 2000000 1}  -width 10 -justify center]
			      pack $vaEtxGenGui(general_setup,generator,stationsSA)	-anchor w
				  	$vaEtxGenGui(general_setup,generator,stationsSA) bind <1> {RLEtxGen::SaveChanges packet_setup SA_StationNum}

  		    set tfincrSAidle  [TitleFrame $frBaseSA.tfincrSAidle -text "incr idle SA"]
		        set vaEtxGenGui(general_setup,generator,incrSAidle) [SpinBox [$tfincrSAidle getframe].sbincrSAidle \
				              -textvariable RLEtxGen::vaEtxGenSet(SA_incrIdle) -modifycmd {RLEtxGen::SaveChanges packet_setup SA_incrIdle}\
				              -range {0 2000000 1}  -width 10 -justify center]
			      pack $vaEtxGenGui(general_setup,generator,incrSAidle)	-anchor w
				  	$vaEtxGenGui(general_setup,generator,incrSAidle) bind <1> {RLEtxGen::SaveChanges packet_setup SA_incrIdle}

				  lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general_setup,generator,SA) $vaEtxGenGui(general_setup,generator,incrSA)
				  lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general_setup,generator,stationsSA) $vaEtxGenGui(general_setup,generator,incrSAidle)
			    pack $tfSA $tfincrSA $tfstationSA $tfincrSAidle -side left -padx 6

 			  pack $frBaseSA	-anchor w -pady 4

			pack $vaEtxGenGui(general_setup,generator,baseSaDa)	-anchor w -fill x

			bind $vaEtxGenGui(general_setup,generator,baseSaDa).l <1> {
			  set RLEtxGen::vaEtxGenSet(SA) 0
			  set RLEtxGen::vaEtxGenSet(DA) 0
			  set RLEtxGen::vaEtxGenSet(incrSA) 0
			  set RLEtxGen::vaEtxGenSet(incrDA) 0
			  set RLEtxGen::vaEtxGenSet(stationsSA) 0
			  set RLEtxGen::vaEtxGenSet(stationsDA) 0
			  set RLEtxGen::vaEtxGenSet(incrSAidle) 0
			  set RLEtxGen::vaEtxGenSet(incrDAidle) 0
			}

		  set vaEtxGenGui(general_setup,generator,factory) [checkbutton [$vaEtxGenGui(general_setup,generator) getframe].factory  -justify center\
               -variable RLEtxGen::vaEtxGenSet(genfactory) -command {RLEtxGen::SaveChanges generator genfactory} -text "Generator factory"]
		  set vaEtxGenGui(general_setup,packet_setup,clrUdf) [checkbutton [$vaEtxGenGui(general_setup,generator) getframe].clrUdf  -justify center\
               -variable RLEtxGen::vaEtxGenSet(clrUdf) -command {RLEtxGen::SaveChanges packet_setup clrUdf} -text "Clear UDF"]

			lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general_setup,generator,factory) $vaEtxGenGui(general_setup,packet_setup,clrUdf)
			pack $vaEtxGenGui(general_setup,generator,factory) $vaEtxGenGui(general_setup,packet_setup,clrUdf)	-anchor w -side left -padx 6
	  pack $vaEtxGenGui(general_setup,generator) -anchor w


	#Packet setup page creation
  #===========================================================================================
  set vaEtxGenSet(prgtext)   "Creating Packet setup..."
  set vaEtxGenGui(packet_setup) [$notebook insert end PacketSetup -text "Packet Setup"]

    set vaEtxGenGui(packet_setup,Mac) [TitleFrame $vaEtxGenGui(packet_setup).mac -text "MAC"]
			set tfEthtype [TitleFrame [$vaEtxGenGui(packet_setup,Mac) getframe].tfEthtype -text "Ethernet type"]
			  set vaEtxGenGui(packet_setup,mac,ethtype) [Entry [$tfEthtype getframe].ethtype -justify center \
	                 -textvariable RLEtxGen::vaEtxGenSet(EthFrameType) -width 10  -command {} \
	                 -helptext "This is the Ethernet packet type"]
	
				lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,mac,ethtype)
				pack $vaEtxGenGui(packet_setup,mac,ethtype) -anchor w
	      bind $vaEtxGenGui(packet_setup,mac,ethtype) <1> {
				  RLEtxGen::SaveChanges packet_setup EthFrameType
				}

			set tfmacpayload [TitleFrame [$vaEtxGenGui(packet_setup,Mac) getframe].tfmacpayload -text "Payload"]
			  set vaEtxGenGui(packet_setup,mac,payload) [Entry [$tfmacpayload getframe].payload -justify center \
	                 -textvariable RLEtxGen::vaEtxGenSet(payload) -width 60 -font {{} 10 {bold}}]
	
				lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,mac,payload)
				pack $vaEtxGenGui(packet_setup,mac,payload) -anchor w
	      bind $vaEtxGenGui(packet_setup,mac,payload) <1> {
				  RLEtxGen::SaveChanges packet_setup payload
				}
			pack $tfEthtype $tfmacpayload -side left -padx 6
		#pack $vaEtxGenGui(packet_setup,Mac) -anchor w	 -fill x

    set vaEtxGenGui(packet_setup,Vlan1) [TitleFrame $vaEtxGenGui(packet_setup).vlan1 -text "Vlan one tag"]
      set frVlanid [frame [$vaEtxGenGui(packet_setup,Vlan1) getframe].frVlanid]
			  set tfvlanid [TitleFrame $frVlanid.tfvlanid -text "VLAN ID"]
	        set vaEtxGenGui(packet_setup,Vlan1,id) [SpinBox [$tfvlanid getframe].sbvlanid \
			              -textvariable RLEtxGen::vaEtxGenSet(C_VLANID) -modifycmd {RLEtxGen::SaveChanges packet_setup C_VLANID
																																							RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {1 4094 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan1,id)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan1,id) bind <1> {RLEtxGen::SaveChanges packet_setup C_VLANID ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan1,id)
			  set tfvlanidincr [TitleFrame $frVlanid.tfvlanidincr -text "Incr ID"]
	        set vaEtxGenGui(packet_setup,Vlan1,IDincr) [SpinBox [$tfvlanidincr getframe].sbvlanidincr \
			              -textvariable RLEtxGen::vaEtxGenSet(cvlanIDincr) -modifycmd {RLEtxGen::SaveChanges packet_setup cvlanIDincr
																																							RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {0 4094 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan1,IDincr)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan1,IDincr) bind <1> {RLEtxGen::SaveChanges packet_setup cvlanIDincr ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan1,IDincr)
			  set tfvlanidincrsteps [TitleFrame $frVlanid.tfvlanidincrsteps -text "Incr steps"]
	        set vaEtxGenGui(packet_setup,Vlan1,IDincrsteps) [SpinBox [$tfvlanidincrsteps getframe].sbvlanidincrsteps \
			              -textvariable RLEtxGen::vaEtxGenSet(C_VLANincrNum) -modifycmd {RLEtxGen::SaveChanges packet_setup C_VLANincrNum
																																							RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {0 4094 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan1,IDincrsteps)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan1,IDincrsteps) bind <1> {RLEtxGen::SaveChanges packet_setup C_VLANincrNum ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan1,IDincrsteps)
			  set tfvlanidincridle [TitleFrame $frVlanid.tfvlanidincridle -text "Incr idle"]
	        set vaEtxGenGui(packet_setup,Vlan1,IDincridle) [SpinBox [$tfvlanidincridle getframe].sbvlanidincridle \
			              -textvariable RLEtxGen::vaEtxGenSet(C_VLANincrIdle) -modifycmd {RLEtxGen::SaveChanges packet_setup C_VLANincrIdle
																																							RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {0 4094 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan1,IDincridle)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan1,IDincridle) bind <1> {RLEtxGen::SaveChanges packet_setup C_VLANincrIdle ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan1,IDincridle)

			  set tfvlanP [TitleFrame $frVlanid.tfvlanP -text "VLAN P"]
	        set vaEtxGenGui(packet_setup,Vlan1,p) [SpinBox [$tfvlanP getframe].sbvlanp \
			              -textvariable RLEtxGen::vaEtxGenSet(C_VLANPbits) -modifycmd {RLEtxGen::SaveChanges packet_setup C_VLANPbits
																																							RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {0 7 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan1,p)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan1,p) bind <1> {RLEtxGen::SaveChanges packet_setup C_VLANPbits ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan1,p)
			  set tfvlanPincr [TitleFrame $frVlanid.tfvlanPincr -text "Incr P"]
	        set vaEtxGenGui(packet_setup,Vlan1,Pincr) [SpinBox [$tfvlanPincr getframe].sbvlanpincr \
			              -textvariable RLEtxGen::vaEtxGenSet(cvlanPincr) -modifycmd {RLEtxGen::SaveChanges packet_setup cvlanPincr
																																							RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {0 7 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan1,Pincr)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan1,Pincr) bind <1> {RLEtxGen::SaveChanges packet_setup cvlanPincr ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan1,Pincr)
				pack $tfvlanid $tfvlanidincr $tfvlanidincrsteps $tfvlanidincridle $tfvlanP $tfvlanPincr -side left -padx 4
			pack $frVlanid -anchor w -pady 4


      set frVlanEthtype [frame [$vaEtxGenGui(packet_setup,Vlan1) getframe].frVlanEthtype]
				set tfVlan1Ethtype [TitleFrame $frVlanEthtype.tfEthtype -text "Ethernet type"]
				  set vaEtxGenGui(packet_setup,Vlan1,ethtype) [Entry [$tfVlan1Ethtype getframe].ethtype -justify center \
		                 -textvariable RLEtxGen::vaEtxGenSet(EthFrameType) -width 10  -command {} \
		                 -helptext "This is the Ethernet packet type"]
		
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan1,ethtype)
					pack $vaEtxGenGui(packet_setup,Vlan1,ethtype) -anchor w
		      bind $vaEtxGenGui(packet_setup,Vlan1,ethtype) <1> {
					  RLEtxGen::SaveChanges packet_setup EthFrameType
					}
	
				set tfvlan1payload [TitleFrame $frVlanEthtype.tfvlan1payload -text "Payload"]
				  set vaEtxGenGui(packet_setup,Vlan1,payload) [Entry [$tfvlan1payload getframe].payload -justify center \
		                 -textvariable RLEtxGen::vaEtxGenSet(payload) -width 52 -font {{} 10 {bold}}]
		
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan1,payload)
					pack $vaEtxGenGui(packet_setup,Vlan1,payload) -anchor w
		      bind $vaEtxGenGui(packet_setup,Vlan1,payload) <1> {
					  RLEtxGen::SaveChanges packet_setup payload
					}
				pack $tfVlan1Ethtype $tfvlan1payload  -side left -padx 4
			pack $frVlanEthtype -anchor w -pady 4
		#pack $vaEtxGenGui(packet_setup,Vlan1) -anchor w	 -fill x


    set vaEtxGenGui(packet_setup,Vlan2) [TitleFrame $vaEtxGenGui(packet_setup).vlan2 -text "Vlan two tags"]
      set frCVlanid [frame [$vaEtxGenGui(packet_setup,Vlan2) getframe].frCVlanid]
			  set tfCvlanid [TitleFrame $frCVlanid.tfcvlanid -text "C-VLAN ID"]
	        set vaEtxGenGui(packet_setup,Vlan2,cvlanID) [SpinBox [$tfCvlanid getframe].sbcvlanid \
			              -textvariable RLEtxGen::vaEtxGenSet(C_VLANID) -modifycmd {RLEtxGen::SaveChanges packet_setup C_VLANID
																																							RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {1 4094 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan2,cvlanID)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan2,cvlanID) bind <1> {RLEtxGen::SaveChanges packet_setup C_VLANID ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,cvlanID)
			  set tfCvlanidincr [TitleFrame $frCVlanid.tfCvlanidincr -text "Incr ID"]
	        set vaEtxGenGui(packet_setup,Vlan2,CIDincr) [SpinBox [$tfCvlanidincr getframe].sbCvlanidincr \
			              -textvariable RLEtxGen::vaEtxGenSet(cvlanIDincr) -modifycmd {RLEtxGen::SaveChanges packet_setup cvlanIDincr
																																							RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {0 4094 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan2,CIDincr)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan2,CIDincr) bind <1> {RLEtxGen::SaveChanges packet_setup cvlanIDincr ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,CIDincr)
			  set tfCvlanidincrsteps [TitleFrame $frCVlanid.tfCvlanidincrsteps -text "Incr steps"]
	        set vaEtxGenGui(packet_setup,Vlan2,CIDincrsteps) [SpinBox [$tfCvlanidincrsteps getframe].sbCvlanidincrsteps \
			              -textvariable RLEtxGen::vaEtxGenSet(C_VLANincrNum) -modifycmd {RLEtxGen::SaveChanges packet_setup C_VLANincrNum
																																							RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {0 4094 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan2,CIDincrsteps)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan2,CIDincrsteps) bind <1> {RLEtxGen::SaveChanges packet_setup C_VLANincrNum ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,CIDincrsteps)
			  set tfCvlanidincridle [TitleFrame $frCVlanid.tfCvlanidincridle -text "Incr idle"]
	        set vaEtxGenGui(packet_setup,Vlan2,CIDincridle) [SpinBox [$tfCvlanidincridle getframe].sbCvlanidincridle \
			              -textvariable RLEtxGen::vaEtxGenSet(C_VLANincrIdle) -modifycmd {RLEtxGen::SaveChanges packet_setup C_VLANincrIdle
																																							RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {0 4094 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan2,CIDincridle)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan2,CIDincridle) bind <1> {RLEtxGen::SaveChanges packet_setup C_VLANincrIdle ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,CIDincridle)
			  set tfCvlanP [TitleFrame $frCVlanid.tfCvlanP -text "C-VLAN P"]
	        set vaEtxGenGui(packet_setup,Vlan2,Cp) [SpinBox [$tfCvlanP getframe].sbCvlanp \
			              -textvariable RLEtxGen::vaEtxGenSet(C_VLANPbits) -modifycmd {RLEtxGen::SaveChanges packet_setup C_VLANPbits
																																							RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {0 7 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan2,Cp)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan2,Cp) bind <1> {RLEtxGen::SaveChanges packet_setup C_VLANPbits ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,Cp)
			  set tfCvlanPincr [TitleFrame $frCVlanid.tfCvlanPincr -text "Incr P"]
	        set vaEtxGenGui(packet_setup,Vlan2,CPincr) [SpinBox [$tfCvlanPincr getframe].sbCvlanpincr \
			              -textvariable RLEtxGen::vaEtxGenSet(cvlanPincr) -modifycmd {RLEtxGen::SaveChanges packet_setup cvlanPincr
																																							RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {0 7 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan2,CPincr)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan2,CPincr) bind <1> {RLEtxGen::SaveChanges packet_setup cvlanPincr ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,CPincr)
				pack $tfCvlanid $tfCvlanidincr $tfCvlanidincrsteps $tfCvlanidincridle $tfCvlanP $tfCvlanPincr -side left -padx 4
			pack $frCVlanid -anchor w	 -pady 4


      set frSVlanid [frame [$vaEtxGenGui(packet_setup,Vlan2) getframe].frSVlanid]
			  set tfSvlanid [TitleFrame $frSVlanid.tfsvlanid -text "S-VLAN ID"]
	        set vaEtxGenGui(packet_setup,Vlan2,svlanID) [SpinBox [$tfSvlanid getframe].sbsvlanid \
			              -textvariable RLEtxGen::vaEtxGenSet(S_VLANID) -modifycmd {RLEtxGen::SaveChanges packet_setup S_VLANID
																																							RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {1 4094 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan2,svlanID)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan2,svlanID) bind <1> {RLEtxGen::SaveChanges packet_setup S_VLANID ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,svlanID)
			  set tfSvlanidincr [TitleFrame $frSVlanid.tfSvlanidincr -text "Incr ID"]
	        set vaEtxGenGui(packet_setup,Vlan2,SIDincr) [SpinBox [$tfSvlanidincr getframe].sbSvlanidincr \
			              -textvariable RLEtxGen::vaEtxGenSet(svlanIDincr) -modifycmd {RLEtxGen::SaveChanges packet_setup svlanIDincr
																																							   RLEtxGen::SaveChanges packet_setup VlanType
																																							 }\
			              -range {0 4094 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan2,SIDincr)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan2,SIDincr) bind <1> {RLEtxGen::SaveChanges packet_setup svlanIDincr ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,SIDincr)
			  set tfSvlanidincrsteps [TitleFrame $frSVlanid.tfSvlanidincrsteps -text "Incr steps"]
	        set vaEtxGenGui(packet_setup,Vlan2,SIDincrsteps) [SpinBox [$tfSvlanidincrsteps getframe].sbSvlanidincrsteps \
			              -textvariable RLEtxGen::vaEtxGenSet(S_VLANincrNum) -modifycmd {RLEtxGen::SaveChanges packet_setup S_VLANincrNum
																																							     RLEtxGen::SaveChanges packet_setup VlanType
																																							    }\
			              -range {0 4094 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan2,SIDincrsteps)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan2,SIDincrsteps) bind <1> {RLEtxGen::SaveChanges packet_setup S_VLANincrNum ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,SIDincrsteps)
			  set tfSvlanidincridle [TitleFrame $frSVlanid.tfSvlanidincridle -text "Incr idle"]
	        set vaEtxGenGui(packet_setup,Vlan2,SIDincridle) [SpinBox [$tfSvlanidincridle getframe].sbSvlanidincridle \
			              -textvariable RLEtxGen::vaEtxGenSet(S_VLANincrIdle) -modifycmd {RLEtxGen::SaveChanges packet_setup S_VLANincrIdle
																																							      RLEtxGen::SaveChanges packet_setup VlanType
																																							     }\
			              -range {0 4094 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan2,SIDincridle)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan2,SIDincridle) bind <1> {RLEtxGen::SaveChanges packet_setup S_VLANincrIdle ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,SIDincridle)
			  set tfSvlanP [TitleFrame $frSVlanid.tfSvlanP -text "S-VLAN P"]
	        set vaEtxGenGui(packet_setup,Vlan2,Sp) [SpinBox [$tfSvlanP getframe].sbSvlanp \
			              -textvariable RLEtxGen::vaEtxGenSet(S_VLANPbits) -modifycmd {RLEtxGen::SaveChanges packet_setup S_VLANPbits
																																							      RLEtxGen::SaveChanges packet_setup VlanType
																																							     }\
			              -range {0 7 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan2,Sp)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan2,Sp) bind <1> {RLEtxGen::SaveChanges packet_setup S_VLANPbits ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,Sp)
			  set tfSvlanPincr [TitleFrame $frSVlanid.tfSvlanPincr -text "Incr P"]
	        set vaEtxGenGui(packet_setup,Vlan2,SPincr) [SpinBox [$tfSvlanPincr getframe].sbSvlanpincr \
			              -textvariable RLEtxGen::vaEtxGenSet(svlanPincr) -modifycmd {RLEtxGen::SaveChanges packet_setup svlanPincr
																																							      RLEtxGen::SaveChanges packet_setup VlanType
																																							     }\
			              -range {0 7 1}  -width 10 -justify center]
		      pack $vaEtxGenGui(packet_setup,Vlan2,SPincr)	-anchor w
				  $vaEtxGenGui(packet_setup,Vlan2,SPincr) bind <1> {RLEtxGen::SaveChanges packet_setup svlanPincr ;RLEtxGen::SaveChanges packet_setup VlanType}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,SPincr)
				pack $tfSvlanid $tfSvlanidincr $tfSvlanidincrsteps $tfSvlanidincridle $tfSvlanP $tfSvlanPincr -side left -padx 4
			pack $frSVlanid -anchor w -pady 4


      set frVlan2Ethtype [frame [$vaEtxGenGui(packet_setup,Vlan2) getframe].frVlan2Ethtype]
				set tfVlanStype [TitleFrame $frVlan2Ethtype.tfVlanStype -text "S-VLAN Type"]
				  set vaEtxGenGui(packet_setup,Vlan2,Stype) [ComboBox [$tfVlanStype getframe].stype -justify center \
		                 -textvariable RLEtxGen::vaEtxGenSet(SVlanType) -width 10  -modifycmd {RLEtxGen::SaveChanges packet_setup SVlanType
																																							      RLEtxGen::SaveChanges packet_setup VlanType
			                                                                              set RLEtxGen::vaEtxGenSet(VlanType) stacked
																																							     }\
		                 -values "8100 9100 88A8" -helptext "This is the S-Vlan type"]
		
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,Stype)
					pack $vaEtxGenGui(packet_setup,Vlan2,Stype) -anchor w
				set tfVlan2Ethtype [TitleFrame $frVlan2Ethtype.tfSEthtype -text "Ethernet type"]
				  set vaEtxGenGui(packet_setup,Vlan2,ethtype) [Entry [$tfVlan2Ethtype getframe].ethtype -justify center \
		                 -textvariable RLEtxGen::vaEtxGenSet(EthFrameType) -width 10  -command {} \
		                 -helptext "This is the Ethernet packet type"]
		
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,ethtype)
					pack $vaEtxGenGui(packet_setup,Vlan2,ethtype) -anchor w
		      bind $vaEtxGenGui(packet_setup,Vlan2,ethtype) <1> {
					  RLEtxGen::SaveChanges packet_setup EthFrameType
					}
	
				set tfvlan2payload [TitleFrame $frVlan2Ethtype.tfvlan2payload -text "Payload"]
				  set vaEtxGenGui(packet_setup,Vlan2,payload) [Entry [$tfvlan2payload getframe].payload -justify center \
		                 -textvariable RLEtxGen::vaEtxGenSet(payload) -width 44 -font {{} 10 {bold}}]
		
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Vlan2,payload)
					pack $vaEtxGenGui(packet_setup,Vlan2,payload) -anchor w
		      bind $vaEtxGenGui(packet_setup,Vlan2,payload) <1> {
					  RLEtxGen::SaveChanges packet_setup payload
					}
				pack $tfVlanStype $tfVlan2Ethtype $tfvlan2payload  -side left -padx 4
			pack $frVlan2Ethtype -anchor w -pady 4
		#pack $vaEtxGenGui(packet_setup,Vlan2) -anchor w	 -fill x


    set vaEtxGenGui(packet_setup,IP) [TitleFrame $vaEtxGenGui(packet_setup).ip -text "IP"]
      set fripparam [frame [$vaEtxGenGui(packet_setup,IP) getframe].fripparam]
			  set tfTos [TitleFrame $fripparam.tfTos -text "Tos"]
	        set vaEtxGenGui(packet_setup,IP,tos) [ComboBox [$tfTos getframe].cbtos -justify center \
		                 -textvariable RLEtxGen::vaEtxGenSet(IPtos) -width 12  -modifycmd {RLEtxGen::SaveChanges packet_setup IPtos} \
		                 -values $RLEtxGen::vaEtxGenSet(hexcodes) -helptext "This is the IP TOS"]
		      pack $vaEtxGenGui(packet_setup,IP,tos)	-anchor w
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,IP,tos)
			  set tfTtl [TitleFrame $fripparam.tfTtl -text "Ttl"]
	        set vaEtxGenGui(packet_setup,IP,ttl) [SpinBox [$tfTtl getframe].sbttl \
			              -textvariable RLEtxGen::vaEtxGenSet(IPttl) -modifycmd {RLEtxGen::SaveChanges packet_setup IPttl}\
			              -range {1 255 1}  -width 12 -justify center]
		      pack $vaEtxGenGui(packet_setup,IP,ttl)	-anchor w
				  $vaEtxGenGui(packet_setup,IP,ttl) bind <1> {RLEtxGen::SaveChanges packet_setup IPttl}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,IP,ttl)
			  set tfIdentif [TitleFrame $fripparam.tfIdentif -text "Identificator"]
	        set vaEtxGenGui(packet_setup,IP,ident) [SpinBox [$tfIdentif getframe].sbidentif \
			              -textvariable RLEtxGen::vaEtxGenSet(IPidentific) -modifycmd {RLEtxGen::SaveChanges packet_setup IPidentific}\
			              -range {1 65535 1}  -width 12 -justify center]
		      pack $vaEtxGenGui(packet_setup,IP,ident)	-anchor w
				  $vaEtxGenGui(packet_setup,IP,ident) bind <1> {RLEtxGen::SaveChanges packet_setup IPidentific}
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,IP,ident)
			  set tfProtoc [TitleFrame $fripparam.tfProtoc -text "Protocol"]
	        set vaEtxGenGui(packet_setup,IP,protoc) [ComboBox [$tfProtoc getframe].cbprotoc -justify center \
		                 -textvariable RLEtxGen::vaEtxGenSet(IPprotocol) -width 12  -modifycmd {RLEtxGen::SaveChanges packet_setup IPprotocol} \
		                 -values $RLEtxGen::vaEtxGenSet(hexcodes) -helptext "This is the IP Protocol"]
		      pack $vaEtxGenGui(packet_setup,IP,protoc)	-anchor w
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,IP,protoc)
				pack $tfTos $tfTtl $tfIdentif $tfProtoc  -side left -padx 6
			pack $fripparam -anchor w

      set fripparam2 [frame [$vaEtxGenGui(packet_setup,IP) getframe].fripparam2]
				set tfDestIp [TitleFrame $fripparam2.tfDestIp -text "Destination IP"]
				  set vaEtxGenGui(packet_setup,IP,destIp) [Entry [$tfDestIp getframe].destIp -justify center \
		                 -textvariable RLEtxGen::vaEtxGenSet(IPdestination) -width 14 -font {{} 10}]
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,IP,destIp)
					pack $vaEtxGenGui(packet_setup,IP,destIp) -anchor w
		      bind $vaEtxGenGui(packet_setup,IP,destIp) <1> {
					  RLEtxGen::SaveChanges packet_setup IPdestination
					}
				set tfSourceIp [TitleFrame $fripparam2.tfSourceIp -text "Source IP"]
				  set vaEtxGenGui(packet_setup,IP,sourceIp) [Entry [$tfSourceIp getframe].sourceIp -justify center \
		                 -textvariable RLEtxGen::vaEtxGenSet(IPsource) -width 14 -font {{} 10}]
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,IP,sourceIp)
					pack $vaEtxGenGui(packet_setup,IP,sourceIp) -anchor w
		      bind $vaEtxGenGui(packet_setup,IP,sourceIp) <1> {
					  RLEtxGen::SaveChanges packet_setup IPsource
					}
				set tfIPpayload [TitleFrame $fripparam2.tfIPpayload -text "Payload"]
				  set vaEtxGenGui(packet_setup,IP,payload) [Entry [$tfIPpayload getframe].payload -justify center \
		                 -textvariable RLEtxGen::vaEtxGenSet(payload) -width 26 -font {{} 10 {bold}}]
		
					lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,IP,payload)
					pack $vaEtxGenGui(packet_setup,IP,payload) -anchor w
		      bind $vaEtxGenGui(packet_setup,IP,payload) <1> {
					  RLEtxGen::SaveChanges packet_setup payload
					}
				pack $tfDestIp $tfSourceIp $tfIPpayload -side left -padx 5
			pack $fripparam2 -anchor w
		#pack $vaEtxGenGui(packet_setup,IP) -anchor w	 -fill x


    set vaEtxGenGui(packet_setup,Raw) [TitleFrame $vaEtxGenGui(packet_setup).raw -text "RAW"]
      set frRaw1 [frame [$vaEtxGenGui(packet_setup,Raw) getframe].frRaw1]
			  foreach title {13-16 17-20 21-24 25-28 29-32 33-36 37-40 41-44} {
					set tf$title [TitleFrame $frRaw1.tf$title -text "$title"]
					  set vaEtxGenGui(packet_setup,Raw,$title) [Entry [[set tf$title] getframe].raw$title -justify center \
			                 -textvariable RLEtxGen::vaEtxGenSet(raw$title) -width 9]
						lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Raw,$title)
						pack $vaEtxGenGui(packet_setup,Raw,$title) -anchor w
			      bind $vaEtxGenGui(packet_setup,Raw,$title) <1> [list RLEtxGen::SaveChanges packet_setup raw$title]
						
				}
				set lbData [label $frRaw1.lbData -text "Data:"]
				pack $lbData [set tf13-16] [set tf17-20] [set tf21-24] [set tf25-28]\
			       [set tf29-32] [set tf33-36] [set tf37-40] [set tf41-44] -side left -padx 2
			pack $frRaw1 -anchor w
	    foreach udfTytle {1 2 3 4 5 6} {
        set ftudf$udfTytle [frame [$vaEtxGenGui(packet_setup,Raw) getframe].ftudf$udfTytle]
					foreach udf {BaseValue IncrValue IncrSteps IncrIdle} {
						set tf$udf [TitleFrame [set ftudf$udfTytle].tf$udf$udfTytle -text "$udf"]
						  set vaEtxGenGui(packet_setup,Raw,udf$udfTytle,$udf) [Entry [[set tf$udf] getframe].udf$udfTytle -justify center \
				                 -textvariable RLEtxGen::vaEtxGenSet(raw$udf$udfTytle) -width 14]
							#set RLEtxGen::vaEtxGenSet(raw$udf$udfTytle) 0
							lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Raw,udf$udfTytle,$udf)
							pack $vaEtxGenGui(packet_setup,Raw,udf$udfTytle,$udf) -anchor w
				      bind $vaEtxGenGui(packet_setup,Raw,udf$udfTytle,$udf) <1> [list RLEtxGen::SaveChanges packet_setup raw$udf$udfTytle]

					}
				  set tfOffset$udfTytle [TitleFrame [set ftudf$udfTytle].tfOffset$udfTytle -text "Offset"]
		        set vaEtxGenGui(packet_setup,Raw,udf$udfTytle,offset) [ComboBox [[set tfOffset$udfTytle] getframe].offset$udfTytle -justify center \
			                 -textvariable RLEtxGen::vaEtxGenSet(rawOffset$udfTytle) -width 10  -modifycmd [list RLEtxGen::SaveChanges packet_setup rawOffset$udfTytle] \
			                 -values {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43}]
			      pack $vaEtxGenGui(packet_setup,Raw,udf$udfTytle,offset)	-anchor w
						lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Raw,udf$udfTytle,offset)
				  set tfWidth$udfTytle [TitleFrame [set ftudf$udfTytle].tfWidth$udfTytle -text "Width"]
		        set vaEtxGenGui(packet_setup,Raw,udf$udfTytle,Width) [ComboBox [[set tfWidth$udfTytle] getframe].width$udfTytle -justify center \
			                 -textvariable RLEtxGen::vaEtxGenSet(rawWidth$udfTytle) -width 10  -modifycmd [list RLEtxGen::SaveChanges packet_setup rawWidth$udfTytle] \
			                 -values {0 8 16 32}]
						#set RLEtxGen::vaEtxGenSet(rawWidth$udfTytle) 0
			      pack $vaEtxGenGui(packet_setup,Raw,udf$udfTytle,Width)	-anchor w
						lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(packet_setup,Raw,udf$udfTytle,Width)
				  set lbUdf$udfTytle [label [set ftudf$udfTytle].lbUdf -text "Udf $udfTytle:"]

					pack [set lbUdf$udfTytle] $tfBaseValue $tfIncrValue $tfIncrSteps $tfIncrIdle\
				       [set tfOffset$udfTytle] [set tfWidth$udfTytle] -side left -padx 2
				pack [set ftudf$udfTytle] -anchor w -pady 4
			}
		#pack $vaEtxGenGui(packet_setup,Raw) -anchor w	 -fill x


	#Statistics  page creation
  #===========================================================================================
  set vaEtxGenSet(prgtext)   "Creating Generator Statistics..."
  set vaEtxGenGui(statistics) [$notebook insert end Statistics -text "Generator statistics"]
    set vaEtxGenGui(genstat,tools) [TitleFrame $vaEtxGenGui(statistics).tools -text "Tools"]

		  set bbox [ButtonBox [$vaEtxGenGui(genstat,tools) getframe].bbox2 -spacing 0 -padx 1 -pady 1]
		    set vaEtxGenGui(genstat,tools,clear) [$bbox add -image [Bitmap::get $vaEtxGenSet(rundir)/Images/clear] \
		      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 \
		      -helptext "Clear Generator statistics" -command {RLEtxGen::ClearEtxGenStatistics}]
		    set vaEtxGenGui(genstat,tools,clearone) [$bbox add -image [Bitmap::get $vaEtxGenSet(rundir)/Images/clearone] \
		      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 \
		      -helptext "Clear current port statistics" -command {RLEtxGen::ClearEtxGenStatistics}]
				pack $vaEtxGenGui(genstat,tools,clear) $vaEtxGenGui(genstat,tools,clearone) -side left -padx 10
			pack $bbox -side left
		pack $vaEtxGenGui(genstat,tools)	 -fill x 

    GeneralGeneratorStatistics 
		pack $vaEtxGenGui(genstat) -fill both -pady 4


	#Configuration  page creation
  #===========================================================================================
  set vaEtxGenSet(prgtext)   "Creating Chassis configuration..."
  set vaEtxGenGui(configuration) [$notebook insert end Configuration -text "Configuration state"]
  GeneralConfigState 
	pack $vaEtxGenGui(configuration,state) -fill both



	#General configuration frame creation
  #===========================================================================================
  set vaEtxGenSet(prgtext)   "Creating General parameters..."
  set vaEtxGenGui(general) [TitleFrame $framenb.general -text "General"]

		set tfportnum [TitleFrame [$vaEtxGenGui(general) getframe].tfportnum -text "Port number"]
		  set vaEtxGenGui(general,portnumb) [ComboBox [$tfportnum getframe].portnumb -justify center \
                 -textvariable RLEtxGen::vaEtxGenSet(port) -width 10  -modifycmd {RLEtxGen::SaveChanges general port} \
                 -values "1 2 3 4 All" -helptext "This is the Port number"]

			lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general,portnumb)
			pack $vaEtxGenGui(general,portnumb) -anchor w

		set tfchassaddr [TitleFrame [$vaEtxGenGui(general) getframe].tfchassaddr -text "Chassis address"]
		  set vaEtxGenGui(general,chassis) [Entry [$tfchassaddr getframe].chassis -justify center \
                 -textvariable RLEtxGen::vaEtxGenSet(hostIP) -width 16  -editable 0 -font {{} 10 {bold underline}}]

			lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general,chassis)
			pack $vaEtxGenGui(general,chassis) -anchor w

		set tfrunstat [TitleFrame [$vaEtxGenGui(general) getframe].tfrunstat -text "Running state"]
		  set vaEtxGenGui(general,runstate) [Entry [$tfrunstat getframe].chassis -justify center \
                 -textvariable RLEtxGen::vaEtxGenSet(runstate) -width 14  -editable 0 ]

			lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general,runstate)
			pack $vaEtxGenGui(general,runstate) -anchor w

      set vaEtxGenGui(general,serpackage) [checkbutton [$vaEtxGenGui(general) getframe].serpackage  -justify center\
           -variable RLEtxGen::vaEtxGenSet(rlserial) -command {
						                                                    if {$RLEtxGen::vaEtxGenSet(rlserial)} {
																															    set RLEtxGen::vaEtxGenSet(comPackage) "RLSerial"
																															  } else {
																															      set RLEtxGen::vaEtxGenSet(comPackage) "RLCom"
																															  }
																														  } -text "RLSerial package"]

		if {$vaEtxGenSet(starpack)} {
		  pack $tfportnum $tfchassaddr $tfrunstat -side left -padx 4 -fill x
		} else {
		    pack $tfportnum $tfchassaddr $tfrunstat $vaEtxGenGui(general,serpackage) -side left -padx 4 -fill x
			  lappend  vaEtxGenSet(lDisabledEntries) $vaEtxGenGui(general,serpackage)
		}
	$notebook compute_size
  pack $pw $framenb -fill both -padx 4 -pady 4 -side left
  pack $notebook  -fill both -expand yes -padx 4 -pady 4 
	pack $vaEtxGenGui(general) -fill x
  $notebook raise [$notebook page 0]

  set vaEtxGenSet(prgtext)   "Done"
  set vaEtxGenSet(prgindic) 10
  pack $mainframe -fill both -expand 1

  update idletasks
  $vaEtxGenGui(resources,list) configure -redraw 1
  $vaEtxGenGui(resources,list) insert end  Resources -text  "Resources" -image [Bitmap::get $vaEtxGenSet(rundir)/Images/resources]
  destroy .intro

  wm deiconify $base
  raise $base
  focus -force $base

	SetPacketType
	ChangeAutoneg
}


# ................................................................................
#  Abstract: Connect chassis to host by telnet or com.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc ConnectChassis {} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
	variable address
	variable titlname1
	variable titlname2
	variable frBut
	variable package

  if {[winfo exists .connChassisEtxGen]} {focus -force .connChassisEtxGen; return}
  toplevel .connChassisEtxGen -class Toplevel
  wm focusmodel .connChassisEtxGen passive
  wm resizable .connChassisEtxGen 0 0
  wm title .connChassisEtxGen "Connect chassis"
  wm protocol .connChassisEtxGen WM_DELETE_WINDOW {destroy .connChassisEtxGen}
  set b .connChassisEtxGen 
  
	  set titlname1 [TitleFrame $b.titlname1 -text "Com number"]
	    set vaEtxGenGui(cb,connect,com) [ComboBox [$titlname1 getframe].com  -justify center \
               -textvariable RLEtxGen::vaEtxGenSet(connect,com) -width 15 \
							 -modifycmd {set RLEtxGen::address $RLEtxGen::vaEtxGenSet(connect,com) ; set RLEtxGen::package $RLEtxGen::vaEtxGenSet(comPackage)}\
               -values {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33} \
               -helptext "This is the Com number"]
		  pack $vaEtxGenGui(cb,connect,com)

	  set titlname2 [TitleFrame $b.titlname2 -text "IP address"]
	    set vaEtxGenGui(cb,connect,telnet) [ComboBox [$titlname2 getframe].telnet  -justify center \
               -textvariable RLEtxGen::vaEtxGenSet(connect,telnet) -width 15 -modifycmd {set RLEtxGen::address $RLEtxGen::vaEtxGenSet(connect,telnet) ; set RLEtxGen::package RLPlink}\
               -values $RLEtxGen::vaEtxGenSet(listIP) \
               -helptext "This is the IP address"]
		   pack $vaEtxGenGui(cb,connect,telnet)

    set frBut [frame $b.frBut]

    set frConntype [TitleFrame $b.frConntype -text "Connect by..."]
	    set comrb [radiobutton [$frConntype getframe].rad1 -text "Com" -value 1 -variable RLEtxGen::vaEtxGenSet(connectBy)\
              -command  {set RLEtxGen::address $RLEtxGen::vaEtxGenSet(connect,com)
  											 set RLEtxGen::package RLSerial
							           catch {pack forget $RLEtxGen::titlname1 $RLEtxGen::titlname2 $RLEtxGen::frBut}
						             pack $RLEtxGen::titlname1 $RLEtxGen::frBut}]
	    set telrb [radiobutton [$frConntype getframe].rad2 -text "Telnet" -value 0 -variable RLEtxGen::vaEtxGenSet(connectBy)\
              -command  {set RLEtxGen::address $RLEtxGen::vaEtxGenSet(connect,telnet)
 												 set RLEtxGen::package RLPlink
							           catch {pack forget $RLEtxGen::titlname1 $RLEtxGen::titlname2 $RLEtxGen::frBut} 
											   pack $RLEtxGen::titlname2 $RLEtxGen::frBut}]
		  pack $comrb $telrb -side left 
		
	  pack $frConntype
		if {![info exists RLEtxGen::package]} {
	   pack $titlname1
	  } elseif {$RLEtxGen::package == "RLPlink"} {
    	  pack $titlname2
		} else {
  	    pack $titlname1
		}

      set vaEtxGenGui(connect,telnet) [button $frBut.butOk -text Ok -width 9 -command {
      									if {[info exists RLEtxGen::package] && $RLEtxGen::package == "RLPlink"} {
													set RLEtxGen::address $RLEtxGen::vaEtxGenSet(connect,telnet)
												}
												if {![info exists RLEtxGen::address] || ![info exists RLEtxGen::package] || $RLEtxGen::address == "" || $RLEtxGen::package == ""} {
													set gMessage  "Please select all entries"
													tk_messageBox -icon error -type ok -message "$gMessage" -title "Etx204A Generator"
											    return    
												}
			                  RLEtxGen::OkConnChassis $RLEtxGen::address $RLEtxGen::package}]
      pack $vaEtxGenGui(connect,telnet) 

    pack $frBut -padx 3 -pady 3 -fill both
		$vaEtxGenGui(cb,connect,telnet) configure -command {$RLEtxGen::vaEtxGenGui(connect,telnet) invoke} -takefocus 1
  focus -force $b

}	

# ................................................................................
#  Abstract: EtxGenshow_progdlg
#  Inputs: 
#
#  Outputs: 
# ................................................................................

proc EtxGenshow_progdlg { } {
    variable progmsg
		variable progval
    set progmsg "Compute in progress..."
    set progval 0

    ProgressDlg .progress -parent .topEtxGenGui -title "Wait..." \
        -type         infinite \
        -width        20 \
        -textvariable RLEtxGen::progmsg \
        -variable     RLEtxGen::progval \
        -stop         "Stop" \
        -command      {destroy .progress}

				RLEtxGen::EtxGenshow_update_progdlg
}

# ................................................................................
#  Abstract: 
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc EtxGenshow_update_progdlg {} {
    variable progmsg
		variable progval

    if { [winfo exists .progress] } {
        set progval 2
        after 25	RLEtxGen::EtxGenshow_update_progdlg
    }
}



# .........................................................................
#  Abstract: 
#  Inputs: 
#
#  Outputs: 
# .........................................................................
proc OkConnChassis {address package {id 0}} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

	set resources ""
  set reslist  [lrange [$vaEtxGenGui(resources,list) items] 1 end]
	if {$reslist != ""} {
		foreach chassis $reslist {
	  	set ch [lindex [split $chassis :] 1]
    	lappend resources $vaEtxGenStatuses($ch,address) $vaEtxGenStatuses($ch,package)
		}
	}

	if {$resources != ""} {
		if {[lsearch $resources $address] != -1} {
			set gMessage  "There is already given address: $address into resources"
			tk_messageBox -icon error -type ok -message "$gMessage" -title "Etx204A Generator"
	    return    
		}
	}

	if {[info exists vaEtxGenGui(connect,telnet)]} {
	  catch {$vaEtxGenGui(connect,telnet) configure -state disable -relief sunken}
	}
	RLEtxGen::EtxGenshow_progdlg
	#the id doesn't compared to nul when this procedure invoked from ShowGui proc.
	if {!$id} {
		if [catch {RLEtxGen::Open $address -package $package} id] {
		  destroy .progress
  	  if {[info exists vaEtxGenGui(connect,telnet)]} {
	   	  $vaEtxGenGui(connect,telnet) configure -state normal -relief raised
			}
			append gMessage  "\nFail while (RLEtxGen::Open $address -package $package) procedure"
			tk_messageBox -icon error -type ok -message "$gMessage" -title "Etx204A Generator"
	    return    
		}
	}
	set vaEtxGenSet(currentid) $id

	if {[RLEtxGen::GetConfig $id  aResCfg]} {
	  destroy .progress
		tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::GetConfig $id) procedure \n$gMessage" -title "Etx204A Generator"
		RLEtxGen::Close $id
    return    
	}
	array set vaEtxGenCfg [array get aResCfg]

	#parray	vaEtxGenCfg
	#parray	vaEtxGenStatuses
	if {[info exists vaEtxGenGui(connect,telnet)]} {
   	catch {$vaEtxGenGui(connect,telnet) configure -state normal -relief raised}
	}
  $vaEtxGenGui(resources,list) insert end  chassis:$id -text  "chassis $id" -fill darkgreen -indent 10 -font {times 14}
  $vaEtxGenGui(resources,list) selection set chassis:$id
	set vaEtxGenSet(currentchass) chassis:$id
	if {[winfo exists .topEtxGenGui]} {
	  FillCurrentGuiEntries $id 
		#SetPacketType
	}

	if {[regexp {[\d].[\d].} $address]} {
      set chassadr "[lindex [$vaEtxGenGui(resources,list) items] end]    $address"
 	} else {
      set chassadr "[lindex [$vaEtxGenGui(resources,list) items] end]    COM: $address"
	}
	#set RLEtxGen::vaEtxGenSet(genstat,tools,chAddr) [string toupper $chassadr] 


	if {[lsearch $vaEtxGenSet(listIP) $vaEtxGenSet(connect,telnet)] == -1} {
	  lappend vaEtxGenSet(listIP)	  $vaEtxGenSet(connect,telnet)
	}
	destroy .progress
  catch {destroy .connChassisEtxGen}

  if {$vaEtxGenCfg(id$id,etxRun) == 1} {
	  RunCurrentChassis $id noclear
	}
	if {[winfo exists .topEtxGenGui]} {
		SetPacketType
	}

	#puts $address
}

# ...........................................................................
#  Abstract: 	 FillCurrentGuiEntries
#  Inputs: 
#
#  Outputs: 
# ...........................................................................
proc FillCurrentGuiEntries {ip_ID} {

  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

#	parray vaEtxGenCfg


	#Host IP
	set vaEtxGenSet(hostIP) $vaEtxGenCfg(id$ip_ID,hostIP)

	#Port setup 
	set vaEtxGenSet(port)		$vaEtxGenCfg(id$ip_ID,updGen)
	if {[regexp -nocase {all} $vaEtxGenCfg(id$ip_ID,updGen)]} {
		 set port 1
	} else {
 		  set port $vaEtxGenSet(port)
	}

	foreach param {"AdminStatus" "Autonegotiat" "MaxAdvSpeed" "EthSpeed"} {
		set vaEtxGenSet($param) [string tolower $vaEtxGenCfg(id$ip_ID,$param,Gen$port)]
	}

	#Generator setup
	foreach param {"GeneratorMode" "PacketMinLen" "PacketMaxLen" "ChainLength" "PacketRate" "PacketType"} {
		set vaEtxGenSet($param) $vaEtxGenCfg(id$ip_ID,$param,Gen$port)
	}



 	#Base DA/SA setup
	foreach param {"DA" "DA_incr" "DA_StationNum" "DA_incrIdle" "SA" "SA_incr" "SA_StationNum" "SA_incrIdle"} {
		set vaEtxGenSet($param) $vaEtxGenCfg(id$ip_ID,$param,Gen$port)
	}


 	#Vlan1 setup
	foreach param {"C_VLANID" "C_VLANPbits" "C_VLANincrNum" "C_VLANincrIdle"} {
		set vaEtxGenSet($param) $vaEtxGenCfg(id$ip_ID,$param,Gen$port)
	}
	set vaEtxGenSet(cvlanIDincr) [expr $vaEtxGenCfg(id$ip_ID,C_VLANincr,Gen$port)%4096]
	set vaEtxGenSet(cvlanPincr) [expr $vaEtxGenCfg(id$ip_ID,C_VLANincr,Gen$port)/8192]

 	#Vlan2 setup
	foreach param {"S_VLANID" "S_VLANPbits" "S_VLANincrNum" "S_VLANincrIdle"} {
		set vaEtxGenSet($param) $vaEtxGenCfg(id$ip_ID,$param,Gen$port)
	}
	set vaEtxGenSet(svlanIDincr) [expr $vaEtxGenCfg(id$ip_ID,S_VLANincr,Gen$port)%4096]
	set vaEtxGenSet(svlanPincr) [expr $vaEtxGenCfg(id$ip_ID,S_VLANincr,Gen$port)/8192]

 	#Eth type and payload setup
	set vaEtxGenSet(EthFrameType) $vaEtxGenCfg(id$ip_ID,EthFrameType,Gen$port)
	if {$vaEtxGenSet(PacketType) == "MAC"} {
	  set vaEtxGenSet(payload)  ""
	  foreach pl {1 2 3 4 5} {
	    append vaEtxGenSet(payload) $vaEtxGenCfg(id$ip_ID,Payload$pl,Gen$port)
		}
	} elseif {$vaEtxGenSet(PacketType) == "VLAN"} {
	    set vaEtxGenSet(payload)  ""
		  foreach pl {1 2 3 4} {
		    append vaEtxGenSet(payload) $vaEtxGenCfg(id$ip_ID,Payload$pl,Gen$port)
			}
			append vaEtxGenSet(payload) [string range $vaEtxGenCfg(id$ip_ID,Payload5,Gen$port) 0 3 ]
	} elseif {$vaEtxGenSet(PacketType) == "SVLAN"} {
	    set vaEtxGenSet(payload)  ""
		  foreach pl {1 2 3} {
		    append vaEtxGenSet(payload) $vaEtxGenCfg(id$ip_ID,Payload$pl,Gen$port)
			}
			append vaEtxGenSet(payload) [string range $vaEtxGenCfg(id$ip_ID,Payload4,Gen$port) 0 7 ]
	} elseif {$vaEtxGenSet(PacketType) == "IP"} {
	    set vaEtxGenSet(payload)  ""
		  foreach pl {1} {
		    append vaEtxGenSet(payload) $vaEtxGenCfg(id$ip_ID,Payload$pl,Gen$port)
			}
			append vaEtxGenSet(payload) [string range $vaEtxGenCfg(id$ip_ID,Payload2,Gen$port) 0 7 ]
	} elseif {$vaEtxGenSet(PacketType) == "RAW"} {
		  set vaEtxGenSet(allpayload)  ""
		  foreach pl {1 2 3 4 5} {
		    append vaEtxGenSet(allpayload) $vaEtxGenCfg(id$ip_ID,Payload$pl,Gen$port)
			}
		  foreach pl {13-16 17-20 21-24 25-28 29-32 33-36 37-40 41-44}  rnge  {0 8 16 24 32 40 48 56} {
		    set vaEtxGenSet(raw$pl) [string range $vaEtxGenSet(allpayload) $rnge [expr $rnge + 7]]  
			}
	}
 	#IP setup
	foreach param {"IPtos" "IPttl" "IPidentific" "IPprotocol" "IPdestination" "IPsource"} {
		set vaEtxGenSet($param) $vaEtxGenCfg(id$ip_ID,$param,Gen$port)
	}


  if {$vaEtxGenCfg(id$ip_ID,etxRun) == 1} {
  	  set vaEtxGenSet(runstate) "Bert run..."
			$vaEtxGenGui(tb,run) configure -state disable 
			$vaEtxGenGui(tb,stop) configure -state normal 
  		#$vaEtxGenGui(runstate) configure -entryfg darkgreen
	} else {
  	  set vaEtxGenSet(runstate) "Stop"
			$vaEtxGenGui(tb,run) configure -state normal 
			$vaEtxGenGui(tb,stop) configure -state disable 
  		#$vaEtxGenGui(runstate) configure -entryfg red
	}

	FillEtxGenConfigState $ip_ID

	if {!([info exists vaEtxGenSet(id$ip_ID,etxRun)] && $vaEtxGenSet(id$ip_ID,etxRun))} {
	  DisableEnableEntries normal
		ChangeAutoneg
	}
	if {[info exists vaEtxGenSet(id$ip_ID,etxRun)] && $vaEtxGenSet(id$ip_ID,etxRun)} {
	  FillEtxGenStatistics $ip_ID
	  FillCollorStatistGenerator $ip_ID
	}
	$vaEtxGenGui(tb,save) configure -state disable
	update

}


# ................................................................................
#  Abstract: Fill  configuration page into Etx204A GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc FillEtxGenConfigState {ip_ID} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg

  foreach param {AdminStatus Autonegotiat MaxAdvSpeed EthSpeed GeneratorMode PacketType PacketMinLen PacketMaxLen ChainLength \
                 PacketRate EthFrameType DA_incr DA_StationNum DA_incrIdle SA_incr SA_StationNum SA_incrIdle VLAN_type \
								 C_VLANID C_VLANPbits C_VLANincr C_VLANincrNum C_VLANincrIdle S_VLANID S_VLANPbits S_VLANincr S_VLANincrNum \
								 S_VLANincrIdle IPtos IPttl IPidentific IPprotocol} {

		set RLEtxGen::vaEtxGenSet(configuration,state,$param) "\t"
		foreach port {1 2 3 4} {
		  append RLEtxGen::vaEtxGenSet(configuration,state,$param) $vaEtxGenCfg(id$ip_ID,$param,Gen$port)\t\t
		}
	}

  foreach param {DA SA  Payload1 Payload2 Payload3 Payload4 Payload5} {
		set RLEtxGen::vaEtxGenSet(configuration,state,$param) "\t"
		foreach port {1 2 3 4} {
		  append RLEtxGen::vaEtxGenSet(configuration,state,$param) $vaEtxGenCfg(id$ip_ID,$param,Gen$port)\t
		}
	}
  foreach param { IPdestination IPsource} {
		set RLEtxGen::vaEtxGenSet(configuration,state,$param) "\t"
		foreach port {1 2 3 4} {
		  if {[string length $vaEtxGenCfg(id$ip_ID,$param,Gen$port)] < 10} {
		    append RLEtxGen::vaEtxGenSet(configuration,state,$param) $vaEtxGenCfg(id$ip_ID,$param,Gen$port)\t\t
			} else {
		      append RLEtxGen::vaEtxGenSet(configuration,state,$param) $vaEtxGenCfg(id$ip_ID,$param,Gen$port)\t
			}
		}
	}

}

# ................................................................................
#  Abstract: Fill  statistics page into Etx204A GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc FillEtxGenStatistics {ip_ID} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg

	if {$vaEtxGenSet(currentid) == "" || $vaEtxGenSet(currentid) != $ip_ID} {
	  return
	}

	foreach param {"PRBS_OK" "PRBS_ERR" "FRAME_ERR" "FRAME_NOT_RECOGN" "SEQ_ERR" "ERR_CNT"\
                 "LINK_STATE" "SPEED" "TIME" "RCV_PPS" "RCV_BPS"} {

		 foreach {i} {1 2 3 4} {
			 set RLEtxGen::vaEtxGenSet(genstat,${param}$i) $vaEtxGenCfg(id$ip_ID,$param,Gen$i)
		 }
  }

}

# ................................................................................
#  Abstract: Fill color statistics page into Etx204A GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc FillCollorStatistGenerator {ip_ID} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg

	foreach param {"PRBS_ERR" "FRAME_ERR" "FRAME_NOT_RECOGN" "SEQ_ERR" "ERR_CNT"} {
	  foreach i {1 2 3 4} {
			if {$RLEtxGen::vaEtxGenSet(genstat,${param}$i) != 0} {
		    set error 1
			  $RLEtxGen::vaEtxGenGui(genstat,ent${param}$i) configure -entrybg #FFCCCC 
			} else {
			    $RLEtxGen::vaEtxGenGui(genstat,ent${param}$i) configure -entrybg white 
			}
		}
	}
  foreach i {1 2 3 4} {
		if {$RLEtxGen::vaEtxGenSet(genstat,PRBS_OK$i) == 0} {
		  set error 1
		  $RLEtxGen::vaEtxGenGui(genstat,entPRBS_OK$i) configure -entrybg #FFCCCC 
		} else {
		    $RLEtxGen::vaEtxGenGui(genstat,entPRBS_OK$i) configure -entrybg white 
		}
  }
	if {[info exists error]} {
	  if {!$vaEtxGenSet(id$ip_ID,error) && $vaEtxGenSet(id$ip_ID,clear,etxgen,counter) >= 2} {
			RLEtxGen::SendEmail "The ERROR ocurred in chassis $ip_ID"
		}
		$vaEtxGenGui(genstat,tools,clear) configure -bg red
		set vaEtxGenSet(id$ip_ID,error) 1
	}

}

# ................................................................................
#  Abstract: SetPacketType
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc SetPacketType {} {

  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

	catch {pack forget $vaEtxGenGui(packet_setup,Mac)}
	catch {pack forget $vaEtxGenGui(packet_setup,IP)}
	catch {pack forget $vaEtxGenGui(packet_setup,Vlan1)}
	catch {pack forget $vaEtxGenGui(packet_setup,Vlan2)}
	catch {pack forget $vaEtxGenGui(packet_setup,Raw)}

	switch -exact -- $vaEtxGenSet(PacketType) {
	
		 MAC {
		  pack $vaEtxGenGui(packet_setup,Mac) -anchor w	 -fill x

		 }
		 VLAN {
		  pack $vaEtxGenGui(packet_setup,Vlan1) -anchor w	 -fill x
      RLEtxGen::SaveChanges packet_setup VlanType
			set vaEtxGenSet(VlanType) onetagged
		 }
		 SVLAN  {
		  pack $vaEtxGenGui(packet_setup,Vlan2) -anchor w	 -fill x
      RLEtxGen::SaveChanges packet_setup VlanType
			set vaEtxGenSet(VlanType) stacked
		 }
		 IP   {
		  pack $vaEtxGenGui(packet_setup,IP) -anchor w	 -fill x

		 }
		 RAW  {
		  pack $vaEtxGenGui(packet_setup,Raw) -anchor w	 -fill x

		 }

		 default {
		  pack $vaEtxGenGui(packet_setup,Mac) -anchor w	 -fill x

		 }
	}

}

# ................................................................................
#  Abstract: ChangeAutoneg.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc ChangeAutoneg {} {
  global gMessage
	variable vaEtxGenStatuses
  variable vaEtxGenGui
  variable vaEtxGenSet
	variable vaEtxGenCfg

	if {$vaEtxGenSet(Autonegotiat) == "enbl"} {
    $vaEtxGenGui(general_setup,ports,maxadv) configure -state normal
		$vaEtxGenGui(general_setup,ports,ethspeed) configure -state disabled
	} else {
    $vaEtxGenGui(general_setup,ports,maxadv) configure -state disabled
		$vaEtxGenGui(general_setup,ports,ethspeed) configure -state normal
	}


}
# ................................................................................
#  Abstract: Selects EtxGen resource into EtxGen GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc SelectEtxGenResource {node} {
  global gMessage
	variable vaEtxGenStatuses
  variable vaEtxGenGui
  variable vaEtxGenSet
	variable vaEtxGenCfg

	if {$node == "Resources"} {
    $vaEtxGenGui(resources,list) selection set $node
  	set vaEtxGenSet(currentchass) $node
		set vaEtxGenSet(currentid) ""
	  return
	}
	$vaEtxGenGui(resources,list) configure -state disabled
	RLEtxGen::EtxGenshow_progdlg
	#puts $node
	set id [lindex [split $node :] 1]
	if {[regexp {[\d].[\d].} $vaEtxGenStatuses($id,address)]} {
      set chassadr "$node    $vaEtxGenStatuses($id,address)"
 	} else {
      set chassadr "$node    COM: $vaEtxGenStatuses($id,address)"
	}

	#if the selected node is in runing state I use the FillCurrentGuiEntries without get from chassis configuration.
	if {[info exists vaEtxGenSet(id$id,start)] && $vaEtxGenSet(id$id,start)} {
    $vaEtxGenGui(resources,list) selection set $node
  	set vaEtxGenSet(currentid) $id
  	set vaEtxGenSet(currentchass) $node
	  if {[winfo exists .topEtxGenGui]} {
  	  FillCurrentGuiEntries $id 
      DisableEnableEntries	disabled
		}
	  destroy .progress
  	$vaEtxGenGui(resources,list) configure -state normal
		return
	}

	if {[RLEtxGen::ChkConnect $id]} {
	  $vaEtxGenGui(resources,list) itemconfigure $node -fill red
    $vaEtxGenGui(resources,list) selection set $node
  	set vaEtxGenSet(currentchass) $node
	  destroy .progress
		tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::ChkConnect $id) procedure \n$gMessage" -title "Etx204A PRBS"
  	$vaEtxGenGui(resources,list) configure -state normal
    return    
	}
	#puts $node
	#if the selected node is the curent it isn't need to get from chassis configuration because it exist into array vaEtxGenCfg.
	if {$id == "$vaEtxGenSet(currentid)"} {
	  $vaEtxGenGui(resources,list) itemconfigure $node -fill darkgreen
    $vaEtxGenGui(resources,list) selection set $node
  	set vaEtxGenSet(currentchass) $node
  	$vaEtxGenGui(resources,list) configure -state normal
	  destroy .progress
		ClearConfigChanges
	  return
	}

	#puts $node
	set vaEtxGenSet(currentchass) chassis:$id
	set vaEtxGenSet(currentid) $id
	#if the selected node isn't the curent and its info doesn't exist into array vaEtxGenCfg  it is need to get from chassis it configuration.
	if {![info exists vaEtxGenCfg(id$id,linkType)] || $vaEtxGenStatuses($id,currScreen) == "na"} {
		if {[RLEtxGen::GetConfig $id  aCfgRes]} {
  	  $vaEtxGenGui(resources,list) itemconfigure $node -fill red
  	  destroy .progress
			tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::GetConfig $id) procedure \n$gMessage" -title "Etx204A PRBS"
	    return    
		}
		array set vaEtxGenCfg [array get aCfgRes]
	}
	if {[winfo exists .topEtxGenGui]} {
  	FillCurrentGuiEntries $id
		SetPacketType
 	  ClearConfigChanges
	  #FillCollorStatistGenerator $id
	}
  $vaEtxGenGui(resources,list) itemconfigure $node -fill darkgreen
  $vaEtxGenGui(resources,list) selection set $node
	$vaEtxGenGui(resources,list) configure -state normal
  destroy .progress
	#puts $node
}

# ................................................................................
#  Abstract: Sets link type into EtxGen GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc DelEtxGenResource {} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
	variable vaEtxGenCfg

	if {![info exists vaEtxGenSet(currentchass)] || $vaEtxGenSet(currentchass) == "Resources"} {
	  return
	}

  if {$vaEtxGenSet(runstate) != "Stop"} {
		tk_messageBox -icon error -type ok -message "The chassis is running stop it before remove it" -title "Etx204A PRBS"
    return    
	}
	set id [lindex [split $vaEtxGenSet(currentchass) :] 1]
	if {[RLEtxGen::Close $id]} {
		tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::Close $id) procedure \n$gMessage" -title "Etx204A PRBS"
    return    
	}
 	$vaEtxGenGui(resources,list) delete $vaEtxGenSet(currentchass)
	$vaEtxGenGui(resources,list) selection set Resources
	set vaEtxGenSet(currentchass) Resources
	set vaEtxGenSet(currentid)	Resources

  set names [array names vaEtxGenCfg id$id*]
  foreach name $names {
	  unset vaEtxGenCfg($name)
  }
}

# ................................................................................
#  Abstract: ClearEtxGenStatistics
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc ClearEtxGenStatistics {} {

  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

  if {[catch {expr int($vaEtxGenSet(currentid))}]} {
    tk_messageBox -icon error -type ok -message "Select the chassis to clear Generator statistics" -title "Etx204A PRBS"
	  return
  }

	set id $vaEtxGenSet(currentid)
	#set vaEtxGenSet(id$id,start) 1
	set vaEtxGenSet(id$id,clear,etxGen) 1

}

# ............................................................................................
#  Abstract: SaveConfigToFile
#  Inputs: 
#
#  Outputs: 
# ...........................................................................................
proc SaveConfigToFile {fileType} {

  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses


	if {$fileType == "cfg"} {
	  set cfgFile [tk_getSaveFile \
	        -initialdir [pwd] \
	        -filetypes {{ "CFG Files"   {.cfg }}} \
	        -title "Save Configuration As.." \
	        -parent . \
	        -defaultextension $fileType \
				  -initialfile EtxGenGui]

		set vaEtxGenSet(resources,list) ""
	  set reslist  [lrange [$vaEtxGenGui(resources,list) items] 1 end]
		if {$reslist != ""} {
			foreach chassis $reslist {
		  	set id [lindex [split $chassis :] 1]
	    	lappend vaEtxGenSet(resources,list) $vaEtxGenStatuses($id,address) $vaEtxGenStatuses($id,package)
			}
		} else {
		    tk_messageBox -icon error -type ok -message "There is no chassis in resources pane" -title "E1/T1 PRBS"
			  return
		}
	} else {
		  set cfgFile [tk_getSaveFile \
		        -initialdir [pwd] \
		        -filetypes {{ "CFG Files"   {.ini }}} \
		        -title "Save Configuration As.." \
		        -parent . \
		        -defaultextension $fileType \
					  -initialfile EtxGenGui]
	}

  #If the user selected "Cancel"
  if {$cfgFile == ""} {
    return 0
  }
  set idFile [ open $cfgFile w+ ]

	#Generator setup
	foreach param {"AdminStatus" "Autonegotiat" "GeneratorMode" "PacketType" "PacketMinLen" "PacketMaxLen" "ChainLength" "PacketRate"} {
		 if {[regexp {[A-Za-z0-9]} $vaEtxGenSet($param)]} {
				puts $idFile "set vaEtxGenSet($param) \"$vaEtxGenSet($param)\""
		 }
	}
	if {$vaEtxGenSet(Autonegotiat) == "enbl"} {
		if {[regexp {[A-Za-z0-9]} $vaEtxGenSet(MaxAdvSpeed)]} {
		  puts $idFile  "set vaEtxGenSet(MaxAdvSpeed) $vaEtxGenSet(MaxAdvSpeed)"
		}

	} else {
			if {[regexp {[A-Za-z0-9]} $vaEtxGenSet(EthSpeed)]} {
			  puts $idFile  "set vaEtxGenSet(EthSpeed) $vaEtxGenSet(EthSpeed)"
			}
	}
 	#Base DA/SA setup
	foreach param {"DA" "DA_incr" "DA_StationNum" "DA_incrIdle" "SA" "SA_incr" "SA_StationNum" "SA_incrIdle"} {
		 if {[regexp {[A-Za-z0-9]} $vaEtxGenSet($param)]} {
				puts $idFile "set vaEtxGenSet($param) \"$vaEtxGenSet($param)\""
		 }
	}

	if {[string match "*VLAN*" $vaEtxGenSet(PacketType)]} {
	 	#Vlan1 setup
		foreach param {"C_VLANID" "C_VLANPbits" "C_VLANincrNum" "C_VLANincrIdle"} {
		   if {$param == "C_VLANID" && $vaEtxGenSet(C_VLANID) == 0} {
				 continue
			 }
			 if {[regexp {[A-Za-z0-9]} $vaEtxGenSet($param)]} {
					puts $idFile "set vaEtxGenSet($param) \"$vaEtxGenSet($param)\""
			 }
		}
		if {[regexp {[A-Za-z0-9]} $vaEtxGenSet(cvlanIDincr)]} {
		   puts $idFile  "set vaEtxGenSet(cvlanIDincr) $vaEtxGenSet(cvlanIDincr)"
		}
		if {[regexp {[A-Za-z0-9]} $vaEtxGenSet(cvlanPincr)]} {
		  puts $idFile  "set vaEtxGenSet(cvlanPincr) $vaEtxGenSet(cvlanPincr)"
		}
	}

	if {$vaEtxGenSet(PacketType) == "SVLAN"} {
	 	#Vlan2 setup
		foreach param {"S_VLANID" "S_VLANPbits" "S_VLANincrNum" "S_VLANincrIdle"} {
		   if {$param == "S_VLANID" && $vaEtxGenSet(C_VLANID) == 0} {
				 continue
			 }
			 if {[regexp {[A-Za-z0-9]} $vaEtxGenSet($param)]} {
					puts $idFile "set vaEtxGenSet($param) \"$vaEtxGenSet($param)\""
			 }
		}
		if {[regexp {[A-Za-z0-9]} $vaEtxGenSet(svlanIDincr)]} {
		   puts $idFile  "set vaEtxGenSet(svlanIDincr) $vaEtxGenSet(svlanIDincr)"
		}
		if {[regexp {[A-Za-z0-9]} $vaEtxGenSet(svlanPincr)]} {
		  puts $idFile  "set vaEtxGenSet(svlanPincr) $vaEtxGenSet(svlanPincr)"
		}
	}

	if {$vaEtxGenSet(PacketType) != "RAW"} {
	 	#eth type and payload setup
		if {[regexp {[A-Za-z0-9]} $vaEtxGenSet(EthFrameType)]} {
		  puts $idFile  "set vaEtxGenSet(EthFrameType) $vaEtxGenSet(EthFrameType)"
		}
		if {[regexp {[A-Za-z0-9]} $vaEtxGenSet(payload)]} {
		  puts $idFile  "set vaEtxGenSet(payload) $vaEtxGenSet(payload)"
		}
  }
	if {$vaEtxGenSet(PacketType) == "IP"} {
	 	#IP setup
		foreach param {"IPtos" "IPttl" "IPidentific" "IPprotocol" "IPdestination" "IPsource"} {
			 if {[regexp {[A-Za-z0-9]} $vaEtxGenSet($param)]} {
					puts $idFile "set vaEtxGenSet($param) \"$vaEtxGenSet($param)\""
			 }
		}
	}

	if {$vaEtxGenSet(PacketType) == "RAW"} {
		foreach param {13-16 17-20 21-24 25-28 29-32 33-36 37-40 41-44} {
			 if {[regexp {[A-Za-z0-9]} $vaEtxGenSet(raw$param)]} {
					puts $idFile "set vaEtxGenSet(raw$param) \"$vaEtxGenSet(raw$param)\""
			 }
	  }
		foreach number {1 2 3 4 5 6} {
		   foreach udf {BaseValue IncrValue IncrSteps IncrIdle Offset Width} {
				 if {[regexp {[A-Za-z0-9]} $vaEtxGenSet(raw$udf$number)]} {
						puts $idFile "set vaEtxGenSet(raw$udf$number) \"$vaEtxGenSet(raw$udf$number)\""
				 }
			 }
		}
	}

	if {$fileType == "cfg"} {
		puts $idFile "set vaEtxGenSet(listIP) [list $vaEtxGenSet(listIP)]"
	  puts $idFile "set vaEtxGenSet(resources,list) \"$vaEtxGenSet(resources,list)\""
	}
  close $idFile
}

# ................................................................................
#  Abstract: ClearConfigChanges
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc ClearConfigChanges {} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

	set names [array names vaEtxGenSet change*]
  foreach name $names {
	  unset vaEtxGenSet($name)
  }
	$vaEtxGenGui(tb,save) configure -state disabled
}

# ................................................................................
#  Abstract: GetConfigFromFile
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc GetConfigFromFile {fileType} {

  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

	if {$fileType == "cfg"} {
	  set cfgFile [tk_getOpenFile \
	        -initialdir [pwd] \
	        -filetypes {{ "CFG Files"   {.cfg }}} \
	        -title "Open Configuration " \
	        -parent . \
	        -defaultextension cfg ]
	} else {
		  set cfgFile [tk_getOpenFile \
		        -initialdir [pwd] \
		        -filetypes {{ "CFG Files"   {.ini }}} \
		        -title "Save Configuration As.." \
		        -parent . \
		        -defaultextension $fileType \
					  -initialfile EtxGenGui]
  }      
  #If the user selected "Cancel"
  if {$cfgFile == ""} {
    return 0
  }

	#RLEtxGen::EtxGenshow_progdlg

	if {[RLEtxGen::ChkCfgFile $cfgFile]} {
    set gMessage "\n The file $cfgFile doesn't valid for EtxGen configuration"
		#destroy .progress
    tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::ChkCfgFile $cfgFile) procedure \n$gMessage" -title "Error EtxGen"
		return
	} else {
			source $cfgFile
	}
	$vaEtxGenGui(tb,save) configure -state normal

	if {$fileType == "ini"} {
		set id [open $cfgFile r]
		set vaEtxGenSet(inibuffer) [read $id]
		close	 $id
	
		foreach {param}      {general,port \
													ports,AdminStatus \
													ports,Autonegotiat \
													ports,MaxAdvSpeed \
													ports,EthSpeed \
													ports,portfactory \
													ports,save \
													generator,GeneratorMode \
													generator,PacketRate \
													generator,stream \
													generator,PacketMinLen \
													generator,PacketMaxLen \
													generator,ChainLength \
													packet_setup,PacketType \
													packet_setup,clrUdf \
													packet_setup,DA \
													packet_setup,DA_incr \
													packet_setup,DA_StationNum \
													packet_setup,DA_incrIdle \
													packet_setup,SA \
													packet_setup,SA_incr \
													packet_setup,SA_StationNum \
													packet_setup,SA_incrIdle \
													packet_setup,payload \
													packet_setup,EthFrameType \
													packet_setup,C_VLANID \
													packet_setup,C_VLANPbits \
													packet_setup,C_VLANincrNum \
													packet_setup,C_VLANincrIdle \
													packet_setup,S_VLANID \
													packet_setup,S_VLANPbits \
													packet_setup,S_VLANincrNum \
													packet_setup,S_VLANincrIdle \
													packet_setup,SVlanType \
													packet_setup,cvlanIDincr \
													packet_setup,cvlanPincr \
													packet_setup,svlanIDincr \
													packet_setup,svlanPincr \
													packet_setup,IPtos \
													packet_setup,IPttl \
													packet_setup,IPidentific \
													packet_setup,IPprotocol \
													packet_setup,IPdestination \
													packet_setup,IPsource \
													packet_setup,DA \
													packet_setup,SA \
													packet_setup,raw13-16 \
													packet_setup,raw17-20 \
													packet_setup,raw21-24 \
													packet_setup,raw25-28 \
													packet_setup,raw29-32 \
													packet_setup,raw33-36 \
													packet_setup,raw37-40 \
													packet_setup,raw41-44 \
	                        packet_setup,rawOffset1 \
													packet_setup,rawBaseValue1 \
													packet_setup,rawIncrValue1 \
													packet_setup,rawWidth1 \
													packet_setup,rawIncrIdle1 \
													packet_setup,rawIncrSteps1 \
	                        packet_setup,rawOffset2 \
													packet_setup,rawBaseValue2 \
													packet_setup,rawIncrValue2 \
													packet_setup,rawWidth2 \
													packet_setup,rawIncrIdle2 \
													packet_setup,rawIncrSteps2 \
	                        packet_setup,rawOffset3 \
													packet_setup,rawBaseValue3 \
													packet_setup,rawIncrValue3 \
													packet_setup,rawWidth3 \
													packet_setup,rawIncrIdle3 \
													packet_setup,rawIncrSteps3 \
	                        packet_setup,rawOffset4 \
													packet_setup,rawBaseValue4 \
													packet_setup,rawIncrValue4 \
													packet_setup,rawWidth4 \
													packet_setup,rawIncrIdle4 \
													packet_setup,rawIncrSteps4 \
	                        packet_setup,rawOffset5 \
													packet_setup,rawBaseValue5 \
													packet_setup,rawIncrValue5 \
													packet_setup,rawWidth5 \
													packet_setup,rawIncrIdle5 \
													packet_setup,rawIncrSteps5 \
	                        packet_setup,rawOffset6 \
													packet_setup,rawBaseValue6 \
													packet_setup,rawIncrValue6 \
													packet_setup,rawWidth6 \
													packet_setup,rawIncrIdle6 \
													packet_setup,rawIncrSteps6}  {

			set tile [lindex [split $param ,] 1]
			if {[string match "*$tile*" $vaEtxGenSet(inibuffer)]} {
	  	  set vaEtxGenSet(change,$param) 1
			}
		}
		SetPacketType
		ChangeAutoneg
	}
	if {$fileType == "cfg"} {
		set resources ""
	  set reslist  [lrange [$vaEtxGenGui(resources,list) items] 1 end]
		if {$reslist != ""} {
			foreach chassis $reslist {
		  	set id [lindex [split $chassis :] 1]
	    	lappend resources $vaEtxGenStatuses($id,address) $vaEtxGenStatuses($id,package)
			}
		}
		if {$vaEtxGenSet(resources,list) != ""} {
			foreach {address package} $vaEtxGenSet(resources,list) {
			  if {[lsearch $resources $address] == -1} {
				  OkConnChassis $address $package
					ClearConfigChanges
				}
			}
		}
	}
}

# ................................................................................
#  Abstract:  ChkCfgFile
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc  ChkCfgFile {ip_file} {
    set numbLine 0
    set fileId [open $ip_file r ]

    while	{[eof $fileId] != 1} {
	    set line [gets $fileId]
						#puts $line
  	  if {[string match "*set vaEtxGenSet*" $line ] == 0 && $line != "" } {
		   	return -1
			} else {
  		  	incr numbLine
					#puts $numbLine
		 	}
		}
    close $fileId
		#if {$numbLine <25} {
  	# 	return -1
		#}
	  return 0
}


# ................................................................................
#  Abstract: SaveConfigToChassis
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc SaveConfigToChassis {} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

  if {[catch {expr int($vaEtxGenSet(currentid))}]} {
    tk_messageBox -icon error -type ok -message "Select chassis to save configuration" -title "EtxGen"
	  return
  }
	RLEtxGen::EtxGenshow_progdlg
	#save port parameters
	set changelist ""
  foreach {change param val} [list general,port       -updGen        $vaEtxGenSet(port) \
																	 ports,AdminStatus	-admStatus	   $vaEtxGenSet(AdminStatus) \
																	 ports,Autonegotiat	-autoneg		   $vaEtxGenSet(Autonegotiat) \
																	 ports,MaxAdvSpeed	-maxAdvertize	 $vaEtxGenSet(MaxAdvSpeed) \
																	 ports,EthSpeed     -speed		     $vaEtxGenSet(EthSpeed) \
																	 ports,portfactory	-factory		   $vaEtxGenSet(portfactory) \
																	 ports,save	        -save		       $vaEtxGenSet(save)] {

		if {[info exists vaEtxGenSet(change,$change)]} {
			lappend changelist $param $val
		}
	}
	if {$changelist != ""} {
	  if {[eval RLEtxGen::PortsConfig $vaEtxGenSet(currentid) $changelist]} {
		  destroy .progress
      tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::PortsConfig $vaEtxGenSet(currentid)) procedure \n$gMessage" -title "EtxGen"
	    return
	  }
	}

	#save generator parameters
	set changelist ""
  foreach {change param val} [list general,port            -updGen   $vaEtxGenSet(port) \
																	 generator,GeneratorMode -genMode	 $vaEtxGenSet(GeneratorMode) \
																	 generator,PacketRate	   -packRate $vaEtxGenSet(PacketRate) \
																	 packet_setup,PacketType -packType $vaEtxGenSet(PacketType) \
																	 generator,stream	       -stream	 $vaEtxGenSet(stream) \
																	 generator,PacketMinLen  -minLen	 $vaEtxGenSet(PacketMinLen) \
																	 generator,PacketMaxLen  -maxLen	 $vaEtxGenSet(PacketMaxLen) \
																	 generator,genfactory    -factory	 $vaEtxGenSet(genfactory) \
																	 generator,ChainLength	 -chain		 $vaEtxGenSet(ChainLength)] {

		if {[info exists vaEtxGenSet(change,$change)]} {
			lappend changelist $param $val
		}
	}
	if {$changelist != ""} {
	  if {[eval RLEtxGen::GenConfig $vaEtxGenSet(currentid) $changelist]} {
		  destroy .progress
      tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::GenConfig $vaEtxGenSet(currentid)) procedure \n$gMessage" -title "EtxGen"
	    return
	  }
	}


	#save packet parameters(base DA/SA)
	set changelist ""
  foreach {change param val} [list general,port               -updGen      $vaEtxGenSet(port) \
																	 packet_setup,clrUdf				-clrUdf			 $vaEtxGenSet(clrUdf)  \
																	 packet_setup,DA					  -DA			     $vaEtxGenSet(DA)  \
																	 packet_setup,DA_incr			  -DAincrval	 $vaEtxGenSet(DA_incr)  \
																	 packet_setup,DA_StationNum	-DAincrsteps $vaEtxGenSet(DA_StationNum)  \
																	 packet_setup,DA_incrIdle		-DAincridle	 $vaEtxGenSet(DA_incrIdle)  \
																	 packet_setup,SA					  -SA			     $vaEtxGenSet(SA)  \
																	 packet_setup,SA_incr			  -SAincrval	 $vaEtxGenSet(SA_incr)  \
																	 packet_setup,SA_StationNum	-SAincrsteps $vaEtxGenSet(SA_StationNum)  \
																	 packet_setup,SA_incrIdle		-SAincridle	 $vaEtxGenSet(SA_incrIdle)  \
																	 packet_setup,payload				-payload		 $vaEtxGenSet(payload)] {

		if {[info exists vaEtxGenSet(change,$change)]} {
			lappend changelist $param $val
		}

	}

	if {$vaEtxGenSet(PacketType) == "MAC"} {
		if {[info exists vaEtxGenSet(change,packet_setup,EthFrameType)]} {
			lappend changelist -ethType $vaEtxGenSet(EthFrameType)
		}
	} elseif {[string match "*VLAN*" $vaEtxGenSet(PacketType)]} {
		  foreach {change param val} [list packet_setup,EthFrameType	 -ethType			   $vaEtxGenSet(EthFrameType)  \
																			 packet_setup,VlanType       -vlanType	     $vaEtxGenSet(VlanType) \
																			 packet_setup,C_VLANID			 -cvlanid	       $vaEtxGenSet(C_VLANID)  \
																			 packet_setup,C_VLANPbits	   -cvlanp         $vaEtxGenSet(C_VLANPbits)  \
																			 packet_setup,C_VLANincrNum	 -cvlanincrsteps $vaEtxGenSet(C_VLANincrNum)  \
																			 packet_setup,C_VLANincrIdle -cvlanincridle	 $vaEtxGenSet(C_VLANincrIdle) \
																			 packet_setup,S_VLANID			 -svlanid	       $vaEtxGenSet(S_VLANID)  \
																			 packet_setup,S_VLANPbits	   -svlanp         $vaEtxGenSet(S_VLANPbits)  \
																			 packet_setup,S_VLANincrNum	 -svlanincrsteps $vaEtxGenSet(S_VLANincrNum)  \
																			 packet_setup,S_VLANincrIdle -svlanincridle	 $vaEtxGenSet(S_VLANincrIdle) \
																			 packet_setup,SVlanType			 -svlantype	     $vaEtxGenSet(SVlanType)] {
		
				if {[info exists vaEtxGenSet(change,$change)]} {
					lappend changelist $param $val
				}
			}
			if {$vaEtxGenSet(PacketType) == "VLAN"} {
				#lappend changelist -vlanType onetagged
				catch {unset vaEtxGenSet(change,packet_setup,S_VLANID)}
				catch {unset vaEtxGenSet(change,packet_setup,SVlanType)}
				catch {unset vaEtxGenSet(change,packet_setup,S_VLANPbits)}
				catch {unset vaEtxGenSet(change,packet_setup,S_VLANincrNum)}
				catch {unset vaEtxGenSet(change,packet_setup,S_VLANincrIdle)}
				catch {unset vaEtxGenSet(change,packet_setup,svlanIDincr)}
				if {[info exists vaEtxGenSet(change,packet_setup,cvlanIDincr)] || [info exists vaEtxGenSet(change,packet_setup,cvlanPincr)]} {
				  lappend changelist -cvlanincr [expr $vaEtxGenSet(cvlanIDincr) + 8192*$vaEtxGenSet(cvlanPincr)]
				}
				if {[info exists vaEtxGenSet(change,packet_setup,VlanType)]} {
				  set vaEtxGenSet(VlanType) onetagged
				}
			} else {
					if {[info exists vaEtxGenSet(change,packet_setup,cvlanIDincr)] || [info exists vaEtxGenSet(change,packet_setup,cvlanPincr)]} {
					  lappend changelist -cvlanincr [expr $vaEtxGenSet(cvlanIDincr) + 8192*$vaEtxGenSet(cvlanPincr)]
					}
					if {[info exists vaEtxGenSet(change,packet_setup,svlanIDincr)] || [info exists vaEtxGenSet(change,packet_setup,svlanPincr)]} {
				    #lappend changelist -vlanType stacked
					  lappend changelist -svlanincr [expr $vaEtxGenSet(svlanIDincr) + 8192*$vaEtxGenSet(svlanPincr)]
					}
				  if {[info exists vaEtxGenSet(change,packet_setup,VlanType)]} {
				    set vaEtxGenSet(VlanType) stacked
				  }
			}
	} elseif {$vaEtxGenSet(PacketType) == "IP"} {
		  foreach {change param val} [list packet_setup,IPtos				  -tos      $vaEtxGenSet(IPtos)  \
																			 packet_setup,IPttl			    -ttl     $vaEtxGenSet(IPttl)  \
																			 packet_setup,IPidentific	  -identif  $vaEtxGenSet(IPidentific)  \
																			 packet_setup,IPprotocol	  -protocol $vaEtxGenSet(IPprotocol)  \
																			 packet_setup,IPdestination -destinip $vaEtxGenSet(IPdestination) \
																			 packet_setup,IPsource			-sourceip $vaEtxGenSet(IPsource)] {
		
				if {[info exists vaEtxGenSet(change,$change)]} {
					lappend changelist $param $val
				}
			}
	}

	if {($changelist != "" || [info exists vaEtxGenSet(change,packet_setup,PacketType)]) && $vaEtxGenSet(PacketType) != "RAW"} {
	  if {[eval RLEtxGen::PacketConfig $vaEtxGenSet(currentid) $vaEtxGenSet(PacketType) $changelist]} {
		  destroy .progress
      tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::PacketConfig $vaEtxGenSet(currentid)) procedure \n$gMessage" -title "EtxGen"
	    return
	  }
	}

  #save RAWpacket parameters
  if {$vaEtxGenSet(PacketType) == "RAW"} {
	  set changelist ""
    foreach {change param val} [list general,port             -updGen      $vaEtxGenSet(port) \
	 																 packet_setup,clrUdf        -clrUdf      $vaEtxGenSet(clrUdf)  \
	 																 packet_setup,DA            -DA          $vaEtxGenSet(DA)  \
	 																 packet_setup,SA            -SA          $vaEtxGenSet(SA)  \
	 																 packet_setup,raw13-16		  -field1      $vaEtxGenSet(raw13-16)  \
	 																 packet_setup,raw17-20		  -field2      $vaEtxGenSet(raw17-20)  \
	 																 packet_setup,raw21-24		  -field3      $vaEtxGenSet(raw21-24)  \
	 																 packet_setup,raw25-28		  -field4      $vaEtxGenSet(raw25-28)  \
	 																 packet_setup,raw29-32		  -field5      $vaEtxGenSet(raw29-32)  \
	 																 packet_setup,raw33-36		  -field6      $vaEtxGenSet(raw33-36)  \
	 																 packet_setup,raw37-40		  -field7      $vaEtxGenSet(raw37-40)  \
	 																 packet_setup,raw41-44		  -field8      $vaEtxGenSet(raw41-44)] {
	  
	    if {[info exists vaEtxGenSet(change,$change)]} {
	 	    lappend changelist $param $val
	    }

    }
	  if {$changelist != "" || $vaEtxGenSet(PacketType) == "RAW"} {
	    if {[eval RLEtxGen::RawPacketConfig $vaEtxGenSet(currentid) $changelist]} {
		    destroy .progress
        tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::RawPacketConfig $vaEtxGenSet(currentid) payloads) procedure \n$gMessage" -title "EtxGen"
	      return
	    }
	  }

	  foreach udf {1 2 3 4 5 6} {
	    set changelist ""
	    foreach {change param val} [list packet_setup,rawOffset$udf	   -offset		 $vaEtxGenSet(rawOffset$udf)  \
		 																 packet_setup,rawBaseValue$udf   -bvalue		 $vaEtxGenSet(rawBaseValue$udf)  \
		 																 packet_setup,rawIncrValue$udf   -incr	     $vaEtxGenSet(rawIncrValue$udf)  \
		 																 packet_setup,rawWidth$udf		   -width	     $vaEtxGenSet(rawWidth$udf)  \
		 																 packet_setup,rawIncrIdle$udf	   -idle	     $vaEtxGenSet(rawIncrIdle$udf)  \
		 																 packet_setup,rawIncrSteps$udf   -steps	     $vaEtxGenSet(rawIncrSteps$udf)] {
		  
		 	  if {[info exists vaEtxGenSet(change,$change)]} {
		 		  lappend changelist $param $val
		 	  }
	
		  }

		  if {$changelist != ""} {
		 	  lappend changelist -udf $udf
		    if {[eval RLEtxGen::RawPacketConfig $vaEtxGenSet(currentid) $changelist]} {
			    destroy .progress
	        tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::RawPacketConfig $vaEtxGenSet(currentid) udf $udf) procedure \n$gMessage" -title "EtxGen"
		      return
		    }
		  }
	  }

  }

  set names [array names vaEtxGenSet change*]
  foreach name $names {
	  unset vaEtxGenSet($name)
  }

	#Get from chassis the configuration to update vaEtxGenCfg array.
	if {[RLEtxGen::GetConfig $vaEtxGenSet(currentid)  aCfgRes]} {
	  #$vaEtxGenGui(resources,list) itemconfigure $node -fill red
	  destroy .progress
		tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::GetConfig $vaEtxGenSet(currentid)) procedure \n$gMessage" -title "EtxGen"
    return    
	}
	array set vaEtxGenCfg [array get aCfgRes]

	$vaEtxGenGui(tb,save) configure -state disable

	FillCurrentGuiEntries $vaEtxGenSet(currentid) 
  RunCurrentChassis $vaEtxGenSet(currentid)
	destroy .progress

}


# ................................................................................
#  Abstract: GetHelp
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc GetHelp {} {
  global env
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

	if {[regexp -nocase {RLEtxGen.exe} $vaEtxGenSet(rundir) match]} {
  	set path	EtxGenHelp.chm
	} else {
    	set path	$vaEtxGenSet(rundir)/EtxGenHelp.chm
	}

  set comspec [set env(COMSPEC)]
 
  #exec $comspec /c start $path
}

#..................................................................................
#  Abstract:  RunCurrentChassis
#  Inputs: 	 
#						 id   id of chassis
#
#  Outputs: 
#..................................................................................
proc RunCurrentChassis {id {clear ""}} {

  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

	$vaEtxGenGui(tb,run) configure -state disable 
	$vaEtxGenGui(tb,stop) configure -state normal
 
	if {$clear == ""} {
    set vaEtxGenSet(id$id,clear,etxgen,counter) 0
	} else {
      set vaEtxGenSet(id$id,clear,etxgen,counter) 10
	}
	set vaEtxGenSet(id$id,error) 0

  if {[catch {expr int($id)}]} {
		$vaEtxGenGui(tb,run) configure -state  normal
		$vaEtxGenGui(tb,stop) configure -state disable 
    tk_messageBox -icon error -type ok -message "Select the chassis to run it" -title "Etx204A Generator"
	  return
  }

	if {[$vaEtxGenGui(tb,save) cget -state] == "normal"} {
		$vaEtxGenGui(tb,run) configure -state  normal
		$vaEtxGenGui(tb,stop) configure -state disable 
    tk_messageBox -icon error -type ok -message "Save configuration to chassis before to run it or select it again" -title "Etx204A Generator"
	  return
	}

	if {[RLEtxGen::Start $id]} {
		$vaEtxGenGui(tb,run) configure -state  normal
		$vaEtxGenGui(tb,stop) configure -state disable 
		tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::Start $id) procedure \n$gMessage" -title "Etx204A Generator"
	  return
	}

	DisableEnableEntries	disabled
  set vaEtxGenSet(runstate) "Etx204A run..."
	set vaEtxGenCfg(id$id,etxRun) 1
  #$vaEtxGenGui(runstate) configure -entryfg darkgreen

	if {[winfo exists .topEtxGenGui]} {
  	FillGuiIndicators run
	}
	set vaEtxGenSet(id$id,start) 1
	after 100 RLEtxGen::ReadChassisStatistics $id
}

# ................................................................................
#  Abstract: ReadChassisStatistics
#  Inputs: 	 	 id   id of chassis
#
#  Outputs: 
# ................................................................................
proc ReadChassisStatistics {id} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

  #puts "Rinning $id"

	if {![winfo exists .topEtxGenGui]} {
  	return
	}

	if {!$vaEtxGenSet(id$id,start)} {
		if {[RLEtxGen::Stop $id]} {
			tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::Stop $id) procedure \n$gMessage" -title "Etx204A Generator"
		}
		#puts "1 $id"
		$vaEtxGenGui(tb,run) configure -state  normal
		$vaEtxGenGui(tb,stop) configure -state disable 
	  set vaEtxGenSet(runstate) "Stop"
	  set vaEtxGenCfg(id$id,etxRun) 0
	  #$vaEtxGenGui(runstate) configure -entryfg red
		return
	}
	#clear all statist at begin of running after 2 seconds
  incr vaEtxGenSet(id$id,clear,etxgen,counter)
	if {$vaEtxGenSet(id$id,clear,etxgen,counter) == 2} {
		if {[RLEtxGen::Clear $id]} {
			tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::Clear $id ) procedure \n$gMessage" -title "Etx204A Generator"
		}
		set vaEtxGenSet(id$id,error) 0
		$vaEtxGenGui(genstat,tools,clear) configure -bg SystemButtonFace
	}

  if {[info exists vaEtxGenSet(id$id,clear,etxGen)]} {
		if {[RLEtxGen::Clear $id]} {
			tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::Clear $id ) procedure \n$gMessage" -title "Etx204A Generator"
		}
		$vaEtxGenGui(genstat,tools,clear) configure -bg SystemButtonFace
		set vaEtxGenSet(id$id,error) 0
		catch {unset vaEtxGenSet(id$id,clear,etxGen)}
	}


	if {!$vaEtxGenSet(id$id,start)} {
		if {[RLEtxGen::Stop $id]} {
			tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::Stop $id) procedure \n$gMessage" -title "Etx204A Generator"
		}
		$vaEtxGenGui(tb,run) configure -state  normal
		$vaEtxGenGui(tb,stop) configure -state disable 
	  set vaEtxGenSet(runstate) "Stop"
	  #$vaEtxGenGui(runstate) configure -entryfg red
	  set vaEtxGenCfg(id$id,etxRun) 0
		return
	}

	if {[RLEtxGen::GetStatistics $id  aResStat]} {
	  RLEtxGen::Delay 3
		puts "[RLEtxGen::TimeDate]  Error while (RLEtxGen::GetStatistics $id) procedure \n$gMessage"
	  if {[RLEtxGen::GetStatistics $id  aResStat]} {
		  tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::GetStatistics $id) procedure \n$gMessage" -title "Etx204A Generator"
		}
	}

	if {!$vaEtxGenSet(id$id,start)} {
		if {[RLEtxGen::Stop $id]} {
			tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::Stop $id) procedure \n$gMessage" -title "Etx204A Generator"
		}
		$vaEtxGenGui(tb,run) configure -state  normal
		$vaEtxGenGui(tb,stop) configure -state disable 
	  set vaEtxGenSet(runstate) "Stop"
	  set vaEtxGenCfg(id$id,etxRun) 0
	  #$vaEtxGenGui(runstate) configure -entryfg red
		return
	}

	if {[winfo exists .topEtxGenGui]} {
  	FillGuiIndicators run
	}

	array set vaEtxGenCfg [array get aResStat]
  if {[winfo exists .topEtxGenGui]} {
	  FillEtxGenStatistics	 $id
	}

	if {![winfo exists .topEtxGenGui]} {
  	return
	}

	if {!$vaEtxGenSet(id$id,start)} {
		if {[RLEtxGen::Stop $id]} {
			tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::Stop $id) procedure \n$gMessage" -title "Etx204A Generator"
		}
		$vaEtxGenGui(tb,run) configure -state  normal
		$vaEtxGenGui(tb,stop) configure -state disable 
	  set vaEtxGenSet(runstate) "Stop"
	  set vaEtxGenCfg(id$id,etxRun) 0
	  #$vaEtxGenGui(runstate) configure -entryfg red
		return
	}
	FillCollorStatistGenerator $id
	after 1000 RLEtxGen::ReadChassisStatistics $id
	update
}


# ................................................................................
#  Abstract: StopCurrentChassis
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc StopCurrentChassis {id} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

  if {[catch {expr int($id)}]} {
    tk_messageBox -icon error -type ok -message "Select the chassis to stop it" -title "Etx204A Generator"
	  return
  }
	#$vaEtxGenGui(tb,run) configure -state  normal (get normal state into ReadChassisStatistics  procedure)
	$vaEtxGenGui(tb,stop) configure -state disable 
  DisableEnableEntries normal
	ChangeAutoneg
	$vaEtxGenGui(tb,save) configure -state disable

	set vaEtxGenSet(id$id,start) 0
	set vaEtxGenCfg(id$id,etxRun) 0

	if {[winfo exists .topEtxGenGui]} {
  	FillGuiIndicators stop
	}
}

# ................................................................................
#  Abstract: FillGuiIndicators
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc FillGuiIndicators {param} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

  set reslist  [lrange [$vaEtxGenGui(resources,list) items] 1 end]

 	foreach chassis $reslist {
  	set id [lindex [split $chassis :] 1]
		if {[info exists vaEtxGenSet(id$id,start)] && $vaEtxGenSet(id$id,start)} {
		  set runid $id
		}
	}
	if {[info exists runid] && $param == "run"} {
	  $vaEtxGenGui(runTime) configure -text "Run time [RLEtxGen::TimeDate]"
		$vaEtxGenGui(runStatus) configure	 -text "At least one Chassis is running"
	} elseif {![info exists runid] && $param == "run"} {
			$vaEtxGenGui(startTime) configure	 -text "Start time [RLEtxGen::TimeDate]"
			$vaEtxGenGui(runStatus) configure	 -text "Chassis is running"
	    set vaEtxGenSet(startTime) [clock seconds]
	} elseif {![info exists runid] && $param == "stop"} {
		  $vaEtxGenGui(runTime) configure -text "Run time [RLEtxGen::TimeDate]"
			$vaEtxGenGui(runStatus) configure	 -text "Chassis was stoped"
	}
}

 
# ................................................................................
#  Abstract: DisableEnableEntries
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc DisableEnableEntries {param} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

	foreach entry $vaEtxGenSet(lDisabledEntries) {
		 #puts $entry
		 $entry configure -state $param
	}
	.topEtxGenGui.mainframe setmenustate getcfgfile $param
	.topEtxGenGui.mainframe setmenustate savecfgfile $param
	.topEtxGenGui.mainframe setmenustate getguicfgfile $param
	.topEtxGenGui.mainframe setmenustate saveguicfgfile $param
	.topEtxGenGui.mainframe setmenustate savecfgchass $param
	.topEtxGenGui.mainframe setmenustate exit $param
	.topEtxGenGui.mainframe setmenustate run $param
	.topEtxGenGui.mainframe setmenustate connect $param
	.topEtxGenGui.mainframe setmenustate disconnect $param
	.topEtxGenGui.mainframe setmenustate portsFactory $param
	.topEtxGenGui.mainframe setmenustate portsSave $param
	.topEtxGenGui.mainframe setmenustate reset $param
	.topEtxGenGui.mainframe setmenustate email $param

}
	 	  
# ................................................................................
#  Abstract: RunAllChassis
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc RunAllChassis {} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses


  set reslist  [lrange [$vaEtxGenGui(resources,list) items] 1 end]
	if {$reslist == ""} {
    tk_messageBox -icon error -type ok -message "There aren't chassis to run its" -title "Etx204A Generator"
	  return
	}

	RLEtxGen::EtxGenshow_progdlg
	$vaEtxGenGui(resources,list) configure -state disabled

	foreach chassis $reslist {
  	set id [lindex [split $chassis :] 1]
		if {![info exists vaEtxGenSet(id$id,start)] || !$vaEtxGenSet(id$id,start)} {
			$vaEtxGenGui(resources,list) selection set $chassis
		  RunCurrentChassis $id
		}
	}
  destroy .progress
	RLEtxGen::SelectEtxGenResource chassis:1
 	$vaEtxGenGui(resources,list) configure -state normal
}

# ................................................................................
#  Abstract: StopAllChassis
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc StopAllChassis {} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

  set reslist  [lrange [$vaEtxGenGui(resources,list) items] 1 end]
	if {$reslist == ""} {
   # tk_messageBox -icon error -type ok -message "There aren't chassis to stop its" -title "Etx204A Generator"
	  return
	}
	RLEtxGen::EtxGenshow_progdlg
	$vaEtxGenGui(resources,list) configure -state disabled
	foreach chassis $reslist {
  	set id [lindex [split $chassis :] 1]
		if {[info exists vaEtxGenSet(id$id,start)] && $vaEtxGenSet(id$id,start)} {
			$vaEtxGenGui(resources,list) selection set $chassis
  		StopCurrentChassis $id
			#puts "stop $id"
		}
	}
  destroy .progress
 	$vaEtxGenGui(resources,list) configure -state normal
}


# ................................................................................
#  Abstract: FactoryEtxGen
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc FactoryEtx {param val} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

  if {[catch {expr int($vaEtxGenSet(currentid))}]} {
    tk_messageBox -icon error -type ok -message "Select chassis to set $param" -title "Etx204A Generator"
	  return
  }

	if {$param == "-reset" && $vaEtxGenStatuses($vaEtxGenSet(currentid),package) == "RLPlink"} {
    set res [tk_messageBox -icon warning -type ok -message "The \"Set reset\" action causes the chassis handled by telnet to be disconnected from telnet!!!!!" -title "Etx204A Generator"]
		return
	} elseif {$vaEtxGenStatuses($vaEtxGenSet(currentid),package) == "RLPlink"} {
      set res [tk_messageBox -icon warning -type yesno -message "The \"Set $param\" action causes the chassis handled by telnet, be disconnected from telnet!!!!! \n \
			After this action you must disconnect and again connect chassis by resources pane\n Press Yes to confirm" -title "Etx204A Generator"]
			if {$res == "no"} {
				return
			}
	}


 	set id $vaEtxGenSet(currentid) 

	$vaEtxGenGui(resources,list) configure -state disabled

	RLEtxGen::EtxGenshow_progdlg
  if {[RLEtxGen::PortsConfig $vaEtxGenSet(currentid) $param $val]} {
    destroy .progress
  	$vaEtxGenGui(resources,list) configure -state normal
    tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::PortsConfig $vaEtxGenSet(currentid)) procedure \n$gMessage" -title "Etx204A Generator"
    return
  }

  set names [array names vaEtxGenSet change*]
  foreach name $names {
	  unset vaEtxGenSet($name)
  }

	if {$param == "-reset"} {
	  tk_messageBox -icon warning -type ok -message "Please wait after RESET and press OK when reboot will be completed......." -title "Etx204A Generator"
	}
	if {[RLEtxGen::ChkConnect $id]} {
	  $vaEtxGenGui(resources,list) itemconfigure $vaEtxGenSet(currentchass) -fill red
	  destroy .progress
		tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::ChkConnect $id) procedure \n$gMessage" -title "Etx204A Generator"
  	$vaEtxGenGui(resources,list) configure -state normal
    return    
	}

	#Get from chassis the configuration to update vaEtxGenCfg array.
	if {[RLEtxGen::GetConfig $vaEtxGenSet(currentid)  aCfgRes]} {
	  #$vaEtxGenGui(resources,list) itemconfigure $node -fill red
	  destroy .progress
  	$vaEtxGenGui(resources,list) configure -state normal
		tk_messageBox -icon error -type ok -message "Error while (RLEtxGen::GetConfig $vaEtxGenSet(currentid)) procedure \n$gMessage" -title "Etx204A Generator"
    return    
	}
	array set vaEtxGenCfg [array get aCfgRes]
 	$vaEtxGenGui(resources,list) configure -state normal

	$vaEtxGenGui(tb,save) configure -state disable

	FillCurrentGuiEntries $vaEtxGenSet(currentid) 
  RunCurrentChassis $vaEtxGenSet(currentid)
	destroy .progress
}


# ................................................................................
#  Abstract:   Quit application.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc Quit {} {
  catch {exec taskkill.exe /im plink.exe  /f  /t}
	exit
}

# ................................................................................
#  Abstract: Create introduction GUI while building main ETX204A generator GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc _create_intro { } {

  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet

  set top [toplevel .intro -relief raised -borderwidth 2]

  wm withdraw $top
  wm overrideredirect $top 1

  set ximg  [label $top.x -bitmap @$vaEtxGenSet(rundir)/Images/x1.xbm \
    -foreground grey90 -background white]
  set bwimg [label $ximg.bw -bitmap @$vaEtxGenSet(rundir)/Images/bwidget.xbm \
    -foreground grey90 -background white]
  set frame [frame $ximg.f -background white]
  set lab1  [label $frame.lab1 -text "Loading ETX204A generator GUI" \
    -background white -font {times 8}]
  set lab2  [label $frame.lab2 -textvariable vaEtxGenSet(prgtext) \
    -background white -font {times 8} -width 35]
  set prg   [ProgressBar $frame.prg -width 50 -height 10 -background white \
    -variable vaEtxGenSet(prgindic) -maximum 10]
  pack $lab1 $lab2 $prg
  place $frame -x 0 -y 0 -anchor nw
  place $bwimg -relx 1 -rely 1 -anchor se
  pack $ximg
  BWidget::place $top 0 0 center
  wm deiconify $top
}

# ................................................................................
#  Abstract: SaveChanges
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc SaveChanges {type param {fromCfgEtxGen 0}} {

  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

	puts "$type $param"

	if {$fromCfgEtxGen} {
	  set vaEtxGenSet(change,$type,$param) 1
		if {!($vaEtxGenSet(currentid) != "" && $vaEtxGenSet(currentid) != "Resourses" && \
		    [info exists vaEtxGenSet(id$vaEtxGenSet(currentid),start)] && $vaEtxGenSet(id$vaEtxGenSet(currentid),start))} {
	    $vaEtxGenGui(tb,save) configure -state normal
		}
	} else {
	    set vaEtxGenSet(change,$type,$param) 1
	    $vaEtxGenGui(tb,save) configure -state normal
	}
}


# ................................................................................
#  Abstract: Create Generator statistics into EtxGen GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc GeneralGeneratorStatistics {} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet

    set vaEtxGenGui(genstat) [TitleFrame $vaEtxGenGui(statistics).genstat -text "General Statistics"]
		  set genstatfr [$vaEtxGenGui(genstat) getframe]
			set lablesfr [frame $genstatfr.lablesfr]
	      set labbert  [label $lablesfr.labbert -text "\t\t\t    Gen 1\t\t    Gen 2\t\t    Gen 3\t\t    Gen 4" ]
				pack $labbert	-anchor w
			pack $lablesfr -anchor w

			  foreach param {PRBS_OK PRBS_ERR FRAME_ERR FRAME_NOT_RECOGN SEQ_ERR ERR_CNT LINK_STATE SPEED TIME RCV_PPS RCV_BPS} {
				  set vaEtxGenGui(genstat,$param) [frame $genstatfr.ent$param]
				    set vaEtxGenGui(genstat,lb$param) [LabelEntry $vaEtxGenGui(genstat,$param).ent$param -label "" -width 15 -text $param  \
					                                     -justify left -editable 0 -entrybg lightgray -relief flat]
					  pack $vaEtxGenGui(genstat,lb$param) -anchor w -side left -padx 10
					  for {set i 1} {$i <=4} {incr i} {
					    set vaEtxGenGui(genstat,ent${param}$i) [LabelEntry $vaEtxGenGui(genstat,$param).entryGen$i -label "" -width 12 \
						                      -textvariable RLEtxGen::vaEtxGenSet(genstat,${param}$i) -editable 0 -justify center]
						  pack $vaEtxGenGui(genstat,ent${param}$i) -side left -padx 10
					  }

				  pack $vaEtxGenGui(genstat,$param) -anchor w -pady 4
			  }
}


# ................................................................................
#  Abstract: Create GeneralConfigState into EtxGen GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc GeneralConfigState {} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet

  set vaEtxGenGui(configuration,state) [TitleFrame $vaEtxGenGui(configuration).state -text "Current Chassis Configuration Parameters"]
    set currParamFr [$vaEtxGenGui(configuration,state) getframe]

		set vaEtxGenGui(configuration,state,label) [Entry $currParamFr.lb -width 106 -textvariable RLEtxGen::vaEtxGenSet(configuration,state,label) \
		                                         -relief flat -editable 0 -bg lightgray] 
		 
    set vaEtxGenSet(configuration,state,label) "\t\t\t    Gen 1\t\t    Gen 2\t\t     Gen 3\t\t    Gen 4"

		pack $vaEtxGenGui(configuration,state,label)	 -anchor w

      set swcurrParamFr [ScrolledWindow $currParamFr.sw -relief sunken -borderwidth 2]
        set sfcurrParamFr [ScrollableFrame $swcurrParamFr.sf -height 370]
        $swcurrParamFr setwidget $sfcurrParamFr
	      $sfcurrParamFr configure -constrainedwidth 1
        set subfrcurrParamFr [$sfcurrParamFr getframe]


     pack $swcurrParamFr -fill both -expand yes

		  foreach param {AdminStatus Autonegotiat MaxAdvSpeed EthSpeed GeneratorMode PacketType PacketMinLen PacketMaxLen ChainLength \
	                   PacketRate EthFrameType DA DA_incr DA_StationNum DA_incrIdle SA SA_incr SA_StationNum SA_incrIdle VLAN_type \
										 C_VLANID C_VLANPbits C_VLANincr C_VLANincrNum C_VLANincrIdle S_VLANID S_VLANPbits S_VLANincr S_VLANincrNum \
										 S_VLANincrIdle IPtos IPttl IPidentific IPprotocol IPdestination IPsource Payload1 Payload2 Payload3 Payload4 Payload5} {
			  set subsubparamFr [frame $subfrcurrParamFr.fr$param]
				set vaEtxGenGui(configuration,state,lb$param) [LabelEntry $subsubparamFr.lb$param -label "" -width 16 -text "$param"  \
				  	 -justify center -editable 0 -entrybg lightgray -relief flat]
				pack $vaEtxGenGui(configuration,state,lb$param) -side left -padx 2
				set vaEtxGenGui(configuration,state,$param) [LabelEntry $subsubparamFr.entry$param -width 90  -label "" -justify left \
					                     -textvariable RLEtxGen::vaEtxGenSet(configuration,state,$param) -relief flat -editable 0]
				pack $vaEtxGenGui(configuration,state,$param) -side left -padx 3
				pack $subsubparamFr -pady 3
			}

}


# ................................................................................
#  Abstract: Close EtxGen GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc CloseEtxGenGui {} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses

	if {!$vaEtxGenSet(closeByDestroy)} {
    destroy .topEtxGenGui
 	  return
	}

  set reslist  [lrange [$vaEtxGenGui(resources,list) items] 1 end]
	if {$reslist == ""} {
    destroy .topEtxGenGui 
		exit
	} else {
	    destroy .topEtxGenGui 
  	  RLEtxGen::CloseAll
			exit
	}

}

# ***************************************************************************
# EtxGenEmailSet
# ***************************************************************************
proc EtxGenEmailSet {base} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
	variable vaEtxGenStatuses
  
  if {[winfo exists $base]} {
    wm deiconify $base
    return
  }
  
  toplevel $base
  focus -force $base
  wm protocol $base WM_DELETE_WINDOW "wm attribute $base -topmost 0 ; destroy $base ; RLEtxGen::InitFileEmail"
  wm focusmodel $base passive
  wm overrideredirect $base 0
  wm resizable $base 0 0
  wm deiconify $base
  wm title $base "Send Results to..."
  wm attribute $base -topmost 1
    
  if {[file exists InitEmail.tcl]} {
    source InitEmail.tcl
  }  
    
  set vaEtxGenGui(labMail) [Label $base.labMail -text "Emails" -font {{} 10 {bold underline}}]
  pack $vaEtxGenGui(labMail) -side top -pady 2 -padx 4 -anchor w
  for {set i 1} {$i<=$vaEtxGenSet(EmailSum)} {incr i} {
    set vaEtxGenGui(fraMail.$i) [frame $base.fraMail$i]
      set vaEtxGenGui(entMail.$i) [Entry $vaEtxGenGui(fraMail.$i).entMail$i \
      -width 18 -textvariable RLEtxGen::vaEtxGenSet(Email.$i)]
      set vaEtxGenGui(cbMail.$i) [checkbutton $vaEtxGenGui(fraMail.$i).cbMail$i \
      -text ".$i" -variable RLEtxGen::vaEtxGenSet(chbutEmail.$i) -command "RLEtxGen::ActivateMail"]      
      pack $vaEtxGenGui(cbMail.$i) $vaEtxGenGui(entMail.$i) -side right -padx 4 -pady 2
    pack $vaEtxGenGui(fraMail.$i) -side top -pady 2 -padx 4 -anchor w
  }  
  RLEtxGen::ActivateMail   
}

# ***************************************************************************
# ActivateMail
# ***************************************************************************
proc ActivateMail {} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
	variable vaEtxGenStatuses
  for {set i 1} {$i<=$vaEtxGenSet(EmailSum)} {incr i} {
    if {[set vaEtxGenSet(chbutEmail.$i)]==0} {
      [set vaEtxGenGui(entMail.$i)] configure -state disabled
    } else {
      [set vaEtxGenGui(entMail.$i)] configure -state normal
    }
  }
}

#***************************************************************************
##** InitFileEmail +
##***************************************************************************
proc InitFileEmail {} {
  global gMessage
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses
  set fileId [open InitEmail.tcl w]
  seek $fileId 0 start
  for {set i 1} {$i<=$vaEtxGenSet(EmailSum)} {incr i} {
    puts $fileId "set vaEtxGenSet(Email.$i) \"$vaEtxGenSet(Email.$i)\""
    puts $fileId "set vaEtxGenSet(chbutEmail.$i) \"$vaEtxGenSet(chbutEmail.$i)\""
  }  
  close $fileId
}


# ***************************************************************************
# SendEmail
# ***************************************************************************
proc SendEmail {msg} {
  global gMessage env
  variable vaEtxGenGui
  variable vaEtxGenSet
  variable vaEtxGenCfg
	variable vaEtxGenStatuses
  package require ezsmtp
  ezsmtp::config -mailhost radmail -from "ETX-204A GENERATOR"
  
  if {[file exists InitEmail.tcl]} {
    source InitEmail.tcl
  } 
  for {set i 1} {$i<=$vaEtxGenSet(EmailSum)} {incr i} {   
    if {[info exists vaEtxGenSet(chbutEmail.$i)] && $vaEtxGenSet(chbutEmail.$i)==1} {
      if { [catch {ezsmtp::send -to "$vaEtxGenSet(Email.$i)" \
      -subject "ETX-204A GENERATOR : Update message from the Tester" \
      -body "$msg" \
      -from "$env(USERNAME)@rad.com"} res]} {
        return "Abort"
      }    
    }
  }
  return "Ok"
}


#***************************************************************
#** TimeDate
#**
#** Abstract: Reading time and Date from CPU clock.
#**
#** Inputs: 
#**
#** Outputs: Return the current Time/Date in the format: 08:38:15 <06/01/1999>
#** 
#** Usage: RLTime::TimeDate
#**
#***************************************************************
proc TimeDate {} {  
 
   set clkTime [clock format [clock seconds] -format %H:%M:%S]
   set clkDate [clock format [clock seconds] -format %d/%m/%Y]
   set timeDate "$clkTime  <$clkDate>"

   return $timeDate
}

#***************************************************************************
#** ChkIPValid	
#** 
#** 
#***************************************************************************
proc ChkIPValid	{ip_uutIp} {

	set lIp	[split $ip_uutIp	.]
	if {[llength $lIp] != 4} {
			return -1
	}
  foreach dev	$lIp {
		if {[string length $dev] > 3} {
      return -1
    } 
    if {[catch "expr int($dev)" res] || $dev > 255} {
      return -1
    }
  }
  return 0
}

#MakeEtxGenGui
#package require RLEH
#RLEH::Open
} ;#end namespace




