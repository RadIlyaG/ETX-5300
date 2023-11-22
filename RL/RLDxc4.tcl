#.........................................................................................
#   File name: RLDxc4.tcl
#   Written by Semion 31.10.2005 Updated by Semion 29.10.2006
#
#   Abstract: This file activate the product Dxc-4 with specific software for running E1/T1 BERTs,
#             E1/T1 signaling generator, E1/T1 HDLC generator.
#             This Dxc-4 has 8 or 4 ports, every one may be configured indepandly.
#   Procedures names in this file:
#           - Open
#           - SysConfig
#           - PortConfig
#           - SignConfig
#           - BertConfig
#           - BertInject
#           - BPVInject
#           - SetLoop
#           - SetAllOnes
#           - GetAllOnes
#           - GetConfig
#           - CompareConfig
#           - Start
#           - Stop
#           - GetStatistics
#           - ShowGui
#           - Clear
#           - ChkConnect
#           - Close
#           - CloseAll
#   Examples:
#
#.........................................................................................

package require BWidget
package require RLEH 
package provide RLDxc4 1.42
global gDxc4BufferDebug
set gDxc4BufferDebug 0
global gMessage

namespace eval RLDxc4 {
  namespace export Open Start Stop SysConfig PortConfig SignConfig BertConfig BertInject BPVInject SetLoop SetAllOnes
  namespace export GetAllOnes GetConfig CompareConfig GetStatistics ShowGui ChkConnect Clear Close CloseAll 
 
  global gMessage
  global    gDxc4Buffer
  global    gDxc4BufferDebug
  variable  vaDxc4Gui
  variable  vaDxc4Set
  variable  vaDxc4Cfg
  variable  vaDxcStatuses 
  variable  vOpenedDxcHistoryCounter
  
  #set rundir [file dirname [info script]]
	set vaDxc4Set(closeByDestroy) 0

  #if {[string match -nocase $rundir "C:/Tcl/lib/RL"]} {
  #  set   vaDxc4Set(rundir) C:/RLFiles/Dxc4
  #} else {
      #for starpacks applications
  #    set dir [string range $rundir 0 [string last / $rundir]]
  #    set   vaDxc4Set(rundir) [append dir application]
  #}
  #source [file join $vaDxc4Set(rundir) GuiDxc4.tcl]
	#source [file join $rundir	GuiDxc4.tcl]

  set vOpenedDxcHistoryCounter  0

  set vaDxcStatuses(lMenuSrcClock)    "stam lbtul int stne1 stnt1 auto lbt1 lbt2 lbt3 lbt4 lbt5 lbt6 lbt7 lbt8"
  set vaDxcStatuses(lSrcClock)        "stam lbtUL int stam stnE1 stnT1 stam stam stam auto lbt1 lbt2 lbt3 lbt4 lbt5 lbt6 lbt7 lbt8"
  set vaDxcStatuses(lTimeRes)         "stam 10 20 30 40 50 60 70 80 90 100"
  set vaDxcStatuses(lSigRun)          "Stop Run"
  set vaDxcStatuses(lBertRun)         "Stop Run"
  set vaDxcStatuses(lInsErrSt)        "Off On"
  set vaDxcStatuses(lMenuIntfT1)      "stam csu dsu"
  set vaDxcStatuses(lIntfT1)          "stam stam csu dsu"
  set vaDxcStatuses(lMenuIntfE1)      "stam dsu ltu"
  set vaDxcStatuses(lIntfE1)          "stam stam stam dsu ltu"
  set vaDxcStatuses(lMenuSyncT1)      "stam fast 62411"
  set vaDxcStatuses(lSyncT1)          "stam stam 62411 stam fast"
  set vaDxcStatuses(lMenuFrameE1)     "stam g732s g732scrc4 g732n g732ncrc4 unframe"
  set vaDxcStatuses(lFrameE1)         "stam stam stam stam g732n g732ncrc4 g732s g732scrc4 unframe"
  set vaDxcStatuses(lMenuBalancE1)    "stam yes no"
  set vaDxcStatuses(lBalancE1)        "stam stam no yes"
  set vaDxcStatuses(lMenuFrameT1)     "stam sf esf unframe"
  set vaDxcStatuses(lFrameT1)         "stam stam esf sf stam stam stam stam unframe"
  set vaDxcStatuses(lMenuRstTimeE1)   "stam fast 62411 ccitt"
  set vaDxcStatuses(lRstTimE1)        "stam stam 62411 ccitt fast"
  set vaDxcStatuses(lMenuCodeT1)      "stam ami b8zs transp"
  set vaDxcStatuses(lCodeT1)          "stam ami b8zs stam stam stam transp"
  set vaDxcStatuses(lCodeE1)          "stam stam stam hdb3 stam ami"
  set vaDxcStatuses(lMenuMaskT1)      "stam 0 7.5 15 22.5 0-133 134-266 267-399 400-533 534-655 fcc-68a"
  set vaDxcStatuses(lMaskT1)          "stam stam 7.5 15 22.5 0"
  set vaDxcStatuses(lMaskT1DSU)       "stam stam 0-133 134-266 267-399 400-533 534-655 fcc-68a"
  set vaDxcStatuses(lMenuSigType)     "stam fix incr alter"
  set vaDxcStatuses(lSigType)         "fix incr alter"
	set vaDxcStatuses(lIncSpeed)				"1 2 3 4 8 16"
  set vaDxcStatuses(lMenuIncSpeed)    "stam 1 2 3 4 8 16"
  set vaDxcStatuses(lIncSpeed)        "stam 1 2 3 4 stam stam stam 8 stam stam stam stam stam stam stam 16"
  set vaDxcStatuses(lMenuBertPatt)    "stam 2047 2e15 qrss 511" 
  set vaDxcStatuses(lBertPatt)        "stam stam 2047 2e15 qrss 511" 
  set vaDxcStatuses(lMenuInsErrRt)    "stam none single 2e1 2e2 2e3 2e4 2e5 2e6 2e7"
  set vaDxcStatuses(lInsErrRt)        "none single 2e1 2e2 2e3 2e4 2e5 2e6 2e7"
  set vaDxcStatuses(lSigEnbl)         "dsbl enbl"
  set vaDxcStatuses(lBertEnbl)        "dsbl enbl"
  set vaDxcStatuses(lInsErrEn)        "dsbl enbl"
  set vaDxcStatuses(lPortLpSt)        "none stam remote stam stam stam stam stam stam stam stam stam stam stam stam stam local"
  set vaDxcStatuses(lAllOneTx)        "off on"
  set vaDxcStatuses(lAllOneRx)        "off on"
  set vaDxcStatuses(lDiagPort)        "stam 1 2 3 4 5 6 7 8"

  
      
#***************************************************************************
#***************************************************************************
#
#                  EXPORT FUNCTIONs
#
#***************************************************************************
#***************************************************************************

#***************************************************************************
#**                        RLDxc4::Open
#** 
#**  Abstract: Open the RLDxc4 by com or telnet
#**            Check if the RLDxc4 is ready to be activate
#**
#**   Inputs:
#**            ip_address             :	        Com number or IP address.
#**                              
#**            args   parameters and their value:
#**                              
#**                              
#**  					 -package  	             :	      RLCom/RLSerial/RLTcp/plink (default rlcom).
#**                              
#**  					 -config    	           :	      none/default (default none).
#**                              
#**   Outputs: 
#**            IDApp                   :        ID of opened  RLDxc4 . 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	1. set id1  [RLDxc4::Open 1 -package RLSerial -config none]
#**	2. set id2  [RLDxc4::Open 172.18.124.102 -package RLTcp -config default]
#***************************************************************************

proc Open {ip_address args } {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
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
                          if {[lsearch  "RLCom RLSerial RLTcp plink" $package] == -1} {
         					            set	gMessage "RLDxc4 Open:  Wrong value of parameter $param (must be RLCom/RLSerial/RLTcp/plink)"
                              return [RLEH::Handle SAsyntax gMessage]
      										}
						 }

						-config {
										if {[string match -nocase $val "none"]} {
											set config none
										} elseif {[string match -nocase $val  "default"]} {
											  set config default
										} else {
   					            set	gMessage "RLDxc4 Open:  Wrong value of parameter $param (must be none/default)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }
             default {
                      set gMessage "RLDxc4 Open:  Wrong name of parameter $param (must be -package/-config)"
                      return [RLEH::Handle SAsyntax gMessage]
             }
		}
	}

  #processing address
  if {[regexp {([0-9]+).([0-9]+).([0-9]+).([0-9]+)} $ip_address match subip1 subip2 subip3 subip4]} {
     if {$subip1 > 255 || $subip2 > 255 || $subip3 > 255 || $subip4 > 255} {
        set gMessage "RLDxc4 Open:  Wrong IP address"
        return [RLEH::Handle SAsyntax gMessage]
     }
      set connection telnet
  } elseif {$ip_address > 333 || $ip_address < 1} {
      set gMessage "RLDxc4 Open:  Wrong Com number or IP address"
      return [RLEH::Handle SAsyntax gMessage]
  } else {
      set connection com
  }
	#check empty place in Opened Dxc array
	for {set i 1} {$i <= $vOpenedDxcHistoryCounter} {incr i} {
		if {![info exists vaDxcStatuses($i,dxcID)]} {
		  break
		}
	}

	set dxcIndex $i
  #open dxc
  set  vaDxcStatuses($i,connection) $connection
  set  vaDxcStatuses($i,package) $package
  set  vaDxcStatuses($i,address) $ip_address

  if {![OpenDxc $ip_address $connection $package $i]} {
    set  vaDxcStatuses($i,dxcID) $i
  	if {$i > $vOpenedDxcHistoryCounter} {
      incr vOpenedDxcHistoryCounter
    }
  	if {[string match -nocase $config "default"]} {
      SysConfig $vaDxcStatuses($i,dxcID) -factory yes
    }
    return $vaDxcStatuses($i,dxcID)
  } else {
      append gMessage "\nCann't open DXC-4"
      #return [RLEH::Handle SAsyntax gMessage]
			return $fail
  }
} 

#***************************************************************************
#**                        RLDxc4::SysConfig
#** 
#**  Abstract: Configure System parameters of Dxc-4 by com or telnet
#**
#**   Inputs:
#**            ip_ID                   :	        ID of Dxc-4 returned by Open procedure .
#**                              
#**            args   parameters and their value:
#**                              
#**                              
#**  					 -srcClk  	             :	      lbtUL/int/stnE1/stnT1/auto/lbt1/lbt2/lbt3/lbt4/lbt5/lbt6/lbt7/lbt8.
#**                              
#**  					 -factory    	           :	      yes/no.
#**                              
#**  					 -reset      	           :	      yes/no.
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	1. RLDxc4::SysConfig 1 -srcClk int
#**	2. RLDxc4::SysConfig 2 -srcClk lbt1  -reset yes
#**	3. RLDxc4::SysConfig 3 -factory yes
#***************************************************************************

proc SysConfig {ip_ID args } {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0

  if {$ip_ID == "?"} {
    return "arguments options:  -srcClk , -factory , -reset"
  }

  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "SysConfig procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "SysConfig procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }

	#processing command line parameters
  foreach {param val}   $args   {
   
    switch -exact -- $param  {
    

						-srcClk {
                      if {$val == "?"} {
                        return "source clock options:  lbtUL int stnE1 stnT1 auto lbt1 lbt2 lbt3 lbt4 lbt5 lbt6 lbt7 lbt8"
                      }
                      if {$vaDxcStatuses($ip_ID,bertRun)} {
                		    set	gMessage "SysConfig procedure: Bert running state must be Stop"
                        return $fail
                      }
                      if {$vaDxcStatuses($ip_ID,numbPorts) == 4 && ($val == "lbt5" || $val == "lbt6" ||$val == "lbt7" ||$val == "lbt8")} {
                		    set	gMessage "SysConfig procedure: The source clock value $val of parameter $param wrong"
                        return [RLEH::Handle SAsyntax gMessage]
                      }
 						          if {[set tmpsrcclock [lsearch $vaDxcStatuses(lMenuSrcClock) [string tolower $val]]] == -1} {
                		    set	gMessage "SysConfig procedure: The source clock value $val of parameter $param wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set srcclock $tmpsrcclock
											}
						 }

						-factory {
                    if {$val == "?"} {
                      return "factory defualt options:  yes , no"
                    }
										if {[string match -nocase $val "yes"]} {
											set factory yes
										} elseif {[string match -nocase $val "no"]} {
											  
										} else {
   					            set	gMessage "SysConfig procedure:  Wrong value $val of parameter $param (must be yes/no)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }

						-reset {
                    if {$val == "?"} {
                      return "reset options:   yes , no"
                    }
										if {[string match -nocase $val "yes"]} {
											set reset yes
										} elseif {[string match -nocase $val "no"]} {
											  
										} else {
   					            set	gMessage "SysConfig procedure:  Wrong value $val  parameter $param (must be yes/no)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }

             default {
                      set gMessage "SysConfig procedure:   Wrong name of parameter $param"
                      return [RLEH::Handle SAsyntax gMessage]
             }
		}
	}
	set ret 0
	if {$vaDxcStatuses($ip_ID,currScreen) != "System"} {
	  set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
	  set ret [expr [SendToDxc4 $ip_ID "2\r" "Link channel" 6] | $ret]
	  set ret [expr [SendToDxc4 $ip_ID "1\r" "Reset" 6] | $ret]
	  set vaDxcStatuses($ip_ID,currScreen) "System"
	}
  if {[info exists srcclock] } {
    set ret [expr [SendToDxc4 $ip_ID "1\r" "LBT from port" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$srcclock\r" "Reset" 6] | $ret]
  }

  if {[info exists factory] } {
    set ret [expr [SendToDxc4 $ip_ID "5\r" "Y/N" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "Y\r" "Reset" 6] | $ret]
    set  vaDxcStatuses($ip_ID,linkType) E1
  }

  if {[info exists reset] } {
    set ret [expr [SendToDxc4 $ip_ID "6\r" "Y/N" 6] | $ret]
    #SendToDxc4 $ip_ID "Y\r" "stam" 25
    SendToDxc4 $ip_ID "Y\r"
		Delay 25
    set ret [expr [SendToDxc4 $ip_ID "\r" "DXC-4" 6] | $ret]
	  set vaDxcStatuses($ip_ID,currScreen) "Main"
  }

  if {$ret} {
	  set vaDxcStatuses($ip_ID,currScreen) "na"
    return $fail
  } else {
      return $ok
  }
}


#*************************************************************************
#**                        RLDxc4::PortConfig
#** 
#**  Abstract: Configure ports parameters of Dxc-4 by com or telnet
#**
#**   Inputs:
#**            ip_ID                   :	        ID of Dxc-4 returned by Open procedure .
#**                              
#**  					 ip_linkType   	         :	      T1/E1.
#**                              
#**            args   parameters and their value:
#**                              
#**                              
#**  					 -updPort  	             :	      1-8/all.
#**                              
#**  					 -frameE1    	           :	      g732s/g732scrc4/g732n/g732ncrc4/unframe.
#**                              
#**  					 -frameT1    	           :	      sf/esf/unframe.
#**                              
#**  					 -restTime   	           :	      fast/62411/ccitt.
#**                              
#**  					 -sync    	             :	      fast/62411.
#**                              
#**  					 -intfT1    	           :	      csu/dsu.
#**                              
#**  					 -intfE1    	           :	      ltu/dsu.
#**                              
#**  					 -idleCode   	           :	      00 - FF.
#**                              
#**  					 -lineCodeE1 	           :	      ami/hdb3.
#**                              
#**  					 -lineCodeT1 	           :	      ami/b8zs/transp.
#**                              
#**  					 -balanced  	           :	      yes/no.
#**                              
#**  					 -oosCode   	           :	      00 - FF.
#**                              
#**  					 -mask      	           :	      For CSU: 0 , 7.5 , 15 , 22.5. For DSU: 0-133 , 134-266 , 267-399 , 400-533 , 534-655 , fcc-68a."
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::PortConfig 1 E1 -updPort all -frameE1 g732s -intfE1 dsu -lineCodeE1 hdb3  -balanced yes  -oosCode  7F
#**  RLDxc4::PortConfig 1 T1 -updPort all -frameT1 esf -intfT1 csu -oosCode  7F -idleCode AA -lineCodeT1 transp -mask 7.5
#***************************************************************************

proc PortConfig {ip_ID ip_linkType args } {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0

  if {$ip_ID == "?"} {
    return "arguments options:  -updPort , -frameE1 , -frameT1 , -restTime , -sync , -intfE1 , -intfT1 , -idleCode , -lineCodeE1 , -lineCodeT1 , -balanced , -oosCode , -mask"
  }

  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "PortConfig procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "PortConfig procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }

	if {[string match -nocase $ip_linkType "E1"]} {
		set linkType E1
	} elseif {[string match -nocase $ip_linkType "T1"]} {
		   set linkType T1
	} else {
      set	gMessage "PortConfig procedure:  Wrong Link type: $ip_linkType (must be E1/T1)"
      return [RLEH::Handle SAsyntax gMessage]
	}

  if {$vaDxcStatuses($ip_ID,bertRun)} {
    set	gMessage "PortConfig procedure: Bert running state must be Stop"
    return $fail
  }

	#processing command line parameters
  foreach {param val}   $args   {
   
    switch -exact -- $param  {
    

						-updPort {
                      if {$val == "?"} {
                        return "updated port options:  1/2/3/4/5/6/7/8/all"
                      }
                      if {[string match -nocase $val "all"]} {
                        set vaDxcStatuses($ip_ID,updPort) all
                        if {$vaDxcStatuses($ip_ID,numbPorts) == 4} {
  												set updPort 5
                        } else {
  													set updPort 9
                        }
                      } else {
  										  if {[set res [catch {expr int($val)}]]} {
                    		  set	gMessage "PortConfig procedure: The value $val of parameter $param isn't integer"
                          return [RLEH::Handle SAsyntax gMessage]
                        }
                        if {$vaDxcStatuses($ip_ID,numbPorts) == 4 && $val >5} {
                  		    set	gMessage "PortConfig procedure: The value $val of parameter $param wrong"
                          return [RLEH::Handle SAsyntax gMessage]
                        }
   						          if {$val < 1 || $val > 8} {
                  		    set	gMessage "PortConfig procedure: The value $val of parameter $param wrong"
                          return [RLEH::Handle SAsyntax gMessage]
  							     	  } else {
  													set updPort $val
                            set vaDxcStatuses($ip_ID,updPort) $val
  											}
                      }
						 }

						-frameE1 {
                      if {$val == "?"} {
                        return "Frame E1 options:  g732s , g732scrc4 , g732n , g732ncrc4 , unframe"
                      }
                      if {$linkType == "T1"} {
                		    set	gMessage "PortConfig procedure: Mismatch the Link type and frame: $linkType  $val"
                        return [RLEH::Handle SAsyntax gMessage]
                      }
 						          if {[set tmpframe [lsearch $vaDxcStatuses(lMenuFrameE1) [string tolower $val]]] == -1} {
                		    set	gMessage "PortConfig procedure: The frame E1 value $val of parameter $param wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set frameE1 $tmpframe
											}
						 }

						-frameT1 {
                      if {$val == "?"} {
                        return "Frame T1 options:  sf , esf , unframe"
                      }
                      if {$linkType == "E1"} {
                		    set	gMessage "PortConfig procedure: Mismatch the Link type and frame: $linkType  $val"
                        return [RLEH::Handle SAsyntax gMessage]
                      }
 						          if {[set tmpframe [lsearch $vaDxcStatuses(lMenuFrameT1) [string tolower $val]]] == -1} {
                		    set	gMessage "PortConfig procedure: The frame T1 value $val of parameter $param wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set frameT1 $tmpframe
											}
						 }

						-restTime {
                      if {$val == "?"} {
                        return "Restoration time E1 options:  fast , 62411 , ccitt"
                      }
                      if {$linkType == "T1"} {
                		    set	gMessage "PortConfig procedure: Mismatch the Link type $linkType and Restoration "
                        return [RLEH::Handle SAsyntax gMessage]
                      }
 						          if {[set tmprestTime [lsearch $vaDxcStatuses(lMenuRstTimeE1) [string tolower $val]]] == -1} {
                		    set	gMessage "PortConfig procedure: The Restoration time value $val of parameter $param wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set restTime $tmprestTime
											}
						 }

						-sync {
                    if {$val == "?"} {
                      return "Sync T1 options:  fast , 62411"
                    }
                    if {$linkType == "E1"} {
              		    set	gMessage "PortConfig procedure: Mismatch the Link type $linkType and Sync T1"
                      return [RLEH::Handle SAsyntax gMessage]
                    }
										if {[string match -nocase $val "fast"]} {
											set sync $val
										} elseif {$val == "62411"} {
											   set sync $val
										} else {
   					            set	gMessage "PortConfig procedure:  Wrong value: $val of parameter $param (must be fast/62411)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }

						-intfE1 {
                    if {$val == "?"} {
                      return "Interface type E1 options:  ltu , dsu"
                    }
                    if {$linkType == "T1"} {
              		    set	gMessage "PortConfig procedure: Mismatch the Link type $linkType and Interface type E1"
                      return [RLEH::Handle SAsyntax gMessage]
                    }
										if {[string match -nocase $val "ltu"]} {
											set intfE1 $val
										} elseif {[string match -nocase $val "dsu"]} {
											   set intfE1 $val
										} else {
   					            set	gMessage "PortConfig procedure:  Wrong value: $val of parameter $param (must be ltu/dsu)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }

						-intfT1 {
                    if {$val == "?"} {
                      return "Interface type T1 options:  csu , dsu"
                    }
                    if {$linkType == "E1"} {
              		    set	gMessage "PortConfig procedure: Mismatch the Link type $linkType and Interface type T1"
                      return [RLEH::Handle SAsyntax gMessage]
                    }
										if {[string match -nocase $val "csu"]} {
											set intfT1 $val
										} elseif {[string match -nocase $val "dsu"]} {
											   set intfT1 $val
										} else {
   					            set	gMessage "PortConfig procedure:  Wrong value: $val of parameter $param (must be csu/dsu)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }

						-idleCode {
                    if {$val == "?"} {
                      return "Idle code options:  00 - FF"
                    }
										if {[string length $val] < 2} {
											set val 0$val
										}
                    if {![regexp {[0-9,A-F,a-f][0-9,A-F,a-f]} $val]} {
              		    set	gMessage "PortConfig procedure: Wrong value: $val of parameter $param (must be 00 - FF)"
                      return [RLEH::Handle SAsyntax gMessage]
										} else {
                        set idleCode $val
										}
						 }

						-lineCodeE1 {
                    if {$val == "?"} {
                      return "Line code E1 options:  ami , hdb3"
                    }
                    if {$linkType == "T1"} {
              		    set	gMessage "PortConfig procedure: Mismatch the Link type $linkType and Line code E1"
                      return [RLEH::Handle SAsyntax gMessage]
                    }
										if {[string match -nocase $val "ami"]} {
											set lineCodeE1 $val
										} elseif {[string match -nocase $val "hdb3"]} {
											   set lineCodeE1 $val
										} else {
   					            set	gMessage "PortConfig procedure:  Wrong value: $val of parameter $param (must be ami/hdb3)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }

						-lineCodeT1 {
                      if {$val == "?"} {
                        return "Line code T1 options:  ami , b8zs , transp"
                      }
                      if {$linkType == "E1"} {
                		    set	gMessage "PortConfig procedure: Mismatch the Link type $linkType and Line code T1"
                        return [RLEH::Handle SAsyntax gMessage]
                      }
 						          if {[set tmplinecode [lsearch $vaDxcStatuses(lMenuCodeT1) [string tolower $val]]] == -1} {
                		    set	gMessage "PortConfig procedure: The Line code T1 value $val of parameter $param wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set lineCodeT1 $tmplinecode
											}
						 }

						-balanced {
                    if {$val == "?"} {
                      return "E1 balanced options:  yes , no"
                    }
                    if {$linkType == "T1"} {
              		    set	gMessage "PortConfig procedure: Mismatch the Link type $linkType and balanced E1"
                      return [RLEH::Handle SAsyntax gMessage]
                    }
										if {[string match -nocase $val "yes"]} {
											set balanced $val
										} elseif {[string match -nocase $val "no"]} {
											   set balanced $val
										} else {
   					            set	gMessage "PortConfig procedure:  Wrong value: $val of parameter $param (must be yes/no)"
                        return [RLEH::Handle SAsyntax gMessage]
										}
						 }

						-oosCode {
                    if {$val == "?"} {
                      return "OOS code options:  00 - FF"
                    }
										if {[string length $val] < 2} {
											set val 0$val
										}
                    if {![regexp {[0-9,A-F,a-f][0-9,A-F,a-f]} $val]} {
              		    set	gMessage "PortConfig procedure: Wrong value: $val of parameter $param (must be 00 - FF)"
                      return [RLEH::Handle SAsyntax gMessage]
										} else {
                        set oosCode $val
										}
						 }

						-mask {
                    if {$val == "?"} {
                      return "T1 mask options: For CSU: 0 , 7.5 , 15 , 22.5. For DSU: 0-133 , 134-266 , 267-399 , 400-533 , 534-655 , fcc-68a."
                    }
                    if {$linkType == "E1"} {
              		    set	gMessage "PortConfig procedure: Mismatch the Link type $linkType and MASK T1"
                      return [RLEH::Handle SAsyntax gMessage]
                    }
					          if {[set tmpmask [lsearch $vaDxcStatuses(lMenuMaskT1) [string tolower $val]]] == -1} {
              		    set	gMessage "PortConfig procedure: The MASK T1 value $val of parameter $param wrong"
                      return [RLEH::Handle SAsyntax gMessage]
						     	  } else {
												set mask $tmpmask
										}
						 }

             default {
                      set gMessage "PortConfig procedure:   Wrong name of parameter $param"
                      return [RLEH::Handle SAsyntax gMessage]
             }
		}
	}
	set ret 0
	if {$vaDxcStatuses($ip_ID,currScreen) != "Ports"} {
	  set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
	  set ret [expr [SendToDxc4 $ip_ID "2\r" "Link channel" 6] | $ret]
	  set ret [expr [SendToDxc4 $ip_ID "2\r" "Port parameters" 6] | $ret]
	  #if current link type does not match to required, toggle link type
	  set  vaDxcStatuses($ip_ID,linkType) $linkType
	  if {![string match -nocase "*($linkType)*" $gDxc4Buffer(id$ip_ID)]} {
	    set ret [expr [SendToDxc4 $ip_ID "1\r" "Port parameters" 6] | $ret]
	  }
    #enter into port parameters screen 
    set ret [expr [SendToDxc4 $ip_ID "2\r" "Out of service" 6] | $ret]
		set vaDxcStatuses($ip_ID,currScreen) "Ports"
	} else {
  	  set ret [expr [SendToDxc4 $ip_ID "\33" "Link channel" 6] | $ret]
      #if current link type does not match to required, toggle link type
      set  vaDxcStatuses($ip_ID,linkType) $linkType
      if {![string match -nocase "*($linkType)*" $gDxc4Buffer(id$ip_ID)]} {
        set ret [expr [SendToDxc4 $ip_ID "1\r" "Port parameters" 6] | $ret]
      }
      #enter into port parameters screen 
      set ret [expr [SendToDxc4 $ip_ID "2\r" "Out of service" 6] | $ret]
	}
  #updated port
  if {[info exists updPort]} {
    set ret [expr [SendToDxc4 $ip_ID "1\r" "All Ports" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$updPort\r" "Out of service" 6] | $ret]
  }
  #refresh port parameters screen 
  set ret [expr [SendToDxc4 $ip_ID "\r" "Out of service" 6] | $ret]
  #handling other toggled parameters
  foreach {param val} {sync 7 intfE1 4 intfT1 4 lineCodeE1 6 balanced 7} {
    if {[info exists $param]} {
      if {![string match -nocase "*([set $param])*" $gDxc4Buffer(id$ip_ID)]} {
        set ret [expr [SendToDxc4 $ip_ID "$val\r" "Out of service" 6] | $ret]
      }
    }

  }
  #handling frameE1
  if {[info exists frameE1]} {
    set ret [expr [SendToDxc4 $ip_ID "2\r" "UNFRAME" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$frameE1\r" "Out of service" 6] | $ret]
  }

  #handling frameT1
  if {[info exists frameT1]} {
    set ret [expr [SendToDxc4 $ip_ID "2\r" "UNFRAME" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$frameT1\r" "Out of service" 6] | $ret]
  }

  #handling restTime
  if {[info exists restTime]} {
    set ret [expr [SendToDxc4 $ip_ID "3\r" "CCITT" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$restTime\r" "Out of service" 6] | $ret]
  }
  
  #handling idleCode
  if {[info exists idleCode]} {
    set ret [expr [SendToDxc4 $ip_ID "5\r" "H" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$idleCode\r" "Out of service" 6] | $ret]
  }

  #handling lineCodeT1
  if {[info exists lineCodeT1]} {
    set ret [expr [SendToDxc4 $ip_ID "3\r" "TRANSPARENT" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$lineCodeT1\r" "Out of service" 6] | $ret]
  }

  #handling oosCode
  if {[info exists oosCode]} {
    set ret [expr [SendToDxc4 $ip_ID "8\r" "H" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$oosCode\r" "Out of service" 6] | $ret]
  }
 
  #handling mask
  if {[info exists mask]} {
    set ret [expr [SendToDxc4 $ip_ID "\r" "Out of service" 6] | $ret]
    if {[string match -nocase "*(CSU)*" $gDxc4Buffer(id$ip_ID)]} {
		  set waitstr "22.5"
			if {$mask > 4} {
				set mask 4
			}
		} else {
  		  set waitstr "FCC-68A"
				if {$mask > 4} {
					incr mask -4
				}
		}
    set ret [expr [SendToDxc4 $ip_ID "6\r" $waitstr 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$mask\r" "Out of service" 6] | $ret]
  }
  if {$ret} {
		set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}



#***************************************************************************
#**                        RLDxc4::SignConfig
#** 
#**  Abstract: Configure ports parameters of Dxc-4 by com or telnet
#**
#**   Inputs:
#**            ip_ID                   :	        ID of Dxc-4 returned by Open procedure .
#**                              
#**            args   parameters and their value:
#**                              
#**                              
#**  					 -updPort  	             :	      1-8/all.
#**                              
#**  					 -linkType   	           :	      T1/E1.
#**                              
#**  					 -enabled    	           :	      enable/disable.
#**                              
#**  					 -signType   	           :	      fix/incr/alter.
#**                              
#**  					 -signValue   	         :	      00 -FF.
#**                              
#**  					 -incrSpeed	             :	      1,2,3,4,8,16.
#**                              
#**  					 -timeResol    	         :	      10,20,30,40,50,60,70,80,90,100.
#**                              
#**  					 -tsAssignm    	         :	      all/1-4,7,9/1-24/1,2,3,5-8,13,17/........
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::SignConfig 1 -updPort all -linkType T1 -enabled  enbl -signType incr -signValue A5  -incrSpeed 1  -timeResol 20 -tsAssignm 1-10,15,24
#***************************************************************************

proc SignConfig {ip_ID args } {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0

  if {$ip_ID == "?"} {
    return "arguments options:  -updPort , -linkType , -enabled , -signType , -signValue , -incrSpeed , -timeResol , -tsAssignm"
  }

  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "SignConfig procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "SignConfig procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }

	#processing command line parameters
  foreach {param val}   $args   {
   
    switch -exact -- $param  {
    

						-updPort {
                      if {$val == "?"} {
                        return "updated port options:  1/2/3/4/5/6/7/8/all"
                      }
                      if {[string match -nocase $val "all"]} {
                        set vaDxcStatuses($ip_ID,updPort) all
                        if {$vaDxcStatuses($ip_ID,numbPorts) == 4} {
  												set updPort 5
                        } else {
  													set updPort 9
                        }
                      } else {
  										  if {[set res [catch {expr int($val)}]]} {
                    		  set	gMessage "SignConfig procedure: The value $val of parameter $param isn't integer"
                          return [RLEH::Handle SAsyntax gMessage]
                        }
                        if {$vaDxcStatuses($ip_ID,numbPorts) == 4 && $val >5} {
                  		    set	gMessage "SignConfig procedure: The value $val of parameter $param wrong"
                          return [RLEH::Handle SAsyntax gMessage]
                        }
   						          if {$val < 1 || $val > 8} {
                  		    set	gMessage "SignConfig procedure: The value $val of parameter $param wrong"
                          return [RLEH::Handle SAsyntax gMessage]
  							     	  } else {
  													set updPort $val
                            set vaDxcStatuses($ip_ID,updPort) $val
  											}
                      }
						 }

            -linkType {

                        if {$vaDxcStatuses($ip_ID,bertRun)} {
                  		    set	gMessage "SignConfig procedure: Bert running state must be Stop"
                          return $fail
                        }
                      	if {[string match -nocase $val "E1"]} {
                      		set linkType E1
                      	} elseif {[string match -nocase $val "T1"]} {
                      		   set linkType T1
                      	} else {
                            set	gMessage "SignConfig procedure:  Wrong Link type: $val (must be E1/T1)"
                            return [RLEH::Handle SAsyntax gMessage]
                      	}
            }

						-enabled {
                      if {$val == "?"} {
                        return "enabled options:  enbl , dsbl"
                      }
                      if {$vaDxcStatuses($ip_ID,bertRun)} {
                		    set	gMessage "SignConfig procedure: Bert running state must be Stop"
                        return $fail
                      }
                    	if {[string match -nocase $val "enbl"]} {
                    		set enabled $val
                    	} elseif {[string match -nocase $val "dsbl"]} {
                    		   set enabled $val
                    	} else {
                          set	gMessage "SignConfig procedure:  Wrong enabled: $val (must be enbl/dsbl)"
                          return [RLEH::Handle SAsyntax gMessage]
                      }
						 }

						-signType {
                      if {$val == "?"} {
                        return "Signaling type options:  fix , incr , alter"
                      }
                      if {$vaDxcStatuses($ip_ID,bertRun)} {
                		    set	gMessage "SignConfig procedure: Bert running state must be Stop"
                        return $fail
                      }
 						          if {[set tmpsignType [lsearch $vaDxcStatuses(lMenuSigType) [string tolower $val]]] == -1} {
                		    set	gMessage "SignConfig procedure: The Signaling type value $val of parameter $param wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set signType $tmpsignType
											}
						 }

						-signValue {
                    if {$val == "?"} {
                      return "Signaling value options:  00 - FF"
                    }
                    if {$vaDxcStatuses($ip_ID,bertRun)} {
              		    set	gMessage "SIgnConfig procedure: Bert running state must be Stop"
                      return $fail
                    }
										if {[string length $val] < 2} {
											set val 0$val
										}
                    if {![regexp {[0-9,A-F,a-f][0-9,A-F,a-f]} $val]} {
              		    set	gMessage "SignConfig procedure: Wrong value: $val of parameter $param (must be 00 - FF)"
                      return [RLEH::Handle SAsyntax gMessage]
										} else {
                        set signValue $val
										}
						 }

						-incrSpeed {
                    if {$val == "?"} {
                      return "Increment speed Signaling value options:  1,2,3,4,8,16"
                    }
                    if {$vaDxcStatuses($ip_ID,bertRun)} {
              		    set	gMessage "SignConfig procedure: Bert running state must be Stop"
                      return $fail
                    }
					          if {[set tmpincrSpeed [lsearch $vaDxcStatuses(lMenuIncSpeed) [string tolower $val]]] == -1} {
              		    set	gMessage "SignConfig procedure: The Increment speed Signaling value $val of parameter $param wrong"
                      return [RLEH::Handle SAsyntax gMessage]
						     	  } else {
												set incrSpeed $tmpincrSpeed
										}
						 }

						-timeResol {
                    if {$val == "?"} {
                      return "Time resolution value options:  10,20,30,40,50,60,70,80,90,100"
                    }
                    if {!([expr $val/10] >0 && [expr $val/10] <11)} {
              		    set	gMessage "SignConfig procedure: Wrong value: $val of parameter $param "
                      return [RLEH::Handle SAsyntax gMessage]
										} else {
                        set timeResol [expr $val/10]
										}
						 }

						-tsAssignm {
                    if {$val == "?"} {
                      return "Time slots assignment options:  all/1-15,17-31/1,3,7,8/1-3,6-9,11,12-24/.........."
                    }
                    set tsAssignm $val
						 }

             default {
                      set gMessage "SignConfig procedure:   Wrong name of parameter $param"
                      return [RLEH::Handle SAsyntax gMessage]
             }
    }

  }
	set ret 0
	if {$vaDxcStatuses($ip_ID,currScreen) != "Signaling"} {
	  set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
	  set ret [expr [SendToDxc4 $ip_ID "3\r" "Current signaling" 6] | $ret]
	  set vaDxcStatuses($ip_ID,currScreen) "Signaling"
	}
  #Link type
  if {[info exists linkType]} {
    #if current link type does not match to required, toggle link type
    set  vaDxcStatuses($ip_ID,linkType) $linkType
    if {![string match -nocase "*($linkType)*" $gDxc4Buffer(id$ip_ID)]} {
      set ret [expr [SendToDxc4 $ip_ID "1\r" "Current signaling" 6] | $ret]
    }
  }

  #updated port
  if {[info exists updPort]} {
    set ret [expr [SendToDxc4 $ip_ID "2\r" "All Ports" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$updPort\r" "Current signaling" 6] | $ret]
  }

  #Time resolution
  if {[info exists timeResol]} {
    set ret [expr [SendToDxc4 $ip_ID "4\r" "100 mSec" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$timeResol\r" "Current signaling" 6] | $ret]
  }

  #Time slots assignment
  if {[info exists tsAssignm]} {
    set ret [expr [SendToDxc4 $ip_ID "5\r" "H" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$tsAssignm\r" "Current signaling" 6] | $ret]
    if {[string match "*ERROR*" $gDxc4Buffer(id$ip_ID)]} {
	    set vaDxcStatuses($ip_ID,currScreen) "na"
      set	gMessage "SignConfig procedure: Wrong Time slots assignment"
      return [RLEH::Handle SAsyntax gMessage]
    }
  }
  #enter into port signaling configuration screen 
  set ret [expr [SendToDxc4 $ip_ID "3\r" "Increment Signaling" 6] | $ret]

  #Enable ports
  if {[info exists enabled]} {
    #if current enabled does not match to required, toggle it
    if {![string match -nocase "*($enabled)*" $gDxc4Buffer(id$ip_ID)]} {
      set ret [expr [SendToDxc4 $ip_ID "1\r" "Increment Signaling" 6] | $ret]
    }
  }

  #Signaling type
  if {[info exists signType]} {
    set ret [expr [SendToDxc4 $ip_ID "2\r" "ALTER" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$signType\r" "Increment Signaling" 6] | $ret]
  }
  
  #Signaling value
  if {[info exists signValue]} {
    set ret [expr [SendToDxc4 $ip_ID "3\r" "H" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$signValue\r" "Increment Signaling" 6] | $ret]
  }

  #Increment speed Signaling
  if {[info exists incrSpeed]} {
    set ret [expr [SendToDxc4 $ip_ID "4\r" "16" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$incrSpeed\r" "Increment Signaling" 6] | $ret]
  }
  #return into signaling configuration screen 
  set ret [expr [SendToDxc4 $ip_ID "\33" "Current signaling" 6] | $ret]

	if {$ret} {
	  set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}


#***************************************************************************
#**                        RLDxc4::BertConfig
#** 
#**  Abstract: Configure berts parameters of Dxc-4 by com or telnet
#**
#**   Inputs:
#**            ip_ID                   :	        ID of Dxc-4 returned by Open procedure .
#**                              
#**            args   parameters and their value:
#**                              
#**                              
#**  					 -updPort  	             :	      1-8/all.
#**                              
#**  					 -linkType   	           :	      T1/E1.
#**                              
#**  					 -enabledBerts           :	      all/1-7/1,3,8/...........
#**                              
#**  					 -pattern    	           :	      2047/2e15/qrss/511.
#**                              
#**  					 -tsAssignm    	         :	      all/unframe/1-4,7,9/1-24/1,2,3,5-8,13,17/.....
#**                              
#**  					 -inserrRate   	         :	      none/single/2e1/2e2/2e3/2e4/2e5/2e6/2e7.
#**                              
#**  					 -inserrBerts            :	      all/1-7/1,3,8/.....
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::BertConfig 1 -updPort all -linkType E1 -enabledBerts  all -pattern 2e15 -tsAssignm 1-10,15,31 -inserrRate single  -inserrBerts all 
#***************************************************************************

proc BertConfig {ip_ID args } {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0

  if {$ip_ID == "?"} {
    return "arguments options:  -updPort , -linkType , -enabledBerts , -pattern , -tsAssignm , -inserrRate , -inserrBerts"
  }

  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "BertConfig procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "BertConfig procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }

	#processing command line parameters
  foreach {param val}   $args   {
   
    switch -exact -- $param  {
    

						-updPort {
                      if {$val == "?"} {
                        return "updated port options:  1/2/3/4/5/6/7/8/all"
                      }
                      if {[string match -nocase $val "all"]} {
                        set vaDxcStatuses($ip_ID,updPort) all
                        if {$vaDxcStatuses($ip_ID,numbPorts) == 4} {
  												set updPort 5
                        } else {
  													set updPort 9
                        }
                      } else {
  										  if {[set res [catch {expr int($val)}]]} {
                    		  set	gMessage "BertConfig procedure: The value $val of parameter $param isn't integer"
                          return [RLEH::Handle SAsyntax gMessage]
                        }
                        if {$vaDxcStatuses($ip_ID,numbPorts) == 4 && $val >5} {
                  		    set	gMessage "BertConfig procedure: The value $val of parameter $param wrong"
                          return [RLEH::Handle SAsyntax gMessage]
                        }
   						          if {$val < 1 || $val > 8} {
                  		    set	gMessage "BertConfig procedure: The value $val of parameter $param wrong"
                          return [RLEH::Handle SAsyntax gMessage]
  							     	  } else {
  													set updPort $val
                            set vaDxcStatuses($ip_ID,updPort) $val
  											}
                      }
						 }

            -linkType {

                        if {$vaDxcStatuses($ip_ID,bertRun)} {
                  		    set	gMessage "BertConfig procedure: Bert running state must be Stop"
                          return $fail
                        }
                      	if {[string match -nocase $val "E1"]} {
                      		set linkType E1
                      	} elseif {[string match -nocase $val "T1"]} {
                      		   set linkType T1
                      	} else {
                            set	gMessage "BertConfig procedure:  Wrong Link type: $val (must be E1/T1)"
                            return [RLEH::Handle SAsyntax gMessage]
                      	}
            }

						-enabledBerts {
                      if {$val == "?"} {
                        return "Enabled berts options:  all/1-7/1,3,8/..........."
                      }
                      #if {$vaDxcStatuses($ip_ID,bertRun)} {
                		  #  set	gMessage "BertConfig procedure: Bert running state must be Stop"
                      #  return $fail
                      #}
                    	set enabledBerts $val
						 }

						-pattern {
                      if {$val == "?"} {
                        return "Bert pattern options:  2047 , 2e15 , qrss , 511"
                      }
                      #if {$vaDxcStatuses($ip_ID,bertRun)} {
                		  #  set	gMessage "BertConfig procedure: Bert running state must be Stop"
                      #  return $fail
                      #}
 						          if {[set tmppattern [lsearch $vaDxcStatuses(lMenuBertPatt) [string tolower $val]]] == -1} {
                		    set	gMessage "BertConfig procedure: The bert Pattern value $val of parameter $param wrong"
                        return [RLEH::Handle SAsyntax gMessage]
							     	  } else {
													set pattern $tmppattern
											}
						 }

						-tsAssignm {
                    if {$val == "?"} {
                      return "Time slots assignment options:  all/1-15,17-31/1,3,7,8/1-3,6-9,11,12-24/.........."
                    }
                    #if {$vaDxcStatuses($ip_ID,bertRun)} {
              		  #  set	gMessage "BertConfig procedure: Bert running state must be Stop"
                    #  return $fail
                    #}
                    set tsAssignm $val
						 }

						-inserrRate {
                    if {$val == "?"} {
                      return "Insert error rate options:  none , single , 2e1 , 2e2 , 2e3 , 2e4 , 2e5 , 2e6 , 2e7"
                    }
                    #if {$vaDxcStatuses($ip_ID,bertRun)} {
              		  #  set	gMessage "BertConfig procedure: Bert running state must be Stop"
                    #  return $fail
                    #}
					          if {[set tmpinserrRate [lsearch $vaDxcStatuses(lMenuInsErrRt) [string tolower $val]]] == -1} {
              		    set	gMessage "BertConfig procedure: The Insert error rate value $val of parameter $param wrong"
                      return [RLEH::Handle SAsyntax gMessage]
						     	  } else {
												set inserrRate $tmpinserrRate
										}
						 }

						-inserrBerts {
                      if {$val == "?"} {
                        return "Insert error bert options:  all/1-7/1,3,8/..........."
                      }
                    	set inserrBerts $val
						 }

             default {
                      set gMessage "BertConfig procedure:   Wrong name of parameter $param"
                      return [RLEH::Handle SAsyntax gMessage]
             }
    }

  }
	set ret 0
	if {$vaDxcStatuses($ip_ID,currScreen) != "Berts"} {
	  set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
	  set ret [expr [SendToDxc4 $ip_ID "4\r" "Clear Statistics" 6] | $ret]
	  set vaDxcStatuses($ip_ID,currScreen) "Berts"
	}
  #Link type
  if {[info exists linkType]} {
    set  vaDxcStatuses($ip_ID,linkType) $linkType
    #if current link type does not match to required, toggle link type
    if {![string match -nocase "*($linkType)*" $gDxc4Buffer(id$ip_ID)]} {
      set ret [expr [SendToDxc4 $ip_ID "1\r" "Clear Statistics" 6] | $ret]
    }
  }

  #updated port
  if {[info exists updPort]} {
    set ret [expr [SendToDxc4 $ip_ID "2\r" "All Ports" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$updPort\r" "Clear Statistics" 6] | $ret]
  }

  #Enabled berts assignment
  if {[info exists enabledBerts]} {
    set ret [expr [SendToDxc4 $ip_ID "3\r" "H" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$enabledBerts\r" "Clear Statistics" 6] | $ret]
    if {[string match "*ERROR*" $gDxc4Buffer(id$ip_ID)]} {
  	  set vaDxcStatuses($ip_ID,currScreen) "na"
      set	gMessage "BertConfig procedure: Wrong Enabled berts assignment"
      return [RLEH::Handle SAsyntax gMessage]
    }
  }

  #Bert pattern
  if {[info exists pattern]} {
    set ret [expr [SendToDxc4 $ip_ID "4\r" "511" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$pattern\r" "Clear Statistics" 6] | $ret]
    if {[string match "*ERROR:*" $gDxc4Buffer(id$ip_ID)]} {
      set ret [expr [SendToDxc4 $ip_ID "\r" "Clear Statistics" 6] | $ret]
  	  set vaDxcStatuses($ip_ID,currScreen) "na"
      set	gMessage "BertConfig procedure: The specified Bert is enabled and is in running state.\nDisable or Stop it before change parameters"
      return $fail
    }
  }

  #Time slots assignment
  if {[info exists tsAssignm]} {
    set ret [expr [SendToDxc4 $ip_ID "5\r" "H" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$tsAssignm\r" "Clear Statistics" 6] | $ret]
    if {[string match "*ERROR:*" $gDxc4Buffer(id$ip_ID)]} {
      set ret [expr [SendToDxc4 $ip_ID "\r" "Clear Statistics" 6] | $ret]
  	  set vaDxcStatuses($ip_ID,currScreen) "na"
      set	gMessage "BertConfig procedure: The specified Bert is enabled and is in running state.\nDisable or Stop it before change parameters"
      return $fail
    }
    if {[string match "*ERROR*" $gDxc4Buffer(id$ip_ID)]} {
  	  set vaDxcStatuses($ip_ID,currScreen) "na"
      set	gMessage "BertConfig procedure: Wrong Time slots assignment"
      return [RLEH::Handle SAsyntax gMessage]
    }
  }

  #Insert error rate
  if {[info exists inserrRate]} {
    set ret [expr [SendToDxc4 $ip_ID "8\r" "10E-7" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$inserrRate\r" "Clear Statistics" 6] | $ret]
    if {[string match "*ERROR:*" $gDxc4Buffer(id$ip_ID)]} {
      set ret [expr [SendToDxc4 $ip_ID "\r" "Clear Statistics" 6] | $ret]
  	  set vaDxcStatuses($ip_ID,currScreen) "na"
      set	gMessage "BertConfig procedure: The specified Bert is enabled and is in running state.\nDisable or Stop it before change parameters"
      return $fail
    }
  }

  #Insert error berts assignment
  if {[info exists inserrBerts]} {
    set ret [expr [SendToDxc4 $ip_ID "9\r" "H" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$inserrBerts\r" "Clear Statistics" 6] | $ret]
    if {[string match "*ERROR*" $gDxc4Buffer(id$ip_ID)]} {
	    set vaDxcStatuses($ip_ID,currScreen) "na"
      set	gMessage "BertConfig procedure: Wrong Insert error berts assignment"
      return [RLEH::Handle SAsyntax gMessage]
    }
  }
	if {$ret} {
	  set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}



#***************************************************************************
#**                        RLDxc4::GetConfig
#** 
#**  Abstract: Gets Configuration of all Dxc-4's ports
#**
#**   Inputs:
#**            ip_ID                   :	        ID of Dxc-4 returned by Open procedure .
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
#**	 RLDxc4::GetConfig 1  res
#***************************************************************************

proc GetConfig {ip_ID op_results} {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vaDxc4Cfg
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  upvar $op_results  results
  catch {unset results}

  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "GetConfig procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "GetConfig procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }

	set ret 0
	if {$vaDxcStatuses($ip_ID,currScreen) != "Main"} {
    set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
		set vaDxcStatuses($ip_ID,currScreen) "Main"
	}
  set ret [expr [SendToDxc4 $ip_ID "6\r" "IntfE1" 6] | $ret]
  lappend tempbuffer $gDxc4Buffer(id$ip_ID)
  DelayMs 50
  set ret [expr [SendToDxc4 $ip_ID "d" "SigTsAs2" 6] | $ret]
  lappend tempbuffer $gDxc4Buffer(id$ip_ID)
  DelayMs 50
  set ret [expr [SendToDxc4 $ip_ID "d" "InsErrSt" 6] | $ret]
  lappend tempbuffer $gDxc4Buffer(id$ip_ID)
  set gDxc4Buffer(id$ip_ID) $tempbuffer
  DelayMs 50
  #set ret [expr [SendToDxc4 $ip_ID "d" "AllOneRx" 6] | $ret]	 some time with plink we don't get a few bytes after "AllOneRx" we need its.
  set ret [expr [SendToDxc4 $ip_ID "d" ">" 6] | $ret]
  lappend tempbuffer $gDxc4Buffer(id$ip_ID)
  set gDxc4Buffer(id$ip_ID) $tempbuffer

  if {![regexp {IpForEth [ ,0-9]+} $gDxc4Buffer(id$ip_ID) match]} {
  	set	gMessage "GetConfig procedure: Cann't get parameter IpForEth from Dxc-4"
    return $fail
  } else {
      set ip [join [lrange $match 1 4] .]
      set results(id$ip_ID,IpForEth) $ip
  }

  foreach param {SrcClock TimeRes SigRun BertRun InsErrSt DiagPort AllOneRx} {
     if {![regexp "$param \[ ,0-9\]+" $gDxc4Buffer(id$ip_ID) match]} {
        set vaDxcStatuses($ip_ID,currScreen) "na"
      	set	gMessage "GetConfig procedure: Cann't get parameter $param from Dxc-4"
        return $fail
     }
     set results(id$ip_ID,$param) [lindex $vaDxcStatuses(l$param) [lindex $match 1]]

  }

  foreach param {FrameT1 CodeT1 IntfT1 MaskT1 SyncT1 FrameE1 CodeE1 RstTimE1 IntfE1 BalancE1 SigEnbl SigType IncSpeed BertEnbl BertPatt InsErrRt InsErrEn PortLpSt AllOneTx} {
     if {![regexp "$param \[ ,0-9\]+" $gDxc4Buffer(id$ip_ID) match]} {
        set vaDxcStatuses($ip_ID,currScreen) "na"
      	set	gMessage "GetConfig procedure: Cann't get parameter $param from Dxc-4"
        return $fail
     }
     for {set i 1} {$i <= $vaDxcStatuses($ip_ID,numbPorts)} {incr i} {
		   if {$param == "MaskT1" && $results(id$ip_ID,IntfT1,Port$i) == "dsu"} {
         set results(id$ip_ID,$param,Port$i) [lindex $vaDxcStatuses(lMaskT1DSU) [lindex $match $i]]
			 } else {
           set results(id$ip_ID,$param,Port$i) [lindex $vaDxcStatuses(l$param) [lindex $match $i]]
			 }
     }
  }

  foreach param {IdleT1 OosT1 IdleE1 OosE1 SigValue SigTsAs0 SigTsAs1 SigTsAs2 SigTsAs3 BerTsAs0 BerTsAs1 BerTsAs2 BerTsAs3} {
     if {![regexp "$param \[ ,0-9,A-F,a-f\]+" $gDxc4Buffer(id$ip_ID) match]} {
        set vaDxcStatuses($ip_ID,currScreen) "na"
      	set	gMessage "GetConfig procedure: Cann't get parameter $param from Dxc-4"
        return $fail
     }
     for {set i 1} {$i <= $vaDxcStatuses($ip_ID,numbPorts)} {incr i} {
       set results(id$ip_ID,$param,Port$i) [lindex $match $i]
		 	 if {$param == "BerTsAs3"} {
		 	 	 if {$vaDxcStatuses($ip_ID,linkType) == "E1" && $results(id$ip_ID,FrameE1,Port$i) == "unframe"} {
		 	 		 set results(id$ip_ID,bertRate,Port$i) 2048000
		 	   } elseif {$vaDxcStatuses($ip_ID,linkType) == "T1" && $results(id$ip_ID,FrameT1,Port$i) == "unframe"} {
		 	 		 set results(id$ip_ID,bertRate,Port$i) 1544000
		 	   } else {
		 	 	     set varbert ""
		 	 	 		 foreach group  {BerTsAs0 BerTsAs1 BerTsAs2 BerTsAs3}	 {
		 	 	 		 	 append varbert \\x$results(id$ip_ID,$group,Port$i)
		 	 	 		 }
		 	 	 		 set chann 0
		 	 	 		 eval binary scan $varbert  B* tss
		 	 	 		 for {set j 1} {$j <= 31} {incr j} {
		 	 	 		   if {$j == 16 && $vaDxcStatuses($ip_ID,linkType) == "E1" && 
		 	 	 			     ($results(id$ip_ID,FrameE1,Port$i) == "g732s" ||
		 	 	 					  $results(id$ip_ID,FrameE1,Port$i) == "g732scrc4")} {
		 	 	 				 continue
		 	 	 			 }
		 	 	 		   if {[string index $tss [expr $j - 1]] == 1} {
		 	 	 				 incr chann
		 	 	 			 }
		 	 	 		 }
		 	 	 		 set results(id$ip_ID,bertRate,Port$i) [expr $chann * 64000]
		 	 	 }
		 	 }
     }
  }
  set ret [expr [SendToDxc4 $ip_ID "!" "File Utilities" 6] | $ret]
  set vaDxcStatuses($ip_ID,currScreen) "Main"
  set results(id$ip_ID,linkType) $vaDxcStatuses($ip_ID,linkType)
	set results(id$ip_ID,updPort) $vaDxcStatuses($ip_ID,updPort)
	if {$ret} {
    set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}


#***************************************************************************
#**                        RLDxc4::CompareConfig
#** 
#**  Abstract: Compare Configuration of any two Dxc-4's ports
#**
#**   Inputs:
#**            ip_ID1                   :	        ID of first Dxc-4 returned by Open procedure .
#**                              
#**            ip_ID2                   :	        ID of second Dxc-4 returned by Open procedure .
#**                              
#**            ip_Port1                 :         first port for comparing 
#**                              
#**            ip_Port2                 :         second port for comparing 
#**                              
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::CompareConfig 1 1 1 8 
#***************************************************************************

proc CompareConfig {ip_ID1 ip_ID2 ip_Port1 ip_Port2} {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaDxcStatuses($ip_ID1,dxcID)]} {
  	set	gMessage "CompareConfig procedure: The Dxc-4 with ID=$ip_ID1 doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID1,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID1 ]} {
  	  set	gMessage "CompareConfig procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID1"
      return $fail
    }
  }

  if {$vaDxcStatuses($ip_ID2,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID2 ]} {
  	  set	gMessage "CompareConfig procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID2"
      return $fail
    }
  }

  if {![info exists vaDxcStatuses($ip_ID2,dxcID)]} {
  	set	gMessage "CompareConfig procedure: The Dxc-4 with ID=$ip_ID2 doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$ip_Port1 < 1 || $ip_Port1 > $vaDxcStatuses($ip_ID1,numbPorts)} {
  	set	gMessage "CompareConfig procedure: The Dxc-4 didn't has the port with number $ip_Port1"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$ip_Port2 < 1 || $ip_Port2 > $vaDxcStatuses($ip_ID2,numbPorts)} {
  	set	gMessage "CompareConfig procedure: The Dxc-4 didn't has the port with number $ip_Port2"
    return [RLEH::Handle SAsyntax gMessage]
  }

  set res [RLDxc4::GetConfig $ip_ID1 firstConf]
  if {$res == $fail} {
  	append	gMessage "CompareConfig procedure: Cann't get configuration by GetConfig proc.\n"
    return $fail
  }
  if {$ip_ID1 != $ip_ID2} {
    set res [RLDxc4::GetConfig $ip_ID2 secondConf]
    if {$res == $fail} {
    	append	gMessage "CompareConfig procedure: Cann't get configuration by GetConfig proc.\n"
      return $fail
    }
  } else {
      array set secondConf [array get firstConf]
  }

  foreach param {FrameT1 CodeT1 IntfT1 MaskT1 SyncT1 FrameE1 RstTimE1 IntfE1 BalancE1 SigEnbl SigType IncSpeed  \
                 BertEnbl BertPatt InsErrRt InsErrEn IdleT1 OosT1 IdleE1 OosE1 SigValue SigTsAs0 SigTsAs1 SigTsAs2 SigTsAs3 \
                 BerTsAs0 BerTsAs1 BerTsAs2 BerTsAs3 PortLpSt AllOneTx} {

    if {![string match $firstConf(id$ip_ID1,$param,Port$ip_Port1)  $secondConf(id$ip_ID2,$param,Port$ip_Port2)]} {
    	append	gMessage "CompareConfig procedure: The parameter $param of port $ip_Port1 doesn't match to port $ip_Port2.\n"
      return $fail
    }
  }

  foreach param {TimeRes InsErrSt linkType DiagPort} {

    if {![string match $firstConf(id$ip_ID1,$param)  $secondConf(id$ip_ID2,$param)]} {
    	append	gMessage "CompareConfig procedure: The parameter $param of first DXC-4 doesn't match to second DXC-4.\n"
      return $fail
    }
  }
  return $ok
}



#***************************************************************************
#**                        RLDxc4::Start
#** 
#**  Abstract: Start Berts or Signaling generator.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Dxc-4 returned by Open procedure .
#**                              
#**            ip_object               :        bert/sign
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::Start 1 bert  
#***************************************************************************

proc Start {ip_ID ip_object} {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "Start procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID]} {
  	  set	gMessage "Start procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }


  if {[string match -nocase $ip_object "bert"]} {
    set object bert
  } elseif {[string match -nocase $ip_object "sign"]} {
      set object sign
  } else {
    	set	gMessage "Start procedure: Wrong parameter $ip_object (must be bert/sign)."
      return [RLEH::Handle SAsyntax gMessage]
  }
	set ret 0
	if {$object == "bert" && $vaDxcStatuses($ip_ID,currScreen) != "Berts"} {
    set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
    set ret [expr [SendToDxc4 $ip_ID "4\r" "Clear Statistics" 6] | $ret]
    set vaDxcStatuses($ip_ID,currScreen) "Berts"
	} elseif {$object == "bert" && $vaDxcStatuses($ip_ID,currScreen) == "Berts"} {
      set ret [expr [SendToDxc4 $ip_ID "\r" "Clear Statistics" 6] | $ret]
	} elseif {$object == "sign" && $vaDxcStatuses($ip_ID,currScreen) != "Signaling"} {
      set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
      set ret [expr [SendToDxc4 $ip_ID "3\r" "Current signaling" 6] | $ret]
      set vaDxcStatuses($ip_ID,currScreen) "Signaling"
	} elseif {$object == "sign" && $vaDxcStatuses($ip_ID,currScreen) == "Signaling"} {
      set ret [expr [SendToDxc4 $ip_ID "\r" "Clear Statistics" 6] | $ret]
	}

  if {[string match "*(Stop)*" $gDxc4Buffer(id$ip_ID)]} {
    set ret [expr [SendToDxc4 $ip_ID "6\r" "Clear Statistics" 6] | $ret]
    if {[string match "*ERROR*" $gDxc4Buffer(id$ip_ID)]} {
      set vaDxcStatuses($ip_ID,currScreen) "na"
			SendToDxc4 $ip_ID "\r" "Clear Statistics" 6
    	set	gMessage "Start procedure: If port has unframe mode , the BERT's time slot assignment must be unframe too and vice versa"
      return $fail
    }
  }
	if {$ret} {
    set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  if {$object == "bert" && !$ret} {
     set  vaDxcStatuses($ip_ID,bertRun) 1
  } elseif {$object == "sign"} {
       set  vaDxcStatuses($ip_ID,bertRun) 0
  } else {
      return $ret
  }

  return $ret
}


#***************************************************************************
#**                        RLDxc4::Stop
#** 
#**  Abstract: Stops Berts or Signaling generator.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Dxc-4 returned by Open procedure .
#**                              
#**            ip_object               :        bert/sign
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::Stop 1 bert  
#***************************************************************************

proc Stop {ip_ID ip_object} {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "Stop procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "Stop procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }

  if {[string match -nocase $ip_object "bert"]} {
    set object bert
  } elseif {[string match -nocase $ip_object "sign"]} {
      set object sign
  } else {
    	set	gMessage "Stop procedure: Wrong parameter $ip_object (must be bert/sign)."
      return [RLEH::Handle SAsyntax gMessage]
  }

	set ret 0
	if {$object == "bert" && $vaDxcStatuses($ip_ID,currScreen) != "Berts"} {
    set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
    set ret [expr [SendToDxc4 $ip_ID "4\r" "Clear Statistics" 6] | $ret]
    set vaDxcStatuses($ip_ID,currScreen) "Berts"
	} elseif {$object == "bert" && $vaDxcStatuses($ip_ID,currScreen) == "Berts"} {
      set ret [expr [SendToDxc4 $ip_ID "\r" "Clear Statistics" 6] | $ret]
	} elseif {$object == "sign" && $vaDxcStatuses($ip_ID,currScreen) != "Signaling"} {
      set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
      set ret [expr [SendToDxc4 $ip_ID "3\r" "Current signaling" 6] | $ret]
      set vaDxcStatuses($ip_ID,currScreen) "Signaling"
	} elseif {$object == "sign" && $vaDxcStatuses($ip_ID,currScreen) == "Signaling"} {
      set ret [expr [SendToDxc4 $ip_ID "\r" "Clear Statistics" 6] | $ret]
	}

  if {![string match "*(Stop)*" $gDxc4Buffer(id$ip_ID)]} {
    set ret [expr [SendToDxc4 $ip_ID "6\r" "Clear Statistics" 6] | $ret]
  }

	if {$ret} {
    set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  if {$object == "bert" && !$ret} {
     set  vaDxcStatuses($ip_ID,bertRun) 0
  } elseif {$object == "sign"} {
       set  vaDxcStatuses($ip_ID,bertRun) 0
  } else {
      return $ret
  }

  return $ret
}


#***************************************************************************
#**                        RLDxc4::BertInject
#** 
#**  Abstract: Inject Berts o errors.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Dxc-4 returned by Open procedure .
#**            [ip_port]               :         ports will be inject errors
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::BertInject 1   
#***************************************************************************

proc BertInject {ip_ID {ip_port 0}} {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "BertInject procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "BertInject procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }
	set ret 0
  if {$vaDxcStatuses($ip_ID,currScreen) == "bertStatis" && $ip_port == 0} {
    set ret [expr [SendToDxc4 $ip_ID "I" "DXC-4" 6] | $ret]
	} else {
      if {$vaDxcStatuses($ip_ID,currScreen) != "Berts" } {
		    set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
		    set ret [expr [SendToDxc4 $ip_ID "4\r" "Clear Statistics" 6] | $ret]
        set vaDxcStatuses($ip_ID,currScreen) "Berts"
			}
			if {$ip_port != 0} {
		    set ret [expr [SendToDxc4 $ip_ID "9\r" "H" 6] | $ret]
		    set ret [expr [SendToDxc4 $ip_ID "$ip_port\r" "Clear Statistics" 6] | $ret]
		    if {[string match "*ERROR*" $gDxc4Buffer(id$ip_ID)]} {
          set vaDxcStatuses($ip_ID,currScreen) "na"
		      set	gMessage "Inject bert procedure: Wrong ports parameter: $ip_port"
		      return [RLEH::Handle SAsyntax gMessage]
		    }
			}
      set ret [expr [SendToDxc4 $ip_ID "10\r" "Clear Statistics" 6] | $ret]
	}
	if {$ret} {
    set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  Delay 1
  return $ret
}


#***************************************************************************
#**                        RLDxc4::BPVInject
#** 
#**  Abstract: Inject BPV errors by specific ports.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Dxc-4 returned by Open procedure .
#**            [ip_port]               :         ports will be inject BPV errors
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::BPVInject 1   
#**	 RLDxc4::BPVInject 1 1-4  
#***************************************************************************

proc BPVInject {ip_ID {ip_port 0}} {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "BPVInject procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "BPVInject procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }
	set ret 0

  if {$vaDxcStatuses($ip_ID,currScreen) != "Berts" } {
    set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
    set ret [expr [SendToDxc4 $ip_ID "4\r" "Clear Statistics" 6] | $ret]
    set vaDxcStatuses($ip_ID,currScreen) "Berts"
	}
	if {$ip_port != 0} {
    set ret [expr [SendToDxc4 $ip_ID "9\r" "H" 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$ip_port\r" "Clear Statistics" 6] | $ret]
    if {[string match "*ERROR*" $gDxc4Buffer(id$ip_ID)]} {
      set vaDxcStatuses($ip_ID,currScreen) "na"
      set	gMessage "BPVInject procedure: Wrong ports parameter: $ip_port"
      return [RLEH::Handle SAsyntax gMessage]
    }
	}
  set ret [expr [SendToDxc4 $ip_ID "12\r" "Clear Statistics" 6] | $ret]
	if {$ret} {
    set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}



#***************************************************************************
#**                        RLDxc4::SetLoop
#** 
#**  Abstract: Set or clear any loop in specific ports.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Dxc-4 returned by Open procedure .
#**            ip_loop                 :         loop type: local/remote/none
#**            [ip_port]               :         port number(current port default)
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::SetLoop 1 local    
#**	 RLDxc4::SetLoop 1 off 4  
#***************************************************************************

proc SetLoop {ip_ID ip_loop {ip_port 0}} {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "SetLoop procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "SetLoop procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }
	if {![regexp -nocase {remote|local|none} $ip_loop match]} {
	  set	gMessage "SetLoop procedure: Wrong parameter: $ip_loop (must be local/remote/off)"
    return [RLEH::Handle SAsyntax gMessage]
	}
	set ret 0

  if {$vaDxcStatuses($ip_ID,currScreen) != "Diagnostic" } {
    set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
    set ret [expr [SendToDxc4 $ip_ID "7\r" "Set" 6] | $ret]
    set vaDxcStatuses($ip_ID,currScreen) "Diagnostic"
	}
	if {$ip_port != 0} {
    set ret [expr [SendToDxc4 $ip_ID "1\r" "8." 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$ip_port\r" "Set" 6] | $ret]
    if {[string match "*ERROR*" $gDxc4Buffer(id$ip_ID)]} {
      set vaDxcStatuses($ip_ID,currScreen) "na"
      set	gMessage "SetLoop procedure: Wrong ports parameter: $ip_port"
      return [RLEH::Handle SAsyntax gMessage]
    }
	}
	#refresh to get screen into buffer
  set ret [expr [SendToDxc4 $ip_ID "\r" "Set" 6] | $ret]

  switch -exact -- [string tolower $match]  {

					local {
									if {[string match "*(ON_L)*" $gDxc4Buffer(id$ip_ID)] || [string match "*(ON_R)*" $gDxc4Buffer(id$ip_ID)]} {
									  set	gMessage "SetLoop procedure: There is already loop in current  port"
										return $fail
									} else {
                      set ret [expr [SendToDxc4 $ip_ID "2\r" "Set" 6] | $ret]
									}

					}

					remote {
									if {[string match "*(ON_L)*" $gDxc4Buffer(id$ip_ID)] || [string match "*(ON_R)*" $gDxc4Buffer(id$ip_ID)]} {
									  set	gMessage "SetLoop procedure: There is already loop in current port"
										return $fail
									} else {
                      set ret [expr [SendToDxc4 $ip_ID "3\r" "Set" 6] | $ret]
									}
					}

					none {
								if {[string match "*(ON_L)*" $gDxc4Buffer(id$ip_ID)]} {
                  set ret [expr [SendToDxc4 $ip_ID "2\r" "Set" 6] | $ret]
								} elseif {[string match "*(ON_R)*" $gDxc4Buffer(id$ip_ID)]} {
                    set ret [expr [SendToDxc4 $ip_ID "3\r" "Set" 6] | $ret]
								}
					}
	}

	if {$ret} {
    set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}


#***************************************************************************
#**                        RLDxc4::SetAllOnes
#** 
#**  Abstract: Set transmit all ones in specific ports.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Dxc-4 returned by Open procedure .
#**            ip_value                :         value on/off
#**            [ip_port]               :         port number(current port default)
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::SetAllOnes 1 on    
#**	 RLDxc4::SetAllOnes 1 off 4  
#***************************************************************************

proc SetAllOnes {ip_ID ip_value {ip_port 0}} {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "SetAllOnes procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "SetAllOnes procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }
	set ret 0

  if {$vaDxcStatuses($ip_ID,currScreen) != "Diagnostic" } {
    set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
    set ret [expr [SendToDxc4 $ip_ID "7\r" "Set" 6] | $ret]
    set vaDxcStatuses($ip_ID,currScreen) "Diagnostic"
	}
	if {$ip_port != 0} {
    set ret [expr [SendToDxc4 $ip_ID "1\r" "8." 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$ip_port\r" "Set" 6] | $ret]
    if {[string match "*ERROR*" $gDxc4Buffer(id$ip_ID)]} {
      set vaDxcStatuses($ip_ID,currScreen) "na"
      set	gMessage "SetAllOnes procedure: Wrong ports parameter: $ip_port"
      return [RLEH::Handle SAsyntax gMessage]
    }
	}
	#refresh to get screen into buffer
  set ret [expr [SendToDxc4 $ip_ID "\r" "Set" 6] | $ret]

  switch -exact -- [string tolower $ip_value]  {

					on {
									if {[string match "*OFF_TAIS*" $gDxc4Buffer(id$ip_ID)]} {
                    set ret [expr [SendToDxc4 $ip_ID "4\r" "Set" 6] | $ret]
									}
					}

					off {
									if {[string match "*ON_TAIS*" $gDxc4Buffer(id$ip_ID)]} {
                    set ret [expr [SendToDxc4 $ip_ID "4\r" "Set" 6] | $ret]
									}
					}

					default {
									  set	gMessage "SetAllOnes procedure: Wrong value $ip_value (must be on/off)"
										return $fail
					}
	}

	if {$ret} {
    set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}


#***************************************************************************
#**                        RLDxc4::GetAllOnes
#** 
#**  Abstract: Get status of all ones in receive of specific ports.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Dxc-4 returned by Open procedure .
#**            op_res                  :         result of status all ones: on/off
#**            [ip_port]               :         port number(current port default)
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::GetAllOnes 1 res    
#**	 RLDxc4::GetAllOnes 1 res 4  
#***************************************************************************

proc GetAllOnes {ip_ID op_res {ip_port 0}} {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0

	upvar $op_res result 
  catch {unset result}
  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "GetAllOnes procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "GetAllOnes procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }
	set ret 0

  if {$vaDxcStatuses($ip_ID,currScreen) != "Diagnostic" } {
    set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
    set ret [expr [SendToDxc4 $ip_ID "7\r" "Set" 6] | $ret]
    set vaDxcStatuses($ip_ID,currScreen) "Diagnostic"
	}
	if {$ip_port != 0} {
    set ret [expr [SendToDxc4 $ip_ID "1\r" "8." 6] | $ret]
    set ret [expr [SendToDxc4 $ip_ID "$ip_port\r" "Set" 6] | $ret]
    if {[string match "*ERROR*" $gDxc4Buffer(id$ip_ID)]} {
      set vaDxcStatuses($ip_ID,currScreen) "na"
      set	gMessage "GetAllOnes procedure: Wrong ports parameter: $ip_port"
      return [RLEH::Handle SAsyntax gMessage]
    }
	}
	#refresh to get screen into buffer
  set ret [expr [SendToDxc4 $ip_ID "\r" "Set" 6] | $ret]

	if {[string match "*OFF_RAIS*" $gDxc4Buffer(id$ip_ID)]} {
    set result off
	} elseif {[string match "*ON_RAIS*" $gDxc4Buffer(id$ip_ID)]} {
      set result on
	}

	if {$ret} {
    set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}



#***************************************************************************
#**                        RLDxc4::ShowGui
#** 
#**  Abstract: Show Gui of generator.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Dxc-4 returned by Open procedure will be into resource entry in select mode.
#**                              
#**            args   parameters and their value:
#**
#**                -idlist                       IDs of others Dxc-4 returned by Open procedure will be into resource entry.
#**                -statistics                   bertStatis/signStatis will be rise.
#**								 -showHide										 SHOW/HIDE/ICONIFY
#**								 -closeChassis								 yes/no close chassis while destroy
#**
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::ShowGui 1 -idlist "2 3" -statistics  bertStatis 	 -showHide	SHOW	-closeChassis no
#***************************************************************************

proc ShowGui {ip_ID args} {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vaDxc4Gui
  variable      vaDxc4Set
  variable      vaDxc4Cfg

	set	showHide	 0
	set statistics 4
	set base       .topDxc4Gui

  if {$ip_ID == "?"} {
    return "arguments options:  -idlist , -statistics , -showHide"
  }

  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "ShowGui procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
		tk_messageBox -icon error -type ok -message $gMessage -title "E1/T1 Generator"
    return $fail
    #return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "ShowGui procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
  		tk_messageBox -icon error -type ok -message $gMessage -title "E1/T1 Generator"
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
										  		tk_messageBox -icon error -type ok -message $gMessage -title "E1/T1 Generator"
										      return $fail
	                       # return [RLEH::Handle SAsyntax gMessage]
												}
											  if {![info exists vaDxcStatuses($ind,dxcID)]} {
											  	set	gMessage "ShowGui procedure: The Dxc-4 with ID=$ind of idlist: $val doesn't opened"
										  		tk_messageBox -icon error -type ok -message $gMessage -title "E1/T1 Generator"
										      return $fail
											    #return [RLEH::Handle SAsyntax gMessage]
											  }
											}
											set idlist $val
						 }

						-statistics {
                      if {$val == "?"} {
                        return "statistics options:  bertStatis , signStatis"
                      }
                      if {$val == "signStatis"} {
                		    set	statistics	3
                      } elseif {$val == "bertStatis"} {
                		      set	statistics	4
							     	  } else {
	                		    set	gMessage "ShowGui procedure: The  value $val of parameter $param wrong"
	                        return [RLEH::Handle SAsyntax gMessage]
											}
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


  RLDxc4::MakeDxc4Gui
  RLDxc4::OkConnChassis $vaDxcStatuses($ip_ID,dxcHandle) $vaDxcStatuses($ip_ID,package) $ip_ID

	if {[info exists idlist]} {
	  foreach chass $idlist {
      RLDxc4::OkConnChassis $vaDxcStatuses($chass,dxcHandle) $vaDxcStatuses($chass,package) $chass
      #$vaDxc4Gui(resources,list) insert end  chassis:$chass -text  "chassis $chass" -fill red -indent 10 -font {times 14}
		}
	}
	$vaDxc4Gui(notebook) raise [$vaDxc4Gui(notebook) page $statistics]

	if {[info exists closeChassis]} {
	  set vaDxc4Set(closeByDestroy) $closeChassis
	}

}



#***************************************************************************
#**                        RLDxc4::Clear
#** 
#**  Abstract: Clear Berts or Signaling generator.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Dxc-4 returned by Open procedure .
#**                              
#**            ip_object               :        bert/sign
#**            [ip_port]               :        ports will be cleared.
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::Clear 1 bert  
#***************************************************************************

proc Clear {ip_ID ip_object {ip_port 0}} {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "Clear procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "Clear procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }

  if {[string match -nocase $ip_object "bert"]} {
    set object bert
  } elseif {[string match -nocase $ip_object "sign"]} {
      set object sign
  } else {
    	set	gMessage "Clear procedure: Wrong parameter $ip_object (must be bert/sign)."
      return [RLEH::Handle SAsyntax gMessage]
  }

	set ret 0
  if {$object == "bert"} {

		if {$vaDxcStatuses($ip_ID,currScreen) == "bertStatis" && $ip_port == 0} {
	    set ret [expr [SendToDxc4 $ip_ID "C" "DXC-4" 6] | $ret]
		} else {
	      if {$vaDxcStatuses($ip_ID,currScreen) != "Berts" } {
			    set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
			    set ret [expr [SendToDxc4 $ip_ID "4\r" "Clear Statistics" 6] | $ret]
	        set vaDxcStatuses($ip_ID,currScreen) "Berts"
				}
				if {$ip_port != 0} {
			    set ret [expr [SendToDxc4 $ip_ID "9\r" "H" 6] | $ret]
			    set ret [expr [SendToDxc4 $ip_ID "$ip_port\r" "Clear Statistics" 6] | $ret]
			    if {[string match "*ERROR*" $gDxc4Buffer(id$ip_ID)]} {
	          set vaDxcStatuses($ip_ID,currScreen) "na"
			      set	gMessage "Cleart bert procedure: Wrong ports parameter: $ip_port"
			      return [RLEH::Handle SAsyntax gMessage]
			    }
				}
	      set ret [expr [SendToDxc4 $ip_ID "11\r" "Clear Statistics" 6] | $ret]
		}
  }  else {
      if {$vaDxcStatuses($ip_ID,currScreen) == "signStatis"} {
        set ret [SendToDxc4 $ip_ID "C" "DXC-4" 6]
      } else {
	        if {$vaDxcStatuses($ip_ID,currScreen) != "Signaling" } {
            set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
            set ret [expr [SendToDxc4 $ip_ID "3\r" "Clear Statistics" 6] | $ret]
            set vaDxcStatuses($ip_ID,currScreen) "Signaling"
					}
          set ret [expr [SendToDxc4 $ip_ID "9\r" "Clear Statistics" 6] | $ret]
      }
  }
	if {$ret} {
    set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}

#***************************************************************************
#**                        RLDxc4::GetStatistics
#** 
#**  Abstract: Get statistics of berts or signaling generator.
#**
#**   Inputs:
#**            ip_ID                   :	        ID of Dxc-4 returned by Open procedure .
#**                              
#**            op_results              :          Array of results.
#**                              
#**            args   parameters and their value:
#**                              
#**                              
#**  					 -statistic              :	      bertStatis/signStatis/signValue/signTsError.
#**                              
#**  					 -port      	           :	      1-8/all.
#**                              
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	1. RLDxc4::GetStatistics 1  res  -statistic bertStatis -port 6
#**	2. RLDxc4::GetStatistics 4  res  -statistic signStatis -port all
#***************************************************************************

proc GetStatistics {ip_ID op_results args } {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage "" 
  set port           all                
	set fail          -1
	set ok             0

  upvar $op_results  results
  catch {unset results}
  if {$ip_ID == "?"} {
    return "arguments options:  -statistic , -port "
  }

  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "GetStatistics procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "GetStatistics procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }

	#processing command line parameters
  foreach {param val}   $args   {
   
    switch -exact -- $param  {
    

						-statistic {
                      if {$val == "?"} {
                        return "arguments options:  bertStatis , signStatis , signValue , signTsError"
                      }

                      if {$val != "bertStatis" && $val == "signStatis" && $val == "signValue" && $val == "signTsError"} {
                		    set	gMessage "GetStatistics procedure: Wrong value of parameter $param"
                        return [RLEH::Handle SAsyntax gMessage]
                      }
											set statistic $val
						 }

						-port {
                    if {$val == "?"} {
                      return "-port options:  1-8 , all"
                    }
                    if {[string match -nocase $val  "all"] && $vaDxcStatuses($ip_ID,updPort) != "all" } {
              		      set	gMessage "GetStatistics procedure: The value $val of parameter $param mismatch to updeted port"
                        return [RLEH::Handle SAsyntax gMessage]
                    } elseif {[string match -nocase $val  "all"] && $vaDxcStatuses($ip_ID,updPort) == "all"} {
												set port $val
                    } elseif {[set res [catch {expr int($val)}]]} {
                		    set	gMessage "GetStatistics procedure: The value $val of parameter $param isn't integer"
                        return [RLEH::Handle SAsyntax gMessage]
                    } elseif {$vaDxcStatuses($ip_ID,numbPorts) == 4 && $val >5} {
              		      set	gMessage "GetStatistics procedure: The value $val of parameter $param wrong"
                        return [RLEH::Handle SAsyntax gMessage]
                    } elseif {$val < 1 || $val > 8} {
              		      set	gMessage "GetStatistics procedure: The value $val of parameter $param wrong"
                        return [RLEH::Handle SAsyntax gMessage]
						     	  } else {
												set port $val
										}
						 }

             default {
                      set gMessage "GetStatistics procedure:   Wrong name of parameter $param"
                      return [RLEH::Handle SAsyntax gMessage]
             }
		}
	}



  switch -exact -- $statistic  {

    bertStatis  {
      if {$vaDxcStatuses($ip_ID,currScreen) != "bertStatis"} {
        set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
        set ret [expr [SendToDxc4 $ip_ID "4\r" "Clear Statistics" 6] | $ret]
        set ret [expr [SendToDxc4 $ip_ID "7\r" ">" 6] | $ret]
        set vaDxcStatuses($ip_ID,currScreen) "bertStatis"
      } else {
          set ret [SendToDxc4 $ip_ID "\r" ">" 6] 
      }
      if {$port == "all"} {
         for {set i 1} {$i <= $vaDxcStatuses($ip_ID,numbPorts)} {incr i} {
           if {[regexp "Bert$i \[ ,0-9\]+" $gDxc4Buffer(id$ip_ID) match ]} {
             set results(id$ip_ID,runTime,Port$i) [lindex $match 1]
             set results(id$ip_ID,syncLoss,Port$i) [lindex $match 2]
             set results(id$ip_ID,errorSec,Port$i) [lindex $match 3]
             set results(id$ip_ID,errorBits,Port$i) [lindex $match 4]
           }
         }
      } else {
           if {[regexp "Bert$port \[ ,0-9\]+" $gDxc4Buffer(id$ip_ID) match ]} {
             set results(id$ip_ID,runTime,Port$port) [lindex $match 1]
             set results(id$ip_ID,syncLoss,Port$port) [lindex $match 2]
             set results(id$ip_ID,errorSec,Port$port) [lindex $match 3]
             set results(id$ip_ID,errorBits,Port$port) [lindex $match 4]
           } else {
				      set	gMessage "GetStatistics procedure: There are not Bert statistics for Bert$port"
		          return $fail
					 }
      }

    }

    signStatis  {
      if {$vaDxcStatuses($ip_ID,currScreen) != "signStatis"} {
        set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
        set ret [expr [SendToDxc4 $ip_ID "3\r" "Clear Statistics" 6] | $ret]
        set ret [expr [SendToDxc4 $ip_ID "7\r" ">" 6] | $ret]
        set vaDxcStatuses($ip_ID,currScreen) "signStatis"
      } else {
          set ret [SendToDxc4 $ip_ID "\r" ">" 6]
      }
      if {$port == "all"} {
         for {set i 1} {$i <= $vaDxcStatuses($ip_ID,numbPorts)} {incr i} {
           if {[regexp "Port$i \[ ,0-9\]+" $gDxc4Buffer(id$ip_ID) match ]} {
             set results(id$ip_ID,sentSign,Port$i) [lindex $match 1]
             set results(id$ip_ID,receivedSign,Port$i) [lindex $match 2]
             set results(id$ip_ID,errorSign,Port$i) [lindex $match 3]
           }
         }
      } else {
           if {[regexp "Port$port \[ ,0-9\]+" $gDxc4Buffer(id$ip_ID) match ]} {
             set results(id$ip_ID,sentSign,Port$port) [lindex $match 1]
             set results(id$ip_ID,receivedSign,Port$port) [lindex $match 2]
             set results(id$ip_ID,errorSign,Port$port) [lindex $match 3]
           } else {
				      set	gMessage "GetStatistics procedure: There are not Sign statistics for Port$port"
		          return $fail
					 }
      }

    }

    signValue  {
      if {$vaDxcStatuses($ip_ID,currScreen) != "signValue"} {
        set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
        DelayMs 30
        set ret [expr [SendToDxc4 $ip_ID "3\r" "Clear Statistics" 6] | $ret]
        if {$vaDxcStatuses($ip_ID,linkType) == "E1"} {
          set ret [expr [SendToDxc4 $ip_ID "10\r" "TS12" 6] | $ret]
          lappend tempbuffer $gDxc4Buffer(id$ip_ID)
          DelayMs 50
          set ret [expr [SendToDxc4 $ip_ID "d" "TS25" 6] | $ret]
          lappend tempbuffer $gDxc4Buffer(id$ip_ID)
          DelayMs 50
          set ret [expr [SendToDxc4 $ip_ID "d" "TS31" 6] | $ret]
          lappend tempbuffer $gDxc4Buffer(id$ip_ID)
          set gDxc4Buffer(id$ip_ID)  $tempbuffer
        } else {
            set ret [expr [SendToDxc4 $ip_ID "10\r" "TS12" 6] | $ret]
            lappend tempbuffer $gDxc4Buffer(id$ip_ID)
            DelayMs 50
            set ret [expr [SendToDxc4 $ip_ID "d" "TS24" 6] | $ret]
            lappend tempbuffer $gDxc4Buffer(id$ip_ID)
            set gDxc4Buffer(id$ip_ID)  $tempbuffer
        }
        set vaDxcStatuses($ip_ID,currScreen) "signValue"
      } else {
          set ret [SendToDxc4 $ip_ID "\33" "DXC-4" 6]
          DelayMs 30
          if {$vaDxcStatuses($ip_ID,linkType) == "E1"} {
            set ret [expr [SendToDxc4 $ip_ID "10\r" "TS12" 6] | $ret]
            lappend tempbuffer $gDxc4Buffer(id$ip_ID)
            DelayMs 50
            set ret [expr [SendToDxc4 $ip_ID "d" "TS25" 6] | $ret]
            lappend tempbuffer $gDxc4Buffer(id$ip_ID)
            DelayMs 50
            set ret [expr [SendToDxc4 $ip_ID "d" "TS31" 6] | $ret]
            lappend tempbuffer $gDxc4Buffer(id$ip_ID)
            set gDxc4Buffer(id$ip_ID)  $tempbuffer
          } else {
              set ret [expr [SendToDxc4 $ip_ID "10\r" "TS12" 6] | $ret]
              lappend tempbuffer $gDxc4Buffer(id$ip_ID)
              DelayMs 50
              set ret [expr [SendToDxc4 $ip_ID "d" "TS24" 6] | $ret]
              lappend tempbuffer $gDxc4Buffer(id$ip_ID)
              set gDxc4Buffer(id$ip_ID)  $tempbuffer
          }
      }
      if {[regexp "TSs   \[ ,1-8,P,o,r,t\]+" $gDxc4Buffer(id$ip_ID) matchports ]} {
        set numb [llength $matchports]
      } else {
          set vaDxcStatuses($ip_ID,currScreen) "na"
		      set	gMessage "GetStatistics procedure: There are not statistics for signaling value"
          return $fail
      }
      for {set i 1} {$i < 32} {incr i} {
         if {[regexp "TS$i \[ ,0-9,A-F,a-f\]+" $gDxc4Buffer(id$ip_ID) match ]} {
           if {$port == "all"} {
             for {set j 1} {$j < $numb} {incr j} {
               set ch [lindex $matchports $j]
               set results(id$ip_ID,$ch,signValue,TS$i) [lindex $match $j]  
             }
           } else {
               set results(id$ip_ID,Port$port,signValue,TS$i) [lindex $match $port]  
           }
         }
      }
    }

    signTsError  {
      if {$vaDxcStatuses($ip_ID,currScreen) != "signTsError"} {
        set ret [SendToDxc4 $ip_ID "!" "File Utilities" 6]
        DelayMs 30
        set ret [expr [SendToDxc4 $ip_ID "3\r" "Clear Statistics" 6] | $ret]
				if {[string match "*(all)*" $gDxc4Buffer(id$ip_ID)]} {
					return 0
				}
        if {$vaDxcStatuses($ip_ID,linkType) == "E1"} {
          set ret [expr [SendToDxc4 $ip_ID "8\r" "TS12" 6] | $ret]
          lappend tempbuffer $gDxc4Buffer(id$ip_ID)
          DelayMs 50
          set ret [expr [SendToDxc4 $ip_ID "d" "TS25" 6] | $ret]
          lappend tempbuffer $gDxc4Buffer(id$ip_ID)
          DelayMs 50
          set ret [expr [SendToDxc4 $ip_ID "d" "TS31" 6] | $ret]
          lappend tempbuffer $gDxc4Buffer(id$ip_ID)
          set gDxc4Buffer(id$ip_ID)  $tempbuffer
        } else {
            set ret [expr [SendToDxc4 $ip_ID "8\r" "TS12" 6] | $ret]
            lappend tempbuffer $gDxc4Buffer(id$ip_ID)
            DelayMs 50
            set ret [expr [SendToDxc4 $ip_ID "d" "TS24" 6] | $ret]
            lappend tempbuffer $gDxc4Buffer(id$ip_ID)
            set gDxc4Buffer(id$ip_ID)  $tempbuffer
        }
        set vaDxcStatuses($ip_ID,currScreen) "signTsError"
      } else {
          set ret [SendToDxc4 $ip_ID "\33" "DXC-4" 6]
          DelayMs 30
					if {[string match "*(all)*" $gDxc4Buffer(id$ip_ID)]} {
						return 0
					}
          if {$vaDxcStatuses($ip_ID,linkType) == "E1"} {
            set ret [expr [SendToDxc4 $ip_ID "8\r" "TS12" 6] | $ret]
            lappend tempbuffer $gDxc4Buffer(id$ip_ID)
            DelayMs 50
            set ret [expr [SendToDxc4 $ip_ID "d" "TS25" 6] | $ret]
            lappend tempbuffer $gDxc4Buffer(id$ip_ID)
            DelayMs 50
            set ret [expr [SendToDxc4 $ip_ID "d" "TS31" 6] | $ret]
            lappend tempbuffer $gDxc4Buffer(id$ip_ID)
            set gDxc4Buffer(id$ip_ID)  $tempbuffer
          } else {
              set ret [expr [SendToDxc4 $ip_ID "8\r" "TS12" 6] | $ret]
              lappend tempbuffer $gDxc4Buffer(id$ip_ID)
              DelayMs 50
              set ret [expr [SendToDxc4 $ip_ID "d" "TS24" 6] | $ret]
              lappend tempbuffer $gDxc4Buffer(id$ip_ID)
              set gDxc4Buffer(id$ip_ID)  $tempbuffer
          }
      }
      if {[regexp "TSs   \[ ,1-8,P,o,r,t\]+" $gDxc4Buffer(id$ip_ID) matchports ]} {
        set numb [llength $matchports]
      } else {
          set vaDxcStatuses($ip_ID,currScreen) "na"
		      set	gMessage "GetStatistics procedure: There are not statistics for signaling ts errors"
          return $fail
      }
      for {set i 1} {$i < 32} {incr i} {
         if {[regexp "TS$i \[ ,0-9\]+" $gDxc4Buffer(id$ip_ID) match ]} {
           if {$port == "all"} {
             for {set j 1} {$j < $numb} {incr j} {
               set ch [lindex $matchports $j]
               set results(id$ip_ID,$ch,errors,TS$i) [lindex $match $j]  
             }
           } else {
               set results(id$ip_ID,Port$port,errors,TS$i) [lindex $match $port]  
           }
         }
      }
    }
    default {
            set gMessage "GetStatistics procedure:   Wrong name of statistic $statistic"
            return [RLEH::Handle SAsyntax gMessage]
    }
  }
	if {$ret} {
    set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}


#***************************************************************************
#**                        RLDxc4::ChkConnect
#** 
#**  Abstract: Checks the connection to Dxc4.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Dxc-4 returned by Open procedure .
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::ChkConnect 1   
#***************************************************************************

proc ChkConnect {ip_ID } {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vaDxc4Cfg
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "ChkConnect procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$vaDxcStatuses($ip_ID,package) == "plink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "ChkConnect procedure: The plink process doesn't exist for DXC-4 with ID=$ip_ID"
      return $fail
    }
  }


  for {set i 1} {$i <= 2} {incr i} {
    set ret [SendToDxc4 $ip_ID "\r" "DXC-4" 2]
    if {!$ret} {
      break
    }
  }

  if {$ret} {
    set gMessage "ChkConnect procedure: Dxc4 with id=$ip_ID isn't connected to Host.\nIt's recommended after CHASSIS RESET or POWER OFF disconnect and again connect the chassis in resources pane."
    set vaDxcStatuses($ip_ID,currScreen) "na"
    return $fail
	}
	if {$vaDxcStatuses($ip_ID,currScreen) != "Main" && [string match "*Main Menu*" $gDxc4Buffer(id$ip_ID)]} {
    set vaDxcStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}



#*******************************************************************************
#**                        RLDxc4::Close
#** 
#**  Abstract: Close DXC-4.
#**
#**   Inputs:
#**            ip_ID                   :	       ID of Dxc-4 returned by Open procedure .
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::Close 1   
#******************************************************************************

proc Close {ip_ID} {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "Close procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  switch -exact -- $vaDxcStatuses($ip_ID,connection)  {
    

			com {
          if {$vaDxcStatuses($ip_ID,package) == "RLCom"} {
            RLCom::Close $vaDxcStatuses($ip_ID,dxcHandle)
          } else {
              RLSerial::Close $vaDxcStatuses($ip_ID,dxcHandle)
          }
      }

			telnet {
        if {$vaDxcStatuses($ip_ID,package) == "RLTcp"} {
           RLTcp::TelnetClose  $vaDxcStatuses($ip_ID,dxcHandle)
        } elseif {$vaDxcStatuses($ip_ID,package) == "plink"} {
            set pids [pid $vaDxcStatuses($ip_ID,dxcHandle)]
            exec taskkill.exe  /fi "PID eq $pids"  /f /t 
            catch {close $vaDxcStatuses($ip_ID,dxcHandle)}
        }
      }
  }

  unset vaDxcStatuses($ip_ID,dxcID)
  unset vaDxcStatuses($ip_ID,dxcHandle)
  unset vaDxcStatuses($ip_ID,connection)
  unset vaDxcStatuses($ip_ID,package)

  return $ok
}


#***************************************************************************
#**                        RLDxc4::CloseAll
#** 
#**  Abstract: Close all DXC-4.
#**
#**   Inputs:
#**                              
#**   Outputs: 
#**            0                       :        if success. 
#**            Negativ error cod or    :        Otherwise.     
#**            error message by RLEH 	 				
#**                              
#** Example:                        
#**	 RLDxc4::CloseAll  
#***************************************************************************

proc CloseAll {} {

  global        gDxc4Buffer
  global        gMessage
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0

	for {set i 1} {$i <= $vOpenedDxcHistoryCounter} {incr i} {
		if {[info exists vaDxcStatuses($i,dxcID)]} {
		  RLDxc4::Close $vaDxcStatuses($i,dxcID)
		}
	}
  set  vOpenedDxcHistoryCounter 0
}
#***************************************************************************
#***************************************************************************
#
#                  INTERNAL FUNCTIONs
#
#***************************************************************************
#***************************************************************************

#***************************************************************************
#**                        OpenDxc
#** 
#**  Abstract: The internal procedure Open the RLDxc4 by com or telnet
#**            Check if the RLDxc4 is ready to be activate
#**
#**   Inputs:
#**            ip_address           :	        Com number or IP address.
#**                              
#**  					 ip_connection        :	        com/telnet.
#**                              
#**  					 ip_package           :	        RLCom/RLSerial/RLTcp/plink.
#**                              
#**            ip_place             :         location into vaDxcStatuses array
#**                              
#**   Outputs: 
#**            0                    :         If success. 
#**            Negativ error cod    :         Otherwise.     
#***************************************************************************
proc OpenDxc {ip_address ip_connection ip_package ip_place} {

  global        gMessage
  global        gDxc4Buffer
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
  set gMessage ""                   

	set fail          -1
	set ok             0

  switch -exact -- $ip_connection  {
    

			com {
            package require $ip_package
            if {$ip_package == "RLCom"} {
						  if [catch {RLCom::Open $ip_address 115200 8 NONE 1 } msg] {
						    set gMessage "RLDxc4 Open:  Cann't open com by RLCom: $msg"
						    return $fail
							}
            } else {
                if {[RLSerial::Open $ip_address 115200 n 8 1]} {
							    set gMessage "RLDxc4 Open:  Cann't open com$ip_address by RLSerial"
							    return $fail
								}
            }
            set  vaDxcStatuses($ip_place,dxcHandle) $ip_address

      }

			telnet {
        if {$ip_package == "RLTcp"} {
            package require $ip_package
            set handle [RLTcp::TelnetOpen $ip_address]
            set  vaDxcStatuses($ip_place,dxcHandle) $handle
        } else {
            set handle [open "|plink -telnet $ip_address" w+]
            fconfigure $handle -blocking 0 -buffering none  -translation binary
            set  vaDxcStatuses($ip_place,dxcHandle) $handle
        }

      }
  }
	set ret 0
  for {set i 1} {$i <= 3} {incr i} {
    set ret [expr [SendToDxc4 $ip_place "!" "File Utilities" 2] | $ret]
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
          } elseif {$ip_package == "plink" } {
              set pids [pid $handle]
              exec taskkill.exe  /fi "PID eq $pids"  /f /t 
              catch {close $handle}
          }
        }
    }
    set vaDxcStatuses($ip_place,currScreen) "na"
    set gMessage "RLDxc4 Open:  Cann't connect to DXC-4"
    return $fail
  }
  if {[string match "*( 8 PORTS )*" $gDxc4Buffer(id$ip_place)]} {
    set  vaDxcStatuses($ip_place,numbPorts) 8
  } elseif {[string match "*( 4 PORTS )*" $gDxc4Buffer(id$ip_place)]} {
      set  vaDxcStatuses($ip_place,numbPorts) 4
  } else {
      set vaDxcStatuses($ip_place,currScreen) "na"
      set gMessage "RLDxc4 Open:  Cann't recognize DXC-4/4 or DXC-4/8"
      return $fail
  }

  DelayMs 100
  set ret [expr [SendToDxc4 $ip_place "3\r" "Current signaling" 6] | $ret]
  if {[string match "*(Stop)*" $gDxc4Buffer(id$ip_place)]} {
    set  vaDxcStatuses($ip_place,signRun) 0
  } elseif {[string match "*(Run)*" $gDxc4Buffer(id$ip_place)]} {
      set  vaDxcStatuses($ip_place,signRun) 1
  } else {
      set vaDxcStatuses($ip_place,currScreen) "na"
      set gMessage "RLDxc4 Open:  Cann't recognize Signaling generator running state"
      return $fail
  }

  if {[string match "*(E1)*" $gDxc4Buffer(id$ip_place)]} {
    set  vaDxcStatuses($ip_place,linkType) E1
  } elseif {[string match "*(T1)*" $gDxc4Buffer(id$ip_place)]} {
      set  vaDxcStatuses($ip_place,linkType) T1
  }

  set ret [expr [SendToDxc4 $ip_place "!" "File Utilities" 6] | $ret]
  DelayMs 200
  set ret [expr [SendToDxc4 $ip_place "4\r" "Clear Statistics" 6] | $ret]
  if {[string match "*(Stop)*" $gDxc4Buffer(id$ip_place)]} {
    set  vaDxcStatuses($ip_place,bertRun) 0
  } elseif {[string match "*(Run)*" $gDxc4Buffer(id$ip_place)]} {
      set  vaDxcStatuses($ip_place,bertRun) 1
  } else {
      set vaDxcStatuses($ip_place,currScreen) "na"
      set gMessage "RLDxc4 Open:  Cann't recognize bert running state"
      return $fail
  }

  set ret [expr [SendToDxc4 $ip_place "2\r" "All Ports" 6] | $ret]
  if {$vaDxcStatuses($ip_place,numbPorts) == 4} {
    set ret [expr [SendToDxc4 $ip_place "5\r" "Clear Statistics" 6] | $ret]
  } else {
      set ret [expr [SendToDxc4 $ip_place "9\r" "Clear Statistics" 6] | $ret]
  }
  set vaDxcStatuses($ip_place,updPort) "all"
	if {$ret} {
    set vaDxcStatuses($ip_place,currScreen) "na"
	} else {
      set vaDxcStatuses($ip_place,currScreen) "Berts"
	}
  return $ret
}


#***************************************************************************
#**                        SendToDxc4
#** 
#**  Abstract: The internal procedure send string to Dxc4 by com or telnet
#**
#**   Inputs:
#**            ip_ID                :	        ID of DXC-4.
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

proc SendToDxc4 {ip_ID ip_sended {ip_expected stamstam} {ip_timeout 10}} {

  global        gMessage gDxc4Buffer gDxc4BufferDebug telnetBuffer$ip_ID
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
	set fail          -1
	set ok             0

  if {$gDxc4BufferDebug} {
    puts "\n---- SendToDxc4 -------\nSended to DXC-4 ID $ip_ID : $ip_sended" 
  }
  update

  switch -exact -- $vaDxcStatuses($ip_ID,connection)  {
    

			com {

           switch -exact -- $vaDxcStatuses($ip_ID,package) {

             RLCom {
                     if {$ip_expected=="stamstam" } {
                        RLCom::SendSlow $vaDxcStatuses($ip_ID,dxcHandle) $ip_sended 30
                        set ret 0
                     } else {
                         set ret [RLCom::SendSlow $vaDxcStatuses($ip_ID,dxcHandle) $ip_sended 30 gDxc4Buffer(id$ip_ID) $ip_expected $ip_timeout]
                         if {$ret} {
                           set gMessage "SendToDxc4 procedure:   Return cod = $ret while (RLCom::SendSlow $vaDxcStatuses($ip_ID,dxcHandle) $ip_sended 30 gDxc4Buffer(id$ip_ID) $ip_expected $ip_timeout)"
                         }
                     }
             }

             RLSerial {
                     if {$ip_expected=="stamstam" } {
                        RLSerial::SendSlow $vaDxcStatuses($ip_ID,dxcHandle) $ip_sended 30
                        set ret 0
                     } else {
                         set ret [RLSerial::SendSlow $vaDxcStatuses($ip_ID,dxcHandle) $ip_sended 30 gDxc4Buffer(id$ip_ID) $ip_expected $ip_timeout]
                         if {$ret} {
                           set gMessage "SendToDxc4 procedure:   Return cod = $ret while (RLSerial::SendSlow $vaDxcStatuses($ip_ID,dxcHandle) $ip_sended 30 gDxc4Buffer(id$ip_ID) $ip_expected $ip_timeout)"
                         }
                     }
             }
           }
      }

			telnet {

           switch -exact -- $vaDxcStatuses($ip_ID,package) {
             
             RLTcp {
                     set len [string length $ip_sended]
                     for {set ind 0} {$ind < $len} {incr ind} {
                       RLTcp::Send $vaDxcStatuses($ip_ID,dxcHandle) [string index $ip_sended $ind]
                       DelayMs 30
                     }
                     set ret 0
                     if {$ip_expected != "stamstam" } {
                       DelayMs 300
                       set ret [RLTcp::Waitfor  $vaDxcStatuses($ip_ID,dxcHandle)  $ip_expected  telnetBuffer$ip_ID  $ip_timeout]
                       set gDxc4Buffer(id$ip_ID) [set telnetBuffer$ip_ID]
                       if {$ret} {
                         set gMessage "SendToDxc4 procedure:   Return cod = $ret while (RLTcp::Waitfor $vaDxcStatuses($ip_ID,dxcHandle) $ip_expected  gDxc4Buffer(id$ip_ID)  $ip_timeout)"
                       }
                     }

             }
             plink {
                    set len [string length $ip_sended]
                    for {set ind 0} {$ind < $len} {incr ind} {
                      puts -nonewline $vaDxcStatuses($ip_ID,dxcHandle) [string index $ip_sended $ind]
                      DelayMs 30
                    }
                    set gDxc4Buffer(id$ip_ID) ""
                    set startTime [clock seconds]
                    while 1 {
                      DelayMs 30
                      lappend gDxc4Buffer(id$ip_ID) [read $vaDxcStatuses($ip_ID,dxcHandle)]
                      if {$ip_expected != "stamstam" } {
                        if {[string match "*$ip_expected*" $gDxc4Buffer(id$ip_ID)]} {
                          set ret 0
                          break
                        } else {
                            set ret $fail
                        }
                      } else {
                          set ret 0
                          break
                      }

                      set timeNow [clock seconds]
                      set runTime [expr $timeNow - $startTime]
                      if {$runTime>$ip_timeout} {
                        break
                      }
                    }
                    if {$ret} {
                       set gMessage "SendToDxc4 procedure:   Return cod = $ret while (puts $vaDxcStatuses($ip_ID,dxcHandle) $ip_sended  and read $ip_expected  gDxc4Buffer(id$ip_ID)  $ip_timeout  by plink)"
                    }
             }

           }
      }
  }
  FilterBuffer $ip_ID
  if {$gDxc4BufferDebug} {
    puts "Expected : $ip_expected .  Received : \n$gDxc4Buffer(id$ip_ID)\n---- SendToDxc4 ------" 
  }
  update
  return $ret
}

# ................................................................................
#  Abstract: Checks if plink process exists for opened DXC-4 by  plink package
#
#**            ip_ID                :	        ID of DXC-4.
#**                              
#**   Outputs: 
#**            0                    :         If success. 
#**            Negativ error cod    :         Otherwise.     
# ................................................................................
proc CheckPlinkExist {ip_ID} {
  global        gMessage gDxc4Buffer gDxc4BufferDebug
  variable      vaDxcStatuses 
  variable      vOpenedDxcHistoryCounter
	set fail          -1
	set ok             0

  if {![info exists vaDxcStatuses($ip_ID,dxcID)]} {
  	set	gMessage "CheckPlinkExist procedure: The Dxc-4 with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  set pids [pid $vaDxcStatuses($ip_ID,dxcHandle)]
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
#  Abstract: clean buffer from junk after read dxc4 by com or telnet
#
#  Inputs: 
#
#  Outputs: 
# ..............................................................................
proc FilterBuffer {ip_ID} {
  global gDxc4Buffer
  variable      vaDxcStatuses 
  set re \[\x1B\x08\[\]
  regsub -all -- $re         $gDxc4Buffer(id$ip_ID) " " 1
  #regsub -all -- .1C       $1      " " 2
  
  #set gDxc4Buffer(id$ip_ID) $2
  set gDxc4Buffer(id$ip_ID) $1
}

# ...........................................................................
#  Abstract: Build dxc4 GUI.
#
#  Inputs: 
#
#  Outputs: 
# ..........................................................................
proc MakeDxc4Gui {} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
 
  set rundir [file dirname [info script]]  
	if {[regexp -nocase {RLDxc4.exe} $rundir match]} {
    #for starpacks applications
    set dir [string range $rundir 0 [string last / $rundir]]
    set   vaDxc4Set(rundir) [append dir application]
	} else {
      set   vaDxc4Set(rundir) C:/RLFiles/Dxc4
	}

  #set vaDxc4Set(rundir) [pwd]
	set vaDxc4Set(hexcodes) "00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F \
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

  set vaDxc4Set(listIP)	 ""
	set vaDxc4Set(connect,com) ""
	set vaDxc4Set(connect,telnet) ""

	set base .topDxc4Gui
	toplevel $base -class Toplevel		
  wm focusmodel $base passive
	wm overrideredirect $base 0
  wm title $base "E1/T1 Generators"
  wm protocol $base WM_DELETE_WINDOW {RLDxc4::CloseDxc4Gui}
  #wm geometry . +180+25
  #wm geometry $base 292x240+$shiftX+$shiftY
  #wm geometry $base 292x260+$shiftX+$shiftY
  #wm resizable $base 0 0

  wm geometry $base 800x550
	bind .topDxc4Gui <F1> {set gConsole show; console show} 

    variable notebook
    variable mainframe

  set vaDxc4Set(prgtext) "Please wait while loading font..."
  set vaDxc4Set(prgindic) -1
  _create_intro
  update
  SelectFont::loadfont
	set vaDxc4Set(currentid) ""

  set descmenu {
    "&File" {} {} 0 {		
	     {cascad "&Console" {} console 0 {
		      {radiobutton "console show" {} "Console Show" {} \
		       -command "console show" -value show -variable gConsole}
		      {radiobutton "console hide" {} "Console Hide" {} \
		       -command "console hide" -value hide -variable gConsole}
		     }
		    }
						{command	"Get Configuration from file..." {getcfgfile} {} {} -command {RLDxc4::GetConfigFromFile}}
						{command	"Save Configuration to file..." {savecfgfile} {} {} -command {RLDxc4::SaveConfigToFile}}
						{command	"Set Configuration to chassis" {savecfgchass} {} {} -command {RLDxc4::SaveConfigToChassis}}

	     {separator}
	     {command "Destroy" {exit} {Exit} {} -command {RLDxc4::CloseDxc4Gui}}		
	     {command "Quit" {quit} {Exit} {} -command {RLDxc4::Quit}}		
	   }	
 	  "&Run" {} {} 0 {
 	      {command "Run Signaling" {sign} {} {} -command {set RLDxc4::vaDxc4Set(runType) 0 ; RLDxc4::RunCurrentChassis 0 $RLDxc4::vaDxc4Set(currentid)}}
 	      {command "Run Bert" {bert} {} {} -command {set RLDxc4::vaDxc4Set(runType) 1 ; RLDxc4::RunCurrentChassis 1 $RLDxc4::vaDxc4Set(currentid)}}
		  }
 	  "&Connection" {} {} 0 {
	      {command "Connect Chassis..." {connect} {} {} -command {RLDxc4::ConnectChassis}}
	      {command "Disconnect Chassis" {disconnect} {} {} -command {RLDxc4::DelDxcResource}}
		  }
 	  "&Tools" {} {} 0 {
  	    {command "Disconnect" {disconn} {} {} -command {RLDxc4::DelDxcResource}}
  	    {command "Factory setup" {factory} {} {} -command {RLDxc4::FactorySetup}}
  	    {command "Reset chassis" {reset} {} {} -command {RLDxc4::ResetChassis}}
		  }
    "&Help" {} {} 0 {
         {command "&Index" {} {} {} -command {RLDxc4::GetHelp}}
         {command "&About E1/T1 Generators" {} {} {} -command {tk_messageBox \
           -icon info -type ok -message "E1/T1 Generators\n Ver. 1.41\n Copyright © 2006, Rad Data Communications"\
							 -title "About E1/T1 Generators"}}
			 }
  } 
  set mainframe [MainFrame $base.mainframe -menu $descmenu -textvariable vaDxc4Gui(status) -progressvar  vaDxc4Gui(prgindic)]
  set vaDxc4Gui(startTime) [$mainframe addindicator]
  set vaDxc4Gui(runTime) [$mainframe addindicator]
  set vaDxc4Gui(runStatus) [$mainframe addindicator]
  
 	#$base.mainframe setmenustate results disabled

 # toolbar  creation
  incr vaDxc4Set(prgindic)
  set tb  [$mainframe addtoolbar]
  set bbox [ButtonBox $tb.bbox1 -spacing 0 -padx 1 -pady 1]
  set vaDxc4Gui(tb,new) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/new] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLDxc4::SaveConfigToFile} \
      -helptext "Save configuration  to a file"]
  set vaDxc4Gui(tb,open) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/open] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLDxc4::GetConfigFromFile} \
      -helptext "Get configuration from a existing file"]
  set vaDxc4Gui(tb,save) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/save] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLDxc4::SaveConfigToChassis} \
      -helptext "Set configuration from GUI to chassis"]

	lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(tb,new) $vaDxc4Gui(tb,open) $vaDxc4Gui(tb,save)

  pack $bbox -side left -anchor w
  set sep [Separator $tb.sep1 -orient vertical]
  pack $sep -side left -fill y -padx 4 -anchor w

  set bbox [ButtonBox $tb.bbox2 -spacing 0 -padx 1 -pady 1]
  set vaDxc4Gui(tb,connect) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/connect] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLDxc4::ConnectChassis} \
      -helptext "Connect a chassis"]
  #set vaDxc4Gui(tb,inject) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/inject] \
   #   -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 \
    #  -helptext "Inject error"]
  set vaDxc4Gui(tb,help) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/help] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLDxc4::GetHelp} \
      -helptext "Help topics"]

  pack $bbox -side left -anchor w
  set sep [Separator $tb.sep2 -orient vertical]
  pack $sep -side left -fill y -padx 4 -anchor w

  set bbox [ButtonBox $tb.bbox4 -spacing 0 -padx 1 -pady 1]
  set vaDxc4Gui(tb,run) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/run] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLDxc4::RunCurrentChassis $RLDxc4::vaDxc4Set(runType) $RLDxc4::vaDxc4Set(currentid)} \
      -helptext "Run the current chassis"]
  set vaDxc4Gui(tb,stop) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/stop] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLDxc4::StopCurrentChassis $RLDxc4::vaDxc4Set(runType) $RLDxc4::vaDxc4Set(currentid)} \
      -helptext "Stop the current chassis"]

  pack $bbox -side left -anchor w
  set sep [Separator $tb.sep3 -orient vertical]
  pack $sep -side left -fill y -padx 4 -anchor w

  set bbox [ButtonBox $tb.bbox3 -spacing 0 -padx 1 -pady 1]
  set vaDxc4Gui(tb,multirun) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/mulrun] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLDxc4::RunAllChassis} \
      -helptext "Run all chassis"]
  set vaDxc4Gui(tb,multistop) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/mulstop] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {RLDxc4::StopAllChassis} \
      -helptext "Stop all chassis"]

  pack $bbox -side left -anchor w

  #Resource pane creation
  set frame    [$mainframe getframe]

  set pw    [PanedWindow $frame.pw -side top]

  set pane  [$pw add -weight 1]
  set title [TitleFrame $pane.lf -text "Resources"]
  set vaDxc4Gui(resources,sw)  [ScrolledWindow [$title getframe].sw -relief sunken -borderwidth 2]

  set vaDxc4Gui(resources,list) [ListBox::create $vaDxc4Gui(resources,sw).lb \
                -relief flat -borderwidth 0 \
                -dragevent 3 \
                -dropenabled 1 \
                -width 20 -highlightthickness 0 -bg white\
                -redraw 0 -dragenabled 0 \
                -droptypes {
                    TREE_NODE    {copy {} move {} link {}}
                    LISTBOX_ITEM {copy {} move {} link {}}}]

  $vaDxc4Gui(resources,sw) setwidget $vaDxc4Gui(resources,list)
	set vaDxc4Set(resources,list) ""

  pack $vaDxc4Gui(resources,sw) -fill both -expand yes
  pack $title -fill both  -expand yes


  $vaDxc4Gui(resources,list) bindText  <ButtonPress-1>        "RLDxc4::SelectDxcResource"
  #$vaDxc4Gui(resources,list) bindText  <ButtonPress-3> "RLDxc4::DelDxcResource"
 # $vaDxc4Gui(resources,list) bindImage <Double-ButtonPress-1> "DemoTree::select list 2 $tree $list"


  # NoteBook creation
  set framenb    [frame $frame.framenb]
  set notebook [NoteBook $framenb.nb]
  set vaDxc4Gui(notebook) $notebook

	#Port setup tab creation
	set vaDxc4Set(linkType) T1
#	set vaDxc4Set(clocsrc) int
#	set vaDxc4Set(port)  All
#	set vaDxc4Set(linktype,t1,frame) esf
#	set vaDxc4Set(linktype,t1,intftp) csu
#	set vaDxc4Set(linktype,t1,mask) 0
#	set vaDxc4Set(linktype,t1,sync) Fast
#	set vaDxc4Set(linktype,t1,linecod) Ami
#	set vaDxc4Set(linktype,t1,idlecod) 7F
#	set vaDxc4Set(linktype,t1,oos)  7F
#	set vaDxc4Set(linktype,e1,frame) g732n
#	set vaDxc4Set(linktype,e1,intftp) dsu
#	set vaDxc4Set(linktype,e1,bal) yes
#	set vaDxc4Set(linktype,e1,resttime) ccitt
#	set vaDxc4Set(linktype,e1,linecod)  hdb3
#	set vaDxc4Set(linktype,e1,idlecod) 7F
#	set vaDxc4Set(linktype,e1,oos)  7F
	set vaDxc4Set(runType) 1

  set vaDxc4Set(prgtext)   "Creating Ports Setup..."
  set frame1 [$notebook insert end Portsetup -text "Ports Setup"]

  	set vaDxc4Set(maskList) "0 7.5 15 22.5"
    set vaDxc4Gui(portsetup,linktype,t1) [TitleFrame $frame1.titf2 -text "Link type T1"]
  		set combofr1  [frame [$vaDxc4Gui(portsetup,linktype,t1) getframe].combofr1]
  		set combofr2  [frame [$vaDxc4Gui(portsetup,linktype,t1) getframe].combofr2]

			pack $combofr1 -anchor w
 			pack $combofr2 -anchor w
			  set titlcomb3 [TitleFrame $combofr1.titlcomb3 -text "Frame"]
			    set vaDxc4Gui(portsetup,linktype,t1,frame) [ComboBox [$titlcomb3 getframe].combo3  -justify center\
                   -textvariable RLDxc4::vaDxc4Set(linktype,t1,frame) -width 15 -modifycmd {RLDxc4::SaveChanges port frameT1}  \
                   -values {"sf" "esf" "unframe"} -helptext "This is the Frame type"]
				  pack $vaDxc4Gui(portsetup,linktype,t1,frame)
			  set titlcomb4 [TitleFrame $combofr1.titlcomb4 -text "Interface type"]
			    set vaDxc4Gui(portsetup,linktype,t1,intftp) [ComboBox [$titlcomb4 getframe].combo4  -justify center \
                   -textvariable RLDxc4::vaDxc4Set(linktype,t1,intftp) -width 15 -modifycmd {RLDxc4::SaveChanges port intfT1} \
                   -values {"dsu" "csu" } -helptext "This is the Inteface type" ]
				  pack $vaDxc4Gui(portsetup,linktype,t1,intftp)
			  set titlcomb5 [TitleFrame $combofr1.titlcomb5 -text "Mask"]
			    set vaDxc4Gui(portsetup,linktype,t1,mask) [ComboBox [$titlcomb5 getframe].combo5  -justify center \
                   -textvariable RLDxc4::vaDxc4Set(linktype,t1,mask) -width 15 -modifycmd {RLDxc4::SaveChanges port maskT1} \
                   -values $vaDxc4Set(maskList) -helptext "This is the Mask"]
				  pack $vaDxc4Gui(portsetup,linktype,t1,mask)
			  set titlcomb6 [TitleFrame $combofr1.titlcomb6 -text "Sync"]
			    set vaDxc4Gui(portsetup,linktype,t1,sync) [ComboBox [$titlcomb6 getframe].combo6  -justify center \
                   -textvariable RLDxc4::vaDxc4Set(linktype,t1,sync) -width 15 -modifycmd {RLDxc4::SaveChanges port syncT1} \
                   -values {"Fast" "62411"} -helptext "This is the Sync type"]
				  pack $vaDxc4Gui(portsetup,linktype,t1,sync)
				pack $titlcomb3	 $titlcomb4 $titlcomb5 $titlcomb6	 -side left	 -padx 4

			  set titlcomb7 [TitleFrame $combofr2.titlcomb7 -text "Line code"]
			    set vaDxc4Gui(portsetup,linktype,t1,linecod) [ComboBox [$titlcomb7 getframe].combo7  -justify center \
                   -textvariable RLDxc4::vaDxc4Set(linktype,t1,linecod) -width 15 -modifycmd {RLDxc4::SaveChanges port linecodeT1} \
                   -values {"Ami" "B8ZS" "Transp"} -helptext "This is the Line code"]
				  pack $vaDxc4Gui(portsetup,linktype,t1,linecod)
			  set titlcomb8 [TitleFrame $combofr2.titlcomb8 -text "Idle code"]
			    set vaDxc4Gui(portsetup,linktype,t1,idlecod) [ComboBox [$titlcomb8 getframe].combo8  -justify center \
                   -textvariable RLDxc4::vaDxc4Set(linktype,t1,idlecod) -width 15 -modifycmd {RLDxc4::SaveChanges port idleT1} \
                   -values $vaDxc4Set(hexcodes) -helptext "This is the Idle code"]
				  pack $vaDxc4Gui(portsetup,linktype,t1,idlecod)
			  set titlcomb9 [TitleFrame $combofr2.titlcomb9 -text "Oos"]
			    set vaDxc4Gui(portsetup,linktype,t1,oos) [ComboBox [$titlcomb9 getframe].combo9  -justify center \
                   -textvariable RLDxc4::vaDxc4Set(linktype,t1,oos) -width 15 -modifycmd {RLDxc4::SaveChanges port oosT1} \
                   -values $vaDxc4Set(hexcodes) -helptext "This is the Oos code"]
				  pack $vaDxc4Gui(portsetup,linktype,t1,oos)
				set titlcomb10 [TitleFrame $combofr2.titlname10 -text "Source clock"]
				  set vaDxc4Gui(portsetup,gencfg,clksrc) [ComboBox [$titlcomb10 getframe].combo10  -justify center \
		                 -textvariable RLDxc4::vaDxc4Set(clocksrc) -width 15 -modifycmd {RLDxc4::SaveChanges system clock} \
		                 -values {lbtUL int stnE1 stnT1 auto lbt1 lbt2 lbt3 lbt4 lbt5 lbt6 lbt7 lbt8} \
		                 -helptext "This is the Source clock"]
					pack $vaDxc4Gui(portsetup,gencfg,clksrc)
				pack $titlcomb7	 $titlcomb8 $titlcomb9 $titlcomb10 -side left	 -padx 4

				lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(portsetup,linktype,t1,frame) \
																						 $vaDxc4Gui(portsetup,linktype,t1,intftp) \
																						 $vaDxc4Gui(portsetup,linktype,t1,mask) \
																						 $vaDxc4Gui(portsetup,linktype,t1,sync) \
																						 $vaDxc4Gui(portsetup,linktype,t1,linecod) \
																						 $vaDxc4Gui(portsetup,linktype,t1,idlecod) \
																						 $vaDxc4Gui(portsetup,linktype,t1,oos) \
																						 $vaDxc4Gui(portsetup,gencfg,clksrc)
		#pack	$vaDxc4Gui(portsetup,linktype,t1) -fill x -pady 4

    set vaDxc4Gui(portsetup,linktype,e1) [TitleFrame $frame1.titf3 -text "Link type E1"]
  		set combofr3  [frame [$vaDxc4Gui(portsetup,linktype,e1) getframe].combofr3]
  		set combofr4  [frame [$vaDxc4Gui(portsetup,linktype,e1) getframe].combofr4]
			pack $combofr3 -anchor w
 			pack $combofr4 -anchor w
			  set titlcomb10 [TitleFrame $combofr3.titlcomb10 -text "Frame"]
			    set vaDxc4Gui(portsetup,linktype,e1,frame) [ComboBox [$titlcomb10 getframe].combo10  -justify center \
                   -textvariable RLDxc4::vaDxc4Set(linktype,e1,frame) -width 15 -modifycmd {RLDxc4::SaveChanges port frameE1} \
                   -values {"g732s" "g732scrc4" "g732n" "g732ncrc4" "unframe"} -helptext "This is the Frame type"]
				  pack $vaDxc4Gui(portsetup,linktype,e1,frame)
			  set titlcomb11 [TitleFrame $combofr3.titlcomb11 -text "Interface type"]
			    set vaDxc4Gui(portsetup,linktype,e1,intftp) [ComboBox [$titlcomb11 getframe].combo11  -justify center \
                   -textvariable RLDxc4::vaDxc4Set(linktype,e1,intftp) -width 15 -modifycmd {RLDxc4::SaveChanges port intfE1} \
                   -values {"ltu" "dsu"} -helptext "This is the Interface type"]
				  pack $vaDxc4Gui(portsetup,linktype,e1,intftp)
			  set titlcomb12 [TitleFrame $combofr3.titlcomb12 -text "Balance"]
			    set vaDxc4Gui(portsetup,linktype,e1,bal) [ComboBox [$titlcomb12 getframe].combo12  -justify center \
                   -textvariable RLDxc4::vaDxc4Set(linktype,e1,bal) -width 15 -modifycmd {RLDxc4::SaveChanges port balanE1} \
                   -values {"yes" "no"} -helptext "This is the Balance"]
				  pack $vaDxc4Gui(portsetup,linktype,e1,bal)
			  set titlcomb13 [TitleFrame $combofr3.titlcomb13 -text "Restoration time"]
			    set vaDxc4Gui(portsetup,linktype,e1,resttime) [ComboBox [$titlcomb13 getframe].combo13  -justify center\
                   -textvariable RLDxc4::vaDxc4Set(linktype,e1,resttime) -width 15 -modifycmd {RLDxc4::SaveChanges port syncE1} \
                   -values {"Fast" "62411" "ccitt"} -helptext "This is the Restoration time"]
				  pack $vaDxc4Gui(portsetup,linktype,e1,resttime)
				pack $titlcomb10	 $titlcomb11 $titlcomb12 $titlcomb13	 -side left	 -padx 4

			  set titlcomb14 [TitleFrame $combofr4.titlcomb14 -text "Line code"]
			    set vaDxc4Gui(portsetup,linktype,e1,linecod) [ComboBox [$titlcomb14 getframe].combo14  -justify center\
                   -textvariable RLDxc4::vaDxc4Set(linktype,e1,linecod) -width 15 -modifycmd {RLDxc4::SaveChanges port linecodeE1} \
                   -values {"Ami" "hdb3"} -helptext "This is the Line code"]
				  pack $vaDxc4Gui(portsetup,linktype,e1,linecod)
			  set titlcomb15 [TitleFrame $combofr4.titlcomb15 -text "Idle code"]
			    set vaDxc4Gui(portsetup,linktype,e1,idlecod) [ComboBox [$titlcomb15 getframe].combo15 -justify center \
                   -textvariable RLDxc4::vaDxc4Set(linktype,e1,idlecod) -width 15 -modifycmd {RLDxc4::SaveChanges port idleE1} \
                   -values $vaDxc4Set(hexcodes) -helptext "This is the Idle code"]
				  pack $vaDxc4Gui(portsetup,linktype,e1,idlecod)
			  set titlcomb16 [TitleFrame $combofr4.titlcomb16 -text "Oos"]
			    set vaDxc4Gui(portsetup,linktype,e1,oos) [ComboBox [$titlcomb16 getframe].combo16 -justify center \
                   -textvariable RLDxc4::vaDxc4Set(linktype,e1,oos) -width 15 -modifycmd {RLDxc4::SaveChanges port oosE1} \
                   -values $vaDxc4Set(hexcodes) -helptext "This is the Oos code"]
				  pack $vaDxc4Gui(portsetup,linktype,e1,oos)
				set titlcomb17 [TitleFrame $combofr4.titlname17 -text "Source clock"]
				  set vaDxc4Gui(portsetup,gencfg,clksrc) [ComboBox [$titlcomb17 getframe].combo17  -justify center \
		                 -textvariable RLDxc4::vaDxc4Set(clocksrc) -width 15 -modifycmd {RLDxc4::SaveChanges system clock} \
		                 -values {lbtUL int stnE1 stnT1 auto lbt1 lbt2 lbt3 lbt4 lbt5 lbt6 lbt7 lbt8} \
		                 -helptext "This is the Source clock"]
					pack $vaDxc4Gui(portsetup,gencfg,clksrc)

				pack $titlcomb14	 $titlcomb15 $titlcomb16 $titlcomb17 -side left	 -padx 4

	#	pack	$vaDxc4Gui(portsetup,linktype,e1) -fill x -pady 4
				lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(portsetup,linktype,e1,frame) \
																						 $vaDxc4Gui(portsetup,linktype,e1,intftp) \
																						 $vaDxc4Gui(portsetup,linktype,e1,bal) \
																						 $vaDxc4Gui(portsetup,linktype,e1,resttime) \
																						 $vaDxc4Gui(portsetup,linktype,e1,linecod) \
																						 $vaDxc4Gui(portsetup,linktype,e1,idlecod) \
																						 $vaDxc4Gui(portsetup,linktype,e1,oos) \
																						 $vaDxc4Gui(portsetup,gencfg,clksrc)



    set vaDxc4Gui(portsetup,diagnostic) [TitleFrame $frame1.diagfr -text "Diagnostics"]
  		set diagcombofr  [frame [$vaDxc4Gui(portsetup,diagnostic) getframe].diagcombofr]
  		set diagportsfr  [frame [$vaDxc4Gui(portsetup,diagnostic) getframe].diagportsfr]
  		set diagloopsfr  [frame [$vaDxc4Gui(portsetup,diagnostic) getframe].diagloopsfr]
  		set diagonesfr  [frame [$vaDxc4Gui(portsetup,diagnostic) getframe].diagonesfr]

			pack $diagcombofr -anchor w -pady 4
			pack $diagportsfr -anchor w -pady 4
			pack $diagloopsfr -anchor w -pady 4
			pack $diagonesfr -anchor w	-pady 4

			  set titlcombdiagport [TitleFrame $diagcombofr.titlcombdiagport -text "Diagnostic Port"]
			    set vaDxc4Gui(portsetup,diagnostic,diagport) [ComboBox [$titlcombdiagport getframe].combodiagport  -justify center \
                   -textvariable RLDxc4::vaDxc4Set(diagnostic,diagport) -width 15 -modifycmd {RLDxc4::SaveChanges port diagPort} \
                   -values {1 2 3 4 5 6 7 8} -helptext "This is the Port for diagnostics"]
				  pack $vaDxc4Gui(portsetup,diagnostic,diagport)

			  set titlcombloopport [TitleFrame $diagcombofr.titlcombloopport -text "Loop"]
			    set vaDxc4Gui(portsetup,diagnostic,loopport) [ComboBox [$titlcombloopport getframe].comboloopport  -justify center \
                   -textvariable RLDxc4::vaDxc4Set(diagnostic,loopport) -width 15 -modifycmd {RLDxc4::SaveChanges port loopPort} \
                   -values {local remote none} -helptext "This is the Port for diagnostics"]
				  pack $vaDxc4Gui(portsetup,diagnostic,loopport)

			  set titlcomballones [TitleFrame $diagcombofr.titlcomballones -text "Tx All Ones"]
			    set vaDxc4Gui(portsetup,diagnostic,txallones) [ComboBox [$titlcomballones getframe].comboallones  -justify center \
                   -textvariable RLDxc4::vaDxc4Set(diagnostic,txallones) -width 15 -modifycmd {RLDxc4::SaveChanges port txallones} \
                   -values {off on} -helptext "This is the Port for diagnostics"]
				  pack $vaDxc4Gui(portsetup,diagnostic,txallones)

	      set titlrxallones [TitleFrame $diagcombofr.titlrxallones -text "Rx All Ones"] 
		      set vaDxc4Gui(portsetup,diagnostic,rxallones) [LabelEntry [$titlrxallones getframe].entrrxallones  -justify center\
		                             -textvariable RLDxc4::vaDxc4Set(diagnostic,rxallones) -width 14 -editable 0]
			    pack $vaDxc4Gui(portsetup,diagnostic,rxallones)

				pack $titlcombdiagport $titlcombloopport $titlcomballones $titlrxallones -side left	 -padx 4


				set vaDxc4Gui(portsetup,diagnostic,ports) [LabelEntry $diagportsfr.entryports -label "" -width 10 -text "Ports"  \
				  	 -justify center -editable 0 -entrybg lightgray -relief flat]
				pack $vaDxc4Gui(portsetup,diagnostic,ports) -side left -padx 2
				for {set i 1} {$i<=8} {incr i} {
					set vaDxc4Gui(portsetup,diagnostic,port$i) [LabelEntry $diagportsfr.entryport$i -label "" -width 7 -text "$i"  \
					  	 -justify center -editable 0 -entrybg lightgray -relief flat]
					pack $vaDxc4Gui(portsetup,diagnostic,port$i) -side left -padx 2
				}


				set vaDxc4Gui(portsetup,diagnostic,loops) [LabelEntry $diagloopsfr.entryloops -label "" -width 10 -text "Loops"  \
				  	 -justify center -editable 0 -entrybg lightgray -relief flat]
				pack $vaDxc4Gui(portsetup,diagnostic,loops) -side left -padx 2
				for {set i 1} {$i<=8} {incr i} {
					set vaDxc4Gui(portsetup,diagnostic,loop$i) [LabelEntry $diagloopsfr.entryloop$i -width 7  -label "" -justify center \
					                     -textvariable RLDxc4::vaDxc4Set(diagnostic,port$i,loop) -relief flat -editable 0]
					pack $vaDxc4Gui(portsetup,diagnostic,loop$i) -side left -padx 2
				}


				set vaDxc4Gui(portsetup,diagnostic,txallonesstate) [LabelEntry $diagonesfr.txallonesstate -label "" -width 10 -text "Tx All Ones"  \
				  	 -justify center -editable 0 -entrybg lightgray -relief flat]
				pack $vaDxc4Gui(portsetup,diagnostic,txallonesstate) -side left -padx 2
				for {set i 1} {$i<=8} {incr i} {
					set vaDxc4Gui(portsetup,diagnostic,txallonesstate$i) [LabelEntry $diagonesfr.txallonesstate$i -width 7 -label "" -justify center \
					                 -textvariable RLDxc4::vaDxc4Set(diagnostic,port$i,txallonesstate) -relief flat -editable 0]
					pack $vaDxc4Gui(portsetup,diagnostic,txallonesstate$i) -side left -padx 2
				}
		pack	$vaDxc4Gui(portsetup,diagnostic) -fill x -pady 4
	
		lappend  vaDxc4Set(lDisabledEntries)	$vaDxc4Gui(portsetup,diagnostic,diagport) \
																					$vaDxc4Gui(portsetup,diagnostic,loopport) \
																					$vaDxc4Gui(portsetup,diagnostic,txallones)
  incr vaDxc4Set(prgindic)


	#Signaling setup tab creation
#	set vaDxc4Set(signtype) Incr
#	set vaDxc4Set(signval) AA
#	set vaDxc4Set(incrspeed) 1
#	set vaDxc4Set(timeres) 20
#	set vaDxc4Set(signenab,port) 1

  set vaDxc4Set(prgtext)   "Creating Signaling Setup..."
  set frame2 [$notebook insert end Signsetup -text "Signaling Setup"]

    set vaDxc4Gui(signsetup,signsetup) [TitleFrame $frame2.titf2 -text "Signaling setup"]
  		set combofr1  [frame [$vaDxc4Gui(signsetup,signsetup) getframe].combofr1]

			  set titlcomb4 [TitleFrame $combofr1.titlcomb4 -text "Signaling type"]
			    set vaDxc4Gui(signsetup,signsetup,signtype) [ComboBox [$titlcomb4 getframe].combo4 -justify center \
                   -textvariable RLDxc4::vaDxc4Set(signtype) -width 11 -modifycmd {RLDxc4::SaveChanges sign type} \
                   -values {"Fix" "Alter" "Incr" } -helptext "This is the Signaling type"]
				  pack $vaDxc4Gui(signsetup,signsetup,signtype)
			  set titlcomb5 [TitleFrame $combofr1.titlcomb5 -text "Signaling value"]
			    set vaDxc4Gui(signsetup,signsetup,signval) [ComboBox [$titlcomb5 getframe].combo5 -justify center \
                   -textvariable RLDxc4::vaDxc4Set(signval) -width 11 -modifycmd {RLDxc4::SaveChanges sign value} \
                   -values $vaDxc4Set(hexcodes) -helptext "This is the Signaling value"]
				  pack $vaDxc4Gui(signsetup,signsetup,signval)
			  set titlcomb6 [TitleFrame $combofr1.titlcomb6 -text "Incr sign speed"]
			    set vaDxc4Gui(signsetup,signsetup,incrspeed) [ComboBox [$titlcomb6 getframe].combo6 -justify center \
                   -textvariable RLDxc4::vaDxc4Set(incrspeed) -width 11 -modifycmd {RLDxc4::SaveChanges sign speed} \
                   -values {"1" "2" "3" "4" "8" "16"} -helptext "This is the Incr sign speed"]
				  pack $vaDxc4Gui(signsetup,signsetup,incrspeed)
			  set titlcomb7 [TitleFrame $combofr1.titlcomb7 -text "Time resolution"]
			    set vaDxc4Gui(signsetup,signsetup,timeres) [ComboBox [$titlcomb7 getframe].combo7 -justify center \
                   -textvariable RLDxc4::vaDxc4Set(timeres) -width 11 -modifycmd {RLDxc4::SaveChanges sign timeres} \
                   -values {10 20 30 40 50 60 70 80 90 100} -helptext "This is the Time resolution mlsecond"]
				  pack $vaDxc4Gui(signsetup,signsetup,timeres)

        set vaDxc4Gui(signsetup,signsetup,signenab) [checkbutton [$vaDxc4Gui(signsetup,signsetup) getframe].chkbut  \
				        -text "Signaling enable"  -command {RLDxc4::SaveChanges sign enable} \
                -variable RLDxc4::vaDxc4Set(signenab,port)]

 				pack $titlcomb4 $titlcomb5 $titlcomb6	 $titlcomb7  -side left	 -padx 4
			pack $combofr1 $vaDxc4Gui(signsetup,signsetup,signenab) -side left -anchor w

		pack	$vaDxc4Gui(signsetup,signsetup) -fill x -pady 4

		lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(signsetup,signsetup,signtype) \
																						 $vaDxc4Gui(signsetup,signsetup,signval) \
																						 $vaDxc4Gui(signsetup,signsetup,incrspeed) \
																						 $vaDxc4Gui(signsetup,signsetup,timeres) \
																						 $vaDxc4Gui(signsetup,signsetup,signenab)

		set vaDxc4Set(sign,allts) 0
    set vaDxc4Gui(signsetup,tsass) [TitleFrame $frame2.titf3 -text "Signaling TS assignment"]
      set frGrid [frame [$vaDxc4Gui(signsetup,tsass) getframe].frGrid]
        for {set i 1} {$i<=31} {incr i} {
					if {$vaDxc4Set(linkType) == "E1" || ($vaDxc4Set(linkType)== "T1" && $i<25)} {
				    set vaDxc4Set(signass,ts$i) 1
					}
          frame $frGrid.f$i -bd 2 -relief ridge -width 53 -height 53
          grid $frGrid.f$i -row [expr ($i-1)/8] -column [expr ($i-1)%8]
					if {$i < 10} {
					  set text "TS$i  "
					} else {
					  set text "TS$i"
					}
          set vaDxc4Gui(signsetup,tsass,ts$i) [checkbutton $frGrid.f$i.ch$i -text $text -variable RLDxc4::vaDxc4Set(signass,ts$i) \
					                                     -command {RLDxc4::SaveChanges sign tsass ; set RLDxc4::vaDxc4Set(sign,allts) 0}]
          pack $frGrid.f$i.ch$i
          lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(signsetup,tsass,ts$i)
  
        }
      set frBut [frame [$vaDxc4Gui(signsetup,tsass) getframe].frBut -bd 2 -relief sunken]
        set vaDxc4Gui(signsetup,tsass,setAll) [button $frBut.butSetAll -text "Set ALL" \
            -command {
              for {set i 1} {$i<=31} {incr i} {
							  if {$i >24 && $RLDxc4::vaDxc4Set(linkType)== "T1"} {
								  break
								}
                set RLDxc4::vaDxc4Set(signass,ts$i) 1
              }
							RLDxc4::SaveChanges sign tsass
          		set RLDxc4::vaDxc4Set(sign,allts) 1
              update
            }
        ]
        lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(signsetup,tsass,setAll)
        set vaDxc4Gui(signsetup,tsass,clrAll) [button $frBut.butClrAll -text "Clear ALL"\
            -command {
              for {set i 1} {$i<=31} {incr i} {
                set RLDxc4::vaDxc4Set(signass,ts$i) 0
              }
							RLDxc4::SaveChanges sign tsass
          		set RLDxc4::vaDxc4Set(sign,allts) 0
              update
            }
        ]
        lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(signsetup,tsass,clrAll)
        pack $vaDxc4Gui(signsetup,tsass,setAll) $vaDxc4Gui(signsetup,tsass,clrAll) -fill x -padx 3 -pady 8
      pack $frGrid $frBut -side left -padx 3 -fill both -expand 0

		pack  $vaDxc4Gui(signsetup,tsass)	 -fill x -pady 4


  incr vaDxc4Set(prgindic)


	#Bert setup tab creation
	set vaDxc4Set(pattern) qrss
	set vaDxc4Set(errrate) single



  set vaDxc4Set(prgtext)   "Creating Bert Setup..."
  set frame3 [$notebook insert end Bertsetup -text "Bert Setup"]


    set vaDxc4Gui(bertsetup,bertsetup) [TitleFrame $frame3.titf2 -text "Bert setup"]
  		set combofr1  [frame [$vaDxc4Gui(bertsetup,bertsetup) getframe].combofr1]
  		set combofr2  [frame [$vaDxc4Gui(bertsetup,bertsetup) getframe].combofr2]

 			pack $combofr1 -anchor w
 			pack $combofr2 -anchor w

			  set titlcomb3 [TitleFrame $combofr1.titlcomb3 -text "Bert pattern"]
			    set vaDxc4Gui(bertsetup,bertsetup,pattren) [ComboBox [$titlcomb3 getframe].combo3 -justify center \
                   -textvariable RLDxc4::vaDxc4Set(pattern) -width 15 -modifycmd {RLDxc4::SaveChanges bert pattern} \
                   -values {"2047" "2e15" "qrss" "511" } -helptext "This is the Bert pattern"]
				  pack $vaDxc4Gui(bertsetup,bertsetup,pattren) -pady 5

        lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(bertsetup,bertsetup,pattren)
			  set titlberten [TitleFrame $combofr1.titlberten -text "Berts enable"]
				  set bertenfr [frame [$titlberten getframe].bertenfr]
          foreach chkbut {1 2 3 4 5 6 7 8} {
					    set vaDxc4Set(bertenab,bert$chkbut) 1
              set vaDxc4Gui(bertsetup,bertsetup,bertenab,chkbut$chkbut) [checkbutton $bertenfr.chkbut$chkbut -text $chkbut \
                -variable RLDxc4::vaDxc4Set(bertenab,bert$chkbut)  -command {RLDxc4::SaveChanges bert enable}]
    				  pack $vaDxc4Gui(bertsetup,bertsetup,bertenab,chkbut$chkbut)  -side left -fill x
              lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(bertsetup,bertsetup,bertenab,chkbut$chkbut)
					}
		      set frBut [frame [$titlberten getframe].frBut -bd 2 -relief sunken]
		        set vaDxc4Gui(bertsetup,bertenab,setAll) [button $frBut.butSetAll -text "Set ALL" \
		            -command {
		              for {set i 1} {$i<=8} {incr i} {
		                set RLDxc4::vaDxc4Set(bertenab,bert$i) 1
		              }
									RLDxc4::SaveChanges bert enable
		              update
		            }
		        ]
            lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(bertsetup,bertenab,setAll)
		        set vaDxc4Gui(bertsetup,bertenab,clrAll) [button $frBut.butClrAll -text "Clear ALL"\
		            -command {
		              for {set i 1} {$i<=8} {incr i} {
		                set RLDxc4::vaDxc4Set(bertenab,bert$i) 0
		              }
									RLDxc4::SaveChanges bert  enable
		              update
		            }
		        ]
            lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(bertsetup,bertenab,clrAll)
		        pack $vaDxc4Gui(bertsetup,bertenab,setAll) $vaDxc4Gui(bertsetup,bertenab,clrAll) -fill x -side left	 -pady 2 -padx 2
					pack $bertenfr $frBut	 -side left 
				pack $titlcomb3 $titlberten -side left -fill x	-padx 4

			  set titlcomb4 [TitleFrame $combofr2.titlcomb4 -text "Insert error rate"]
			    set vaDxc4Gui(bertsetup,bertsetup,errrate) [ComboBox [$titlcomb4 getframe].combo4 -justify center \
                   -textvariable RLDxc4::vaDxc4Set(errrate) -width 15 -modifycmd {RLDxc4::SaveChanges bert errrate} \
                   -values {none single 2e1 2e2 2e3 2e4 2e5 2e6 2e7 } -helptext "This is the Insert error rate"]
				  pack $vaDxc4Gui(bertsetup,bertsetup,errrate) -pady 5
          lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(bertsetup,bertsetup,errrate)

			  set titlerren [TitleFrame $combofr2.titlerren -text "Insert error enable"]
				  set errenfr [frame [$titlerren getframe].errenfr]
          foreach chkbut {1 2 3 4 5 6 7 8} {
					    set vaDxc4Set(errenab,bert$chkbut) 1
              set vaDxc4Gui(bertsetup,bertsetup,errenab,chkbut$chkbut) [checkbutton $errenfr.chkbut$chkbut -text $chkbut \
                -variable RLDxc4::vaDxc4Set(errenab,bert$chkbut) -command {RLDxc4::SaveChanges bert errenable}]
    				  pack $vaDxc4Gui(bertsetup,bertsetup,errenab,chkbut$chkbut)  -side left -fill x
              lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(bertsetup,bertsetup,errenab,chkbut$chkbut)
					}
		      set frBut [frame [$titlerren getframe].frBut -bd 2 -relief sunken]
		        set vaDxc4Gui(bertsetup,errenab,setAll) [button $frBut.butSetAll -text "Set ALL" \
		            -command {
		              for {set i 1} {$i<=8} {incr i} {
		                set RLDxc4::vaDxc4Set(errenab,bert$i) 1
		              }
									RLDxc4::SaveChanges bert errenable
		              update
		            }
		        ]
            lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(bertsetup,errenab,setAll)
		        set vaDxc4Gui(bertsetup,errenab,clrAll) [button $frBut.butClrAll -text "Clear ALL"\
		            -command {
		              for {set i 1} {$i<=8} {incr i} {
		                set RLDxc4::vaDxc4Set(errenab,bert$i) 0
		              }
									RLDxc4::SaveChanges bert errenable
		              update
		            }
		        ]
            lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(bertsetup,errenab,clrAll)
		        pack $vaDxc4Gui(bertsetup,errenab,setAll) $vaDxc4Gui(bertsetup,errenab,clrAll) -fill x -side left	 -pady 2 -padx 2
					pack $errenfr $frBut	 -side left 
				pack $titlcomb4 $titlerren -side left -fill x	-padx 4


			pack $vaDxc4Gui(bertsetup,bertsetup) -fill x -pady 4

    set vaDxc4Gui(bertsetup,tsass) [TitleFrame $frame3.titf3 -text "Bert TS assignment"]
      set frGrid [frame [$vaDxc4Gui(bertsetup,tsass) getframe].frGrid]
        for {set i 1} {$i<=31} {incr i} {
					if {$vaDxc4Set(linkType) == "E1" || ($vaDxc4Set(linkType)== "T1" && $i<25)} {
				    set vaDxc4Set(berttsass,ts$i) 1
					}
          frame $frGrid.f$i -bd 2 -relief ridge -width 53 -height 53
          grid $frGrid.f$i -row [expr ($i-1)/8] -column [expr ($i-1)%8]
					if {$i < 10} {
					  set text "TS$i  "
					} else {
					  set text "TS$i"
					}
          set vaDxc4Gui(bertsetup,tsass,ts$i) [checkbutton $frGrid.f$i.ch$i -text $text -variable RLDxc4::vaDxc4Set(berttsass,ts$i) \
					                                    -command {RLDxc4::SaveChanges bert tsass}]
          pack $frGrid.f$i.ch$i            
          lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(bertsetup,tsass,ts$i)
        }
      set frBut [frame [$vaDxc4Gui(bertsetup,tsass) getframe].frBut -bd 2 -relief sunken]
        set vaDxc4Gui(bertsetup,tsass,setAll) [button $frBut.butSetAll -text "Set ALL" \
            -command {
              for {set i 1} {$i<=31} {incr i} {
							  if {$i >24 && $RLDxc4::vaDxc4Set(linkType)== "T1"} {
								  break
								}
                set RLDxc4::vaDxc4Set(berttsass,ts$i) 1
              }
							RLDxc4::SaveChanges bert tsass
              update
            }
        ]
        lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(bertsetup,tsass,setAll)
        set vaDxc4Gui(bertsetup,tsass,clrAll) [button $frBut.butClrAll -text "Clear ALL"\
            -command {
              for {set i 1} {$i<=31} {incr i} {
                set RLDxc4::vaDxc4Set(berttsass,ts$i) 0
              }
							RLDxc4::SaveChanges bert tsass
              update
            }
        ]
        lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(bertsetup,tsass,clrAll)
        pack $vaDxc4Gui(bertsetup,tsass,setAll) $vaDxc4Gui(bertsetup,tsass,clrAll) -fill x -padx 3 -pady 8
      pack $frGrid $frBut -side left -padx 3 -fill both -expand 0

		pack  $vaDxc4Gui(bertsetup,tsass)	 -fill x -pady 4


  incr vaDxc4Set(prgindic)


	#General Signaling statistics tab creation
	set vaDxc4Set(stattype) General

  set vaDxc4Set(prgtext)   "Creating Signaling Statistics..."
  set vaDxc4Gui(signstatfr) [$notebook insert end SignStatistics -text "Signaling Statistics"]
	set vaDxc4Set(sign,currstat) signStatis
    set vaDxc4Gui(signstat,tools) [TitleFrame $vaDxc4Gui(signstatfr).titf4 -text "Tools"]

	#	  set titlcomb4 [TitleFrame [$vaDxc4Gui(signstat,tools) getframe].titlcomb4 -text "Statistic type"]
        set labName [label [$vaDxc4Gui(signstat,tools) getframe].labName -text "Statistic Type" -width 12 -anchor nw]
		    set vaDxc4Gui(signstat,tools,stattype) [ComboBox [$vaDxc4Gui(signstat,tools) getframe].combo4    \
                 -textvariable RLDxc4::vaDxc4Set(stattype) -width 15 -modifycmd {RLDxc4::ShowStatistics} \
								 -values {General "TSs error" "TSs value" } \
								 -helptext "This is the Statistic type" ]
			  pack $labName $vaDxc4Gui(signstat,tools,stattype) -side left -anchor n

		  set bbox [ButtonBox [$vaDxc4Gui(signstat,tools) getframe].bbox2 -spacing 0 -padx 1 -pady 1]
		    set vaDxc4Gui(signstat,tools,clear) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/clear] \
		      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 \
		      -helptext "Clear signaling statistics" -command {RLDxc4::ClearSignalingStatistics}]
				pack $vaDxc4Gui(signstat,tools,clear) -anchor n 
			pack $bbox  -side left -anchor n -padx 15
		pack $vaDxc4Gui(signstat,tools) -fill x

    GeneralSignStatistics 
		pack $vaDxc4Gui(signstat,genstat) -fill both

    TSsErrSignStatistics  
    TSsValSignStatistics  


  incr vaDxc4Set(prgindic)
  

	#Berts statistics tab creation
  set vaDxc4Set(prgtext)   "Creating Bert Statistics..."
  set vaDxc4Gui(bertstatfr) [$notebook insert end BertStatistics -text "Bert Statistics"]

    set vaDxc4Gui(bertstat,tools) [TitleFrame $vaDxc4Gui(bertstatfr).titf4 -text "Tools"]

		  set bbox [ButtonBox [$vaDxc4Gui(bertstat,tools) getframe].bbox2 -spacing 0 -padx 1 -pady 1]
		    set vaDxc4Gui(bertstat,tools,bpv) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/bpverror] \
		      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 \
		      -helptext "Inject BPV error" -command {RLDxc4::InjectBPVErrors}]
		    set vaDxc4Gui(bertstat,tools,clear) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/clear] \
		      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 \
		      -helptext "Clear Bert statistics" -command {RLDxc4::ClearBertStatistics}]
		    set vaDxc4Gui(bertstat,tools,inj) [$bbox add -image [Bitmap::get $vaDxc4Set(rundir)/Images/error] \
		      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 \
		      -helptext "Inject error bert" -command {RLDxc4::InjectBertErrors}]
				pack $vaDxc4Gui(bertstat,tools,bpv) $vaDxc4Gui(bertstat,tools,clear) $vaDxc4Gui(bertstat,tools,inj) -side left -padx 10
			pack $bbox -side left
		pack $vaDxc4Gui(bertstat,tools)	 -fill x

    GeneralBertStatistics 
		pack $vaDxc4Gui(bertstat,genstat) -fill both


	#Current configuration tab creation
  set vaDxc4Set(prgtext)   "Creating Chassis configuration..."
  set vaDxc4Gui(currConfigFr) [$notebook insert end CurrentConfig -text "Chassis Configuration"]
    set vaDxc4Gui(currConfigFr,param) [TitleFrame $vaDxc4Gui(currConfigFr).titf1 -text "Current Chassis Configuration Parameters"]
		pack $vaDxc4Gui(currConfigFr,param) -fill both
	    set currParamFr [$vaDxc4Gui(currConfigFr,param) getframe]

			set vaDxc4Gui(currConfig,ports,label) [Entry $currParamFr.lab -width 90 -textvariable RLDxc4::vaDxc4Set(currConfig,ports,label) \
			                                         -relief flat -editable 0 -bg lightgray] 
			 
	    set vaDxc4Set(currConfig,ports,label) "    Parameters      \
	         Port 1        \
			     Port 2        \
		       Port 3        \
		       Port 4         \
		       Port 5         \
		       Port 6        \
		       Port 7        \
		       Port 8"
	
			pack $vaDxc4Gui(currConfig,ports,label)	 -anchor w

        set swcurrParamFr [ScrolledWindow $currParamFr.sw -relief sunken -borderwidth 2]
          set sfcurrParamFr [ScrollableFrame $swcurrParamFr.sf]
          $swcurrParamFr setwidget $sfcurrParamFr
		      $sfcurrParamFr configure -constrainedwidth 1
          set subfrcurrParamFr [$sfcurrParamFr getframe]


       pack $swcurrParamFr -fill both -expand yes

			  foreach param {Frame Interface Mask Sync Balance LineCode IdleCode OOS BertPatt BertErrRate BertTSass \
		                   SignType SignValue SignSpeed SignEnbl SignTSass} {
				  set subsubparamFr [frame $subfrcurrParamFr.fr$param]
					set vaDxc4Gui(currConfig,param,$param) [LabelEntry $subsubparamFr.entry$param -label "" -width 9 -text "$param"  \
					  	 -justify center -editable 0 -entrybg lightgray -relief flat]
					pack $vaDxc4Gui(currConfig,param,$param) -side left -padx 2
					if {$param == "BertTSass" || $param == "SignTSass"} {
						set justif left
					} else {
						  set justif center
					}
					for {set i 1} {$i<=8} {incr i} {
						set vaDxc4Gui(currConfig,param,$param$i) [LabelEntry $subsubparamFr.entry$param$i -width 7  -label "" -justify $justif \
						                     -textvariable RLDxc4::vaDxc4Set(currConfig,param,$param$i) -relief flat -editable 0]
						pack $vaDxc4Gui(currConfig,param,$param$i) -side left -padx 3
					}
					pack $subsubparamFr -pady 2
				}


	#General configuration frame creation
	Dxc4SetLinkType T1

	set vaDxc4Set(ports,list) "1 2 3 4 5 6 7 8 all"
  set vaDxc4Gui(general,gencfg,cfg) [TitleFrame $framenb.titf1 -text "General"]
	  set linktpfr [TitleFrame [$vaDxc4Gui(general,gencfg,cfg) getframe].linktpfr -text "Link type"] 
		  set vaDxc4Gui(general,gencfg,t1) [radiobutton [$linktpfr getframe].rad1 -text "E1" \
                -variable RLDxc4::vaDxc4Set(linkType) -value E1 -command  {RLDxc4::Dxc4SetLinkType E1 ; RLDxc4::SaveChanges port linktype}]
		  set vaDxc4Gui(general,gencfg,e1) [radiobutton [$linktpfr getframe].rad2 -text "T1" \
                -variable RLDxc4::vaDxc4Set(linkType) -value T1 -command  {RLDxc4::Dxc4SetLinkType T1 ; RLDxc4::SaveChanges port linktype}]
			pack $vaDxc4Gui(general,gencfg,t1) $vaDxc4Gui(general,gencfg,e1) -side left 

      lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(general,gencfg,t1) $vaDxc4Gui(general,gencfg,e1)

		set titlname2 [TitleFrame [$vaDxc4Gui(general,gencfg,cfg) getframe].titlname2 -text "Port number"]
		  set vaDxc4Gui(general,gencfg,portnumb) [ComboBox [$titlname2 getframe].combo2 -justify center \
                 -textvariable RLDxc4::vaDxc4Set(port) -width 10  -modifycmd {RLDxc4::SaveChanges port portnumber} \
                 -values $vaDxc4Set(ports,list) \
                 -helptext "This is the Port number"]

			lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(general,gencfg,portnumb)


	  set runtpfr [TitleFrame [$vaDxc4Gui(general,gencfg,cfg) getframe].runtpfr -text "Run enable"] 
		  set vaDxc4Gui(general,gencfg,sign) [radiobutton [$runtpfr getframe].rad1 -text "Sign." \
                -variable RLDxc4::vaDxc4Set(runType) -value 0 -command  ""]
		  set vaDxc4Gui(general,gencfg,bert) [radiobutton [$runtpfr getframe].rad2 -text "Bert" \
                -variable RLDxc4::vaDxc4Set(runType) -value 1 -command  ""]
			pack $vaDxc4Gui(general,gencfg,sign) $vaDxc4Gui(general,gencfg,bert) -side left 

     lappend  vaDxc4Set(lDisabledEntries) $vaDxc4Gui(general,gencfg,sign) $vaDxc4Gui(general,gencfg,bert)

	  set titlip [TitleFrame [$vaDxc4Gui(general,gencfg,cfg) getframe].titlip -text "IP Address"] 
		  set ipaddr [LabelEntry [$titlip getframe].entipaddr -justify center \
		          -textvariable RLDxc4::vaDxc4Set(ipaddress) -width 16 -editable 0]
			pack $ipaddr
	  set titlst [TitleFrame [$vaDxc4Gui(general,gencfg,cfg) getframe].titlst -text "Running state"] 
		  set vaDxc4Gui(runstate) [LabelEntry [$titlst getframe].entrunstate  -justify center\
		                             -textvariable RLDxc4::vaDxc4Set(runstate) -width 14 -editable 0]
			pack $vaDxc4Gui(runstate)


	    pack $vaDxc4Gui(general,gencfg,portnumb) 
	  pack $linktpfr $titlname2 $runtpfr -side left -padx 4
		pack $titlip $titlst -side left	 -padx 4



  set vaDxc4Set(prgtext)   "Done"
  incr vaDxc4Set(prgindic)


  $notebook compute_size
  #pack $pw -fill both  
  #pack $pw $notebook  -fill both -expand yes -padx 4 -pady 4 -side left
  pack $pw $framenb -fill both -padx 4 -pady 4 -side left
  pack $notebook $vaDxc4Gui(general,gencfg,cfg)  -fill both -expand yes -padx 4 -pady 4 
  $notebook raise [$notebook page 4]

#	pack $framenb -side left

	#pack $vaDxc4Gui(general,gencfg,cfg)  -fill x 



  pack $mainframe -fill both -expand 1

  set vaDxc4Set(prgindic) 10
  update idletasks

 # SelectFont::loadfont
 # option add *TitleFrame.l.font {helvetica 11 bold italic}
 # font create MyTabsFont -size 11 -family "helvetica"

  $vaDxc4Gui(resources,list) configure -redraw 1
  $vaDxc4Gui(resources,list) insert end  Resources -text  "Resources" -image [Bitmap::get $vaDxc4Set(rundir)/Images/resources]
  #$vaDxc4Gui(resources,list) insert end  chassis:1 -text  "chassis 1" -fill red -indent 10 -font {times 14}
  #$vaDxc4Gui(resources,list) insert end  chassis:2 -text  "chassis 2" -fill red -indent 10 -font {times 14}
  #$vaDxc4Gui(resources,list) selection set Resources:1
  destroy .intro

  wm deiconify $base
  raise $base
  focus -force $base

}

# .........................................................................
#  Abstract: Connect chassis to host by telnet or com.
#  Inputs: 
#
#  Outputs: 
# ..........................................................................
proc ConnectChassis {} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
	variable address
	variable titlname1
	variable titlname2
	variable frBut
	variable package

  if {[winfo exists .connChassis]} {focus -force .connChassis; return}
  toplevel .connChassis -class Toplevel
  wm focusmodel .connChassis passive
  wm resizable .connChassis 0 0
  wm title .connChassis "Connect chassis"
  wm protocol .connChassis WM_DELETE_WINDOW {destroy .connChassis}
  set b .connChassis 
  
	  set titlname1 [TitleFrame $b.titlname1 -text "Com number"]
	    set vaDxc4Gui(cb,connect,com) [ComboBox [$titlname1 getframe].com  -justify center \
               -textvariable RLDxc4::vaDxc4Set(connect,com) -width 15 -modifycmd {set RLDxc4::address $RLDxc4::vaDxc4Set(connect,com) ; set RLDxc4::package RLSerial}\
               -values {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33} \
               -helptext "This is the Com number"]
		  pack $vaDxc4Gui(cb,connect,com)

	  set titlname2 [TitleFrame $b.titlname2 -text "IP address"]
	    set vaDxc4Gui(cb,connect,telnet) [ComboBox [$titlname2 getframe].telnet  -justify center \
               -textvariable RLDxc4::vaDxc4Set(connect,telnet) -width 15 -modifycmd {set RLDxc4::address $RLDxc4::vaDxc4Set(connect,telnet) ; set RLDxc4::package plink}\
               -values $RLDxc4::vaDxc4Set(listIP) \
               -helptext "This is the IP address"]
		   pack $vaDxc4Gui(cb,connect,telnet)

    set frBut [frame $b.frBut]

    set frConntype [TitleFrame $b.frConntype -text "Connect by..."]
	    set comrb [radiobutton [$frConntype getframe].rad1 -text "Com" -value 1 -variable RLDxc4::vaDxc4Set(connectBy)\
              -command  {set RLDxc4::address $RLDxc4::vaDxc4Set(connect,com)
  											 set RLDxc4::package RLSerial
							           catch {pack forget $RLDxc4::titlname1 $RLDxc4::titlname2 $RLDxc4::frBut}
						             pack $RLDxc4::titlname1 $RLDxc4::frBut}]
	    set telrb [radiobutton [$frConntype getframe].rad2 -text "Telnet" -value 0 -variable RLDxc4::vaDxc4Set(connectBy)\
              -command  {set RLDxc4::address $RLDxc4::vaDxc4Set(connect,telnet)
 												 set RLDxc4::package plink
							           catch {pack forget $RLDxc4::titlname1 $RLDxc4::titlname2 $RLDxc4::frBut} 
											   pack $RLDxc4::titlname2 $RLDxc4::frBut}]
		  pack $comrb $telrb -side left 
		
	  pack $frConntype
		if {![info exists RLDxc4::package]} {
	   pack $titlname1
	  } elseif {$RLDxc4::package == "plink"} {
    	  pack $titlname2
		} else {
  	    pack $titlname1
		}

      set vaDxc4Gui(connect,telnet) [button $frBut.butOk -text Ok -width 9 -command {
      									if {[info exists RLDxc4::package] && $RLDxc4::package == "plink"} {
													set RLDxc4::address $RLDxc4::vaDxc4Set(connect,telnet)
												}
												if {![info exists RLDxc4::address] || ![info exists RLDxc4::package] || $RLDxc4::address == "" || $RLDxc4::package == ""} {
													set gMessage  "Please select all entries"
													tk_messageBox -icon error -type ok -message "$gMessage" -title "E1/T1 Generator"
											    return    
												}
			                  RLDxc4::OkConnChassis $RLDxc4::address $RLDxc4::package}]
      pack $vaDxc4Gui(connect,telnet) 

    pack $frBut -padx 3 -pady 3 -fill both
		$vaDxc4Gui(cb,connect,telnet) configure -command {$RLDxc4::vaDxc4Gui(connect,telnet) invoke} -takefocus 1
  focus -force $b


}	

# ................................................................................
#  Abstract: Dxc4show_progdlg
#  Inputs: 
#
#  Outputs: 
# ................................................................................

proc Dxc4show_progdlg { } {
    variable progmsg
		variable progval
    set progmsg "Compute in progress..."
    set progval 0

    ProgressDlg .progress -parent .topDxc4Gui -title "Wait..." \
        -type         infinite \
        -width        20 \
        -textvariable RLDxc4::progmsg \
        -variable     RLDxc4::progval \
        -stop         "Stop" \
        -command      {destroy .progress}

				RLDxc4::Dxc4show_update_progdlg
}

proc Dxc4show_update_progdlg {} {
    variable progmsg
		variable progval

    if { [winfo exists .progress] } {
        set progval 2
        after 25	RLDxc4::Dxc4show_update_progdlg
    }
}



# ................................................................................
#  Abstract: 
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc OkConnChassis {address package {id 0}} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

	set resources ""
  set reslist  [lrange [$vaDxc4Gui(resources,list) items] 1 end]
	if {$reslist != ""} {
		foreach chassis $reslist {
	  	set ch [lindex [split $chassis :] 1]
    	lappend resources $vaDxcStatuses($ch,address) $vaDxcStatuses($ch,package)
		}
	}
	if {$resources != ""} {
		if {[lsearch $resources $address] != -1} {
			set gMessage  "There is yet given address: $address into resources"
			tk_messageBox -icon error -type ok -message "$gMessage" -title "E1/T1 Generator"
	    return    
		}
	}

	if {[info exists vaDxc4Gui(connect,telnet)]} {
	  catch {$vaDxc4Gui(connect,telnet) configure -state disable -relief sunken}
	}
	RLDxc4::Dxc4show_progdlg
	#the id doesn't compare to nul when this procedure invoked from ShowGui proc.
	if {!$id} {
	  catch {RLDxc4::Open $address -package $package} id
		if {$id < 0 || [catch {expr int($id)}]} {
		  destroy .progress
  	  if {[info exists vaDxc4Gui(connect,telnet)]} {
	   	  $vaDxc4Gui(connect,telnet) configure -state normal -relief raised
			}
			append gMessage  "\nFail while (RLDxc4::Open $address -package $package) procedure"
			tk_messageBox -icon error -type ok -message "$gMessage" -title "E1/T1 Generator"
	    return    
		}
	}
	set vaDxc4Set(currentid) $id

	if {[RLDxc4::GetConfig $id  aResCfg]} {
	  destroy .progress
		tk_messageBox -icon error -type ok -message "Error while (RLDxc4::GetConfig $id) procedure \n$gMessage" -title "E1/T1 Generator"
		RLDxc4::Close $id
    return    
	}
	array set vaDxc4Cfg [array get aResCfg]

	#if {[RLDxc4::GetStatistics $id  aResSignStat -statistic signStatis]} {
	#  destroy .progress
	#	tk_messageBox -icon error -type ok -message $gMessage -title "E1/T1 Generator"
  #  return    
	#}

	#array set vaDxc4Cfg [array get aResSignStat]

	#if {[RLDxc4::GetStatistics $id  aResBertStat -statistic bertStatis]} {
	#  destroy .progress
	#	tk_messageBox -icon error -type ok -message $gMessage -title "E1/T1 Generator"
  #  return    
	#}

	#array set vaDxc4Cfg [array get aResBertStat]

	#parray	vaDxc4Cfg
	#parray	vaDxcStatuses
	if {[info exists vaDxc4Gui(connect,telnet)]} {
   	catch {$vaDxc4Gui(connect,telnet) configure -state normal -relief raised}
	}
  $vaDxc4Gui(resources,list) insert end  chassis:$id -text  "chassis $id" -fill darkgreen -indent 10 -font {times 14}
  $vaDxc4Gui(resources,list) selection set chassis:$id
	set vaDxc4Set(currentchass) chassis:$id
	if {[winfo exists .topDxc4Gui]} {
	  FillCurrentGuiEntries $id 
	}

	if {[lsearch $vaDxc4Set(listIP) $vaDxc4Set(connect,telnet)] == -1} {
	  lappend vaDxc4Set(listIP)	  $vaDxc4Set(connect,telnet)
	}
	destroy .progress
  catch {destroy .connChassis}

  if {$vaDxc4Cfg(id$id,SigRun) == "Run"} {
	  RunCurrentChassis 0 $id
	} 
  if {$vaDxc4Cfg(id$id,BertRun) == "Run"} {
	  RunCurrentChassis 1 $id noclear
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
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

#	parray vaDxc4Cfg

	#Port setup and General setup
	set vaDxc4Set(linkType)                  $vaDxc4Cfg(id$ip_ID,linkType)
	set vaDxc4Set(clocksrc)                  $vaDxc4Cfg(id$ip_ID,SrcClock)
	set vaDxc4Set(port)		                   $vaDxc4Cfg(id$ip_ID,updPort)
	if {$vaDxc4Cfg(id$ip_ID,updPort) == "all"} {
		 set port 1
	} else {
 		  set port $vaDxc4Set(port)
	}
	set vaDxc4Set(linktype,t1,frame)				 $vaDxc4Cfg(id$ip_ID,FrameT1,Port$port)
	set vaDxc4Set(linktype,t1,intftp)				 $vaDxc4Cfg(id$ip_ID,IntfT1,Port$port)	
	set vaDxc4Set(linktype,t1,mask)					 $vaDxc4Cfg(id$ip_ID,MaskT1,Port$port)
	set vaDxc4Set(linktype,t1,sync)					 $vaDxc4Cfg(id$ip_ID,SyncT1,Port$port)
	set vaDxc4Set(linktype,t1,linecod)			 $vaDxc4Cfg(id$ip_ID,CodeT1,Port$port)
	set vaDxc4Set(linktype,t1,idlecod)			 $vaDxc4Cfg(id$ip_ID,IdleT1,Port$port)
	set vaDxc4Set(linktype,t1,oos)					 $vaDxc4Cfg(id$ip_ID,OosT1,Port$port)
	
  if {$vaDxc4Set(linktype,t1,intftp) == "dsu"} {
  	set vaDxc4Set(maskList) "0-133 134-266 267-399 400-533 534-655 fcc-68a"
	} else {
    	set vaDxc4Set(maskList) "0 7.5 15 22.5"
	}
	$vaDxc4Gui(portsetup,linktype,t1,mask) configure -values $vaDxc4Set(maskList)

	set vaDxc4Set(linktype,e1,frame)				 $vaDxc4Cfg(id$ip_ID,FrameE1,Port$port)
	set vaDxc4Set(linktype,e1,intftp)				 $vaDxc4Cfg(id$ip_ID,IntfE1,Port$port)	
	set vaDxc4Set(linktype,e1,bal)					 $vaDxc4Cfg(id$ip_ID,BalancE1,Port$port)
	set vaDxc4Set(linktype,e1,resttime)			 $vaDxc4Cfg(id$ip_ID,RstTimE1,Port$port)
	set vaDxc4Set(linktype,e1,linecod)			 $vaDxc4Cfg(id$ip_ID,CodeE1,Port$port)
	set vaDxc4Set(linktype,e1,idlecod)			 $vaDxc4Cfg(id$ip_ID,IdleE1,Port$port)
	set vaDxc4Set(linktype,e1,oos)					 $vaDxc4Cfg(id$ip_ID,OosE1,Port$port)

	set vaDxc4Set(diagnostic,diagport)			 $vaDxc4Cfg(id$ip_ID,DiagPort)
	set vaDxc4Set(diagnostic,loopport)			 $vaDxc4Cfg(id$ip_ID,PortLpSt,Port$vaDxc4Set(diagnostic,diagport))
	set vaDxc4Set(diagnostic,txallones)			 $vaDxc4Cfg(id$ip_ID,AllOneTx,Port$vaDxc4Set(diagnostic,diagport))
	set vaDxc4Set(diagnostic,rxallones)			 $vaDxc4Cfg(id$ip_ID,AllOneRx)

	for {set i 1} {$i <= 8} {incr i} {
	  catch {set vaDxc4Set(diagnostic,port$i,loop) $vaDxc4Cfg(id$ip_ID,PortLpSt,Port$i)}
	  catch {set vaDxc4Set(diagnostic,port$i,txallonesstate) $vaDxc4Cfg(id$ip_ID,AllOneTx,Port$i)}
		if {$vaDxcStatuses($ip_ID,numbPorts) == 4 && $i > 4} {
		  catch {pack forget $vaDxc4Gui(portsetup,diagnostic,port$i)}
		  catch {pack forget $vaDxc4Gui(portsetup,diagnostic,loop$i)}
		  catch {pack forget $vaDxc4Gui(portsetup,diagnostic,txallonesstate$i)}
			
		} elseif {$vaDxcStatuses($ip_ID,numbPorts) == 8 && $i > 4} {
		    catch {pack $vaDxc4Gui(portsetup,diagnostic,port$i) -side left -fill x -padx 2}
		    catch {pack $vaDxc4Gui(portsetup,diagnostic,loop$i) -side left -fill x -padx 2}
		    catch {pack $vaDxc4Gui(portsetup,diagnostic,txallonesstate$i) -side left -fill x -padx 2}
		}
	}


	set vaDxc4Set(ipaddress)								 $vaDxc4Cfg(id$ip_ID,IpForEth)
	if {$vaDxc4Cfg(id$ip_ID,SigRun) == "Run"} {
	  set vaDxc4Set(runstate) "Signaling run..."
		set vaDxc4Set(runType) 0
		$vaDxc4Gui(tb,run) configure -state disable 
		$vaDxc4Gui(tb,stop) configure -state normal 
		$vaDxc4Gui(runstate) configure -entryfg darkgreen
	} elseif {$vaDxc4Cfg(id$ip_ID,BertRun) == "Run" } {
  	  set vaDxc4Set(runstate) "Bert run..."
  		set vaDxc4Set(runType) 1
			$vaDxc4Gui(tb,run) configure -state disable 
			$vaDxc4Gui(tb,stop) configure -state normal 
  		$vaDxc4Gui(runstate) configure -entryfg darkgreen
	} else {
  	  set vaDxc4Set(runstate) "Stop"
			$vaDxc4Gui(tb,run) configure -state normal 
			$vaDxc4Gui(tb,stop) configure -state disable 
  		$vaDxc4Gui(runstate) configure -entryfg red
	}

	#RLDxc4::Dxc4SetLinkType $vaDxc4Set(linkType)

	#Signaling setup
	set vaDxc4Set(signtype) $vaDxc4Cfg(id$ip_ID,SigType,Port$port)
	set vaDxc4Set(signval)  $vaDxc4Cfg(id$ip_ID,SigValue,Port$port)
	set vaDxc4Set(incrspeed) $vaDxc4Cfg(id$ip_ID,IncSpeed,Port$port)
	set vaDxc4Set(timeres)	 $vaDxc4Cfg(id$ip_ID,TimeRes)
	set vaDxc4Set(signenab,port) [lsearch $vaDxcStatuses(lSigEnbl) $vaDxc4Cfg(id$ip_ID,SigEnbl,Port$port)]

	foreach group  {SigTsAs0 SigTsAs1 SigTsAs2 SigTsAs3}	 {
		append varsign \\x$vaDxc4Cfg(id$ip_ID,$group,Port$port)
	}

  eval binary scan $varsign  B* tss
  for {set i 1} {$i <= 31} {incr i} {
	  set vaDxc4Set(signass,ts$i) [string index $tss [expr $i - 1]]
  }
	#puts $tss

	#Bert setup
	set vaDxc4Set(pattern) $vaDxc4Cfg(id$ip_ID,BertPatt,Port$port)
	for {set i 1} {$i <= 8} {incr i} {
	  catch {set vaDxc4Set(bertenab,bert$i) [lsearch $vaDxcStatuses(lBertEnbl) $vaDxc4Cfg(id$ip_ID,BertEnbl,Port$i)]}
		if {$vaDxcStatuses($ip_ID,numbPorts) == 4 && $i > 4} {
		  catch {pack forget $vaDxc4Gui(bertsetup,bertsetup,bertenab,chkbut$i)}
		  catch {pack forget $vaDxc4Gui(bertsetup,bertsetup,errenab,chkbut$i)}
			
		} elseif {$vaDxcStatuses($ip_ID,numbPorts) == 8 && $i > 4} {
		    catch {pack $vaDxc4Gui(bertsetup,bertsetup,bertenab,chkbut$i) -side left -fill x}
		    catch {pack $vaDxc4Gui(bertsetup,bertsetup,errenab,chkbut$i) -side left -fill x}
		}
	}
  set vaDxc4Set(errrate) $vaDxc4Cfg(id$ip_ID,InsErrRt,Port$port)

	for {set i 1} {$i <= $vaDxcStatuses($ip_ID,numbPorts)} {incr i} {
	  set vaDxc4Set(errenab,bert$i) [lsearch $vaDxcStatuses(lInsErrEn) $vaDxc4Cfg(id$ip_ID,InsErrEn,Port$i)]

	}

	foreach group  {BerTsAs0 BerTsAs1 BerTsAs2 BerTsAs3}	 {
		append varbert \\x$vaDxc4Cfg(id$ip_ID,$group,Port$port)
	}

  eval binary scan $varbert  B* tss
  for {set i 1} {$i <= 31} {incr i} {
	  set vaDxc4Set(berttsass,ts$i) [string index $tss [expr $i - 1]]
  }

	if {$vaDxc4Set(linktype,[string tolower $vaDxc4Set(linkType)],frame) == "unframe"} {
	  catch {pack forget $vaDxc4Gui(bertsetup,tsass)}
	} elseif {$vaDxc4Set(linktype,[string tolower $vaDxc4Set(linkType)],frame) != "unframe"} {
  	  catch {pack $vaDxc4Gui(bertsetup,tsass)}
	}

	#General statistics signaling
	for {set i 1} {$i <= 8} {incr i} {
	  catch {set vaDxc4Set(genstat,entrysent$i)	$vaDxc4Cfg(id$ip_ID,sentSign,Port$i)}
	  catch {set vaDxc4Set(genstat,entryrec$i)	$vaDxc4Cfg(id$ip_ID,receivedSign,Port$i)}
	  catch {set vaDxc4Set(genstat,entryerr$i)	$vaDxc4Cfg(id$ip_ID,errorSign,Port$i)}
  	catch {pack forget $vaDxc4Gui(signstat,genstat,entriesfr$i)}
		if {$vaDxc4Cfg(id$ip_ID,updPort) == "all"} {
	    if {$i <= $vaDxcStatuses($ip_ID,numbPorts) && $vaDxc4Cfg(id$ip_ID,SigEnbl,Port$i) == "enbl"} {
	      pack $vaDxc4Gui(signstat,genstat,entriesfr$i) -anchor w
	    }
		}
	}
	if {$vaDxc4Cfg(id$ip_ID,updPort) != "all"} {
     pack $vaDxc4Gui(signstat,genstat,entriesfr$port) -anchor w
  }


	#General statistics bert
	for {set i 1} {$i <= 8} {incr i} {
	  catch {set vaDxc4Set(genstat,entryrun$i)	$vaDxc4Cfg(id$ip_ID,runTime,Port$i)}
	  catch {set vaDxc4Set(genstat,entryloss$i)	$vaDxc4Cfg(id$ip_ID,syncLoss,Port$i)}
	  catch {set vaDxc4Set(genstat,entrysec$i)	$vaDxc4Cfg(id$ip_ID,errorSec,Port$i)}
	  catch {set vaDxc4Set(genstat,entrybits$i)	$vaDxc4Cfg(id$ip_ID,errorBits,Port$i)}
  	catch {pack forget $vaDxc4Gui(bertstat,genstat,entriesfr$i)}
		if {$vaDxc4Cfg(id$ip_ID,updPort) == "all"} {
		  if {$i <= $vaDxcStatuses($ip_ID,numbPorts) && $vaDxc4Cfg(id$ip_ID,BertEnbl,Port$i) == "enbl"} {
		    pack $vaDxc4Gui(bertstat,genstat,entriesfr$i) -anchor w
		  }
		}
	}
	if {$vaDxc4Cfg(id$ip_ID,updPort) != "all"} {
     pack $vaDxc4Gui(bertstat,genstat,entriesfr$port) -anchor w
  }

	#Current parametres
	for {set i 1} {$i <= 8} {incr i} {
		foreach paramgui {Frame Interface LineCode IdleCode OOS} paramcur {Frame Intf Code	Idle Oos} {
  	  catch {set vaDxc4Set(currConfig,param,$paramgui$i)	$vaDxc4Cfg(id$ip_ID,$paramcur$vaDxc4Set(linkType),Port$i)}
		}
		if {$vaDxc4Set(linkType) == "E1"} {
  	  catch {set vaDxc4Set(currConfig,param,Balance$i)	$vaDxc4Cfg(id$ip_ID,BalancE1,Port$i)}
  	  catch {set vaDxc4Set(currConfig,param,Sync$i)	$vaDxc4Cfg(id$ip_ID,RstTimE1,Port$i)}
  	  catch {set vaDxc4Set(currConfig,param,Mask$i)	""}
		} else {
    	  catch {set vaDxc4Set(currConfig,param,Sync$i)	$vaDxc4Cfg(id$ip_ID,SyncT1,Port$i)}
    	  catch {set vaDxc4Set(currConfig,param,Mask$i)	$vaDxc4Cfg(id$ip_ID,MaskT1,Port$i)}
    	  catch {set vaDxc4Set(currConfig,param,Balance$i)	""}
		}



		foreach paramgui {SignType SignValue SignSpeed SignEnbl} \
						paramcur {SigType SigValue IncSpeed SigEnbl} {
  	  catch {set vaDxc4Set(currConfig,param,$paramgui$i)	$vaDxc4Cfg(id$ip_ID,$paramcur,Port$i)}
		}
		set signasm ""
		foreach signbyte  {SigTsAs0 SigTsAs1 SigTsAs2 SigTsAs3}	 {
		  if {[info exists vaDxc4Cfg(id$ip_ID,$signbyte,Port$i)]} {
			  if {[string length $vaDxc4Cfg(id$ip_ID,$signbyte,Port$i)] < 2} {
					set vaDxc4Cfg(id$ip_ID,$signbyte,Port$i) 0$vaDxc4Cfg(id$ip_ID,$signbyte,Port$i)
				}
			  append signasm [string tolower $vaDxc4Cfg(id$ip_ID,$signbyte,Port$i)]

			}
		}
  	catch {set vaDxc4Set(currConfig,param,SignTSass$i) $signasm}

		foreach paramgui {BertPatt BertErrRate}	paramcur {BertPatt InsErrRt} {
  	  catch {set vaDxc4Set(currConfig,param,$paramgui$i)	$vaDxc4Cfg(id$ip_ID,$paramcur,Port$i)}
		}
		#Display bert ts assignment include unframe 
		set bertasm ""
		foreach bertbyte  {BerTsAs0 BerTsAs1 BerTsAs2 BerTsAs3}	 {
		  if {[info exists vaDxc4Cfg(id$ip_ID,$bertbyte,Port$i)]} {
			  if {[string length $vaDxc4Cfg(id$ip_ID,$bertbyte,Port$i)]< 2} {
					set vaDxc4Cfg(id$ip_ID,$bertbyte,Port$i) 0$vaDxc4Cfg(id$ip_ID,$bertbyte,Port$i)
				}
			  append bertasm [string tolower $vaDxc4Cfg(id$ip_ID,$bertbyte,Port$i)]

			}
		}
		if {$bertasm == "ffffffff" && $vaDxc4Set(linkType) == "E1"} {
		  set bertasm "unframe"
		}
		if {$bertasm == "ffffff01" && $vaDxc4Set(linkType) == "T1"} {
		  set bertasm "unframe"
		}
  	catch {set vaDxc4Set(currConfig,param,BertTSass$i) $bertasm}
	}


  ConvertTssOrBertsAssToString	signass

  if {$vaDxcStatuses($ip_ID,numbPorts) == 4} {
	  set vaDxc4Set(ports,list) "1 2 3 4 all"
	} else {
	    set vaDxc4Set(ports,list) "1 2 3 4 5 6 7 8 all"
	}
	$vaDxc4Gui(general,gencfg,portnumb) configure -values $vaDxc4Set(ports,list)
	if {!([info exists vaDxc4Set(id$ip_ID,start)] && $vaDxc4Set(id$ip_ID,start))} {
	  DisableEnableEntries normal
	}
	RLDxc4::Dxc4SetLinkType $vaDxc4Set(linkType)
	$vaDxc4Gui(tb,save) configure -state disable
	update

}

# ................................................................................
#  Abstract: Selects Dxc4 resource into Dxc4 GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc SelectDxcResource {node} {
  global gMessage
	variable vaDxcStatuses
  variable vaDxc4Gui
  variable vaDxc4Set
	variable vaDxc4Cfg

	if {$node == "Resources"} {
    $vaDxc4Gui(resources,list) selection set $node
  	set vaDxc4Set(currentchass) $node
		set vaDxc4Set(currentid) ""
	  return
	}
	RLDxc4::Dxc4show_progdlg
	#puts $node
	$vaDxc4Gui(resources,list) configure -state disabled
	set id [lindex [split $node :] 1]
	#if the selected node is in runing state I use the FillCurrentGuiEntries without get from chassis configuration.
	if {[info exists vaDxc4Set(id$id,start)] && $vaDxc4Set(id$id,start)} {
    $vaDxc4Gui(resources,list) selection set $node
  	set vaDxc4Set(currentid) $id
  	set vaDxc4Set(currentchass) $node
	  if {[winfo exists .topDxc4Gui]} {
  	  FillCurrentGuiEntries $id 
      DisableEnableEntries	disabled
		}
	  destroy .progress
  	$vaDxc4Gui(resources,list) configure -state normal
		return
	}

	if {[RLDxc4::ChkConnect $id]} {
	  $vaDxc4Gui(resources,list) itemconfigure $node -fill red
    $vaDxc4Gui(resources,list) selection set $node
  	set vaDxc4Set(currentchass) $node
	  destroy .progress
		tk_messageBox -icon error -type ok -message "Error while (RLDxc4::ChkConnect $id) procedure \n$gMessage" -title "E1/T1 Generator"
  	$vaDxc4Gui(resources,list) configure -state normal
    return    
	}
	#puts $node
	#if the selected node is the curent it isn't need to get from chassis configuration because it exist into array vaDxc4Cfg.
	if {$id == "$vaDxc4Set(currentid)"} {
	  $vaDxc4Gui(resources,list) itemconfigure $node -fill darkgreen
    $vaDxc4Gui(resources,list) selection set $node
  	set vaDxc4Set(currentchass) $node
  	$vaDxc4Gui(resources,list) configure -state normal
	  destroy .progress
	  return
	}

	#puts $node
	set vaDxc4Set(currentchass) chassis:$id
	set vaDxc4Set(currentid) $id
	#if the selected node isn't the curent and its info doesn't exist into array vaDxc4Cfg  it is need to get from chassis it configuration.
	if {![info exists vaDxc4Cfg(id$id,linkType)] || $vaDxcStatuses($id,currScreen) == "na"} {
		if {[RLDxc4::GetConfig $id  aCfgRes]} {
  	  $vaDxc4Gui(resources,list) itemconfigure $node -fill red
  	  destroy .progress
			tk_messageBox -icon error -type ok -message "Error while (RLDxc4::GetConfig $id) procedure \n$gMessage" -title "E1/T1 Generator"
	    return    
		}
		array set vaDxc4Cfg [array get aCfgRes]
	}
	if {[winfo exists .topDxc4Gui]} {
  	FillCurrentGuiEntries $id 
	  FillCollorBertGenerator $vaDxc4Set(runType)
	}
  $vaDxc4Gui(resources,list) itemconfigure $node -fill darkgreen
  $vaDxc4Gui(resources,list) selection set $node
	$vaDxc4Gui(resources,list) configure -state normal
  destroy .progress
	#puts $node
}

# ................................................................................
#  Abstract: Sets link type into Dxc4 GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc DelDxcResource {} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
	variable vaDxc4Cfg

	if {![info exists vaDxc4Set(currentchass)] || $vaDxc4Set(currentchass) == "Resources"} {
	  return
	}

  if {$vaDxc4Set(runstate) != "Stop"} {
		tk_messageBox -icon error -type ok -message "The chassis is running stop it before remove it" -title "E1/T1 Generator"
    return    
	}
	set id [lindex [split $vaDxc4Set(currentchass) :] 1]
	if {[RLDxc4::Close $id]} {
		tk_messageBox -icon error -type ok -message "Error while (RLDxc4::Close $id) procedure \n$gMessage" -title "E1/T1 Generator"
    return    
	}
 	$vaDxc4Gui(resources,list) delete $vaDxc4Set(currentchass)
	$vaDxc4Gui(resources,list) selection set Resources
	set vaDxc4Set(currentchass) Resources
	set vaDxc4Set(currentid)	Resources

  set names [array names vaDxc4Cfg id$id*]
  foreach name $names {
	  unset vaDxc4Cfg($name)
  }
}

# ................................................................................
#  Abstract: Sets link type into Dxc4 GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc Dxc4SetLinkType {val} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set

	#RLDxc4::SaveChanges port linktype 
	catch {pack forget $vaDxc4Gui(portsetup,linktype,e1)}
	catch {pack forget $vaDxc4Gui(portsetup,linktype,t1)}
	if {$val == "T1"} {
		pack $vaDxc4Gui(portsetup,linktype,t1)	 -fill x -pady 4
		set state disable
	} else {
		 pack $vaDxc4Gui(portsetup,linktype,e1) -fill x -pady 4
		 set state normal
	}
	for {set i 25} {$i <= 31} {incr i} {
		$vaDxc4Gui(signsetup,tsass,ts$i) configure -state $state
		$vaDxc4Gui(bertsetup,tsass,ts$i) configure -state $state
  	if {$val == "T1"} {
    	catch {pack forget $vaDxc4Gui(signstat,tserrstat,ts$i)}
    	catch {pack forget $vaDxc4Gui(signstat,tsvalstat,ts$i)}
			
		} else {
        pack $vaDxc4Gui(signstat,tserrstat,ts$i)	  -fill x -pady 3
        pack $vaDxc4Gui(signstat,tsvalstat,ts$i)	  -fill x -pady 3
		}

	}
	if {$vaDxc4Set(linktype,[string tolower $vaDxc4Set(linkType)],frame) == "unframe"} {
	  catch {pack forget $vaDxc4Gui(bertsetup,tsass)}
	} elseif {$vaDxc4Set(linktype,[string tolower $vaDxc4Set(linkType)],frame) != "unframe"} {
  	  catch {pack $vaDxc4Gui(bertsetup,tsass)}
	}

}
 
# ....................................................................................
#  Abstract: Create General signaling statistics into Dxc4 GUI.
#  Inputs: 
#
#  Outputs: 
# ....................................................................................
proc ShowStatistics {} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
	variable vaDxc4Cfg
		
	catch {pack forget $vaDxc4Gui(signstat,genstat)}
	catch {pack forget $vaDxc4Gui(signstat,tserrstat)} 
	catch {pack forget $vaDxc4Gui(signstat,tsvalstat)} 

	if {$vaDxc4Set(stattype) == "General"} {
	  pack $vaDxc4Gui(signstat,genstat)	 -fill both
		set vaDxc4Set(sign,currstat) signStatis
		return

	} elseif {$vaDxc4Set(stattype) == "TSs error"} {
		 pack $vaDxc4Gui(signstat,tserrstat) -fill both
     set vaDxc4Set(sign,currstat) signTsError
		 #array set vaDxc4Cfg [array get aTserr]
		 #set statis error

	} elseif {$vaDxc4Set(stattype) == "TSs value"} {
		 pack $vaDxc4Gui(signstat,tsvalstat) -fill both
     set vaDxc4Set(sign,currstat) signValue
		 #if {[catch {expr int($vaDxc4Set(currentid))}]} {
		 #  tk_messageBox -icon error -type ok -message "Select chassis for statistics" -title "E1/T1 Generator"
		 #	 return
		 #}
		 #RLDxc4::Dxc4show_progdlg
		 #if {[RLDxc4::GetStatistics $vaDxc4Set(currentid)  aTsval -statistic signValue]} {
		 #  destroy .progress
		 #  tk_messageBox -icon error -type ok -message $gMessage -title "E1/T1 Generator"
	   #  return    
		 #}
		 #array set vaDxc4Cfg [array get aTsval]
		 #set statis value

	} else {

	}
	#FillSignalingStatistics	 $vaDxc4Set(currentid) $statis
	#catch {destroy .progress}
}

# ................................................................................
#  Abstract: FillSignalingStatistics
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc FillSignalingStatistics {ip_ID statis} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

	if {$vaDxc4Set(currentid) == "" || $vaDxc4Set(currentid) != $ip_ID} {
	  return
	}

	if {$vaDxc4Cfg(id$ip_ID,updPort) == "all"} {
		 set port 1
	} else {
 		  set port $vaDxc4Set(port)
	}


	set rev1 "_" ; set rev2 "__"; set rev3 "___"; set rev4 "____"; set rev5 "_____"; set rev6 "______"; set rev7 "_______"
	set rev8 "________"; set rev9 "_________"; set rev10 "__________"; set rev11 "___________"; set rev12 "____________"
	set rev13 "_____________"; set rev14 "______________"; set rev15 "_______________"; set rev16 "________________"
	set rev17 "_________________"; set rev18 "__________________"; set rev19 "___________________"; set rev20 "____________________"

	set vaDxc4Set(tserrstat,label) "TSs     "
	set vaDxc4Set(tsvalstat,label) "TSs     "
	for {set i 1 } {$i<= $vaDxcStatuses($ip_ID,numbPorts)} {incr i} {
	  #display only enabled ports
		if {$vaDxc4Cfg(id$ip_ID,SigEnbl,Port$i) == "enbl"} {
			 append vaDxc4Set(tserrstat,label) "Port $i          "
			 append vaDxc4Set(tsvalstat,label) "Port $i          "
		}
	}

  for {set i 1} {$i <= 31} {incr i} {
	  if {$i == 16 && $vaDxc4Set(linkType) == "E1"} {
		  continue
		}

    switch -exact -- $statis  {

		  error {
			  set n 0
			  set vaDxc4Set(tserrstat,ts$i) "  $i"
				for {set j 1} {$j <= $vaDxcStatuses($ip_ID,numbPorts)} {incr j} {
      		if {$vaDxc4Cfg(id$ip_ID,SigEnbl,Port$j) == "enbl"} {
    			  catch {append vaDxc4Set(tserrstat,ts$i) "[set rev[expr $n*10 + 9 - [string length $vaDxc4Set(tserrstat,ts$i)]]] $vaDxc4Cfg(id$ip_ID,Port$j,errors,TS$i)"}
						incr n
					}

				}
			}

			value {
			  set n 0
			  set vaDxc4Set(tsvalstat,ts$i) "  $i"
				for {set j 1} {$j <= $vaDxcStatuses($ip_ID,numbPorts)} {incr j} {
      		if {$vaDxc4Cfg(id$ip_ID,SigEnbl,Port$j) == "enbl"} {
    			  catch {append vaDxc4Set(tsvalstat,ts$i) "[set rev[expr $n*10 + 9 - [string length $vaDxc4Set(tsvalstat,ts$i)]]] $vaDxc4Cfg(id$ip_ID,Port$j,signValue,TS$i)"}
						incr n
					}

				}
			}
		}
	}

}


# ................................................................................
#  Abstract: FillGeneralStatistics
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc FillGeneralStatistics {ip_ID} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

	if {$vaDxc4Set(currentid) == "" || $vaDxc4Set(currentid) != $ip_ID} {
	  return
	}
	for {set i 1} {$i <= $vaDxcStatuses($ip_ID,numbPorts)} {incr i} {
		if {$vaDxc4Cfg(id$ip_ID,SigEnbl,Port$i) == "enbl" && $vaDxc4Cfg(id$ip_ID,SigRun) == "Run"} {
		  catch {set vaDxc4Set(genstat,entrysent$i) $vaDxc4Cfg(id$ip_ID,sentSign,Port$i)}
		  catch {set vaDxc4Set(genstat,entryrec$i) $vaDxc4Cfg(id$ip_ID,receivedSign,Port$i)}
		  catch {set vaDxc4Set(genstat,entryerr$i) $vaDxc4Cfg(id$ip_ID,errorSign,Port$i)}
		}
		if {$vaDxc4Cfg(id$ip_ID,BertEnbl,Port$i) == "enbl" && $vaDxc4Cfg(id$ip_ID,BertRun) == "Run"} {
		  catch {set vaDxc4Set(genstat,entryrun$i) $vaDxc4Cfg(id$ip_ID,runTime,Port$i)}
		  catch {set vaDxc4Set(genstat,entryloss$i) $vaDxc4Cfg(id$ip_ID,syncLoss,Port$i)}
		  catch {set vaDxc4Set(genstat,entrysec$i) $vaDxc4Cfg(id$ip_ID,errorSec,Port$i)}
		  catch {set vaDxc4Set(genstat,entrybits$i) $vaDxc4Cfg(id$ip_ID,errorBits,Port$i)}
			if {($vaDxc4Cfg(id$ip_ID,syncLoss,Port$i) != 0 || $vaDxc4Cfg(id$ip_ID,errorSec,Port$i) != 0) && $vaDxc4Cfg(id$ip_ID,errorBits,Port$i) == 0} {
			  set vaDxc4Set(genstat,entryber$i) ""
			} else {
  		    catch {set vaDxc4Set(genstat,entryber$i) [format "%.1E" [expr (double($vaDxc4Cfg(id$ip_ID,errorBits,Port$i))/$vaDxc4Cfg(id$ip_ID,runTime,Port$i))/$vaDxc4Cfg(id$ip_ID,bertRate,Port$i)]]}
			}

		}
	}
}
# ................................................................................
#  Abstract: ClearSignalingStatistics	 clrs sign. statis
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc ClearSignalingStatistics {} {

  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

  if {[catch {expr int($vaDxc4Set(currentid))}]} {
    tk_messageBox -icon error -type ok -message "Select the chassis to clear signaling statistics" -title "E1/T1 Generator"
	  return
  }

	set id $vaDxc4Set(currentid)
	#set vaDxc4Set(id$id,start) 1
	set vaDxc4Set(id$id,clear,sign) 1
}

# ................................................................................
#  Abstract: ClearBertStatistics
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc ClearBertStatistics {} {

  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

  if {[catch {expr int($vaDxc4Set(currentid))}]} {
    tk_messageBox -icon error -type ok -message "Select the chassis to clear bert statistics" -title "E1/T1 Generator"
	  return
  }

	set id $vaDxc4Set(currentid)
	#set vaDxc4Set(id$id,start) 1
	set vaDxc4Set(id$id,clear,bert) 1

}

# ................................................................................
#  Abstract: InjectBertErrors
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc InjectBertErrors {} {

  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

  if {[catch {expr int($vaDxc4Set(currentid))}]} {
    tk_messageBox -icon error -type ok -message "Select the chassis to inject bert errors" -title "E1/T1 Generator"
	  return
  }

	set id $vaDxc4Set(currentid)
	#set vaDxc4Set(id$id,start) 1
	set vaDxc4Set(id$id,injecterr) 1

}

# ................................................................................
#  Abstract: InjectBPVErrors
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc InjectBPVErrors {} {

  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

  if {[catch {expr int($vaDxc4Set(currentid))}]} {
    tk_messageBox -icon error -type ok -message "Select the chassis to inject BPV errors" -title "E1/T1 Generator"
	  return
  }

	set id $vaDxc4Set(currentid)
	#set vaDxc4Set(id$id,start) 1
	set vaDxc4Set(id$id,injectbpv) 1

}

# ............................................................................................
#  Abstract: SaveConfigToFile
#  Inputs: 
#
#  Outputs: 
# ...........................................................................................
proc SaveConfigToFile {} {

  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses


  set cfgFile [tk_getSaveFile \
        -initialdir [pwd] \
        -filetypes {{ "CFG Files"   {.cfg }}} \
        -title "Save Configuration As.." \
        -parent . \
        -defaultextension cfg \
			  -initialfile Dxc4Gui]
        
  #If the user selected "Cancel"
  if {$cfgFile == ""} {
    return 0
  }

  set idFile [ open $cfgFile w+ ]

	foreach param {	vaDxc4Set(linktype,t1,frame)	vaDxc4Set(linktype,t1,intftp) vaDxc4Set(linktype,t1,mask)        \
	                vaDxc4Set(linktype,t1,sync)   vaDxc4Set(linktype,t1,linecod) vaDxc4Set(linktype,t1,idlecod)    \
	                vaDxc4Set(linktype,t1,oos)  vaDxc4Set(clocksrc)  vaDxc4Set(linktype,e1,frame)                  \
                  vaDxc4Set(linktype,e1,intftp)  vaDxc4Set(linktype,e1,bal)  vaDxc4Set(linktype,e1,resttime)     \
                  vaDxc4Set(linktype,e1,linecod)  vaDxc4Set(linktype,e1,idlecod)  vaDxc4Set(linktype,e1,oos)     \
                  vaDxc4Set(signtype)  vaDxc4Set(signval) vaDxc4Set(incrspeed) vaDxc4Set(timeres)                \
                	vaDxc4Set(signenab,port)	vaDxc4Set(pattern)	vaDxc4Set(errrate) vaDxc4Set(linkType)           \
									vaDxc4Set(port)		vaDxc4Set(runType) vaDxc4Set(diagnostic,diagport)	\
									vaDxc4Set(diagnostic,loopport) vaDxc4Set(diagnostic,txallones)}	{
	
    puts $idFile  "set $param	[set $param]"
	}
	puts $idFile "set vaDxc4Set(listIP) [list $vaDxc4Set(listIP)]"
  foreach param {signass berttsass bertenab errenab} {
	  ConvertTssOrBertsAssToString	$param
	  puts $idFile	"set vaDxc4Set($param) $vaDxc4Set($param)"
		if {$vaDxc4Set(linkType) == "E1" && ($param == "signass" || $param == "berttsass")} {
			set cnt 31
			set obj ts
		} elseif {$vaDxc4Set(linkType) == "T1" && ($param == "signass" || $param == "berttsass")} {
				set cnt 24
				set obj ts
		} else {
				set cnt 8
				set obj bert
		}
		for {set i 1} {$i <= $cnt} {incr i} {
  	  puts $idFile	"set vaDxc4Set($param,$obj$i) $vaDxc4Set($param,$obj$i)"
		}
	}

	set vaDxc4Set(resources,list) ""
  set reslist  [lrange [$vaDxc4Gui(resources,list) items] 1 end]
	if {$reslist != ""} {
		foreach chassis $reslist {
	  	set id [lindex [split $chassis :] 1]
    	lappend vaDxc4Set(resources,list) $vaDxcStatuses($id,address) $vaDxcStatuses($id,package)
		}
	}

	puts $idFile "set vaDxc4Set(resources,list) \"$vaDxc4Set(resources,list)\""

  close $idFile
}


# ................................................................................
#  Abstract: ConvertTssOrBertsAssToString
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc ConvertTssOrBertsAssToString {param}  {

  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses


	if {$vaDxc4Set(linkType) == "E1" && ($param == "signass" || $param == "berttsass")} {
		set cnt 31
		set obj ts
	} elseif {$vaDxc4Set(linkType) == "T1" && ($param == "signass" || $param == "berttsass")} {
			set cnt 24
			set obj ts
	} else {
			if {[info exists vaDxc4Set(currentid)] && ![catch {expr int($vaDxc4Set(currentid))}]} {
			  set cnt $vaDxcStatuses($vaDxc4Set(currentid),numbPorts)
			} else {
			    set cnt 8
			}
			set obj bert
	}

	set start 0
	set blank 0
	set last 0
	set all  1
	set vaDxc4Set($param) ""
	for {set i 1} {$i <=$cnt} {incr i} {

  	if {$vaDxc4Set(linkType) == "E1" && $i == 16 && $param == "signass" } {
			continue
		}
		if {$vaDxc4Set($param,$obj$i) && !$start } {
			 append vaDxc4Set($param) $i
			 set last 1
			 set start 1
		} elseif {$vaDxc4Set($param,$obj$i) && $start && $last} {
  			 set last 1
         set blank 1
		} elseif {!$vaDxc4Set($param,$obj$i) && $start && $last && $blank} {
  			append vaDxc4Set($param) -
				append vaDxc4Set($param) [expr $i -1]
				set last 0
				set blank 0
				set all 0
		} elseif {$vaDxc4Set($param,$obj$i) && $start && !$last} {
				 append vaDxc4Set($param) ,
  			 append vaDxc4Set($param) $i
				 set last 1
		} elseif {!$vaDxc4Set($param,$obj$i)} {
				set last 0
				set blank 0
				set all 0
		}
	}
	if {$start && $last && $blank} {
		append vaDxc4Set($param) -
		append vaDxc4Set($param) [expr $i -1]
	}
	if {$all && $start && $param != "signass"} {
		set vaDxc4Set($param) "all"
	} elseif {$all && $start && $param == "signass" && $vaDxc4Set(sign,allts)} {
  		set vaDxc4Set($param) "all"
	}
}

# ................................................................................
#  Abstract: ClearConfigChanges
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc ClearConfigChanges {} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

	set names [array names vaDxc4Set change*]
  foreach name $names {
	  unset vaDxc4Set($name)
  }
	$vaDxc4Gui(tb,save) configure -state disabled
}

# ................................................................................
#  Abstract: GetConfigFromFile
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc GetConfigFromFile {} {

  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

  set cfgFile [tk_getOpenFile \
        -initialdir [pwd] \
        -filetypes {{ "CFG Files"   {.cfg }}} \
        -title "Open Configuration " \
        -parent . \
        -defaultextension cfg ]
        
  #If the user selected "Cancel"
  if {$cfgFile == ""} {
    return 0
  }

	#RLDxc4::Dxc4show_progdlg

	if {[RLDxc4::ChkCfgFile $cfgFile]} {
    set gMessage "\n The file $cfgFile doesn't valid for Dxc4 configuration"
		#destroy .progress
    tk_messageBox -icon error -type ok -message "Error while (RLDxc4::ChkCfgFile $cfgFile) procedure \n$gMessage" -title "Error Dxc4"
		return
	} else {
			source $cfgFile
	}
  RLDxc4::Dxc4SetLinkType $vaDxc4Set(linkType)
	$vaDxc4Gui(tb,save) configure -state normal

	foreach {param}      {port,frameT1      \
												port,intfT1	      \
												port,maskT1	      \
												port,syncT1	      \
												port,linecodeT1   \
												port,idleT1       \
												port,oosT1	      \
												port,diagPort     \		  
												port,loopPort     \
												port,txallones    \
												system,clock	    \
                        port,frameE1      \
												port,intfE1	      \
												port,balanE1	    \
												port,syncE1	      \
												port,linecodeE1   \
												port,idleE1       \
												port,oosE1				\
                        sign,type         \
												sign,value	      \
												sign,speed	      \
												sign,timeres	    \
												sign,enable       \
												port,linktype     \
												port,portnumber 	\
												sign,tsass				\
                        bert,pattern      \
												bert,errrate	    \
												bert,enable       \
												bert,errenable    \
												bert,tsass}  {


  	set vaDxc4Set(change,$param) 1
	}

	set resources ""
  set reslist  [lrange [$vaDxc4Gui(resources,list) items] 1 end]
	if {$reslist != ""} {
		foreach chassis $reslist {
	  	set id [lindex [split $chassis :] 1]
    	lappend resources $vaDxcStatuses($id,address) $vaDxcStatuses($id,package)
		}
	}
	if {$vaDxc4Set(resources,list) != ""} {
		foreach {address package} $vaDxc4Set(resources,list) {
		  if {[lsearch $resources $address] == -1} {
			  OkConnChassis $address $package
				ClearConfigChanges
			}
		}
	}
}

# ................................................................................
# ................................................................................
#  Abstract:  ChkCfgFile
#  Inputs: 
#
#  Outputs: 
# ................................................................................
# ................................................................................
proc  ChkCfgFile {ip_file} {
    set numbLine 0
    set fileId [open $ip_file r ]

    while	{[eof $fileId] != 1} {
	    set line [gets $fileId]
						#puts $line
  	  if {[string match "*set vaDxc4Set*" $line ] == 0 && $line != "" } {
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
#  Abstract: FactorySetup
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc FactorySetup {} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

  if {[catch {expr int($vaDxc4Set(currentid))}]} {
    tk_messageBox -icon error -type ok -message "Select chassis to set factory default" -title "E1/T1 Generator"
	  return
  }

  if {$vaDxc4Set(runstate) != "Stop"} {
		tk_messageBox -icon error -type ok -message "The chassis is running stop it before FactorySetup" -title "E1/T1 Generator"
    return    
	}

	RLDxc4::Dxc4show_progdlg
  if {[RLDxc4::SysConfig $vaDxc4Set(currentid) -factory yes]} {
    destroy .progress
    tk_messageBox -icon error -type ok -message "Error while (RLDxc4::SysConfig $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
    return
  }

  set names [array names vaDxc4Set change*]
  foreach name $names {
	  unset vaDxc4Set($name)
  }

	#Get from chassis the configuration to update vaDxc4Cfg array.
	if {[RLDxc4::GetConfig $vaDxc4Set(currentid)  aCfgRes]} {
	  #$vaDxc4Gui(resources,list) itemconfigure $node -fill red
	  destroy .progress
		tk_messageBox -icon error -type ok -message "Error while (RLDxc4::GetConfig $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
    return    
	}
	array set vaDxc4Cfg [array get aCfgRes]

	$vaDxc4Gui(tb,save) configure -state disable

	FillCurrentGuiEntries $vaDxc4Set(currentid) 

	destroy .progress
}

# ................................................................................
#  Abstract: ResetChassis
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc ResetChassis {} {

  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

  if {[catch {expr int($vaDxc4Set(currentid))}]} {
    tk_messageBox -icon error -type ok -message "Select chassis to reset it" -title "E1/T1 Generator"
	  return
  }

  if {$vaDxc4Set(runstate) != "Stop"} {
		tk_messageBox -icon error -type ok -message "The chassis is running stop it before ResetChassis" -title "E1/T1 Generator"
    return    
	}

	RLDxc4::Dxc4show_progdlg
  if {[RLDxc4::SysConfig $vaDxc4Set(currentid) -reset yes]} {
    destroy .progress
    tk_messageBox -icon error -type ok -message "Error while (RLDxc4::SysConfig $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
    return
  }

  set names [array names vaDxc4Set change*]
  foreach name $names {
	  unset vaDxc4Set($name)
  }

	#Get from chassis the configuration to update vaDxc4Cfg array.
	if {[RLDxc4::GetConfig $vaDxc4Set(currentid)  aCfgRes]} {
	  #$vaDxc4Gui(resources,list) itemconfigure $node -fill red
	  destroy .progress
		tk_messageBox -icon error -type ok -message "Error while (RLDxc4::GetConfig $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
    return    
	}
	array set vaDxc4Cfg [array get aCfgRes]

	$vaDxc4Gui(tb,save) configure -state disable

	FillCurrentGuiEntries $vaDxc4Set(currentid) 

	destroy .progress

}


# ................................................................................
#  Abstract: SaveConfigToChassis
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc SaveConfigToChassis {} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

  if {[catch {expr int($vaDxc4Set(currentid))}]} {
    tk_messageBox -icon error -type ok -message "Select chassis to save configuration" -title "E1/T1 Generator"
	  return
  }

	RLDxc4::Dxc4show_progdlg
	if {[info exists vaDxc4Set(change,system,clock)]} {
	   if {$vaDxcStatuses($vaDxc4Set(currentid),numbPorts) == 8 && [lsearch "lbtUL int stnE1 stnT1 auto lbt1 lbt2 lbt3 lbt4 lbt5 lbt6 lbt7 lbt8" $vaDxc4Set(clocksrc)] == -1} {
       destroy .progress
	     tk_messageBox -icon error -type ok -message "Wrong source clock for this chassis" -title "E1/T1 Generator"
		   return
		 }
	   if {$vaDxcStatuses($vaDxc4Set(currentid),numbPorts) == 4 && [lsearch "lbtUL int stnE1 stnT1 auto lbt1 lbt2 lbt3 lbt4" $vaDxc4Set(clocksrc)] == -1} {
       destroy .progress
	     tk_messageBox -icon error -type ok -message "Wrong source clock for this chassis" -title "E1/T1 Generator"
		   return
		 }
		 if {[RLDxc4::SysConfig $vaDxc4Set(currentid) -srcClk $vaDxc4Set(clocksrc)]} {
		   destroy .progress
	     tk_messageBox -icon error -type ok -message "Error while (RLDxc4::SysConfig $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
		   return
		 }
		 #catch {unset vaDxc4Cfg(id$vaDxc4Set(currentid),linkType)}
	}

  if {$vaDxcStatuses($vaDxc4Set(currentid),numbPorts) == 8 && [lsearch "1 2 3 4 5 6 7 8 all" $vaDxc4Set(port)] == -1} {
     destroy .progress
     tk_messageBox -icon error -type ok -message "Wrong source clock for this chassis" -title "E1/T1 Generator"
	   return
	}
  if {$vaDxcStatuses($vaDxc4Set(currentid),numbPorts) == 4 && [lsearch "1 2 3 4 all" $vaDxc4Set(port)] == -1} {
     destroy .progress
     tk_messageBox -icon error -type ok -message "Wrong source clock for this chassis" -title "E1/T1 Generator"
	   return
	}

	if {[info exists vaDxc4Set(change,port,diagPort)]} {
	   if {$vaDxcStatuses($vaDxc4Set(currentid),numbPorts) == 8 && $vaDxc4Set(diagnostic,diagport) > 8} {
       destroy .progress
	     tk_messageBox -icon error -type ok -message "Wrong port number for diagnostics for this chassis" -title "E1/T1 Generator"
		   return
		 }
	   if {$vaDxcStatuses($vaDxc4Set(currentid),numbPorts) == 4 && $vaDxc4Set(diagnostic,diagport) > 4} {
       destroy .progress
	     tk_messageBox -icon error -type ok -message "Wrong port number for diagnostics for this chassis" -title "E1/T1 Generator"
		   return
		 }
	}


	set changelist ""
	if {$vaDxc4Set(linkType) == "T1"} {
	  foreach {change param val} [list port,frameT1 -frameT1 $vaDxc4Set(linktype,t1,frame)           \
																		 port,intfT1	-intfT1	 $vaDxc4Set(linktype,t1,intftp)          \
																		 port,maskT1	-mask		 $vaDxc4Set(linktype,t1,mask)            \
																		 port,syncT1	-sync		 $vaDxc4Set(linktype,t1,sync)            \
																		 port,linecodeT1 -lineCodeT1	$vaDxc4Set(linktype,t1,linecod)	 \
																		 port,idleT1 -idleCode $vaDxc4Set(linktype,t1,idlecod)         \
																		 port,oosT1	 -oosCode	 $vaDxc4Set(linktype,t1,oos)] {

			if {[info exists vaDxc4Set(change,$change)]} {
				lappend changelist $param $val
			}
		}
		#comments: change frame, as port parameter, from unframe to any other causes the BERT time slot assignment be changed to all.
		if {$changelist != ""} {
		  if {[info exists vaDxc4Set(change,port,portnumber)]} {
				lappend changelist -updPort $vaDxc4Set(port)
				unset	 vaDxc4Set(change,port,portnumber)
			}
		  if {[eval RLDxc4::PortConfig $vaDxc4Set(currentid) $vaDxc4Set(linkType) $changelist]} {
  		  destroy .progress
	      tk_messageBox -icon error -type ok -message "Error while (RLDxc4::PortConfig $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
		    return
		  }
		  #catch {unset vaDxc4Cfg(id$vaDxc4Set(currentid),linkType)}
		}
	} else {
		  foreach {change param val} [list port,frameE1 -frameE1 $vaDxc4Set(linktype,e1,frame)           \
																			 port,intfE1	-intfE1	 $vaDxc4Set(linktype,e1,intftp)          \
																			 port,balanE1	-balanced		 $vaDxc4Set(linktype,e1,bal)         \
																			 port,syncE1	-restTime		 $vaDxc4Set(linktype,e1,resttime)    \
																			 port,linecodeE1 -lineCodeE1	$vaDxc4Set(linktype,e1,linecod)	 \
																			 port,idleE1 -idleCode $vaDxc4Set(linktype,e1,idlecod)         \
																			 port,oosE1	 -oosCode	 $vaDxc4Set(linktype,e1,oos)] {
	
				if {[info exists vaDxc4Set(change,$change)]} {
					lappend changelist $param $val
				}
			}

			if {$changelist != ""} {
			  if {[info exists vaDxc4Set(change,port,portnumber)]} {
					lappend changelist -updPort $vaDxc4Set(port)
					unset	 vaDxc4Set(change,port,portnumber)
				}
			  if {[eval RLDxc4::PortConfig $vaDxc4Set(currentid) $vaDxc4Set(linkType)  $changelist]} {
		      destroy .progress
		      tk_messageBox -icon error -type ok -message "Error while (RLDxc4::PortConfig $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
			    return
			  }
		    #catch {unset vaDxc4Cfg(id$vaDxc4Set(currentid),linkType)}
		  }
	}
	if {[info exists vaDxc4Set(change,port,diagPort)]} {
	  if {[RLDxc4::SetLoop $vaDxc4Set(currentid) $vaDxc4Set(diagnostic,loopport)  $vaDxc4Set(diagnostic,diagport)]} {
      destroy .progress
      tk_messageBox -icon error -type ok -message "Error while (RLDxc4::SetLoop $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
	    return
	  }
	  if {[RLDxc4::SetAllOnes $vaDxc4Set(currentid) $vaDxc4Set(diagnostic,txallones)  $vaDxc4Set(diagnostic,diagport)]} {
      destroy .progress
      tk_messageBox -icon error -type ok -message "Error while (RLDxc4::SetAllOnes $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
	    return
	  }
	} else {
			if {[info exists vaDxc4Set(change,port,loopPort)]} {
			  if {[RLDxc4::SetLoop $vaDxc4Set(currentid) $vaDxc4Set(diagnostic,loopport)  $vaDxc4Set(diagnostic,diagport)]} {
		      destroy .progress
		      tk_messageBox -icon error -type ok -message "Error while (RLDxc4::SetLoop $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
			    return
			  }
			}
			if {[info exists vaDxc4Set(change,port,txallones)]} {
			  if {[RLDxc4::SetAllOnes $vaDxc4Set(currentid) $vaDxc4Set(diagnostic,txallones)  $vaDxc4Set(diagnostic,diagport)]} {
		      destroy .progress
		      tk_messageBox -icon error -type ok -message "Error while (RLDxc4::SetAllOnes $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
			    return
			  }
			}
	}


	set changelist ""
	if {$vaDxc4Set(signenab,port)} {
	  set signenable enbl
	} else {
  	  set signenable dsbl
	}
  foreach {change param val} [list sign,type -signType $vaDxc4Set(signtype)           \
																	 sign,value	-signValue	 $vaDxc4Set(signval)        \
																	 sign,speed	-incrSpeed		 $vaDxc4Set(incrspeed)    \
																	 sign,timeres	-timeResol		 $vaDxc4Set(timeres)    \
																	 sign,enable -enabled	$signenable	                  \
																	 port,linktype -linkType $vaDxc4Set(linkType)] {

		if {[info exists vaDxc4Set(change,$change)]} {
			lappend changelist $param $val
		}
	}

	if {[info exists vaDxc4Set(change,sign,tsass)]} {
	  ConvertTssOrBertsAssToString	signass
		if {$vaDxc4Set(signass) == ""} {
		  destroy .progress
      tk_messageBox -icon error -type ok -message "Select at least one time slot assignment for signaling" -title "E1/T1 Generator"
	    return
		}
		lappend changelist	-tsAssignm  $vaDxc4Set(signass)
	}
	#puts $changelist
	if {$changelist != ""} {
	  if {[info exists vaDxc4Set(change,port,portnumber)]} {
			lappend changelist -updPort $vaDxc4Set(port)
			unset	 vaDxc4Set(change,port,portnumber)
		}
	  if {[eval RLDxc4::SignConfig $vaDxc4Set(currentid) $changelist]} {
		  destroy .progress
      tk_messageBox -icon error -type ok -message "Error while (RLDxc4::SignConfig $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
	    return
	  }
		#catch {unset vaDxc4Cfg(id$vaDxc4Set(currentid),linkType)}
  }

	set changelist ""
  foreach {change param val} [list bert,pattern -pattern $vaDxc4Set(pattern)          \
																	 bert,errrate	-inserrRate	 $vaDxc4Set(errrate)      \
																	 port,linktype -linkType $vaDxc4Set(linkType)       \
																	 port,portnumber -updPort	 $vaDxc4Set(port)] {

		if {[info exists vaDxc4Set(change,$change)]} {
			lappend changelist $param $val
		}
	}

	foreach {param obj comm} {enable bertenab -enabledBerts errenable errenab -inserrBerts  tsass berttsass -tsAssignm} {
		if {[info exists vaDxc4Set(change,bert,$param)]} {
		  ConvertTssOrBertsAssToString	$obj
			if {$vaDxc4Set($obj) == "" && $obj == "berttsass"} {
			  destroy .progress
	      tk_messageBox -icon error -type ok -message "Select at least one time slot assignment for bert" -title "E1/T1 Generator"
		    return
			} elseif {$vaDxc4Set($obj) == "" && $obj != "berttsass"} {
					set vaDxc4Set($obj) none
			}
			lappend changelist	$comm  $vaDxc4Set($obj)
		}
	}

  if {$vaDxc4Set(linktype,[string tolower $vaDxc4Set(linkType)],frame) == "unframe" } {
	  if {[info exists vaDxc4Set(change,port,frame$vaDxc4Set(linkType))]} {
		  set vaDxc4Set(berttsass) unframe
		  lappend changelist	-tsAssignm $vaDxc4Set(berttsass)
		}
	}

	if {$changelist != ""} {
	  if {[eval RLDxc4::BertConfig $vaDxc4Set(currentid) $changelist]} {
		  destroy .progress
      tk_messageBox -icon error -type ok -message "Error while (RLDxc4::BertConfig $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
	    return
	  }
		#catch {unset vaDxc4Cfg(id$vaDxc4Set(currentid),linkType)}
  }

  set names [array names vaDxc4Set change*]
  foreach name $names {
	  unset vaDxc4Set($name)
  }

	#Get from chassis the configuration to update vaDxc4Cfg array.
	if {[RLDxc4::GetConfig $vaDxc4Set(currentid)  aCfgRes]} {
	  #$vaDxc4Gui(resources,list) itemconfigure $node -fill red
	  destroy .progress
		tk_messageBox -icon error -type ok -message "Error while (RLDxc4::GetConfig $vaDxc4Set(currentid)) procedure \n$gMessage" -title "E1/T1 Generator"
    return    
	}
	array set vaDxc4Cfg [array get aCfgRes]

	$vaDxc4Gui(tb,save) configure -state disable

	FillCurrentGuiEntries $vaDxc4Set(currentid) 

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
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

	if {[regexp -nocase {RLDxc4.exe} $vaDxc4Set(rundir) match]} {
  	set path	Dxc4Help.chm
	} else {
    	set path	$vaDxc4Set(rundir)/Dxc4Help.chm
	}

  set comspec [set env(COMSPEC)]
 
  exec $comspec /c start $path
}


#..................................................................................
#  Abstract:  RunCurrentChassis
#  Inputs: 	 tool the bert or sign
#						 id   id of chassis
#
#  Outputs: 
#..................................................................................
proc RunCurrentChassis {tool id {clear ""}} {

  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

	$vaDxc4Gui(tb,run) configure -state disable 
	$vaDxc4Gui(tb,stop) configure -state normal
 
	if {$clear == ""} {
    set vaDxc4Set(id$id,clear,bert,counter) 0
	} else {
	    #If chassis is running , and we connect it to GUI we must avoid clear command to obtain errors if any are.
      set vaDxc4Set(id$id,clear,bert,counter) 10
	}
  if {[catch {expr int($id)}]} {
		$vaDxc4Gui(tb,run) configure -state  normal
		$vaDxc4Gui(tb,stop) configure -state disable 
    tk_messageBox -icon error -type ok -message "Select the chassis to run it" -title "E1/T1 Generator"
	  return
  }

	if {[$vaDxc4Gui(tb,save) cget -state] == "normal"} {
		$vaDxc4Gui(tb,run) configure -state  normal
		$vaDxc4Gui(tb,stop) configure -state disable 
    tk_messageBox -icon error -type ok -message "Save configuration to chassis before to run it or select it again" -title "E1/T1 Generator"
	  return
	}

	if {[RLDxc4::Start $id [lindex "sign bert" $tool]]} {
		$vaDxc4Gui(tb,run) configure -state  normal
		$vaDxc4Gui(tb,stop) configure -state disable 
		if {[string match "*If port has unframe mode*" $gMessage]} {
		  append gMessage "\nMAKE ports and active berts the same frame mode and SAVE again GUI configuration to chassis"
			$vaDxc4Gui(tb,save) configure -state normal
			#set vaDxc4Set(change,port,frame$vaDxc4Set(linkType)) 1
		}
		tk_messageBox -icon error -type ok -message "Error while (RLDxc4::Start $id) procedure \n$gMessage" -title "E1/T1 Generator"
	  return
	}

	DisableEnableEntries	disabled

	if {$tool} {
	  set vaDxc4Set(runstate) "Bert run..."
		set vaDxc4Cfg(id$id,BertRun) Run
	} else {
  	  set vaDxc4Set(runstate) "Signaling run..."
			set vaDxc4Cfg(id$id,SigRun) Run
	}
  $vaDxc4Gui(runstate) configure -entryfg darkgreen

	if {[winfo exists .topDxc4Gui]} {
  	FillGuiIndicators run
	}
	set vaDxc4Set(id$id,start) 1
	ReadChassisStatistics $tool $id
}


# ................................................................................
#  Abstract: ReadChassisStatistics
#  Inputs: 	 tool the bert or sign
#						 id   id of chassis
#
#  Outputs: 
# ................................................................................
proc ReadChassisStatistics {tool id} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

  #puts "Rinning $id"

	if {![winfo exists .topDxc4Gui]} {
  	return
	}
	if {!$vaDxc4Set(id$id,start)} {
		if {[RLDxc4::Stop $id [lindex "sign bert" $tool]]} {
			tk_messageBox -icon error -type ok -message "Error while (RLDxc4::Stop $id) procedure \n$gMessage" -title "E1/T1 Generator"
		}
		#puts "1 $id"
		$vaDxc4Gui(tb,run) configure -state  normal
		$vaDxc4Gui(tb,stop) configure -state disable 
	  set vaDxc4Set(runstate) "Stop"
	  $vaDxc4Gui(runstate) configure -entryfg red
		return
	}
  if {[info exists vaDxc4Set(id$id,clear,sign)]} {
		if {[RLDxc4::Clear $id  sign]} {
			tk_messageBox -icon error -type ok -message "Error while (RLDxc4::Clear $id sign) procedure \n$gMessage" -title "E1/T1 Generator"
		}
		unset vaDxc4Set(id$id,clear,sign)
	}
	#clear bert at begin of run after 2 seconds
  incr vaDxc4Set(id$id,clear,bert,counter)
	if {$vaDxc4Set(id$id,clear,bert,counter) == 3} {
		set vaDxc4Set(id$id,clear,bert) 1
	}
  if {[info exists vaDxc4Set(id$id,clear,bert)]} {
		if {[RLDxc4::Clear $id  bert]} {
			tk_messageBox -icon error -type ok -message "Error while (RLDxc4::Stop $id bert) procedure \n$gMessage" -title "E1/T1 Generator"
		}
		unset vaDxc4Set(id$id,clear,bert)
	}
  if {[info exists vaDxc4Set(id$id,injecterr)]} {
		if {[RLDxc4::BertInject $id ]} {
			tk_messageBox -icon error -type ok -message "Error while (RLDxc4::BertInject $id) procedure \n$gMessage" -title "E1/T1 Generator"
		}
		unset vaDxc4Set(id$id,injecterr)
	}
  if {[info exists vaDxc4Set(id$id,injectbpv)]} {
		if {[RLDxc4::BPVInject $id ]} {
			tk_messageBox -icon error -type ok -message "Error while (RLDxc4::BPVInject $id) procedure \n$gMessage" -title "E1/T1 Generator"
		}
		unset vaDxc4Set(id$id,injectbpv)
	}

	if {$tool} {
		 set liststatist bertStatis
	} else {
		 set liststatist "signStatis signTsError signValue"
	}
	foreach statist $liststatist {
		if {![winfo exists .topDxc4Gui]} {
	  	return
		}
		if {!$vaDxc4Set(id$id,start)} {
			if {[RLDxc4::Stop $id [lindex "sign bert" $tool]]} {
				tk_messageBox -icon error -type ok -message "Error while (RLDxc4::Stop $id) procedure \n$gMessage" -title "E1/T1 Generator"
			}
   		#puts "2 $statist $id"
			$vaDxc4Gui(tb,run) configure -state  normal
			$vaDxc4Gui(tb,stop) configure -state disable 
		  set vaDxc4Set(runstate) "Stop"
		  $vaDxc4Gui(runstate) configure -entryfg red
			return
		}
		if {$statist == "bertStatis" || $vaDxc4Set(sign,currstat) == "$statist"} {
			if {!$vaDxc4Set(id$id,start)} {
				if {[RLDxc4::Stop $id [lindex "sign bert" $tool]]} {
					tk_messageBox -icon error -type ok -message "Error while (RLDxc4::Stop $id) procedure \n$gMessage" -title "E1/T1 Generator"
				}
   		  #puts "3 $statist $id"
				$vaDxc4Gui(tb,run) configure -state  normal
				$vaDxc4Gui(tb,stop) configure -state disable 
			  set vaDxc4Set(runstate) "Stop"
			  $vaDxc4Gui(runstate) configure -entryfg red
				return
			}
			if {![winfo exists .topDxc4Gui]} {
		  	return
			}
			if {[RLDxc4::GetStatistics $id  aResStat -statistic $statist]} {
			  RLDxc4::Delay 3
				puts "[RLDxc4::TimeDate]  Error while (RLDxc4::GetStatistics $id) procedure \n$gMessage"
			  if {[RLDxc4::GetStatistics $id  aResStat -statistic $statist]} {
				  tk_messageBox -icon error -type ok -message "Error while (RLDxc4::GetStatistics $id) procedure \n$gMessage" -title "E1/T1 Generator"
				}
			}
			if {!$vaDxc4Set(id$id,start)} {
				if {[RLDxc4::Stop $id [lindex "sign bert" $tool]]} {
					tk_messageBox -icon error -type ok -message "Error while (RLDxc4::Stop $id) procedure \n$gMessage" -title "E1/T1 Generator"
				}
   		  #puts "4  $statist $id"
				$vaDxc4Gui(tb,run) configure -state  normal
				$vaDxc4Gui(tb,stop) configure -state disable 
			  set vaDxc4Set(runstate) "Stop"
			  $vaDxc4Gui(runstate) configure -entryfg red
				return
			}
    	if {[winfo exists .topDxc4Gui]} {
		  	FillGuiIndicators run
			}
    	array set vaDxc4Cfg [array get aResStat]
			if {$statist == "signStatis" || $statist == "bertStatis"} {
      	if {[winfo exists .topDxc4Gui]} {
			    FillGeneralStatistics	 $id
				}
			} else {
        	if {[winfo exists .topDxc4Gui]} {
  			    FillSignalingStatistics	 $id value
  			    FillSignalingStatistics	 $id error
					}
			}
		}
	}
	if {!$vaDxc4Set(id$id,start)} {
		if {[RLDxc4::Stop $id [lindex "sign bert" $tool]]} {
			tk_messageBox -icon error -type ok -message "Error while (RLDxc4::Stop $id) procedure \n$gMessage" -title "E1/T1 Generator"
		}
   	#puts "5 $id"
		$vaDxc4Gui(tb,run) configure -state  normal
		$vaDxc4Gui(tb,stop) configure -state disable 
	  set vaDxc4Set(runstate) "Stop"
	  $vaDxc4Gui(runstate) configure -entryfg red
		return
	}
	if {![winfo exists .topDxc4Gui]} {
  	return
	}
	FillCollorBertGenerator $tool
	after 1000 RLDxc4::ReadChassisStatistics $tool $id
}


# ................................................................................
#  Abstract: FillCollorBertGenerator
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc FillCollorBertGenerator {tool} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses
	if {$tool} {
			for {set i 1} {$i <= 8} {incr i} {
			  if {($RLDxc4::vaDxc4Set(genstat,entryloss$i)!=0 && $RLDxc4::vaDxc4Set(genstat,entryloss$i)!= "") || \
			      ($RLDxc4::vaDxc4Set(genstat,entrysec$i)!=0 && $RLDxc4::vaDxc4Set(genstat,entrysec$i)!= "") || \
					  ($RLDxc4::vaDxc4Set(genstat,entrybits$i)!=0 && $RLDxc4::vaDxc4Set(genstat,entrybits$i)!= "")} {
				  $vaDxc4Gui(bertstat,genstat,entrybert$i) configure -entrybg red
				} else {
  				  $vaDxc4Gui(bertstat,genstat,entrybert$i) configure -entrybg green
				}
			}
	} else {
			for {set i 1} {$i <= 8} {incr i} {
			  if {($RLDxc4::vaDxc4Set(genstat,entryerr$i)!=0 && $RLDxc4::vaDxc4Set(genstat,entryerr$i)!= "") || \
			       $RLDxc4::vaDxc4Set(genstat,entryrec$i) == 0} {
				  $vaDxc4Gui(signstat,genstat,entryport$i) configure -entrybg red
				} else {
  				  $vaDxc4Gui(signstat,genstat,entryport$i) configure -entrybg green
				}
			}

	}

}

# ................................................................................
#  Abstract: StopCurrentChassis
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc StopCurrentChassis {tool id} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

	$vaDxc4Gui(tb,run) configure -state  normal
	$vaDxc4Gui(tb,stop) configure -state disable 
  if {[catch {expr int($id)}]} {
    tk_messageBox -icon error -type ok -message "Select the chassis to stop it" -title "E1/T1 Generator"
	  return
  }
  DisableEnableEntries normal
	$vaDxc4Gui(tb,save) configure -state disable

	set vaDxc4Set(id$id,start) 0
	set vaDxc4Cfg(id$id,SigRun) Stop
	set vaDxc4Cfg(id$id,BertRun) Stop

	if {[winfo exists .topDxc4Gui]} {
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
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

  set reslist  [lrange [$vaDxc4Gui(resources,list) items] 1 end]

 	foreach chassis $reslist {
  	set id [lindex [split $chassis :] 1]
		if {[info exists vaDxc4Set(id$id,start)] && $vaDxc4Set(id$id,start)} {
		  set runid $id
		}
	}
	if {[info exists runid] && $param == "run"} {
	  $vaDxc4Gui(runTime) configure -text "Run time [RLDxc4::TimeDate]"
		$vaDxc4Gui(runStatus) configure	 -text "Chassis is running"
	} elseif {![info exists runid] && $param == "run"} {
			$vaDxc4Gui(startTime) configure	 -text "Start time [RLDxc4::TimeDate]"
			$vaDxc4Gui(runStatus) configure	 -text "Chassis is running"
	} elseif {![info exists runid] && $param == "stop"} {
		  $vaDxc4Gui(runTime) configure -text "Run time [RLDxc4::TimeDate]"
			$vaDxc4Gui(runStatus) configure	 -text "Chassis was stoped"
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
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

	foreach entry $vaDxc4Set(lDisabledEntries) {
		 $entry configure -state $param
	}
	.topDxc4Gui.mainframe setmenustate getcfgfile $param
	.topDxc4Gui.mainframe setmenustate savecfgfile $param
	.topDxc4Gui.mainframe setmenustate savecfgchass $param
	.topDxc4Gui.mainframe setmenustate exit $param
	.topDxc4Gui.mainframe setmenustate sign $param
	.topDxc4Gui.mainframe setmenustate bert $param

  if {$vaDxc4Set(linkType) == "T1" && $param == "normal"} {
	  for {set i 25} {$i <= 31} {incr i} {
		  $vaDxc4Gui(signsetup,tsass,ts$i) configure -state disabled
		  $vaDxc4Gui(bertsetup,tsass,ts$i) configure -state disabled
		}	
	}

}

# ................................................................................
#  Abstract: RunAllChassis
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc RunAllChassis {} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses


  set reslist  [lrange [$vaDxc4Gui(resources,list) items] 1 end]
	if {$reslist == ""} {
    tk_messageBox -icon error -type ok -message "There aren't chassis to run its" -title "E1/T1 Generator"
	  return
	}
	foreach chassis $reslist {
  	set id [lindex [split $chassis :] 1]
		if {![info exists vaDxc4Set(id$id,start)] || !$vaDxc4Set(id$id,start)} {
		  RunCurrentChassis $vaDxc4Set(runType) $id
		}
	}
}

# ................................................................................
#  Abstract: StopAllChassis
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc StopAllChassis {} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

  set reslist  [lrange [$vaDxc4Gui(resources,list) items] 1 end]
	if {$reslist == ""} {
   # tk_messageBox -icon error -type ok -message "There aren't chassis to stop its" -title "E1/T1 Generator"
	  return
	}
	foreach chassis $reslist {
  	set id [lindex [split $chassis :] 1]
		if {[info exists vaDxc4Set(id$id,start)] && $vaDxc4Set(id$id,start)} {
  		StopCurrentChassis $vaDxc4Set(runType) $id
			#puts "stop $id"
		}
	}
}


# ................................................................................
#  Abstract: SaveChanges
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc SaveChanges {type param} {

  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses


	$vaDxc4Gui(tb,save) configure -state normal
	set vaDxc4Set(change,$type,$param) 1
	if {$type == "port" && $param == "frame$vaDxc4Set(linkType)" && $vaDxc4Set(linktype,[string tolower $vaDxc4Set(linkType)],frame) == "unframe"} {
	  catch {pack forget $vaDxc4Gui(bertsetup,tsass)}
	} elseif {$type == "port" && $param == "frame$vaDxc4Set(linkType)" && $vaDxc4Set(linktype,[string tolower $vaDxc4Set(linkType)],frame) != "unframe"} {
  	  catch {pack $vaDxc4Gui(bertsetup,tsass)}
	}
	if {$type == "port" && $param == "intfT1"} {
	  if {$vaDxc4Set(linktype,t1,intftp) == "dsu"} {
    	set vaDxc4Set(maskList) "0-133 134-266 267-399 400-533 534-655 fcc-68a"
			if {[lsearch $vaDxc4Set(maskList) $vaDxc4Set(linktype,t1,mask)] == -1} {
			  set vaDxc4Set(linktype,t1,mask) "0-133"
			}
		} else {
      	set vaDxc4Set(maskList) "0 7.5 15 22.5"
				if {[lsearch $vaDxc4Set(maskList) $vaDxc4Set(linktype,t1,mask)] == -1} {
		  	  set vaDxc4Set(linktype,t1,mask) "0"
				}
		}
		$vaDxc4Gui(portsetup,linktype,t1,mask) configure -values $vaDxc4Set(maskList)
	}
}
# ................................................................................
#  Abstract: Create General signaling statistics into Dxc4 GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc GeneralSignStatistics {} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set

    set vaDxc4Gui(signstat,genstat) [TitleFrame $vaDxc4Gui(signstatfr).general -text "General Statistics"]
		  set genstatfr [$vaDxc4Gui(signstat,genstat) getframe]
			set lablesfr [frame $genstatfr.lablesfr]
	      set labport  [label $lablesfr.labport -text "Ports" ]
	      set labsent  [label $lablesfr.labsent -text "Sent signaling" ]
	      set labrec   [label $lablesfr.labrec -text "     Received signaling" ]
	      set laberr   [label $lablesfr.laberr -text "Error signaling" ]
				pack $labport	$labsent	$labrec $laberr -side left -padx 15
			pack $lablesfr -anchor w

			for {set i 1} {$i <= 8} {incr i} {
				 set vaDxc4Gui(signstat,genstat,entriesfr$i) [frame $genstatfr.entriesfr$i]
				   set vaDxc4Gui(signstat,genstat,entryport$i) [LabelEntry $vaDxc4Gui(signstat,genstat,entriesfr$i).entryport$i -label "" -width 5 -text $i  \
					 -justify center -editable 0 -entrybg lightgray -relief flat]
				   set vaDxc4Gui(signstat,genstat,entrysent$i) [LabelEntry $vaDxc4Gui(signstat,genstat,entriesfr$i).entrysent$i -label "" -width 15 \
					 -textvariable RLDxc4::vaDxc4Set(genstat,entrysent$i) -editable 0 -justify center]
				   set vaDxc4Gui(signstat,genstat,entryrec$i) [LabelEntry $vaDxc4Gui(signstat,genstat,entriesfr$i).entryrec$i -label "" -width 15 \
					 -textvariable RLDxc4::vaDxc4Set(genstat,entryrec$i) -editable 0 -justify center]
				   set vaDxc4Gui(signstat,genstat,entryerr$i) [LabelEntry $vaDxc4Gui(signstat,genstat,entriesfr$i).entryerr$i -label "" -width 15 \
					 -textvariable RLDxc4::vaDxc4Set(genstat,entryerr$i) -editable 0 -justify center]
				   pack	 $vaDxc4Gui(signstat,genstat,entryport$i) $vaDxc4Gui(signstat,genstat,entrysent$i)  $vaDxc4Gui(signstat,genstat,entryrec$i) \
			           $vaDxc4Gui(signstat,genstat,entryerr$i) -side left -padx 10 -pady 3
				 pack $vaDxc4Gui(signstat,genstat,entriesfr$i) -anchor w
			}
}


# ................................................................................
#  Abstract: Create General bert statistics into Dxc4 GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc GeneralBertStatistics {} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set

    set vaDxc4Gui(bertstat,genstat) [TitleFrame $vaDxc4Gui(bertstatfr).general -text "General Statistics"]
		  set genstatfr [$vaDxc4Gui(bertstat,genstat) getframe]
			set lablesfr [frame $genstatfr.lablesfr]
	      set labbert  [label $lablesfr.labbert -text "Bert" ]
	      set labrun  [label $lablesfr.labrun -text "Run time" ]
	      set labloss   [label $lablesfr.labloss -text "Sync loss" ]
	      set labsec  [label $lablesfr.labsec -text "Error second" ]
	      set labbits  [label $lablesfr.labbits -text "Error bits" ]
				set labber  [label $lablesfr.labber -text "Average BER"]
				pack $labbert	$labrun	$labloss $labsec $labbits $labber -side left -padx 20
			pack $lablesfr -anchor w

			for {set i 1} {$i <= 8} {incr i} {
				 set vaDxc4Gui(bertstat,genstat,entriesfr$i) [frame $genstatfr.entriesfr$i]
				   set vaDxc4Gui(bertstat,genstat,entrybert$i) [LabelEntry $vaDxc4Gui(bertstat,genstat,entriesfr$i).entrybert$i -label "" -width 5 -text $i  \
					 -justify center -editable 0 -entrybg lightgray -relief flat]
				   set vaDxc4Gui(bertstat,genstat,entryrun$i) [LabelEntry $vaDxc4Gui(bertstat,genstat,entriesfr$i).entryrun$i -label "" -width 12 \
					 -textvariable RLDxc4::vaDxc4Set(genstat,entryrun$i) -editable 0 -justify center]
				   set vaDxc4Gui(bertstat,genstat,entryloss$i) [LabelEntry $vaDxc4Gui(bertstat,genstat,entriesfr$i).entryloss$i -label "" -width 11 \
					 -textvariable RLDxc4::vaDxc4Set(genstat,entryloss$i) -editable 0 -justify center]
				   set vaDxc4Gui(bertstat,genstat,entrysec$i) [LabelEntry $vaDxc4Gui(bertstat,genstat,entriesfr$i).entrysec$i -label "" -width 11 \
					 -textvariable RLDxc4::vaDxc4Set(genstat,entrysec$i) -editable 0 -justify center]
				   set vaDxc4Gui(bertstat,genstat,entrybits$i) [LabelEntry $vaDxc4Gui(bertstat,genstat,entriesfr$i).entrybits$i -label "" -width 11 \
					 -textvariable RLDxc4::vaDxc4Set(genstat,entrybits$i) -editable 0 -justify center]
				   set vaDxc4Gui(bertstat,genstat,entryber$i) [LabelEntry $vaDxc4Gui(bertstat,genstat,entriesfr$i).entryber$i -label "" -width 11 \
					 -textvariable RLDxc4::vaDxc4Set(genstat,entryber$i) -editable 0 -justify center]
				   pack	 $vaDxc4Gui(bertstat,genstat,entrybert$i) \
								 $vaDxc4Gui(bertstat,genstat,entryrun$i)	\
								 $vaDxc4Gui(bertstat,genstat,entryloss$i)	\
								 $vaDxc4Gui(bertstat,genstat,entrysec$i)	\
			           $vaDxc4Gui(bertstat,genstat,entrybits$i) \
								 $vaDxc4Gui(bertstat,genstat,entryber$i) -side left -padx 10 -pady 3
				 pack $vaDxc4Gui(bertstat,genstat,entriesfr$i) -anchor w
			}
}


# ................................................................................
#  Abstract: Create General signaling statistics into Dxc4 GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc TSsErrSignStatistics {} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set

  set vaDxc4Gui(signstat,tserrstat) [TitleFrame $vaDxc4Gui(signstatfr).errorst -text "TSs Error Statistics"]
	set tserrstatfr [$vaDxc4Gui(signstat,tserrstat) getframe]

    set sw [ScrolledWindow $tserrstatfr.sw -relief sunken -borderwidth 2]
    set sf [ScrollableFrame $sw.f]
    $sw setwidget $sf
		$sf configure -constrainedwidth 1
    set subf [$sf getframe]

		set vaDxc4Gui(signstat,tserrstat,label) [Entry $tserrstatfr.lab -width 90 -textvariable RLDxc4::vaDxc4Set(tserrstat,label) \
		                                         -relief flat -editable 0 -bg lightgray] 
		 
    set vaDxc4Set(tserrstat,label) "TSs      \
         Port 1         \
		     Port 2         \
	       Port 3         \
	       Port 4         \
	       Port 5         \
	       Port 6         \
	       Port 7         \
	       Port 8"

		pack $vaDxc4Gui(signstat,tserrstat,label)	 -anchor w
    for {set i 1} {$i <= 31} {incr i} {
			set vaDxc4Gui(signstat,tserrstat,ts$i) [Entry $subf.ent$i -width 50 -textvariable RLDxc4::vaDxc4Set(tserrstat,ts$i) -relief flat -editable 0] 
			if {$vaDxc4Set(linkType) == "E1" || ($vaDxc4Set(linkType)== "T1" && $i<25)} {
        pack $vaDxc4Gui(signstat,tserrstat,ts$i)	  -fill x -pady 3
			}
    	bind $subf.ent$i <FocusIn> "$sf see $subf.ent$i"
    }

    pack $sw -fill both -expand yes
	#pack $vaDxc4Gui(signstat,tserrstat) -fill both

}


# ................................................................................
#  Abstract: Create General signaling statistics into Dxc4 GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc TSsValSignStatistics {} {

  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set

  set vaDxc4Gui(signstat,tsvalstat) [TitleFrame $vaDxc4Gui(signstatfr).valst -text "TSs Signaling Value Statistics"]
	set tsvalstatfr [$vaDxc4Gui(signstat,tsvalstat) getframe]

    set sw [ScrolledWindow $tsvalstatfr.sw -relief sunken -borderwidth 2]
    set sf [ScrollableFrame $sw.f]
    $sw setwidget $sf
		$sf configure -constrainedwidth 1
    set subf [$sf getframe]

		set vaDxc4Gui(signstat,tsvalstat,label) [Entry $tsvalstatfr.lab -width 90 -textvariable RLDxc4::vaDxc4Set(tsvalstat,label) \
		                                         -relief flat -editable 0 -bg lightgray] 
		 
    set vaDxc4Set(tsvalstat,label) "TSs      \
         Port 1         \
		     Port 2         \
	       Port 3         \
	       Port 4         \
	       Port 5         \
	       Port 6         \
	       Port 7         \
	       Port 8"
		pack $vaDxc4Gui(signstat,tsvalstat,label)	 -anchor w
    for {set i 1} {$i <= 31} {incr i} {
			set vaDxc4Gui(signstat,tsvalstat,ts$i) [Entry $subf.ent$i -width 50 -textvariable RLDxc4::vaDxc4Set(tsvalstat,ts$i) -relief flat -editable 0] 
			if {$vaDxc4Set(linkType) == "E1" || ($vaDxc4Set(linkType)== "T1" && $i<25)} {
        pack $vaDxc4Gui(signstat,tsvalstat,ts$i)	  -fill x -pady 3
			}
    	bind $subf.ent$i <FocusIn> "$sf see $subf.ent$i"
    }


    pack $sw -fill both -expand yes
	#pack $vaDxc4Gui(signstat,tsvalstat) -fill both

}



# ................................................................................
#  Abstract: Create introduction GUI while building main Dxc4 GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc CloseDxc4Gui {} {
  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set
  variable vaDxc4Cfg
	variable vaDxcStatuses

	if {!$vaDxc4Set(closeByDestroy)} {
    destroy .topDxc4Gui
 	  return
	}

  set reslist  [lrange [$vaDxc4Gui(resources,list) items] 1 end]
	if {$reslist == ""} {
    destroy .topDxc4Gui 
		exit
	}
	set running 0
	foreach chassis $reslist {
  	set id [lindex [split $chassis :] 1]
		if {[info exists vaDxc4Set(id$id,start)] && $vaDxc4Set(id$id,start)} {
  		set running 1
			break
		}
	}
	if {$running} {
	  RLDxc4::StopAllChassis
	  RLDxc4::Dxc4show_progdlg
		RLDxc4::Delay 2
		destroy .progress
    destroy .topDxc4Gui
 	  RLDxc4::CloseAll
		exit
	} else {
	    destroy .topDxc4Gui 
  	  RLDxc4::CloseAll
			exit
	}

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
#  Abstract: Create introduction GUI while building main Dxc4 GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc _create_intro { } {

  global gMessage
  variable vaDxc4Gui
  variable vaDxc4Set

  set top [toplevel .intro -relief raised -borderwidth 2]

  wm withdraw $top
  wm overrideredirect $top 1

  set ximg  [label $top.x -bitmap @$vaDxc4Set(rundir)/Images/x1.xbm \
    -foreground grey90 -background white]
  set bwimg [label $ximg.bw -bitmap @$vaDxc4Set(rundir)/Images/bwidget.xbm \
    -foreground grey90 -background white]
  set frame [frame $ximg.f -background white]
  set lab1  [label $frame.lab1 -text "Loading Dxc4 GUI" \
    -background white -font {times 8}]
  set lab2  [label $frame.lab2 -textvariable vaDxc4Set(prgtext) \
    -background white -font {times 8} -width 35]
  set prg   [ProgressBar $frame.prg -width 50 -height 10 -background white \
    -variable vaDxc4Set(prgindic) -maximum 10]
  pack $lab1 $lab2 $prg
  place $frame -x 0 -y 0 -anchor nw
  place $bwimg -relx 1 -rely 1 -anchor se
  pack $ximg
  BWidget::place $top 0 0 center
  wm deiconify $top
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


#end namespace
}
