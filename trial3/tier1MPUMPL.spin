{{┌──────────────────────────────────────────┐
  │ MPU-9150 demo using my I2C driver        │
  │ Author: Chris Gadd                       │
  │ Copyright (c) 2014 Chris Gadd            │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘

  Demonstrates the MPU-9150A 9-Axis Module from SparkFun
  This demo is able to use an I2C driver that can be shared among many devices

                        MPU-9150    
             3.3V  ┌─┐ ┌───────────┐                                                                                                                                                                          
                 └─┤• GND      │                                                                                                                                                                     
               └─────┤• VCC      │                                                                                                                                                                     
      P29 ──┻─┼───────┤• SDA      │                                                                                                                                                                     
      P28 ────┻───────┤• SCL      │                                                                                                                                                                     
                       │• ESD      │                                                                                                                                                                     
                       │• ESC      │                                                                                                                                                                      
                       │• COUT     │
                       │• CIN      │
                       │• AD0      │
                       │• FSYNC    │
                       │• INT      │                        
                                                                                                 
}}                                                                                                                                                
CON
  _clkmode = xtal1 + pll16x                                                    
  _xinfreq = 5_000_000

  SCL = 15
  SDA = 14

  ACC_X_CAL = 512
  ACC_Y_CAL = 436
  ACC_Z_CAL = -700
  
' useful assignments:
  MPU = $68
  MAG = $0C
  
VAR

  long  acc_x, acc_y, acc_z, temp, gyro_x, gyro_y, gyro_z, roll, pitch, mag_x, mag_y, mag_z
  long  gyro_cal_x, gyro_cal_y, gyro_cal_z
  byte  asax, asay, asaz
  byte  array[14]

OBJ
  I2C : "I2C Spin driver v1.3"
 ' I2C_spin : "I2C PASM driver v1.6"
  FDS : "FullDuplexSerial"

PUB Main 
  FDS.start(31,30,0,115_200)
  waitcnt(cnt + clkfreq * 2)
  FDS.tx($00)

                                                      
  'I2C.start(SCL,SDA,400_000)

  if not ina[SCL]
    FDS.str(string("No pullup detected on SCL",$0D))                            
  if not ina[SDA]                                                               
    FDS.str(string("No pullup detected on SDA",$0D))
  if not ina[SDA] or not ina[SCL]
    FDS.str(string(" Use I2C Spin push_pull driver",$0D,"Halting"))                                                              
    repeat                                                                      

'  if not \MPU_9150_demo                                                         ' The Spin-based I2C driver aborts if there's no response
'    FDS.str(string($0D,"MPU-9150 not responding"))                              '  from the addressed device within 10ms
                                                                                ' An abort trap '\' must be used somewhere in the calling code
PUB initSensor(sc, sd)
  I2C.start(sc,sd)      

PUB mpuSetting 

  I2C.write(MPU,$6B,$01)                                                        ' take out of sleep and use gyro-x as clock source
  I2C.write(MPU,$37,$02)                                                        ' enable I2C bypass in order to communicate with the magnetometer at address $0C
  I2C.write(MAG,$0A,%1111)                                                      ' access the magnetometer Fuse ROM
  I2C.read_page(MAG,$10,@asax,3)                                                ' Read the magnetometer adjustment values
  asax := (asax - 128) / 2                                                      ' These values never change so might as well do a partial calculation here
  asay := (asay - 128) / 2                                                      '  equation from datasheet:    Hadj = H x (((ASA - 128) x 0.5 / 128) + 1) 
  asaz := (asaz - 128) / 2                                                      '  microcontroller friendlier: Hadj = (H x (ASA - 128) / 2) / 128 + H

  I2C.write(MPU,$19,$01)                                                        ' Sample rate divider (divide gyro_rate by 1 + x)
  I2C.write(MPU,$1A,%00_000_110)                                                ' Digital low-pass filtering (0 = 8KHz gyro_rate, !0 = 1KHz gyro_rate)
  I2C.write(MPU,$1B,%000_00_000)                                                ' Accelerometer sensitivity ±250°/s
  I2C.write(MPU,$1C,%0000_0000)                                                ' Accelerometer sensitivity ±2g

  Calibrate_gyro

PUB getMpuData(accPtr, gyroPtr, tempPtr)

  Read_MPU
  Long[accPtr][0] := Acc_x
  Long[accPtr][1] := Acc_y
  Long[accPtr][2] := Acc_z
  Long[gyroPtr][0] := Gyro_X/131
  Long[gyroPtr][1] := Gyro_Y/131
  Long[gyroPtr][2] := Gyro_Z  
  Long[tempPtr] := temp

PUB getAk8Data(dataPtr)
  Read_Mags
  Long[dataPtr][0] := Mag_X
  Long[dataPtr][1] := Mag_Y
  Long[dataPtr][2] := Mag_Z   



   
  
  {
PUB MPU_9150_demo 
  repeat
    if Read_MPU
      fds.tx($01)
                                                                   
      fds.str(string("Acc_X",$09))                                              
      decf(Acc_X,16384,3)
       fds.str(string("   ",$09))                                                 
      fds.dec(Acc_x)
       fds.str(string("   ",$09))
      
      fds.str(string($0D,"Acc_Y",$09)) 
      decf(Acc_Y,16384,3)
             
      fds.str(string($0D,"Acc_Z",$09)) 
      decf(Acc_Z,16384,3)
        
      fds.str(string($0D,$0D,"Gyro_X",$09))
      decf(Gyro_X,131,3)              
      fds.str(string($0D,"Gyro_Y",$09))
      decf(Gyro_Y,131,3)              
      fds.str(string($0D,"Gyro_Z",$09))
      decf(Gyro_Z,131,3)              

      fds.str(string($0D,$0D,"Temp",$09))
      fds.dec(Temp)
      fds.str(string("°C",$09))                               
      fds.dec(Temp * 9 / 5 + 32)
      fds.str(string("°F"))
       
    Read_Mags

    fds.str(string($0C,$01,$0F,10,"Mag_X",$09))        ' clear below, home cursor / position cursor reduces the amount of display glitching
    fds.dec(Mag_X)
    fds.str(string($0D,"Mag_Y",$09))
    fds.dec(Mag_Y)
    fds.str(string($0D,"Mag_Z",$09))
    fds.dec(Mag_Z)
   }
PUB Calibrate_gyro
  repeat 32
    repeat until I2C.read(MPU,$3A) & $01
    I2C.read_page(MPU,$43,@array,6)
    gyro_cal_x += ~array[0] << 8 | array[1]
    gyro_cal_y += ~array[2] << 8 | array[3]
    gyro_cal_z += ~array[4] << 8 | array[5]

  gyro_cal_x ~>= 5
  gyro_cal_y ~>= 5
  gyro_cal_z ~>= 5

PUB Read_MPU
  if I2C.read(MPU,$3A) & $01                                                    ' wait for new data (based on sampling rate and digital low-pass filtering registers)
    I2C.read_page(MPU,$3B,@array,14)
    I2C.read(MPU,$3B)
    
    Acc_X  := ~array[0] << 8 | array[1] - ACC_X_CAL                             ' The accelerometer and gyroscope values are read as big-endians
    Acc_Y  := ~array[2] << 8 | array[3] - ACC_Y_CAL
    Acc_Z  := ~array[4] << 8 | array[5] - ACC_Z_CAL
    Temp   := ~array[6] << 8 | array[7] / 340 + 35                              ' Convert Temp into °c, formula if from the register map document
    Gyro_X := ~array[8] << 8 | array[9] - gyro_cal_x 
    Gyro_Y := ~array[10] << 8 | array[11] - gyro_cal_y
    Gyro_Z := ~array[12] << 8 | array[13] - gyro_cal_z
    return true

PUB Read_Mags

  longfill(@mag_x,0,3)                                                          ' Clear the mag registers

  repeat 16                                                                     ' Average 16 samples together
    I2C.write(Mag,$0A,$01)                                                      ' Perform single measurement by setting mode to 1 in control register $0A
    repeat until (I2C.read(Mag,$02) & $01)                                      ' Check data ready bit in status1 register
    I2C.read_page(Mag,$03,@array,6)
    mag_x += ~array[1] << 8 | array[0]                                          ' The magnetometer values are read as little-endians
    mag_y += ~array[3] << 8 | array[2]
    mag_z += ~array[5] << 8 | array[4]

  mag_x ~>= 4                                                                   ' Divide by 16 while preserving the sign
  mag_y ~>= 4
  mag_z ~>= 4

  mag_x := (mag_x * asax) / 128 + mag_x                                         ' Apply the adjustment values 
  mag_y := (mag_y * asay) / 128 + mag_y                                         ' Hadj = (H x (ASA - 128) / 2) / 128 + H     
  mag_z := (mag_z * asaz) / 128 + mag_z
  
PRI DecF(value,divider,places) | i, x

  if value < 0
    || value                                                                    ' If negative, make positive
    fds.tx("-")                                                                 '  and output sign
  else                                                                           
    fds.tx(" ")                                                                  
                                                                                 
  i := 1_000_000_000                                                            ' Initialize divisor
  x := value / divider                                                           
                                                                                 
  repeat 10                                                                     ' Loop for 10 digits
    if x => i                                                                    
      fds.tx(x / i + "0")                                                       ' If non-zero digit, output digit
      x //= i                                                                   '  and remove digit from value
      result~~                                                                  '  flag non-zero found
    elseif result or i == 1                                                      
      fds.tx("0")                                                               ' If zero digit (or only digit) output it
    i /= 10                                                                     ' Update divisor
                                                                                 
  fds.tx(".")                                                                    
                                                                                 
  i := 1                                                                         
  repeat places                                                                  
    i *= 10                                                                      
                                                                                 
  x := value * i / divider                                                       
  x //= i                                                                       ' limit maximum value
  i /= 10
    
  repeat places
    fds.Tx(x / i + "0")
    x //= i
    i /= 10    
    
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