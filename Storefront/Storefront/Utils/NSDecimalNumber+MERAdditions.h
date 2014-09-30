//
//  NSDecimalNumber+MERAdditions.h
//  Storefront
//
//  Created by Joshua Tessier on 2014-09-15.
//  Copyright (c) 2014 Shopify Inc. All rights reserved.
//

@import Foundation;

@interface NSDecimalNumber (MERAdditions)

+ (NSDecimalNumber*)decimalNumberOrZeroWithString:(NSString*)string;
+ (NSDecimalNumber*)decimalNumberFromJSON:(id)valueFromJSON;

@end
