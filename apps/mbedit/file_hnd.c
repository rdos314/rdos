/*      file_hnd.c                           04.03.99       */
/*!
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/  file handler (read / write datafiles)
/
*/

/****************************************************************
*                                                               *
*  BENUTZTE UNTERPROGRAMME (C LIBRARY)                          *
*                                                               *
****************************************************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "file_hnd.h"
#include "history.h"
#include "disp_hnd.h"
#include "kb_input.h"
#include "err_mess.h"
#include "mb_ctype.h"


/****************************************************************
*                                                               *
*  BENUTZTE UNTERPROGRAMME / GLOBALE VARIABLEN                  *
*                                                               *
****************************************************************/

#if (ACT_OP_SYSTEM == OS_9)
#ifndef fileno
#define fileno(p)  ((p)->_fd)
#endif
#endif

#if ((UNIX) || (ACT_OP_SYSTEM == OS_9))
#define SET_ATTRIBUTES 1
#else
#define SET_ATTRIBUTES 0
#endif


#if (ACT_OP_SYSTEM == RDOS)
#define FAST_BACKUP 0                 /* RDOS currently does not support rename */
#else
#define FAST_BACKUP 1                  /* <== select here ! */
#endif

#if ((BINARY_MODE) && (ACT_OP_SYSTEM != OS_9))
#define FAST_FILE_LENGTH 1             /* <== select here ! */
#else
#define FAST_FILE_LENGTH 0             /* must be 0 !! */
#endif


#if ((!FAST_BACKUP) || (!FAST_FILE_LENGTH))
#define BUFFER_SIZE 0x0400             /* sinnvoll: 2-er-potenz < 64 k */
static char help_buff [BUFFER_SIZE];
#endif

#define RD_WR_SIZE  0x4000             /* sinnvoll: 2-er-potenz < 64 k */


/****************************************************************
*                                                               *
*  ENDE DER DEKLARATIONEN                                       *
*                                                               *
****************************************************************/

/* -FF-  */

int delete_datafile (char *filename)
{

#if (ACT_OP_SYSTEM == UNIX_SVR4)

   return unlink (filename);

#else

   return remove (filename);

#endif

}  /* delete_datafile */


int rename_datafile (char *name_inp, char *name_outp)
{

#if (ACT_OP_SYSTEM == UNIX_SVR4)

/* link input- to bak-file */
   if (link (name_inp, name_outp) != 0)
      return (-3);   /* error */

/* remove input-file */
   if (unlink (name_inp) == 0)
      return (0);    /* o.k. */
   else
      return (-3);   /* error */

#else

int first_ind = 0;


#define OS9_WITH_BERKLIB 0   /* 0 rename with    full path in <new name> */
                             /* 1 rename without full path in <new name> */

#if ((ACT_OP_SYSTEM == OS_9) && (OS9_WITH_BERKLIB))

int ii, name_len;

/* In the Berklib, the rename function works different in os/9 : */
/* name_outp is only the filename, not the entire path (as in ms/dos + unix). */
/* Thus, we remove the path up to the begin of the filename. */

   name_len  = strlen (name_outp);
 
   for (ii = (name_len-1) ; ii >= 1 ; ii--)   /* rueckwaerts */
   {
   /* abort search, if a separator is found before */
      if (name_outp [ii] == '/')      /* path separator */
      {
         first_ind = ii + 1;
         break; 
      }
   }  /* for ii */

#endif

/* rename input-file to bak-file */
   if (rename (name_inp, &name_outp[first_ind]) == 0)
      return (0);    /* o.k. */
   else
      return (-3);   /* error */

#endif

}  /* rename_datafile */

/* -FF-  */

#if FAST_BACKUP    /* neue (schnelle) version */

static int gen_backup_file (char *name_inp, char *name_outp)
{

   delete_datafile (name_outp);

   return rename_datafile (name_inp, name_outp);

}  /* gen_backup_file */

/* -FF-  */

#else    /* alte version fuer den notfall */

static int gen_backup_file (char *name_inp, char *name_outp)
{

/************************/
/*  local definitions   */
/************************/

static FILE *fp_inp;
static FILE *fp_out;
size_t num;

/************************/
/*  open datafiles      */
/************************/

   fp_inp = fopen (name_inp, READ_FORMAT);
   if (fp_inp == NULL)
   {
      return (-1);   /* error */
   }

   fp_out = fopen (name_outp, WRITE_FORMAT);
   if (fp_out == NULL)
   {
      fclose (fp_inp);
      return (-2);   /* error */
   }


/* loop for input file */
   while ((num = fread (help_buff, 1, BUFFER_SIZE, fp_inp)) > 0)
   {
      fwrite (help_buff, 1, num, fp_out);
   }  /* end while */


/************************/
/*  end of program      */
/************************/

   fclose (fp_inp);
   fclose (fp_out);
   return (0);
}  /* gen_backup_file */

#endif

/* -FF-  */

/***************************************************************/
/* get file length                                             */
/***************************************************************/

long get_file_length (char *filename, int file_must_exist)
{
FILE *fp;
long index;

/* ACHTUNG !! bei files > 0x7fff laenge wird bei os/9 st_size negativ, */
/*            obwohl in <stat.h> als long definiert                    */

#if (FAST_FILE_LENGTH)
static struct stat filestat;
#else
size_t num;
#endif

   show_status_line_2 ("*** counting source file ***", 0, -2, 0);

/* open datafile */
   fp = fopen (filename, READ_FORMAT);  /* ACHTUNG! im ASCII-Mode: ^Z (0x1a) ==> EOF */
   if (fp == NULL)           /* file doesn't exist */
   {
      if (file_must_exist)
      {
         err_message (FILE_DOESN_T_EXIST);
         return -2;          /* error : abort --> */
      }
      else
      {
         return 0;           /* no bytes read */
      }
   }

#if (FAST_FILE_LENGTH)

/* close datafile */
   fclose (fp);

   if (stat (filename, &filestat))
      index = 0;                 /* error */
   else
      index = filestat.st_size;  /* o.k. */

#else

/* read datafile */
   index = 0;   
   while ((num = fread (help_buff, 1, BUFFER_SIZE, fp)) > 0)
   {
      index += num;
   }  /* end while */

/* close datafile */
   fclose (fp);

#endif


/* o.k. */
   return (index + 1);  /* number of bytes read + EOF */

}  /* get_file_length */

/* -FF-  */

/***************************************************************/
/* read datafile                                               */
/***************************************************************/

long read_datafile (char *filename, char FA_HU *buff_0,
                    long max_len, int file_must_exist)
{
char FA_HU * buffer;
FILE *fp;
long index;
size_t num;

   show_status_line_2 ("*** reading source file ***", 0, -2, 0);

/* valid buffer ? */
   if (buff_0 == NULL)
   {
      err_message (OUT_OF_MEMORY);
      return -1;      /* error : abort --> */
   }

/* open datafile */
   fp = fopen (filename, READ_FORMAT);
   if (fp == NULL)           /* file doesn't exist */
   {
      if (file_must_exist)
      {
         err_message (FILE_DOESN_T_EXIST);
         return -2;          /* error : abort --> */
      }
      else
      {
         *buff_0 = EOF;
         return 0;           /* no bytes read */
      }
   }

/* read datafile */   
   buffer = buff_0;
   index = 0;
   while ((num = fread (buffer, 1,
                        (size_t)(min (max_len, (long) RD_WR_SIZE)), fp)) > 0)
   {
      buffer  += num;
      index   += num;
      max_len -= num;
      if (max_len <= 0) break;
   }  /* end while */

/* close datafile */
   fclose (fp);

/* is file to large for memory buffer ? */
   if (max_len <= 0)
   {
      if (max_len == 0)
      {
         err_message (FILE_SIZE_CHANGED); /* file was increased during read */
         index--;                         /* skip this (new) character */
      }
      else
      {
         err_message (BUFFER_OVERFLOW);
         return (-3);                     /* error : abort --> */
      }
   }

/* o.k. */
   return index;  /* number of bytes read */

}  /* read_datafile */

/* -FF-  */

#if (SET_ATTRIBUTES)

#if (ACT_OP_SYSTEM == OS_9)

static int stat_2_modes (int inp_mode)
{
/* The handling of the file attributes is a little bit confused in os_9. */
/* Get attributes with "stat" , corresponding header file "inet/stat.h". */
/* Set attributes with "chmod", corresponding header file "modes.h".     */
/*                                                                       */
/* The definitions of the access rights (bit masks) are different for    */
/* "get" and "set". Totally absurd !!                                    */
/*                                                                       */
/* Both header files exclude each other !!                               */
/* We have included "inet/stat.h" here.                                  */
/*                                                                       */
/* This function translates between both worlds.                         */

/* translation table */
struct TRANSLATE
       {
          int inet_stat_h;
          int modes_h;
       };

static const struct TRANSLATE translate [] =
       {
          0400, 0x01,   /* S_IREAD , S_IREAD   */
          0200, 0x02,   /* S_IWRITE, S_IWRITE  */
          0100, 0x04,   /* S_IEXEC , S_IEXEC   */
          0004, 0x08,   /* S_IROTH , S_IOREAD  */
          0002, 0x10,   /* S_IWOTH , S_IOWRITE */
          0001, 0x20    /* S_IXOTH , S_IOEXEC  */
       };

int ii;
int outp_mode;


/* set the particular bits */
   outp_mode = 0x0000;
   for (ii = 0 ; ii < lengthof(translate) ; ii++)
   {
      if (inp_mode & translate[ii].inet_stat_h)
          outp_mode |= translate[ii].modes_h;
   }  /* for ii */

   return outp_mode;

}  /* stat_2_modes */

#endif

/***************************************************************/
/* get + put file attributes, set write permission             */
/***************************************************************/

static int mode;
static int uid;
static int gid;


static int get_file_attributes (char *filename)
{
static struct stat file_status;

   mode = 0;
   uid  = 0;
   gid  = 0;

   if (stat (filename, &file_status))
   {
      return -1;                   /* error */
   }
   else
   {                               /* o.k. */
      mode = file_status.st_mode;
      uid  = file_status.st_uid;
      gid  = file_status.st_gid;
   }

#if ((ACT_OP_SYSTEM == OS_9) && (0))   /* 28.10.96 - Braun */
   mode = stat_2_modes (mode);
#endif

   return mode;  /*  -1 : error */
                 /* else: mode  */
}  /* get_file_attributes */


static int put_file_attributes (char *filename)
{
int res_1, res_2;

   res_1 = chmod (filename, mode);       /* -1 : error */
   res_2 = chown (filename, uid, gid);   /* -1 : error */

   return (res_1 | res_2);
}  /* put_file_attributes */


static int file_without_write_permission (char *filename)
{

   return access (filename, W_OK);  /*  0 : write allowed   */
                                    /* -1 : write forbidden */

}  /* file_without_write_permission */


static int set_write_permission (char *filename)
{
#if ((ACT_OP_SYSTEM != OS_9) || (1))          /* @@ ?? 04.02.99 Check it ! */
   mode |= S_IWRITE;   /* = 0200 */
#else
   mode |= _WRITE;     /* = 0x02 */
#endif

   return chmod (filename, mode);  /*  0 : o.k.  */
                                   /* -1 : error */
}  /* set_write_permission */

#endif

/* -FF-  */

/***************************************************************/
/* write datafile                                              */
/***************************************************************/

static char *create_bak_name (char *filename)
{
#if (ACT_OP_SYSTEM == MS_DOS) || (ACT_OP_SYSTEM == RDOS)
#define LONG_BAK_NAMES  0   /* always 0 here ! */
#else
#define LONG_BAK_NAMES  1   /* for unix + os-9.
                               set to 0, if long bak names are not desired */
#endif

#define BAK_EXT ".bak"       /* 4 chars */
static char bak_name [BUF_256 + 4 + 1];
int name_len, namind;
#if (!LONG_BAK_NAMES)
int ii;
#endif

/* generates a backupname from the filename. */
/* note the special cases in the examples !  */

/* filename            bak_name      
   -----------------------------------
   "test.c"            "test.bak"      unix + os-9: test.c.bak
   "test.h"            "test.bak"      unix + os-9: test.h.bak
   ".profile"          ".profile.bak"
   "demo"              "demo.bak"    
   "./demo"            "./demo.bak"  
   "../demo"           "../demo.bak" 
*/

/* build name of backup file */
   name_len  = strlen (filename);
   namind    = name_len;


#if (!LONG_BAK_NAMES)
/* attention ! ii == 0 is not allowed, because  */
/* ".bak" is no valid filename in ms-dos + os/9 */
   for (ii = (name_len-1) ; ii >= 1 ; ii--)   /* rueckwaerts */
   {
   /* search for 1st occurence of point */
      if (filename [ii] == '.')
      {
         namind = ii;
         break; 
      }

   /* abort search, if a separator is found before */
      if ((filename [ii] == '/') ||     /* unix, os/9 */
          (filename [ii] == '\\'))      /* ms/dos     */
      {
         break; 
      }
   }  /* for ii */
#endif


   strncpy (bak_name, filename, BUF_256);
   strcpy  (&bak_name [namind], ".bak");    /* 4 chars, plus '\0' */

   return bak_name;
}  /* create_bak_name */

/* -FF-  */

/***************************************************************/
/* write datafile                                              */
/***************************************************************/

int write_datafile (char *filename, char FA_HU *buff_0,
                    long byte_anz , int overwrite_allowed,
                    int backup_file)
{
char FA_HU * buffer;
FILE *fp;
int  ii;
int  err_flag, key, file_exists, do_it;
size_t num, count;
char *bak_name;

#if (SET_ATTRIBUTES)
int key_2;
#endif

/* default */
   err_flag = 0;

/* check, if filename available */
   if (!*filename)
   {                                                     /* no: get one ! */
      do_it = get_line_2_string ("Enter Filename:",
                                 filename, C_R, ID_FILE);
      if (!do_it)
      {
         return -10;              /* aborted with ^C (silent) */
      }
      else
      {
         if (*filename)
         {                        /* got a valid name */
            overwrite_allowed = 0;
            backup_file = 0;
         }
         else
         {                        /* no: don't try to write, it doesn't work */
            err_message (INVALID_NULL_NAME);
            return -4;
         }
      }
   }

/* remove illegal spaces in filename */
#if (ACT_OP_SYSTEM == WIN_32) || (ACT_OP_SYSTEM == RDOS)
   ii = strlen(filename) - 1;
   while (ii && (filename [ii] == ' '))    /* remove trailing spaces */
   {
     filename [ii] = '\0'; 
     ii--;
   }
   while (*filename == ' ')                /* remove leading spaces */
   {
     strcpy(filename, filename+1);
   }
#else
   for (ii = 0 ; ii < (int) strlen(filename) ; ii++)
   {
      if (filename [ii] == ' ')
      {
         filename [ii] = '\0';   /* forced end of string */
         break;
      }
   }
#endif

/* check, if file exists */
   file_exists = 0;
   fp = fopen (filename, READ_FORMAT);
   if (fp != NULL)
   {
      if (!isatty(fileno(fp)))   /* not a device ? */
         file_exists = 1;

      fclose (fp);
   }

/* overwrite file ? */
   if ((file_exists) && (!overwrite_allowed))
   {
      err_message (FILE_EXISTS_OVERWRITE);

      key = get_1_key (0);
      if (toupper (key) != 'Y')
         return -5;                  /* abort */
   }

#if (SET_ATTRIBUTES)
/* read file attributes */
   if (file_exists)
   {
      get_file_attributes (filename);
      
      if (file_without_write_permission (filename))
      {
         err_message (FILE_IS_READ_ONLY);
         key_2 = get_1_key (0);
         switch (toupper (key_2))
         {
            case 'Y':
               if (set_write_permission (filename))
               {
                  err_message (COULDN_T_SET_ACCESS_RIGHTS);
               }
               break;
   
            default:
               return -6;                  /* abort */
               break;
         }
      }
   }
#endif

/* generate backup file ? */
   if ((file_exists) && (backup_file))
   {
      show_status_line_2 ("*** writing backup file ***", 0, -2, 0);
      bak_name = create_bak_name (filename);

   /* save file to BAK-file */
      err_flag = gen_backup_file (filename, bak_name);
      switch (err_flag)
      {
         case 0:
            show_status_line_2 ("*** backup file written ***", 0, -2, 0);
            break;

         case -1:
            err_message (ERROR_READ_FILE);
            break;

         case -2:
            err_message (ERROR_WRITE_FILE);
            break;

         case -3:
            err_message (ERROR_BACKUP_FILE);
            break;

         default:
            err_message (FATAL_ERROR);
            break;
      }   
   }  /* backup_file */

/* open datafile */
   show_status_line_2 ("*** writing source file ***", 0, -2, 0);


#if (ACT_OP_SYSTEM == MS_DOS)
   {
      int tmphndl;

   /* this sequence is necessary under ms/dos, because we must be sure */
   /* to open our file on this directory, not in the append path !     */

      if (_dos_creat (filename, 0, &tmphndl))
      {
         err_message (ERROR_CREATE_FILE);
         return -4;          /* error : abort --> */
      }
      _dos_close(tmphndl);
   }
#endif

   
   fp = fopen (filename, WRITE_FORMAT);
   if (fp == NULL)
   {
      err_message (ERROR_WRITE_FILE);
      return -3;          /* error : abort --> */
   }

/* write datafile */   
   buffer = buff_0;
   while (byte_anz > 0)
   {
      count = (size_t)(min (byte_anz, (long) RD_WR_SIZE));
      num = fwrite (buffer, 1, count, fp);
      buffer   += num;
      byte_anz -= num;

      if (num != count)
      {
         fclose (fp);
         err_message (ERROR_WRITE_FILE);
         return -6;          /* error : abort --> */
      }
   }  /* end while */

/* close datafile */
   if (fclose (fp) != 0)
   {
      err_message (ERROR_WRITE_FILE);
      return -6;          /* error : abort --> */
   }

/* restore file attributes */
#if (SET_ATTRIBUTES)
   if ((file_exists) && (backup_file))
   {
      if (put_file_attributes (filename))
      {
         err_message (COULDN_T_SET_ACCESS_RIGHTS);
      }
   }
#endif

   show_status_line_2 ("*** source file written ***", 0, -2, 0);

   return err_flag;   /* from generation of BAK-file */

}  /* write_datafile */

/* -FF-  */

/* Modification History */
/* 21.10.92 - file erzeugt */
/* 25.11.92 - return -3, wenn file zu gross */
/* 01.12.92 - loc_malloc (), loc_free () */
/* 03.12.92 - loc_malloc (), loc_free () public gemacht */
/* 03.12.92 - loc_malloc (), loc_free () public in memo_hnd.c ausgelagert */
/* 06.12.92 - generate backup file */
/* 08.12.92 - generate backup file with local function copy_file */
/* 09.12.92 - err_message () */
/* 19.12.92 - FA_HU (far / huge) */
/* 20.12.92 - get_file_length */
/* 28.07.93 - fopen (file, "rb") bzw. "wb" */
/* 28.07.93 - fopen (file, READ_FORMAT) bzw. WRITE_FORMAT */
/* 28.08.93 - create_bak_name () */
/* 29.08.93 - get- put_file_attributes () */
/* 31.08.93 - set_write_permission () */
/* 02.09.93 - put_file_atributes (): only if bak-file */
/* 02.09.93 - delete_datafile () */
/* 03.09.93 - bug fix: file_length(): OS9 --> OS_9 */
/* 12.09.93 - show_status_line_2 (..., ignore_batch) */
/* 16.09.93 - create_bak_name: special case OS_9 */
/* 05.10.93 - rename_datafile() */
/* 10.10.93 - ID_FILE */
/* 19.11.93 - S_IWRITE / _WRITE */
/* 29.11.93 - mb_ctype.h */
/* 06.12.93 - bugfix: error write file --> error message */
/* 22.02.94 - "Enter Filename:" aborted with ^C --> no error message */
/* 27.09.94 - type cast(s) wg. compiler warnings (microsoft c 6.0) */
/* 03.11.95 - stat_2_modes(): for setting of file attributes in os_9 */
/* 10.12.95 - read_datafile(): FILE_SIZE_CHANGED */
/* 23.01.96 - write_datafile(): check return value fclose() */
/* 28.10.96 - stat_2_modes() stillgelegt */
/* 26.02.97 - os9: rename() with full path */
/* 04.02.99 - get_ / put_file_attributes: with uid + gid */
/* 04.03.99 - LONG_BAK_NAMES */
