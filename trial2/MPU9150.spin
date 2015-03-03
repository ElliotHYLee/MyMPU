CON
_clkmode = xtal1 + pll16x                                                      
_xinfreq = 5_000_000

SCL = 15
SDA = 14
mpuAdd = %1101_000

mpuRegPowMgmt = 107
mpuRegDLPF = 26
mpuRegSMPLRT = 25
mpuRegGyroConfig = 27
mpuRegAccConfig = 28


mpuXAccH = $3B
ACK = 0

OBJ
  I2C    : "I2C Spin driver v1.3"
  FDS    : "FullDuplexSerial"

Var
  Byte hiAddAlive
  Byte regAlive
  Byte LoAddAlive
  Byte checkWrite
  long MPU[10]
PUB main | data, iter,sigData
  I2C.start(SCL,SDA)
  FDS.start(31,30,0,115_200)
  waitcnt(clkfreq + cnt)  
  FDS.tx($00)
  FDS.str(String("start  "))  
  'Check if alive
  hiAddAlive := I2C.command(%1101_000,0)
  if hiAddAlive < 1
    FDS.str(String("no mpu detected"))
    return 0
  FDS.str(String("mpu detected  "))

  'Setting MPU
  FDS.str(String("mpu setting")) 
  setting
  
  'Getting MPU data
  
  repeat
    iter :=0  
    FDS.tx($00)
    repeat 8
      data := I2C.read(mpuAdd, 59+iter)
      FDS.hex(59+iter, 2)
      FDS.str(String(": "))
      if iter//2 == 0
        sigData := data << 8
      else
        sigData := sigData | data
        FDS.dec(sigData)
      FDS.tx($0D)
      
      iter := iter + 1
    waitcnt(cnt + clkfreq/10)


PUB setting

   checkWrite := I2C.write(mpuAdd, mpuRegPowMgmt,%00000000)
  if (not checkWrite)
    FDS.str(String("setting failed"))
    return 0
  checkWrite := I2C.write(mpuAdd, mpuRegDLPF,%00000100)
  if (not checkWrite)
    FDS.str(String("setting failed"))
    return 0 
  checkWrite := I2C.write(mpuAdd, mpuRegSMPLRT,%00000001)
  if (not checkWrite)
    FDS.str(String("setting failed"))
    return 0
  checkWrite := I2C.write(mpuAdd, mpuRegGyroConfig,%00011000)
  if (not checkWrite)
    FDS.str(String("setting failed"))
    return 0
  checkWrite := I2C.write(mpuAdd, mpuRegAccConfig,%00001000)
  if (not checkWrite)
    FDS.str(String("setting failed"))
    return 0

PUB Scale_data(XPtr)

MPU[0] ^= MPU[1]          'Xor swap x-y axes, negate x axis
MPU[1] := MPU[0]^MPU[1]
MPU[0] := -(MPU[0]^MPU[1]) 

MPU[4] ^= MPU[5]          'Xor swap x-y axes, negate x axis
MPU[5] := MPU[4]^MPU[5]
MPU[4] := -(MPU[4]^MPU[5])

{
if calibrated                   'Subtract gyro bias vector 
  MPU[4] -= offset[0]
  MPU[5] -= offset[1]
  MPU[6] -= offset[2]    

M_MULT_INT(@MPU[0],@ACCEL_CAL,@MPU[0],@ACCEL_OFF,15)
M_MULT_INT(@MPU[7],@MAG_CAL,@MPU[7],@MAG_OFF,15)
} 
longmove(Xptr,@MPU,7)    


PUB Calc_bias | il

 