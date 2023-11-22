set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_181\\bin
set gaSet(pioType) Ex
set gaSet(tester) $gaSet(pair)
switch -exact -- $gaSet(tester) {
  1 {
      set gaSet(comMC.1.1) 5
      set gaSet(comMC.1.2) 6
      set gaSet(comMC.2.1) 7
      set gaSet(comMC.2.2) 8
      set gaSet(comMC.1.d) 9
      set gaSet(comMC.2.d) 10
      set gaSet(com204)    2
      set gaSet(com220)    4
      set gaSet(comDXC)    1  
          

      console eval {wm title . "Con 1"}     
      
      set gaSet(pioRB1)    1
      set gaSet(pioRB2)    2        
  }
  2 {
      set gaSet(comMC1)    9
      set gaSet(comMC2)    10
      set gaSet(com204)    11
      set gaSet(com220)    12
      set gaSet(comDXC)    13            

      console eval {wm title .  "Con 21"}     
      
      set gaSet(pioRB1)    1
      set gaSet(pioRB2)    2    
  }
}  
source Lib_PackSour_ETX5300A-MC.tcl