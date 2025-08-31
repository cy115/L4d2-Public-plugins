#if defined _l4d2_new_generation_scoremod
    #endinput
#endif
#define _l4d2_new_generation_scoremod

// Get current bonus
native int NGSM_GetPermHealthBonus()
native int NGSM_GetDamageBonus()
native int NGSM_GetSkillBonus()
native int NGSM_GetPillsBonus()
native int NGSM_GetConditionBonus()
// Get Map Max bonus
native int NGSM_GetMaxPermHealthBonus()
native int NGSM_GetMaxDamageBonus()
native int NGSM_GetMaxSkillBonus()
native int NGSM_GetMaxPillsBonus()
native int NGSM_GetMaxConditionBonus()

public SharedPlugin __pl_l4d2_new_generation_scoremod = {
    name = "l4d2_new_generation_scoremod",
    file = "l4d2_new_generation_scoremod.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_new_generation_scoremod_SetNTVOptional()
{
    //=============================================//
    MarkNativeAsOptional("NGSM_GetRestBonus");
    MarkNativeAsOptional("NGSM_GetPermHealthBonus");
    MarkNativeAsOptional("NGSM_GetDamageBonus");
    MarkNativeAsOptional("NGSM_GetSkillBonus");
    MarkNativeAsOptional("NGSM_GetPillsBonus");
    MarkNativeAsOptional("NGSM_GetConditionBonus");
    //===============================================//
    MarkNativeAsOptional("NGSM_GetMaxChapterBonus");
    MarkNativeAsOptional("NGSM_GetMaxPermHealthBonus");
    MarkNativeAsOptional("NGSM_GetMaxDamageBonus");
    MarkNativeAsOptional("NGSM_GetMaxSkillBonus");
    MarkNativeAsOptional("NGSM_GetMaxPillsBonus");
    MarkNativeAsOptional("NGSM_GetMaxConditionBonus");
}
#endif