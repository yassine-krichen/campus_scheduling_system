% ============================================================
%  energy.pl  [Person 2 — Energy Reasoner]
%  Energy-aware reasoning for INSAT Campus Scheduler
%  Milestone 2
%
%  DESIGN NOTES for Person 2:
%  - Use slot_duration_hours/1 from time_slots.pl (value: 1.5).
%  - Use room/6 from buildings_and_rooms.pl to get hourly cost.
%  - Use building/3 to get daily threshold per building.
%  - building_energy_ok/3 is called from generator.pl during
%    construction — must work correctly on a PARTIAL list.
%  - Document how energy constraints reduce the solution space
%    and show experimental results (feasibility rate
%    with vs. without energy constraints) in the report.
% ============================================================

:- module(energy, [
    assignment_energy/2,
    building_daily_energy/4,
    building_energy_ok/3,
    all_buildings_energy_ok/2,
    total_weekly_energy/2
]).

:- use_module(library(lists)).     % sum_list/2
:- use_module(buildings_and_rooms).
:- use_module(time_slots).

% ============================================================
%  assignment_energy(+Assignment, -Energy_kWh)
%
%  Energy consumed by one session:
%    Energy = HourlyRate (kW) × SlotDuration (h)
%  SlotDuration is always 1.5 hours (from time_slots.pl).
% ============================================================
assignment_energy(assign(_C, _G, RoomID, _Slot), Energy) :-
    room(RoomID, _Building, _Floor, _Cap, _Equip, HourlyRate),
    slot_duration_hours(Duration),
    Energy is HourlyRate * Duration.

% ============================================================
%  building_daily_energy(+Day, +Assignments, +Building, -Total)
%
%  Sums the energy of all assignments whose room belongs to
%  Building, scheduled on Day, from the given Assignments list.
% ============================================================
building_daily_energy(Day, Assignments, Building, Total) :-
    findall(E,
        (   member(assign(C, G, R, slot(Day, Idx)), Assignments),
            room(R, Building, _Floor, _Cap, _Equip, _Rate),
            assignment_energy(assign(C, G, R, slot(Day, Idx)), E)
        ),
        Energies),
    sum_list(Energies, Total).

% ============================================================
%  building_energy_ok(+Day, +Assignments, +Building)
%
%  Succeeds iff the total energy used by Building on Day
%  does not exceed its daily threshold.
%  Safe to call on a partial assignment list (used by generator).
% ============================================================
building_energy_ok(Day, Assignments, Building) :-
    building(Building, _Name, Threshold),
    building_daily_energy(Day, Assignments, Building, Used),
    Used =< Threshold.

% ============================================================
%  all_buildings_energy_ok(+Day, +Assignments)
%
%  Checks building_energy_ok for every known building.
% ============================================================
all_buildings_energy_ok(Day, Assignments) :-
    forall(
        building(B, _Name, _Threshold),
        building_energy_ok(Day, Assignments, B)
    ).

% ============================================================
%  total_weekly_energy(+Assignments, -TotalEnergy_kWh)
%
%  Sums assignment_energy over the full assignment list.
% ============================================================
total_weekly_energy(Assignments, Total) :-
    findall(E,
        (   member(A, Assignments),
            assignment_energy(A, E)
        ),
        Energies),
    sum_list(Energies, Total).
