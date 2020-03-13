#import <Foundation/Foundation.h>

#import "DDXML.h"

@class XMPPResultSet;

NS_ASSUME_NONNULL_BEGIN
@interface NSXMLElement (XEP_0059)

@property (nonatomic, readonly) BOOL isResultSet;
@property (nonatomic, readonly) BOOL hasResultSet;
@property (nonatomic, readonly, nullable) XMPPResultSet *resultSet;

@end
NS_ASSUME_NONNULL_END
