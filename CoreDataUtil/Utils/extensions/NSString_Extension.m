//
//  NSString_Extensions.m
//  LogRabbit
//
//  Created by Chris Wilson on 12/12/12.
//

#import "NSString_Extension.h"
#import "Logger.h"

@interface NSString (internal)

@end

@implementation NSString (Helpers)

/**
 returns YES if the string is an integer
 **/
- (BOOL)isInteger {
    if ([self intValue] != 0) {
        return true;
    } else if ([self isEqualToString:@"0"]) {
        return true;
    }

    return false;

}

// test if string contains substring
// NOTE: case sensitive search
- (BOOL)contains:(NSString *)substring {
    return [self contains:substring ignoreCase:NO];
}

// test if string contains substring
// @param ignoreCase : YES/NO
- (BOOL)contains:(NSString *)substring ignoreCase:(BOOL)ignoreCase {
    NSUInteger index = [self indexOfString:substring ignoreCase:ignoreCase];
    return (index != NSNotFound);
}

// find substring in this string
// first index of substring or NSNotFound
- (NSUInteger)indexOfString:(NSString *)substring {
    return [self indexOfString:substring ignoreCase:NO];
}

// find substring in this string
// first index of substring or NSNotFound
- (NSUInteger)indexOfString:(NSString *)substring ignoreCase:(BOOL)ignoreCase {
    NSRange range = [self rangeOfString:substring options:(ignoreCase ? NSCaseInsensitiveSearch : (NSStringCompareOptions)0)];
    return range.location;
}

// trim whitespace off front and end of string
- (NSString *) trim {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

// a safe version of characterAtIndex - prevents checking out of bounds
- (unichar)safeCharacterAtIndex:(NSUInteger)index {
    if (index < self.length) {
        return [self characterAtIndex:index];
    }
    else {
        return nil;
    }
}

// removes a substring which is between 'startsWith' and 'endsWith'
// @param removed - where to put the removed string
// @returns string without the removed substring (or entire string if not found)
//
// example: "this is a test (1234)"
// -> substringBetween:@"(" and:@")" into:&removedStr
// removedStr will be set to "1234"
// returns "this is a test"
- (NSString *)removeSubstringBetween:(NSString *)startStr and:(NSString *)endStr into:(NSString **)removed {
    // default removed string to nil
    if (removed != nil) {
        *removed = nil;
    }
    NSRange stRange = [self rangeOfString:startStr];
    if (stRange.location == NSNotFound) return self;
    NSUInteger stPos = NSMaxRange(stRange);
    NSInteger len = [self length] - stPos;
    // check if startStr is at end of string
    if (len <= 1) return nil;

    NSRange endRange = [self rangeOfString:endStr options:nil range:NSMakeRange(stPos, (NSUInteger)len)];
    if (endRange.location == NSNotFound) return self;

    //DDLog(@"st:%@, end:%@, %@", NSStringFromRange(stRange), NSStringFromRange(endRange), self );

    // remove substring and place into removed
    if (removed != nil) {
        NSUInteger endLen = endRange.location - stPos;
        *removed = [self substringWithRange:NSMakeRange(stPos, endLen)];
    }

    // return string around substring
    NSMutableString *newString = [NSMutableString new];
    if (stRange.location > 0) {
        [newString appendString:[self substringToIndex:stRange.location]];
    }
    if (NSMaxRange(endRange) < [self length]-1) {
        [newString appendString:[self substringFromIndex:NSMaxRange(endRange)]];
    }
    return newString;
}

@end
