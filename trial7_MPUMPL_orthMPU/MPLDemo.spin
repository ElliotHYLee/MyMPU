CON
_clkmode = xtal1 + pll16x                                                      
_xinfreq = 5_000_000

SCL = 15
SDA = 14

STATUS     =$00
OUT_P_MSB  =$01
OUT_P_CSB  =$02
OUT_P_LSB  =$03
OUT_T_MSB  =$04
OUT_T_LSB  =$05
DR_STATUS  =$06
OUT_P_DELTA_MSB  =$07
OUT_P_DELTA_CSB  =$08
OUT_P_DELTA_LSB  =$09
OUT_T_DELTA_MSB  =$0A
OUT_T_DELTA_LSB  =$0B
WHO_AM_I   =$0C
F_STATUS   =$0D
F_DATA     =$0E
F_SETUP    =$0F
TIME_DLY   =$10
SYSMOD     =$11
INT_SOURCE =$12
PT_DATA_CFG =$13
BAR_IN_MSB =$14
BAR_IN_LSB =$15
P_TGT_MSB  =$16
P_TGT_LSB  =$17
T_TGT      =$18
P_WND_MSB  =$19
P_WND_LSB  =$1A
T_WND      =$1B
P_MIN_MSB  =$1C
P_MIN_CSB  =$1D
P_MIN_LSB  =$1E
T_MIN_MSB  =$1F
T_MIN_LSB  =$20
P_MAX_MSB  =$21
P_MAX_CSB  =$22
P_MAX_LSB  =$23
T_MAX_MSB  =$24
T_MAX_LSB  =$25
CTRL_REG1  =$26
CTRL_REG2  =$27
CTRL_REG3  =$28
CTRL_REG4  =$29
CTRL_REG5  =$2A
OFF_P      =$2B
OFF_T      =$2C
OFF_H      =$2D
mplAdd =$60 



OBJ
  I2C    : "I2C Spin driver v1.3"
  FDS    : "FullDuplexSerial"

Var
  long array[10], regPressure, biasPressure, pressure, prevPressure[100], avgPressure
  long altitudeMeters[2], regAltitude, rawAltitude, biasAltitude, prevAlt[10], avgAlt
PUB main | a, i, dP

  fds.quickStart

  i2c.start(scl, sda)

  regPressure := 99600 'Pa
  regAltitude := 230 'meter

  if \i2c.command(mplAdd,0)
    fds.strLn(String("MPL alive"))
    fds.decLn(i2c.read(mplAdd, $0C))

    setModeAltimeter
    setOverSampleRate(7)
    enableEventFlags

  calcBias
  repeat 256
    getPressure
    getAvgPressure
  calcAlitBias
  repeat
    fds.clear
    getPressure
    fds.dec(getAvgPressure)
    fds.strLn(String(" Pa"))
    getAltitudeMeters(@altitudeMeters)
    fds.dec(getAvgAlt)
    fds.strLn(String(" m"))
    
    waitcnt(cnt+clkfreq/7)

PUB getAltitudeMeters(hPtr)
{

 H = 44330.77{1-(p/101326)^0.1902632)} + OFF_H
 can be appx. linearlized for 0 km < altitude < 40 km

 H = 44331 -  (0.12*p + 34202) + OFF_H
   = 44331 - p/10 - 34202 + OFF_H
   = 10129 - p/10 + OFF_H       
}



  Long[hPtr][0] :=  getRawAltitude - biasAltitude
  'Long[hPtr][1] :=

PUB getAvgAlt| avgCoef  , i

  avgCoef:= 10

  repeat i from 0 to (avgCoef-2)
    prevAlt[i] := prevAlt[i+1]
  prevAlt[avgCoef-1] :=  altitudeMeters[0]
    
  avgAlt := 0 
    
  repeat i from 0 to (avgCoef-1)
    avgAlt += prevAlt[i]/avgCoef 

  return avgAlt


PUB getRawAltitude

  rawAltitude := 10129 - (avgPressure+5)/10

  return rawAltitude

PUB calcAlitBias  

  getRawAltitude
  biasAltitude := 10129 - (avgPressure+5)/10 - regAltitude  
  fds.decLN(biasAltitude)
  'waitcnt(cnt+clkfreq*10)

PUB absolute(value)

  if (value<0)
    return -value
  else
    return value


PUB getAvgPressure | avgCoef  , i

  avgCoef:= 50

  repeat i from 0 to (avgCoef-2)
    prevPressure[i] := prevPressure[i+1]
  prevPressure[avgCoef-1] := pressure
    
  avgPressure := 0 
    
  repeat i from 0 to (avgCoef-1)
    avgPressure += prevPressure[i]/avgCoef 

  return avgPressure
    
PUB getPressure
  pressure := getRawPressure - biasPressure 
  return pressure

PUB calcBias | avg
  avg:=0
  repeat 100
    avg += getRawPressure

  avg := (avg)/100
  biasPressure := (avg - regPressure)

  
PRI getRawPressure | total

  toggleOneShote

  array[0] := I2C.read(mplAdd,$01)
  array[1] := I2C.read(mplAdd,$02)
  array[2] := I2C.read(mplAdd,$03)
  
  array[0] := array[0] << 10
  array[1] := array[1] <<2  
  array[2] := array[2] >> 6 

  toggleOneShote

  total := array[0] + array[1] + array[2]
  return (total)   'Pascal

PUB toggleOneShote| tempSetting

  tempSetting := i2c.read(mplAdd, CTRL_REG1)
  tempSetting &= (%01)
  i2c.write(mplAdd, CTRL_REG1, tempSetting)

  tempSetting := i2c.read(mplAdd, CTRL_REG1)
  tempSetting := (%10)
  i2c.write(mplAdd, CTRL_REG1, tempSetting)

PUB setModeAltimeter | tempSetting

  tempSetting := i2c.read(mplAdd, CTRL_REG1)
  tempSetting |= %1000_0000
  i2c.write(mplAdd, CTRL_REG1, tempSetting)

  

PUB setOverSampleRate(sampleRate)|tempSetting

 if(sampleRate > 7)
   sampleRate :=7

 tempSetting := i2c.read(mplAdd, CTRL_REG1)
 tempSetting &= %11000111
 tempSetting |= sampleRate
 i2c.write(mplAdd, CTRL_REG1, tempSetting)

PUB enableEventFlags

  i2c.write(mplAdd, PT_DATA_CFG, $07)

 