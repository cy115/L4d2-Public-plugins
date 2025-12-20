#pragma semicolon 1
#pragma newdecls required

#include <sourcescramble>

public Plugin myinfo =
{
    name = "Grenade Launcher No Collision With Teammates",
    author = "Hitomi",
    description = "Grenade Launcher No Collision With Teammates",
    version = "1.0",
    url = "https://github.com/cy115/"
};

public void OnPluginStart()
{
    GameData hGameData = new GameData("gl_no_collision_with_teammates");
    if (!hGameData) {
        SetFailState("Can't find gamedata file 'gl_no_collision_with_teammates.txt'.");
    }

    MemoryPatch patch = MemoryPatch.CreateFromConf(hGameData, "CGrenadeLauncher_Projectile::CollideWithTeammatesThink");
    patch.Validate();
    patch.Enable();

    delete hGameData;
}