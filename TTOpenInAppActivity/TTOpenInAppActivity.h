//
//  TTOpenInAppActivity.h
//
//  Created by Tobias Tiemerding on 12/25/12.
//  Copyright (c) 2012-2013 Tobias Tiemerding
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <UIKit/UIKit.h>

@class TTOpenInAppActivity;

@protocol TTOpenInAppActivityDelegate <NSObject>
@optional
- (void)openInAppActivityWillPresentMenu:(TTOpenInAppActivity*)activity;
- (void)openInAppActivityDidDismissMenu:(TTOpenInAppActivity*)activity;
@end

@interface TTOpenInAppActivity : UIActivity <UIDocumentInteractionControllerDelegate>

@property (nonatomic, weak) id superViewController;

// If a UIImage is supplied, this defines the file name to use when saving the temporary image
// (Default: "export.png"). If the name specifies a JPEG file, the image is saved as JPEG with
// best quality. Else it is saved as PNG.
// The image is stored in the app's caches directory, and deleted when the action completes.
@property (nonatomic, strong) NSString* temporaryImageFileName;

@property (nonatomic, weak) id<TTOpenInAppActivityDelegate> delegate;

- (id)initWithView:(UIView *)view andRect:(CGRect)rect;
- (id)initWithView:(UIView *)view andBarButtonItem:(UIBarButtonItem *)barButtonItem;

- (void)dismissMenuAnimated:(BOOL)animated;

@end
