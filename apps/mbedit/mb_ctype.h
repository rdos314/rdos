/*      mb_ctype.h                          04.07.94       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for mb_ctype.c (function prototypes)
/
*/


/* some constants */

/* function prototypes */

extern int mb_toupper (int arg);
extern int mb_tolower (int arg);
extern int mb_isdigit (int arg);
extern int mb_isxdigit (int arg);
extern int mb_isprint (int arg);
extern int mb_isspace (int arg);


/* Modification History */
/* 15.01.93 - file erzeugt */
/* 04.07.94 - mb_isspace */
