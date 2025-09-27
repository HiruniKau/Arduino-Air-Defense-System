import processing.serial.*;

Serial myPort;  // Create object from Serial class
String data;    // Data received from the serial port
int angle = 90;
int distance = 0;
int gunAngle = 90;
boolean motionDetected = false;

void setup() {
  size(800, 600); // Window size
  background(0);   // Black background
  
  // List all the available serial ports
  println("Available serial ports:");
  printArray(Serial.list());
  
  // Open the port that the Arduino is connected to (adjust the index as needed)
  String portName = Serial.list()[0]; // Change this to the correct port
  myPort = new Serial(this, portName, 9600);
  myPort.bufferUntil('\n'); // Read data until newline
  
  // Set up text rendering
  textSize(12);
}

void draw() {
  // Clear the screen with a dark background
  background(0);
  
  drawRadar();
  drawInfoPanel();
}

void drawRadar() {
  pushMatrix();
  translate(width/2, height/2); // Move origin to center
  
  // Draw radar background
  noFill();
  stroke(0, 255, 0);
  strokeWeight(1);
  for (int i = 1; i <= 5; i++) {
    ellipse(0, 0, i * 80, i * 80); // Concentric circles
  }
  
  // Draw distance markers
  fill(0, 255, 0);
  textAlign(CENTER);
  text("0", 0, -height/2 + 30);
  text("50cm", 0, -height/2 + 110);
  text("100cm", 0, -height/2 + 190);
  text("150cm", 0, -height/2 + 270);
  
  // Draw angle markers
  line(-200, 0, 200, 0);
  line(0, -200, 0, 200);
  text("0°", 200, 10);
  text("90°", 10, -200);
  text("180°", -200, 10);
  text("270°", 10, 200);
  
  // Draw radar sweep line
  float rad = radians(angle);
  float x = 250 * cos(rad);
  float y = 250 * sin(rad);
  stroke(0, 255, 0, 100);
  line(0, 0, x, y);
  
  // Draw detected object
  if (distance > 0 && distance < 50) {
    float objX = map(distance, 0, 50, 0, 250) * cos(rad);
    float objY = map(distance, 0, 50, 0, 250) * sin(rad);
    
    if (motionDetected) {
      fill(255, 0, 0); // Red for threat
      stroke(255, 0, 0);
    } else {
      fill(255, 255, 0); // Yellow for object without motion
      stroke(255, 255, 0);
    }
    
    ellipse(objX, objY, 10, 10);
    
    // Draw line to object
    line(0, 0, objX, objY);
  }
  
  // Draw gun direction
  float gunRad = radians(gunAngle);
  float gunX = 50 * cos(gunRad);
  float gunY = 50 * sin(gunRad);
  stroke(255, 0, 0);
  strokeWeight(3);
  line(0, 0, gunX, gunY);
  
  // Draw gun indicator
  fill(255, 0, 0);
  triangle(gunX, gunY, gunX-5, gunY-10, gunX+5, gunY-10);
  
  popMatrix();
}

void drawInfoPanel() {
  // Draw information panel background
  fill(0, 180);
  noStroke();
  rect(10, 10, 200, 140);
  
  // Draw panel text
  fill(0, 255, 0);
  textAlign(LEFT);
  text("Angle: " + angle + "°", 20, 30);
  text("Distance: " + distance + "cm", 20, 50);
  text("Gun Angle: " + gunAngle + "°", 20, 70);
  text("Motion: " + (motionDetected ? "DETECTED" : "None"), 20, 90);
  text("Object: " + (distance > 0 && distance < 50 ? "DETECTED" : "None"), 20, 110);
  
  // Draw status with appropriate color
  if (motionDetected && distance > 0 && distance < 50) {
    fill(255, 0, 0); // Red for threat
    text("Status: THREAT!", 20, 130);
  } else {
    fill(0, 255, 0); // Green for clear
    text("Status: Clear", 20, 130);
  }
  
  // Draw title
  fill(0, 255, 0);
  textAlign(CENTER);
  textSize(16);
  text("Arduino Air Defense System Radar", width/2, 30);
  textSize(12);
}

void serialEvent(Serial myPort) {
  try {
    data = myPort.readStringUntil('\n');
    if (data != null) {
      data = trim(data);
      println("Received: " + data); // Debug output
      
      // Parse the data from Arduino - format: "A:90,D:25,M:1,G:45"
      if (data.startsWith("A:")) {
        String[] parts = split(data, ',');
        
        for (String part : parts) {
          if (part.startsWith("A:")) {
            angle = int(part.substring(2));
          } else if (part.startsWith("D:")) {
            distance = int(part.substring(2));
          } else if (part.startsWith("M:")) {
            motionDetected = (int(part.substring(2)) == 1);
          } else if (part.startsWith("G:")) {
            gunAngle = int(part.substring(2));
          }
        }
      }
    }
  } 
  catch (Exception e) {
    println("Error parsing data: " + e);
  }
}

void keyPressed() {
  // Press 'R' to reset the radar display
  if (key == 'r' || key == 'R') {
    background(0);
    println("Radar display reset");
  }
}
