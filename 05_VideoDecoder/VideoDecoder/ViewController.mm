//
//  ViewController.m
//  VideoDecoder
//
//  Created by shenyuanluo on 2018/8/1.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import "ViewController.h"
#import "VideoDecoder.h"
#import "SYPlayView.h"


static ViewController *cSelf =nil;
@interface ViewController ()
{
    dispatch_queue_t m_decodeQueue;
}
@property (nonatomic, strong) SYPlayView *playView;

@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    cSelf = self;
    
    m_decodeQueue = dispatch_queue_create("DecodeQueue", DISPATCH_QUEUE_SERIAL);
    
    [self setupPlayView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(m_decodeQueue, ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        [strongSelf decodeH264File];
    });
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -- 解码 H264 文件
- (void)decodeH264File
{
    NSString *h264FilePath = [[NSBundle mainBundle] pathForResource:@"XinWenLianBo_480x360"
                                                             ofType:@"h264"];
    VideoDocoder decoder;
    decoder.setDecodeDataCB((DecDataCallBack)DecodeDataCB);
    decoder.DecodeFile(h264FilePath.UTF8String, DecData_yuv420p);
}

#pragma mark -- 设置播放视图
- (BOOL)setupPlayView
{
    CGFloat scrHeight   = [[UIScreen mainScreen] bounds].size.height;
    CGFloat playViewW   = [[UIScreen mainScreen] bounds].size.width;
    CGFloat radio       = (CGFloat)(4.0f / 3.0f);
    CGFloat playViewH   = playViewW / radio;
    CGFloat orignY      = 812 == scrHeight ? 84 : 64;
    CGRect playViewRect = CGRectMake(0, orignY, playViewW, playViewH);
    self.playView       = [[SYPlayView alloc] initWithRect:playViewRect
                                               videoFormat:SYVideoI420
                                               isRatioShow:YES];
    if (!self.playView)
    {
        NSLog(@"Init playview failure!");
        return NO;
    }
    self.playView.backgroundColor = [UIColor lightGrayColor];
    [self.playView enableScale:YES];
    [self.playView setupMaxScale:4 minScale:1];
    [self.view addSubview:self.playView];
    return YES;
}

#pragma mark -- 解码数据回调
void DecodeDataCB(DecDataFormat fmt, unsigned char* buff, unsigned int size, unsigned int width, unsigned int height)
{
    [cSelf.playView renderData:buff
                          size:size
                         width:width
                        height:height];
}


- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


@end
