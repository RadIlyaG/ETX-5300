
#***************************************************************************
#** Filename: RLExHfmux.tcl 
#** Written by Semion  24.10.07  
#** 
#** Absrtact: This file activate the Hfmux	by RLExPio package
#**
#   Procedures names in this file:
#           - Open
#           - Set
#           - Close
#** Examples:  
#**	1.  RLExHfmux::Open 1 2	 					 (Opens Hfmux by port 1 of card 2 PCI-PIO )
#**	3.  RLExHfmux::Close idHfmux
#**	4.  RLExHfmux::Set8 idHfmux 1			 (hfmux8: connect 'main' to port 1)
#**	5.  RLExHfmux::Set4 idHfmux 1 5		 (hfmux4: connect 'main to port 5 , 'sub' to port 1)
#**	6.  RLExHfmux::Set4 idHfmux 3			 (hfmux4: connect 'sub' to port 3)
#**	7.  RLExHfmux::Set4 idHfmux 6			 (hfmux4: connect 'main' to port 6)
#**
#***************************************************************************
  package require RLEH
  package require RLExPio
  package provide RLExHfmux 0.0

namespace eval RLExHfmux    { 
     
  namespace export Open Close Set4 Set8

  global gMessage


#***************************************************************************
#**                        RLExHfmux::Open
#** Absrtact:
#**   Open Hfmux by library RLExPio. 
#**
#**   Inputs:  ip_pio			 port number 1-30
#**            [ip_card]   card number 1-15 (fefault 1)
#**   Outputs: 
#**            mux id :                       if success 
#**            error message by RLEH :	 		  otherwise
#***************************************************************************
proc Open { portNumber {card 1}} {
  global gMessage	 ERRMSG
  if {[set idHfMux [RLExPio::Open $portNumber PORT $card]] <= 0}  {
    set gMessage $ERRMSG
    append gMessage "\nERROR while open ExHfmux."
    return [RLEH::Handle SAsystem gMessage]
  }
	#Config Pio to OUT 
  if {[RLExPio::SetConfig $idHfMux out out]}  {
    set gMessage $ERRMSG
    append gMessage "\nERROR while open ExHfmux."
    return [RLEH::Handle SAsystem gMessage]
  }
  return $idHfMux
}


#***************************************************************************
#**                        RLExHfmux::Close
#** Absrtact:
#**   Close Hfmux by library RLExPio::Close. 
#**
#**   Inputs:  mux id		       
#**  										
#**   Outputs: 
#**            0 :                           if success 
#**            error message by RLEH :			 otherwise
#***************************************************************************
proc Close {muxId } {
  RLExPio::Close $muxId
	return 0
}



#***************************************************************************
#**                        RLExHfmux::Set8
#** 
#** Absrtact:
#**   Set any connection in Hfmux by library RLExPio::Set. 
#**
#**   Inputs:  
#**            mux id
#**            port								  : 1..8
#**   Outputs: 
#**            0                          if success 
#**            error message by RLEH 			otherwise
#***************************************************************************
proc Set8 {muxId port} {
  global  gMessage
  switch $port {
    "1" {set pioCode "xxx0xx00"}
	  "2" {set pioCode "xxx0xx01"}
	  "3" {set pioCode "xxx0xx10"}
	  "4" {set pioCode "xxx0xx11"}
    "5" {set pioCode "xxx100xx"}
	  "6" {set pioCode "xxx101xx"}
	  "7" {set pioCode "xxx110xx"}
	  "8" {set pioCode "xxx111xx"}
	  "default" {
        set gMessage "Fail : There is no port $port in ExHFmux8"
        return [RLEH::Handle SAsyntax gMessage]	  
	  }
  }
  RLExPio::Set $muxId $pioCode
  return 0
}

#***************************************************************************
#**                        RLExHfmux::Set4
#** 
#** Absrtact:
#**   Set any connection in Hfmux by library RLExPio::Set. 
#**
#**   Inputs:  
#**            mux id
#**            ports						: if you write one of the ports 1..4 than you connect 
#**      													the 'sub' to that port
#**                   					: if you write one of the ports 5..8 than you connect 
#**      													 the 'main' to that port
#** 													  : if you write 2 ports (one from 1..4 and one from 5..8)
#**                                              than you connect to the main & sub
#**   Outputs: 
#**            0                          if success 
#**            error message by RLEH 			otherwise
#***************************************************************************
proc Set4 {muxId args} {
  global  gMessage
  set sub -1
  set main -1
  if {[llength $args]==2} {
     set sub [lindex $args 0]
     set main [lindex $args 1]
  }
  if {[llength $args]==1} {     
     set temp [lindex $args 0]
	  if {$temp==1 || $temp==2 || $temp==3 || $temp==4} {
		  set sub $temp
	  } else {
	     set main $temp
	  }
  }
  switch -- $sub {
    "1" {set sCode "00"}
	  "2" {set sCode "01"}
	  "3" {set sCode "10"}
	  "4" {set sCode "11"}
	  "-1" {set sCode "xx"}
	  "default" {
        set gMessage "Fail : There is no port $sub in ExHFmux4"
        return [RLEH::Handle SAsyntax gMessage]	  
	  }
  }
  switch -- $main {
    "5" {set mCode "00"}
	  "6" {set mCode "01"}
	  "7" {set mCode "10"}
	  "8" {set mCode "11"}
	  "-1" {set mCode "xx"}
	  "default" {
        set gMessage "Fail : There is no port $main in ExHFmux4"
        return [RLEH::Handle SAsyntax gMessage]	  
	  }
  }
  RLExPio::Set $muxId "xxxx$mCode$sCode"
  return 0
}


#end name space
}
