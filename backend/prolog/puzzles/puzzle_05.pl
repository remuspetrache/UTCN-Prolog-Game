% ============================================================================
% puzzle_05.pl — "Sesiunea de toamnă"
% Hard hand-crafted puzzle. Unlike puzzles 01-04 the solution grid has no
% full-row uniformity, forcing the solver to combine several different clue
% types before any single cell becomes determined.
%
% Solution grid (I=integralist, R=restantier):
%
%      a    b    c    d
%  1:  I    R    R    I
%  2:  R    I    R    I
%  3:  I    R    I    I
%  4:  R    I    R    R   <- b4 (start) is the only integralist in row 4
%  5:  I    I    R    I
%
% Deduction chain:
%   b4=I  -> count_row(4,R,3)           -> a4=R, c4=R, d4=R
%   a4=R  -> direct_neighbor(sus,I)     -> a3=I
%   c4=R  -> count_corner(I,4)          -> a1=I, d1=I, a5=I, d5=I
%   d4=R  -> count_col(d,I,4)           -> d2=I, d3=I   (uses d1,d5 from above)
%   a3=I  -> count_col(a,I,3)           -> a2=R          (uses a1,a5 from above)
%   a1=I  -> count_row(1,I,2)           -> b1=R, c1=R   (uses d1 from above)
%   d2=I  -> role_count(asistent,I,3)   -> c3=I          (uses d3=I,b4=I known)
%   d3=I  -> neighbor_count(d3,R,3)     -> c2=R          (uses c3=I,c4=R,d4=R)
%   a5=I  -> multi(row5+direct)         -> b5=I, c5=R
%   d5=I  -> count_row(3,R,1)           -> b3=R          (uses a3,c3,d3 from above)
%   b3=R  -> neighbor_count(b3,I,4)     -> b2=I          (last cell)
% ============================================================================

puzzle_title("Sesiunea de toamnă").
puzzle_difficulty(greu).

% ---------------------------------------------------------------------------
% Characters: character(Cell, Name, Role, Group)
% ---------------------------------------------------------------------------
character(a1, 'Oana',     student,  311).
character(b1, 'Dragoș',   student,  311).
character(c1, 'Patricia', student,  311).
character(d1, 'Luca',     student,  311).

character(a2, 'Adrian',   student,  311).
character(b2, 'Daniela',  profesor, cadre).
character(c2, 'Viorica',  laborant, cadre).
character(d2, 'Sergiu',   profesor, cadre).

character(a3, 'Nadia',    student,  313).
character(b3, 'Cristian', student,  313).
character(c3, 'Anca',     asistent, asistenti).
character(d3, 'Miron',    asistent, asistenti).

character(a4, 'Vali',     student,  313).
character(b4, 'Remus',    asistent, asistenti).
character(c4, 'Dorin',    student,  313).
character(d4, 'Radu',     student,  313).

character(a5, 'Florica',  profesor, cadre).
character(b5, 'Toma',     student,  312).
character(c5, 'Irina',    student,  312).
character(d5, 'Pavel',    student,  312).

% ---------------------------------------------------------------------------
% Solution
% ---------------------------------------------------------------------------
solution(a1, integralist).  solution(b1, restantier).
solution(c1, restantier).   solution(d1, integralist).

solution(a2, restantier).   solution(b2, integralist).
solution(c2, restantier).   solution(d2, integralist).

solution(a3, integralist).  solution(b3, restantier).
solution(c3, integralist).  solution(d3, integralist).

solution(a4, restantier).   solution(b4, integralist).
solution(c4, restantier).   solution(d4, restantier).

solution(a5, integralist).  solution(b5, integralist).
solution(c5, restantier).   solution(d5, integralist).

% ---------------------------------------------------------------------------
% Initial reveal
% ---------------------------------------------------------------------------
revealed_at_start(b4).

% ---------------------------------------------------------------------------
% Clue chain
% ---------------------------------------------------------------------------

% Remus (b4): "Suntem singurul integralist din rândul 4."
% -> row 4 has 3 restantierii, so a4=R, c4=R, d4=R.
clue_of(b4, count_row(4, restantier, 3)).

% Vali (a4): "Cel de deasupra mea e integralist."
% -> a3 = integralist.
clue_of(a4, direct_neighbor(a4, sus, integralist)).

% Dorin (c4): "Toți cei 4 colțari sunt integralisti."
% -> a1=I, d1=I, a5=I, d5=I.
clue_of(c4, count_corner(integralist, 4)).

% Radu (d4): "Coloana D are exact 4 integralisti."
% -> combined with d1=I and d5=I (from c4's clue), forces d2=I and d3=I.
clue_of(d4, count_col(d, integralist, 4)).

% Nadia (a3): "Coloana A are exact 3 integralisti."
% -> combined with a1=I and a5=I (forced by c4's clue), forces a2=R.
clue_of(a3, count_col(a, integralist, 3)).

% Oana (a1): "Rândul 1 are exact 2 integralisti."
% -> combined with d1=I (corner), forces b1=R and c1=R.
clue_of(a1, count_row(1, integralist, 2)).

% Luca (d1): flavor only — no longer needed in the deduction chain.
clue_of(d1, flavor("Nu am dormit de trei zile.")).

% Miron (d3): "Am exact 3 vecini restantieri."
% -> d3's neighbors are c2, d2, c3, c4, d4.
%    c3=I is already known (via d2's clue), c4=R and d4=R are known,
%    d2=I — so the three R neighbors are c2, c4, d4, forcing c2=R.
clue_of(d3, neighbor_count(d3, restantier, 3)).

% Florica (a5): "Rândul 5 are 3 integralisti și vecinul din dreapta mea e integralist."
% -> direct_neighbor forces b5=I; then count_row(5,I,3) with a5,b5,d5=I
%    forces c5=R.
clue_of(a5, multi([
    count_row(5, integralist, 3),
    direct_neighbor(a5, dreapta, integralist)
])).

% Pavel (d5): "Rândul 3 are exact un restantier."
% -> a3=I, c3=I, d3=I are already determined; one R in row 3 forces b3=R.
clue_of(d5, count_row(3, restantier, 1)).

% Cristian (b3): "Am exact 4 vecini integralisti."
% -> b3's neighbors: a2, b2, c2, a3, c3, a4, b4, c4.
%    Known at this point: a3=I, c3=I, b4=I (3I) plus a2=R, c2=R, a4=R, c4=R.
%    Unknown: b2. Need 4I total → b2=I forced. This is the last cell.
clue_of(b3, neighbor_count(b3, integralist, 4)).

% ---------------------------------------------------------------------------
% Flavor clues (no logical content)
% ---------------------------------------------------------------------------
clue_of(b1, flavor("De ce naiba am ales această facultate?")).
clue_of(c1, flavor("Teza de laborator mi-a dat de gândit.")).
clue_of(a2, flavor("Mă duc la profesori mâine... poate.")).
clue_of(b2, flavor("Am corectat 60 de teze, nu mai pot.")).
clue_of(c2, flavor("Laboratorul e ocupat până la noapte.")).
clue_of(d2, role_count(asistent, integralist, 3)).
clue_of(c3, flavor("Nici eu nu știam că e sesiune.")).
clue_of(b5, flavor("A, s-a terminat sesiunea? Nu știam.")).
clue_of(c5, flavor("Măcar am participat la cursuri.")).
