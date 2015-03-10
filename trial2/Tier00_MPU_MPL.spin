CON
  _clkmode = xtal1 + pll16x                                                      
  _xinfreq = 5_000_000
   
  SCL = 15
  SDA = 14

  'MPU-related constants 
  mpuAdd = %1101_000
  
  mpuRegPowMgmt = 107
  mpuRegDLPF = 26
  mpuRegSMPLRT = 25
  mpuRegGyroConfig = 27
  mpuRegAccConfig = 28
  mpuByPass = 55
  
  mpuXAccH = $3B
  mpuXAccL = $3C
  mpuYAccH = $3D
  mpuYAccL = $3E
  mpuZAccH = $3F
  mpuZAccL = $40
  mpuTempH = $41
  mpuTempL = $42
  mpuXGyroH = $43
  mpuXGyroL = $44
  mpuYGyroH = $45
  mpuYGyroL = $46
  mpuZGyroH = $47
  mpuZGyroL = $48        

  'Magnetometer-related
  ak8Add = %0001_100 

  ak8XL  = $03
  ak8XH  = $04
  ak8YL  = $05
  ak8YH  = $06
  ak8ZL  = $07
  ak8ZH  = $08
    
  'MPL-related constants
  mplAdd = %1100_000
   
OBJ
  I2C    : "I2C Spin driver v1.3"
  FDS    : "FullDuplexSerial.spin"

Var
  long mpuRawData[10], accOffset[3], gyroOffset[3], mag[3]

  long mpuData[10] 'Acc x-y-z, Gyro x-y-z, Mag z-y-z, temperature
  byte mpuIsAlive, mplIsAlive, IsCalibrated
  
PUB main | data, iter,sigData, i
  initSensor(SCL, SDA)
  
  FDS.start(31,30,0,115_200)
  FDS.clear
  FDS.strLn(String("Starting"))  

  'Check if alive
  if NOT(isAlive)
    FDS.strLn(String("Sensor status is bad. System abort"))
    return
  
  'Setting MPU
  setting
  
  'Getting MPU data
    
  repeat
    FDS.clear 
    getMpuData(@mpuData)
    'getMagData
    'getTemData
    FDS.str(String("accX: "))
    FDS.decLn(mpuData[0])
    FDS.str(String("accY: "))
    FDS.decLn(mpuData[1])
    FDS.str(String("accZ: "))
    FDS.decLn(mpuData[2])
    FDS.str(String("gyroX: "))
    FDS.decLn(mpuData[3])
    FDS.str(String("gyroY: "))
    FDS.decLn(mpuData[4])
    FDS.str(String("gyroZ: "))
    FDS.decLn(mpuData[5])
    FDS.str(String("magX: "))
    FDS.decLn(mpuData[6])
    FDS.str(String("magY: "))
    FDS.decLn(mpuData[7])
    FDS.str(String("magZ: "))
    FDS.decLn(mpuData[8])
    FDS.str(String("Temperature: "))
    FDS.decLn(mpuData[9])
     

    waitcnt(cnt + clkfreq/10)

PUB initSensor(sc, sd)
  I2C.start(sc,sd)    

PUB getMpuData(dataPtr)

  getRawMpuData
  LONG[dataPtr][0] := mpuRawData[1]
  LONG[dataPtr][1] := mpuRawData[0]
  LONG[dataPtr][2] := mpuRawData[2]
  
  LONG[dataPtr][3] := mpuRawData[5]
  LONG[dataPtr][4] := mpuRawData[4]
  LONG[dataPtr][5] := mpuRawData[6]
  LONG[dataPtr][9] := (mpuRawData[3] + %11000001111100) / %101010100    'temperature
  
  getAk8Data
  LONG[dataPtr][6] := mag[0]
  LONG[dataPtr][7] := mag[1]
  LONG[dataPtr][8] := mag[2]

  

PUB getAk8Data | i

  i2c.write(ak8Add, $0A, %0000_0001)
  
  mag[0] := (I2C.read(ak8Add, ak8XH)<< 8)  | (I2C.read(ak8Add, ak8XL) & $ff)
  ~mag[0]
  mag[1] := (I2C.read(ak8Add, ak8YH)<< 8)  | (I2C.read(ak8Add, ak8YL) & $ff)
  ~mag[1]  
  mag[2] := (I2C.read(ak8Add, ak8ZH)<< 8)  | (I2C.read(ak8Add, ak8ZL) & $ff)
  ~mag[2]

  repeat i from 0 to 2
    if mag[i] > %1100_1000
      mag[i] -= %1111_1111   

PUB isAlive | iter

  mpuIsAlive := false
  mplIsAlive := false
  
  repeat while NOT(mpuIsAlive AND mplIsAlive)
    if \I2C.command(mpuAdd, 0)
      mpuIsAlive := true
    if \I2C.command(mplAdd, 0)
      mplIsAlive := true
      quit
    if iter > 10
      quit
    iter++
                                                                       
  return reportSensorSatus
  
PUB reportSensorSatus : status

  status := true
  
  if (mpuIsAlive)
'   FDS.strLn(String("MPU - acc, gyro, and mag is on"))
  else
'    FDS.strLn(String("MPU is not detected"))
    status := false

  if (mplIsAlive)
'    FDS.strLn(String("MPL - altimeter is on"))
  else
'    FDS.strLn(String("MPL is not detected")) 
    status := false
  
PUB setting

'  FDS.strLn(String("Setting MPU..."))
  i2c.write(mpuAdd, $6A, %0000_0000)                 'Disable i2cMaster mode 
  I2C.write(mpuAdd, mpuRegPowMgmt,%0000_0001)
  I2C.write(mpuAdd, mpuRegDLPF,%0000_0001)
  I2C.write(mpuAdd, mpuRegSMPLRT,%00000001)
  I2C.write(mpuAdd, mpuRegGyroConfig,%000_00_000)      '+- 250 deg/s
  I2C.write(mpuAdd, mpuRegAccConfig,%0000_1000)       '+- 4g
  I2c.write(mpuAdd, mpuByPass, %0000_0010)           'for magnetometer's sharing the scl and sda line
  i2c.write(ak8Add, $0A, %0000_0001)                 '2Gauss
  
'  FDS.strLn(String("Calculating Bias..."))
  calcBias

PUB calcBias | il, num

  num := 200
  repeat num
    getRawMpuData
    repeat il from 0 to 2
      accOffset[il] += mpuRawData[il]
      gyroOffset[il] += mpuRawData[il+4]      
    'waitcnt(clkfreq*1/256 + cnt)                        '1 second window

  repeat il from 0 to 2
    accOffset[il] /= num
    gyroOffset[il] /= num

  IsCalibrated := true

PUB getRawMpuData

  mpuRawData[0] := (I2C.read(mpuAdd, mpuXAccH)<< 8)  | (I2C.read(mpuAdd, mpuXAccL) )
  ~~mpuRawData[0]  ' converting 16 bits to signed long
  mpuRawData[1] := (I2C.read(mpuAdd, mpuYAccH)<< 8)  | (I2C.read(mpuAdd, mpuYAccL) )
  ~~mpuRawData[1] 
  mpuRawData[2] := (I2C.read(mpuAdd, mpuZAccH)<< 8)  | (I2C.read(mpuAdd, mpuZAccL) )
  ~~mpuRawData[2] 
  mpuRawData[3] := (I2C.read(mpuAdd, mpuTempH)<< 8)  | (I2C.read(mpuAdd, mpuTempL) )  
  ~~mpuRawData[3] 
  mpuRawData[4] := ((I2C.read(mpuAdd, mpuXGyroH)<< 8)&$ff) | ((I2C.read(mpuAdd, mpuXGyroL) )&$ff)  
  ~~mpuRawData[4] 
  mpuRawData[5] := ((I2C.read(mpuAdd, mpuYGyroH)<< 8)&$ff) | ((I2C.read(mpuAdd, mpuYGyroL) ) &$ff) 
  ~~mpuRawData[5] 
  mpuRawData[6] := ((I2C.read(mpuAdd, mpuZGyroH)<< 8)&$ff) | ((I2C.read(mpuAdd, mpuZGyroL) )&$ff)
  ~~mpuRawData[6] 

  Scale_data 

PUB Scale_data | i

  mpuRawData[0] ^= mpuRawData[1]          'Xor swap x-y axes, negate x axis
  mpuRawData[1] := mpuRawData[0]^mpuRawData[1]
  mpuRawData[0] := -(mpuRawData[0]^mpuRawData[1]) 
   
  mpuRawData[4] ^= mpuRawData[5]          'Xor swap x-y axes, negate x axis
  mpuRawData[5] := mpuRawData[4]^mpuRawData[5]
  mpuRawData[4] := -(mpuRawData[4]^mpuRawData[5])
   
  if IsCalibrated                   'Subtract gyro bias vector 
    mpuRawData[4] -= gyroOffset[0]
    mpuRawData[5] -= gyroOffset[1]
    mpuRawData[6] -= gyroOffset[2]    
   
  M_MULT_INT(@mpuRawData[0], @ACCEL_CAL, @mpuRawData[0], @ACCEL_OFF, 15)
  M_MULT_INT(@mpuRawData[7], @MAG_CAL, @mpuRawData[7], @MAG_OFF, 15)

  repeat i from 0 to 2
    mpuRawData[i] -= accOffset[i] 


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