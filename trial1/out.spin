CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

PUB main
dira[18] :=1
dira[1] :=1 
repeat
  outa[2] :=1
  outa[1] :=1 