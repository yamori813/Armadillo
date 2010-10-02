//
//  main.m
//  Armadillo
//
//  Created by H.M on 10/08/29.
//  Copyright 2010 Hiroki Mori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
    return NSApplicationMain(argc,  (const char **) argv);
}

@interface ArmadilloApp : NSApplication
@end
@implementation ArmadilloApp
-(void)ArmadilloTest:(NSScriptCommand*)command {
	printf("MORI MORI AppleScript");
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
