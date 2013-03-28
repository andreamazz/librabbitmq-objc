//
//  AMQPExchange+Additions.h
//  SMARTClassroom
//
//  Created by Pedro Gomes on 27/11/2012.
//  Copyright (c) 2012 EF Education First. All rights reserved.
//

#import "AMQPExchange.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface AMQPExchange(Additions)

- (void)publishMessage:(NSString *)body messageID:(NSString *)messageID usingRoutingKey:(NSString *)theRoutingKey;

- (void)publishMessage:(NSString *)messageType
             messageID:(NSString *)messageID
               payload:(NSString *)body
       usingRoutingKey:(NSString *)theRoutingKey;

@end
