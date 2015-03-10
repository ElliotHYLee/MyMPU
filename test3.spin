CON
  _clkmode = xtal1 + pll16x                                                    
  _xinfreq = 5_000_000

OBJ
  usb : "FullDuplexSerial.spin"

Var

 Long x,y

PUB main

  usb.quickStart
  
  repeat
    x := %1100_1111_0000_0000 
    usb.clear
    usb.decLn(x)
    usb.str(String("x:   "))
    usb.binLn(x,32)
    usb.str(String("x+1: "))
    usb.binLn(x + 1, 32)
    usb.str(String("~x:  "))    'making the bits as 2'c complement
    usb.bin(~x,32)
    usb.newline
    usb.str(String("~~x: "))
    x := %1111_1111_1111_1111  
    usb.binLn(~~x,32)

    usb.strLn(String("so"))
    usb.dec(x)
    
    
    waitcnt(cnt + clkfreq)
    