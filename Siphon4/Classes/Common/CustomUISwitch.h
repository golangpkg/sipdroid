/**
 *  Siphon SIP-VoIP for iPhone and iPod Touch
 *  Copyright (C) 2011 Samuel <samuelv0304@gmail.com>
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


@interface CustomUISwitch : UIControl
{
@private
	BOOL on_;
	UIImageView *bgView_;
}

@property(nonatomic, getter=isOn) BOOL on;

// Overrides initWithFrame: and enforces a size appropriate for the control.
- (id)initWithFrame:(CGRect)frame;

// Set the state of the switch to On or Off, optionally animating the transition.
- (void)setOn:(BOOL)on animated:(BOOL)animated;

- (void)setAlternateColors:(BOOL)alternate;

@end
