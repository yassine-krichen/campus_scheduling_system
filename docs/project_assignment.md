# Project of Logic Programming

## Intelligent Energy-Aware Campus Resource Scheduling System

**Spring Term 2026**

**Start Date:** February 24, 2026\
**Final Defense:** May 5, 2026\
**Group Size:** 6 Students at most

------------------------------------------------------------------------

## 1. General Vision and Scientific Motivation

The purpose of this project is to design and implement a declarative
decision engine capable of scheduling academic activities in a
multi-building university campus under energy, capacity, temporal, and
fairness constraints. Unlike small-scale exercises that focus on
isolated recursion or simple symbolic inference, this project requires
the construction of a structured reasoning architecture that integrates
knowledge representation, combinatorial search, constraint satisfaction,
optimization, and meta-level evaluation.

Modern university campuses face increasingly complex scheduling
challenges. Classrooms vary in capacity, equipment, and energy
consumption. Laboratories require specific infrastructure. Some
buildings have peak electricity usage limits. Courses have pedagogical
constraints such as required weekly hours, group assignments, and
instructor availability. Additionally, sustainability policies may
impose restrictions on total daily energy consumption or encourage load
balancing across buildings.

The objective of this project is to build a Prolog-based reasoning
system that generates an optimized weekly schedule for a set of courses
while respecting structural, temporal, spatial, and energetic
constraints. The system must not only produce feasible schedules but
must also evaluate and compare alternatives using quantitative criteria.
The intellectual challenge lies in modeling a real institutional
decision problem using purely declarative logic.

------------------------------------------------------------------------

## 2. Formal Problem Description

Consider the following abstract model of the campus scheduling problem.

Let:

-   C = {c1, c2, ..., cn} be the set of courses\
-   R = {r1, r2, ..., rm} be the set of rooms\
-   T = {t1, t2, ..., tk} be the set of time slots\
-   G = {g1, g2, ..., gp} be the set of student groups\
-   B = {b1, b2, ..., bq} be the set of buildings

Each course (ci) is characterized by:

-   A required number of weekly sessions (si)\
-   A duration (di) (in slots)\
-   An assigned student group g(ci)\
-   A required equipment type e(ci)\
-   An instructor availability set Ai ⊆ T

Each room (rj) has:

-   A capacity cap(rj)\
-   An equipment type e(rj)\
-   A building location b(rj)\
-   An hourly energy cost ε(rj)

Each building (bl) has:

-   A daily energy threshold Emax(bl)

A schedule is a mapping assigning each course session to a room and time
slot such that no hard constraints are violated.

The system must ensure:

1.  No room hosts two sessions at the same time.\
2.  No student group attends two sessions at the same time.\
3.  Room capacity satisfies enrollment.\
4.  Equipment requirements are met.\
5.  Instructor availability constraints are respected.\
6.  Building energy usage does not exceed limits.

This formalization transforms the scheduling task into a constrained
combinatorial reasoning problem.

------------------------------------------------------------------------

## 3. Milestone Structure

### Milestone 1: Knowledge Modeling and Constraint Enforcement

The first milestone focuses on constructing a rigorous logical
representation of the campus environment and enforcing hard feasibility
constraints.

Students must design a structured knowledge base representing courses,
rooms, buildings, time slots, equipment types, and instructor
availability. This phase emphasizes relational modeling clarity. The
correctness of the entire system depends on the precision of the
underlying representation.

At this stage, the system must be able to generate candidate assignments
and verify structural feasibility. It must detect violations of:

-   Room-time conflicts\
-   Group-time conflicts\
-   Capacity constraints\
-   Equipment incompatibilities\
-   Instructor unavailability

The central intellectual challenge in this milestone is constraint
placement. Students must determine whether constraints should be checked
before recursive expansion or after partial construction. Poor placement
will lead to combinatorial explosion. Efficient logical pruning must be
achieved through early failure.

Key analytical questions:

-   How does the ordering of constraints affect search complexity?\
-   What is the theoretical branching factor of the search tree?\
-   Under what modeling decisions does the system become incomplete or
    inefficient?

------------------------------------------------------------------------

### Milestone 2: Energy Modeling and Quantitative Reasoning

The system is extended with energy-aware reasoning and numerical
computation.

Each assignment contributes to building-level energy consumption. The
system must dynamically accumulate daily energy usage and prevent
violations of building thresholds.

Students must also compute global metrics such as total weekly campus
energy consumption.

This milestone tests integration of arithmetic accumulation with
recursive logical generation. Students must analyze the impact of energy
constraints on solution feasibility.

------------------------------------------------------------------------

### Milestone 3: Optimization, Fairness, and Multi-Criteria Evaluation

The final milestone transforms the system into a decision-making engine.

The system must evaluate multiple valid schedules using criteria such
as:

-   Minimizing total energy consumption\
-   Minimizing daily load imbalance\
-   Ensuring fairness in room allocation

Students must implement structured comparison logic and justify
optimization strategies.

Key questions:

-   How to compare structured schedules declaratively?\
-   How to avoid combinatorial explosion during optimization?\
-   What trade-offs exist between fairness and efficiency?

------------------------------------------------------------------------

## 4. Integration and System Architecture

The final system must integrate:

-   Knowledge representation\
-   Recursive generation\
-   Constraint enforcement\
-   Numeric accumulation\
-   Optimization comparison

The main predicate orchestrates the full reasoning pipeline. Modular
design is required.

------------------------------------------------------------------------

## 5. Expected Intellectual Depth

Students must:

-   Model a real institutional decision problem\
-   Design a recursive constraint system\
-   Integrate arithmetic with logic\
-   Implement multi-criteria optimization\
-   Control search complexity\
-   Analyze performance theoretically and experimentally

------------------------------------------------------------------------

## 6. Final Defenses

Final Defense: Tuesday May 5th

Submission deadline: Sunday, May 3rd at midnight (strict).

Any two groups submitting substantially similar reports will receive a
score of ZERO.
