
#===============================================================
#
#  NameSpace:   RLScreen
#
#  Abstract:    This namespace handle the TestScreen display options.  
#
#  Procedures:  -MainDisplay
#               -MajorTest
#               -MinorTest
#               -ScaleSet
#               -ScaleCreate
#               -TestPass
#               -TestFail
#               -Delayn                                                    
#               -ScreenDestroy
#               -Bar::Create
#               -Bar::Reset
#               -Bar::Step
#               -Bar::Destroy
#
#  Remark:      The gif files  'stop' 'Logorad' 'exit' should be in:
#					 ".../TclPro1.2/lib/Gif"
#
#===============================================================

package require RLEH 
package require RLFile 
package require Iwidgets              

package provide RLScreen 1.01

global gMessage
global env

namespace eval RLScreen {  

  namespace export  MainDisplay  MajorTest  MinorTest  ScaleCreate  ScaleSet
  namespace export  TestPass  TestFail  Delayn  ScreenDestroy

  #***************************************************************
  #** MainDisplay
  #**
  #** Abstract: creates the main display window and it's components.     
  #**
  #** Inputs:   ip_steps     number of steps to divide the Scale Bar.
  #**								  (number of major sub tests)
  #**
  #**			    ip_debug     when working in debug mode must specify 'debug'
  #**                        default is not debug mode
  #** Outputs:
  #**
  #** Usage:  RLScreen::MainDisplay 10 MHS-4
  #**         RLScreen::MainDisplay 10 MHS-4 debug
  #**
  #** Remarks: The cursor attribute in the main screen is the attribute
  #**          that is configured by windows. To change the attribute select:
  #**          "Start Menu - Settings - Control Panel - Mouse - Pointers"
  #**
  #***************************************************************

  proc MainDisplay { ip_steps ip_testerName {ip_debug 0} } {

    global gMessage
    global env

    variable gifPath

    set iniFile $env(windir)\\RLPath.ini
    # Geting the sound files directory path into variable "soundPath"
    if { [RLFile::Inigetitem $iniFile RadLab GifPath gifPath errMsg] != 0 } {
      set gMessage "Error while trying to get GifPath from ini file: $iniFile"
      RLEH::Handle System gMessage
      return -1
    }
	 
	 puts iniFile=$iniFile
	 puts gifPath=$gifPath

    toplevel .main1
    focus -force .main1
    wm title .main1 ""
    wm geometry .main1 792x600+0+0
    .main1 configure -borderwidth 20 -cursor wait   
    
	 Logo $ip_testerName
	 ScaleCreate $ip_steps    
    MajorTest ""
    MinorTest ""
    StartTime
  	 StopSign
    PauseButton
	 if { $ip_debug == "debug" } {
	   DebugMode
	 }
	 update
  }
      
  #***************************************************************
  #** StartTime
  #**
  #** Abstract: displays the starting time of the test in a lable 
  #**           inside the main window.     
  #**
  #***************************************************************

  proc StartTime {} {
    set startTime [clock format [clock seconds] -format "%H : %M"] 
    label .main1.startTime -text "Start Time    $startTime" -relief ridge \
    -width 15 -fg blue -pady 5 -padx 20
    pack .main1.startTime -pady 10
  }

  #***************************************************************
  #** EndTime
  #**
  #** Abstract: displays the Ending time of the test in a lable 
  #**           inside the main window.     
  #**
  #***************************************************************

  proc EndTime {} {
    set endTime [clock format [clock seconds] -format "%H : %M"] 
    label .main1.endTime -text "End Time    $endTime" -relief ridge \
    -width 15 -fg blue -pady 5 -padx 20
    pack .main1.endTime 
  } 

  #***************************************************************
  #** StopSign
  #**
  #** Abstract: displays a STOP sign in the main window to use in 
  #**           Emergency exit only, The button command is: "exit"     
  #**
  #***************************************************************
    
  proc StopSign {} {
    
    variable gifPath
    
	 image create photo stopSign -file $gifPath\\stop.gif
    
	 frame .main1.bottomFrame
    pack .main1.bottomFrame -side bottom -fill x
    
	 label .main1.bottomFrame.msg -text "Emergency\nuse\nonly!" -font {{Courier New} 10 } \
    -relief flat -fg red       
    
	 button .main1.bottomFrame.stop -image stopSign -bd 5 -cursor hand2 -relief raised \
	 -command {
	 destroy .main1
    exit }
    
	 pack .main1.bottomFrame.stop .main1.bottomFrame.msg -side left
  }  

  #***************************************************************
  #** PauseButton
  #**
  #** Abstract: displays a PAUSE button in the main window to use in 
  #**           order to pause the test. After presing pause the button
  #**           changes to "continue".    
  #**
  #***************************************************************
  
  proc PauseButton {} {
    
    frame .main1.barFrame -width 100 -height 75
	 pack .main1.barFrame -side bottom -fill x  
	 pack propagate .main1.barFrame false
	 
    button .main1.barFrame.pause -text "PAUSE" -width 5 -height 2 -relief raised -cursor hand2\
    -borderwidth 5 -fg blue -font {{Courier New} 12 bold} -command {
    if { [.main1.barFrame.pause cget -text] == "PAUSE" } {
      .main1.barFrame.pause configure -width 7 
	   .main1.barFrame.pause configure -text "PRESS\nTO\nCONTINUE" -fg red -bg yellow
	 } else {
        .main1.barFrame.pause configure -width 5
		  .main1.barFrame.pause configure -text "PAUSE" -fg blue -bg gray
      }
        
	 while { [.main1.barFrame.pause cget -text] != "PAUSE" } {
      set textInfo [.main1.barFrame.pause cget -text]
      switch $textInfo {
         "PRESS\nTO\nCONTINUE" { .main1.barFrame.pause configure -text "" }
         "" { .main1.barFrame.pause configure -text "PRESS\nTO\nCONTINUE" }
      }
      # the name of the variable MUST be unique in order to prevent errors
		# don't ever use the RLTime::Delay or the variable of it ('x')
		set flashingTheContinueButtonLabel 0
      after 1000 { set flashingTheContinueButtonLabel 1 }
      vwait flashingTheContinueButtonLabel
    }  
   } 
	pack .main1.barFrame.pause -side left 
  }
  
  #***************************************************************
  #** DebugMode
  #**
  #** Abstract: set a sign notifing that test is performed from
  #**           debug mode.    
  #**
  #***************************************************************
  
  proc DebugMode {} {

    global gMessage
  
    if { [winfo exists .main1.bottomFrame] == 1 } {	 
      label .main1.bottomFrame.debugMode -text "          Debug Mode" -font {{Courier New} 20 bold} -fg yellow
      pack .main1.bottomFrame.debugMode -side left
	 } else {
	     set gMessage "The Bottom Frame in Main window does not exist !!!"
        RLEH::Handle SAsystem gMessage
		}
  }
  
  #***************************************************************
  #** Logo
  #**
  #** Abstract: create the RAD logo and the Tester name.    
  #**
  #** Inputs:   ip_testerName  name of tester to display.
  #**
  #** Outputs:
  #**
  #** Usage:  RLScreen::Logo "HS-4"
  #**
  #***************************************************************
    
  proc Logo {ip_testerName} {
    
    variable gifPath
        
	 image create photo rad -file $gifPath\\Logorad.gif
	 
	 frame .main1.topFrame
	 pack .main1.topFrame -side top -fill x -pady 5
	 
	 label .main1.topFrame.logo1 -image rad 
	 label .main1.topFrame.logo2 -text $ip_testerName -font {{Courier New} 28 bold} -fg blue4
	 
	 pack .main1.topFrame.logo1 -side left
	 pack .main1.topFrame.logo2 -side right 
  }
    
  #***************************************************************
  #** MajorTest
  #**
  #** Abstract: create/change the Major test display line.     
  #**
  #** Inputs:   ip_text  text to be display in the Major test display line.
  #**
  #** Outputs:
  #**
  #** Usage:  RLScreen::MajorTest "Loop Test IO-1"
  #**
  #***************************************************************
    
  proc MajorTest {ip_text} {
    if { [winfo exists .main1.major] == 0 } {
      label .main1.major -text $ip_text -font {{Courier New} 16 bold} \
      -relief ridge -bd 5 -width 40 -bg blue -fg white       
      pack .main1.major -padx 30 -pady 20 -ipady 5
    } else {
        .main1.major configure -text $ip_text
        update
      }
  }

  #***************************************************************
  #** MinorTest
  #**
  #** Abstract: create/change the Minor test display line.     
  #**
  #** Inputs:   ip_text  text to be display in the Minor test display line.
  #**
  #** Outputs:
  #**
  #** Usage:  RLScreen::MinorTest "Testing Data Progress"
  #**
  #***************************************************************
    
  proc MinorTest {ip_text} {
    if { [winfo exists .main1.minor] == 0 } {
      label .main1.minor -text $ip_text -font {{Courier New} 12 bold} \
      -relief ridge -bd 5 -width 45 -bg blue -fg white        
      pack .main1.minor -padx 20 -ipady 5  
    } else {
        .main1.minor configure -text $ip_text
		  update
      }
  }

  #***************************************************************
  #** ScaleCreate
  #**
  #** Abstract: create the Scale Bar with the specified number of steps.     
  #**           or if it's exist only changes the number of steps.
  #**
  #** Inputs:   ip_steps  number of steps to configure the scale bar to.
  #**
  #** Outputs:
  #**
  #** Usage:  RLScreen::ScaleCreate 10
  #**
  #***************************************************************
    
  proc ScaleCreate {ip_steps} {
    if { [winfo exists .main1.scale] == 0 } {
      scale .main1.scale -from 0 -to $ip_steps \
      -length 700 -orient horizontal -tickinterval 1 -font {{Courier New} 10 bold}\
      -foreground blue -highlightbackground blue
      pack .main1.scale -side top
    } else {
        .main1.scale configure -to $ip_steps
        update
      }
  }
  
  #***************************************************************
  #** ScaleSet
  #**
  #** Abstract: set the Scale slider position to the specified step.     
  #**
  #** Inputs:   ip_sliderPosition  the step number to set the silder to.
  #**
  #** Outputs:
  #**
  #** Usage:  RLScreen::ScaleSet 3
  #**
  #***************************************************************
  
  proc ScaleSet {ip_sliderPosition} { 
    .main1.scale set $ip_sliderPosition 
  } 
 
  #***************************************************************
  #** TestPass
  #**
  #** Abstract: set the main window to a TEST PASS configuration.     
  #**
  #** Inputs:   
  #**
  #** Outputs:
  #**
  #** Usage:  RLScreen::TestPass
  #**
  #***************************************************************
    
  proc TestPass  {} {
    
    variable gifPath
      
    destroy .main1.barFrame  
    .main1 configure -cursor arrow 
	 .main1.major configure -text "***      !!!  TEST PASS  !!!      ***"  
    .main1.minor configure -text ""  
    set stop 0
    #exec passbeep
    EndTime
    .main1.major configure -bg green -fg blue
    .main1.minor configure -bg green -fg blue
    image create photo exitImage -file $gifPath\\exit.gif
   
    button .main1.end -image exitImage -bd 10 -relief raised -cursor hand2 -command {
      set stop 1
      destroy .main1
    }
    pack .main1.end -padx 20 -pady 20
  
    set textInfo "         !!!  TEST PASS  !!!         "  
    while { [winfo exists .main1.end] == 1 } {
      switch $textInfo {
        "***      !!!  TEST PASS  !!!      ***" { .main1.major configure -text "         !!!  TEST PASS  !!!         " }
        "         !!!  TEST PASS  !!!         " { .main1.major configure -text "***      !!!  TEST PASS  !!!      ***" }
      }												 
      set textInfo [.main1.major cget -text]
      set k 0
		after 1000 {set k 1}
		vwait k
    }  
  }

  #***************************************************************
  #** TestFail
  #**
  #** Abstract: set the main window to a TEST FAIL configuration.     
  #**
  #** Inputs:   
  #**
  #** Outputs:
  #**
  #** Usage:  RLScreen::TestFail
  #**
  #***************************************************************
    
  proc TestFail {} {
    
    variable gifPath
    
    destroy .main1.barFrame
    .main1 configure -cursor arrow 
	 .main1.major configure -text "** FAIL **  ** FAIL **  ** FAIL **"  
    .main1.minor configure -text ""  
    set stop 0
    #exec passbeep
    EndTime
    .main1.major configure -bg red -fg white
    .main1.minor configure -bg red -fg white
    image create photo exitImage -file $gifPath\\exit.gif
  
    button .main1.end -image exitImage -bd 10 -relief raised -cursor hand2 -command {
      set stop 1
      destroy .main1
      }
    pack .main1.end -padx 20 -pady 20
  
    set textInfo "            ** FAIL **            "  
    while { [winfo exists .main1.end] == 1 } {
      switch -exact -- $textInfo {
        "            ** FAIL **            " {.main1.major configure -text "** FAIL **              ** FAIL **"}
	     "** FAIL **              ** FAIL **" {.main1.major configure -text "            ** FAIL **            "}
      }
      set textInfo [.main1.major cget -text]
      set k 0
		after 1000 {set k 1}
		vwait k
    }  
  }

  #***************************************************************
  #** Delayn
  #**
  #** Abstract: create a delay for the specified time in seconds
  #**           and display the remaining time in the main window.     
  #**
  #** Inputs:   ip_timeSec  the delay time in seconds. 
  #**
  #** Outputs:
  #**
  #** Usage:  RLScreen::Delayn 15
  #**
  #***************************************************************
 
  proc Delayn {ip_timeSec} {
  
    global TimeLeft
  	 set TimeLeft $ip_timeSec
    
	 label .main1.bottomFrame.wait -text "Please Wait  - " -fg blue4 -font {{Courier New} 16 bold}
    message .main1.bottomFrame.sec -textvariable TimeLeft -fg blue4 -font {{Courier New} 16 bold}
    pack .main1.bottomFrame.sec .main1.bottomFrame.wait -side right
    
	 for {} {$TimeLeft} {incr TimeLeft -1} {
      global TimeLeft
      set k 0
		after 1000 {set k 1}
		vwait k
    }
    destroy .main1.bottomFrame.sec 
    destroy .main1.bottomFrame.wait
  }

  #***************************************************************
  #** ScreenDestroy
  #**
  #** Abstract: destroys the main screen display. not the menubar    
  #**
  #***************************************************************

  proc ScreenDestroy {} {

    destroy .main1
  } 
#===============================================================
#  NameSpace:   Bar
#
#  Abstract:    This namespace handle the progress bar procedures.  
#					 (works from inside 'RLScreen' namespace)
#
#  Procedures:  -Create
#               -Reset
#               -Step 
#               -Destroy
#
#===============================================================

namespace eval Bar {  

  namespace export Create Reset Step Destroy

  #***************************************************************
  #** Create
  #**
  #** Abstract: creates a progress bar     
  #**
  #** Inputs:   ip_headline  headline to display while working
  #**           ip_steps     number of steps to divide the bar
  #**
  #** Outputs:
  #**
  #** Usage:  RLScreen::Bar::Create "FB Init" 35
  #**
  #***************************************************************
  
  proc Create { ip_headline ip_steps} {  
    
    global gMessage
  
    if { [winfo exists .main1] == 1 } {
  	   destroy .main1.barFrame.f1
	   
	   frame .main1.barFrame.f1 -bd 2 -relief ridge -bg yellow -width 300 -height 75
	   pack .main1.barFrame.f1 -side right	 
	   pack propagate .main1.barFrame.f1 false
	 	
		iwidgets::feedback .main1.barFrame.f1.fb -labeltext $ip_headline -steps $ip_steps
	   pack .main1.barFrame.f1.fb -fill x
	   update
 	 } else {
        set gMessage "The Main window does not exist !!!"
        RLEH::Handle SAsystem gMessage
		}
  }
    
  #***************************************************************
  #** Reset
  #**
  #** Abstract: resets the progress bar     
  #**
  #** Inputs:   
  #**
  #** Outputs:
  #**
  #** Usage:  RLScreen::Bar::Reset
  #**
  #***************************************************************
  
  proc Reset {} {
   
    global gMessage
  
    if { [winfo exists .main1.barFrame.f1.fb] == 0 } {
      set gMessage "Progress Bar don't exist !!!"
      RLEH::Handle SAsystem gMessage
    } else {
        .main1.barFrame.f1.fb reset
      }  
  }

  #***************************************************************
  #** Step
  #**
  #** Abstract: forwords the bar one step     
  #**
  #** Inputs:   
  #**
  #** Outputs:
  #**
  #** Usage:  RLScreen::Bar::Step
  #**
  #***************************************************************
  
  proc Step {} {
  
    global gMessage
  
    if { [winfo exists .main1.barFrame.f1.fb] == 0 } {
      set gMessage "Progress Bar don't exist !!!"
      RLEH::Handle SAsystem gMessage
    } else {
        .main1.barFrame.f1.fb step
      }  
  }
    
  #***************************************************************
  #** Destroy
  #**					  
  #** Abstract: destroys the progress bar     
  #**
  #** Inputs:   
  #**
  #** Outputs:
  #**
  #** Usage:  RLScreen::Bar::Destroy
  #**
  #***************************************************************
  
  proc Destroy {} {

    destroy .main1.barFrame.f1
  }  
}
}

