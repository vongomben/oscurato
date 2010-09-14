
void initComponents() {

  String addresses[] = {"/layer1/clip1/connect", ""};
  MButton button1 = new MButton( addresses, 6);
  
  Button button2 = new Button("/layer1/clip2/connect", 7);
  Button button3 = new Button("/layer2/clip1/connect", 8);
  Button button4 = new Button("/layer2/clip2/connect", 9);
  Button button5 = new Button("/layer3/clip1/audio/position/direction", 10);
  Button button6 = new Button("/layer3/clip1/audio/position/direction", 11);
  Button button7 = new Button("/track1/connect", 12);
  Button button8 = new Button("/track2/connect", 13);
  Button[] btns = { button1, button2, button3, button4, button5, button6, button7, button8  };
  buttons = btns;

  hd = new HD("/layer1/clip1/video/position/values");

  MPot pot1_0 = new MPot("/layer2/clip1/video/position/speed",  0, "", 0f, 1023f, 0f, 1f);
  MPot pot1_1 = new MPot("/layer3/video/opacity/values", 1, "", 0f, 1023f, 0f, 1f);
  MPot pot1_2 = new MPot("/layer2/clip1video/position/speed", 2, "", 0f, 1023f, 0f, 1f);
  MPot pot1_3 = new MPot("/layer1/video/opacity/values", 3, "", 0f, 1023f, 0f, 1f);
  MPot pot1_4 = new MPot("/layer4/video/opacity/values", 4, "", 0f, 1023f, 0f, 1f);
  MPot pot1_5 = new MPot("/composition/link4/values", 5, "", 0f, 1023f, 0f, 1f);
  MPot pot1_6 = new MPot("/composition/link3/values", 6, "", 0f, 1023f, 0f, 1f);
  MPot pot1_7 = new MPot("/composition/link4/values", 7, "", 0f, 1023f, 0f, 1f);
  
  //analog pin 8 is the harddisk
  
  // free analog pin (1,2 on arduino board) left.
  MPot pot1_9 = new MPot("/composition/link3/values",   9, "", 0f, 1023f, 0f, 1f);
  MPot pot1_10 = new MPot("/composition/link4/values", 10, "", 0f, 1023f, 0f, 1f);

  
  MPot[] mpots1 = { pot1_0 , pot1_1, pot1_2, pot1_3, pot1_4, pot1_5, pot1_6, pot1_7, pot1_9, pot1_10 };
  pots = mpots1;
  
  
}
