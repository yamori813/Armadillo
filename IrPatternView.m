/*
 *  IrPatternView.m
 *  Armadillo
 *
 *  Created by H.M on 10/08/29.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#import "IrPatternView.h"

@implementation IrPatternView

CGRect convertToCGRect(NSRect inRect);

- (void)drawRect:(NSRect)rect
{
    CGContextRef gc = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSetGrayFillColor(gc, 1.0, 1.0);
    CGContextFillRect(gc, convertToCGRect(rect));
	
}

// A convenience function to get a CGRect from an NSRect. You can also use the
// *(CGRect *)&nsRect sleight of hand, but this way is a bit clearer.
CGRect convertToCGRect(NSRect inRect)
{
    return CGRectMake(inRect.origin.x, inRect.origin.y, inRect.size.width, inRect.size.height);
}

@end
