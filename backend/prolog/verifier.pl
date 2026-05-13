% ============================================================================
% verifier.pl
% Checks that a puzzle is solvable step-by-step with no guessing: starting
% from the revealed character and its clue, we can always find at least one
% cell whose status is uniquely forced, reveal its clue, and continue.
% ============================================================================

:- module(verifier, [
    is_winnable/0,              % uses currently loaded puzzle
    replay_solution/1,          % replay_solution(-PlaybackSteps)
    puzzle_loaded/0
]).

:- use_module(board).
:- use_module(state).
:- use_module(solver).

% The loaded puzzle file must provide these predicates:
%   character/4, revealed_at_start/1, clue_of/2, solution/2

puzzle_loaded :-
    current_predicate(user:revealed_at_start/1),
    current_predicate(user:clue_of/2),
    current_predicate(user:solution/2),
    current_predicate(user:character/4).

% is_winnable succeeds iff the loaded puzzle can be played without guessing.
is_winnable :-
    puzzle_loaded,
    replay_solution(Steps),
    length(Steps, 20).

% replay_solution(-Steps) — the ordered list of (Cell, Status) reveals,
% including the starting cell.
replay_solution(Steps) :-
    reset_state,
    user:revealed_at_start(Start),
    user:solution(Start, StartStatus),
    register_known(Start, StartStatus),
    reveal_if_any(Start),
    play_loop([Start-StartStatus|Acc0]-Acc0, Steps).

% play_loop(+Difference-List-Accumulator, -Final)
% Uses a difference-list trick: we accumulate into the tail (O(1) append).
play_loop(Start-End, Out) :-
    next_forced(Cell, Status), !,
    register_known(Cell, Status),
    reveal_if_any(Cell),
    End = [Cell-Status|NewEnd],
    play_loop(Start-NewEnd, Out).
play_loop(Start-End, Out) :-
    End = [],
    Out = Start.

next_forced(Cell, Status) :-
    all_cells(All),
    member(Cell, All),
    \+ is_known(Cell, _),
    forced(Cell, Status), !.

reveal_if_any(Cell) :-
    user:clue_of(Cell, Clue), !,
    record_revealed_clue(Cell, Clue).
reveal_if_any(_).
