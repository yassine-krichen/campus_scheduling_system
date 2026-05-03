% ============================================================
%  sanity_test.pl
%  Basic sanity checks for the INSAT Scheduler Knowledge Base
% ============================================================

:- use_module('../src/groups').
:- use_module('../src/buildings_and_rooms').
:- use_module('../src/courses').
:- use_module('../src/config').
:- use_module('../src/generator').
:- use_module('../src/constraints').
:- use_module('../src/energy').

run_tests :-
    test_groups_load,
    test_rooms_load,
    test_courses_load,
    test_course_sessions_have_feasible_rooms,
    test_full_campus_prep_selection,
    test_schedule_generation,
    test_energy_threshold_enforced,
    write('All sanity tests passed!'), nl.

test_groups_load :-
    (   group(_, _, _, _)
    ->  write('[test] Groups loaded successfully.'), nl
    ;   write('[test] FAIL: No groups found.'), nl, fail
    ).

test_rooms_load :-
    (   room(_, _, _, _, _, _)
    ->  write('[test] Rooms loaded successfully.'), nl
    ;   write('[test] FAIL: No rooms found.'), nl, fail
    ).

test_courses_load :-
    (   course(_, _, _, _, _, _, _, _)
    ->  write('[test] Courses loaded successfully.'), nl
    ;   write('[test] FAIL: No courses found.'), nl, fail
    ).

test_course_sessions_have_feasible_rooms :-
    (   forall(
            course_session(CourseID, GroupID),
            (   room(RoomID, _, _, _, _, _),
                equipment_satisfied(CourseID, RoomID),
                capacity_satisfied(CourseID, GroupID, RoomID)
            )
        )
    ->  write('[test] Every course/group session has at least one feasible room.'), nl
    ;   write('[test] FAIL: At least one course/group session has no feasible room.'), nl,
        fail
    ).

test_full_campus_prep_selection :-
    setenv('SCHED_SCENARIO', 'full_campus'),
    scenario_courses(Courses),
    scenario_groups(Groups),
    (   member(mpi_analysis_lec, Courses),
        member(mpi_1, Groups),
        member(mpi_13, Groups),
        member(iia_1, Groups),
        member(cba_8, Groups)
    ->  write('[test] Full-campus prep course/group selection works.'), nl
    ;   write('[test] FAIL: Prep courses/groups are not integrated in full_campus.'), nl,
        fail
    ).

test_schedule_generation :-
    setenv('SCHED_SCENARIO', 'demo'),
    setenv('SCHED_ENERGY', 'true'),
    (   generate_schedule(Schedule)
    ->  length(Schedule, N),
        format('[test] Schedule generation succeeded (~w assignments).~n', [N]),
        (   no_room_conflict(Schedule),
            no_group_conflict(Schedule)
        ->  write('[test] Generated schedule has no room/group conflicts.'), nl
        ;   write('[test] FAIL: Generated schedule violates room/group conflicts.'), nl,
            fail
        )
    ;   write('[test] FAIL: No demo schedule found.'), nl,
        fail
    ).

test_energy_threshold_enforced :-
    findall(
        assign(dummy_course, dummy_group, auditorium, slot(monday, 1)),
        between(1, 23, _),
        OverLimitSchedule
    ),
    (   \+ building_energy_ok(monday, OverLimitSchedule, insat_amphi_wing)
    ->  write('[test] Energy threshold violation is rejected.'), nl
    ;   write('[test] FAIL: Energy threshold violation was accepted.'), nl,
        fail
    ).
