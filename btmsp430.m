//  RFCOMM_Open_SPP_Example
//
//  Created by Marco Pontil on 12/18/04.
//  Copyright Apple Computer, Inc. 2004. All rights reserved.
//

/*
	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
	consideration of your agreement to the following terms, and your use, installation, 
	modification or redistribution of this Apple software constitutes acceptance of these 
	terms.  If you do not agree with these terms, please do not use, install, modify or 
	redistribute this Apple software.
	
	In consideration of your agreement to abide by the following terms, and subject to these 
	terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
	this original Apple software (the "Apple Software"), to use, reproduce, modify and 
	redistribute the Apple Software, with or without modifications, in source and/or binary 
	forms; provided that if you redistribute the Apple Software in its entirety and without 
	modifications, you must retain this notice and the following text and disclaimers in all 
	such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
	or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
	the Apple Software without specific prior written permission from Apple. Except as expressly
	stated in this notice, no other rights or licenses, express or implied, are granted by Apple
	herein, including but not limited to any patent rights that may be infringed by your 
	derivative works or by other works in which the Apple Software may be incorporated.
	
	The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
	EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
	USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
	
	IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
	OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
	REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
	WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
	OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import "btmsp430.h"

@implementation BTMSP430

#if 0
#pragma mark -
#pragma mark Methods to interact with the window
#endif

- (void)send:(int)len data:(NSString *)data
{
	int i;
	char senddat[32];
	// http://plaza.rakuten.co.jp/teetee/diary/?ctgy=36
	char irpat[] = {0xb0, 0x02, 0xb3, 0x02, 0x4d, 0x10, 0x00};
	
	for(i = 0; i < [data length] / 2; ++i) {
			senddat[i] = hex2Int((char *)[data cStringUsingEncoding:NSASCIIStringEncoding]+i*2);
	}
	irpat[4] = senddat[0];
	irpat[5] = senddat[1];
	[mRFCOMMChannel writeSync:irpat length:7];
}

- (void)close
{
	[self closeRFCOMMConnectionOnChannel:mRFCOMMChannel];
}

// =============================
// == BLUETOOTH SPECIFIC CODE ==
// =============================

#if 0
#pragma mark -
#pragma mark Methods to handle the Baseband and RFCOMM connection
#endif

- (BOOL)openSerialPortProfile
{
    IOBluetoothDeviceSelectorController	*deviceSelector;
	IOBluetoothSDPUUID					*sppServiceUUID;
	NSArray								*deviceArray;
	
    // The device selector will provide UI to the end user to find a remote device
    deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
	
	if ( deviceSelector == nil )
	{
		NSLog( @"Error - unable to allocate IOBluetoothDeviceSelectorController.\n" );
		return FALSE;
	}
		
	// Create an IOBluetoothSDPUUID object for the chat service UUID
	sppServiceUUID = [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassSerialPort];

	// Tell the device selector what service we are interested in.
	// It will only allow the user to select devices that have that service.
	[deviceSelector addAllowedUUID:sppServiceUUID];
	
	// Run the device selector modal.  This won't return until the user has selected a device and the device has
	// been validated to contain the specified service or the user has hit the cancel button.
	if ( [deviceSelector runModal] != kIOBluetoothUISuccess )
	{
		NSLog( @"User has cancelled the device selection.\n" );
		return FALSE;
	}

	// Get the list of devices the user has selected.
	// By default, only one device is allowed to be selected.
	deviceArray = [deviceSelector getResults];
	
	if ( ( deviceArray == nil ) || ( [deviceArray count] == 0 ) )
	{
		NSLog( @"Error - no selected device.  ***This should never happen.***\n" );
		return FALSE;
	}
	
	// The device we want is the first in the array (even if the user somehow selected more than
	// one device in this example we care only about the first one):
	IOBluetoothDevice *device = [deviceArray objectAtIndex:0];
	
	// Finds the service record that describes the service (UUID) we are looking for:
	IOBluetoothSDPServiceRecord	*sppServiceRecord = [device getServiceRecordForUUID:sppServiceUUID];
	
	if ( sppServiceRecord == nil )
	{
		NSLog( @"Error - no spp service in selected device.  ***This should never happen since the selector forces the user to select only devices with spp.***\n" );
		return FALSE;
	}

	// To connect we need a device to connect and an RFCOMM channel ID to open on the device:
	UInt8	rfcommChannelID;
	if ( [sppServiceRecord getRFCOMMChannelID:&rfcommChannelID] != kIOReturnSuccess )
	{
		NSLog( @"Error - no spp service in selected device.  ***This should never happen an spp service must have an rfcomm channel id.***\n" );
		return FALSE;
	}

	// Open asyncronously the rfcomm channel when all the open sequence is completed my implementation of "rfcommChannelOpenComplete:" will be called.
	if ( ( [device openRFCOMMChannelAsync:&mRFCOMMChannel withChannelID:rfcommChannelID delegate:self] != kIOReturnSuccess ) && ( mRFCOMMChannel != nil ) )
	{
		// Something went bad (looking at the error codes I can also say what, but for the moment let's not dwell on
		// those details). If the device connection is left open close it and return an error:
		NSLog( @"Error - open sequence failed.***\n" );
		
		[self closeDeviceConnectionOnDevice:device];
		
		return FALSE;
	}

	// So far a lot of stuff went well, so we can assume that the device is a good one and that rfcomm channel open process is going
	// well. So we keep track of the device and we (MUST) retain the RFCOMM channel:
	mBluetoothDevice = device;
	[mBluetoothDevice  retain];
	[mRFCOMMChannel retain];
		
	return TRUE;
}

- (void)closeRFCOMMConnectionOnChannel:(IOBluetoothRFCOMMChannel*)channel
{
	if ( mRFCOMMChannel == channel )
	{
		[mRFCOMMChannel closeChannel];
	}
}

- (void)closeDeviceConnectionOnDevice:(IOBluetoothDevice*)device
{
	if ( mBluetoothDevice == device )
	{
		IOReturn error = [mBluetoothDevice closeConnection];
		if ( error != kIOReturnSuccess )
		{
			// I failed to close the connection, maybe the device is busy, no problem, as soon as the device is no more busy it will close the connetion itself.
			NSLog(@"Error - failed to close the device connection with error %08lx.\n", (UInt32)error);
		}
		
		[mBluetoothDevice release];
		mBluetoothDevice = nil;
	}

}

#if 0
#pragma mark -
#pragma mark These are methods that are called when "things" happen on the
#pragma mark bluetooth connection, read along and it will all be clearer:
#endif

// Called by the RFCOMM channel on us once the baseband and rfcomm connection is completed:
- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel status:(IOReturn)error
{
// Not need this device
//	[rfcommChannel setSerialParameters:9600 dataBits:8 parity:kBluetoothRFCOMMParityTypeNoParity stopBits:1];

	// If it failed to open the channel call our close routine and from there the code will
	// perform all the necessary cleanup:
	if ( error != kIOReturnSuccess )
	{
		NSLog(@"Error - failed to open the RFCOMM channel with error %08lx.\n", (UInt32)error);
		[self rfcommChannelClosed:rfcommChannel];
		return;
	}

	// The RFCOMM channel is now completly open so it is possible to send and receive data
	// ... add the code that begin the send data ... for example to reset a modem:
	//	[rfcommChannel writeSync:"*IDN?\n" length:6];
	[rfcommChannel writeSync:"AT\n" length:3];
}

// Called by the RFCOMM channel on us when new data is received from the channel:
- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel *)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength
{
	unsigned char *dataAsBytes = (unsigned char *)dataPointer;
	
	while ( dataLength-- )
	{
		dataAsBytes++;
	}
}

// Called by the RFCOMM channel on us when something happens and the connection is lost:
- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel *)rfcommChannel
{
	// wait a second and close the device connection as well:
	[self performSelector:@selector(closeDeviceConnectionOnDevice:) withObject:mBluetoothDevice afterDelay:1.0];
}

@end
