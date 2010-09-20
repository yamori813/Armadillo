/*
 *  IrPatternView.h
 *  Armadillo
 *
 *  Created by H.M on 10/09/19.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

#include "genir.h"

@interface IrPatternView : NSView {
	CGContextRef gc;
	int patcount;
	irdata* pat;
}

- (void)setIrPattern:(int)count pat:(irdata*) thepat;

@end
