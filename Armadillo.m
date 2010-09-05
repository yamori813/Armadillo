/*
 *  Armadillo.c
 *  Armadillo
 *
 *  Created by H.M on 10/08/29.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#include "crossam2.h"
#include "pcoprs1.h"
#import "Armadillo.h"

@implementation Armadillo

- (IBAction)debugInit:(id)sender
{
	crossam2_init((CFStringRef)@"/dev/cu.F5U103000013FD");
}

- (IBAction)debugPushKey:(id)sender
{
	crossam2_pushkey(0,40);
}

- (IBAction)debugLEDOn:(id)sender
{
	crossam2_led(1);
}

- (IBAction)debugLEDOff:(id)sender
{
	crossam2_led(0);
}


- (IBAction)debugPcoprs1_1:(id)sender
{
	pcoprs1_init((CFStringRef)@"/dev/cu.OPRS00002776");
}

- (void) receiveTask
{
	if(pcoprs1_receive_start()) {
		while(pcoprs1_receive_data(data) == 0)
			;
		NSLog(@"MORI MORI Debug %02x %02x", data[0], data[1]);
	}
}

- (IBAction)debugPcoprs1_2:(id)sender
{
	[NSThread detachNewThreadSelector:@selector(receiveTask) toTarget:self
						   withObject:nil];
}

- (IBAction)debugPcoprs1_3:(id)sender
{
	pcoprs1_transfer(1, data);
}
	
- (IBAction)debugPcoprs1_4:(id)sender
{
	pcoprs1_led();
}

- (IBAction)debugPcoprs1_5:(id)sender
{
	pcoprs1_receive_cancel();
}

@end
