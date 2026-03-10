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

// GetInt
int32_t (*_userKeyValue_GetInt)(System_String_o *key, int32_t defaultValue, void *method);
int32_t userKeyValue_GetInt(System_String_o *key, int32_t defaultValue, void *method)
{
    NSString *keyString = [NSString stringWithCharacters:(const unichar *)key->chars length:key->length];
    NSLog(@"Mod GetInt >>> key: %@, defaultValue: %d", keyString, defaultValue);
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

// GetInt with DB
int32_t (*_userKeyValue_GetIntWithDB)(void *db, System_String_o *key, int32_t defaultValue, void *method);
int32_t userKeyValue_GetIntWithDB(void *db, System_String_o *key, int32_t defaultValue, void *method)
{
    NSString *keyString = [NSString stringWithCharacters:(const unichar *)key->chars length:key->length];
    NSLog(@"Mod GetInt db >>> key: %@, defaultValue: %d", keyString, defaultValue);
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

    return _userKeyValue_GetIntWithDB(db, key, defaultValue, method);
}

// SetInt
bool (*_userKeyValue_SetInt)(System_String_o *key, int32_t value, void *method);
bool userKeyValue_SetInt(System_String_o *key, int32_t value, void *method)
{
    NSString *keyString = [NSString stringWithCharacters:(const unichar *)key->chars length:key->length];
    NSLog(@"Mod SetInt >>> key: %@, value: %d", keyString, value);

    return _userKeyValue_SetInt(key, value, method);
}

// SetInt with DB
bool (*_userKeyValue_SetIntWithDB)(void *db, System_String_o *key, int32_t value, void *method);
bool userKeyValue_SetIntWithDB(void *db, System_String_o *key, int32_t value, void *method)
{
    NSString *keyString = [NSString stringWithCharacters:(const unichar *)key->chars length:key->length];
    NSLog(@"Mod SetInt db >>> key: %@, value: %d", keyString, value);

    return _userKeyValue_SetIntWithDB(db, key, value, method);
}

// ================================================================================= //

// GetLong
int64_t (*_userKeyValue_GetLong)(System_String_o *key, int64_t defaultValue, void *method);
int64_t userKeyValue_GetLong(System_String_o *key, int64_t defaultValue, void *method)
{
    NSString *keyString = [NSString stringWithCharacters:(const unichar *)key->chars length:key->length];
    NSLog(@"Mod GetLong >>> key: %@, defaultValue: %lld", keyString, defaultValue);
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

    return _userKeyValue_GetLong(key, defaultValue, method);
}

// GetLong with DB
int64_t (*_userKeyValue_GetLongWithDB)(void *db, System_String_o *key, int64_t defaultValue, void *method);
int64_t userKeyValue_GetLongWithDB(void *db, System_String_o *key, int64_t defaultValue, void *method)
{
    NSString *keyString = [NSString stringWithCharacters:(const unichar *)key->chars length:key->length];
    NSLog(@"Mod GetLong db >>> key: %@, defaultValue: %lld", keyString, defaultValue);
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

    return _userKeyValue_GetLongWithDB(db, key, defaultValue, method);
}

// SetLong
bool (*_userKeyValue_SetLong)(System_String_o *key, int64_t value, void *method);
bool userKeyValue_SetLong(System_String_o *key, int64_t value, void *method)
{
    NSString *keyString = [NSString stringWithCharacters:(const unichar *)key->chars length:key->length];
    NSLog(@"Mod SetLong >>> key: %@, value: %lld", keyString, value);

    return _userKeyValue_SetLong(key, value, method);
}

// SetLong with DB
bool (*_userKeyValue_SetLongWithDB)(void *db, System_String_o *key, int64_t value, void *method);
bool userKeyValue_SetLongWithDB(void *db, System_String_o *key, int64_t value, void *method)
{
    NSString *keyString = [NSString stringWithCharacters:(const unichar *)key->chars length:key->length];
    NSLog(@"Mod SetLong db >>> key: %@, value: %lld", keyString, value);

    return _userKeyValue_SetLongWithDB(db, key, value, method);
}
