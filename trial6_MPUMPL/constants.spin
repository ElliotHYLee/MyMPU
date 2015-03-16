CON
_clkmode = xtal1 + pll16x                                                      
_xinfreq = 5_000_000

SCL = 15
SDA = 14


''==========================
''MPL3115A2 - Barometer
''==========================
MPL_STATUS     =$00
MPL_OUT_P_MSB  =$01
MPL_OUT_P_CSB  =$02
MPL_OUT_P_LSB  =$03
MPL_OUT_T_MSB  =$04
MPL_OUT_T_LSB  =$05
MPL_DR_STATUS  =$06
MPL_OUT_P_DELTA_MSB  =$07
MPL_OUT_P_DELTA_CSB  =$08
MPL_OUT_P_DELTA_LSB  =$09
MPL_OUT_T_DELTA_MSB  =$0A
MPL_OUT_T_DELTA_LSB  =$0B
MPL_WHO_AM_I   =$0C
MPL_F_STATUS   =$0D
MPL_F_DATA     =$0E
MPL_F_SETUP    =$0F
MPL_TIME_DLY   =$10
MPL_SYSMOD     =$11
MPL_INT_SOURCE =$12
MPL_PT_DATA_CFG =$13
MPL_BAR_IN_MSB =$14
MPL_BAR_IN_LSB =$15
MPL_P_TGT_MSB  =$16
MPL_P_TGT_LSB  =$17
MPL_T_TGT      =$18
MPL_P_WND_MSB  =$19
MPL_P_WND_LSB  =$1A
MPL_T_WND      =$1B
MPL_P_MIN_MSB  =$1C
MPL_P_MIN_CSB  =$1D
MPL_P_MIN_LSB  =$1E
MPL_T_MIN_MSB  =$1F
MPL_T_MIN_LSB  =$20
MPL_P_MAX_MSB  =$21
MPL_P_MAX_CSB  =$22
MPL_P_MAX_LSB  =$23
MPL_T_MAX_MSB  =$24
MPL_T_MAX_LSB  =$25
MPL_CTRL_REG1  =$26
MPL_CTRL_REG2  =$27
MPL_CTRL_REG3  =$28
MPL_CTRL_REG4  =$29
MPL_CTRL_REG5  =$2A
MPL_OFF_P      =$2B
MPL_OFF_T      =$2C
MPL_OFF_H      =$2D
mplAdd =$60 


''==============================
''MPU 9150 - Attitude Sensers
''==============================
mpuAdd = $68
MPU_AUX_VDDIO          = $01   
MPU_SMPLRT_DIV         = $19   
MPU_CONFIG             = $1A   
MPU_GYRO_CONFIG        = $1B   
MPU_ACCEL_CONFIG       = $1C   
MPU_FF_THR             = $1D   
MPU_FF_DUR             = $1E   
MPU_MOT_THR            = $1F   
MPU_MOT_DUR            = $20   
MPU_ZRMOT_THR          = $21   
MPU_ZRMOT_DUR          = $22   
MPU_FIFO_EN            = $23   
MPU_I2C_MST_CTRL       = $24   
MPU_I2C_SLV0_ADDR      = $25   
MPU_I2C_SLV0_REG       = $26   
MPU_I2C_SLV0_CTRL      = $27   
MPU_I2C_SLV1_ADDR      = $28   
MPU_I2C_SLV1_REG       = $29   
MPU_I2C_SLV1_CTRL      = $2A   
MPU_I2C_SLV2_ADDR      = $2B   
MPU_I2C_SLV2_REG       = $2C   
MPU_I2C_SLV2_CTRL      = $2D   
MPU_I2C_SLV3_ADDR      = $2E   
MPU_I2C_SLV3_REG       = $2F   
MPU_I2C_SLV3_CTRL      = $30   
MPU_I2C_SLV4_ADDR      = $31   
MPU_I2C_SLV4_REG       = $32   
MPU_I2C_SLV4_DO        = $33   
MPU_I2C_SLV4_CTRL      = $34   
MPU_I2C_SLV4_DI        = $35     
MPU_I2C_MST_STATUS     = $36   
MPU_INT_PIN_CFG        = $37   
MPU_INT_ENABLE         = $38   
MPU_INT_STATUS         = $3A     
MPU_ACCEL_XOUT_H       = $3B     
MPU_ACCEL_XOUT_L       = $3C     
MPU_ACCEL_YOUT_H       = $3D     
MPU_ACCEL_YOUT_L       = $3E     
MPU_ACCEL_ZOUT_H       = $3F     
MPU_ACCEL_ZOUT_L       = $40     
MPU_TEMP_OUT_H         = $41     
MPU_TEMP_OUT_L         = $42     
MPU_GYRO_XOUT_H        = $43     
MPU_GYRO_XOUT_L        = $44     
MPU_GYRO_YOUT_H        = $45     
MPU_GYRO_YOUT_L        = $46     
MPU_GYRO_ZOUT_H        = $47     
MPU_GYRO_ZOUT_L        = $48     
MPU_EXT_SENS_DATA_00   = $49     
MPU_EXT_SENS_DATA_01   = $4A     
MPU_EXT_SENS_DATA_02   = $4B     
MPU_EXT_SENS_DATA_03   = $4C     
MPU_EXT_SENS_DATA_04   = $4D     
MPU_EXT_SENS_DATA_05   = $4E     
MPU_EXT_SENS_DATA_06   = $4F     
MPU_EXT_SENS_DATA_07   = $50     
MPU_EXT_SENS_DATA_08   = $51     
MPU_EXT_SENS_DATA_09   = $52     
MPU_EXT_SENS_DATA_10   = $53     
MPU_EXT_SENS_DATA_11   = $54     
MPU_EXT_SENS_DATA_12   = $55     
MPU_EXT_SENS_DATA_13   = $56     
MPU_EXT_SENS_DATA_14   = $57     
MPU_EXT_SENS_DATA_15   = $58     
MPU_EXT_SENS_DATA_16   = $59     
MPU_EXT_SENS_DATA_17   = $5A     
MPU_EXT_SENS_DATA_18   = $5B     
MPU_EXT_SENS_DATA_19   = $5C     
MPU_EXT_SENS_DATA_20   = $5D     
MPU_EXT_SENS_DATA_21   = $5E     
MPU_EXT_SENS_DATA_22   = $5F     
MPU_EXT_SENS_DATA_23   = $60     
MPU_MOT_DETECT_STATUS  = $61     
MPU_I2C_SLV0_DO        = $63   
MPU_I2C_SLV1_DO        = $64   
MPU_I2C_SLV2_DO        = $65   
MPU_I2C_SLV3_DO        = $66   
MPU_I2C_MST_DELAY_CTRL = $67   
MPU_SIGNAL_PATH_RESET  = $68   
MPU_MOT_DETECT_CTRL    = $69   
MPU_USER_CTRL          = $6A   
MPU_PWR_MGMT_1         = $6B   
MPU_PWR_MGMT_2         = $6C   
MPU_FIFO_COUNTH        = $72   
MPU_FIFO_COUNTL        = $73   
MPU_FIFO_R_W           = $74   
MPU_WHO_AM_I           = $75   



PUB dummy