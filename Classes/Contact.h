//
//  Contact.h
//  Glucose
//
//  Created by Brandon Fosdick on 11/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface Contact : NSObject
{
	ABRecordID				recordID;		// Address book record ID
	ABMultiValueIdentifier	emailID;		// ID of the selected email address
}

@property (nonatomic, assign) ABRecordID	recordID;
@property (nonatomic, assign) ABMultiValueIdentifier	emailID;

- (id)initWithRecordID:(ABRecordID)record emailID:(ABMultiValueIdentifier)email;

@end
