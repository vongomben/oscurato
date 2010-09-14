class HD extends ArduinoInput {
  
  HD(String address) {
    super(address, 0); 
  }
     float newValue=0; // keep it out to be absolut
  int oldVal = 0;
  void pick() {
   
  
     //float newValue=0;
  
  //float newValue= map(arduino.analogRead(8), 0, 100, -1, 1 );
          int val = arduino.analogRead(8);
          if (val==16383) 
            newValue=newValue-0.01;
          if (val==1)
            newValue=newValue+0.01;
          if (val > oldVal) newValue = newValue+0.01;
          if (val < oldVal) newValue = newValue-0.01;
          oldVal= val;
  
     //  println(">>>>> "  + arduino.analogRead(8));
   // println(newValue);
      //  println("HD > pick > newvalue="+newValue);
  
      // check changes
    
    // check canges
    if (newValue != value) {
      value = newValue;
      sendOsc();
    }  
  }

}




