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

-(void)usedevice:(NSScriptCommand*)command {
	NSString *directParameter = [command directParameter];
	NSDictionary *args = [command arguments];

	if([directParameter compare:@"Crossam2"] == NSOrderedSame) {
		[arma setTab:0];
	} else if([directParameter compare:@"PC-OP-RS1"] == NSOrderedSame) {
		[arma setTab:1];
		[arma pcoprs1Init:nil];
		int port = [[args objectForKey:@"port"] intValue];
		if(port > 0 && port <= 4) {
			[arma setPort:(port-1)];
		}
	} else if([directParameter compare:@"BitBang"] == NSOrderedSame) {
		[arma setTab:2];
		[arma ftbitbangInit:nil];
	} else if([directParameter compare:@"REMOCON"] == NSOrderedSame) {
		[arma setTab:3];
	} else if([directParameter compare:@"BTMSP430"] == NSOrderedSame) {
		[arma setTab:4];
	} else if([directParameter compare:@"IRKit"] == NSOrderedSame) {
		[arma setTab:5];
	}
}

-(void)commandsend:(NSScriptCommand*)command {
	id directParameter = [command directParameter];
	[arma setCommand:directParameter];
	int tab = [arma getTab];
	if(tab == 0) {
	} else if(tab == 1) {
		[arma pcoprs1Trans:nil];
	} else if(tab == 2) {
		[arma ftbitbangTrans:nil];
	} else if(tab == 3) {
		[arma remoconTrans:nil];
	} else if(tab == 5) {
		[arma irkitTrans:nil];
	}
//	[NSThread detachNewThreadSelector:@selector(transftbitbang:) toTarget:arma
//						   withObject:directParameter];
}
@end
