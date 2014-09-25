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

//Gibt die Anzahl der vergangenen Mikrosekunden seit dem Start zurück
uint32_t micros()
{
	return ((ms10 * 10000) + (TCE0_CNT << 1));
}

uint32_t millis()
{
      return micros()/1000;
}

ISR(TCE0_OVF_vect)
{
	ms10 += 1;	//Millisekunden in Aufloesung von 10ms
}