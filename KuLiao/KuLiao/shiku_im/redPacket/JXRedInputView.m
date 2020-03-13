//
//  JXRedInputView.m
//  shiku_im
//
//  Created by 1 on 17/8/15.
//  Copyright © 2017年 Reese. All rights reserved.
//

#import "JXRedInputView.h"

#define RowHeight 44
#define RowMargin 20

@interface JXRedInputView (){
    CGFloat _greetY;
    CGFloat _countY;
    CGFloat _moneyY;
}

@end


@implementation JXRedInputView

-(instancetype)initWithFrame:(CGRect)frame type:(NSUInteger)type isRoom:(BOOL)isRoom delegate:(id)delegate{
    if (self = [super initWithFrame:frame]) {
        self.frame = frame;
        self.type = type;
        self.delegate = delegate;
        self.isRoom = isRoom;
        
        [self customSubViews];
    }
    return self;
}

-(instancetype)init{
    if (self = [super init]) {
        [self customSubViews];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self customSubViews];
    }
    return self;
}

-(void)layoutSubviews{
    if (_type == 3) {
        _greetY = RowMargin;
        if(_isRoom){
            _countY = RowMargin*2 + RowHeight;
            _moneyY = _countY +RowMargin + RowHeight;
        }else{
            _moneyY = RowMargin*2 + RowHeight;
        }
    }else{
        if(_isRoom){
            _countY = RowMargin;
            _moneyY = _countY +RowMargin + RowHeight;
        }else{
            _moneyY = RowMargin;
        }
        _greetY = _moneyY +RowMargin*2 + RowHeight;
    }
    
    if(_isRoom){
        _countView.frame = CGRectMake(15, _countY, self.frame.size.width-15*2, RowHeight);
        _countUnit.frame = CGRectMake(CGRectGetWidth(_countView.frame)-40, 0, 40, RowHeight);
        _countTextField.frame = CGRectMake(CGRectGetMaxX(_countTitle.frame), 0, CGRectGetMinX(_countUnit.frame)-CGRectGetMaxX(_countTitle.frame), RowHeight);
    }
    _moneyView.frame = CGRectMake(15, _moneyY, self.frame.size.width-15*2, RowHeight);
    _moneyUnit.frame = CGRectMake(CGRectGetWidth(_moneyView.frame)-40, 0, 40, RowHeight);
    _moneyTextField.frame = CGRectMake(CGRectGetMaxX(_moneyTitle.frame), 0, CGRectGetMinX(_moneyUnit.frame)-CGRectGetMaxX(_moneyTitle.frame), RowHeight);
    
    _greetView.frame = CGRectMake(15, _greetY, self.frame.size.width-15*2, RowHeight);
    
    _sendButton.frame = CGRectMake(50, RowHeight*3+RowMargin*6, self.frame.size.width-50*2, 40);
    _sendButton.tag = _type;
    
    _noticeTitle.frame = CGRectMake(0, -20, CGRectGetWidth(_greetView.frame), 20);
    
    if (_type == 3) {
        _greetTitle.hidden = NO;
        _greetTextField.frame = CGRectMake(CGRectGetMaxX(_greetTitle.frame), 0, CGRectGetWidth(_greetView.frame)-CGRectGetWidth(_greetTitle.frame), RowHeight);
    }else{
        _greetTitle.hidden = YES;
        _greetTextField.frame = CGRectMake(0, 0, CGRectGetWidth(_greetView.frame), RowHeight);
    }
    
    [self viewLocalized];
}

-(void)viewLocalized{
    _countTitle.text = Localized(@"JXRed_numberPackets");// @"红包个数";//
    _moneyTitle.text = Localized(@"JXRed_totalAmount");//@"总金额";//
    _countUnit.text = Localized(@"JXRed_A");//@"个";//
    _moneyUnit.text = Localized(@"JX_ChinaMoney");//@"元";//
    [_sendButton setTitle:Localized(@"JXRed_send") forState:UIControlStateNormal];//@"塞钱进红包"
    [_sendButton setTitle:Localized(@"JXRed_send") forState:UIControlStateHighlighted];
    _moneyTextField.placeholder = Localized(@"JXRed_inputAmount");//@"输入金额";//
    _countTextField.placeholder = Localized(@"JXRed_inputNumPackets");//@"请输入红包个数";//
    
    switch (_type) {
        case 1:{
            _noticeTitle.text = Localized(@"JXRed_sameAmount");//@"小伙伴领取的金额相同";//
            _greetTextField.placeholder = Localized(@"JXRed_greetOlace");//@"恭喜发财，万事如意";// Congratulation, everything goes well
            
            
            break;
        }
        case 2:{
            _noticeTitle.text = Localized(@"JXRed_ARandomAmount");//@"小伙伴领取的金额随机";//
            _greetTextField.placeholder = Localized(@"JXRed_greetOlace");//@"恭喜发财，万事如意";
            
            break;
        }
        case 3:{
            _noticeTitle.text = Localized(@"JXRed_NoticeOrder");//@"小伙伴需回复口令抢红包";//
            _greetTextField.placeholder = Localized(@"JXRed_orderPlace");//@"如“我真帅”";// eg."I'm so handsome";
            _greetTitle.text = Localized(@"JXRed_setOrder");//@"设置口令";//
            break;
        }
        default:
            break;
    }
}

-(void)customSubViews{
    if(_isRoom)
        [self addSubview:self.countView];
    [self addSubview:self.moneyView];
    [self addSubview:self.greetView];
    
    [self addSubview:self.sendButton];
}


-(UIView *)countView{
    if (!_countView) {
        _countView = [[UIView alloc] init];
            _countView.backgroundColor = [UIColor whiteColor];
        [_countView addSubview:self.countTitle];
        [_countView addSubview:self.countTextField];
        [_countView addSubview:self.countUnit];
    }
    return _countView;
}

-(UIView *)moneyView{
    if (!_moneyView) {
        _moneyView = [[UIView alloc] init];
        _moneyView.backgroundColor = [UIColor whiteColor];
        [_moneyView addSubview:self.moneyTitle];
        [_moneyView addSubview:self.moneyTextField];
        [_moneyView addSubview:self.moneyUnit];
    }
    return _moneyView;
}

-(UIView *)greetView{
    if (!_greetView) {
        _greetView = [[UIView alloc] init];
        _greetView.backgroundColor = [UIColor whiteColor];
        [_greetView addSubview:self.greetTitle];
        [_greetView addSubview:self.greetTextField];
        [_greetView addSubview:self.noticeTitle];
    }
    return _greetView;
}

-(UIButton *)sendButton{
    if (!_sendButton) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sendButton setBackgroundImage:[g_theme themeTintImage:@"feaBtn_backImg_sel"] forState:UIControlStateNormal];
        [_sendButton.titleLabel setFont:g_factory.font15];
        
    }
    return _sendButton;
}

-(UILabel *)noticeTitle{
    if (!_noticeTitle) {
        _noticeTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, -20, 200, 20)];
        _noticeTitle.font = g_factory.font14;
        _noticeTitle.textColor = [UIColor lightGrayColor];
    }
    return _noticeTitle;
}

-(UILabel *)countTitle{
    if (!_countTitle) {
        _countTitle = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 80, RowHeight)];
        _countTitle.font = g_factory.font15;
        _countTitle.textColor = [UIColor blackColor];
//        _countTitle.text = @"红包个数";
    }
    return _countTitle;
}
-(UILabel *)moneyTitle{
    if (!_moneyTitle) {
        _moneyTitle = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 80, RowHeight)];
        _moneyTitle.font = g_factory.font15;
        _moneyTitle.textColor = [UIColor blackColor];
//        _moneyTitle.text = @"总金额";
    }
    return _moneyTitle;
}
-(UILabel *)greetTitle{
    if (!_greetTitle) {
        _greetTitle = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 80, RowHeight)];
        _greetTitle.font = g_factory.font15;
        _greetTitle.textColor = [UIColor blackColor];
    }
    return _greetTitle;
}


-(UITextField *)countTextField{
    if (!_countTextField) {
        _countTextField = [UIFactory createTextFieldWith:CGRectZero delegate:_delegate returnKeyType:UIReturnKeyNext secureTextEntry:NO placeholder:nil font:g_factory.font14];
        _countTextField.text = @"";    // 红包默认最少为1个
        _countTextField.clearButtonMode = UITextFieldViewModeNever;
        _countTextField.textAlignment = NSTextAlignmentRight;
        _countTextField.borderStyle = UITextBorderStyleNone;
        _countTextField.keyboardType = UIKeyboardTypeNumberPad;
    }
    return _countTextField;
}
-(UITextField *)moneyTextField{
    if (!_moneyTextField) {
        _moneyTextField = [UIFactory createTextFieldWith:CGRectZero delegate:_delegate returnKeyType:UIReturnKeyNext secureTextEntry:NO placeholder:nil font:g_factory.font14];
        _moneyTextField.clearButtonMode = UITextFieldViewModeNever;
        _moneyTextField.textAlignment = NSTextAlignmentRight;
        _moneyTextField.borderStyle = UITextBorderStyleNone;
        _moneyTextField.keyboardType = UIKeyboardTypeDecimalPad;
    }
    return _moneyTextField;
}
-(UITextField *)greetTextField{
    if (!_greetTextField) {
        _greetTextField = [UIFactory createTextFieldWith:CGRectZero delegate:_delegate returnKeyType:UIReturnKeyNext secureTextEntry:NO placeholder:nil font:g_factory.font14];
        _greetTextField.textAlignment = NSTextAlignmentLeft;
        _greetTextField.borderStyle = UITextBorderStyleNone;
        _greetTextField.keyboardType = UIKeyboardTypeDefault;
    }
    return _greetTextField;
}


-(UILabel *)countUnit{
    if (!_countUnit) {
        _countUnit = [[UILabel alloc] initWithFrame:CGRectZero];
        _countUnit.font = g_factory.font15;
        _countUnit.textColor = [UIColor blackColor];
        _countUnit.textAlignment = NSTextAlignmentCenter;
//        _countUnit.text = @"个";
    }
    return _countUnit;
}
-(UILabel *)moneyUnit{
    if (!_moneyUnit) {
        _moneyUnit = [[UILabel alloc] initWithFrame:CGRectZero];
        _moneyUnit.font = g_factory.font15;
        _moneyUnit.textColor = [UIColor blackColor];
        _moneyUnit.textAlignment = NSTextAlignmentCenter;
//        _moneyUnit.text = @"元";
    }
    return _moneyUnit;
}



-(void)stopEdit{
    [_countTextField resignFirstResponder];
    [_moneyTextField resignFirstResponder];
    [_greetTextField resignFirstResponder];
}

@end
