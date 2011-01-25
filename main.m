//
//  main.m
//  Armadillo
//
//  Created by H.M on 10/08/29.
//  Copyright 2010 Hiroki Mori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Armadillo.h"

#import "main.h"

int main(int argc, char *argv[])
{
    return NSApplicationMain(argc,  (const char **) argv);
}

@implementation ArmadilloApp
- (id)init {
    self = [super init];
    if (self) {
		armadilloVers = [NSString stringWithString:@"0.1"];
	}
	return self;
}

-(void)ArmadilloTest:(NSScriptCommand*)command {
// this code crash on write data to usb
//	[arma ftbitbangTrans:self];
// this is workaround code
	// Required parameter.
	[NSThread detachNewThreadSelector:@selector(ftbitbangTrans:) toTarget:arma
						   withObject:nil];
}

-(void)openxml:(NSScriptCommand*)command {
	id directParameter = [command directParameter];
	[NSThread detachNewThreadSelector:@selector(openxml:) toTarget:arma
						   withObject:directParameter];
}

-(void)initftbitbang:(NSScriptCommand*)command {
	[NSThread detachNewThreadSelector:@selector(initftbitbang:) toTarget:arma
						   withObject:nil];
}

-(void)transftbitbang:(NSScriptCommand*)command {
	id directParameter = [command directParameter];
	[NSThread detachNewThreadSelector:@selector(transftbitbang:) toTarget:arma
						   withObject:directParameter];
}
@end
