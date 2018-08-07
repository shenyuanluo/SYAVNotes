//
//  main.cpp
//  Mp3Encoder
//
//  Created by shenyuanluo on 2018/7/24.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#include <iostream>
#include "Mp3Encoder.h"


#define SAMPLE_RATE 44100   // 比特率（单位：Hz)
#define BIT_PER_SAMPLE 16   // 通道数（量化格式或位深）
#define NUM_CHANNELs 2      // 声道数
#define BIT_RATE 1411200    // 码率（= SAMPLE_RATE × BIT_PER_SAMPLE × NUM_CHANNELs）


int main(int argc, const char * argv[])
{
    Mp3Encoder encoder;
    bool ret = encoder.InitParam("XinWenLianBo.wav", "XinWenLianBo.mp3", SAMPLE_RATE, NUM_CHANNELs, BIT_RATE);
    if (ret)
    {
        encoder.StartEncode();
    }
    
    return 0;
}
