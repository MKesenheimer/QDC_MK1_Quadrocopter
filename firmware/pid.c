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
//P-Wert erhöhen bis unkontrollierte Oszillationen beginnen, dann solange verringern bis Oszillationen verschwinden
//I-Wert solange verändern, bis der Copter nicht mehr zum Sollwert zurückkehrt (fängt an zu driften), dann langsam erhöhen
//D-Wert erhöhen bis das Ausgleichen abrupter Änderungen aus der Gleichgewichtslage zu lange dauert, dann langsam erniedrigen

//Merke:
//langsame Oszillationen -> P-Wert niedriger, oder D-Wert größer, oder I-Wert niedriger
//schnelle Oszillationen (zwitschern) -> D-Wert niedriger
//Drift -> I-Wert erhöhen
//Kein Ausgleich schneller Änderungen -> D-Wert größer

//P: Proportional: Gegenverstärkung der Winkelgeschwindigkeit, regelt proportional zu einem Fehler
//I: Integral: Gegenverstärkung des Winkels, wenn der Fehler konstant bleibt, wird die Verstärkung so lange erhöht, bis eine Verbesserung zu verzeichnen ist
//D: Differential: Verstärkung der Winkelbeschleunigung, wird dieser Wert erhöht, regelt der Copter schneller auf seinen Soll-Wert zurück, der D-Wert "sagt den Regelwert voraus", je höher die Änderung des Fehlers ist, desto größer muss die Anpassung sein.

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
            iSum[angle] = constrain(iSum[angle],-50,50);
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
      iSum[YAW] = constrain(iSum[YAW],-100,100);
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

