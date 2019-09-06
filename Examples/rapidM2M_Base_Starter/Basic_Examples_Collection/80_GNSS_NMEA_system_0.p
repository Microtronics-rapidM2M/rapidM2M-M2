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
 * Simple "GNSS NMEA" Example
 *
 * Example on how to decode GNSS NMEA frames with sentence identifier "GGA" by using
 * rM2M system integrated functions. Each time a NMEA data frame is received from the GNSS module (approximately every second) 
 * the frame is decoded and issued via the console. Periodically (record interval) the last valid values for longitude 
 * and latitude are stored in the flash of the system. The measurement data generated this way is then 
 * transmitted periodically (transmission interval) to the server.    
 * 
 * Note: To use the recorded data within the interface of the server (e.g. reports, visualisations, graphics, etc.)
 *       it is necessary to define a Data Descriptor (see 80_GNSS_NMEA_system_0.txt).
 *
 
 * Only compatible with rapidM2M M2xx
 * Special hardware necessary (GNSS module, e.g. ublox NEO-M8 Series) 
 *
 * @version 20190905  
 */

 /* Path for hardware-specific include file */
#include ".\rapidM2M M2\mx.inc"

/* String functions */
#include <string.inc>

/* Forward declarations of public functions */
forward public MainTimer();                 // Called up 1x per sec. for the program sequence
forward public UartRx(const data{}, len);   // Called up when characters are received via the UART interface
forward public Handle_NMEA_Frame(aData{});  // Called up when any GNSS frame was received

const
{
  PORT_UART = 0,                            // The first UART interface
  MAX_LENGTH = 80,                          // Maximum length of a NMEA data frame
}

const
{  
  INTERVAL_RECORD = 10,                     // Interval of record [s]
  INTERVAL_TX     = 10 * 60,                // Interval of transmission [s]
  
  TXMODE              = RM2M_TXMODE_TRIG,   // Connection type
  HISTDATA_SIZE       = 2 * 4 + 1,          // 2 channel (s32) + "Split-tag" (u8)
}

/* State of the reception task for NMEA data frames */
const
{
  STATE_WAIT_STX = 0,                       // Wait for the start character 
  STATE_WAIT_ETX,                           // Wait for the stop character
  STATE_FINISHED,                           // Complete data frame was received
}

static sGNSSdata[TNMEA_GGA];                // Structure that contains received GNSS (GGA) data
static iGNSSupdate = false;                 // Variable that indicates available GNSS data

/* Global variables for the remaining time until certain actions are triggered */
static iRecTimer;                           // Sec. until the next recording
static iTxTimer;                            // Sec. until the next transmission 

/* Application entry point */
main()
{
  /* Temporary memory for the index of a public function and the return value of a function  */
  new iIdx, iResult;
  
  /* Initialisation of a cyclic 1 sec. timer
     - Determining the function index that should be executed 1x per sec.
     - Transferring the index to the system
     - Issuing the index and return value of the init function via the console  */    
  iIdx = funcidx("MainTimer");
  iResult = rM2M_TimerAdd(iIdx);
  printf("rM2M_TimerAddExt(%d) = %d\r\n", iIdx, iResult);

  /* Initialisation of the UART interface that should be used 
   - Determining the function index that should be called up when characters are received
   - Transferring the index to the system and configuring the interface                      
     (9600 baud, 8 data bits, no parity, 1 stop bit)                                     */	   
  iIdx = funcidx("UartRx");
  iResult = rM2M_UartInit(PORT_UART, 9600, RM2M_UART_8_DATABIT|RM2M_UART_PARITY_NONE|RM2M_UART_1_STOPBIT, iIdx);
  
  iRecTimer = INTERVAL_RECORD;              // Sets counter variable to defined record interval
  iTxTimer  = INTERVAL_TX;                  // Sets counter variable to defined transmission interval

  rM2M_TxSetMode(TXMODE);                   // Sets the connection type to "Interval" mode
  rM2M_TxStart();                           // Initiates a connection to the server  
}

/* 1 sec. timer is used for the general program sequence */
public MainTimer()
{
  iRecTimer--;                              // Counter counting down the sec. to the next recording
  if(iRecTimer <= 0)                        // When the counter has expired ->  
  {
    if(iGNSSupdate)                         // If GNSS data is available ->
    {
      print("Create Record\r\n");    
      Handle_Record();                      // Calls up the function to record the data
      iGNSSupdate = false;                  // Resets GNSS data Available flag      	  
    }
    
    iRecTimer = INTERVAL_RECORD;            // Resets counter variable to defined record interval  
  }
  
  iTxTimer--;                               // Counter counting down the sec. to the next transmission
  if(iTxTimer <= 0)                         // When the counter has expired -> 
  {
    print("Start Transmission\r\n");
    rM2M_TxStart();                         // Initiates a connection to the server 
    iTxTimer = INTERVAL_TX;                 // Resets counter var. to defined transmission interval [sec.]  
  }
  
  // Issues the seconds until the next recording and the next transmission to the console
  printf("iRecTimer=%d iTxTimer=%d\r\n", iRecTimer, iTxTimer);  
}

/* Function for recording the data */
Handle_Record()                                     
{
    /* Temporary memory in which the data record to be saved is compiled */
    new aRecData{HISTDATA_SIZE};

    /* Compiles the data record to be saved in the "aRecData" temporary memory
     - The first byte (position 0 in the "aRecData" array) is set to 0 so that the server copies
       the data record into measurement data channel 0 upon receipt, as specified during the design
         of the connector
     - Longitude is copied to position 1-4. Data type: u32
     - Latitude is copied to position 5-8. Data type: u32                                        */  	
    aRecData{0} = 0;     // "Split-tag"
    rM2M_Pack(aRecData, 1, sGNSSdata.Long, RM2M_PACK_BE + RM2M_PACK_S32);
    rM2M_Pack(aRecData, 5, sGNSSdata.Lat,  RM2M_PACK_BE + RM2M_PACK_S32);

    /* Transfers the data record to the system */
    rM2M_RecData(0, aRecData, HISTDATA_SIZE);
}

/**
 * Callback function that is called up when characters are received via the UART interface
 *
 * Receives data via the UART interface and scans it for GNSS data frames that start with the character "$" and 
 * end either with a carriage return or line feed. If a complete data frame was received, the function to process 
 * the received data frame is called up.
 *
 * @param data[]:u8 - Array that contains the received data 
 * @param len:s32   - Number of received bytes 
 */
public UartRx(const data{}, len)
{
  static iState = STATE_WAIT_STX;          // State of the reception task for the data frames   
  static aFrame{MAX_LENGTH};               // Array to store a received data frame 
  static iFrameLength = 0;                 // Number of characters of the received data frame
  
  new iChar;                                // Temporary memory for a character   
  
  for(new iIdx=0; iIdx < len; iIdx++)       // For all characters just received -> 
  {
    iChar = data{iIdx};                     // Copies the character from the current examined position of the array to temporary memory  
    
    switch(iState)                          // Switch state of the reception of the data frames ->
    {
      case STATE_WAIT_STX:					// Wait for the start character
      {
        if(iChar=='$')                      // If the start character was received ->
        {
          aFrame{iFrameLength++} = '$';     // Copies the start character into the array for storing a data frame and 
                                            // increases the number of received characters 
          iState = STATE_WAIT_ETX;          // Sets state to "Wait for the stop character"  
        }
      }
      case STATE_WAIT_ETX:                  // Wait for the stop character
      {
        if(iChar == '\r' || iChar == '\n')  // If the stop character (carriage return or line feed) ->
        {
          aFrame{iFrameLength} = '\0';      // Writes a "0" to the current postion in the array for storing a data frame in order to terminate the string  
          iState = STATE_FINISHED;          // Sets state to "Complete data frame was received"
        }
        else                                // Otherwise (a character that is part of the data frame was received) ->   
        {
          if(iFrameLength < MAX_LENGTH)     // If the maximum length of a data frame is not exceeded ->
          {
            aFrame{iFrameLength++} = iChar; // Copies the current character into the array for storing a data frame and 
                                            // increases the number of received characters   
          }
          else                              // Otherwise (maximum length of the data frame exceeded) -> 
          { 
            //Restarts the reception of the data frames
            iFrameLength = 0;               // Sets number of characters to 0
            iState = STATE_WAIT_STX;        // Sets state to "Wait for the start character" 
          }
        }
      }
    }
  }
  
  if(iState == STATE_FINISHED)              // If a complete data frame was received ->
  {
    Handle_NMEA_Frame(aFrame);	            // Calls up the function to process the received data frame 
	
    // Restarts the reception of the data frames
    iFrameLength = 0;                       // Sets number of characters to 0
    iState = STATE_WAIT_STX;                // Sets state to "Wait for the start character"
  }
}

/**
 * Function to process the NMEA frame
 *
 * Checks if received GNSS frame's sentence identifier is "GGA". If so, the data is decoded
 * and buffered.
 *
 * @param aData[]:u8  - Array that contains the received data frame
 */
public Handle_NMEA_Frame(aData{})
{
  if  ((strcmp(aData, "$GPGGA", 6) == 0)  // Searches for frame with sentence ID "GGA"
	|| (strcmp(aData, "$GLGGA", 6) == 0)
	|| (strcmp(aData, "$GAGGA", 6) == 0)
	|| (strcmp(aData, "$GNGGA", 6) == 0))
  {
	new aGNSSdata[8];                      // Array that buffers GNSS data

    rM2M_DecodeNMEA(aData, aGNSSdata);     // Decodes NMEA data frame
	
	new iTalkerID     = aGNSSdata[0];      // A structure of type TNMEA_GGA does only support storage for GGA data fields but not the TalkerID or SentenceID,
	new iSentenceID   = aGNSSdata[1];      // so in this case the data fields are stored in the designated structure and the IDs in separate variables.
	sGNSSdata.Lat     = aGNSSdata[2];
	sGNSSdata.Long    = aGNSSdata[3];
	sGNSSdata.Alt     = aGNSSdata[4];
	sGNSSdata.Qual    = aGNSSdata[5];
	sGNSSdata.SatUsed = aGNSSdata[6];
	sGNSSdata.HDOP    = aGNSSdata[7];
    
	// Results are printed to console
	printf("GGA Frame erkannt: Talker-ID=%x, Sentence-ID=%x, Lat=%d, Long=%d, Alt=%d, Qual=%d, SatUsed=%d, HDOP=%d\n\r",
	iTalkerID,           // HEX format -> See the manual for further information
	iSentenceID,         // HEX format -> See the manual for further information
	sGNSSdata.Lat,
	sGNSSdata.Long,
	sGNSSdata.Alt,
	sGNSSdata.Qual,
	sGNSSdata.SatUsed,
	sGNSSdata.HDOP
	);
	
	iGNSSupdate = true;                    // Indicates complete reception of GNSS data frame
  }
}
