/*
 *  appleremote.c
 *  Armadillo
 *
 *  Created by H.M on 10/09/28.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#include "appleremote.h"

// http://www.cocoadev.com/index.pl?UsingTheAppleRemoteControl

#include <stdio.h>
#include <unistd.h>
#include <mach/mach.h>
#include <mach/mach_error.h>
#include <IOKit/IOKitLib.h>
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

IOHIDQueueInterface **						queue;

void AppleRemoteQueuesStart(IOHIDDeviceInterface **hidDeviceInterface, cookie_struct_t cookies)
{
	HRESULT 					result;
	queue = (*hidDeviceInterface)->allocQueue(hidDeviceInterface);
	
	if (queue)
	{
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
	}
}
		
int AppleRemoteGetQueues(IOHIDDeviceInterface **hidDeviceInterface, cookie_struct_t cookies)
{
	int							eventkey = 0;
	HRESULT 					result;
	IOHIDEventStruct			event;
	//check queue a few times to see accumulated events
	AbsoluteTime				zeroTime = {0,0};
	
	result = (*queue)->getNextEvent(queue, &event, zeroTime, 0);
	if (!result)
	{
		if (event.elementCookie == cookies->playCookie && 
			event.value == 1) {
			eventkey = 1;
		} else if (event.elementCookie == cookies->skipLeftCookie && 
				   event.value == 1) {
			eventkey = 2;
		} else if (event.elementCookie == cookies->skipRightCookie && 
				   event.value == 1) {
			eventkey = 3;
		}
#if 0	
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
#endif
	}
	return eventkey;
}	

void AppleRemoteQueuesStop(IOHIDDeviceInterface **hidDeviceInterface, cookie_struct_t cookies)
{
HRESULT						result;

	//stop data delivery to queue
	result = (*queue)->stop(queue);
	printf("Queue stop result: %lx\n", result);
	
	//dispose of queue
	result = (*queue)->dispose(queue);
	printf("Queue dispose result: %lx\n", result);
	
	//release the queue we allocated
	(*queue)->Release(queue);
}


cookie_struct_t getHIDCookies(IOHIDDeviceInterface122 **handle)
{
	cookie_struct_t cookies = memset(malloc(sizeof(*cookies)), 0, sizeof(*cookies));
	CFTypeRef				object;
	long					number;
	IOHIDElementCookie		cookie;
	long					usage;
	long					usagePage;
	CFArrayRef				elements;
	CFDictionaryRef			element;
	IOReturn				success;
	
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

static void CreateHIDDeviceInterface(io_object_t hidDevice,
									   IOHIDDeviceInterface ***hidDeviceInterface)
{
	io_name_t					className;
	IOCFPlugInInterface			**plugInInterface = NULL;
	HRESULT						plugInResult = S_OK;
	SInt32						score = 0;
	IOReturn					ioReturnValue = kIOReturnSuccess;
	
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

IOHIDDeviceInterface						**hidDeviceInterface = NULL;
cookie_struct_t cookies;

void SetupAppleRemote(io_iterator_t hidObjectIterator)
{
	io_object_t						hidDevice;
	IOReturn						ioReturnValue = kIOReturnSuccess;
	
	hidDevice = IOIteratorNext(hidObjectIterator);
	
	CreateHIDDeviceInterface(hidDevice, &hidDeviceInterface);
	
	cookies = getHIDCookies((IOHIDDeviceInterface122 **)hidDeviceInterface);
	ioReturnValue = IOObjectRelease(hidDevice);
	
	print_errmsg_if_io_err(ioReturnValue, "Error releasing HID device");
	if (hidDeviceInterface != NULL)
	{
		IOReturn ioReturnValue = kIOReturnSuccess;
		
		//open the device
		ioReturnValue = (*hidDeviceInterface)->open(hidDeviceInterface, 0);
		//printf("Open result = %d\n", ioReturnValue);
		
	}	
}

void FindAppleRemote(mach_port_t masterPort,
					  io_iterator_t *hidObjectIterator)
{
    CFMutableDictionaryRef hidMatchDictionary = NULL;
    IOReturn ioReturnValue = kIOReturnSuccess;
    Boolean noMatchingDevices = false;
    
    // Set up a matching dictionary to search the I/O Registry by class
	// name for AppleIRController
	hidMatchDictionary = IOServiceMatching("AppleIRController");

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

//
//
//

io_iterator_t hidObjectIterator;

int appleremote_open()
{
	FindAppleRemote(kIOMasterPortDefault, &hidObjectIterator);
	if (hidObjectIterator != NULL)
	{
		SetupAppleRemote(hidObjectIterator);
		
		//Release iterator. Don't need to release iterator objects.
		AppleRemoteQueuesStart(hidDeviceInterface, cookies);
		return 1;
	}
	return 0;
}

int appleremote_getevent()
{
	return AppleRemoteGetQueues(hidDeviceInterface, cookies);
}

void appleremote_close()
{
	AppleRemoteQueuesStop(hidDeviceInterface, cookies);

	(*hidDeviceInterface)->close(hidDeviceInterface);
	
	//release the interface
	(*hidDeviceInterface)->Release(hidDeviceInterface);
	
	IOObjectRelease(hidObjectIterator);
}
