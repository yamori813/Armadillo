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
}

- (IBAction)debugInit:(id)sender;
- (IBAction)debugPushKey:(id)sender;
- (IBAction)debugLEDOn:(id)sender;
- (IBAction)debugLEDOff:(id)sender;

- (IBAction)debugPcoprs1_1:(id)sender;
- (IBAction)debugPcoprs1_2:(id)sender;
- (IBAction)debugPcoprs1_3:(id)sender;
- (IBAction)debugPcoprs1_4:(id)sender;

@end
