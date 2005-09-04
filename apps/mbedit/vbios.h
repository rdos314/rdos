/*      vbios.h                             14.02.95       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for vbios.c (function prototypes)
/
*/


/* div. constants */
#define VIDEO_INT     0x10    /* Video-Interrupt     */
#define SET_POSN      0x2     /* Set Cursor Position */
#define SET_VMODE     0x0     /* Setze Video Mode (clear) */
#define GET_VMODE     0xf     /* Get Video Mode      */
#define GET_VSTATE    0x1b    /* Get Video BIOS State Information */
#define SAVE_VSTATE   0x1c    /* Save/Restore Video BIOS State */

#define VIDEO_CHAR    17      /* EGA/VGA Character generator routines */
#define LOAD_USER     16      /* EGA/VGA User specified character set */
#define LOAD_8x8      18      /* EGA/VGA 8x8-Character Set */
#define LOAD_8x14     17      /* EGA/VGA 14x8-Character Set */
#define LOAD_8x16     20      /* VGA 16x8-Character Set */

/* macros */
#if ((ACT_SERVER == SERVER_VGA) && (WITH_WINCH == 5) && 0)
#define SaveVideoContext()      vb_savecontext ()
#define RestoreVideoContext()   vb_restorecontext ()
#else
#define SaveVideoContext()   
#define RestoreVideoContext()
#endif

/* function prototypes */
extern int  vb_getpage  (void);
extern void vb_setcur   (int posn);
extern void vb_ctoxy    (int x, int y);
extern int  vb_getvmode (void);
extern int  vb_setvmode (int mode);
extern int  vb_getvsize (int* cols, int* lines);
extern void vb_savecontext (void);
extern void vb_restorecontext (void);
extern void vb_setvlines (int lines);
extern void vb_switch_lines (void);


/* Modification History */
/* 19.12.92 - file erzeugt */
/* 21.12.92 - vb_getvmode(), vb_setvmode () */
/* 21.12.92 - vb_getvmode (), vb_setvmode () */
/* 22.01.95 - vb_getvsize (), ... */
