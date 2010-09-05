/*
 *  crossam2.h
 *  Armadillo
 *
 *  Created by H.M on 10/08/29.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

int crossam2_init(CFStringRef devname);
void crossam2_close();
void crossam2_pushkey(int dial, int key);
void crossam2_led(int ledon);

