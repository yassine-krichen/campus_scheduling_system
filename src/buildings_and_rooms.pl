% ============================================================
%  buildings_and_rooms.pl
%  Spatial knowledge base for INSAT Campus Scheduler
%
%  INSAT physical layout:
%    - T-shaped building, 3 levels (ground + 2 upper floors)
%    - Ground floor (rdc): Amphitheaters (9 total)
%    - Floor 1 (f1):  60 rooms  (lecture rooms + labs)
%    - Floor 2 (f2):  60 rooms  (lecture rooms + labs)
%    - 1 large Auditorium
%
%  building(?BuildingID, ?Name, ?EnergyThreshold_kWh_per_day)
%    STEG institutional thresholds are estimated from the STEG
%    Medium-Voltage (MT) tariff for public institutions (2024):
%      - Peak hours 07h–21h,  rate ≈ 0.142 TND/kWh
%      - Off-peak hours rate ≈ 0.058 TND/kWh
%    A university wing of ~60 rooms drawing ~4–6 kW each averages
%    240–360 kWh/day. We set conservative thresholds per wing below.
%
%  room(?RoomID, ?Building, ?Floor, ?Capacity, ?EquipmentType,
%       ?HourlyEnergyCost_kW)
%
%  Equipment types used:
%    projector_board   – standard lecture room (projector + whiteboard)
%    amphitheater      – large fixed-seat hall, high lighting/HVAC load
%    cs_lab            – computer science lab (30 PCs, wifi, outlets)
%    physics_lab       – oscilloscopes, signal generators, benches
%    chemistry_lab     – fume hoods, chemical benches
%    biology_lab       – microscopes, bio-safety benches
%    electronics_lab   – instrumentation, PCB stations
%    auditorium        – main hall, full AV system, large HVAC
%    language_lab      – booths, headsets, projector
% ============================================================

:- module(buildings_and_rooms, [building/3, room/6, equipment_compatible/2]).

% ============================================================
%  BUILDINGS
%  INSAT is one legal entity but logically we split by wing/zone
%  because energy metering in large MT-connected buildings is
%  done per distribution board (tableau général basse tension).
%
%  Zones:
%    insat_amphi_wing  – ground floor amphitheater zone + auditorium
%    insat_f1_wing     – floor 1, all rooms 101–160
%    insat_f2_wing     – floor 2, all rooms 201–260
% ============================================================

% building(ID, Name, DailyEnergyThreshold_kWh)
%   Amphi wing: 9 amphitheaters × 6 kW × 9h active = ~486 kWh, threshold 500.
%   F1 wing:    60 rooms avg 3 kW × 9h = ~1620 kWh total,
%               but not all rooms run simultaneously; threshold 900.
%   F2 wing:    same as F1, threshold 900.
building(insat_amphi_wing, 'INSAT - Ground Floor Amphi Zone', 500).
building(insat_f1_wing,    'INSAT - Floor 1 Wing',            900).
building(insat_f2_wing,    'INSAT - Floor 2 Wing',            900).

% ============================================================
%  AMPHITHEATERS  (ground floor, capacity 100, high energy)
%  9 amphitheaters: A1 .. A9
%  Hourly energy: 6.0 kW
%    (projector 0.5 + lighting 2.0 + HVAC 3.0 + misc 0.5)
% ============================================================
room(amphi_a1, insat_amphi_wing, rdc, 100, amphitheater, 6.0).
room(amphi_a2, insat_amphi_wing, rdc, 100, amphitheater, 6.0).
room(amphi_a3, insat_amphi_wing, rdc, 100, amphitheater, 6.0).
room(amphi_a4, insat_amphi_wing, rdc, 100, amphitheater, 6.0).
room(amphi_a5, insat_amphi_wing, rdc, 100, amphitheater, 6.0).
room(amphi_a6, insat_amphi_wing, rdc, 100, amphitheater, 6.0).
room(amphi_a7, insat_amphi_wing, rdc, 100, amphitheater, 6.0).
room(amphi_a8, insat_amphi_wing, rdc, 100, amphitheater, 6.0).
room(amphi_a9, insat_amphi_wing, rdc, 100, amphitheater, 6.0).

% ============================================================
%  AUDITORIUM  (ground floor, capacity ~400, very high energy)
% ============================================================
room(auditorium, insat_amphi_wing, rdc, 400, auditorium, 15.0).

% ============================================================
%  FLOOR 1 ROOMS  (rooms 101–160)
%  Layout:
%    101–135: standard lecture rooms (projector_board, cap ~35)
%    136–145: CS labs (cs_lab, cap 30)
%    146–150: Physics labs (physics_lab, cap 30)
%    151–153: Chemistry labs (chemistry_lab, cap 30)
%    154–156: Biology labs (biology_lab, cap 30)
%    157–158: Electronics labs (electronics_lab, cap 30)
%    159–160: Language labs (language_lab, cap 30)
%
%  Energy per room type (kW/hr):
%    Standard lecture: 3.0  (projector 0.3 + lighting 1.2 + HVAC 1.3 + misc 0.2)
%    CS lab:           5.5  (30 PCs × 0.15kW + lighting + HVAC + wifi AP)
%    Physics lab:      4.5  (instruments avg 1.5 + lighting + HVAC)
%    Chemistry lab:    6.5  (fume hoods 3.0 + lighting + HVAC)
%    Biology lab:      4.0  (equipment + lighting + HVAC + bio-safety)
%    Electronics lab:  4.5  (benches + instruments + lighting)
%    Language lab:     3.5  (headsets + projector + lighting + HVAC)
% ============================================================

% Standard lecture rooms 101–135
room(r101, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r102, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r103, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r104, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r105, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r106, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r107, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r108, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r109, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r110, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r111, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r112, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r113, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r114, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r115, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r116, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r117, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r118, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r119, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r120, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r121, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r122, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r123, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r124, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r125, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r126, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r127, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r128, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r129, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r130, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r131, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r132, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r133, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r134, insat_f1_wing, f1, 35, projector_board, 3.0).
room(r135, insat_f1_wing, f1, 35, projector_board, 3.0).

% CS Labs 136–145 (30 seats each)
room(r136, insat_f1_wing, f1, 30, cs_lab, 5.5).
room(r137, insat_f1_wing, f1, 30, cs_lab, 5.5).
room(r138, insat_f1_wing, f1, 30, cs_lab, 5.5).
room(r139, insat_f1_wing, f1, 30, cs_lab, 5.5).
room(r140, insat_f1_wing, f1, 30, cs_lab, 5.5).
room(r141, insat_f1_wing, f1, 30, cs_lab, 5.5).
room(r142, insat_f1_wing, f1, 30, cs_lab, 5.5).
room(r143, insat_f1_wing, f1, 30, cs_lab, 5.5).
room(r144, insat_f1_wing, f1, 30, cs_lab, 5.5).
room(r145, insat_f1_wing, f1, 30, cs_lab, 5.5).

% Physics labs 146–150 (30 seats each)
room(r146, insat_f1_wing, f1, 30, physics_lab, 4.5).
room(r147, insat_f1_wing, f1, 30, physics_lab, 4.5).
room(r148, insat_f1_wing, f1, 30, physics_lab, 4.5).
room(r149, insat_f1_wing, f1, 30, physics_lab, 4.5).
room(r150, insat_f1_wing, f1, 30, physics_lab, 4.5).

% Chemistry labs 151–153
room(r151, insat_f1_wing, f1, 30, chemistry_lab, 6.5).
room(r152, insat_f1_wing, f1, 30, chemistry_lab, 6.5).
room(r153, insat_f1_wing, f1, 30, chemistry_lab, 6.5).

% Biology labs 154–156
room(r154, insat_f1_wing, f1, 30, biology_lab, 4.0).
room(r155, insat_f1_wing, f1, 30, biology_lab, 4.0).
room(r156, insat_f1_wing, f1, 30, biology_lab, 4.0).

% Electronics labs 157–158
room(r157, insat_f1_wing, f1, 30, electronics_lab, 4.5).
room(r158, insat_f1_wing, f1, 30, electronics_lab, 4.5).

% Language labs 159–160
room(r159, insat_f1_wing, f1, 30, language_lab, 3.5).
room(r160, insat_f1_wing, f1, 30, language_lab, 3.5).

% ============================================================
%  FLOOR 2 ROOMS  (rooms 201–260)
%  Same layout mirrored from floor 1:
%    201–235: standard lecture rooms
%    236–245: CS labs
%    246–250: Physics labs
%    251–253: Chemistry labs
%    254–256: Biology labs
%    257–258: Electronics labs
%    259–260: Language labs
% ============================================================

% Standard lecture rooms 201–235
room(r201, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r202, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r203, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r204, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r205, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r206, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r207, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r208, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r209, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r210, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r211, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r212, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r213, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r214, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r215, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r216, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r217, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r218, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r219, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r220, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r221, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r222, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r223, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r224, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r225, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r226, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r227, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r228, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r229, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r230, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r231, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r232, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r233, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r234, insat_f2_wing, f2, 35, projector_board, 3.0).
room(r235, insat_f2_wing, f2, 35, projector_board, 3.0).

% CS Labs 236–245
room(r236, insat_f2_wing, f2, 30, cs_lab, 5.5).
room(r237, insat_f2_wing, f2, 30, cs_lab, 5.5).
room(r238, insat_f2_wing, f2, 30, cs_lab, 5.5).
room(r239, insat_f2_wing, f2, 30, cs_lab, 5.5).
room(r240, insat_f2_wing, f2, 30, cs_lab, 5.5).
room(r241, insat_f2_wing, f2, 30, cs_lab, 5.5).
room(r242, insat_f2_wing, f2, 30, cs_lab, 5.5).
room(r243, insat_f2_wing, f2, 30, cs_lab, 5.5).
room(r244, insat_f2_wing, f2, 30, cs_lab, 5.5).
room(r245, insat_f2_wing, f2, 30, cs_lab, 5.5).

% Physics labs 246–250 (30 seats each)
room(r246, insat_f2_wing, f2, 30, physics_lab, 4.5).
room(r247, insat_f2_wing, f2, 30, physics_lab, 4.5).
room(r248, insat_f2_wing, f2, 30, physics_lab, 4.5).
room(r249, insat_f2_wing, f2, 30, physics_lab, 4.5).
room(r250, insat_f2_wing, f2, 30, physics_lab, 4.5).

% Chemistry labs 251–253
room(r251, insat_f2_wing, f2, 30, chemistry_lab, 6.5).
room(r252, insat_f2_wing, f2, 30, chemistry_lab, 6.5).
room(r253, insat_f2_wing, f2, 30, chemistry_lab, 6.5).

% Biology labs 254–256
room(r254, insat_f2_wing, f2, 30, biology_lab, 4.0).
room(r255, insat_f2_wing, f2, 30, biology_lab, 4.0).
room(r256, insat_f2_wing, f2, 30, biology_lab, 4.0).

% Electronics labs 257–258
room(r257, insat_f2_wing, f2, 30, electronics_lab, 4.5).
room(r258, insat_f2_wing, f2, 30, electronics_lab, 4.5).

% Language labs 259–260
room(r259, insat_f2_wing, f2, 30, language_lab, 3.5).
room(r260, insat_f2_wing, f2, 30, language_lab, 3.5).

% ============================================================
%  Helper: equipment_compatible(?RoomEquip, ?RequiredEquip)
%  A room can host a session if its equipment satisfies the need.
%  amphitheater and auditorium also satisfy projector_board needs.
% ============================================================
equipment_compatible(E, E).
equipment_compatible(amphitheater,  projector_board).
equipment_compatible(auditorium,    projector_board).
equipment_compatible(auditorium,    amphitheater).
