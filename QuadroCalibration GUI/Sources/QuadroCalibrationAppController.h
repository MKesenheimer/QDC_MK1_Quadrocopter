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

#import <Foundation/Foundation.h>
#import "ORSSerialPort.h"
#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>

@class ORSSerialPortManager;

#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7)
@protocol NSUserNotificationCenterDelegate <NSObject>
@end
#endif

@interface QuadroCalibrationAppController : NSObject <ORSSerialPortDelegate, NSUserNotificationCenterDelegate, CPTPlotDataSource> {
    IBOutlet CPTGraphHostingView *hostView;
    IBOutlet NSPopUpButton *popUp;
    CPTXYGraph *graph;
    NSMutableArray *plotDataNick;
    NSMutableArray *plotDataRoll;
    NSMutableArray *plotDataP;
    NSMutableArray *plotDataI;
    NSMutableArray *plotDataD;
    NSInteger countPointsNR;
    NSInteger countPointsPID;
    NSInteger numberI, numberP, numberD;
    NSString *plotIndex;
    IBOutlet NSMatrix *plotState;       
}

- (IBAction)openOrClosePort:(id)sender;
- (IBAction)plot:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)clearPlot:(id)sender;
- (IBAction)popUpChange:(id)sender;
- (IBAction)plotStateChange:(id)sender;
- (IBAction)send:(id)sender;
- (IBAction)receive:(id)sender;
- (IBAction)reset:(id)sender;
- (void)sendFct;

@property (unsafe_unretained) IBOutlet NSButton *openCloseButton;
@property (unsafe_unretained) IBOutlet NSButton *plotButton;
@property (unsafe_unretained) IBOutlet NSButton *stopButton;
@property (unsafe_unretained) IBOutlet NSButton *sendButton;
@property (unsafe_unretained) IBOutlet NSButton *startMotorsButton;
@property (unsafe_unretained) IBOutlet NSButton *stopMotorsButton;
@property (unsafe_unretained) IBOutlet NSButton *resetButton;
@property (unsafe_unretained) IBOutlet NSButton *receiveButton;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldNick;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldRoll;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldPReceive;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldIReceive;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldDReceive;
@property (unsafe_unretained) IBOutlet NSSlider *nickSlider;
@property (unsafe_unretained) IBOutlet NSSlider *rollSlider;
@property (unsafe_unretained) IBOutlet NSSlider *pSliderValueReceive;
@property (unsafe_unretained) IBOutlet NSSlider *iSliderValueReceive;
@property (unsafe_unretained) IBOutlet NSSlider *dSliderValueReceive;

@property (unsafe_unretained) IBOutlet NSTextField *textFieldPRollSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldIRollSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldDRollSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldPRollReceive;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldIRollReceive;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldDRollReceive;

@property (unsafe_unretained) IBOutlet NSTextField *textFieldPPitchSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldIPitchSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldDPitchSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldPPitchReceive;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldIPitchReceive;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldDPitchReceive;

@property (unsafe_unretained) IBOutlet NSTextField *textFieldPYawSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldIYawSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldDYawSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldPYawReceive;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldIYawReceive;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldDYawReceive;

@property (unsafe_unretained) IBOutlet NSTextField *textFieldPPidlevelSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldIPidlevelSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldDPidlevelSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldPPidlevelReceive;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldIPidlevelReceive;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldDPidlevelReceive;

@property (unsafe_unretained) IBOutlet NSTextField *textFieldrcRateSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldrcRateReceive;

@property (unsafe_unretained) IBOutlet NSTextField *textFieldrcExpoSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldrcExpoReceive;

@property (unsafe_unretained) IBOutlet NSTextField *textFieldrollPitchRateSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldrollPitchRateReceive;

@property (unsafe_unretained) IBOutlet NSTextField *textFieldyawRateSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldyawRateReceive;

@property (unsafe_unretained) IBOutlet NSTextField *textFielddynThrPidSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFielddynThrPidReive;

@property (unsafe_unretained) IBOutlet NSTextField *textFieldthrMidSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldthrMidReceive;

@property (unsafe_unretained) IBOutlet NSTextField *textFieldthrExpoSend;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldthrExpoReceive;

@property (unsafe_unretained) IBOutlet NSTextField *textFieldangleTrim0Send;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldangleTrim0Receive;

@property (unsafe_unretained) IBOutlet NSTextField *textFieldangleTrim1Send;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldangleTrim1Receive;

@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
@property (nonatomic, strong) ORSSerialPort *serialPort;
@property (nonatomic, strong) NSArray *availableBaudRates;

@end
