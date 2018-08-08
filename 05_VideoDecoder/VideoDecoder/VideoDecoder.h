//
//  VideoDecoder.h
//  VideoDecoder
//
//  Created by shenyuanluo on 2018/8/1.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#ifndef VideoDecoder_h
#define VideoDecoder_h

#include <iostream>


/* 解码回调数据格式 */
typedef enum __decDataFormat {
    DecData_unknow          = -1,       // 未知
    DecData_yuv420p         = 0,        // YUV420p
    DecData_rgb24           = 1,        // RGB24
}DecDataFormat;


/**
 解码数据回调函数指针

 @param fmt 数据格式
 @param buff 数据缓冲
 @param size 数据大小
 @param width 视频帧宽度
 @param height 视频帧高度
 */
typedef void (*DecDataCallBack)(DecDataFormat fmt, unsigned char* buff, unsigned int size, unsigned int width, unsigned int height);


class VideoDocoder
{
private:
    DecDataCallBack     m_decCB;    // 解码数据回调函数指针
    
    
public:
    VideoDocoder();
    
    ~VideoDocoder();
    
    /**
     设置解码数据回调函数

     @param decDataCB <#decDataCB description#>
     */
    void setDecodeDataCB(DecDataCallBack decDataCB);
    
    /**
     解码（视频）文件

     @param filePath 文件路径
     @param dataFmt 设置解码后数据格式
     @return 是否解码成功；0：成功，-1：失败
     */
    int DecodeFile(const char* filePath, DecDataFormat dataFmt);
};

#endif /* VideoDecoder_h */
