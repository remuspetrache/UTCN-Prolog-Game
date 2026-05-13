% ============================================================================
% state.pl
% Dynamic game state: known cells, revealed clues, mistakes, hint flags.
% Uses: L10 (Side Effects) via assertz/retractall of dynamic predicates.
% ============================================================================

:- module(state, [
    set_session/1,
    reset_state/0,
    register_known/2,
    is_known/2,
    all_known/1,
    known_count/1,
    record_revealed_clue/2,
    force_revealed_clue/2,
    clear_revealed_clue/1,
    reveal_clue_for/1,
    revealed_clue_of/2,
    all_revealed_clues/1,
    record_mistake/2,
    mistake_count/1,
    all_mistakes/1,
    register_hinted/1,
    is_hinted/1,
    all_hinted/1
]).

:- dynamic current_session/1.
:- dynamic known_s/3.
:- dynamic revealed_clue_s/3.
:- dynamic mistake_s/3.
:- dynamic hinted_s/2.

% ---------------------------------------------------------------------------
% Session context
% ---------------------------------------------------------------------------

set_session(Session) :-
    retractall(current_session(_)),
    assertz(current_session(Session)).

session_id(Session) :-
    current_session(Session), !.
session_id(default) :-
    assertz(current_session(default)).

% ---------------------------------------------------------------------------
% State operations (scoped by current session)
% ---------------------------------------------------------------------------

% L10: wipe the dynamic predicate base for the current session.
reset_state :-
    session_id(Session),
    retractall(known_s(Session, _, _)),
    retractall(revealed_clue_s(Session, _, _)),
    retractall(mistake_s(Session, _, _)),
    retractall(hinted_s(Session, _)).

% Compatibility wrappers used by Python bridge queries.
known(Cell, Status) :-
    session_id(Session),
    known_s(Session, Cell, Status).
revealed_clue(Cell, Clue) :-
    session_id(Session),
    revealed_clue_s(Session, Cell, Clue).
mistake(Cell-Status) :-
    session_id(Session),
    mistake_s(Session, Cell, Status).
hinted(Cell) :-
    session_id(Session),
    hinted_s(Session, Cell).

% Register a confirmed choice as a new fact. (idempotent)
register_known(Cell, Status) :-
    session_id(Session),
    known_s(Session, Cell, Status), !.
register_known(Cell, Status) :-
    session_id(Session),
    assertz(known_s(Session, Cell, Status)).

is_known(Cell, Status) :-
    known(Cell, Status).

all_known(List) :-
    findall(Cell-Status, known(Cell, Status), List).

known_count(N) :-
    findall(_, known(_, _), L),
    length(L, N).

% Clue reveal is stored once per cell.
record_revealed_clue(Cell, _Clue) :-
    revealed_clue(Cell, _), !.
record_revealed_clue(Cell, Clue) :-
    session_id(Session),
    assertz(revealed_clue_s(Session, Cell, Clue)).

force_revealed_clue(Cell, Clue) :-
    clear_revealed_clue(Cell),
    session_id(Session),
    assertz(revealed_clue_s(Session, Cell, Clue)).

clear_revealed_clue(Cell) :-
    session_id(Session),
    retractall(revealed_clue_s(Session, Cell, _)).

% reveal_clue_for(+Cell): look up the puzzle clue attached to Cell and
% record it without requiring the caller to pass the term. Used by the
% Python bridge to avoid round-tripping complex Prolog terms.
reveal_clue_for(Cell) :-
    revealed_clue(Cell, _), !.
reveal_clue_for(Cell) :-
    session_id(Session),
    user:clue_of(Cell, Clue), !,
    assertz(revealed_clue_s(Session, Cell, Clue)).
reveal_clue_for(_).

revealed_clue_of(Cell, Clue) :-
    revealed_clue(Cell, Clue).

all_revealed_clues(List) :-
    findall(Cell-Clue, revealed_clue(Cell, Clue), List).

record_mistake(Cell, Status) :-
    session_id(Session),
    assertz(mistake_s(Session, Cell, Status)).

mistake_count(N) :-
    findall(_, mistake(_), L),
    length(L, N).

all_mistakes(L) :-
    findall(M, mistake(M), L).

register_hinted(Cell) :-
    hinted(Cell), !.
register_hinted(Cell) :-
    session_id(Session),
    assertz(hinted_s(Session, Cell)).

is_hinted(Cell) :-
    hinted(Cell).

all_hinted(L) :-
    findall(C, hinted(C), L).
