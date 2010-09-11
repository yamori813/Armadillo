/*
 *  Armadillo.h
 *  Armadillo
 *
 *  Created by H.M on 10/08/29.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@interface Armadillo : NSObject {
	unsigned char data[240];
	IBOutlet NSProgressIndicator *waitTimer;
	Boolean cancelReceive;
}

- (IBAction)debugCrossam_1:(id)sender;
- (IBAction)debugCrossam_2:(id)sender;
- (IBAction)debugCrossam_3:(id)sender;
- (IBAction)debugCrossam_4:(id)sender;
- (IBAction)debugCrossam_5:(id)sender;
- (IBAction)debugCrossam_6:(id)sender;
- (IBAction)debugCrossam_7:(id)sender;

- (IBAction)debugPcoprs1_1:(id)sender;
- (IBAction)debugPcoprs1_2:(id)sender;
- (IBAction)debugPcoprs1_3:(id)sender;
- (IBAction)debugPcoprs1_4:(id)sender;
- (IBAction)debugPcoprs1_5:(id)sender;

@end
