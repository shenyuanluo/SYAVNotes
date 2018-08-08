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
uniform sampler2D textureR;    // 纹理采样器，R 纹理
uniform sampler2D textureG;    // 纹理采样器，G 纹理
uniform sampler2D textureB;    // 纹理采样器，B 纹理


void main()
{
    highp vec3 pixelRGB;    // 像素点 RGB 值
    pixelRGB.r   = texture2D(textureR, texCoord).r;
    pixelRGB.g   = texture2D(textureG, texCoord).r;
    pixelRGB.b   = texture2D(textureB, texCoord).r;
    gl_FragColor = vec4(pixelRGB, 1.0);
}

