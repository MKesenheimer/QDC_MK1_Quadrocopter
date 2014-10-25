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


void mixTable()
{
	int32_t maxMotor;
	uint8_t i;

	motor[0] = (uint32_t)constrain((int32_t)PIDMIX(+1,-1,-1), MOTORMIN, MOTORMAX); //Vorne Links
	motor[1] = (uint32_t)constrain((int32_t)PIDMIX(+1,+1,+1), MOTORMIN, MOTORMAX); //Heck Links
	motor[2] = (uint32_t)constrain((int32_t)PIDMIX(-1,+1,-1), MOTORMIN, MOTORMAX); //Heck Rechts
	motor[3] = (uint32_t)constrain((int32_t)PIDMIX(-1,-1,+1), MOTORMIN, MOTORMAX); //Vorne Rechts
	
	//Motorwerte "deckeln"
	maxMotor=motor[0];
	for( i = 0; i < MOTOR_CNT; i++ )
		if (motor[i]>maxMotor)
			maxMotor=motor[i]; //den hšchsten Wert finden
	
	for (i = 0; i < MOTOR_CNT; i++) {
		if (maxMotor > MOTORMAX) // this is a way to still have good gyro corrections if at least one motor reaches its max.
			motor[i] -= maxMotor - MOTORMAX;
		
            motor[i] = constrain(motor[i], MOTORMIN, MOTORMAX);
		
            if (rcThrottle < MINCHECK)
			motor[i] = MOTORMIN;
	}
}

void writeMotors()
{
    if (motorsActive) {
        TCC0.CCA = motor[0];	//DutyCycle fŸr Motor 1
        TCC0.CCB = motor[1];	//Motor 2
        TCC0.CCC = motor[2];	//Motor 3
        TCC0.CCD = motor[3];	//Motor 4
	}
    
    if (!motorsActive) {
        TCC0.CCA = 0;
        TCC0.CCB = 0;
        TCC0.CCC = 0;
        TCC0.CCD = 0;
    }
}