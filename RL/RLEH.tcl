
#***************************************************************************
#** Exception Handler, written by Aharon Strosberg 3/99.
#** 
#** Exported procedures:  
#**  Init {} 
#**  SetCommand {ip_level ip_commandProc} 
#**  DefNewLevel {ip_level ip_command} 
#**  Handle {ip_level ip_messageName}
#**  GetCommand {ip_level}
#**  IsEnabled {ip_level}
#**  GetAccExceptions {ip_level}
#**  ClearAccExceptions {ip_level}
#**  ClearAllAccExceptions {}
#** 
#** Standard eException levels:
#**  FatalSystem System Syntax SAfatalSystem SAsystem SAsyntax 
#**  FatalQuestion Question 
#** 
#** Standard commands (treatments):
#**  ErrOkExit ErrOkAbort ErrAbortOrCont ErrExitOrCont
#**  WarnOk Disable Transparent
#** 
#** 
#***************************************************************************

#************************************************************************
#** Levels definition:
#**  
#** FatalSystem        - Fatal system error (e.g. memory allocation).
#**                      Higher level can handle returned errors
#**                      (e.g. TestBert).
#** system             - Non-fatal system error, possibly caused by 
#**                      programmer's mistake(e.g. COM1 is already open).
#**                      Higher level can handle returned errors
#**                      (e.g. TestBert).
#** Syntax             - Syntax error. 
#**                      Higher level can handle returned errors.
#**                      (e.g. TestBert).
#** SAFatalSystem      - The same as FatalSystem, but higher levels can not
#**                      handle errors (e.g. after SetBert we do not check
#**                      the returned code, so if there is a need to abort,
#**                      we should do it automatically).
#** SASystem           - The same as System, but higher levels can not
#**                      handle errors (e.g. after SetBert we do not check
#**                      the returned code, so if there is a need to abort,
#**                      we should do it automatically).
#** SASyntax           - The same as Syntax, but higher levels can not
#**                      handle errors (e.g. after SetBert we do not check
#**                      the returned code, so if there is a need to abort,
#**                      we should do it automatically).
#** FatalQuestion      - A question which provides important details, that
#**                      we can't bypass using default answers.
#** Question           - A question that we can eliminate, using default
#**                      answers.
#** FatalConfirmation  - A crucial confirmation (e.g. it doesn't make sense
#**                      proceed until the user connects a cable). 
#** Confirmation       - A confirmation that can be eliminated.
#** Warning            - A warning
#** FatalUut           - A UUT error is fatal if it is going to cause many
#**                      other test steps to fail.(e.g. no response to
#**                      management commands)
#** Uut                - A non-fatal error.
#**  
#************************************************************************

#************************************************************************
#** Standard commands (treatments) definition:
#**  
#** ErrOkExit      - Error message box with OK button; exit. 
#** ErrOkAbort     - Error message box with OK button;
#**                  return "Abort".
#** ErrAbortOrCont - Error message box, "Would you like to abort?" yes/no.
#**                  yes: return "Abort", no: return 0.
#** ErrExitOrCont  - Error message box, "Would you like to exit?" yes/no.
#**                  yes: exit, no: return 0.
#** WarnOk         - Warning message box with OK button; return 0.
#** Disable        - No message, return 0.
#** Enable         - Exception levels associated with "Enable" should use
#**                  the IsEnabled procedure instead of Handle. This is
#**                  a special mechanism for external treatment of exceptions. 
#** Transparent    - No message, return the original exception level
#** 
#***************************************************************************
package require Tk 
#package require RLSound 1.1
package require snack
package provide RLEH 1.04

namespace eval RLEH {
 namespace export SetCommand DefNewLevel Handle GetCommand IsEnabled 
 namespace export GetAccExceptions ClearAccExceptions
 namespace export ClearAllAccExceptions Open Close
  
  #RLSound::Open
   
  sound failSound 
 # failSound read failbeep.wav 

 #semion
 if {[file exists c:\\RLFiles\\Sound\\Wav\\fail.wav]} {
	 failSound read c:\\RLFiles\\Sound\\Wav\\fail.wav
 } elseif {[file exists c:\\windows\\media\\Chord.wav]} {
     failSound read c:\\windows\\media\\Chord.wav 
 }
 proc Open {} {
  variable nAlreadyOpen
  
  if {[info exists nAlreadyOpen]} {
    error "Exception Handler already open"
  }
  Init
  set nAlreadyOpen open
  return
 }

 proc Close {} {
  variable nAlreadyOpen
  variable naException
  
  if {![info exists nAlreadyOpen]} {
    error "Exception Handler is not open"
  }
  unset nAlreadyOpen
  unset naException
 }

 #***********************************************************************
 #** Init {}
 #** 
 #** 1. Undefine all the external levels
 #** 2. Associate default commands with internal levels
 #** 3. Clear all accumulated errors
 #** 
 #** 
 #***********************************************************************
 proc Init {} {
   variable naException
   variable naAccumulatedExceptions
   
   #Erase the existing array
   if {[info exists naException]} {
     unset naException
   }
   
   set lLevels {FatalSystem System Syntax SAfatalSystem SAsystem \
     SAsyntax FatalQuestion Question \
     FatalConfirmation Confirmation Warning FatalUut Uut}
   
   foreach level $lLevels {
     set naAccumulatedExceptions($level) 0
   }

   foreach {level command} { FatalSystem       ErrOkAbort \
                             System            ErrOkAbort \
                             Syntax            ErrOkAbort \
                             SAfatalSystem     ErrOkExit \
                             SAsystem          ErrOkExit \
                             SAsyntax          ErrOkExit \
                             FatalQuestion     Enable \
                             Question          Enable \
                             FatalConfirmation Enable \
                             Confirmation      Enable \
                             Warning           WarnOk \
                             FatalUut          ErrOkAbort \
                             Uut               ErrOkAbort } {
             set naException($level,command) $command
   }
 }
 

#***************************************************************************
#** SetCommand {ip_level ip_commandProc}:
#** 
#** Associate a new command (treatment) with an existing level.
#** If the procedure name in ip_commandProc is not one of the standard
#** internal commands, it will be associated with the global scope.
#** An external procedure should be declared with 2 input parameters:
#** {ip_level ip_messageName}.
#** Return: 
#** Old command.
#***************************************************************************

 proc SetCommand {ip_level ip_commandProc} {
   variable naException
   variable nMessage
   variable nAlreadyOpen

   if {![info exists nAlreadyOpen]} {
     error "Exception Handler is not open"
   }
 
   if {![LevelExists $ip_level]} {
     error "Level does not exist: $ip_level"
   }
   #If not an internal command, add :: to point the global scope
   if {(![CommandExists $ip_commandProc]) && ($ip_commandProc != "Enable")} {
     if {![string match ::* $ip_commandProc]} {
       set ip_commandProc ::$ip_commandProc 
     }
   }
   set oldCommand $naException($ip_level,command)
   set naException($ip_level,command) $ip_commandProc   
   return $oldCommand
 }
 
 proc LevelExists {ip_level} {
   variable naException

   if {[array names naException "$ip_level,command"] != ""} {
     return 1
   } else {
     return 0
   }
 }


 #***********************************************************************
 #** CommandExists:
 #** Check if command procedure with a specified name exists as a standard
 #** command within the Exception Handler.
 #***********************************************************************

 proc CommandExists {ip_commandProcedure} {
   variable naException

   #Check if exists an internal procedure.
   if {[info procs $ip_commandProcedure] != ""} {
     return 1
   } else {
     return 0
   }
 }
 

 #*************************************************************************
 #** DefNewLevel:
 #** In application layer it is possible to define new exception levels.
 #** If the command procedure, associated with the new exception level, is 
 #** not one of the standard commands, a leading :: is added, to associate 
 #** it with the global scope.
 #*************************************************************************
 
 
 proc DefNewLevel {ip_level ip_commandProc} {
   variable naException
   variable nMessage
   variable naAccumulatedExceptions
   variable nAlreadyOpen

   if {![info exists nAlreadyOpen]} {
     error "Exception Handler is not open"
   }
 
   if {[LevelExists $ip_level]} {
     error "Level already exists: $ip_level"
   }

   #If not an internal command, add :: to point the global scope
   if {(![CommandExists $ip_commandProc]) && ($ip_commandProc != "Enable")} {
     if {![string match ::* $ip_commandProc]} {
       set ip_commandProc ::$ip_commandProc 
     }
   }
  
   #set naException($ip_level,state) off   
   set naException($ip_level,command) $ip_commandProc   
   set naAccumulatedExceptions($ip_level) 0 
}
 
 

#***************************************************************************
#**  Handle {ip_level ip_messageName}:
#** 
#**  Handle the exception: 
#**  1. Increment the accumulated errors of the specified level.
#**  2. Report to the log mechanism.
#**  3. Run the command (the associated procedure).
#** 
#***************************************************************************
 
 proc Handle {ip_level ip_messageName} {
   variable naException
   variable nMessage
   variable nAlreadyOpen
           
   if {![info exists nAlreadyOpen]} {
     error "Exception Handler is not open"
   }
 
   if {![LevelExists $ip_level]} {
     error "Level does not exist: $ip_level"
   }
   if {$naException($ip_level,command) == "Enable"} {
     error "No procedure for Enable command!"
   }
   return [eval $naException($ip_level,command) $ip_level $ip_messageName]
 }
 

 #*************************************************************************
 #** GetCommand {ip_level}:
 #** 
 #** Return the command, associated with the specified leve.
 #*************************************************************************
   
 proc GetCommand {ip_level} {
   variable naException
   variable nMessage
   variable nAlreadyOpen
           
   if {![info exists nAlreadyOpen]} {
     error "Exception Handler is not open"
   }
 
   if {![LevelExists $ip_level]} {
     error "Level does not exist: $ip_level"
   }
   
   return $naException($ip_level,command) 
 }
 

 #*************************************************************************
 #**  IsEnabled {ip_level}
 #** 
 #**  Return 1 if that level has any command, othe than Disable or 
 #**  Transparent.
 #*************************************************************************
 
 proc IsEnabled {ip_level} {
   variable naException
   variable nMessage
   variable naAccumulatedExceptions
   variable nAlreadyOpen
           
   if {![info exists nAlreadyOpen]} {
     error "Exception Handler is not open"
   }

   if {![LevelExists $ip_level]} {
     error "Level does not exist: $ip_level"
   }
   
   # When the application uses the IsEnabled procedure, it means that
   # an exception has occured, but the treatment will be external.
   # We still have to report the exception to the log and increment the
   # accumulated errors of that level.
   WriteLog "???" 
   set naAccumulatedExceptions($ip_level) \
    [expr $naAccumulatedExceptions($ip_level) + 1]

   
   if {($naException($ip_level,command)!= "Disable") && \
     ($naException($ip_level,command)!= "Transparent")} {
     return 1
   } else {
     return 0
   }
 } 


 proc FailBeep {} {
  #RLSound::Play fail
  if {[llength [snack::mixer devices]]} {
	  failSound play 
  }
 }

 proc ErrOkExit {ip_level ip_messageName} {
  variable naAccumulatedExceptions
  global $ip_messageName

  WriteLog "???" 
  
  
  set naAccumulatedExceptions($ip_level) \
    [expr $naAccumulatedExceptions($ip_level) + 1]
  FailBeep  
  set caption "$ip_level Error"
  set msg [set $ip_messageName]
  tk_messageBox -message $msg -title $caption \
    -type ok -icon error  
  error "$ip_level Error:\n$msg"
 }

 proc ErrOkAbort {ip_level ip_messageName} {
  variable naAccumulatedExceptions
  global $ip_messageName

  WriteLog "???" 
  
  
  set naAccumulatedExceptions($ip_level) \
    [expr $naAccumulatedExceptions($ip_level) + 1]
  FailBeep  
  set caption "$ip_level Error"
  tk_messageBox -message [set $ip_messageName] -title $caption \
    -type ok -icon error  
  return abort
 }



 proc ErrAbortOrCont {ip_level ip_messageName} {
  variable naAccumulatedExceptions
  global $ip_messageName

  WriteLog "???" 
  set naAccumulatedExceptions($ip_level) \
    [expr $naAccumulatedExceptions($ip_level) + 1]
  FailBeep  
  set caption "$ip_level Error"
  set msg [set $ip_messageName]
  append msg "\n\nWould you like to abort?"
  set ret [tk_messageBox -message $msg -title $caption \
    -type yesno -icon error -default yes]
  if {$ret == "yes"} {
   return abort 
  }
  return 0
 }

 proc ErrExitOrCont {ip_level ip_messageName} {
  variable naAccumulatedExceptions
  global $ip_messageName

  WriteLog "???" 
  set naAccumulatedExceptions($ip_level) \
    [expr $naAccumulatedExceptions($ip_level) + 1]
  FailBeep  
  set caption "$ip_level Error"
  set msg [set $ip_messageName]
  append msg "\n\nWould you like to exit?"
  set ret [tk_messageBox -message $msg -title $caption \
    -type yesno -icon error -default yes]
  if {$ret == "yes"} {
   exit 
  }
  return 0
 }

  proc WarnOk {ip_level ip_messageName} { 
  variable naAccumulatedExceptions
  global $ip_messageName

  WriteLog "???"
  set naAccumulatedExceptions($ip_level) \
    [expr $naAccumulatedExceptions($ip_level) + 1]
  set caption "$ip_level"
  tk_messageBox -message [set $ip_messageName] -title $caption \
    -type ok -icon warning
  return 0
 }

 proc Disable {ip_level ip_messageName} {
  variable naAccumulatedExceptions
  global $ip_messageName

  WriteLog "???"
  set naAccumulatedExceptions($ip_level) \
    [expr $naAccumulatedExceptions($ip_level) + 1]
  return 0
 }

 proc Transparent {ip_level ip_messageName} {
  variable naAccumulatedExceptions
  global $ip_messageName

  WriteLog "???"
  set naAccumulatedExceptions($ip_level) \
    [expr $naAccumulatedExceptions($ip_level) + 1]
  return $ip_level
 }

 proc WriteLog {ip_messageName} {
 global $ip_messageName
  #TBD
 } 

 proc GetAccExceptions {ip_level} {
   variable naException
   variable naAccumulatedExceptions
   variable nMessage
   variable nAlreadyOpen
           
   if {![info exists nAlreadyOpen]} {
     error "Exception Handler is not open"
   }

   if {![LevelExists $ip_level]} {
     error "Level does not exist: $ip_level"
   }
   return $naAccumulatedExceptions($ip_level)   
 } 

 proc ClearAccExceptions {ip_level} {
   variable naException
   variable naAccumulatedExceptions
   variable nMessage
   variable nAlreadyOpen
           
   if {![info exists nAlreadyOpen]} {
     error "Exception Handler is not open"
   }

   if {![LevelExists $ip_level]} {
     error "Level does not exist: $ip_level"
   }
   set naAccumulatedExceptions($ip_level) 0
 } 

 proc ClearAllAccExceptions {} {
   variable naAccumulatedExceptions
   variable naException
   variable nAlreadyOpen
           
   if {![info exists nAlreadyOpen]} {
     error "Exception Handler is not open"
   }
         
    foreach level [array names naAccumulatedExceptions] {
      set naAccumulatedExceptions($level) 0
    }
 }

}


