% ============================================================================
% puzzle_02.pl — "UTCN: Aceeași poveste, cast nou"
% Same logical chain as puzzle_01, only the character names differ. The
% solution grid and clue terms are identical (cell IDs are stable).
% ============================================================================

puzzle_title("Restanțele din UTCN — runda 2").
puzzle_difficulty(mediu).

% ---------------------------------------------------------------------------
% Characters
% ---------------------------------------------------------------------------
character(a1, 'Andreea',   student,  311).
character(b1, 'Maria',     student,  311).
character(c1, 'Izabela',   student,  311).
character(d1, 'Larisa',    student,  311).

character(a2, 'Maria',     student,  311).
character(b2, 'Camelia',   profesor, cadre).
character(c2, 'Natalia',   laborant, cadre).
character(d2, 'Ciprian',   profesor, cadre).

character(a3, 'Giulia',    student,  312).
character(b3, 'Alexia',    student,  312).
character(c3, 'Ivett',     student,  312).
character(d3, 'Andreea',   student,  312).

character(a4, 'Ana',       student,  312).
character(b4, 'Tudor',     student,  312).
character(c4, 'Cezar',     student,  312).
character(d4, 'Sebastian', student,  312).

character(a5, 'Iulia',     student,  312).
character(b5, 'Tobias',    student,  312).
character(c5, 'Alexandra', student,  312).
character(d5, 'Laura',     student,  312).

% ---------------------------------------------------------------------------
% Solution (identical layout to puzzle_01)
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
% Clue chain — identical Prolog terms to puzzle_01.
% ---------------------------------------------------------------------------
clue_of(b4, direct_above_role(b4, student, integralist)).
clue_of(b3, between_count(c2, c5, integralist, 2)).
clue_of(c3, between_at_most(a5, d5, integralist, 1)).
clue_of(c4, role_above_count(laborant, restantier, 1)).
clue_of(c1, count_row(5, restantier, 1)).
clue_of(a5, multi([
    direct_neighbor(a5, sus, integralist),
    count_row(4, integralist, 3)
])).
clue_of(d5, count_corner(integralist, 3)).
clue_of(a4, claim_status_list([a1, b1], restantier)).
clue_of(d4, multi([
    neighbor_count(b3, restantier, 3),
    neighbor_edge_count(b3, restantier, 1)
])).
clue_of(c2, neighbor_edge_count(c4, restantier, 3)).
clue_of(d3, unique_col_count(c, restantier, 3)).
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
