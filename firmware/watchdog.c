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

#include "watchdog.h"

#ifdef __AVR_XMEGA__

void WDT_EnableAndSetTimeout( void )
{
    uint8_t temp = WDT_ENABLE_bm | WDT_CEN_bm | WATCHDOG_TIMEOUT;
    CCP = CCP_IOREG_gc;
    WDT.CTRL = temp;
    
    /* Wait for WD to synchronize with new settings. */
    while(WDT_IsSyncBusy());
}

void WDT_Disable( void )
{
    uint8_t temp = (WDT.CTRL & ~WDT_ENABLE_bm) | WDT_CEN_bm;
    CCP = CCP_IOREG_gc;
    WDT.CTRL = temp;
}

#endif // __AVR_XMEGA__