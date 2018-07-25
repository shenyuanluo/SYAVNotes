# `H264` 简介
> `H.264`，又称为 `MPEG-4` 第10部分，高级视频编码（英语：MPEG-4 Part 10, Advanced Video Coding，缩写为 `MPEG-4 AVC`）是一种面向块，基于 **运动补偿** 的视频编码标准（可以被视为由多个不同的应用框架 / 配置文件（`profiles`）组成的“标准系列”）。

## 视频的编码方式
> **视频编码：** 其本质就是将数据压缩，主要是去除冗余信息（包括 **空间** 上的冗余信息和 **时间** 上的冗余信息），从而实现数据量的压缩。
 
1. **空间冗余：** 在同一图像（帧）内，相近像素之间的差别很小（甚至是相同的），所以就可以用一个特定大小的像素矩阵来表示相邻的像素。
2. **时间冗余：** 视频中连续的图像（帧）之间，其中发生变化的像素占整张图像像素的比例极其微小，所以就可以用其中一帧来表示相邻的帧来减少带宽消耗。
3. **编码冗余：** 不同像素出现的概率不同，所以就可以为出现概率高的像素分配尽量少的字节，对出现概率低的像素分配尽量多的字节。
4. **视觉冗余:** 人眼对很多像素颜色不敏感，所以就可以丢弃这些冗余的信息而并不影响人眼观看的效果。

### 帧间编码
> **帧间编码：** 可以去除 *时间* 上的冗余信息。

1. **运动补偿：** 通过先前的局部图像来预测、补偿当前的局部图像（是减少帧序列冗余信息的有效方法）。
2. **运动表示：** 不同区域的图像需要使用不同的运动矢量来描述运动信息。
3. **运动估计：** 从视频序列中抽取运动信息的一整套技术。

### 帧内编码
> **帧内编码：** 可以去除 *空间* 上的冗余信息。

### 帧类别
- **I 帧：**帧内编码帧（`intra picture`）可以去掉视频的空间的冗余信息；通常是每个 **GOP**（两个 `I` 帧之间形成的一组视频帧）的第一帧，经过适度地压缩，作为随机访问的参考点，可以当成静态图像。（压缩率：7） 
- **P 帧：** 向前预测编码帧（`predictive-frame`），通过将图像序列中前面已编码帧的时间冗余信息充分去除来压缩传输数据量的编码图像，也成为预测帧。（压缩率：20）
- **B 帧：** 双向预测内插编码帧（`bi-directional interpolated prediction frame`），既考虑原图像序列前面的已编码帧，又估计图像序列后面的已编码帧之间的时间冗余信息，来压缩传输数据量的编码图像，也成为双向预测帧。（压缩率：50）


## `H264` 码流结构
> 在 `H.264/AVC` 视频编码标准中，整个系统框架被分为了两个层面：
> 
> - **视频编码层面（VCL）：** 负责有效表示视频数据的内容
> - **网络抽象层面（NAL）：** 负责格式化数据并提供头信息，以保证数据适合各种信道和存储介质上的传输。
> 
> 因此平时的每帧数据就是一个 **NAL 单元（SPS 与 PPS 除外）** 。

**H.264** 原始码流（又称为“裸流”）是由一个一个的 `NALU` 组成的；其中每个 `NALU` 之间通过 `startcode`（起始码）进行分隔，起始码分成两种：**0x000001（3 Byte）** 或者  **0x00000001（4 Byte）**。

![NALU 结构](NALU.jpeg)

### NALU 结构
``` c
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
```

### NALU 禁止位类型
``` c
/* Nal 单元禁止类型（1 Bit） */
typedef enum __nalUnitForbiddenType {
    Forbidden_legal     = 0,    // 合法
    Forbidden_illegal   = 1,    // 不合法（语法出错）
}NaluForbiddenType;
```

### NALU 类型
``` c
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
```

### NALU 参考基本类型
``` c
/* Nal 单元参考级别（2 Bit） */
typedef enum __nalUnitReferenceLevel {
    Reference_disposable    = 0,    // 可以任意处理
    Reference_low           = 1,    // 低
    Reference_middle        = 2,    // 中
    Reference_high          = 3,    // 高
}NaluReferenceLevel;
```



# 参考
1. [H.264/MPEG-4 AVC](https://zh.wikipedia.org/wiki/H.264/MPEG-4_AVC)
2. [视音频数据处理入门：H.264视频码流解析](https://blog.csdn.net/leixiaohua1020/article/details/50534369)