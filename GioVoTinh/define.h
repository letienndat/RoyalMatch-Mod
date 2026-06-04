//
//  define.h
//  LienQuanVNMod
//
//  Created by Le Tien Dat on 5/18/26.
//

struct System_String_o;

struct Royal_Player_Context_Data_Session_SpendingData_Fields {
    int32_t _CoinAmount_k__BackingField;
    int32_t paddingByte; // padding 4 bytes
    struct System_String_o *_SpendingName_k__BackingField;
};

struct Royal_Player_Context_Data_Session_SpendingData_o {
    Royal_Player_Context_Data_Session_SpendingData_Fields fields;
};
