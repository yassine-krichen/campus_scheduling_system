% ============================================================
%  generator.pl  [Person 1 — Schedule Generator]
%  Recursive schedule generator for INSAT Campus Scheduler
%  Logical Programming Project — Spring 2026
%
%  PUBLIC API
%  ----------
%  generate_schedule(-Assignments)
%      Produces one valid assignment list for the active
%      scenario (controlled by config.pl).
%
%  generate_n_schedules(+N, -Schedules)
%      Collects up to N valid schedules via findnsols/4.
%
%  build_work_list(-WorkList)
%      Expands course_session/2 pairs by SessionsPerWeek into
%      a flat list of work_item(C,G) terms.  Also exported so
%      main.pl can query it for diagnostic output.
%
%  DESIGN NOTES — Early Failure
%  ----------------------------
%  The generator iterates over (Course × Group) pairs that
%  belong to the active scenario.  For each pair it must
%  assign SessionsPerWeek distinct (Room, Slot) combinations.
%
%  Constraint checking is done INCREMENTALLY:
%    • all_constraints_satisfied/2 from constraints.pl is
%      called for EACH candidate before appending it to the
%      partial list.  This implements chronological
%      backtracking with early pruning.
%    • Energy constraints from energy.pl are also checked
%      per assignment (building threshold not exceeded).
%
%  Slot ordering  Monday→Saturday, index 1→5 means the
%  generator naturally fills mornings before afternoons,
%  producing compact schedules without extra heuristics.
%
%  Session repetition:
%    A course with SessionsPerWeek = 2 means that the same
%    (CourseID, GroupID) pair must be scheduled TWICE in the
%    week.  expand_sessions/2 flattens this into N copies of
%    work_item(C,G) so assign_all/3 treats each independently.
% ============================================================

:- module(generator, [
    generate_schedule/1,
    generate_n_schedules/2,
    build_work_list/1
]).

:- use_module(library(solution_sequences)).  % findnsols/4
:- use_module(courses).
:- use_module(buildings_and_rooms).
:- use_module(time_slots).
:- use_module(groups).
:- use_module(constraints).
:- use_module(energy).
:- use_module(config).

% ============================================================
%  GENERATE A SINGLE VALID SCHEDULE
%  generate_schedule(-Assignments)
%
%  Entry point.  Builds the work list from the active
%  scenario, then assigns each (CourseID, GroupID) session.
% ============================================================
generate_schedule(Assignments) :-
    build_work_list(WorkList),
    assign_all(WorkList, [], Assignments).

% ============================================================
%  GENERATE UP TO N VALID SCHEDULES
%  generate_n_schedules(+N, -Schedules)
%
%  Uses findnsols/4 from library(solution_sequences).
%  Returns a list of at most N schedules.
% ============================================================
generate_n_schedules(N, Schedules) :-
    findnsols(N, S, generate_schedule(S), Schedules).

% ============================================================
%  BUILD WORK LIST
%  build_work_list(-WorkList)
%
%  WorkList is a flat list of work_item(CourseID, GroupID)
%  terms, each representing one session that must be
%  scheduled.  A course with sessions_per_week = 2 and 3
%  groups generates 6 items.
%
%  Only courses/groups belonging to the active scenario are
%  included (via config predicates).
% ============================================================
build_work_list(WorkList) :-
    scenario_courses(ActiveCourses),
    scenario_groups(ActiveGroups),
    findall(wi(C, G, Spw),
        (   member(C, ActiveCourses),
            course_session(C, G),
            member(G, ActiveGroups),
            course(C, _Name, _Dept, _Year, Spw, _Type, _Eq, _Prof)
        ),
        RawItems),
    expand_sessions(RawItems, WorkList).

% expand_sessions(+RawItems, -WorkList)
%  Repeats each wi(C,G,N) N times as work_item(C,G).
expand_sessions([], []).
expand_sessions([wi(C, G, N) | Rest], Expanded) :-
    N > 0,
    replicate(N, work_item(C, G), Items),
    expand_sessions(Rest, RestExpanded),
    append(Items, RestExpanded, Expanded).

% replicate(+N, +Elem, -List)
replicate(0, _, []) :- !.
replicate(N, E, [E|Rest]) :-
    N > 0,
    N1 is N - 1,
    replicate(N1, E, Rest).

% ============================================================
%  MAIN ASSIGNMENT LOOP
%  assign_all(+WorkList, +Partial, -FinalAssignments)
%
%  Base case: work list empty → return accumulated schedule.
%  Recursive: pick head item, find a valid (Room,Slot) via
%  assign_one/4, prepend result, recurse on tail.
% ============================================================
assign_all([], Acc, Acc).
assign_all([work_item(C, G) | Rest], Partial, Final) :-
    assign_one(C, G, Partial, NewAssign),
    assign_all(Rest, [NewAssign | Partial], Final).

% ============================================================
%  ASSIGN ONE SESSION
%  assign_one(+CourseID, +GroupID, +Partial, -Assignment)
%
%  Iterates over (Slot × Room) candidates via backtracking.
%  For each candidate, verifies ALL hard constraints
%  (constraints.pl) BEFORE committing — early-failure.
%
%  Slot/Room ordering: slots iterate in natural (day, index)
%  order to produce compact schedules.  Rooms iterate in the
%  order they appear in buildings_and_rooms.pl.
% ============================================================
assign_one(CourseID, GroupID, Partial,
           assign(CourseID, GroupID, RoomID, Slot)) :-
    % Choose a slot (iterate via backtracking from time_slots.pl)
    time_slot(Slot, _Day, _SH, _SM, _EH, _EM),
    % Choose a room (iterate via backtracking from buildings_and_rooms.pl)
    room(RoomID, _Building, _Floor, _Cap, _Equip, _ERate),
    % Build candidate
    Candidate = assign(CourseID, GroupID, RoomID, Slot),
    % Check all hard constraints incrementally (cheapest first)
    all_constraints_satisfied(Candidate, Partial),
    % Check building energy threshold (only if enabled in config)
    check_energy_constraint(Candidate, Partial).

% ============================================================
%  INCREMENTAL ENERGY CONSTRAINT
%  check_energy_constraint(+NewAssign, +Partial)
%
%  If energy constraints are disabled in config, always
%  succeeds.  Otherwise asks building_energy_ok/3 whether
%  adding NewAssign to Partial keeps the affected building
%  within its daily threshold for the affected day.
%
%  NOTE: we use named variables (C2, G2, Idx2) so that the
%  new assignment term is properly reconstructed in the body
%  rather than silently creating fresh anonymous variables.
% ============================================================
check_energy_constraint(assign(C2, G2, RoomID, slot(Day, Idx2)), Partial) :-
    setting(enable_energy_constraints, Flag),
    (   Flag = false
    ->  true
    ;   room(RoomID, Building, _Floor, _Cap, _Equip, _ERate),
        % Project the partial list *with* the new assignment included
        ProposedSlot = slot(Day, Idx2),
        ProposedList = [assign(C2, G2, RoomID, ProposedSlot) | Partial],
        building_energy_ok(Day, ProposedList, Building)
    ).
