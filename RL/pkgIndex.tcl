# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

package ifneeded RL10GbGen 1.3.2 [list source [file join $dir RL10GbGen.tcl]]
package ifneeded RLClose 1.0 [list source [file join $dir RLClose.tcl]]
package ifneeded RLCom 4.21 [list source [file join $dir RLCom.tcl]]
package ifneeded RLDCom 4.2 [list load [file join $dir RLDCom.dll]]
package ifneeded RLDExPio 1.65 [list load [file join $dir RLDExPio.dll]]
package ifneeded RLDMeght 2.0 [list load [file join $dir RLDMeght.dll]]
package ifneeded RLDMfour 2.0 [list load [file join $dir RLDMfour.dll]]
package ifneeded RLDPio 2.0 [list load [file join $dir RLDPio.dll]]
package ifneeded RLDTcp 4.0 [list load [file join $dir RLDTcp.dll]]
package ifneeded RLDTime 2.0 [list load [file join $dir RLDTime.dll]]
package ifneeded RLDxc4 1.42 [list source [file join $dir RLDxc4.tcl]]
package ifneeded RLEH 1.04 [list source [file join $dir RLEH.tcl]]
package ifneeded RLEMux 3.0 [list source [file join $dir RLEMux.tcl]]
package ifneeded RLEtxGen 1.21 [list source [file join $dir RLEtxGen.tcl]]
package ifneeded RLExEMux 1.0 [list source [file join $dir RLExEMux.tcl]]
package ifneeded RLExHfmux 0.0 [list source [file join $dir RLExHfmux.tcl]]
package ifneeded RLExMmux 0.0 [list source [file join $dir RLExMmux.tcl]]
package ifneeded RLExMux2514 1.0 [list source [file join $dir RLExMx2514.tcl]]
package ifneeded RLExMux818 1.0 [list source [file join $dir RLExMx818.tcl]]
package ifneeded RLExPio 1.65 [list source [file join $dir RLExPio.tcl]]
package ifneeded RLFile 1.12 [list source [file join $dir RLFile.tcl]]
package ifneeded RLHfmux 0.0 [list source [file join $dir RLHfmux.tcl]]
package ifneeded RLLpt 1.0 [list source [file join $dir RLLpt.tcl]]
package ifneeded RLMmux 0.0 [list source [file join $dir RLMmux.tcl]]
package ifneeded RLMux2514 2.0 [list source [file join $dir RLMx2514.tcl]]
package ifneeded RLMux818 2.0 [list source [file join $dir RLMx818.tcl]]
package ifneeded RLPio 2.0 [list source [file join $dir RLPio.tcl]]
package ifneeded RLScotty 1.2 [list source [file join $dir RLScotty.tcl]]
package ifneeded RLScreen 1.01 [list source [file join $dir RLScreen.tcl]]
package ifneeded RLSerial 1.1 [list source [file join $dir RLSerial.tcl]]
package ifneeded RLSound 1.11 [list source [file join $dir RLSound.tcl]]
package ifneeded RLStatus 0.1 [list source [file join $dir RLStatus.tcl]]
package ifneeded RLTcp 4.0 [list source [file join $dir RLTcp.tcl]]
package ifneeded RLTime 3.0 [list source [file join $dir RLTime.tcl]]
package ifneeded lpttcl 3.0 [list load [file join $dir lpttcl.dll]]\n[list source [file join $dir RLLpt.tcl]]
