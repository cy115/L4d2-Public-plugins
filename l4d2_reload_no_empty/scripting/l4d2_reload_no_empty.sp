#pragma semicolon 1
#pragma newdecls required

#include <sourcescramble>

public void OnPluginStart()
{
    GameData hGameData = new GameData("l4d2_reload_no_empty");
    if (!hGameData) {
        SetFailState("Can't not find gamedata file \"l4d2_reload_no_empty.txt\"");
    }

    MemoryPatch patch = MemoryPatch.CreateFromConf(hGameData, "CTerrorGun::Reload_NoAmmoTransfer");
    if (!patch.Validate()) {
        SetFailState("Validate patch \"CTerrorGun::Reload_NoAmmoTransfer\" failed");
    }

    if (!patch.Enable()) {
        SetFailState("Enable patch \"CTerrorGun::Reload_NoAmmoTransfer\" failed");
    }

    patch = MemoryPatch.CreateFromConf(hGameData, "CTerrorGun::Reload_NoClipClear");
    if (!patch.Validate()) {
        SetFailState("Validate patch \"CTerrorGun::Reload_NoClipClear\" failed");
    }

    if (!patch.Enable()) {
        SetFailState("Enable patch \"CTerrorGun::Reload_NoClipClear\" failed");
    }

    delete hGameData;
}