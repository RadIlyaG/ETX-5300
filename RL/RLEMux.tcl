
#***************************************************************************
#** Filename: RLEMux.tcl 
#** Written by Semion  30.5.2001 updated 3.01.06 
#** 
#** Absrtact: This file operate with EMux
#**
#** Inputs:
#**  'DOS command line style of BTL',i.e :
#**     COMMAND FirstParameter SecondParameter [ThirdParameter]...
#**     The COMMANDs are:
#**           - RLEMux::Open           Open EMux(Group of EMux) for following operation.
#**           - RLEMux::Close          Close EMux.
#**           - RLEMux::Set            Set any connection in EMux.
#**						- RLEMux::Increment			 Increment connection the Main to folowing channel.
#**						- RLEMux::Disconnect	   Disconnect EMux.
#**						- RLEMux::Connect				 Connect the last state of channels that was before disconnect.
#**           - RLEMux::GetState       Get State of Connection in EMux.
#**
#**           - RLEMux::OpenSingle        Open only one EMux for following operation.
#**           - RLEMux::CloseSingle       Close only one EMux.
#**           - RLEMux::SetSingle         Set any connection in only one EMux.
#**						- RLEMux::IncrementSingle	  Increment connection the Main to folowing channel.
#**						- RLEMux::DisconnectSingle	Disconnect only one EMux.
#**						- RLEMux::ConnectSingle		  Connect the last state of channels that was before disconnect.
#**           - RLEMux::GetStateSingle    Get State of Connection in only one EMux.
#** Examples:  
#**	1.  RLEMux::Open 3L 1	 
#**	2.  RLEMux::Open 2H	8	-mainH 5 
#**	3.  RLEMux::Close IDmux
#**	4.  RLEMux::Set IDmux -mainH 4 -mainL 7
#**	5.  RLEMux::Set IDmux -mainH 34 -mainL 35
#**	6.  RLEMux::Set IDmux -mainH 14 -mainL 27		NO VALID !!! the split Main channel must be in same EMux.
#**	7.  RLEMux::Set IDmux -main 63
#**	8.  RLEMux::Set IDmux -main 2	-muxE 3
#**	9.  RLEMux::Increment	IDmux
#**	10.	RLEMux::Disconnect	IDmux
#**	11.	RLEMux::Connect		IDmux
#**	12.	RLEMux::GetState	IDmux		
#**
#**	13. RLEMux::OpenSingle           3a L 	 
#**	14. RLEMux::OpenSingle           2c H 
#**	15. RLEMux::CloseSingle          IDmux
#**	16. RLEMux::SetSingle            IDmux -mainH 4 -mainL 7
#**	17. RLEMux::SetSingle            IDmux -main 5
#**	18. RLEMux::SetSingle            IDmux -mainH 1
#**	19. RLEMux::SetSingle            IDmux -mainL 3
#**	20. RLMux::IncremSingle	         IDmux
#**	21.	RLEMux::DisconnectSingle	   IDmux
#**	22.	RLEMux::ConnectSingle		     IDmux
#**	23.	RLEMux::GetStateSingle	     IDmux		
#***************************************************************************
  package require RLEH 1.0
  package require RLPio 2.0
  package require RLTime
  package provide RLEMux 3.0

namespace eval RLEMux    { 
     
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


#		set		glPio		[list 1H 2H 3H 4H 5H 6H 7H 8H 1L 2L 3L 4L 5L 6L 7L 8L]
  set  glExtendMux "0 11111110 11111100 11111000 11110000 11100000 11000000 10000000 00000000"
		set  glchanCod			"0	000 100 010 110 001 101 011 111"
		set  glEmuxCod 		"0 000 001 010 011 100 101 110 111"

#***************************************************************************
#**                        RLEMux::Open
#** 
#** Absrtact:
#**   Open EMux by library RLPio::Config(a,b,c). 
#**
#**   Inputs:  ip_pio   		       :	1L,1H....8L,8H
#**  					 ip_numbEmuxs				 : number of split Emuxs 1-8
#**            [par. for Set	]		 : parameters for set any conection during open mux
#**   Outputs: 
#**            IDmux                         if success 
#**            error message by RLEH 				 otherwise
#**                              
#** Example:                        
#**	1. set IDemux1  [RLEMux::Open 3L 1]
#**	2. set IDemux2  [RLEMux::Open 2H	8 -main 7 -muxE 3]	 
#**	3. set IDemux3  [RLEMux::Open 3	8 -mainH 5 -hwCheck yes]	 
#***************************************************************************

proc Open { args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 
  variable glExtendMux 

	set arrleng      [llength $args]
  set maxarg       10
  set minarg       2
	set numbEmux		 [lindex $args 1]
	set pioNumber		 [lindex $args 0]
	set hwCheck  "yes"

  #check for rigth syntax of "Pio Number"
  set number [set tempnumber [ string index $pioNumber 0]] 
  if {[SyntaxCheck PIONUMBER $tempnumber] != $gTrue} {
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
  #check for space parameter
	set tempspace		[string index $pioNumber 1]
	if {[string match $tempspace ""] || [string match $tempspace H]} {
    set space HIGH
		set tempspace	H
	} elseif {[string match $tempspace L]} {
 	  set space LOW
	}	else {
    set gMessage "   You must provide the Right\"Space\" parameter   \
                     \n\n   It's must be L,H, or no thing"
    return [RLEH::Handle SAsyntax gMessage]
	}
	
	#check that this Emux was not opened before
	set emuxID [append tempnumber $tempspace]
  if {[info exists gaEmuxPresentStatus($emuxID,mainID)]} {
    set gMessage "EMux $emuxID already open"
    return [RLEH::Handle SAsyntax gMessage]
  }
	
	#set members of global array of opened emux.
	set gaEmuxPresentStatus($emuxID,mainID)	$emuxID
	set gaEmuxPresentStatus($emuxID,numbEmux)	$numbEmux
	#open pio "a" ,"b" ,"c" for this Emux
	foreach {pio conf}  {a OUT b OUT c IN} {
	  set	tempnumber	$number
		if {[catch {RLPio::Config [append tempnumber $pio] $conf $space} gaEmuxPresentStatus($emuxID,id$pio)]} {
		  unset gaEmuxPresentStatus($emuxID,id$pio)
			RLEMux::Close $emuxID             
	    return [RLEH::Handle SAsyntax gMessage]
		}
	}

	RLTime::Delayms 250
	#check order of extended Emuxes
	if {[string match -nocase $hwCheck "yes"]} {
		if {[set expmap [lindex $glExtendMux $numbEmux]] !=  \
		                              [set map [RLPio::Get	$gaEmuxPresentStatus($emuxID,idc)	confres]]} {
	  set gMessage "Mismatch of addreses extended Emuxes : exists (0) and not exists (1) \		
				              \n\n          MSBIT - Emux 8 ; LSBIT - Emux 1   :  $map \
																	  \n           expected for Emuxes = $numbEmux               :  $expmap"
				RLEMux::Close $emuxID             
	  return [RLEH::Handle SAsyntax gMessage]
		}
	}
	#open without connection
	if {$arrleng == $minarg} {
			RLPio::Set	$gaEmuxPresentStatus($emuxID,idb) 1xxxxxxx
	} elseif {$arrleng == 4 && [lindex $args 2] == "-hwCheck"} {
			RLPio::Set	$gaEmuxPresentStatus($emuxID,idb) 1xxxxxxx
	} else {
	#open with connection
					RLEMux::Set $emuxID	[lindex $args 2]	[lindex $args 3] [lindex $args 4] [lindex $args 5]			\
					                    [lindex $args 6]	[lindex $args 7] [lindex $args 8]	[lindex $args 9]
	}
	return $emuxID
}


#***************************************************************************
#**                        RLEMux::Close
#** 
#** Absrtact:
#**   Close EMux by library RLPio::Close. 
#**
#**   Inputs:  ip_emuxID		       :	1L,1H....8L,8H
#**  										
#**   Outputs: 
#**            0                             if success 
#**            error message by RLEH 								otherwise
#**                              
#** Example:                        
#**	  RLEMux::Close 	ip_emuxID
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

	#close pio "a" ,"b" ,"c" for this Emux
	foreach {pio amember}  [list a		gaEmuxPresentStatus($emuxID,ida)	\
                              b  gaEmuxPresentStatus($emuxID,idb) 	\
	                             c	 gaEmuxPresentStatus($emuxID,idc)] {

			if {[info exists $amember]} {
			 RLPio::Close $gaEmuxPresentStatus($emuxID,id$pio)
					unset	$amember
			}
	}
	unset	gaEmuxPresentStatus($emuxID,mainID)
	unset gaEmuxPresentStatus($emuxID,numbEmux)	

	return $gTrue
}


#***************************************************************************
#**                        RLEMux::Set
#** 
#** Absrtact:
#**   Set any connection in EMux by library RLPio::Set. 
#**
#**   Inputs:  ip_emuxID		         :	       1L,1H....8L,8H
#**            [ip_main]			 [val]		:								-main			1-64
#**  										[ip_mainH] 	 [val]		:								-mainH		1-64
#**  										[ip_mainL]			[val]		:								-mainL		1-64
#**  										[ip_numbMux]	[val]		:								-muxE			1-8
#**  										
#**   Outputs: 
#**            0                             if success 
#**            error message by RLEH 								otherwise
#**                              
#** Example:                        
#**	1.  RLEMux::Set	ip_emuxID	-main 53
#** 2.   !!!! error       RLEMux::Set	ip_emuxID	-main 23 -muxE 2    no valid                      
#** 3.  RLEMux::Set	ip_emuxID	-main 3 -muxE 6                         
#** 4.  RLEMux::Set	ip_emuxID	-mainH 43                           
#** 5.  RLEMux::Set	ip_emuxID	-maiL 8 -muxE 5                           
#** 6.  RLEMux::Set	ip_emuxID	-mainH 3 -mainL 7 -muxE 2                          
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

			-hwCheck {

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
#		RLPio::Set	$gaEmuxPresentStatus($emuxID,idb) 1xxxxxxx
#		RLTime::Delayms 250
		#set new connaction
		RLPio::Set	$gaEmuxPresentStatus($emuxID,ida) $ctrlwordL$ctrlwordH
		RLPio::Set	$gaEmuxPresentStatus($emuxID,idb) 0xxxx$ctrlEmux
		return $gTrue
}


#***************************************************************************
#**                        RLEMux::Increment
#** 
#** Absrtact:
#**   Set connection in EMux by increment to input parameters or to current state. 
#**
#**   Inputs:  ip_emuxID		         :	       1L,1H....8L,8H
#**  										
#**   Outputs: 
#**            0                             if success 
#**											-1                             if over last mux and channel
#**            error message by RLEH 								otherwise
#**                              
#** Example:                        
#**	1.  RLEMux::Increm	ip_emuxID	
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

		set arrleng    [llength $args]
  set maxarg       2
  set minarg       1
		set emuxID					[lindex $args 0]

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

  set currChann [lsearch $glchanCod	[string range [RLPio::Get $gaEmuxPresentStatus($emuxID,ida)	res]	\
	                                                                                            2 4]]

  set currEmux [lsearch $glEmuxCod	[string range [RLPio::Get $gaEmuxPresentStatus($emuxID,idb)	res]	\
	                                                                                            5 end]]

  set updateChann	[expr	($currChann + $incrVal)	+ (8 *	($currEmux	-1))]


  if {$updateChann <1 ||	$updateChann > [expr	$gaEmuxPresentStatus($emuxID,numbEmux)*8]} {
  		return $gFalse
		}	else {
		    RLEMux::Set	$emuxID	-main $updateChann
#						puts "chann= $currChann ,Emux=$currEmux "
		}
  		return $gTrue
}


#***************************************************************************
#**                        RLEMux::Disconnect
#** 
#** Absrtact:
#**   Disconnection all date through the EMux . 
#**
#**   Inputs:  ip_emuxID		         :	       1L,1H....8L,8H
#**  										
#**   Outputs: 
#**            0                             if success 
#**            error message by RLEH 								otherwise
#**                              
#** Example:                        
#**	  RLEMux::Disconnect	ip_emuxID	
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
		set emuxID					[lindex $args 0]

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

	RLPio::Set	$gaEmuxPresentStatus($emuxID,idb) 1xxxxxxx

		return $gTrue
}


#***************************************************************************
#**                        RLEMux::Connect
#** 
#** Absrtact:
#**   Connect current state that was before command disconnecte EMux . 
#**
#**   Inputs:  ip_emuxID		         :	       1L,1H....8L,8H
#**  										
#**   Outputs: 
#**            0                             if success 
#**            error message by RLEH 								otherwise
#**                              
#** Example:                        
#**	  RLEMux::Connect	ip_emuxID	
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
		set emuxID					[lindex $args 0]

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

	RLPio::Set	$gaEmuxPresentStatus($emuxID,idb) 0xxxxxxx

		return $gTrue
}


#***************************************************************************
#**                        RLEMux::GetState
#** 
#** Absrtact:
#**   Get state of connection in EMux by library RLPio::Get. 
#**
#**   Inputs:  ip_emuxID		         :	       1L,1H....8L,8H
#**  										
#**   Outputs: 
#**            list states of connection     if success 
#**            error message by RLEH 								otherwise
#**                              
#** Example:                        
#**	  RLEMux::GetState	ip_emuxID
#**                              
#***************************************************************************

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
		set emuxID					[lindex $args 0]

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

 	set currChann		[RLPio::Get $gaEmuxPresentStatus($emuxID,ida)	res]
		set aStateEmux(mainH) 	[lsearch $glchanCod	[string range $currChann 5 end]]
		set aStateEmux(mainL) 	[lsearch $glchanCod	[string range $currChann 2 4]]

		set currEmux		[RLPio::Get $gaEmuxPresentStatus($emuxID,idb)	res]
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
#**                        RLEMux::OpenSingle
#** 
#** Absrtact:
#**   OpenSingle EMux by library RLPio::Config(a,b,c). 
#**
#**   Inputs:  ip_pio   		       :	1L,1H....8L,8H
#**            
#**   Outputs: 
#**            IDmux                         if success 
#**            error message by RLEH 								otherwise
#**                              
#** Example:                        
#**	1. set IDemux1  [RLEMux::OpenSingle 3a L]
#**	2. set IDemux2  [RLEMux::OpenSingle 2c H]	 
#**	3. set IDemux3  [RLEMux::OpenSingle 3c]	 
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
  set space					[ lindex $args 1]
  set pioNumber				[ lindex $args 0]

  #check for rigth syntax of "Pio Number"
  set number [ string index $pioNumber 0] 
  if {$number < 1 || $number > 8} {
  	 set gMessage "   You must provide the Right \"Pio Number\" parameter   \
                      \n\n   It must be from 1 to 8 but got $number"
     return [RLEH::Handle SAsyntax gMessage]
  } 
  set letter [ string index $pioNumber 1] 
  if {[string match {[a-cA-C]} $letter] != 1} {
  	 set gMessage "   You must provide the Right \"Pio Number Letter\" parameter   \
                      \n\n   It must be from a to c but got $letter"
     return [RLEH::Handle SAsyntax gMessage]
  }
  set letter [string tolower $letter] 

  #check for space parameter
  #set space		[string index $pioNumber 1]
  if {[string match $space ""] || [string match $space H] || [string match $space HIGH]} {
 	  set space HIGH
	  set tempspace	H
  } elseif {[string match $space L] || [string match $space LOW]} {
   	  set space LOW
	  set tempspace	L
  }	else {
      set gMessage "   You must provide the Right \"Space\" parameter   \
                       \n\n   It must be L,LOW,H,HIGH or nothing but got $space"
      return [RLEH::Handle SAsyntax gMessage]
  }
		
  #check that this Emux was not opened before
  set emuxID ""
  append emuxID $number $letter $tempspace
  if {[info exists gaEmuxPresentStatus($emuxID,mainID)]} {
    set gMessage "EMux $emuxID already open"
    return [RLEH::Handle SAsyntax gMessage]
  }
	
  #open pio for this Emux
  set	tempnumber	$number
  set gaEmuxPresentStatus($emuxID,idpio) [RLPio::Config [append tempnumber $letter] OUT $space] 
  #set members of global array of opened emux.
  set gaEmuxPresentStatus($emuxID,mainID)	$emuxID
  
  RLTime::Delayms 250
  
  RLPio::Set $gaEmuxPresentStatus($emuxID,idpio) 1xxxxxxx
  
  return $emuxID
}

#***************************************************************************
#**                        RLEMux::CloseSingle
#** 
#** Absrtact:
#**   CloseSingle EMux by library RLPio::Close. 
#**
#**   Inputs:  ip_emuxID		       :	1L,1H....8L,8H
#**  										
#**   Outputs: 
#**            0                             if success 
#**            error message by RLEH 				 otherwise
#**                              
#** Example:                        
#**	  RLEMux::CloseSingle 	ip_emuxID
#***************************************************************************

proc CloseSingle {args } {

  # global (import) 
  global ERRMSG
  global  gMessage
  variable gaEmuxPresentStatus  
  variable gFalse 
  variable gTrue 

		set arrleng    [llength $args]
		set emuxID					[lindex $args 0]

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

  if {[info exists gaEmuxPresentStatus($emuxID,numbEmux)]} {
    set gMessage "This EMux with ID: $emuxID has been opened with Open procedure\n and must use Close procedure."
    return [RLEH::Handle SAsyntax gMessage]
  }
	
  #close pio "a" ,"b" ,"c" for this Emux
  RLPio::Close $gaEmuxPresentStatus($emuxID,idpio)
  unset	gaEmuxPresentStatus($emuxID,idpio)
  unset	gaEmuxPresentStatus($emuxID,mainID)

  return $gTrue
}


#***************************************************************************
#**                        RLEMux::SetSingle
#** 
#** Absrtact:
#**   SetSingle any connection into single EMux by library RLPio::Set. 
#**
#**   Inputs:  ip_emuxID		            :	       1L,1H....8L,8H
#**            [ip_main]			 [val]		:					-main		  1-8
#**  					 [ip_mainH] 	   [val]		:   			-mainH		1-8
#**  					 [ip_mainL]			 [val]		:	        -mainL		1-8
#**  										
#**   Outputs: 
#**            0                        if success 
#**            error message by RLEH 	otherwise
#**                              
#** Example:                        
#**	1.  RLEMux::SetSingle	ip_emuxID	-main 5
#** 2.  RLEMux::SetSingle	ip_emuxID	-mainH 4                           
#** 3.  RLEMux::SetSingle	ip_emuxID	-mainL 8                           
#** 4.  RLEMux::SetSingle	ip_emuxID	-mainH 3 -mainL 7                      
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
    set gMessage "Error in quantity of parameters in 'SetEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
  }					

		#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,mainID)]} {
    set gMessage "EMux $emuxID has not been opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {[info exists gaEmuxPresentStatus($emuxID,numbEmux)]} {
    set gMessage "This EMux with ID: $emuxID has been opened with Open procedure\n and must use Set procedure."
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
                set gMessage "Set EMux:  Wrong name of parameter $param"
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
  RLPio::Set $gaEmuxPresentStatus($emuxID,idpio) $ctrlwordL$ctrlwordH
  RLEMux::ConnectSingle $gaEmuxPresentStatus($emuxID,mainID)
  return $gTrue
}

#***************************************************************************
#**                        RLEMux::IncrementSingle
#** 
#** Absrtact:
#**   Set connection in EMux by increment to input parameters or to current state. 
#**
#**   Inputs:  ip_emuxID		   :	       1L,1H....8L,8H
#**  		   [ip_incVal]				 :         1,2,...6,7,-1,-2....-6,-7  ; number of steps to incr the EMux								
#**  										
#**   Outputs: 
#**            0                    	if success 
#**            error message by RLEH 	otherwise
#**                              
#** Example:                        
#**	1.  RLEMux::IncrementSingle $ip_emuxID	
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
  set emuxID	 [lindex $args 0]

		#check	for quantity of parameters in 'IncremEmux' function
  if {$arrleng < $minarg || $arrleng > $maxarg} {
    set gMessage "Error in quantity of parameters in 'IncremEmux' function"
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
  if {![info exists gaEmuxPresentStatus($emuxID,mainID)]} {
    set gMessage "EMux $emuxID has not been opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {[info exists gaEmuxPresentStatus($emuxID,numbEmux)]} {
    set gMessage "This EMux with ID: $emuxID has been opened with Open procedure\n and must use Increment procedure."
    return [RLEH::Handle SAsyntax gMessage]
  }

  set currChannL [lsearch $glchanCod	[string range [RLPio::Get $gaEmuxPresentStatus($emuxID,idpio)	res]  2 4]]
  set currChannH [lsearch $glchanCod	[string range [RLPio::Get $gaEmuxPresentStatus($emuxID,idpio)	res]  5 7]]

  set updateChannH	[expr ($currChannH + $incrVal)%8]
  set updateChannL	[expr ($currChannL + $incrVal)%8]

  RLEMux::SetSingle $emuxID	-mainL $updateChannL -mainH $updateChannH
  return $gTrue
}

#***************************************************************************
#**                        RLEMux::DisconnectSingle
#** 
#** Absrtact:
#**   Disconnection all date through the single EMux . 
#**
#**   Inputs:  ip_emuxID		         :	       1L,1H....8L,8H
#**  										
#**   Outputs: 
#**            0                             if success 
#**            error message by RLEH 								otherwise
#**                              
#** Example:                        
#**	  RLEMux::DisconnectSingle	ip_emuxID	
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
		set emuxID					[lindex $args 0]

		#check	for quantity of parameters in 'DisconnectEmux' function
  if {$arrleng != 1} {
    set gMessage "Error in quantity of parameters in 'DisconnectEmux' function"
    return [RLEH::Handle SAsyntax gMessage]
		}					

		#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,mainID)]} {
    set gMessage "EMux $emuxID has not been opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {[info exists gaEmuxPresentStatus($emuxID,numbEmux)]} {
    set gMessage "This EMux with ID: $emuxID has been opened with Open procedure\n and must use Disconnect procedure."
    return [RLEH::Handle SAsyntax gMessage]
  }

	RLPio::Set	$gaEmuxPresentStatus($emuxID,idpio) 1xxxxxxx

		return $gTrue
}


#***************************************************************************
#**                        RLEMux::ConnectSingle
#** 
#** Absrtact:
#**   Connect current state that was before command disconnecte EMux . 
#**
#**   Inputs:  ip_emuxID		         :	       1L,1H....8L,8H
#**  										
#**   Outputs: 
#**            0                             if success 
#**            error message by RLEH 								otherwise
#**                              
#** Example:                        
#**	  RLEMux::ConnectSingle	ip_emuxID	
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
		set emuxID					[lindex $args 0]

		#check	for quantity of parameters in 'ConnectEmux' function
  if {$arrleng != 1} {
    set gMessage "Error in quantity of parameters in 'Connect' function"
    return [RLEH::Handle SAsyntax gMessage]
		}					

		#check that this Emux was opened before
  if {![info exists gaEmuxPresentStatus($emuxID,mainID)]} {
    set gMessage "EMux $emuxID has not been opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {[info exists gaEmuxPresentStatus($emuxID,numbEmux)]} {
    set gMessage "This EMux with ID: $emuxID has been opened with Open procedure\n and must use Connect procedure."
    return [RLEH::Handle SAsyntax gMessage]
  }

	RLPio::Set	$gaEmuxPresentStatus($emuxID,idpio) 0xxxxxxx

		return $gTrue
}


#***************************************************************************
#**                        RLEMux::GetStateSingle
#** 
#** Absrtact:
#**   Get state of connection in single EMux by library RLPio::Get. 
#**
#**   Inputs:  ip_emuxID		         :	       1L,1H....8L,8H
#**  										
#**   Outputs: 
#**            list states of connection     if success 
#**            error message by RLEH 								otherwise
#**                              
#** Example:                        
#**	  RLEMux::GetStateSingle	ip_emuxID
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
		set emuxID					[lindex $args 0]

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

  if {[info exists gaEmuxPresentStatus($emuxID,numbEmux)]} {
    set gMessage "This EMux with ID: $emuxID has been opened with Open procedure\n and must use GetState procedure."
    return [RLEH::Handle SAsyntax gMessage]
  }

  set currChann [RLPio::Get $gaEmuxPresentStatus($emuxID,idpio)	res]
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
										if [string match {[1-8]} $ip_value]  {
												return $gTrue
         }	else {
           set gMessage "   You must provide the Right\"Pio Number\" parameter   \
                        \n\n   It's must be from 1 to 8"
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
									}	else {
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

#end name space
}
