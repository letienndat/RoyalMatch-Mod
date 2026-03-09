#import "Foundation/Foundation.h"

bool isActiveCoin = false;
int coins = 0;

int (*_get_Coins)(void* self);

int get_Coins(void* self) {
    if (isActiveCoin) {
        return coins;
    }
    return _get_Coins(self);
}