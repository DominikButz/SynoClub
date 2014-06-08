//
//  InfoViewController.m
//  SynoClub
//
//  Created by Dominik Butz on 01/06/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController ()
@property (strong, nonatomic) IBOutlet UITextView *instructionsTextView;

@end

@implementation InfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSTextStorage *textStorage = self.instructionsTextView.textStorage;
    
    [textStorage replaceCharactersInRange:NSMakeRange(0, 0) withString:[NSString stringWithContentsOfURL:[NSBundle.mainBundle URLForResource:@"instructions" withExtension:@"txt"] usedEncoding:nil error:NULL]];
    
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textSizeChangedWithNotification:) name:UIContentSizeCategoryDidChangeNotification object:nil] ;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneButtonPressed:(UIBarButtonItem *)sender {
    
    
        [self.delegate didPressDoneButton];
    
    
    
}

-(void)textSizeChangedWithNotification:(NSNotification *) notification {
    
    [_instructionsTextView  setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
