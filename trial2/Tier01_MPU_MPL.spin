CON
  _clkmode = xtal1 + pll16x                                                      
  _xinfreq = 5_000_000

  PERCENT_CONST = 1000 
OBJ
  sensor    : "Tier00_MPU_MPL.spin"
  FDS    : "FullDuplexSerial.spin"
  f : "FloatMath"
Var
  Long gyroIntegral[0], compFilter[3], baseMag[3], gForce, mag[3]

  Long prevAccX[20], prevAccY[20], prevAccZ[20], avgAcc[3]
  
  Long raw[10], acc[3], gyro[3], temperature

PUB main



  FDS.quickStart  
  
  sensor.initSensor(15, 14)

  setting
  
  run

  
PUB setting
  'Check if alive
  if NOT(sensor.isAlive)
    FDS.strLn(String("Sensor status is bad. System abort"))
    return
  
  'Setting MPU
  sensor.setting
  
PUB run | i, j

  repeat
    'getting raw values
    sensor.getMpuData(@raw)
    repeat i from 0 to 2
      repeat j from 0 to 2
        if i==0
          acc[j] := raw[j] 
        if i==1
          gyro[j] := raw[j+3] 
          mag[j] := raw[j+6]
    temperature := raw[9]
    
    'Manpulating data for 1 tier - complementary filter, gForce
    calcCompFilter
     
    FDS.clear
    printXAxis
    waitcnt(cnt + clkfreq/10)



PUB getGForce
  gForce := (acc[0]*acc[0] + acc[1]*acc[1] + acc[2]*acc[2])/410/4100/8
                                           
PUB calcCompFilter | i, a

  a := 1000

  repeat i from 0 to 3
    prevAccX[i] := prevAccX[i+1]
  prevAccX[4] := acc[0]

  avgAcc[0] := 0
  repeat i from 0 to 4
    avgAcc[0] += prevAccX[i]/5 

  gyroIntegral[0] := gyroIntegral[0] - gyro[1]*%10110100/%1111101000
  'compFilter[0] := 0'a*(compFilter[0] - (gyro[1]))/PERCENT_CONST + ((PERCENT_CONST-a)*avgAcc[0])/PERCENT_CONST

{
  if avgAcc[0] - 20 > 0
    compFilter[0] := a*(compFilter[0] + (gyro[1]*40/100))/PERCENT_CONST + ((PERCENT_CONST-a)*avgAcc[0])/PERCENT_CONST
  elseif avgAcc[0] + 20 < 0
    compFilter[0] := a*(compFilter[0] + (gyro[1]*35/100))/PERCENT_CONST + ((PERCENT_CONST-a)*avgAcc[0])/PERCENT_CONST
  else
    compFilter[0] := avgAcc[0]
}
  'compFilter[1] := 989*(gyro[2])/PERCENT_CONST + 5*acc[1]/PERCENT_CONST
  'compFilter[2] := acc[2]

PUB getMag

PUB getTemperautre

PUB getAltitude
 

PUB getCompFilter


PUB getMagnetoMeter


PRI printXAxis | check
  FDS.str(String("Acc   ["))
  FDS.dec(acc[0])
  FDS.strLn(String("]"))
  FDS.str(String("AvgAcc["))
  FDS.dec(avgAcc[0])
  FDS.strLn(String("]"))
  FDS.str(String("Gyr   ["))
  check := gyro[1]
  FDS.dec(check)
  FDS.str(String("]"))
  if check > 0
    FDS.str(STring("++++"))
  FDS.newline
  FDS.str(String("GyrInt["))
  FDS.dec(gyroIntegral[0])
  FDS.strLn(String("]"))  
  FDS.str(String("ComFil["))  
  FDS.dec(compFilter[0])
  FDS.strLn(String("]"))


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
        FDS.decLn( -(avgAcc[j]-compFilter[j])*1000*100/avgAcc[j]/1000    )
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



        