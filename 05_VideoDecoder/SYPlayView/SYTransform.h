//
//  SYTransform.h
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

/*
 矩阵变换操作类
 */

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <GLKit/GLKit.h>


@interface SYTransform : NSObject

#pragma mark - 平移
/**
 平移（矩阵）操作
 
 @param x 平移向量 x 坐标
 @param y 平移向量 y 坐标
 @param z 平移向量 z 坐标
 */
- (void)translateX:(GLfloat)x Y:(GLfloat)y Z:(GLfloat)z;

/**
 平移（矩阵）操作
 
 @param transVec3 平移向量
 */
- (void)translate:(GLKVector3)transVec3;

#pragma mark - 选择
/**
 旋转（矩阵）操作
 
 @param angle 旋转角度（弧度）
 @param x 旋转向量 x 坐标
 @param y 旋转向量 y 坐标
 @param z 旋转向量 z 坐标
 */
- (void)rotateAngle:(GLfloat)angle X:(GLfloat)x Y:(GLfloat)y Z:(GLfloat)z;

/**
 旋转（矩阵）操作
 
 @param angle 旋转角度（弧度）
 @param rotateVec 旋转向量
 */
- (void)rotateAngle:(GLfloat)angle vector3:(GLKVector3)rotateVec;

#pragma mark - 缩放
/**
 缩放（矩阵）操作
 
 @param x 缩放向量 x 坐标
 @param y 缩放向量 y 坐标
 @param z 缩放向量 z 坐标
 */
- (void)scaleX:(GLfloat)x Y:(GLfloat)y Z:(GLfloat)z;

/**
 缩放（矩阵）操作
 
 @param scaleVec 缩放向量
 */
- (void)scale:(GLKVector3)scaleVec;

#pragma mark - 转置、逆
/**
 ‘逆矩阵’操作
 */
- (void)inverse;

/**
 ’转置矩阵‘操作
 */
- (void)transpose;

#pragma mark - 投影
/**
 创建（透视）投影矩阵
 
 @param angle （平截头体）视野（FOV：Field of View）角度（弧度）
 @param width 视口（Viewport）宽度
 @param height 视口（Viewport）高度
 @param nearPlane （平截头体）近平面距离
 @param farPlane （平截头体）远平面距离
 */
- (void)perspective:(GLfloat)angle
              width:(GLfloat)width
             height:(GLfloat)height
          nearPlane:(GLfloat)nearPlane
           farPlane:(GLfloat)farPlane;

/**
 创建（正射）投影矩阵
 
 @param left （平截头体）左坐标
 @param right （平截头体）右坐标
 @param top （平截头体）上坐标
 @param bottom （平截头体）下坐标
 @param nearPlane （平截头体）近平面距离
 @param farPlane （平截头体）远平面距离
 */
- (void)orthoWithLeft:(GLfloat)left
                right:(GLfloat)right
                  top:(GLfloat)top
               bottom:(GLfloat)bottom
            nearPlane:(GLfloat)nearPlane
             farPlane:(GLfloat)farPlane;

#pragma mark - 角度转换
/**
 角度制转弧度制
 
 @param degree 角度制度数
 @return 弧度制度数
 */
- (GLfloat)radianWithDegree:(GLfloat)degree;

/**
 弧度制转角度制
 
 @param radian 弧度制度数
 @return 弧度制度数
 */
- (GLfloat)degreeWithRadian:(GLfloat)radian;

#pragma mark - 使用
/**
 使用变换矩阵
 
 @return （组合）变换矩阵数据
 */
- (GLKMatrix4)use;

/**
 重置为单位矩阵
 */
- (void)reset;

@end
