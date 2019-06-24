## Explanation
The examples included in the basic example collection are designed to demonstrate how to use the rapidM2M Device API. In addition to the basic handling you also find best practice examples. With the number at the begin of the name also the complexity of the example increases. 

## Example overview
* **[00_common_0_Main.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/00_common_0_Main.p)** <br/>
*Simple rapidM2M "Hello World"* <br/>
Prints "Hello World" to the development console once after starting the script.
* **[00_common_1_Timer_1.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/00_common_1_Timer_1.p)** <br/>
*Extended rapidM2M "Hello World" Example* <br/>
Prints "Hello World" every second to the development console
* **[00_common_2_get_module_info.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/00_common_2_get_module_info.p)** <br/>
Prints the information for identifying the rapidM2M hardware and the implemented API level to the development console.
* **[10_Switch.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/10_Switch.p)** <br/>
*Simple "Button" Example* <br/>
Evaluates the state of a button connected to the "INT0" pin. <br/>
* **[10_Switch_Long.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/10_Switch_Long.p)** <br/>
*Extended "Button" Example* <br/>
Evaluates the state of a button connected to the "INT0" pin and also detects if the button was pressed only briefly or for a longer time <br/>
* **[11_Led_2.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/11_Led_2.p)** <br/>
*Simple "LED" Example* <br/>
Toggles LED2 every second and turns off all other LEDs <br/>
* **[11_Led_2_3.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/11_Led_2_3.p)** <br/>
*Extended "LED" Example* <br/>
Toggles LED2 and LED3 every second and turns off all other LEDs. If LED2 is on, then LED3 is off and vice versa. <br/>
* **[11_Led_rgb_v1.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/11_Led_rgb_v1.p)** <br/>
*"RGB LED" Example V1* <br/>
Changes the color of the RGB LED 1 each second. To do this, a counter is repeatedly increased from 0 to 7. Each bit of the counter is assigned a color of the RGB LED1. <br/>
 * **[11_Led_rgb_v2.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/11_Led_rgb_v2.p)** <br/>
*"RGB LED" Example V2* <br/>
Changes the color of the RGB LED 1 each second. To do this, a counter is repeatedly increased from 0 to 7. Each bit of the counter is assigned a color of the RGB LED1. <br/>
* **[12_Transmission_0.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/12_Transmission_0.p)** <br/>
*Simple "Transmission" Example*<br/>
Initiates a connection to the server. The synchronisation of the configuration, registration and measurement data is automatically done by the firmware. <br/>
* **[12_Transmission_1_uplink.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/12_Transmission_1_uplink.p)** <br/>
*Simple "WiFi Transmission" Example*<br/>
Selects the WiFi module as the communication interface and initiates a connection to the server. The synchronisation of the configuration, registration and measurement data is automatically done by the firmware. <br/>
* **[12_Transmission_2_cyclic_connection.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/12_Transmission_2_cyclic_connection.p)** <br/>
*Extended "Transmission" Example*<br/>
Initiates a connection to the server every 2 hours. The synchronisation of the configuration, registration and measurement data is automatically done by the firmware. <br/>
* **[12_Transmission_3_ForceOnline.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/12_Transmission_3_ForceOnline.p)** <br/>
*Extended "Online Mode Transmission" Example*<br/>
Establishes and tries to maintain an online connection to the server. As long as the device is in online mode, a synchronisation of the configuration, registration and measurement data is initiated every 2 hours.<br/>
 * **[13_Transmission_Led.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/13_Transmission_Led.p)** <br/>
*"Indicating the Transmission state" Example*<br/>
Initiates a connection to the server and uses LED 2 to indicate the current connection state. <br/>
* **[20_rs232_1.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/20_rs232_1.p)** <br/>
*Simple "UART" Example* <br/>
Issues the text "Data" every secound via the UART interface and receives data via the UART interface. <br/>
* **[20_rs232_2.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/20_rs232_2.p)** <br/>
*Extended "UART" Example* <br/>
Receives data via the UART interface and scans it for data frames that start with the character "+" and end either with a carriage return or line feed. If a complete data frame was received, a string is created that is composed as follows: "UartRx (<data frame received via UART>) <number of characters of data frame> OK". This string is then issued via the console and the UART interface. <br/>
* **[20_rs232_3.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/20_rs232_3.p)** <br/>
*Extended "UART" Example* <br/>
Receives data via the UART interface and scans it for data frames that start with the character "+" and end either with a carriage return or line feed. The received data is issued again immediately after receiving it via the UART interface. If a complete data frame was received, a string is created that is composed as follows: "UartRx (<data frame received via UART>) <number of characters of data frame> OK". This string is then issued via the console and the UART interface. <br/>
* **[20_rs232_4.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/20_rs232_4.p)** <br/>
*Extended "UART" Example* <br/>
Receives data via the UART interface and scans it for data frames that start with the character "+" and end either with a carriage return or line feed. The received data is issued again immediately after receiving it via the UART interface. If a complete data frame was received, a string is created that is composed as follows: "UartRx (<data frame received via UART>) <number of characters of data frame> OK". This string is then issued via the console and the UART interface. <br/>
* **[30_ui_0.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/30_ui_0.p)** <br/>
*Simple "System Values" Example* <br/>
Reads the last valid values for Vin and Vaux from the system and issues them every second via the console <br/>
* **[30_ui_1.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/30_ui_1.p)** <br/>
*Extended "System Values" Example* <br/>
Reads the last valid values for Vin and Vaux periodically (record interval) from the system and stores the generated data record in the flash of the system. The measurement data generated this way is then transmitted periodically (transmission interval) to the server. <br/>
* **[30_ui_2.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/30_ui_2.p)** <br/>
*Extended "System Values" Example* <br/>
Reads the last valid values for Vin and Vaux periodically (record interval) from the system and stores the generated data record in the flash of the system. The measurement data generated this way is then transmitted periodically (transmission interval) to the server. The interval for recording and transmitting measurement data can be configured via the server. <br/>
* **[40_i2c.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/40_i2c.p)** <br/>
*Simple "I2C, Temperature and humidity (SHT31)" example* <br/>
Uses the I2C interface to communicate with a SHT31 temperature and humidity sensor. <br/>
* **[50_spi.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/50_spi.p)** <br/>
*Simple "SPI, g-forces (LIS3DSH)" example* <br/>
Uses the SPI interface to communicate with a LIS3DSH accelerometer. The LIS3DSH is first configured to periodically perform a measurement with an output data rate (ODR) of 6.25 Hz.A 1sec. timer is then used to read out the measurement values and issue the g-forces [mg] for all 3 axes (X, Y, Z) via the console.<br/>
* **[50_spi_winkel.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/50_spi_winkel.p)** <br/>
*Extended "SPI, g-forces (LIS3DSH)" example* <br/>
Uses the SPI interface to communicate with a LIS3DSH accelerometer. The LIS3DSH is first configured to periodically perform a measurement with an output data rate (ODR) of 6.25 Hz. A 100ms timer is then used to read out the measurement values and add up these sample measurements of the g-forces [mg]. Another 1 sec. timer is used to average the sample measurements and calculate the angle of the axes in relation to the surface of the earth. The calculated angle of the 3 axes are then issued via the console.<br/>
* **[60_statemachine_1.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/60_statemachine_1.p)** <br/>
*Simple "State machine" example* <br/>
The state machine has six different states that are indicated by the RGB LED1. <br/>
* **[60_statemachine_2.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/60_statemachine_2.p)** <br/>
*Extended "State machine" example* <br/>
The state machine has seven different states that are indicated by the RGB LED1. <br/>
* **[61_alarm_1.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/61_alarm_1.p)** <br/>
*Simple "Alarm" Example* <br/>
Simulates and records (record interval) a temperature value that changes between 19°C and 31°C in 1°C steps. The measurement data generated this way is then transmitted periodically (transmission interval) to the server. If the temperature exceeds 25°C, an alarm is triggered. Once an alarm has been triggered and the temperature falls below 25°C again, the alarm is released. In both cases (when triggering or releasing the alarm) an alarm record is generated and transmitted to the server immediately.<br/>
* **[61_alarm_2.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/61_alarm_2.p)** <br/>
*Extended "Alarm" Example* <br/>
Simulates and records (record interval) a temperature value that changes between 19°C and 31°C in 1°C steps. The measurement data generated this way is then transmitted periodically (transmission interval) to the server. If the temperature is greater than or equal to 25°C, an alarm is triggered. Once an alarm has been triggered and the temperature falls to or below 25°C - 5% (i.e. 23,75°C) again, the alarm is released. In both cases (when triggering  or releasing the alarm) an alarm record is generated and transmitted to the server immediately. </br>
 * **[70_wifi_scan.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/70_wifi_scan.p)** <br/>
*Simple "WiFi" Example* <br/>
Scans every 5 seconds for WiFi network in the receiving range and issues security type, WiFi RF channel and Service Set Identifier of the found WiFi networks via the console <br/>
* **[70_wifi_scan_devinfo.p](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/70_wifi_scan_devinfo.p)** <br/>
*Extended "WiFi" Example* <br/>
Scans for WiFi network in the receiving range every 5 seconds and issues security type, WiFi RF channel and Service Set Identifier of the found WiFi networks via the console. After the initialisation of the WiFi interface the name/designation, hardware version, firmware version and MAC adress of the built-in WiFi module are also issued once via the console.
* **[lis3dsh.inc](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/lis3dsh.inc)** <br/>
*LIS3DSH interface functions* <br/>
* **[sht31.inc](https://github.com/Microtronics-rapidM2M/rapidM2M-M2/blob/master/Examples/rapidM2M_Base_Starter/Basic_Examples_Collection/sht31.inc)** <br/>
*SHT31 interface functions* <br/>

## rapidM2M Device API functions used in the examples 

Click on the name of the function to view in which example it is used.

### [Timer, date & time](http://support.microtronics.com/Developer_Documentation/Content/Developer_Documentation/sw/Pawn_rM2M_Time.htm)

<details>
<summary>**rm2m_TimerAdd(funcidx)**</summary>
+ 00_common_1_Timer.p<br/> 
+ 10_Switch_Long.p<br/>  
+ 11_Led_2.p<br/>  
+ 11_Led_2_3.p<br/>  
+ 11_Led_rgb_v1.p<br/>  
+ 11_Led_rgb_v2.p<br/>  
+ 12_Transmission_2_cyclic_connection.p<br/>  
+ 12_Transmission_3_ForceOnline.p<br/>  
+ 13_Transmission_Led.p<br/>  
+ 20_rs232_1.p<br/>  
+ 30_ui_0.p<br/>  
+ 30_ui_1.p<br/>  
+ 30_ui_2.p<br/>  
+ 40_i2c.p<br/>  
+ 50_spi.p<br/>  
+ 50_spi_winkel.p<br/>  
+ 60_statemachine_1.p<br/>  
+ 60_statemachine_2.p<br/>  
+ 61_alarm_1.p<br/>  
+ 61_alarm_2.p<br/>  
+ 70_wifi_scan.p<br/>  
+ 70_wifi_scan_devinfo.p<br/>  
</details>


<details>
<summary>**rM2M_TimerRemove(funcidx)**</summary>
+ 10_Switch_Long.p
</details>

<details>
<summary>**rM2M_TimerAddExt(funcidx)**</summary>
+ 00_common_1_Timer.p 
+ 10_Switch_Long.p 
+ 11_Led_2.p 
+ 11_Led_2_3.p 
+ 11_Led_rgb_v1.p 
+ 11_Led_rgb_v2.p 
+ 13_Transmission_Led.p 
+ 40_i2c.p 
+ 50_spi.p 
+ 50_spi_winkel.p 
</details>

<details>
<summary>**rM2M_TimerRemoveExt(funcidx)**</summary>
+ 10_Switch_Long.p
</details>

### [Uplink](http://support.microtronics.com/Developer_Documentation/Content/Developer_Documentation/sw/Pawn_rM2M_Uplink.htm)

<details>
<summary>**rM2M_TxStart(flags=0)**</summary>
+ 12_Transmission_0.p
+ 12_Transmission_1_uplink.p
+ 12_Transmission_2_cyclic_connection.p
+ 12_Transmission_3_ForceOnline.p
+ 13_Transmission_Led.p
+ 30_ui_1.p
+ 30_ui_2.p
+ 61_alarm_1.p
+ 61_alarm_2.p
</details>

<details>
<summary>**rM2M_TxSetMode(mode, flags=0)**</summary>
+ 12_Transmission_3_ForceOnline.p
+ 13_Transmission_Led.p
+ 30_ui_2.p
+ 70_wifi_scan.p
+ 70_wifi_scan_devinfo.p
</details>

<details>
<summary>**rM2M_TxGetStatus(&errorcode=0)**</summary>
+ 12_Transmission_3_ForceOnline.p 
+ 13_Transmission_Led.p
</details>

<details>
<summary>**rM2M_TxSelectItf(itf)**</summary>
+ 12_Transmission_1_uplink.p
+ 13_Transmission_Led.p
+ 70_wifi_scan.p
+ 70_wifi_scan_devinfo.p
</details>

<details>
<summary>**rM2M_RecData(timestamp, const data{}, len)**</summary>
+ 30_ui_1.p
+ 30_ui_2.p
+ 61_alarm_1.p
+ 61_alarm_2.p
</details>

<details>
<summary>**rM2M_CfgOnChg(funcidx)**</summary>
+ 30_ui_2.p
</details>

### [WiFi](http://support.microtronics.com/Developer_Documentation/Content/Developer_Documentation/sw/Pawn_rM2M_WiFi.htm)
<details>
<summary>**WiFi_Init(funcidx)**</summary>
+ 70_wifi_scan.p
+ 70_wifi_scan_devinfo.p
</details>

<details>
<summary>**WiFi_GetState()**</summary>
+ 70_wifi_scan.p
+ 70_wifi_scan_devinfo.p
</details>

<details>
<summary>**WiFi_Scan()**</summary>
+ 70_wifi_scan.p
+ 70_wifi_scan_devinfo.p
</details>

### [System](http://support.microtronics.com/Developer_Documentation/Content/Developer_Documentation/sw/Pawn_rM2M_System.htm)

<details>
<summary>**Mx_GetSysValues(values[TMx_SysValue], len=sizeof values)**</summary>
+ 30_ui_0.p
+ 30_ui_1.p
+ 30_ui_2.p
</details>

### [Encoding](http://support.microtronics.com/Developer_Documentation/Content/Developer_Documentation/sw/Pawn_rM2M_Encoding.htm)
<details>
<summary>**rM2M_GetPackedB(const data{}, pos, block[], size);**</summary>
+ 70_wifi_scan.p
+ 70_wifi_scan_devinfo.p
</details>

<details>
<summary>**rM2M_Pack(const data{}, pos, &{Float,Fixed,_}:value, type)**</summary>
+ 30_ui_1.p
+ 30_ui_2.p
+ 61_alarm_1.p
+ 61_alarm_2.p
+ 70_wifi_scan.p
+ 70_wifi_scan_devinfo.p
+ lis3dsh.inc
</details>

### [GPIO, IRQ](http://support.microtronics.com/Developer_Documentation/Content/Developer_Documentation/sw/Pawn_rM2M_GPIO_IRQ.htm)
<details>
<summary>**rM2M_GpioDir(gpio, dir)**</summary>
+ 11_Led_2.p
+ 11_Led_2_3.p
+ 11_Led_rgb_v1.p
+ 11_Led_rgb_v2.p
+ 13_Transmission_Led.p
+ 20_rs232_3.p
+ 20_rs232_4.p
+ 40_i2c.p
+ 50_spi.p
+ 50_spi_winkel.p
+ 60_statemachine_1.p
+ 60_statemachine_2.p
+ lis3dsh.inc
</details>

<details>
<summary>**rM2M_GpioSet(gpio, level)**</summary>
+ 11_Led_2.p
+ 11_Led_2_3.p
+ 11_Led_rgb_v1.p
+ 11_Led_rgb_v2.p
+ 13_Transmission_Led.p
+ 20_rs232_3.p
+ 20_rs232_4.p
+ 40_i2c.p
+ 50_spi.p
+ 50_spi_winkel.p
+ 60_statemachine_1.p
+ 60_statemachine_2.p
+ lis3dsh.inc
</details>

<details>
<summary>**rM2M_IrqInit(irq, config, funcidx)**</summary>
+ 10_Switch.p
+ 10_Switch_Long.p 
</details>

<details>
<summary>**rM2M_IrqClose(irq)**</summary>
+ 10_Switch.p
+ 10_Switch_Long.p 
</details>

### [SPI, I2C, UART](http://support.microtronics.com/Developer_Documentation/Content/Developer_Documentation/sw/Pawn_rM2M_SPI_I2C_UART.htm)
<details>
<summary>**rM2M_SpiInit(spi, clock, config)**</summary>
+ 50_spi.p
+ 50_spi_winkel.p
</details>

<details>
<summary>**rM2M_SpiClose(spi)**</summary>
+ 50_spi.p
+ 50_spi_winkel.p
</details>

<details>
<summary>**rM2M_SpiCom(spi, data{}, txlen, rxlen)**</summary>
+ lis3dsh.inc
</details>

<details>
<summary>**rM2M_I2cInit(i2c, clock, config)**</summary>
+ 40_i2c.p
</details>

<details>
<summary>**M2M_I2cClose(i2c)**</summary>
+ 40_i2c.p
</details>

<details>
<summary>**rM2M_I2cCom(i2c, adr, data{}, txlen, rxlen)**</summary>
+ sht31.inc
</details>

<details>
<summary>**rM2M_UartInit(uart, baudrate, mode, funcidx)**</summary>
+ 20_rs232_1.p
+ 20_rs232_2.p
+ 20_rs232_3.p
+ 20_rs232_4.p
</details>

<details>
<summary>**rM2M_UartWrite(uart, const data{}, len)**</summary>
+ 20_rs232_1.p
+ 20_rs232_2.p
+ 20_rs232_3.p
+ 20_rs232_4.p
</details>

### [Registry](http://support.microtronics.com/Developer_Documentation/Content/Developer_Documentation/sw/Pawn_rM2M_Registry.htm)

<details>
<summary>**rM2M_RegSetString(reg, const name[], const string[])**</summary>
+ 12_Transmission_1_uplink.p
</details>

### [Char & String](http://support.microtronics.com/Developer_Documentation/Content/Developer_Documentation/sw/Pawn_Erweiterungen_String_Funktionen.htm)

<details>
<summary>**sprintf(dest[], maxlength=sizeof dest, const format[], {Float,Fixed,_}:...)**</summary>
+ 20_rs232_2.p
+ 20_rs232_3.p
+ 20_rs232_4.p
</details>

<details>
<summary>**strcmp(const string1[], const string2[], length=cellmax)**</summary>
+ 20_rs232_3.p
+ 20_rs232_4.p
</details>

### [Various](http://support.microtronics.com/Developer_Documentation/Content/Developer_Documentation/sw/Pawn_Erweiterungen_Hilfsfunktionen.htm)

<details>
<summary>**getapilevel()**</summary>
+ 00_common_2_get_module_info.p
</details>

<details>
<summary>**rM2M_GetId(id[TrM2M_Id], len=sizeof id)**</summary>
+ 00_common_2_get_module_info.p
</details>

<details>
<summary>**funcidx(const name[])**</summary>
+ 00_common_1_Timer.p 
+ 10_Switch.p
+ 10_Switch_Long.p 
+ 11_Led_2.p 
+ 11_Led_2_3.p 
+ 11_Led_rgb_v1.p 
+ 11_Led_rgb_v2.p 
+ 12_Transmission_2_cyclic_connection.p 
+ 12_Transmission_3_ForceOnline.p 
+ 13_Transmission_Led.p 
+ 20_rs232_1.p 
+ 20_rs232_2.p 
+ 20_rs232_3.p 
+ 20_rs232_4.p 
+ 30_ui_0.p 
+ 30_ui_1.p 
+ 30_ui_2.p 
+ 40_i2c.p 
+ 50_spi.p 
+ 50_spi_winkel.p 
+ 60_statemachine_1.p 
+ 60_statemachine_2.p 
+ 61_alarm_1.p 
+ 61_alarm_2.p 
+ 70_wifi_scan.p 
+ 70_wifi_scan_devinfo.p 
</details>

### [Console](http://support.microtronics.com/Developer_Documentation/Content/Developer_Documentation/sw/Pawn_Erweiterungen_Consolen_Funktionen.htm)

<details>
<summary>**print(const string[])**</summary>
+ 00_common_0_Main.p
+ 10_Switch_Long.p 
+ 13_Transmission_Led.p  
+ 20_rs232_2.p 
+ 20_rs232_3.p 
+ 20_rs232_4.p  
+ 30_ui_1.p 
+ 30_ui_2.p 
+ 61_alarm_1.p 
+ 61_alarm_2.p 
+ 70_wifi_scan.p 
+ 70_wifi_scan_devinfo.p 
+ sht31.inc 
</details>

<details>
<summary>**printf(const format[], {Float,Fixed,_}:...)**</summary>
+ 00_common_1_Timer.p 
+ 00_common_2_get_module_info.p
+ 10_Switch.p
+ 10_Switch_Long.p 
+ 11_Led_2.p 
+ 11_Led_2_3.p 
+ 11_Led_rgb_v1.p 
+ 11_Led_rgb_v2.p 
+ 12_Transmission_0.p 
+ 12_Transmission_1_uplink.p 
+ 12_Transmission_2_cyclic_connection.p 
+ 12_Transmission_3_ForceOnline.p 
+ 13_Transmission_Led.p 
+ 20_rs232_1.p 
+ 20_rs232_2.p 
+ 20_rs232_3.p 
+ 20_rs232_4.p 
+ 30_ui_0.p 
+ 30_ui_1.p 
+ 30_ui_2.p 
+ 40_i2c.p 
+ 50_spi.p 
+ 50_spi_winkel.p 
+ 60_statemachine_1.p 
+ 60_statemachine_2.p 
+ 61_alarm_1.p 
+ 61_alarm_2.p 
+ 70_wifi_scan.p 
+ 70_wifi_scan_devinfo.p 
+ lis3dsh.inc 
+ sht31.inc 
</details>