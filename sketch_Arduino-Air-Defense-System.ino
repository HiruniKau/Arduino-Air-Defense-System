#include <Servo.h>

// --- Pin Definitions ---
const int pirSensor = 2;       // The PIR sensor's signal pin
const int redLed = 13;         // The red LED pin
const int blueLed = 12;        // The blue LED pin
const int buzzerPin = 7;       // The buzzer pin
const int trigPin = 4;         // Ultrasonic sensor Trigger pin
const int echoPin = 3;         // Ultrasonic sensor Echo pin
const int gunServoPin = 9;     // Servo motor pin for the 'gun'
const int radarServoPin = 10;  // Servo motor pin for the 'radar'

// --- Global Variables ---
int pirState = 0;
long duration;
int distance;
int gunServoAngle;

int radarAngle = 0;
int radarDirection = 1;
const int sweepSpeed = 10;
unsigned long lastSweepTime = 0;

// --- NEW variables for non-blocking flashing ---
unsigned long lastFlashTime = 0;
bool flashState = false;
const unsigned long flashInterval = 500; // ms (was delay(500))

Servo gunServo;
Servo radarServo;

void setup() {
  pinMode(redLed, OUTPUT);
  pinMode(blueLed, OUTPUT);
  pinMode(buzzerPin, OUTPUT);
  pinMode(trigPin, OUTPUT);

  pinMode(pirSensor, INPUT);
  pinMode(echoPin, INPUT);

  gunServo.attach(gunServoPin);
  radarServo.attach(radarServoPin);

  Serial.begin(9600);
}

void loop() {
  // --- PIR ---
  pirState = digitalRead(pirSensor);

  // --- Ultrasonic ---
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  duration = pulseIn(echoPin, HIGH);
  distance = duration * 0.034 / 2;

  // --- Radar sweep ---
  handleRadarSweep();

  // --- Send data to Processing ---
  Serial.print("A:");
  Serial.print(radarAngle);
  Serial.print(",D:");
  Serial.print(distance);
  Serial.print(",M:");
  Serial.print(pirState);
  Serial.print(",G:");
  Serial.println(gunServoAngle);

  // --- Threat logic ---
  if (pirState == HIGH && distance < 20) {
    // Blue OFF
    digitalWrite(blueLed, LOW);

    // Non-blocking blink for red LED + buzzer
    if (millis() - lastFlashTime >= flashInterval) {
      lastFlashTime = millis();
      flashState = !flashState;
      digitalWrite(redLed, flashState);
      digitalWrite(buzzerPin, flashState);
    }

    // Gun servo angle mapped to distance
    gunServoAngle = map(distance, 5, 50, 0, 180);
    gunServo.write(gunServoAngle);

    Serial.println("Both motion and object detected! Engaging gun servo.");
  } else {
    // Reset outputs
    digitalWrite(redLed, LOW);
    digitalWrite(buzzerPin, LOW);
    digitalWrite(blueLed, HIGH);

    // Gun servo neutral
    gunServo.write(90);
    gunServoAngle = 90;

    Serial.println("No motion or object detected. Blue LED is ON. Gun servo reset.");
  }
}

// --- Radar Sweep Function ---
void handleRadarSweep() {
  if (millis() - lastSweepTime > sweepSpeed) {
    lastSweepTime = millis();
    radarAngle += radarDirection;

    if (radarAngle >= 180 || radarAngle <= 0) {
      radarDirection *= -1;
    }

    radarServo.write(radarAngle);
  }
}
