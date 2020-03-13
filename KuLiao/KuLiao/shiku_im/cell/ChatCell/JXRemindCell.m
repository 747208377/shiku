//
//  JXRemindCell.m
//  shiku_im
//
//  Created by Apple on 16/10/11.
//  Copyright © 2016年 Reese. All rights reserved.
//

#import "JXRemindCell.h"
#import "JXRoomRemind.h"

@implementation JXRemindCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

-(void)creatUI{
    _messageRemind=[[UILabel alloc] initWithFrame:CGRectMake(0, 2, 200, 20)];
    _messageRemind.userInteractionEnabled = NO;
    _messageRemind.lineBreakMode = NSLineBreakByCharWrapping;
    _messageRemind.numberOfLines = 0;
    _messageRemind.textAlignment = NSTextAlignmentCenter;
    _messageRemind.backgroundColor = HEXCOLOR(0xB5B5B5);
    _messageRemind.layer.borderWidth = 1;
    _messageRemind.layer.borderColor = HEXCOLOR(0xB5B5B5).CGColor;
    _messageRemind.textColor = [UIColor whiteColor];
    _messageRemind.font = g_factory.font13;
    _messageRemind.layer.cornerRadius = 6;
    _messageRemind.layer.masksToBounds = YES;
    [self.contentView addSubview:_messageRemind];
//    [_messageRemind release];
    
    self.confirmBtn = [[UIButton alloc] init];
    self.confirmBtn.backgroundColor = [UIColor clearColor];
    [self.confirmBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.confirmBtn];
    
}

- (void)btnAction:(UIButton *)btn {
    [g_notify postNotificationName:kCellRemindNotifaction object:self.msg];
}

-(void)setCellData{
    if([self.msg.type intValue] == kWCMessageTypeRemind){
        
//        _messageRemind.textColor = [UIColor whiteColor];
//        _messageRemind.backgroundColor = HEXCOLOR(0xB5B5B5);
        
        NSString *content;
        if (self.msg.isShowTime) {
            NSString* t = [TimeUtil formatDate:self.msg.timeSend format:@"MM-dd HH:mm"];
            content = [NSString stringWithFormat:@"%@ (%@)",self.msg.content,t];
            t = nil;
        }else {
            content = [NSString stringWithFormat:@"%@",self.msg.content];
        }
        
        
        NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:content];
        NSRange range = [content rangeOfString:Localized(@"JX_ToConfirm")];
        NSRange range1 = [content rangeOfString:Localized(@"JX_VerifyConfirmed")];
        if (range.location == NSNotFound) {
            range = range1;
        }
        if (range.location != NSNotFound) {
            [att addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:range];
            self.msg.remindType = [NSNumber numberWithInt:kRoomRemind_NeedVerify];
        }
        NSRange range2 = [content rangeOfString:Localized(@"JX_ShikuRedPacket")];
        if (range.location == NSNotFound) {
            if (range2.location != NSNotFound) {
                range = range2;
                [att addAttribute:NSForegroundColorAttributeName value:HEXCOLOR(0xF58A2E) range:range2];
                self.msg.remindType = [NSNumber numberWithInt:kWCMessageTypeRedPacketReceive];
            }
        }
        

        _messageRemind.attributedText = att;
        
        CGSize size = [_messageRemind.text boundingRectWithSize:CGSizeMake(JX_SCREEN_WIDTH - 20, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:g_factory.font13} context:nil].size;
        int w = size.width + 5;
        _messageRemind.frame = CGRectMake((JX_SCREEN_WIDTH-w)/2, 2, w, size.height + 5);
        
        if (range.location != NSNotFound) {
            [att addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:range];
            NSString *str = [content substringToIndex:range.location];
            CGSize size = [str boundingRectWithSize:CGSizeMake(JX_SCREEN_WIDTH - 20, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:g_factory.font13} context:nil].size;
            self.confirmBtn.frame = CGRectMake(size.width + _messageRemind.frame.origin.x, 0, 50, size.height + 5);
        }
    }
}

+ (float)getChatCellHeight:(JXMessageObject *)msg {
    
    NSString *str = nil;
    if (msg.isShowTime) {
        NSString* t = [TimeUtil formatDate:msg.timeSend format:@"MM-dd HH:mm"];
        str = [NSString stringWithFormat:@"%@ (%@)",msg.content,t];
        t = nil;
    }else {
        str = [NSString stringWithFormat:@"%@",msg.content];
    }
    
    CGSize size = [str boundingRectWithSize:CGSizeMake(JX_SCREEN_WIDTH - 20, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:g_factory.font13} context:nil].size;
    float n = size.height + 5 + 6;
    return n;
}

-(void)didTouch:(UIButton*)button{
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
