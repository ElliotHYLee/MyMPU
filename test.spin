CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ

  i2c : "Basic_I2C_Driver.spin"
  usb : "Parallax Serial Terminal.spin"

VAR
  LONG data


PUB main | a, b
  usb.start(115200)
  data := 567

  usb.dec(data)
  usb.newline

  'testPtr(@data)

  repeat
    usb.clear
    repeat a from 1 to 6
      repeat b from 1 to 10
        usb.bin(a,5)
        usb.str(String(" & "))
        usb.bin(b,5)
        usb.str(String(" = "))
        usb.bin(a&b,5)
        usb.str(String("     "))
        usb.dec(a)
        usb.str(String(" & "))
        usb.dec(b)
        usb.str(String(" = "))
        usb.dec(a&b)
        usb.newline
      usb.str(String("------------------"))
      usb.newline
    waitcnt(cnt + clkfreq*10)

    
PUB testPtr(xx)| a,b,c, x
  usb.hex(xx,5)
  usb.newline
  usb.dec(LONG[xx])
  x := ~~LONG[xx]
  usb.dec(x)
  usb.newline
