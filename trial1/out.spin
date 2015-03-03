CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

PUB main
dira[18] :=1
dira[12] :=1 
repeat
  outa[18] :=1
  outa[12] :=1 