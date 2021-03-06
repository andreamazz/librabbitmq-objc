//
//  AMQPExchange.m
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

#import "AMQPExchange.h"

#import "AMQPChannel.h"
#import "AMQPConnection.h"

//#import "config.h"

#define AMQP_EXCHANGE_TYPE_DIRECT   @"direct"
#define AMQP_EXCHANGE_TYPE_FANOUT   @"fanout"
#define AMQP_EXCHANGE_TYPE_TOPIC    @"topic"

@interface AMQPExchange ()

@property (assign, readwrite) amqp_bytes_t internalExchange;
@property (strong, readwrite) AMQPChannel *channel;

@end

@implementation AMQPExchange

- (void)dealloc
{
	amqp_bytes_free(_internalExchange);
}

- (id)initExchangeOfType:(NSString *)theType withName:(NSString *)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError * __autoreleasing *)error
{
    if ((self = [super init])) {
		amqp_exchange_declare(theChannel.connection.internalConnection, theChannel.internalChannel, amqp_cstring_bytes([theName UTF8String]), amqp_cstring_bytes([theType UTF8String]), passive, durable, AMQP_EMPTY_TABLE);
		
		[theChannel.connection checkLastOperation:@"Failed to declare exchange" error:error];
		
		_internalExchange = amqp_bytes_malloc_dup(amqp_cstring_bytes([theName UTF8String]));
		_channel = theChannel;
	}
	
	return self;
}

- (id)initDirectExchangeWithName:(NSString *)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError * __autoreleasing *)error
{
	return [self initExchangeOfType:AMQP_EXCHANGE_TYPE_DIRECT withName:theName onChannel:theChannel isPassive:passive isDurable:durable getsAutoDeleted:autoDelete error:error];
}

- (id)initFanoutExchangeWithName:(NSString *)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError * __autoreleasing *)error
{
	return [self initExchangeOfType:AMQP_EXCHANGE_TYPE_FANOUT withName:theName onChannel:theChannel isPassive:passive isDurable:durable getsAutoDeleted:autoDelete error:error];
}

- (id)initTopicExchangeWithName:(NSString *)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError * __autoreleasing *)error
{
	return [self initExchangeOfType:AMQP_EXCHANGE_TYPE_TOPIC withName:theName onChannel:theChannel isPassive:passive isDurable:durable getsAutoDeleted:autoDelete error:error];
}

- (void)publishMessage:(NSString *)body usingRoutingKey:(NSString *)theRoutingKey error:(NSError * __autoreleasing *)error
{
	amqp_basic_publish(_channel.connection.internalConnection, _channel.internalChannel, _internalExchange, amqp_cstring_bytes([theRoutingKey UTF8String]), NO, NO, NULL, amqp_cstring_bytes([body UTF8String]));
	
	[_channel.connection checkLastOperation:@"Failed to publish message" error:error];
}

@end
