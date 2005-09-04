/*      memo_hnd.h                          25.08.93       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for memo_hnd.c (function prototypes)
/
*/


/* some constants */

/* function prototypes */

/* local */

/* global */

#if (BUFF_MALLOC == BUFF_HUGE)
   extern void FA_HU * loc_malloc (long length);
#else
   extern void FA_HU * loc_malloc (size_t length);
#endif

extern int  loc_free (void FA_HU *buffer);

extern void *mac_malloc (size_t length);
extern int  mac_free (void *buffer);

extern char *memcpy_rev (char FA_HU *dest, const char FA_HU *src, long length);


/* Modification History */
/* 03.12.92 - file erzeugt */
/* 15.01.93 - file aufgeteilt in memo_hnd.h, microsft.h, mb_ctype.h */
/* 13.09.93 - mac_malloc(), mac_free() */
