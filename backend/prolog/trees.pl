% ============================================================================
% trees.pl — MODULE WRAPPER, DO NOT EDIT
%
% PROVIDED — do not edit. This file loads the student implementation via
% :- include and exports the module interface unchanged.
%
% Labs that students use in the included file:
%   L07 (Trees) — n-ary tree traversal over the university hierarchy
% ============================================================================

:- module(trees, [
    university_tree/1,
    group_members/3,
    spec_members/3,
    all_groups_of_tree/2,
    in_group/3
]).

% --------------------------------------------------------------------------
% Provided: the university tree fact.
% Shape: fac(Name, [spec(Name, [grupa(Id, [cells...])]), ...])
% --------------------------------------------------------------------------

university_tree(
    fac(cti, [
        spec(calculatoare, [
            grupa(311, [a1, b1, a2, b2]),
            grupa(312, [c1, d1, c2, d2]),
            grupa(313, [a3, b3, a4, b4])
        ]),
        spec(personal, [
            grupa(asistenti, [c3, d3, c4, d4]),
            grupa(cadre,     [a5, b5, c5, d5])
        ])
    ])
).

% --------------------------------------------------------------------------
% Student implementation (lab07_trees.pl) is included below.
% The predicates group_members/3, spec_members/3, all_groups_of_tree/2, and
% in_group/3 are defined there.
% --------------------------------------------------------------------------

:- include('lab07_trees.pl').
