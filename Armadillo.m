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
#include "remocon.h"
#include "appleremote.h"
#import "Armadillo.h"

@implementation Armadillo

- (void) appleRemote
{
	NSAutoreleasePool* pool;
    pool = [[NSAutoreleasePool alloc]init];

	int val;
	do {
		@synchronized(self) {
			val = appleremote_getevent();
		}
		if(val == 1 && [ftbitbangTransButton isEnabled] == YES)
			[self ftbitbangTrans:self];
		int numItem, curItem;
		numItem = [dataSelect numberOfItems];
		if(numItem)
			curItem = [dataSelect indexOfSelectedItem];
		if(val == 2 && numItem != 0 && curItem != 0) {
			--curItem;
			[dataSelect selectItemAtIndex:curItem];
		}
		if(val == 3 && numItem != 0 && curItem != numItem - 1) {
			++curItem;
			[dataSelect selectItemAtIndex:curItem];
		}
		usleep(500*1000);
	} while(appleremoteStat == 1);

	[pool release];
	[NSThread exit];
}

- (void)dealloc {
	if(appleremoteStat) {
		appleremoteStat = 0;
		appleremote_close();
	}
	[super dealloc];
}

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
		isPcoprs1Receive = NO;
		if(appleremote_open()) {
			appleremoteStat = 1;
			[NSThread detachNewThreadSelector:@selector(appleRemote) toTarget:self
							   withObject:nil];
		} else {
			appleremoteStat = 0;
		}
		remoData = nil;
		xmlFilePath = nil;
		pat = NULL;
    }
    return self;
}

// parser for as follow site data
// http://www.256byte.com/remocon/iremo_db.php
//

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	inPat = NO;
	inFrame = NO;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if([elementName compare:@"pat"] == NSOrderedSame){
		if(inPat)
			remoCode[remoCodeCount] = (irtime *)malloc(sizeof(irtime));
		else if(inFrame)
			remoFrame[remoFrameCount] = (irtime *)malloc(sizeof(irtime));
	}
    if([elementName compare:@"code_pat"] == NSOrderedSame){
		inPat = YES;
	}
    if([elementName compare:@"frame_pat"] == NSOrderedSame){
		inFrame = YES;
	}
	if([elementName compare:@"remote"] == NSOrderedSame){
		remoteName = [[NSMutableString alloc] initWithString:[attributeDict objectForKey:@"name"]];
	}
    if([elementName compare:@"button"] == NSOrderedSame){
		buttonName = [[NSMutableString alloc] initWithString:[attributeDict objectForKey:@"name"]];
		buttonRepeatType = [[NSMutableString alloc] initWithString:[attributeDict objectForKey:@"repeat_type"]];
		signalArray = [[NSMutableArray alloc] init];
	}
    if([elementName compare:@"signal"] == NSOrderedSame){
        isSignal = YES;
		codePat = [[NSMutableString alloc] initWithString:[attributeDict objectForKey:@"code_pat"]];
		framePat = [[NSMutableString alloc] initWithString:[attributeDict objectForKey:@"frame_pat"]];

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
    if([elementName compare:@"pat"] == NSOrderedSame){
		if(inPat)
			++remoCodeCount;
		else if(inFrame)
			++remoFrameCount;
	}
    if([elementName compare:@"code_pat"] == NSOrderedSame){
		inPat = NO;
	}
    if([elementName compare:@"frame_pat"] == NSOrderedSame){
		inFrame = NO;
	}
	if([elementName compare:@"code0_high"] == NSOrderedSame) {
		remoCode[remoCodeCount]->zero_h = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"code0_low"] == NSOrderedSame) {
		remoCode[remoCodeCount]->zero_l = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"code1_high"] == NSOrderedSame) {
		remoCode[remoCodeCount]->one_h = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"code1_low"] == NSOrderedSame) {
		remoCode[remoCodeCount]->one_l = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"header_high"] == NSOrderedSame) {
		remoFrame[remoFrameCount]->start_h = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"header_low"] == NSOrderedSame) {
		remoFrame[remoFrameCount]->start_l = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"stop_high"] == NSOrderedSame) {
		remoFrame[remoFrameCount]->stop_h = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"stop_low"] == NSOrderedSame) {
		remoFrame[remoFrameCount]->stop_l = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"bit_count"] == NSOrderedSame) {
		remoBits[remoFrameCount] = atoi((char *)[formatValue cStringUsingEncoding:NSASCIIStringEncoding]);
		[formatValue release];
		isFormat = NO;
	}
	if([elementName compare:@"button"] == NSOrderedSame){
		if([buttonName length] && [remoData objectForKey:buttonName] == nil) {
//			NSLog(@"%@ %@", buttonName, signalArray);
			[remoData setObject:signalArray forKey:buttonName];
		}
		[buttonName release];
		[buttonRepeatType release];
	}
	if([elementName compare:@"signal"] == NSOrderedSame){
		[signalArray addObject:buttonRepeatType];
		[signalArray addObject:codePat];
		[signalArray addObject:framePat];
		[signalArray addObject:signalValue];
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
	[fileName setStringValue:[path lastPathComponent]];
}

// make irdata to pat by current menu select pattern

-(void) mkirdata:(int)signalcount
{
	int codeIndex, frameIndex;
	int i, j;

	if(pat != NULL)
		free(pat);
	pat = (irdata *)malloc(sizeof(irdata) * signalcount);
	irdata *patptr = pat;
	for(j = 0; j < signalcount; ++j) {
		// set value from xml
		codeIndex = atoi((char *)[[[remoData objectForKey:[dataSelect titleOfSelectedItem]] objectAtIndex:(j * 4 + 1)]
								  cStringUsingEncoding:NSASCIIStringEncoding]);
		frameIndex = atoi((char *)[[[remoData objectForKey:[dataSelect titleOfSelectedItem]] objectAtIndex:(j * 4 + 2)]
								   cStringUsingEncoding:NSASCIIStringEncoding]);
		patptr->format.start_h = remoFrame[frameIndex]->start_h;
		patptr->format.start_l = remoFrame[frameIndex]->start_l;
		patptr->format.stop_h = remoFrame[frameIndex]->stop_h;
		patptr->format.stop_l = remoFrame[frameIndex]->stop_l;
		patptr->format.zero_h = remoCode[codeIndex]->zero_h;
		patptr->format.zero_l = remoCode[codeIndex]->zero_l;
		patptr->format.one_h = remoCode[codeIndex]->one_h;
		patptr->format.one_l = remoCode[codeIndex]->one_l;
		NSString *theData = [[remoData objectForKey:[dataSelect titleOfSelectedItem]] objectAtIndex:(j * 4 + 3)];
		for(i = 0; i < [theData length] / 2; ++i) {
			patptr->data[i] = hex2Int((char *)[theData cStringUsingEncoding:NSASCIIStringEncoding]+i*2);
		}
		patptr->bitlen = remoBits[frameIndex];
		patptr->repeat = atoi((char *)[[[remoData objectForKey:[dataSelect titleOfSelectedItem]] objectAtIndex:(j * 4 + 0)]
									   cStringUsingEncoding:NSASCIIStringEncoding]);
		//			NSLog(@"%d %d %d %@ %d %d", patptr->repeat, codeIndex, frameIndex, theData, [theData length], remoBits[frameIndex]);
		++patptr;
	}
}

-(void) nodata
{
	NSRunAlertPanel(@"データがロードされていません", @"XMLデータファイルをロードしてください。",
					NULL, NULL, NULL);
}

//
// Crossam2 code
//

- (IBAction)crossam2Init:(id)sender
{
	int i;
	NSString *portName;
	portName = nil;
	portName = [[crossam2DevSelect selectedItem] title];
	
	if(portName != nil) {
		if(crossam2_init((CFStringRef)portName)) {
			crossam2_protectoff();
			[crossam2LEDOnButton setEnabled: YES];
			[crossam2InitButton setEnabled: NO];
			[crossam2WriteButton setEnabled: YES];
			[crossam2PushButton setEnabled: YES];
			[crossam2ReadButton setEnabled: YES];
			[buttonSelect setEnabled: YES];
			[dialSelect setEnabled: YES];
			for(i = 0; i < [buttonItems count]; ++i)
				[buttonSelect addItemWithTitle:[buttonItems objectAtIndex:i]];
		} else {
			if(NSRunAlertPanel(@"クロッサムが確認できません", @"クロッサムを初期化しますか？初期化する場合はOKボタンを押した後にクロッサムの"
							   "RECボタンとPowerボタンを押した後ファンクション14を押してください。", @"OK", @"Cancel", NULL) == NSOKButton) {
				crossam2_patch();
			}
		}
	}
}

- (IBAction)crossam2LEDOn:(id)sender
{
	crossam2_led(1);
	usleep(400*1000);
	crossam2_led(0);
}

- (IBAction)crossam2Read:(id)sender
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

- (IBAction)crossam2Write:(id)sender
{
	unsigned char cmddata[1024];
	int gen_size;
	int signalcount;
//	NSLog(@"%d %d", [dialSelect selectedSegment], 
//		  [buttonItems indexOfObject:[[buttonSelect selectedItem] title]]);

	if(remoCodeCount) {
		signalcount = [[remoData objectForKey:[dataSelect titleOfSelectedItem]] count] / 4;
		[self mkirdata:signalcount];
		
		// generate and send data
		gen_size = genir_crossam2(1, signalcount, pat , cmddata, sizeof(cmddata));
		int i;
		for(i = 0; i < gen_size; ++i) {
			printf("%02x ", cmddata[i]);
			if((i + 1) % 16 == 0)
				printf("\n");
		}
		printf("\n");
		[patView setIrPattern:1 pat:pat];
		[patView setNeedsDisplay:YES];
		crossam2_write([dialSelect selectedSegment],[buttonItems indexOfObject:[[buttonSelect selectedItem] title]], cmddata, gen_size);	
	} else {
		[self nodata];
	}
}

- (IBAction)crossam2Push:(id)sender
{
	crossam2_pushkey([dialSelect selectedSegment],
					 [buttonItems indexOfObject:[[buttonSelect selectedItem] title]]);
}

//
// PC-OP-RS1 code
//

- (void)setPort:(int)port
{
	[pcopes1LEDSelect setSelectedSegment:port];
}

- (void) transferTask
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	pcoprs1_transfer(1, data);

	[pool release];
	[NSThread exit];
}

- (void) receiveTask
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if(pcoprs1_receive_start()) {
		while(pcoprs1_receive_data(data) == 0) {
			if(isPcoprs1Receive == NO)
				break;
		}
		int i, j, k;
/*		for(j = 0; j < 15; ++j) {
			for(i = 0; i < 16; ++i) {
				printf("%02x ", data[j * 16 + i]);
			}
			printf("\n");
		}*/
		int lastbit = 1;
		int bitcount = 0;
		int onecount;
		int val[128][2];
		k = 0;
		for(j = 0; j < 240; ++j) {
			for(i = 0; i <8 ; ++i) {
				if(((data[j] >> i) & 1) != lastbit) {
					if(lastbit == 1) {
						onecount = bitcount;
					} else {
						if(k < 128) {
//							printf("%d %d %d\n", k, onecount, bitcount);
							val[k][0] = onecount;
							val[k][1] = bitcount;
							++k;
						}
					}
					bitcount = 1;
				} else {
					++bitcount;
				}
				lastbit = (data[j] >> i) & 1;
			}
		}

		int blocklen;
		// check block length
		for(i = 1; i < k; ++i) {
			if(val[i][0] + val[i][1] > 100) {
				blocklen = i;
				printf("bitblock length %d\n", blocklen);
				break;				
			}
		}

		// byte block check
		int hasByteBlock = 0;
		if(val[9][0] * 4 < val[9][1]) {
			hasByteBlock = 1;
			printf("hasByteBlock true\n");
		}

		// check signal type
		int signaltype;
		for(i = 1; i < blocklen; ++i) {
			if(val[i][0] + val[i][1] < 30 &&
			   val[i][0] > val[i][1] * 16 / 10) {
				printf("maybe sony\n");
				signaltype = 1;
				// no stop bit
				++blocklen;
				break;
			}
			if(val[i][0] + val[i][1] < 30 &&
			   val[i][0] * 16 / 10 < val[i][1]) {
				if(hasByteBlock == 1) {
					printf("maybe mitsubishi\n");
					signaltype = 3;
					break;
				} else if(blocklen == 33) {
					printf("maybe nec\n");
					signaltype = 2;
					break;
				} else if(blocklen == 49) {
					printf("maybe sharp\n");
					signaltype = 4;
					break;
				} else {
					printf("unkown type\n");
					signaltype = 0;
					break;
				}
			}
		}

		unsigned char cmd[8];
		j = 0;
		for(i = 0; i < sizeof(cmd); ++i) {
			cmd[i] = 0;
		}
		for(i = 1; i < blocklen; ++i) {
			if(signaltype == 1) {
				if(i == blocklen - 1) {
					if(val[i][0] > val[i-1][1] * 16 / 10)
						cmd[j / 8] |= 1 << (7 - j % 8);
				} else {
					if(val[i][0] > val[i][1] * 16 / 10)
						cmd[j / 8] |= 1 << (7 - j % 8);
				}
				++j;
			}
			if(signaltype == 2) {
				if(val[i][0] * 16 / 10 < val[i][1] ) {
					cmd[j / 8] |= 1 << (7 - j % 8);
				}
				++j;
			}
			if(signaltype == 3) {
				if(i % 9 != 0) {
					if(val[i][0] * 16 / 10 < val[i][1] ) {
						cmd[j / 8] |= 1 << (7 - j % 8);
					}
					++j;
				}
			}
			if(signaltype == 4) {
				if(val[i][0] * 16 / 10 < val[i][1] ) {
					cmd[j / 8] |= 1 << (7 - j % 8);
				}
				++j;
			}
		}
		printf("bit length: %d\n", j);
		for(i = 0; i < (j + 7)/ 8; ++i) {
			printf("%02x ", cmd[i]);
		}
		printf("\n");
	}
	[pcoprs1RecvButton setTitle:@"Recv"];
	isPcoprs1Receive = NO;
	
	[waitTimer stopAnimation:self];
	[waitTimer setHidden:YES];

	[pool release];
	[NSThread exit];
}

//

- (IBAction)pcoprs1Init:(id)sender
{
	NSString *portName;
	portName = nil;
	portName = [[pcoprs1DevSelect selectedItem] title];

	if(portName != nil && pcoprs1_init((CFStringRef)portName)) {
		[pcoprs1InitButton setEnabled: NO];
		[pcoprs1TransButton setEnabled: YES];
		[pcoprs1LEDButton setEnabled: YES];
		[pcoprs1RecvButton setEnabled: YES];
	}
}

- (IBAction)pcoprs1LED:(id)sender
{
	pcoprs1_led();
}

- (IBAction)pcoprs1Recv:(id)sender
{
	if(isPcoprs1Receive == NO) {
		[waitTimer setHidden:NO];
		[waitTimer startAnimation:self];
		isPcoprs1Receive = YES;	
		[NSThread detachNewThreadSelector:@selector(receiveTask) toTarget:self
						   withObject:nil];
		[pcoprs1RecvButton setTitle:@"Cancel"];
	} else {
		isPcoprs1Receive = NO;
		pcoprs1_receive_cancel();
	}
}

- (IBAction)pcoprs1Trans:(id)sender
{

	unsigned char cmddata[240];
	int gen_size;

	int signalcount;
	if(remoCodeCount) {
		signalcount = [[remoData objectForKey:[dataSelect titleOfSelectedItem]] count] / 4;
		[self mkirdata:signalcount];

		// generate and send data
		gen_size = genir_pcoprs1(signalcount, pat , cmddata);
		[patView setIrPattern:1 pat:pat];
		[patView setNeedsDisplay:YES];
		printf("genir_bitbang size = %d\n",gen_size);
		pcoprs1_transfer([pcopes1LEDSelect selectedSegment]+1, cmddata);
	} else {
		[self nodata];
	}
}

// 
// FT Bit Bang code
//

- (IBAction)ftbitbangInit:(id)sender
{
	if([ftbitbangInitButton isEnabled] ==YES && 
	   bitbang_init([ftbitbangDevSelect indexOfSelectedItem])) {
		[ftbitbangInitButton setEnabled: NO];
		[ftbitbangTransButton setEnabled: YES];
	}
}

- (IBAction)ftbitbangTrans:(id)sender
{
	unsigned char cmddata[1024*128];
	int gen_size;
	int signalcount;
	if(remoCodeCount) {
		signalcount = [[remoData objectForKey:[dataSelect titleOfSelectedItem]] count] / 4;
		[self mkirdata:signalcount];
		
		// generate and send data
		gen_size = genir_bitbang(signalcount, pat , cmddata, sizeof(cmddata));
		[patView setIrPattern:1 pat:pat];
		[patView setNeedsDisplay:YES];
		printf("genir_bitbang size = %d\n",gen_size);
		bitbang_transfer(gen_size, cmddata);
	} else {
		[self nodata];
	}
}

- (int)checktype:(irdata *)apat
{
	if(apat->format.start_h > 5000)
		return 2;
	else if(apat->format.start_h > 3000)
		return 1;
	
	return 3;
}

- (IBAction)remoconTrans:(id)sender
{
	unsigned char cmddata[6];
	int signalcount;
	int i, j, len;
	
	if(remoCodeCount) {
		signalcount = [[remoData objectForKey:[dataSelect titleOfSelectedItem]] count] / 4;
		irdata *patptr = (irdata *)malloc(sizeof(irdata) * signalcount);
		pat = patptr;
		[self mkirdata:signalcount];
		len = 0;
		j = 0;
//		for(j = 0; j < signalcount; ++j) {
			NSString *theData = [[remoData objectForKey:[dataSelect titleOfSelectedItem]] objectAtIndex:(j * 4 + 3)];
			for(i = 0; i < [theData length] / 2; ++i) {
				if(len < 6) {
					unsigned char b = hex2Int((char *)[theData cStringUsingEncoding:NSASCIIStringEncoding]+i*2);
					// reverse bit
					b = ((b * 0x0802LU & 0x22110LU) | (b * 0x8020LU & 0x88440LU)) * 0x10101LU >> 16; 
					cmddata[len] = b;
					++len;
				}
			}
//		}
		remocon_transfer(remoBits[0]/4, [self checktype:pat], cmddata);
	} else {
		[self nodata];
	}
}

- (IBAction)btmsp430Open:(id)sender
{
	if(btmsp430 == nil)
		btmsp430 = [[BTMSP430 alloc] init];

	if ( [btmsp430 openSerialPortProfile] )
	{
		// if openSerialPortProfile is successful the connection is open or at
		// least in the process of opening. So we disable the "Open" button. The
		// button will be re-enabled if the open process fails or when the
		// connection is closed.
		[btmsp430OpenButton setEnabled:FALSE];
		[btmsp430CloseButton setEnabled:TRUE];
		[btmsp430TransButton setEnabled:TRUE];
	}
	
}

- (IBAction)btmsp430Close:(id)sender
{
	// The button did its job until we open a new connection we do not need to re-enable it:
	[btmsp430CloseButton setEnabled:FALSE];
	[btmsp430TransButton setEnabled:FALSE];
	[btmsp430OpenButton setEnabled:TRUE];
	
	// Do the real work to close the connection:
	[btmsp430 close];
}

- (IBAction)btmsp430Trans:(id)sender
{
	int rep;
	int signalcount;
	if(remoCodeCount) {
		signalcount = [[remoData objectForKey:[dataSelect titleOfSelectedItem]] count] / 4;
		[self mkirdata:signalcount];
		NSString *theData = [[remoData objectForKey:[dataSelect titleOfSelectedItem]] objectAtIndex:(3)];
		rep = atoi((char *)[[[remoData objectForKey:[dataSelect titleOfSelectedItem]] objectAtIndex:(0)]
					  cStringUsingEncoding:NSASCIIStringEncoding]);
		[btmsp430 send:[self checktype:pat] len:remoBits[0] data:theData repeat:rep];
	} else {
		[self nodata];
	}
}

- (IBAction)irkitTrans:(id)sender
{
	char cmddata[1024*32];
	int signalcount;
	IRKit *ir;

	if(remoCodeCount) {
		signalcount = [[remoData objectForKey:[dataSelect titleOfSelectedItem]] count] / 4;
		[self mkirdata:signalcount];
		
		// generate and send data
		if(genir_irkit(signalcount, pat , cmddata, sizeof(cmddata)) != -1) {
			[patView setIrPattern:1 pat:pat];
			[patView setNeedsDisplay:YES];
			
			ir = [[IRKit alloc] init];
			[ir send:[NSString stringWithCString:(char *)cmddata encoding:NSUTF8StringEncoding]
				host:[irkitHost stringValue]];
		}
	} else {
		[self nodata];
	}
}

//
// Load XML IR data file
//

- (IBAction)xmlLoad:(id)sender
{
	NSOpenPanel *opPanel = [ NSOpenPanel openPanel ];
	NSArray *xmlTypes = [ NSArray arrayWithObjects : @"xml",nil ];
	
	int	 opRet;

	opRet = [ opPanel runModalForTypes : xmlTypes];
	
	if ( opRet == NSOKButton ) {
//		xmlFilePath = [opPanel filename];
		xmlFilePath = [[NSString stringWithString:[opPanel filename]] retain];
		// load data from xml
		remoCodeCount = 0;
		remoFrameCount = 0;
		if(remoData == nil)
			remoData = [[NSMutableDictionary alloc] init];
		else
			[remoData removeAllObjects];
		[self readData:xmlFilePath];

		[dataSelect removeAllItems];
//		for (id key in remoData)
//			[dataSelect addItemWithTitle:key];
		NSLog(@"%@", remoData);
		NSEnumerator *enumerator = [remoData keyEnumerator];
		id key;

		while ((key = [enumerator nextObject])) {
			[dataSelect addItemWithTitle:key];
		}
	} 
}

//
// apple script support method
//

- (void) openxml:(NSString *)path
{
//	NSLog(@"loadxml = %@", path);
//	NSAutoreleasePool* pool;
//	pool = [[NSAutoreleasePool alloc]init];
	// Todo add file check
	xmlFilePath = [[NSString stringWithString:path] retain];
	// load data from xml
	remoCodeCount = 0;
	remoFrameCount = 0;
	if(remoData == nil)
		remoData = [[NSMutableDictionary alloc] init];
	else
		[remoData removeAllObjects];
	[self readData:xmlFilePath];
	
	[dataSelect removeAllItems];
//	for (id key in remoData)
//		[dataSelect addItemWithTitle:key];
	NSEnumerator *enumerator = [remoData keyEnumerator];
	id key;

	NSLog(@"%@", remoData);
	while ((key = [enumerator nextObject])) {
		[dataSelect addItemWithTitle:key];
	}
	
//	[pool release];
//	[NSThread exit];
}

- (void) setTab:(int)tab
{
	[ tabView selectTabViewItemAtIndex: tab ];	
}

- (int) getTab
{
	return [ tabView indexOfTabViewItem: [tabView selectedTabViewItem]];
}

- (void) setCommand:(NSString *)command
{
	if([dataSelect indexOfItemWithTitle:command] != -1) {
		[ dataSelect selectItemWithTitle:command ];
	}
}

//
// for prefernce
//

- (void) getPrefernce
{
	CFStringRef appName = CFSTR("jp.ddo.ellington.Armadillo");
	CFStringRef windowFrameKey = CFSTR("Window Frame");
	CFStringRef tabSelectedKey = CFSTR("Tab Selected");
	CFStringRef patternDisplayKey = CFSTR("Pattern Display");
	CFStringRef crossamPortKey = CFSTR("Crossam2 Port");
	CFStringRef pcoprs1PortKey = CFSTR("PC-OP-RS1 Port");
	CFStringRef xmlFileKey = CFSTR("XML File");
	CFStringRef irkithostKey = CFSTR("IRKit Host");
	CFStringRef strvalue;
	
	strvalue = CFPreferencesCopyAppValue(windowFrameKey, appName);
	if(strvalue) {
		[ mainWindow setFrameFromString: (NSString *)strvalue ];
		CFRelease(strvalue);
	}
	CFNumberRef numvalue;
	numvalue = CFPreferencesCopyAppValue(tabSelectedKey, appName);
	if(numvalue) {
		int ret;
		CFNumberGetValue(numvalue, kCFNumberIntType, &ret);
		[ tabView selectTabViewItemAtIndex: ret ];
		CFRelease(numvalue);
	}
	numvalue = CFPreferencesCopyAppValue(patternDisplayKey, appName);
	if(numvalue) {
		int ret;
		CFNumberGetValue(numvalue, kCFNumberIntType, &ret);
		if(ret == 0) {
			[disclosureButton setIntValue:ret];
			NSRect frame = [mainWindow frame];
			frame.size.height -= 120;
//			frame.origin.y += 120;
			[mainWindow setFrame:frame display:NO animate:NO];
		}
		CFRelease(numvalue);
	}
	if([crossam2DevSelect numberOfItems] != 0) {
		strvalue = CFPreferencesCopyAppValue(crossamPortKey, appName);
		if(strvalue) {
			[ crossam2DevSelect selectItemWithTitle: (NSString *)strvalue ];
			CFRelease(strvalue);
		}
	}

	if([pcoprs1DevSelect numberOfItems] != 0) {
		strvalue = CFPreferencesCopyAppValue(pcoprs1PortKey, appName);
		if(strvalue) {
			[ pcoprs1DevSelect selectItemWithTitle: (NSString *)strvalue ];
			CFRelease(strvalue);
		}
	}
	
	strvalue = CFPreferencesCopyAppValue(xmlFileKey, appName);
	if(strvalue) {
		xmlFilePath = [[NSString stringWithString:(NSString *)strvalue] retain];
		// load data from xml
		remoCodeCount = 0;
		remoFrameCount = 0;
		if(remoData == nil)
			remoData = [[NSMutableDictionary alloc] init];
		else
			[remoData removeAllObjects];
		[self readData:xmlFilePath];
		
		[dataSelect removeAllItems];
//		for (id key in remoData)
//			[dataSelect addItemWithTitle:key];
		NSEnumerator *enumerator = [remoData keyEnumerator];
		id key;
		
		while ((key = [enumerator nextObject])) {
			[dataSelect addItemWithTitle:key];
		}
		
		CFRelease(strvalue);
	}
	
	strvalue = CFPreferencesCopyAppValue(irkithostKey, appName);
	if(strvalue) {
		[irkitHost setStringValue:(NSString *)strvalue];
		CFRelease(strvalue);
	}
}

- (void) savePrefernce
{
	CFStringRef appName = CFSTR("jp.ddo.ellington.Armadillo");
	CFStringRef windowFrameKey = CFSTR("Window Frame");
	CFStringRef tabSelectedKey = CFSTR("Tab Selected");
	CFStringRef patternDisplayKey = CFSTR("Pattern Display");
	CFStringRef crossamPortKey = CFSTR("Crossam2 Port");
	CFStringRef pcoprs1PortKey = CFSTR("PC-OP-RS1 Port");
	CFStringRef xmlFileKey = CFSTR("XML File");
	CFStringRef irkithostKey = CFSTR("IRKit Host");

	CFPreferencesSetAppValue(windowFrameKey, (CFStringRef)[ mainWindow 
														   stringWithSavedFrame], appName);
	int intnum = [ tabView indexOfTabViewItem: [tabView selectedTabViewItem]];
	CFNumberRef numRef = CFNumberCreate(NULL, kCFNumberIntType, &intnum);
	if(numRef) {
		CFPreferencesSetAppValue(tabSelectedKey, numRef, appName);
		CFRelease(numRef);
	}

	intnum = [ disclosureButton intValue];
	numRef = CFNumberCreate(NULL, kCFNumberIntType, &intnum);
	if(numRef) {
		CFPreferencesSetAppValue(patternDisplayKey, numRef, appName);
		CFRelease(numRef);
	}
	
	CFPreferencesSetAppValue(crossamPortKey, (CFStringRef)[ crossam2DevSelect  
														   titleOfSelectedItem], appName);
	CFPreferencesSetAppValue(pcoprs1PortKey, (CFStringRef)[ pcoprs1DevSelect  
														   titleOfSelectedItem], appName);

	if(xmlFilePath != nil)
		CFPreferencesSetAppValue(xmlFileKey, (CFStringRef)xmlFilePath, appName);

	CFPreferencesSetAppValue(irkithostKey, (CFStringRef)[ irkitHost  
														   stringValue], appName);
	(void)CFPreferencesAppSynchronize(appName);
}

- (IBAction)disclosureControls:sender
{
    NSRect frame = [mainWindow frame];
	switch([sender state]) {
        case NSOnState:
			frame.size.height += 120;
			frame.origin.y -= 120;
            break;
        case NSOffState:
			frame.size.height -= 120;
			frame.origin.y += 120;
            break;
        default:
            break;
    }
    [mainWindow setFrame:frame display:YES animate:YES];
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSMutableArray *ifList = [[ NSMutableArray alloc ] init];
	NSMutableArray *ftList = [[ NSMutableArray alloc ] init];
	
    io_iterator_t	serialPortIterator;
    FindModems(&serialPortIterator);
    GetModemPath(serialPortIterator, (CFMutableArrayRef)ifList);
    bitbang_list((CFMutableArrayRef)ftList);
    IOObjectRelease(serialPortIterator);	// Release the iterator.
	NSLog(@"%@", ifList);
    // add device path to menu
	
//    [ crossam2DevSelect removeAllItems ];
//    [ pcoprs1DevSelect removeAllItems ];
    if([ ifList count]) {
        [ crossam2DevSelect addItemsWithTitles : ifList];
        [ crossam2DevSelect setEnabled : true];
        [ pcoprs1DevSelect addItemsWithTitles : ifList];
        [ pcoprs1DevSelect setEnabled : true];
    } else {
        [ crossam2InitButton setEnabled : false];
        [ pcoprs1InitButton setEnabled : false];
        [ crossam2DevSelect setEnabled : false];
        [ pcoprs1DevSelect setEnabled : false];
    }
    if([ ftList count]) {
        [ ftbitbangDevSelect addItemsWithTitles : ftList];
        [ ftbitbangDevSelect setEnabled : true];
    } else {
        [ ftbitbangInitButton setEnabled : false];
        [ ftbitbangDevSelect setEnabled : false];
    }
	if(remocon_init()) {
        [ remoconTransButton setEnabled : true];
	}
	
	[self getPrefernce];
	
	[ mainWindow makeKeyAndOrderFront:nil];
}

- (void) applicationWillTerminate:(NSNotification *)aNotification
{
	if([ftbitbangInitButton isEnabled] == NO)
		bitbang_close();

	if([remoconTransButton isEnabled] == YES)
		remocon_close();

	[self savePrefernce];
}
@end
