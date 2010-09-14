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

// parser for as follow site data
// http://www.256byte.com/remocon/iremo_db.php

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if([elementName compare:@"remote"] == NSOrderedSame){
		remoteName = [[NSMutableString alloc] initWithString:[attributeDict objectForKey:@"name"]];
	}
    if([elementName compare:@"button"] == NSOrderedSame){
		buttonName = [[NSMutableString alloc] initWithString:[attributeDict objectForKey:@"name"]];
		buttonRepeatType = [[NSMutableString alloc] initWithString:[attributeDict objectForKey:@"repeat_type"]];
	}
    if([elementName compare:@"signal"] == NSOrderedSame){
        isSignal = YES;

        signalValue = [[NSMutableString string] retain];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if(isSignal){
        [signalValue appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
	if([elementName compare:@"button"] == NSOrderedSame){
		[buttonName release];
		[buttonRepeatType release];
	}
	if([elementName compare:@"signal"] == NSOrderedSame){
        isSignal = NO;
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
}

- (void) readData
{
	NSData *result = [[NSData alloc] initWithContentsOfFile:@"/tmp/iremo.xml"];
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:result];
	[xmlParser setDelegate:self];
	[xmlParser parse];
	[xmlParser release];
}

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

//	[self readData];
	crossam2_init((CFStringRef)portName);

	[NSThread detachNewThreadSelector:@selector(timerTask) toTarget:self
						   withObject:nil];
}

- (IBAction)debugCrossam_2:(id)sender
{
	crossam2_protectoff();

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
	unsigned char crossam_data[128];
	int read_size;
	read_size = crossam2_read(4,40, crossam_data, sizeof(crossam_data));
	int i;
	for(i = 0; i < read_size; ++i) {
		printf("%02x ", crossam_data[i]);
		if((i + 1) % 16 == 0)
			printf("\n");
	}
	printf("\n");
	
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
	int gen_size;
#if 0
	// Preset Sony TV Power
	cmddata[0] = 0x00;
	cmddata[1] = 0xc0;
	cmddata[2] = 0x11;
	gen_size = 3;
#else
	// Make Sony TV Power
	unsigned char cmd[2];
	cmd[0] = 0xa9;
	cmd[1] = 0x00;
	irpat = (irdata *)malloc(sizeof(irdata));
	irpat->zero_h = 660;
	irpat->zero_l = 540;
	irpat->one_h = 1245;
	irpat->one_l = 540;
	irpat->stop_h = 0;
	irpat->stop_l = 25100;
	irpat->start_h = 2460;
	irpat->start_l = 525;
	gen_size = genir_crossam2(irpat, cmd, 12,
								 2, cmddata, sizeof(cmddata));
#endif
	int i;
	for(i = 0; i < gen_size; ++i) {
		printf("%02x ", cmddata[i]);
		if((i + 1) % 16 == 0)
			printf("\n");
	}
	printf("\n");
	crossam2_write(4,40, cmddata, gen_size);	
	
	[NSThread detachNewThreadSelector:@selector(timerTask) toTarget:self
						   withObject:nil];
}

- (IBAction)debugCrossam_8:(id)sender
{
	crossam2_pushkey(0,40);
	
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
//		NSLog(@"MORI MORI Debug %02x %02x", data[0], data[1]);
		int i, j;
		for(j = 0; j < 15; ++j) {
			for(i = 0; i < 16; ++i) {
				printf("%02x ", data[j * 16 + i]);
			}
			printf("\n");
		}
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
