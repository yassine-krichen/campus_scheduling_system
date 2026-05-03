% ============================================================
%  config.pl  [Person 1 — Configuration / Scenario Manager]
%  INSAT Intelligent Campus Scheduling System
%  Logical Programming Project — Spring 2026
%
%  Role: Centralises all runtime-tunable settings so that
%  no core scheduling module needs to be edited when moving
%  between scenarios (demo, gl3_only, full_campus, …).
%
%  Usage:
%    :- use_module(config).
%    ?- setting(scenario, S).          % currently active scenario
%    ?- setting(candidate_limit, N).   % max schedules to explore
%
%  Environment override (optional):
%    Set SCHED_SCENARIO, SCHED_LIMIT, etc. before launching
%    swipl if you want shell-level configuration.  The module
%    attempts to read them via getenv/2 and falls back to the
%    compiled-in defaults below.
% ============================================================

:- module(config, [
    setting/2,
    active_departments/1,
    active_years/1,
    scenario_courses/1,
    scenario_groups/1
]).

:- use_module(library(lists)).
:- use_module(courses).
:- use_module(groups).

% ============================================================
%  COMPILED-IN DEFAULTS
%  Override any of these by exporting the corresponding
%  environment variable before running swipl.
%
%  scenario:
%    demo        – a single subset (GL3) for quick demos
%    gl3_only    – all GL year-3 courses and groups
%    engineering – all engineering years 2–5, all depts
%    full_campus – entire knowledge base (may be slow)
%
%  candidate_limit:
%    Maximum number of valid schedules the generator will
%    collect before stopping.  Use 1 for "first-valid" mode.
%
%  optimization_mode:
%    none        – return first valid schedule found
%    energy      – prefer lower total energy
%    balanced    – prefer lower daily load imbalance
%
%  enable_energy_constraints:
%    true | false  – whether to enforce building thresholds
%    during generation (set false to ignore energy limits)
% ============================================================

%  Read an env variable and convert it to a Prolog atom;
%  succeed with Default if the variable is absent or empty.
env_setting(Var, Default, Value) :-
    (   catch(getenv(Var, Raw), _, fail),
        Raw \= ''
    ->  atom_string(Value, Raw)
    ;   Value = Default
    ).

%  setting(?Key, ?Value)
%  Unified access point for all tunable parameters.
setting(scenario, V) :-
    env_setting('SCHED_SCENARIO', demo, V).

setting(candidate_limit, V) :-
    env_setting('SCHED_LIMIT', '1', Raw),
    (   atom_number(Raw, N) -> V = N ; V = 1 ).

setting(optimization_mode, V) :-
    env_setting('SCHED_OPT', none, V).

setting(enable_energy_constraints, V) :-
    env_setting('SCHED_ENERGY', true, V).

setting(kb_source, V) :-
    env_setting('SCHED_KB', legacy, V).

% ============================================================
%  SCENARIO DEFINITIONS
%  Each scenario specifies which departments and years to
%  include.  The generator queries scenario_courses/1 and
%  scenario_groups/1 to obtain the working sets.
% ============================================================

% active_departments(?Scenario, ?Departments)
scenario_depts(demo,        [gl]).
scenario_depts(gl3_only,    [gl]).
scenario_depts(engineering, [gl, rt, imi, ch, bio]).
scenario_depts(full_campus, [mpi, iia, cba, gl, rt, imi, ch, bio]).

% active_years(?Scenario, ?Years)
%  'prep' is the abstract course year used by MPI/IIA/CBA
%  prep-stream courses. Prep groups are stored more precisely
%  as prep1/prep2, so scenario_groups/1 maps prep -> prep1/prep2.
scenario_years(demo,        [3]).
scenario_years(gl3_only,    [2,3,4,5]).
scenario_years(engineering, [2,3,4,5]).
scenario_years(full_campus, [prep, 2, 3, 4, 5]).

% ---- Public: active_departments/1 ----
active_departments(Depts) :-
    setting(scenario, Sc),
    scenario_depts(Sc, Depts).

% ---- Public: active_years/1 ----
active_years(Years) :-
    setting(scenario, Sc),
    scenario_years(Sc, Years).

% ============================================================
%  scenario_courses(-CourseIDs)
%  Returns the list of course IDs that belong to the active
%  scenario, using the department and year filters.
% ============================================================
scenario_courses(Courses) :-
    setting(kb_source, Source),
    active_departments(Depts),
    active_years(Years),
    findall(CID,
        (   courses:course(CID, _Name, Dept, Year, _Spw, _Type, _Eq, _Prof),
            course_source_selected(Source, CID),
            member(Dept, Depts),
            member(Year, Years)
        ),
        RawCourses),
    list_to_set(RawCourses, Courses).

csv_generated_course(CID) :-
    courses:course(CID, _Name, _Dept, _Year, _Spw, _Type, _Eq, Prof),
    atom(Prof),
    sub_atom(Prof, 0, 9, _, csv_prof_).

course_source_selected(csv, CID) :-
    csv_generated_course(CID).
course_source_selected(legacy, CID) :-
    \+ csv_generated_course(CID).
course_source_selected(both, _CID).

% group_year_selected(+GroupYear, +ScenarioYears)
%   Bridges the data model vocabulary: prep-stream courses use
%   'prep', while prep-stream groups use concrete years prep1/prep2.
group_year_selected(prep1, Years) :-
    member(prep, Years), !.
group_year_selected(prep2, Years) :-
    member(prep, Years), !.
group_year_selected(Year, Years) :-
    member(Year, Years).

% ============================================================
%  scenario_groups(-GroupIDs)
%  Returns the group IDs that belong to the active scenario.
% ============================================================
scenario_groups(Groups) :-
    active_departments(Depts),
    active_years(Years),
    findall(GID,
        (   groups:group(GID, Dept, Year, _Enroll),
            member(Dept, Depts),
            group_year_selected(Year, Years)
        ),
        RawGroups),
    list_to_set(RawGroups, Groups).
