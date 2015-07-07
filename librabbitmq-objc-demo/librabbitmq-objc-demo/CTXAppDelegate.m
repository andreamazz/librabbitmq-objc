//
//  CTXAppDelegate.m
//  librabbitmq-objc-demo
//
//  Created by Alberto De Bortoli on 13/01/2014.
//  Copyright (c) 2014 EF Education First. All rights reserved.
//

#import "CTXAppDelegate.h"

#import <AMQPConnection.h>
#import <AMQPChannel.h>

@implementation CTXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[UIViewController alloc] init];
    [self.window makeKeyAndVisible];

    NSError *error;
    AMQPConnection *connection = [[AMQPConnection alloc] init];
    [connection connectToHost:@"127.0.0.1" onPort:5672 error:&error];
    if (error) { NSLog(@"%@", error); }

    [connection loginAsUser:@"guest" withPassword:@"guest" onVHost:@"/" error:&error];
    if (error) { NSLog(@"%@", error); }

    AMQPChannel *channel = [connection openChannelWithError:&error];
    if (error) { NSLog(@"%@", error); }

    [channel close];
    return YES;
}

@end
