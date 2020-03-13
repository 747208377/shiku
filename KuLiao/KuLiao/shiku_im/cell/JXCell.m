//
//  JXCell.m
//
//  Created by flyeagleTang on 14-4-3.
//  Copyright (c) 2014年 Reese. All rights reserved.
//

#import "JXCell.h"
#import "JXLabel.h"
#import "JXImageView.h"
#import "AppDelegate.h"


@implementation JXCell
@synthesize title,bottomTitle,headImage,bage,userId;
@synthesize index,delegate,didTouch,lbTitle,lbBottomTitle,lbSubTitle;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){

        self.selectionStyle  = UITableViewCellSelectionStyleBlue;
        //内容
        UIFont* f0 = [UIFont systemFontOfSize:14];
        //名称
        UIFont * f1 = [UIFont systemFontOfSize:16];
        //时间
        UIFont* timeFont = [UIFont systemFontOfSize:13];
        
        int n = 64;
        UIView* v = [[UIView alloc]initWithFrame:CGRectMake(0,0, JX_SCREEN_WIDTH, n)];
        v.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        self.selectedBackgroundView = v;

        self.lineView = [[UIView alloc]initWithFrame:CGRectMake(SEPSRATOR_WIDTH,n-0.5,JX_SCREEN_WIDTH,0.5)];
        self.lineView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        [self.contentView addSubview:self.lineView];
        
        _delBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 22, 20, 20)];
        [_delBtn setBackgroundImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
        [_delBtn addTarget:self action:@selector(delBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        _delBtn.hidden = YES;
        [self.contentView addSubview:_delBtn];
        
        
        _headImageView = [[JXImageView alloc]init];
        _headImageView.userInteractionEnabled = NO;
        _headImageView.tag = index;
        _headImageView.delegate = self;
        _headImageView.didTouch = @selector(headImageDidTouch);
        _headImageView.frame = CGRectMake(14,5,52,52);
        _headImageView.layer.cornerRadius = 25;
        _headImageView.layer.masksToBounds = YES;
//        _headImageView.layer.borderWidth = 0.5;
        _headImageView.layer.borderColor = [UIColor darkGrayColor].CGColor;
        [self.contentView addSubview:self.headImageView];
        
        [g_notify addObserver:self selector:@selector(headImageNotification:) name:kGroupHeadImageModifyNotifaction object:nil];

//        if(headImage){
//            if([headImage rangeOfString:@"http://"].location == NSNotFound)
//                self.headImageView.image = [UIImage imageNamed:headImage];
//            else
//                [g_server getImage:headImage imageView:self.headImageView];
//        }
//        [g_server getHeadImageSmall:userId userName:self.title imageView:self.headImageView];
        
        //昵称Label
        JXLabel* lb;
        lb = [[JXLabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_headImageView.frame)+14, 10, JX_SCREEN_WIDTH - 115 -CGRectGetMaxX(_headImageView.frame)-14, 14)];
        lb.textColor = HEXCOLOR(0x323232);
        lb.userInteractionEnabled = NO;
        lb.backgroundColor = [UIColor clearColor];
        lb.font = f1;
        lb.tag = self.index;
//        lb.delegate = self.delegate;
//        lb.didTouch = self.didTouch;
        [self.contentView addSubview:lb];
//        [lb release];
        [lb setText:self.title];
        self.lbTitle = lb;
        
        _positionLabel = [UIFactory createLabelWith:CGRectMake(CGRectGetMaxX(self.lbTitle.frame)+2, CGRectGetMinY(self.lbTitle.frame), 20, 20) text:@"" font:g_factory.font11 textColor:[UIColor whiteColor] backgroundColor:nil];
        _positionLabel.layer.backgroundColor = [UIColor orangeColor].CGColor;
        _positionLabel.layer.cornerRadius = 5;
        _positionLabel.textAlignment = NSTextAlignmentCenter;
        _positionLabel.hidden = YES;
        [self.contentView addSubview:_positionLabel];
        if (self.positionTitle.length > 0){
            self.positionTitle = self.positionTitle;
        }
        
        //聊天消息Label
        lb = [[JXLabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_headImageView.frame)+14, CGRectGetMaxY(self.lbTitle.frame)+10, JX_SCREEN_WIDTH-86-50, 16)];
        lb.textColor = [UIColor lightGrayColor];
        lb.userInteractionEnabled = NO;
        lb.backgroundColor = [UIColor clearColor];
        lb.font = f0;
        [self.contentView addSubview:lb];
//        [lb release];
        [lb setText:self.subtitle];
        self.lbSubTitle = lb;
        
        //时间Label
        self.timeLabel = [[JXLabel alloc]initWithFrame:CGRectMake(JX_SCREEN_WIDTH - 120, 13, 115, 20)];
        self.timeLabel.textColor = [UIColor lightGrayColor];
        self.timeLabel.userInteractionEnabled = NO;
        self.timeLabel.backgroundColor = [UIColor clearColor];
        self.timeLabel.textAlignment = NSTextAlignmentRight;
        self.timeLabel.font = timeFont;
        [self.contentView addSubview:self.timeLabel];
//        [self.timeLabel release];
        [self.timeLabel setText:self.bottomTitle];
        self.lbBottomTitle = self.timeLabel;
        
        //快捷回复
        self.replayView = [[JXImageView alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH-25-20, 64-25-20-6, 45, 45)];
        self.replayView.hidden = YES;
        self.replayView.didTouch = @selector(didQuickReply);
        self.replayView.delegate = self;
        [self.contentView addSubview:self.replayView];
        _replayImgV = [[UIImageView alloc] initWithFrame:CGRectMake(45-25, 45-25, 15, 15)];
        _replayImgV.image = [UIImage imageNamed:@"msg_replay_icon"];
        [self.replayView addSubview:_replayImgV];
        
        //免打扰图标
        self.notPushImageView = [[JXImageView alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH-25-15-10, 64-25-6, 15, 15)];
        self.notPushImageView.image = [UIImage imageNamed:@"msg_not_push"];
        self.notPushImageView.hidden = YES;
        [self.contentView addSubview:self.notPushImageView];

        _bageNumber  = [[JXBadgeView alloc] initWithFrame:CGRectMake(45-27, 45-25, 20, 20)];
        _bageNumber.delegate = delegate;
        _bageNumber.didDragout = self.didDragout;
        _bageNumber.userInteractionEnabled = YES;
        _bageNumber.lb.font = SYSFONT(12);
        [self.replayView addSubview:_bageNumber];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didQuickReply)];
        [_bageNumber addGestureRecognizer:tap];

//        [bageNumber release];
        self.bage = bage;
        
//        [self saveBadge:bage withTitle:self.title];
    }
    return self;
}

- (void)delBtnAction:(UIButton *)btn {
    if (self.delegate && [self.delegate respondsToSelector:self.didDelMsg]) {
        [self.delegate performSelectorOnMainThread:self.didDelMsg withObject:self waitUntilDone:YES];
    }
}

-(void)dealloc{
//    NSLog(@"JXCell.dealloc");
//    [self.bageDict removeAllObjects];
//    self.bageDict = nil;
    
    [g_notify removeObserver:self name:kGroupHeadImageModifyNotifaction object:nil];
    self.title = nil;
    self.subtitle = nil;
    self.bottomTitle = nil;
    self.headImage = nil;
    self.bage = nil;
    self.userId = nil;
    
    self.lbSubTitle = nil;
    self.lbTitle = nil;
    self.lbBottomTitle = nil;
//    self.bageDict = nil;
//    [_headImageView release];
//    [super dealloc];
}


- (void)setIsNotPush:(BOOL)isNotPush {
    _isNotPush = isNotPush;
    self.notPushImageView.hidden = !isNotPush;
}

- (void)setIsMsgVCCome:(BOOL)isMsgVCCome { // 只有JXMsgViewController显示回复按钮
    _isMsgVCCome = isMsgVCCome;
    self.replayView.hidden = !isMsgVCCome;
    // 这里获取需要userid   一定要在cell赋值userid 之后再调用
    //
    _replayImgV.alpha = 1-([self.userId intValue] == [SHIKU_TRANSFER intValue]);
    
}


- (void)didQuickReply {
    if ([self.userId intValue] == [SHIKU_TRANSFER intValue]) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:self.didReplay]) {
        [self.delegate performSelectorOnMainThread:self.didReplay withObject:self waitUntilDone:YES];
    }
}

//将所有Cell的badge存到沙盒里
//- (void)saveBadge:(NSString*)badg withTitle:(NSString*)titl{
//
//    if (bage == nil || titl == nil) {
//        return;
//    }
//    NSArray * path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//    NSString * cacherDir = [[path objectAtIndex:0] stringByAppendingPathComponent:@"cellBage.txt"];
//    
//    NSData * data = [[NSData alloc]initWithContentsOfFile:cacherDir];
//    
//    NSKeyedUnarchiver * unarchiver = [[NSKeyedUnarchiver alloc]initForReadingWithData:data];
//    
//    self.bageDict = [unarchiver decodeObjectForKey:@"dict"];
//    
//    if (self.bageDict == nil) {
//        self.bageDict = [[NSMutableDictionary alloc]init];
//    }
//    
//    [self.bageDict setObject:badg forKey:titl];
//    
//    NSMutableData * muData = [[NSMutableData alloc]init];
//    
//    NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:muData];
//    
//    [archiver encodeObject:self.bageDict forKey:@"dict"];
//    
//    [archiver finishEncoding];
//
//    [muData writeToFile:cacherDir atomically:YES];
//}

//- (void)awakeFromNib
//{
//    // Initialization code
//}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)headImageDidTouch{
    if (self.delegate && [self.delegate respondsToSelector:didTouch]) {
        [self.delegate performSelectorOnMainThread:didTouch withObject:self.dataObj waitUntilDone:YES];
    }
}
- (void)getHeadImage{
    if(headImage){
        if([headImage rangeOfString:@"http://"].location == NSNotFound)
            self.headImageView.image = [UIImage imageNamed:headImage];
        else
            [g_server getImage:headImage imageView:self.headImageView];
    }
    [g_server getHeadImageSmall:userId userName:self.title imageView:self.headImageView];
}

-(void)setBage:(NSString *)s{
//    bageNumber.hidden = [s intValue]<=0;
    _replayImgV.hidden = [s intValue] > 0;
    _bageNumber.badgeString = s;
    if ([s intValue] >= 10 && [s intValue] <= 99) {
        _bageNumber.lb.font = SYSFONT(12);
    }else if ([s intValue] > 0 && [s intValue] < 10) {
        _bageNumber.lb.font = SYSFONT(13);
    }else if([s intValue] > 99){
        _bageNumber.lb.font = SYSFONT(9);
    }
    bage = s;
}

-(void)setForTimeLabel:(NSString *)s{
    self.bottomTitle = s;
//    self.bottomTitle = [s retain];
    self.timeLabel.text = s;
}

-(void)setTitle:(NSString *)s{
//    title = [s retain];
    title = s;
    self.lbTitle.text = s;
}
-(void)setPositionTitle:(NSString *)positionTitle{
    _positionTitle = positionTitle;
    if (positionTitle.length > 0) {
        _positionLabel.text = positionTitle;
        _positionLabel.hidden = NO;
        CGSize positionSize =[positionTitle sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:11]}];
        if (positionSize.width >150)
            positionSize.width = 150;
        CGSize titleSize = [self.lbTitle.text sizeWithAttributes:@{NSFontAttributeName: self.lbTitle.font}];
        _positionLabel.frame = CGRectMake(self.lbTitle.frame.origin.x + titleSize.width + 2, CGRectGetMinY(self.lbTitle.frame) + 5, positionSize.width+4, positionSize.height);
        _positionLabel.center = CGPointMake(_positionLabel.center.x, 54 / 2);
    }
}

- (void)setSuLabel:(NSString *)s{
//    subtitle = [s retain];
    _subtitle = s;
    self.lbSubTitle.attributedText = [self setContentLabelStr:s];
}
-(void)setSubtitle:(NSString *)subtitle{
    _subtitle = subtitle;
    self.lbSubTitle.attributedText = [self setContentLabelStr:subtitle];
}
- (void)getMessageRange:(NSString*)message :(NSMutableArray*)array {
    
    NSRange range=[message rangeOfString: @"["];
    
    NSRange range1=[message rangeOfString: @"]"];
    
    
    // 动画过滤
    if ([message isEqualToString:[NSString stringWithFormat:@"[%@]",Localized(@"emojiVC_Emoji")]]) {
        [array addObject:message];
        return;
    }
    
    
    //判断当前字符串是否还有表情的标志。
    
    if (range.length>0 && range1.length>0 && range1.location > range.location) {
        
        if (range.location > 0) {
            
            [array addObject:[message substringToIndex:range.location]];
            
            [array addObject:[message substringWithRange:NSMakeRange(range.location, range1.location+1-range.location)]];
            
            NSString *str=[message substringFromIndex:range1.location+1];
            
            [self getMessageRange:str :array];
            
        }else {
            
            NSString *nextstr=[message substringWithRange:NSMakeRange(range.location, range1.location+1-range.location)];
            
            //排除文字是“”的
            
            if (![nextstr isEqualToString:@""]) {
                
                [array addObject:nextstr];
                
                NSString *str=[message substringFromIndex:range1.location+1];
                
                [self getMessageRange:str :array];
                
            }else {
                
                return;
                
            }
            
        }
        
    } else if (message != nil) {
        
        [array addObject:message];
        
    }
    
}
- (NSAttributedString *) setContentLabelStr:(NSString *) str {
    NSMutableArray *contentArray = [NSMutableArray array];
    
    [self getMessageRange:str :contentArray];
    
    NSMutableAttributedString *strM = [[NSMutableAttributedString alloc] init];
    
    NSInteger count = contentArray.count;
    if (contentArray.count > 15) {
        count = 15;
    }
    
    for (NSInteger i = 0; i < count; i ++) {
        
        NSString *object = contentArray[i];
        
//        NSLog(@"%@",object);
        BOOL flag = NO;
        if ([object hasSuffix:@"]"]&&[object hasPrefix:@"["]) {
            
            //如果是表情用iOS中附件代替string在label上显示
            
            NSTextAttachment *imageStr = [[NSTextAttachment alloc]init];
            NSString *imageShortName = [object substringWithRange:NSMakeRange(1, object.length - 2)];
            for (NSInteger i = 0; i < g_constant.emojiArray.count; i ++) {
                NSDictionary *dict = g_constant.emojiArray[i];
                NSString *imageName = dict[@"english"];
                if ([imageName isEqualToString:imageShortName]) {
                    imageStr.image = [UIImage imageNamed:dict[@"filename"]];
                    flag = YES;
                    break;
                }
            }
            if (!flag) {
                [strM appendAttributedString:[[NSAttributedString alloc] initWithString:object]];
                
                NSRange range = [object rangeOfString:Localized(@"JX_Draft")];
                [strM addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
                
                range = [object rangeOfString:Localized(@"JX_Someone@Me")];
                [strM addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
                continue;
            }
            //            imageStr.image = [UIImage imageNamed:[object substringWithRange:NSMakeRange(1, object.length - 2)]];
            
            //这里对图片的大小进行设置一般来说等于文字的高度
            
            CGFloat height = self.lbSubTitle.font.lineHeight + 1;
            
            imageStr.bounds = CGRectMake(0, -4, height, height);
            
            NSAttributedString *attrString = [NSAttributedString attributedStringWithAttachment:imageStr];
            
            [strM appendAttributedString:attrString];
            
        }else{
            
            //如果不是表情直接进行拼接

            [strM appendAttributedString:[[NSAttributedString alloc] initWithString:object]];
            
            NSRange range = [object rangeOfString:Localized(@"JX_Draft")];
            [strM addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
            
            range = [object rangeOfString:Localized(@"JX_Someone@Me")];
            [strM addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
        }
        
    }
    
    return strM;
}


-(void)headImageNotification:(NSNotification *)notification{
    NSDictionary * groupDict = notification.object;

    NSString * roomJid = groupDict[@"roomJid"];
    if ([roomJid isEqualToString:self.userId]) {
        UIImage * hImage = groupDict[@"groupHeadImage"];
        self.headImageView.image = hImage;
    }
}

-(void)headImageViewImageWithUserId:(NSString *)userId roomId:(NSString *)roomIdStr {

    if (roomIdStr != nil) {
//        if (![g_server getRoomHeadImageSmall:self.userId imageView:self.headImageView]) {
//            NSString *groupImagePath = [NSString stringWithFormat:@"%@%@/%@.%@",NSTemporaryDirectory(),g_myself.userId,roomIdStr,@"jpg"];
//            if (groupImagePath && [[NSFileManager defaultManager] fileExistsAtPath:groupImagePath]) {
//                self.headImageView.image = [UIImage imageWithContentsOfFile:groupImagePath];
//            }else{
//                [roomData roomHeadImageRoomId:roomIdStr toView:self.headImageView];
//            }
        [g_server getRoomHeadImageSmall:userId roomId:roomIdStr imageView:self.headImageView];
//        }
    }else{
        if(headImage){
            if([headImage rangeOfString:@"http://"].location == NSNotFound)
                self.headImageView.image = [UIImage imageNamed:headImage];
            else
                [g_server getImage:headImage imageView:self.headImageView];
        }
        [g_server getHeadImageSmall:self.userId userName:self.title imageView:self.headImageView];
    }
}

- (void)setIsSmall:(BOOL)isSmall {
    _isSmall = isSmall;
    
    CGFloat headX = 14;
    self.delBtn.hidden = YES;
    if (self.isEdit) {
        self.delBtn.hidden = NO;
        headX = CGRectGetMaxX(_delBtn.frame) + 10;
    }
    
    if (!isSmall) {
        
        _headImageView.frame = CGRectMake(headX,5,52,52);
        self.lbTitle.frame = CGRectMake(CGRectGetMaxX(_headImageView.frame)+14, 13, JX_SCREEN_WIDTH - 100 -CGRectGetMaxX(_headImageView.frame)-14, 18);
        self.lbSubTitle.frame = CGRectMake(CGRectGetMaxX(_headImageView.frame)+14, self.lbSubTitle.frame.origin.y, JX_SCREEN_WIDTH - 55 -CGRectGetMaxX(_headImageView.frame)-14, self.lbSubTitle.frame.size.height);
        self.lineView.frame = CGRectMake(CGRectGetMaxX(_headImageView.frame)+14,64-0.5,JX_SCREEN_WIDTH,0.5);
    }else {
        
        _headImageView.frame = CGRectMake(headX,5,42,42);
        _headImageView.layer.cornerRadius = _headImageView.frame.size.width / 2;
        self.lbTitle.frame = CGRectMake(CGRectGetMaxX(_headImageView.frame)+14, 10, JX_SCREEN_WIDTH - 100 -CGRectGetMaxX(_headImageView.frame)-14, 54 - 20);
        self.lbSubTitle.frame = CGRectMake(CGRectGetMaxX(_headImageView.frame)+14, self.lbSubTitle.frame.origin.y, JX_SCREEN_WIDTH - 55 -CGRectGetMaxX(_headImageView.frame)-14, self.lbSubTitle.frame.size.height);
        self.lineView.frame = CGRectMake(CGRectGetMaxX(_headImageView.frame)+14,54-0.5,JX_SCREEN_WIDTH,0.5);
    }
}

@end
