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

//Alias
#define ROLL       0	//X
#define PITCH      1	//Y
#define YAW        2	//Z
#define THROTTLE   3	//Gas
#define AUX1       4
#define AUX2       5
#define AUX3       6
#define AUX4       7
#define PIDLEVEL   7    //hat bisher keine Funktion!
#define PIDITEMS   4

//Senden und Empfangen
#define PID		   0
#define NR		   1
#define NOT		   2
#define DEB        3
#define RECON	   1
#define RECOFF	   0

//entscheidet was an die GUI gesendet werden soll
static uint8_t plot = NOT; //am Anfang nichts senden : NOT
static uint8_t receiveOn = RECOFF;
static uint8_t iter = 0;
static uint8_t next = 1;
static uint8_t before = 0;
static uint8_t whichPIDToSend = 0;
static uint8_t motorsActive = 0;

//Konfigurationsvariablen
static struct
{
	uint8_t checkNewConf;
	uint8_t KP[PIDITEMS], KI[PIDITEMS], KD[PIDITEMS];
	int16_t angleTrim[2];
} conf;

static uint8_t EEMEM startAd[sizeof(conf)];
#define FIRST_RUN 0 //auf Eins setzen, wenn das Programm zum ersten Mal auf den QDC geladen wird. Ist nur dazu da, das EEPROM zu initialiseren/formatieren.

// WATCHDOG
#define WATCHDOG_TIMEOUT WDT_PER_2KCLK_gc

//Baudrate für den DSM2 Empfänger (rx31c-K1)
#define USART_BSCALED0 0
#define USART_BAUDRATED0 115200
#define BAUD_PRESCALED0 ((F_CPU / ((int16_t)(pow (2.0, USART_BSCALED0)) * (USART_BAUDRATED0 * 16UL)))  - 1)

//DEBUG UART //Daten an die GUI
#define USART_BSCALED1 0
#define USART_BAUDRATED1  19200 //19200// //38400 //115200 //57600
#define BAUD_PRESCALED1 ((F_CPU / ((int16_t)(pow (2.0, USART_BSCALED1)) * (USART_BAUDRATED1 * 16UL)))  - 1)

//DEBUG
#define DEBUGITEMS 10
static float debug[DEBUGITEMS];
static uint32_t meanTime = 0;
static uint32_t sumTime = 0;
static int num = 0;

//Zeitmanagment
//volatile uint32_t micro;
static uint32_t ms10 = 0;
static uint32_t currentTime = 0;
static uint32_t previousTime = 0;
static uint16_t cycleTime = 0;
static float dt = 0.00125; //sec
static uint8_t a = 0; //Laufvariable für die _delay_loop2

//I2C Einstellungen für MPU6050
#define BAUDRATE	400000
#define SLAVE_ADDRESS    0x69 //Adresse des MPU6050
#define TWI_BAUDSETTING TWI_BAUD(F_CPU, BAUDRATE)
TWI_Master_t twiMaster;
static uint8_t sendbuffer[2];
static uint8_t ra;	//temporaere Registeradresse zum Senden der I2C Daten

//Anzahl der Kalibrationsdurchgaenge Gyro/Acc
static uint16_t calibratingG = 10000;
static uint16_t calibratingA = 10000;
static float gyroOffset[3] = {0,0,0}; //alles int16_t
static float accOffset[3] = {0,0,0};
static float gyroADC[3] = {0,0,0};
static float accADC[3] = {0,0,0};
static float gyroRate[3] = {0,0,0};
static float gyroAngle[3] = {0,0,0};
static float accAngle[3] = {0,0,0};

//Empfaengersettings
#define RCMIN 1140 //Falls der Empfänger andere Offset-Werte hat, hier ändern
#define RCMAX 1860
#define RCANGLEMIN -500 //RC Winkel in 0.1 Grad Einheiten
#define RCANGLEMAX 500
#define RCTHROTTLEMIN 10
#define RCTHROTTLEMAX 1000
#define MOTORMIN 0 //PWM Minimalwert
#define MOTORMAX 60000 //PWM Maximalwert
#define MOTORMID (MOTORMAX + MOTORMIN)/2
#define MOTORRANGE (MOTORMAX - MOTORMIN)
#define MINCHECK 40
#define MAXCHECK 420
#define PIDRATIO 1 //Bestimmt den Einfluss der PID-Werte auf die Drehzahl der Motoren in Bezug auf den Gaswert von der Fernsteuerung
#define THROTTLERATIO 60
static uint32_t rcData[8]; // interval [1150,1850], aktuelle rcDaten gemittelt
static int32_t rcAngle[2]; // interval [-500,500]
static int32_t rcYawRate; // interval [-500,500]
static uint16_t rcThrottle; // interval [0,1000]

//PWM
#define MOTOR_CNT 4
#define PIDMIX(X,Y,Z) (THROTTLERATIO * rcThrottle + PIDRATIO * (axisPID[ROLL]*X + axisPID[PITCH]*Y + 1.414 * axisPID[YAW]*Z))
static uint32_t motor[MOTOR_CNT];

//PID-Settings
static float axisPID[PIDITEMS];
static float previousError[PIDITEMS] = {0,0,0,0};
static float error[PIDITEMS] = {0,0,0,0};
static float pTerm[PIDITEMS] = {0,0,0,0};
static float dTerm[PIDITEMS] = {0,0,0,0};
static float iTerm[PIDITEMS] = {0,0,0,0};
static float iSum[PIDITEMS] = {0,0,0,0};

//Filter-Settings
static float compAngle[3] = {0,0,0}; //Eulerwinkel in Grad
static float filter_RollTerm[3] = {0,0,0};
static float filter_PitchTerm[3] = {0,0,0};
//First order complementary filter
static float ratio = 0.9994; //Verhältnis von ACC zu GYRO
//Second order complementary filter
//BIG4825 0.1, je größer dieser Wert, desto mehr Einfluss
//hat das ACC bei der Filterung. Driftet das Gyro findet
//der QDC mit einem höheren Wert schneller zu den "richtigen" Werten zurück.
#define timeConstant 1
//Kalman Filter
static float Q_angle  =  0.001; //0.001    //Q indicates how much we trust the acceleromter
static float Q_gyro   =  0.003;  //0.003 //relative to the gyros
static float R_angle  =  0.3;  //0.03 oder 0.3 (BIG4825) //we expect 0.01 rad jitter from the accelerometer
static float bias[2] = {0,0};
static float P_00[2] = {0,0};
static float P_01[2] = {0,0};
static float P_10[2] = {0,0};
static float P_11[2] = {0,0};

//LEDs
static uint16_t LEDCOUNT = 0;
#define TOGGLELED1      PORTA.OUTTGL |= (1<<PIN5); //Led_vorn
#define TOGGLELED2      PORTC.OUTTGL |= (1<<PIN6); //Led_hinten
#define TOGGLELED3      PORTC.OUTTGL |= (1<<PIN7);
#define TOGGLELED4      PORTE.OUTTGL |= (1<<PIN2);
#define TOGGLELED12     TOGGLELED1; TOGGLELED2;
#define TOGGLELED34     TOGGLELED3; TOGGLELED4;

#define CLRLED1         PORTA.OUTCLR |= (1<<PIN5);
#define CLRLED2         PORTC.OUTCLR |= (1<<PIN6);
#define CLRLED3         PORTC.OUTCLR |= (1<<PIN7);
#define CLRLED4         PORTE.OUTCLR |= (1<<PIN2);
#define CLRLED12        CLRLED1; CLRLED2;
#define CLRLED34        CLRLED3; CLRLED4;

#define SETLED1         PORTA.OUTSET |= (1<<PIN5);
#define SETLED2         PORTC.OUTSET |= (1<<PIN6);
#define SETLED3         PORTC.OUTSET |= (1<<PIN7);
#define SETLED4         PORTE.OUTSET |= (1<<PIN2);

#define LEDPIN_TOGGLE   PORTA.OUTTGL |= (1<<PIN6); //freie Anschluesse
#define LEDPIN_ON       PORTA.OUTSET |= (1<<PIN6);
#define LEDPIN_OFF      PORTA.OUTCLR |= (1<<PIN6);
#define BUZZERPIN_ON    PORTA.OUTSET |= (1<<PIN7);
#define BUZZERPIN_OFF   PORTA.OUTCLR |= (1<<PIN7);

//Compilerfunktionen
#ifndef map
#define map(oldmin, oldmax, newmin, newmax, x) ((newmin*oldmax - newmax*oldmin + newmax*x - newmin*x)/(oldmax - oldmin))
#endif

#define ssin(val) (val)
#define scos(val) (1.0f - (val)*(val)/2.0f)

#ifndef max
#define max(a, b) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef min
#define min(a, b) ( ((a) < (b)) ? (a) : (b) )
#endif

#ifndef constrain
#define constrain(Value, Min, Max) ( ((Value) < (Min)) ? (Min) : ((Value) > (Max)) ? (Max) : (Value) )
#endif

#ifndef fp_is_neg
#define fp_is_neg(val) (( ( (uint8_t*) &val)[3] & 0x80) != 0)
#endif