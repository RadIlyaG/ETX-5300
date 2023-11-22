# .........................................................................................
#   File name: RL10GbGen.tcl
#   Written by Ilya 
#
#   Abstract: This file activate the product Etx-220 with specific software for running Ethernet generator,
#              This Etx-220 has 4 generators of 10GB , every one may be configured indepandly.
#   Procedures names in this file:
#           - Open
#           - Init
#           - Config
#           - Start
#           - Clear
#           - Stop
#           - Read
#           - Stop
#           - Check
#           - Close
#           - CloseAll
#
# .........................................................................................

package require BWidget
package require RLEH 
package require img::ico 
# package require math::bignum
# package require math::bigfloat

package provide RL10GbGen 1.3.2
# global g10GbGenBufferDebug
# set g10GbGenBufferDebug 1
global gMessage

namespace eval RL10GbGen {
  namespace export Open Init Config Start Clear Read Stop Check\
	 ShowGui GoToMain Close CloseAll 
 
  global gMessage
  global    g10GbGenBuffer
  variable    g10GbGenBufferDebug
  
  variable  va10GbGenGui
  variable  va10GbGenSet
  variable  va10GbGenCfg
  variable  va10GbGenStatuses 
  variable  vOpened10GbGenHistoryCounter
  variable  vlStreamStatsL
  variable  vlStreamZeroStatsL
  variable  vlPortStatsL
  variable  vlPortZeroStatsL
  
  set ::RL10GbGen::g10GbGenBufferDebug 0
  
	set va10GbGenSet(closeByDestroy) 0
	set va10GbGenSet(startTime) 0
  set va10GbGenSet(EmailSum) 10
  set vOpened10GbGenHistoryCounter  0

  set ::RL10GbGen::vlStreamStatsL [list RunTime BitsTransmitRate BitsReceivedRate \
      TxPacket RxPacket TxByte RxByte DataIntegrityErrors DataSequenceErrors ]
  set ::RL10GbGen::vlStreamZeroStatsL [list DataIntegrityErrors DataSequenceErrors ]    
      # [RxCrcErrors RxOversizePackets RxJabbers RxMacError RxShortPackets RxMacOverflow]
#   set ::RL10GbGen::vlPortStatsL [list RunTime RxPkts RxOctets RxOversizePackets RxJabbers\
#       RxCrcErrors RxMacError RxShortPackets RxMacOverflow TxPkts TxOctets\
#       TxOversizePackets TotalTxDroppedPackets ClassificationErrors]
  set ::RL10GbGen::vlPortStatsL [list RunTime TxPkts RxPkts TxOctets RxOctets \
      RxOversizePackets RxJabbers\
      RxCrcErrors RxMacError RxShortPackets RxMacOverflow \
      TxOversizePackets TotalTxDroppedPackets ClassificationErrors]      
  set ::RL10GbGen::vlPortZeroStatsL [list RxOversizePackets RxJabbers\
      RxCrcErrors RxMacError RxShortPackets RxMacOverflow \
      TxOversizePackets TotalTxDroppedPackets ClassificationErrors]    
      # AclDataDiscard ParserDiscard
      # ClassifierDiscard XpermissionDiscard MacLimitViolation ForwardedUnmatchedDis
      # ForwardedMatchedDis OamDiscard LxcpDiscard
# ***************************************************************************
# ***************************************************************************
#
#                  EXPORT FUNCTIONs
#
# ***************************************************************************
# ***************************************************************************

# ***************************************************************************
# **                        RL10GbGen::Open
# ** 
# **  Abstract: Open the RL10GbGen by com or telnet
# **            Check if the RL10GbGen is ready to be activate
# **
# **   Inputs:
# **            ip_address              :	        Com number or IP address.
# **                              
# **                              
# **   Outputs: 
# *            IDApp                   :        ID of opened  RL10GbGen . 
# **            Negative error code or  :        Otherwise.     
# **            error message by RLEH 	 				
# **                              
# ** Example:                        
# **	1. set id1  [::RL10GbGen::Open 1]
# ***************************************************************************

proc Open {ip_address} {
  global        g10GbGenBuffer
  global        gMessage
  variable      va10GbGenStatuses 
  variable      vOpened10GbGenHistoryCounter
  variable ScriptFile
  set gMessage ""                   
	set package 		 RLSerial
  set config         none
	set fail          -1
	set ok             0

	# processing address
  if {[regexp {([0-9]+).([0-9]+).([0-9]+).([0-9]+)} $ip_address match subip1 subip2 subip3 subip4]} {
    if {$subip1 > 255 || $subip2 > 255 || $subip3 > 255 || $subip4 > 255} {
      set gMessage "RL10GbGen Open:  Wrong IP address"
      return [RLEH::Handle SAsyntax gMessage]
    }
    set connection telnet
  } elseif {$ip_address > 333 || $ip_address < 1} {
    set gMessage "RL10GbGen Open:  Wrong Com number or IP address"
    return [RLEH::Handle SAsyntax gMessage]
  } else {
    set connection com
  }
	# check empty place in Opened 10GbGen array
	for {set i 1} {$i <= $vOpened10GbGenHistoryCounter} {incr i} {
		if {![info exists va10GbGenStatuses($i,10GbGenID)]} {
		  break
		}
	}
  
	set 10GbGenIndex $i
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "Open ip_address:$ip_address i:$i" ; update
  }
  # open 10GbGen
  set  va10GbGenStatuses($i,connection) $connection
  set  va10GbGenStatuses($i,package) $package
  set  va10GbGenStatuses($i,address) $ip_address
  
  
  set ScriptFile c:\\tmpTmp\\[clock format [clock seconds] -format "%Y.%m.%d_%H.%M.%S"].txt
  if ![file exists c:\\tmpTmp] {
    file mkdir c:\\tmpTmp
  }
  set id [open $ScriptFile w+]
  close $id
  
  # puts "Open gMessage:$gMessage"; update
  set res [Open10GbGen $ip_address $connection $package $i]
  # puts "Open res:$res"; update
  if {$res=="0"} {
    set  va10GbGenStatuses($i,10GbGenID) $i
  	if {$i > $vOpened10GbGenHistoryCounter} {
      incr vOpened10GbGenHistoryCounter
    }
    return $va10GbGenStatuses($i,10GbGenID)
  } else {
    append gMessage "\nCann't open Etx-220"
    return [RLEH::Handle SAsyntax gMessage]
  }
} 
# *************************************************************************
# **                        RL10GbGen::Init
# ** 
# **  Abstract: Configure Gen ports parameters of Etx220A Generator by com 
# **
# **   Inputs:
# **            ip_ID                   :	        ID of Etx220 Gen returned by Open procedure .
# **                              
# **                              
# **            
# **                              
# **   Outputs: 
# **            0                       :        if success. 
# **            Negative error code or  :        Otherwise.     
# **            error message by RLEH 	 				
# **                              
# ** Example:                        
# **	 ::RL10GbGen::Init 1
# ***************************************************************************
proc Init {id} {
  set ret [::RL10GbGen::GenConfig $id cfg]
  return $ret
}

# ***************************************************************************
# **                        RL10GbGen::Config
# ** 
# **  Abstract: Stream Configuration.
# **
# **   Inputs:
# **            ip_ID                   :	       ID of Etx220 returned by Open procedure .
# **            tx_port                 :         Transmit Port
# **            rx_port                 :         Receive Port
# **
# **            args   parameters and their value:
# **            -da                     :  MAC Destination Address. Default: 001000100001. 12 HEX digits 
# **            -sa                     :  MAC Source Address. Default: 002000200002. 12 HEX digits
# **            -minPacketSize          :  Minimum Packet Size. Default: 64. Range: 64 - 2000. Must be same for all streams
# **            -maxPacketSize          :  Maximum Packet Size. Default: 2000. Range: 64 - 2000. Must be same for all streams
# **            -IPG                    :  Inter-Packet Gap. Default: 20. Range: 8 - 31.  Must be same for all streams
# **            -seqErrorThreshold      :  Sequence Errors Threshold. Default: 0. Range: 0 - 128.  Must be same for all streams
# **            -sizeType               :  Fixed/Incr/Random/Emix Default: Fixed
# **            -size                   :  When -sizeType is Fixed, the -size may be any value between the -minPacketSize and the -maxPacketSize. Default: 1000.
# **                                       When -sizeType is Incr or Random, the -size is unnecessary. The stream's size will be configured automatically to a value between the -minPacketSize and the -maxPacketSize
# **                                       When -sizeType is Emix, the values of -size are 64, 128, 256, 512, 1024, 1280, 1518 and 2000. Should be provided as list up to 8 sizes
# **            -streamControl          :  "packet" or integer. Default: packet. If an integer is defined, the Stream will transmitted as a burst of n packets 
# **            -clkFreq                :  Depends on board's HW. Default: 150
# **            -lineRate               :  Percent of tx_port's capacity 
# **            -vlan1                  :  Range: 0 - 4095. Default: 0
# **            -pBit1                  :  Range: 0 - 7. Default: 0
# **            -cfi1                   :  Reset/Set. Default: Reset
# **            -protocolId1            :  0x8100/0x88a8. Default: 0x8100
# **            -vlan2 -vlan3 -vlan4    :  Same as for -vlan1
# **            -pBit2 -pBit3 -pBit4    :  Same as for -pBit1
# **            -cfi2 -cfi3 -cfi4       :  Same as for -cfi1
# **            -protocolId2 -protocolId3 -protocolId4    :  Same as for -protocolId1
# **            -ipv4DA                 :  Default 0.0.0.0
# **            -ipv4SA                 :  Default 0.0.0.0
# **            -ipv4Ttl                :  Default 64
# **            -dataPatternType        :  Incremental/Repeat/Random/AllZeros. Default: AllZeros 
# **            -dataPatternData        :  When -dataPatternType is Repeat, range: 00 - FF Default: 00 

# **                              
# **   Outputs: 
# **            0                       :  if success. 
# **            Negative error code or  :  Otherwise.     
# **            error message by RLEH 	 				
# **                              
# ** Example:                        
# **	 ::RL10GbGen::Config 1 1 2 
# **	 ::RL10GbGen::Config 1 1 2 -da 0123456789AB  -da FEDCBA987654
# **	 ::RL10GbGen::Config 1 1 2 -minPacketSize 100 -maxPacketSize 1510 -sizeType Fixed -size 1000
# **	 ::RL10GbGen::Config 1 1 2 -minPacketSize 100 -maxPacketSize 1510 -sizeType Incr
# **	 ::RL10GbGen::Config 1 1 2 -sizeType Random
# **	 ::RL10GbGen::Config 1 1 2 -minPacketSize 100 -maxPacketSize 1510 -sizeType Emix -size [list 64 2000 512 128 1280]
# **	 ::RL10GbGen::Config 1 1 2 -streamControl packet
# **	 ::RL10GbGen::Config 1 1 2 -streamControl 100000
# **	 ::RL10GbGen::Config 1 1 2 -clkFreq 150
# **	 ::RL10GbGen::Config 1 1 2 -lineRate 56%
# **	 ::RL10GbGen::Config 1 1 2 -vlan1 128 -pBit1 2 -cfi1 Set -protocolId1 0x8100 -vlan2 0 -vlan3 4095 -vlan4 100
# **	 ::RL10GbGen::Config 1 1 2 -ipv4DA 1.2.3.4  -ipv4SA 8.7.6.5 -ipv4Ttl 100
# **	 ::RL10GbGen::Config 1 1 2 -dataPatternType incremental
# ***************************************************************************
proc Config {id tx_port rx_port args} {
  if {$tx_port==$rx_port} {
    set txPortL [list $tx_port]
    set rxPortL [list $rx_port]
  } else {
    set txPortL [list $tx_port $rx_port]
    set rxPortL [list $rx_port $tx_port]
  }
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "Config txPortL:<$txPortL> rxPortL:<$rxPortL>"; update
  }  
  after 100
  foreach txPort $txPortL rxPort $rxPortL {
    set stream_id [expr {$txPort-1}]
    set ret [eval ::RL10GbGen::StreamConfig $id $stream_id $txPort $rxPort $args]
    if {$ret!=0} {
      return $ret
    }
  } 
  return $ret 
}	
# ***************************************************************************
# **                        RL10GbGen::Start
# ** 
# **  Abstract: Start Etx generators.
# **
# **   Inputs:
# **            ip_ID                   :	       ID of Etx220 returned by Open procedure .
# **            tx_port                 :         Transmit Port
# **            rx_port                 :         Receive Port
# **                              
# **   Outputs: 
# **            0                       :        if success. 
# **            Negative error code or  :        Otherwise.     
# **            error message by RLEH 	 				
# **                              
# ** Example:                        
# **	 ::RL10GbGen::Start 1 1 2 
# ***************************************************************************
proc Start {ip_ID tx_port rx_port} {
  if {$tx_port==$rx_port} {
    set portL [list $tx_port]
  } else {
    set portL [list $tx_port $rx_port]
  }  
  
  foreach port $portL {
      set ret [::RL10GbGen::StreamClearRmon $ip_ID [::RL10GbGen::ParsePortNum2IntNum $port]]
    if {$ret!=0} {
      return $ret
    }
  }
  
  foreach port $portL {
    set stream_id [expr {$port-1}]
    set ret [::RL10GbGen::StreamStart $ip_ID $stream_id]
    if {$ret!=0} {
      return $ret
    }
  }
  

  return $ret
}
# ***************************************************************************
# **                        RL10GbGen::Stop
# ** 
# **  Abstract: Stop Etx generators.
# **
# **   Inputs:
# **            ip_ID                   :	       ID of Etx220 returned by Open procedure .
# **            tx_port                 :         Transmit Port
# **            rx_port                 :         Receive Port
# **                              
# **   Outputs: 
# **            0                       :        if success. 
# **            Negative error code or  :        Otherwise.     
# **            error message by RLEH 	 				
# **                              
# ** Example:                        
# **	 ::RL10GbGen::Stop 1 1 2 
# ***************************************************************************
proc Stop {ip_ID tx_port rx_port} {
  if {$tx_port==$rx_port} {
    set portL [list $tx_port]
  } else {
    set portL [list $tx_port $rx_port]
  }  
  foreach port $portL {
    set stream_id [expr {$port-1}]
    set ret [::RL10GbGen::StreamStop $ip_ID $stream_id]
    if {$ret!=0} {
      return $ret
    }
  }
  after 1000
  return $ret
}
# ***************************************************************************
# **                        RL10GbGen::Read
# ** 
# **  Abstract: Read statistics.
# **
# **   Inputs:
# **            ip_ID                   :	       ID of Etx204A returned by Open procedure .
# **            tx_port                 :         Transmit Port
# **            rx_port                 :         Receive Port
# **            aRes                    :         array for Statistics. 
# **  2 groups of statistics are existing - for port: aRes(port.1.ClassificationErrors)
# **                              and for OAM stream: aRes(strm.1.DataIntegrityErrors)
# **                              
# **   Outputs: 
# **            0                       :        if success. 
# **            Negative error code or  :        Otherwise.     
# **            error message by RLEH 	 				
# **                              
# ** Example:                        
# **	 ::RL10GbGen::Read 1 1 2 gaRes  
# ***************************************************************************
proc Read {ip_ID tx_port rx_port a} {
  upvar $a arrRes
  if {$tx_port==$rx_port} {
    set portL [list $tx_port]
  } else {
    set portL [list $tx_port $rx_port]
  }  
  foreach port $portL {
    set stream_id [expr {$port-1}]
    set ret [::RL10GbGen::StreamReadStatistics $ip_ID $stream_id arrRes]
    if {$ret!=0} {
      return $ret
    }
  }
  return $ret
}

# ***************************************************************************
# **                        RL10GbGen::Check
# ** 
# **  Abstract: Check statistics.
# **
# **   Inputs:
# **            ip_ID   :	ID of Etx204A returned by Open procedure .
# **            tx_port :  Transmit Port
# **            rx_port :  Receive Port
# **            aRes    :  array of Statistics
# **                    
# **   Outputs: 
# **            0       : if the following port's counters are 0: ClassificationErrors,
# **  RxCrcErrors, RxJabbers, RxMacError, RxMacOverflow, RxOversizePackets, RxShortPackets,
# **  TotalTxDroppedPackets, TxOversizePackets
# **                      and if the following OAM stream's counters are 0: DataIntegrityErrors, DataSequenceErrors
# **                      and if the following port's counters are not 0: RxOctets, RxPkts, TxOctets, TxPkts 
# **                      and if the following OAM stream's counters are not 0: RxByte, RxPacket, TxByte, TxPacket 
# **                      and if TxPkts of tx_port = RxPkts of rx_port
# **                      and if TxPkts of rx_port = RxPkts of tx_port 
# **                      and if TxOctets of tx_port = RxOctets of rx_port
# **                      and if TxOctets of rx_port = RxOctets of tx_port 
# **                      and if TxPacket of tx_port's OAM stream = RxPacket of rx_port's OAM stream
# **                      and if TxPacket of rx_port's OAM stream = RxPacket of tx_port's OAM stream
# **                      and if TxByte of tx_port's OAM stream = RxByte of rx_port's OAM stream
# **                      and if TxByte of rx_port's OAM stream = RxByte of tx_port's OAM stream
# **            Negative error code or  :        Otherwise.     
# **            error message by RLEH 	 				
# **                              
# ** Example:                        
# **	 ::RL10GbGen::Check 1 1 2 gaRes  
# ***************************************************************************

proc Check {ip_ID tx_port rx_port a} {
  global gMessage
  set gMessage ""
  set portTitle 0
  set strmTitle 0
  upvar $a arrRes
  if {$tx_port==$rx_port} {
    set portL [list $tx_port]
  } else {
    set portL [list $tx_port $rx_port]
  }
  set portZeroPrmL [list ClassificationErrors RxCrcErrors RxJabbers RxMacError\
      RxMacOverflow RxOversizePackets RxShortPackets TotalTxDroppedPackets\
      TxOversizePackets]
  set portNoneZeroPrmL [list RxOctets RxPkts TxOctets TxPkts]     
  set strmZeroPrmL [list DataIntegrityErrors DataSequenceErrors]   
  set strmNoneZeroPrmL [list RxByte RxPacket TxByte TxPacket]
  foreach port $portL {    
    foreach prm $portZeroPrmL {
      set val $arrRes($ip_ID.port.$port.$prm)
      if {$val!=0} {
        if {$portTitle==0} {
          append gMessage "Ports' statistics:\r"
          set portTitle 1 
        }
        append gMessage "The \'$prm\' of port $port is $val. Should be 0. \r"
        # return -1
        # puts "port $port prm:$prm val:$val"
      }  
    }
    foreach prm $portNoneZeroPrmL {
      set val $arrRes($ip_ID.port.$port.$prm)
      if {$val==0} {
        append gMessage "The \'$prm\' of port $port is 0. \r"
        # return -1
        # puts "port $port prm:$prm val:$val"
      }  
    } 
    
  }  
  if {$arrRes($ip_ID.port.$tx_port.TxPkts)!=$arrRes($ip_ID.port.$rx_port.RxPkts)} {
    append gMessage "The \'TxPkts\' of port $tx_port is $arrRes($ip_ID.port.$tx_port.TxPkts)\
        The \'RxPkts\' of port $rx_port is $arrRes($ip_ID.port.$rx_port.RxPkts). \r"
    # return -1  
  }
  if {$arrRes($ip_ID.port.$tx_port.TxOctets)!=$arrRes($ip_ID.port.$rx_port.RxOctets)} {
    append gMessage "The \'TxOctets\' of port $tx_port is $arrRes($ip_ID.port.$tx_port.TxOctets)\
        The \'RxOctets\' of port $rx_port is $arrRes($ip_ID.port.$rx_port.RxOctets). \r"
    # return -1  
  }
  if {$arrRes($ip_ID.port.$rx_port.TxPkts)!=$arrRes($ip_ID.port.$tx_port.RxPkts)} {
    append gMessage "The \'TxPkts\' of port $rx_port is $arrRes($ip_ID.port.$rx_port.TxPkts)\
        The \'RxPkts\' of port $tx_port is $arrRes($ip_ID.port.$tx_port.RxPkts). \r"
    # return -1  
  }
  if {$arrRes($ip_ID.port.$rx_port.TxOctets)!=$arrRes($ip_ID.port.$tx_port.RxOctets)} {
    append gMessage "The \'TxOctets\' of port $rx_port is $arrRes($ip_ID.port.$rx_port.TxOctets)\
        The \'RxOctets\' of port $tx_port is $arrRes($ip_ID.port.$tx_port.RxOctets). \r"
    # return -1  
  }
  if {$gMessage!=""} {
    append gMessage \r
  }
  foreach port $portL {
    foreach prm $strmZeroPrmL {
      set stream_id $port
      set val $arrRes($ip_ID.strm.$stream_id.$prm)
      if {$val!=0} {
        if {$strmTitle==0} {
          append gMessage "Streams' statistics:\r"
          set strmTitle 1 
        }
        append gMessage "The \'$prm\' of stream $stream_id is $val. Should be 0. \r"
        # return -1
      }  
      # puts "stream_id $stream_id prm:$prm val:$val"
    } 
    foreach prm $strmNoneZeroPrmL {
      set stream_id $port
      set val $arrRes($ip_ID.strm.$stream_id.$prm)
      if {$val==0} {
        append gMessage "The \'$prm\' of stream $stream_id is 0. \r"
        # return -1
      }  
      # puts "stream_id $stream_id prm:$prm val:$val"
    }
    set stream_id $port
    if {$arrRes($ip_ID.strm.$stream_id.TxPacket)!=$arrRes($ip_ID.strm.$stream_id.RxPacket)} {
      append gMessage "The \'TxPacket\' of stream $stream_id is $arrRes($ip_ID.strm.$stream_id.TxPacket)\
          The \'RxPacket\' is $arrRes($ip_ID.strm.$stream_id.RxPacket). \r"
      # return -1  
    }
    if {$arrRes($ip_ID.strm.$stream_id.TxByte)!=$arrRes($ip_ID.strm.$stream_id.RxByte)} {
      append gMessage "The \'TxByte\' of stream $stream_id is $arrRes($ip_ID.strm.$stream_id.TxByte)\
          The \'RxByte\' is $arrRes($ip_ID.strm.$stream_id.RxByte). \r"
      # return -1  
    }
  }
  
#   foreach port $portL {
#     set stream_id $port
#     if {$arrRes(strm.$stream_id.TxPacket)!=$arrRes(strm.$stream_id.RxPacket)} {
#       append gMessage "The \'TxPacket\' is $arrRes(strm.$stream_id.TxPacket)\
#           The \'RxPacket\' is $arrRes(strm.$stream_id.RxPacket). \r"
#       # return -1  
#     }
#   }
  if {$gMessage==""} {
    return 0
  } else {
    set gMessage [string trimright $gMessage \r]
    return -1
  }   
}		 
# *******************************************************************************
# **                        RL10GbGen::Close
# ** 
# **  Abstract: Close Etx204A.
# **
# **   Inputs:
# **            ip_ID                   :	       ID of Etx204A returned by Open procedure .
# **                              
# **   Outputs: 
# **            0                       :        if success. 
# **            Negative error code or  :        Otherwise.     
# **            error message by RLEH 	 				
# **                              
# ** Example:                        
# **	 ::RL10GbGen::Close 1   
# ******************************************************************************
proc Close {ip_ID} {

  global        g10GbGenBuffer
  global        gMessage
  variable      va10GbGenStatuses 
  variable      vOpened10GbGenHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0


  if {![info exists va10GbGenStatuses($ip_ID,10GbGenID)]} {
  	set	gMessage "Close procedure: The Etx204A with ID=$ip_ID doesn't opened"
    return $fail
  }

  switch -exact -- $va10GbGenStatuses($ip_ID,connection)  {
    

			com {
          if {$va10GbGenStatuses($ip_ID,package) == "RLCom"} {
            RLCom::Close $va10GbGenStatuses($ip_ID,10GbGenHandle)
          } else {
              RLSerial::Close $va10GbGenStatuses($ip_ID,10GbGenHandle)
          }
      }

			telnet {
        if {$va10GbGenStatuses($ip_ID,package) == "RLTcp"} {
           RLTcp::TelnetClose  $va10GbGenStatuses($ip_ID,10GbGenHandle)
        } elseif {$va10GbGenStatuses($ip_ID,package) == "RLPlink"} {
				    RLPlink::Close $va10GbGenStatuses($ip_ID,10GbGenHandle)
        }
      }
  }

  unset va10GbGenStatuses($ip_ID,10GbGenID)
  unset va10GbGenStatuses($ip_ID,10GbGenHandle)
  unset va10GbGenStatuses($ip_ID,connection)
  unset va10GbGenStatuses($ip_ID,package)

  return $ok
}


# ***************************************************************************
# **                        RL10GbGen::CloseAll
# ** 
# **  Abstract: Close all Etx220.
# **
# **   Inputs:
# **                              
# **   Outputs: 
# **            0                       :        if success. 
# **            Negative error code or  :        Otherwise.     
# **            error message by RLEH 	 				
# **                              
# ** Example:                        
# **	 ::RL10GbGen::CloseAll  
# ***************************************************************************
proc CloseAll {} {

  global        g10GbGenBuffer
  global        gMessage
  variable      va10GbGenStatuses 
  variable      vOpened10GbGenHistoryCounter
  set gMessage ""                   
	set fail          -1
	set ok             0

	for {set i 1} {$i <= $vOpened10GbGenHistoryCounter} {incr i} {
		if {[info exists va10GbGenStatuses($i,10GbGenID)]} {
		  ::RL10GbGen::Close $va10GbGenStatuses($i,10GbGenID)
		}
	}
  set  vOpened10GbGenHistoryCounter 0
}
# ***************************************************************************
# **                        RL10GbGen::Clear
# ** 
# **  Abstract: Clear Etx generator's Statistics.
# **
# **   Inputs:
# **            ip_ID                   :	       ID of Etx220 returned by Open procedure .
# **            tx_port                 :         Transmit Port
# **            rx_port                 :         Receive Port
# **                              
# **   Outputs: 
# **            0                       :        if success. 
# **            Negative error code or  :        Otherwise.     
# **            error message by RLEH 	 				
# **                              
# ** Example:                        
# **	 ::RL10GbGen::Clear 1 1 2 
# ***************************************************************************
proc Clear {ip_ID tx_port rx_port} {
  if {$tx_port==$rx_port} {
    set portL [list $tx_port]
  } else {
    set portL [list $tx_port $rx_port]
  }  
  foreach port $portL {
    set stream_id [expr {$port-1}]
    set ret [::RL10GbGen::StreamClearStatistics $ip_ID $stream_id]
    if {$ret!=0} {
      return $ret
    }
  }
  after 1000
  return $ret
}
# ***************************************************************************
# **                        RL10GbGen::ShowGui
# ** 
# **  Abstract: Show Gui of generator.
# **
# **   Inputs:
# **            ip_ID                   :	       ID of EGate-100 returned by Open procedure will be into resource entry in select mode.
# **                              
# **            args   parameters and their value:
# **
# **                -idlist                       IDs of others EGate-100 returned by Open procedure will be into resource entry.
# **								 -showHide										 SHOW/HIDE/ICONIFY
# **								 -closeChassis								 yes/no close chassis while destroy
# **
# **   Outputs: 
# **            0                       :        if success. 
# **            Negativ error cod or    :        Otherwise.     
# **            error message by RLEH 	 				
# **                              
# ** Example:                        
# **	 ::RL10GbGen::ShowGui 1 -idlist "2 3" -showHide	SHOW	-closeChassis no
# ***************************************************************************

proc ShowGui {ip_ID args} {

  global        g10GbGenBuffer
  global        gMessage
  variable      va10GbGenStatuses 
  variable      va10GbGenGui
  variable      va10GbGenSet
  variable      va10GbGenCfg

	set	showHide	 0
	set statistics 4
	set base       .top10GbGenGui
	set fail -1

  if {$ip_ID == "?"} {
    return "arguments options:  -idlist , -showHide"
  }

  if {![info exists va10GbGenStatuses($ip_ID,10GbGenID)]} {
  	set	gMessage "ShowGui procedure: The Egate-100 with ID=$ip_ID doesn't opened"
		tk_messageBox -icon error -type ok -message $gMessage -title "Etx204A Generator"
    return $fail
    # return [RLEH::Handle SAsyntax gMessage]
  }

  if {$va10GbGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "ShowGui procedure: The plink process doesn't exist for Etx204A Generator with ID=$ip_ID"
      return $fail
    }
  }

	# processing command line parameters
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
										  		tk_messageBox -icon error -type ok -message $gMessage -title "Etx204A Generator"
										      return $fail
	                       # return [RLEH::Handle SAsyntax gMessage]
												}
											  if {![info exists va10GbGenStatuses($ind,10GbGenID)]} {
											  	set	gMessage "ShowGui procedure: The Etx204A Generator with ID=$ind of idlist: $val doesn't opened"
										  		tk_messageBox -icon error -type ok -message $gMessage -title "Etx204A Generator"
										      return $fail
											    # return [RLEH::Handle SAsyntax gMessage]
											  }
											}
											set idlist $val
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


  ::RL10GbGen::Make10GbGenGui
  ::RL10GbGen::OkConnChassis $va10GbGenStatuses($ip_ID,10GbGenHandle) $va10GbGenStatuses($ip_ID,package) $ip_ID connectChs

	if {[info exists idlist]} {
	  foreach chass $idlist {
      ::RL10GbGen::OkConnChassis $va10GbGenStatuses($chass,10GbGenHandle) $va10GbGenStatuses($chass,package) $chass connectChs
      # $va10GbGenGui(resources,list) insert end  chassis:$chass -text  "chassis $chass" -fill red -indent 10 -font {times 14}
		}
	}
	# $va10GbGenGui(notebook) raise [$va10GbGenGui(notebook) page statistics]

	if {[info exists closeChassis]} {
	  set va10GbGenSet(closeByDestroy) $closeChassis
	}

}



# ***************************************************************************
# ***************************************************************************
#
#                  INTERNAL FUNCTIONs
#
# ***************************************************************************
# ***************************************************************************
# ***************************************************************************
# About
# ***************************************************************************
proc About {} {
  tk_messageBox -icon info -type ok \
  -message "10GbE ETX220 Tool\n 1.3.2 09/07/2014 \n Copyright © 2013, Rad Data Communications"\
  -title "About 10GbE ETX220 Tool"
}

# ***************************************************************************
# Make10GbGenGui
# ***************************************************************************
proc Make10GbGenGui {} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
 
  set rundir [file dirname [info script]]  
  
	if {[regexp -nocase {10GbGen.exe} $rundir match]} {
    # for starpacks applications
		set dir [string range $rundir 0 [string last / $rundir]]
    set va10GbGenSet(rundir) [append dir 10GbGen]
		set va10GbGenSet(starpack) 1
	} else {
    set va10GbGenSet(rundir) C:/RLFiles/10GbGen
		set va10GbGenSet(starpack) 0
	}
  if [file exist [pwd]/inits/init.tcl] {
    source [pwd]/inits/init.tcl
  } else {
    set ::RL10GbGen::va10GbGenSet(connect,com) 1
    set ::RL10GbGen::va10GbGenSet(connect,telnet) "172.18.92.1"
    set ::RL10GbGen::va10GbGenSet(connectBy) 1
    set ::RL10GbGen::va10GbGenSet(listIP) [list {} 172.18.92.1]
    set ::RL10GbGen::va10GbGenSet(clockFreq)  150
    set ::RL10GbGen::va10GbGenSet(readStreamEach)  5  
    set ::RL10GbGen::va10GbGenSet(lastEthType)  00ff
  }

  # set va10GbGenSet(listIP)	 ""
	# set va10GbGenSet(connect,com) ""
	# set va10GbGenSet(connect,telnet) ""
  set va10GbGenSet(comPackage)	 RLSerial
	
	set base .top10GbGenGui
	toplevel $base -class Toplevel		
  wm focusmodel $base passive
	wm overrideredirect $base 0
  wm title $base "10GbEth ETX220 Tool"
  wm protocol $base WM_DELETE_WINDOW {::RL10GbGen::Quit}
  wm protocol $base WM_SAVE_YOURSELF {::RL10GbGen::Quit}
  wm geometry .top10GbGenGui +25+25
  # wm resizable $base 0 0

	if {$va10GbGenSet(starpack)} {
    wm geometry $base 900x650
	} else {
    wm geometry $base 900x630
	}
	bind .top10GbGenGui <F1> {set gConsole show; console show} 

  variable notebook
  variable mainframe

  set va10GbGenSet(prgtext) "Please wait while loading font..."
  set va10GbGenSet(prgindic) -1
  _create_intro
  update
  SelectFont::loadfont
	set va10GbGenSet(currentid) ""

  set descmenu {
    "&File" {} {} 0 {		
	     {cascad "&Console" {} console 0 {
         {checkbutton "Console activation" {} "Console activation" {} \
		       -command {} -variable ::RL10GbGen::g10GbGenBufferDebug}
         {separator}
		     {radiobutton "console show" {} "Console Show" {} \
		       -command "console show" -value show -variable gConsole}
		     {radiobutton "console hide" {} "Console Hide" {} \
		       -command "console hide" -value hide -variable gConsole}
         {separator}  
         {command "Save Console" console "Save Console" {} \
           -command {
             global gaSet
             ::RL10GbGen::CaptureConsole [file normalize c:/tmpTmp]
           }
         }
		   }
		   }       
			 {command	"Get Configuration from file..." {getcfgfile} {} {} -command {::RL10GbGen::GetConfigFromFile cfg}}
			 {command	"Save Configuration to file..." {savecfgfile} {} {} -command {::RL10GbGen::SaveConfigToFile cfg}}
	     {separator}
	     		
	     {command "Exit" {quit} {Exit} {} -command {::RL10GbGen::Quit}}		
	   }	
 	  
 	  "&Connection" {} {} 0 {
	      {command "Connect Chassis..." {connect} {} {} -command {::RL10GbGen::ConnectChassis}}
	      {command "Disconnect Chassis" {disconnect} {} {} -command {::RL10GbGen::Del10GbGenResource}}
		  }
 	  "&Tools" {} {} 0 {
  	    {command "Etx220 Global Init" {reset} {} {} -command {::RL10GbGen::FactoryEtx}}
  	    {command "E-mail setting" {email} {} {} -command {::RL10GbGen::10GbGenEmailSet .mail}}
        {command "Advanced setup" {email} {} {} -command {::RL10GbGen::FineTuningGui}}
		  }
    "&Help" {} {} 0 {
         {command "&Index" {} {} {} -command {::RL10GbGen::GetHelp}}
         {command "&About 10GbE ETX220 Tool" {} {} {} -command {::RL10GbGen::About}}
			 }
  } 
#  {command "Destroy" {exit} {Exit} {} -command {::RL10GbGen::Close10GbGenGui}}
#   "&Run" {} {} 0 {
#  	      {command "Run Generator" {run} {} {} -command {::RL10GbGen::CurrentChassisRun $::RL10GbGen::va10GbGenSet(currentid)}}
# 		  }
#   						{command	"Set Configuration to chassis" {savecfgchass} {} {} -command {::RL10GbGen::SaveConfigToChassis}}
# 	          {separator}
# 						{command	"Save GUI config to file..." {saveguicfgfile} {} {} -command {::RL10GbGen::SaveConfigToFile ini}}
# 						{command	"Get GUI config from file..." {getguicfgfile} {} {} -command {::RL10GbGen::GetConfigFromFile ini}}

  set mainframe [MainFrame $base.mainframe -menu $descmenu \
     -textvariable ::RL10GbGen::va10GbGenGui(status) -progressvar va10GbGenGui(prgindic)]
#   set va10GbGenGui(startTime) [$mainframe addindicator]
#   set va10GbGenGui(runTime) [$mainframe addindicator]
#   set va10GbGenGui(runStatus) [$mainframe addindicator]
  $mainframe showstatusbar status 

  .top10GbGenGui.mainframe setmenustate reset  disabled
  

 # toolbar  creation
  incr va10GbGenSet(prgindic)
  set tb  [$mainframe addtoolbar]
  set indx 1
  set bbox [ButtonBox $tb.bbox[set indx] -spacing 0 -padx 1 -pady 1]
  set va10GbGenGui(tb,save) [$bbox add -image [image create photo -file $va10GbGenSet(rundir)/Images/saveas.ico] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {::RL10GbGen::SaveConfigToFile cfg} \
      -helptext "Save configuration  to a file"]
  set va10GbGenGui(tb,open) [$bbox add -image [image create photo -file $va10GbGenSet(rundir)/Images/open2.ico] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {::RL10GbGen::GetConfigFromFile cfg} \
      -helptext "Get configuration from a existing file"]
  

	lappend  va10GbGenSet(lDisabledEntries) $va10GbGenGui(tb,open) $va10GbGenGui(tb,save)
  pack $bbox -side left -anchor w
  
  incr indx
  set sep [Separator $tb.sep[set indx] -orient vertical]
  pack $sep -side left -fill y -padx 4 -anchor w

  incr indx
  set bbox [ButtonBox $tb.bbox[set indx] -spacing 0 -padx 1 -pady 1]
  set va10GbGenGui(tb,connect) [$bbox add -image [image create photo -file $va10GbGenSet(rundir)/Images/connect1.ico] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {::RL10GbGen::ConnectChassis} \
      -helptext "Connect a chassis"]
  set va10GbGenGui(tb,help) [$bbox add -image [image create photo -file $va10GbGenSet(rundir)/Images/about2.ico] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {::RL10GbGen::GetHelp} \
      -helptext "Help topics"]
  pack $bbox -side left -anchor w
  
  incr indx
  set sep [Separator $tb.sep[set indx] -orient vertical]
  pack $sep -side left -fill y -padx 4 -anchor w

  incr indx
  set bbox [ButtonBox $tb.bbox[set indx] -spacing 0 -padx 1 -pady 1]
  set va10GbGenGui(tb,run) [$bbox add -image [image create photo -file $va10GbGenSet(rundir)/Images/run1.ico] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {::RL10GbGen::ButRun} \
      -helptext "Start Transmit"]
  set va10GbGenGui(tb,stop) [$bbox add -image [image create photo -file $va10GbGenSet(rundir)/Images/stop1.ico] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 -command {::RL10GbGen::ButStop} \
      -helptext "Stop Transmit"]
  set va10GbGenGui(tb,clr) [$bbox add -image [image create photo -file $va10GbGenSet(rundir)/Images/clear3.ico] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 \
      -command {::RL10GbGen::ButClearStats} \
      -helptext "Clear Statistics"]
  pack $bbox -side left -anchor w
  
  lappend  va10GbGenSet(lDisabledEntries) $va10GbGenGui(tb,run) $va10GbGenGui(tb,stop) $va10GbGenGui(tb,clr)
  
  incr indx
  set sep [Separator $tb.sep[set indx] -orient vertical]
  pack $sep -side left -fill y -padx 4 -anchor w
  
  incr indx
  set bbox [ButtonBox $tb.bbox[set indx] -spacing 0 -padx 1 -pady 1]  
  set va10GbGenGui(tb,gi) [$bbox add -image [image create photo -file $va10GbGenSet(rundir)/Images/setup1.ico] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 \
      -command {::RL10GbGen::FactoryEtx} -helptext "Chassis Global Init"]  
  $va10GbGenGui(tb,gi) configure -state disabled    
  pack $bbox -side left -anchor w
  
  incr indx
  set sep [Separator $tb.sep[set indx] -orient vertical]
  pack $sep -side left -fill y -padx 4 -anchor w
  
  incr indx
  set bbox [ButtonBox $tb.bbox[set indx] -spacing 0 -padx 1 -pady 1]  
    set va10GbGenGui(tb,streamEnDis) [$bbox add -image [image create photo -file $va10GbGenSet(rundir)/Images/enDis1_w.ico] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 \
      -command {::RL10GbGen::ToogleAllStreamsEnable} -helptext "Toggle Enable/Disable of configured streams"]  
    set va10GbGenGui(tb,streamDel) [$bbox add -image [image create photo -file $va10GbGenSet(rundir)/Images/delete1_w.ico] \
      -highlightthickness 0 -takefocus 0 -relief link -borderwidth 1 -padx 1 -pady 1 \
      -command {::RL10GbGen::DeleteConfiguredStreams} -helptext "Delete configured streams"]    
  pack $bbox -side left -anchor w

  # Resource pane creation
  set frame    [$mainframe getframe]

  set pw    [PanedWindow $frame.pw -side top]

  set pane  [$pw add -weight 1]
  set title [TitleFrame $pane.lf -text "Resources"]
  set va10GbGenGui(resources,sw)  [set sw [ScrolledWindow [$title getframe].sw -relief sunken -borderwidth 2]]

  set va10GbGenGui(resources,list) [Tree $va10GbGenGui(resources,sw).lb \
      -relief flat -borderwidth 0 -dragevent 3 -dropenabled 1 -width 30 -highlightthickness 0 -bg white\
      -redraw 0 -dragenabled 0 \
      -droptypes {
          TREE_NODE    {copy {} move {} link {}}
          LISTBOX_ITEM {copy {} move {} link {}}
      } \
      -opencmd   {} -closecmd  {}]
  set tree $::RL10GbGen::va10GbGenGui(resources,list)  
  $va10GbGenGui(resources,list) insert end root home -open 1 -text "Resources" -image [image create photo -file $va10GbGenSet(rundir)/Images/resources1.ico]
  $tree bindText  <ButtonRelease-1>         "::RL10GbGen::TreeSelect tree 1 $tree %X %Y"
  $tree bindText  <Double-ButtonPress-1>  "::RL10GbGen::TreeSelect tree 2 $tree %X %Y"
  $tree bindImage <ButtonRelease-1>         "::RL10GbGen::TreeSelect tree 1 $tree %X %Y"
  # $tree bindImage <Double-ButtonPress-1> "::RL10GbGen::TreeSelect tree 2 $tree %X %Y"
  $tree bindText  <ButtonRelease-3>       "::RL10GbGen::TreeSelect tree 3 $tree %X %Y"
  $tree opentree home                    

  $va10GbGenGui(resources,sw) setwidget $va10GbGenGui(resources,list)
	set va10GbGenSet(resources,list) ""

  pack $va10GbGenGui(resources,sw) -fill both -expand yes
  pack $title -fill both  -expand yes

 
  	# General configuration frame creation
  # ===========================================================================================
  set frameB [frame $frame.frameB -bd 0 -relief groove]
  set va10GbGenSet(prgtext)   "Creating General parameters..."
  
  set va10GbGenGui(global) [TitleFrame $frameB.global -text "Global"]
    set fr [$va10GbGenGui(global) getframe]
    set fr1 [frame $fr.fr1 -bd 0 -relief groove]
      set helptxt ""
      set l1 [Label $fr1.l1 -text "Total Data Bit Rate Usage, %  "]
      set l2 [Label $fr1.l2 -width 16 -textvariable ::RL10GbGen::va10GbGenSet(global,totalBitRate) -bd 2 -relief sunken]
      set va10GbGenGui(global,totalBitRate) $l2
      $::RL10GbGen::va10GbGenGui(global,totalBitRate) configure -helptext $helptxt  
      set l3 [Label $fr1.l3 -text "%"]
      pack $l1 $l2  -side left
    pack $fr1 -anchor w
    
    set helptxt "Any change in this filed will affect all other active streams...\r\
        Change will take place in the coming stream configuration"
    set fr2 [frame $fr.fr2 -bd 0 -relief groove]
      set l1 [Label $fr2.l1 -text "MIN packet size, \[64...1999\]" -helptext $helptxt]
      set l2 [Label $fr2.l2 -text "MAX packet size, \[65...2000\]" -helptext $helptxt]
      set l3 [Label $fr2.l3 -text "IPG, \[8...31\]" -helptext $helptxt]
      set l4 [Label $fr2.l4 -text "Sequence error threshold, \[0...128\]" -helptext $helptxt]
      set l5 [Label $fr2.l5 -text "Clock frequency, \[MHz\]" -helptext $helptxt]
      set ent1 [spinbox $fr2.ent1 -justify center -from 64 -to 1999 -increment 1 -validate key -vcmd {expr [string is integer %P]}]
      set va10GbGenGui(PacketSizeMin) $ent1 
      DynamicHelp::add $ent1 -text $helptxt
      set ent2 [spinbox $fr2.ent2 -justify center -from 65 -to 2000 -increment 1 -validate key -vcmd {expr [string is integer %P]}]
      set va10GbGenGui(PacketSizeMax) $ent2  
      $ent2 set 2000
      DynamicHelp::add $ent2 -text $helptxt
      set ent3 [spinbox $fr2.ent3 -justify center -from 8 -to 31 -increment 1 -validate key -vcmd {expr [string is integer %P]}]
      set va10GbGenGui(IPG) $ent3
      $ent3 set 20
      DynamicHelp::add $ent3 -text $helptxt
      set ent4 [spinbox $fr2.ent4 -justify center -from 1 -to 128 -increment 1 -validate key -vcmd {expr [string is integer %P]}]
      set va10GbGenGui(SeqErThr) $ent4
      $ent4 set 0
      DynamicHelp::add $ent4 -text $helptxt
#       set ent5 [Entry $fr2.ent5 -justify center -text 150 -validate key -vcmd {expr [string is integer %P]}]
#       set va10GbGenGui(clockFreq) [$ent5 cget -text]
      grid $l1 $ent1 -padx 4 -sticky w
      grid $l2 $ent2 -padx 4 -sticky w
      grid $l3 $ent3 -padx 4 -sticky w
      grid $l4 $ent4 -padx 4 -sticky w
      # grid $l5 $ent5
    pack $fr2 -anchor w -padx 2 -pady 4
  pack $va10GbGenGui(global) -fill x -expand 0 -anchor n 
   
  
  set fra [set va10GbGenGui(fra) [frame $frameB.fra -bd 0 -relief groove]]
    set notebook [NoteBook $fra.nb]
    set va10GbGenGui(nb) $notebook
    set va10GbGenGui(nb.setup) [$va10GbGenGui(nb) insert end setup -text "Stream Setup/View"]
    set fraNBA [frame $va10GbGenGui(nb.setup).fraNBA -bd 0 -relief groove] 
          
    set va10GbGenGui(fra,fraStream) [TitleFrame $fraNBA.fraStream -text "Stream"]
      set fr0 [$va10GbGenGui(fra,fraStream) getframe]
      set fr1 [frame $fr0.fr1 -bd 0 -relief groove]
        set l [Label $fr1.l -text Enable]
        set chb [checkbutton $fr1.chb -command {::RL10GbGen::UpdateChassisLineRate ; ::RL10GbGen::ToggleStreamEnable}]
        set va10GbGenGui(StreamEnable) $chb
        pack $l $chb -fill both
      set fr2 [frame $fr0.fr2 -bd 0 -relief groove]
        set b [Button $fr2.b -text "Edit stream's Frame data  " -command [list ::RL10GbGen::GuiStream FrameData]]
        pack $b ; # -fill both -expand 1
      set fr3 [frame $fr0.fr3 -bd 0 -relief groove]
        set b [Button $fr3.b -text "Edit stream's control  " -command [list ::RL10GbGen::GuiStream StreamControl]]
        pack $b ; # -fill both -expand 1        
      pack $fr1 $fr2 $fr3 -side left -padx 3 ; # -fill both -expand 1  
   # pack $va10GbGenGui(fra,fraStream) -fill both -expand 1
    
    set va10GbGenGui(fra,statView) [TitleFrame $fraNBA.statView -text "Stream Statistics View"]
      set fr [$va10GbGenGui(fra,statView) getframe]
      set frClr [frame $fr.frClr]
        set bRun [Button $frClr.bRun -image [image create photo -file $va10GbGenSet(rundir)/Images/run1.ico]\
            -helptext "Run Port" ]
        set va10GbGenGui(bRun) $bRun    
        bind $bRun <ButtonRelease> {::RL10GbGen::PortRun [::RL10GbGen::GetActivePort] %W}         
        
        set bStop [Button $frClr.bStop -image [image create photo -file $va10GbGenSet(rundir)/Images/stop1.ico]\
            -helptext "Stop Port"  -state disabled -relief sunken]
        set va10GbGenGui(bStop) $bStop
        bind $bStop <ButtonRelease> {::RL10GbGen::PortStop [::RL10GbGen::GetActivePort] %W}             
        
        set bClr [Button $frClr.bClr -image [image create photo -file $va10GbGenSet(rundir)/Images/clear3.ico]\
            -helptext "Clear Statistics"  -state disabled -relief sunken\
            -command {::RL10GbGen::ClearStatistics [::RL10GbGen::GetActivePort]}]
        set va10GbGenGui(bClr) $bClr
        bind $bClr <ButtonRelease> {::RL10GbGen::ClearStatistics [::RL10GbGen::GetActivePort] %W}
        pack $bRun $bStop $bClr -pady 2 -padx 2 -side left
      # grid x $frClr -pady 2
      foreach w $::RL10GbGen::vlStreamStatsL {
        if [string match *Rate $w] {
          set txt "${w}, \[bps\]"
        } else {
          set txt $w
        }
        set va10GbGenGui(fra,statView,lbl$w) [Label $fr.lbl$w -text "${txt}: "]
        set va10GbGenGui(fra,statView,ent$w) [Label $fr.ent$w -bd 2 -relief sunken -width 22 -takefocus ""]
        grid $va10GbGenGui(fra,statView,lbl$w) $va10GbGenGui(fra,statView,ent$w) -sticky w
      } 
      
#       set va10GbGenGui(fra,statViewPort) [TitleFrame $fraNBA.statViewPort -text "Port Statistics View"]
#       foreach w $::RL10GbGen::vlPortStatsL {
# #         if [string match *Rate $w] {
# #           set txt "${w}, \[bps\]"
# #         } else {
# #           set txt $w
# #         }
#         set txt $w
#         set va10GbGenGui(fra,statViewPort,lbl$w) [Label $fr.lbl$w -text "${txt}: "]
#         set va10GbGenGui(fra,statViewPort,ent$w) [Label $fr.ent$w -bd 2 -relief sunken -width 22 -takefocus ""]
#         grid $va10GbGenGui(fra,statViewPort,lbl$w) $va10GbGenGui(fra,statViewPort,ent$w) -sticky w
#       }  
      
    set va10GbGenGui(fra,packetView) [TitleFrame $fraNBA.packetView -text "Packet View"]  
    set fr [$va10GbGenGui(fra,packetView) getframe]   
      set sw [ScrolledWindow $fr.sw -relief sunken -borderwidth 0]
        set sf [ScrollableFrame $sw.f]
        $sw setwidget $sf
        set subf [$sf getframe]
      
        set va10GbGenGui(fra,packView,lbl) [Label $subf.lbl -bd 0 -relief sunken -width 65]   
        pack $va10GbGenGui(fra,packView,lbl) -fill both
      pack $sw -fill both -expand yes
    # pack $va10GbGenGui(fra,statView) -anchor w
    

  
  set va10GbGenGui(nb.stats) [$va10GbGenGui(nb) insert end stats -text "Stream Statistics View"]
  set fraNBB [frame $va10GbGenGui(nb.stats).fraNBB -bd 0 -relief groove]
  
    set sw [ScrolledWindow $fraNBB.sw  -relief sunken -borderwidth 2]
      set sf [ScrollableFrame $sw.sf -height 420 -width 480]
      # set ::sf2 $sf
      $sw setwidget $sf
        set frTit [frame [$sf getframe].frTit -bd 0 -relief groove]
          foreach w "str $::RL10GbGen::vlStreamStatsL" {
            if {$w=="str"} {
              set lab$w [Label $frTit.lab$w -text "" -bd 0 -relief sunken]
            } else {
              if [string match *Rate $w] {
                set txt "${w}, \[bps\]"
              } else {
                set txt $w
              }
              set lab$w [Label $frTit.lab$w -text $txt -bd 0 -relief sunken]
            }
            
            pack [set lab$w] -pady 2 -anchor w -padx 2
          }
        pack $frTit -side left
        # # only 2 chasisses are available
        for {set chId 1} {$chId<=2} {incr chId} {
          for {set i 1} {$i<=8} {incr i} {
            set frStat[set chId]$i [frame [$sf getframe].frStat[set chId]$i -bd 0 -relief groove]
            foreach w "str $::RL10GbGen::vlStreamStatsL"  {
              set lab$w [Label [set frStat[set chId]$i].lab$w  -bd 0 -relief groove -justify right]
              set va10GbGenGui(stats.$chId.$i.$w) [set lab$w] 
              pack [set lab$w] -pady 2 -anchor e -padx 2
            }
            pack [set frStat[set chId]$i] -side left
          }
        }
    pack $sw -fill x -expand 1 
    
    set va10GbGenGui(nb.statsPort) [$va10GbGenGui(nb) insert end statsPort -text "Port Statistics View"]
    set fraNCC [frame $va10GbGenGui(nb.statsPort).fraNCC -bd 0 -relief groove]
  
    set sw [ScrolledWindow $fraNCC.sw  -relief sunken -borderwidth 2]
      set sf [ScrollableFrame $sw.sf -height 420 -width 480]
      # set ::sf2 $sf
      $sw setwidget $sf
        set frTit [frame [$sf getframe].frTit -bd 0 -relief groove]
          foreach w "str $::RL10GbGen::vlPortStatsL" {
            if {$w=="str"} {
              set lab$w [Label $frTit.lab$w -text "" -bd 0 -relief sunken]
            } else {
#               if [string match *Rate $w] {
#                 set txt "${w}, \[bps\]"
#               } else {
#                 set txt $w
#               }
              set lab$w [Label $frTit.lab$w -text $w -bd 0 -relief sunken]
            }
            
            pack [set lab$w] -pady 0 -anchor w -padx 2
          }
        pack $frTit -side left
        
        ## only 2 chasisses are available
        for {set chId 1} {$chId<=2} {incr chId} {
          for {set i 1} {$i<=8} {incr i} {
            set frStat[set chId]$i [frame [$sf getframe].frStat[set chId]$i -bd 0 -relief groove]
            foreach w "str $::RL10GbGen::vlPortStatsL"  {
              set fr [set frStat[set chId]$i]
                set lab.$w [Label $fr.lab1$w  -bd 0 -relief groove -justify right]
                set va10GbGenGui(statsPort.$chId.$i.$w) [set lab.$w] 
#                 set lab.2.$w [Label $fr.lab2$w  -bd 0 -relief groove -justify right]
#                 set va10GbGenGui(statsPort.$chId.$i.2.$w) [set lab.2.$w] 
                # pack [set lab.1.$w] [set lab.2.$w] -side left -pady 2 -anchor e -padx 2
                # grid [set lab.1.$w] [set lab.2.$w] -sticky e -padx 2 -pady 0 
                grid [set lab.$w] -sticky e -padx 2 -pady 0 
              # pack $fr
            } 
            pack [set frStat[set chId]$i] -side left
          }
        }
    pack $sw -fill x -expand 1 
	pack $fraNBA $fraNBB $fraNCC -fill both -expand 1
  $notebook compute_size
  update idletasks
  pack $notebook  -fill both -expand yes -padx 4 -pady 4
  $notebook raise [$notebook page 0]

  pack $fra -fill both -expand 1
  pack $pw $frameB -expand 0 -anchor w -side left
  pack configure $frameB -expand 1  -fill both
  pack configure $pw -fill y 
  pack configure $frameB -fill both
  
  set va10GbGenSet(prgtext)   "Done"
  set va10GbGenSet(prgindic) 10
  pack $mainframe -fill both -expand 1

  update idletasks
  $va10GbGenGui(resources,list) configure -redraw 1

  destroy .intro
  
  ::RL10GbGen::Defaults

  wm deiconify $base
  raise $base
  focus -force $base
  
  $::RL10GbGen::va10GbGenGui(nb) configure -width [expr {[winfo width .top10GbGenGui] - [winfo width .top10GbGenGui.mainframe.frame.pw] - 20}]
  $::RL10GbGen::va10GbGenGui(nb) configure -height [expr {[winfo height .top10GbGenGui] - [winfo height $::RL10GbGen::va10GbGenGui(global)] - 100}]  
    
}
# ***************************************************************************
# GuiStream
# ***************************************************************************
proc GuiStream {pageUp} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  variable va10GbGenSetTmp
  variable vaDefaults
  if ![::RL10GbGen::GlobalSanityCheck] {return}
  set activePort [::RL10GbGen::GetActivePort]
  if {[string match *Port* $activePort]==0} {
    set gMessage  "For configuration please select a port"
		tk_messageBox -icon error -type ok -message "$gMessage" -title "Etx220 Generator"
		return  
  }
   
  set base .topGuiStream
  if [winfo exists $base] {
    raise $base
    wm deiconify $base
    return 0
  }
  array unset va10GbGenSetTmp $activePort.*
  array set va10GbGenSetTmp [array get va10GbGenSet $activePort.*]
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm resizable $base 0 0
  wm geometry $base +[expr {50+[winfo x .top10GbGenGui]}]+[expr {50+[winfo y .top10GbGenGui]}]    ; # 650x370
  wm title $base "Stream Setup in $activePort"
  set frFr [frame $base.frFr]
  set frBut [frame $base.frBut]
    set notebook [NoteBook $frFr.nb]
    set va10GbGenGui(StreamSetupNB) $notebook
      set va10GbGenGui(StreamSetupNB,FrameData) [$notebook insert end FrameData -text "Frame Data"]
        set va10GbGenGui(StreamSetupNB,FrameData,dataPatt) [TitleFrame $va10GbGenGui(StreamSetupNB,FrameData).frdataPatt -text "Data Pattern"]
        set frNB [$va10GbGenGui(StreamSetupNB,FrameData,dataPatt) getframe]
        set fr1 [frame $frNB.fr1]
          set l1 [Label $fr1.l1 -text "Type"]
          set c1 [ComboBox $fr1.c1 -values {AllZeros Incremental Random Repeat} -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.PatternType) \
             -justify center -modifycmd [list ::RL10GbGen::TogglePatternData $activePort] \
              -editable 0 -helptext "Incremental, Random and Repeat Data Pattern configuration may take few seconds (depending on MAX packet size)"]
          set va10GbGenGui(general_setup,generator,PatternType) $c1
          if {$::RL10GbGen::va10GbGenSetTmp($activePort.PatternType)==""} {
            set ::RL10GbGen::va10GbGenSetTmp($activePort.PatternType) $::RL10GbGen::vaDefaults(PatternType)
          }
          
          set l2 [Label $fr1.l2 -text "Data"]   
          for {set i 0} {$i<=255} {incr i} {
            lappend l [format %.2X $i]
          }
          set c2 [ComboBox $fr1.c2 -values $l -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.PatternData) \
              -justify center -modifycmd {} -editable 0]
          set va10GbGenGui(general_setup,generator,PatternData) $c2
          if {$::RL10GbGen::va10GbGenSetTmp($activePort.PatternData)==""} {
            set ::RL10GbGen::va10GbGenSetTmp($activePort.PatternData) $::RL10GbGen::vaDefaults(PatternData) 
          }
          grid $l1 $c1 -sticky news -padx 3 -pady 3
          grid $l2 $c2 -sticky news -padx 3 -pady 3    
        set fr2 [frame $frNB.fr2]
          set b1 [Button $fr2.b1 -text "New" -width 10 -command ::RL10GbGen::PatternNew]
          set va10GbGenGui(general_setup,generator,PatternNew) $b1
          set b2 [Button $fr2.b2 -text "Edit" -width 10 -command ::RL10GbGen::PatternEdit]
          set va10GbGenGui(general_setup,generator,PatternEdit) $b2
          pack $b1 $b2 -anchor w
        pack $fr1  -side left -padx 2  ; # $fr2
        
      
      set rangeL [list [$::RL10GbGen::va10GbGenGui(PacketSizeMin) get] [$::RL10GbGen::va10GbGenGui(PacketSizeMax) get]   1]
      # puts rangeL:$rangeL
      set va10GbGenGui(StreamSetupNB,FrameData,FrameSize) [TitleFrame $va10GbGenGui(StreamSetupNB,FrameData).frdFrameSize -text "Frame Size"]
        set frFS [$va10GbGenGui(StreamSetupNB,FrameData,FrameSize) getframe]
          set tfFrameSizeType  [TitleFrame $frFS.tfFrameSizeType -text "Frame Size Type"]
		        set va10GbGenGui(general_setup,generator,FrameSizeType) [ComboBox [$tfFrameSizeType getframe].cbFrameSizeType \
				        -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.FrameSizeType) \
                -modifycmd [list ::RL10GbGen::ToggleFrameSize $activePort]\
				        -values {Fixed Incr Random EMIX}  -width 11 -justify center \
                -helptext " In \'Increment\' and \'Random\' frame size the Min and Max values are taken from \'Global\' definition frame"]
            if {$::RL10GbGen::va10GbGenSetTmp($activePort.FrameSizeType)==""} {
              set ::RL10GbGen::va10GbGenSetTmp($activePort.FrameSizeType) $::RL10GbGen::vaDefaults(FrameSizeType)
            }
			      pack $va10GbGenGui(general_setup,generator,FrameSizeType) -anchor w

          
          set tfMinLen  [TitleFrame $frFS.tfMinLen -text "Min Pack Len"]
		        set va10GbGenGui(general_setup,generator,minlen) [SpinBox [$tfMinLen getframe].cbminlen \
				        -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.PacketMinLen) -modifycmd {}\
				        -range $rangeL  -width 10 -justify center -helptext "This is the Minimal packet length"]
            set ::RL10GbGen::va10GbGenSetTmp($activePort.PacketMinLen) [lindex $rangeL 0]    
			      pack $va10GbGenGui(general_setup,generator,minlen) -anchor w
  		    
          set tfMaxLen  [TitleFrame $frFS.tfMaxLen -text "Max Pack Len"]
		        set va10GbGenGui(general_setup,generator,maxlen) [SpinBox [$tfMaxLen getframe].cbmaxlen \
				        -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.PacketMaxLen) -modifycmd {}\
				        -range $rangeL  -width 10 -justify center -helptext "This is the Maximal packet length"]
            set ::RL10GbGen::va10GbGenSetTmp($activePort.PacketMaxLen) [lindex $rangeL 1]     
			      pack $va10GbGenGui(general_setup,generator,maxlen) -anchor w
            
          set tfFixLen  [TitleFrame $frFS.tfFixLen -text "Fixed Pack Len"]
		        set va10GbGenGui(general_setup,generator,fixlen) [SpinBox [$tfFixLen getframe].cbfixlen \
				        -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.PacketFixLen) -modifycmd {}\
				        -range $rangeL  -width 10 -justify center -helptext "This is the Fixed packet length"]
            if {$::RL10GbGen::va10GbGenSetTmp($activePort.PacketFixLen)<[lindex $rangeL 0]} {
               set ::RL10GbGen::va10GbGenSetTmp($activePort.PacketFixLen) 1000
            } elseif {$::RL10GbGen::va10GbGenSetTmp($activePort.PacketFixLen)>[lindex $rangeL 1]} {
               set ::RL10GbGen::va10GbGenSetTmp($activePort.PacketFixLen) [lindex $rangeL 1]
            }    
			      pack $va10GbGenGui(general_setup,generator,fixlen) -anchor w
  
          foreach emix {1 2 3 4 5 6 7 8} {
            set tfEmixLen  [TitleFrame $frFS.tfEmixLen$emix -text "EMIX $emix"]
              set va10GbGenGui(general_setup,generator,emix[set emix].en) [checkbutton [$tfEmixLen getframe].chbemixEn$emix \
                  -variable ::RL10GbGen::va10GbGenSetTmp($activePort.PacketEmixEn$emix)]
		          set va10GbGenGui(general_setup,generator,emix[set emix]len) [SpinBox [$tfEmixLen getframe].cbemixlen$emix \
				          -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.PacketEmixLen$emix) -modifycmd {} \
				          -values {64 128 256 512 1024 1280 1518 2000} -editable 0 -width 5 -justify center -helptext "This is the EMIX $emix packet length"]
              if {$::RL10GbGen::va10GbGenSetTmp($activePort.PacketEmixLen$emix)<[lindex $rangeL 0]} {
                 set ::RL10GbGen::va10GbGenSetTmp($activePort.PacketEmixLen$emix) [lindex $rangeL 0]
              } elseif {$::RL10GbGen::va10GbGenSetTmp($activePort.PacketEmixLen$emix)>[lindex $rangeL 1]} {
                 set ::RL10GbGen::va10GbGenSetTmp($activePort.PacketEmixLen$emix) [lindex $rangeL 1]
              }    
			        pack $va10GbGenGui(general_setup,generator,emix[set emix].en) $va10GbGenGui(general_setup,generator,emix[set emix]len) -anchor w
          }  

			  pack $tfFrameSizeType  $tfMinLen $tfMaxLen   -padx 4 -anchor w  ; # left
        # pack $tfMinLen $tfMaxLen  -side left -padx 4
      # pack $va10GbGenGui(StreamSetupNB,FrameData,FrameSize)	-anchor w -fill x  
      
      set va10GbGenGui(StreamSetupNB,FrameData,DASA) [TitleFrame $va10GbGenGui(StreamSetupNB,FrameData).frbaseSaDa \
          -text "MAC DA/SA"]
      set frDASA [$va10GbGenGui(StreamSetupNB,FrameData,DASA) getframe]
        set frBaseDA [frame $frDASA.frBaseDA]
  		    set tfDA  [TitleFrame $frBaseDA.tfDA -text "DA"]
		        set va10GbGenGui(general_setup,generator,DA) [Entry [$tfDA getframe].enDA  -justify center -command {}\
                   -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.DA) -width 15 -relief ridge -editable 1 \
                   -validate key -vcmd {expr {[string is xdigit %P] && [string length %P]<=10}} \
                   -helptext "An user can define only 10 hex digits.\nThe last 2 digits are reserved for internal use." ]
			      pack $va10GbGenGui(general_setup,generator,DA)	-anchor w
			      if {$::RL10GbGen::va10GbGenSetTmp($activePort.DA)==""} {
              set ::RL10GbGen::va10GbGenSetTmp($activePort.DA) $::RL10GbGen::vaDefaults(DA)
            }
          pack $tfDA  -side left -padx 6 -anchor n ; # $tfincrDA $tfstationDA $tfincrDAidle
 			  pack $frBaseDA	-anchor n -pady 2 -side left 
        
        set frBaseSA [frame $frDASA.frBaseSA]
  		    set tfSA  [TitleFrame $frBaseSA.tfSA -text "SA"]
		        set va10GbGenGui(general_setup,generator,SA) [Entry [$tfSA getframe].enSA  -justify center -command {}\
                   -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.SA) -width 15 -relief ridge -editable 1 \
                   -validate key -vcmd {expr {[string is xdigit %P] && [string length %P]<=12}}  ]
			      pack $va10GbGenGui(general_setup,generator,SA)	-anchor w
			      if {$::RL10GbGen::va10GbGenSetTmp($activePort.SA)==""} {
              set ::RL10GbGen::va10GbGenSetTmp($activePort.SA) $::RL10GbGen::vaDefaults(SA)
            }
           pack $tfSA  -side left -padx 6 -anchor n ; # $tfincrDA $tfstationDA $tfincrDAidle
 			  pack $frBaseSA	-anchor n -pady 2 
      # pack $va10GbGenGui(StreamSetupNB,FrameData,DASA)	-anchor w -fill x   
      
#       set va10GbGenGui(StreamSetupNB,FrameData,SeqChecking) [TitleFrame $va10GbGenGui(StreamSetupNB,FrameData).frSeqChecking \
#           -text "Sequence Checking"]
#         set frSC [$va10GbGenGui(StreamSetupNB,FrameData,SeqChecking) getframe]
#           set frSNO [TitleFrame $frSC.frSNO -text "Sequence number offset"]
#           set fr [$frSNO getframe]
#             set va10GbGenGui(SeqChecking,TypeDef) \
#                 [radiobutton $fr.chbDef -text "Default" -value def\
#                 -variable ::RL10GbGen::va10GbGenSetTmp($activePort.SeqNumOffset,Type) \
#                 -command  [list ::RL10GbGen::ToggleSeqNumOffset $activePort]]
#             if {$::RL10GbGen::va10GbGenSetTmp($activePort.SeqNumOffset,Type)==""} {
#               set ::RL10GbGen::va10GbGenSetTmp($activePort.SeqNumOffset,Type) def 
#             }
#             
#             set va10GbGenGui(SeqChecking,TypeUDF) \
#                 [radiobutton $fr.chbUDF -text "UDF" -value udf\
#                 -variable ::RL10GbGen::va10GbGenSetTmp($activePort.SeqNumOffset,Type) \
#                 -command  [list ::RL10GbGen::ToggleSeqNumOffset $activePort]]  
#             
#             set va10GbGenGui(SeqChecking,ValUDF) \
#                 [Entry $fr.entUDF -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.SeqNumOffset,ValUDF)]
#         
#             grid $va10GbGenGui(SeqChecking,TypeDef) -sticky w
#             grid $va10GbGenGui(SeqChecking,TypeUDF) $va10GbGenGui(SeqChecking,ValUDF) -sticky w
#               
#           set lSER [Label $frSC.l -text "Sequence error threshold:  "]
#           set va10GbGenGui(SeqErThr) [Entry $frSC.entSER \
#               -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.SeqErThr) \
#               -validate key -vcmd {expr {[string is integer %P]} } ]
#           if {$::RL10GbGen::va10GbGenSetTmp($activePort.SeqErThr)==""} {
#             set ::RL10GbGen::va10GbGenSetTmp($activePort.SeqErThr) 2
#           }   
#                
#           # grid $frSNO -sticky new -columnspan 2
#           grid $lSER $va10GbGenGui(SeqErThr) -pady 2 -sticky nw                
      
      set frProts [frame $va10GbGenGui(StreamSetupNB,FrameData).frProts]
        set va10GbGenGui(protocols_setup,DLI) [TitleFrame $frProts.dli -text "Data Link Layer"]  
          set frDLI [$va10GbGenGui(protocols_setup,DLI) getframe] 
            set frVlans [frame $frDLI.frVlans -bd 0 -relief groove]
              set va10GbGenGui(VlansEn) [checkbutton $frVlans.chbVlansEn \
                  -variable ::RL10GbGen::va10GbGenSetTmp($activePort.vlans,en) \
                  -command [list ::RL10GbGen::ToggleVlan $activePort] -text "VLAN(s)"]
              set va10GbGenGui(VlansBut) [Button $frVlans.bVlans -text "Edit VLAN(s)" -width 11 -command [list ::RL10GbGen::GuiVlans $activePort]]
              grid $va10GbGenGui(VlansEn) $va10GbGenGui(VlansBut) -sticky w  
              
              set va10GbGenGui(MplsEn) [checkbutton $frVlans.chbMplsEn \
                  -variable ::RL10GbGen::va10GbGenSetTmp($activePort.MplsEn) \
                  -command [list ::RL10GbGen::ToggleMpls $activePort] -text "MPLS"]
              set va10GbGenGui(MplsBut) [Button $frVlans.bMpls -text "Edit MPLS" -width 11]
              # grid $va10GbGenGui(MplsEn) $va10GbGenGui(MplsBut) -sticky w
            
            set frEthII [frame $frDLI.frEthII -bd 0 -relief groove]
              set va10GbGenGui(EthIINone)  [radiobutton $frEthII.rbEthIINone \
                  -value None -variable ::RL10GbGen::va10GbGenSetTmp($activePort.EthIIEn) \
                  -text None -command [list ::RL10GbGen::ToggleEthII $activePort]]
              if {$::RL10GbGen::va10GbGenSetTmp($activePort.EthIIEn)==""} {
                set ::RL10GbGen::va10GbGenSetTmp($activePort.EthIIEn) $::RL10GbGen::vaDefaults(EthIIEn)
              }    
              set va10GbGenGui(EthIIEthII) [radiobutton $frEthII.rbEthIIEthII \
                  -value EthII -variable ::RL10GbGen::va10GbGenSetTmp($activePort.EthIIEn) \
                  -text "Ethernet II" -command [list ::RL10GbGen::ToggleEthII $activePort] ]
              set l [Label $frEthII.l -text "Type"]  
              set va10GbGenGui(EthIIType)  [Entry $frEthII.entEthIIType -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.EthIIType) -width 12]
              if {$::RL10GbGen::va10GbGenSetTmp($activePort.EthIIType)==""} {
                set ::RL10GbGen::va10GbGenSetTmp($activePort.EthIIType) $::RL10GbGen::vaDefaults(EthIIType)
              }    
              
              grid $va10GbGenGui(EthIINone) $l -sticky w  
              grid $va10GbGenGui(EthIIEthII) $va10GbGenGui(EthIIType) -sticky w          
            
#             grid $frVlans -sticky n
#             grid $frEthII -sticky w
            pack $frVlans -anchor n
            pack $frEthII -side bottom
        
        set va10GbGenGui(protocols_setup,Protocols) [TitleFrame $frProts.protocols -text "Protocols"] 
          set frProtocols [$va10GbGenGui(protocols_setup,Protocols) getframe]
            set frIPV4 [frame $frProtocols.frIPV4 -bd 2 -relief groove]
              set va10GbGenGui(IPV4None)  [radiobutton $frIPV4.rbfrIPV4None -text "None" \
                  -value None -variable ::RL10GbGen::va10GbGenSetTmp($activePort.IPV4) \
                  -command [list ::RL10GbGen::ToggleIPV4 $activePort]]
              if {$::RL10GbGen::va10GbGenSetTmp($activePort.IPV4)==""} {    
                set ::RL10GbGen::va10GbGenSetTmp($activePort.IPV4) $::RL10GbGen::vaDefaults(IPV4)
              }
              set va10GbGenGui(IPV4IPV4)  [radiobutton $frIPV4.rbfrIPV4IPV4 -text "IPV4"\
                  -value IPV4 -variable ::RL10GbGen::va10GbGenSetTmp($activePort.IPV4) \
                  -command [list ::RL10GbGen::ToggleIPV4 $activePort]]
              set va10GbGenGui(bIPV4Edit) [Button $frIPV4.bIPV4 -text "Edit" -width 11 \
                  -command [list ::RL10GbGen::GuiIPV4 $activePort]]
              # pack $va10GbGenGui(protocols_setup,IPV4None) $va10GbGenGui(protocols_setup,IPV4IPV4) $va10GbGenGui(protocols_setup,bIPV4Edit) -anchor w
              grid $va10GbGenGui(IPV4None)  $va10GbGenGui(bIPV4Edit) -sticky w              
              grid $va10GbGenGui(IPV4IPV4) -sticky w
              grid configure $va10GbGenGui(bIPV4Edit) -sticky e
            set frIP [frame $frProtocols.frIP -bd 2 -relief groove]
              set va10GbGenGui(IPNone) [radiobutton $frIP.rbfrIPNone -value None -variable ::RL10GbGen::va10GbGenSetTmp($activePort.IP) -text "None"]
              if {$::RL10GbGen::va10GbGenSetTmp($activePort.IP)==""} {    
                set ::RL10GbGen::va10GbGenSetTmp($activePort.IP) $::RL10GbGen::vaDefaults(IP)
              }
              set va10GbGenGui(IPtcp)  [radiobutton $frIP.rbfrIPtcp -value TCP -variable ::RL10GbGen::va10GbGenSetTmp($activePort.IP) -text "TCP / IP"]
              set va10GbGenGui(IPudp)  [radiobutton $frIP.rbfrIPudp -value UDP -variable ::RL10GbGen::va10GbGenSetTmp($activePort.IP) -text "UDP / IP"]                            
              set va10GbGenGui(IPdhcp) [radiobutton $frIP.rbfrIPdhcp -value DHCP -variable ::RL10GbGen::va10GbGenSetTmp($activePort.IP) -text "DHCP / UDP / IP"]
              set va10GbGenGui(IPgre) [radiobutton $frIP.rbfrIPGre -value GRE -variable ::RL10GbGen::va10GbGenSetTmp($activePort.IP) -text "GRE / IP"]                            
              
              grid $va10GbGenGui(IPNone) -sticky w 
              # grid $va10GbGenGui(IPtcp)  -sticky w ; #  $va10GbGenGui(IPdhcp)  $va10GbGenGui(IPgre)
              # grid $va10GbGenGui(IPudp)  -sticky w
            
            pack $frIPV4 -anchor w -fill x ; #  $frIP 
        
        pack $va10GbGenGui(protocols_setup,DLI) $va10GbGenGui(protocols_setup,Protocols) -side left -padx 2  -fill y 
      
         
      ##grid $va10GbGenGui(StreamSetupNB,FrameData,dataPatt) $va10GbGenGui(StreamSetupNB,FrameData,DASA) -sticky news 
      grid $va10GbGenGui(StreamSetupNB,FrameData,DASA) $frProts -sticky news 
      grid $va10GbGenGui(StreamSetupNB,FrameData,dataPatt)  -sticky new
      grid configure $frProts  -rowspan 2
      grid $va10GbGenGui(StreamSetupNB,FrameData,FrameSize) -sticky new -columnspan 2
      # grid $va10GbGenGui(StreamSetupNB,FrameData,SeqChecking) -sticky news
      
      
      set va10GbGenGui(StreamSetupNB,StreamControl) [$notebook insert end StreamControl -text "Stream Control"]
 
        set frStCt [frame $va10GbGenGui(StreamSetupNB,StreamControl).frStCt -bd 0 -relief groove] 
          set indx 1
          
          set frRP [frame $frStCt.frRP -bd 2 -relief groove] 
            set lRP [Label $frRP.l[set indx] -text "Receive Port:  "]
            set va10GbGenGui(RcvPortList) [ComboBox $frRP.chb[set indx] \
                -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.RcvPort) \
                -modifycmd [list ::RL10GbGen::SetTxPort $activePort]\
                -postcommand [list ::RL10GbGen::UpdateFreeRcvPorts $activePort]] 
                # -values [::RL10GbGen::GetFreeRcvPorts $activePort]
            set va10GbGenGui(butRxPortEqTxPort) [Button $frRP.b[set indx] -text "Connect the port to itself"\
                -command [list ::RL10GbGen::LoopThePort $activePort]]  
            grid $lRP $va10GbGenGui(RcvPortList) -pady 2
            grid $va10GbGenGui(butRxPortEqTxPort) -pady 2 -columnspan 2 -sticky e      
        
          set frBR [frame $frStCt.frBR -bd 2 -relief groove]
            set rb1 [radiobutton $frBR.rb1 -text "Continuous Packet" -value packet \
                -variable ::RL10GbGen::va10GbGenSetTmp($activePort.PacketBurst) \
                -command [list ::RL10GbGen::TogglePacketPerBurst $activePort]]
            if {$::RL10GbGen::va10GbGenSetTmp($activePort.PacketBurst)==""} {
              set ::RL10GbGen::va10GbGenSetTmp($activePort.PacketBurst) $::RL10GbGen::vaDefaults(PacketBurst)
            }    
            set va10GbGenGui(ContPacket) $rb1
            
            set rb2 [radiobutton $frBR.rb2 -text "Continuous Burst" -value burst \
                -variable ::RL10GbGen::va10GbGenSetTmp($activePort.PacketBurst) \
                -command [list ::RL10GbGen::TogglePacketPerBurst $activePort]]
            set va10GbGenGui(ContBurst) $rb2
            
            set l1 [Label $frBR.l1 -text "Packet per Burst"]
            set ent1 [Entry $frBR.ent1 -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.PacketPerBurst)\
                -validate key -vcmd {expr {[string is integer %P]} } ]
            if {$::RL10GbGen::va10GbGenSetTmp($activePort.PacketPerBurst)==""} {
              set ::RL10GbGen::va10GbGenSetTmp($activePort.PacketPerBurst) $::RL10GbGen::vaDefaults(PacketPerBurst)
            }
            set va10GbGenGui(PacketPerBurst) $ent1
            
            grid $rb1 -sticky w
            grid $rb2 -sticky w
            grid $l1 $ent1 -sticky w -padx 2           
          
          incr indx
          set lLR [Label $frStCt.l[set indx] -text "Line Rate percentage relative to Port's capacity, \[%\]:  "]
          set va10GbGenGui(LineRate) [Entry $frStCt.ent[set indx] \
              -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.LineRate) \
              -validate key -vcmd {expr {[string is double %P]} } ]
         
            
         
#           grid $lRP $va10GbGenGui(RcvPortList) -pady 4
#           grid $va10GbGenGui(butRxPortEqTxPort) -pady 4
          grid $frRP -pady 4
          grid $frBR -pady 4
          grid $lLR $va10GbGenGui(LineRate) -pady 4
          # grid $lSER $va10GbGenGui(SeqErThr) -pady 2
          
          foreach w {lRP lLR} {
            grid configure [set $w] -sticky w 
          }
          foreach w {RcvPortList LineRate} {
            grid configure  $va10GbGenGui($w) -sticky ew
          }
          grid configure  $frRP -columnspan 2 -sticky ew 
          grid configure  $frBR -columnspan 2 -sticky ew
          
        pack $frStCt -anchor w
        
        
      $notebook compute_size
      $notebook raise $pageUp
    pack $notebook -fill both -expand 1 
  pack $frFr -fill both -expand 1
  
    set bOk [Button $frBut.bOk -text "Save" -width 11 -command [list ::RL10GbGen::GuiStreamButOk $base $activePort] ]
    set bCa [Button $frBut.bCa -text "Cancel" -width 11 -command [list ::RL10GbGen::GuiStreamButCa $base $activePort]]
    pack $bCa $bOk -side right -padx 2
  pack $frBut -fill x -pady 2
  
  ::RL10GbGen::ToggleFrameSize $activePort
  update
  ::RL10GbGen::ToggleEthII $activePort
  ::RL10GbGen::ToggleIPV4 $activePort
  # ::RL10GbGen::ToggleSeqNumOffset $activePort
  ::RL10GbGen::ToggleVlan $activePort
  ::RL10GbGen::ToggleMpls $activePort
  ::RL10GbGen::TogglePacketPerBurst $activePort
  ::RL10GbGen::TogglePatternData $activePort
  
  focus -force $base
}

# ***************************************************************************
# GuiStreamButOk
# ***************************************************************************
proc GuiStreamButOk {base activePort} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenSetTmp
  variable va10GbGenCfg
	variable va10GbGenStatuses
  # puts "GuiStreamButOk $activePort"
  set chassis [lindex [split [lindex [split $activePort .] 0] :] 1]      
  set id $::RL10GbGen::va10GbGenStatuses($chassis,10GbGenID)
  set ret 0
  set message 55
  set title 66
  set ::RL10GbGen::va10GbGenSet($activePort.process) "notConfigured"
  
  set rangeL [list [$::RL10GbGen::va10GbGenGui(PacketSizeMin) get] [$::RL10GbGen::va10GbGenGui(PacketSizeMax) get]]      
  if {$va10GbGenSetTmp($activePort.FrameSizeType)=="Incr" || \
      $va10GbGenSetTmp($activePort.FrameSizeType)=="Random"} {
    set min $::RL10GbGen::va10GbGenSetTmp($activePort.PacketMinLen)
    set max $::RL10GbGen::va10GbGenSetTmp($activePort.PacketMaxLen)
    if {$min>$max} {
      set message "The \'Min Packet Size\' should not be more then \'Max Packet Size\'"
      set title "Wrong Frame Size"
      set ret -1
    } 
    if {$min<[lindex $rangeL 0]} {
      set message "The \'Min Packet Size\' should be equal or more then [lindex $rangeL 0]"
      set title "Wrong Frame Size"
      set ret -1
    } 
    if {$max>[lindex $rangeL 1]} {
      set message "The \'Max Packet Size\' should be less then [lindex $rangeL 1]"
      set title "Wrong Frame Size"
      set ret -1
    }
  } elseif {$va10GbGenSetTmp($activePort.FrameSizeType)=="Fixed"} {
    if {$::RL10GbGen::va10GbGenSetTmp($activePort.PacketFixLen)<[lindex $rangeL 0]} {
      set message "The \'Packet Size\' should be equal or more then [lindex $rangeL 0]"
      set title "Wrong Frame Size"
      set ret -1
    } elseif {$::RL10GbGen::va10GbGenSetTmp($activePort.PacketFixLen)>[lindex $rangeL 1]} {
      set message "The \'Packet Size\' should be less then [lindex $rangeL 1]"
      set title "Wrong Frame Size"
      set ret -1
    } 
  } elseif {$va10GbGenSetTmp($activePort.FrameSizeType)=="EMIX"} {
    foreach emix {1 2 3 4 5 6 7 8} {
      if {$::RL10GbGen::va10GbGenSetTmp($activePort.PacketEmixLen$emix)<[lindex $rangeL 0]} {
        set message "The \'Packet Size\' should be equal or more then [lindex $rangeL 0]"
        set title "Wrong Frame Size"
        set ret -1
      } elseif {$::RL10GbGen::va10GbGenSetTmp($activePort.PacketEmixLen$emix)>[lindex $rangeL 1]} {
        set message "The \'Packet Size\' should be less then [lindex $rangeL 1]"
        set title "Wrong Frame Size"
        set ret -1
      }
    } 
  } 
  
 
  set stream_id $::RL10GbGen::va10GbGenSet($activePort.strId) 
  set strId [format %.2x [expr { 2 * $stream_id } ]] 
  set ::RL10GbGen::va10GbGenSetTmp($activePort.DA) [string range $::RL10GbGen::va10GbGenSetTmp($activePort.DA) 0 9][set strId]
  set da $::RL10GbGen::va10GbGenSetTmp($activePort.DA)
  set res [expr {[string is xdigit $da] && [string length $da]==12}] 
  if {$res != "1"} {
    set message "DA_MAC should have 12 HEXs"
    set title "Wrong DA MAC"
    set ret -1
  }         
  set sa $::RL10GbGen::va10GbGenSetTmp($activePort.SA)
  set res [expr {[string is xdigit $sa] && [string length $sa]==12}] 
  if {$res != "1"} {
    set message "SA_MAC should have 12 HEXs"
    set title "Wrong SA MAC"
    set ret -1
  }
  
  set pb  $::RL10GbGen::va10GbGenSetTmp($activePort.PacketBurst)
  set ppb $::RL10GbGen::va10GbGenSetTmp($activePort.PacketPerBurst)
  # puts "pb:<$pb>  ppb:<$ppb>"
  if {$pb=="packet"} {
    ## OK, do nothing
  } else {
    if {[string is integer $ppb] && $ppb!=""} {
      ## OK, do nothing        
    } else {
      set message "PacketConfig procedure: Packet/Burst should be an integer or \'packet\'"
      set title "Wrong Packet/Burst"
      set ret -1
    }  
  }
    
  if {$ret==0} {    
    set tree $va10GbGenGui(resources,list)
    set strId [lindex [split [lindex [split $activePort .] 1] :] 1]
    if {$::RL10GbGen::va10GbGenSetTmp($activePort.RcvPort)!="NC" && $::RL10GbGen::va10GbGenSetTmp($activePort.RcvPort)!=""} {
      set ::RL10GbGen::va10GbGenSet($activePort.process) "configured"
      set ::RL10GbGen::va10GbGenSetTmp($activePort.process) "configured"
      set rcvP [lindex [split $::RL10GbGen::va10GbGenSetTmp($activePort.RcvPort) .] 1]      
      $tree itemconfigure $activePort -text "[string trim [lindex [split [$tree itemcget $activePort -text] < ] 0]]  <stream $strId>  $rcvP"      
    } else {
      set ::RL10GbGen::va10GbGenSet($activePort.process) "notConfigured"
      $tree itemconfigure $activePort -text "[string trim [lindex [split [$tree itemcget $activePort -text] < ] 0]]"    
    }  
  }
  if {$ret==0} {
    if {$::RL10GbGen::va10GbGenSet($activePort.process)=="configured"} {
      set ::RL10GbGen::va10GbGenSetTmp($activePort.PacketPerBurst) [string trim $::RL10GbGen::va10GbGenSetTmp($activePort.PacketPerBurst)]
      set strId $::RL10GbGen::va10GbGenSet($activePort.strId)
      set ::RL10GbGen::va10GbGenSet($id.$strId.TxPort) $activePort
      set ::RL10GbGen::va10GbGenSet($id.$strId.RxPort) [string trim [lindex [split $::RL10GbGen::va10GbGenSet($activePort.RcvPort) -] 0]]      
    }
    foreach nam [array names ::RL10GbGen::va10GbGenSetTmp $activePort.*] {
      set va10GbGenSet($nam) $va10GbGenSetTmp($nam)   
    }
    if {$::RL10GbGen::va10GbGenSet($activePort.process)=="configured"} {
      ::RL10GbGen::BuildPacket $activePort
      ::RL10GbGen::UpdateChassisLineRate
    }
    ::RL10GbGen::GuiStreamButCa $base $activePort
  } elseif {$ret!=0}  {
    tk_messageBox -message $message  -title $title
  }
}
# ***************************************************************************
# GuiStreamButCa
# ***************************************************************************
proc GuiStreamButCa {base activePort} {
  # puts "GuiStreamButCa $base"
  destroy $base
}

# ***************************************************************************
# GuiVlans
# ***************************************************************************
proc GuiVlans {activePort} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  variable va10GbGenSetTmp
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "GuiVlans $activePort"
  }
  
  set base .topGuiVlans
  if [winfo exists $base] {
    raise $base
    wm deiconify $base
    return 0
  }
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm resizable $base 0 0
  wm geometry $base +[expr {50+[winfo x .top10GbGenGui]}]+[expr {50+[winfo y .top10GbGenGui]}]
  wm title $base "VLAN in $activePort"
  set frFr [frame $base.frFr]
    set frSetup [frame $frFr.frSetup -bd 0 -relief groove]
    foreach v {1 2 3 4} {
      set frV$v [TitleFrame $frSetup.frV$v -text "VLAN $v"]
      set fr [[set frV$v] getframe]
        set chb [checkbutton $fr.chb -variable ::RL10GbGen::va10GbGenSetTmp($activePort.vlan.En.$v)]
        set lVid [Label $fr.lVid -text "VLAN ID"]
        set lPri [Label $fr.lPri -text "User\nPriority"]
        set lCfi [Label $fr.lCfi -text "CFI"]
        set lPid [Label $fr.lPid -text "Tag\nProtocol ID"]
        
        set entVid [Entry $fr.entVid -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.vlan.Id.$v) -width 7 -validate key -vcmd {expr {[string is integer %P] && [string length %P]<=4}}] ; #  && %P<=4096
        if {$::RL10GbGen::va10GbGenSetTmp($activePort.vlan.Id.$v)==""} {
          $entVid configure -text 0
        }
        set ::RL10GbGen::va10GbGenGui($activePort.vlan.Id.$v) $entVid
        
        set cmbPri [ComboBox $fr.cmbPri -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.vlan.uPri.$v) -width 3 -values {0 1 2 3 4 5 6 7} -editable 0]
        if {$::RL10GbGen::va10GbGenSetTmp($activePort.vlan.uPri.$v)==""} {
          $cmbPri configure -text 0
        }  
        set cmbCfi [ComboBox $fr.cmbCfi -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.vlan.cfi.$v) -width 6 -values {Reset Set} -editable 0]
        if {$::RL10GbGen::va10GbGenSetTmp($activePort.vlan.cfi.$v)==""} {
          $cmbCfi configure -text Reset
        }  
        set cmbPid [ComboBox $fr.cmbPid -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.vlan.pid.$v) -width 8 -values {0x8100 0x88a8} -editable 0]
        if {$::RL10GbGen::va10GbGenSetTmp($activePort.vlan.pid.$v)==""} {
          $cmbPid configure -text 0x8100
        }  
        
        grid x    $lVid   $lPri   $lCfi   $lPid   -sticky swe
        grid $chb $entVid $cmbPri $cmbCfi $cmbPid -sticky w -padx 2
      
      pack [set frV$v] -fill x -pady 1
    }
    
    set frBut [frame $frFr.frBut -bd 0 -relief groove]
      set bOk [Button $frBut.bOk -text OK     -width 11 -command [list ::RL10GbGen::GuiVlansButOk $activePort]]
      set bCa [Button $frBut.bCa -text Cancel -width 11 -command ::RL10GbGen::GuiVlansButCa]
      pack $bOk  -side right -padx 5
    
    pack $frSetup $frBut -anchor e -pady 2
  
  pack $frFr -fill both -padx 2 -pady 2  
}  
# ***************************************************************************
# GuiVlansButOk
# ***************************************************************************
proc GuiVlansButOk {activePort} {
  variable va10GbGenGui
#   puts "GuiVlansButOk $activePort"
  set ret 0
  foreach v {1 2 3 4} {
    if {$::RL10GbGen::va10GbGenSetTmp($activePort.vlan.Id.$v)>4095} {
      set message "The \'VLAN ID\' of VLAN $v is too high. It should be less then 4096"
      set title "Wrong VLAN ID"
      set ret -1
      $::RL10GbGen::va10GbGenGui($activePort.vlan.Id.$v) selection range 0 end
      break
    }   
  }
  if {$ret==0} {
    ::RL10GbGen::GuiVlansButCa
  } else {
    tk_messageBox -message $message  -title $title
    focus $::RL10GbGen::va10GbGenGui($activePort.vlan.Id.$v)
    update
  } 
}
# ***************************************************************************
# GuiVlansButCa
# ***************************************************************************
proc GuiVlansButCa {} {
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "GuiVlansButCa"
  }
  destroy .topGuiVlans
}
# ***************************************************************************
# ButRun
# ***************************************************************************
proc ButRun {} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  if ![::RL10GbGen::GlobalSanityCheck] {return}
  
  set portL [::RL10GbGen::GetEnabledPorts]  
  if ![llength $portL] {
    set node [::RL10GbGen::GetActivePort]
    $::RL10GbGen::va10GbGenGui(resources,list) selection set $node
    if {$node=="home"} {
      set msg "Enable at least one stream to run"
    } elseif {[llength [split $node .] ] == 1} {
      set msg "Enable at least one stream to run"
    } elseif {[llength [split $node .] ] == 2} {
      set msg "Enable the stream to run"
    }
     
    tk_messageBox -title "Chassis Run" -message $msg
    return 0
  }

  ::RL10GbGen::DisableEnableEntries disabled
  set va10GbGenSet(runstate) "Etx220 run..."
  
  ## disappear unused ports' stats from "Statistics View"
  set disportL [::RL10GbGen::GetEnabledPorts dis]  
  foreach disport $disportL {
    set id [lindex [split [lindex [split $disport .] 0 ] :] 1]
    set pm [lindex [split [lindex [split $disport .] 1 ] :] 1]
    ##chassis:1.Port:2 -> id=1 pm=2
    foreach w "str $::RL10GbGen::vlStreamStatsL" {
      $::RL10GbGen::va10GbGenGui(stats.$id.$pm.$w) configure -text ""
    }
    set stream_id [expr {[lindex [split [lindex [split $disport .] 1] :] 1] - 1}]
    set strApStats [expr {$stream_id + 1}]
    foreach w "$::RL10GbGen::vlPortStatsL" {  
      $::RL10GbGen::va10GbGenGui(statsPort.$id.$pm.$w)  configure -text ""
      update
    }
    $::RL10GbGen::va10GbGenGui(statsPort.$id.$pm.str) configure -text ""
    # $::RL10GbGen::va10GbGenGui(statsPort.$id.$strApStats.2.str) configure -text ""
  }
	  
  foreach activePort $portL {
    set id [lindex [split [lindex [split $activePort .] 0 ] :] 1]
    if {[catch {expr int($id)}]} {
  		tk_messageBox -icon error -type ok -message "Select the chassis to run it" -title "Etx220A Generator"
  	  return
    }
  }  
     
	if {[winfo exists .top10GbGenGui]} {
  	# FillGuiIndicators run
	}
 
  if [llength $portL] {
    foreach activePort $portL {
      set id [lindex [split [lindex [split $activePort .] 0 ] :] 1]
      set stream_id $::RL10GbGen::va10GbGenSet($activePort.strId)
      if {![info exists ::RL10GbGen::va10GbGenSet($id.$stream_id.activity)]} {
        set ::RL10GbGen::va10GbGenSet($id.$stream_id.activity)=="new"
      }
      if {$::RL10GbGen::va10GbGenSet($id.$stream_id.activity)=="stop"} {
        set ::RL10GbGen::va10GbGenSet($id.$stream_id.activity) "new"
      }
      lappend ::RL10GbGen::va10GbGenSet(runPortL) $activePort
    }
  }
  
  if ![info exists ::RL10GbGen::va10GbGenSet(WhileLoopReadStats.state)] {
    set ::RL10GbGen::va10GbGenSet(WhileLoopReadStats.state) stop
  }
  if {$::RL10GbGen::va10GbGenSet(WhileLoopReadStats.state)=="stop"} {
    WhileLoopReadStats
  } elseif {$::RL10GbGen::va10GbGenSet(WhileLoopReadStats.state)=="run"} {
#     19/02/2014 9:25:53
    ::RL10GbGen::DisableEnableEntries normal
  }

  return 0
}
# ***************************************************************************
# WhileLoopReadStats
# ***************************************************************************
proc WhileLoopReadStats {} {
  variable va10GbGenGui
  variable va10GbGenGetStats
  set ::RL10GbGen::va10GbGenSet(WhileLoopReadStats.state) run
  set portL [::RL10GbGen::GetEnabledPorts all]  
  while {[llength $portL]>0} {      
    set portL [::RL10GbGen::GetEnabledPorts all]
    # puts "portL:$portL" ; update
    # after 2000
    foreach activePort $portL {
      # puts "\n[::RL10GbGen::MyTime] 1. WhileLoopReadStats activePort:<$activePort> portL:<$portL> llength:<[llength $portL]>" ; update
      set stream_id [expr {[lindex [split [lindex [split $activePort .] 1] :] 1] - 1}]
      set chassis [lindex [split [lindex [split $activePort .] 0] :] 1]      
      set id $::RL10GbGen::va10GbGenStatuses($chassis,10GbGenID)
      
      
      if {$::RL10GbGen::g10GbGenBufferDebug} {
        puts "\n[::RL10GbGen::MyTime] WhileLoopReadStatsactivePortL:$activePort id:$id stream_id:$stream_id activity:$::RL10GbGen::va10GbGenSet($id.$stream_id.activity)" ; update
      }
       
      if {[lsearch $::RL10GbGen::va10GbGenSet(runPortL) $activePort]=="-1"} {
        set portL [lreplace $portL [lsearch $portL $activePort] [lsearch $portL $activePort] ]
        if {[llength $portL]==0} {
          set ::RL10GbGen::va10GbGenSet(WhileLoopReadStats.state) stop
          ::RL10GbGen::DisableEnableEntries normal
          return 0
        }
        # puts "\n[::RL10GbGen::MyTime] 2. WhileLoopReadStats activePort:<$activePort> portL:<$portL> llength:<[llength $portL]>" ; update
        continue
      }
      
      if {$::RL10GbGen::va10GbGenSet($id.$stream_id.activity)=="new"} {
        ::RL10GbGen::DisableEnableEntries disabled
        ::RL10GbGen::PortRun $activePort $::RL10GbGen::va10GbGenGui(bRun)
        ::RL10GbGen::DisableEnableEntries normal
      }
      
      if {$::RL10GbGen::g10GbGenBufferDebug} {
        puts "[::RL10GbGen::MyTime] WhileLoopReadStats activePort:<$activePort> portL:<$portL> llength:<[llength $portL]>" ; update
      }
      
      ## remove a stopped port from the list
      if {$::RL10GbGen::va10GbGenSet($id.$stream_id.activity)=="stop"} {
        ::RL10GbGen::DisableEnableEntries disabled
        set portL [lreplace $portL [lsearch $portL $activePort] [lsearch $portL $activePort] ]
        ::RL10GbGen::PortStop $activePort $::RL10GbGen::va10GbGenGui(bStop)
        after 1000
        set ret [::RL10GbGen::StreamLoopReadStatistics $id $stream_id]
        if {$::RL10GbGen::g10GbGenBufferDebug} {
          puts "[::RL10GbGen::MyTime] WhileLoopReadStats.2.StreamLoopReadStatistics <$id> <$stream_id> ret:<$ret>" ; update
        }
        set ::RL10GbGen::va10GbGenSet($id.$stream_id.activity) "stop"
        set runPortL $::RL10GbGen::va10GbGenSet(runPortL)
        set runPortL [lreplace $runPortL [lsearch $runPortL $activePort] [lsearch $runPortL $activePort] ]
        set ::RL10GbGen::va10GbGenSet(runPortL) $runPortL  
        ::RL10GbGen::DisableEnableEntries normal      
      }
      if {$::RL10GbGen::g10GbGenBufferDebug} {
        # puts "portL:<$portL> llength:<[llength $portL]>" ; update
      }
      if {[llength $portL]==0} {
        set ::RL10GbGen::va10GbGenSet(WhileLoopReadStats.state) stop
        ::RL10GbGen::DisableEnableEntries normal
        return 0
      }
         
      if {$::RL10GbGen::va10GbGenSet($id.$stream_id.activity)=="clear"} {
        set ::RL10GbGen::va10GbGenGui(status) "Clear Stream's [expr {1+$stream_id}] statistics" ; update
        set ::RL10GbGen::va10GbGenSet($id.$stream_id.activity) "run"
        StreamClearStatistics $id $stream_id
#         update
        after 100
      }
      # puts "[::RL10GbGen::MyTime] WhileLoopReadStats activePort:$activePort $::RL10GbGen::va10GbGenSet($id.$stream_id.activity)" ; update
      
      if {$::RL10GbGen::va10GbGenSet($id.$stream_id.activity)=="run"} {        
        set ret [StreamLoopReadStatistics $id $stream_id]  
        if {$::RL10GbGen::g10GbGenBufferDebug} {
          puts "[::RL10GbGen::MyTime] WhileLoopReadStats.1.StreamLoopReadStatistics <$id> <$stream_id> ret:<$ret>" ; update
        }  
      }    
    }
  }

  if {$ret!=0} {
    ::RL10GbGen::ButStop 
  }
  return 0
}
# ***************************************************************************
# GetEnabledPorts
# ::RL10GbGen::GetEnabledPorts
# ::RL10GbGen::GetEnabledPorts all
# ::RL10GbGen::GetEnabledPorts configured
# ***************************************************************************
proc GetEnabledPorts {{out ""}} {
  set activePort [::RL10GbGen::GetActivePort]
  if {$out=="all"} {set activePort home; set out ""}
  if {$activePort=="home"} {
    set curr all
    set porr all
  } else {
    set li [split $activePort .]
    if {[llength $li]==1} {
      # chassis:1
      set curr $li
      set porr all
    } elseif {[llength $li]>1} {
      # chassis:1.Port:1
      set curr [lindex $li 0]
      set porr [lindex [split [lindex $li 1] :] 1]
    }
  }
  set reslist [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) home]
  set pl [list]
  foreach chas $reslist {
    if {$curr=="all" || $curr==$chas} {
      for {set po 1} {$po <= 8} {incr po} {
       if {$porr=="all" || $porr==$po} {
         lappend pl $chas.Port:$po
       }
      }
    }
  }
  # puts "pl:$pl"
  # set streamId 0
  set portIdL [list]
  set disportIdL [list]
  set process0portIdL [list]
  set process1portIdL [list]
  set process2portIdL [list]
  set process3portIdL [list]
  foreach p $pl {
    if ![info exists ::RL10GbGen::va10GbGenSet($p.StreamEnable)] {
      set ::RL10GbGen::va10GbGenSet($p.StreamEnable) 0
      lappend disportIdL $p
    } else {
      if {$::RL10GbGen::va10GbGenSet($p.StreamEnable)==1} {
        lappend portIdL $p
      } else {
        lappend disportIdL $p
      }
    }
    if {![info exists ::RL10GbGen::va10GbGenSet($p.process)] || $::RL10GbGen::va10GbGenSet($p.process)=="notConfigured"} {
      set ::RL10GbGen::va10GbGenSet($p.process) "notConfigured"
      lappend process0portIdL $p
    } else {
      if {$::RL10GbGen::va10GbGenSet($p.process)=="started"} {
        lappend process1portIdL $p
      } elseif {$::RL10GbGen::va10GbGenSet($p.process)=="stoped"} {
        lappend process2portIdL $p
      } elseif {$::RL10GbGen::va10GbGenSet($p.process)=="configured"} {
        lappend process3portIdL $p
      }
    }
    # puts "out:$out p:$p $::RL10GbGen::va10GbGenSet($p.process) \
        process0portIdL:$process0portIdL process1portIdL:$process1portIdL\
         process2portIdL:$process2portIdL  process3portIdL:$process3portIdL"
    
  }
  
  if {$out==""} {
    return [lsort -unique $portIdL]
  } elseif {$out=="dis"} {
    return [lsort -unique $disportIdL]
  } elseif {$out=="notConfigured"} {
    return [lsort -unique $process0portIdL]
  } elseif {$out=="started"} {
    return [lsort -unique $process1portIdL]
  } elseif {$out=="stoped"} {
    return [lsort -unique $process2portIdL]
  } elseif {$out=="configured"} {
    return [lsort -unique $process3portIdL]
  }
  ## ::RL10GbGen::
}
# ***************************************************************************
# PortRun
# ***************************************************************************
proc PortRun {activePort w} {
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "\n[::RL10GbGen::MyTime] ... PortRun $activePort"; update
  }
  global        gMessage
  variable va10GbGenStatuses
  variable va10GbGenGui
  variable va10GbGenGetStats
  
  set stream_id [expr {[lindex [split [lindex [split $activePort .] 1] :] 1] - 1}]
  set chassis [lindex [split [lindex [split $activePort .] 0] :] 1]      
  set id $::RL10GbGen::va10GbGenStatuses($chassis,10GbGenID)
  set activity $::RL10GbGen::va10GbGenSet($id.$stream_id.activity)
  if {$activity=="run"} {
    if {$::RL10GbGen::g10GbGenBufferDebug} {
      puts "[::RL10GbGen::MyTime] The port $activePort is already run" ; update
    }
    return 0
  }    
  
  foreach w "$::RL10GbGen::vlStreamStatsL" { 
    set ::RL10GbGen::va10GbGenGetStats($id.$stream_id.$w) ""  
    set strApStats [expr {$stream_id + 1}]
    $::RL10GbGen::va10GbGenGui(stats.$id.$strApStats.$w)  configure -text ""
  }
  set port [::RL10GbGen::ParsePort $activePort]
  foreach w "$::RL10GbGen::vlPortStatsL" {  
    $::RL10GbGen::va10GbGenGui(statsPort.$id.$port.$w)  configure -text ""
    update
  }
  
  ::RL10GbGen::UpdateChassisLineRate
  update
  set clkFreq $::RL10GbGen::va10GbGenSet(clockFreq)
  set max_psize [$::RL10GbGen::va10GbGenGui(PacketSizeMax) get]
  set min_psize [$::RL10GbGen::va10GbGenGui(PacketSizeMin) get]
  set ipg       [$::RL10GbGen::va10GbGenGui(IPG) get]
  
  # set Seq_error_threshold_stream $::RL10GbGen::va10GbGenSet($activePort.SeqErThr)
  set Seq_error_threshold_stream [$::RL10GbGen::va10GbGenGui(SeqErThr) get]
  
  set da $::RL10GbGen::va10GbGenSet($activePort.DA) 
  
  set sa $::RL10GbGen::va10GbGenSet($activePort.SA)
  
  ## chassis:1.Port:6 -> 6
  set tx_port [lindex [split $activePort :] end]
  
  ## chassis:1.Port:5 - 1G -> 5 
  if ![info exists ::RL10GbGen::va10GbGenSet($activePort.RcvPort)] {
    set ::RL10GbGen::va10GbGenSet($activePort.RcvPort) $::RL10GbGen::vaDefaults(RcvPort)
  }
  set received_port [lindex [split [string trim [lindex [split $::RL10GbGen::va10GbGenSet($activePort.RcvPort) - ] 0]] : ] end]
  if {$received_port=="" || $received_port=="NC"} {
    # tk_messageBox -message "The Rcv Port is not defined" -title "Wrong Stream define"
    set gMessage "The Receive Port at $activePort is not defined.\nChoose an appropriate Port at the \"Stream Control\" page."
    return [RLEH::Handle Syntax gMessage]
  }
  
  set sizeType $::RL10GbGen::va10GbGenSet($activePort.FrameSizeType)
  set randomSize "$min_psize $max_psize"
  
  set fixedSize $::RL10GbGen::va10GbGenSet($activePort.PacketFixLen)
  set emixSize [list]
  for {set i 1} {$i<=8} {incr i} {
    if {$::RL10GbGen::va10GbGenSet($activePort.PacketEmixEn$i)==1} {
      lappend emixSize $::RL10GbGen::va10GbGenSet($activePort.PacketEmixLen$i) 
    }
  }
  if {[llength $emixSize]==0} {
    set emixSize 1500
  }
  set incrSize "$min_psize $max_psize"
  switch -exact -- [string tolower $sizeType] {
    fixed  {set size $fixedSize}
    incr   {set size $incrSize}
    random {set size $randomSize}
    emix   {set size $emixSize}
  }
  
  if {$::RL10GbGen::va10GbGenSet($activePort.PacketBurst)=="packet"} {
    set streamControl packet
  } else {
    set streamControl $::RL10GbGen::va10GbGenSet($activePort.PacketPerBurst)
  } 
  
  set lineRate $::RL10GbGen::va10GbGenSet($activePort.LineRate)
  
  if {$::RL10GbGen::va10GbGenSet($activePort.PatternType)=="Fixed"} {
    set ::RL10GbGen::va10GbGenSet($activePort.PatternType) $::RL10GbGen::vaDefaults(PatternType)
  }
  if {$::RL10GbGen::va10GbGenSet($activePort.PatternData)=="FF FF"} {
    set ::RL10GbGen::va10GbGenSet($activePort.PatternData) $::RL10GbGen::vaDefaults(PatternData)
  }
  set dataPatternType $::RL10GbGen::va10GbGenSet($activePort.PatternType)
  set dataPatternData $::RL10GbGen::va10GbGenSet($activePort.PatternData)
  
  
  set ::RL10GbGen::va10GbGenSet($activePort.StreamEnable) 1
  set stream_id $::RL10GbGen::va10GbGenSet($activePort.strId)
  
  ## chassis:1.Port:6 -> 1
  set id [lindex [split [lindex [split $activePort .] 0] :] end]
  
  set tree $::RL10GbGen::va10GbGenGui(resources,list)
  $tree itemconfigure $activePort -image [image create photo -file $::RL10GbGen::va10GbGenSet(rundir)/images/portRun1.ico]
  
  update
  
  set cmd [list $id $stream_id $tx_port $received_port -sa $sa -da $da  -minPacketSize $min_psize \
    -maxPacketSize $max_psize -IPG $ipg -seqErrorThreshold $Seq_error_threshold_stream \
    -sizeType $sizeType -size $size\
    -streamControl $streamControl -lineRate $lineRate -clkFreq $clkFreq \
    -dataPatternType $dataPatternType -dataPatternData $dataPatternData]
  if {$::RL10GbGen::va10GbGenSet($activePort.vlans,en)==1} {
    foreach v {1 2 3 4} {
      if {$::RL10GbGen::va10GbGenSet($activePort.vlan.En.$v)==1} {
        set cmd [concat $cmd -vlan$v       $::RL10GbGen::va10GbGenSet($activePort.vlan.Id.$v)]
        set cmd [concat $cmd -pBit$v       $::RL10GbGen::va10GbGenSet($activePort.vlan.uPri.$v)]
        set cmd [concat $cmd -cfi$v        $::RL10GbGen::va10GbGenSet($activePort.vlan.cfi.$v)]
        set cmd [concat $cmd -protocolId$v $::RL10GbGen::va10GbGenSet($activePort.vlan.pid.$v)]
      }
    }
  }  
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] ... $activePort PortRun. Start StreamConfig"; update
  }
  set ret [eval ::RL10GbGen::StreamConfig $cmd]
  
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] ... $activePort PortRun. Finish StreamConfig"; update
  }
  
  set rx_port $::RL10GbGen::va10GbGenSet($id.$stream_id.RxPort)
  set tx_port $::RL10GbGen::va10GbGenSet($id.$stream_id.TxPort)
  if {[info exist ::RL10GbGen::va10GbGenSet($tx_port.state)]==0 || \
      $::RL10GbGen::va10GbGenSet($tx_port.state)=="stopped"} {
    set ::RL10GbGen::va10GbGenSet($tx_port.state) "configured"
    set TxPortInt [::RL10GbGen::ParsePortNum2IntNum  [::RL10GbGen::ParsePort $tx_port]]
    set ret [::RL10GbGen::StreamClearRmon $id $TxPortInt]
  } else {
    if {$::RL10GbGen::g10GbGenBufferDebug} {
      puts "don't clear port $tx_port !!!"; update
    }  
  }
  if {[info exist ::RL10GbGen::va10GbGenSet($rx_port.state)]==0 || \
      $::RL10GbGen::va10GbGenSet($rx_port.state)=="stopped"} {
    set ::RL10GbGen::va10GbGenSet($rx_port.state) "configured"
    set RxPortInt [::RL10GbGen::ParsePortNum2IntNum  [::RL10GbGen::ParsePort $rx_port]]
    # SendTo10GbGen $id "mea rmon clear $RxPortInt\r" "FPGA"
    set ret [::RL10GbGen::StreamClearRmon $id $RxPortInt]
  } else {
    if {$::RL10GbGen::g10GbGenBufferDebug} {
      puts "don't clear port $received_port !!!"; update
    }  
  }
  
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] ... $activePort PortRun. Start StreamStart"; update  
  }
  set ret [::RL10GbGen::StreamStart $id $stream_id] 
  
  set ::RL10GbGen::va10GbGenSet($tx_port.state) "started"
  set ::RL10GbGen::va10GbGenSet($rx_port.state) "started"
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] ... $activePort PortRun. Finish StreamStart"; update  
  }
  
  $::RL10GbGen::va10GbGenGui(stats.$id.[expr {$stream_id+1}].str) configure -bg white
  foreach port "$::RL10GbGen::va10GbGenSet($id.$stream_id.TxPort) $::RL10GbGen::va10GbGenSet($id.$stream_id.RxPort)" {
    set pport [::RL10GbGen::ParsePort $port]
    $::RL10GbGen::va10GbGenGui(statsPort.$id.$pport.str) configure -bg white
    $::RL10GbGen::va10GbGenGui(statsPort.$id.$pport.str) configure -bg white
  }  
  return 0
}
# ***************************************************************************
# PortStop
# ***************************************************************************
proc PortStop {activePort w} {
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] PortStop $activePort"; update
  }  
  global        gMessage
  set stream_id $::RL10GbGen::va10GbGenSet($activePort.strId)
  set chassis [lindex [split [lindex [split $activePort .] 0] :] 1]      
  set id $::RL10GbGen::va10GbGenStatuses($chassis,10GbGenID)
  ::RL10GbGen::StreamStop $id $stream_id
  
  set rx_port $::RL10GbGen::va10GbGenSet($id.$stream_id.RxPort)
  set tx_port $::RL10GbGen::va10GbGenSet($id.$stream_id.TxPort)
  
  set ::RL10GbGen::va10GbGenSet($rx_port.state) "stopped"
  set ::RL10GbGen::va10GbGenSet($tx_port.state) "stopped"
#   after 1000
  
  set tree $::RL10GbGen::va10GbGenGui(resources,list)
  $tree itemconfigure $activePort -image [image create photo -file $::RL10GbGen::va10GbGenSet(rundir)/images/port2.ico]
  $::RL10GbGen::va10GbGenGui(stats.$id.[expr {$stream_id+1}].str) configure -bg SystemButtonFace  
  foreach port "$::RL10GbGen::va10GbGenSet($id.$stream_id.TxPort) $::RL10GbGen::va10GbGenSet($id.$stream_id.RxPort)" {
    set pport [::RL10GbGen::ParsePort $port]
    $::RL10GbGen::va10GbGenGui(statsPort.$id.$pport.str) configure -bg SystemButtonFace
    $::RL10GbGen::va10GbGenGui(statsPort.$id.$pport.str) configure -bg SystemButtonFace
  }
  update
}  


# ***************************************************************************
# StreamLoopReadStatistics
# ***************************************************************************
proc StreamLoopReadStatistics {id stream_id} {
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] StreamLoopReadStatistics $id $stream_id" ; update
  }
  variable va10GbGenGetStats
  variable va10GbGenSet
  
  set strApStats [expr {$stream_id + 1}]
  
  if {$::RL10GbGen::va10GbGenSet($id.$stream_id.activity)=="stop"} {
    # return stop
  }
  set ret [::RL10GbGen::StreamReadStatistics $id $stream_id aRes]
  # puts "ret of StreamReadStatistics <$id> <$stream_id> : $ret" ; update
  if {$ret!=0} {return $ret}
  
  ## show stats at separate column of "View Statistics" page   
  # puts "vlStreamStatsL" ; update 
  foreach w "$::RL10GbGen::vlStreamStatsL" {     
    if {$w!="RunTime"} {
      if ![info exist aRes($id.strm.$strApStats.$w)] {return {}}
      set ::RL10GbGen::va10GbGenGetStats($id.$stream_id.$w) $aRes($id.strm.$strApStats.$w)
      $::RL10GbGen::va10GbGenGui(stats.$id.$strApStats.$w) configure -text [::RL10GbGen::InsPsik $::RL10GbGen::va10GbGenGetStats($id.$stream_id.$w)]
      if {[lsearch $::RL10GbGen::vlStreamZeroStatsL $w]!="-1" && $::RL10GbGen::va10GbGenGetStats($id.$stream_id.$w)!=0} {
        $::RL10GbGen::va10GbGenGui(stats.$id.$strApStats.$w) configure -fg red
      } elseif {[lsearch $::RL10GbGen::vlStreamZeroStatsL $w]!="-1" && $::RL10GbGen::va10GbGenGetStats($id.$stream_id.$w)==0} {
        $::RL10GbGen::va10GbGenGui(stats.$id.$strApStats.$w) configure -fg black
      }
    } elseif {$w=="RunTime"} {
      $::RL10GbGen::va10GbGenGui(stats.$id.$strApStats.$w)  configure -text [CalcRunTime $::RL10GbGen::va10GbGenSet($id.$stream_id.startSec)]
    }
    update
    # puts "\nstream_id:$stream_id strApStats:$strApStats id:$id\n"
    if {$::RL10GbGen::va10GbGenSet(chassis:$id.Port:$strApStats.PacketBurst)=="burst"} {
      set sntPackets $::RL10GbGen::va10GbGenGetStats($id.$stream_id.TxPacket)
      set guiPacketPerBurst $::RL10GbGen::va10GbGenSet(chassis:$id.Port:$strApStats.PacketPerBurst)
      if {$::RL10GbGen::g10GbGenBufferDebug} {
        puts "chassis:$id.Port:$strApStats sntPackets:$sntPackets guiPacketPerBurst:$guiPacketPerBurst" ; update
      }
      if {$sntPackets>=$guiPacketPerBurst} {
        set ::RL10GbGen::va10GbGenSet($id.$stream_id.activity) "stop"
      }
    }
    # puts "vlStreamStatsL w:$w" ; update
  }
  set RxPort [::RL10GbGen::ParsePort $::RL10GbGen::va10GbGenSet($id.$stream_id.RxPort)]
  set TxPort [::RL10GbGen::ParsePort $::RL10GbGen::va10GbGenSet($id.$stream_id.TxPort)]
  set RxPortInt [::RL10GbGen::ParsePortNum2IntNum  $RxPort]
  set TxPortInt [::RL10GbGen::ParsePortNum2IntNum  $TxPort]
  # puts "vlPortStatsL" ; update
  foreach w "$::RL10GbGen::vlPortStatsL" { 
    if {$w!="RunTime"} {
      set ::RL10GbGen::va10GbGenGetStats($id.$TxPort.$w) $aRes($id.port.$TxPort.$w)
      $::RL10GbGen::va10GbGenGui(statsPort.$id.$TxPort.$w)  configure -text [::RL10GbGen::InsPsik $::RL10GbGen::va10GbGenGetStats($id.$TxPort.$w)]
      if {[lsearch $::RL10GbGen::vlPortZeroStatsL $w]!="-1" && $::RL10GbGen::va10GbGenGetStats($id.$TxPort.$w)!=0}  {
        $::RL10GbGen::va10GbGenGui(statsPort.$id.$TxPort.$w) configure -fg red
      } elseif {[lsearch $::RL10GbGen::vlPortZeroStatsL $w]!="-1" && $::RL10GbGen::va10GbGenGetStats($id.$TxPort.$w)==0}  {
        $::RL10GbGen::va10GbGenGui(statsPort.$id.$TxPort.$w) configure -fg black
      }
      
      set ::RL10GbGen::va10GbGenGetStats($id.$RxPort.$w) $aRes($id.port.$RxPort.$w)
      $::RL10GbGen::va10GbGenGui(statsPort.$id.$RxPort.$w)  configure -text [::RL10GbGen::InsPsik $::RL10GbGen::va10GbGenGetStats($id.$RxPort.$w)]
      if {[lsearch $::RL10GbGen::vlPortZeroStatsL $w]!="-1" && $::RL10GbGen::va10GbGenGetStats($id.$RxPort.$w)!=0}  {
        $::RL10GbGen::va10GbGenGui(statsPort.$id.$RxPort.$w) configure -fg red
      } elseif {[lsearch $::RL10GbGen::vlPortZeroStatsL $w]!="-1" && $::RL10GbGen::va10GbGenGetStats($id.$RxPort.$w)==0}  {
        $::RL10GbGen::va10GbGenGui(statsPort.$id.$RxPort.$w) configure -fg black
      }      
    } elseif {$w=="RunTime"} {
      $::RL10GbGen::va10GbGenGui(statsPort.$id.$RxPort.$w)  configure -text [CalcRunTime $::RL10GbGen::va10GbGenSet($id.$stream_id.startSec)]
    }
    update
    # puts "\nstream_id:$stream_id strApStats:$strApStats id:$id\n"
  }
  $::RL10GbGen::va10GbGenGui(stats.$id.$strApStats.str) configure -text "chs:$id.strm:$strApStats"
  $::RL10GbGen::va10GbGenGui(statsPort.$id.$TxPort.str) configure -text "Port $TxPort"
  $::RL10GbGen::va10GbGenGui(statsPort.$id.$RxPort.str) configure -text "Port $RxPort"
  set activePort [::RL10GbGen::GetActivePort]
  
  # puts "::RL10GbGen::vlStreamStatsL" ; update
  if {[llength [split $activePort .]]>1 } {  
    set strAP [expr {[lindex [split [lindex [split $activePort .] 1] :] 1] - 1}]    
    set chassisAP [lindex [split [lindex [split $activePort .] 0] :] 1]      
    set idAP $::RL10GbGen::va10GbGenStatuses($chassisAP,10GbGenID)
    # puts "\nstrAP:$strAP stream_id:$stream_id chassisAP:$chassisAP id:$id\n"
    if {$chassisAP==$id && $strAP==$stream_id} {
      # puts "\n[::RL10GbGen::MyTime] strAP:$strAP strApStats:$strApStats idAP:$idAP\n" ; update
      foreach w "$::RL10GbGen::vlStreamStatsL" { 
        if {$w!="RunTime"} {
          $::RL10GbGen::va10GbGenGui(fra,statView,ent$w) configure -text [::RL10GbGen::InsPsik $::RL10GbGen::va10GbGenGetStats($id.$stream_id.$w)]
          if {[lsearch $::RL10GbGen::vlStreamZeroStatsL $w]!="-1" && $::RL10GbGen::va10GbGenGetStats($id.$stream_id.$w)!=0} {
            $::RL10GbGen::va10GbGenGui(fra,statView,ent$w) configure -fg red
          } elseif {[lsearch $::RL10GbGen::vlStreamZeroStatsL $w]!="-1" && $::RL10GbGen::va10GbGenGetStats($id.$stream_id.$w)==0} {
            $::RL10GbGen::va10GbGenGui(fra,statView,ent$w) configure -fg black
          }
        } elseif {$w=="RunTime"} {
          $::RL10GbGen::va10GbGenGui(fra,statView,ent$w)  configure -text [CalcRunTime $::RL10GbGen::va10GbGenSet($id.$stream_id.startSec)]          
        }
        update
        # puts "::RL10GbGen::vlStreamStatsL w:$w" ; update  
      }
    } else {
      foreach w "$::RL10GbGen::vlStreamStatsL" { 
        # $::RL10GbGen::va10GbGenGui(fra,statView,ent$w) configure -text 0
      }
    }
  }
  update   
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] StreamLoopReadStatistics Finish $id $stream_id" ; update
    puts "[::RL10GbGen::MyTime] StreamLoopReadStatistics id:$id stream_id:$stream_id activity:$::RL10GbGen::va10GbGenSet($id.$stream_id.activity)" ; update
  }
  # ::RL10GbGen::
  return 0
}

# ***************************************************************************
# StreamReadStatistics
# ***************************************************************************
proc StreamReadStatistics {ip_ID stream_id arrRes} {
  # puts "StreamReadStatistics $ip_ID $stream_id $activePort $arrRes"
  global        g10GbGenBuffer
  global        gMessage
  variable      va10GbGenStatuses 
  variable      vOpened10GbGenHistoryCounter
  variable      va10GbGenSet
  set gMessage ""                   
	set fail          -1
	set ok             0
  variable      oam_port
  variable      drop_cluster
  variable      oam_cluster
  variable      ia 
  upvar $arrRes a
  
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] StreamReadStatistics ip_ID:$ip_ID stream_id:$stream_id activity:$::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.activity)" ; update
  }
  
  set RxPort [::RL10GbGen::ParsePort $::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.RxPort)]
  set TxPort [::RL10GbGen::ParsePort $::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.TxPort)]
  set RxPortInt [::RL10GbGen::ParsePortNum2IntNum  $RxPort]
  set TxPortInt [::RL10GbGen::ParsePortNum2IntNum  $TxPort]
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] StreamReadStatistics $ip_ID $stream_id $arrRes __TXport:$TxPort $TxPortInt  __RXport:$RxPort $RxPortInt" ; update
  }
  set ::RL10GbGen::va10GbGenGui(status) "Stream's [expr {1+$stream_id}] reading statistics" ; update
  SendTo10GbGen $ip_ID "mea oam 10G rmon gen $stream_id $RxPortInt $TxPortInt\r" "FPGA" 2  
  set strApStats [expr {$stream_id + 1}]
  
  ## all, except dots and spaces 
  set b2 [regexp -all -inline {[^\x2e\s]+} $g10GbGenBuffer(id$ip_ID)]
  
  ## a small test if the buffer is right: the 
  ## if it is not, just quit from the proc
  ## and hope that next lap will OK
  if {[llength [lsearch -all -glob $b2 lxcp_discard*]]!=2} {
    return 0
  } 
  
  set BitsIndx [lsearch $b2 Bits]
  set BitsTransmitRate [lindex $b2 [expr {$BitsIndx + 3}]]
  set c [::RL10GbGen::c1c2 0 $BitsTransmitRate]
  set a($ip_ID.strm.$strApStats.BitsTransmitRate) $c
  
  
  foreach {c1 c2} [lrange $b2 [expr {$BitsIndx + 6}] [expr {$BitsIndx + 7}]] {
    set c [::RL10GbGen::c1c2 $c1 $c2]
  }
  set a($ip_ID.strm.$strApStats.TxPacket) $c
  
  foreach {c1 c2} [lrange $b2 [expr {$BitsIndx + 10}] [expr {$BitsIndx + 11}]] {
    set c [::RL10GbGen::c1c2 $c1 $c2]
  }
  set a($ip_ID.strm.$strApStats.TxByte) $c
  
  set BitsReceivedRate [lindex $b2 [expr {$BitsIndx + 15}]]
  set c [::RL10GbGen::c1c2 0 $BitsReceivedRate]
  set a($ip_ID.strm.$strApStats.BitsReceivedRate) $c
  
  foreach {c1 c2} [lrange $b2 [expr {$BitsIndx + 18}] [expr {$BitsIndx + 19}]] {
    set c [::RL10GbGen::c1c2 $c1 $c2]
  }
  set a($ip_ID.strm.$strApStats.RxSN) $c
  
  foreach {c1 c2} [lrange $b2 [expr {$BitsIndx + 22}] [expr {$BitsIndx + 23}]] {
    set c [::RL10GbGen::c1c2 $c1 $c2]
  }
  set a($ip_ID.strm.$strApStats.RxByte) $c
  
  foreach {c1 c2} [lrange $b2 [expr {$BitsIndx + 28}] [expr {$BitsIndx + 29}]] {
    set c [::RL10GbGen::c1c2 $c1 $c2]
  }
  set a($ip_ID.strm.$strApStats.DataIntegrityErrors) $c
  
  foreach {c1 c2} [lrange $b2 [expr {$BitsIndx + 33}] [expr {$BitsIndx + 34}]] {
    set c [::RL10GbGen::c1c2 $c1 $c2]
  }
  set a($ip_ID.strm.$strApStats.DataSequenceErrors) $c
  
  foreach {c1 c2} [lrange $b2 [expr {$BitsIndx + 37}] [expr {$BitsIndx + 38}]] {
    set c [::RL10GbGen::c1c2 $c1 $c2]
  }
  set a($ip_ID.strm.$strApStats.RxPacket) $c
  
  regexp {(rx_pkts.*)rx_pkts} $b2 - rxPortPart
  regexp {lxcp_discard.*(rx_pkts.*)FPGA} $b2 - txPortPart
  if ![info exists rxPortPart] {
    return -1 ; #0
  }
  if ![info exists txPortPart] {
    return -1 ; #0
  }
  foreach part "\"$rxPortPart\" \"$txPortPart\"" port "$RxPort $TxPort" {
    set b2 $part
    
    foreach {c1 c2} [lrange $b2 1 2] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.RxPkts) $c
    
    foreach {c1 c2} [lrange $b2 4 5] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.RxOctets) $c
    
    foreach {c1 c2} [lrange $b2 7 8] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.RxOversizePackets) $c 
    
    foreach {c1 c2} [lrange $b2 10 11] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.RxJabbers) $c
    
    foreach {c1 c2} [lrange $b2 13 14] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.RxCrcErrors) $c
    
    foreach {c1 c2} [lrange $b2 16 17] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.RxMacError) $c
    
    foreach {c1 c2} [lrange $b2 19 20] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.RxShortPackets) $c
    
    foreach {c1 c2} [lrange $b2 22 23] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.RxMacOverflow) $c
    
    foreach {c1 c2} [lrange $b2 25 26] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.TxPkts) $c
    
    foreach {c1 c2} [lrange $b2 28 29] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.TxOctets) $c
    
    foreach {c1 c2} [lrange $b2 31 32] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.TxOversizePackets) $c
    
    foreach {c1 c2} [lrange $b2 34 35] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.TotalTxDroppedPackets) $c
    
    foreach {c1 c2} [lrange $b2 37 38] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.ClassificationErrors) $c
    
    foreach {c1 c2} [lrange $b2 40 41] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.ClassificationErrors) [::RL10GbGen::BigNum $a($ip_ID.port.$port.ClassificationErrors) + $c]
    
    foreach {c1 c2} [lrange $b2 43 44] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.ClassificationErrors) [::RL10GbGen::BigNum $a($ip_ID.port.$port.ClassificationErrors) + $c]
    
    foreach {c1 c2} [lrange $b2 46 47] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.ClassificationErrors) [::RL10GbGen::BigNum $a($ip_ID.port.$port.ClassificationErrors) + $c]
    
    foreach {c1 c2} [lrange $b2 49 50] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.ClassificationErrors) [::RL10GbGen::BigNum $a($ip_ID.port.$port.ClassificationErrors) + $c]
    
    foreach {c1 c2} [lrange $b2 53 54] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.ClassificationErrors) [::RL10GbGen::BigNum $a($ip_ID.port.$port.ClassificationErrors) + $c]
    
    foreach {c1 c2} [lrange $b2 58 59] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.ClassificationErrors) [::RL10GbGen::BigNum $a($ip_ID.port.$port.ClassificationErrors) + $c]
    
    foreach {c1 c2} [lrange $b2 61 62] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.ClassificationErrors) [::RL10GbGen::BigNum $a($ip_ID.port.$port.ClassificationErrors) + $c]
   
    foreach {c1 c2} [lrange $b2 64 65] {
      set c [::RL10GbGen::c1c2 $c1 $c2]
    }
    set a($ip_ID.port.$port.ClassificationErrors) [::RL10GbGen::BigNum $a($ip_ID.port.$port.ClassificationErrors) + $c]
  }
  set ::RL10GbGen::va10GbGenGui(status) "" ; update
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] StreamReadStatistics ip_ID:$ip_ID stream_id:$stream_id activity:$::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.activity)" ; update
  }
  return 0
  # ::RL10GbGen:: 
}
# ***************************************************************************
# c1c2
# ***************************************************************************
proc c1c2 {c1 c2} {
  if {![string is double $c1] || [string length $c1]==0 || \
      ![string is double $c2] || [string length $c2]==0} {
    if {$::RL10GbGen::g10GbGenBufferDebug} {
      puts "[::RL10GbGen::MyTime] c1c2 c1:<$c1> c2:<$c2>"
    }
    return -999999
  }
  set c1 [format %.1f $c1]
  set c2 [format %.1f $c2]
#   set c1 [scan $c1 %d]
#   set c2 [scan $c2 %d]
  if {$c1>0} {
    set 2pow32 [expr round([expr pow(2,32)])]
  } else {
    set 2pow32 0
  }  
  # set c [::RL10GbGen::BigFloat [::RL10GbGen::BigFloat $c1 * $2pow32] + $c2]
  set c [expr {$c1 * $2pow32 + $c2}]
  if {[string range $c end-1 end]==".0"} {
    set c [string range $c 0 end-2]
  }
  # puts "$c1 * $2pow32 + $c2 = $c"
  return $c
  # ::RL10GbGen::
}
# ***************************************************************************
# StreamClearStatistics
# ***************************************************************************
proc StreamClearStatistics {ip_ID stream_id} {
  set RxPort [::RL10GbGen::ParsePort $::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.RxPort)]
  set TxPort [::RL10GbGen::ParsePort $::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.TxPort)]
  set RxPortInt [::RL10GbGen::ParsePortNum2IntNum  $RxPort]
  set TxPortInt [::RL10GbGen::ParsePortNum2IntNum  $TxPort]
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] StreamClearStatistics $ip_ID $stream_id __TXport:$TxPort $TxPortInt  __RXport:$RxPort $RxPortInt"
  }
  set ret [SendTo10GbGen $ip_ID "mea oam 10G rmon clear $stream_id $RxPortInt $TxPortInt\r" "FPGA"]
  set ::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.startSec) [clock seconds]
  return $ret
}
# ***************************************************************************
# StreamClearRmon
# ***************************************************************************
proc StreamClearRmon {ip_ID port} {
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "StreamClearRmon $ip_ID $port" ; update
  }
  set ret [SendTo10GbGen $ip_ID "mea rmon clear $port\r" "FPGA"]
  return $ret
}


# ***************************************************************************
# ButStop
# ***************************************************************************
proc ButStop {} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  
  if ![::RL10GbGen::GlobalSanityCheck] {return}
  # ::RL10GbGen::DisableEnableEntries normal
  
  set portL [::RL10GbGen::GetEnabledPorts]
  if [llength $portL] {
    foreach activePort $portL {
      set id [lindex [split [lindex [split $activePort .] 0] :] end]
      set stream_id $::RL10GbGen::va10GbGenSet($activePort.strId)
      set ::RL10GbGen::va10GbGenSet($id.$stream_id.activity) stop 
      if {$::RL10GbGen::g10GbGenBufferDebug} {
        puts "[::RL10GbGen::MyTime] <$id.$stream_id> ButStop.activity==stop" ; update
      }  
    }  
  }
  return {}
}

# ***************************************************************************
# ButClearStats
# ***************************************************************************
proc ButClearStats {} {
  global gMessage
  set portL [::RL10GbGen::GetEnabledPorts]
  if [llength $portL] {
    foreach activePort $portL {
      set stream_id $::RL10GbGen::va10GbGenSet($activePort.strId)
      set chassis [lindex [split [lindex [split $activePort .] 0] :] 1]      
      set id $::RL10GbGen::va10GbGenStatuses($chassis,10GbGenID)
      set activity $::RL10GbGen::va10GbGenSet($id.$stream_id.activity)
      if {$::RL10GbGen::g10GbGenBufferDebug} {
        puts "[::RL10GbGen::MyTime] ButClearStats activePort:$activePort activity:$activity" ; update
      }
      ::RL10GbGen::ClearStatistics $id $stream_id
      ## if return to a running port it's previous activity, it will never call 
      ## to StreamClearStatistics from WhileLoopReadStats
      if {$activity=="stop" || $activity=="new"} {
        set ::RL10GbGen::va10GbGenSet($id.$stream_id.activity) $activity
      }
    }  
  }
#   if {$::RL10GbGen::g10GbGenBufferDebug} {
#     puts "[::RL10GbGen::MyTime] ButClearStats [parray ::RL10GbGen::va10GbGenSet *activity]" ; update
#   }
  return 0
}
# ***************************************************************************
# GuiIPV4
# ***************************************************************************
proc GuiIPV4 {activePort} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  variable va10GbGenSetTmp
  
  set base .topGuiIPV4
  if [winfo exists $base] {
    raise $base
    wm deiconify $base
    return 0
  }
  
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm resizable $base 0 0
  wm geometry $base +[expr {50+[winfo x .top10GbGenGui]}]+[expr {50+[winfo y .top10GbGenGui]}]
  wm title $base "IPv4 Setup in $activePort"
  set frFr [frame $base.frFr]
  set frBut [frame $base.frBut]
  
    set frIpv4 [TitleFrame $frFr.frIpv4 -text "IPv4 Setup"]
      set frA [$frIpv4 getframe] 
        # set frAddr [frame $frA.frAddr -bd 2 -relief groove]
          set l1 [Label $frA.l1 -text "Destination Address"]
          set ent1 [Entry $frA.ent1 \
              -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.ipv4DA)]   ; # -validate key -vcmd {::RL10GbGen::ValidIP %P}
          set va10GbGenGui(ipv4DA) $ent1 
          if {![info exists ::RL10GbGen::va10GbGenSetTmp($activePort.ipv4DA)] || $::RL10GbGen::va10GbGenSetTmp($activePort.ipv4DA)==""} {
            set va10GbGenSetTmp($activePort.ipv4DA) $::RL10GbGen::vaDefaults(ipv4DA)
          }    
          set l2 [Label $frA.l2 -text "Source Address"]
          set ent2 [Entry $frA.ent2 \
              -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.ipv4SA)]
          if {![info exists ::RL10GbGen::va10GbGenSetTmp($activePort.ipv4SA)] || $::RL10GbGen::va10GbGenSetTmp($activePort.ipv4SA)==""} {
            set va10GbGenSetTmp($activePort.ipv4SA) $::RL10GbGen::vaDefaults(ipv4SA)
          }
          set va10GbGenGui(ipv4SA) $ent2
          grid $l1 $ent1 -sticky w -padx 3 
          grid $l2 $ent2 -sticky w -padx 3
          
        # set frTtl [frame $frA.frTtl -bd 2 -relief groove] 
          set l1 [Label $frA.l3 -text "Time to Live"]
          set ent1 [Entry $frA.ent3 -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.ipv4Ttl)]
          set va10GbGenGui(ipv4Ttl) $ent1 
          if {![info exists ::RL10GbGen::va10GbGenSetTmp($activePort.ipv4Ttl)] || $::RL10GbGen::va10GbGenSetTmp($activePort.ipv4Ttl)==""} {
            set va10GbGenSetTmp($activePort.ipv4Ttl) $::RL10GbGen::vaDefaults(ipv4Ttl)
          } 
          grid $l1 $ent1 -sticky w -padx 3 
         
        # pack $frAddr $frTtl -anchor w -padx 2 -pady 2  
    
    set frTcp [TitleFrame $frFr.frTcp -text "TCP/IP Setup"]
      set frA [$frTcp getframe] 
        set l1 [Label $frA.l1 -text "Sequence Number"]
        set ent1 [Entry $frA.ent1 \
            -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.tcpSeqNum)]   ; # -validate key -vcmd {::RL10GbGen::ValidIP %P}
        set va10GbGenGui(tcpSeqNum) $ent1 
        if {![info exists ::RL10GbGen::va10GbGenSetTmp($activePort.tcpSeqNum)] || $::RL10GbGen::va10GbGenSetTmp($activePort.tcpSeqNum)==""} {
          set va10GbGenSetTmp($activePort.tcpSeqNum) $::RL10GbGen::vaDefaults(tcpSeqNum)
        } 
        
        set l2 [Label $frA.l2 -text "Acknowledge Number"]
        set ent2 [Entry $frA.ent2 \
            -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.tcpAckNum)]   ; # -validate key -vcmd {::RL10GbGen::ValidIP %P}
        set va10GbGenGui(tcpAckNum) $ent2 
        if {![info exists ::RL10GbGen::va10GbGenSetTmp($activePort.tcpAckNum)] || $::RL10GbGen::va10GbGenSetTmp($activePort.tcpAckNum)==""} {
          set va10GbGenSetTmp($activePort.tcpAckNum) $::RL10GbGen::vaDefaults(tcpAckNum)
        }
        grid $l1 $ent1 -sticky w -padx 3 
        grid $l2 $ent2 -sticky w -padx 3 
    
    set frUdp [TitleFrame $frFr.frUdp -text "UDP/IP Setup"]
      set frA [$frUdp getframe] 
        set l1 [Label $frA.l1 -text "Source Port"]
        set ent1 [Entry $frA.ent1 -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.ipv4UdpSP)]
        set va10GbGenGui(ipv4UdpSP) $ent1 
        if {![info exists ::RL10GbGen::va10GbGenSetTmp($activePort.ipv4UdpSP)] || $::RL10GbGen::va10GbGenSetTmp($activePort.ipv4UdpSP)==""} {
          set va10GbGenSetTmp($activePort.ipv4UdpSP) $::RL10GbGen::vaDefaults(ipv4UdpSP)
        } 
        set l2 [Label $frA.l2 -text "Destination Port"]
        set ent2 [Entry $frA.ent2 -textvariable ::RL10GbGen::va10GbGenSetTmp($activePort.ipv4UdpDP)]
        set va10GbGenGui(ipv4UdpDP) $ent2 
        if {![info exists ::RL10GbGen::va10GbGenSetTmp($activePort.ipv4UdpDP)] || $::RL10GbGen::va10GbGenSetTmp($activePort.ipv4UdpDP)==""} {
          set va10GbGenSetTmp($activePort.ipv4UdpDP) $::RL10GbGen::vaDefaults(ipv4UdpDP)
        }
        grid $l1 $ent1 -sticky w -padx 3 
        grid $l2 $ent2 -sticky w -padx 3 
    
    pack $frIpv4 $frTcp $frUdp -padx 2 -pady 2 -fill both
  
  pack $frFr -fill both -expand 1
  
  set disL [list]
  switch -exact -- $::RL10GbGen::va10GbGenSetTmp($activePort.IP) {
    None {
      lappend disL tcpSeqNum tcpAckNum ipv4UdpSP ipv4UdpDP
    }
    TCP {
      lappend disL ipv4UdpSP ipv4UdpDP
    }
    UDP {
      lappend disL tcpSeqNum tcpAckNum 
    }
    DHCP {} 
    GRE  {}
  }
  foreach w $disL {
    $va10GbGenGui($w) configure -state disabled
  }
  
    set bOk [Button $frBut.bOk -text "OK" -width 11 -command [list ::RL10GbGen::GuiIPV4ButOk $base $activePort] ]
    pack $bOk -side right -padx 2
  pack $frBut -fill x -pady 2
  
}
# ***************************************************************************
# GuiIPV4ButOk
# ***************************************************************************
proc GuiIPV4ButOk {base activePort} {
  set ret 0
  foreach elem {ipv4DA ipv4SA} elemN {"Dest. Address" "Source Address"} {
    set v $::RL10GbGen::va10GbGenSetTmp($activePort.$elem)
    set v [string trim $v]
    if [regexp -all {[^\d\.]} $v] {
      set ret -1
      break
    }
    set subNetL [split $v .]
    if {[llength $subNetL]!=4} {
      set ret -1
      break
    }
    foreach subNet $subNetL {
      if {[string length $subNet]==0 || [string length $subNet]>3} {
        set ret -1
        break  
      }
    }
    if {$ret!=0} {break}
  }  
  if {$ret!=0} {
    tk_messageBox -message "The $elemN - $v - is wrong"
    return
  } 
  
  set v $::RL10GbGen::va10GbGenSetTmp($activePort.ipv4Ttl)
  if {[string is integer $v]==0 || $v<0 || $v>255} {
    tk_messageBox -message "The TTL - $v - is wrong"
    return
  }
  
  foreach elem {tcpSeqNum tcpAckNum} elemN {"Sequence Number" "Acknowledge Number"} {
    set v $::RL10GbGen::va10GbGenSetTmp($activePort.$elem)
    set v [string trim $v]
    if [regexp -all {[^\d\sA-Fa-f]} $v] {
      set ret -1
      break
    }
    set subNetL [split $v " "]
    if {[llength $subNetL]!=4} {
      set ret -1
      break
    }
    foreach subNet $subNetL {
      if {[string length $subNet]==0 || [string length $subNet]>2 || $subNet>0xFF} {
        set ret -1
        break  
      }
    }
    if {$ret!=0} {break}
  }  
  if {$ret!=0} {
    tk_messageBox -message "The $elemN - $v - is wrong"
    return
  } 
  
  destroy $base
}

# ***************************************************************************
# ValidIP
# ***************************************************************************
proc ValidIP {str} {
  set ipnum1 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
  set ipnum2 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
  set ipnum3 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
  set ipnum4 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
  set fullExp {^($ipnum1)\.($ipnum2)\.($ipnum3)\.($ipnum4)$}
  set partialExp {^(($ipnum1)(\.(($ipnum2)(\.(($ipnum3)(\.(($ipnum4)?)?)?)?)?)?)?)?$}
  set fullExp [subst -nocommands -nobackslashes $fullExp]
  set partialExp [subst -nocommands -nobackslashes $partialExp]
  return [regexp -- $partialExp $str]  
}
# ***************************************************************************
# FineTuningGui
# ***************************************************************************
proc FineTuningGui {} {
  variable va10GbGenSet
  variable va10GbGenSetTmp
  variable g10GbGenBufferDebugTmp
  set base .topFineTuningGui
  if [winfo exists $base] {
    raise $base
    wm deiconify $base
    return 0
  }
  if ![info exists ::RL10GbGen::va10GbGenSet(readStreamEach)] {
    set ::RL10GbGen::va10GbGenSet(readStreamEach) 10
  }
  
  set ::RL10GbGen::va10GbGenSetTmp(clockFreq) $::RL10GbGen::va10GbGenSet(clockFreq)
  set ::RL10GbGen::va10GbGenSetTmp(readStreamEach) $::RL10GbGen::va10GbGenSet(readStreamEach)
  set ::RL10GbGen::g10GbGenBufferDebugTmp $::RL10GbGen::g10GbGenBufferDebug
  
  if ![info exists ::RL10GbGen::va10GbGenSet(lastEthType)] {
    set ::RL10GbGen::va10GbGenSet(lastEthType) $::RL10GbGen::vaDefaults(lastEthType)
  }
  set ::RL10GbGen::va10GbGenSetTmp(lastEthType) $::RL10GbGen::va10GbGenSet(lastEthType)
  
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm resizable $base 0 0
  wm geometry $base +[expr {50+[winfo x .top10GbGenGui]}]+[expr {50+[winfo y .top10GbGenGui]}]    ; # 650x370
  wm title $base "Fine Tuning"
  set frFr [frame $base.frFr]
    set fr1 [frame $frFr.fr1 -bd 0 -relief groove]
      set l1 [Label $fr1.l1 -text "Clock frequency, \[MHz\]"]
      set ent1 [Entry $fr1.ent1 -justify center -width 5\
          -textvariable ::RL10GbGen::va10GbGenSetTmp(clockFreq) \
          -validate key -vcmd {expr [string is integer %P]}]
      # set chb2 [checkbutton $fr1.chb2 -variable ::RL10GbGen::g10GbGenBufferDebugTmp \
          -text "Console activation"] 
      set l2 [Label $fr1.l2 -text "Last ETHType"]
      set ent2 [Entry $fr1.ent2 -justify center -width 4\
          -textvariable ::RL10GbGen::va10GbGenSetTmp(lastEthType) \
          -validate key -vcmd {expr [string is xdigit %P]}]       
      grid $l1 $ent1 -pady 2 -padx 4 
      grid $l2 $ent2 -pady 2 -padx 4
      # grid $chb2 -columnspan 2 -sticky w -pady 2
    pack $fr1 -fill both -expand 1    
  pack $frFr -fill both -expand 1
  set frBut [frame $base.frBut]
    set bOk [Button $frBut.bOk -text "Save" -width 11 -command [list ::RL10GbGen::FineTuningGuiButOk $base] ]
    set bCa [Button $frBut.bCa -text "Cancel" -width 11 -command [list ::RL10GbGen::FineTuningGuiButCa $base ]]
    pack $bCa $bOk -side right -padx 2
  pack $frBut -fill x -pady 2
  ## ::RL10GbGen::
}
# ***************************************************************************
# FineTuningGuiButOk
# ***************************************************************************
proc FineTuningGuiButOk {base} {
  variable va10GbGenSet
  variable va10GbGenSetTmp 
  set va10GbGenSet(clockFreq) $va10GbGenSetTmp(clockFreq)
  set va10GbGenSet(lastEthType) $va10GbGenSetTmp(lastEthType)
  # set va10GbGenSet(readStreamEach) $va10GbGenSetTmp(readStreamEach)
  # set ::RL10GbGen::g10GbGenBufferDebug $::RL10GbGen::g10GbGenBufferDebugTmp
  ::RL10GbGen::FineTuningGuiButCa $base  
}
# ***************************************************************************
# FineTuningGuiButOk
# ***************************************************************************
proc FineTuningGuiButCa {base} {
  destroy $base
}



# ................................................................................
#  Abstract: Connect chassis to host by telnet or com.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc ConnectChassis {} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
	variable address
	variable titlname1
	variable titlname2
	variable frBut
	variable package
  
  
  set reslist  [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) home]
  if {[llength $reslist]==2} {
    tk_messageBox -title "Connect chassis" -message "Up to two chassises may be connected"
    return 0
  }

  if {[winfo exists .connChassis10GbGen]} {focus -force .connChassis10GbGen; return}
  toplevel .connChassis10GbGen -class Toplevel
  wm focusmodel .connChassis10GbGen passive
  wm resizable .connChassis10GbGen 0 0
  wm title .connChassis10GbGen "Connect"
  wm protocol .connChassis10GbGen WM_DELETE_WINDOW {destroy .connChassis10GbGen}
  set b .connChassis10GbGen 
  wm geometry $b +[expr {50+[winfo x .top10GbGenGui]}]+[expr {50+[winfo y .top10GbGenGui]}]
  
	  set titlname1 [TitleFrame $b.titlname1 -text "Com number"]
	    set va10GbGenGui(cb,connect,com) [ComboBox [$titlname1 getframe].com  -justify center \
               -textvariable ::RL10GbGen::va10GbGenSet(connect,com) -width 15 \
							 -modifycmd {set ::RL10GbGen::address $::RL10GbGen::va10GbGenSet(connect,com) ; set ::RL10GbGen::package $::RL10GbGen::va10GbGenSet(comPackage)}\
               -values {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33} \
               -helptext "This is the Com number"]
		  pack $va10GbGenGui(cb,connect,com)

	  set titlname2 [TitleFrame $b.titlname2 -text "IP address"]
	    set va10GbGenGui(cb,connect,telnet) [ComboBox [$titlname2 getframe].telnet  -justify center \
               -textvariable ::RL10GbGen::va10GbGenSet(connect,telnet) -width 15 -modifycmd {set ::RL10GbGen::address $::RL10GbGen::va10GbGenSet(connect,telnet) ; set ::RL10GbGen::package RLPlink}\
               -values $::RL10GbGen::va10GbGenSet(listIP) \
               -helptext "This is the IP address"]
		   pack $va10GbGenGui(cb,connect,telnet)

    set frBut [frame $b.frBut]

    set frConntype [TitleFrame $b.frConntype -text "Connect"]
	    set comrb [radiobutton [$frConntype getframe].rad1 -text "Com" -value 1 -variable ::RL10GbGen::va10GbGenSet(connectBy)\
              -command  {set ::RL10GbGen::address $::RL10GbGen::va10GbGenSet(connect,com)
  											 set ::RL10GbGen::package RLSerial
							           catch {pack forget $::RL10GbGen::titlname1 $::RL10GbGen::titlname2 $::RL10GbGen::frBut}
						             pack $::RL10GbGen::titlname1 $::RL10GbGen::frBut}]
	    set telrb [radiobutton [$frConntype getframe].rad2 -text "Telnet" -value 0 -variable ::RL10GbGen::va10GbGenSet(connectBy)\
              -command  {set ::RL10GbGen::address $::RL10GbGen::va10GbGenSet(connect,telnet)
 												 set ::RL10GbGen::package RLPlink
							           catch {pack forget $::RL10GbGen::titlname1 $::RL10GbGen::titlname2 $::RL10GbGen::frBut} 
											   pack $::RL10GbGen::titlname2 $::RL10GbGen::frBut}]
		  pack $comrb $telrb -side left 
		  set ::RL10GbGen::address $::RL10GbGen::va10GbGenSet(connect,com)
	    # catch {pack forget $::RL10GbGen::titlname1 $::RL10GbGen::titlname2 $::RL10GbGen::frBut}
			# pack $::RL10GbGen::titlname1 $::RL10GbGen::frBut
	  # pack $frConntype
		if {![info exists ::RL10GbGen::package]} {
	    pack $titlname1
	  } elseif {$::RL10GbGen::package == "RLPlink"} {
    	pack $titlname2
		} else {
  	  pack $titlname1
		}

    set va10GbGenGui(connect,telnet) [button $frBut.butOk -text Ok -width 9 -command {
      	if {[info exists ::RL10GbGen::package] && $::RL10GbGen::package == "RLPlink"} {
    		  set ::RL10GbGen::address $::RL10GbGen::va10GbGenSet(connect,telnet)
    		}
        if {[info exists ::RL10GbGen::va10GbGenSet(connectBy)] && $::RL10GbGen::va10GbGenSet(connectBy)==0} {
          set ::RL10GbGen::package RLPlink
          set ::RL10GbGen::address $::RL10GbGen::va10GbGenSet(connect,telnet)
        } elseif {[info exists ::RL10GbGen::va10GbGenSet(connectBy)] && $::RL10GbGen::va10GbGenSet(connectBy)==1} {
          set ::RL10GbGen::package RLSerial
          set ::RL10GbGen::address $::RL10GbGen::va10GbGenSet(connect,com)
        } 
    		if {![info exists ::RL10GbGen::address] || ![info exists ::RL10GbGen::package] || $::RL10GbGen::address == "" || $::RL10GbGen::package == ""} {
    		  set gMessage  "Please select all entries"
    			tk_messageBox -icon error -type ok -message "$gMessage" -title "Etx204A Generator"
    			return    
    	  }
    		::RL10GbGen::OkConnChassis $::RL10GbGen::address $::RL10GbGen::package 0 connectChs
      }]
    pack $va10GbGenGui(connect,telnet) 

    pack $frBut -padx 3 -pady 3 -fill both
		$va10GbGenGui(cb,connect,telnet) configure -command {$::RL10GbGen::va10GbGenGui(connect,telnet) invoke} -takefocus 1
  focus -force $b

}	
# ***************************************************************************
# OkConnChassis
# ***************************************************************************
proc OkConnChassis {address package id calledFrom} {
  global gMessage g10GbGenBuffer
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses

	set resources ""
  set reslist  [Tree::nodes $va10GbGenGui(resources,list) home]
	if {$reslist != ""} {
		foreach chassis $reslist {
	  	set ch [lindex [split $chassis :] 1]
    	lappend resources $va10GbGenStatuses($ch,address) $va10GbGenStatuses($ch,package)
		}
	}

	if {$resources != ""} {
		if {[lsearch $resources $address] != -1} {
			set gMessage  "There is already given address: $address into resources"
			tk_messageBox -icon error -type ok -message "$gMessage" -title "Etx220 Generator"
	    return    
		}
	}

	if {[info exists va10GbGenGui(connect,telnet)]} {
	  catch {$va10GbGenGui(connect,telnet) configure -state disable -relief sunken}
	}
	::RL10GbGen::10GbGenshow_progdlg "connecting"
	# the id doesn't compared to nul when this procedure invoked from ShowGui proc.
	if {!$id} {
		if [catch {::RL10GbGen::Open $address} id] {
      if {$::RL10GbGen::g10GbGenBufferDebug} {
        puts "OkConnChassis id:$id"; update
		  }
      destroy .progress
  	  if {[info exists va10GbGenGui(connect,telnet)]} {
	   	  $va10GbGenGui(connect,telnet) configure -state normal -relief raised
			}
			append gMessage  "\nFail while (::RL10GbGen::Open $address -package $package) procedure"
			tk_messageBox -icon error -type ok -message "$gMessage" -title "Etx220A Generator"
	    return    
		}
	}
	set va10GbGenSet(currentid) $id

	# parray	va10GbGenCfg
	# parray	va10GbGenStatuses
	if {[info exists va10GbGenGui(connect,telnet)]} {
   	catch {$va10GbGenGui(connect,telnet) configure -state normal -relief raised}
	}
  
  set tree $va10GbGenGui(resources,list)
  switch -exact -- $package {
    RLSerial {set addr com}
    telnet   {set addr telnet}
    default  {set addr ""}  
  }
  $tree insert end home chassis:$id -text  "Chassis $id ($addr $address)" -image [Bitmap::get folder] -drawcross allways -data  $id -open 1
  TestTreeInit $id $tree
  
    
	set va10GbGenSet(currentchass) chassis:$id
	
	if {[lsearch $va10GbGenSet(listIP) $va10GbGenSet(connect,telnet)] == -1} {
	  lappend va10GbGenSet(listIP)	  $va10GbGenSet(connect,telnet)
	}
	destroy .progress
  catch {destroy .connChassis10GbGen}

  set res 0
  # SendTo10GbGen $id "mea ser sh ser \r" "FPGA>>"
  # set res [regexp {0[\s\|]+21[\s\|]+9[\s\|]+0x1FFF} $g10GbGenBuffer(id$id)]
  
  set openStreams ""
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "Open10GbGen res:$res calledFrom:$calledFrom openStreams:$openStreams"
  }
  if {$res==0 && ($calledFrom=="connectChs" || ($calledFrom=="getCfg" && $openStreams==""))} {
    set ret [::RL10GbGen::GenConfig $id cfg]
  }
  .top10GbGenGui.mainframe setmenustate reset normal
  $va10GbGenGui(tb,gi) configure -state normal
  set ::RL10GbGen::va10GbGenStatuses($id.globalInitPerformed) 1 
  $tree selection set chassis:1
  console eval { set ::tk::console::maxLines 100000 }
  
	# puts $address
}
# ***************************************************************************
# **                        Open10GbGen
# ** 
# **  Abstract: The internal procedure Open the EGate-100 by com or telnet
# **            Check if it is ready to be activate
# **
# **   Inputs:
# **            ip_address           :	        Com number or IP address.
# **                              
# **  					 ip_connection        :	        com/telnet.
# **                              
# **  					 ip_package           :	        RLCom/RLSerial/RLTcp/RLPlink.
# **                              
# **            ip_place             :         location into va10GbGenStatuses array
# **                              
# **   Outputs: 
# **            0                    :         If success. 
# **            Negativ error cod    :         Otherwise.     
# ***************************************************************************
proc Open10GbGen {ip_address ip_connection ip_package ip_place} {
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "Open10GbGen $ip_address $ip_connection $ip_package $ip_place"; update
  }
  global        gMessage
  global        g10GbGenBuffer
  variable      va10GbGenStatuses 
  variable      vOpened10GbGenHistoryCounter
  variable      oam_port
  variable      drop_cluster
  variable      oam_cluster
  variable      ia 
  set gMessage ""                   

	set fail          -1
	set ok             0
  set drop_cluster   61
  set oam_port       21
  set oam_cluster    60
  set ia              1

  switch -exact -- $ip_connection  {
    

			com {
            package require $ip_package
            if {$ip_package == "RLCom"} {
						  if [catch {RLCom::Open $ip_address 115200 8 NONE 1 } msg] {
						    set gMessage "Open10GbGen:  Cann't open com by RLSerial: $msg"
						    return $fail
							}
            } else {
                if {[RLSerial::Open $ip_address 115200 n 8 1]} {
							    set gMessage "Open10GbGen:  Cann't open com$ip_address by RLSerial"
							    return $fail
								}
            }
            set  va10GbGenStatuses($ip_place,10GbGenHandle) $ip_address

      }

			telnet {
        package require $ip_package
        if {$ip_package == "RLTcp"} {
            set handle [RLTcp::TelnetOpen $ip_address]
        } else {
            set handle [RLPlink::Open $ip_address -protocol telnet]
        }
        set  va10GbGenStatuses($ip_place,10GbGenHandle) $handle

      }
  }

	set ret 0
  for {set i 1} {$i <= 60} {incr i} {
    SendTo10GbGen $ip_place "\r\r" "FPGA" 1
    if {[string match *FPGA* $g10GbGenBuffer(id$ip_place)]} {
      set ret 0
      break
    }
  }
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts ret2:$ret 
  }
  if {$ret==0} {
    if {[string match {*ETX-220*} $g10GbGenBuffer(id$ip_place)]} {
      SendTo10GbGen $ip_place "debug mea\r\r" "FPGA" 5
      
    }
  }
  
  if {$ret!=0} {
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
        } elseif {$ip_package == "RLPlink" } {
          RLPlink::Close $handle
        }
      }
    }
    set va10GbGenStatuses($ip_place,currScreen) "na"
    set gMessage "Open10GbGen:  Can't connect to ETX220($ip_place) device"
    return $fail
  }
  set g10GbGenBuffer(id$ip_place) "(Stop)"
  set  va10GbGenStatuses($ip_place,etxRun) 0
  
	if {$ret} {
    set va10GbGenStatuses($ip_place,currScreen) "na"
    set gMessage "Open10GbGen:  Fail while define port number ETX220($ip_place)"
	} else {
    set va10GbGenStatuses($ip_place,currScreen) "Gen"
    set va10GbGenStatuses($ip_place,updGen) "All"
	}
    
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts ret1:$ret
  }
  return $ret
}

# ***************************************************************************
# GenConfig
# ***************************************************************************
proc GenConfig {ip_ID mode} {
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "GenConfig $ip_ID $mode"
  }
  global        g10GbGenBuffer
  global        gMessage
  variable      va10GbGenStatuses 
  variable      vOpened10GbGenHistoryCounter
  variable      oam_port
  variable      drop_cluster
  variable      oam_cluster
  variable      ia 
  set gMessage ""                   
	set fail          -1
	set ok             0
  set drop_cluster   61
  set oam_port       21
  set oam_cluster    60
  set ia              1
  ::RL10GbGen::Defaults
  set ::RL10GbGen::va10GbGenSet(lastEthType) $::RL10GbGen::vaDefaults(lastEthType)
  
  if {![info exists va10GbGenStatuses($ip_ID,10GbGenID)]} {
  	set	gMessage "GenConfig procedure: The 10GbGen with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$va10GbGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "GenConfig procedure: The plink process doesn't exist for 10GbGen with ID=$ip_ID"
      return $fail
    }
  }

  set ::RL10GbGen::va10GbGenGui(status) "Global Initialisation of Chassis $ip_ID" ; update
  ::RL10GbGen::10GbGenshow_progdlg "Global Init of Chassis $ip_ID"
	set ret 0
	SendTo10GbGen $ip_ID "\r\r" "FPGA" 6
	SendTo10GbGen $ip_ID "top\r" "FPGA" 6
  
  if {$mode=="cfg"} {
    SendTo10GbGen $ip_ID "mea ser set del all\r" "FPGA"
    SendTo10GbGen $ip_ID "mea mod acl del 0 all\r" "FPGA"
    SendTo10GbGen $ip_ID "mea mod acl del 2 all\r" "FPGA"
    foreach pm {0 1 2 3 4 5 6 7} port {1 2 3 4 28 29 30 31} {
      SendTo10GbGen $ip_ID "mea oam 10G tx active set $pm 0\r" "FPGA"  
      SendTo10GbGen $ip_ID "mea oam 10G rx ena set $pm 0\r" "FPGA" 
      SendTo10GbGen $ip_ID "mea oam 10G rmon clear $pm $port\r" "FPGA" 
    }
  } elseif {$mode=="reinit"} {
    SendTo10GbGen $ip_ID "mea fpga reinit\r\r" "stam" 1
    for {set sec 0} {$sec<=40} {incr sec} {
      set ret [RLSerial::Waitfor $va10GbGenStatuses($ip_ID,10GbGenHandle) g10GbGenBuffer(id$ip_ID) "FPGA" 1]
      if {$::RL10GbGen::g10GbGenBufferDebug} {
        puts "sec:$sec" ; update
      }
      if {$ret==0} {break}
    }
  }
  SendTo10GbGen $ip_ID "me oam 10G rmon dis 1 \r" "FPGA"
  SendTo10GbGen $ip_ID "me gl set policer 0 \r" "FPGA"
  SendTo10GbGen $ip_ID "me gl se mqs 0 \r" "FPGA"
  SendTo10GbGen $ip_ID "me gl se bmqs 0 \r" "FPGA"  
  SendTo10GbGen $ip_ID "me queue Cluster Create 20 60 -m 2000 \r" "FPGA" 20
  SendTo10GbGen $ip_ID "me port ing set 20 -p 9 -s 0 -a 1 -v 224 \r" "FPGA"
  SendTo10GbGen $ip_ID "me port eg set 20 -a 1 \r" "FPGA"
  SendTo10GbGen $ip_ID "me port ing set 21 -p 9 -s 0 -a 1 -v 224 \r" "FPGA"
  SendTo10GbGen $ip_ID "me port eg set 21 -a 1 \r" "FPGA"
  foreach pp {1 2 3 4 28 29 30 31} {
    SendTo10GbGen $ip_ID "me port ing set $pp -p 9 -s 0 -a 1 -v 224 \r" "FPGA"
    SendTo10GbGen $ip_ID "me port eg set $pp -a 1 \r" "FPGA"
    SendTo10GbGen $ip_ID "me queue Cluster Create $pp $pp -m 2000 \r" "FPGA" 20
  }
  
  # # SendTo10GbGen $ip_ID "mea oam 10G tx param set $IPG $min_psize $max_psize \r" "FPGA>>"
	
  SendTo10GbGen $ip_ID "me ser set cre 21 0x1fff 0x1ffe 0x1ffe 0x7f 0x7f 0 1 0 1000000000 0 64000 0 0 1 $drop_cluster -tm 0 -pm 0 -acl 0 00:00:00:00:00:00 -acl-out $drop_cluster -un 1 \r" "FPGA"

  destroy .progress
  set ::RL10GbGen::va10GbGenGui(status) "" ; update
  after 1000

  if {$ret} {
		set va10GbGenStatuses($ip_ID,currScreen) "na"
	}
  return $ret
}

# ***************************************************************************
# StreamConfig
# ***************************************************************************
proc StreamConfig {ip_ID stream_id tx_port rx_port args} {
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "StreamConfig $ip_ID $stream_id $tx_port $rx_port $args"
  }
  global        g10GbGenBuffer
  global        gMessage
  variable      va10GbGenStatuses 
  variable      vOpened10GbGenHistoryCounter
  variable      va10GbGenSet
  set gMessage ""                   
	set fail          -1
	set ok             0
  variable      oam_port
  variable      drop_cluster
  variable      oam_cluster
  variable      ia 
  # ::RL10GbGen::va10GbGenSet
  
  
  if {[llength [split $stream_id :]]==1} {
    set chassis 1
    set port [expr {1 + $stream_id }]
    # set port $stream_id
  } else {
    set chassis [lindex [split $stream_id :] 0]
    set port    [lindex [split $stream_id :] 1]
  }
  set activePort chassis:$chassis.Port:$port  
  
  if {$ip_ID == "?"} {
    return "arguments options:  , -DA 10101010, -minPacketSize 64, -maxPacketSize 2000, \
        -IPG 20, -seqErrorThreshold 60"
  }

  if {![info exists va10GbGenStatuses($ip_ID,10GbGenID)]} {
  	set	gMessage "Config procedure: The 10GbGen with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  if {$va10GbGenStatuses($ip_ID,package) == "RLPlink"} {
    if {[CheckPlinkExist $ip_ID ]} {
  	  set	gMessage "Config procedure: The plink process doesn't exist for 10GbGen with ID=$ip_ID"
      return $fail
    }
  }  
  set headersLen 0
  
  set tx_port_stream [::RL10GbGen::ParsePortNum2IntNum $tx_port] 
  set received_port_stream [::RL10GbGen::ParsePortNum2IntNum $rx_port]
  
  if {[lsearch $args -da]=="-1"} {
    lappend args -da $::RL10GbGen::vaDefaults(DA)
  }
  if {[lsearch $args -sa]=="-1"} {
    lappend args -sa $::RL10GbGen::vaDefaults(SA)
  }
  if {[lsearch $args -minPacketSize]=="-1"} {
    lappend args -minPacketSize $::RL10GbGen::vaDefaults(PacketMinLen)
  }
  if {[lsearch $args -maxPacketSize]=="-1"} {
    lappend args -maxPacketSize $::RL10GbGen::vaDefaults(PacketMaxLen)
  }
  if {[lsearch $args -IPG]=="-1"} {
    lappend args -IPG $::RL10GbGen::vaDefaults(IPG)
  }
  if {[lsearch $args -seqErrorThreshold]=="-1"} {
    lappend args -seqErrorThreshold $::RL10GbGen::vaDefaults(SeqErrorThreshold)
  }
  set disVlanQty 0
  foreach v {1 2 3 4} {
    if {[lsearch $args -vlan$v ]=="-1"} {
      set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.$v) 0
      incr disVlanQty
    }
  }
  if {$disVlanQty==4} {
    # # all 4 vlans absent in the args list
    set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 0
  }
  if {[lsearch $args -sizeType]=="-1"} {
    set args [linsert $args 0 -sizeType]
    set args [linsert $args 1 $::RL10GbGen::vaDefaults(FrameSizeType)]
    #lappend args -sizeType $::RL10GbGen::vaDefaults(FrameSizeType)
  }
  if {[lsearch $args -size]=="-1"} {
    lappend args -size $::RL10GbGen::vaDefaults(PacketFixLen)
  }
  if {[lsearch $args -streamControl]=="-1"} {
    lappend args -streamControl $::RL10GbGen::vaDefaults(PacketBurst)
  }
  if {[lsearch $args -clkFreq]=="-1"} {
    lappend args -clkFreq $::RL10GbGen::vaDefaults(clockFreq)
  }
  if {[lsearch $args -lineRate]=="-1"} {
    lappend args -lineRate $::RL10GbGen::vaDefaults(LineRate)
  }
  if {[lsearch $args -dataPatternType]=="-1"} {
    lappend args -dataPatternType $::RL10GbGen::vaDefaults(PatternType)
  }
  if {[lsearch $args -dataPatternData]=="-1"} {
    lappend args -dataPatternData $::RL10GbGen::vaDefaults(PatternData)
  }
   
  # # an previous loop to capture the clkFreq before -rate 
  foreach {param val} $args {   
    # puts "$param $val" ; update
    switch -exact -- $param  {
      -clkFreq {set clkFreq $val}
    }
  }  
  # puts "args:$args"
  foreach {param val} $args {   
    if {$::RL10GbGen::g10GbGenBufferDebug} {
      puts "$param $val" ; update
    }
    switch -exact -- $param  {
      -da {
        set ret [expr {[string is xdigit $val] && [string length $val]==12}]   
        if {$ret == 0} {
			    set gMessage "Config procedure: -da $val is wrong"
          return [RLEH::Handle SAsyntax gMessage]
				} else {
					set dMac $val
          foreach {dMac1 dMac2 dMac3 dMac4 dMac5 dMac6} [::RL10GbGen::SplitString2Paires $dMac] {}
          set dMac6 [format %.2x [expr { 2 * $stream_id } ]]
          set ::RL10GbGen::va10GbGenSet($activePort.DA) $dMac
          incr headersLen 6
			  }
        foreach mac {dMac1 dMac2 dMac3 dMac4 dMac5 dMac6} {
          if {$::RL10GbGen::g10GbGenBufferDebug} {
            puts "$mac:[set $mac]"
          }  
        }          
			}
         
      -sa {
        set ret [expr {[string is xdigit $val] && [string length $val]==12}]   
        if {$ret == 0} {
			    set gMessage "Config procedure: -sa $val is wrong"
          return [RLEH::Handle SAsyntax gMessage]
				} else {
					set sMac $val
          foreach {sMac1 sMac2 sMac3 sMac4 sMac5 sMac6} [::RL10GbGen::SplitString2Paires $sMac] {}
          set ::RL10GbGen::va10GbGenSet($activePort.SA) $sMac
          incr headersLen 6
			  }
#         puts "inside StreamConfig -sa activePort:$activePort"
#         parray ::RL10GbGen::va10GbGenSet *:\[123\].SA
			} 
      -minPacketSize {
        if {![string is integer $val] || $val < 64 || $val > 2000} {
			    set gMessage "Config procedure: -minPacketSize $val is wrong. Should be integer between 64 and 2000"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set min_psize $val
      }
      -maxPacketSize {
        if {![string is integer $val] || $val < 64 || $val > 2000} {
			    set gMessage "Config procedure: -maxPacketSize $val is wrong. Should be integer between 64 and 2000"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set max_psize $val
      }
      -IPG {
        if {![string is integer $val] || $val < 8 || $val > 31} {
			    set gMessage "Config procedure: -IPG $val is wrong. Should be integer between 8 and 31"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set IPG $val
      }
      -seqErrorThreshold {
        if {![string is integer $val] || $val < 0 || $val > 128} {
			    set gMessage "Config procedure: -seqErrorThreshold $val is wrong. Should be integer between 0 and 128"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set Seq_error_threshold_stream $val
      }
      
      -vlan1 {
        if {![string is integer $val] || $val < 0 || $val > 4095} {
			    set gMessage "Config procedure: -vlan1 $val is wrong. Should be integer between 0 and 4095"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.1) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.Id.1) $val  
        incr headersLen 4  
      }
      -pBit1 {
        if {![string is integer $val] || $val < 0 || $val > 7} {
			    set gMessage "Config procedure: -pBit1 $val is wrong. Should be integer between 0 and 7"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.1) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.uPri.1) $val  
      }
      -cfi1 {
        if {$val != "Reset" &&  $val != "Set"} {
			    set gMessage "Config procedure: -cfi1 $val is wrong. Should be Reset or Set"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.1) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.cfi.1) $val  
      }
      -protocolId1 {
        if {$val != "0x8100" &&  $val != "0x88a8"} {
			    set gMessage "Config procedure: -protocolId1 $val is wrong. Should be 0x8100 or 0x88a8"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.1) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.pid.1) $val  
      }
      -vlan2 {
        if {![string is integer $val] || $val < 0 || $val > 4095} {
			    set gMessage "Config procedure: -vlan2 $val is wrong. Should be integer between 0 and 4095"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.2) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.Id.2) $val    
        incr headersLen 4
      }
      -pBit2 {
        if {![string is integer $val] || $val < 0 || $val > 7} {
			    set gMessage "Config procedure: -pBit2 $val is wrong. Should be integer between 0 and 7"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.2) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.uPri.2) $val   
      }
      -cfi2 {
        if {$val != "Reset" &&  $val != "Set"} {
			    set gMessage "Config procedure: -cfi2 $val is wrong. Should be Reset or Set"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.2) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.cfi.2) $val  
      }
      -protocolId2 {
        if {$val != "0x8100" &&  $val != "0x88a8"} {
			    set gMessage "Config procedure: -protocolId2 $val is wrong. Should be 0x8100 or 0x88a8"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.2) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.pid.2) $val  
      }   
      -vlan3 {
        if {![string is integer $val] || $val < 0 || $val > 4095} {
			    set gMessage "Config procedure: -vlan3 $val is wrong. Should be integer between 0 and 4095"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.3) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.Id.3) $val 
        incr headersLen 4 
      }
      -pBit3 {
        if {![string is integer $val] || $val < 0 || $val > 7} {
			    set gMessage "Config procedure: -pBit3 $val is wrong. Should be integer between 0 and 7"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.3) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.uPri.3) $val  
      }
      -cfi3 {
        if {$val != "Reset" &&  $val != "Set"} {
			    set gMessage "Config procedure: -cfi3 $val is wrong. Should be Reset or Set"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.3) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.cfi.3) $val  
      }
      -protocolId3 {
        if {$val != "0x8100" &&  $val != "0x88a8"} {
			    set gMessage "Config procedure: -protocolId3 $val is wrong. Should be 0x8100 or 0x88a8"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.3) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.pid.3) $val  
      } 
      -vlan4 {
        if {![string is integer $val] || $val < 0 || $val > 4095} {
			    set gMessage "Config procedure: -vlan4 $val is wrong. Should be integer between 0 and 4095"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.4) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.Id.4) $val 
        incr headersLen 4 
      }
      -pBit4 {
        if {![string is integer $val] || $val < 0 || $val > 7} {
			    set gMessage "Config procedure: -pBit4 $val is wrong. Should be integer between 0 and 7"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.4) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.uPri.4) $val  
      }   
      -cfi4 {
        if {$val != "Reset" &&  $val != "Set"} {
			    set gMessage "Config procedure: -cfi4 is wrong. Should be Reset or Set"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.4) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.cfi.4) $val  
      }   
      -protocolId4 {
        if {$val != "0x8100" &&  $val != "0x88a8"} {
			    set gMessage "Config procedure: -protocolId4 $val is wrong. Should be 0x8100 or 0x88a8"
          return [RLEH::Handle SAsyntax gMessage]
				}
        set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.4) 1
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.pid.4) $val  
      }  
      -sizeType {
        if {[regexp {(fixed|incr|random|emix)} [string tolower $val] - type] == 0} {
	        set	gMessage "Stream Config procedure: Wrong packet size type: must be Fixed or Incr or Random or EMIX (Etx220($ip_ID))"
          return $fail
      	} else {
          switch -exact -- [string tolower $val] {
            fixed  {set ptype_stream 0}
            incr   {set ptype_stream 1}
            random {set ptype_stream 2}
            emix   {set ptype_stream 3}
          }
        } 
      }
      -size {
        if {$ptype_stream=="3"} {
          ## EMIX
          set emix_stream [list]          
          foreach si [split $val " "] emix {0 1 2 3 4 5 6 7} {
            if {$si==""} {break}
            set ::RL10GbGen::va10GbGenSet($activePort.PacketEmixEn$emix) 1
            switch -exact -- $si {
              64   {set indx 0}
              128  {set indx 1}
              256  {set indx 2}
              512  {set indx 3}
              1024 {set indx 4}
              1280 {set indx 5}
              1518 {set indx 6}
              2000 {set indx 7}
            }
            set emix_stream [concat $emix_stream $emix $indx]            
          }
          set psize_stream 1000
          set emixnum_stream [expr {$emix-1}]
          set dTableSize [expr {$max_psize/16}]
        } elseif {$ptype_stream=="0"} {
          ## Fixed
          set psize_stream $val
          set ::RL10GbGen::va10GbGenSet($activePort.PacketFixLen) $val
          set emix_stream "1 64"
          set emixnum_stream 1
          set dTableSize [expr {$psize_stream/16}]
        } elseif {$ptype_stream=="1" || $ptype_stream=="2"} {
          ## Increment or Random - in these cases the min and max are defined by 
          ## min_psize and max_psize
          set psize_stream 64
          set emix_stream "1 64"
          set emixnum_stream 1
          set dTableSize [expr {$max_psize/16}]
        }        
      } 
      -streamControl {
        if {$val=="packet"} {
          set stream_control_stream 0
        } elseif {[string is integer $val]} {
          set stream_control_stream $val        
        } else {
          set gMessage "Config procedure: -streamControl  $val is should be an integer or \'packet\'"
          return [RLEH::Handle SAsyntax gMessage]
        }
        
      }
      -clkFreq {set clkFreq $val}
      -lineRate {
        switch -exact -- $tx_port_stream {
          30 - 31 - 28 - 29 {
            set rate [format %.4E [expr {[string trimright $val %]*10e+9/100.0}]]              
          } 
          1 - 2 - 3 - 4 {
            set rate [format %.4E [expr {[string trimright $val %]*1e+9/100.0}]]             
          }
        } 
         
        foreach cc {2047 1000 100 10 1} resol {4 3 2 1 0} step {1.0E+005 1.0E+006 1.0E+007 1.0E+008 1.0E+009} {
          set r2s [expr {$rate/$step}]
          if {$::RL10GbGen::g10GbGenBufferDebug} {
            puts "rate:$rate cc:$cc step:$step clkFreq:$clkFreq r2s:$r2s"  ; update
          }
          if {$r2s<2048} {            
            set bwExact [expr {($rate * $cc)/(8 * $clkFreq * 1000000)}]
            break
          }
        }
        # set bw [expr int($bwExact)]
        set bwRnd [expr round($bwExact)] ; # expr round(1.1) -> 1, round(1.9) -> 2 
        if {$bwRnd==0} {
          set bw 1
        } else {
          set bw $bwRnd
        }
        
        if {$::RL10GbGen::g10GbGenBufferDebug} {
          puts "rate:$rate resol:$resol step:$step bwExact:$bwExact bwRnd:$bwRnd bw:$bw"
        }      
      }
      -ipv4DA {
        if {[ValidIP $val] != 1} {
			    set gMessage "Config procedure: -ipv4DA $val is wrong."
          return [RLEH::Handle SAsyntax gMessage]
				}       
        set ::RL10GbGen::va10GbGenSet($activePort.EthIIEn) "EthII" 
        set ::RL10GbGen::va10GbGenSet($activePort.IPV4) "IPV4"
        set ::RL10GbGen::va10GbGenSet($activePort.ipv4DA) $val
      } 
      -ipv4SA {
        if {[ValidIP $val] != 1} {
			    set gMessage "Config procedure: -ipv4SA $val is wrong."
          return [RLEH::Handle SAsyntax gMessage]
				} 
        set ::RL10GbGen::va10GbGenSet($activePort.EthIIEn) "EthII" 
        set ::RL10GbGen::va10GbGenSet($activePort.IPV4) "IPV4"
        set ::RL10GbGen::va10GbGenSet($activePort.ipv4SA) $val
      } 
      -ipv4Ttl {
        if {![string is integer $val] || $val<0 || $val>255} {
			    set gMessage "Config procedure: -ipv4Ttl $val is wrong. Should be integer between 0 and 255"
          return [RLEH::Handle SAsyntax gMessage]
				} 
        set ::RL10GbGen::va10GbGenSet($activePort.EthIIEn) "EthII" 
        set ::RL10GbGen::va10GbGenSet($activePort.IPV4) "IPV4"
        set ::RL10GbGen::va10GbGenSet($activePort.ipv4Ttl) $val
      }
      -dataPatternType {
        switch -exact -- [string tolower $val] {
          incremental       {set dataPatternType incr}
          random            {set dataPatternType rand}
          allzeros          {set dataPatternType all0}
          repeat            {set dataPatternType repeat}
        }
      }
      -dataPatternData {
        set dataPatternData [string tolower $val]
      }
    }
    # puts "headersLen:$headersLen"
  }
    
#   set ::RL10GbGen::va10GbGenSet($activePort.EthIIEn) "None"
#   set ::RL10GbGen::va10GbGenSet($activePort.IPV4) "None"
  
  # puts "headersLen0:$headersLen"
  ## the RX/TX_seq_number_offset_stream should be between 16 to 255
  ## therfor in untagged packet (12 bytes of header) I add 4 bytes for "headers"
  if {$headersLen<16} {
    set headersLen 16
  }
  
  
  update
  
  set pkt [BuildPacket $activePort]
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "pkt <$pkt>"
  }
  set incrDataPatt 0
  ## since each line should contain 16 bytes, I complete the packet by 00
  ## meantime Shimon Caspi fills the payload by zeros also
  set div [expr {[llength $pkt] % 16}]
  set zerosL [list]
  if {$div!=0} {
    for {set i 1} {$i<=[expr {16 - $div}]} {incr i} {
      if {$dataPatternType=="all0"} {
        lappend dataPattL "00"
      } elseif {$dataPatternType=="rand"} {
        lappend dataPattL "[::RL10GbGen::RandomPatternByte]"
      } elseif {$dataPatternType=="incr"} {
        lappend dataPattL "[format %.2X $incrDataPatt]"
        incr incrDataPatt
      } elseif {$dataPatternType=="repeat"} {
        lappend dataPattL "$dataPatternData"
      }
    } 
  }
  set packet [concat $pkt $dataPattL ]
  set packLen [llength $packet]
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "1. <$packet> <$packLen>"
  }
  set RX_seq_number_offset_stream $packLen; # headersLen
  set TX_seq_number_offset_stream $packLen; # headersLen
  set RX_payload_offset_stream [expr {4+$RX_seq_number_offset_stream}]
  set TX_payload_offset_stream [expr {4+$TX_seq_number_offset_stream}]
  set ret 0
  
  set ::RL10GbGen::va10GbGenGui(status) "Stream's [expr {1+$stream_id}] configuration" ; update
  
	# set ret [SendTo10GbGen $ip_ID "\r\r" "FPGA" 6]
	SendTo10GbGen $ip_ID "top\r" "FPGA" 6

 SendTo10GbGen $ip_ID "mea oam 10G rx ena set $stream_id 0 \r" "FPGA"
 SendTo10GbGen $ip_ID "mea oam 10G tx active set $stream_id 0  \r" "FPGA"
#   set ret [SendTo10GbGen $ip_ID "mea oam 10G rmon clear $stream_id $received_port_stream\r" "FPGA"]
#   set ret [SendTo10GbGen $ip_ID "mea oam 10G rmon clear $stream_id $tx_port_stream\r" "FPGA"]
  
  
  ##set ret [SendTo10GbGen $ip_ID "mea oam 10 rx st $stream_id  \r" "FPGA>>"]
  SendTo10GbGen $ip_ID "mea ser sh ser \r" "FPGA"
  set portnum xxx
  foreach li [split $g10GbGenBuffer(id$ip_ID) \r\n] {
    if [regexp {(\d+)[\s\|]+(\d+)[\s\|]+(\d+)[\s\|]+0x} $li - serid portnum] {
      # puts "<$li> <$serid> <$portnum>"
      if {$portnum==$received_port_stream} {
        if {$::RL10GbGen::g10GbGenBufferDebug} {
          puts "<$serid> <$portnum>" ; update
        }  
        break
      } else {
        set portnum xxx
      }
    }
  }
  if {$portnum==30 || $portnum==31} {
    set ihp 2
  } else {
    set ihp 0
  }
  
  if {$portnum!="xxx"} {
    SendTo10GbGen $ip_ID "mea ser set del $serid $ihp \r" "FPGA"
  }   
  
  ## ------ Flows ------- 
  SendTo10GbGen $ip_ID "mea mod acl crea $oam_port 0 0 0x[set dMac5][set dMac6] 0x[set dMac3][set dMac4] 0x[set dMac1][set dMac2] 0 -out 1 $tx_port_stream \r" "FPGA"
  regexp {AclId[\s\=]+(\d+)} $g10GbGenBuffer(id$ip_ID) - ::RL10GbGen::va10GbGenSet($stream_id.AclId.1)
  set ::RL10GbGen::va10GbGenSet($stream_id.ihp.1) 2
  SendTo10GbGen $ip_ID "me ser set cre $received_port_stream 0x1fff 0x1ffe 0x1ffe 0x7f 0x7f 0 1 0 1000000000 0 64000 0 0 1 $drop_cluster -tm 0 -pm 0 -acl 0 00:00:00:00:00:00 -acl-out $drop_cluster -un 1 \r" "FPGA"
  regexp {ServiceId[\s\=]+(\d+)\s+Tm} $g10GbGenBuffer(id$ip_ID) - serid
  regexp {AclId[\s\=]+(\d+)} $g10GbGenBuffer(id$ip_ID) - ::RL10GbGen::va10GbGenSet($stream_id.AclId.2)
  set ::RL10GbGen::va10GbGenSet($stream_id.ihp.2) [ParsePortNum2Ihp $rx_port]
  SendTo10GbGen $ip_ID "mea mod acl crea $received_port_stream $serid 0 0x[set dMac5][set dMac6] 0x[set dMac3][set dMac4] 0x[set dMac1][set dMac2] 0 -out 1 $oam_cluster \r" "FPGA"
  regexp {AclId[\s\=]+(\d+)} $g10GbGenBuffer(id$ip_ID) - ::RL10GbGen::va10GbGenSet($stream_id.AclId.3)
  set ::RL10GbGen::va10GbGenSet($stream_id.ihp.3) [ParsePortNum2Ihp $rx_port]
  #set ret [SendTo10GbGen $ip_ID "mea mod acl show\r" "FPGA>>"]
  
  ## ------ RX param ------- 
  SendTo10GbGen $ip_ID "mea oam 10G rx param set -w $Seq_error_threshold_stream -txoffset $stream_id $TX_payload_offset_stream -rxoffset $stream_id $RX_payload_offset_stream -snoffset $stream_id $RX_seq_number_offset_stream \r" "FPGA"
  
#   set ret [SendTo10GbGen $ip_ID "me port ing set $received_port_stream -p 9 -s 0 -a 1 -v 224 \r" "FPGA>>"]
#   set ret [SendTo10GbGen $ip_ID "me port eg set $tx_port_stream -a 1 \r" "FPGA>>"]
#   set ret [SendTo10GbGen $ip_ID "me queue Cluster Create $tx_port_stream $tx_port_stream -m $max_psize \r" "FPGA>>"]

  ## ------ TX param ------- 
  SendTo10GbGen $ip_ID "mea ker oam wr 0xd  [format %#.3x [expr {$stream_id * 128}]] 0x00000000 0x00000000 0x00000000 0x00000000 \r" "FPGA"
  
  set k 0
  set packet [lreplace $packet 5 5 $dMac6]
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "StreamCofig packet:<[set packet]>"
  }  
  foreach {p0 p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11 p12 p13 p14 p15} $packet {
    incr k
    set word$k "0x[set p12][set p13][set p14][set p15] 0x[set p8][set p9][set p10][set p11] 0x[set p4][set p5][set p6][set p7] 0x[set p0][set p1][set p2][set p3] "
    if {$::RL10GbGen::g10GbGenBufferDebug} {
      puts "StreamCofig word$k:<[set word$k]>"
    }  
  }
  for {set i 1} {$i<=$k} {incr i} {
    SendTo10GbGen $ip_ID "mea ker oam wr 0xd [format %#.3x [expr {($stream_id * 128) + $i}]] [set word$i] \r" "FPGA"
  }
  
  if {$dataPatternType=="all0"} {
    ## do nothing  
  } elseif {$dataPatternType=="incr" || $dataPatternType=="rand" || $dataPatternType=="repeat"} {
    for {} {$i<=94} {incr i} {
      for {set p 0} {$p<=15} {incr p} {
        if {$dataPatternType=="incr"} {
          set p$p "[format %.2X $incrDataPatt]"
          incr incrDataPatt
          if {$incrDataPatt=="256"} {
            set incrDataPatt 0
          }
        } elseif {$dataPatternType=="rand"} {
          set p$p "[::RL10GbGen::RandomPatternByte]"
        } elseif {$dataPatternType=="repeat"} {
          set p$p "$dataPatternData"
        }
      }  
      set patt$i "0x[set p12][set p13][set p14][set p15] 0x[set p8][set p9][set p10][set p11] 0x[set p4][set p5][set p6][set p7] 0x[set p0][set p1][set p2][set p3] "
      if {$::RL10GbGen::g10GbGenBufferDebug} {
        puts "StreamCofig dTableSize:$dTableSize patt$i:<[set patt$i]>"
      }
      SendTo10GbGen $ip_ID "mea ker oam wr 0xd [format %#.3x [expr {($stream_id * 128) + $i}]] [set patt$i] \r" "FPGA"
      if {$i>$dTableSize} {
        break
      }
    }
  }  
  SendTo10GbGen $ip_ID "mea oam 10G tx param set $IPG $min_psize $max_psize \r" "FPGA"
  SendTo10GbGen $ip_ID "mea oam 10G tx desc set $stream_id -ia $ia -lbm 0 -limit $stream_control_stream\r" "FPGA"  ; # -limit $stream_control_stream
  SendTo10GbGen $ip_ID "mea oam 10G tx desc set $stream_id -bandwidth $bw -resolution $resol \r" "FPGA"
  SendTo10GbGen $ip_ID "mea oam 10G tx desc set $stream_id -packetsize $psize_stream -packettype $ptype_stream  \r" "FPGA"
  SendTo10GbGen $ip_ID "mea oam 10G tx desc set $stream_id -emix $emix_stream -emixnum $emixnum_stream\r" "FPGA"  ; # -emixnum $emixnum_stream
  set ret [SendTo10GbGen $ip_ID "mea oam 10G tx desc set $stream_id -snoff $TX_seq_number_offset_stream \r" "FPGA"]
  
  ## ------ bypass for SW issue --------
  # set ret [SendTo10GbGen $ip_ID "mea ker re wr 0x1074 0xaff \r" "FPGA>>"]
   
  # set ret [SendTo10GbGen $ip_ID "mea ser sh ser \r" "FPGA>>"]
  
  set ::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.TxPort) chassis:$chassis.Port:$tx_port
  set ::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.RxPort) chassis:$chassis.Port:$rx_port      
  if {$ret} {
		set va10GbGenStatuses($ip_ID,currScreen) "na"
	}
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "2. <$packet> <[llength $packet]>"
  }
  set ::RL10GbGen::va10GbGenGui(status) "" ; update
  return $ret
  # ::RL10GbGen::
}

# ***************************************************************************
# StreamStart
# ***************************************************************************
proc StreamStart {ip_ID stream_id args} {
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "StreamStart $ip_ID $stream_id"
  }
  global        gMessage
  set gMessage ""                   
  
  # set ret [SendTo10GbGen $ip_ID "\r\r" "FPGA" 6]
	# set ret [SendTo10GbGen $ip_ID "top\r" "FPGA" 6]
  set RxPort [::RL10GbGen::ParsePort $::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.RxPort)]
  set TxPort [::RL10GbGen::ParsePort $::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.TxPort)]
  set RxPortInt [ParsePortNum2IntNum  $RxPort]
  set TxPortInt [::RL10GbGen::ParsePortNum2IntNum  $TxPort]
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "StreamStart $ip_ID $stream_id __TXport:$TxPort $TxPortInt __RXport:$RxPort $RxPortInt"
  }
  set ::RL10GbGen::va10GbGenGui(status) "Stream's [expr {1+$stream_id}] start" ; update
  SendTo10GbGen $ip_ID "mea oam 10G rmon clear $stream_id\r" "FPGA"
  SendTo10GbGen $ip_ID "mea oam 10G rx ena set $stream_id 1 \r" "FPGA"
  set ret [SendTo10GbGen $ip_ID "mea oam 10G tx active set $stream_id 1 \r" "FPGA"]
  set ::RL10GbGen::va10GbGenGui(status) "" ; update
  set ::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.activity) run
  set ::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.startSec) [clock seconds]
  # parray ::RL10GbGen::va10GbGenSet *.packView
  return $ret
}  

# ***************************************************************************
# StreamStop
# ***************************************************************************
proc StreamStop {ip_ID stream_id} {
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] StreamStop" ; update 
  }
  global        g10GbGenBuffer
  global        gMessage
  variable      va10GbGenStatuses 
  variable      va10GbGenSet
  set gMessage ""                   
	set RxPort [::RL10GbGen::ParsePort $::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.RxPort)]
  set TxPort [::RL10GbGen::ParsePort $::RL10GbGen::va10GbGenSet($ip_ID.$stream_id.TxPort)]
  set RxPortInt [ParsePortNum2IntNum  $RxPort]
  set TxPortInt [::RL10GbGen::ParsePortNum2IntNum  $TxPort]
  
  set ::RL10GbGen::va10GbGenGui(status) "Stream's [expr {1+$stream_id}] stop" ; update
  SendTo10GbGen $ip_ID "mea oam 10G tx active set $stream_id 0 \r" "FPGA" 
  after 1200
  SendTo10GbGen $ip_ID "mea oam 10G rx ena set $stream_id 0 \r" "FPGA"
  
  SendTo10GbGen $ip_ID "mea ser sh ser \r" "FPGA"
  set portnum xxx
  foreach li [split $g10GbGenBuffer(id$ip_ID) \r\n] {
    # puts "<$li>" ; update
    if [regexp {(\d+)[\s\|]+(\d+)[\s\|]+(\d+)[\s\|]+0x} $li - serid portnum] {
      # puts "<$li> <$serid> <$portnum>"; update
      if {$portnum==$RxPortInt} {
        if {$::RL10GbGen::g10GbGenBufferDebug} {
          puts "<$serid> <$portnum>" ; update
        }
        break
      } else {
        set portnum xxx
      }
    }
  }
  if {$portnum==30 || $portnum==31} {
    set ihp 2
  } else {
    set ihp 0
  }
  if {$portnum!="xxx"} {
    SendTo10GbGen $ip_ID "mea ser set del $serid $ihp \r" "FPGA"
    
  }
  # SendTo10GbGen $ip_ID "mea mod acl show\r" "FPGA>>"  
##   15:44 13.02.2014
  for {set i 1} {$i<=3} {incr i} {
    set ihp $::RL10GbGen::va10GbGenSet($stream_id.ihp.$i)
    set aclId $::RL10GbGen::va10GbGenSet($stream_id.AclId.$i)
    SendTo10GbGen $ip_ID "mea mod acl del $ihp $aclId \r" "FPGA"
  }
  SendTo10GbGen $ip_ID "mea mod acl show\r" "FPGA"
#   17/02/2014 14:01:11
  set ret [SendTo10GbGen $ip_ID "mea oam 10G tx des del $stream_id\r" "FPGA"]
  set ::RL10GbGen::va10GbGenGui(status) "" ; update
  return $ret
  ## ::RL10GbGen::
}  

# ***************************************************************************
# **                        SendTo10GbGen
# ** 
# **  Abstract: The internal procedure send string to ETX204A by com or telnet
# **
# **   Inputs:
# **            ip_ID                :	        ID of ETX204A.
# **                              
# **  					 ip_sended            :	        sended string.
# **                              
# **  					 ip_expected          :	        expected string.
# **                              
# **  					 ip_timeout           :	        time out for waiting expected string.
# **                              
# **                              
# **   Outputs: 
# **            0                    :         If success. 
# **            Negativ error cod    :         Otherwise.     
# ***************************************************************************

proc SendTo10GbGen {ip_ID ip_sended {ip_expected stamstam} {ip_timeout 10}} {

  global        gMessage g10GbGenBuffer telnetBuffer$ip_ID
  variable      va10GbGenStatuses 
  variable      vOpened10GbGenHistoryCounter
  variable ScriptFile
	set fail          -1
	set ok             0
  
  # set g10GbGenBufferDebug 0

  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] Sent to 10GbGen ID $ip_ID : <$ip_sended>" 
  }
  update

  switch -exact -- $va10GbGenStatuses($ip_ID,connection)  {
	  com {
      switch -exact -- $va10GbGenStatuses($ip_ID,package) {
        RLCom {
          if {$ip_expected=="stamstam" } {
            RLCom::SendSlow $va10GbGenStatuses($ip_ID,10GbGenHandle) $ip_sended 30
            set ret 0
          } else {
            set ret [RLCom::SendSlow $va10GbGenStatuses($ip_ID,10GbGenHandle) $ip_sended 30 g10GbGenBuffer(id$ip_ID) $ip_expected $ip_timeout]
            if {$ret} {
              set gMessage "SendTo10GbGen procedure:   Return cod = $ret while (RLCom::SendSlow $va10GbGenStatuses($ip_ID,10GbGenHandle) $ip_sended 30 g10GbGenBuffer(id$ip_ID) $ip_expected $ip_timeout)"
            }
          }
        }
        RLSerial {
          if {$ip_expected=="stamstam" } {
            RLSerial::SendSlow $va10GbGenStatuses($ip_ID,10GbGenHandle) $ip_sended 30
            set ret 0
          } else {
            # set ret [RLSerial::SendSlow $va10GbGenStatuses($ip_ID,10GbGenHandle) $ip_sended 30 g10GbGenBuffer(id$ip_ID) $ip_expected $ip_timeout]
            if {$::RL10GbGen::g10GbGenBufferDebug && [string match {*mea oam 10G rmon gen*} $ip_sended]==0} {
              set id [open $ScriptFile a+]
              puts $id $ip_sended
              close $id
            }
            set tt [expr [lindex [time {set ret [RLSerial::Send $va10GbGenStatuses($ip_ID,10GbGenHandle) $ip_sended g10GbGenBuffer(id$ip_ID) $ip_expected $ip_timeout]}] 0]/1000000.0]
            if {$ret} {
              set gMessage "SendTo10GbGen procedure:   Return code = $ret while (RLSerial::SendSlow $va10GbGenStatuses($ip_ID,10GbGenHandle) $ip_sended 30 g10GbGenBuffer(id$ip_ID) $ip_expected $ip_timeout)"
            }
          }
        }
      }
    }
    telnet {
      switch -exact -- $va10GbGenStatuses($ip_ID,package) {
        RLTcp {
          set len [string length $ip_sended]
          for {set ind 0} {$ind < $len} {incr ind} {
            RLTcp::Send $va10GbGenStatuses($ip_ID,10GbGenHandle) [string index $ip_sended $ind]
            DelayMs 30
          }
          set ret 0
          if {$ip_expected != "stamstam" } {
            DelayMs 300
            set ret [RLTcp::Waitfor  $va10GbGenStatuses($ip_ID,10GbGenHandle)  $ip_expected  telnetBuffer$ip_ID  $ip_timeout]
            set g10GbGenBuffer(id$ip_ID) [set telnetBuffer$ip_ID]
            if {$ret} {
              set gMessage "SendTo10GbGen procedure:   Return cod = $ret while (RLTcp::Waitfor $va10GbGenStatuses($ip_ID,10GbGenHandle) $ip_expected  g10GbGenBuffer(id$ip_ID)  $ip_timeout)"
            }
          }
        }
        RLPlink {
          if {$ip_expected=="stamstam" } {
            RLPlink::SendSlow $va10GbGenStatuses($ip_ID,10GbGenHandle) $ip_sended 30
            set ret 0
          } else {
            set ret [RLPlink::SendSlow $va10GbGenStatuses($ip_ID,10GbGenHandle) $ip_sended 30 g10GbGenBuffer(id$ip_ID) $ip_expected $ip_timeout]
            if {$ret} {
              set gMessage "SendTo10GbGen procedure:   Return cod = $ret while (RLPlink::SendSlow $va10GbGenStatuses($ip_ID,10GbGenHandle) $ip_sended 30 g10GbGenBuffer(id$ip_ID) $ip_expected $ip_timeout)"
            }
          }
        }
      }
    }
  }
  FilterBuffer $ip_ID
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "ret$ret tt:${tt}sec. Expected : $ip_expected .  Received : <$g10GbGenBuffer(id$ip_ID)>\n" 
  }
  update
  return $ret
  ## ::RL10GbGen::
}

# ................................................................................
#  Abstract: Checks if plink process exists for opened ETX204A by  plink package
#
# **            ip_ID                :	        ID of ETX204A.
# **                              
# **   Outputs: 
# **            0                    :         If success. 
# **            Negativ error cod    :         Otherwise.     
# ................................................................................
proc CheckPlinkExist {ip_ID} {
  global        gMessage g10GbGenBuffer telnetBuffer$ip_ID
  variable      va10GbGenStatuses 
  variable      vOpened10GbGenHistoryCounter
	set fail          -1
	set ok             0

  if {![info exists va10GbGenStatuses($ip_ID,10GbGenID)]} {
  	set	gMessage "CheckPlinkExist procedure: The 10GbGen with ID=$ip_ID doesn't opened"
    return [RLEH::Handle SAsyntax gMessage]
  }

  set pids [pid $va10GbGenStatuses($ip_ID,10GbGenHandle)]
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
#  FilterBuffer : clean buffer from junk after read 10GbGen by com or telnet
# ..............................................................................
proc FilterBuffer {ip_ID} {
  global g10GbGenBuffer
  variable      va10GbGenStatuses 
  set re \[\x1B\x08\[\]
  regsub -all -- $re         $g10GbGenBuffer(id$ip_ID) " " 1
  # regsub -all -- .1C       $1      " " 2
  
  # set g10GbGenBuffer(id$ip_ID) $2
  set g10GbGenBuffer(id$ip_ID) $1
}


# ***************************************************************************
# 10GbGenshow_progdlg
# ***************************************************************************
proc 10GbGenshow_progdlg {txt} {
  if {![winfo exists .top10GbGenGui]} {return 0}
    variable progmsg
		variable progval
    set progmsg "Wait for $txt..."
    set progval 0
    if { [winfo exists .progress] } {
      destroy .progress
    }
    ProgressDlg .progress -parent .top10GbGenGui -title "Wait..." \
        -type         infinite \
        -width        35 \
        -textvariable ::RL10GbGen::progmsg \
        -variable     ::RL10GbGen::progval \
        -stop         "Stop" \
        -command      {destroy .progress}

				::RL10GbGen::10GbGenshow_update_progdlg
}

# ***************************************************************************
# 10GbGenshow_update_progdlg
# ***************************************************************************
proc 10GbGenshow_update_progdlg {} {
  variable progmsg
	variable progval

  if { [winfo exists .progress] } {
    set progval 2
    after 25	::RL10GbGen::10GbGenshow_update_progdlg
  }
}

# ***************************************************************************
# Del10GbGenResource
# ***************************************************************************
proc Del10GbGenResource {} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
	variable va10GbGenCfg

# 	if {![info exists va10GbGenSet(currentchass)] || $va10GbGenSet(currentchass) == "Resources"} {
# 	  return 1
# 	}

	set id [lindex [split [lindex [split [::RL10GbGen::GetActivePort] .] 0] :] 1]
  set activePort [::RL10GbGen::GetActivePort]
  if {$activePort=="home"} {
    set chassisL [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) home]
  } else {
    set chassisL [lindex [split [::RL10GbGen::GetActivePort] .] 0]
  } 
  foreach chassis $chassisL {
    set id [lindex  [split $chassis  :] 1]
    if {$id==""} {
      tk_messageBox -title "Disconnect chassis" -message "Point on a Port of the disconecting Chassis"
      return -1
    }
    if {$::RL10GbGen::g10GbGenBufferDebug} {
      puts "Del10GbGenResource id:$id" ; update
    }  
    set va10GbGenSet(currentchass) "chassis:$id"
  	if {[::RL10GbGen::Close $id]} {
  		tk_messageBox -icon error -type ok -message "Error while (::RL10GbGen::Close $id) procedure \n$gMessage" -title "Etx204A PRBS"
      return    
  	}
   	$va10GbGenGui(resources,list) delete $va10GbGenSet(currentchass)
    
    }
	set va10GbGenSet(currentchass) Resources
	set va10GbGenSet(currentid)	Resources
  
  ## for jumping to the "Resources" without open New Connection Dialog I call
  ## to ToggleFrame with fake node
  ::RL10GbGen::ToggleFra del:del
  update
  $::RL10GbGen::va10GbGenGui(resources,list) selection set home
  # ::RL10GbGen::
}

# ***************************************************************************
# SaveComTelnetToFile
# ***************************************************************************
proc SaveComTelnetToFile {} {
  variable va10GbGenSet
  if ![file exists [pwd]/inits] {
    file mkdir  [pwd]/inits
  }
  set idFile [ open [pwd]/inits/init.tcl w+ ]
  if ![info exists ::RL10GbGen::va10GbGenSet(connect,com)] {
    set ::RL10GbGen::va10GbGenSet(connect,com) 1
  }
  if ![info exists ::RL10GbGen::va10GbGenSet(connect,telnet)] {
    set ::RL10GbGen::va10GbGenSet(connect,telnet) "172.18.92.1"
  }
  if ![info exists ::RL10GbGen::va10GbGenSet(connectBy)] {
    set ::RL10GbGen::va10GbGenSet(connectBy) "1"
  }
  if ![info exists ::RL10GbGen::va10GbGenSet(listIP)] {
    set ::RL10GbGen::va10GbGenSet(listIP) "{} 172.18.92.1"
  }
  if ![info exists ::RL10GbGen::va10GbGenSet(clockFreq)] {
    set ::RL10GbGen::va10GbGenSet(clockFreq) "150"
  }
  if ![info exists ::RL10GbGen::va10GbGenSet(readStreamEach)] {
    set ::RL10GbGen::va10GbGenSet(readStreamEach) "3"
  }
  if ![info exists ::RL10GbGen::va10GbGenSet(lastEthType)] {
    set ::RL10GbGen::va10GbGenSet(lastEthType) "00ff"
  }
  puts $idFile "set ::RL10GbGen::va10GbGenSet(connect,com) \"$::RL10GbGen::va10GbGenSet(connect,com)\""
  puts $idFile "set ::RL10GbGen::va10GbGenSet(connect,telnet) \"$::RL10GbGen::va10GbGenSet(connect,telnet)\""
  puts $idFile "set ::RL10GbGen::va10GbGenSet(connectBy) \"$::RL10GbGen::va10GbGenSet(connectBy)\""
  puts $idFile "set ::RL10GbGen::va10GbGenSet(listIP) \"$::RL10GbGen::va10GbGenSet(listIP)\""
  puts $idFile "set ::RL10GbGen::va10GbGenSet(clockFreq)  \"$::RL10GbGen::va10GbGenSet(clockFreq)\""
  puts $idFile "set ::RL10GbGen::va10GbGenSet(readStreamEach)  \"$::RL10GbGen::va10GbGenSet(readStreamEach)\""
  puts $idFile "set ::RL10GbGen::va10GbGenSet(lastEthType)  \"$::RL10GbGen::va10GbGenSet(lastEthType)\""
  close $idFile
  return {}
  # ::RL10GbGen::
}
# ............................................................................................
#  Abstract: SaveConfigToFile
#  Inputs: 
#
#  Outputs: 
# ...........................................................................................
proc SaveConfigToFile {fileType} {

  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses


	if {$fileType == "cfg"} {
    set va10GbGenSet(resources,list) ""
	  set reslist  [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) home]
		if {$reslist != ""} {
			foreach chassis $reslist {
		  	set id [lindex [split $chassis :] 1]
	    	lappend va10GbGenSet(resources,list) $va10GbGenStatuses($id,address) $va10GbGenStatuses($id,package)
			}
		} else {
		  tk_messageBox -icon error -type ok -message "There is no chassis in resources pane" -title "Save Configuration"
			return -1
		}
	  set cfgFile [tk_getSaveFile \
	        -initialdir [pwd]/inits/ \
	        -filetypes {{ "CFG Files"   {.cfg }}} \
	        -title "Save Configuration As.." \
	        -parent . \
	        -defaultextension $fileType \
				  -initialfile 10GbGenGui]

		
	} else {
		  set cfgFile [tk_getSaveFile \
		        -initialdir [pwd]/inits/ \
		        -filetypes {{ "CFG Files"   {.ini }}} \
		        -title "Save Configuration As.." \
		        -parent . \
		        -defaultextension $fileType \
					  -initialfile 10GbGenGui]
	}

  # If the user selected "Cancel"
  if {$cfgFile == ""} {
    return -1
  }
  set idFile [ open $cfgFile w+ ]
  
#   foreach chassis $reslist {
#     foreach port [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) $chassis] {
#      puts "ch:$chassis po:$port"
#     }
#   }
#   
  foreach chassis $reslist {
    set id [lindex [split $chassis :] 1]
    for {set strId 0} {$strId<=7} {incr strId} {      
      # puts $idFile "set va10GbGenSet($id.$strId.activity) \"$va10GbGenSet($id.$strId.activity)\""
      puts $idFile "set va10GbGenSet($id.$strId.activity) \"stop\"" 
      if ![info exists va10GbGenSet($id.$strId.startSec)] {
        set va10GbGenSet($id.$strId.startSec) [clock seconds]
      }
      puts $idFile "set va10GbGenSet($id.$strId.startSec) \"$va10GbGenSet($id.$strId.startSec)\""     
    }
    foreach port [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) $chassis] {
      ## port==chassis:1.Port:1
      puts $idFile "set va10GbGenSet($port.DA)              \"$va10GbGenSet($port.DA)\""
      puts $idFile "set va10GbGenSet($port.EthIIEn)         \"$va10GbGenSet($port.EthIIEn)\""
      puts $idFile "set va10GbGenSet($port.EthIIType)       \"$va10GbGenSet($port.EthIIType)\""
      puts $idFile "set va10GbGenSet($port.FrameSizeType)   \"$va10GbGenSet($port.FrameSizeType)\""
      puts $idFile "set va10GbGenSet($port.IP)              \"$va10GbGenSet($port.IP)\""
      puts $idFile "set va10GbGenSet($port.IPV4)            \"$va10GbGenSet($port.IPV4)\""
      puts $idFile "set va10GbGenSet($port.LineRate)        \"$va10GbGenSet($port.LineRate)\""
      puts $idFile "set va10GbGenSet($port.PacketBurst)     \"$va10GbGenSet($port.PacketBurst)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixEn1)   \"$va10GbGenSet($port.PacketEmixEn1)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixEn2)   \"$va10GbGenSet($port.PacketEmixEn2)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixEn3)   \"$va10GbGenSet($port.PacketEmixEn3)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixEn4)   \"$va10GbGenSet($port.PacketEmixEn4)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixEn5)   \"$va10GbGenSet($port.PacketEmixEn5)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixEn6)   \"$va10GbGenSet($port.PacketEmixEn6)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixEn7)   \"$va10GbGenSet($port.PacketEmixEn7)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixEn8)   \"$va10GbGenSet($port.PacketEmixEn7)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixLen1)  \"$va10GbGenSet($port.PacketEmixLen1)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixLen2)  \"$va10GbGenSet($port.PacketEmixLen2)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixLen3)  \"$va10GbGenSet($port.PacketEmixLen3)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixLen4)  \"$va10GbGenSet($port.PacketEmixLen4)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixLen5)  \"$va10GbGenSet($port.PacketEmixLen5)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixLen6)  \"$va10GbGenSet($port.PacketEmixLen6)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixLen7)  \"$va10GbGenSet($port.PacketEmixLen7)\""
      puts $idFile "set va10GbGenSet($port.PacketEmixLen8)  \"$va10GbGenSet($port.PacketEmixLen8)\""
      puts $idFile "set va10GbGenSet($port.PacketFixLen)    \"$va10GbGenSet($port.PacketFixLen)\""
      puts $idFile "set va10GbGenSet($port.PacketMaxLen)    \"$va10GbGenSet($port.PacketMaxLen)\""
      puts $idFile "set va10GbGenSet($port.PacketMinLen)    \"$va10GbGenSet($port.PacketMinLen)\""
      puts $idFile "set va10GbGenSet($port.PacketPerBurst)  \"$va10GbGenSet($port.PacketPerBurst)\""
      puts $idFile "set va10GbGenSet($port.PatternData)     \"$va10GbGenSet($port.PatternData)\""
      puts $idFile "set va10GbGenSet($port.PatternType)     \"$va10GbGenSet($port.PatternType)\""
      puts $idFile "set va10GbGenSet($port.RcvPort)         \"$va10GbGenSet($port.RcvPort)\""
      puts $idFile "set va10GbGenSet($port.SA)              \"$va10GbGenSet($port.SA)\""
      puts $idFile "set va10GbGenSet($port.SeqErThr)        \"$va10GbGenSet($port.SeqErThr)\""
      puts $idFile "set va10GbGenSet($port.StreamEnable)    \"$va10GbGenSet($port.StreamEnable)\""
      puts $idFile "set va10GbGenSet($port.chassis.portNum) \"$va10GbGenSet($port.chassis.portNum)\""
      puts $idFile "set va10GbGenSet($port.intNum)          \"$va10GbGenSet($port.intNum)\""
      puts $idFile "set va10GbGenSet($port.MplsEn)          \"$va10GbGenSet($port.MplsEn)\""
      # puts $idFile "set va10GbGenSet($port.packView)        \"$va10GbGenSet($port.packView)\""
      puts $idFile "set va10GbGenSet($port.vlans,en)        \"$va10GbGenSet($port.vlans,en)\""
      foreach v {1 2 3 4} {
        puts $idFile "set va10GbGenSet($port.vlan.Id.$v)    \"$va10GbGenSet($port.vlan.Id.$v)\""
        puts $idFile "set va10GbGenSet($port.vlan.En.$v)    \"$va10GbGenSet($port.vlan.En.$v)\""
        puts $idFile "set va10GbGenSet($port.vlan.uPri.$v)  \"$va10GbGenSet($port.vlan.uPri.$v)\""
        puts $idFile "set va10GbGenSet($port.vlan.cfi.$v)   \"$va10GbGenSet($port.vlan.cfi.$v)\""
        puts $idFile "set va10GbGenSet($port.vlan.pid.$v)   \"$va10GbGenSet($port.vlan.pid.$v)\""
      }     
      puts $idFile "set va10GbGenSet($port.ipv4DA)            \"$va10GbGenSet($port.ipv4DA)\""
      puts $idFile "set va10GbGenSet($port.ipv4SA)            \"$va10GbGenSet($port.ipv4SA)\""
      puts $idFile "set va10GbGenSet($port.ipv4UdpDP)         \"$va10GbGenSet($port.ipv4UdpDP)\""
      puts $idFile "set va10GbGenSet($port.ipv4UdpSP)         \"$va10GbGenSet($port.ipv4UdpSP)\""
      puts $idFile "set va10GbGenSet($port.tcpAckNum)         \"$va10GbGenSet($port.tcpAckNum)\""
      puts $idFile "set va10GbGenSet($port.tcpSeqNum)         \"$va10GbGenSet($port.tcpSeqNum)\""
      puts $idFile "set va10GbGenSet($port.ipv4Ttl)           \"$va10GbGenSet($port.ipv4Ttl)\""
      if ![info exists va10GbGenSet($port.process)] {
        set va10GbGenSet($port.process) "notConfigured"
      }
      puts $idFile "set va10GbGenSet($port.process)           \"$va10GbGenSet($port.process)\""
    }
  }
	if {$fileType == "cfg"} {
		puts $idFile "set va10GbGenSet(listIP) [list $va10GbGenSet(listIP)]"
	  puts $idFile "set va10GbGenSet(resources,list) \"$va10GbGenSet(resources,list)\""
    puts $idFile "set va10GbGenSet(connect,com) \"$va10GbGenSet(connect,com)\""
    puts $idFile "set va10GbGenSet(connect,telnet) \"$va10GbGenSet(connect,telnet)\""
    puts $idFile "set va10GbGenSet(connectBy) \"$va10GbGenSet(connectBy)\""
    
	}
  close $idFile
  return 0
  # ::RL10GbGen::
}
# ................................................................................
#  Abstract: GetConfigFromFile
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc GetConfigFromFile {fileType} {

  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  variable va10GbGenSetTmp
  variable va10GbGenSet

	if {$fileType == "cfg"} {
	  set cfgFile [tk_getOpenFile \
	        -initialdir [pwd]/inits/ \
	        -filetypes {{ "CFG Files"   {.cfg }}} \
	        -title "Open Configuration " \
	        -parent . \
	        -defaultextension cfg ]
	} else {
		  set cfgFile [tk_getOpenFile \
		        -initialdir [pwd]/inits/ \
		        -filetypes {{ "CFG Files"   {.ini }}} \
		        -title "Save Configuration As.." \
		        -parent . \
		        -defaultextension $fileType \
					  -initialfile 10GbGenGui]
  }      
  # If the user selected "Cancel"
  if {$cfgFile == ""} {
    return 0
  }

	if {[::RL10GbGen::ChkCfgFile $cfgFile]} {
    set gMessage "\n The file $cfgFile doesn't valid for 10GbGen configuration"
		tk_messageBox -icon error -type ok -message "Error while (::RL10GbGen::ChkCfgFile $cfgFile) procedure \n$gMessage" -title "Error 10GbGen"
		return
	} else {
		source $cfgFile
	}
  
  ## "clear" ports' text
  set tree $::RL10GbGen::va10GbGenGui(resources,list)
  foreach chs [$tree nodes home] {
    foreach activePort [$tree nodes $chs] {
      $tree itemconfigure $activePort -text "[string trim [lindex [split [$tree itemcget $activePort -text] < ] 0]]"
    }
  }
  
	$va10GbGenGui(tb,save) configure -state normal

	if {$fileType == "ini"} {
		set id [open $cfgFile r]
		set va10GbGenSet(inibuffer) [read $id]
		close	 $id
	
		
	}
	if {$fileType == "cfg"} {
		set resources ""
	  set reslist  [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) home]
		if {$reslist != ""} {
			foreach chassis $reslist {
		  	set id [lindex [split $chassis :] 1]
	    	lappend resources $va10GbGenStatuses($id,address) $va10GbGenStatuses($id,package)
			}
		}
		if {$va10GbGenSet(resources,list) != ""} {
			foreach {address package} $va10GbGenSet(resources,list) {
			  if {[lsearch $resources $address] == -1} {
				  OkConnChassis $address $package 0 getCfg
				}
			}
      source $cfgFile
		}
    after 1000
    set reslist  [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) home]
    
    if {$reslist != ""} {
			foreach chassis $reslist {
	    	foreach activePort [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) $chassis] {
          array unset va10GbGenSetTmp $activePort.*
          array set va10GbGenSetTmp [array get va10GbGenSet $activePort.*]          
        }
			}
		}
    
    ::RL10GbGen::ToggleStreamEnable
    $::RL10GbGen::va10GbGenGui(resources,list) selection set chassis:1
    update
	}
  focus -force .top10GbGenGui
  # ::RL10GbGen::
}

# ................................................................................
#  Abstract:  ChkCfgFile
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc ChkCfgFile {ip_file} {
    set numbLine 0
    set fileId [open $ip_file r ]

    while	{[eof $fileId] != 1} {
	    set line [gets $fileId]
						# puts $line
  	  if {[string match "*set va10GbGenSet*" $line ] == 0 && $line != "" } {
        if {$::RL10GbGen::g10GbGenBufferDebug} {
          puts "line:$numbLine <$line>" ; update
        }  
        close $fileId
		   	return -1
			} else {
  		  	incr numbLine
					# puts $numbLine
		 	}
		}
    close $fileId
	  return 0
    # ::RL10GbGen::
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
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses

	if {[regexp -nocase {RL10GbGen.exe} $va10GbGenSet(rundir) match]} {
  	set path	10GbGenHelp.chm
	} else {
    	set path	$va10GbGenSet(rundir)/10GbGenHelp.chm
	}

  set comspec [set env(COMSPEC)]
 
  # exec $comspec /c start $path
}


# ................................................................................
#  Abstract: DisableEnableEntries
#  Inputs: 
#
#  Outputs: 
#
#  ::RL10GbGen::DisableEnableEntries
# ................................................................................
proc DisableEnableEntries {param} {
  global gMessage
	foreach entry $::RL10GbGen::va10GbGenSet(lDisabledEntries) {
		 # puts $entry
		 $entry configure -state $param
	}
	.top10GbGenGui.mainframe setmenustate getcfgfile $param
	.top10GbGenGui.mainframe setmenustate savecfgfile $param
	.top10GbGenGui.mainframe setmenustate getguicfgfile $param
	.top10GbGenGui.mainframe setmenustate saveguicfgfile $param
	.top10GbGenGui.mainframe setmenustate savecfgchass $param
	.top10GbGenGui.mainframe setmenustate exit $param
	.top10GbGenGui.mainframe setmenustate run $param
	.top10GbGenGui.mainframe setmenustate connect $param
	.top10GbGenGui.mainframe setmenustate disconnect $param
	.top10GbGenGui.mainframe setmenustate portsFactory $param
	.top10GbGenGui.mainframe setmenustate portsSave $param
	.top10GbGenGui.mainframe setmenustate reset $param
	.top10GbGenGui.mainframe setmenustate email $param

}

# ................................................................................
#  Abstract: Factory10GbGen
# ................................................................................
proc FactoryEtx {} {
  global gMessage
   
  set res [tk_messageBox -title "Global Init" -type yesno \
      -message "Global init will erase all streams at the chassis/es. Are you sure?"]
  if {$res=="no"} {return {}}    
  
  set idL [::RL10GbGen::GetActiveChassisId]
  foreach id $idL { 
    set ::RL10GbGen::va10GbGenSet(currentid) $id 
	  $::RL10GbGen::va10GbGenGui(resources,list) configure -state disabled
    ::RL10GbGen::10GbGenshow_progdlg "Global Init of Chassis $id"
	  ::RL10GbGen::GenConfig $id reinit
    destroy .progress
    update
    after 1000
  }
  
	$::RL10GbGen::va10GbGenGui(resources,list) configure -state normal
  return {}
}


# ................................................................................
#  Quit application.
# ................................................................................
proc Quit {} {
  SaveComTelnetToFile
	set ret [tk_messageBox -title "Confirm exit" -icon question \
      -type "yesnocancel" -message "Would you like to save the configuration to a file?"]
  if {$ret=="cancel"} {
    ## do nothing
  } elseif {$ret=="yes"} {
    set ret [::RL10GbGen::SaveConfigToFile cfg]
  }
  focus -force .top10GbGenGui
  if {$ret=="no" || $ret==0} {
    # catch {exec taskkill.exe /im plink.exe  /f  /t}
    destroy .top10GbGenGui
    exit
  }
}

# ................................................................................
#  Abstract: Create introduction GUI while building main ETX204A generator GUI.
#  Inputs: 
#
#  Outputs: 
# ................................................................................
proc _create_intro { } {
  return 0
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet

  set top [toplevel .intro -relief raised -borderwidth 2]

  wm withdraw $top
  wm overrideredirect $top 1

  set ximg  [label $top.x -bitmap @$va10GbGenSet(rundir)/Images/x1.xbm \
    -foreground grey90 -background white]
  set bwimg [label $ximg.bw -bitmap @$va10GbGenSet(rundir)/Images/bwidget.xbm \
    -foreground grey90 -background white]
  set frame [frame $ximg.f -background white]
  set lab1  [label $frame.lab1 -text "Loading ETX220 generator's GUI" \
    -background white -font {times 8}]
  set lab2  [label $frame.lab2 -textvariable va10GbGenSet(prgtext) \
    -background white -font {times 8} -width 35]
  set prg   [ProgressBar $frame.prg -width 50 -height 10 -background white \
    -variable va10GbGenSet(prgindic) -maximum 10]
  pack $lab1 $lab2 $prg
  place $frame -x 0 -y 0 -anchor nw
  place $bwimg -relx 1 -rely 1 -anchor se
  pack $ximg
  BWidget::place $top 0 0 center
  wm deiconify $top
}


proc neClose10GbGenGui {} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  SaveComTelnetToFile
	if {!$va10GbGenSet(closeByDestroy)} {
    destroy .top10GbGenGui
 	  return
	}

  set reslist  [lrange [Tree::nodes $va10GbGenGui(resources,list) root] 1 end]
	if {$reslist == ""} {
    destroy .top10GbGenGui 
		exit
	} else {
	  destroy .top10GbGenGui 
  	::RL10GbGen::CloseAll
		exit
	}

}

# ***************************************************************************
# 10GbGenEmailSet
# ***************************************************************************
proc 10GbGenEmailSet {base} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
	variable va10GbGenStatuses
  
  if {[winfo exists $base]} {
    wm deiconify $base
    return
  }
  
  toplevel $base
  focus -force $base
  wm protocol $base WM_DELETE_WINDOW "wm attribute $base -topmost 0 ; destroy $base ; ::RL10GbGen::InitFileEmail"
  wm focusmodel $base passive
  wm overrideredirect $base 0
  wm resizable $base 0 0
  wm deiconify $base
  wm title $base "Send Results to..."
  wm attribute $base -topmost 1
    
  if {[file exists [pwd]/inits/InitEmail.tcl]} {
    source [pwd]/inits/InitEmail.tcl
  }  
    
  set va10GbGenGui(labMail) [Label $base.labMail -text "Emails" -font {{} 10 {bold underline}}]
  pack $va10GbGenGui(labMail) -side top -pady 2 -padx 4 -anchor w
  for {set i 1} {$i<=$va10GbGenSet(EmailSum)} {incr i} {
    set va10GbGenGui(fraMail.$i) [frame $base.fraMail$i]
      set va10GbGenGui(entMail.$i) [Entry $va10GbGenGui(fraMail.$i).entMail$i \
      -width 18 -textvariable ::RL10GbGen::va10GbGenSet(Email.$i)]
      set va10GbGenGui(cbMail.$i) [checkbutton $va10GbGenGui(fraMail.$i).cbMail$i \
      -text ".$i" -variable ::RL10GbGen::va10GbGenSet(chbutEmail.$i) -command "::RL10GbGen::ActivateMail"]      
      pack $va10GbGenGui(cbMail.$i) $va10GbGenGui(entMail.$i) -side right -padx 4 -pady 2
    pack $va10GbGenGui(fraMail.$i) -side top -pady 2 -padx 4 -anchor w
  }  
  ::RL10GbGen::ActivateMail   
}

# ***************************************************************************
# ActivateMail
# ***************************************************************************
proc ActivateMail {} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
	variable va10GbGenStatuses
  for {set i 1} {$i<=$va10GbGenSet(EmailSum)} {incr i} {
    if {[set va10GbGenSet(chbutEmail.$i)]==0} {
      [set va10GbGenGui(entMail.$i)] configure -state disabled
    } else {
      [set va10GbGenGui(entMail.$i)] configure -state normal
    }
  }
}

# ***************************************************************************
##** InitFileEmail +
# #***************************************************************************
proc InitFileEmail {} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  set fileId [open [pwd]/inits/InitEmail.tcl w]
  seek $fileId 0 start
  for {set i 1} {$i<=$va10GbGenSet(EmailSum)} {incr i} {
    puts $fileId "set va10GbGenSet(Email.$i) \"$va10GbGenSet(Email.$i)\""
    puts $fileId "set va10GbGenSet(chbutEmail.$i) \"$va10GbGenSet(chbutEmail.$i)\""
  }  
  close $fileId
}


# ***************************************************************************
# SendEmail
# ***************************************************************************
proc SendEmail {msg} {
  global gMessage env
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  package require ezsmtp
  ezsmtp::config -mailhost radmail.rad.co.il -from "ETX-220 GENERATOR"
  
  if {[file exists [pwd]/inits/InitEmail.tcl]} {
    source [pwd]/inits/InitEmail.tcl
  } 
  for {set i 1} {$i<=$va10GbGenSet(EmailSum)} {incr i} {   
    if {[info exists va10GbGenSet(chbutEmail.$i)] && $va10GbGenSet(chbutEmail.$i)==1} {
      if { [catch {ezsmtp::send -to "$va10GbGenSet(Email.$i)" \
      -subject "ETX-220 GENERATOR : Update message from the Tester" \
      -body "$msg" \
      -from "$env(USERNAME)@rad.com"} res]} {
        return "Abort"
      }    
    }
  }
  return "Ok"
}


# ***************************************************************
# ** TimeDate
# **
# ** Abstract: Reading time and Date from CPU clock.
# **
# ** Inputs: 
# **
# ** Outputs: Return the current Time/Date in the format: 08:38:15 <06/01/1999>
# ** 
# ** Usage: RLTime::TimeDate
# **
# ***************************************************************
proc TimeDate {} {  
 
   set clkTime [clock format [clock seconds] -format %H:%M:%S]
   set clkDate [clock format [clock seconds] -format %d/%m/%Y]
   set timeDate "$clkTime  <$clkDate>"

   return $timeDate
}

# ***************************************************************************
# ToggleFrameSize
# ***************************************************************************
proc ToggleFrameSize {activePort} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  variable va10GbGenSetTmp
  
  # puts "va10GbGenSet(FrameSizeType):$va10GbGenSetTmp($activePort.FrameSizeType)"
  switch -exact -- $va10GbGenSetTmp($activePort.FrameSizeType) {
    Fixed {
      foreach len {min max emix1 emix2 emix3 emix4  emix5 emix6 emix7 emix8} {
        set fr [winfo parent [winfo parent $va10GbGenGui(general_setup,generator,[set len]len)]]
        # puts "fr:$fr"
        pack forget $fr
      }  
      foreach len {fix} {
        set fr [winfo parent [winfo parent $va10GbGenGui(general_setup,generator,[set len]len)]]
        pack $fr -side left -padx 2
      }
    }
    Incr - Random {
      foreach len {fix emix1 emix2 emix3 emix4  emix5 emix6 emix7 emix8} {
        set fr [winfo parent [winfo parent $va10GbGenGui(general_setup,generator,[set len]len)]]
        pack forget $fr
      }  
      foreach len {min max} {
#         set fr [winfo parent [winfo parent $va10GbGenGui(general_setup,generator,[set len]len)]]
#         pack $fr -side left -padx 2
      }
    }
    EMIX {
      foreach len {min max fix emix1 emix2 emix3 emix4  emix5 emix6 emix7 emix8} {
        set fr [winfo parent [winfo parent $va10GbGenGui(general_setup,generator,[set len]len)]]
        pack forget $fr
      }  
      foreach len { emix1 emix2 emix3 emix4  emix5 emix6 emix7 emix8} {
        set fr [winfo parent [winfo parent $va10GbGenGui(general_setup,generator,[set len]len)]]
        pack $fr -side left -padx 2
      }
    }  
  }
  
}

# ***************************************************************************
# TogglePatternData
# ***************************************************************************
proc TogglePatternData {activePort} {
  # puts TogglePatternData
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  variable va10GbGenSetTmp
  
  switch -exact -- $va10GbGenSetTmp($activePort.PatternType) {
    Incremental {
      $va10GbGenGui(general_setup,generator,PatternData) configure -state disabled ; # -text "00 01 02 03"
      $va10GbGenGui(general_setup,generator,PatternNew) configure -state disabled
      $va10GbGenGui(general_setup,generator,PatternEdit) configure -state disabled
    }
    Random {
      $va10GbGenGui(general_setup,generator,PatternData) configure -state disabled 
      $va10GbGenGui(general_setup,generator,PatternNew) configure -state disabled
      $va10GbGenGui(general_setup,generator,PatternEdit) configure -state disabled
    }
    Repeat {
      $va10GbGenGui(general_setup,generator,PatternData) configure -state normal -text $::RL10GbGen::va10GbGenSet($activePort.PatternData)
      $va10GbGenGui(general_setup,generator,PatternNew) configure -state disabled
      $va10GbGenGui(general_setup,generator,PatternEdit) configure -state disabled
    }
    AllZeros - Fixed {
      $va10GbGenGui(general_setup,generator,PatternData) configure -state disabled ; # -text "00"
      $va10GbGenGui(general_setup,generator,PatternNew) configure -state disabled
      $va10GbGenGui(general_setup,generator,PatternEdit) configure -state disabled
    }
    default {puts $va10GbGenSet(PatternType)}
  }   
}

# ***************************************************************************
# PatternEdit
# ***************************************************************************
proc PatternEdit {} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  
   
}

# ***************************************************************************
# PatternNew
# ***************************************************************************
proc PatternNew {} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  
   
}
# ***************************************************************************
# TreeSelect
# ***************************************************************************
proc TreeSelect {where num tree  x y node} {
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "TreeSelect where:$where num:$num node:$node x:$x y:$y"
  }
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses

  if { $num == 1 } {
    # ::RL10GbGen::TreeSelect_node $tree $node
    ToggleFra $node
  }
  if { $num == 2 } {
    ::RL10GbGen::GuiStream FrameData
  }
  if { $num == 3 } {
    if {$where == "tree"} {
      ::RL10GbGen::PopUp1 $x $y $node
    }
    # ::RL10GbGen::TreeSelect_node $tree $node
  }
}

# ***************************************************************************
# ReBuildTree
# ::RL10GbGen::ReBuildTree
# ***************************************************************************
proc ReBuildTree {} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  set tree $::RL10GbGen::va10GbGenGui(resources,list)
  set id 1
  $tree delete [$tree nodes home]
  $tree insert end home chassis:$id -text  "Chassis $id" -image [Bitmap::get folder] -drawcross allways -data  $id -open 1
  ::RL10GbGen::TestTreeInit $id $tree
  # $tree opentree home
}

# ***************************************************************************
# TestTreeInit
# ***************************************************************************
proc TestTreeInit {chassis tree  args } {
  global   tcl_platform gaEthSet
  variable count
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  set count 0
  set rootdir "Tests"
  set id $::RL10GbGen::va10GbGenStatuses($chassis,10GbGenID)
  foreach po {1 2 3 4 5 6 7 8} ps {10G 10G 10G 10G 1G 1G 1G 1G} {
    AddChassis $tree chassis:$chassis chassis:$chassis.Port:$po "Port $po - $ps" port1.ico never 0
    SetStream2Default $id $chassis $po $ps
  } 
  
  $tree configure -redraw 1   
  return {} 
  # set reslist [$::RL10GbGen::va10GbGenGui(resources,list) nodes home]        
}

# ***************************************************************************
# AddTest
# ***************************************************************************
proc AddChassis {tree parent node txt img cross data } {
  variable va10GbGenSet
  $tree insert end $parent $node -text $txt -drawcross $cross -data $data \
      -padx 20 -image [image create photo -file $va10GbGenSet(rundir)/images/$img] ; # -helptext $node    
}

# ***************************************************************************
# SetStream2Default
# ***************************************************************************
proc SetStream2Default {id chassis po ps} {
  set ::RL10GbGen::va10GbGenSet(chassis:$chassis.Port:$po.chassis.portNum) $chassis:$po
  set ::RL10GbGen::va10GbGenSet(chassis:$chassis.Port:$po.intNum) [ParsePortNum2IntNum  $po]
  set ::RL10GbGen::va10GbGenSet(chassis:$chassis.Port:$po.ps) $ps
  set strId [expr {$po - 1}]
  set ::RL10GbGen::va10GbGenSet(chassis:$chassis.Port:$po.strId) $strId
  
  set activePort "chassis:$chassis.Port:$po"
  set ::RL10GbGen::va10GbGenSet($activePort.SeqErThr) 1
  set ::RL10GbGen::va10GbGenSet($activePort.DA) $::RL10GbGen::vaDefaults(DA)
  set ::RL10GbGen::va10GbGenSet($activePort.SA) $::RL10GbGen::vaDefaults(SA)
  set ::RL10GbGen::va10GbGenSet($activePort.FrameSizeType) $::RL10GbGen::vaDefaults(FrameSizeType)
  set ::RL10GbGen::va10GbGenSet($activePort.PacketFixLen) $::RL10GbGen::vaDefaults(PacketFixLen)
  set ::RL10GbGen::va10GbGenSet($activePort.PacketBurst) $::RL10GbGen::vaDefaults(PacketBurst)
  set ::RL10GbGen::va10GbGenSet($activePort.LineRate) $::RL10GbGen::vaDefaults(LineRate)
  set ::RL10GbGen::va10GbGenSet($chassis.[expr {$po - 1}].activity) new
  set ::RL10GbGen::va10GbGenSet($activePort.PatternType) $::RL10GbGen::vaDefaults(PatternType)
  set ::RL10GbGen::va10GbGenSet($activePort.PatternData) $::RL10GbGen::vaDefaults(PatternData)
  set ::RL10GbGen::va10GbGenSet($activePort.EthIIEn) $::RL10GbGen::vaDefaults(EthIIEn)
  set ::RL10GbGen::va10GbGenSet($activePort.EthIIType) $::RL10GbGen::vaDefaults(EthIIType)
  set ::RL10GbGen::va10GbGenSet($activePort.IPV4) $::RL10GbGen::vaDefaults(IPV4)
  set ::RL10GbGen::va10GbGenSet($activePort.IP) $::RL10GbGen::vaDefaults(IP)
  set ::RL10GbGen::va10GbGenSet($activePort.PacketPerBurst) $::RL10GbGen::vaDefaults(PacketPerBurst)    
  set ::RL10GbGen::va10GbGenSet($activePort.RcvPort) $::RL10GbGen::vaDefaults(RcvPort)  
  
  set ::RL10GbGen::va10GbGenSet($id.$strId.TxPort) $activePort
  set ::RL10GbGen::va10GbGenSet($id.$strId.RxPort) $::RL10GbGen::vaDefaults(RcvPort)  
  for {set i 1} {$i<=8} {incr i} {
    set ::RL10GbGen::va10GbGenSet($activePort.PacketEmixEn$i) $::RL10GbGen::vaDefaults(PacketEmixEn$i)
    set ::RL10GbGen::va10GbGenSet($activePort.PacketEmixLen$i) $::RL10GbGen::vaDefaults(PacketEmixLen$i)
  }
  set ::RL10GbGen::va10GbGenSet($activePort.PacketMaxLen) $::RL10GbGen::vaDefaults(PacketMaxLen)
  set ::RL10GbGen::va10GbGenSet($activePort.PacketMinLen) $::RL10GbGen::vaDefaults(PacketMinLen)
  if ![info exist ::RL10GbGen::va10GbGenSet($activePort.StreamEnable)] {
    set ::RL10GbGen::va10GbGenSet($activePort.StreamEnable) $::RL10GbGen::vaDefaults(StreamEnable)
  }
  # puts "::RL10GbGen::va10GbGenSet($activePort.StreamEnable):$::RL10GbGen::va10GbGenSet($activePort.StreamEnable)"
  set ::RL10GbGen::va10GbGenSet($activePort.MplsEn) $::RL10GbGen::vaDefaults(MplsEn)
  set ::RL10GbGen::va10GbGenSet($activePort.packView) $::RL10GbGen::vaDefaults(packView)
  set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) $::RL10GbGen::vaDefaults(vlans,en)
  foreach v {1 2 3 4} {
    set ::RL10GbGen::va10GbGenSet($activePort.vlan.Id.$v)   $::RL10GbGen::vaDefaults(vlan.Id.$v) 
    set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.$v)   $::RL10GbGen::vaDefaults(vlan.En.$v) 
    set ::RL10GbGen::va10GbGenSet($activePort.vlan.uPri.$v) $::RL10GbGen::vaDefaults(vlan.uPri.$v) 
    set ::RL10GbGen::va10GbGenSet($activePort.vlan.cfi.$v)  $::RL10GbGen::vaDefaults(vlan.cfi.$v) 
    set ::RL10GbGen::va10GbGenSet($activePort.vlan.pid.$v)  $::RL10GbGen::vaDefaults(vlan.pid.$v) 
  } 
  set ::RL10GbGen::va10GbGenSet($activePort.ipv4DA) $::RL10GbGen::vaDefaults(ipv4DA)
  set ::RL10GbGen::va10GbGenSet($activePort.ipv4SA) $::RL10GbGen::vaDefaults(ipv4SA)
  set ::RL10GbGen::va10GbGenSet($activePort.ipv4UdpDP) $::RL10GbGen::vaDefaults(ipv4UdpDP)
  set ::RL10GbGen::va10GbGenSet($activePort.ipv4UdpSP) $::RL10GbGen::vaDefaults(ipv4UdpSP)
  set ::RL10GbGen::va10GbGenSet($activePort.tcpAckNum) $::RL10GbGen::vaDefaults(tcpAckNum)
  set ::RL10GbGen::va10GbGenSet($activePort.tcpSeqNum) $::RL10GbGen::vaDefaults(tcpSeqNum)
  set ::RL10GbGen::va10GbGenSet($activePort.ipv4Ttl) $::RL10GbGen::vaDefaults(ipv4Ttl)
  # AddChassis $tree chassis:$chassis.Port:$po chassis:$chassis.Port:$po.rcvPort "Receive Port" rport1.ico never 0
  # AddChassis $tree chassis:$chassis.Port:$po chassis:$chassis.Port:$po.stream "Packet Streams" stream1.ico never 0
  # AddChassis $tree chassis:$chassis.Port:$po chassis:$chassis.Port:$po.statView "Statistic View" stview1.ico never 0

}

# ***************************************************************************
# ParsePortName2IntNum
# ***************************************************************************
proc ParsePortNum2IntNum {port} {
  switch -exact -- $port {
    1  {return 30}
    2  {return 31}
    3  {return 28}
    4  {return 29}
    5  {return  1}
    6  {return  2}
    7  {return  3}
    8  {return  4}    
  }
}
# ***************************************************************************
# ParsePortNum2Ihp
# ***************************************************************************
proc ParsePortNum2Ihp {port} {
  switch -exact -- $port {
    1 - 2 {return 2}
    3 - 4 - 5 - 6 - 7 - 8  {return 0}       
  }
}
# ***************************************************************************
# ParsePortIntNum2Num
# ***************************************************************************
proc ParsePortIntNum2Num {port} {
  switch -exact -- $port {
    30 {return 1 }
    31 {return 2 }
    28 {return 3 }
    29 {return 4 }
     1 {return 5 }
     2 {return 6 }
     3 {return 7 }
     4 {return 8 }    
  }
}

# ***************************************************************************
# PopUp1
# ***************************************************************************
proc PopUp1 {x y node} {
  variable va10GbGenSet
  if {[winfo exists .top10GbGenGui.men]} {
    destroy  .top10GbGenGui.men
  }  
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "PopUp1 $node" ; update
  }
  set men [menu .top10GbGenGui.men -tearoff 0]
  set ::me $men
  $::RL10GbGen::va10GbGenGui(resources,list) selection set $node
  if {$node=="home"} {
    set what home
  } elseif {[llength [split $node .] ] == 1} {
    set what chass
  } elseif {[llength [split $node .] ] == 2} {
    set what port
  }
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts what:$what
  }
  switch -exact -- $what {
    home {
      $men insert end command -label "Run all configurated chasisses"
      $men insert end command -label "Stop all configurated chasisses"
      $men insert end command -label "Clear statistics of all configurated chasisses"
      $men insert end separator
      $men insert end command -label "Connect chassis" -command {::RL10GbGen::ConnectChassis}
    }
    chass {
      $men insert end command -label "Run all configurated ports"
      $men insert end command -label "Stop all configurated ports"
      $men insert end command -label "Clear statistics of all configurated ports"
    }
    port {
      $men insert end command -label "Run stream"
      $men insert end command -label "Stop stream"
      $men insert end command -label "Clear stream's statistics"
      $men insert end separator
      $men insert end command -label "Edit stream" \
          -command "
            ::RL10GbGen::GuiStream FrameData
            ::RL10GbGen::ToggleFra $node
          "
    }
  }
  $men entryconfigure 0 -compound left -command {::RL10GbGen::ButRun} \
      -image [image create photo -file $va10GbGenSet(rundir)/Images/run1.ico]
      
  
  $men entryconfigure 1  -compound left -command {::RL10GbGen::ButStop} \
      -image [image create photo -file $va10GbGenSet(rundir)/Images/stop1.ico]
      
      
  $men entryconfigure 2  -compound left -command {::RL10GbGen::ButClearStats} \
      -image [image create photo -file $va10GbGenSet(rundir)/Images/clear3.ico]
         
  tk_popup $men $x $y
  return {}
}

# ***************************************************************************
# RcvPortLbl
# ***************************************************************************
proc RcvPortLbl {node chas po} {
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "RcvPortLbl node:$node chas:$chas po:$po"
  }
  $::RL10GbGen::va10GbGenGui(resources,list) itemconfigure $node -text "Receive Port: Chassis:$chas.Port$po"
}

# ***************************************************************************
# ToggleFra
#  ::RL10GbGen::ToggleFra chassis:1.Port:1
# ***************************************************************************
proc ToggleFra {node} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  variable va10GbGenGetStats
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "ToggleFra node: <$node>" 
  }
  set tree $va10GbGenGui(resources,list)
  if ![::RL10GbGen::GlobalSanityCheck] {return}
  if {[$::RL10GbGen::va10GbGenGui(PacketSizeMax) get] < [$::RL10GbGen::va10GbGenGui(PacketSizeMin) get]} {
    tk_messageBox -message "The \'MIN packet size\' cann't be more then \'MAX packet size\' "\
        -title "Wrong packet size"
    return {}    
  }
  
  catch {pack forget $va10GbGenGui(fra,fraStream)}
  catch {pack forget $va10GbGenGui(fra,statView)}
  catch {pack forget $va10GbGenGui(fra,packetView)}
  
  
  if {[llength [split $node :]] == 2} {
    ## meantime do not show anything for chassis
    set node chassis
  }
  switch -exact -- $node {
    home {
      set reslist  [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) home]
      if [llength $reslist] {
        $::RL10GbGen::va10GbGenGui(nb) raise [$::RL10GbGen::va10GbGenGui(nb) page 1]
      }   
    }
    chassis {
      $::RL10GbGen::va10GbGenGui(nb) raise [$::RL10GbGen::va10GbGenGui(nb) page 1]  
    }
    default {
      pack $va10GbGenGui(fra,fraStream) -anchor w	-fill x  
      pack $va10GbGenGui(fra,statView) -anchor w	-fill x
      pack $va10GbGenGui(fra,packetView) -anchor w	-fill x
      
      $va10GbGenGui(StreamEnable) configure -variable ::RL10GbGen::va10GbGenSet([GetActivePort].StreamEnable)
      $va10GbGenGui(fra,packView,lbl) configure -textvariable ::RL10GbGen::va10GbGenSet([GetActivePort].packView)
      
      set stream_id [expr {[lindex [split [lindex [split $node .] 1] :] 1] - 1}]
      set chassis [lindex [split [lindex [split $node .] 0] :] 1]      
      set id $::RL10GbGen::va10GbGenStatuses($chassis,10GbGenID)
      set activity $::RL10GbGen::va10GbGenSet($id.$stream_id.activity)
      if {$activity=="run"} {
        $va10GbGenGui(bRun)  configure -state disabled -relief sunken
        $va10GbGenGui(bStop) configure -state normal -relief raised
        $va10GbGenGui(StreamEnable) configure -state disabled
      } elseif {$activity=="stop" || $activity=="new"} {
        $va10GbGenGui(bRun)  configure -state normal -relief raised
        $va10GbGenGui(bStop) configure -state disabled -relief sunken
        $va10GbGenGui(StreamEnable) configure -state normal
      }
      foreach w "$::RL10GbGen::vlStreamStatsL"  { 
        if ![info exists ::RL10GbGen::va10GbGenGetStats($id.$stream_id.$w)] {
          set ::RL10GbGen::va10GbGenGetStats($id.$stream_id.$w) ""
        }
        $::RL10GbGen::va10GbGenGui(fra,statView,ent$w) configure -text $::RL10GbGen::va10GbGenGetStats($id.$stream_id.$w)
      }
      $::RL10GbGen::va10GbGenGui(nb) raise [$::RL10GbGen::va10GbGenGui(nb) page 0]
    }
  }
  # $va10GbGenGui(nb) compute_size
  ::RL10GbGen::UpdateChassisLineRate
  update idletasks
}
# ***************************************************************************
# mparray
# ***************************************************************************
proc mparray {a {pattern *}} {
  upvar 1 $a array
  if {![array exists array]} {
	  error "\"$a\" isn't an array"
  }
  set maxl 0
  foreach name [lsort -dict [array names array $pattern]] {
	  if {[string length $name] > $maxl} {
	    set maxl [string length $name]
  	}
  }
  set maxl [expr {$maxl + [string length $a] + 2}]
  foreach name [lsort -dict [array names array $pattern]] {
	  set nameString [format %s(%s) $a $name]
	  puts stdout [format "%-*s = %s" $maxl $nameString $array($name)]
  }
}
# ***************************************************************************
# ::RL10GbGen::GetActivePort
# set activePort [::RL10GbGen::GetActivePort]
# ***************************************************************************
proc GetActivePort {} {
  variable va10GbGenGui
  set ret [$::RL10GbGen::va10GbGenGui(resources,list) selection get]
  return $ret
}
# ***************************************************************************
# GetActiveChassis
# ***************************************************************************
proc GetActiveChassis {} {
  set ret [::RL10GbGen::GetActivePort]
  set ret [lindex [split $ret .] 0]
  return $ret
}
# ***************************************************************************
# ParsePort
# ***************************************************************************
proc ParsePort {prt} {
  return [lindex [split [lindex [split $prt .] 1] :] 1]
}
# ***************************************************************************
# GetActiveChassisId
# set activeChassisId [::RL10GbGen::GetActiveChassisId]
# ***************************************************************************
proc GetActiveChassisId {} {
  set acL [::RL10GbGen::GetActiveChassis]
  if {$acL=="home"} {
    set acL [$::RL10GbGen::va10GbGenGui(resources,list) nodes home]
  }
  set idL [list]
  foreach ac $acL {
    lappend idL [lindex [split $ac :] 1]
  }  
  return $idL
}

# ***************************************************************************
# ToggleEthII
# ***************************************************************************
proc ToggleEthII {activePort} {
  variable va10GbGenGui
  variable va10GbGenSetTmp
  set wL [list]
  lappend wL MplsEn  IPV4None IPV4IPV4 EthIIType 
  switch -exact -- $::RL10GbGen::va10GbGenSetTmp($activePort.EthIIEn) {
    None  {
      set state disabled
      set ::RL10GbGen::va10GbGenSetTmp($activePort.IPV4) None
      set ::RL10GbGen::va10GbGenSetTmp($activePort.IP) None
      set ::RL10GbGen::va10GbGenSetTmp($activePort.MplsEn) 0
      lappend wL IPNone IPtcp IPudp IPdhcp IPgre bIPV4Edit
    }
    EthII {
      set state normal 
    }    
  }
  foreach w $wL {
    $va10GbGenGui($w) configure -state $state 
  }
}
# ***************************************************************************
# ToggleIPV4
# ***************************************************************************
proc ToggleIPV4 {activePort} {
  variable va10GbGenGui
  variable va10GbGenSetTmp
  set wL [list]
  lappend wL IPNone IPtcp IPudp IPdhcp IPgre bIPV4Edit
  switch -exact -- $::RL10GbGen::va10GbGenSetTmp($activePort.IPV4) {
    None  {
      set state disabled 
      set ::RL10GbGen::va10GbGenSetTmp($activePort.IP) None 
      $va10GbGenGui(EthIIType) configure -state normal  
      $va10GbGenGui(general_setup,generator,FrameSizeType) configure -values {Fixed Incr Random EMIX}        
    }
    IPV4 {
      set state normal 
      set ::RL10GbGen::va10GbGenSetTmp($activePort.EthIIType) 0800 
      $va10GbGenGui(EthIIType) configure -state disabled
      $va10GbGenGui(general_setup,generator,FrameSizeType) configure -values Fixed
      set ::RL10GbGen::va10GbGenSetTmp($activePort.FrameSizeType) Fixed
      ToggleFrameSize $activePort
      if {![info exists ::RL10GbGen::va10GbGenSetTmp($activePort.ipv4DA)] || $::RL10GbGen::va10GbGenSetTmp($activePort.ipv4DA)==""} {
        set va10GbGenSetTmp($activePort.ipv4DA) 0.0.0.0
      }
      if {![info exists ::RL10GbGen::va10GbGenSetTmp($activePort.ipv4SA)] || $::RL10GbGen::va10GbGenSetTmp($activePort.ipv4SA)==""} {
        set va10GbGenSetTmp($activePort.ipv4SA) 0.0.0.0
      }
      if {![info exists ::RL10GbGen::va10GbGenSetTmp($activePort.ipv4Ttl)] || $::RL10GbGen::va10GbGenSetTmp($activePort.ipv4Ttl)==""} {
        set va10GbGenSetTmp($activePort.ipv4Ttl) 64
      } 
      
    }    
  }
  foreach w $wL {
    $va10GbGenGui($w) configure -state $state 
  }
}  

# ***************************************************************************
# ToggleSeqNumOffset
# ***************************************************************************
proc ToggleSeqNumOffset {activePort} {
  variable va10GbGenGui
  variable va10GbGenSetTmp
  set wL [list]
  lappend wL "SeqChecking,ValUDF"
  switch -exact -- $::RL10GbGen::va10GbGenSetTmp($activePort.SeqNumOffset,Type) {
    def  {
      set state disabled 
    }
    udf {
      set state normal 
    }    
  }
  foreach w $wL {
    $va10GbGenGui($w) configure -state $state 
  }
}
# ***************************************************************************
# ToggleVlan
# ***************************************************************************
proc ToggleVlan {activePort} {
  variable va10GbGenGui
  variable va10GbGenSetTmp
  set wL [list]
  lappend wL  VlansBut
  switch -exact -- $::RL10GbGen::va10GbGenSetTmp($activePort.vlans,en) {
    0  {
      set state disabled 
    }
    1 {
      set state normal 
    }    
  }
  foreach w $wL {
    $va10GbGenGui($w) configure -state $state 
  }
}
# ***************************************************************************
# ToggleMpls
# ***************************************************************************
proc ToggleMpls {activePort} {
  variable va10GbGenGui
  variable va10GbGenSetTmp
  set wL [list]
  lappend wL  MplsBut
  switch -exact -- $::RL10GbGen::va10GbGenSetTmp($activePort.MplsEn) {
    0  {
      set state disabled 
    }
    1 {
      set state normal 
    }    
  }
  foreach w $wL {
    $va10GbGenGui($w) configure -state $state 
  }
}
# ***************************************************************************
# ::RL10GbGen::UpdateChassisPorts
# ***************************************************************************
proc UpdateChassisPorts {} {
  set reslist [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) home]
  set pl [list]
  foreach chas $reslist {
    for {set po 1} {$po <= 8} {incr po} {
      lappend pl $chas.Port:$po
    }
  }
  return $pl  
}
# ***************************************************************************
# UpdateFreeRcvPorts
# ***************************************************************************
proc UpdateFreeRcvPorts {activePort} {
  set w $::RL10GbGen::va10GbGenGui(RcvPortList)
  # puts "UpdateFreeRcvPorts $w $activePort"
  $w configure -values [::RL10GbGen::GetFreeRcvPorts $activePort]
}
# ***************************************************************************
# ::RL10GbGen::GetFreeRcvPorts
# ***************************************************************************
proc GetFreeRcvPorts {activePort} {
  set reslist [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) home]
  set pl [list]
  set occL [list]
  # puts "GetFreeRcvPorts activePort:$activePort reslist:$reslist"
  set chas [lindex [split $activePort .] 0]
  # foreach chas $reslist {}
  for {set po 1} {$po <= 8} {incr po} {
    lappend pl $chas.Port:$po
  }

  # puts "pl:$pl"
  foreach p $pl {
    if {[info exists ::RL10GbGen::va10GbGenSetTmp($p.RcvPort)] && $::RL10GbGen::va10GbGenSetTmp($p.RcvPort)!=""} {
      lappend occL $::RL10GbGen::va10GbGenSetTmp($p.RcvPort)      
    }
  }
  
  foreach occP $occL {
    set indx [lsearch $pl [string trim [lindex [split $occP - ] 0] ] ]
    set pl [lreplace $pl $indx $indx]
  }
  # puts "occL:<$occL>"
  set pl [lsort -unique $pl]
  foreach p $pl {
    set po [lindex [split $p :] end]
    switch -exact $po {
      1 - 2 - 3 - 4 {set ps 10G}
      5 - 6 - 7 - 8 {set ps 1G}
    }    
    set pl [lreplace $pl [lsearch $pl $p] [lsearch $pl $p] "[set p] - $ps"]
  }
  set pl [concat "NC" $pl]
  # puts "GetFreeRcvPorts pl:$pl"
  return $pl
}

# ***************************************************************************
# SetTxPort
# ***************************************************************************
proc SetTxPort {activePort} {
  set stream_id [expr {[lindex [split [lindex [split $activePort .] 1] :] 1] - 1}]
  set chassis [lindex [split [lindex [split $activePort .] 0] :] 1]      
  set id $::RL10GbGen::va10GbGenStatuses($chassis,10GbGenID)
  set tp $activePort
  set rp $::RL10GbGen::va10GbGenSetTmp($activePort.RcvPort)
  set ::RL10GbGen::va10GbGenSetTmp($rp.TxPort) $tp
}



# ***************************************************************************
# TogglePacketPerBurst
# ***************************************************************************
proc TogglePacketPerBurst {activePort} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  variable va10GbGenSetTmp
  switch -exact -- $::RL10GbGen::va10GbGenSetTmp($activePort.PacketBurst) {
    packet {set state disabled}
    burst {set state normal}
  }
  $va10GbGenGui(PacketPerBurst) configure -state $state
}
# ***************************************************************************
# ClearStatistics
# ***************************************************************************
proc ClearStatistics {id stream_id} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  variable va10GbGenSetTmp
  variable va10GbGenGetStats
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] ClearStatistics $id $stream_id"
  }
  set activity $::RL10GbGen::va10GbGenSet($id.$stream_id.activity)
  set ::RL10GbGen::va10GbGenSet($id.$stream_id.activity) "clear"

  ## only for non-running activity states - "stop" and "new" - I should 
  ## set the -text to "0". the running port's -text should by set to "0" 
  ## by ETX itself, after performing StreamClearStatistics from WhileLoopReadStats
  if {$activity=="stop" || $activity=="new"} {
    set strStats [expr {$stream_id + 1}]
    foreach w "$::RL10GbGen::vlStreamStatsL" { 
      if {[$::RL10GbGen::va10GbGenGui(stats.$id.$strStats.$w) cget -text]!=""} {
        $::RL10GbGen::va10GbGenGui(stats.$id.$strStats.$w)  configure -text 0 -fg black
      }
      set ::RL10GbGen::va10GbGenGetStats($id.$stream_id.$w) 0
      $va10GbGenGui(fra,statView,ent$w) configure -text "0"  -fg black
    }
    set TxPort [::RL10GbGen::ParsePort $::RL10GbGen::va10GbGenSet($id.$stream_id.TxPort)]
    set RxPort [::RL10GbGen::ParsePort $::RL10GbGen::va10GbGenSet($id.$stream_id.RxPort)]
    foreach w "$::RL10GbGen::vlPortStatsL" { 
      $::RL10GbGen::va10GbGenGui(statsPort.$id.$TxPort.$w)  configure -text 0 -fg black
      $::RL10GbGen::va10GbGenGui(statsPort.$id.$RxPort.$w)  configure -text 0 -fg black
    }
  }
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "[::RL10GbGen::MyTime] ClearStatistics id:$id stream_id:$stream_id activity:$activity" ; update
  }
  update   
}

# ***************************************************************************
# ::RL10GbGen::BuildPacket
# ***************************************************************************
proc BuildPacket {activePort} {
  global gMessage
  variable va10GbGenGui
  variable va10GbGenSet
  variable va10GbGenCfg
	variable va10GbGenStatuses
  
 
  set pkt [::RL10GbGen::SplitString2Paires $::RL10GbGen::va10GbGenSet($activePort.DA)]
  set pkt [concat $pkt [::RL10GbGen::SplitString2Paires $::RL10GbGen::va10GbGenSet($activePort.SA)]]
  set headersLen 12
  
  if ![info exists ::RL10GbGen::va10GbGenSet($activePort.vlans,en)] {
    set ::RL10GbGen::va10GbGenSet($activePort.vlans,en) 0
  }
  if {$::RL10GbGen::va10GbGenSet($activePort.vlans,en)==1} {
    foreach v {1 2 3 4} {
      if ![info exists ::RL10GbGen::va10GbGenSet($activePort.vlan.En.$v)] {
        set ::RL10GbGen::va10GbGenSet($activePort.vlan.En.$v) 0
      }
      if {$::RL10GbGen::va10GbGenSet($activePort.vlan.En.$v)} {
        incr headersLen 4
        if ![info exists ::RL10GbGen::va10GbGenSet($activePort.vlan.pid.$v)] {
          set ::RL10GbGen::va10GbGenSet($activePort.vlan.pid.$v) $::RL10GbGen::vaDefaults(vlan.pid.$v)
        }
        set pid [string range $::RL10GbGen::va10GbGenSet($activePort.vlan.pid.$v) 2 end]
        set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $pid]]  
        
        if ![info exists ::RL10GbGen::va10GbGenSet($activePort.vlan.uPri.$v)] {
          set ::RL10GbGen::va10GbGenSet($activePort.vlan.uPri.$v) $::RL10GbGen::vaDefaults(vlan.uPri.$v)
        }
        set uPri [expr {2 * $::RL10GbGen::va10GbGenSet($activePort.vlan.uPri.$v)}]
        
        if ![info exists ::RL10GbGen::va10GbGenSet($activePort.vlan.cfi.$v)] {
          set ::RL10GbGen::va10GbGenSet($activePort.vlan.cfi.$v) $::RL10GbGen::vaDefaults(vlan.cfi.$v)
        }
        set cfi $::RL10GbGen::va10GbGenSet($activePort.vlan.cfi.$v)
        if {$cfi=="Reset" || $cfi=="0"} {
          set cfi 0
        } else {
          set cfi 1
        }
        set uPriCfi [expr {$uPri + $cfi}]      
        set uPriCfi [format %x $uPriCfi]
        
        if ![info exists ::RL10GbGen::va10GbGenSet($activePort.vlan.Id.$v)] {
          set ::RL10GbGen::va10GbGenSet($activePort.vlan.Id.$v) $::RL10GbGen::vaDefaults(vlan.Id.$v)
        }     
        set id $::RL10GbGen::va10GbGenSet($activePort.vlan.Id.$v)
        set id [format %.3x $id]
        
        set vlan [set uPriCfi][set id]
        
        set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $vlan]] 
      }    
    }
  }
  
  if ![info exists ::RL10GbGen::va10GbGenSet($activePort.EthIIEn)] {
    set ::RL10GbGen::va10GbGenSet($activePort.EthIIEn) None
  }
  if {$::RL10GbGen::va10GbGenSet($activePort.EthIIEn)=="None"} {
    ## add nothing
  } elseif {$::RL10GbGen::va10GbGenSet($activePort.EthIIEn)=="EthII"} {
    if ![info exists ::RL10GbGen::va10GbGenSet($activePort.EthIIType)] {
      ## if there is no ipv4 then the EthIIType is FFFF
      ## otherwise he EthIIType is 0800
      set ::RL10GbGen::va10GbGenSet($activePort.EthIIType) $::RL10GbGen::vaDefaults(EthIIType) ; # FF FF
      if {$::RL10GbGen::va10GbGenSet($activePort.IPV4)=="IPV4"} {
        set ::RL10GbGen::va10GbGenSet($activePort.EthIIType) "0800"
      }
    } 
    set EthIIType $::RL10GbGen::va10GbGenSet($activePort.EthIIType)
    set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $EthIIType]]
    incr headersLen 2
  }
   
  if ![info exists ::RL10GbGen::va10GbGenSet($activePort.IPV4)] {
    set ::RL10GbGen::va10GbGenSet($activePort.IPV4) None
  } 
  if {$::RL10GbGen::va10GbGenSet($activePort.IPV4)=="IPV4"} {
    set frSize $::RL10GbGen::va10GbGenSet($activePort.PacketFixLen)
    
    ## reduce the frame size for the lastEthType
    ## lastEthType will be added to the pkt at end of the process
    set frSize [expr {$frSize - 2}]

    set ipv4 45 ; # version (4) and header len (5 * quoters (4 bytes))
    append ipv4 00 ; # TOS/DSCP
    set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $ipv4]]
    incr headersLen 2
    
    
    set frameLen [format %.4x [expr {$frSize - $headersLen - 2}] ]
    set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $frameLen]]
    incr headersLen 2
    
    set identifier 0000
    set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $identifier]]
    incr headersLen 2
    
    set flagsFragm 0000
    set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $flagsFragm]]
    incr headersLen 2
    
    if ![info exists ::RL10GbGen::va10GbGenSet($activePort.ipv4Ttl)] {
      set ::RL10GbGen::va10GbGenSet($activePort.ipv4Ttl) $::RL10GbGen::vaDefaults(ipv4Ttl)
    }
    set ttl $::RL10GbGen::va10GbGenSet($activePort.ipv4Ttl)
    set ttl [format %.2x $ttl]
    set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $ttl]]
    incr headersLen 1
    
    if ![info exists ::RL10GbGen::va10GbGenSet($activePort.IP)] {
      set ::RL10GbGen::va10GbGenSet($activePort.IP) $::RL10GbGen::vaDefaults(IP)
    }
    switch -exact -- $::RL10GbGen::va10GbGenSet($activePort.IP) { 
      None {set prot 255}
      TCP  {set prot 6}
      UDP  {set prot 17}
      DHCP {set prot 17}
      GRE  {set prot 47}
    }
    ## since DHCP is over UDP the prot==17
    set prot [format %.2x $prot]
    set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $prot]]
    incr headersLen 1
    
    if ![info exists ::RL10GbGen::va10GbGenSet($activePort.ipv4SA)] {
      set ::RL10GbGen::va10GbGenSet($activePort.ipv4SA) $::RL10GbGen::vaDefaults(ipv4SA)
    }
    set sa $::RL10GbGen::va10GbGenSet($activePort.ipv4SA)
    foreach prm [split $sa .] {
      append sad [format %.2x $prm] 
    }
    # set pkt [concat $pkt [::RL10GbGen::SplitString2Paires $sad]]
    incr headersLen 4
    
    if ![info exists ::RL10GbGen::va10GbGenSet($activePort.ipv4DA)] {
      set ::RL10GbGen::va10GbGenSet($activePort.ipv4DA) $::RL10GbGen::vaDefaults(ipv4DA)
    }
    set da $::RL10GbGen::va10GbGenSet($activePort.ipv4DA)
    foreach prm [split $da .] {
      append dad [format %.2x $prm] 
    }
    # set pkt [concat $pkt [::RL10GbGen::SplitString2Paires $dad]]
    incr headersLen 4
    
    set chkSum [::RL10GbGen::CalculateCheckSum 0x[set ipv4] 0x[set frameLen] \
        0x[set identifier] 0x[set flagsFragm] 0x[set ttl][set prot] \
        0x[string range $sad 0 3] 0x[string range $sad 4 7] \
        0x[string range $dad 0 3] 0x[string range $dad 4 7]]
    incr headersLen 2    
    
    set pkt [concat $pkt [::RL10GbGen::SplitString2Paires $chkSum]]
    set pkt [concat $pkt [::RL10GbGen::SplitString2Paires $sad]]
    set pkt [concat $pkt [::RL10GbGen::SplitString2Paires $dad]]
  
  
    if {$::RL10GbGen::va10GbGenSet($activePort.IP)=="TCP"} {
      set tcpSeqLen 0
      set sp 0000
      set sp 066d
      set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $sp]]
      incr headersLen 2
      incr tcpSeqLen 2
      
      set dp 0000
      set dp 0050
      set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $dp]]
      incr headersLen 2
      incr tcpSeqLen 2
      
      set seqNum $::RL10GbGen::va10GbGenSet($activePort.tcpSeqNum)
      # set seqNum "00 00 00 01"
      set pkt [concat $pkt $seqNum]
      incr headersLen 4 
      incr tcpSeqLen 4
      
      set ackNum $::RL10GbGen::va10GbGenSet($activePort.tcpAckNum)
      # set ackNum  "00 00 00 01"
      set pkt [concat $pkt $ackNum]
      incr headersLen 4
      incr tcpSeqLen 4
      
      set headerLen 0101 ; # 5*4=20 bytes
      set reserv    000000
      set flags     000000
      set flags 000010
      set field [set headerLen][set reserv][set flags]
      set field [::RL10GbGen::Bits2Hex $field -]
      incr headersLen 2
      incr tcpSeqLen 2
      set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $field]]
      
      set win 0000
      set win 0080
      set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $win]]
      incr headersLen 2
      incr tcpSeqLen 2
      
      set up 0000
      incr headersLen 2
       incr tcpSeqLen 2
      
      incr headersLen 2; # for checksum
      incr tcpSeqLen 2
  
      incr headersLen 4; # for CRC
      incr tcpSeqLen 4
      
      set freeDataLen [expr {$frSize - $headersLen}]
      incr tcpSeqLen $freeDataLen 
      if {$::RL10GbGen::g10GbGenBufferDebug} {
        puts "frSize:$frSize headersLen:$headersLen freeDataLen:$freeDataLen tcpSeqLen:$tcpSeqLen"
      }
      
      set payload [::RL10GbGen::BuildPayload $activePort $freeDataLen]
      if {$::RL10GbGen::g10GbGenBufferDebug} {
        puts "payload $payload"
      }  
      
      set sad c0442b01
      set dad 0ab00222
      set chkSum [::RL10GbGen::CalculateCheckSum \
          0x[string range $sad 0 3] 0x[string range $sad 4 7] \
          0x[string range $dad 0 3] 0x[string range $dad 4 7] \
          0x6 0x[format %.2x $tcpSeqLen] 0x[set sp] 0x[set dp] \
          0x[lindex $seqNum 0][lindex $seqNum 1] 0x[lindex $seqNum 2][lindex $seqNum 3] \
          0x[lindex $ackNum 0][lindex $ackNum 1] 0x[lindex $ackNum 2][lindex $ackNum 3] \
          0x[set field] 0x[set win] 0x[set up] ]
      # incr headersLen 2
      
      set pkt [concat $pkt [::RL10GbGen::SplitString2Paires $chkSum]]
      set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $up]]
    }
  } 
  # puts "BuildPacket $activePort pkt:<$pkt>" 
  set pkt [concat $pkt  [::RL10GbGen::SplitString2Paires $::RL10GbGen::va10GbGenSet(lastEthType)]]
  # puts "BuildPacket $activePort pkt:<$pkt>" 
  incr headersLen 2  
  
  # set freeDataLen [expr {$frSize - $headersLen - 4}] ; # 4 bytes for CRC32
  # puts "frSize:$frSize headersLen:$headersLen freeDataLen:$freeDataLen"
  # set payload [::RL10GbGen::BuildPayload $activePort $freeDataLen]
 ## puts "payload $payload"
  ##set pkt [concat $pkt $payload]   don't do it meantime
  
  set pktString [join $pkt ""]
  set crc [::RL10GbGen::Crc32 $pktString]
  ##set pkt [concat $pkt [::RL10GbGen::SplitString2Paires $crc]]   don't do it meantime
  
  set pkt [string toupper $pkt]  
  # puts "BuildPacket $activePort pkt:<$pkt>" 
  # $::RL10GbGen::va10GbGenGui(runStatus) configure -text $pkt
  set pktLen [llength $pkt]
  if [winfo exists ::RL10GbGen::va10GbGenGui(fra,packView,lbl)] {
    $::RL10GbGen::va10GbGenGui(fra,packView,lbl) configure -text ""
  }
  set txt ""
  for {set i 0; set k 15} {$i<[expr {$pktLen / 16}]} {incr i} {
    append txt "[lrange $pkt [expr {$i*16}] [expr {$i*16 + 15}]]\n"
    
  }
  append txt "[lrange $pkt [expr {16*$i}] end]"
  # $::RL10GbGen::va10GbGenGui(fra,packView,lbl) configure -text $txt
  # puts "BuildPacket $activePort txt:<$txt>"
  if [info exist ::RL10GbGen::va10GbGenSet($activePort.packView)] {
    set ::RL10GbGen::va10GbGenSet($activePort.packView) "$activePort   $txt"
  }
  return $pkt
}
# ***************************************************************************
# SplitString2Paires
# ***************************************************************************
proc SplitString2Paires {str} {
  foreach {f s} [split $str ""] {
    lappend l [set f][set s]
  }
  return $l
}
# ***************************************************************************
# CalculateCheckSum
# ***************************************************************************
proc CalculateCheckSum {args} {
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "CalculateCheckSum $args"
  }
  set sum1 0
  foreach arg $args {
    set sum1 [expr $sum1 + $arg]
  }  
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts sum1:$sum1   
  }
  set sum2 [format %.8x $sum1] 
  set sum3 [format %x $sum1]
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "sum3:$sum3 sum2:$sum2"  
  }
  # set sum4 [::RL10GbGen::Hex2Bin 0x$sum2 [expr {4 * [string length $sum3]}]]
  if {[string length $sum3]<5} {
    set sum4 [expr 1 * 0x[set sum3]]
  } elseif {[string length $sum3]==5} {
    set sum4 [expr 0x[string range $sum3 0 0] + 0x[string range $sum3 1 end]]
  }  
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "sum4:$sum4"
  }
  set sum5 [format %x $sum4]
  set sum6 [format %.8x $sum4]
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "sum5:$sum5 sum6:$sum6"
  }
  set sum7 [::RL10GbGen::Hex2Bin 0x$sum6 [expr {4 * [string length $sum5]}]]
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "sum7:$sum7"
  }  
  foreach bit [split $sum7 ""] {
    append flip [expr {1 ^ $bit}] ; # 1 XOR bit == ^bit
  } 
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts flip:$flip
  }
  set sum8 [::RL10GbGen::Bits2Hex $flip 4]
  if {$::RL10GbGen::g10GbGenBufferDebug} {
    puts "sum8:$sum8"
  }
  return $sum8
  # ::RL10GbGen::  
}
# ***************************************************************************
# Hex2Bin
# ***************************************************************************
proc Hex2Bin {val {len 16}} {
  if {[string range $val 0 1]=="0x"} {
    set val [string range $val 2 end]
  }
  set binRep [binary format H* $val]
  binary scan $binRep B* binStr
  return [string range $binStr [expr {[string length $binStr]-$len}] end]
}
# ***************************************************************************
# Bits2Hex
# ***************************************************************************
proc Bits2Hex {bits fillZero} {
  # returns integer equivalent of a bitlist
  set bits [format %032s [join $bits {}]]
  binary scan [binary format B* $bits] I1 x
  if {$fillZero!="-"} {
    return [format %0[set fillZero]X $x]
  } elseif {$fillZero=="-"} {
    return [format %X $x]
  }  
}
# ***************************************************************************
# BuildPayload
# ***************************************************************************
proc BuildPayload {activePort freeDataLen} {
  if ![info exist ::RL10GbGen::va10GbGenSet($activePort.PatternType)] {
    set ::RL10GbGen::va10GbGenSet($activePort.PatternType) AllZeros 
  }
   if ![info exist ::RL10GbGen::va10GbGenSet($activePort.PatternData)] {
    set ::RL10GbGen::va10GbGenSet($activePort.PatternData) "00" 
  }
  set pT $::RL10GbGen::va10GbGenSet($activePort.PatternType)
  set pD $::RL10GbGen::va10GbGenSet($activePort.PatternData)
  set patt $pD
  set pattLen [llength $patt] 
  switch -exact -- $pT {
    Fixed {
      while {[expr {$pattLen < $freeDataLen}]} {
        set patt [concat $patt $pD]
        set pattLen [llength $patt]
      }  
    }
  }
  return [lrange $patt 0 [expr {$freeDataLen-1}]]
  # ::RL10GbGen::
}
# ***************************************************************************
# Crc32
# ***************************************************************************
proc Crc32 {instr} {
  set gCrc32List [::RL10GbGen::CreateCrc32List]
  set crc_value 0xFFFFFFFF
  for {set idx 0} {$idx < [string length $instr]} {incr idx 2} {
     set str 0x[string range $instr $idx [expr {$idx +1}]]
     set crc_value [expr [lindex $gCrc32List [expr ($crc_value ^ $str) & 0xFF]] ^ [::RL10GbGen::>>> $crc_value 8]]
  }
  set crc [format %.8X [format %u [expr $crc_value ^ 0xFFFFFFFF]]]
  # # revercing bytes: AABBCCDD->DDCCBBAA
  set ret ""
  for {set idx 0} {$idx < [string length $crc]} {incr idx 2} {
   set ret [string range $crc $idx [expr {$idx +1}]][set ret]
  }
  return $ret
}

# ***************************************************************************
# >>>
# ***************************************************************************
proc >>> {x1 x2} {
  for {set v 1} {$v!=0} {set w $v; set v [expr {$v<<1}]} {}
  set ret [expr {($x1>>$x2) & ~($w>>($x2-1))}]
  return $ret
}

# ***************************************************************************
# CreateCrc32List
# ***************************************************************************
proc CreateCrc32List {} {
  for {set i 0} {$i<256} {incr i} {
    set crc $i
    for {set j 0} {$j < 8} {incr j} {
      if {[expr {$crc & 1}]} {
        set crc [expr {($crc>>1) ^ 0xEDB88320}]
      } else {
        set crc [expr {$crc>>1}]
      }
    }
    lappend crcL [format 0x%.8X $crc]
  }
  return $crcL
}

# ***************************************************************************
# MyTime
# ***************************************************************************
proc MyTime {} {
  return [clock format [clock seconds] -format "%T %d/%m/%Y"]
}

# ***************************************************************************
# ToggleStreamEnable
# ***************************************************************************
proc ToggleStreamEnable {} {
  global gMessage
  # puts "ToggleStreamEnable"
  variable va10GbGenSetTmp                                        
  variable va10GbGenSet   
  set tree $::RL10GbGen::va10GbGenGui(resources,list)  
  set chassisL [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) home]
  # parray ::RL10GbGen::va10GbGenSet *StreamEnable
  foreach chassis $chassisL {
    set chas [lindex [split $chassis :] 1]
    set id $::RL10GbGen::va10GbGenStatuses($chas,10GbGenID)
    for {set po 1} {$po <= 8} {incr po} {
      set activePort $chassis.Port:$po
      # puts "ToggleStreamEnable 1 chassis:<$chassis> activePort:$activePort" ; update
      array unset va10GbGenSetTmp $activePort.*
      array set va10GbGenSetTmp [array get va10GbGenSet $activePort.*]
      set activity $::RL10GbGen::va10GbGenSet($id.[expr {$po-1}].activity)
      set strEn $::RL10GbGen::va10GbGenSet($activePort.StreamEnable)
      # puts "ToggleStreamEnable 2 chassis:<$chassis> activePort:$activePort activity:<$activity> strEn:<$strEn>" ; update      
      if {$strEn==1} {
        GuiStreamButOk .topGuiStream $activePort
        set received_port [lindex [split [string trim [lindex [split $::RL10GbGen::va10GbGenSet($activePort.RcvPort) - ] 0]] : ] end]
        if {$received_port=="" || $received_port=="NC"} {
          set ::RL10GbGen::va10GbGenSet($activePort.StreamEnable) 0
          set gMessage "The Receive Port at $activePort is not defined.\nChoose an appropriate Port at the \"Stream Control\" page."
          return [RLEH::Handle Syntax gMessage]
        }
        if {$activity=="stop" || $activity=="new"} {
          $tree itemconfigure $activePort -image [image create photo -file $::RL10GbGen::va10GbGenSet(rundir)/images/port2.ico]
        }
      } elseif {$strEn==0} {
        if {$activity=="stop" || $activity=="new"} {
          $tree itemconfigure $activePort -image [image create photo -file $::RL10GbGen::va10GbGenSet(rundir)/images/port1.ico]
        }
      } 
    }
  }
}
# ***************************************************************************
# CalcChassisLineRate
# ***************************************************************************
proc CalcChassisLineRate {} {
  set tree $::RL10GbGen::va10GbGenGui(resources,list)  
  set pl [list]  
  set chassis [lindex [split [::RL10GbGen::GetActivePort] .] 0]
  set id [lindex [split $chassis :] 1]
  if {[string match *home* $chassis] || $chassis==""} {return ""}
  set reslist [Tree::nodes $::RL10GbGen::va10GbGenGui(resources,list) $chassis]
  for {set po 1} {$po <= 8} {incr po} {
    if {$::RL10GbGen::va10GbGenSet($chassis.Port:$po.RcvPort)=="NC" || \
        $::RL10GbGen::va10GbGenSet($chassis.Port:$po.RcvPort)==""} {
      
    }    
    if ![info exists ::RL10GbGen::va10GbGenSet($chassis.Port:$po.StreamEnable)] {
      set ::RL10GbGen::va10GbGenSet($chassis.Port:$po.StreamEnable) 0
    }
    # set activity $::RL10GbGen::va10GbGenSet($id.[expr {$po-1}].activity)
    if {$::RL10GbGen::va10GbGenSet($chassis.Port:$po.StreamEnable)==1} {
      lappend pl $chassis.Port:$po
    } elseif {$::RL10GbGen::va10GbGenSet($chassis.Port:$po.StreamEnable)==0} {
      # # do nothing
    } 
  }
  if {[llength $pl]==0} {return 0}
  
  set chasLineRate 0
  foreach po $pl {
    set tx_port_stream $::RL10GbGen::va10GbGenSet($po.intNum)
    set val $::RL10GbGen::va10GbGenSet($po.LineRate)
    switch -exact -- $tx_port_stream {
      30 - 31 - 28 - 29 {
        set rate [format %.4E [expr {[string trimright $val %]*10e+9/100.0}]]              
      } 
      1 - 2 - 3 - 4 {
        set rate [format %.4E [expr {[string trimright $val %]*1e+9/100.0}]]             
      }
    } 
    set chasLineRate [expr {$chasLineRate + $rate}]
  }
  set max 1.0000E+010
  set per [expr {($chasLineRate/$max)*100}]
  return $per
  # return [format %.4E $chasLineRate]
}
# ***************************************************************************
# UpdateChassisLineRate
# ***************************************************************************
proc UpdateChassisLineRate {} {  
  global gMessage  
  set max 70.0; # 100.0  08/01/2014 15:49:29
  set msg ""
  foreach activePort [::RL10GbGen::GetEnabledPorts all] {
    if {$::RL10GbGen::va10GbGenSet($activePort.FrameSizeType)=="Incr"  || \
        $::RL10GbGen::va10GbGenSet($activePort.FrameSizeType)=="Random"} {
      set max 50.0
      set msg "At least one stream has \"Incr\" or \"Random\" Frame Size Type.\r"
      break    
    }
  }
  set chassisLineRate [::RL10GbGen::CalcChassisLineRate]
  # set ::RL10GbGen::va10GbGenSet(global,totalBitRate) $chassisLineRate ; # 12/01/2014 13:40:30
  if {$chassisLineRate>$max} {
    # $::RL10GbGen::va10GbGenGui(global,totalBitRate) configure -fg red ; # 12/01/2014 13:40:30
    # set txt "$chassisLineRate Over!!!" ; # 12/01/2014 13:40:30 
    set ret -1 ; # 12/01/2014 13:40:30
  } else {
    $::RL10GbGen::va10GbGenGui(global,totalBitRate) configure -fg black
    set txt "$chassisLineRate"
    set ret 0 ; # 12/01/2014 13:40:30
  }
  if {$ret==0} {
    set ::RL10GbGen::va10GbGenSet(global,totalBitRate) $txt
  } else {
    set ::RL10GbGen::va10GbGenSet([::RL10GbGen::GetActivePort].StreamEnable) 0
    set gMessage "[set msg]Enabling this stream will exceed the Total Bit Rate limit.
    The maximum Total Bit Rate can be [expr int($max)]%"
    return [RLEH::Handle Warning gMessage]
 
  }
  return $ret
}

# ***************************************************************************
# Defaults
# ***************************************************************************
proc Defaults {} {
  variable vaDefaults
  set ::RL10GbGen::vaDefaults(PatternType) AllZeros
  set ::RL10GbGen::vaDefaults(PatternData) "00"
  set ::RL10GbGen::vaDefaults(FrameSizeType) Fixed
  set ::RL10GbGen::vaDefaults(DA) 001000100001  
  set ::RL10GbGen::vaDefaults(SA) 002000200002
  set ::RL10GbGen::vaDefaults(EthIIEn) None
  set ::RL10GbGen::vaDefaults(EthIIType) FFFF
  set ::RL10GbGen::vaDefaults(IPV4) None
  set ::RL10GbGen::vaDefaults(IP) None
  set ::RL10GbGen::vaDefaults(IPG) 20
  set ::RL10GbGen::vaDefaults(SeqErrorThreshold) 0
  set ::RL10GbGen::vaDefaults(PacketBurst) packet
  set ::RL10GbGen::vaDefaults(PacketPerBurst) 100
  set ::RL10GbGen::vaDefaults(LineRate) 10
  set ::RL10GbGen::vaDefaults(RcvPort) "NC"
  set ::RL10GbGen::vaDefaults(PacketFixLen) 1000
  for {set i 1} {$i<=8} {incr i} {
    set ::RL10GbGen::vaDefaults(PacketEmixEn$i) 0
    set ::RL10GbGen::vaDefaults(PacketEmixLen$i) 64
  }
  set ::RL10GbGen::vaDefaults(PacketMaxLen) 2000
  set ::RL10GbGen::vaDefaults(PacketMinLen) 64
  set ::RL10GbGen::vaDefaults(StreamEnable) 0
  set ::RL10GbGen::vaDefaults(MplsEn) 0
  set ::RL10GbGen::vaDefaults(packView) ""
  set ::RL10GbGen::vaDefaults(ipv4DA) "0.0.0.0"
  set ::RL10GbGen::vaDefaults(ipv4SA) "0.0.0.0"
  set ::RL10GbGen::vaDefaults(ipv4Ttl) 64
  set ::RL10GbGen::vaDefaults(tcpSeqNum) "00 00 00 00"
  set ::RL10GbGen::vaDefaults(tcpAckNum) "00 00 00 00"
  set ::RL10GbGen::vaDefaults(ipv4UdpSP) 63
  set ::RL10GbGen::vaDefaults(ipv4UdpDP) 63
  set ::RL10GbGen::vaDefaults(vlans,en) 0
  foreach v {1 2 3 4} {
    set ::RL10GbGen::vaDefaults(vlan.Id.$v) "0" 
    set ::RL10GbGen::vaDefaults(vlan.En.$v) 0
    set ::RL10GbGen::vaDefaults(vlan.uPri.$v) 0
    set ::RL10GbGen::vaDefaults(vlan.cfi.$v) "Reset" 
    set ::RL10GbGen::vaDefaults(vlan.pid.$v) "0x8100"
  } 
  set ::RL10GbGen::vaDefaults(clockFreq) 150
  set ::RL10GbGen::vaDefaults(lastEthType) 00ff
}
# ***************************************************************************
# LoopThePort
# ***************************************************************************
proc LoopThePort {activePort} {
  variable va10GbGenSetTmp 
  set freePortL [::RL10GbGen::GetFreeRcvPorts $activePort]
  set success 0
  foreach freePort $freePortL {
    ## chassis:1.Port:3 - 10G -> chassis:1.Port:3
    set fp [string trim [lindex [split $freePort - ] 0]]
    # puts "LoopThePort activePort:$activePort fp:$fp freePort:$freePort"
    if {$activePort==$fp} {
      set ::RL10GbGen::va10GbGenSetTmp($activePort.RcvPort) [lindex $freePortL [lsearch $freePortL $freePort] ]
      SetTxPort $activePort
      set success 1
      break
    }
  }
  # puts "LoopThePort activePort:$activePort fp:$fp freePort:$freePort success:$success"
  if {$success==0} {
    foreach na [array names ::RL10GbGen::va10GbGenSetTmp [set activePort]*.TxP*] {
      # puts "LoopThePort activePort:$activePort na:$na"
      set txp $::RL10GbGen::va10GbGenSetTmp($na)
      tk_messageBox -title "Receive Port Alert" -type ok -message "Port is already occupied by \'$txp\'"
    }
  }
  return {} 
}
# ***************************************************************************
# InsPsik
# ***************************************************************************
proc InsPsik {m} {
  # return $m
  if [string match *e* $m] {
    # # don't do it for 1.434+e12 numbers
    return $m
  } 
  set ns ""
  for {set i 0} {$i<[string length $m]} {incr i} {
    set strLen [string length $m]
    set tail [expr {$strLen - $i - 1}]
    set indx [expr {$strLen-$tail}]
    set ch [string index $m $tail ]
    # puts "i:$i ch:$ch tail:$tail strLen:$strLen indx:$indx" 
    if {([expr {$indx%3}]!=0) || ([expr {$indx%3}]==0 && $tail==0)} {
      append ns $ch
      # puts "-ns:$ns"
    } elseif {[expr {$indx%3}]==0 && $tail!=0} {
      # puts "--i:$i [string index $m $tail ] tail:$tail strLen:$strLen indx:$indx"  
      append ns "$ch,"
      # puts "--ns:$ns"
    }    
  }
  # puts "ns:$ns"
  for {set i 0} {$i<[string length $ns]} {incr i} {
    set strLen [string length $ns]
    set tail [expr {$strLen - $i - 1}]
    # set indx [expr {$strLen-$tail}]
    set ch [string index $ns $tail ]
    append nm $ch
  }
  return $nm
  # ::RL10GbGen::
}
# ***************************************************************************
# BigNum
# ***************************************************************************
proc BigNum {aa oper bb} {
  set aa [format %f $aa]
  set bb [format %f $bb]
  set cc [expr [list $aa $oper $bb]]
  if {[string range $cc end-1 end]==".0"} {
    set cc [string range $cc 0 end-2]
  }
  return $cc
  # puts "BigNum $aa $oper $bb"
  # global gaEthSet
  switch -exact -- $oper {
    + {set func add}
    * {set func mul}
    - {set func sub}  
    / - : {set func div}  
    % {set func rem}
    default {set func $oper}
  }
#   if {$gaEthSet(putsBigNum)==1} {
#     puts "BigNum aa:$aa oper:$oper func:$func bb:$bb"
#   }
  set a   [::math::bignum::fromstr $aa]
  set b   [::math::bignum::fromstr $bb]
  set c   [::math::bignum::$func $a $b]
  set res [::math::bignum::tostr $c]
  return $res
  # ::RL10GbGen::
} 
# ***************************************************************************
# BigFloat
# ***************************************************************************
proc BigFloat {aa oper bb} {
  # global gaEthSet
  switch -exact -- $oper {
    + {set func add}
    * {set func mul}
    - {set func sub}  
    / - : {set func div}  
    % {set func rem}
    default {set func $oper}
  }
  set a    [::math::bigfloat::fromstr $aa]
  if [::math::bigfloat::isFloat $a] {
    set a  [::math::bigfloat::fromstr $aa 15]
  } else {
    set a  [::math::bigfloat::fromstr $aa.0 15]
  }
  set b    [::math::bigfloat::fromstr $bb]
  if [::math::bigfloat::isFloat $b] {
    set b  [::math::bigfloat::fromstr $bb 15]
  } else {
    set b  [::math::bigfloat::fromstr $bb.0 15]
  }
  set c    [::math::bigfloat::$func $a $b]
  set res  [::math::bigfloat::tostr $c]
  scan $res %g res
#   if {$gaEthSet(putsBigNum)==1} {
#     puts "BigFloat aa:$aa oper:$oper func:$func bb:$bb res:$res"
#   }
  return $res
  # ::RL10GbGen::
} 


# ***************************************************************************
# GlobalSanityCheck
# ***************************************************************************
proc GlobalSanityCheck {} {
  foreach {wn min max mes} {PacketSizeMin 64 1999 "MIN packet size" \
                            PacketSizeMax 65 2000 "MAX packet size" \
                            IPG 8 31 "IPG" \
                            SeqErThr 0 128 "Sequence error threshold"} {
    set val [$::RL10GbGen::va10GbGenGui($wn) get]  
    if {$val<$min || $val>$max} {
      if {$::RL10GbGen::g10GbGenBufferDebug} {
        puts "wn:$wn"
      }  
      $::RL10GbGen::va10GbGenGui($wn) selection range 0 end
      tk_messageBox -message "The \'$mes\' should be between $min and $max"\
          -title "Wrong $mes"
      focus -force $::RL10GbGen::va10GbGenGui($wn)
      return 0
    }                        
  }
  
  return 1 
  # ::RL10GbGen::
}
# ***************************************************************************
# CaptureConsole
# ***************************************************************************
proc CaptureConsole {n} {
  global gaEthSet
  if {$n==""} {set n c:/}
  set host [info host]
  # puts "CaptureConsole n:_${n}_ host:_${host}_"
  console eval "set n $n"
  console eval "set host $host"
  console eval { 
    catch {
      set w .console
      set fi [set n]/Console_[set host]_[clock format [clock seconds] -format "%Y%m%d_%H%M"].txt
      # puts "CaptureConsole fi:_${fi}_"
      set aa [.console get 1.0 end]
      set id [open $fi w+]
      puts $id $aa
      close $id
    }
  }
  ##::RL10GbGen::
}

# ***************************************************************************
# CalcRunTime
# ***************************************************************************
proc CalcRunTime {startSec} {
  set runSec [::RL10GbGen::BigNum [clock seconds] - $startSec ]
  set runInDay [clock format $runSec -format %T -gmt 1]
  # second in a day is 86400
  set runDay [expr int([::RL10GbGen::BigNum $runSec / 86400]) ]
  set RunTime "$runDay.$runInDay"
  return $RunTime
  #### ::RL10GbGen::
}
# ***************************************************************************
# ToogleAllStreamsEnable
#
#  ToogleAllStreamsEnable 1
#  ToogleAllStreamsEnable 0
# ***************************************************************************
proc ToogleAllStreamsEnable {} {
  if ![info exists ::RL10GbGen::va10GbGenSet(confStreamEnDisMode)] {
    set ::RL10GbGen::va10GbGenSet(confStreamEnDisMode) -
  }
  if {$::RL10GbGen::va10GbGenSet(confStreamEnDisMode)=="1"} {
    set mode 0
    set ico port1.ico
  } elseif {$::RL10GbGen::va10GbGenSet(confStreamEnDisMode)=="0"} {
    set mode 1
    set ico port2.ico
  } elseif {$::RL10GbGen::va10GbGenSet(confStreamEnDisMode)=="-"} {
    set mode 1
    set ico port2.ico
  }
  set ::RL10GbGen::va10GbGenSet(confStreamEnDisMode) $mode
  
  set portL [::RL10GbGen::GetEnabledPorts configured]
  foreach activePort $portL {
    set stream_id [expr {[lindex [split [lindex [split $activePort .] 1] :] 1] - 1}]
    set chassis [lindex [split [lindex [split $activePort .] 0] :] 1]   
    set po      [lindex [split [lindex [split $activePort .] 1] :] 1]   
    set id $::RL10GbGen::va10GbGenStatuses($chassis,10GbGenID)
    if {$::RL10GbGen::va10GbGenSet($id.$stream_id.activity)!="run"} {    
      set ::RL10GbGen::va10GbGenSet($activePort.StreamEnable) $mode
      $::RL10GbGen::va10GbGenGui(resources,list) itemconfigure $activePort -image [image create photo -file $::RL10GbGen::va10GbGenSet(rundir)/images/$ico]
    }
  }
  ::RL10GbGen::UpdateChassisLineRate
}
# ***************************************************************************
# DeleteConfiguredStreams
# ***************************************************************************
proc DeleteConfiguredStreams {} {
  set tree $::RL10GbGen::va10GbGenGui(resources,list)
  set portL [::RL10GbGen::GetEnabledPorts configured]
  foreach activePort $portL {
    set stream_id [expr {[lindex [split [lindex [split $activePort .] 1] :] 1] - 1}]
    set chassis [lindex [split [lindex [split $activePort .] 0] :] 1]   
    set po      [lindex [split [lindex [split $activePort .] 1] :] 1]   
    set id $::RL10GbGen::va10GbGenStatuses($chassis,10GbGenID)
    if {$::RL10GbGen::va10GbGenSet($id.$stream_id.activity)!="run"} {    
      set ::RL10GbGen::va10GbGenSet($activePort.process) "notConfigured"
      $tree itemconfigure $activePort -text "[string trim [lindex [split [$tree itemcget $activePort -text] < ] 0]]"    
      $tree itemconfigure $activePort -image [image create photo -file $::RL10GbGen::va10GbGenSet(rundir)/images/port1.ico]
      set ::RL10GbGen::va10GbGenSet($activePort.StreamEnable) 0
      set ::RL10GbGen::va10GbGenSet($activePort.RcvPort) "NC"
      
      
      switch -exact -- $po {
        1 - 2 - 3 - 4 {set ps 10G}
        5 - 6 - 7 - 8 {set ps 1G}
      }
      SetStream2Default $id $chassis $po $ps
      ::RL10GbGen::UpdateChassisLineRate
    }
  }
}


# ***************************************************************************
# RandomPatternByte
# ***************************************************************************
proc RandomPatternByte {} {
  ##  ::RL10GbGen::RandomPatternByte
  return [format %.2X [expr round ([expr {[expr rand()]*255}])]]
}

# Make10GbGenGui
# package require RLEH
# RLEH::Open
} ;# end namespace
