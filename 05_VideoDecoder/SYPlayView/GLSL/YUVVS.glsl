//
//  vertexShader.glsl
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

/*
 顶点着色器（每个顶点都会运行一次）
 */


// attribute 关键字仅用来描述其是传入 顶点着色器 的变量
attribute vec4 aPos;       // 输入，顶点坐标
attribute vec2 aTexCoor;   // 输入，纹理坐标

uniform mat4 modelMat;     // 模型 矩阵
uniform mat4 projectMat;   // 投影 矩阵

// varying 关键字用来描述从顶点着色器传递给片段着色器的变量
varying vec2 texCoord;     // 输出，纹理坐标(传递给片段着色器)

void main()
{
    // gl_Position 是顶点着色器的内建变量，最终输出到渲染管线中
    gl_Position = projectMat * modelMat * aPos;
    texCoord    = aTexCoor;
}

