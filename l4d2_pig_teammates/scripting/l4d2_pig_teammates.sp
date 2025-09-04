#pragma semicolon 1
#pragma newdecls required

#include <left4dhooks>
#include <colors>

int
    g_iShover[33];

float
    g_fBoomerShoved[33];

public Plugin myinfo =
{
    name = "Your Pig Teammates",
    author = "Hitomi",
    description = "你的铸币队友骚操作",
    version = "1.2",
    url = "https://github.com/cy115/"
};

public void OnPluginStart()
{
    // HookEvents
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_shoved", Event_PlayerShoved);
}

public void OnClientPutInServer(int client)
{
    g_fBoomerShoved[client] = 0.0;
}

// Events
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int
        attacker = GetClientOfUserId(event.GetInt("attacker")),
        victim = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidInfected(victim) || !IsValidClientIndex(attacker)) {
        return;
    }

    switch (GetClientTeam(attacker)) {
        case 2: {
            int iZombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
            switch (iZombieClass) {
                case 2: {   // why you instance shoot the boomer i just shove away?
                    if (g_fBoomerShoved[victim] > GetGameTime() && g_iShover[victim] && attacker != g_iShover[victim]) {
                        CPrintToChatAll("{red}Idiot survivor immediately{default}[{olive}%N{default}] {red}pop the boomer {default}which just shoved by teammate.", attacker);
                        g_fBoomerShoved[victim] = 0.0;
                    }
                }
            }
        }
        case 3: {
            int iZombieClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");
            switch (iZombieClass) {
                case 8: {
                    if (GetEntProp(victim, Prop_Send, "m_zombieClass") != 8) {
                        char weapon[12], buffer[16];
                        GetEventString(event, "weapon", weapon, sizeof(weapon));
                        if (StrEqual(weapon, "tank_claw")) {
                            FormatEx(buffer, sizeof(buffer), "Punch");
                        }
                        else if (StrEqual(weapon, "tank_rock")) {
                            FormatEx(buffer, sizeof(buffer), "Rock");
                        }
                        else {
                            FormatEx(buffer, sizeof(buffer), "Hittable");
                        }

                        if (!IsFakeClient(attacker)) {
                            CPrintToChatAll("{red}Tank {default}[{olive}%N{default}] {red}Slay {default}his teammate by {red}%s{default}.", attacker, buffer);
                        }
                        else {
                            CPrintToChatAll("{red}Tank {default}[{olive}AI{default}] {red}Slay {default}his teammate by {red}%s{default}.", buffer);
                        }
                    }
                }
            }
        }
    }
}

void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int shover = GetClientOfUserId(event.GetInt("attacker"));
    if (!IsValidInfected(victim) || GetEntProp(victim, Prop_Send, "m_zombieClass") != 2 || !IsValidSurvivor(shover)) {
        return;
    }

    g_iShover[victim] = shover;
    g_fBoomerShoved[victim] = GetGameTime() + 1.0;
}

public void L4D_OnEnterGhostState(int client)
{
    if (IsValidInfected(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 2) {
        g_fBoomerShoved[client] = 0.0;
        g_iShover[client] = -1;
    }
}

// Tools
/**
 * Return true if the valid client index and is client on the survivor team.
 *
 * @param client client ID
 * @return bool
 */
stock bool IsValidSurvivor(int client)
{
	return (IsValidClientIndex(client) && GetClientTeam(client) == 2);
}

/**
 * Return true if the valid client index and is client on the infected team.
 *
 * @param client client ID
 * @return bool
 */
stock bool IsValidInfected(int client)
{
	return (IsValidClientIndex(client) && GetClientTeam(client) == 3);
}

stock bool IsValidClientIndex(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}