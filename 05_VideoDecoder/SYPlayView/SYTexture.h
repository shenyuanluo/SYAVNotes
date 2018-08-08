//
//  SYTexture.h
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

/*
 纹理类
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>


@interface SYTexture : NSObject

/**
 创建纹理
 
 @param pixel 纹理数据
 @param width 纹理宽度
 @param height 纹理高度
 @param iFormat 纹理（内部存储）格式
 @param pFormat 纹理（数据类型）格式
 */
- (void)crateTextureWithData:(const GLubyte*)pixel
                       width:(GLsizei)width
                      height:(GLsizei)height
              internalFormat:(GLint)iFormat
                 pixelFormat:(GLint)pFormat;

/**
 使用纹理（激活并绑定指定纹理单元）
 
 @param texUnit 纹理单元：GL_TEXTURE0 +
 */
- (void)useInUnit:(GLenum)texUnit;

/**
 释放纹理
 */
- (void)freeTexture;

@end
