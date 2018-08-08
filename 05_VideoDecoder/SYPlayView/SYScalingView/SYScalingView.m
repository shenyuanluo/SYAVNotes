//
//  SYScalingView.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/3/15.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import "SYScalingView.h"

@implementation SYScalingView

#pragma mark -- 等比例缩放子视图以适应父视图展示
+ (CGRect)scaleWithSubSize:(CGSize)subSize
              inParentSize:(CGSize)parentSize
{
    CGRect resultRect = CGRectMake(0, 0, 0, 0);
    
    if (0 == subSize.width || 0 == subSize.height)
    {
        return resultRect;
    }
    CGFloat pDivisor = parentSize.width / parentSize.height;    // 父视图比例因子（宽/高）
    CGFloat sDivisor = subSize.width / subSize.height;          // 子视图比例因子（宽/高）
    
    CGFloat resultH;
    CGFloat resultW;
    CGPoint originP;
    
    if (sDivisor < pDivisor )        // 等高缩放
    {
        resultH = parentSize.height;
        resultW = resultH * sDivisor;
    }
    else if ( sDivisor > pDivisor)   // 等宽缩放
    {
        resultW = parentSize.width;
        resultH = resultW / sDivisor;
    }    
    else    // 等比例缩放
    {
        resultW = parentSize.width;
        resultH = parentSize.height;
    }
    // 起点位置
    originP.x  = (parentSize.width - resultW) / 2.0f;
    originP.y  = (parentSize.height - resultH) / 2.0f; ;
    resultRect = CGRectMake(originP.x, originP.y, resultW, resultH);
    
    return resultRect;
}

@end
