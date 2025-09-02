# l4d2_new_generation_scoremod

**-------------------------------------------------------------------**
**----------Introduce of new generation sourcemod-----------**
**-------------------------------------------------------------------**

## ========== Main Parts ==========

### The score system Includes six parts:

1. Map Distance Bonus;
2. Permanent Health Bonus;
3. Damage Bonus;
4. Great Skill Bonus;
5. Pills Bonus;
6. Condition(When survivors made it to saferoom) Bonus.

## ========== Per Parts ==========

- Map Distance Bonus:
  - Comes from map value "VersusMaxCompletionScore"
  - Divided by survivor team size, and plus teamsize(g_iMapDistance)
- Permanent Health Bonus:
  - One basic evidence of surviors's power, come form survior's Permanent health
  - Once survivor incapacitate, his Bonus decrease to 0
- Damage Bonus:
  - Now the damage bonus is more reliable then the origin one which make survivors lose almost all bonus after a player died and lead to hope even more remote
- Great Skill Bonus:
  - This part of bonus depend on "l4d2_skill_detect"
  - When survivors make nice skill they will get SB(skill bonus) until it comes to the cap, and infected can also do skill to deduct surs' SB
  - It's a positive part to encourage player to do brave things and make the match even more breathtaking
- Pills Bonus:
  - It's the same as origin pills bonus
  - Per pills equal distance bonuse divided by 20
  - Maybe I will update next time to calculate the pills on the map survivors never find
- Condition Bonus:
  - Just a consolation prize for survivors so they may not get a "0" when made it to saferoom after hardships
  - And it's another way to adjust player's skill to protect their health at inevitable scenes
