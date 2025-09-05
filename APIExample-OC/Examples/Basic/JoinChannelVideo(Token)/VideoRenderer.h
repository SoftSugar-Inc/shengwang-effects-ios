//
//  VideoRenderer.h
//  APIExample-OC
//
//  Created by 马浩萌 on 2024/7/22.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <AgoraRtcKit/AgoraRtcKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoRenderer : GLKView
{
    GLuint _program;
    GLuint _textureY, _textureU, _textureV;
    GLuint _vao, _vbo;
}

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context;
- (void)renderFrame:(AgoraOutputVideoFrame *)frame;

@end

NS_ASSUME_NONNULL_END
