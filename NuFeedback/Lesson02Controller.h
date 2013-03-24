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

/* Lesson02Controller.h */

#import <Cocoa/Cocoa.h>
#import "Lesson02View.h"
#import "RDFeedbackGLView.h"
#import "RPServer.h"

@interface Lesson02Controller : NSResponder <RPServerDelegate>
{
	IBOutlet NSWindow *glWindow;

	NSTimer *renderTimer;
	RDFeedbackGLView *glView;
   
	NSPoint currentLocation;
    bool isFullScreen;
    
	bool zoomRot;
	float panDelta;
    RPServer *server;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;
- (void) switchMouseMode;

- (void) didReceivePacket:(payload)p;

@end
