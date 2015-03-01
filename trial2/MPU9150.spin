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
PUB main | data, iter
  I2C.start(SCL,SDA)
  FDS.start(31,30,0,115_200)
  waitcnt(clkfreq + cnt)  
  FDS.tx($00)

  'Check if alive
  hiAddAlive := I2C.command(%1101_000,0)
  if hiAddAlive < 1
    FDS.str(String("no mpu detected"))
    return 0

  'Setting MPU
  checkWrite := I2C.write(mpuAdd, mpuRegPowMgmt,%11010000)
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
  
  'Getting MPU data
  
  repeat
    iter :=0  
    FDS.tx($00)
    repeat 8
      data := I2C.read(mpuAdd, 59+iter)
      FDS.hex(59+iter, 2)
      FDS.str(String(": "))
      FDS.bin(data,8)
      FDS.tx($0D)
      iter := iter + 1
    waitcnt(cnt + clkfreq/10)
  