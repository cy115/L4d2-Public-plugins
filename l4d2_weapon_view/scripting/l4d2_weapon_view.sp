#pragma semicolon 1
#pragma newdecls required

#include <left4dhooks>

public void OnPluginStart()
{
    RegConsoleCmd("sm_anim",Cmd_AnimHookSet);
}

Action Cmd_AnimHookSet(int client, int args)
{
    int active_weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
    if (active_weapon == -1) {
        return Plugin_Handled;
    }

    int sequence = GetWeaponSequence(active_weapon);
    SetEntProp(GetEntPropEnt(client, Prop_Send, "m_hViewModel") , Prop_Send, "m_nLayerSequence", sequence);

    return Plugin_Continue;
}

int GetWeaponSequence(int weapon) {
    L4D2WeaponId wepid = L4D2_GetWeaponId(weapon);
    switch (wepid) {
        case L4D2WeaponId_Pistol: return GetEntProp(weapon, Prop_Send, "m_isDualWielding") ? 29 : 23;
        case L4D2WeaponId_PistolMagnum: return 23;
        case L4D2WeaponId_Smg: return 20;
        case L4D2WeaponId_SmgSilenced: return 20;
        case L4D2WeaponId_SmgMP5: return 24;
        case L4D2WeaponId_Pumpshotgun: return 24;
        case L4D2WeaponId_ShotgunChrome: return 24;
        case L4D2WeaponId_Rifle: return 20;
        case L4D2WeaponId_RifleDesert: return 20;
        case L4D2WeaponId_RifleAK47: return 20;
        case L4D2WeaponId_RifleSG552: return 24;
        case L4D2WeaponId_RifleM60: return 20;
        case L4D2WeaponId_HuntingRifle: return 24;
        case L4D2WeaponId_SniperAWP: return 20;
        case L4D2WeaponId_SniperMilitary: return 13;
        case L4D2WeaponId_SniperScout: return 20;
        case L4D2WeaponId_GrenadeLauncher: return 19;
        case L4D2WeaponId_ShotgunSpas: return 24;
        case L4D2WeaponId_Autoshotgun: return 24;
        case L4D2WeaponId_Melee: return 20;
    }

    return -1;
}