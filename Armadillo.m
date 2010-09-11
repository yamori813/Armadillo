/*
 *  Armadillo.c
 *  Armadillo
 *
 *  Created by H.M on 10/08/29.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#include "serial.h"
#include "crossam2.h"
#include "pcoprs1.h"
#import "Armadillo.h"

@implementation Armadillo

//
// Crossam2 Debug code
//

- (void) timerTask
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[waitTimer setHidden:NO];
	[waitTimer startAnimation:self];
	sleep(10);
	[waitTimer stopAnimation:self];
	[waitTimer setHidden:YES];
}

- (IBAction)debugCrossam_1:(id)sender
{
	NSMutableArray *ifList;
	NSMutableString *portName;
	// get serial port name list
    ifList = [[ NSMutableArray alloc ] init];
    io_iterator_t	serialPortIterator;
    FindModems(&serialPortIterator);
    GetModemPath(serialPortIterator, (CFMutableArrayRef)ifList);
    IOObjectRelease(serialPortIterator);	// Release the iterator.
	int i;
	for(i =0; i < [ ifList count]; ++i) {
		NSRange range;
		range = [[ifList objectAtIndex:i] rangeOfString:@"F5U103"];
		if (range.location != NSNotFound) {
			//			NSLog(@"MORI MORI port %@\n", [ifList objectAtIndex:i]);
			portName = [[ NSMutableString alloc ] init];
			[portName setString:[ifList objectAtIndex:i]];
			break;
		}
	}
	
	crossam2_init((CFStringRef)portName);

	[NSThread detachNewThreadSelector:@selector(timerTask) toTarget:self
						   withObject:nil];
}

- (IBAction)debugCrossam_2:(id)sender
{
//	crossam2_pushkey(0,40);
	crossam2_protectoff();
//	crossam2_read(0,40);
//	crossam2_leam(0,40);
	[NSThread detachNewThreadSelector:@selector(timerTask) toTarget:self
						   withObject:nil];
}

- (IBAction)debugCrossam_3:(id)sender
{
	crossam2_led(1);

	[NSThread detachNewThreadSelector:@selector(timerTask) toTarget:self
						   withObject:nil];
}

- (IBAction)debugCrossam_4:(id)sender
{
	crossam2_led(0);

	[NSThread detachNewThreadSelector:@selector(timerTask) toTarget:self
						   withObject:nil];
}

- (IBAction)debugCrossam_5:(id)sender
{
	unsigned char data[128];
	crossam2_read(0,40, data, sizeof(data));

	[NSThread detachNewThreadSelector:@selector(timerTask) toTarget:self
						   withObject:nil];
}

- (IBAction)debugCrossam_6:(id)sender
{
	char str[1024];
	crossam2_version(str, sizeof(str));
	NSLog(@"Version : %s", str);
	
	[NSThread detachNewThreadSelector:@selector(timerTask) toTarget:self
						   withObject:nil];
}

- (IBAction)debugCrossam_7:(id)sender
{
	unsigned char cmddata[1024];
	// Preset Sony TV Power
	cmddata[0] = 0x00;
	cmddata[1] = 0xc0;
	cmddata[2] = 0x11;
	crossam2_write(4,40, cmddata, 3);	
	
	[NSThread detachNewThreadSelector:@selector(timerTask) toTarget:self
						   withObject:nil];
}

//
// PC-OP-RS1 Debug code
//

- (void) transferTask
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	pcoprs1_transfer(1, data);
}

- (void) receiveTask
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if(pcoprs1_receive_start()) {
		while(pcoprs1_receive_data(data) == 0) {
			if(cancelReceive == YES)
				break;
		}
		NSLog(@"MORI MORI Debug %02x %02x", data[0], data[1]);
	}
	[waitTimer stopAnimation:self];
	[waitTimer setHidden:YES];
}


- (IBAction)debugPcoprs1_1:(id)sender
{
	NSMutableArray *ifList;
	NSMutableString *portName;
	// get serial port name list
    ifList = [[ NSMutableArray alloc ] init];
    io_iterator_t	serialPortIterator;
    FindModems(&serialPortIterator);
    GetModemPath(serialPortIterator, (CFMutableArrayRef)ifList);
    IOObjectRelease(serialPortIterator);	// Release the iterator.
	int i;
	for(i =0; i < [ ifList count]; ++i) {
		NSRange range;
		range = [[ifList objectAtIndex:i] rangeOfString:@"OPRS"];
		if (range.location != NSNotFound) {
			//			NSLog(@"MORI MORI port %@\n", [ifList objectAtIndex:i]);
			portName = [[ NSMutableString alloc ] init];
			[portName setString:[ifList objectAtIndex:i]];
			break;
		}
	}
	
	pcoprs1_init((CFStringRef)portName);
}

- (IBAction)debugPcoprs1_2:(id)sender
{
	[waitTimer setHidden:NO];
	[waitTimer startAnimation:self];
	cancelReceive = NO;
	
	[NSThread detachNewThreadSelector:@selector(receiveTask) toTarget:self
						   withObject:nil];
}

- (IBAction)debugPcoprs1_3:(id)sender
{
	[NSThread detachNewThreadSelector:@selector(transferTask) toTarget:self
						   withObject:nil];
}
	
- (IBAction)debugPcoprs1_4:(id)sender
{
	pcoprs1_led();
}

- (IBAction)debugPcoprs1_5:(id)sender
{
	cancelReceive = YES;

	pcoprs1_receive_cancel();

	[waitTimer stopAnimation:self];
	[waitTimer setHidden:YES];
}

@end
