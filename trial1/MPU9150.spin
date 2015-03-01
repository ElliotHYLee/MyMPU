CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  
OBJ

  i2c : "Basic_I2C_Driver.spin"
  usb : "Parallax Serial Terminal.spin"
  const : "Constants"
  
VAR
  byte MPU9150_alive, ackbit

  LONG  MPU[10],offset[3]        'gains x,y,z; offsets x,y,z
  byte  calibrated, MPU_Add
          
  long  ti[2]
  byte  addr

CON
  SCL = const#SCL
  SDA = const#SDA
  MPU_address = const#MPU_address
  ACK = 0     
PUB main| il, okayToGo, er, iteration
  usb.start(115200)   
  usb.clear

  prepareI2cPins

  checkMpuPresence

  'mpu9150Setting


  iteration :=1
  okayToGo :=1
  repeat  while (okayToGo)
    waitcnt(cnt + clkfreq/10)
    usb.clear
    usb.dec(iteration)
    usb.str(String(": "))
    checkMpuPresence     
    usb.bin(reportDevAddr << 1, 8)
    usb.newline
    er := GET_MPU_Data
    if (er < 0)
      usb.str(String("error on getting mpu data"))
      okayToGo := 0 
    repeat il from 0 to 10
      usb.dec(MPU[il])
      usb.newline    
    iteration ++
  usb.str(String("end of program"))
  
PUB prepareI2cPins
  i2c.initialize(SCL, SDA)
  usb.str(String("i2c initialized"))
  usb.newline

PUB checkMpuPresence

  MPU9150_alive := i2c.devicePresent(SCL,SDA,MPU_address)
  if MPU9150_alive
    usb.str(String("Sensor is on"))
  else
    usb.str(String("No sensor detected"))
  usb.newline

PUB reportDevAddr : address
  i2c.start(SCL, SDA)
  ackbit := i2c.writeNS(SCL, SDA, MPU_Address)
'  if (ack==0)
'    usb.str(String("Writing address accessed"))
'    usb.newline
    
  ackbit := i2c.writeNS(SCL, SDA, const#MPU_reg_whoAmI)
'  if (ack==0)
'    usb.str(String("Register accessed"))  
'    usb.newline
    
  i2c.start(SCL, SDA)
  ackbit := i2c.writeNS(SCL, SDA, MPU_Address | 1)
'  if (ack==0)
'    usb.str(String("Reading address accessed")) 
'    usb.newline
    
  address := i2c.readNS(SCL, SDA, 1)
  usb.dec(address)
  usb.newline
  usb.newline
  usb.newline  
'  if (ack==0)
'    usb.bin(address<<1,8)
'    usb.newline
  i2c.stop(SCL, SDA) 
PUB mpu9150Setting

  if MPU9150_alive
    i2c.writeLocation(SCL,SDA,MPU_ADD, $6B, %0000_0001) '100Hz output at 1kHz sample
    i2c.writeLocation(SCL,SDA,MPU_Address, $1A, %00000001)  'Set DLPF_CONFIG to 4 for 20Hz bandwidth        
    i2c.writeLocation(SCL,SDA,MPU_Address, $19, %0001_0100) 'SMPLRT_DIV = 1 => 1khz/(1+1) = 500hz sample rate 
     
    i2c.writeLocation(SCL,SDA,MPU_Address, $1B, %0001_1000)' full scale range of 2000 deg/sec   
    i2c.writeLocation(SCL,SDA,MPU_Address, $1C, %0000_1000)'4G

   Calc_bias


PUB Get_MPU_Data| recAck 
                     
  
  'i2c.ReadSensors(SCL,SDA, MPU_ADD, $3B, @MPU, 7, 1)
  'Scale_data(XPtr)

  i2c.start(SCL, SDA)
  if (i2c.writeNS(SCL, SDA, MPU_address) == ACK)
    if (i2c.writeNS(SCL, SDA, 59) == ACK)
      i2c.start(SCL, SDA)
      if (i2c.writeNS(SCL, SDA, MPU_address | 1) == ACK)
        MPU[0] := (i2c.ReadNS(SCL,SDA, 1)<<8) 
        i2c.stop(SCL, SDA)
        usb.str(string("Acc_x is retrieved: "))
        usb.dec(MPU[0])
        usb.newline
      else
        usb.str(String("error1"))
        usb.newline
        return -1
    else
      usb.str(String("error2"))
      usb.newline
      return -1
  else
    usb.str(String("error3"))
    usb.newline
    'return -1

  'Scale_data
  
PUB Calc_bias | il

  repeat 256
    i2c.start(SCL, SDA)
    Get_MPU_Data
    i2c.stop(SCL,SDA)
    repeat il from 0 to 2
      offset[il] += MPU[il+4]      
    waitcnt(clkfreq*2/256 + cnt)                        '2 second window

  repeat il from 0 to 2
    offset[il] /= 256

  calibrated := true

PUB Scale_data

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
    