//
//  JXServer.m
//  sjvodios
//
//  Created by  on 12-5-22.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "JXServer.h"
#import "JXConnection.h"
#import "AppDelegate.h"
#import "JSON.h"
#import "JXImageView.h"
#import "versionManage.h"
//#import "MobClick.h"
#import "md5.h"
#import "WeiboReplyData.h"
#import "loginVC.h"
#import "webpageVC.h"
#import "searchData.h"
#import "roomData.h"
#import "BPush.h"
#import "photo.h"
#import "resumeData.h"
#import "ATMHud.h"
#import "JXMyTools.h"
#import "JXLocation.h"
#import "UIImageView+WebCache.h"


@interface JXServer ()<JXLocationDelegate,JXConnectionDelegate>

@property (nonatomic, assign) BOOL isGetSetting;

@end

@implementation JXServer
@synthesize isLoginWeibo,longitude,latitude;
@synthesize count_money;
@synthesize user_id;
@synthesize user_type;
@synthesize myself;
@synthesize access_token;
@synthesize isLogin;
@synthesize lastOfflineTime;

-(id)init{
    self = [super init];
    _arrayConnections= [[NSMutableArray alloc] init];
    _dictWaitViews   = [[NSMutableDictionary alloc] init];
    _bAlreadyAutoLogin= NO;
    isLogin   = NO;
    
    //    latitude  = 22.6;
    //    longitude = 114.04;
    latitude  =  0;
    longitude =  0;
    
    _locationCount  = 0;
//    self.location = [[JXLocation alloc] init];
//    self.location.delegate = self;
    [self locate];   //定位
    //    [self performSelector:@selector(startLocation) withObject:nil afterDelay:10];
    
    access_token = @"8864c3159c964c82bf0719ae0ade5ccd";//个人
    
    myself = [[JXUserObject alloc] init];
    myself.userId = @"100003";
    //企业：18908983800,qqq, 18503054766,123456 ,189388807760,1234
    //个人：18503054765,123456 18938880756,1234
    //18938880752,为客服号
    myself.userNickname = Localized(@"JX_NickName");
    myself.userDescription = Localized(@"JX_GiftText");
    myself.birthday = [NSDate date];
    myself.companyId    = [NSNumber numberWithInt:1];
    myself.level        = [NSNumber numberWithInt:1];
    myself.fansCount    = [NSNumber numberWithInt:1000];
    myself.attCount     = [NSNumber numberWithInt:1000];
    myself.userHead     = @"http://image.tianjimedia.com/uploadImages/2013/231/KJQIZSVQ013Q.jpg";
    
    [self readDefaultSetting];
    
    _hud = [[ATMHud alloc] initWithDelegate:self];
//    self.multipleLogin = [JXMultipleLogin sharedInstance];
    return self;
}

-(void)dealloc{
    //    [_location release];
    //    [mvViewArray release];
    //    [_arrayConnections release];
    //    [_dictWaitViews release];
    //    [_dictSingers release];
    //    [myself release];
    //    [iExamArray release];
    //    [wExamArray release];
    //    [jobArray release];
    //
    //    [super dealloc];
}

-(JXConnection*)addTask:(NSString*)action param:(id)param toView:(id)delegate{
    if([action length]<=0)
        return nil;
    if(param==nil)
        param = @"";
    
    NSString* url=nil;
    NSString* s=@"";
    
    JXConnection *task = [[JXConnection alloc] init];
    
    if([action rangeOfString:@"http://"].location == NSNotFound){
        if([action isEqualToString:act_UploadFile] ||[action isEqualToString:act_UploadVoiceServlet] || [action isEqualToString:act_UploadHeadImage] || [action isEqualToString:act_SetGroupAvatarServlet]){
            s = g_config.uploadUrl;
            
        }
        else{
            NSRange range = [g_config.apiUrl rangeOfString:@"config"];
            if (range.location != NSNotFound) {
                s = [g_config.apiUrl substringToIndex:range.location];
            }else {
                s = g_config.apiUrl;
            }
            
        }
    }
    url = [NSString stringWithFormat:@"%@%@%@",s,action,param];
    
    task.url = url;
    //    task.timeOutSeconds = jx_connect_timeout;
    task.param = param;
    task.delegate = self;
    task.action = action;
    task.toView  = delegate;
    //    [url1 release];
    
    if([task.toView respondsToSelector:@selector(didServerConnectStart:)])
        [task.toView didServerConnectStart:task];
    
    if([task isImage] || [task isAudio] || [task isVideo])
        [task go];
    
    [_arrayConnections addObject:task];
    //    [task release];
    return task;
}

-(void)stopConnection:(id)toView{
    for(NSInteger i=[_arrayConnections count]-1;i>=0;i--){
        JXConnection* task = [_arrayConnections objectAtIndex:i];
        if(toView == task.toView){
            [_arrayConnections removeObjectAtIndex:i];
            [task stop];
        }
        task = nil;
    }
}
#pragma  mark   ------------------服务器数据成功----------------
-(void)requestSuccess:(JXConnection*)task
{
    if( [task isImage] ){
        [self doSaveImage:task];
        return;
    }
    if ([task isAudio] || [task isVideo]) {
        [self doSaveVideoAudio:task];
        return;
    }
    
    @autoreleasepool {
        NSString* string = task.responseData;
        //	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString* error=nil;
        
        SBJsonParser * resultParser = [[SBJsonParser alloc] init] ;
        id resultObject = [resultParser objectWithString:string];
        //    id resultObject = [resultParser objectWithData:task.responseData];
        //    [resultParser release];
        
        if( [resultObject isKindOfClass:[NSDictionary class]] ){
            int resultCode = [[resultObject objectForKey:@"resultCode"] intValue];
            if(resultCode==0 || resultCode>=1000000)
            {
                error = [resultObject objectForKey:@"resultMsg"];
                if([error length]<=0)
                    error = Localized(@"JXServer_Error");
            }
        }else{
            error = Localized(@"JXServer_ErrorReturn");
            if([string length]>=6){
                if([[string substringToIndex:6] isEqualToString:@"<html>"])
                    error = Localized(@"JXServer_ErrorSever");
            }
        }
        
        if(error){
            [self doError:task dict:resultObject resultMsg:string errorMsg:error];
        }else{
            NSLog(@"%@成功:%@",task.action,string);
            if ([task.action isEqualToString:act_getCurrentTime] || [task.action isEqualToString:act_Config]) {
                // 获取服务器时间，然后对比当前客户端时间
                // 两个接口调用，防止单个接口出现空值
                if ([[resultObject objectForKey:@"currentTime"] doubleValue] > 0) {
                    self.serverCurrentTime = [[resultObject objectForKey:@"currentTime"] doubleValue];
                    self.timeDifference = self.serverCurrentTime - ([[NSDate date] timeIntervalSince1970] *1000);
                }
                NSLog(@"currentTime: %@ - %f",task.action,self.timeDifference);
            }
            resultObject = [resultObject objectForKey:@"data"];
            NSDictionary * dict = nil;
            NSArray* array = nil;
            
            if( [resultObject isKindOfClass:[NSDictionary class]] )
                dict  = resultObject;
            if( [resultObject isKindOfClass:[NSArray class]] )
                array = resultObject;
            
            if( [task.toView respondsToSelector:@selector(didServerResultSucces:dict:array:)] )
                [task.toView didServerResultSucces:task dict:dict array:array];
            
            dict = nil;
            array = nil;
        }
        resultObject = nil;
        //    [pool release];
        [_arrayConnections removeObject:task];
    }
}

-(void)requestError:(JXConnection *)task
{
    //    NSLog(@"http失败");
    [_arrayConnections removeObject:task];
    
    if( [task.toView respondsToSelector:@selector(didServerConnectError:error:)] ){
        int n = [task.toView didServerConnectError:task error:task.error];
        if(n != hide_error){
            //            if(task.showError)
            [g_App showAlert:[NSString stringWithFormat:@"%@%@",Localized(@"JXServer_ErrorNetwork"),task.error.localizedDescription]];
        }
    }
}

-(void) doError:(JXConnection*)task dict:(NSDictionary*)dict resultMsg:(NSString*)string errorMsg:(NSString*)errorMsg{
    //    NSLog(@"%@错误:%@",task.action,string);
    
    int resultCode = [[dict objectForKey:@"resultCode"] intValue];
    if(![task.action isEqualToString:act_UserLogout] && ![task.action isEqualToString:act_OutTime]){
        if(resultCode==0 || resultCode>=1000000)
        {
            if(resultCode == 1030101 || resultCode == 1030102){//未登陆时
                
                if (isLogin || [task.action isEqualToString:act_userLoginAuto]) {
                    // 自动登录失败后要清除token ，不然会影响到手动登录
                    g_server.access_token = nil;
                    [g_default removeObjectForKey:kMY_USER_TOKEN];
                    [share_defaults removeObjectForKey:kMY_ShareExtensionToken];
                    [g_App showAlert:@"登录过期，请重新登录" delegate:self tag:11000 onlyConfirm:YES];
                }
                isLogin = NO;
                return;
            }
        }
    }
    
    int n=show_error;
    if ([task.toView respondsToSelector:@selector(didServerResultFailed:dict:)])
        n= [task.toView didServerResultFailed:task dict:dict];
    if ([task.action isEqualToString:act_OutTime]) {
        n = hide_error;
    }
    if(n != hide_error){
        //        if(task.showError)
        [g_App showAlert:[NSString stringWithFormat:@"%@",errorMsg]];
    }
}

- (void)otherUpdatePassword {
    isLogin = NO;
    g_server.access_token = nil;
    [g_default removeObjectForKey:kMY_USER_TOKEN];
    [share_defaults removeObjectForKey:kMY_ShareExtensionToken];
    [g_App showAlert:@"你的其他端账号修改了密码，需要重新登录" delegate:self tag:11000 onlyConfirm:YES];

}

-(void)doSaveImage:(JXConnection*)task{
    @try {
        [_arrayConnections removeObject:task];
        UIImage* p = [[UIImage alloc]initWithData:task.responseData];
        
        if(p==nil)
            return;
        NSString* file = [[task.action lastPathComponent] stringByDeletingPathExtension];
        NSString* ext  = [[task.action lastPathComponent] pathExtension];
        NSString* filepath;
        if([task.action rangeOfString:@"/t/"].location == NSNotFound)
            filepath = [NSString stringWithFormat:@"%@o/",tempFilePath];
        else
            filepath = [NSString stringWithFormat:@"%@t/",tempFilePath];
        [FileInfo createDir:filepath];
        
        filepath = [NSString stringWithFormat:@"%@%@@2x.%@",filepath,file,ext];
        [task.responseData writeToFile:filepath atomically:YES];
        
        //为了双倍分辨率：
        //        [p release];
        p = [[UIImage alloc]initWithContentsOfFile:filepath];
        
        //显示图像
        if(task.toView){
            
            JXImageView* iv = (JXImageView*)task.toView;
            iv.image = p;
            iv = nil;
            
        }
        //        NSLog(@"%@成功:%@",task.action,filepath);
        
        //        [p release];
    }
    @catch (NSException *exception) {
    }
    return;
}

-(void) doSaveVideoAudio:(JXConnection*)task{
    @try {
        NSString * filePath = [myTempFilePath stringByAppendingString:[[task.url stringByRemovingPercentEncoding] lastPathComponent]];
        task.downloadFile = filePath;
        BOOL success = [task.responseData writeToFile:filePath options:NSDataWritingAtomic error:nil];
        if (!success) {
            NSLog(@"文件写入失败");
        }else{
            if( [task.toView respondsToSelector:@selector(didServerResultSucces:dict:array:)] )
                [task.toView didServerResultSucces:task dict:nil array:nil];
            //            [g_notify postNotificationName:@"audiaoDownloadFinished" object:task];
        }
    } @catch (NSException *exception) {
    } @finally {
        [_arrayConnections removeObject:task];
    }
}

-(NSString*)getHeadImageOUrl:(NSString*)userId{
    NSString* dir  = [NSString stringWithFormat:@"%d",[userId intValue] % 10000];
    NSString* url  = [NSString stringWithFormat:@"%@avatar/o/%@/%@.jpg",g_config.downloadAvatarUrl,dir,userId];
    return url;
}

-(NSString*)getHeadImageTUrl:(NSString*)userId{
    NSString* dir  = [NSString stringWithFormat:@"%d",[userId intValue] % 10000];
    NSString* url  = [NSString stringWithFormat:@"%@avatar/t/%@/%@.jpg",g_config.downloadAvatarUrl,dir,userId];
    return url;
}

-(void)getHeadImageSmall:(NSString*)userId userName:(NSString *)userName imageView:(UIImageView*)iv{
    for (UIView *subView in iv.subviews) {
        [subView removeFromSuperview];
    }
    //    客服头像
    if([userId intValue]<10100 && [userId intValue]>=10000){
        iv.image = [UIImage imageNamed:[NSString stringWithFormat:@"im_10000"]];
        return;
    }
    // 支付公众号
    if ([userId intValue] == [SHIKU_TRANSFER intValue]) {
        iv.image = [UIImage imageNamed:[NSString stringWithFormat:@"shiku_transfer"]];
        return;
    }
     NSString* s;
    if([userId isKindOfClass:[NSNumber class]])
        s = [(NSNumber*)userId stringValue];
    else
        s = userId;
//    if([s length]<=0)
//        return;
    
    // 我的其他手机设备头像
    if ([s isEqualToString:ANDROID_USERID] || [s isEqualToString:IOS_USERID]) {
        iv.image = [UIImage imageNamed:@"fdy"];
        return;
    }
    // 我的电脑端头像
    if ([s isEqualToString:PC_USERID] || [s isEqualToString:MAC_USERID] || [s isEqualToString:WEB_USERID]) {
        iv.image = [UIImage imageNamed:@"feb"];
        return;
    }
    
    UIImage *placeholderImage = [UIImage imageNamed:@"avatar_normal"];
    if (iv.image) {
        placeholderImage = iv.image;
    }
    
    NSString* dir  = [NSString stringWithFormat:@"%d",[s intValue] % 10000];
    NSString* url  = [NSString stringWithFormat:@"%@avatar/t/%@/%@.jpg",g_config.downloadAvatarUrl,dir,s];
//    [iv sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"avatar_normal"] options:SDWebImageRetryFailed];
    [self getDefultHeadImage:[NSURL URLWithString:url] userId:userId userName:userName  placeholderImage:placeholderImage iv:iv];
}

-(void)getHeadImageLarge:(NSString*)userId userName:(NSString *)userName imageView:(UIImageView*)iv{
    for (UIView *subView in iv.subviews) {
        [subView removeFromSuperview];
    }
    //    客服头像
    if([userId intValue]<10100 && [userId intValue]>=10000){
        iv.image = [UIImage imageNamed:[NSString stringWithFormat:@"im_10000"]];
        return;
    }
    // 支付公众号
    if ([userId intValue] == [SHIKU_TRANSFER intValue]) {
        iv.image = [UIImage imageNamed:[NSString stringWithFormat:@"shiku_transfer"]];
        return;
    }
    NSString* s;
    if([userId isKindOfClass:[NSNumber class]])
        s = [(NSNumber*)userId stringValue];
    else
        s = userId;
//    if([s length]<=0)
//        return;
    // 我的其他手机设备头像
    if ([s isEqualToString:ANDROID_USERID]) {
        iv.image = [UIImage imageNamed:@"fdy"];
        return;
    }
    // 我的电脑端头像
    if ([s isEqualToString:PC_USERID] || [s isEqualToString:MAC_USERID]) {
        iv.image = [UIImage imageNamed:@"feb"];
        return;
    }
    NSString* dir  = [NSString stringWithFormat:@"%d",[s intValue] % 10000];
    NSString* url  = [NSString stringWithFormat:@"%@avatar/o/%@/%@.jpg",g_config.downloadAvatarUrl,dir,s];
    
    UIImage *placeholderImage = [UIImage imageNamed:@"avatar_normal"];
    if (iv.image) {
        placeholderImage = iv.image;
    }
    
//    [iv sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholderImage options:SDWebImageRetryFailed];
    [self getDefultHeadImage:[NSURL URLWithString:url] userId:userId userName:userName placeholderImage:placeholderImage iv:iv];
}

-(void)getRoomHeadImageSmall:(NSString*)userId roomId:(NSString *)roomId imageView:(UIImageView*)iv{
    for (UIView *subView in iv.subviews) {
        [subView removeFromSuperview];
    }

    if (roomId.length <= 0) {
        return;
    }
    int hashCode = [self gethashCode:userId];
    int a = abs(hashCode % 10000);
    int b = abs(hashCode % 20000);
    
    NSString *urlStr = [NSString stringWithFormat:@"%@avatar/o/%d/%d/%@.jpg",g_config.downloadAvatarUrl,a,b,userId];
    [iv sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[self roomHeadImage:userId roomId:roomId] options:SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        
    }];
    
}

-(UIImage *)roomHeadImage:(NSString *)userId roomId:(NSString *)roomId{
    UIImage *image;
    
    NSString *groupImagePath = [NSString stringWithFormat:@"%@%@/%@.%@",NSTemporaryDirectory(),g_myself.userId,userId,@"jpg"];
    if (groupImagePath && [[NSFileManager defaultManager] fileExistsAtPath:groupImagePath]) {
        return [UIImage imageWithContentsOfFile:groupImagePath];
    }
    
    //获取全部
    NSArray * allMem = [memberData fetchAllMembers:roomId];

    if(!allMem || allMem.count <= 1){
        return [UIImage imageNamed:@"groupImage"];//数据库没有值
    }
    
    NSMutableArray * userIdArr = [[NSMutableArray alloc] init];
    NSMutableArray * downLoadImageArr = [[NSMutableArray alloc] init];
    __block int finishCount = 0;
    NSString * roomIdStr = [userId mutableCopy];
    
    if (roomIdStr.length  <= 0) {
        return [UIImage imageNamed:@"groupImage"];
    }
    
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //webcache
        SDWebImageManager * manager = [SDWebImageManager sharedManager];
        for (int i = 0; (i<allMem.count) && (i<10); i++) {
            memberData * member = allMem[i];
            //取userId
            long longUserId = member.userId;
            if (longUserId >= 10000000){
                [userIdArr addObject:[NSNumber numberWithLong:longUserId]];
            }
            if(userIdArr.count >= 5)
                break;
        }
        for (NSNumber * userIdNum in userIdArr) {
            NSString* dir  = [NSString stringWithFormat:@"%ld",[userIdNum longValue] % 10000];
            NSString* url  = [NSString stringWithFormat:@"%@avatar/t/%@/%@.jpg",g_config.downloadAvatarUrl,dir,userIdNum];
            
            [manager loadImageWithURL:[NSURL URLWithString:url] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                
            } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                finishCount++;
                if(image){
                    [downLoadImageArr addObject:image];
                }
                if(error){
                    
                }
                if (downLoadImageArr.count >= 5 || finishCount >= userIdArr.count){
                    if (downLoadImageArr.count <userIdArr.count){
                        UIImage * defaultImage = [UIImage imageNamed:@"userhead"];
                        for (int i=(int)downLoadImageArr.count; i<userIdArr.count; i++) {
                            [downLoadImageArr addObject:defaultImage];
                        }
                    }
                    //生成群头像
                    image = [self combineImage:downLoadImageArr];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSDictionary * groupDict = @{@"groupHeadImage":image,@"roomJid":roomIdStr};
                        [g_notify postNotificationName:kGroupHeadImageModifyNotifaction object:groupDict];
                        
                        NSString *groupImagePath = [NSString stringWithFormat:@"%@%@/%@.%@",NSTemporaryDirectory(),g_myself.userId,roomIdStr,@"jpg"];
                        if (groupImagePath && [[NSFileManager defaultManager] fileExistsAtPath:groupImagePath]) {
                            NSError * error = nil;
                            [[NSFileManager defaultManager] removeItemAtPath:groupImagePath error:&error];
                            if (error)
                                NSLog(@"删除文件错误:%@",error);
                        }
                        [g_server saveImageToFile:image file:groupImagePath isOriginal:NO];
                    });
                }
            }];
        }
//    });
    return image;
}
- (UIImage *)combineImage:(NSArray *)imageArray {
    UIView *view5 = [JJHeaders createHeaderView:140
                                         images:imageArray];
    view5.center = CGPointMake(235, 390);
    view5.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
    
    
    CGSize s = view5.bounds.size;
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(s, YES, 1.0);
    [view5.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}



-(int)gethashCode:(NSString *)str {
    // 字符串转hash
    int hash = 0;
    for (int i = 0; i<[str length]; i++) {
        NSString *s = [str substringWithRange:NSMakeRange(i, 1)];
        char *unicode = (char *)[s cStringUsingEncoding:NSUnicodeStringEncoding];
        int charactorUnicode = 0;
        size_t length = strlen(unicode);
        for (int n = 0; n < length; n ++) {
            charactorUnicode += (int)((unicode[n] & 0xff) << (n * sizeof(char) * 8));
        }
        hash = hash * 31 + charactorUnicode;
    }
    return hash;
}

- (void)getDefultHeadImage:(NSURL *)url userId:(NSString *)userId userName:(NSString *)userName placeholderImage:(UIImage *)placeholderImage iv:(UIImageView *)iv {
    
    [iv sd_setImageWithURL:url placeholderImage:placeholderImage completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        
        if (error) {
            JXUserObject *user = [[JXUserObject sharedInstance] getUserById:userId];
            if (user.roomId.length > 0) {
                return;
            }else {
                NSString *nameStr = [NSString string];
                
                UILabel *name = [[UILabel alloc] initWithFrame:iv.bounds];
                name.layer.backgroundColor = THEMECOLOR.CGColor;
                name.textColor = [UIColor whiteColor];
                name.textAlignment = NSTextAlignmentCenter;
                name.font = SYSFONT(name.frame.size.width/3);
                if (userName.length <= 0) {
                    if ([userId intValue] == [MY_USER_ID intValue]) {
                        nameStr = MY_USER_NAME;
                    }else {
                        nameStr = user.userNickname;
                    }
                }else {
                    nameStr = userName;
                }
                name.text = [self subTextString:nameStr len:2];
                
                [iv addSubview:name];
                
                if (nameStr.length <= 0) {
                    [name removeFromSuperview];
                    iv.image = placeholderImage;
                }
            }

        }
        
//        if (iv.image.size.width != iv.image.size.height) {
//            CGRect rect;//然后，将此部分从图片中剪切出来
//            if (iv.image.size.width > iv.image.size.height) {
//                rect = CGRectMake((iv.image.size.width - iv.image.size.height) / 2, 0, iv.image.size.height, iv.image.size.height);
//            }else {
//                rect = CGRectMake(0, (iv.image.size.height - iv.image.size.width) / 2, iv.image.size.width, iv.image.size.width);
//            }
//
//            CGImageRef imageRef = CGImageCreateWithImageInRect([iv.image CGImage], rect);
//
//            UIImage *image1 = [UIImage imageWithCGImage:imageRef];
//
//            iv.image = image1;
//        }
        
    }];
    
}

-(NSString*)subTextString:(NSString*)str len:(NSInteger)len{
    if(str.length<=len)return str;
    int count=0;
    NSMutableString *sb = [NSMutableString string];
    for (NSUInteger i=str.length-1; i>0; i--) {
        NSRange range = NSMakeRange(i, 1) ;
        NSString *aStr = [str substringWithRange:range];
        count += [aStr lengthOfBytesUsingEncoding:NSUTF8StringEncoding]>1?2:1;
        [sb insertString:aStr atIndex:0];
        if(count >= len*2-1) {
            if (sb.length <= 2) {
                return [sb copy];
            }
            if (count >= len*2) {
                return [sb copy];
            }
        }
    }
    return str;
}

-(void)getImage:(NSString*)url imageView:(UIImageView*)iv{
    for (UIView *subView in iv.subviews) {
        [subView removeFromSuperview];
    }
    
    [iv sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"avatar_normal"] options:SDWebImageRefreshCached completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        
        if (iv.image.size.width != iv.image.size.height) {
            CGRect rect;//然后，将此部分从图片中剪切出来
            if (iv.image.size.width > iv.image.size.height) {
                rect = CGRectMake((iv.image.size.width - iv.image.size.height) / 2, 0, iv.image.size.height, iv.image.size.height);
            }else {
                rect = CGRectMake(0, (iv.image.size.height - iv.image.size.width) / 2, iv.image.size.width, iv.image.size.width);
            }
            
            CGImageRef imageRef = CGImageCreateWithImageInRect([iv.image CGImage], rect);
            
            UIImage *image1 = [UIImage imageWithCGImage:imageRef];
            
            iv.image = image1;
        }
    }];
    
//    //按比例缩小iv
//    float count = iv.frame.size.height / iv.image.size.height;
//
//    iv.frame = CGRectMake(0, iv.frame.origin.y, iv.image.size.width * count, iv.frame.size.height);
//
//    iv.contentMode = UIViewContentModeScaleAspectFit;
}

-(void)delHeadImage:(NSString*)userId{
    
    NSString* s1;
    //获取userId
    if([userId isKindOfClass:[NSNumber class]])
        s1 = [(NSNumber*)userId stringValue];
    else
        s1 = userId;
    
    NSString* dir1 = [NSString stringWithFormat:@"%lld",[s1 longLongValue] % 10000];
    //头像网址
    NSString* url1  = [NSString stringWithFormat:@"%@avatar/t/%@/%@.jpg",g_config.downloadAvatarUrl,dir1,s1];
    NSString* url2  = [NSString stringWithFormat:@"%@avatar/o/%@/%@.jpg",g_config.downloadAvatarUrl,dir1,s1];
    
    [[SDImageCache sharedImageCache] removeImageForKey:url1 withCompletion:nil];
    [[SDImageCache sharedImageCache] removeImageForKey:url2 withCompletion:nil];
    
//    [[SDImageCache sharedImageCache] removeImageForKey:url1];
//    [[SDImageCache sharedImageCache] removeImageForKey:url2];
}


-(void)waitStart:(UIView*)view{
    [self waitEnd:view];
    
    UIActivityIndicatorView* aiv;
    aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    aiv.center = view.center;
    //aiv.center = CGPointMake(view.bounds.size.width / 2.0f, view.bounds.size.height/2 + 30.0f);
    [aiv startAnimating];
    [view addSubview:aiv];
    //    [aiv release];
    [self performSelector:@selector(waitFree:) withObject:view afterDelay:jx_connect_timeout];
    
    [_dictWaitViews setObject:aiv forKey:[NSString stringWithFormat:@"%ld",view.tag]];
    //    NSLog(@"_dictWaitViews=%d",[_dictWaitViews count]);
}

-(void)waitEnd:(UIView*)view{
    UIActivityIndicatorView* aiv = [_dictWaitViews objectForKey:[NSString stringWithFormat:@"%ld",view.tag]];
    if(aiv)
        @try {
            [aiv stopAnimating];
            aiv.hidden = YES;
        }
    @catch (NSException *exception) {
    }
    aiv =nil;
}

-(void)waitFree:(UIView*)sender{
    NSString* s=[NSString stringWithFormat:@"%ld",sender.tag];
    UIActivityIndicatorView* aiv = [_dictWaitViews objectForKey:s];
    [_dictWaitViews removeObjectForKey:s];
    //    NSLog(@"_dictWaitViews=%d",[_dictWaitViews count]);
    
    [aiv stopAnimating];
    [aiv removeFromSuperview];
    aiv = nil;
}

-(void)showMsg:(NSString*)s{
    [g_window addSubview:_hud.view];
    [_hud setCaption:s];
    [_hud show];
    [_hud hideAfter:1.0];
}

-(void)showMsg:(NSString*)s delay:(float)delay{
    [g_window addSubview:_hud.view];
    [_hud setCaption:s];
    [_hud show];
    if (delay)
        [_hud hideAfter:delay];
    else
        [_hud hideAfter:1.0];
}

-(NSString*)getString:(NSString*)s{
    if(s == nil || ![s isKindOfClass:[NSString class]])
        return @"";
    else
        return s;
}

//获取服务器当前时间
- (void)getCurrentTimeToView:(id)toView{
    JXConnection* p = [self addTask:act_getCurrentTime param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p go];
}


#pragma mark-----登录加密
-(void)login:(JXUserObject*)user toView:(id)toView{
    
    NSLog(@"%@",g_macAddress);
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    JXConnection* p = [self addTask:act_UserLogin param:nil toView:toView];
    
    [p setPostValue:[self getMD5String:user.telephone] forKey:@"telephone"];
    [p setPostValue:user.areaCode forKey:@"areaCode"];
    [p setPostValue:user.password forKey:@"password"];
    [p setPostValue:user.verificationCode forKey:@"verificationCode"];
    [p setPostValue:@"client_credentials" forKey:@"grant_type"];
    [p setPostValue:user.model forKey:@"model"];
    [p setPostValue:user.osVersion forKey:@"osVersion"];
    [p setPostValue:g_macAddress forKey:@"serial"];
    [p setPostValue:[NSNumber numberWithDouble:self.latitude] forKey:@"latitude"];
    [p setPostValue:[NSNumber numberWithDouble:self.longitude] forKey:@"longitude"];
    [p setPostValue:user.location forKey:@"location"];
    [p setPostValue:identifier forKey:@"appId"];
    [p setPostValue:[NSNumber numberWithInt:1] forKey:@"xmppVersion"];
    
    // 登录类型 0：账号密码登录，1：短信验证码登录
    if (user.verificationCode.length > 0) {
        [p setPostValue:@1 forKey:@"loginType"];
    }else {
        [p setPostValue:@0 forKey:@"loginType"];
    }
    // 是否开启集群
    if ([g_config.isOpenCluster integerValue] == 1) {
        NSString *area = [g_default objectForKey:kLocationArea];
        [p setPostValue:area forKey:@"area"];
    }
    [p go];
}

-(BOOL)autoLogin:(id)toView{
    NSString * userId = MY_USER_ID;
    NSString * token = [[NSUserDefaults standardUserDefaults] stringForKey:kMY_USER_TOKEN];
    NSString * userName = MY_USER_NAME;
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    if([token length]<=0)
        return NO;
    
    myself.userId = userId;
    myself.userNickname = userName;
    self.access_token = token;
    
    JXConnection* p = [self addTask:act_userLoginAuto param:nil toView:toView];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:token forKey:@"access_token"];
    [p setPostValue:g_macAddress forKey:@"serial"];
    [p setPostValue:[NSNumber numberWithDouble:latitude] forKey:@"latitude"];
    [p setPostValue:[NSNumber numberWithDouble:longitude] forKey:@"longitude"];
    [p setPostValue:identifier forKey:@"appId"];
    [p setPostValue:[NSNumber numberWithInt:1] forKey:@"xmppVersion"];
    // 是否开启集群
    if ([g_config.isOpenCluster integerValue] == 1) {
        NSString *area = [g_default objectForKey:kLocationArea];
        [p setPostValue:area forKey:@"area"];
    }
    [p go];
    return YES;
}

#pragma mark----登出
-(void)logout:(NSString *)areaCode toView:(id)toView{
    JXConnection* p = [self addTask:act_UserLogout param:nil toView:toView];
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    [p setPostValue:access_token forKey:@"access_token"];
    
    [p setPostValue:[self getMD5String:myself.telephone] forKey:@"telephone"];
    [p setPostValue:areaCode forKey:@"areaCode"];
    [p setPostValue:myself.userId forKey:@"userId"];
    [p setPostValue:myself.model forKey:@"model"];
    [p setPostValue:myself.osVersion forKey:@"osVersion"];
    [p setPostValue:myself.serialNumber forKey:@"serialNumber"];
    [p setPostValue:myself.latitude forKey:@"latitude"];
    [p setPostValue:myself.longitude forKey:@"longitude"];
    [p setPostValue:myself.location forKey:@"location"];
    [p setPostValue:identifier forKey:@"appId"];
    [p setPostValue:@"ios" forKey:@"deviceKey"];
    [p go];
    
    self.lastOfflineTime = [[NSDate date] timeIntervalSince1970];
    [g_default setObject:[NSNumber numberWithLongLong:self.lastOfflineTime] forKey:kLastOfflineTime];
    [g_default synchronize];
}

-(void)outTime:(id)toView{
    JXConnection* p = [self addTask:act_OutTime param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:myself.userId forKey:@"userId"];
    
    [p go];
    
    self.lastOfflineTime = [[NSDate date] timeIntervalSince1970];
    [g_default setObject:[NSNumber numberWithLongLong:self.lastOfflineTime] forKey:kLastOfflineTime];
    [g_default synchronize];
}



-(void)doGetUserIdList:(NSMutableDictionary*)map array:(NSArray*)array{
    //    for(int i=0;i<[map count];i++){
    //        [[[map allValues] objectAtIndex:i] release];
    //        [[[map allKeys] objectAtIndex:i] release];
    //    }
    [map removeAllObjects];
    
    for(int i=0;i<[array count];i++){
        NSDictionary* p = [array objectAtIndex:i];
        [map setObject:[[p objectForKey:@"keyId"] copy] forKey:[[p objectForKey:@"userId"] copy]];
        p = nil;
    }
}

-(void)doLoginOK:(NSDictionary*)dict user:(JXUserObject*)user{
    
    isLogin = YES;
    myself.password = user.password;
    myself.telephone = user.telephone;
    myself.userId = user.userId;
    myself.companyId = user.companyId;
    myself.userNickname = user.userNickname;
    myself.areaCode = user.areaCode;
    myself.myInviteCode = user.myInviteCode;
    myself.role = user.role;
    [self doSaveUser:dict];//保存用户信息
    [self performSelector:@selector(setPushChannelId:) withObject:[BPush getChannelId] afterDelay:2];
    if([dict objectForKey:@"access_token"])
        self.access_token = [dict objectForKey:@"access_token"];
    
    [self saveDefaultSetting];//写到配置表
    
    // 创建系统号
    [[JXUserObject sharedInstance] createSystemFriend];
    self.multipleLogin = [JXMultipleLogin sharedInstance];
    [FileInfo createDir:myTempFilePath];
#if TAR_IM
#ifdef Meeting_Version
    [g_meeting startMeeting];
    if ([g_default objectForKey:@"voipToken"]) {
        [g_server pkpushSetToken:[g_default objectForKey:@"voipToken"] deviceId:nil isVoip:1 toView:nil];
    }
#endif
#endif
    if (![g_config.isOpenAPNSorJPUSH boolValue]) {
        // 上传推送apnsToken
        if ([g_default objectForKey:@"apnsToken"]) {
            [g_server pkpushSetToken:[g_default objectForKey:@"apnsToken"] deviceId:nil isVoip:0 toView:nil];
        }
    }else {
        // 上传jPush专用RegistrationID
        if ([g_default objectForKey:@"jPushRegistrationID"]) {
            [g_server jPushSetToken:[g_default objectForKey:@"jPushRegistrationID"] toView:self];
        }
    }
    
    
    if ([g_myself.telephone isEqualToString:@"18938880001"]) {
        myself.phoneDic = [myself getPhoneDic];
    }
    
    // 登录成功后清除过期聊天记录
    [[JXUserObject sharedInstance] deleteUserChatRecordTimeOutMsg];
    
    // 上传通讯录
    _addressBook = [JXAddressBook sharedInstance];
    [_addressBook uploadAddressBookContacts];
    
    
    // 系统登录成功
    [g_notify postNotificationName:kSystemLoginNotifaction object:self userInfo:nil];
}

-(void)doSaveUser:(NSDictionary*)dict{
    if([dict objectForKey:@"userId"])
        myself.userId = [[dict objectForKey:@"userId"] stringValue];
    if([dict objectForKey:@"nickname"])
        myself.userNickname = [dict objectForKey:@"nickname"];
    if([dict objectForKey:@"companyId"])
        myself.companyId = [dict objectForKey:@"companyId"];
    if([dict objectForKey:@"password"])
        myself.password = [dict objectForKey:@"password"];
    if([dict objectForKey:@"telephone"])
        myself.telephone = [dict objectForKey:@"telephone"];
    if([dict objectForKey:@"areaCode"])
        myself.areaCode = [dict objectForKey:@"areaCode"];
    if([dict objectForKey:@"myInviteCode"])
        myself.myInviteCode = [dict objectForKey:@"myInviteCode"];
    if ([dict objectForKey:@"role"]) {
        myself.role = [dict objectForKey:@"role"];
    }
    if([[dict objectForKey:@"login"] objectForKey:@"offlineTime"]){
        long long lastOfflineTime = [[g_default objectForKey:kLastOfflineTime] longLongValue];
        if (lastOfflineTime > 0) {
            self.lastOfflineTime = lastOfflineTime;
        }else {
            self.lastOfflineTime = [[[dict objectForKey:@"login"] objectForKey:@"offlineTime"] longLongValue];
        }
        //        NSDate * da = [NSDate dateWithTimeIntervalSince1970:self.lastOfflineTime];
        //        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        //        [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
        //        NSDate *destDate= [dateFormatter dateFromString:<#(nonnull NSString *)#>];
    }
    if ([dict objectForKey:@"friendCount"]) {
        myself.friendCount   = [dict objectForKey:@"friendCount"];
    }
    
    if ([dict objectForKey:@"settings"]) {
        myself.chatRecordTimeOut = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"chatRecordTimeOut"]];
        myself.chatSyncTimeLen = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"chatSyncTimeLen"]];
        myself.groupChatSyncTimeLen = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"groupChatSyncTimeLen"]];
        myself.friendsVerify = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"friendsVerify"]];
        myself.isEncrypt = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"isEncrypt"]];
        myself.isTyping = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"isTyping"]];
        myself.isVibration = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"isVibration"]];
        myself.multipleDevices = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"multipleDevices"]];
        myself.isUseGoogleMap = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"isUseGoogleMap"]];
        myself.filterCircleUserIds = [[dict objectForKey:@"settings"] objectForKey:@"filterCircleUserIds"];
    }
    
    myself.countryId = [dict objectForKey:@"countryId"];
    myself.provinceId = [dict objectForKey:@"provinceId"];
    myself.cityId = [dict objectForKey:@"cityId"];
    myself.areaId = [dict objectForKey:@"areaId"];
    myself.level = [dict objectForKey:@"level"];
    myself.vip = [dict objectForKey:@"vip"];
    myself.userType = [dict objectForKey:@"userType"];
    myself.status = [dict objectForKey:@"status"];
    myself.attCount = [dict objectForKey:@"attCount"];
    myself.fansCount = [dict objectForKey:@"fansCount"];
    myself.sex    = [dict objectForKey:@"sex"];
    myself.userDescription   = [dict objectForKey:@"description"];
    myself.isupdate = [dict objectForKey:@"isupdate"];
//    myself.isMultipleLogin = [dict objectForKey:@"multipleDevices"];
    myself.isPayPassword = [dict objectForKey:@"payPassword"];

    myself.birthday = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"birthday"] longLongValue]];
    myself.timeCreate = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"createTime"] longLongValue]];
    myself.account = [dict objectForKey:@"account"];
    myself.setAccountCount = [dict objectForKey:@"setAccountCount"];
}

-(void)saveDefaultSetting{
    //    [g_App saveMeetingId:myself.userId];
    //初始化一个供App Groups使用的NSUserDefaults对象
    //写入数据
    [g_default setObject:self.access_token forKey:kMY_USER_TOKEN];
    [share_defaults setValue:self.access_token forKey:kMY_ShareExtensionToken];
    if (!IsStringNull(myself.password)) {
        [g_default setObject:myself.password forKey:kMY_USER_PASSWORD];
        [share_defaults setValue:myself.password forKey:kMY_ShareExtensionPassword];
    }
    [g_default setObject:myself.telephone forKey:kMY_USER_LoginName];
    if (!IsStringNull(myself.userId)) {
        [g_default setObject:myself.userId forKey:kMY_USER_ID];
        [share_defaults setValue:myself.userId forKey:kMY_ShareExtensionUserId];
    }
    if (!IsStringNull(myself.areaCode)) {
        [g_default setObject:myself.areaCode forKey:kMY_USER_AREACODE];
    }
    [g_default setObject:myself.companyId forKey:kMY_USER_COMPANY_ID];
    [g_default setObject:myself.userNickname forKey:kMY_USER_NICKNAME];
    [g_default setObject:myself.myInviteCode forKey:kMY_USER_INVITECODE];
    [g_default setObject:myself.role forKey:kMY_USER_ROLE];
}

-(void)readDefaultSetting{
    myself.password = [g_default objectForKey:kMY_USER_PASSWORD];
    myself.telephone = [g_default objectForKey:kMY_USER_LoginName];
    myself.userId = MY_USER_ID;
    myself.companyId =[g_default objectForKey:kMY_USER_COMPANY_ID];
    self.access_token = [g_default objectForKey:kMY_USER_TOKEN];
    myself.myInviteCode = [g_default objectForKey:kMY_USER_INVITECODE];
    myself.role = [g_default objectForKey:kMY_USER_ROLE];
    myself.userNickname = MY_USER_NAME;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    NSString * URLString = [NSString stringWithString:@"http://itunes.apple.com/cn/app/id333206289?mt=8"];
    
    if (alertView.tag == 11000) {
        [g_xmpp.reconnectTimer invalidate];
        g_xmpp.reconnectTimer = nil;
        g_xmpp.isReconnect = NO;
        [g_xmpp logout];
        NSLog(@"XMPP ---- jxserver");
        
        if (![g_navigation.rootViewController isKindOfClass:[loginVC class]]) {
            
            [self showLogin];
        }else {
            loginVC *vc = (loginVC *)g_navigation.rootViewController;
            
            vc.btn.userInteractionEnabled = YES;
            vc.launchImageView.hidden = YES;
        }
    }else {
        NSString * URLString = @"http://itunes.apple.com/cn/app/id333206289?mt=8";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
    }
}


-(long)getUserIdFromDict:(NSDictionary*)dict key:(NSString*)key{
    NSArray* p=[dict allKeys];
    long j=-1;
    for(int i=0;i<[p count];i++){
        if([key isEqualToString:[p objectAtIndex:i]]){
            j=i;
            break;
        }
    }
    
    if(j<[p count] && j>=0)
        j = [[[dict allValues] objectAtIndex:j] intValue];
    else
        j = 0;
    p = nil;
    return j;
}

-(void) showAddMoney:(NSDictionary*)dict msg:(NSString*)s autoHide:(BOOL)autoHide{
    if(s == nil)
        s = Localized(@"JXServer_OK");
    if([dict objectForKey:@"thisMoney"] != nil){
        int n = [[dict objectForKey:@"thisMoney"] intValue];
        self.count_money += n;
        if(self.count_money<0)
            self.count_money = 0;
        if(n>=0)
            s = [NSString stringWithFormat:@"%@,%@%d%@%ld",s,Localized(@"JXServer_SystemSend1"),n,Localized(@"JXServer_SystemSend2"),self.count_money];
        else
            s = [NSString stringWithFormat:@"%@,%@%d%@%ld",s,Localized(@"JXServer_SystemSend3"),n,Localized(@"JXServer_SystemSend2"),self.count_money];
    }
    if(autoHide)
        [g_App.jxServer showMsg:s];
    else
        [g_App showAlert:s];
}


-(void)bindUser:(NSString*)blogId type:(int)type toView:(id)toView{
    [self addTask:act_BindUser param:[NSString stringWithFormat:@"?blogId=%@&type=%d",blogId,type] toView:toView];
}

-(void)unBindUser:(NSString*)blogId type:(int)type toView:(id)toView{
    [self addTask:act_UnBindUser param:[NSString stringWithFormat:@"?blogId=%@&type=%d",blogId,type] toView:toView];
}

-(void)selectBindUser:(id)toView{
}

-(void)checkPhone:(NSString*)phone areaCode:(NSString *)areaCode verifyType:(int)verifyType toView:(id)toView{
    JXConnection* p = [self addTask:act_CheckPhone param:nil toView:toView];
    [p setPostValue:phone forKey:@"telephone"];
    [p setPostValue:areaCode forKey:@"areaCode"];
    if (verifyType > 0) {
        [p setPostValue:[NSNumber numberWithInt:verifyType] forKey:@"verifyType"];
    }
    [p go];
}

-(NSString*)getMD5String:(NSString*)s{
    if(s==nil)
        return nil;
//    if(s.length == 32){
//        return s;
//    }
    const char *buf = [s cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char md[MD5_DIGEST_LENGTH];
    unsigned long n = strlen(buf);
    MD5(buf, n, md);
    
    printf("%s md5: ", buf);
    char t[50]="",p[50]="";
    int i;
    for(i = 0; i< MD5_DIGEST_LENGTH; i++){
        sprintf(t, "%02x", md[i]);
        strcat(p, t);
        printf("%02x", md[i]);
    }
    s = [NSString stringWithCString:p encoding:NSUTF8StringEncoding];
    printf("/n");
    //    NSLog(@"%@",s);
    return s;
}
#pragma mark-----注册密码加密
-(void)registerUser:(JXUserObject*)user inviteCode:(NSString *)inviteCode workexp:(int)workexp diploma:(int)diploma isSmsRegister:(BOOL)isSmsRegister toView:(id)toView{
    JXConnection* p;
    if (self.openId.length <= 0) {
        p = [self addTask:act_Register param:nil toView:toView];
    }else {
        p = [self addTask:act_registerSDK param:nil toView:toView];
        [p setPostValue:[NSNumber numberWithInteger:self.thirdType] forKey:@"type"];
        [p setPostValue:self.openId forKey:@"loginInfo"];
    }
    [p setPostValue:user.telephone forKey:@"telephone"];
    [p setPostValue:user.password forKey:@"password"];
    [p setPostValue:user.areaCode forKey:@"areaCode"];
    [p setPostValue:user.userType forKey:@"userType"];
    [p setPostValue:user.userNickname forKey:@"nickname"];
    [p setPostValue:user.userDescription forKey:@"description"];
    [p setPostValue:[NSNumber numberWithLongLong:[user.birthday timeIntervalSince1970]] forKey:@"birthday"];
    [p setPostValue:user.sex forKey:@"sex"];
    [p setPostValue:user.companyId forKey:@"companyId"];
    [p setPostValue:user.countryId forKey:@"countryId"];
    [p setPostValue:user.provinceId forKey:@"provinceId"];
    if ([user.cityId integerValue] > 0) {
        [p setPostValue:user.cityId forKey:@"cityId"];
    }else {
        [p setPostValue:[NSNumber numberWithInt:self.cityId] forKey:@"cityId"];
    }
    [p setPostValue:user.areaId forKey:@"areaId"];
    [p setPostValue:user.model forKey:@"model"];
    [p setPostValue:user.osVersion forKey:@"osVersion"];
    [p setPostValue:user.serialNumber forKey:@"serialNumber"];
    [p setPostValue:user.latitude forKey:@"latitude"];
    [p setPostValue:user.longitude forKey:@"longitude"];
    [p setPostValue:user.location forKey:@"location"];
    [p setPostValue:[NSNumber numberWithInt:workexp] forKey:@"w"];
    [p setPostValue:[NSNumber numberWithInt:diploma] forKey:@"d"];
    [p setPostValue:[NSNumber numberWithInt:1] forKey:@"xmppVersion"];
    [p setPostValue:[NSNumber numberWithInt:(isSmsRegister ? 1 : 0)] forKey:@"isSmsRegister"];
    [p setPostValue:inviteCode forKey:@"inviteCode"];
    [p go];
}

-(void)checkPhone:(NSString*)phone toView:(id)toView{
    JXConnection* p = [self addTask:act_CheckPhone param:nil toView:toView];
    [p setPostValue:phone forKey:@"telephone"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(NSString *)getImgCode:(NSString*)telephone areaCode:(NSString *)areaCode{
    if(telephone==nil)
        return nil;
    //    http://192.168.0.168:8080/getImgCode?telephone=8618318722019
    NSString *s;
    NSRange range = [g_config.apiUrl rangeOfString:@"config"];
    if (range.location != NSNotFound) {
        s = [g_config.apiUrl substringToIndex:range.location];
    }else {
        s = g_config.apiUrl;
    }
    return [NSString stringWithFormat:@"%@%@?telephone=%@%@",s,act_GetCode,areaCode,telephone];
}

-(void)updateUser:(JXUserObject*)user toView:(id)toView{
    JXConnection* p = [self addTask:act_UserUpdate param:nil toView:toView];
    [p setPostValue:user.userType forKey:@"userType"];
    [p setPostValue:user.userNickname forKey:@"nickname"];
    [p setPostValue:user.userDescription forKey:@"description"];
    [p setPostValue:[NSNumber numberWithLongLong:[user.birthday timeIntervalSince1970]] forKey:@"birthday"];
    [p setPostValue:user.sex forKey:@"sex"];
    [p setPostValue:user.countryId forKey:@"countryId"];
    [p setPostValue:user.provinceId forKey:@"provinceId"];
    [p setPostValue:user.cityId forKey:@"cityId"];
    [p setPostValue:user.areaId forKey:@"areaId"];
    [p setPostValue:[self getMD5String:user.payPassword] forKey:@"payPassword"];
    [p setPostValue:user.msgBackGroundUrl forKey:@"msgBackGroundUrl"];
    [p setPostValue:access_token forKey:@"access_token"];
//    [p setPostValue:user.isMultipleLogin forKey:@"multipleDevices"];
    [p go];
}

-(void)updateShikuNum:(JXUserObject*)user toView:(id)toView {
    JXConnection* p = [self addTask:act_UserUpdate param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:user.account forKey:@"account"];
    [p go];
}

-(void)getUser:(NSString*)theUserId toView:(id)toView{
    if(theUserId==nil)
        return;
    JXConnection* p = [self addTask:act_UserGet param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:theUserId forKey:@"userId"];
    [p go];
}


-(void)searchUser:(JXUserObject*)user minAge:(int)minAge maxAge:(int)maxAge page:(int)page toView:(id)toView{
    //    JXConnection* p = [self addTask:act_UserSearch param:[NSString stringWithFormat:@"?pageIndex=%d&pageSize=%d&access_token=fc77f5174c82416aa2c84ba1b96f7939",page,jx_page_size] toView:toView];
    JXConnection* p = [self addTask:act_UserSearch param:[NSString stringWithFormat:@"?pageIndex=%d&pageSize=%d",page,jx_page_size] toView:toView];
    
    [p setPostValue:user.telephone forKey:@"telephone"];
    [p setPostValue:user.userNickname forKey:@"nickname"];
    [p setPostValue:user.userDescription forKey:@"description"];
    [p setPostValue:[NSNumber numberWithLongLong:[user.birthday timeIntervalSince1970]] forKey:@"birthday"];
    [p setPostValue:user.sex forKey:@"sex"];
    [p setPostValue:user.countryId forKey:@"countryId"];
    [p setPostValue:user.provinceId forKey:@"provinceId"];
    [p setPostValue:user.cityId forKey:@"cityId"];
    [p setPostValue:user.areaId forKey:@"areaId"];
    [p setPostValue:user.latitude forKey:@"latitude"];
    [p setPostValue:user.longitude forKey:@"longitude"];
    [p setPostValue:user.location forKey:@"location"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

// 搜索公众号列表
- (void)searchPublicWithKeyWorld:(NSString *)keyWorld limit:(int)limit page:(int)page toView:(id)toView{
    JXConnection* p = [self addTask:act_PublicSearch param:nil toView:toView];
    [p setPostValue:keyWorld forKey:@"keyWorld"];
    [p setPostValue:[NSNumber numberWithInt:limit] forKey:@"limit"];
    [p setPostValue:[NSNumber numberWithInt:page] forKey:@"page"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}


-(void)reportUser:(NSString *)toUserId roomId:(NSString *)roomId webUrl:(NSString *)webUrl reasonId:(NSNumber *)reasonId toView:(id)toView{
    JXConnection* p = [self addTask:act_Report param:nil toView:toView];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:reasonId forKey:@"reason"];
    [p setPostValue:webUrl forKey:@"webUrl"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)saveImageToFile:(UIImage*)image file:(NSString*)file isOriginal:(BOOL)isOriginal{
    if(![[NSFileManager defaultManager] fileExistsAtPath:file]){
        NSData *data = [Photo image2Data:image isOriginal:isOriginal];
        [data writeToFile:file atomically:YES];
        data = nil;
    }
}

-(void)saveDataToFile:(NSData*)data file:(NSString*)file{
    if(![[NSFileManager defaultManager] fileExistsAtPath:file]){
        [data writeToFile:file atomically:YES];
        data = nil;
    }
}


-(void) uploadFile:(NSArray*)files audio:(NSString*)audio video:(NSString*)video file:(NSString*)file type:(int)type validTime:(NSString *)validTime timeLen:(int)timeLen toView:(id)toView{
    JXConnection* p = [self addTask:act_UploadFile param:nil toView:toView];
//    if (type == 4 && audio.length > 0) {
//        p = [self addTask:act_UploadVoiceServlet param:nil toView:toView];
//    }
//    [p setPostValue:[NSNumber numberWithInt:type] forKey:@"uploadFlag"];
    [p setPostValue:[NSNumber numberWithInt:type] forKey:@"type"];
    [p setPostValue:myself.userId forKey:@"userId"];
    if (!validTime) {
        validTime = @"-1";
    }
    [p setPostValue:validTime forKey:@"validTime"];
    NSString* s;
    for(int i=0;i<[files count];i++){
        s = [NSString stringWithFormat:@"file%d.jpg",i+1];
        [p setData:UIImageJPEGRepresentation([files objectAtIndex:i], 0.5) forKey:s messageId:nil];
    }
    [p setPostValue:@(timeLen) forKey:@"length"];
    [p setData:[NSData dataWithContentsOfFile:audio] forKey:[audio lastPathComponent] messageId:nil];
    if ([NSData dataWithContentsOfFile:video]) {
        [p setData:[NSData dataWithContentsOfFile:video] forKey:[video lastPathComponent] messageId:nil];
    }else {
        [p setData:[NSData dataWithContentsOfURL:[NSURL URLWithString:video]] forKey:[video lastPathComponent] messageId:nil];
    }
    [p setData:[NSData dataWithContentsOfFile:file] forKey:[file lastPathComponent] messageId:nil];
    [p go];
}
//上传文件到服务器（传路径）
-(void)uploadFile:(NSString*)file validTime:(NSString *)validTime messageId:(NSString *)messageId toView:(id)toView{
    if(!file)
        return;
    if(![[NSFileManager defaultManager] fileExistsAtPath:file])
        return;
    
    JXConnection* p = [self addTask:act_UploadFile param:nil toView:toView];
//    [p setPostValue:[NSNumber numberWithInt:2] forKey:@"uploadFlag"];
    [p setPostValue:MY_USER_ID forKey:@"userId"];
    if (!validTime) {
        validTime = @"-1";
    }
    [p setPostValue:validTime forKey:@"validTime"];
    [p setData:[NSData dataWithContentsOfFile:file] forKey:[file lastPathComponent] messageId:nil];
    p.userData = [file lastPathComponent];
    p.messageId = messageId;
    [p go];
}
// 上传音频文件
-(void)UploadVoiceServlet:(NSString*)file validTime:(NSString *)validTime messageId:(NSString *)messageId toView:(id)toView{
    if(!file)
        return;
    if(![[NSFileManager defaultManager] fileExistsAtPath:file])
        return;
    
    JXConnection* p = [self addTask:act_UploadVoiceServlet param:nil toView:toView];
    //    [p setPostValue:[NSNumber numberWithInt:2] forKey:@"uploadFlag"];
    [p setPostValue:MY_USER_ID forKey:@"userId"];
    if (!validTime) {
        validTime = @"-1";
    }
    [p setPostValue:validTime forKey:@"validTime"];
    [p setData:[NSData dataWithContentsOfFile:file] forKey:[file lastPathComponent] messageId:nil];
    p.userData = [file lastPathComponent];
    p.messageId = messageId;
    [p go];
}

// 上传文件（传data）
-(void)uploadFileData:(NSData*)data key:(NSString *)key toView:(id)toView{
    if(!data)
        return;
    if (!key) {
        return;
    }
    
    JXConnection* p = [self addTask:act_UploadFile param:nil toView:toView];
    //    [p setPostValue:[NSNumber numberWithInt:2] forKey:@"uploadFlag"];
    [p setPostValue:myself.userId forKey:@"userId"];
    [p setData:data forKey:key messageId:nil];
    p.userData = key;
    [p go];
}

-(void)uploadHeadImage:(NSString*)userId image:(UIImage*)image toView:(id)toView{
    JXConnection* p = [self addTask:act_UploadHeadImage param:nil toView:toView];
    [p setPostValue:userId forKey:@"userId"];
    [p setData:UIImageJPEGRepresentation(image, 0.5) forKey:@"file.jpg" messageId:nil];
    [p go];
}

//获取用户余额
-(void)getUserMoenyToView:(id)toView{
    JXConnection* p = [self addTask:act_getUserMoeny param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    
    [p go];
}

//获取签名
- (void)getSign:(NSString *)price payType:(NSInteger)payType toView:(id)toView{
    JXConnection *p = [self addTask:act_getSign param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:price forKey:@"price"];
    [p setPostValue:[NSNumber numberWithInteger:payType] forKey:@"payType"];
    [p go];
}
//获取支付宝授权authInfo
- (void)getAliPayAuthInfoToView:(id)toView{
    JXConnection *p = [self addTask:act_getAliPayAuthInfo param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p go];
}
//保存支付宝用户Id
- (void)aliPayUserId:(NSString *)aliUserId toView:(id)toView{
    JXConnection *p = [self addTask:act_aliPayUserId param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:aliUserId forKey:@"aliUserId"];
    [p go];
}
//支付宝提现
- (void)alipayTransfer:(NSString *)amount secret:(NSString *)secret time:(NSNumber *)time toView:(id)toView{
    JXConnection *p = [self addTask:act_alipayTransfer param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:amount forKey:@"amount"];
    [p setPostValue:secret forKey:@"secret"];
    [p setPostValue:time forKey:@"time"];
    [p go];
}

//二维码支付
- (void)codePayment:(NSString *)paymentCode money:(NSString *)money time:(long)time desc:(NSString *)desc secret:(NSString *)secret toView:(id)toView {
    JXConnection *p = [self addTask:act_codePayment param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:paymentCode forKey:@"paymentCode"];
    [p setPostValue:money forKey:@"money"];
    [p setPostValue:[NSNumber numberWithLong:time] forKey:@"time"];
    [p setPostValue:desc forKey:@"desc"];
    [p setPostValue:secret forKey:@"secret"];

    [p go];
}

//二维码收款
- (void)codeReceipt:(NSString *)toUserId money:(NSString *)money time:(long)time desc:(NSString *)desc secret:(NSString *)secret toView:(id)toView {
    JXConnection *p = [self addTask:act_codeReceipt param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:money forKey:@"money"];
    [p setPostValue:[NSNumber numberWithLong:time] forKey:@"time"];
    [p setPostValue:desc forKey:@"desc"];
    [p setPostValue:secret forKey:@"secret"];
    
    [p go];
}


//接受转账
- (void)getTransfer:(NSString *)transferId toView:(id)toView{
    JXConnection *p = [self addTask:act_receiveTransfer param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:transferId forKey:@"id"];
    [p go];
}

//获取转账信息
- (void)transferDetail:(NSString *)transferId toView:(id)toView{
    JXConnection *p = [self addTask:act_getTransferInfo param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:transferId forKey:@"id"];
    [p go];
}

//好友交易记录明细
- (void)getConsumeRecordList:(NSString *)toUserId pageIndex:(int)pageIndex pageSize:(int)pageSize toView:(id)toView{
    JXConnection *p = [self addTask:act_getConsumeRecordList param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:[NSNumber numberWithInt:pageIndex] forKey:@"pageIndex"];
    [p setPostValue:[NSNumber numberWithInt:pageSize] forKey:@"pageSize"];

    [p go];
}


//转账
- (void)transferUserId:(NSString *)toUserId money:(NSString *)money remark:(NSString *)remark time:(long)time secret:(NSString *)secret toView:(id)toView{
    JXConnection *p = [self addTask:act_sendTransfer param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:money forKey:@"money"];
    [p setPostValue:remark forKey:@"remark"];
    [p setPostValue:[NSString stringWithFormat:@"%ld",time] forKey:@"time"];
    [p setPostValue:secret forKey:@"secret"];
    [p go];
}


//直接充值
- (void)userRecharge:(NSString *)price toView:(id)toView{
    JXConnection *p = [self addTask:act_userRechagrge param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:[NSNumber numberWithDouble:[price doubleValue]] forKey:@"money"];
    [p setPostValue:[NSNumber numberWithInteger:1] forKey:@"type"];
    [p go];
}

//发红包
- (void)sendRedPacket:(double)money type:(int)type count:(int)count greetings:(NSString *)greet roomJid:(NSString*)roomJid toUserId:(NSString *)toUserId time:(long)time secret:(NSString *)secret toView:(id)toView{
    JXConnection *p = [self addTask:act_sendRedPacket param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:roomJid forKey:@"roomJid"];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:[NSNumber numberWithDouble:money] forKey:@"money"];
    [p setPostValue:[NSNumber numberWithInteger:type] forKey:@"type"];
    [p setPostValue:[NSNumber numberWithInteger:count] forKey:@"count"];
    [p setPostValue:greet forKey:@"greetings"];
    [p setPostValue:[NSString stringWithFormat:@"%ld",time] forKey:@"time"];
    [p setPostValue:secret forKey:@"secret"];
    [p go];
}


//发红包(新版)
- (void)sendRedPacketV1:(double)money type:(int)type count:(int)count greetings:(NSString *)greet roomJid:(NSString*)roomJid toUserId:(NSString *)toUserId time:(long)time secret:(NSString *)secret toView:(id)toView{
    JXConnection *p = [self addTask:act_sendRedPacketV1 param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:roomJid forKey:@"roomJid"];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:[NSNumber numberWithDouble:money] forKey:@"moneyStr"];
    [p setPostValue:[NSNumber numberWithInteger:type] forKey:@"type"];
    [p setPostValue:[NSNumber numberWithInteger:count] forKey:@"count"];
    [p setPostValue:greet forKey:@"greetings"];
    [p setPostValue:[NSString stringWithFormat:@"%ld",time] forKey:@"time"];
    [p setPostValue:secret forKey:@"secret"];
    [p go];
}


//交易记录
- (void)getConsumeRecord:(int)pageIndex toView:(id)toView{
    JXConnection *p = [self addTask:act_consumeRecord param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:[NSNumber numberWithInteger:pageIndex] forKey:@"pageIndex"];
    //    [p setPostValue:[NSNumber numberWithInteger:10] forKey:@"pageSize"];
    [p go];
}

// 获得发送的红包
- (void)redPacketGetSendRedPacketListIndex:(NSInteger)index toView:(id)toView {
    JXConnection *p = [self addTask:act_redPacketGetSendRedPacketList param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:[NSNumber numberWithInteger:index] forKey:@"pageIndex"];
    //    [p setPostValue:[NSNumber numberWithInteger:10] forKey:@"pageSize"];
    [p go];
}
// 获得接收的红包
- (void)redPacketGetRedReceiveListIndex:(NSInteger)index toView:(id)toView {
    JXConnection *p = [self addTask:act_redPacketGetRedReceiveList param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:[NSNumber numberWithInteger:index] forKey:@"pageIndex"];

    [p go];
}
// 红包回复
- (void)redPacketReply:(NSString *)redPacketId content:(NSString *)content toView:(id)toView {
    JXConnection *p = [self addTask:act_redPacketReply param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:redPacketId forKey:@"id"];
    [p setPostValue:content forKey:@"reply"];

    [p go];
}

#pragma mark-----删除服务器消息
- (void)readDeleteMsg:(JXMessageObject *)msg toView:(id)toView{
    JXConnection *p = [self addTask:act_readDelMsg param:nil toView:toView];
    [p setPostValue:msg.messageId forKey:@"messageId"];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p go];
    
}

- (void)getRedPacket:(NSString *)redPacketId toView:(id)toView{
    JXConnection *p = [self addTask:act_getRedPacket param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:redPacketId forKey:@"id"];
    [p go];
}

- (void)openRedPacket:(NSString *)redPacketId toView:(id)toView{
    JXConnection *p = [self addTask:act_openRedPacket param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:redPacketId forKey:@"id"];
    [p go];
}

-(void)addPhoto:(NSString*)photos toView:(id)toView{
    JXConnection* p = [self addTask:act_PhotoAdd param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:photos forKey:@"photos"];
    [p go];
}

-(void)delPhoto:(NSString*)photoId toView:(id)toView{
    JXConnection* p = [self addTask:act_PhotoDel param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:photoId forKey:@"photoId"];
    [p go];
}

-(void)updatePhoto:(NSString*)photoId oUrl:(NSString*)oUrl tUrl:(NSString*)tUrl toView:(id)toView{
    JXConnection* p = [self addTask:act_PhotoMod param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:photoId forKey:@"photoId"];
    [p setPostValue:oUrl forKey:@"oUrl"];
    [p setPostValue:tUrl forKey:@"tUrl"];
    [p go];
}

-(void)listPhoto:(NSString*)theUserId toView:(id)toView{
    JXConnection* p = [self addTask:act_PhotoList param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:theUserId forKey:@"userId"];
    [p go];
}

-(void)setHeadImage:(NSString*)photoId toView:(id)toView{
    JXConnection* p = [self addTask:act_SetHeadImage param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:photoId forKey:@"photoId"];
    [p go];
}

-(void)setGroupAvatarServlet:(NSString*)roomId image:(UIImage *)image toView:(id)toView{
    JXConnection* p = [self addTask:act_SetGroupAvatarServlet param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:roomId forKey:@"jid"];
    [p setData:UIImageJPEGRepresentation(image, 0.5) forKey:@"file.jpg" messageId:nil];
    [p go];
}

- (NSString *) getPhotoLocalPath:(NSString*)s
{
    return [NSString stringWithFormat:@"%@/tmp/%@", NSHomeDirectory(), [s lastPathComponent]];
}

-(void)resetPwd:(NSString*)telephone areaCode:(NSString *)areaCode randcode:(NSString*)randcode newPwd:(NSString*)newPassword toView:(id)toView{

    if(telephone==nil || newPassword==nil || randcode==nil)
        return;

    JXConnection* p = [self addTask:act_PwdReset param:nil toView:toView];
    [p setPostValue:telephone forKey:@"telephone"];
    [p setPostValue:randcode forKey:@"randcode"];
    [p setPostValue:areaCode forKey:@"areaCode"];
    [p setPostValue:[self getMD5String:newPassword] forKey:@"newPassword"];
    [p go];
}

-(void)updatePwd:(NSString*)telephone areaCode:(NSString *)areaCode oldPwd:(NSString*)oldPassword newPwd:(NSString*)newPassword toView:(id)toView{
    if(telephone==nil || newPassword==nil || oldPassword==nil)
        return;
    JXConnection* p = [self addTask:act_PwdUpdate param:nil toView:toView];
    [p setPostValue:telephone forKey:@"telephone"];
    [p setPostValue:areaCode forKey:@"areaCode"];
    [p setPostValue:[self getMD5String:oldPassword] forKey:@"oldPassword"];
    [p setPostValue:[self getMD5String:newPassword] forKey:@"newPassword"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

//-(void)sendSMS:(NSString*)telephone toView:(id)toView{
//
//    if(telephone==nil)
//        return;
//    JXConnection* p = [self addTask:act_SendSMS param:nil toView:toView];
//    [p setPostValue:telephone forKey:@"telephone"];
//    [p go];
//
//}
#pragma mark---发送验证码
-(void)sendSMS:(NSString*)telephone areaCode:(NSString *)areaCode isRegister:(BOOL)isRegister imgCode:(NSString *)imgCode toView:(id)toView{
    if(telephone==nil)
        return;
    JXConnection* p = [self addTask:act_SendSMS param:nil toView:toView];
    [p setPostValue:telephone forKey:@"telephone"];
    [p setPostValue:areaCode forKey:@"areaCode"];
    NSString *language;
    if ([g_constant.sysLanguage isEqualToString:@"en"]) {
        language = @"en";
    }else{
        language = @"zh";
    }
    [p setPostValue:language forKey:@"language"];
    p.timeout = 30;
    [p setPostValue:[NSNumber numberWithBool:isRegister] forKey:@"isRegister"];
    if(imgCode==nil || imgCode.length <= 0)
        return;
    [p setPostValue:imgCode forKey:@"imgCode"];
    [p setPostValue:@"1" forKey:@"version"];
    [p go];
    
}
#pragma mark---创建公司
- (void)createCompany:(NSString *)companyName toView:(id)toView{
    JXConnection *p = [self addTask:act_creatCompany param:nil toView:toView];
    [p setPostValue:companyName forKey:@"companyName"];
    [p setPostValue:g_myself.userId forKey:@"createUserId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
#pragma mark---退出公司/解散公司
- (void)quitCompany:(NSString *)companyId toView:(id)toView{
    JXConnection *p = [self addTask:act_companyQuit param:nil toView:toView];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:g_myself.userId forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
#pragma mark---自动查找公司
- (void)getCompanyAuto:(id)toView{
    JXConnection *p = [self addTask:act_getCompany param:nil toView:toView];
    [p setPostValue:g_myself.userId forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
#pragma mark---指定管理员
- (void)setManager:(NSString *)userId toView:(id)toView{
    JXConnection *p = [self addTask:act_setManager param:nil toView:toView];
    [p setPostValue:userId forKey:@"managerId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
#pragma mark---管理员列表
- (void)getCompanyManager:(NSString *)companyId toView:(id)toView{
    JXConnection *p = [self addTask:act_managerList param:nil toView:toView];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
#pragma mark---修改公司名
- (void)updataCompanyName:(NSString *)companyName companyId:(NSString *)companyId toView:(id)toView{
    JXConnection *p = [self addTask:act_updataCompanyName param:nil toView:toView];
    [p setPostValue:companyName forKey:@"companyName"];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}
#pragma mark---更改公司公告
- (void)changeCompanyNotice:(NSString *)noticeContent companyId:(NSString *)companyId toView:(id)toView{
    JXConnection *p = [self addTask:act_changeNotice param:nil toView:toView];
    [p setPostValue:noticeContent forKey:@"noticeContent"];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
#pragma mark---查找公司
- (void)seachCompany:(NSString *)keyworld toView:(id)toView{
    JXConnection *p = [self addTask:act_seachCompany param:nil toView:toView];
    [p setPostValue:keyworld forKey:@"keyworld"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}
#pragma mark---删除公司
- (void)deleteCompany:(NSString *)companyId userId:(NSString *)userId toView:(id)toView{
    JXConnection *p = [self addTask:act_deleteCompany param:nil toView:toView];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}
#pragma mark---创建部门
- (void)createDepartment:(NSString *)companyId parentId:(NSString *)parentId departName:(NSString *)departName createUserId:(NSString *)createUserId toView:(id)toView{
    JXConnection *p = [self addTask:act_createDepartment param:nil toView:toView];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:parentId forKey:@"parentId"];
    [p setPostValue:g_myself.userId forKey:@"createUserId"];
    [p setPostValue:departName forKey:@"departName"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}
#pragma mark---修改部门名
- (void)updataDepartmentName:(NSString *)departmentName departmentId:(NSString *)departmentId toView:(id)toView{
    JXConnection *p = [self addTask:act_updataDepartmentName param:nil toView:toView];
    [p setPostValue:departmentName forKey:@"dpartmentName"];
    [p setPostValue:departmentId forKey:@"departmentId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}
#pragma mark---删除部门
- (void)deleteDepartment:(NSString *)departmentId toView:(id)toView{
    JXConnection *p = [self addTask:act_deleteDepartment param:nil toView:toView];
    [p setPostValue:departmentId forKey:@"departmentId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}
#pragma mark---添加员工
- (void)addEmployee:(NSArray *)userIdArray companyId:(NSString *)companyId departmentId:(NSString *)departmentId roleArray:(NSArray *)roleArray toView:(id)toView{
    JXConnection *p = [self addTask:act_addEmployee param:nil toView:toView];
    [p setPostValue:[userIdArray componentsJoinedByString:@","] forKey:@"userId"];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:departmentId forKey:@"departmentId"];
    if (roleArray) {
        [p setPostValue:roleArray forKey:@"roleArray"];
    }
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}
#pragma mark---删除员工
- (void)deleteEmployee:(NSString *)departmentId userId:(NSString *)userId toView:(id)toView{
    JXConnection *p = [self addTask:act_deleteEmployee param:nil toView:toView];
    [p setPostValue:userId forKey:@"userIds"];
    [p setPostValue:departmentId forKey:@"departmentId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}
#pragma mark---更改员工部门
- (void)modifyDpart:(NSString *)userId companyId:(NSString *)companyId newDepartmentId:(NSString *)newDepartmentId toView:(id)toView{
    JXConnection *p = [self addTask:act_modifyDpart param:nil toView:toView];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:newDepartmentId forKey:@"newDepartmentId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}
#pragma mark---部门员工列表
- (void)empList:(NSString *)departmentId toView:(id)toView{
    JXConnection *p = [self addTask:act_empList param:nil toView:toView];
    [p setPostValue:departmentId forKey:@"departmentId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
#pragma mark---更改员工角色
- (void)modifyRole:(NSString *)userId companyId:(NSString *)companyId role:(NSNumber *)role toView:(id)toView{
    JXConnection *p = [self addTask:act_modifyRole param:nil toView:toView];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:role forKey:@"role"];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
#pragma mark---更改员工职位(头衔)
- (void)modifyPosition:(NSString *)position companyId:(NSString *)companyId userId:(NSString *)userId toView:(id)toView{
    JXConnection *p = [self addTask:act_modifyPosition param:nil toView:toView];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:position forKey:@"position"];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
#pragma mark---公司列表
- (void)companyListPage:(NSNumber *)pageIndex toView:(id)toView{
    JXConnection *p = [self addTask:act_companyList param:nil toView:toView];
    [p setPostValue:pageIndex forKey:@"pageIndex"];
    [p setPostValue:[NSNumber numberWithInt:12] forKey:@"pageSize"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}
#pragma mark---部门列表
- (void)departmentListPage:(NSNumber *)pageIndex companyId:(NSString *)companyId toView:(id)toView{
    JXConnection *p = [self addTask:act_departmentList param:nil toView:toView];
    [p setPostValue:pageIndex forKey:@"pageIndex"];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
#pragma mark---员工列表
- (void)employeeListPage:(NSNumber *)pageIndex companyId:(NSString *)companyId toView:(id)toView{
    JXConnection *p = [self addTask:act_employeeList param:nil toView:toView];
    [p setPostValue:pageIndex forKey:@"pageIndex"];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
#pragma mark---获取公司详情
- (void)getCompanyInfo:(NSString *)companyId toView:(id)toView{
    JXConnection *p = [self addTask:act_companyInfo param:nil toView:toView];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}
#pragma mark---员工详情
- (void)getEmployeeInfo:(NSString *)userId toView:(id)toView{
    JXConnection *p = [self addTask:act_employeeInfo param:nil toView:toView];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}
#pragma mark---部门详情
- (void)getDepartmentInfo:(NSString *)departmentId toView:(id)toView{
    JXConnection *p = [self addTask:act_dpartmentInfo param:nil toView:toView];
    [p setPostValue:departmentId forKey:@"departmentId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}
#pragma mark---公司员工数
- (void)getCompanyCount:(NSString *)companyId toView:(id)toView{
    JXConnection *p = [self addTask:act_companyNum param:nil toView:toView];
    [p setPostValue:companyId forKey:@"companyId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
#pragma mark---部门员工数
- (void)getDepartmentCount:(NSString *)departmentId toView:(id)toView{
    JXConnection *p = [self addTask:act_dpartmentNum param:nil toView:toView];
    [p setPostValue:departmentId forKey:@"departmentId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
-(void)getMessage:(NSString*)messageId toView:(id)toView{
    if([messageId length]<=0)
        return;
    JXConnection* p = [self addTask:act_MsgGet param:nil toView:toView];
    [p setPostValue:messageId forKey:@"messageId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)listMessage:(int)type messageId:(NSString*)messageId toView:(id)toView{
    JXConnection* p = [self addTask:act_MsgList param:[NSString stringWithFormat:@"?pageSize=%d",jx_page_size] toView:toView];
    [p setPostValue:messageId forKey:@"messageId"];
    [p setPostValue:[NSNumber numberWithInt:type] forKey:@"type"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)addMessage:(NSString*)text type:(int)type data:(NSDictionary*)dict flag:(int)flag visible:(int)visible lookArray:(NSArray *)lookArray coor:(CLLocationCoordinate2D)coor location:(NSString *)location remindArray:(NSArray *)remindArray lable:(NSString *)lable isAllowComment:(int)isAllowComment toView:(id)toView{
    if(text==nil)
        return;
    NSMutableArray* array;
    
    NSString * jsonFiles=nil;
    //    NSMutableArray* a=[[NSMutableArray alloc]init];
    SBJsonWriter * OderJsonwriter = [SBJsonWriter new];
    
    array = [dict objectForKey:@"images"];
    NSString * jsonImages = nil;
    if([array count]>0){
        [self doCheckUploadResult:array];
        jsonImages = [OderJsonwriter stringWithObject:array];
        jsonFiles = jsonImages;
    }
    
    array = [dict objectForKey:@"videos"];
    NSString * jsonVideos=nil;
    if([array count]>0){
        [self doCheckUploadResult:array];
        jsonVideos = [OderJsonwriter stringWithObject:array];
        jsonFiles = jsonVideos;
        //        for(int i =0;i<[array count];i++)
        //            [a addObject:[[array objectAtIndex:i] objectForKey:@"oUrl"]];
        //        jsonVideos = [OderJsonwriter stringWithObject:a];
    }
    
    array = [dict objectForKey:@"audios"];
    NSString * jsonAudios=nil;
    if([array count]>0){
        [self doCheckUploadResult:array];
        jsonAudios = [OderJsonwriter stringWithObject:array];
        jsonFiles = jsonAudios;
        //        for(int i =0;i<[array count];i++)
        //            [a addObject:[[array objectAtIndex:i] objectForKey:@"oUrl"]];
        //        jsonAudios = [OderJsonwriter stringWithObject:a];
    }
    
    array = [dict objectForKey:@"others"];
    if([array count]>0){
        [self doCheckUploadResult:array];
        jsonFiles = [OderJsonwriter stringWithObject:array];
        //        for(int i =0;i<[array count];i++)
        //            [a addObject:[[array objectAtIndex:i] objectForKey:@"oUrl"]];
        //        jsonAudios = [OderJsonwriter stringWithObject:a];
    }
    
    
    array = nil;
    
    JXConnection* p = [self addTask:act_MsgAdd param:nil toView:toView];
    [p setPostValue:[NSNumber numberWithInt:type] forKey:@"type"];
    [p setPostValue:[NSNumber numberWithInt:flag] forKey:@"flag"];
    [p setPostValue:[NSNumber numberWithInt:visible] forKey:@"visible"];
    [p setPostValue:[NSNumber numberWithInt:1] forKey:@"cityId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:text forKey:@"text"];
    if (type == 5) {
        [p setPostValue:jsonFiles forKey:@"files"];
    }else if (type == 6) {
        [p setPostValue:[dict objectForKey:@"sdkUrl"] forKey:@"sdkUrl"];
        [p setPostValue:[dict objectForKey:@"sdkIcon"] forKey:@"sdkIcon"];
        [p setPostValue:[dict objectForKey:@"sdkTitle"] forKey:@"sdkTitle"];
    }
    else {
        [p setPostValue:jsonImages forKey:@"images"];
        [p setPostValue:jsonAudios forKey:@"audios"];
        [p setPostValue:jsonVideos forKey:@"videos"];
    }
    [p setPostValue:myself.model forKey:@"model"];
    [p setPostValue:myself.osVersion forKey:@"osVersion"];
    [p setPostValue:myself.serialNumber forKey:@"serialNumber"];
    [p setPostValue:lable forKey:@"lable"];
    [p setPostValue:[NSNumber numberWithInt:isAllowComment] forKey:@"isAllowComment"];
    
    if (location.length > 0) {
        [p setPostValue:[NSNumber numberWithDouble:coor.latitude] forKey:@"latitude"];
        [p setPostValue:[NSNumber numberWithDouble:coor.longitude] forKey:@"longitude"];
        [p setPostValue:location forKey:@"location"];
    }
    
    if (lookArray.count >0 && (visible == 3 || visible == 4)) {
        NSString * lookStr = [lookArray componentsJoinedByString:@","];
        NSString * arrayTitle = nil;
        switch (visible) {
            case 3:
                arrayTitle = @"userLook";
                break;
            case 4:
                arrayTitle = @"userNotLook";
                break;
//            case 5:
//                arrayTitle = @"userRemindLook";
//                break;
                
            default:
                arrayTitle = @"";
                break;
        }
        [p setPostValue:lookStr forKey:arrayTitle];
    }
    
    if (remindArray.count > 0) {
        [p setPostValue:[remindArray componentsJoinedByString:@","] forKey:@"userRemindLook"];
    }
    
    [p go];
}

-(void)forwardMessage:(NSString*)text messageId:(NSString*)messageId toView:(id)toView{
    if(text==nil)
        return;
    JXConnection* p = [self addTask:act_Msgforward param:nil toView:toView];
    [p setPostValue:text forKey:@"text"];
    [p setPostValue:messageId forKey:@"messageId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:myself.model forKey:@"model"];
    [p setPostValue:myself.osVersion forKey:@"osVersion"];
    [p setPostValue:myself.serialNumber forKey:@"serialNumber"];
    [p setPostValue:myself.latitude forKey:@"latitude"];
    [p setPostValue:myself.longitude forKey:@"longitude"];
    [p setPostValue:myself.location forKey:@"location"];
    [p go];
}

-(void)delMessage:(NSString*)messageId toView:(id)toView{
    if(messageId==nil)
        return;
    JXConnection* p = [self addTask:act_MsgDel param:nil toView:toView];
    [p setPostValue:messageId forKey:@"messageId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)listComment:(NSString*)messageId pageIndex:(NSInteger)pageIndex pageSize:(NSInteger)pageSize commentId:(NSString*)commentId  toView:(id)toView{
    JXConnection* p = [self addTask:act_CommentList param:nil toView:toView];
    [p setPostValue:messageId forKey:@"messageId"];
    if (pageIndex == 0) { // 第一次请求才传该参数
        [p setPostValue:commentId forKey:@"commentId"];
    }
    [p setPostValue:[NSNumber numberWithInteger:pageIndex] forKey:@"pageIndex"];
    [p setPostValue:[NSNumber numberWithInteger:pageSize] forKey:@"pageSize"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)listPraise:(NSString*)messageId pageIndex:(NSInteger)pageIndex pageSize:(NSInteger)pageSize praiseId:(NSString*)praiseId toView:(id)toView{
    JXConnection* p = [self addTask:act_PraiseList param:nil toView:toView];
    [p setPostValue:messageId forKey:@"messageId"];
    if (pageIndex == 0) { // 第一次请求才传该参数
        [p setPostValue:praiseId forKey:@"praiseId"];
    }
    [p setPostValue:[NSNumber numberWithInteger:pageIndex] forKey:@"pageIndex"];
    [p setPostValue:[NSNumber numberWithInteger:pageSize] forKey:@"pageSize"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)listGift:(NSString*)messageId giftId:(NSString*)giftId toView:(id)toView{
    JXConnection* p = [self addTask:act_GiftList param:[NSString stringWithFormat:@"?pageSize=%d",jx_page_size] toView:toView];
    [p setPostValue:giftId forKey:@"giftId"];
    [p setPostValue:messageId forKey:@"messageId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)addPraise:(NSString*)messageId toView:(id)toView{
    if(messageId==nil)
        return;
    JXConnection* p = [self addTask:act_PraiseAdd param:nil toView:toView];
    [p setPostValue:messageId forKey:@"messageId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)delPraise:(NSString*)messageId toView:(id)toView{
    if(messageId==nil)
        return;
    JXConnection* p = [self addTask:act_PraiseDel param:nil toView:toView];
    [p setPostValue:messageId forKey:@"messageId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)addGift:(NSString*)messageId gifts:(NSString*)gifts toView:(id)toView{
    if(messageId==nil)
        return;
    JXConnection* p = [self addTask:act_GiftAdd param:nil toView:toView];
    [p setPostValue:messageId forKey:@"messageId"];
    [p setPostValue:gifts forKey:@"gifts"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)addComment:(WeiboReplyData*)reply toView:(id)toView{
    if(reply.messageId==nil)
        return;
    JXConnection* p = [self addTask:act_CommentAdd param:nil toView:toView];
    [p setPostValue:reply.messageId forKey:@"messageId"];
    [p setPostValue:reply.body forKey:@"body"];
    [p setPostValue:reply.toUserId forKey:@"toUserId"];
    [p setPostValue:reply.toNickName forKey:@"toNickname"];
    [p setPostValue:reply.toBody forKey:@"toBody"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)delComment:(NSString*)messageId commentId:(NSString*)commentId toView:(id)toView{
    if(messageId==nil)
        return;
    JXConnection* p = [self addTask:act_CommentDel param:nil toView:toView];
    [p setPostValue:messageId forKey:@"messageId"];
    [p setPostValue:commentId forKey:@"commentId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)addFriend:(NSString*)toUserId toView:(id)toView{
    if(toUserId==nil)
        return;
    JXConnection* p = [self addTask:act_FriendAdd param:nil toView:toView];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)delFriend:(NSString*)toUserId toView:(id)toView{
    if(toUserId==nil)
        return;
    JXConnection* p = [self addTask:act_FriendDel param:nil toView:toView];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)listFriend:(int)page userId:(NSString*)userId toView:(id)toView{
    JXConnection* p = [self addTask:act_FriendList param:[NSString stringWithFormat:@"?pageIndex=%d&pageSize=%d",page,jx_page_size] toView:toView];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)listFans:(int)page userId:(NSString*)userId toView:(id)toView{
    JXConnection* p = [self addTask:act_FansList param:[NSString stringWithFormat:@"?pageIndex=%d&pageSize=%d",page,jx_page_size] toView:toView];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)listAttention:(int)page userId:(NSString*)userId toView:(id)toView{
    JXConnection* p = [self addTask:act_AttentionList param:[NSString stringWithFormat:@"?pageIndex=%d&pageSize=%d",page,jx_page_size] toView:toView];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}




-(void)addAttention:(NSString*)toUserId fromAddType:(int)fromAddType toView:(id)toView{
    if(toUserId==nil)
        return;
    JXConnection* p = [self addTask:act_AttentionAdd param:nil toView:toView];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:@(fromAddType) forKey:@"fromAddType"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)delAttention:(NSString*)toUserId toView:(id)toView{
    if(toUserId==nil)
        return;
    JXConnection* p = [self addTask:act_AttentionDel param:nil toView:toView];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)addBlacklist:(NSString*)toUserId toView:(id)toView{
    if(toUserId==nil)
        return;
    JXConnection* p = [self addTask:act_BlacklistAdd param:nil toView:toView];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)delBlacklist:(NSString*)toUserId toView:(id)toView{
    if(toUserId==nil)
        return;
    JXConnection* p = [self addTask:act_BlacklistDel param:nil toView:toView];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)listBlacklist:(int)page toView:(id)toView{
    JXConnection* p = [self addTask:act_BlacklistList param:[NSString stringWithFormat:@"?pageIndex=%d&pageSize=%d",page,jx_page_size] toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)setFriendName:(NSString*)toUserId noteName:(NSString*)noteName describe:(NSString *)describe toView:(id)toView{
    if(toUserId==nil)
        return;
    JXConnection* p = [self addTask:act_FriendRemark param:nil toView:toView];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:noteName forKey:@"remarkName"];
    [p setPostValue:describe forKey:@"describe"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

// 修改好友的聊天记录过期时间
-(void)friendsUpdate:(NSString *)toUserId chatRecordTimeOut:(NSString *)chatRecordTimeOut toView:(id)toView {
    if(toUserId==nil)
        return;
    JXConnection* p = [self addTask:act_FriendsUpdate param:nil toView:toView];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:chatRecordTimeOut forKey:@"chatRecordTimeOut"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)getNewMessage:(NSString*)messageId toView:(id)toView{
    JXConnection* p = [self addTask:act_MsgListNew param:[NSString stringWithFormat:@"?pageSize=%d",jx_page_size*5] toView:toView];
    [p setPostValue:messageId forKey:@"messageId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

//设置是否需要好友验证
-(void)changeFriendSetting:(NSString *)friendsVerify allowAtt:(NSString *)allowAtt allowGreet:(NSString*)allowGreet key:(NSString *)key value:(NSString *)value toView:(id)toView{
    JXConnection * p = [self addTask:act_SettingsUpdate param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:friendsVerify forKey:@"friendsVerify"];
    [p setPostValue:allowAtt forKey:@"allowAtt"];
    [p setPostValue:allowGreet forKey:@"allowGreet"];
    [p setPostValue:value forKey:key];
    [p go];
}
//获取好友验证设置
- (void)getFriendSettings:(NSString *)userID toView:(id)toView{
    JXConnection * p = [self addTask:act_Settings param:nil toView:toView];
    [p setPostValue:userID forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

//离线期间调用的接口
- (void)offlineOperation:(double)offlineTime toView:(id)toView{
    JXConnection * p = [self addTask:act_offlineOperation param:nil toView:toView];
    [p setPostValue:[NSNumber numberWithDouble:offlineTime] forKey:@"offlineTime"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)getUserMessage:(NSString*)userId messageId:(NSString*)messageId toView:(id)toView{
    JXConnection* p = [self addTask:act_MsgListUser param:[NSString stringWithFormat:@"?pageSize=%d",jx_page_size*5] toView:toView];
    [p setPostValue:messageId forKey:@"messageId"];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)getSetting:(id)toView{
    JXConnection* p = [self addTask:act_Config param:nil toView:toView];
    NSString *area = [g_default objectForKey:kLocationArea];
    area = [self httpDataStr:area];
    [p setPostValue:area forKey:@"area"];
    [p go];
    
}

//http传输过程的数据转换
- (NSString *)httpDataStr:(NSString *)str {
    
    NSString *outputStr = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)str,NULL,(CFStringRef)@"!*'();:@&=+$/?%#[] ",kCFStringEncodingUTF8));
    return outputStr;
}

-(long)user_id{
    return [myself.userId intValue];
}

-(void)doCheckUploadResult:(NSMutableArray*)a{
    NSMutableDictionary* p;
    for(NSInteger i=[a count]-1;i>=0;i--){
        p = [a objectAtIndex:i];
        if([[p objectForKey:@"status"]intValue]!=1){
            [a removeObjectAtIndex:i];
            continue;
        }
        [p removeObjectForKey:@"status"];
//        [p removeObjectForKey:@"oFileName"];
    }
}

-(void)showLogin{
    // 显示手动登录界面， 隐藏悬浮窗
    g_App.subWindow.hidden = YES;

    [g_default removeObjectForKey:kMY_USER_PASSWORD];
    [g_default removeObjectForKey:kMY_USER_TOKEN];
    [share_defaults removeObjectForKey:kMY_ShareExtensionToken];
    loginVC* vc = [loginVC alloc];
    vc.isAutoLogin = NO;
    vc.isSwitchUser= NO;
    vc = [vc init];
    g_navigation.rootViewController = vc;
//    [g_navigation.subViews removeAllObjects];
//    g_mainVC = nil;
//    [g_navigation pushViewController:vc];
//    g_App.window.rootViewController = vc;
//    [g_App.window makeKeyAndVisible];

//    loginVC* vc = [loginVC alloc];
//    vc.isAutoLogin = NO;
//    vc.isSwitchUser= YES;
//    vc = [vc init];
//    [g_window addSubview:vc.view];
//    [g_navigation pushViewController:vc];
}

-(void)showWebPage:(NSString*)url title:(NSString*)s{
    webpageVC* webVC = [webpageVC alloc];
    webVC.title = s;
    webVC.isSend = YES;
    webVC.url   = url;
    webVC = [webVC init];
    [g_navigation.navigationView addSubview:webVC.view];
//    [g_navigation pushViewController:vc animated:YES];
}


-(void)listPays:(id)toView{
    JXConnection* p = [self addTask:act_payList param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)order:(int)goodId count:(int)count type:(int)rechargeType toView:(id)toView{
    JXConnection* p = [self addTask:act_payBuy param:nil toView:toView];
    [p setPostValue:[NSString stringWithFormat:@"%d",goodId] forKey:@"goodsId"];
    [p setPostValue:[NSString stringWithFormat:@"%d",count] forKey:@"count"];
    [p setPostValue:[NSString stringWithFormat:@"%d",rechargeType] forKey:@"rechargeType"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)listBizs:(id)toView{
    JXConnection* p = [self addTask:act_bizList param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)buy:(int)goodId count:(int)count toView:(id)toView{
    JXConnection* p = [self addTask:act_bizBuy param:nil toView:toView];
    [p setPostValue:[NSString stringWithFormat:@"%d",goodId] forKey:@"goodsId"];
    [p setPostValue:[NSString stringWithFormat:@"%d",count] forKey:@"count"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
#pragma mark----新用户
- (void)nearbyNewUser:(searchData*)search nearOnly:(BOOL)bNearOnly page:(int)page toView:(id)toView{
    JXConnection *p = [self addTask:act_nearNewUser param:[NSString stringWithFormat:@"?pageSize=%d&pageIndex=%d",jx_page_size,page] toView:toView];
    [p setPostValue:[NSNumber numberWithInt:search.minAge] forKey:@"minAge"];
    [p setPostValue:[NSNumber numberWithInt:search.maxAge] forKey:@"maxAge"];
    if(search.sex != -1)
        [p setPostValue:[NSNumber numberWithInt:search.sex] forKey:@"sex"];
    if(bNearOnly){
        [p setPostValue:[NSNumber numberWithDouble:longitude] forKey:@"longitude"];
        [p setPostValue:[NSNumber numberWithDouble:latitude] forKey:@"latitude"];
    }
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}

-(void)nearbyUser:(searchData*)search nearOnly:(BOOL)bNearOnly lat:(double)lat lng:(double)lng page:(int)page toView:(id)toView{
    JXConnection* p = [self addTask:act_nearbyUser param:[NSString stringWithFormat:@"?pageSize=%d&pageIndex=%d",12,page] toView:toView];
    if (search) {
        [p setPostValue:search.name forKey:@"nickname"];
//        [p setPostValue:[NSNumber numberWithInt:search.minAge] forKey:@"minAge"];
//        [p setPostValue:[NSNumber numberWithInt:search.maxAge] forKey:@"maxAge"];
        if(search.sex != -1)
            [p setPostValue:[NSNumber numberWithInt:search.sex] forKey:@"sex"];
    }
    
    if(bNearOnly && (lat != 0) &&(lng != 0)){
        [p setPostValue:[NSNumber numberWithDouble:lng] forKey:@"longitude"];
        [p setPostValue:[NSNumber numberWithDouble:lat] forKey:@"latitude"];
    }else if (bNearOnly){
        [p setPostValue:[NSNumber numberWithDouble:longitude] forKey:@"longitude"];
        [p setPostValue:[NSNumber numberWithDouble:latitude] forKey:@"latitude"];
    }
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
    
}

-(void)addRoom:(roomData*)room isPublic:(BOOL)isPublic isNeedVerify:(BOOL)isNeedVerify category:(NSInteger)category toView:(id)toView{
    JXConnection* p = [self addTask:act_roomAdd param:nil toView:toView];
    [p setPostValue:room.roomJid forKey:@"jid"];
    [p setPostValue:room.name forKey:@"name"];
    [p setPostValue:room.desc forKey:@"desc"];
    [p setPostValue:[NSNumber numberWithInt:(isPublic ? 1:0)] forKey:@"isLook"];
    [p setPostValue:[NSNumber numberWithInt:(isNeedVerify ? 1:0)] forKey:@"isNeedVerify"];
    [p setPostValue:[NSNumber numberWithInt:(room.showMember ? 1:0)] forKey:@"showMember"];
    [p setPostValue:[NSNumber numberWithInt:(room.allowSendCard ? 1:0)] forKey:@"allowSendCard"];
    [p setPostValue:[NSNumber numberWithInt:(room.allowInviteFriend ? 1:0)] forKey:@"allowInviteFriend"];
    [p setPostValue:[NSNumber numberWithInt:(room.allowUploadFile ? 1:0)] forKey:@"allowUploadFile"];
    [p setPostValue:[NSNumber numberWithInt:(room.allowConference ? 1:0)] forKey:@"allowConference"];
    [p setPostValue:[NSNumber numberWithInt:(room.allowSpeakCourse ? 1:0)] forKey:@"allowSpeakCourse"];
    [p setPostValue:[NSNumber numberWithInt:(room.allowHostUpdate ? 1:0)] forKey:@"allowHostUpdate"];
    if (room.showRead) {
        [p setPostValue:[NSNumber numberWithInt:1] forKey:@"showRead"];
    }else{
        [p setPostValue:[NSNumber numberWithInt:0] forKey:@"showRead"];
    }
    [p setPostValue:[NSNumber numberWithInt:room.countryId] forKey:@"countryId"];
    [p setPostValue:[NSNumber numberWithInt:room.provinceId] forKey:@"provinceId"];
    [p setPostValue:[NSNumber numberWithInt:room.cityId] forKey:@"cityId"];
    [p setPostValue:[NSNumber numberWithInt:room.areaId] forKey:@"areaId"];
    [p setPostValue:[NSNumber numberWithDouble:room.longitude] forKey:@"longitude"];
    [p setPostValue:[NSNumber numberWithDouble:room.latitude] forKey:@"latitude"];
    [p setPostValue:[NSNumber numberWithInteger:category] forKey:@"category"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)delRoom:(NSString*)roomId toView:(id)toView{
    JXConnection* p = [self addTask:act_roomDel param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)getRoom:(NSString*)roomId toView:(id)toView{
    JXConnection* p = [self addTask:act_roomGet param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
//    [p setPostValue:[NSNumber numberWithInt:kRoomMemberListNum] forKey:@"pageSize"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)updateRoom:(roomData*)room toView:(id)toView{
    JXConnection* p = [self addTask:act_roomSet param:nil toView:toView];
    [p setPostValue:room.roomId forKey:@"roomId"];
    [p setPostValue:room.name forKey:@"roomName"];
    [p setPostValue:room.chatRecordTimeOut forKey:@"chatRecordTimeOut"];
    [p setPostValue:[NSNumber numberWithLong:room.talkTime] forKey:@"talkTime"];
    [p setPostValue:[NSNumber numberWithInt:room.maxCount] forKey:@"maxUserSize"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)updateRoomMaxUserSize:(roomData*)room toView:(id)toView{
    JXConnection* p = [self addTask:act_roomSet param:nil toView:toView];
    [p setPostValue:room.roomId forKey:@"roomId"];
    [p setPostValue:[NSNumber numberWithInt:room.maxCount] forKey:@"maxUserSize"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

- (void)updateRoom:(roomData *)room key:(NSString *)key value:(NSString *)value toView:(id)toView {
    JXConnection* p = [self addTask:act_roomSet param:nil toView:toView];
    [p setPostValue:room.roomId forKey:@"roomId"];
    [p setPostValue:access_token forKey:@"access_token"];
    if (value) {
        [p setPostValue:value forKey:key];
    }
    
    [p go];
}

-(void)updateRoomShowRead:(roomData*)room key:(NSString *)key value:(BOOL)value toView:(id)toView{
    JXConnection* p = [self addTask:act_roomSet param:nil toView:toView];
    [p setPostValue:room.roomId forKey:@"roomId"];
    if (value) {
        [p setPostValue:[NSNumber numberWithInt:1] forKey:key];
    }else {
        [p setPostValue:[NSNumber numberWithInt:0] forKey:key];
    }
    
//
//    if (room.showRead)
//        [p setPostValue:[NSNumber numberWithInt:1] forKey:@"showRead"];
//    else
//        [p setPostValue:[NSNumber numberWithInt:0] forKey:@"showRead"];
//
//
//    [p setPostValue:[NSNumber numberWithInt:room.isLook ? 1 : 0] forKey:@"isLook"];
//    [p setPostValue:[NSNumber numberWithInt:room.isNeedVerify ? 1 : 0] forKey:@"isNeedVerify"];
//    [p setPostValue:[NSNumber numberWithInt:room.showMember ? 1 : 0] forKey:@"showMember"];
//    [p setPostValue:[NSNumber numberWithInt:room.allowSendCard ? 1 : 0] forKey:@"allowSendCard"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)updateRoomDesc:(roomData*)room toView:(id)toView{
    JXConnection* p = [self addTask:act_roomSet param:nil toView:toView];
    [p setPostValue:room.roomId forKey:@"roomId"];
    [p setPostValue:room.desc forKey:@"desc"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)updateRoomNotify:(roomData*)room toView:(id)toView{
    JXConnection* p = [self addTask:act_roomSet param:nil toView:toView];
    [p setPostValue:room.roomId forKey:@"roomId"];
    [p setPostValue:room.note forKey:@"notice"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)updateNotice:(NSString*)roomId noticeId:(NSString *)noticeId noticeContent:(NSString *)noticeContent toView:(id)toView{
    JXConnection* p = [self addTask:act_updateNotice param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:noticeId forKey:@"noticeId"];
    [p setPostValue:noticeContent forKey:@"noticeContent"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)listRoom:(int)page roomName:(NSString *)roomName toView:(id)toView{
    JXConnection* p = [self addTask:act_roomList param:[NSString stringWithFormat:@"?pageIndex=%d",page] toView:toView];
    [p setPostValue:roomName forKey:@"roomName"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)listHisRoom:(int)page pageSize:(int)pageSize toView:(id)toView{
    
    //    JXConnection* p = [self addTask:act_roomListHis param:[NSString stringWithFormat:@"?pageSize=%d&pageIndex=%d",jx_page_size,page] toView:toView];
    JXConnection* p = [self addTask:act_roomListHis param:[NSString stringWithFormat:@"?pageSize=%d&pageIndex=%d",pageSize,page] toView:toView];
    [p setPostValue:[NSNumber numberWithInt:0] forKey:@"type"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)listRoomMember:(NSString*)roomId page:(int)page toView:(id)toView{
    JXConnection* p = [self addTask:act_roomMemberList param:[NSString stringWithFormat:@"?pageSize=%d&pageIndex=%d",jx_page_size,page] toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)getRoomMember:(NSString*)roomId userId:(long)userId toView:(id)toView{
    JXConnection* p = [self addTask:act_roomMemberGet param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:[NSNumber numberWithLong:userId] forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)delRoomMember:(NSString*)roomId userId:(long)userId toView:(id)toView{
    JXConnection* p = [self addTask:act_roomMemberDel param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:[NSNumber numberWithLong:userId] forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)setRoomMember:(NSString*)roomId member:(memberData*)member toView:(id)toView{
    if(!member)
        return;
    JXConnection* p = [self addTask:act_roomMemberSet param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:[NSNumber numberWithLong:member.userId] forKey:@"userId"];
    //    [p setPostValue:[NSNumber numberWithInt:member.role] forKey:@"role"];
    //    [p setPostValue:[NSNumber numberWithInt:member.sub] forKey:@"sub"];
    if (member.lordRemarkName.length > 0) {
        [p setPostValue:member.lordRemarkName forKey:@"remarkName"];
    }else {
        [p setPostValue:member.userNickName forKey:@"nickname"];
    }
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)setDisableSay:(NSString*)roomId member:(memberData*)member  toView:(id)toView{
    JXConnection* p = [self addTask:act_roomMemberSet param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:[NSNumber numberWithLongLong:member.talkTime] forKey:@"talkTime"];
    [p setPostValue:[NSNumber numberWithLong:member.userId] forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)setRoomAdmin:(NSString*)roomId userId:(NSString*)userId type:(int)type  toView:(id)toView{
    JXConnection* p = [self addTask:act_roomSetAdmin param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:userId forKey:@"touserId"];
    [p setPostValue:[NSNumber numberWithInt:type] forKey:@"type"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
// 指定监控人、隐身人
-(void)setRoomInvisibleGuardian:(NSString*)roomId userId:(NSString*)userId type:(int)type toView:(id)toView{
    JXConnection* p = [self addTask:act_roomSetInvisibleGuardian param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:userId forKey:@"touserId"];
    [p setPostValue:[NSNumber numberWithInt:type] forKey:@"type"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

// 转让群主
- (void)roomTransfer:(NSString *)roomId toUserId:(NSString *)toUserId toView:(id)toView {
    JXConnection* p = [self addTask:act_roomTransfer param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)addRoomMember:(NSString*)roomId userId:(NSString*)userId nickName:(NSString*)nickName toView:(id)toView{
    JXConnection* p = [self addTask:act_roomMemberSet param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:nickName forKey:@"nickname"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

-(void)addRoomMember:(NSString*)roomId userArray:(NSArray*)array toView:(id)toView{
    NSString * text;
    if([array count]<=0)
        return;
    SBJsonWriter * OderJsonwriter = [SBJsonWriter new];
    text = [OderJsonwriter stringWithObject:array];

    JXConnection* p = [self addTask:act_roomMemberSet param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:text forKey:@"text"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

/**添加共享文件*/
-(void)roomShareAddRoomId:(NSString *)roomId url:(NSString *)fileUrl fileName:(NSString *)fileName size:(NSNumber *)size type:(NSInteger)type toView:(id)toView{
    JXConnection* p = [self addTask:act_shareAdd param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:g_myself.userId forKey:@"userId"];
    [p setPostValue:fileUrl forKey:@"url"];
    [p setPostValue:fileName forKey:@"name"];
    [p setPostValue:size forKey:@"size"];
    [p setPostValue:[NSNumber numberWithInteger:type] forKey:@"type"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
/**获取文件列表*/
-(void)roomShareListRoomId:(NSString *)roomId userId:(NSString *)userId pageSize:(int)pageSize pageIndex:(int)pageIndex toView:(id)toView{
    JXConnection* p = [self addTask:act_shareList param:[NSString stringWithFormat:@"?pageSize=%d&pageIndex=%d",jx_page_size,pageIndex] toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    if (userId.length > 0) {
        [p setPostValue:g_myself.userId forKey:@"userId"];
    }
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
/**获取单个文件信息*/
-(void)roomShareGetRoomId:(NSString *)roomId shareId:(NSString *)shareId toView:(id)toView{
    JXConnection* p = [self addTask:act_shareGet param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:shareId forKey:@"shareId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
/**删除文件*/
-(void)roomShareDeleteRoomId:(NSString *)roomId shareId:(NSString *)shareId toView:(id)toView{
    JXConnection* p = [self addTask:act_shareDelete param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:shareId forKey:@"shareId"];
    [p setPostValue:g_myself.userId forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}


// 群成员分页获取
- (void)roomMemberGetMemberListByPageWithRoomId:(NSString *)roomId joinTime:(long)joinTime toView:(id)toView {
    
    JXConnection* p = [self addTask:act_roomMemberGetMemberListByPage param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:[NSNumber numberWithLong:joinTime] forKey:@"joinTime"];
    [p setPostValue:[NSNumber numberWithInt:kRoomMemberListNum] forKey:@"pageSize"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}


-(void)setPushChannelId:(NSString*)channelId{
    if(channelId==nil)
        return;
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    JXConnection* p = [self addTask:act_setPushChannelId param:nil toView:nil];
    [p setPostValue:@"2" forKey:@"deviceId"];
    [p setPostValue:channelId forKey:@"channelId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:identifier forKey:@"appId"];
    [p go];
}

//简历接口：
-(void)updateResume:(NSString*)resumeId nodeName:(NSString*)nodeName text:(NSString*)text toView:(id)toView{
    JXConnection* p = [self addTask:act_resumeUpdate param:nil toView:toView];
    [p setPostValue:resumeId forKey:@"resumeId"];
    [p setPostValue:nodeName forKey:@"nodeName"];
    [p setPostValue:text forKey:@"text"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

- (void)locate {
    
    // 判断定位操作是否被允许
    if([CLLocationManager locationServicesEnabled]) {
        //        _location = [[CLLocationManager alloc] init] ;
        //        _location.delegate = self;
        //        if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        ////            [_location requestAlwaysAuthorization];//始终允许访问位置信息,必须关闭
        //            [_location requestWhenInUseAuthorization];//使用应用程序期间允许访问位置数据
        //        }
        
        
        [self.location locationStart];
        
    }else {
    }
    
    // 没开启定位
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        
        [self.location getLocationWithIp];
    }
}

#pragma mark JXLocationDelegate
//- (void)location:(JXLocation *)location CountryCode:(NSString *)countryCode CityName:(NSString *)cityName CityId:(NSString *)cityId Address:(NSString *)address Latitude:(double)lat Longitude:(double)lon{
//    self.countryCode = countryCode;
//    self.cityName = cityName;
//    self.cityId = [cityId intValue];
//    self.address = address;
//    self.latitude = lat;
//    self.longitude = lon;
//    
//    if (isLogin || _isGetSetting) {
//        //[self getSetting:self];//根据城市不同返回不同配置
//    }
//}


-(double)getLocation:(double)latitude1 longitude:(double)longitude1{
    if (latitude1 == 0 || longitude1 == 0) {
        return 0;
    }
    CLLocation * hisLocation=[[CLLocation alloc] initWithLatitude:latitude1 longitude:longitude1];//在手机上测试
    CLLocation *myLocation=[[CLLocation alloc] initWithLatitude:latitude longitude:longitude];//在simulator上测试，成功获得位置:22.602976,114.052067
    double n = [myLocation distanceFromLocation:hisLocation];//[myLocation getDistanceFrom:hisLocation];
    //    [hisLocation release];
    //    [myLocation release];
    return n;
}

//  获取首页的最近一条的聊天记录列表
- (void)getLastChatListStartTime:(NSNumber *)startTime toView:(id)toView {
    JXConnection* p = [self addTask:act_tigaseGetLastChatList param:nil toView:toView];
    [p setPostValue:startTime forKey:@"startTime"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

// 获取单聊漫游聊天记录
- (void)tigaseMsgsWithReceiver:(NSString *)receiver StartTime:(long)startTime EndTime:(long)endTime PageIndex:(int)pageIndex toView:(id)toView; {
    JXConnection* p = [self addTask:act_tigaseMsgs param:nil toView:toView];
    [p setPostValue:[NSNumber numberWithInt:pageIndex] forKey:@"pageIndex"];
    [p setPostValue:[NSNumber numberWithInt:50] forKey:@"pageSize"];
    [p setPostValue:[NSNumber numberWithLong:startTime] forKey:@"startTime"];
    [p setPostValue:[NSNumber numberWithLong:endTime] forKey:@"endTime"];
    [p setPostValue:receiver forKey:@"receiver"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

// 获取群聊漫游聊天记录
- (void)tigaseMucMsgsWithRoomId:(NSString *)roomId StartTime:(long)startTime EndTime:(long)endTime PageIndex:(int)pageIndex PageSize:(int)pageSize toView:(id)toView {
    JXConnection* p = [self addTask:act_tigaseMucMsgs param:nil toView:toView];
    [p setPostValue:[NSNumber numberWithInt:pageIndex] forKey:@"pageIndex"];
    [p setPostValue:[NSNumber numberWithInt:pageSize] forKey:@"pageSize"];
    [p setPostValue:[NSNumber numberWithLong:startTime] forKey:@"startTime"];
    [p setPostValue:[NSNumber numberWithLong:endTime] forKey:@"endTime"];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

// 公众号菜单
- (void)getPublicMenuListWithUserId:(NSString *)userId toView:(id)toView {
    JXConnection* p = [self addTask:act_publicMenuList param:nil toView:toView];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

// 获取所有群助手列表
- (void)getHelperList:(int)pageIndex pageSize:(int)pageSize toView:(id)toView {
    JXConnection* p = [self addTask:act_getHelperList param:nil toView:toView];
    [p setPostValue:[NSNumber numberWithInt:pageIndex] forKey:@"pageIndex"];
    [p setPostValue:[NSNumber numberWithInt:pageSize] forKey:@"pageSize"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

// 查询房间群助手接口
- (void)queryGroupHelper:(NSString *)roomId toView:(id)toView {
    JXConnection* p = [self addTask:act_queryGroupHelper param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

// 添加群助手接口
- (void)addGroupHelper:(NSString *)roomId roomJid:(NSString *)roomJid helperId:(NSString *)helperId toView:(id)toView {
    JXConnection* p = [self addTask:act_addGroupHelper param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:roomJid forKey:@"roomJid"];
    [p setPostValue:helperId forKey:@"helperId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

// 移除群助手接口
- (void)deleteGroupHelper:(NSString *)groupHelperId toView:(id)toView {
    JXConnection* p = [self addTask:act_deleteGroupHelper param:nil toView:toView];
    [p setPostValue:groupHelperId forKey:@"groupHelperId"];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

// 添加自动回复关键字
- (void)addAutoResponse:(NSString *)roomId helperId:(NSString *)helperId keyword:(NSString *)keyword value:(NSString *)value toView:(id)toView {
    JXConnection* p = [self addTask:act_addAutoResponse param:nil toView:toView];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:keyword forKey:@"keyword"];
    [p setPostValue:value forKey:@"value"];
    [p setPostValue:helperId forKey:@"helperId"];
    
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

// 删除自动回复关键字接口
- (void)deleteAutoResponse:(NSString *)groupHelperId keyWordId:(NSString *)keyWordId toView:(id)toView {
    JXConnection* p = [self addTask:act_deleteAutoResponse param:nil toView:toView];
    [p setPostValue:groupHelperId forKey:@"groupHelperId"];
    [p setPostValue:keyWordId forKey:@"keyWordId"];
    
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}
// 删除&撤回聊天记录
- (void)tigaseDeleteMsgWithMessageId:(NSString *)msgId type:(int)type deleteType:(int)deleteType roomJid:(NSString *)roomJid toView:(id)toView {
    JXConnection* p = [self addTask:act_tigaseDeleteMsg param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:msgId forKey:@"messageId"];
    [p setPostValue:[NSNumber numberWithInt:type] forKey:@"type"];
    [p setPostValue:[NSNumber numberWithInt:deleteType] forKey:@"delete"];
    if (roomJid) {
        [p setPostValue:roomJid forKey:@"roomJid"];
    }
    [p go];
}

// 通用接口请求，只是单纯的请求接口，不做其他操作
- (void)requestWithUrl:(NSString *)url toView:(id)toView {
    JXConnection* p = [self addTask:url param:nil toView:toView];
    [p go];
}

// 消息免打扰（是否开启或关闭消息免打扰、阅后即焚、聊天置顶 统一都是0:关闭,1:开启),新增参数type(type = 0  消息免打扰 ,type = 1  阅后即焚 ,type = 2  聊天置顶)
- (void)friendsUpdateOfflineNoPushMsgUserId:(NSString *)userId toUserId:(NSString *)toUserId offlineNoPushMsg:(int)offlineNoPushMsg type:(int)type toView:(id)toView {
    JXConnection* p = [self addTask:act_friendsUpdateOfflineNoPushMsg param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:[NSNumber numberWithInt:offlineNoPushMsg] forKey:@"offlineNoPushMsg"];
    [p setPostValue:[NSNumber numberWithInt:type] forKey:@"type"];

    [p go];
}

-(void)pkpushSetToken:(NSString *)token deviceId:(NSString *)deviceId isVoip:(int)isVoip toView:(id)toView{
    
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    JXConnection* p = [self addTask:act_PKPushSetToken param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:token forKey:@"token"];
    [p setPostValue:@"2" forKey:@"deviceId"];
    [p setPostValue:[NSNumber numberWithInt:isVoip] forKey:@"isVoip"];
    [p setPostValue:identifier forKey:@"appId"];
    [p go];
}

-(void)jPushSetToken:(NSString *)token toView:(id)toView{
    
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    JXConnection* p = [self addTask:act_jPushSetToken param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:token forKey:@"regId"];
    [p setPostValue:@"4" forKey:@"deviceId"];
    [p setPostValue:identifier forKey:@"appId"];
    [p go];
}


//添加收藏
-(void)addFavoriteWithEmoji:(NSMutableArray *)emoji toView:(id)toView{
    JXConnection* p = [self addTask:act_userEmojiAdd param:nil toView:toView];
//    NSMutableArray *emoji = [[NSMutableArray alloc] init];
//    NSDictionary *dict = [[NSDictionary alloc] init];
//    if ([type length] > 0)
//        [dict setValue:type forKey:@"type"];
//
//    if ([type intValue] == 6) {
//        [dict setValue:url forKey:@"url"];
//    }else {
//        [dict setValue:msgId forKey:@"msgId"];
//        if (roomJid) {
//            [dict setValue:roomJid forKey:@"roomJid"];
//        }
//    }
//    [emoji addObject:dict];
    SBJsonWriter * OderJsonwriter = [SBJsonWriter new];
    NSString * emojiJson = [OderJsonwriter stringWithObject:emoji];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:emojiJson forKey:@"emoji"];

    [p go];
}

////添加收藏
//-(void)addFavoriteWithContent:(NSString *)contentStr type:(int)type toView:(id)toView{
//    JXConnection* p = [self addTask:act_userEmojiAdd param:nil toView:toView];
//    [p setPostValue:access_token forKey:@"access_token"];
//    [p setPostValue:contentStr forKey:@"url"];
//    [p setPostValue:[NSNumber numberWithInt:type] forKey:@"type"];
//    [p go];
//}

// 收藏表情
//- (void)userEmojiAddWithUrl:(NSString *)url toView:(id)toView {
//    JXConnection* p = [self addTask:act_userEmojiAdd param:nil toView:toView];
//    [p setPostValue:access_token forKey:@"access_token"];
//    [p setPostValue:url forKey:@"url"];
//    [p go];
//}

// 取消收藏
- (void)userEmojiDeleteWithId:(NSString *)emojiId toView:(id)toView {
    JXConnection* p = [self addTask:act_userEmojiDelete param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:emojiId forKey:@"emojiId"];
    [p go];
}

// 朋友圈里面取消收藏
- (void)userWeiboEmojiDeleteWithId:(NSString *)messageId toView:(id)toView {
    JXConnection* p = [self addTask:act_WeiboDeleteCollect param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:messageId forKey:@"messageId"];
    [p go];
}

// 不看他(她)生活圈和视频    toUserId : 对方用户Id    type : 1 屏蔽   -1  取消屏蔽
- (void)filterUserCircle:(NSString *)toUserId type:(NSNumber *)type toView:(id)toView {
    JXConnection* p = [self addTask:act_filterUserCircle param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:type forKey:@"type"];
    [p go];
}

// 收藏列表
-(void)userCollectionListWithType:(int)type pageIndex:(int)pageIndex toView:(id)toView{
    JXConnection* p = [self addTask:act_userCollectionList param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:g_myself.userId forKey:@"userId"];
    if (type > 0)
        [p setPostValue:[NSNumber numberWithInt:type] forKey:@"type"];
    [p setPostValue:[NSNumber numberWithInteger:pageIndex] forKey:@"pageIndex"];
    [p setPostValue:[NSNumber numberWithInteger:1000] forKey:@"pageSize"];
    [p go];
}
//收藏的表情列表
- (void)userEmojiListWithPageIndex:(int)pageIndex toView:(id)toView {
    JXConnection* p = [self addTask:act_userEmojiList param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:g_myself.userId forKey:@"userId"];
    [p setPostValue:[NSNumber numberWithInteger:pageIndex] forKey:@"pageIndex"];
    [p setPostValue:[NSNumber numberWithInteger:1000] forKey:@"pageSize"];
    [p go];
}

// 添加课程
- (void)userCourseAddWithMessageIds:(NSString *)messageIds CourseName:(NSString *)courseName RoomJid:(NSString *)roomJid toView:(id)toView {
    JXConnection* p = [self addTask:act_userCourseAdd param:nil toView:toView];
    if (roomJid.length > 0) {
        [p setPostValue:roomJid forKey:@"roomJid"];
    }
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:g_myself.userId forKey:@"userId"];
    [p setPostValue:messageIds forKey:@"messageIds"];
    [p setPostValue:courseName forKey:@"courseName"];
    long long time = [[NSDate date] timeIntervalSince1970];
    [p setPostValue:[NSString stringWithFormat:@"%lld",time] forKey:@"createTime"];
    [p go];
}
// 查询课程
- (void)userCourseList:(id)toView {
    JXConnection* p = [self addTask:act_userCourseList param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:g_myself.userId forKey:@"userId"];
    [p go];
}
// 修改课程
- (void)userCourseUpdateWithCourseId:(NSString *)courseId MessageIds:(NSString *)messageIds CourseName:(NSString *)courseName CourseMessageId:(NSString *)courseMessageId toView:(id)toView {
    JXConnection* p = [self addTask:act_userCourseUpdate param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    if (courseId.length > 0) {
        [p setPostValue:courseId forKey:@"courseId"];
    }
    if (messageIds.length > 0) {
        [p setPostValue:messageIds forKey:@"messageIds"];
    }
    if (courseName.length > 0) {
        [p setPostValue:courseName forKey:@"courseName"];
    }
    if (courseMessageId.length > 0) {
        [p setPostValue:courseMessageId forKey:@"courseMessageId"];
    }
    
    long long time = [[NSDate date] timeIntervalSince1970];
    [p setPostValue:[NSString stringWithFormat:@"%lld",time] forKey:@"updateTime"];
    [p go];
}
// 删除课程
- (void)userCourseDeleteWithCourseId:(NSString *)courseId toView:(id)toView {
    JXConnection* p = [self addTask:act_userCourseDelete param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:courseId forKey:@"courseId"];
    [p go];
}
// 课程详情
- (void)userCourseGetWithCourseId:(NSString *)courseId toView:(id)toView {
    JXConnection* p = [self addTask:act_userCourseGet param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:courseId forKey:@"courseId"];
    [p go];
}

// 更新角标
- (void)userChangeMsgNum:(NSInteger)num toView:(id)toView {
    JXConnection* p = [self addTask:act_userChangeMsgNum param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:[NSNumber numberWithInteger:num] forKey:@"num"];
    [p go];
}

// 设置群消息免打扰
- (void)roomMemberSetOfflineNoPushMsg:(NSString *)roomId userId:(NSString *)userId type:(int)type offlineNoPushMsg:(int)offlineNoPushMsg toView:(id)toView{
    
    JXConnection* p = [self addTask:act_roomMemberSetOfflineNoPushMsg param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:[NSNumber numberWithInt:type] forKey:@"type"];
    [p setPostValue:[NSNumber numberWithInt:offlineNoPushMsg] forKey:@"offlineNoPushMsg"];
    [p go];
}

// 添加标签
- (void)friendGroupAdd:(NSString *)groupName toView:(id)toView {
    JXConnection* p = [self addTask:act_FriendGroupAdd param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:groupName forKey:@"groupName"];
    [p go];
}

// 修改好友标签
- (void)friendGroupUpdateGroupUserList:(NSString *)groupId userIdListStr:(NSString *)userIdListStr toView:(id)toView {
    
    JXConnection* p = [self addTask:act_FriendGroupUpdateGroupUserList param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:groupId forKey:@"groupId"];
    [p setPostValue:userIdListStr forKey:@"userIdListStr"];
    [p go];
}

// 更新标签名
- (void)friendGroupUpdate:(NSString *)groupId groupName:(NSString *)groupName toView:(id)toView {
    
    JXConnection* p = [self addTask:act_FriendGroupUpdate param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:groupId forKey:@"groupId"];
    [p setPostValue:groupName forKey:@"groupName"];
    [p go];
}

// 删除标签
- (void)friendGroupDelete:(NSString *)groupId toView:(id)toView {
    
    JXConnection* p = [self addTask:act_FriendGroupDelete param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:groupId forKey:@"groupId"];
    [p go];
}

// 标签列表
- (void)friendGroupListToView:(id)toView {
    JXConnection* p = [self addTask:act_FriendGroupList param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p go];
}

// 修改好友的分组列表
- (void)friendGroupUpdateFriendToUserId:(NSString *)toUserId groupIdStr:(NSString *)groupIdStr toView:(id)toView {
    
    JXConnection* p = [self addTask:act_FriendGroupUpdateFriend param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:groupIdStr forKey:@"groupIdStr"];
    [p go];
}

// 删除群组公告
- (void)roomDeleteNotice:(NSString *)roomId noticeId:(NSString *)noticeId ToView:(id)toView {
    JXConnection* p = [self addTask:act_roomDeleteNotice param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:roomId forKey:@"roomId"];
    [p setPostValue:noticeId forKey:@"noticeId"];
    [p go];
}

// 拷贝文件
- (void)uploadCopyFileServlet:(NSString *)paths validTime:(NSString *)validTime toView:(id)toView {
    
    JXConnection* p = [self addTask:act_UploadCopyFileServlet param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:validTime forKey:@"validTime"];
    [p setPostValue:paths forKey:@"paths"];
    [p go];
}

// 群组复制
- (void)copyRoom:(NSString *)roomId toView:(id)toView {
    JXConnection* p = [self addTask:act_copyRoom param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:roomId forKey:@"roomId"];
    [p go];
}


// 清空聊天记录
- (void)emptyMsgWithTouserId:(NSString *)toUserId type:(NSNumber *)type toView:(id)toView {
    JXConnection* p = [self addTask:act_EmptyMsg param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p setPostValue:type forKey:@"type"];
    [p go];
}

// 获取通讯录所有号码
- (void)getAddressBookAll:(id)toView {
    JXConnection* p = [self addTask:act_AddressBookGetAll param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p go];
}
// 上传通讯录
- (void)uploadAddressBookUploadStr:(NSString *)uploadStr toView:(id)toView {
    JXConnection* p = [self addTask:act_AddressBookUpload param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:uploadStr forKey:@"uploadJsonStr"];
    [p go];
}
// 添加手机联系人好友
- (void)friendsAttentionBatchAddToUserIds:(NSString *)toUserIds toView:(id)toView {
    JXConnection* p = [self addTask:act_FriendsAttentionBatchAdd param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:toUserIds forKey:@"toUserIds"];
    [p go];
}


// 用户绑定微信code，获取openid
- (void)userBindWXCodeWithCode:(NSString *)code toView:(id)toView {
    JXConnection* p = [self addTask:act_UserBindWXCode param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:code forKey:@"code"];
    [p go];
}

/**
 * 余额微信提现
 * amout -- 提现金额，0.3=30，单位为分，最少0.5
 * secret -- 提现秘钥
 * time -- 请求时间，服务器检查，允许5分钟时差
 */
- (void)transferWXPayWithAmount:(NSString *)amount secret:(NSString *)secret time:(NSNumber *)time toView:(id)toView {
    JXConnection* p = [self addTask:act_TransferWXPay param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:amount forKey:@"amount"];
    [p setPostValue:secret forKey:@"secret"];
    [p setPostValue:time forKey:@"time"];
    [p go];
}

// 检查支付密码是否正确
- (void)checkPayPasswordWithUser:(JXUserObject *)user toView:(id)toView {
    JXConnection* p = [self addTask:act_CheckPayPassword param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:[self getMD5String:user.payPassword] forKey:@"payPassword"];
    [p go];
}


// 更新支付密码
- (void)updatePayPasswordWithUser:(JXUserObject *)user toView:(id)toView {
    JXConnection* p = [self addTask:act_UpdatePayPassword param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:[self getMD5String:user.payPassword] forKey:@"payPassword"];
    [p setPostValue:user.oldPayPassword ? [self getMD5String:user.oldPayPassword] : @"" forKey:@"oldPayPassword"];
    [p go];
}

// 获取集群音视频服务地址
- (void)userOpenMeetWithToUserId:(NSString *)toUserId toView:(id)toView {
    JXConnection* p = [self addTask:act_UserOpenMeet param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    NSString *area = [g_default objectForKey:kLocationArea];
    [p setPostValue:area forKey:@"area"];
    [p setPostValue:toUserId forKey:@"toUserId"];
    [p go];
}

// 获取群组信息
- (void)roomGetRoom:(NSString *)roomId toView:(id)toView {
    JXConnection* p = [self addTask:act_roomGetRoom param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:roomId forKey:@"roomId"];
    [p go];
}

// 朋友圈纯视频接口
- (void)circleMsgPureVideoPageIndex:(NSInteger)pageIndex lable:(NSString *)lable toView:(id)toView{
    JXConnection* p = [self addTask:act_CircleMsgPureVideo param:nil toView:toView];

    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:[NSNumber numberWithInteger:pageIndex] forKey:@"pageIndex"];
    [p setPostValue:lable forKey:@"lable"];
    [p setPostValue:[NSNumber numberWithInteger:20] forKey:@"pageSize"];
    [p go];
}

// 获取音乐列表
- (void)musicListPageIndex:(NSInteger)pageIndex keyword:(NSString *)keyword toView:(id)toView {
    JXConnection* p = [self addTask:act_MusicList param:nil toView:toView];
    
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:[NSNumber numberWithInteger:pageIndex] forKey:@"pageIndex"];
    [p setPostValue:[NSNumber numberWithInteger:20] forKey:@"pageSize"];
    [p setPostValue:keyword forKey:@"keyword"];
    [p go];
}

// 第三方认证
- (void)openOpenAuthInterfaceWithUserId:(NSString *)userId appId:(NSString *)appId appSecret:(NSString *)appSecret type:(NSInteger)type toView:(id)toView{
    JXConnection* p = [self addTask:act_OpenAuthInterface param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p setPostValue:userId forKey:@"userId"];
    [p setPostValue:appId forKey:@"appId"];
    [p setPostValue:appSecret forKey:@"appSecret"];
    [p setPostValue:[NSNumber numberWithInteger:type] forKey:@"type"];
    
    long time = (long)[[NSDate date] timeIntervalSince1970];
    [p setPostValue:[NSNumber numberWithLong:time] forKey:@"time"];
    
    NSString *str1 = [g_server getMD5String:appSecret];
    
    NSMutableString *str2 = [NSMutableString string];
    [str2 appendString:self.access_token];
    [str2 appendString:[NSString stringWithFormat:@"%ld",time]];
    str2 = [[g_server getMD5String:str2] mutableCopy];
    
    NSMutableString *str3 = [NSMutableString string];
    [str3 appendString:APIKEY];
    [str3 appendString:appId];
    [str3 appendString:userId];
    [str3 appendString:str2];
    [str3 appendString:str1];
    str3 = [[g_server getMD5String:str3] mutableCopy];
    
    [p setPostValue:str3 forKey:@"secret"];
    
    [p go];
}


// 获取微信登录openid
- (void)getWxOpenId:(NSString *)code toView:(id)toView {
    JXConnection* p = [self addTask:act_GetWxOpenId param:nil toView:toView];
    [p setPostValue:code forKey:@"code"];
    [p go];
}

- (void)wxSdkLogin:(JXUserObject *)user type:(NSInteger)type openId:(NSString *)openId toView:(id)toView {
    JXConnection* p = [self addTask:act_sdkLogin param:nil toView:toView];
    [p setPostValue:[NSNumber numberWithInteger:type] forKey:@"type"];
    [p setPostValue:openId forKey:@"loginInfo"];
    [p setPostValue:user forKey:@"UserExample"];
    [p go];
}
// 第三方绑定手机号
-(void)thirdLogin:(JXUserObject*)user type:(NSInteger)type openId:(NSString *)openId isLogin:(BOOL)isLogin toView:(id)toView{
    //  type  第三方登录类型  1: QQ  2: 微信
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    JXConnection* p = [self addTask:act_thirdLogin param:nil toView:toView];
    
    [p setPostValue:[NSNumber numberWithInteger:type] forKey:@"type"];
    [p setPostValue:openId forKey:@"loginInfo"];
    if (self.openId.length > 0 ) {
        NSString *tel = [NSString stringWithFormat:@"%@%@",user.areaCode,user.telephone];
        [p setPostValue:tel forKey:@"telephone"];
    }else {
        [p setPostValue:user.telephone forKey:@"telephone"];
    }
    [p setPostValue:user.password forKey:@"password"];
    // 没有在登录后 绑定 才需要传下面的参数
    if (!isLogin) {
        [p setPostValue:user.areaCode forKey:@"areaCode"];
        [p setPostValue:@"client_credentials" forKey:@"grant_type"];
        [p setPostValue:user.model forKey:@"model"];
        [p setPostValue:user.osVersion forKey:@"osVersion"];
        [p setPostValue:g_macAddress forKey:@"serial"];
        [p setPostValue:[NSNumber numberWithDouble:latitude] forKey:@"latitude"];
        [p setPostValue:[NSNumber numberWithDouble:longitude] forKey:@"longitude"];
        [p setPostValue:user.location forKey:@"location"];
        [p setPostValue:identifier forKey:@"appId"];
        [p setPostValue:[NSNumber numberWithInt:1] forKey:@"xmppVersion"];
        // 是否开启集群
        if ([g_config.isOpenCluster integerValue] == 1) {
            NSString *area = [g_default objectForKey:kLocationArea];
            [p setPostValue:area forKey:@"area"];
        }
    }
    
    [p go];
}

// 第三方网页授权
- (void)openCodeAuthorCheckAppId:(NSString *)appId state:(NSString *)state callbackUrl:(NSString *)callbackUrl toView:(id)toView {
    JXConnection* p = [self addTask:act_openCodeAuthorCheck param:nil toView:toView];
    [p setPostValue:appId forKey:@"appId"];
    [p setPostValue:state forKey:@"state"];
    [p setPostValue:callbackUrl forKey:@"callbackUrl"];
    [p go];
}

// 检查网址是否被锁定
- (void)userCheckReportUrl:(NSString *)webUrl toView:(id)toView {
    
    JXConnection* p = [self addTask:act_userCheckReportUrl param:nil toView:toView];
    [p setPostValue:webUrl forKey:@"webUrl"];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p go];
}

// 第三方解绑
- (void)setAccountUnbind:(int)type toView:(id)toView {
    //  type  第三方登录类型  1: QQ  2: 微信
    JXConnection* p = [self addTask:act_unbind param:nil toView:toView];
    [p setPostValue:[NSNumber numberWithInt:type] forKey:@"type"];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p go];
}

// 获取用户绑定信息接口
- (void)getBindInfo:(id)toView {
    JXConnection* p = [self addTask:act_getBindInfo param:nil toView:toView];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p go];
}

// 面对面建群
//面对面建群查询
- (void)roomLocationQueryWithIsQuery:(int)isQuery password:(NSString *)password toView:(id)toView{
    
    JXConnection* p = [self addTask:act_RoomLocationQuery param:nil toView:toView];
    [p setPostValue:[NSNumber numberWithDouble:longitude] forKey:@"longitude"];
    [p setPostValue:[NSNumber numberWithDouble:latitude] forKey:@"latitude"];
    [p setPostValue:[NSNumber numberWithInt:isQuery] forKey:@"isQuery"];
    [p setPostValue:password forKey:@"password"];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p go];
}
//面对面建群加入
- (void)roomLocationJoinWithJid:(NSString *)jid toView:(id)toView{
    
    JXConnection* p = [self addTask:act_RoomLocationJoin param:nil toView:toView];
    [p setPostValue:jid forKey:@"jid"];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p go];
}
//面对面建群退出
- (void)roomLocationExitWithJid:(NSString *)jid toView:(id)toView{
    
    JXConnection* p = [self addTask:act_RoomLocationExit param:nil toView:toView];
    [p setPostValue:jid forKey:@"jid"];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p go];
}

// 视酷支付
// 接口获取订单信息
- (void)payGetOrderInfoWithAppId:(NSString *)appId prepayId:(NSString *)prepayId toView:(id)toView{
    
    JXConnection* p = [self addTask:act_PayGetOrderInfo param:nil toView:toView];
    [p setPostValue:appId forKey:@"appId"];
    [p setPostValue:prepayId forKey:@"prepayId"];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p go];
}

// 输入密码后支付接口
- (void)payPasswordPaymentWithAppId:(NSString *)appId prepayId:(NSString *)prepayId sign:(NSString *)sign time:(NSString *)time secret:(NSString *)secret toView:(id)toView {
    
    JXConnection* p = [self addTask:act_PayPasswordPayment param:nil toView:toView];
    [p setPostValue:appId forKey:@"appId"];
    [p setPostValue:prepayId forKey:@"prepayId"];
    [p setPostValue:sign forKey:@"sign"];
    [p setPostValue:secret forKey:@"secret"];
    [p setPostValue:time forKey:@"time"];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p go];
}

// weba扫描二维码登录
- (void)userQrCodeLoginWithQRCodeKey:(NSString *)qrCodeKey type:(NSString *)type toView:(id)toView {
    
    JXConnection* p = [self addTask:act_UserQrCodeLogin param:nil toView:toView];
    [p setPostValue:qrCodeKey forKey:@"qrCodeKey"];
    [p setPostValue:type forKey:@"type"];
    [p setPostValue:self.access_token forKey:@"access_token"];
    [p go];
}

// 根据通讯号获取用户资料
- (void)userGetByAccountWithAccount:(NSString *)account toView:(id)toView {
    JXConnection* p = [self addTask:act_UserGetByAccount param:nil toView:toView];
    [p setPostValue:access_token forKey:@"access_token"];
    [p setPostValue:account forKey:@"account"];
    [p go];
}

@end
