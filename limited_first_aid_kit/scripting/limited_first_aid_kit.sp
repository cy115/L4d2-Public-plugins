#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_PREFIX "[{olive}医疗包限制{default}] "

int
    g_iUseKits,
    g_iMaxKits,
    g_iPlayersPerKit,
    g_iChanceToDefib;

bool
    g_bEnabled,
    g_bHadAnyOneLeaveStartArea;

public Plugin myinfo =
{
    name = "L4D2 Limited First Aid Kit",
    author = "Hitomi",
    description = "基于玩家的人数来限制医疗包使用",
    version = "1.0",
    url = "https://github.com/cy115/"
};

public void OnPluginStart()
{
    CreateConVarHook("l4d2_lfak_enable", "1", "启用医疗包的限制插件", _, true, 0.0, true, 1.0, OnEnableChanged);
    CreateConVarHook("l4d2_lfak_players", "4", "每多少名玩家允许多用一个医疗包", _, false, 0.0, false, 0.0, OnPlayersChanged);
    CreateConVarHook("l4d2_lfak_chance", "1", "医疗包转换时生成电击器的概率", _, true, 0.0, true, 100.0, OnChanceChanged);

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("heal_success", Event_HealSuccess);
    HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_PostNoCopy);
}

public Action L4D2_BackpackItem_StartAction(int client, int entity, any type)
{
    if (!g_bEnabled) {
        return Plugin_Continue;
    }

    if (type == 12 && g_iUseKits >= g_iMaxKits) {
        RemovePlayerItem(client, entity);
        if (GetRandomInt(1, 100) < g_iChanceToDefib) {
            GivePlayerItem(client, "weapon_defibrillator");
        } else {
            GivePlayerItem(client, "weapon_pain_pills");
        }

        return Plugin_Handled;
    } else {
        return Plugin_Continue;
    }
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_iUseKits = 0;
    g_bHadAnyOneLeaveStartArea = false;
}

void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnabled) {
        return;
    }

    if (g_bHadAnyOneLeaveStartArea) {
        g_iUseKits++;
        if (g_iUseKits == g_iMaxKits) {
            ConverAllKitsToOthers();
        }

        int client = GetClientOfUserId(event.GetInt("userid"));
        if (!IsValidSurvivor(client)) {
            return;
        }

        CPrintToChatAll("%s {blue}%N {default}使用了一个{olive}医疗包{default}[{blue}%i{default}/{blue}%i{default}]", PLUGIN_PREFIX, client, g_iUseKits, g_iMaxKits);
    }
}

void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
    g_bHadAnyOneLeaveStartArea = true;
    if (g_bEnabled) {
        int iSurCount;
        for (int i = 1; i < 32; i++) {
            if (IsClientInGame(i) && GetClientTeam(i) == 2) {
                iSurCount++;
            }
        }

        g_iMaxKits = iSurCount / g_iPlayersPerKit;
    }
}

void ConverAllKitsToOthers()
{
    int iWeaponIndex;
    char classname[32];
    for (int i = 1; i < 32; i++) {
        if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) {
            continue;
        }

        iWeaponIndex = GetPlayerWeaponSlot(i, 3);
        if (iWeaponIndex < 0) {
            continue;
        }

        GetEntityClassname(iWeaponIndex, classname, sizeof(classname));
        if (!StrEqual(classname, "weapon_first_aid_kit")) {
            continue;
        }

        RemovePlayerItem(i, iWeaponIndex);
        if (GetRandomInt(1, 100) < g_iChanceToDefib) {
            GivePlayerItem(i, "weapon_defibrillator");
        } else {
            GivePlayerItem(i, "weapon_pain_pills");
        }
    }

    float vPos[3];
    int entity = -1, item;
    while ((entity = FindEntityByClassname(entity, "weapon_first_aid_kit_spawn")) != INVALID_ENT_REFERENCE) {
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
        AcceptEntityInput(entity, "kill");
        item = CreateEntityByName("weapon_pain_pills_spawn");
        if (item) {
            TeleportEntity(item, vPos);
            DispatchSpawn(item);
        }
    }

    entity = -1;
    while ((entity = FindEntityByClassname(entity, "weapon_spawn")) != INVALID_ENT_REFERENCE) {
        if (GetEntProp(entity, Prop_Data, "m_weaponID") == 12) {
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
            AcceptEntityInput(entity, "kill");
            item = CreateEntityByName("weapon_pain_pills_spawn");
            if (item) {
                TeleportEntity(item, vPos);
                DispatchSpawn(item);
            }
        }
    }
}

// ConVars
void OnEnableChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_bEnabled = convar.BoolValue;
}

void OnPlayersChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_iPlayersPerKit = convar.IntValue;
}

void OnChanceChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_iChanceToDefib = convar.IntValue;
}

ConVar CreateConVarHook(const char[] name, const char[] defaultValue, const char[] description = "",
    int flags = 0, bool hasMin = false, float min = 0.0, bool hasMax = false, float max = 0.0, ConVarChanged callback) {
    ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
    
    Call_StartFunction(INVALID_HANDLE, callback);
    Call_PushCell(cv);
    Call_PushNullString();
    Call_PushNullString();
    Call_Finish();
    
    cv.AddChangeHook(callback);
    
    return cv;
}

// tools
bool IsValidSurvivor(int client) {
    return client > 0 && client < 32 && IsClientInGame(client) && GetClientTeam(client) == 2;
}