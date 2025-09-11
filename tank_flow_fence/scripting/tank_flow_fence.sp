#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <readyup>
#include <l4d_boss_vote>
#include <l4d2_boss_percents>

#define SPRITE_MATERIAL "materials/sprites/laserbeam.vmt"

int
    g_sprite,
    g_iCurrentIndex;

float
    g_fTargetFlow,
    g_fVersusBossBuffer,
    g_fMaxFlowDistance;

ArrayList
    g_alTriggerNavList[2],
    g_alNavList;

public Plugin myinfo =
{
    name = "Tank Flow Fence",
    author = "Hitomi",
    description = "触发坦克生成地的栅栏",
    version = "1.0",
    url = "https://github.com/cy115/"
};

public void OnMapStart()
{
    g_iCurrentIndex = 0;
    g_fMaxFlowDistance = L4D2Direct_GetMapMaxFlowDistance();
    g_sprite = PrecacheModel(SPRITE_MATERIAL, true);
    RequestFrame(PrecacheNavList);
    CreateTimer(1.0, Timer_DrawBossTriggerField, _, TIMER_REPEAT);
}

public void OnPluginStart()
{
    FindConVar("sv_multiplayer_maxtempentities").SetInt(512);
    g_alNavList = new ArrayList();
    g_alTriggerNavList[0] = new ArrayList(3);
    g_alTriggerNavList[1] = new ArrayList(3);
    g_fVersusBossBuffer = FindConVar("versus_boss_buffer").FloatValue;
    g_iCurrentIndex = 0;
    HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);
}

void RoundStartEvent(Event event, const char[] name, bool dontBroadcast) {
    if (!GameRules_GetProp("m_bInSecondHalfOfRound"))
	    CreateTimer(10.0, AdjustBossFlow, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action AdjustBossFlow(Handle timer)
{
    g_alTriggerNavList[0].Clear();
    g_alTriggerNavList[1].Clear();
    g_fTargetFlow = float(GetStoredTankPercent()) / 100;
    PrintToServer("开始查找流程值为 %.2f 的nav区域...", g_fTargetFlow);
    g_iCurrentIndex = 0;
    RequestFrame(ProcessNavAreasFrame);

    return Plugin_Stop;
}

public void OnUpdateBosses(int iTankFlow, int iWitchFlow)
{
    g_alTriggerNavList[0].Clear();
    g_alTriggerNavList[1].Clear();
    g_fTargetFlow = float(iTankFlow) / 100;
    PrintToServer("开始查找流程值为 %.2f 的nav区域...", g_fTargetFlow);
    g_iCurrentIndex = 0;
    RequestFrame(ProcessNavAreasFrame);
}

Action Timer_DrawBossTriggerField(Handle timer)
{
    if (!L4D2Direct_GetVSTankToSpawnThisRound(GameRules_GetProp("m_bInSecondHalfOfRound"))) {
        return Plugin_Continue;
    }

    static int length1, length2;
    length1 = g_alTriggerNavList[0].Length, length2 = g_alTriggerNavList[1].Length;
    if (!length1 || !length2 || length1 != length2) {
        return Plugin_Continue;
    }

    static float vPos[3], vPosPlus[3];
    for (int i = 0; i < length1; i++) {
        g_alTriggerNavList[0].GetArray(i, vPos);
        g_alTriggerNavList[1].GetArray(i, vPosPlus);
        DrawAreaField(vPos, vPosPlus, 1.0);
    }

    return Plugin_Continue;
}

public void OnPluginEnd()
{
    delete g_alNavList;
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
                g_alTriggerNavList[0].PushArray(vPos);
                g_alTriggerNavList[1].PushArray(vPosPlus);
                // DrawAreaField(vPos, vPosPlus);
                PrintToServer("找到匹配的nav区域 #%d: 流程值 %.2f, 位置 (%.0f, %.0f, %.0f)", i, flow, vPos[0], vPos[1], vPos[2]);
                PrintToServer("尺寸 (%.1f, %.1f, %.1f)", vPosPlus[0], vPosPlus[1], vPosPlus[2]);
            }
        }
        
        processed++;
        g_iCurrentIndex++;
    }
    
    // 如果还有剩余的nav区域需要处理，继续下一帧
    if (g_iCurrentIndex < length) {
        RequestFrame(ProcessNavAreasFrame);
        // 每处理一定数量后显示进度
        if (g_iCurrentIndex % 500 == 0) {
            PrintToServer("处理进度: %d/%d (%.1f%%)", g_iCurrentIndex, length, float(g_iCurrentIndex) / float(length) * 100.0);
        }
    }
    else {
        PrintToServer("导航区域处理完成！总共处理了 %d 个区域", length);
        g_iCurrentIndex = 0; // 重置索引
    }
}

stock void DrawAreaField(const float center[3], const float size[3], float life = 1.0)
{
    float height[2][3];
    height[0] = center;
    height[1] = center;
    height[1][2] += 20.0;
    DrawBeamBetweenPoints(height[0], height[1], life);
    // 画矩形nav，会导致choke，慎用
    // 计算矩形的四个角点
    /*
    float halfWidth = size[0] / 2.0, halfLength = size[1] / 2.0;
    float corners[4][3];
    // 左下角
    corners[0][0] = center[0] - halfWidth;
    corners[0][1] = center[1] - halfLength;
    corners[0][2] = center[2];
    // 右下角
    corners[1][0] = center[0] + halfWidth;
    corners[1][1] = center[1] - halfLength;
    corners[1][2] = center[2];
    // 右上角
    corners[2][0] = center[0] + halfWidth;
    corners[2][1] = center[1] + halfLength;
    corners[2][2] = center[2];
    // 左上角
    corners[3][0] = center[0] - halfWidth;
    corners[3][1] = center[1] + halfLength;
    corners[3][2] = center[2];
    
    // 绘制矩形的四条边
    DrawBeamBetweenPoints(corners[0], corners[1], life); // 底边
    DrawBeamBetweenPoints(corners[1], corners[2], life); // 右边
    DrawBeamBetweenPoints(corners[2], corners[3], life); // 顶边
    DrawBeamBetweenPoints(corners[3], corners[0], life); // 左边
    */
    // 可选：绘制对角线，更清楚地显示区域
    // DrawBeamBetweenPoints(corners[0], corners[2]); // 左下到右上
    // DrawBeamBetweenPoints(corners[1], corners[3]); // 右下到左上
}

stock void DrawBeamBetweenPoints(const float start[3], const float end[3], float life = 1.0)
{
    // 创建临时光束
    TE_SetupBeamPoints(start, end, g_sprite, 0, 0, 0, life, 1.0, 1.0, 1, 0.0, {0, 255, 0, 255}, 0);
    TE_SendToAll();
}

stock void CreateBeam(const float vecPos[3])
{
    int entity = CreateEntityByName("beam_spotlight");
    DispatchKeyValue(entity, "targetname", "l4d_random_beam_item");
    DispatchKeyValue(entity, "spawnflags", "3");
    DispatchKeyValue(entity, "rendercolor", "0 0 255");
    DispatchKeyValueFloat(entity, "SpotlightLength", 25.0);
    DispatchKeyValueFloat(entity, "SpotlightWidth", 5.0);
    DispatchKeyValueFloat(entity, "HDRColorScale", 20.0);
    DispatchKeyValueVector(entity, "origin", vecPos);
    DispatchKeyValueVector(entity, "angles", {270.0 , 0.0 , 0.0});
    DispatchSpawn(entity);
    SetEntProp(entity, Prop_Send, "m_nHaloIndex", -1);
}