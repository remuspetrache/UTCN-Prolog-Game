% ============================================================================
% lab03_board.pl — STUDENT FILE
%
% Labs: L03 (Operations on Lists), L06 (Deep Lists)
% Game component: Board geometry — cells, rows, columns, corners, edges.
% Loaded by: board.pl (wrapper), which is used by clues.pl, solver.pl,
%            graph.pl, verifier.pl, and generator.pl.
%
% Complete the predicates below in the order they appear. Each predicate
% builds on the helpers that come before it.
%
% PROVIDED helpers available in board.pl (do NOT redefine them here):
%   col_idx(+ColLetter, -Index)   — col_idx(a,1), col_idx(b,2), ...
%   col_atom(+Index, -ColLetter)  — col_atom(1,a), col_atom(2,b), ...
%   col_letter(?Col)              — true for a, b, c, d
%   row_number(?Row)              — true for 1, 2, 3, 4, 5
%   cell_id(+Col, +Row, -Id)      — cell_id(a, 1, a1)
%   cell_coord(?Id, ?Col, ?Row)   — cell_coord(c3, c, 3)
%   is_edge(+Cell)                — true for cells on the outer border
% ============================================================================


%--------------------------------------------------
% 1. cells_in_row(+Row, -Cells)  [Lab 03]
%
%   Unify Cells with the list of the 4 cell atoms in row Row (left to right:
%   col a, b, c, d). Row is an integer from 1 to 5.
%
%   Approach: the four columns are always [a, b, c, d]. Recurse over that
%   list and use cell_id/3 to build each cell atom.
%   This is the classic L03 "map" pattern: transform every element of a
%   known list using a helper predicate.
%
%   ?- cells_in_row(1, Cells).
%   Cells = [a1, b1, c1, d1].
%
%   ?- cells_in_row(3, Cells).
%   Cells = [a3, b3, c3, d3].

% cells_in_row(+Row, -Cells) :- % *IMPLEMENTATION HERE*

cells_in_row(_, _) :- fail.


%--------------------------------------------------
% 2. cells_in_col(+Col, -Cells)  [Lab 03]
%
%   Unify Cells with the list of the 5 cell atoms in column Col (top to
%   bottom: rows 1..5). Col is a column letter (a, b, c, or d).
%
%   Approach: the five rows are always [1, 2, 3, 4, 5]. Recurse over that
%   list and use cell_id/3 to build each cell atom.
%
%   ?- cells_in_col(a, Cells).
%   Cells = [a1, a2, a3, a4, a5].
%
%   ?- cells_in_col(d, Cells).
%   Cells = [d1, d2, d3, d4, d5].

% cells_in_col(+Col, -Cells) :- % *IMPLEMENTATION HERE*

cells_in_col(_, _) :- fail.


%--------------------------------------------------
% 3. corner_cells(-Cells)  [Lab 03]
%
%   Unify Cells with the list of the 4 corner cells of the 4x5 board.
%   The corners are: a1 (top-left), d1 (top-right), a5 (bottom-left),
%   d5 (bottom-right).
%
%   Hint: this can be a single fact.
%
%   ?- corner_cells(Cells).
%   Cells = [a1, d1, a5, d5].

% corner_cells(-Cells) :- % *IMPLEMENTATION HERE*

corner_cells(_) :- fail.


%--------------------------------------------------
% 4. all_cells(-Cells)  [Lab 03]
%
%   Unify Cells with the flat list of all 20 cell atoms in the grid,
%   ordered row-major: a1, b1, c1, d1, a2, b2, ..., d5.
%
%   Approach: recurse over [1,2,3,4,5]. For each row R call cells_in_row/2
%   to get that row's 4 cells, then use append/3 to join all rows into
%   a single flat list.
%
%   ?- all_cells(Cells).
%   Cells = [a1, b1, c1, d1, a2, b2, c2, d2, a3, b3, c3, d3,
%            a4, b4, c4, d4, a5, b5, c5, d5].
%
%   ?- all_cells(L), length(L, N).
%   N = 20.

% all_cells(-Cells) :- % *IMPLEMENTATION HERE*

all_cells(_) :- fail.


%--------------------------------------------------
% 5. grid(-Grid)  [Lab 06]
%
%   Unify Grid with the board as a list of 5 rows, where each row is itself
%   a list of 4 cell atoms (top row first).
%   This is the "list of lists" (deep list) structure from Lab 06.
%
%   Approach: recurse over [1,2,3,4,5]. For each row R call cells_in_row/2
%   to produce one inner list. The outer list collects all five inner lists.
%
%   ?- grid(Grid).
%   Grid = [[a1,b1,c1,d1], [a2,b2,c2,d2], [a3,b3,c3,d3],
%           [a4,b4,c4,d4], [a5,b5,c5,d5]].
%
%   ?- grid(G), length(G, Rows), G = [R1|_], length(R1, Cols).
%   Rows = 5, Cols = 4.

% grid(-Grid) :- % *IMPLEMENTATION HERE*

grid(_) :- fail.


%--------------------------------------------------
% 6. edge_cells(-Cells)  [Lab 03 + Lab 04]
%
%   Unify Cells with the 14 cells on the outer border of the 4x5 grid.
%
%   Approach (two steps):
%     (a) Use all_cells/1 (predicate 4) to get the flat list of all 20 cells.
%     (b) Write a recursive predicate that walks the list and keeps only
%         those cells C for which is_edge(C) holds.
%
%   Lab 04 (Cut): in the recursive filter predicate, use two clauses with
%   cut (!) to handle the "keep" and "skip" cases without the "->".
%
%   ?- edge_cells(Cells), length(Cells, N).
%   N = 14.
%
%   ?- edge_cells(Cells), sort(Cells, S), length(S, N).
%   N = 14.   % no duplicates

% edge_cells(-Cells) :- % *IMPLEMENTATION HERE*

edge_cells(_) :- fail.
