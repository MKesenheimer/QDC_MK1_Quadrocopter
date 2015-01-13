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

//Konfigurationshinweise:
//P-Wert erh�hen bis unkontrollierte Oszillationen beginnen, dann solange verringern bis Oszillationen verschwinden
//I-Wert solange ver�ndern, bis der Copter nicht mehr zum Sollwert zur�ckkehrt (f�ngt an zu driften), dann langsam erh�hen
//D-Wert erh�hen bis das Ausgleichen abrupter �nderungen aus der Gleichgewichtslage zu lange dauert, dann langsam erniedrigen

//Merke:
//langsame Oszillationen -> P-Wert niedriger, oder D-Wert gr��er, oder I-Wert niedriger
//schnelle Oszillationen (zwitschern) -> D-Wert niedriger
//Drift -> I-Wert erh�hen
//Kein Ausgleich schneller �nderungen -> D-Wert gr��er

//P: Proportional: Gegenverst�rkung der Winkelgeschwindigkeit, regelt proportional zu einem Fehler
//I: Integral: Gegenverst�rkung des Winkels, wenn der Fehler konstant bleibt, wird die Verst�rkung so lange erh�ht, bis eine Verbesserung zu verzeichnen ist
//D: Differential: Verst�rkung der Winkelbeschleunigung, wird dieser Wert erh�ht, regelt der Copter schneller auf seinen Soll-Wert zur�ck, der D-Wert "sagt den Regelwert voraus", je h�her die �nderung des Fehlers ist, desto gr��er muss die Anpassung sein.

void pid() {

	//Berechnung mit float-Werten
	previousError[ROLL] = error[ROLL];
	previousError[PITCH] = error[PITCH];
	previousError[YAW]= error[YAW];
	
      //ROLL und PITCH Regler
	//rcAngle im Intervall [-500,500], compAngle im Intervall [-180,180]
      //mit rcAngle/10 lassen sich also Winkel von -50 bis 50 Deg ansteuern
      int angle = ROLL;
      for (angle = ROLL; angle<=PITCH; angle++) {
            error[angle] = (float)rcAngle[angle]/10 - compAngle[angle] + conf.angleTrim[angle]; //[-230,230]deg
            pTerm[angle] = error[angle]*conf.KP[angle];
            iSum[angle] += error[angle]*dt;
            iSum[angle] = constrain(iSum[angle],-5,5); //vorher 50 -> gute Ergebnis mit KI = 145
            iTerm[angle] = iSum[angle]*conf.KI[angle];
            dTerm[angle] = gyroRate[angle]*conf.KD[angle]; //[-10,10]deg/sec //TODO Intervall messen
      }
      
      //Alternative Derivative berechnung (Picopter)
      /*
       dHist[dFilK] = (error - prevError) / dt;
       dFilK++;
       if(dFilK == dFilLen) {
       dFilK = 0;
       }
       //Average history table
       derivative = 0;
       for(int k = 0; k < dFilLen; k++) {
       derivative += dHist[k];
       }
       derivative /= dFilLen
       */
	
      //YAW-Regler
      error[YAW] = (float)rcYawRate - gyroRate[YAW]; //hier wird auf die Winkelgeschwdg. geregelt
      pTerm[YAW] = error[YAW]*conf.KP[YAW];
      iSum[YAW] += error[YAW]*dt;
      iSum[YAW] = constrain(iSum[YAW],-50,50);
      iTerm[YAW] = iSum[YAW]*conf.KI[YAW];
      dTerm[YAW] = gyroRate[YAW]*conf.KD[YAW];
      
      //Mischen
	  axisPID[ROLL] = pTerm[ROLL] - dTerm[ROLL] + iTerm[ROLL];
        axisPID[PITCH] = pTerm[PITCH] - dTerm[PITCH] + iTerm[PITCH];
	  axisPID[YAW] = pTerm[YAW] - dTerm[YAW] + iTerm[YAW];
    
      //DEBUG
      debug[6] = axisPID[ROLL]/100;
      debug[7] = pTerm[ROLL]/100;
      debug[8] = dTerm[ROLL]/100;
      debug[9] = iTerm[ROLL]/100;
}