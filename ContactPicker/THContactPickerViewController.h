//
//  ContactPickerViewController.h
//  ContactPicker
//
//  Created by Tristan Himmelman on 11/2/12.
//  Copyright (c) 2012 Tristan Himmelman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>
#import "THContactPickerView.h"
#import "THContact.h"
#import "THContactPickerTableViewCell.h"
#import <SBPickerSelector/SBPickerSelector.h>
@protocol THUserStatusDelegate
- (void) contactAdded:(THContact *)contact;
- (void) contactRemoved:(THContact *)contact;

@end
@interface THContactPickerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, THContactPickerDelegate, ABPersonViewControllerDelegate, SBPickerSelectorDelegate>

@property (nonatomic, strong) THContactPickerView *contactPickerView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSMutableArray *selectedContacts;
@property (nonatomic, strong) NSArray *filteredContacts;
@property (nonatomic, weak) UIViewController<THUserStatusDelegate> * delegate;

@end
