//
//  JoinChannelVideo.m
//  APIExample
//
//  Created by zhaoyongqiang on 2023/7/11.
//

#import "JoinChannelVideoToken.h"
#import "KeyCenter.h"
#import <AgoraRtcKit/AgoraRtcKit.h>
#import "VideoView.h"
#import "APIExample_OC-swift.h"
#import "VideoRendererView.h"
#import "STMobileWrapper.h"

static NSUInteger mUid = 234;
static NSString *mAppId = @"1234b52f23d642b8bf34784f7582f458";
static NSString *mToken = @"007eJxTYHB2OlBptPTtp1VTI9YGaekqXdn2hW1tiWTBcuFbd//Hqd5TYDA0MjZJMjVKMzJOMTMxSrJISjM2MbcwSTM3tTBKMzG16Dt/La0hkJHh+s8QJUYGCATx1RmKSpKNzQxMTBJNTHVNjc3NdE2MDMx0LQ2N03QNUlJSjJISzVLMDCyYGYA2AAAznSoP";
static NSString *mChannelId = @"rtc36044a45-5376-4206-913f-0ddd2ba6d608";

@interface JoinChannelVideoTokenEntry ()
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextField *appIdTextField;
@property (weak, nonatomic) IBOutlet UITextField *tokenTextField;

@end

@implementation JoinChannelVideoTokenEntry

- (void)viewDidLoad {
    [super viewDidLoad];
    self.appIdTextField.text = mAppId;
    self.tokenTextField.text = mToken;
    self.textField.text = mChannelId; // channel
    
    
}

- (IBAction)onClickTipsButton:(id)sender {
    [self showAlertWithTitle:@"Quick input APPID and Token methods".localized
                     message:@"I: the mobile phone and Mac log in to the same Apple account. After copying the Mac, it will automatically synchronize other terminals with the same account. The mobile phone can directly click the input box to paste.\n\n II: use https://cl1p.net/ online clipboard:\n\n1.Enter in a URL that starts with cl1p.net. Example cl1p.net/uqztgjnqcalmd\n\n2.Paste in anything you want.\n\n3.On another computer enter the same URL and get your stuff.".localized
               textAlignment:(NSTextAlignmentLeft)];
}

- (IBAction)onClickJoinButton:(id)sender {
    [self.textField resignFirstResponder];
    
    if (self.appIdTextField.text.length <= 0) {
        [ToastView showWithText:@"please input AppId!".localized postion:ToastViewPostionCenter];
        return;
    }
    if (self.tokenTextField.text.length <= 0) {
        [ToastView showWithText:@"please input Token!".localized postion:ToastViewPostionCenter];
        return;
    }
    if (self.textField.text.length <= 0) {
        [ToastView showWithText:@"please input channel name!".localized postion:ToastViewPostionCenter];
        return;
    }
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"JoinChannelVideoToken" bundle:nil];
    BaseViewController *newViewController = [storyBoard instantiateViewControllerWithIdentifier:@"JoinChannelVideoToken"];
    newViewController.configs = @{@"channelName": self.textField.text,
                                  @"appId": self.appIdTextField.text,
                                  @"token": self.tokenTextField.text};
    [self.navigationController pushViewController:newViewController animated:YES];
}

@end


@interface JoinChannelVideoToken ()<AgoraRtcEngineDelegate, AgoraVideoFrameDelegate>
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, strong)VideoView *localView;
@property (nonatomic, strong)VideoView *remoteView;
@property (nonatomic, strong)AgoraRtcEngineKit *agoraKit;

@property STMobileWrapper *stWrapper;

/// 美颜开关是否打开
@property (nonatomic, assign) BOOL beautyIsOn;

@end

@implementation JoinChannelVideoToken

- (VideoView *)localView {
    if (_localView == nil) {
        _localView = (VideoView *)[NSBundle loadVideoViewFormType:StreamTypeLocal audioOnly:NO];
    }
    return _localView;
}

- (VideoView *)remoteView {
    if (_remoteView == nil) {
        _remoteView = (VideoView *)[NSBundle loadVideoViewFormType:StreamTypeRemote audioOnly:NO];
    }
    return _remoteView;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // layout render view
    [self.localView setPlaceholder:@"Local Host".localized];
    [self.remoteView setPlaceholder:@"Remote Host".localized];
    [self.containerView layoutStream:@[self.localView, self.remoteView]];
    
    NSString *channelName = [[self.configs objectForKey:@"channelName"] stringByTrimmingCharactersInSet:
    [NSCharacterSet whitespaceCharacterSet]];
    NSString *appId = [[self.configs objectForKey:@"appId"] stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceCharacterSet]];
    NSString *token = [[self.configs objectForKey:@"token"] stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceCharacterSet]];
    
    // 创建 AgoraLogConfig 对象
    AgoraLogConfig *logConfig = [[AgoraLogConfig alloc] init];
    // 将日志过滤器等级设置为 ERROR
    logConfig.level = AgoraLogLevelInfo;

    // 设置 log 的文件路径
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"ddMMyyyyHHmm"];
    NSString *folder = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES )[0];
    logConfig.filePath = [NSString stringWithFormat:@"%@/logs/%@.log", folder, [formatter stringFromDate:[NSDate date]]];

    // 设置 log 的文件大小为 2MB
    logConfig.fileSizeInKB = 2 * 1024;
    
    // set up agora instance when view loaded
    AgoraRtcEngineConfig *config = [[AgoraRtcEngineConfig alloc] init];
    config.appId = appId;
    config.channelProfile = AgoraChannelProfileLiveBroadcasting;
    config.logConfig = logConfig;

    self.agoraKit = [AgoraRtcEngineKit sharedEngineWithConfig:config delegate:self];
//    self.agoraKit getmode
    // make myself a broadcaster
    [self.agoraKit setClientRole:(AgoraClientRoleBroadcaster)];
    // enable video module and set up video encoding configs
    [self.agoraKit enableAudio];
    [self.agoraKit enableVideo];
    
    AgoraVideoEncoderConfiguration *encoderConfig = [[AgoraVideoEncoderConfiguration alloc] initWithSize:CGSizeMake(960, 540)
                                                                                               frameRate:(AgoraVideoFrameRateFps15)
                                                                                                 bitrate:15
                                                                                         orientationMode:(AgoraVideoOutputOrientationModeFixedPortrait)
                                                                                              mirrorMode:(AgoraVideoMirrorModeAuto)];
    [self.agoraKit setVideoEncoderConfiguration:encoderConfig];
    
    // set up local video to render your local camera preview
    AgoraRtcVideoCanvas *videoCanvas = [[AgoraRtcVideoCanvas alloc] init];
    videoCanvas.uid = 0;
    // the view to be binded
    videoCanvas.view = self.localView.videoView;
    videoCanvas.renderMode = AgoraVideoRenderModeHidden;
    videoCanvas.enableAlphaMask = YES;
    [self.agoraKit setupLocalVideo:videoCanvas];
    // you have to call startPreview to see local video
    [self.agoraKit startPreview];
    
    // Set audio route to speaker
    [self.agoraKit setEnableSpeakerphone:YES];
    
    // start joining channel
    // 1. Users can only see each other after they join the
    // same channel successfully using the same app id.
    // 2. If app certificate is turned on at dashboard, token is needed
    // when joining channel. The channel name and uid used to calculate
    // the token has to match the ones used for channel join
    AgoraRtcChannelMediaOptions *options = [[AgoraRtcChannelMediaOptions alloc] init];
    options.autoSubscribeAudio = YES;
    options.autoSubscribeVideo = YES;
    options.publishCameraTrack = YES;
    options.publishMicrophoneTrack = YES;
    options.clientRoleType = AgoraClientRoleBroadcaster;
    /// 设置视频数据回调监听
    [self.agoraKit setVideoFrameDelegate:self];
    int result = [self.agoraKit joinChannelByToken:token channelId:channelName uid:mUid mediaOptions:options joinSuccess:nil];
    if (result != 0) {
        // Usually happens with invalid parameters
        // Error code description can be found at:
        // en: https://api-ref.agora.io/en/video-sdk/ios/4.x/documentation/agorartckit/agoraerrorcode
        // cn: https://doc.shengwang.cn/api-ref/rtc/ios/error-code
        NSLog(@"joinChannel call failed: %d, please check your params", result);
    }
    
    /// 美颜开关
    UIButton *beautyBtn = [[UIButton alloc] initWithFrame:CGRectMake(30, 350, (self.view.bounds.size.width - 45) / 2.0, 30)];
    [beautyBtn setTitle:@"开启美颜" forState:UIControlStateNormal];
    [beautyBtn setTitle:@"关闭美颜" forState:UIControlStateSelected];
    [beautyBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [beautyBtn setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    [beautyBtn addTarget:self action:@selector(beautyEffectsSwitch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:beautyBtn];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.agoraKit disableAudio];
    [self.agoraKit disableVideo];
    [self.agoraKit stopPreview];
    [self.agoraKit leaveChannel:nil];
    [AgoraRtcEngineKit destroy];
}

/// callback when error occured for agora sdk, you are recommended to display the error descriptions on demand
/// to let user know something wrong is happening
/// Error code description can be found at:
/// en: https://api-ref.agora.io/en/video-sdk/ios/4.x/documentation/agorartckit/agoraerrorcode
/// cn: https://doc.shengwang.cn/api-ref/rtc/ios/error-code
/// @param errorCode error code of the problem
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraErrorCode)errorCode {
    NSLog(@"Error %ld occur",errorCode);
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString *)channel withUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    NSLog(@"Join %@ with uid %lu elapsed %ldms", channel, uid, elapsed);
    self.localView.uid = uid;
}

/// callback when a remote user is joinning the channel, note audience in live broadcast mode will NOT trigger this event
/// @param uid uid of remote joined user
/// @param elapsed time elapse since current sdk instance join the channel in ms
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    NSLog(@"remote user join: %lu %ldms", uid, elapsed);
    // Only one remote video view is available for this
    // tutorial. Here we check if there exists a surface
    // view tagged as this uid.
    AgoraRtcVideoCanvas *videoCanvas = [[AgoraRtcVideoCanvas alloc]init];
    videoCanvas.uid = uid;
    // the view to be binded
    videoCanvas.view = self.remoteView.videoView;
    videoCanvas.renderMode = AgoraVideoRenderModeHidden;
    [self.agoraKit setupRemoteVideo:videoCanvas];
    self.remoteView.uid = uid;
}

/// callback when a remote user is leaving the channel, note audience in live broadcast mode will NOT trigger this event
/// @param uid uid of remote joined user
/// @param reason reason why this user left, note this event may be triggered when the remote user
/// become an audience in live broadcasting profile
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason {
    // to unlink your view from sdk, so that your view reference will be released
    // note the video will stay at its last frame, to completely remove it
    // you will need to remove the EAGL sublayer from your binded view
    AgoraRtcVideoCanvas *videoCanvas = [[AgoraRtcVideoCanvas alloc]init];
    videoCanvas.uid = uid;
    // the view to be binded
    videoCanvas.view = nil;
    [self.agoraKit setupRemoteVideo:videoCanvas];
    self.remoteView.uid = 0;
}

#pragma mark - AgoraVideoFrameDelegate
//-(BOOL)onRenderVideoFrame:(AgoraOutputVideoFrame *)videoFrame uid:(NSUInteger)uid channelId:(NSString *)channelId {
////    [self.videoView renderFrame:videoFrame]; // I420
////    CVPixelBufferRef pixelBuffer = videoFrame.pixelBuffer;
//    videoFrame.pixelBuffer = [self.wrapper processGetBufferByPixelBuffer:videoFrame.pixelBuffer rotate:0 captureDevicePosition:0 renderOrigin:NO error:nil];
//    return YES;
//}

-(BOOL)onCaptureVideoFrame:(AgoraOutputVideoFrame *)videoFrame sourceType:(AgoraVideoSourceType)sourceType {
    if (!_stWrapper) {
        NSString *modelPathOf106 = [[NSBundle mainBundle] pathForResource:@"M_SenseME_Face_Video_Template_p_4.0.0" ofType:@"model"]; // 所需的检测模型路径
        NSString *licensePath = [NSBundle.mainBundle pathForResource:@"SENSEME" ofType:@"lic"];
        NSDictionary *wrapperConfig = @{
            @"license": licensePath,
            @"config": @(STMobileWrapperConfigPreview),
            @"models": @[modelPathOf106]
        };
        self.stWrapper = [[STMobileWrapper alloc] initWithConfig:wrapperConfig context:nil error:nil];
    }

    if (_beautyIsOn) {
        videoFrame.pixelBuffer = [self.stWrapper processGetBufferByPixelBuffer:videoFrame.pixelBuffer rotate:0 captureDevicePosition:0 renderOrigin:NO error:nil];
    }else {
        videoFrame.pixelBuffer = videoFrame.pixelBuffer;
    }
    return YES;
}

-(AgoraVideoFrameProcessMode)getVideoFrameProcessMode {
    return AgoraVideoFrameProcessModeReadWrite;
}

#pragma mark - action
- (void)beautyEffectsSwitch:(UIButton *)sender {
    if (sender.selected) {
        _beautyIsOn = NO;
        sender.selected = !sender.selected;
        return;
    }
    // 2. 设置特效
    
    // 1.基础美颜功能
    // 美白:zip包和mode方式各一个，美白4，mode3（默认开启美白4）
    NSString *whitenPath = [[NSBundle mainBundle] pathForResource:@"whiten4" ofType:@"zip"];
    [self.stWrapper setBeautyPath:EFFECT_BEAUTY_BASE_WHITTEN path:whitenPath error:nil];
    [self.stWrapper setBeautyMode:EFFECT_BEAUTY_BASE_WHITTEN mode:EFFECT_WHITEN_3 error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_BASE_WHITTEN strength:0.8 error:nil];

    // 磨皮：mode4
    [self.stWrapper setBeautyMode:EFFECT_BEAUTY_BASE_FACE_SMOOTH mode:EFFECT_SMOOTH_FACE_EVEN error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_BASE_FACE_SMOOTH strength:0.8 error:nil];
    
    // 红润
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_BASE_REDDEN strength:0.8 error:nil];

    // 2.美型
    // 瘦脸、小脸、窄脸、圆眼、大眼
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_RESHAPE_SHRINK_FACE strength:0.8 error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_RESHAPE_ENLARGE_EYE strength:0.8 error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_RESHAPE_SHRINK_JAW strength:0.8 error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_RESHAPE_NARROW_FACE strength:0.8 error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_RESHAPE_ROUND_EYE strength:0.8 error:nil];
    
    // 3.微整形
    // 小头，下巴
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_PLASTIC_THINNER_HEAD strength:0.8 error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_PLASTIC_CHIN_LENGTH strength:0.8 error:nil];
    
    // 4.滤镜（babypink）
    NSString *filterPath = [[NSBundle mainBundle] pathForResource:@"filter_style_babypink" ofType:@"model"];
    [self.stWrapper setBeautyPath:EFFECT_BEAUTY_FILTER path:filterPath error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_FILTER strength:0.8 error:nil];
    
    // 5.风格妆
    NSString *stylePath = [[NSBundle mainBundle] pathForResource:@"oumei" ofType:@"zip"];
    int stickerId = [self.stWrapper changePackage:stylePath error:nil];
    [self.stWrapper setPackageBeautyGroup:stickerId type:EFFECT_BEAUTY_GROUP_FILTER strength:0.8 error:nil];
    [self.stWrapper setPackageBeautyGroup:stickerId type:EFFECT_BEAUTY_GROUP_MAKEUP strength:0.8 error:nil];
    
    // 6.单妆（口红）
    NSString *lipstickPath = [[NSBundle mainBundle] pathForResource:@"1自然" ofType:@"zip"];
    [self.stWrapper setBeautyPath:EFFECT_BEAUTY_MAKEUP_LIP path:lipstickPath error:nil];
    [self.stWrapper setBeautyStrength:EFFECT_BEAUTY_MAKEUP_LIP strength:0.8 error:nil];

    // 7.2D脸部贴纸
    NSString *araleStickerPath = [[NSBundle mainBundle] pathForResource:@"bunny" ofType:@"zip"];
    int stickerPackageId = [self.stWrapper changePackage:araleStickerPath error:nil];
    
    _beautyIsOn = YES;
    sender.selected = !sender.selected;
}

@end
