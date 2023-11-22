
#***************************************************************************
#** Filename: RLExMx818.tcl 
#** Written by Semion  22.10.2007  
#** 
#** Absrtact: This file operate with Mux818, used RLExPio package
#**
#** Inputs:
#**  'DOS command line style of BTL',i.e :
#**     COMMAND FirstParameter SecondParameter [ThirdParameter]...
#**     The COMMANDs are:
#**           - RLExMux818::Open  Open Mux818 ,return Id of Mux818 for following operation.
#**           - RLExMux818::Close Close MUX818.
#**           - RLExMux818::Set   Set any Connection in Mux818.
#**           - RLExMux818::Get   Get State of Connection in Mux818.
#** Examples:  
#**
#** set id [RLExMux818::Open 3 2 ]
#** RLExMux818::Set $id -mainH 1 -mainL 3 
#** RLExMux818::Get $id resState
#***************************************************************************
  package require RLEH 
  package require RLExPio


  package provide RLExMux818 1.0

namespace eval RLExMux818    { 
     
  namespace export Open Close Set Get
 
  global gMessage
  set gMessage " "                   
  variable glchanCod 
 	set  glchanCod			"0	111 011 101 001 110 010 100 000"

#***************************************************************************
#**                        RLExMux818::Open
#** 
#** Absrtact:
#**   Return ID of Mux818 that may work with PIO port (ID consists of port number, ports group and card number) 
#**
#**   Inputs:  portNumber  [card] 
#**  
#**            portNumber: 1-30
#**            card     : 1-15 , default 1
#** Outputs: 
#**   id of mux818 if success else error message by RLEH 
#**                              
#** Example:                        
#**     set id [RLExMux818::Open 13]
#**     set id [RLExMux818::Open 6 2] 
#***************************************************************************

proc Open { args } {

  global ERRMSG

  global gIndex
  #Message to be send to EH 
  global gMessage
 
 
  set arrleng      [llength $args]
  set maxarg       2
  set minarg       1
  set idMux818    ""
  
  # Checking number arguments
  if { $arrleng > $maxarg|| $arrleng < $minarg } {
    set gMessage "Open ExMux818:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  }

  # Check space parammeter                   
  if {$arrleng==2}  {
	  set card [lindex $args 1]
  } else  {
      set card  1
  }
  
  # Open ExMUX818
  set portNumber  [lindex $args 0]
  if {[set idMux818 [RLExPio::Open $portNumber PORT $card]] <= 0}  {
    set gMessage $ERRMSG
    append gMessage "\nERROR while open ExMux818."
    return [RLEH::Handle SAsystem gMessage]
  }
	#Config Pio to OUT 
  if {[RLExPio::SetConfig $idMux818 out out]}  {
    set gMessage $ERRMSG
    append gMessage "\nERROR while open ExMux818."
    return [RLEH::Handle SAsystem gMessage]
  }
  return $idMux818
}

#***************************************************************************
#**                        RLExMux818::Set
#** 
#** Absrtact: Set parammeters of MUX818 to any value
#**   
#**   Inputs:  id     consist of port number ,ports group and card number
#**
#**            args   parameters for ExMUX818 setup and their value
#**  
#**            -mainH : 1-8.
#**            -mainL : 1-8.
#**   Outputs: 
#**           return  0                    if success 
#**           error message by RLEH        if error                  
#** Example:                        
#**         RLExMux818::Set id -mainH 2 -mainL 3 .
#**                              
#***************************************************************************

proc Set { args } {

  global ERRMSG
  #Message to be send to EH 
  global gMessage
	variable glchanCod 

  set arrleng      [llength $args]
  set ok           0

  if { $arrleng !=5 } {
    set gMessage "Set ExMux818:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  } 

  if { "[ lindex $args 1 ]" == "[ lindex $args 3 ]"}  {
    set gMessage "Set ExMux818: Syntax error: Args\[1\] = to Args\[3\] "
    return [RLEH::Handle SAsyntax gMessage]
  }
  set idMux818 [ lindex $args 0 ]
  #remove id and set command line to variable lCommandLine
  set lCommandLine [ lrange $args 1 end ] 

  foreach {param val}   $lCommandLine   {
   
		if {$val < 1 || $val > 8} {
      set gMessage "Set ExMux818: Wrong value $val of $param must be 1 - 8"
      return [RLEH::Handle SAsyntax gMessage]
		}
    if { $param=="-mainH"}  {
      set ctrlH [lindex $glchanCod $val]
    } elseif {$param=="-mainL"}  {
        set ctrlL [lindex $glchanCod $val]
    } else {
        set gMessage "Set ExMux818: Wrong name of $param"
        return [RLEH::Handle SAsyntax gMessage]
    }
  }  
  if {[RLExPio::Set $idMux818 $ctrlL$ctrlH]} {
    set gMessage $ERRMSG
    append gMessage "\nERROR while Set ExMux818."
    return [RLEH::Handle SAsystem gMessage]
  }
  return $ok
}
          
#***************************************************************************
#**                        RLExMux818::Get
#** 
#** Absrtact: Get array of parammeters of MUX818 and return to tcl 
#**   
#**   Inputs:  id     consist of port number ,ports group and card number.
#**
#**  
#**   Outputs: 
#**           return  array                if success 
#**           error message by RLEH        if error                  
#** Example:                        
#**         RLExMux818::Get id .
#**                              
#***************************************************************************

proc Get { args } {

  global ERRMSG
  #Message to be send to EH 
  global gMessage
  variable glchanCod 

  set numbargs      [llength $args]
  

  if {$numbargs !=1 } {
    set gMessage "Get ExMux818:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  } 

  set idMux818 [ lindex $args 0 ]

 	RLExPio::Get $idMux818	currChann
	set aStateEmux(mainH) 	[lsearch $glchanCod	[string range $currChann 5 end]]
	set aStateEmux(mainL) 	[lsearch $glchanCod	[string range $currChann 2 4]]

  return [array get aStateEmux]
}


#***************************************************************************
#**                        RLExMux818::Close
#** 
#** Absrtact: RLExMux818::Close procedure uses RLExPio dll to close Pio port. 
#**
#** Inputs:   idMux818  
#**           idMux818 : consist of port number ,ports group and card number.
#**
#**
#** Outputs:  0                        if ok
#**           err msg by RLEH          if fail   
#**                                 
#** Example:                        
#**                              
#**           RLExMux818::Close $id
#***************************************************************************

proc Close { args } {

  # global (import) from RLGmic.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage


  set arrleng      [llength $args]
  set numbargs     1
  set ok           0
 
  if { $arrleng != $numbargs } {
    set gMessage "Close ExMux818:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
    # Close ExMUX818                   
  } else {
      set idMux818 [ lindex $args 0 ]
      if {[RLExPio::Close $idMux818]}   {
        set gMessage $ERRMSG
        append gMessage "\nERROR while Close ExMux818."
        return [RLEH::Handle SAsystem gMessage]
      }
      return $ok
  }
}
#end name space
}


