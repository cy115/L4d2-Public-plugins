#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
// 猴子，小僵尸，女巫随机尺寸的上下限值
#define JOCKEY_MIN_SIZE 0.1
#define JOCKEY_MAX_SIZE 0.1
#define INFECTED_MIN_SIZE 0.1
#define INFECTED_MAX_SIZE 2.0
#define WITCH_MIN_SIZE 0.1
#define WITCH_MAX_SIZE 2.0

public Plugin myinfo =
{
    name = "Infected Size",
    author = "Hitomi",
    description = "改变猴子, 小僵尸, 女巫尺寸",
    version = "1.2",
    url = "https://github.com/cy115/"
};

bool
    g_bJockeyRandom,
    g_bInfRandom,
    g_bWitchRandom;

float
    g_fJockeySize,
    g_fInfSize,
    g_fWitchSize;

ConVar
    g_hCvarJockeyRandom,
    g_hCvarJockeySize,
    g_hCvarInfRandom,
    g_hCvarInfSize,
    g_hCvarWitchRandom,
    g_hCvarWitchSize;

public void OnPluginStart()
{
    g_hCvarJockeyRandom = CreateConVar("l4d2_jockey_rand", "1", "是否启用Jockey随机大小[0=禁用/1=启用].", _, true, 0.0, true, 1.0);
    g_hCvarJockeySize = CreateConVar("l4d2_jockey_size", "1.0", "Jockey尺寸[若启用随机大小则禁用此功能].", _, true, 0.0);
    g_hCvarInfRandom = CreateConVar("l4d2_inf_rand", "1", "是否启用小僵尸随机大小[0=禁用/1=启用].", _, true, 0.0, true, 1.0);
    g_hCvarInfSize = CreateConVar("l4d2_inf_size", "1.0", "小僵尸尺寸[若启用随机大小则禁用此功能].", _, true, 0.0);
    g_hCvarWitchRandom = CreateConVar("l4d2_witch_rand", "1", "是否启用女巫随机大小[0=禁用/1=启用].", _, true, 0.0, true, 1.0);
    g_hCvarWitchSize = CreateConVar("l4d2_witch_size", "1.0", "女巫尺寸[若启用随机大小则禁用此功能].", _, true, 0.0);
    g_hCvarJockeyRandom.AddChangeHook(OnConVarChanged);
    g_hCvarJockeySize.AddChangeHook(OnConVarChanged);
    g_hCvarInfRandom.AddChangeHook(OnConVarChanged);
    g_hCvarInfSize.AddChangeHook(OnConVarChanged);
    g_hCvarWitchRandom.AddChangeHook(OnConVarChanged);
    g_hCvarWitchSize.AddChangeHook(OnConVarChanged);

    GetCvars();

    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("witch_spawn", Event_WitchSpawn);

    AutoExecConfig(true, "l4d2_scale_size");
}

void GetCvars()
{
    g_bJockeyRandom = g_hCvarJockeyRandom.BoolValue;
    g_bInfRandom = g_hCvarInfRandom.BoolValue;
    g_bWitchRandom = g_hCvarWitchRandom.BoolValue;
    g_fJockeySize = g_hCvarJockeySize.FloatValue;
    g_fInfSize = g_hCvarInfSize.FloatValue;
    g_fWitchSize = g_hCvarWitchSize.FloatValue;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}
// 猴子大小设置
void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    if (g_bJockeyRandom) {
        RequestFrame(SetJockeyRandomSize, userid);
    }
    else if (g_fJockeySize && g_fJockeySize != 1.0) {
        RequestFrame(SetJockeyStaticSize, userid);
    }
}

void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int witch = event.GetInt("witchid");
    if (g_bWitchRandom) {
        RequestFrame(SetWitchRandomSize, witch);
    }
    else if (g_fWitchSize && g_fWitchSize != 1.0) {
        RequestFrame(SetWitchStaticSize, witch);
    }
}

void SetJockeyRandomSize(int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 5) {
        SetEntPropFloat(client, Prop_Send, "m_flModelScale", GetRandomFloat(JOCKEY_MIN_SIZE, JOCKEY_MAX_SIZE));
    }
}

void SetJockeyStaticSize(int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 5) {
        SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_fJockeySize);
    }
}

void SetWitchRandomSize(int witch)
{
    if (IsWitch(witch)) {
        SetEntPropFloat(witch, Prop_Send, "m_flModelScale", GetRandomFloat(WITCH_MIN_SIZE, WITCH_MAX_SIZE));
    }
}

void SetWitchStaticSize(int witch)
{
    if (IsWitch(witch)) {
        SetEntPropFloat(witch, Prop_Send, "m_flModelScale", g_fWitchSize);
    }
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!IsValidEntity(entity) || !entity) {
        return;
    }

    if (!strncmp(classname, "infected", 8)) {
        if (g_bInfRandom) {
            RequestFrame(SetInfectedRandomSize, entity);
        }
        else if (g_fInfSize && g_fInfSize != 1.0) {
            RequestFrame(SetInfectedStaticSize, entity);
        }
    }
}

void SetInfectedRandomSize(int entity)
{
    if (IsValidEntity(entity)) {
        SetEntPropFloat(entity, Prop_Send, "m_flModelScale", GetRandomFloat(INFECTED_MIN_SIZE,INFECTED_MAX_SIZE));
    }
}

void SetInfectedStaticSize(int entity)
{
    if (IsValidEntity(entity)) {
        SetEntPropFloat(entity, Prop_Send, "m_flModelScale", g_fInfSize);
    }
}

stock bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

int IsWitch(int witch)
{
    if (witch > 0 && IsValidEdict(witch) && IsValidEntity(witch)) {
        char classname[32];
        GetEdictClassname(witch, classname, sizeof(classname));
        if (!strncmp(classname, "witch", 5)) {
            return true;
        }
    }

    return false;
}