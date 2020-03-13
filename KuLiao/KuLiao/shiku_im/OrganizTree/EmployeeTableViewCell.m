//
//  EmployeeTableViewCell.m
//  shiku_im
//
//  Created by 1 on 17/5/18.
//  Copyright © 2017年 Reese. All rights reserved.
//

#import "EmployeeTableViewCell.h"

@implementation EmployeeTableViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectedBackgroundView = [UIView new];
        self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
        
        [self customUI];
    }
    return self;
}

-(void)customUI{

    self.backgroundColor = [UIColor whiteColor];
    
    _headImageView = [[UIImageView alloc]init];
    _headImageView.frame = CGRectMake(10,8,30,30);
    _headImageView.layer.cornerRadius = 15;
    _headImageView.layer.masksToBounds = YES;
    _headImageView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    [self.contentView addSubview:self.headImageView];

    _customTitleLabel = [UIFactory createLabelWith:CGRectMake(45, 10, 100, 21) text:@"" font:g_UIFactory.font15 textColor:[UIColor blackColor] backgroundColor:nil];
    _customTitleLabel.textAlignment = NSTextAlignmentLeft;
    _customTitleLabel.textColor = [UIColor blackColor];
    [self.contentView addSubview:_customTitleLabel];
    
    
    _positionLabel = [UIFactory createLabelWith:CGRectMake(CGRectGetMaxX(_customTitleLabel.frame)+2, CGRectGetMinY(_customTitleLabel.frame), 20, 20) text:@"" font:g_factory.font11 textColor:[UIColor whiteColor] backgroundColor:nil];
    _positionLabel.layer.backgroundColor = [UIColor orangeColor].CGColor;
    _positionLabel.layer.cornerRadius = 5;
    _positionLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_positionLabel];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    [self layoutIfNeeded];
    
}
- (void)prepareForReuse
{
    [super prepareForReuse];
}
//- (void)willTransitionToState:(UITableViewCellStateMask)state{
//    
//}

- (void)setupWithData:(EmployeObject *)dataObj level:(NSInteger)level
{
    self.customTitleLabel.text = dataObj.nickName;
    self.positionLabel.text = dataObj.position;
    [g_server getHeadImageSmall:dataObj.userId userName:dataObj.nickName imageView:_headImageView];
    self.employObject = dataObj;
    
   
    CGFloat left = 11 + 20 * level;
    
    CGRect titleFrame = self.customTitleLabel.frame;
    CGRect headFrame = self.headImageView.frame;
    headFrame.origin.x = left;
    self.headImageView.frame = headFrame;
    
    CGSize nameSize =[dataObj.nickName sizeWithAttributes:@{NSFontAttributeName:self.customTitleLabel.font}];
    titleFrame.origin.x = left + CGRectGetWidth(_headImageView.frame) + 4;
    titleFrame.size = nameSize;
    self.customTitleLabel.frame = titleFrame;
    self.customTitleLabel.center = CGPointMake(_customTitleLabel.center.x, self.headImageView.center.y);
    
    CGSize positionSize =[dataObj.position sizeWithAttributes:@{NSFontAttributeName:self.positionLabel.font}];
    if (positionSize.width >150)
        positionSize.width = 150;
    self.positionLabel.frame = CGRectMake(CGRectGetMaxX(self.customTitleLabel.frame)+2, CGRectGetMinY(self.customTitleLabel.frame), positionSize.width+4, positionSize.height);
    
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
