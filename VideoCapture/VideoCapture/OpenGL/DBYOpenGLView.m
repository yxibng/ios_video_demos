
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The OpenGL ES view
 */

#import "DBYOpenGLView.h"
#import <OpenGLES/EAGL.h>
#import <QuartzCore/CAEAGLLayer.h>
#import "ShaderUtilities.h"



#if !defined(_STRINGIFY)
#define __STRINGIFY(_x) #_x
#define _STRINGIFY(_x) __STRINGIFY(_x)
#endif

static const char *kPassThruVertex =
_STRINGIFY(
    attribute vec4 position;
    attribute vec4 texcoord;
    varying vec2 v_texcoord;

    void main() {
        gl_Position = position;
        v_texcoord = texcoord.xy;
    }
);

static const char *kPassThruFragment =
_STRINGIFY(
    precision highp float;
    varying highp vec2 v_texcoord;
    uniform sampler2D texSampler_y;
    uniform sampler2D texSampler_u;
    uniform sampler2D texSampler_v;

    void main() {
        highp float y = texture2D(texSampler_y, v_texcoord).r;
        highp float u = texture2D(texSampler_u, v_texcoord).r - 0.5;
        highp float v = texture2D(texSampler_v, v_texcoord).r - 0.5;
        highp float r = y + 1.402 * v;
        highp float g = y - 0.344 * u - 0.714 * v;
        highp float b = y + 1.772 * u;

        gl_FragColor = vec4(r, g, b, 1.0);
    }
);

enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};

@interface DBYOpenGLView () {
    CVPixelBufferPoolRef _bufferPool;
    CVOpenGLESTextureCacheRef _textureCache;
    GLint _width;
    GLint _height;
    GLuint _frameBufferHandle;
    GLuint _colorBufferHandle;
    GLuint _program;
    GLint _frame;
    GLuint _texture_y;
    GLuint _texture_u;
    GLuint _texture_v;
    GLuint _uniform_y;
    GLuint _uniform_u;
    GLuint _uniform_v;
}
@property (nonatomic, strong) NSLock *renderLock;
@property (nonatomic, strong) NSLock *bufferLock;
@property (nonatomic, strong) EAGLContext *openglContext;
@property (nonatomic, strong) CAEAGLLayer *eaglLayer;
@property (nonatomic, assign) CGSize screenSize;
@property (nonatomic, assign) UInt32 renderSize;
@property (nonatomic, assign) BOOL shouldRender;
@property (nonatomic) uint8_t *renderBuffer;

@end

@implementation DBYOpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // On iOS8 and later we use the native scale of the screen as our content scale factor.
        // This allows us to render to the exact pixel resolution of the screen which avoids additional scaling and GPU rendering work.
        // For example the iPhone 6 Plus appears to UIKit as a 736 x 414 pt screen with a 3x scale factor (2208 x 1242 virtual pixels).
        // But the native pixel dimensions are actually 1920 x 1080.
        // Since we are streaming 1080p buffers from the camera we can render to the iPhone 6 Plus screen at 1:1 with no additional scaling if we set everything up correctly.
        // Using the native scale of the screen also allows us to render at full quality when using the display zoom feature on iPhone 6/6 Plus.
        
        // Only try to compile this code if we are using the 8.0 or later SDK.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if ([UIScreen instancesRespondToSelector:@selector(nativeScale)]) {
            self.contentScaleFactor = [UIScreen mainScreen].nativeScale;
        } else
#endif
        {
            self.contentScaleFactor = [UIScreen mainScreen].scale;
        }
        [self setupVariable];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if ([UIScreen instancesRespondToSelector:@selector(nativeScale)]) {
            self.contentScaleFactor = [UIScreen mainScreen].nativeScale;
        } else
#endif
        {
            self.contentScaleFactor = [UIScreen mainScreen].scale;
        }
        [self setupVariable];
    }
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    _screenSize = self.frame.size;
    glFinish();
    [self reset];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self reset];
    [self freeUpResources];
}
#pragma mark - private
- (void)freeUpResources {
    [_bufferLock lock];
    if (_renderBuffer) {
        free(_renderBuffer);
        _renderBuffer = nil;
        _renderSize = 0;
    }
    [_bufferLock unlock];
}
- (void)setupVariable {
    _renderLock = [[NSLock alloc] init];
    _bufferLock = [[NSLock alloc] init];
    
    _screenSize = self.frame.size;
    // Initialize OpenGL ES 2
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    _eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking : @(NO), kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8 };
    
    [_renderLock lock];
    _shouldRender = YES;
    [_renderLock unlock];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}
- (void)setupContext {
    if (_openglContext == nil) {
        _openglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    BOOL result = [EAGLContext setCurrentContext:_openglContext];
    if (!result) {
        NSLog(@"Setup EAGLContext Failed...");
    }
}
- (void)initializeProgram {
    if (_program) {
        return;
    }
    _program = createGLProgram(kPassThruVertex, kPassThruFragment);
    
    if (!_program) {
        NSLog(@"Error creating the program");
    }
    
    _uniform_y = glGetUniformLocation(_program, "texSampler_y");
    _uniform_u = glGetUniformLocation(_program, "texSampler_u");
    _uniform_v = glGetUniformLocation(_program, "texSampler_v");
}
- (void)initializeTexture {
    //创建texture
    if (_texture_y == 0) {
        _texture_y = createTexture2D(GL_LUMINANCE, _width, _height, NULL);
    }
    if (_texture_u == 0) {
        _texture_u = createTexture2D(GL_LUMINANCE, _width / 2, _height / 2, NULL);
    }
    if (_texture_v == 0) {
        _texture_v = createTexture2D(GL_LUMINANCE, _width / 2, _height / 2, NULL);
    }
}
- (void)initializeBuffers {
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (GL_FRAMEBUFFER_COMPLETE == status) {
        return;
    }
    NSLog(@"initialize framebuffer faild, status: %d", status);
    GLenum glError = glGetError();
    if (GL_NO_ERROR == glError) {
        return;
    }
    NSLog(@"failed to setup GL %x", glError);
    //是否覆盖当前像素
    glDisable(GL_DEPTH_TEST);
    
    //帧缓冲
    glGenFramebuffers(1, &_frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    
    //渲染缓冲
    glGenRenderbuffers(1, &_colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    
    //为绘制缓冲分配存储空间
    BOOL result = [_openglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    if (!result) {
        NSLog(@"failed to renderbufferStorage");
    }
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_height);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBufferHandle);
}

- (void)reset {
    EAGLContext *oldContext = [EAGLContext currentContext];
    if ( oldContext != _openglContext ) {
        if (![EAGLContext setCurrentContext:_openglContext]) {
            return;
        }
    }
    if (_frameBufferHandle) {
        glDeleteFramebuffers(1, &_frameBufferHandle);
        _frameBufferHandle = 0;
    }
    if (_colorBufferHandle) {
        glDeleteRenderbuffers(1, &_colorBufferHandle);
        _colorBufferHandle = 0;
    }
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    if (_textureCache) {
        CFRelease(_textureCache);
        _textureCache = 0;
    }
    if ( oldContext != _openglContext ) {
        [EAGLContext setCurrentContext:oldContext];
    }
}
- (void)flushPixelBufferCache {
    if (_textureCache) {
        CVOpenGLESTextureCacheFlush(_textureCache, 0);
    }
}
#pragma mark - notification
- (void)applicationWillResignActive:(NSNotification *)notification {
    [self.renderLock lock];
    self.shouldRender = NO;
    [self.renderLock unlock];
    glFinish();
    [self reset];
    [self freeUpResources];
}
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self.renderLock lock];
    self.shouldRender = YES;
    [self.renderLock unlock];
}
#pragma mark - public
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    // Perform a vertical flip by swapping the top left and the bottom left coordinate.
    // CVPixelBuffers have a top left origin and OpenGL has a bottom left origin.
    const GLfloat passThroughTextureVertices[] = {
        0.0f, 1.0f, // top left
        1.0f, 1.0f, // top right
        0.0f, 0.0f, // bottom left
        1.0f, 0.0f // bottom right
    };
    GLfloat textureCoords[] = {
        -1.0f, -1.0f, // bottom left
        1.0f, -1.0f, // bottom right
        -1.0f, 1.0f, // top left
        1.0f, 1.0f, // top right
    };
    float screenAspect = _screenSize.height / _screenSize.width;
    float imageAspect = 1.0f * _height / _width;
    if (screenAspect < imageAspect) {
        // screen is wider
        float halfImageStretchWidth = screenAspect / imageAspect;
        textureCoords[0] = -halfImageStretchWidth; // bottom left
        textureCoords[1] = -1.0f;
        textureCoords[2] = halfImageStretchWidth; // bottom right
        textureCoords[3] = -1.0f;
        textureCoords[4] = -halfImageStretchWidth; // top left
        textureCoords[5] = 1.0f;
        textureCoords[6] = halfImageStretchWidth; // top right
        textureCoords[7] = 1.0f;
    } else {
        float halfImageStetchHeight = imageAspect / screenAspect;
        textureCoords[0] = -1.0f; // bottom left
        textureCoords[1] = -halfImageStetchHeight;
        textureCoords[2] = 1.0f; // bottom right
        textureCoords[3] = -halfImageStetchHeight;
        textureCoords[4] = -1.0f; // top left
        textureCoords[5] = halfImageStetchHeight;
        textureCoords[6] = 1.0f; // top right
        textureCoords[7] = halfImageStetchHeight;
    }
    
    if (pixelBuffer == NULL) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL pixel buffer" userInfo:nil];
        return;
    }
    
    [self initializeBuffers];
    
    // Create a CVOpenGLESTexture from a CVPixelBufferRef
    size_t frameWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t frameHeight = CVPixelBufferGetHeight(pixelBuffer);
    CVOpenGLESTextureRef texture = NULL;
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                _textureCache,
                                                                pixelBuffer,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA,
                                                                (GLsizei)frameWidth,
                                                                (GLsizei)frameHeight,
                                                                GL_BGRA,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &texture);
    
    if (!texture || err) {
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);
        return;
    }
    
    // Set the view port to the entire view
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    glViewport(0, 0, _width, _height);
    
    glUseProgram(_program);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(CVOpenGLESTextureGetTarget(texture), CVOpenGLESTextureGetName(texture));
    glUniform1i(_frame, 0);
    
    // Set texture parameters
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, textureCoords);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    
    glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, passThroughTextureVertices);
    glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
    
    glClearColor(0.4f, 0.5f, 0.6f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    [_openglContext presentRenderbuffer:GL_RENDERBUFFER];
    
    glBindTexture(CVOpenGLESTextureGetTarget(texture), 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    CFRelease(texture);
}
- (void)displayYUV420Data:(void *)data width:(int)width height:(int)height {
    [_renderLock lock];
    if (_shouldRender == NO) {
        [_renderLock unlock];
        return;
    }
    [_renderLock unlock];
    
    [_bufferLock lock];
    UInt32 renderSize = width * height * 1.5;
    if (renderSize != _renderSize) {
        free(_renderBuffer);
        _renderBuffer = malloc(renderSize);
        _renderSize = renderSize;
    }
    memcpy(_renderBuffer, data, renderSize);
    [_bufferLock unlock];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!weakSelf) {
            return;
        }
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf.renderLock lock];
        if (strongSelf.shouldRender == NO) {
            [strongSelf.renderLock unlock];
            return;
        }
        [strongSelf.renderLock unlock];
        
        [strongSelf.bufferLock lock];
        size_t renderSize = width * height * 1.5;
        if (renderSize < strongSelf.renderSize) {
            [strongSelf.bufferLock unlock];
            return;
        }
        [strongSelf.bufferLock unlock];
        
        GLfloat passThroughTextureVertices[] = {
            0.0f, 1.0f, // top left
            1.0f, 1.0f, // top right
            0.0f, 0.0f, // bottom left
            1.0f, 0.0f // bottom right
        };
        GLfloat textureCoords[] = {
            -1.0f, -1.0f, // bottom left
            1.0f, -1.0f, // bottom right
            -1.0f, 1.0f, // top left
            1.0f, 1.0f, // top right
        };
        float screenAspect = strongSelf.screenSize.height / strongSelf.screenSize.width;
        float imageAspect = 1.0f * height / width;
        if (screenAspect < imageAspect) {
            // screen is wider
            float halfImageStretchWidth = screenAspect / imageAspect;
            textureCoords[0] = -halfImageStretchWidth; // bottom left
            textureCoords[1] = -1.0f;
            textureCoords[2] = halfImageStretchWidth; // bottom right
            textureCoords[3] = -1.0f;
            textureCoords[4] = -halfImageStretchWidth; // top left
            textureCoords[5] = 1.0f;
            textureCoords[6] = halfImageStretchWidth; // top right
            textureCoords[7] = 1.0f;
        } else {
            float halfImageStetchHeight = imageAspect / screenAspect;
            textureCoords[0] = -1.0f; // bottom left
            textureCoords[1] = -halfImageStetchHeight;
            textureCoords[2] = 1.0f; // bottom right
            textureCoords[3] = -halfImageStetchHeight;
            textureCoords[4] = -1.0f; // top left
            textureCoords[5] = halfImageStetchHeight;
            textureCoords[6] = 1.0f; // top right
            textureCoords[7] = halfImageStetchHeight;
        }
        
        [strongSelf setupContext];
        [strongSelf initializeBuffers];
        [strongSelf initializeProgram];
        [strongSelf initializeTexture];
        
        glUseProgram(strongSelf->_program);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        
        [strongSelf.bufferLock lock];
        
        uint8_t *base_y = strongSelf.renderBuffer;
        uint8_t *base_u = base_y + width * height;
        uint8_t *base_v = base_u + width * height / 4;
        
        glBindTexture(GL_TEXTURE_2D, strongSelf->_texture_y);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, base_y);
        glGenerateMipmap(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, 0);
        
        glBindTexture(GL_TEXTURE_2D, strongSelf->_texture_u);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, base_u);
        glGenerateMipmap(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, 0);
        
        glBindTexture(GL_TEXTURE_2D, strongSelf->_texture_v);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, base_v);
        glGenerateMipmap(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, 0);
        
        [strongSelf.bufferLock unlock];
        // Set the view port to the entire view
        glBindFramebuffer(GL_FRAMEBUFFER, strongSelf->_frameBufferHandle);
        glViewport(0, 0, strongSelf->_width, strongSelf->_height);
        
        glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, passThroughTextureVertices);
        glEnableVertexAttribArray(ATTRIB_VERTEX);
        
        glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureCoords);
        glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, strongSelf->_texture_y);
        glUniform1i(strongSelf->_uniform_y, 0);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, strongSelf->_texture_u);
        glUniform1i(strongSelf->_uniform_u, 1);
        
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, strongSelf->_texture_v);
        glUniform1i(strongSelf->_uniform_v, 2);
        
        glClearColor(0.0, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glBindRenderbuffer(GL_RENDERBUFFER, strongSelf->_colorBufferHandle);
        [strongSelf->_openglContext presentRenderbuffer:GL_RENDERBUFFER];
    });
}

@end
