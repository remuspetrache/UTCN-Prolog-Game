% ============================================================================
% solver.pl — MODULE WRAPPER, DO NOT EDIT
%
% PROVIDED — do not edit. This file loads the student implementation via
% :- include and exports the module interface unchanged.
%
% Labs that students use in the included file:
%   L04 (Cut + Negation-as-Failure) — forced/2, has_consistent_world/2
%   L08 (Incomplete Structures)     — build_initial_world/1, pin_cell/3, search/2
% ============================================================================

:- module(solver, [
    forced/2,
    has_consistent_world/2,
    build_initial_world/1,
    pin_cell/3,
    search/2,
    solve_complete/1,
    possible_status/2
]).

:- use_module(board).
:- use_module(graph).
:- use_module(clues).
:- use_module(state).

% --------------------------------------------------------------------------
% Provided utilities — DO NOT MODIFY.
% --------------------------------------------------------------------------

% opposite_status/2 — used by forced/2 to get the other candidate status.
opposite_status(integralist, restantier).
opposite_status(restantier, integralist).

% possible_status(+Cell, -Status): enumerate statuses that have at least one
% consistent world. Used by the hint system.
possible_status(Cell, Status) :-
    member(Status, [integralist, restantier]),
    has_consistent_world(Cell, Status).

% solve_complete(-Assignment): find one full consistent assignment.
% Used by verifier/generator; depends on search/2 being implemented.
solve_complete(Assignment) :-
    build_initial_world(World),
    state:all_revealed_clues(Clues),
    search(World, Clues),
    findall(C-S, member(cell(C, S), World), Assignment).

% --------------------------------------------------------------------------
% Student implementation (lab04_08_solver.pl) is included below.
% The predicates forced/2, has_consistent_world/2, build_initial_world/1,
% pin_cell/3, and search/2 are defined there.
% --------------------------------------------------------------------------

:- include('lab04_08_solver.pl').
