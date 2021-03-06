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
#include <string.h>

void set3byte(unsigned char *buff, int val)
{
	buff[0] = val & 0xff;
	buff[1] = (val >> 8) & 0xff;
	buff[2] = (val >> 16) & 0xff;
}

int timepos(int count, int *timearray, int hi, int lo)
{
	int i;
	for(i = 0; i < count; ++i) {
		if(*(timearray + i * 2) == hi && *(timearray + i * 2 + 1) == lo)
			return i;
	}
	return -1;
}

void timeset(int count, int *timearray, int hi, int lo)
{
	*(timearray + count * 2) = hi;
	*(timearray + count * 2 + 1) = lo;
	return;
}

int genir_crossam2(int car, int patcount, irdata *pat, unsigned char *buff, int size)
{
	int totalbit;
	int timecount;
	int timearray[128];
	int tpos;
	char bitbuff[512];
	int zeropat, onepat, startpat, stoppat;
	totalbit = 0;

	timecount = 0;

	buff[0] = 0;

	// set career
	if(car == 0)	// 40.3KHz
		buff[2] = 0x1f;
	else if(car == 1)	// 39.1KHz
		buff[2] = 0x20;
	else if(car == 2)	// 37.9KHz
		buff[2] = 0x21;
	else if(car == 3)	// 36.7 KHz ?
		buff[2] = 0x22;
	else if(car == 4)	// 35.7KHz
		buff[2] = 0x23;

	do {
		if(pat->format.zero_h + pat->format.zero_l != 0 && pat->bitlen != 0) {
			tpos = timepos(timecount, timearray, 
						   pat->format.zero_h, pat->format.zero_l);
			if(tpos == -1) {
				timeset(timecount, timearray, 
							   pat->format.zero_h, pat->format.zero_l);
				zeropat = timecount;
				++timecount;
			} else {
				zeropat = tpos;
			}
		}
		if(pat->format.one_h + pat->format.one_l != 0 && pat->bitlen != 0) {
			tpos = timepos(timecount, timearray, 
						   pat->format.one_h, pat->format.one_l);
			if(tpos == -1) {
				timeset(timecount, timearray, 
							   pat->format.one_h, pat->format.one_l);
				onepat = timecount;
				++timecount;
			} else {
				onepat = tpos;
			}
		}
		if(pat->format.stop_h + pat->format.stop_l != 0) {
			tpos = timepos(timecount, timearray, 
						   pat->format.stop_h, pat->format.stop_l);
			if(tpos == -1) {
				timeset(timecount, timearray, 
							   pat->format.stop_h, pat->format.stop_l);
				stoppat = timecount;
				++timecount;
			} else {
				stoppat = tpos;
			}
		}
		if(pat->format.start_h + pat->format.start_l != 0) {
			tpos = timepos(timecount, timearray, 
						   pat->format.start_h, pat->format.start_l);
			if(tpos == -1) {
				timeset(timecount, timearray, 
							   pat->format.start_h, pat->format.start_l);
				startpat = timecount;
				++timecount;
			} else {
				startpat = tpos;
			}
		}

		int i, j;
		i = 0;
		j = 0;
		if(pat->format.start_h + pat->format.start_l != 0) {
			if(totalbit % 2 == 0)
				bitbuff[totalbit / 2] = startpat << 4;
			else
				bitbuff[totalbit / 2] |= startpat;
			++totalbit;
		}
		if(pat->bitlen) {
			do {
				if(totalbit % 2 == 0)
					bitbuff[totalbit / 2] = (pat->data[j] >> (7 - i) & 1) ? onepat << 4 : zeropat;
				else
					bitbuff[totalbit / 2] |= (pat->data[j] >> (7 - i) & 1) ? onepat : zeropat;
				//		printf("%d ", (data[j] >> (7 - i) & 1));
				++totalbit;

				if(i == 7) {
					i = 0;
					++j;
				} else {
					++i;
				}
			} while((j * 8 + i) != pat->bitlen);
		}

		if(pat->format.stop_h + pat->format.stop_l != 0) {
			if(totalbit % 2 == 0)
				bitbuff[totalbit / 2] = stoppat << 4;
			else
				bitbuff[totalbit / 2] |= stoppat;
			++totalbit;
		}
		++pat;
		--patcount;
	} while(patcount);

	// back to lst pattern
	--pat;

	// set control code
	if(pat->repeat == 0 || pat->repeat == 1) {
		if(totalbit % 2 == 0)
			bitbuff[totalbit / 2] = 0xf << 4;
		else
			bitbuff[totalbit / 2] |= 0xf;
		++totalbit;
		if(totalbit % 2 == 0)
			bitbuff[totalbit / 2] = 0xf << 4;
		else
			bitbuff[totalbit / 2] |= 0xf;
		++totalbit;
//	} else if(pat->repeat == -1) {
	} else {
		if(totalbit % 2 == 0)
			bitbuff[totalbit / 2] = 0xf << 4;
		else
			bitbuff[totalbit / 2] |= 0xf;
		++totalbit;
		if(totalbit % 2 == 0)
			bitbuff[totalbit / 2] = 0xe << 4;
		else
			bitbuff[totalbit / 2] |= 0xe;
		++totalbit;
		if(totalbit% 2 == 0)
			bitbuff[totalbit / 2] = ((totalbit - 3) >> 4) << 4;
		else
			bitbuff[totalbit / 2] |= ((totalbit - 3) >> 4);
		++totalbit;
		if(totalbit % 2 == 0)
			bitbuff[totalbit / 2] = (totalbit - 3) << 4;
		else
			bitbuff[totalbit / 2] |= (totalbit - 3);
		++totalbit;
	}

	// copy signal time
	int i;
	for(i = 0; i < timecount; ++i) {
		set3byte(buff + 3 + 6 * i, *(timearray + i * 2) * 10 / 4);
		set3byte(buff + 3 + 6 * i + 3, *(timearray + i * 2 + 1) * 10 / 4);
	}
	buff[1] = timecount;

	// copy bit data
	if(totalbit % 2 == 0) {
		memcpy(buff + 3 + timecount * 6, bitbuff, totalbit / 2);
		return 3 + timecount * 6 + totalbit / 2;
	}

	memcpy(buff + 3 + timecount * 6, bitbuff, totalbit / 2 + 1);
	return 3 + timecount * 6 + totalbit / 2 + 1;
}

int sethilobit(int pos, unsigned char *buff, int hi, int lo)
{
	int hibit, lobit;
	hibit = hi / 100;
	lobit = lo / 100;
	int i;
	for(i = 0; i < hibit; ++i) {
		buff[pos / 8] |= 1 << (pos % 8);
		++pos;
	}
	return pos + lobit;
}

// buff is 240 byte fix

int genir_pcoprs1(int patcount, irdata *pat, unsigned char *buff)
{
	int curbit = 0;
	int i, j, k;
	int rep;
	irdata *orgpat;
	int orgpatcount;
	orgpat = pat;
	orgpatcount = patcount;
	memset(buff, 0, 240);
	rep = (orgpat + patcount - 1)->repeat;
	k = 0;
	do {
		pat = orgpat;
		patcount = orgpatcount;
		do {
			// start bit
			if(pat->format.start_h + pat->format.start_l != 0)
				curbit = sethilobit(curbit, buff, pat->format.start_h,
									pat->format.start_l);
			// data bit
			i = 0;
			j = 0;
			if(pat->bitlen) {
				do {
					if((pat->data[j] >> (7 - i) & 1) == 1) {
						curbit = sethilobit(curbit, buff, pat->format.one_h, 
											pat->format.one_l);
					} else {
						curbit = sethilobit(curbit, buff, pat->format.zero_h, 
											pat->format.zero_l);
					}
					
					if(i == 7) {
						i = 0;
						++j;
					} else {
						++i;
					}
				} while((j * 8 + i) != pat->bitlen);
			}
			
			// stop bit		
			if(pat->format.stop_h + pat->format.stop_l != 0)
				curbit = sethilobit(curbit, buff, pat->format.stop_h, 
									pat->format.stop_l);
			++pat;
			--patcount;
		} while(patcount);
		++k;
		if(k == 1 && (rep == -1 || curbit * rep > 240 * 8))
			rep = 240 * 8 / curbit;
	} while(k < rep);
/*
	for(j = 0; j < 240; ++j) {
		for(i = 0; i < 8; ++i) {
			printf("%d", (buff[j] >> i) & 1);
		}
	}
	printf("\n");
*/
	return 1;
}


int sebitbang(int pos, unsigned char *buff, int hi, int lo)
{
	int hibit, lobit;
	hibit = hi / 23;
	lobit = lo / 23;
	int i;
	for(i = 0; i < hibit; ++i) {
		/*
		buff[pos++] = 0x01;
		buff[pos++] = 0x00;
		buff[pos++] = 0x00;
		buff[pos++] = 0x00;
		buff[pos++] = 0x00;
		 */
		buff[pos] = 0x01;
		pos += 5;
	}
	for(i = 0; i < lobit; ++i) {
		/*
		buff[pos++] = 0x00;
		buff[pos++] = 0x00;
		buff[pos++] = 0x00;
		buff[pos++] = 0x00;
		buff[pos++] = 0x00;
		 */
		pos += 5;
	}
	return pos;
}

int genir_bitbang(int patcount, irdata *pat, unsigned char *buff, int size)
{
	int curbit = 0;
	int i, j, k;
	int rep;
	irdata *orgpat;
	int orgpatcount;
	orgpat = pat;
	orgpatcount = patcount;
	memset(buff, 0, size);
	rep = (orgpat + patcount - 1)->repeat;
	if(rep == -1)
		rep = 4;
	k = 0;
	do {
		pat = orgpat;
		patcount = orgpatcount;
		do {
			// start bit
			if(pat->format.start_h + pat->format.start_l != 0)
				curbit = sebitbang(curbit, buff, pat->format.start_h,
									pat->format.start_l);
			// data bit
			i = 0;
			j = 0;
			if(pat->bitlen) {
				do {
					if((pat->data[j] >> (7 - i) & 1) == 1) {
						curbit = sebitbang(curbit, buff, pat->format.one_h, 
											pat->format.one_l);
					} else {
						curbit = sebitbang(curbit, buff, pat->format.zero_h, 
											pat->format.zero_l);
					}
					
					if(i == 7) {
						i = 0;
						++j;
					} else {
						++i;
					}
				} while((j * 8 + i) != pat->bitlen);
			}
			
			// stop bit		
			if(pat->format.stop_h + pat->format.stop_l != 0)
				curbit = sebitbang(curbit, buff, pat->format.stop_h, 
									pat->format.stop_l);
			++pat;
			--patcount;
		} while(patcount);
		++k;
		if(k == 1 && curbit * rep > size)
			rep = size / curbit;
	} while(k < rep);
	/*
	 for(j = 0; j < 240; ++j) {
	 for(i = 0; i < 8; ++i) {
	 printf("%d", (buff[j] >> i) & 1);
	 }
	 }
	 printf("\n");
	 */
	return curbit;
	
}

// if buffer over flow return -1

int setirkit(char *buff, int size, int hilen, int lolen)
{
	char hilo[32];
	int curlen;
	sprintf(hilo, "%d,%d", hilen, lolen);
	curlen = strlen(buff);
	if(curlen + strlen(hilo) + 1 > size)
		return -1;
	if(curlen != 0)
		strcat(buff, ",");	
	strcat(buff, hilo);
	return 0;
}

int genir_irkit(int patcount, irdata *pat,char *buff, int size)
{
	int err;
	int i, j, k;
	int rep;
	irdata *orgpat;
	int orgpatcount;
	orgpat = pat;
	orgpatcount = patcount;
	memset(buff, 0, 240);
	rep = (orgpat + patcount - 1)->repeat;
	k = 0;
	*buff = '\0';
	do {
		pat = orgpat;
		patcount = orgpatcount;
		do {
			// start bit
			if(pat->format.start_h + pat->format.start_l != 0) {
				err = setirkit(buff, size, pat->format.start_h,
							   pat->format.start_l);
				if(err == -1)
					return -1;
			}
			// data bit
			i = 0;
			j = 0;
			if(pat->bitlen) {
				do {
					if((pat->data[j] >> (7 - i) & 1) == 1) {
						err = setirkit(buff,  size, pat->format.one_h, 
											pat->format.one_l);
					} else {
						err = setirkit(buff, size, pat->format.zero_h, 
											pat->format.zero_l);
					}
					if(err == -1)
						return -1;
					
					if(i == 7) {
						i = 0;
						++j;
					} else {
						++i;
					}
				} while((j * 8 + i) != pat->bitlen);
			}
			
			// stop bit		
			if(pat->format.stop_h + pat->format.stop_l != 0) {
				err = setirkit(buff, size, pat->format.stop_h, 
									pat->format.stop_l);
				if(err == -1)
					return -1;
			}
			++pat;
			--patcount;
		} while(patcount);
		++k;
	} while(k < rep);

	return 0;
}

