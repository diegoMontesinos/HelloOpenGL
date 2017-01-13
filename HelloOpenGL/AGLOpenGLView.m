//
//  AGLOpenGLView.m
//  HelloOpenGL
//
//  Created by Diego Montesinos on 1/11/17.
//  Copyright © 2017 Diego Montesinos. All rights reserved.
//

#import "AGLOpenGLView.h"
#import "NPDisplayLink.h"
#import <OpenGL/gl3.h>

@interface AGLOpenGLView ()
@property (atomic, assign) BOOL didReshape;
@property (nonatomic, assign) GLuint VAO;
@property (nonatomic, assign) GLuint shaderProgram;
@end

@implementation AGLOpenGLView

+ (NSOpenGLPixelFormat*) defaultPixelFormat {
    const NSOpenGLPixelFormatAttribute attrs[] = {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAStencilSize, 0,
        0
    };
    return [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
}

- (instancetype) initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format {
    return [super initWithFrame:frameRect pixelFormat:format];
}

- (instancetype) initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [[NPDisplayLink sharedDisplayLink] addTarget: self selector: @selector(cvCallback)];
    }
    return self;
}

- (void)cvCallback {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setupOpenGL];
    });
    
    [self render];
}

- (void)reshape
{
    self.didReshape = YES;
}

- (void) render {
    if (self.didReshape) {
        glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
    }
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(self.shaderProgram);
    glBindVertexArray(self.VAO);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    glBindVertexArray(0);
    
    glFlush();
}

- (void)setupOpenGL
{
    self.openGLContext = [[NSOpenGLContext alloc] initWithFormat:[AGLOpenGLView defaultPixelFormat]
                                                    shareContext:nil];
    self.openGLContext.view = self;
    
    [self.openGLContext makeCurrentContext];
    
    // VAO
    glGenVertexArrays(1, &_VAO);
    glBindVertexArray(self.VAO);
    
    // VBO
    GLfloat vertices[] = {
        -0.5f, -0.5f, 0.0f,
        0.5f, -0.5f, 0.0f,
        0.0f,  0.5f, 0.0f
    };
    
    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), (GLvoid*) 0);
    glEnableVertexAttribArray(0);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    
    const GLchar *vertexShaderSrc = "#version 330 core \
    layout (location = 0) in vec3 position;\
    void main()\
    {\
        gl_Position = vec4(position.x, position.y, position.z, 1.0);\
    }";
    
    GLuint vertexShader;
    vertexShader = glCreateShader(GL_VERTEX_SHADER);
    
    glShaderSource(vertexShader, 1, &vertexShaderSrc, NULL);
    glCompileShader(vertexShader);
    
    GLint success;
    GLchar infoLog[512];
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    
    if (!success) {
        glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
        NSLog(@"ERROR::SHADER::VERTEX::COMPILATION_FAILED\n %s", infoLog);
    }
    
    const GLchar *fragmentShaderSrc = "#version 330 core\
    out vec4 color;\
    void main()\
    {\
        color = vec4(1.0f, 0.5f, 0.2f, 1.0f);\
    }";
    
    GLuint fragmentShader;
    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSrc, NULL);
    glCompileShader(fragmentShader);
    
    self.shaderProgram = glCreateProgram();
    
    glAttachShader(self.shaderProgram, vertexShader);
    glAttachShader(self.shaderProgram, fragmentShader);
    glLinkProgram(self.shaderProgram);
    
    glGetShaderiv(self.shaderProgram, GL_LINK_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(self.shaderProgram, 512, NULL, infoLog);
        NSLog(@"ERROR::SHADER::PROGRAM::COMPILATION_FAILED\n %s", infoLog);
    }
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    [self reshape];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing		 code here.
}

@end
