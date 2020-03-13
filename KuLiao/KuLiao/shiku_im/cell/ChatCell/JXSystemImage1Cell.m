//
//  JXSystemImage1Cell.m
//  shiku_im
//
//  Created by p on 2017/7/20.
//  Copyright © 2017年 Reese. All rights reserved.
//

#import "JXSystemImage1Cell.h"


@interface JXSystemImage1Cell ()
@property (nonatomic, strong) UIImageView *imageBackground;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UILabel *subtitle;
@property (nonatomic, strong) UIImageView *imageV;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UILabel *showAllLabel;
@property (nonatomic, strong) UIImageView *showAllImageView;

@end

@implementation JXSystemImage1Cell

-(void)creatUI{
    
    _imageBackground =[[UIImageView alloc]initWithFrame:CGRectZero];
    [_imageBackground setBackgroundColor:[UIColor clearColor]];
    _imageBackground.layer.cornerRadius = 6;
    _imageBackground.image = [UIImage imageNamed:@"white"];
    _imageBackground.layer.masksToBounds = YES;
    [self.bubbleBg addSubview:_imageBackground];
    
//    _view = [[UIView alloc] initWithFrame:CGRectMake(10, 5, JX_SCREEN_WIDTH - 20, 290.5)];
//    _view.backgroundColor = [UIColor whiteColor];
//    _view.layer.cornerRadius = 3.0;
//    _view.layer.masksToBounds = YES;
//    [self.contentView addSubview:_view];
    
    _title = [[UILabel alloc] initWithFrame:CGRectMake(18, 15, kSystemImageCellWidth - 30, 30)];
    _title.font = SYSFONT(15.0);
    _title.numberOfLines = 0;
    _title.text = Localized(@"JXSystemImage_single");
    [_imageBackground addSubview:_title];
    
    _imageV = [[UIImageView alloc] initWithFrame:CGRectMake(18, CGRectGetMaxY(_title.frame) + 15, kSystemImageCellWidth - 30, 150)];
    _imageV.image = [UIImage imageNamed:Localized(@"JX_SendThePosition")];
    [_imageBackground addSubview:_imageV];
    
    _subtitle = [[UILabel alloc] initWithFrame:CGRectMake(18, CGRectGetMaxY(_imageV.frame) + 15, kSystemImageCellWidth - 30, 30)];
    _subtitle.font = SYSFONT(14.0);
    _subtitle.textColor = [UIColor grayColor];
    _subtitle.numberOfLines = 0;
    _subtitle.text = Localized(@"JXSystemImage_single");
    [_imageBackground addSubview:_subtitle];
    
    _lineView = [[UIView alloc] initWithFrame:CGRectMake(18, CGRectGetMaxY(_subtitle.frame) + 15, kSystemImageCellWidth - 30, .5)];
    _lineView.backgroundColor = HEXCOLOR(0xf0f0f0);
    [_imageBackground addSubview:_lineView];
    
    _showAllLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, CGRectGetMaxY(_lineView.frame) + 15, 100, 20)];
    _showAllLabel.font = SYSFONT(14.0);
    _showAllLabel.text = Localized(@"JX_ReadPassage");
    [_imageBackground addSubview:_showAllLabel];
    
    _showAllImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kSystemImageCellWidth - 10 - 15, CGRectGetMaxY(_lineView.frame) + 13, 10, 15)];
    _showAllImageView.image = [UIImage imageNamed:@"more_flag"];
    [_imageBackground addSubview:_showAllImageView];
}

-(void)setCellData{
    
    [super setCellData];
    
    SBJsonParser * parser = [[SBJsonParser alloc] init] ;
    id content = [parser objectWithString:self.msg.content];
    
    [_imageV sd_setImageWithURL:[content objectForKey:@"img"] placeholderImage:[UIImage imageNamed:@"Default_Gray" ]];
    
    _title.text = [content objectForKey:@"title"];
    
    _subtitle.text = [content objectForKey:@"sub"];
    
    CGSize titleSize = [_title.text boundingRectWithSize:CGSizeMake(_title.frame.size.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_title.font} context:nil].size;
    CGRect titleFrame = _title.frame;
    titleFrame.size.height = titleSize.height;
    _title.frame = titleFrame;
    
    CGSize subtitleSize = [_subtitle.text boundingRectWithSize:CGSizeMake(_subtitle.frame.size.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_subtitle.font} context:nil].size;
    CGRect subtitleFrame = _subtitle.frame;
    subtitleFrame.size.height = subtitleSize.height;
    _subtitle.frame = subtitleFrame;
    
    [self setSubViewFrame];
    
//    CGRect frame = _view.frame;
//    frame.size.height = 230.5 + titleSize.height + subtitleSize.height;
//    _view.frame = frame;
    
    if(self.msg.isMySend)
    {
        self.bubbleBg.frame=CGRectMake(JX_SCREEN_WIDTH-HEAD_SIZE- kSystemImageCellWidth - INSETS*2+CHAT_WIDTH_ICON, INSETS, kSystemImageCellWidth, 260.5 + titleSize.height + subtitleSize.height);
        _imageBackground.frame = self.bubbleBg.bounds;
        
    }
    else
    {
        self.bubbleBg.frame=CGRectMake(CGRectGetMaxX(self.headImage.frame) + INSETS-CHAT_WIDTH_ICON, INSETS2(self.msg.isGroup), kSystemImageCellWidth, 260.5 + titleSize.height + subtitleSize.height);
        _imageBackground.frame = self.bubbleBg.bounds;
    }
    
    if (self.msg.isShowTime) {
        CGRect frame = self.bubbleBg.frame;
        frame.origin.y = self.bubbleBg.frame.origin.y + 40;
        self.bubbleBg.frame = frame;
    }
    
    [self setMaskLayer:_imageBackground];
}

- (void) setSubViewFrame {
    
    _imageV.frame = CGRectMake(_imageV.frame.origin.x, CGRectGetMaxY(_title.frame) + 15, _imageV.frame.size.width, _imageV.frame.size.height);
    _subtitle.frame = CGRectMake(_subtitle.frame.origin.x, CGRectGetMaxY(_imageV.frame) + 15, _subtitle.frame.size.width, _subtitle.frame.size.height);
    _lineView.frame = CGRectMake(_lineView.frame.origin.x, CGRectGetMaxY(_subtitle.frame) + 15, _lineView.frame.size.width, _lineView.frame.size.height);
    _showAllLabel.frame = CGRectMake(_showAllLabel.frame.origin.x, CGRectGetMaxY(_lineView.frame) + 15, _showAllLabel.frame.size.width, _showAllLabel.frame.size.height);
    _showAllImageView.frame = CGRectMake(_showAllImageView.frame.origin.x, CGRectGetMaxY(_lineView.frame) + 15, _showAllImageView.frame.size.width, _showAllImageView.frame.size.height);
}

-(void)didTouch:(UIButton*)button{
    
    [g_notify postNotificationName:kCellSystemImage1DidTouchNotifaction object:self.msg];
}

+ (float)getChatCellHeight:(JXMessageObject *)msg {
    
    if ([msg.chatMsgHeight floatValue] > 1) {
        return [msg.chatMsgHeight floatValue];
    }
    
    float n = 0;
    SBJsonParser * parser = [[SBJsonParser alloc] init] ;
    id content = [parser objectWithString:msg.content];
    
    CGSize titleSize = [[content objectForKey:@"title"] boundingRectWithSize:CGSizeMake(kSystemImageCellWidth - 20, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:SYSFONT(15)} context:nil].size;
    
    CGSize subtitleSize = [[content objectForKey:@"sub"] boundingRectWithSize:CGSizeMake(kSystemImageCellWidth - 20, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:SYSFONT(14)} context:nil].size;
    
    if (msg.isShowTime) {
        n = 270.5 + titleSize.height + subtitleSize.height + 40 + INSETS;
    }else {
        n = 270.5 + titleSize.height + subtitleSize.height + INSETS;
    }
    
    msg.chatMsgHeight = [NSString stringWithFormat:@"%f",n];
    if (!msg.isNotUpdateHeight) {
        [msg updateChatMsgHeight];
    }
    return n;
}

@end
