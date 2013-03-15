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
   glView = [ [ RDFeedbackGLView alloc ] initWithFrame:[ glWindow frame ]
              colorBits:32 depthBits:16 fullscreen:FALSE ];
   if( glView != nil )
   {
      [ glWindow setContentView:glView ];
      [ glWindow makeKeyAndOrderFront:self ];
      [ self setupRenderTimer ];
	  zoomRot = true;
	   panDelta = 0.05;
	  currentLocation = [NSEvent mouseLocation];
   }
   else
      [ self createFailed ];
}  


/*
 * Setup timer to update the OpenGL view.
 */
- (void) setupRenderTimer
{
   NSTimeInterval timeInterval = 1.0 / 30.0;

   renderTimer = [ [ NSTimer scheduledTimerWithTimeInterval:timeInterval
                             target:self
                             selector:@selector( updateGLView: )
                             userInfo:nil repeats:YES ] retain ];
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
		case 'i':
			[glView increaseZoom];
			break;
		
		case 'k':
			[glView decreaseZoom];
			break;

		case 'j':
			[glView decreaseRotation];
			break;
		
		case 'l':
			[glView increaseRotation];
			break;

		case 'w':
			[glView setCenterDx:0.0 andDy:panDelta];
			break;
			
		case 's':
			[glView setCenterDx:0.0 andDy:-panDelta];
			break;
			
		case 'a':
			[glView setCenterDx:-panDelta andDy:0];
			break;
			
		case 'd':
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

- (void) mouseMoved:(NSEvent *)theEvent
{
	NSPoint newLocation = [NSEvent mouseLocation];

	float dx = (newLocation.x - currentLocation.x) / 1440.0;
	float dy = (newLocation.y - currentLocation.y) / 900.0;
	
	currentLocation = newLocation;
	
	if (zoomRot)
	{
		[glView increaseRotationBy:dx];
		[glView increaseZoomBy:dy];
	} else {
		[glView setCenterDx:dx/10.0 andDy:dy/10.0];
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
                    inFrame:NSMakeRect( 0, 0, 800, 600 ) ] )
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
   [ glWindow release ]; 
   [ glView release ];
   if( renderTimer != nil && [ renderTimer isValid ] )
      [ renderTimer invalidate ];

	[super dealloc ];
}

@end
