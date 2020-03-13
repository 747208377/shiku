//
//  JXMergeRelayCell.m
//  shiku_im
//
//  Created by p on 2018/7/5.
//  Copyright © 2018年 Reese. All rights reserved.
//

#import "JXMergeRelayCell.h"

@implementation JXMergeRelayCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

-(void)creatUI{
    _imageBackground =[[UIImageView alloc]initWithFrame:CGRectZero];
    [_imageBackground setBackgroundColor:[UIColor whiteColor]];
    _imageBackground.layer.cornerRadius = 6;
    _imageBackground.image = [UIImage imageNamed:@"white"];
    _imageBackground.layer.masksToBounds = YES;
    _imageBackground.clipsToBounds = YES;
    [self.bubbleBg addSubview:_imageBackground];
    
}

-(void)setCellData{
    [super setCellData];
    
    [_imageBackground.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, kChatCellMaxWidth, 20)];
    _titleLabel.font = g_factory.font15;
    _titleLabel.numberOfLines = 1;
    _titleLabel.text = self.msg.objectId;
    [_imageBackground addSubview:_titleLabel];
    
    SBJsonParser * parser = [[SBJsonParser alloc] init] ;
    NSArray *content = [parser objectWithString:self.msg.content];
    CGFloat y = CGRectGetMaxY(_titleLabel.frame) + 5;
    for (NSInteger i = 0; i < (content.count <= 3 ? content.count : 3); i ++) {
        NSString *str = content[i];
        SBJsonParser * parser = [[SBJsonParser alloc] init] ;
        NSDictionary *dict = [parser objectWithString:str];
        JXMessageObject *msg = [[JXMessageObject alloc] init];
        [msg fromDictionary:dict];
        JXEmoji *label = [[JXEmoji alloc] initWithFrame:CGRectMake(10, y, kChatCellMaxWidth, 15)];
        label.font = [UIFont systemFontOfSize:10.0];
        label.faceWidth = 14;
        label.faceHeight = 14;
        label.textColor = [UIColor lightGrayColor];
        label.text = [NSString stringWithFormat:@"%@: %@", msg.fromUserName, [msg getLastContent]];
        [_imageBackground addSubview:label];
        y = CGRectGetMaxY(label.frame) + 5;
    }
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, y, kChatCellMaxWidth + INSETS * 2, .5)];
    lineView.backgroundColor = [UIColor lightGrayColor];
    [_imageBackground addSubview:lineView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, y + 5, kChatCellMaxWidth, 15)];
    label.textColor = [UIColor lightGrayColor];
    label.font = [UIFont systemFontOfSize:11.0];
    label.text = Localized(@"JX_ChatRecord");
    [_imageBackground addSubview:label];
    
    int n = CGRectGetMaxY(label.frame);
    if(self.msg.isMySend)
    {
        self.bubbleBg.frame=CGRectMake(JX_SCREEN_WIDTH-HEAD_SIZE- kChatCellMaxWidth - INSETS*4+CHAT_WIDTH_ICON, INSETS, kChatCellMaxWidth + INSETS * 2, n+INSETS -4);
        _imageBackground.frame = self.bubbleBg.bounds;
        
    }
    else
    {
        self.bubbleBg.frame=CGRectMake(CGRectGetMaxX(self.headImage.frame) + INSETS-CHAT_WIDTH_ICON, INSETS2(self.msg.isGroup), kChatCellMaxWidth + INSETS * 2, n+INSETS -4);
        _imageBackground.frame = self.bubbleBg.bounds;
    }
    
    if (self.msg.isShowTime) {
        CGRect frame = self.bubbleBg.frame;
        frame.origin.y = self.bubbleBg.frame.origin.y + 40;
        self.bubbleBg.frame = frame;
    }
    
    [self setMaskLayer:_imageBackground];

    if(!self.msg.isMySend)
        [self drawIsRead];
}

//未读红点
-(void)drawIsRead{
    if (self.msg.isMySend) {
        return;
    }
    if([self.msg.isRead boolValue]){
        self.readImage.hidden = YES;
    }
    else{
        if(self.readImage==nil){
            self.readImage=[[JXImageView alloc]init];
            [self.contentView addSubview:self.readImage];
            //            [self.readImage release];
        }
        self.readImage.image = [UIImage imageNamed:@"new_tips"];
        self.readImage.hidden = NO;
        self.readImage.frame = CGRectMake(self.bubbleBg.frame.origin.x+self.bubbleBg.frame.size.width+2, self.bubbleBg.frame.origin.y+13, 8, 8);
        self.readImage.center = CGPointMake(self.readImage.center.x, self.bubbleBg.center.y);
        
    }
}

-(void)didTouch:(UIButton*)button{
    
    [self.msg sendAlreadyReadMsg];
    if (self.msg.isGroup) {
        self.msg.isRead = [NSNumber numberWithInt:1];
        [self.msg updateIsRead:nil msgId:self.msg.messageId];
    }
    if(!self.msg.isMySend){
        [self drawIsRead];
    }
    
    [g_notify postNotificationName:kCellSystemMergeRelayNotifaction object:self.msg];
}

+ (float)getChatCellHeight:(JXMessageObject *)msg {
    
    if ([msg.chatMsgHeight floatValue] > 1) {
        return [msg.chatMsgHeight floatValue];
    }
    
    float n = 0;
    SBJsonParser * parser = [[SBJsonParser alloc] init] ;
    NSArray *content = [parser objectWithString:msg.content];
    if (msg.isGroup && !msg.isMySend) {
        if (msg.isShowTime) {
            n = 55 + 20 * (content.count <= 3 ? content.count : 3) + 20*2 + 40;
        }else {
            n = 55 + 20 * (content.count <= 3 ? content.count : 3) +20*2;
        }
    }else {
        if (msg.isShowTime) {
            n = 55 + 20 * (content.count <= 3 ? content.count : 3) +10*2 + 40;
        }else {
            n = 55 + 20 * (content.count <= 3 ? content.count : 3) +10*2;
        }
    }
    
    msg.chatMsgHeight = [NSString stringWithFormat:@"%f",n];
    if (!msg.isNotUpdateHeight) {
        [msg updateChatMsgHeight];
    }
    return n;
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
