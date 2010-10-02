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

@interface ArmadilloApp : NSApplication
Armadillo *arma;
@end
@implementation ArmadilloApp
-(void)setArmaObj:(Armadillo *)theobj
{
	NSLog(@"MORI MORI NSApp");
	arma = theobj;
}

-(void)ArmadilloTest:(NSScriptCommand*)command {
	NSLog(@"MORI MORI AppleScript");
	[arma ftbitbangInit:nil];
	/*
	NSDictionary*	theArgs = [command evaluatedArguments];
	NSString*		encodeString = [theArgs objectForKey:@"textWith"];
	NSData *sjisData = [ encodeString dataUsingEncoding: 
						NSShiftJISStringEncoding ];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: 
	 @"ServiceNotificaiton" object: sjisData];
*/
}

@end
