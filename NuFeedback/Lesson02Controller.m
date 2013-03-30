/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * A HUGE thanks to Fredric Echols for cleaning up
 * and optimizing the base code, making it more flexible!
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson02Controller.m */

#import "Lesson02Controller.h"
#import "RDFeedbackGLView.h"

@interface Lesson02Controller (InternalMethods)
- (void) setupRenderTimer;
- (void) updateGLView:(NSTimer *)timer;
- (void) createFailed;
@end

@implementation Lesson02Controller

- (void) awakeFromNib
{  
   [ NSApp setDelegate:self ];   // We want delegate notifications
   renderTimer = nil;
   [ glWindow makeFirstResponder:self ];
   [ glWindow setAcceptsMouseMovedEvents:TRUE ];
   [ glWindow setDelegate:self ];
   audioController = [[RPAudioController alloc] init];
   [audioController setUpAudio];
   glView = [ [ RDFeedbackGLView alloc ] initWithFrame:[ glWindow frame ]
             colorBits:32 depthBits:16 fullscreen:FALSE audioController:audioController ];
   if( glView != nil )
   {
      [ glWindow setContentView:glView ];
      [ glWindow makeKeyAndOrderFront:self ];
      [ self setupRenderTimer ];
	  zoomRot = true;
      panDelta = 0.005;
	  currentLocation = [NSEvent mouseLocation];
   }
   else
      [ self createFailed ];
}  


- (void) windowDidEnterFullScreen:(NSNotification *)notification {
    CGDisplayHideCursor(kCGDirectMainDisplay);
    isFullScreen = YES;
}

- (void) windowDidExitFullScreen:(NSNotification *)notification {
    CGDisplayShowCursor(kCGDirectMainDisplay);
    isFullScreen = NO;
}

/*
 * Setup timer to update the OpenGL view.
 */
- (void) setupRenderTimer
{
   NSTimeInterval timeInterval = 1.0 / 30.0;

   renderTimer = [ NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                   target:self
                                                 selector:@selector( updateGLView: )
                                                 userInfo:nil
                                                  repeats:YES ];
   [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
                                  forMode:NSEventTrackingRunLoopMode ];
   [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
                                  forMode:NSModalPanelRunLoopMode ];
}


/*
 * Called by the rendering timer.
 */
- (void) updateGLView:(NSTimer *)timer
{
   if( glView != nil )
      [ glView drawRect:[ glView frame ] ];
}  


/*
 * Handle key presses
 */
- (void) keyDown:(NSEvent *)theEvent
{
	unichar unicodeKey;
	unicodeKey = [ [ theEvent characters ] characterAtIndex:0 ];

	switch( unicodeKey )
	{
/* zoom / rotate */
		case 'i':
			[glView increaseZoomBy:0.001];
			break;
		
		case 'k':
			[glView decreaseZoomBy:0.001];
			break;

		case 'j':
			[glView decreaseRotationBy:0.001];
			break;
		
		case 'l':
			[glView increaseRotationBy:0.001];
			break;

		case 'I':
			[glView increaseZoom];
			break;
            
		case 'K':
			[glView decreaseZoom];
			break;
            
		case 'J':
			[glView decreaseRotation];
			break;
            
		case 'L':
			[glView increaseRotation];
			break;
            
/* panning */
		case 'w':
			[glView setCenterDx:0.0 andDy:panDelta / 10.0];
			break;
			
		case 's':
			[glView setCenterDx:0.0 andDy:-panDelta / 10.0];
			break;
			
		case 'a':
			[glView setCenterDx:-panDelta / 10.0 andDy:0];
			break;
			
		case 'd':
			[glView setCenterDx:panDelta / 10.0 andDy:0];
			break;
		          
		case 'W':
			[glView setCenterDx:0.0 andDy:panDelta];
			break;
			
		case 'S':
			[glView setCenterDx:0.0 andDy:-panDelta];
			break;
			
		case 'A':
			[glView setCenterDx:-panDelta andDy:0];
			break;
			
		case 'D':
			[glView setCenterDx:panDelta andDy:0];
			break;

		case '+':
			[glView changeLineWidth:0.5];
			break;

		case '-':
			[glView changeLineWidth:-0.5];
			break;
		
		case ' ':
			[glView reset];
			break;
			
		case '\t':
			[self switchMouseMode];
		
   }
}

//void keyboard(unsigned char key, int x, int y)
//{
//	if(key == 'z')
//		++menubarDisplacement;
//
//	if(key == 'x')
//		--menubarDisplacement;
//
//	if(key == 'j')
//		rot -= .0025;
//
//	if(key == 'l')
//		rot += .0025;
//
//	if(key == 'i')
//		size -= .0025;
//
//	if(key == 'k')
//		size += .0025;
//
//	if(key == 'w')
//		ycen += .001;
//
//	if(key == 'a')
//		xcen -= .001;
//
//	if(key == 's')
//		ycen -= .001;
//
//	if(key == 'd')
//		xcen += .001;
//
//	if(key == 't')
//		dt -= .000005;
//
//	if(key == 'T')
//		dt += .000005;
//
//	if(key == '-')
//		lineWidth -= .25;
//
//	if(key == '=')
//		lineWidth += .25;
//
//	if(key == 'b')
//		blur = !blur;
//
//	if(key == '\t')
//		zoomRot = !zoomRot;
//
//	if(key == ' ') {
//		size = 1.0;
//		rot = 0;
//		xcen = ycen = size / 2.0;
//	}
//}


- (void) mouseMoved:(NSEvent *)theEvent
{
	NSPoint newLocation = [NSEvent mouseLocation];

	float dx = (newLocation.x - currentLocation.x) / 1440.0;
	float dy = (newLocation.y - currentLocation.y) / 900.0;
	
    NSLog(@"dx: %f dy: %f", dx, dy);
    currentLocation = newLocation;
	
	if (zoomRot)
	{
		[glView increaseRotationBy:dx];
		[glView increaseZoomBy:dy];
	} else {
		[glView setCenterDx:dx/10.0 andDy:dy/10.0];
	}

    if (isFullScreen) {
        CGPoint center = CGPointMake(1440/2, 900/2);
        CGSetLocalEventsSuppressionInterval(0);
        CGWarpMouseCursorPosition(center);

        currentLocation = center;
    }
}

- (void) switchMouseMode {
	zoomRot = !zoomRot;
}


/*
 * Set full screen.
 */
- (IBAction)setFullScreen:(id)sender
{
   [ glWindow setContentView:nil ];
   if( [ glView isFullScreen ] )
   {
      if( ![ glView setFullScreen:FALSE inFrame:[ glWindow frame ] ] )
         [ self createFailed ];
      else
         [ glWindow setContentView:glView ];
   }
   else
   {
      if( ![ glView setFullScreen:TRUE
                    inFrame:NSMakeRect( 0, 0, 1200, 800 ) ] )
         [ self createFailed ];
   }
}


/*
 * Called if we fail to create a valid OpenGL view
 */
- (void) createFailed
{
   NSWindow *infoWindow;

   infoWindow = NSGetCriticalAlertPanel( @"Initialization failed",
                                         @"Failed to initialize OpenGL",
                                         @"OK", nil, nil );
   [ NSApp runModalForWindow:infoWindow ];
   [ infoWindow close ];
   [ NSApp terminate:self ];
}


/* 
 * Cleanup
 */
- (void) dealloc
{
   if( renderTimer != nil && [ renderTimer isValid ] )
      [ renderTimer invalidate ];
}

@end
