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

void ledThrottlePattern() {
    if (rcThrottle < 200) {
        blinkleds(1);
    }
    if (rcThrottle >= 200) {
        blinkleds(0);
    }
}