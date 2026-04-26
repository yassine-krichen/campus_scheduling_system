% ============================================================
%  optimizer.pl  [Person 2 — Multi-Criteria Optimizer]
%  Schedule scoring and selection for INSAT Campus Scheduler
%  Milestone 3
%
%  REQUIRED PREDICATES TO IMPLEMENT (Person 2):
%  ---------------------------------------------------
%  schedule_score(+Assignments, -Score)
%    → Compute a composite score for the schedule.
%      Lower Score = better schedule.
%      Suggested formula:
%        Score = TotalEnergy
%               + w1 * DailyImbalance
%               + w2 * RoomFairnessPenalty
%
%  best_schedule(+Schedules, -Best)
%    → Select the schedule with the lowest score.
%
%  compare_schedules(+S1, +S2, ?Order)
%    → Order is (<) if S1 is better than S2, (>) if worse,
%      (=) if equal.  Usable with msort/keysort.
%
%  daily_load_imbalance(+Assignments, -Imbalance)
%    → Measures how unequal energy usage is across days.
%      e.g. standard deviation or max−min of daily totals.
%
%  room_fairness_penalty(+Assignments, -Penalty)
%    → Penalty for over-concentrating sessions in a subset
%      of rooms (e.g. variance of usage counts).
%
%  DESIGN NOTES for Person 2:
%  - Call total_weekly_energy/2 from energy.pl for the
%    energy component of the score.
%  - Document the weight choices (w1, w2) and justify them
%    experimentally in the report.
%  - Avoid enumerating all full-campus schedules; apply
%    scoring to the candidate list returned by
%    generate_n_schedules/2.
% ============================================================

:- module(optimizer, [
    schedule_score/2,
    best_schedule/2,
    compare_schedules/3,
    daily_load_imbalance/2,
    room_fairness_penalty/2
]).

:- use_module(library(lists)).       % sum_list/2, max_list/2, min_list/2
:- use_module(library(aggregate)).   % aggregate_all/3
:- use_module(energy).
:- use_module(time_slots).
:- use_module(buildings_and_rooms).

% Weight constants
w_imbalance(0.5).
w_fairness(0.3).

% ============================================================
%  schedule_score(+Assignments, -Score)
%  Composite: energy + weighted imbalance + weighted fairness.
% ============================================================
schedule_score(Assignments, Score) :-
    total_weekly_energy(Assignments, Energy),
    daily_load_imbalance(Assignments, Imbalance),
    room_fairness_penalty(Assignments, Fairness),
    w_imbalance(W1),
    w_fairness(W2),
    Score is Energy + W1 * Imbalance + W2 * Fairness.

% ============================================================
%  best_schedule(+Schedules, -Best)
%  Returns the schedule with the minimum composite score.
% ============================================================
best_schedule([Only], Only) :- !.
best_schedule([H | T], Best) :-
    best_schedule(T, BestOfRest),
    schedule_score(H, SH),
    schedule_score(BestOfRest, SR),
    (SH =< SR -> Best = H ; Best = BestOfRest).

% ============================================================
%  compare_schedules(+S1, +S2, ?Order)
% ============================================================
compare_schedules(S1, S2, Order) :-
    schedule_score(S1, Sc1),
    schedule_score(S2, Sc2),
    compare(Order, Sc1, Sc2).

% ============================================================
%  daily_load_imbalance(+Assignments, -Imbalance)
%  Max daily energy − min daily energy across active days.
% ============================================================
daily_load_imbalance(Assignments, Imbalance) :-
    findall(DayTotal,
        (   day(D),
            findall(E,
                (   member(assign(C, G, R, slot(D, _I)), Assignments),
                    energy:assignment_energy(assign(C, G, R, slot(D, _I)), E)
                ),
                Es),
            Es \= [],
            sum_list(Es, DayTotal)
        ),
        DayTotals),
    (   DayTotals = []
    ->  Imbalance = 0
    ;   max_list(DayTotals, MaxD),
        min_list(DayTotals, MinD),
        Imbalance is MaxD - MinD
    ).

% ============================================================
%  room_fairness_penalty(+Assignments, -Penalty)
%  Variance of per-room session counts (unnormalised).
% ============================================================
room_fairness_penalty(Assignments, Penalty) :-
    findall(R, member(assign(_, _, R, _), Assignments), Rooms),
    sort(Rooms, UniqueRooms),
    findall(Count,
        (   member(UR, UniqueRooms),
            aggregate_all(count, member(assign(_, _, UR, _), Assignments), Count)
        ),
        Counts),
    (   Counts = []
    ->  Penalty = 0
    ;   length(Counts, Len),
        sum_list(Counts, Total),
        Mean is Total / Len,
        findall(Sq, (member(X, Counts), Sq is (X - Mean)^2), Sqs),
        sum_list(Sqs, SqSum),
        Penalty is SqSum / Len
    ).


