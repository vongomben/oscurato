class Button extends ArduinoInput {
  
  Button(String address, int p) {
    super(address, p); 
  }
 
  void pick() {
    float newValue = arduino.digitalRead(pin);
  
    // check canges
    if (newValue != value) {
      value = newValue;
      sendOsc();
    }  
  }

}

class MButton extends Button {
  
  String addresses[];
  
  MButton(String[] addresses, int p) {
    super(addresses[0], p); 
    
    this.addresses = addresses;
  }
 
  void pick() {
    float newValue = arduino.digitalRead(pin);
    String s = "";
  
    // check canges
    if (newValue != value) {
      value = newValue;
      for(int i=0; i<this.addresses.length; i++){
        s = addresses[i];
        sendOsc(s);
      }
    }  
  }

}


