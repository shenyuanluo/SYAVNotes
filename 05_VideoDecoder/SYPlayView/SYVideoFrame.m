//
//  SYVideoFrame.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import "SYVideoFrame.h"


typedef NS_ENUM(NSInteger, EndianType) {
    EndianLittle        = 0,        // 小端
    EndianBig           = 1,        // 大端
};


@implementation SYVideoFrame

#pragma mark -- 判断大小端
- (EndianType)checkEndian
{
    union {
        char c[4];
        unsigned int num;
    } endianUnion = {'l', '?', '?', 'b'};
    
    if ('l' == (char)endianUnion.num)   // 取首字节判断
    {
        return EndianLittle;
    }
    else // 'b' == (char)endianUnion.num
    {
        return EndianBig;
    }
}

@end


#pragma mark - YUV
@implementation SYVideoFrameYUV

@end


#pragma mark -- YUV:I420
@implementation SYVideoFrameI420

- (instancetype)initWithBuffer:(unsigned char*)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH
{
    if (self = [super init])
    {
        self.width     = frameW;
        self.height    = frameH;
        unsigned int frameSize = frameW * frameH;
        self.size      = frameSize * 1.5;
        if (buffLen != self.size)
        {
            NSLog(@"It's wrong with I420 data");
            return nil;
        }
        unsigned char* y = (unsigned char*)malloc(frameSize);
        unsigned char* u = (unsigned char*)malloc(frameSize * 0.25);
        unsigned char* v = (unsigned char*)malloc(frameSize * 0.25);
        if (NULL == y || NULL == u || NULL == v)
        {
            NSLog(@"Malloc buffer for I420 frame is failure!");
            return nil;
        }
        memset(y, 0, frameSize);
        memset(u, 0, frameSize * 0.25);
        memset(v, 0, frameSize * 0.25);
        
        memcpy(y, buffer, frameSize);
        memcpy(u, buffer + frameSize, frameSize * 0.25);
        memcpy(v, buffer + (int)(frameSize * 1.25), frameSize * 0.25);
        
        // yuv数据
        self.luma    = [NSData dataWithBytes:y length:frameSize];
        self.chromaB = [NSData dataWithBytes:u length:frameSize * 0.25];
        self.chromaR = [NSData dataWithBytes:v length:frameSize * 0.25];
        
        free(y);
        free(u);
        free(v);
        y = NULL;
        u = NULL;
        v = NULL;
    }
    return self;
}

@end


#pragma mark -- YUV:NV12
@implementation SYVideoFrameNV12

- (instancetype)initWithBuffer:(unsigned char*)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH
{
    if (self = [super init])
    {
        self.width     = frameW;
        self.height    = frameH;
        unsigned int frameSize = frameW * frameH;
        self.size      = frameSize * 1.5;
        if (buffLen != self.size)
        {
            NSLog(@"It's wrong with NV12 data");
            return nil;
        }
        unsigned char* yuv = (unsigned char*)malloc(self.size);
        unsigned char* y   = (unsigned char*)malloc(frameSize);
        unsigned char* u   = (unsigned char*)malloc(frameSize * 0.25);
        unsigned char* v   = (unsigned char*)malloc(frameSize * 0.25);
        if (NULL == yuv || NULL == y || NULL == u || NULL == v)
        {
            NSLog(@"Malloc buffer for NV12 frame is failure!");
            return nil;
        }
        memset(yuv, 0, self.size);
        memset(y, 0, frameSize);
        memset(u, 0, frameSize * 0.25);
        memset(v, 0, frameSize * 0.25);
        
        memcpy(yuv, buffer, buffLen);
        memmove(y, yuv, frameSize);
        
        unsigned int index = 0;
        for (int i = frameSize; i < self.size; i += 2)
        {
            memmove(u + index, yuv + i, 1);
            memmove(v + index, yuv + i + 1, 1);
            index++;
        }
        
        // yuv数据
        self.luma    = [NSData dataWithBytes:y length:frameSize];
        self.chromaB = [NSData dataWithBytes:u length:frameSize * 0.25];
        self.chromaR = [NSData dataWithBytes:v length:frameSize * 0.25];
        
        free(yuv);
        free(y);
        free(u);
        free(v);
        yuv = NULL;
        y   = NULL;
        u   = NULL;
        v   = NULL;
    }
    return self;
}

@end


#pragma mark -- YUV:NV21
@implementation SYVideoFrameNV21

- (instancetype)initWithBuffer:(unsigned char*)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH
{
    if (self = [super init])
    {
        self.width     = frameW;
        self.height    = frameH;
        unsigned int frameSize = frameW * frameH;
        self.size      = frameSize * 1.5;
        if (buffLen != self.size)
        {
            NSLog(@"It's wrong with NV12 data");
            return nil;
        }
        unsigned char* yuv = (unsigned char*)malloc(self.size);
        unsigned char* y   = (unsigned char*)malloc(frameSize);
        unsigned char* u   = (unsigned char*)malloc(frameSize * 0.25);
        unsigned char* v   = (unsigned char*)malloc(frameSize * 0.25);
        if (NULL == yuv || NULL == y || NULL == u || NULL == v)
        {
            NSLog(@"Malloc buffer for NV12 frame is failure!");
            return nil;
        }
        memset(yuv, 0, self.size);
        memset(y, 0, frameSize);
        memset(u, 0, frameSize * 0.25);
        memset(v, 0, frameSize * 0.25);
        
        memcpy(yuv, buffer, buffLen);
        memmove(y, yuv, frameSize);
        
        unsigned int index = 0;
        for (int i = frameSize; i < self.size; i += 2)
        {
            memmove(v + index, yuv + i, 1);
            memmove(u + index, yuv + i + 1, 1);
            index++;
        }
        
        // yuv数据
        self.luma    = [NSData dataWithBytes:y length:frameSize];
        self.chromaB = [NSData dataWithBytes:u length:frameSize * 0.25];
        self.chromaR = [NSData dataWithBytes:v length:frameSize * 0.25];
        
        free(yuv);
        free(y);
        free(u);
        free(v);
        yuv = NULL;
        y   = NULL;
        u   = NULL;
        v   = NULL;
    }
    return self;
}

@end


#pragma mark - RGB
@implementation SYVideoFrameRGB

@end


#pragma mark -- RGB565
@implementation SYVideoFrameRGB565
- (instancetype)initWithBuffer:(unsigned char *)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH
{
    if (self = [super init])
    {
        self.width    = frameW;
        self.height   = frameH;
        unsigned int frameSize = frameW * frameH;
        self.size     = frameSize * 3;
        if (buffLen != frameSize * 2)
        {
            NSLog(@"It's wrong with RGB565 data");
            return nil;
        }
        unsigned char* rgb = (unsigned char*)malloc(buffLen);
        unsigned char* r   = (unsigned char*)malloc(frameSize);
        unsigned char* g   = (unsigned char*)malloc(frameSize);
        unsigned char* b   = (unsigned char*)malloc(frameSize);
        if (NULL == rgb || NULL == r || NULL == g || NULL == b)
        {
            NSLog(@"Malloc buffer for RGB565 frame is failure!");
            return nil;
        }
        memset(rgb, 0, buffLen);
        memset(r, 0, frameSize);
        memset(g, 0, frameSize);
        memset(b, 0, frameSize);
        memcpy(rgb, buffer, buffLen);
        
        unsigned int index = 0;
        
        for (int i = 0; i < buffLen; i += 2)
        {
            unsigned short color;   // 每个像素点颜色值（注意大小端）
            switch ([self checkEndian])
            {
                case EndianLittle:  // 小端
                {
                    color = rgb[i] + (rgb[i + 1]<<8);   // 每次取 2 个字节
                }
                    break;
                    
                case EndianBig:     // 大端
                {
                    color = (rgb[i]<<8) + rgb[i + 1];   // 每次取 2 个字节
                }
                    break;
                    
                default:
                    break;
            }
            unsigned char R = (color & 0xF800) >> 8;// (获取高字节 5 个bit，作为 char 的高 5 位)
            unsigned char G = (color & 0x07E0) >> 3;// (获取中间的 6 个bit，作为 char 的高 6 位)
            unsigned char B = (color & 0x001F) << 3;// (获取低字节 5 个bit，作为 char 的高 5 位)
            
            r[index] = R;
            g[index] = G;
            b[index] = B;
            index++;
        }
        
        // rgb数据
        self.red   = [NSData dataWithBytes:r length:frameSize];
        self.green = [NSData dataWithBytes:g length:frameSize];
        self.blue  = [NSData dataWithBytes:b length:frameSize];
        
        free(rgb);
        free(r);
        free(g);
        free(b);
        rgb = NULL;
        r   = NULL;
        g   = NULL;
        b   = NULL;
    }
    return self;
}
@end


#pragma mark -- RGB24
@implementation SYVideoFrameRGB24

- (instancetype)initWithBuffer:(unsigned char*)buffer
                        length:(unsigned int)buffLen
                         width:(unsigned int)frameW
                        height:(unsigned int)frameH
{
    if (self = [super init])
    {
        self.width    = frameW;
        self.height   = frameH;
        unsigned int frameSize = frameW * frameH;
        self.size     = frameSize * 3;
        if (buffLen != self.size)
        {
            NSLog(@"It's wrong with RGB24 data");
            return nil;
        }
        unsigned char* rgb = (unsigned char*)malloc(self.size);
        unsigned char* r   = (unsigned char*)malloc(frameSize);
        unsigned char* g   = (unsigned char*)malloc(frameSize);
        unsigned char* b   = (unsigned char*)malloc(frameSize);
        if (NULL == rgb || NULL == r || NULL == g || NULL == b)
        {
            NSLog(@"Malloc buffer for RGB24 frame is failure!");
            return nil;
        }
        memset(rgb, 0, self.size);
        memset(r, 0, frameSize);
        memset(g, 0, frameSize);
        memset(b, 0, frameSize);
        memcpy(rgb, buffer, self.size);
        
        unsigned int index = 0;
        
        for (int i = 0; i < self.size; i += 3)
        {
            memmove(r + index, rgb + i + 0, 1);
            memmove(g + index, rgb + i + 1, 1);
            memmove(b + index, rgb + i + 2, 1);
            index++;
        }
        
        // rgb数据
        self.red   = [NSData dataWithBytes:r length:frameSize];
        self.green = [NSData dataWithBytes:g length:frameSize];
        self.blue  = [NSData dataWithBytes:b length:frameSize];
        
        free(rgb);
        free(r);
        free(g);
        free(b);
        rgb = NULL;
        r   = NULL;
        g   = NULL;
        b   = NULL;
    }
    return self;
}

@end
