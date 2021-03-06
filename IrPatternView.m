/*
 *  IrPatternView.m
 *  Armadillo
 *
 *  Created by H.M on 10/09/19.
 *  Copyright 2010 Hiroki Mori. All rights reserved.
 *
 */

#import "IrPatternView.h"

@implementation IrPatternView

#define OFFSETX 10
#define OFFSETY 10
#define HEIGHT 60
#define SCALE 100

CGRect convertToCGRect(NSRect inRect);

- (id)init {
    self = [super init];
    if (self) {
		patcount = 0;
    }
    return self;
}

- (void)drawScale:(int) width
{
	int i;
	for(i = 0; i < (width - 10) / 50; ++i) {
		CGContextMoveToPoint(gc, OFFSETX + i * 50, 2);
		CGContextAddLineToPoint(gc, OFFSETX + i * 50, 5);
	}
	CGContextStrokePath(gc);
}

- (int)addHiLoLine:(int)pos hi:(int)himsec lo:(int)lomsec
{
	int hisize, losize;
	hisize = himsec / SCALE;
	losize = lomsec / SCALE;
    CGContextSetLineCap(gc,kCGLineCapButt);
    CGContextMoveToPoint(gc, OFFSETX + pos, OFFSETY);
	if(himsec != 0) {
		CGContextAddLineToPoint(gc, OFFSETX + pos, OFFSETY + HEIGHT); // |
		CGContextAddLineToPoint(gc, OFFSETX  + pos + hisize, OFFSETY + HEIGHT); //-
	}
    CGContextAddLineToPoint(gc, OFFSETX  + pos + hisize, OFFSETY); // |
    CGContextAddLineToPoint(gc, OFFSETX  + pos + hisize + losize, OFFSETY); //-
	return pos + hisize + losize;
}

- (void)setIrPattern:(int)count pat:(irdata*) thepat
{
	pat = thepat;
	patcount = count;
}

- (int)drawIrPattern:(int)count pat:(irdata*) thepat
{
	int nextpos;
	int i, j;
	nextpos = 0;
	do {
		if(thepat->format.start_h + thepat->format.start_l != 0)
			nextpos = [self addHiLoLine:nextpos hi:thepat->format.start_h lo:thepat->format.start_l];

		i = 0;
		j = 0;
		if(thepat->bitlen) {
			do {
				if((thepat->data[j] >> (7 - i) & 1) == 1) {
					nextpos = [self addHiLoLine:nextpos hi:thepat->format.one_h lo:thepat->format.one_l];
				} else {
					nextpos = [self addHiLoLine:nextpos hi:thepat->format.zero_h lo:thepat->format.zero_l];
				}
				
				if(i == 7) {
					i = 0;
					++j;
				} else {
					++i;
				}
			} while((j * 8 + i) != thepat->bitlen);
		}
		if(thepat->format.stop_h + thepat->format.stop_l != 0)
			nextpos = [self addHiLoLine:nextpos hi:thepat->format.stop_h lo:thepat->format.stop_l];
		++thepat;
		--count;
	} while(count);
    CGContextStrokePath(gc);
	
	return nextpos;
}

- (void)drawRect:(NSRect)rect
{
    gc = [[NSGraphicsContext currentContext] graphicsPort];
    
	CGContextSetGrayFillColor(gc, 1.0, 1.0);
	CGContextFillRect(gc, convertToCGRect(rect));
//	CGContextStrokeRect(gc, convertToCGRect(rect));

	if(patcount)
	{
		int linelen = [self drawIrPattern:patcount pat:pat];
		if(linelen + OFFSETX > 653) {
			[self setFrame:NSMakeRect(0,0,linelen + OFFSETX * 2,86)];
			[self drawScale:linelen + OFFSETX * 2];
		}
		else {
			[self setFrame:NSMakeRect(0,0,653,86)];
			[self drawScale:653];
		}
	}
}

// A convenience function to get a CGRect from an NSRect. You can also use the
// *(CGRect *)&nsRect sleight of hand, but this way is a bit clearer.
CGRect convertToCGRect(NSRect inRect)
{
    return CGRectMake(inRect.origin.x, inRect.origin.y, inRect.size.width, inRect.size.height);
}

@end
