// Pragma //////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma semicolon 1
#pragma newdecls required

// Include Files ///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <colors>
#include <l4d2lib>
#undef REQUIRE_PLUGIN
#include <l4d2_skill_detect>

// Variables ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

int
    g_iTeamSize,
    g_iMapDistance,
    g_iMapMaxDistance,
    g_iPillsBonus,
    g_iPillWorth,
    // damage bonus lose per round
    g_iLostDamageBonus[2],
    // damage bonus rest
    g_iSiDamage[2];

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
    // skill bonus gain per rond
    g_fSkillGainBonus[2],
    // also about bonus...
    g_fSurvivorBonus[2],
    g_fSurvivorMainBonus[2],
    g_fSurvivorSkillBonus[2],
    // skill bonus percent
    g_f5Percents,
    g_f10Percents,
    g_f20Percents;

bool
    g_bLateLoad,
    g_bRoundOver,
    // tier breaker
    g_bTiebreakerEligibility[2];

// Game Cvars
ConVar
    g_hCvarValveTieBreaker,
    g_hCvarValveDefibPenalty,
    g_hCvarValveSurivivalBonus;

// Scoremod Convars
ConVar
    g_hCvarNGSMPermanentHealthBonusRate,    // 实血分占比
    g_hCvarNGSMIncapBonusRate,              // 倒地，死亡分数占比
    g_hCvarNGSMSkillBonusRate,              // 操作分数池占比
    g_hCvarNGSMPillsBonusRate,              // 药分占比
    g_hCvarNGSMConditionBonusRate;              // 生还状态占比

public Plugin myinfo =
{
    name = "L4D2 New Generation ScoreMod",
    author = "Hitomi",
    description = "New Generation ScoreMod for Versus",
    version = "1.2",
    url = "https://github.com/cy115/"
};

// Natives and Forwards ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

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

public int Native_GetRestBonus(Handle plugin, int numParams) {
    return (RoundToFloor(g_fPermHealthBonus) + RoundToFloor(g_fDamageBonus) + RoundToFloor(g_fSkillBonus) + g_iPillsBonus + RoundToFloor(g_fConditionBonus)) - 
            (RoundToFloor(GetSurvivorPermHealthBonus()) + RoundToFloor(GetSurvivorDamageBonus()) + RoundToFloor(GetSurvivorSkillBonus()) + RoundToFloor(GetSurvivorPillsBonus()) + RoundToFloor(GetSurvivorConditionBonus()));
}

public int Native_GetPermHealthBonus(Handle plugin, int numParams) {
    return RoundToFloor(GetSurvivorPermHealthBonus());
}

public int Native_GetDamageBonus(Handle plugin, int numParams) {
    return RoundToFloor(GetSurvivorDamageBonus());
}

public int Native_GetSkillBonus(Handle plugin, int numParams) {
    return RoundToFloor(GetSurvivorSkillBonus());
}

public int Native_GetPillsBonus(Handle plugin, int numParams) {
    return RoundToFloor(GetSurvivorPillsBonus());
}

public int Native_GetConditionBonus(Handle plugin, int numParams) {
    return RoundToFloor(GetSurvivorConditionBonus());
}

public int Native_GetMaxChapterBonus(Handle plugin, int numParams) {
    return RoundToFloor(g_fPermHealthBonus) + RoundToFloor(g_fDamageBonus) + RoundToFloor(g_fSkillBonus) + g_iPillsBonus + RoundToFloor(g_fConditionBonus);
}

public int Native_GetMaxPermHealthBonus(Handle plugin, int numParams) {
    return RoundToFloor(g_fPermHealthBonus);
}

public int Native_GetMaxDamageBonus(Handle plugin, int numParams) {
    return RoundToFloor(g_fDamageBonus);
}

public int Native_GetMaxSkillBonus(Handle plugin, int numParams) {
    return RoundToFloor(g_fSkillBonus);
}

public int Native_GetMaxPillsBonus(Handle plugin, int numParams) {
    return g_iPillsBonus;
}

public int Native_GetMaxConditionBonus(Handle plugin, int numParams) {
    return RoundToFloor(g_fConditionBonus);
}

// Plugin Functions ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

public void OnPluginStart()
{
    // Get Game Cvars
    g_hCvarValveTieBreaker = FindConVar("vs_tiebreak_bonus");
    g_hCvarValveDefibPenalty = FindConVar("vs_defib_penalty");
    g_hCvarValveSurivivalBonus = FindConVar("vs_survival_bonus");

    // Set Plugin Convars
    g_hCvarNGSMPermanentHealthBonusRate = CreateConVar("l4d2_NGSM_Perm", "1.2", "实血分在路程分的比例[实血分 = 最大路程分 * 比例]");
    g_hCvarNGSMIncapBonusRate = CreateConVar("l4d2_NGSM_Incap", "0.8", "倒地分在路程分的比例[倒地分 = 最大路程分 * 比例]");
    g_hCvarNGSMSkillBonusRate = CreateConVar("l4d2_NGSM_Skill", "0.5", "操作分所占路程分比例[操作分 = 最大路程分 * 比例]");
    g_hCvarNGSMPillsBonusRate = CreateConVar("l4d2_NGSM_Pills", "0.2", "药分所占路程分比例[药分 = 最大路程分 * 比例]");
    g_hCvarNGSMConditionBonusRate = CreateConVar("l4d2_NGSM_Condition", "0.4", "队伍状态分所占路程分比例");

    // Hook Evnets
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_incapacitated", Event_PlayerIncapacitated);
    HookEvent("player_death", Event_PlayerDeath);

    // Commands
    RegConsoleCmd("sm_health", Cmd_Bonus);
    RegConsoleCmd("sm_bonus", Cmd_Bonus);
    RegConsoleCmd("sm_mapinfo", Cmd_MapInfo);

    // late load
    if (g_bLateLoad) {
        for (int i = 1; i <= MaxClients; i++) {
            if (!IsClientInGame(i))
                continue;

            OnClientPutInServer(i);
        }
    }
}

public void OnPluginEnd()
{
    g_hCvarValveTieBreaker.RestoreDefault();
    g_hCvarValveDefibPenalty.RestoreDefault();
    g_hCvarValveSurivivalBonus.RestoreDefault();
}

public void OnConfigsExecuted()
{
    // 初始化生还人数，奖励分
    g_iTeamSize = FindConVar("survivor_limit").IntValue;
    g_hCvarValveTieBreaker.SetInt(0);
    g_hCvarValveDefibPenalty.SetInt(0);
    g_hCvarValveSurivivalBonus.SetInt(0);
    // 初始化地图路程(分)
    g_iMapMaxDistance = L4D2_GetMapValueInt("max_distance", L4D_GetVersusMaxCompletionScore());
    L4D_SetVersusMaxCompletionScore(g_iMapMaxDistance);
    g_iMapDistance = (g_iMapMaxDistance / 4) * g_iTeamSize;
    
    // 插件分数设置
    g_fPermHealthBonusRate = g_hCvarNGSMPermanentHealthBonusRate.FloatValue;
    g_fDamageBonusRate = g_hCvarNGSMIncapBonusRate.FloatValue;
    g_fSkillBonusRate = g_hCvarNGSMSkillBonusRate.FloatValue;
    g_fPillsBonusRate = g_hCvarNGSMPillsBonusRate.FloatValue;
    g_fConditionBonusRate = g_hCvarNGSMConditionBonusRate.FloatValue;

    g_fMapBonus = g_iMapDistance * (g_fPermHealthBonusRate + g_fDamageBonusRate + g_fSkillBonusRate + g_fPillsBonusRate + g_fConditionBonusRate); // 地图总分
    g_fPermHealthBonus = g_iMapDistance * g_fPermHealthBonusRate;       // 总血分
    g_fDamageBonus = g_iMapDistance * g_fDamageBonusRate;               // 总伤害分
    g_fSkillBonus = g_iMapDistance * g_fSkillBonusRate;                 // 总操作分
    g_iPillsBonus = RoundToNearest(g_iMapDistance * g_fPillsBonusRate); // 总药分
    g_fConditionBonus = g_iMapDistance * g_fConditionBonusRate;                 // 总状态分
    g_iPillWorth = g_iPillsBonus / g_iTeamSize;                         // 每瓶药的分值

    // 操作分百分比计算
    g_f5Percents = g_fSkillBonus * 0.05;
    g_f10Percents = g_fSkillBonus * 0.1;
    g_f20Percents = g_fSkillBonus * 0.2;
}

// About the round /////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

public void OnMapStart()
{
    OnConfigsExecuted();

    g_iLostDamageBonus[0] = 0;
    g_iLostDamageBonus[1] = 0;
    g_fSkillGainBonus[0] = 0.0;
    g_fSkillGainBonus[1] = 0.0;
    g_bTiebreakerEligibility[0] = false;
    g_bTiebreakerEligibility[1] = false;
}

public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
    if (g_bRoundOver) {
        return Plugin_Continue;
    }

    int
        team = InSecondHalfOfRound(),
        iSurvivalMultiplier = GetUprightSurvivors();
    
    // 操作分用心脏除颤仪惩罚分来加
    g_fSurvivorSkillBonus[team] = GetSurvivorSkillBonus();
    g_fSurvivorSkillBonus[team] = float(RoundToFloor(g_fSurvivorSkillBonus[team] / g_iTeamSize) * g_iTeamSize);
    // 主要得分
    g_fSurvivorMainBonus[team] = GetSurvivorPermHealthBonus() + GetSurvivorDamageBonus() + GetSurvivorPillsBonus() +GetSurvivorConditionBonus();
    g_fSurvivorMainBonus[team] = float(RoundToFloor(g_fSurvivorMainBonus[team] / g_iTeamSize) *g_iTeamSize);
    // 所有得分
    g_fSurvivorBonus[team] = g_fSurvivorMainBonus[team] + g_fSurvivorSkillBonus[team];
    if (iSurvivalMultiplier > 0 && RoundToFloor(g_fSurvivorBonus[team] / iSurvivalMultiplier) >= g_iTeamSize) {
        g_hCvarValveSurivivalBonus.SetInt(RoundToFloor(g_fSurvivorMainBonus[team] / iSurvivalMultiplier));
        g_fSurvivorMainBonus[team] = float(g_hCvarValveSurivivalBonus.IntValue * iSurvivalMultiplier);
    }
    else {
        g_fSurvivorBonus[team] = 0.0;
        g_hCvarValveSurivivalBonus.SetInt(0);
        g_hCvarValveDefibPenalty.SetInt(0);
        g_bTiebreakerEligibility[team] = (iSurvivalMultiplier == g_iTeamSize);
    }

    g_hCvarValveDefibPenalty.SetInt(-RoundToFloor(g_fSurvivorSkillBonus[team]));
    GameRules_SetProp("m_iVersusDefibsUsed", (RoundToFloor(g_fSurvivorSkillBonus[team]) == 0) ? 0 : 1, 4, GameRules_GetProp("m_bAreTeamsFlipped", 4, 0));

    if (team > 0 && g_bTiebreakerEligibility[0] && g_bTiebreakerEligibility[1]) {
        GameRules_SetProp("m_iChapterDamage", g_iSiDamage[0], _, 0, true);
        GameRules_SetProp("m_iChapterDamage", g_iSiDamage[1], _, 1, true);
        if (g_iSiDamage[0] != g_iSiDamage[1]) {
            g_hCvarValveTieBreaker.SetInt(g_iPillWorth);
        }
    }

    // 打印
    CreateTimer(3.0, Timer_PrintRoundEndBonus, _, TIMER_FLAG_NO_MAPCHANGE);
    g_bRoundOver = true;

    return Plugin_Continue;
}

// Client Event ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!IsSurvivor(victim) || IsPlayerIncap(victim)) {
        return Plugin_Continue;
    }

    if (!IsAnyInfected(attacker)) {
        g_iSiDamage[InSecondHalfOfRound()] += (damage <= 100.0 ? RoundFloat(damage) : 100);
    }

    return Plugin_Continue;
}

// Event Hooks /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_bRoundOver = false;
}

void Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
    int sur = GetClientOfUserId(event.GetInt("userid"));
    if (IsSurvivor(sur) && !IsPlayerLedged(sur)) {
        g_iLostDamageBonus[InSecondHalfOfRound()] += 
            RoundToFloor(g_fDamageBonus * (GetEntProp(sur, Prop_Send, "m_currentReviveCount") + 1) * 0.1);
    }
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int sur = GetClientOfUserId(event.GetInt("userid"));
    if (IsSurvivor(sur) && !GetEntProp(sur, Prop_Send, "m_currentReviveCount")) {
        g_iLostDamageBonus[InSecondHalfOfRound()] += 
            RoundToFloor(g_fDamageBonus * 0.25);
    }
}

// Console Commands ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

public Action Cmd_Bonus(int client, int args) // 打印分数信息到聊天栏
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

    int totalBonus = RoundToFloor(fPermHealthBonus + fDamageBonus + fSkillBonus + fPillsBonus + fConditionBonus);
    // Second Round
    if (InSecondHalfOfRound()) {
        CPrintToChat(client, "{red}R{default}#{olive}1 {default}Bonus: {red}%d {default}<{red}%.1f%%{default}>", 
                    RoundToFloor(g_fSurvivorMainBonus[0] + g_fSurvivorSkillBonus[0]), 
                    CalculateBonusPercent(g_fSurvivorMainBonus[0] + g_fSurvivorSkillBonus[0]));
    }

    CPrintToChat(client, "{blue}R{default}#{olive}%i {default}Bonus: {blue}%d {default}<{blue}%.1f%%{default}>", 
        InSecondHalfOfRound() + 1, totalBonus, 
        CalculateBonusPercent(fPermHealthBonus + fDamageBonus + fSkillBonus + fPillsBonus + fConditionBonus, g_fMapBonus));
    CPrintToChat(client, "{default}[ {blue}HB{default}: {olive}%.0f%% {default}| {blue}DB{default}: {olive}%.0f%% {default}| {blue}SB{default}: {olive}%.0f%% {default}| {blue}PB{default}: {olive}%.0f%% {default}| {blue}CB{default}: {olive}%.0f%% {default}]", 
        CalculateBonusPercent(fPermHealthBonus, g_fPermHealthBonus), CalculateBonusPercent(fDamageBonus, g_fDamageBonus), 
        CalculateBonusPercent(g_fSkillGainBonus[InSecondHalfOfRound()], g_fSkillBonus), CalculateBonusPercent(fPillsBonus, float(g_iPillsBonus)), 
        CalculateBonusPercent(fConditionBonus, g_fConditionBonus));
    // R#1 Bonus: 1145 <81%>
    // [HB: 20% | DB: 50% | SB: 56% | PB: 75% | CB: 50%]

    return Plugin_Handled;
}

public Action Cmd_MapInfo(int client, int args) // 打印地图信息
{
    if (!client) {
        return Plugin_Handled;
    }

    CPrintToChat(client, "{default}[{lightgreen}NGSM {default}:: {lightgreen}%i{default}v{lightgreen}%i{default}] {olive}Map Info", g_iTeamSize, g_iTeamSize);
    CPrintToChat(client, "{blue}Distance{default}: [{olive}%d{default}]", g_iMapDistance);
    CPrintToChat(client, "{blue}MaxBonus{default}: [{olive}%d{default}]", RoundToFloor(g_fMapBonus));
    CPrintToChat(client, "{blue}PermBonus{default}: [{olive}%d{default}]", RoundToFloor(g_fPermHealthBonus));
    CPrintToChat(client, "{blue}DamageBonus{default}: [{olive}%d{default}]", RoundToFloor(g_fDamageBonus));
    CPrintToChat(client, "{blue}SkillBonus{default}: [{olive}%d{default}]", RoundToFloor(g_fSkillBonus));
    CPrintToChat(client, "{blue}PillsBonus{default}: [{olive}%d{default}]", g_iPillsBonus);
    CPrintToChat(client, "{blue}ConditionBonus{default}: [{olive}%d{default}]", RoundToFloor(g_fConditionBonus));
    CPrintToChat(client, "{blue}TieBreaker{default}: [{olive}%d{default}]", g_iPillWorth);

    return Plugin_Handled;
}

// Functions of Others
Action Timer_PrintRoundEndBonus(Handle timer)
{
    for (int i = 0; i <= InSecondHalfOfRound(); i++) {
        CPrintToChatAll("{lightgreen}R{default}#{olive}%i {default}Bonus: {lightgreen}%d{default}/{lightgreen}%d {default}<{lightgreen}%.1f%%{default}>",
                        i + 1, RoundToFloor(g_fSurvivorMainBonus[InSecondHalfOfRound()]), 
                        RoundToFloor(g_fMapBonus), 
                        CalculateBonusPercent(g_fSurvivorMainBonus[InSecondHalfOfRound()]));
    }

    if (InSecondHalfOfRound() && g_bTiebreakerEligibility[0] && g_bTiebreakerEligibility[1]) {
        CPrintToChatAll("{red}TIEBREAKER{default}: Team {red}%#1{default} - {red}%i{default}, Team {blue}%#2{default} - {blue}%i", g_iSiDamage[0], g_iSiDamage[1]);
        if (g_iSiDamage[0] == g_iSiDamage[1]) {
            CPrintToChatAll("{red}双方平分秋色，无法决出胜负!");
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
    return (g_fDamageBonus >= g_iLostDamageBonus[InSecondHalfOfRound()]) ? 
            g_fDamageBonus - g_iLostDamageBonus[InSecondHalfOfRound()] : 
            0.0;
}

float GetSurvivorSkillBonus()
{
    return g_fSkillGainBonus[InSecondHalfOfRound()];
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

// Tools
stock int InSecondHalfOfRound() // 判断是否第二回合
{
    return GameRules_GetProp("m_bInSecondHalfOfRound");
}

stock int GetUprightSurvivors() // 获取当前幸存者人数
{
    int aliveCount, survivorCount;
    for (int i = 1; i <= MaxClients && survivorCount < g_iTeamSize; i++) {
        if (IsSurvivor(i)) {
            survivorCount++;
            if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedged(i)) {
                aliveCount++;
            }
        }
    }

    return aliveCount;
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

stock float CalculateBonusPercent(float score, float maxbonus = -1.0) // 计算分数百分比
{
    return score / (maxbonus == -1.0 ? g_fMapBonus : maxbonus) * 100;
}

stock bool HasPills(int client) // 判断生还是否有药
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
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") | GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

// Skill Detect ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

public void OnSpecialClear(int clearer, int pinner, int pinvictim, int zombieClass, float timeA, float timeB, bool withShove) {
    if (timeA <= 0.2 || timeB <= 0.2) {
        if (g_fSkillGainBonus[InSecondHalfOfRound()] < g_fSkillBonus) {
            g_fSkillGainBonus[InSecondHalfOfRound()] = g_fSkillGainBonus[InSecondHalfOfRound()] + g_f5Percents >= g_fSkillBonus ? g_fSkillBonus : g_fSkillGainBonus[InSecondHalfOfRound()] + g_f5Percents;
        }
    }
}

public void OnHunterSkeet(int survivor, int hunter) {
    if (g_fSkillGainBonus[InSecondHalfOfRound()] < g_fSkillBonus) {
        g_fSkillGainBonus[InSecondHalfOfRound()] = g_fSkillGainBonus[InSecondHalfOfRound()] + g_f5Percents >= g_fSkillBonus ? g_fSkillBonus : g_fSkillGainBonus[InSecondHalfOfRound()] + g_f5Percents;
    }
}

public void OnChargerLevelHurt(int survivor, int charger, int damage) {
    if (g_fSkillGainBonus[InSecondHalfOfRound()] < g_fSkillBonus) {
        g_fSkillGainBonus[InSecondHalfOfRound()] = g_fSkillGainBonus[InSecondHalfOfRound()] + g_f5Percents >= g_fSkillBonus ? g_fSkillBonus : g_fSkillGainBonus[InSecondHalfOfRound()] + g_f5Percents;
    }
}

public void OnWitchCrown(int survivor, int damage) {
    if (g_fSkillGainBonus[InSecondHalfOfRound()] < g_fSkillBonus) {
        g_fSkillGainBonus[InSecondHalfOfRound()] = g_fSkillGainBonus[InSecondHalfOfRound()] + g_f10Percents >= g_fSkillBonus ? g_fSkillBonus : g_fSkillGainBonus[InSecondHalfOfRound()] + g_f10Percents;
    }
}

public void OnWitchCrownHurt(int survivor, int damage, int chipdamage) {
    if (g_fSkillGainBonus[InSecondHalfOfRound()] < g_fSkillBonus) {
        g_fSkillGainBonus[InSecondHalfOfRound()] = g_fSkillGainBonus[InSecondHalfOfRound()] + g_f10Percents >= g_fSkillBonus ? g_fSkillBonus : g_fSkillGainBonus[InSecondHalfOfRound()] + g_f10Percents;
    }
}

public void OnTongueCut(int survivor, int smoker) {
    if (g_fSkillGainBonus[InSecondHalfOfRound()] < g_fSkillBonus) {
        g_fSkillGainBonus[InSecondHalfOfRound()] = g_fSkillGainBonus[InSecondHalfOfRound()] + g_f5Percents >= g_fSkillBonus ? g_fSkillBonus : g_fSkillGainBonus[InSecondHalfOfRound()] + g_f5Percents;
    }
}

public void OnHunterHighPounce(int hunter, int survivor, int actualDamage, float calculatedDamage, float height, bool reportedHigh) {
    if (actualDamage > 19) {
        if (g_fSkillGainBonus[InSecondHalfOfRound()] >= g_f10Percents) {
            g_fSkillGainBonus[InSecondHalfOfRound()] -= g_f10Percents;
        }
        else {
            g_fSkillGainBonus[InSecondHalfOfRound()] = 0.0;
        }
    }
}

public void OnDeathCharge(int charger, int survivor, float height, float distance, bool wasCarried) {
    if (g_fSkillGainBonus[InSecondHalfOfRound()] >= g_f20Percents) {
        g_fSkillGainBonus[InSecondHalfOfRound()] -= g_f20Percents;
    }
    else {
        g_fSkillGainBonus[InSecondHalfOfRound()] = 0.0;
    }
}

stock bool IsAnyInfected(int entity)
{
    if (entity > 0 && entity <= MaxClients) {
        return IsClientInGame(entity) && GetClientTeam(entity) == 3;
    }
    else if (entity > MaxClients) {
        char classname[64];
        GetEdictClassname(entity, classname, sizeof(classname));
        if (StrEqual(classname, "infected") || StrEqual(classname, "witch")) {
            return true;
        }
    }

    return false;
}