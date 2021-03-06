{{
  9-axis MPU-9150

  I2C address is %1101_0000

  Rewritten to use i2c library exclusively
}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  
  'I2C registers for the MPU-9150
  
  MPU_add                       = c#MPU_address
  AKM_address                   = c#AKM_address
            
  pcport                        = c#pcport
  pcrx                          = c#pcrx
  pctx                          = c#pctx
  pcbaud                        = c#pcbaud

  PERCENT_CONST =1000
  
OBJ

  i2c   :       "basic_i2c_driver"                    '0 COG
  c     :       "constants"                  
  uart    :     "FullDuplexSerial"

VAR

  LONG  MPU[10],offset[3],mag[3]        'gains x,y,z; offsets x,y,z
  byte  MPU9150_alive,calibrated,scl,sda
          
  long  ti[2]
  byte addr

  Long compFilter[3], baseMag[3], gForce

  Long prevAccX[20], prevAccY[20], prevAccZ[20], avgAcc[3]
  
  Long acc[3], gyro[3], temperature, raw[10]              
PUB MAIN | il


scl := 15
sda := 14
       
'Designed to test the MPU-9150 Magnetic sensor
uart.quickStart


Init(SCL,SDA)

repeat   
  uart.clear
  uart.strLn(string("Raw MPU values"))
  ti[0] := cnt                
  i2c.writeLocation(SCL,SDA,AKM_address, $0A, %0000_0001)'2G 
  Get_MPU_Data(@MPU)
  calcCompFilter
  ti[1] := clkfreq/(cnt-ti[0])
    repeat il from 0 to 6
      uart.decLn(MPU[il])
  uart.strLn(string("Raw AKM values"))
  
  ti[0] := cnt                    
  Get_AKM_Data(@MAG)
  ti[1] := clkfreq/(cnt-ti[0])
    repeat il from 0 to 2
      uart.decLn(MAG[il])
    uart.decLn(ti[1])
           
  waitcnt(clkfreq/10+cnt)

     
PUB calcCompFilter | i, a, avgCoef, intCoef

  a := 1000
  avgCoef:= 10
  repeat i from 0 to (avgCoef-2)
    prevAccX[i] := prevAccX[i+1]
  prevAccX[avgCoef-1] := acc[0]

  avgAcc[0] := 0
  repeat i from 0 to (avgCoef-1)
    avgAcc[0] += prevAccX[i]/avgCoef 
                                                  
  compFilter[0] := a*(compFilter[0] - (gyro[1]))/PERCENT_CONST + ((PERCENT_CONST-a)*avgAcc[0])/PERCENT_CONST
  uart.str(string("Comp: "))      
  uart.decLn(compFilter[0])
  
{ 
  intCoef := 8000
  if gyro[1] < 0
    compFilter[0] := a*(compFilter[0] - (gyro[1]*intCoef/100))/PERCENT_CONST + ((PERCENT_CONST-a)*avgAcc[0])/PERCENT_CONST
  else
    compFilter[0] := a*(compFilter[0] - (gyro[1]*(10000-intCoef)/100))/PERCENT_CONST + ((PERCENT_CONST-a)*avgAcc[0])/PERCENT_CONST
  'else
  '  compFilter[0] := avgAcc[0]
}

  'compFilter[1] := 989*(gyro[2])/PERCENT_CONST + 5*acc[1]/PERCENT_CONST
  'compFilter[2] := acc[2]                    
PUB Init(sc,sd)
{{
  Initializes MPU-9150 

  parameters:  Addresses and scl/sda lines specified in the constant section. Optional debug ports listed in constant section  
  return:      1 if device found and reported healthy. 0 otherwise.

  example usage:    Init
  expected results: 1
}}
i2c.initialize(SCL,SDA)      
  scl := sc
  sda := sd
  
  Alive

  if MPU9150_alive
    i2c.writeLocation(SCL,SDA,MPU_ADD, $6B, %0000_0001) '100Hz output at 1kHz sample
    i2c.writeLocation(SCL,SDA,MPU_ADD, $37, %0000_0010) 'i2c Passthrough
    i2c.writeLocation(SCL,SDA,MPU_ADD, $6A, %0000_0000) 'Disable i2cMaster mode    
      
    i2c.writeLocation(SCL,SDA,MPU_ADD, $19, 19) '50Hz output at 1kHz sample
    i2c.writeLocation(SCL,SDA,MPU_ADD, $1A, %0000_0001)'184Hz lowpass
    i2c.writeLocation(SCL,SDA,MPU_ADD, $1B, %0000_1000)'500 deg/s                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
    i2c.writeLocation(SCL,SDA,MPU_ADD, $1C, %0001_0000)'8G
     
    i2c.writeLocation(SCL,SDA,AKM_address, $0A, %0000_0001)'2Gauss   

  if MPU9150_alive
    Calc_bias
  result := MPU9150_alive

PUB Alive

  MPU9150_alive := i2c.devicePresent(SCL,SDA,MPU_add)

  result := MPU9150_alive
  
PUB STATUS(address,register) 

  return i2c.readLocation8(SCL,SDA,address, register)
  
PUB Get_MPU_Data(XPtr)  

  i2c.ReadSensors(SCL,SDA, MPU_ADD,$3B, @MPU, 7, 1)
  i2c.ReadSensors(SCL,SDA, MPU_ADD,$3B, XPtr, 7, 1)
  i2c.writeLocation(SCL,SDA,AKM_address, $0A, %0000_0001)'2 Gauss
  Scale_data(XPtr)
  
PUB Scale_data(XPtr)

MPU[0] ^= MPU[1]          'Xor swap x-y axes, negate x axis
MPU[1] := MPU[0]^MPU[1]
MPU[0] := -(MPU[0]^MPU[1]) 

MPU[4] ^= MPU[5]          'Xor swap x-y axes, negate x axis
MPU[5] := MPU[4]^MPU[5]
MPU[4] := -(MPU[4]^MPU[5])

if calibrated                   'Subtract gyro bias vector 
  MPU[4] -= offset[0]
  MPU[5] -= offset[1]
  MPU[6] -= offset[2]    

M_MULT_INT(@MPU[0],@ACCEL_CAL,@MPU[0],@ACCEL_OFF,15)
M_MULT_INT(@MPU[7],@MAG_CAL,@MPU[7],@MAG_OFF,15)

'longmove(Xptr,@MPU,7)    

PUB Get_AKM_Data(XPtr) 
  
  i2c.ReadSensors(SCL,SDA, AKM_address, $03, Xptr, 3, 0)

PUB Calc_bias | il

  repeat 256
    Get_MPU_Data(@MPU)
    repeat il from 0 to 2
      offset[il] += MPU[il+4]      
    waitcnt(clkfreq*2/256 + cnt)                        '2 second window

  repeat il from 0 to 2
    offset[il] /= 256

  calibrated := true

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
│COPYRIGHT HOLD ERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,  │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}