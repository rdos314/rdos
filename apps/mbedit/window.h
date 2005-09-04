/*      window.h                                    01.02.96       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/     header file for window.c
/
*/

/* -FF-  */

/************************/
/*  function prototypes */
/************************/

/* local */
static int window_split  (void);

/* global */
extern int window_change (void);
extern int window_do     (void);
extern int window_kill   (void);
extern int window_set    (int flag);
extern int window_adjust (void);

/* -FF-  */

/* Modification History */
/* 28.09.93 - file erzeugt */
/* 30.09.93 - window_set() */
/* 01.10.93 - window_adjust() */
/* 03.10.93 - exchange_longs(), ...ints() */
/* 01.02.96 - exchange_longs(), ...ints() removed */
