/*
 *  pcoprs1.c
 *  Armadillo
 *
 *  Created by H.M on 10/09/05.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

// http://su-u.jp/juju/%CA%AC%B2%F2%A4%B7%A4%C6%A4%DF%A4%E8%A4%A6/PC-OP-RS1.html

#include "pcoprs1.h"

#include <unistd.h>
#include <fcntl.h>
#include <sys/termios.h>
#include <sys/time.h>

static int pcoprs1_port;

static void sioinit()
{
	struct termios	rstio;
	
	tcgetattr(pcoprs1_port, &rstio);
	rstio.c_cflag |= CS8;
	rstio.c_cflag &= ~CSTOPB;
	rstio.c_cflag &= ~(PARODD | PARENB);
	rstio.c_cflag &= ~(CRTS_IFLOW | CDTR_IFLOW);
	rstio.c_cflag &= ~(CDSR_OFLOW | CCAR_OFLOW);
	rstio.c_ispeed = rstio.c_ospeed = B115200;
	tcsetattr(pcoprs1_port, TCSADRAIN, &rstio);
}


void pcoprs1_receive_cancel()
{
	char data[1];
	
	data[0] = 0x63;
	write(pcoprs1_port, data, 1);
}

int pcoprs1_receive_data(unsigned char *data)
{
	fd_set sio_fd;
	struct timeval wtime;
	int read_size, allsize;
	char tmpbuff[242];
	
	allsize = 0;
	while(1) {
		FD_ZERO(&sio_fd);
		FD_SET(pcoprs1_port, &sio_fd);
		wtime.tv_sec = 1;
		wtime.tv_usec = 0;
		select(pcoprs1_port + 1, &sio_fd, 0, 0, &wtime);
		if(!FD_ISSET(pcoprs1_port, &sio_fd)) {
			return 0;
		}
		read_size = read(pcoprs1_port, tmpbuff+allsize, sizeof(tmpbuff)-allsize);
		allsize += read_size;
		
		if(allsize == 242) {
			// copy only data
			memcpy(data, tmpbuff+1, 240);
			return 1;
		}
	}
	return 0;
}

int pcoprs1_receive_start()
{
	fd_set sio_fd;
	struct timeval wtime;
	char data[1];
	int read_size;
	
	data[0] = 0x72;
	write(pcoprs1_port, data, 1);

	while(1) {
		FD_ZERO(&sio_fd);
		FD_SET(pcoprs1_port, &sio_fd);
		wtime.tv_sec = 2;
		wtime.tv_usec = 0;
		select(pcoprs1_port + 1, &sio_fd, 0, 0, &wtime);
		if(!FD_ISSET(pcoprs1_port, &sio_fd)) {
			printf("pcoprs1_receive_start error\n");
			return 0;
		}
		read_size = read(pcoprs1_port, data, 1);

		// check recive ack
		if(read_size == 1 && data[0] == 0x59)
			return 1;
		else 
			break;
	}
	
	return 0;
}

// chnnel 1 - 4
int pcoprs1_transfer(int chnnel, unsigned char *data)
{
	fd_set sio_fd;
	struct timeval wtime;
	char tmpbuff[1];
	int read_size;
	
	tmpbuff[0] = 0x74;
	write(pcoprs1_port, tmpbuff, 1);
	
	while(1) {
		FD_ZERO(&sio_fd);
		FD_SET(pcoprs1_port, &sio_fd);
		wtime.tv_sec = 2;
		wtime.tv_usec = 0;
		select(pcoprs1_port + 1, &sio_fd, 0, 0, &wtime);
		if(!FD_ISSET(pcoprs1_port, &sio_fd)) {
			printf("pcoprs1_transfer error\n");
			return 0;
		}
		read_size = read(pcoprs1_port, tmpbuff, 1);
		
		// check recive ack
		if(read_size == 1 && tmpbuff[0] == 0x59)
			break;
		else 
			return 0;
	}

	tmpbuff[0] = 0x30 | chnnel;
	write(pcoprs1_port, tmpbuff, 1);
	
	while(1) {
		FD_ZERO(&sio_fd);
		FD_SET(pcoprs1_port, &sio_fd);
		wtime.tv_sec = 2;
		wtime.tv_usec = 0;
		select(pcoprs1_port + 1, &sio_fd, 0, 0, &wtime);
		if(!FD_ISSET(pcoprs1_port, &sio_fd)) {
			printf("pcoprs1_transfer error\n");
			return 0;
		}
		read_size = read(pcoprs1_port, tmpbuff, 1);
		
		// check recive ack
		if(read_size == 1 && tmpbuff[0] == 0x59)
			break;
		else 
			return 0;
	}
	
	write(pcoprs1_port, data, 240);

	while(1) {
		FD_ZERO(&sio_fd);
		FD_SET(pcoprs1_port, &sio_fd);
		wtime.tv_sec = 2;
		wtime.tv_usec = 0;
		select(pcoprs1_port + 1, &sio_fd, 0, 0, &wtime);
		if(!FD_ISSET(pcoprs1_port, &sio_fd)) {
			printf("pcoprs1_transfert error\n");
			return 0;
		}
		read_size = read(pcoprs1_port, tmpbuff, 1);
		
		// check recive ack
		if(read_size == 1 && tmpbuff[0] == 0x45)
			break;
		else 
			return 0;
	}

	return 1;
}

int pcoprs1_led()
{
	fd_set sio_fd;
	struct timeval wtime;
	char data[1];
	int read_size;
	
	data[0] = 0x69;
	write(pcoprs1_port, data, 1);
	
	while(1) {
		FD_ZERO(&sio_fd);
		FD_SET(pcoprs1_port, &sio_fd);
		wtime.tv_sec = 0;
		wtime.tv_usec = 200*1000;
		select(pcoprs1_port + 1, &sio_fd, 0, 0, &wtime);
		if(!FD_ISSET(pcoprs1_port, &sio_fd)) {
			printf("pcoprs1_led error\n");
			return 0;
		}
		read_size = read(pcoprs1_port, data, 1);
		
		// check recive ack
		if(read_size == 1 && data[0] == 0x4f)
			return 1;
		else 
			break;
	}
	
	return 0;
}

int pcoprs1_init(CFStringRef devname)
{
	char devstr[1024];
	
    CFStringGetCString(devname,
					   devstr,
					   1024, 
					   kCFStringEncodingASCII);
	
	pcoprs1_port = open(devstr, O_RDWR);
    if(pcoprs1_port < 0)
        return 0;
	
	tcflush(pcoprs1_port, TCIOFLUSH);

	sioinit();
	
	return 1;
}

void pcoprs1_close()
{
	close(pcoprs1_port);
}