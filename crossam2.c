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
		wtime.tv_sec = 0;
		wtime.tv_usec = 500*1000;
		select(crossam2_port + 1, &sio_fd, 0, 0, &wtime);
		if(!FD_ISSET(crossam2_port, &sio_fd)) {
			printf("MORI MORI Debug error\n");
			return 0;
		}
		read_size = read(crossam2_port, data+allsize, datasize-allsize);
		allsize += read_size;

		if(allsize > 2 && data[allsize-2] == 0x0d &&
		   data[allsize-1] == 0x0a) {
			data[allsize-2] = 0x00;
			printf("MORI MORI Debug %s\n", data);
			break;
		}
	}

	return allsize - 2;
	
}

void crossam2_writedata(char *data, int datasize)
{
	int i;
	for(i = 0; i < datasize; ++i) {
		write(crossam2_port, data+i, 1);
		usleep(1000*10);
	}
}

int crossam2_leam(int dial, int key)
{
	char outbytes[128];
	sprintf(outbytes, "/G%d,%d", dial, key);
	printf("MORI MORI debug %s\n", outbytes);
	int cmdlen = strlen(outbytes);
	outbytes[cmdlen] = 0x0d;
	crossam2_writedata(outbytes, cmdlen+1);
	char inbytes[128];
	if(crossam2_readline(inbytes, sizeof(inbytes)) == 0) {
		return 0;
	} else
		return 1;
}

void crossam2_protectoff()
{
	char outbytes[128];
	int cmdlen;
	strcpy(outbytes, "/HAL Laboratory INC.");
	cmdlen = strlen(outbytes);
	printf("MORI MORI debug %s\n", outbytes);
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
	else
		result = ((int)hexstr[0] - 'A' + 10) * 16;

	if(hexstr[1] >= '0' && hexstr[1] <= '9')
		result += (int)hexstr[1] - '0';
	else
		result += (int)hexstr[1] - 'A' + 10;
	
	return result;
}

int crossam2_read(int dial, int key, unsigned char *data, int datasize)
{
	char outbytes[128];
	int lineCount = 0;
	int dataSize;
	sprintf(outbytes, "/R%d,%d", dial, key);
	printf("MORI MORI debug %s\n", outbytes);
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
			printf("data size = %d\n", dataSize);
		} else if(lineCount == dataSize + 2) {
			break;
		}
	}
	if(lineCount)
		return 1;
	else
		return 0;
}

void crossam2_version(char *verstr, int strsize)
{
	char outbytes[128];
	char inbytes[128];
	verstr[0] = 0x00;
	strcpy(outbytes, "/V");
	printf("MORI MORI debug %s\n", outbytes);
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
	
	sprintf(outbytes, "/P%d", ledon);
	printf("MORI MORI debug %s\n", outbytes);
	int cmdlen = strlen(outbytes);
	outbytes[cmdlen] = 0x0d;
	crossam2_writedata(outbytes, cmdlen+1);
}

void crossam2_pushkey(int dial, int key)
{
	char outbytes[128];

	sprintf(outbytes, "/T%d,%d", dial, key);
	printf("MORI MORI debug %s\n", outbytes);
	int cmdlen = strlen(outbytes);
	outbytes[cmdlen] = 0x0d;
	crossam2_writedata(outbytes, cmdlen+1);

	usleep(300*1000);
	
	crossam2_sendcr();
}

int crossam2_check()
{
	char outbytes[128];
	
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

	sioinit();

	crossam2_sendcr();

	usleep(200*1000);
	
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