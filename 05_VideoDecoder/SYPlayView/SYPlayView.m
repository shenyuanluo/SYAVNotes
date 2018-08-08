//
//  SYPlayView.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import "SYPlayView.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "SYShader.h"
#import "SYTexture.h"
#import "SYTransform.h"
#import "SYScalingView.h"
#import "SYVideoFrame.h"


#define SCREEN_W [UIScreen mainScreen].bounds.size.width
#define SCREEN_H [UIScreen mainScreen].bounds.size.height


@interface SYPlayView() <
                            UIGestureRecognizerDelegate
                        >
{
    GLuint          m_VAO;                  // 视频帧 VAO
    GLuint          m_frameBuffer;          // 帧缓冲
    GLuint          m_renderBuffer;         // 渲染缓冲
    GLint           m_renderBufferWidth;    // 渲染缓冲·宽度
    GLint           m_renderBufferHeight;   // 渲染缓冲·高度
    
    GLsizei         m_decodeFrameW;         // 帧宽度
    GLsizei         m_decodeFrameH;         // 帧高度
    BOOL            m_isEnableScale;        // 是否开启捏合缩放功能
    BOOL            m_isScaling;            // 是否正在缩放
    
    CGFloat         m_glViewScale;          // 缩放大小
    CGFloat         m_maxGlViewScale;       // 最大缩放倍数
    CGFloat         m_minGlViewScale;       // 最小缩放倍数
    GLfloat         m_transSpaceX;          // 水平移动距离（放大模式下）
    GLfloat         m_transSpaceY;          // 垂直移动距离（放大模式下）
    CGPoint         m_transStartPoint;      // 移动起始点（放大模式下）
    CGPoint         m_transEndPoint;        // 移动终点（放大模式下）
    
    UIPinchGestureRecognizer *m_pinchRecognizer; // 捏合手势
}
@property (nonatomic, readwrite, assign) SYVideoFormat videoFormat; // 视频帧格式
@property (nonatomic, readwrite, assign) BOOL isRatioPlay;          // 是否按帧比例显示
@property (nonatomic, readwrite, strong) EAGLContext *glContext;    // OpenGLES 上下文
@property (nonatomic, readwrite, strong) SYShader *shader;          // 着色器
@property (nonatomic, readwrite, strong) SYTexture *texture0;       // Y（R） 纹理
@property (nonatomic, readwrite, strong) SYTexture *texture1;       // U（G） 纹理
@property (nonatomic, readwrite, strong) SYTexture *texture2;       // V（B） 纹理
@property (nonatomic, readwrite, strong) SYTransform *projectMat;   // 投影矩阵
@property (nonatomic, readwrite, strong) SYTransform *modelMat;     // 模型矩阵
@end


@implementation SYPlayView

#pragma mark -- 初始化播放视图
- (instancetype)initWithRect:(CGRect)rect
                 videoFormat:(SYVideoFormat)vFormat
                 isRatioShow:(BOOL)isRatio
{
    self = [super initWithFrame:rect];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.videoFormat     = vFormat;
        self.isRatioPlay     = isRatio;

        [self initAttrib];

        if (NO == [self initContext])
        {
            return nil;
        }
        if (NO == [self initFrameBuffer])
        {
            return nil;
        }
        if (NO == [self initShader])
        {
            return nil;
        }
        [self initVAO];
        [self initMVP];
        [self initTextures];

        [self addPinchRestures];
    }
    return self;
}

- (void)dealloc
{
    if (m_VAO)
    {
        glDeleteVertexArrays(1, &m_VAO);
        m_VAO = 0;
    }
    if (m_frameBuffer)
    {
        glDeleteFramebuffers(1, &m_frameBuffer);
        m_frameBuffer = 0;
    }
    if (m_renderBuffer)
    {
        glDeleteRenderbuffers(1, &m_renderBuffer);
        m_renderBuffer = 0;
    }
    if (self.glContext)
    {
        [EAGLContext setCurrentContext:nil];
        self.glContext = nil;
    }
    if (self.shader)
    {
        [self.shader freeShader];
        self.shader = nil;
    }
    if (self.texture0)
    {
        [self.texture0 freeTexture];
    }
    if (self.texture1)
    {
        [self.texture1 freeTexture];
    }
    if (self.texture2)
    {
        [self.texture2 freeTexture];
    }
    
    NSLog(@"---------- SYPlayerView dealloc ----------");
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    /*
     注意：当核心动画层的边界或属性更改时，需要重新分配 renderbuffer 的存储。
     如果不重新分配 renderbuffers，renderbuffer 大小将不匹配图层的大小;
     在这种情况下，Core Animation可以缩放图像的内容以适应图层。）
     */
    [self resizeRenderBuffer];
}

#pragma mark -- 分配 RenderBuffer 空间
- (void)resizeRenderBuffer
{
    glBindRenderbuffer(GL_RENDERBUFFER, m_renderBuffer);    // 绑定渲染缓冲对象
    /*
     Apple 不允许 OpenGL 直接渲染在屏幕上，需要将其放进输出的颜色缓冲，
     然后询问 EAGL 去把缓冲对象展现到屏幕上。
     因为颜色渲染缓冲是强制需要的，为了设置这些属性，
     需要通过 EAGLContext 调用 renderbufferStorage:fromDrawable:
     将colorRenderbuffer 和 Core Animation 图层关联起来。
     （注意：‘glRenderbufferStorage’ 在 iOS 平台不适用）
     */
    [self.glContext renderbufferStorage:GL_RENDERBUFFER
                           fromDrawable:(CAEAGLLayer*)self.layer];
    // 检索 renderbuffer 的高度和宽度
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &m_renderBufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &m_renderBufferHeight);
    // 重新分配渲染缓冲空间后，需要更新视图
    [self updateViewWidth:m_renderBufferWidth
                   height:m_renderBufferHeight];
}

#pragma mark -- 初始化参数
- (void)initAttrib
{
    m_isEnableScale  = NO;
    m_isScaling      = NO;
    m_glViewScale    = 1.0f;
    m_maxGlViewScale = 1.0f;
    m_minGlViewScale = 1.0f;
    m_transSpaceX    = 0;
    m_transSpaceY    = 0;
    m_decodeFrameW   = 0;
    m_decodeFrameH   = 0;
}

#pragma mark -- 初始化 OpenGL 上下文
- (BOOL)initContext
{
    NSDictionary *property       = @{kEAGLDrawablePropertyRetainedBacking : @(NO),  // 渲染完后不需要保存
                                     kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8 };
    CAEAGLLayer *eaglLayer       = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque             = YES; // 设置不透明，提高性能
    eaglLayer.drawableProperties = property;
    eaglLayer.contentsScale      = [UIScreen mainScreen].scale;
    self.glContext               = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.glContext)
    {
        NSLog(@"Init OpenGL context failure !");
        return NO;
    }
    if (![EAGLContext setCurrentContext:self.glContext])    // 设置为当前上下文
    {
        NSLog(@"Set OpenGL context failure !");
        return NO;
    }
    return YES;
}

#pragma mark -- 初始化帧缓冲
- (BOOL)initFrameBuffer
{
    glGenFramebuffers(1, &m_frameBuffer);   // 生成帧缓冲对象
    glBindFramebuffer(GL_FRAMEBUFFER, m_frameBuffer);   // 绑定帧缓冲对象
    glGenRenderbuffers(1, &m_renderBuffer); // 生成渲染缓冲对象
    glBindRenderbuffer(GL_RENDERBUFFER, m_renderBuffer);    // 绑定渲染缓冲对象

    // 初始分配存储空间
    [self resizeRenderBuffer];
    
    // 将渲染缓冲附件添加到帧缓冲上，‘GL_COLOR_ATTACHMENT0’ 作为颜色缓冲
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, m_renderBuffer);
    
    /*
     解绑渲染缓冲对象
     注意：已经分配足够内存的渲染缓冲对象附件，可以将其解绑
     */
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    
    if (GL_FRAMEBUFFER_COMPLETE != glCheckFramebufferStatus(GL_FRAMEBUFFER))
    {
        NSLog(@"Create frame buffer failure !");
        m_frameBuffer = 0;
        return NO;
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);   // 还原成默认缓冲，以免渲染错误

    return YES;
}

#pragma mark -- 初始化着色器
- (BOOL)initShader
{
    NSString *vsSourceName = nil;
    NSString *fsSourceName = nil;
    if (SYVideoI420 == self.videoFormat
        || SYVideoNv12 == self.videoFormat
        || SYVideoNv21 == self.videoFormat)
    {
        vsSourceName = @"YUVVS";
        fsSourceName = @"YUVFS";
    }
    else if (SYVideoRgb565 == self.videoFormat
             || SYVideoRgb24 == self.videoFormat)
    {
        vsSourceName = @"RGBVS";
        fsSourceName = @"RGBFS";
    }
    else
    {
        
    }
    // 读取 GLSL 文件的内容
    NSString *vsCodePath = [[NSBundle mainBundle] pathForResource:vsSourceName
                                                           ofType:@"glsl"];
    NSString *fsCodePath = [[NSBundle mainBundle] pathForResource:fsSourceName
                                                           ofType:@"glsl"];
    NSString *vsCode = [NSString stringWithContentsOfFile:vsCodePath
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    NSString *fsCode = [NSString stringWithContentsOfFile:fsCodePath
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    // 创建着色器
    self.shader = [[SYShader alloc] initWithVShaderCode:vsCode.UTF8String
                                            fShaderCode:fsCode.UTF8String];
    if (!self.shader)
    {
        NSLog(@"Create rgb shader failure !");
        return NO;
    }
    // 设置相关属性下标
    [self.shader setAttrib:"aPos" onIndex:0];       // 顶点坐标属性
    [self.shader setAttrib:"aTexCoor" onIndex:1];   // 纹理坐标属性
    // 设置着色器相关纹理单元
    if (SYVideoI420 == self.videoFormat
        || SYVideoNv12 == self.videoFormat
        || SYVideoNv21 == self.videoFormat)
    {
        [self.shader setUniformInt:"textureY"
                          forValue:0];
        [self.shader setUniformInt:"textureU"
                          forValue:1];
        [self.shader setUniformInt:"textureV"
                          forValue:2];
    }
    else if (SYVideoRgb565 == self.videoFormat
             || SYVideoRgb24 == self.videoFormat)
    {
        [self.shader setUniformInt:"textureR"
                          forValue:0];
        [self.shader setUniformInt:"textureG"
                          forValue:1];
        [self.shader setUniformInt:"textureB"
                          forValue:2];
    }
    else
    {
        
    }
    
    return YES;
}

#pragma mark -- 初始化 VAO
- (void)initVAO
{
    // 顶点数据
    GLfloat vertices[] =
    {
        // 顶点坐标     // 纹理坐标
        -1.0f, -1.0f,  0.0f, 1.0f,
         1.0f, -1.0f,  1.0f, 1.0f,
        -1.0f,  1.0f,  0.0f, 0.0f,
         1.0f,  1.0f,  1.0f, 0.0f,
    };
    GLuint VBO;
    glGenVertexArrays(1, &m_VAO); // 创建一个顶点数组对象（可包含：VBO，EBO，VertexAttribPointer ）
    glGenBuffers(1, &VBO);    // 创建顶点缓存对象
    glBindVertexArray(m_VAO); // 绑定顶点数组对象在先，然后再绑定和设置顶点缓存对象，并且配置顶点属性
    glBindBuffer(GL_ARRAY_BUFFER, VBO);   // 绑定缓存对象类型为：顶点数组缓存
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), &vertices, GL_STATIC_DRAW); // 拷贝顶点数据到顶点缓存对象ID引用的缓存中
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), (void*)0); // 设置顶点属性 （告诉 OpenGL 如何解释使用顶点数据）
    glEnableVertexAttribArray(0);   // 启用顶点属性
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), (void*)(2 * sizeof(GLfloat))); // 设置纹理属性 （告诉 OpenGL 如何解释使用纹理数据）
    glEnableVertexAttribArray(1);   // 启用纹理属性
    glBindVertexArray(0);
    glDeleteBuffers(1, &VBO); // 设置好相关属性的 顶点缓存对象可以删除
}

#pragma mark -- 初始化 Model、View、Project 矩阵
- (void)initMVP
{
    self.modelMat   = [[SYTransform alloc] init];
    self.projectMat = [[SYTransform alloc] init];
    [self.projectMat orthoWithLeft:-1.0f
                             right:1.0f
                               top:1.0f
                            bottom:-1.0f
                         nearPlane:-1.0f
                          farPlane:1.0f];
}

#pragma mark -- 初始化纹理
- (void)initTextures
{
    self.texture0 = [[SYTexture alloc] init];
    self.texture1 = [[SYTexture alloc] init];
    self.texture2 = [[SYTexture alloc] init];
}

#pragma mark -- 创建帧 Y、U、V 纹理
- (BOOL)createTextureWithYuvFrame:(SYVideoFrameYUV *)yuvFrame
{
    if (!yuvFrame || !yuvFrame.luma || !yuvFrame.chromaB || !yuvFrame.chromaR)
    {
        return NO;
    }
    NSUInteger frameSize = yuvFrame.width * yuvFrame.height * 1.5;
    if (frameSize != yuvFrame.size)
    {
        return NO;
    }

    if (yuvFrame.width != m_decodeFrameW
        || yuvFrame.height != m_decodeFrameH)
    {
        m_decodeFrameW = (GLsizei)yuvFrame.width;
        m_decodeFrameH = (GLsizei)yuvFrame.height;
        [self updateViewWidth:m_renderBufferWidth
                       height:m_renderBufferHeight];
    }
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    // 创建 Y 纹理
    [self.texture0 crateTextureWithData:yuvFrame.luma.bytes
                                  width:(GLsizei)yuvFrame.width
                                 height:(GLsizei)yuvFrame.height
                         internalFormat:GL_LUMINANCE
                            pixelFormat:GL_LUMINANCE];
    
    // 创建 U 纹理
    [self.texture1 crateTextureWithData:yuvFrame.chromaB.bytes
                                  width:(GLsizei)yuvFrame.width * 0.5
                                 height:(GLsizei)yuvFrame.height * 0.5
                         internalFormat:GL_LUMINANCE
                            pixelFormat:GL_LUMINANCE];
    
    // 创建 V 纹理
    [self.texture2 crateTextureWithData:yuvFrame.chromaR.bytes
                                  width:(GLsizei)yuvFrame.width * 0.5
                                 height:(GLsizei)yuvFrame.height * 0.5
                         internalFormat:GL_LUMINANCE
                            pixelFormat:GL_LUMINANCE];
    return YES;
}

#pragma mark -- 创建帧 R、G、B 纹理
- (BOOL)createTextureWithRgbFrame:(SYVideoFrameRGB *)rgbFrame
{
    if (!rgbFrame || !rgbFrame.red || !rgbFrame.green || !rgbFrame.blue)
    {
        return NO;
    }
    NSUInteger frameSize = rgbFrame.width * rgbFrame.height * 3;
    if (frameSize != rgbFrame.size)
    {
        return NO;
    }
    if (rgbFrame.width != m_decodeFrameW
        || rgbFrame.height != m_decodeFrameH)
    {
        m_decodeFrameW = (GLsizei)rgbFrame.width;
        m_decodeFrameH = (GLsizei)rgbFrame.height;
        [self updateViewWidth:m_renderBufferWidth
                       height:m_renderBufferHeight];
    }
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    // 创建 RGB 纹理
    [self.texture0 crateTextureWithData:rgbFrame.red.bytes
                                  width:(GLsizei)rgbFrame.width
                                 height:(GLsizei)rgbFrame.height
                         internalFormat:GL_LUMINANCE
                            pixelFormat:GL_LUMINANCE];
    [self.texture1 crateTextureWithData:rgbFrame.green.bytes
                                  width:(GLsizei)rgbFrame.width
                                 height:(GLsizei)rgbFrame.height
                         internalFormat:GL_LUMINANCE
                            pixelFormat:GL_LUMINANCE];
    [self.texture2 crateTextureWithData:rgbFrame.blue.bytes
                                  width:(GLsizei)rgbFrame.width
                                 height:(GLsizei)rgbFrame.height
                         internalFormat:GL_LUMINANCE
                            pixelFormat:GL_LUMINANCE];
    return YES;
}

#pragma mark -- 渲染帧数据
- (void)renderData:(unsigned char*)buffer
              size:(unsigned int)size
             width:(unsigned int)width
            height:(unsigned int)height
{
    if (NULL == buffer || 0 == size
        || 0 == width || 0 == height)
    {
        fflush(stdout);
        printf("Have no data to render !\n");
        return;
    }
    if (SYVideoI420 == self.videoFormat
        || SYVideoNv12 == self.videoFormat
        || SYVideoNv21 == self.videoFormat)
    {
        SYVideoFrameYUV *yuvFrame = nil;
        switch (self.videoFormat)
        {
            case SYVideoI420:
            {
                yuvFrame = [[SYVideoFrameI420 alloc] initWithBuffer:buffer
                                                             length:size
                                                              width:width
                                                             height:height];
            }
                break;
                
            case SYVideoNv12:
            {
                yuvFrame = [[SYVideoFrameNV12 alloc] initWithBuffer:buffer
                                                             length:size
                                                              width:width
                                                             height:height];
            }
                break;
                
            case SYVideoNv21:
            {
                yuvFrame = [[SYVideoFrameNV21 alloc] initWithBuffer:buffer
                                                             length:size
                                                              width:width
                                                             height:height];
            }
                break;
                
            default:
                break;
        }
        __weak typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            if (NO == [strongSelf createTextureWithYuvFrame:yuvFrame])
            {
                return;
            }
            [strongSelf startRender];
        });
    }
    else if (SYVideoRgb565 == self.videoFormat
             || SYVideoRgb24 == self.videoFormat)
    {
        SYVideoFrameRGB *rgbFrame = nil;
        switch (self.videoFormat)
        {
            case SYVideoRgb565:
            {
                rgbFrame = [[SYVideoFrameRGB565 alloc] initWithBuffer:buffer
                                                               length:size
                                                                width:width
                                                               height:height];
            }
                break;
                
            case SYVideoRgb24:
            {
                rgbFrame = [[SYVideoFrameRGB24 alloc] initWithBuffer:buffer
                                                              length:size
                                                               width:width
                                                              height:height];
            }
                break;
                
            default:
                break;
        }
        __weak typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            if (NO == [strongSelf createTextureWithRgbFrame:rgbFrame])
            {
                return;
            }
            [strongSelf startRender];
        });
    }
    else
    {
        
    }
}

#pragma mark -- 开始渲染
- (void)startRender
{
    [EAGLContext setCurrentContext:self.glContext];
    glBindFramebuffer(GL_FRAMEBUFFER, m_frameBuffer);   // 绑定帧缓冲，开始绘制
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);   // 设置清除缓存时窗体背景颜色
    glClear(GL_COLOR_BUFFER_BIT);   // 开始清除（颜色缓冲）
    
    // 变换矩阵
    [self.modelMat reset];
    [self.modelMat scaleX:m_glViewScale
                        Y:m_glViewScale
                        Z:0.0f];
    [self.modelMat translateX:m_transSpaceX
                            Y:m_transSpaceY
                            Z:0.0f];
    
    /* ========== 视频渲染 ========== */
    [self.shader use];
    [self.shader setUniformMat4:"modelMat"
                       forValue:self.modelMat.use.m];
    [self.shader setUniformMat4:"projectMat"
                       forValue:self.projectMat.use.m];
    // 激活并绑定纹理
    [self.texture0 useInUnit:GL_TEXTURE0];
    [self.texture1 useInUnit:GL_TEXTURE1];
    [self.texture2 useInUnit:GL_TEXTURE2];
    glBindVertexArray(m_VAO);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindVertexArray(0);
    
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];   // 显示 renderbuffer 内容
}

#pragma mark -- 设置是否开启捏合缩放功能
- (void)enableScale:(BOOL)enable
{
    m_isEnableScale = enable;
}

#pragma mark -- 设置捏合缩放比例大小
- (void)setupMaxScale:(CGFloat)maxScale
             minScale:(CGFloat)minScale
{
    if (NO == m_isEnableScale)
    {
        return;
    }
    m_maxGlViewScale = sqrtf(maxScale);
    m_minGlViewScale = sqrtf(minScale);
}

#pragma mark -- 大小变化更新
- (void)updateViewWidth:(GLint)width
                 height:(GLint)height
{
    CGRect viewportRect = CGRectZero;
    if (NO == self.isRatioPlay)
    {
        viewportRect = CGRectMake(0, 0, width, height);
    }
    else
    {
        viewportRect = [SYScalingView scaleWithSubSize:CGSizeMake(m_decodeFrameW, m_decodeFrameH)
                                          inParentSize:CGSizeMake(width, height)];
    }
    glViewport(viewportRect.origin.x,
               viewportRect.origin.y,
               viewportRect.size.width,
               viewportRect.size.height);
}

#pragma mark - 捏合处理
#pragma mark -- 捏合手势添加
-(void)addPinchRestures
{
    if (!m_pinchRecognizer)
    {
        self.multipleTouchEnabled = YES;
        m_pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                     action:@selector(pinchAction:)];
        m_pinchRecognizer.delegate = self;
        [self addGestureRecognizer:m_pinchRecognizer];
    }
}

#pragma mark -- 捏合放大
- (void)pinchAction:(UIPinchGestureRecognizer *)sender
{
    m_glViewScale *= sender.scale;
    
    if (m_maxGlViewScale <= m_glViewScale)
    {
        m_glViewScale = m_maxGlViewScale;
    }
    
    if (m_minGlViewScale >= m_glViewScale)
    {
        m_glViewScale = m_minGlViewScale;
    }
    
    m_transSpaceY = 0;
    m_transSpaceX = 0;
    m_isScaling   = (1 < m_glViewScale) ? YES : NO;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch
{
    return m_isEnableScale;
}

#pragma mark - 移动手势处理
- (void)touchesBegan:(NSSet<UITouch *> *)touches
           withEvent:(UIEvent *)event
{
    if(1 != [touches count])
    {
        return;
    }
    UITouch *touch   = [touches anyObject];
    m_transStartPoint = [touch locationInView:self]; // 移动起点（手指开始点击）
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches
           withEvent:(UIEvent *)event
{
    if(1 != [touches count] || NO == m_isScaling)
    {
        return;
    }
    UITouch *touch = [touches anyObject];
    m_transEndPoint = [touch locationInView:self];   // 移动终点（手指移动-ing）
    
    CGFloat moveHoriSpace = m_transEndPoint.x - m_transStartPoint.x;  // 水平移动距离
    CGFloat moveVertSpace = m_transEndPoint.y - m_transStartPoint.y;  // 垂直移动距离
    
    m_transStartPoint = m_transEndPoint;
    
    CGFloat moveHoriRatio = fabs(moveHoriSpace) / SCREEN_W;     // 水平移动比例
    CGFloat moveVertRatio = fabs(moveVertSpace) / SCREEN_H;     // 垂直移动比例
    CGFloat maxMoveSpace  = (m_glViewScale - 1) * (1/m_glViewScale);
    
    if (0 < moveHoriSpace)  // 向右移
    {
        m_transSpaceX += moveHoriRatio;
        if (maxMoveSpace <= m_transSpaceX)
        {
            m_transSpaceX = maxMoveSpace;
        }
    }
    else    // 向左移
    {
        m_transSpaceX -= moveHoriRatio;
        if (-maxMoveSpace >= m_transSpaceX)
        {
            m_transSpaceX = -maxMoveSpace;
        }
    }
    if (0 >= moveVertSpace) // 向上移
    {
        m_transSpaceY += moveVertRatio;
        if (maxMoveSpace <= m_transSpaceY)
        {
            m_transSpaceY = maxMoveSpace;
        }
    }
    else    // 向下移
    {
        m_transSpaceY -= moveVertRatio;
        if (-maxMoveSpace >= m_transSpaceY)
        {
            m_transSpaceY = -maxMoveSpace;
        }
    }
}

#pragma mark -- 检查 OpenGL 状态机是否出错
- (BOOL)isErrorGL
{
    GLenum glStatus = glGetError();
    BOOL ret = NO;
    switch (glStatus)
    {
        case GL_NO_ERROR:
            ret = NO;
            break;
            
        case GL_INVALID_ENUM:
            ret = YES;
            NSLog(@"GL-ERROR: GL_INVALID_ENUM");
            break;
            
        case GL_INVALID_VALUE:
            ret = YES;
            NSLog(@"GL-ERROR: GL_INVALID_VALUE");
            break;
            
        case GL_INVALID_OPERATION:
            ret = YES;
            NSLog(@"GL-ERROR: GL_INVALID_OPERATION");
            break;
            
        case GL_OUT_OF_MEMORY:
            ret = YES;
            NSLog(@"GL-ERROR: GL_OUT_OF_MEMORY");
            break;
            
        default:
            break;
    }
    return ret;
}


@end
