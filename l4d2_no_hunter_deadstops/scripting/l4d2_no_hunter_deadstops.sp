#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <left4dhooks>

int
    g_iHookid[33];

bool
    g_bGoLunging[33];

DynamicHook
    g_hDynamicHook;

float
    fHunterGroundM2Godframes,
    g_fGodFrameTime[33];

ConVar
    cvarHunterGroundM2Godframes;

public Plugin myinfo = 
{
    name = "L4D2 No Hunter Deadstops",
    author = "Hitomi",
    description = "Self-descriptive",
    version = "1.1",
    url = "https://github.com/cy115/"
};

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("ability_use", Event_AbilityUse);

    cvarHunterGroundM2Godframes = CreateConVar("hunter_ground_m2_godframes", "0.75", "m2 godframes after a hunter lands on the ground", _, true, 0.0, true, 1.0);
    fHunterGroundM2Godframes = cvarHunterGroundM2Godframes.FloatValue;
    cvarHunterGroundM2Godframes.AddChangeHook(OnGodFramesChanged);

    char buffer[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, buffer, sizeof(buffer), "gamedata/l4d2_no_hunter_deadstops.txt");
    if (!FileExists(buffer)) {
        SetFailState("\n==========\nMissing required file: \"%s\".\n==========", buffer);
    }

    GameData hGameData = new GameData("l4d2_no_hunter_deadstops");
    if (!hGameData) {
        SetFailState("Failed to load gamedata file l4d2_no_hunter_deadstops.");
    }

    g_hDynamicHook = DynamicHook.FromConf(hGameData, "CY115::CTerrorPlayer::OnGroundChanged");
    if (!g_hDynamicHook) {
        SetFailState("Failed to create DynamicHook: CY115::CTerrorPlayer::OnGroundChanged.");
    }

    delete hGameData;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsHunter(client)) {
        g_iHookid[client] = g_hDynamicHook.HookEntity(Hook_Post, client, OnHunterLandAfterLunge);
    }
}

void OnGodFramesChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    fHunterGroundM2Godframes = cvarHunterGroundM2Godframes.FloatValue;
}

void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsHunter(client)) {
        return;
    }

    char ability[16];
    event.GetString("ability", ability, sizeof(ability));
    if (StrEqual(ability, "ability_lunge")) {
        g_bGoLunging[client] = true;
    }
}

MRESReturn OnHunterLandAfterLunge(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    if (!IsHunter(pThis)) {
        return MRES_Ignored;
    }

    if (g_bGoLunging[pThis] && !hParams.IsNull(2)) {
        g_fGodFrameTime[pThis] = GetGameTime() + fHunterGroundM2Godframes;
        g_bGoLunging[pThis] = false;
    }

    return MRES_Ignored;
}

public Action L4D_OnShovedBySurvivor(int shover, int shovee, const float vector[3])
{
    return Shove_Handler(shover, shovee);
}

public Action L4D2_OnEntityShoved(int shover, int shovee_ent, int weapon, float vector[3], bool bIsHunterDeadstop)
{
    return Shove_Handler(shover, shovee_ent);
}

Action Shove_Handler(int shover, int shovee)
{
    if (!IsSurvivor(shover) || !IsHunter(shovee)) {
        return Plugin_Continue;
    }
    
    if (HasTarget(shovee)) {
        return Plugin_Continue;
    }
    
    if (IsHunterLunging(shovee) || GetGameTime() < g_fGodFrameTime[shovee]) {
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
} 

bool IsSurvivor(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

bool IsInfected(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3);
}

bool IsHunter(int client) {
    return IsInfected(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 3;
}

bool IsHunterLunging(int client) {
    if (!IsHunter(client)) {
        return false;
    }

    int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
    if (!IsValidEntity(ability)) {
        return false;
    }

    return view_as<bool>(GetEntProp(ability, Prop_Send, "m_isLunging"));
}

bool HasTarget(int hunter) {
    int target = GetEntPropEnt(hunter, Prop_Send, "m_pounceVictim");
    return (IsSurvivor(target) && IsPlayerAlive(target));
}