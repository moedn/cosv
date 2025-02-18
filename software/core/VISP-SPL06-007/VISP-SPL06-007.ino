/*
   This file is part of VISP Core.

   VISP Core is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   VISP Core is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with VISP Core.  If not, see <http://www.gnu.org/licenses/>.

   Author: Steven.Carr@hammontonmakers.org
*/

// TODO: Better input validation
// TODO: Failure modes (all of them) need to be accounted for and baked into the system
// TODO: design a board that has TEENSY/NANO/MapleLeaf sockets with a missing pulse detection alarm circuit and integrated motor drivers for steppers and DC motors
// TODO: 2.8" SPI display for TEENSY and BluePill

// Failures left to detect
// Low battery
// Motor on, no pulsing
// Motor on, no VISP data change
// Motor on, 200+ steps & no home detected
// Motor on, 200+ homes and 1 step pulse (improper wiring, should swap IRQ's)
// No VISP heartbeat
// VISP shows volume/pressure with motor off
// TOO MUCH PRESSURE???  (How do we determine too much?)
// TOO MUCH VOLUME???    (How do we determine too much?)
//
// TODO: detect patient wants to breath

// Air flow is difference between the two pitot sensors
// Relative pressure is difference between inside and outside sensors

// The kilopascal is a unit of pressure.  1 kPa is approximately the pressure
// exerted by a 10-g mass resting on a 1-cm2 area.  101.3 kPa = 1 atm.  There
// are 1,000 pascals in 1 kilopascal.

#include "config.h"
#include <FastPID.h>

#define PATIENT_CHECK_INTERVAL 20
float Kp=0.85, Ki=0.09, Kd=0.023, Hz=(1000/PATIENT_CHECK_INTERVAL);
int output_bits = 8;
bool output_signed = false;
FastPID myPID(Kp, Ki, Kd, Hz, output_bits, output_signed);

#ifdef ARDUINO_TEENSY40
TwoWire *i2cBus1 = &Wire;
TwoWire *i2cBus2 = &Wire1;
#elif ARDUINO_BLUEPILL_F103C8
TwoWire *i2cBus1 = &Wire;
TwoWire Wire2(PB11, PB10);
TwoWire *i2cBus2 = &Wire1;
#elif ARDUINO_AVR_NANO
TwoWire *i2cBus1 = &Wire;
TwoWire *i2cBus2 = NULL;
#elif ARDUINO_AVR_UNO
TwoWire *i2cBus1 = &Wire;
TwoWire *i2cBus2 = NULL;
#else
#error Unsupported board selection.
#endif


uint8_t currentMode = MODE_OFF;
debugState_e debug = DEBUG_DISABLED;

uint16_t breathPressure; // For pressure controlled automatic ventilation
uint16_t breathVolume;
uint8_t  breathRate;
uint8_t  breathRatio;
uint16_t breathThreshold;
uint16_t motor_speed;    // For demonstration purposes, run motor at a fixed speed...

int8_t batteryLevel;
int8_t FiO2Level;

// DUAL I2C VISP on a CPU with 1 I2C Bus using NPN transistors
//
// Simple way to make both I2C buses use a single I2C port
// Use an NPN transistor to permit the SCL line to pull SCL to GND
//
// NOTE: SCL1 & SCL2 have pullups on the VISP
//
//                                       / ------  SCL1 to VISP
//                                      /
// ENABLE_PIN_BUS_A  --- v^v^v^----  --|
//                        10K           V
//                                       \------  SCL from NANO
//
//                                       / ------  SCL2 to VISP
//                                      /
// ENABLE_PIN_BUS_B  --- v^v^v^----  --|
//                        10K           V
//                                       \------  SCL from NANO
//
// Connect BOTH SDA1 and SDA2 together to the SDA
//
//   SDA on NANO --------------+-- SDA1 to the VISP
//                             |
//                             +-- SDA2 to the VISP
//
// Shamelessly swiped from: https://i.stack.imgur.com/WnsM0.png
//
// Put a transistor inverter on ENABLE_PIN_BUS_A to eliminate needing the second ENABLE_PIN_BUS_B
//

/*** Timer callback subsystem ***/

typedef void (*tCBK)() ;
typedef struct t  {
  unsigned long tStart;
  unsigned int  tTimeout; // 64 second max timeout
  tCBK cbk;
} t_t;


unsigned long tCheck (struct t * t ) {
  unsigned long accrued = 0L;

  if (millis() > t->tStart + t->tTimeout)
  {
    unsigned long startTime = micros();
    t->cbk();
    t->tStart = millis();
    accrued += (micros() - startTime);
  }
  return accrued;
}

// Periodically pulse a pin
void __NOINLINE timeToPulseWatchdog()
{
  if (sensorsFound && motorFound)
  {
    digitalWrite(MISSING_PULSE_PIN, HIGH);
    delayMicroseconds(1);
    digitalWrite(MISSING_PULSE_PIN, LOW);
  }

  // Save some flash code space and do this often, the display code prints 1 line per invocation, and has 2 displays to output to.
  // 8 lines of text being updated, so we need to do this every 100ms or so.
  displayUpdate();
}

void timeToReadVISP()
{
  // Read them all NOW
  if (sensorsFound)
  {
    // If any of the sensors fail, stop trying to do others
    for (int8_t x = 0; x < 4; x++)
    {
      if (!sensors[x].calculate(&sensors[x]))
        return;
    }
  }
  // OK, the cable might have just been unplugged, and the sensors have gone away.
  // Hence the double checks one above, and this one below
  if (sensorsFound)
  {
    if (calibrateInProgress())
      calibrateSensors();
    else
    {
      calibrateApply();

      if (visp_eeprom.bodyType == 'P')
        calculatePitotValues();
      else
        calculateVenturiValues();
      // TidalVolume is the same for both versions
      calculateTidalVolume();
      // Take some time to write to the serial port
      dataSend();
    }
  }
}


unsigned long timeToInhale = 0;
unsigned long timeToStopInhale = 0;
volatile unsigned long timeToIgnoreHome = 0;

#define isInInhaleCycle() (timeToStopInhale > 0)

void timeToCheckPatient()
{
  unsigned long theMillis = millis();
  // breathRate is in breaths per minute. timeout= 60*1000/bpm
  // breatRation is a 1:X where 1=inhale, and X=exhale.  So a 1:2 is 50% inhaling and 50% exhaling

  if (currentMode == MODE_OFF)
    return;

  // Can't do stuff without the sensor package!
  if (!sensorsFound)
    return;

  // The patient hasn't tried to breath on their own...
  if (theMillis > timeToInhale)
  {
    unsigned long nextBreathCycle = ((60.0 / (float)breathRate) * 1000.0);
    timeToInhale = nextBreathCycle;
    timeToStopInhale = (nextBreathCycle / breathRatio);

    // This info is 200 bytes long...
    info(PSTR("brate=%d  I:E=1:%d Inhale=%l Exhale=%l millis"), breathRate, breathRatio, timeToStopInhale, nextBreathCycle - timeToStopInhale);

    timeToInhale += theMillis;
    timeToStopInhale += theMillis;

    timeToIgnoreHome = theMillis + 300;

    // motorReverseDirection();  // Go the same direction as we recently reversed
    motorSpeedUp();
  }

  if (timeToStopInhale > 0)
  {
    if (theMillis > timeToStopInhale)
    {
      motorStop();
      motorGoHome();
      timeToStopInhale = 0;
    }
    else
    {
      // TODO: if in the middle of the inhalation time, and we don't have any pressure from the VISP,
      // TODO: either we have a motor fault or we have a disconnected tube
      switch (currentMode)
      {
        case MODE_MANUAL_PCCMV:
        case MODE_PCCMV:
          motorSpeed = myPID.step(breathPressure, pressure); // (setpoint, feedback)
          if ( motorSpeed > motorMaxSpeed)
            motorSpeed = motorMaxSpeed;
          motorGo();
          break;
        case MODE_MANUAL_VCCMV:
        case MODE_VCCMV:          
          motorSpeed = myPID.step(breathVolume, volume); // (setpoint, feedback)
          if ( motorSpeed > motorMaxSpeed)
            motorSpeed = motorMaxSpeed;
          motorGo();
          break;
      }
    }
  }
}
// NANO uses NPN switches to enable/disable a bus for DUAL_I2C with a single hardware I2C bus
void __NOINLINE enableI2cBusA(busDevice_t *busDevice, bool enableFlag)
{
#ifdef ENABLE_PIN_BUS_A
  digitalWrite(ENABLE_PIN_BUS_A, (enableFlag == true ? HIGH : LOW));
#endif
}
void __NOINLINE enableI2cBusB(busDevice_t *busDevice, bool enableFlag)
{
#ifdef ENABLE_PIN_BUS_B
  digitalWrite(ENABLE_PIN_BUS_B, (enableFlag == true ? HIGH : LOW));
#endif
}

void timeToCheckSensors()
{
  // If debug is on, and a VISP is NOT connected, we flood the system with sensor scans.
  // Do it every half second (or longer)
  if (!sensorsFound)
  {
    detectVISP(i2cBus1, i2cBus2, enableI2cBusA, enableI2cBusB);
    if (sensorsFound)
      displaySetup(i2cBus1); // Need to setup the VISP I2C OLED that just attached
  }

  FiO2Level = 40; // Percentage (Hard Coded till we get BME680 supported
}

// Scales the analog input to a range.
int  __NOINLINE scaleAnalog(int analogIn, int minValue, int maxValue)
{
  //float percentage = (float)analogIn / (float)MAX_ANALOG; // This is CPU dependent, 1024 on Nano, 4096 on STM32
  //return minValue + (maxValue * percentage);
  return minValue + ((maxValue * analogIn) / MAX_ANALOG);
}

// 344 bytes
void timeToCheckADC()
{
  int8_t analogMode = scaleAnalog(analogRead(ADC_MODE), 0, 3);

  // if analogMode==0 then 100% software control from the rPi
  if (analogMode)
  {
    currentMode = (analogMode == 1 ? MODE_MANUAL_PCCMV : MODE_MANUAL_VCCMV);
    breathPressure = scaleAnalog(analogRead(ADC_PRESSURE), MIN_BREATH_PRESSURE, MAX_BREATH_PRESSURE);
    breathVolume = scaleAnalog(analogRead(ADC_VOLUME), MIN_BREATH_VOLUME, MAX_BREATH_VOLUME);
    breathRate = scaleAnalog(analogRead(ADC_RATE), MIN_BREATH_RATE, MAX_BREATH_RATE);
    breathRatio = scaleAnalog(analogRead(ADC_RATIO), MIN_BREATH_RATIO, MAX_BREATH_RATIO);
  }
}

void __NOINLINE timeToSendHealthStatus()
{
  // batteryLevel = scaleAnalog(analogRead(ADC_BATTERY), 0, 100);

  batteryLevel = 100;
  sendCurrentSystemHealth();
  respondAppropriately(RESPOND_BATTERY);
}


// Timer Driven Tasks and their Schedules.
// These are checked and executed in order.
// If something takes priority over another task, put it at the top of the list
t tasks[] = {
  {0, 20, timeToReadVISP},
  {0, PATIENT_CHECK_INTERVAL,  timeToCheckPatient},
  {0, 100, timeToPulseWatchdog},
  //  {0, 200, timeToCheckADC}, // disabled for now
  {0, 500, timeToCheckSensors},
  {0, 3000, timeToSendHealthStatus},
  {0, 0, NULL} // End of list
};

/*** End of timer callback subsystem ***/





void scanI2C(TwoWire * wire)
{
  int error;
  if (wire)
  {
    for (uint8_t x = 0; x < 128; x++)
    {
      wire->beginTransmission(x);
      error = wire->endTransmission();
      if (error == 0)
        info(PSTR("Detected 0x%x on bus 0x%x"), x, wire);
    }
  }
}
void initI2C(TwoWire * wire)
{
  if (wire)
  {
    wire->begin();
    wire->setClock(400000); // Typical 400KHz
  }
}

void setup()
{
  hwSerial.begin(SERIAL_BAUD);
  respond('I', PSTR("VISP Core,%d,%d,%d"), VERSION_MAJOR, VERSION_MINOR, VERSION_REVISION);

  initI2C(i2cBus1);
  initI2C(i2cBus2);

  // Address select lines for Dual I2C switching using NPN Transistors
#ifdef ENABLE_PIN_BUS_A
  pinMode(ENABLE_PIN_BUS_A, OUTPUT);
  digitalWrite(ENABLE_PIN_BUS_A, LOW);
#endif
#ifdef ENABLE_PIN_BUS_B
  pinMode(ENABLE_PIN_BUS_B, OUTPUT);
  digitalWrite(ENABLE_PIN_BUS_B, LOW);
#endif
  pinMode(MISSING_PULSE_PIN, OUTPUT);
  digitalWrite(MISSING_PULSE_PIN, LOW);

  myPID.setOutputRange(0, 100);

  motorSetup();

  busDeviceInit();

  vispInit();

  // Some reset conditions do not reset our globals.
  sensorsFound = false;

  // Start the VISP calibration process
  calibrateClear();

  displaySetup(i2cBus1);

  //scanI2C(i2cBus1);
  //scanI2C(i2cBus2);

  coreLoadSettings();

  // primeTheFrontEnd();
  sendCurrentSystemHealth();
}




// Every second, compute how much time we spent working, and report the percentage
unsigned long currentUtilization = 0;
unsigned long utilizationTimeout = 0;

// loop() gets called repeatedly forever, so there is no 'idle' time
// do not compute the time checking for things to be done, only compute the time we do things.
void loop() {
  unsigned long startMicros;

  startMicros = micros();
  motorRun();
  currentUtilization += micros() - startMicros;

  if (homeHasBeenTriggered)
  {
    homeHasBeenTriggered = false;
    motorFound = true;
    motorRunState = MOTOR_STOPPED;

    motorStop();
    info(PSTR("Home Triggered"));
    if (timeToStopInhale > 0)
    {
      info(PSTR("Inhale (%l) stopped short as we hit home!"), timeToStopInhale);
      timeToStopInhale = 0;
    }
  }

  for (t_t *entry = tasks; entry->cbk; entry++)
    currentUtilization += tCheck(entry);

  // Command parser uses >6K bytes of flash... This is a LOT
  // Handle user input, 1 character at a time
  startMicros = micros();
  while (hwSerial.available())
    commandParser(hwSerial.read());

  // Spread out the writing of the EEPROM over time
  coreSaveSettingsStateMachine();

  currentUtilization += micros() - startMicros;

  if (millis() > utilizationTimeout)
  {
    debug(PSTR("Utilization %l%%"), currentUtilization / 10000);
    currentUtilization = 0;
    utilizationTimeout = millis() + 1000;
  }
}
