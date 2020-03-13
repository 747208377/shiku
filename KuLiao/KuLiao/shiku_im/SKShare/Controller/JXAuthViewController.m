//
//  JXAuthViewController.m
//  shiku_im
//
//  Created by p on 2018/11/2.
//  Copyright © 2018年 Reese. All rights reserved.
//

#import "JXAuthViewController.h"

@interface JXAuthViewController ()

@end

@implementation JXAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.isGotoBack   = YES;
    self.title = [NSString stringWithFormat:@"%@%@",APP_NAME,Localized(@"JX_Login")];
    self.heightFooter = 0;
    self.heightHeader = JX_SCREEN_TOP;
    
    [self createHeadAndFoot];
    
    JXImageView *icon = [[JXImageView alloc] initWithFrame:CGRectMake(100, 50, 100, 100)];
    icon.center = CGPointMake(self.tableBody.frame.size.width / 2, icon.center.y);
    icon.image = [UIImage imageNamed:@"酷聊120"];
    [self.tableBody addSubview:icon];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(icon.frame) + 50, JX_SCREEN_WIDTH - 15, 20)];
    label.font = [UIFont systemFontOfSize:15.0];
    label.textColor = HEXCOLOR(0x323232);
    label.text = Localized(@"JX_AfterLogin");
    [self.tableBody addSubview:label];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(label.frame) + 10, JX_SCREEN_WIDTH - 15, 20)];
    label.font = [UIFont systemFontOfSize:13.0];
    label.textColor = [UIColor lightGrayColor];
    label.text = Localized(@"JX_GetPublicInformation");
    [self.tableBody addSubview:label];
    
    UIButton *btn = [UIFactory createCommonButton:Localized(@"JX_ConfirmTheLogin") target:self action:@selector(loginBtnAction:)];
    btn.frame = CGRectMake(10, CGRectGetMaxY(label.frame) + 20, JX_SCREEN_WIDTH - 20, 45);
    [self.tableBody addSubview:btn];

}

- (void)loginBtnAction:(UIButton *)btn {
    
    if (self.isWebAuth) {
        
        [g_server openCodeAuthorCheckAppId:self.appId state:g_server.access_token callbackUrl:self.callbackUrl toView:self];
    }else {
     
        [g_server openOpenAuthInterfaceWithUserId:g_myself.userId appId:self.appId appSecret:self.appSecret type:1 toView:self];
    }
    
}
-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait hide];
    
    if([aDownload.action isEqualToString:act_OpenAuthInterface]){
        
        if ([dict[@"flag"] intValue] != 1) {
            
            [g_App showAlert:Localized(@"JX_NoCertification")];
            
            return;
        }
        
        NSString* s;
        if([dict[@"userId"] isKindOfClass:[NSNumber class]])
            s = [(NSNumber*)dict[@"userId"] stringValue];
        else
            s = dict[@"userId"];
        if([s length]<=0)
            return;

        NSString* dir  = [NSString stringWithFormat:@"%d",[s intValue] % 10000];
        NSString* url  = [NSString stringWithFormat:@"%@avatar/o/%@/%@.jpg",g_config.downloadAvatarUrl,dir,s];
        
        NSString *str = [NSString stringWithFormat:@"%@://type=%@,userId=%@,nickName=%@,avatarUrl=%@,birthday=%@,sex=%@",self.urlSchemes,@"Auth",dict[@"userId"],g_myself.userNickname,url,[NSString stringWithFormat:@"%@",g_myself.birthday],[NSString stringWithFormat:@"%@",g_myself.sex]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] options:nil completionHandler:^(BOOL success) {
        }];
        
        [self actionQuit];
    }
    
    
    if ([aDownload.action isEqualToString:act_openCodeAuthorCheck]) {
        NSString *url = [NSString stringWithFormat:@"%@?code=%@",[dict objectForKey:@"callbackUrl"],[dict objectForKey:@"code"]];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        
        [self actionQuit];
    }
}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    [_wait hide];
    return show_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    [_wait hide];
    return show_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
    [_wait start];
}
- (void)actionQuit {
    [self dismissViewControllerAnimated:YES completion:nil];
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
