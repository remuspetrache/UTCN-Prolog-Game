% ============================================================================
% lab11_12_graph.pl — STUDENT FILE
%
% Labs: L11 (Graphs), L12 (Graph Traversal — BFS)
% Game component: Neighbor graph and BFS connectivity.
%   Cells are neighbours if they share an edge or corner on the 4x5 board.
%   Orthogonal neighbours share only an edge (N/S/E/W).
%   Clues like "all restantierii pe rândul 1 sunt conectați" use BFS to check
%   whether a subset of cells forms a connected region.
% Loaded by: graph.pl (wrapper), which is used by clues.pl and solver.pl.
%
% IMPORTANT: Complete lab03_board.pl first. build_neighbors/0 (predicate 3)
%   is called automatically when graph.pl is loaded via :- initialization/1.
%   If board:all_cells/1 is still a stub, build_neighbors/0 will silently
%   produce no neighbor facts. Reload graph.pl after fixing board predicates.
%
% PROVIDED dynamic declarations in graph.pl:
%   :- dynamic neighbor/2.        % 8-directional, asserted by build_neighbors/0
%   :- dynamic ortho_neighbor/2.  % 4-directional (N/S/E/W only)
%
% PROVIDED helpers via board.pl:
%   all_cells(-Cells), cell_coord(?Id, ?Col, ?Row), col_idx(?Col, ?Idx)
% ============================================================================


% --- Lab 11: Graph Representation -------------------------------------------


%--------------------------------------------------
% 1. diag_adjacent(+A, +B)  [Lab 11]
%
%   Succeed if A and B are two different cells that touch diagonally —
%   i.e., their column indices differ by exactly 1 AND their row numbers
%   differ by exactly 1.
%
%   Hint: use cell_coord/3 and col_idx/2 to extract coordinates,
%         then use abs/1 and the arithmetic is/2.
%
%   ?- diag_adjacent(a1, b2).
%   true.
%
%   ?- diag_adjacent(a1, a2).
%   false.   % same column — orthogonal, not diagonal
%
%   ?- diag_adjacent(a1, c3).
%   false.   % columns differ by 2

% diag_adjacent(+A, +B) :- % *IMPLEMENTATION HERE*

diag_adjacent(_, _) :- fail.


%--------------------------------------------------
% 2. ortho_adjacent(+A, +B)  [Lab 11]
%
%   Succeed if A and B are two different cells that share an edge —
%   i.e., they differ by exactly 1 in either column OR row, but not both.
%
%   ?- ortho_adjacent(a1, b1).
%   true.   % same row, adjacent columns
%
%   ?- ortho_adjacent(a1, a2).
%   true.   % same column, adjacent rows
%
%   ?- ortho_adjacent(a1, b2).
%   false.  % diagonal

% ortho_adjacent(+A, +B) :- % *IMPLEMENTATION HERE*

ortho_adjacent(_, _) :- fail.


%--------------------------------------------------
% 3. build_neighbors  [Lab 11]
%
%   Assert neighbor/2 and ortho_neighbor/2 facts for every adjacent pair of
%   cells. Both directions must be asserted (if neighbor(a1, b2) then also
%   neighbor(b2, a1)). This predicate is called once at load time via
%   :- initialization(build_neighbors) in graph.pl.
%
%   Strategy:
%     (a) Use all_cells/1 to get the full cell list.
%     (b) For every pair (A, B) where A \= B, check adjacency.
%     (c) Use a failure-driven loop or recursion over all pairs.
%
%   Hint: a failure-driven loop over member(A, Cells), member(B, Cells)
%         is the simplest approach.
%
%   ?- build_neighbors, neighbor(a1, N), sort(0, @<, [N], _).
%   % (after build_neighbors/0 succeeds, neighbor facts exist)
%
%   ?- neighbors_of(a1, Ns), length(Ns, 3).
%   true.  % a1 has 3 neighbours: b1, a2, b2

% build_neighbors :- % *IMPLEMENTATION HERE*

build_neighbors :- fail.


%--------------------------------------------------
% 4. neighbors_of(+Cell, -Ns)  [Lab 11 + Lab 03]
%
%   Unify Ns with the list of all 8-directional neighbours of Cell.
%   Use findall/3 and the dynamic neighbor/2 facts.
%
%   ?- neighbors_of(a1, Ns).
%   Ns = [b1, a2, b2].   % 3 neighbours — corner cell
%
%   ?- neighbors_of(c3, Ns), length(Ns, N).
%   N = 8.   % interior cell — 8 neighbours

% neighbors_of(+Cell, -Ns) :- % *IMPLEMENTATION HERE*

neighbors_of(_, _) :- fail.


%--------------------------------------------------
% 5. ortho_neighbors_of(+Cell, -Ns)  [Lab 11 + Lab 03]
%
%   Unify Ns with the list of N/S/E/W neighbours only.
%
%   ?- ortho_neighbors_of(a1, Ns).
%   Ns = [b1, a2].   % only edge-sharing neighbours
%
%   ?- ortho_neighbors_of(c3, Ns), length(Ns, N).
%   N = 4.

% ortho_neighbors_of(+Cell, -Ns) :- % *IMPLEMENTATION HERE*

ortho_neighbors_of(_, _) :- fail.


%--------------------------------------------------
% 6. common_neighbors(+A, +B, -Common)  [Lab 11 + Lab 03]
%
%   Unify Common with the list of cells that are 8-directional neighbours
%   of both A and B (excluding A and B themselves).
%
%   Hint: use neighbors_of/2 and findall with member/2 intersection.
%
%   ?- common_neighbors(a1, b2, Common).
%   Common = [b1, a2].  % cells adjacent to both a1 and b2

% common_neighbors(+A, +B, -Common) :- % *IMPLEMENTATION HERE*

common_neighbors(_, _, _) :- fail.


%--------------------------------------------------
% 6b. common_neighbors_count(+A, +B, +_Status, -N)  [Lab 11 + Lab 03]
%
%   Unify N with the number of common neighbours of A and B.
%   The Status argument is present for interface compatibility but is not used.
%
%   Hint: use common_neighbors/3 and length/2.
%
%   ?- common_neighbors_count(a1, b2, integralist, N).
%   N = 2.

% common_neighbors_count(+A, +B, +_Status, -N) :- % *IMPLEMENTATION HERE*

common_neighbors_count(_, _, _, _) :- fail.


% --- Lab 12: Graph Traversal (BFS) ------------------------------------------


%--------------------------------------------------
% 7. bfs_reach(+Start, +Allowed, -Reached)  [Lab 12]
%
%   BFS from Start, restricted to cells in the Allowed list.
%   Reached is the list of all cells reachable from Start (including Start
%   itself if it is in Allowed). Only orthogonal moves (ortho_neighbor/2)
%   are used for connectivity.
%
%   IMPORTANT: Do NOT use assertz/retractall — keep the BFS pure.
%   Use a queue + visited accumulator pattern (like bfs1/3 in the L12 examples).
%
%   Helper to implement: bfs_loop(+Queue, +Allowed, +Visited, -Reached)
%     Base case: empty queue → Reached = Visited.
%     Recursive: expand the first cell, collect unvisited ortho-neighbours
%                in Allowed, add them to queue and visited, recurse.
%
%   ?- bfs_reach(a1, [a1,b1,c1,d1], Reached), sort(Reached, R).
%   R = [a1, b1, c1, d1].
%
%   ?- bfs_reach(a1, [a1], R).
%   R = [a1].
%
%   ?- bfs_reach(a1, [b1,c1,d1], R).
%   R = [].   % Start not in Allowed

% bfs_reach(+Start, +Allowed, -Reached) :- % *IMPLEMENTATION HERE*

bfs_reach(_, _, _) :- fail.

% bfs_loop(+Queue, +Allowed, +Visited, -Reached) :- % *IMPLEMENTATION HERE*

bfs_loop(_, _, _, _) :- fail.


%--------------------------------------------------
% 8. all_connected_in(+Cells, +Allowed)  [Lab 12]
%
%   Succeed iff every cell in Cells is reachable from the first cell via
%   BFS restricted to Allowed.
%
%   Hint: call bfs_reach/3 once from the first cell, then check that the
%         result contains every element of Cells.
%
%   ?- all_connected_in([a1,b1], [a1,b1]).
%   true.   % a1 and b1 are ortho-adjacent
%
%   ?- all_connected_in([a1,d1], [a1,d1]).
%   false.  % a1 and d1 are not ortho-adjacent, nothing in between

% all_connected_in(+Cells, +Allowed) :- % *IMPLEMENTATION HERE*

all_connected_in(_, _) :- fail.
