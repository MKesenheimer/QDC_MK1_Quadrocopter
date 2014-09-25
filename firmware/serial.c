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

/* Hinweise zum Senden und Empfangen:
 * 
 * Alle Werte werden vom QDC als ASCII-Werte gesendet. Um die Werte voneinander
 * unterscheiden zu koennen, werden zwischen den Zahlenwerten Buchstaben
 * eingefuegt. So hat zum Beispiel das Datenpaket der PID-Konfigurationswerte
 * die Form {a KP[ROLL] a KI[ROLL] a KD[ROLL] \r}. Das Cocoa-Programm auf dem
 * Rechner liest die verschiedenen Strings ein (der Wagenruecklauf \r ist notwendig
 * um dem Cocoa-Programm das Ende des Strings mitzuteilen) und scannt nach den
 * verschiedenen Buchstaben, so dass die Zahlenwerten den korrekten Werten zugeordnet
 * werden koennen.
 */

// TODO: Das gesamte Programm kann mit dem Einsatz von Funktionen eleganter geschrieben werden.
// Zum Beispiel so: sendValues(uint_8 Identifier, uint_8 value1, uint_8 value2, ...)

void changeConfig()
{	
	//neue Daten gleich ins EEPROM schreiben
	EEpromWriteBlock(&conf, (void*)&startAd, sizeof(conf));
}

void send16(int16_t a)
{
	uint8_t i;
	char buffer[6] = {0, 0, 0, 0, 0, 0}; //längste erwartete Zeichenfolge: -1234
	itoa(a, buffer, 10); //Zahl in Ascii umwandeln, 10 = Dezimalsystem
	for (i = 0; buffer[i] != 0; i++) {
		while (!( USARTD1.STATUS & USART_DREIF_bm));
		USARTD1.DATA = buffer[i];
	}
}

void sendPIDToGUI(int16_t p, int16_t i, int16_t d)
{
	uint8_t oldSREG;
	oldSREG = SREG; cli();
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x2E; //Punkt senden
	send16(p);
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x2E; //Punkt senden
	send16(i);
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x2E; //Punkt senden
	send16(d);
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x0A; //Wagenrücklauf - \r

	SREG = oldSREG; sei();
	//_delay_ms(10);
      //_delay_loop_2(65535);	// 8.2 ms
}

void sendAnglesToGUI(int16_t a, int16_t b)
{
	uint8_t oldSREG;
	oldSREG = SREG; cli();

	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x2C; //Komma senden
	send16(a);
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x2C; //Komma senden
	send16(b);
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x0A; //Wagenrücklauf - \r
	
	SREG = oldSREG; sei();
}


//Zu sendender String: (die Buchstaben dienen als Identifier der Wertepaare)

//a KP[ROLL] a KI[ROLL] a KD[ROLL] \r
//b KP[PITCH] b KI[PITCH] b KD[PITCH] \r
//c KP[YAW] c KI[YAW] c KD[YAW] \r
//d KP[PIDLEVEL] d KI[PIDLEVEL] d KD[PIDLEVEL] \r
//e rcRate8 e rollPitchRate e yawRate e rcExpo8 \r
//f dynThrPID f thrMid8 f thrExpo8 \r
//g angleTrim[0] g angleTrim[1] \r

void sendConfPIDRoll()
{
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x61; //a senden
	send16(conf.KP[ROLL]);
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x61;
	send16(conf.KI[ROLL]);
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x61;
	send16(conf.KD[ROLL]);

	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x0A; //Wagenrücklauf - \r
}

void sendConfPIDPitch()
{
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x62; //b senden
	send16(conf.KP[PITCH]);
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x62;
	send16(conf.KI[PITCH]);
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x62;
	send16(conf.KD[PITCH]);

	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x0A; //Wagenrücklauf - \r
}

void sendConfPIDYaw()
{
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x63; //c senden
	send16(conf.KP[YAW]);
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x63;
	send16(conf.KI[YAW]); 
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x63;
	send16(conf.KD[YAW]);

	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x0A; //Wagenrücklauf - \r
}

void sendConfPIDPidlevel()
{
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x64; //d senden
	send16(conf.KP[PIDLEVEL]); //früher PIDLEVEL, löschen!
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x64;
	send16(conf.KD[PIDLEVEL]);
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x64;
	send16(conf.KD[PIDLEVEL]);

	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x0A; //Wagenrücklauf - \r
}

void sendConfrcRate()
{
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x65; //e senden
	send16(conf.rcRate8);

	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x65;
	send16(conf.rollPitchRate);
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x65;
	send16(conf.yawRate);
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x65;
	send16(conf.rcExpo8);

	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x0A; //Wagenrücklauf - \r
}

void sendConfThr()
{
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x66; //f senden
	send16(conf.dynThrPID);
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x66;
	send16(conf.thrMid8);
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x66;
	send16(conf.thrExpo8);

	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x0A; //Wagenrücklauf - \r
}

void sendConfAngleTrim()
{
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x67; //g senden
	send16(conf.angleTrim[0]); //Achtung: int8_t Wert, TODO
	
	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x67;
	send16(conf.angleTrim[1]); //Achtung: int8_t Wert, TODO

	while (!( USARTD1.STATUS & USART_DREIF_bm));
	USARTD1.DATA = 0x0A; //Wagenrücklauf - \r
}

ISR(USARTD1_RXC_vect)
{
      
      uint8_t oldSREG;
      oldSREG = SREG; cli();
      
      
      while ( !( USARTD1.STATUS & USART_RXCIF_bm) );
      char receivedData = USARTD1.DATA;
      
      if (receiveOn) {
            if (iter == 0) {
                  conf.KP[ROLL] = (uint8_t) receivedData;
                  iter = 1;
                  before = next;
            }
            if (iter == 1 && before != next) {
                  conf.KI[ROLL] = (uint8_t) receivedData;
                  iter = 2;
                  before = next;
            }
            if (iter == 2 && before != next) {
                  conf.KD[ROLL] = (uint8_t) receivedData;
                  iter = 3;
                  before = next;
            }
            if (iter == 3 && before != next) {
                  conf.KP[PITCH] = (uint8_t) receivedData;
                  iter = 4;
                  before = next;
            }
            if (iter == 4 && before != next) {
                  conf.KI[PITCH] = (uint8_t) receivedData;
                  iter = 5;
                  before = next;
            }
            if (iter == 5 && before != next) {
                  conf.KD[PITCH] = (uint8_t) receivedData;
                  iter = 6;
                  before = next;
            }
            if (iter == 6 && before != next) {
                  conf.KP[YAW] = (uint8_t) receivedData;
                  iter = 7;
                  before = next;
            }
            if (iter == 7 && before != next) {
                  conf.KI[YAW] = (uint8_t) receivedData;
                  iter = 8;
                  before = next;
            }
            if (iter == 8 && before != next) {
                  conf.KD[YAW] = (uint8_t) receivedData;
                  iter = 9;
                  before = next;
            }
            if (iter == 9 && before != next) {
                  conf.KP[PIDLEVEL] = (uint8_t) receivedData;
                  iter = 10;
                  before = next;
            }
            if (iter == 10 && before != next) {
                  conf.KI[PIDLEVEL] = (uint8_t) receivedData;
                  iter = 11;
                  before = next;
            }
            if (iter == 11 && before != next) {
                  conf.KD[PIDLEVEL] = (uint8_t) receivedData;
                  iter = 12;
                  before = next;
            }
            if (iter == 12 && before != next) {
                  conf.rcRate8 = (uint8_t) receivedData;
                  iter = 13;
                  before = next;
            }
            if (iter == 13 && before != next) {
                  conf.rollPitchRate = (uint8_t) receivedData;
                  iter = 14;
                  before = next;
            }
            if (iter == 14 && before != next) {
                  conf.yawRate = (uint8_t) receivedData;
                  iter = 15;
                  before = next;
            }
            if (iter == 15 && before != next) {
                  conf.rcExpo8 = (uint8_t) receivedData;
                  iter = 16;
                  before = next;
            }
            if (iter == 16 && before != next) {
                  conf.dynThrPID = (uint8_t) receivedData;
                  iter = 17;
                  before = next;
            }
            if (iter == 17 && before != next) {
                  conf.thrMid8 = (uint8_t) receivedData;
                  iter = 18;
                  before = next;
            }
            if (iter == 18 && before != next) {
                  conf.thrExpo8 = (uint8_t) receivedData;
                  iter = 19;
                  before = next;
            }
            if (iter == 19 && before != next) {
                  conf.angleTrim[0] = (uint8_t) receivedData;
                  iter = 20;
                  before = next;
            }
            if (iter == 20 && before != next) {
                  conf.angleTrim[1] = (uint8_t) receivedData;
                  iter = 0;
                  receiveOn = RECOFF; //Empfangen der Konfigurationswerte abschalten
                  changeConfig();
            }
      }
      
      //a KP[ROLL] a KI[ROLL] a KD[ROLL] \r
      //b KP[PITCH] b KI[PITCH] b KD[PITCH] \r
      //c KP[YAW] c KI[YAW] c KD[YAW] \r
      //d KP[PIDLEVEL] d KI[PIDLEVEL] d KD[PIDLEVEL] \r
      //e rcRate8 e rollPitchRate e yawRate e rcExpo8 \r
      //f dynThrPID f thrMid8 f thrExpo8 \r
      //g angleTrim[0] g angleTrim[1] \r
      
      if (!receiveOn) {
            switch (receivedData) {
                  case 0x41: //A - Nick und Rollwerte senden
                        plot = NR;
                        break;
                  case 0x58: //X - PIDROLL-Werte senden
                        plot = PID;
                        whichPIDToSend = 0;
                        break;
                  case 0x59: //Y - PIDROLL-Werte senden
                        plot = PID;
                        whichPIDToSend = 1;
                        break;
                  case 0x60: //Z - PIDROLL-Werte senden
                        plot = PID;
                        whichPIDToSend = 2;
                        break;
                  case 0x43: //C - nichts senden
                        plot = NOT;
                        break;
                  case 0x44: //D - Struct Conf senden
                        sendConfPIDRoll();
                        //_delay_ms(100);
                        for (a=0; a<10; a++) {_delay_loop_2(65535);}	// ca. 100ms
                        sendConfPIDPitch();
                        //_delay_ms(100);
                        for (a=0; a<10; a++) {_delay_loop_2(65535);}	// ca. 100ms
                        sendConfPIDYaw();
                        //_delay_ms(100);
                        for (a=0; a<10; a++) {_delay_loop_2(65535);}	// ca. 100ms
                        sendConfPIDPidlevel();
                        //_delay_ms(100);
                        for (a=0; a<10; a++) {_delay_loop_2(65535);}	// ca. 100ms
                        sendConfrcRate();
                        //_delay_ms(100);
                        for (a=0; a<10; a++) {_delay_loop_2(65535);}	// ca. 100ms
                        sendConfThr();
                        //_delay_ms(100);
                        for (a=0; a<10; a++) {_delay_loop_2(65535);}	// ca. 100ms
                        sendConfAngleTrim();
                        //_delay_ms(100);
                        for (a=0; a<10; a++) {_delay_loop_2(65535);}	// ca. 100ms
                        break;
                  case 0x52: //R - Reset
                        while(1); //Endlossschleife um den Watchdog auszuloesen, der den QDC zuruecksetzt.
                        break;
                  case 0x53: //S - Empfangen der Konfigurationswerte starten
                        receiveOn = RECON;
                        break;
                  case 0x45: //E - Empfangen der Konfigurationswerte abschalten
                        receiveOn = RECOFF;
                        break;
                  case 0x4d: //M - Motoren starten
                        motorsActive = 1;
                        break;
                  case 0x4e: //N - Motoren stoppen
                        motorsActive = 0;
                        break;
            }
      }
      next++;
      SREG = oldSREG; sei();
}