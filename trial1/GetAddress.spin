CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ

  i2c : "Basic_I2C_Driver.spin"
  usb : "Parallax Serial Terminal.spin"
  const : "Constants"

VAR
  byte isAlive

PUB scan(scl,sda) | address
 usb.start(115200)  
 scl:= 18
 sda:= 17

 i2c.Initialize(scl,sda)
 waitcnt(clkfreq*2+cnt)      
 repeat
  usb.clear
  address :=0
  repeat address from 0 to 255 step 2 'why not 1?
    if i2c.devicePresent(scl,sda,address)
      usb.newline
      usb.bin(address,8)
  usb.newline
  usb.str(String("end of line"))
  waitcnt(clkfreq+cnt)

  