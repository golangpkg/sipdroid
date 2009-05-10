/**
 *  Siphon SIP-VoIP for iPhone and iPod Touch
 *  Copyright (C) 2008-2009 Samuel <samuelv0304@gmail.com>
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

#import "SiphonApplication.h"
#include "version.h"

#import "ContactViewController.h"
#import "RecentsViewController.h"
#import "FavoritesListController.h"

#import "Reachability.h"

#import "RecentCall.h"

#include <unistd.h>
#if defined(CYDIA) && (CYDIA == 1)
#import <CFNetwork/CFNetwork.h>
#include <sys/stat.h>
#endif

#define THIS_FILE "SiphonApplication.m"
#define kDelayToCall 10.0

typedef enum ConnectionState {
  DISCONNECTED,
  IN_PROGRESS,
  CONNECTED,
  ERROR
} ConnectionState;

@implementation SiphonApplication

@synthesize window;
//@synthesize navController;
@synthesize tabBarController;
@synthesize recentsViewController;

@synthesize launchDefault;
@synthesize isConnected;
@synthesize isIpod;

/***** MESSAGE *****/
-(void)displayParameterError:(NSString *)msg
{
  NSString *message = NSLocalizedString(msg, msg);
  NSString *error = [message stringByAppendingString:NSLocalizedString(
      @"\nTo correct this parameter, select \"Settings\" from your Home screen, "
       "and then tap the \"Siphon\" entry.", @"SiphonApp")];
  
  
  UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:nil 
                                                   message:error
#if defined(CYDIA) && (CYDIA == 1)
                                                  delegate:self
#else
                                                  delegate:nil
#endif
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", @"SiphonApp") 
                                         otherButtonTitles:NSLocalizedString(@"Settings", @"SiphonApp"), nil ] autorelease];
  [alert show];
  //[alert release];
}

#if defined(CYDIA) && (CYDIA == 1)
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 1)
    [[UIApplication sharedApplication] launchApplicationWithIdentifier:@"com.apple.Preferences"
                                                             suspended:NO];
}

#endif

-(void)displayError:(NSString *)error withTitle:(NSString *)title
{
  UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title 
                                                   message:error 
                                                  delegate:nil 
                                         cancelButtonTitle:NSLocalizedString(@"OK", @"SiphonApp") 
                                         otherButtonTitles:nil] autorelease];
   [alert show];
   //[alert release];
}

-(void)displayStatus:(pj_status_t)status withTitle:(NSString *)title
{
  char msg[80];
  pj_str_t pj_msg = pj_strerror(status, msg, 80);
  PJ_UNUSED_ARG(pj_msg);
  
  NSString *message = [NSString stringWithUTF8String:msg];
  
  [self displayError:message withTitle:nil];
  //[message release];
}

/***** SIP ********/
/* */
- (BOOL)sipConnect
{
  pj_status_t status;
  
  if (_app_config.pool == NULL && (sip_startup(&_app_config) != PJ_SUCCESS))
  {
       return FALSE;
  }

#if defined(CYDIA) && (CYDIA == 1)
#if 1
  BOOL overEDGE = FALSE;
  if (isIpod == FALSE)
  {
    overEDGE = [[NSUserDefaults standardUserDefaults] boolForKey:@"siphonOverEDGE"];
  }
  if ((overEDGE  && [[Reachability sharedReachability] remoteHostStatus] == NotReachable) || 
      (!overEDGE && [[Reachability sharedReachability] remoteHostStatus] != ReachableViaWiFiNetwork))
    return FALSE;
  // FIXME: beurk
  if (overEDGE  && [[Reachability sharedReachability] remoteHostStatus] == ReachableViaCarrierDataNetwork)
  {
#if 0
    CFStreamError error;
    Boolean hasBeenResolved;
    CFArrayRef array;
    CFStringRef google = CFSTR("www.google.com");
    CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, google);
    CFHostStartInfoResolution (host, kCFHostAddresses, &error);
    array = CFHostGetAddressing(host, &hasBeenResolved);
    array = CFHostGetNames (host, &hasBeenResolved);
    CFRelease(host);
#else
    NSURL * url = [[NSURL alloc] initWithString:[NSString stringWithCString:"http://www.google.com"]];
    NSData * data = [NSData dataWithContentsOfURL:url];
    [url release];
#endif
  }
#else
  //if (isIpod == FALSE &&
  //[[Reachability sharedReachability] remoteHostStatus] == NotReachable)
  if (isIpod == FALSE)
  {
    BOOL overEDGE = [[NSUserDefaults standardUserDefaults] boolForKey:@"siphonOverEDGE"];
    //NetworkStatus networkStatus = (overEDGE ? NotReachable : ReachableViaCarrierDataNetwork);
    //if ([[Reachability sharedReachability] remoteHostStatus] == networkStatus)
    //  return FALSE;
    if (overEDGE)
    {
      NetworkStatus networkStatus = [[Reachability sharedReachability] remoteHostStatus];
      if (networkStatus == NotReachable)
        return FALSE;
      
      // FIXME: beurk
      if (networkStatus == ReachableViaCarrierDataNetwork)
      {
#if 0
        CFStreamError error;
        Boolean hasBeenResolved;
        CFArrayRef array;
        CFStringRef google = CFSTR("www.google.com");
        CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, google);
        CFHostStartInfoResolution (host, kCFHostAddresses, &error);
        array = CFHostGetAddressing(host, &hasBeenResolved);
        array = CFHostGetNames (host, &hasBeenResolved);
        CFRelease(host);
#else
        NSURL * url = [[NSURL alloc] initWithString:[NSString stringWithCString:"http://www.google.com"]];
        NSData * data = [NSData dataWithContentsOfURL:url];
        [url release];
#endif
      }
    }
    else
    {
      if ([[Reachability sharedReachability] remoteHostStatus] != ReachableViaWiFiNetwork)
        return FALSE;
    }
  }
#endif
#else
  if (isIpod == FALSE &&
      [[Reachability sharedReachability] remoteHostStatus] != ReachableViaWiFiNetwork)
  {
    return FALSE;
  }
#endif

  
  if (_sip_acc_id == PJSUA_INVALID_ID)
  {
    if ((status = sip_connect(_app_config.pool, &_sip_acc_id)) != PJ_SUCCESS)
      return FALSE;
  }
  
  return TRUE;
}

/* */
- (BOOL)sipDisconnect
{
  if ((_sip_acc_id != PJSUA_INVALID_ID) &&
      (sip_disconnect(&_sip_acc_id) != PJ_SUCCESS))
  {
    return FALSE;
  }

  _sip_acc_id = PJSUA_INVALID_ID;

  isConnected = FALSE;

  return TRUE;
}

- (void)initUserDefaults:(NSMutableDictionary *)dict fromSettings:(NSString *)settings
{
  NSDictionary *prefItem;
  
  NSString *pathStr = [[NSBundle mainBundle] bundlePath];
  NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
  NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:settings];
  NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
  NSArray *prefSpecifierArray = [settingsDict objectForKey:@"PreferenceSpecifiers"];
  
  for (prefItem in prefSpecifierArray)
  {
    NSString *keyValueStr = [prefItem objectForKey:@"Key"];
    if (keyValueStr)
    {
      id defaultValue = [prefItem objectForKey:@"DefaultValue"];
      if (defaultValue)
      {
        [dict setObject:defaultValue forKey: keyValueStr];
      }
    }
  }
}

- (void)initUserDefaults
{
#if defined(CYDIA) && (CYDIA == 1)
  // TODO Franchement pas beau ;-)
  NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithInt: 1800], @"regTimeout",
                        [NSNumber numberWithBool:NO], @"enableNat",
                        [NSNumber numberWithInt: 5060], @"localPort",
                        [NSNumber numberWithInt: 4000], @"rtpPort",
                        [NSNumber numberWithInt: 15], @"kaInterval",
                        [NSNumber numberWithBool:NO], @"enableEC",
                        [NSNumber numberWithBool:YES], @"disableVad",
                        [NSNumber numberWithInt: 0], @"codec",
                        [NSNumber numberWithBool:NO], @"dtmfWithInfo",
                        [NSNumber numberWithBool:NO], @"enableICE",
                        [NSNumber numberWithInt: 0], @"logLevel",
                        [NSNumber numberWithBool:YES],  @"enableG711u",
                        [NSNumber numberWithBool:YES],  @"enableG711a",
                        [NSNumber numberWithBool:NO],   @"enableG722",
                        [NSNumber numberWithBool:YES],  @"enableGSM",
                        nil];
  
  [userDef registerDefaults:dict];
  [userDef synchronize];
#else
  NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
  
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: 10];
  [self initUserDefaults:dict fromSettings:@"Advanced.plist"];
  [self initUserDefaults:dict fromSettings:@"Network.plist"];
  [self initUserDefaults:dict fromSettings:@"Phone.plist"];
  [self initUserDefaults:dict fromSettings:@"Codec.plist"];
  
  [userDef registerDefaults:dict];
  [userDef synchronize];
  //[dict release];
#endif // CYDIA
}

- (void)initModel
{
  NSString *model = [[UIDevice currentDevice] model];
  isIpod = [model hasPrefix:@"iPod"];
  //NSLog(@"%@", model);
}

/***** APPLICATION *****/
- (void)applicationDidFinishLaunching:(UIApplication *)application
{
#if defined(CYDIA) && (CYDIA == 1)
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
  NSString *libraryDirectory = [NSString stringWithFormat:@"%@/Siphon", [paths objectAtIndex:0]];
  mkdir([libraryDirectory UTF8String], 0755);
#endif
  
  _sip_acc_id = PJSUA_INVALID_ID;

  isConnected = FALSE;
  
  [self initModel];

  self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];

  NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
  [self initUserDefaults];
  
	if (![[userDef objectForKey: @"username"] length] ||
		![[userDef objectForKey: @"server"] length])
  {    
    // TODO: go to settings immediately
    UIView *mainView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen]
                                                      applicationFrame]];
    mainView.backgroundColor = [UIColor whiteColor];
    
    UINavigationBar *navBar = [[UINavigationBar alloc] init];
    [navBar setFrame:CGRectMake(0, 0, 320,45)];
    navBar.barStyle = UIBarStyleBlackOpaque;
    [navBar pushNavigationItem: [[UINavigationItem alloc] initWithTitle:VERSION_STRING]
                                 animated: NO];
    [mainView addSubview:navBar];

    UIImageView *background = [[UIImageView alloc]
      initWithFrame:CGRectMake(0.0f, 45.0f, 320.0f, 185.0f)];
    [background setImage:[UIImage imageNamed:@"settings.png"]];
    [mainView addSubview:background];

    UILabel *text = [[UILabel alloc]
      initWithFrame: CGRectMake(0, 220, 320, 200.0f)];
    text.backgroundColor = [UIColor clearColor];
    text.textAlignment = UITextAlignmentCenter;
    text.numberOfLines = 0;
    text.lineBreakMode = UILineBreakModeWordWrap;
    text.font = [UIFont systemFontOfSize: 18];
    text.text = NSLocalizedString(@"Siphon requires a valid\nSIP account.\n\nTo enter this information, select \"Settings\" from your Home screen, and then tap the \"Siphon\" entry.", @"SiphonApp");
    [mainView addSubview:text];

    text = [[UILabel alloc] initWithFrame: CGRectMake(0, 420, 320, 40.0f)];
    text.backgroundColor = [UIColor clearColor];
    text.textAlignment = UITextAlignmentCenter;
    text.font = [UIFont systemFontOfSize: 16];
    text.text = NSLocalizedString(@"Press the Home button", @"SiphonApp");
    [mainView addSubview:text];
    [window addSubview: mainView];
    [window makeKeyAndVisible];
    
    launchDefault = NO;
  }
  else
  {
    NSString *server = [userDef stringForKey: @"proxyServer"];
    if (!server || [server length] < 1)
      server = [userDef stringForKey: @"server"];

    NSRange range = [server rangeOfString:@":" 
                                  options:NSCaseInsensitiveSearch|NSBackwardsSearch];
    if (range.length > 0)
    {
      server = [server substringToIndex:range.location];
    }
    
    [[Reachability sharedReachability] setHostName:server];
    // The Reachability class is capable of notifying your application when the network
    // status changes. By default, those notifications are not enabled.
    // Uncomment the following line to enable them:
    [[Reachability sharedReachability] setNetworkStatusNotificationsEnabled:YES];
    // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
    // method "reachabilityChanged" will be called. 
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:@"kNetworkReachabilityChangedNotification" object:nil];
    

    // Build GUI
    callViewController = [[CallViewController alloc] initWithNibName:nil bundle:nil];

    /* Favorites List*/
    FavoritesListController *favoritesListCtrl = [[FavoritesListController alloc]
                                                  initWithStyle:UITableViewStylePlain];
                                                  //autorelease];
    favoritesListCtrl.phoneCallDelegate = self;

    UINavigationController *favoritesViewCtrl = [[[UINavigationController alloc]
                                                   initWithRootViewController:
                                                   favoritesListCtrl]
                                                  autorelease];
    favoritesViewCtrl.navigationBar.barStyle = UIBarStyleBlackOpaque;
    [favoritesListCtrl release];

    /* Recents list */
    recentsViewController = [[RecentsViewController alloc]
                              initWithStyle:UITableViewStylePlain];
                                             //autorelease];
    recentsViewController.phoneCallDelegate = self;
    UINavigationController *recentsViewCtrl = [[[UINavigationController alloc]
                                                   initWithRootViewController:
                                                   recentsViewController]
                                                  autorelease];
    recentsViewCtrl.navigationBar.barStyle = UIBarStyleBlackOpaque;
    [recentsViewController release];

    /* Dialpad */
    phoneViewController = [[[PhoneViewController alloc]
                            initWithNibName:nil bundle:nil] autorelease];
    phoneViewController.phoneCallDelegate = self;

    /* Contacts */
    ContactViewController *contactsViewCtrl = [[[ContactViewController alloc]
                                                init] autorelease];
    contactsViewCtrl.phoneCallDelegate = self;

    tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = [NSArray arrayWithObjects:
                                        favoritesViewCtrl, recentsViewCtrl,
                                        phoneViewController,
                                        contactsViewCtrl, nil];
    tabBarController.selectedIndex = 2;

    [window addSubview:tabBarController.view];
    [window makeKeyAndVisible];
    if (_app_config.pool == NULL)
    {
      sip_startup(&_app_config);

      /** Call management **/
  	  [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(processCallState:)
                                                   name: kSIPCallState object:nil];
      
      /** Registration management */
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(processRegState:)
                                                   name: kSIPRegState object:nil];

      //[[Reachability sharedReachability] remoteHostStatus];
      [[NSNotificationCenter defaultCenter] addObserver:self 
                                               selector:@selector(reachabilityChanged:) 
                                                   name:@"kNetworkReachabilityChangedNotification" 
                                                 object:nil];
      //if ([[Reachability sharedReachability] addressFromString: server address:NULL])
      [self sipConnect];
    }
    launchDefault = YES;
    //[self performSelector:@selector(postFinishLaunch) withObject:nil afterDelay:0.0];
  }

 // [window makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // TODO enregistrer le numéro en cours pour le rappeler au retour ?
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self sipDisconnect];

  if (_app_config.pool != NULL)
  {
    sip_cleanup(&_app_config);
  }
  
  [callViewController release];
  //[tabBarController release];
  
  //int count  = [recentsViewController retainCount];
  //(void)count;
  // FIXME: logically previous [tabBarController release] should be ok !!!
  [recentsViewController finalizeDatabase];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
  pjsua_call_id call_id;
  pj_status_t status;
  
  if (launchDefault == NO)
    return NO;
  launchDefault = NO;

  if (!url)
  {
    // The URL is nil. There's nothing more to do.
    return NO;
  }

  NSString *URLString = [url absoluteString];
  if (!URLString)
  {
    // The URL's absoluteString is nil. There's nothing more to do.
    return NO;
  }
  NSString *URLSip = [URLString stringByReplacingOccurrencesOfString:@"://"
                                                          withString:@":" 
                                                             options:0 
                                                               range:NSMakeRange(3,4)];
  if (_app_config.pool == NULL || pjsua_verify_sip_url([URLSip UTF8String]) != PJ_SUCCESS)
  {
    return NO;
  }
  
  // FIXME: use private variable
  [[NSUserDefaults standardUserDefaults] setObject:URLSip forKey:@"callURL"];
  [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"dateOfCall"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  if ([self isConnected])
  {
    status = sip_dial_with_uri(_sip_acc_id, [URLSip UTF8String], &call_id);
    launchDefault = YES;
    if (status != PJ_SUCCESS)
    {
      // FIXME
      const pj_str_t *str = pjsip_get_status_text(status);
      NSString *msg = [[NSString alloc]
                       initWithBytes:str->ptr 
                       length:str->slen 
                       encoding:[NSString defaultCStringEncoding]];
      [self displayError:msg withTitle:@"registration error"];
      return NO;
    }
  }
  else
  {
    [self performSelector:@selector(outOfTimeToCall) withObject:nil afterDelay:kDelayToCall];
  }

  return YES;
}

- (void)outOfTimeToCall
{
  launchDefault = YES;
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"dateOfCall"];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"callURL"];
}

- (void)dealloc
{
  [phoneViewController release];
  [recentsViewController release];
  
	//[navController release];
  [callViewController release];
  [tabBarController release];  
	[window release];
	[super dealloc];
}

/************ **************/
//- (void)prefsHaveChanged:(NSNotification *)notification
//{
//  NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
//  [self displayError:[userDef objectForKey: @"sip_user"] withTitle:@"username"];
//}

- (NSString *)normalizePhoneNumber:(NSString *)number
{
  const char *phoneDigits = "22233344455566677778889999",
             *nb = [[number uppercaseString] UTF8String];
  int i, len = [number length];
  char *u, *c, *utf8String = (char *)calloc(sizeof(char), len+1);
  c = (char *)nb; u = utf8String;
  for (i = 0; i < len; ++c, ++i)
  {
    if (*c == ' ' || *c == '(' || *c == ')' || *c == '/' || *c == '-' || *c == '.')
      continue;
/*    if (*c >= '0' && *c <= '9')
    {
      *u = *c;
      u++;
    }
    else*/ if (*c >= 'A' && *c <= 'Z')
    {
      *u = phoneDigits[*c - 'A'];
    }
    else
      *u = *c;
    u++;
  }
  NSString * norm = [[NSString alloc] initWithUTF8String:utf8String];
  free(utf8String);
  return norm;
}


/** FIXME plutôt à mettre dans l'objet qui gère les appels **/
-(void) dialup:(NSString *)phoneNumber number:(BOOL)isNumber
{
  pjsua_call_id call_id;
  pj_status_t status;
  NSString *number;
#if 0
  if (isNumber)
  {
  NSString *normNumber = [self normalizePhoneNumber:phoneNumber];
  NSString *prefix = [[NSUserDefaults standardUserDefaults] stringForKey: 
                      @"intlPrefix"];
  if ([prefix length] > 0)
  {
    number = [normNumber stringByReplacingOccurrencesOfString:@"+"
                                                  withString:prefix 
                                                     options:0 
                                                       range:NSMakeRange(0,1)];
  }
  else
  {
    number = normNumber; 
  }
  }
  else
    number = phoneNumber;
#else
  if (isNumber)
    number = [self normalizePhoneNumber:phoneNumber];
  else
    number = phoneNumber;

  NSString *prefix = [[NSUserDefaults standardUserDefaults] stringForKey: 
                      @"intlPrefix"];
  if ([prefix length] > 0)
  {
    number = [number stringByReplacingOccurrencesOfString:@"+"
                                                   withString:prefix 
                                                      options:0 
                                                        range:NSMakeRange(0,1)];
  }
  
#endif

#if defined(CYDIA) && (CYDIA == 1)
  //NetworkStatus networkStatus = NotReachable;
  BOOL overEDGE = FALSE;
  if (isIpod == FALSE)
  {
    overEDGE = [[NSUserDefaults standardUserDefaults] boolForKey:@"siphonOverEDGE"];
  }
  
  if (!isConnected &&
    ((overEDGE  && [[Reachability sharedReachability] remoteHostStatus] == NotReachable) ||
     (!overEDGE && [[Reachability sharedReachability] remoteHostStatus] != ReachableViaWiFiNetwork)))
#else
  if (!isConnected &&
      [[Reachability sharedReachability] remoteHostStatus] != ReachableViaWiFiNetwork)
#endif
  {
    _phoneNumber = [[NSString stringWithString: number] retain];
    if (isIpod)
    {
      UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil 
                                                           message:NSLocalizedString(@"You must enable Wi-Fi or SIP account to place a call.",@"SiphonApp") 
                                                          delegate:nil 
                                                 cancelButtonTitle:NSLocalizedString(@"OK",@"SiphonApp")
                                                 otherButtonTitles:nil] autorelease];
      [alertView show];
    }
    else
    {
      UIActionSheet *actionSheet = [[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"The SIP server is unreachable!",@"SiphonApp") 
                                                               delegate:self 
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel",@"SiphonApp") 
                                                 destructiveButtonTitle:nil 
                                                      otherButtonTitles:NSLocalizedString(@"Cellular call",@"SiphonApp"),
                                     nil] autorelease];
      actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
      [actionSheet showInView: self.window];
    }
    return;
  }

  if ([self sipConnect])
  {
    NSRange range = [number rangeOfString:@"@"];
    if (range.location != NSNotFound)
    {
      status = sip_dial_with_uri(_sip_acc_id, [[NSString stringWithFormat:@"sip:%@", number] UTF8String], &call_id);
    }
    else
    status = sip_dial(_sip_acc_id, [number UTF8String], &call_id);
    if (status != PJ_SUCCESS)
    {
      // FIXME
      //[self displayStatus:status withTitle:nil];
      const pj_str_t *str = pjsip_get_status_text(status);
      NSString *msg = [[NSString alloc]
                       initWithBytes:str->ptr 
                       length:str->slen 
                       encoding:[NSString defaultCStringEncoding]];
      [self displayError:msg withTitle:@"registration error"];
    }
  }
}
/** Fin du FIXME */


- (void)processCallState:(NSNotification *)notification
{
#if 0
  NSNumber *value = [[ notification userInfo ] objectForKey: @"CallID"];
  pjsua_call_id callId = [value intValue];
#endif
  int state = [[[ notification userInfo ] objectForKey: @"State"] intValue];

  switch(state)
  {
    case PJSIP_INV_STATE_NULL: // Before INVITE is sent or received.
      return;
    case PJSIP_INV_STATE_CALLING: // After INVITE is sent.
      self.proximitySensingEnabled = YES;
    case PJSIP_INV_STATE_INCOMING: // After INVITE is received.
      self.idleTimerDisabled = YES;
      self.statusBarStyle = UIStatusBarStyleBlackTranslucent;
      [tabBarController presentModalViewController:callViewController animated:YES];
    case PJSIP_INV_STATE_EARLY: // After response with To tag.
    case PJSIP_INV_STATE_CONNECTING: // After 2xx is sent/received.
      break;
    case PJSIP_INV_STATE_CONFIRMED: // After ACK is sent/received.
      self.proximitySensingEnabled = YES;
      break;
    case PJSIP_INV_STATE_DISCONNECTED:
      self.idleTimerDisabled = NO;
      self.proximitySensingEnabled = NO;
      //[tabBarController dismissModalViewControllerAnimated: YES];
      [self performSelector:@selector(disconnected:) 
                 withObject:nil afterDelay:1.0];
      break;
  }
  [callViewController processCall: [ notification userInfo ]];
}

- (void)processRegState:(NSNotification *)notification
{
//  const pj_str_t *str;
  //NSNumber *value = [[ notification userInfo ] objectForKey: @"AccountID"];
  //pjsua_acc_id accId = [value intValue];
  int status = [[[ notification userInfo ] objectForKey: @"Status"] intValue];
  
  switch(status)
  {
    case 200: // OK
      isConnected = TRUE;
      if (launchDefault == NO)
      {
        pjsua_call_id call_id;
        NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:@"dateOfCall"];
        NSString *url = [[NSUserDefaults standardUserDefaults] stringForKey:@"callURL"];
        if (date && [date timeIntervalSinceNow] < kDelayToCall)
        {          
          sip_dial_with_uri(_sip_acc_id, [url UTF8String], &call_id);
        }
        [self outOfTimeToCall];
      }
      break;
    case 403: // registration failed
    case 404: // not found
      //sprintf(TheGlobalConfig.accountError, "SIP-AUTH-FAILED");
      //break;
    case 503:
    case PJSIP_ENOCREDENTIAL: 
      // This error is caused by the realm specified in the credential doesn't match the realm challenged by the server
      //sprintf(TheGlobalConfig.accountError, "SIP-REGISTER-FAILED");
      //break;
    default:
      isConnected = FALSE;
//      [self sipDisconnect];
  }
} 

- (void) disconnected:(id)fp8
{
  self.statusBarStyle = UIStatusBarStyleDefault;
  [tabBarController dismissModalViewControllerAnimated: YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet 
clickedButtonAtIndex:(NSInteger)buttonIndex
{
  NSURL *url;
  NSString *urlStr;
  switch (buttonIndex) 
  {
    case 0: // Call with GSM
      urlStr = [NSString stringWithFormat:@"tel://%@",_phoneNumber,nil];
      url = [NSURL URLWithString:urlStr];
      [self openURL: url];
      break;
    default:
      break;
  }
  [_phoneNumber release];
}

//-(RecentsViewController *)recentsViewController
//{
//  return recentsViewController;
//}

- (app_config_t *)pjsipConfig
{
  return &_app_config;
}

- (void)reachabilityChanged:(NSNotification *)notification
{
  // FIXME on doit pouvoir faire plus intelligent !!
  //NSLog(@"reachabilityChanged");
 // SCNetworkReachabilityFlags flags = [[[ notification userInfo ] 
  //                                     objectForKey: @"Flags"] intValue];
  [phoneViewController reachabilityChanged:notification];
  [self sipDisconnect];
  [self sipConnect];
}

@end
