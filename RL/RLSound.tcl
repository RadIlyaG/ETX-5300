#===============================================================
#
#  FileName:   RLSound.tcl
#
#  Written by: Ohad / 03.10.1999
#
#  Abstract:   This file contains procedures for activating sound files
#
#              
#  Procedures:    - Open
#                 - Play
#
#===============================================================

package require RLEH 1.04
package require  RLFile 
package require  snack 

package provide RLSound 1.11

namespace eval RLSound {

  namespace export Open Play 
  
  #***************************************************************
  #**
  #** Open
  #**
  #** Abstract: Initializing the system to work with sound
  #**           check the system requierments and creates a list 
  #**           contaning pairs in the folowing format:
  #**           { var1 soundFileName1 var2 soundFileName2 ..... }
  #**
  #** Inputs: 'ip_list' the list contaning the variables and the sound file names.
  #**         if not specifing any list there is a default list (see Remarks)
  #**     
  #** Outputs: '0' if O.K. '-1' else
  #**
  #** Usage: RLSound::Open {var1 name1 var2 name2 .... }
  #**
  #** Remarks: In the soundFileName you can specify a file name from the
  #**          sound directory or you can specify the full name of a sound 
  #**          file, e.g. c:\\mywork\\sounds\\wav\\horn.wav
  #**          Default list: {pass pass.wav fail fail.wav \
  #**                         information info.wav warning warning.wav}
  #**
  #**					  !!!!!!  "info" is a reserved word - can't be use  !!!!!!
  #**
  #**          
  #** Example: RLSound::Open {passbeep pass1.wav failbeep fail.wav \
  #**                         infobeep c:\\wav\\horn.wav warningbeep c:\\siren.wav ...}
  #**
  #***************************************************************

  proc Open { {ip_list 0} } {
    
    global gMessage
    global env
		variable vSoundDevice 
    set devs [snack::mixer devices]
		if {[llength $devs] == 0} {
  		set vSoundDevice 0
		} else {
  		  set vSoundDevice 1
		}

    set iniFile $env(windir)\\RLPath.ini
	 
	 if {$ip_list == 0 } {
	   # set default sounds
	   set soundList {pass pass.wav fail fail.wav information info.wav warning warning.wav}
      set numOfElements [llength $soundList]
	 } else {
	     # set custom sounds given by the user
	     set soundList $ip_list
	 	  puts $soundList
	 	  set numOfElements [llength $soundList]
	 	  puts $numOfElements
	 	  if {$numOfElements <= 1 } {
	 	    set gMessage "Sound list must contain atlist two elements. (RLSound::Open {soundList})"
	 		 RLEH::Handle SAsyntax gMessage
	 	    return -1
	 	  }
	 	  # checking that soundList contain an EVEN number of elements
	 	  for {set i 2 ; set stopLoop 0 } {($i <= 100) && ($stopLoop == 0)} {incr i 2} {
	 	    if {$numOfElements == $i} {
	 		   set stopLoop 1
	 		 }
	 	  }
	 	  if {$i > 100} {
	 	    set gMessage "Wrong format of sound list structure.\n\n\
	 		 Number of elements should be an EVEN number.\n\
	 		 Number of variables must equal to number of sound files.\n"
	 		 RLEH::Handle SAsyntax gMessage
	 	    return -1
	 	  }
   }      
	 # Geting the sound files directory path into variable "soundPath"
   if { [RLFile::Inigetitem $iniFile RadLab SoundPath soundPath errMsg] != 0 } {
	 	  set gMessage "Error while trying to get item from ini file: $iniFile"
	 	  RLEH::Handle System gMessage
	 	  return -1
	 }
	 # checking for valid file types in sound list
	 for {set i 1} {$i < $numOfElements} {incr i 2} {
	 	  set fileType [string tolower [file extension [lindex $soundList $i]]]
	 	  if { $fileType != ".wav" } {
	 	    set gMessage "Wrong file type in sound list.\nFile: [lindex $soundList $i]\nNot a valid WAV file. (Must have a '.wav' extension)"
	 		 RLEH::Handle SAsyntax gMessage
	 	    return -1
	 	  }
	 }
	 	# appending full path to files without full path
	for {set i 1} {$i < $numOfElements} {incr i 2} {
	  set filePath [file dirname [lindex $soundList $i]]
	  if { $filePath == "." } {
	    sound [lindex $soundList [expr $i -1]]
		 if {[catch {[lindex $soundList [expr $i -1]] read $soundPath\\[lindex $soundList $i]} fileError] == 1} {
		   set gMessage $fileError
			RLEH::Handle SAsyntax gMessage
	      return -1
		 }
	  } else {
		   sound [lindex $soundList [expr $i -1]]
		   if {[catch {[lindex $soundList [expr $i -1]] read [lindex $soundList $i]} fileError] ==1} {
         	  set gMessage $fileError
			      RLEH::Handle SAsyntax gMessage
		        return -1
			 }
		}
  }
  return 0
  }      


  #***************************************************************
  #**
  #** Play
  #**
  #** Abstract: Plays the specified file that is represented by the variable name
  #**
  #** Inputs: 'ip_varName' name of variable 
  #**     
  #** Outputs: 
  #**
  #** Usage: RLSound::Play failbeep
  #**
  #** Remark: If working with default sound list the variables name are:
  #**         pass ; fail ; information ; warning
  ##**
  #***************************************************************

  proc Play { ip_varName } {
    
		variable vSoundDevice
    if ![info exists vSoundDevice] {
      RLSound::Open
    }
 	  if {$vSoundDevice} {
      $ip_varName play
		}
  }
}

