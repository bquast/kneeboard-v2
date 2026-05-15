#import "AppDelegate.h"

@interface KneeboardViewController : NSViewController <NSTextViewDelegate>
@property (strong) NSTextView *textView;
@property (copy) void (^closePopoverHandler)(void);
@end

@implementation KneeboardViewController

- (void)loadView {
    NSRect frame = NSMakeRect(0, 0, 450, 550);
    NSView *view = [[NSView alloc] initWithFrame:frame];
    
    // Scroll View & Text View
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:frame];
    scrollView.hasVerticalScroller = YES;
    scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    self.textView = [[NSTextView alloc] initWithFrame:scrollView.bounds];
    self.textView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.textView.font = [NSFont systemFontOfSize:14];
    self.textView.textContainerInset = NSMakeSize(12, 12);
    self.textView.allowsUndo = YES;
    self.textView.delegate = self;
    
    // Restore text
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:@"KneeboardText"];
    if (saved) self.textView.string = saved;
    
    scrollView.documentView = self.textView;
    [view addSubview:scrollView];
    
    // Settings Button (added after scroll view so it floats on top)
    NSButton *settingsButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"gearshape.fill" accessibilityDescription:nil] target:self action:@selector(showSettings:)];
    settingsButton.bordered = NO;
    // Position at bottom right
    settingsButton.frame = NSMakeRect(frame.size.width - 32, 8, 24, 24);
    settingsButton.autoresizingMask = NSViewMinXMargin | NSViewMaxYMargin;
    [view addSubview:settingsButton];
    
    self.view = view;
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self.view.window makeFirstResponder:self.textView];
}

- (void)textDidChange:(NSNotification *)notification {
    [[NSUserDefaults standardUserDefaults] setObject:self.textView.string forKey:@"KneeboardText"];
}

- (void)showSettings:(id)sender {
    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"Quit Kneeboard" action:@selector(terminate:) keyEquivalent:@"q"];
    [NSMenu popUpContextMenu:menu withEvent:[NSApp currentEvent] forView:sender];
}

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(insertNewline:) && ([[NSApp currentEvent] modifierFlags] & NSEventModifierFlagCommand)) {
        if (self.closePopoverHandler) self.closePopoverHandler();
        return YES;
    }
    return NO;
}
@end


@interface AppDelegate ()
@property (strong) NSStatusItem *statusItem;
@property (strong) NSPopover *popover;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.image = [NSImage imageWithSystemSymbolName:@"square.and.pencil" accessibilityDescription:@"Kneeboard"];
    self.statusItem.button.target = self;
    self.statusItem.button.action = @selector(togglePopover:);
    
    // Set up invisible main menu for keyboard shortcuts (Copy, Paste, Undo, etc.)
    NSMenu *mainMenu = [[NSMenu alloc] init];
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenuItem setSubmenu:editMenu];
    [mainMenu addItem:editMenuItem];
    
    [editMenu addItemWithTitle:@"Undo" action:NSSelectorFromString(@"undo:") keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Redo" action:NSSelectorFromString(@"redo:") keyEquivalent:@"Z"];
    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    
    [NSApp setMainMenu:mainMenu];
    
    KneeboardViewController *vc = [[KneeboardViewController alloc] init];
    __weak typeof(self) weakSelf = self;
    vc.closePopoverHandler = ^{
        [weakSelf.popover performClose:nil];
    };
    
    self.popover = [[NSPopover alloc] init];
    self.popover.contentViewController = vc;
    self.popover.behavior = NSPopoverBehaviorTransient;
}

- (void)togglePopover:(id)sender {
    if (self.popover.isShown) {
        [self.popover performClose:sender];
    } else {
        [self.popover showRelativeToRect:self.statusItem.button.bounds ofView:self.statusItem.button preferredEdge:NSMinYEdge];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end
