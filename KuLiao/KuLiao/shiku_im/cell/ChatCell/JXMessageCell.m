//
//  JXMessageCell.m
//  shiku_im
//
//  Created by Apple on 16/10/10.
//  Copyright © 2016年 Reese. All rights reserved.
//

#import "JXMessageCell.h"


//#define TEXT_MAX_HEIGHT 500.0f



@implementation JXMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
//    self.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, 55);
}

- (void)dealloc {
    
    [self.readDelTimer invalidate];
    self.readDelTimer = nil;
}

-(void)creatUI{
    _messageConent=[[JXEmoji alloc] init];
//    _messageConent.userInteractionEnabled = YES;
    _messageConent.lineBreakMode = NSLineBreakByWordWrapping;
    _messageConent.numberOfLines = 0;
    _messageConent.backgroundColor = [UIColor clearColor];
    _messageConent.font = [UIFont systemFontOfSize:g_constant.chatFont];
//    _messageConent.userInteractionEnabled = NO;
    [self.bubbleBg addSubview:_messageConent];

    _timeIndexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    _timeIndexLabel.layer.cornerRadius = _timeIndexLabel.frame.size.width / 2;
    _timeIndexLabel.layer.masksToBounds = YES;
    _timeIndexLabel.textColor = [UIColor whiteColor];
    _timeIndexLabel.backgroundColor = HEXCOLOR(0x02d8c9);
    _timeIndexLabel.textAlignment = NSTextAlignmentCenter;
    _timeIndexLabel.text = @"0";
    _timeIndexLabel.font = [UIFont systemFontOfSize:12.0];
    _timeIndexLabel.hidden = YES;
    [self.contentView addSubview:_timeIndexLabel];
}

-(void)setCellData{
    [super setCellData];
    
    _messageConent.font = [UIFont systemFontOfSize:g_constant.chatFont];
    _messageConent.frame = CGRectMake(0, 0, 200, 20);
    if (self.msg.objectId.length > 0) {
        _messageConent.atUserIdS = self.msg.objectId;
    }
    if ([self.msg.isReadDel boolValue] && [self.msg.fileName length] <= 0 && !self.msg.isMySend) {
        _messageConent.userInteractionEnabled = NO;
        _messageConent.text = [NSString stringWithFormat:@"%@ T", Localized(@"JX_ClickAndView")];
        _messageConent.textColor = HEXCOLOR(0x0079FF);
        _timeIndexLabel.hidden = YES;
    }else {
        _messageConent.userInteractionEnabled = YES;
        _messageConent.textColor = [UIColor blackColor];
        _messageConent.text = self.msg.content;
        _timeIndexLabel.hidden = YES;
        if (!self.msg.isMySend && [self.msg.fileName isKindOfClass:[NSString class]] && [self.msg.fileName length] > 0 && [self.msg.fileName intValue] >= 0) {
            self.timeIndexLabel.hidden = NO;
            
            NSString *messageR = [self.msg.content stringByReplacingOccurrencesOfString:@"\r" withString:@""];  //去掉回车键
            NSString *messageN = [messageR stringByReplacingOccurrencesOfString:@"\n" withString:@""];  //去掉回车键
            NSString *messageText = [messageN stringByReplacingOccurrencesOfString:@" " withString:@""];  //去掉空格
            CGSize size = [messageText boundingRectWithSize:CGSizeMake(_messageConent.frame.size.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:SYSFONT(g_constant.chatFont)} context:nil].size;
            NSInteger count = size.height / _messageConent.font.lineHeight;
            NSLog(@"countcount ===  %ld-----%f-----%@",count,[[NSDate date] timeIntervalSince1970],self.msg.fileName);
//            NSLog(@"countcount === %ld,,,,%f,,,,%@",count,[[NSDate date] timeIntervalSince1970], self.msg.fileName);
            count = count * 10 - ([[NSDate date] timeIntervalSince1970] - [self.msg.fileName longLongValue]);
            self.timerIndex = count;
            
            NSLog(@"countcount1 ===  %ld",count);
            if (count > 0) {
                self.timeIndexLabel.text = [NSString stringWithFormat:@"%ld",count];
                if (!self.readDelTimer) {
                    self.readDelTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
                }
            }else {
                
                self.msg.fileName = @"0";
                
                //阅后即焚通知
                [g_notify postNotificationName:kCellReadDelNotification object:self.msg];
                [self deleteMsg:self.msg];
            }
            
            
        }
    }
    [self creatBubbleBg];
}
-(void)creatBubbleBg{
    CGSize textSize = _messageConent.frame.size;
    int n = textSize.width;
    //聊天长度反正就是算错了，强行改
    if(n){
//        n -= 10;
    }
    if(self.msg.isMySend){
        self.bubbleBg.frame=CGRectMake(JX_SCREEN_WIDTH-INSETS*4-HEAD_SIZE-n - 2+CHAT_WIDTH_ICON, INSETS, n+INSETS*2, textSize.height+INSETS*2);
        [_messageConent setFrame:CGRectMake(INSETS*0.4 + 3, INSETS, n + 5, textSize.height)];
        _timeIndexLabel.frame = CGRectMake(self.bubbleBg.frame.origin.x - 30, self.bubbleBg.frame.origin.y, 20, 20);
        
        //            _messageConent.textAlignment = NSTextAlignmentRight;
    }else
    {
        self.bubbleBg.frame=CGRectMake(CGRectGetMaxX(self.headImage.frame) + INSETS-CHAT_WIDTH_ICON, INSETS2(self.msg.isGroup), n+INSETS*2, textSize.height+INSETS*2);
        [_messageConent setFrame:CGRectMake(INSETS + 3, INSETS, n + 5, textSize.height)];
        _timeIndexLabel.frame = CGRectMake(CGRectGetMaxX(self.bubbleBg.frame) + 10, self.bubbleBg.frame.origin.y, 20, 20);
        //            _messageConent.textAlignment = NSTextAlignmentLeft;
    }
    if (self.msg.isShowTime) {
        CGRect frame = self.bubbleBg.frame;
        frame.origin.y = self.bubbleBg.frame.origin.y + 40;
        self.bubbleBg.frame = frame;
        
        _timeIndexLabel.frame = CGRectMake(_timeIndexLabel.frame.origin.x, self.bubbleBg.frame.origin.y, 20, 20);
    }
    
}

- (void)setBackgroundImage {
    [super setBackgroundImage];
    if (!self.msg.isMySend && [self.msg.fileName isKindOfClass:[NSString class]] && [self.msg.fileName length] > 0 && [self.msg.fileName intValue] >= 0 && [self.msg.type intValue] == kWCMessageTypeText) {
        self.isDidMsgCell = YES;
    }
    if ([self.msg.isReadDel boolValue] && !self.msg.isMySend && self.isDidMsgCell) {
        [self drawReadDelView:YES];
        self.isDidMsgCell = NO;
    }

}

//复制信息到剪贴板
- (void)myCopy{
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:self.msg.content];
}

+ (float)getChatCellHeight:(JXMessageObject *)msg {
    
    if ([msg.chatMsgHeight floatValue] > 1) {
            return [msg.chatMsgHeight floatValue];
    }
    float n;
    JXEmoji *messageConent=[[JXEmoji alloc]initWithFrame:CGRectMake(0, 0, 200, 20)];
    messageConent.backgroundColor = [UIColor clearColor];
//    messageConent.userInteractionEnabled = NO;
    messageConent.numberOfLines = 0;
    messageConent.lineBreakMode = NSLineBreakByWordWrapping;//UILineBreakModeWordWrap;
    messageConent.font = [UIFont systemFontOfSize:g_constant.chatFont];
    messageConent.offset = -12;
    
    messageConent.frame = CGRectMake(0, 0, 200, 20);
    if ([msg.isReadDel boolValue] && [msg.fileName intValue] <= 0 && !msg.isMySend) {
        messageConent.text = [NSString stringWithFormat:@"%@ T", Localized(@"JX_ClickAndView")];
    }else {
        messageConent.text = msg.content;
    }
    
    if (msg.isGroup && !msg.isMySend) {
        n = messageConent.frame.size.height+10*3 + 20;
        if (msg.isShowTime) {
            n=messageConent.frame.size.height+10*3 + 40 + 20;
        }
    }else {
        n= messageConent.frame.size.height+10*3 + 10;
        if (msg.isShowTime) {
            n=messageConent.frame.size.height+10*3 + 40 + 10;
        }
    }
    
    //                NSLog(@"heightForRowAtIndexPath_%d,%d:=%@",indexPath.row,n,_messageConent.text);
    if(n<55)
        n = 55;
    if (msg.isShowTime) {
        if(n<95)
            n = 95;
    }
    msg.chatMsgHeight = [NSString stringWithFormat:@"%f",n];
    if (!msg.isNotUpdateHeight) {
        [msg updateChatMsgHeight];
    }
    
    return n;
}

-(void)didTouch:(UIButton*)button{
    if ([self.msg.isReadDel boolValue] && [self.msg.fileName intValue] <= 0 && !self.msg.isMySend) {
        [self.msg sendAlreadyReadMsg];
        
        self.msg.fileName = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
        [self.msg updateFileName];
        
        self.timeIndexLabel.hidden = NO;
        _messageConent.text = self.msg.content;
//        NSString *messageR = [self.msg.content stringByReplacingOccurrencesOfString:@"\r" withString:@""];  //去掉回车键
//        NSString *messageN = [messageR stringByReplacingOccurrencesOfString:@"\n" withString:@""];  //去掉回车键
//        NSString *messageText = [messageN stringByReplacingOccurrencesOfString:@" " withString:@""];  //去掉空格
//        CGSize size = [messageText boundingRectWithSize:CGSizeMake(_messageConent.frame.size.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:SYSFONT(g_constant.chatFont)} context:nil].size;
//        NSInteger count = size.height / _messageConent.font.lineHeight;
//        self.msg.fileName = [NSString stringWithFormat:@"%ld", count * 10];
        self.isDidMsgCell = YES;
        self.msg.chatMsgHeight = [NSString stringWithFormat:@"0"];
        [self.msg updateChatMsgHeight];
        [g_notify postNotificationName:kCellMessageReadDelNotifaction object:[NSNumber numberWithInt:self.indexNum]];
//        self.readDelTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
        
    }
}

- (void)timerAction:(NSTimer *)timer {
   
    if (self.timerIndex <= 0) {
        [self.readDelTimer invalidate];
        self.readDelTimer = nil;
        self.msg.fileName = @"0";
        
        //阅后即焚通知
        [g_notify postNotificationName:kCellReadDelNotification object:self.msg];
        [self deleteMsg:self.msg];
        return;
    }
    self.timeIndexLabel.text = [NSString stringWithFormat:@"%ld",-- self.timerIndex];
//    self.msg.fileName = self.timeIndexLabel.text;
//    [self.msg updateFileName];
    
}


- (void)deleteMsg:(JXMessageObject *)msg{
    
    if ([self.msg.isReadDel boolValue]) {
        
        if ([self.msg.fileName intValue] > 0) {
            return;
        }
        
        //渐变隐藏
        [UIView animateWithDuration:2.f animations:^{
            self.bubbleBg.alpha = 0;
            self.timeIndexLabel.alpha = 0;
            self.readImage.alpha = 0;
            self.burnImage.alpha = 0;
        } completion:^(BOOL finished) {
            //动画结束后删除UI
            [self.delegate performSelectorOnMainThread:self.readDele withObject:msg waitUntilDone:NO];
            self.bubbleBg.alpha = 1;
            self.timeIndexLabel.alpha = 1;
            self.readImage.alpha = 1;
            self.burnImage.alpha = 1;
        }];
    }
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
