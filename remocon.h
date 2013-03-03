/*
 *  remocon.h
 *  Armadillo
 *
 *  Created by hiroki on 13/03/03.
 *  Copyright 2013 __MyCompanyName__. All rights reserved.
 *
 */

void remocon_transfer(int len, int type, unsigned char *dat);
int remocon_init();
void remocon_close();