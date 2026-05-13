% ============================================================================
% graph.pl — MODULE WRAPPER, DO NOT EDIT
%
% PROVIDED — do not edit. This file loads the student implementation via
% :- include and exports the module interface unchanged.
%
% Labs that students use in the included file:
%   L11 (Graphs)          — dynamic neighbor facts, adjacency predicates
%   L12 (Graph Traversal) — BFS connectivity check
% ============================================================================

:- module(graph, [
    neighbor/2,
    ortho_neighbor/2,
    neighbors_of/2,
    ortho_neighbors_of/2,
    common_neighbors/3,
    common_neighbors_count/4,
    bfs_reach/3,
    all_connected_in/2
]).

:- use_module(board).

:- dynamic neighbor/2.
:- dynamic ortho_neighbor/2.

% build_neighbors/0 is called on load via :- initialization/1 so that all
% neighbor/2 and ortho_neighbor/2 facts exist before any query.
:- initialization(build_neighbors).

% --------------------------------------------------------------------------
% Student implementation (lab11_12_graph.pl) is included below.
% The predicates build_neighbors/0, diag_adjacent/2, ortho_adjacent/2,
% neighbors_of/2, ortho_neighbors_of/2, common_neighbors/3, common_neighbors_count/4,
% bfs_reach/3, and all_connected_in/2 are defined there.
% --------------------------------------------------------------------------

:- include('lab11_12_graph.pl').
