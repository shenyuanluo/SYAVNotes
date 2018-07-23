//
//  main.cpp
//  H264Parser
//
//  Created by shenyuanluo on 2018/7/21.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#include <iostream>
#include "H264Parser.h"

int main(int argc, const char * argv[])
{
    H264Parser h264Parser;
    h264Parser.parseH264File("XinWenLianBo_480x360.h264");
    
    return 0;
}
