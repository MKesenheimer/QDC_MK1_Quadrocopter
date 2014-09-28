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
    //NSMutableArray *plotDataDBG; //hier werden die empfangenen Werte gespeichert
    //NSMutableArray *arrayPlotDataDBG; //dieses Array enthält plotDataDBG für insgesamt 10 Debug-Kanäle, d.h. [plotDataDBG1, plotDataDBG2, ...]
    
    NSMutableArray *plotDataDBG0;
    NSMutableArray *plotDataDBG1;
    NSMutableArray *plotDataDBG2;
    NSMutableArray *plotDataDBG3;
    NSMutableArray *plotDataDBG4;
    NSMutableArray *plotDataDBG5;
    NSMutableArray *plotDataDBG6;
    NSMutableArray *plotDataDBG7;
    NSMutableArray *plotDataDBG8;
    NSMutableArray *plotDataDBG9;
    
    NSInteger countPointsNR;
    NSInteger countPointsPID;
    NSInteger countPointsDBG;
    NSInteger numberI, numberP, numberD;
    NSInteger numberMotor1, numberMotor2, numberMotor3, numberMotor4;
    NSInteger numberDebug0, numberDebug1, numberDebug2, numberDebug3, numberDebug4, numberDebug5, numberDebug6, numberDebug7, numberDebug8, numberDebug9;
    NSString *plotIndex;
    IBOutlet NSMatrix *plotState;
    IBOutlet NSButton *checkDBG0;
    IBOutlet NSButton *checkDBG1;
    IBOutlet NSButton *checkDBG2;
    IBOutlet NSButton *checkDBG3;
    IBOutlet NSButton *checkDBG4;
    IBOutlet NSButton *checkDBG5;
    IBOutlet NSButton *checkDBG6;
    IBOutlet NSButton *checkDBG7;
    IBOutlet NSButton *checkDBG8;
    IBOutlet NSButton *checkDBG9;
    IBOutlet NSTextField *cycleTimeTextField;
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
- (IBAction)checkDBG0Change:(id)sender;
- (IBAction)checkDBG1Change:(id)sender;
- (IBAction)checkDBG2Change:(id)sender;
- (IBAction)checkDBG3Change:(id)sender;
- (IBAction)checkDBG4Change:(id)sender;
- (IBAction)checkDBG5Change:(id)sender;
- (IBAction)checkDBG6Change:(id)sender;
- (IBAction)checkDBG7Change:(id)sender;
- (IBAction)checkDBG8Change:(id)sender;
- (IBAction)checkDBG9Change:(id)sender;
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

@property (unsafe_unretained) IBOutlet NSTextField *textFieldangleTrim0Send;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldangleTrim0Receive;

@property (unsafe_unretained) IBOutlet NSTextField *textFieldangleTrim1Send;
@property (unsafe_unretained) IBOutlet NSTextField *textFieldangleTrim1Receive;

@property (unsafe_unretained) IBOutlet NSLevelIndicatorCell *levelMotor1;
@property (unsafe_unretained) IBOutlet NSLevelIndicatorCell *levelMotor2;
@property (unsafe_unretained) IBOutlet NSLevelIndicatorCell *levelMotor3;
@property (unsafe_unretained) IBOutlet NSLevelIndicatorCell *levelMotor4;

@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
@property (nonatomic, strong) ORSSerialPort *serialPort;
@property (nonatomic, strong) NSArray *availableBaudRates;

@end
