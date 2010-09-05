/*
 *  pcoprs1.h
 *  Armadillo
 *
 *  Created by H.M on 10/09/05.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

void pcoprs1_receive_cancel();
int pcoprs1_receive_data(unsigned char *data);
int pcoprs1_receive_start();
int pcoprs1_transfer(int chnnel, unsigned char *data);
int pcoprs1_led();
int pcoprs1_init(CFStringRef devname);
void pcoprs1_close();

