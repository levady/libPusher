//
//  PTPusherAPI.m
//  libPusher
//
//  Created by Luke Redpath on 14/08/2011.
//  Copyright 2011 LJR Software Limited. All rights reserved.
//

#import "PTPusherAPI.h"
#import "LRURLRequestOperation.h"
#import "JSON.h"
#import "NSString+Hashing.h"
#import "NSDictionary+QueryString.h"


#define kPUSHER_API_DEFAULT_HOST @"api.pusherapp.com"

@implementation PTPusherAPI

- (id)initWithKey:(NSString *)aKey appID:(NSString *)anAppID secretKey:(NSString *)aSecretKey
{
  if ((self = [super init])) {
    key = [aKey copy];
    appID = [anAppID copy];
    secretKey = [aSecretKey copy];
    operationQueue = [[NSOperationQueue alloc] init];
  }
  return self;
}

- (void)dealloc 
{
  [operationQueue release];
  [key release];
  [appID release];
  [secretKey release];
  [super dealloc];
}

- (void)triggetEvent:(NSString *)eventName onChannel:(NSString *)channelName data:(id)eventData socketID:(NSInteger)socketID
{
  NSString *path = [NSString stringWithFormat:@"/apps/%@/channels/%@/events", appID, channelName];
  NSString *body = [eventData JSONRepresentation];
  
  NSMutableDictionary *queryParameters = [NSMutableDictionary dictionary];
  
  [queryParameters setObject:eventData forKey:@"name"];
  [queryParameters setValue:[[body MD5Hash] lowercaseString] forKey:@"body_md5"];
  [queryParameters setValue:key forKey:@"auth_key"];
  [queryParameters setValue:[NSNumber numberWithDouble:time(NULL)] forKey:@"auth_timestamp"];
  [queryParameters setValue:@"1.0" forKey:@"auth_version"];
  [queryParameters setValue:eventName forKey:@"name"];
  
  if (socketID > 0) {
    [queryParameters setObject:[NSNumber numberWithInteger:socketID] forKey:@"socket_id"];
  }
    
  NSString *signatureString = [NSString stringWithFormat:@"POST\n%@\n%@", path, [queryParameters sortedQueryString]];
  
  [queryParameters setObject:[signatureString HMACDigestUsingSecretKey:secretKey] forKey:@"auth_signature"];
  
  NSString *URLString = [NSString stringWithFormat:@"http://%@%@?%@", kPUSHER_API_DEFAULT_HOST, path, [queryParameters sortedQueryString]];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
  [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
  [request setHTTPMethod:@"POST"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

  LRURLRequestOperation *operation = [[LRURLRequestOperation alloc] initWithURLRequest:request];
  [operationQueue addOperation:operation];
  [operation release];
}

@end
