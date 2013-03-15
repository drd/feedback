//
//  RPAppDelegate.m
//  NuFeedback
//
//  Created by Eric O'Connell on 3/13/13.
//  Copyright (c) 2013 Eric O'Connell. All rights reserved.
//

#import "RPAppDelegate.h"
#import "Lesson02Controller.h"

@implementation RPAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    Lesson02Controller *controller = [[Lesson02Controller alloc] init];
    [controller awakeFromNib];
}

@end
