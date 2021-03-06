//
//  NetworkLocationAction.m
//  ControlPlane
//
//  Created by David Symonds on 4/07/07.
//  Modified by Vladimir Beloborodov (VladimirTechMan) on 12 June 2013.
//

#import <SystemConfiguration/SCNetworkConfiguration.h>
#import <SystemConfiguration/SCPreferences.h>
#import <SystemConfiguration/SCSchemaDefinitions.h>

#import "NetworkLocationAction.h"


@implementation NetworkLocationAction

#pragma mark Utility methods

+ (NSDictionary *)getAllSets {
	NSDictionary *dict = nil;

    SCPreferencesRef prefs = SCPreferencesCreate(NULL, CFSTR("ControlPlane"), NULL);
	SCPreferencesLock(prefs, true);

	CFDictionaryRef cfDict = (CFDictionaryRef) SCPreferencesGetValue(prefs, kSCPrefSets);
    if (cfDict) {
        dict = [NSDictionary dictionaryWithDictionary:(NSDictionary *) cfDict];
    }

	SCPreferencesUnlock(prefs);
	CFRelease(prefs);

	return dict;
}

#pragma mark -

- (id)initWithOption:(NSString *)option {
	self = [super init];
    if (self) {
        networkLocation = [option copy];
    }
	return self;
}

- (id)init {
	return [self initWithOption:@""];
}

- (id)initWithDictionary:(NSDictionary *)dict {
	return [self initWithOption:dict[@"parameter"]];
}

- (void)dealloc {
	[networkLocation release];

	[super dealloc];
}

- (NSMutableDictionary *)dictionary {
	NSMutableDictionary *dict = [super dictionary];
    dict[@"parameter"] = [[networkLocation copy] autorelease];
	return dict;
}

- (NSString *)description {
	return [NSString stringWithFormat:NSLocalizedString(@"Changing network location to '%@'.", @""),
		networkLocation];
}

- (BOOL)isRequiredNetworkLocationAlreadySet {
	BOOL result = NO;
    
    SCPreferencesRef prefs = SCPreferencesCreate(NULL, CFSTR("ControlPlane"), NULL);
	SCPreferencesLock(prefs, true);
    
    SCNetworkSetRef currentSet = SCNetworkSetCopyCurrent(prefs);
    if (currentSet) {
        result = [(NSString *) SCNetworkSetGetName(currentSet) isEqualToString:networkLocation];
        CFRelease(currentSet);
    }
    
    SCPreferencesUnlock(prefs);
    CFRelease(prefs);
    
    return result;
}

- (BOOL)execute:(NSString **)errorString {
    if ([self isRequiredNetworkLocationAlreadySet]) {
#ifdef DEBUG_MODE
        NSLog(@"Network location is already set to '%@'", networkLocation);
#endif
        return YES;
    }

    __block NSString *networkSetId = nil;

	NSDictionary *allSets = [[self class] getAllSets];
    [allSets enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *subdict, BOOL *stop) {
        if ([networkLocation isEqualToString:subdict[@"UserDefinedName"]]) {
            networkSetId = key;
            *stop = YES;
        }
    }];

	if (!networkSetId) {
		NSString *format = NSLocalizedString(@"No network location named \"%@\" exists!", @"Action error message");
        *errorString = [NSString stringWithFormat:format, networkLocation];
		return NO;
	}

    // Using SCPreferences* to change the location requires a setuid binary,
	// so we just execute /usr/sbin/scselect to do the heavy lifting.
	NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/sbin/scselect" arguments:@[ networkSetId ]];
	[task waitUntilExit];
	if ([task terminationStatus] != 0) {
		*errorString = NSLocalizedString(@"Failed changing network location", @"Action error message");
		return NO;
	}

	return YES;
}

+ (NSString *)helpText {
	return NSLocalizedString(@"The parameter for NetworkLocation actions is the name of the "
				 "network location to select.", @"");
}

+ (NSString *)creationHelpText {
	return NSLocalizedString(@"Changing network location to", @"");
}

+ (NSArray *)limitedOptions {
	NSDictionary *allSets = [[self class] getAllSets];
    NSMutableArray *networkLocationNames = [NSMutableArray arrayWithCapacity:[allSets count]];

    [allSets enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary *set, BOOL *stop) {
		[networkLocationNames addObject:set[@"UserDefinedName"]];
    }];
	[networkLocationNames sortUsingSelector:@selector(localizedCompare:)];

	NSMutableArray *opts = [NSMutableArray arrayWithCapacity:[networkLocationNames count]];
	for (NSString *loc in networkLocationNames) {
		[opts addObject:@{ @"option": loc, @"description": loc }];
    }

	return opts;
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Network Location", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"Networking", @"");
}

@end
