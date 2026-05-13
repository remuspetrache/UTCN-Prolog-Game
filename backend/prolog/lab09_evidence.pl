% ============================================================================
% lab09_evidence.pl — STUDENT FILE
%
% Labs: L09 (Difference Lists)
% Game component: Difference-list evidence log.
%   During a game session revealed clues are appended to an evidence log.
%   Using a difference list (DL) makes each append O(1) regardless of how
%   many clues have been revealed.
% Loaded by: evidence.pl (wrapper), which is used by verifier.pl.
%
% DIFFERENCE LIST NOTATION
%   A difference list is represented as a pair S-E, where:
%     S  = the start of the open list (a regular Prolog list with a hole tail)
%     E  = the hole at the end (an unbound variable)
%   An empty DL has S == E (the start IS the hole): X-X.
%   Appending an element in O(1): bind E = [Elem|NewHole], new DL is S-NewHole.
%   Closing the DL (getting a plain list): bind E = [], result is S.
%
% Example session:
%   ?- empty_evidence(E0),            % E0 = H-H  (fresh hole)
%      add_evidence_dl(clue1, E0, E1), % E0's hole <- [clue1|H1], E1 = H0-H1
%      add_evidence_dl(clue2, E1, E2), % E1's hole <- [clue2|H2], E2 = H0-H2
%      evidence_list(E2, L).           % close hole: L = [clue1, clue2]
%   L = [clue1, clue2].
% ============================================================================


%--------------------------------------------------
% 1. empty_evidence(-E)  [Lab 09]
%
%   Unify E with an empty difference list X-X, where X is a fresh unbound
%   variable (the start and end are the same hole).
%
%   ?- empty_evidence(E).
%   E = _A-_A.   % some uninstantiated variable
%
%   ?- empty_evidence(E), evidence_list(E, L).
%   E = []-[], L = [].

% empty_evidence(-E) :- % *IMPLEMENTATION HERE*

empty_evidence(_) :- fail.


%--------------------------------------------------
% 2. add_evidence_dl(+Clue, +Dl0, -Dl1)  [Lab 09]
%
%   Append Clue to the open tail of Dl0 in O(1) and produce Dl1.
%   Dl0 = S-E;  bind E = [Clue|NewTail];  Dl1 = S-NewTail.
%   This does NOT traverse the list — it simply unifies the tail hole.
%
%   ?- empty_evidence(E0),
%      add_evidence_dl(revealed(a1, row_count(1,integralist,2)), E0, E1),
%      add_evidence_dl(revealed(b2, group_count(311,restantier,1)), E1, E2),
%      evidence_list(E2, L).
%   L = [revealed(a1, row_count(1,integralist,2)),
%        revealed(b2, group_count(311,restantier,1))].

% add_evidence_dl(+Clue, +Dl0, -Dl1) :- % *IMPLEMENTATION HERE*

add_evidence_dl(_, _, _) :- fail.


%--------------------------------------------------
% 3. evidence_list(+Dl, -Plain)  [Lab 09]
%
%   Close the open tail of Dl (bind E = []) and unify Plain with the
%   resulting ordinary list S.
%   After this call Dl is no longer an open DL — do not append to it again.
%
%   ?- empty_evidence(E), evidence_list(E, L).
%   L = [].
%
%   ?- empty_evidence(E0),
%      add_evidence_dl(clue_a, E0, E1),
%      add_evidence_dl(clue_b, E1, E2),
%      evidence_list(E2, L).
%   L = [clue_a, clue_b].

% evidence_list(+Dl, -Plain) :- % *IMPLEMENTATION HERE*

evidence_list(_, _) :- fail.


%--------------------------------------------------
% 4. evidence_length(+Dl, -N)  [Lab 09 + Lab 03]
%
%   Unify N with the number of clues stored in the difference list Dl.
%
%   Hint: close the DL with evidence_list/2 to get a plain list,
%         then use length/2.
%   Note: closing the DL is safe here because we only need the count.
%
%   ?- empty_evidence(E0),
%      add_evidence_dl(c1, E0, E1),
%      add_evidence_dl(c2, E1, E2),
%      evidence_length(E2, N).
%   N = 2.
%
%   ?- empty_evidence(E), evidence_length(E, N).
%   N = 0.

% evidence_length(+Dl, -N) :- % *IMPLEMENTATION HERE*

evidence_length(_, _) :- fail.
