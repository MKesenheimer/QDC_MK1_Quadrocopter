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
	conf.KP[ROLL] = 145; //40 //Roll Bewegung (Drehung um x-Achse)
	conf.KI[ROLL] = 130; //30
	conf.KD[ROLL] = 50; //23
	
	conf.KP[PITCH] = 145; //40 //Nick Bewegung (Drehung um y-Achse)
	conf.KI[PITCH] = 130; //30
	conf.KD[PITCH] = 50; //23
      
	conf.KP[YAW] = 90; //90 //Gier Bewegung (Drehung um z-Achse)
	conf.KI[YAW] = 60; //65
	conf.KD[YAW] = 0;  //0
	
      conf.KP[PIDLEVEL] = 0;
      conf.KI[PIDLEVEL] = 0;
      conf.KD[PIDLEVEL] = 0;
      
	/*conf.rcRate8 = 90;
	conf.rcExpo8 = 65;
	conf.rollPitchRate = 0;
	conf.yawRate = 0;
	conf.dynThrPID = 0;
	
	conf.thrMid8 = 50; 
	conf.thrExpo8 = 0;
	*/
      
	conf.angleTrim[0] = 0;
	conf.angleTrim[1] = 0;
}

void config()
{
	
	//Wenn das Programm auf den Mikrokontroller zum ersten mal geladen wird,
	//müssen die Startwerte ins EEprom von Hand mit folgendem Code geschrieben werden.
	//Dieser Code muss mit dem Setzen von FIRST_RUN auf 0 bei jedem nächsten
	//Mal auskommentiert werden. Gleichzeitig kann mit FIRST_RUN = 1 das EEprom
	//auf die Startwerte zurückgesetzt werden.
	
	#if FIRST_RUN == 1
		//Startwerte ins EProm schreiben
		configFirstRun();
		EEpromWriteBlock(&conf, (void*)&startAd, sizeof(conf));
	#endif
	
	EEpromReadBlock(&conf, (void*)&startAd, sizeof(conf));
	
      int i;
	for (i=0; i<8;i++)
		rcData[i] = (RCMIN+RCMAX)/2; //Startwerte setzen
      
      rcData[THROTTLE] = RCMIN;
}