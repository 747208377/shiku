//
//  JXPayViewController.m
//  shiku_im
//
//  Created by 1 on 2019/3/6.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXPayViewController.h"
#import "JXCollectMoneyVC.h"
#import "QRImage.h"


#define HEIGHT 50

@interface JXPayViewController ()
@property (nonatomic, strong) UIImageView *barCode;// 条形码
@property (nonatomic, strong) UIImageView *qrCode;// 二维码
@property (nonatomic, strong) NSString *codeStr;
@property (nonatomic, strong) NSTimer *timer;


@end

@implementation JXPayViewController

// GCD定时器
static dispatch_source_t _timer;

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.heightHeader = 0;
    self.heightFooter = 0;
    [self createHeadAndFoot];
    [self setupNav];
    [self setupViews];
    
    [g_notify addObserver:self selector:@selector(notifyPaymentGet:) name:kXMPPMessageQrPaymentNotification object:nil];
}

- (void)notifyPaymentGet:(NSNotification *)noti {
    JXMessageObject *msg = noti.object;
    if ([msg.type intValue] == kWCMessageTypePaymentOut) {
        [g_server showMsg:Localized(@"JX_PaymentToFriend")];
        [self updateQr];
    }
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startTimer];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopTimer];
}

- (void)setupNav {
    UIView *nav = [[UIView alloc] initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_TOP)];
    nav.backgroundColor = HEXCOLOR(0x14a399);
    [self.view addSubview:nav];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(8, JX_SCREEN_TOP - 38, 31, 31)];
    [btn setBackgroundImage:[UIImage imageNamed:@"title_back"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(actionQuit) forControlEvents:UIControlEventTouchUpInside];
    [nav addSubview:btn];
    
    UILabel *p = [[UILabel alloc]initWithFrame:CGRectMake(40, JX_SCREEN_TOP - 32, JX_SCREEN_WIDTH-40*2, 20)];
    p.backgroundColor = [UIColor clearColor];
    p.textAlignment   = NSTextAlignmentCenter;
    p.textColor       = [UIColor whiteColor];
    p.text = Localized(@"JX_Receiving");
    [nav addSubview:p];
}

- (void)setupViews {
    self.tableBody.backgroundColor = HEXCOLOR(0x14a399);

    UIView *baseView = [[UIView alloc] initWithFrame:CGRectMake(10, JX_SCREEN_TOP, JX_SCREEN_WIDTH-20, 480)];
    baseView.backgroundColor = [UIColor whiteColor];
    baseView.layer.masksToBounds = YES;
    baseView.layer.cornerRadius = 3.f;
    [self.tableBody addSubview:baseView];
    
    JXImageView *iv = [self createButton:Localized(@"JX_QrCodeCollection") drawTop:NO drawBottom:YES icon:@"pay_wallet_white" click:@selector(onCollectMoney)];
    iv.frame = CGRectMake(10, CGRectGetMaxY(baseView.frame)+20, JX_SCREEN_WIDTH-20, 50);
    [self.tableBody addSubview:iv];
    
    UILabel *payLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 13, 50, 18)];
    payLabel.text = Localized(@"JX_Payment");
    payLabel.textColor = HEXCOLOR(0x14a399);
    [baseView addSubview:payLabel];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(payLabel.frame)+13, baseView.frame.size.width, .5)];
    line.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
    [baseView addSubview:line];

    UILabel *barCodeLab = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(line.frame)+30, JX_SCREEN_WIDTH, 15)];
    barCodeLab.text = Localized(@"JX_PaymentBarCode");
    barCodeLab.textColor = [UIColor lightGrayColor];
    barCodeLab.font = SYSFONT(14);
    barCodeLab.textAlignment = NSTextAlignmentCenter;
    [baseView addSubview:barCodeLab];
    
    // 条形码
    _barCode = [[UIImageView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(barCodeLab.frame)+10, baseView.frame.size.width- 40, 80)];
    [baseView addSubview:_barCode];
    
    // 二维码
    _qrCode = [[UIImageView alloc] initWithFrame:CGRectMake((baseView.frame.size.width - 200)/2, CGRectGetMaxY(_barCode.frame)+50, 200, 200)];
    [baseView addSubview:_qrCode];
    
    
    self.tableBody.contentSize = CGSizeMake(0, CGRectGetMaxY(iv.frame)+20);
    
    // 第一次进入更新一下二维码、条形码
    [self updateQr];
}


#pragma mark - 收钱
- (void)onCollectMoney {
    JXCollectMoneyVC * collVC = [[JXCollectMoneyVC alloc] init];
    [g_navigation pushViewController:collVC animated:YES];
}

#pragma mark - 更新 二维码 && 条形码
- (void)updateQr {

    self.codeStr = [self getQrCode];
    _barCode.image = [QRImage barCodeWithString:self.codeStr BCSize:_barCode.frame.size];
    _qrCode.image = [QRImage qrImageForString:self.codeStr imageSize:200];
    
}


- (void)startTimer {
    //设置时间间隔 一分钟
    self.timer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                                  target:self
                                                selector:@selector(updateQr) userInfo:nil
                                                 repeats:YES];
}

- (void)stopTimer {
    if (_timer){
        // 关闭定时器
        [_timer invalidate];
    }
}


- (JXImageView*)createButton:(NSString*)title drawTop:(BOOL)drawTop drawBottom:(BOOL)drawBottom icon:(NSString*)icon click:(SEL)click{
    JXImageView* btn = [[JXImageView alloc] init];
    btn.backgroundColor = HEXCOLOR(0x42AEA4);
    btn.userInteractionEnabled = YES;
    btn.didTouch = click;
    btn.delegate = self;
    [self.tableBody addSubview:btn];
    
    JXLabel* p = [[JXLabel alloc] initWithFrame:CGRectMake(10*2+20, 0, self_width-35-20-5, HEIGHT)];
    p.text = title;
    p.font = g_factory.font16;
    p.backgroundColor = [UIColor clearColor];
    p.textColor = [UIColor whiteColor];
    [btn addSubview:p];
    
    if(icon){
        UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(10, (HEIGHT-20)/2, 21, 21)];
        iv.image = [UIImage imageNamed:icon];
        [btn addSubview:iv];
    }
    
    if(click){
        UIImageView* iv;
        iv = [[UIImageView alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH-INSETS-40, 16, 20, 20)];
        iv.image = [UIImage imageNamed:@"pay_arrow_white"];
        [btn addSubview:iv];
        
    }
    return btn;
}

#pragma mark - 生成二维码数据
- (NSString *)getQrCode {
    int n = 9;
    int opt = [self getRandomNumber:100 to:101];
    
    NSString *str = [NSString stringWithFormat:@"%d",[MY_USER_ID intValue]+n+opt];
    
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    long timeOpt = time/opt;
    // 如果小于8位数
    if (timeOpt < 10000000) {
        timeOpt = time/(opt - 100);
    }
    
    NSString *code = [NSString stringWithFormat:@"%ld%@%d%ld",str.length,str,opt,timeOpt];
    
    NSLog(@"length = %lu   code = %@",code.length,code);
    
    return code;
}

//获取一个随机整数，范围在[from,to），包括from，不包括to
-(int)getRandomNumber:(int)from to:(int)to {
    return (from + (arc4random() % (to - from + 1)));
}

@end
