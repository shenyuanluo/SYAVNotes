//
//  VideoDecoder.cpp
//  VideoDecoder
//
//  Created by shenyuanluo on 2018/8/1.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#include "VideoDecoder.h"
#include <unistd.h>

#ifdef __cplusplus
extern "C" {
#endif
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
#ifdef __cplusplus
}
#endif


#define VIDEO_FPS  40  // 视频帧率（这里模拟的需要算上解码时间）


#pragma mark - Public
#pragma mark -- 构造函数
VideoDocoder::VideoDocoder()
{
    // 1. 注册所支持的所有的视频文件（容器）格式及其对应的 CODEC（编解码器）（注意：只需调用一次）
    av_register_all();
}

#pragma mark -- 析构函数
VideoDocoder::~VideoDocoder()
{
    
}

#pragma mark -- 设置解码数据回调函数
void VideoDocoder::setDecodeDataCB(DecDataCallBack decDataCB)
{
    if (NULL == decDataCB)
    {
        return;
    }
    m_decCB = decDataCB;
}

#pragma mark -- 解码文件
int VideoDocoder::DecodeFile(const char* filePath, DecDataFormat dataFmt)
{
    if (NULL == filePath)
    {
        std::cout << "文件路径不存在，无法解码！" << std::endl;
        return -1;
    }
    AVFormatContext*    avFormatCtx     = NULL;     // 封装格式上下文
    AVStream*           videoStream     = NULL;     // 视频流信息结构体
    AVCodecContext*     avCodecCtx      = NULL;     // 解码器上下文
    AVCodec*            avCodec         = NULL;     // 解码器
    AVPixelFormat       pixelFmt        = AV_PIX_FMT_NONE;  // 解码后的视频帧数据格式
    AVFrame*            decAvFrame      = NULL;     // 解码后的视频帧
    AVFrame*            scaleAvFrame    = NULL;     // 解码转换后的视频帧（YUV420p、RGB24）
    AVPacket            avPacket;
    struct SwsContext*  swsCtx          = NULL;
    unsigned int        frameNo         = 0;        // 帧序号
    int                 videoStreamIdx  = -1;       // 视频流下标（第一路流）
    uint8_t*            decBuffer       = NULL;     // 解码数据缓冲
    int                 decBuffLen      = 0;        // 解码数据缓冲大小
    
    // 2. 打开（视频）文件
    if (0 != avformat_open_input(&avFormatCtx, filePath, NULL, NULL))
    {
        std::cout << "打开（视频）文件失败！" << std::endl;
        return -1;
    }
    // 3. 提取视频流信息
    if (0 > avformat_find_stream_info(avFormatCtx, NULL))
    {
        std::cout << "无法提取视频流信息！" << std::endl;
        return -1;
    }
    
#ifdef DEBUG
    // 将文件信息打印至标准输出（一般：在调试模式下使用）
    av_dump_format(avFormatCtx, 0, filePath, 0);
#endif
    
    // 4. (在多路流中）查找第一路视频流
    for (int i = 0; i < avFormatCtx->nb_streams; i++)
    {
        if (AVMEDIA_TYPE_VIDEO != avFormatCtx->streams[i]->codecpar->codec_type)    // 查找视频流
        {
            continue;
        }
        videoStream    = avFormatCtx->streams[i];
        videoStreamIdx = i;
        break;
    }
    if (NULL == videoStream || -1 == videoStreamIdx)
    {
        std::cout << "无法找到视频流信息！" << std::endl;
        return -1;
    }
    // 5. 获取视频流对应的解码器和上下文
    avCodec    = avcodec_find_decoder(videoStream->codecpar->codec_id); // 根据编解码 ID 查找 解码器
    avCodecCtx = avcodec_alloc_context3(avCodec);   // 为解码器上下文申请内存
    avcodec_parameters_to_context(avCodecCtx, videoStream->codecpar); // 将解码器相关的信息从 AVCodecParameters 复制到 AVCodecContext
    if (NULL == avCodec)
    {
        std::cout << "找不到匹配的解码器！" << std::endl;
        return -1;
    }
    // 6. 打开解码器
    if (0 > avcodec_open2(avCodecCtx, avCodec, NULL))
    {
        std::cout << "无法打开解码器！" << std::endl;
        return -1;
    }
    // 7. 为解码帧分配内存
    decAvFrame   = av_frame_alloc();
    scaleAvFrame = av_frame_alloc();
    if (NULL == decAvFrame || NULL == scaleAvFrame)
    {
        std::cout << "为解码帧分配内存失败！" << std::endl;
        return -1;
    }
    if (DecData_yuv420p == dataFmt) // 解码成 YUV420p
    {
        pixelFmt = AV_PIX_FMT_YUV420P;
        
    }
    else if (DecData_rgb24 == dataFmt)  // 解码成 RGB24
    {
        pixelFmt = AV_PIX_FMT_RGB24;
    }
    // 8. 确定所需的缓冲区大小并分配内存
    decBuffLen = av_image_get_buffer_size(pixelFmt, avCodecCtx->width, avCodecCtx->height, 1);
    decBuffer  = (uint8_t*)av_malloc(decBuffLen * sizeof(uint8_t));    // 申请内存
    
    // 将解码后的帧（frame）关联到刚才分配的内存
    av_image_fill_arrays(scaleAvFrame->data, scaleAvFrame->linesize, decBuffer, pixelFmt, avCodecCtx->width, avCodecCtx->height, 1);
    
    // 初始化 SWS
    swsCtx = sws_getContext(avCodecCtx->width, avCodecCtx->height, avCodecCtx->pix_fmt, avCodecCtx->width, avCodecCtx->height, pixelFmt, SWS_BILINEAR, NULL, NULL, NULL);
    
    // 9. 循环读取视频帧
    int ret = -1;
    while (0 <= av_read_frame(avFormatCtx, &avPacket))  // 每次读取一个数据包（packet），将其存储到 AVPacket 结构体中
    {
        // 判断是否当前需要解析的（那一路）视频流
        if (avPacket.stream_index != videoStreamIdx)
        {
            continue;
        }
        // 10. 开始解码视频帧：将数据包（packet）转换为视频帧（frame） （‘avcodec_decode_video2’ is deprecated）
        ret = avcodec_send_packet(avCodecCtx, &avPacket); // 将读取的数据包发送到解码器进行解码
        if (0 != ret)
        {
            std::cout << "数据包发送至解码器失败！" << std::endl;
            continue;
        }
        ret = avcodec_receive_frame(avCodecCtx, decAvFrame);    // 从解码器接收解码收的数据帧
        av_packet_unref(&avPacket); // （注意，记得释放数据包内存，否则会内存泄露）（‘av_free_packet’ is deprecated）
        
        // 通过睡眠模拟帧率
        usleep((unsigned int)(((float)(1.0f / VIDEO_FPS)) * 1000000));
        
        if (0 == ret)    // 解码成功（解码到完整的一帧时）
        {
            // 将视频帧转换成 RGB 格式
            sws_scale(swsCtx, (const uint8_t *const *)decAvFrame, decAvFrame->linesize, 0, avCodecCtx->height, scaleAvFrame->data, scaleAvFrame->linesize);
            
            if (m_decCB)
            {
                m_decCB(dataFmt, decBuffer, decBuffLen, avCodecCtx->width, avCodecCtx->height);
            }
        }
        else
        {
            std::cout << "第 " << frameNo << " 帧解码失败！" << std::endl;
        }
        frameNo++;
    }
    av_free(decBuffer);
    av_frame_free(&scaleAvFrame);
    av_frame_free(&decAvFrame);
    avcodec_free_context(&avCodecCtx);
    avformat_close_input(&avFormatCtx);
    
    std::cout << "解码完毕！" << std::endl;
    
    return 0;
}
