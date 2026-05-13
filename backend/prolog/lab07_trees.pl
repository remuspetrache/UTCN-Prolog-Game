% ============================================================================
% lab07_trees.pl — STUDENT FILE
%
% Labs: L07 (Trees)
% Game component: University group tree traversal.
%   The tree encodes UTCN's CTI faculty → specialisations → groups → students.
%   Clues like "there are N integraliști in group 311" require walking this tree.
% Loaded by: trees.pl (wrapper), which is used by clues.pl.
%
% The tree fact is defined in trees.pl (provided) as university_tree/1.
% Its shape is:
%   fac(cti, [
%     spec(calculatoare, [
%       grupa(311, [a1, b1, a2, b2]),
%       grupa(312, [c1, d1, c2, d2]),
%       grupa(313, [a3, b3, a4, b4])
%     ]),
%     spec(personal, [
%       grupa(asistenti, [c3, d3, c4, d4]),
%       grupa(cadre,     [a5, b5, c5, d5])
%     ])
%   ])
%
% IMPORTANT: this is an n-ary tree — each node has a list of children,
% not a left and right subtree. Use recursion over lists, not the binary
% t(K, L, R) pattern from the L07 examples.
% ============================================================================


%--------------------------------------------------
% 1. group_members(+GroupId, +Tree, -Members)  [Lab 07]
%
%   Unify Members with the list of cell atoms that belong to the group
%   identified by GroupId. Walk the fac -> spec -> grupa structure.
%
%   Hint: write separate clauses for when the current node IS the target
%   grupa, when it is a spec, and when it is a fac. Recurse over the
%   children list with a helper predicate.
%
%   ?- university_tree(T), group_members(311, T, M).
%   M = [a1, b1, a2, b2].
%
%   ?- university_tree(T), group_members(cadre, T, M).
%   M = [a5, b5, c5, d5].

% group_members(+GroupId, +Tree, -Members) :- % *IMPLEMENTATION HERE*

group_members(_, _, _) :- fail.


%--------------------------------------------------
% 2. all_groups_of_tree(+Tree, -GroupIds)  [Lab 07]
%
%   Unify GroupIds with the flat list of all group identifiers in the tree.
%   The order mirrors the left-to-right depth-first order of the tree.
%
%   Hint: use findall/3 with a helper that backtracks over all grupa nodes,
%         or use explicit recursion that collects from each spec.
%
%   ?- university_tree(T), all_groups_of_tree(T, Gs).
%   Gs = [311, 312, 313, asistenti, cadre].
%
%   ?- university_tree(T), all_groups_of_tree(T, Gs), length(Gs, N).
%   N = 5.

% all_groups_of_tree(+Tree, -GroupIds) :- % *IMPLEMENTATION HERE*

all_groups_of_tree(_, _) :- fail.


%--------------------------------------------------
% 3. spec_members(+SpecName, +Tree, -Members)  [Lab 07]
%
%   Unify Members with the concatenated list of all cell atoms under the
%   specialisation named SpecName. Concatenate all group member lists.
%
%   Hint: find the spec(SpecName, Groups) node, then use append/3 or
%         recursion to flatten the group member lists.
%
%   ?- university_tree(T), spec_members(calculatoare, T, M).
%   M = [a1, b1, a2, b2, c1, d1, c2, d2, a3, b3, a4, b4].
%
%   ?- university_tree(T), spec_members(personal, T, M).
%   M = [c3, d3, c4, d4, a5, b5, c5, d5].

% spec_members(+SpecName, +Tree, -Members) :- % *IMPLEMENTATION HERE*

spec_members(_, _, _) :- fail.


%--------------------------------------------------
% 4. in_group(+Cell, ?Group, +Tree)  [Lab 07]
%
%   Succeed if Cell appears in the member list of Group in Tree.
%   If Group is unbound, backtrack over all groups that contain Cell.
%
%   Hint: use group_members/3 and member/2.
%
%   ?- university_tree(T), in_group(a1, G, T).
%   G = 311.
%
%   ?- university_tree(T), in_group(z9, _, T).
%   false.

% in_group(+Cell, ?Group, +Tree) :- % *IMPLEMENTATION HERE*

in_group(_, _, _) :- fail.
