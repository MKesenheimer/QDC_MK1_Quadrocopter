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

// Scanner für config Werte
    //Zu empfangende String:
	//:P8[ROLL]:I8[ROLL]:D8[ROLL]:P8[PITCH]:I8[PITCH]:D8[PITCH]:P8[YAW]:I8[YAW]:D8[YAW]:P8[PIDLEVEL]:I8[PIDLEVEL]:D8[PIDLEVEL]
	//:rcRate8:rcExpo8:rollPitchRate:yawRate:dynThrPID:thrMid8:thrExpo8:angleTrim[0]:angleTrim[1]\r
    if ([string rangeOfString:@":"].location != NSNotFound) {
        //neue Möglichkeit: componentsSeperatedByString: (erzeugt ein StringArray, aus dem String, dessen Komponenten mit ':' getrennt sind.)
        /*
        NSArray *stringArray = [string componentsSeparatedByString:@":"];
        P8ROLL = [[stringArray objectAtIndex:0] intValue];
        I8ROLL = [[stringArray objectAtIndex:1] intValue];
        D8ROLL = [[stringArray objectAtIndex:2] intValue];
        P8PITCH = [[stringArray objectAtIndex:3] intValue];
        I8PITCH = [[stringArray objectAtIndex:4] intValue];
        D8PITCH = [[stringArray objectAtIndex:5] intValue];
        P8YAW = [[stringArray objectAtIndex:6] intValue];
        I8YAW = [[stringArray objectAtIndex:7] intValue];
        D8YAW= [[stringArray objectAtIndex:8] intValue];
        P8PIDLEVEL = [[stringArray objectAtIndex:9] intValue];
        I8PIDLEVEL = [[stringArray objectAtIndex:10] intValue];
        D8PIDLEVEL = [[stringArray objectAtIndex:11] intValue];
        rcRate8 = [[stringArray objectAtIndex:12] intValue];
        rcExpo8 = [[stringArray objectAtIndex:13] intValue];
        rollPitchRate = [[stringArray objectAtIndex:14] intValue];
        yawRate = [[stringArray objectAtIndex:15] intValue];
        dynThrPID = [[stringArray objectAtIndex:16] intValue];
        thrMid8 = [[stringArray objectAtIndex:17] intValue];
        thrExpo8 = [[stringArray objectAtIndex:18] intValue];
        angleTrim0 = [[stringArray objectAtIndex:19] intValue];
        angleTrim1 = [[stringArray objectAtIndex:20] intValue];
         */
        
        NSScanner *scanner = [NSScanner scannerWithString:string];
        NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"-0123456789"];
        NSCharacterSet *characters = [NSCharacterSet characterSetWithCharactersInString:@":"];
        
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strP8ROLL];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strI8ROLL];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strD8ROLL];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strP8PITCH];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strI8PITCH];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strD8PITCH];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strP8YAW];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strI8YAW];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strD8YAW];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strP8PIDLEVEL];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strI8PIDLEVEL];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strD8PIDLEVEL];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strrcRate8];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strrcExpo8];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strrollPitchRate];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&stryawRate];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strdynThrPID];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strthrMid8];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strthrExpo8];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strangleTrim0];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strangleTrim1];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        
        P8ROLL = [strP8ROLL intValue];
        I8ROLL = [strI8ROLL intValue];
        D8ROLL = [strD8ROLL intValue];
        P8PITCH = [strP8PITCH intValue];
        I8PITCH = [strI8PITCH intValue];
        D8PITCH = [strD8PITCH intValue];
        P8YAW = [strP8YAW intValue];
        I8YAW = [strI8YAW intValue];
        D8YAW = [strD8YAW intValue];
        P8PIDLEVEL = [strP8PIDLEVEL intValue];
        I8PIDLEVEL = [strI8PIDLEVEL intValue];
        D8PIDLEVEL = [strD8PIDLEVEL intValue];
        rcRate8 = [strrcRate8 intValue];
        rcExpo8 = [strrcExpo8 intValue];
        rollPitchRate = [strrollPitchRate intValue];
        yawRate = [stryawRate intValue];
        dynThrPID = [strdynThrPID intValue];
        thrMid8 = [strthrMid8 intValue];
        thrExpo8 = [strthrExpo8 intValue];
        angleTrim0 = [strangleTrim0 intValue];
        angleTrim1 = [strangleTrim1 intValue];
        
        [_textFieldPRollReceive setIntegerValue:P8ROLL];
        [_textFieldIRollReceive setIntegerValue:I8ROLL];
        [_textFieldDRollReceive setIntegerValue:D8ROLL];
        [_textFieldPPitchReceive setIntegerValue:P8PITCH];
        [_textFieldIPitchReceive setIntegerValue:I8PITCH];
        [_textFieldDPitchReceive setIntegerValue:D8PITCH];
        [_textFieldPYawReceive setIntegerValue:P8YAW];
        [_textFieldIYawReceive setIntegerValue:I8YAW];
        [_textFieldDYawReceive setIntegerValue:D8YAW];
        [_textFieldPPidlevelReceive setIntegerValue:P8PIDLEVEL];
        [_textFieldIPidlevelReceive setIntegerValue:I8PIDLEVEL];
        [_textFieldDPidlevelReceive setIntegerValue:D8PIDLEVEL];
        [_textFieldrcRateReceive setIntegerValue:rcRate8];
        [_textFieldrcExpoReceive setIntegerValue:rcExpo8];
        [_textFieldrollPitchRateReceive setIntegerValue:rollPitchRate];
        [_textFieldyawRateReceive setIntegerValue:yawRate];
        [_textFielddynThrPidReive setIntegerValue:dynThrPID];
        [_textFieldthrMidReceive setIntegerValue:thrMid8];
        [_textFieldthrExpoReceive setIntegerValue:thrExpo8];
        [_textFieldangleTrim0Receive setIntegerValue:angleTrim0];
        [_textFieldangleTrim0Receive setIntegerValue:angleTrim1];
    }
