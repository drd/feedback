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

/* Lesson02View.h */

#import <Cocoa/Cocoa.h>

@interface Lesson02View : NSOpenGLView
{
   int colorBits, depthBits;
   float t;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLuint tex1, tex2;
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;
- (int) createTextureWithSize:(int)size andChannels:(int)channels ofType:(int)type;
- (void) viewPerspective;
- (void) viewOrtho;


@end
