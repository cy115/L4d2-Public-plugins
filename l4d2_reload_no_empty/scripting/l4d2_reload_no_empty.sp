#pragma semicolon 1
#pragma newdecls required

#include <sourcescramble>

public void OnPluginStart()
{
    GameData hGameData = new GameData("l4d2_reload_no_empty");
    if (hGameData == null) {
        SetFailState("no gamedata file");
    }

    MemoryPatch patch = MemoryPatch.CreateFromConf(hGameData, "CTerrorGun::Reload_NoAmmoTransfer");
    if (!patch.Validate()) {
        SetFailState("Validate Failed");
    }

    if (!patch.Enable()) {
        SetFailState("Enable Failed");
    }

    patch = MemoryPatch.CreateFromConf(hGameData, "CTerrorGun::Reload_NoClipClear");
    if (!patch.Validate()) {
        SetFailState("Validate Failed");
    }

    if (!patch.Enable()) {
        SetFailState("Enable Failed");
    }

    delete hGameData;
}