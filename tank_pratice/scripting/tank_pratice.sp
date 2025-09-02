#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

int
    propCount = 0,
    propRefs[2048];

float
    propPos[2048][3],
    propAng[2048][3];

ConVar
    z_frustration;

public Plugin myinfo =
{
    name = "L4D2 pratice",
    author = "Hitomi",
    description = "练...",
    version = "1.0",
    url = "https://github.com/cy115/"
};

public void OnPluginStart()
{
    z_frustration = FindConVar("z_frustration");
    SetConVarInt(z_frustration, 0);

    RegConsoleCmd("sm_tk", Cmd_TankMenu);

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void OnPluginEnd()
{
    SetConVarInt(z_frustration, 1);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    CreateTimer(10.0, getTankPropHandler, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Cmd_TankMenu(int client, int args)
{
    if (!IsValidClient(client) || GetClientTeam(client) != 3) {
        return Plugin_Handled;
    }

    ShowMenu(client);

    return Plugin_Handled;
}

void ShowMenu(int client)
{
    Menu menu = new Menu(TankMenu_Handler);
    menu.SetTitle("坦克练习面板");
    menu.AddItem("a", "变成坦克");
    menu.AddItem("b", "开关穿墙");
    menu.AddItem("c", "道具复原");

    menu.Display(client, MENU_TIME_FOREVER);
}

int TankMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action) {
        case MenuAction_Select: {
            char item[2];
            menu.GetItem(param2, item, sizeof(item));
            switch (item[0]) {
                case 'a': SetClientTank(param1);
                case 'b': ToggleClientNoclip(param1);
                case 'c': ResetAllHittable();
            }

            ShowMenu(param1);
        }
    }

    return 0;
}

void SetClientTank(int client)
{
    if (GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") != 8 
        && !view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"))) {
        L4D2Direct_SetTankTickets(client, 20000);
        CheatCommand(client, "z_spawn", "tank"); 
    }
}

void ToggleClientNoclip(int client)
{
    MoveType mt = GetEntityMoveType(client);
    if (mt == MOVETYPE_NOCLIP) {
        SetEntityMoveType(client, MOVETYPE_WALK);
    }
    else {
        SetEntityMoveType(client, MOVETYPE_NOCLIP);
    }
}

void ResetAllHittable()
{
    int i, ent;
    for (i = 0; i < propCount; i++) {
        ent = EntRefToEntIndex(propRefs[i]);
        if (!IsValidEntity(ent))
            continue;

        TeleportEntity(ent, propPos[i], propAng[i], {0.0, 0.0, 0.0});
    }
}

Action getTankPropHandler(Handle timer)
{
    int i, index = 0;
    float pos[3], ang[3];
    for (i = MaxClients + 1; i < GetEntityCount(); i++) {
        if (!IsValidEntity(i)) {
            continue;
        }

        if (!L4D2_IsTankPropPro(i)) {
            continue;
        }

        GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
        GetEntPropVector(i, Prop_Send, "m_angRotation", ang);
        propRefs[index] = EntIndexToEntRef(i);
        CopyVectors(pos, propPos[index]);
        CopyVectors(ang, propAng[index++]);
        propCount += 1;
    }

    return Plugin_Stop;
}

bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock void CheatCommand(int client, const char[] command, const char[] arguments)
{
    int admindata = GetUserFlagBits(client);
    SetUserFlagBits(client, ADMFLAG_ROOT);
    int flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
    SetUserFlagBits(client, admindata);
}

stock bool L4D2_IsTankPropPro(int entity)
{
    static char classname[16];
    GetEdictClassname(entity, classname, sizeof(classname));
    if (strcmp(classname, "prop_physics") == 0) {
        if (GetEntProp(entity, Prop_Send, "m_hasTankGlow")) {
            return true;
        }
    }
    else if (strcmp(classname, "prop_car_alarm") == 0) {
        return true;
    }

    return false;
}

stock void CopyVectors(float origin[3], float result[3])
{
    result[0] = origin[0];
    result[1] = origin[1];
    result[2] = origin[2];
}