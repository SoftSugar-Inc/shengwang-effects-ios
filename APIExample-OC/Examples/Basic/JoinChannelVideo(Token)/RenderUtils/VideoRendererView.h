//
//  VideoRendererView.h
//  APIExample-OC
//
//  Created by 马浩萌 on 2024/7/22.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <AgoraRtcKit/AgoraRtcKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoRendererView : UIView {
    EAGLContext *context;
    GLuint frameBuffer;
    GLuint renderBuffer;
    GLuint program;
    GLuint textureY, textureU, textureV, textureAlpha;
    GLuint vao, vbo;
}

@property (nonatomic, strong) CAEAGLLayer *eaglLayer;

-(void)renderFrame:(AgoraOutputVideoFrame *)frame;

@end

NS_ASSUME_NONNULL_END
