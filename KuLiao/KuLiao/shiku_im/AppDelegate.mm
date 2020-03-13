#import "AppDelegate.h"

#import "JXMainViewController.h"
#import "emojiViewController.h"
#import "JXXMPP.h"
#import "JXServer.h"
#import "JXCommonService.h"
#import "versionManage.h"
#import "JXGroupViewController.h"
#import "JXConstant.h"
#import "loginVC.h"
#import "BPush.h"
#import "UMSocial.h"
#import "UMSocialWechatHandler.h"
#import "JXShareManage.h"
//#import <AlipaySDK/AlipaySDK.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#if Meeting_Version
#if !TARGET_IPHONE_SIMULATOR
#import <JitsiMeet/JitsiMeet.h>
#endif
#endif
#ifdef USE_GOOGLEMAP
#import <GoogleMaps/GoogleMaps.h>
#endif
#import <AlipaySDK/AlipaySDK.h>
#import "NumLockViewController.h"

// iOS10 注册 APNs 所需头文件
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif
// 如果需要使用 idfa 功能所需要引入的头文件（可选）
#import <AdSupport/AdSupport.h>


@implementation AppDelegate
@synthesize window,faceView,mainVc,config,jxServer;
@synthesize jxConstant;

#if TAR_IM
#ifdef Meeting_Version
@synthesize jxMeeting;
#endif
#endif

static  BMKMapManager* _baiduMapManager;

- (void)dealloc
{
#if TAR_IM
#ifdef Meeting_Version
    [jxMeeting stopMeeting];
#endif
#endif
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    application.statusBarStyle = UIStatusBarStyleDefault;
    
    _navigation = [[JXNavigation alloc] init];
    
    // 网络监听
    [self networkStatusChange];
    // 监听截屏
//    [g_notify addObserver:self selector:@selector(getScreenShot:) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    
//    if(isIOS7){
//        application.statusBarStyle = UIStatusBarStyleDefault;
//        window.clipsToBounds = YES;
//        window.frame = CGRectMake(0, 20, self.window.frame.size.width, self.window.frame.size.height-20);
//    }
    
    _commonService = [[JXCommonService alloc] init];
    jxServer = [[JXServer alloc] init];
    config  = [[versionManage alloc] init];
    jxConstant = [[JXConstant alloc]init];
    _didPushObj = [JXDidPushObj sharedInstance];

#if TAR_IM
#ifdef Meeting_Version
    jxMeeting = [[JXMeetingObject alloc] init];
    [self startVoIPPush];
#endif
#endif
    
//    [NSThread sleepForTimeInterval:0.3];
    
    [self showLoginUI];
    [self startPush:application didFinishLaunchingWithOptions:launchOptions];
    
    // 要使用百度地图，请先启动BaiduMapManager
    _baiduMapManager = [[BMKMapManager alloc]init];
    // 如果要关注网络及授权验证事件，请设定     generalDelegate参数
    
    NSString * identifier = [[NSBundle mainBundle] bundleIdentifier];
    BOOL ret = false;
    if ([identifier isEqualToString:@"com.shiku.im.push"]) {//IM2
        ret = [_baiduMapManager start:@"tVZRqzVYKwbwX7NytFnDWAUh4RbMnPDL"  generalDelegate:nil];
    }else if ([identifier isEqualToString:@"com.shiku.live.push1"]) {//直播
        ret = [_baiduMapManager start:@"7YGiGTxFpa546GSxYt0RjVQ7yoz0oOdQ" generalDelegate:nil];
    }else if ([identifier isEqualToString:@"com.shiku.coolim.push1"]) {//IM
        ret = [_baiduMapManager start:@"YWCjFscGk7cv3RlEtaxoypzt0sipp6vw"  generalDelegate:nil];
    }
    if (!ret)
        NSLog(@"BMKMapManager start faild!");
    
    //notice: 3.0.0 及以后版本注册可以这样写，也可以继续用之前的注册方式
    JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
    entity.types = JPAuthorizationOptionAlert|JPAuthorizationOptionBadge|JPAuthorizationOptionSound|JPAuthorizationOptionProvidesAppNotificationSettings;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        // 可以添加自定义 categories
        // NSSet<UNNotificationCategory *> *categories for iOS10 or later
        // NSSet<UIUserNotificationCategory *> *categories for iOS8 and iOS9
    }
    [JPUSHService registerForRemoteNotificationConfig:entity delegate:self];
    
    // 获取 IDFA
    // 如需使用 IDFA 功能请添加此代码并在初始化方法的 advertisingIdentifier 参数中填写对应值
    NSString *advertisingId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    
    // Required
    // init Push
    // notice: 2.1.5 版本的 SDK 新增的注册方法，改成可上报 IDFA，如果没有使用 IDFA 直接传 nil
    [JPUSHService setupWithOption:launchOptions appKey:@"e18945a450b6888c7091e8c9"
                          channel:@"App Store"
                 apsForProduction:YES
            advertisingIdentifier:advertisingId];
    
    [JPUSHService registrationIDCompletionHandler:^(int resCode, NSString *registrationID) {
        if(resCode == 0){
            NSLog(@"registrationID获取成功：%@",registrationID);
            [g_default setObject:registrationID forKey:@"jPushRegistrationID"];

        }
        else{
            NSLog(@"registrationID获取失败，code：%d",resCode);
        }
    }];

    //谷歌地图
#ifdef USE_GOOGLEMAP
    [GMSServices provideAPIKey:@"AIzaSyDk0-ylpwNIPtOZHYSPiGvM--RG02azY7w"];
#endif
//    if (![g_default boolForKey:kUseGoogleMap]) {
//        [g_default setBool:NO forKey:kUseGoogleMap];
//    }
    // 设置友盟AppKey
    [UMSocialData setAppKey:@"ec6e99350b0fdb428cf50a5be403b268"];
    
//    [WXApi registerApp:MXWechatAPPID enableMTA:NO];
    [UMSocialWechatHandler setWXAppId:MXWechatAPPID appSecret:@"ec6e99350b0fdb428cf50a5be403b268" url:@"http://www.umeng.com/social"];
    
    
    [self registerAPN];
    
    [self setUserAgent];
    
    NSDictionary* pushNotificationKey = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
//    [g_notify postNotificationName:kDidReceiveRemoteNotification object:pushNotificationKey];
    [g_default setObject:pushNotificationKey forKey:kDidReceiveRemoteDic];
    [g_default synchronize];
    
    return YES;
}

- (void)setUserAgent {
    
    UIWebView *webView = [[UIWebView alloc] init];
    NSString *originUA = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    NSString *newUA = [NSString stringWithFormat:@"%@ %@",originUA,@"app-shikuimapp"];
    NSDictionary *dictionary = @{@"UserAgent":newUA};
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
}

- (void)registerAPN{
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

-(UIView *)subWindow
{
    if (!_subWindow) {
        _subWindow = [[UIView alloc] initWithFrame:CGRectMake(100,200,80,80)];
//        _subWindow.windowLevel  =  UIWindowLevelAlert +1;
//        [_subWindow makeKeyAndVisible]; //关键语句，显示窗口
        [g_window addSubview:_subWindow];
    }
    
    return _subWindow;
}
/**
*关闭悬浮的窗口
*/
- (void)resignWindow
{
//    [_subWindow resignKeyWindow];
    [_subWindow removeFromSuperview];
    _subWindow  =  nil ;
}

-(void)showLoginUI{
    loginVC* vc = [loginVC alloc];
    vc.isAutoLogin = YES;
    vc.isSwitchUser= NO;
    vc = [vc init];
    g_navigation.rootViewController = vc;
//    [self.window addSubview:vc.view];
//    self.window.rootViewController = vc;
//    [self.window makeKeyAndVisible];
//    
//    _navigation = [[JXNavigation alloc] init];
//    [g_navigation.subViews removeAllObjects];
//    [g_navigation pushViewController:vc];
}

-(void)showMainUI{
//    if(mainVc==nil){
        mainVc=[[JXMainViewController alloc]init];
//    }
//        [window addSubview:mainVc.view];
//        window.rootViewController = mainVc;
        g_navigation.rootViewController = mainVc;
        int height = 218;
        if (THE_DEVICE_HAVE_HEAD) {
            height = 253;
        }
        faceView = [[emojiViewController alloc]initWithFrame:CGRectMake(0, JX_SCREEN_HEIGHT-height, JX_SCREEN_WIDTH, height)];
    
    
    NSString *str = [g_default stringForKey:kDeviceLockPassWord];
    if (str.length > 0) {
        [self showDeviceLock];
    }
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // 进入后台
    [g_notify postNotificationName:kApplicationDidEnterBackground object:nil];
    
    [g_notify postNotificationName:kAllVideoPlayerStopNotifaction object:nil userInfo:nil];
    [g_notify postNotificationName:kAllAudioPlayerStopNotifaction object:nil userInfo:nil];
    
    NSLog(@"XMPP ---- Appdelegate");
    [g_server userChangeMsgNum:[UIApplication sharedApplication].applicationIconBadgeNumber toView:self];
#if TAR_IM
#ifdef Meeting_Version
    [jxMeeting meetingDidEnterBackground:application];
    
    if (!g_meeting.isMeeting) {
        
        [g_server outTime:nil];
        g_xmpp.isCloseStream = YES;
        g_xmpp.isReconnect = NO;
        [g_xmpp logout];
        
        NSString *str = [g_default stringForKey:kDeviceLockPassWord];
        if (str.length > 0) {
            [self showDeviceLock];
        }
    }
#else
    [g_server outTime:nil];
    g_xmpp.isCloseStream = YES;
    g_xmpp.isReconnect = NO;
    [g_xmpp logout];
    
    NSString *str = [g_default stringForKey:kDeviceLockPassWord];
    if (str.length > 0) {
        [self showDeviceLock];
    }
#endif
#endif
    
    
    
    
    NSLog(@"程序后台");
}

- (void)showDeviceLock {
    if (!self.isShowDeviceLock) {
        self.isShowDeviceLock = YES;
        _numLockVC = [[NumLockViewController alloc]init];
        _numLockVC.isClose = NO;
        [g_window addSubview:_numLockVC.view];
    }
}



- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [config showDisableUse];
    [g_notify postNotificationName:kApplicationWillEnterForeground object:nil];
//    NSLog(@"applicationWillEnterForeground");
    if(g_server.isLogin){
//        NSLog(@"login");
        [[JXXMPP sharedInstance] login];
#if TAR_IM
#ifdef Meeting_Version
        [jxMeeting meetingWillEnterForeground:application];
#endif
#endif
    }
    
    // 清除过期聊天记录
    [[JXUserObject sharedInstance] deleteUserChatRecordTimeOutMsg];
}

//- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
//	NSLog(@"OpenURL:%@",url);
//    //如果极简开发包不可用，会跳转支付宝钱包进行支付，需要将支付宝钱包的支付结果回传给开发包
////    if ([url.host isEqualToString:@"safepay"]) {
////        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
////            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
////            NSLog(@"result = %@",resultDic);
////        }];
////    }
////    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回authCode
////        
////        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
////            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
////            NSLog(@"result = %@",resultDic);
////        }];
////    }
//    
//    return YES;
//}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    [[JXShareManage sharedManager] handleOpenURL:url delegate:nil];
    
    return  [WXApi handleOpenURL:url delegate:[WXApiManager sharedManager]];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
#if Meeting_Version
#if !TARGET_IPHONE_SIMULATOR
    [JitsiMeetView application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
#endif
#endif
    [[JXShareManage sharedManager] handleOpenURL:url delegate:nil];
    
    return [WXApi handleOpenURL:url delegate:[WXApiManager sharedManager]];
}

// NOTE: 9.0以后使用新API接口
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
    if ([url.host isEqualToString:@"safepay"]) {
        // 授权跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
            // 解析 auth code
            NSString *result = resultDic[@"result"];
            NSString *authCode = nil;
            if (result.length>0) {
                NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                for (NSString *subResult in resultArr) {
                    if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                        authCode = [subResult substringFromIndex:10];
                        break;
                    }
                }
            }
            NSLog(@"授权结果 authCode = %@", authCode?:@"");
        }];
    }

    [[JXShareManage sharedManager] handleOpenURL:url delegate:nil];
    
    return [WXApi handleOpenURL:url delegate:[WXApiManager sharedManager]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // 进入活跃
    [g_notify postNotificationName:kApplicationDidBecomeActive object:nil];
    
//    if(g_server.isLogin && g_xmpp.isLogined != login_status_yes)
//        [[JXXMPP sharedInstance] login];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    [g_server userChangeMsgNum:[UIApplication sharedApplication].applicationIconBadgeNumber toView:self];
//    if(g_server.isLogin) {
//        [g_server outTime:nil];
//        g_xmpp.isCloseStream = YES;
//        g_xmpp.isReconnect = NO;
//        [g_xmpp logout];
//    }
}

- (void) showAlert: (NSString *) message
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:APP_NAME message:message delegate:self cancelButtonTitle:Localized(@"JX_Confirm") otherButtonTitles:nil, nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [av show];
    });
	
//    [av release];
}

- (UIAlertView *) showAlert: (NSString *) message delegate:(id)delegate
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:APP_NAME message:message delegate:delegate cancelButtonTitle:Localized(@"JX_Cencal") otherButtonTitles:Localized(@"JX_Confirm"), nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [av show];
    });
    
    return av;
}

- (UIAlertView *) showAlert: (NSString *) message delegate:(id)delegate tag:(NSUInteger)tag onlyConfirm:(BOOL)onlyConfirm
{
    UIAlertView *av;
    if (onlyConfirm)
       av = [[UIAlertView alloc] initWithTitle:APP_NAME message:message delegate:delegate cancelButtonTitle:Localized(@"JX_Confirm") otherButtonTitles:nil];
    else
        av = [[UIAlertView alloc] initWithTitle:APP_NAME message:message delegate:delegate cancelButtonTitle:Localized(@"JX_Cencal") otherButtonTitles:Localized(@"JX_Confirm"), nil];
    av.tag = tag;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [av show];
    });
    return av;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
#if TAR_IM
#ifdef Meeting_Version
//    [jxMeeting doNotify:notification];
#endif
#endif
//    NSLog(@"推送：接收本地通知啦！！！");
//    [BPush showLocalNotificationAtFront:notification identifierKey:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"程序杀死");
    
    [g_server userChangeMsgNum:[UIApplication sharedApplication].applicationIconBadgeNumber toView:self];
    [g_server outTime:nil];
    g_xmpp.isCloseStream = YES;
    g_xmpp.isReconnect = NO;
    [g_xmpp logout];
    
#if TAR_IM
#ifdef Meeting_Version
    [jxMeeting doTerminate];
    [self endCall];
#endif
#endif
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
#if TAR_IM
#ifdef Meeting_Version
    [jxMeeting clearMemory];
#endif
#endif
}

-(void)startPush:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    // iOS8 下需要使用新的 API
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        UIUserNotificationType myTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:myTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
    }
    
    // 在 App 启动时注册百度云推送服务，需要提供 Apikey
    NSString * identifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([identifier isEqualToString:@"com.shiku.im.push"]) {
        [BPush registerChannel:launchOptions apiKey:@"YWCjFscGk7cv3RlEtaxoypzt0sipp6vw" pushMode: BPushModeProduction withFirstAction:nil withSecondAction:nil withCategory:nil useBehaviorTextInput:YES isDebug:NO];
    }else{
        [BPush registerChannel:launchOptions apiKey:@"7LlWDe0AZGKILS4Tq5cMNMum" pushMode: BPushModeProduction withFirstAction:nil withSecondAction:nil withCategory:nil useBehaviorTextInput:YES isDebug:NO];
    }
    
//
    // App 是用户点击推送消息启动
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
//        NSLog(@"从消息启动:%@",userInfo);
        [BPush handleNotification:userInfo];
    }
#if TARGET_IPHONE_SIMULATOR
    Byte dt[32] = {0xc6, 0x1e, 0x5a, 0x13, 0x2d, 0x04, 0x83, 0x82, 0x12, 0x4c, 0x26, 0xcd, 0x0c, 0x16, 0xf6, 0x7c, 0x74, 0x78, 0xb3, 0x5f, 0x6b, 0x37, 0x0a, 0x42, 0x4f, 0xe7, 0x97, 0xdc, 0x9f, 0x3a, 0x54, 0x10};
    [self application:application didRegisterForRemoteNotificationsWithDeviceToken:[NSData dataWithBytes:dt length:32]];
#endif
    //角标清0
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

//// 此方法是 用户点击了通知，应用在前台 或者开启后台并且应用在后台 时调起
//- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
//{
//    completionHandler(UIBackgroundFetchResultNewData);
//    // 打印到日志 textView 中
////    NSLog(@"********** iOS7.0之后 background **********");
//    // 应用在前台 或者后台开启状态下，不跳转页面，让用户选择。
//    if (application.applicationState == UIApplicationStateActive || application.applicationState == UIApplicationStateBackground) {
////        NSLog(@"acitve or background");
////        [self showAlert:userInfo[@"aps"][@"alert"]];
//    }
//    else//杀死状态下，直接跳转到跳转页面。
//    {
//    }
//}


// 在 iOS8 系统中，还需要添加这个方法。通过新的 API 注册推送服务
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"test:%@",deviceToken);
//    NSString *token = [NSString stringWithFormat:@"%@",deviceToken];
    NSString * token = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    //apnsToken 需要提交给服务器
    [g_default setObject:token forKey:@"apnsToken"];
    [BPush registerDeviceToken:deviceToken];
    [BPush bindChannelWithCompleteHandler:^(id result, NSError *error) {
        // 需要在绑定成功后进行 settag listtag deletetag unbind 操作否则会失败
        if (result) {
            [BPush setTag:@"Mytag" withCompleteHandler:^(id result, NSError *error) {
                if (result) {
                    NSLog(@"设置tag成功");
                }
            }];
        }
    }];
    
    /// 极光推送 - 注册 DeviceToken
    [JPUSHService registerDeviceToken:deviceToken];
}

// 当 DeviceToken 获取失败时，系统会回调此方法
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"DeviceToken 获取失败，原因：%@",error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    // App 收到推送的通知
    [BPush handleNotification:userInfo];
    
    // Required, For systems with less than or equal to iOS 6
    [JPUSHService handleRemoteNotification:userInfo];

    
    [g_default setObject:userInfo forKey:kDidReceiveRemoteDic];
    [g_default synchronize];
//    [g_notify postNotificationName:kDidReceiveRemoteNotification object:userInfo];
    
//    NSLog(@"********** ios7.0之前 **********");
    // 应用在前台 或者后台开启状态下，不跳转页面，让用户选择。
    if (application.applicationState == UIApplicationStateActive || application.applicationState == UIApplicationStateBackground) {
//        NSLog(@"acitve or background");
//        [self showAlert:userInfo[@"aps"][@"alert"]];
    }
    else//杀死状态下，直接跳转到跳转页面。
    {
    }
}


#pragma mark- JPUSHRegisterDelegate

// iOS 12 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(UNNotification *)notification{
    if (notification && [notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //从通知界面直接进入应用
    }else{
        //从通知设置界面进入应用
    }
}

// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger))completionHandler {
    // Required
    NSDictionary * userInfo = notification.request.content.userInfo;
    
    
    [g_default setObject:userInfo forKey:kDidReceiveRemoteDic];
    [g_default synchronize];
    
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
    }
    completionHandler(UNNotificationPresentationOptionAlert); // 需要执行这个方法，选择是否提醒用户，有 Badge、Sound、Alert 三种类型可以选择设置
}

// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    // Required
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    [g_default setObject:userInfo forKey:kDidReceiveRemoteDic];
    [g_default synchronize];
    
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
    }
    completionHandler();  // 系统要求执行这个方法
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    [g_default setObject:userInfo forKey:kDidReceiveRemoteDic];
    [g_default synchronize];
    
    // Required, iOS 7 Support
    [JPUSHService handleRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

// 监听网络状态
- (void)networkStatusChange {
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
    
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status != AFNetworkReachabilityStatusNotReachable) {
            if (g_server.isLogin) {
                if (g_xmpp.isLogined != login_status_yes) {
                    [[JXXMPP sharedInstance] logout];
                    [[JXXMPP sharedInstance] login];
                }
            }
            
        }else {
            [g_xmpp.reconnectTimer invalidate];
            g_xmpp.reconnectTimer = nil;
            g_xmpp.isReconnect = NO;
            [[JXXMPP sharedInstance] logout];
            [g_App showAlert:Localized(@"JX_NetWorkError")];
        }
    }];
}

#if TAR_IM
#ifdef Meeting_Version
-(void)startVoIPPush{
    NSString * identifier = [[NSBundle mainBundle] bundleIdentifier];
    NSLog(@"callkit - start");
    if ([identifier isEqualToString:@"com.shiku.im.push"] && [[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        PKPushRegistry * pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
        pushRegistry.delegate = self;
        pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    }else{
        [g_default removeObjectForKey:@"voipToken"];
    }
}

#pragma mark - PKPushRegistryDelegate
-(void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type{
    if ([credentials.token length] == 0) {
        NSLog(@"voip token NULL");
        return;
    }
    NSString * voipToken = [[[[credentials.token description] stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    //voipToken 需要提交给服务器
    [g_default setObject:voipToken forKey:@"voipToken"];
    NSLog(@"voipToken:%@",voipToken);
}

-(void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type{
    NSLog(@"callkit - didreceive");
    if (type != PKPushTypeVoIP) {
        return;
    }
    
    NSString * fromUserName = payload.dictionaryPayload[@"fromUserName"];
    int messageType = [[NSString stringWithFormat:@"%@",payload.dictionaryPayload[@"messageType"]] intValue];
    BOOL isCallKit = messageType == kWCMessageTypeAudioChatAsk ? YES : NO;
    BOOL isAudio = (messageType == kWCMessageTypeAudioChatAsk || messageType == kWCMessageTypeAudioMeetingInvite) ? YES : NO;
    BOOL isVideo = (messageType == kWCMessageTypeVideoChatAsk || messageType == kWCMessageTypeVideoMeetingInvite) ? YES : NO;
    fromUserName = fromUserName.length > 0 ? fromUserName : APP_NAME;
    
    
    switch ([UIApplication sharedApplication].applicationState) {
        case UIApplicationStateActive:
        case UIApplicationStateInactive:{
            //不处理,显示app接听界面
            if (_uuid) {
                [self endCall];
            }
            break;
        }
        case UIApplicationStateBackground:
        default:{
            if (isCallKit && !_uuid && [[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
                if (_uuid) {
                    return;
                }
                
                _uuid = [NSUUID UUID];
                [self applicationWillEnterForeground:[UIApplication sharedApplication]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //显示系统CALLKit接听界面
                    CXCallUpdate * callUpdate = [[CXCallUpdate alloc] init];
                    callUpdate.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:fromUserName];
                    callUpdate.hasVideo = NO;
                    [self.provider reportNewIncomingCallWithUUID:_uuid update:callUpdate completion:^(NSError * _Nullable error) {
                        if (error) {
                            NSLog(@"report error:%@",error.description);
                        }else{
                            [self performSelector:@selector(endCall) withObject:nil afterDelay:30];
                        }
                    }];
                });
                
            }else if(isAudio || isVideo){
                _uuid = nil;
                [self meetingLocalNotifi:fromUserName isAudio:isAudio];
            }
            break;
        }
    }
}

-(void)meetingLocalNotifi:(NSString *)fromUserName isAudio:(BOOL)isAudio{
    UILocalNotification *callNotification = [[UILocalNotification alloc] init];
    
    NSString *stringAlert;
    if (isAudio){
        stringAlert = [NSString stringWithFormat:@"%@ \n %@", Localized(@"JXMeetingObject_VoiceChat"),fromUserName];
    }else{
        stringAlert = [NSString stringWithFormat:@"%@\n %@",Localized(@"JXMeetingObject_VideoChat"), fromUserName];
    }
    callNotification.alertBody = stringAlert;
    
    callNotification.soundName = @"whynotyou.caf";
    [[UIApplication sharedApplication]
     presentLocalNotificationNow:callNotification];
}


#pragma mark - callKit
- (CXProviderConfiguration *)providerConfig{
    static CXProviderConfiguration* configInternal = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    
        configInternal = [[CXProviderConfiguration alloc] initWithLocalizedName:APP_NAME];
        configInternal.supportsVideo = NO;
        configInternal.maximumCallsPerCallGroup = 1;
        configInternal.maximumCallGroups = 1;
        configInternal.supportedHandleTypes = [NSSet setWithObject:@(CXHandleTypePhoneNumber)];
        UIImage* iconMaskImage = [UIImage imageNamed:@"酷聊120"];
        configInternal.iconTemplateImageData = UIImagePNGRepresentation(iconMaskImage);
        configInternal.ringtoneSound = @"whynotyou.caf";
    });
    
    return configInternal;
}

-(CXProvider *)provider{
    if (!_provider) {
        _provider = [[CXProvider alloc] initWithConfiguration:self.providerConfig];
        [_provider setDelegate:self queue:nil];
    }
    return _provider;
}

-(CXCallController *)cxCallController{
    if (!_cxCallController) {
        _cxCallController = [[CXCallController alloc] initWithQueue:dispatch_get_main_queue()];
    }
    return _cxCallController;
}

#pragma mark - CXProviderDelegate
/// Called when the provider has been reset. Delegates must respond to this callback by cleaning up all internal call state (disconnecting communication channels, releasing network resources, etc.). This callback can be treated as a request to end all calls without the need to respond to any actions
- (void)providerDidReset:(CXProvider *)provider{
    NSLog(@"callkit - reset");
    [self endCall];
}

-(void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action{
    NSLog(@"callkit - timeout");
    [self endCall];
}


// user answered this incoming call
- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action{
    
    NSLog(@"callkit - answercallaction");
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(endCall) object:nil];
    
    [action fulfill];
}
// user end this call
- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action{
    NSLog(@"callkit - callend");
    [g_notify postNotificationName:kCallEndNotification object:nil];
    [self endCall];
    [action fulfill];
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession{
    NSLog(@"callkit - callanswer");
    [g_notify postNotificationName:kCallAnswerNotification object:nil];
}
- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action{
    NSLog(@"callkit - setmuted");
    [g_notify postNotificationName:kCallSetMutedNotification object:[NSNumber numberWithBool:action.muted]];
}


- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession{
    NSLog(@"callkit - deactivate");
    switch ([UIApplication sharedApplication].applicationState) {
        case UIApplicationStateActive:
        case UIApplicationStateInactive:{
            break;
        }
        case UIApplicationStateBackground:
        default:{
            [self applicationDidEnterBackground:[UIApplication sharedApplication]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                exit(0);
            });
            break;
        }
    }
}

-(void)endCall{
    if (_uuid) {
        NSLog(@"callkit - endcall");
//        self.isShowCall = NO;
        CXEndCallAction * endAction = [[CXEndCallAction alloc] initWithCallUUID:_uuid];
        CXTransaction * trans = [[CXTransaction alloc] initWithAction:endAction];
        
        CXCallController * callVC = [[CXCallController alloc] initWithQueue:dispatch_get_main_queue()];
        [callVC requestTransaction:trans completion:^(NSError * _Nullable error) {
            if (error) {
//                NSLog(@"%@",error.description);
                [self.provider reportCallWithUUID:_uuid endedAtDate:nil reason:CXCallEndedReasonUnanswered];
            }
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                [self applicationDidEnterBackground:[UIApplication sharedApplication]];
            }
            _uuid = nil;
        }];
    }
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        [self applicationDidEnterBackground:[UIApplication sharedApplication]];
    }
}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
    NSLog(@"callkit - startcall");
}

-(void)callEndInTimeOut{
    
    NSLog(@"callkit - endintimeout");
    if (_uuid) {
        [self.provider reportCallWithUUID:_uuid endedAtDate:[NSDate dateWithTimeIntervalSinceNow:30] reason:CXCallEndedReasonUnanswered];
    }
}
#endif
#endif


// 截屏监听
//- (void)getScreenShot:(NSNotification *)notification{
//    NSLog(@"捕捉截屏事件");
//    
//    //获取截屏图片
////    UIImage *image = [UIImage imageWithData:[self imageDataScreenShot]];
//    NSData *imageData = [self imageDataScreenShot];
//    BOOL isSuccess = [imageData writeToFile:ScreenShotImage atomically:YES];
//    if (isSuccess) {
//        NSLog(@"截屏存储成功 - %@", NSHomeDirectory());
//    }else {
//        NSLog(@"截屏存储失败");
//    }
//}

- (NSData *)imageDataScreenShot
{
    CGSize imageSize = CGSizeZero;
    imageSize = [UIScreen mainScreen].bounds.size;
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, window.center.x, window.center.y);
        CGContextConcatCTM(context, window.transform);
        CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);
        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
        {
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
        }
        else
        {
            [window.layer renderInContext:context];
        }
        CGContextRestoreGState(context);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return UIImagePNGRepresentation(image);
}

- (void)copyDbWithUserId:(NSString *)userId {
    // 拷贝文件到share extension 共享存储空间中
    userId = [userId uppercaseString];
    NSString* t =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString* copyPath = [NSString stringWithFormat:@"%@/%@.db",t,userId];
    
    //获取分组的共享目录
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *groupURL = [manager containerURLForSecurityApplicationGroupIdentifier:APP_GROUP_ID];
    NSString *fileName = [NSString stringWithFormat:@"%@.db",userId];
    NSURL *fileURL = [groupURL URLByAppendingPathComponent:fileName];
    
    NSString *path = [fileURL.absoluteString substringFromIndex:7];
    
    NSError *error = nil;
    [manager removeItemAtPath:path error:&error];
    if (error) {
        NSLog(@"删除失败error : %@",error);
    }
    if (path.length <= 0) {
        return;
    }
    BOOL isCopy = [manager copyItemAtPath:copyPath toPath:path error:nil];
    
    if (isCopy) {
        static dispatch_once_t disOnce;
        dispatch_once(&disOnce,^ {
            //只执行一次的代码
            NSLog(@"share extension : %@",path);
        });
    }
}


@end
