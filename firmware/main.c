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


/*
 * -----------> Wichtige Hinweise: <----------------
 *
 * Bevor der QDC zum ersten Mal geflasht wird, muss unbedingt FIRST_RUN
 * in def.c auf 1 gesetzt werden. Danach ein zweites mal mit FIRST_RUN = 0
 * flashen. Das ist nur nötig um zum ersten Mal das EEPROM zu formatieren,
 * danach wird dieser Aufruf kein weiteres Mal benötigt.
 *
 * PWM_init() aus/einkommentieren um die Motoren für DEBUG-Zwecke aus/einzuschalten.
 *
 * In def.c muss der richtige Receiver ausgewählt werden. Es stehen ein DSL oder 
 * ein DSM2 Receiver zur Auswahl.
 *
 */

#define F_CPU 32000000UL

#include <stdlib.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <avr/io.h>
#include <math.h>
#include <string.h>
#include "avr_compiler.h"
#include "MPU6050.h"
#include "twi_master_driver.h"
#include "twi_master_driver.c"
#include "xeeprom.h"
#include "def.c"
#include "watchdog.c"
#include "time.c"
#include "IMU.c"
#include "config.c"
#include "output.c"
#include "receive.c"
#include "init.c"
#include "serial.c"
#include "filters.c"
#include "pid.c"

void blinkleds(int option) {
      if (option == 0) {
            if (LEDCOUNT == 500 || LEDCOUNT == 700) {
                  SETLED1; SETLED2; SETLED3; SETLED4;
            }
            if (LEDCOUNT == 600 || LEDCOUNT == 900) {
                  CLRLED1; CLRLED2; CLRLED3; CLRLED4;
            }
            if (LEDCOUNT > 1000) {
            LEDCOUNT = 0;
            }
      }
      
      if (option == 1) {
            if (LEDCOUNT == 125) {
                  CLRLED1;
                  SETLED2;
            }
            if (LEDCOUNT == 250) {
                  CLRLED2;
                  SETLED3;
            }
            if (LEDCOUNT == 375) {
                  CLRLED3;
                  SETLED4;
            }
            if (LEDCOUNT == 500) {
                  CLRLED4;
                  SETLED1;
            }
            if (LEDCOUNT > 500) {
                  LEDCOUNT = 0;
            }
      }
      LEDCOUNT++;
}

int main()
{
	setup();
	uint32_t sendTime = 0;
	uint32_t rcTime = 0;
	
	while (1) {
            
		//Zeitmessung
		currentTime = micros(); //Zeit in Einheiten von 10mus
		cycleTime = currentTime - previousTime; //1250mus ~1.2ms => 800Hz
		previousTime = currentTime;
		//Mittlere Ausführungszeit
		sumTime += cycleTime;
		num++;
		if (num > 100) {
			meanTime = sumTime/100;
			num = 0;
			sumTime = 0;
		}
		
		//Integrationszeit
		dt = (float)cycleTime/1000000; //~0.001250s
		
		//Acc und Gyro Daten einlesen und integrieren
		Gyro_getADC();
		ACC_getADC();
            //first_order_comp_filter();
		//second_order_comp_filter();
            kalman_filter();
		pid();
            
		//alle 20ms rcData einlesen
		if (currentTime > rcTime) {
			USARTD0.CTRLB = USART_RXEN_bm;
			rcTime = currentTime + 20000;
			computeRC(); //berechnet die rcDaten -> rcData[channel] im Intervall [SIGNALMIN,SIGNALMAX]
                  
                  //Wenn linker Stick nach rechts unten und
                  //rechter Stick nach links unten gedrückt wird kalibriert sich der QDC neu
                  if ( (rcThrottle < 20) && (rcAngle[ROLL] < -450) && (rcAngle[PITCH]<-450) && (rcYawRate < -450) ) {
                        SETLED1; SETLED2; SETLED3; SETLED4;
                        for (a=0; a<8; a++) {_delay_loop_2(65535);}	// ca. 1s
                        while (1) {}; //Watchdog ausloesen
                  }
                  
                  //Wenn linker Stick nach rechts unten und
                  //rechter Stick nach rechts unten gedrückt werden die Motoren gestartet/gestopt
                  if ( (rcThrottle < 20) && (rcAngle[ROLL] > 450) && (rcAngle[PITCH]<-450) && (rcYawRate < -450) ) {
                        int first = 0;
                        
                        //Motoren ausschalten
                        if (motorsActive && !first) {
                              TCC0.CCA = 0;
                              TCC0.CCB = 0;
                              TCC0.CCC = 0;
                              TCC0.CCD = 0;
                              motorsActive = 0;
                              first = 1;
                        }
                        
                        //Motoren einschalten
                        if (!motorsActive && !first) {
                              motorsActive = 1;
                              first = 1;
                        }
                        
                        int i;
                        for (i=0; i<15; i++) {
                              SETLED1; SETLED2; SETLED3; SETLED4;
                              for (a=0; a<4; a++) {_delay_loop_2(65535);}	// ca. 500 ms
                              CLRLED1; CLRLED2; CLRLED3; CLRLED4;
                              for (a=0; a<4; a++) {_delay_loop_2(65535);}
                        }
                  }
		}
            
		//alle 20ms Daten an die GUI senden
		if (currentTime > sendTime) {
			sendTime = currentTime + 20000;
			switch (plot) {
				case NR:
                    //hier werden die Winkel mit 10 multipliziert,
                    //da die Übertragung nur mit Integerwerte funktionert.
                    //Es soll aber eine Auflösung von 0.1 Grad erhalten bleiben,
                    //somit dividiert die GUI die erhaltenen Werte wieder durch 10.
					sendAnglesToGUI(compAngle[ROLL]*10, compAngle[PITCH]*10);
                    sendMotorsToGUI(motor[0]/1000, motor[1]/1000, motor[2]/1000, motor[3]/1000);
					break;
				case PID:
					sendPIDToGUI(pTerm[whichPIDToSend]/100, iTerm[whichPIDToSend]/100, dTerm[whichPIDToSend]/100);
                    sendMotorsToGUI(motor[0]/1000, motor[1]/1000, motor[2]/1000, motor[3]/1000);
					break;
                case DEB:
                    sendDebugToGUI(&debug[0]);
                    break;
				case NOT:
					//nichts senden
					break;
			}
		}
            
            if (rcThrottle < 200) {
                  blinkleds(1);
            }
            if (rcThrottle >= 200) {
                  blinkleds(0);
            }
		mixTable();
            writeMotors();
		WDT_Reset();
	}

}
