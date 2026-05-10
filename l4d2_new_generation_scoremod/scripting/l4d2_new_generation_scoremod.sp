/*----------------------------------------------
-------------------- Pragma --------------------
----------------------------------------------*/

#pragma semicolon 1
#pragma newdecls required

/*----------------------------------------------
----------------- Include Files ----------------
----------------------------------------------*/

#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <colors>
#include <l4d2lib>
#undef REQUIRE_PLUGIN
#include <l4d2_skill_detect>

/*----------------------------------------------
------------------- Variables ------------------
----------------------------------------------*/

int
    g_iTeamSize,
    g_iMapDistance,
    g_iMapMaxDistance,
    g_iPillsBonus,
    g_iPillWorth;

float
    // variables of bonus
    g_fMapBonus,            // TotalBonus
    // permanent health bonus
    g_fPermHealthBonus,
    g_fPermHealthBonusRate,
    // damage health bonus
    g_fDamageBonus,
    g_fDamageBonusRate,
    // skill bonus
    g_fSkillBonus,
    g_fSkillBonusRate,
    // pills bonus
    g_fPillsBonusRate,
    // Condition bonus
    g_fConditionBonus,
    g_fConditionBonusRate,
    // skill bonus percent
    g_f5Percent,
    g_f10Percent,
    g_f20Percent;

bool
    g_bLateLoad,
    g_bRoundOver;

// Game Cvars
ConVar
    g_hCvarValveTieBreaker,
    g_hCvarValveDefibPenalty,
    g_hCvarValveSurvivalBonus;

enum struct Team {
    int iLostDamageBonus;           // damage bonus lose per round
    int iSiDamage;                  // damage bonus rest

    float fSkillGainBonus;          // skill bonus gain per rond
    float fSurvivorBonus;
    float fSurvivorMainBonus;
    float fSurvivorSkillBonus;

    bool bTiebreakerEligibility;    // tier breaker

    char sSurvivorState[32];

    void Reset() {
        this.iLostDamageBonus = 0;
        this.fSkillGainBonus = 0.0;
        this.iSiDamage = 0;
        this.bTiebreakerEligibility = false;
    }
}
Team g_esTeam[2];

/*----------------------------------------------
-------------------- Marcos --------------------
----------------------------------------------*/

#define PERCENT_5   0.05
#define PERCENT_10  0.10
#define PERCENT_20  0.20

public Plugin myinfo =
{
    name = "L4D2 New Generation ScoreMod",
    author = "Hitomi",
    description = "New Generation ScoreMod for Versus",
    version = "1.3",
    url = "https://github.com/cy115/"
};

/*----------------------------------------------
-------------------- Natives -------------------
----------------------------------------------*/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("NGSM_GetRestBonus", Native_GetRestBonus);
    CreateNative("NGSM_GetPermHealthBonus", Native_GetPermHealthBonus);
    CreateNative("NGSM_GetDamageBonus", Native_GetDamageBonus);
    CreateNative("NGSM_GetSkillBonus", Native_GetSkillBonus);
    CreateNative("NGSM_GetPillsBonus", Native_GetPillsBonus);
    CreateNative("NGSM_GetConditionBonus", Native_GetConditionBonus);
    //=====================================================//
    CreateNative("NGSM_GetMaxChapterBonus", Native_GetMaxChapterBonus);
    CreateNative("NGSM_GetMaxPermHealthBonus", Native_GetMaxPermHealthBonus);
    CreateNative("NGSM_GetMaxDamageBonus", Native_GetMaxDamageBonus);
    CreateNative("NGSM_GetMaxSkillBonus", Native_GetMaxSkillBonus);
    CreateNative("NGSM_GetMaxPillsBonus", Native_GetMaxPillsBonus);
    CreateNative("NGSM_GetMaxConditionBonus", Native_GetMaxConditionBonus);
    //===========================================================//
    RegPluginLibrary("l4d2_new_generation_scoremod");
    g_bLateLoad = late;

    return APLRes_Success;
}

int Native_GetRestBonus(Handle plugin, int numParams) {
    return (RoundToFloor(g_fPermHealthBonus) + RoundToFloor(g_fDamageBonus) + RoundToFloor(g_fSkillBonus) + g_iPillsBonus + RoundToFloor(g_fConditionBonus)) - 
            (RoundToFloor(GetSurvivorPermHealthBonus()) + RoundToFloor(GetSurvivorDamageBonus()) + RoundToFloor(GetSurvivorSkillBonus()) + RoundToFloor(GetSurvivorPillsBonus()) + RoundToFloor(GetSurvivorConditionBonus()));
}

int Native_GetPermHealthBonus(Handle plugin, int numParams) {
    return RoundToFloor(GetSurvivorPermHealthBonus());
}

int Native_GetDamageBonus(Handle plugin, int numParams) {
    return RoundToFloor(GetSurvivorDamageBonus());
}

int Native_GetSkillBonus(Handle plugin, int numParams) {
    return RoundToFloor(GetSurvivorSkillBonus());
}

int Native_GetPillsBonus(Handle plugin, int numParams) {
    return RoundToFloor(GetSurvivorPillsBonus());
}

int Native_GetConditionBonus(Handle plugin, int numParams) {
    return RoundToFloor(GetSurvivorConditionBonus());
}

int Native_GetMaxChapterBonus(Handle plugin, int numParams) {
    return RoundToFloor(g_fPermHealthBonus) + RoundToFloor(g_fDamageBonus) + RoundToFloor(g_fSkillBonus) + g_iPillsBonus + RoundToFloor(g_fConditionBonus);
}

int Native_GetMaxPermHealthBonus(Handle plugin, int numParams) {
    return RoundToFloor(g_fPermHealthBonus);
}

int Native_GetMaxDamageBonus(Handle plugin, int numParams) {
    return RoundToFloor(g_fDamageBonus);
}

int Native_GetMaxSkillBonus(Handle plugin, int numParams) {
    return RoundToFloor(g_fSkillBonus);
}

int Native_GetMaxPillsBonus(Handle plugin, int numParams) {
    return g_iPillsBonus;
}

int Native_GetMaxConditionBonus(Handle plugin, int numParams) {
    return RoundToFloor(g_fConditionBonus);
}

/*----------------------------------------------
--------------------- Main ---------------------
----------------------------------------------*/

public void OnPluginStart()
{
    // Get Game Cvars
    g_hCvarValveTieBreaker = FindConVar("vs_tiebreak_bonus");
    g_hCvarValveDefibPenalty = FindConVar("vs_defib_penalty");
    g_hCvarValveSurvivalBonus = FindConVar("vs_survival_bonus");

    // Regist Plugin Convars
    CreateConVarHook("l4d2_NGSM_Perm", "1.2", "Permanent health bonus ratio[maxMapDistance * thisRatio].", _, true, 0.0, false, 0.0, OnPHBChange);
    CreateConVarHook("l4d2_NGSM_Incap", "0.8", "Damage bonus ratio[maxMapDistance * thisRatio].", _, true, 0.0, false, 0.0, OnIBRChange);
    CreateConVarHook("l4d2_NGSM_Skill", "0.5", "Skill bonus ratio[maxMapDistance * thisRatio].", _, true, 0.0, false, 0.0, OnSBRChange);
    CreateConVarHook("l4d2_NGSM_Pills", "0.2", "Pill bonus ratio[maxMapDistance * thisRatio].", _, true, 0.0, false, 0.0, OnPBRChange);
    CreateConVarHook("l4d2_NGSM_Condition", "0.4", "Condition bonus ratio[maxMapDistance * thisRatio].", _, true, 0.0, false, 0.0, OnCBRChange);

    // Hook Evnets
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_incapacitated", Event_PlayerIncapacitated);
    HookEvent("player_death", Event_PlayerDeath);

    // Commands
    RegConsoleCmd("sm_health", Cmd_Bonus, "Print bonus.");
    RegConsoleCmd("sm_bonus", Cmd_Bonus, "Print bonus.");
    RegConsoleCmd("sm_mapinfo", Cmd_MapInfo, "Print Map bonus info.");

    // late load
    if (g_bLateLoad) {
        for (int i = 1; i <= MaxClients; i++) {
            if (!IsClientInGame(i)) {
                continue;
            }

            OnClientPutInServer(i);
        }
    }
}

public void OnPluginEnd()
{
    g_hCvarValveTieBreaker.RestoreDefault();
    g_hCvarValveDefibPenalty.RestoreDefault();
    g_hCvarValveSurvivalBonus.RestoreDefault();
}

public void OnConfigsExecuted()
{
    // Initialize survivor count and bonus values
    g_iTeamSize = FindConVar("survivor_limit").IntValue;
    g_hCvarValveTieBreaker.SetInt(0);
    g_hCvarValveDefibPenalty.SetInt(0);
    g_hCvarValveSurvivalBonus.SetInt(0);
    // Initialize map distance (bonus)
    g_iMapMaxDistance = L4D2_GetMapValueInt("max_distance", L4D_GetVersusMaxCompletionScore());
    L4D_SetVersusMaxCompletionScore(g_iMapMaxDistance);
    g_iMapDistance = (g_iMapMaxDistance / 4) * g_iTeamSize;

    g_fMapBonus = g_iMapDistance * (g_fPermHealthBonusRate + g_fDamageBonusRate + g_fSkillBonusRate + g_fPillsBonusRate + g_fConditionBonusRate); // 地图总分
    g_fPermHealthBonus = g_iMapDistance * g_fPermHealthBonusRate;       // Total health bonus
    g_fDamageBonus = g_iMapDistance * g_fDamageBonusRate;               // Total damage bonus
    g_fSkillBonus = g_iMapDistance * g_fSkillBonusRate;                 // Total skill bonus
    g_iPillsBonus = RoundToNearest(g_iMapDistance * g_fPillsBonusRate); // Total pills bonus
    g_fConditionBonus = g_iMapDistance * g_fConditionBonusRate;         // Total conditionBonus
    g_iPillWorth = g_iPillsBonus / g_iTeamSize;                         // Bonus of per pain_pill

    // Skill bonus thresholds
    g_f5Percent = g_fSkillBonus * 0.05;
    g_f10Percent = g_fSkillBonus * 0.1;
    g_f20Percent = g_fSkillBonus * 0.2;
}

public void OnMapStart()
{
    OnConfigsExecuted();

    g_esTeam[0].Reset();
    g_esTeam[1].Reset();
}

public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
    if (g_bRoundOver) {
        return Plugin_Continue;
    }

    int
        team = InSecondHalfOfRound(),
        iSurvivalMultiplier = countSurvivors ? GetAliveSurvivorCount() : 0;
    
    g_esTeam[team].fSurvivorSkillBonus = GetSurvivorSkillBonus();
    g_esTeam[team].fSurvivorSkillBonus = float(RoundToFloor(g_esTeam[team].fSurvivorSkillBonus / g_iTeamSize) * g_iTeamSize);

    g_esTeam[team].fSurvivorMainBonus = GetSurvivorPermHealthBonus() + GetSurvivorDamageBonus() + GetSurvivorPillsBonus() +GetSurvivorConditionBonus();
    g_esTeam[team].fSurvivorMainBonus = float(RoundToFloor(g_esTeam[team].fSurvivorMainBonus / g_iTeamSize) *g_iTeamSize);

    g_esTeam[team].fSurvivorBonus = g_esTeam[team].fSurvivorMainBonus + g_esTeam[team].fSurvivorSkillBonus;
    if (iSurvivalMultiplier > 0 && RoundToFloor(g_esTeam[team].fSurvivorBonus / iSurvivalMultiplier) >= g_iTeamSize) {
        g_hCvarValveSurvivalBonus.SetInt(RoundToFloor(g_esTeam[team].fSurvivorMainBonus / iSurvivalMultiplier));
        g_esTeam[team].fSurvivorMainBonus = float(g_hCvarValveSurvivalBonus.IntValue * iSurvivalMultiplier);
        FormatEx(g_esTeam[team].sSurvivorState, sizeof(Team::sSurvivorState), "%s%i\x01/\x05%i\x01", (iSurvivalMultiplier == g_iTeamSize ? "\x05" : "\x04"), iSurvivalMultiplier, g_iTeamSize);
    } else {
        g_esTeam[team].fSurvivorBonus = 0.0;
        g_hCvarValveSurvivalBonus.SetInt(0);
        g_hCvarValveDefibPenalty.SetInt(0);
        g_esTeam[team].bTiebreakerEligibility = (iSurvivalMultiplier == g_iTeamSize);
        FormatEx(g_esTeam[team].sSurvivorState, sizeof(Team::sSurvivorState), "\x04%s\x01", (iSurvivalMultiplier == 0 ? "wiped out" : "bonus depleted"));
    }

    g_hCvarValveDefibPenalty.SetInt(-RoundToFloor(g_esTeam[team].fSurvivorSkillBonus));
    GameRules_SetProp("m_iVersusDefibsUsed", (RoundToFloor(g_esTeam[team].fSurvivorSkillBonus) == 0) ? 0 : 1, 4, GameRules_GetProp("m_bAreTeamsFlipped", 4, 0));

    if (team > 0 && g_esTeam[0].bTiebreakerEligibility && g_esTeam[1].bTiebreakerEligibility) {
        GameRules_SetProp("m_iChapterDamage", g_esTeam[0].iSiDamage, _, 0, true);
        GameRules_SetProp("m_iChapterDamage", g_esTeam[1].iSiDamage, _, 1, true);
        if (g_esTeam[0].iSiDamage != g_esTeam[1].iSiDamage) {
            g_hCvarValveTieBreaker.SetInt(g_iPillWorth);
        }
    }

    // 打印
    CreateTimer(3.0, Timer_PrintRoundEndBonus, _, TIMER_FLAG_NO_MAPCHANGE);
    g_bRoundOver = true;

    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!IsSurvivor(victim) || IsPlayerIncap(victim)) {
        return Plugin_Continue;
    }

    if (!IsAnyInfected(attacker)) {
        g_esTeam[InSecondHalfOfRound()].iSiDamage += (damage <= 100.0 ? RoundFloat(damage) : 100);
    }

    return Plugin_Continue;
}

/*----------------------------------------------
-------------------- Events --------------------
----------------------------------------------*/

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_bRoundOver = false;
}

void Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bRoundOver) {
        return;
    }

    int sur = GetClientOfUserId(event.GetInt("userid"));
    if (IsSurvivor(sur) && !IsPlayerLedged(sur)) {
        g_esTeam[InSecondHalfOfRound()].iLostDamageBonus += 
            RoundToFloor(g_fDamageBonus * (GetEntProp(sur, Prop_Send, "m_currentReviveCount") + 1) * 0.1);
    }
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bRoundOver) {
        return;
    }

    int sur = GetClientOfUserId(event.GetInt("userid"));
    if (IsSurvivor(sur) && !GetEntProp(sur, Prop_Send, "m_currentReviveCount")) {
        g_esTeam[InSecondHalfOfRound()].iLostDamageBonus += 
            RoundToFloor(g_fDamageBonus * 0.25);
    }
}

/*----------------------------------------------
------------------- Commands -------------------
----------------------------------------------*/

Action Cmd_Bonus(int client, int args)
{
    if (g_bRoundOver || !client) {
        return Plugin_Handled;
    }

    float
        fPermHealthBonus = GetSurvivorPermHealthBonus(),
        fDamageBonus = GetSurvivorDamageBonus(),
        fSkillBonus = GetSurvivorSkillBonus(),
        fPillsBonus = GetSurvivorPillsBonus(),
        fConditionBonus = GetSurvivorConditionBonus();

    int
        team = InSecondHalfOfRound(),
        totalBonus = RoundToFloor(fPermHealthBonus + fDamageBonus + fSkillBonus + fPillsBonus + fConditionBonus);
    // Second Round
    if (team) {
        CPrintToChat(client, "{red}R\x01#\x051 \x01Bonus: {red}%d \x01<{red}%.1f%%\x01> [%s]", 
                    RoundToFloor(g_esTeam[0].fSurvivorMainBonus + g_esTeam[0].fSurvivorSkillBonus), 
                    CalculateBonusPercent(g_esTeam[0].fSurvivorMainBonus + g_esTeam[0].fSurvivorSkillBonus),
                    g_esTeam[0].sSurvivorState);
    }

    CPrintToChat(client, "{blue}R\x01#\x05%i \x01Bonus: {blue}%d \x01<{blue}%.1f%%\x01>", 
        team + 1, totalBonus, 
        CalculateBonusPercent(fPermHealthBonus + fDamageBonus + fSkillBonus + fPillsBonus + fConditionBonus, g_fMapBonus));
    CPrintToChat(client, "\x01[ {blue}HB\x01: \x05%.0f%% \x01| {blue}DB\x01: \x05%.0f%% \x01| {blue}SB\x01: \x05%.0f%% \x01| {blue}PB\x01: \x05%.0f%% \x01| {blue}CB\x01: \x05%.0f%% \x01]", 
        CalculateBonusPercent(fPermHealthBonus, g_fPermHealthBonus), CalculateBonusPercent(fDamageBonus, g_fDamageBonus), 
        CalculateBonusPercent(g_esTeam[team].fSkillGainBonus, g_fSkillBonus), CalculateBonusPercent(fPillsBonus, float(g_iPillsBonus)), 
        CalculateBonusPercent(fConditionBonus, g_fConditionBonus));
    // R#1 Bonus: 1145 <81%>
    // [HB: 20% | DB: 50% | SB: 56% | PB: 75% | CB: 50%]

    return Plugin_Handled;
}

Action Cmd_MapInfo(int client, int args)
{
    if (!client) {
        return Plugin_Handled;
    }

    CPrintToChat(client, "\x01[{lightgreen}NGSM \x01:: {lightgreen}%i\x01v{lightgreen}%i\x01] \x05Map Info", g_iTeamSize, g_iTeamSize);
    CPrintToChat(client, "{blue}Distance\x01: [\x05%d\x01]\n{blue}MaxBonus\x01: [\x05%d\x01]", g_iMapDistance, RoundToFloor(g_fMapBonus));
    CPrintToChat(client, "{blue}PermBonus\x01: [\x05%d\x01]\n{blue}DamageBonus\x01: [\x05%d\x01]", RoundToFloor(g_fPermHealthBonus), RoundToFloor(g_fDamageBonus));
    CPrintToChat(client, "{blue}SkillBonus\x01: [\x05%d\x01]\n{blue}PillsBonus\x01: [\x05%d\x01]", RoundToFloor(g_fSkillBonus), g_iPillsBonus);
    CPrintToChat(client, "{blue}ConditionBonus\x01: [\x05%d\x01]\n{blue}TieBreaker\x01: [\x05%d\x01]", RoundToFloor(g_fConditionBonus), g_iPillWorth);

    // [NGSM :: 4v4] Map Info
    // Distance: [400]
    // MaxBonus: [920]
    // PermBonus: [600]
    // DamageBonus: [200]
    // SkillBonus: [30]
    // PillsBonus: [30]
    // ConditionBonus: [30]
    // TieBreaker: [30]

    return Plugin_Handled;
}

// Functions of Others
Action Timer_PrintRoundEndBonus(Handle timer)
{
    int team = InSecondHalfOfRound();
    for (int i = 0; i <= team; i++) {
        CPrintToChatAll("{lightgreen}R\x01#\x05%i \x01Bonus: {lightgreen}%d\x01/{lightgreen}%d \x01<{lightgreen}%.1f%%\x01> [%s]",
                        i + 1, RoundToFloor(g_esTeam[team].fSurvivorMainBonus), 
                        RoundToFloor(g_fMapBonus), 
                        CalculateBonusPercent(g_esTeam[team].fSurvivorMainBonus),
                        g_esTeam[team].sSurvivorState);
    }

    if (team && g_esTeam[0].bTiebreakerEligibility && g_esTeam[1].bTiebreakerEligibility) {
        CPrintToChatAll("{red}TIEBREAKER\x01: Team {red}#1\x01 - {red}%i\x01, Team {blue}#2\x01 - {blue}%i", g_esTeam[0].iSiDamage, g_esTeam[1].iSiDamage);
        if (g_esTeam[0].iSiDamage == g_esTeam[1].iSiDamage) {
            CPrintToChatAll("{red}Teams have performed absolutely equal\x01! Impossible to decide a clear round winner");
        }
    }

    return Plugin_Continue;
}

// Functions of GetBouns
float GetSurvivorPermHealthBonus()
{
    float fPermHealthBonus;
    int survivorCount, survivalMultiplier;
    for (int i = 1; i <= MaxClients && survivorCount < g_iTeamSize; i++) {
        if (IsSurvivor(i)) {
            survivorCount++;
            if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedged(i)) {
                survivalMultiplier++;
                if (GetEntProp(i, Prop_Send, "m_currentReviveCount") != 0) {
                    continue;
                }

                fPermHealthBonus += GetSurvivorPermanentHealth(i) * ((g_fPermHealthBonus / g_iTeamSize) / 100);
            }
        }
    }

    return (fPermHealthBonus / g_iTeamSize * survivalMultiplier);
}

float GetSurvivorDamageBonus()
{
    int team = InSecondHalfOfRound();
    float LostDamage = float(g_esTeam[team].iLostDamageBonus);

    return (g_fDamageBonus >= LostDamage) ? g_fDamageBonus - LostDamage : 0.0;
}

float GetSurvivorSkillBonus()
{
    return g_esTeam[InSecondHalfOfRound()].fSkillGainBonus;
}

float GetSurvivorPillsBonus()
{
    int pillsBonus;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsSurvivor(i)) {
            if (IsPlayerAlive(i) && !IsPlayerIncap(i) && HasPills(i)) {
                pillsBonus += g_iPillWorth;
            }
        }
    }

    return float(pillsBonus);
}

float GetSurvivorConditionBonus()
{
    int
        iSurvivorCount = 0,
        iGreenSurvivorCount = 0,
        iYellowSurvivorCount = 0,
        iRedSurvivorCount = 0,
        iTotalHealth = 0;

    float
        fGreenWorth = g_fConditionBonus / 4,
        fYellowWorth = g_fConditionBonus / 10,
        fRedWorth = g_fConditionBonus / 20;

    for (int i = 1; i <= MaxClients && iSurvivorCount < g_iTeamSize; i++) {
        if (IsSurvivor(i)) {
            iSurvivorCount++;
            if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedged(i)) {
                if (GetEntProp(i, Prop_Send, "m_currentReviveCount") == 0) {
                    iTotalHealth = GetEntProp(i, Prop_Send, "m_iHealth") + GetSurvivorTemporaryHealth(i);
                }
                else {
                    iTotalHealth = GetSurvivorTemporaryHealth(i) + 1;
                }

                if (iTotalHealth >= 40) {iGreenSurvivorCount++;}
                else if (iTotalHealth >= 25) {iYellowSurvivorCount++;}
                else {iRedSurvivorCount++;}
            }
        }
    }

    return iGreenSurvivorCount * fGreenWorth + iYellowSurvivorCount * fYellowWorth + iRedSurvivorCount * fRedWorth;
}

/*----------------------------------------------
--------------------- Tools --------------------
----------------------------------------------*/
stock int InSecondHalfOfRound()
{
    return GameRules_GetProp("m_bInSecondHalfOfRound");
}

stock int GetAliveSurvivorCount()
{
    int iAliveCount, iSurvivorCount;
    for (int i = 1; i <= MaxClients && iSurvivorCount < g_iTeamSize; i++) {
        if (IsSurvivor(i)) {
            iSurvivorCount++;
            if (IsPlayerAlive(i)) {
                iAliveCount++;
            }
        }
    }

    return iAliveCount;
}

stock int GetSurvivorPermanentHealth(int client)
{
    return GetEntProp(client, Prop_Send, "m_currentReviveCount") > 0 ? 0 : (GetEntProp(client, Prop_Send, "m_iHealth") > 0 ? GetEntProp(client, Prop_Send, "m_iHealth") : 0);
}

stock int GetSurvivorTemporaryHealth(int client)
{
	int temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * FindConVar("pain_pills_decay_rate").FloatValue)) - 1;
	return (temphp > 0 ? temphp : 0);
}

stock float CalculateBonusPercent(float score, float maxbonus = -1.0)
{
    return score / (maxbonus == -1.0 ? g_fMapBonus : maxbonus) * 100;
}

stock bool HasPills(int client)
{
    int item = GetPlayerWeaponSlot(client, 4);
    if (IsValidEdict(item)) {
        char buffer[32];
        GetEdictClassname(item, buffer, sizeof(buffer));
        return StrEqual(buffer, "weapon_pain_pills");
    }

    return false;
}

stock bool IsSurvivor(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock bool IsPlayerIncap(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

stock bool IsPlayerLedged(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge")|GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

/*----------------------------------------------
------------------ Skill Detect ----------------
----------------------------------------------*/

public void OnSpecialClear(int clearer, int pinner, int pinvictim, int zombieClass, float timeA, float timeB, bool withShove)
{
    int team = InSecondHalfOfRound();
    if (timeA <= 0.2 || timeB <= 0.2) {
        if (g_esTeam[team].fSkillGainBonus < g_fSkillBonus) {
            g_esTeam[team].fSkillGainBonus = g_esTeam[team].fSkillGainBonus + g_f5Percent >= g_fSkillBonus ? g_fSkillBonus : g_esTeam[team].fSkillGainBonus + g_f5Percent;
        }
    }
}

public void OnHunterSkeet(int survivor, int hunter)
{
    if (g_bRoundOver) {
        return;
    }

    int team = InSecondHalfOfRound();
    if (g_esTeam[team].fSkillGainBonus < g_fSkillBonus){
        g_esTeam[team].fSkillGainBonus = g_esTeam[team].fSkillGainBonus + g_f5Percent >= g_fSkillBonus ? g_fSkillBonus : g_esTeam[team].fSkillGainBonus + g_f5Percent;
    }
}

public void OnChargerLevelHurt(int survivor, int charger, int damage)
{
    if (g_bRoundOver) {
        return;
    }
    
    int team = InSecondHalfOfRound();
    if (g_esTeam[team].fSkillGainBonus < g_fSkillBonus) {
        g_esTeam[team].fSkillGainBonus = g_esTeam[team].fSkillGainBonus + g_f5Percent >= g_fSkillBonus ? g_fSkillBonus : g_esTeam[team].fSkillGainBonus + g_f5Percent;
    }
}

public void OnWitchCrown(int survivor, int damage)
{
    if (g_bRoundOver) {
        return;
    }
    
    int team = InSecondHalfOfRound();
    if (g_esTeam[team].fSkillGainBonus < g_fSkillBonus) {
        g_esTeam[team].fSkillGainBonus = g_esTeam[team].fSkillGainBonus + g_f10Percent >= g_fSkillBonus ? g_fSkillBonus : g_esTeam[team].fSkillGainBonus + g_f10Percent;
    }
}

public void OnWitchCrownHurt(int survivor, int damage, int chipdamage)
{
    if (g_bRoundOver) {
        return;
    }
    
    int team = InSecondHalfOfRound();
    if (g_esTeam[team].fSkillGainBonus < g_fSkillBonus) {
        g_esTeam[team].fSkillGainBonus = g_esTeam[team].fSkillGainBonus + g_f10Percent >= g_fSkillBonus ? g_fSkillBonus : g_esTeam[team].fSkillGainBonus + g_f10Percent;
    }
}

public void OnTongueCut(int survivor, int smoker)
{
    if (g_bRoundOver) {
        return;
    }
    
    int team = InSecondHalfOfRound();
    if (g_esTeam[team].fSkillGainBonus < g_fSkillBonus) {
        g_esTeam[team].fSkillGainBonus = g_esTeam[team].fSkillGainBonus + g_f5Percent >= g_fSkillBonus ? g_fSkillBonus : g_esTeam[team].fSkillGainBonus + g_f5Percent;
    }
}

public void OnHunterHighPounce(int hunter, int survivor, int actualDamage, float calculatedDamage, float height, bool reportedHigh)
{
    if (g_bRoundOver) {
        return;
    }
    
    int team = InSecondHalfOfRound();
    if (actualDamage > 19) {
        if (g_esTeam[team].fSkillGainBonus >= g_f10Percent) {
            g_esTeam[team].fSkillGainBonus -= g_f10Percent;
        } else {
            g_esTeam[team].fSkillGainBonus = 0.0;
        }
    }
}

public void OnDeathCharge(int charger, int survivor, float height, float distance, bool wasCarried)
{
    if (g_bRoundOver) {
        return;
    }
    
    int team = InSecondHalfOfRound();
    if (g_esTeam[team].fSkillGainBonus >= g_f20Percent) {
        g_esTeam[team].fSkillGainBonus -= g_f20Percent;
    } else {
        g_esTeam[team].fSkillGainBonus = 0.0;
    }
}

stock bool IsAnyInfected(int entity)
{
    if (entity > 0 && entity <= MaxClients) {
        return IsClientInGame(entity) && GetClientTeam(entity) == 3;
    } else if (entity > MaxClients) {
        char classname[64];
        GetEdictClassname(entity, classname, sizeof(classname));
        if (StrEqual(classname, "infected") || StrEqual(classname, "witch")) {
            return true;
        }
    }

    return false;
}

/*----------------------------------------------
-------------------- ConVars -------------------
----------------------------------------------*/
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

void OnPHBChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_fPermHealthBonusRate = convar.FloatValue;
}

void OnIBRChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_fDamageBonusRate = convar.FloatValue;
}

void OnSBRChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_fSkillBonusRate = convar.FloatValue;
}

void OnPBRChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_fPillsBonusRate = convar.FloatValue;
}

void OnCBRChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_fConditionBonusRate = convar.FloatValue;
}