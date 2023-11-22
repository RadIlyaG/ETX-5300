#***************************************************************************
#** Filename: RLExPio.tcl 
#** Written by Semion  13.6.2007  
#** 
#** Absrtact: This file operate with Pci PC card PIO, used functions
#**           in RLDExPio.dll
#** Inputs:
#**     The COMMANDs are:
#**       - RLExPio::Open      : Open port of specific group: PORT/SPDT/RBA ,return Id (list of port group card) of this port.
#**       - RLExPio::Close     : Close port of specific group: PORT/SPDT/RBA.
#**       - RLExPio::SetConfig : Configure PIO(in/out) of group: PORT.
#**       - RLExPio::GetConfig : Get Configure status PIO(in/out) of group: PORT.
#**       - RLExPio::Set       : Set port to binary value (e.g. 10101010).
#**       - RLExPio::Get       : Get from port of PORT group its binary status. 
#**       - RLExPio::GetBusy   : Return opened state of specific port or all ports. 
#**       - RLExPio::Reset     : Resets PIO Card. 
#**            
#** Examples:  
#**
#**     set id [RLExPio::Open 3 PORT 2]   ; #opens port 3 of ports group PORT card number 2(default 1)
#**     set id [RLExPio::Open 1 PORT]     ; #opens port 1 of ports group PORT card number 1(default)
#**     set id [RLExPio::Open 2 SPDT 2]   ; #opens port 2 of ports group SPDT card number 2(default 1)
#**     set id [RLExPio::Open 5 RBA]      ; #opens port 5 of ports group RBA card number 1(default)
#**     RLExPio::Reset                    ; #Resets PIO card(default 1). 
#**     RLExPio::Close $id                ; #closes port with id = $id 
#**     RLExPio::SetConfig $id in out     ; #configure high nibble of port with id=$id to in low nibble to out
#**     RLExPio::GetConfig $id state      ; #return nibbles configuration(IN/OUT) of port with id=$id by state variable
#**     RLExPio::Set $id 11110000         ; #set port with id=$id to 11110000 value
#**     RLExPio::Set $id 1                ; #set port with id=$id LSB bit to 1 value (e.g. for RBA or SPDT group)
#**     RLExPio::Get $id buff             ; #get from port with id=$id its value returned by buff variable
#**     RLExPio::GetBusy $id state        ; #get busy state of port with id=$id returned by state variable,
#**																					 if id == "all group card" procedure return busy state of all ports of this group
#***************************************************************************

package require RLEH 1.0
package require RLDExPio 1.65


  #**  1  .  RLDLLOpenExPio     port  group     [card]
  #**  2  .  RLDLLConfigExPio   id    hnibble   lnibble  [card]
  #**  3  .  RLDLLSetExPio      id    group     byte     [card]
  #**  4  .  RLDLLGetExPio      id    readByte  [card]
  #**  5  .  RLDLLGetStateExPio id    cfgState  [card]
  #**  6  .  RLDLLGetBusyExPio  group busyState [card]
  #**  7  .  RLDLLClosePio      id		group		  [card]
	#**  8  .  RLDLLResetExPio		[card]

package provide RLExPio 1.65

namespace eval RLExPio    { 

  namespace export Open Close SetConfig GetConfig Set Get GetBusy Reset
 
  global gMessage
  variable vPioCardsQty

#***************************************************************************
#**                        RLExPio::Open
#** 
#** Absrtact: Open procedure use RLDExPio dll to open port in PIO PC PCI card. 
#**
#** Inputs:     
#**           port     port number to open (1-30 for PORT group , 1-14 for RBA  group , 1-10 for SPDT group)
#**           group    1 - PORT , 2 - SPDT , 3 - RBA
#**           card     card number (default = 1)
#**
#**
#** Outputs:  id (list of portnumber groupnumber cardnumber)	if success
#**           negativ code and error message by RLEH          if error   
#**                                 
#** Example:                        
#**     set id [RLExPio::Open 3 PORT 2]   ; #opens port 3 of ports group PORT card number 2(default 1)
#**     set id [RLExPio::Open 1 PORT]     ; #opens port 1 of ports group PORT card number 1(default)
#**     set id [RLExPio::Open 2 SPDT] 2   ; #opens port 2 of ports group SPDT card number 2(default 1)
#**     set id [RLExPio::Open 5 RBA]      ; #opens port 5 of ports group RBA card number 1(default)
#***************************************************************************

proc Open { args }  {
 
  #global (import) from RLDExPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage
  variable vPioCardsQty

  set arrleng      [llength $args]
  set maxarg       3
  set minarg       2
	set portnumber   [lindex $args 0]
	set group        [string toupper [lindex $args 1]]
  set ok           0
  
  if {$portnumber == "?"} {
    return "arguments options:  First: port number , Second: group (PORT/SPDT/RBA) , Third: card number (default = 1)"
  }

  if { $arrleng > $maxarg|| $arrleng < $minarg }  {
    set gMessage "Open ExPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
	} elseif {$arrleng == $maxarg} {
			set cardnumber   [lindex $args 2]
	} else {
			set cardnumber   1
	}
     
  switch  $group {
    PORT  { set groupnumber 1 }
    SPDT  { set groupnumber 2 }
    RBA   { set groupnumber 3 }
    default {
      set gMessage "Open ExPio: Syntax error ,use: PORT/SPDT/RBA for group parameter."
      return [RLEH::Handle SAsyntax gMessage]
    }
	}
  set err [RLDLLOpenExPio $portnumber $groupnumber $cardnumber vPioCardsQty]
	if {$err == -33 && $vPioCardsQty == 0} {
	  #there is no PLX cards in PC
    set gMessage "There is no PLX cards in PC"
    append gMessage "\nERROR while open ExPio."
    RLEH::Handle Warning  gMessage
		return -33
	}	elseif {$err == -1} {
	  #There none PLX PIO Cards in this PC
    set gMessage $ERRMSG
    append gMessage "\nERROR while open ExPio."
    RLEH::Handle Warning  gMessage
		return -1
	}	elseif {$err == -2} {
	  #the card number > than there is ExPio cards in PC
    set gMessage "The card number wrong or over the quantity ($vPioCardsQty) of ExPio cards in PC"
    append gMessage "\nERROR while open ExPio."
    RLEH::Handle Warning  gMessage
		return -2
	}	elseif {$err <= 0} {
    set gMessage $ERRMSG
    append gMessage "\nERROR while open ExPio."
    return [RLEH::Handle SAsyntax gMessage]
  } else {
	    return "$portnumber $groupnumber $cardnumber"
	}
}  

#******************************************************************************
#**                        RLExPio::Close
#** 
#** Absrtact: Close procedure use RLDExPio dll to close Pio port. 
#**
#** Inputs:   idPio : The port ID returned by Open procedure. 
#**
#**
#** Outputs:  0                           	                  if success
#**           negativ code and error message by RLEH          if error   
#**                                 
#** Example:                        
#**                              
#**           RLExPio::Close $id
#*****************************************************************************

proc Close { args }  {

  # global (import) from RLDExPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set idpiolist [lindex $args 0]
  set numbargs     1
  set ok           0

  if {$idpiolist == "?"} {
    return "arguments options:  ID list in form: {port group card}"
  }

  # Checking number arguments
  if { $arrleng != $numbargs } {
    set gMessage "Close ExPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
    
    # Close pio                   
  } else {
      if {[set err [RLDLLCloseExPio [lindex $idpiolist 0] [lindex $idpiolist 1] [lindex $idpiolist 2]]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while Close ExPio."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}

#***************************************************************************
#**                        RLExPio::SetConfig
#** 
#** Absrtact: SetConfig procedure use RLDExPio dll to configure Pio port of PORT group. 
#**
#** Inputs:    
#**           idPio   : The port ID returned by Open procedure
#**           hnibble : IN/OUT configure out disable/enable high nibble
#**           lnibble : IN/OUT configure out disable/enable low nibble
#**
#**
#** Outputs:  0                           	                  if success
#**           negativ code and error message by RLEH          if error   
#**                                 
#**                                 
#** Example:                        
#**                              
#**           RLExPio::SetConfig $id out out
#**           RLExPio::SetConfig $id in out
#***************************************************************************

proc SetConfig { args } {
 
  # global (import) from RLDExPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set numbargs     3
  set idpiolist [lindex $args 0]
  set ok           0

  if {$idpiolist == "?"} {
    return "arguments options:  First: ID list in form: {port group card} , Second: high nibble config. (in/out) , Third: low nibble config. (in/out)"
  }
  # Checking number arguments
  if { $arrleng != $numbargs }  {
    set gMessage "SetConfig ExPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
    # config pio                   
  } else {
    	set hnibble [string tolower [lindex $args 1]]
      switch  $hnibble {
        in  { set configH 0 }
        out { set configH 1 }
        default {
          set gMessage "Config ExPio: Syntax error ,use: IN , OUT (config paramm.)"
          return [RLEH::Handle SAsyntax gMessage]
        }
      }
     	set lnibble [string tolower [lindex $args 2]]
      switch  $lnibble {
        in  { set configL 0 }
        out { set configL 1 }
        default {
          set gMessage "Config ExPio: Syntax error ,use: IN , OUT (config paramm.)"
          return [RLEH::Handle SAsyntax gMessage]
        }
      }
			if {[lindex $idpiolist 1] != 1} {
	      set gMessage "Config ExPio: Syntax error ,only ports from PORT group may be configured."
	      return [RLEH::Handle SAsyntax gMessage]
			}
      if {[set err [RLDLLConfigExPio [lindex $idpiolist 0] $configH $configL [lindex $idpiolist 2]]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while SetConfig ExPio."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}

#***************************************************************************
#**                        RLExPio::GetConfig
#** 
#** Absrtact: GetConfig procedure use RLDExPio dll to get how was configure Pio port of PORT group. 
#**
#** Inputs:    
#**           idPio   : The port ID returned by Open procedure
#**           state   : Variable where procedure return configuration state of high and low nibbles.
#**
#**
#** Outputs:  0  and configured value by state variable   if success
#**           negativ code and error message by RLEH      if error   
#**                                 
#**                                 
#** Example:                        
#**                              
#**           RLExPio::GetConfig $id state
#***************************************************************************

proc GetConfig { args } {
 
  # global (import) from RLDExPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set numbargs     2
  set idpiolist [lindex $args 0]
  set readstatus [ lindex $args 1]
  upvar $readstatus cfgStatus
	set state ""
	set cfgStatus ""
  set ok           0

  if {$idpiolist == "?"} {
    return "arguments options:  First: ID list in form: {port group card} , Second: variable where procedure return config value."
  }
  # Checking number arguments
  if { $arrleng != $numbargs }  {
    set gMessage "GetConfig ExPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
    #get config pio                   
  } else {
			if {[lindex $idpiolist 1] != 1} {
	      set gMessage "Get Config ExPio: Syntax error ,only ports from PORT group may be configured."
	      #return [RLEH::Handle SAsyntax gMessage]
				return -1
			}
      if {[set err [RLDLLGetStateExPio [lindex $idpiolist 0] state [lindex $idpiolist 2]]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while GetConfig ExPio."
        return [RLEH::Handle SAsyntax gMessage]
      }
    	set hnibble [string index $state 0]
      switch  $hnibble {
        0  { lappend  cfgStatus in }
        1 { lappend  cfgStatus out }
      }
    	set lnibble [string index $state 1]
      switch  $lnibble {
        0  { lappend  cfgStatus in }
        1 { lappend  cfgStatus out }
      }
      return $ok
  }
}

#***************************************************************************
#**                        RLExPio::Set
#** 
#** Absrtact: RLExPio::Set procedure use RLDExPio dll to Write to Pio port. 
#**
#** Inputs:   
#**           idPio   : The port ID returned by Open procedure
#**           byteCod : binary cod from 1 to 8 bit
#**
#** Outputs:  0                           	                  if success
#**           negativ code and error message by RLEH          if error   
#**                                 
#** Example:                        
#**                              
#**     RLExPio::Set $id 10101111
#**     RLExPio::Set $id 1                ; #set port with id=$id LSB bit to 1 value (e.g. for RBA or SPDT group)
#***************************************************************************

proc Set { args } {
 
  # global (import) from RLDExPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set numbargs     2
  set idpiolist [lindex $args 0]
	set value	  [lindex $args 1]
  set ok           0

  if {$idpiolist == "?"} {
    return "arguments options:  First: ID list in form: {port group card} , Second: bynary value to write to port(e.g. 10101010)."
  }
  # Checking number arguments
  if { $arrleng != $numbargs }  {
    set gMessage "Set ExPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
    # Write pio                   
  } else {
      if {[set err [RLDLLSetExPio [lindex $idpiolist 0] [lindex $idpiolist 1] $value [lindex $idpiolist 2]]]} {
        set gMessage $ERRMSG
        append gMessage "\nERROR while Set ExPio."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}

#*******************************************************************************
#**                        RLExPio::Get
#** 
#** Absrtact: Get procedure use RLDExPio dll to get the binary valuue of port from PORT group. 
#**
#** Inputs:    
#**           idPio   : The port ID returned by Open procedure
#**           state   : Variable where procedure return binary valuue of port.
#**
#**
#** Outputs:  0  and port value by state variable         if success
#**           negativ code and error message by RLEH      if error   
#**                                 
#**                                 
#** Example:                        
#**                              
#**           RLExPio::Get $id state
#******************************************************************************

proc Get { args } {
 
  # global (import) from RLDExPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set numbargs     2
  set idpiolist [lindex $args 0]
  set readstatus [ lindex $args 1]
  upvar $readstatus valStatus
	set valStatus ""
  set ok           0

  if {$idpiolist == "?"} {
    return "arguments options:  First: ID list in form: {port group card} , Second: variable where procedure return value."
  }
  # Checking number arguments
  if { $arrleng != $numbargs }  {
    set gMessage "Get ExPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
    #get pio                   
  } else {
			if {[lindex $idpiolist 1] != 1} {
	      set gMessage "Get ExPio: Syntax error ,only ports from PORT group may be for this procedure."
	      #return [RLEH::Handle SAsyntax gMessage]
				return -1
			}
      if {[set err [RLDLLGetExPio [lindex $idpiolist 0] valStatus [lindex $idpiolist 2]]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while Get ExPio."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}

#***************************************************************************
#**                        RLExPio::GetBusy
#** 
#** Absrtact: GetConfig procedure use RLDExPio dll to get busy statuses of PIO ports. 
#**
#** Inputs:    
#**           idPio   : The port ID returned by Open procedure or other list of {portnumber groupnamber card number}
#**           state   : Variable where procedure return busy state of PIO ports.
#**
#**
#** Outputs:  0  and busy status by state variable        if success
#**           negativ code and error message by RLEH      if error   
#**                                 
#**                                 
#** Example:                        
#**                              
#**           RLExPio::GetBusy $id state
#**           RLExPio::GetBusy "24 1 1" state ;#first arg from id list - port 24 , second arg 1 - group PORT , third arg 1 - card 1 
#***************************************************************************

proc GetBusy { args } {
 
  # global (import) from RLDExPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set numbargs     2
  set idpiolist [lindex $args 0]
  set readstatus [ lindex $args 1]
  upvar $readstatus busyStatus
	set state ""
	set busyStatus ""
  set ok           0

  if {$idpiolist == "?"} {
    return "arguments options:  First: ID list in form: {port group card} , Second: variable where procedure return value."
  }
  # Checking number arguments
  if { $arrleng != $numbargs }  {
    set gMessage "GetBusy ExPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
    #get config pio                   
  } else {
	    set group [lindex $idpiolist 1]
			set port  [lindex $idpiolist 0]
      if {[set err [RLDLLGetBusyExPio $group state [lindex $idpiolist 2]]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while GetBusy ExPio."
        return [RLEH::Handle SAsyntax gMessage]
      }
			if {![string match [string tolower $port] "all"]} {
				if {$group == 1 && ($port < 0 || $port > 30)} {
		      set gMessage "GetBusy ExPio: Syntax error ,port number missmatch with group PORT."
		      #return [RLEH::Handle SAsyntax gMessage]
					return -1
				} elseif {$group == 2 && ($port < 0 || $port > 10)} {
			      set gMessage "GetBusy ExPio: Syntax error ,port number missmatch with group SPDT."
			      #return [RLEH::Handle SAsyntax gMessage]
						return -1
				} elseif {$group == 3 && ($port < 0 || $port > 14)} {
			      set gMessage "GetBusy ExPio: Syntax error ,port number missmatch with group RBA."
			      #return [RLEH::Handle SAsyntax gMessage]
						return -1
				}
				#specific port busy status
				if {[string index $state [expr $port - 1]] == 1} {
				  set busyStatus busy
				} else {
				    set busyStatus free
				}
			} else {
			    #all ports busy status 
			    set busyStatus	$state
			}
      return $ok
  }
}

#***************************************************************************************
#**                        RLExPio::Reset
#** 
#** Absrtact: RLExPio::Reset procedure use RLDExPio dll to reset Pio card. 
#**
#** Inputs:   
#**           [card]   : The card number (default = 1)
#**
#** Outputs:  0                           	                  if success
#**           negativ code and error message by RLEH          if error   
#**                                 
#** Example:                        
#**                              
#**     RLExPio::Reset 2
#**     RLExPio::Reset                ; #reset card number 1
#**************************************************************************************

proc Reset { args } {
 
  # global (import) from RLDExPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set ok           0

  if {$args == "?"} {
    return "arguments options:  card number (if empty card number = 1)"
  }
  # Checking number arguments
  if { $arrleng == 0 }  {
    set cardnumber 1
	} else {
      set cardnumber [lindex $args 0]
	}
  if {[set err [RLDLLResetExPio $cardnumber ]]} {
    set gMessage $ERRMSG
    append gMessage "\nERROR while Reset ExPio."
    return [RLEH::Handle SAsyntax gMessage]
  }
  return $ok
}

# end name space
}                                  
