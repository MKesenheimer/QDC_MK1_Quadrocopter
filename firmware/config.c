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

void configFirstRun()
{
      //TODO: Aendern!
	conf.KP[ROLL] = 26; //40 //Roll Bewegung (Drehung um x-Achse)
	conf.KI[ROLL] = 200; //30
	conf.KD[ROLL] = 7; //23
	
	conf.KP[PITCH] = 26; //40 //Nick Bewegung (Drehung um y-Achse)
	conf.KI[PITCH] = 200; //30
	conf.KD[PITCH] = 7; //23
	
	
	conf.KP[YAW] = 40; //90 //Gier Bewegung (Drehung um z-Achse)
	conf.KI[YAW] = 25; //65
	conf.KD[YAW] = 0;  //0
	
	conf.KP[7] = 70; //70 
	conf.KI[7] = 10;	//10
	conf.KD[7] = 100; //100
	
	
	conf.rcRate8 = 90; 
	conf.rcExpo8 = 65;
	conf.rollPitchRate = 0;
	conf.yawRate = 0;
	conf.dynThrPID = 0;
	
	conf.thrMid8 = 50; 
	conf.thrExpo8 = 0;
	
	conf.angleTrim[0] = 0;
	conf.angleTrim[1] = 0;
    
      #ifdef GYRO_SMOOTHING
      conf.Smoothing[3] = GYRO_SMOOTHING;
      #endif
    
	conf.checkNewConf = EEPROM_CONF_VERSION;
}

void config()
{
	
	//Wenn das Programm auf den Mikrokontroller zum ersten mal geladen wird,
	//mŸssen die Startwerte ins EEprom von Hand mit folgendem Code geschrieben werden.
	//Dieser Code muss mit dem Setzen von FIRST_RUN auf 0 bei jedem nŠchsten
	//Mal auskommentiert werden. Gleichzeitig kann mit FIRST_RUN = 1 das Eprom
	//auf die Startwerte zurŸckgesetzt werden.
	
	#if FIRST_RUN == 1
		//Startwerte ins EProm schreiben
		configFirstRun();
		EEpromWriteBlock(&conf, (void*)&startAd, sizeof(conf));
	#endif
	
	EEpromReadBlock(&conf, (void*)&startAd, sizeof(conf));
	
	/* Ablauf mit Eprom
	 sobald von der GUI andere Configwerte empfangen werden conf.checkNewConf++ und die neuen Werte gleich ins Eprom schreiben.
	 das nŠchste mal, wenn beim Starten config() aufgerufen wird, wird die erste Abfrage Ÿbersprungen und 
	 if conf.checkNewConf >= conf.versionNumber
	*/
	
	uint8_t i;
	for (i=0; i<8;i++)
		rcData[i] = 0; //Startwerte setzen
}

