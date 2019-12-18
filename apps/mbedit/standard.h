/*      standard.h                               15.02.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for all c programs
/
*/


/************************/
/*  include files       */
/************************/

/* common include files */
#include <stdio.h>
#include <string.h>
#if (ACT_OP_SYSTEM != QNX)
#include <memory.h>
#endif
#include <signal.h>
#include <errno.h>
#include <time.h>
#include <assert.h>

#if 0
#include <ctype.h>   darf nicht verwendet werden !!
                     (siehe config.h und memo_hnd.c)
#endif
     


/* operating system dependant include files */

#if (ACT_OP_SYSTEM == MS_DOS)
#include <stdlib.h>
#include <io.h>
#include <bios.h>
#include <malloc.h>
#include <conio.h>
#include <fcntl.h>
#include <dos.h>
#include <sys\types.h>
#include <sys\stat.h>
#endif


#if (ACT_OP_SYSTEM == WIN_32) || (ACT_OP_SYSTEM == RDOS)
#include <stdlib.h>
#include <io.h>
#include <malloc.h>
#include <conio.h>
#include <fcntl.h>
// #include <dos.h>
#include <sys\types.h>
#include <sys\stat.h>

// #include <stdarg.h>
// #include <windows.h>
// #include <wincon.h>
#endif


#if (ACT_OP_SYSTEM == OS_9)
#include <stdlib.h>
#include <io.h>
#include <sgstat.h> 
#include <stat.h> 
#include <dir.h> 

#if (OS_9_PPC)
#include <rbf.h>
#include <sg_codes.h>
#include <types.h>
#include <scf.h>
#else
#include <direct.h> 
#endif

#endif


#if (UNIX)

#if (OS_QNX6)
#include <sys/dcmd_blk.h>
#include <sys/iomsg.h>
#include <fcntl.h>
#include <share.h>
#include <termios.h>
#define termio termios
/* #include <sys/statvfs.h> */
#else
#include <termio.h>
/* #include <sys/statfs.h> */
#endif

#ifndef CLOCKS_PER_SEC
#define CLOCKS_PER_SEC CLOCKS_PER_SECOND    /* e.g. UNIX_SVR4 */
#endif

#if (ACT_OP_SYSTEM != UNIX_SVR4)
#include <stdlib.h>
#else
   extern char *getenv (const char *name);
#endif

#if ((ACT_OP_SYSTEM == SCO_UNIX) && (WITH_WINCH == 3))
#define _IBCS2                   /* fuer ioctl (..., TIOCGWINSZ,...) */
#endif


/* general unix part */
#include <malloc.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <setjmp.h>
#include <dirent.h> 

/* labs ist sonst eine function definiert in stdlib.h und math.h */
#ifndef labs
#define labs abs
#endif

#ifndef const
#define const   /* nix */
#endif

#endif


/************************/
/* toupper / tolower    */
/************************/

/* switch (toupper(-nn)) bereitet unerklaerliche probleme, ferner sind     */
/* die return values der macros bzw. library-functionen sind fuer negative */
/* argumente fragwuerdig. deshalb beutze ich meine eigenen funktionen.     */
/* gleiches gilt auch fuer die is... functions (siehe auch memo_hnd.c).    */

#undef toupper
#undef tolower
#undef isdigit
#undef isxdigit
#undef isprint
#undef isspace

/* we use new function names to avoid linker conflicts */
#define toupper  mb_toupper
#define tolower  mb_tolower
#define isdigit  mb_isdigit
#define isxdigit mb_isxdigit
#define isprint  mb_isprint
#define isspace  mb_isspace


/************************/
/* often used macros    */
/************************/

#define _F_PTR(s,o) ( (void far *) ( ((unsigned long)(s) << 16u) + (o) ) )

#ifndef lengthof
#define lengthof(A) (sizeof(A)/sizeof(A[0]))
#endif

#ifndef min
#define min(a,b)        (((a) < (b)) ? (a) : (b))
#endif

#ifndef max
#define max(a,b)        (((a) > (b)) ? (a) : (b))
#endif


/************************/
/* often used defines   */
/************************/

#ifndef FALSE
#define FALSE 0
#endif

#ifndef TRUE
#define TRUE  1
#endif

#ifndef byte
#define byte  unsigned char
#endif

#ifndef word
#define word  unsigned short
#endif

#ifndef dword
#define dword unsigned long
#endif

#ifndef NULL
#define NULL 0
#endif


/* Values for the second argument to access.
   These may be OR'd together.  */
#if (ACT_OP_SYSTEM == OS_9)

#ifndef R_OK
#define R_OK S_IREAD    /* 0x01 Test for read permission.  */
#define W_OK S_IWRITE   /* 0x02 Test for write permission.  */
#define X_OK S_IEXEC    /* 0x04 Test for execute permission.  */
#define F_OK 0x00       /* 0x00 Test for existence.  */
#endif

#else

#ifndef R_OK
#define R_OK 0x04       /* 0x04 Test for read permission.  */
#define W_OK 0x02       /* 0x02 Test for write permission.  */
#define X_OK 0x01       /* 0x01 Test for execute permission.  */
#define F_OK 0x00       /* 0x00 Test for existence.  */
#endif

#endif




/************************/
/*  public variables    */
/************************/

#undef pubext
#ifdef _GLOBAL_
#define pubext
#else
#define pubext extern
#endif


/* Modification History */
/* 20.11.92 - file erzeugt */
/* 04.12.92 - ACT_OP_SYSTEM */
/* 19.12.92 - include malloc.h */
/* 21.12.92 - min, max */
/* 25.08.93 - Fallunterscheidung der Unix'e abgewandelt */
/* 29.08.93 - ms-dos: sys\types.h, sys\stat.h */
/* 30.08.93 - os/9  : modes.h, stat.h, unix: sys/stat.h */
/* 01.09.93 - #define NULL 0 */
/* 13.09.93 - UNIX_SVR4: prototype getenv() */
/* 13.09.93 - dirent.h */
/* 07.12.93 - define const (nix) */
/* 18.05.94 - macro lengthof mit #ifndef */
/* 04.07.94 - mb_isspace */
/* 21.07.94 - SCO_UNIX: _IBCS2 */
/* 28.02.95 - CLOCKS_PER_SEC(OND) */
/* 22.01.96 - OS_9: #include <stat.h>, (vorher: <inet/stat.h>) */
/* 04.02.99 - R_OK, W_OK, X_OK, F_OK */
/* 05.02.99 - R_OK, W_OK, X_OK, F_OK different for OS_9 */
/* 08.02.99 - OS_9_PPC */
/* 16.03.99 - OS_9_PPC: #include <scf.h> */
/* 15.02.04 - QNX6: New ! */
