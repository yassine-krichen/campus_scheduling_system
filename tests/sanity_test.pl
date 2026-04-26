% ============================================================
%  sanity_test.pl
%  Basic sanity checks for the INSAT Scheduler Knowledge Base
% ============================================================

:- use_module('../src/groups').
:- use_module('../src/buildings_and_rooms').
:- use_module('../src/courses').

run_tests :-
    test_groups_load,
    test_rooms_load,
    test_courses_load,
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
