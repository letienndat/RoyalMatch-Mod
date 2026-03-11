#import "Foundation/Foundation.h"
#import "../Macros.h"

// Flag active
bool isActiveCoin = false;
bool isActiveStar = false;

// Store value
int coins = 0;
int stars = 0;

void (*_Royal_Scenes_Home_Ui_Sections_Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge)(
    void *self,
    void *inventory,
    void *method);
void Royal_Scenes_Home_Ui_Sections_Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge(
    void *self,
    void *inventory,
    void *method)
{
    if (isActiveCoin)
    {
        *(uint32_t *)((uint64_t)inventory + 0x10) = coins;
        uint64_t updateCoins = getRealOffset(ENCRYPTOFFSET("0x006A05D4"));
        ((void (*)(void *, int32_t, void *))updateCoins)(inventory, coins, nullptr);
    }
    if (isActiveStar)
    {
        *(uint32_t *)((uint64_t)inventory + 0x14) = stars;
        uint64_t updateStars = getRealOffset(ENCRYPTOFFSET("0x006A03E4"));
        ((void (*)(void *, int32_t, void *))updateStars)(inventory, stars, nullptr);
    }
    _Royal_Scenes_Home_Ui_Sections_Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge(self, inventory, method);
}

void (*_Royal_Player_Context_Data_Persistent_UserInventory__UpdateCoins)(
    void *self,
    int32_t newCoins,
    void *method);
void Royal_Player_Context_Data_Persistent_UserInventory__UpdateCoins(
    void *self,
    int32_t newCoins,
    void *method)
{
    if (isActiveCoin)
    {
        newCoins = coins;
    }
    _Royal_Player_Context_Data_Persistent_UserInventory__UpdateCoins(self, newCoins, method);
}