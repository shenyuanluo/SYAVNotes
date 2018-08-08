//
//  SYShader.h
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

/*
 着色器类
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>


@interface SYShader : NSObject

/**
 初始化着色器
 
 @param vsCode 顶点着色器 GLSL 源码
 @param fsCode 片段着色器 GLSL 源码
 @return 着色器实例
 */
- (instancetype)initWithVShaderCode:(const GLchar*)vsCode
                        fShaderCode:(const GLchar*)fsCode;

/**
 获取顶点着色器属性位置

 @param name 属性名
 @return 位置
 */
- (GLuint)getPositionOfAttrib:(const GLchar *)name;

/**
 设置着色器顶点属性下标
 
 @param name 顶点属性名称
 @param index 下标
 */
- (void)setAttrib:(const GLchar *)name
          onIndex:(GLuint)index;

/**
 设置 uniform(int 类型) 的值
 
 @param name uniform 变量-key
 @param value uniform 变量-value
 */
- (void)setUniformInt:(const GLchar *)name
             forValue:(GLint)value;

/**
 设置 uniform(Vector3 类型) 的值
 
 @param name name uniform 变量-key
 @param x Vec3 X 分量的值
 @param y Vec3 Y 分量的值
 @param z Vec3 Z 分量的值
 */
- (void)setUniformVec3:(const GLchar *)name
                  vecX:(GLfloat)x
                  vecY:(GLfloat)y
                  vecZ:(GLfloat)z;

/**
 设置 uniform(Matrix 类型) 的值
 
 @param name uniform 变量-key
 @param value uniform 变量-value
 */
- (void)setUniformMat4:(const GLchar *)name
              forValue:(const GLfloat *)value;

/**
 使用着色器
 */
- (void)use;

/**
 释放着色器
 */
- (void)freeShader;


@end
