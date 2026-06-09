const int NUM_SENSORS = 4;
int trigPins[NUM_SENSORS] = { 9, 7, 5, 3 };
int echoPins[NUM_SENSORS] = { 8, 6, 4, 12 };
const int buttonPin = 10;
const int LEDPin = 11;
int lastButtonState = HIGH;
long duration;
float distance;

void setup() {
  Serial.begin(9600);
  pinMode(LEDPin, OUTPUT);
  pinMode(buttonPin, INPUT_PULLUP);

  for (int i = 0; i < NUM_SENSORS; i++) {
    pinMode(trigPins[i], OUTPUT);
    pinMode(echoPins[i], INPUT);
  }
}

void loop() {
  bool anObjectIsClose = false;
  float d = -1;
  float n = -1;

  for (int i = 0; i < NUM_SENSORS; i++) {
    digitalWrite(trigPins[i], LOW);
    delayMicroseconds(2);
    digitalWrite(trigPins[i], HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPins[i], LOW);

    duration = pulseIn(echoPins[i], HIGH, 18000);
    distance = (duration * 0.034) / 2;

    if (distance > 1 && distance < 100) {
      anObjectIsClose = true;
      d = distance;
      n = i;
      break;
    }
  }

 // Serial.println("d=" + (String)d + " n=" + (String)n);


  digitalWrite(LEDPin, anObjectIsClose ? HIGH : LOW);
  delay(200);

  int buttonState = digitalRead(buttonPin);
  if (buttonState != lastButtonState) {
    if (buttonState == LOW) Serial.println("Record");
    else Serial.println("Stop Recording");
    lastButtonState = buttonState;
  }
}