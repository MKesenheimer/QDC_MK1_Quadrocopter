/*
 QDC MK1 v1.0 - September 2014
 http://deralchemist.wordpress.com/
 Copyright (c) 2014 Matthias Kesenheimer.  All rights reserved.
 An Open Source Arduino based multicopter.
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

void initClock()
{
	OSC.CTRL = OSC_RC32MEN_bm;		//aktiviert internen 32MHz Oszillator
	while(!(OSC.STATUS & OSC_RC32MRDY_bm));	//warte bis der Oszillator stabil läuft
	CCP = CCP_IOREG_gc;			//deaktiviert den Interrupt für 4 Taktzyklen -> Schutz
	CLK.CTRL = 0x01;			//Waehle den Oszillator als Taktquelle aus
}

void initTimerE0() //Timer E0 loest alle 10 ms einen Interrupt aus (OVF_IRQ)
{
	//Timer E0 initialisieren
	TCE0.CTRLA = TC_CLKSEL_DIV64_gc;
	TCE0.CTRLB = 0x00;	//Timer im "Normalmode"
	//TCE0.INTCTRLA = 0x01;	//Interrupt hat niedrige Priorität
	TCE0.INTCTRLA = 0x02;	//Interrupt hat mittlere Priorität
	//TCE0.INTCTRLA = 0x03;	//Interrupt hat hohe Priorität
	TCE0.PER = 5000;

	ms10 = 0;				//Variable, die die vergangenen Millisekunden in Zehnerschritten zaehlt
}

void initPWM()
{
	//Timer C0 als PWM initialisieren
	TCC0.PER = 0xefff;		//ganzer Zaehlerbereich wird verwendet
	TCC0.CTRLA = 0x02;		//Prescaler auf 3
	TCC0.CTRLB = 0xf3;		//Single Slope und PWM an allen PWM Ausgaengen freischalten
	
	motor[0] = 0x00;
	motor[1] = 0x00;
	motor[2] = 0x00;
	motor[3] = 0x00;
}

void initPorts()
{
	//initialisierung der Motorenausgänge
	PORTC.DIR |= (1<<PIN0);		//Motor 1
	PORTC.DIR |= (1<<PIN1);		//Motor 2
	PORTC.DIR |= (1<<PIN2);		//Motor 3
	PORTC.DIR |= (1<<PIN3);		//Motor 4
	
	//LEDs definieren
	PORTA.DIR |= (1<<PIN5);		//blau an Motor 1 = LED1= PORTA.DIR = 0x20;
	PORTC.DIR |= (1<<PIN6);		//rot an Motor 2 = LED2
	PORTC.DIR |= (1<<PIN7);		//rot an Motor 3 = LED3
	PORTE.DIR |= (1<<PIN2);		//blau an Motor 4 = LED4
	
	//TWI Ausgänge - Noetig?
	PORTE.DIRSET = PIN0_bm;      // Als Ausgang  TWI SDA
	PORTE.DIRSET = PIN1_bm;       // Als Ausgang  TWI SCL
	
	//RECEIVER UART D0
	PORTD.DIRCLR = PIN2_bm;		//Empfangen RxD0
	PORTD.DIRSET = PIN3_bm;		//Senden TxD0
	
	//DEBUG GUI UART D1
	PORTD.DIRSET = PIN7_bm;		//Pin7 D+ TxD1
	PORTD.DIRCLR = PIN6_bm;		//Pin6 D- RxD1
}

void initMPU6050()
{
	//Device Reset
	sendbuffer[0] = MPU6050_RA_PWR_MGMT_1;	//Registeradresse 0x6b
	sendbuffer[1] = 0x80;	//Device Reset
	TWI_MasterWrite(&twiMaster, SLAVE_ADDRESS, &sendbuffer[0], 2);
      while (twiMaster.status != TWIM_STATUS_READY){}
	
	//_delay_ms(10);
	_delay_loop_2(65535);	// 8,2 ms
      
	//PWR_MGMT_1
	sendbuffer[0] = MPU6050_RA_PWR_MGMT_1;	//Registeradresse 0x6b
	sendbuffer[1] = 0x03;	//DEVICE_RESET = 0, SLEEP = 0, CYCLE = 0, TEMP_DIS = 0, CLKSEL = PLL with z axis gyro reference
	TWI_MasterWrite(&twiMaster, SLAVE_ADDRESS, &sendbuffer[0], 2);
	while (twiMaster.status != TWIM_STATUS_READY){}
	
	
	//Sample Rate 1000/(1+1) =  500Hz
	sendbuffer[0] = MPU6050_RA_SMPLRT_DIV;	//Registeradresse 0x19
	sendbuffer[1] = 0x01;
	TWI_MasterWrite(&twiMaster, SLAVE_ADDRESS, &sendbuffer[0], 2);
	while (twiMaster.status != TWIM_STATUS_READY){}
	
	
	//DLPF
	sendbuffer[0] = MPU6050_RA_CONFIG; //Registeradresse 0x1a
	sendbuffer[1] = MPU6050_DLPF_CFG_20HZ;	//EXT_SYNC_SET = 0, Digital Low Pass Filter
	TWI_MasterWrite(&twiMaster, SLAVE_ADDRESS, &sendbuffer[0], 2);
	while (twiMaster.status != TWIM_STATUS_READY){}
}

void initGyro()
{	
	//GYRO_CONFIG
	sendbuffer[0] = MPU6050_RA_GYRO_CONFIG;  //Registeradresse 0x1b
	sendbuffer[1] = 0b00001000;	//Gyro Selftest FS_SEL = disabled, Scale +-500 deg/sec
	TWI_MasterWrite(&twiMaster, SLAVE_ADDRESS, &sendbuffer[0], 2);
	while (twiMaster.status != TWIM_STATUS_READY){}
}

void initAcc()
{
	//ACCEL_CONFIG
	sendbuffer[0] = MPU6050_RA_ACCEL_CONFIG;
	sendbuffer[1] = 0b00001000;	//Accel Selftest = disabled, Scale = +-4g, DHPF = disabled
	TWI_MasterWrite(&twiMaster, SLAVE_ADDRESS, &sendbuffer[0], 2);
	while (twiMaster.status != TWIM_STATUS_READY){}	
}

void initSensors()
{
	//_delay_ms(300);
      for (a=0; a<3; a++) {_delay_loop_2(65535);}	// ca. 30 ms
	initMPU6050();
	initGyro();
	initAcc();
	//_delay_ms(300);
      for (a=0; a<3; a++) {_delay_loop_2(65535);}	// ca. 30 ms
}

void initUsart()
{
	//PMIC.CTRL |= PMIC_LOLVLEX_bm; //weglassen?

      //DEBUG GUI UART D1
      USARTD1.BAUDCTRLB = (BAUD_PRESCALED1 >> 8);
      USARTD1.BAUDCTRLA = BAUD_PRESCALED1;
      USARTD1.CTRLA |= (USART_RXCINTLVL_LO_gc | USART_DREINTLVL_LO_gc | USART_RXCINTLVL1_bm);
      USARTD1.CTRLB |= (USART_TXEN_bm | USART_RXEN_bm);
      USARTD1.CTRLC |= (USART_CMODE_ASYNCHRONOUS_gc | USART_PMODE_DISABLED_gc | USART_CHSIZE_8BIT_gc);

      //Quadrocopter mit DSM2/Spektrum Empfänger
      USARTD0.BAUDCTRLA = BAUD_PRESCALED0;
      USARTD0.BAUDCTRLB = (BAUD_PRESCALED0 >> 8);
      USARTD0.CTRLA = USART_RXCINTLVL_HI_gc;
      USARTD0.CTRLB = USART_RXEN_bm;
      USARTD0.CTRLC = USART_CMODE_ASYNCHRONOUS_gc | USART_PMODE_DISABLED_gc | USART_CHSIZE_8BIT_gc | USART_SBMODE_bm; //Asynchron, no parity, 8 Bit Zeichengröße, 2 Stop Bits
}

void setup()
{
	//Initialisierungen
	initClock();
	initPorts();
	EEpromInit();
	
	//Fuer DEBUG - Motoren ausschalten
#if 1
    initPWM();
#endif
	
	initTimerE0(); //TimerE0 ist dafür zuständig, dass jede 2us ein Interrupt ausgeloest wird
	TWI_MasterInit(&twiMaster, &TWIE, TWI_MASTER_INTLVL_HI_gc, TWI_BAUDSETTING);	// TWI am PortE initialisiert
	initUsart();
	
	//Interruptlevel freigeben
	PMIC.CTRL |= PMIC_LOLVLEN_bm | PMIC_MEDLVLEN_bm | PMIC_HILVLEN_bm;
	sei();
	
	//Wichtig: muss nach der Initialisierung der Interrupts durchgefuehrt werden!,
	//da die Initialisierung auf I2C-Interrupts zugreift
	initSensors();
	config(); //Configuration
	
	//_delay_ms(3000); //Der Quadro wartet 3 Sekunden, danach kalibriert er sich
      //for (a=0; a<4; a++) {_delay_loop_2(65535);}	// ca. 40 ms
	calibrate();
    
    //Watchdog initialisieren
    WDT_EnableAndSetTimeout();
    //while (1); //Test
}

