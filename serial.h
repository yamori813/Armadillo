/*
 *  serial.h
 *  zauask-osx
 *
 *  Created by Hiroki Mori on Sat Sep 11 2004.
 *  Copyright (c) 2004 Hiroki Mor. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

kern_return_t FindModems(io_iterator_t *matchingServices);
kern_return_t GetModemPath(io_iterator_t serialPortIterator, CFMutableArrayRef interfaceList);
