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
 * @version 20190809
 * 
 * Revision history:
 * 20190809
 * - First version
 */

 /* Path for hardware-specific include file */
#include ".\rapidM2M M2\mx.inc"

#include "sht31.inc"
#include "lis3dsh.inc"
#include "Alarm.inc"

#define ALARM_HYST        (0.05)                                  // Hysteresis for releasing an active alarm (0.05 ^= 5%)

/* pin configuration */
const
{
  PIN_LED2   = 0,                                                 // LED 2: Green
  PIN_LED1_R = 1,                                                 // RGB LED 1: Red
  PIN_LED1_G = 2,                                                 // RGB LED 1: Green
  PIN_LED1_B = 3,                                                 // RGB LED 1: Blue
  PIN_LED3   = 4,                                                 // LED 3: Green
  PIN_ACC_CS = 5,                                                 // CS signal accelerometer
  PORT_I2C   = 0,                                                 // I2C port used for communication with Temperature/Humidity sensor
  PORT_SPI   = 0,                                                 // SPI port used for communication with accelerometer

  IRQ_KEY = 0,                                                    // Interruptible pin "INT0" is used for the button   
  
  LED_ENABLE     = RM2M_GPIO_HIGH,                                // By setting the GPIO to "high" the LED is turned on
  LED_DISABLE    = RM2M_GPIO_LOW,                                 // By setting the GPIO to "low" the LED is turned off
};

/* LED configuration */
const
{
  // Operating mode of RGB LED 1
  LED_MODE_OFF   = 0,                                             // LED is disabled
  LED_MODE_TEMP  = 1,                                             // Displays the current alarm/warning state for the temperature measurement channel
  LED_MODE_MAGIC = 2,                                             // LED is used for the magic trick
  
  LED1_R = 0x01,                                                  // Bit that is assigned to the red colour of the RGB LED1   (0^=Off; 1=^On)
  LED1_G = 0x02,                                                  // Bit that is assigned to the green colour of the RGB LED1 (0^=Off; 1=^On)
  LED1_B = 0x04,                                                  // Bit that is assigned to the blue colour of the RGB LED1  (0^=Off; 1=^On)  
  
  // State/colour of RGB LED 1
  LED1_OFF   = 0x00,
  LED1_RED   = 0x01,
  LED1_GREEN = 0x02,
  LED1_YELLOW= 0x03,
  LED1_BLUE  = 0x04,
  LED1_CYAN  = 0x06,
  LED1_WHITE = 0x07,
  											
  VALUE_MAX=1030,                                                 // G-force equivalent to an angle of 90° [mg] 
};

//State that can be displayed via LED 2
const
{  
  STATE_OFF   = 0,                                                // Device is offline (not connected) or in "Wakeup" mode   (LED2 off)	
  STATE_ON,                                                       // Device is connected to the server                       (LED2 on)
  STATE_SLOW,                                                     // Connection establishment failed                         (LED2 blinking)
  STATE_FAST,                                                     // Connection establishment has started or 
                                                                  // is waiting for the next automatic retry                 (LED2 flickering)	  
};

// Index of the measurement data channel
const
{
  CH_TEMPERATURE = 0,
  CH_HUMIDITY,
  CH_ANGLE_X,
  CH_ANGLE_Y,  
  CH_ANGLE_Z,  
  CH_BATTERY_VOLTAGE,
  CH_INPUT_VOLTAGE,
  CH_LED_STATE,
  CH_GSM_LEVEL,
}

// Possible alarm/warning states
const
{											
  ALARM_HIGH   = (AL_FLG_ALARM|AL_FLG_WARNING), 		          // Measurement value has met or exceeded the "alarm threshold high" 
  WARNING_HIGH = (AL_FLG_WARNING),              		          // Measurement value has met or exceeded the "warning threshold high"
  NO_ALARM     = 0,                             		          // Measurement value is lower than "warning threshold high" and greater than "warning threshold low"  
  WARNING_LOW  = (AL_FLG_UNDERFLOW | AL_FLG_WARNING),	          // Measurement value has dropped to or below the "warning threshold low"
  ALARM_LOW    = (AL_FLG_UNDERFLOW | AL_FLG_ALARM|AL_FLG_WARNING),// Measurement value has dropped to or below the "alarm threshold low"											
}

// Special values and limits for the 16 bit signed integer data type
const
{  
  S16_MIN           = 0x8000,                                     // Lower Limit 
  S16_MAX           = 0x7FFF,                                     // Upper Limit
  S16_STATUS_NAN    = 0x7FFF,                                     // Undefined error
  S16_STATUS_OF     = 0x7FFE,                                     // Overflow
  S16_STATUS_UF     = 0x8002,                                     // Underflow
  S16_STATUS_OL     = 0x8001,                                     // Open loop (interruption)
  S16_STATUS_SC     = 0x8000,                                     // Short circuit
};

/* Standard values to initialise the configuration */
const
{
  ITV_RECORD         = 1 * 60,                                    // Record interval [sec.], default 1 min
  ITV_TRANSMISSION   = 1 * 60 * 60,                               // Transmission interval [sec.], default 60 min
  TXMODE             = RM2M_TXMODE_TRIG,                          // Connection type, default "Interval"
  LED_MODE           = LED_MODE_OFF,                              // Operating mode of RGB LED 1, default "Temperature alarm/warning"
  
  TX_RETRY_MAX      = 10,                                         // Maximum retries for establishing the online connection
  TX_RETRY_INTERVAL = 60 * 60,                                    // Waiting time before restarting the connection attempts [sec.], default 60min  
  
  MAGIC_DELAY        = 5,                                         // Delay before activating the humidity detection again in "Magic" mode, default 5sec.
  MAGIC_ON           = 500,                                       // Threshold [%0,1rH] to switch on RGB LED 1 in "Magic" mode, default 50.0%
  MAGIC_OFF          = 1100,                                      // Threshold [mg] to switch off RGB LED 1 in "Magic" mode, default 1100mg 
}
/* Size and index specifications for the configuration blocks and measurement data block */
const
{
  CFG_BASIC_INDEX    = 0,                                         // Config block 0 contains the basic config
  CFG_BASIC_SIZE     = 10                                         // Record interval (u32) + transmission interval (u32) +
                                                                  // Connection type (u8) + LED mode (u8)
  CFG_TEMPERATURE_INDEX = 1,                                      // Config block 1 contains the temperature config
  CFG_TEMPERATURE_SIZE  = 8,                                      // Alerting threshold high (s16) + Warning threshold high (s16) + 																	
                                                                  // Alerting threshold low (s16) + Warning threshold low (s16) +
  CFG_ADVANCED_INDEX = 2,                                         // Config block 2 contains the advanced config
  CFG_ADVANCED_SIZE  = 7,                                         // Magic Delay (u8) + Magic On (u16) + Magic Off (u16) +																	
                                                                  // g-Force 90° (u16)																	
																	
  HISTDATA_INDEX = 0,                                             // Histdata channel 0 should be used for the measurement data
  HISTDATA_SIZE      = 2 * 7 + 1 + 1 +1,                          // Temp.(s16) + Humidity(s16) + x-Axis(s16) + y-Axis(s16) +
                                                                  // z-Axis(s16) + Batt. Voltage(s16) + Input Voltage(s16) +
                                                                  // LED State (u8) + GSM Leve (s8) + "Split-tag" (u8)

																	
}


/* forward declarations of public functions */
forward public MainTimer();                 // Called up 1x per sec. for the program sequence
forward public InitTimer();                 // Single shot timer to initialise the LEDs, the Temp. & RH sensor and the accelerometer
forward public Timer100ms();                // Called up every 100ms to display the current state of the connection via LED 2 
forward public ReadConfig(cfg);             // Called up when one of the config blocks is changed
forward public KeyChanged(iKeyState);       // Called up when the button is pressed or released

/* Global variables declarations */
static iBattVIn;                            // Stores the battery voltage value
static iVIn;                                // Stores the input voltage value
static iLedState;                           // Stores current state (colour) of RGB LED1 
static iTemperature;                        // Stores current temperature value
static iHumidity;                           // Stores current humidity value
static ixAngle,iyAngle,izAngle;             // Stores X, Y and Z angle for accelerometer
static iX, iY, iZ;                          // Temporary memory for g-forces read from the LIS3DSH (accelerometer)
static iGSM_Level;                          // Stores current GSM level
static iAlarmActive;                        // Stores current active alarms


/* Handles for available sensors */
static hTempRh[TSHT31_Handle];              // Handle for the SHT31 (Temp. & RH sensor)
static hACC[TLIS3DSH_Handle];               // Handle for the LIS3DSH (accelerometer)
static iStateInit;                          // State of the init process for the Temp. & RH sensor  

/* Global variables to store the current configuration */
static iRecItv;                             // Current record interval [sec.]
static iTxItv;                              // Current transmission interval [sec.]
static iTxMode;                             // Current connection type (0 = interval, 1 = wakeup,
                                            // 2 = online)
static iLED_Mode;                           // Current operating mode of the RGB LED (0 = Off, 1 = Temperature alarm/warning, 2 = "Magic")

static iMagic_Delay;                        // Current delay before activating the humidity detection again in "Magic" mode after RGB LED 1 has been switched on
static iMagic_On;                           // Current threshold [%rH] to switch on RGB LED 1 in "Magic" mode 
static iMagic_Off;                          // Current threshold [mg] to switch off RGB LED 1 in "Magic" mode 
static igForce_max;                         // Current g-force equivalent to an angle of 90° [mg]

static iTemp_Alert_high;                    // Current "alarm threshold high" for the temperature channel
static iTemp_Warning_high;                  // Current "warning threshold high" for the temperature channel
static iTemp_Warning_low;                   // Current "warning threshold low" for the temperature channel
static iTemp_Alert_low;                     // Current "alarm threshold low" for the temperature channel

/* Global variables for the remaining time until certain actions are triggered */
static iRecTimer;                           // Sec. until the next recording  
static iTxTimer;                            // Sec. until the next transmission

static iLed3_State     = STATE_OFF;         // Current state that should be displayed via LED 2
static iLed3_Timer     = 0;                 // Counter used to generate the blink interval for LED 2 
static iLed3_StateGpio = 0;                 // Current state of the GPIO used to control LED 2 

/* init states */
const
{
  INIT_START = 0,                           // Initialisation started
  INIT_SHT31_RESET,                         // Performs soft reset of the Temp. & RH sensor
  INIT_SHT31_CONFIG,                        // Configures sensor and starts measuring
  INIT_LIS3DSH,                             // Configures accelerometer
  INIT_READY                                // Temp. & RH sensor and accelerometer ready
};


/* application entry point */
main()
{
 /* Temporary memory for the index of a public function and the return value of a function  */
  new iIdx, iResult;

  /* Initialisation of the interrupt input used for the button
     - Determining the function index that should be called up when pressing the button
     - Transferring the index to the system and informing it that an interrupt should
       accrue on a falling edge (i.e. button pressed)
     - In case of a problem the index and return value of the init function are issued by the console  	*/
  iIdx = funcidx("KeyChanged");                        
  iResult = rM2M_IrqInit(IRQ_KEY, RM2M_IRQ_FALLING, iIdx);  
  if(iResult < OK)
    printf("[MAIN] rM2M_IrqInit(%d) = %d\r\n", iIdx, iResult);
  
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
  
  /* Reads out the basic configuration, temperature configuration and advanced configuration
     If config block 0 and 1 are still empty (first program start), the
     basic configuration and temperature configuration are initialised with the standard values.        */  
  ReadConfig(CFG_BASIC_INDEX);
  ReadConfig(CFG_TEMPERATURE_INDEX);
  ReadConfig(CFG_ADVANCED_INDEX);

  Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, 0, 0, 0); // Clears alarm on start
  
  /* Setting the counters to 0 immediately triggers a transmission and a recording.
     You could also refrain from setting it to 0, as all variables in PAWN are initialised with 0
     when they are created. However, it was completed at this point for the purpose of a better
     understanding. */
  iTxTimer  = 0;
  iRecTimer = 0;

 /* Setting the connection type */
  rM2M_TxSetMode(iTxMode);
}

/**
 * Function that should be called up when the button is pressed or released
 *
 * Note: An interruptible pin can only be configured to initiate the interrupt on the rising OR falling 
 *       edges. If both pressing and releasing the button should be detected when an interrupt 
 *       occurs, it is necessary to first deactivate the interrupt functionality and then activate the 
 *       interrupt functionality again, but this time for the other edge.
 *
 * @param iKeyState:s32 - Signal level at the interruptible pin after the edge that triggered the 
 *                        interrupt occurred 
 *						  0: "low" signal level
 *                        1: "high" signal level
 */
public KeyChanged(iKeyState)
{
  /* Temporary memory for the index of a public function and the return value of a function             */  
  new iIdx,iResult;
  
  /* Deactivates the interrupt functionality of the input used for the button and issues the result of  
     the close function via the console                                                                */
  iResult = rM2M_IrqClose(IRQ_KEY);
  if(iResult < OK)
    printf("[KEY] rM2M_IrqClose(0)=%d\r\n", iResult);

  if(!iKeyState)                            // If the button was pressed ->
  {
    /* Activates the interrupt functionality of the input used for the button again and issues the result of  
     the init function via the console. An interrupt should occur on a rising edge (i.e. button released) */ 
    iIdx = funcidx("KeyChanged");
    iResult = rM2M_IrqInit(IRQ_KEY, RM2M_IRQ_RISING,iIdx);
    if(iResult < OK)
      printf("[KEY] rM2M_IrqInit(%d)=%d\r\n", iIdx, iResult);
    
    printf("[KEY] Key pressed\r\n");        // Prints "[KEY] Key pressed" to the console
  }
  else                                      // Otherwise -> If the button has been released ->
  {
    /* Activates the interrupt functionality of the input used for the button again and issues the result of  
     the init function via the console. An interrupt should occur on a falling edge (i.e. button pressed) */   
    iIdx=funcidx("KeyChanged");
    iResult = rM2M_IrqInit(IRQ_KEY, RM2M_IRQ_FALLING,iIdx);
    if(iResult < OK)
      printf("[KEY] rM2M_IrqInit(%d)=%d\r\n", iIdx, iResult);
      
   
    /* Sets count variable for seconds until the next transmission to 0. This ensures that a transmission
       is triggered the next time the "Handle_Transmission" function is called up by the "Timer1s"
       function.                                                                                      */
    iTxTimer = 0;   
   
    printf("[KEY] Key released\r\n");       // Prints "[KEY] Key released" to the console
  } 
}

/* 1 sec. timer is used for the general program sequence */
public MainTimer()
{
  if(iStateInit == INIT_READY)              // If the Temp. & RH sensor and the accelerometer are ready (Init process finished)
  {
    Handle_SHT31();                         // SHT31 handler
    Handle_LIS3DSH();                       // Accelerometer handler
  }
  Handle_Transmission();                    // Control of the transmission
  Handle_Record();                          // Control of the record  
  Handle_RGB_Led();                         // Control of the LED   
  Handle_Led();                             // Control of the LED 
}


/* Single shot ms timer to initialise the Temp. & RH sensor and accelerometer.
   The "InitHandler" function restarts the timer again until the initialisation is done.        */
public InitTimer()
{
  InitHandler();                            // Initialises the Temp. & RH sensor
}


/* 100ms timer used to display current state of the connection via LED 2 */
public Timer100ms()
{
  iLed3_Timer--;                                    // Decrements the counter used to generate the blink interval for LED 2  
  if(iLed3_Timer <= 0)                              // When the counter has expired ->
  {
    if(iLed3_State == STATE_OFF)                    // If LED 2 should be off ->	
    {
      // LED off
      iLed3_StateGpio = LED_DISABLE;                // Sets current state of the GPIO used to control LED 2 to "LED_DISABLE"  
      iLed3_Timer = 0;                              // Sets the counter used to generate the blink interval to 0 	  
    }  
    else if (iLed3_State == STATE_ON)               // If LED 2 should light up ->
    {
      // LED on
      iLed3_StateGpio = LED_ENABLE;                 // Sets current state of the GPIO used to control LED 2 to "LED_ENABLE" 
      iLed3_Timer = 0                               // Sets the Counter used to generate the blink interval to 0 
    }
    else if (iLed3_State == STATE_FAST)             // If LED 2 should flicker ->
    {
	  // 100ms on, 100ms off
      if(iLed3_StateGpio)                           // If the current state of the GPIO used to control LED 2 is "LED_ENABLE"  -> Sets it to "LED_DISABLE" 
        iLed3_StateGpio = LED_DISABLE;
      else                                          // Otherwise -> Sets it to "LED_ENABLE"
        iLed3_StateGpio = LED_ENABLE;                
        
      iLed3_Timer = 0;                              // Sets the counter used to generate the blink interval to 0 
    }
    else if (iLed3_State == STATE_SLOW)             // If LED 2 should blink slowly ->
    {
      // 1 second on, 1 second off
      if(iLed3_StateGpio)                           // If the current state of the GPIO used to control LED 2 is "LED_ENABLE"  -> sets it to "LED_DISABLE"
        iLed3_StateGpio = LED_DISABLE;
      else                                          // Otherwise -> Sets it to "LED_ENABLE" 
        iLed3_StateGpio = LED_ENABLE;
        
      iLed3_Timer = 10;                             // Sets the counter used to generate the blink interval to 1 second 
    }

	if(iLED_Mode == LED_MODE_MAGIC)                 // If RGB LED1 is used for the magic trick
	{
	  rM2M_GpioSet(PIN_LED3, LED_DISABLE);          // Sets current state of the GPIO used to control LED 2 to "LED_DISABLE" 
                                                    // Displaying the current state of the connection via LED 2 is disabled in "Magic" mode	  
	}
	else
	{
      rM2M_GpioSet(PIN_LED3, iLed3_StateGpio);      // Sets the GPIO which controls the LED 2 to the detected level	
	}
  }
}

/* Initialises the Temp. & RH sensor and the accelerometer
   While the initialisation is not finished, this function starts a single shot timer which 
   calls it up again.                                                                           */ 
InitHandler()
{
  new iTimeout = 0;                                 // Interval of the timer used for the initialisation [ms] 

  /* Temporary memory for the index of a public function and the return value of a function        */
  new iIdx, iResult;

  if(iStateInit == INIT_START)                      // If the state of the init process is "Initialisation started" ->
  {
    /* Sets signal direction for GPIOs used to control LEDs to "Output" and turns off all LEDs
       Note: It is recommended to set the desired output level of a GPIO before setting the 
             signal direction for the GPIO.                                                     */
    rM2M_GpioSet(PIN_LED1_R, LED_DISABLE);          // Sets the output level of the GPIO to "low" ( LED 1: Red is off)
    rM2M_GpioDir(PIN_LED1_R, RM2M_GPIO_OUTPUT);     // Sets the signal direction for the GPIO used to control LED 1: Red 
    rM2M_GpioSet(PIN_LED1_G, LED_DISABLE);
    rM2M_GpioDir(PIN_LED1_G, RM2M_GPIO_OUTPUT);
    rM2M_GpioSet(PIN_LED1_B, LED_DISABLE);
    rM2M_GpioDir(PIN_LED1_B, RM2M_GPIO_OUTPUT);
    rM2M_GpioSet(PIN_LED2, LED_DISABLE);
    rM2M_GpioDir(PIN_LED2, RM2M_GPIO_OUTPUT);
    rM2M_GpioSet(PIN_LED3, LED_DISABLE);
    rM2M_GpioDir(PIN_LED3, RM2M_GPIO_OUTPUT); 

    iTimeout = 1;                                   // Sets the init timer to 1ms so that the InitHandler is called up again immediately
    iStateInit = INIT_SHT31_RESET;                  // Sets the state of the init process to "Perform soft reset"
  }
  else if(iStateInit == INIT_SHT31_RESET)           // Otherwise if the state of the init process is "Perform soft reset" ->  
  {
    iResult = rM2M_I2cInit(PORT_I2C, 400000, 0);    // Inits the I2C interface with 400kHz clock 
    
    /* Inits SHT31 (Temp. and rH measurement) and issues an error message if the sensor could not be initialised */
    iResult = SHT31_Init(hTempRh, PORT_I2C, SHT31_I2C_ADR_A);
    if(iResult < OK)
      printf("[INIT] SHT31_Init() = %d\r\n", iResult);

    rM2M_I2cClose(PORT_I2C);                        // Closes the I2C interface  
                                                    // Note: 50ms delay without I2C communication is required after SHT31_Init (SoftReset) 
    
    iTimeout = 100;                                 // Sets the init timer to 100ms so that this 50ms delay is observed in any case.  
    iStateInit = INIT_SHT31_CONFIG;                 // Sets the state of the init process to "Configures sensor and starts measuring"
  }
  else if(iStateInit == INIT_SHT31_CONFIG)          // Otherwise if the state of the init process is "Configures sensor and starts measuring"
  {
    iResult = rM2M_I2cInit(PORT_I2C, 400000, 0);    // Inits the I2C interface with 400kHz clock 
    
    /* Starts measurement (periodic 1 measurement per second, medium repeatability) and 
	   issues an error message if the sensor could not be initialised                                     */
    iResult = SHT31_TriggerMeasurement(hTempRh, SHT31_CMD_MEAS_PERI_1_H);
    if(iResult < OK)
      printf("[INIT] SHT31_TriggerMeasurement() = %d\r\n", iResult);

    rM2M_I2cClose(PORT_I2C);                        // Closes the I2C interface 

    iTimeout = 1;                                   // Sets the init timer to 1ms so that the InitHandler is called up again immediately
    iStateInit = INIT_LIS3DSH;                      // Sets the state of the init process to "Config accelerometer"
  }
  else if(iStateInit == INIT_LIS3DSH)               // Otherwise if the state of the init process is "Config accelerometer" ->
  {
    // Init SPI interface for communication with the LIS3DSH (accelerometer) and issues an error message if interface could not be initialised 
    iResult = rM2M_SpiInit(PORT_SPI, LIS3DSH_SPICLK, LIS3DSH_SPIMODE);
    if(iResult < OK)
      printf("[INIT] rM2M_SpiInit() = %d\r\n", iResult);
      
    iResult = LIS3DSH_Init(hACC, PIN_ACC_CS, PORT_SPI);// Inits LIS3DSH accelerometer
    if(iResult >= OK)                               // If the initialisation was successful ->
    {
      // Enables X, Y, Z axes and sets output data rate (ODR) to 6.25 Hz and check if it was sucessful
      iResult = LIS3DSH_Write(hACC, LIS3DSH_REG_CTRL4, LIS3DSH_ODR_6HZ25|0x7);
      if(iResult >= OK) printf("[INIT] LIS3DSH OK\r\n");
      else printf("[INIT] LIS3DSH_Init failed %d\r\n", iResult); 
    }
    else                                            // Otherwise ->  Issues an error message via the console
    {
      printf("[INIT] LIS3DSH_Init failed  %d\r\n", iResult);	
    }
    
    rM2M_SpiClose(PORT_SPI);                        // Closes the SPI interface 	
	
    /* Initialisation of a 100ms timer used to display current state of the connection via LED 2
       - Determining the function index that should be executed every 100ms
       - Transferring the index to the system and informing it that the timer should be restarted 
	     following expiry of the interval
	   - In case of a problem the index and return value of the init function are issued by the console  */	
    iIdx = funcidx("Timer100ms");
    iResult = rM2M_TimerAddExt(iIdx, true, 100);
    if(iResult < OK)
      printf("rM2M_TimerAddExt(%d) = %d\r\n", iIdx, iResult);	
	
    iStateInit = INIT_READY;                        // Sets the state of the init process to "ready"
  }

  if(iTimeout > 0)                                  //If the init timer should be started ->
  {
    /* Starts the init timer. If the timer expires, the "InitHandler" function is called up again by the 
       function transferred.
       - Determining the function index that should be called up when the timer expires and informing it 
         that the timer should be stopped following expiry of the interval (single shot timer)
       - Transferring the index to the system                                                              
       - If the timer could not be started, the error message is issued via the console                       */
    iIdx = funcidx("InitTimer");
    iResult = rM2M_TimerAddExt(iIdx, false, iTimeout);
    if(iResult < OK)
      printf("[INIT] rM2M_TimerAddExt failed with %d\r\n", iResult);
  }
}

/* Function for controlling the reading of the g-forces [mg] for all 3 axes of the LIS3DSH (accelerometer) and
   calculating the angles of the axes in relation to the surface of the earth                                 */
Handle_LIS3DSH()
{
  new iResult;                                         // Temporary memory for the return value of a function
   
  // Inits SPI interface for communication with the LIS3DSH (accelerometer) and issues an error message if interface could not be initialised
  iResult = rM2M_SpiInit(PORT_SPI, LIS3DSH_SPICLK, LIS3DSH_SPIMODE);
  if(iResult < OK)
    printf("[MAIN] rM2M_SpiInit() = %d\r\n", iResult);

  LIS3DSH_ReadMeasurement(hACC, iX, iY, iZ)            // Reads the g-forces [mg] for all 3 axes from the LIS3DSH (accelerometer)
  
  rM2M_SpiClose(PORT_SPI);                             // Closes the SPI interface 
	
  // Calculates the angles of the axes in relation to the surface of the earth
  ixAngle = CalcAngle(iX, igForce_max);
  iyAngle = CalcAngle(iY, igForce_max);
  izAngle = CalcAngle(iZ, igForce_max);
}


/* Function for controlling the reading of the temperature and humidity from SHT31 */
Handle_SHT31()
{
  new iResult;                                      // Temporary memory for the return value of a function  
  new iTemp, iRh;                                   // Temporary memory for the temperature and humidity read from the SHT31 (Temp. and RH sensor)

  rM2M_I2cInit(PORT_I2C, 400000, 0);                // Inits the I2C interface with 400kHz clock

  //Reads the temperature and humidity from the SHT31 (Temp. and rH sensor)
  iResult = SHT31_ReadMeasurement(hTempRh, iTemp, iRh);

  if(iResult >= OK)                                 // If the values could be read -> 
  {
    iTemperature = iTemp;                           // Copies the currently read temperature to the global variable
    iHumidity = iRh;                                // Copies the currently read humidity to the global variable
  }
  else
  {
    /* Issues an error message via the console 
	   Note: probably NACK received indicating that no measurement data is present                   */
    printf("SHT31_ReadMeasurement failed with %d\r\n", iResult);
  }
  rM2M_I2cClose(PORT_I2C);                          // Closes the I2C interface 
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
  iRecTimer--;                                      // Decrements the counter counting down the seconds to the
                                                    // next recording 
  if(iRecTimer <= 0)                                // When the counter has expired ->
  {
    new sSysValues[TMx_SysValue];                   // Temporary memory for the internal measurement values  
    Mx_GetSysValues(sSysValues);                    // Reads the last valid values for Vin and Vaux from the system 
                                                    // The interval for determining these values is 1sec. and cannot be changed.
    iBattVIn = sSysValues.VAux;                     // Copies the currently read battery voltage to the global variable
    iVIn     = sSysValues.VIn;                      // Copies the currently read input voltage to the global variable
	
    iGSM_Level = rM2M_GetRSSI();                    // Reads out the current GSM-level
  
    /* Temporary memory in which the data record to be saved is compiled */
    new aRecData{HISTDATA_SIZE};
	
    /* Compiles the data record to be saved in the "aRecData" temporary memory
       - The first byte (position 0 in the "aRecData" array) is set to 0 so that the server copies
         the data record into measurement data channel 0 upon receipt, as specified during the design
         of the connector
       - The temperature is copied to position 1-2. Data type: s16  		 
	   - The humidity is copied to position 3-4. Data type: s16 	   
	   - The accelerometer X Angle is copied to position 5-6. Data type: s16 
	   - The accelerometer Y Angle is copied to position 7-8. Data type: s16 
	   - The accelerometer Z Angle is copied to position 9-10. Data type: s16 	   
       - The input voltage is copied to position 11-12. Data type: s16	   
       - The battery voltage is copied to position 13-14. Data type: s16
       - The LED state is copied to position 15. Data type: u8
       - The GSM level is copied to position 9. Data type: s8                                    */	
    aRecData{0} = 0;     // "Split-tag"
    rM2M_Pack(aRecData,   1,   iTemperature,  RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,   3,   iHumidity,     RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,   5,   ixAngle,       RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,   7,   iyAngle,       RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,   9,   izAngle,       RM2M_PACK_BE + RM2M_PACK_S16);     
    rM2M_Pack(aRecData,  11,   iBattVIn,      RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,  13,   iVIn,          RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,  15,   iLedState,     RM2M_PACK_BE + RM2M_PACK_U8);	
    rM2M_Pack(aRecData,  16,   iGSM_Level,    RM2M_PACK_BE + RM2M_PACK_S8);
	
    /* Transfers compounded data record to the system to be recorded */
    rM2M_RecData(0, aRecData, HISTDATA_SIZE);
    
	/* Issues current measurement values via the console */
    printf("Bat Volt(mV): %d; Vin (mV): %d; Angle (X,Y,Z): %d %d %d; rh: %.1f;  temp: %.2f °C; LED: %d GSM: %d;\n",
      iBattVIn,
      iVIn,
      ixAngle,
      iyAngle,
      izAngle,
      iHumidity / 10.0,
      iTemperature / 100.0,
      iLedState,
	  iGSM_Level);
      
    iRecTimer = iRecItv;                            // Resets counter variable to current record interval 
	
	CheckAlarm();                                   // Calls up the function which checks whether an alarm has to be triggered 	
  }
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
  
    /* Reads config 0 data from the system and copies it to the temporary memory. The
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
      iTmp = LED_MODE;
      rM2M_Pack(aData, 9, iTmp,  RM2M_PACK_BE + RM2M_PACK_U8);	  	  
      iSize = CFG_BASIC_SIZE;
      print("created new Config #0\r\n");
    }


    /* If the number of read bytes at least equates to the size of the basic config ->                  */
    if(iSize >= CFG_BASIC_SIZE)
    {
      /* Copies record interval (u32, Big Endian) at position 0-3 from the temporary memory for the read
         basic config 0 into the temporary memory for a parameter                                       */
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_U32 + RM2M_PACK_GET);
      if(iTmp != iRecItv)                                     // If the received value does not correspond to that of the global variables ->
      {
        printf("iRecItv changed to %d s\r\n", iTmp);          // Issues received value via the console
        iRecItv = iTmp;                                       // Copies received value into global variable
        iRecTimer = iTmp;                                     // Uses timer immediately
      }
      
      /* Copies transmission interval (u32, Big Endian) at position 4-7 from the temporary memory for the
         read basic config 0 into the temporary memory for a parameter                                   */
      rM2M_Pack(aData, 4, iTmp,  RM2M_PACK_BE + RM2M_PACK_U32 + RM2M_PACK_GET);
      if(iTmp != iTxItv)                                      // If the received value does not correspond to that of the global variables ->
      {
        printf("iTxItv changed to %d s\r\n", iTmp);           // Issues received value via the console
        iTxItv = iTmp;                                        // Copies received value into the global variable
        iTxTimer = iTmp;                                      // Uses timer immediately
      }

      /* Copies connection type (u8) at position 8 from the temporary memory for the read basic config 0 into
         the temporary memory for a parameter                                                            */
      rM2M_Pack(aData, 8, iTmp,  RM2M_PACK_BE + RM2M_PACK_U8 + RM2M_PACK_GET);
      if(iTmp != iTxMode)                                     // If the received value does not correspond to that of the global variables ->
      {
        rM2M_TxSetMode(iTmp);                                 // Sets connection type to the received value
        printf("iTxMode changed to %d\r\n", iTmp);            // Issues received value via the console
        iTxMode = iTmp;                                       // Copies received value into the global variable
      }
	    
      /* Copies LED mode (u8) at position 9 from the temporary memory for the read basic config 0 into
         the temporary memory for a parameter                                                            */
      rM2M_Pack(aData, 9, iTmp,  RM2M_PACK_BE + RM2M_PACK_U8 + RM2M_PACK_GET);
      if(iTmp != iLED_Mode)                                   // If the received value does not correspond to that of the global variables ->
      {
        printf("iLED_Mode changed to %d\r\n", iTmp);          // Issues received value via the console
        iLED_Mode = iTmp;                                     // Copies received value into the global variable
      }	    
    }
  }
  /* If the changed configuration is the temperature config -> */
  else if(cfg == CFG_TEMPERATURE_INDEX)
  {
    new aData{CFG_TEMPERATURE_SIZE};                          // Temporary memory for the config 1 data read from the system
    new iSize;                                                // Temporary memory for the size of the config 1 data in bytes
    new iTmp;                                                 // Temporary memory for a config 1 data parameter

    /* Reads config 1 data from the system and copies it to the temporary memory. The
       number of the data block and return value of the read function (number of bytes or error code)
       are then issued via the console */	
    iSize = rM2M_CfgRead(cfg, 0, aData, CFG_TEMPERATURE_SIZE);
    printf("Cfg %d size = %d\r\n", cfg, iSize);  	

    /* If the number of read bytes is lower than the size of the config 1  ->
       Info: Error codes are negative */
    if(iSize < CFG_TEMPERATURE_SIZE)              
    {
      /* The following block initially copies the default values of config 1 to the temporary memory for the read
         config 1 and then sets the temporary memory for the size of the config 1 to the current
         size. This ensures that the following "IF" is executed during re-initialisation and when
         changes are received. If special actions have to be executed for individual parameters,
         it is thus not necessary to implement these separately for both cases.                          */
      iTmp = S16_STATUS_NAN;
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_S16);
      iTmp = S16_STATUS_NAN;
      rM2M_Pack(aData, 2, iTmp,   RM2M_PACK_BE + RM2M_PACK_S16);
      iTmp = S16_STATUS_NAN;
      rM2M_Pack(aData, 4, iTmp,   RM2M_PACK_BE + RM2M_PACK_S16);
      iTmp = S16_STATUS_NAN;
      rM2M_Pack(aData, 6, iTmp,   RM2M_PACK_BE + RM2M_PACK_S16);	  
      iSize = CFG_TEMPERATURE_SIZE;
      print("created new Config #1\r\n");  
    }
	
    /* If the number of read bytes at least equates to the size of the config1 ->                         */
    if(iSize >= CFG_TEMPERATURE_SIZE)
    {
      /* Copies temperature alerting threshold high(s16) at position 0-1 from the temporary memory for the read
         config 1 into the temporary memory for a parameter                                               */	
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_S16 + RM2M_PACK_GET);
      if(iTmp != iTemp_Alert_high)                            // If the received value does not correspond to that of the global variables ->
      {
        printf("iTemp_Alert_high changed to %d \r\n", iTmp);  // Issues received value via the console
        iTemp_Alert_high = iTmp;                              // Copies received value into global variable
      }
      
      /* Copies temperature warning threshold high(s16) at position 2-3 from the temporary memory for the
         read config 1 into the temporary memory for a parameter                                          */
      rM2M_Pack(aData, 2, iTmp,  RM2M_PACK_BE + RM2M_PACK_S16 + RM2M_PACK_GET);
      if(iTmp != iTemp_Warning_high)                          // If the received value does not correspond to that of the global variables ->
      {
        printf("iTemp_Warning_high changed to %d \r\n", iTmp);// Issues received value via the console
        iTemp_Warning_high = iTmp;                            // Copies received value into the global variable
      }
	  
	  
      /* Copies temperature warning threshold low(s16) at position 0-1 from the temporary memory for the read
         config 1 into the temporary memory for a parameter                                               */	
      rM2M_Pack(aData, 4, iTmp,  RM2M_PACK_BE + RM2M_PACK_S16 + RM2M_PACK_GET);
      if(iTmp != iTemp_Warning_low)                           // If the received value does not correspond to that of the global variables ->
      {
        printf("iTemp_Warning_low changed to %d \r\n", iTmp); // Issues received value via the console
        iTemp_Warning_low = iTmp;                             // Copies received value into global variable
      }
      
      /* Copies temperature alerting threshold low(s16) at position 2-3 from the temporary memory for the
         read config 1 into the temporary memory for a parameter                                          */
      rM2M_Pack(aData, 6, iTmp,  RM2M_PACK_BE + RM2M_PACK_S16 + RM2M_PACK_GET);
      if(iTmp != iTemp_Alert_low)                             // If the received value does not correspond to that of the global variables ->
      {
        printf("iTemp_Alert_low changed to %d \r\n", iTmp);   // Issues received value via the console
        iTemp_Alert_low = iTmp;                               // Copies received value into the global variable
      }	  	 	 	  
    }	
  }
  /* If the changed configuration is the advanced config -> */
  else if(cfg == CFG_ADVANCED_INDEX)
  {
    new aData{CFG_ADVANCED_SIZE};                             // Temporary memory for the config 2 data read from the system
    new iSize;                                                // Temporary memory for the size of the config 1 data in bytes
    new iTmp;                                                 // Temporary memory for a config 2 data parameter

    /* Reads config 2 data from the system and copies it to the temporary memory. The
       number of the data block and return value of the read function (number of bytes or error code)
       are then issued via the console */	
    iSize = rM2M_CfgRead(cfg, 0, aData, CFG_ADVANCED_SIZE);
    printf("Cfg %d size = %d\r\n", cfg, iSize);  	

    /* If the number of read bytes is lower than the size of the config 2  ->
       Info: Error codes are negative */
    if(iSize < CFG_ADVANCED_SIZE)              
    {
      /* The following block initially copies the default values of config 2 to the temporary memory for the read
         config 2 and then sets the temporary memory for the size of the config 2 to the current
         size. This ensures that the following "IF" is executed during re-initialisation and when
         changes are received. If special actions have to be executed for individual parameters,
         it is thus not necessary to implement these separately for both cases.                          */
      iTmp = MAGIC_DELAY;
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_U8);
      iTmp = MAGIC_ON;
      rM2M_Pack(aData, 1, iTmp,   RM2M_PACK_BE + RM2M_PACK_U16);
      iTmp = MAGIC_OFF;
      rM2M_Pack(aData, 3, iTmp,   RM2M_PACK_BE + RM2M_PACK_U16);
      iTmp = VALUE_MAX;
      rM2M_Pack(aData, 4, iTmp,   RM2M_PACK_BE + RM2M_PACK_U16);	  
      iSize = CFG_ADVANCED_SIZE;
      print("created new Config #1\r\n");  
    }

	/* If the number of read bytes at least equates to the size of the config2 ->                         */
    if(iSize >= CFG_ADVANCED_SIZE)
    {
      /* Copies magic delay(u8) at position 0 from the temporary memory for the read
         config 2 into the temporary memory for a parameter                                               */	
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_U8 + RM2M_PACK_GET);
      if(iTmp != iMagic_Delay)                                // If the received value does not correspond to that of the global variables ->
      {
        printf("iMagic_Delay changed to %d \r\n", iTmp);      // Issues received value via the console
        iMagic_Delay = iTmp;                                  // Copies received value into global variable
      }
      
      /* Copies magic on (u16) at position 1-2 from the temporary memory for the
         read config 2 into the temporary memory for a parameter                                          */
      rM2M_Pack(aData, 1, iTmp,  RM2M_PACK_BE + RM2M_PACK_U16 + RM2M_PACK_GET);
      if(iTmp != iMagic_On)                                   // If the received value does not correspond to that of the global variables ->
      {
        printf("iMagic_On changed to %d \r\n", iTmp);         // Issues received value via the console
        iMagic_On = iTmp;                                     // Copies received value into the global variable
      }
	  
	  
      /* Copies magic off (u16) at position 3-4 from the temporary memory for the read
         config 2 into the temporary memory for a parameter                                               */	
      rM2M_Pack(aData, 3, iTmp,  RM2M_PACK_BE + RM2M_PACK_U16 + RM2M_PACK_GET);
      if(iTmp != iMagic_Off)                                  // If the received value does not correspond to that of the global variables ->
      {
        printf("iMagic_Off changed to %d \r\n", iTmp);        // Issues received value via the console
        iMagic_Off = iTmp;                                    // Copies received value into global variable
      }
      
      /* Copies g-force 90° (u16) at position 5-6 from the temporary memory for the
         read config 2 into the temporary memory for a parameter                                          */
      rM2M_Pack(aData, 5, iTmp,  RM2M_PACK_BE + RM2M_PACK_U16 + RM2M_PACK_GET);
      if(iTmp != igForce_max)                                 // If the received value does not correspond to that of the global variables ->
      {
        printf("igForce_max changed to %d \r\n", iTmp);       // Issues received value via the console
        igForce_max = iTmp;                                   // Copies received value into the global variable
      }	  	 	 	  
    }
  }  
}

/* Function to control the RGB LED 1 */
Handle_RGB_Led()
{
  static iCntMagic_Delay = 0;                                 // Delay [sec.] before activating the humidity detection again in "Magic" mode after RGB LED 1 has been switched on
  
  switch(iLED_Mode)                                           // Switches the operating mode of RGB LED 1
  {
    case LED_MODE_OFF:                                        // RGB LED 1 should be "Off"  
    {
      iLedState = LED1_OFF;                                   // Turns off the RGB LED 1 
    }
     
    case LED_MODE_TEMP:                                       // RGB LED 1 should be used to display the current alarm/warning state for the temperature measurement channel 
    {
      switch(iAlarmActive)                                    // Switches current alarm/warning state
      {
        case ALARM_HIGH:                                      // "High alarm" is active ->
        {
          iLedState = LED1_RED;                               // RGB LED 1 should light up red
        }
        case WARNING_HIGH:                                    // "High warning" is active
        {
          iLedState = LED1_YELLOW;                            // RGB LED 1 should light up yellow
        }
        case NO_ALARM:                                        // No alarm or warining is active
        {
          iLedState = LED1_GREEN;                             // RGB LED 1 should light up green
        }
        case WARNING_LOW:                                     // "Low alarm" is active
        {
          iLedState = LED1_CYAN;                              // RGB LED 1 should light up cyan (light blue)  
        }
        case ALARM_LOW:                                       // "Low warning" is active
        {
          iLedState = LED1_BLUE;                              // RGB LED 1 should light up blue
        }
        default:                                              // Undefined state
        {
          iLedState = LED1_OFF;                               // Turns off the RGB LED 1  
        }	  
      }
    }	
	
    case LED_MODE_MAGIC:                                      // RGB LED 1 should be used for the magic trick 
    {	
      // Issues current measurement values for the g-forces (x, y and z), humidity and temperature via the console 
      printf("Angle(X,Y,Z): %d %d %d; rh: %.1f;  temp: %.2f °C; \n", iX, iY, iZ, iHumidity / 10.0,iTemperature / 100.0);  
	
      /* If RGB LED 1 is "off" 
         - AND current measured humidity has met or exceeded the threshold to switch on RGB LED 1 
         - AND the delay before activating the humidity detection again has expired 
         -> LED should light up white                                                                           */
      if( (iLedState == LED1_OFF) && (iHumidity >= iMagic_On) && (iCntMagic_Delay == 0) ) iLedState = LED1_WHITE;

      // If the current measured g-force for one of the axes has exceeded the threshold to switch off RGB LED 1 
      if ((Abs(iX)>iMagic_Off)|| (Abs(iY)>iMagic_Off) || (Abs(iZ)>iMagic_Off))
      {
        // If the current measured humidity has met or exceeded the threshold to switch on RGB LED 1 ->
        if(iHumidity >= iMagic_On) iCntMagic_Delay = iMagic_Delay;// Resets the delay before activating the humidity detection again  
        iLedState = LED1_OFF;                                 // Turns off the LED
      }
    }
  }

  // If the delay before activating the humidity detection again has not expired -> Decrements the counter for the delay 
  if(iCntMagic_Delay > 0)iCntMagic_Delay--;
   
  rM2M_GpioSet(PIN_LED1_R, (iLedState & LED1_R)); // Red colour of the RGB LED1
  rM2M_GpioSet(PIN_LED1_G, (iLedState & LED1_G)); // Green colour of the RGB LED1
  rM2M_GpioSet(PIN_LED1_B, (iLedState & LED1_B)); // Blue colour of the RGB LED1 
}

/* Function to control the LED */
Handle_Led()
{
  new iTxState;                                // Temporary memory for the current connection status
  static iTxStateAkt;                          // Last determined connection status
  
  iTxState = rM2M_TxGetStatus();               // Reads current connection status from the system
  
  if(iTxState != iTxStateAkt)                  // If the connection status has changed ->  
  {
    // If the connection is not active, has not started and is not waiting for next automatic retry
    if((iTxState & (RM2M_TX_WAKEUPABLE|RM2M_TX_RETRY | RM2M_TX_STARTED| RM2M_TX_ACTIVE | RM2M_TX_FAILED)) == 0)                             
    {
      print("iTxState: ---\r\n");
      ChangeState(STATE_OFF);                  // LED 2 should be off 
    }
	else
	{
      print("iTxState: ");
      if(iTxState & RM2M_TX_FAILED)            // If the connection establishment failed -> 
      {
        print("FAILED | ");
		ChangeState(STATE_SLOW);               // LED 2 should blink slowly   
      }
      if(iTxState & RM2M_TX_ACTIVE)            // If the GPRS connection is established -> 
      {
        print("ACTIVE | ");
        ChangeState(STATE_ON);                 // LED 2 should be on
      }
      if(iTxState & RM2M_TX_STARTED)           // If the connection establishment has started ->
      {
        print("STARTED | ");
        ChangeState(STATE_FAST);               // LED 2 should flicker
      }
      if(iTxState & RM2M_TX_RETRY)             // If the system is waiting for the next automatic retry
      {
        print("RETRY | ");
        ChangeState(STATE_FAST);               // LED 2 should flicker
      }
	  // If the modem is logged into the GSM network AND (the connection is not active, has not started and is not waiting for next automatic retry) ->
      if((iTxState & RM2M_TX_WAKEUPABLE) && !(iTxState & (RM2M_TX_RETRY + RM2M_TX_STARTED + RM2M_TX_ACTIVE)))
      {
        print("WAKEUPABLE | ");
        ChangeState(STATE_OFF);                // LED 2 should be off 
      }
      print("\r\n");	  
	}

    iTxStateAkt = iTxState;                    // Copies current connection status to the variable for the last determined connection status
  }	
}

// Checks whether an alarm or warning has to be triggered or released
CheckAlarm()
{
  new iNewAlerts;                                   // Temporary memory for newly detected alarms or warnings

  if(iTemp_Alert_high != S16_STATUS_NAN)            // If the detection of "high alarms" is active ("alarm threshold high" has been specified) ->
  {
    // If the temperature has met or exceeded the "alarm threshold high" -> Sets "Warning" and "Alarm" Flags  
	if(iTemperature >= iTemp_Alert_high) iNewAlerts |= (AL_FLG_ALARM | AL_FLG_WARNING);
	// Otherwise -> If currently a "high alarm" is active and the temperature is higher than ("alarm threshold high" - hysteresis) -> Sets "Warning" and "Alarm" Flags 
	else if((iAlarmActive == ALARM_HIGH) && (iTemperature > ( iTemp_Alert_high - Abs(float(iTemp_Alert_high) * ALARM_HYST) ) ) ) iNewAlerts |= (AL_FLG_ALARM | AL_FLG_WARNING);
  }
  
  if(iTemp_Warning_high != S16_STATUS_NAN)          // If the detection of "high warnings" is active ("warning threshold high" has been specified) ->
  {
    // If the temperature has met or exceeded the "warning threshold high" -> Sets "Warning" Flag 
	if(iTemperature >= iTemp_Warning_high) iNewAlerts |= AL_FLG_WARNING;
	// Otherwise -> If (currently no "low alarm or warning" is active and currently a "high alarm or warning" is active ) and the temperature is higher than ("warning threshold high" - hysteresis) -> Sets "Warning" and "Alarm" Flags 
	else if( !(iAlarmActive & AL_FLG_UNDERFLOW ) && (iAlarmActive & (AL_FLG_ALARM | AL_FLG_WARNING)) && (iTemperature > (iTemp_Warning_high - Abs(float(iTemp_Warning_high) * ALARM_HYST) ) ) ) iNewAlerts |= AL_FLG_WARNING;
  }

  if(iTemp_Warning_low != S16_STATUS_NAN)           // If the detection of "low warnings" is active  ("warning threshold low" has been specified) ->
  {
    // If the temperature has dropped to or below the "warning threshold low" -> Sets "Underflow of value" and "Warning" Flag 
    if(iTemperature <= iTemp_Warning_low) iNewAlerts |= (AL_FLG_UNDERFLOW | AL_FLG_WARNING) ;
	// Otherwise -> If currently a "low alarm or warning" is active and the temperature is lower than ("warning threshold low" + hysteresis) -> Sets " Underflow of value" and "Warning" Flag 	
	else if( (iAlarmActive & (AL_FLG_UNDERFLOW | AL_FLG_ALARM | AL_FLG_WARNING)) && (iTemperature < (iTemp_Warning_low + Abs(float(iTemp_Warning_low) * ALARM_HYST) ) ) ) iNewAlerts |= (AL_FLG_UNDERFLOW | AL_FLG_WARNING)
  }
  
  if(iTemp_Alert_low != S16_STATUS_NAN)             // If the detection of "low alarms" is active  ("alarm threshold low" has been specified) ->
  {
    // If the temperature has dropped to or below the "alarm threshold low" -> Sets " Underflow of value", "Alarm" and "Warning" Flag 
	if(iTemperature <= iTemp_Alert_low) iNewAlerts |= (AL_FLG_UNDERFLOW | AL_FLG_ALARM | AL_FLG_WARNING) ;
    // Otherwise -> If currently a "low alarm" is active and the temperature is lower than ("alarm threshold low" + hysteresis) -> Sets "Underflow of value", "Alarm" and "Warning" Flag 
	else if( (iAlarmActive == ALARM_LOW) && (iTemperature < (iTemp_Alert_low + Abs(float(iTemp_Alert_low) * ALARM_HYST) ) ) ) iNewAlerts |= (AL_FLG_UNDERFLOW | AL_FLG_ALARM | AL_FLG_WARNING) ;
  }

  if(iNewAlerts != iAlarmActive)                    // If the current active alarms/warnings have changed -> 
  {
    switch(iNewAlerts)                              // Switches newly detected alarms or warnings
    {
      case ALARM_HIGH:                              // "High alarm" detected ->
      {
        if(iAlarmActive & AL_FLG_UNDERFLOW)         // If currently a "low alarm or warning" is active ("Underflow of value" flag is set) ->
        {
          Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, 0, 0, 0); // Clear alarm (necessary to clear active "Low warnings" and "Low alarms") 
          Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, WARNING_HIGH, iTemperature, iTemp_Warning_high);  // Set "High warning" 
          Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, ALARM_HIGH, iTemperature, iTemp_Alert_high);		// Set "High alarm"
        }
        else                                        // Otherwise -> Currently a "high alarm or warning" or no alarm/warning is active
        {
          // If currently no "high warning" is active -> Sets "High warning"  
          if(!(iAlarmActive & AL_FLG_WARNING)) Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, WARNING_HIGH, iTemperature, iTemp_Warning_high);
          // If currently no "high alarm" is active -> Sets "High alarm" 
          if(!(iAlarmActive & AL_FLG_ALARM))   Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, ALARM_HIGH, iTemperature, iTemp_Alert_high);

        }
      } 
	  
      case WARNING_HIGH:                            // "High warnung" detected ->
      {
        if(iAlarmActive & AL_FLG_UNDERFLOW)         // If currently a "low alarm or warning" is active ("Underflow of value" flag is set) ->  
        {
          Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, 0, 0, 0);   // Clear alarm (necessary to clear active "Low warnings" and "Low alarms") 
          Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, WARNING_HIGH, iTemperature, iTemp_Warning_high); // Set "High warning" 
        }
        else                                        // Otherwise -> Currently a "high alarm or warning" or no alarm/warning is active
        {
         // If currently a "high alarm" is active -> Clears alarm
         if(iAlarmActive & AL_FLG_ALARM) Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, WARNING_HIGH, 0, 0);		
         // If currently no "high warning" is active -> Sets "High warning" 
         if(!(iAlarmActive & AL_FLG_WARNING)) Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, WARNING_HIGH, iTemperature, iTemp_Warning_high);
		 
        }
      }
	  
      case NO_ALARM:                                // No alarm or warning detected ->
      {
        Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, 0, 0, 0); // Clears alarm 
      }	
      
      case WARNING_LOW:                             // "Low warning" detected ->
      {
        if(!(iAlarmActive & AL_FLG_UNDERFLOW))      // If currently a "high alarm or warning" or no alarm/warning is active  
        {
          Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, 0, 0, 0);  // Clears alarm (necessary to clear active "high warnings" and "high alarms") 
          Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, WARNING_LOW, iTemperature, iTemp_Warning_low);		  
        }
        else                                        // Otherwise -> Currently a "low alarm or warning" is active 
        {        
          // If currently a "low alarm" is active -> Clears alarm
          if(iAlarmActive & AL_FLG_ALARM) Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, WARNING_LOW, 0, 0);
          // If currently no "low warning" is active -> Sets "Low warning"
          if(!(iAlarmActive & AL_FLG_WARNING)) Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, WARNING_LOW, iTemperature, iTemp_Warning_low);
        }
      }
      case ALARM_LOW:                               // "Low alarm" detected ->
      {
        if(!(iAlarmActive & AL_FLG_UNDERFLOW))      // If currently a "high alarm or warning" or no alarm/warning is active    
        {
          Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, 0, 0, 0); // Clears alarm (necessary to clear active "high warnings" and "high alarms") 
          Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, WARNING_LOW, iTemperature, iTemp_Warning_low); // Sets "Low warning" 
          Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, ALARM_LOW, iTemperature, iTemp_Alert_low);     // Sets "Low alarm" 
        }
        else                                        // Otherwise -> Currently a "low alarm or warning" is active 
        {
           // If currently no "low warning" is active -> Sets "Low warning"  
           if(!(iAlarmActive & AL_FLG_WARNING)) Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, WARNING_LOW, iTemperature, iTemp_Warning_low);	  
           // If currently no "low alarm" is active -> Sets "Low alarm" 
           if(!(iAlarmActive & AL_FLG_ALARM))   Al_SetAlarm(HISTDATA_INDEX, CH_TEMPERATURE, ALARM_LOW, iTemperature, iTemp_Alert_low);
        }
      }     
    }
	
    /* Sets count variable for seconds until the next transmission to 0. This ensures that a transmission
       is triggered the next time the "Handle_Transmission" function is called up by the "Timer1s"
       function.                                                                                      */
    iTxTimer = 0;   	  
	
  }

  iAlarmActive = iNewAlerts;                        // Copies newly detected alarms or warnings to the variable for the current active alarms
}


 /**
 * Calculates the angle of the axis in relation to the surface of the earth
 *
 * @param iValue:s32    - g-force [mg] measured for an axis  
 * @param iMaxValue:s32 - g-force equivalent to an angle of 90° [mg]
 * @return s32          - angle of the axis in relation to the surface of the earth
 */                        
stock CalcAngle(iValue, iMaxValue)
{
  new Float:fValue;
  new iResult;
  
  if(iValue > iMaxValue)                            // If the measured g-force for the axis is higher than the g-force equivalent to an angle of 90° 
    return 90;                                      // Return 90°  														
  
  if(iValue < -iMaxValue)                           // If the measured g-force for the axis is lower than the g-force equivalent to an angle of -90° 
    return -90;                                     // Return -90°
  
  // Calculates the angle of the axis in relation to the surface of the earth and return it
  fValue = 90-(acos(float(iValue) / float(iMaxValue)) * 180.0 / M_PI);
  iResult = fValue;
  return iResult;
}

/**
 * Calculates the absolute value 
 *
 * @param iValue:s32 - Value for which the absolute value should be determined
 * @return s32       - Absolute value of the transferred value 
 * 
 */
Abs(iValue)
{
 return ((iValue)<0 ? (-iValue) : (iValue))
}

/**
 * Changes the state that should be displayed via LED 2
 *
 * @param iNewState:s32 - New state that should be displayed via LED 2
 */
ChangeState(iNewState)
{
  if(iNewState != iLed3_State)                      // If the status to be set differs from the current status ->
  {
    // Update on Next Tick
    iLed3_Timer = 0;                                // Sets the counter used to generate the blink interval to 0 so that LED2 can be controlled
                                                    // on the next expiry of the 100ms
    iLed3_State = iNewState;                        // Copies new status to the variable for the current state that should be displayed via LED 2 
  }
}

