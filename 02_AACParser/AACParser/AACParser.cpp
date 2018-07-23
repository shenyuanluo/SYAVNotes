//
//  AACParser.cpp
//  AACParser
//
//  Created by shenyuanluo on 2018/7/23.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#include "AACParser.h"


#define IS_OUT_PUT_FILE 0   // 解析结果是否输出到文件
#define SIZE_KB 1024        // 1024
#define SIZE_MB 1048576     // 1024 * 1024


#pragma mark - Public
#pragma mark -- 构造函数
AACParser::AACParser()
{
    m_audioType    = Object_unknow;
    m_frequency    = Frequency_unknow;
}

#pragma mark -- 析构函数
AACParser::~AACParser()
{
    
}

#pragma mark -- 解析 AAC 文件
bool AACParser::parseAACFile(const char* filePath)
{
    if (NULL == filePath)
    {
        return false;
    }
    FILE* fp_aac = fopen(filePath, "rb");
    if(NULL == fp_aac)
    {
        printf("打开 AAC 文件失败！\n");
        return false;
    }
    FILE* fp_out;
    if (IS_OUT_PUT_FILE)
    {
        fp_out = fopen("outPut_log.txt", "wb+");
    }
    else
    {
        fp_out = stdout;
    }
    unsigned int size     = 0;
    unsigned int dataSize = 0;
    unsigned int count    = 0;
    unsigned int offset   = 0;
    
    unsigned char* parseBuf = (unsigned char*)malloc(SIZE_MB);
    unsigned char* aacFrame = (unsigned char*)malloc(5 * SIZE_KB);
    
    fprintf(fp_out, "-----+- ADTS Frame Table -+------+\n");
    fprintf(fp_out, " NUM | Profile | Frequency| Size |\n");
    fprintf(fp_out, "-----+---------+----------+------+\n");
    
    while(!feof(fp_aac))
    {
        dataSize = (unsigned int)fread(parseBuf + offset, 1, SIZE_MB - offset, fp_aac);
        unsigned char* inputData = parseBuf;
        
        while(1)
        {
            int ret = ParseNextADTSFrame(inputData, dataSize, aacFrame, &size);
            if(-1 == ret)   // 解析出错
            {
                break;
            }
            else if(1 == ret)   // 解析失败：数据不足一个 ADTS Frame
            {
                memcpy(parseBuf, inputData, dataSize);  // 复制不足部分数据以便重复解析
                offset = dataSize;
                break;
            }
            
            char profileStr[10] = {0};
            char frequenceStr[10] = {0};
            
            m_audioType = (AudioObjectType)((aacFrame[2]&0xC0)>>6);
            
            switch(m_audioType) // 类型
            {
                case Object_main: sprintf(profileStr,"Main");    break;
                case Object_lc:   sprintf(profileStr,"LC");      break;
                case Object_ssr:  sprintf(profileStr,"SSR");     break;
                case Object_ltp:  sprintf(profileStr,"LTP");     break;
                default:          sprintf(profileStr,"unknown"); break;
            }
            
            m_frequency = (SampleFrequencyType)((aacFrame[2]&0x3C)>>2);

            switch(m_frequency) // 采样率
            {
                case Frequency_96000: sprintf(frequenceStr,"96000Hz"); break;
                case Frequency_88200: sprintf(frequenceStr,"88200Hz"); break;
                case Frequency_64000: sprintf(frequenceStr,"64000Hz"); break;
                case Frequency_48000: sprintf(frequenceStr,"48000Hz"); break;
                case Frequency_44100: sprintf(frequenceStr,"44100Hz"); break;
                case Frequency_32000: sprintf(frequenceStr,"32000Hz"); break;
                case Frequency_24000: sprintf(frequenceStr,"24000Hz"); break;
                case Frequency_22050: sprintf(frequenceStr,"22050Hz"); break;
                case Frequency_16000: sprintf(frequenceStr,"16000Hz"); break;
                case Frequency_12000: sprintf(frequenceStr,"12000Hz"); break;
                case Frequency_11025: sprintf(frequenceStr,"11025Hz"); break;
                case Frequency_8000:  sprintf(frequenceStr,"8000Hz");  break;
                case Frequency_7350:  sprintf(frequenceStr,"7350Hz");  break;
                default:              sprintf(frequenceStr,"unknown"); break;
            }
            
            fprintf(fp_out,"%5d| %8s|  %8s| %5d|\n", count++, profileStr ,frequenceStr, size);
            
            dataSize  -= size;
            inputData += size;
        }
    }
    fclose(fp_aac);
    free(parseBuf);
    free(aacFrame);
    parseBuf = NULL;
    aacFrame = NULL;
    
    return 0;
}



#pragma mark - Private
#pragma mark -- 解析下一个 ADTS
int AACParser::ParseNextADTSFrame(unsigned char* buffer, unsigned int bufSize, unsigned char* adtsBuf ,unsigned int* adtsSize)
{
    if (NULL == buffer || NULL == adtsBuf || 0 == bufSize)
    {
        return -1;
    }
    unsigned int size = 0;
    while(1)
    {
        if(7 > bufSize) // ADTS 头部长度 7 Byte（或 9 Byte 当有 CRC 时）
        {
            return -1;
        }
        // 查找同步字：0xFFF
        if(0xff == buffer[0]    // 第一字节
           && 0xf0 == (buffer[1] & 0xf0))   // 第二字节：高 4 Bit
        {
            // 解析 ADTS 帧大小：13 Bit
            size |= ((buffer[3] & 0x03)<<11);       // 高 2 bit
            size |= buffer[4]<<3;                   // 中 8 bit
            size |= ((buffer[5] & 0xe0)>>5);        // 低 3 bit
            break;
        }
        bufSize--;
        buffer++;
    }
    
    if(bufSize < size)
    {
        return 1;
    }
    memcpy(adtsBuf, buffer, size); // 复制 ADTS 数据
    *adtsSize = size;
    
    return 0;
}
