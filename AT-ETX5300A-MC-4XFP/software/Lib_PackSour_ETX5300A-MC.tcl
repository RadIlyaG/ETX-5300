wm iconify . ; update

package require registry
set gaSet(hostDescription) [registry get "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\LanmanServer\\Parameters" srvcomment ]
set jav [registry -64bit get "HKEY_LOCAL_MACHINE\\SOFTWARE\\javasoft\\Java Runtime Environment" CurrentVersion]
set gaSet(javaLocation) [file normalize [registry -64bit get "HKEY_LOCAL_MACHINE\\SOFTWARE\\javasoft\\Java Runtime Environment\\$jav" JavaHome]/bin]

## delete barcode files TO3001483079.txt
foreach fi [glob -nocomplain -type f *.txt] {
  if [regexp {\w{2}\d{9,}} $fi] {
    file delete -force $fi
  }
}
if [file exists c:/TEMP_FOLDER] {
  file delete -force c:/TEMP_FOLDER
}
after 1000
set ::RadAppsPath c:/RadApps

if 1 {
  set gaSet(radNet) 0
  foreach {jj ip} [regexp -all -inline {v4 Address[\.\s\:]+([\d\.]+)} [exec ipconfig]] {
    if {[string match {*192.115.243.*} $ip] || [string match {*172.18.*} $ip]} {
      set gaSet(radNet) 1
    }  
  }
  if {$gaSet(radNet)} {
    set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl]
    set mTimeRL  [file mtime c:/tcl/lib/rl/rlautosync.tcl]
    puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
    if {$mTimeTds>$mTimeRL} {
      puts "$mTimeTds>$mTimeRL"
      file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl c:/tcl/lib/rl
      after 2000
    }
    
    set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl]
    set mTimeRL  [file mtime c:/tcl/lib/rl/rlautoupdate.tcl]
    puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
    if {$mTimeTds>$mTimeRL} {
      puts "$mTimeTds>$mTimeRL"
      file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl c:/tcl/lib/rl
      after 2000
    }
    
    update
  }
  package require RLAutoSync
  
  set s1 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX5300A-MC-4XFP/AT-ETX5300A-MC-4XFP/software]
  set d1 [file normalize  C:/ETX5300A-MC-4XFP/software]
  
  
  if {$gaSet(radNet)} {
    set emailL {{ilya_g@rad.com} {} {}}
    set emailL {{meir_ka@rad.com} {} {}}
  } else {
    set emailL [list]
  }
  
  set ret [RLAutoSync::AutoSync "$s1 $d1" -noCheckFiles {init*.tcl skipped.txt *.db} \
      -jarLocation $::RadAppsPath -javaLocation $gaSet(javaLocation) \
      -emailL $emailL -putsCmd 1 -radNet $gaSet(radNet)]
  #console show
  puts "ret:<$ret>"
  set gsm $gMessage
  foreach gmess $gMessage {
    puts "$gmess"
  }
  update
  if {$ret=="-1"} {
    set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
    -message "The AutoSync process did not perform successfully.\n\n\
    Do you want to continue? "]
    if {$res=="no"} {
      exit
    }
  }
  
  if {$gaSet(radNet)} {
    package require RLAutoUpdate
    set s2 [file normalize W:/winprog/ATE]
    set d2 [file normalize $::RadAppsPath]
    set ret [RLAutoUpdate::AutoUpdate "$s2 $d2" \
        -noCopyGlobL {Get_Li* Get28* Macreg.2* Macreg-i* DP* *.prd}]
    #console show
    puts "ret:<$ret>"
    set gsm $gMessage
    foreach gmess $gMessage {
      puts "$gmess"
    }
    update
    if {$ret=="-1"} {
      set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
      -message "The AutoSync process did not perform successfully.\n\n\
      Do you want to continue? "]
      if {$res=="no"} {
        SQliteClose
        exit
      }
    }
  }
}

package require BWidget
package require img::ico
package require RLSerial
package require RLEH
package require RLTime
package require RLStatus
package require RLDxc4
package require RL[set gaSet(pioType)]Pio
#package require RLEtxGen
package require RL10GbGen
package require ezsmtp
package require RLAutoUpdate
package require sqlite3

source Gui_ETX5300A-MC.tcl
source Lib_Gen_ETX5300A-MC.tcl
source Lib_DialogBox.tcl

#parray gaSet
source [pwd]/[info hostname]/init$gaSet(tester).tcl
#parray gaSet
source Lib_FindConsole.tcl
source Main_ETX5300A-MC.tcl
source Lib_Put_ETX5300A-MC.tcl
source LibEmail.tcl
source LibIPRelay.tcl
source Lib_GuiPageSetup_ETX5300A-MC.tcl
source Lib_Ds280e01_ETX5300A-MC.tcl
source lib_bc.tcl
source Lib_Etx204_220.tcl

if [file exists [pwd]/uutInits/$gaSet(uutOpt).tcl] {
  source [pwd]/uutInits/$gaSet(uutOpt).tcl
} else {
  source [lindex [glob [pwd]/uutInits/ETX-5300*.tcl] 0]
}
source lib_SQlite.tcl
source LibUrl.tcl
source Lib_GetOperator.tcl

set gaSet(act) 1
set gaSet(oneTest)    0
set gaSet(waitBreak) 0
set glXFPs [list "10000_1310.00_SM" "10000_1310 Laser_SM" "15000_850_MM"]
set gaSet(useExistBarcode) 0
set gaSet(PageSetupType) BarcodeOnly
set gaSet(UUTREF) UUTUUT

GUI
BuildTests
Status "Ready"

wm geometry . $gaGui(xy)
update
wm deiconify .  
