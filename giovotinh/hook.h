#import "Foundation/Foundation.h"
#import "../Macros.h"

// Flag active
bool isActiveCoin = false;
bool isActiveStar = false;

// Store value
void *instanceInventory = nullptr;
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
    instanceInventory = inventory;
    _Royal_Scenes_Home_Ui_Sections_Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge(self, inventory, method);
}

void applyMod()
{
    if (isActiveCoin)
    {
        *(uint32_t *)((uintptr_t)instanceInventory + 0x10) = coins;
        uint64_t updateCoins = getRealOffset(ENCRYPTOFFSET("0x006A05D4"));
        ((void (*)(void *, int32_t, void *))updateCoins)(instanceInventory, coins, nullptr);
    }
    if (isActiveStar)
    {
        *(uint32_t *)((uintptr_t)instanceInventory + 0x14) = stars;
        uint64_t updateStars = getRealOffset(ENCRYPTOFFSET("0x006A03E4"));
        ((void (*)(void *, int32_t, void *))updateStars)(instanceInventory, stars, nullptr);
    }
}