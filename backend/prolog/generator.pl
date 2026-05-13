% ============================================================================
% generator.pl
% Generate a winnable puzzle for the 4x5 grid.
%
% Approach (greedy):
%   1. Pick a random target solution (20 integralist/restantier assignments).
%   2. Pick a starting cell.
%   3. Repeatedly:
%        a) Try candidate clue terms true in the solution;
%        b) Attach one that, combined with the current game state, forces a
%           new cell to be determined.
%   4. Verify with `is_winnable/0`; retry otherwise.
% ============================================================================

:- module(generator, [
    generate_puzzle/0,
    generate_puzzle/1,
    write_puzzle_file/2,
    gen_solution/2,
    gen_clue_of/2,
    gen_revealed_at_start/1
]).

:- use_module(board).
:- use_module(graph).
:- use_module(clues).
:- use_module(state).
:- use_module(solver).
:- use_module(verifier).

% Keep generator state separate from puzzle facts so we can reuse them.
:- dynamic gen_solution/2.
:- dynamic gen_clue_of/2.
:- dynamic gen_revealed_at_start/1.

% During generation we temporarily expose the same shape as a puzzle file
% by forwarding solution/2, clue_of/2, revealed_at_start/1 via :- multifile
% hooks into the user module.
:- dynamic user:solution/2.
:- dynamic user:clue_of/2.
:- dynamic user:revealed_at_start/1.

:- dynamic user:character/4.

reset_gen :-
    retractall(gen_solution(_, _)),
    retractall(gen_clue_of(_, _)),
    retractall(gen_revealed_at_start(_)),
    retractall(user:solution(_, _)),
    retractall(user:clue_of(_, _)),
    retractall(user:revealed_at_start(_)),
    retractall(user:character(_, _, _, _)),
    assert_default_characters,
    state:reset_state.

assert_default_characters :-
    forall(default_character(Id, Name, Role, Group),
           assertz(user:character(Id, Name, Role, Group))).

% ---------------------------------------------------------------------------
% generate_puzzle / 0-1
% ---------------------------------------------------------------------------
generate_puzzle :-
    generate_puzzle(_).

generate_puzzle(Seed) :-
    normalize_seed(Seed, S0),
    set_seed(S0),
    try_attempts(1, 50).

normalize_seed(Seed, Seed) :- nonvar(Seed), !.
normalize_seed(Seed, Seed) :- get_time(Seed).

try_attempts(N, Max) :-
    N =< Max,
    attempt_once(N), !.
try_attempts(N, Max) :-
    N =< Max,
    N1 is N + 1,
    try_attempts(N1, Max).

set_seed(S) :-
    Hash is truncate(S) mod 1000000,
    set_random(seed(Hash)).

attempt_once(N) :-
    format("Generation attempt ~w~n", [N]),
    reset_gen,
    random_solution,
    random_start(Start),
    assertz(user:revealed_at_start(Start)),
    assertz(gen_revealed_at_start(Start)),
    greedy_chain,
    fill_flavor,
    verifier_winnable.

verifier_winnable :-
    verifier:is_winnable.

% ---------------------------------------------------------------------------
% Random solution
% ---------------------------------------------------------------------------
random_solution :-
    all_cells(Cells),
    random_assign(Cells).

random_assign([]).
random_assign([C|Rest]) :-
    random_between(0, 1, Bit),
    status_of_bit(Bit, S),
    assertz(user:solution(C, S)),
    assertz(gen_solution(C, S)),
    random_assign(Rest).

status_of_bit(0, integralist).
status_of_bit(1, restantier).

random_start(Start) :-
    all_cells(Cells),
    length(Cells, L),
    random_between(1, L, K),
    nth1(K, Cells, Start).

% ---------------------------------------------------------------------------
% Greedy chain: at each step find a clue that reveals progress.
% ---------------------------------------------------------------------------
greedy_chain :-
    gen_revealed_at_start(Start),
    user:solution(Start, SS),
    state:register_known(Start, SS),
    assign_best_clue(Start, started),
    chain_loop(Start, 0).

chain_loop(_Last, Stuck) :-
    Stuck >= 60, !.
chain_loop(_Last, _Stuck) :-
    state:known_count(20), !.
chain_loop(_Last, _Stuck) :-
    next_forced(Cell, Status), !,
    state:register_known(Cell, Status),
    assign_best_clue(Cell, progress),
    chain_loop(Cell, 0).
chain_loop(Last, Stuck) :-
    promote_clue(Last),
    NewStuck is Stuck + 1,
    chain_loop(Last, NewStuck).

next_forced(Cell, Status) :-
    all_cells(All),
    member(Cell, All),
    \+ state:is_known(Cell, _),
    solver:forced(Cell, Status), !.

% ---------------------------------------------------------------------------
% Clue selection
% ---------------------------------------------------------------------------
% For each cell we try a ranked list of candidate clue terms; the first one
% that (is true in the solution) and (causes progress) is assigned.
% "Progress" = after recording the clue, some new cell becomes forced.
% ---------------------------------------------------------------------------
assign_best_clue(Cell, _Reason) :-
    gen_clue_of(Cell, _), !.       % already assigned
assign_best_clue(Cell, _Reason) :-
    candidate_clues(Cell, Candidates),
    select_progress_clue(Cell, Candidates, Clue), !,
    state:clear_revealed_clue(Cell),
    assertz(user:clue_of(Cell, Clue)),
    assertz(gen_clue_of(Cell, Clue)),
    state:force_revealed_clue(Cell, Clue).
assign_best_clue(Cell, _Reason) :-
    FlavorClue = flavor("Nu am nimic relevant de zis."),
    state:clear_revealed_clue(Cell),
    assertz(user:clue_of(Cell, FlavorClue)),
    assertz(gen_clue_of(Cell, FlavorClue)),
    state:force_revealed_clue(Cell, FlavorClue).

% If stuck, try replacing the last-assigned clue with a stronger one (i.e.
% promote from flavor or from a non-progressing clue).
promote_clue(Cell) :-
    gen_clue_of(Cell, Old), !,
    retractall(user:clue_of(Cell, Old)),
    retractall(gen_clue_of(Cell, Old)),
    state:clear_revealed_clue(Cell),
    assign_best_clue(Cell, promote).
promote_clue(_).

% candidate_clues(+Cell, -List): ordered candidate clue terms.
candidate_clues(_Cell, List) :-
    findall(C, ( candidate_clue_template(C), true_in_solution(C) ), Raw),
    List = Raw.

true_in_solution(Clue) :-
    build_solution_world(W),
    check_clue(Clue, W).

build_solution_world(W) :-
    all_cells(Cells),
    maplist(cell_pair, Cells, W).

cell_pair(Id, cell(Id, S)) :-
    user:solution(Id, S).

% Iterate through candidates; pick the first that causes progress.
select_progress_clue(Cell, [C|_], C) :-
    causes_progress(Cell, C), !.
select_progress_clue(Cell, [_|Rest], C) :-
    select_progress_clue(Cell, Rest, C).

causes_progress(Cell, Clue) :-
    state:force_revealed_clue(Cell, Clue),
    once_forced(Found),
    state:clear_revealed_clue(Cell),
    Found = yes.

once_forced(yes) :- next_forced(_, _), !.
once_forced(no).

% ---------------------------------------------------------------------------
% Clue templates (enumerate plausible Clue shapes).
% ---------------------------------------------------------------------------
candidate_clue_template(count_row(R, S, N)) :-
    member(R, [1,2,3,4,5]),
    member(S, [integralist, restantier]),
    member(N, [0,1,2,3,4]).
candidate_clue_template(count_col(C, S, N)) :-
    member(C, [a,b,c,d]),
    member(S, [integralist, restantier]),
    member(N, [0,1,2,3,4,5]).
candidate_clue_template(count_edge(S, N)) :-
    member(S, [integralist, restantier]),
    member(N, [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14]).
candidate_clue_template(count_corner(S, N)) :-
    member(S, [integralist, restantier]),
    member(N, [0,1,2,3,4]).
candidate_clue_template(neighbor_count(Cell, S, N)) :-
    all_cells(Cells), member(Cell, Cells),
    member(S, [integralist, restantier]),
    member(N, [0,1,2,3,4,5,6,7,8]).
candidate_clue_template(direct_neighbor(Cell, Dir, S)) :-
    all_cells(Cells), member(Cell, Cells),
    member(Dir, [sus, jos, stanga, dreapta]),
    member(S, [integralist, restantier]).
candidate_clue_template(all_connected_row(R, S)) :-
    member(R, [1,2,3,4,5]),
    member(S, [integralist, restantier]).
candidate_clue_template(group_count(G, S, N)) :-
    member(G, [311, 312, 313, asistenti, cadre]),
    member(S, [integralist, restantier]),
    member(N, [0,1,2,3,4]).

% ---------------------------------------------------------------------------
% Flavor filler for cells that never got a clue.
% ---------------------------------------------------------------------------
fill_flavor :-
    all_cells(Cells),
    fill_flavor_list(Cells).

fill_flavor_list([]).
fill_flavor_list([C|Rest]) :-
    gen_clue_of(C, _), !,
    fill_flavor_list(Rest).
fill_flavor_list([C|Rest]) :-
    F = flavor("Nu am nimic relevant de zis."),
    assertz(user:clue_of(C, F)),
    assertz(gen_clue_of(C, F)),
    fill_flavor_list(Rest).

% ---------------------------------------------------------------------------
% write_puzzle_file(+Path, +Title)
% Dump the generated puzzle to a .pl file consumable by the game.
% ---------------------------------------------------------------------------
write_puzzle_file(Path, Title) :-
    setup_call_cleanup(
        open(Path, write, Out),
        write_puzzle(Out, Title),
        close(Out)).

write_puzzle(Out, Title) :-
    format(Out, "% auto-generated puzzle~n", []),
    format(Out, ":- module(gen_puzzle, [character/4, revealed_at_start/1, clue_of/2, solution/2, puzzle_title/1, puzzle_difficulty/1]).~n", []),
    format(Out, ":- discontiguous character/4.~n", []),
    format(Out, ":- discontiguous clue_of/2.~n", []),
    format(Out, ":- discontiguous solution/2.~n~n", []),
    format(Out, "puzzle_title(\"~w\").~n", [Title]),
    format(Out, "puzzle_difficulty(generat).~n~n", []),
    % characters fall back to a default cast reused from puzzle_01/_02
    forall(default_character(Id, Name, Role, Group),
           format(Out, "character(~q, ~q, ~q, ~q).~n",
                  [Id, Name, Role, Group])),
    nl(Out),
    forall(gen_solution(C, S),
           format(Out, "solution(~q, ~q).~n", [C, S])),
    nl(Out),
    forall(gen_revealed_at_start(Cell),
           format(Out, "revealed_at_start(~q).~n", [Cell])),
    nl(Out),
    forall(gen_clue_of(C, Clue),
           format(Out, "clue_of(~q, ~q).~n", [C, Clue])).

default_character(a1, 'Andrei',   student,  311).
default_character(b1, 'Bogdan',   student,  311).
default_character(c1, 'Cristina', student,  312).
default_character(d1, 'Daniel',   student,  312).
default_character(a2, 'Elena',    student,  311).
default_character(b2, 'Florin',   student,  311).
default_character(c2, 'Gabriela', student,  312).
default_character(d2, 'Horia',    student,  312).
default_character(a3, 'Ioana',    student,  313).
default_character(b3, 'Luca',     student,  313).
default_character(c3, 'Mihai',    asistent, asistenti).
default_character(d3, 'Nicoleta', asistent, asistenti).
default_character(a4, 'Ovidiu',   student,  313).
default_character(b4, 'Paul',     student,  313).
default_character(c4, 'Raluca',   asistent, asistenti).
default_character(d4, 'Sorin',    asistent, asistenti).
default_character(a5, 'Teodora',  profesor, cadre).
default_character(b5, 'Vlad',     profesor, cadre).
default_character(c5, 'Iulia',    decan,    cadre).
default_character(d5, 'Mircea',   secretar, cadre).
