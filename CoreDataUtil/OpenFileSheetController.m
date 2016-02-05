//
//  OpenFileSheetController.m
//  CoreDataUtil
//
//  Created by Laurie Caires on 5/17/12.
//  Copyright (c) 2012 mFluent LLC. All rights reserved.
//

#import "OpenFileSheetController.h"
#import "MFLConstants.h"
#import "SimulatorItem.h"
#import "Logger.h"

@interface OpenFileSheetController ()

@property (strong) NSDictionary *initialValues;
@property (strong) NSURL *momFileUrl;
@property (strong) NSURL *dbFileUrl;
@property (strong) NSDictionary *savedFields;
@property (strong) NSArray *processList;
@property (strong) NSMutableArray *simulatorUrlList;
@property (weak) IBOutlet NSOutlineView *simulatorSourceList;

@property (strong) NSMutableArray *simulatorNodeList;

- (void)initializeTab;
- (void)showOrHideOpenButton;
- (NSURL *)applicationSupportDirectory;
- (void)showOrHideSimulatorButton:(NSButton *)simulatorButton;
- (void)showOrHidePersistenceButtons;
- (NSSet *)filesWithExtension:(NSString *)dir :(NSString *)extension;
- (void)handleMomSelection:(NSSet *)momFiles modelTextField:(NSTextField *)modelTextField;
- (void)selectDbFileButtonAction:(NSTextField *)modelTextField persistenceTextField:(NSTextField *)persistenceTextField directoryURL:(NSURL*) directoryURL;
- (void)selectSimulatorDirectoryAction:(NSTextField *)modelTextField persistenceTextField:(NSTextField *)persistenceTextField;
- (void)clearComboSelector;

@end

@implementation OpenFileSheetController


- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self)
    {
        currentTab = FileTab;
        didSubmit = NO;
    }
    
    return self;
}

- (NSTextField*) currentModelTextField {
    
    switch (currentTab)
    {
        case FileTab:
            return self.fileTabModelTextField;
            break;
        case ProcessTab:
            return self.processTabModelTextField;
            break;
        case SimulatorTab:
            return self.simulatorTabModelTextField;
            break;
    }
    
    return nil;
}

- (NSTextField*) currentPersistenceTextField {
    
    switch (currentTab)
    {
        case FileTab:
            return self.fileTabPersistenceTextField;
            break;
        case ProcessTab:
            return self.processTabPersistenceTextField;
            break;
        case SimulatorTab:
            return self.simulatorTabPersistenceTextField;
            break;
    }
    
    return nil;
}


- (void) setModelFileInUI:(NSString*) momFilePath {
    if (momFilePath != nil) {
        [[self currentModelTextField] setStringValue:momFilePath];
    }
}


- (void)windowDidLoad
{
    [super windowDidLoad];
    DDLog(@"%s", __FUNCTION__);
    
    if (self.initialValues != nil)
    {
        NSString* momFile = (self.initialValues)[MFL_MOM_FILE_KEY];
        if (momFile != nil) {
            if ([[momFile lowercaseString] rangeOfString:@"/iphone simulator"].location != NSNotFound) {
                currentTab = SimulatorTab;
            }
            
            [self setModelFileInUI:momFile];
        
        }
        
        [self showOrHideOpenButton];
        [self showOrHidePersistenceButtons];
    }
}

- (void)initializeTab
{
    switch (currentTab)
    {
        case FileTab:
            [self.fileTabModelTextField setStringValue:@""];
            [self.fileTabPersistenceTextField setStringValue:@""];
        break;
        case ProcessTab:
            [self.processTabModelTextField setStringValue:@""];
            [self.processTabPersistenceTextField setStringValue:@""];
        break;
        case SimulatorTab:
            [self.simulatorTabModelTextField setStringValue:@""];
            [self.simulatorTabPersistenceTextField setStringValue:@""];
        break;
    }
    
    [self showOrHideOpenButton];
    [self showOrHidePersistenceButtons];
}

- (void)awakeFromNib
{
    DDLog(@"awakeFromNib");
    
    [self initializeTab];
}

- (void)showOrHideOpenButton
{
    BOOL canShow = NO;
    NSTextField* currentModelTextField = [self currentModelTextField];
    NSTextField* currentPersistenceTextField = [self currentPersistenceTextField];
    
    if ([currentModelTextField stringValue] != nil && [currentPersistenceTextField stringValue] != nil && 
        ![[currentModelTextField stringValue] isEqualToString:@""] && ![[currentPersistenceTextField stringValue] isEqualToString:@""])
    {
        canShow = YES;
    }
    
    if (canShow)
    {
        [self.openButton setEnabled:YES];
    }
    else
    {
        [self.openButton setEnabled:NO];
    }
}

- (NSURL *)applicationSupportDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return libraryURL;
}

- (void)showOrHideSimulatorButton:(NSButton *)simulatorButton
{
    NSString *appDirectory = [[[self applicationSupportDirectory] relativePath] stringByAppendingString:@"/iPhone Simulator"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:appDirectory])
    {
        [simulatorButton setEnabled:YES];
    }
    else
    {
        [simulatorButton setEnabled:NO];
    }
}

- (void)showOrHidePersistenceButtons
{
    switch (currentTab)
    {
        case FileTab:
            [self showOrHideSimulatorButton:self.fileTabSimulatorDirectoryButton];
            if ([self.fileTabModelTextField stringValue] != nil && ![[self.fileTabModelTextField stringValue] isEqualToString:@""])
            {
                [self.fileTabPersistenceFileButton setEnabled:YES];
                [self.fileTabSimulatorDirectoryButton setEnabled:YES];
            }
            else
            {
                [self.fileTabPersistenceFileButton setEnabled:NO];
                [self.fileTabSimulatorDirectoryButton setEnabled:NO];
            }
        break;
        case ProcessTab:
            if ([self.processTabModelTextField stringValue] != nil && ![[self.processTabModelTextField stringValue] isEqualToString:@""])
            {
                [self.processTabPersistenceFileButton setEnabled:YES];
                [self.processTabAppSupportButton setEnabled:YES];
            }
            else
            {
                [self.processTabPersistenceFileButton setEnabled:NO];
                [self.processTabAppSupportButton setEnabled:NO];
            }
        break;
        case SimulatorTab:
            [self showOrHideSimulatorButton:self.simulatorTabSimulatorDirectoryButton];
            
            if ([self.simulatorTabModelTextField stringValue] != nil && ![[self.simulatorTabModelTextField stringValue] isEqualToString:@""])
            {
                [self.simulatorTabPersistenceFileButton setEnabled:YES];
                [self.simulatorTabSimulatorDirectoryButton setEnabled:YES];
            }
            else
            {
                [self.simulatorTabPersistenceFileButton setEnabled:NO];
                [self.simulatorTabSimulatorDirectoryButton setEnabled:NO];
            }
        break;
    }
}

- (NSOrderedSet *)filesWithExtension:(NSString*)dir :(NSString *)extension
{
    DDLog(@"Scanning: %@", dir);
    
    NSMutableOrderedSet *contents = [[NSMutableOrderedSet alloc] init];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    if (dir && ([fm fileExistsAtPath:dir isDirectory:&isDir] && isDir))
    {
        if (![dir hasSuffix:@"/"])
        {
            dir = [dir stringByAppendingString:@"/"];
        }
        
        NSDirectoryEnumerator *de = [fm enumeratorAtPath:dir];
        NSString *f;
        NSString *fqn;
        while ((f = [de nextObject]))
        {
            fqn = [dir stringByAppendingString:f];
            if ([fm fileExistsAtPath:fqn isDirectory:&isDir] && isDir)
            {
                fqn = [fqn stringByAppendingString:@"/"];
            }
            if (extension == nil || [fqn hasSuffix:extension])
            {
                [contents addObject:fqn];
            }
        }
    }
    else
    {
        printf("%s must be directory and must exist\n", [dir UTF8String]);
    }
    
    return contents;
}

- (NSInteger) persistFileFormat {
    NSMenuItem* menuItem = nil;
    switch (currentTab)
    {
        case FileTab:
            menuItem = [self.fileTabPersistenceFormat selectedItem];
            break;
        case ProcessTab:
            menuItem = [self.processTabPersistenceFormat selectedItem];
            break;
        case SimulatorTab:
            menuItem = [self.simulatorTabPersistenceFormat selectedItem];
            break;
    }
    
    NSString* title = [menuItem title];
    if ([title isEqualToString:@"SQL"]) {
        return MFL_SQLiteStoreType;
    } else if ([title isEqualToString:@"XML"]) {
        return MFL_XMLStoreType;
    } else if ([title isEqualToString:@"BINARY"]) {
        return MFL_BinaryStoreType;
    } 
                
                
    // Default to SQL
    return MFL_SQLiteStoreType;
 }

- (void)handleMomSelection:(NSOrderedSet *)momFiles modelTextField:(NSTextField *)modelTextField
{
    if ([momFiles count] <= 0)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"No .mom file in this application."];
        [alert setInformativeText:@"Please choose another application that contains a .mom file."];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:NULL contextInfo:nil];
    }
    else if ([momFiles count] == 1)
    {
        NSString* momFile = [momFiles firstObject];
        if ([momFile hasPrefix:@"/"]) {
            self.momFileUrl = [NSURL fileURLWithPath:momFile];
        } else {
            self.momFileUrl = [NSURL URLWithString:momFile];
        }

        [modelTextField setStringValue:[self.momFileUrl relativePath]];
        
        [self showOrHideOpenButton];
        [self showOrHidePersistenceButtons];
    }
    else
    {
        [self clearComboSelector];
        [self.processSelectorBox setLineBreakMode:NSLineBreakByTruncatingMiddle];
        [self.processSelectorBox setPlaceholderString:@"Select Managed Object Model"];
        
        NSMutableArray* apps = [NSMutableArray arrayWithCapacity:0];
        self.simulatorUrlList = [[NSMutableArray alloc] initWithArray:[momFiles sortedArrayUsingDescriptors:nil]];
        for (NSString* app in self.simulatorUrlList)
        {
            NSString *appString = nil;
            NSString *momString = nil;
            
            NSArray *paths = [app componentsSeparatedByString:@"/"];
            for (NSString *path in paths)
            {
                if ([path hasSuffix:@".app"])
                {
                    appString = path;
                }
                else if ([path hasSuffix:MFL_MOM_FILE_EXTENSION])
                {
                    momString = path;
                }
            }
            
            [apps addObject:[NSString stringWithFormat:@"%@ %@", appString, momString]];
        }
        
        [self.processSelectorBox addItemsWithObjectValues:apps];
        
        [NSApp beginSheet:self.comboSelectorDialog
           modalForWindow:self.window
            modalDelegate:nil
           didEndSelector:NULL
              contextInfo:nil];
    }
}

- (void)selectDbFileButtonAction:(NSTextField *)modelTextField persistenceTextField:(NSTextField *)persistenceTextField directoryURL:(NSURL*) directoryURL
{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    if (directoryURL != nil) {
        [openDlg setDirectoryURL:directoryURL];
    } else {
        [openDlg setDirectoryURL:self.momFileUrl];
    }
    
    [openDlg setCanChooseFiles:YES];
    
    if ([openDlg runModal] == NSOKButton)
    {        
        NSString *fileString = [[openDlg URLs][0] absoluteString];
        if ([fileString hasSuffix:MFL_COREDATA_PROJECT_EXTENSION])
        {
            NSDictionary *filePaths = [[NSDictionary alloc] initWithContentsOfURL:[openDlg URLs][0]];
            self.momFileUrl = [NSURL URLWithString:filePaths[MFL_MOM_FILE_KEY]];
            [modelTextField setStringValue:[self.momFileUrl relativePath]];
            self.dbFileUrl = [NSURL URLWithString:filePaths[MFL_DB_FILE_KEY]];
            [persistenceTextField setStringValue:[self.dbFileUrl relativePath]];
        }
        else
        {
            self.dbFileUrl = [openDlg URLs][0];
            [persistenceTextField setStringValue:[self.dbFileUrl relativePath]];
        }
        
        [self showOrHideOpenButton];
    }
}

- (void)selectSimulatorDirectoryAction:(NSTextField *)modelTextField persistenceTextField:(NSTextField *)persistenceTextField
{
    NSURL* simulatorUrl = [self applicationSupportDirectory];
    
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setDirectoryURL: [simulatorUrl URLByAppendingPathComponent:@"iPhone Simulator"]];
    
    if (self.momFileUrl != nil && modelTextField != nil)
    {
        // iPhone usually puts the DB files in AppName.app/../../Documents
        NSString* momFilePath = [modelTextField stringValue];
        
        NSRange textRange;
        textRange =[momFilePath rangeOfString:[simulatorUrl absoluteString]];
        if(textRange.location != NSNotFound)
        {
            BOOL foundApp = NO;
            NSURL* pathUrl = self.momFileUrl;
            
            while (!foundApp)
            {
                NSString* lastComponent = [pathUrl lastPathComponent];
                if ([lastComponent hasSuffix:@".app"])
                {
                    foundApp = YES;
                }
                
                pathUrl = [pathUrl URLByDeletingLastPathComponent]; 
            }
            
            [openDlg setDirectoryURL: pathUrl];
        }
    }
    
    [openDlg setCanChooseFiles:YES];
    if ([openDlg runModal] == NSOKButton)
    {
        self.dbFileUrl = [openDlg URLs][0];
        [persistenceTextField setStringValue:[self.dbFileUrl relativePath]];
        
        [self showOrHideOpenButton];
    }
}

- (IBAction)fileTabModelFileButtonAction:(id)sender
{
    NSArray *fileTypes = @[@"mom", @"MOM", @"app", MFL_COREDATA_PROJECT_EXTENSION, MFL_COREDATA_PROJECT_EXTENSION_UPERCASE, MFL_COREDATA_EDITOR_PROJECT_EXTENSION];
    
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setTreatsFilePackagesAsDirectories:NO];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowedFileTypes:fileTypes];
    
    if ([openDlg runModal] == NSOKButton)
    {
        NSString *fileString = [[openDlg URLs][0] absoluteString];
        if ([fileString hasSuffix:MFL_COREDATA_PROJECT_EXTENSION])
        {
            NSDictionary *filePaths = [[NSDictionary alloc] initWithContentsOfURL:[openDlg URLs][0]];
            self.momFileUrl = [NSURL URLWithString:filePaths[MFL_MOM_FILE_KEY]];
            [self.fileTabModelTextField setStringValue:[self.momFileUrl relativePath]];
            self.dbFileUrl = [NSURL URLWithString:filePaths[MFL_DB_FILE_KEY]];
            [self.fileTabPersistenceTextField setStringValue:[self.dbFileUrl relativePath]];
            
            [self showOrHideOpenButton];
            [self showOrHidePersistenceButtons];
        }
        else if ([fileString hasSuffix:@".app"])
        {
            NSURL *url = [openDlg URLs][0];
            NSSet *momFiles = [self filesWithExtension: [url path]: MFL_MOM_FILE_EXTENSION];
            [self handleMomSelection:momFiles modelTextField:self.fileTabModelTextField];
        }
        else
        {
            self.momFileUrl = [openDlg URLs][0];
            [self.fileTabModelTextField setStringValue:[self.momFileUrl relativePath]];
            
            [self showOrHideOpenButton];
            [self showOrHidePersistenceButtons];
        }
    }
}

- (IBAction)processTabRunningProcessButtonAction:(id)sender
{
    [self clearComboSelector];
    [self.processSelectorBox setPlaceholderString:@"Select Application Process"];
    
    self.processList = [[NSWorkspace sharedWorkspace] runningApplications];
    NSMutableArray* apps = [NSMutableArray arrayWithCapacity:0];
    
    for (NSRunningApplication* app in self.processList)
    {        
        DDLog(@"App: %@->[%@]",[app localizedName], [app bundleURL]);
        [apps addObject:[app localizedName]];
    }
    
    // sort!
    [apps sortUsingSelector:@selector(caseInsensitiveCompare:)];
    // update self.processList
    NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"localizedName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    self.processList = [self.processList sortedArrayUsingDescriptors:@[desc]];
    
    [self.processSelectorBox addItemsWithObjectValues:apps];
    
    [NSApp beginSheet:self.comboSelectorDialog
	   modalForWindow:self.window
		modalDelegate:nil
	   didEndSelector:NULL
		  contextInfo:nil];
}

- (IBAction)simulatorTabSimulatorAppButtonAction:(id)sender
{
    [self clearComboSelector];
    [self.processSelectorBox setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [self.processSelectorBox setPlaceholderString:@"Select Managed Object Model"];
    
    NSURL* simulatorUrl = nil; //[[self applicationSupportDirectory] URLByAppendingPathComponent:@"iPhone Simulator"];
    //SimulatorItem* simulatorItem = [self.simulatorSourceList itemAtRow:[self.simulatorSourceList selectedRow]];
    if ([self.simulatorTabModelTextField stringValue] == nil || [[self.simulatorTabModelTextField stringValue] length] == 0) {
        DDLog(@"TODO: prompt user to select an app first.");
        NSBeep();
        return;
    } else {
        simulatorUrl = [NSURL URLWithString: [self.simulatorTabModelTextField stringValue]];
    }
    
    
    NSSet* paths = [self filesWithExtension:[simulatorUrl path] :MFL_MOM_FILE_EXTENSION];
    NSMutableArray* apps = [NSMutableArray arrayWithCapacity:0];
    self.simulatorUrlList = [[NSMutableArray alloc] init];
    for (NSString* app in paths)
    {
        [self.simulatorUrlList addObject:app];
        
        NSString *shortUrl = [[simulatorUrl absoluteString] stringByReplacingOccurrencesOfString:URL_FILE_BEGINNING withString:@""];
        shortUrl = [shortUrl stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
        shortUrl = [app stringByReplacingOccurrencesOfString:shortUrl withString:@""];
        NSArray *separatedPath = [shortUrl componentsSeparatedByString:@"/"];
        
        int versionIndex = 0;
        for (NSString* value in separatedPath) {
            if (value == nil) {
                versionIndex++;
            } else if  ([value length] == 0) {
                versionIndex++;
            } else if ([value rangeOfString:@"."].location == NSNotFound) {
                versionIndex++;
            } else {
                break;
            }
        }
        
        NSString *appName;
        for (NSString *path in separatedPath)
        {
            if ([path hasSuffix:@".app"])
            {
                appName = path;
            }
        }
        
        [apps addObject:[NSString stringWithFormat:@"%@ %@ %@", separatedPath[versionIndex], appName, separatedPath[[separatedPath count]-1]]];
    }
    
    [self.processSelectorBox addItemsWithObjectValues:apps];
    
    [NSApp beginSheet:self.comboSelectorDialog
	   modalForWindow:self.window
		modalDelegate:nil
	   didEndSelector:NULL
		  contextInfo:nil];
}

- (IBAction)tabStoreFileButtonAction:(id)sender
{
    if (currentTab == SimulatorTab) {
        SimulatorItem* simulatorItem = [self.simulatorSourceList itemAtRow:[self.simulatorSourceList selectedRow]];
        if (simulatorItem.itemType != MFLAppItem) {
            DDLog(@"TODO: prompt user to select app first.");
            NSBeep();
            return;
        }
        
        NSURL* directoryURL = [NSURL URLWithString:simulatorItem.documentsFolder];
        NSOpenPanel* openDlg = [NSOpenPanel openPanel];
        if (directoryURL != nil) {
            [openDlg setDirectoryURL:directoryURL];
        } else {
            [openDlg setDirectoryURL:self.momFileUrl];
        }
        
        [openDlg setCanChooseFiles:YES];
        
        if ([openDlg runModal] == NSOKButton)
        {
            NSString *fileString = [[openDlg URLs][0] absoluteString];
            if ([fileString hasSuffix:MFL_COREDATA_PROJECT_EXTENSION])
            {
                NSDictionary *filePaths = [[NSDictionary alloc] initWithContentsOfURL:[openDlg URLs][0]];
                self.dbFileUrl = [NSURL URLWithString:filePaths[MFL_DB_FILE_KEY]];
                [[self currentPersistenceTextField] setStringValue:[self.dbFileUrl relativePath]];
            }
            else
            {
                self.dbFileUrl = [openDlg URLs][0];
                [[self currentPersistenceTextField] setStringValue:[self.dbFileUrl relativePath]];
            }
            
            [self showOrHideOpenButton];
        }
        
    } else {
        NSTextField* storeTextField = [self currentPersistenceTextField];
        [self selectDbFileButtonAction:self.simulatorTabModelTextField persistenceTextField:storeTextField directoryURL:nil];
    }
}

- (IBAction)tabStoreApplicationSupportButtonAction:(id)sender
{
    NSTextField* storeTextField = [self currentPersistenceTextField];
    [self selectDbFileButtonAction:self.simulatorTabModelTextField persistenceTextField:storeTextField directoryURL:[self applicationSupportDirectory] ];
}

- (IBAction)openButtonAction:(id)sender
{
    didSubmit = YES;
    [NSApp stopModal];
    [self.window close];
}

- (IBAction)cancelButtonAction:(id)sender
{
    didSubmit = NO;
    [NSApp stopModal];
    [self.window close];
}

- (void)clearComboSelector
{
    self.processList = nil;
    [self.processSelectorBox removeAllItems];
    [self.processSelectorBox setStringValue:@""];
}

- (IBAction)comboSelectOk:(id)sender
{
    NSInteger selectedItemIndex = [self.processSelectorBox indexOfSelectedItem];
    if (selectedItemIndex >= 0)
    {
        if (self.processList != nil)
        {
            NSRunningApplication* selectedApp = (self.processList)[selectedItemIndex];
            DDLog(@"Selected: %@", selectedApp);
            
            NSSet* momFiles = [self filesWithExtension: [[selectedApp bundleURL] path]: MFL_MOM_FILE_EXTENSION];
            
            [self clearComboSelector];
            [NSApp endSheet:self.comboSelectorDialog];
            [self.comboSelectorDialog orderOut:sender];
            
            switch (currentTab)
            {
                case FileTab:
                    [self handleMomSelection:momFiles modelTextField:self.fileTabModelTextField];
                break;
                case ProcessTab:
                    [self handleMomSelection:momFiles modelTextField:self.processTabModelTextField];
                break;
                case SimulatorTab:
                    [self handleMomSelection:momFiles modelTextField:self.simulatorTabModelTextField];
                break;
            }
        }
        else
        {
            DDLog(@"value: %@ - %@", [self.processSelectorBox objectValueOfSelectedItem], [[self.processSelectorBox objectValueOfSelectedItem] class]);
            
            self.momFileUrl = [NSURL fileURLWithPath:(self.simulatorUrlList)[selectedItemIndex]];
            switch (currentTab)
            {
                case FileTab:
                    [self.fileTabModelTextField setStringValue:(self.simulatorUrlList)[selectedItemIndex]];
                break;
                case ProcessTab:
                    [self.processTabModelTextField setStringValue:(self.simulatorUrlList)[selectedItemIndex]];
                break;
                case SimulatorTab:
                    [self.simulatorTabModelTextField setStringValue:(self.simulatorUrlList)[selectedItemIndex]];
                break;
            }
            
            [self clearComboSelector];
            [NSApp endSheet:self.comboSelectorDialog];
            [self.comboSelectorDialog orderOut:sender];
            
            [self showOrHideOpenButton];
            [self showOrHidePersistenceButtons];
        }
    }
}

- (IBAction)comboSelectCancel:(id)sender
{
    [self clearComboSelector];
    [NSApp endSheet:self.comboSelectorDialog];
	[self.comboSelectorDialog orderOut:sender];
}

- (NSDictionary *)show:(NSWindow *)sender
{
    return [self show:sender :nil];
}

- (NSDictionary *)show:(NSWindow *)sender :(NSDictionary *)initialValues
{
    DDLog(@"show");
    NSWindow* window = self.window;
    [self setInitialValues:initialValues];
    [self initializeTab];
    
    if (self.initialValues != nil && (self.initialValues)[MFL_MOM_FILE_KEY] != nil)
    {
        NSString* momFilePath = (self.initialValues)[MFL_MOM_FILE_KEY];
        self.momFileUrl = [NSURL fileURLWithPath:momFilePath];
        
        if ([[momFilePath lowercaseString] rangeOfString:@"/iphone simulator"].location != NSNotFound) {
            NSArray* items = [self.tabView tabViewItems];
            for (NSTabViewItem * item in items) {
                if ([[item identifier] isEqualToString:@"3"]) {
                    currentTab = SimulatorTab;
                    [self.tabView selectTabViewItem:item];
                    break;
                }
            }
        }
        
        switch (currentTab)
        {
            case FileTab:
                [self.fileTabModelTextField setStringValue:momFilePath];
                break;
            case ProcessTab:
                [self.processTabModelTextField setStringValue:momFilePath];
                break;
            case SimulatorTab:
                [self.simulatorTabModelTextField setStringValue:momFilePath];
                break;
        }        
    }
    
    if (self.initialValues != nil && (self.initialValues)[MFL_DB_FILE_KEY] != nil)
    {
        NSString* storeFilePath = (self.initialValues)[MFL_DB_FILE_KEY];
        self.dbFileUrl = [NSURL fileURLWithPath:storeFilePath];
        
        NSTextField* textField = [self currentPersistenceTextField];
        [textField setStringValue:storeFilePath];
    }
    
    [self showOrHideOpenButton];
    [self showOrHidePersistenceButtons];
    
    [NSApp beginSheet:self.window modalForWindow:sender modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[NSApp runModalForWindow:window];
	// sheet is up here...
    
    [NSApp endSheet:window];
	[self.window orderOut:self];
    
    if (didSubmit)
    {
        self.savedFields = @{MFL_MOM_FILE_KEY: self.momFileUrl,
                            MFL_DB_FILE_KEY: self.dbFileUrl,
                            MFL_DB_FORMAT_KEY: [NSNumber numberWithLong:[self persistFileFormat]]};
    }
    else
    {
        self.savedFields = nil;
    }
    
	return self.savedFields;
}

- (IBAction) simulatorInfo: (id) sender {
    DDLog(@"SimulatorInfo selected");
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/yepher/CoreDataUtility#xcode-6-and-ios-simulator-project-files"]];
    
}

#pragma mark
#pragma NSTabViewDelegate

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if ([[tabViewItem identifier] isEqualToString:@"3"])
    {
        currentTab = SimulatorTab;
    }
    else if ([[tabViewItem identifier] isEqualToString:@"2"])
    {
        currentTab = ProcessTab;
    }
    else
    {
        currentTab = FileTab;
    }
    
    [self initializeTab];
}

#pragma mark - NSOutlineView

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    NSInteger rowCount =  (item == nil) ? 1 : [item numberOfChildren];
    return rowCount;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    BOOL result = (item == nil) ? YES : ([item numberOfChildren] != -1);
    return result;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    id result = (item == nil) ? [SimulatorItem rootItem] : [(SimulatorItem *)item childAtIndex:index];
    //DDLog(@"%s: %@", __FUNCTION__, result);
    return result;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView* result = [outlineView makeViewWithIdentifier:@"simulatorRow" owner:self];
    SimulatorItem* simItem = (SimulatorItem*) item;
    result.textField.stringValue = simItem.label;
    if ([item itemType] == MFLRootItem) {
        //[outlineView expandItem:item];
    }
    return result;
}

// Delegate methods

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    //DDLog(@"Item Selected: %@", notification);
    
    SimulatorItem* simulatorItem = [self.simulatorSourceList itemAtRow:[self.simulatorSourceList selectedRow]];
    if (simulatorItem.itemType == MFLAppItem) {
        DDLog(@"Selected Application: %@", simulatorItem.label);
        //self.momFileUrl = [NSURL URLWithString:simulatorItem.fullPath];
        [self.simulatorTabModelTextField setStringValue:simulatorItem.fullAppPath];
        [self showOrHidePersistenceButtons];
        //DDLog(@"Documents: %@", simulatorItem.documentsFolder);
        //[self.currentPersistenceTextField setStringValue:simulatorItem.documentsFolder];
    }
}



@end
