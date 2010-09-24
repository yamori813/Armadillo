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
#include "bitbang.h"
#import "Armadillo.h"

@implementation Armadillo

- (id)init {
    self = [super init];
    if (self) {
		buttonItems = [[NSArray alloc] initWithObjects:
					   @"チャンネル1",
					   @"チャンネル2",
					   @"チャンネル3",
					   @"チャンネル4",
					   @"チャンネル5",
					   @"チャンネル6",
					   @"チャンネル7",
					   @"チャンネル8",
					   @"チャンネル9",
					   @"チャンネル10",
					   @"チャンネル11",
					   @"チャンネル12",
					   @"カーソル左",
					   @"カーソル右",
					   @"カーソル上",
					   @"カーソル下",
					   @"ファンクション1",
					   @"ファンクション2",
					   @"ファンクション3",
					   @"ファンクション4",
					   @"ファンクション5",
					   @"ファンクション6",
					   @"ファンクション7",
					   @"ファンクション8",
					   @"ファンクション9",
					   @"ファンクション10",
					   @"ファンクション11",
					   @"ファンクション12",
					   @"ファンクション13",
					   @"ファンクション14",
					   @"ボリューム上",
					   @"ボリューム下",
					   @"一時停止",
					   @"巻き戻し",
					   @"再生",
					   @"早送り",
					   @"記録",
					   @"前へ",
					   @"停止",
					   @"次へ",
					   @"電源", nil];
    }
    return self;
}

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
    if([elementName compare:@"code0_high"] == NSOrderedSame || 
	   [elementName compare:@"code0_low"] == NSOrderedSame || 
	   [elementName compare:@"code1_high"] == NSOrderedSame || 
	   [elementName compare:@"code1_low"] == NSOrderedSame || 
	   [elementName compare:@"header_high"] == NSOrderedSame || 
	   [elementName compare:@"header_low"] == NSOrderedSame || 
	   [elementName compare:@"stop_high"] == NSOrderedSame || 
	   [elementName compare:@"stop_low"] == NSOrderedSame || 
	   [elementName compare:@"bit_count"] == NSOrderedSame) {
        isFormat = YES;
        formatValue = [[NSMutableString alloc] init];
    }
	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if(isSignal){
        [signalValue appendString:string];
    }
    if(isFormat){
        [formatValue appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
	
	if([elementName compare:@"code0_high"] == NSOrderedSame) {
		remoFormat->zero_h = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"code0_low"] == NSOrderedSame) {
		remoFormat->zero_l = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"code1_high"] == NSOrderedSame) {
		remoFormat->one_h = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"code1_low"] == NSOrderedSame) {
		remoFormat->one_l = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"header_high"] == NSOrderedSame) {
		remoFormat->start_h = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"header_low"] == NSOrderedSame) {
		remoFormat->start_l = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"stop_high"] == NSOrderedSame) {
		remoFormat->stop_h = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"stop_low"] == NSOrderedSame) {
		remoFormat->stop_l = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"bit_count"] == NSOrderedSame) {
		remoBits = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"button"] == NSOrderedSame){
		[buttonName release];
		[buttonRepeatType release];
	}
	if([elementName compare:@"signal"] == NSOrderedSame){
		[remoData addObject:[NSArray arrayWithObjects:buttonName, signalValue, nil]];
        isSignal = NO;
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
}

- (void) readData:(NSString *)path
{
	NSData *result = [[NSData alloc] initWithContentsOfFile:path];
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

	crossam2_init((CFStringRef)portName);
	for(i = 0; i < [buttonItems count]; ++i)
		[buttonSelect addItemWithTitle:[buttonItems objectAtIndex:i]];

//	[NSThread detachNewThreadSelector:@selector(timerTask) toTarget:self
//						   withObject:nil];
}

- (IBAction)debugCrossam_2:(id)sender
{
	crossam2_protectoff();
}

- (IBAction)debugCrossam_3:(id)sender
{
	crossam2_led(1);
}

- (IBAction)debugCrossam_4:(id)sender
{
	crossam2_led(0);
}

- (IBAction)debugCrossam_5:(id)sender
{
	unsigned char crossam_data[128];
	int read_size;
	read_size = crossam2_read([dialSelect selectedSegment],
							  [buttonItems indexOfObject:[[buttonSelect selectedItem] title]],
							  crossam_data, sizeof(crossam_data));
	int i;
	for(i = 0; i < read_size; ++i) {
		printf("%02x ", crossam_data[i]);
		if((i + 1) % 16 == 0)
			printf("\n");
	}
	printf("\n");
	if(read_size)
		crossam2_dump(crossam_data);
}

- (IBAction)debugCrossam_6:(id)sender
{
	char str[1024];
	crossam2_version(str, sizeof(str));
	NSLog(@"Version : %s", str);
}

- (IBAction)debugCrossam_7:(id)sender
{
	unsigned char cmddata[1024];
	int gen_size;
	NSLog(@"%d %d", [dialSelect selectedSegment], 
		  [buttonItems indexOfObject:[[buttonSelect selectedItem] title]]);
#if 0
	// Preset Sony TV Power
	cmddata[0] = 0x00;
	cmddata[1] = 0xc0;
	cmddata[2] = 0x11;
	gen_size = 3;
#endif

#if 0
	// Make MITSUBISHI LCD Display
	irdata *patptr = (irdata *)malloc(sizeof(irdata) * 2);
	pat = patptr;
	patptr->format.zero_h = 420;
	patptr->format.zero_l = 540;
	patptr->format.one_h = 420;
	patptr->format.one_l = 1490;
	patptr->format.stop_h = 390;
	patptr->format.stop_l = 3970;
	patptr->format.start_h = 7870;
	patptr->format.start_l = 3970;
	patptr->data[0] = 0x27;
	patptr->bitlen = 8;
	++patptr;
	patptr->format.zero_h = 420;
	patptr->format.zero_l = 540;
	patptr->format.one_h = 420;
	patptr->format.one_l = 1490;
	patptr->format.stop_h = 390;
	patptr->format.stop_l = 20426;
	patptr->format.start_h = 0;
	patptr->format.start_l = 0;
	//	patptr->data = cmd + 1;
	/* Power */
	patptr->data[0] = 0xc0;
	/* HDMI1
	patptr->data[0] = 0x74;
	 */
	patptr->bitlen = 8;
	patptr->repeat = -1;
	gen_size = genir_crossam2(0, 2, pat , cmddata, sizeof(cmddata));
//	gen_size = genir_pcoprs1(2, pat , cmddata);
//	pcoprs1_transfer(1, cmddata);
	[patView setIrPattern:2 pat:pat];
	[patView setNeedsDisplay:YES];
#endif

#if 0
	// Make ONKYO CD
	irdata *patptr = (irdata *)malloc(sizeof(irdata) * 3);
	pat = patptr;
	patptr->format.zero_h = 480;
	patptr->format.zero_l = 590;
	patptr->format.one_h = 480;
	patptr->format.one_l = 1700;
	patptr->format.stop_h = 480;
	patptr->format.stop_l = 41290;
	patptr->format.start_h = 8900;
	patptr->format.start_l = 4530;
	/* Eject */
	patptr->data[0] = 0x4b;
	patptr->data[1] = 0x34;
	patptr->data[2] = 0xd0;
	patptr->data[3] = 0x2f;
	/* Stop
	patptr->data[0] = 0x4b;
	patptr->data[1] = 0x34;
	patptr->data[2] = 0x38;
	patptr->data[3] = 0xc7;
	*/
	patptr->bitlen = 32;
	++patptr;
	patptr->format.stop_h = 480;
	patptr->format.stop_l = 96130;
	patptr->format.start_h = 8900;
	patptr->format.start_l = 2280;
	patptr->bitlen = 0;
	++patptr;
	patptr->format.stop_h = 480;
	patptr->format.stop_l = 96130;
	patptr->format.start_h = 8900;
	patptr->format.start_l = 2280;
	patptr->bitlen = 0;
	patptr->repeat = 0;
	gen_size = genir_crossam2(2, 3, pat , cmddata, sizeof(cmddata));
	[patView setIrPattern:1 pat:pat];
	[patView setNeedsDisplay:YES];
#endif

#if 1
	// Make Sony TV (12bit)
	irdata *patptr = (irdata *)malloc(sizeof(irdata) * 1);
	pat = patptr;
	patptr->format.zero_h = 660;
	patptr->format.zero_l = 540;
	patptr->format.one_h = 1245;
	patptr->format.one_l = 540;
	patptr->format.stop_h = 0;
	patptr->format.stop_l = 25100;
	patptr->format.start_h = 2460;
	patptr->format.start_l = 525;
	/* Power */
	patptr->data[0] = 0xa9;
	patptr->data[1] = 0x00;
	/* Input select
	patptr->data[0]= 0xa5;
	patptr->data[1]= 0x00;
	 */
	patptr->bitlen = 12;
	patptr->repeat = -1;
	gen_size = genir_crossam2(1, 1, pat , cmddata, sizeof(cmddata));
	[patView setIrPattern:1 pat:pat];
	[patView setNeedsDisplay:YES];
#endif

	int i;
	for(i = 0; i < gen_size; ++i) {
		printf("%02x ", cmddata[i]);
		if((i + 1) % 16 == 0)
			printf("\n");
	}
	printf("\n");

	crossam2_write(4,40, cmddata, gen_size);	
}

- (IBAction)debugCrossam_8:(id)sender
{
	crossam2_pushkey([dialSelect selectedSegment],
					 [buttonItems indexOfObject:[[buttonSelect selectedItem] title]]);
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
/*		for(j = 0; j < 15; ++j) {
			for(i = 0; i < 16; ++i) {
				printf("%02x ", data[j * 16 + i]);
			}
			printf("\n");
		}*/
/*
		for(j = 0; j < 240; ++j) {
			for(i = 0; i <8 ; ++i) {
				printf("%d", (data[j] >> i) & 1);
			}
		}
		printf("\n");*/
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

- (IBAction)debugPcoprs1_6:(id)sender
{
	unsigned char cmddata[240];
	int gen_size;

	// set value from xml
	irdata *patptr = (irdata *)malloc(sizeof(irdata) * 1);
	pat = patptr;
	patptr->format = *remoFormat;
	NSString *theData = [[remoData objectAtIndex:[dataSelect indexOfSelectedItem]] objectAtIndex:1];
	NSLog(@"%@ %d", theData, [theData length]);
	int i;
	for(i = 0; i < [theData length] / 2; ++i) {
		patptr->data[i] = hex2Int((char *)[theData cStringUsingEncoding:NSASCIIStringEncoding]+i*2);
	}
	patptr->bitlen = remoBits;
	patptr->repeat = -1;

	// generate and send data
	gen_size = genir_pcoprs1(1, pat , cmddata);
	pcoprs1_transfer(1, cmddata);

	// draw pattern
	[patView setIrPattern:1 pat:pat];
	[patView setNeedsDisplay:YES];	
}

- (IBAction)debugPcoprs1_7:(id)sender
{
	NSOpenPanel *opPanel = [ NSOpenPanel openPanel ];
	NSArray *imgTypes = [ NSArray arrayWithObjects : @"xml",nil ];
	
	int	 opRet;
	
	opRet = [ opPanel runModalForDirectory : NSHomeDirectory()
									  file : @"Documents"
									 types : imgTypes ];

	if ( opRet == NSOKButton ) {
		NSString *filepath = [opPanel filename];
		// load data from xml
		remoFormat = (irtime *)malloc(sizeof(irtime));
		remoData = [[NSMutableArray alloc] init];
		[self readData:filepath];
		int i;
		for(i = 0; i < [remoData count]; ++i)
			[dataSelect addItemWithTitle:[[remoData objectAtIndex:i] objectAtIndex:0]];
		
	} 
}

- (IBAction)debugBitbang1_1:(id)sender
{
	bitbang_init();
}

- (IBAction)debugBitbang1_2:(id)sender
{
	unsigned char cmddata[1024*32];
	int gen_size;
#if 1
	// Apple remote
	// http://www.ez0.net/2007/11/appleremoteの赤外線信号を解析してみた/
	// http://www2.renesas.com/faq/ja/mi_com/f_com_remo.html
	irdata *patptr = (irdata *)malloc(sizeof(irdata) * 2);
	pat = patptr;
	// read code
	patptr->format.zero_h = 560;
	patptr->format.zero_l = 560;
	patptr->format.one_h = 560;
	patptr->format.one_l = 1690;
	patptr->format.stop_h = 560;
	patptr->format.stop_l = 10000;
	patptr->format.start_h = 9000;
	patptr->format.start_l = 4500;
	/* Play */
	patptr->data[0] = 0x77;
	patptr->data[1] = 0xe1;
	patptr->data[2] = 0xa0;
	patptr->data[3] = 0xe9;
	patptr->bitlen = 32;
	++patptr;
	// repet code
	patptr->format.zero_h = 560;
	patptr->format.zero_l = 560;
	patptr->format.one_h = 560;
	patptr->format.one_l = 1690;
	patptr->format.stop_h = 560;
	patptr->format.stop_l = 10000;
	patptr->format.start_h = 9000;
	patptr->format.start_l = 2250;
	patptr->bitlen = 0;
	patptr->repeat = 1;	
	gen_size = genir_bitbang(2, pat , cmddata, sizeof(cmddata));
	[patView setIrPattern:1 pat:pat];
	[patView setNeedsDisplay:YES];
#else	
	// Make Sony TV (12bit)
	irdata *patptr = (irdata *)malloc(sizeof(irdata) * 1);
	pat = patptr;
	patptr->format.zero_h = 660;
	patptr->format.zero_l = 540;
	patptr->format.one_h = 1245;
	patptr->format.one_l = 540;
	patptr->format.stop_h = 0;
	patptr->format.stop_l = 25100;
	patptr->format.start_h = 2460;
	patptr->format.start_l = 525;
	/* Power */
	patptr->data[0] = 0xa9;
	patptr->data[1] = 0x00;
	/* Input select
	 patptr->data[0]= 0xa5;
	 patptr->data[1]= 0x00;
	 */
	patptr->bitlen = 12;
	patptr->repeat = 2;
	gen_size = genir_bitbang(1, pat , cmddata, sizeof(cmddata));
	[patView setIrPattern:1 pat:pat];
	[patView setNeedsDisplay:YES];
#endif
	printf("genir_bitbang size = %d\n",gen_size);
	bitbang_transfer(gen_size, cmddata);
}

@end
