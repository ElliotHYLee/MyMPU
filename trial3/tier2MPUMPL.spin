CON
  _clkmode = xtal1 + pll16x                                                    
  _xinfreq = 5_000_000

PERCENT_CONST = 1000

OBJ
  sensor    : "Tier1MPUMPL.spin"
  FDS    : "FullDuplexSerial.spin"
  
Var
  Long compFilter[3], baseMag[3], gForce, mag[3]

  Long prevAccX[20], prevAccY[20], prevAccZ[20], avgAcc[3]
  
  Long acc[3], gyro[3], temperature

PUB main

  FDS.quickStart  
  
  sensor.initSensor(15, 14)

  sensor.mpuSetting
  
  run

PUB run

  repeat
    sensor.getMpuData(@acc, @gyro, @temperature)
    sensor.getAk8Data(@mag)
    calcCompFilter
    FDS.clear
    printAll

PUB calcCompFilter | i, a, avgCoef, intCoef

  a := 950
  avgCoef:= 10
  repeat i from 0 to (avgCoef-2)
    prevAccX[i] := prevAccX[i+1]
  prevAccX[avgCoef-1] := acc[0]

  avgAcc[0] := 0
  repeat i from 0 to (avgCoef-1)
    avgAcc[0] += prevAccX[i]/avgCoef 

  if avgAcc[0] > 500
  compFilter[0] := a*(compFilter[0] - (gyro[1]*500/10))/PERCENT_CONST + ((PERCENT_CONST-a)*avgAcc[0])/PERCENT_CONST

{  
  intCoef := 8000
  if gyro[1] < 0
    compFilter[0] := a*(compFilter[0] - (gyro[1]*intCoef/100))/PERCENT_CONST + ((PERCENT_CONST-a)*avgAcc[0])/PERCENT_CONST
  else
    compFilter[0] := a*(compFilter[0] - (gyro[1]*(10000-intCoef)/100))/PERCENT_CONST + ((PERCENT_CONST-a)*avgAcc[0])/PERCENT_CONST
  'else
  '  compFilter[0] := avgAcc[0]

 }
  'compFilter[1] := 989*(gyro[2])/PERCENT_CONST + 5*acc[1]/PERCENT_CONST
  'compFilter[2] := acc[2]

PUB getMag

PUB getTemperautre

PUB getAltitude
 

PUB getCompFilter


PUB getMagnetoMeter



PRI printAll | i, j
  repeat i from 0 to 2
    repeat j from 0 to 2
      if i==0
        FDS.str(String("Acc["))
        FDS.dec(j)
        FDS.str(String("]=  "))      
        FDS.dec(acc[j])
        FDS.str(String(" AvgAcc["))
        FDS.dec(j)
        FDS.str(String("]=  "))      
        FDS.decLn(avgAcc[j])
        
        FDS.str(String("Comp["))
        FDS.dec(j)
        FDS.str(String("]= "))      
        FDS.dec(compFilter[j])
        FDS.str(String("  err: "))
        FDS.decLn( -(avgAcc[j]-compFilter[j])*90/16800    )
      if i==1
        FDS.str(String("Gyro["))
        FDS.dec(j)
        FDS.str(String("]= "))      
        FDS.decLn(gyro[j])
      if i ==2
        FDS.str(String("Mag["))
        FDS.dec(j)
        FDS.str(String("]= "))      
        FDS.decLn(mag[j])
  FDS.Str(String("Tempearture = "))
  FDS.decLn(temperature)
  FDS.Str(String("gForce = "))
  FDS.decLn(gForce)
