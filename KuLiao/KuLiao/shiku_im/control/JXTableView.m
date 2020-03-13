#import "JXTableView.h"

@implementation JXTableView

@synthesize touchDelegate = _touchDelegate;

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style{
    self = [super initWithFrame:frame style:style];
    _pool = [[NSMutableArray alloc]init];
    return self;
}

-(void)dealloc{
    NSLog(@"JXTableView.dealloc");
    [self clearPool];
    _pool = nil;
//    [super dealloc];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    if ([_touchDelegate conformsToProtocol:@protocol(JXTableViewDelegate)] &&
        [_touchDelegate respondsToSelector:@selector(tableView:touchesBegan:withEvent:)])
    {
        [_touchDelegate tableView:self touchesBegan:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    if ([_touchDelegate conformsToProtocol:@protocol(JXTableViewDelegate)] &&
        [_touchDelegate respondsToSelector:@selector(tableView:touchesCancelled:withEvent:)])
    {
        [_touchDelegate tableView:self touchesCancelled:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    if ([_touchDelegate conformsToProtocol:@protocol(JXTableViewDelegate)] &&
        [_touchDelegate respondsToSelector:@selector(tableView:touchesEnded:withEvent:)] )
    {
        [_touchDelegate tableView:self touchesEnded:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    if ([_touchDelegate conformsToProtocol:@protocol(JXTableViewDelegate)] &&
        [_touchDelegate respondsToSelector:@selector(tableView:touchesMoved:withEvent:)])
    {
        [_touchDelegate tableView:self touchesMoved:touches withEvent:event];
    }
}

- (void) gotoLastRow:(BOOL)animated{
    NSInteger n = [self numberOfRowsInSection:0]-1;
    if(n>=1)
        [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:n inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

- (void) gotoFirstRow:(BOOL)animated{
    NSInteger n = [self numberOfRowsInSection:0]-1;
    if(n>=1)
        [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
}

-(void)gotoRow:(int)n{
    if(n<0)
        return;
    if([self numberOfRowsInSection:0] > n)
        [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:n inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void)showEmptyImage:(EmptyType)emptyType{
    if(!_empty){
        _empty = [[UIImageView alloc]initWithFrame:CGRectMake((JX_SCREEN_WIDTH-56)/2, self.frame.size.height/5, 56, 108)];
        _empty.image = [UIImage imageNamed:@"no_data_for_the_time_being"];
//        _empty.backgroundColor = [UIColor magentaColor];
        [self addSubview:_empty];
    }
    
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(_empty.frame.origin.x, _empty.frame.origin.y + _empty.frame.size.height + 10, JX_SCREEN_WIDTH, 30)];
        CGPoint centerPoint = CGPointMake(_empty.center.x, _empty.frame.origin.y + _empty.frame.size.height + 10);
        _tipLabel.center = centerPoint;
        _tipLabel.font = g_factory.font16;
        _tipLabel.textAlignment = NSTextAlignmentCenter;
//        _tipLabel.backgroundColor = [UIColor cyanColor];
        [self addSubview:_tipLabel];
    }
    switch (emptyType) {
        case EmptyTypeNoData:
            _tipLabel.text = Localized(@"JX_NoData");
            break;
        case EmptyTypeNetWorkError:
            _tipLabel.text = Localized(@"JX_NetWorkError");
        default:
            break;
    }
    
    if (!_tipBtn) {
        _tipBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, _tipLabel.frame.origin.y + _tipLabel.frame.size.height + 20, 120, 40)];
        [_tipBtn setTitle:Localized(@"JX_LoadAgain") forState:UIControlStateNormal];
        [_tipBtn setBackgroundColor:THEMECOLOR];
        _tipBtn.layer.masksToBounds = YES;
        _tipBtn.layer.cornerRadius = 5;
        _tipBtn.center = CGPointMake(JX_SCREEN_WIDTH/2, _tipBtn.center.y);
        [_tipBtn addTarget:self.delegate
                    action:@selector(getServerData) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_tipBtn];
    }
}

-(void)hideEmptyImage{
    if (_empty) {
        [_empty removeFromSuperview];
        _empty = nil;
    }
    if (_tipLabel) {
        [_tipLabel removeFromSuperview];
        _tipLabel = nil;
    }
    if (_tipBtn) {
        [_tipBtn removeFromSuperview];
        _tipBtn = nil;
    }
}

-(void)onAfterLoad{
//    if([self numberOfRowsInSection:0]<=0){
//        //[self showEmptyImage:nil];
//    }else{
//        [self hideEmptyImage];
//    }
}

-(void)reloadData{
    [self clearPool];
    [super reloadData];
    [self onAfterLoad];
}

-(void)addToPool:(id)p{
    if([_pool indexOfObject:p] == NSNotFound){
        [_pool addObject:p];
        p = nil;
    }
}

-(void)delFromPool:(id)p{
    [_pool removeObject:p];
}

-(void)clearPool{
    for (NSInteger i=[_pool count]-1; i>0;i--){
        UITableViewCell* p = [_pool objectAtIndex:i];
        [_pool removeObjectAtIndex:i];
//        [p removeFromSuperview];
        p = nil;
    }
}

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation{
    [self hideEmptyImage];
    [super insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

-(void)reloadRow:(int)n section:(int)section{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:n inSection:section];
    [indexPaths addObject:indexPath];
    
    [self beginUpdates];
    [self reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self endUpdates];
}

-(void)insertRow:(int)n section:(int)section{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:n inSection:section];
    [indexPaths addObject:indexPath];
    
    [self beginUpdates];
    [self insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self endUpdates];
}

-(void)deleteRow:(int)n section:(int)section{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:n inSection:section];
    [indexPaths addObject:indexPath];
    
    [self beginUpdates];
    [self deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self endUpdates];
}

@end
