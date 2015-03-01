CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ

  i2c : "Basic_I2C_Driver.spin"
  usb : "Parallax Serial Terminal.spin"

VAR
  LONG data

PUB main
  usb.start(115200)
  data := %1

  usb.bin(data <<24, 25)
  usb.newline

  data <-= 2
  usb.bin(data , 25)
  usb.newline

  
