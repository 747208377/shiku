//
//  JXTransferRecordTableVC.m
//  shiku_im
//
//  Created by 1 on 2019/4/20.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXTransferRecordTableVC.h"
#import "JXRecordModel.h"
#import "JXRecordCell.h"

@interface JXTransferRecordTableVC ()
//@property (nonatomic, strong) JXRecordModel *model;
@property (nonatomic, strong) NSMutableArray *array;

@end

@implementation JXTransferRecordTableVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.heightHeader = JX_SCREEN_TOP;
    self.heightFooter = 0;
    self.isGotoBack = YES;
    [self createHeadAndFoot];
    _array = [[NSMutableArray alloc] init];

    self.title = Localized(@"JX_TransferTheDetail");
    
    [self getServerData];
}


- (void)getServerData {
    [g_server getConsumeRecordList:self.userId pageIndex:_page pageSize:20 toView:self];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 58;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"JXRecordCell";
    JXRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[JXRecordCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    JXRecordModel *model = _array[indexPath.row];
    
    [cell setData:model];
    
    return cell;
}



-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait stop];
    if( [aDownload.action isEqualToString:act_getConsumeRecordList]){
        NSArray *arr = [dict objectForKey:@"pageData"];
        if (arr.count <= 0) {
        }
        NSMutableArray *mutArr = [[NSMutableArray alloc] init];
        if(_page == 0){
            [_array removeAllObjects];
            for (int i = 0; i < arr.count; i++) {
                JXRecordModel *model = [[JXRecordModel alloc] init];
                [model getDataWithDict:arr[i]];
                [mutArr addObject:model];
            }
            [_array addObjectsFromArray:mutArr];
        }else{
            if([arr count]>0){
                for (int i = 0; i < arr.count; i++) {
                    JXRecordModel *model = [[JXRecordModel alloc] init];
                    [model getDataWithDict:arr[i]];
                    [mutArr addObject:model];
                }
                [_array addObjectsFromArray:mutArr];
            }
        }
        _page ++;
        if (_array.count > 0) {
            [_table hideEmptyImage];
        }else {
            [_table showEmptyImage:EmptyTypeNoData];
        }
        
        [_table reloadData];

    }
    
}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    [_wait stop];
    
    return show_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    [_wait stop];
    
    return show_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
    [_wait start];
}



@end
