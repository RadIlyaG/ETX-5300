
#***************************************************************************
#** Filename: RL2514.tcl 
#** Written by Semion  30.3.1999  
#** 
#** Absrtact: This file operate with Mux2514, used Semion's functions  RldMfour.dll
#**
#** Inputs:
#**  'DOS command line style of BTL',i.e :
#**     COMMAND FirstParameter SecondParameter [ThirdParameter]...
#**     The COMMANDs are:
#**           - RLMux2514::Open  Open Mux2514 ,return Id of Mux2514 for following operation.
#**           - RLMux2514::Close Close MUX2514.
#**           - RLMux2514::Set   Set any Connection in Mux2514.
#**           - RLMux2514::Get   Get State of Connection in Mux2514.
#** Examples:  
#**
#** RLMux2514::Open pio 3a [HIGH];RLMux2514::Set id -mainH 1 -mainL 3 -chann2 0;RLMux2514::Get id 
#***************************************************************************
  package require RLEH 1.0
  package require RLDMfour 2.0

  #**  1  .  RLDLLOpenMux2514 type number idrefer [space]
  #**  2  .  RLDLLSetMainMux2514  id subMain numbChann
  #**  3  .  RLDLLSetChannelMux2514 id numbChann value
  #**  4  .  RLDLLGetMux2514 id 
  #**  5  .  RLDLLCloseMux2514 id 

  package provide RLMux2514 2.0


namespace eval RLMux2514    { 
     
  namespace export Open Close Set Get
 
  global gMessage
  set gMessage " "                   


#***************************************************************************
#**                        RLMux2514::Open
#** 
#** Absrtact:
#**   Return ID of Mux2514 that may work with PIO(1a-8c),GPIB(dev addr 1-15) 
#**
#**   Inputs:  type  instrNumber  [space] 
#**  
#**            type      : pio,gpib
#**            instrNumber: 1a-8c(for pio), 1-15(for gpib)
#**            space     : LOW, HIGH
#** Outputs: 
#**   id of mux2514 if success else error message by RLEH
#**                              
#** Example:                        
#**     RLMux2514::Open pio 3a ;RLMux2514::Open pio 6c LOW; RLMux2514::Open gpib 4;
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
  set typeMux2514     [lindex $args 0]
  set instrNumber  [lindex $args 1]
  set maxarg       3
  set minarg       2
  set idMux2514    ""
  
  # Checking number arguments
  if { $arrleng > $maxarg|| $arrleng < $minarg } {
    set gMessage "Open Mux2514:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  }

  # Check space parammeter                   
  if {$arrleng==3}  {
    switch -- [ lindex $args 2 ] {
      LOW  { set space  1 }
      HIGH { set space  2 }
      default {
        set gMessage "Open Mux2514: Syntex error ,use: LOW,HIGH(space paramm.)"
        return [RLEH::Handle SAsyntax gMessage]
      }
    }
    # Open MUX2514_Open Pio with paramm. space
    if {[set err [RLDLLOpenMux2514 $typeMux2514 $instrNumber idMux2514 $space ]]}  {
      set gMessage $ERRMSG
      append gMessage "\nERROR while open Mux2514."
      return [RLEH::Handle SAsystem gMessage]
    }
  
  } else {
      #Open MUX2514 Pio without paramm. space or gpib
      if {[set err [RLDLLOpenMux2514 $typeMux2514 $instrNumber idMux2514]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while open Mux2514."
        return [RLEH::Handle SAsystem gMessage]
      }

  }
           
  return $idMux2514
  
}

          
#***************************************************************************
#**                        RLMux2514::Set
#** 
#** Absrtact: Set parammeters of MUX2514 to any value
#**   
#**   Inputs:  ip_IdMux2514     1-48(for pio) 49-64(for gpib)
#**
#**            args   parameters for MUX2514 setup and their value
#**  
#**            -mainH : 1-4.
#**            -mainL : 1-4.
#**            -chann1: OFF;ON.
#**            -chann2: OFF;ON.
#**            -chann3: OFF;ON.
#**            -chann4: OFF;ON.
#**   Outputs: 
#**           return  0                     if success 
#**           return  error message by RLEH if error                  
#** Example:                        
#**         RLMux2514::Set id -mainH 2 -mainL 3 -chann1  OFF -chann4 ON .
#**                              
#***************************************************************************

proc Set { args } {

  # global (import) from RLGmic.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set maxarg       13
  set minarg       3
  set ok           0
  

  if { $arrleng > $maxarg || $arrleng < $minarg } {
    set gMessage "Set Mux2514:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  } 

  set idMux2514 [ lindex $args 0 ]
  #remove id and set command line to variable lCommandLine
  set lCommandLine [ lrange $args 1 end ] 

  foreach {param val}   $lCommandLine   {
   
    switch -exact -- $param  {
    
      -mainH {
              if {[set err [ RLDLLSetMainMux2514 $idMux2514 1 $val]]}   {
                set gMessage $ERRMSG
                append gMessage "\nERROR while SetMux2514 mainH."
                return [RLEH::Handle SAsyntax gMessage]
              }
      }

      -mainL {
              if {[set err [ RLDLLSetMainMux2514 $idMux2514 2 $val]]}   {
                set gMessage $ERRMSG
                append gMessage "\nERROR while SetMux2514 mainL."
                return [RLEH::Handle SAsyntax gMessage]
              }
          
      }

      -chann1 -
      -chann2 -
      -chann3 -
      -chann4 {
               if {[string compare $param -chann1]==0} {
                 set numbChann  1
               } elseif {[ string compare $param -chann2]==0} {
                   set numbChann  2
                 } elseif {[ string compare $param -chann3]==0} {
                     set numbChann 3
                   } elseif {[ string compare $param -chann4]==0} {
                       set numbChann 4
                     }  
                       
               if {[string compare $val OFF]==0} {
                  set idVal  0  
               } elseif  {[string compare $val ON]==0} {
                  set idVal  1
                 } else  {
                     set gMessage "Set Mux2514: Wrong value of parameter -chann"
                     return [RLEH::Handle SAsyntax gMessage]
                   }
               if {[set err [ RLDLLSetChannelMux2514 $idMux2514 $numbChann $idVal]]}   {
                 set gMessage $ERRMSG
                 append gMessage "\nERROR while SetMux2514."
                 return [RLEH::Handle SAsyntax gMessage]
               }
      }
      
      default {
                set gMessage "Set Mux2514:  Wrong name of parameter $param"
                return [RLEH::Handle SAsyntax gMessage]
      }
    
    }
  }
  return $ok
}

#***************************************************************************
#**                        RLMux2514::Get
#** 
#** Absrtact: Get array of parammeters of MUX2514 and set to console as list 
#**   
#**   Inputs:  ip_IdMux2514     1-48(for pio) 49-64(for gpib)
#**
#**  
#**   Outputs: 
#**           return  array                 if success 
#**           return  error message by RLEH if error                  
#** Example:                        
#**         RLMux2514::Get id .
#**                              
#***************************************************************************

proc Get { args } {

  # global (import) from RLGmic.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set numbargs      [llength $args]
  
  if {$numbargs !=1 }  {
    set gMessage "Get Mux2514:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  } 
   
  set idMux2514 [ lindex $args 0 ]
  if {[set err [ RLDLLGetMux2514 $idMux2514 agetResult]]}   {
    set gMessage $ERRMSG
    append gMessage "\nERROR while GetMux2514."
    return [RLEH::Handle SAsyntax gMessage]
  }
  
  foreach { param val } [array get agetResult]   {
    
    switch -exact -- $param  {
  
      chann1 -
      chann2 -
      chann3 -
      chann4  {
        if { $val==0 }  {
          set agetResult($param) OFF
        } else  {
            set agetResult($param) ON
        }  
      }
    }
  } 
    return [array get agetResult]
}


#***************************************************************************
#**                        RLMux2514::Close
#** 
#** Absrtact: RLMux2514::Close procedure use Rl2514 dll to close Pio port. 
#**
#** Inputs:   idMux2514  
#**           idMux2514 : 1-64
#**
#**
#** Outputs:  0                   ok
#**           error msg by RLEH  if fail   
#**                                 
#** Example:                        
#**                              
#**           RLMux2514::Close $id
#***************************************************************************

proc Close { args } {

  # global (import) from RLGmic.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set numbargs     1
  set ok           0
 
  if { $arrleng != $numbargs }  {
    set gMessage "Close Mux2514:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
    # Close MUX2514                   
  } else {
      set idMux2514 [ lindex $args 0 ]
      if {[set err [RLDLLCloseMux2514 $idMux2514]]}   {
        set gMessage $ERRMSG
        append gMessage "\nERROR while Close Mux2514."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}
#end namespace
}


