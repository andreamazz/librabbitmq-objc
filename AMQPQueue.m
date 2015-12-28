//
//  AMQPQueue.m
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

#import "AMQPQueue.h"

#import "AMQPChannel.h"
#import "AMQPExchange.h"
#import "AMQPConsumer.h"
#import "AMQPConnection.h"
#import "AMQPMessage.h"

uint16_t amqp_queue_ttl = 60000;
uint16_t amqp_queue_msg_ttl = 60000;

@interface AMQPQueue ()

@property (assign, readwrite) amqp_bytes_t internalQueue;
@property (strong, readwrite) AMQPChannel *channel;

@end

@implementation AMQPQueue

- (void)dealloc
{
	amqp_bytes_free(_internalQueue);
}

- (id)initWithName:(NSString *)theName
         onChannel:(AMQPChannel *)theChannel
         isPassive:(BOOL)passive
       isExclusive:(BOOL)exclusive
         isDurable:(BOOL)durable
   getsAutoDeleted:(BOOL)autoDelete
             error:(NSError * __autoreleasing *)error
{
    if ((self = [super init])) {
        amqp_table_t queue_args;
        amqp_table_entry_t entries[2];
        
        entries[0].key = amqp_cstring_bytes("x-message-ttl");
        entries[0].value.kind = AMQP_FIELD_KIND_I32;
        entries[0].value.value.i32 = amqp_queue_msg_ttl;
        
        entries[1].key = amqp_cstring_bytes("x-expires");
        entries[1].value.kind = AMQP_FIELD_KIND_I32;
        entries[1].value.value.i32 = amqp_queue_ttl;
        
        queue_args.num_entries = 2;
        queue_args.entries = entries;

		amqp_queue_declare_ok_t *declaration = amqp_queue_declare(theChannel.connection.internalConnection,
                                                                  theChannel.internalChannel,
                                                                  amqp_cstring_bytes([theName UTF8String]),
                                                                  passive,
                                                                  durable,
                                                                  exclusive,
                                                                  autoDelete,
                                                                  queue_args);
		
		[theChannel.connection checkLastOperation:@"Failed to declare queue" error:error];
		
    if (declaration == NULL){
        return nil;
    }
    
		_internalQueue = amqp_bytes_malloc_dup(declaration->queue);
		_channel = theChannel;
	}
	
	return self;
}

- (id)initPersistentWithName:(NSString *)theName
         onChannel:(AMQPChannel *)theChannel
         isPassive:(BOOL)passive
       isExclusive:(BOOL)exclusive
         isDurable:(BOOL)durable
   getsAutoDeleted:(BOOL)autoDelete
             error:(NSError * __autoreleasing *)error
{
    if ((self = [super init])) {
        amqp_queue_declare_ok_t *declaration = amqp_queue_declare(theChannel.connection.internalConnection,
                                                                  theChannel.internalChannel,
                                                                  amqp_cstring_bytes([theName UTF8String]),
                                                                  passive,
                                                                  durable,
                                                                  exclusive,
                                                                  autoDelete,
                                                                  amqp_empty_table);
        
        [theChannel.connection checkLastOperation:@"Failed to declare queue" error:error];
        
        if (declaration == NULL){
            return nil;
        }
        _internalQueue = amqp_bytes_malloc_dup(declaration->queue);
        _channel = theChannel;
    }
    
    return self;
}

- (void)bindToExchange:(AMQPExchange *)theExchange withKey:(NSString *)bindingKey error:(NSError * __autoreleasing *)error
{
	amqp_queue_bind(self.channel.connection.internalConnection,
                    self.channel.internalChannel,
                    self.internalQueue,
                    theExchange.internalExchange,
                    amqp_cstring_bytes([bindingKey UTF8String]),
                    AMQP_EMPTY_TABLE);
	
	[self.channel.connection checkLastOperation:@"Failed to bind queue to exchange" error:error];
}

- (void)unbindFromExchange:(AMQPExchange *)theExchange withKey:(NSString *)bindingKey error:(NSError * __autoreleasing *)error
{
    amqp_queue_unbind(self.channel.connection.internalConnection,
                      self.channel.internalChannel,
                      self.internalQueue,
                      theExchange.internalExchange,
                      amqp_cstring_bytes([bindingKey UTF8String]),
                      AMQP_EMPTY_TABLE);
	
	[self.channel.connection checkLastOperation:@"Failed to unbind queue from exchange" error:error];
}

- (AMQPConsumer *)startConsumerWithAcknowledgements:(BOOL)ack isExclusive:(BOOL)exclusive receiveLocalMessages:(BOOL)local error:(NSError * __autoreleasing *)error
{
	AMQPConsumer *consumer = [[AMQPConsumer alloc] initForQueue:self
                                                      onChannel:self.channel
                                            useAcknowledgements:ack
                                                    isExclusive:exclusive
                                           receiveLocalMessages:local
                                                          error:error];
	
	return consumer;
}

- (NSError *) formatError:(NSString *)reason {
    NSError *err = [NSError errorWithDomain:kAMQPDomain
                               code:kAMQPErrorCode
                           userInfo:@{
                                      NSLocalizedDescriptionKey: NSLocalizedString(@"AMQP Operation was unsuccessful.", nil),
                                      NSLocalizedFailureReasonErrorKey: reason
                                      }];
    return err;
}

- (NSString *)basicGet:(BOOL) ack error:(NSError * __autoreleasing *)error {
    amqp_rpc_reply_t reply = amqp_basic_get(self.channel.connection.internalConnection,
                                            self.channel.internalChannel,
                                            self.internalQueue,
                                            ack);

    [self.channel.connection checkLastOperation:@"Basic get from queue failed" error:error];
    if (reply.reply.id != AMQP_BASIC_GET_OK_METHOD)
      return nil;

    int result = -1;
    amqp_frame_t frame;
    size_t receivedBytes = 0;
    size_t bodySize = -1;
    amqp_bytes_t body;

    result = amqp_simple_wait_frame(self.channel.connection.internalConnection, &frame);
    if (result != 0){
        *error = [self formatError:@"Failure waiting for frame."];
        return nil; 
    }
    if (frame.frame_type != AMQP_FRAME_HEADER){
        *error = [self formatError:@"Expecting AMQP_FRAME_HEADER type of frame."];
        return nil;
    }
      
    /* This memory is valid until you call amqp_maybe_release_buffers() */
    amqp_basic_properties_t *props = (amqp_basic_properties_t*)frame.payload.properties.decoded;
      
    bodySize = (size_t)frame.payload.properties.body_size;
    receivedBytes = 0;
    body = amqp_bytes_malloc(bodySize);
      
    // Frame #3+: body frames
    while (receivedBytes < bodySize) {
        result = amqp_simple_wait_frame(_channel.connection.internalConnection, &frame);
        if (result < 0) {
            *error = [self formatError:@"Failure waiting for frame."];
            amqp_bytes_free(body);
            return nil;
        }
        
        if (frame.frame_type != AMQP_FRAME_BODY) {
            *error = [self formatError:@"Expecting AMQP_FRAME_BODY type of frame."];
            amqp_bytes_free(body);
            return nil;
        }
          
        receivedBytes += frame.payload.body_fragment.len;
        memcpy(body.bytes, frame.payload.body_fragment.bytes, frame.payload.body_fragment.len);
    }

    NSString *reply_to = AMQP_BYTES_TO_NSSTRING(props->reply_to);
    if (![reply_to hasPrefix:@"amq.rabbitmq.reply-to"]){
        *error = [self formatError:@"Invalid fast consumer queue."];
        return nil;
    }
    amqp_maybe_release_buffers(_channel.connection.internalConnection);
    amqp_bytes_free(body);
    return reply_to;
}

- (void)deleteQueueWithError:(NSError * __autoreleasing *)error
{
    amqp_queue_delete(self.channel.connection.internalConnection,
                      self.channel.internalChannel,
                      self.internalQueue, TRUE,
                      TRUE);
    
    [self.channel.connection checkLastOperation:@"Failed to delete queue" error:error];
}

@end
