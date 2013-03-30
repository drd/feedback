//
//  RDFeedbackGLView.m
//  Lesson02_OSXCocoa
//
//  Created by Eric O'Connell on 11/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RDFeedbackGLView.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>


// From https://github.com/alessani/ColorConverter
// One could also implement HSL as a fragment shader:
// http://stackoverflow.com/questions/9569068/gradient-with-hsv-rather-than-rgb-in-opengl
static void HSL2RGB(float h, float s, float l, float* outR, float* outG, float* outB)
{
	float			temp1,
    temp2;
	float			temp[3];
	int				i;
	
	// Check for saturation. If there isn't any just return the luminance value for each, which results in gray.
	if(s == 0.0) {
		if(outR)
			*outR = l;
		if(outG)
			*outG = l;
		if(outB)
			*outB = l;
		return;
	}
	
	// Test for luminance and compute temporary values based on luminance and saturation
	if(l < 0.5)
		temp2 = l * (1.0 + s);
	else
		temp2 = l + s - l * s;
    temp1 = 2.0 * l - temp2;
	
	// Compute intermediate values based on hue
	temp[0] = h + 1.0 / 3.0;
	temp[1] = h;
	temp[2] = h - 1.0 / 3.0;
    
	for(i = 0; i < 3; ++i) {
		
		// Adjust the range
		if(temp[i] < 0.0)
			temp[i] += 1.0;
		if(temp[i] > 1.0)
			temp[i] -= 1.0;
		
		
		if(6.0 * temp[i] < 1.0)
			temp[i] = temp1 + (temp2 - temp1) * 6.0 * temp[i];
		else {
			if(2.0 * temp[i] < 1.0)
				temp[i] = temp2;
			else {
				if(3.0 * temp[i] < 2.0)
					temp[i] = temp1 + (temp2 - temp1) * ((2.0 / 3.0) - temp[i]) * 6.0;
				else
					temp[i] = temp1;
			}
		}
	}
	
	// Assign temporary values to R, G, B
	if(outR)
		*outR = temp[0];
	if(outG)
		*outG = temp[1];
	if(outB)
		*outB = temp[2];
}

// http://stackoverflow.com/questions/4633177/c-how-to-wrap-a-float-to-the-interval-pi-pi
static double inline fwrap(double x, double y)
{
    if (0 == y) return x;
    return x - y * floor(x/y);
}


@implementation RDFeedbackGLView

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
       audioController:(RPAudioController *)theAudioController
{
	self = [super initWithFrame:frame colorBits:numColorBits depthBits:numDepthBits fullscreen:runFullScreen];

    if (self) {
		// initial values
		texture_resolution = 4096;
		
		t = 0; dt = .001;
		rot = 0; size = 1;
		xcen = .5; ycen = .5;

		lineWidth = 1;
		blur = false;

		// set up GL
		[self initGL];
		[self initFrameBuffer:&fbo1 ofSize:texture_resolution withRenderBuffer:&rb1 andTexture:&tb1];
		[self initFrameBuffer:&fbo2 ofSize:texture_resolution withRenderBuffer:&rb2 andTexture:&tb2];
        
        audioController = theAudioController;
    }

	return self;
}

//- (id)initWithFrame:(NSRect)frame {
//    self = [super initWithFrame:frame];
//
//    if (self) {
//		// initial values
//		texture_resolution = 2048;
//		
//		t = 0; dt = .001;
//		rot = 0; size = 1;
//		xcen = .5; ycen = .5;
//
//		lineWidth = 1;
//		blur = false;
//		zoomRot = true;
//
//		// set up GL
//		[self initGL];
//		[self initFrameBuffer:&fbo1 ofSize:texture_resolution withRenderBuffer:&rb1 andTexture:&tb1];
//		[self initFrameBuffer:&fbo2 ofSize:texture_resolution withRenderBuffer:&rb2 andTexture:&tb2];
//    }
//	
//    return self;
//}

- (void)clear {
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)setViewportWidth:(int)width andHeight:(int)height {
	glViewport(0, 0, width, height);
}

- (void)drawRect:(NSRect)rect {
	[self incrementTime];
	[self clear];
	[self setViewportWidth: texture_resolution andHeight:texture_resolution];

	[self bindFrameBuffer:fbo1];
	[self setViewportWidth: texture_resolution andHeight:texture_resolution];

	[self viewOrthoWithWidth:texture_resolution	andHeight:texture_resolution];
	[self drawPlaneWithTexture:tb2];

	[self bindFrameBuffer:fbo2];

	[self drawFullTexture:tb1 ofResolution:texture_resolution];

	[self viewPerspective];
	[self drawSineWave];

	[self bindFrameBuffer:0];
	
	[self drawScaledTextureToView:tb2];

	[[self openGLContext] flushBuffer];
}

- (void) drawScaledTextureToView:(GLuint)texture {
	float s1,t1,s2,t2;
	float scaleFactor;
	float screenWidth =  (float)[self width];
	float screenHeight =  (float)[self height];

	[self bindTexture:texture];

	[self setViewportWidth:[self width] andHeight:[self height]];
	[self viewOrthoWithWidth:[self width] andHeight:[self height]];
	
	if (screenWidth > screenHeight) {
		s1 = 0.0; s2 = 1.0;
		scaleFactor = (1.0 - ((float)screenHeight/(float)screenWidth))/2.0;
		t1 = scaleFactor;
		t2 = 1.0 - scaleFactor;
	} else {
		t1 = 0.0; t2 = 1.0;
		scaleFactor = (1.0 - ((float)screenWidth/(float)screenHeight))/2.0;
		s1 = scaleFactor;
		s2 = 1.0 - scaleFactor;
	}
	
	glBegin(GL_QUADS);     
		glTexCoord2f(s1, t1);    glVertex2f(0, 0);
		glTexCoord2f(s1, t2);    glVertex2f(0, [self height]); 
		glTexCoord2f(s2, t2);    glVertex2f([self width], [self height]);
		glTexCoord2f(s2, t1);    glVertex2f([self width], 0);
	glEnd();
}

- (void) drawFullTexture:(GLuint)texture ofResolution:(int)resolution {
	glEnable(GL_TEXTURE_2D);
	
	[self viewOrthoWithWidth:resolution andHeight:resolution];
	[self bindTexture:texture];
	
	glBegin(GL_QUADS);
		glTexCoord2f(0, 0);    glVertex2f(0, 0);
		glTexCoord2f(0, 1);    glVertex2f(0, resolution); 
		glTexCoord2f(1, 1);    glVertex2f(resolution, resolution);
		glTexCoord2f(1, 0);    glVertex2f(resolution, 0);
	glEnd();
}

- (void) drawPlaneWithTexture:(GLuint)texture {
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, texture);		

	float ct = cos(rot);
	float st = sin(rot);
	
	float xsize = size / 2.0;
	float ysize = size / 2.0;
	
	float x1 = -xsize;
	float y1 = -ysize;
	float x2 = xsize;
	float y2 = ysize;
	
	float xx1 = x1 * ct - y1 * st + xcen;
	float yy1 = x1 * st + y1 * ct + ycen;
	float xx2 = x1 * ct - y2 * st + xcen;
	float yy2 = x1 * st + y2 * ct + ycen;
	float xx3 = x2 * ct - y2 * st + xcen;
	float yy3 = x2 * st + y2 * ct + ycen;
	float xx4 = x2 * ct - y1 * st + xcen;
	float yy4 = x2 * st + y1 * ct + ycen;
	
	glPushMatrix();

	glBegin(GL_QUADS);
		glTexCoord2f(xx1, yy1);
		glVertex2f(0, 0);
            
		glTexCoord2f(xx2, yy2);
		glVertex2f(0, texture_resolution);

		glTexCoord2f(xx3, yy3);
		glVertex2f(texture_resolution, texture_resolution);
            
		glTexCoord2f(xx4, yy4);
		glVertex2f(texture_resolution, 0);
	glEnd();

	glPopMatrix();
}

- (void) setDeltaTime:(float)deltaTime {
	dt = deltaTime;
}

- (void) setMouseControlsZoom:(bool)controls {
	zoomRot = controls;
}

- (void) setRotation:(float)newRotation {
	rot = newRotation;
}

- (void) increaseRotation {
	[self setRotation: rot + .01];
}

- (void) decreaseRotation {
	[self setRotation: rot - .01];
}

- (void) increaseZoom {
	[self setSize: size - .01];
}

- (void) decreaseZoom {
	[self setSize: size + .01];
}

- (void) increaseRotationBy:(float)increment {
	[self setRotation: rot + increment];
}

- (void) decreaseRotationBy:(float)decrement {
	[self setRotation: rot - decrement];
}

- (void) increaseZoomBy:(float)increment {
	[self setSize: size - increment];
}

- (void) decreaseZoomBy:(float)decrement {
	[self setSize: size + decrement];
}

- (void) setSize:(float)newSize {
	size = newSize;
}

- (void) setCenterX:(float)x andY:(float)y {
	xcen = x;
	ycen = y;
}

- (void) setCenterDx:(float)dx andDy:(float)dy {
    dx *= size;
    dy *= size;
	xcen += dx * cos(rot) - dy * sin(rot);
	ycen += dx * sin(rot) + dy * cos(rot);
//	xcen += dx;
//	ycen += dy;
}


- (void) setCenterX:(float)x {
	xcen = x;
}

- (void) setCenterY:(float)y {
	ycen = y;
}

- (void) setLineWidth:(float)width {
	lineWidth = width;
}

- (void) changeLineWidth:(float)dw {
	lineWidth += dw;
}

- (void) reset {
	size = 1.0;
	rot = 0;
	xcen = ycen = size / 2.0;
}



- (void) drawSineWave {
	float tt = t * 8;
	float i;
	
	glPushMatrix();

    glMatrixMode(GL_PROJECTION);               
	glLoadIdentity();                                  
	gluPerspective(45.0f, 1.0, .5f ,150.0f);
    glMatrixMode(GL_MODELVIEW);       
	glLoadIdentity();
	gluLookAt(0, 0, 4,     0, 0, 0,     0, 1.0, 0);
	glRotatef(t * 200, .5f, -.2f, 1.f);

    glDisable(GL_TEXTURE_2D);
    glEnable(GL_COLOR_MATERIAL);
	
	glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // These vary roughly from 0 to 1 for whistling input.
    Float32 cookedPitch = audioController.pitch / 4000;
    Float32 cookedLoudness = audioController.loudness / 40;
    
    float h1,s1,l1,h2,s2,l2,r1,g1,b1,r2,g2,b2;
    
	for(i = -2; i <= 2; i += .005)
	{
		glLineWidth(fabs(i) * lineWidth + 3);

		float x1 = i;
		float y1 = sin(x1 * 5 + t*2);
		float x2 = i + .1;
		float y2 = sin(x2 * 5 + t*2);

		float z1 = 1.5*cos(y1 * 3 - t * .5)*(cookedLoudness+1);
		float z2 = 1.5*cos(y2 * 3 - t * .5);
        
        h1 = fwrap(cookedPitch + cos(tt+x1)*0.2, 1.0);
        s1 = 0.7 + 0.2*cos(tt+x1);
        l1 = 0.5;
        
        h2 = fwrap(cookedPitch - cos(tt+x2)*0.2, 1.0);
        s2 = 0.7 + 0.2*cos(tt+x2);
        l2 = 0.5;

        HSL2RGB(h1,s1,l1,&r1,&g1,&b1);
        HSL2RGB(h2,s2,l2,&r2,&g2,&b2);
		
		glBegin(GL_LINES);
            glColor4f(r1 , g1, b1, 0.25);
            glVertex3f(x1, y1, z1);
            
            glColor4f(r2, g2, b2, 0.25);
            glVertex3f(x2, y2, z2);
		glEnd();
	} 
	glColor4f(0.985, 0.985, 0.985, 0);
	glDisable(GL_BLEND);
    
    glEnable(GL_TEXTURE_2D);
    glDisable(GL_COLOR_MATERIAL);

	glPopMatrix();
}

- (void) initGL {
    glEnable( GL_TEXTURE_2D );                             // Enable Texture Mapping 
	glEnable( GL_MULTISAMPLE_ARB );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT); 
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT); 
   
    glViewport(0,0, [self width], [self height]);                        // Make our viewport the whole window

    glMatrixMode(GL_PROJECTION);                        // Select The Projection Matrix
    glLoadIdentity();                                    // Reset The Projection Matrix

	gluPerspective(45.0f, (GLfloat)[self width]/(GLfloat)[self height], .5f ,150.0f);

    glMatrixMode(GL_MODELVIEW);                            // Select The Modelview Matrix
    glLoadIdentity(); 
    
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f); 
}

- (void) initFrameBuffer:(GLuint *)fbo ofSize:(int)textureSize withRenderBuffer:(GLuint *)rb andTexture:(GLuint *)tb {
	glGenFramebuffersEXT(1, fbo);													// create a new framebuffer
	glGenTextures(1, tb);													// and a new texture used as a color buffer
	glGenRenderbuffersEXT(1, rb);											// And finaly a new depthbuffer

	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, *fbo);									// switch to the new framebuffer

	// initialize color texture
	glBindTexture(GL_TEXTURE_2D, *tb);										// Bind the colorbuffer texture

	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);				// make it linear filterd
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, textureSize, textureSize, 0,GL_RGBA, GL_INT, NULL);	// Create the texture data
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D, *tb, 0); // attach it to the framebuffer

	// initialize depth renderbuffer
	glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, *rb);							// bind the depth renderbuffer
	glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT24, textureSize, textureSize);	// get the data space for it
	glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, *rb); // bind it to the renderbuffer

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);									// Swithch back to normal framebuffer rendering
}

- (void) bindFrameBuffer:(GLuint)fbo {
	glBindTexture(GL_TEXTURE_2D, 0);
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fbo);
}

- (void) bindTexture:(GLuint)texture {
	glBindTexture(GL_TEXTURE_2D, texture);
}

- (void) viewOrthoWithWidth:(int)width andHeight:(int)height {
	glMatrixMode(GL_PROJECTION);					// Select Projection
	glPushMatrix();									// Push The Matrix
	glLoadIdentity();								// Reset The Matrix
	glOrtho( 0, width , 0 , height, -1, 1 );		// Select Ortho Mode (640x480)
	glMatrixMode(GL_MODELVIEW);						// Select Modelview Matrix
	glPushMatrix();									// Push The Matrix
	glLoadIdentity();								// Reset The Matrix
}

- (void) viewPerspective {
	glMatrixMode( GL_PROJECTION );					// Select Projection
	glPopMatrix();									// Pop The Matrix
	glMatrixMode( GL_MODELVIEW );					// Select Modelview
	glPopMatrix();									// Pop The Matrix
}

- (int) height {
    NSRect backingBounds = [self convertRectToBacking:[self bounds]];
	return backingBounds.size.height;
}

- (int) width {
    NSRect backingBounds = [self convertRectToBacking:[self bounds]];
	return backingBounds.size.width;
}

- (void) incrementTime {
	t += dt;
}

@end
