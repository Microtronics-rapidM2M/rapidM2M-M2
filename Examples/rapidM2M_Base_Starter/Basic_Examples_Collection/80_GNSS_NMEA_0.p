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
 * Receives "GNSS" data of format "NMEA" via UART interface. This example gives advice
 * on how to use the "gnss.inc" file. Received data is printed to the console.
 * 
 * Only compatible with rapidM2M M2xx
 * Special hardware necessary (GNSS module, e.g. ublox NEO-M8 Series) 
 *
 * @version 20190905  
 */

 /* Path for hardware-specific include file */
#include ".\rapidM2M M2\mx.inc"

 /* For GNSS NMEA decoding, checksum etc. */
#include "gnss.inc"

/* String functions */
#include <string.inc>

#define GNSS_DEBUG_SAVEFRAME (0)           // Do not change! Feature is not working correctly

const
{
  PORT_UART = 0,                            // The first UART interface should be used
  TXMODE    = RM2M_TXMODE_TRIG              // Connection type, default "Interval"
}

/* Forward declarations of public functions */
forward public MainTimer();                 // Called up 1x per sec. for the program sequence
forward public PrintGNSSdata();             // Issues all available GNSS data via the console
forward public UartRx(const data{}, len);   // Called up when characters are received via the UART interface

#if GNSS_DEBUG_SAVEFRAME != 0
static iStateSave = GNSS_SAVE_STOP;
#endif

static gaGNSS_GGA[TYPE_GNSS_GGA];           // Last received GGA sentence (Global positioning system fix data)
static gaGNSS_VTG[TYPE_GNSS_VTG];           // Last received VTG sentence (Vector track and speed over the ground)
static gaGNSS_RMC[TYPE_GNSS_RMC];           // Last received RMC sentence (Recommended minimum sentence C)
static gaGNSS_GSV[TYPE_GNSS_GSV];           // Detailed data for one of the satellites in view

static sNMEAFrame{GNSS_MAX_FRAME_LENGTH+1}; // Array to store a received NMEA data frame 
static iFrameIndex = 0;                     // Number of characters of the received NMEA data frame

static gaPrintfBuffer{4096};                // Array used as extended buffer for the "printf" function to output strings

/* Application entry point */
main()
{
  /* Temporary memory for the index of a public function and the return value of a function  */
  new iIdx, iResult;
 
  // Switches the buffer for the "printf" function from the buffer (256 Bytes) integrated in the firmware to the transferred buffer.
  setbuf(gaPrintfBuffer, 4096);              
 
   /* Initialisation of a cyclic 1 sec. timer
     - Determining the function index that should be executed 1x per sec.
     - Transferring the index to the system
     - Issuing the index and return value of the init function via the console  */
  iIdx = funcidx("MainTimer");
  iResult = rM2M_TimerAdd(iIdx);
  printf("rM2M_TimerAddExt(%d) = %d\r\n", iIdx, iResult);

  GNSS_Init(PORT_UART);                     // Initialises the UART interface for communication with a GNSS module
}

/* 1 sec. timer is used for the general program sequence */
public MainTimer()
{
  PrintGNSSdata();                          // Issues all available GNSS data via the console
}

/**
 * Prints GNSS data
 *
 * If the "Available" flag inside a GNSS structure is set, all data elements are printed to
 * the console. The SV states are always printed.
 *
 */
public PrintGNSSdata()
{
  if(gaGNSS_GGA.Available == 1)             // If a new GGA sentence (Global positioning system fix data) is available -> 
  {
    // Issues the last received GGA sentence via the console
    printf("\r\n--\r\n UTC: %d\r\n Lat: %d \r\n Lon: %d \r\n PosFixInd: %d \r\n SatUsed: %d \r\n H. Precision: %d",
            gaGNSS_GGA.UTC,
            gaGNSS_GGA.Latitude,
            gaGNSS_GGA.Longitude,
            gaGNSS_GGA.PosFixInd,
            gaGNSS_GGA.SatUsed,
            gaGNSS_GGA.HPrecision
          );
    printf("\r\n Altitude: %d \r\n GeoSep: %d \r\n DGNSS Age: %d \r\n DGNSS ID: %d \r\n--\r\n",
            gaGNSS_GGA.Altitude,
            gaGNSS_GGA.GeoSep,
            gaGNSS_GGA.DGNSSage,
            gaGNSS_GGA.DGNSSID
          );
	
    gaGNSS_GGA.Available = 0;               // Clears the flag indicating that a new GGA sentence is available.
                                            // Note: This flag is set by the GNSS_NMEADecodeGGA function when decoding the NMEA data frame. 	
  }
  
  
  if(gaGNSS_RMC.Available == 1)             // If a new RMC sentence (Recommended minimum sentence C) is available -> 
  {
    // Issues the last received RMC sentence via the console
    printf("\r\n--\r\n UTC: %d\r\n Status: %s\r\n Lat: %d \r\n Lon: %d \r\n Speed: %d \r\n Track: %d \r\n UTC date: %d",
            gaGNSS_RMC.UTC,
            gaGNSS_RMC.Status{0},
            gaGNSS_RMC.Latitude,
            gaGNSS_RMC.Longitude,
            gaGNSS_RMC.SpeedOverGround,
            gaGNSS_RMC.CourseOverGround,
            gaGNSS_RMC.UTCdate
          );
    printf("\r\n Magnetic Variation: %d \r\n Mode: %s \r\n--\r\n",
            gaGNSS_RMC.MagVar,
            gaGNSS_RMC.Mode{0}
          );
    gaGNSS_RMC.Available = 0;               // Clears the flag indicating that a new RMC sentence is available.
                                            // Note: This flag is set by the GNSS_NMEADecodeRMC function when decoding the NMEA data frame.
	
  }
  
  
  if(gaGNSS_VTG.Available == 1)             // If a new VTG sentence (Vector track and speed over the ground) is available -> 
  {
    // Issues the last received VTG sentence via the console  
    printf("\r\n--\r\n Course True: %d\r\n Course Mag.: %d\r\n Speed kn: %d \r\n Speed kph: %d \r\n Mode: %s \r\n--\r\n",
            gaGNSS_VTG.CourseOverGroundTrue,
            gaGNSS_VTG.CourseOverGroundMagnetic,
            gaGNSS_VTG.SpeedOverGround_kn,
            gaGNSS_VTG.SpeedOverGround_kph,
            gaGNSS_VTG.Mode{0}
          );
    gaGNSS_VTG.Available = 0;               // Clears the flag indicating that a new VTG sentence is available.
                                            // Note: This flag is set by the GNSS_NMEADecodeVTG function when decoding the NMEA data frame.

  }
	
	
  for(new i=0; i < GNSS_SAT_COUNT; i++)    // For the maximum count of satellites which can be stored in the GSV sentences ->
  {
    GNSS_GetInfoGSV(i, gaGNSS_GSV);        // Reads the detailed data for one of the satellites in view from the private memory area of the gnss.inc
                                           // Note: The data for the satellites in view is updated by the GNSS_NMEADecodeGSV function when decoding the NMEA data frame.
										   
    //Issues detailed data of a satellite in view via the console
    printf("\r\n--\r\n PRN: %d\r\n Elevation: %d\r\n Azimuth: %d \r\n SNR: %d \r\n--\r\n",
             gaGNSS_GSV.SvPrnNumber,
             gaGNSS_GSV.Elevation,
             gaGNSS_GSV.Azimuth,
             gaGNSS_GSV.Snr
           );
  }

#if GNSS_DEBUG_SAVEFRAME != 0
  GNSS_SaveNextFrame();
#endif
}

/**
 * Callback function that is called up when characters are received via the UART interface
 *
 * Receives data via the UART interface and scans for the character '$'. If this prefix is received,
 * all data is buffered until the NMEA frame is terminated with '\r' and '\n'. Then, the checksum is
 * verified. After that, the function determines which sentence-identifier came with the data
 * stream and starts decoding if the specific identifier is supported in the header file. Additionally,
 * the data can be stored in the flash for uplink purpose.
 *
 * @param data[]:u8 - Array that contains the received data 
 * @param len:s32   - Number of received bytes
 */
public UartRx(const data{}, len)
{
  new iIndex       = 0;                    // Temporary memory for the index (within the received data) of the character currently being processed
  new iCurrentChar = 0;                    // Temporary memory for a character 

  while(iIndex < len)                      // For all characters just received ->
                                           // I.e. while the index of the character currently being processed < number of received bytes 
  {
    iCurrentChar = data{iIndex++};         // Copies the character from the currently examined position of the array to temporary memory 
                                           // and increases the index of the character currently being processed

    // If the start character was received -> Restarts the reception of the NMEA data frames
    if(iCurrentChar == '$') iFrameIndex = 0; 
    // Otherwise -> If the stop character (carriage return or line feed) was received or 80 characters have been received (max. length of a NMEA frame) -> 
    else if(iCurrentChar == '\r' || iCurrentChar == '\n' || iFrameIndex == 79)
    {
      sNMEAFrame{iFrameIndex} = '\0';      // Writes a "0" to the current postion in the array for storing a NMEA data frame in order to terminate the string 
	  
      if(GNSS_NMEAIsChecksumValid(sNMEAFrame) >= 0) // If the calculated and received checksum are equal ->
      {
        new sSID{3};                                // Temporary memory for the sentence ID of a NMEA data frame
        GNSS_GetSentenceID(sNMEAFrame, sSID);       // Reads out the sentence ID from the array to store the received NMEA data frame 
		
        GNSS_PrintNMEAframe(sNMEAFrame);            // Issues the received NMEA data frame via the console
		
        // Frame with Sentence-ID "GGA" (Global positioning system fix data) received -> Calls up function to decode GGA frames 
        if(strcmp(sSID, "GGA") == 0)
        {
          GNSS_NMEADecodeGGA(sNMEAFrame, gaGNSS_GGA);
        }

        // Frame with Sentence-ID "RMC" (Recommended minimum sentence C) received -> Calls up function to decode RMC frames 
        else if(strcmp(sSID, "RMC") == 0)
        {
          GNSS_NMEADecodeRMC(sNMEAFrame, gaGNSS_RMC);
        }

        // Frame with Sentence-ID "VTG" (Vector track and speed over the ground) received -> Calls up function to decode VTG frames 		
        else if(strcmp(sSID, "VTG") == 0)
        {
          GNSS_NMEADecodeVTG(sNMEAFrame, gaGNSS_VTG);
        }

        // Frame with Sentence-ID "GSV" (Detailed satellite data) received -> Calls up function to decode GSV frames 		
        else if(strcmp(sSID, "GSV") == 0)
        {
          GNSS_NMEADecodeGSV(sNMEAFrame);        
        }
        
#if GNSS_DEBUG_SAVEFRAME != 0
        if(iStateSave == GNSS_SAVE_RUN)        // Stops saving frames
          iStateSave = GNSS_SAVE_STOP;
        else if(iStateSave == GNSS_SAVE_START) // Starts saving GNSS frames
          iStateSave = GNSS_SAVE_RUN;
			
        // Saves GNSS Frame
        if(iStateSave == GNSS_SAVE_RUN)
          GNSS_SaveFrame(sNMEAFrame);
#endif
      }

      iFrameIndex = 0;                     // Restarts the reception of the NMEA data frames
    }
	
    if(iFrameIndex < GNSS_MAX_FRAME_LENGTH)    // If the maximum length of a data frame is not exceeded -> 
      sNMEAFrame{iFrameIndex++} = iCurrentChar;// Copies the current character into the array for storing a NMEA data frame
  }
}
