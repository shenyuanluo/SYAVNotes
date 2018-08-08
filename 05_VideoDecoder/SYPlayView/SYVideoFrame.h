//
//  SYVideoFrame.h
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

/*
 视频数据模型类
 */

#import <Foundation/Foundation.h>


@interface SYVideoFrame : NSObject

/** 视频帧 宽度 */
@property (nonatomic, assign, readwrite) NSUInteger width;
/** 视频帧 高度 */
@property (nonatomic, assign, readwrite) NSUInteger height;
/** 视频帧数据大小 */
@property (readwrite, nonatomic) NSUInteger size;

@end


#pragma mark - YUV
@interface SYVideoFrameYUV : SYVideoFrame

/** 视频帧 亮度数据（Y分量) */
@property (nonatomic, strong, readwrite) NSData *luma;
/** 视频帧 色度数据（U分量) */
@property (nonatomic, strong, readwrite) NSData *chromaB;
/** 视频帧 色度数据（V分量) */
@property (nonatomic, strong, readwrite) NSData *chromaR;

@end


#pragma mark -- YUV:I420
@interface SYVideoFrameI420 : SYVideoFrameYUV

/**
 I420 内存分布
                   W
         +--------------------+
         |Y0Y1Y2Y3...         |
         |...                 |
         |                    |   H
         |                    |
         |                    |
         |                    |
         +--------------------+
         |U0U1...   |
         |...       |   H/2
         |          |
         +----------+
         |V0V1...   |
         |...       |  H/2
         |          |
         +----------+
             w/2
*/

/**
 初始化 I420 帧

 @param buffer 数据缓冲
 @param buffLen 数据长度
 @param frameW 帧宽度
 @param frameH 帧高度
 @return I420 帧
 */
- (instancetype)initWithBuffer:(unsigned char*)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH;


@end


#pragma mark -- YUV:NV12
@interface SYVideoFrameNV12 : SYVideoFrameYUV

/**
 NV12 内存分布
                    W
         +--------------------+
         |Y0Y1Y2Y3...         |
         |...                 |
         |                    |
         |                    |   H
         |                    |
         |                    |
         +--------------------+
         |U0V0U1V1...         |
         |...                 |   H/2
         |                    |
         +--------------------+
 */

/**
 初始化 NV12 帧
 
 @param buffer 数据缓冲
 @param buffLen 数据长度
 @param frameW 帧宽度
 @param frameH 帧高度
 @return I420 帧
 */
- (instancetype)initWithBuffer:(unsigned char*)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH;


@end


#pragma mark -- YUV:NV21
@interface SYVideoFrameNV21 : SYVideoFrameYUV

/**
 NV12 内存分布
                   W
         +--------------------+
         |Y0Y1Y2Y3...         |
         |...                 |
         |                    |
         |                    |   H
         |                    |
         |                    |
         +--------------------+
         |V0U0V1U1...         |
         |...                 |   H/2
         |                    |
         +--------------------+
 */

/**
 初始化 NV21 帧
 
 @param buffer 数据缓冲
 @param buffLen 数据长度
 @param frameW 帧宽度
 @param frameH 帧高度
 @return I420 帧
 */
- (instancetype)initWithBuffer:(unsigned char*)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH;


@end



#pragma mark - RGB
@interface SYVideoFrameRGB : SYVideoFrame

/** 视频帧 R 数据 */
@property (readwrite, nonatomic, strong) NSData *red;
/** 视频帧 G 数据 */
@property (readwrite, nonatomic, strong) NSData *green;
/** 视频帧 B 数据 */
@property (readwrite, nonatomic, strong) NSData *blue;

@end


#pragma mark -- RGB565
@interface SYVideoFrameRGB565 : SYVideoFrameRGB

/**
 初始化 RGB24 帧
 
 @param buffer 数据缓冲
 @param buffLen 数据长度
 @param frameW 帧宽度
 @param frameH 帧高度
 @return RGB24 帧
 */
- (instancetype)initWithBuffer:(unsigned char*)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH;

@end


#pragma mark - RGB24
@interface SYVideoFrameRGB24 : SYVideoFrameRGB

/**
 初始化 RGB24 帧

 @param buffer 数据缓冲
 @param buffLen 数据长度
 @param frameW 帧宽度
 @param frameH 帧高度
 @return RGB24 帧
 */
- (instancetype)initWithBuffer:(unsigned char*)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH;

@end

