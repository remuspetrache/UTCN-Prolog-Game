% ============================================================================
% lab10_state.pl — STUDENT FILE (STANDALONE, not loaded by any wrapper)
%
% Labs: L10 (Side Effects — assertz, retractall, findall, failure-driven loops)
% Game component: Conceptual exercises only.
%   The real game state is handled by the provided state.pl module, which uses
%   the same L10 patterns below. After completing these exercises, read
%   state.pl to see assertz/retractall used for session-scoped game state.
%
% This file is NOT included by any module wrapper and is NOT part of the
% running game. Load it directly in SWI-Prolog to practise L10 concepts:
%   ?- [lab10_state].
% ============================================================================

% ============================================================================
% EXERCISE 1 — assertz and retract  [Lab 10]
%
% Dynamic fact: score(+Player, +Points)
% Implement add_score/2 and remove_score/1 that manipulate this fact.
% ============================================================================

:- dynamic score/2.

%--------------------------------------------------
% add_score(+Player, +Points)  [Lab 10]
%
%   Assert a new score(Player, Points) fact into the Prolog database.
%   If Player already has a score, a second fact is added (duplicates allowed
%   at this stage; see update_score/2 in Exercise 3 for a cleaner approach).
%
%   ?- add_score(alice, 10), add_score(bob, 7), listing(score/2).
%   score(alice, 10).
%   score(bob, 7).

% add_score(+Player, +Points) :- % *IMPLEMENTATION HERE*

add_score(_, _) :- fail.


%--------------------------------------------------
% remove_score(+Player)  [Lab 10]
%
%   Retract the FIRST score/2 fact for Player from the database.
%   Succeeds even if no such fact exists (use retract inside a
%   conditional or use retractall — your choice).
%
%   ?- add_score(alice, 10), remove_score(alice), listing(score/2).
%   % no score/2 clauses

% remove_score(+Player) :- % *IMPLEMENTATION HERE*

remove_score(_) :- fail.


% ============================================================================
% EXERCISE 2 — findall over dynamic facts  [Lab 10]
%
% Implement all_scores/1 using findall/3.
% ============================================================================

%--------------------------------------------------
% all_scores(-List)  [Lab 10]
%
%   Collect every score/2 fact in the database into List as Player-Points pairs.
%
%   ?- add_score(alice, 10), add_score(bob, 7),
%      all_scores(L).
%   L = [alice-10, bob-7].
%
%   ?- retractall(score(_,_)), all_scores(L).
%   L = [].

% all_scores(-List) :- % *IMPLEMENTATION HERE*

all_scores(_) :- fail.


% ============================================================================
% EXERCISE 3 — retractall + idempotent assertz  [Lab 10]
%
% Implement update_score/2: replace all existing scores for a player
% with a single new one.
% ============================================================================

%--------------------------------------------------
% update_score(+Player, +NewPoints)  [Lab 10]
%
%   Remove all existing score(Player, _) facts, then assert score(Player, NewPoints).
%   The result is exactly one score/2 fact for Player.
%
%   ?- add_score(alice, 10), add_score(alice, 5),
%      update_score(alice, 20),
%      all_scores(L).
%   L = [alice-20].

% update_score(+Player, +NewPoints) :- % *IMPLEMENTATION HERE*

update_score(_, _) :- fail.


% ============================================================================
% EXERCISE 4 — failure-driven loop  [Lab 10]
%
% Implement print_all_scores/0 using the failure-driven loop pattern:
%   goal_that_backtracks, side_effect, fail ; true.
%
% This is the same pattern used in neighb_to_edge_v2 from Lab 11 and in
% state.pl's internal loops.
% ============================================================================

%--------------------------------------------------
% print_all_scores  [Lab 10]
%
%   Print every score/2 fact to the console, one per line, as "Player: Points".
%   Use the failure-driven loop pattern: score(P,N), format(...), fail ; true.
%   Do not use findall here — the purpose is to practise the loop pattern.
%
%   ?- add_score(alice, 10), add_score(bob, 7), print_all_scores.
%   alice: 10
%   bob: 7

% print_all_scores :- % *IMPLEMENTATION HERE*

print_all_scores :- fail.
