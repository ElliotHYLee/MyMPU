CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ

  i2c : "Basic_I2C_Driver.spin"
  usb : "Parallax Serial Terminal.spin"


VAR
  byte isAlive

PUB scan(scl,sda) | address , ack
 usb.start(115200)  
 scl:=15
 sda:=14

 i2c.Initialize(scl)
 waitcnt(clkfreq+cnt)      
 repeat
  usb.clear
  address :=0
  repeat address from 0 to 255 step 2 'why not 1?
    i2c.start(scl)
    ack := i2c.write(scl,address)
    i2c.stop(scl)
    'usb.dec(ack) 
    if (ack ==0)
      usb.newline
      usb.bin(address,8)
  usb.newline
  usb.str(String("end of line"))
  waitcnt(clkfreq+cnt)