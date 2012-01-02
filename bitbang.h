/*
 *  bitbang.h
 *  Armadillo
 *
 *  Created by H.M on 10/09/23.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

int bitbang_list(CFMutableArrayRef interfaceList);
int bitbang_init(int iDev);
int bitbang_transfer(int size, unsigned char *data);
