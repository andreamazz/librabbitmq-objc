//
//  AMQPConnection.h
//  Objective-C wrapper for librabbitmq-c
//
//  Copyright 2009 Max Wolter. All rights reserved.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Foundation/Foundation.h>

#import "AMQPObject.h"

extern NSString *const kAMQPDomain;
extern NSInteger const kAMQPErrorCode;

@class AMQPChannel;

@interface AMQPConnection : AMQPObject

@property (nonatomic, readonly) amqp_connection_state_t internalConnection;

- (void)connectToHost:(NSString *)host onPort:(int)port error:(NSError * __autoreleasing *)error;
- (void)loginAsUser:(NSString *)username withPassword:(NSString *)password onVHost:(NSString *)vhost error:(NSError * __autoreleasing *)error;
- (void)disconnectWithError:(NSError * __autoreleasing *)error; // all channels have to be closed before closing the connection

- (void)checkLastOperation:(NSString *)context error:(NSError * __autoreleasing *)error;

- (AMQPChannel *)openChannelWithError:(NSError * __autoreleasing *)error;

- (BOOL)check;

@end
