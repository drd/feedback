//
//  RPAudioController.m
//  NuFeedback
//
//  Created by David McCabe on 3/28/13.
//  Copyright (c) 2013 Eric O'Connell. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>
#import "RPAudioController.h"

/*
 This struct stores the data used or modified by the recording function, which,
 because it runs in a real-time thread, isn't to send Objective-C messages.
 */
typedef struct AudioControllerState
{
	AudioStreamBasicDescription streamFormat;
	AudioUnit inputUnit;
    AudioBufferList *bufferList;
    Float32 loudness;
    Float32 pitch;
} AudioControllerState;

@interface RPAudioController ()
@property (assign) AudioControllerState state;
@end

static void CheckErrorInternal(OSStatus error, char *filename, int line)
{
    if(error != noErr) {
        NSLog(@"Error %d at %s:%d", (int)error, filename, line);
        exit(1);
    }
}
#define CheckError(expr) CheckErrorInternal(expr, __FILE__, __LINE__)

/*
 This function accepts incoming sound data and pulls out
 some statistics for the rest of the program to use.
 It runs it a real-time thread, so it shouldn't allocate
 memory, send Objective-C messages, take locks, or do anything
 else with an unpredictable time.
 */
static OSStatus InputRenderProc(void *inRefCon,
						 AudioUnitRenderActionFlags *ioActionFlags,
						 const AudioTimeStamp *inTimeStamp,
						 UInt32 inBusNumber,
						 UInt32 inNumberFrames,
						 AudioBufferList * ioData /* NULL and unused. */)
{
	AudioControllerState *state = (AudioControllerState *)inRefCon;
    
    /* Have the incoming data placed into state->bufferList. */
    CheckError(AudioUnitRender(state->inputUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, state->bufferList));
    Float32 *samples = state->bufferList->mBuffers[0].mData;
    UInt32 sampleCount = state->bufferList->mBuffers[0].mDataByteSize / sizeof(Float32);

    /* Loudness is the sum of the magnitude of the samples. */
    vDSP_svemg(samples, 1, &state->loudness, sampleCount);
    
    /* Pitch is roughly estimated by zero crossings.
       In the absence of sound, the noise in the signal gives a basically random
       zero-crossing count, so set pitch to 0 if the signal is too quiet. */
    if(state->loudness < 1) {
        state->pitch = 0;
    } else {
        vDSP_Length crossings, unused;
        vDSP_nzcros(samples, 1, sampleCount, &unused, &crossings, sampleCount);
        Float32 secondsRepresentedByBuffer = (float)sampleCount / (float)state->streamFormat.mSampleRate;
        state->pitch = (float)crossings / secondsRepresentedByBuffer;
    }
    
    
    
    return noErr;
}

@implementation RPAudioController

- (void)setUpAudio
{
    /*
     Based on http://developer.apple.com/library/mac/#technotes/tn2091/_index.html
     Note that the so-called "HALOutput" unit actually handles input here.
     This is basically a bunch of tedious goop that you don't need to read.
     */
    
    /***** LISTING 1: Creating an AudioOutputUnit *****/
    
    AudioComponent comp;
    AudioComponentDescription desc;
    AudioComponentInstance auHAL;
    
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_HALOutput;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    comp = AudioComponentFindNext(NULL, &desc);
    assert(comp != NULL);
    AudioComponentInstanceNew(comp, &auHAL);
    
    
    /***** LISTING 3: Enabling IO *****/
    
    UInt32 disabled = 0;
    UInt32 enabled = 1;
    CheckError(AudioUnitSetProperty(auHAL, kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input, 1 /* input element */,
                                    &enabled, sizeof(enabled)));
    CheckError(AudioUnitSetProperty(auHAL, kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Output, 0 /* output element */,
                                    &disabled, sizeof(disabled)));
    
    
    /***** LISTING 4: Setting the current device *****/
    
    AudioDeviceID inputDevice;
    UInt32 size = sizeof(AudioDeviceID);
    
    AudioObjectPropertyAddress theAddress = {
        kAudioHardwarePropertyDefaultInputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster };

    CheckError(AudioObjectGetPropertyData(kAudioObjectSystemObject, &theAddress, 0, NULL, &size, &inputDevice));
    
    CheckError(AudioUnitSetProperty(auHAL, kAudioOutputUnitProperty_CurrentDevice,
                                    kAudioUnitScope_Global, 0,
                                    &inputDevice, size));
    
    
    /***** LISTING 5: Setting the stream format *****/
    
    AudioStreamBasicDescription deviceFormat;
    size = sizeof(AudioStreamBasicDescription);
    
    CheckError(AudioUnitGetProperty(auHAL, kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input, 1,
                                    &deviceFormat, &size));
    
    int bytesPerSample = sizeof(Float32);
    AudioStreamBasicDescription inputStreamFormat = {0};
    inputStreamFormat.mFormatID         = kAudioFormatLinearPCM;
    inputStreamFormat.mFormatFlags      = kAudioFormatFlagIsFloat |
                                        kAudioFormatFlagsNativeEndian |
                                        kAudioFormatFlagIsPacked |
                                        kAudioFormatFlagIsNonInterleaved;
    inputStreamFormat.mBytesPerPacket   = bytesPerSample;
    inputStreamFormat.mBytesPerFrame    = bytesPerSample;
    inputStreamFormat.mFramesPerPacket  = 1;
    inputStreamFormat.mBitsPerChannel   = 8 * bytesPerSample;
    inputStreamFormat.mChannelsPerFrame = 2;
    inputStreamFormat.mSampleRate       = deviceFormat.mSampleRate;

    CheckError(AudioUnitSetProperty(auHAL, kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output, 1,
                                    &inputStreamFormat, sizeof(inputStreamFormat)));
    
    
    /***** LISTING 7: Setting the input proc ******/
    
    AURenderCallbackStruct input;
    input.inputProc = InputRenderProc;
    input.inputProcRefCon = &_state;
    
    CheckError(AudioUnitSetProperty(auHAL, kAudioOutputUnitProperty_SetInputCallback,
                                    kAudioUnitScope_Global, 0,
                                    &input, sizeof(input)));
    

    /***** INTERLUDE: Allocating buffers to record into *****/
    
	UInt32 framesPerBuffer = 0;
	size = sizeof(UInt32);
	CheckError(AudioUnitGetProperty(auHAL, kAudioDevicePropertyBufferFrameSize,
                                    kAudioUnitScope_Global, 0,
                                    &framesPerBuffer, &size));
    
	UInt32 bytesPerBuffer = framesPerBuffer * sizeof(Float32);
    UInt32 bufferListSize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * inputStreamFormat.mChannelsPerFrame);
    
    _state.bufferList = (AudioBufferList *)malloc(bufferListSize);
    assert(_state.bufferList);
    _state.bufferList->mNumberBuffers = inputStreamFormat.mChannelsPerFrame;
    
    for(UInt32 i =0; i< _state.bufferList->mNumberBuffers ; i++) {
        _state.bufferList->mBuffers[i].mNumberChannels = 1;
        _state.bufferList->mBuffers[i].mDataByteSize = bytesPerBuffer;
        _state.bufferList->mBuffers[i].mData = malloc(bytesPerBuffer);
        assert(_state.bufferList->mBuffers[i].mData);
    }

    
    /***** LISTING 8: Starting the unit ******/
    
    _state.inputUnit = auHAL;
    _state.streamFormat = inputStreamFormat;
    
    AudioUnitInitialize(auHAL);
    AudioOutputUnitStart(auHAL);
}


- (Float32)loudness
{
    return self.state.loudness;
}

- (Float32)pitch
{
    return self.state.pitch;
}

@end
