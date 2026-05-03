% ============================================================
%  courses.pl
%  Course knowledge base — INSAT 2025/2026
%
%  course(?CourseID, ?Name, ?Department, ?Year,
%         ?SessionsPerWeek, ?SessionType,
%         ?RequiredEquipment, ?InstructorID)
%
%  SessionType:   lecture | td | tp
%  RequiredEquipment matches equipment types in buildings_and_rooms.pl:
%    projector_board | amphitheater | cs_lab |
%    physics_lab | chemistry_lab | biology_lab |
%    electronics_lab | language_lab
%
%  Enrollment is derived from the group assigned to the course.
%  Each course entry corresponds to a single CLASS (section).
%  A real schedule assigns one course-session to one group.
%
%  course_session(?CourseID, ?GroupID)
%    → which groups attend this course
%
%  Sessions per week guidelines used:
%    Prep (MPI/IIA/CBA): 10–12 unique course types, each
%      with 2 lec + 1 TD + 1 TP = 4 sessions/week per course.
%    Engineering year 2: 6–8 courses, 1–2 lec + 1 TD possibly 1 TP.
%    Engineering year 3+: 5–6 courses, fewer sessions.
%
%  We model a representative week for the FULL campus.
%  Courses are named with ID pattern:
%    <dept>_<year>_<subject_abbrev>_<type>
%    e.g.  gl3_lp_lec  = GL year3 Logic Programming lecture
% ============================================================

:- module(courses, [course/8, course_session/2]).

% ============================================================
% ============================================================
%  SECTION A: ALL course/8 FACTS
%  All course definitions, organized by department & year
% ============================================================

% --- MPI — PREP YEAR 1 & 2 ---
course(mpi_analysis_lec,   'Analyse Mathématique - Cours',   mpi, prep, 2, lecture, amphitheater,    prof_math_1).
course(mpi_analysis_td,    'Analyse Mathématique - TD',      mpi, prep, 2, td,      projector_board,  prof_math_2).
course(mpi_algebra_lec,    'Algèbre - Cours',                mpi, prep, 2, lecture, amphitheater,    prof_math_3).
course(mpi_algebra_td,     'Algèbre - TD',                   mpi, prep, 2, td,      projector_board,  prof_math_4).
course(mpi_mech_lec,       'Mécanique - Cours',              mpi, prep, 2, lecture, amphitheater,    prof_phys_6).
course(mpi_mech_td,        'Mécanique - TD',                 mpi, prep, 2, td,      projector_board,  prof_phys_6).
course(mpi_mech_tp,        'Mécanique - TP',                 mpi, prep, 1, tp,      physics_lab,      prof_phys_6).
course(mpi_thermo_lec,     'Thermodynamique - Cours',        mpi, prep, 2, lecture, amphitheater,    prof_phys_3).
course(mpi_thermo_td,      'Thermodynamique - TD',           mpi, prep, 2, td,      projector_board,  prof_phys_4).
course(mpi_thermo_tp,      'Thermodynamique - TP',           mpi, prep, 1, tp,      physics_lab,      prof_phys_4).
course(mpi_cs_lec,         'Informatique - Cours',           mpi, prep, 2, lecture, amphitheater,    prof_cs_1).
course(mpi_cs_td,          'Informatique - TD',              mpi, prep, 2, td,      projector_board,  prof_cs_2).
course(mpi_cs_tp,          'Informatique - TP',              mpi, prep, 1, tp,      cs_lab,           prof_cs_2).
course(mpi_chem_lec,       'Chimie Générale - Cours',        mpi, prep, 1, lecture, amphitheater,    prof_chem_3).
course(mpi_chem_tp,        'Chimie Générale - TP',           mpi, prep, 1, tp,      chemistry_lab,    prof_chem_4).
course(mpi_eng_lec,        'Anglais - Cours',                mpi, prep, 2, lecture, projector_board,  prof_lang_1).
course(mpi_fr_lec,         'Français Communication - Cours', mpi, prep, 1, lecture, projector_board,  prof_lang_3).

% --- IIA — PREP STREAM ---
course(iia_algo_lec,  'Algorithmique - Cours',     iia, prep, 2, lecture, amphitheater,   prof_cs_1).
course(iia_algo_td,   'Algorithmique - TD',         iia, prep, 2, td,      projector_board, prof_cs_2).
course(iia_algo_tp,   'Algorithmique - TP',         iia, prep, 1, tp,      cs_lab,          prof_cs_2).
course(iia_math_lec,  'Mathématiques - Cours',      iia, prep, 2, lecture, amphitheater,   prof_math_5).
course(iia_math_td,   'Mathématiques - TD',         iia, prep, 2, td,      projector_board, prof_math_6).
course(iia_phys_lec,  'Physique - Cours',           iia, prep, 2, lecture, amphitheater,   prof_phys_7).
course(iia_phys_tp,   'Physique - TP',              iia, prep, 1, tp,      physics_lab,     prof_phys_8).
course(iia_elec_lec,  'Electronique - Cours',       iia, prep, 2, lecture, amphitheater,   prof_elec_1).
course(iia_elec_td,   'Electronique - TD',          iia, prep, 2, td,      projector_board, prof_elec_2).
course(iia_elec_tp,   'Electronique - TP',          iia, prep, 1, tp,      electronics_lab, prof_elec_2).
course(iia_ctrl_lec,  'Systèmes Asservis - Cours',  iia, prep, 1, lecture, projector_board, prof_iia_1).
course(iia_ctrl_td,   'Systèmes Asservis - TD',     iia, prep, 1, td,      projector_board, prof_iia_2).
course(iia_eng_lec,   'Anglais - Cours',            iia, prep, 1, lecture, projector_board, prof_lang_1).

% --- CBA — PREP STREAM (chimie/bio/agro) ---
course(cba_chem_lec,  'Chimie Organique - Cours',     cba, prep, 2, lecture, amphitheater,   prof_chem_1).
course(cba_chem_td,   'Chimie Organique - TD',         cba, prep, 2, td,      projector_board, prof_chem_2).
course(cba_chem_tp,   'Chimie Organique - TP',         cba, prep, 1, tp,      chemistry_lab,   prof_chem_2).
course(cba_phys_lec,  'Physique - Cours',              cba, prep, 2, lecture, amphitheater,   prof_phys_5).
course(cba_phys_td,   'Physique - TD',                 cba, prep, 2, td,      projector_board, prof_phys_5).
course(cba_bio_lec,   'Biologie Cellulaire - Cours',   cba, prep, 2, lecture, amphitheater,   prof_bio_1).
course(cba_bio_td,    'Biologie Cellulaire - TD',      cba, prep, 2, td,      projector_board, prof_bio_2).
course(cba_bio_tp,    'Biologie Cellulaire - TP',      cba, prep, 1, tp,      biology_lab,     prof_bio_2).
course(cba_math_lec,  'Mathématiques - Cours',         cba, prep, 2, lecture, amphitheater,   prof_math_7).
course(cba_math_td,   'Mathématiques - TD',            cba, prep, 2, td,      projector_board, prof_math_8).
course(cba_eng_lec,   'Anglais - Cours',               cba, prep, 1, lecture, projector_board, prof_lang_2).

% --- GL YEAR 2 — SOFTWARE ENGINEERING ---
course(gl2_oop_lec,    'POO - Cours',                  gl, 2, 2, lecture, projector_board, prof_cs_3).
course(gl2_oop_td,     'POO - TD',                     gl, 2, 1, td,      projector_board, prof_cs_4).
course(gl2_oop_tp,     'POO - TP',                     gl, 2, 1, tp,      cs_lab,          prof_cs_4).
course(gl2_algo_lec,   'Algorithmique - Cours',         gl, 2, 2, lecture, projector_board, prof_cs_1).
course(gl2_algo_td,    'Algorithmique - TD',            gl, 2, 1, td,      projector_board, prof_cs_2).
course(gl2_algo_tp,    'Algorithmique - TP',            gl, 2, 1, tp,      cs_lab,          prof_cs_2).
course(gl2_db_lec,     'Bases de Données - Cours',      gl, 2, 2, lecture, projector_board, prof_cs_5).
course(gl2_db_td,      'Bases de Données - TD',         gl, 2, 1, td,      projector_board, prof_cs_6).
course(gl2_db_tp,      'Bases de Données - TP',         gl, 2, 1, tp,      cs_lab,          prof_cs_6).
course(gl2_math_lec,   'Probabilités & Stats - Cours',  gl, 2, 1, lecture, projector_board, prof_math_5).
course(gl2_math_td,    'Probabilités & Stats - TD',     gl, 2, 1, td,      projector_board, prof_math_6).
course(gl2_os_lec,     'Systèmes Exploitation - Cours', gl, 2, 2, lecture, projector_board, prof_cs_7).
course(gl2_os_tp,      'Systèmes Exploitation - TP',    gl, 2, 1, tp,      cs_lab,          prof_cs_7).
course(gl2_arch_lec,   'Architecture Ordinateurs',      gl, 2, 1, lecture, projector_board, prof_cs_11).
course(gl2_eng_lec,    'Anglais Technique',             gl, 2, 1, lecture, projector_board, prof_lang_1).

% --- GL YEAR 3 --- 
course(gl3_lp_lec,     'Programmation Logique - Cours',  gl, 3, 2, lecture, projector_board, prof_cs_9).
course(gl3_lp_td,      'Programmation Logique - TD',     gl, 3, 1, td,      projector_board, prof_cs_9).
course(gl3_lp_tp,      'Programmation Logique - TP',     gl, 3, 1, tp,      cs_lab,          prof_cs_9).
course(gl3_net_lec,    'Réseaux - Cours',                gl, 3, 2, lecture, projector_board, prof_cs_8).
course(gl3_net_td,     'Réseaux - TD',                   gl, 3, 1, td,      projector_board, prof_cs_8).
course(gl3_web_lec,    'Dev Web & Distribué - Cours',    gl, 3, 2, lecture, projector_board, prof_cs_10).
course(gl3_web_tp,     'Dev Web & Distribué - TP',       gl, 3, 1, tp,      cs_lab,          prof_cs_10).
course(gl3_gl_lec,     'Génie Logiciel - Cours',         gl, 3, 2, lecture, projector_board, prof_cs_3).
course(gl3_gl_td,      'Génie Logiciel - TD',            gl, 3, 1, td,      projector_board, prof_cs_4).
course(gl3_ai_lec,     'Intelligence Artificielle - Cours', gl, 3, 1, lecture, projector_board, prof_cs_9).
course(gl3_sec_lec,    'Sécurité Informatique - Cours',  gl, 3, 1, lecture, projector_board, prof_cs_12).
course(gl3_eng_lec,    'Anglais Professionnel',          gl, 3, 1, lecture, projector_board, prof_lang_2).

% --- GL YEAR 4 ---
course(gl4_proj_mgmt_lec, 'Gestion de Projets - Cours',  gl, 4, 1, lecture, projector_board, prof_cs_3).
course(gl4_cloud_lec,     'Cloud & DevOps - Cours',      gl, 4, 2, lecture, projector_board, prof_cs_10).
course(gl4_cloud_tp,      'Cloud & DevOps - TP',         gl, 4, 1, tp,      cs_lab,          prof_cs_10).
course(gl4_sec_lec,       'Sécurité Avancée - Cours',    gl, 4, 1, lecture, projector_board, prof_cs_12).
course(gl4_sec_tp,        'Sécurité Avancée - TP',       gl, 4, 1, tp,      cs_lab,          prof_cs_12).
course(gl4_eng_lec,       'Anglais Business',            gl, 4, 1, lecture, projector_board, prof_lang_1).

% --- GL YEAR 5 ---
course(gl5_arch_lec,  'Architecture Logicielle - Cours', gl, 5, 1, lecture, projector_board, prof_cs_4).
course(gl5_pfe_suivi, 'Suivi PFE',                       gl, 5, 1, lecture, projector_board, prof_cs_3).
course(gl5_mgmt_lec,  'Entrepreneuriat',                 gl, 5, 1, lecture, projector_board, prof_lang_3).

% --- RT YEAR 2 — NETWORKS & TELECOM ---
course(rt2_math_lec,  'Mathématiques RT - Cours',        rt, 2, 2, lecture, projector_board, prof_math_9).
course(rt2_math_td,   'Mathématiques RT - TD',           rt, 2, 1, td,      projector_board, prof_math_9).
course(rt2_sig_lec,   'Traitement du Signal - Cours',    rt, 2, 2, lecture, projector_board, prof_rt_1).
course(rt2_sig_td,    'Traitement du Signal - TD',       rt, 2, 1, td,      projector_board, prof_rt_2).
course(rt2_sig_tp,    'Traitement du Signal - TP',       rt, 2, 1, tp,      electronics_lab, prof_rt_2).
course(rt2_elec_lec,  'Electronique Analogique - Cours', rt, 2, 2, lecture, projector_board, prof_elec_3).
course(rt2_elec_tp,   'Electronique Analogique - TP',    rt, 2, 1, tp,      electronics_lab, prof_elec_4).
course(rt2_eng_lec,   'Anglais Technique',               rt, 2, 1, lecture, projector_board, prof_lang_1).

% --- RT YEAR 3 ---
course(rt3_proto_lec,  'Protocoles Réseau - Cours',      rt, 3, 2, lecture, projector_board, prof_rt_3).
course(rt3_proto_td,   'Protocoles Réseau - TD',         rt, 3, 1, td,      projector_board, prof_rt_4).
course(rt3_proto_tp,   'Protocoles Réseau - TP',         rt, 3, 1, tp,      cs_lab,          prof_rt_4).
course(rt3_ant_lec,    'Antennes & Propagation - Cours', rt, 3, 2, lecture, projector_board, prof_rt_5).
course(rt3_emb_lec,    'Systèmes Embarqués - Cours',     rt, 3, 1, lecture, projector_board, prof_rt_6).
course(rt3_emb_tp,     'Systèmes Embarqués - TP',        rt, 3, 1, tp,      electronics_lab, prof_rt_6).
course(rt3_eng_lec,    'Anglais',                        rt, 3, 1, lecture, projector_board, prof_lang_2).

% --- RT YEAR 4 ---
course(rt4_5g_lec,   '5G & Mobile Networks - Cours',    rt, 4, 2, lecture, projector_board, prof_rt_3).
course(rt4_5g_tp,    '5G & Mobile Networks - TP',       rt, 4, 1, tp,      cs_lab,          prof_rt_3).
course(rt4_sec_lec,  'Sécurité Réseau - Cours',         rt, 4, 1, lecture, projector_board, prof_cs_12).

% --- RT YEAR 5 ---
course(rt5_arch_lec,  'Architecture Télécoms Avancée',  rt, 5, 1, lecture, projector_board, prof_rt_5).
course(rt5_pfe_suivi, 'Suivi PFE',                      rt, 5, 1, lecture, projector_board, prof_rt_4).

% --- IMI YEAR 2 — INGÉNIERIE MATHÉMATIQUES & INFORMATIQUE ---
course(imi2_math_lec,  'Analyse Numérique - Cours',     imi, 2, 2, lecture, projector_board, prof_math_8).
course(imi2_math_td,   'Analyse Numérique - TD',        imi, 2, 2, td,      projector_board, prof_math_8).
course(imi2_algo_lec,  'Algorithmique - Cours',         imi, 2, 2, lecture, projector_board, prof_cs_1).
course(imi2_algo_tp,   'Algorithmique - TP',            imi, 2, 1, tp,      cs_lab,          prof_cs_2).
course(imi2_elec_lec,  'Electronique - Cours',          imi, 2, 2, lecture, projector_board, prof_elec_1).
course(imi2_elec_tp,   'Electronique - TP',             imi, 2, 1, tp,      electronics_lab, prof_elec_2).
course(imi2_eng_lec,   'Anglais',                       imi, 2, 1, lecture, projector_board, prof_lang_1).

% --- IMI YEAR 3 ---
course(imi3_optim_lec,  'Optimisation - Cours',          imi, 3, 2, lecture, projector_board, prof_math_9).
course(imi3_optim_td,   'Optimisation - TD',             imi, 3, 1, td,      projector_board, prof_math_9).
course(imi3_ml_lec,     'Machine Learning - Cours',      imi, 3, 2, lecture, projector_board, prof_cs_9).
course(imi3_ml_tp,      'Machine Learning - TP',         imi, 3, 1, tp,      cs_lab,          prof_cs_9).
course(imi3_sys_lec,    'Systèmes Embarqués - Cours',    imi, 3, 1, lecture, projector_board, prof_rt_6).
course(imi3_eng_lec,    'Anglais',                       imi, 3, 1, lecture, projector_board, prof_lang_2).

% --- IMI YEAR 4 ---
course(imi4_bigdata_lec, 'Big Data - Cours',             imi, 4, 2, lecture, projector_board, prof_cs_5).
course(imi4_bigdata_tp,  'Big Data - TP',                imi, 4, 1, tp,      cs_lab,          prof_cs_6).
course(imi4_cv_lec,      'Vision Artificielle - Cours',  imi, 4, 1, lecture, projector_board, prof_cs_9).

% --- IMI YEAR 5 ---
course(imi5_pfe_suivi, 'Suivi PFE',                      imi, 5, 1, lecture, projector_board, prof_cs_9).

% --- CH YEAR 2 — GÉNIE CHIMIQUE ---
course(ch2_chem_lec,  'Chimie Physique - Cours',          ch, 2, 2, lecture, projector_board, prof_chem_3).
course(ch2_chem_td,   'Chimie Physique - TD',             ch, 2, 2, td,      projector_board, prof_chem_4).
course(ch2_chem_tp,   'Chimie Physique - TP',             ch, 2, 1, tp,      chemistry_lab,   prof_chem_4).
course(ch2_math_lec,  'Mathématiques CH - Cours',         ch, 2, 2, lecture, projector_board, prof_math_7).
course(ch2_math_td,   'Mathématiques CH - TD',            ch, 2, 1, td,      projector_board, prof_math_8).
course(ch2_phys_lec,  'Physique - Cours',                 ch, 2, 1, lecture, projector_board, prof_phys_3).
course(ch2_eng_lec,   'Anglais',                          ch, 2, 1, lecture, projector_board, prof_lang_2).

% --- CH YEAR 3 ---
course(ch3_proc_lec,  'Génie des Procédés - Cours',       ch, 3, 2, lecture, projector_board, prof_chem_6).
course(ch3_proc_td,   'Génie des Procédés - TD',          ch, 3, 1, td,      projector_board, prof_chem_6).
course(ch3_proc_tp,   'Génie des Procédés - TP',          ch, 3, 1, tp,      chemistry_lab,   prof_chem_5).
course(ch3_anal_lec,  'Chimie Analytique - Cours',        ch, 3, 2, lecture, projector_board, prof_chem_5).
course(ch3_eng_lec,   'Anglais',                          ch, 3, 1, lecture, projector_board, prof_lang_1).

% --- CH YEAR 4 ---
course(ch4_env_lec,    'Environnement & Développement Durable', ch, 4, 1, lecture, projector_board, prof_chem_3).
course(ch4_sim_lec,    'Simulation des Procédés - Cours',       ch, 4, 2, lecture, projector_board, prof_chem_6).
course(ch4_sim_tp,     'Simulation des Procédés - TP',          ch, 4, 1, tp,      cs_lab,          prof_chem_6).

% --- CH YEAR 5 ---
course(ch5_pfe_suivi,  'Suivi PFE',                             ch, 5, 1, lecture, projector_board, prof_chem_6).

% --- BIO YEAR 2 — GÉNIE BIOLOGIQUE ---
course(bio2_bio_lec,   'Biochimie - Cours',               bio, 2, 2, lecture, projector_board, prof_bio_3).
course(bio2_bio_td,    'Biochimie - TD',                  bio, 2, 2, td,      projector_board, prof_bio_4).
course(bio2_bio_tp,    'Biochimie - TP',                  bio, 2, 1, tp,      biology_lab,     prof_bio_4).
course(bio2_cell_lec,  'Biologie Cellulaire - Cours',     bio, 2, 2, lecture, projector_board, prof_bio_1).
course(bio2_cell_tp,   'Biologie Cellulaire - TP',        bio, 2, 1, tp,      biology_lab,     prof_bio_2).
course(bio2_math_lec,  'Mathématiques BIO - Cours',       bio, 2, 1, lecture, projector_board, prof_math_7).
course(bio2_eng_lec,   'Anglais',                         bio, 2, 1, lecture, projector_board, prof_lang_2).

% --- BIO YEAR 3 ---
course(bio3_micro_lec, 'Microbiologie - Cours',           bio, 3, 2, lecture, projector_board, prof_bio_5).
course(bio3_micro_tp,  'Microbiologie - TP',              bio, 3, 1, tp,      biology_lab,     prof_bio_5).
course(bio3_biopro_lec,'Bioprocédés - Cours',             bio, 3, 2, lecture, projector_board, prof_bio_6).
course(bio3_biopro_td, 'Bioprocédés - TD',                bio, 3, 1, td,      projector_board, prof_bio_6).
course(bio3_eng_lec,   'Anglais',                         bio, 3, 1, lecture, projector_board, prof_lang_1).

% --- BIO YEAR 4 ---
course(bio4_bioinfo_lec,'Bioinformatique - Cours',        bio, 4, 2, lecture, projector_board, prof_cs_9).
course(bio4_bioinfo_tp, 'Bioinformatique - TP',           bio, 4, 1, tp,      cs_lab,          prof_cs_9).
course(bio4_env_lec,    'Environnement & Biotechnologie', bio, 4, 1, lecture, projector_board, prof_bio_6).

% --- BIO YEAR 5 ---
course(bio5_pfe_suivi, 'Suivi PFE',                      bio, 5, 1, lecture, projector_board, prof_bio_6).

% ============================================================
% ============================================================
%  SECTION B: ALL course_session/2 FACTS
%  All course-group mappings, organized by department & year
% ============================================================

% --- MPI SESSIONS ---
course_session(mpi_analysis_lec, mpi_1).  course_session(mpi_analysis_lec, mpi_2).
course_session(mpi_analysis_lec, mpi_3).  course_session(mpi_analysis_lec, mpi_4).
course_session(mpi_analysis_lec, mpi_5).  course_session(mpi_analysis_lec, mpi_6).
course_session(mpi_analysis_lec, mpi_7).  course_session(mpi_analysis_lec, mpi_8).
course_session(mpi_analysis_lec, mpi_9).  course_session(mpi_analysis_lec, mpi_10).
course_session(mpi_analysis_lec, mpi_11). course_session(mpi_analysis_lec, mpi_12).
course_session(mpi_analysis_lec, mpi_13). course_session(mpi_analysis_lec, mpi_14).
course_session(mpi_analysis_lec, mpi_15). course_session(mpi_analysis_lec, mpi_16).
course_session(mpi_analysis_lec, mpi_17). course_session(mpi_analysis_lec, mpi_18).
course_session(mpi_analysis_lec, mpi_19). course_session(mpi_analysis_lec, mpi_20).
course_session(mpi_analysis_lec, mpi_21). course_session(mpi_analysis_lec, mpi_22).
course_session(mpi_analysis_lec, mpi_23). course_session(mpi_analysis_lec, mpi_24).

course_session(mpi_analysis_td, mpi_1).  course_session(mpi_analysis_td, mpi_2).
course_session(mpi_analysis_td, mpi_3).  course_session(mpi_analysis_td, mpi_4).
course_session(mpi_analysis_td, mpi_5).  course_session(mpi_analysis_td, mpi_6).
course_session(mpi_analysis_td, mpi_7).  course_session(mpi_analysis_td, mpi_8).
course_session(mpi_analysis_td, mpi_9).  course_session(mpi_analysis_td, mpi_10).
course_session(mpi_analysis_td, mpi_11). course_session(mpi_analysis_td, mpi_12).
course_session(mpi_analysis_td, mpi_13). course_session(mpi_analysis_td, mpi_14).
course_session(mpi_analysis_td, mpi_15). course_session(mpi_analysis_td, mpi_16).
course_session(mpi_analysis_td, mpi_17). course_session(mpi_analysis_td, mpi_18).
course_session(mpi_analysis_td, mpi_19). course_session(mpi_analysis_td, mpi_20).
course_session(mpi_analysis_td, mpi_21). course_session(mpi_analysis_td, mpi_22).
course_session(mpi_analysis_td, mpi_23). course_session(mpi_analysis_td, mpi_24).

course_session(mpi_algebra_lec, mpi_1).  course_session(mpi_algebra_lec, mpi_2).
course_session(mpi_algebra_lec, mpi_3).  course_session(mpi_algebra_lec, mpi_4).
course_session(mpi_algebra_lec, mpi_5).  course_session(mpi_algebra_lec, mpi_6).
course_session(mpi_algebra_lec, mpi_7).  course_session(mpi_algebra_lec, mpi_8).
course_session(mpi_algebra_lec, mpi_9).  course_session(mpi_algebra_lec, mpi_10).
course_session(mpi_algebra_lec, mpi_11). course_session(mpi_algebra_lec, mpi_12).
course_session(mpi_algebra_lec, mpi_13). course_session(mpi_algebra_lec, mpi_14).
course_session(mpi_algebra_lec, mpi_15). course_session(mpi_algebra_lec, mpi_16).
course_session(mpi_algebra_lec, mpi_17). course_session(mpi_algebra_lec, mpi_18).
course_session(mpi_algebra_lec, mpi_19). course_session(mpi_algebra_lec, mpi_20).
course_session(mpi_algebra_lec, mpi_21). course_session(mpi_algebra_lec, mpi_22).
course_session(mpi_algebra_lec, mpi_23). course_session(mpi_algebra_lec, mpi_24).

course_session(mpi_algebra_td, mpi_1).  course_session(mpi_algebra_td, mpi_2).
course_session(mpi_algebra_td, mpi_3).  course_session(mpi_algebra_td, mpi_4).
course_session(mpi_algebra_td, mpi_5).  course_session(mpi_algebra_td, mpi_6).
course_session(mpi_algebra_td, mpi_7).  course_session(mpi_algebra_td, mpi_8).
course_session(mpi_algebra_td, mpi_9).  course_session(mpi_algebra_td, mpi_10).
course_session(mpi_algebra_td, mpi_11). course_session(mpi_algebra_td, mpi_12).
course_session(mpi_algebra_td, mpi_13). course_session(mpi_algebra_td, mpi_14).
course_session(mpi_algebra_td, mpi_15). course_session(mpi_algebra_td, mpi_16).
course_session(mpi_algebra_td, mpi_17). course_session(mpi_algebra_td, mpi_18).
course_session(mpi_algebra_td, mpi_19). course_session(mpi_algebra_td, mpi_20).
course_session(mpi_algebra_td, mpi_21). course_session(mpi_algebra_td, mpi_22).
course_session(mpi_algebra_td, mpi_23). course_session(mpi_algebra_td, mpi_24).

course_session(mpi_cs_lec, mpi_1).  course_session(mpi_cs_lec, mpi_2).
course_session(mpi_cs_lec, mpi_3).  course_session(mpi_cs_lec, mpi_4).
course_session(mpi_cs_lec, mpi_5).  course_session(mpi_cs_lec, mpi_6).
course_session(mpi_cs_lec, mpi_7).  course_session(mpi_cs_lec, mpi_8).
course_session(mpi_cs_lec, mpi_9).  course_session(mpi_cs_lec, mpi_10).
course_session(mpi_cs_lec, mpi_11). course_session(mpi_cs_lec, mpi_12).
course_session(mpi_cs_lec, mpi_13). course_session(mpi_cs_lec, mpi_14).
course_session(mpi_cs_lec, mpi_15). course_session(mpi_cs_lec, mpi_16).
course_session(mpi_cs_lec, mpi_17). course_session(mpi_cs_lec, mpi_18).
course_session(mpi_cs_lec, mpi_19). course_session(mpi_cs_lec, mpi_20).
course_session(mpi_cs_lec, mpi_21). course_session(mpi_cs_lec, mpi_22).
course_session(mpi_cs_lec, mpi_23). course_session(mpi_cs_lec, mpi_24).

course_session(mpi_cs_td, mpi_1).  course_session(mpi_cs_td, mpi_2).
course_session(mpi_cs_td, mpi_3).  course_session(mpi_cs_td, mpi_4).
course_session(mpi_cs_td, mpi_5).  course_session(mpi_cs_td, mpi_6).
course_session(mpi_cs_td, mpi_7).  course_session(mpi_cs_td, mpi_8).
course_session(mpi_cs_td, mpi_9).  course_session(mpi_cs_td, mpi_10).
course_session(mpi_cs_td, mpi_11). course_session(mpi_cs_td, mpi_12).
course_session(mpi_cs_td, mpi_13). course_session(mpi_cs_td, mpi_14).
course_session(mpi_cs_td, mpi_15). course_session(mpi_cs_td, mpi_16).
course_session(mpi_cs_td, mpi_17). course_session(mpi_cs_td, mpi_18).
course_session(mpi_cs_td, mpi_19). course_session(mpi_cs_td, mpi_20).
course_session(mpi_cs_td, mpi_21). course_session(mpi_cs_td, mpi_22).
course_session(mpi_cs_td, mpi_23). course_session(mpi_cs_td, mpi_24).

course_session(mpi_cs_tp, mpi_1).  course_session(mpi_cs_tp, mpi_2).
course_session(mpi_cs_tp, mpi_3).  course_session(mpi_cs_tp, mpi_4).
course_session(mpi_cs_tp, mpi_5).  course_session(mpi_cs_tp, mpi_6).
course_session(mpi_cs_tp, mpi_7).  course_session(mpi_cs_tp, mpi_8).
course_session(mpi_cs_tp, mpi_9).  course_session(mpi_cs_tp, mpi_10).
course_session(mpi_cs_tp, mpi_11). course_session(mpi_cs_tp, mpi_12).
course_session(mpi_cs_tp, mpi_13). course_session(mpi_cs_tp, mpi_14).
course_session(mpi_cs_tp, mpi_15). course_session(mpi_cs_tp, mpi_16).
course_session(mpi_cs_tp, mpi_17). course_session(mpi_cs_tp, mpi_18).
course_session(mpi_cs_tp, mpi_19). course_session(mpi_cs_tp, mpi_20).
course_session(mpi_cs_tp, mpi_21). course_session(mpi_cs_tp, mpi_22).
course_session(mpi_cs_tp, mpi_23). course_session(mpi_cs_tp, mpi_24).

course_session(mpi_eng_lec, mpi_1).  course_session(mpi_eng_lec, mpi_2).
course_session(mpi_eng_lec, mpi_3).  course_session(mpi_eng_lec, mpi_4).
course_session(mpi_eng_lec, mpi_5).  course_session(mpi_eng_lec, mpi_6).
course_session(mpi_eng_lec, mpi_7).  course_session(mpi_eng_lec, mpi_8).
course_session(mpi_eng_lec, mpi_9).  course_session(mpi_eng_lec, mpi_10).
course_session(mpi_eng_lec, mpi_11). course_session(mpi_eng_lec, mpi_12).
course_session(mpi_eng_lec, mpi_13). course_session(mpi_eng_lec, mpi_14).
course_session(mpi_eng_lec, mpi_15). course_session(mpi_eng_lec, mpi_16).
course_session(mpi_eng_lec, mpi_17). course_session(mpi_eng_lec, mpi_18).
course_session(mpi_eng_lec, mpi_19). course_session(mpi_eng_lec, mpi_20).
course_session(mpi_eng_lec, mpi_21). course_session(mpi_eng_lec, mpi_22).
course_session(mpi_eng_lec, mpi_23). course_session(mpi_eng_lec, mpi_24).

% --- IIA SESSIONS ---
course_session(iia_algo_lec, iia_1). course_session(iia_algo_lec, iia_2).
course_session(iia_algo_lec, iia_3). course_session(iia_algo_lec, iia_4).
course_session(iia_algo_lec, iia_5). course_session(iia_algo_lec, iia_6).
course_session(iia_algo_lec, iia_7).
course_session(iia_algo_td, iia_1). course_session(iia_algo_td, iia_2).
course_session(iia_algo_td, iia_3). course_session(iia_algo_td, iia_4).
course_session(iia_algo_td, iia_5). course_session(iia_algo_td, iia_6).
course_session(iia_algo_td, iia_7).
course_session(iia_algo_tp, iia_1). course_session(iia_algo_tp, iia_2).
course_session(iia_algo_tp, iia_3). course_session(iia_algo_tp, iia_4).
course_session(iia_algo_tp, iia_5). course_session(iia_algo_tp, iia_6).
course_session(iia_algo_tp, iia_7).
course_session(iia_math_lec, iia_1). course_session(iia_math_lec, iia_2).
course_session(iia_math_lec, iia_3). course_session(iia_math_lec, iia_4).
course_session(iia_math_lec, iia_5). course_session(iia_math_lec, iia_6).
course_session(iia_math_lec, iia_7).
course_session(iia_math_td, iia_1). course_session(iia_math_td, iia_2).
course_session(iia_math_td, iia_3). course_session(iia_math_td, iia_4).
course_session(iia_math_td, iia_5). course_session(iia_math_td, iia_6).
course_session(iia_math_td, iia_7).
course_session(iia_eng_lec, iia_1). course_session(iia_eng_lec, iia_2).
course_session(iia_eng_lec, iia_3). course_session(iia_eng_lec, iia_4).
course_session(iia_eng_lec, iia_5). course_session(iia_eng_lec, iia_6).
course_session(iia_eng_lec, iia_7).

% --- CBA SESSIONS ---
course_session(cba_chem_lec, cba_1). course_session(cba_chem_lec, cba_2).
course_session(cba_chem_lec, cba_3). course_session(cba_chem_lec, cba_4).
course_session(cba_chem_lec, cba_5). course_session(cba_chem_lec, cba_6).
course_session(cba_chem_lec, cba_7). course_session(cba_chem_lec, cba_8).
course_session(cba_chem_td, cba_1).  course_session(cba_chem_td, cba_2).
course_session(cba_chem_td, cba_3).  course_session(cba_chem_td, cba_4).
course_session(cba_chem_td, cba_5).  course_session(cba_chem_td, cba_6).
course_session(cba_chem_td, cba_7).  course_session(cba_chem_td, cba_8).
course_session(cba_chem_tp, cba_1).  course_session(cba_chem_tp, cba_2).
course_session(cba_chem_tp, cba_3).  course_session(cba_chem_tp, cba_4).
course_session(cba_chem_tp, cba_5).  course_session(cba_chem_tp, cba_6).
course_session(cba_chem_tp, cba_7).  course_session(cba_chem_tp, cba_8).
course_session(cba_bio_lec, cba_1).  course_session(cba_bio_lec, cba_2).
course_session(cba_bio_lec, cba_3).  course_session(cba_bio_lec, cba_4).
course_session(cba_bio_lec, cba_5).  course_session(cba_bio_lec, cba_6).
course_session(cba_bio_lec, cba_7).  course_session(cba_bio_lec, cba_8).
course_session(cba_bio_td, cba_1).   course_session(cba_bio_td, cba_2).
course_session(cba_bio_td, cba_3).   course_session(cba_bio_td, cba_4).
course_session(cba_bio_td, cba_5).   course_session(cba_bio_td, cba_6).
course_session(cba_bio_td, cba_7).   course_session(cba_bio_td, cba_8).
course_session(cba_bio_tp, cba_1).   course_session(cba_bio_tp, cba_2).
course_session(cba_bio_tp, cba_3).   course_session(cba_bio_tp, cba_4).
course_session(cba_bio_tp, cba_5).   course_session(cba_bio_tp, cba_6).
course_session(cba_bio_tp, cba_7).   course_session(cba_bio_tp, cba_8).
course_session(cba_eng_lec, cba_1).  course_session(cba_eng_lec, cba_2).
course_session(cba_eng_lec, cba_3).  course_session(cba_eng_lec, cba_4).
course_session(cba_eng_lec, cba_5).  course_session(cba_eng_lec, cba_6).
course_session(cba_eng_lec, cba_7).  course_session(cba_eng_lec, cba_8).

% --- GL SESSIONS ---
course_session(gl2_oop_lec, gl2_a).    course_session(gl2_oop_lec, gl2_b).
course_session(gl2_oop_td, gl2_a).     course_session(gl2_oop_td, gl2_b).
course_session(gl2_oop_tp, gl2_a).     course_session(gl2_oop_tp, gl2_b).
course_session(gl2_algo_lec, gl2_a).   course_session(gl2_algo_lec, gl2_b).
course_session(gl2_algo_td, gl2_a).    course_session(gl2_algo_td, gl2_b).
course_session(gl2_algo_tp, gl2_a).    course_session(gl2_algo_tp, gl2_b).
course_session(gl2_db_lec, gl2_a).     course_session(gl2_db_lec, gl2_b).
course_session(gl2_db_td, gl2_a).      course_session(gl2_db_td, gl2_b).
course_session(gl2_db_tp, gl2_a).      course_session(gl2_db_tp, gl2_b).
course_session(gl2_math_lec, gl2_a).   course_session(gl2_math_lec, gl2_b).
course_session(gl2_math_td, gl2_a).    course_session(gl2_math_td, gl2_b).
course_session(gl2_os_lec, gl2_a).     course_session(gl2_os_lec, gl2_b).
course_session(gl2_os_tp, gl2_a).      course_session(gl2_os_tp, gl2_b).
course_session(gl2_arch_lec, gl2_a).   course_session(gl2_arch_lec, gl2_b).
course_session(gl2_eng_lec, gl2_a).    course_session(gl2_eng_lec, gl2_b).

course_session(gl3_lp_lec, gl3_a).   course_session(gl3_lp_lec, gl3_b).
course_session(gl3_lp_td, gl3_a).    course_session(gl3_lp_td, gl3_b).
course_session(gl3_lp_tp, gl3_a).    course_session(gl3_lp_tp, gl3_b).
course_session(gl3_net_lec, gl3_a).  course_session(gl3_net_lec, gl3_b).
course_session(gl3_net_td, gl3_a).   course_session(gl3_net_td, gl3_b).
course_session(gl3_web_lec, gl3_a).  course_session(gl3_web_lec, gl3_b).
course_session(gl3_web_tp, gl3_a).   course_session(gl3_web_tp, gl3_b).
course_session(gl3_gl_lec, gl3_a).   course_session(gl3_gl_lec, gl3_b).
course_session(gl3_gl_td, gl3_a).    course_session(gl3_gl_td, gl3_b).
course_session(gl3_ai_lec, gl3_a).   course_session(gl3_ai_lec, gl3_b).
course_session(gl3_sec_lec, gl3_a).  course_session(gl3_sec_lec, gl3_b).
course_session(gl3_eng_lec, gl3_a).  course_session(gl3_eng_lec, gl3_b).

course_session(gl4_proj_mgmt_lec, gl4_a). course_session(gl4_proj_mgmt_lec, gl4_b).
course_session(gl4_cloud_lec, gl4_a).     course_session(gl4_cloud_lec, gl4_b).
course_session(gl4_cloud_tp, gl4_a).      course_session(gl4_cloud_tp, gl4_b).
course_session(gl4_sec_lec, gl4_a).       course_session(gl4_sec_lec, gl4_b).
course_session(gl4_sec_tp, gl4_a).        course_session(gl4_sec_tp, gl4_b).
course_session(gl4_eng_lec, gl4_a).       course_session(gl4_eng_lec, gl4_b).

course_session(gl5_arch_lec, gl5_a).  course_session(gl5_arch_lec, gl5_b).
course_session(gl5_pfe_suivi, gl5_a). course_session(gl5_pfe_suivi, gl5_b).
course_session(gl5_mgmt_lec, gl5_a).  course_session(gl5_mgmt_lec, gl5_b).

% --- RT SESSIONS ---
course_session(rt2_math_lec, rt2_a). course_session(rt2_math_lec, rt2_b).
course_session(rt2_math_td, rt2_a).  course_session(rt2_math_td, rt2_b).
course_session(rt2_sig_lec, rt2_a).  course_session(rt2_sig_lec, rt2_b).
course_session(rt2_sig_td, rt2_a).   course_session(rt2_sig_td, rt2_b).
course_session(rt2_sig_tp, rt2_a).   course_session(rt2_sig_tp, rt2_b).
course_session(rt2_elec_lec, rt2_a). course_session(rt2_elec_lec, rt2_b).
course_session(rt2_elec_tp, rt2_a).  course_session(rt2_elec_tp, rt2_b).
course_session(rt2_eng_lec, rt2_a).  course_session(rt2_eng_lec, rt2_b).

course_session(rt3_proto_lec, rt3_a). course_session(rt3_proto_lec, rt3_b).
course_session(rt3_proto_td, rt3_a).  course_session(rt3_proto_td, rt3_b).
course_session(rt3_proto_tp, rt3_a).  course_session(rt3_proto_tp, rt3_b).
course_session(rt3_ant_lec, rt3_a).   course_session(rt3_ant_lec, rt3_b).
course_session(rt3_emb_lec, rt3_a).   course_session(rt3_emb_lec, rt3_b).
course_session(rt3_emb_tp, rt3_a).    course_session(rt3_emb_tp, rt3_b).
course_session(rt3_eng_lec, rt3_a).   course_session(rt3_eng_lec, rt3_b).

course_session(rt4_5g_lec, rt4_a).  course_session(rt4_5g_lec, rt4_b).
course_session(rt4_5g_tp, rt4_a).   course_session(rt4_5g_tp, rt4_b).
course_session(rt4_sec_lec, rt4_a). course_session(rt4_sec_lec, rt4_b).

course_session(rt5_arch_lec, rt5_a).  course_session(rt5_arch_lec, rt5_b).
course_session(rt5_pfe_suivi, rt5_a). course_session(rt5_pfe_suivi, rt5_b).

% --- IMI SESSIONS ---
course_session(imi2_math_lec, imi2_a). course_session(imi2_math_lec, imi2_b).
course_session(imi2_math_td, imi2_a).  course_session(imi2_math_td, imi2_b).
course_session(imi2_algo_lec, imi2_a). course_session(imi2_algo_lec, imi2_b).
course_session(imi2_algo_tp, imi2_a).  course_session(imi2_algo_tp, imi2_b).
course_session(imi2_elec_lec, imi2_a). course_session(imi2_elec_lec, imi2_b).
course_session(imi2_elec_tp, imi2_a).  course_session(imi2_elec_tp, imi2_b).
course_session(imi2_eng_lec, imi2_a).  course_session(imi2_eng_lec, imi2_b).

course_session(imi3_optim_lec, imi3_a). course_session(imi3_optim_lec, imi3_b).
course_session(imi3_optim_td, imi3_a).  course_session(imi3_optim_td, imi3_b).
course_session(imi3_ml_lec, imi3_a).    course_session(imi3_ml_lec, imi3_b).
course_session(imi3_ml_tp, imi3_a).     course_session(imi3_ml_tp, imi3_b).
course_session(imi3_sys_lec, imi3_a).   course_session(imi3_sys_lec, imi3_b).
course_session(imi3_eng_lec, imi3_a).   course_session(imi3_eng_lec, imi3_b).

course_session(imi4_bigdata_lec, imi4_a). course_session(imi4_bigdata_lec, imi4_b).
course_session(imi4_bigdata_tp, imi4_a).  course_session(imi4_bigdata_tp, imi4_b).
course_session(imi4_cv_lec, imi4_a).      course_session(imi4_cv_lec, imi4_b).

course_session(imi5_pfe_suivi, imi5_a). course_session(imi5_pfe_suivi, imi5_b).

% --- CH SESSIONS ---
course_session(ch2_chem_lec, ch2_a). course_session(ch2_chem_lec, ch2_b).
course_session(ch2_chem_td, ch2_a).  course_session(ch2_chem_td, ch2_b).
course_session(ch2_chem_tp, ch2_a).  course_session(ch2_chem_tp, ch2_b).
course_session(ch2_math_lec, ch2_a). course_session(ch2_math_lec, ch2_b).
course_session(ch2_math_td, ch2_a).  course_session(ch2_math_td, ch2_b).
course_session(ch2_phys_lec, ch2_a). course_session(ch2_phys_lec, ch2_b).
course_session(ch2_eng_lec, ch2_a).  course_session(ch2_eng_lec, ch2_b).

course_session(ch3_proc_lec, ch3_a). course_session(ch3_proc_lec, ch3_b).
course_session(ch3_proc_td, ch3_a).  course_session(ch3_proc_td, ch3_b).
course_session(ch3_proc_tp, ch3_a).  course_session(ch3_proc_tp, ch3_b).
course_session(ch3_anal_lec, ch3_a). course_session(ch3_anal_lec, ch3_b).
course_session(ch3_eng_lec, ch3_a).  course_session(ch3_eng_lec, ch3_b).

course_session(ch4_env_lec, ch4_a).  course_session(ch4_env_lec, ch4_b).
course_session(ch4_sim_lec, ch4_a).  course_session(ch4_sim_lec, ch4_b).
course_session(ch4_sim_tp, ch4_a).   course_session(ch4_sim_tp, ch4_b).

course_session(ch5_pfe_suivi, ch5_a). course_session(ch5_pfe_suivi, ch5_b).

% --- BIO SESSIONS ---
course_session(bio2_bio_lec, bio2_a). course_session(bio2_bio_lec, bio2_b).
course_session(bio2_bio_td, bio2_a).  course_session(bio2_bio_td, bio2_b).
course_session(bio2_bio_tp, bio2_a).  course_session(bio2_bio_tp, bio2_b).
course_session(bio2_cell_lec, bio2_a). course_session(bio2_cell_lec, bio2_b).
course_session(bio2_cell_tp, bio2_a).  course_session(bio2_cell_tp, bio2_b).
course_session(bio2_math_lec, bio2_a). course_session(bio2_math_lec, bio2_b).
course_session(bio2_eng_lec, bio2_a).  course_session(bio2_eng_lec, bio2_b).

course_session(bio3_micro_lec, bio3_a). course_session(bio3_micro_lec, bio3_b).
course_session(bio3_micro_tp, bio3_a).  course_session(bio3_micro_tp, bio3_b).
course_session(bio3_biopro_lec, bio3_a). course_session(bio3_biopro_lec, bio3_b).
course_session(bio3_biopro_td, bio3_a).  course_session(bio3_biopro_td, bio3_b).
course_session(bio3_eng_lec, bio3_a).    course_session(bio3_eng_lec, bio3_b).

course_session(bio4_bioinfo_lec, bio4_a). course_session(bio4_bioinfo_lec, bio4_b).
course_session(bio4_bioinfo_tp, bio4_a).  course_session(bio4_bioinfo_tp, bio4_b).
course_session(bio4_env_lec, bio4_a).     course_session(bio4_env_lec, bio4_b).

course_session(bio5_pfe_suivi, bio5_a). course_session(bio5_pfe_suivi, bio5_b).
