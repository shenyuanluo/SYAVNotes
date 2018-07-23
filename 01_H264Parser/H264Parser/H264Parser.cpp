//
//  H264Parser.cpp
//  H264Parser
//
//  Created by shenyuanluo on 2018/7/21.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#include "H264Parser.h"


#define IS_OUT_PUT_FILE 0   // 解析结果是否输出到文件


#pragma mark - Public
#pragma mark -- 构造函数
H264Parser::H264Parser()
{
    m_maxBuffSize = 100000;
    m_naluSize    = sizeof(NalUnit);
    m_nalu = (NalUnit*)malloc(m_naluSize);
    if (NULL == m_nalu)
    {
        printf("NALU 内存申请失败！");
    }
    else
    {
        memset(m_nalu, 0, m_naluSize);
        m_nalu->data = (char *)malloc(m_maxBuffSize);
        if (NULL == m_nalu->data)
        {
            printf ("NALU 数据内存申请失败！");
            free (m_nalu);
            m_nalu = NULL;
        }
        else
        {
            memset(m_nalu->data, 0, m_maxBuffSize);
        }
        m_parseNaluBuf = (unsigned char*)malloc(m_maxBuffSize);
        if (NULL == m_parseNaluBuf)
        {
            printf("解析 NALU 内存申请失败！");
        }
        else
        {
            memset(m_parseNaluBuf, 0, m_maxBuffSize);
        }
    }
}

#pragma mark -- 析构函数
H264Parser::~H264Parser()
{
    if (m_nalu)
    {
        if (m_nalu->data)
        {
            free(m_nalu->data);
            m_nalu->data = NULL;
        }
        free (m_nalu);
        m_nalu = NULL;
    }
}

#pragma mark -- 解析 H264 码流文件
bool H264Parser::parseH264File(const char *filePath)
{
    if (NULL == filePath)
    {
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
    if (NULL == fp_out)
    {
        return false;
    }
    if (m_fpH264)
    {
        fclose(m_fpH264);
        m_fpH264 = NULL;
    }
    m_fpH264 = fopen(filePath, "rb+");
    if (NULL == m_fpH264)
    {
        printf("打开 H264 文件失败！\n");
        return false;
    }
    
    unsigned int dataOffset = 0;    // 数据偏移量
    unsigned int naluIdx    = 0;    // NALU 序号
    
    fprintf(fp_out, "-----+-------- NALU Table ------+---------+\n");
    fprintf(fp_out, " NUM |    POS  |    IDC |  TYPE |   LEN   |\n");
    fprintf(fp_out, "-----+---------+--------+-------+---------+\n");
    
    while(!feof(m_fpH264))
    {
        int dataLenth = ExtractAnnexbNalu();
        
        char typeStr[20] = {0};
        switch(m_nalu->type)
        {
            case Nalu_unknow:   sprintf(typeStr, "Unknow");     break;
            case Nalu_slice:    sprintf(typeStr, "SLICE");      break;
            case Nalu_dpa:      sprintf(typeStr, "DPA");        break;
            case Nalu_dpb:      sprintf(typeStr, "DPB");        break;
            case Nalu_dpc:      sprintf(typeStr, "DPC");        break;
            case Nalu_idr:      sprintf(typeStr, "IDR");        break;
            case Nalu_sei:      sprintf(typeStr, "SEI");        break;
            case Nalu_sps:      sprintf(typeStr, "SPS");        break;
            case Nalu_pps:      sprintf(typeStr, "PPS");        break;
            case Nalu_aud:      sprintf(typeStr, "AUD");        break;
            case Nalu_eoseq:    sprintf(typeStr, "EOSEQ");      break;
            case Nalu_eostream: sprintf(typeStr, "EOSTREAM");   break;
            case Nalu_fill:     sprintf(typeStr, "FILL");       break;
        }
        char idcStr[20] = {0};
        switch(m_nalu->level)
        {
            case Reference_disposable: sprintf(idcStr, "DISPOS");   break;
            case Reference_low:        sprintf(idcStr, "LOW");      break;
            case Reference_middle:     sprintf(idcStr, "HIGH");     break;
            case Reference_high:       sprintf(idcStr, "HIGHEST");  break;
        }
        
        fprintf(fp_out, "%5d| %8d| %7s| %6s| %8d|\n", naluIdx, dataOffset, idcStr, typeStr, m_nalu->len);
        
        dataOffset += dataLenth;
        naluIdx++;
    }
    
    
    return 0;
}


#pragma mark - Private
#pragma mark -- 查找起始码 1：0x000001
bool H264Parser::FindStartCode1(unsigned char* buff)
{
    // 起始码1：0x000001
    if (0 != buff[0]
        || 0 != buff[1]
        || 1 != buff[2])
    {
        return false;
    }
    else
    {
        return true;
    }
}

#pragma mark -- 查找起始码 2：0x00000001
bool H264Parser::FindStartCode2 (unsigned char* buff)
{
    // 起始码2：0x00000001
    if (0 != buff[0]
        || 0 != buff[1]
        || 0 != buff[2]
        || 1 != buff[3])
    {
        return false;
    }
    else
    {
        return true;
    }
}

#pragma mark -- 提取裸 H264（annexb 封装格式）的 NALU
int H264Parser::ExtractAnnexbNalu()
{
    memset(m_nalu->data, 0, m_maxBuffSize);
    memset(m_parseNaluBuf, 0, m_maxBuffSize);
    int pos = 0;
    int nextStartCodeFound; // 下一个起始码是否找到
    int rewind; // 起始码的距离
    
    m_nalu->startCodeLen = 3;
    size_t readLen = fread (m_parseNaluBuf, 1, 3, m_fpH264);  // 读取 3 Byte 分析起始码1：0x000001
    if (3 != readLen)   // 数据不足 3 Byte
    {
        return 0;
    }
    m_isStartCode1 = FindStartCode1(m_parseNaluBuf);
    if(false == m_isStartCode1) // 不是起始码1：0x000001
    {
        readLen = fread(m_parseNaluBuf + 3, 1, 1, m_fpH264);  // 在多读取 1 Byte 分析 起始码2：0x00000001
        if(1 != readLen)    // 数据不足 1 Byte
        {
            return 0;
        }
        m_isStartCode2 = FindStartCode2(m_parseNaluBuf);
        if (false == m_isStartCode2)    // 不是起始码2：0x00000001
        {
            return -1;
        }
        else    // 属于起始码2：0x00000001
        {
            pos = 4;
            m_nalu->startCodeLen = 4;
        }
    }
    else    // 属于起始码1：0x000001
    {
        pos = 3;
        m_nalu->startCodeLen = 3;
    }
    
    nextStartCodeFound = 0;
    m_isStartCode1 = false;
    m_isStartCode2 = false;
    
    // 寻找下一个 起始码（0x000001 或 0x00000001）
    while (!nextStartCodeFound) // 循环查找下一起始码
    {
        if (feof(m_fpH264))   // 文件末尾
        {
            m_nalu->len = (pos - 1) - m_nalu->startCodeLen;
            memcpy(m_nalu->data, &m_parseNaluBuf[m_nalu->startCodeLen], m_nalu->len);
            /*
             NALU （首字节）
             +-------------------------------------+
             | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | ... |
             +-------------------------------------+
             0 ： 禁止位（值为 1 表示语法出错）
             1~2：NALU 参考级别
             3~7：NALU 类型
             
             */
            m_nalu->forbidden = (NaluForbiddenType) ((m_nalu->data[0] & 0x80)>>7);  // 高 1   bit
            m_nalu->level     = (NaluReferenceLevel)((m_nalu->data[0] & 0x60)>>5);  // 高 2~3 bit
            m_nalu->type      = (NaluType)           (m_nalu->data[0] & 0x1f);      // 低 5   bit
            return pos - 1;
        }
        m_parseNaluBuf[pos++] = fgetc(m_fpH264);     // 每次读取 1 Byte
        m_isStartCode2 = FindStartCode2(&m_parseNaluBuf[pos - 4]);  // 判断起始码2：0x00000001
        if(false == m_isStartCode2)  // 不是 起始码2：0x00000001
        {
            m_isStartCode1 = FindStartCode1(&m_parseNaluBuf[pos - 3]); // 判断起始码1：0x000001
        }
        nextStartCodeFound = (true == m_isStartCode1 || true == m_isStartCode2);
    }
    
    // 已找到下一个 起始码
    rewind = (true == m_isStartCode2) ? -4 : -3;
    
    if (0 != fseek(m_fpH264, rewind, SEEK_CUR))
    {
        printf("GetNextNalu: H264 文件 Seek 失败！");
        return -1;
    }
    
    // 至此，起始码，完整的 NALU，以及下一个起始码都已经读入了 buff 中，可以进行相关计算了
    m_nalu->len = (pos+rewind) - m_nalu->startCodeLen;  // NALU 长度
    memcpy(m_nalu->data, &m_parseNaluBuf[m_nalu->startCodeLen], m_nalu->len);    // 复制 NALU 数据
    /*
     NALU（首字节）
     +-------------------------------------+
     | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | ... |
     +-------------------------------------+
     0 ： 禁止位（值为 1 表示语法出错）
     1~2：NAL 参考级别
     3~7：NALU 类型
     
     */
    m_nalu->forbidden = (NaluForbiddenType) ((m_nalu->data[0] & 0x80)>>7);  // 高 1   bit
    m_nalu->level     = (NaluReferenceLevel)((m_nalu->data[0] & 0x60)>>5);  // 高 2~3 bit
    m_nalu->type      = (NaluType)           (m_nalu->data[0] & 0x1f);      // 低 5   bit
    
    return (pos+rewind);
}
