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

#include "genir.h"

@interface Armadillo : NSObject {
	unsigned char data[240];
	IBOutlet NSProgressIndicator *waitTimer;
	IBOutlet IrPatternView *patView;
	IBOutlet NSPopUpButton *buttonSelect;
	IBOutlet NSSegmentedControl *dialSelect;	
	IBOutlet NSPopUpButton *dataSelect;
	Boolean cancelReceive;
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
}

- (IBAction)debugCrossam_1:(id)sender;
- (IBAction)debugCrossam_2:(id)sender;
- (IBAction)debugCrossam_3:(id)sender;
- (IBAction)debugCrossam_4:(id)sender;
- (IBAction)debugCrossam_5:(id)sender;
- (IBAction)debugCrossam_6:(id)sender;
- (IBAction)debugCrossam_7:(id)sender;
- (IBAction)debugCrossam_8:(id)sender;

- (IBAction)debugPcoprs1_1:(id)sender;
- (IBAction)debugPcoprs1_2:(id)sender;
- (IBAction)debugPcoprs1_3:(id)sender;
- (IBAction)debugPcoprs1_4:(id)sender;
- (IBAction)debugPcoprs1_5:(id)sender;
- (IBAction)debugPcoprs1_6:(id)sender;
- (IBAction)debugPcoprs1_7:(id)sender;

- (IBAction)debugBitbang1_1:(id)sender;
- (IBAction)debugBitbang1_2:(id)sender;
@end
