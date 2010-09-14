/*
 *  genir.h
 *  Armadillo
 *
 *  Created by H.M on 10/09/14.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

typedef struct _irdata {
	int start_h;
	int start_l;
	int zero_h;
	int zero_l;
	int one_h;
	int one_l;
	int stop_h;
	int stop_l;
} irdata;

int genir_crossam2(irdata *format, unsigned char *data, int bitlen,
				  int repeat, unsigned char *buff, int size);
int genir_pcoprs1(irdata *format, unsigned char *data, int bitlen,
				  int repeat, unsigned char *buff);
