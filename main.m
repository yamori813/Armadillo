//
//  main.m
//  Armadillo
//
//  Created by H.M on 10/08/29.
//  Copyright 2010 Hiroki Mori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Armadillo.h"

int main(int argc, char *argv[])
{
    return NSApplicationMain(argc,  (const char **) argv);
}

@interface ArmadilloApp : NSApplication {
	Armadillo *arma;
}
-(void)setArmaObj:(Armadillo *)theobj;
@end

@implementation ArmadilloApp
-(void)setArmaObj:(Armadillo *)theobj
{
	arma = theobj;
}

-(void)ArmadilloTest:(NSScriptCommand*)command {
// this code crash on write data to usb
//	[arma ftbitbangTrans:self];
// this is workaround code
	[NSThread detachNewThreadSelector:@selector(ftbitbangTrans:) toTarget:arma
						   withObject:nil];
}

@end
