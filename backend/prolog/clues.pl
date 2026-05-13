% ============================================================================
% clues.pl
% All clue-kind terms, their truth-checking against a World assignment,
% and their Romanian textual description.
%
% A World is a list [cell(Id, Status), ...] covering all 20 cells, with every
% Status fully ground to either integralist or restantier.
%
% Uses extensively L03 (lists), L04 (cut for determinism) and relies on the
% board.pl (L06), graph.pl (L11-L12) and trees.pl (L07) modules.
% ============================================================================

:- module(clues, [
    check_clue/2,               % check_clue(+Clue, +World)
    describe_clue/2,            % describe_clue(+Clue, -Text)
    describe_clue_for/3,        % describe_clue_for(+Speaker, +Clue, -Text)
    is_flavor/1,
    all_clue_kinds/1
]).

:- discontiguous check_clue/2.
:- discontiguous describe_clue/2.
:- discontiguous role_ro_pl/2.

:- use_module(board).
:- use_module(graph).
:- use_module(trees).

% ---------------------------------------------------------------------------
% Helpers
% ---------------------------------------------------------------------------

cell_status(Id, World, Status) :-
    member(cell(Id, Status), World).

status_count_in(_, [], 0).
status_count_in(Status, [cell(_, S)|T], N) :-
    nonvar(S),
    S == Status, !,
    status_count_in(Status, T, N1),
    N is N1 + 1.
status_count_in(Status, [_|T], N) :-
    status_count_in(Status, T, N).

% select_cells(+Ids, +World, -Sub) — keep only cells with Ids in World.
select_cells([], _, []).
select_cells([Id|Rest], World, [cell(Id, S)|Out]) :-
    member(cell(Id, S), World), !,
    select_cells(Rest, World, Out).
select_cells([_|Rest], World, Out) :-
    select_cells(Rest, World, Out).

% status_ids(+Status, +World, -Ids) — Ids whose Status matches in World.
status_ids(Status, World, Ids) :-
    pick_status_cells(Status, World, Ids).

% Romanian status words
status_ro(integralist, "integralist").
status_ro(restantier,  "restantier").

status_ro_pl(integralist, "integraliști").
status_ro_pl(restantier,  "restantieri").

% status_ro_n(+N, +Status, -Word) — singular when N is 1, plural otherwise.
status_ro_n(N, Status, Word) :-
    N =:= 1, !,
    status_ro(Status, Word).
status_ro_n(_, Status, Word) :-
    status_ro_pl(Status, Word).

% role_ro_n(+N, +Role, -Word) — singular when N is 1, plural otherwise.
role_ro_n(N, Role, Word) :-
    N =:= 1, !,
    role_ro(Role, Word).
role_ro_n(_, Role, Word) :-
    role_ro_pl(Role, Word).

parity_ro(par,   "par").
parity_ro(impar, "impar").

% verb_a_fi(+N, -Verb) — "este" for singular, "sunt" for plural.
verb_a_fi(1, "este") :- !.
verb_a_fi(_, "sunt").

% Character info accessed via a user-defined character/4 predicate in the
% loaded puzzle. For robustness, we call it through ":- discontiguous" via
% meta-calls so this module doesn't need to import it statically.
char_name(Id, Name) :-
    current_predicate(user:character/4),
    user:character(Id, Name, _, _).

char_role(Id, Role) :-
    current_predicate(user:character/4),
    user:character(Id, _, Role, _).

% ---------------------------------------------------------------------------
% Check clause per clue term (a big dispatch).
% ---------------------------------------------------------------------------

check_clue(flavor(_), _) :- !.

check_clue(count_row(R, Status, N), World) :- !,
    cells_in_row(R, Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, N).

check_clue(count_col(C, Status, N), World) :- !,
    cells_in_col(C, Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, N).

check_clue(count_edge(Status, N), World) :- !,
    edge_cells(Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, N).

check_clue(count_corner(Status, N), World) :- !,
    corner_cells(Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, N).

check_clue(parity_row(R, Status, Parity), World) :- !,
    cells_in_row(R, Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, N),
    parity_of(N, Parity).

check_clue(parity_col(C, Status, Parity), World) :- !,
    cells_in_col(C, Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, N),
    parity_of(N, Parity).

check_clue(parity_edge(Status, Parity), World) :- !,
    edge_cells(Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, N),
    parity_of(N, Parity).

check_clue(neighbor_count(Cell, Status, N), World) :- !,
    neighbors_of(Cell, Ns),
    select_cells(Ns, World, Sub),
    status_count_in(Status, Sub, N).

check_clue(neighbor_at_least(Cell, Status, N), World) :- !,
    neighbors_of(Cell, Ns),
    select_cells(Ns, World, Sub),
    status_count_in(Status, Sub, K),
    K >= N.

check_clue(neighbor_at_most(Cell, Status, N), World) :- !,
    neighbors_of(Cell, Ns),
    select_cells(Ns, World, Sub),
    status_count_in(Status, Sub, K),
    K =< N.

check_clue(common_count(A, B, Status, N), World) :- !,
    common_neighbors(A, B, Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, N).

check_clue(between_count(A, B, Status, N), World) :- !,
    cells_between(A, B, Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, N).

check_clue(direct_neighbor(Cell, Dir, Status), World) :- !,
    direct_neighbor_cell(Cell, Dir, Other),
    cell_status(Other, World, Status).

check_clue(row_more(R1, R2, Status), World) :- !,
    cells_in_row(R1, A),
    cells_in_row(R2, B),
    select_cells(A, World, Sa),
    select_cells(B, World, Sb),
    status_count_in(Status, Sa, Na),
    status_count_in(Status, Sb, Nb),
    Na > Nb.

check_clue(row_equal(R1, R2, Status), World) :- !,
    cells_in_row(R1, A),
    cells_in_row(R2, B),
    select_cells(A, World, Sa),
    select_cells(B, World, Sb),
    status_count_in(Status, Sa, Na),
    status_count_in(Status, Sb, Nb),
    Na =:= Nb.

check_clue(col_more(C1, C2, Status), World) :- !,
    cells_in_col(C1, A),
    cells_in_col(C2, B),
    select_cells(A, World, Sa),
    select_cells(B, World, Sb),
    status_count_in(Status, Sa, Na),
    status_count_in(Status, Sb, Nb),
    Na > Nb.

check_clue(all_connected_row(R, Status), World) :- !,
    cells_in_row(R, Ids),
    status_ids(Status, World, StatusAll),
    intersection_list(Ids, StatusAll, Subset),
    all_connected_in(Subset, Subset).

check_clue(all_connected_col(C, Status), World) :- !,
    cells_in_col(C, Ids),
    status_ids(Status, World, StatusAll),
    intersection_list(Ids, StatusAll, Subset),
    all_connected_in(Subset, Subset).

check_clue(group_count(Group, Status, N), World) :- !,
    university_tree(T),
    group_members(Group, T, Members),
    select_cells(Members, World, Sub),
    status_count_in(Status, Sub, N).

check_clue(group_more(G1, G2, Status), World) :- !,
    university_tree(T),
    group_members(G1, T, M1),
    group_members(G2, T, M2),
    select_cells(M1, World, S1),
    select_cells(M2, World, S2),
    status_count_in(Status, S1, N1),
    status_count_in(Status, S2, N2),
    N1 > N2.

check_clue(role_count(Role, Status, N), World) :- !,
    findall(Id, user:character(Id, _, Role, _), Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, N).

check_clue(role_some(Role, Status), World) :- !,
    findall(Id, user:character(Id, _, Role, _), Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, K),
    K >= 1.

check_clue(max_neighbors_unique(Cell, Status), World) :- !,
    all_cells(All),
    neighbors_of(Cell, MyNs),
    select_cells(MyNs, World, MySub),
    status_count_in(Status, MySub, MyN),
    forall_other_less(All, Cell, Status, MyN, World).

% ---------------------------------------------------------------------------
% Compound + custom clue kinds added for the UTCN puzzle set.
% ---------------------------------------------------------------------------

% multi(+Clues): a single clue that is the conjunction of all sub-clues.
check_clue(multi([]), _) :- !.
check_clue(multi([C|Rest]), World) :- !,
    check_clue(C, World),
    check_clue(multi(Rest), World).

% claim_status(+Cell, +Status): direct claim that Cell is Status.
check_clue(claim_status(Cell, Status), World) :- !,
    cell_status(Cell, World, Status).

% claim_status_list(+Cells, +Status): every cell in Cells has Status.
check_clue(claim_status_list([], _), _) :- !.
check_clue(claim_status_list([C|Rest], Status), World) :- !,
    cell_status(C, World, Status),
    check_clue(claim_status_list(Rest, Status), World).

% direct_above_role(+Cell, +Role, +Status):
%   the cell directly above Cell has the given Role and the given Status.
check_clue(direct_above_role(Cell, Role, Status), World) :- !,
    direct_neighbor_cell(Cell, sus, Above),
    user:character(Above, _, Role, _),
    cell_status(Above, World, Status).

% between_at_most(+A, +B, +Status, +N) — at most N Status cells strictly
% between A and B (same row or column).
check_clue(between_at_most(A, B, Status, N), World) :- !,
    cells_between(A, B, Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, K),
    K =< N.

% between_at_least(+A, +B, +Status, +N) — at least N Status cells.
check_clue(between_at_least(A, B, Status, N), World) :- !,
    cells_between(A, B, Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, K),
    K >= N.

% role_above_count(+Role, +Status, +N):
%   exactly N characters with role Role have a cell directly above them
%   whose Status matches.
check_clue(role_above_count(Role, Status, N), World) :- !,
    findall(Above, (
        user:character(Cell, _, Role, _),
        direct_neighbor_cell(Cell, sus, Above)
    ), Aboves),
    select_cells(Aboves, World, Sub),
    status_count_in(Status, Sub, N).

% neighbor_edge_count(+Cell, +Status, +N):
%   exactly N of Cell's neighbours that are on the board edge have Status.
check_clue(neighbor_edge_count(Cell, Status, N), World) :- !,
    neighbors_of(Cell, Ns),
    edge_filter(Ns, Edges),
    select_cells(Edges, World, Sub),
    status_count_in(Status, Sub, N).

% unique_col_count(+Col, +Status, +N):
%   column Col has exactly N cells of Status, and no other column has
%   exactly N cells of Status.
check_clue(unique_col_count(Col, Status, N), World) :- !,
    cells_in_col(Col, Ids),
    select_cells(Ids, World, Sub),
    status_count_in(Status, Sub, N),
    \+ other_col_has_count(Col, Status, N, World).

other_col_has_count(Col, Status, N, World) :-
    col_letter(Other),
    Other \== Col,
    cells_in_col(Other, OIds),
    select_cells(OIds, World, OSub),
    status_count_in(Status, OSub, N).

edge_filter([], []).
edge_filter([H|T], [H|R]) :- is_edge(H), !, edge_filter(T, R).
edge_filter([_|T], R) :- edge_filter(T, R).

% Helper: every other cell has strictly fewer Status-neighbors than MyN.
forall_other_less([], _, _, _, _).
forall_other_less([Id|Rest], Cell, Status, MyN, World) :-
    Id == Cell, !,
    forall_other_less(Rest, Cell, Status, MyN, World).
forall_other_less([Id|Rest], Cell, Status, MyN, World) :-
    neighbors_of(Id, Ns),
    select_cells(Ns, World, Sub),
    status_count_in(Status, Sub, K),
    K < MyN,
    forall_other_less(Rest, Cell, Status, MyN, World).

% ---------------------------------------------------------------------------
% Misc helpers
% ---------------------------------------------------------------------------

parity_of(N, par)   :- 0 is N mod 2, !.
parity_of(N, impar) :- 1 is N mod 2.

intersection_list([], _, []).
intersection_list([X|Xs], L, [X|R]) :- member(X, L), !, intersection_list(Xs, L, R).
intersection_list([_|Xs], L, R) :- intersection_list(Xs, L, R).

% Direct neighbor: cardinal direction inside 4x5 grid.
direct_neighbor_cell(Cell, sus, Other) :-
    cell_coord(Cell, C, R),
    R > 1, R1 is R - 1,
    cell_id(C, R1, Other).
direct_neighbor_cell(Cell, jos, Other) :-
    cell_coord(Cell, C, R),
    R < 5, R1 is R + 1,
    cell_id(C, R1, Other).
direct_neighbor_cell(Cell, stanga, Other) :-
    cell_coord(Cell, C, R),
    col_idx(C, I), I > 1, I1 is I - 1,
    col_idx(C1, I1),
    cell_id(C1, R, Other).
direct_neighbor_cell(Cell, dreapta, Other) :-
    cell_coord(Cell, C, R),
    col_idx(C, I), I < 4, I1 is I + 1,
    col_idx(C1, I1),
    cell_id(C1, R, Other).

is_flavor(flavor(_)).

all_clue_kinds([
    count_row, count_col, count_edge, count_corner,
    parity_row, parity_col, parity_edge,
    neighbor_count, neighbor_at_least, neighbor_at_most,
    common_count, between_count, direct_neighbor,
    row_more, row_equal, col_more,
    all_connected_row, all_connected_col,
    group_count, group_more,
    role_count, role_some,
    max_neighbors_unique,
    flavor
]).

% ---------------------------------------------------------------------------
% describe_clue(+Clue, -Text)
% Produces a Romanian description for the UI.
% ---------------------------------------------------------------------------

describe_clue(flavor(Text), Text) :- !.

describe_clue(count_row(R, Status, N), Text) :- !,
    status_ro_n(N, Status, StatStr),
    verb_a_fi(N, V),
    format(string(Text), "Pe rândul ~w ~w exact ~w ~w.", [R, V, N, StatStr]).

describe_clue(count_col(C, Status, N), Text) :- !,
    status_ro_n(N, Status, StatStr),
    upcase_atom(C, Cu),
    verb_a_fi(N, V),
    format(string(Text), "Pe coloana ~w ~w exact ~w ~w.", [Cu, V, N, StatStr]).

describe_clue(count_edge(Status, N), Text) :- !,
    status_ro_n(N, Status, StatStr),
    verb_a_fi(N, V),
    format(string(Text), "Pe margini ~w exact ~w ~w.", [V, N, StatStr]).

describe_clue(count_corner(Status, N), Text) :- !,
    status_ro_n(N, Status, StatStr),
    verb_a_fi(N, V),
    format(string(Text), "În colțuri ~w exact ~w ~w.", [V, N, StatStr]).

describe_clue(parity_row(R, Status, Par), Text) :- !,
    status_ro_pl(Status, StatStr),
    parity_ro(Par, P),
    format(string(Text), "Numărul de ~w de pe rândul ~w este ~w.", [StatStr, R, P]).

describe_clue(parity_col(C, Status, Par), Text) :- !,
    status_ro_pl(Status, StatStr),
    parity_ro(Par, P),
    upcase_atom(C, Cu),
    format(string(Text), "Numărul de ~w de pe coloana ~w este ~w.", [StatStr, Cu, P]).

describe_clue(parity_edge(Status, Par), Text) :- !,
    status_ro_pl(Status, StatStr),
    parity_ro(Par, P),
    format(string(Text), "Numărul de ~w de pe margini este ~w.", [StatStr, P]).

describe_clue(neighbor_count(Cell, Status, N), Text) :- !,
    vecin_word(N, VW),
    status_ro_n(N, Status, StatStr),
    cell_label(Cell, Lbl),
    format(string(Text), "~w are exact ~w ~w ~w.", [Lbl, N, VW, StatStr]).

describe_clue(neighbor_at_least(Cell, Status, N), Text) :- !,
    vecin_word(N, VW),
    status_ro_n(N, Status, StatStr),
    cell_label(Cell, Lbl),
    format(string(Text), "~w are cel puțin ~w ~w ~w.", [Lbl, N, VW, StatStr]).

describe_clue(neighbor_at_most(Cell, Status, N), Text) :- !,
    vecin_word(N, VW),
    status_ro_n(N, Status, StatStr),
    cell_label(Cell, Lbl),
    format(string(Text), "~w are cel mult ~w ~w ~w.", [Lbl, N, VW, StatStr]).

describe_clue(common_count(A, B, Status, N), Text) :- !,
    vecin_word(N, VW),
    status_ro_n(N, Status, StatStr),
    cell_label(A, La),
    cell_label(B, Lb),
    format(string(Text), "~w și ~w au exact ~w ~w comuni ~w.",
           [La, Lb, N, VW, StatStr]).

describe_clue(between_count(A, B, Status, N), Text) :- !,
    status_ro_n(N, Status, StatStr),
    cell_label(A, La),
    cell_label(B, Lb),
    format(string(Text), "Între ~w și ~w sunt exact ~w ~w.",
           [La, Lb, N, StatStr]).

describe_clue(direct_neighbor(Cell, Dir, Status), Text) :- !,
    status_ro(Status, S),
    cell_label(Cell, Lbl),
    direction_ro(Dir, DStr),
    format(string(Text), "Vecinul direct ~w al lui ~w este ~w.",
           [DStr, Lbl, S]).

describe_clue(row_more(R1, R2, Status), Text) :- !,
    status_ro_pl(Status, StatStr),
    format(string(Text), "Pe rândul ~w sunt mai mulți ~w decât pe rândul ~w.",
           [R1, StatStr, R2]).

describe_clue(row_equal(R1, R2, Status), Text) :- !,
    status_ro_pl(Status, StatStr),
    format(string(Text), "Pe rândurile ~w și ~w este același număr de ~w.",
           [R1, R2, StatStr]).

describe_clue(col_more(C1, C2, Status), Text) :- !,
    status_ro_pl(Status, StatStr),
    upcase_atom(C1, C1u),
    upcase_atom(C2, C2u),
    format(string(Text), "Pe coloana ~w sunt mai mulți ~w decât pe coloana ~w.",
           [C1u, StatStr, C2u]).

describe_clue(all_connected_row(R, Status), Text) :- !,
    status_ro_pl(Status, StatStr),
    format(string(Text), "Toți ~w de pe rândul ~w sunt conectați.", [StatStr, R]).

describe_clue(all_connected_col(C, Status), Text) :- !,
    status_ro_pl(Status, StatStr),
    upcase_atom(C, Cu),
    format(string(Text), "Toți ~w de pe coloana ~w sunt conectați.", [StatStr, Cu]).

describe_clue(group_count(G, Status, N), Text) :- !,
    status_ro_pl(Status, StatStr),
    group_label(G, GL),
    format(string(Text), "În ~w sunt exact ~w ~w.", [GL, N, StatStr]).

describe_clue(group_more(G1, G2, Status), Text) :- !,
    status_ro_pl(Status, StatStr),
    group_label(G1, L1),
    group_label(G2, L2),
    format(string(Text), "În ~w sunt mai mulți ~w decât în ~w.", [L1, StatStr, L2]).

describe_clue(role_count(Role, Status, N), Text) :- !,
    status_ro_pl(Status, StatStr),
    role_ro_pl(Role, RoleStr),
    format(string(Text), "Exact ~w dintre ~w sunt ~w.", [N, RoleStr, StatStr]).

describe_clue(role_some(Role, Status), Text) :- !,
    status_ro(Status, S),
    role_ro(Role, RoleStr),
    format(string(Text), "Cel puțin un ~w este ~w.", [RoleStr, S]).

describe_clue(max_neighbors_unique(Cell, Status), Text) :- !,
    status_ro_pl(Status, StatStr),
    cell_label(Cell, Lbl),
    format(string(Text), "~w are cel mai mare număr de vecini ~w (unic).",
           [Lbl, StatStr]).

% ---------------------------------------------------------------------------
% Descriptions for the new clue kinds.
% ---------------------------------------------------------------------------

describe_clue(multi(Cs), Text) :- !,
    describe_each(Cs, Texts),
    join_strings(Texts, " ", Text).

describe_each([], []).
describe_each([C|Rest], [T|Ts]) :-
    describe_clue(C, T),
    describe_each(Rest, Ts).

join_strings([], _, "").
join_strings([S], _, S) :- !.
join_strings([S|Rest], Sep, Out) :-
    join_strings(Rest, Sep, Tail),
    format(string(Out), "~w~w~w", [S, Sep, Tail]).

describe_clue(claim_status(Cell, Status), Text) :- !,
    cell_label(Cell, Lbl),
    status_ro(Status, S),
    format(string(Text), "~w este ~w.", [Lbl, S]).

describe_clue(claim_status_list(Cells, Status), Text) :- !,
    join_cell_labels(Cells, " și ", Lbls),
    status_ro_pl(Status, StatStr),
    format(string(Text), "~w sunt ~w.", [Lbls, StatStr]).

describe_clue(direct_above_role(Cell, Role, Status), Text) :- !,
    role_ro_def(Role, RoleStr),
    cell_label(Cell, Lbl),
    status_ro(Status, S),
    format(string(Text), "~w de deasupra lui ~w este ~w.",
           [RoleStr, Lbl, S]).

describe_clue(between_at_most(A, B, Status, N), Text) :- !,
    cell_label(A, La),
    cell_label(B, Lb),
    status_ro_n(N, Status, StatStr),
    format(string(Text), "Între ~w și ~w se află cel mult ~w ~w.",
           [La, Lb, N, StatStr]).

describe_clue(between_at_least(A, B, Status, N), Text) :- !,
    cell_label(A, La),
    cell_label(B, Lb),
    status_ro_n(N, Status, StatStr),
    format(string(Text), "Între ~w și ~w se află cel puțin ~w ~w.",
           [La, Lb, N, StatStr]).

describe_clue(role_above_count(Role, Status, N), Text) :- !,
    role_ro_n(N, Role, RoleStr),
    have_word(N, HW),
    status_ro(Status, S),
    format(string(Text),
           "Exact ~w ~w ~w un ~w direct deasupra.",
           [N, RoleStr, HW, S]).

describe_clue(neighbor_edge_count(Cell, Status, N), Text) :- !,
    cell_label(Cell, Lbl),
    vecin_word(N, VW),
    status_ro_n(N, Status, StatStr),
    format(string(Text), "~w are exact ~w ~w ~w pe muchie.",
           [Lbl, N, VW, StatStr]).

describe_clue(unique_col_count(Col, Status, N), Text) :- !,
    upcase_atom(Col, Cu),
    status_ro_n(N, Status, StatStr),
    format(string(Text),
           "Coloana ~w este singura coloană cu exact ~w ~w.",
           [Cu, N, StatStr]).

% "vecin" / "vecini" agreement.
vecin_word(1, "vecin") :- !.
vecin_word(_, "vecini").

% "are" (singular) / "au" (plural) — Romanian verb agreement for "to have".
have_word(1, "are") :- !.
have_word(_, "au").

% Helper: comma-and-join of cell labels.
join_cell_labels([], _, "").
join_cell_labels([C], _, Lbl) :- !,
    cell_label(C, Lbl).
join_cell_labels([C|Rest], Sep, Out) :-
    cell_label(C, Lbl),
    join_cell_labels(Rest, Sep, Tail),
    format(string(Out), "~w~w~w", [Lbl, Sep, Tail]).

% Definite-article forms ("studentul", "asistentul", ...).
role_ro_def(student,       "Studentul").
role_ro_def(asistent,      "Asistentul").
role_ro_def(profesor,      "Profesorul").
role_ro_def(laborant,      "Laborantul").
role_ro_def(secretar,      "Secretarul").
role_ro_def(bibliotecar,   "Bibliotecarul").
role_ro_def(decan,         "Decanul").
role_ro_def(paznic,        "Paznicul").
role_ro_def(informatician, "Informaticianul").

% Cell label — either "<Name> (A3)" if character/4 is loaded, or "A3".
cell_label(Cell, Label) :-
    current_predicate(user:character/4),
    user:character(Cell, Name, _, _), !,
    upcase_atom(Cell, CU),
    format(string(Label), "~w (~w)", [Name, CU]).
cell_label(Cell, Label) :-
    upcase_atom(Cell, Label).

direction_ro(sus,     "de sus").
direction_ro(jos,     "de jos").
direction_ro(stanga,  "din stânga").
direction_ro(dreapta, "din dreapta").

group_label(311, "grupa 311").
group_label(312, "grupa 312").
group_label(313, "grupa 313").
group_label(asistenti, "rândul asistenților").
group_label(cadre,     "rândul cadrelor didactice").
group_label(G, Label) :- format(string(Label), "grupa ~w", [G]).

role_ro(student,       "student").
role_ro(asistent,      "asistent").
role_ro(profesor,      "profesor").
role_ro(laborant,      "laborant").
role_ro(secretar,      "secretar").
role_ro(bibliotecar,   "bibliotecar").
role_ro(decan,         "decan").
role_ro(paznic,        "paznic").
role_ro(informatician, "informatician").

role_ro_pl(student,       "studenți").
role_ro_pl(asistent,      "asistenți").
role_ro_pl(profesor,      "profesori").
role_ro_pl(laborant,      "laboranți").
role_ro_pl(secretar,      "secretari").
role_ro_pl(bibliotecar,   "bibliotecari").
role_ro_pl(decan,         "decani").
role_ro_pl(paznic,        "paznici").

% ---------------------------------------------------------------------------
% describe_clue_for(+Speaker, +Clue, -Text)
% Same as describe_clue/2, but rephrases in first person ("eu", "mine",
% "mea") whenever the clue refers to the Speaker's own cell.
% ---------------------------------------------------------------------------

describe_clue_for(Speaker, Clue, Text) :-
    speaker_clue(Speaker, Clue, Text), !.
describe_clue_for(_, Clue, Text) :-
    describe_clue(Clue, Text).

% --- direct_neighbor / direct_above_role about my own cell ---

speaker_clue(Self, direct_neighbor(Self, Dir, Status), Text) :-
    direction_ro(Dir, DStr),
    status_ro(Status, S),
    format(string(Text), "Vecinul meu direct ~w este ~w.", [DStr, S]).

speaker_clue(Self, direct_above_role(Self, Role, Status), Text) :-
    role_ro_def(Role, RoleStr),
    status_ro(Status, S),
    format(string(Text), "~w de deasupra mea este ~w.", [RoleStr, S]).

% --- counts about my own neighbours ---

speaker_clue(Self, neighbor_count(Self, Status, N), Text) :-
    vecin_word(N, VW),
    status_ro_n(N, Status, StatStr),
    format(string(Text), "Am exact ~w ~w ~w.", [N, VW, StatStr]).

speaker_clue(Self, neighbor_at_least(Self, Status, N), Text) :-
    vecin_word(N, VW),
    status_ro_n(N, Status, StatStr),
    format(string(Text), "Am cel puțin ~w ~w ~w.", [N, VW, StatStr]).

speaker_clue(Self, neighbor_at_most(Self, Status, N), Text) :-
    vecin_word(N, VW),
    status_ro_n(N, Status, StatStr),
    format(string(Text), "Am cel mult ~w ~w ~w.", [N, VW, StatStr]).

speaker_clue(Self, neighbor_edge_count(Self, Status, N), Text) :-
    vecin_word(N, VW),
    status_ro_n(N, Status, StatStr),
    format(string(Text), "Am exact ~w ~w ~w pe muchie.",
           [N, VW, StatStr]).

speaker_clue(Self, max_neighbors_unique(Self, Status), Text) :-
    status_ro_pl(Status, StatStr),
    format(string(Text),
           "Am cel mai mare număr de vecini ~w (unic).", [StatStr]).

% --- between_count / between_at_most / between_at_least ---

speaker_clue(Self, between_count(Self, B, Status, N), Text) :-
    cell_label(B, Lb),
    status_ro_n(N, Status, StatStr),
    format(string(Text), "Între mine și ~w sunt exact ~w ~w.",
           [Lb, N, StatStr]).
speaker_clue(Self, between_count(A, Self, Status, N), Text) :-
    cell_label(A, La),
    status_ro_n(N, Status, StatStr),
    format(string(Text), "Între ~w și mine sunt exact ~w ~w.",
           [La, N, StatStr]).

speaker_clue(Self, between_at_most(Self, B, Status, N), Text) :-
    cell_label(B, Lb),
    status_ro_n(N, Status, StatStr),
    format(string(Text),
           "Între mine și ~w se află cel mult ~w ~w.",
           [Lb, N, StatStr]).
speaker_clue(Self, between_at_most(A, Self, Status, N), Text) :-
    cell_label(A, La),
    status_ro_n(N, Status, StatStr),
    format(string(Text),
           "Între ~w și mine se află cel mult ~w ~w.",
           [La, N, StatStr]).

speaker_clue(Self, between_at_least(Self, B, Status, N), Text) :-
    cell_label(B, Lb),
    status_ro_n(N, Status, StatStr),
    format(string(Text),
           "Între mine și ~w se află cel puțin ~w ~w.",
           [Lb, N, StatStr]).
speaker_clue(Self, between_at_least(A, Self, Status, N), Text) :-
    cell_label(A, La),
    status_ro_n(N, Status, StatStr),
    format(string(Text),
           "Între ~w și mine se află cel puțin ~w ~w.",
           [La, N, StatStr]).

% --- common_count where I am one of the two anchors ---

speaker_clue(Self, common_count(Self, B, Status, N), Text) :-
    vecin_word(N, VW),
    status_ro_n(N, Status, StatStr),
    cell_label(B, Lb),
    format(string(Text), "Eu și ~w avem exact ~w ~w comuni ~w.",
           [Lb, N, VW, StatStr]).
speaker_clue(Self, common_count(A, Self, Status, N), Text) :-
    vecin_word(N, VW),
    status_ro_n(N, Status, StatStr),
    cell_label(A, La),
    format(string(Text), "Eu și ~w avem exact ~w ~w comuni ~w.",
           [La, N, VW, StatStr]).

% --- direct claims that include me ---

speaker_clue(Self, claim_status(Self, Status), Text) :-
    status_ro(Status, S),
    format(string(Text), "Eu sunt ~w.", [S]).

speaker_clue(Self, claim_status_list([Self], Status), Text) :- !,
    status_ro(Status, S),
    format(string(Text), "Eu sunt ~w.", [S]).
speaker_clue(Self, claim_status_list(Cells, Status), Text) :-
    select(Self, Cells, Others),
    Others \== [],
    join_cell_labels(Others, " și ", OtherLbls),
    status_ro_pl(Status, StatStr),
    format(string(Text), "~w și eu suntem ~w.", [OtherLbls, StatStr]).

% --- multi: distribute speaker context to each sub-clue ---

speaker_clue(Speaker, multi(Cs), Text) :-
    Cs \== [],
    describe_each_for(Speaker, Cs, Texts),
    join_strings(Texts, " ", Text).

describe_each_for(_, [], []).
describe_each_for(Speaker, [C|Rest], [T|Ts]) :-
    describe_clue_for(Speaker, C, T),
    describe_each_for(Speaker, Rest, Ts).
role_ro_pl(informatician, "informaticieni").
