#pragma semicolon 1
#pragma newdecls required

#include <dhooks>

enum {
    WEPID_NONE,             // 0
    WEPID_PISTOL,           // 1
    WEPID_SMG,              // 2
    WEPID_PUMPSHOTGUN,      // 3
    WEPID_AUTOSHOTGUN,      // 4
    WEPID_RIFLE,            // 5
    WEPID_HUNTING_RIFLE,    // 6
    WEPID_SMG_SILENCED,     // 7
    WEPID_SHOTGUN_CHROME,   // 8
    WEPID_RIFLE_DESERT,     // 9
    WEPID_SNIPER_MILITARY,  // 10
    WEPID_SHOTGUN_SPAS,     // 11
    WEPID_FIRST_AID_KIT,    // 12
    WEPID_MOLOTOV,          // 13
    WEPID_PIPE_BOMB,        // 14
    WEPID_PAIN_PILLS,       // 15
    WEPID_GASCAN,           // 16
    WEPID_PROPANE_TANK,     // 17
    WEPID_OXYGEN_TANK,      // 18
    WEPID_MELEE,            // 19
    WEPID_CHAINSAW,         // 20
    WEPID_GRENADE_LAUNCHER, // 21
    WEPID_AMMO_PACK,        // 22
    WEPID_ADRENALINE,       // 23
    WEPID_DEFIBRILLATOR,    // 24
    WEPID_VOMITJAR,         // 25
    WEPID_RIFLE_AK47,       // 26
    WEPID_GNOME_CHOMPSKI,   // 27
    WEPID_COLA_BOTTLES,     // 28
    WEPID_FIREWORKS_BOX,    // 29
    WEPID_INCENDIARY_AMMO,  // 30
    WEPID_FRAG_AMMO,        // 31
    WEPID_PISTOL_MAGNUM,    // 32
    WEPID_SMG_MP5,          // 33
    WEPID_RIFLE_SG552,      // 34
    WEPID_SNIPER_AWP,       // 35
    WEPID_SNIPER_SCOUT,     // 36
    WEPID_RIFLE_M60,        // 37
    WEPID_TANK_CLAW,        // 38
    WEPID_HUNTER_CLAW,      // 39
    WEPID_CHARGER_CLAW,     // 40
    WEPID_BOOMER_CLAW,      // 41
    WEPID_SMOKER_CLAW,      // 42
    WEPID_SPITTER_CLAW,     // 43
    WEPID_JOCKEY_CLAW,      // 44
    WEPID_MACHINEGUN,       // 45
    WEPID_VOMIT,            // 46
    WEPID_SPLAT,            // 47
    WEPID_POUNCE,           // 48
    WEPID_LOUNGE,           // 49
    WEPID_PULL,             // 50
    WEPID_CHOKE,            // 51
    WEPID_ROCK,             // 52
    WEPID_PHYSICS,          // 53
    WEPID_AMMO,             // 54
    WEPID_UPGRADE_ITEM,     // 55

    WEPID_SIZE //56 size
};

stock const char WeaponNames[WEPID_SIZE][] = {
    "none", "pistol", "smg",                                            // 0
    "pumpshotgun", "autoshotgun", "rifle",                              // 3
    "hunting_rifle", "smg_silenced", "shotgun_chrome",                  // 6
    "rifle_desert", "sniper_military", "shotgun_spas",                  // 9
    "first_aid_kit", "molotov", "pipe_bomb",                            // 12
    "pain_pills", "gascan", "propanetank",                              // 15
    "oxygentank", "melee", "chainsaw",                                  // 18
    "grenade_launcher", "ammo_pack", "adrenaline",                      // 21
    "defibrillator", "vomitjar", "rifle_ak47",                          // 24
    "gnome", "cola_bottles", "fireworkcrate",                           // 27
    "upgradepack_incendiary", "upgradepack_explosive", "pistol_magnum", // 30
    "smg_mp5", "rifle_sg552", "sniper_awp",                             // 33
    "sniper_scout", "rifle_m60", "tank_claw",                           // 36
    "hunter_claw", "charger_claw", "boomer_claw",                       // 39
    "smoker_claw", "spitter_claw", "jockey_claw",                       // 42
    "machinegun", "vomit", "splat",                                     // 45
    "pounce", "lounge", "pull",                                         // 48
    "choke", "rock", "physics",                                         // 51
    "ammo", "upgrade_item"                                              // 54
};

bool
    g_bEnableWeapon[WEPID_SIZE] = {false, ...};

float
    g_fPunch[WEPID_SIZE][3];

static
    StringMap hWeaponNamesTrie = null;

public void OnPluginStart()
{
    GameData hGameData = new GameData("l4d2_set_punchangle");
    DynamicDetour hDetour = DynamicDetour.FromConf(hGameData, "CY115::CBasePlayer::SetPunchAngle");
    hDetour.Enable(Hook_Pre, SetVerticlePunchTest);
    delete hDetour;
    delete hGameData;
    // sm_setweaponpunchangle hunting_rifle -5 0 0  开枪向上仰
    // sm_setweaponpunchangle hunting_rifle 5 0 0   开枪向下沉
    RegServerCmd("sm_setweaponpunchangle", SrvCmd_SetPunchAngle);
}

Action SrvCmd_SetPunchAngle(int args)
{
    if (args != 4) {
        return Plugin_Handled;
    }

    char sWeaponName[32];
    GetCmdArg(1, sWeaponName, sizeof(sWeaponName));
    int iWeaponID = WeaponNameToId(sWeaponName);
    if (iWeaponID < WEPID_NONE || iWeaponID >= WEPID_SIZE) {
        return Plugin_Handled;
    }

    g_bEnableWeapon[iWeaponID] = true;
    for (int i = 0; i < 3; i++) {
        g_fPunch[iWeaponID][i] = GetCmdArgFloat(i + 2);
    }

    return Plugin_Handled;
}

MRESReturn SetVerticlePunchTest(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    if (GetClientTeam(pThis) != 2 || !IsPlayerAlive(pThis) || hParams.IsNull(1)) {
        return MRES_Ignored;
    }

    int iWeaponID = IdentifyWeapon(GetEntPropEnt(pThis, Prop_Send, "m_hActiveWeapon"));
    PrintToServer("%i", iWeaponID);
    if (g_bEnableWeapon[iWeaponID]) {
        hParams.SetVector(1, g_fPunch[iWeaponID]);
        return MRES_ChangedHandled;
    }

    return MRES_Ignored;
}

int IdentifyWeapon(int entity)
{
    if (!entity || !IsValidEntity(entity) || !IsValidEdict(entity)) {
        return WEPID_NONE;
    }

    char class[64];
    if (!GetEdictClassname(entity, class, sizeof(class))) {
        return WEPID_NONE;
    }

    ReplaceString(class, sizeof(class), "weapon_", "");

    return WeaponNameToId(class);
}

int WeaponNameToId(const char[] weaponName)
{
    if (hWeaponNamesTrie == null) {
        InitWeaponNamesTrie();
    }

    int id;
    if (hWeaponNamesTrie.GetValue(weaponName, id)) {
        return id;
    }

    return WEPID_NONE;
}

void InitWeaponNamesTrie()
{
    hWeaponNamesTrie = new StringMap();

    for (int i = 0; i < WEPID_SIZE; i++) {
        hWeaponNamesTrie.SetValue(WeaponNames[i], i);
    }
}