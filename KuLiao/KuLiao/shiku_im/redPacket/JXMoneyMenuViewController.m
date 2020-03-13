//
//  JXMoneyMenuViewController.m
//  shiku_im
//
//  Created by 1 on 2018/9/18.
//  Copyright © 2018年 Reese. All rights reserved.
//

#import "JXMoneyMenuViewController.h"
#import "JXRecordCodeVC.h"
#import "JXPayPasswordVC.h"


#define HEIGHT 50

@interface JXMoneyMenuViewController ()

@end

@implementation JXMoneyMenuViewController


- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = Localized(@"JX_PayCenter");
        self.heightHeader = JX_SCREEN_TOP;
        self.heightFooter = 0;
        self.isGotoBack = YES;
        [self createHeadAndFoot];
        self.tableBody.backgroundColor = HEXCOLOR(0xf0eff4);
        
        int h=9;
        int w=JX_SCREEN_WIDTH;

        JXImageView* iv;
        iv = [self createButton:Localized(@"JX_Bill") drawTop:NO drawBottom:YES click:@selector(onBill)];
        iv.frame = CGRectMake(0,h, w, HEIGHT);
        h+=iv.frame.size.height;
        
        iv = [self createButton:Localized(@"JX_SetPayPsw") drawTop:NO drawBottom:YES click:@selector(onPayThePassword)];
        iv.frame = CGRectMake(0,h, w, HEIGHT);
        h+=iv.frame.size.height;

        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}


- (void)onBill {
    JXRecordCodeVC * recordVC = [[JXRecordCodeVC alloc]init];
    [g_navigation pushViewController:recordVC animated:YES];
}


- (void)onPayThePassword {
    JXPayPasswordVC * PayVC = [JXPayPasswordVC alloc];
    if ([g_server.myself.isPayPassword boolValue]) {
        PayVC.type = JXPayTypeInputPassword;
    }else {
        PayVC.type = JXPayTypeSetupPassword;
    }
    PayVC.enterType = JXEnterTypeDefault;
    PayVC = [PayVC init];
    [g_navigation pushViewController:PayVC animated:YES];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(JXImageView*)createButton:(NSString*)title drawTop:(BOOL)drawTop drawBottom:(BOOL)drawBottom click:(SEL)click{
    JXImageView* btn = [[JXImageView alloc] init];
    btn.backgroundColor = [UIColor whiteColor];
    btn.userInteractionEnabled = YES;
    btn.didTouch = click;
    btn.delegate = self;
    [self.tableBody addSubview:btn];
    
    JXLabel* p = [[JXLabel alloc] initWithFrame:CGRectMake(20, 0, self_width-35-20-5, HEIGHT)];
    p.text = title;
    p.font = g_factory.font17;
    p.backgroundColor = [UIColor clearColor];
    p.textColor = HEXCOLOR(0x323232);
    [btn addSubview:p];
    
    if(drawTop){
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(20,0,JX_SCREEN_WIDTH-20,0.5)];
        line.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        [btn addSubview:line];
    }
    
    if(drawBottom){
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(20,HEIGHT-0.5,JX_SCREEN_WIDTH-20,0.5)];
        line.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        [btn addSubview:line];
    }
    
    if(click){
        UIImageView* iv;
        iv = [[UIImageView alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH-INSETS-20-3, 16, 20, 20)];
        iv.image = [UIImage imageNamed:@"set_list_next"];
        [btn addSubview:iv];
        
    }
    return btn;
}


@end
