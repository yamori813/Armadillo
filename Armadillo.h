/*
 *  Armadillo.h
 *  Armadillo
 *
 *  Created by H.M on 10/08/29.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

#import "IrPatternView.h"
#import "btmsp430.h"
#import "IRKit.h"

#include "genir.h"

@interface Armadillo : NSObject {
	unsigned char data[240];
	IBOutlet NSButton *crossam2InitButton;
	IBOutlet NSButton *crossam2WriteButton;
	IBOutlet NSButton *crossam2PushButton;
	IBOutlet NSButton *crossam2LEDOnButton;
	IBOutlet NSButton *crossam2ReadButton;
	IBOutlet NSPopUpButton *buttonSelect;
	IBOutlet NSSegmentedControl *dialSelect;
	IBOutlet NSPopUpButton *crossam2DevSelect;

	IBOutlet NSButton *pcoprs1InitButton;
	IBOutlet NSButton *pcoprs1TransButton;
	IBOutlet NSButton *pcoprs1LEDButton;
	IBOutlet NSButton *pcoprs1RecvButton;
	IBOutlet NSSegmentedControl *pcopes1LEDSelect;
	IBOutlet NSPopUpButton *pcoprs1DevSelect;

	IBOutlet NSPopUpButton *ftbitbangDevSelect;
	IBOutlet NSButton *ftbitbangInitButton;
	IBOutlet NSButton *ftbitbangTransButton;

	IBOutlet NSButton *remoconTransButton;
	IBOutlet NSPopUpButton *remoconFormatSelect;

	IBOutlet NSButton *btmsp430OpenButton;
	IBOutlet NSButton *btmsp430CloseButton;
	IBOutlet NSButton *btmsp430TransButton;

	IBOutlet NSTextField *irkitHost;

	IBOutlet NSProgressIndicator *waitTimer;
	IBOutlet NSPopUpButton *dataSelect;
	IBOutlet NSTextField *fileName;

	IBOutlet NSButton *disclosureButton;
	IBOutlet IrPatternView *patView;

	IBOutlet NSWindow *mainWindow;
	IBOutlet NSTabView *tabView;
	NSString *xmlFilePath;

	Boolean isPcoprs1Receive;
	NSString *remoteName;
	NSString *buttonName;
	NSString *buttonRepeatType;
	NSString *codePat;
	NSString *framePat;
	Boolean isSignal;
	Boolean inPat;
	Boolean inFrame;
	NSMutableString *signalValue;
	irdata *pat;
	NSArray *buttonItems;

	Boolean isFormat;
	NSMutableString *formatValue;
	int remoCodeCount;
	int remoFrameCount;
	irtime *remoCode[4];
	irtime *remoFrame[4];
	int remoBits[4];
	NSMutableArray *signalArray;
	NSMutableDictionary *remoData;

	BTMSP430 *btmsp430;
	
	int appleremoteStat;
}

- (IBAction)crossam2Init:(id)sender;
- (IBAction)crossam2LEDOn:(id)sender;
- (IBAction)crossam2Push:(id)sender;
- (IBAction)crossam2Write:(id)sender;
- (IBAction)crossam2Read:(id)sender;

- (IBAction)pcoprs1Init:(id)sender;
- (IBAction)pcoprs1Trans:(id)sender;
- (IBAction)pcoprs1LED:(id)sender;
- (IBAction)pcoprs1Recv:(id)sender;

- (IBAction)ftbitbangInit:(id)sender;
- (IBAction)ftbitbangTrans:(id)sender;

- (IBAction)remoconTrans:(id)sender;

- (IBAction)btmsp430Open:(id)sender;
- (IBAction)btmsp430Close:(id)sender;
- (IBAction)btmsp430Trans:(id)sender;

- (IBAction)irkitTrans:(id)sender;

// 

- (IBAction)xmlLoad:(id)sender;

//

- (void) openxml:(NSString *)path;
- (void) setTab:(int)tab;
- (int) getTab;
- (void) setCommand:(NSString *)command;

- (IBAction)disclosureControls:sender;

@end
