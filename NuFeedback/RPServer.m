//
//  RPServer.m
//  NuFeedback
//
//  Created by Eric O'Connell on 3/24/13.
//  Copyright (c) 2013 Eric O'Connell. All rights reserved.
//

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"

#import "RPServer.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation RPServer

- (RPServer *)initWithDelegate:(id)delegate {
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	[DDLog addLogger:[DDASLLogger sharedInstance]];

    serverDelegate = delegate;
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                             delegateQueue:dispatch_get_main_queue()];
	// Create an array to hold accepted incoming connections.
	
	connectedSockets = [[NSMutableArray alloc] init];
	
	// Now we tell the socket to accept incoming connections.
	// We don't care what port it listens on, so we pass zero for the port number.
	// This allows the operating system to automatically assign us an available port.
	
	NSError *err = nil;
	if ([asyncSocket acceptOnPort:0 error:&err])
	{
		// So what port did the OS give us?
		
		UInt16 port = [asyncSocket localPort];
		
		// Create and publish the bonjour service.
		// Obviously you will be using your own custom service type.
		
		netService = [[NSNetService alloc] initWithDomain:@"local."
		                                             type:@"_feedback._tcp."
		                                             name:@""
		                                             port:port];
		
		[netService setDelegate:self];
		[netService publish];
		
		// You can optionally add TXT record stuff
		
		NSMutableDictionary *txtDict = [NSMutableDictionary dictionaryWithCapacity:2];
		
		[txtDict setObject:@"ohai" forKey:@"kthx"];
		
		NSData *txtData = [NSNetService dataFromTXTRecordDictionary:txtDict];
		[netService setTXTRecordData:txtData];
	}
	else
	{
		DDLogError(@"Error in acceptOnPort:error: -> %@", err);
	}
    
    return self;
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	DDLogInfo(@"Accepted new socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);
	
	// The newSocket automatically inherits its delegate & delegateQueue from its parent.
    [connectedSockets addObject:newSocket];
    [newSocket readDataToLength:48 withTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	// This method is executed on the socketQueue (not the main thread)
    payload p;
    NSData *payloadData = [data subdataWithRange:NSMakeRange(0, [data length] - [[GCDAsyncSocket ZeroData] length])];
    [payloadData getBytes:&p];
    [serverDelegate didReceivePacket:p];
    NSLog(@"Heyo, got a packet.. %f %f %f", p.roll, p.pitch, p.yaw);
    NSLog(@"Heyo, got a packet.. %f %f %f", p.ax, p.ay, p.az);

    [sock readDataToLength:48 withTimeout:-1 tag:0];
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	[connectedSockets removeObject:sock];
}

- (void)netServiceDidPublish:(NSNetService *)ns
{
	DDLogInfo(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)",
			  [ns domain], [ns type], [ns name], (int)[ns port]);
}

- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict
{
	// Override me to do something here...
	//
	// Note: This method in invoked on our bonjour thread.
	
	DDLogError(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@",
               [ns domain], [ns type], [ns name], errorDict);
}

@end
