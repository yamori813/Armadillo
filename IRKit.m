//
//  IRKit.m
//  Armadillo
//
//  Created by hiroki on 16/12/29.
//  Copyright 2016 __MyCompanyName__. All rights reserved.
//

#import "IRKit.h"


@implementation IRKit

- (void) send:(NSString *)data host:(NSString *)host
{
	NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/messages", host]];
	NSMutableURLRequest* urlRequest = [[NSMutableURLRequest alloc]initWithURL:url];
	[urlRequest setHTTPMethod:@"POST"];
	NSString *bodystr = [NSString stringWithFormat:@"{\"format\":\"raw\",\"freq\":38,\"data\":[%@]}", data];
	NSLog(@"%@", bodystr);
	[urlRequest setHTTPBody:[bodystr dataUsingEncoding:NSUTF8StringEncoding]];
	NSURLResponse* response;
	NSError* error;
	NSData* result = [NSURLConnection sendSynchronousRequest:urlRequest
										   returningResponse:&response
													   error:&error];
}

@end
