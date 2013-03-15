//
//  RDFeedbackGLView.h
//  Lesson02_OSXCocoa
//
//  Created by Eric O'Connell on 11/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Lesson02View.h"

@interface RDFeedbackGLView : Lesson02View {
	int texture_resolution;
	
	GLuint tb1, tb2;
	GLuint fbo1, fbo2;
	GLuint rb1, rb2;

//	float t;
	float dt;
	float rot;
	float size;
	float xcen;
	float ycen;
	float lineWidth;

	int mouseX;
	int mouseY;

	bool blur;
	bool zoomRot;
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) initGL;
- (void) initFrameBuffer:(GLuint *)fbo ofSize:(int)size withRenderBuffer:(GLuint *)rb andTexture:(GLuint *)tb;

- (void) incrementTime;
- (int) width;
- (int) height;

- (void) clear;

- (void) drawSineWave;
- (void) drawPlaneWithTexture:(GLuint)texture;

- (void) drawFullTexture:(GLuint)texture ofResolution:(int)resolution;
- (void) drawScaledTextureToView:(GLuint)texture;

- (void) setDeltaTime:(float)deltaTime;

- (void) switchMouseMode;

- (void) setRotation:(float)newRotation;
- (void) setSize:(float)newSize;

- (void) increaseZoom;
- (void) decreaseZoom;

- (void) increaseZoomBy:(float)increment;
- (void) decreaseZoomBy:(float)decrement;

- (void) increaseRotationBy:(float)increment;
- (void) decreaseRotationBy:(float)decrement;

- (void) increaseRotation;
- (void) decreaseRotation;

- (void) setCenterX:(float)x andY:(float)y;
- (void) setCenterX:(float)x;
- (void) setCenterY:(float)y;
- (void) setCenterDx:(float)dx andDy:(float)dy;

- (void) setLineWidth:(float)width;
- (void) changeLineWidth:(float)dw;
- (void) reset;

- (void) viewOrthoWithWidth:(int)width andHeight:(int)height;
- (void) viewPerspective;

- (void) bindFrameBuffer:(GLuint)fbo;
- (void) bindTexture:(GLuint)texture;


@end
