#***************************************************************************
#** Filename: RLExEMux.tcl 
#** Written by Semion  21.10.2007 
#** 
#** Absrtact: This file operate with EMux by  PciPio PC card
#**
#** Inputs:
#**  'DOS command line style of BTL',i.e :
#**     COMMAND FirstParameter SecondParameter [ThirdParameter]...
#**     The COMMANDs are:
#**           - RLExEMux::Open           Open EMux(Group of EMux) for following operation.
#**           - RLExEMux::Close          Close EMux.
#**           - RLExEMux::Set            Set any connection in EMux.
#**						- RLExEMux::Increment			 Increment connection the Main channel to following channel.
#**						- RLExEMux::Disconnect	   Disconnect EMux.
#**						- RLExEMux::Connect				 Connect the last state of channels that was disconnected before.
#**           - RLExEMux::GetState       Get State of Connection in EMux.
#**
#**           - RLExEMux::OpenSingle        Open only single EMux for following operation.
#**           - RLExEMux::CloseSingle       Close only single EMux.
#**           - RLExEMux::SetSingle         Set any connection in single EMux.
#**						- RLExEMux::IncrementSingle	  Increment connection the Main channel to following channel.
#**						- RLExEMux::DisconnectSingle	Disconnect single EMux.
#**						- RLExEMux::ConnectSingle		  Connect the last state of channels that was disconnect before.
#**           - RLExEMux::GetStateSingle    Get State of Connection in single EMux.
#** Examples:  
#**	  RLExEMux::Open 1  4 -hwCheck no	 
#**	  RLExEMux::Open 2	8	-mainH 5 -card 3
#**   RLExEMux::Open 10	6 -mainH 3 -hwCheck yes 
#**	  RLExEMux::Close IDmux
#**	  RLExEMux::Set IDmux -mainH 4 -mainL 7
#**	  RLExEMux::Set IDmux -mainH 34 -mainL 35
#**	  RLExEMux::Set IDmux -mainH 14 -mainL 27		NO VALID !!! the split Main channel must be in same EMux.
#**	  RLExEMux::Set IDmux -main 63
#**	  RLExEMux::Set IDmux -main 2	-muxE 3
#**	  RLExEMux::Increment	IDmux
#**		RLExEMux::Disconnect	IDmux
#**		RLExEMux::Connect		IDmux
#**		RLExEMux::GetState	IDmux		
#**
#**	  RLExEMux::OpenSingle           30 	 
#**	  RLExEMux::OpenSingle           22 
#**	  RLExEMux::CloseSingle          IDmux
#**	  RLExEMux::SetSingle            IDmux -mainH 4 -mainL 7
#**	  RLExEMux::SetSingle            IDmux -main 5
#**	  RLExEMux::SetSingle            IDmux -mainH 1
#**	  RLExEMux::SetSingle            IDmux -mainL 3
#**	  RLMux::IncremSingle	         IDmux
#**	  RLExEMux::DisconnectSingle	   IDmux
#**	  RLExEMux::ConnectSingle		     IDmux
#**	  RLExEMux::GetStateSingle	     IDmux		
#***************************************************************************
  package require RLEH 1.0
  package require RLExPio 1.0
  package require RLTime
  package provide RLExEMux 1.0

namespace eval RLExEMux    { 
     
  namespace export Open Close Set Increment Disconnect Connect GetState \
									 OpenSingle CloseSingle SetSingle IncrementSingle DisconnectSingle ConnectSingle GetStateSingle
  global gMessage
  variable gaEmuxPresentStatus  
	variable glPio
  variable gFalse 
  variable gTrue 
  variable glExtendMux 
  variable glEmuxCod 
  variable glchanCod 
  set gMessage " "                   
  set gTrue 0
  set gFalse -1


  set  glExtendMux "0 11111110 11111100 11111000 11110000 11100000 11000000 10000000 00000000"
		set  glchanCod			"0	000 100 010 110 001 101 011 111"
		set  glEmuxCod 		"0 000 001 010 011 100 101 110 111"


#***************************************************************************
#**                        RLExEMux::Open
#** 
#** Absrtact:
#**   Open EMux by library RLExPio. 
#**
#**   Inputs:  ip_portsGroup   		       :	1 - 10 all group consists of three ports
#**  					 ip_numbEmuxs				       : number of Emuxs 1-8
#**            [par. for Set	]		       : parameters for set any conection during open mux
#**   Outputs: 
#**            IDmux                         if success 
#**            error message by RLEH 				 otherwise
#**                              
#** Example:                        
#**	 set IDemux1  [RLExEMux::Open 3 1 -card 2]		 ; opens Emux by pio ports: 7,8,9 of card 2
#**	 set IDemux2  [RLExEMux::Open 7	8 -main 7 -muxE 3]	 ; opens 8 Emuxs by pio ports: 19,20,21 and connect main of mux 3 to channel  7.
#**	 set IDemux3  [RLExEMux::Open 1	8 -mainH 5 -hwCheck yes] opens 8 Emuxs by pio ports: 1,2,3 , connect main of mux 1 to channel 5	 and checks that all 8 muxes exists. 
#***************************************************************************

proc Open { args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 
  variable glExtendMux 

	set card   1
	set arrleng      [llength $args]
  set maxarg       12
  set minarg       2
	set numbEmux		 [lindex $args 1]
	set pioGroup		 [lindex $args 0]
	set hwCheck  "yes"

  #check for rigth syntax of "Pio group"
  if {[SyntaxCheck PIONUMBER $pioGroup] != $gTrue} {
     return [RLEH::Handle SAsyntax gMessage]
  } 

  #check for rigth syntax of "quantity of extended Emux"    
  if {[SyntaxCheck EXTMUXNUMB $numbEmux] != $gTrue} {
     return [RLEH::Handle SAsyntax gMessage]
  } 

		#check	for quantity of parameters in 'Openemux' function
  if {$arrleng < $minarg|| $arrleng > $maxarg} {
    set gMessage "Error in quantity of parameters in 'OpenEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
	}					

  if {[set ind [lsearch $args "-hwCheck"]] != -1} {
		set hwCheck [lindex $args [expr $ind + 1]]
	}
	
  if {[set ind [lsearch $args "-card"]] != -1} {
		set card [lindex $args [expr $ind + 1]]
	}
	#check that this Emux was not opened before
	set emuxID "$pioGroup $card"
  if {[info exists gaEmuxPresentStatus($emuxID,mainID)]} {
    set gMessage "EMux $emuxID already open"
    return [RLEH::Handle SAsyntax gMessage]
  }
	
	#set members of global array of opened emux.
	set gaEmuxPresentStatus($emuxID,mainID)	$emuxID
	set gaEmuxPresentStatus($emuxID,numbEmux)	$numbEmux
	#open  first , second and third pio of ports group for this Emux
	set first [expr ($pioGroup * 3) - 2]
	set second [expr $first + 1]
	set third [expr $first + 2]
	foreach {port conf}  [list $first OUT $second OUT $third IN] {
		if {[catch {RLExPio::Open $port PORT $card } gaEmuxPresentStatus($emuxID,id$port)]} {
		  unset gaEmuxPresentStatus($emuxID,id$port)
			RLExEMux::Close $emuxID             
	    return [RLEH::Handle SAsyntax gMessage]
		}
		RLExPio::SetConfig $gaEmuxPresentStatus($emuxID,id$port) $conf $conf
	}

	RLTime::Delayms 250
	#check order of extended Emuxes
	if {[string match -nocase $hwCheck "yes"]} {
	  RLExPio::Get	$gaEmuxPresentStatus($emuxID,id$third)	map
		if {[set expmap [lindex $glExtendMux $numbEmux]] != $map } {
	    set gMessage "Mismatch of addreses extended Emuxes : exists (0) and not exists (1) \		
				              \n\n          MSBIT - Emux 8 ; LSBIT - Emux 1   :  $map \
																	  \n           expected for Emuxes = $numbEmux               :  $expmap"
		  RLExEMux::Close $emuxID             
	    return [RLEH::Handle SAsyntax gMessage]
		}
	}

	if {[regexp {main|mux} $args]} {
	  #open with connection
		RLExEMux::Set $emuxID	[lindex $args 2]	[lindex $args 3] [lindex $args 4] [lindex $args 5] [lindex $args 6]\
			                    [lindex $args 7] [lindex $args 8]	[lindex $args 9] [lindex $args 10]	 [lindex $args 11]	
	} else {
	    #open without connection
			RLExPio::Set	$gaEmuxPresentStatus($emuxID,id$second) 1xxxxxxx
	}
	return $emuxID
}

#***************************************************************************
#**                        RLExEMux::Close
#** 
#** Absrtact:
#**   Close EMux by library RLExPio::Close. 
#**
#**   Inputs:  ip_emuxID		       :	consists of port group and card
#**  										
#**   Outputs: 
#**            0                                    if success 
#**            error message by RLEH 								otherwise
#**                              
#** Example:                        
#**	  RLExEMux::Close 	ip_emuxID
#***************************************************************************

proc Close {args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 

	set arrleng    [llength $args]
	set emuxID		 [lindex $args 0]

		#check	for quantity of parameters in 'CloseEmux' function
  if {$arrleng != 1} {
    set gMessage "Error in quantity of parameters in 'CloseEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
		}					

		#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,mainID)]} {
    set gMessage "EMux $emuxID has not been opened before"
    return [RLEH::Handle SAsyntax gMessage]
  }
	
  if {![info exists gaEmuxPresentStatus($emuxID,numbEmux)]} {
    set gMessage "This EMux with ID: $emuxID has been opened with OpenSingle procedure\n and must must use CloseSingle procedure."
    return [RLEH::Handle SAsyntax gMessage]
  }

	#close  first , second and third pio of ports group for this Emux
	set pioGroup [lindex $emuxID 0]
	set first [expr ($pioGroup * 3) - 2]
	set second [expr $first + 1]
	set third [expr $first + 2]
	foreach {port}  [list gaEmuxPresentStatus($emuxID,id$first)	gaEmuxPresentStatus($emuxID,id$second) gaEmuxPresentStatus($emuxID,id$third)] {
		if {[info exists $port]} {
			 RLExPio::Close [set $port]
			 unset	$port
		}
	}
	unset	gaEmuxPresentStatus($emuxID,mainID)
	unset gaEmuxPresentStatus($emuxID,numbEmux)	

	return $gTrue
}
 

#***************************************************************************
#**                        RLExEMux::Set
#** 
#** Absrtact:
#**   Set any connection in EMux by library RLExPio::Set. 
#**
#**   Inputs:  ip_emuxID		          :	       Returned by Open procedure
#**            [ip_main]		 [val]		:								-main			1-64
#**  					 [ip_mainH] 	 [val]		:								-mainH		1-64
#**  					 [ip_mainL]		 [val]		:								-mainL		1-64
#**  					 [ip_numbMux]	 [val]		:								-muxE			1-8
#**  										
#**   Outputs: 
#**            0                             if success 
#**            error message by RLEH 					otherwise
#**                              
#** Example:                        
#**	1.  RLExEMux::Set	ip_emuxID	-main 53
#** 2.   !!!! error       RLExEMux::Set	ip_emuxID	-main 23 -muxE 2    no valid                      
#** 3.  RLExEMux::Set	ip_emuxID	-main 3 -muxE 6                         
#** 4.  RLExEMux::Set	ip_emuxID	-mainH 43                           
#** 5.  RLExEMux::Set	ip_emuxID	-maiL 8 -muxE 5                           
#** 6.  RLExEMux::Set	ip_emuxID	-mainH 3 -mainL 7 -muxE 2                          
#**                              
#***************************************************************************

proc Set {args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 
  variable glchanCod 
  variable glEmuxCod 
  variable glExtendMux 

	set arrleng    [llength $args]
	#puts "arrlen = $arrleng args = $args "
  set maxarg       9
  set minarg       3
	set emuxID					[lindex $args 0]
	set pioGroup [lindex $emuxID 0]
	set first [expr ($pioGroup * 3) - 2]
	set second [expr $first + 1]
	set third [expr $first + 2]


	#check	for quantity of parameters in 'Setemux' function
  if {$arrleng < $minarg|| $arrleng > $maxarg} {
    set gMessage "Error in quantity of parameters in 'SetEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
	}					

				#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,mainID)]} {
    set gMessage "EMux $emuxID has not been opened before"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {![info exists gaEmuxPresentStatus($emuxID,numbEmux)]} {
    set gMessage "This EMux with ID: $emuxID has been opened with OpenSingle procedure\n and must use SetSingle procedure."
    return [RLEH::Handle SAsyntax gMessage]
  }

	set lCommandLine [ lrange $args 1 end ] 
	set ctrlwordH xxx
	set ctrlwordL xxx

	foreach {param val}   $lCommandLine   {
   
    switch -exact -- $param  {
    
      -main {

             if {[SyntaxCheck NUMBCHANN $val 64] != $gTrue} {
               return [RLEH::Handle SAsyntax gMessage]
             } 
						 if {[info exists	flagEmux]	&& $val >	8} {
               set gMessage "Set Emux main:  mismatch between number channel and parameter -muxE val"
               return [RLEH::Handle SAsyntax gMessage]
						 }
      			 set abschannelH $val
      			 set abschannelL $val
						 if ![info exists	flagEmux]	{
						   set expEmuxL [set expEmuxH [expr ($val -1) /	8 +1]]
						 }
						 if {$expEmuxH > $gaEmuxPresentStatus($emuxID,numbEmux)} {
               set gMessage "Set Emux main:  mismatch between number channel and quantity Emuxes"
               return [RLEH::Handle SAsyntax gMessage]
						 }	else {
							    set tempchann		[expr $val	% 8]
									if {$tempchann == 0} {
									  set tempchann 8
									}
									set channelH [set channelL $tempchann]
									set	ctrlwordH	[set ctrlwordL	[lindex $glchanCod $channelH]]
						 }
			}

      -mainH {

              if {[SyntaxCheck NUMBCHANN $val 64] != $gTrue} {
                return [RLEH::Handle SAsyntax gMessage]
              } 
							if {[info exists	flagEmux]	&& $val >	8} {
                set gMessage "Set Emux mainH:  mismatch between number channel and parameter -muxE val"
                return [RLEH::Handle SAsyntax gMessage]
							}
      				set abschannelH $val
							if ![info exists	flagEmux]	{
  							set expEmuxH [expr ($val -1) /	8 +1]
							}
						  if {$expEmuxH > $gaEmuxPresentStatus($emuxID,numbEmux)} {
                set gMessage "Set Emux mainH:  mismatch between number channel and quantity Emuxes"
                return [RLEH::Handle SAsyntax gMessage]
							}	else {
							    set tempchann		[expr $val	% 8]
									if {$tempchann == 0} {
									  set tempchann 8
									}
									set channelH $tempchann
									set ctrlwordH	[lindex $glchanCod $channelH]
							}
      }

      -mainL {

             if {[SyntaxCheck NUMBCHANN $val 64] != $gTrue} {
               return [RLEH::Handle SAsyntax gMessage]
             } 
						 if {[info exists	flagEmux]	&& $val >	8} {
               set gMessage "Set Emux mainL:  mismatch between number channel and parameter -muxE val"
               return [RLEH::Handle SAsyntax gMessage]
						 }
      			 set abschannelL $val
						 if ![info exists	flagEmux]	{
  					  	set expEmuxL [expr ($val -1) /	8 +1]
						 }
						 if {$expEmuxL > $gaEmuxPresentStatus($emuxID,numbEmux)} {
               set gMessage "Set Emux mainL:  mismatch between number channel and quantity Emuxes"
               return [RLEH::Handle SAsyntax gMessage]
						 }	else {
							    set tempchann		[expr $val	% 8]
									if {$tempchann == 0} {
									  set tempchann 8
									}
									set channelL $tempchann
									set ctrlwordL	[lindex $glchanCod $channelL]
						 }
      }

      -muxE {

             if {[SyntaxCheck EXTMUXNUMB $val ] != $gTrue} {
               return [RLEH::Handle SAsyntax gMessage]
             } 

						 if {$val > $gaEmuxPresentStatus($emuxID,numbEmux)} {
               set gMessage "Set Emux: The extended Emux $val does not exist"
               return [RLEH::Handle SAsyntax gMessage]
						 }
      			 	
						 if { [info exists	abschannelL]} {
							 if {	$abschannelL	>8} {
                 set gMessage "Set Emux: mismatch between number channel and number extended Emux"
                 return [RLEH::Handle SAsyntax gMessage]
						   }
						 }
						 if { [info exists	abschannelH]} {
							 if {	$abschannelH	>8} {
                 set gMessage "Set Emux: mismatch between number channel and number extended Emux"
                 return [RLEH::Handle SAsyntax gMessage]
						   }
						 }
						 set expEmuxH	[set expEmuxL	$val]
						 set flagEmux 1
      }

    
		  {}       {
								#empty
			}

      default {
                set gMessage "Set EMux:  Wrong name of parameter $param"
                return [RLEH::Handle SAsyntax gMessage]
      }
    }
	}
	if {[info exists expEmuxH] && [info exists expEmuxL]	} {
	  if {	$expEmuxH != $expEmuxL} {
      set gMessage "Set Emux: Connection for -mainH and -mainL must be in same EMux"
      return [RLEH::Handle SAsyntax gMessage]
	  }
	}

	if [info exists expEmuxH]	{
	  set ctrlEmux [lindex $glEmuxCod $expEmuxH]
	} else {
  	  set ctrlEmux [lindex $glEmuxCod $expEmuxL]
	}
	#disconnect all Emuxes 
  #RLExPio::Set	$gaEmuxPresentStatus($emuxID,idb) 1xxxxxxx
  #RLTime::Delayms 250
	#set new connaction
	RLExPio::Set	$gaEmuxPresentStatus($emuxID,id$first) $ctrlwordL$ctrlwordH
	RLExPio::Set	$gaEmuxPresentStatus($emuxID,id$second) 0xxxx$ctrlEmux
	return $gTrue
}


#***************************************************************************
#**                        RLExEMux::Increment
#** 
#** Absrtact:
#**   Set connection in EMux by increment to input parameters or to current state. 
#**
#**   Inputs:  ip_emuxID		         :	       Returned by Open procedure
#**  										
#**   Outputs: 
#**            0                              if success 
#**						 -1                             if over last mux and channel
#**            error message by RLEH 					otherwise
#**                              
#** Example:                        
#**	1.  RLExEMux::Increment	ip_emuxID	
#**                              
#***************************************************************************

proc Increment {args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 
  variable glchanCod 
  variable glEmuxCod 
  variable glExtendMux 

	set arrleng      [llength $args]
  set maxarg       2
  set minarg       1
	set emuxID			 [lindex $args 0]

	set pioGroup [lindex $emuxID 0]
	set first [expr ($pioGroup * 3) - 2]
	set second [expr $first + 1]
	set third [expr $first + 2]

	#check	for quantity of parameters in 'IncremEmux' function
  if {$arrleng < $minarg || $arrleng > $maxarg} {
    set gMessage "Error in quantity of parameters in 'IncremEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
	}					

	if {	$arrleng == 1} {
	  set incrVal 1
	} else {
  	  set incrVal [lindex $args 1]
	}
	#check increment value
	if {[SyntaxCheck INCREMVAL $incrVal ] != $gTrue} {
    return [RLEH::Handle SAsyntax gMessage]
  } 

	#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,mainID)]} {
    set gMessage "EMux $emuxID has not been opened before"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {![info exists gaEmuxPresentStatus($emuxID,numbEmux)]} {
    set gMessage "This EMux with ID: $emuxID has been opened with OpenSingle procedure\n and must use IncrementSingle procedure."
    return [RLEH::Handle SAsyntax gMessage]
  }
	RLExPio::Get $gaEmuxPresentStatus($emuxID,id$first)	res1
  set currChann [lsearch $glchanCod	[string range $res1 2 4]]
	RLExPio::Get $gaEmuxPresentStatus($emuxID,id$second)	res2
  set currEmux [lsearch $glEmuxCod	[string range $res2 5 end]]

  set updateChann	[expr	($currChann + $incrVal)	+ (8 *	($currEmux	-1))]


  if {$updateChann <1 ||	$updateChann > [expr	$gaEmuxPresentStatus($emuxID,numbEmux)*8]} {
  	return $gFalse
	}	else {
		  RLExEMux::Set	$emuxID	-main $updateChann
      #puts "chann= $currChann ,Emux=$currEmux "
	}
  return $gTrue
}


#***************************************************************************
#**                        RLExEMux::Disconnect
#** 
#** Absrtact:
#**   Disconnection all date through the EMux . 
#**
#**   Inputs:  ip_emuxID		         :	       Returned by Open procedure
#**  										
#**   Outputs: 
#**            0                             if success 
#**            error message by RLEH 				 otherwise
#**                              
#** Example:                        
#**	  RLExEMux::Disconnect	ip_emuxID	
#**                              
#***************************************************************************

proc Disconnect {args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 
  variable glchanCod 
  variable glEmuxCod 
  variable glExtendMux 

	set arrleng    [llength $args]
	set emuxID		 [lindex $args 0]
	set pioGroup   [lindex $emuxID 0]
	set second     [expr ($pioGroup * 3) - 1]

	#check	for quantity of parameters in 'DisconnectEmux' function
  if {$arrleng != 1} {
    set gMessage "Error in quantity of parameters in 'DisconnectEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
	}					

	#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,mainID)]} {
    set gMessage "EMux $emuxID has not been opened before"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {![info exists gaEmuxPresentStatus($emuxID,numbEmux)]} {
    set gMessage "This EMux with ID: $emuxID has been opened with OpenSingle procedure\n and must use DisconnectSingle procedure."
    return [RLEH::Handle SAsyntax gMessage]
  }

	RLExPio::Set	$gaEmuxPresentStatus($emuxID,id$second) 1xxxxxxx

	return $gTrue
}


#***************************************************************************
#**                        RLExEMux::Connect
#** 
#** Absrtact:
#**   Connect current state that was before command disconnecte EMux . 
#**
#**   Inputs:  ip_emuxID		         :	       Returned by Open procedure
#**  										
#**   Outputs: 
#**            0                             if success 
#**            error message by RLEH 				 otherwise
#**                              
#** Example:                        
#**	  RLExEMux::Connect	ip_emuxID	
#**                              
#***************************************************************************

proc Connect {args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 
  variable glchanCod 
  variable glEmuxCod 
  variable glExtendMux 

	set arrleng    [llength $args]
	set emuxID		 [lindex $args 0]
 	set pioGroup   [lindex $emuxID 0]
	set second     [expr ($pioGroup * 3) - 1]

	#check	for quantity of parameters in 'ConnectEmux' function
  if {$arrleng != 1} {
    set gMessage "Error in quantity of parameters in 'ConnectEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
	}					

	#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,mainID)]} {
    set gMessage "EMux $emuxID has not been opened before"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {![info exists gaEmuxPresentStatus($emuxID,numbEmux)]} {
    set gMessage "This EMux with ID: $emuxID has been opened with OpenSingle procedure\n and must use ConnectSingle procedure."
    return [RLEH::Handle SAsyntax gMessage]
  }

	RLExPio::Set	$gaEmuxPresentStatus($emuxID,id$second) 0xxxxxxx

		return $gTrue
}


#***************************************************************************
#**                        RLExEMux::GetState
#** 
#** Absrtact:
#**   Get state of connection in EMux by library RLExPio::Get. 
#**
#**   Inputs:  ip_emuxID		         :	       Returned by Open procedure
#**  										
#**   Outputs: 
#**            list states of connection     if success 
#**            error message by RLEH 				 otherwise
#**                              
#** Example:                        
#**	  RLExEMux::GetState	ip_emuxID
#**                              
#****************************************************************************

proc GetState {args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 
  variable glchanCod 
  variable glEmuxCod 
  variable glExtendMux 

	set arrleng    [llength $args]
	set emuxID		 [lindex $args 0]
	set pioGroup   [lindex $emuxID 0]
	set first      [expr ($pioGroup * 3) - 2]
	set second     [expr $first + 1]
	set third      [expr $first + 2]

	#check	for quantity of parameters in 'GetStateEmux' function
  if {$arrleng != 1} {
    set gMessage "Error in quantity of parameters in 'GetStateEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
	}					

	#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,mainID)]} {
    set gMessage "EMux $emuxID has not been opened before"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {![info exists gaEmuxPresentStatus($emuxID,numbEmux)]} {
    set gMessage "This EMux with ID: $emuxID has been opened with OpenSingle procedure\n and must use GetStateSingle procedure."
    return [RLEH::Handle SAsyntax gMessage]
  }

 	RLExPio::Get $gaEmuxPresentStatus($emuxID,id$first)	currChann
	set aStateEmux(mainH) 	[lsearch $glchanCod	[string range $currChann 5 end]]
	set aStateEmux(mainL) 	[lsearch $glchanCod	[string range $currChann 2 4]]

	RLExPio::Get $gaEmuxPresentStatus($emuxID,id$second)	currEmux
	set aStateEmux(muxE) 	[lsearch $glEmuxCod		[string range $currEmux 5 end]]
	set connection			[string index $currEmux 0]
	#puts $currEmux
	#puts	$connection
	if {$connection == 0} {
	  set	aStateEmux(connection) YES
	} else {
	 	  set	aStateEmux(connection) NO
	}
  return [array get aStateEmux]
}


#***************************************************************************
#**                        RLExEMux::OpenSingle
#** 
#** Absrtact:
#**   OpenSingle EMux by library RLExPio. 
#**
#**   Inputs:  ip_port   		       :	1-30
#**            [ip_card]					 :	1-15
#**            
#**   Outputs: 
#**            IDmux                         if success 
#**            error message by RLEH 				 otherwise
#**                              
#** Example:                        
#**	1. set IDemux1  [RLExEMux::OpenSingle 13]
#**	2. set IDemux2  [RLExEMux::OpenSingle 2 2]	 
#**	3. set IDemux3  [RLExEMux::OpenSingle 3 1]	 
#***************************************************************************

proc OpenSingle { args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 
  variable glExtendMux 

	set arrleng      [llength $args]
  set maxarg       2
  set minarg       1
  set portNumber	 [ lindex $args 0]

  #check for rigth syntax of "Port Number"
  if {$portNumber < 1 || $portNumber > 30} {
  	 set gMessage "   You must provide the Right \"Port Number\" parameter   \
                      \n\n   It must be from 1 to 30 but got $portNumber"
     return [RLEH::Handle SAsyntax gMessage]
  } 
  if {$arrleng == 1} {
    set card	1
  } elseif {$arrleng == 2} {
     set card	[ lindex $args 1]
	} else {
      set gMessage "Error in quantity of parameters in 'OpenSingleEmux' function"
      return [RLEH::Handle SAsyntax gMessage]
	}
		
  #check that this Emux was not opened before
  set emuxID "$portNumber $card"
  if {[info exists gaEmuxPresentStatus($emuxID,singleID)]} {
    set gMessage "Single EMux $emuxID already open"
    return [RLEH::Handle SAsyntax gMessage]
  }
	
  #open port for this Emux
  set gaEmuxPresentStatus($emuxID,idport) [RLExPio::Open $portNumber PORT $card ] 
  #set members of global array of opened emux.
  set gaEmuxPresentStatus($emuxID,singleID)	$emuxID
  
	RLExPio::SetConfig $gaEmuxPresentStatus($emuxID,idport) out out
  RLTime::Delayms 250
  
  RLExPio::Set $gaEmuxPresentStatus($emuxID,idport) 1xxxxxxx
  
  return $emuxID
}

#****************************************************************************
#**                        RLExEMux::CloseSingle
#** 
#** Absrtact:
#**   CloseSingle EMux by library RLExPio::Close. 
#**
#**   Inputs:  ip_emuxID		       :	Returned by Open procedure
#**  										
#**   Outputs: 
#**            0                             if success 
#**            error message by RLEH 				 otherwise
#**                              
#** Example:                        
#**	  RLExEMux::CloseSingle 	ip_emuxID
#****************************************************************************

proc CloseSingle {args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 

	set arrleng    [llength $args]
	set emuxID		 [lindex $args 0]

	#check	for quantity of parameters in 'CloseEmux' function
  if {$arrleng != 1} {
    set gMessage "Error in quantity of parameters in 'CloseSingleEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
  }					

	#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,singleID)]} {
    set gMessage "Single EMux $emuxID has not been opened before"
    return [RLEH::Handle SAsyntax gMessage]
  }

  #close port for this Emux
  RLExPio::Close $gaEmuxPresentStatus($emuxID,idport)
  unset	gaEmuxPresentStatus($emuxID,idport)
  unset	gaEmuxPresentStatus($emuxID,singleID)

  return $gTrue
}


#***************************************************************************
#**                        RLExEMux::SetSingle
#** 
#** Absrtact:
#**   SetSingle any connection into single EMux by library RLExPio::Set. 
#**
#**   Inputs:  ip_emuxID		            :	       Returned by Open procedure
#**            [ip_main]			 [val]		:					-main		  1-8
#**  					 [ip_mainH] 	   [val]		:   			-mainH		1-8
#**  					 [ip_mainL]			 [val]		:	        -mainL		1-8
#**  										
#**   Outputs: 
#**            0                        if success 
#**            error message by RLEH 	otherwise
#**                              
#** Example:                        
#**	1.  RLExEMux::SetSingle	ip_emuxID	-main 5
#** 2.  RLExEMux::SetSingle	ip_emuxID	-mainH 4                           
#** 3.  RLExEMux::SetSingle	ip_emuxID	-mainL 8                           
#** 4.  RLExEMux::SetSingle	ip_emuxID	-mainH 3 -mainL 7                      
#**                              
#***************************************************************************

proc SetSingle {args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 
  variable glchanCod 
  variable glEmuxCod 
  variable glExtendMux 

  set arrleng    [llength $args]
			   
  set maxarg       5
  set minarg       3
  set emuxID	   [lindex $args 0]

		#check	for quantity of parameters in 'Setemux' function
  if {$arrleng < $minarg || $arrleng > $maxarg} {
    set gMessage "Error in quantity of parameters in 'SetSingleEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
  }					

	#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,singleID)]} {
    set gMessage "Single EMux $emuxID has not been opened"
    return [RLEH::Handle SAsyntax gMessage]
  }


  set lCommandLine [ lrange $args 1 end ] 

  set ctrlwordH xxx
  set ctrlwordL xxx
  set abschannelL 0
  set abschannelH 0

  foreach {param val}   $lCommandLine   {
   
  	switch -exact -- $param  {
    	-main {
            if {[string match {[1-8]} $val] != 1} {
				      set gMessage "You must provide the Right \"Number channel EMuxs\" parameter   \
                          \n\n   It must be from 1 to 8"
            	return [RLEH::Handle SAsyntax gMessage]
            } 
			      set abschannelH $val
      		  set abschannelL $val
		  }

      -mainH { 
             if {[string match {[1-8]} $val] != 1} {
				       set gMessage "You must provide the Right \"Number channel EMuxs\" parameter   \
                          \n\n   It must be from 1 to 8"
            	 return [RLEH::Handle SAsyntax gMessage]
             } 
			       set abschannelH $val
      }
 
      -mainL {

             if {[string match {[1-8]} $val] != 1} {
				       set gMessage "You must provide the Right \"Number channel EMuxs\" parameter   \
                          \n\n   It must be from 1 to 8"
            	 return [RLEH::Handle SAsyntax gMessage]
             } 
			       set abschannelL $val
      }  
      default {
                set gMessage "Set Single EMux:  Wrong name of parameter $param"
                return [RLEH::Handle SAsyntax gMessage]
      }
    
  	}
  }

  if {$abschannelL != 0} {
  	set ctrlwordL [lindex $glchanCod $abschannelL]
  }
  if {$abschannelH != 0} {
  	set ctrlwordH [lindex $glchanCod $abschannelH]
  }
  #set new connaction
  RLExPio::Set $gaEmuxPresentStatus($emuxID,idport) $ctrlwordL$ctrlwordH
  RLExEMux::ConnectSingle $gaEmuxPresentStatus($emuxID,singleID)
  return $gTrue
}

#***************************************************************************
#**                        RLExEMux::IncrementSingle
#** 
#** Absrtact:
#**   Set connection in EMux by increment to input parameters or to current state. 
#**
#**   Inputs:  ip_emuxID		   :	       Returned by Open procedure
#**  		       [ip_incVal]		 :         1,2,...6,7,-1,-2....-6,-7  ; number of steps to incr the EMux								
#**  										
#**   Outputs: 
#**            0                    	if success 
#**            error message by RLEH 	otherwise
#**                              
#** Example:                        
#**	1.  RLExEMux::IncrementSingle $ip_emuxID	
#**                              
#***************************************************************************

proc IncrementSingle {args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 
  variable glchanCod 
  variable glEmuxCod 
  variable glExtendMux 

  set arrleng    [llength $args]
  set maxarg     2
  set minarg     1
  set emuxID	   [lindex $args 0]

		#check	for quantity of parameters in 'IncremEmux' function
  if {$arrleng < $minarg || $arrleng > $maxarg} {
    set gMessage "Error in quantity of parameters in 'IncremSingleEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
  }					

  if {$arrleng == 1} {
  	set incrVal 1
  } else {
    set incrVal [expr [lindex $args 1]%8]
  }
  if {$incrVal == 0 } {
  	return $gTrue
  }

  #check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,singleID)]} {
    set gMessage "Single EMux $emuxID has not been opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

	RLExPio::Get $gaEmuxPresentStatus($emuxID,idport)	res1
  set currChannL [lsearch $glchanCod	[string range $res1  2 4]]
	RLExPio::Get $gaEmuxPresentStatus($emuxID,idport)	res2
  set currChannH [lsearch $glchanCod	[string range $res2  5 7]]

  set updateChannH	[expr ($currChannH + $incrVal)%8]
  set updateChannL	[expr ($currChannL + $incrVal)%8]
	if {$updateChannH == 0} {
	  set updateChannH 8
	}
 	if {$updateChannL == 0} {
	  set updateChannL 8
	}

  RLExEMux::SetSingle $emuxID	-mainL $updateChannL -mainH $updateChannH
  return $gTrue
}

#***************************************************************************
#**                        RLExEMux::DisconnectSingle
#** 
#** Absrtact:
#**   Disconnection all date through the single EMux . 
#**
#**   Inputs:  ip_emuxID		         :	       Returned by Open procedure
#**  										
#**   Outputs: 
#**            0                             if success 
#**            error message by RLEH 				 otherwise
#**                              
#** Example:                        
#**	  RLExEMux::DisconnectSingle	ip_emuxID	
#**                              
#***************************************************************************

proc DisconnectSingle {args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 
  variable glchanCod 
  variable glEmuxCod 
  variable glExtendMux 

	set arrleng    [llength $args]
	set emuxID		 [lindex $args 0]

	#check	for quantity of parameters in 'DisconnectEmux' function
  if {$arrleng != 1} {
    set gMessage "Error in quantity of parameters in 'DisconnectSingleEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
	}					

	#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,singleID)]} {
    set gMessage "Single EMux $emuxID has not been opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

	RLExPio::Set	$gaEmuxPresentStatus($emuxID,idport) 1xxxxxxx

	return $gTrue
}


#***************************************************************************
#**                        RLExEMux::ConnectSingle
#** 
#** Absrtact:
#**   Connect current state that was before command disconnecte EMux . 
#**
#**   Inputs:  ip_emuxID		         :	       Returned by Open procedure
#**  										
#**   Outputs: 
#**            0                             if success 
#**            error message by RLEH 				 otherwise
#**                              
#** Example:                        
#**	  RLExEMux::ConnectSingle	ip_emuxID	
#**                              
#***************************************************************************

proc ConnectSingle {args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 
  variable glchanCod 
  variable glEmuxCod 
  variable glExtendMux 

	set arrleng    [llength $args]
	set emuxID		 [lindex $args 0]

	#check	for quantity of parameters in 'ConnectEmux' function
  if {$arrleng != 1} {
    set gMessage "Error in quantity of parameters in 'ConnectSingleEMux' function"
    return [RLEH::Handle SAsyntax gMessage]
	}					

	#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,singleID)]} {
    set gMessage "Single EMux $emuxID has not been opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

	RLExPio::Set	$gaEmuxPresentStatus($emuxID,idport) 0xxxxxxx

	return $gTrue
}


#***************************************************************************
#**                        RLExEMux::GetStateSingle
#** 
#** Absrtact:
#**   Get state of connection in single EMux by library RLExPio::Get. 
#**
#**   Inputs:  ip_emuxID		         :	       Returned by Open procedure
#**  										
#**   Outputs: 
#**            list states of connection     if success 
#**            error message by RLEH 				 otherwise
#**                              
#** Example:                        
#**	  RLExEMux::GetStateSingle	ip_emuxID
#**                              
#***************************************************************************

proc GetStateSingle {args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 
  variable glchanCod 
  variable glEmuxCod 
  variable glExtendMux 

	set arrleng    [llength $args]
	set emuxID		 [lindex $args 0]

	#check	for quantity of parameters in 'GetStateEmux' function
  if {$arrleng != 1} {
    set gMessage "Error in quantity of parameters in 'GetStateSingleEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
	}					

	#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,singleID)]} {
    set gMessage "Single EMux $emuxID has not been opened before"
    return [RLEH::Handle SAsyntax gMessage]
  }

  RLExPio::Get $gaEmuxPresentStatus($emuxID,idport)	currChann
  set aStateEmux(mainH)	[lsearch $glchanCod	[string range $currChann 5 7]]
  set aStateEmux(mainL)	[lsearch $glchanCod	[string range $currChann 2 4]]
  set connection		[string index $currChann 0]
  if {$connection == 0} {
    set	aStateEmux(connection) YES
  } else {
    set	aStateEmux(connection) NO
  }

  return [array get aStateEmux]
}

#***************************************************************************
#** 
#**                          SyntaxCheck
#** 
#**    Absrtact:		Check syntaxis input parameters
#** 
#** 
#**    Inputs:  ip_item   		       parameter
#** 												ip_value           value of tested parameter
#**    Outputs: 
#** 												error message by RLEH 		if bad syntaxis
#** 
#** 
#***************************************************************************

proc SyntaxCheck {ip_item ip_value {ip_maxval 8}} {
  variable gFalse 
  variable gTrue 
  global gMessage
  variable glPio
         
  switch -- $ip_item {
    PIONUMBER {            
							if {[string match {[1-9]} $ip_value] || $ip_value == 10}  {
								return $gTrue
              }	else {
                  set gMessage "   You must provide the Right\"ports Group\" parameter   \
                            \n\n   It's must be from 1 to 10"
                  return $gFalse
							}
    }

 		EXTMUXNUMB {
								if [string match {[1-8]} $ip_value]  {
									return $gTrue
								} else {
                    set gMessage "   You must provide the Right\"Quantity of extended EMuxs\" parameter   \
                           \n\n   It's must be from 1 to 8"
                    return $gFalse
								}
		}

 		NUMBCHANN {
							 if {[string length	$ip_value] ==1} {
					       if [string match {[1-9]} $ip_value]  {
							 		 return $gTrue
							 	 } else {
                     set gMessage "   You must provide the Right\"Number channel EMuxs\" parameter   \
                              \n\n   It's must be from 1 to 64"
                     return $gFalse
							 	 }
							 }	elseif	{[string length	$ip_value] ==2} {
							      if {[string match {[1-6][0-9]} $ip_value] && $ip_value <65 }  {
							 			  return $gTrue
							 			} else {
                        set gMessage "   You must provide the Right\"Number channel EMuxs\" parameter   \
                                 \n\n   It's must be from 1 to 64"
                        return $gFalse
							 			}
							 } else {
                   set gMessage "   You must provide the Right\"Number channel EMuxs\" parameter   \
                             \n\n   It's must be from 1 to 64"
                   return $gFalse
							 }
		}

 		INCREMVAL {

							set lenIncr		[string length	$ip_value]
              switch -- $lenIncr {
								 1 {
						        if {[string match {[0-9]} $ip_value] && $ip_value != 0}  {
  									  return $gTrue
	  							  } else {
                        set gMessage "   You must provide the Right\"Increment value\" parameter   \
                                 \n\n   It's must be from -64 to 64"
                        return $gFalse
								    }

								 }

								 2 {
							      if {[string match {[0-6-+][0-9]} $ip_value] && $ip_value <65 && $ip_value >-65 && $ip_value != 0}  {
										  return $gTrue
										} else {
                        set gMessage "   You must provide the Right\"Increment value\" parameter   \
                                   \n\n   It's must be from -64 to 64"
                        return $gFalse
										}

									}

									3 {
							       if {[string match {[0-6-+][0-9][0-9]} $ip_value] && $ip_value <65 && $ip_value >-65 && $ip_value != 0}  {
										   return $gTrue
										 } else {
                         set gMessage "   You must provide the Right\"Increment value\" parameter   \
                                     \n\n   It's must be from -64 to 64"
                         return $gFalse
										 }

									}

                  default {
                            set gMessage "   You must provide the Right\"Increment value\" parameter   \
                                         \n\n   It's must be from -64 to 64"
                            return $gFalse
                  }
							}
		}
	}     
}

} ;#end name space
