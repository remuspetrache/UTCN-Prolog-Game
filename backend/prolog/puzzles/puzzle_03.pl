% ============================================================================
% puzzle_01.pl — "UTCN: Restantierii din spatele clasei"
% Hand-crafted Romanian puzzle. The deduction chain is described in
% new_game.txt and uses several custom clue kinds defined in clues.pl
% (multi, claim_status_list, direct_above_role, between_at_most,
% role_above_count, neighbor_edge_count, unique_col_count).
% ============================================================================

% Loaded as plain facts into the user module by prolog_bridge.py; relies on
% puzzle_facts.pl having declared character/4, clue_of/2, etc. as
% dynamic + discontiguous.

puzzle_title("Restanțele din UTCN").
puzzle_difficulty(mediu).

% ---------------------------------------------------------------------------
% Characters: character(Cell, Name, Role, Group)
% ---------------------------------------------------------------------------
character(a1, 'Andreea',  student,  311).
character(b1, 'Delia',    student,  311).
character(c1, 'Ioana',    student,  311).
character(d1, 'Timotei',  student,  311).

character(a2, 'Raul',     student,  311).
character(b2, 'Camelia',  profesor, cadre).
character(c2, 'Natalia',  laborant, cadre).
character(d2, 'Ciprian',  profesor, cadre).

character(a3, 'Arina',    student,  312).
character(b3, 'Eduard',   student,  312).
character(c3, 'Alexia',   student,  312).
character(d3, 'Marius',   student,  312).

character(a4, 'Tania',    student,  312).
character(b4, 'Remus',    asistent, asistenti).
character(c4, 'Stefania', student,  312).
character(d4, 'Mihai',    student,  312).

character(a5, 'Doru',     asistent, asistenti).
character(b5, 'Ioan',     student,  312).
character(c5, 'Adrian',   student,  312).
character(d5, 'Octavian', student,  312).

% ---------------------------------------------------------------------------
% Solution
% ---------------------------------------------------------------------------
solution(a1, restantier).  solution(b1, restantier).
solution(c1, restantier).  solution(d1, integralist).

solution(a2, restantier).  solution(b2, restantier).
solution(c2, restantier).  solution(d2, integralist).

solution(a3, integralist). solution(b3, integralist).
solution(c3, integralist). solution(d3, restantier).

solution(a4, integralist). solution(b4, integralist).
solution(c4, integralist). solution(d4, restantier).

solution(a5, integralist). solution(b5, integralist).
solution(c5, restantier).  solution(d5, integralist).

% ---------------------------------------------------------------------------
% Initial reveal
% ---------------------------------------------------------------------------
revealed_at_start(b4).

% ---------------------------------------------------------------------------
% Clue chain (see new_game.txt for the deduction story).
% ---------------------------------------------------------------------------

% Remus (b4): "studentul de deasupra mea e integralist" -> b3 = int.
clue_of(b4, direct_above_role(b4, student, integralist)).

% Eduard (b3): "intre Natalia (c2) si Adrian (c5) sunt 2 integralisti"
% -> c3 = int, c4 = int (the only two cells strictly between c2 and c5).
clue_of(b3, between_count(c2, c5, integralist, 2)).

% Alexia (c3): "intre Doru (a5) si Octavian (d5) cel mult 1 integralist".
clue_of(c3, between_at_most(a5, d5, integralist, 1)).

% Stefania (c4): "exact un laborant are un restantier deasupra lui"
% -> Natalia is the only laborant; her cell-above (c1) becomes rest.
clue_of(c4, role_above_count(laborant, restantier, 1)).

% Ioana (c1): "pe randul 5 exista un singur restantier"
% combined with C3 forces a5 = int, d5 = int.
clue_of(c1, count_row(5, restantier, 1)).

% Doru (a5): "direct deasupra mea e unul din cei 3 integralisti din rand 4".
% Encoded as: above me is integralist AND row 4 has exactly 3 integralisti.
clue_of(a5, multi([
    direct_neighbor(a5, sus, integralist),
    count_row(4, integralist, 3)
])).

% Octavian (d5): "exact 3 integralisti in colturi".
clue_of(d5, count_corner(integralist, 3)).

% Tania (a4): "Andreea (a1) si Delia (b1) sunt restantiere".
clue_of(a4, claim_status_list([a1, b1], restantier)).

% Mihai (d4): "Doar unul din cei 3 vecini restantieri ai lui Eduard e pe muchie".
% Encoded as: Eduard has exactly 3 rest neighbours AND exactly 1 is on edge.
clue_of(d4, multi([
    neighbor_count(b3, restantier, 3),
    neighbor_edge_count(b3, restantier, 1)
])).

% Natalia (c2): "Stefania are 3 vecini restantieri pe muchie" -> Marius = rest.
clue_of(c2, neighbor_edge_count(c4, restantier, 3)).

% Marius (d3): "coloana C e singura coloana cu exact 3 restantieri".
clue_of(d3, unique_col_count(c, restantier, 3)).

% Ioan (b5): "Raul are exact 2 vecini integralisti" -> a3 = int, a2 = rest.
clue_of(b5, neighbor_count(a2, integralist, 2)).

% --- Flavor clues ----------------------------------------------------------
clue_of(a1, flavor("Nu-i adevărat!")).
clue_of(b1, flavor("Nu-mi place jocul ăsta.")).
clue_of(d1, flavor("Păi și normal, dacă am învățat.")).
clue_of(b2, flavor("Restantier o să fie cine a făcut jocul ăsta.")).
clue_of(c5, flavor("Cum să am restanță dacă încă nici nu a început sesiunea?")).
clue_of(d2, flavor("Așa mă gândeam și eu.")).
clue_of(a3, flavor("Phew, la limită.")).
clue_of(a2, flavor("Am auzit că ne trece pe toți în toamnă oricum.")).
