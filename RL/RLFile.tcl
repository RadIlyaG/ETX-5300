#.........................................................................................
#   File name: RLFile.tcl 
#   Written by yakov  4.5.1999 
#   Version 1.0 containing procedures that work with *.ini files
#
#   Abstract: This library deals whith files. 
#   
#   Librery Contents:
#           - Del
#           - Echo 
#           - Ech 
#           - Type
#           - IniSetItem  
#           - IniGetItem
#											-	Setseeksection
#											- Getseeksection
#   Examples: 
#                                 delete file d:\\tclwork\\resume
#     RLFile::Del d:\\tclwork\\resume
#                                 echo to file
#     RLFile::Echo d:\\tclwork\\resume "Hi Word"
#                                 echo to file nonewline
#     RLFile::Ech d:\\tclwork\\resume "Hi Word"

#                                 type the file
#     RLFile::Type d:\\tclwork\\resume 
#..........................................................................................

#package require  RLEH 1.0
package provide RLFile 1.12

namespace eval RLFile { 
 
 namespace export Echo Ech Type Del Inigetitem Inisetitem Setseeksection Getseeksection

 global gMessage
 set gMessage " "


# .............................. Echo .....................................
#    
#   Abstract:echo data to file 
#       
#   Inputs: 1 - filename,2 - data to echo to the file.
#                  
#   Outputs: 
#   
# ................................................................................

 proc Echo { ip_fileName ip_data } {
  set buffer ""
  # if file exist ,openfile for read & write
  if { [file exists $ip_fileName ] } {
   set id [ open $ip_fileName r+ ]
   } else {
   set id [ open $ip_fileName w+ ]
  }
  # puts all file contentcs  to buffer
  set buffer [ read $id ]
  close $id
  append buffer $ip_data
  # destroy all contentcs of file
  set id [ open $ip_fileName w+ ]
  puts $id $buffer
  close $id
 }
# .............................. Ech ......................................
#    
#   Abstract:echo data to file nonewline
#       
#   Inputs: 1 - filename,2 - data to echo to the file.
#                  
#   Outputs: 
#   
# ................................................................................

 proc Ech { ip_fileName ip_data } {
  set buffer ""
  # if file exist ,openfile for read & write
  if { [file exists $ip_fileName ] } {
   set id [ open $ip_fileName r+ ]
   } else {
   set id [ open $ip_fileName w+ ]
  }
  # puts all file contentcs  to buffer
  set buffer [ read $id ]
  close $id
  append buffer $ip_data
  # destroy all contentcs of file
  set id [ open $ip_fileName w+ ]
  puts -nonewline $id $buffer
  close $id
 } 
# .............................. Type .....................................
#    
#   Abstract:types file contentcs.
#       
#   Inputs: filename.
#                  
#   Outputs: 
#   
# ................................................................................

 proc Type { ip_fileName } {

   global gMessage  

   if { ! [ file exist $ip_fileName] } {
   set gMessage "Filename $ip_fileName not exist ."
   return [RLEH::Handle SAsyntax gMessage]
  } else {
   set id [ open $ip_fileName r ]
   set buffer [ read $id ]
   close $id
   return $buffer
  }
 }
# .............................. Del .....................................
#    
#   Abstract:del file.
#       
#   Inputs: filename.
#                  
#   Outputs: 
#   
# ................................................................................

 proc Del { ip_fileName } {

   global gMessage  

   if { [ file exist $ip_fileName] } {
   file delete -force $ip_fileName
  } else {
    set gMessage "Filename $ip_fileName not exist ."
    return [RLEH::Handle SAsyntax gMessage]
  } 
 }

#***************************************************************************
#** IniSetItem 
#** Set the value of a specified item in a standard configuration file.
#**   1. Copy the original inifile (dest) to tmp.tmp (src)
#**   2. Open src for reading and dest for writing.
#**   3. Search for the section name. Copy the lines from src to dest while 
#**      searching.
#**   4. Search for the item inside the section. Continue to copy lines.
#**   5. Edit the line of the item and write it with the new value.
#**   6. Copy all the rest.
#** 
#** 
#** Arguments:
#** ip_file        - The name of the configuration file.
#** ip_section     - In which section the required item is located. The section should be 
#**                  specified without the [].
#** ip_item        - The name of the item in the configuration file.
#** ip_newVal      - The new value of the item.
#** 
#** Return codes: 
#**  
#**   0   - OK
#**  -1  - Error, section not found
#**  -2  - Error, item not found
#**  -3  - Couldn't  open file.
#***************************************************************************
proc Inisetitem {ip_file ip_section ip_item ip_newVal op_errMsg} {

  global gMessage
  upvar $op_errMsg gMessage

  set bakFile [file rootname $ip_file]
  append bakFile .bak
  
  if {![file exists $ip_file]} {
    set gMessage "File $ip_file does not exist"
    return -3
  }
  
  file copy -force $ip_file $bakFile

  if [catch {open $ip_file w} destId] {
    set gMessage $destId
    append gMessage "Couldn't  open file"
    return -3
  }

  if [catch {open $bakFile r} srcId] {
    set gMessage $destId
    append gMessage "Couldn't  open file"
    return -3

  }

  # Find the section:
  set accessPosition [Setseeksection $srcId $destId $ip_section]

  if {$accessPosition < 0 } { 
    close $srcId
    close $destId
    file copy -force $bakFile $ip_file 
    set gMessage "Section \[$ip_section\] does not exist" 
    return -1  

  } 
  
  #Add the sufix "=" to the item name
  set item $ip_item=
  
  while {[gets $srcId line] >= 0} {

    #If another section is reached while searching for the reqired item: 
    if {[string first \[ $line] == 0} {
      close $srcId
      close $destId
      file copy -force $bakFile $ip_file 
      set gMessage "Item \"$ip_item\" does not exist" 
      return -2

    }
    
    #If item found:
    if {[string match $item* $line]} {
        puts $destId $item$ip_newVal
        while {[gets $srcId line] >= 0} {
          puts $destId $line
        }
        close $srcId
        close $destId
        return 0
    }
  
    puts $destId $line
  }
  #If section found but item not found:
  close $srcId
  close $destId
  file copy -force $bakFile $ip_file 
  set gMessage "Item \"$ip_item\" does not exist" 
  return -2

}

#***************************************************************************
#** IniGetItem 
#** Get the value of a specified item from a standard configuration file.
#** 
#** Arguments:
#** ip_file        - ID of the configuration file.
#** ip_section     - In which section the required item is located. The section should be 
#**                  specified without the [].
#** ip_item        - The name of the item in the configuration file.
#** OP_itemVarName - The name of the variable where the item's value shouls be stored.
#** 
#** Return codes: 
#**  
#**   0   - OK
#**  -1  - Error, section not found
#**  -2  - Error, item not found
#**  -3  - Error, iniFile not found  
#***************************************************************************
proc Inigetitem {ip_file ip_section ip_item OP_itemVarName op_errMsg} {

  global gMessage
  upvar $op_errMsg gMessage
  upvar $OP_itemVarName itemVal
 

  if [catch {open $ip_file r} fileId] {
    set gMessage $fileId 
    append gMessage "Error, iniFile not found"
    return -3

  }   

  set accessPosition [Getseeksection $fileId $ip_section]
  if {$accessPosition < 0 } { 
    close $fileId
    set gMessage "Section \[$ip_section\] does not exist" 
    return -1
  }

  #Add the sufix "=" to the item name
  set item $ip_item=
  
  while {[gets $fileId line] >= 0} {

    #If another section is reached while searching for the reqired item: 
    if {[string first \[ $line] == 0} {
      close $fileId
      set gMessage "Item \"$ip_item\" does not exist" 
      return -2
    }
    
    #If item found:
    if {[string match $item* $line]} {
      seek $fileId [expr [string length $item] - [string length $line] - 2]  current 
      gets $fileId itemVal
      close $fileId
      return 0
    }
  }
  
  #If item was not found:
  close $fileId
  set gMessage "Item \"$ip_item\" does not exist" 
  return -2
}
#***************************************************************************
#** 
#** GetSeekSection:
#** 
#** Find the required section and return the location of the first item.
#** 
#** Exceptions: return -1 if section was not found
#***************************************************************************
proc Getseeksection {ip_fileId ip_section} {

    global gMessage
    set section \[$ip_section\]
    #semion disable seek because of influence on RLExcel 
    #seek $ip_fileId 0 start 
    # Find section:  

    while {[gets $ip_fileId line] >= 0} { 
        set matchResult [string compare $section $line]
        if {$matchResult == 0} {
            return [tell $ip_fileId ]
        }
    }

    # If the section was not found:
    set gMessage "Error, section not found"
    return -1
}

#***************************************************************************
#** SetSeekSection
#** 
#** 
#** Find the required section and return the location of the first item.
#** 
#** Exceptions: return -1 if section was not found
#***************************************************************************
proc Setseeksection {ip_srcFileId ip_destFileId ip_section}  {

    global gMessage
    set section \[$ip_section\] 
    #semion disable seek because of influence on RLExcel 
    #seek $ip_srcFileId 0 start  
    #seek $ip_destFileId 0 start 

    # Find section:  

    while {[gets $ip_srcFileId line] >= 0} { 
        set matchResult [string compare $section $line]
        puts $ip_destFileId $line
        if {$matchResult == 0} {
            return [tell $ip_srcFileId ]
        }
    }

    # If the section was not found:
    set gMessage "Error, section not found"
    return -1
}
 
}
