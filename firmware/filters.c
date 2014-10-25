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

//Runs a complementary filter configured via float a
void first_order_comp_filter()
{
      //DEBUG
      compAngle[ROLL] = debug[0];
      compAngle[PITCH] = debug[1];
      
	compAngle[ROLL] = (float)(compAngle[ROLL] + gyroRate[ROLL]*dt)*ratio + accAngle[ROLL]*(1-ratio);
	compAngle[PITCH] = (float)(compAngle[PITCH] + gyroRate[PITCH]*dt)*ratio + accAngle[PITCH]*(1-ratio);
      
      //DEBUG
      debug[0] = compAngle[ROLL];
      debug[1] = compAngle[PITCH];
}

//Runs 2nd order complementary filter
void second_order_comp_filter() //Aeroquad, oder http://robottini.altervista.org/tag/complementary-filter
{
      //DEBUG
      compAngle[ROLL] = debug[2];
      compAngle[PITCH] = debug[3];
      
	filter_RollTerm[0] = (accAngle[ROLL] - compAngle[ROLL]) * timeConstant * timeConstant;
	filter_PitchTerm[0] = (accAngle[PITCH] - compAngle[PITCH]) * timeConstant * timeConstant;
  	filter_RollTerm[2] = (dt * filter_RollTerm[0]) + filter_RollTerm[2];
  	filter_PitchTerm[2] = (dt * filter_PitchTerm[0]) + filter_PitchTerm[2];
  	filter_RollTerm[1] = filter_RollTerm[2] + (accAngle[ROLL] - compAngle[ROLL]) * 2 * timeConstant + gyroRate[ROLL];
  	filter_PitchTerm[1] = filter_PitchTerm[2] + (accAngle[PITCH] - compAngle[PITCH]) * 2 * timeConstant + gyroRate[PITCH];
  	compAngle[ROLL] = (dt * filter_RollTerm[1]) + compAngle[ROLL];
  	compAngle[PITCH] = (dt * filter_PitchTerm[1]) + compAngle[PITCH];
      
      //DEBUG
      debug[2] = compAngle[ROLL];
      debug[3] = compAngle[PITCH];
}


// KasBot V1 - Kalman filter module, http://robottini.altervista.org/tag/complementary-filter
void kalman_filter()
{
      //DEBUG
      compAngle[ROLL] = debug[4];
      compAngle[PITCH] = debug[5];
      
      float y, S, K_0, K_1;
      
      //Filter für ROLL Achse
      compAngle[ROLL] += dt * (gyroRate[ROLL] - bias[ROLL]);
      P_00[ROLL] +=  - dt * (P_10[ROLL] + P_01[ROLL]) + Q_angle * dt;
      P_01[ROLL] +=  - dt * P_11[ROLL];
      P_10[ROLL] +=  - dt * P_11[ROLL];
      P_11[ROLL] +=  + Q_gyro * dt;
      
      y = accAngle[ROLL] - compAngle[ROLL];
      S = P_00[ROLL] + R_angle;
      K_0 = P_00[ROLL] / S;
      K_1 = P_10[ROLL] / S;
      
      compAngle[ROLL] +=  K_0 * y;
      bias[ROLL]  +=  K_1 * y;
      P_00[ROLL] -= K_0 * P_00[ROLL];
      P_01[ROLL] -= K_0 * P_01[ROLL];
      P_10[ROLL] -= K_1 * P_00[ROLL];
      P_11[ROLL] -= K_1 * P_01[ROLL];
      
      //Filter für PITCH Achse
      compAngle[PITCH] += dt * (gyroRate[PITCH] - bias[PITCH]);
      P_00[PITCH] +=  - dt * (P_10[PITCH] + P_01[PITCH]) + Q_angle * dt;
      P_01[PITCH] +=  - dt * P_11[PITCH];
      P_10[PITCH] +=  - dt * P_11[PITCH];
      P_11[PITCH] +=  + Q_gyro * dt;
      
      y = accAngle[PITCH] - compAngle[PITCH];
      S = P_00[PITCH] + R_angle;
      K_0 = P_00[PITCH] / S;
      K_1 = P_10[PITCH] / S;
      
      compAngle[PITCH] +=  K_0 * y;
      bias[PITCH]  +=  K_1 * y;
      P_00[PITCH] -= K_0 * P_00[PITCH];
      P_01[PITCH] -= K_0 * P_01[PITCH];
      P_10[PITCH] -= K_1 * P_00[PITCH];
      P_11[PITCH] -= K_1 * P_01[PITCH];
      
      //DEBUG
      debug[4] = compAngle[ROLL];
      debug[5] = compAngle[PITCH];
}