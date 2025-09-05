//
//  VideoRenderer.m
//  APIExample-OC
//
//  Created by 马浩萌 on 2024/7/22.
//

#import "VideoRenderer.h"
@import OpenGLES;

#define TTF_STRINGIZE(x) #x
#define TTF_STRINGIZE2(x) TTF_STRINGIZE(x)
#define TTF_SHADER_STRING(text) @ TTF_STRINGIZE2(text)

@implementation VideoRenderer

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context {
    self = [super initWithFrame:frame context:context];
    if (self) {
        [self setupOpenGL];
    }
    return self;
}

- (void)setupOpenGL {
    [EAGLContext setCurrentContext:self.context];
    [self setupShaders];
    [self setupTextures];
    [self setupBuffers];
}

- (void)setupShaders {
    // Compile and link shaders (similar to the previous code)
    // Vertex shader source code
    const GLchar* vertexShaderSource = TTF_SHADER_STRING
    (
        attribute vec4 position;
        attribute vec2 texCoord;
        varying vec2 TexCoord;
        void main()
        {
            gl_Position = position;
            TexCoord = texCoord;
        }
     ).UTF8String;
    
    // Fragment shader source code
    const GLchar* fragmentShaderSource = TTF_SHADER_STRING
    (
     precision mediump float;
     varying vec2 TexCoord;
     uniform sampler2D textureY;
     uniform sampler2D textureU;
     uniform sampler2D textureV;
     void main()
     {
         float y = texture2D(textureY, TexCoord).r;
         float u = texture2D(textureU, TexCoord).r - 0.5;
         float v = texture2D(textureV, TexCoord).r - 0.5;
         float r = y + 1.402 * v;
         float g = y - 0.344 * u - 0.714 * v;
         float b = y + 1.772 * u;
         gl_FragColor = vec4(r, g, b, 1.0);
     }
     ).UTF8String;
    
    // Compile shaders and create program
    GLuint vertexShader = [self compileShader:vertexShaderSource withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:fragmentShaderSource withType:GL_FRAGMENT_SHADER];
    _program = glCreateProgram();
    glAttachShader(_program, vertexShader);
    glAttachShader(_program, fragmentShader);
    glLinkProgram(_program);

    // Check for linking errors
    GLint success;
    glGetProgramiv(_program, GL_LINK_STATUS, &success);
    if (!success) {
        GLchar infoLog[512];
        glGetProgramInfoLog(_program, 512, NULL, infoLog);
        NSLog(@"ERROR::SHADER::PROGRAM::LINKING_FAILED\n%s", infoLog);
    }
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    glUseProgram(_program);
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
    glGenTextures(1, &_textureY);
    glBindTexture(GL_TEXTURE_2D, _textureY);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glGenTextures(1, &_textureU);
    glBindTexture(GL_TEXTURE_2D, _textureU);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glGenTextures(1, &_textureV);
    glBindTexture(GL_TEXTURE_2D, _textureV);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void)setupBuffers {
    GLfloat vertices[] = {
        // Positions   // Texture Coords
        -1.0f,  1.0f,  0.0f, 1.0f,
        -1.0f, -1.0f,  0.0f, 0.0f,
         1.0f, -1.0f,  1.0f, 0.0f,
         1.0f,  1.0f,  1.0f, 1.0f,
    };

    GLuint indices[] = {
        0, 1, 2,
        2, 3, 0
    };

    GLuint vbo, ebo;
    glGenVertexArrays(1, &_vao);
    glGenBuffers(1, &vbo);
    glGenBuffers(1, &ebo);

    glBindVertexArray(_vao);

    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    GLint posAttrib = glGetAttribLocation(_program, "position");
    glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), (GLvoid*)0);
    glEnableVertexAttribArray(posAttrib);

    GLint texAttrib = glGetAttribLocation(_program, "texCoord");
    glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), (GLvoid*)(2 * sizeof(GLfloat)));
    glEnableVertexAttribArray(texAttrib);
}

- (void)renderFrame:(AgoraOutputVideoFrame *)frame {
    if (frame.type != 1) {
        return;
    }

    glUseProgram(_program);
    glClearColor(1, 0, 0, 1);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureY);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, frame.width, frame.height, 0, GL_RED, GL_UNSIGNED_BYTE, frame.yBuffer);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureU);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, frame.width / 2, frame.height / 2, 0, GL_RED, GL_UNSIGNED_BYTE, frame.uBuffer);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _textureV);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, frame.width / 2, frame.height / 2, 0, GL_RED, GL_UNSIGNED_BYTE, frame.vBuffer);

    glUniform1i(glGetUniformLocation(_program, "textureY"), 0);
    glUniform1i(glGetUniformLocation(_program, "textureU"), 1);
    glUniform1i(glGetUniformLocation(_program, "textureV"), 2);

    glBindVertexArray(_vao);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
}

@end
