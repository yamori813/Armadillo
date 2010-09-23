/*
 *  bitbang.c
 *  Armadillo
 *
 *  Created by H.M on 10/09/23.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#include "bitbang.h"

#include <stdio.h>
#include <unistd.h>

// Globals
FT_HANDLE ftHandle = NULL;

int bitbang_init()
{
	FT_STATUS	ftStatus;
	ftStatus = FT_Open(0, &ftHandle);
	if(ftStatus != FT_OK) {
		/* 
		 This can fail if the ftdi_sio driver is loaded
		 use lsmod to check this and rmmod ftdi_sio to remove
		 also rmmod usbserial
		 */
		printf("FT_Open failed = %d\n", ftStatus);
		return 0;
	}
	ftStatus = FT_SetLatencyTimer(ftHandle, 10);
	if(ftStatus != FT_OK) {
		printf("Failed to FT_SetLatencyTimer\n");       
		return 0;
	}
	ftStatus = FT_SetBitMode(ftHandle, 0x01, 0x01);
	if(ftStatus != FT_OK) {
		printf("Failed to set Asynchronous Bit bang Mode");
		return 0;
	}
	usleep(1000*200);
	ftStatus = FT_Purge(ftHandle, FT_PURGE_RX);
	if(ftStatus != FT_OK) {
		printf("Failed to FT_Purge\n");	
	}
	ftStatus = FT_SetBaudRate(ftHandle, 9600*5);
	if(ftStatus != FT_OK) {
		printf("Failed to FT_SetBaudRate\n");	
		return 0;
	}

	return 1;
}

void bitbang_close()
{
	if(ftHandle != NULL) {
		FT_Close(ftHandle);
		ftHandle = NULL;
	}
}

int bitbang_transfer(int size, unsigned char *data)
{
	FT_STATUS	ftStatus;
	DWORD dwBytesInQueue = 0;

	ftStatus = FT_Write(ftHandle, data, size, &dwBytesInQueue);
	if(ftStatus != FT_OK) {
		printf("Failed to FT_Write\n");
		return 0;
	} else {
		printf("FT_Write dwBytesInQueue = %d\n",dwBytesInQueue);
	}
	return 1;
}
