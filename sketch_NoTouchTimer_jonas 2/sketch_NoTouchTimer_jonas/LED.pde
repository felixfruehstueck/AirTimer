class LED {
  int id = 0;
  float angle;
  float x;
  float y;

  //constructor
  //set ID + location, then draw.
  public LED (int i) {
    id = i;
    angle = i * TWO_PI / 60;
    x = width/2.0 + cos(angle - radians(90)) * lg_rad;
    y = width/2.0 + sin(angle - radians(90)) * lg_rad;

    ellipse(x, y, sm_diam, sm_diam);
    println(id);
  }

  //set color of this LED instance
  public void setColor (int hue, int sat, int bri) {
    fill(hue, sat, bri);
    ellipse(x, y, sm_diam, sm_diam);
  }

  //get ID of this LED instance
  public int getID() {
    return (id);
  }
}