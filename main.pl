% ============================================================
%  main.pl — INSAT Intelligent Campus Scheduling System
%  Logical Programming Project — Spring 2026
%  INSAT GL3
%
%  Entry point: load this file into SWI-Prolog.
%
%  Usage:
%    swipl main.pl
%    ?- run_scheduler.
%
%  Or in script mode (exits after running):
%    swipl -g run_scheduler -t halt main.pl
%
%  Environment overrides (before launching swipl):
%    set SCHED_SCENARIO=demo          (demo | gl3_only | engineering | full_campus)
%    set SCHED_LIMIT=1                (max schedules to collect)
%    set SCHED_OPT=none               (none | energy | balanced)
%    set SCHED_ENERGY=true            (true | false)
%
%  Module loading order:
%    1. config          [Person 1] — scenario / tunable settings
%    2. time_slots      [KB]       — temporal facts
%    3. buildings_and_rooms [KB]   — spatial facts + energy rates
%    4. groups          [KB]       — student group facts
%    5. instructors     [KB]       — instructor facts + availability
%    6. courses         [KB]       — course facts + course_session/2
%    7. constraints     [Person 1] — hard constraint predicates
%    8. generator       [Person 1] — recursive schedule builder
%    9. energy          [Person 2] — energy accumulation & thresholds
%   10. optimizer       [Person 2] — multi-criteria schedule ranking
%   11. interface       [Person 2] — display and query predicates
% ============================================================

:- use_module(src/config).
:- use_module(src/time_slots).
:- use_module(src/buildings_and_rooms).
:- use_module(src/groups).
:- use_module(src/instructors).
:- use_module(src/courses).
:- use_module(src/constraints).
:- use_module(src/generator).
:- use_module(src/energy).
:- use_module(src/optimizer).
:- use_module(src/interface).
:- use_module(library(apply)).   % include/3 for convenience predicates

% ============================================================
%  INITIALIZATION
%  The :- initialization(..., main) directive is called after
%  all modules are loaded.  It calls main/0 which then
%  delegates to run_scheduler/0 (defined in interface.pl or
%  here as fallback).
% ============================================================
:- initialization(main, main).

main :-
    print_banner,
    run_scheduler.

% ============================================================
%  BANNER
% ============================================================
print_banner :-
    nl,
    write('===================================================='), nl,
    write('  INSAT Intelligent Campus Scheduling System'), nl,
    write('  Logical Programming Project — Spring 2026'), nl,
    write('  INSAT GL3'), nl,
    write('===================================================='), nl,
    setting(scenario, Sc),
    setting(candidate_limit, Lim),
    setting(optimization_mode, Opt),
    setting(enable_energy_constraints, Energy),
    format('  Scenario         : ~w~n', [Sc]),
    format('  Candidate limit  : ~w~n', [Lim]),
    format('  Optimization     : ~w~n', [Opt]),
    format('  Energy checks    : ~w~n', [Energy]),
    write('===================================================='), nl, nl.

% ============================================================
%  RUN_SCHEDULER/0  (fallback — overridden by interface.pl)
%
%  This minimal implementation allows the system to run even
%  if interface.pl is not yet complete (Person 2 stub).
%  interface.pl defines a richer version that supersedes this.
% ============================================================
% run_scheduler/0 is defined in interface.pl and imported via use_module.
% The predicate below is a safeguard for the case interface.pl fails to load.
run_scheduler :-
    run_scheduler_fallback.

run_scheduler_fallback :-
    setting(candidate_limit, Limit),
    write('[generator] Building work list...'), nl,
    (   catch(
            build_work_list(WL),
            Err,
            (format('[ERROR] build_work_list failed: ~w~n', [Err]), fail)
        )
    ->  length(WL, NItems),
        format('[generator] Work list: ~w session-items to assign.~n', [NItems]),
        write('[generator] Searching for valid schedules...'), nl,
        generate_n_schedules(Limit, Schedules),
        length(Schedules, Found),
        format('[generator] Found ~w schedule(s).~n', [Found]),
        (   Schedules = [Best | _]
        ->  print_schedule_summary(Best)
        ;   write('[generator] No valid schedule found for this scenario.'), nl
        )
    ;   write('[generator] Failed to build work list. Check config/scenario.'), nl
    ).

% ============================================================
%  PRINT_SCHEDULE_SUMMARY/1
%  Minimal schedule printer used by the fallback path.
%  interface.pl provides a richer display.
% ============================================================
print_schedule_summary(Schedule) :-
    nl,
    write('----------------------------------------------------'), nl,
    write('  Schedule Summary'), nl,
    write('----------------------------------------------------'), nl,
    length(Schedule, N),
    format('  Total assignments : ~w~n', [N]),
    (   predicate_property(total_weekly_energy(_, _), defined)
    ->  total_weekly_energy(Schedule, E),
        format('  Total weekly energy: ~2f kWh~n', [E])
    ;   true
    ),
    nl,
    write('  Assignments (CourseID / GroupID / RoomID / Slot):'), nl,
    print_assignments(Schedule).

print_assignments([]).
print_assignments([assign(C, G, R, slot(Day, Idx)) | Rest]) :-
    format('    ~w  |  ~w  |  ~w  |  ~w slot ~w~n', [C, G, R, Day, Idx]),
    print_assignments(Rest).

% ============================================================
%  CONVENIENCE QUERY PREDICATES
%  These can be called interactively at the ?- prompt.
% ============================================================

% schedule_for_group(+GroupID, -Assignments)
%   Returns all assignments for a given group from a freshly
%   generated schedule.
schedule_for_group(GroupID, GroupAssignments) :-
    generate_schedule(Schedule),
    include(assignment_for_group(GroupID), Schedule, GroupAssignments).

assignment_for_group(G, assign(_, G, _, _)).

% schedule_for_room(+RoomID, -Assignments)
schedule_for_room(RoomID, RoomAssignments) :-
    generate_schedule(Schedule),
    include(assignment_for_room(RoomID), Schedule, RoomAssignments).

assignment_for_room(R, assign(_, _, R, _)).

% validate_schedule(+Schedule)
%   Post-hoc validation: recheck every hard constraint on a
%   complete schedule.  Useful for testing.
validate_schedule(Schedule) :-
    write('[validate] Checking room conflicts...'), nl,
    no_room_conflict(Schedule),
    write('[validate] OK — no room conflicts.'), nl,
    write('[validate] Checking group conflicts...'), nl,
    no_group_conflict(Schedule),
    write('[validate] OK — no group conflicts.'), nl,
    write('[validate] All hard constraints satisfied.'), nl.
