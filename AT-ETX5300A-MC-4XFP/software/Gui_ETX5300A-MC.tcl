proc GUI {} {
  global gaSet gaGui glTests  
  wm title . "$gaSet(tester) : ETX-5300A-MC/4XFP"
  wm protocol . WM_DELETE_WINDOW {Quit}
  wm geometry . $gaGui(xy)
  wm resizable . 0 0
  set descmenu {
    "&File" all file 0 {	 
      {command "Log File"  {} {} {} -command ShowLog}
	    {separator}     
      {cascad "&Console" {} console 0 {
        {checkbutton "console show" {} "Console Show" {} -command "console show" -variable gConsole}  
        {command "Capture Console" cc "Capture Console" {} -command CaptureConsole}
        {command "Find Console" console "Find Console" {} -command {GuiFindConsole}}          
      }
      }
      {separator}
      {command "COMs mapping" init "" {} -command "ShowComs"}
      {separator}
      {command "History" History "" {} \
         -command {
           set cmd [list exec "C:\\Program\ Files\\Internet\ Explorer\\iexplore.exe" [pwd]\\history.html &]
           eval $cmd
         }
      }
      {separator}
      {command "Update INIT and UserDefault files on all the Testers" {} "Exit" {} -command {UpdateInitsToTesters}}
      {separator}
      {command "E&xit" exit "Exit" {Alt x} -command {Quit}}		
    }
    "&Tester Tools" tools tools 0 {	  
      {command "Inventory" init {} {} -command {GuiInventory}}	
      {separator}                   	
      {cascad "Page Setup" {} "Page Setup" 0 {
        {radiobutton "Barcode only" {} "Barcode only" {} -command {} -value BarcodeOnly -variable gaSet(PageSetupType)}
        {radiobutton "All Pages with Barcode" {} "All Pages  Barcode" {} \
            -command {
              DialogBox -title "PAGES Download" -type OK \
                  -message "Verify the $gaSet(pageFile) file is updated"\
                  -icon [pwd]/images/question.ico
            } \
            -value AllPagesWithBarcode -variable gaSet(PageSetupType)}
      }
      } 
      {command "Page File Setup" {} "Page File Setup" {} -command {Gui_Page_Setup .pageSetup}}
      {separator}		
      {command "One test" init {} {} -command {set gaSet(oneTest) 1}}
      {command "Break a Wait" init {} {} -command {WaitBreak}}
      {separator}	
      {command "E-mail Setting" gaGui(ToolAdd) {} {} -command {GuiEmail .mail}} 
		  {command "E-mail Test" gaGui(ToolAdd) {} {} -command {TestEmail}} 
      {separator}		
      {command "IPRelay IP Address" {} "IPRelay IP Address" {} -command {GuiIPRelay}}
      {separator}
      {command "Open tmpDir" "" "" {} -command {exec explorer.exe [file nativename c:\\tmpDir] &}}
      {separator}   
      {cascad "UUT-REF" {} "UUT-REF" 0 {
        {radiobutton "Chassis-1 UUT, Chassis-2 UUT" {} "Chassis-1 UUT, Chassis-2 UUT" {} -command {BuildTests} -value UUTUUT -variable gaSet(UUTREF)}
        {radiobutton "Chassis-1 UUT, Chassis-2 REF" {} "Chassis-1 UUT, Chassis-2 REF" {} -command {BuildTests} -value UUTREF -variable gaSet(UUTREF)}
        {radiobutton "Chassis-1 REF, Chassis-2 UUT" {} "Chassis-1 REF, Chassis-2 UUT" {} -command {BuildTests} -value REFUUT -variable gaSet(UUTREF)}
      }
      }                   
    }
    "&UUT Tools" tools tools 0 {	  
      {command "PS-1 and PS-2 ON" {} "PS-1 and PS-2 ON" {} -command {ToolPower "1 2" on}}  
      {command "PS-1 and PS-2 OFF" {} "PS-1 and PS-2 OFF" {} -command {ToolPower "1 2" off}} 
      {command "PS-1 ON" {} "PS-1 ON" {} -command {ToolPower 1 on}}  
      {command "PS-1 OFF" {} "PS-1 OFF" {} -command {ToolPower 1 off}} 
      {command "PS-2 ON" {} "PS-2 ON" {} -command {ToolPower 2 on}} 
      {command "PS-2 OFF" {} "PS-2 OFF" {} -command {ToolPower 2 off}} 
      {separator}	
      {command "Slots reset" init {} {} -command {IoCardsResetTool}}      
      {command "Slots shutdown-no shutdown" init {} {} -command {SlotsStateTool}}
      {command "Manual Switch" init {} {} -command {ManualSwitchTool}}    
      {command "Clear Alarms" init {} {} -command {ClearAlarmTool}}
      {command "Read Alarms" init {} {} -command {ReadAlarmsTool}}                     
    }
    "&Terminal" terminal tterminal 0  {
      {command "Chassis-1 MC-A"    "" "" {} -command {OpenTeraTerm gaSet(comMC.1.1)}}
      {command "Chassis-1 MC-B"    "" "" {} -command {OpenTeraTerm gaSet(comMC.1.2)}}
      {command "Chassis-1 DaviCOM" "" "" {} -command {OpenTeraTerm gaSet(comMC.1.d)}}
      {command "Chassis-2 MC-A"    "" "" {} -command {OpenTeraTerm gaSet(comMC.2.1)}}
      {command "Chassis-2 MC-B"    "" "" {} -command {OpenTeraTerm gaSet(comMC.2.2)}}
      {command "Chassis-2 DaviCOM" "" "" {} -command {OpenTeraTerm gaSet(comMC.2.d)}}
      {command "DXC4" "" "" {} -command {OpenTeraTerm gaSet(comDXC)}} 
      {command "GEN" "" "" {} -command {OpenTeraTerm gaSet(com220)}}      
    }
    "Files" all about 0 {
      {command "Open the project folders" "" "" {} \
          -command {
           exec explorer.exe \\\\prod-svm1\\tds\\Temp\\ilya\\shared\\ETX5300A-MC-4XFP &
           exec explorer.exe [ file nativename [ file dirname [pwd]]] &
         } 
      }
    }
    "&About" all about 0 {
      {command "&About" about "" {} -command {About} 
      }
    }
  }
   #{command "Page Setup" {} "Page Setup" {} -command {Gui_Page_Setup .pageSetup}} 
   #{command "SW init" init {} {} -command {GuiSwInit}}	
   #{command "Init EtxGen" init {} {} -command {InitEtxGen}}
   #{radiobutton "Stop on Failure" {} "" {} -value 1 -variable gaSet(stopFail)}
   #{separator}
   #{command "Init DXC" init {} {} -command {InitDXC}}      
   #{separator}
   #{separator}
   #{radiobutton "Use exist Barcodes" init {} {} -command {} -variable gaSet(useExistBarcode) -value 1}
              
		  

  set mainframe [MainFrame .mainframe -menu $descmenu]
  #set gaSet(sstatus) [$mainframe addindicator]  
  #$gaSet(sstatus) configure -width 70 
  #set gaGui(ls2) [$mainframe addindicator]
  #UpdateDlsFields
  #$gaGui(ls2) configure -text $txt
  set gaSet(startTime) [$mainframe addindicator]
  set gaSet(amc) [$mainframe addindicator]; # active main card
  $gaSet(amc) configure -width 3
  set gaSet(runTime) [$mainframe addindicator]
  $gaSet(runTime) configure -width 4
  
  #console show
  #return 1
  

  set tb0 [$mainframe addtoolbar]
  pack $tb0 -fill x
  set labstartFrom [Label $tb0.labSoft -text "Start From   "]
  set gaGui(startFrom) [ComboBox $tb0.cbstartFrom  -height 13 -textvariable gaSet(startFrom) \
      -justify center  -editable 0 ]
  $gaGui(startFrom) bind <Button-1> {SaveInit}
  pack $labstartFrom $gaGui(startFrom) -padx 2 -side left
  set sepIntf [Separator $tb0.sepIntf -orient vertical]
  pack $sepIntf -side left -padx 6 -pady 2 -fill y -expand 0
	 
  set bb [ButtonBox $tb0.bbox0 -spacing 1 -padx 5 -pady 5]
    set gaGui(tbrun) [$bb add -image [image create photo -file [pwd]/images/run1.ico] \
        -takefocus 0 -command ButRun \
        -bd 1 -padx 5 -pady 5 -helptext "Run the Tester"]		 		 
    set gaGui(tbstop) [$bb add -image [image create photo -file [pwd]/images/stop1.ico] \
        -takefocus 0 -command ButStop \
        -bd 1 -padx 5 -pady 5 -helptext "Stop the Tester"]
    set gaGui(tbpaus) [$bb add -image [image create photo -file [pwd]/images/pause.ico] \
        -takefocus 0 -command ButPause \
        -bd 1 -padx 5 -pady 1 -helptext "Pause/Continue the Tester"]	    
  pack $bb -side left  -anchor w -padx 7 ;#-pady 3
  
  set bb [ButtonBox $tb0.bbox12 -spacing 1 -padx 5 -pady 5]
    set gaGui(email) [$bb add -image [image create photo -file  [pwd]/images/email16.ico] \
        -takefocus 0 -command {GuiEmail .mail} \
        -bd 1 -padx 5 -pady 5 -helptext "Email Setup"]   
    set gaGui(ramzor) [$bb add -image [image create photo -file  [pwd]/images/TRFFC09_1.ico] \
        -takefocus 0 -command {GuiIPRelay} \
        -bd 1 -padx 5 -pady 5 -helptext "IP-Relay Setup"] 
  pack $bb -side left  -anchor w -padx 7
  
  set sepIntf [Separator $tb0.sepFL -orient vertical]
  #pack $sepIntf -side left -padx 6 -pady 2 -fill y -expand 0 
  
    
  set bb [ButtonBox $tb0.bbox2]
    set gaGui(butShowLog) [$bb add -image [image create photo -file [pwd]/images/find1.1.ico] \
        -takefocus 0 -command {ShowLog} -bd 1 -helptext "View Log file"]    
  pack $bb -side left  -anchor w -padx 7
  
    set frCommon [frame $mainframe.frCommon]
      set frUut [frame $frCommon.frUut]   
        
      pack $frUut -fill y -expand 1 -padx 2 -pady 2 -side left ; # -ipadx 10
    pack $frCommon -fill y -expand 1 -padx 2 -pady 0 -side left 

#    set frTestSetup [TitleFrame $mainframe.frTestSetup -bd 2 -relief groove \
        -text "Test Setup"]
#       set labStartFrom [Label [$frTestSetup getframe].labStartFrom  \
#           -text " Start From  " -width 12]
#       set gaGui(startFrom) [ComboBox [$frTestSetup getframe].startFrom  \
#           -textvariable gaSet(startFrom) -editable 0 ]
#       pack $labStartFrom $gaGui(startFrom) -padx 7 -pady 3 -fill x -side left;# -expand 1
 	 
    set frDUT [frame $mainframe.frDUT -bd 2 -relief groove] 
      set labDUT [Label $frDUT.labDUT -text "UUT's option" -width 15]
      set gaGui(cmbDUT) [ComboBox $frDUT.cmbDUT -bd 1 -justify center -width 50\
            -editable 0 -relief groove -textvariable gaSet(uutOpt) -command {}\
            -helptext "Choose checked option" -values [list Regular Telmex MSCEM LY_SYSTELE]]
      pack $labDUT $gaGui(cmbDUT) -side left -padx 2
    
    set frTestPerf [TitleFrame $mainframe.frTestPerf -bd 2 -relief groove \
        -text "Test Performance"] 
      set f [$frTestPerf getframe]
      set frCur [frame $f.frCur]  
        set labCur [Label $frCur.labCur -text "Current Test  " -width 12]
        set gaGui(curTest) [Entry $frCur.curTest -bd 1 \
            -editable 0 -relief groove -textvariable gaSet(curTest) \
	       -justify center -width 70]
        pack $labCur $gaGui(curTest) -padx 7 -pady 3 -side left -fill x;# -expand 1 
      pack $frCur  -anchor w
      set frStatus [frame $f.frStatus]
        set labStatus [Label $frStatus.labStatus -text "Status  " -width 12]
        set gaGui(labStatus) [Entry $frStatus.entStatus -bd 1 -editable 0 \
            -relief groove -textvariable gaSet(status) -justify center -width 70]
        pack $labStatus $gaGui(labStatus) -fill x -padx 7 -pady 3 -side left;# -expand 1 	 
      pack $frStatus -anchor w
      set frFail [frame $f.frFail]
      set gaGui(frFailStatus) $frFail
        set labFail [Label $frFail.labFail -text "Fail Reason  " -width 12]
        set labFailStatus [Entry $frFail.labFailStatus \
            -bd 1 -editable 1 -relief groove \
            -textvariable gaSet(fail) -justify center -width 80]
      pack $labFail $labFailStatus -fill x -padx 7 -pady 3 -side left; # -expand 1	
      #pack $gaGui(frFailStatus) -anchor w
      
           
    pack $frDUT $frTestPerf -fill x -expand yes -padx 2 -pady 2 -anchor n	 
  pack $mainframe -fill both -expand yes

  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled  
  
  .menubar.tterminal entryconfigure 0 -label "Chassis-1 MC-A: COM $gaSet(comMC.1.1)"
  .menubar.tterminal entryconfigure 1 -label "Chassis-1 MC-B: COM $gaSet(comMC.1.2)"
  .menubar.tterminal entryconfigure 2 -label "Chassis-1 DaviCOM: COM $gaSet(comMC.1.d)"
  .menubar.tterminal entryconfigure 3 -label "Chassis-2 MC-A: COM $gaSet(comMC.2.1)"
  .menubar.tterminal entryconfigure 4 -label "Chassis-2 MC-B: COM $gaSet(comMC.2.2)"
  .menubar.tterminal entryconfigure 5 -label "Chassis-2 DaviCOM: COM $gaSet(comMC.2.d)"
  .menubar.tterminal entryconfigure 6 -label "DXC4: COM $gaSet(comDXC)"
  .menubar.tterminal entryconfigure 7 -label "GEN: COM $gaSet(com220)"    

  console eval {.console config -height 36 -width 132}
  console eval {set ::tk::console::maxLines 100000}
  console eval {.console config -font {Verdana 8}}
  focus -force .
  bind . <F1> {console show}

  #RLStatus::Show -msg atp
  #RLStatus::Show -msg fti
  
  if ![info exists ::RadAppsPath] {
    set ::RadAppsPath c:/RadApps
  }
  set gaSet(GuiUpTime) [clock seconds]
}
# ***************************************************************************
# About
# ***************************************************************************
proc About {} {
  if [file exists history.html] {
    set id [open history.html r]
    set hist [read $id]
    close $id
#     regsub -all -- {[<>]} $hist " " a
#     regexp {div ([\d\.]+) \/div} $a m date
    regsub -all -- {<[\w\=\#\d\s\"\/]+>} $hist "" a
    regexp {<!---->\s(.+)\s<!---->} $a m date
  } else {
    set date 04.09.2014
  }
  DialogBox -title "About the Tester" -icon info -type ok  -font {{Lucida Console} 9} -message "ATE software upgrade\n$date"
  
#   if [file exists history.html] {
#     set id [open history.html r]
#     set hist [read $id]
#     close $id
#     regsub -all -- {[<>]} $hist " " a
#     regexp {div ([\d\.]+) \/div} $a m date
#   } else {
#     set date 04.09.2014 
#   }
#   DialogBox -title About -icon [pwd]/images/info.ico -type ok -message "The software upgrated at $date"
# 
#   #DialogBox -title "About the Tester" -icon info -type ok\
#           -message "The software upgrated at 04.09.2014"
}

# ***************************************************************************
# Quit
# ***************************************************************************
proc Quit {} {
  global gaSet
  SaveInit
  set ret [DialogBox -title "Confirm exit"\
      -type "yes no"  -icon [pwd]/images/question.ico  -aspect 2000\
      -text "Are you sure you want to close the application?"]
  if {$ret=="yes"} {exit}
}
#***************************************************************************
#** GuiInventory
#***************************************************************************
proc GuiInventory {} {  
  global gaSet gaTmp gaGui glXFPs
  
  source uutInits/$gaSet(uutOpt).tcl
  
  array unset gaTmp
  if ![info exists gaSet(sp)] {set gaSet(sp) sp}
  set gaTmp(sp)  $gaSet(sp)
  
  if ![info exists gaSet(hw)] {set gaSet(hw) hw}
  set gaTmp(hw)  $gaSet(hw)
  
  if ![info exists gaSet(sw)] {set gaSet(sw) sw}
  set gaTmp(sw)  $gaSet(sw)
  
  if ![info exists gaSet(fw)] {set gaSet(fw) fw}
  set gaTmp(fw)  $gaSet(fw)
  
  if ![info exists gaSet(boot)] {set gaSet(boot) boot}
  set gaTmp(boot)  $gaSet(boot)
  
  if ![info exists gaSet(io)] {set gaSet(io) io}
  set gaTmp(io)  $gaSet(io)
  
  if ![info exists gaSet(u17)] {set gaSet(u17) u17}
  set gaTmp(u17)  $gaSet(u17)
  
  if ![info exists gaSet(pwrC)] {set gaSet(pwrC) pwrC}
  set gaTmp(pwrC)  $gaSet(pwrC)
  
  
  if ![info exists gaSet(etx220cnf)] {set gaSet(etx220cnf) c:/etx220cnf}
  set gaTmp(etx220cnf)  $gaSet(etx220cnf)
  
  if ![info exists gaSet(etx5300cnf1)] {set gaSet(etx5300cnf1) c:/etx5300cnf1}
  set gaTmp(etx5300cnf1)  $gaSet(etx5300cnf1)
  
  if ![info exists gaSet(pageFile)] {set gaSet(pageFile) c:/pageFile}
  set gaTmp(pageFile)  $gaSet(pageFile)
  
  if ![info exists gaSet(xfp1)] {set gaSet(xfp1) xfp1}
  set gaTmp(xfp1)  $gaSet(xfp1)
  if ![info exists gaSet(xfp2)] {set gaSet(xfp2) xfp2}
  set gaTmp(xfp2)  $gaSet(xfp2)
  if ![info exists gaSet(xfp3)] {set gaSet(xfp3) xfp3}
  set gaTmp(xfp3)  $gaSet(xfp3)
  if ![info exists gaSet(xfp4)] {set gaSet(xfp4) xfp4}
  set gaTmp(xfp4)  $gaSet(xfp4)
  
  
  
  set base .topHwInit
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm geometry $base $gaGui(xy)
  wm resizable $base 1 1 
  wm title $base "Inventory of \'$gaSet(uutOpt)\'"
  pack [LabelEntry $base.entSP   -label "SW-pack:  " -labelwidth 20 -width 25 -justify center -textvariable  gaTmp(sp)] -pady 1 -padx 3 
  pack [LabelEntry $base.entSW   -label "SW:  "      -labelwidth 20  -width 25 -justify center -textvariable gaTmp(sw)] -pady 1 -padx 3        
  pack [LabelEntry $base.entHW   -label "HW:  "      -labelwidth 20 -width 25 -justify center -textvariable gaTmp(hw)] -pady 1 -padx 3  
  pack [LabelEntry $base.entFW   -label "FW:  "      -labelwidth 20 -width 25 -justify center -textvariable gaTmp(fw)] -pady 1 -padx 3
  pack [LabelEntry $base.entBoot -label "Boot:  "    -labelwidth 20 -width 25 -justify center -textvariable gaTmp(boot)] -pady 1 -padx 3  
  pack [LabelEntry $base.entU17  -label "U17:  "    -labelwidth 20 -width 25 -justify center -textvariable gaTmp(u17)] -pady 1 -padx 3
  pack [LabelEntry $base.entpwrC  -label "Power Controller:  "    -labelwidth 20 -width 25 -justify center -textvariable gaTmp(pwrC)] -pady 1 -padx 3  
  
  pack [Separator $base.sep1 -orient horizontal] -fill x -padx 2 -pady 3
  
  foreach xfp {1 2 3 4} {
    set fr [frame $base.frXFP$xfp]
      set lab [Label $fr.lab -text "10GbE $xfp" -width 12 ]
      set cb [ComboBox $fr.cb -textvariable gaTmp(xfp$xfp) -values $glXFPs -justify center]
      pack $lab $cb -side left -padx 2
    pack $fr
  }  

  pack [Separator $base.sep2 -orient horizontal] -fill x -padx 2 -pady 3
  
  set fr [frame $base.fr3 -bd 2 -relief groove]
    pack [Button $fr.brwUaf -text "Browse ETX-220 Configuration File..." -command "BrowseEtx220cnf"] -side left -pady 1 -padx 3 -anchor w
    pack [Label $fr.labUaf  -textvariable gaTmp(etx220cnf)] -pady 1 -padx 3 -anchor w
  pack $fr  -fill x 
  
  set fr [frame $base.fr2 -bd 2 -relief groove]
    pack [Button $fr.brwUaf -text "Browse ETX-5300.1 Configuration File..." -command "BrowseEtx5300cnf1"] -side left -pady 1 -padx 3 -anchor w
    pack [Label $fr.labUaf  -textvariable gaTmp(etx5300cnf1)] -pady 1 -padx 3 -anchor w
  pack $fr  -fill x 
  
  set fr [frame $base.fr4 -bd 2 -relief groove]
    pack [Button $fr.brwPage -text "Browse Page File..." -command "BrowsePage"] -side left -pady 1 -padx 3 -anchor w
    pack [Label $fr.labPage  -textvariable gaTmp(pageFile)] -pady 1 -padx 3 -anchor w
  pack $fr  -fill x 
  #pack [Separator $base.sep2 -orient horizontal] -fill x -padx 2 -pady 3
  
  #pack [Separator $base.sep3 -orient horizontal] -fill x -padx 2 -pady 3
  
  pack [frame $base.frBut ] -pady 4 -anchor e
    pack [Button $base.frBut.butCanc -text Cancel -command ButCancInventory -width 7] -side right -padx 6
    pack [Button $base.frBut.butOk -text Ok -command ButOkInventory -width 7]  -side right -padx 6
  
  focus -force $base
  grab $base
  return {}  
}
# ***************************************************************************
# BrowseUdf
# ***************************************************************************
proc BrowseEtx220cnf {} {
  global gaTmp
  set gaTmp(etx220cnf) [tk_getOpenFile -title "Choose ETX-220 Configuration File" -initialdir "c:\\Download"]
  focus -force .topHwInit
}
# ***************************************************************************
# BrowseUaf
# ***************************************************************************
proc BrowseEtx5300cnf1 {} {
  global gaTmp
  set gaTmp(etx5300cnf1) [tk_getOpenFile -title "Choose ETX-5300.1 Configuration File" -initialdir "c:\\Download"]
  focus -force .topHwInit
}

# ***************************************************************************
# BrowsePage
# ***************************************************************************
proc BrowsePage {} {
  global gaTmp
  set gaTmp(pageFile) [tk_getOpenFile -title "Choose Page File" -initialdir "[pwd]/[info hostname]"]
  focus -force .topHwInit
}

#***************************************************************************
#** ButOk
#***************************************************************************
proc ButOkInventory {} {
  global gaSet gaTmp
  set hw  [.topHwInit.entHW cget -text]
  puts "hw:$hw"
  set sw  [.topHwInit.entSW cget -text]
  puts "sw:$sw"
  set sp  [.topHwInit.entSP cget -text]
  puts "sp:$sp"
  set fw  [.topHwInit.entFW cget -text]
  puts "fw:$fw"
  set boot  [.topHwInit.entBoot cget -text]
  puts "boot:$boot"
  set u17  [.topHwInit.entU17 cget -text]
  puts "u17:$u17"
  set pwrC  [.topHwInit.entpwrC cget -text]
  puts "pwrC:$pwrC"
  
  set gaSet(sw) $sw
  set gaSet(hw) $hw
  set gaSet(sp) $sp
  set gaSet(fw) $fw
  set gaSet(boot) $boot
  set gaSet(u17) $u17
  set gaSet(pwrC) $pwrC
  
   if {$gaTmp(etx220cnf)!=""} {
     set gaSet(etx220cnf) $gaTmp(etx220cnf)
   }
  if {$gaTmp(etx5300cnf1)!=""} {
    set gaSet(etx5300cnf1) $gaTmp(etx5300cnf1)
  }
  if {$gaTmp(pageFile)!=""} {
    set gaSet(pageFile) $gaTmp(pageFile)
  }
  foreach xfp {1 2 3 4} {
    set  gaSet(xfp$xfp) $gaTmp(xfp$xfp)
  }    
  
  array unset gaTmpSet
  set fil "uutInits/$gaSet(uutOpt).tcl"
  SaveUutInit $fil
  #SaveInit
  ButCancInventory
}


#***************************************************************************
#** ButCancInventory
#***************************************************************************
proc ButCancInventory {} {
  grab release .topHwInit
  focus .
  destroy .topHwInit
}

# ***************************************************************************
# ButStop
# ***************************************************************************
proc ButStop {} {
  global gaGui gaSet
  set gaSet(act) 0
  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled
  $gaGui(tbpaus) configure -relief sunken -state disabled
  .mainframe setmenustate tools normal
  CloseRL
  update
}
# ***************************************************************************
# ButPause
# ***************************************************************************
proc ButPause {} {
  global gaGui gaSet
  if { [$gaGui(tbpaus) cget -relief] == "raised" } {
    $gaGui(tbpaus) configure -relief "sunken"     
    #CloseRL
  } else {
    $gaGui(tbpaus) configure -relief "raised" 
    #OpenRL   
  }
        
  while { [$gaGui(tbpaus) cget -relief] != "raised" } {
    RLTime::Delay 1
  }  
}

# ***************************************************************************
# ButRun
# ***************************************************************************
proc ButRun {} {
  global gaSet gaGui glTests  gRelayState
  set gaSet(act) 1

  Status ""
  set gaSet(curTest) ""
  $gaSet(amc) configure -text ""
  set gaSet(barcode1.IdMacLink) ""
  set gaSet(barcode2.IdMacLink) ""
  IPRelay-Green
  if ![file exists c:/logs] {
    file mkdir c:/logs
    after 1000
  }
  
#   if {![file exists uutInits/$gaSet(DutInitName)]} {
#     set txt "Init file for \'$gaSet(DutFullName)\' is absent"
#     Status  $txt
#     set gaSet(fail) $txt
#     set gaSet(curTest) $gaSet(startFrom)
#     set ret -1
#     AddToLog $gaSet(fail)
#   }
    
  console eval {.console delete 1.0 end}
  console eval {set ::tk::console::maxLines 100000}
  catch {unset gaSet(barcode1)}
  catch {unset gaSet(barcode2)}
  set gaSet(ButRunTime) [clock seconds]

  
  set ret [GuiReadOperator]
  parray gaSet *arco*
  parray gaSet *rato*
  if {$ret!=0} {
    set ret -3
  } elseif {$ret==0} {
    set ret [ReadBarcode]
    parray gaSet *arco*
    parray gaSet *rato*
    if {$ret=="-1"} {
#       ## SKIP is pressed, we can continue
#       set ret 0
#       set gaSet(1.barcode1) "skipped" 
    }
  
    pack forget $gaGui(frFailStatus)
    $gaSet(startTime) configure -text " Start: [MyTime] "
    $gaGui(tbrun) configure -relief sunken -state disabled
    $gaGui(tbstop) configure -relief raised -state normal
    $gaGui(tbpaus) configure -relief raised -state normal
    set gaSet(fail) ""
    $gaSet(runTime) configure -text ""
    #.mainframe setmenustate tools disabled
    update
    catch {exec taskkill.exe /im hypertrm.exe /f /t}
  }
    
  if {$ret==0} {
     set ti [clock format [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"]
    set gaSet(logFile) c:/logs/${ti}-$gaSet(barcode1)-$gaSet(barcode2).txt
    set gaSet(logTime) [clock format [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"]
    AddToLog "ETX5300A-MC-4XFP"
    AddToLog "UUT Option: $gaSet(uutOpt)" ; #"$gaSet(DutFullName)"
    AddToLog "Start Test"
    AddToLog "UUT-1: $gaSet(barcode1)"
    AddToLog "UUT-2: $gaSet(barcode2)"
 
  }
#   if {$ret=="-1"} {
#     ## SKIP is pressed, we can continue
#     set ret 0
#     set gaSet(1.barcode1) "skipped" 
#   }
#     
#   RLTime::Delay 1
#   set ret 0
  
  if {$ret==0} {
    set ret [OpenRL]
    if {$ret==0} {
      set gaSet(runStatus) ""
      set ret [Testing]
      set gaSet(DavicomCaptureEn) 0
    }
  }
  puts "ret of Testing: $ret"  ; update
  .mainframe setmenustate tools normal
  puts "end of normal widgets"  ; update
  update
  set retC [CloseRL]
  puts "ret of CloseRL: $retC"  ; update
  set gRelayState red
  IPRelay-LoopRed
  
  set gaSet(oneTest) 0
  set gaSet(UUTREF) UUTUUT
  
  if {$ret==0} {
    set txt "Perform \'VOLTAGE TEST\'"
    if {[file exists c:\\notes.txt]} {
      if {[file size c:\\notes.txt]>0} {
        set id [open c:\\notes.txt r]
        set txt [read $id]
        close $id
      }
    }
    
    #exec C:\\RLFiles\\Tools\\Btl\\passbeep.exe &
    Status "Done"  green
	  set gaSet(curTest) ""
    
	  set gaSet(startFrom) [lindex $glTests 0]
    file rename -force $gaSet(logFile) [file rootname $gaSet(logFile)]-Pass.txt
    set gaSet(runStatus) Pass
  } elseif {$ret==1} {
    #exec C:\\RLFiles\\Tools\\Btl\\beep.exe &
    Status "The test has been perform"  yellow
  } else {
    set gaSet(runStatus) Fail  
    if {$ret=="-2"} {
	    set gaSet(fail) "User stop"
      
      ## do not include UserStop in statistics
      set gaSet(runStatus) ""  
	  }
    if {$ret=="-3"} {
	    ## do not include No Operator fail in statistics
      set gaSet(runStatus) ""  
	  }
	  pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
	  #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
	  Status "Test FAIL"  red
	  #DialogBox -icon error -type "OK" -text "TEST FAILED"  -aspect 2000 -title ETX5300A-MC-4XFP
    if {[string length $gaSet(curTest)]>1} {
      ## don't update if current is empty, for example - after fail of OpenRL
      set gaSet(startFrom) $gaSet(curTest)
    }
    file rename -force $gaSet(logFile) [file rootname $gaSet(logFile)]-Fail.txt
    update
  }
  
  if {$gaSet(runStatus)!=""} {
    if [string match {*Chassis-1*} $gaSet(fail)] {
      SQliteAddLine 1
    } 
    if [string match {*Chassis-2*} $gaSet(fail)] {
      SQliteAddLine 2
    } 
    if {[string match {*Chassis-1*} $gaSet(fail)]==0 && [string match {*Chassis-2*} $gaSet(fail)]==0} {
      SQliteAddLine 1
      SQliteAddLine 2
    }
  }
  
  #SendEmail "ETX5300A-MC-4XFP" [$gaSet(sstatus) cget -text]
  SendEmail "ETX5300A-MC-4XFP" $gaSet(status)
  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled
  $gaGui(tbpaus) configure -relief sunken -state disabled
  update
}

#***************************************************************************
#** CaptureConsole
#***************************************************************************
proc CaptureConsole {} {
  console eval { 
    set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"]
    set fi c:/temp/ConsoleCapt_[set ti].txt
    if [file exists $fi] {
      set res [tk_messageBox -title "Save Console Content" \
        -icon info -type yesno \
        -message "File $fi already exist.\n\
               Do you want overwrite it?"]      
      if {$res=="no"} {
         set types { {{Text Files} {.txt}} }
         set new [tk_getSaveFile -defaultextension txt \
                 -initialdir c:\\ -initialfile [file rootname $fi]  \
                 -filetypes $types]
         if {$new==""} {return {}}
      }
    }
    set aa [.console get 1.0 end]
    set id [open $fi w]
    puts $id $aa
    close $id
  }
}
# ***************************************************************************
# ShowComs
# ***************************************************************************
proc ShowComs {} {                                                                        
  global gaSet gaGui
  DialogBox -title "COMs definitions" -type OK -aspect 2150  -icon [pwd]/images/info.ico\
    -message "Chassis 1: MC-A: COM-$gaSet(comMC.1.1), MC-B: COM-$gaSet(comMC.1.2), DaviCOM: COM-$gaSet(comMC.1.d)\n\
    Chassis 2: MC-A: COM-$gaSet(comMC.2.1), MC-B: COM-$gaSet(comMC.2.2), DaviCOM: COM-$gaSet(comMC.2.d)\n\
    ETX220: COM-$gaSet(com220) \nDXC: COM-$gaSet(comDXC)"
  return {}
}
# ***************************************************************************
# GuiReadOperator
# ***************************************************************************
proc GuiReadOperator {} {
  global gaSet gaGui gaDBox gaGetOpDBox
  catch {array unset gaDBox} 
  catch {array unset gaGetOpDBox} 
  #set ret [GetOperator -i pause.gif -ti "title Get Operator" -te "text Operator's Name "]
  set ret [GetOperator -i images/oper32.ico -gn $::RadAppsPath]
  if {$ret=="-1"} {
    set gaSet(fail) "No Operator Name"
    return $ret
  } else {
    set gaSet(operator) $ret
    return 0
  }
}