//
//  NSString_Extension.h
//  LogRabbit
//
//  Created by Chris Wilson on 12/15/12.
//

#import <Foundation/Foundation.h>

@interface NSString (Helpers)

/**
 returns YES if the string is an integer
 **/
- (BOOL)isInteger;

- (BOOL)contains:(NSString *)substring;

- (BOOL)contains:(NSString *)substring ignoreCase:(BOOL)ignoreCase;

- (NSUInteger)indexOfString:(NSString *)substring;

- (NSUInteger)indexOfString:(NSString *)substring ignoreCase:(BOOL)ignoreCase;

- (NSString *)trim;

- (unichar)safeCharacterAtIndex:(NSUInteger)index;

- (NSString *)removeSubstringBetween:(NSString *)startStr and:(NSString *)endStr into:(NSString **)removed;
@end
