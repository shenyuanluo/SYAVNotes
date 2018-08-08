//
//  SYTexture.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import "SYTexture.h"


@interface SYTexture()

@property (nonatomic, readwrite, assign) GLuint textureId;  // 纹理 ID

@end


@implementation SYTexture

- (instancetype)init
{
    if (self = [super init])
    {
        glGenTextures(1, &_textureId);
    }
    return self;
}

#pragma mark -- 创建纹理
- (void)crateTextureWithData:(const GLubyte*)pixel
                       width:(GLsizei)width
                      height:(GLsizei)height
              internalFormat:(GLint)iFormat
                 pixelFormat:(GLint)pFormat
{
    if (NULL == pixel)
    {
        return;
    }
    
    glBindTexture(GL_TEXTURE_2D, self.textureId);   // 绑定纹理
    /* 创建纹理图片 */
    glTexImage2D(GL_TEXTURE_2D, 0, iFormat, width, height, 0, pFormat, GL_UNSIGNED_BYTE, pixel);
    [self configSWrap:GL_CLAMP_TO_EDGE
                tWrap:GL_CLAMP_TO_EDGE];
    [self configMinFilter:GL_LINEAR
                magFilter:GL_LINEAR];
}

#pragma mark -- 使用纹理
- (void)useInUnit:(GLenum)texUnit
{
    glActiveTexture(texUnit);
    glBindTexture(GL_TEXTURE_2D, self.textureId);
}

#pragma mark -- 释放纹理
- (void)freeTexture
{
    if (self.textureId)
    {
        glDeleteTextures(1, &_textureId);
    }
}

#pragma mark -- 设置纹理环绕方式
- (void)configSWrap:(GLint)sWrap
              tWrap:(GLint)tWrap
{
    /* 设置之前先绑定纹理 */
    glBindTexture(GL_TEXTURE_2D, self.textureId);
    /* 设置纹理环绕(S 轴)方式 */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, sWrap);
    /* 设置纹理环绕(T 轴)方式 */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, tWrap);
}

#pragma mark -- 设置纹理过滤方式
- (void)configMinFilter:(GLint)minFilter
              magFilter:(GLint)magFilter
{
    /* 设置之前先绑定纹理 */
    glBindTexture(GL_TEXTURE_2D, self.textureId);
    /* 设置纹理过滤(缩小)方式 */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
    /* 设置纹理过滤(放大)方式 */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);
}

@end
