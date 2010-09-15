/*
 *  genir.c
 *  Armadillo
 *
 *  Created by H.M on 10/09/14.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#include "genir.h"

#include <stdio.h>
#include <stdio.h>
void set3byte(unsigned char *buff, int val)
{
	buff[0] = val & 0xff;
	buff[1] = (val >> 8) & 0xff;
	buff[2] = (val >> 16) & 0xff;
}

int genir_crossam2(irdata *format, unsigned char *data, int bitlen,
				  int repeat, unsigned char *buff, int size)
{
	int tmpval;

	buff[0] = 0;
	buff[1] = 4;
	buff[2] = 0x20;

	tmpval = format->zero_h * 10 / 4;
	set3byte(&buff[3], tmpval);	
	tmpval = format->zero_l * 10 / 4;
	set3byte(&buff[6], tmpval);
	tmpval = format->one_h * 10 / 4;
	set3byte(&buff[9], tmpval);
	tmpval = format->one_l * 10 / 4;
	set3byte(&buff[12], tmpval);
	tmpval = format->stop_h * 10 / 4;
	set3byte(&buff[15], tmpval);
	tmpval = format->stop_l * 10 / 4;
	set3byte(&buff[18], tmpval);
	tmpval = format->start_h * 10 / 4;
	set3byte(&buff[21], tmpval);
	tmpval = format->start_l * 10 / 4;
	set3byte(&buff[24], tmpval);

	int i, j;
	i = 0;
	j = 0;
	buff[27 + (j * 8 + i) / 2] = 0x30;
	do {
		if((j * 8 + i + 1) % 2 == 0)
			buff[27 + (j * 8 + i + 1) / 2] = (data[j] >> (7 - i) & 1) << 4;
		else
			buff[27 + (j * 8 + i + 1) / 2] |= (data[j] >> (7 - i) & 1);
//		printf("%d ", (data[j] >> (7 - i) & 1));
		if(i == 8) {
			i = 0;
			++j;
		} else {
			++i;
		}
	} while((j * 8 + i) != bitlen);
	if((j * 8 + i + 1) % 2 == 0)
		buff[27 + (j * 8 + i + 1) / 2] = 2;
	else
		buff[27 + (j * 8 + i + 1) / 2] |= 2;
	/*
	buff[27] = 0x31;
	buff[28] = 0x01;
	buff[29] = 0x01;
	buff[30] = 0x00;
	buff[31] = 0x10;
	buff[32] = 0x00;
	buff[33] = 0x02;
*/
	buff[34] = 0xfe;
	buff[35] = 0x0e;

	return 36;
}

int genir_pcoprs1(irdata *format, unsigned char *data, int bitlen,
				  int repeat, unsigned char *buff)
{
	return 1;
}
