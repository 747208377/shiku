/**
 @@create by 刘智援 2016-11-28
 
 @简书地址:    http://www.jianshu.com/users/0714484ea84f/latest_articles
 @Github地址: https://github.com/lyoniOS
 @return WXApiManager（微信结果回调类）
 */

#import "WXApiManager.h"

@implementation WXApiManager

#pragma mark - 单粒

+(instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static WXApiManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[WXApiManager alloc] init];
    });
    return instance;
}

#pragma mark - WXApiDelegate

- (void)onResp:(BaseResp *)resp
{
    // 支付回调
    if([resp isKindOfClass:[PayResp class]]){
        
        [g_notify postNotificationName:kWxPayFinishNotification object:resp];
        
        //支付返回结果，实际支付结果需要去微信服务器端查询
        NSString *strMsg,*strTitle = [NSString stringWithFormat:@"支付结果"];
        
        switch (resp.errCode) {
            case WXSuccess:
                strMsg = @"支付结果：成功！";
                NSLog(@"支付成功－PaySuccess，retcode = %d", resp.errCode);
                break;
                
            default:
                strMsg = [NSString stringWithFormat:@"支付结果：失败！retcode = %d, retstr = %@", resp.errCode,resp.errStr];
                NSLog(@"错误，retcode = %d, retstr = %@", resp.errCode,resp.errStr);
                break;
        }
        
    }
//    else if ([resp isKindOfClass:[SendAuthResp class]]) {
//        if (_delegate && [_delegate respondsToSelector:@selector(managerDidRecvAuthResponse:)]) {
//            SendAuthResp *authResp = (SendAuthResp *)resp;
//            [_delegate managerDidRecvAuthResponse:authResp];
//        }
//    }
    // 授权回调
    if ([resp isKindOfClass:[SendAuthResp class]]) {
        [g_notify postNotificationName:kWxSendAuthRespNotification object:resp];
    }
}


-(void) onReq:(BaseReq*)req{
    
}

@end
