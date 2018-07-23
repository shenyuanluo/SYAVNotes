//
//  H264Parser.h
//  H264Parser
//
//  Created by shenyuanluo on 2018/7/21.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#ifndef H264Parser_h
#define H264Parser_h

#include <iostream>


/* Nal 单元禁止类型（1 Bit） */
typedef enum __nalUnitForbiddenType {
    Forbidden_legal     = 0,    // 合法
    Forbidden_illegal   = 1,    // 不合法（语法出错）
}NaluForbiddenType;

/* Nal 单元类型（5 Bit） */
typedef enum __nalUnitType {
    Nalu_unknow         = 0,    // 未使用
    Nalu_slice          = 1,    // 不分区，非 IDR 图像的片
    Nalu_dpa            = 2,    // 片分区 A
    Nalu_dpb            = 3,    // 片分区 B
    Nalu_dpc            = 4,    // 片分区 C
    Nalu_idr            = 5,    // IDR 图像的片（I 帧）
    Nalu_sei            = 6,    // 补充增强信息单元（SEI）
    Nalu_sps            = 7,    // 序列参数集（Sequence Parameter Set）
    Nalu_pps            = 8,    // 图像参数集（Picture Parameter Set）
    Nalu_aud            = 9,    // 分界符
    Nalu_eoseq          = 10,   // 序列结束
    Nalu_eostream       = 11,   // 码流结束
    Nalu_fill           = 12,   // 填充
    // 13~23：保留    24~31 未使用
}NaluType;

/* Nal 单元参考级别（2 Bit） */
typedef enum __nalUnitReferenceLevel {
    Reference_disposable    = 0,    // 可以任意处理
    Reference_low           = 1,    // 低
    Reference_middle        = 2,    // 中
    Reference_high          = 3,    // 高
}NaluReferenceLevel;

/* Nal 单元结构体 */
typedef struct __nalUnit
{
    unsigned int startCodeLen;      // NALU 起始码长度（4：参数集和第一个 slice 在图像内；3：其他）
    unsigned int len;               // NALU 长度（除去起始码，起始码不属于 NALU）
    NaluForbiddenType forbidden;    // 禁止位（值为 1 表示语法出错）
    NaluReferenceLevel level;       // NALU 参考级别
    NaluType type;                  // NALU 类型
    char *data;                     // NALU 数据（不包括起始码）
}NalUnit;


class H264Parser
{
private:
    FILE*          m_fpH264;            // h264 码流文件句柄
    NalUnit*       m_nalu;              // NAL 单元
    bool           m_isStartCode1;      // 是否是起始码 1：0x000001
    bool           m_isStartCode2;      // 是否是起始码 2：0x00000001
    unsigned char* m_parseNaluBuf;      // 解析 NALU 缓冲
    unsigned int   m_naluSize;          // NALU 结构体长度
    unsigned int   m_maxBuffSize;       // 最大缓冲区大小
    
    
    /**
     查找起始码 1：0x000001

     @param buff h264 数据缓冲
     @return 是否存在起始码 1
     */
    bool FindStartCode1(unsigned char* buff);
    
    /**
     查找起始码 2：0x00000001
     
     @param buff h264 数据缓冲
     @return 是否存在起始码 2
     */
    bool FindStartCode2 (unsigned char* buff);
    
    /**
     提取裸 H264（annexb 封装格式）的 NALU

     @return 解析成功：起始码长度+NALU长度； 解析失败：0； 解析出错：-1
     */
    int ExtractAnnexbNalu();
    
    
public:
    H264Parser();
    
    ~H264Parser();
    
    /**
     解析 H264 码流文件

     @param filePath 文件路径
     @return 是否解析成功
     */
    bool parseH264File(const char* filePath);
};

#endif /* H264Parser_h */
