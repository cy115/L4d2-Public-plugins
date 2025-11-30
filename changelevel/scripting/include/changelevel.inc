#if defined _changelevel_included
 #endinput
#endif
#define _changelevel_included

/**
 * @brief Use to change level.
 *
 * @param sMapName		        Map String without .bsp.
 * @param bShouldResetScores	Reset all scores in all gamemodes.
 */
native bool ChangeLevel(const char[] sMapName, bool bResetScores = true);

/**
 * @brief Use to change level with a safe timer.
 *
 * @param fDelay		        Delay to change map.
 * @param sMapName		        Map String without .bsp.
 * @param bShouldResetScores	Reset all scores in all gamemodes.
 */
native void ChangeLevelDelay(float fDelay = 3.0, char[] sMapName = "", bool bShouldResetScores = true);

public Extension __ext_changelevel =
{
    name = "ChangeLevel",
    file = "changelevel.ext",
#if defined AUTOLOAD_EXTENSIONS
    autoload = 1,
#else
    autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public void __ext_changelevel_SetNTVOptional()
{
    MarkNativeAsOptional("ChangeLevel");
    MarkNativeAsOptional("ChangeLevelDelay");
}
#endif