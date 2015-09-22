//
//  CheckoutViewController.m
//  Mobile Buy SDK Advanced Sample
//
//  Created by Shopify.
//  Copyright (c) 2015 Shopify Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "CheckoutViewController.h"
#import "GetCompletionStatusOperation.h"
#import "SummaryItemsTableViewCell.h"
@import Buy;
@import PassKit;
@import SafariServices;

NSString * const CheckoutCallbackNotification = @"CheckoutCallbackNotification";
NSString * const MerchantId = @"";

@interface CheckoutViewController () <GetCompletionStatusOperationDelegate, SFSafariViewControllerDelegate>

@property (nonatomic, strong) BUYCheckout *checkout;
@property (nonatomic, strong) BUYClient *client;
@property (nonatomic, strong) NSArray *summaryItems;
@property (nonatomic, strong) BUYApplePayHelpers *applePayHelper;

@end

@implementation CheckoutViewController

- (instancetype)initWithClient:(BUYClient *)client checkout:(BUYCheckout *)checkout;
{
    NSParameterAssert(client);
    NSParameterAssert(checkout);
    
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        self.checkout = checkout;
        self.client = client;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Checkout";
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 164)];
    
    UIButton *creditCardButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [creditCardButton setTitle:@"Checkout with Credit Card" forState:UIControlStateNormal];
    creditCardButton.backgroundColor = [UIColor colorWithRed:0.48f green:0.71f blue:0.36f alpha:1.0f];
    creditCardButton.layer.cornerRadius = 6;
    [creditCardButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    creditCardButton.translatesAutoresizingMaskIntoConstraints = NO;
    [creditCardButton addTarget:self action:@selector(checkoutWithCreditCard) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:creditCardButton];
    
    UIButton *webCheckoutButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [webCheckoutButton setTitle:@"Web Checkout" forState:UIControlStateNormal];
    webCheckoutButton.backgroundColor = [UIColor colorWithRed:0.48f green:0.71f blue:0.36f alpha:1.0f];
    webCheckoutButton.layer.cornerRadius = 6;
    [webCheckoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    webCheckoutButton.translatesAutoresizingMaskIntoConstraints = NO;
    [webCheckoutButton addTarget:self action:@selector(checkoutOnWeb) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:webCheckoutButton];
    
    UIButton *applePayButton = [BUYPaymentButton buttonWithType:BUYPaymentButtonTypeBuy style:BUYPaymentButtonStyleBlack];
    applePayButton.translatesAutoresizingMaskIntoConstraints = NO;
    [applePayButton addTarget:self action:@selector(checkoutWithApplePay) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:applePayButton];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(creditCardButton, webCheckoutButton, applePayButton);
    [footerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[creditCardButton]-|" options:0 metrics:nil views:views]];
    [footerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[webCheckoutButton]-|" options:0 metrics:nil views:views]];
    [footerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[applePayButton]-|" options:0 metrics:nil views:views]];
    
    [footerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[creditCardButton(44)]-[webCheckoutButton(==creditCardButton)]-[applePayButton(==creditCardButton)]-|" options:0 metrics:nil views:views]];
    
    self.tableView.tableFooterView = footerView;
    
    [self.tableView registerClass:[SummaryItemsTableViewCell class] forCellReuseIdentifier:@"SummaryCell"];
}

- (void)setCheckout:(BUYCheckout *)checkout
{
    _checkout = checkout;
    self.summaryItems = [checkout buy_summaryItems];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.summaryItems count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SummaryCell" forIndexPath:indexPath];
    PKPaymentSummaryItem *summaryItem = self.summaryItems[indexPath.row];
    cell.textLabel.text = summaryItem.label;
    cell.detailTextLabel.text = [self.currencyFormatter stringFromNumber:summaryItem.amount];
    // Only show a line above the last cell
    if (indexPath.row != [self.summaryItems count] - 2) {
        cell.separatorInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, cell.bounds.size.width);
    }
    
    return cell;
}

- (void)addCreditCardToCheckout:(void (^)(BOOL success))callback
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [self.client storeCreditCard:[self creditCard] checkout:self.checkout completion:^(BUYCheckout *checkout, NSString *paymentSessionId, NSError *error) {
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

        if (error == nil && checkout) {
            
            NSLog(@"Successfully added credit card to checkout");
            self.checkout = checkout;
        }
        else {
            NSLog(@"Error applying credit card: %@", error);
        }
        
        callback(error == nil && checkout);
    }];
}

- (BUYCreditCard *)creditCard
{
    BUYCreditCard *creditCard = [[BUYCreditCard alloc] init];
    creditCard.number = @"4242424242424242";
    creditCard.expiryMonth = @"12";
    creditCard.expiryYear = @"20";
    creditCard.cvv = @"123";
    creditCard.nameOnCard = @"Dinosaur Banana";
    
    return creditCard;
}

- (void)showCheckoutConfirmation
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Checkout complete" message:nil preferredStyle:UIAlertControllerStyleAlert];;
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          
                                                          [self.navigationController popToRootViewControllerAnimated:YES];
                                                          
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark Native Checkout

- (void)checkoutWithCreditCard
{
    __weak CheckoutViewController *welf = self;
    
    // First, the credit card must be stored on the checkout
    [self addCreditCardToCheckout:^(BOOL success) {
        
        if (success) {
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

            // Upon successfully adding the credit card to the checkout, complete checkout must be called immediately
            [welf.client completeCheckout:welf.checkout completion:^(BUYCheckout *checkout, NSError *error) {
                
                if (error == nil && checkout) {
                    
                    NSLog(@"Successfully completed checkout");
                    welf.checkout = checkout;
                    
                    GetCompletionStatusOperation *completionOperation = [[GetCompletionStatusOperation alloc] initWithClient:welf.client withCheckout:welf.checkout];
                    completionOperation.delegate = welf;

                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                    [[NSOperationQueue mainQueue] addOperation:completionOperation];
                }
                else {
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    NSLog(@"Error completing checkout: %@", error);
                }
            }];
        }
    }];
}

- (void)operation:(GetCompletionStatusOperation *)operation didReceiveCompletionStatus:(BUYStatus)completionStatus
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    NSLog(@"Successfully got completion status: %lu", (unsigned long)completionStatus);
    
    [self showCheckoutConfirmation];
}

- (void)operation:(GetCompletionStatusOperation *)operation failedToReceiveCompletionStatus:(NSError *)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    NSLog(@"Error getting completion status: %@", error);
}

#pragma mark - Apple Pay Checkout

- (void)checkoutWithApplePay
{
    PKPaymentRequest *request = [self paymentRequest];
    
    PKPaymentAuthorizationViewController *paymentController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
 
    self.applePayHelper = [[BUYApplePayHelpers alloc] initWithClient:self.client checkout:self.checkout];
    paymentController.delegate = self.applePayHelper;
    
    [self presentViewController:paymentController animated:YES completion:nil];
}

- (PKPaymentRequest *)paymentRequest
{
    PKPaymentRequest *paymentRequest = [[PKPaymentRequest alloc] init];
    
    [paymentRequest setMerchantIdentifier:MerchantId];
    [paymentRequest setRequiredBillingAddressFields:PKAddressFieldAll];
    [paymentRequest setRequiredShippingAddressFields:self.checkout.requiresShipping ? PKAddressFieldAll : PKAddressFieldEmail|PKAddressFieldPhone];
    [paymentRequest setSupportedNetworks:@[PKPaymentNetworkVisa, PKPaymentNetworkMasterCard]];
    [paymentRequest setMerchantCapabilities:PKMerchantCapability3DS];
    [paymentRequest setCountryCode:@"US"];
    [paymentRequest setCurrencyCode:@"USD"];
    
    [paymentRequest setPaymentSummaryItems: [self.checkout buy_summaryItems]];

    
    return paymentRequest;
}

# pragma mark - Web checkout

- (void)checkoutOnWeb
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveCallbackURLNotification:) name:CheckoutCallbackNotification object:nil];

    // On iOS 9+ we should use the SafariViewController to display the checkout in-app
    if ([SFSafariViewController class]) {
        
        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:self.checkout.webCheckoutURL];
        safariViewController.delegate = self;
        
        [self presentViewController:safariViewController animated:YES completion:nil];
    }
    else {
        [[UIApplication sharedApplication] openURL:self.checkout.webCheckoutURL];
    }
}

- (void)didReceiveCallbackURLNotification:(NSNotification *)notification
{
    NSURL *url = notification.userInfo[@"url"];
    
    __weak CheckoutViewController *welf = self;

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [self.client getCompletionStatusOfCheckoutURL:url completion:^(BUYStatus status, NSError *error) {
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

        if (error == nil && status == BUYStatusComplete) {
            
            NSLog(@"Successfully completed checkout");
            [welf showCheckoutConfirmation];
        }
        else {
            NSLog(@"Error completing checkout: %@", error);
        }
    }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CheckoutCallbackNotification object:nil];
}
@end
