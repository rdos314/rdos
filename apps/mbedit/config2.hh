/*      config2.hh                          15.02.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for header file config.h
/
/    definition of operating system
/
*/

/*---------------------------------*/
/* definition of operating system  */
/*---------------------------------*/

#define MS_DOS        11             /* IBM-PC and compatible */
#define WIN_32        12             /* IBM-PC w/ 32Bit OS */
#define RDOS          13             /* RDOS on 32-bit x86 */

#define OS_9          21             /* os/9 computer Eltec   */
#define OS_9000       22             /* Power PC Motorola     */

                                     /* unix, branch AT & T */
#define UNIX_SVR4     31                /* Motorola MVME 167     */

                                     /* unix, branch Berkeley */
#define DEC_ULTRIX    41                /* DECstation 5000       */
#define SGI_IRIX      42                /* SGI Crimson           */
#define SUN_OS        43                /* sun sparc station 10  */
#define SCO_UNIX      44                /* IBM-PC and compatible */
#define LINUX         45                /* IBM-PC and compatible */
#define OSF_1         46                /* DEC Alpha RISC        */
#define HP_UX         47                /* hp 700                */
#define QNX           48                /* QNX4 (!)              */
#define QNX6          49                /* QNX6                  */
#define CYGWIN        50                /* Unix for Windows      */


/* -------------------------------------------------
   ATTENTION !!  In case of additional entries,
                 please expand the list of the
                 #define TEXT_OP_SYSTEM "..." 
                 in config.h 
------------------------------------------------- */


#define ACT_OP_SYSTEM  RDOS         /* <== select here !! */


/* unterscheidung der dos-varianten */
#if defined (MBEDIT32)
#undef  ACT_OP_SYSTEM
#define ACT_OP_SYSTEM  WIN_32
#endif


/* unterscheidung der os-9-varianten */
#if (ACT_OP_SYSTEM == OS_9000)
#undef  ACT_OP_SYSTEM
#define ACT_OP_SYSTEM  OS_9
#define OS_9_PPC  1
#else
#define OS_9_PPC  0
#endif
#undef  OS_9000


/* unterscheidung der qnx-varianten */
#if (ACT_OP_SYSTEM == QNX6)
#undef  ACT_OP_SYSTEM
#define ACT_OP_SYSTEM  QNX
#define OS_QNX6   1
#else
#define OS_QNX6   0
#endif
#undef  QNX6


/* Cygwin is a special case of Linux */
#if (ACT_OP_SYSTEM == CYGWIN)
#undef  ACT_OP_SYSTEM
#define ACT_OP_SYSTEM  LINUX
#define LINUX_FOR_CYGWIN  1
#else
#define LINUX_FOR_CYGWIN  0
#endif
#undef  CYGWIN


/* unterscheidung der unix-varianten */
#if (ACT_OP_SYSTEM >= UNIX_SVR4)
#define UNIX  1
#else
#define UNIX  0
#endif

/* -FF-  */

/* Modification History */
/* 29.11.93 - file erzeugt */
/* 29.11.93 - SUN_OS: Neu ! */
/* 08.12.93 - SCO_UNIX + LINUX: Neu ! */
/* 28.02.94 - OSF_1: Neu ! */
/* 10.05.94 - HP_UX: Neu ! */
/* 16.05.94 - VERSION_SCO */
/* 17.05.94 - Unterscheidung der UNIX-Varianten */
/* 18.05.94 - Kommentar (Chromleiste) */
/* 09.09.98 - QNX */
/* 04.03.99 - OS_9000, OS_9_PPC */
/* 07.03.99 - #undef OS_9000 */
/* 07.05.03 - CYGWIN: New ! */
/* 15.02.04 - QNX6: New ! */
