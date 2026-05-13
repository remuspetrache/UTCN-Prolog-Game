% ============================================================================
% evidence.pl — MODULE WRAPPER, DO NOT EDIT
%
% PROVIDED — do not edit. This file loads the student implementation via
% :- include and exports the module interface unchanged.
%
% Labs that students use in the included file:
%   L09 (Difference Lists) — O(1) append evidence log
% ============================================================================

:- module(evidence, [
    empty_evidence/1,
    add_evidence_dl/3,
    evidence_list/2,
    evidence_length/2
]).

% --------------------------------------------------------------------------
% Student implementation (lab09_evidence.pl) is included below.
% The predicates empty_evidence/1, add_evidence_dl/3, evidence_list/2, and
% evidence_length/2 are defined there.
% --------------------------------------------------------------------------

:- include('lab09_evidence.pl').
