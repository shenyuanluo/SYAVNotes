//
//  main.cpp
//  AACParser
//
//  Created by shenyuanluo on 2018/7/23.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#include <iostream>
#include "AACParser.h"



int main(int argc, const char * argv[])
{
    AACParser parser;
    parser.parseAACFile("XinWenLianBo.aac");
    
    return 0;
}
