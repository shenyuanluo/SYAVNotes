//
//  Mp3Encoder.h
//  Mp3Encoder
//
//  Created by shenyuanluo on 2018/7/24.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#ifndef Mp3Encoder_h
#define Mp3Encoder_h

#include <iostream>
#include "lame.h"

/*
 Mp3 编码器类（PCM ==> MP3）
 */
class Mp3Encoder
{
private:
    FILE*  m_pcmFile;       // PCM 文件句柄
    FILE*  m_mp3File;       // MP3 文件句柄
    lame_t m_lameClient;    // Lame
    
public:
    Mp3Encoder();
    
    ~Mp3Encoder();
    
    /**
     初始化（每次转换前都要设置）

     @param pcmFilePath PCM 文件路径（输入数据）
     @param mp3FilePath MP3 文件路径（输出数据）
     @param sampleRate 采样率
     @param numChannels 声道数
     @param bitRate 比特率（= 采样率 × 通道数 × 声道数）
     @return 是否初始化成功
     */
    bool InitParam(const char* pcmFilePath, const char* mp3FilePath, int sampleRate, int numChannels, int bitRate);
    
    /**
     开始编码（MP3）
     */
    void StartEncode();
};

#endif /* Mp3Encoder_h */
