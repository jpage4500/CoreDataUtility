//
//  MFLMainWindowController.h
//  CoreDataUtil
//
//  Created by Chris Wilson on 6/25/12.
//  Copyright (c) 2012 mFluent LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFLCoreDataIntrospection.h"
#import "CoreDataHistoryObject.h"

#import "EntityTableView.h"
#import "MBTableGrid.h"

@class EntityTableView;
@class MBTableGrid;

typedef NS_ENUM(NSUInteger, EViewType) {
 ViewTypeString = 0,
 ViewTypeNumber,
 ViewTypeDate,
 ViewTypeLink,
 ViewTypeTransformable,
};

@interface MFLMainWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, MFLCoreDataIntrospectionDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, NSSplitViewDelegate, MBTableGridDataSource, MBTableGridDelegate>

@property IBOutlet MBTableGrid *entityContentTable;

@property (weak) IBOutlet EntityTableView *dataSourceList;
@property (weak) IBOutlet NSSegmentedControl* userSelecteddateFormat;
@property (unsafe_unretained) IBOutlet NSWindow *predicateSheet;
@property (weak) IBOutlet NSMatrix *preferenceSheetMatrix;
@property (weak) IBOutlet NSTextField *generatedPredicateLabel;
@property (weak) IBOutlet NSSegmentedControl *historySegmentedControl;
@property (nonatomic) NSString *projectFile;

//- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;
- (BOOL) openFiles:(NSURL*) momFile persistenceFile:(NSURL*) persistenceFile persistenceType: (NSInteger) persistenceType;

- (BOOL)openProject:(NSString *)filename;

- (NSURL*) momFileUrl;
- (NSURL*) persistenceFileUrl;
- (NSInteger) persistenceFileFormat;

- (id)getValueObjFromDataRows:(NSInteger)row columnName:(NSString *)columnName;

/**
 Displays the info sheet for the currently selected entity
 **/
- (void)getInfoAction;

@end
