% ============================================================
%  interface.pl  [Person 2 — Terminal Interface]
%  Display and query predicates for INSAT Campus Scheduler
%
%  REQUIRED PREDICATES TO IMPLEMENT (Person 2):
%  ---------------------------------------------------
%  run_scheduler/0
%    → Main orchestration: generate schedule(s) using config,
%      optionally optimise, then display the result.
%      This predicate overrides the fallback in main.pl.
%
%  display_schedule(+Assignments)
%    → Print a human-readable weekly timetable to stdout.
%      Format: grouped by Day → Slot, with room, course,
%      and group clearly shown.
%
%  display_schedule_for_group(+GroupID, +Assignments)
%    → Filtered view: only assignments for GroupID.
%
%  display_schedule_for_room(+RoomID, +Assignments)
%    → Filtered view: only assignments for RoomID.
%
%  DESIGN NOTES for Person 2:
%  - Use config:setting/2 to read candidate_limit and
%    optimization_mode at runtime.
%  - Use generator:generate_n_schedules/2 to collect
%    candidates, then optimizer:best_schedule/2 to select.
%  - Display should be readable in a terminal: align columns,
%    separate days with clear headers.
%  - Prepare at least one full run screenshot / output log
%    for the defence (demo scenario, then gl3_only or larger).
% ============================================================

:- module(interface, [
    run_scheduler/0,
    display_schedule/1,
    display_schedule_for_group/2,
    display_schedule_for_room/2
]).

:- use_module(library(apply)).            % include/3, maplist/2
:- use_module(config).
:- use_module(generator).
:- use_module(optimizer).
:- use_module(energy).
:- use_module(courses).
:- use_module(time_slots).

% ============================================================
%  run_scheduler/0
%  Main orchestration predicate.  Overrides the fallback
%  defined in main.pl as soon as this module is loaded.
% ============================================================
run_scheduler :-
    setting(scenario,          Sc),
    setting(candidate_limit,   Limit),
    setting(optimization_mode, OptMode),
    format('[scheduler] Scenario    : ~w~n', [Sc]),
    format('[scheduler] Limit       : ~w~n', [Limit]),
    format('[scheduler] Optimise by : ~w~n', [OptMode]),
    nl,
    write('[generator] Building session work list...'), nl,
    build_work_list(WL),
    length(WL, NItems),
    format('[generator] ~w session-items to assign.~n', [NItems]),
    write('[generator] Searching for valid schedules...'), nl,
    generate_n_schedules(Limit, Schedules),
    length(Schedules, Found),
    format('[generator] Found ~w valid schedule(s).~n~n', [Found]),
    (   Schedules = []
    ->  write('No feasible schedule found for this scenario.'), nl,
        write('Suggestions:'), nl,
        write('  - Reduce scenario (set SCHED_SCENARIO=demo)'), nl,
        write('  - Disable energy checks (set SCHED_ENERGY=false)'), nl,
        write('  - Increase limit (set SCHED_LIMIT=5)'), nl
    ;   select_best(OptMode, Schedules, Best),
        display_schedule(Best),
        nl,
        total_weekly_energy(Best, E),
        format('Total weekly energy : ~2f kWh~n', [E]),
        length(Best, NA),
        format('Total assignments   : ~w~n', [NA])
    ).

% select_best(+Mode, +Schedules, -Best)
select_best(none,     [H|_],    H) :- !.
select_best(energy,   Schedules, Best) :- !, best_schedule(Schedules, Best).
select_best(balanced, Schedules, Best) :- !, best_schedule(Schedules, Best).
select_best(_,        [H|_],    H).

% ============================================================
%  display_schedule(+Assignments)
%  Prints the full timetable grouped by Day → Slot.
% ============================================================
display_schedule(Assignments) :-
    nl,
    write('+=============================================================+'), nl,
    write('|           INSAT WEEKLY SCHEDULE                             |'), nl,
    write('+=============================================================+'), nl,
    forall(
        day(D),
        display_day(D, Assignments)
    ),
    write('+-------------------------------------------------------------+'), nl.

display_day(Day, Assignments) :-
    % Only print day header when this day has at least one assignment
    (   member(assign(_, _, _, slot(Day, _)), Assignments)
    ->  format('~n  +-- ~w ~n', [Day]),
        forall(
            member(Idx, [1,2,3,4,5]),
            display_slot(Day, Idx, Assignments)
        )
    ;   true
    ).

display_slot(Day, Idx, Assignments) :-
    findall(assign(C,G,R,slot(Day,Idx)),
            member(assign(C,G,R,slot(Day,Idx)), Assignments),
            SlotAssigns),
    (   SlotAssigns = []
    ->  true                        % slot empty — skip silently
    ;   time_slot(slot(Day,Idx), _, SH, SM, EH, EM),
        format('  |  [~`0t~d~2|:~`0t~d~5| - ~`0t~d~8|:~`0t~d~11|]~n',
               [SH, SM, EH, EM]),
        forall(
            member(assign(C,G,R,slot(Day,Idx)), SlotAssigns),
            print_assignment_line(C, G, R)
        )
    ).

print_assignment_line(C, G, R) :-
    (   course(C, Name, _Dept, _Year, _Spw, _Type, _Eq, _Prof)
    ->  true
    ;   Name = C          % fallback if course name unavailable
    ),
    format('  |      Group: ~w  |  ~w  |  Room: ~w~n', [G, Name, R]).

% ============================================================
%  display_schedule_for_group(+GroupID, +Assignments)
% ============================================================
display_schedule_for_group(GroupID, Assignments) :-
    include(assign_for_group(GroupID), Assignments, Filtered),
    format('~n  Schedule for group: ~w~n', [GroupID]),
    display_schedule(Filtered).

assign_for_group(G, assign(_, G, _, _)).

% ============================================================
%  display_schedule_for_room(+RoomID, +Assignments)
% ============================================================
display_schedule_for_room(RoomID, Assignments) :-
    include(assign_for_room(RoomID), Assignments, Filtered),
    format('~n  Schedule for room: ~w~n', [RoomID]),
    display_schedule(Filtered).

assign_for_room(R, assign(_, _, R, _)).
