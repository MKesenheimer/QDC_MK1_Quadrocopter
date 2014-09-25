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

#ifndef __WATCHDOG_H
#define __WATCHDOG_H

#include "avr_compiler.h"

// Defines

/*! \brief Check if Synchronization busy flag is set. */
#define WDT_IsSyncBusy() ( WDT.STATUS & WDT_SYNCBUSY_bm )
#define WDT_Reset()     asm("wdr")

// Prototypes
extern void WDT_EnableAndSetTimeout( void );
extern void WDT_Disable( void );

#endif // __WATCHDOG_H
