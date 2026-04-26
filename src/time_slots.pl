% ============================================================
%  time_slots.pl
%  Temporal knowledge base for INSAT Campus Scheduler
%  Each session = 1h30min. Break: 15min between sessions.
%  Lunch break: 13h00–14h00. Last session ends 17h15.
%
%  day(?Day)
%  time_slot(?SlotID, ?Day, ?StartHour, ?StartMin, ?EndHour, ?EndMin)
%  slot_index(?SlotID, ?Index)   % 1..5, used in conflict checks
% ============================================================

:- module(time_slots, [day/1, time_slot/6, slot_index/2, slot_duration_hours/1]).

% ----- Days -----
day(monday).
day(tuesday).
day(wednesday).
day(thursday).
day(friday).
day(saturday).

% ----- Slot duration (in hours, used for energy computation) -----
slot_duration_hours(1.5).

% ----- Slot definitions -----
% Session layout per day:
%   Slot 1: 08h00 – 09h30
%   Slot 2: 09h45 – 11h15
%   Slot 3: 11h30 – 13h00
%   [LUNCH 13h00 – 14h00]
%   Slot 4: 14h00 – 15h30
%   Slot 5: 15h45 – 17h15
%
% SlotID format: slot(Day, Index)

% Monday
time_slot(slot(monday,1), monday, 8,  0,  9,  30).
time_slot(slot(monday,2), monday, 9,  45, 11, 15).
time_slot(slot(monday,3), monday, 11, 30, 13, 0).
time_slot(slot(monday,4), monday, 14, 0,  15, 30).
time_slot(slot(monday,5), monday, 15, 45, 17, 15).

% Tuesday
time_slot(slot(tuesday,1), tuesday, 8,  0,  9,  30).
time_slot(slot(tuesday,2), tuesday, 9,  45, 11, 15).
time_slot(slot(tuesday,3), tuesday, 11, 30, 13, 0).
time_slot(slot(tuesday,4), tuesday, 14, 0,  15, 30).
time_slot(slot(tuesday,5), tuesday, 15, 45, 17, 15).

% Wednesday
time_slot(slot(wednesday,1), wednesday, 8,  0,  9,  30).
time_slot(slot(wednesday,2), wednesday, 9,  45, 11, 15).
time_slot(slot(wednesday,3), wednesday, 11, 30, 13, 0).
time_slot(slot(wednesday,4), wednesday, 14, 0,  15, 30).
time_slot(slot(wednesday,5), wednesday, 15, 45, 17, 15).

% Thursday
time_slot(slot(thursday,1), thursday, 8,  0,  9,  30).
time_slot(slot(thursday,2), thursday, 9,  45, 11, 15).
time_slot(slot(thursday,3), thursday, 11, 30, 13, 0).
time_slot(slot(thursday,4), thursday, 14, 0,  15, 30).
time_slot(slot(thursday,5), thursday, 15, 45, 17, 15).

% Friday
time_slot(slot(friday,1), friday, 8,  0,  9,  30).
time_slot(slot(friday,2), friday, 9,  45, 11, 15).
time_slot(slot(friday,3), friday, 11, 30, 13, 0).
time_slot(slot(friday,4), friday, 14, 0,  15, 30).
time_slot(slot(friday,5), friday, 15, 45, 17, 15).

% Saturday
time_slot(slot(saturday,1), saturday, 8,  0,  9,  30).
time_slot(slot(saturday,2), saturday, 9,  45, 11, 15).
time_slot(slot(saturday,3), saturday, 11, 30, 13, 0).
time_slot(slot(saturday,4), saturday, 14, 0,  15, 30).
time_slot(slot(saturday,5), saturday, 15, 45, 17, 15).

% ----- Index extractor (for ordering / conflict detection) -----
slot_index(slot(_Day, Index), Index).

% ----- All slots as flat list (useful for generate-and-test) -----
all_slots(Slots) :-
    findall(S, time_slot(S, _, _, _, _, _), Slots).
