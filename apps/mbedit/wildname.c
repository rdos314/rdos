/*      wildname.c                                    14.02.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    ausgelagerte functions von mbedit.c
/
/     read files with wildcard names (e.g. "*.c")
/
*/


/************************/
/*  include files       */
/************************/

#include "config.h"
#include "standard.h"
#include "global.h"
#include "history.h"
#include "disp_hnd.h"
#include "kb_input.h"
#include "mon_outp.h"
#include "file_hnd.h"
#include "err_mess.h"
#include "memo_hnd.h"
#include "commands.h"
#include "directry.h"
#include "wildname.h"
#include "mb_ctype.h"
#include "mousec.h"


#if WILD_NAMES


/* some constants */

#if (ACT_OP_SYSTEM == MS_DOS)
#define DOS_HIGH_SPEED 1        /* <== select here */
#else
#define DOS_HIGH_SPEED 0        /* must always be 0 !! */
#endif

#define TEST_DISPLAY   0
#define TIMING_TEST    0

#define sel_entry      de[file_ind].name


/* some local variables */

static int window_length, old_window_length;    /* = f (strlen (...text)) */
/* static char file_entry [BUF_256]; */
static int top, left, bot, right;

/* -FF-  */

#if (QSORT_FUNC_ANSI)
static int comp_dirs  (const void *de1, const void *de2)
#else
static int comp_dirs  (de1, de2)
const void *de1;
const void *de2;
#endif
{
   return (((struct DIR_ENTRY *) de2)->dir_flag - 
           ((struct DIR_ENTRY *) de1)->dir_flag);
}



#if (QSORT_FUNC_ANSI)
static int comp_names (const void *de1, const void *de2)
#else
static int comp_names (de1, de2)
const void *de1;
const void *de2;
#endif
{
   return (strcmp (((struct DIR_ENTRY *) de1)->name,
                   ((struct DIR_ENTRY *) de2)->name));
}

/* -FF-  */

static struct DIR_ENTRY *get_directory_buffer (char *path  , char *file,
                                               int *dir_num, int *total_num)
{
DIR *act_dir;
struct dirent *act_ent;
int new_ind, found, ii, jj, special, high_speed, dir_flag;
size_t len;
char filter [MAX_FILENAME];  /* without path */
static struct DIR_ENTRY *de;

struct stat buff;
int save_len;

/* get a copy of filename */
   strncpy (filter, file, sizeof(filter));

/* step 1.) */

/* check, if directory exists */
   if ((act_dir = opendir (path)) == NULL)
      return NULL;

/* count no of files */
#if TEST_DISPLAY
   show_status_line_2 ("Counting Directory ...", 0, -1, 0);
#endif
   *total_num = 0;
   while ((act_ent = readdir (act_dir)) != NULL)
   {
      (*total_num)++;  /* count every entry, even those, which are filtered */
   }                   /* out later on. so we are on the safe side. */
   closedir (act_dir);

/* free old buffer */
   if (de)
      free (de);

/* get dynamic memory */
   de = (struct DIR_ENTRY *) malloc (*total_num * sizeof (struct DIR_ENTRY));
   if (de == NULL)  /* NEU ! 29.09.94 */
      return NULL;

/* step 2.) */

/* read the filenames into allocated buffer */
   if ((act_dir = opendir (path)) == NULL)
      return NULL;

#if TEST_DISPLAY
   show_status_line_2 ("Reading Directory ...", 0, -1, 0);
#endif
   *total_num = 0;
   *dir_num = 0;
   while ((act_ent = readdir (act_dir)) != NULL)
   {
   /* look for valid pathname and type (dir or file) */

   /* decide, which method is used (stat = slow) */
      high_speed = 1;
      if ((!DOS_HIGH_SPEED) ||
          (strcmp(act_ent->d_name, "..") == 0))
         high_speed = 0;

      dir_flag = -1;   /* invalid */

#if (ACT_OP_SYSTEM == MS_DOS)
      if (high_speed)
      {
         dir_flag = ((act_ent->d_ino & _A_SUBDIR) != 0);
      }
      else
#endif
      {
      /* construct full pathname */
         save_len = strlen (path);
         strncat (path, FILE_SEPARATOR, BUF_256);
         strncat (path, act_ent->d_name, BUF_256);

         if (!stat (path, &buff))
         /* dir_flag = ((buff.st_mode & S_IFMT) == S_IFDIR); bugfix 15.11.96 */
            dir_flag = ((buff.st_mode & S_IFDIR) != 0);

      /* restore old pathname */
         path[save_len] = '\0';
      }

   /* valid file entry ? */   /* dir_flag = -1 : invalid entry */
                              /*          =  0 : file          */
                              /*          =  1 : directory     */
      if (dir_flag >= 0)
      {
         if (dir_flag)
         {                       /* directory */
            (*dir_num)++;
            de [*total_num].dir_flag = 1;
            strncpy (de [*total_num].name, act_ent->d_name, MAX_FILENAME); 
            (*total_num)++;
         }
         else
         {                       /* file */

         /* check for special cases "*" and "*.*" */
#if 0
          which files do match the filter ?
          (all files, with or without extension)
              
             \ filter |   "*"   |  "*.*"  |
          os   \      |         |         |
          ------------+---------+---------+
          unix + os/9 |  all    |with ext.|
          ------------+---------+---------+
          ms-dos      | w/o ext.|  all    |
          ------------+---------+---------+
#endif
            special = 0;
            if (strcmp (filter, "*"  ) == 0) special = 1;
            if (strcmp (filter, "*.*") == 0) special = 2;
            
            switch (special)
            {
               case 1:    /* "*" */
#if (ACT_OP_SYSTEM == MS_DOS)
                                    /* use files without extension */
                  found = (strchr (act_ent->d_name, '.') == NULL);
#else
                  found = 1;        /* use all files */
#endif
                  break;

               case 2:    /* "*.*" */
#if (ACT_OP_SYSTEM == MS_DOS)
                  found = 1;        /* use all files */
#else
                                    /* use files with extension */
                  found = (strchr (act_ent->d_name, '.') != NULL);
#endif
                  break;

               default:
               /* check for match */
                  new_ind = (int) (comm_find ((char FA_HU *)act_ent->d_name, 0L, 
                                          (long)strlen (act_ent->d_name), filter,
                                          1, 0, 0,
                                          1, &len));
      
               /* name found ? */
                  found = (new_ind >= 0);
      
               /* check 1st char */
                  if ((file[0] != '*') &&
                      (new_ind != (int) len))
                     found = 0;
      
               /* check last char */
                  ii = strlen (file);
                  jj = strlen (act_ent->d_name);
                  if ((file[ii-1] != '*') &&
                      (new_ind != jj))
                  found = 0;
                  break;
            }  /* switch special */

         /* use this file ? */
            if (found)
            {
               de [*total_num].dir_flag = 0;
               strncpy (de [*total_num].name, act_ent->d_name, MAX_FILENAME); 
               (*total_num)++;
            }
         }
      }
   }  /* while act_ent != NULL */
   closedir (act_dir);


/* step 3.) */
#if TEST_DISPLAY
   show_status_line_2 ("Sorting Directory ...", 0, -1, 0);

#endif

/* sort all entries */
/* sort dirs on top */
   qsort (de, *total_num,
          sizeof(struct DIR_ENTRY), comp_dirs);

/* sort entries (separate for dirs + files) */
   qsort (de, *dir_num,
          sizeof(struct DIR_ENTRY), comp_names);

   qsort (&de[*dir_num], (*total_num - *dir_num),
          sizeof(struct DIR_ENTRY), comp_names);


#if TEST_DISPLAY
   show_status_line_2 ("Ready !", 0, -1, 0);
#endif

   return de;

}  /* get_directory_buffer */

/* -FF-  */

static void print_dir_line (char *string   , int act_ind ,
                            int select_flag, int directory_entry)
{
char line_buf [WILD_MAX_LEN+1];
int row, col, ii;


/* print function */
   push_cursor ();

   row = top + 1 + act_ind;
   col = left + 1;
   set_cursor_to (row, col);

   if (directory_entry)
   {
      line_buf [0] = '/';       /* 04.03.99, before: 'd' */
      set_invers_mode ();
      out_1_char (line_buf[0], 0);
      set_normal_mode ();
   }
   else
   {
      line_buf [0] = ' ';
      out_1_char (line_buf[0], 0);
   }

/* display 1 line */
   if (select_flag) set_invers_mode ();

   strncpy (&line_buf[1], string, (window_length-1));
   line_buf [window_length] = '\0';       /* forced end of string */
   out_string (&line_buf[1]);

#if (!INVERT_WHOLE_LINE)
   if (select_flag) set_normal_mode ();
#endif

   for (ii = strlen (line_buf) ; ii < window_length ; ii++)
   {
      out_1_char (' ', 0);    /* fill rest of line with blanks */
   }

#if (INVERT_WHOLE_LINE)
   if (select_flag) set_normal_mode ();
#endif

   pop_cursor ();

#if TIMING_TEST
   sleep_msec(10);  /* @@ */
#endif

   return;
}  /* print_dir_line */

/* -FF-  */

static void plot_dir_content (struct DIR_ENTRY *de,
                              int top_ind, int row_ind,
                              int total_num, int plot_new)
{
int entry, row, dir_flag;
char *string;

static int top_old, row_old, refresh_window;


/* window shifted ? */
   if ((plot_new) || (top_ind != top_old))
      refresh_window = 1;


/* if a key was pressed in between, delay update of window until next time */
   if (key_pressed ())
      return;

   push_cursor ();

/* plot window complete or only 2 lines (old and new one) */
   if (refresh_window)
   {
      refresh_window = 0;

   /* loop for all entries up to the selected one */
      for (entry = 0 ; entry < HIST_SIZE ; entry++)
      {
         if (entry < total_num)
         {
            string   = de[entry+top_ind].name;
            dir_flag = de[entry+top_ind].dir_flag;
         }
         else
         {
            string   = "";
            dir_flag = 0;
         }
   
         print_dir_line (string, entry, (entry == row_ind), dir_flag);
      }
   }
   else
   {
   /* anything modified at all ? */
      if (row_ind != row_old)
      {
      /* plot old line normal */
         entry = row_old;
         string   = de[entry+top_ind].name;
         dir_flag = de[entry+top_ind].dir_flag;
         print_dir_line (de[entry+top_ind].name, entry, 0, dir_flag);
   
      /* plot new line invers */
         entry = row_ind;
         string   = de[entry+top_ind].name;
         dir_flag = de[entry+top_ind].dir_flag;
         print_dir_line (de[entry+top_ind].name, entry, 1, dir_flag);
      }
   }

/* cursor to end of selected line */
   row = top + 1 + row_ind;
   set_cursor_to (row, right);

/* save for next turn */
   top_old = top_ind;
   row_old = row_ind;

   pop_cursor ();

   return;
}  /* plot_dir_content */

/* -FF-  */

static void plot_dir_window (struct DIR_ENTRY *de, int total_num)
{
int len, max_len, entry;
static int old_top, old_left, old_bot, old_right;

   push_cursor ();


/* bestimme max. laenge aller filenamen dieser directory */
   max_len = 0;
   for (entry = 0 ; entry < total_num ; entry++)
   {
      len = strlen (de[entry].name);
      max_len = max (max_len, len);
   }

/* begrenzen */
   max_len = max (max_len, WILD_MIN_LEN);
   max_len = min (max_len, WILD_MAX_LEN);   
   max_len = min (max_len, (COLUMNS - 5));   

   window_length = max_len + 1 + 1;   /* 1 byte for directory flag */
                                      /* 1 byte for optic          */


/* fenster mitten auf bildschirm */
   top   = (ROWS    - (HIST_SIZE     + 2)) / 2;
   left  = (COLUMNS - (window_length + 2)) / 2;
   bot   = top  + (HIST_SIZE     + 1);
   right = left + (window_length + 1);

/* begrenzen */
   top  = max (0, top);
   left = max (0, left);

/* reste alter fenster entfernen */
   if (window_length < old_window_length)
   {
      restore_window_background (old_top, old_left, old_bot, old_right);
   }
   old_window_length = window_length;
   old_top   = top;
   old_left  = left;
   old_bot   = bot;
   old_right = right;

/* plotten */
   plot_rectangle (top, left, bot, right);


   pop_cursor ();


   return;
}  /* plot_dir_window */

/* -FF-  */

static void prepare_indizes (int delta, int total_num,
                             int *file_ind, int *row_ind, int *top_ind)
{
/* modify indizes */
   *file_ind += delta;
   *row_ind  += delta;

/* limit indizes */
   *file_ind = min (*file_ind, (total_num-1));
   *file_ind = max (*file_ind, 0);

   *row_ind  = min (*row_ind , (total_num-1));
   *row_ind  = min (*row_ind , (HIST_SIZE-1));
   *row_ind  = max (*row_ind , 0);

/* calc top index */
   *top_ind  = *file_ind - *row_ind;

   return;
}  /* prepare_indizes */

/* -FF-  */

static void restore_window_background (int top, int left, int bot, int right)
{
   refresh_display_window (top, left, bot, right);
   refresh_whole_screen ();
   return;
}

/* -FF-  */

static int get_real_filename (char *pathname, int filename_index)
{
struct DIR_ENTRY *de;
int file_ind, top_ind, row_ind, key, dir_num, total_num;
int slen, ii, jj, layer, delta, empty_path, new_win, return_key;
DIR *act_dir;

#define TEXT_RESERVE 80         /* max. zulaessige strlen (text) */
static char l_text   [BUF_256 + TEXT_RESERVE];
static char filename [MAX_FILENAME];  /* without path */


/* video output ON ? */
   if (!get_video_active (0))
      return -1;   /* --> */

/* directory level (= no of separators) */
   slen = strlen (pathname);
   layer = 0;
   for (ii = 0 ; ii < slen ; ii++)
   {
      if (pathname[ii] == *FILE_SEPARATOR)
         layer++;
   }

/* separate pathname from filename */

/* file without path */
   strncpy (filename, &pathname[filename_index], sizeof(filename));

/* path without file */
   if (filename_index > 0)
   {
      empty_path = 0;
      pathname [filename_index-1] = '\0';
   }
   else
   {
      empty_path = 2;
      strcpy (pathname, ".");
   }

   old_window_length = 0;
once_more:

/* check, if directory exists */
   if (filename_index > 0)   /* index <= 0 : we are on current directory */
   {
   /* check directory */
      act_dir = opendir (pathname);

   /* test result */
      if (act_dir == NULL)
      {
         err_message (INVALID_PATH_NAME);
         restore_window_background (top, left, bot, right);
         return -1;   /* --> */
      }
   }

/* status display */
   line_2_flag = 1;
   show_status_line_2 ("Reading Directory ...", 0, -1, 0);

/* construct file with all directory entries */
   de = get_directory_buffer (pathname, filename, &dir_num, &total_num);

/* display current directory */
   sprintf (l_text, "Path: \"%s%c%s\" (%d+%d)",
                             pathname, *FILE_SEPARATOR, filename,
                             dir_num, (total_num-dir_num));
   show_status_line_2 (l_text, 0, -1, 0);

   file_ind = !strcmp (de[1].name, "..");   /* if ".." exists, point to it */
   row_ind  = file_ind;
   top_ind  = file_ind - row_ind;
   plot_dir_window (de, total_num);

#if (WITH_MOUSE)
   MouSetMoveArea (0,   0,
                   0, 255,
                   2);
#endif

#if (ACT_SERVER == SERVER_VT_100)
   text_area++;
#endif

/* command loop */
   new_win = 1;
   return_key = 0;
   while (return_key == 0)
   {
      plot_dir_content (de, top_ind, row_ind, total_num, new_win);
      new_win = 0;

      key = toupper (get_1_key (0));

      if ((key >= 'A') && (key <= 'Z'))  /* upper case character ? */
      {
      /* jump to next file with 1st char (like xtree) */
         for (ii = 1 ; ii < total_num ; ii++)
         {
            jj = (ii + file_ind) % total_num;
            
            if (toupper (de[jj].name[0]) == key)  /* match 1st char ? */
            {
               delta = jj - file_ind;

               prepare_indizes (delta, total_num,
                                &file_ind, &row_ind, &top_ind);   
               break;
            }
         }  /* for ii */
      }
      else
      {
         delta = 1;
         switch (key)
         {
            case KEY_PGUP:  /* to top and 16 more */
               delta = HIST_SIZE + file_ind - top_ind;
            /* fall through */
   
            case KEY_UP:
               prepare_indizes (-delta, total_num,
                                &file_ind, &row_ind, &top_ind);   
               break;
   
            case KEY_PGDN:  /* to bottom and 16 more */
               delta = 2 * HIST_SIZE - 1 + top_ind - file_ind;
            /* fall through */
   
            case KEY_DOWN:
               prepare_indizes (delta, total_num,
                                &file_ind, &row_ind, &top_ind);   
               break;
   
            case KEY_HOME:
               file_ind = 0;
               row_ind  = 0;
               top_ind  = 0;
               break;
   
            case KEY_END:
               file_ind = total_num-1;
               row_ind  = min (file_ind, HIST_SIZE-1);
               top_ind  = file_ind - row_ind;
               break;
   
            case 0x1b:    /* <esc> */
            case 0x03:    /* ^C */
               strncat (pathname, FILE_SEPARATOR, BUF_256);
               strncat (pathname, filename, BUF_256);

            /* remove ".\" at begin of path */
               if (empty_path)
                  strcpy (pathname, &pathname[2]);
   
               return_key = -1;   /* --> */
               break;
   
#if (VAR_EOLN)
            case 0x0d:    /* <cr>     */
            case 0x0a:    /* <lf>     */
            case 0x0d0a:  /* <cr><lf> */
#else
            case C_R:     /* <cr> */
#endif
               if (!de[file_ind].dir_flag)
               {  /* file, get it ! */
                  strncat (pathname, FILE_SEPARATOR, BUF_256);
                  strncat (pathname, sel_entry, BUF_256);
   
               /* remove ".\" at begin of path */
                  if (empty_path)
                     strcpy (pathname, &pathname[2]);
   
                  return_key = 1;   /* --> */
               }
               else
               {  /* directory, change to it ! */

                  if (strcmp (de[file_ind].name, ".") == 0)
                  {
#if 0
                     break;   /* "." : do nothing */
#else
                  /* return the directory name + separator only */
                     strncat (pathname, FILE_SEPARATOR, BUF_256);

                     return_key = 1;   /* --> */
                     break;
#endif
                  }

                  if (strcmp (de[file_ind].name, "..") == 0)
                  {           /* ".." : one directory back */
                              /* remove one entry in pathname */
                     layer--;
                     if (layer >= 0)
                     {
                        slen = strlen (pathname);
                        for (ii = slen-1 ; ii >= 0 ; ii--)
                        {
                           if (pathname[ii] == *FILE_SEPARATOR)
                           {
                              pathname[ii] = '\0';
                              filename_index = ii+1;
                              goto once_more;             /* 'tschuldigung */
                           }
                        }
                     }
                  }
   
               /* one directory fore */
               /* insert new entry in pathname */
                  layer++;
                  strncat (pathname, FILE_SEPARATOR, BUF_256);
                  strncat (pathname, sel_entry, BUF_256);
                  filename_index = strlen (pathname);
                  goto once_more;             /* 'tschuldigung */
               }
               break;
   
            case KEY_DO_NOTHING:
               break;

            default:
               beep ();
               break;
         }  /* switch (key) */
      }  /* if no upper case character */
   }  /* while */

/* end of function */
   restore_window_background (top, left, bot, right);

#if (WITH_MOUSE)
   MouSetMoveArea ( 0                , (byte) TOP_ROW,
                   (byte) (COLUMNS-1), (byte) MAX_ROW,
                    -1);
#endif

#if (ACT_SERVER == SERVER_VT_100)
   text_area--;
#endif

   return (return_key);
}  /* get_real_filename */

/* -FF-  */

int wildcard_filename (char *pathname)
{

/* input value : full pathname (e.g. "..\include\*.h")                 */ 
/*                                                                     */ 
/* return value:                                                       */ 
/*    0 : normal filename (without wildcard)         ==> take it       */
/*    1 : with wildcard, converted to valid filename ==> take it       */
/*   -1 : with wildcard, no valid filename selected  ==> keep old name */


char *tmp_name;
int wild_flag, namind, name_len, ii, result;
static char rest_string [MAX_FILENAME];


/* convert file separators + check for wildcards */
   wild_flag = 0;
   tmp_name = pathname;
   *rest_string = '\0';

   while (*tmp_name)
   {
   /* replace separators */
      if ((*tmp_name == '/') ||
          (*tmp_name == '\\'))
      {
         *tmp_name = *FILE_SEPARATOR;
      }

   /* check for wildcards */
      if ((*tmp_name == '*') ||
          (*tmp_name == '?'))
      {
         wild_flag = 1;
      }

   /* check for spaces */
      if ((wild_flag) &&
          (*tmp_name == ' '))
      {
#if (ACT_OP_SYSTEM == WIN_32)
		 if (strnicmp(&tmp_name[1], "vo", 2) == 0)
		 {
#endif
            strncpy (rest_string, tmp_name, sizeof(rest_string)-1);
            *tmp_name = '\0';   /* force end of string */
            break;
#if (ACT_OP_SYSTEM == WIN_32)
		 }
#endif
      }

      tmp_name++;
   }

#if (ACT_OP_SYSTEM == MS_DOS)

/* insert file separator between drive and path, eventually */
/* (e.g. "L:*.LST" --> "L:\*.LST") */

   if ((pathname [1] == ':') &&
       (pathname [2] != *FILE_SEPARATOR))
   {
      name_len = strlen (pathname);
      memcpy_rev (&pathname[3], &pathname[2], (long)(name_len-1));
      pathname [2] = *FILE_SEPARATOR;
   }

#endif

/* find limit between path and filename */
   namind   = 0;
   name_len = strlen (pathname);
 
   for (ii = (name_len-1) ; ii >= 0 ; ii--)   /* rueckwaerts */
   {
   /* abort search, if a separator is found before */
      if (pathname [ii] == *FILE_SEPARATOR)
      {
         namind = ii + 1;
         break; 
      }
   }  /* for ii */


/* found wildcard character ? */
   if (!wild_flag)
   {
      return 0;                              /* 0 */
   }
   else
   {
      result = get_real_filename (pathname, namind);   /* 1 or -1 */

   /* append space and rest again */
      if (*rest_string)
      {
         strcat (pathname, rest_string);
      }
      
      return result;
   }
}  /* wildcard_filename */

/* -FF-  */

#endif

/* Modification History */
/* 02.11.93 - file erzeugt */
/* 06.11.93 - wildcard_file() returns result */
/* 08.11.93 - umstellung auf opendir, readdir */
/* 29.11.93 - mb_ctype.h */
/* 12.12.93 - MouSetMoveArea () */
/* 19.12.93 - bugfix: directory "." is noe handled properly */
/* 20.12.93 - text_area */
/* 27.09.94 - type cast(s) wg. compiler warnings (microsoft c 6.0) */
/* 29.09.94 - check ((de = malloc(...)) == NULL) */
/* 22.02.95 - file_entry weggelassen */
/* 24.02.95 - QSORT_FUNC_ANSI */
/* 20.10.95 - window-size dynamic = f (filename-length) */
/* 22.10.95 - WILD_MAX_LEN, WILD_MIN_LEN */
/* 23.10.95 - bugfix */
/* 24.11.95 - wildcard_filename(): Quit Init "*.c vo" */
/* 15.11.96 - bugfix: dir_flag = ((buff.st_mode & S_IFDIR) != 0); */
/* 05.09.98 - VAR_EOLN */
/* 04.03.99 - directory sign 'd' replaced with '/' */
/* 01.05.03 - wildcard filename + "vo" in WIN_32 */
/* 14.02.04 - out_1_char (int key, int rectangle) */
