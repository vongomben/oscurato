color off = color(4, 79, 111);
color on = color(184, 245, 258);

color ctext = color(255);

int ty_btn = 50;
int space_btn = 25;
int BUTTON_NUMBER = 13;

int ty_pot = 50;
int space_pots = 30;
int POT_NUMERS = 10;


PFont font;

void setupgui() {
  size(600, 500);
  smooth();
  font = loadFont("font.vlw");  
}

void gui() {

  int 
    x = 0,
  y = 0;

  float t = 0;

  background(off);
  stroke(on);

  // buttons rect
  fill(ctext);
  text("BUTTONS", 25, ty_btn-20);
  for (int i = 0; i < buttons.length; i++) {
    x = 25;
    y = i * space_btn + ty_btn;

    fill(ctext);
    text(i, x, y);

    if (arduino.digitalRead(buttons[i].pin) == Arduino.HIGH) fill(on);
    else fill(off);
    rect(x+15, y-10, 25, 10);

    if (i<buttons.length) {
      fill(ctext);
      text(buttons[i].address, x+55, y); 
    }
  }

  // pots circles
  fill(ctext);
  text("MULTIPLEXED POTS", width/2, ty_pot-20);
  for (int i = 0; i < POT_NUMERS; i++) {
    x = width/2;
    y = i * space_pots + ty_pot;

    t = arduino.analogRead(i);
    fill(off);
    ellipse(x, y, t / 20, t / 20);

    fill(ctext);
    text(pots[i].value, x-15, y+5);
    
    if (i<pots.length) {
      fill(ctext);
      text(pots[i].address, x+40, y); 
    }

  }

  // hd ^___^
  t = arduino.analogRead(8);
  t = constrain(t, 0, 500);
  t = map(t, 0, 500, 20, 200);

  fill(ctext);
  y += 70;
  text("SCRATCH", x, y);
  text(hd.value, x+20, y+20);
  text(hd.address, x+20, y+50);
  fill(on);
  ellipse(x, y+20, t / 16, t / 16);  
  
  
  text("ARDUiNO OSC BRiDGE CONTROLLER, LPM 2010", 50, y+150);
  
}


