#pragma semicolon 1
#pragma newdecls required

#include <sourcescramble>

public Plugin myinfo =
{
    name = "[L4D2] SG552 Rate of Fire Patch",
    author = "Hitomi",
    description = "Restore normal rate of fire on scoping.",
    version = "1.0",
    url = "https://github.com/cy115/"
};

MemoryPatch
    g_mpSG552ZoomPatch;

public void OnPluginStart()
{
    GameData hGameData = new GameData("l4d2_sg552_firerate_patch");
    if (!hGameData) {
        SetFailState("Missing gamedata \"l4d2_sg552_firerate_patch\".");
    }

    g_mpSG552ZoomPatch = MemoryPatch.CreateFromConf(hGameData, "sg552_get_rate_of_fire");
    if (!g_mpSG552ZoomPatch.Validate()) {
        SetFailState("Can't validate \"l4d2_sg552_firerate_patch\".");
    }

    if (!g_mpSG552ZoomPatch.Enable()) {
        SetFailState("Can't patch \"l4d2_sg552_firerate_patch\".");
    }

    delete hGameData;
}

public void OnPluginEnd()
{
    g_mpSG552ZoomPatch.Disable();
    delete g_mpSG552ZoomPatch;
}