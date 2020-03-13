//
//  XMPPStreamManagementPersistentStorage.m
//  friendlib
//
//  Created by lujiangbin on 15/9/29.
//  Copyright © 2015年 Mac. All rights reserved.
//

#import "XMPPStreamManagementPersistentStorage.h"
#import <libkern/OSAtomic.h>
#import "XMPPStreamManagementStanzas.h"

#define kResumptionId [NSString stringWithFormat:@"resumptionId_%@",MY_USER_ID]
#define kTimeout [NSString stringWithFormat:@"timeout_%@",MY_USER_ID]
#define kLastDisconnect [NSString stringWithFormat:@"lastDisconnect_%@",MY_USER_ID]
#define kLastHandledByClient [NSString stringWithFormat:@"lastHandledByClient_%@",MY_USER_ID]
#define kLastHandledByServer [NSString stringWithFormat:@"lastHandledByServer_%@",MY_USER_ID]

#define kPendingOutgoingStanzas [NSString stringWithFormat:@"pendingOutgoingStanzas_%@",MY_USER_ID]

@interface XMPPStreamManagementPersistentStorage ()
{
    int32_t isConfigured;
}

@end

@implementation XMPPStreamManagementPersistentStorage


- (BOOL)configureWithParent:(XMPPStreamManagement *)parent queue:(dispatch_queue_t)queue
{
    return OSAtomicCompareAndSwap32(0, 1, &isConfigured);
}

- (void)setResumptionId:(NSString *)inResumptionId
                timeout:(uint32_t)inTimeout
         lastDisconnect:(NSDate *)inLastDisconnect
              forStream:(XMPPStream *)stream
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:inResumptionId forKey:kResumptionId];
    [userDefaults setObject:@(inTimeout) forKey:kTimeout];
    [userDefaults setObject:inLastDisconnect forKey:kLastDisconnect];
    [userDefaults setObject:@(0) forKey:kLastHandledByClient];
    [userDefaults setObject:@(0) forKey:kLastHandledByServer];
    [userDefaults setObject:nil forKey:kPendingOutgoingStanzas];
    [userDefaults synchronize];
}

- (void)setLastDisconnect:(NSDate *)inLastDisconnect
      lastHandledByClient:(uint32_t)inLastHandledByClient
                forStream:(XMPPStream *)stream
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:inLastDisconnect forKey:kLastDisconnect];
    [userDefaults setObject:@(inLastHandledByClient) forKey:kLastHandledByClient];
    [userDefaults synchronize];
}

- (void)setLastDisconnect:(NSDate *)inLastDisconnect
      lastHandledByServer:(uint32_t)inLastHandledByServer
   pendingOutgoingStanzas:(NSArray *)inPendingOutgoingStanzas
                forStream:(XMPPStream *)stream
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:inLastDisconnect forKey:kLastDisconnect];
    [userDefaults setObject:@(inLastHandledByServer) forKey:kLastHandledByServer];
    //[userDefaults setObject:inPendingOutgoingStanzas forKey:@"pendingOutgoingStanzas"];
    
    
    
    NSMutableArray *archiveArray = [NSMutableArray arrayWithCapacity:inPendingOutgoingStanzas.count];
    for (XMPPStreamManagementOutgoingStanza *stanzas in inPendingOutgoingStanzas) {
        NSData *stanzasData = [NSKeyedArchiver archivedDataWithRootObject:stanzas];
        [archiveArray addObject:stanzasData];
    }
    [userDefaults setObject:archiveArray forKey:kPendingOutgoingStanzas];
    
    [userDefaults synchronize];
}

- (void)setLastDisconnect:(NSDate *)inLastDisconnect
      lastHandledByClient:(uint32_t)inLastHandledByClient
      lastHandledByServer:(uint32_t)inLastHandledByServer
   pendingOutgoingStanzas:(NSArray *)inPendingOutgoingStanzas
                forStream:(XMPPStream *)stream
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:inLastDisconnect forKey:kLastDisconnect];
    [userDefaults setObject:@(inLastHandledByClient) forKey:kLastHandledByClient];
    [userDefaults setObject:@(inLastHandledByServer) forKey:kLastHandledByServer];
    //[userDefaults setObject:inPendingOutgoingStanzas forKey:@"pendingOutgoingStanzas"];
    NSMutableArray *archiveArray = [NSMutableArray arrayWithCapacity:inPendingOutgoingStanzas.count];
    for (XMPPStreamManagementOutgoingStanza *stanzas in inPendingOutgoingStanzas) {
        NSData *stanzasData = [NSKeyedArchiver archivedDataWithRootObject:stanzas];
        [archiveArray addObject:stanzasData];
    }
    [userDefaults setObject:archiveArray forKey:kPendingOutgoingStanzas];
    
    [userDefaults synchronize];
}

- (void)getResumptionId:(NSString **)resumptionIdPtr
                timeout:(uint32_t *)timeoutPtr
         lastDisconnect:(NSDate **)lastDisconnectPtr
              forStream:(XMPPStream *)stream
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (resumptionIdPtr)   *resumptionIdPtr   = [userDefaults valueForKey:kResumptionId];
    if (timeoutPtr)        *timeoutPtr        = [[userDefaults valueForKey:kTimeout] unsignedIntValue];
    if (lastDisconnectPtr) *lastDisconnectPtr = [userDefaults valueForKey:kLastDisconnect];
}


- (void)getLastHandledByClient:(uint32_t *)lastHandledByClientPtr
           lastHandledByServer:(uint32_t *)lastHandledByServerPtr
        pendingOutgoingStanzas:(NSArray **)pendingOutgoingStanzasPtr
                     forStream:(XMPPStream *)stream;
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (lastHandledByClientPtr)    *lastHandledByClientPtr    = [[userDefaults valueForKey:kLastHandledByClient] unsignedIntValue];
    if (lastHandledByServerPtr)    *lastHandledByServerPtr    = [[userDefaults valueForKey:kLastHandledByServer] unsignedIntValue];
   // if (pendingOutgoingStanzasPtr) *pendingOutgoingStanzasPtr = [userDefaults valueForKey:@"pendingOutgoingStanzas"];
    
    if (pendingOutgoingStanzasPtr) {
        NSMutableArray *archiveArray = [userDefaults valueForKey:kPendingOutgoingStanzas];
        NSMutableArray *outgoingArray = [NSMutableArray arrayWithCapacity:archiveArray.count];
        for (NSData *data in archiveArray) {
            XMPPStreamManagementOutgoingStanza *outgoingStanza = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [outgoingArray addObject:outgoingStanza];
        }
        *pendingOutgoingStanzasPtr = outgoingArray;
    }

}

- (void)removeAllForStream:(XMPPStream *)stream
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:nil forKey:kResumptionId];
    [userDefaults setInteger:0 forKey:kTimeout];
    [userDefaults setObject:nil forKey:kLastDisconnect];
    [userDefaults setInteger:0 forKey:kLastHandledByClient];
    [userDefaults setInteger:0 forKey:kLastHandledByServer];
    [userDefaults setObject:nil forKey:kPendingOutgoingStanzas];
    [userDefaults synchronize];
}


@end
