//
//  Contact.m
//  Glucose
//
//  Created by Brandon Fosdick on 11/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Contact.h"


@implementation Contact

@synthesize recordID, emailID;

- (id)initWithRecordID:(ABRecordID)record emailID:(ABMultiValueIdentifier)email
{
	if( self = [self init] )
	{
		emailID = email;
		recordID = record;
	}
    return self;
}

@end
