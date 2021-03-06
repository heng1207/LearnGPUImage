//
//  WatermarkTextPictureVC.m
//  GPUImageDemo
//
//  Created by 恒 on 2017/12/12.
//  Copyright © 2017年 恒. All rights reserved.
//

#import "WatermarkTextPictureVC.h"
#import "GPUImage.h"
#import <AssetsLibrary/ALAssetsLibrary.h>



@interface WatermarkTextPictureVC ()
@property (nonatomic , strong) UILabel  *mLabel;

@end

@implementation WatermarkTextPictureVC
{
    GPUImageMovie *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.view = filterView;
    
    self.mLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 100, 100)];
    self.mLabel.textColor = [UIColor redColor];
    [self.view addSubview:self.mLabel];
    
    // 滤镜
    filter = [[GPUImageDissolveBlendFilter alloc] init];
    [(GPUImageDissolveBlendFilter *)filter setMix:0.5];
    
    
    // 播放
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"abc2" withExtension:@"mp4"];
    AVAsset *asset = [AVAsset assetWithURL:sampleURL];
    movieFile = [[GPUImageMovie alloc] initWithAsset:asset];
    movieFile.runBenchmark = YES;
    movieFile.playAtActualSpeed = YES;
    
    // 水印
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    label.text = @"我是水印";
    label.font = [UIFont systemFontOfSize:30];
    label.textColor = [UIColor redColor];
    [label sizeToFit];
    UIImage *image = [UIImage imageNamed:@"watermark.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    CGSize size = self.view.bounds.size;
    UIView *subView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    subView.backgroundColor = [UIColor clearColor];
    imageView.center = CGPointMake(subView.bounds.size.width / 2, subView.bounds.size.height / 2);
    [subView addSubview:imageView];
    [subView addSubview:label];
    
    
    
    //把UIView对象转换成纹理对象，进入响应链
    GPUImageUIElement *uielement = [[GPUImageUIElement alloc] initWithView:subView];//
    
    //    GPUImageTransformFilter 动画的filter
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 480.0)];
    
    GPUImageFilter* progressFilter = [[GPUImageFilter alloc] init];
    [movieFile addTarget:progressFilter];
    [progressFilter addTarget:filter];
    [uielement addTarget:filter];
    movieWriter.shouldPassthroughAudio = YES;
    movieFile.audioEncodingTarget = movieWriter;
    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    // 显示到界面
    [filter addTarget:filterView];
    [filter addTarget:movieWriter];
    
    
    [movieWriter startRecording];
    [movieFile startProcessing];
    
    
    CADisplayLink* dlink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
    [dlink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [dlink setPaused:NO];
    
    //当GPUImageFilter渲染完纹理后，会调用frameProcessingCompletionBlock回调。
    [progressFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        
        //UI应该放在主线程里面，修改图片位置
        dispatch_async(dispatch_get_main_queue(), ^{
            CGRect frame = imageView.frame;
            frame.origin.x += 1;
            frame.origin.y += 1;
            imageView.frame = frame;
        });
        [uielement updateWithTimestamp:time];
    }];
    
    
     __weak typeof(self) weakSelf = self;
    [movieWriter setCompletionBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->filter removeTarget:strongSelf->movieWriter];
        [strongSelf->movieWriter finishRecording];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathToMovie))
        {
            [library writeVideoAtPathToSavedPhotosAlbum:movieURL completionBlock:^(NSURL *assetURL, NSError *error)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     if (error) {
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存失败" message:nil
                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [alert show];
                     } else {
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存成功" message:nil
                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [alert show];
                     }
                 });
             }];
        }
        else {
            NSLog(@"error mssg)");
        }
    }];



    // Do any additional setup after loading the view.
}

- (void)updateProgress
{
    self.mLabel.text = [NSString stringWithFormat:@"Progress:%d%%", (int)(movieFile.progress * 100)];
    [self.mLabel sizeToFit];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
