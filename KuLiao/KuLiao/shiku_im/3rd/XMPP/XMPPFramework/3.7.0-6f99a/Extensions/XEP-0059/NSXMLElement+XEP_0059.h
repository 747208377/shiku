#import <Foundation/Foundation.h>

#import "KissXML.h"

@class XMPPResultSet;


@interface NSXMLElement (XEP_0059)

- (BOOL)isResultSet;
- (BOOL)hasResultSet;
- (XMPPResultSet *)resultSet;

@end
