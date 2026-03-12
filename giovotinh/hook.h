#import "Foundation/Foundation.h"
#import "../Macros.h"

// Flag active
bool isActiveCoin = false;
bool isActiveStar = false;

// Store value
void *instanceInventory = nullptr;
int coins = 0;
int stars = 0;

// ================================================================================== //

// Define struct
struct System_String_o;
typedef struct System_String_o *(*il2cpp_string_new_type)(const char *str);

struct Royal_Player_Context_Data_Session_SpendingData_Fields
{
    int32_t _CoinAmount_k__BackingField;
    int32_t paddingByte; // padding 4 bytes
    struct System_String_o *_SpendingName_k__BackingField;
};

struct Royal_Player_Context_Data_Session_SpendingData_o
{
    Royal_Player_Context_Data_Session_SpendingData_Fields fields;
};

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

        // Get symbol il2cpp_string_new
        il2cpp_string_new_type il2cpp_string_new = (il2cpp_string_new_type)getSym("il2cpp_string_new");

        Royal_Player_Context_Data_Session_SpendingData_o spendingData;
        spendingData.fields._CoinAmount_k__BackingField = 0;
        spendingData.fields._SpendingName_k__BackingField = il2cpp_string_new("TriggerSpendCoinToReloadUI");

        // Call spendCoins to trigger reload coin view
        uint64_t spendCoins = getRealOffset(ENCRYPTOFFSET("0x006A07BC"));
        ((bool (*)(void *, Royal_Player_Context_Data_Session_SpendingData_o, void *, int32_t, void *))spendCoins)(instanceInventory, spendingData, 0, -1, nullptr);
    }
    if (isActiveStar)
    {
        *(uint32_t *)((uintptr_t)instanceInventory + 0x14) = stars;
        uint64_t updateStars = getRealOffset(ENCRYPTOFFSET("0x006A03E4"));
        ((void (*)(void *, int32_t, void *))updateStars)(instanceInventory, stars, nullptr);
    }
}