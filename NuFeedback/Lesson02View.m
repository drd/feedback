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

/* Lesson02View.m */

#import "Lesson02View.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

@interface Lesson02View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
@end

@implementation Lesson02View

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (__bridge NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   pixelFormat = [ self createPixelFormat:frame ];
   if( pixelFormat != nil )
   {
      self = [ super initWithFrame:frame pixelFormat:pixelFormat ];
      if( self )
      {
         [ [ self openGLContext ] makeCurrentContext ];
         if( runningFullScreen )
            [ [ self openGLContext ] setFullScreen ];
         [ self reshape ];
         if( ![ self initGL ] )
         {
            [ self clearGLContext ];
            self = nil;
         }
         [self setWantsBestResolutionOpenGLSurface:YES]; 
      }
   }
   else
      self = nil;

   t = 0;

   return self;
}


/*
 * Create a pixel format and possible switch to full screen mode
 */
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame
{
   NSOpenGLPixelFormatAttribute pixelAttribs[ 16 ];
   int pixNum = 0;
   NSDictionary *fullScreenMode;
   NSOpenGLPixelFormat *pixelFormat;

   pixelAttribs[ pixNum++ ] = NSOpenGLPFADoubleBuffer;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFAAccelerated;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFAColorSize;
   pixelAttribs[ pixNum++ ] = colorBits;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFADepthSize;
   pixelAttribs[ pixNum++ ] = depthBits;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFAMultisample;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFASampleBuffers;
   pixelAttribs[ pixNum++ ] = (NSOpenGLPixelFormatAttribute)1;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFASamples;
   pixelAttribs[ pixNum++ ] = (NSOpenGLPixelFormatAttribute)4;

   if( runningFullScreen )  // Do this before getting the pixel format
   {
      pixelAttribs[ pixNum++ ] = NSOpenGLPFAFullScreen;
      fullScreenMode = (__bridge NSDictionary *) CGDisplayBestModeForParameters(
                                           kCGDirectMainDisplay,
                                           colorBits, frame.size.width,
                                           frame.size.height, NULL );
      CGDisplayCapture( kCGDirectMainDisplay );
      CGDisplayHideCursor( kCGDirectMainDisplay );
      CGDisplaySwitchToMode( kCGDirectMainDisplay,
                             (__bridge CFDictionaryRef) fullScreenMode );
   }
   pixelAttribs[ pixNum ] = 0;
   pixelFormat = [ [ NSOpenGLPixelFormat alloc ]
                   initWithAttributes:pixelAttribs ];

   return pixelFormat;
}


/*
 * Enable/disable full screen mode
 */
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame
{
   BOOL success = FALSE;
   NSOpenGLPixelFormat *pixelFormat;
   NSOpenGLContext *newContext;

   [ [ self openGLContext ] clearDrawable ];
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   runningFullScreen = enableFS;
   pixelFormat = [ self createPixelFormat:frame ];
   if( pixelFormat != nil )
   {
      newContext = [ [ NSOpenGLContext alloc ] initWithFormat:pixelFormat
                     shareContext:nil ];
      if( newContext != nil )
      {
         [ super setFrame:frame ];
         [ super setOpenGLContext:newContext ];
         [ newContext makeCurrentContext ];
         if( runningFullScreen )
            [ newContext setFullScreen ];
         [ self reshape ];
         if( [ self initGL ] )
            success = TRUE;
      }
   }
   if( !success && runningFullScreen )
      [ self switchToOriginalDisplayMode ];

   return success;
}


/*
 * Switch to the display mode in which we originally began
 */
- (void) switchToOriginalDisplayMode
{
   CGDisplaySwitchToMode( kCGDirectMainDisplay,
                          (__bridge CFDictionaryRef) originalDisplayMode );
   CGDisplayShowCursor( kCGDirectMainDisplay );
   CGDisplayRelease( kCGDirectMainDisplay );
}


/*
 * Initial OpenGL setup
 */
- (BOOL) initGL
{ 
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glEnable( GL_TEXTURE_2D );                             // Enable Texture Mapping 
   glEnable(GL_MULTISAMPLE);


   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT); 
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT); 

   tex1 = [self createTextureWithSize:512 andChannels:3 ofType:GL_RGB];
   tex2 = [self createTextureWithSize:512 andChannels:3 ofType:GL_RGB];

   glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
   
   return TRUE;
}

- (int) createTextureWithSize:(int)size andChannels:(int)channels ofType:(int)type
{
	GLuint textureId;
	
    // Create a pointer to store the blank image data
    unsigned int *pTexture = NULL;                             
    pTexture = malloc(sizeof(unsigned int) *  size * size * channels);
    memset(pTexture, 0, size * size * channels * sizeof(unsigned int));    

    // Register the texture with OpenGL and bind it to the texture ID
    glGenTextures(1, &textureId);                                
    glBindTexture(GL_TEXTURE_2D, textureId);                    
    
    // Create the texture and store it on the video card
    glTexImage2D(GL_TEXTURE_2D, 0, channels, size, size, 0, type, GL_UNSIGNED_INT, pTexture);                        
    
    // Set the texture quality
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR_MIPMAP_NEAREST);

	// unbind the texture
    glBindTexture(GL_TEXTURE_2D, 0);

    // Since we stored the texture space with OpenGL, we can delete the image data
    free(pTexture);     
	
	return textureId;																			
}

- (void) viewOrtho							// Set Up An Ortho View
{
	glMatrixMode(GL_PROJECTION);					// Select Projection
	glPushMatrix();							// Push The Matrix
	glLoadIdentity();						// Reset The Matrix
	glOrtho( 0, 640 , 480 , 0, -1, 1 );				// Select Ortho Mode (640x480)
	glMatrixMode(GL_MODELVIEW);					// Select Modelview Matrix
	glPushMatrix();							// Push The Matrix
	glLoadIdentity();						// Reset The Matrix
}

- (void) viewPerspective							// Set Up A Perspective View
{
	glMatrixMode( GL_PROJECTION );					// Select Projection
	glPopMatrix();							// Pop The Matrix
	glMatrixMode( GL_MODELVIEW );					// Select Modelview
	glPopMatrix();							// Pop The Matrix
}

/*
 * Resize ourself
 */
- (void) reshape
{ 
   NSRect sceneBounds;
   
   [ [ self openGLContext ] update ];
   sceneBounds = [ self bounds ];
   // Reset current viewport
   glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
   glMatrixMode( GL_PROJECTION );   // Select the projection matrix
   glLoadIdentity();                // and reset it
   // Calculate the aspect ratio of the view
   gluPerspective( 45.0f, sceneBounds.size.width / sceneBounds.size.height,
                   0.1f, 100.0f );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
   // Clear the screen and depth buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glLoadIdentity();   // Reset the current modelview matrix

   [self viewOrtho];

//   glTranslatef( 0.0f, 0.0f, -4.0f );   // Left 1.5 units, into screen 6.0
//   glRotatef( t, 0.0f, 0.0f, 1.0f );

   glBindTexture(GL_TEXTURE_2D, tex1);
   glViewport(0, 0, 640, 480);

	glBegin( GL_QUADS );                // Draw a quad
		glTexCoord2f(0,0); glVertex2f(0,0);
		glTexCoord2f(0,1); glVertex2f(0,480);
		glTexCoord2f(1,1); glVertex2f(640,480);
		glTexCoord2f(1,0); glVertex2f(640,0);
	glEnd();
   
   glViewport(0, 0, 512, 512);
   glBindTexture(GL_TEXTURE_2D, tex1);
   glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, 0, 0, 512, 512, 0);

	glBegin( GL_QUADS );                // Draw a quad
		glTexCoord2f(0,0); glVertex2f(0,0);
		glTexCoord2f(0,1); glVertex2f(0,512);
		glTexCoord2f(1,1); glVertex2f(512,512);
		glTexCoord2f(1,0); glVertex2f(512,0);
	glEnd();

   glBindTexture(GL_TEXTURE_2D, tex2);
   glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, 0, 0, 512, 512, 0);

	glBegin( GL_QUADS );                // Draw a quad
		glTexCoord2f(0,0); glVertex2f(0,0);
		glTexCoord2f(0,1); glVertex2f(0,512);
		glTexCoord2f(1,1); glVertex2f(512,512);
		glTexCoord2f(1,0); glVertex2f(512,0);
	glEnd();
   
   [self viewPerspective];
   
//   [self reshape];
//   glTranslatef( 3.0f, 0.0f, 0.0f );    // Move right 3 units

   glBegin( GL_QUADS );                // Draw a quad
   glVertex3f( -1.0f,  1.0f, 0.0f );   // Top left
   glVertex3f(  1.0f,  1.0f, 0.0f );   // Top right
   glVertex3f(  1.0f, -1.0f, 0.0f );   // Bottom right
   glVertex3f( -1.0f, -1.0f, 0.0f );   // Bottom left
   glEnd();                            // Quad is complete

   [ [ self openGLContext ] flushBuffer ];
   
   t+=.05;
}


/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
   return runningFullScreen;
}


/*
 * Cleanup
 */
- (void) dealloc
{
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
}

@end
