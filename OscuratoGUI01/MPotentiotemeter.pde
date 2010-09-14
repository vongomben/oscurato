class MPot extends ArduinoInput {
  
  float total = 0;
  
  // initial values are set at 0
  float vals[];

  float inm, inM, outm, outM;

  MPot(String address, int p, String foo, float inm, float inM, float outm, float outM) {
    super(address, p);

    this.inm = inm;
    this.inM = inM;
    this.outm = outm;
    this.outM = outM;

    vals = new float[num];
    for (int i=0; i<num; i++) this.vals[i] = 0.0f;
  }

  void pick() {
    // read
    float val = arduino.analogRead(pin);
    
    // compute new average
    float newAverage = doSmooth(val);

    // if change..
    if ( newAverage != this.value) {
      value = newAverage;
      sendOsc();
    }
  }

  float doSmooth(float value) {
    float newAverage = 0f;
    float t = 0;

    total = total - vals[index];
    t = PApplet.map(value, inm, inM, outm, outM);
    vals[index] = t;
    total = total + vals[index];
    newAverage = total/num;

    // math for truncation. es: 3.1415926535897931 ---> 3.141
    newAverage = ( (float) ( (int) (newAverage * 100.0f) ) ) / 100.0f ;
    
    return newAverage;
  }
}

