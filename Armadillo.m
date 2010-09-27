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

// http://www.cocoadev.com/index.pl?UsingTheAppleRemoteControl

#include <IOKit/IOCFPlugIn.h>
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/hid/IOHIDKeys.h>

void print_errmsg_if_io_err(int expr, char *msg)
{
	IOReturn err = (expr);
	if (err != kIOReturnSuccess) {
		fprintf(stderr, "%s - %s(%x,%d)\n", msg,
				mach_error_string(err),
				err, err & 0xffffff);
		fflush(stderr);
//		exit(EX_OSERR);
	}
}

void print_errmsg_if_err(int expr, char *msg)
{
	if (expr) {
		fprintf(stderr, "%s\n", msg);
		fflush(stderr);
//		exit(EX_OSERR);
	}
}

typedef struct cookie_struct
	{
		IOHIDElementCookie volumeCookie;
		IOHIDElementCookie menuCookie;
		IOHIDElementCookie playCookie;
		IOHIDElementCookie skipRightCookie;
		IOHIDElementCookie skipLeftCookie;
	} *cookie_struct_t;

static void MyTestHIDDeviceInterface(IOHIDDeviceInterface **hidDeviceInterface, cookie_struct_t cookies)
{
	IOReturn ioReturnValue = kIOReturnSuccess;
	
	//open the device
	ioReturnValue = (*hidDeviceInterface)->open(hidDeviceInterface, 0);
	//printf("Open result = %d\n", ioReturnValue);
	
	//test queue interface
	MyTestQueues(hidDeviceInterface, cookies);
	
	//test the interface
	//	MyTestHIDInterface(hidDeviceInterface, cookies);
	
	//close the device
	if (ioReturnValue == KERN_SUCCESS)
		ioReturnValue = (*hidDeviceInterface)->close(hidDeviceInterface);
	
	//release the interface
	(*hidDeviceInterface)->Release(hidDeviceInterface);
}

void MyTestQueues(IOHIDDeviceInterface **hidDeviceInterface, cookie_struct_t cookies)
{
	HRESULT 						result;
	IOHIDQueueInterface **						queue;
	Boolean						hasElement;
	long						index;
	IOHIDEventStruct						event;
	
	queue = (*hidDeviceInterface)->allocQueue(hidDeviceInterface);
	
	if (queue)
	{
		//printf("Queue allocated: %lx\n", (long) queue);
		//create the queue
		result = (*queue)->create(queue,
								  0,
								  8);	/* depth: maximum number of elements
		 in queue before oldest elements in 
		 queue begin to be lost. */
		//printf("Queue create result: %lx\n", result);
		
		//add elements to the queue
		(*queue)->addElement(queue, cookies->volumeCookie, 0);
		(*queue)->addElement(queue, cookies->menuCookie, 0);
		(*queue)->addElement(queue, cookies->playCookie, 0);
		(*queue)->addElement(queue, cookies->skipRightCookie, 0);
		(*queue)->addElement(queue, cookies->skipLeftCookie, 0);
		
		//start data delivery to queue
		(*queue)->start(queue);
		
		
		//check queue a few times to see accumulated events
		sleep(1);
		printf("Checking queue\n");
		for (index = 0; index < 100; index++)
		{
			// printf("Queue iteration %d\n", index);
			AbsoluteTime				zeroTime = {0,0};
			
			result = (*queue)->getNextEvent(queue, &event, zeroTime, 0);
			if (!result)
			{
				
				if (event.elementCookie == cookies->volumeCookie)
					printf("Volume");
				else if (event.elementCookie == cookies->skipRightCookie)
					printf("Skip Right");
				else if (event.elementCookie == cookies->playCookie)
					printf("play");
				else if (event.elementCookie == cookies->menuCookie)
					printf("Menu");
			    else if (event.elementCookie == cookies->skipLeftCookie)
					printf("Skip Left");
			    else
				{
					printf("Queue: event:[%lx] %ld\n", 
						   (unsigned long) event.elementCookie,
						   event.value);
					printf("Cookie val = %d\n", (unsigned long) event.elementCookie); 
				}
				printf(" %d\n", event.value);
				
			}
			
			sleep(1);
		}
		
		//stop data delivery to queue
		result = (*queue)->stop(queue);
		printf("Queue stop result: %lx\n", result);
		
		//dispose of queue
		result = (*queue)->dispose(queue);
		printf("Queue dispose result: %lx\n", result);
		
		//release the queue we allocated
		(*queue)->Release(queue);
	}
}

cookie_struct_t getHIDCookies(IOHIDDeviceInterface122 **handle)
{
	cookie_struct_t cookies = memset(malloc(sizeof(*cookies)), 0, sizeof(*cookies));
	CFTypeRef					object;
	long					number;
	IOHIDElementCookie					cookie;
	long					usage;
	long					usagePage;
	CFArrayRef				elements;
	CFDictionaryRef				element;
	IOReturn success;
	
	if (!handle || !(*handle)) return cookies;
	
	// Copy all elements, since we're grabbing most of the elements
	// for this device anyway, and thus, it's faster to iterate them
	// ourselves. When grabbing only one or two elements, a matching
	// dictionary should be passed in here instead of NULL.
	success = (*handle)->copyMatchingElements(handle, NULL, &elements);
	
	//printf("LOOKING FOR ELEMENTS.\n");
	if (success == kIOReturnSuccess) {
		CFIndex i;
		//printf("ITERATING...\n");
		for (i=0; i<CFArrayGetCount(elements); i++)
		{
			element = CFArrayGetValueAtIndex(elements, i);
			//printf("GOT ELEMENT.\n");
			
			//Get cookie
			object = (CFDictionaryGetValue(element, CFSTR(kIOHIDElementCookieKey)));
			if (object == 0 || CFGetTypeID(object) != CFNumberGetTypeID())
				continue;
			if(!CFNumberGetValue((CFNumberRef) object, kCFNumberLongType, &number))
				continue;
			cookie = (IOHIDElementCookie) number;
			
			//Get usage
			object = CFDictionaryGetValue(element, CFSTR(kIOHIDElementUsageKey));
			if (object == 0 || CFGetTypeID(object) != CFNumberGetTypeID())
				continue;
			if (!CFNumberGetValue((CFNumberRef) object, kCFNumberLongType, &number))
				continue;
			usage = number;
			
			//Get usage page
			object = CFDictionaryGetValue(element,CFSTR(kIOHIDElementUsagePageKey));
			if (object == 0 || CFGetTypeID(object) != CFNumberGetTypeID())
				continue;
			if (!CFNumberGetValue((CFNumberRef) object, kCFNumberLongType, &number))
				continue;
			usagePage = number;
			
 			if (usage == -1 && usagePage == 1)
				cookies->volumeCookie = cookie;
			else if (usage == 134 && usagePage == 1)
				cookies->menuCookie = cookie;
			else if (usage == 137  && usagePage == 1)
				cookies->playCookie = cookie;
			else if (usage == 138  && usagePage == 1)
				cookies->skipRightCookie = cookie;
			else if (usage == 139 && usagePage == 1)
				cookies->skipLeftCookie = cookie;
			
			
		}
	} else {
		printf("copyMatchingElements failed with error %d\n", success);
	}
	
	return cookies;
}

static void MyCreateHIDDeviceInterface(io_object_t hidDevice,
									   IOHIDDeviceInterface ***hidDeviceInterface)
{
	io_name_t						className;
	IOCFPlugInInterface						**plugInInterface = NULL;
	HRESULT						plugInResult = S_OK;
	SInt32						score = 0;
	IOReturn						ioReturnValue = kIOReturnSuccess;
	
	ioReturnValue = IOObjectGetClass(hidDevice, className);
	
	print_errmsg_if_io_err(ioReturnValue, "Failed to get class name.");
	
	printf("Found device type %s\n", className);
	
	ioReturnValue = IOCreatePlugInInterfaceForService(hidDevice,
													  kIOHIDDeviceUserClientTypeID,
													  kIOCFPlugInInterfaceID,
													  &plugInInterface,
													  &score);
	
	if (ioReturnValue == kIOReturnSuccess)
	{
		//Call a method of the intermediate plug-in to create the device 
		//interface
		plugInResult = (*plugInInterface)->QueryInterface(plugInInterface,
														  CFUUIDGetUUIDBytes(kIOHIDDeviceInterfaceID),
														  (LPVOID) hidDeviceInterface);
		print_errmsg_if_err(plugInResult != S_OK, "Couldn't create HID class device interface");
		
		(*plugInInterface)->Release(plugInInterface);
	}
}

void MyTestHIDDevices(io_iterator_t hidObjectIterator)
{
	io_object_t						hidDevice = NULL;
	IOHIDDeviceInterface						**hidDeviceInterface = NULL;
	IOReturn						ioReturnValue = kIOReturnSuccess;
	
	while ((hidDevice = IOIteratorNext(hidObjectIterator)))
	{
		cookie_struct_t cookies;
		
		MyCreateHIDDeviceInterface(hidDevice, &hidDeviceInterface);
		
		cookies = getHIDCookies((IOHIDDeviceInterface122 **)hidDeviceInterface);
		ioReturnValue = IOObjectRelease(hidDevice);
		print_errmsg_if_io_err(ioReturnValue, "Error releasing HID device");
		if (hidDeviceInterface != NULL)
		{
			MyTestHIDDeviceInterface(hidDeviceInterface, cookies);
			(*hidDeviceInterface)->Release(hidDeviceInterface);
		}
		
	}
	IOObjectRelease(hidObjectIterator);
}

void MyFindHIDDevices(mach_port_t masterPort,
					  io_iterator_t *hidObjectIterator)
{
    CFMutableDictionaryRef hidMatchDictionary = NULL;
    IOReturn ioReturnValue = kIOReturnSuccess;
    Boolean noMatchingDevices = false;
    
    // Set up a matching dictionary to search the I/O Registry by class
	// name for all HID class devices
	hidMatchDictionary = IOServiceMatching("AppleIRController");//ANDYkIOHIDDeviceKey);
	
 	// Now search I/O Registry for matching devices.
 	ioReturnValue = IOServiceGetMatchingServices(masterPort, 
												 hidMatchDictionary, hidObjectIterator);
	
 	noMatchingDevices = ((ioReturnValue != kIOReturnSuccess) 
						 | (*hidObjectIterator == NULL));
	
	//If search is unsuccessful, print message and hang.
	if (noMatchingDevices)
		print_errmsg_if_err(ioReturnValue, "No matching HID class devices found.");
	
 	// IOServiceGetMatchingServices consumes a reference to the
 	//   dictionary, so we don't need to release the dictionary ref.
 	hidMatchDictionary = NULL;
}

@implementation Armadillo

- (void) appleRemote
{
	io_iterator_t hidObjectIterator = NULL;
	IOReturn ioReturnValue = kIOReturnSuccess;
	
	MyFindHIDDevices(kIOMasterPortDefault, &hidObjectIterator);
	if (hidObjectIterator != NULL)
	{
		MyTestHIDDevices(hidObjectIterator);
		
		//Release iterator. Don't need to release iterator objects.
		IOObjectRelease(hidObjectIterator);
	}
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
		[NSThread detachNewThreadSelector:@selector(appleRemote) toTarget:self
							   withObject:nil];
    }
    return self;
}

// parser for as follow site data
// http://www.256byte.com/remocon/iremo_db.php

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
}

//
// Crossam2 Debug code
//

- (IBAction)crossam2Init:(id)sender
{
	NSMutableArray *ifList;
	NSMutableString *portName;
	portName = nil;
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
			crossam2_patch();
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
	int signalcount, codeIndex, frameIndex;
	int i, j;
	NSLog(@"%d %d", [dialSelect selectedSegment], 
		  [buttonItems indexOfObject:[[buttonSelect selectedItem] title]]);

	if(remoCodeCount) {
		signalcount = [[remoData objectForKey:[dataSelect titleOfSelectedItem]] count] / 4;
		irdata *patptr = (irdata *)malloc(sizeof(irdata) * signalcount);
		pat = patptr;
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
			NSLog(@"%d %d %d %@ %d %d", patptr->repeat, codeIndex, frameIndex, theData, [theData length], remoBits[frameIndex]);
			++patptr;
		}
		
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
		NSRunAlertPanel( @"データがロードされていません" , @"XMLデータファイルをロードしてください。" , NULL , NULL , NULL );
	}


}

- (IBAction)crossam2Push:(id)sender
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
			if(isPcoprs1Receive == NO)
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
	[pcoprs1RecvButton setTitle:@"Recv"];

	[waitTimer stopAnimation:self];
	[waitTimer setHidden:YES];
}

//

- (IBAction)pcoprs1Init:(id)sender
{
	NSMutableArray *ifList;
	NSMutableString *portName;
	portName = nil;
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

	int signalcount, codeIndex, frameIndex;
	int i, j;
	if(remoCodeCount) {
		signalcount = [[remoData objectForKey:[dataSelect titleOfSelectedItem]] count] / 4;
		irdata *patptr = (irdata *)malloc(sizeof(irdata) * signalcount);
		pat = patptr;
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
			NSLog(@"%d %d %d %@ %d %d", patptr->repeat, codeIndex, frameIndex, theData, [theData length], remoBits[frameIndex]);
			++patptr;
		}
		
		// generate and send data
		gen_size = genir_pcoprs1(signalcount, pat , cmddata);
		[patView setIrPattern:1 pat:pat];
		[patView setNeedsDisplay:YES];
		printf("genir_bitbang size = %d\n",gen_size);
		pcoprs1_transfer(gen_size, cmddata);
	} else {
		NSRunAlertPanel( @"データがロードされていません" , @"XMLデータファイルをロードしてください。" , NULL , NULL , NULL );
	}
}

// 

- (IBAction)ftbitbangInit:(id)sender
{
	if(bitbang_init()) {
		[ftbitbangInitButton setEnabled: NO];
		[ftbitbangTransButton setEnabled: YES];
	}
}

- (IBAction)ftbitbangTrans:(id)sender
{
	unsigned char cmddata[1024*128];
	int gen_size;
	int signalcount, codeIndex, frameIndex;
	int i, j;
	if(remoCodeCount) {
		signalcount = [[remoData objectForKey:[dataSelect titleOfSelectedItem]] count] / 4;
		irdata *patptr = (irdata *)malloc(sizeof(irdata) * signalcount);
		pat = patptr;
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
			NSLog(@"%d %d %d %@ %d %d", patptr->repeat, codeIndex, frameIndex, theData, [theData length], remoBits[frameIndex]);
			++patptr;
		}
		
		// generate and send data
		gen_size = genir_bitbang(signalcount, pat , cmddata, sizeof(cmddata));
		[patView setIrPattern:1 pat:pat];
		[patView setNeedsDisplay:YES];
		printf("genir_bitbang size = %d\n",gen_size);
		bitbang_transfer(gen_size, cmddata);
	} else {
		NSRunAlertPanel( @"データがロードされていません" , @"XMLデータファイルをロードしてください。" , NULL , NULL , NULL );
	}
}

- (IBAction)xmlLoad:(id)sender
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
		remoCodeCount = 0;
		remoFrameCount = 0;
		remoData = [[NSMutableDictionary alloc] init];
		[self readData:filepath];

		[dataSelect removeAllItems];
		for (id key in remoData)
			[dataSelect addItemWithTitle:key];
	} 
}
@end
