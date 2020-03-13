//
//  JXTransferViewController.m
//  shiku_im
//
//  Created by 1 on 2019/3/1.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXTransferViewController.h"
#import "UIImage+Color.h"
#import "JXVerifyPayVC.h"
#import "JXPayPasswordVC.h"

#define drawMarginX 25
#define bgWidth JX_SCREEN_WIDTH-15*2
#define drawHei 60

@interface JXTransferViewController () <UITextFieldDelegate,UITextViewDelegate,UIScrollViewDelegate>
@property (nonatomic, strong) UITextField * countTextField;
@property (nonatomic, strong) UIButton *transferBtn;
@property (nonatomic, strong) UILabel *addDscLab;
@property (nonatomic, strong) UILabel *dscLab;
@property (nonatomic, strong) NSString *desContent;
@property (nonatomic, strong) JXVerifyPayVC *verVC;


@property (nonatomic, strong) UIView *bigView;
@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UILabel *replayTitle;
@property (nonatomic, strong) UITextField *replayTextField;

@end

@implementation JXTransferViewController

- (instancetype)init {
    if (self = [super init]) {
        self.heightHeader = JX_SCREEN_TOP;
        self.heightFooter = 0;
        self.isGotoBack = YES;
        [self createHeadAndFoot];
        [self setupViews];
        
        [self setupReplayView];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = Localized(@"JX_Transfer");
}

- (void)setupViews {
    self.tableBody.backgroundColor = HEXCOLOR(0xefeff4);

    UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH/2-25, 10, 50, 50)];
    icon.layer.masksToBounds = YES;
    icon.layer.cornerRadius = icon.frame.size.width/2;
    [self.tableBody addSubview:icon];
   
    NSString *name = _user.remarkName.length > 0 ? _user.remarkName : _user.userNickname;
    [g_server getHeadImageLarge:_user.userId userName:name imageView:icon];
   
    CGSize size = [name sizeWithAttributes:@{NSFontAttributeName:SYSFONT(14)}];
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake((JX_SCREEN_WIDTH-size.width)/2, CGRectGetMaxY(icon.frame)+10, size.width, size.height)];
    nameLabel.font = SYSFONT(14);
    nameLabel.text = name;
    
    [self.tableBody addSubview:nameLabel];
    
    UIView *baseView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(nameLabel.frame)+10, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT- CGRectGetMaxY(nameLabel.frame)+10)];
    baseView.backgroundColor = [UIColor whiteColor];
    [self.tableBody addSubview:baseView];
    
    UIBezierPath *cornerRadiusPath = [UIBezierPath bezierPathWithRoundedRect:baseView.bounds byRoundingCorners:UIRectCornerTopRight | UIRectCornerTopLeft cornerRadii:CGSizeMake(15, 15)];
    CAShapeLayer *cornerRadiusLayer = [ [CAShapeLayer alloc ] init];
    cornerRadiusLayer.frame = baseView.bounds;
    cornerRadiusLayer.path = cornerRadiusPath.CGPath;
    baseView.layer.mask = cornerRadiusLayer;

    
    UILabel * cashTitle = [UIFactory createLabelWith:CGRectMake(drawMarginX, 0, 120, drawHei) text:Localized(@"JX_TransferAmount")];
    [baseView addSubview:cashTitle];
    
    UILabel * rmbLabel = [UIFactory createLabelWith:CGRectMake(drawMarginX, CGRectGetMaxY(cashTitle.frame), 35, 35) text:@"¥"];
    rmbLabel.font = g_factory.font28b;
    rmbLabel.textAlignment = NSTextAlignmentLeft;
    [baseView addSubview:rmbLabel];
    
    _countTextField = [UIFactory createTextFieldWithRect:CGRectMake(CGRectGetMaxX(rmbLabel.frame), CGRectGetMinY(rmbLabel.frame), bgWidth-CGRectGetMaxX(rmbLabel.frame)-drawMarginX, drawHei) keyboardType:UIKeyboardTypeDecimalPad secure:NO placeholder:nil font:[UIFont boldSystemFontOfSize:45] color:[UIColor blackColor] delegate:self];
    _countTextField.borderStyle = UITextBorderStyleNone;
    [baseView addSubview:_countTextField];
   [_countTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    UIView * line = [[UIView alloc] init];
    line.frame = CGRectMake(drawMarginX, CGRectGetMaxY(_countTextField.frame)+5, bgWidth-drawMarginX*2, 0.8);
    line.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.5];
    [baseView addSubview:line];
    
    //转账说明内容
    _dscLab = [[UILabel alloc] initWithFrame:CGRectMake(drawMarginX, CGRectGetMaxY(line.frame)+15, 0, 0)];
    [baseView addSubview:_dscLab];
    // 添加转账说明
    _addDscLab = [[UILabel alloc] initWithFrame:CGRectMake(drawMarginX, CGRectGetMaxY(line.frame)+15, 120, 18)];
    _addDscLab.text = Localized(@"JX_AddTransferInstructions");
    _addDscLab.textColor = HEXCOLOR(0x6E7B8F);
    _addDscLab.userInteractionEnabled = YES;
    [baseView addSubview:_addDscLab];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showSendTransferDsc)];
    [_addDscLab addGestureRecognizer:tap];

    
    _transferBtn = [UIFactory createButtonWithRect:CGRectZero title:Localized(@"JX_Transfer") titleFont:g_factory.font17 titleColor:[UIColor whiteColor] normal:nil selected:nil selector:@selector(transferBtnAction:) target:self];
    _transferBtn.tag = 1000;
    _transferBtn.frame = CGRectMake(drawMarginX, CGRectGetMaxY(_addDscLab.frame)+20, JX_SCREEN_WIDTH-drawMarginX*2, 50);
    [_transferBtn setBackgroundImage:[UIImage createImageWithColor:HEXCOLOR(0x1aad19)] forState:UIControlStateNormal];
    [_transferBtn setBackgroundImage:[UIImage createImageWithColor:[HEXCOLOR(0xa2dea3) colorWithAlphaComponent:0.8f]] forState:UIControlStateDisabled];
    _transferBtn .layer.cornerRadius = 5;
    _transferBtn.clipsToBounds = YES;
   _transferBtn.enabled = NO;
   
    [baseView addSubview:_transferBtn];
}


- (void)setupReplayView {
    int height = 44;
    self.bigView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.bigView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    self.bigView.hidden = YES;
    [g_App.window addSubview:self.bigView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    [self.bigView addGestureRecognizer:tap];
    
    self.baseView = [[UIView alloc] initWithFrame:CGRectMake(40, JX_SCREEN_HEIGHT/4-.5, JX_SCREEN_WIDTH-80, 162.5)];
    self.baseView.backgroundColor = [UIColor whiteColor];
    self.baseView.layer.masksToBounds = YES;
    self. baseView.layer.cornerRadius = 4.0f;
    [self.bigView addSubview:self.baseView];
    int n = 20;
    _replayTitle = [[UILabel alloc] initWithFrame:CGRectMake(INSETS, n, self.baseView.frame.size.width - INSETS*2, 20)];
    _replayTitle.lineBreakMode = NSLineBreakByTruncatingTail;
    _replayTitle.textAlignment = NSTextAlignmentCenter;
    _replayTitle.textColor = HEXCOLOR(0x595959);
    _replayTitle.font = [UIFont boldSystemFontOfSize:17];
    _replayTitle.text = Localized(@"JX_TransferInstructions");
    [self.baseView addSubview:_replayTitle];
    
    n = n + height;
    self.replayTextField = [self createTextField:self.baseView default:nil hint:nil];
    self.replayTextField.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1];
    self.replayTextField.frame = CGRectMake(10, n, self.baseView.frame.size.width - INSETS*2, 35.5);
    self.replayTextField.delegate = self;
    self.replayTextField.textColor = HEXCOLOR(0x595959);
    self.replayTextField.placeholder = Localized(@"JX_Maximum10Words");
    [self.replayTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    n = n + INSETS + height;
    self.topView = [[UIView alloc] initWithFrame:CGRectMake(0, n, self.baseView.frame.size.width, 44)];
    [self.baseView addSubview:self.topView];
    
    // 两条线
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.baseView.frame.size.width, 0.5)];
    topLine.backgroundColor = HEXCOLOR(0xD6D6D6);
    [self.topView addSubview:topLine];
    UIView *botLine = [[UIView alloc] initWithFrame:CGRectMake(self.baseView.frame.size.width/2, 0, 0.5, self.topView.frame.size.height)];
    botLine.backgroundColor = HEXCOLOR(0xD6D6D6);
    [self.topView addSubview:botLine];
    
    // 取消
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(topLine.frame), self.baseView.frame.size.width/2, botLine.frame.size.height)];
    [cancelBtn setTitle:Localized(@"JX_Cencal") forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [cancelBtn.titleLabel setFont:SYSFONT(15)];
    [cancelBtn addTarget:self action:@selector(hideBigView) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:cancelBtn];
    // 确定
    UIButton *sureBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.baseView.frame.size.width/2, CGRectGetMaxY(topLine.frame), self.baseView.frame.size.width/2, botLine.frame.size.height)];
    [sureBtn setTitle:Localized(@"JX_Confirm") forState:UIControlStateNormal];
    [sureBtn setTitleColor:HEXCOLOR(0x383893) forState:UIControlStateNormal];
    [sureBtn.titleLabel setFont:SYSFONT(15)];
    [sureBtn addTarget:self action:@selector(onRelease) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:sureBtn];
    
}
- (void)hideBigView {
    [self resignKeyBoard];
}

- (void)onRelease {
    [self resignKeyBoard];
    self.desContent = _replayTextField.text;
    
    _dscLab.text = self.desContent;
   _addDscLab.text = self.desContent.length > 0 ? Localized(@"JX_Modify") : Localized(@"JX_AddTransferInstructions");
    CGSize size = [self.desContent sizeWithAttributes:@{NSFontAttributeName:SYSFONT(17)}];
    _dscLab.frame = CGRectMake(drawMarginX, _dscLab.frame.origin.y, size.width, 18);
    _addDscLab.frame = CGRectMake(CGRectGetMaxX(_dscLab.frame)+5, _addDscLab.frame.origin.y, 120, 18);
}



#pragma mark - 转账
- (void)transferBtnAction:(UIButton *)button {
   if ([_countTextField.text doubleValue] > g_App.myMoney) {
      [g_App showAlert:Localized(@"CREDIT_LOW")];
      return;
   }
   if ([g_server.myself.isPayPassword boolValue]) {
      self.verVC = [JXVerifyPayVC alloc];
      self.verVC.type = JXVerifyTypeTransfer;
      self.verVC.RMB = self.countTextField.text;
      self.verVC.delegate = self;
      self.verVC.didDismissVC = @selector(dismissVerifyPayVC);
      self.verVC.didVerifyPay = @selector(didVerifyPay:);
      self.verVC = [self.verVC init];

      [self.view addSubview:self.verVC.view];
   } else {
      JXPayPasswordVC *payPswVC = [JXPayPasswordVC alloc];
      payPswVC.type = JXPayTypeSetupPassword;
      payPswVC.enterType = JXEnterTypeTransfer;
      payPswVC = [payPswVC init];
      [g_navigation pushViewController:payPswVC animated:YES];
   }

}

- (void)didVerifyPay:(NSString *)sender {
   long time = (long)[[NSDate date] timeIntervalSince1970];
   NSString *secret = [self getSecretWithText:sender time:time];
   [g_server transferUserId:_user.userId money:_countTextField.text remark:_replayTextField.text time:time secret:secret toView:self];
}


- (void)dismissVerifyPayVC {
   [self.verVC.view removeFromSuperview];
}

- (void)showSendTransferDsc{
    self.bigView.hidden = NO;
    [self.replayTextField becomeFirstResponder];
}


- (void)textFieldDidChange:(UITextField *)textField {
   if (textField == _countTextField) {
      if ([textField.text doubleValue] > 0) {
         _transferBtn.enabled = YES;
      }else {
         _transferBtn.enabled = NO;
      }
   }
//   if (textField == _replayTextField) {
//      if (textField.text.length > 10) {
//         textField.text = [textField.text substringToIndex:10];
//      }
//   }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
   NSString * toBeString = [textField.text stringByReplacingCharactersInRange:range withString:string];
   if (textField == _countTextField) {
      // 首位不能输入 .
      if (IsStringNull(textField.text) && [string isEqualToString:@"."]) {
         return NO;
      }
      //限制.后面最多有两位，且不能再输入.
      if ([textField.text rangeOfString:@"."].location != NSNotFound) {
         //有.了 且.后面输入了两位  停止输入
         if (toBeString.length > [toBeString rangeOfString:@"."].location+3) {
            return NO;
         }
         //有.了，不允许再输入.
         if ([string isEqualToString:@"."]) {
            return NO;
         }
      }
      //限制首位0，后面只能输入. 和 删除
      if ([textField.text isEqualToString:@"0"]) {
         if (![string isEqualToString:@"."] && ![string isEqualToString:@""]) {
            return NO;
         }
      }
      //限制只能输入：1234567890.
      NSCharacterSet * characterSet = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890."] invertedSet];
      NSString * filtered = [[string componentsSeparatedByCharactersInSet:characterSet] componentsJoinedByString:@""];
      return [string isEqualToString:filtered];
   }
   if (textField == self.replayTextField) {
      if (toBeString.length > 10) {
         return NO;
      }
   }

   return YES;
}


-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
   if( [aDownload.action isEqualToString:act_sendTransfer]){
      [self dismissVerifyPayVC];  // 销毁支付密码界面
      
      if (self.delegate && [self.delegate respondsToSelector:@selector(transferToUser:)]) {
         [self.delegate performSelector:@selector(transferToUser:) withObject:dict];
      }
      [self actionQuit];

   }
}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
   [_wait stop];
   if ([aDownload.action isEqualToString:act_sendTransfer]) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
         [self.verVC clearUpPassword];
      });
   }

   return show_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
   
   [_wait stop];
   return show_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
      [_wait start];
}



- (void)resignKeyBoard {
    self.bigView.hidden = YES;
    [self hideKeyBoard];
    [self resetBigView];
}

- (void)resetBigView {
    self.replayTextField.frame = CGRectMake(10, 64, self.baseView.frame.size.width - INSETS*2, 35.5);
    self.baseView.frame = CGRectMake(40, JX_SCREEN_HEIGHT/4-.5, JX_SCREEN_WIDTH-80, 162.5);
    self.topView.frame = CGRectMake(0, 118, self.baseView.frame.size.width, 40);
}

- (void)hideKeyBoard {
    if (self.replayTextField.isFirstResponder) {
        [self.replayTextField resignFirstResponder];
    }
}


-(UITextField*)createTextField:(UIView*)parent default:(NSString*)s hint:(NSString*)hint{
    UITextField* p = [[UITextField alloc] initWithFrame:CGRectMake(0,INSETS,JX_SCREEN_WIDTH,54)];
    p.delegate = self;
    p.autocorrectionType = UITextAutocorrectionTypeNo;
    p.autocapitalizationType = UITextAutocapitalizationTypeNone;
    p.enablesReturnKeyAutomatically = YES;
    p.textAlignment = NSTextAlignmentLeft;
    p.userInteractionEnabled = YES;
    p.backgroundColor = [UIColor whiteColor];
    p.text = s;
    p.font = g_factory.font16;
    [parent addSubview:p];
    return p;
}

- (NSString *)getSecretWithText:(NSString *)text time:(long)time {
   NSMutableString *str1 = [NSMutableString string];
   [str1 appendString:APIKEY];
   [str1 appendString:[NSString stringWithFormat:@"%ld",time]];
   [str1 appendString:[NSString stringWithFormat:@"%@",[NSNumber numberWithDouble:[_countTextField.text doubleValue]]]];
   str1 = [[g_server getMD5String:str1] mutableCopy];
   
   [str1 appendString:g_myself.userId];
   [str1 appendString:g_server.access_token];
   NSMutableString *str2 = [NSMutableString string];
   str2 = [[g_server getMD5String:text] mutableCopy];
   [str1 appendString:str2];
   str1 = [[g_server getMD5String:str1] mutableCopy];
   
   return [str1 copy];
   
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
   if (scrollView == self.tableBody) {
      if ([self.countTextField isFirstResponder]) {
         [self.countTextField resignFirstResponder];
      }
   }
}

@end
