#  console show
#===============================================================
#
#  FileName:   RLTime.tcl
#
#  Written by: Ohad / 24.3.1999
#              Added by Ilana
#														Added by Semion CviDelay,CviDelayms,CviDelayn
#
#  Abstract:   This file contains procedures regarding time. 
#              Delay proc. and Time/Date proc.
#
#  Procedures:    - Delay
#                 - Delayn
#                 - Delayms
#                 - TimeDate
#									-	CviDelay
#									-	CviDelayms
#									-	CviDelayn
#									- Update
#					   			- Checkdate
#						
#===============================================================

package require  RLDTime 2.0
package require  RLFile 1.0
package require RLEH 1.02
package provide RLTime 3.0

namespace eval RLTime {

  namespace export Delay Delayn Delayms CviDelay CviDelayn CviDelayms TimeDate Update CheckDate
  
  
  #***************************************************************
  #** Delay
  #**
  #** Abstract: Creates a delay for the specified time in seconds.
  #**
  #** Inputs: 'ip_timeSec' time in sec.
  #**
  #** Outputs:
  #**
  #** Usage:  RLTime::Delay 3
  #**
  #***************************************************************

  proc Delay { ip_timeSec } {
    set x 0
    after [ expr { $ip_timeSec * 1000 }] { set x 1 }
    vwait x
  }

  #***************************************************************
  #** CviDelay
  #**
  #** Abstract: Creates a delay for the specified time in seconds by CVI DLL Level.
  #**
  #** Inputs: 'ip_timeSec' time in sec.
  #**
  #** Outputs:	0    if success
  #**
  #** Usage:  RLTime::CviDelay 3
  #**
  #***************************************************************

  proc CviDelay { ip_timeSec } {
    # global (import)
    global ERRMSG
    #Message to be send to EH 
    global gMessage

    set ok           0

    if {[set err [ RLDLLCviDelay $ip_timeSec]]}   {
      set gMessage $ERRMSG
      append gMessage "\nERROR while CviDelay."
      return [RLEH::Handle SAsystem gMessage]
    }
    return $ok
  }


  #***************************************************************
  #** Delayn
  #**
  #** Abstract: Displays the delay time specified, with a message attached.
  #**
  #** Inputs: 'ip_timeSec' time in sec, 'ip_message' message to display
  #**         (default message = empty string).
  #**
  #** Outputs:
  #**
  #** Usage:  RLTime::Delayn 3 "string"
  #**         RLTime::Delayn 3
  #**
  #***************************************************************

  proc Delayn {ip_timeSec {ip_message ""}} {

    global timeToDisplay

    set timeToDisplay $ip_timeSec
    toplevel .wait
    wm focusmodel .wait passive
    wm geometry .wait +20+400
    message .wait.t -aspect 1500 -text "$ip_message" -foreground blue \
    -font {{Courier New} 16 bold}
    pack .wait.t
    message .wait.m -textvariable timeToDisplay -foreground red \
    -font {{Courier New} 22 bold}
    pack .wait.m
    for {} {$timeToDisplay} {incr timeToDisplay -1} {
  
      global timeToDisplay
  
      Delay 1
    }
    destroy .wait
  }

  #***************************************************************
  #** CviDelayn
  #**
  #** Abstract: Displays the delay time specified, with a message attached.
  #**
  #** Inputs: 'ip_timeSec' time in sec, 'ip_message' message to display
  #**         (default message = empty string).
  #**
  #** Outputs:
  #**
  #** Usage:  RLTime::CviDelayn 3 "string"
  #**         RLTime::CviDelayn 3
  #**
  #***************************************************************

  proc CviDelayn {ip_timeSec {ip_message ""}} {

    global timeToDisplay

    set timeToDisplay $ip_timeSec
    toplevel .wait
    wm focusmodel .wait passive
    wm geometry .wait +20+400
    message .wait.t -aspect 1500 -text "$ip_message" -foreground blue \
    -font {{Courier New} 16 bold}
    pack .wait.t
    message .wait.m -textvariable timeToDisplay -foreground red \
    -font {{Courier New} 22 bold}
    pack .wait.m
				update
    for {} {$timeToDisplay} {incr timeToDisplay -1} {
      global timeToDisplay
  		  if ![winfo exists .wait] {
							 return
						}
  				update
      CviDelay 1
    }
    destroy .wait
  }


  #***************************************************************
  #** Delayms
  #**
  #** Abstract: Creates a delay for the specified time in miliseconds.
  #**
  #** Inputs: 'ip_timeSec' time in milisec.
  #**
  #** Outputs:
  #**
  #** Usage:  RLTime::Delayms 500 (for a 0.5 sec dalay)
  #**
  #***************************************************************

  proc Delayms { ip_timeSec } {
    set x 0
    after $ip_timeSec { set x 1 }
    vwait x
  }


  #***************************************************************
  #** CviDelayms
  #**
  #** Abstract: Creates a delay for the specified time in milliseconds by CVI DLL Level.
  #**
  #** Inputs: 'ip_timeMlsec' time in sec.
  #**
  #** Outputs:	0    if success
  #**
  #** Usage:  RLTime::CviDelayms 3
  #**
  #***************************************************************

  proc CviDelayms { ip_timeMlsec } {
    # global (import) 
    global ERRMSG
    #Message to be send to EH 
    global gMessage

    set ok           0

    if {[set err [ RLDLLCviDelayms $ip_timeMlsec]]}   {
      set gMessage $ERRMSG
      append gMessage "\nERROR while CviDelayms."
      return [RLEH::Handle SAsystem gMessage]
    }
    return $ok
  }


  #***************************************************************
  #** TimeDate
  #**
  #** Abstract: Reading time and Date from CPU clock.
  #**
  #** Inputs: 
  #**
  #** Outputs: Return the current Time/Date in the format: 08:38:15 <06/01/1999>
  #** 
  #** Usage: RLTime::TimeDate
  #**
  #***************************************************************
  proc TimeDate {} {  
   
     set clkTime [clock format [clock seconds] -format %H:%M:%S]
     set clkDate [clock format [clock seconds] -format %d/%m/%Y]
     set timeDate "$clkTime  <$clkDate>"

     return $timeDate
  }


  #***************************************************************
  #** Update
  #**
  #** Abstract: Updates the time and date of Common Logic .
  #**
  #** Inputs: ip_time_date	  == the time and date from Common Logic .
  #**
  #** Outputs: return the update parameters as list 
  #**          for exemple : year {f 7} day {f 5} month {f 0} hour {f 3} minute {f 4}
  #**
  #** Usage: RLTime::Update "Current Date : Wed 18-04-2001  Current Time : 14:19:18" 
  #**		 
  #***************************************************************

   proc Update { ip_time_date } {
		global gMessage
		set gMessage " "
	
		set day_cl ""
		set month_cl "" 
		set year_cl "" 
		set hour_cl ""
		set minute_cl ""
	
		set num_count 0 

   	for { set string_length 0 } { $string_length <= [ expr [ string length $ip_time_date ] - 1 ] } { incr string_length } {
			set var [ string index $ip_time_date $string_length ]
	
			if { $var <= 9 && $var >= 0 } {
				incr num_count
																			
				#bring the day from string
				if { $num_count <= 2 } {
					append day_cl $var
				
				#bring the month from string
				} elseif { $num_count > 2 && $num_count <= 4 } {
					append month_cl $var
				
				#bring the year from string
				} elseif { $num_count > 4 && $num_count <= 8 } {
					append year_cl $var

				#bring the hour from string
				} elseif { $num_count > 8 && $num_count <= 10 } {
					append hour_cl $var
				
				#bring the minute from string
				} elseif { $num_count > 10 && $num_count <= 12 } {
					append minute_cl $var
				}
			}
		}
	
		if { [ string index $day_cl 0 ] == 0 } { set day_cl [ string index $day_cl 1 ] }
		if { [ string index $month_cl 0 ] == 0 } { set month_cl [ string index $month_cl 1 ] }
		if { [ string index $hour_cl 0 ] == 0 } { set hour_cl [ string index $hour_cl 1 ] }
		if { [ string index $minute_cl 0 ] == 0 } { set minute_cl [ string index $minute_cl 1 ] }


   	# Getting variables : the Date and Time from PC 
		set hour_pc [format "%g" [clock format [clock seconds] -format %H]]
		set minute_pc [format "%g" [clock format [clock seconds] -format %M]]
		set day_pc [format "%g" [clock format [clock seconds] -format %e]]
		set month_pc [format "%g" [clock format [clock seconds] -format %m]]
		set year_pc [format "%g" [clock format [clock seconds] -format %Y]]

      # Updating the Hour
		set hour_updt [expr $hour_pc - $hour_cl]
		if {$hour_updt == 0} {
  			set h_updt "f 0"
		} elseif {$hour_updt < 0 & [expr abs ($hour_updt)] > 12} {
			set h_updt "f [expr 24-abs ($hour_updt)]"
		} elseif {$hour_updt < 0 & [expr abs ($hour_updt)] <= 12} {
			set h_updt "b [expr abs ($hour_updt)]"  	
 		} elseif {$hour_updt > 0 & $hour_updt > 12} {
			set h_updt "b [expr 24-$hour_updt]"
		} elseif {$hour_updt > 0 & $hour_updt <= 12} {
			set h_updt "f $hour_updt"  	
		}
		
 		# Updating the Minutes
		set minute_updt [expr $minute_pc - $minute_cl]
		if {$minute_updt == 0} {
  			set min_updt "f 0"
		} elseif {$minute_updt < 0 & [expr abs ($minute_updt)] > 30} {
			set min_updt "f [expr 60-abs ($minute_updt)]"
		} elseif {$minute_updt < 0 & [expr abs ($minute_updt)] <= 30} {
			set min_updt "b [expr abs ($minute_updt)]"  	
 		} elseif {$minute_updt > 0 & $minute_updt > 30} {
			set min_updt "b [expr 60-$minute_updt]"
		} elseif {$minute_updt > 0 & $minute_updt <= 30} {
			set min_updt "f $minute_updt"  	
		}
		
  		# Updating the Day
		set day_updt [expr $day_pc - $day_cl]
		if {$day_updt == 0} {
  			set d_updt "f 0"
		} elseif {$day_updt < 0} {
			set d_updt "b [expr abs ($day_updt)]"
		} elseif {$day_updt > 0} {
			set d_updt "f $day_updt"  	
		}
		
 		# Updating the Month
		set month_updt [expr $month_pc - $month_cl]
		if {$month_updt == 0} {
  			set mon_updt "f 0"
		} elseif {$month_updt < 0} {
			set mon_updt "b [expr abs ($month_updt)]"
		} elseif {$month_updt > 0} {
			set mon_updt "f $month_updt"  	
		}
		
 		# Updating the Year
		set year_updt [expr $year_pc - $year_cl]
		if {$year_updt == 0} {
  			set y_updt "f 0"
		} elseif {$year_updt < 0} {
			set y_updt "b [expr abs ($year_updt)]"
		} elseif {$year_updt > 0} {
			set y_updt "f $year_updt"  	
		}

		# Setting the update parameters to Array
		set updt(minute) $min_updt
		set updt(hour) $h_updt
		set updt(month) $mon_updt
		set updt(day) $d_updt
		set updt(year) $y_updt
		
		return [ array get updt ]
  	}

  #**************************************************************
  #** CheckDate
  #**
  #** Abstract: Compare the time and date of Common Logic with time and date of PC.
  #**
  #** Inputs:  ip_minuteError == the permissible error of minutes (default == +_ 10 minutes)
  #**			   ip_time_date	== the time and date from Common Logic .
  #**
  #** Outputs:
  #**
  #** Usage: RLTime::CheckDate "Current Date : Wed 18-04-2001  Current Time : 14:19:18" 5  
  #**		 
  #**************************************************************
	
  proc CheckDate { ip_time_date { ip_minuteError 10 } } {
	 	
  	   global gMessage
		set gMessage " "
		
		set day_cl ""
		set month_cl "" 
		set year_cl "" 
		set hour_cl ""
		set minute_cl ""
	
		set num_count 0 

   	for { set string_length 0 } { $string_length <= [ expr [ string length $ip_time_date ] - 1 ] } { incr string_length } {
			set var [ string index $ip_time_date $string_length ]
	
			if { $var <= 9 && $var >= 0 } {
				incr num_count
																			
				#bring the day from string (ip_time_date)
				if { $num_count <= 2 } {
					append day_cl $var
				
				#bring the month from string (ip_time_date)
				} elseif { $num_count > 2 && $num_count <= 4 } {
					append month_cl $var
				
				#bring the year from string (ip_time_date)
				} elseif { $num_count > 4 && $num_count <= 8 } {
					append year_cl $var

				#bring the hour from string (ip_time_date)
				} elseif { $num_count > 8 && $num_count <= 10 } {
					append hour_cl $var
				
				#bring the minute from string (ip_time_date)
				} elseif { $num_count > 10 && $num_count <= 12 } {
					append minute_cl $var
				}
			}
		}
	
		if { [ string index $day_cl 0 ] == 0 } { set day_cl [ string index $day_cl 1 ] }
		if { [ string index $month_cl 0 ] == 0 } { set month_cl [ string index $month_cl 1 ] }
		if { [ string index $hour_cl 0 ] == 0 } { set hour_cl [ string index $hour_cl 1 ] }
		if { [ string index $minute_cl 0 ] == 0 } { set minute_cl [ string index $minute_cl 1 ] }

  		# Getting variables : the date and time from PC 
		set hour_pc [format "%g" [clock format [clock seconds] -format %H]]
		set minute_pc [format "%g" [clock format [clock seconds] -format %M]]
		set day_pc [format "%g" [clock format [clock seconds] -format %e]]
		set month_pc [format "%g" [clock format [clock seconds] -format %m]]
		set year_pc [format "%g" [clock format [clock seconds] -format %Y]]

  		#Comparison 
		set time_updt [expr $hour_pc*60 + $minute_pc - $hour_cl*60 - $minute_cl]
		set year_updt [expr $year_pc - $year_cl]
		set month_updt [expr $month_pc - $month_cl]
		set day_updt [expr $day_pc - $day_cl]
	   if { $year_updt == 0 \
			&& $month_updt ==0 \
			&& $day_updt == 0 \
			&& [expr abs ($time_updt)] <= $ip_minuteError } {
			return 0
		} else {
			append gMessage " \nThe CheckDate faulse!!! \nThe time and date are not correct!!! "
			return -1
		}
	   return 0
   }
}


