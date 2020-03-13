//
//  JXAboutVC.m
//  shiku_im
//
//  Created by flyeagleTang on 14-6-10.
//  Copyright (c) 2014年 Reese. All rights reserved.
//

#import "JXAboutVC.h"
#import "JXShareListVC.h"
#import "JXShareManager.h"

#define HEIGHT 44
#define STARTTIME_TAG 1

@interface JXAboutVC ()<ShareListDelegate>

@end

@implementation JXAboutVC

- (id)init
{
    self = [super init];
    if (self) {
        self.isGotoBack   = YES;
            self.title = Localized(@"JXAboutVC_AboutUS");
        self.heightFooter = 0;
        self.heightHeader = JX_SCREEN_TOP;
        //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
        [self createHeadAndFoot];
        self.tableBody.backgroundColor = HEXCOLOR(0xf0eff4);
        self.tableBody.scrollEnabled = YES;
//        int h = 0;
        
        if (THE_APP_OUR) {
            //右侧分享按钮
            UIButton *shareBtn = [[UIButton alloc] initWithFrame:CGRectMake(self_width-31-8, JX_SCREEN_TOP - 38, 31, 31)];
            [shareBtn setImage:THESIMPLESTYLE ? [UIImage imageNamed:@"ic_share_black"] : [UIImage imageNamed:@"ic_share"] forState:UIControlStateNormal];
            [shareBtn addTarget:self action:@selector(shareBtnClick:) forControlEvents:UIControlEventTouchUpInside];
            [self.tableHeader addSubview:shareBtn];
        }
        
        JXImageView* iv;
        iv = [[JXImageView alloc]initWithFrame:CGRectMake((JX_SCREEN_WIDTH-120)/2, 110, 120, 120)];
        iv.center = CGPointMake(JX_SCREEN_WIDTH/2, iv.center.y);
        iv.image = [UIImage imageNamed:@"酷聊120"];
        [self.tableBody addSubview:iv];
//        [iv release];
        
        
        UILabel* p = [self createLabel:self.tableBody default:[NSString stringWithFormat:@"%@ %@",APP_NAME,g_config.version]];
        p.frame = CGRectMake(0, iv.frame.origin.y+iv.frame.size.height+20, JX_SCREEN_WIDTH, 20);
        p.textAlignment = NSTextAlignmentCenter;
        p.font = g_factory.font16;
        
        if (THE_APP_OUR) {
            p = [self createLabel:self.view default:g_App.config.companyName];
            p.frame = CGRectMake(0, JX_SCREEN_HEIGHT-40, JX_SCREEN_WIDTH, 20);
            p.font = g_factory.font13;
            p.textColor = [UIColor grayColor];
            p.textAlignment = NSTextAlignmentCenter;
            
            p = [self createLabel:self.view default:g_App.config.copyright];
            p.frame = CGRectMake(0, JX_SCREEN_HEIGHT-20, JX_SCREEN_WIDTH, 20);
            p.font = g_factory.font13;
            p.textColor = [UIColor grayColor];
            p.textAlignment = NSTextAlignmentCenter;
        }
        UIButton* _btn;
        _btn = [UIFactory createCommonButton:Localized(@"JXAboutVC_Good") target:self action:@selector(onGood)];
        _btn.frame = CGRectMake(INSETS, iv.frame.origin.y+iv.frame.size.height+20 + 20 + 20, WIDTH, HEIGHT);
        [self.tableBody addSubview:_btn];
        
    }
    return self;
}

-(void)dealloc{
//    NSLog(@"JXAboutVC.dealloc");
//    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UILabel*)createLabel:(UIView*)parent default:(NSString*)s{
    UILabel* p = [[UILabel alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH/2,INSETS,JX_SCREEN_WIDTH/2 -20,HEIGHT-INSETS*2)];
    p.userInteractionEnabled = NO;
    p.text = s;
    p.font = g_factory.font13;
    p.textAlignment = NSTextAlignmentRight;
    [parent addSubview:p];
//    [p release];
    return p;
}

-(void)onGood{
    if (g_App.config.appleId.length > 0) {
        NSString *str = [NSString stringWithFormat:@"http://itunes.apple.com/us/app/id%@",g_App.config.appleId];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
    }
}

//分享按钮点击事件
- (void)shareBtnClick:(UIButton *)shareBtn{
    JXShareListVC *shareListVC = [[JXShareListVC alloc] init];
    shareListVC.shareListDelegate = self;
    [self.view addSubview:shareListVC.view];
}

#pragma mark JXShareSelectView delegate
- (void)didShareBtnClick:(UIButton *)shareBtn{
    //    NSString *userId = [NSString stringWithFormat:@"%lld",[[_dataDict objectForKey:@"userId"] longLongValue]-1];
//    NSString *userId = [NSString stringWithFormat:@"%lld",[[_dataDict objectForKey:@"userId"] longLongValue]];
    
    JXShareModel *shareModel = [[JXShareModel alloc] init];
    shareModel.shareTo = shareBtn.tag;
    //分享标题
    shareModel.shareTitle = APP_NAME;
    
    //分享内容
    shareModel.shareContent = @"微信？快手？ZOOM?\n轻轻松松实现它！";
    //    //分享链接
    //    shareModel.shareUrl = [NSString stringWithFormat:@"%@%@?userId=%lld&language=%@",g_config.shareUrl,act_ShareBoss,[[_dataDict objectForKey:@"userId"] longLongValue],[JXMyTools getCurrentSysLanguage]];
    //分享链接
    shareModel.shareUrl = g_config.website;
    
    //分享头像

//    shareModel.shareImageUrl = url;
    shareModel.shareImage = [UIImage imageNamed:@"酷聊120"];
    [[JXShareManager defaultManager] shareWith:shareModel delegate:self];
    
}

@end
