#pragma semicolon 1
#pragma newdecls required

#include <sourcescramble>

public void OnPluginStart()
{
    GameData hGameData = new GameData("l4d2_tongue_cut_pro");
    if (!hGameData) {
        SetFailState("Can't not find gamedata file \"l4d2_tongue_cut_pro.txt\"");
    }

    MemoryPatch patch = MemoryPatch.CreateFromConf(hGameData, "allow_melee_duration_tongue");
    if (!patch.Validate()) {
        SetFailState("Validate patch \"allow_melee_duration_tongue\" failed");
    }

    if (!patch.Enable()) {
        SetFailState("Enable patch \"allow_melee_duration_tongue\" failed");
    }

    delete hGameData;
}