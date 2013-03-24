//
//  RPServer.h
//  NuFeedback
//
//  Created by Eric O'Connell on 3/24/13.
//  Copyright (c) 2013 Eric O'Connell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

typedef struct {
    double roll, pitch, yaw;
    double ax, ay, az;
} payload;

@interface RPServer : NSObject <NSNetServiceDelegate>
{
	NSNetService *netService;
	GCDAsyncSocket *asyncSocket;
	NSMutableArray *connectedSockets;
    id serverDelegate;
}

- (RPServer *)initWithDelegate:(id)delegate;

// NSNetService delegate methods for publication
- (void)netServiceWillPublish:(NSNetService *)netService;
- (void)netService:(NSNetService *)netService
     didNotPublish:(NSDictionary *)errorDict;
- (void)netServiceDidStop:(NSNetService *)netService;

// Other methods
- (void)handleError:(NSNumber *)error withService:(NSNetService *)service;

@end

@protocol RPServerDelegate <NSObject>

- (void)didReceivePacket:(payload)p;

@end
