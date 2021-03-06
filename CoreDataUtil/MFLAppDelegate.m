//
//  MFLAppDelegate.m
//  CoreDataUtil
//
//  Created by Chris Wilson on 11/3/11.
//  Copyright (c) 2011 mFluent LLC. All rights reserved.
//

#import "MFLAppDelegate.h"
#import "MFLConstants.h"
#import "MFLMainWindowController.h"
#import "OpenFileSheetController.h"
#import "MFLCoreDataEditorProjectLoader.h"
#import "Logger.h"

NSString* const APPLICATIONS_DIR = @"/Applications/";

@interface MFLAppDelegate ()

@property (strong) OpenFileSheetController *openFileSheetController;

- (void) addRecentDocument: (NSURL*) recentDocumentUrl;

@end

@implementation MFLAppDelegate


- (BOOL) openFileHelper: (NSString*) filename {
    if ([filename hasSuffix:MFL_COREDATA_PROJECT_EXTENSION]) {
        BOOL result = [self.mainWindowController openProject:filename];
        if (result)
        {
            [self addRecentDocument:[NSURL fileURLWithPath:filename]];
            self.projectHasChanged = NO;
        }
        
        return result;
        
    } else if ([filename hasSuffix:MFL_MOM_FILE_EXTENSION]) {
        DDLog(@"Load MOM File: [%@]", filename);
        //NSURL* momUrl = [NSURL fileURLWithPath:filename];
        NSDictionary* initialValue = @{MFL_MOM_FILE_KEY: filename};
        
        if (self.openFileSheetController != nil) {
            NSBeep();
            return YES;
        }
        
        self.openFileSheetController = [[OpenFileSheetController alloc] initWithWindowNibName:@"OpenFileSheetController"];
        NSDictionary *newValues = [self.openFileSheetController show:self.window: initialValue];
        self.openFileSheetController = nil;
        if (newValues[MFL_MOM_FILE_KEY] != nil && newValues[MFL_DB_FILE_KEY] != nil)
        {
            
            NSNumber* persistenceFormat = newValues[MFL_DB_FORMAT_KEY];
            if (persistenceFormat == nil) {
                persistenceFormat = [NSNumber numberWithInt:MFL_SQLiteStoreType];
            }
            
            BOOL result = [self.mainWindowController openFiles:newValues[MFL_MOM_FILE_KEY] persistenceFile:newValues[MFL_DB_FILE_KEY] persistenceType:[persistenceFormat intValue]];
            
            if (result)
            {
                [self addRecentDocument:[NSURL fileURLWithPath:filename]];
                self.projectHasChanged = YES;
            }
        }
        
        return YES;
        
    } else if ([filename hasSuffix:MFL_COREDATA_EDITOR_PROJECT_EXTENSION]) {
        MFLCoreDataEditorProjectLoader* externalLoader = [[MFLCoreDataEditorProjectLoader alloc] init];
        
        NSDictionary* project = nil;
        @try {
            project = [externalLoader decodeProjectFile:filename];
        
        } @catch (NSException *exception) {
            DDLog(@"Failed to load CoreDataEditor External Project [%@]", exception);
        }

        if (project == nil) {
            NSBeep();
            return NO;
        } else {
            self.projectHasChanged = NO;
        }
        
        self.openFileSheetController = [[OpenFileSheetController alloc] initWithWindowNibName:@"OpenFileSheetController"];
        NSDictionary *newValues = [self.openFileSheetController show:self.window: project];
        self.openFileSheetController = nil;
        if (newValues[MFL_MOM_FILE_KEY] != nil && newValues[MFL_DB_FILE_KEY] != nil)
        {
            
            NSNumber* persistenceFormat = newValues[MFL_DB_FORMAT_KEY];
            if (persistenceFormat == nil) {
                persistenceFormat = [NSNumber numberWithInt:MFL_SQLiteStoreType];
            }
            
            BOOL result = [self.mainWindowController openFiles:newValues[MFL_MOM_FILE_KEY] persistenceFile:newValues[MFL_DB_FILE_KEY] persistenceType:[persistenceFormat intValue]];
            
            if (result)
            {
                [self addRecentDocument:[NSURL fileURLWithPath:filename]];
                self.projectHasChanged = YES;
            }
        }
        
        return YES;
        
    } else {
        DDLog(@"Unknown file type [%@].", filename);
        NSBeep();
        return NO;
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{   
    if (self.mainWindowController == nil) {
        self.mainWindowController = [[MFLMainWindowController alloc] initWithWindowNibName:@"MFLMainWindowController"];
    }
    
    [self handleLaunchArguments:[ [NSProcessInfo processInfo] arguments] ];
    
    [self setWindow:[self.mainWindowController window]];

    // Open previously opened file
    if ([self.mainWindowController momFileUrl] == nil) {
        NSDocumentController *controller = [NSDocumentController sharedDocumentController];
        NSArray *documents = [controller recentDocumentURLs];
        
        // If there is a recent document, try to open it.
        if ([documents count] > 0)
        {
            [self openFileHelper:[documents[0] path]];
            if ([[documents[0] absoluteString] hasSuffix:MFL_COREDATA_PROJECT_EXTENSION])
            {
                self.projectHasChanged = NO;
            }
        }
        else
        {
            [self newAction:aNotification];
        }
    }

    // bring app to foreground
    [NSApp activateIgnoringOtherApps:YES];
}

+ (NSUInteger)indexOfArgument:(NSString *)argumentName inArguments:(NSArray *)arguments
{
    NSUInteger result = NSNotFound;
    for (NSUInteger index = 0; index < arguments.count; index ++)
    {
        NSString *argument;
        if ( [ [arguments objectAtIndex:index] isKindOfClass:[NSString class] ] )
        {
            argument = [arguments objectAtIndex:index];
        }
        
        if ( [argument isEqualToString:argumentName] )
        {
            result = index;
            break;
        }
    }
    return result;
}

+ (NSString *)getValueForArgument:(NSString *)argumentName inArguments:(NSArray *)arguments
{
    NSString *result;
    
    NSUInteger argumentIndex = [self indexOfArgument:argumentName inArguments:arguments];
    if (argumentIndex != NSNotFound)
    {
        if (argumentIndex + 1 < arguments.count)
        {
            if ( [ [arguments objectAtIndex:argumentIndex + 1] isKindOfClass:[NSString class] ] )
            {
                result = [arguments objectAtIndex:argumentIndex + 1];
            }
        }
    }
    
    return result;
}

- (void)handleLaunchArguments:(NSArray *)launchArguments
{
    NSUInteger helpIndex = [MFLAppDelegate indexOfArgument:@"--help" inArguments:launchArguments];
    if (helpIndex != NSNotFound)
    {
        NSLog(@"Command Line Usage:");
        NSLog(@"--model FILE \t\t (Required) Specify the location of the model file");
        NSLog(@"--store FILE \t\t (Required) Specify the location of the persistent store file");
        NSLog(@"--storeType TYPE \t\t (Required) Specify the type of the persistent store file, types include: SQLite, XML, Binary");
        exit(0);
    } else
    {
        NSURL *model = [NSURL URLWithString:[MFLAppDelegate getValueForArgument:@"--model" inArguments:launchArguments] ];
        NSURL *store = [NSURL URLWithString:[MFLAppDelegate getValueForArgument:@"--store" inArguments:launchArguments] ];
        MFL_StoreTypes storeFormat = 0;
        BOOL storeFormatSet = NO;

        NSString *storeFormatString = [MFLAppDelegate getValueForArgument:@"--storeType" inArguments:launchArguments];
        if (storeFormatString)
        {
            if ( [storeFormatString isEqualToString:@"SQLite"] )
            {
                storeFormat = MFL_SQLiteStoreType;
                storeFormatSet = YES;
            } else if ( [storeFormatString isEqualToString:@"XML"] )
            {
                storeFormat = MFL_XMLStoreType;
                storeFormatSet = YES;
            } else if ( [storeFormatString isEqualToString:@"Binary"] )
            {
                storeFormat = MFL_BinaryStoreType;
                storeFormatSet = YES;
            }
        }
        
        if (model && store && storeFormatSet)
        {
            BOOL result = [self.mainWindowController openFiles:model persistenceFile:store persistenceType:(NSInteger)storeFormat];
            
            if (result) {
                self.projectHasChanged = YES;
            }
        }
    }
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    if (self.mainWindowController == nil) {
        self.mainWindowController = [[MFLMainWindowController alloc] initWithWindowNibName:@"MFLMainWindowController"];
    }
    
    return [self openFileHelper:filename];
    
}

- (IBAction)openAction:(id)sender
{
    DDLog(@"openAction: [%@]", sender);
    [self.window makeKeyAndOrderFront:self];
    NSArray *fileTypes = @[MFL_COREDATA_PROJECT_EXTENSION, MFL_COREDATA_PROJECT_EXTENSION_UPERCASE, MFL_COREDATA_EDITOR_PROJECT_EXTENSION];
    
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowedFileTypes:fileTypes];
    
    if ([openDlg runModal] == NSOKButton)
    {
        NSString *filename = [[openDlg URLs][0] path];
        [self openFileHelper:filename];
    }
}


- (IBAction)newAction:(id)sender
{
    DDLog(@"New Action Called.");
    if (self.openFileSheetController != nil) {
        NSBeep();
    }
    
    self.openFileSheetController = [[OpenFileSheetController alloc] initWithWindowNibName:@"OpenFileSheetController"];
    NSDictionary *newValues = [self.openFileSheetController show:self.window];
    self.openFileSheetController = nil;
    if (newValues[MFL_MOM_FILE_KEY] != nil && newValues[MFL_DB_FILE_KEY] != nil)
    {
        
        NSNumber* persistenceFormat = newValues[MFL_DB_FORMAT_KEY];
        if (persistenceFormat == nil) {
            persistenceFormat = [NSNumber numberWithInt:MFL_SQLiteStoreType];
        }
        
        BOOL result = [self.mainWindowController openFiles:newValues[MFL_MOM_FILE_KEY] persistenceFile:newValues[MFL_DB_FILE_KEY] persistenceType:[persistenceFormat intValue]];

        if (result) {
            self.projectHasChanged = YES;
        }
    }
}

- (IBAction)showStoreInFinder:(id)sender {
    if (self.mainWindowController == nil) {return;}
    if (self.mainWindowController.persistenceFileUrl == nil) {return; }
    
    NSArray *fileURLs = @[self.mainWindowController.persistenceFileUrl];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}

- (IBAction)showModelInFinder:(id)sender {
    if (self.mainWindowController == nil) {return;}
    if (self.mainWindowController.momFileUrl == nil) {return; }
    
    NSArray *fileURLs = @[self.mainWindowController.momFileUrl];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}

- (void)addRecentDocument:(NSURL*) recentDocument
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    [docController noteNewRecentDocumentURL:recentDocument];
}


- (IBAction)clearRecentDocuments:(id)sender {
    DDLog(@"clearRecentDocuments: [%@]", sender);
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    [docController clearRecentDocuments:sender];
}


- (void)applicationWillFinishLaunching:(NSNotification *)notification
{

}


- (void)awakeFromNib
{
    
}

- (IBAction)saveAction:(id)sender
{
    if (self.mainWindowController == nil)
    {
        return;
    }
    
    NSInteger persistenceType = [self.mainWindowController persistenceFileFormat];
    NSURL* persistenceUrl = [self.mainWindowController persistenceFileUrl];
    NSURL* momfileUrl = [self.mainWindowController momFileUrl];
    DDLog(@"Will Save [%ld]\n%@\n%@",persistenceType, momfileUrl, persistenceUrl);
    
    if (momfileUrl != nil)
    {
        NSArray *fileTypes = @[MFL_COREDATA_PROJECT_EXTENSION, MFL_COREDATA_PROJECT_EXTENSION_UPERCASE, MFL_COREDATA_EDITOR_PROJECT_EXTENSION];
        
        NSSavePanel* saveDlg = [NSSavePanel savePanel];
        [saveDlg setAllowedFileTypes:fileTypes];
        
        NSArray *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentURLString = [URL_FILE_BEGINNING stringByAppendingString:documents[0]];
        [saveDlg setDirectoryURL:[NSURL URLWithString:documentURLString]];
        
        if ([saveDlg runModal] == NSSaveAsOperation)
        {
            NSDictionary *stuffToSave = @{MFL_PROJECT_FILE_VERSION_KEY: @1,
                                         MFL_MOM_FILE_KEY: [momfileUrl absoluteString],
                                         MFL_DB_FORMAT_KEY: @((int)persistenceType),
                                         MFL_DB_FILE_KEY: [persistenceUrl absoluteString]};

            NSURL *saveUrl = [saveDlg URL];
            if (![stuffToSave writeToURL:saveUrl atomically:NO])
            {
                DDLog(@"Error in saving file!");
            }
            else
            {
                [self addRecentDocument:saveUrl];

                [self.mainWindowController setProjectFile:saveUrl.absoluteString];
            }
            self.projectHasChanged = NO;
        } else {
            DDLog(@"User Canceled Save...");
        }
    }
    
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (self.projectHasChanged) {
        //Prompt user to save project before exiting
        NSString *question = NSLocalizedString(@"Core Data Pro project not saved. Quit without saving?", @"UnsavedProjectChanges");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"QuitDiscardsChangesText");
        NSString *quitButton = NSLocalizedString(@"Exit", @"QuitAnywayButtonText");
        NSString *saveAndExit = NSLocalizedString(@"Save and Exit", @"SaveAndExitButtonText");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"CancelButtonText");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:saveAndExit];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        switch (answer) {
            case  NSAlertFirstButtonReturn:         // Quit Anyway
                DDLog(@"NSAlertFirstButtonReturn: Quit without saving project");
                return NSTerminateNow;
                break;
            case  NSAlertSecondButtonReturn:        // Save And Exit
                DDLog(@"NSAlertSecondButtonReturn: Save project and exit");
                [self saveAction:sender];
                
                if (self.projectHasChanged) {
                    return [self applicationShouldTerminate:sender];
                } else {
                    return NSTerminateNow;
                }
                
                break;
            case  NSAlertThirdButtonReturn:         // Cancel (Don't exit app)
                DDLog(@"NSAlertThirdButtonReturn: Cancel");
                return NSTerminateCancel;
                break;
                
            default:
                DDLog(@"default");
                return NSTerminateNow;
                break;
        }
        
        
    }
    
    return NSTerminateNow;
}


- (IBAction)reportAnIssueAction:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/yepher/CoreDataUtility/issues"]];
}


@end
