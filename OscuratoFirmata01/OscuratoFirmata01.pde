/*

Custom version of Standard Firmata for 
Workshop: Arduino meets Resolume
LPM 2010 Brancaleone, Roma

thanks to Cristian Megabug e Massimo Banzi

Alberto Massa, Davide Gombda

*/


/*
  Copyright (C) 2006-2008 Hans-Christoph Steiner.  All rights reserved.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 See file LICENSE.txt for further informations on licensing terms.
 
 formatted using the GNU C formatting and indenting
 */

/* 
 * TODO: use Program Control to load stored profiles from EEPROM
 */

#include <Firmata.h>
#include <Servo.h>

/*==============================================================================
 * GLOBAL VARIABLES
 *============================================================================*/

/* analog inputs */
int analogInputsToReport = 0; // bitwise array to store pin reporting
int analogPin = 0; // counter for reading analog pins

/* digital pins */
byte reportPINs[TOTAL_PORTS];   // PIN == input port
byte previousPINs[TOTAL_PORTS]; // PIN == input port
byte pinStatus[TOTAL_DIGITAL_PINS]; // store pin status, default OUTPUT
byte portStatus[TOTAL_PORTS];

/* timer variables */
unsigned long currentMillis;     // store the current value from millis()
unsigned long nextExecuteMillis; // for comparison with currentMillis
int samplingInterval = 19;      // how often to run the main loop (in ms)

Servo servos[MAX_SERVOS];

/*==============================================================================
 * FUNCTIONS
 *============================================================================*/

void outputPort(byte portNumber, byte portValue)
{
  portValue = portValue &~ portStatus[portNumber];
  if(previousPINs[portNumber] != portValue) {
    Firmata.sendDigitalPort(portNumber, portValue);
    previousPINs[portNumber] = portValue;
  }
}

/* -----------------------------------------------------------------------------
 * check all the active digital inputs for change of state, then add any events
 * to the Serial output queue using Serial.print() */
void checkDigitalInputs(void)
{
  byte i, tmp;
  for(i=0; i < TOTAL_PORTS; i++) {
    if(reportPINs[i]) {
      switch(i) {
      case 0:
        outputPort(0, PIND &~ B00000011); // ignore Rx/Tx 0/1
        break;
      case 1:
        outputPort(1, PINB);
        break;
      case ANALOG_PORT:
        outputPort(ANALOG_PORT, PINC);
        break;
      }
    }
  }
}

// -----------------------------------------------------------------------------
/* sets the pin mode to the correct state and sets the relevant bits in the
 * two bit-arrays that track Digital I/O and PWM status
 */
void setPinModeCallback(byte pin, int mode) {
  byte port = 0;
  byte offset = 0;

  // TODO: abstract for different boards
  if (pin < 8) {
    port = 0;
    offset = 0;
  } 
  else if (pin < 14) {
    port = 1;
    offset = 8;
  } 
  else if (pin < 22) {
    port = 2;
    offset = 14;
  }

  if(pin > 1) { // ignore RxTx (pins 0 and 1)
    if (isServoSupportedPin(pin) && mode != SERVO)
      if (servos[pin - FIRST_SERVO_PIN].attached())
        servos[pin - FIRST_SERVO_PIN].detach();
    if(pin > 13) 
      reportAnalogCallback(pin - 14, mode == ANALOG ? 1 : 0); // turn on/off reporting
    switch(mode) {
    case ANALOG:
      digitalWrite(pin, LOW); // disable internal pull-ups and fall thru to 'case INPUT:'
    case INPUT:
      pinStatus[pin] = mode;
      pinMode(pin, INPUT);
      portStatus[port] = portStatus[port] &~ (1 << (pin - offset));
      break;
    case OUTPUT:
      digitalWrite(pin, LOW); // disable PWM and fall thru to 'case PWM:' 
    case PWM:
      pinStatus[pin] = mode;
      pinMode(pin, OUTPUT);
      portStatus[port] = portStatus[port] | (1 << (pin - offset));
      break;
    case SERVO:
      // TODO: Support Arduino Mega
      if (isServoSupportedPin(pin)) {
        pinStatus[pin] = mode;
        if (!servos[pin - FIRST_SERVO_PIN].attached())
          servos[pin - FIRST_SERVO_PIN].attach(pin);
      } 
      else
        Firmata.sendString("Servo only on pins from 2 to 13");
      break;
    case I2C:
      pinStatus[pin] = mode;
      Firmata.sendString("I2C mode not yet supported");
      break;
    default:
      Firmata.sendString("Unknown pin mode"); // TODO: put error msgs in EEPROM
    }
    // TODO: save status to EEPROM here, if changed
  }
}

void analogWriteCallback(byte pin, int value)
{
  switch(pinStatus[pin]) {
  case SERVO:
    if (isServoSupportedPin(pin))
      servos[pin - FIRST_SERVO_PIN].write(value);
    break;
  case PWM:
    analogWrite(pin, value);
    break;
  }
}

void digitalWriteCallback(byte port, int value)
{
  switch(port) {
  case 0: // pins 2-7 (don't change Rx/Tx, pins 0 and 1)
    // 0xFF03 == B1111111100000011    0x03 == B00000011
    PORTD = (value &~ 0xFF03) | (PORTD & 0x03);
    break;
  case 1: // pins 8-13 (14,15 are disabled for the crystal) 
    PORTB = (byte)value;
    break;
  case 2: // analog pins used as digital
    byte pin;
    byte pinModeMask;
    for(pin=0; pin<8; pin++)
      if(pinStatus[pin] == OUTPUT)
        pinModeMask += 1 << pin;
    PORTC = (byte)value & pinModeMask;
    break;
  }
}

// -----------------------------------------------------------------------------
/* sets bits in a bit array (int) to toggle the reporting of the analogIns
 */
//void FirmataClass::setAnalogPinReporting(byte pin, byte state) {
//}
void reportAnalogCallback(byte pin, int value)
{
  if(value == 0) {
    analogInputsToReport = analogInputsToReport &~ (1 << pin);
  }
  else { // everything but 0 enables reporting of that pin
    analogInputsToReport = analogInputsToReport | (1 << pin);
  }
  // TODO: save status to EEPROM here, if changed
}

void reportDigitalCallback(byte port, int value)
{
  reportPINs[port] = (byte)value;
  if(port == ANALOG_PORT) // turn off analog reporting when used as digital
    analogInputsToReport = 0;
}

/*==============================================================================
 * SYSEX-BASED commands
 *============================================================================*/

void sysexCallback(byte command, byte argc, byte *argv)
{
  switch(command) {
  case SERVO_CONFIG:
    if(argc > 4) {
      // these vars are here for clarity, they'll optimized away by the compiler
      byte pin = argv[0];
      int minPulse = argv[1] + (argv[2] << 7);
      int maxPulse = argv[3] + (argv[4] << 7);

      if (isServoSupportedPin(pin)) {
        // servos are pins from 2 to 13, so offset for array
        if (servos[pin - FIRST_SERVO_PIN].attached())
          servos[pin - FIRST_SERVO_PIN].detach();
        servos[pin - FIRST_SERVO_PIN].attach(pin, minPulse, maxPulse);
        setPinModeCallback(pin, SERVO);
      }
    }
    break;
  case SAMPLING_INTERVAL:
    if (argc > 1)
      samplingInterval = argv[0] + (argv[1] << 7);
    else
      Firmata.sendString("Not enough data");
    break;
  }
}

boolean isServoSupportedPin(byte pin)
{
  return ((FIRST_SERVO_PIN <= pin) && (pin <= (FIRST_SERVO_PIN + MAX_SERVOS)));
}

/*==============================================================================
 * SETUP()
 *============================================================================*/
void setup() 
{
  byte i;

  Firmata.setFirmwareVersion(2, 1);

  Firmata.attach(ANALOG_MESSAGE, analogWriteCallback);
  Firmata.attach(DIGITAL_MESSAGE, digitalWriteCallback);
  Firmata.attach(REPORT_ANALOG, reportAnalogCallback);
  Firmata.attach(REPORT_DIGITAL, reportDigitalCallback);
  Firmata.attach(SET_PIN_MODE, setPinModeCallback);
  Firmata.attach(START_SYSEX, sysexCallback);

  portStatus[0] = B00000011;  // ignore Tx/RX pins
  portStatus[1] = B11000000;  // ignore 14/15 pins 
  portStatus[2] = B00000000;

  for(i=0; i < FIRST_ANALOG_PIN; ++i) {
    setPinModeCallback(i,OUTPUT);
  }
  // set all outputs to 0 to make sure internal pull-up resistors are off
  PORTB = 0; // pins 8-15
  PORTC = 0; // analog port
  PORTD = 0; // pins 0-7

  // TODO rethink the init, perhaps it should report analog on default
  for(i=0; i<TOTAL_PORTS; ++i) {
    reportPINs[i] = false;
  }
  // TODO: load state from EEPROM here

  /* send digital inputs here, if enabled, to set the initial state on the
   * host computer, since once in the loop(), this firmware will only send
   * digital data on change. */
  if(reportPINs[0]) outputPort(0, PIND &~ B00000011); // ignore Rx/Tx 0/1
  if(reportPINs[1]) outputPort(1, PINB);
  if(reportPINs[ANALOG_PORT]) outputPort(ANALOG_PORT, PINC);

  Firmata.begin(57600);
}

/*==============================================================================
 * LOOP()
 *============================================================================*/
void loop() 
{
  /* DIGITALREAD - as fast as possible, check for changes and output them */
  checkDigitalInputs();  
  currentMillis = millis();
  if(currentMillis > nextExecuteMillis) {  
    nextExecuteMillis = currentMillis + samplingInterval;
    /* SERIALREAD - Serial.read() uses a 128 byte circular buffer, so handle
     * all serialReads at once, i.e. empty the buffer */
    while(Firmata.available())
      Firmata.processInput();
    /* SEND FTDI WRITE BUFFER - make sure that the FTDI buffer doesn't go over
     * 60 bytes. Ideally this could send an "event character" every 4 ms to
     * trigger the buffer to dump. */

    /* ANALOGREAD - do all of the analogReads() once per poll cycle */
    
    /********************************************************************************************************/
    // here is triggeered the custom analog read - implies multiplexing cycle and harddisk encoder procedure from megabug
    lpmAnalogRead(); 
    /********************************************************************************************************/
  }
}

/***************************************************** NOW CUSTOM CODE FOR MULTIPLEXER AND HARDDISK *****/
/***************************************************** SCRATCH TABLE FOR LPM WORKSHOP *******************/
/********************************************************************************************************/
/********************************************************************************************************/
/********************************************************************************************************/
/********************************************************************************************************/
/********************************************************************************************************/
/********************************************************************************************************/


//---------- fixed multiplexer pin on arduino board
int 
s0 = 2, //digital
s1 = 3, //digital
s2 = 4, //digital
z = 0; //analog

//---------- fixed hardisk pin on arduino board
int
h0 = 1, //analog
h1 = 2, //analog
h2 = 3; //analog

void lpmAnalogRead() {
    // read multiplexer
    // interfaced inside external analog pin 0..7
    //   (other programs like processing or puredata 
    //    with standard Arduino Object are reading 
    //    multiplexed analog value with 
    //    analaog pin from 0 to 7)
    multiplexer();
    
    // HD here.
    // analog pin 8
    // (vide supra)
    hd();
    
    // analog pin left (1,2): 9, 10
    //   (inside arduino board are still free 2 analog pin, the 1 and 2
    //    and are interfaced to externals program to Arduino Object pin 9 and 10)
    Firmata.sendAnalog(9, analogRead(1)); 
    Firmata.sendAnalog(10, analogRead(2)); 
 
}

//----------------------------------------------- multiplexed code
void multiplexer() {

  pinMode(s0,OUTPUT);
  pinMode(s1,OUTPUT);
  pinMode(s2,OUTPUT);

  for(analogPin=0;analogPin<8;analogPin++) {
    //thanks to Massimo Banzi for bit wise operation mask
    
    //set bin row s1 s2 s3
    if (analogPin & 0x01)
      digitalWrite(2, HIGH );
    else
      digitalWrite(2, LOW); 

    if (analogPin & 0x02) //2° bit
      digitalWrite(3, HIGH );
    else
      digitalWrite(3, LOW); 

    if (analogPin & 0x04) //3° bit
      digitalWrite(4, HIGH );
    else
      digitalWrite(4, LOW); 

    Firmata.sendAnalog(analogPin, analogRead(z)); 
  }  
}

//----------------------------------------------- harddisk encoder from cristian megabug

int actual = -1;
int encActual = -1;

void hd() {
  if (interpolate())
    Firmata.sendAnalog(8, actual); 
}

int readEncoder() {
  int p1 = analogRead(h0);
  int p2 = analogRead(h1);
  int p3 = analogRead(h2);

  if (p1+p2+p3==0)
    return -1;

  int l = p1+p2+p3;    
  int x = (p2-p3)*86;
  int y = p1*100 - (p2+p3)*50;
  int p=-1;
  if (y>0) {
    if (abs(x) < y*57/100) 
      p=0;
    else 
      p=(x<0) ? 5 : 1;
  }
  else {
    if (abs(x) < -y*57/100) 
      p=3;
    else 
      p=(x<0) ? 4 : 2;
  }
  return p;
}

boolean interpolate() {
  int delta[] = {
    -1, -2, 0, +2, +1, 0, -1, -2, 0, +2, +1
  };
  int v = readEncoder();
  if (v==-1)
    return false;
  if (actual==-1) {
    actual = 0;
    encActual = v;
    return true;
  }

  int d = delta[v-encActual+5];
  actual += d;
  encActual = v;
  return true;
}


