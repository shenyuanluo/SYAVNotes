//
//  SYShader.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import "SYShader.h"


typedef NS_ENUM(NSInteger, ShaderType) {
    ShaderVertex                = 0x00,     /* 顶点着色器 */
    ShaderFragment              = 0x01,     /* 片段着色器 */
    ShaderProgram               = 0x02,     /* 着色器程序 */
};


@interface SYShader()
@property (nonatomic, readwrite, assign) GLuint programId;
@end


@implementation SYShader

#pragma mark -- 初始化着色器
- (instancetype)initWithVShaderCode:(const GLchar*)vsCode
                        fShaderCode:(const GLchar*)fsCode
{
    if (NULL == vsCode || NULL == fsCode)
    {
        return nil;
    }
    if (self = [super init])
    {
        // 顶点着色器
        GLuint vShaderId = [self createShader:ShaderVertex
                                     withCode:vsCode];
        // 检查 顶点 着色器是否创建出错
        if (YES == [self isErrorShader:vShaderId
                                  type:ShaderVertex])
        {
            [self releaseShader:vShaderId
                           type:ShaderVertex];
            return nil;
        }
        
        // 片段着色器
        GLuint fShaderId = [self createShader:ShaderFragment
                                     withCode:fsCode];
        // 检查 片段 着色器是否创建出错
        if (YES == [self isErrorShader:fShaderId
                                  type:ShaderFragment])
        {
            [self releaseShader:fShaderId
                           type:ShaderFragment];
            return nil;
        }
        
        // 着色器程序
        self.programId = [self createProgramWithVShaderId:vShaderId
                                             andFShaderId:fShaderId];
        // 检查 着色器程序是否创建出错
        if (YES == [self isErrorShader:self.programId
                                  type:ShaderProgram])
        {
            [self releaseShader:self.programId
                           type:ShaderProgram];
            return nil;
        }
        
        // 移除顶点着色器 （已成功链接到 Program 的 shader 可以移除）
        [self releaseShader:vShaderId
                       type:ShaderVertex];
        // 移除片段着色器
        [self releaseShader:fShaderId
                       type:ShaderFragment];
    }
    return self;
}

#pragma mark --  获取顶点着色器属性位置
- (GLuint)getPositionOfAttrib:(const GLchar *)name
{
    return glGetAttribLocation(self.programId, name);
}

#pragma mark -- 设置着色器顶点属性下标
- (void)setAttrib:(const GLchar *)name
          onIndex:(GLuint)index
{
    if (NULL == name)
    {
        return;
    }
    glUseProgram(self.programId);   // 绑定着色器程序(对着色器设置之前，先绑定)
    glBindAttribLocation(self.programId, index, name);
}

#pragma mark -- 设置 uniform(int 类型) 的值
- (void)setUniformInt:(const GLchar *)name
             forValue:(GLint)value
{
    if (NULL == name)
    {
        return;
    }
    glUseProgram(self.programId);   // 绑定着色器程序(对着色器设置之前，先绑定)
    glUniform1i([self uniformLocation:name], value);
}

#pragma mark -- 设置 uniform(Vector3 类型) 的值
- (void)setUniformVec3:(const GLchar *)name
                  vecX:(GLfloat)x
                  vecY:(GLfloat)y
                  vecZ:(GLfloat)z
{
    glUseProgram(self.programId);   // 绑定着色器程序(对着色器设置之前，先绑定)
    glUniform3f([self uniformLocation:name], x, y, z);
}

#pragma mark -- 设置 uniform(Matrix 类型) 的值
- (void)setUniformMat4:(const GLchar *)name
              forValue:(const GLfloat *)value
{
    if (NULL == name)
    {
        return;
    }
    glUseProgram(self.programId);   // 绑定着色器程序(对着色器设置之前，先绑定)
    glUniformMatrix4fv([self uniformLocation:name], 1, GL_FALSE, value);
}

#pragma mark -- 使用着色器
- (void)use
{
    // 绑定着色器程序，以供使用
    glUseProgram(self.programId);
}

#pragma mark -- 释放着色器
- (void)freeShader
{
    if (self.programId)
    {
        [self releaseShader:self.programId
                       type:ShaderProgram];
    }
}

#pragma mark -- 获取 Uniform 变量地址
- (GLint)uniformLocation:(const GLchar *)name
{
    if (NULL == name || 0 == self.programId)
    {
        return -1;
    }
    GLint location = glGetUniformLocation(self.programId, name);
    return location;
}

#pragma mark -- 创建着色器
- (GLuint)createShader:(ShaderType)sType
              withCode:(const GLchar *)shaderCode
{
    if (NULL == shaderCode)
    {
        NSLog(@"Can not create Shader !");
        return 0;
    }
    GLuint shaderId;
    switch (sType)
    {
        case ShaderVertex:  // 顶点着色器
            shaderId = glCreateShader(GL_VERTEX_SHADER);
            break;
            
        case ShaderFragment:    // 片段着色器
            shaderId = glCreateShader(GL_FRAGMENT_SHADER);
            break;
            
        default:
            shaderId = 0;
            break;
    }
    glShaderSource(shaderId, 1, &shaderCode, NULL); // 执行创建着色器 GLSL 的源码
    glCompileShader(shaderId);  // 编译 GLSL 源码
    
    return shaderId;
}

#pragma mark -- 创建着色器程序
- (GLuint)createProgramWithVShaderId:(GLuint)vShaderId
                        andFShaderId:(GLuint)fShaderId

{
    GLuint program = glCreateProgram(); // 创建着色器程序
    glAttachShader(program, vShaderId); // 添加 顶点着色器
    glAttachShader(program, fShaderId); // 添加 片段着色器
    glLinkProgram(program); // 链接 着色器程序
    return program;
}

#pragma mark -- 移除着色器
- (void)releaseShader:(GLuint)shaderId
                 type:(ShaderType)sType
{
    if (0 == shaderId)
    {
        return;
    }
    switch (sType)
    {
        case ShaderVertex:   glDeleteShader(shaderId);  break;
        case ShaderFragment: glDeleteShader(shaderId);  break;
        case ShaderProgram:  glDeleteProgram(shaderId); break;
        default: break;
    }
}

#pragma mark -- 检测着色器是否出错
- (BOOL)isErrorShader:(GLuint)shaderId
                 type:(ShaderType)sType
{
    GLint isSuccess;
    switch (sType)
    {
        case ShaderVertex:  // 顶点着色器
        {
            /* 检查编译 GLSL 是否出错 */
            glGetShaderiv(shaderId, GL_COMPILE_STATUS, &isSuccess);
            if (!isSuccess)
            {
                GLint logBuffLen;
                glGetShaderiv(shaderId, GL_INFO_LOG_LENGTH, &logBuffLen);
                if (0 >= logBuffLen)
                {
                    break;
                }
                /* 获取 编译 信息 */
                GLchar *infoLog = (GLchar *)malloc(logBuffLen);
                glGetShaderInfoLog(shaderId, logBuffLen, NULL, infoLog);
                NSLog(@"Crate Vertex shader failure ：%s", infoLog);
                free(infoLog);
            }
        }
            break;
            
        case ShaderFragment:    // 片段着色器
        {
            /* 检查编译 GLSL 是否出错 */
            glGetShaderiv(shaderId, GL_COMPILE_STATUS, &isSuccess);
            if (!isSuccess)
            {
                GLint logBuffLen;
                glGetShaderiv(shaderId, GL_INFO_LOG_LENGTH, &logBuffLen);
                if (0 >= logBuffLen)
                {
                    break;
                }
                /* 获取 编译 信息 */
                GLchar *infoLog = (GLchar *)malloc(logBuffLen);
                glGetShaderInfoLog(shaderId, logBuffLen, NULL, infoLog);
                NSLog(@"Crate Fragment shader failure ：%s", infoLog);
                free(infoLog);
            }
        }
            break;
            
        case ShaderProgram: // 着色器程序
        {
            /* 检查着色器程序链接是否出错 */
            glGetProgramiv(shaderId, GL_LINK_STATUS, &isSuccess);
            if (!isSuccess)
            {
                GLint logBuffLen;
                glGetProgramiv(shaderId, GL_INFO_LOG_LENGTH, &logBuffLen);
                if (0 >= logBuffLen)
                {
                    break;
                }
                /* 获取 链接 信息 */
                GLchar *infoLog = (GLchar *)malloc(logBuffLen);
                glGetProgramInfoLog(shaderId, logBuffLen, NULL, infoLog);
                NSLog(@"Link Shader program failure ：%s", infoLog);
                free(infoLog);
            }
        }
            break;
            
        default:
            isSuccess = GL_FALSE;
            break;
    }
    return !isSuccess;
}

@end
