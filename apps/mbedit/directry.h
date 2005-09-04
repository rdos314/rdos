/*      directry.h                                    10.11.93       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for directry.c
/
*/


/************************/
/*  include files       */
/************************/


#if (WILD_NAMES)

#if (ACT_OP_SYSTEM == MS_DOS) || (ACT_OP_SYSTEM == WIN_32) || (ACT_OP_SYSTEM == RDOS)

/* emulation of the unix + os/9 directory functions */

typedef char DIR;
struct dirent
       {
          long d_ino;     /* inode number */
          char *d_name;   /* filename */
       };

extern DIR *opendir (char *path);
extern void closedir (DIR *dir_p);
extern struct dirent *readdir (DIR *dir_p);

#endif


#if (ACT_OP_SYSTEM == OS_9)
#define dirent direct
#endif

#endif

/* -FF-  */

/* Modification History */
/* 10.11.93 - file erzeugt */
