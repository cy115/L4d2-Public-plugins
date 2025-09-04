#pragma semicolon 1
#pragma newdecls required

#include <left4dhooks>
#include <l4d2_ems_hud>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>
#undef REQUIRE_PLUGIN
#include <l4d2_boss_percents>
#include <l4d2_hybrid_scoremod>

#define PERCENTSYM "%%"

float
    fVersusBossBuffer;

bool
    g_bHybridScoremod;

char
    sReadyCfgName[64],
    sHostname[64];

Handle
    g_hTimerHUD[2] = {null};

ConVar
    hServerNamer,
    l4d_ready_cfg_name,
    versus_boss_buffer;

public Plugin myinfo =
{
    name = "Info Hud for Competitive Config",
    author = "Hitomi",
    description = "nothing but useful",
    version = "1.0",
    url = "https://github.com/cy115/"
};

public void OnPluginStart()
{
    (versus_boss_buffer = FindConVar("versus_boss_buffer")).AddChangeHook(GameConVarChanged);

    GetGameCvars();

    FillServerNamer();
    FillReadyConfig();

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void OnPluginEnd()
{
    if (HUDSlotIsUsed(HUD_LEFT_TOP)) {
        RemoveHUD(HUD_LEFT_TOP);
    }

    if (HUDSlotIsUsed(HUD_RIGHT_TOP)) {
        RemoveHUD(HUD_RIGHT_TOP);
    }
}

void GameConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetGameCvars();
}

void ServerCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    FillServerNamer();
}

public void OnAllPluginsLoaded()
{
    FillServerNamer();
    FillReadyConfig();
    FindScoreMod();
}

public void OnLibraryAdded(const char[] name)
{
    FindScoreMod();
}

public void OnLibraryRemoved(const char[] name)
{
    FindScoreMod();
}

void FindScoreMod()
{
    g_bHybridScoremod = LibraryExists("l4d2_hybrid_scoremod") || LibraryExists("l4d2_hybrid_scoremod_zone");
}

// 插件依赖
void FillServerNamer()
{
    ConVar convar = null;
    if ((convar = FindConVar("l4d_ready_server_cvar")) != null) {
        char buffer [64];
        convar.GetString(buffer, sizeof(buffer));
        convar = FindConVar(buffer);
    }

    if (convar == null) {
        convar = FindConVar("hostname");
    }

    if (hServerNamer == null) {
        hServerNamer = convar;
        hServerNamer.AddChangeHook(ServerCvarChanged);
    }
    else if (hServerNamer != convar) {
        hServerNamer.RemoveChangeHook(ServerCvarChanged);
        hServerNamer = convar;
        hServerNamer.AddChangeHook(ServerCvarChanged);
    }

    hServerNamer.GetString(sHostname, sizeof(sHostname));
}

void FillReadyConfig()
{
    if (l4d_ready_cfg_name != null || (l4d_ready_cfg_name = FindConVar("l4d_ready_cfg_name")) != null)
        l4d_ready_cfg_name.GetString(sReadyCfgName, sizeof(sReadyCfgName));
}
public void OnMapStart()
{
    EnableHUD();
}

void GetGameCvars()
{
    fVersusBossBuffer = versus_boss_buffer.FloatValue;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    // 有关服名字 右
    g_hTimerHUD[0] = CreateTimer(3.0, Timer_FillServerName, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
    // 有关Boss、分数、轮换的 左
    g_hTimerHUD[1] = CreateTimer(1.0, HudBossInfo, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

Action Timer_FillServerName(Handle timer)
{
    static char buf[64];
    FormatEx(buf, sizeof(buf), "%s(%i/%i)", sHostname, GetRealClientCount(), FindConVar("sv_maxplayers").IntValue);
    HUDSetLayout(HUD_RIGHT_TOP, HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT, buf);
    HUDPlace(HUD_RIGHT_TOP, 0.65, 0.0, 1.2, 0.03);

    return Plugin_Continue;
}

Action HudBossInfo(Handle timer)
{
    char sLeft[2][108];
    // Boss
    int tank = GetStoredTankPercent(), witch = GetStoredWitchPercent();
    // 声明需要打包的东西
    int iNumber[3];
    char sBosstance[sizeof(iNumber)][24];

    int distance = GetHighestSurvivorFlow();
    if (distance == -1) {
        distance = GetFurthestSurvivorFlow();
    }

    FormatEx(sBosstance[0], sizeof(sBosstance[]), "Cur: [ %i%s ]", distance, PERCENTSYM);
    if (tank > 0)
        FormatEx(sBosstance[1], sizeof(sBosstance[]), " Tank: [ %i%s ]", tank, PERCENTSYM);
    else if (!tank)
        FormatEx(sBosstance[1], sizeof(sBosstance[]), " Tank: [ Static ]");
    else
        FormatEx(sBosstance[1], sizeof(sBosstance[]), " Tank: [ Error ]");

    if (witch > 0)
        FormatEx(sBosstance[2], sizeof(sBosstance[]), " Witch: [ %i%s ]", witch, PERCENTSYM);
    else if (!witch)
        FormatEx(sBosstance[2], sizeof(sBosstance[]), " Witch: [ Static ]");
    else
        FormatEx(sBosstance[2], sizeof(sBosstance[]), " Witch: [ Error ]");

    ImplodeStrings(sBosstance, sizeof(sBosstance), "", sLeft[0], sizeof(sLeft[]));

    if (g_bHybridScoremod) {
        int HealthBonus = SMPlus_GetHealthBonus(),
            DamageBonus = SMPlus_GetDamageBonus(),
            PillsBonus = SMPlus_GetPillsBonus(),
            TotalBonus = HealthBonus + DamageBonus + PillsBonus,
            maxHealthBonus = SMPlus_GetMaxHealthBonus(),
            maxDamageBonus = SMPlus_GetMaxDamageBonus(),
            maxPillsBonus = SMPlus_GetMaxPillsBonus();
        FormatEx(sLeft[1], sizeof(sLeft[]), "Bonus %i [HB: %i%s | DB: %i%s | PB: %i/%i%s ]", 
        TotalBonus, calculatepercent(HealthBonus, maxHealthBonus), PERCENTSYM, calculatepercent(DamageBonus, maxDamageBonus), PERCENTSYM, PillsBonus, calculatepercent(PillsBonus, maxPillsBonus), PERCENTSYM);
    }

    char sAll[216];
    ImplodeStrings(sLeft, sizeof(sLeft), "\n", sAll, sizeof(sAll));
    HUDSetLayout(HUD_LEFT_TOP, HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG, sAll);
    HUDPlace(HUD_LEFT_TOP, 0.00, 0.00, 1.2, 0.06);

    return Plugin_Continue;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Tools
stock int GetFurthestSurvivorFlow()
{
    int flow = RoundToNearest(100.0 * (L4D2_GetFurthestSurvivorFlow() + fVersusBossBuffer) / L4D2Direct_GetMapMaxFlowDistance());
    return flow < 100 ? flow : 100;
}

stock int GetHighestSurvivorFlow()
{
    int flow = -1, client = L4D_GetHighestFlowSurvivor();
    if (client > 0) {
        flow = RoundToNearest(100.0 * (L4D2Direct_GetFlowDistance(client) + fVersusBossBuffer) / L4D2Direct_GetMapMaxFlowDistance());
    }
    
    return flow < 100 ? flow : 100;
}

stock int GetRoundTankFlow()
{
    return RoundToNearest(L4D2Direct_GetVSTankFlowPercent(InSecondHalfOfRound()) + fVersusBossBuffer / L4D2Direct_GetMapMaxFlowDistance());
}

stock int GetRoundWitchFlow()
{
    return RoundToNearest(L4D2Direct_GetVSWitchFlowPercent(InSecondHalfOfRound()) + fVersusBossBuffer / L4D2Direct_GetMapMaxFlowDistance());
}

stock bool RoundHasFlowTank()
{
    return L4D2Direct_GetVSTankToSpawnThisRound(InSecondHalfOfRound());
}

stock bool RoundHasFlowWitch()
{
    return L4D2Direct_GetVSWitchToSpawnThisRound(InSecondHalfOfRound());
}

stock int GetRealClientCount()
{
    int clients = 0;
    for (int i = 1; i <= MaxClients; ++i) {
        if (IsClientConnected(i) && !IsFakeClient(i)) {
            clients++;
        }
    }
    
    return clients;
}

stock int calculatepercent(int a, int b) {
    return RoundToNearest(float(a) / float(b) * 100.0);
}