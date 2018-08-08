//
//  fragmentShader.glsl
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

/*
 片段着色器（每个像素点都会运行一次，期间会进行插值）
 */


//#version 120 core

// 精度修饰符分为三种：highp, mediump, lowp
varying highp vec2 texCoord;   // 输入，纹理坐标(顶点着色器传入)
uniform sampler2D textureY;    // 纹理采样器，Y 纹理（I420 数据的 Y 平面数据）
uniform sampler2D textureU;    // 纹理采样器，U 纹理（I420 数据的 U 平面数据）
uniform sampler2D textureV;    // 纹理采样器，V 纹理（I420 数据的 V 平面数据）


/*
 由于 U(Cb)、V(Cr) 取值范围是 [﹣128, 127]，对应的浮点数表示为 [﹣0.5, 0.5]；
 而在存储时，为了方便存储，跟 Y 数据一样，统一用一个(无符号)字节表示，
 即取值范围是 [0, 255]，对应的浮点数表示为：[0, 1]，
 所以在读取是，需要 将 U(Cb)、V(Cr)的浮点值 [0, 1] 减去 128(0.5) 使其变为 ：[﹣0.5, 0.5]。
 */
const highp vec3 coverToCbr = vec3(0.0, -128.0/255.0, -128.0/255.0);    // Y 不用变

/* */
/* ========== YUV --> RGB 的变换矩阵 ==========
 1、（常用）
 __ __     __                         __ __ __
 | R |     | 1.0,  0.0,       1.370705 | | Y'|
 | G |  =  | 1.0, -0.337633, -0.698001 | | U |
 | B |     | 1.0,  1.732446,  0.0      | | V |
 -- --     --                         -- -- --

 2、标清电视标准：BT.601
 __ __     __                       __ __ __
 | R |     | 1.0,  0.0,      1.13983 | | Y'|
 | G |  =  | 1.0, -0.39465, -0.5806  | | U |
 | B |     | 1.0,  2.03211,  0.0     | | V |
 -- --     --                       -- -- --
 
 3、高清电视标准：BT.709
 __ __     __                       __ __ __
 | R |     | 1.0,  0.0,      1.28033 | | Y'|
 | G |  =  | 1.0, -0.21482, -0.38059 | | U |
 | B |     | 1.0,  2.12798,  0.0     | | V |
 -- --     --                       -- -- --
 
*/

const highp mat3 yuvToRGBMat = mat3(1.0,  0.0,       1.370705,
                                    1.0, -0.337633, -0.698001,
                                    1.0,  1.732446,  0.0);


/**
 ’转置矩阵‘变换（OpenGL-ES 不支持 GLSL 内置转置函数‘transpose’）
 
 @param inMatrix  3×3 矩阵
 @return 转置后的 3×3 矩阵
 */
highp mat3 transposeMat3(in highp mat3 inMatrix)
{
    highp vec3 v0 = inMatrix[0];
    highp vec3 v1 = inMatrix[1];
    highp vec3 v2 = inMatrix[2];
    
    highp mat3 outMatrix = mat3(
                                vec3(v0.x, v1.x, v2.x),
                                vec3(v0.y, v1.y, v2.y),
                                vec3(v0.z, v1.z, v2.z)
                                );
    return outMatrix;
}


void main()
{
    highp vec3 pixelRGB;    // 像素点 RGB 值
    highp vec3 pixelYUV;    // 像素点 YUV 值
    
    // 因为是 YUV 的一个平面，所以采样后的r,g,b,a这四个参数的数值是一样的
    /*
     因为 yuv420p（I420、YV12）的采样方式是 planar（即，每一个分量矩阵称为一个平面），
     所有在每个平面（Y平面、U平面、V平面）纹理中，对应的 r、g、b 的数值都是一样的，
     即，texture2D(textureY, texCoord).r == texture2D(textureY, texCoord).g == texture2D(textureY, texCoord).b
     */
    pixelYUV.x = texture2D(textureY, texCoord).r;
    pixelYUV.y = texture2D(textureU, texCoord).r;
    pixelYUV.z = texture2D(textureV, texCoord).r;
    
    pixelYUV += coverToCbr;  // 读取值得范围是0-255，需要要 -128 恢复 Cb、Cr 原来的值
    
    // 输出像素颜色值给光栅器
    gl_FragColor = vec4(transposeMat3(yuvToRGBMat) * pixelYUV, 1.0);
}

