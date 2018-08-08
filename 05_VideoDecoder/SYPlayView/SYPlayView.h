//
//  SYPlayView.h
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

/*
 视频渲染类
 */

#import <UIKit/UIKit.h>
#import "SYFullScreenView.h"


/** 视频帧格式 枚举 */
typedef NS_ENUM(NSInteger, SYVideoFormat) {
    SYVideoUnknow               = -1,       // 未知格式
    SYVideoRgb565               = 0,        // RGB565 格式
    SYVideoRgb24                = 1,        // RGB24 格式
    SYVideoI420                 = 2,        // I420 格式
    SYVideoNv12                 = 3,        // NV12 格式
    SYVideoNv21                 = 4,        // NV21 格式
};


@interface SYPlayView : SYFullScreenView

/**
 初始化播放视图

 @param rect 视图 Rect
 @param vFormat 渲染的视频帧类型
 @param isRatio 是否按帧比例显示
 @return 播放视图实例
 */
- (instancetype)initWithRect:(CGRect)rect
                 videoFormat:(SYVideoFormat)vFormat
                 isRatioShow:(BOOL)isRatio;

/**
 渲染 视频 帧画面

 @param buffer 视频帧数据
 @param size 数据大小
 @param width 视频帧宽度
 @param height 视频帧高度
 */
- (void)renderData:(unsigned char*)buffer
              size:(unsigned int)size
             width:(unsigned int)width
            height:(unsigned int)height;

/**
 设置是否开启捏合缩放功能（default is NO）
 
 @param enable 是否开启；YES：开启，NO：关闭
 */
- (void)enableScale:(BOOL)enable;

/**
 设置捏合缩放比例大小（开启时可用）
 
 @param maxScale 最大缩放
 @param minScale 最小缩放
 */
- (void)setupMaxScale:(CGFloat)maxScale
             minScale:(CGFloat)minScale;

@end
