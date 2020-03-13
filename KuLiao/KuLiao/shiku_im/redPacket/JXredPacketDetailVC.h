//
//  JXredPacketDetailVC.h
//  shiku_im
//
//  Created by Apple on 16/8/30.
//  Copyright © 2016年 Reese. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JXPacketObject.h"
#import "JXGetPacketList.h"
@interface JXredPacketDetailVC : JXTableViewController

@property (nonatomic,strong) NSString * redPacketId;//红包id
@property (nonatomic,strong) NSDictionary * dataDict;//数据源
@property (nonatomic,strong) NSArray * OpenMember;//打开红包的人的列表
@property (nonatomic,strong) JXPacketObject * packetObj;//红包对象
@property (nonatomic, assign) BOOL isGroup;  // YES 群聊  NO 单聊



/**
 头部视图
 **/
@property (strong, nonatomic) UIImageView * headImgV;
@property (strong, nonatomic) UIView *contentView;


/**
 头像
 */
@property (strong, nonatomic) UIImageView *headerImageView;

/**
 总金额
 */
@property (strong, nonatomic) UILabel *totalMoneyLabel;

/**
 来自
 */
@property (strong, nonatomic) UILabel *fromUserLabel;

/**
 红包标题
 */
@property (strong, nonatomic) UILabel *greetLabel;

/**
 领取个数
 */
@property (strong, nonatomic) IBOutlet UILabel *showNumLabel;

/**
 红包过时
 */
@property (strong, nonatomic) UILabel * returnMoneyLabel;


@end
