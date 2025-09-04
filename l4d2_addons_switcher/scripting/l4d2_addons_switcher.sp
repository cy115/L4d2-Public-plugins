#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <left4dhooks>

StringMap
    adminTrie;

public Plugin myinfo =
{
    name = "l4d2 addons switcher",
    author = "Hitomi",
    description = "输入神秘小代码开启mod",
    version = "1.0",
    url = "https://github.com/cy115/"
};

public void OnPluginStart()
{
    adminTrie = new StringMap();
    RegAdminCmd("sm_mod", Cmd_ToggleMod, ADMFLAG_BAN);
}

public void OnPluginEnd()
{
    adminTrie.Clear();
    delete adminTrie;
}

Action Cmd_ToggleMod(int client, int args)
{
    if (!client) {
        return Plugin_Continue;
    }

    char buffer[64];
    bool temp;
    GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));
    if (!adminTrie.GetValue(buffer, temp)) {
        adminTrie.SetValue(buffer, true);
        CPrintToChat(client, "{blue}神秘小代码已启动, 快重新进游戏乱杀吧!");
    }
    else {
        adminTrie.Remove(buffer);
        CPrintToChat(client, "{red}你接受了自己的平庸, 发现科技没法拯救中国.");
    }

    return Plugin_Handled;
}

public Action L4D2_OnClientDisableAddons(const char[] steamID)
{
    return IsIDAdmin(steamID) ? Plugin_Handled : Plugin_Continue;
}

stock bool IsIDAdmin(const char[] AuthID)
{
    bool dummy;
    return GetTrieValue(adminTrie, AuthID, dummy);
}