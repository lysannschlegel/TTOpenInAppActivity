//
//  TTOpenInAppActivity.m
//
//  Created by Tobias Tiemerding on 12/25/12.
//  Copyright (c) 2012-2013 Tobias Tiemerding
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TTOpenInAppActivity.h"
#import <MobileCoreServices/MobileCoreServices.h> // For UTI
#import <Foundation/NSPathUtilities.h>

@interface TTOpenInAppActivity ()
    // Private attributes
    @property (nonatomic, strong) NSURL *fileURL;
    @property (nonatomic, assign) BOOL isTemporary;
    @property (atomic) CGRect rect;
    @property (nonatomic, strong) UIBarButtonItem *barButtonItem;
    @property (nonatomic, strong) UIView *superView;
    @property (nonatomic, strong) UIDocumentInteractionController *docController;

    // Private methods
    - (NSString *)UTIForURL:(NSURL *)url;
    - (void)openDocumentInteractionController;

    - (void)deleteTemporaryImage;

@end

@implementation TTOpenInAppActivity
@synthesize rect = _rect;
@synthesize superView = _superView;
@synthesize superViewController = _superViewController;

- (id)initWithView:(UIView *)view andRect:(CGRect)rect
{
    if(self =[super init]){
        self.superView = view;
        self.rect = rect;
        self.temporaryImageFileName = @"export.png";
    }
    return self;
}

- (id)initWithView:(UIView *)view andBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    if(self =[super init]){
        self.superView = view;
        self.barButtonItem = barButtonItem;
        self.temporaryImageFileName = @"export.png";
    }
    return self;
}

- (void)dealloc {
    [self deleteTemporaryImage];
}

- (NSString *)activityType
{
	return NSStringFromClass([self class]);
}

- (NSString *)activityTitle
{
	return NSLocalizedString(@"Open in ...", @"Open in ...");
}

- (UIImage *)activityImage
{
	if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
        return [UIImage imageNamed:@"TTOpenInAppActivity7"];
    else
        return [UIImage imageNamed:@"TTOpenInAppActivity"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]] || [activityItem isKindOfClass:[UIImage class]]) {
			return YES;
		}
	}
	
	return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]]) {
			self.fileURL = activityItem;
			self.isTemporary = NO;
			break;
		} else if([activityItem isKindOfClass:[UIImage class]]) {
			// get file name for saving
			NSString* temporaryDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
			NSURL* tempURL = [NSURL fileURLWithPathComponents:@[temporaryDirectory, self.temporaryImageFileName]];
			
			// save the image to the temporary location
			NSData *imageData = nil;
			if([[self UTIForURL:tempURL] isEqual:@"public.jpeg"]) {
				imageData = UIImageJPEGRepresentation(activityItem, 1);
			} else {
				imageData = UIImagePNGRepresentation(activityItem);
			}
			if([imageData writeToURL:tempURL atomically:NO]) {
				self.fileURL = tempURL;
				self.isTemporary = YES;
				break;
			} else {
				NSLog(@"Error: failed to save temporary image to open in other app.");
			}
		}
	}
}

- (void)performActivity
{
    if(!self.superViewController){
        [self activityDidFinish:YES];
        return;
    }

    // Dismiss activity view
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
        // iPhone dismiss UIActivityViewController
        [self.superViewController dismissViewControllerAnimated:YES completion:^(void){
            // Open UIDocumentInteractionController
            [self openDocumentInteractionController];
        }];
    } else {
        [self.superViewController dismissPopoverAnimated:YES];
        [((UIPopoverController *)self.superViewController).delegate popoverControllerDidDismissPopover:self.superViewController];
        // Open UIDocumentInteractionController
        [self openDocumentInteractionController];
    }
}

#pragma mark - Helper
- (NSString *)UTIForURL:(NSURL *)url
{
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)url.pathExtension, NULL);
    return (NSString *) CFBridgingRelease(UTI);
}

- (void)openDocumentInteractionController
{
    // Open "Open in"-menu
    self.docController = [UIDocumentInteractionController interactionControllerWithURL:self.fileURL];
    self.docController.delegate = self;
    self.docController.UTI = [self UTIForURL:self.fileURL];
    BOOL sucess; // Sucess is true if it was possible to open the controller and there are apps available
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
        sucess = [self.docController presentOpenInMenuFromRect:CGRectZero inView:self.superView animated:YES];
    } else {
        if(self.barButtonItem)
            sucess = [self.docController presentOpenInMenuFromBarButtonItem:self.barButtonItem animated:YES];
        else
            sucess = [self.docController presentOpenInMenuFromRect:self.rect inView:self.superView animated:YES];
    }
    
    if(!sucess){
        // There is no app to handle this file
        NSString* message = NSLocalizedString(@"Your {devicemodel} doesn't have any apps that can open this document",
                                              @"message indicating no apps were found that can open the document. {devicemodel} is replaced by the device name/kind and {devicename} is replaced by the user-specified name of the device, as in Bob's iPad.");
        message = [message stringByReplacingOccurrencesOfString:@"{devicemodel}" withString:[UIDevice currentDevice].localizedModel];
        message = [message stringByReplacingOccurrencesOfString:@"{devicename}" withString:[UIDevice currentDevice].name];
        
        // Display alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Suitable Apps Installed", @"title for alert indicating that no apps were found that can open the given document")
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"ok")
                                              otherButtonTitles:nil];
        [alert show];
        
        // Inform app that the activity has finished
        // Return NO because the service was canceled and did not finish because of an error.
        // http://developer.apple.com/library/ios/#documentation/uikit/reference/UIActivity_Class/Reference/Reference.html
        [self activityDidFinish:NO];
    }
}

- (void)dismissMenuAnimated:(BOOL)animated {
    // delete temp image
    [self deleteTemporaryImage];
    
    // hide menu
    [self.docController dismissMenuAnimated:animated];
    
    // Inform app that the activity has finished
    [self activityDidFinish:NO];
}

- (void)deleteTemporaryImage {
    if(self.isTemporary && self.fileURL) {
		NSError *error;
		if (![[NSFileManager defaultManager] removeItemAtURL:self.fileURL error:&error]) {
			NSLog(@"Error removing temporary file at path %@: %@", self.fileURL, error.description);
		}
		self.fileURL = nil;
		self.isTemporary = NO;
	}
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void) documentInteractionControllerWillPresentOpenInMenu:(UIDocumentInteractionController *)controller {
    // inform delegate
    if([self.delegate respondsToSelector:@selector(openInAppActivityWillPresentMenu:)]) {
        [self.delegate openInAppActivityWillPresentMenu:self];
    }
}

- (void) documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController *) controller
{
    // inform delegate
    if([self.delegate respondsToSelector:@selector(openInAppActivityDidDismissMenu:)]) {
        [self.delegate openInAppActivityDidDismissMenu:self];
    }
    
    // delete temp image
	[self deleteTemporaryImage];
    
    // Inform app that the activity has finished
    [self activityDidFinish:YES];
}

@end

