#import "Foundation/Foundation.h"

// Flag active
bool isActiveCoin = true;
bool isActiveLevel = true;
bool isActiveStar = true;
bool isActiveChest = true;

// Store value
int coins = 999999;
int level = 12500;
int stars = 99999;
int chest = 1000;

struct System_String_o
{
    void *klass;
    void *monitor;
    int32_t length;
    char16_t chars[0];
};

struct MethodInfo
{
    void *methodPointer;
};

int32_t (*_userKeyValue_GetInt)(System_String_o *key, int32_t defaultValue, const MethodInfo *method);

int32_t userKeyValue_GetInt(System_String_o *key, int32_t defaultValue, const MethodInfo *method)
{
    NSString *keyString = [NSString stringWithCharacters:(const unichar *)key->chars length:key->length];
    if ([keyString isEqualToString:@"Coins"] && isActiveCoin)
    {
        return coins;
    }
    if ([keyString isEqualToString:@"Level"] && isActiveLevel)
    {
        return level;
    }
    if ([keyString isEqualToString:@"Stars"] && isActiveStar)
    {
        return stars;
    }
    if ([keyString isEqualToString:@"Chest"] && isActiveChest)
    {
        return chest;
    }

    return _userKeyValue_GetInt(key, defaultValue, method);
}