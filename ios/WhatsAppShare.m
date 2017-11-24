//
//  FacebookShare.m
//  RNShare
//
//  Created by Diseño Uno BBCL on 23-07-16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "WhatsAppShare.h"

@implementation WhatsAppShare
static UIDocumentInteractionController *documentInteractionController;

- (void)shareSingle:(NSDictionary *)options
    failureCallback:(RCTResponseErrorBlock)failureCallback
    successCallback:(RCTResponseSenderBlock)successCallback {

    NSLog(@"Try open view");

    if ([options objectForKey:@"message"] && [options objectForKey:@"message"] != [NSNull null]) {
        NSString *text = [RCTConvert NSString:options[@"message"]];
        text = [text stringByAppendingString: [@" " stringByAppendingString: options[@"url"]] ];

        if ([[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString:@"whatsapp://app"]]) {
            NSLog(@"WhatsApp installed");
        } else {
            // Cannot open whatsapp
            NSString *stringURL = @"http://itunes.apple.com/app/whatsapp-messenger/id310633997";
            NSURL *url = [NSURL URLWithString:stringURL];
            [[UIApplication sharedApplication] openURL:url];

            NSString *errorMessage = @"Not installed";
            NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedString(errorMessage, nil)};
            NSError *error = [NSError errorWithDomain:@"com.rnshare" code:1 userInfo:userInfo];

            NSLog(errorMessage);
            return failureCallback(error);
        }

        if ([options[@"url"] rangeOfString:@"wam"].location != NSNotFound || [options[@"url"] rangeOfString:@"mp4"].location != NSNotFound) {
            NSLog(@"Sending whatsapp movie");
            NSURL *tempFile = [self createTempFile:options[@"url"] type:@"whatsAppTmp.wam"];
            documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:tempFile];
            documentInteractionController.UTI = @"net.whatsapp.movie";
            documentInteractionController.delegate = self;

            [documentInteractionController presentOpenInMenuFromRect:CGRectMake(0, 0, 0, 0) inView:[[[[[UIApplication sharedApplication] delegate] window] rootViewController] view] animated:YES];
            NSLog(@"Done whatsapp movie");
            successCallback(@[]);
        } else if ([options[@"url"] rangeOfString:@"wai"].location != NSNotFound) {
            NSLog(@"Sending whatsapp image");
            NSURL *tempFile = [self createTempFile:options[@"url"] type:@"whatsAppTmp.wai"];
            documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:tempFile];
            documentInteractionController.UTI = @"net.whatsapp.image";
            documentInteractionController.delegate = (id)self;

            [documentInteractionController presentOpenInMenuFromRect:CGRectMake(0, 0, 0, 0) inView:[[[[[UIApplication sharedApplication] delegate] window] rootViewController] view] animated:YES];
            NSLog(@"Done whatsapp image");
            successCallback(@[]);
        } else {
            text = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef) text, NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
            
            NSString * urlWhats = [NSString stringWithFormat:@"whatsapp://send?text=%@", text];
            NSURL * whatsappURL = [NSURL URLWithString:urlWhats];
    
            if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
                [[UIApplication sharedApplication] openURL: whatsappURL];
                successCallback(@[]);
            }
        }
    }
}

#pragma mark - Helpers
- (NSURL *)createTempFile:(NSString *)path type:(NSString *)type
{
    NSData *data = [[NSData alloc]initWithContentsOfFile:path];
	NSError *error = nil;
	NSURL *tempFile = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
															 inDomain:NSUserDomainMask
													appropriateForURL:nil
															   create:YES
																error:&error];

	if (tempFile && !error) {
		tempFile = [tempFile URLByAppendingPathComponent:type];
	} else {
		[self alertError:[NSString stringWithFormat:@"Error getting document directory: %@", error]];
	}
	
	if (![data writeToFile:tempFile.path options:NSDataWritingAtomic error:&error]) {
		[self alertError:[NSString stringWithFormat:@"Error writing File: %@", error]];
	}

	return tempFile;
}

- (void)alertWithTitle:(NSString *)title message:(NSString *)message
{
	UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
																   message:message
															preferredStyle:UIAlertControllerStyleAlert];
	
	[alert addAction:[UIAlertAction actionWithTitle:@"OK"
										   style:UIAlertActionStyleCancel
										 handler:^(UIAlertAction *action) {
											 
		 [vc dismissViewControllerAnimated:YES completion:^{}];
	 }]];
	
	[vc presentViewController:alert animated:YES completion:nil];
}

- (void)alertError:(NSString *)message
{
	[self alertWithTitle:@"Error" message:message];
}

@end
