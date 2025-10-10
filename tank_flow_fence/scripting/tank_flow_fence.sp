#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <readyup>
#include <l4d_boss_vote>
#include <l4d2_boss_percents>

// #define SPRITE_MATERIAL "materials/effects/scavenge_boundary.vmt"
#define SPRITE_MATERIAL "materials/sprites/laserbeam.vmt"

int
    g_iCurrentIndex = 0;

float
    g_fTargetFlow,
    g_fVersusBossBuffer,
    g_fMaxFlowDistance;

ArrayList
    g_alCurrentBeamList,
    g_alNavList;

public Plugin myinfo =
{
    name = "Tank Flow Fence",
    author = "Hitomi",
    description = "触发坦克生成地的栅栏",
    version = "1.1",
    url = "https://github.com/cy115/"
};

public void OnMapStart()
{
    g_iCurrentIndex = 0;
    g_fMaxFlowDistance = L4D2Direct_GetMapMaxFlowDistance();
    PrecacheModel(SPRITE_MATERIAL, true);
    RequestFrame(PrecacheNavList);  // 获取当前地图Nav块
}

public void OnPluginStart()
{
    g_alNavList = new ArrayList();
    g_alCurrentBeamList = new ArrayList();

    g_fVersusBossBuffer = FindConVar("versus_boss_buffer").FloatValue;
    
    HookEvent("round_start_post_nav", Event_RoundStartPostNav, EventHookMode_PostNoCopy);
}

void Event_RoundStartPostNav(Event event, const char[] name, bool dontBroadcast)
{
    ClearTheBeamList();
    if (!GameRules_GetProp("m_bInSecondHalfOfRound")) {
        CreateTimer(5.1, AdjustBossFlow, _, TIMER_FLAG_NO_MAPCHANGE);
    } else {
        g_fTargetFlow = float(GetStoredTankPercent()) / 100;
        g_iCurrentIndex = 0;
        RequestFrame(ProcessNavAreasFrame);
    }
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
    ClearTheBeamList();
}

Action AdjustBossFlow(Handle timer)
{
    g_fTargetFlow = float(GetStoredTankPercent()) / 100;
    g_iCurrentIndex = 0;
    RequestFrame(ProcessNavAreasFrame);

    return Plugin_Stop;
}

public void OnUpdateBosses(int iTankFlow, int iWitchFlow)
{
    ClearTheBeamList();
    g_fTargetFlow = float(iTankFlow) / 100;
    g_iCurrentIndex = 0;
    RequestFrame(ProcessNavAreasFrame);
}

public void OnPluginEnd()
{
    ClearTheBeamList();
    delete g_alNavList;
    delete g_alCurrentBeamList;
}

void PrecacheNavList()
{
    g_alNavList.Clear();
    L4D_GetAllNavAreas(g_alNavList);
}

void ProcessNavAreasFrame()
{
    int length = g_alNavList.Length;
    int processed = 0;
    Address navAddress, pNavArea;
    float vPos[3], vPosPlus[3], flow;
    for (int i = g_iCurrentIndex; i < length && processed < 50; i++) {
        navAddress = g_alNavList.Get(i);
        if (navAddress == Address_Null) {
            g_iCurrentIndex++;
            continue;
        }
        
        L4D_GetNavAreaCenter(navAddress, vPos);
        pNavArea = L4D2Direct_GetTerrorNavArea(vPos);
        
        if (pNavArea != Address_Null) {
            flow = (L4D2Direct_GetTerrorNavAreaFlow(pNavArea) / g_fMaxFlowDistance) + g_fVersusBossBuffer / L4D2Direct_GetMapMaxFlowDistance();
            // 使用近似比较，避免浮点精度问题
            if (FloatAbs(flow - g_fTargetFlow) < 0.005) {
                L4D_GetNavAreaSize(pNavArea, vPosPlus);
                DrawAreaField(vPos, vPosPlus);
            }
        }
        
        processed++;
        g_iCurrentIndex++;
    }
    // 如果还有剩余的nav区域需要处理，继续下一帧
    if (g_iCurrentIndex < length) {
        RequestFrame(ProcessNavAreasFrame);
    } else {
        g_iCurrentIndex = 0; // 重置索引
    }
}

stock void DrawAreaField(const float center[3], const float size[3], float life = 1.0)
{
    float halfWidth = size[0] / 2.0, halfLength = size[1] / 2.0, halfHeight = size[2] / 2.0;
    float corners[4][3];
    // 左下角
    corners[0][0] = center[0] - halfWidth;
    corners[0][1] = center[1] - halfLength;
    corners[0][2] = center[2] - halfHeight;
    // 右下角
    corners[1][0] = center[0] + halfWidth;
    corners[1][1] = center[1] - halfLength;
    corners[1][2] = center[2] - halfHeight;
    // 右上角
    corners[2][0] = center[0] + halfWidth;
    corners[2][1] = center[1] + halfLength;
    corners[2][2] = center[2] + halfHeight;
    // 左上角
    corners[3][0] = center[0] - halfWidth;
    corners[3][1] = center[1] + halfLength;
    corners[3][2] = center[2] + halfHeight;

    CreateEnvBeam(corners[0], corners[1]); // 底边
    CreateEnvBeam(corners[1], corners[2]); // 右边
    CreateEnvBeam(corners[2], corners[3]); // 顶边
    CreateEnvBeam(corners[3], corners[0]); // 左边
}

stock void CreateEnvBeam(const float startPos[3], const float endPos[3])
{
    int beam = CreateEntityByName("env_beam");
    if (!beam || !IsValidEntity(beam)) {
        return;
    }

    g_alCurrentBeamList.Push(beam);

    DispatchKeyValueVector(beam, "origin", startPos);
    DispatchKeyValueFloat(beam, "BoltWidth", 1.0);
    DispatchKeyValueInt(beam, "damage", 0);
    DispatchKeyValueInt(beam, "framerate", 0);
    DispatchKeyValueInt(beam, "framestart", 0);
    DispatchKeyValueFloat(beam, "HDRColorScale", 1.0);
    DispatchKeyValueFloat(beam, "life", 0.1);
    DispatchKeyValueInt(beam, "TouchType", 0);
    DispatchKeyValueFloat(beam, "NoiseAmplitude", 0.0);
    DispatchKeyValueInt(beam, "TextureScroll", 0);
    DispatchKeyValueInt(beam, "speed", 0);
    DispatchKeyValueInt(beam, "Radius", 256);
    DispatchKeyValue(beam, "texture", "sprites/laserbeam.spr");
    DispatchKeyValueInt(beam, "renderamt", 255);
    DispatchKeyValueInt(beam, "StrikeTime", 1);
    DispatchKeyValue(beam, "rendercolor", "255 255 0");
    DispatchKeyValueInt(beam, "spawnflags", 0);
    DispatchKeyValueInt(beam, "renderfx", 0);
    DispatchSpawn(beam);
    ActivateEntity(beam);
    SetEntityModel(beam, "sprites/laserbeam.vmt");
    SetEntPropVector(beam, Prop_Send, "m_vecEndPos", endPos);
    AcceptEntityInput(beam, "TurnOn");
}

void ClearTheBeamList()
{
    int length = g_alCurrentBeamList.Length, entity = -1;
    for (int i = 0; i < length; i++) {
        entity = g_alCurrentBeamList.Get(i);
        if (entity && IsValidEntity(entity)) {
            AcceptEntityInput(entity, "Kill");
        }
    }

    g_alCurrentBeamList.Clear();
}