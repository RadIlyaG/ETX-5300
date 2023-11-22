
#***************************************************************************
#** Filename: RLExMx2514.tcl 
#** Written by Semion  22.10.2007  
#** 
#** Absrtact: This file operate with Mux2514 uses RLExPio package
#**
#** Inputs:
#**  'DOS command line style of BTL',i.e :
#**     COMMAND FirstParameter SecondParameter [ThirdParameter]...
#**     The COMMANDs are:
#**           - RLExMux2514::Open  Open Mux2514 ,return Id of Mux2514 for following operation.
#**           - RLExMux2514::Close Close MUX2514.
#**           - RLExMux2514::Set   Set any Connection in Mux2514.
#**           - RLExMux2514::Get   Get State of Connection in Mux2514.
#** Examples:  
#**
#** set id [RLExMux2514::Open 3 3]
#** RLExMux2514::Set $id -mainH 1 -mainL 3 -chann2 0
#** RLExMux2514::Get $id 
#***************************************************************************
  package require RLEH 1.0
  package require RLExPio


  package provide RLExMux2514 1.0


namespace eval RLExMux2514    { 
     
  namespace export Open Close Set Get
 
  global gMessage
  set gMessage " "                   


#***************************************************************************
#**                        RLExMux2514::Open
#** 
#** Absrtact:
#**   Return ID of Mux2514 that may work with PCI-PIO port. 
#**
#**   Inputs:  type  portNumber  [card] 
#**  
#**            portNumber: 1-30
#**            card     : 1-15
#** Outputs: 
#**   id of mux2514 if success else error message by RLEH
#**                              
#** Example:                        
#**  RLExMux2514::Open 7 2 
#**  RLExMux2514::Open 6
#***************************************************************************

proc Open { args } {

  # global (import) from RLGmic.dll
  global ERRMSG

  global gIndex
  #Message to be send to EH 
  global gMessage
 
  set arrleng      [llength $args]
  set portNumber  [lindex $args 0]
  set maxarg       2
  set minarg       1
  set idMux2514    ""
  
  # Checking number arguments
  if { $arrleng > $maxarg|| $arrleng < $minarg } {
    set gMessage "Open ExMux2514:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  }

  # Check space parammeter                   
  if {$arrleng==2}  {
    set card [lindex $args 1]
	} else {
			set card 1
	}
  if {[set idMux2514 [RLExPio::Open $portNumber PORT $card]] <= 0}  {
    set gMessage $ERRMSG
    append gMessage "\nERROR while open ExMux2514."
    return [RLEH::Handle SAsystem gMessage]
  }
	#Config Pio to OUT 
  if {[RLExPio::SetConfig $idMux2514 out out]}  {
    set gMessage $ERRMSG
    append gMessage "\nERROR while open ExMux2514."
    return [RLEH::Handle SAsystem gMessage]
  }
  return $idMux2514
}

          
#***************************************************************************
#**                        RLExMux2514::Set
#** 
#** Absrtact: Set parammeters of MUX2514 to any value
#**   
#**   Inputs:  ip_IdMux2514     consist of port number ,ports group and card number
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
#**         RLExMux2514::Set id -mainH 2 -mainL 3 -chann1  OFF -chann4 ON .
#**                              
#***************************************************************************

proc Set { args } {

  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set maxarg       13
  set minarg       3
  set ok           0
  

  if { $arrleng > $maxarg || $arrleng < $minarg } {
    set gMessage "Set ExMux2514:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  } 

	set mainH xx
	set mainL xx
	set chann1 x
	set chann2 x
	set chann3 x
	set chann4 x
  set idMux2514 [ lindex $args 0 ]
  #remove id and set command line to variable lCommandLine
  set lCommandLine [ lrange $args 1 end ] 

  foreach {param val}   $lCommandLine   {
   
    switch -exact -- $param  {
    	-mainL -
      -mainH {
			        switch -exact -- $val {
								1 {
			            	set [string trimleft $param -] 11
								}
								2 {
			            	set [string trimleft $param -] 01
								}
								3 {
			            	set [string trimleft $param -] 10
								}
								4 {
			            	set [string trimleft $param -] 00
								}
					      default {
					                set gMessage "Set ExMux2514:  Wrong value $val must be 1 - 4"
					                return [RLEH::Handle SAsyntax gMessage]
					      }
							}
      }

      -chann1 -
      -chann2 -
      -chann3 -
      -chann4 {

               if {[string compare -nocase $val OFF]==0} {
                  set [string trimleft $param -]  0  
               } elseif  {[string compare -nocase $val ON]==0} {
                  set [string trimleft $param -]  1
               } else  {
                   set gMessage "Set ExMux2514: Wrong value of parameter $param"
                   return [RLEH::Handle SAsyntax gMessage]
               }
      }
      
      default {
                set gMessage "Set ExMux2514:  Wrong name of parameter $param"
                return [RLEH::Handle SAsyntax gMessage]
      }
    
    }
  }
  if {[RLExPio::Set $idMux2514 $mainL$mainH$chann4$chann3$chann2$chann1]} {
    set gMessage $ERRMSG
    append gMessage "\nERROR while Set ExMux2514."
    return [RLEH::Handle SAsystem gMessage]
  }
  return $ok
}

#***************************************************************************
#**                        RLExMux2514::Get
#** 
#** Absrtact: Get array of parammeters of MUX2514 and set to console as list 
#**   
#**   Inputs:  ip_IdMux2514     consist of port number ,ports group and card number
#**
#**  
#**   Outputs: 
#**           return  array                 if success 
#**           return  error message by RLEH if error                  
#** Example:                        
#**         RLExMux2514::Get id .
#**                              
#***************************************************************************

proc Get { args } {

  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set numbargs      [llength $args]
  
  if {$numbargs !=1 }  {
    set gMessage "Get ExMux2514:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
  } 
   
  set idMux2514 [ lindex $args 0 ]
	RLExPio::Get $idMux2514	currChann

  set agetResult(mainL) [string range $currChann 0 1]
  set agetResult(mainH) [string range $currChann 2 3]
	foreach chann {1 2 3 4} {
	  set agetResult(chann$chann) [string index $currChann [expr {8 - $chann}]]
	}
  foreach { param val } [array get agetResult] {
    
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

    	mainL -
      mainH {
			        switch -exact -- $val {
								11 {
			            	set agetResult($param) 1
								}
								01 {
			            	set agetResult($param) 2
								}
								10 {
			            	set agetResult($param) 3
								}
								00 {
			            	set agetResult($param) 4
								}
							}
			}
    }
  }
 
    return [array get agetResult]
}


#***************************************************************************
#**                        RLExMux2514::Close
#** 
#** Absrtact: RLExMux2514::Close procedure uses RLExPio dll to close Pio port. 
#**
#** Inputs:   idMux2514  
#**           idMux2514 : consist of port number ,ports group and card number.
#**
#**
#** Outputs:  0                   ok
#**           error msg by RLEH  if fail   
#**                                 
#** Example:                        
#**                              
#**           RLExMux2514::Close $id
#***************************************************************************

proc Close { args } {

  global ERRMSG
  #Message to be send to EH 
  global gMessage

  set arrleng      [llength $args]
  set numbargs     1
  set ok           0
 
  if { $arrleng != $numbargs }  {
    set gMessage "Close ExMux2514:  Wrong number of parameters"
    return [RLEH::Handle SAsyntax gMessage]
    # Close MUX2514                   
  } else {
      set idMux2514 [ lindex $args 0 ]
        if {[RLExPio::Close $idMux2514]}   {
        set gMessage $ERRMSG
        append gMessage "\nERROR while Close ExMux2514."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}
#end namespace
}


