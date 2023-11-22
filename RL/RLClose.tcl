
#===============================================================
#
#  FileName:   RLClose.tcl
#
#  Written by: Ohad / 25.3.1999
#
#  Abstract:   This file contains procedures for inserting commands
#              to be execute when there is a need to close open sessions
#              or open windows.
#              The commands will be executed with with the 'Close...'
#              procedures.
#
#  Procedures:    - InsertCommand
#                 - InsertMark
#                 - ExcludeCommand
#                 - CloseUntilMark
#                 - CloseAll 
#
#===============================================================

package require RLEH 1.0
package provide RLClose 1.0


namespace eval RLClose {

  namespace export InsertCommand InsertMark ExcludeCommand 
  namespace export CloseUntilMark CloseAll
  variable commandArray

  #***************************************************************
  #**
  #** InsertCommand
  #**
  #** Abstract: Update an array with a command to be later execute. 
  #**
  #** Inputs: 'ip_command' the command to be insert.
  #**     
  #** Outputs:
  #**
  #** Usage: RLClose::InsertCommand 'command'
  #**
  #** Remarks: The stored commands will be executed when
  #**          exiting from TCL script.
  #**
  #***************************************************************

  proc InsertCommand {ip_command} {
  
    variable commandArray
 
    set newElementIndex [ array size commandArray ]    
    set commandArray($newElementIndex) $ip_command
  }


  #***************************************************************
  #**
  #** InsertMark
  #**
  #** Abstract: Update an array with a MARK to provide stoping point
  #**           when executing the commands in commandArray. 
  #**
  #** Inputs:
  #**     
  #** Outputs:
  #**
  #** Usage: RLClose::InsertMark
  #**
  #** Remarks: In proc. CloseUntilMark only the commands from the 'MARK'
  #**          sign to the end of the commandArray will be executed.
  #**
  #***************************************************************

  proc InsertMark {} {
  
    variable commandArray
 
    set newElementIndex [ array size commandArray ]    
    set commandArray($newElementIndex) "MARK"
  }


  #***************************************************************
  #**
  #** ExcludeCommand
  #**
  #** Abstract: Exclude the command from the commandArray.(see InsertCommand proc.) 
  #**
  #** Inputs: 'ip_command' the command to be exclude.
  #**     
  #** Outputs:
  #**
  #** Usage: RLClose::ExcludeCommand 'command'
  #**
  #** Remarks: The command will be exclude from the list of commands (commandArray)
  #**          to be execute when exiting from TCL script.
  #**
  #***************************************************************

  proc ExcludeCommand {ip_command} {
  
    global gMessage
    variable commandArray
  
    set arrayList [array get commandArray ]
   
   
    set elementPlace [ lsearch $arrayList $ip_command ]
    # if the command dose not exist
    if { $elementPlace < 0 } {
      set gMessage "Can't exclude command '$ip_command', no such command in array"
      RLEH::Handle SAsystem gMessage
    }
    set elementIndex [ lindex $arrayList [ expr $elementPlace - 1 ]]
    #inserting ' NULL ' only to fill the place and keep the array numeric order.
    set commandArray($elementIndex) "NULL"
  }


  #***************************************************************
  #**
  #** CloseUntilMark
  #**
  #** Abstract: Execute commands in commandArray.(see InsertCommand proc.) 
  #**           from the end of the array until the first MARK.
  #**
  #** Inputs: 
  #**     
  #** Outputs:
  #**
  #** Usage: RLClose::CloseUntilMark
  #**
  #** Remarks: 
  #**
  #***************************************************************

  proc CloseUntilMark {} {

    variable commandArray

    set lastElementIndex [ expr [ array size commandArray ] - 1 ]
  
    for {set command ""} {$command != "MARK" } {incr lastElementIndex -1} {
      set command [set commandArray($lastElementIndex)]
      if { $command != "MARK" } {
        if { $command != "NULL" } {
          eval [ set commandArray($lastElementIndex) ] 
        }
        unset commandArray($lastElementIndex)
      }
      if { $command == "MARK" } {
        unset commandArray($lastElementIndex)
      }
    }
  } 


  #***************************************************************
  #**
  #** CloseAll
  #**
  #** Abstract: Execute all commands from the commandArray.(see InsertCommand proc.) 
  #**
  #** Inputs: 
  #**     
  #** Outputs:
  #**
  #** Usage: RLClose::CloseAll
  #**
  #** Remarks: The proc. will execute all commands in commandArray
  #**          ignoring the 'MARK' signs.
  #**
  #***************************************************************

  proc CloseAll {} {

    variable commandArray

    set lastElementIndex [ expr [ array size commandArray ] - 1 ]
  
    for {} {$lastElementIndex >= 0} {incr lastElementIndex -1} {
      set command [ set commandArray($lastElementIndex) ]
      if { ($command != "MARK") && ($command != "NULL") } {
        eval [ set commandArray($lastElementIndex) ] 
      }
      unset commandArray($lastElementIndex)
    }
  } 

}






