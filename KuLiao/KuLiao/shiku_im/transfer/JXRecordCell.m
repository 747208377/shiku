//
//  JXRecordCell.m
//  shiku_im
//
//  Created by 1 on 2019/4/20.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXRecordCell.h"
#import "JXRecordModel.h"

@interface JXRecordCell ()
@property (nonatomic, strong) UILabel *desc;
@property (nonatomic, strong) UILabel *time;
@property (nonatomic, strong) UILabel *money;
@property (nonatomic, strong) UILabel *status;

@end

@implementation JXRecordCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.desc = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 200, 18)];
        self.desc.font = SYSFONT(15);
        [self.contentView addSubview:self.desc];
        
        self.time = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.desc.frame)+5, 100, 15)];
        self.time.font = SYSFONT(14);
        self.time.textColor = [UIColor grayColor];
        [self.contentView addSubview:self.time];

        self.money = [[UILabel alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH-110, 10, 100, 18)];
        self.money.font = SYSFONT(15);
        self.money.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.money];

        self.status = [[UILabel alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH-110, CGRectGetMaxY(self.money.frame)+5, 100, 15)];
        self.status.font = SYSFONT(14);
        self.status.textColor = [UIColor grayColor];
        self.status.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.status];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 57.5, JX_SCREEN_WIDTH, .5)];
        line.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
        [self.contentView addSubview:line];
    }
    return self;
}


- (void)setData:(JXRecordModel *)model {
    self.desc.text = model.desc;
    self.money.text = [NSString stringWithFormat:@"%.2f",model.money];
    self.time.text = [self stringToDate:model.time withDateFormat:@"yyyy-MM-dd"];
    self.status.text = [self getPayType:model.status];
}

- (NSString *)getPayType:(int)status {
    NSString *str = [NSString string];
    if (status == 0) {
        str= Localized(@"JX_Create");
    }
    else if (status == 1) {
        str= Localized(@"JX_PayToComplete");
    }
    else if (status == 2) {
        str= Localized(@"JX_CompleteTheTransaction");
    }
    else if (status == -1) {
        str= Localized(@"JX_TradingClosed");
    }

    return str;
}

//字符串转日期格式
- (NSString *)stringToDate:(long)date withDateFormat:(NSString *)format {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];
    
    NSDate*timeDate = [[NSDate alloc] initWithTimeIntervalSince1970:date];
    return [dateFormatter stringFromDate:timeDate];
}


@end
