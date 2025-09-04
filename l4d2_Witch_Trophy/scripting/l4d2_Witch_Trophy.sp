#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <l4d2util>
#include <sdkhooks>
#include <sdktools>

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define CROWN_SOUND "level/gnomeftw.wav"
#define FAILED_SOUND "player/survivor/voice/producer/laughter04.wav"

Handle witchDamageTrie				= INVALID_HANDLE;
Handle witchHarasserTrie			= INVALID_HANDLE;
Handle witchUnharassedDamageTrie	= INVALID_HANDLE;
Handle witchShotsTrie				= INVALID_HANDLE;

Handle crownForward 	= INVALID_HANDLE;
Handle drawCrownForward = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "Witch_Trophy",
	author = "Hitomi",
	description = "击杀Witch显示奖杯特效果",
	version = "1.0",
	url = "https://github.com/cy115/"
}

public void OnPluginStart()
{
	witchDamageTrie				= CreateTrie();
	witchHarasserTrie			= CreateTrie();
	witchUnharassedDamageTrie	= CreateTrie();
	witchShotsTrie				= CreateTrie();

	HookEvent("infected_hurt",			Event_InfectedHurt, EventHookMode_Post);
	HookEvent("witch_harasser_set",		Event_WitchHarasserSet, EventHookMode_Post);
	HookEvent("witch_killed",			Event_WitchKilled, EventHookMode_Post);
	HookEvent("player_death",			Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_incapacitated",	Event_Incapacitated, EventHookMode_Post);

	crownForward 		= CreateGlobalForward("Kether_OnWitchCrown", ET_Ignore, Param_Cell, Param_Cell );
	drawCrownForward	= CreateGlobalForward("Kether_OnWitchDrawCrown", ET_Ignore, Param_Cell, Param_Cell );
}

public void OnMapStart()
{
	PrecacheSound(CROWN_SOUND);
	PrecacheSound(FAILED_SOUND);
}

public void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	int entityID = GetEventInt(event, "entityid");
	if (IsWitch(entityID))
	{
		int WitchDamageCollector[MAXPLAYERS + 1];
		int WitchUnharassedDamageCollector[MAXPLAYERS + 1];
		int WitchShotsCollector[MAXPLAYERS + 1];
		bool hasHarraser = false;
		int harraserClient = -1;
		int witchID = entityID;
		char Witch_Dmg_Key[20];
		char Witch_Unharassed_Dmg_Key[20];
		char Witch_Hrasser_key[20];
		char Witch_Shots_Key[20];
		Format(Witch_Dmg_Key, sizeof(Witch_Dmg_Key), "%x_dmg", witchID);
		Format(Witch_Unharassed_Dmg_Key, sizeof(Witch_Unharassed_Dmg_Key), "%x_uh_dmg", witchID);
		Format(Witch_Hrasser_key, sizeof(Witch_Hrasser_key), "%x_harasser", witchID);
		Format(Witch_Shots_Key, sizeof(Witch_Shots_Key), "%x_shots", witchID);
		GetTrieArray(witchUnharassedDamageTrie, Witch_Unharassed_Dmg_Key, WitchUnharassedDamageCollector, sizeof(WitchUnharassedDamageCollector));
		GetTrieArray(witchDamageTrie, Witch_Dmg_Key, WitchDamageCollector, sizeof(WitchDamageCollector));
		GetTrieArray(witchShotsTrie, Witch_Shots_Key, WitchShotsCollector, sizeof(WitchShotsCollector));
		hasHarraser = GetTrieValue(witchHarasserTrie, Witch_Hrasser_key, harraserClient);

		int attackerId = GetEventInt(event, "attacker");
		int attacker = GetClientOfUserId(attackerId);
		if (IsValidClient(attacker))
		{
			int damageDone = GetEventInt(event, "amount");
			if(GetClientTeam(attacker) == TEAM_SURVIVOR)
			{
				WitchShotsCollector[attacker] += 1;
				WitchDamageCollector[attacker] += damageDone;
				SetTrieArray(witchDamageTrie, Witch_Dmg_Key, WitchDamageCollector, sizeof(WitchDamageCollector));
				SetTrieArray(witchShotsTrie, Witch_Shots_Key, WitchShotsCollector, sizeof(WitchShotsCollector));

				if(!hasHarraser)
				{
					WitchUnharassedDamageCollector[attacker] += damageDone;
					SetTrieArray(witchUnharassedDamageTrie, Witch_Unharassed_Dmg_Key, WitchUnharassedDamageCollector, sizeof(WitchUnharassedDamageCollector));
				}
			}
		}
	}
}

void Event_WitchHarasserSet(Event event, const char[] name, bool dontBroadcast)
{
	int Harasser = GetClientOfUserId(GetEventInt(event, "userid"));
	int witchID = GetEventInt(event, "witchID");
	char Witch_Hrasser_key[20];
	Format(Witch_Hrasser_key, sizeof(Witch_Hrasser_key), "%x_harasser", witchID);
	DelayedAddTrie(Witch_Hrasser_key, Harasser);
}

void DelayedAddTrie(char[] Witch_Hrasser_key, int harasser)
{
	DataPack Pack;
	CreateDataTimer(0.1, AddToTheTrie, Pack);
	Pack.WriteString(Witch_Hrasser_key);
	Pack.WriteCell(harasser);
}

Action AddToTheTrie(Handle timer, DataPack Pack)
{
	char Witch_Hrasser_key[20];
	int Harasser;
	Pack.Reset();
	Pack.ReadString(Witch_Hrasser_key, sizeof(Witch_Hrasser_key));
	Harasser = Pack.ReadCell();
	SetTrieValue(witchHarasserTrie, Witch_Hrasser_key, Harasser);
	
	return Plugin_Continue;
}

void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	int attackerUserID = GetEventInt(event, "userid");
	int attacker = GetClientOfUserId(attackerUserID);
	int witchID = GetEventInt(event, "witchID");
	int WitchUnharassedDamageCollector[MAXPLAYERS + 1];
	char Witch_Dmg_Key[20];
	char Witch_Shots_Key[20];
	char Witch_Unharassed_Dmg_Key[20];
	Format(Witch_Dmg_Key, sizeof(Witch_Dmg_Key), "%x_dmg", witchID);
	Format(Witch_Unharassed_Dmg_Key, sizeof(Witch_Unharassed_Dmg_Key), "%x_uh_dmg", witchID);
	Format(Witch_Shots_Key, sizeof(Witch_Shots_Key), "%x_shots", witchID);
	int WitchDamageCollector[MAXPLAYERS + 1];
	int WitchShotsCollector[MAXPLAYERS + 1];
	GetTrieArray(witchDamageTrie, Witch_Dmg_Key, WitchDamageCollector, sizeof(WitchDamageCollector));
	GetTrieArray(witchShotsTrie, Witch_Shots_Key, WitchShotsCollector, sizeof(WitchShotsCollector));
	bool UnharassedDmg = GetTrieArray(witchUnharassedDamageTrie, Witch_Unharassed_Dmg_Key, WitchUnharassedDamageCollector, sizeof(WitchUnharassedDamageCollector));
	bool IsOneShot = GetEventBool(event, "oneshot");
	if(IsOneShot || (WitchShotsCollector[attacker] < 9 && getTotalDamageDoneToWitchBySurvivors(witchID) == WitchDamageCollector[attacker] && !UnharassedDmg))
	{
		HandleCrown(attacker, WitchDamageCollector[attacker]);
	}
	else
	{
		if (witchID)
		{
			if(getTotalDamageDoneToWitchBySurvivors(witchID) == WitchDamageCollector[attacker] && WitchShotsCollector[attacker] < 18)
			{
				char weaponNameBuffer[128];
				GetClientWeapon(attacker, weaponNameBuffer, sizeof(weaponNameBuffer));
				if(StrContains(weaponNameBuffer, "shotgun", false) != -1)
				{
					int totalWitchDamage = getTotalDamageDoneToWitchBySurvivors(witchID) - WitchUnharassedDamageCollector[attacker];
					if(WitchDamageCollector[attacker] >= totalWitchDamage)
					{
						HandleDrawCrown(attacker, WitchDamageCollector[attacker]);
					}
				}
			}
		}
	}
}

void Event_Incapacitated(Handle event, const char[] name, bool dontBroadcast)
{
	int userId = GetEventInt(event, "userid");
	int victim = GetClientOfUserId(userId);
	int attacker = GetEventInt(event, "attackerentid");
	
	if (IsValidClient(victim) && IsWitch(attacker))
	{
		EmitSoundToAll(FAILED_SOUND, victim, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	}
}

void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int userId = GetEventInt(event, "userid");
	int victim = GetClientOfUserId(userId);
	int attacker = GetEventInt(event, "attackerentid");

	if (IsValidClient(victim) && IsWitch(attacker))
	{
		CPrintToChatAll("{blue}[{default}笑死我了{blue}] {green}%N {default}这个猪鼻秒妹不成还被妹单杀了.", victim);
	}
}

void HandleCrown(int attacker, int damage)
{
	if (IsValidClient(attacker))
	{
		DoTrophy(attacker);
	}
    
	Call_StartForward(crownForward);
	Call_PushCell(attacker);
	Call_PushCell(damage);
	Call_Finish();
}

void HandleDrawCrown(int attacker, int damage)
{
	if (IsValidClient(attacker))
	{
		DoTrophy(attacker);
	}
    
	Call_StartForward(drawCrownForward);
	Call_PushCell(attacker);
	Call_PushCell(damage);
	Call_Finish();
}

int getTotalDamageDoneToWitchBySurvivors(int witchID)
{
	int maxSurvivors = GetConVarInt(FindConVar("survivor_limit"));
	int witchDamageCollector[MAXPLAYERS + 1];
	char witch_dmg_key[20];
	Format(witch_dmg_key, sizeof(witch_dmg_key), "%x_dmg", witchID);
	GetTrieArray(witchDamageTrie, witch_dmg_key, witchDamageCollector, sizeof(witchDamageCollector));
	int OneHundredPercentDamageValue = 0;
	int survivorsTMP = 0;
	for(int client = 1; client <= MAXPLAYERS; client++)
	{
		if(IsValidClient(client))
		{
			OneHundredPercentDamageValue += witchDamageCollector[client];
			if(GetClientTeam(client) == TEAM_SURVIVOR)
			{
				survivorsTMP++;
			}
			if(survivorsTMP >= maxSurvivors)
			{
				break;
			}
		}
	}
	return OneHundredPercentDamageValue;
}

bool IsWitch(int iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}

bool IsValidClient(int client)
{
	if (client && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	else
	{
		return false;
	}
}

// 奖杯特效
void DoTrophy(int client)
{
	int Particle = CreateEntityByName("info_particle_system");
	if (Particle == -1) { return; }
	
	float Pos[3];
	GetClientAbsOrigin(client, Pos);
	
	Pos[2] += 80;
	TeleportEntity(Particle, Pos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(Particle, "effect_name", "achieved");
	DispatchKeyValue(Particle, "targetname", "particle");
	DispatchSpawn(Particle);
	ActivateEntity(Particle);
	AcceptEntityInput(Particle, "start");
	
	CreateTimer(3.0, KillParticle, EntIndexToEntRef(Particle), TIMER_FLAG_NO_MAPCHANGE);
	EmitSoundToAll(CROWN_SOUND, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	CreateTimer(2.5, KillSound);
}

Action KillParticle(Handle timer, int entRef)
{
	int entity = EntRefToEntIndex(entRef);
	if (entity > 0 && IsValidEdict(entity))
	{
		RemoveEntity(entity);
	}
	return Plugin_Stop;
}

Action KillSound(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
			StopSound(i, SNDCHAN_AUTO, CROWN_SOUND);
	
	return Plugin_Stop;
}