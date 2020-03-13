//
//  JXRechargeViewController.h
//  shiku_im
//
//  Created by 1 on 17/10/30.
//  Copyright © 2017年 Reese. All rights reserved.
//

#import "JXTableViewController.h"

@protocol RechargeDelegate <NSObject>

-(void)rechargeSuccessed;

@end

@interface JXRechargeViewController : JXTableViewController

@property (nonatomic, weak) id<RechargeDelegate> rechargeDelegate;

@property (nonatomic,assign) BOOL isQuitAfterSuccess;

@end
