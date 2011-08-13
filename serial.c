/*
 *  serial.c
 *  zauask-osx
 *
 *  Created by Hiroki Mori on Sat Sep 11 2004.
 *  Copyright (c) 2004 Hiroki Mor. All rights reserved.
 *
 */

#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>

//#include <stdio.h>

kern_return_t FindModems(io_iterator_t *matchingServices)
{
    kern_return_t		kernResult; 
    mach_port_t			masterPort;
    CFMutableDictionaryRef	classesToMatch;

    kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult)
    {
//        printf("IOMasterPort returned %d\n", kernResult);
		goto exit;
    }

    // Serial devices are instances of class IOSerialBSDClient
    classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    if (classesToMatch == NULL)
    {
//        printf("IOServiceMatching returned a NULL dictionary.\n");
    }
    else {
        CFDictionarySetValue(classesToMatch,
                             CFSTR(kIOSerialBSDTypeKey),
//                             CFSTR(kIOSerialBSDModemType));
							 CFSTR(kIOSerialBSDRS232Type));
    }

    kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, matchingServices);    
    if (KERN_SUCCESS != kernResult)
    {
//        printf("IOServiceGetMatchingServices returned %d\n", kernResult);
	goto exit;
    }
        
exit:
    return kernResult;
}

kern_return_t GetModemPath(io_iterator_t serialPortIterator, CFMutableArrayRef interfaceList)
{
    io_object_t		modemService;
    kern_return_t	kernResult = KERN_FAILURE;
    
//	IOIteratorReset(serialPortIterator);
    while (modemService = IOIteratorNext(serialPortIterator))
    {
        CFTypeRef	bsdPathAsCFString;

		bsdPathAsCFString = IORegistryEntryCreateCFProperty(modemService,
                                                            CFSTR(kIOCalloutDeviceKey),
                                                            kCFAllocatorDefault,
                                                            0);

        if (bsdPathAsCFString)
        {
//			printf("MORI MORI %s\n",CFStringGetCStringPtr(bsdPathAsCFString, kCFStringEncodingMacRoman));
	    
            CFArrayAppendValue(interfaceList, bsdPathAsCFString);
        }


        // Release the io_service_t now that we are done with it.
	
		(void) IOObjectRelease(modemService);
    }
        
    return kernResult;
}

