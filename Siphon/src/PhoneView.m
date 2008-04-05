/**
 *  Siphon SIP-VoIP for iPhone and iPod Touch
 *  Copyright (C) 2008 Samuel <samuelv@users.sourceforge.org>
 *  Copyright (C) 2008 Christian Toepp <chris.touchmods@googlemail.com>
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

#import <UIKit/UIKit.h>
#import <UIKit/UITextField-Internal.h>
#import <UIKit/UITextField-SyntheticEvents.h>
#import <UIKit/UITextField.h>
#import <UIKit/UITextFieldBackground.h>
#import <UIKit/UITextFieldLabel.h>

#import <CoreGraphics/CGGeometry.h>
#import <OSServices/SystemSound.h>

#import <Message/NetworkController.h>
#import <iTunesStore/ISNetworkController.h>
#import <WebCore/WebFontCache.h>

#import "PhoneView.h"

#include "call.h"
#include "dtmf.h"

@implementation PhoneView

- (BOOL)hasWiFiConnection 
{
    return ([[ISNetworkController sharedInstance] networkType] == 2);
}

-(id)initWithFrame:(struct CGRect)frame
{
  self = [super initWithFrame:frame];
  
  _sip_acc_id = PJSUA_INVALID_ID;
  _sip_call_id = PJSUA_INVALID_ID;
  
  UIImageView *background = [[[UIImageView alloc] 
      initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, 
      frame.size.width,frame.size.height-66.0f)] autorelease];
  [background setImage:[[UIImage alloc] 
      initWithContentsOfFile:[[NSBundle mainBundle] 
      pathForResource :@"TEL-background-top" ofType:@"png"
      inDirectory:@"skins"]]];
  [self addSubview:background];

  font = [NSClassFromString(@"WebFontCache") 
         createFontWithFamily:@"Helvetica" 
         traits:2 size:35];
  font2 = [NSClassFromString(@"WebFontCache") 
         createFontWithFamily:@"Helvetica" 
         traits:2 size:20];

  struct __GSFont *btnFont = [NSClassFromString(@"WebFontCache") 
                 createFontWithFamily:@"Helvetica" 
                 traits:2 size:16];

  float fnt[] = {255, 255, 255, 1};
  struct CGColor *fntColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(),fnt);
  float bg[] = {0, 0, 0, 0};
  struct CGColor *bgColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(),bg);
  float bg2[] = {255, 255, 255, 1};
  struct CGColor *bg2Color = CGColorCreate(CGColorSpaceCreateDeviceRGB(),bg2);
  
  lbNumber = [[UITextLabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 65.0f)];
  [lbNumber setCentersHorizontally:TRUE];
  [lbNumber setFont: font2];
  [lbNumber setAlignment: 1]; // Center
  [lbNumber setColor: fntColor];
  [lbNumber setBackgroundColor: bgColor];
  [lbNumber setText: NSLocalizedString(@"Please connect to SIP-Server", 
    @"PhoneView")];

  _pad = [[DialerPhonePad alloc] initWithFrame:
        CGRectMake(0.0f, 74.0f, 320.0f, 273.0f)];
  [_pad setPlaysSounds:TRUE];

  // UIImage* btnAddImage = [UIImage imageNamed:@"skins/TEL-key-Lb.png"];
  imgConnecting = [UIImage imageNamed:@"skins/TEL-key-sip-connecting.png"];
  imgConnected = [UIImage imageNamed:@"skins/TEL-key-sip-connected.png"];
  btnAdd = [[UIPushButton alloc] init];
  [btnAdd setAutosizesToFit: NO];
  [btnAdd setFrame: CGRectMake(1.0f, 346.0f, 105.0f, 68.0f)];
  [btnAdd addTarget:self action:@selector(btnAddPress:) forEvents:1];
  // [btnAdd setTitle: @"Connect"];
  [btnAdd setTitleColor: bg2Color forState:0];
  [btnAdd setTitleColor: bg2Color forState:1];
  [btnAdd setTitleFont: btnFont];
  [btnAdd setDrawContentsCentered: YES];
  [btnAdd setImage:nil forState:0];


  // UIImage* btnCallImage = [UIImage imageNamed:@"skins/TEL-key-CALL.png"];
  imgAnswer = [UIImage imageNamed:@"skins/TEL-key-tel-answer.png"];
  imgHangup = [UIImage imageNamed:@"skins/TEL-key-tel-hangup.png"];
  btnCallHangup = [[UIPushButton alloc] init];
  [btnCallHangup setAutosizesToFit: NO];
  [btnCallHangup setFrame: CGRectMake(107.0f, 346.0f, 105.0f, 68.0f)];
  [btnCallHangup addTarget:self action:@selector(btnCallHangupPress:) forEvents:1];
  [btnCallHangup setImage:nil forState:0];
  // [btnCallHangup setTitle: @"Dial"];
  [btnCallHangup setTitleColor: bg2Color forState:0];
  [btnCallHangup setTitleColor: bg2Color forState:1];
  [btnCallHangup setTitleFont: btnFont];
  [btnCallHangup setDrawContentsCentered: YES];

  UIImage* btnDelImage = [UIImage imageNamed:@"skins/TEL-key-Rb.png"];
  btnDel = [[UIPushButton alloc] init];
  [btnDel setAutosizesToFit: NO];
  [btnDel setFrame: CGRectMake(213.0f, 346.0f, 105.0f, 68.0f)];
  [btnDel addTarget:self action:@selector(btnDelPress:) forEvents:1];
  [btnDel setImage:btnDelImage forState:1];
  [btnDel setEnabled: NO];

  incomming = [[UIAlertSheet alloc] initWithFrame:CGRectMake(20.0f, 50.0f, 280.0f, 200.0f)];
  [incomming setTitle:@"Incomming Call"];
  [incomming addButtonWithTitle:@"Answer"];
  [incomming addButtonWithTitle:@"Reject"];
  [incomming setDelegate:self];

  [self addSubview: lbNumber];

  [self addSubview: _pad];
  
  [self addSubview: btnAdd];
  [self addSubview: btnCallHangup];
  [self addSubview: btnDel];
  connected = NO;
  [btnCallHangup setEnabled: NO];
  
  return self;
}

- (void)closeConn
{
  if (_sip_acc_id != PJSUA_INVALID_ID)
  {
    sip_disconnect(&_sip_acc_id);
  }
}

- (void)alertSheet:(UIAlertSheet*)sheet buttonClicked:(int)button
{
  if(button == 1)
  {
    sip_answer(&_sip_call_id);
    [btnCallHangup setImage:imgHangup forState:0];
  }
  else
  {
    sip_hangup(&_sip_call_id);
    [lbNumber setText:@""];
    [lbNumber setFont:font];
    [btnCallHangup setImage:nil forState:0];
  }
  [sheet dismiss];
}

/*** ***/
- (void)phonePad:(TPPhonePad *)phonepad appendString:(NSString *)string
{
  NSString *curText = [lbNumber text];
  [lbNumber setText: [curText stringByAppendingString: string]];
  
  /* DTMF */
  if (_sip_call_id != PJSUA_INVALID_ID)
  {
    const char *sd = [string UTF8String];
    if (sd && strlen(sd) > 0)
    {
      sip_call_play_digit(_sip_call_id, sd[0]);
    }
  }
  
}

- (void)btnAddPress:(UIPushButton*)btn
{
  // if([btnAdd title] == @"Connect"){
  if([btnAdd currentImage] == nil){
#if 0 // Manage edge    
    if ([self hasWiFiConnection] == FALSE)
    {
        UIAlertSheet * zSheet;
    
    zSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0,240,320,240)];
    [zSheet setTitle:@"Infomation"];
    [zSheet setBodyText: @"\nWi-Fi unavailable\n\n"];
    [zSheet setRunsModal: true]; 
    [zSheet popupAlertAnimated:YES]; //Displays
              //Pauses here until user taps the sheet closed
        return;
    }
#endif    
    if (sip_startup())
    {
      return;
    }
NSLog(@"edge %d", [[NSUserDefaults standardUserDefaults] boolForKey: @"siphonOverEDGE"]);
NSLog(@"nat %d", [[NSUserDefaults standardUserDefaults] boolForKey: @"sip_nat"]);
NSLog(@"stun domain %@", [[NSUserDefaults standardUserDefaults] stringForKey: @"sip_stunDomain"]);
NSLog(@"stun server %@", [[NSUserDefaults standardUserDefaults] stringForKey: @"sip_stunServer"]);

    if (sip_connect(&_sip_acc_id))
    { 
      UIAlertSheet * zSheet;
    
      zSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0,240,320,240)];
      [zSheet setTitle:@"Error"];
      [zSheet setBodyText: @"\nConnection error\nVerify your account parameters\n\n"];
      [zSheet setRunsModal: true]; //I'm a big fan of running sheet modally
      [zSheet popupAlertAnimated:YES];
      
      return ;
    }
    
    [btnAdd setImage:imgConnecting forState:0];
   
    [btnAdd setImage:imgConnected forState:0];

    [_pad setDelegate:self];
  
    [btnDel setEnabled: YES];
    [btnCallHangup setEnabled: YES];
    [lbNumber setText:@""];
    [lbNumber setFont:font];
    [lbNumber setTextAutoresizesToFit:YES];
  }
  else
  {  
    if (_sip_acc_id != PJSUA_INVALID_ID)
    {
      sip_disconnect(&_sip_acc_id);
      sip_cleanup();
    }

    [btnAdd setImage:nil forState:0];

    [_pad setDelegate:nil];
    
    [btnDel setEnabled: NO];
    [btnCallHangup setEnabled: NO];

    [lbNumber setFont:font2];
    [lbNumber setTextAutoresizesToFit:NO];
    [lbNumber setText:NSLocalizedString(@"Please connect to SIP-Server", 
      @"PhoneView")];
  }
}

- (void)btnCallHangupPress:(UIPushButton*)btn
{
  if([btnCallHangup currentImage] == nil && [[lbNumber text] length] > 1)
  {
    [btnCallHangup setImage:imgHangup forState:0];
    if (sip_dial(_sip_acc_id, [[lbNumber text] UTF8String], &_sip_call_id))
      {
        [btnCallHangup setImage:nil forState:0];
        [lbNumber setText:@""];
      }
  }
  else if([btnCallHangup currentImage] == imgAnswer)
  {
    sip_answer(&_sip_call_id);
  }
  else
  {
    sip_hangup(&_sip_call_id);
    [btnCallHangup setImage:nil forState:0];
    [lbNumber setText:@""];
    [lbNumber setFont: font];
  }
}

- (void)btnDelPress:(UIPushButton*)btn
{
  NSString *curText = [lbNumber text];
  if([curText length] > 0)
  {
    [lbNumber setText: [curText substringToIndex:([curText length]-1)]];
  }
}

@end

