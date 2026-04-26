% ============================================================
%  groups.pl
%  Student groups knowledge base — INSAT 2025/2026
%
%  group(?GroupID, ?Department, ?Year, ?Enrollment)
%
%  Departments & years at INSAT:
%    MPI  – Mathématiques & Physique & Informatique (prep years 1–2)
%           → 24 classes, avg 30 students each
%    IIA  – Ingénierie Informatique et Automatique (GL equiv stream, years 1–3)
%           renamed here as per INSAT: IAA → we keep user notation IIA
%           → 7 classes, avg 30 students
%    CBA  – Chimie Biologie et Agronomie (prep stream)
%           → 8 classes, avg 30 students
%    GL   – Génie Logiciel (Software Engineering), years 2–5
%           → 2 classes per year
%    RT   – Réseaux et Télécommunications, years 2–5
%           → 2 classes per year
%    IMI  – Ingénierie en Mathématiques et Informatique, years 2–5
%           → 2 classes per year
%    CH   – Génie Chimique, years 2–5
%           → 2 classes per year
%    BIO  – Génie Biologique, years 2–5
%           → 2 classes per year
%
%  Enrollment note:
%    Prep (MPI/IIA/CBA): ~30 per class
%    Engineering years 2–3: ~30 per class
%    Engineering years 4–5: ~25 per class (some attrition)
% ============================================================

:- module(groups, [group/4, group_size/2]).

% ============================================================
%  MPI — 24 classes (prep, mixed physics/maths/CS)
% ============================================================
group(mpi_1,  mpi, prep1, 30). group(mpi_2,  mpi, prep1, 30).
group(mpi_3,  mpi, prep1, 30). group(mpi_4,  mpi, prep1, 30).
group(mpi_5,  mpi, prep1, 30). group(mpi_6,  mpi, prep1, 30).
group(mpi_7,  mpi, prep1, 30). group(mpi_8,  mpi, prep1, 30).
group(mpi_9,  mpi, prep1, 30). group(mpi_10, mpi, prep1, 30).
group(mpi_11, mpi, prep1, 30). group(mpi_12, mpi, prep1, 30).
group(mpi_13, mpi, prep2, 30). group(mpi_14, mpi, prep2, 30).
group(mpi_15, mpi, prep2, 30). group(mpi_16, mpi, prep2, 30).
group(mpi_17, mpi, prep2, 30). group(mpi_18, mpi, prep2, 30).
group(mpi_19, mpi, prep2, 30). group(mpi_20, mpi, prep2, 30).
group(mpi_21, mpi, prep2, 30). group(mpi_22, mpi, prep2, 30).
group(mpi_23, mpi, prep2, 30). group(mpi_24, mpi, prep2, 30).

% ============================================================
%  IIA — 7 classes (prep stream, informatique & automatique)
% ============================================================
group(iia_1, iia, prep1, 30). group(iia_2, iia, prep1, 30).
group(iia_3, iia, prep1, 30). group(iia_4, iia, prep1, 30).
group(iia_5, iia, prep2, 30). group(iia_6, iia, prep2, 30).
group(iia_7, iia, prep2, 30).

% ============================================================
%  CBA — 8 classes (prep stream, chimie/bio/agro)
% ============================================================
group(cba_1, cba, prep1, 30). group(cba_2, cba, prep1, 30).
group(cba_3, cba, prep1, 30). group(cba_4, cba, prep1, 30).
group(cba_5, cba, prep2, 30). group(cba_6, cba, prep2, 30).
group(cba_7, cba, prep2, 30). group(cba_8, cba, prep2, 30).

% ============================================================
%  GL — Génie Logiciel (Software Engineering), years 2–5
% ============================================================
group(gl2_a, gl, 2, 30). group(gl2_b, gl, 2, 30).
group(gl3_a, gl, 3, 30). group(gl3_b, gl, 3, 30).
group(gl4_a, gl, 4, 25). group(gl4_b, gl, 4, 25).
group(gl5_a, gl, 5, 25). group(gl5_b, gl, 5, 25).

% ============================================================
%  RT — Réseaux & Télécommunications, years 2–5
% ============================================================
group(rt2_a, rt, 2, 30). group(rt2_b, rt, 2, 30).
group(rt3_a, rt, 3, 30). group(rt3_b, rt, 3, 30).
group(rt4_a, rt, 4, 25). group(rt4_b, rt, 4, 25).
group(rt5_a, rt, 5, 25). group(rt5_b, rt, 5, 25).

% ============================================================
%  IMI — Ingénierie Mathématiques & Informatique, years 2–5
% ============================================================
group(imi2_a, imi, 2, 30). group(imi2_b, imi, 2, 30).
group(imi3_a, imi, 3, 30). group(imi3_b, imi, 3, 30).
group(imi4_a, imi, 4, 25). group(imi4_b, imi, 4, 25).
group(imi5_a, imi, 5, 25). group(imi5_b, imi, 5, 25).

% ============================================================
%  CH — Génie Chimique, years 2–5
% ============================================================
group(ch2_a, ch, 2, 30). group(ch2_b, ch, 2, 30).
group(ch3_a, ch, 3, 30). group(ch3_b, ch, 3, 30).
group(ch4_a, ch, 4, 25). group(ch4_b, ch, 4, 25).
group(ch5_a, ch, 5, 25). group(ch5_b, ch, 5, 25).

% ============================================================
%  BIO — Génie Biologique, years 2–5
% ============================================================
group(bio2_a, bio, 2, 30). group(bio2_b, bio, 2, 30).
group(bio3_a, bio, 3, 30). group(bio3_b, bio, 3, 30).
group(bio4_a, bio, 4, 25). group(bio4_b, bio, 4, 25).
group(bio5_a, bio, 5, 25). group(bio5_b, bio, 5, 25).

% ============================================================
%  Derived: group_size/2
% ============================================================
group_size(G, S) :- group(G, _, _, S).
