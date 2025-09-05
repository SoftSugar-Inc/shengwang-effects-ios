//
//  VideoRendererView.m
//  APIExample-OC
//
//  Created by 马浩萌 on 2024/7/22.
//

#import "VideoRendererView.h"
#import "MHMGLHelper.h"

@implementation VideoRendererView
{
    CGFloat _mainScale;
    CGRect _frame;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

-(CAEAGLLayer *)eaglLayer {
    return (CAEAGLLayer *)self.layer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupContext];
        [self setupBuffers];
        [self setupShaders];
        [self setupTextures];
        _mainScale = UIScreen.mainScreen.scale;
        _frame = frame;
    }
    return self;
}

- (void)setupContext {
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!context) {
        NSLog(@"Failed to create ES context");
        exit(1);
    }
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (void)setupBuffers {
    glGenFramebuffers(1, &frameBuffer);
    glGenRenderbuffers(1, &renderBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
    
    GLint width, height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    glViewport(0, 0, width, height);
}

- (void)setupShaders {
    // Vertex shader source code
    const GLchar* vertexShaderSource =
    "attribute vec4 position;                                   \n"
    "attribute vec2 texCoord;                                   \n"
    "varying vec2 TexCoord;                                     \n"
    "void main()                                                \n"
    "{                                                          \n"
    "    gl_Position = position;                                \n"
    "    TexCoord = texCoord;                                   \n"
    "}                                                          \n";
    
    // Fragment shader source code
    const GLchar* fragmentShaderSource =
    "precision mediump float;                                   \n"
    "varying vec2 TexCoord;                                     \n"
    "uniform sampler2D textureY;                                \n"
    "uniform sampler2D textureU;                                \n"
    "uniform sampler2D textureV;                                \n"
    "uniform sampler2D textureAlpha;                            \n"
    "uniform bool hasAlpha;                                     \n"
    "void main()                                                \n"
    "{                                                          \n"
    "    float y = texture2D(textureY, TexCoord).r;             \n"
    "    float u = texture2D(textureU, TexCoord).r - 0.5;       \n"
    "    float v = texture2D(textureV, TexCoord).r - 0.5;       \n"
    "    float alpha = hasAlpha ? texture2D(textureAlpha, TexCoord).r : 1.0; \n"
    "    float r = y + 1.402 * v;                               \n"
    "    float g = y - 0.344 * u - 0.714 * v;                   \n"
    "    float b = y + 1.772 * u;                               \n"
    "    gl_FragColor = vec4(r, g, b, alpha);                   \n"
    "}                                                          \n";
    
    GLuint vertexShader = [self compileShader:vertexShaderSource withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:fragmentShaderSource withType:GL_FRAGMENT_SHADER];
    program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    
    GLint success;
    glGetProgramiv(program, GL_LINK_STATUS, &success);
    if (!success) {
        GLchar infoLog[512];
        glGetProgramInfoLog(program, 512, NULL, infoLog);
        NSLog(@"ERROR::SHADER::PROGRAM::LINKING_FAILED\n%s", infoLog);
    }
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    glUseProgram(program);
}

- (GLuint)compileShader:(const GLchar *)shaderSource withType:(GLenum)shaderType {
    GLuint shader = glCreateShader(shaderType);
    glShaderSource(shader, 1, &shaderSource, NULL);
    glCompileShader(shader);
    GLint success;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        GLchar infoLog[512];
        glGetShaderInfoLog(shader, 512, NULL, infoLog);
        NSLog(@"ERROR::SHADER::COMPILATION_FAILED\n%s", infoLog);
    }
    return shader;
}

- (void)setupTextures {
    glGenTextures(1, &textureY);
    glBindTexture(GL_TEXTURE_2D, textureY);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glGenTextures(1, &textureU);
    glBindTexture(GL_TEXTURE_2D, textureU);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glGenTextures(1, &textureV);
    glBindTexture(GL_TEXTURE_2D, textureV);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glGenTextures(1, &textureAlpha);
    glBindTexture(GL_TEXTURE_2D, textureAlpha);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void)renderFrame:(AgoraOutputVideoFrame *)frame {
    _mainScale = UIScreen.mainScreen.scale;
    
    if (frame.type != 1) {
        return;
    }
    
    if ([EAGLContext currentContext] != context) {
        [EAGLContext setCurrentContext:context];
    }
    glCheckError();
    glClearColor(0.0, 1.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glViewport(0, 0, _frame.size.width, _frame.size.height);
    
    glUseProgram(program);
    glCheckError();
    
    // Bind and upload Y texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureY);
    if (frame.yStride == frame.width) {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, frame.width, frame.height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, frame.yBuffer);
    } else {
        for (int i = 0; i < frame.height; i++) {
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, i, frame.width, 1, GL_LUMINANCE, GL_UNSIGNED_BYTE, frame.yBuffer + i * frame.yStride);
        }
    }

    // Bind and upload U texture
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, textureU);
    if (frame.uStride == frame.width / 2) {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, frame.width / 2, frame.height / 2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, frame.uBuffer);
    } else {
        for (int i = 0; i < frame.height / 2; i++) {
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, i, frame.width / 2, 1, GL_LUMINANCE, GL_UNSIGNED_BYTE, frame.uBuffer + i * frame.uStride);
        }
    }

    // Bind and upload V texture
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, textureV);
    if (frame.vStride == frame.width / 2) {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, frame.width / 2, frame.height / 2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, frame.vBuffer);
    } else {
        for (int i = 0; i < frame.height / 2; i++) {
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, i, frame.width / 2, 1, GL_LUMINANCE, GL_UNSIGNED_BYTE, frame.vBuffer + i * frame.vStride);
        }
    }

    BOOL hasAlpha = (frame.alphaBuffer != NULL);
    if (hasAlpha) {
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, textureAlpha);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, frame.width, frame.height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, frame.alphaBuffer);
    }

    glUniform1i(glGetUniformLocation(program, "textureY"), 0);
    glUniform1i(glGetUniformLocation(program, "textureU"), 1);
    glUniform1i(glGetUniformLocation(program, "textureV"), 2);
    glUniform1i(glGetUniformLocation(program, "textureAlpha"), 3);
    glUniform1i(glGetUniformLocation(program, "hasAlpha"), hasAlpha);

    GLfloat vertices[] = {
        // Positions   // Texture Coords
        -1.0f,  1.0f,  0.0f, 0.0f, // 左上
        -1.0f, -1.0f,  0.0f, 1.0f, // 左下
         1.0f, -1.0f,  1.0f, 1.0f, // 右下
         1.0f,  1.0f,  1.0f, 0.0f  // 右上
    };
    
    GLuint indices[] = {
        0, 1, 2,
        2, 3, 0
    };
    glCheckError();

    GLuint vbo, ebo;
    glGenVertexArrays(1, &vao);
    glGenBuffers(1, &vbo);
    glGenBuffers(1, &ebo);
    
    glBindVertexArray(vao);
    
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    glCheckError();

    GLint posAttrib = glGetAttribLocation(program, "position");
    glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), 0);
    glEnableVertexAttribArray(posAttrib);
    
    GLint texAttrib = glGetAttribLocation(program, "texCoord");
    glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), (const GLvoid *)(2 * sizeof(GLfloat)));
    glEnableVertexAttribArray(texAttrib);
    glCheckError();

    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    
    glBindVertexArray(0);
    glCheckError();

    [context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
