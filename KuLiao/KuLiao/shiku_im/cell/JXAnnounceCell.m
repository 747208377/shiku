//
//  JXAnnounceCell.m
//  shiku_im
//
//  Created by 1 on 2018/8/17.
//  Copyright © 2018年 Reese. All rights reserved.
//

#import "JXAnnounceCell.h"

#define HEIGHT 40

@interface JXAnnounceCell ()
@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) UIView *line;

@end

@implementation JXAnnounceCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        self.baseView = [[UIView alloc] initWithFrame:CGRectMake(INSETS, INSETS, JX_SCREEN_WIDTH-INSETS*2, MAXFLOAT)];
        self.baseView.backgroundColor = [UIColor whiteColor];
        self.baseView.layer.masksToBounds = YES;
        self.baseView.layer.cornerRadius = 4.0f;
        [self.contentView addSubview:self.baseView];
        
        self.icon = [[UIImageView alloc] initWithFrame:CGRectMake(INSETS, INSETS, HEIGHT, HEIGHT)];
        [self.baseView addSubview:self.icon];
        
        self.name = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.icon.frame)+6, 15, 200, 20)];
        [self.baseView addSubview:self.name];
        
        self.time = [[UILabel alloc] initWithFrame:CGRectMake(self.baseView.frame.size.width-INSETS-100, 15, 100, 20)];
        self.time.textAlignment = NSTextAlignmentRight;
        self.time.font = [UIFont systemFontOfSize:14];
        [self.baseView addSubview:self.time];
        
        self.line = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.icon.frame)+INSETS, self.baseView.frame.size.width, 0.5)];
        self.line.backgroundColor = HEXCOLOR(0xD6D6D6);
        [self.baseView addSubview:self.line];
        
        self.content = [[UILabel alloc] initWithFrame:CGRectMake(INSETS, CGRectGetMaxY(self.line.frame)+INSETS, self.baseView.frame.size.width-INSETS*2, MAXFLOAT)];
        self.content.font = [UIFont systemFontOfSize:14];
        self.content.numberOfLines = 0;
        [self.content sizeToFit];
        [self.baseView addSubview:self.content];
    }
    return self;
}

- (void)setCellHeightWithText:(NSString *)text {
    CGSize size = [text boundingRectWithSize:CGSizeMake(JX_SCREEN_WIDTH-INSETS*4, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:g_factory.font14} context:nil].size;
    self.content.frame = CGRectMake(INSETS, CGRectGetMaxY(self.line.frame)+INSETS,size.width, size.height);
    self.baseView.frame = CGRectMake(INSETS, INSETS, JX_SCREEN_WIDTH-INSETS*2, 80+size.height);
}

@end
