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
    plotDataNick = [NSMutableArray arrayWithCapacity:1000]; //[[NSMutableArray alloc]init];
    plotDataRoll = [NSMutableArray arrayWithCapacity:1000];
    
    plotDataP = [NSMutableArray arrayWithCapacity:1000];
    plotDataI = [NSMutableArray arrayWithCapacity:1000];
    plotDataD = [NSMutableArray arrayWithCapacity:1000];
    
    //plotDataDBG = [NSMutableArray arrayWithCapacity:1000]; //hier werden die empfangenen Werte gespeichert (history)
    //arrayPlotDataDBG = [NSMutableArray arrayWithCapacity:10]; //dieses Array enthält plotDataDBG für insgesamt 10 Debug-Kanäle, d.h. [plotDataDBG1, plotDataDBG2, ...]
    
    plotDataDBG0 = [NSMutableArray arrayWithCapacity:1000];
    plotDataDBG1 = [NSMutableArray arrayWithCapacity:1000];
    plotDataDBG2 = [NSMutableArray arrayWithCapacity:1000];
    plotDataDBG3 = [NSMutableArray arrayWithCapacity:1000];
    plotDataDBG4 = [NSMutableArray arrayWithCapacity:1000];
    plotDataDBG5 = [NSMutableArray arrayWithCapacity:1000];
    plotDataDBG6 = [NSMutableArray arrayWithCapacity:1000];
    plotDataDBG7 = [NSMutableArray arrayWithCapacity:1000];
    plotDataDBG8 = [NSMutableArray arrayWithCapacity:1000];
    plotDataDBG9 = [NSMutableArray arrayWithCapacity:1000];
    
    countPointsNR = 0;
    countPointsPID = 0;
    countPointsDBG = 0;
    
    numberP = 0;
    numberI = 0;
    numberD = 0;
    
    numberMotor1 = 0;
    numberMotor2 = 0;
    numberMotor3 = 0;
    numberMotor4 = 0;
    
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
      
    [_levelMotor1 setIntValue:0];
    [_levelMotor2 setIntValue:0];
    [_levelMotor3 setIntValue:0];
    [_levelMotor4 setIntValue:0];
    
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

-(void)createPlotDBG
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
    
    //--------------------------DBG--------------------------------------------------------------------------------
    
    if ([checkDBG0 state] == NSOnState) {
        //ScatterPlot - DBG0
        CPTScatterPlot *d0Plot = [[CPTScatterPlot alloc] init];
        d0Plot.identifier = @"d0Diagramm";
        CPTMutableLineStyle *lineStyleD0 = [d0Plot.dataLineStyle mutableCopy];
        lineStyleD0.lineWidth = 1.f;
        lineStyleD0.lineColor = [CPTColor greenColor];
        d0Plot.dataLineStyle = lineStyleD0;
        d0Plot.dataSource = self;
        
        [graph addPlot:d0Plot];
    }
    
    if ([checkDBG1 state] == NSOnState) {
        //ScatterPlot - DBG1
        CPTScatterPlot *d1Plot = [[CPTScatterPlot alloc] init];
        d1Plot.identifier = @"d1Diagramm";
        CPTMutableLineStyle *lineStyleD1 = [d1Plot.dataLineStyle mutableCopy];
        lineStyleD1.lineWidth = 1.f;
        lineStyleD1.lineColor = [CPTColor blueColor];
        d1Plot.dataLineStyle = lineStyleD1;
        d1Plot.dataSource = self;
        
        [graph addPlot:d1Plot];
    }
    
    if ([checkDBG2 state] == NSOnState) {
        //ScatterPlot - DBG2
        CPTScatterPlot *d2Plot = [[CPTScatterPlot alloc] init];
        d2Plot.identifier = @"d2Diagramm";
        CPTMutableLineStyle *lineStyleD2 = [d2Plot.dataLineStyle mutableCopy];
        lineStyleD2.lineWidth = 1.f;
        lineStyleD2.lineColor = [CPTColor redColor];
        d2Plot.dataLineStyle = lineStyleD2;
        d2Plot.dataSource = self;
        
        [graph addPlot:d2Plot];
    }

    if ([checkDBG3 state] == NSOnState) {
        //ScatterPlot - DBG3
        CPTScatterPlot *d3Plot = [[CPTScatterPlot alloc] init];
        d3Plot.identifier = @"d3Diagramm";
        CPTMutableLineStyle *lineStyleD3 = [d3Plot.dataLineStyle mutableCopy];
        lineStyleD3.lineWidth = 1.f;
        lineStyleD3.lineColor = [CPTColor yellowColor];
        d3Plot.dataLineStyle = lineStyleD3;
        d3Plot.dataSource = self;
        
        [graph addPlot:d3Plot];
    }
    
    if ([checkDBG4 state] == NSOnState) {
        //ScatterPlot - DBG4
        CPTScatterPlot *d4Plot = [[CPTScatterPlot alloc] init];
        d4Plot.identifier = @"d4Diagramm";
        CPTMutableLineStyle *lineStyleD4 = [d4Plot.dataLineStyle mutableCopy];
        lineStyleD4.lineWidth = 1.f;
        lineStyleD4.lineColor = [CPTColor purpleColor];
        d4Plot.dataLineStyle = lineStyleD4;
        d4Plot.dataSource = self;
        
        [graph addPlot:d4Plot];
    }
    
    if ([checkDBG5 state] == NSOnState) {
        //ScatterPlot - DBG5
        CPTScatterPlot *d5Plot = [[CPTScatterPlot alloc] init];
        d5Plot.identifier = @"d5Diagramm";
        CPTMutableLineStyle *lineStyleD5 = [d5Plot.dataLineStyle mutableCopy];
        lineStyleD5.lineWidth = 1.f;
        lineStyleD5.lineColor = [CPTColor blackColor];
        d5Plot.dataLineStyle = lineStyleD5;
        d5Plot.dataSource = self;
        
        [graph addPlot:d5Plot];
    }
    
    if ([checkDBG6 state] == NSOnState) {
        //ScatterPlot - DBG6
        CPTScatterPlot *d6Plot = [[CPTScatterPlot alloc] init];
        d6Plot.identifier = @"d6Diagramm";
        CPTMutableLineStyle *lineStyleD6 = [d6Plot.dataLineStyle mutableCopy];
        lineStyleD6.lineWidth = 1.f;
        lineStyleD6.lineColor = [CPTColor grayColor];
        d6Plot.dataLineStyle = lineStyleD6;
        d6Plot.dataSource = self;
        
        [graph addPlot:d6Plot];
    }
    
    if ([checkDBG7 state] == NSOnState) {
        //ScatterPlot - DBG7
        CPTScatterPlot *d7Plot = [[CPTScatterPlot alloc] init];
        d7Plot.identifier = @"d7Diagramm";
        CPTMutableLineStyle *lineStyleD7 = [d7Plot.dataLineStyle mutableCopy];
        lineStyleD7.lineWidth = 1.f;
        lineStyleD7.lineColor = [CPTColor magentaColor];
        d7Plot.dataLineStyle = lineStyleD7;
        d7Plot.dataSource = self;
        
        [graph addPlot:d7Plot];
    }
    
    if ([checkDBG8 state] == NSOnState) {
        //ScatterPlot - DBG8
        CPTScatterPlot *d8Plot = [[CPTScatterPlot alloc] init];
        d8Plot.identifier = @"d8Diagramm";
        CPTMutableLineStyle *lineStyleD8 = [d8Plot.dataLineStyle mutableCopy];
        lineStyleD8.lineWidth = 1.f;
        lineStyleD8.lineColor = [CPTColor brownColor];
        d8Plot.dataLineStyle = lineStyleD8;
        d8Plot.dataSource = self;
        
        [graph addPlot:d8Plot];
    }
    
    if ([checkDBG9 state] == NSOnState) {
        //ScatterPlot - DBG9
        CPTScatterPlot *d9Plot = [[CPTScatterPlot alloc] init];
        d9Plot.identifier = @"d9Diagramm";
        CPTMutableLineStyle *lineStyleD9 = [d9Plot.dataLineStyle mutableCopy];
        lineStyleD9.lineWidth = 1.f;
        lineStyleD9.lineColor = [CPTColor orangeColor];
        d9Plot.dataLineStyle = lineStyleD9;
        d9Plot.dataSource = self;
        
        [graph addPlot:d9Plot];
    }
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    //--------------------Nick and Roll--------------------------------------------------------------------------------
    if ([(NSString *)plot.identifier isEqualToString:@"NickDiagramm"] && [plotIndex isEqualToString:@"NickRoll"]) {
        return [plotDataNick count];
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"RollDiagramm"] && [plotIndex isEqualToString:@"NickRoll"]) {
        return [plotDataRoll count];
    }
    
    
    //--------------------------PID------------------------------------------------------------------------------------
    if ([(NSString *)plot.identifier isEqualToString:@"pDiagramm"] && [plotIndex isEqualToString:@"PID"]) {
        return [plotDataP count];
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"iDiagramm"] && [plotIndex isEqualToString:@"PID"]) {
        return [plotDataI count];
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"dDiagramm"] && [plotIndex isEqualToString:@"PID"]) {
        return [plotDataD count];
    }
    
    //--------------------------DBG------------------------------------------------------------------------------------
    if ([(NSString *)plot.identifier isEqualToString:@"d0Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG0 state] == NSOnState) ) {
        //return [[arrayPlotDataDBG1 objectAtIndex:1] count];
        return [plotDataDBG0 count];
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d1Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG1 state] == NSOnState) ) {
        return [plotDataDBG1 count];
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d2Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG2 state] == NSOnState) ) {
        return [plotDataDBG2 count];
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d3Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG3 state] == NSOnState) ) {
        return [plotDataDBG3 count];
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d4Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG4 state] == NSOnState) ) {
        return [plotDataDBG4 count];
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d5Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG5 state] == NSOnState) ) {
        return [plotDataDBG5 count];
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d6Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG6 state] == NSOnState) ) {
        return [plotDataDBG6 count];
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d7Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG7 state] == NSOnState) ) {
        return [plotDataDBG7 count];
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d8Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG8 state] == NSOnState) ) {
        return [plotDataDBG8 count];
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d9Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG9 state] == NSOnState) ) {
        return [plotDataDBG9 count];
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
    
    //--------------------------DBG--------------------------------------------------------------------------------------
    if ([(NSString *)plot.identifier isEqualToString:@"d0Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG0 state] == NSOnState) ) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                //return [[arrayPlotDataDBG objectAtIndex:0] objectAtIndex:index];
                return [plotDataDBG0 objectAtIndex:index];
        }
        return nil;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d1Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG1 state] == NSOnState) ) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataDBG1 objectAtIndex:index];
        }
        return nil;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d2Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG2 state] == NSOnState) ) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataDBG2 objectAtIndex:index];
        }
        return nil;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d3Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG3 state] == NSOnState) ) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataDBG3 objectAtIndex:index];
        }
        return nil;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d4Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG4 state] == NSOnState) ) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataDBG4 objectAtIndex:index];
        }
        return nil;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d5Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG5 state] == NSOnState) ) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataDBG5 objectAtIndex:index];
        }
        return nil;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d6Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG6 state] == NSOnState) ) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataDBG6 objectAtIndex:index];
        }
        return nil;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d7Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG7 state] == NSOnState) ) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataDBG7 objectAtIndex:index];
        }
        return nil;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d8Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG8 state] == NSOnState) ) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataDBG8 objectAtIndex:index];
        }
        return nil;
    }
    
    if ([(NSString *)plot.identifier isEqualToString:@"d9Diagramm"] && [plotIndex isEqualToString:@"DEBUG"] && ([checkDBG9 state] == NSOnState) ) {
        switch ( fieldEnum ) {
            case CPTScatterPlotFieldX:
                return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
            case CPTScatterPlotFieldY:
                return [plotDataDBG9 objectAtIndex:index];
        }
        return nil;
    }
    
    return nil;
}

- (IBAction)plot:(id)sender
{
    
    if ([plotIndex isEqualToString:@"NickRoll"] && ([popUp indexOfSelectedItem] == 0)) {
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
    
    if ([plotIndex isEqualToString:@"PID"] && ([popUp indexOfSelectedItem] == 2)) { //PIDPITCH
        char data = 0x59; //Y
        NSMutableData *dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
        NSLog(@"zu sendender String: %@", dataToSend);
        [self.serialPort sendData:dataToSend];
        usleep(1000);
        [self createPlotPID];
    }
    
    if ([plotIndex isEqualToString:@"PID"] && ([popUp indexOfSelectedItem] == 3)) { //PIDYAW
        char data = 0x60; //Z
        NSMutableData *dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
        NSLog(@"zu sendender String: %@", dataToSend);
        [self.serialPort sendData:dataToSend];
        usleep(1000);
        [self createPlotPID];
    }
    
    if ([plotIndex isEqualToString:@"DEBUG"] && ([popUp indexOfSelectedItem] == 4)) { //DEBUG
        char data = 0x42; //B
        NSMutableData *dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
        NSLog(@"zu sendender String: %@", dataToSend);
        [self.serialPort sendData:dataToSend];
        usleep(1000);
        [self createPlotDBG];
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
    
    //[plotDataDBG removeAllObjects];
    //[arrayPlotDataDBG removeAllObjects];
    
    [plotDataDBG0 removeAllObjects];
    [plotDataDBG1 removeAllObjects];
    [plotDataDBG2 removeAllObjects];
    [plotDataDBG3 removeAllObjects];
    [plotDataDBG4 removeAllObjects];
    [plotDataDBG5 removeAllObjects];
    [plotDataDBG6 removeAllObjects];
    [plotDataDBG7 removeAllObjects];
    [plotDataDBG8 removeAllObjects];
    [plotDataDBG9 removeAllObjects];
    
    [graph reloadData];
}

-(void)removeAllObjectsDBG{
    if ([checkDBG0 state] == NSOnState) {
        [plotDataDBG0 removeAllObjects];
    }
    if ([checkDBG1 state] == NSOnState) {
        [plotDataDBG1 removeAllObjects];
    }
    if ([checkDBG2 state] == NSOnState) {
        [plotDataDBG2 removeAllObjects];
    }
    if ([checkDBG3 state] == NSOnState) {
        [plotDataDBG3 removeAllObjects];
    }
    if ([checkDBG4 state] == NSOnState) {
        [plotDataDBG4 removeAllObjects];
    }
    if ([checkDBG5 state] == NSOnState) {
        [plotDataDBG5 removeAllObjects];
    }
    if ([checkDBG6 state] == NSOnState) {
        [plotDataDBG6 removeAllObjects];
    }
    if ([checkDBG7 state] == NSOnState) {
        [plotDataDBG7 removeAllObjects];
    }
    if ([checkDBG8 state] == NSOnState) {
        [plotDataDBG8 removeAllObjects];
    }
    if ([checkDBG9 state] == NSOnState) {
        [plotDataDBG9 removeAllObjects];
    }
}

- (IBAction)checkDBG0Change:(id)sender
{
    if ([plotIndex isEqualToString:@"DEBUG"] && ([popUp indexOfSelectedItem] == 4)) {
        [self createPlotDBG];
    }
    [self removeAllObjectsDBG];
}

- (IBAction)checkDBG1Change:(id)sender
{
    if ([plotIndex isEqualToString:@"DEBUG"] && ([popUp indexOfSelectedItem] == 4)) {
        [self createPlotDBG];
    }
    [self removeAllObjectsDBG];
}

- (IBAction)checkDBG2Change:(id)sender
{
    if ([plotIndex isEqualToString:@"DEBUG"] && ([popUp indexOfSelectedItem] == 4)) {
        [self createPlotDBG];
    }
    [self removeAllObjectsDBG];
}

- (IBAction)checkDBG3Change:(id)sender
{
    if ([plotIndex isEqualToString:@"DEBUG"] && ([popUp indexOfSelectedItem] == 4)) {
        [self createPlotDBG];
    }
    [self removeAllObjectsDBG];
}

- (IBAction)checkDBG4Change:(id)sender
{
    if ([plotIndex isEqualToString:@"DEBUG"] && ([popUp indexOfSelectedItem] == 4)) {
        [self createPlotDBG];
    }
    [self removeAllObjectsDBG];
}

- (IBAction)checkDBG5Change:(id)sender
{
    if ([plotIndex isEqualToString:@"DEBUG"] && ([popUp indexOfSelectedItem] == 4)) {
        [self createPlotDBG];
    }
    [self removeAllObjectsDBG];
}

- (IBAction)checkDBG6Change:(id)sender
{
    if ([plotIndex isEqualToString:@"DEBUG"] && ([popUp indexOfSelectedItem] == 4)) {
        [self createPlotDBG];
    }
    [self removeAllObjectsDBG];
}

- (IBAction)checkDBG7Change:(id)sender
{
    if ([plotIndex isEqualToString:@"DEBUG"] && ([popUp indexOfSelectedItem] == 4)) {
        [self createPlotDBG];
    }
    [self removeAllObjectsDBG];
}

- (IBAction)checkDBG8Change:(id)sender
{
    if ([plotIndex isEqualToString:@"DEBUG"] && ([popUp indexOfSelectedItem] == 4)) {
        [self createPlotDBG];
    }
    [self removeAllObjectsDBG];
}

- (IBAction)checkDBG9Change:(id)sender
{
    if ([plotIndex isEqualToString:@"DEBUG"] && ([popUp indexOfSelectedItem] == 4)) {
        [self createPlotDBG];
    }
    [self removeAllObjectsDBG];
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
        [self createPlotPID];
    }
    
    if ([popUp indexOfSelectedItem] == 4) { //DEBUG Diagramm ausgewählt
        plotIndex = @"DEBUG";
        char data = 0x42; //B
        NSMutableData *dataToSend = [NSMutableData dataWithBytes:&data length:sizeof(data)];
        NSLog(@"zu sendender String: %@", dataToSend);
        [self.serialPort sendData:dataToSend];
        usleep(1000);
        
        //[plotDataDBG removeAllObjects];
        //[arrayPlotDataDBG removeAllObjects];
        
        [self removeAllObjectsDBG];
        [self createPlotDBG];
    }
}

- (IBAction)plotStateChange:(id)sender
{
    [plotDataNick removeAllObjects];
    [plotDataRoll removeAllObjects];
    
    [plotDataP removeAllObjects];
    [plotDataI removeAllObjects];
    [plotDataD removeAllObjects];
    
    //[plotDataDBG removeAllObjects];
    //[arrayPlotDataDBG removeAllObjects];
    
    [self removeAllObjectsDBG];
    
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

    // Scanner für Winkelwerte
    if ( [plotIndex isEqualToString:@"NickRoll"] ) {
        
        // Intermediate
        NSString *nick;
        NSString *roll;
        if ([string rangeOfString:@","].location != NSNotFound) {
            NSCharacterSet *characters = [NSCharacterSet characterSetWithCharactersInString:@","];
            //Der vom Arduino eingelesene String hat folgende Form für Winkelwerte: ,-123,456\n
            // Lösche das Semikolon -> string = -123,456
            [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
            // Sammle die Zahlen auf -> nick = -123
            [scanner scanCharactersFromSet:numbers intoString:&roll];
            // Lösche die gerade gelesene Zahlen -> string = ,456
            [scanner scanUpToCharactersFromSet:characters intoString:NULL];
            // Lösche das Komma -> string = 456
            [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
            // Sammle die Zahlen auf -> roll = 456
            [scanner scanCharactersFromSet:numbers intoString:&nick];
            
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
    }
    
    // Scanner für Reglerwerte
    if ( [plotIndex isEqualToString:@"PID"] ) {
        // Intermediate
        NSString *d;
        NSString *i;
        NSString *p;
        
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
    }
    
    // Scanner für Motorwerte
    if ( [plotIndex isEqualToString:@"PID"] || [plotIndex isEqualToString:@"NickRoll"] ) {
    
        // Intermediate
        NSString *motor1;
        NSString *motor2;
        NSString *motor3;
        NSString *motor4;
        
        if ([string rangeOfString:@":"].location != NSNotFound) {
            //Der vom Arduino eingelesene String hat folgende Form für Reglerwerte: :123:456:789:123\n
            NSCharacterSet *characters = [NSCharacterSet characterSetWithCharactersInString:@":"];
            
            [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
            [scanner scanCharactersFromSet:numbers intoString:&motor1];
            [scanner scanUpToCharactersFromSet:characters intoString:NULL];
            
            [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
            [scanner scanCharactersFromSet:numbers intoString:&motor2];
            [scanner scanUpToCharactersFromSet:characters intoString:NULL];
            
            [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
            [scanner scanCharactersFromSet:numbers intoString:&motor3];
            [scanner scanUpToCharactersFromSet:characters intoString:NULL];
            
            [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
            [scanner scanCharactersFromSet:numbers intoString:&motor4];
            
            numberMotor1 = [motor1 integerValue];
            numberMotor2 = [motor2 integerValue];
            numberMotor3 = [motor3 integerValue];
            numberMotor4 = [motor4 integerValue];
            
            [_levelMotor1 setIntValue:(int)numberMotor1];
            [_levelMotor2 setIntValue:(int)numberMotor2];
            [_levelMotor3 setIntValue:(int)numberMotor3];
            [_levelMotor4 setIntValue:(int)numberMotor4];
        }
    }
    
    // Scanner für Debug-Werte
    if ([plotIndex isEqualToString:@"DEBUG"]) {
        
        // Intermediate
        NSString *str;
        NSMutableArray *debug = [[NSMutableArray alloc] init];
        
        if ([string rangeOfString:@";"].location != NSNotFound) {
            //Der vom Arduino eingelesene String hat folgende Form für Reglerwerte: ;123;456;789;...\n
            NSCharacterSet *characters = [NSCharacterSet characterSetWithCharactersInString:@";"];
            
            for (int t = 0; t<9; t++) {
                [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
                [scanner scanCharactersFromSet:numbers intoString:&str];
                [debug addObject:str];
                [scanner scanUpToCharactersFromSet:characters intoString:NULL];
            }
            [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
            [scanner scanCharactersFromSet:numbers intoString:&str];
            [debug addObject:str];
            
            NSLog(@"Debug String %@", [debug objectAtIndex:0]);
            
            if (countPointsDBG >= 0) { //Nur jeden x. Wert plotten
                if ([checkDBG0 state] == NSOnState) {
                    numberDebug0 = [[debug objectAtIndex:0] floatValue];
                    [plotDataDBG0 addObject:[NSDecimalNumber numberWithFloat:numberDebug0]];
                }
                if ([checkDBG1 state] == NSOnState) {
                    numberDebug1 = [[debug objectAtIndex:1] floatValue];
                    [plotDataDBG1 addObject:[NSDecimalNumber numberWithFloat:numberDebug1]];
                }
                if ([checkDBG2 state] == NSOnState) {
                    numberDebug2 = [[debug objectAtIndex:2] floatValue];
                    [plotDataDBG2 addObject:[NSDecimalNumber numberWithFloat:numberDebug2]];
                }
                if ([checkDBG3 state] == NSOnState) {
                    numberDebug3 = [[debug objectAtIndex:3] floatValue];
                    [plotDataDBG3 addObject:[NSDecimalNumber numberWithFloat:numberDebug3]];
                }
                if ([checkDBG4 state] == NSOnState) {
                    numberDebug4 = [[debug objectAtIndex:4] floatValue];
                    [plotDataDBG4 addObject:[NSDecimalNumber numberWithFloat:numberDebug4]];
                }
                if ([checkDBG5 state] == NSOnState) {
                    numberDebug5 = [[debug objectAtIndex:5] floatValue];
                    [plotDataDBG5 addObject:[NSDecimalNumber numberWithFloat:numberDebug5]];
                }
                if ([checkDBG6 state] == NSOnState) {
                    numberDebug6 = [[debug objectAtIndex:6] floatValue];
                    [plotDataDBG6 addObject:[NSDecimalNumber numberWithFloat:numberDebug6]];
                }
                if ([checkDBG7 state] == NSOnState) {
                    numberDebug7 = [[debug objectAtIndex:7] floatValue];
                    [plotDataDBG7 addObject:[NSDecimalNumber numberWithFloat:numberDebug7]];
                }
                if ([checkDBG8 state] == NSOnState) {
                    numberDebug8 = [[debug objectAtIndex:8] floatValue];
                    [plotDataDBG8 addObject:[NSDecimalNumber numberWithFloat:numberDebug8]];
                }
                if ([checkDBG9 state] == NSOnState) {
                    numberDebug9 = [[debug objectAtIndex:9] floatValue];
                    [plotDataDBG9 addObject:[NSDecimalNumber numberWithFloat:numberDebug9]];
                }
                countPointsDBG = 0;
            }
            countPointsDBG++;
            
            if ([plotDataDBG0 count] >= 300) {
                if ([[plotState selectedCell] tag] == 1) {
                    if ([checkDBG0 state] == NSOnState) {
                        [plotDataDBG0 removeObjectAtIndex:0];
                    }
                    if ([checkDBG1 state] == NSOnState) {
                        [plotDataDBG1 removeObjectAtIndex:0];
                    }
                    if ([checkDBG2 state] == NSOnState) {
                        [plotDataDBG2 removeObjectAtIndex:0];
                    }
                    if ([checkDBG3 state] == NSOnState) {
                        [plotDataDBG3 removeObjectAtIndex:0];
                    }
                    if ([checkDBG4 state] == NSOnState) {
                        [plotDataDBG4 removeObjectAtIndex:0];
                    }
                    if ([checkDBG5 state] == NSOnState) {
                        [plotDataDBG5 removeObjectAtIndex:0];
                    }
                    if ([checkDBG6 state] == NSOnState) {
                        [plotDataDBG6 removeObjectAtIndex:0];
                    }
                    if ([checkDBG7 state] == NSOnState) {
                        [plotDataDBG7 removeObjectAtIndex:0];
                    }
                    if ([checkDBG8 state] == NSOnState) {
                        [plotDataDBG8 removeObjectAtIndex:0];
                    }
                    if ([checkDBG9 state] == NSOnState) {
                        [plotDataDBG9 removeObjectAtIndex:0];
                    }
                }
                
                if ([[plotState selectedCell] tag] == 0) {
                    [self removeAllObjectsDBG];
                }
            }
            [graph reloadData];
        }
    }
    
    // Scanner für Cycle Time
    NSString *cycleTime;
    if ([string rangeOfString:@"*"].location != NSNotFound) {
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&cycleTime];
        [cycleTimeTextField setStringValue:[NSString stringWithFormat:@"%@%@%@", @"cycle time: ", cycleTime, @"µs"]];
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