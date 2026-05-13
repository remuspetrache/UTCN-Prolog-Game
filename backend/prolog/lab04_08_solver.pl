% ============================================================================
% lab04_08_solver.pl — STUDENT FILE
%
% Labs: L08 (Incomplete Structures), L04 (Cut + Negation-as-Failure)
% Game component: Forced-value inference engine.
%   Given the current game state (known cells + revealed clues), determine
%   whether a cell MUST be integralist or restantier by trying all consistent
%   worlds and applying logical necessity.
% Loaded by: solver.pl (wrapper), which is called by prolog_bridge.py.
%
% Read verifier.pl to see how forced/2 is consumed in the game loop:
%   next_forced/2 calls forced(Cell, Status) for each unknown cell.
%
% PROVIDED utilities in solver.pl (do NOT redefine here):
%   opposite_status(+S, -Other) — opposite_status(integralist, restantier)
%   possible_status(+Cell, -Status) — uses has_consistent_world/2
%   solve_complete(-Assignment) — uses build_initial_world/1 and search/2
% PROVIDED state predicates (call as state:predicate):
%   state:all_known(-List)          — list of Cell-Status pairs already confirmed
%   state:all_revealed_clues(-List) — list of Cell-Clue pairs to check
%   state:is_known(+Cell, ?Status)  — true if cell is already confirmed
% ============================================================================


% --- Lab 08: Incomplete Structures (World) -----------------------------------


%--------------------------------------------------
% 1a. make_world(+Cells, -World)  [Lab 08]
%
%   Helper: convert the flat cell list from all_cells/1 into a list of
%   cell/2 terms where every Status slot is a fresh unbound variable.
%   This is the L08 "incomplete structure" pattern.
%
%   ?- make_world([a1, b1], W).
%   W = [cell(a1, _A), cell(b1, _B)].  % _A and _B are distinct unbound vars

% make_world(+Cells, -World) :- % *IMPLEMENTATION HERE*

make_world(_, _) :- fail.


%--------------------------------------------------
% 1b. pin_known(+World)  [Lab 08]
%
%   Helper: retrieve state:all_known/1 to get a list of Cell-Status pairs,
%   then call pin_cell/3 for each pair to fill in already-confirmed slots.
%
%   ?- make_world([a1,b1], W), assertz(known_s(test,a1,integralist)),
%      pin_known(W), member(cell(a1, S), W).
%   S = integralist.

% pin_known(+World) :- % *IMPLEMENTATION HERE*

pin_known(_) :- fail.


%--------------------------------------------------
% 1. build_initial_world(-World)  [Lab 08]
%
%   Produce the starting world for search: one cell(Id, _) per board cell
%   with every Status slot as a fresh unbound variable, then pin any cells
%   that are already known in the current game state.
%
%   Decompose into three steps:
%     (a) Get the cell list: all_cells(Cells)
%     (b) Build the world: make_world(Cells, World)
%     (c) Pin known cells: pin_known(World)
%
%   ?- build_initial_world(W), length(W, N).
%   N = 20.
%
%   ?- build_initial_world(W), W = [cell(a1, S)|_], var(S).
%   true.   % slot is unbound (assuming a1 is not yet known)

% build_initial_world(-World) :- % *IMPLEMENTATION HERE*

build_initial_world(_) :- fail.


%--------------------------------------------------
% 2. pin_cell(+World, +Cell, +Status)  [Lab 08]
%
%   Find cell(Cell, S) in World using member/2 and unify S with Status.
%   Succeeds if S is unbound (fresh variable — unification binds it) or if
%   S is already bound to Status (consistent re-pin).
%   Fails if S is already bound to a DIFFERENT status (contradiction).
%
%   ?- make_world([a1, b1], W), pin_cell(W, a1, integralist),
%      member(cell(a1, S), W).
%   S = integralist.
%
%   ?- make_world([a1], W), pin_cell(W, a1, integralist),
%      pin_cell(W, a1, restantier).
%   false.   % second pin contradicts first

% pin_cell(+World, +Cell, +Status) :- % *IMPLEMENTATION HERE*

pin_cell(_, _, _) :- fail.


%--------------------------------------------------
% 3. search(+World, +Clues)  [Lab 08 + Lab 04]
%
%   Assign a status (integralist or restantier) to every unbound cell slot
%   in World, then verify that every clue in Clues holds. Use backtracking
%   to try all combinations until one consistent assignment is found.
%
%   Approach (simple flat search — sufficient for 20 cells):
%     For each cell(_, S) in World where S is still unbound, non-deterministically
%     bind S to integralist or restantier (Lab 04: use member/2 or two clauses).
%     When no unbound slot remains, check all clues with clues:check_clue/2.
%
%   Note: the provided solver.pl also exports solve_complete/1 which calls
%   build_initial_world/1 + search/2. Once your search/2 is correct,
%   solve_complete/1 works for free.
%
%   ?- build_initial_world(W), search(W, []).
%   true.   % empty clue list: any assignment is consistent

% search(+World, +Clues) :- % *IMPLEMENTATION HERE*

search(_, _) :- fail.


% --- Lab 04: Cut and Negation-as-Failure (forced/2) -------------------------


%--------------------------------------------------
% 4. has_consistent_world(+Cell, +Status)  [Lab 04]
%
%   Succeed iff there exists at least one complete assignment where Cell has
%   the given Status and all revealed clues are satisfied.
%
%   Steps:
%     (a) build_initial_world(World)
%     (b) pin_cell(World, Cell, Status)
%     (c) state:all_revealed_clues(Clues)
%     (d) search(World, Clues)
%   Use cut (!) after search/2 to commit to the first consistent world found —
%   we only need to know if one EXISTS, not find all of them.
%
%   ?- has_consistent_world(a1, integralist).
%   true.   % (if the current clues allow a1 to be integralist)

% has_consistent_world(+Cell, +Status) :- % *IMPLEMENTATION HERE*

has_consistent_world(_, _) :- fail.


%--------------------------------------------------
% 5. forced(+Cell, -Status)  [Lab 04 — Negation-as-Failure]
%
%   Succeed iff Cell's status is FORCED: there is a consistent world with
%   Cell = Status AND there is NO consistent world with Cell = OtherStatus.
%
%   A cell is forced when only one status is logically possible — the other
%   would contradict at least one revealed clue.
%
%   Conditions (all must hold, in order):
%     (a) Cell is not already known: \+ state:is_known(Cell, _)
%     (b) A consistent world with Cell = Status exists: has_consistent_world(Cell, Status)
%     (c) No consistent world with Cell = OtherStatus: \+ has_consistent_world(Cell, Other)
%         where opposite_status(Status, Other).
%
%   Do NOT use "->". Use separate goals and \+ (negation-as-failure).
%   Use cut (!) at the end to commit once a forced status is found.
%
%   ?- forced(a1, S).
%   S = integralist.  % (if the current puzzle forces a1 to be integralist)
%
%   ?- forced(a1, _).
%   false.  % if a1 is already known, or its status is not yet determined

% forced(+Cell, -Status) :- % *IMPLEMENTATION HERE*

forced(_, _) :- fail.
