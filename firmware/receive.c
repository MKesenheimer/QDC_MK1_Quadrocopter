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

#define SPEKTRUM 1024
volatile uint8_t rcFrameComplete; // for serial rc receiver Spektrum
#define SPEK_MAX_CHANNEL 7
#define SPEK_FRAME_SIZE 16 //16
#if (SPEKTRUM == 1024)
  #define SPEK_CHAN_SHIFT  2       // Assumes 10 bit frames, that is 1024 mode.
  #define SPEK_CHAN_MASK   0x03    // Assumes 10 bit frames, that is 1024 mode.
#endif
#if (SPEKTRUM == 2048)
  #define SPEK_CHAN_SHIFT  3       // Assumes 11 bit frames, that is 2048 mode.
  #define SPEK_CHAN_MASK   0x07    // Assumes 11 bit frames, that is 2048 mode.
#endif
volatile uint8_t spekFrame[SPEK_FRAME_SIZE];

//für das Zeitmanagement muss die Funktion mikros() als Prototyp deklariert sein:
uint32_t micros();

uint16_t readRawRC(uint8_t chan) {
	uint16_t data;
	uint8_t oldSREG;
	oldSREG = SREG; cli();				// Let's disable interrupts

	static uint32_t spekChannelData[SPEK_MAX_CHANNEL];
	if (rcFrameComplete) {
		for (uint8_t b = 3; b < SPEK_FRAME_SIZE; b += 2) {
			uint8_t spekChannel = 0x0F & (spekFrame[b - 1] >> SPEK_CHAN_SHIFT);
			if (spekChannel < SPEK_MAX_CHANNEL) spekChannelData[spekChannel] = ((uint32_t)(spekFrame[b - 1] & SPEK_CHAN_MASK) << 8) + spekFrame[b];
		}
		rcFrameComplete = 0;
	}
	SREG = oldSREG; sei();				// Let's enable the interrupts
      
	static uint8_t spekRcChannelMap[SPEK_MAX_CHANNEL] = {1,2,3,0,4,5,6};
	if (chan >= SPEK_MAX_CHANNEL) {
		data = 1500;
      } else {
        #if (SPEKTRUM == 1024)
		data = 988 + spekChannelData[spekRcChannelMap[chan]];          // 1024 mode
        #endif
        #if (SPEKTRUM == 2048)
		data = 988 + (spekChannelData[spekRcChannelMap[chan]] >> 1);   // 2048 mode
        #endif
	}
	return data; // We return the value correctly copied when the IRQ's where disabled
}

void computeRC()
{
      static int16_t rcData4Values[8][4], rcDataMean[8];
      static uint8_t rc4ValuesIndex = 0;
      uint8_t chan,a;
      
      rc4ValuesIndex++;
      for (chan = 0; chan < 8; chan++) {
            rcData4Values[chan][rc4ValuesIndex%4] = readRawRC(chan);
            rcDataMean[chan] = 0;
            for (a=0;a<4;a++) rcDataMean[chan] += rcData4Values[chan][a];
            rcDataMean[chan]= (rcDataMean[chan]+2)/4;
            if ( rcDataMean[chan] < rcData[chan] -3)  rcData[chan] = rcDataMean[chan]+2;
            if ( rcDataMean[chan] > rcData[chan] +3)  rcData[chan] = rcDataMean[chan]-2;
            
            if (chan<YAW) { //rcData auf das neue Intervall [-500,500] mappen
                  rcAngle[chan] = constrain((int32_t) map((int32_t)RCMIN,(int32_t)RCMAX,(int32_t)RCANGLEMIN,(int32_t)(int32_t)RCANGLEMAX,(int32_t)rcData[chan]),RCANGLEMIN,RCANGLEMAX);
                  
                  if (chan == ROLL) {
                        rcAngle[chan] = -rcAngle[chan];
                  }
            }
            
            if (chan == YAW) {
                  rcYawRate = constrain((int32_t) map((int32_t)RCMIN,(int32_t)RCMAX,(int32_t)RCANGLEMIN,(int32_t)(int32_t)RCANGLEMAX,(int32_t)rcData[chan]),RCANGLEMIN,RCANGLEMAX);
            }
            
            if (chan==THROTTLE) {
                  rcThrottle = constrain((uint16_t) map((uint32_t)RCMIN,(uint32_t)RCMAX,(uint32_t)RCTHROTTLEMIN,(uint32_t)(uint32_t)RCTHROTTLEMAX,(uint32_t)rcData[THROTTLE]),RCTHROTTLEMIN,RCTHROTTLEMAX);
            }
      }
}

ISR(USARTD0_RXC_vect) {
	uint32_t spekTime;
	static uint32_t spekTimeLast, spekTimeInterval;
	static uint8_t  spekFramePosition;
	spekTime = micros();
	spekTimeInterval = spekTime - spekTimeLast;
	spekTimeLast = spekTime;
	if (spekTimeInterval > 5000) spekFramePosition = 0;		// alle 22 ms kommt ein neuer Frame, ein Frame dauert ~1,5 ms
	spekFrame[spekFramePosition] = USARTD0.DATA;
	if (spekFramePosition == SPEK_FRAME_SIZE - 1) {
		rcFrameComplete = 1;
      #ifdef FAILSAFE
            if(failsafeCnt > 20) failsafeCnt -= 20; else failsafeCnt = 0;   // clear FailSafe counter
      #endif
	} else {
		spekFramePosition++;
	}
}
