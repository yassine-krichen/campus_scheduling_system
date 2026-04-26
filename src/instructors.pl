% ============================================================
%  instructors.pl
%  Instructor knowledge base — INSAT 2025/2026
%
%  instructor(?InstructorID, ?Department, ?Specialization)
%
%  instructor_available(?InstructorID, ?Day, ?SlotIndex)
%    → true if instructor can teach on that day at that slot.
%    Slot indices 1..5 as defined in time_slots.pl.
%
%  instructor_teaches(?InstructorID, ?CourseID)
%    → defined in courses.pl, cross-referenced here.
%
%  Headcount estimate per department:
%    MPI profs teach large cohorts; ~10 full-time + shared.
%    Engineering depts: ~4–6 profs per dept per year.
%    Language dept: 4 profs, shared across all depts.
%    Cross-teaching: some profs cover multiple paths
%      (e.g., Maths profs cover MPI + eng year 2,
%       English profs cover all departments).
%
%  Availability model:
%    - By default a professor is available Mon–Sat slots 1–5.
%    - Exceptions (research days, admin duties) are listed
%      as explicit unavailability overrides below.
%    - We use a closed-world assumption: if no unavailability
%      fact exists, the professor is considered available.
%
%  instructor_unavailable(?ID, ?Day, ?SlotIndex)  ← exceptions
% ============================================================

:- module(instructors, [instructor/3, instructor_available/3]).

% ============================================================
%  AVAILABILITY HELPER
%  A professor is available on Day at SlotIndex
%  if they are not listed as unavailable.
% ============================================================
instructor_available(ID, Day, SlotIndex) :-
    instructor(ID, _, _),
    day_atom(Day),
    member(SlotIndex, [1,2,3,4,5]),
    \+ instructor_unavailable(ID, Day, SlotIndex).

day_atom(monday).  day_atom(tuesday). day_atom(wednesday).
day_atom(thursday). day_atom(friday). day_atom(saturday).

% ============================================================
%  MATHEMATICS DEPARTMENT
%  Shared: MPI (both years), year-2 engineering all branches
% ============================================================
instructor(prof_math_1,  maths, analysis).
instructor(prof_math_2,  maths, analysis).
instructor(prof_math_3,  maths, algebra).
instructor(prof_math_4,  maths, algebra).
instructor(prof_math_5,  maths, probability_statistics).
instructor(prof_math_6,  maths, probability_statistics).
instructor(prof_math_7,  maths, discrete_maths).
instructor(prof_math_8,  maths, numerical_methods).
instructor(prof_math_9,  maths, logic_and_graphs).
instructor(prof_math_10, maths, analysis).

% Prof math_10 is department head — free Saturday
instructor_unavailable(prof_math_10, saturday, 1).
instructor_unavailable(prof_math_10, saturday, 2).
instructor_unavailable(prof_math_10, saturday, 3).
instructor_unavailable(prof_math_10, saturday, 4).
instructor_unavailable(prof_math_10, saturday, 5).

% ============================================================
%  PHYSICS DEPARTMENT
%  Shared: MPI, IIA, engineering year 2 (CH/BIO/IMI/RT/GL)
% ============================================================
instructor(prof_phys_1, physics, electromagnetism).
instructor(prof_phys_2, physics, electromagnetism).
instructor(prof_phys_3, physics, thermodynamics).
instructor(prof_phys_4, physics, thermodynamics).
instructor(prof_phys_5, physics, optics_waves).
instructor(prof_phys_6, physics, mechanics).
instructor(prof_phys_7, physics, electronics_physics).
instructor(prof_phys_8, physics, electronics_physics).

% Two profs share a Wednesday research seminar (slot 4–5)
instructor_unavailable(prof_phys_1, wednesday, 4).
instructor_unavailable(prof_phys_1, wednesday, 5).
instructor_unavailable(prof_phys_2, wednesday, 4).
instructor_unavailable(prof_phys_2, wednesday, 5).

% ============================================================
%  COMPUTER SCIENCE DEPARTMENT
%  GL, RT, IMI, also MPI year-2 CS intro
% ============================================================
instructor(prof_cs_1,  cs, algorithms_data_structures).
instructor(prof_cs_2,  cs, algorithms_data_structures).
instructor(prof_cs_3,  cs, software_engineering).
instructor(prof_cs_4,  cs, software_engineering).
instructor(prof_cs_5,  cs, databases).
instructor(prof_cs_6,  cs, databases).
instructor(prof_cs_7,  cs, operating_systems).
instructor(prof_cs_8,  cs, networks).
instructor(prof_cs_9,  cs, ai_logic_programming).
instructor(prof_cs_10, cs, web_distributed_systems).
instructor(prof_cs_11, cs, computer_architecture).
instructor(prof_cs_12, cs, security_cryptography).

% prof_cs_9 teaches logical programming (your subject!)
% Available all week; no exceptions.

% prof_cs_12 unavailable Friday afternoon (consulting)
instructor_unavailable(prof_cs_12, friday, 4).
instructor_unavailable(prof_cs_12, friday, 5).

% ============================================================
%  NETWORKS & TELECOM DEPARTMENT
%  RT-specific, some overlap with CS
% ============================================================
instructor(prof_rt_1, rt, signal_processing).
instructor(prof_rt_2, rt, signal_processing).
instructor(prof_rt_3, rt, telecom_protocols).
instructor(prof_rt_4, rt, telecom_protocols).
instructor(prof_rt_5, rt, antenna_propagation).
instructor(prof_rt_6, rt, embedded_systems).

% ============================================================
%  INDUSTRIAL ENGINEERING / AUTOMATION
%  IIA, some GL/RT overlap
% ============================================================
instructor(prof_iia_1, iia, control_systems).
instructor(prof_iia_2, iia, control_systems).
instructor(prof_iia_3, iia, robotics).
instructor(prof_iia_4, iia, industrial_automation).
instructor(prof_iia_5, iia, system_modeling).

% ============================================================
%  CHEMISTRY DEPARTMENT
%  CBA, CH
% ============================================================
instructor(prof_chem_1, chemistry, organic_chemistry).
instructor(prof_chem_2, chemistry, organic_chemistry).
instructor(prof_chem_3, chemistry, physical_chemistry).
instructor(prof_chem_4, chemistry, physical_chemistry).
instructor(prof_chem_5, chemistry, analytical_chemistry).
instructor(prof_chem_6, chemistry, chemical_engineering_proc).

% ============================================================
%  BIOLOGY DEPARTMENT
%  CBA, BIO
% ============================================================
instructor(prof_bio_1, biology, cell_molecular_biology).
instructor(prof_bio_2, biology, cell_molecular_biology).
instructor(prof_bio_3, biology, biochemistry).
instructor(prof_bio_4, biology, biochemistry).
instructor(prof_bio_5, biology, microbiology).
instructor(prof_bio_6, biology, bioprocess_engineering).

% ============================================================
%  ELECTRONICS / INSTRUMENTATION DEPARTMENT
%  IMI, RT (hardware side), also MPI year-2
% ============================================================
instructor(prof_elec_1, electronics, circuit_theory).
instructor(prof_elec_2, electronics, circuit_theory).
instructor(prof_elec_3, electronics, digital_electronics).
instructor(prof_elec_4, electronics, microcontrollers_embedded).
instructor(prof_elec_5, electronics, instrumentation_measurement).

% ============================================================
%  LANGUAGE / HUMANITIES DEPARTMENT
%  Shared across ALL departments and years
%  (English, French, Arabic, Communication skills)
% ============================================================
instructor(prof_lang_1, languages, english).
instructor(prof_lang_2, languages, english).
instructor(prof_lang_3, languages, french_communication).
instructor(prof_lang_4, languages, arabic_humanities).

% Language professors have high load — no Saturday slots
instructor_unavailable(prof_lang_1, saturday, 1).
instructor_unavailable(prof_lang_1, saturday, 2).
instructor_unavailable(prof_lang_1, saturday, 3).
instructor_unavailable(prof_lang_1, saturday, 4).
instructor_unavailable(prof_lang_1, saturday, 5).
instructor_unavailable(prof_lang_2, saturday, 1).
instructor_unavailable(prof_lang_2, saturday, 2).
instructor_unavailable(prof_lang_2, saturday, 3).
instructor_unavailable(prof_lang_2, saturday, 4).
instructor_unavailable(prof_lang_2, saturday, 5).
instructor_unavailable(prof_lang_3, saturday, 1).
instructor_unavailable(prof_lang_3, saturday, 2).
instructor_unavailable(prof_lang_3, saturday, 3).
instructor_unavailable(prof_lang_3, saturday, 4).
instructor_unavailable(prof_lang_3, saturday, 5).
instructor_unavailable(prof_lang_4, saturday, 1).
instructor_unavailable(prof_lang_4, saturday, 2).
instructor_unavailable(prof_lang_4, saturday, 3).
instructor_unavailable(prof_lang_4, saturday, 4).
instructor_unavailable(prof_lang_4, saturday, 5).
