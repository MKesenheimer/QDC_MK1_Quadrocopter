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

#import "QuadroCalibrationAppController.h"
#import "ORSSerialPortManager.h"
#import <CorePlot/CorePlot.h>

@implementation QuadroCalibrationAppController

-(void)awakeFromNib
{
    [super awakeFromNib];
    plotDataNick = [NSMutableArray arrayWithCapacity:1000];
    plotDataRoll = [NSMutableArray arrayWithCapacity:1000];
    
    plotDataP = [NSMutableArray arrayWithCapacity:1000];
    plotDataI = [NSMutableArray arrayWithCapacity:1000];
    plotDataD = [NSMutableArray arrayWithCapacity:1000];
    
    countPointsNR = 0;
    countPointsPID = 0;
    numberP = 0;
    numberI = 0;
    numberD = 0;
    plotIndex = @"NickRoll"; //gibt an, welche Daten geplottet werden sollen
    [self createPlotNR];
    [popUp removeAllItems];
    [popUp addItemsWithTitles:[NSArray arrayWithObjects:[NSString stringWithFormat:@"Nick & Roll"], [NSString stringWithFormat:@"PIDROLL"], [NSString stringWithFormat:@"PIDPITCH"], [NSString stringWithFormat:@"PIDYAW"],[NSString stringWithFormat:@"DEBUG"], nil]];
    
    //TODO: Auch hier sollte sich das Programm die letzten Konfigurationswerte merken, 
    //so dass beim nächsten Starten des Programms die letzten eingegebenen Werte wieder da sind.
    [_textFieldPRollSend setIntValue:145];
    [_textFieldIRollSend setIntValue:130];
    [_textFieldDRollSend setIntValue:50];
    
    [_textFieldPPitchSend setIntValue:145];
    [_textFieldIPitchSend setIntValue:130];
    [_textFieldDPitchSend setIntValue:50];
    
    [_textFieldPPidlevelSend setIntValue:0];
    [_textFieldIPidlevelSend setIntValue:0];
    [_textFieldDPidlevelSend setIntValue:0];
    
    [_textFieldPYawSend setIntValue:90];
    [_textFieldIYawSend setIntValue:60];
    [_textFieldDYawSend setIntValue:0];

    [_textFieldangleTrim0Send setIntValue:0];
    [_textFieldangleTrim1Send setIntValue:0];
    
    [self.sendButton setEnabled: NO];
    [self.receiveButton setEnabled:NO];
    [self.startMotorsButton setEnabled: NO];
    [self.stopMotorsButton setEnabled:NO];
    [self.resetButton setEnabled:NO];
}

#pragma mark Plot Data Source Methods

-(void)createPlotNR
{
   // Create graph from theme
    graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:CGRectZero];
    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme]; //kCPTDarkGradientTheme
    [graph applyTheme:theme];
    hostView.hostedGraph = graph;
    
    //Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-50.f)
                                                    length:CPTDecimalFromFloat(100.f)];
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.f)
                                                    length:CPTDecimalFromFloat(300.0f)];
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromFloat(350);
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0"); //Offset
    x.minorTicksPerInterval       = 0;
    //x.labelFormatter            = ;
    
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength         = CPTDecimalFromFloat(10);
    y.minorTicksPerInterval       = 0;
    y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"25");
    
    //--------------------Nick and Roll------------------------------------------------------------------------------
    
    // ScatterPlot - Nick
    CPTScatterPlot *nickPlot = [[CPTScatterPlot alloc] init];
    nickPlot.identifier = @"NickDiagramm";
    
    CPTMutableLineStyle *lineStyleNick = [nickPlot.dataLineStyle mutableCopy];
    lineStyleNick.lineWidth = 1.f;
    lineStyleNick.lineColor = [CPTColor redColor];
    nickPlot.dataLineStyle = lineStyleNick;
    nickPlot.dataSource = self;
    
    //ScatterPlot - Roll
    CPTScatterPlot *rollPlot = [[CPTScatterPlot alloc] init];
    rollPlot.identifier = @"RollDiagramm";
    
    CPTMutableLineStyle *lineStyleRoll = [rollPlot.dataLineStyle mutableCopy];
    lineStyleRoll.lineWidth = 1.f;
    lineStyleRoll.lineColor = [CPTColor greenColor];
    rollPlot.dataLineStyle = lineStyleRoll;
    rollPlot.dataSource = self;
     
    //Adding the Plots
    [graph addPlot:nickPlot];
    [graph addPlot:rollPlot];
}

-(void)createPlotPID
{
    // Create graph from theme
    graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:CGRectZero];
    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme]; //kCPTDarkGradientTheme
    [graph applyTheme:theme];
    hostView.hostedGraph = graph;
    
    //Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-100.f)
                                                    length:CPTDecimalFromFloat(200.f)];
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.f)
                                                    length:CPTDecimalFromFloat(300.0f)];
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromFloat(350);
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0"); //Offset
    x.minorTicksPerInterval       = 0;
    //x.labelFormatter            = ;
    
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength         = CPTDecimalFromFloat(50);
    y.minorTicksPerInterval       = 0;
    y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"25");
    
    //--------------------------PID--------------------------------------------------------------------------------
    
    //ScatterPlot - P
    CPTScatterPlot *pPlot = [[CPTScatterPlot alloc] init];
    pPlot.identifier = @"pDiagramm";
    
    CPTMutableLineStyle *lineStyleP = [pPlot.dataLineStyle mutableCopy];
    lineStyleP.lineWidth = 1.f;
    lineStyleP.lineColor = [CPTColor blueColor];
    pPlot.dataLineStyle = lineStyleP;
    pPlot.dataSource = self;
    
    //ScatterPlot - I
    CPTScatterPlot *iPlot = [[CPTScatterPlot alloc] init];
    iPlot.identifier = @"iDiagramm";
    
    CPTMutableLineStyle *lineStyleI = [iPlot.dataLineStyle mutableCopy];
    lineStyleI.lineWidth = 1.f;
    lineStyleI.lineColor = [CPTColor greenColor];
    iPlot.dataLineStyle = lineStyleI;
    iPlot.dataSource = self;
    
    //ScatterPlot - D
    CPTScatterPlot *dPlot = [[CPTScatterPlot alloc] init];
    dPlot.identifier = @"dDiagramm";
    
    CPTMutableLineStyle *lineStyleD = [dPlot.dataLineStyle mutableCopy];
    lineStyleD.lineWidth = 1.f;
    lineStyleD.lineColor = [CPTColor yellowColor];
    dPlot.dataLineStyle = lineStyleD;
    dPlot.dataSource = self;
    
    [graph addPlot:pPlot];
    [graph addPlot:iPlot];
    [graph addPlot:dPlot];
}


-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    //--------------------Nick and Roll--------------------------------------------------------------------------------
    if ([(NSString *)plot.identifier isEqualToString:@"NickDiagramm"] && [plotIndex isEqualToString:@"NickRoll"]) {
        return plotDataNick.count;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"RollDiagramm"] && [plotIndex isEqualToString:@"NickRoll"]) {
        return plotDataRoll.count;
    }
    
    
    //--------------------------PID------------------------------------------------------------------------------------
    if ([(NSString *)plot.identifier isEqualToString:@"pDiagramm"] && [plotIndex isEqualToString:@"PID"]) {
        return plotDataP.count;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"iDiagramm"] && [plotIndex isEqualToString:@"PID"]) {
        return plotDataI.count;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"dDiagramm"] && [plotIndex isEqualToString:@"PID"]) {
        return plotDataD.count;
    }
    
    return nil;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    //--------------------Nick and Roll--------------------------------------------------------------------------------
    if ([(NSString *)plot.identifier isEqualToString:@"NickDiagramm"] && [plotIndex isEqualToString:@"NickRoll"]) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataNick objectAtIndex:index];
        }
        return nil;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"RollDiagramm"] && [plotIndex isEqualToString:@"NickRoll"]) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataRoll objectAtIndex:index];
        }
        return nil;
    }
    
    
    //--------------------------PID--------------------------------------------------------------------------------------
    if ([(NSString *)plot.identifier isEqualToString:@"pDiagramm"] && [plotIndex isEqualToString:@"PID"]) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataP objectAtIndex:index];
        }
        return nil;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"iDiagramm"] && [plotIndex isEqualToString:@"PID"]) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataI objectAtIndex:index];
        }
        return nil;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"dDiagramm"] && [plotIndex isEqualToString:@"PID"]) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataD objectAtIndex:index];
        }
        return nil;
    }
    
    return nil;
}

- (IBAction)plot:(id)sender
{
    
    if ([plotIndex isEqualToString:@"NickRoll"]) {
        char data = 0x41; //A
        NSMutableData *dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
        NSLog(@"zu sendender String: %@", dataToSend);
        [self.serialPort sendData:dataToSend];
        usleep(1000);
        [self createPlotNR];
    }
    
    if ([plotIndex isEqualToString:@"PID"] && ([popUp indexOfSelectedItem] == 1)) { //PIDROLL
        char data = 0x58; //X
        NSMutableData *dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
        NSLog(@"zu sendender String: %@", dataToSend);
        [self.serialPort sendData:dataToSend];
        usleep(1000);
        [self createPlotPID];
    }
    
    if ([plotIndex isEqualToString:@"PID"] && ([popUp indexOfSelectedItem] == 1)) { //PIDPITCH
        char data = 0x59; //Y
        NSMutableData *dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
        NSLog(@"zu sendender String: %@", dataToSend);
        [self.serialPort sendData:dataToSend];
        usleep(1000);
        [self createPlotPID];
    }
    
    if ([plotIndex isEqualToString:@"PID"] && ([popUp indexOfSelectedItem] == 1)) { //PIDYAW
        char data = 0x60; //Z
        NSMutableData *dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
        NSLog(@"zu sendender String: %@", dataToSend);
        [self.serialPort sendData:dataToSend];
        usleep(1000);
        [self createPlotPID];
    }
}

- (IBAction)stop:(id)sender
{
    char data = 0x43; //C
    NSMutableData *dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
}

- (IBAction)clearPlot:(id)sender
{
    [plotDataNick removeAllObjects];
    [plotDataRoll removeAllObjects];
    
    [plotDataP removeAllObjects];
    [plotDataI removeAllObjects];
    [plotDataD removeAllObjects];
    [graph reloadData];
}

#pragma Init

- (id)init
{
    self = [super init];
    if (self)
	{
        self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
		self.availableBaudRates = [NSArray arrayWithObjects: [NSNumber numberWithInteger:300], [NSNumber numberWithInteger:1200], [NSNumber numberWithInteger:2400], [NSNumber numberWithInteger:4800], [NSNumber numberWithInteger:9600], [NSNumber numberWithInteger:14400], [NSNumber numberWithInteger:19200], [NSNumber numberWithInteger:28800], [NSNumber numberWithInteger:38400], [NSNumber numberWithInteger:57600], [NSNumber numberWithInteger:115200], [NSNumber numberWithInteger:230400],
								   nil];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(serialPortsWereConnected:) name:ORSSerialPortsWereConnectedNotification object:nil];
		[nc addObserver:self selector:@selector(serialPortsWereDisconnected:) name:ORSSerialPortsWereDisconnectedNotification object:nil];

#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
		[[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
#endif
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions
- (IBAction)receive:(id)sender
{
      //QDC aufforden die Config Werte zu senden
      char identifier = 0x44; //D
      NSMutableData *dataToSend = [NSMutableData dataWithBytes:&identifier length:sizeof(identifier)];
      NSLog(@"zu sendender String: %@", dataToSend);
      [self.serialPort sendData:dataToSend];
      //usleep(1000);
}

- (IBAction)send:(id)sender
{
    [self sendFct];
    //QDC aufforden die Config Werte zu senden
    char identifier = 0x44; //D
    NSMutableData *dataToSend = [NSMutableData dataWithBytes:&identifier length:sizeof(identifier)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    //usleep(1000);
}

- (IBAction)startMotors:(id)sender {
    char identifier = 0x4d; //M
    NSMutableData *dataToSend = [NSMutableData dataWithBytes:&identifier length:sizeof(identifier)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
}

- (IBAction)stopMotors:(id)sender {
    char identifier = 0x4e; //N
    NSMutableData *dataToSend = [NSMutableData dataWithBytes:&identifier length:sizeof(identifier)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
}

- (IBAction)reset:(id)sender
{
    //QDC Initialisieren
    char identifier = 0x52; //R
    NSMutableData *dataToSend = [NSMutableData dataWithBytes:&identifier length:sizeof(identifier)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
}

- (void)sendFct
{
    //TODO: Das gesamte Programm mit dem Einsatz von Funktion eleganter schreiben!
    //Da NSData-Werte little-Endian formatiert sind,
    //müssen die bytes einmal getauscht werden um in der
    //richtigen Reihenfolge zu sein -> CFSwapInt16
    
    //Übersicht der Identifier:
    // S - Datenpaket start
    // E - Datenpaket Ende
    // A - Dem QDC den Befehl geben Nick und Rollwerte zu senden
    // X - Die PIDROLL Werte senden
    // Y - Die PIDPITCH Werte senden
    // Z - Die PIDYAW Werte senden
    // C - QDC stop
    // D - QDC aufforden die Config Werte zu senden
    // E - Reset/Init
    
    //Senden des QDC anhalten
    char identifier = 0x43; //C
    NSMutableData *dataToSend = [NSMutableData dataWithBytes:&identifier length:sizeof(identifier)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    
    //QDC auf Empfang schalten
    identifier = 0x53; //S
    dataToSend = [NSMutableData dataWithBytes:&identifier length:sizeof(identifier)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);

    //CFSwapInt16()
    //PRoll Wert senden
    uint8 data = [self.textFieldPRollSend intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    //IRoll Wert senden
    data = [self.textFieldIRollSend intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    //DRoll Wert senden
    data = [self.textFieldDRollSend intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    
    //PPitch Wert senden
    data = [self.textFieldPPitchSend intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    //IPitch Wert senden
    data = [self.textFieldIPitchSend intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    //dPitch Wert senden
    data = [self.textFieldDPitchSend intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    
    //PYaw Wert senden
    data = [self.textFieldPYawSend intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    //IYaw Wert senden
    data = [self.textFieldIYawSend intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    //dYaw Wert senden
    data = [self.textFieldDYawSend intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    
    //PPidlevel Wert senden
    data = [self.textFieldPPidlevelSend intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    //IPidlevel Wert senden
    data = [self.textFieldIPidlevelSend intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    //dPidlevel Wert senden
    data = [self.textFieldDPidlevelSend intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    
    //angleTrim0 Wert senden
    data = [self.textFieldangleTrim0Send intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    //angleTrim1 Wert senden
    data = [self.textFieldangleTrim1Send intValue];
    dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
    NSLog(@"zu sendender String: %@", dataToSend);
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    
    //QDC Ende des Datenpakets mitteilen
    identifier = 0x45; //E
    dataToSend = [NSMutableData dataWithBytes:&identifier length:sizeof(identifier)];
    [self.serialPort sendData:dataToSend];
    usleep(1000);
    
    //a P8[ROLL] a I8[ROLL] a D8[ROLL] \r
    //b P8[PITCH] b I8[PITCH] b D8[PITCH] \r
    //c P8[YAW] c I8[YAW] c D8[YAW] \r
    //d P8[PIDLEVEL] d I8[PIDLEVEL] d D8[PIDLEVEL] \r
    //e rcRate8 e rollPitchRate e yawRate e rcExpo8 \r
    //f dynThrPID f thrMid8 f thrExpo8 \r
    //g angleTrim[0] g angleTrim[1] \r
    
    /*
    //Senden des QDC wieder einschalten
    if ([popUp indexOfSelectedItem] == 0) { //Nick und Roll Diagramm ausgewählt
        plotIndex = @"NickRoll";
        identifier = 0x41; //A
        dataToSend = [NSMutableData dataWithBytes:&identifier length:sizeof(identifier)];
        [self.serialPort sendData:dataToSend];
        usleep(1000);
    }
    
    if ([popUp indexOfSelectedItem] == 1) { //PIDROLL Diagramm ausgewählt
        plotIndex = @"PID";
        identifier = 0x58; //X
        dataToSend = [NSMutableData dataWithBytes:&identifier length:sizeof(identifier)];
        [self.serialPort sendData:dataToSend];
        usleep(1000);
    }
     
     if ([popUp indexOfSelectedItem] == 1) { //PIDPITCH Diagramm ausgewählt
     plotIndex = @"PID";
     identifier = 0x59; //Y
     dataToSend = [NSMutableData dataWithBytes:&identifier length:sizeof(identifier)];
     [self.serialPort sendData:dataToSend];
     usleep(1000);
     }
     
     if ([popUp indexOfSelectedItem] == 1) { //PIDYAW Diagramm ausgewählt
     plotIndex = @"PID";
     identifier = 0x60; //Z
     dataToSend = [NSMutableData dataWithBytes:&identifier length:sizeof(identifier)];
     [self.serialPort sendData:dataToSend];
     usleep(1000);
     }
     */
}

- (IBAction)openOrClosePort:(id)sender
{
	self.serialPort.isOpen ? [self.serialPort close] : [self.serialPort open];
}

- (IBAction)popUpChange:(id)sender
{    
    if ([popUp indexOfSelectedItem] == 0) { //Nick und Roll Diagramm ausgewählt
        plotIndex = @"NickRoll";
        char data = 0x41; //A
        NSMutableData *dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
        NSLog(@"zu sendender String: %@", dataToSend);
        [self.serialPort sendData:dataToSend];
        usleep(1000);
        [plotDataNick removeAllObjects];
        [plotDataRoll removeAllObjects];
        [self createPlotNR];
    }
    
    if ([popUp indexOfSelectedItem] == 1) { //PIDROLL Diagramm ausgewählt
        plotIndex = @"PID";
        char data = 0x58; //X
        NSMutableData *dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
        NSLog(@"zu sendender String: %@", dataToSend);
        [self.serialPort sendData:dataToSend];
        usleep(1000);
        [plotDataP removeAllObjects];
        [plotDataI removeAllObjects];
        [plotDataD removeAllObjects];
        [self createPlotNR];
        [self createPlotPID];
    }
    
    if ([popUp indexOfSelectedItem] == 2) { //PIDPITCH Diagramm ausgewählt
        plotIndex = @"PID";
        char data = 0x59; //Y
        NSMutableData *dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
        NSLog(@"zu sendender String: %@", dataToSend);
        [self.serialPort sendData:dataToSend];
        usleep(1000);
        [plotDataP removeAllObjects];
        [plotDataI removeAllObjects];
        [plotDataD removeAllObjects];
        [self createPlotNR];
        [self createPlotPID];
    }
    
    if ([popUp indexOfSelectedItem] == 3) { //PIDYAW Diagramm ausgewählt
        plotIndex = @"PID";
        char data = 0x60; //Z
        NSMutableData *dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
        NSLog(@"zu sendender String: %@", dataToSend);
        [self.serialPort sendData:dataToSend];
        usleep(1000);
        [plotDataP removeAllObjects];
        [plotDataI removeAllObjects];
        [plotDataD removeAllObjects];
        [self createPlotNR];
        [self createPlotPID];
    }
}

- (IBAction)plotStateChange:(id)sender
{
    [plotDataNick removeAllObjects];
    [plotDataRoll removeAllObjects];
    
    [plotDataP removeAllObjects];
    [plotDataI removeAllObjects];
    [plotDataD removeAllObjects];
    [graph reloadData];
}

#pragma mark - AppDelegate Methods

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
	self.openCloseButton.title = @"Close";
    [self.sendButton setEnabled:YES];
	[self.receiveButton setEnabled:YES];
	[self.startMotorsButton setEnabled: YES];
    [self.stopMotorsButton setEnabled:YES];
    [self.resetButton setEnabled:YES];
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
	self.openCloseButton.title = @"Open";
    [self.sendButton setEnabled:NO];
	[self.receiveButton setEnabled:NO];
	[self.startMotorsButton setEnabled: NO];
    [self.stopMotorsButton setEnabled:NO];
    [self.resetButton setEnabled:NO];
}

//SCANNER
- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSScanner *scanner = [NSScanner scannerWithString:string];
    NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"-0123456789"];
    
    if ([string length] == 0) return;
	NSLog(@"eingelesener String: %@", string);

    // Intermediate
    NSString *nick;
    NSString *roll;
    NSString *d;
    NSString *i;
    NSString *p;

    // Scanner für Winkelwerte
    if ([string rangeOfString:@","].location != NSNotFound) {
	NSCharacterSet *characters = [NSCharacterSet characterSetWithCharactersInString:@","];
        //Der vom Arduino eingelesene String hat folgende Form für Winkelwerte: ,-123,456\n
        // Lösche das Semikolon -> string = -123,456
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        // Sammle die Zahlen auf -> nick = -123
        [scanner scanCharactersFromSet:numbers intoString:&nick];
        // Lösche die gerade gelesene Zahlen -> string = ,456
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];
        // Lösche das Komma -> string = 456
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        // Sammle die Zahlen auf -> roll = 456
        [scanner scanCharactersFromSet:numbers intoString:&roll];
        
        float numberNick = [nick floatValue]/10;
        float numberRoll = [roll floatValue]/10;
        
        [_nickSlider setFloatValue:numberNick];
        [_rollSlider setFloatValue:numberRoll];
        [_textFieldNick setIntValue:numberNick];
        [_textFieldRoll setIntValue:numberRoll];
        
        if (countPointsNR >= 0) { //Nur jeden x. Wert plotten
            [plotDataNick addObject:[NSDecimalNumber numberWithFloat:numberNick]];
            [plotDataRoll addObject:[NSDecimalNumber numberWithFloat:numberRoll]];
            countPointsNR = 0;
        }
        countPointsNR++;
        
        if ([plotDataNick count] >= 300) {
            if ([[plotState selectedCell] tag] == 1) {
                [plotDataNick removeObjectAtIndex:0];
                [plotDataRoll removeObjectAtIndex:0];
            }
            
            if ([[plotState selectedCell] tag] == 0) {
                [plotDataNick removeAllObjects];
                [plotDataRoll removeAllObjects];
            }
        }
        
        [graph reloadData];
    }
    
    // Scanner für Reglerwerte
    if ([string rangeOfString:@"."].location != NSNotFound) {
        //Der vom Arduino eingelesene String hat folgende Form für Reglerwerte: .-123.456.789\n
	NSCharacterSet *characters = [NSCharacterSet characterSetWithCharactersInString:@"."];

        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&p];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];

        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&i];
        [scanner scanUpToCharactersFromSet:characters intoString:NULL];

        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&d];
        
        numberD = [d floatValue];
        numberI = [i floatValue];
        numberP = [p floatValue];
        
        //NSLog(@"PID Werte sortiert.");
       
        [_textFieldDReceive setIntegerValue:numberD];
        [_textFieldIReceive setIntegerValue:numberI];
        [_textFieldPReceive setIntegerValue:numberP];
        [_dSliderValueReceive setFloatValue:numberD];
        [_iSliderValueReceive setFloatValue:numberI];
        [_pSliderValueReceive setFloatValue:numberP];
        
        if (countPointsPID >= 0) { //Nur jeden x. Wert plotten
            [plotDataP addObject:[NSDecimalNumber numberWithFloat:numberP]];
            [plotDataI addObject:[NSDecimalNumber numberWithFloat:numberI]];
            [plotDataD addObject:[NSDecimalNumber numberWithFloat:numberD]];
            countPointsPID = 0;
        }
        countPointsPID++;
        
        if ([plotDataP count] >= 300) {
            if ([[plotState selectedCell] tag] == 1) {
                [plotDataP removeObjectAtIndex:0];
                [plotDataI removeObjectAtIndex:0];
                [plotDataD removeObjectAtIndex:0];
            }
            
            if ([[plotState selectedCell] tag] == 0) {
                [plotDataP removeAllObjects];
                [plotDataI removeAllObjects];
                [plotDataD removeAllObjects];
            }
        }
        
        [graph reloadData];
    }
    
    // Scanner für config Werte   
    NSInteger P8ROLL;
    NSInteger I8ROLL;
    NSInteger D8ROLL;
    NSInteger P8PITCH;
    NSInteger I8PITCH;
    NSInteger D8PITCH;
    NSInteger P8YAW;
    NSInteger I8YAW;
    NSInteger D8YAW;
    NSInteger P8PIDLEVEL;
    NSInteger I8PIDLEVEL;
    NSInteger D8PIDLEVEL;
    NSInteger angleTrim0;
    NSInteger angleTrim1;
    
    NSString *strP8ROLL;
    NSString *strI8ROLL;
    NSString *strD8ROLL;
    NSString *strP8PITCH;
    NSString *strI8PITCH;
    NSString *strD8PITCH;
    NSString *strP8YAW;
    NSString *strI8YAW;
    NSString *strD8YAW;
    NSString *strP8PIDLEVEL;
    NSString *strI8PIDLEVEL;
    NSString *strD8PIDLEVEL;
    NSString *strangleTrim0;
    NSString *strangleTrim1;
    
    //der empfangene String hat folgende Form: (die Buchstaben dienen als Identifier der Wertepaare)
    //a P8[ROLL] a I8[ROLL] a D8[ROLL] \r
    //b P8[PITCH] b I8[PITCH] b D8[PITCH] \r
    //c P8[YAW] c I8[YAW] c D8[YAW] \r
    //d P8[PIDLEVEL] d I8[PIDLEVEL] d D8[PIDLEVEL] \r
    //e rcRate8 e rollPitchRate e yawRate e rcExpo8 \r
    //f dynThrPID f thrMid8 f thrExpo8 \r
    //g angleTrim[0] g angleTrim[1] \r

    //TODO: Das gesamte Programm mit dem Einsatz von Funktion eleganter schreiben!

    if ([string rangeOfString:@"a"].location != NSNotFound) {
        //a P8[ROLL] a I8[ROLL] a D8[ROLL] \r
        NSCharacterSet *achar = [NSCharacterSet characterSetWithCharactersInString:@"a"];

        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strP8ROLL];
        [scanner scanUpToCharactersFromSet:achar intoString:NULL];

        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strI8ROLL];
        [scanner scanUpToCharactersFromSet:achar intoString:NULL];

        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&strD8ROLL];
        
        P8ROLL = [strP8ROLL intValue];
        I8ROLL = [strI8ROLL intValue];
        D8ROLL = [strD8ROLL intValue];

        [_textFieldPRollReceive setIntegerValue:P8ROLL];
        [_textFieldIRollReceive setIntegerValue:I8ROLL];
        [_textFieldDRollReceive setIntegerValue:D8ROLL];
   }

   if ([string rangeOfString:@"b"].location != NSNotFound) {
       //b P8[PITCH] b I8[PITCH] b D8[PITCH] \r
       NSCharacterSet *bchar = [NSCharacterSet characterSetWithCharactersInString:@"b"];

       [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
       [scanner scanCharactersFromSet:numbers intoString:&strP8PITCH];
       [scanner scanUpToCharactersFromSet:bchar intoString:NULL];

       [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
       [scanner scanCharactersFromSet:numbers intoString:&strI8PITCH];
       [scanner scanUpToCharactersFromSet:bchar intoString:NULL];

       [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
       [scanner scanCharactersFromSet:numbers intoString:&strD8PITCH];

       P8PITCH = [strP8PITCH intValue];
       I8PITCH = [strI8PITCH intValue];
       D8PITCH = [strD8PITCH intValue];
	
       [_textFieldPPitchReceive setIntegerValue:P8PITCH];
       [_textFieldIPitchReceive setIntegerValue:I8PITCH];
       [_textFieldDPitchReceive setIntegerValue:D8PITCH];
   }

   if ([string rangeOfString:@"c"].location != NSNotFound) {
       //c P8[YAW] c I8[YAW] c D8[YAW] \r
       NSCharacterSet *cchar = [NSCharacterSet characterSetWithCharactersInString:@"c"];

       [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
       [scanner scanCharactersFromSet:numbers intoString:&strP8YAW];
       [scanner scanUpToCharactersFromSet:cchar intoString:NULL];

       [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
       [scanner scanCharactersFromSet:numbers intoString:&strI8YAW];
       [scanner scanUpToCharactersFromSet:cchar intoString:NULL];

       [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
       [scanner scanCharactersFromSet:numbers intoString:&strD8YAW];

       P8YAW = [strP8YAW intValue];
       I8YAW = [strI8YAW intValue];
       D8YAW = [strD8YAW intValue];

       [_textFieldPYawReceive setIntegerValue:P8YAW];
       [_textFieldIYawReceive setIntegerValue:I8YAW];
       [_textFieldDYawReceive setIntegerValue:D8YAW];
   }

   if ([string rangeOfString:@"d"].location != NSNotFound) {
       //d P8[PIDLEVEL] d I8[PIDLEVEL] d D8[PIDLEVEL] \r
       NSCharacterSet *dchar = [NSCharacterSet characterSetWithCharactersInString:@"d"];

       [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
       [scanner scanCharactersFromSet:numbers intoString:&strP8PIDLEVEL];
       [scanner scanUpToCharactersFromSet:dchar intoString:NULL];

       [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
       [scanner scanCharactersFromSet:numbers intoString:&strI8PIDLEVEL];
       [scanner scanUpToCharactersFromSet:dchar intoString:NULL];

       [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
       [scanner scanCharactersFromSet:numbers intoString:&strD8PIDLEVEL];

       P8PIDLEVEL = [strP8PIDLEVEL intValue];
       I8PIDLEVEL = [strI8PIDLEVEL intValue];
       D8PIDLEVEL = [strD8PIDLEVEL intValue];

       [_textFieldPPidlevelReceive setIntegerValue:P8PIDLEVEL];
       [_textFieldIPidlevelReceive setIntegerValue:I8PIDLEVEL];
       [_textFieldDPidlevelReceive setIntegerValue:D8PIDLEVEL];

   }

   if ([string rangeOfString:@"g"].location != NSNotFound) {
       //g angleTrim[0] g angleTrim[1] \r
       NSCharacterSet *gchar = [NSCharacterSet characterSetWithCharactersInString:@"g"];
        
       [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
       [scanner scanCharactersFromSet:numbers intoString:&strangleTrim0];
       [scanner scanUpToCharactersFromSet:gchar intoString:NULL];
        
       [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
       [scanner scanCharactersFromSet:numbers intoString:&strangleTrim1];
       
       angleTrim0 = [strangleTrim0 intValue];
       angleTrim1 = [strangleTrim1 intValue];

       [_textFieldangleTrim0Receive setIntegerValue:angleTrim0];
       [_textFieldangleTrim1Receive setIntegerValue:angleTrim1];
    }

}

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort;
{
	// After a serial port is removed from the system, it is invalid and we must discard any references to it
	self.serialPort = nil;
	self.openCloseButton.title = @"Open";
}

- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error
{
	NSLog(@"Serial port %@ encountered an error: %@", serialPort, error);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, object, keyPath);
	NSLog(@"Change dictionary: %@", change);
}

#pragma mark - NSUserNotificationCenterDelegate

#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[center removeDeliveredNotification:notification];
	});
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
	return YES;
}

#endif

#pragma mark - Notifications

- (void)serialPortsWereConnected:(NSNotification *)notification
{
	NSArray *connectedPorts = [[notification userInfo] objectForKey:ORSConnectedSerialPortsKey];
	NSLog(@"Ports were connected: %@", connectedPorts);
	[self postUserNotificationForConnectedPorts:connectedPorts];
}

- (void)serialPortsWereDisconnected:(NSNotification *)notification
{
	NSArray *disconnectedPorts = [[notification userInfo] objectForKey:ORSDisconnectedSerialPortsKey];
	NSLog(@"Ports were disconnected: %@", disconnectedPorts);
	[self postUserNotificationForDisconnectedPorts:disconnectedPorts];
	
}

- (void)postUserNotificationForConnectedPorts:(NSArray *)connectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
	if (!NSClassFromString(@"NSUserNotificationCenter")) return;
	
	NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
	for (ORSSerialPort *port in connectedPorts)
	{
		NSUserNotification *userNote = [[NSUserNotification alloc] init];
		userNote.title = NSLocalizedString(@"Serial Port Connected", @"Serial Port Connected");
		NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was connected to your Mac.", @"Serial port connected user notification informative text");
		userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
		userNote.soundName = nil;
		[unc deliverNotification:userNote];
	}
#endif
}

- (void)postUserNotificationForDisconnectedPorts:(NSArray *)disconnectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
	if (!NSClassFromString(@"NSUserNotificationCenter")) return;
	
	NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
	for (ORSSerialPort *port in disconnectedPorts)
	{
		NSUserNotification *userNote = [[NSUserNotification alloc] init];
		userNote.title = NSLocalizedString(@"Serial Port Disconnected", @"Serial Port Disconnected");
		NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was disconnected from your Mac.", @"Serial port disconnected user notification informative text");
		userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
		userNote.soundName = nil;
		[unc deliverNotification:userNote];
	}
#endif
}


#pragma mark - Properties

@synthesize openCloseButton = _openCloseButton;

@synthesize serialPortManager = _serialPortManager;
- (void)setSerialPortManager:(ORSSerialPortManager *)manager
{
	if (manager != _serialPortManager)
	{
		[_serialPortManager removeObserver:self forKeyPath:@"availablePorts"];
		_serialPortManager = manager;
		NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
		[_serialPortManager addObserver:self forKeyPath:@"availablePorts" options:options context:NULL];
	}
}

@synthesize serialPort = _serialPort;
- (void)setSerialPort:(ORSSerialPort *)port
{
	if (port != _serialPort)
	{
		[_serialPort close];
		_serialPort.delegate = nil;
		
		_serialPort = port;
		
		_serialPort.delegate = self;
	}
}

@synthesize availableBaudRates = _availableBaudRates;

@end