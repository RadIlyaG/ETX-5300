puts "inside LibGuiPageSetup.tcl File" ; update

# ***************************************************************************
# Gui_Page_Setup                                          PageSetupGui (1/7)
# ***************************************************************************
proc Gui_Page_Setup {base} {
  global gaGui gaSet
   
  #Comment: gui for adding files
  if {[winfo exists $base]} {
    wm deiconify $base
    return
  }
  
  toplevel $base   
  wm protocol $base WM_DELETE_WINDOW "destroy $base"
  wm focusmodel $base passive
  wm overrideredirect $base 0
  wm resizable $base 0 0
  wm deiconify $base
  wm title $base "Tester$gaSet(tester) Page Setup"
  
  set fra [frame $base.fra -bd 2 -relief groove]
   set frm1 [frame $fra.frm1 -bd 0 -relief groove]
     set lab1 [label $frm1.lab -text "Please create Page0-3 setup in Hex mode ..." \
     -width 130]
     pack $lab1  -side left 
   pack $frm1 -expand 1 -fill both -pady 15 -padx 3
   
 
   # File PageSetup:
   set frmPageSetup [frame $fra.frmPageSetup -bd 0 -relief groove]
     set labPageSetup [label $frmPageSetup.labPageSetup -text "File Name:" -width 21]     
     set gaGui(entPageSetup) [label $frmPageSetup.entPageSetup -textvariable gaSet(PageSetup_Partial_path) \
        -relief sunken -bd 2 -width 39 -bg SystemWindow]
     set gaGui(butPageSetup) [button $frmPageSetup.butPageSetup -text "Browse.." -command {OpenFileDialog2 PageSetup}]
     pack $labPageSetup $gaGui(entPageSetup) $gaGui(butPageSetup) -side left -padx 2
   pack $frmPageSetup  -fill x -pady 5         
   
   for {set i 0} {$i<=3} {incr i} {
     set frmP$i [frame $fra.fraP$i -bd 0 -relief groove]
       set labP$i [label [set frmP$i].labP$i -text "Page $i - " -width 21]
       pack [set labP$i] -side left -padx 2
       for {set id 0} {$id<=31} {incr id} {
         set gaGui(Page$i.Ent$id) [Entry [set frmP$i].page[set i]ent[set id] -textvariable gaSet(Page$i.Ent$id) \
           -relief sunken -bd 2 -width 3 -bg SystemWindow -justify center \
           -dropenabled 1 -dragenabled 1 -dragevent 3 -dropcmd {PageButRel3} \
           -validate key \
           -vcmd {expr {[string is xdigit %P] && [string length %P]<=2}}]
         pack [set gaGui(Page$i.Ent$id)] -side left -padx 2
         bind $gaGui(Page$i.Ent$id) <KeyRelease> [list JumpNextCell $i $id %W]
         #$gaGui(Page$i.Ent$id) insert 0 "00"               
       }       
     pack [set frmP$i]  -fill x -pady 3
   }
      
   set fra3 [frame $fra.fra3 -bd 0 -relief groove]
      set but1 [button $fra3.but1 -text "Accept" -command "ButAccept_01 $base" \
      -padx 4 -pady 4 -relief raised  -bd 3]
      set but2 [button $fra3.but2 -text "Cancel" -command "ButCancel $base" \
      -padx 4 -pady 4 -relief raised  -bd 3]          
      pack $but1 $but2 -side left -padx 3      
   pack $fra3 -pady 2 -padx 2  -pady 15   
         
  pack $fra -pady 5 -padx 5 -fill both -expand yes  
  
  # Get Info:  
  source InitPage.tcl

  focus -force $base
  #grab $base
}



# ***************************************************************************
# ButAccept_01                                                  SetupGui (2/7)
# ***************************************************************************
proc ButAccept_01 {base} {
  InitFile_Page 
  ButCancel $base
}

# ***************************************************************************
# ButCancel                                                    SetupGui (3/7)
# ***************************************************************************
proc ButCancel {base} {
  grab release $base
  focus .
  destroy $base
}

##***************************************************************************
##** OpenFileDialog2                                          SetupGui (4/7)
##**                  ext: Apl;DefApl1;DefApl2;Bist;DefConfig;PageSetup
##***************************************************************************
proc OpenFileDialog2 {ext} {
  global gaGui gaSet
  
  set types {{"ALL files"  *}}
	  
  set fullName [tk_getSaveFile -filetypes $types \
    -initialdir "c:\\$ext" -title "Create a file ..."] 
	 
  if {$fullName==""} {
    set gaSet($ext) $gaSet($ext)
  } else {
    set gaSet($ext) $fullName
  }
  
  # convert to .txt extension  ----------
  if {[file extension $gaSet($ext)]==""} {
    set gaSet($ext) [set gaSet($ext)].txt
  }  
  if {[file extension $gaSet($ext)]!=".txt"} {
    regsub {\.\w*} $gaSet($ext)  ".txt" gaSet($ext)
  }  
  #---------------------------------------
  
  
  #----
  set lpath [file split $gaSet([set ext])]
  if {[llength $lpath]>3} {
    set gaSet([set ext]_Partial_path) ".../[lindex $lpath [expr [llength $lpath]-2]]/[lindex $lpath end]"
  } else {
    set gaSet([set ext]_Partial_path) $gaSet([set ext])
  }
  #----

  return {}
}

##***************************************************************************
##** InitFile_Page                                           SetupGui (5/7)                                   
##***************************************************************************
proc InitFile_Page {} {
  global gaGui gaSet
  
  if {$gaSet(PageSetup)!="?"} {
    # Create page File:
    for {set i 0} {$i<=3} {incr i} {
      lappend gaInfo(Page.$i) Page $i -
    }  
    for {set i 0} {$i<=3} {incr i} {
      for {set id 0} {$id<=31} {incr id} {
        set gaSet(Page$i.Ent$id) [string toupper $gaSet(Page$i.Ent$id)]
        lappend gaInfo(Page.$i) $gaSet(Page$i.Ent$id)      
      }
    }    
    set fileId [open $gaSet(PageSetup) w]
    seek $fileId 0 start
    for {set i 0} {$i<=3} {incr i} {
      puts $fileId "$gaInfo(Page.$i)"
    }
    close $fileId
  }
  
  # update Init Page File:
  set fileId [open InitPage.tcl w]
  seek $fileId 0 start
  puts $fileId "puts \"inside InitPage.tcl File\" ; update"
  puts $fileId "set gaSet(PageSetup) \"$gaSet(PageSetup)\""
  puts $fileId "set gaSet(PageSetup_Partial_path) \"$gaSet(PageSetup_Partial_path)\""
  for {set i 0} {$i<=3} {incr i} {
    for {set id 0} {$id<=31} {incr id} {
      puts $fileId "set gaSet(Page$i.Ent$id) \"$gaSet(Page$i.Ent$id)\""
    }
  }
  close $fileId
}

# ***************************************************************************
# JumpNextCell                                                SetupGui (6/7)  
# ***************************************************************************
proc JumpNextCell {i id w} {
  global gaGui gaSet
  set nextCol $id
  set nextRow $i
 
  set txt [$w cget -text]  
  #puts "txt:$txt"
  if {[string length $txt]==2} {
    
    # color:
    $gaGui(Page$i.Ent$id) configure -bg yellow

    # jump next cell:
    if {$id>=0 && $id<31} {
      ## inside a row
      set nextCol [expr {$id+1}]
      set nextRow $i
    }
    if {$id==31 && $i<3} {
      ## last cell in 3 1st. rows
      set nextCol 0
      set nextRow [expr {$i+1}]
    }
    if {$id==31 && $i==3} {
      ## last cell in 4th. row
      set nextCol $id
      set nextRow $i
    }   
    focus $gaGui(Page$nextRow.Ent$nextCol)
    $gaGui(Page$nextRow.Ent$nextCol) selection range 0 end
  }
  
  #puts "row:$i col:$id nextCol:$nextCol nextRow:$nextRow w:$w"
  return {}
}

# ***************************************************************************
# PageButRel3                                              SetupGui (7/7)  
# ***************************************************************************
proc PageButRel3 {args} {
  set dropTarget [lindex $args 0]
  set txt [lindex $args 5] 
  if {[string length $txt]<=2} {
    #puts "PageButRel3 w:$args dropTarget:$dropTarget" 
    $dropTarget configure -text $txt
    update idletasks
  }
  #puts [$dropTarget cget -text]
  return 1
}