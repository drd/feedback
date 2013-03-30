//
//  RPAudioController.h
//  NuFeedback
//
//  Created by David McCabe on 3/28/13.
//  Copyright (c) 2013 Eric O'Connell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RPAudioController : NSObject

- (void)setUpAudio;
- (Float32)loudness;
- (Float32)pitch;

@end
