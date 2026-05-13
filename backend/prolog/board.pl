% ============================================================================
% board.pl — MODULE WRAPPER, DO NOT EDIT
%
% PROVIDED — do not edit. This file loads the student implementation via
% :- include and exports the module interface unchanged.
%
% Grid geometry: 4 columns (a..d) × 5 rows (1..5). Every cell is identified
% by an atom of the form <col><row>, e.g. a1, c3, d5.
%
% Labs that students use in the included file:
%   L03 (Operations on Lists) — flat cell lists
%   L06 (Deep Lists)          — grid as list-of-rows
% ============================================================================

:- module(board, [
    all_cells/1,
    cells_in_row/2,
    cells_in_col/2,
    corner_cells/1,
    edge_cells/1,
    cell_id/3,
    cell_coord/3,
    col_idx/2,
    col_atom/2,
    col_letter/1,
    row_number/1,
    is_edge/1,
    cells_between/3,
    pick_status_cells/3,
    grid/1
]).

% --------------------------------------------------------------------------
% Provided helpers — DO NOT MODIFY.
% These are used by the wrappers and clues.pl; students do not implement them.
% --------------------------------------------------------------------------

col_idx(a, 1).
col_idx(b, 2).
col_idx(c, 3).
col_idx(d, 4).

col_atom(1, a).
col_atom(2, b).
col_atom(3, c).
col_atom(4, d).

col_letter(a).
col_letter(b).
col_letter(c).
col_letter(d).

row_number(1).
row_number(2).
row_number(3).
row_number(4).
row_number(5).

% cell_id(+Col, +Row, -Id) — build atom from column letter + row number.
cell_id(Col, Row, Id) :-
    atom_number(RowAtom, Row),
    atom_concat(Col, RowAtom, Id).

% cell_coord(?Id, ?Col, ?Row) — works both ways.
cell_coord(Id, Col, Row) :-
    col_letter(Col),
    row_number(Row),
    cell_id(Col, Row, Id).

% is_edge_coord(+Col, +Row) — true for cells on the outer border.
% Uses L04 cut for determinism.
is_edge_coord(a, _) :- !.
is_edge_coord(d, _) :- !.
is_edge_coord(_, 1) :- !.
is_edge_coord(_, 5).

% is_edge(+Id) — true if Id is a border cell.
% Provided so clues.pl can call it before edge_cells/1 is implemented.
is_edge(Id) :-
    cell_coord(Id, C, R),
    is_edge_coord(C, R).

% cells_between(+A, +B, -Between)
% Cells strictly between A and B when they are on the same row or column.
% Follows the game-rules definition: "between" excludes the endpoints.
cells_between(A, B, Between) :-
    cell_coord(A, Ca, Ra),
    cell_coord(B, Cb, Rb),
    between_impl(Ca, Ra, Cb, Rb, Between).

between_impl(C, Ra, C, Rb, Between) :- !,
    between_range(Ra, Rb, Rs),
    findall(Id, ( member(R, Rs), cell_id(C, R, Id) ), Between).
between_impl(Ca, R, Cb, R, Between) :-
    col_idx(Ca, Ai),
    col_idx(Cb, Bi),
    between_range(Ai, Bi, Is),
    findall(Id, ( member(I, Is), col_idx(C, I), cell_id(C, R, Id) ), Between).

between_range(A, B, []) :- Diff is abs(A - B), Diff < 2, !.
between_range(A, B, L) :-
    Lo is min(A, B) + 1,
    Hi is max(A, B) - 1,
    numlist(Lo, Hi, L).

% pick_status_cells(+Status, +World, -Ids)
% From a World list [cell(Id, S), ...], extract Ids whose S == Status.
pick_status_cells(_, [], []).
pick_status_cells(Status, [cell(Id, S)|Rest], [Id|Out]) :-
    nonvar(S),
    S == Status, !,
    pick_status_cells(Status, Rest, Out).
pick_status_cells(Status, [_|Rest], Out) :-
    pick_status_cells(Status, Rest, Out).

% --------------------------------------------------------------------------
% Student implementation (lab03_board.pl) is included below.
% The predicates all_cells/1, cells_in_row/2, cells_in_col/2, corner_cells/1,
% edge_cells/1, and grid/1 are defined there.
% --------------------------------------------------------------------------

:- include('lab03_board.pl').
