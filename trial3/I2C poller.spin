{{┌──────────────────────────────────────────┐
  │ Polls for devices on I2C bus             │
  │ Author: Chris Gadd                       │
  │ Copyright (c) 2014 Chris Gadd            │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘
  Sends a start, device ID, and a 0 for every device id from 0 to 127

}}                                                                                                                                                
CON
_clkmode = xtal1 + pll16x                                                      
_xinfreq = 5_000_000

SCL = 15
SDA = 14

OBJ
  I2C    : "I2C Spin driver v1.3"
  I2C_pp : "I2C Spin push_pull driver"
  FDS    : "FullDuplexSerial"

PUB Main | device_id, pullups
  FDS.start(31,30,0,115_200)
  waitcnt(clkfreq + cnt)
  fds.tx($00)
  pullups := 1

  if not ina[SCL]                                                               ' This detects whether or not the I2C lines have pullups
    FDS.str(string("No pullup detected on SCL",$0D))                            ' Object uses I2C Spin driver v1.2 if pullups are detected
    pullups := 0                                                                '        uses I2C Spin driver v1.2b if pullups are not detected 
  if not ina[SDA]                                                               ' Main difference is that I2Cb drives SCL and SDA high and low
    FDS.str(string("No pullup detected on SDA",$0D))
    pullups := 0
  waitcnt(cnt + clkfreq)

  FDS.str(string($0D,"Polling I2C bus for devices",$0D,"7-bit ID",$09,"Device type - not all inclusive",$0D))
  if pullups
    I2C.start(SCL,SDA)
    repeat device_id from 0 to $7F
      I2C.I2C_stop                                      ' For whatever reason, a HMC5883 compass at address $1E won't respond to this poll                            
      if device_id == %0011110                          '  It will respond if a separate start or a stop is called before it's polled
        dira[16]~~                                      '  It will respond if polling is started at $08 or higher
      if \I2C.command(device_id,0)                      '  It will respond if a device is present at $1D                        
        FDS.bin(device_id,7)
        FDS.str(string($09,$09))
        FDS.str(Get_device(device_id))
        FDS.tx($0D)
    FDS.str(string("pull-up Finished"))
  else
    I2C_pp.start(SCL,SDA)
    repeat device_id from 0 to $7F
      I2C_pp.I2C_stop
      if \I2C_pp.command(device_id,0)
        FDS.bin(device_id,7)
        FDS.str(string($09,$09))
        FDS.str(Get_device(device_id))
        FDS.tx($0D)
    FDS.str(string("no pull-up Finished"))

PRI Get_device(Device_ID)

  case Device_ID
    $0C:                         return(string("AK8975C magnetometer"))                                                         ' compass section of the MPU9150 needs to be enabled before it can be detected   
    $1D:                         return(string("ADXL345, MMA7455L accelerometer"))                                                                                                                               
    $1E:                         return(string("HMC5843 / HMC5883 compass"))                                                    ' also MMA7455L with IADDR0 pulled high
    $20..$27:                    return(string("IO expander - various types"))                                                  ' MCP23008, CY8C9520A, TCA6424
'   $21:                         return(string("CY8C9520A IO expander"))              
'   $22,$23:                     return(string("TCA6424 24-bit IO expander"))
    $38:                         return(string("BMA150 accelerometer"))
    $3C,$3D:                     return(string("SSD1308 128x64 display driver"))
    $40..$43:                    return(string("IQS156 touch sensor"))
    $48:                         return(string("AD7745 / AD7746 capacitance to digital converter",$0D,{
    }                                  $09,$09,"ADS1113/4/5 16bit analog to digital converter"))
    $49,$4A,$4B:                 return(string("ADS1113/4/5 16bit analog to digital converter"))                                ' alternate addresses
    $50..$52,$54..$57:           return(string("24LCxxx EEPROM"))
    $53:                         return(string("ADXL345 accelerometer alternate address",$0D,{
    }                                  $09,$09,"24LCxxx EEPROM at address 3"))
    $5A..$5D:                    return(string("MPR121 touch sensor"))
    $60:                         return(string("MPL3115A2 altimeter"))
    $68:                         return(string("DS1307 real-time clock",$0D,{
    }                                  $09,$09,"L3G4200D gyroscope with SDO low",$0D,{
    }                                  $09,$09,"MPU9150 gyroscope and accelerometer with AD0 low"))                             ' also ITG3200 gyro 
    $69:                         return(string("L3G4200D gyroscope with SDO high",$0D,{                                                             
    }                                  $09,$09,"MPU9150 gyroscope and accelerometer with AD0 high"))                            ' also ITG3200 gyro 
    $76:                         return(string("MS5607 altimeter with CSB high"))
    $77:                         return(string("BMP085 pressure sensor",$0D,{
    }                                  $09,$09,"MS5607 altimeter with CSB low"))
    other:                       return(string("unknown"))

DAT                     
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}                                  