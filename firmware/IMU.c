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

#define gyroSensitivityRoll 66.5 //66.5 Dead on at last check
#define gyroSensitivityPitch 66.5 //72.7 Dead on at last check
#define gyroSensitivityYaw 65.5

//MasterTwi Interrupthandler
ISR(TWIE_TWIM_vect)
{
	TWI_MasterInterruptHandler(&twiMaster);
}

void calibrate_Gyro()
{
	int i = 0;
	int32_t calibrationSum[3] = {0,0,0};
	
      SETLED2;
      
	for (i = 0; i < calibratingG; i++) {
		ra = MPU6050_RA_GYRO_XOUT_H;
		TWI_MasterWriteRead(&twiMaster, SLAVE_ADDRESS, &ra, 1, 6);
		while (twiMaster.status != TWIM_STATUS_READY){}
		calibrationSum[ROLL] += ((twiMaster.readData[0] << 8) + twiMaster.readData[1]);
		calibrationSum[PITCH] += ((twiMaster.readData[2] << 8) + twiMaster.readData[3]);
		calibrationSum[YAW] += ((twiMaster.readData[4] << 8) + twiMaster.readData[5]);
		//_delay_ms(1);
            _delay_loop_2(200);
            WDT_Reset();
	}
      
      CLRLED2;
	
	gyroOffset[ROLL] = calibrationSum[ROLL]/calibratingG;
	gyroOffset[PITCH] = calibrationSum[PITCH]/calibratingG;
	gyroOffset[YAW] = calibrationSum[YAW]/calibratingG;
}

void calibrate_Acc()
{
	int i = 0;
	int32_t calibrationSum[3] = {0,0,0};
	
      SETLED3;
      
	for (i = 0; i < calibratingA; i++) {
		ra = MPU6050_RA_ACCEL_XOUT_H;
		TWI_MasterWriteRead(&twiMaster, SLAVE_ADDRESS, &ra, 1, 6);
		while (twiMaster.status != TWIM_STATUS_READY){}
		calibrationSum[ROLL] += ((twiMaster.readData[0] << 8) + twiMaster.readData[1]);
		calibrationSum[PITCH] += ((twiMaster.readData[2] << 8) + twiMaster.readData[3]);
		calibrationSum[YAW] += ((twiMaster.readData[4] << 8) + twiMaster.readData[5]);
		//_delay_ms(1);
            _delay_loop_2(200);
            WDT_Reset();
	}
      
      CLRLED3;
	
	accOffset[ROLL] = calibrationSum[ROLL]/calibratingA;
	accOffset[PITCH] = calibrationSum[PITCH]/calibratingA;
	accOffset[YAW] = calibrationSum[YAW]/calibratingA;
}

void calibrate()
{
      
      accOffset[ROLL] = 0;
      accOffset[PITCH] = 0;
      accOffset[YAW] = 0;
      gyroOffset[ROLL] = 0;
      gyroOffset[PITCH] = 0;
      gyroOffset[YAW] = 0;
      
      calibrate_Gyro();
      calibrate_Acc();
      
      int i;
      for (i=0; i<15; i++) {
            SETLED1; SETLED2; SETLED3; SETLED4;
            for (a=0; a<4; a++) {_delay_loop_2(65535);}	// ca. 500 ms
            CLRLED1; CLRLED2; CLRLED3; CLRLED4;
            for (a=0; a<4; a++) {_delay_loop_2(65535);}
      }
}

void Gyro_getADC()
{
	ra = MPU6050_RA_GYRO_XOUT_H; //Startregister der Winkelbeschleunigungswerte
	TWI_MasterWriteRead(&twiMaster, SLAVE_ADDRESS, &ra, 1, 6);
	while (twiMaster.status != TWIM_STATUS_READY){}
	gyroADC[ROLL] = ((twiMaster.readData[0] << 8) + twiMaster.readData[1]) - gyroOffset[ROLL];
	gyroADC[PITCH] = ((twiMaster.readData[2] << 8) + twiMaster.readData[3]) - gyroOffset[PITCH];
	gyroADC[YAW] = ((twiMaster.readData[4] << 8) + twiMaster.readData[5]) - gyroOffset[YAW];
	
	//nachfolgende Befehle ~140mus
	
	//Gyro Rates (Winkelgeschwindigkeit)
	gyroRate[ROLL] = (float)gyroADC[ROLL]/gyroSensitivityRoll;
	gyroRate[PITCH] = (float)gyroADC[PITCH]/gyroSensitivityPitch;
	gyroRate[YAW] = (float)gyroADC[YAW]/gyroSensitivityYaw;
	
	//Gyro Integral (Winkel)
	gyroAngle[ROLL] += (float)gyroRate[ROLL]*dt;
	gyroAngle[PITCH] += (float)gyroRate[PITCH]*dt;
      gyroAngle[YAW] += (float)gyroRate[YAW]*dt;
      
      //TODO aus gyroAngle[YAW] den gyroOffset[YAW] bestimmen (Inflight Calibration)
}

void ACC_getADC()
{
	ra = MPU6050_RA_ACCEL_XOUT_H; //Startregister der Beschleunigungswerte
	TWI_MasterWriteRead(&twiMaster, SLAVE_ADDRESS, &ra, 1, 6); //Senden der Registeraddresse und auf Antwort warten, &ra = Adresse der Variable ra Ÿbergeben
	while (twiMaster.status != TWIM_STATUS_READY){} //Warten bis die Kommunikation abgeschlossen ist
	accADC[ROLL] = ((twiMaster.readData[0] << 8) + twiMaster.readData[1]) - accOffset[ROLL]; //empfangene 8 Bit Werte in einer 16 Bit Variable speichern
	accADC[PITCH] = ((twiMaster.readData[2] << 8) + twiMaster.readData[3]) - accOffset[PITCH];
	accADC[YAW] = ((twiMaster.readData[4] << 8) + twiMaster.readData[5]); //accOffset[YAW]
	
	//TODO: woher kommen die 57.295?
	accAngle[ROLL] = 57.295*atan((float)accADC[PITCH]/sqrt(pow((float)accADC[YAW],2)+pow((float)accADC[ROLL],2)));
	accAngle[PITCH] = 57.295*atan((float)-accADC[ROLL]/sqrt(pow((float)accADC[YAW],2)+pow((float)accADC[PITCH],2)));
}
