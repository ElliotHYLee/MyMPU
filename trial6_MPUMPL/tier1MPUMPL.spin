CON
  _clkmode = xtal1 + pll16x                                                    
  _xinfreq = 5_000_000

  SCL = 15
  SDA = 14
{
  ACC_X_CAL = 512
  ACC_Y_CAL = 436
  ACC_Z_CAL = -700
}  

  mpuAdd = $68
  ak8Add = $0C
  mplAdd = $60       
VAR

  'MPU 9150 DATA
  
  '1st-tier data
  long  acc[3], temperature, gyro[3], mag[3]

  'intermediate data
  long  gyroBias[3]
  byte  asax, asay, asaz

  'raw data
  byte  array[14],array2[14], MPU[10]

  'MPL3115A2 DATA
  long arrayAlt[10], biasPressure, prevPressure[100], avgPressure, localPressure, currentPressure
  byte firstTimeMpl


OBJ
  I2C : "I2C Spin driver v1.3"
  FDS : "FullDuplexSerial"
  c   : "constants.spin"
PUB Main

  fds.quickStart
  
  initSensor(SCL, SDA)                                                    

  setMpu(%000_11_00, %000_01_000)


  setMpl(99600)     
  
  testMpuMpl


PUB testMpuMpl 

  repeat
    fds.clear

    getMpu
    fds.str(String("accX "))
    fds.dec(acc[0])
    fds.newline
    fds.newline
    fds.str(String("   magX "))
    fds.dec(mag[0])
    fds.str(String("   magY "))
    fds.dec(mag[1])
    fds.str(String("   magZ "))
    fds.decLn(mag[2])
    fds.newline
    fds.newline
    
    fds.str(String("   gyroX "))
    fds.dec(gyro[0])
    fds.str(String("   gyroY "))
    fds.dec(gyro[1])
    fds.str(String("   gyroZ "))
    fds.decLn(gyro[2])

    fds.str(String("magnituide"))
    
    fds.decLn(acc[0]*acc[0]+acc[1]*acc[1]+acc[2]*acc[2])
       
    getAk8

    fds.newline
    fds.str(String("avgP: "))
    fds.decLn(getAvgPressure)


    
 {     
    orthogonalize

    fds.str(String("Orth accX "))
    fds.decLn(mpu[0])
    fds.str(String("Orth accY "))
    fds.decLn(mpu[1])
    fds.str(String("Orth accZ "))
    fds.decLn(mpu[2])        
    fds.newline

    fds.str(String("Orth   gyroX "))
    fds.decLn(mpu[4])
    fds.str(String("Orth   gyroY "))
    fds.decLn(mpu[5])
    fds.str(String("Orth   gyroZ "))
    fds.decLn(mpu[6])
 }   
    waitcnt(cnt+clkfreq/10)


                                                 
PUB initSensor(sc, sd)

  I2C.start(sc,sd)      

PUB mpuIsAlive
  if (i2c.read(mpuAdd, c#MPU_WHO_AM_I) == mpuAdd )
    return 1
  else
    return 0
    
PUB mplIsAlive
  if (i2c.read(mplAdd, c#MPL_WHO_AM_I) == 196 )
    return 1
  else
    return 0  

{{
================================================================
MPL3115A2 REGION


================================================================
}}

PUB getAvgPressure
  if firstTimeMpl
    repeat 110
      calcAvgPressure
    firstTimeMpl := 0
  else
    calcAvgPressure

  return avgPressure

PRI calcAvgPressure | avgCoef  , i

  avgCoef:= 100

  repeat i from 0 to (avgCoef-2)
    prevPressure[i] := prevPressure[i+1]
  prevPressure[avgCoef-1] := getCurrentPressure
    
  avgPressure := 10 
    
  repeat i from 0 to (avgCoef-1)
    avgPressure += prevPressure[i]/avgCoef 

  return avgPressure
  
PUB getCurrentPressure
  currentPressure := getRawPressure - biasPressure 
  return currentPressure
  
PUB setMpl(value)

  firstTimeMpl := 1
  localPressure := value           

  setModeAltimeter
  setOverSampleRate(7)
  enableEventFlags

  calcPressureBias

PRI calcPressureBias | avg
  avg:=0
  repeat 100
    avg += getRawPressure

  avg := (avg+50)/100
  biasPressure := (avg - localPressure)

PRI getRawPressure | total

  toggleOneShote

  arrayAlt[0] := I2C.read(mplAdd,$01)
  arrayAlt[1] := I2C.read(mplAdd,$02)
  arrayAlt[2] := I2C.read(mplAdd,$03)
  
  arrayAlt[0] := arrayAlt[0] << 10
  arrayAlt[1] := arrayAlt[1] << 2  
  arrayAlt[2] := arrayAlt[2] >> 6 

  toggleOneShote

  total := array[0] + array[1] '+ array[2]
  return (total)   'Pascal
  
PRI toggleOneShote| tempSetting

  tempSetting := i2c.read(mplAdd, c#MPL_CTRL_REG1)
  tempSetting &= (%01)
  i2c.write(mplAdd, c#MPL_CTRL_REG1, tempSetting)

  tempSetting := i2c.read(mplAdd, c#MPL_CTRL_REG1)
  tempSetting := (%10)
  i2c.write(mplAdd, c#MPL_CTRL_REG1, tempSetting)

PRI setModeAltimeter | tempSetting

  tempSetting := i2c.read(mplAdd, c#MPL_CTRL_REG1)
  tempSetting |= %1000_0000
  i2c.write(mplAdd, c#MPL_CTRL_REG1, tempSetting)

PRI setOverSampleRate(sampleRate)|tempSetting

 if(sampleRate > 7)
   sampleRate :=7

 tempSetting := i2c.read(mplAdd, c#MPL_CTRL_REG1)
 tempSetting &= %11000111
 tempSetting |= sampleRate
 i2c.write(mplAdd, c#MPL_CTRL_REG1, tempSetting)

PRI enableEventFlags

  i2c.write(mplAdd, c#MPL_PT_DATA_CFG, $07)

{{
===========================================================================
MPU9150 REGION


===========================================================================
}}
PUB reportData(accPtr, gyroPtr, magPtr, temPtr)

  getMpu
  getAk8
   
  Long[accPtr][0] := acc[0]
  Long[accPtr][1] := acc[1]
  Long[accPtr][2] := acc[2]

  Long[gyroPtr][0] := gyro[0]
  Long[gyroPtr][1] := gyro[1]
  Long[gyroPtr][2] := gyro[2]

  Long[magPtr][0] := mag[0]
  Long[magPtr][1] := mag[1]
  Long[magPtr][2] := mag[2]                           

  Long[temPtr] := temperature

PUB setMpu(gyroSense, accSense) 

  I2C.write(mpuAdd,c#MPU_PWR_MGMT_1,$01)   ' take out of sleep and use gyro-x as clock source
  I2C.write(mpuAdd,c#MPU_INT_PIN_CFG,$02)  ' enable I2C bypass in order to communicate with the magnetometer at address $0C
  I2C.write(ak8Add,$0A,%1111)              ' access the magnetometer Fuse ROM
  I2C.read_page(ak8Add,$10,@asax,3)        ' Read the magnetometer adjustment values

  asax := (asax - 128) / 2                 ' These values never change so might as well do a partial calculation here
  asay := (asay - 128) / 2                 '  equation from datasheet:    Hadj = H x (((ASA - 128) x 0.5 / 128) + 1) 
  asaz := (asaz - 128) / 2                 '  microcontroller friendlier: Hadj = (H x (ASA - 128) / 2) / 128 + H

  I2C.write(mpuAdd,c#MPU_SMPLRT_DIV,$01)           ' Sample rate divider (divide gyro_rate by 1 + x)
  I2C.write(mpuAdd,c#MPU_CONFIG,%00_000_110)       ' Digital low-pass filtering (0 = 8KHz gyro_rate, !0 = 1KHz gyro_rate)
  I2C.write(mpuAdd,c#MPU_GYRO_CONFIG,gyroSense)    
  I2C.write(mpuAdd,c#MPU_ACCEL_CONFIG,accSense)    

  calcBias

PUB calcBias

  repeat 256
    repeat until I2C.read(mpuAdd,c#MPU_INT_STATUS) & $01
    I2C.read_page(mpuAdd,c#MPU_GYRO_XOUT_H,@array,6)
    gyroBias[0] += ~array[0] << 8 | array[1]
    gyroBias[1] += ~array[2] << 8 | array[3]
    gyroBias[2] += ~array[4] << 8 | array[5]

  gyroBias[0] /=256
  gyroBias[1] /=256
  gyroBias[2] /=256

PUB getMpu | i

  if I2C.read(mpuAdd,c#MPU_INT_STATUS) & $01           ' wait for new data (based on sampling rate and digital low-pass filtering registers)
    I2C.read_page(mpuAdd,c#MPU_ACCEL_XOUT_H,@array,14)
    I2C.read(mpuAdd,c#MPU_ACCEL_XOUT_H)
    
    acc[0]  := ~array[0] << 8 | array[1]' - ACC_X_CAL          
    acc[1]  := ~array[2] << 8 | array[3]'  - ACC_Y_CAL
    acc[2]  := ~array[4] << 8 | array[5]'  - ACC_Z_CAL

    temperature   := ~array[6] << 8 | array[7] / 340 + 35       ' Temperature in 'C

    gyro[0] := ~array[8] << 8 | array[9] - gyroBias[0]          
    gyro[1] := ~array[10] << 8 | array[11] - gyroBias[1]        
    gyro[2] := ~array[12] << 8 | array[13] - gyroBias[2]

     return true
    
PUB getAk8

  longfill(@mag[0],0,3)                                                          ' Clear the mag registers

  repeat 1                                                                     ' Average 16 samples together
    I2C.write(ak8Add,$0A,$01)                                                      ' Perform single measurement by setting mode to 1 in control register $0A
    repeat until (I2C.read(ak8Add,$02) & $01)                                      ' Check data ready bit in status1 register
    I2C.read_page(ak8Add,$03,@array2,6)
    mag[0] += ~array2[1] << 8 | array2[0]                                          ' The magnetometer values are read as little-endians
    mag[1] += ~array2[3] << 8 | array2[2]
    mag[2] += ~array2[5] << 8 | array2[4]

'  mag[0] ~>= 4                                                                   ' Divide by 16 while preserving the sign
'  mag[1] ~>= 4
'  mag[2] ~>= 4

  mag[0] := (mag[0] * asax + 64 ) / 128 + mag[0]                                         ' Apply the adjustment values 
  mag[1] := (mag[1] * asay + 64 ) / 128 + mag[1]                                         ' Hadj = (H x (ASA - 128) / 2) / 128 + H     
  mag[2] := (mag[2] * asaz + 64 ) / 128 + mag[2]


    
PUB orthogonalize

  mpu[0] := acc[0]
  mpu[1] := acc[1]
  mpu[2] := acc[2]
  mpu[3] := temperature
  mpu[4] := gyro[0]
  mpu[5] := gyro[1]
  mpu[6] := gyro[2]

  M_MULT_INT(@MPU[0],@ACCEL_CAL,@MPU[0],@ACCEL_OFF,15)
'  M_MULT_INT(@MPU[7],@MAG_CAL,@MPU[7],@MAG_OFF,15)


PUB M_MULT_INT(M1,M2,M3,M4,shift)  | RTEMP[3]

RTEMP[0] := ((LONG[M1][0]*LONG[M2][0]+LONG[M1][1]*LONG[M2][3]+LONG[M1][2]*LONG[M2][6])~>shift)-LONG[M4][0]
RTEMP[1] := ((LONG[M1][0]*LONG[M2][1]+LONG[M1][1]*LONG[M2][4]+LONG[M1][2]*LONG[M2][7])~>shift)-LONG[M4][1]
RTEMP[2] := ((LONG[M1][0]*LONG[M2][2]+LONG[M1][1]*LONG[M2][5]+LONG[M1][2]*LONG[M2][8])~>shift)-LONG[M4][2]
longmove(M3,@RTEMP,3)
            
DAT

GYRO_CAL      long      33250,321,-211,-373,33092,-396,206,109,33440      
ACCEL_CAL     long      33006,-175,172,186,32889,84,-112,0,32629'33007,0,0,11,32890,0,62,83,32629
ACCEL_OFF     long      34,35,63'34,35,63      
MAG_CAL       long      54181,0,0,-7664,51226,0,7208,-10321,50167
MAG_OFF       long      -79,123,-33

     
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