#***************************************************************************
#** Filename: RLStatus.tcl
#** Written by Ronnie Erez  27.3.04
#**
#** Absrtact: This file activate the status message of the tester
#**
#   Procedures names in this file:
#           - Show
#** Examples:
#**	1.  RLStatus::Show -msg fti
#**	2.  RLStatus::Show -msg atp
#**
#***************************************************************************
package require RLEH
package require BWidget
package provide RLStatus 0.1

namespace eval RLStatus    {

  namespace export Show

  global gMessage


  #***************************************************************************
  #**                        RLStatus::Show
  #** Absrtact:
  #**   Show the invalid message
  #**
  #**   Inputs:  -msg (fti atp)
  #**   Outputs: error message by RLEH        if error
  #**            none								 if ok
  #***************************************************************************
  proc Show {args} {
    # default parameter
    set msg "This automatic Tester is not approved !"
	 # analyze parameters
    if {[expr [llength $args]%2]!=0} {
      set gMessage "Wrong number of parameters"
      return [RLEH::Handle SAsyntax gMessage]
    }
    foreach {prm val} "[lrange $args 0 end]"  {
      if {$prm=="-msg"} {
        switch -- $val {
          "fti" {set msg "This automatic Tester is not approved !\n\n F.T.I. doesn't match this Tester"}
          "atp" {set msg "This automatic Tester is not approved !\n\n A.T.P. is missing"}
        }
      } else {
        set gMessage "No such parameter ($prm)"
        return [RLEH::Handle SAsyntax gMessage]
      }
    }
    # create the gui
	 set base .status
	 wm withdraw .
    toplevel $base
	 set fontSize [expr int([winfo screenwidth .]/26.6666)]
    wm geometry $base [winfo screenwidth .]x[winfo screenheight .]+0+0
    wm protocol $base WM_DELETE_WINDOW {update}
    wm title $base "Warnning !!"
    wm focusmodel $base passive
    wm overrideredirect $base 1
    wm resizable $base 0 0
    wm deiconify $base

    set butOk [button $base.b1 -text "I Agree" -font "{} $fontSize {bold}" \
	     -command "destroy $base; wm deiconify ." \
        -padx 4 -pady 4 -relief raise  -bd 5]
    pack $butOk -side bottom -pady 50
    set labIcon [label $base.icon  -font "{} $fontSize {bold}" \
        -image [Bitmap::get "c:\\RLFiles\\Status\\bigError.gif"]]
    set labMsg [message $base.msg -text "$msg" -font "{} $fontSize {bold}" \
        -relief groove -justify center -width [expr $fontSize*10]]
    pack $labIcon $labMsg -side left -padx [expr $fontSize/2]
    tkwait window $base
  } 


}  ; #end name space



