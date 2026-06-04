#import "../Macros.h"
#import "Foundation/Foundation.h"
#import "define.h"

// Flag active
bool isActiveCoin = false;
bool isActiveStar = false;
bool isActiveMove = false;
bool isMoveApplied = false;

// Store value
void *instanceInventory = nullptr;
void *moveManager = nullptr;
int coins = 0;
int stars = 0;
int moves = 0;

// Store field offset
uintptr_t coinOffset = 0;
uintptr_t starOffset = 0;
uintptr_t moveOffset = 0;

// Store function offset
uint64_t Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge_Offset = 0;
uint64_t Game_Levels_Units_MoveManager__SetMaxMoves_Offset = 0;
uint64_t Game_Levels_Units_MoveManager__SetMovesForStart_Offset = 0;
void (*updateCoins)(void *, int32_t, void *);
bool (*spendCoins)(void *, Royal_Player_Context_Data_Session_SpendingData_o,
                   void *, int32_t, void *);
void (*updateStars)(void *, int32_t, void *);
void (*triggerMoveChanged)(void *, int32_t, void *);

// ==================================================================================

void (
    *_Royal_Scenes_Home_Ui_Sections_Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge)(
    void *self, void *inventory, void *method);
void Royal_Scenes_Home_Ui_Sections_Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge(
    void *self, void *inventory, void *method) {
    instanceInventory = inventory;
    _Royal_Scenes_Home_Ui_Sections_Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge(
        self, inventory, method);
}

void (*_Royal_Scenes_Game_Levels_Units_MoveManager__SetMaxMoves)(void *self,
                                                                 int32_t moves,
                                                                 void *method);
void Royal_Scenes_Game_Levels_Units_MoveManager__SetMaxMoves(void *self,
                                                             int32_t moves,
                                                             void *method) {
    moveManager = self;
    _Royal_Scenes_Game_Levels_Units_MoveManager__SetMaxMoves(self, moves,
                                                             method);
}

void (*_Royal_Scenes_Game_Levels_Units_MoveManager__SetMovesForStart)(
    void *self, int32_t maxMoves, int32_t leftMoves, int32_t madeMoves,
    void *method);
void Royal_Scenes_Game_Levels_Units_MoveManager__SetMovesForStart(
    void *self, int32_t maxMoves, int32_t leftMoves, int32_t madeMoves,
    void *method) {
    moveManager = self;
    if (isMoveApplied && isActiveMove) {
        maxMoves = moves;
        leftMoves = moves;
        madeMoves = 0;
    }
    _Royal_Scenes_Game_Levels_Units_MoveManager__SetMovesForStart(
        self, maxMoves, leftMoves, madeMoves, method);
}

void applyMod() {
    if (isActiveCoin) {
        if (instanceInventory == nullptr)
            goto step_active_star;

        *(uint32_t *)((uintptr_t)instanceInventory + coinOffset) = coins;
        updateCoins(instanceInventory, coins, nullptr);

        Royal_Player_Context_Data_Session_SpendingData_o spendingData;
        spendingData.fields._CoinAmount_k__BackingField = 0;
        spendingData.fields._SpendingName_k__BackingField =
            (System_String_o *)IL2CPP::il2cpp_string_new(
                ENCRYPT("TriggerSpendCoinToReloadUI"));

        // Call spendCoins to trigger reload coin view
        spendCoins(instanceInventory, spendingData, 0, -1, nullptr);
    }

step_active_star:
    if (isActiveStar) {
        if (instanceInventory == nullptr)
            goto step_active_move;

        *(uint32_t *)((uintptr_t)instanceInventory + starOffset) = stars;
        updateStars(instanceInventory, stars, nullptr);
    }

step_active_move:
    if (isActiveMove) {
        isMoveApplied = true;
        if (moveManager == nullptr)
            return;

        *(uint32_t *)((uintptr_t)moveManager + moveOffset) = moves;
        // Call TriggerMoveChanged to update move in UI
        triggerMoveChanged(moveManager, 0, nullptr);
    }
}
