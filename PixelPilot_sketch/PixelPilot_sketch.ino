
#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
  #include <avr/power.h>
#endif

// *********************** LED strip
#define LED 6

// Parameter 1 = number of pixels in strip
// Parameter 2 = Arduino pin number (most are valid)
// Parameter 3 = pixel type flags, add together as needed:
//   NEO_KHZ800  800 KHz bitstream (most NeoPixel products w/WS2812 LEDs)
//   NEO_KHZ400  400 KHz (classic 'v1' (not v2) FLORA pixels, WS2811 drivers)
//   NEO_GRB     Pixels are wired for GRB bitstream (most NeoPixel products)
//   NEO_RGB     Pixels are wired for RGB bitstream (v1 FLORA pixels, not v2)
Adafruit_NeoPixel strip = Adafruit_NeoPixel(64, LED, NEO_GRB + NEO_KHZ800);

// *********************** Serial Port
// A string to hold our incoming serial command
String g_serialString = "";

void setup(){  
  Serial.begin(57600);  
  Serial.flush();

  strip.begin();
  strip.show();
}

void loop(){
  readSerial();  
  delay(10);
}

void pushColor(int r, int g, int b) {
  uint32_t color = strip.Color(r, g, b);
}

void parseSerialString() {
  if(g_serialString.length() > 0) {

    
    
    // Command strings will look like:
    // x:7|y:2|r:234|g:188|b:164
    
    Serial.print("Parsing command: ");
    Serial.println(g_serialString); 

    // First split by '|'
    int firstPipeIndex = g_serialString.indexOf('|');
    int secondPipeIndex = g_serialString.indexOf('|', firstPipeIndex+1);
    int thirdPipeIndex = g_serialString.indexOf('|', secondPipeIndex+1);
    int fourthPipeIndex = g_serialString.indexOf('|', thirdPipeIndex+1);

    // Check for errors
    if (firstPipeIndex == -1 || secondPipeIndex == -1 || thirdPipeIndex == -1 || fourthPipeIndex == -1 ) {
       Serial.println("Error parsing command");
       g_serialString = "";
       return; 
    }

    
    // Create each substring "x:7
    String xSet = g_serialString.substring(0, firstPipeIndex);
    String ySet = g_serialString.substring(firstPipeIndex+1, secondPipeIndex);
    String rSet = g_serialString.substring(secondPipeIndex+1, thirdPipeIndex);
    String gSet = g_serialString.substring(thirdPipeIndex+1, fourthPipeIndex);
    String bSet = g_serialString.substring(fourthPipeIndex); // To the end of 
    
    int xColonIndex = xSet.indexOf(':');
    String xString = xSet.substring(0, xColonIndex);
    int x = xString.toInt();

    int yColonIndex = ySet.indexOf(':');
    String yString = ySet.substring(0, yColonIndex);
    int y = yString.toInt();

    int rColonIndex = rSet.indexOf(':');
    String rString = rSet.substring(0, rColonIndex);
    int r = rString.toInt();

    int gColonIndex = gSet.indexOf(':');
    String gString = gSet.substring(0, gColonIndex);
    int g = gString.toInt();

    int bColonIndex = gSet.indexOf(':');
    String bString = gSet.substring(0, bColonIndex);
    int b = bString.toInt();

    
    Serial.print("\tx: ");
    Serial.println(x);  

    Serial.print("\ty: ");
    Serial.println(y);  

    Serial.print("\tr: ");
    Serial.println(r);  

    Serial.print("\tg: ");
    Serial.println(g);  

    Serial.print("\tb: ");
    Serial.println(b);  

    // Clear for next command
    g_serialString = "";

    // Send color to LED grid
    pushColor(r, g, b);
    
  }
}

void readSerial(){
    //expect a string like wer,qwe rty,123 456,hyre kjhg,
  //or like hello world,who are you?,bye!,
  while (Serial.available()) {
    delay(1);  //small delay to allow input buffer to fill
    char c = Serial.read();  //gets one byte from serial buffer
    if (c == '\n') {
      parseSerialString();
      return;
    } 
    g_serialString += c; //makes the string readString
  }

  
}
  
  
  



