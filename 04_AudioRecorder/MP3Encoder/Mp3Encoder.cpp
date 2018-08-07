//
//  Mp3Encoder.cpp
//  Mp3Encoder
//
//  Created by shenyuanluo on 2018/7/24.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#include "Mp3Encoder.h"
#include  <unistd.h>


#define SIZE_KB 1024        // 1024


#pragma mark - Public
#pragma mark -- 构造函数
Mp3Encoder::Mp3Encoder()
{
    m_isRecording = false;
}

#pragma mark -- 析构函数
Mp3Encoder::~Mp3Encoder()
{
    if (m_pcmFile)
    {
        fclose(m_pcmFile);
        m_pcmFile = NULL;
    }
    if (m_mp3File)
    {
        fclose(m_mp3File);
        m_mp3File = NULL;
    }
}

#pragma mark -- 初始化参数
bool Mp3Encoder::InitParam(const char* pcmFilePath, const char* mp3FilePath, int sampleRate, int numChannels, int bitRate)
{
    if (NULL == pcmFilePath || NULL == mp3FilePath)
    {
        return false;
    }
    m_pcmFile = fopen(pcmFilePath, "rb");   // 打开 PCM 文件
    if (NULL == m_pcmFile)
    {
        printf("打开 PCM 文件失败！\n");
        return false;
    }
    m_mp3File = fopen(mp3FilePath, "wb+");  // 打开 MP3 文件
    if (NULL == m_mp3File)
    {
        printf("打开 MP3 文件失败！\n");
        return false;
    }
    m_lameClient = lame_init(); //  初始化 lame
    lame_set_in_samplerate(m_lameClient, sampleRate);   // 设置 PCM 采样率（Hz)
    lame_set_out_samplerate(m_lameClient, sampleRate);  // 设置 MP3 采样率（Hz)
    lame_set_num_channels(m_lameClient, numChannels);   // 设置声道数
    lame_set_brate(m_lameClient, bitRate/1000);         // 设置比特率（kb/s)
    lame_init_params(m_lameClient);     // 初始化 Lame 参数
    
    return true;
}

#pragma mark -- 开始编码 MP3 
void Mp3Encoder::StartEncode()
{
    int bufferSize = SIZE_KB * 256;
    unsigned short* pcmBuffer   = (unsigned short*)malloc(bufferSize);  // PCM 数据缓冲
    unsigned short* leftBuffer  = (unsigned short*)malloc(bufferSize/2);// PCM 左声道数据缓冲
    unsigned short* rightBuffer = (unsigned short*)malloc(bufferSize/2);// PCM 右声道数据缓冲
    unsigned char* mp3Buffer    = (unsigned char*)malloc(bufferSize);   // MP3 数据缓冲
    if (NULL == pcmBuffer || NULL == leftBuffer || NULL == rightBuffer || NULL == mp3Buffer)
    {
        printf("申请内存失败！\n");
        return;
    }
    
    size_t readSize  = 0;   // 实际读取 PCM 数据大小
    size_t writeSize = 0;   // 实际写入 MP3 数据大小
    /*
     WAV 文件头长度 44 Byte，需要如果是 WAV 文件则需要跳过文件头（否则转码的 MP3 开头会有爆音）；
     如果是裸 PCM 数据文件，则不需要跳过
     */
    fseek(m_pcmFile, 44 * 1024, SEEK_SET);
    
    long curPos = 0;        // PCM 当前读取位置
    long endPos = 0;        // PCM 当前已录制文件长度
    size_t recordSize = 0;  // 新录制 PCM 长度
    
    while (m_isRecording)
    {
        memset(pcmBuffer, 0, bufferSize);
        memset(leftBuffer, 0, bufferSize/2);
        memset(rightBuffer, 0, bufferSize/2);
        memset(mp3Buffer, 0, bufferSize);
        
        curPos = ftell(m_pcmFile);  // 获取当前文件指针位置
        fseek(m_pcmFile, 0, SEEK_END);  // 将读取指针移至文件末尾
        endPos = ftell(m_pcmFile);  // 获取当前文件指针位置
        
        recordSize = endPos - curPos;
        fseek(m_pcmFile, curPos, SEEK_SET); // 将读取指针重新回归上次读取位置
        
        readSize = fread(pcmBuffer, 2, recordSize / 2, m_pcmFile);   // 读取 PCM 数据
        
        for (int i = 0; i < readSize; i++)    // 分离左、右声道数据
        {
            if (0 == (i & 1))   // 左声道（i%2 = 0)
            {
                leftBuffer[i/2] = pcmBuffer[i];
            }
            else
            {
                rightBuffer[i/2] = pcmBuffer[i];
            }
        }
        writeSize = lame_encode_buffer(m_lameClient, (short*)leftBuffer, (short*)rightBuffer, (int)(readSize/2), mp3Buffer, bufferSize);    // 开始编码 MP3 数据
        
        fwrite(mp3Buffer, 1, writeSize, m_mp3File); // 写入 MP3  数据
        
        usleep(100);    // 等待 pcm 数据录制
    }
    printf("PCM 转 Mp3 完成！\n");
    
    free(pcmBuffer);
    free(leftBuffer);
    free(rightBuffer);
    free(mp3Buffer);
    pcmBuffer   = NULL;
    leftBuffer  = NULL;
    rightBuffer = NULL;
    mp3Buffer   = NULL;

}

void Mp3Encoder::SetRecordingFlag(bool flag)
{
    m_isRecording = flag;
}


#pragma mark - Private
