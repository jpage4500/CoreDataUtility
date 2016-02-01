//
// Created by Joe Page on 5/12/14.
//

#import <pthread.h>
#import "Logger.h"
#import "NSString_Extension.h"

// max # of characters (not bytes) to limit log -> string requests to
static const int MAX_LOG_TO_STRING_CHARS = 15000;

#if TARGET_OS_IPHONE
// Compiling for iOS
    #ifndef kCFCoreFoundationVersionNumber_iOS_8_0
        #define kCFCoreFoundationVersionNumber_iOS_8_0 1140.10
    #endif
    #define USE_PTHREAD_THREADID_NP                (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)
#else
// Compiling for Mac OS X
    #ifndef kCFCoreFoundationVersionNumber10_10
      #define kCFCoreFoundationVersionNumber10_10    1151.16
    #endif
    #define USE_PTHREAD_THREADID_NP                (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_10)
#endif /* if TARGET_OS_IPHONE */


@interface Logger ()

@property DDLogFileManagerDefault *logFileManager;

@property NSString *mainThreadId;

@end

@implementation Logger

+ (Logger *)getInstance {
    static Logger *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [Logger new];
    });
    return instance;
}

// configure CocoaLumberjack (https://github.com/CocoaLumberjack/CocoaLumberjack/wiki/GettingStarted)
- (void)registerLogger {
    // can only register once
    if (self.logFileManager != nil) { return; }

    // create file manager
    self.logFileManager = [[DDLogFileManagerDefault alloc] init];
    self.logFileManager.maximumNumberOfLogFiles = 1;

    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:self.logFileManager];
    fileLogger.maximumFileSize = 512 * 1024; // 500k
    fileLogger.rollingFrequency = kDDDefaultLogRollingFrequency;
    [fileLogger setLogFormatter:self];
    // add File logger (only DEBUG level entries will go to file)
    [DDLog addLogger:fileLogger withLevel:MFL_LOG_LEVEL_FILE];

    // add Console.app logger (Mac)
    //[DDLog addLogger:[DDASLLogger sharedInstance]];

    // add Terminal logger
    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    [ttyLogger setLogFormatter:self];
    [DDLog addLogger:ttyLogger withLevel:MFL_LOG_LEVEL_TTY];

    // show colors in console (see https://github.com/CocoaLumberjack/CocoaLumberjack/wiki/XcodeColors)
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];

    if (USE_PTHREAD_THREADID_NP) {
        __uint64_t tid;
        pthread_threadid_np(NULL, &tid);
        self.mainThreadId = [[NSString alloc] initWithFormat:@"%llu", tid];
    } else {
        self.mainThreadId = [[NSString alloc] initWithFormat:@"%x", pthread_mach_thread_np(pthread_self())];
    }

    // log to console only
    DDLogFileInfo *info = [self.logFileManager.sortedLogFileInfos firstObject];
    DDLogDebug(@"logging to file: %@", info.filePath);
}

// read last log into a string for uploading crash reports to server
- (NSString *)logToString {
    if (self.logFileManager == nil) {
        [self registerLogger];
    }
    DDLogFileInfo *info = [self.logFileManager.sortedLogFileInfos firstObject];
    if (info == nil) return @"no log found!";

    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:info.filePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSString *errMsg = [NSString stringWithFormat:@"ERROR reading file: %@", info.filePath];
        DDLogError(@"%@", errMsg);
        return errMsg;
    }

    // limit log files to last MAX_LOG_TO_STRING_CHARS characters
    NSUInteger len = [content length];
    if (len > MAX_LOG_TO_STRING_CHARS) {
        NSInteger fromIndex = len - MAX_LOG_TO_STRING_CHARS;
        NSString *truncatedStr = [content substringFromIndex:(NSUInteger)fromIndex];
        content = [NSString stringWithFormat:@"<truncated>\n%@", truncatedStr];
    }

    // NOTE: could be memory intensive for large log files
    //NSArray *lineArr = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    return content;
}

// see example at: https://github.com/CocoaLumberjack/CocoaLumberjack/wiki/CustomFormatters
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *logLevel;
    switch (logMessage.level) {
        case DDLogLevelError:
            logLevel = @"E";
            break;
        case DDLogLevelWarning:
            logLevel = @"W";
            break;
        case DDLogLevelInfo:
            logLevel = @"I";
            break;
        case DDLogLevelDebug:
            logLevel = @"D";
            break;
        default:
            logLevel = @"V";
            break;
    }

    NSString *dateAndTime = [self stringFromDate:(logMessage.timestamp)];
    NSString *message = logMessage.message;

    // Android log format: "10-15 15:16:07.176  5364  5432 I "
    // DDLog format: "2014-05-13 09:58:48:419 BriteIM[35887:303] "

    NSString *file = logMessage.fileName;
    // only interested in the first part of the filename and methodName.. that should be more than enough to help debug
    NSString *method = [self extractMethodName:logMessage.function];

    // main interest in thead ID is to check if a method is running on UI or a non-UI thread.. simplify this by saying "[UI]" if on main thread
    NSString *threadId;
    if ([self.mainThreadId isEqualToString:logMessage.threadID]) {
        threadId = @"UI";
    }
    else {
        threadId = logMessage.threadID;
    }

    return [NSString stringWithFormat:@"%@ %@ [%@] %@:%@: %@", dateAndTime, logLevel, threadId, file, method, message];
}

// NOTE: latest CocoaLumberjack's methodName property looks like "-[MFLAppDelegate methodNameOne:methodNameTwo:]".. parse out just first param (ie: "methodNameOne")
- (NSString *)extractMethodName:(NSString *)name {
    NSUInteger stPos = [name indexOfString:@" "];
    if (stPos != NSNotFound && (stPos + 1 < [name length])) {
        name = [name substringFromIndex:stPos + 1];
    }
    // get first part of method name
    NSUInteger endPos = 0;
    NSUInteger nameLen = [name length];
    for (endPos = 0; endPos < nameLen; endPos++) {
        unichar c = [name characterAtIndex:endPos];
        // look for end of method name (typically ":" or "]")
        if (c == ']' || c == ':' || c == ' ') {
            break;
        }
    }
    if (endPos < nameLen) {
        name = [name substringToIndex:endPos];
    }
    return name;
}

static NSString *const KEY = @"MFLLogger_NSDateFormatter";

- (NSString *)stringFromDate:(NSDate *)date {
    // NSDateFormatter is NOT thread-safe (FileLogger and TTYLogger are running on separate threads)
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *dateFormatter = threadDictionary[KEY];
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];

        // use a concise date format that has enough info for debugging a specific issue (IMO date isn't as important as time)
        // Android date format: "10-15 15:16:07.176"
        // DDLog date format: "2014-05-13 09:58:48:419"
        // @see http://waracle.net/iphone-nsdateformatter-date-formatting-table/
        [dateFormatter setDateFormat:@"MM-dd HH:mm:ss"];

        threadDictionary[KEY] = dateFormatter;
    }

    return [dateFormatter stringFromDate:date];
}

@end