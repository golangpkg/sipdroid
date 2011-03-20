/**
 *  Siphon SIP-VoIP for iPhone and iPod Touch
 *  Copyright (C) 2008-2011 Samuel <samuelv0304@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#import "RecentsViewController.h"
#import "RecentCall.h"

#import "SIPController.h"
#import "AKSIPURI.h"
#import "SIPAccountController.h"

#import "SiphonAppDelegate.h"
#import "SiphonCoreDataStorage.h"

@interface RecentsViewController ()

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end


@implementation RecentsViewController

@synthesize fetchedResultsController = fetchedResultsController_;
@synthesize managedObjectContext = managedObjectContext_;

- (NSDateFormatter *)dateFormatter 
{	
	if (dateFormatter_ == nil) 
	{
		dateFormatter_ = [[NSDateFormatter alloc] init];
		[dateFormatter_ setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter_ setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter_ setDoesRelativeDateFormatting:YES];
	}
	return dateFormatter_;
}

- (NSDateFormatter *)hourFormatter
{
	if (hourFormatter_ == nil)
	{
		hourFormatter_ = [[NSDateFormatter alloc] init];
		[hourFormatter_ setDateStyle:NSDateFormatterNoStyle];
		[hourFormatter_ setTimeStyle:NSDateFormatterShortStyle];
		[hourFormatter_ setDoesRelativeDateFormatting:YES];
	}
	return hourFormatter_;
}

/**
 Returns the fetched results controller. Creates and configures the controller if necessary.
 */
- (NSFetchedResultsController *)fetchedResultsController 
{
	if (fetchedResultsController_ != nil) 
		return fetchedResultsController_;
	
	// Create and configure a fetch request with the RecentCall entity.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"RecentCall" inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
	
	// Create the sort descriptors array.
	NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	//NSSortDescriptor *authorDescriptor = [[NSSortDescriptor alloc] initWithKey:@"author" ascending:YES];
	//NSSortDescriptor *titleDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
	//NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:authorDescriptor, titleDescriptor, nil];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:dateDescriptor, nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	// Create and initialize the fetch results controller.
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
																																															managedObjectContext:self.managedObjectContext
																																																sectionNameKeyPath:nil 
																																																				 cacheName:@"Root"];
	self.fetchedResultsController = aFetchedResultsController;
	fetchedResultsController_.delegate = self;
	
	// Memory management.
	[aFetchedResultsController release];
	[fetchRequest release];
	//[authorDescriptor release];
	//[titleDescriptor release];
	[dateDescriptor release];
	[sortDescriptors release];
	
	return fetchedResultsController_;
} 

- (NSManagedObjectContext *)managedObjectContext
{
	SiphonAppDelegate *appDelegate = (SiphonAppDelegate *)[[UIApplication sharedApplication] delegate];
	return appDelegate.dataStorage.managedObjectContext;
}

#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

- (id)initWithStyle:(UITableViewStyle)style
{
	if (self = [super initWithStyle:style]) 
  {    
    self.title = NSLocalizedString(@"Recent Calls", @"Recents View");
#if defined(CYDIA) && (CYDIA!=0)
    self.tabBarItem = [[UITabBarItem alloc]
                       initWithTabBarSystemItem: UITabBarSystemItemRecents tag:1];
#else
    self.tabBarItem.title = NSLocalizedString(@"Recents", @"Recents View");
    self.tabBarItem.image = [UIImage imageNamed:@"Recents"];
#endif
    //self.navigationItem.leftBarButtonItem = [self editButtonItem];
    /*self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
																							 initWithTitle:NSLocalizedString(@"Clear", @"Clear the call history")
                                               style:UIBarButtonItemStylePlain
																							 target:self action:@selector(clearAll:)]
                                              autorelease];*/
    
    // segmented control as the custom title view
#if 0
    NSArray *segmentTextContent = [NSArray arrayWithObjects:
                                   NSLocalizedString(@"All", @"Recents View"),
                                   NSLocalizedString(@"Missed", @"Recents View"),
                                   nil];
    UISegmentedControl* segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
    segmentedControl.selectedSegmentIndex = 0;
    //	segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    
    self.navigationItem.titleView = segmentedControl;
    [segmentedControl release];
#endif
	}
	return self;
}


#pragma mark -
#pragma mark View lifecycle

/*
 */
- (void)viewDidLoad 
{
	[super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
																						 initWithTitle:NSLocalizedString(@"Clear", @"Clear the call history")
																						 style:UIBarButtonItemStylePlain
																						 target:self action:@selector(clearAll:)]
																						autorelease];
	
	NSError *error;
	if (![[self fetchedResultsController] performFetch:&error]) 
	{
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		[error release];
		//exit(-1);  // Fail
	}
}

/*
 */
- (void)viewDidUnload 
{
	// Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
	// For example: self.myOutlet = nil;
	self.fetchedResultsController = nil;
	[dateFormatter_ release];
	dateFormatter_ = nil;
	[hourFormatter_ release];
	hourFormatter_ = nil;
}

/*
 */
- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	[self.tableView reloadData];
	id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController_ sections] objectAtIndex:0];
	int count = [sectionInfo numberOfObjects];
	if (count)
  {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
  }
  else
  {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem = nil;
  }
}

// Invoked when the user touches Edit.
- (void)setEditing:(BOOL)editing animated:(BOOL)animated 
{
  // Updates the appearance of the Edit|Done button as necessary.
  [super setEditing:editing animated:animated];
  [self.tableView setEditing:editing animated:YES];
	
  // Disable the clear button while editing.
  if (editing) 
  {
    self.navigationItem.rightBarButtonItem.enabled = NO;
  } 
  else 
  {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController_ sections] objectAtIndex:0];
		int count = [sectionInfo numberOfObjects];
    if (count)
			self.navigationItem.rightBarButtonItem.enabled = YES;
		else
    {
      self.navigationItem.leftBarButtonItem = nil;
      //self.navigationItem.rightBarButtonItem.enabled = NO;
    }
  }
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    // Return the number of sections.
    return [[fetchedResultsController_ sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section 
{
    // Return the number of rows in the section.
	id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController_ sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString *CellIdentifier = @"RecentsCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
																	 reuseIdentifier:CellIdentifier] autorelease];
	}
	
	[self configureCell:cell atIndexPath:indexPath];
	
	return cell;
}

- (void)configureCell:(UITableViewCell *)cell 
					atIndexPath:(NSIndexPath *)indexPath
{
	// Configure the cell...
	// Configure the cell to show the caller/callee
	RecentCall *aCall = [fetchedResultsController_ objectAtIndexPath:indexPath];
	
	cell.textLabel.text = aCall.displayName;
	if (aCall.isMissed)
		cell.textLabel.textColor = [UIColor redColor];
	else
		cell.textLabel.textColor = [UIColor blackColor];
	
	if ([aCall.date timeIntervalSinceNow] > -86400.0)
		cell.detailTextLabel.text = [self.hourFormatter stringFromDate:aCall.date];
	else 
		cell.detailTextLabel.text = [self.dateFormatter stringFromDate:aCall.date];
	cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
 */
- (void)tableView:(UITableView *)tableView 
		commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
		 forRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (editingStyle == UITableViewCellEditingStyleDelete) 
	{	
		// Delete the managed object.
		NSManagedObjectContext *context = [fetchedResultsController_ managedObjectContext];
		[context deleteObject:[fetchedResultsController_ objectAtIndexPath:indexPath]];
		
		NSError *error;
		if (![context save:&error]) 
		{
			// Update to handle the error appropriately.
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			//exit(-1);  // Fail
		}
	}   
}



/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // Navigation logic may go here. Create and push another view controller.
    /*
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
    */
	RecentCall *selectedCall = (RecentCall *)[[self fetchedResultsController] objectAtIndexPath:indexPath];

	// TODO call
	AccountController *firstEnabledAccountController = [[[SIPController sharedInstance] 
																											 enabledAccountControllers] objectAtIndex:0];
	
	AKSIPURI *destinationURI = [AKSIPURI SIPURIWithUser:selectedCall.phoneNumber
																								 host:firstEnabledAccountController.account.registrar
																					displayName:selectedCall.displayName];
	
	// TODO find the label
	[firstEnabledAccountController makeCallToURI:destinationURI
																		phoneLabel:@""];
}

- (void)tableView:(UITableView *)tableView 
accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	RecentCall *selectedCall = (RecentCall *)[[self fetchedResultsController] objectAtIndexPath:indexPath];
  if ([selectedCall.uid intValue] != kABRecordInvalidID)
  {
    ABAddressBookRef addressBook = ABAddressBookCreate();
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook,
                                                            [selectedCall.uid intValue]);
    //CFRelease(addressBook);
    if (person)
    {
      ABPersonViewController *personCtrl = [[ABPersonViewController alloc] init];
      personCtrl.displayedPerson = person;
      personCtrl.allowsEditing = NO;
      personCtrl.personViewDelegate = self;
      //[self setTitle:call.type forUIViewController:personCtrl];
      
      if ([selectedCall.identifier intValue] != kABMultiValueInvalidIdentifier)
        [personCtrl setHighlightedItemForProperty:kABPersonPhoneProperty 
                                   withIdentifier:[selectedCall.identifier intValue]];
      [self.navigationController pushViewController:personCtrl animated:YES];
      [personCtrl release];
      return;
    }
    selectedCall.uid = [NSNumber numberWithInt: kABRecordInvalidID];
    selectedCall.identifier = [NSNumber numberWithInt: kABMultiValueInvalidIdentifier];
  }
  
  CFErrorRef *error = NULL;
  ABRecordRef person = ABPersonCreate ();
  // Keep the call to update his fields if the user adds it to Address Book.
  //unknownCall = call;
  
  // Add Name
  if ([selectedCall.compositeName length])
    ABRecordSetValue(person, kABPersonFirstNameProperty, selectedCall.compositeName, 
                     error);
  
  // Add Number
  if ([selectedCall.phoneNumber length])
  {
    ABMutableMultiValueRef multiValue = ABMultiValueCreateMutable(kABStringPropertyType);
    ABMultiValueAddValueAndLabel(multiValue, selectedCall.phoneNumber, kABPersonPhoneMainLabel, 
                                 NULL);
    ABRecordSetValue(person, kABPersonPhoneProperty, multiValue, error);
  }
  ABUnknownPersonViewController *unknownCtrl = [[ABUnknownPersonViewController alloc] init];
  unknownCtrl.displayedPerson = person;
  unknownCtrl.allowsActions = YES;
  unknownCtrl.allowsAddingToAddressBook = true;
  // TODO implémenter et mettre à jour le nom, l'uid et l'identifier dans l'historique
  unknownCtrl.unknownPersonViewDelegate = self;
  //[self setTitle:call.type forUIViewController:unknownCtrl];
  CFRelease(person);
  [self.navigationController pushViewController:unknownCtrl animated:YES];
  [unknownCtrl release];
	
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate
/**
 Delegate methods of NSFetchedResultsController to respond to additions, removals and so on.
 */

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller 
{
	// The fetch controller is about to start sending change notifications, 
	// so prepare the table view for updates.
	[self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller 
	 didChangeObject:(id)anObject 
			 atIndexPath:(NSIndexPath *)indexPath 
		 forChangeType:(NSFetchedResultsChangeType)type 
			newIndexPath:(NSIndexPath *)newIndexPath
{	
	UITableView *tableView = self.tableView;
	
	switch(type) 
	{
		case NSFetchedResultsChangeInsert:
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate:
			[self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			break;
			
		case NSFetchedResultsChangeMove:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type 
{
	switch(type) 
	{
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
	// The fetch controller has sent all current change notifications, so tell the table view to process all updates.
	[self.tableView endUpdates];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)dealloc 
{
	[fetchedResultsController_ release];
	[managedObjectContext_ release];
	[dateFormatter_ release];
	[hourFormatter_ release];
	[super dealloc];
}

#pragma mark -
#pragma mark ABPersonViewControllerDelegate
- (BOOL)personViewController:(ABPersonViewController *)personViewController 
shouldPerformDefaultActionForPerson:(ABRecordRef)person 
										property:(ABPropertyID)property 
									identifier:(ABMultiValueIdentifier)identifierForValue
{
	CFTypeRef multiValue;
  CFIndex valueIdx;
  
  if (kABPersonPhoneProperty == property)
  {
    multiValue = ABRecordCopyValue(person, property);
    valueIdx = ABMultiValueGetIndexForIdentifier(multiValue,identifierForValue);
    NSString *phoneNumber = (NSString *)ABMultiValueCopyValueAtIndex(multiValue, valueIdx);

		if ([phoneNumber length])
		{
			NSString *name = (NSString *)ABRecordCopyCompositeName(person);
			if ([name length] == 0)
				//name = (NSString *)ABMultiValueCopyValueAtIndex(multiValue, valueIdx);
				name = [phoneNumber retain];
			NSString *label = (NSString *)ABMultiValueCopyLabelAtIndex(multiValue, valueIdx);			
			
			AccountController *firstEnabledAccountController = [[[SIPController sharedInstance] 
																													 enabledAccountControllers] objectAtIndex:0];
			
			AKSIPURI *destinationURI = [AKSIPURI SIPURIWithUser:phoneNumber
																										 host:firstEnabledAccountController.account.registrar
																							displayName:name];
			
			[firstEnabledAccountController makeCallToURI:destinationURI
																				phoneLabel:label];
		
		}
		
    return NO;
  }
  return YES;
}


#pragma mark -
#pragma mark ABUnknownPersonViewControllerDelegate
- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonView 
								 didResolveToPerson:(ABRecordRef)person
{
	if (person)
	{
		// update
	}
}

- (BOOL)unknownPersonViewController:(ABUnknownPersonViewController *)personViewController 
shouldPerformDefaultActionForPerson:(ABRecordRef)person 
													 property:(ABPropertyID)property 
												 identifier:(ABMultiValueIdentifier)identifier
{
	return NO;
}

#pragma mark -
#pragma mark Buttons
- (void)clearAll:(id)sender
{
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil 
                                                           delegate:self 
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel",@"Recents View") 
                                             destructiveButtonTitle:NSLocalizedString(@"Clear All Recents",@"Recents View") 
                                                  otherButtonTitles:nil];
  actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
  //[actionSheet showFromTabBar:self.view.superview];
  //[actionSheet showFromTabBar:self.parentViewController.tabBarController.view];
  //SiphonApplication *app = (SiphonApplication *)[SiphonApplication sharedApplication];
  //[actionSheet showInView:[app window]];
	[actionSheet showInView:self.navigationController.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet 
clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// Clear All Recent
	if (buttonIndex == actionSheet.destructiveButtonIndex)
	{
		//NSLog(@"Clear All Recent");
		// Create and configure a fetch request with the RecentCall entity.
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"RecentCall" inManagedObjectContext:self.managedObjectContext];
		[fetchRequest setEntity:entity];
		
		NSArray *theCalls = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
		[fetchRequest release];
		
		for (RecentCall *aCall in theCalls)
			[self.managedObjectContext deleteObject:aCall];
		
		[self.managedObjectContext save:nil];
	}
}


@end

