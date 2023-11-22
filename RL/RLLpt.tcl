load lpttcl

namespace eval RLLpt {

  namespace export SetLpt SetBit ClrBit GetLpt GetBit SetPort GetPort
	
	
	proc SetLpt {ip_Byte} {
		lpt_wrdata $ip_Byte
	}

	proc SetBit {ip_Bit} {
		set mult [expr pow(2,$ip_Bit)]
		set mult [expr round($mult)]
		lpt_wrdata [expr [lpt_rddata] | $mult]
	}

	proc ClrBit {ip_Bit} {
		set mult [expr pow(2,$ip_Bit)]
		set mult [expr round($mult)]
		set mult [expr ~ $mult]
		lpt_wrdata [expr [lpt_rddata] & $mult]
	}

	proc GetLpt {} {
		return [lpt_rddata]
	}

	proc GetBit {ip_Bit} {
		set mult [expr pow(2,$ip_Bit)]
		set mult [expr round($mult)]
		set calc [expr [lpt_rddata] & $mult]
		if {$calc==$mult} {
			return 1
			} else {
				return 0
			}
	}
	
  # ip_Lpt = LPT ID    1 = LPT1 2=LPT2 3=LPT3 ...
	proc SetPort {ip_Lpt} {
	 return [lpt_setport $ip_Lpt]
  }
  
  # return LPT ID      1 = LPT1 2=LPT2 3=LPT3 ...
  proc GetPort {} {
	 return [lpt_getport]
  }

}

package provide RLLpt 1.0

