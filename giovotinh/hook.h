#import "UIKit/UIKit.h"

int (*_get_Coins)(void* self);

int get_Coins(void* self) {
    NSLog(@"[get_Coins] called");

    return _get_Coins(self);
}