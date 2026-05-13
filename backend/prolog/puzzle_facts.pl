% ============================================================================
% puzzle_facts.pl
% Declares the puzzle predicates as dynamic and discontiguous so puzzle
% files can extend them and we can reload puzzles via retractall + consult.
% ============================================================================

:- dynamic character/4.
:- dynamic revealed_at_start/1.
:- dynamic clue_of/2.
:- dynamic solution/2.
:- dynamic puzzle_title/1.
:- dynamic puzzle_difficulty/1.

:- discontiguous character/4.
:- discontiguous clue_of/2.
:- discontiguous solution/2.
