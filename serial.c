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

kern_return_t FindModems(io_iterator_t *matchingServices)
{
    kern_return_t		kernResult; 
    mach_port_t			masterPort;
    CFMutableDictionaryRef	classesToMatch;

/*! @function IOMasterPort
    @abstract Returns the mach port used to initiate communication with IOKit.
    @discussion Functions that don't specify an existing object require the IOKit master port to be passed. This function obtains that port.
    @param bootstrapPort Pass MACH_PORT_NULL for the default.
    @param masterPort The master port is returned.
    @result A kern_return_t error code. */

    kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult)
    {
//        printf("IOMasterPort returned %d\n", kernResult);
	goto exit;
    }
        
/*! @function IOServiceMatching
    @abstract Create a matching dictionary that specifies an IOService class match.
    @discussion A very common matching criteria for IOService is based on its class. IOServiceMatching will create a matching dictionary that specifies any IOService of a class, or its subclasses. The class is specified by C-string name.
    @param name The class name, as a const C-string. Class matching is successful on IOService's of this class or any subclass.
    @result The matching dictionary created, is returned on success, or zero on failure. The dictionary is commonly passed to IOServiceGetMatchingServices or IOServiceAddNotification which will consume a reference, otherwise it should be released with CFRelease by the caller. */

    // Serial devices are instances of class IOSerialBSDClient
    classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    if (classesToMatch == NULL)
    {
//        printf("IOServiceMatching returned a NULL dictionary.\n");
    }
    else {
/*!
	@function CFDictionarySetValue
	Sets the value of the key in the dictionary.
	@param theDict The dictionary to which the value is to be set. If this
		parameter is not a valid mutable CFDictionary, the behavior is
		undefined. If the dictionary is a fixed-capacity dictionary and
		it is full before this operation, and the key does not exist in
		the dictionary, the behavior is undefined.
	@param key The key of the value to set into the dictionary. If a key 
		which matches this key is already present in the dictionary, only
		the value is changed ("add if absent, replace if present"). If
		no key matches the given key, the key-value pair is added to the
		dictionary. If added, the key is retained by the dictionary,
		using the retain callback provided
		when the dictionary was created. If the key is not of the sort
		expected by the key retain callback, the behavior is undefined.
	@param value The value to add to or replace into the dictionary. The value
		is retained by the dictionary using the retain callback provided
		when the dictionary was created, and the previous value if any is
		released. If the value is not of the sort expected by the
		retain or release callbacks, the behavior is undefined.
*/
        CFDictionarySetValue(classesToMatch,
                             CFSTR(kIOSerialBSDTypeKey),
                             CFSTR(kIOSerialBSDModemType));
        // Each serial device object has a property with key
        // kIOSerialBSDTypeKey and a value that is one of kIOSerialBSDAllTypes,
        // kIOSerialBSDModemType, or kIOSerialBSDRS232Type. You can experiment with the
        // matching by changing the last parameter in the above call to CFDictionarySetValue.
        
        // As shipped, this sample is only interested in modems,
        // so add this property to the CFDictionary we're matching on. 
        // This will find devices that advertise themselves as modems,
        // such as built-in and USB modems. However, this match won't find serial modems.
    }
    
    /*! @function IOServiceGetMatchingServices
        @abstract Look up registered IOService objects that match a matching dictionary.
        @discussion This is the preferred method of finding IOService objects currently registered by IOKit. IOServiceAddNotification can also supply this information and install a notification of new IOServices. The matching information used in the matching dictionary may vary depending on the class of service being looked up.
        @param masterPort The master port obtained from IOMasterPort().
        @param matching A CF dictionary containing matching information, of which one reference is consumed by this function. IOKitLib can contruct matching dictionaries for common criteria with helper functions such as IOServiceMatching, IOOpenFirmwarePathMatching.
        @param existing An iterator handle is returned on success, and should be released by the caller when the iteration is finished.
        @result A kern_return_t error code. */

    kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, matchingServices);    
    if (KERN_SUCCESS != kernResult)
    {
//        printf("IOServiceGetMatchingServices returned %d\n", kernResult);
	goto exit;
    }
        
exit:
    return kernResult;
}

#define MAXPATH 1024

kern_return_t GetModemPath(io_iterator_t serialPortIterator, CFMutableArrayRef interfaceList)
{
    io_object_t		modemService;
    kern_return_t	kernResult = KERN_FAILURE;
    Boolean		modemFound = false;
    char		bsdPath[MAXPATH];
    
    // Iterate across all modems found. In this example, we bail after finding the first modem.

//    interfaceList = CFArrayCreateMutable( NULL, 0, NULL );

    while ((modemService = IOIteratorNext(serialPortIterator)))
    {
        CFTypeRef	bsdPathAsCFString;

	// Get the callout device's path (/dev/cu.xxxxx). The callout device should almost always be
	// used: the dialin device (/dev/tty.xxxxx) would be used when monitoring a serial port for
	// incoming calls, e.g. a fax listener.
	
	bsdPathAsCFString = IORegistryEntryCreateCFProperty(modemService,
                                                            CFSTR(kIOCalloutDeviceKey),
                                                            kCFAllocatorDefault,
                                                            0);
        if (bsdPathAsCFString)
        {
            Boolean result;
            
            // Convert the path from a CFString to a C (NUL-terminated) string for use
	    // with the POSIX open() call.
	    
#if 1
            CFArrayAppendValue(interfaceList, bsdPathAsCFString);
#else
	    result = CFStringGetCString(bsdPathAsCFString,
                                        bsdPath,
                                        MAXPATH, 
                                        kCFStringEncodingASCII);
            CFRelease(bsdPathAsCFString);
            
            CFArrayAppendValue(interfaceList, bsdPath);
#endif
        }

//        printf("\n");

        // Release the io_service_t now that we are done with it.
	
	(void) IOObjectRelease(modemService);
    }
        
    return kernResult;
}

