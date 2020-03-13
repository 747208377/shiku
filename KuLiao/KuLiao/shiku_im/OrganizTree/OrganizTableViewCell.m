//
//  OrganizTableViewCell.m
//  shiku_im
//
//  Created by 1 on 17/5/12.
//  Copyright © 2017年 Reese. All rights reserved.
//

#import "OrganizTableViewCell.h"

//#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation OrganizTableViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
//        self.selectedBackgroundView = [UIView new];
//        self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
        [self customUI];
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    [self layoutIfNeeded];
    
    _additionButton.frame = CGRectMake(self.frame.size.width -22-20, 0, 22, 22);
    _additionButton.center = CGPointMake(_additionButton.center.x, self.contentView.center.y);
    CGRect frame = _nameLabel.frame;
    frame.size.width = CGRectGetMinX(_additionButton.frame) -CGRectGetMinX(_nameLabel.frame) -5;
    _nameLabel.frame = frame;
    _nameLabel.center = CGPointMake(_nameLabel.center.x, self.contentView.center.y);
    
    _arrowView.center = CGPointMake(_arrowView.center.x, self.contentView.center.y);
    
}
-(void)customUI{
    
    _arrowView = [[UIImageView alloc] init];
    _arrowView.frame = CGRectMake(0, 0, 20, 20);
    _arrowView.image = [UIImage imageNamed:@"arrow_right"];
    [self.contentView addSubview:_arrowView];
    
    _nameLabel = [UIFactory createLabelWith:CGRectMake(22, 5, 200, 22) text:@"" font:g_UIFactory.font15 textColor:[UIColor blackColor] backgroundColor:nil];
    _nameLabel.textAlignment = NSTextAlignmentLeft;
    [self.contentView addSubview:_nameLabel];
    
    _additionButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    _additionButton.frame = CGRectMake(self.frame.size.width -22-20, 11, 22, 22);
    [self.contentView addSubview:_additionButton];
    
    [_additionButton addTarget:self action:@selector(additionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.arrowExpand = NO;
}

- (void)setupWithData:(DepartObject *)dataObj level:(NSInteger)level expand:(BOOL)expand
{
    _arrowView.transform = CGAffineTransformIdentity;
    if (expand == YES) {
        self.arrowExpand = expand;
    }
    self.nameLabel.text = dataObj.departName;
    self.organizObject = dataObj;
   
    if (level == 0) {
        self.backgroundColor = HEXCOLOR(0xe3e6e8);
        self.nameLabel.textColor = [UIColor blackColor];
    }else{
        self.backgroundColor = [UIColor whiteColor];
        self.nameLabel.textColor = [UIColor grayColor];
    }
    
    CGFloat left = 20 * level;
    
    CGRect arrowFrame = self.arrowView.frame;
    arrowFrame.origin.x = left;
    self.arrowView.frame = arrowFrame;
    
    CGRect titleFrame = self.nameLabel.frame;
    titleFrame.origin.x = left +22;
    self.nameLabel.frame = titleFrame;
}


#pragma mark - Properties

-(void)setArrowExpand:(BOOL)arrowExpand{
    [self setArrowExpand:arrowExpand animated:YES];
}

- (void)setArrowExpand:(BOOL)arrowExpand animated:(BOOL)animated{
    _arrowExpand = arrowExpand;
    [UIView animateWithDuration:animated ? 0.2 : 0 animations:^{
        if (arrowExpand) {
            _arrowView.transform = CGAffineTransformRotate(_arrowView.transform, M_PI_2);
        }else{
            _arrowView.transform = CGAffineTransformRotate(_arrowView.transform, -M_PI_2);
        }
//        _arrowView.hidden = arrowExpand;
    }];
}
//- (void)setAdditionButtonHidden:(BOOL)additionButtonHidden
//{
//    [self setAdditionButtonHidden:additionButtonHidden animated:NO];
//}

//- (void)setAdditionButtonHidden:(BOOL)additionButtonHidden animated:(BOOL)animated
//{
//    _additionButtonHidden = additionButtonHidden;
//    [UIView animateWithDuration:animated ? 0.2 : 0 animations:^{
//        self.additionButton.hidden = additionButtonHidden;
//    }];
//}


#pragma mark - Actions

- (void)additionButtonTapped:(id)sender
{
    if (self.additionButtonTapAction) {
        self.additionButtonTapAction(sender);
        
    }
}
@end
