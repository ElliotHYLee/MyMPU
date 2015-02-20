CON
  _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
  _xinfreq = 5_000_000

CON
  SCL = 15
  SDA = 14
  MPU_address = %1101_0000

PUB main