/*
 *                  _     _  __  __ ___  __  __
 *                 (_)   | ||  \/  |__ \|  \/  |
 *  _ __ __ _ _ __  _  __| || \  / |  ) | \  / |
 * | '__/ _` | '_ \| |/ _` || |\/| | / /| |\/| |
 * | | | (_| | |_) | | (_| || |  | |/ /_| |  | |
 * |_|  \__,_| .__/|_|\__,_||_|  |_|____|_|  |_|
 *           | |
 *           |_|
 *
 * @version 20190704
 *
 * Revision history:
 * 20190729 01v002
 * - Reading the acceleration data from the LIS3DSH has been optimised
 * 20190704 01v001
 * - If the current connection type is "Online" and the connection is interrupted, the system  
 *   automatically tries to re-establish the connection.
 */

 /* Path for hardware-specific include file */
#include ".\rapidM2M M2\mx.inc"
#include "sht31.inc"
#include "lis3dsh.inc"

/* pin configuration */
const
{
  PIN_LED2   = 0,                                                 // LED 2: Green
  PIN_LED1_R = 1,                                                 // RGB LED 1: Red
  PIN_LED1_G = 2,                                                 // RGB LED 1: Green
  PIN_LED1_B = 3,                                                 // RGB LED 1: Blue
  PIN_LED3   = 4,                                                 // LED 3: Green
  PIN_ACC_CS = 5,                                                 // CS signal accelerometer
  IRQ_KEY    = 0,                                                 // IRQ for the key
  PORT_I2C   = 0,                                                 // I2C Port used for communication with Temperature/Humidity sensor
  CNT_RESET_TIME     = 5000,                                      // Time (ms) for which the button must be pressed to start
                                                                  // a connection 
};


/* Standard values to initialise the configuration */
const
{
  ITV_RECORD         = 1 * 60,                                     // Record interval [sec.], default 1 min
  ITV_TRANSMISSION   = 1 * 60 * 60,                                // Transmission interval [sec.], default 60 min
  TXMODE             = RM2M_TXMODE_TRIG,                           // Connection type, default "Interval"
  HUMIDITY_WARN      = 300,                                        // Default humidity warning threshold
  HUMIDITY_ALERT     = 400,                                        // Default humidity alerting threshold
  THRESHOLD_ACCPOS   = 75,                                         // Default accelerometer up (positive) threshold
  THRESHOLD_ACCNEG   = -75,                                        // Default accelerometer down (negative) threshold

  TX_RETRY_MAX      = 10,                                          // Maximum retries for establishing the online connection
  TX_RETRY_INTERVAL = 60 * 60,                                     // Waiting time before restarting the connection attempts [sec.], default 60min
}
/* Size and index specifications for the configuration blocks and measurement data block */
const
{
  CFG_BASIC_INDEX    = 0,                                           // Config block 0 contains the basic config
  CFG_BASIC_SIZE     = 9,                                           // Record interval (u32) + transmission interval (u32) +
                                                                    // Connection type (u8)
  CFG_HUMIDITY_INDEX = 1,                                           // Config block 1 contains the air humidity config
  CFG_HUMIDITY_SIZE  = 4,                                           // Warning threshold (s16) + Alerting threshold (s16)
  CFG_ACC_INDEX      = 2,                                           // Config block 2 contains the accelerometer config
  CFG_ACC_SIZE       = 4,                                           // Threshold Up (s16) + Threshold Down (s16)
  HISTDATA_SIZE      = 2 * 8  + 1,                                  // 8 channel (8 x s16) + "Split-tag" (u8)
}

static const caAppId{}    = "Base_Starter_Demo";                    // Global value of application Id
static const caAppVers{}  = "01v002";                               // Global value of application version


/* This table is used to convert the raw value to the angle */ 
 static aAgnleTable[9][TablePoint] = [                              
  [ -16800, -90],
  [ -15500,  -68],
  [ -11900,  -45],
  [ -6500,  -23],
  [ -70,  0],
  [ 6200,  23],
  [ 11700,  45],
  [ 15300,  68],
  [ 16600,  90]
];

/* forward declarations of public functions */
forward public MainTimer();                 // Called up 1x per sec. for the program sequence
forward public InitTimer();   
forward public ReadConfig(cfg);             // Called up when one of the config blocks is changed
forward public KeyChanged(iKeyState);       // Called up when the button is pressed or released
forward public KeyDetectLong();             // Called up when the timer to detect a long key press has
                                            // expired

/* Global variables declarations */
static iBattVIn;                            // Store the battery voltage value
static iVIn;                                // Store the input voltage value
static iCounter;                            // Store the button counter value
static iTemperature;                        // Store current temperature value
static iHumidity;                           // Store current humidity value
static ixAngle,iyAngle,izAngle;             // Store X,Y and Z angle for accelerometer
static iLongPushDetected;                   // Long key press detected

/* Handles for available sensors */
static hTempRh[TSHT31_Handle];
static hACC[TLIS3DSH_Handle];

/* Global variables to store the current configuration */
static iRecItv;                             // Current record interval [sec.]
static iTxItv;                              // Current transmission interval [sec.]
static iTxMode;                             // Current connection type (0 = interval, 1 = wakeup,
                                            // 2 = online)    
static iHumidity_Warn;                      // Humidity warning threshold
static iHumidity_Alert;                     // Humidity alerting threshold
static iThresholdAccPositive;               // Accelerometer positive threshold
static iThresholdAccNegative;               // Accelerometer negative threshold
                                                                   

/* Global variables for the remaining time until certain actions are triggered */
static iRecTimer;                            // Sec. until the next recording  
static iTxTimer;                             // Sec. until the next transmission


/* init states */
const
{
  INIT_START = 0,
  INIT_TEMP_RH_WAIT,
  INIT_TEMP_RH,
  INIT_ACC
};

/* PoC runtime variables */
static sPoC_Vars[.init];

/* application entry point */
main()
{
 /* Temporary memory for the index of a public function and the return value of a function  */
  new iIdx, iResult;
  
  /* Initialisation of application specific memory blocks                                    */
  PipApp_Init();
  
  /* Initialisation of the interrupt input used for the button.
     - Determining the function index that should be called up when pressing the button
     - Transferring the index to the system and informing it that an interrupt should
       accrue on a falling edge (i.e. button pressed)
     - Index and return value of the init function are issued by the console                */
  iIdx = funcidx("KeyChanged");                        
  iResult = rM2M_IrqInit(IRQ_KEY, RM2M_IRQ_FALLING, iIdx);  
  printf("rM2M_IrqInit(%d) = %d\r\n", iIdx, iResult);
  
  /* Initialisation of a 1 sec. timer used for the general program sequence
     - Determining the function index that should be executed 1x per sec.
     - Transferring the index to the system
     - Index and function return value used to generate the timer are issued via the console */
  iIdx = funcidx("MainTimer");
  iResult = rM2M_TimerAdd(iIdx);
  printf("rM2M_TimerAddExt(%d) = %d\r\n", iIdx, iResult);
  
  /* start init handler */
  InitHandler();
  
  /* Specification of the function that should be called up when a config block is changed
     - Determining the function index called up when changing one of the config blocks
     - Transferring the index to the system
     - Index and init function return values are issued via the console                      */
  iIdx = funcidx("ReadConfig");
  iResult = rM2M_CfgOnChg(iIdx);
  printf("rM2M_CfgOnChg(%d) = %d\r\n", iIdx, iResult);

  /* Read out the basic, air humidity and accelerometer configuration. 
     If config block 0, 1 and 2 are still empty (first program start), the
     basic, air humidity and accelerometer configuration are initialised with 
	 the standard values.                                                                       */
  ReadConfig(CFG_BASIC_INDEX);
  ReadConfig(CFG_HUMIDITY_INDEX);
  ReadConfig(CFG_ACC_INDEX);

  /* Setting the counters to 0 immediately triggers a transmission and a recording.
     You could also refrain from setting it to 0, as all variables in PAWN are initialised with 0
     when they are created. However, it was completed at this point for the purpose of a better
     understanding. */
  iTxTimer  = 0;
  iRecTimer = 0;

 /* Setting the connection type */
  rM2M_TxSetMode(iTxMode);
}

PipApp_Init()
{
  new aAppId{50};                                                // Temporary memory to read the application Id from the system
  new aAppVers{15};                                              // Temporary memory to read the application version from the system
  
  rM2M_RegGetString(RM2M_REG_APP_OTP, "pipAppId", aAppId);       // Reads an application Id from a registration memory block
  if(aAppId != caAppId)                                          // If the received value does not correspond to that of the global variables->
    rM2M_RegSetString(RM2M_REG_APP_OTP, "pipAppId", caAppId);    // Writes a global value of application Id into a registration memory block
  
  rM2M_RegGetString(RM2M_REG_APP_OTP, "pipAppVer", aAppVers);    // Reads an application version from a registration memory block
  if(aAppVers != caAppVers)                                      // If the received value does not correspond to that of the global variables->
    rM2M_RegSetString(RM2M_REG_APP_OTP, "pipAppVer", caAppVers); // Writes a global value of application version into a registration memory block

}

/* 1 sec. timer is used for the general program sequence */
public MainTimer()
{  
  Handle_SHT31();                                 // SHT31 handler
  Handle_LIS3DSH();                               // Accelerometer handler
  Handle_Transmission();                          // Control of the transmission
  Handle_Record();                                // Control of the record  
}


public InitTimer()
{
  InitHandler();
}


// Initialise i2c
InitHandler()
{
  new iTimeout = 0;
  /* Temporary memory for the index of a public function and the return value of a function        */
  new iIdx, iResult;

  if(sPoC_Vars.init == INIT_START)
  {
    /* set PIN_LEDx as signalling output with init state OFF (0) */
    rM2M_GpioSet(PIN_LED1_R, RM2M_GPIO_LOW);
    rM2M_GpioDir(PIN_LED1_R, RM2M_GPIO_OUTPUT);
    rM2M_GpioSet(PIN_LED1_G, RM2M_GPIO_LOW);
    rM2M_GpioDir(PIN_LED1_G, RM2M_GPIO_OUTPUT);
    rM2M_GpioSet(PIN_LED1_B, RM2M_GPIO_LOW);
    rM2M_GpioDir(PIN_LED1_B, RM2M_GPIO_OUTPUT);
    rM2M_GpioSet(PIN_LED2, RM2M_GPIO_LOW);
    rM2M_GpioDir(PIN_LED2, RM2M_GPIO_OUTPUT);
    rM2M_GpioSet(PIN_LED3, RM2M_GPIO_LOW);
    rM2M_GpioDir(PIN_LED3, RM2M_GPIO_OUTPUT); 

    /* proceed immediately */
    iTimeout = 1;
    sPoC_Vars.init = INIT_TEMP_RH;
  }
  else if(sPoC_Vars.init == INIT_TEMP_RH)
  {
    /* init I2C #0 with 400kHz clock */
    iResult = rM2M_I2cInit(PORT_I2C, 400000, 0);
    
    /* init SHT31 (Temp and RH measurement) */
    iResult = SHT31_Init(hTempRh, PORT_I2C, SHT31_I2C_ADR_A);
    if(iResult >= OK)
      printf("SHT31 OK\r\n");
    else
      printf("SHT31_Init() = %d\r\n", iResult);

    rM2M_I2cClose(PORT_I2C);
    
    /* Note:
     * 50ms delay without I2C communication is required after SHT31_Init (SoftReset) */
    iTimeout = 100;
    sPoC_Vars.init = INIT_TEMP_RH_WAIT;
  }
  else if(sPoC_Vars.init == INIT_TEMP_RH_WAIT)
  {
    /* init I2C #0 with 400kHz clock */
    iResult = rM2M_I2cInit(PORT_I2C, 400000, 0);
    
    /* trigger measurement: periodic 1 mps, medium repeatability */
    iResult = SHT31_TriggerMeasurement(hTempRh, SHT31_CMD_MEAS_PERI_1_H);
    if(iResult < OK)
      printf("SHT31_TriggerMeasurement failed with %d\r\n", iResult);

    rM2M_I2cClose(PORT_I2C);

    /* proceed with init */
    iTimeout = 1;
    sPoC_Vars.init = INIT_ACC;
  }
  else if(sPoC_Vars.init == INIT_ACC)
  {
     /* init SPI #0 with 1MHz clock (clock polarity idle low) */
    iResult = rM2M_SpiInit(hACC.spi, LIS3DSH_SPICLK, LIS3DSH_SPIMODE);
    if(iResult < OK)
      printf("rM2M_SpiInit() = %d\r\n", iResult);
      
    /* init LIS3DSH accelerometer (SPI #0) */
    iResult = LIS3DSH_Init(hACC, PIN_ACC_CS, 0);
    if(iResult >= OK)
    {
      /* X, Y, Z enabled, ODR = 6.25 Hz */
      LIS3DSH_Write(hACC, LIS3DSH_REG_CTRL4, LIS3DSH_ODR_6HZ25|0x7);
      printf("LIS3DSH OK\r\n");
    }
    else
    {
      printf("LIS3DSH_Init: %d\r\n", iResult);
    }
    
    rM2M_SpiClose(hACC.spi);
  }

  if(iTimeout > 0)
  {
    iIdx = funcidx("InitTimer");
    iResult = rM2M_TimerAddExt(iIdx, false, iTimeout);
    if(iResult < OK)
      printf("InitHandler: rM2M_TimerAddExt failed with %d\r\n", iResult);
  }
}


Handle_LIS3DSH()
{
  /* configure SPI for LIS3D(S)H */
  rM2M_SpiInit(hACC.spi, LIS3DSH_SPICLK, LIS3DSH_SPIMODE);
  
  new iX, iY, iZ;
 
  LIS3DSH_Read(hACC, LIS3DSH_REG_OUT_X, iX);
  LIS3DSH_Read(hACC, LIS3DSH_REG_OUT_Y, iY);
  LIS3DSH_Read(hACC, LIS3DSH_REG_OUT_Z, iZ);
  
  /* Converting raw values to Angle */
  CalcTable(iX, ixAngle, aAgnleTable);         // Converts x axis raw value to angle
  CalcTable(iY, iyAngle, aAgnleTable);         // Converts y axis raw value to angle
  CalcTable(iZ, izAngle, aAgnleTable);         // Converts y axis raw value to angle

  if (iyAngle > iThresholdAccPositive) {       // facing up i.e. if y Angle > Accelerometer Up Threshold
    rM2M_GpioSet(PIN_LED2, RM2M_GPIO_LOW);     // set the LED2 to low
    rM2M_GpioSet(PIN_LED3, RM2M_GPIO_HIGH);    // set the LED3 to high
  }
  else if (iyAngle < iThresholdAccNegative) {  // facing down i.e. if y Angle < Accelerometer Up Threshold
    rM2M_GpioSet(PIN_LED3, RM2M_GPIO_LOW);     // set the LED3 to low
    rM2M_GpioSet(PIN_LED2, RM2M_GPIO_HIGH);    // set the LED2 to high 
  }
  else {                                       // no indication
    rM2M_GpioSet(PIN_LED3, RM2M_GPIO_LOW);     // set both LED to low
    rM2M_GpioSet(PIN_LED2, RM2M_GPIO_LOW);
  }
  
  rM2M_SpiClose(hACC.spi);
}


/* External temperature reading from SHT31*/
Handle_SHT31()
{
  new iResult;
  new iTemp, iRh;

  /* init I2C #0 with 400kHz clock */
  rM2M_I2cInit(PORT_I2C, 400000, 0);
 
  iResult = SHT31_ReadMeasurement(hTempRh, iTemp, iRh);

  if(iResult >= OK)
  {
    iTemperature = iTemp;
    iHumidity = iRh;
  }
  else
  {
    /* NOTE: probably NACK received indicating that no measurement data is present.      */
    printf("SHT31_ReadMeasurement failed with %d\r\n", iResult);
  }
  rM2M_I2cClose(PORT_I2C);
  
  /* If iHumidity is less than 300 (i.e. 30.0) then only LED1 green state should be high */
  if(iHumidity<iHumidity_Warn){
  rM2M_GpioSet(PIN_LED1_R, RM2M_GPIO_LOW);
  rM2M_GpioSet(PIN_LED1_G, RM2M_GPIO_HIGH);
  rM2M_GpioSet(PIN_LED1_B, RM2M_GPIO_LOW);
  }
  /* If iHumidity is between 300 and 400 (i.e. 30.0 and 40.0) then only LED1 yellow 
     (combination of green and red) state should be high                                 */
  else if(iHumidity >= iHumidity_Warn && iHumidity <= iHumidity_Alert){
  rM2M_GpioSet(PIN_LED1_R, RM2M_GPIO_HIGH);
  rM2M_GpioSet(PIN_LED1_G, RM2M_GPIO_HIGH);
  rM2M_GpioSet(PIN_LED1_B, RM2M_GPIO_LOW); 
  }
  /* If iHumidity is more than 400 (i.e. 40.0) then only LED1 red state should be high   */
  else if(iHumidity > iHumidity_Alert){
  rM2M_GpioSet(PIN_LED1_R, RM2M_GPIO_HIGH);
  rM2M_GpioSet(PIN_LED1_G, RM2M_GPIO_LOW);
  rM2M_GpioSet(PIN_LED1_B, RM2M_GPIO_LOW); 
  }
}


/* Function to generate the transmission interval */
Handle_Transmission()
{
  new iResult;                                // Temporary memory for the return value of a function

  if(iTxMode == RM2M_TXMODE_ONLINE)           // If the current connection type is "Online"
  {
    new iTxCurrentState;                      // Temporary memory for the current connection status
    static iForceOnlineTry;                   // Retry counter for establishing the online connection 
    static iTxRetriggerTimer;                 // Counter for restarting the connection tries (sec. until the next retry 
                                              // to establish the online connection if the max retries are exceeded)
 
    iTxCurrentState = rM2M_TxGetStatus();     // Gets the current connection status 
  
    /* Temporary memory indicating if the device is currently connecting to the server or already connected to the server.
       Is 0 if the connection is not active, has not started, is not waiting for next automatic retry and is not disabled */
    new iIsConnected = iTxCurrentState & (RM2M_TX_ACTIVE|RM2M_TX_STARTED|RM2M_TX_RETRY|RM2M_TX_DISABLED);

    if((iIsConnected == 0) && (iTxTimer > 5) && ((iTxItv - iTxTimer) > 10) && (iForceOnlineTry < TX_RETRY_MAX))
    {
      /* Force reconnection to get back into "Online" mode by setting the counter counting down the sec. to the next 
         transmission to 0 if 
           - the connection is not active, has not started, is not waiting for next automatic retry and is not disabled
           - AND connection is not starting within the next 5 seconds
           - AND connection was not triggered 10 seconds ago
	   - AND max retries were not reached
         Note: Max retry recommended!								                                                       */
      iTxTimer = 0;
    
      iForceOnlineTry++;                      // Increases counter for the retries to establishing the online connection
      if(iForceOnlineTry >= TX_RETRY_MAX)     // If max retries exceeded ->
      {
        iTxRetriggerTimer = TX_RETRY_INTERVAL;// Sets Counter for restarting the connection tries to TX_RETRY_INTERVAL seconds
      }
    }
  
    /* Wait until iTxRetriggerTimer is 0 to restart connection tries */
    if(iTxRetriggerTimer > 0)                 // If the counter for restarting the connection tries has not expired -> 
    {
      iTxRetriggerTimer--;                    // Counting down the sec. until the connection attempts are restarted
      if(iTxRetriggerTimer <= 0)              // When the counter has expired -> 
      {
        iForceOnlineTry = 0;                  // Resets the retry counter for establishing the online connection
      }
    }
  }

  iTxTimer--;                                                   // Counter counting down the sec. to the next transmission
  if(iTxTimer <= 0)                                             // When the counter has expired ->
  {
    /* If the device is currently in "Online" mode, the rM2M_TxStart() function only initiates a 
	   synchronisation of the configuration, registration and measurement data with the server.
       If the device is not online, the function initiates a connection to the server and the system 
	   (Firmware) automatically synchronises the configuration, registration and measurement data 
	   with the server. In any case the return value of the function is issued via the console.         */  
	iResult = rM2M_TxStart();
    if(iResult < OK)
      printf("rM2M_TxStart() = %d\r\n", iResult);
    
    iTxTimer = iTxItv;                                          // Resets counter var. to current transmission interval [sec.] 
  }
}


/* Function for recording the data */
Handle_Record()                                     
{
  iRecTimer--;                                                  // Decrementing the counter counting down the seconds to the
                                                                // next recording 
  if(iRecTimer <= 0)                                            // When the counter has expired 
  {
    new sSysValues[TMx_SysValue];                               // Temporary memory for the internal measurement values  
    
    Mx_GetSysValues(sSysValues);                                // Reads the last valid values for Vin and Vaux from the system 
                                                                // The interval for determining these values is 1sec. and cannot be changed.
    iBattVIn = sSysValues.VAux;                                 // Copies the currently read battery voltage to the global variable
    iVIn     = sSysValues.VIn;                                  // Copies the currently read input voltage to the global variable
  
    /* Temporary memory in which the data record to be saved is compiled */
    new aRecData{HISTDATA_SIZE};

    /* Compile the data record to be saved in the "aRecData" temporary memory
       - The first byte (position 0 in the "aRecData" array) is set to 0 so that the server copies
         the data record into measurement data channel 0 upon receipt, as specified during the design
         of the connector:
       - The SHT 31 temperature i.e. iTemperature is copied to position 1-2. Data type: s16 
       - The SHT 31 humidity i.e. iHumidity is copied to position 3-4. Data type: s16 
       - The battery voltage i.e. iBattVIn is copied to position 5-6. Data type: s16 
       - The input voltage i.e. iVIn is copied to position 7-8. Data type: s16 
       - The button counter i.e. iCounter is copied to position 9-10. Data type: s16 
       - The accelerometer X Angle i.e. ixAngle is copied to position 11-12. Data type: s16 
       - The accelerometer Y Angle i.e. iyAngle is copied to position 13-14. Data type: s16 
       - The accelerometer Z Angle i.e. izAngle is copied to position 15-16. Data type: s16 */
    aRecData{0} = 0;     // "Split-tag"
    rM2M_Pack(aRecData,   1,   iTemperature,  RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,   3,   iHumidity,     RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,   5,   iBattVIn,      RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,   7,   iVIn,          RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,   9,   iCounter,      RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,  11,   ixAngle,       RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,  13,   iyAngle,       RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,  15,   izAngle,       RM2M_PACK_BE + RM2M_PACK_S16);    

    /* Transfer the data record to the system */
    rM2M_RecData(0, aRecData, HISTDATA_SIZE);
    /* Issue all values via console */
    printf("Bat Volt(mV): %d; Vin (mV): %d; Angle (X,Y,Z): %d %d %d; rh: %.1f;  temp: %.2f °C; counter: %d \n",
      iBattVIn,
      iVIn,
      ixAngle,
      iyAngle,
      izAngle,
      iHumidity / 10.0,
      iTemperature / 100.0,
      iCounter);
      
    iRecTimer = iRecItv;                       // Reset counter variable to current record interval 
  }
}

/* Function that enables a transmission to be triggered when the button is pressed */
public KeyChanged(iKeyState)
{
  
  new iIdx,iResult;
  iResult = rM2M_IrqClose(IRQ_KEY);
  if(iResult < OK)
    printf("[KEY] rM2M_IrqClose(0)=%d\r\n", iResult);

  if(!iKeyState)                               // If the button has been pressed ->
  {
    iCounter++;                                // Increment the counter value
    printf("Counter : %d \r\n", iCounter);     // Issue the counter value via the console 
    /* Starts a timer by means of which a long key press is to be detected. If the timer expires, a
     flag is set by the function transferred.
    - Determining the function index that should be called up when the timer expires
    - Transferring the index to the system                                                             */
    iIdx=funcidx("KeyChanged");
    iResult = rM2M_IrqInit(IRQ_KEY, RM2M_IRQ_RISING,iIdx);
    if(iResult < OK)
      printf("[KEY] rM2M_IrqInit(%d)=%d\r\n", iIdx, iResult);

    iIdx = funcidx("KeyDetectLong");
    rM2M_TimerAddExt(iIdx, false, CNT_RESET_TIME);
  }
  else                                      // Otherwise -> If the button has been released ->
  {
    iIdx=funcidx("KeyChanged");
    iResult = rM2M_IrqInit(IRQ_KEY, RM2M_IRQ_FALLING,iIdx);
    if(iResult < OK)
      printf("[KEY] rM2M_IrqInit(%d)=%d\r\n", iIdx, iResult);
      
    if(iLongPushDetected)                   // If the button has been pressed for a long time ->
    {
      printf("[KEY] Long Key detected and key released\r\n");
      iLongPushDetected = 0;                // Delete "long key press detected" flag
      /* Set count variable for seconds until the next transmission to 0. This ensures that a transmission
         is triggered the next time the "Handle_Transmission" function is called up by the "MainTimer"
         function.                                                                                      */
      iTxTimer = 0;
    }
    else                                    // Otherwise (i.e. the button was pressed only briefly) ->
    {
     /* Delete the timer for long keystroke detection if the button has been pressed only for a short
         time so that it cannot expire and therefore the "long key press detected" flag is not set.
         - Determining the function index that should be called up when the timer expires
         - Transferring the index to the system so that the timer can be deleted
         - If it was not possible to delete the timer -> Index and TimerRemove function return values
           are issued via the console                                                                   */
      iIdx = funcidx("KeyDetectLong");
      iResult = rM2M_TimerRemoveExt(iIdx);
      if(iResult != OK) 
        printf("rM2M_TimerRemove(%d) = %d\r\n", iIdx, iResult);
    }
  } 
}

/* Function that is called when the timer to detect a long key press has expired  */
public KeyDetectLong()
{
  print("Long Push Detected\r\n");          // Issue the detection of a long key press via the console
  iLongPushDetected = 1;                    // Set "long key press detected" flag
}

/* Function that makes it possible to react to a changed configuration received from the server */
public ReadConfig(cfg)
{
  /* If the changed configuration is the basic config -> */
  if(cfg == CFG_BASIC_INDEX)                
  {
    new aData{CFG_BASIC_SIZE};                                // Temporary memory for the basic config read from the system
    new iSize;                                                // Temporary memory for the size of the basic config in bytes
    new iTmp;                                                 // Temporary memory for a basic config parameter
  
    /* Read config 0 data from the system and copy it to the temporary memory. The
       number of the config block and return value of the read function (number of bytes or error code)
       are then issued via the console */	
    iSize = rM2M_CfgRead(cfg, 0, aData, CFG_BASIC_SIZE);
    printf("Cfg %d size = %d\r\n", cfg, iSize);   

    /* If the number of read bytes is lower than the size of the basic config ->
       Info: Error codes are negative */
    if(iSize < CFG_BASIC_SIZE)              
    {
      /* The following block initially copies the default values of config 0 to the temporary memory for the read
         basic config and then sets the temporary memory for the size of the basic config to the current
         size. This ensures that the following "IF" is executed during re-initialisation and when
         changes are received. If special actions have to be executed for individual parameters,
         it is thus not necessary to implement these separately for both cases.                        */
      iTmp = ITV_RECORD;
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_U32);
      iTmp = ITV_TRANSMISSION;
      rM2M_Pack(aData, 4, iTmp,   RM2M_PACK_BE + RM2M_PACK_U32);
      iTmp = TXMODE;
      rM2M_Pack(aData, 8, iTmp,  RM2M_PACK_BE + RM2M_PACK_U8);
      iSize = CFG_BASIC_SIZE;
      print("created new Config #0\r\n");
    }


    /* If the number of read bytes at least equates to the size of the basic config ->                  */
    if(iSize >= CFG_BASIC_SIZE)
    {
      /* Copy record interval (u32, Big Endian) at position 0-3 from the temporary memory for the read
         basic config 0 into the temporary memory for a parameter                                       */
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_U32 + RM2M_PACK_GET);
      if(iTmp != iRecItv)                                      //If the received value does not correspond to that of the global variables->
      {
        printf("iRecItv changed to %d s\r\n", iTmp);           // Issue received value via the console
        iRecItv = iTmp;                                        // Copy received value into global variable
        iRecTimer = iTmp;                                      // Use timer immediately
      }
      
      /* Copy transmission interval (u32, Big Endian) at position 4-7 from the temporary memory for the
         read basic config 0 into the temporary memory for a parameter                                   */
      rM2M_Pack(aData, 4, iTmp,  RM2M_PACK_BE + RM2M_PACK_U32 + RM2M_PACK_GET);
      if(iTmp != iTxItv)                                      //If the received value does not correspond to that of the global variables->
      {
        printf("iTxItv changed to %d s\r\n", iTmp);           // Issue received value via the console
        iTxItv = iTmp;                                        // Copy received value into the global variable
        iTxTimer = iTmp;                                      // Use Timer immediately
      }

      /* Copy connection type (u8) at position 8 from the temporary memory for the read basic config 0 into
         the temporary memory for a parameter                                                            */
      rM2M_Pack(aData, 8, iTmp,  RM2M_PACK_BE + RM2M_PACK_U8 + RM2M_PACK_GET);
      if(iTmp != iTxMode)                                    //If the received value does not correspond to that of the global variables->
      {
        rM2M_TxSetMode(iTmp);                                // Set connection type to the received value
        printf("iTxMode changed to %d\r\n", iTmp);           // Issue received value via the console
        iTxMode = iTmp;                                      // Copy received value into the global variable
      }
    }
  }
  /* If the changed configuration is the air humidity config -> */
  else if(cfg == CFG_HUMIDITY_INDEX)
  {
  
    new aData{CFG_HUMIDITY_SIZE};                             // Temporary memory for the config 1 data read from the system
    new iSize;                                                // Temporary memory for the size of the config 1 data in bytes
    new iTmp;                                                 // Temporary memory for a config 1 data parameter
  
    /* Read config 1 data from the system and copy it to the temporary memory. The
       number of the data block and return value of the read function (number of bytes or error code)
       are then issued via the console */	
    iSize = rM2M_CfgRead(cfg, 0, aData, CFG_HUMIDITY_SIZE);
    printf("Cfg %d size = %d\r\n", cfg, iSize);  
 

    /* If the number of read bytes is lower than the size of the config 1  ->
       Info: Error codes are negative */
    if(iSize < CFG_HUMIDITY_SIZE)              
    {
      /* The following block initially copies the default values of config 1 to the temporary memory for the read
         config 1 and then sets the temporary memory for the size of the config 1 to the current
         size. This ensures that the following "IF" is executed during re-initialisation and when
         changes are received. If special actions have to be executed for individual parameters,
         it is thus not necessary to implement these separately for both cases.                          */
      iTmp = HUMIDITY_WARN;
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_S16);
      iTmp = HUMIDITY_ALERT;
      rM2M_Pack(aData, 2, iTmp,   RM2M_PACK_BE + RM2M_PACK_S16);
      iSize = CFG_HUMIDITY_SIZE;
      print("created new Config #1\r\n");
    }


    /* If the number of read bytes at least equates to the size of the config1 ->                         */
    if(iSize >= CFG_HUMIDITY_SIZE)
    {
      /* Copy humidity warning threshold (s16) at position 0-1 from the temporary memory for the read
         config 1 into the temporary memory for a parameter                                               */	
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_S16 + RM2M_PACK_GET);
      if(iTmp != iHumidity_Warn)                                     //If the received value does not correspond to that of the global variables->
      {
        printf("iHumidity_Warn changed to %d \r\n", iTmp);           // Issue received value via the console
        iHumidity_Warn = iTmp;                                       // Copy received value into global variable
      }
      
      /* Copy humidity alerting threshold (s16) at position 2-3 from the temporary memory for the
         read config 1 into the temporary memory for a parameter                                          */
      rM2M_Pack(aData, 2, iTmp,  RM2M_PACK_BE + RM2M_PACK_S16 + RM2M_PACK_GET);
      if(iTmp != iHumidity_Alert)                                      //If the received value does not correspond to that of the global variables->
      {
        printf("iHumidity_Alert changed to %d \r\n", iTmp);            // Issue received value via the console
        iHumidity_Alert = iTmp;                                        // Copy received value into the global variable
      }
    }
  }
    /* If the changed configuration is the accelerometer config -> */
  else if(cfg == CFG_ACC_INDEX)
  {
  
    new aData{CFG_ACC_SIZE};                                  // Temporary memory for the config 2 data read from the system
    new iSize;                                                // Temporary memory for the size of the config 2 data in bytes
    new iTmp;                                                 // Temporary memory for a config 2 data parameter
  
      /* Read config 2 data from the system and copy to the temporary memory. The
         number of the data block and return value of the read function (number of bytes or error code)
         are then issued via the console */	
    iSize = rM2M_CfgRead(cfg, 0, aData, CFG_ACC_SIZE);
    printf("Cfg %d size = %d\r\n", cfg, iSize);  
 

    /* If the number of read bytes is lower than the size of the config 2 ->
         Info: Error codes are negative */
    if(iSize < CFG_ACC_SIZE)              
    {
       /* The following block initially copies the default values of config 2 to the temporary memory for the read
          config 2 and then sets the temporary memory for the size of the config 2 to the current
          size. This ensures that the following "IF" is executed during re-initialisation and when
          changes are received. If special actions have to be executed for individual parameters,
          it is thus not necessary to implement these separately for both cases.                        */
      iTmp = THRESHOLD_ACCPOS;
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_S16);
      iTmp = THRESHOLD_ACCNEG;
      rM2M_Pack(aData, 2, iTmp,   RM2M_PACK_BE + RM2M_PACK_S16);
      iSize = CFG_ACC_SIZE;
      print("created new Config #2\r\n");
    }

      /* If the number of read bytes at least equates to the size of the config 2 ->                     */
    if(iSize >= CFG_ACC_SIZE)
    {
      /* Copy accelerometer positive threshold (s16) at position 0-1 from the temporary memory for the read
         config 2 into the temporary memory for a parameter                                              */	
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_S16 + RM2M_PACK_GET);
      if(iTmp != iThresholdAccPositive)                                      //If the received value does not correspond to that of the global variables->
      {
        printf("iThresholdAccPositive changed to %d \r\n", iTmp);            // Issue received value via the console
        iThresholdAccPositive = iTmp;                                        // Copy received value into global variable
      }
      
      /* Copy accelerometer negative threshold (s16) at position 2-3 from the temporary memory for the
         read config 2 into the temporary memory for a parameter                                         */
      rM2M_Pack(aData, 2, iTmp,  RM2M_PACK_BE + RM2M_PACK_S16 + RM2M_PACK_GET);
      if(iTmp != iThresholdAccNegative)                                      //If the received value does not correspond to that of the global variables->
      {
        printf("iThresholdAccNegative changed to %d \r\n", iTmp);            // Issue received value via the console
        iThresholdAccNegative = iTmp;                                        // Copy received value into the global variable
      }
    }
  }
}
