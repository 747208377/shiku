//
//  JXHelperModel.m
//  shiku_im
//
//  Created by 1 on 2019/5/28.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXHelperModel.h"

@implementation JXHelperModel

- (void)getDataWithDict:(NSDictionary *)dict {
    self.desc = [dict objectForKey:@"desc"];
    self.developer = [dict objectForKey:@"developer"];
    self.iconUrl = [dict objectForKey:@"iconUrl"];
    self.helperId = [dict objectForKey:@"id"];
    self.link = [dict objectForKey:@"link"];
    self.name = [dict objectForKey:@"name"];
    self.openAppId = [dict objectForKey:@"openAppId"];
    self.type = [[dict objectForKey:@"type"] intValue];
    self.urlScheme = [dict objectForKey:@"iosUrlScheme"];
    if ([dict objectForKey:@"other"]) {
        self.appName = [[dict objectForKey:@"other"] objectForKey:@"appName"];
        self.subTitle = [[dict objectForKey:@"other"] objectForKey:@"subTitle"];
        self.url = [[dict objectForKey:@"other"] objectForKey:@"url"];
    }
}


+ (instancetype)initWithDict:(NSDictionary *)dict {
    JXHelperModel *model = [[JXHelperModel alloc] init];
    model.desc = [dict objectForKey:@"desc"];
    model.developer = [dict objectForKey:@"developer"];
    model.iconUrl = [dict objectForKey:@"iconUrl"];
    model.helperId = [dict objectForKey:@"id"];
    model.link = [dict objectForKey:@"link"];
    model.name = [dict objectForKey:@"name"];
    model.openAppId = [dict objectForKey:@"openAppId"];
    model.type = [[dict objectForKey:@"type"] intValue];
    model.urlScheme = [dict objectForKey:@"iosUrlScheme"];
    if ([dict objectForKey:@"other"]) {
        model.appName = [[dict objectForKey:@"other"] objectForKey:@"appName"];
        model.subTitle = [[dict objectForKey:@"other"] objectForKey:@"subTitle"];
        model.url = [[dict objectForKey:@"other"] objectForKey:@"url"];
        model.imageUrl = [[dict objectForKey:@"other"] objectForKey:@"imageUrl"];
        model.appIcon = [[dict objectForKey:@"other"] objectForKey:@"appIcon"];
        model.downloadUrl = [[dict objectForKey:@"other"] objectForKey:@"downloadUrl"];
        model.title = [[dict objectForKey:@"other"] objectForKey:@"title"];

    }
    return model;
}

@end
