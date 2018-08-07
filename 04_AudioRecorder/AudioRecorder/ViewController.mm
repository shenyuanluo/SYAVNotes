//
//  ViewController.m
//  AudioRecorder
//
//  Created by shenyuanluo on 2018/7/25.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "Mp3Encoder.h"


#define MP3_FOLDER_NAME     @"MP3Files"     // MP3 文件保存目录
#define PCM_FILE_ANME       @"Record.wav"   // PCM 文件名

#define SAMPLE_RATE     44100   // 采样率
#define CHANNELS_NUM    2       // 声道数
#define BIT_PER_SAMPLE  16      // 位深


@interface ViewController () <
                                AVAudioRecorderDelegate
                             >
{
    dispatch_queue_t m_mp3EncodeQueue;  // 编码 MP3 串行队列
    Mp3Encoder m_mp3Encode;
    BOOL m_isInitEncoder;
}

@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (nonatomic, readwrite, strong) AVAudioRecorder *audioRecorder;    // 录音器
@property (nonatomic, readwrite, strong) NSDictionary *audioSetting;    // 录音器配置
@property (nonatomic, readwrite, strong) NSTimer *recordTimer;  // 录像计时器
@property (nonatomic, readwrite, assign) NSInteger recDuration; // 录像时长
@property (nonatomic, readwrite, copy) NSString *mp3FolderPath; // 保存 MP3 文件目录
@property (nonatomic, readwrite, copy) NSString *pcmFilePath;   // pcm(wav) 文件路径

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    m_mp3EncodeQueue = dispatch_queue_create("Mp3EncodeQueue", DISPATCH_QUEUE_SERIAL);
    m_isInitEncoder  = NO;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -- 移除 PCM 文件
- (void)removePcmFile
{
    if (!self.pcmFilePath)
    {
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir   = NO;
    BOOL isExist = [fileManager fileExistsAtPath:self.pcmFilePath
                                     isDirectory:&isDir];
    if (NO == isExist || YES == isDir)   // PCM 文件不存在
    {
        return;
    }
    NSError *error;
    BOOL isRemove = [fileManager removeItemAtPath:self.pcmFilePath
                                            error:&error];
    if (NO == isRemove)
    {
        NSLog(@"移除 PCM 文件失败：%@", error.localizedDescription);
    }
}

#pragma mark -- 获取 MP3 文件路径
- (NSString *)curtMp3FilePath
{
    NSString *mp3FileName = [NSString stringWithFormat:@"%@.mp3", [self curTimeStr]];
    
    return [self.mp3FolderPath stringByAppendingPathComponent:mp3FileName];
}

#pragma mark -- 获取当前时间字符串：YYYYMMddHHmmss
- (NSString*)curTimeStr
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMddHHmmss"];
    NSDate *datenow = [NSDate date];
    NSString *timeStr = [formatter stringFromDate:datenow];
    return timeStr;
}

#pragma mark - 录音操作
#pragma mark -- 录像按钮事件
- (IBAction)recordBtnAction:(id)sender
{
    BOOL isSelect = self.recordBtn.selected;
    self.recordBtn.selected = !isSelect;
    
    if (NO == isSelect) // 开始录音
    {
        self.recDuration = 0;
        [self resumeTimer];
        
        [self startAudioRecord];
        
        [self.recordBtn setTitle:@"结束录音"
                        forState:UIControlStateNormal];
    }
    else    // 结束录音
    {
        [self pauseTimer];
        
        [self stopAudioRecord];
        
        [self.recordBtn setTitle:@"开始录音"
                        forState:UIControlStateNormal];
    }
}


#pragma mark - 计时器
#pragma mark -- 开始/恢复计时器
- (void)resumeTimer
{
    if (!self.recordTimer.isValid)
    {
        return;
    }
    [self.recordTimer setFireDate:[NSDate date]];
}

#pragma mark -- 暂停计时器
- (void)pauseTimer
{
    if (!self.recordTimer.isValid)
    {
        return;
    }
    [self.recordTimer setFireDate:[NSDate distantFuture]];
}

#pragma mark -- 停止计时器
- (void)stopTimer
{
    if (self.recordTimer)
    {
        [self.recordTimer invalidate];
        self.recordTimer = nil;
    }
}

#pragma mark -- 更新录音时长
- (void)updateTimeStr
{
    self.recDuration++;
    NSInteger hours   = self.recDuration / 3600;
    NSInteger minutes = (self.recDuration / 60) % 60;
    NSInteger seconds = self.recDuration % 60;
    
    NSString *timeStr = nil;
    if (0 >= hours)
    {
        timeStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
    }
    else
    {
        timeStr = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",(long)hours, (long)minutes, (long)seconds];
    }
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        strongSelf.durationLabel.text = timeStr;
    });
}


#pragma mark -- 开始录音
- (void)startAudioRecord
{
    [self removePcmFile];
    
    if (YES == [self.audioRecorder isRecording])
    {
        NSLog(@"正在录音，请稍后。。。");
        return;
    }
    // 开启会话
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    BOOL ret = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                              error:&error];
    if(NO == ret)
    {
        NSLog(@"设置 AVAudioSession 失败: %@", error.localizedDescription);
        return;
    }
    else
    {
        ret = [session setActive:YES error:&error];  // 激活 AVAudioSession
        if (NO == ret)
        {
            NSLog(@"激活 AVAudioSession 失败：%@", error.localizedDescription);
            return;
        }
    }

    m_isInitEncoder = NO;
    [self.audioRecorder record];    // 开始录音
    
    NSString *mp3Path = [self curtMp3FilePath];
    
    // 同步转码
    __weak typeof(self)weakSelf = self;
    dispatch_async(m_mp3EncodeQueue, ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        if (NO == strongSelf->m_isInitEncoder)
        {
            strongSelf->m_mp3Encode.InitParam([strongSelf.pcmFilePath cStringUsingEncoding:NSUTF8StringEncoding], [mp3Path cStringUsingEncoding:NSUTF8StringEncoding], SAMPLE_RATE, CHANNELS_NUM, BIT_PER_SAMPLE);
            strongSelf->m_mp3Encode.SetRecordingFlag(true);
            strongSelf->m_mp3Encode.StartEncode();
        }
        strongSelf->m_isInitEncoder = YES;
    });
}


#pragma mark -- 停止录音
- (void)stopAudioRecord
{
    if (NO == [self.audioRecorder isRecording])
    {
        NSLog(@"没有录音，无法执行停止录音操作！");
        return;
    }
    [self.audioRecorder stop];
    m_mp3Encode.SetRecordingFlag(false);
}

#pragma mark - 懒加载
#pragma mark -- 录音器
- (AVAudioRecorder *)audioRecorder
{
    if (!_audioRecorder)
    {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error;
        BOOL ret = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                                  error:&error];
        if(NO == ret)
        {
            NSLog(@"设置 AVAudioSession 失败: %@", error.localizedDescription);
        }
        else
        {
            ret = [session setActive:YES error:&error];  // 激活 AVAudioSession
            if (NO == ret)
            {
                NSLog(@"AVAudioSession 激活失败：%@", error.localizedDescription);
            }
        }
        
        // 创建录音文件保存路径
        NSURL *url = [NSURL fileURLWithPath:self.pcmFilePath];
        // 创建录音参数
        _audioRecorder = [[AVAudioRecorder alloc] initWithURL:url
                                                     settings:self.audioSetting
                                                        error:&error];
        _audioRecorder.delegate        = self;
        _audioRecorder.meteringEnabled = YES;
        [_audioRecorder prepareToRecord];   // 准备录音
        if (error)
        {
            NSLog(@"创建 AVAudioRecorder 失败：%@",error.localizedDescription);
            _audioRecorder = nil;
        }
    }
    return _audioRecorder;
}

#pragma mark -- 录音器配置
- (NSDictionary *)audioSetting
{
    if (!_audioSetting)
    {
        _audioSetting = @{
                          AVFormatIDKey            : @(kAudioFormatLinearPCM),  // 音频格式
                          AVSampleRateKey          : @(SAMPLE_RATE),            // 采样率
                          AVNumberOfChannelsKey    : @(CHANNELS_NUM),           // 声道数
                          AVLinearPCMBitDepthKey   : @(BIT_PER_SAMPLE),         // 位深
                          AVEncoderAudioQualityKey : @(AVAudioQualityMax)       // 质量
                          };
    }
    return _audioSetting;
}

#pragma mark -- 录音计时器
- (NSTimer *)recordTimer
{
    if (!_recordTimer)
    {
        _recordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                        target:self
                                                      selector:@selector(updateTimeStr)
                                                      userInfo:nil
                                                       repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_recordTimer
                                  forMode:NSDefaultRunLoopMode];
    }
    return _recordTimer;
}

#pragma mark -- MP3 文件保存目录
- (NSString *)mp3FolderPath
{
    if (!_mp3FolderPath)
    {
        NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                 NSUserDomainMask,
                                                                 YES)lastObject];
        NSString *folderPath = [docPath stringByAppendingPathComponent:MP3_FOLDER_NAME];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir   = NO;
        BOOL isExist = [fileManager fileExistsAtPath:folderPath
                                         isDirectory:&isDir];
        if (YES == isExist && YES == isDir) // 文件夹已存在，无需创建
        {
            _mp3FolderPath = folderPath;
        }
        else    // 目录不存在，则新建
        {
            BOOL isCreate = [fileManager createDirectoryAtPath:folderPath
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:nil];
            if (NO == isCreate) // 创建失败
            {
                NSLog(@"创建 MP3 目录失败！");
                _mp3FolderPath = nil;
            }
            else    // 创建成功
            {
                NSLog(@"创建 MP3 目录成功！");
                _mp3FolderPath = folderPath;
            }
        }
    }
    return _mp3FolderPath;
}

#pragma mark -- PCM 文件路径
- (NSString *)pcmFilePath
{
    if (!_pcmFilePath)
    {
        _pcmFilePath = [self.mp3FolderPath stringByAppendingPathComponent:PCM_FILE_ANME];
    }
    return _pcmFilePath;
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder
                           successfully:(BOOL)flag
{
    if (NO == flag)
    {
        NSLog(@"PCM 录制失败！");
    }
    else
    {
        NSLog(@"PCM 录制成功！");
    }
}



@end
