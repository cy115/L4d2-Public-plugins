#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>

public void OnPluginStart()
{
    HookEvent("grenade_bounce", Event_GrenadeBounce);
}

void Event_GrenadeBounce(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && client <= MaxClients && IsClientInGame(client)) {
        int entity = -1;
        while ((entity = FindEntityByClassname(entity, "pipe_bomb_projectile")) != -1) {
            if (GetEntPropEnt(entity, Prop_Data, "m_hThrower") == client) {
                SetEntProp(entity, Prop_Data, "m_takedamage", 2);
                SDKHooks_TakeDamage(entity, client, client, 100.0);
            }
        }
    }
}