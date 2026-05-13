% ============================================================================
% tests.pl — plunit suite for the pure-Prolog layers.
%
% Run with:  swipl -g "['prolog/tests.pl'], run_tests, halt(0)" -t "halt(1)"
%
% Test clusters map to the labs referenced in the student template:
%   - board_tests    -> L03 lists, L06 list-of-lists
%   - graph_tests    -> L11 neighbor facts, L12 BFS
%   - trees_tests    -> L07 n-ary trees
%   - evidence_tests -> L09 difference lists
%   - state_tests    -> L10 side effects
% ============================================================================

:- use_module(board).
:- use_module(graph).
:- use_module(trees).
:- use_module(evidence).
:- use_module(state).

:- begin_tests(board_tests).

test(grid_has_twenty_cells) :-
    board:all_cells(L),
    length(L, 20).

test(rows_have_four_cells) :-
    board:cells_in_row(1, R),
    length(R, 4),
    member(a1, R),
    !.

test(cols_have_five_cells) :-
    board:cells_in_col(a, C),
    length(C, 5),
    member(a5, C),
    !.

test(corners_are_four) :-
    board:corner_cells(Corners),
    sort(Corners, S),
    length(S, 4).

test(edges_count_fourteen) :-
    board:edge_cells(Es),
    length(Es, 14).

:- end_tests(board_tests).


:- begin_tests(graph_tests).

test(a1_has_three_neighbors) :-
    graph:neighbors_of(a1, Ns),
    length(Ns, 3).

test(c3_has_eight_neighbors) :-
    graph:neighbors_of(c3, Ns),
    length(Ns, 8).

test(bfs_reach_respects_allowed_set) :-
    % Restrict BFS to row 1. Starting at a1 we should reach a1,b1,c1,d1.
    board:cells_in_row(1, Row),
    graph:bfs_reach(a1, Row, Reached),
    sort(Reached, R),
    sort(Row, Rr),
    R == Rr.

test(bfs_reach_cannot_leave_allowed) :-
    % Only a1 is allowed -> only a1 reached.
    graph:bfs_reach(a1, [a1], R),
    R == [a1].

:- end_tests(graph_tests).


:- begin_tests(trees_tests).

test(group_311_contains_a1) :-
    trees:university_tree(T),
    trees:group_members(311, T, Members),
    member(a1, Members), !.

test(spec_personal_contains_asistenti_cells) :-
    trees:university_tree(T),
    trees:spec_members(personal, T, Members),
    member(c3, Members),
    member(d4, Members), !.

test(all_groups_found) :-
    trees:university_tree(T),
    trees:all_groups_of_tree(T, Groups),
    member(311, Groups),
    member(cadre, Groups), !.

:- end_tests(trees_tests).


:- begin_tests(evidence_tests).

% Difference-list evidence chain. Empty evidence pair is E-E; we add clues
% through the tail variable in O(1).
test(empty_evidence_flattens_to_nil) :-
    evidence:empty_evidence(E),
    evidence:evidence_list(E, L),
    L == [].

test(add_three_clues_preserves_order) :-
    evidence:empty_evidence(E0),
    evidence:add_evidence_dl(c1-clue(a), E0, E1),
    evidence:add_evidence_dl(c2-clue(b), E1, E2),
    evidence:add_evidence_dl(c3-clue(c), E2, E3),
    evidence:evidence_list(E3, L),
    L = [c1-clue(a), c2-clue(b), c3-clue(c)].

test(length_of_two_clues) :-
    evidence:empty_evidence(E0),
    evidence:add_evidence_dl(c1-clue(a), E0, E1),
    evidence:add_evidence_dl(c2-clue(b), E1, E2),
    evidence:evidence_length(E2, 2).

:- end_tests(evidence_tests).


:- begin_tests(state_tests).

test(register_and_lookup_known, [setup(state:reset_state)]) :-
    state:register_known(a1, integralist),
    state:is_known(a1, integralist).

test(known_count_increments, [setup(state:reset_state)]) :-
    state:register_known(a1, integralist),
    state:register_known(b1, restantier),
    state:known_count(2).

test(mistake_tracked, [setup(state:reset_state)]) :-
    state:record_mistake(b1, restantier),
    state:mistake_count(1).

test(reset_clears_state) :-
    state:register_known(a1, integralist),
    state:record_mistake(b1, restantier),
    state:reset_state,
    state:known_count(0),
    state:mistake_count(0).

:- end_tests(state_tests).
