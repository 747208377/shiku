#import <Foundation/Foundation.h>
#import "KissXML.h"


@interface NSXMLElement (XEP_0203)

- (BOOL)wasDelayed;
- (NSDate *)delayedDeliveryDate;

@end
