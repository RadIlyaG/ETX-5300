
#***************************************************************************
#** Filename: RLMux818.tcl 
#** Written by Semion  30.3.1999  
#** 
#** Absrtact: This file operate with Mux818, used Semion's functions in RLDMeght.dll
#**
#** Inputs:
#**  'DOS command line style of BTL',i.e :
#**     COMMAND FirstParameter SecondParameter [ThirdParameter]...
#**     The COMMANDs are:
#**           - RLMux818::Open  Open Mux818 ,return Id of Mux818 for following operation.
#**           - RLMux818::Close Close MUX818.
#**           - RLMux818::Set   Set any Conaction in Mux818.
#**           - RLMux818::Get   Get State of Conaction in Mux818.
#** Examples:  
#**
#** RLMux818::Open 3a [HIGH] ,RLMux818::Set id -mainH 1 -mainL 3 ,RLMux818::Get id resState
#***************************************************************************
  package require RLEH 1.0
  package require RLDMeght 2.0

  #**  1  .  RLDLLOpenMux818 type number [space]
  #**  2  .  RLDLLSetMux818 id subMain numbChann
  #**  3  .  RLDLLGetMux818 id resState
  #**  4  .  RLDLLCloseMux818 id 

  package provide RLMux818 2.0

namespace eval RLMux818    { 
     
  namespace export Open Close Set Get
 
  global gMessage
  set gMessage " "                   

#***************************************************************************
#**                        RLMux818::Open
#** 
#** Absrtact:
#**   Return ID of Mux818 that may work with PIO(1a-8c) 
#**
#**   Inputs:  instrNumber  [space] 
#**  
#**            instrNumber: 1a-8c
#**            space     : LOW, HIGH
#** Outputs: 
#**   id of mux818 if success else error message by RLEH 
#**                              
#** Example:                        
#**     RLMux818::Open 3a ;RLMux818::Open 6c LOW; 
#***************************************************************************

proc Open { args } {

  # global (import) from RLGmic.dll
  global ERRMSG

  #global (export) for  close all opened Gmic
  global gaArrCloseCommand
  global gIndex
  #Message to be send to EH 
  global gMessage
 
 
  set arrleng      [llength $args]
  set maxarg       2
  set minarg       1
  set idMux818    ""
  
  # Checking number arguments
  if { $arrleng > $maxarg|| $arrleng < $minarg } {
    set gMessage "Open Mux818:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  }

  # Check space parammeter                   
  if {$arrleng==2}  {
    switch -- [ lindex $args 1 ] {
      LOW  { set space  1 }
      HIGH { set space  2 }
      default {
        set gMessage "Open Mux818: Syntex error ,use: LOW,HIGH(space paramm.)"
        return [RLEH::Handle SAsyntax gMessage]
      }
    }
  } else  {
      set space  2
  }
  
  # Open MUX818
  set instrNumber  [lindex $args 0]
  if {[set err [RLDLLOpenMux818 $instrNumber idMux818 $space]]}  {
    set gMessage $ERRMSG
    append gMessage "\nERROR while open Mux818."
    return [RLEH::Handle SAsystem gMessage]
  }

  return $idMux818
  
}

#***************************************************************************
#**                        RLMux818::Set
#** 
#** Absrtact: Set parammeters of MUX818 to any value
#**   
#**   Inputs:  id     1-48
#**
#**            args   parameters for MUX818 setup and their value
#**  
#**            -mainH : 1-8.
#**            -mainL : 1-8.
#**   Outputs: 
#**           return  0                    if success 
#**           error message by RLEH        if error                  
#** Example:                        
#**         RLMux818::Set id -mainH 2 -mainL 3 .
#**                              
#***************************************************************************

proc Set { args } {

  # global (import) from RLGmic.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set ok           0

  if { $arrleng !=5 } {
    set gMessage "Set Mux818:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  } 

  if { "[ lindex $args 1 ]" == "[ lindex $args 3 ]"}  {
    set gMessage "Set Mux818: Syntax error: Args\[1\] = to Args\[3\] "
    return [RLEH::Handle SAsyntax gMessage]
  }
  set idMux818 [ lindex $args 0 ]
  #remove id and set command line to variable lCommandLine
  set lCommandLine [ lrange $args 1 end ] 

  foreach {param val}   $lCommandLine   {
   
    if { $param=="-mainH"}  {
      set ctrlH $val
    } elseif {$param=="-mainL"}  {
        set ctrlL $val
    } else {
        set gMessage "Set Mux818: Wrong name of $param"
        return [RLEH::Handle SAsyntax gMessage]
    }
  }  
  if {[set err [ RLDLLSetMux818 $idMux818 $ctrlH $ctrlL ]]}   {
    set gMessage $ERRMSG
    append gMessage "\nERROR while SetMux818."
    return [RLEH::Handle SAsystem gMessage]
  }
  return $ok
}
          
#***************************************************************************
#**                        RLMux818::Get
#** 
#** Absrtact: Get array of parammeters of MUX818 and return to tcl 
#**   
#**   Inputs:  id     1-48
#**
#**  
#**   Outputs: 
#**           return  array                if success 
#**           error message by RLEH        if error                  
#** Example:                        
#**         RLMux818::Get id .
#**                              
#***************************************************************************

proc Get { args } {

  # global (import) from RLGmic.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set numbargs      [llength $args]
  

  if {$numbargs !=1 } {
    set gMessage "Get Mux818:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  } 

   set idMux818 [ lindex $args 0 ]
  
   if {[set err [ RLDLLGetMux818 $idMux818 agetResult]]}   {
     set gMessage $ERRMSG
     append gMessage "\nERROR while GetMux818."
     return [RLEH::Handle SAsystem gMessage]
   }
   return [array get agetResult]
}


#***************************************************************************
#**                        RLMux818::Close
#** 
#** Absrtact: RLMux818::Close procedure use Rlmux818 dll to close Pio port. 
#**
#** Inputs:   idMux818  
#**           idMux818 : 1-48
#**
#**
#** Outputs:  0                        if ok
#**           err msg by RLEH          if fail   
#**                                 
#** Example:                        
#**                              
#**           RLMux818::Close $id
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
    set gMessage "Close Mux818:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
    # Close MUX818                   
  } else {
      set idMux818 [ lindex $args 0 ]
      if {[set err [RLDLLCloseMux818 $idMux818]]}   {
        set gMessage $ERRMSG
        append gMessage "\nERROR while CloseMux818."
        return [RLEH::Handle SAsystem gMessage]
      }
      return $ok
  }
}
#end name space
}


