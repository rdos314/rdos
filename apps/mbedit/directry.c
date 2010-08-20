/*      directry.c                                    10.11.93       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    emulation of the unix + os/9 directory functions:
/
/    "opendir", "closedir" + "readdir"
/
*/


/************************/
/*  include files       */
/************************/

#include "config.h"
#include "standard.h"
#include "directry.h"


#if (WILD_NAMES)
#if (ACT_OP_SYSTEM == MS_DOS)


static struct dirent dirent1;
static struct find_t buffer;
static int dir_status;    /* 1: one filename is already available */
                          /* 0: buffer is invalid                 */


DIR *opendir (char *path)
{
int save_len;

   save_len = strlen (path);
   strncat (path, "\\*.*", BUF_256);
   dir_status = (_dos_findfirst (path, 0xffff, &buffer) == 0);
   path[save_len] = '\0';

   if (dir_status)
   {
      dirent1.d_ino  = buffer.attrib;   /* inode is used for file attribute */
      dirent1.d_name = buffer.name;
      return (DIR *) path;
   }
   else
   {
      return NULL;
   }
}  /* opendir */


void closedir (DIR *dir_p)
{
   dir_p;    /* wg. compiler warning */

   dir_status = 0;
   return;
}  /* closedir */


struct dirent *readdir (DIR *dir_p)
{
   dir_p;    /* wg. compiler warning */

   if (dir_status)
   {
      dir_status = 0;
      return &dirent1;
   }
   else
   {
      if (_dos_findnext (&buffer) == 0)
      {
         dirent1.d_ino  = buffer.attrib;   /* inode is used for file attribute */
         dirent1.d_name = buffer.name;
         return &dirent1;
      }
      else
      {
         return NULL;
      }
   }
}  /* readdir */

#endif

#ifndef __WATCOMC__
#if (ACT_OP_SYSTEM == WIN_32) || (ACT_OP_SYSTEM == RDOS)


static struct dirent dirent1;
static struct _finddata_t buffer;
static int dir_status;    /* 1: one filename is already available */
                          /* 0: buffer is invalid                 */
static long handle;

DIR *opendir (char *path)
{
int save_len;

   save_len = strlen (path);
   strncat (path, "\\*", BUF_256);
   handle = _findfirst (path, &buffer);
   dir_status = (handle >= 0);
   path[save_len] = '\0';

   if (dir_status)
   {
      dirent1.d_ino  = buffer.attrib;   /* inode is used for file attribute */
      dirent1.d_name = buffer.name;
      return (DIR *) path;
   }
   else
   {
      return NULL;
   }
}  /* opendir */


void closedir (DIR *dir_p)
{
   dir_p;    /* wg. compiler warning */

   dir_status = 0;
   return;
}  /* closedir */


struct dirent *readdir (DIR *dir_p)
{
   dir_p;    /* wg. compiler warning */

   if (dir_status)
   {
      dir_status = 0;
      return &dirent1;
   }
   else
   {
      if (_findnext (handle, &buffer) == 0)
      {
         dirent1.d_ino  = buffer.attrib;   /* inode is used for file attribute */
         dirent1.d_name = buffer.name;
         return &dirent1;
      }
      else
      {
         return NULL;
      }
   }
}  /* readdir */

#endif
#endif
#endif


/* -FF-  */

/* Modification History */
/* 10.11.93 - file erzeugt */
