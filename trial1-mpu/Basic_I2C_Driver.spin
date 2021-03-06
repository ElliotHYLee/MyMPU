CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

   ACK      = 0                        ' I2C Acknowledge
   NAK      = 1                        ' I2C No Acknowledge
   Xmit     = 0                        ' I2C Direction Transmit
   Recv     = 1                        ' I2C Direction Receive
   BootPin  = 28                       ' I2C Boot EEPROM SCL Pin
   EEPROM   = $A0                      ' I2C EEPROM Device Address

   I2CDelay  = 25_000                  'delay to lower speed to 100KHz
   I2CDelayS = 80_000_000/1_000                  'clock stretch delay

PUB Initialize(SCL,SDA)               ' An I2C device may be left in an
                         '  invalid state and may need to be
   outa[SCL] := 1                      '   reinitialized.  Drive SCL high.
   dira[SCL] := 1
   dira[SDA] := 0                      ' Set SDA as input
   repeat 9
      outa[SCL] := 0                   ' Put out up to 9 clock pulses
      outa[SCL] := 1
      if ina[SDA]                      ' Repeat if SDA not driven high
         quit                          '  by the EEPROM


PUB devicePresent(SCL,SDA,deviceAddress) | ackbit
  ' send the deviceAddress and listen for the ACK
   Start(SCL,SDA)
   ackbit := WriteNS(SCL,SDA,deviceAddress | 0)
   Stop(SCL,SDA)

   return (ackbit==ACK)
   
'   if ackbit == ACK  'my comment: ACK = 0 <- this means alive
'     return 1
'   else
'     return 0

PUB Start(SCL,SDA)                    ' SDA goes HIGH to LOW with SCL HIGH
   
   outa[SCL]~~                         ' Initially drive SCL HIGH
   dira[SCL]~~
   outa[SDA]~~                         ' Initially drive SDA HIGH
   dira[SDA]~~
   'waitcnt(clkfreq / I2CDelay + cnt)
   outa[SDA]~                          ' Now drive SDA LOW
   outa[SCL]~                          ' Leave SCL LOW
   return SDA
   
PUB Stop(SCL,SDA)                    ' SDA goes LOW to HIGH with SCL High
   
   outa[SCL]~~                         ' Drive SCL HIGH
   outa[SDA]~~                         '  then SDA HIGH
   dira[SCL]~                          ' Now let them float
   dira[SDA]~                          ' If pullups present, they'll stay HIGH

PUB WriteNS(SCL,SDA, data) : ackbit 
'' Write i2c data.  Data byte is output MSB first, SDA data line is valid
'' only while the SCL line is HIGH.  Data is always 8 bits (+ ACK/NAK).
'' SDA is assumed LOW and SCL and SDA are both left in the LOW state.
'' Doesn't do clock stretching so would work without pull-up on SCL
'   
   ackbit := 0 
   data <<= 24
   repeat 8                            ' Output data to SDA
      outa[SDA] := (data <-= 1) & 1
      outa[SCL]~~                      ' Toggle SCL from LOW to HIGH to LOW
      outa[SCL]~
   dira[SDA]~                          ' Set SDA to input for ACK/NAK
   outa[SCL]~~
   ackbit := ina[SDA]                  ' Sample SDA when SCL is HIGH
   outa[SCL]~
   outa[SDA]~                          ' Leave SDA driven LOW
   dira[SDA]~~
   
PUB Write(SCL,SDA, data) : ackbit | wait
'' Write i2c data.  Data byte is output MSB first, SDA data line is valid
'' only while the SCL line is HIGH.  Data is always 8 bits (+ ACK/NAK).
'' SDA is assumed LOW and SCL and SDA are both left in the LOW state.
'' Requires pull-up on SCL
'
   
   ackbit := 0 
   data <<= 24
   repeat 8                            ' Output data to SDA
     outa[SDA] := (data <-= 1) & 1
     dira[SCL]~                        ' Toggle SCL from LOW to HIGH to LOW
     'waitcnt(500 + cnt)
     wait := cnt
     repeat while 0 == ina[SCL]
       if (cnt-wait) > I2CDelayS
         quit
     dira[SCL]~~
   dira[SDA]~                          ' Set SDA to input for ACK/NAK
   dira[SCL]~
   'waitcnt(500 + cnt)
   wait := cnt
   repeat while 0 == ina[SCL]
     if (cnt-wait) > I2CDelayS
       quit
   ackbit := ina[SDA]                  ' Sample SDA when SCL is HIGH
   dira[SCL]~~
   outa[SDA]~                          ' Leave SDA driven LOW
   dira[SDA]~~

 
PUB ReadNS(SCL,SDA, ackbit):data
'' Read in i2c data, Data byte is output MSB first, SDA data line is
'' valid only while the SCL line is HIGH.  SCL and SDA left in LOW state.
'' Doesn't do clock stretching so would work without pull-up on SCL
'   
   data := 0
   dira[SDA]~                          ' Make SDA an input
   repeat 8                            ' Receive data from SDA
      dira[SCL]~                      ' Sample SDA when SCL is HIGH
      data := (data << 1) | ina[SDA]
      dira[SCL]~~
      
   outa[SDA] := ackbit                 ' Output ACK/NAK to SDA
   dira[SDA]~~
   dira[SCL]~                          ' Toggle SCL from LOW to HIGH to LOW
   dira[SCL]~~
   outa[SDA]~                          ' Leave SDA driven LOW

PUB Read(SCL,SDA, ackbit):data
'' Read in i2c data, Data byte is output MSB first, SDA data line is
'' valid only while the SCL line is HIGH.  SCL and SDA left in LOW state.
'' Requires pull-up on SCL     
'
'   
   data := 0
   dira[SDA]~                          ' Make SDA an input
   repeat 8                            ' Receive data from SDA
     dira[SCL]~                        ' Sample SDA when SCL is HIGH
     data := (data << 1) | ina[SDA]
     dira[SCL]~~

   outa[SDA] := ackbit                 ' Output ACK/NAK to SDA
   dira[SDA]~~
   dira[SCL]~                          ' Toggle SCL from LOW to HIGH to LOW
   dira[SCL]~~
   outa[SDA]~                          ' Leave SDA driven LOW
{

PUB ReadSensors(SCL,SDA, devSel, addrReg, dataPtr, count, MSB) : ackbit | il
'' Read in a block of i2c data.  Device select code is devSel.  Device starting
'' address is addrReg.  Data address is at dataPtr.  Number of bytes is count.
'' The device select code is modified using the upper 3 bits of the 19 bit addrReg.
'' Return zero if no errors or the acknowledge bits if an error occurred.

   Start(SCL,SDA)                          ' Select the device & send address
   ackbit := WriteNS(SCL,SDA, devSel | Xmit)
   ackbit := (ackbit << 1) | WriteNS(SCL,SDA, addrReg & $FF)          
   Start(SCL,SDA)                          ' Reselect the device for reading
   ackbit := (ackbit << 1) | WriteNS(SCL,SDA, devSel | Recv)

   count--                      'zero base index offset
   
   if MSB == 1
      repeat il from 0 to count - 1
        LONG[dataPtr][il] := (ReadNS(SCL,SDA, ACK)<<8) | (ReadNS(SCL,SDA, ACK) & $ff)
        ~~LONG[dataPtr][il]
      LONG[dataPtr][count] := (ReadNS(SCL,SDA, ACK)<<8) | (ReadNS(SCL,SDA, NAK) & $ff)
      ~~LONG[dataPtr][count]

   else
      repeat il from 0 to count - 1
        LONG[dataPtr][il] := (ReadNS(SCL,SDA, ACK) & $ff) | (ReadNS(SCL,SDA, ACK) << 8)
        ~~LONG[dataPtr][il]
      LONG[dataPtr][count] := (ReadNS(SCL,SDA, ACK) & $ff) | (ReadNS(SCL,SDA, NAK) << 8)
      ~~LONG[dataPtr][count]
      
      
   Stop(SCL,SDA)
   return ackbit
}   
PUB ReadSensors(SCL,SDA, devSel, addrReg, dataPtr, count, MSB) | recAck
   {

    @param SCL: SCL pin number
    @param SDA: SDA pin number
    @param devSel: device address
    @param addreReg: register address
    @param dataPtr: data array pointer [10]
    @param count :
    @param MSB: most significant bit. When 1, first 8 bits

    @Requires: I2C status = started
    @Updates: dataPtr
   }
  start(SCL, SDA)
  recAck := writeNS(SCL, SDA, devSel)
  if (recAck<>ACK)
    return  -1
  recAck := writeNS(SCL, SDA, addrReg+1)
  start(SCL, SDA)
  recACK := writeNS(SCL, SDA, devSel |1)
  LONG[dataPtr][1] := (readNS(SCL, SDA, 1)<< 8)
  stop(SCL, SDA)
    
  
  
   


    
PUB writeLocation(SCL,SDA,device_address, register, value)

  start(SCL,SDA)
  writeNS(SCL,SDA,device_address)
  writeNS(SCL,SDA,register)
  writeNS(SCL,SDA,value)  
  stop (SCL,SDA)

PUB writeByte(SCL,SDA,device_address, register)
  start(SCL,SDA)
  writeNS(SCL,SDA,device_address)
  writeNS(SCL,SDA,register)
  stop(SCL,SDA)

PUB readLocation(SCL,SDA,device_address,addr)

  start(SCL,SDA)
  writeNS(SCL,SDA,device_address | 1)

  LONG[addr][0] := (readNS(SCL,SDA,ACK)<<8) | readNS(SCL,SDA,ACK) 
  LONG[addr][1] := (readNS(SCL,SDA,ACK)<<8) | readNS(SCL,SDA,NAK) 

  stop(SCL,SDA)

PUB readLocation8(SCL,SDA,device_address, register) : value
  start(SCL,SDA)
  writeNS(SCL,SDA,device_address | 0)
  writeNS(SCL,SDA,register)
  start(SCL,SDA)
  writeNS(SCL,SDA,device_address | 1)  
  value := readNS(SCL,SDA,NAK)
  stop(SCL,SDA)
  return value

PUB readLocation16(SCL,SDA,device_address, register) : value
  start(SCL,SDA)
  writeNS(SCL,SDA,device_address | 0)
  writeNS(SCL,SDA,register)
  start(SCL,SDA)
  writeNS(SCL,SDA,device_address | 1)
  value := readNS(SCL,SDA,ACK)
  value <<= 8
  value |= (readNS(SCL,SDA,NAK) & $ff)
  stop(SCL,SDA)
    
  return value

PUB readLocation24(SCL,SDA,device_address, register) : value
  start(SCL,SDA)
  writeNS(SCL,SDA,device_address | 0)
  writeNS(SCL,SDA,register)
  start(SCL,SDA)
  writeNS(SCL,SDA,device_address | 1)  
  value := readNS(SCL,SDA,ACK)
  value <<= 8
  value |= (readNS(SCL,SDA,ACK) & $ff)
  value <<= 8
  value |= (readNS(SCL,SDA,NAK) & $ff)
  value >>= 5
  stop(SCL,SDA)
  return value

PUB ReStart(SCL,SDA)                   ' SDA goes HIGH to LOW with SCL HIGH
   SDA := SCL + 1
   outa[SDA]~~                         ' Initially drive SDA HIGH
   dira[SDA]~~
   outa[SCL]~~                         ' Initially drive SCL HIGH
   'waitcnt(clkfreq / I2CDelay + cnt)
   outa[SDA]~                          ' Now drive SDA LOW
   'waitcnt(clkfreq / I2CDelay + cnt)
   outa[SCL]~                          ' Leave SCL LOW

PUB Start_Read(SCL,SDA,device_address) : value
  start(SCL,SDA)
  writeNS(SCL,SDA,device_address | 1)  
  