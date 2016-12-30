/*
 *  genir.h
 *  Armadillo
 *
 *  Created by H.M on 10/09/14.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */


#ifndef _GENIR_H_
#define _GENIR_H_

typedef struct _irtime {
	int start_h;
	int start_l;
	int zero_h;
	int zero_l;
	int one_h;
	int one_l;
	int stop_h;
	int stop_l;
} irtime;

typedef struct _irdata {
	irtime format;
	unsigned char data[32];
	int bitlen;
	int repeat;
} irdata;

int genir_crossam2(int car, int patcount, irdata *pat, unsigned char *buff, int size);
int genir_pcoprs1(int patcount, irdata *pat, unsigned char *buff);
int genir_bitbang(int patcount, irdata *pat, unsigned char *buff, int size);
int genir_irkit(int patcount, irdata *pat,char *buff, int size);

#endif