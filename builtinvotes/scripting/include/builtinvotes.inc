/**
 * vim: set ts=4 :
 * =============================================================================
 * BuiltinVotes (C)2025 Hitomi.  All rights reserved.
 * =============================================================================
 *
 * This file is part of the BuiltinVotes addon.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#if defined _builtinvotes_included
 #endinput
#endif
#define _builtinvotes_included

/**
 * Reasons a vote can end.
 */
enum {
    BuiltinVoteEnd_Done = -1,			/**< Voting finished.  Corresponds to MenuEnd_VotingDone. */
    BuiltinVoteEnd_Cancelled = -2,		/**< Voting was cancelled.  Corresponds to MenuEnd_VotingCancelled */
}

/**
 * Vote types. These are mapped to translation strings and pass strings by VoteStart and VotePass handlers
 */
enum BuiltinVoteType {
    BuiltinVoteType_ChgCampaign = 0,	/**< L4D/L4D2: Yes/No, argument is campaign name */
    BuiltinVoteType_ReturnToLobby = 1,	/**< L4D/L4D2: Yes/No, argument ignored */
    BuiltinVoteType_ChgDifficulty = 2,	/**< L4D/L4D2: Yes/No, argument is difficulty level */
    BuiltinVoteType_Custom_YesNo = 3,	/**< Yes/No, argument is vote text. */
    BuiltinVoteType_Kick = 4,			/**< Yes/No, argument is player userid */
    BuiltinVoteType_Restart = 5,		/**< Yes/No, argument ignored */
    BuiltinVoteType_ChangeLevel = 6,	/**< Yes/No, argument is level number in L4D/L4D2 or map name in TF2 */
    BuiltinVoteType_KickIdle = 7,		/**< TF2: Yes/No, argument is player userid */
    BuiltinVoteType_KickScamming = 8,	/**< TF2: Yes/No, argument is player userid */
    BuiltinVoteType_KickCheating = 9,	/**< TF2: Yes/No, argument is player userid */
    BuiltinVoteType_NextLevel = 10,		/**< TF2: Yes/No, argument is map name */
    BuiltinVoteType_NextLevelMult = 11,	/**< TF2: Multiple-choice, argument ignored */
    BuiltinVoteType_ScrambleNow = 12,	/**< TF2: Yes/No, argument ignored */
    BuiltinVoteType_ScrambleEnd = 13,	/**< TF2: Yes/No, argument ignored */
    BuiltinVoteType_Custom_Mult = 14,	/**< TF2: Multiple-choice, argument is vote text. */
    BuiltinVoteType_Alltalk = 15,		/**< L4D2: Yes/No, argument ignored (handled internally by extension) */
}

/**
 * @brief Reasons a vote can not be called.
 *
 * These numbers are shared with the previous enum, but are split based on purpose
 * Specifically, this set can be sent to CallVoteFailed.
 */
enum BuiltinCallVoteFailReason {
    BuiltinCallVoteFail_PlayersLoading = 1,		/**< Cannot call vote while players are loading, argument ignored */
    BuiltinCallVoteFail_Recent = 2,				/**< Player called a vote recently, argument is number of seconds until player can next call a vote */
    BuiltinCallVoteFail_IssueDisabled = 5,		/**< Server has disabled that issue, argument ignored */
    BuiltinCallVoteFail_MapNotFound = 6,		/**< Map does not exist, argument ignored */
    BuiltinCallVoteFail_MapNotSpecified = 7,	/**< Player must specify a map, argument ignored */
    BuiltinCallVoteFail_RecentlyFailed = 8,		/**< This vote failed recently and players must wait to call it again, argument ignored */
    BuiltinCallVoteFail_WrongTeam = 9,			/**< Player's team cannot call this vote, argument ignored */
    BuiltinCallVoteFail_WaitingForPlayers = 10,	/**< Cannot call vote during Waiting For Players, argument ignored */
    BuiltinCallVoteFail_Unknown = 11,			/**< This reason is currently bugged, do not use, argument unknown */
    BuiltinCallVoteFail_KickAdmin = 12,			/**< Cannot kick server admin, argument ignored */
    BuiltinCallVoteFail_ScramblePending = 13,	/**< Scramble is pending; intended for scramble votes, argument ignored */
    BuiltinCallVoteFail_Spectator = 14,			/**< Spectators cannot call votes, argument ignored */
    BuiltinCallVoteFail_NextLevelSet = 15,		/**< Next level already set, argument ignored */
};

/**
 * Different actions for the vote "pump" callback
 */
enum BuiltinVoteAction {
    BuiltinVoteAction_Start = (1<<0),		/**< A vote display/sequence has started */
    BuiltinVoteAction_End = (1<<1),			/**< A vote display has fully ended. param1 is the BuiltinVoteEnd reason */
    BuiltinVoteAction_Select = (1<<2),		/**< An item was selected (param1=client, param2=item) */
    BuiltinVoteAction_Cancel = (1<<3),		/**< A vote sequence has been cancelled (nothing passed) */
    BuiltinVoteAction_VoteEnd = (1<<4),		/**< A vote sequence has ended (param1=chosen item). */
}

/** Default vote actions */
#define BUILTINVOTE_ACTIONS_DEFAULT	BuiltinVoteAction_Start|BuiltinVoteAction_Cancel|BuiltinVoteAction_End
/** All vote actions */
#define BUILTINVOTE_ACTIONS_ALL		BuiltinVoteAction:0xFFFFFFFF

#define BUILTINVOTEINFO_CLIENT_INDEX	0		/**< Client index */
#define BUILTINVOTEINFO_CLIENT_ITEM		1		/**< Item the client selected, or -1 for none */
#define BUILTINVOTEINFO_ITEM_INDEX		0		/**< Item index */
#define BUILTINVOTEINFO_ITEM_VOTES		1		/**< Number of votes for the item */

#define BUITLINVOTEFLAG_NO_REVOTES		(1<<0)	/**< Players cannot change their votes.  Revotes are not currently supported, so this flag has no effect. */

#define BUILTINVOTES_VOTE_NO			0		/**< Vote was no */
#define BUILTINVOTES_VOTE_YES			1		/**< Vote was yes */

// User vote to kick user.
#define TRANSLATION_L4D_VOTE_KICK_START					"#L4D_vote_kick_player"
#define TRANSLATION_L4D_VOTE_KICK_PASSED				"#L4D_vote_passed_kick_player"

// User vote to restart map.
#define TRANSLATION_L4D_VOTE_RESTART_START				"#L4D_vote_restart_game"
#define TRANSLATION_L4D_VOTE_RESTART_PASSED				"#L4D_vote_passed_restart_game"

// User vote to change maps.
#define TRANSLATION_L4D_VOTE_CHANGECAMPAIGN_START		"#L4D_vote_mission_change"
#define TRANSLATION_L4D_VOTE_CHANGECAMPAIGN_PASSED		"#L4D_vote_passed_mission_change"
#define TRANSLATION_L4D_VOTE_CHANGELEVEL_START			"#L4D_vote_chapter_change"
#define TRANSLATION_L4D_VOTE_CHANGELEVEL_PASSED			"#L4D_vote_passed_chapter_change"

// User vote to return to lobby.
#define TRANSLATION_L4D_VOTE_RETURNTOLOBBY_START		"#L4D_vote_return_to_lobby"
#define TRANSLATION_L4D_VOTE_RETURNTOLOBBY_PASSED		"#L4D_vote_passed_return_to_lobby"

// User vote to change difficulty.
#define TRANSLATION_L4D_VOTE_CHANGEDIFFICULTY_START		"#L4D_vote_change_difficulty"
#define TRANSLATION_L4D_VOTE_CHANGEDIFFICULTY_PASSED	"#L4D_vote_passed_change_difficulty"

// User vote to change alltalk.
#define TRANSLATION_L4D_VOTE_ALLTALK_START				"#L4D_vote_alltalk_change"
#define TRANSLATION_L4D_VOTE_ALLTALK_PASSED				"#L4D_vote_passed_alltalk_change"
#define TRANSLATION_L4D_VOTE_ALLTALK_ENABLE				"#L4D_vote_alltalk_enable"
#define TRANSLATION_L4D_VOTE_ALLTALK_DISABLE			"#L4D_vote_alltalk_disable"

// While not a vote string, it works just as well.
#define TRANSLATION_L4D_VOTE_CUSTOM						"#L4D_TargetID_Player"

/**
 * Reasons a vote was canceled.  Not used for L4D/L4D2, as they don't care
 */
enum BuiltinVoteFailReason {
    BuiltinVoteFail_Generic = 0,		/**< Vote was generically cancelled. */
    BuiltinVoteFail_Loses = 3,			/**< No votes outnumbered Yes votes */
    BuiltinVoteFail_NotEnoughVotes = 4,	/**< Vote did not receive enough votes. */
}

/**
 * Called when a vote action is completed.
 * Based on MenuHandler
 *
 * @param vote				The vote being acted upon.
 * @param action			The action of the vote.
 * @param param1			First action parameter (usually the client).
 * @param param2			Second action parameter (usually the item).
 * @noreturn
 */
typedef BuiltinVoteActionHandler = function void(Vote vote, BuiltinVoteAction action, int param1, int param2);

methodmap Vote < Handle {
    /**
     * Creates a new, empty vote.
     *
     * @param handler			Function which will receive vote actions.
     * @param voteType			Vote type, cannot be changed after set
     * @param actions			Optionally set which actions to receive.  Start,
     *							Cancel, and End will always be received regardless
     *							of whether they are set or not.  They are also
     *							the only default actions.
     * @return					A new vote Handle.
     */
    public native Vote(BuiltinVoteActionHandler handler, BuiltinVoteType voteType, BuiltinVoteAction actions = BUILTINVOTE_ACTIONS_DEFAULT);

    /**
     * Broadcasts a vote to a list of clients.  The most selected item will be
     * returned through BuiltinVoteAction_End.  On a tie, a random item will be returned
     * from a list of the tied items.
     *
     * Note that BuiltinVoteAction_End and BuiltinVoteAction_Start are both
     * default callbacks and do not need to be enabled.
     *
     * @param vote				Vote Handle.
     * @param clients			Array of clients to broadcast to.
     * @param numClients		Number of clients in the array.
     * @param time				Maximum time to leave menu on the screen.
     * @return					True on success, false if a vote is already in progress.
     * @error					Invalid Handle, or a vote is already in progress.
     */
    public native bool Display(int[] clients, int numClients, int time);

    /**
     * Appends a new item to the end of a vote.  Only valid for Multiple Choice votes
     *
     * @param vote				BuiltinVote Handle.
     * @param info				Item information string.
     * @return					True on success, false on failure.
     * @error					Invalid Handle, item limit reached, or if the vote is not multiple choice.
     */
    public native bool AddItem(const char[] info, const char[] display);

    /**
     * Inserts an item into the menu before a certain position; the new item will
     * be at the given position and all next items pushed forward.
     *
     * @param vote				Vote Handle.
     * @param position			Position, starting from 0.
     * @param info				Item information string.
     * @return					True on success, false on failure.
     * @error					Invalid Vote voteor vote position, or if the vote is not multiple choice.
     */
    public native bool InsertItem(int position, const char[] info, const char[] display);

    /**
     * Removes an item from the menu.
     *
     * @param vote				Vote Handle.
     * @param position			Position, starting from 0.
     * @return					True on success, false on failure.
     * @error					Invalid Vote voteor vote position,  or if the vote is not multiple choice.
     */
    public native bool RemoveItem(int position);

    /**
     * Removes all items from a vote.
     *
     * @param vote				Vote Handle.
     * @noreturn
     * @error					Invalid Vote voteor vote position, or if the vote is not multiple choice.
     */
    public native void RemoveAllItems();

    /**
     * Retrieves information about a vote item.
     *
     * @param vote				Vote Handle.
     * @param position			Position, starting from 0.
     * @param infoBuf			Info buffer.
     * @param infoBufLen		Maximum length of the info buffer.
     * @return					True on success, false if position is invalid.
     * @error					Invalid Handlem
     */
    public native bool GetItem(int position, char[] infoBuf, int infoBufLen, char[] dispBuf = "", int dispBufLen = 0);
    
    property int ItemCount {

        /**
         * Returns the number of items in a vote.
         *
         * @param vote				Vote Handle.
         * @return					Number of items in the vote.
         * @error					Invalid Handle.
         */
        public native get();
    }

    /**
     * Sets the vote's argument for votes that support arguments
     *
     * @param vote				Vote Handle.
     * @param argument			Argument string. See vote types for what each argument stands for.
     * @noreturn
     * @error					Invalid Handle.
     */
    public native void SetArgument(const char[] argument);

    /**
     * Returns the text of a vote's argument if set.
     *
     * @param vote				Vote Handle.
     * @param buffer			Buffer to store argument.
     * @param maxlength			Maximum length of the buffer.
     * @return					Number of bytes written.
     * @error					Invalid Handle.
     */
    public native int GetArgument(char[] buffer, int maxlength);

    property bool bIsInProgress {

        /**
         * Returns whether a BuiltinVote or game vote is in progress.
         *
         * @return					True if a BuiltinVote or game vote is in progress, false otherwise.
         */
        public native get();
    }

    property int MaxItems {

        /**
         * Returns a style's maximum items
         *
         * @return Maximum items
         */
        public native get();
    }

    property int Flags {

        /**
         * Retrieves a menu's option flags.
         *
         * NOTE: This is currently unused, but reserved for future use.
         *
         * @param vote				Builtin Vote Handle.
         * @return					A bitstring of VOTEFLAG bits.
         * @error					Invalid Handle.
         */
        public native get();

        /**
         * Sets a vote's option flags.
         *
         * If a certain bit is not supported, it will be stripped before being set.
         *
         * NOTE: This is currently unused, but reserved for future use.
         *
         * @param menu				Builtin Vote Handle.
         * @param flags				A new bitstring of VOTEFLAG bits.
         * @noreturn
         * @error					Invalid Handle.
         */
        public native set(int flags);
    }

    /**
     * Cancels the vote in progress.
     *
     * @noreturn
     * @error					If no vote is in progress.
     */
    public native void Cancel();

    /**
     * Sets an advanced vote handling callback.  If this callback is set,
     * BuiltinVoteAction_VoteEnd will not be called.
     *
     * @param vote				BuiltinVote Handle.
     * @param callback			Callback function.
     * @noreturn
     * @error					Invalid Vote voteor callback.
     */
    public native void SetResultCallback(BuiltinVoteHandler callback);

    property int Delay {

        /**
         * Returns the number of seconds you should "wait" before displaying
         * a public vote.  This number is the time remaining until
         * (last_vote + sm_vote_delay).
         *
         * @return					Number of seconds to wait, or 0 for none.
         */
        public native get();
    }

    /**
     * Returns whether a client is in the pool of clients allowed
     * to participate in the current vote.  This is determined by
     * the client list passed to DisplayBuiltinVote().
     *
     * @param client			Client index.
     * @return					True if client is allowed to vote, false otherwise.
     * @error					If no vote is in progress or client index is invalid.
     */
    public native bool IsClientInPool(int client);

    /**
     * Redraws the current vote to a client in the voting pool.
     *
     * @param client			Client index.
     * @param revotes			True to allow revotes, false otherwise.
     * @return					True on success, false if the client is in the vote pool
     *							but cannot vote again.
    * @error					No vote in progress, client is not in the voting pool,
    *							or client index is invalid.
    */
    public native bool RedrawClient(int client, bool revotes = true);

    property BuiltinVoteType Type {
        /**
         * Retrieve the vote type
         *
         * @return					The built in vote type
         * @error					Invalid Handle
         */
        public native get();
    }

    property int Team {

        /**
         * Retrieve the team this vote is for
         *
         * @return					Team index or BUILTINVOTES_ALL_TEAMS for all teams.
         * @error					Invalid Handle
         */
        public native get();

        /**
         * Set the team this vote is for, or BUILTINVOTES_ALL_TEAMS for all teams.
         *
         * Defaults to BUILTINVOTES_ALL_TEAMS if not explicitly set.
         *
         * @noreturn
         * @error					Invalid Handle
         */
        public native set(int team);
    }

    property int Initiator {

        /**
         * Retrieve the client index who initiated the vote or BUILTINVOTES_SERVER_INDEX if
         * initiated by the server itself.
         *
         * @return					Client index or BUILTINVOTES_SERVER_INDEX
         * @error					Invalid Handle
         */
        public native get();

        /**
         * Set the player who initiated the vote.
         * Use BUILTINVOTES_SERVER_INDEX if initiated by the server itself.
         *
         * Defaults to BUILTINVOTES_SERVER_INDEX if not explicitly set.
         *
         * @noreturn
         * @error					Invalid Handle
         */
        public native set(int client);
    }

    /**
     * Display vote passed screen
     *
     * You MUST call one of DisplayBuiltinVotePass, DisplayBuiltinVotePass2, or DisplayBuiltinVoteFail to hide the vote screen
     * for users who didn't vote, and to clear out their selection for the next vote.
     *
     * @param param1			Normally the item that won the vote. Also used for custom vote winners
     */
    public native void DisplayPass(char[] param1 = "");

    /**
     * Display vote passed screen with a custom type.
     *
     * A sample usage of this would be for an RTV vote pass: DisplayBuiltinVotePass2(vote, TRANSLATION_TF2_VOTE_CHANGELEVEL_PASSED, map);
     *
     * You MUST call one of DisplayBuiltinVotePass, DisplayBuiltinVotePass2, or DisplayBuiltinVoteFail to hide the vote screen
     * for users who didn't vote, and to clear out their selection for the next vote.
     *
     * @param translation		One of the translation passed constants.
     * @param param1			Normally the item that won the vote. Also used for custom vote winners
     */
    public native void DisplayPass2(char[] translation, char[] param1 = "");

    /**
     * Display failure screen.
     *
     * You MUST call one of DisplayBuiltinVotePass, DisplayBuiltinVotePass2, or DisplayBuiltinVoteFail to hide the vote screen
     * for users who didn't vote, and to clear out their selection for the next vote.
     *
     * @param reason			Vote failure reason from BuiltinVoteFailed enum
     */
    public native void DisplayFail(BuiltinVoteFailReason reason = BuiltinVoteFail_Generic);
}

/**
 * Called at the start of creating a vote, at this moment information such as argument, initiator, etc. is not available.
 * NOTE: When using this forward, you need to add a check to the plugin for the vote handle, 
 * otherwise there will be errors in the logs of the sourcemod, because the vote handle will not be set after blocking the forward.
 *
 * @param hPlugin			Handle to the plugin from which the vote was created.
 * @param sPluginName		The name of the plugin from which the vote was created.
 * @return					'Plugin_Continue' to allow voting, otherwise voting will be blocked.
 */
forward Action OnBuiltinVoteCreate(Handle hPlugin, const char[] sPluginName);

/**
 * Called when a vote is created and the vote panel has not yet been sent to the players,
 * at this moment information such as argument, initiator, etc. is available.
 *
 * @param hVote				Vote Handle.
 * @param hPlugin			Handle to the plugin from which the vote was created.
 * @param sPluginName		The saved name of the plugin from which the vote was created.
 * @return					'Plugin_Continue' to allow voting, otherwise voting will be blocked.
 */
forward Action OnBuiltinVoteStart(Vote hVote, Handle hPlugin, const char[] sPluginName);

/**
 * Creates a new, empty vote.
 *
 * @param handler			Function which will receive vote actions.
 * @param voteType			Vote type, cannot be changed after set
 * @param actions			Optionally set which actions to receive.  Start,
 *							Cancel, and End will always be received regardless
 *							of whether they are set or not.  They are also
 *							the only default actions.
 * @return					A new vote Handle.
 */
native Vote CreateBuiltinVote(BuiltinVoteActionHandler handler, BuiltinVoteType voteType, BuiltinVoteAction actions=BUILTINVOTE_ACTIONS_DEFAULT);

/**
 * Broadcasts a vote to a list of clients.  The most selected item will be
 * returned through BuiltinVoteAction_End.  On a tie, a random item will be returned
 * from a list of the tied items.
 *
 * Note that BuiltinVoteAction_End and BuiltinVoteAction_Start are both
 * default callbacks and do not need to be enabled.
 *
 * @param vote				Vote Handle.
 * @param clients			Array of clients to broadcast to.
 * @param numClients		Number of clients in the array.
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if a vote is already in progress.
 * @error					Invalid Handle, or a vote is already in progress.
 */
native bool DisplayBuiltinVote(Vote vote, int[] clients, int numClients, int time);

/**
 * Appends a new item to the end of a vote.  Only valid for Multiple Choice votes
 *
 * @param vote				BuiltinVote Handle.
 * @param info				Item information string.
 * @return					True on success, false on failure.
 * @error					Invalid Handle, item limit reached, or if the vote is not multiple choice.
 */
native bool AddBuiltinVoteItem(Vote vote, const char[] info, const char[] display);

/**
 * Inserts an item into the menu before a certain position; the new item will
 * be at the given position and all next items pushed forward.
 *
 * @param vote				Vote Handle.
 * @param position			Position, starting from 0.
 * @param info				Item information string.
 * @return					True on success, false on failure.
 * @error					Invalid Vote voteor vote position, or if the vote is not multiple choice.
 */
native bool InsertBuiltinVoteItem(Vote vote, int position, const char[] info, const char[] display);

/**
 * Removes an item from the menu.
 *
 * @param vote				Vote Handle.
 * @param position			Position, starting from 0.
 * @return					True on success, false on failure.
 * @error					Invalid Vote voteor vote position,  or if the vote is not multiple choice.
 */
native bool RemoveBuiltinVoteItem(Vote vote, int position);

/**
 * Removes all items from a vote.
 *
 * @param vote				Vote Handle.
 * @noreturn
 * @error					Invalid Vote voteor vote position, or if the vote is not multiple choice.
 */
native void RemoveAllBuiltinVoteItems(Vote vote);

/**
 * Retrieves information about a vote item.
 *
 * @param vote				Vote Handle.
 * @param position			Position, starting from 0.
 * @param infoBuf			Info buffer.
 * @param infoBufLen		Maximum length of the info buffer.
 * @return					True on success, false if position is invalid.
 * @error					Invalid Handlem
 */
native bool GetBuiltinVoteItem(Vote vote, int position, char[] infoBuf, int infoBufLen, char[] dispBuf="", int dispBufLen=0);

/**
 * Returns the number of items in a vote.
 *
 * @param vote				Vote Handle.
 * @return					Number of items in the vote.
 * @error					Invalid Handle.
 */
native int GetBuiltinVoteItemCount(Vote vote);

/**
 * Sets the vote's argument for votes that support arguments
 *
 * @param vote				Vote Handle.
 * @param argument			Argument string. See vote types for what each argument stands for.
 * @noreturn
 * @error					Invalid Handle.
 */
native void SetBuiltinVoteArgument(Vote vote, const char[] argument);

/**
 * Returns the text of a vote's argument if set.
 *
 * @param vote				Vote Handle.
 * @param buffer			Buffer to store argument.
 * @param maxlength			Maximum length of the buffer.
 * @return					Number of bytes written.
 * @error					Invalid Handle.
 */
native int GetBuiltinVoteArgument(Vote vote, char[] buffer, int maxlength);

/**
 * Returns whether a BuiltinVote or game vote is in progress.
 *
 * @return					True if a BuiltinVote or game vote is in progress, false otherwise.
 */
native bool IsBuiltinVoteInProgress();

/**
 * Returns a style's maximum items
 *
 * @return Maximum items
 */
native int GetBuiltinVoteMaxItems();

/**
 * Sets a vote's option flags.
 *
 * If a certain bit is not supported, it will be stripped before being set.
 *
 * NOTE: This is currently unused, but reserved for future use.
 *
 * @param menu				Builtin Vote Handle.
 * @param flags				A new bitstring of VOTEFLAG bits.
 * @noreturn
 * @error					Invalid Handle.
 */
native void SetBuiltinVoteOptionFlags(Vote vote, int flags);

/**
 * Retrieves a menu's option flags.
 *
 * NOTE: This is currently unused, but reserved for future use.
 *
 * @param vote				Builtin Vote Handle.
 * @return					A bitstring of VOTEFLAG bits.
 * @error					Invalid Handle.
 */
native int GetBuiltinVoteOptionFlags(Vote vote);

/**
 * Cancels the vote in progress.
 *
 * @noreturn
 * @error					If no vote is in progress.
 */
native void CancelBuiltinVote();

/**
 * Callback for when a vote has ended and results are available.
 *
 * Identical to (and thus interchangeable with) VoteHandler
 *
 * @param vote				The vote being voted on.
 * @param num_votes			Number of votes tallied in total.
 * @param num_clients		Number of clients who could vote.
 * @param client_info		Array of clients.  Use VOTEINFO_CLIENT_ defines.
 * @param num_items			Number of unique items that were selected.
 * @param item_info			Array of items, sorted by count.  Use VOTEINFO_ITEM
 *							defines.
 * @noreturn
 */
typedef BuiltinVoteHandler = function void(Vote vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info);

/**
 * Sets an advanced vote handling callback.  If this callback is set,
 * BuiltinVoteAction_VoteEnd will not be called.
 *
 * @param vote				BuiltinVote Handle.
 * @param callback			Callback function.
 * @noreturn
 * @error					Invalid Vote voteor callback.
 */
native void SetBuiltinVoteResultCallback(Vote vote, BuiltinVoteHandler callback);

/**
 * Returns the number of seconds you should "wait" before displaying
 * a public vote.  This number is the time remaining until
 * (last_vote + sm_vote_delay).
 *
 * @return					Number of seconds to wait, or 0 for none.
 */
native int CheckBuiltinVoteDelay();

/**
 * Returns whether a client is in the pool of clients allowed
 * to participate in the current vote.  This is determined by
 * the client list passed to DisplayBuiltinVote().
 *
 * @param client			Client index.
 * @return					True if client is allowed to vote, false otherwise.
 * @error					If no vote is in progress or client index is invalid.
 */
native bool IsClientInBuiltinVotePool(int client);

/**
 * Redraws the current vote to a client in the voting pool.
 *
 * @param client			Client index.
 * @param revotes			True to allow revotes, false otherwise.
 * @return					True on success, false if the client is in the vote pool
 *							but cannot vote again.
 * @error					No vote in progress, client is not in the voting pool,
 *							or client index is invalid.
 */
native bool RedrawClientBuiltinVote(int client, bool revotes=true);

/**
 * Retrieve the vote type
 *
 * @return					The built in vote type
 * @error					Invalid Handle
 */
native BuiltinVoteType GetBuiltinVoteType(Vote vote);

/**
 * Set the team this vote is for, or BUILTINVOTES_ALL_TEAMS for all teams.
 *
 * Defaults to BUILTINVOTES_ALL_TEAMS if not explicitly set.
 *
 * @noreturn
 * @error					Invalid Handle
 */
native void SetBuiltinVoteTeam(Vote vote, int team);

/**
 * Retrieve the team this vote is for
 *
 * @return					Team index or BUILTINVOTES_ALL_TEAMS for all teams.
 * @error					Invalid Handle
 */
native int GetBuiltinVoteTeam(Vote vote);

/**
 * Set the player who initiated the vote.
 * Use BUILTINVOTES_SERVER_INDEX if initiated by the server itself.
 *
 * Defaults to BUILTINVOTES_SERVER_INDEX if not explicitly set.
 *
 * @noreturn
 * @error					Invalid Handle
 */
native void SetBuiltinVoteInitiator(Vote vote, int client);

/**
 * Retrieve the client index who initiated the vote or BUILTINVOTES_SERVER_INDEX if
 * initiated by the server itself.
 *
 * @return					Client index or BUILTINVOTES_SERVER_INDEX
 * @error					Invalid Handle
 */
native int GetBuiltinVoteInitiator(Vote vote);

/**
 * Display vote passed screen
 *
 * You MUST call one of DisplayBuiltinVotePass, DisplayBuiltinVotePass2, or DisplayBuiltinVoteFail to hide the vote screen
 * for users who didn't vote, and to clear out their selection for the next vote.
 *
 * @param param1			Normally the item that won the vote. Also used for custom vote winners
 */
native void DisplayBuiltinVotePass(Vote vote, char[] param1="");

/**
 * Display vote passed screen with a custom type.
 *
 * A sample usage of this would be for an RTV vote pass: DisplayBuiltinVotePass2(vote, TRANSLATION_TF2_VOTE_CHANGELEVEL_PASSED, map);
 *
 * You MUST call one of DisplayBuiltinVotePass, DisplayBuiltinVotePass2, or DisplayBuiltinVoteFail to hide the vote screen
 * for users who didn't vote, and to clear out their selection for the next vote.
 *
 * @param translation		One of the translation passed constants.
 * @param param1			Normally the item that won the vote. Also used for custom vote winners
 */
native void DisplayBuiltinVotePass2(Vote vote, char[] translation, char[] param1="");

/**
 * Display failure screen.
 *
 * You MUST call one of DisplayBuiltinVotePass, DisplayBuiltinVotePass2, or DisplayBuiltinVoteFail to hide the vote screen
 * for users who didn't vote, and to clear out their selection for the next vote.
 *
 * @param reason			Vote failure reason from BuiltinVoteFailed enum
 */
native void DisplayBuiltinVoteFail(Vote vote, BuiltinVoteFailReason reason=BuiltinVoteFail_Generic);

/**
 * Quick stock to determine whether voting is allowed.  This doesn't let you
 * fine-tune a reason for not voting, so it's not recommended for lazily
 * telling clients that voting isn't allowed.
 * Checks if a game or builtinvote vote is in progress
 *
 * @return				True if voting is allowed, false if voting is in progress
 *						or the cooldown is active.
 */
stock bool IsNewBuiltinVoteAllowed() {
    return (!(IsBuiltinVoteInProgress() || CheckBuiltinVoteDelay() != 0));
}

/**
 * Retrieves voting information from BuiltinVoteAction_VoteEnd.
 *
 * @param param2		Second parameter of BuiltinVoteAction_VoteEnd.
 * @param winningVotes	Number of votes received by the winning option.
 * @param totalVotes	Number of total votes received.
 * @noreturn
 */
stock void GetBuiltinVoteInfo(int param2, int &winningVotes, int &totalVotes) {
    winningVotes = param2 & 0xFFFF;
    totalVotes = param2 >> 16;
}

/**
 * Do not edit below this line!
 */
public Extension __ext_builtinvotes =
{
    name = "BuiltinVotes",
    file = "builtinvotes.ext",
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
public void __ext_builtinvotes_SetNTVOptional()
{
    MarkNativeAsOptional("CreateBuiltinVote");
    MarkNativeAsOptional("DisplayBuiltinVote");
    MarkNativeAsOptional("AddBuiltinVoteItem");
    MarkNativeAsOptional("InsertBuiltinVoteItem");
    MarkNativeAsOptional("RemoveBuiltinVoteItem");
    MarkNativeAsOptional("RemoveAllBuiltinVoteItems");
    MarkNativeAsOptional("GetBuiltinVoteItem");
    MarkNativeAsOptional("GetBuiltinVoteItemCount");
    MarkNativeAsOptional("SetBuiltinVoteArgument");
    MarkNativeAsOptional("GetBuiltinVoteArgument");
    MarkNativeAsOptional("IsBuiltinVoteInProgress");
    MarkNativeAsOptional("GetBuiltinVoteMaxItems");
    MarkNativeAsOptional("SetBuiltinVoteOptionFlags");
    MarkNativeAsOptional("GetBuiltinVoteOptionFlags");
    MarkNativeAsOptional("CancelBuiltinVote");
    MarkNativeAsOptional("SetBuiltinVoteResultCallback");
    MarkNativeAsOptional("CheckBuiltinVoteDelay");
    MarkNativeAsOptional("IsClientInBuiltinVotePool");
    MarkNativeAsOptional("RedrawClientBuiltinVote");
    MarkNativeAsOptional("GetBuiltinVoteType");
    MarkNativeAsOptional("SetBuiltinVoteTeam");
    MarkNativeAsOptional("GetBuiltinVoteTeam");
    MarkNativeAsOptional("SetBuiltinVoteInitiator");
    MarkNativeAsOptional("GetBuiltinVoteInitiator");
    MarkNativeAsOptional("DisplayBuiltinVotePass");
    MarkNativeAsOptional("DisplayBuiltinVotePass2");
    MarkNativeAsOptional("DisplayBuiltinVoteFail");

    MarkNativeAsOptional("Vote.Vote");
    MarkNativeAsOptional("Vote.Display");
    MarkNativeAsOptional("Vote.AddItem");
    MarkNativeAsOptional("Vote.InsertItem");
    MarkNativeAsOptional("Vote.RemoveItem");
    MarkNativeAsOptional("Vote.RemoveAllItems");
    MarkNativeAsOptional("Vote.GetItem");
    MarkNativeAsOptional("Vote.ItemCount.get");
    MarkNativeAsOptional("Vote.SetArgument");
    MarkNativeAsOptional("Vote.GetArgument");
    MarkNativeAsOptional("Vote.IsInProgress.get");
    MarkNativeAsOptional("Vote.MaxItems.get");
    MarkNativeAsOptional("Vote.Flags.get");
    MarkNativeAsOptional("Vote.Flags.set");
    MarkNativeAsOptional("Vote.Cancel");
    MarkNativeAsOptional("Vote.SetResultCallback");
    MarkNativeAsOptional("Vote.Delay.get");
    MarkNativeAsOptional("Vote.IsClientInPool");
    MarkNativeAsOptional("Vote.RedrawClient");
    MarkNativeAsOptional("Vote.Type.get");
    MarkNativeAsOptional("Vote.Team.set");
    MarkNativeAsOptional("Vote.Team.get");
    MarkNativeAsOptional("Vote.Initiator.set");,
    MarkNativeAsOptional("Vote.Initiator.get");,
    MarkNativeAsOptional("Vote.DisplayPass");
    MarkNativeAsOptional("Vote.DisplayPass2");,
    MarkNativeAsOptional("Vote.DisplayFail");
}
#endif
