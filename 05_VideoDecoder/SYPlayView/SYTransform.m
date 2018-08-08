//
//  SYTransform.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import "SYTransform.h"


@interface SYTransform()

@property (nonatomic, assign) GLKMatrix4 transformMat;

@end

@implementation SYTransform

- (instancetype)init
{
    if (self = [super init])
    {
        self.transformMat = GLKMatrix4Identity;
    }
    return self;
}

#pragma mark -- 平移（矩阵）操作
- (void)translateX:(GLfloat)x Y:(GLfloat)y Z:(GLfloat)z
{
    self.transformMat = GLKMatrix4Translate(self.transformMat, x, y, z);
}

- (void)translate:(GLKVector3)transVec3
{
    self.transformMat = GLKMatrix4TranslateWithVector3(self.transformMat, transVec3);
}

#pragma mark -- 旋转（矩阵）操作
- (void)rotateAngle:(GLfloat)angle X:(GLfloat)x Y:(GLfloat)y Z:(GLfloat)z
{
    self.transformMat = GLKMatrix4Rotate(self.transformMat, angle, x, y, z);
}

- (void)rotateAngle:(GLfloat)angle vector3:(GLKVector3)rotateVec
{
    self.transformMat = GLKMatrix4RotateWithVector3(self.transformMat, angle, rotateVec);
}

#pragma mark -- 缩放（矩阵）操作
- (void)scaleX:(GLfloat)x Y:(GLfloat)y Z:(GLfloat)z
{
    self.transformMat = GLKMatrix4Scale(self.transformMat, x, y, z);
}

- (void)scale:(GLKVector3)scaleVec
{
    self.transformMat = GLKMatrix4ScaleWithVector3(self.transformMat, scaleVec);
}

#pragma mark -- ’逆矩阵‘操作
- (void)inverse
{
    self.transformMat = GLKMatrix4Invert(self.transformMat, nil);
}

#pragma mark -- ’转置矩阵‘操作
- (void)transpose
{
    self.transformMat = GLKMatrix4Transpose(self.transformMat);
}

#pragma mark -- 创建（透视）投影矩阵
- (void)perspective:(GLfloat)angle
              width:(GLfloat)width
             height:(GLfloat)height
          nearPlane:(GLfloat)nearPlane
           farPlane:(GLfloat)farPlane
{
    self.transformMat = GLKMatrix4MakePerspective(angle, width/height, nearPlane, farPlane);
}

#pragma mark -- 创建（正射）投影矩阵
- (void)orthoWithLeft:(GLfloat)left
                right:(GLfloat)right
                  top:(GLfloat)top
               bottom:(GLfloat)bottom
            nearPlane:(GLfloat)nearPlane
             farPlane:(GLfloat)farPlane
{
    self.transformMat = GLKMatrix4MakeOrtho(left, right, bottom, top, nearPlane, farPlane);
}

#pragma mark -- 角度制转弧度制
- (GLfloat)radianWithDegree:(GLfloat)degree
{
    return GLKMathDegreesToRadians(degree);
}

#pragma mark -- 弧度制角弧度制
- (GLfloat)degreeWithRadian:(GLfloat)radian
{
    return GLKMathRadiansToDegrees(radian);
}

#pragma mark -- 使用变换矩阵
- (GLKMatrix4)use
{
    return self.transformMat;
}

#pragma mark -- 重置为单位矩阵
- (void)reset
{
    self.transformMat = GLKMatrix4Identity;
}

@end
