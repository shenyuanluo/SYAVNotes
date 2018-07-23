//
//  AACParser.h
//  AACParser
//
//  Created by shenyuanluo on 2018/7/23.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#ifndef AACParser_h
#define AACParser_h

#include <iostream>


/* MPEG-4 音频对象类型（2 Bit） */
typedef enum __audioObjectType {
    Object_unknow           = -1,   // 未知
    Object_main             = 0,    // Main
    Object_lc               = 1,    // 低复杂度（Low Complexity）
    Object_ssr              = 2,    // 可伸缩的采样率（Scalable Sample Rate）
    Object_ltp              = 3,    // 长期预测（Long Term Prediction）
    
}AudioObjectType;


/* MPEG-4 音频采样率类型（4 Bit） */
typedef enum __sampleFrequencyType {
    Frequency_unknow            = -1,   // 未知
    Frequency_96000             = 0,    // 96000 Hz
    Frequency_88200             = 1,    // 88200 Hz
    Frequency_64000             = 2,    // 64000 Hz
    Frequency_48000             = 3,    // 48000 Hz
    Frequency_44100             = 4,    // 44100 Hz
    Frequency_32000             = 5,    // 32000 Hz
    Frequency_24000             = 6,    // 24000 Hz
    Frequency_22050             = 7,    // 22050 Hz
    Frequency_16000             = 8,    // 16000 Hz
    Frequency_12000             = 9,    // 12000 Hz
    Frequency_11025             = 10,   // 11025 Hz
    Frequency_8000              = 11,   // 8000 Hz
    Frequency_7350              = 12,   // 7350 Hz
    Frequency_reserved1         = 13,   // 保留 1
    Frequency_reserved2         = 14,   // 保留 2
    Frequency_forbidden         = 15,   // 禁用
}SampleFrequencyType;


class AACParser
{
private:
    AudioObjectType     m_audioType;    // 音频类型
    SampleFrequencyType m_frequency;    // 采样率
    
    
    /**
     解析下一个 ADTS 帧

     @param buffer 待解析数据缓冲
     @param bufSize 数据缓冲大小
     @param adtsBuf ADTS 数据
     @param adtsSize ADTS 数据大小
     @return 解析成功：0； 解析失败（数据大小不足一个 ADTS Frame）：1； 解析出错：-1
     */
    int ParseNextADTSFrame(unsigned char* buffer, unsigned int bufSize, unsigned char* adtsBuf ,unsigned int* adtsSize);
    
public:
    AACParser();
    
    ~AACParser();
    
    /**
     解析 AAC 文件
     
     @param filePath 文件路径
     @return 是否解析成功
     */
    bool parseAACFile(const char* filePath);
};

#endif /* AACParser_h */
