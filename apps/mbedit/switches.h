/*      switches.h                               25.08.93       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for switches.c (function prototypes)
/
*/


/************************/
/* often used macros    */
/************************/


/************************/
/* often used defines   */
/************************/


/************************/
/*  forward references  */
/************************/

/* file: switches.c */

/* global */
extern void get_calc_vars_switches (struct CALC_VARS *cv);
extern int  switch_key_0     (int key_0, long repeat_flag, long repeat_max);

/* local */
static int  switch_last_key  (int last_key);
static int  check_for_macro  (int key, long repeat_max);
static int  switch_mode_flag (int key_0, long repeat_flag, long repeat_max);
static void show_error (char *e, int no);


/************************/
/*  public variables    */
/************************/


/* Modification History */
/* 06.12.92 - file erzeugt */
/* 29.12.92 - set_error () */
