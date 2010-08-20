/*      microsft.h                          17.02.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for microsft.c (function prototypes)
/
/
*/


/* some constants */

/* function prototypes */

/* ersatz fuer microsoft functions (kein ANSI_Standard !!) */

/* the function "ltoa" is existent in hp-ux,           */
/* but is different from the implementation in ms-dos. */
/* so we use a macro to replace the name "ltoa".       */

#if (ACT_OP_SYSTEM != MS_DOS) && (ACT_OP_SYSTEM != WIN_32) && (ACT_OP_SYSTEM != RDOS)
#define ltoa MS_ltoa
#endif

#if (!LINUX_FOR_CYGWIN) && (!OS_QNX6)
extern int stricmp (const char *string1, const char *string2);
extern int strnicmp (const char *string1, const char *string2, size_t max_len);
#endif

extern char *strupr (char *string);
extern char *ltoa (long value, char *string, int radix);

#ifndef __WATCOMC__
extern unsigned long _lrotl (unsigned long arg, int count);
extern unsigned long _lrotr (unsigned long arg, int count);
#endif

/* Modification History */
/* 15.01.93 - file erzeugt */
/* 07.05.03 - LINUX_FOR_CYGWIN */
/* 17.02.04 - QNX6: New ! */
