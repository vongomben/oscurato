import processing.serial.*;

//---------------------------------------------------------------- imports
import netP5.*;
import oscP5.*;
import processing.core.PApplet;
import cc.arduino.Arduino;

//---------------------------------------------------------------- global vars
Arduino arduino;
OscP5 osc;
NetAddress remote;
OscBundle bundle;

Button[] buttons;
MPot[] pots;
HD hd;

// average length
int num = 15;
int index = 0;


//---------------------------------------------------------------- setup
void setup() {

  setupgui();
  arduino = new Arduino(this, "COM6", 57600);
  // init arduino
  println(Arduino.list());


  // buttons
  arduino.pinMode(13, Arduino.INPUT);
  arduino.pinMode(12, Arduino.INPUT);
  arduino.pinMode(11, Arduino.INPUT);
  arduino.pinMode(10, Arduino.INPUT);
  arduino.pinMode(9, Arduino.INPUT);
  arduino.pinMode(8, Arduino.INPUT);
  arduino.pinMode(7, Arduino.INPUT);
  arduino.pinMode(6, Arduino.INPUT);
  arduino.pinMode(5, Arduino.INPUT);

  /* FIRMATA NEEDS:
   *
   *  MULTIPLEXER S0, S1, S2 IN DIGITAL PIN 2,3,4
   *              Z IN ANALOIG 0
   *            
   *  HD IN ANALOG PIN 3, 4, 5 (plus ground pin)
   *
   
   *  AND INCOMING ANALOG PINS:
   MULTIPLEXER IN: analog pin 0..7
   HD IN analog pin 8   
   OTHERS IN: analog pin left (1,2): 9, 10
   */

  // init osc
  osc = new OscP5(this,7001);
  remote = new NetAddress("127.0.0.1",7000);
  bundle = new OscBundle();

  initComponents();
}

//---------------------------------------------------------------- draw
void draw() {
  gui();
  sensors(); 
}
void sensors() {
  int i=0;

  // digitals
  Button btn;
  for (i=0; i<buttons.length; i++) {
    btn = buttons[i];
    btn.pick();
  }

  // pots
  MPot m;
  for (i=0; i<pots.length; i++) {
    m = pots[i];
    //if (i!=1) continue;
    m.pick();
  }

  index++;
  if (index>=num-1) {
    index = 0;
  }  

  // one hardisk
  hd.pick();
}

//---------------------------------------------------------------- arduino input base class
class ArduinoInput {

  String address;
  int pin;
  OscMessage myMessage;
  float value = 0;

  ArduinoInput(String address, int p) {
    this.address = address;
    this.pin = p; 
    this.myMessage = new OscMessage(address);
  }

  void sendOsc() {
    sendOsc(this.address);
  }
  
  void sendOsc(String a) {
    myMessage.setAddrPattern(a);
    myMessage.add(value);

    println("value: "+value+" myMessage: "+myMessage);

    osc.send(myMessage, remote);
    //osc.send(bundle, remote);
    myMessage.clear(); 

  } 
}




