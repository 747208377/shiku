//
//  JXTransferNoticeCell.m
//  shiku_im
//
//  Created by 1 on 2019/3/8.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXTransferNoticeCell.h"
#import "JXTransferNoticeModel.h"
#import "JXTransferModel.h"
#import "JXTransferOpenPayModel.h"

@interface JXTransferNoticeCell ()
@property (nonatomic, strong) UIView *baseView;

@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UILabel *moneyTit;
@property (nonatomic, strong) UILabel *moneyLab;
@property (nonatomic, strong) UILabel *payTit;
@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *noteTit;
@property (nonatomic, strong) UILabel *noteLab;


@property (nonatomic, strong) UILabel *backLab;
@property (nonatomic, strong) UILabel *backTime;
@property (nonatomic, strong) UILabel *sendLab;
@property (nonatomic, strong) UILabel *sendTime;

@end

@implementation JXTransferNoticeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        _baseView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, JX_SCREEN_WIDTH-20, 200)];
        _baseView.backgroundColor = [UIColor whiteColor];
        _baseView.layer.masksToBounds = YES;
        _baseView.layer.cornerRadius = 3.f;
        [self.contentView addSubview:_baseView];
        
        _title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 200, 18)];
        [_baseView addSubview:_title];
        
        //收款金额
        _moneyTit = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_title.frame)+10, _baseView.frame.size.width, 18)];
        _moneyTit.text = Localized(@"JX_GetMoney");
        _moneyTit.textAlignment = NSTextAlignmentCenter;
        _moneyTit.textColor = [UIColor lightGrayColor];
        [_baseView addSubview:_moneyTit];
        
        _moneyLab = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_moneyTit.frame)+10, _baseView.frame.size.width, 43)];
        _moneyLab.textAlignment = NSTextAlignmentCenter;
        _moneyLab.font = [UIFont boldSystemFontOfSize:40];
        [_baseView addSubview:_moneyLab];

        //第一行
        _payTit = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(_moneyLab.frame)+20, 80, 18)];
        _payTit.textColor = [UIColor lightGrayColor];
        [_baseView addSubview:_payTit];
        
        _nameLab = [[UILabel alloc] initWithFrame:CGRectMake(90, _payTit.frame.origin.y, _baseView.frame.size.width-70, 18)];
        _nameLab.textColor = [UIColor lightGrayColor];
        [_baseView addSubview:_nameLab];
        
        //第二行
        _noteTit = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(_payTit.frame)+10, 80, 18)];
        _noteTit.textColor = [UIColor lightGrayColor];
        [_baseView addSubview:_noteTit];
        
        _noteLab = [[UILabel alloc] initWithFrame:CGRectMake(90, _noteTit.frame.origin.y, _baseView.frame.size.width-70, 18)];
        _noteLab.textColor = [UIColor lightGrayColor];
        [_baseView addSubview:_noteLab];
        
        //第三行
        _backLab = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(_noteTit.frame)+10, 80, 18)];
        _backLab.text = Localized(@"JX_ReturnTheTime");
        _backLab.textColor = [UIColor lightGrayColor];
        [_baseView addSubview:_backLab];
        
        _backTime = [[UILabel alloc] initWithFrame:CGRectMake(90, _backLab.frame.origin.y, _baseView.frame.size.width-70, 18)];
        _backTime.textColor = [UIColor lightGrayColor];
        [_baseView addSubview:_backTime];
        
        //第四行
        _sendLab = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(_backLab.frame)+10, 80, 18)];
        _sendLab.text = Localized(@"JX_TransferTime");
        _sendLab.textColor = [UIColor lightGrayColor];
        [_baseView addSubview:_sendLab];
        
        _sendTime = [[UILabel alloc] initWithFrame:CGRectMake(90, _sendLab.frame.origin.y, _baseView.frame.size.width-70, 18)];
        _sendTime.textColor = [UIColor lightGrayColor];
        [_baseView addSubview:_sendTime];
    }
    return self;
}


- (void)setDataWithMsg:(JXMessageObject *)msg model:(id)tModel {
    if ([msg.type intValue] == kWCMessageTypeTransferBack) {
        JXTransferModel *model = (JXTransferModel *)tModel;
        _moneyTit.text = Localized(@"JX_Refunds");
        _payTit.text = Localized(@"JX_TheRefundWay");
        _nameLab.text = Localized(@"JX_ReturnedToTheChange");
        _noteTit.text = Localized(@"JX_ReturnReason");
        [self hideTime:NO];
        _moneyLab.text = [NSString stringWithFormat:@"¥%.2f",model.money];
        _backTime.text = model.outTime;
        _sendTime.text = model.createTime;
        _baseView.frame = CGRectMake(10, 10, JX_SCREEN_WIDTH-20, 200+56);
    }
    else if ([msg.type intValue] == kWCMessageTypeOpenPaySuccess) {
        JXTransferOpenPayModel *model = (JXTransferOpenPayModel *)tModel;
        _noteTit.text = Localized(@"JX_Note");
        _payTit.text = @"收款方";
        _nameLab.text = model.name;;
        [self hideTime:YES];
        _moneyLab.text = [NSString stringWithFormat:@"¥%.2f",model.money];
        _baseView.frame = CGRectMake(10, 10, JX_SCREEN_WIDTH-20, 200);
    }
    else {
        JXTransferNoticeModel *model = (JXTransferNoticeModel *)tModel;
        _noteTit.text = Localized(@"JX_Note");
        if (model.type == 1 && [model.userId intValue] == [MY_USER_ID intValue]) {
            _payTit.text = Localized(@"JX_Payee");
            _nameLab.text = model.toUserName;
        }
        else if (model.type == 1 && [model.userId intValue] != [MY_USER_ID intValue]) {
            _payTit.text = Localized(@"JX_Drawee");
            _nameLab.text = model.userName;
        }
        else if (model.type == 2 && [model.userId intValue] == [MY_USER_ID intValue]) {
            _payTit.text = Localized(@"JX_Drawee");
            _nameLab.text = model.toUserName;
        }
        else if (model.type == 2 && [model.userId intValue] != [MY_USER_ID intValue]){
            _payTit.text = Localized(@"JX_Payee");
            _nameLab.text = model.userName;
        }
        [self hideTime:YES];
        _moneyLab.text = [NSString stringWithFormat:@"¥%.2f",model.money];
        _baseView.frame = CGRectMake(10, 10, JX_SCREEN_WIDTH-20, 200);
    }
    _title.text = [self getTitle:[msg.type intValue]];
    _noteLab.text = [self getNote:msg];
}

- (void)hideTime:(BOOL)isHide {
    _backLab.hidden = isHide;
    _backTime.hidden = isHide;
    _sendLab.hidden = isHide;
    _sendTime.hidden = isHide;
}


- (NSString *)getTitle:(int)type {
    NSString *string;
    // 过期退还
    if (type == kWCMessageTypeTransferBack) {
        string = Localized(@"JX_RefundNoticeOfOverdueTransfer");
    }
    // 支付通知
    else if (type == kWCMessageTypePaymentOut || type == kWCMessageTypeReceiptOut) {
        string = Localized(@"JX_PaymentNo.");
    }
    // 收款通知
    else if (type == kWCMessageTypePaymentGet || type == kWCMessageTypeReceiptGet) {
        string = Localized(@"JX_ReceiptNotice");
    }
    
    // 第三方调用IM支付
    if (type == kWCMessageTypeOpenPaySuccess) {
        string = @"支付凭证";
    }

    return string;
}

- (NSString *)getNote:(JXMessageObject *)msg {
    NSString *string;
    // 过期退还
    if ([msg.type intValue] == kWCMessageTypeTransferBack) {
        string = Localized(@"JX_TransferIsOverdueAndTheChange");
    }
    // 支付通知
    else if ([msg.type intValue] == kWCMessageTypePaymentOut || [msg.type intValue] == kWCMessageTypeReceiptOut) {
        string = Localized(@"JX_PaymentToFriend");
    }
    // 收款通知
    else if ([msg.type intValue] == kWCMessageTypePaymentGet || [msg.type intValue] == kWCMessageTypeReceiptGet) {
        string = Localized(@"JX_PaymentReceived");
    }
    // 转账退款通知
    else if ([msg.type intValue] == kWCMessageTypeTransferBack) {
        string = [NSString stringWithFormat:@"%@%@",msg.toUserName,Localized(@"JX_NotReceive24Hours")];
    }
    
    // 第三方调用IM支付通知
    if ([msg.type intValue] == kWCMessageTypeOpenPaySuccess) {
        string = @"支付成功，对方已收款";
    }
    
    return string;
}

+ (float)getChatCellHeight:(JXMessageObject *)msg {
    if ([msg.type intValue] == kWCMessageTypeTransferBack) {
        return 215+56;
    }else {
        return 215;
    }
    return 0;
}


@end
