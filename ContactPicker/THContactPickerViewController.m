//
//  ContactPickerViewController.m
//  ContactPicker
//
//  Created by Tristan Himmelman on 11/2/12.
//  Copyright (c) 2012 Tristan Himmelman. All rights reserved.
//

#import "THContactPickerViewController.h"
#import <AddressBook/AddressBook.h>
#import "THContact.h"

UIBarButtonItem *barButton;

@interface THContactPickerViewController ()

@property (nonatomic, assign) ABAddressBookRef addressBookRef;
@property (nonatomic, strong) THContact * actualContact;
@property (nonatomic, strong) NSIndexPath * indexPathSelectedRow;
@end

//#define kKeyboardHeight 216.0
#define kKeyboardHeight 0.0

@implementation THContactPickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Selecciona Contactos (0)";
        
        CFErrorRef error;
        _addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //    UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleBordered target:self action:@selector(removeAllContacts:)];
//    
//    barButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
//    barButton.enabled = FALSE;
//    
//    self.navigationItem.rightBarButtonItem = barButton;
    
    // Initialize and add Contact Picker View
    self.contactPickerView = [[THContactPickerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
    self.contactPickerView.delegate = self;
    [self.contactPickerView setPlaceholderString:@"Escribe el nombre del contacto"];
    [self.view addSubview:self.contactPickerView];
    
    // Fill the rest of the view with the table view
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.contactPickerView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.contactPickerView.frame.size.height - kKeyboardHeight) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"THContactPickerTableViewCell" bundle:nil] forCellReuseIdentifier:@"ContactCell"];
    
    [self.view insertSubview:self.tableView belowSubview:self.contactPickerView];
    
    ABAddressBookRequestAccessWithCompletion(self.addressBookRef, ^(bool granted, CFErrorRef error) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self getContactsFromAddressBook];
            });
        } else {
            // TODO: Show alert
        }
    });
}

-(void)getContactsFromAddressBook
{
    CFErrorRef error = NULL;
    self.contacts = [[NSMutableArray alloc]init];
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if (addressBook) {
        NSArray *allContacts = (__bridge_transfer NSArray*)ABAddressBookCopyArrayOfAllPeople(addressBook);
        NSMutableArray *mutableContacts = [NSMutableArray arrayWithCapacity:allContacts.count];
        
        NSUInteger i = 0;
        for (i = 0; i<[allContacts count]; i++)
        {
            THContact *contact = [[THContact alloc] init];
            ABRecordRef contactPerson = (__bridge ABRecordRef)allContacts[i];
            contact.recordId = ABRecordGetRecordID(contactPerson);

            // Get first and last names
            NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty);
            NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(contactPerson, kABPersonLastNameProperty);
            
            // Set Contact properties
            contact.firstName = firstName;
            contact.lastName = lastName;
//            contact.phones = [self getPhonesForRecordID:(int)contact.recordId];
            
            
            // Get image if it exists
            NSData  *imgData = (__bridge_transfer NSData *)ABPersonCopyImageData(contactPerson);
            contact.image = [UIImage imageWithData:imgData];
            if (!contact.image) {
                contact.image = [UIImage imageNamed:@"icon-avatar-60x60"];
            }
            
            [mutableContacts addObject:contact];
        }
        
        if(addressBook) {
            CFRelease(addressBook);
        }
        
        self.contacts = [NSArray arrayWithArray:mutableContacts];
        self.selectedContacts = [NSMutableArray array];
        self.filteredContacts = self.contacts;
        
        [self.tableView reloadData];
    }
    else
    {
        DDLogVerbose(@"Error");
        
    }
}

- (void) refreshContacts
{
    for (THContact* contact in self.contacts)
    {
        [self refreshContact: contact];
    }
    [self.tableView reloadData];
}

- (void) refreshContact:(THContact*)contact
{
    
    ABRecordRef contactPerson = ABAddressBookGetPersonWithRecordID(self.addressBookRef, (ABRecordID)contact.recordId);
    contact.recordId = ABRecordGetRecordID(contactPerson);
    
    // Get first and last names
    NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty);
    NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(contactPerson, kABPersonLastNameProperty);
    
    // Set Contact properties
    contact.firstName = firstName;
    contact.lastName = lastName;
//    contact.phones = [self getPhonesForRecordID:(int)contact.recordId];
    
    
    // Get image if it exists
    NSData  *imgData = (__bridge_transfer NSData *)ABPersonCopyImageData(contactPerson);
    contact.image = [UIImage imageWithData:imgData];
    if (!contact.image) {
        contact.image = [UIImage imageNamed:@"icon-avatar-60x60"];
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshContacts];
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat topOffset = 0;
    if ([self respondsToSelector:@selector(topLayoutGuide)]){
        topOffset = self.topLayoutGuide.length;
    }
    CGRect frame = self.contactPickerView.frame;
    frame.origin.y = topOffset;
    self.contactPickerView.frame = frame;
    [self adjustTableViewFrame:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)adjustTableViewFrame:(BOOL)animated {
    CGRect frame = self.tableView.frame;
    // This places the table view right under the text field
    frame.origin.y = self.contactPickerView.frame.size.height;
    // Calculate the remaining distance
    frame.size.height = self.view.frame.size.height - self.contactPickerView.frame.size.height - kKeyboardHeight;
    
    if(animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        [UIView setAnimationDelay:0.1];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        
        self.tableView.frame = frame;
        
        [UIView commitAnimations];
    }
    else{
        self.tableView.frame = frame;
    }
}



#pragma mark - UITableView Delegate and Datasource functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredContacts.count;
}

- (CGFloat)tableView: (UITableView*)tableView heightForRowAtIndexPath: (NSIndexPath*) indexPath {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Get the desired contact from the filteredContacts array
    THContact *contact = [self.filteredContacts objectAtIndex:indexPath.row];
    
    // Initialize the table view cell
    NSString *cellIdentifier = @"ContactCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    // Get the UI elements in the cell;
    UILabel *contactNameLabel = (UILabel *)[cell viewWithTag:101];
    UILabel *mobilePhoneNumberLabel = (UILabel *)[cell viewWithTag:102];
    UIImageView *contactImage = (UIImageView *)[cell viewWithTag:103];
    UIImageView *checkboxImageView = (UIImageView *)[cell viewWithTag:104];
    
    // Assign values to to US elements
    contactNameLabel.text = [contact fullName];
    mobilePhoneNumberLabel.text = @"";
    if(contact.image) {
        contactImage.image = contact.image;
    }
    contactImage.layer.masksToBounds = YES;
    contactImage.layer.cornerRadius = 20;
    
    // Set the checked state for the contact selection checkbox
    UIImage *image;
    if ([self.selectedContacts containsObject:[self.filteredContacts objectAtIndex:indexPath.row]]){
        //cell.accessoryType = UITableViewCellAccessoryCheckmark;
        image = [UIImage imageNamed:@"icon-checkbox-selected-green-25x25"];
    } else {
        //cell.accessoryType = UITableViewCellAccessoryNone;
        image = [UIImage imageNamed:@"icon-checkbox-unselected-25x25"];
    }
    checkboxImageView.image = image;
    
    // Assign a UIButton to the accessoryView cell property
    cell.accessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    // Set a target and selector for the accessoryView UIControlEventTouchUpInside
    [(UIButton *)cell.accessoryView addTarget:self action:@selector(viewContactDetail:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView.tag = contact.recordId; //so we know which ABRecord in the IBAction method

    return cell;
}

- (void)updateInfo:(UIImage *)image checkboxImageView:(UIImageView *)checkboxImageView {
    // Enable Done button if total selected contacts > 0
    if(self.selectedContacts.count > 0) {
        barButton.enabled = TRUE;
    }
    else
    {
        barButton.enabled = FALSE;
    }
    
    // Update window title
    self.title = [NSString stringWithFormat:@"Añadir Usuarios (%lu)", (unsigned long)self.selectedContacts.count];
    
    // Set checkbox image
    checkboxImageView.image = image;
    // Reset the filtered contacts
    self.filteredContacts = self.contacts;
    // Refresh the tableview
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Hide Keyboard
    [self.contactPickerView resignKeyboard];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    // This uses the custom cellView
    // Set the custom imageView
    THContact *user = [self.filteredContacts objectAtIndex:indexPath.row];
    UIImageView *checkboxImageView = (UIImageView *)[cell viewWithTag:104];
    UIImage *image;
    
    if ([self.selectedContacts containsObject:user]){ // contact is already selected so remove it from ContactPickerView
        //cell.accessoryType = UITableViewCellAccessoryNone;
        if([_delegate respondsToSelector:@selector(contactRemoved:)]){
            [_delegate performSelectorInBackground:@selector(contactRemoved:) withObject:user];
        }
        [self.selectedContacts removeObject:user];
        [self.contactPickerView removeContact:user];
        // Set checkbox to "unselected"
        image = [UIImage imageNamed:@"icon-checkbox-unselected-25x25"];
    } else {
        // Contact has not been selected, add it to THContactPickerView
        user.phones = [self getPhonesForRecordID:user.recordId];
        //cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.actualContact = user;
        self.indexPathSelectedRow = indexPath;
        if (user.phones.count > 1){
            SBPickerSelector * phonePicker = [SBPickerSelector picker];
            
            phonePicker.pickerData = [[user.phones allValues] mutableCopy];
            phonePicker.pickerType =  SBPickerSelectorTypeText;
            phonePicker.doneButtonTitle = @"Aceptar";
            phonePicker.cancelButtonTitle = @"Cancelar";
            phonePicker.delegate = self;
            [phonePicker showPickerOver:self];
            

        }else{
            [self assignPhoneNumber:[[self.actualContact.phones allValues] firstObject]];
            self.actualContact = nil;
        }
        
        
        // Set checkbox to "selected"
        image = [UIImage imageNamed:@"icon-checkbox-selected-green-25x25"];
    }
    
    [self updateInfo:image checkboxImageView:checkboxImageView];
}
- (void)assignPhoneNumber:(NSString *)phone {
    self.actualContact.phone = phone;
    if([_delegate respondsToSelector:@selector(contactAdded:)]){
        [_delegate performSelectorInBackground:@selector(contactAdded:) withObject:self.actualContact];
    }
    [self.selectedContacts addObject:self.actualContact];
    [self.contactPickerView addContact:self.actualContact withName:self.actualContact.fullName];
    UIImage *  image = [UIImage imageNamed:@"icon-checkbox-unselected-25x25"];
     UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.indexPathSelectedRow];
    UIImageView *checkboxImageView = (UIImageView *)[cell viewWithTag:104];

    [self updateInfo:image checkboxImageView:checkboxImageView];
}

-(void) SBPickerSelector:(SBPickerSelector *)selector selectedValue:(NSString *)value index:(NSInteger)idx{
    [self assignPhoneNumber:value];
    
}
- (void) SBPickerSelector:(SBPickerSelector *)selector cancelPicker:(BOOL)cancel{
    self.actualContact = nil;
    self.indexPathSelectedRow = nil;
}
#pragma mark - THContactPickerTextViewDelegate

- (void)contactPickerTextViewDidChange:(NSString *)textViewText {
    if ([textViewText isEqualToString:@""]){
        self.filteredContacts = self.contacts;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.%@ contains[cd] %@ OR self.%@ contains[cd] %@", @"firstName", textViewText, @"lastName", textViewText];
        self.filteredContacts = [self.contacts filteredArrayUsingPredicate:predicate];
    }
    [self.tableView reloadData];
}

- (void)contactPickerDidResize:(THContactPickerView *)contactPickerView {
    [self adjustTableViewFrame:YES];
}

- (void)contactPickerDidRemoveContact:(id)contact {
    [self.selectedContacts removeObject:contact];
    if([_delegate respondsToSelector:@selector(contactRemoved:)]){
        [_delegate performSelectorInBackground:@selector(contactRemoved:) withObject:contact];
    }
    NSUInteger index = [self.contacts indexOfObject:contact];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    //cell.accessoryType = UITableViewCellAccessoryNone;
    
    // Enable Done button if total selected contacts > 0
    if(self.selectedContacts.count > 0) {
        barButton.enabled = TRUE;
    }
    else
    {
        barButton.enabled = FALSE;
    }
    
    // Set unchecked image
    UIImageView *checkboxImageView = (UIImageView *)[cell viewWithTag:104];
    UIImage *image;
    image = [UIImage imageNamed:@"icon-checkbox-unselected-25x25"];
    checkboxImageView.image = image;
    
    // Update window title
    self.title = [NSString stringWithFormat:@"Add Members (%lu)", (unsigned long)self.selectedContacts.count];
}

- (void)removeAllContacts:(id)sender
{
    
    [self.contactPickerView removeAllContacts];
    [self.selectedContacts removeAllObjects];
    self.filteredContacts = self.contacts;
    [self.tableView reloadData];
}
#pragma mark ABPersonViewControllerDelegate

- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return YES;
}
- (NSMutableDictionary *) getPhonesForRecordID:(ABRecordID) recordID{
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, nil);
    NSMutableDictionary * phonesDict = [[NSMutableDictionary alloc] init];
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook,recordID);
    
    ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
    
    for(CFIndex j = 0; j < ABMultiValueGetCount(phones); j++)
    {
        
        NSString* num = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phones, j);
        
        CFStringRef locLabel1 = ABMultiValueCopyLabelAtIndex(phones, j);
        
        NSString *phoneLabel1 =(__bridge NSString*) ABAddressBookCopyLocalizedLabel(locLabel1);
        [phonesDict setValue:num forKey:phoneLabel1];
        CFRelease(locLabel1);
    
        
    }
    return phonesDict;
}

// This opens the apple contact details view: ABPersonViewController
//TODO: make a THContactPickerDetailViewController
- (IBAction)viewContactDetail:(UIButton*)sender {
    ABRecordID personId = (ABRecordID)sender.tag;
    ABPersonViewController *view = [[ABPersonViewController alloc] init];
    view.addressBook = self.addressBookRef;
    view.personViewDelegate = self;
    view.displayedPerson = ABAddressBookGetPersonWithRecordID(self.addressBookRef, personId);

    
    [self.navigationController pushViewController:view animated:YES];
}

// TODO: send contact object
- (void)done:(id)sender
{
    
}
- (void) setSelectedContacts:(NSMutableArray *)selectedContacts{
    _selectedContacts = selectedContacts;
    [self.tableView reloadData];
}

@end
