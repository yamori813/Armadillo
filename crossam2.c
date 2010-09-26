/*
 *  crossam2.c
 *  Armadillo
 *
 *  Created by H.M on 10/08/29.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#include "crossam2.h"

#include <unistd.h>
#include <fcntl.h>
#include <sys/termios.h>
#include <sys/time.h>

unsigned char PatchData[] = {
	0xA2,0x10,0xBD,0x23,0x10,0x9D,0x00,0x01,    /* 0 */
	0xCA,0x10,0xF7,0xA2,0x40,0xBD,0x33,0x10,
	0x9D,0x00,0x0B,0xCA,0x10,0xF7,0x3C,0x00,    /* 1 */
	0x2B,0x3C,0x00,0x2C,0x3C,0x32,0x06,0x58,
	0x4C,0x00,0x0B,0x7F,0xD7,0x3C,0x80,0xDF,    /* 2 */
	0x8F,0xDE,0x42,0xEA,0x20,0x58,0xC4,0x4C,
	0x15,0x0B,0x00,0x4F,0xFE,0x6F,0xFF,0x8F,    /* 3 */
	0xFE,0x3C,0x00,0xDA,0xCF,0xDA,0x64,0x06,
	0xD0,0x05,0x6F,0xFE,0x4C,0x00,0x01,0xC2,    /* 4 */
	0x9F,0xFE,0x7F,0xFF,0x20,0xEE,0xC0,0x20,
	0xC8,0xC5,0x9F,0xFC,0x20,0x2A,0x0B,0xA5,    /* 5 */
	0x25,0xD0,0xED,0x80,0xD6,0xA7,0x23,0x01,
	0x60,0xBF,0x23,0x3C,0x00,0x2A,0xA2,0x00,    /* 6 */
	0x20,0x44,0xCD,0xC9,0x2F,0xD0,0xF1,0xE8,
	0x4C,0x9E,0xC9,0xFF,0xFF,0xFF,0xFF,0xFF,    /* 7 */
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,

	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
};

/* refered by zauask sio.c source code */

static int crossam2_port;

static void sioinit()
{
	struct termios	rstio;
	
	tcgetattr(crossam2_port, &rstio);
	rstio.c_cflag |= CS8;
	rstio.c_cflag &= ~CSTOPB;
	rstio.c_cflag &= ~(PARODD | PARENB);
	rstio.c_cflag &= ~(CRTS_IFLOW | CDTR_IFLOW);
	rstio.c_cflag &= ~(CDSR_OFLOW | CCAR_OFLOW);
	rstio.c_ispeed = rstio.c_ospeed = B9600;
	tcsetattr(crossam2_port, TCSADRAIN, &rstio);
}

int crossam2_readline(char *data, int datasize)
{
	fd_set sio_fd;
	struct timeval wtime;
	int read_size, allsize;

	allsize = 0;
	while(1) {
		FD_ZERO(&sio_fd);
		FD_SET(crossam2_port, &sio_fd);
		wtime.tv_sec = 1;
		wtime.tv_usec = 0;
		select(crossam2_port + 1, &sio_fd, 0, 0, &wtime);
		if(!FD_ISSET(crossam2_port, &sio_fd)) {
			printf("crossam2_readline error\n");
			return 0;
		}
		read_size = read(crossam2_port, data+allsize, datasize-allsize);
		allsize += read_size;

		if(allsize > 2 && data[allsize-2] == 0x0d &&
		   data[allsize-1] == 0x0a) {
			data[allsize-2] = 0x00;
//			printf("MORI MORI Debug %s\n", data);
			break;
		}
	}

	return allsize - 2;
	
}

int crossam2_waitgo()
{
	fd_set sio_fd;
	struct timeval wtime;
	int read_size, allsize;
	char buff[8];
	allsize = 0;

	while(1) {
		FD_ZERO(&sio_fd);
		FD_SET(crossam2_port, &sio_fd);
		wtime.tv_sec = 15;
		wtime.tv_usec = 0;
		select(crossam2_port + 1, &sio_fd, 0, 0, &wtime);
		if(!FD_ISSET(crossam2_port, &sio_fd)) {
			printf("crossam2_readline error\n");
			return 0;
		}
		read_size = read(crossam2_port, buff+allsize, sizeof(buff)-allsize);
		allsize += read_size;
		printf("MORI MORI read_size = %d\n", read_size);
		if(buff[0] == 'G' && buff[1] == 'O') {
			return 1;
		}
	}	
	return 0;	
}

void crossam2_writedata(char *data, int datasize)
{
	int i;
	for(i = 0; i < datasize; ++i) {
		write(crossam2_port, data+i, 1);
		usleep(1000*10);
	}
}

int crossam2_learn(int dial, int key)
{
	char outbytes[128];
	sprintf(outbytes, "/G%d,%d", dial, key);
	int cmdlen = strlen(outbytes);
	outbytes[cmdlen] = 0x0d;
	crossam2_writedata(outbytes, cmdlen+1);
	char inbytes[128];
	if(crossam2_readline(inbytes, sizeof(inbytes)) == 0) {
		return 0;
	} else
		return 1;
}

void crossam2_protecton()
{
	// ???
}

void crossam2_protectoff()
{
	char outbytes[128];
	int cmdlen;
	crossam2_sendcr();	
	usleep(200*1000);
	strcpy(outbytes, "/HA Laboratory INC.");
	cmdlen = strlen(outbytes);
	outbytes[cmdlen] = 0x0d;
	crossam2_writedata(outbytes, cmdlen+1);
}

void crossam2_getkey()
{
	char outbytes[128];
	outbytes[0] = '/';
	outbytes[1] = 'I';
	outbytes[2] = 0x0d;
	crossam2_writedata(outbytes, 3);
	char inbytes[128];
	crossam2_readline(inbytes, sizeof(inbytes));
}


int hex2Int(char *hexstr)
{
	int result = 0;
	if(hexstr[0] >= '0' && hexstr[0] <= '9')
		result = ((int)hexstr[0] - '0') * 16;
	else if(hexstr[0] >= 'a' && hexstr[0] <= 'f')
		result = ((int)hexstr[0] - 'a' + 10) * 16;
	else if(hexstr[0] >= 'A' && hexstr[0] <= 'F')
		result = ((int)hexstr[0] - 'A' + 10) * 16;

	if(hexstr[1] >= '0' && hexstr[1] <= '9')
		result += (int)hexstr[1] - (int)'0';
	else if(hexstr[1] >= 'a' && hexstr[1] <= 'f')
		result += (int)hexstr[1] - (int)'a' + 10;
	else if(hexstr[1] >= 'A' && hexstr[1] <= 'F')
		result += (int)hexstr[1] - (int)'A' + 10;
	
	return result;
}

int crossam2_write(int dial, int key, unsigned char *data, int datasize)
{
	
	char outbytes[128];
	int i;
	// wake up from sleep
	crossam2_sendcr();	
	usleep(200*1000);
	
	sprintf(outbytes, "/W%d,%d %d", dial, key, datasize);
	int cmdlen = strlen(outbytes);
	outbytes[cmdlen] = 0x0d;
	crossam2_writedata(outbytes, cmdlen+1);

	for(i = 0; i < datasize; ++i) {
		sprintf(outbytes, "%02x", data[i]);
		int cmdlen = strlen(outbytes);
		outbytes[cmdlen] = 0x0d;
		crossam2_writedata(outbytes, cmdlen+1);
	}
	char inbytes[128];
	
	crossam2_readline(inbytes, sizeof(inbytes));
	return 1;
}

int crossam2_read(int dial, int key, unsigned char *data, int datasize)
{
	char outbytes[128];
	int lineCount = 0;
	int dataSize;
	// wake up from sleep
	crossam2_sendcr();	
	usleep(200*1000);
	
	sprintf(outbytes, "/R%d,%d", dial, key);
	int cmdlen = strlen(outbytes);
	outbytes[cmdlen] = 0x0d;
	crossam2_writedata(outbytes, cmdlen+1);
	char inbytes[128];
	while(crossam2_readline(inbytes, sizeof(inbytes)) != 0) {
		if(strcmp(inbytes, "Ng") == 0)
			return 0;
		else {
			data[lineCount] = hex2Int(inbytes);
			++lineCount;
		}
		
		if(lineCount == 1) {
			dataSize = hex2Int(inbytes);
		} else if (lineCount == 2) {
			dataSize += hex2Int(inbytes) * 0x100;
//			printf("data size = %d\n", dataSize);
		} else if(lineCount == dataSize + 2) {
			break;
		}
	}
	if(lineCount)
		return dataSize + 2;
	else
		return 0;
}

void crossam2_version(char *verstr, int strsize)
{
	char outbytes[128];
	char inbytes[128];
	verstr[0] = 0x00;
	// wake up from sleep
	crossam2_sendcr();	
	usleep(200*1000);
	strcpy(outbytes, "/V");
	int cmdlen = strlen(outbytes);
	outbytes[cmdlen] = 0x0d;
	crossam2_writedata(outbytes, cmdlen+1);
	while(crossam2_readline(inbytes, sizeof(inbytes)) != 0) {
		strcat(verstr, inbytes);
		strcat(verstr, "\n");
	}
}

void crossam2_led(int ledon)
{
	char outbytes[128];
	// wake up from sleep
	crossam2_sendcr();	
	usleep(200*1000);	
	sprintf(outbytes, "/P%d", ledon);
	int cmdlen = strlen(outbytes);
	outbytes[cmdlen] = 0x0d;
	crossam2_writedata(outbytes, cmdlen+1);
}

void crossam2_pushkey(int dial, int key)
{
	char outbytes[128];
	// wake up from sleep
	crossam2_sendcr();	
	usleep(200*1000);	
	sprintf(outbytes, "/T%d,%d", dial, key);
	int cmdlen = strlen(outbytes);
	outbytes[cmdlen] = 0x0d;
	crossam2_writedata(outbytes, cmdlen+1);

	usleep(300*1000);
	
	// stop send signal
	crossam2_sendcr();
}

int crossam2_check()
{
	char outbytes[128];
	// wake up from sleep
	crossam2_sendcr();	
	usleep(200*1000);
	
	outbytes[0] = '/';
	outbytes[1] = 'C';
	outbytes[2] = 0x0d;
	crossam2_writedata(outbytes, 3);

	char inbytes[128];
	if(crossam2_readline(inbytes, sizeof(inbytes)) == 0) {
		return 0;
	} else
		return 1;
}

void crossam2_sendcr()
{
	char outbytes[128];
	outbytes[0] = 0x0d;
	write(crossam2_port, outbytes, 1);
}

int crossam2_patch()
{
	if(crossam2_waitgo()) {
		crossam2_writedata((char *)PatchData, sizeof(PatchData));
		return 1;
	}
	return 0;
}

int crossam2_init(CFStringRef devname)
{
	char devstr[1024];

    CFStringGetCString(devname,
					   devstr,
					   1024, 
					   kCFStringEncodingASCII);
	
	crossam2_port = open(devstr, O_RDWR);
    if(crossam2_port < 0)
        return 0;

	tcflush(crossam2_port, TCIOFLUSH);

	sioinit();

	usleep(500*1000);

	if(crossam2_check() == 0) {
		return 0;
	}
	else
		return 1;
}

void crossam2_close()
{
	close(crossam2_port);
}

void crossam2_dump(unsigned char *buff)
{
	int allsize, ttsize, mark, space;
	int i;

	allsize = buff[0] + buff[1] * 0x100;
	ttsize = buff[3];
	if(ttsize >= 0x80) {
		for(i = 3; i < allsize; ++i) {
			printf("%02x", buff[i]);
		}
		printf("\n");
	} else {
		for(i = 0; i < ttsize; ++i) {
			mark = *((buff + 5) + i * 6)
			+ *((buff + 6) + i * 6) * 0x100 + *((buff + 7) + i * 6) * 0x10000;
			space = *((buff + 8) + i * 6)
			+ *((buff + 9) + i * 6) * 0x100 + *((buff + 10) + i * 6) * 0x10000;
			//		printf("%d %d\n", mark, space);
			printf("%8.1fus %8.1fus\n", (float)mark * 4 / 10, (float)space * 4 / 10);
		}
		printf("\n");
		for(i = 5 + ttsize * 6; i < allsize; ++i) {
			printf("%02x", buff[i]);
		}
		printf("\n");
	}
}