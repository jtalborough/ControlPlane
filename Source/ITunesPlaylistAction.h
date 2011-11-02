//
//	ITunesPlaylistAction.h
//	ControlPlane
//
//	Created by David Jennes on 03/09/11.
//	Copyright 2011. All rights reserved.
//

#import "CAction.h"


@interface ITunesPlaylistAction : CAction <ActionWithLimitedOptions> {
	NSString *playlist;
}

- (id) initWithDictionary: (NSDictionary *) dict;
- (void) dealloc;
- (NSMutableDictionary *) dictionary;

- (NSString *) description;
- (BOOL) execute: (NSString **) errorString;
+ (NSString *) helpText;
+ (NSString *) creationHelpText;

+ (NSArray *) limitedOptions;
- (id) initWithOption: (NSString *) option;

@end