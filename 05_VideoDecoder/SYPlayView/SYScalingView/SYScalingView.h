//
//  SYScalingView.h
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/3/15.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SYScalingView : NSObject

/**
 等比例缩放子视图以适应父视图展示
 
 @param subSize 子视图原始 size
 @param parentSize 父视图原始 size
 @return 等比例缩放后 frame
 */
+ (CGRect)scaleWithSubSize:(CGSize)subSize
              inParentSize:(CGSize)parentSize;

@end
