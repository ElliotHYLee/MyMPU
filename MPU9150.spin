CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ

  i2c : "Basic_I2C_Driver.spin"
  usb : "Parallax Serial Terminal.spin"
  const : "Constants"

VAR
  byte isAlive

PUB main

  usb.start(115200)

  repeat 3
    usb.str(String("run"))
    usb.newline

  i2c.initialize(const#SCL, const#SDA)  
  usb.str(String("i2c initialized"))
  usb.newline
  usb.str(String("checking if responding..."))
  usb.newline
  waitcnt(cnt+ clkfreq*5)

  isAlive := i2c.devicePresent(const#SCL,const#SDA,const#MPU_address )
  if isAlive==1
    usb.str(String("Sensor is on"))
  else
    usb.str(String("No sensor detected"))
    usb.newline