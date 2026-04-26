% ============================================================
%  constraints.pl  [Person 1 — Constraint Engine]
%  Hard feasibility constraints for INSAT Campus Scheduler
%  Logical Programming Project — Spring 2026
%
%  DESIGN RATIONALE — constraint ordering for early failure:
%
%  When assign_session/4 in generator.pl tries to add a new
%  assignment A = assign(C, G, R, Slot) to a partial list,
%  the checks are applied in this order (cheapest / most
%  discriminating first):
%
%    1. equipment_satisfied/2      — pure fact lookup, O(1)
%    2. capacity_satisfied/3       — pure fact lookup, O(1)
%    3. instructor_available_for/2 — fact + CWA check, O(1)
%    4. no_room_conflict/1         — linear in partial list
%    5. no_group_conflict/1        — linear in partial list
%
%  Checks 1–3 depend only on static KB facts and are checked
%  BEFORE scanning the partial assignment list.  They prune
%  the majority of (room, slot) candidates with zero list
%  traversal, drastically reducing the branching factor.
%
%  The combined predicate all_constraints_satisfied/2 (which
%  takes the new assignment separately from the existing list)
%  encodes this order explicitly so the generator can call a
%  single predicate per candidate.
%
%  EXPORTS
%  -------
%  no_room_conflict(+Assignments)
%  no_group_conflict(+Assignments)
%  capacity_satisfied(+CourseID, +GroupID, +RoomID)
%  equipment_satisfied(+CourseID, +RoomID)
%  instructor_available_for(+CourseID, +Slot)
%  all_constraints_satisfied(+NewAssign, +ExistingAssignments)
% ============================================================

:- module(constraints, [
    no_room_conflict/1,
    no_group_conflict/1,
    capacity_satisfied/3,
    equipment_satisfied/2,
    instructor_available_for/2,
    all_constraints_satisfied/2
]).

:- use_module(buildings_and_rooms).
:- use_module(groups).
:- use_module(courses).
:- use_module(instructors).
:- use_module(time_slots).

% ============================================================
%  1. EQUIPMENT CONSTRAINT
%  equipment_satisfied(+CourseID, +RoomID)
%
%  Succeeds iff the room's equipment type satisfies the
%  course's equipment requirement, using the compatibility
%  table defined in buildings_and_rooms.pl.
%
%  Early-fail value: very high — eliminates all lab courses
%  from lecture rooms and vice-versa immediately.
% ============================================================
equipment_satisfied(CourseID, RoomID) :-
    course(CourseID, _Name, _Dept, _Year, _Spw, _Type,
           RequiredEquip, _ProfID),
    room(RoomID, _Building, _Floor, _Cap, RoomEquip, _Energy),
    equipment_compatible(RoomEquip, RequiredEquip).

% ============================================================
%  2. CAPACITY CONSTRAINT
%  capacity_satisfied(+CourseID, +GroupID, +RoomID)
%
%  Succeeds iff the room capacity >= the group's enrollment.
%
%  Early-fail value: high — small rooms are eliminated for
%  large groups without touching the partial list.
% ============================================================
capacity_satisfied(_CourseID, GroupID, RoomID) :-
    group_size(GroupID, Enrollment),
    room(RoomID, _Building, _Floor, Capacity, _Equip, _Energy),
    Capacity >= Enrollment.

% ============================================================
%  3. INSTRUCTOR AVAILABILITY CONSTRAINT
%  instructor_available_for(+CourseID, +Slot)
%
%  Succeeds iff the instructor assigned to CourseID is
%  available on the day and slot index of Slot.
%
%  Uses the closed-world availability model from
%  instructors.pl: available unless explicitly listed as
%  unavailable.
% ============================================================
instructor_available_for(CourseID, slot(Day, Index)) :-
    course(CourseID, _Name, _Dept, _Year, _Spw, _Type,
           _Equip, ProfID),
    instructor_available(ProfID, Day, Index).

% ============================================================
%  4. NO ROOM CONFLICT
%  no_room_conflict(+Assignments)
%
%  Succeeds iff no two assignments in the list share the same
%  (RoomID, Slot) pair — i.e. no room is double-booked.
%
%  Used for checking the entire list.  The incremental version
%  (used by the generator) is room_free_for/3 below.
% ============================================================
no_room_conflict([]).
no_room_conflict([assign(_C, _G, R, Slot) | Rest]) :-
    \+ member(assign(_C2, _G2, R, Slot), Rest),
    no_room_conflict(Rest).

% room_free_for(+RoomID, +Slot, +Assignments)
%  True iff no existing assignment uses RoomID at Slot.
%  Called incrementally during generation (O(n) in partial
%  list size, but called early after equip/cap checks).
room_free_for(_Room, _Slot, []).
room_free_for(Room, Slot, [assign(_C, _G, R, S) | Rest]) :-
    (Room = R, Slot = S -> fail ; true),
    room_free_for(Room, Slot, Rest).

% ============================================================
%  5. NO GROUP CONFLICT
%  no_group_conflict(+Assignments)
%
%  Succeeds iff no two assignments share the same (GroupID,
%  Slot) — i.e. no student group is in two places at once.
% ============================================================
no_group_conflict([]).
no_group_conflict([assign(_C, G, _R, Slot) | Rest]) :-
    \+ member(assign(_C2, G, _R2, Slot), Rest),
    no_group_conflict(Rest).

% group_free_at(+GroupID, +Slot, +Assignments)
%  Incremental version used during generation.
group_free_at(_Group, _Slot, []).
group_free_at(Group, Slot, [assign(_C, G, _R, S) | Rest]) :-
    (Group = G, Slot = S -> fail ; true),
    group_free_at(Group, Slot, Rest).

% ============================================================
%  COMBINED INCREMENTAL CONSTRAINT CHECK
%  all_constraints_satisfied(+NewAssign, +ExistingAssignments)
%
%  Checks ALL hard constraints for adding NewAssign to the
%  current partial schedule.  The order matches the rationale
%  documented at the top of this file (cheapest first).
%
%  NewAssign = assign(CourseID, GroupID, RoomID, Slot)
% ============================================================
all_constraints_satisfied(assign(C, G, R, Slot), Existing) :-
    % --- Static checks (no list scan) ---
    equipment_satisfied(C, R),
    capacity_satisfied(C, G, R),
    instructor_available_for(C, Slot),
    % --- Conflict checks (scan partial list) ---
    room_free_for(R, Slot, Existing),
    group_free_at(G, Slot, Existing).
