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

#ifndef __BUSDEVCE_H__
#define __BUSDEVICE_H__

typedef enum {
  BUSTYPE_ANY  = 0,
  BUSTYPE_NONE = 0,
  BUSTYPE_I2C  = 1,
  BUSTYPE_SPI  = 2
} busType_e;

typedef enum {
  HWTYPE_NONE = 0,
  HWTYPE_SENSOR  = 1,
  HWTYPE_MUX  = 2,
  HWTYPE_EEPROM = 3
} hwType_e;

typedef struct busDevice_s {
  busType_e busType;
  hwType_e hwType;
  uint8_t currentChannel; // If this device is a HWTYPE_MUX
  uint8_t refCount; // Reference count (mux is used by multiple sources)
  union {
    struct {
      SPIClass *spiBus;            // SPI bus
      uint8_t csnPin;         // IO for CS# pin
    } spi;
    struct {
      TwoWire *i2cBus;        // I2C bus ID
      uint8_t address;        // I2C bus device address
      uint8_t channel;        // MUXed I2C Channel
      struct busDevice_s *channelDev; // MUXed I2C Channel Address
      int8_t enablePin;
    } i2c;
  } busdev;
} busDevice_t;

void busDeviceInit();

void busPrint(busDevice_t *bus, const char *function);
busDevice_t *busDeviceInitI2C(TwoWire *wire, uint8_t address, uint8_t channel = 0, busDevice_t *channelDev = NULL, int8_t enablePin = -1, hwType_e hwType = HWTYPE_NONE);
busDevice_t *busDeviceInitSPI(SPIClass *spiBus, uint8_t csnPin, hwType_e hwType = HWTYPE_NONE);
void busDeviceFree(busDevice_t *dev);
bool busDeviceDetect(busDevice_t *busDev);

// read/write Buffers
bool busReadBuf(busDevice_t *busDev, unsigned short reg, unsigned char *values, uint8_t length);
bool busWriteBuf(busDevice_t *busDev, unsigned short reg, unsigned char *values, char length);

// read/write Individual registers
bool busRead(busDevice_t *busDev, unsigned short reg, unsigned char *values);
bool busWrite(busDevice_t *busDev, unsigned short reg, unsigned char value);

#endif