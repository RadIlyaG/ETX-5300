
#***************************************************************************
#** Filename: Rlpio.tcl 
#** Written by Semion  30.3.1999  
#** 
#** Absrtact: This file operate with pio, used Alex's functions
#**           in RlDPio.dll
#** Inputs:
#**     The COMMANDs are:
#**       - RLPio::Config : Open and config(in,out) Pio ,return Id of Pio
#**                         If Pio was opened then config only Pio.
#**       - RLPio::Close  : Close Pio if Id was got during Open Pio.
#**       - RLPio::Set    : Send to opened pio ByteCod.
#**       - RLPio::Get    : Get from opened pio ByteCod end status(in,out). 
#**            
#** Examples:  
#**
#**     RLPio::Config 3a IN [1] ; RLPio::Config $id OUT ; RLPio::Get $id readcod status ;
#**     RLPio::Set $id 10101111 ; RLPio::Close $id .
#***************************************************************************

package require RLEH 1.0
package require RLDPio 2.0


  #**  1  .  RLDLLOpenPio      (1a-8c)  space
  #**  2  .  RLDLLConfigPio     id      state
  #**  3  .  RLDLLOutPio        id      byte  
  #**  4  .  RLDLLInPio         id      readByte 
  #**  5  .  RLDLLGetStatePio   id      readState
  #**  6  .  RLDLLClosePio      id

package provide RLPio 2.0

namespace eval RLPio    { 

  namespace export Config Close Set Get
 
  global gMessage
  global  gIndex

  set gMessage " "                   
  

#***************************************************************************
#**                        RLPioConfig
#** 
#** Absrtact: RLPioConfig procedure use RLPio dll to Open or Config Pio. 
#**
#**           **************** Case Open and Config ******************
#** Inputs:   port config [space]  
#**                                 
#**           port     1a - 8c
#**           config   IN , OUT
#**           space    LOW, HIGH
#**
#**           **************** Case Config only  *********************
#** Inputs:   id   config   
#**                                 
#**           id       1 -  48
#**           config   IN , OUT
#**
#** Outputs:  id (in case open and config), 0 (in case config)
#**           error message by RLEH          if error   
#**                                 
#** Example:                        
#**           RLPio::Config  3  IN         (config in)           
#**           RLPio::Config  2b OUT LOW    (open and config out with space)
#**           RLPio::Config  3a IN         (open and config in without space(default-HIGH))
#***************************************************************************

proc Config { args }  {
 
  # global (import) from RLGmic.dll
  global ERRMSG
  #global (export) for  close all opened Gmic
  global gaArrCloseCommand
  global gIndex
  #Message to be send to EH 
  global gMessage
 
  set arrleng      [llength $args]
  set maxarg       3
  set minarg       2
  set rescatch     0
  set ok           0
  
  if { $arrleng > $maxarg|| $arrleng < $minarg }  {
    set gMessage "Config Pio:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
     
    # Check config parammeter                   
  } else {
           switch -- [ lindex $args 1 ] {
             IN  { set config 0 }
             OUT { set config 1 }
             default {
               set gMessage "Config Pio: Syntex error ,use: IN , OUT (config paramm.)"
               return [RLEH::Handle SAsyntax gMessage]
             }
           }
           set port [ lindex $args 0 ]
           
           #Check if first paramm Id or number pio
           if {[ catch {expr int($port)} rescatch]}  {   
             # Case open and config
             if { $arrleng == $maxarg }  {
               switch -- [ lindex $args 2 ] {
                 LOW  { set space 1 }
                 HIGH { set space 2 }
                 default {
                   set gMessage "Config Pio: Syntex error ,use: LOW , HIGH (space paramm.)"
                   return [RLEH::Handle SAsyntax gMessage]
                 }
               }
             } else {
                 set space 2
             }    
             if {[set err [RLDLLOpenPio $port $space]] <= 0}  {
               set gMessage $ERRMSG
               append gMessage "\nERROR while open Pio."
               return [RLEH::Handle SAsyntax gMessage]
             } 
           
             set idpio $err
             #Config after open
             if {[set err [RLDLLConfigPio $idpio $config]]}  {
               set gMessage $ERRMSG
               append gMessage "\nERROR while Config Pio."
               return [RLEH::Handle SAsyntax gMessage]
             }
             return $idpio  
          
           } else { 
               # Case config only
               if { [set err [RLDLLConfigPio $port $config]]}  {
                 set gMessage $ERRMSG
                 append gMessage "\nERROR while Config Pio."
                 return [RLEH::Handle SAsyntax gMessage]
               } 
               return $ok
           }
  }
}  


#***************************************************************************
#**                        RLPio::Close
#** 
#** Absrtact: RLPio::Close procedure use RLPio dll to close Pio port. 
#**
#** Inputs:   idPio  
#**           idPio : 1-48
#**
#**
#** Outputs:  0  ok
#**           Error message by RLEH   
#**                                 
#** Example:                        
#**                              
#**           RLPio::Close $id
#***************************************************************************

proc Close { args }  {

  # global (import) from RLGmic.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set numbargs     1
  set ok           0

  # Checking number arguments
  if { $arrleng != $numbargs } {
    set gMessage "Close Pio:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
    
    # Close pio                   
  } else {
      set idpio [ lindex $args 0 ]
      if {[set err [RLDLLClosePio $idpio]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while Close Pio."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}

#***************************************************************************
#**                        RLPio::Set
#** 
#** Absrtact: RLPio::Set procedure use RLPio dll to Write to Pio port. 
#**
#** Inputs:   idPio byteCod
#** 
#**           idPio  : 1-48
#**           byteCod: binary cod from 1 to 8 bit
#**
#** Outputs:  0  ok
#**           error message by RLEH  if fail   
#**                                 
#** Example:                        
#**                              
#**           RLPio::Set $id 10101111
#***************************************************************************

proc Set { args } {
 
  # global (import) from RLGmic.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set numbargs     2
  set ok           0

  # Checking number arguments
  if { $arrleng != $numbargs }  {
    set gMessage "Set Pio:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
    # Write pio                   
  } else {
      set idpio [ lindex $args 0 ]
      if {[set err [RLDLLOutPio $idpio [lindex $args 1 ]]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while Set Pio."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}

#***************************************************************************
#**                        RLPio::Get
#** 
#** Absrtact: RLPio::Get procedure use RLPio dll to Read Pio port: status and ByteCod. 
#**
#** Inputs:   idPio  readstatus
#** 
#**           idPio    : 1-48
#**           readstatus: variable for status(IN ,OUT) from pio
#** Outputs:  cod binary             if  ok
#**           Error message by RLEH  if fail   
#**                                 
#** Example:                        
#**                              
#**           RLPio::Get $id readstatus
#***************************************************************************

proc Get { args }  {
 
  # global (import) from RLGmic.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set numbargs     2
  set readcod      ""
   
  # Checking number arguments
  if { $arrleng != $numbargs }  {
    set gMessage "Get Pio:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
    # Read pio                   
  } else {
      set idpio [ lindex $args 0 ]
      if {[set err [RLDLLInPio $idpio readcod]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while Get Pio."
        return [RLEH::Handle SAsyntax gMessage]
      } else {
          # Read State pio
          set readstatus [ lindex $args 1]
          upvar $readstatus valStatus
          set valStatus ""
          if {[set err [RLDLLGetStatePio $idpio valStatus]]}  {
            set gMessage $ERRMSG
            append gMessage "\nERROR while Get Pio."
            return [RLEH::Handle SAsyntax gMessage]
          }
                    
          # If got status=1(OUT)
          if { $valStatus}  {
            set valStatus OUT 
          } else {
              set valStatus IN
          }
      }      
      return $readcod
  }
}
# end name space
}                                 
