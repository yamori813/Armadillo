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
//	rstio.c_cflag |= CS8;
//	rstio.c_cflag &= ~CSTOPB;
//	rstio.c_cflag |= (PARODD | PARENB);
	/*	rstio.c_cflag |= (CRTS_IFLOW | CDTR_IFLOW);*/
	/*	rstio.c_cflag |= (CDSR_OFLOW | CCAR_OFLOW);*/
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
		wtime.tv_sec = 2;
		wtime.tv_usec = 0;
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
		usleep(1000*100);
	}
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
	
	char outbytes[128];
	outbytes[0] = 0x0d;	
	write(crossam2_port, outbytes, 1);
	usleep(1000*1000);
	
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