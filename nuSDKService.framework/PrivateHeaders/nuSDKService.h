//
//  nuSDKService.h
//  nuSDKService
//
//  Created by W.YudoAji on 02/03/20.
//  Copyright © 2020 newuniverse. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "aes.h"

//! Project version number for nuSDKService.
FOUNDATION_EXPORT double nuSDKServiceVersionNumber;

//! Project version string for nuSDKService.
FOUNDATION_EXPORT const unsigned char nuSDKServiceVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <nuSDKService/PublicHeader.h>
extern NSData * SecCreateKey(NSData * password, NSData * salt);
extern NSData * SecEncryptAES128CBCPad(NSData * data, NSData * key, NSData * iv);
extern NSData * SecDecryptAES128CBCPad(NSData * data, NSData * key, NSData * iv);
