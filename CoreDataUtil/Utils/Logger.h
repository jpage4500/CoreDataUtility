//
// Created by Joe Page on 5/12/14.
//

#import <Foundation/Foundation.h>
#import "CocoaLumberjack.h"

// NOTE: below ddLogLevel only controls log level for what's compiled into the app
// The actual log levels allowed are defined by each logger (file=DEBUG+, console=VERBOSE+)
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

#define DDLog(frmt, ...) DDLogDebug(frmt, ##__VA_ARGS__)

#if DEBUG
    static const DDLogLevel MFL_LOG_LEVEL_FILE = DDLogLevelVerbose;
    static const DDLogLevel MFL_LOG_LEVEL_TTY = DDLogLevelVerbose;
    static const DDLogLevel MFL_LOG_LEVEL_CRASH = DDLogLevelInfo;
#else
    static const DDLogLevel MFL_LOG_LEVEL_FILE = DDLogLevelDebug; // NOTE: almost all debugging today is DEBUG
    static const DDLogLevel MFL_LOG_LEVEL_TTY = DDLogLevelDebug;
    static const DDLogLevel MFL_LOG_LEVEL_CRASH = DDLogLevelInfo;
#endif

@interface Logger : NSObject <DDLogFormatter>

+ (Logger *)getInstance;

- (void)registerLogger;

- (NSString *)logToString;

@end