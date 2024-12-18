/*      disp_hnd.c                           24.03.04       */
/*!
/  --------------------------------------------------------------
/  Copyright (C) 2004: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/  display output subroutines, operating system dependant
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
#include "history.h"
#include "disp_hnd.h"
#include "mon_outp.h"
#include "err_mess.h"
#include "kb_input.h"
#include "commands.h"
#include "memo_hnd.h"
#include "mb_ctype.h"
#include "macro.h"
#include "blocks.h"
#include "perform.h"
#include "calc_var.h"
#include "switches.h"
#include "mbed_sub.h"
#include "mbedit.h"
#include "calc.h"
#include "window.h"
#include "wildname.h"
#include "mousec.h"
#include "microsft.h"
#include "hi_light.h"
#include "ansi_out.h"


/****************************************************************
*                                                               *
*  BENUTZTE UNTERPROGRAMME / GLOBALE VARIABLEN                  *
*                                                               *
****************************************************************/

/*
/   Die Ausgabe-Optimierung kann bei MS-DOS abgeschaltet werden,
/   um Speicherplatz zu sparen. Das VGA-Video ist so schnell, dass
/   eine Optimierung nicht notwendig ist.
/   Dagegen ist Speicherplatz unter MS-DOS immer knapp.
*/

#if (ACT_OP_SYSTEM == MS_DOS) || (ACT_OP_SYSTEM == WIN_32)
#define OUTPUT_OPTIMIZED 0     /* always OFF ! */
#else
#define OUTPUT_OPTIMIZED 0     /* <== select here ! */
#endif

#if (OUTPUT_OPTIMIZED)
   static char text_buff [LIMIT_ROWS] [LIMIT_COLUMNS+1];
   static byte attr_buff [LIMIT_ROWS] [LIMIT_COLUMNS+1];
#endif
   static byte attr [LIMIT_COLUMNS+1];

#define BEG_INVERS   0x01
#define BEG_COMMENT  0x02
#define BEG_KEYWORD  0x04
#define BEG_STRING   0x08
#define END_INVERS   0x10
#define END_COMMENT  0x20
#define END_KEYWORD  0x40
#define END_STRING   0x80


#if (ACT_OP_SYSTEM == LINUX)
#define DISPLAY_PAUSE       0   /* msec */
#define CLEAR_TO_EOL_BEFORE 1   /* 1 = fids' behaviour */
#else
#define CLEAR_TO_EOL_BEFORE 0   /* 0 = less work for terminal */
#endif



/* keyword definitions for several languages */
#define ACTUAL_NUMBER_FILETYPES  num_file_types
#define FILE_TYPE  max(0, (fc->file_type < ACTUAL_NUMBER_FILETYPES ? fc->file_type : 0))


/* data for dynamic syntax highlighting (from config file "mbedit.syn") */
static HiLight *hi_light = hi_light_default;

#define STRICTLY_AEDIT_COMPATIBLE  0    /* 29.04.03 */

static int num_file_types  = 1;   /* we start with index 1 (0 = no highlighting) */


/****************************************************************
*                                                               *
*  ENDE DER DEKLARATIONEN                                       *
*                                                               *
****************************************************************/

/* -FF-  */

int is_comment_ml1 (char *buf)
{
   if (hi_light[FILE_TYPE].comment_ml1)
   {
      if (strnicmp(buf,   hi_light[FILE_TYPE].comment_ml1,
                   strlen(hi_light[FILE_TYPE].comment_ml1)) == 0)
      {
           return (strlen(hi_light[FILE_TYPE].comment_ml1));
      }
   }

   return 0;
}  /* is_comment_ml1 */



int is_comment_ml2 (char *buf)
{
   if (hi_light[FILE_TYPE].comment_ml2)
   {
      if (strnicmp(buf,   hi_light[FILE_TYPE].comment_ml2,
                   strlen(hi_light[FILE_TYPE].comment_ml2)) == 0)
      {
           return (strlen(hi_light[FILE_TYPE].comment_ml2));
      }
   }

   return 0;
}  /* is_comment_ml2 */



int is_comment_sl (char *buf)
{
   if (hi_light[FILE_TYPE].comment_sl)
   {
      if (strnicmp(buf,   hi_light[FILE_TYPE].comment_sl,
                   strlen(hi_light[FILE_TYPE].comment_sl)) == 0)
      {
           return (strlen(hi_light[FILE_TYPE].comment_sl));
      }
   }

   return 0;
}  /* is_comment_sl */

/* -FF-  */

int show_syntax_file (void)
{
int ii, jj, rows;

   printf ("\015\012");
   printf ("loaded syntax file  : \"%s\" \015\012", str_synt);
   printf ("   filetype: extension(s) \015\012");
   rows = 3;

   for (jj = 0 ; jj < ACTUAL_NUMBER_FILETYPES ; jj++)
   {
      printf ("         %2d: ", jj);
      for (ii = 0; ii < hi_light[jj].num_file_ext; ii++)
      {
         printf ("\"%s\"\t", hi_light[jj].file_ext[ii]);
      }
      printf ("\015\012");
      rows++;
   }  /* for jj */

   return rows;
}  /* show_syntax_file */

/* -FF-  */

static void reduce_delimiters (int file_index, char *string)
{
size_t ii, jj;

   for (ii = 0; ii < strlen(hi_light[file_index].e_delimit); ii++)
   {
           for (jj = 0; jj < strlen(string); jj++)
           {
                   if (hi_light[file_index].e_delimit[ii] == string[jj])
                   {
                           /* remove this character from the delimiter set */
                           memcpy(      &hi_light[file_index].e_delimit[ii],
                                            &hi_light[file_index].e_delimit[ii+1],
                                          strlen(hi_light[file_index].e_delimit) - ii);
                   }
           }  /* for jj */
   }  /* for ii */
}  /* reduce_delimiters */


char *get_hi_light_delimiters (int file_index)
{
        return hi_light[file_index].e_delimit;
}  /* get_hi_light_delimiters */

/* -FF-  */

int read_syntax_file (char *filename)
{
FILE *fp;
STATIC char parse_line [BUF_256];
char *string, *buffer;
int line_no, err_line;
char err_text [20];

#if (ACT_OP_SYSTEM == OS_9)
#define BIG_BUFFER 32
#endif

#if BIG_BUFFER
static int read_level;
static char bigbuff [BIG_BUFFER*BUFSIZ];
#endif

int counter;
long filpos = 0;

#define FILE_MUST_EXIST  1    /* NEU, konst. ! */
#define FTI  (num_file_types - 1)   /* actual index to write */


   err_line = 0;  /* default: no error */
   line_no  = 0;

/* anzeige */
   show_status_line_2 ("*** reading syntax file ***", 0, -2, 0);

/* open datafile */
   fp = fopen (filename, "r");
   if (fp == NULL)           /* file doesn't exist */
   {
#if FILE_MUST_EXIST
      err_message (FILE_DOESN_T_EXIST);
      return -2;          /* error : abort --> */
#else
      return 0;           /* no bytes read */
#endif
   }

/* for speed up */
#if BIG_BUFFER
   if (read_level == 0)    /* only the first time */
      setvbuf (fp, bigbuff, _IOFBF, sizeof(bigbuff));
   read_level++;
#endif


/* count the number of file types */
   counter = 1;  /* one additional entry '0' */
   while (fgets (parse_line, sizeof(parse_line), fp) != NULL)
   {
      if (toupper(parse_line[0]) == 'E')
         counter++;
   }  /* while fgets */
   rewind (fp);     /* back to start */

   /* create buffer and clear it */
        hi_light = (HiLight *)malloc (counter * sizeof(HiLight));
   if (hi_light != NULL)
   {
      memset (hi_light, 0, (counter * sizeof(HiLight)));
      strcpy (hi_light[0].e_delimit, TOKEN_DELIMITERS);   /* default for unknown file type */
   }
   else
   {
      return -1;
   }


/* read datafile */

/* interprete syntax file */
   while (fgets (parse_line, sizeof(parse_line), fp) != NULL)
   {
      line_no++;

      switch (toupper(parse_line[0]))
      {
      case ';':     /* comment */
      default:      /* empty lines, etc... */
         break;

      case 'E':     /* file extensions */
         strtok(parse_line, " \015\012\011");  /* skip entry */

         num_file_types++;
         strcpy (hi_light[FTI].e_delimit, TOKEN_DELIMITERS);

         /* get all tokens for this line until EOL or comment */
         counter = 0;
         for (;;)
         {
            string = strtok(NULL, " \015\012\011");
            if (string == NULL) break;   /* end of line */
            if (*string == ';') break;   /* comment */

            counter++;
         }  /* for ;; */

      /* restore the old file position */
         fseek(fp, filpos, SEEK_SET);
         fgets (parse_line, sizeof(parse_line), fp);
         strtok(parse_line, " \015\012\011");  /* skip entry */

         /* this is the array for the file extension pointer */
                        buffer = (char *)malloc(sizeof(char *) * max(1, counter));
         if (buffer != NULL)
         {
            hi_light[FTI].file_ext = (char ***)buffer;

            for (hi_light[FTI].num_file_ext = 0 ; ;
                 hi_light[FTI].num_file_ext++)
            {
               string = strtok(NULL, " \015\012\011");
               if (string == NULL) break;   /* end of line */
               if (*string == ';') break;   /* comment */

                                        buffer = (char *)malloc(strlen(string) + 1);
               if (buffer != NULL) strcpy (buffer, string);
               hi_light[FTI].file_ext[hi_light[FTI].num_file_ext] =
                                                       (char **)buffer;
            }  /* for num_file_ext */
         }  /* if buffer */
         else
         {
            sprintf (err_text, " (line %d)", line_no);
            err_message_1 (OUT_OF_MEMORY, err_text);
            break;
         }

#if 0
         {
            printf ("FTI = %d, num_file_types = %d, num_file_ext = %d: ",
                     FTI, num_file_types, hi_light[FTI].num_file_ext);
            for (ii = 0; ii < hi_light[FTI].num_file_ext; ii++)
            {
               printf ("\"%s\" ", hi_light[FTI].file_ext[ii]);
            }
            printf ("\n");
         }
#endif
         break;

      case 'C':     /* case sensitivity */
         strtok(parse_line, " \015\012\011");  /* skip entry */

         hi_light[FTI].case_sensitive = atoi(strtok(NULL, " \015\012\011"));
         break;

      case 'M':     /* comment type 1 (multiple lines) */
         strtok(parse_line, " \015\012\011");  /* skip entry */

         string = strtok(NULL, " \015\012\011");
         if (string)
         {
                                buffer = (char *)malloc(strlen(string) + 1);
            if (buffer != NULL) strcpy (buffer, string);
            hi_light[FTI].comment_ml1 = buffer;
         }

         string = strtok(NULL, " \015\012\011");
         if (string)
         {
                                buffer = (char *)malloc(strlen(string) + 1);
            if (buffer != NULL) strcpy (buffer, string);
            hi_light[FTI].comment_ml2 = buffer;
         }
         break;

      case 'S':     /* comment type 2 (single line) */
         strtok(parse_line, " \015\012\011");  /* skip entry */

         string = strtok(NULL, " \015\012\011");
         if (string)
         {
                                buffer = (char *)malloc(strlen(string) + 1);
            if (buffer != NULL) strcpy (buffer, string);
            hi_light[FTI].comment_sl = buffer;
         }
         break;

      case 'F':     /* comment type 3 (first column) */
         strtok(parse_line, " \015\012\011");  /* skip entry */

         string = strtok(NULL, " \015\012\011");
         if (string)
         {
                                buffer = (char *)malloc(strlen(string) + 1);
            if (buffer != NULL) strcpy (buffer, string);
            hi_light[FTI].comment_fc = buffer;
         }
         break;

      case 'K':     /* keywords */
         strtok(parse_line, " \015\012\011");  /* skip entry */


         if (hi_light[FTI].keywords == NULL)    /* 1st time only */
         {
            /* count the total number of keywords for this file_type */

            /* get all lines with 'K' until next file_type or EOF */
            counter = 0;
            for (;;)
            {
               if (toupper(parse_line[0]) == 'E')
               {
                  break;       /* next file_type: ==> abort */
               }  /* if 'E' */

               if (toupper(parse_line[0]) == 'K')
               {
                  for (;;)
                  {
                     string = strtok(NULL, " \015\012\011");
                     if (string == NULL) break;   /* end of line */
                     if (*string == ';') break;   /* comment */

                     counter++;
                  }  /* for ;; */
               }  /* if 'K' */

               if (fgets (parse_line, sizeof(parse_line), fp) == NULL)
                  break;  /* EOF */

               strtok(parse_line, " \015\012\011");  /* skip entry */
            }  /* for ;; */


         /* restore the old file position */
            fseek(fp, filpos, SEEK_SET);
            fgets (parse_line, sizeof(parse_line), fp);
            strtok(parse_line, " \015\012\011");  /* skip entry */

         /* this is the array for the keyword pointer */
                                buffer = (char *)malloc(sizeof(char *) * max(1, counter));
            if (buffer != NULL) hi_light[FTI].keywords = (char ***)buffer;
            hi_light[FTI].num_keywords = 0;
         }  /* 1st time only */


         if (hi_light[FTI].keywords)
         {
            for (; ; hi_light[FTI].num_keywords++)
            {
               string = strtok(NULL, " \015\012\011");
               if (string == NULL) break;   /* end of line */
               if (*string == ';') break;   /* comment */

               buffer = (char *)malloc(strlen(string) + 1);
               if (buffer != NULL) strcpy (buffer, string);
               hi_light[FTI].keywords[hi_light[FTI].num_keywords] =
                                                       (char **)buffer;
                           reduce_delimiters (FTI, string);
            }  /* for num_keywords */
         }  /* if buffer */
         else
         {
            sprintf (err_text, " (line %d)", line_no);
            err_message_1 (OUT_OF_MEMORY, err_text);
            break;
         }

         break;
      }  /* switch parse_line[0] */

      /* save last file position */
      filpos = ftell(fp);
   }  /* while loop */


/* close datafile */
   fclose (fp);


#if BIG_BUFFER
   read_level--;
#endif


   if (err_line)
   {
      sprintf (err_text, " (line %d)", err_line);
      err_message_1 (INVALID_SYNTAX_ENTRY, err_text);
      return (- err_line);  /* error */
   }
   else
   {
      show_status_line_2 ("*** got syntax file ***", 0, -2, 0);
      return 1;   /* o.k. */
   }
}  /* read_syntax_file */

/* -FF-  */

int search_syntax_file (void)
{
static char filename [BUF_256];
FILE *fp;

/* search sequence, without return between searches. */

/* 1.) search in PATH (not in ms/dos, only unix + os_9) */
/* 2.) search in mbedit path (path of exe-file = argv[0]) */
/* 3.) search in home directory */

#if (ACT_OP_SYSTEM == MS_DOS) /* || (ACT_OP_SYSTEM == WIN_32) */
#define SEARCH_IN_PATH 0
#else
#define SEARCH_IN_PATH 1
#endif

#if SEARCH_IN_PATH
static char path [BUF_256];
char *name_stt, *name_end;
#endif


#if SEARCH_IN_PATH

/* 1.) search in PATH */

/* get environment variable "PATH" */
   strncpy (path, getenv ("PATH"), sizeof (path));
   path [sizeof(path) - 1] = '\0';  /* forced end of string */

/* example: */
/* PATH=H:;D:\USR.PC\BIN;C:\SYSTEM;C:\PCLINK3;C:\BIN;D:\BIN;D:\BAT;D:\UTIL; */

/* parse environment variable */
   name_stt = path;
   name_end = path;
   while (*name_stt != 0)
   {
      while (*name_end != PATH_SEPARATOR)
      {
         if (*name_end == '\0')   /* missing last separator ? */
            break;                /* for safety reasons */
         name_end++;
      }
      *name_end = '\0';

   /* build syntax filename */
      strncpy (filename, name_stt, sizeof(filename));
      strcat  (filename, FILE_SEPARATOR);
      strcat  (filename, SYNTX_FILENAME);

#if MAC_TEST
      printf ("\015\012 filename = %s\015\012", filename);
#endif

   /* test, if file exists */
      if ((fp = fopen (filename, "r")) != NULL)
      {                                         /* found file in search path */
         fclose (fp);
         strncpy (str_synt, filename, sizeof(str_synt));
         return read_syntax_file (filename);  /* get it + return */
         break;
      }

   /* next pathname */
      name_end++;
      name_stt = name_end;
   }  /* while name_stt */

#endif

/* 2.) search in mbedit path */

/* build syntax filename */
   strcpy (filename, get_exe_path ());
   strcat (filename, FILE_SEPARATOR);
   strcat (filename, SYNTX_FILENAME);

#if MAC_TEST
   printf ("\015\012 filename = %s\015\012", filename);
#endif

/* test, if file exists */
   if ((fp = fopen (filename, "r")) != NULL)
   {                                         /* found file in search path */
      fclose (fp);
      strncpy (str_synt, filename, sizeof(str_synt));
      return read_syntax_file (filename);  /* get it + return */
   }

/* 3.) search in home directory */

/* build syntax filename */
   strcpy (filename, HOME_DIR);
   strcat (filename, FILE_SEPARATOR);
   strcat (filename, SYNTX_FILENAME);

#if MAC_TEST
   printf ("\015\012 filename = %s\015\012", filename);
#endif

/* test, if file exists */
   if ((fp = fopen (filename, "r")) != NULL)
   {                                         /* found file in search path */
      fclose (fp);
      strncpy (str_synt, filename, sizeof(str_synt));
      return read_syntax_file (filename);  /* get it + return */
   }


/* no syntax file found: use default setting from header file */
   strncpy (str_synt, "<internal data>", sizeof(str_synt));

   hi_light = hi_light_default;
   num_file_types = lengthof(hi_light_default);


   return -1;  /* nothing found */

}  /* search_syntax_file */

/* -FF-  */

/***************************************************************/
/* calculate file type from extension                          */
/***************************************************************/

int get_file_type (char *pathname)
{
int ii, jj, index;

   for (jj = 0 ; jj < ACTUAL_NUMBER_FILETYPES ; jj++)
   {
      for (ii = 0 ; ii < hi_light[jj].num_file_ext ; ii++)
      {
         /* index to possible file extension */
         index = strlen (pathname) - strlen((char *)hi_light[jj].file_ext[ii]);
         index = max (0, index);   /* avoid neg. numbers (very short filenames) */

         if (stricmp (&pathname[index], (char *)hi_light[jj].file_ext[ii]) == 0)
         {
            if (index >= 1)
            {
               if ((pathname[index-1] == '.') ||
                   (pathname[index-1] == FILE_SEPARATOR[0]))
               {
                  fc->file_type = jj;
                  return jj;
               }
            }

            /* for files without extension (e.g.: "makefile") */
            if (index == 0)
            {
               fc->file_type = jj;
               return jj;
            }
         }
      }
   }

   return 0;
}  /* get_file_type */


/***************************************************************/
/* control of screen update                                    */
/***************************************************************/

struct UPDATE {long start_index;
               int  first_row;
               int  last_row;
               };

static struct UPDATE update = { 0x7fffffff,
                               INIT_ROWS,
                               -1 };

void update_this_line (long lin_left, int row)
{
   update.start_index = min (update.start_index, lin_left);
   update.first_row   = min (update.first_row  , row);
   update.last_row    = max (update.last_row   , row);

   return;
}  /* update_this_line */


void update_rest_of_window (long lin_left, int row)
{
   update.start_index = min (update.start_index, lin_left);
   update.first_row   = min (update.first_row  , row);
   update.last_row    = max (update.last_row   , MAX_ROW);

   return;
}  /* update_rest_of_window */


void update_entire_window (long top_left)
{
   update.start_index = top_left;  /* hier kein min !!! */
#if 0
   update.first_row   = min (update.first_row  , MIN_ROW);
   update.last_row    = max (update.last_row   , MAX_ROW);
#else
   update.first_row   = MIN_ROW;    /* NEU !! 25.05.94 */
   update.last_row    = MAX_ROW;
#endif

   return;
}  /* update_entire_window */


void perform_update (char FA_HU * buff_0, long byte_anz,
                     int left_col)
{

/* anzeige bei macro execution nur, wenn gewuenscht */
   if (!get_video_active (0))
      return;     /* don't display */


/* test, if update necessary */
   if (update.last_row >= update.first_row)
   {
      disp_memory (buff_0          , update.start_index,
                   byte_anz        , left_col,
                   update.first_row, update.last_row);
   }

/* set back to invalid */
   update.start_index =  0x7fffffff;
   update.first_row   =  ROWS+1;
   update.last_row    = -1;

   return;
}  /* perform_update */

/* -FF-  */

#if (ACT_OP_SYSTEM == MS_DOS)
#define SAV_LEN  80
#else
#define SAV_LEN  LIMIT_COLUMNS
#endif

static char save_text_2 [3][SAV_LEN] =
                   {
                     MODE_TEXT_0,
                     MODE_TEXT_0,
                     MODE_TEXT_0
                   };

#if (WITH_ZULU)

static char save_line_2 [SAV_LEN];


void push_status_line_2 (void)
{
   strncpy (save_line_2, save_text_2[act_window], SAV_LEN);
   save_line_2[SAV_LEN - 1] = '\0';
}


void pop_status_line_2 (int left_justified, int cursor_pos,
                        int ignore_batch)
{
   show_status_line_2 (save_line_2, left_justified,
                       cursor_pos, ignore_batch);
}

#endif

void refresh_1_window (void)
{
   update_entire_window (fc->top_left);
   perform_update (fc->buff_0, fc->byte_anz, fc->left_col);

   show_status_line_1 (get_line_1_text (), fc);       /* @@ 22.09.94 */
   show_status_line_2 (save_text_2 [act_window], 0, -2, 0);

   return;
}  /* refresh_1_window */


void refresh_whole_screen (void)
{

#if WINDOW_COMMAND
   if (act_window)
   {
      window_change ();
      refresh_1_window ();
      window_change ();
   }
#endif

   refresh_1_window ();

   return;
}  /* refresh_whole_screen */


/* -FF-  */

/***************************************************************/
/* macro + batch + video control                               */
/***************************************************************/

static int batch_mode;
static int video_stack;

void set_batch_mode (int mode)
{
   batch_mode = mode;
}  /* set_batch_mode */


void push_video_stack (void)
{
   video_stack++;
   return;
}  /* push_video_stack */


void pop_video_stack (void)
{
   if (video_stack > 0)
   {
      video_stack--;
   }
   return;
}  /* pop_video_stack */


int get_video_active (int ignore_batch)
{
   if ((batch_mode) && (!ignore_batch))
      return 0;     /* display OFF */

   if (video_stack)
      return 0;     /* display OFF */

   if ((get_macro_status () == MACRO_EXECUTE) &&
       (set.display == 0))
      return 0;     /* display OFF */

   return 1;        /* display ON */

}  /* get_video_active */

/* -FF-  */

static char action_flag = ' ';

#if (WITH_ACTION_FLAG)

/***************************************************************/
/* display action_flag                                         */
/***************************************************************/

void show_action_flag (char flag)
{
int row, column;

/* anzeige bei macro execution nur, wenn gewuenscht */
   if (!get_video_active (0))
      return;     /* don't display */

   push_cursor ();
   set_stat_1_mode ();

   get_cursor_pos (&row, &column);
   set_cursor_to ((BOT_ROW - 1), 0);
   action_flag = flag;
   out_1_char (action_flag, 0);
   set_cursor_to (row, column);

   fflush (stdout);
   set_normal_mode ();
   pop_cursor ();

   return;
}  /* show_action_flag */

#endif

/* -FF-  */

/***************************************************************/
/* display memory                                              */
/***************************************************************/

void show_status_line_1 (char *filename, struct FILE_CONTROL *fc0)
{
static const char modified [2] = {'=', '*'};
char mod_kenn;
char text1 [LIMIT_COLUMNS], text2 [BUF_256], text3 [100], form2 [20];
int  len1, len2, len3;
char chartext [5];    /* "<xx>"         :  4 + 1 */
int  file_id, nam_ind;
char *nam_ptr;

#define LINE_1_DEBUG  0    /* <== 0: normal */
                           /*     1: test */

/* anzeige bei macro execution nur, wenn gewuenscht */
   if (!get_video_active (0))
      return;     /* don't display */

   push_cursor ();

/* aufbereiten text filename (bzw. hilfstext) */
   memset (chartext, 0, sizeof(chartext));
   if (fc0->byte_index == fc0->byte_anz)
      sprintf (chartext, "EOF ");
   else
      sprintf (chartext, "<%02x>", (((byte) *fc0->buffer) & 0xff));

/* file id : 'A', 'B', 'a', 'b' (Kleinbuchstaben bedeuten: view only) */
   if (fc0->view_only)
      file_id = fc0->buff_no + 'a';
   else
      file_id = fc0->buff_no + 'A';

/* file modified ? */
   mod_kenn = modified [fc0->change_flag & 1];

/* aufbereiten komplette ausgabe-zeile */
   set_stat_1_mode ();

/* zeile aus 3 teilen zusammensetzen               */
/*   text1         text2                text3      */
/* " file A=","L:\erwin.lst vo     ",",row: ...  " */
/* text1 hat feste    laenge                       */
/* text2 hat maximale laenge = f (laenge text3)    */
/* text3 hat minimale laenge                       */
/* die gesamt-laenge ist wieder fest !!            */

#if 0    /* comment */

/* the following statement doesn't work everywhere:                 */
/* (bug in ultrix compiler:                                         */
/* return value is 'address', but should be 'no of characters' !!)  */

   len1 = sprintf (text1, "......");

/* we use instead: */

   sprintf (text1, "......");
   len1 = strlen (text1);

#endif


#if LINE_1_DEBUG
   sprintf (text1, " topleft:%5ld,linleft:%5ld",
                    fc0->top_left, fc0->lin_left);
#else
   sprintf (text1, "%cfile %1c%1c", action_flag, file_id, mod_kenn);
#endif
   len1 = strlen (text1);

   sprintf (text3, ",row:%2d,col:%2d,line:%4ld(%4ld),char%s%5ld(%5ld) ",
                    (fc0->lrow + LINE_OFFSET), fc0->column,
                    (fc0->line_index + LINE_OFFSET), fc0->line_anz+1,
                    chartext, fc0->byte_index, fc0->byte_anz);
   len3 = strlen (text3);

   len2 = min(max(COLUMNS, INIT_COLUMNS), LIMIT_COLUMNS) - len1 - len3; /* INIT_COLUMNS - len1 - len3; */
   sprintf (form2, "%%-%ds", len2);

/* limit filename (last n chars) */
   nam_ind = max (0, ((int) strlen (filename) - len2));
   nam_ptr = &filename [nam_ind];

/* form2 = z.B.: "%-20s" */
   sprintf (text2, form2, nam_ptr);

/* zusammensetzen */
   assert ((strlen(text1) + strlen(text2)) < sizeof(text1));
   strcat (text1, text2);
   assert ((strlen(text1) + strlen(text3)) < sizeof(text1));
   strcat (text1, text3);

/* forced limitation of line */
   if (COLUMNS < INIT_COLUMNS)
   {
      text1[COLUMNS-1] = '!';
      text1[COLUMNS]   = '\0';
   }

/* show it */
   memset (attr, 0, sizeof (attr));
   optimize_output ((BOT_ROW - 1), 0, text1, attr, 2, 0);

   fflush (stdout);

   set_normal_mode ();

   pop_cursor ();

   return;
}  /* show_status_line_1 */

/* -FF-  */

void show_status_line_2 (char *loc_text, int left_justified, int cursor_pos,
                         int ignore_batch)
{
char form2[20], form3[60], form4[40];
int txt_ind, txt_len, len4, max_txt_len;
static int last_ind;

char help [LIMIT_COLUMNS];
char text [LIMIT_COLUMNS];


/* save for refresh_window */
   strncpy (save_text_2[act_window], loc_text, SAV_LEN);
   save_text_2[act_window][SAV_LEN - 1] = '\0';


/* anzeige bei macro execution nur, wenn gewuenscht */
   if (!get_video_active (ignore_batch))
      return;     /* don't display */

   push_cursor ();

/* constant string */
   sprintf (form4, " - %s%s%s - %s - M.Braun ",
            VERSION_TEXT_1, VERSION_TEXT_2, VERSION_TEXT_3, VERSION_DATE);
   len4 = strlen(form4);
   max_txt_len = max(0,(COLUMNS - len4 - 1));

/* laenge des text strings */
   txt_len = strlen (loc_text);

/* string kurz genug ? */
   if (txt_len <= max_txt_len)
   {
      txt_ind = 0;
   }
   else
   {
   /* bei ueberlangen strings: anfang / ende unterdruecken */
      if (cursor_pos < 0)
      {
         if (left_justified)   /* hinten abschneiden */
            txt_ind = 0;
         else                  /* vorn abschneiden */
            txt_ind = max (0, ((int) txt_len - max_txt_len));
      }
      else
      {
         if (left_justified == 2)     /* index in get string = 0 */
         {
            txt_ind = 0;
         }
         else
         {
         /* try last index */
            txt_ind = last_ind;

         /* cursor right of window ? */
            if ((cursor_pos - txt_ind) > max_txt_len)
            {                                             /* shift left */
               txt_ind += cursor_pos - txt_ind - max_txt_len;
            }

         /* cursor left of window ? */
            if ((cursor_pos - txt_ind) < 0)
            {                                             /* shift rigth */
               txt_ind += cursor_pos - txt_ind;
            }

         /* empty space on rigth side ? */
            if ((txt_len - txt_ind) <= max_txt_len)
            {                                             /* shift rigth */
               txt_ind += txt_len - txt_ind - max_txt_len;
            }
         }
      }
   }

   strncpy (help, &loc_text[txt_ind], max_txt_len);
   help [max_txt_len] = '\0';    /* forced end of string */
   last_ind = txt_ind;  /* fuer naechsten aufruf merken */

/* generate format string */
   sprintf (form2, "%%-%ds", max_txt_len);
   sprintf (form3, " %s%s", form2, form4);


/* ausgabe-string aufbereiten */
   sprintf (text, form3, help);

/* forced limitation of line */
   if (COLUMNS < INIT_COLUMNS)
   {
      text[COLUMNS-1] = '!';
      text[COLUMNS]   = '\0';
   }

/* suppress last character to avoid scrolling of the entire screen */
#if (ACT_OP_SYSTEM == WIN_32) || (ACT_OP_SYSTEM == RDOS)
   text[COLUMNS-1] = '\0';
#endif


/* show it */
/* ausgabe */
   set_cursor_to (BOT_ROW, 0);
   set_stat_2_mode ();

/* anzeige, ggf. mit cursor */
   memset (attr, 0, sizeof (attr));
   optimize_output (BOT_ROW, 0, text, attr, 2, (cursor_pos == -2));

   if (cursor_pos >= 0)
   {
      cursor_pos = max (0, min ((cursor_pos - txt_ind), max_txt_len));
      set_cursor_to (BOT_ROW, cursor_pos);   /* @@ +1 weggelassen */
   }
   else
   {
      if (cursor_pos == -1)
      {
         set_cursor_to (BOT_ROW, (txt_len + 1));  /* cursor hinter text */
      }
   }
   set_normal_mode ();

   fflush (stdout);

   pop_cursor ();

   return;
}  /* show_status_line_2 */

/* -FF-  */

#if (WITH_SYNTAX_HIGHLIGHTING)

#define SEARCH_HIGH_SPEED  1

#if (SEARCH_HIGH_SPEED)

#if (QSORT_FUNC_ANSI)
static int comp_strings_cs (const void *kt1, const void *kt2)
#else
static int comp_strings_cs (kt1, kt2)
const void *kt1;
const void *kt2;
#endif
{       /* case sensitive */
   return (strcmp ((char *)(*(char **)kt1),
                   (char *)(*(char **)kt2)));
}  /* comp_strings_cs */


#if (QSORT_FUNC_ANSI)
static int comp_strings_ic (const void *kt1, const void *kt2)
#else
static int comp_strings_ic (kt1, kt2)
const void *kt1;
const void *kt2;
#endif
{       /* ignore case */
   return (stricmp((char *)(*(char **)kt1),
                   (char *)(*(char **)kt2)));
}  /* comp_strings_ic */

#endif

/* -FF-  */

static size_t is_keyword (char FA_HU *buf, long index_1, long index_2)
{
/* tests, if the current buffer text is a keyword. */
/* if yes: return its length */
/* if no : return 0          */

static int first;

int ii, jj, delim1, help;
int len1, len2;
char *buffer;
char token[BUF_256];

#if (SEARCH_HIGH_SPEED)
int delta, start_index0;
#endif


/* initialize */
   if (first == 0)
   {
      first = 1;  /* never again */

#if (SEARCH_HIGH_SPEED)

   /* sort the keyword tables */
      for (jj = 0 ; jj < ACTUAL_NUMBER_FILETYPES ; jj++)
      {
         if (hi_light[jj].case_sensitive)
         {
             qsort (hi_light[jj].keywords,
                    hi_light[jj].num_keywords,
                    sizeof(char *),
                    comp_strings_cs);  /* case sensitive */
         }
         else
         {
             qsort (hi_light[jj].keywords,
                    hi_light[jj].num_keywords,
                    sizeof(char *),
                    comp_strings_ic);  /* ignore case */
         }
      }  /* for jj */

#endif


   /* calculate the lengths of the keywords and save them */
      for (jj = 0 ; jj < ACTUAL_NUMBER_FILETYPES ; jj++)
      {
      /* check, if array key_len already exists (from hi_light_default[]) */
         if (hi_light[jj].key_len == NULL)
         {
            buffer = (char *)malloc(sizeof(size_t *) * max(1, hi_light[jj].num_keywords));
            if (buffer != NULL)
            {
               hi_light[jj].key_len = (size_t *)buffer;
            }
            else
            {
               err_message (OUT_OF_MEMORY);
               break;
            }
         }

      /* now calculate the key_len */
         for (ii = 0 ; ii < hi_light[jj].num_keywords ; ii++)
         {
            hi_light[jj].key_len[ii] = strlen((char *)hi_light[jj].keywords[ii]);
         }  /* for ii */
      }  /* for jj */
   }  /* if first */


/* for safety reasons */
   if (hi_light[FILE_TYPE].key_len == NULL)
   {
      return 0;     /* no valid structure */
   }


/* delimiter before text ? */
   delim1 = 0;
   if (index_1 == 0L)
   {
      delim1 = 1;   /* begin of file */
   }
   else
   {
      if (is_delimiter (buf[-1]))
         delim1 = 1;
   }

/* check text */
   if (delim1)
   {
      /* isolate the token from the text buffer */
          memset (token, 0, sizeof(token));
      strncpy(token, buf, min((sizeof(token) - 1),
                                      (index_2 - index_1)));
      strtok (token, fc->e_delimit);
      strtok (token, " \011\015\012");  /* <space>, <tab>, <cr>, <lf> */
          len2 = strlen(token);

#if (SEARCH_HIGH_SPEED)
      start_index0 = start_index (hi_light[FILE_TYPE].num_keywords + 1);
      delta = start_index0;

      for (ii = delta-1 ; delta > 0 ;  /* */ )
      {
         if (ii >= hi_light[FILE_TYPE].num_keywords)
         {
            help = -1;          /* outside range */
         }
         else
         {
            len1 = hi_light[FILE_TYPE].key_len[ii];
                        len1 = max(len1, len2);
                        len1 = min(len1, (index_2 - index_1));

            if (hi_light[FILE_TYPE].case_sensitive)
               help = strncmp (token, (char *)hi_light[FILE_TYPE].keywords[ii], len1);
            else
               help = strnicmp(token, (char *)hi_light[FILE_TYPE].keywords[ii], len1);

            if (help == 0)
            {
               return (len1);
            }
         }

         delta >>= 1;           /* shift right 1 bit */

         if (help >= 0)         /* successive approximation */
            ii += delta;
         else
            ii -= delta;
      }  /* for loop */
#else
   /* search keyword in list */
      for (ii = 0 ; ii < hi_light[FILE_TYPE].num_keywords ; ii++)
      {
         len1 = hi_light[FILE_TYPE].key_len[ii];
                 len1 = max(len1, len2);
                 len1 = min(len1, (index_2 - index_1));

                 if (hi_light[FILE_TYPE].case_sensitive)
            help = strncmp (token, (char *)hi_light[FILE_TYPE].keywords[ii], len1);
         else
            help = strnicmp(token, (char *)hi_light[FILE_TYPE].keywords[ii], len1);

         if (help == 0)
         {
            return (len1);
         }
      }
#endif
   }  /* if delim1 */

   return 0;   /* nothing found */
}  /* is_keyword */

#endif

/* -FF-  */

int is_inside_string_or_comment (char FA_HU *buff, long start_index,
                                 long max_index, int first, int direction)
{
long ii, i1;
static int inside_s1, inside_s2, inside_sl, inside_fc, inside_ml;

   /* new line in backward direction ? */
   if ((direction == -1) &&
           (start_index < max_index))   /* avoid segmentation violation */
   {
           if ((buff[start_index + 1] == 0x0d) ||
                   (buff[start_index + 1] == 0x0a))
              first = 1;
   }

   /* or first call of this ^K command */
   if (first)
   {
   /* search begin of line */
      i1 = start_index;
      for (ii = start_index; ii >= 0; ii--)
      {
         if ((buff[ii] == 0x0d) || (buff[ii] == 0x0a))
         {
            i1 = ii + 1;
            break;
         }
      }
      inside_s1 = 0;
      inside_s2 = 0;
          inside_sl = 0;
          inside_fc = 0;
          inside_ml = 0;


   /* check for inside string */
      /* count string characters(" or ') from begin of line to start_index */
      for (ii = i1; ii < start_index; ii++)
      {
         if ((is_string_character(buff, ii, max_index) == 1) && (!inside_s2))
            inside_s1 = (inside_s1 + 1) & 0x01;    /* toggle each time */

         if ((is_string_character(buff, ii, max_index) == 2) && (!inside_s1))
            inside_s2 = (inside_s2 + 1) & 0x01;    /* toggle each time */

                 if ((inside_s1 == 0) && (inside_s2 == 0))
                 {
                    if (hi_light[FILE_TYPE].comment_sl != NULL)
                    {
               if (strnicmp(&buff[ii],
                                          hi_light[FILE_TYPE].comment_sl,
                   strlen(hi_light[FILE_TYPE].comment_sl)) == 0)
               {
                              inside_sl = 1;
               }
                        }

                    if (hi_light[FILE_TYPE].comment_fc != NULL)
                    {
               if (strnicmp(&buff[ii],
                                          hi_light[FILE_TYPE].comment_fc,
                   strlen(hi_light[FILE_TYPE].comment_fc)) == 0)
               {
                  if (start_index == 0)
                  {
                     inside_fc = 1;
                  }
                  else if ((buff[ii-1] == 0x0d) || (buff[ii-1] == 0x0a))
                  {
                     inside_fc = 1;
                  }
               }
                        }

                    if (hi_light[FILE_TYPE].comment_ml1 != NULL)
                    {
               if (strnicmp(&buff[ii],
                                          hi_light[FILE_TYPE].comment_ml1,
                   strlen(hi_light[FILE_TYPE].comment_ml1)) == 0)
               {
                              inside_ml = 1;
               }
                        }

                    if (hi_light[FILE_TYPE].comment_ml2 != NULL)
                    {
               if (strnicmp(&buff[ii],
                                          hi_light[FILE_TYPE].comment_ml2,
                   strlen(hi_light[FILE_TYPE].comment_ml2)) == 0)
               {
                              inside_ml = 0;
               }
                    }
                 }
          }
   }  /* if first */
   else
   {
      if ((is_string_character(buff, start_index, max_index) == 1) && (!inside_s2))
         inside_s1 = (inside_s1 + 1) & 0x01;    /* toggle each time */

      if ((is_string_character(buff, start_index, max_index) == 2) && (!inside_s1))
         inside_s2 = (inside_s2 + 1) & 0x01;    /* toggle each time */

          if ((inside_s1 == 0) && (inside_s2 == 0))
          {
             if (hi_light[FILE_TYPE].comment_sl != NULL)
             {
            if (strnicmp(&buff[start_index],
                                   hi_light[FILE_TYPE].comment_sl,
                strlen(hi_light[FILE_TYPE].comment_sl)) == 0)
            {
               inside_sl = (direction == 1) ? 1 : 0;
            }
         }

         if (hi_light[FILE_TYPE].comment_fc != NULL)
                 {
            if (strnicmp(&buff[start_index],
                                   hi_light[FILE_TYPE].comment_fc,
                strlen(hi_light[FILE_TYPE].comment_fc)) == 0)
            {
               if (start_index == 0)
               {
                  inside_fc = 1;
               }
               else if ((buff[start_index-1] == 0x0d) || (buff[start_index-1] == 0x0a))
               {
                  inside_fc = 1;
               }
            }
                 }

             if (hi_light[FILE_TYPE].comment_ml1 != NULL)
                 {
            if (strnicmp(&buff[start_index],
                                   hi_light[FILE_TYPE].comment_ml1,
                strlen(hi_light[FILE_TYPE].comment_ml1)) == 0)
            {
                                inside_ml = (direction == 1) ? 1 : 0;
            }
             }

             if (hi_light[FILE_TYPE].comment_ml2 != NULL)
                 {
            if (strnicmp(&buff[start_index],
                                   hi_light[FILE_TYPE].comment_ml2,
                strlen(hi_light[FILE_TYPE].comment_ml2)) == 0)
            {
                                inside_ml = (direction == 1) ? 0 : 1;
            }
             }
          }

      if ((buff[start_index] == 0x0d) || (buff[start_index] == 0x0a))
      {
         inside_s1 = 0;
         inside_s2 = 0;
             inside_sl = 0;
             inside_fc = 0;
             inside_ml = 0;
      }
   }

   return (inside_s1 || inside_s2 || inside_sl || inside_fc || inside_ml);

}  /* is_inside_string_or_comment */

/* -FF-  */

int is_inside_comment_multi(char FA_HU *buff_0, long start_index, long max_index, int first, int direction)
{
/* check, if cursor position is inside comment (type multiple lines) */
static int is_comment, inside_s1, inside_s2;
int ii;

   if ((hi_light[FILE_TYPE].comment_ml1 == NULL) ||
       (hi_light[FILE_TYPE].comment_ml2 == NULL))
   {
       return 0;
   }

   if (first)
   {
      is_comment = 0;   /* off */
          inside_s1  = 0;
          inside_s2  = 0;

      for (ii = start_index; ii >= 0; ii--)
      {
         if ((is_string_character(buff_0, ii, max_index) == 1) && (!inside_s2))
            inside_s1 = (inside_s1 + 1) & 0x01;    /* toggle each time */

         if ((is_string_character(buff_0, ii, max_index) == 2) && (!inside_s1))
            inside_s2 = (inside_s2 + 1) & 0x01;    /* toggle each time */

                 if ((inside_s1 == 0) && (inside_s2 == 0))
                 {
            if (strnicmp(&buff_0[ii], hi_light[FILE_TYPE].comment_ml1,
                               strlen(hi_light[FILE_TYPE].comment_ml1)) == 0)
                        {
               is_comment = 1;   /* on */
               break;
                        }

            if((strnicmp(&buff_0[ii],  hi_light[FILE_TYPE].comment_ml2,
                                strlen(hi_light[FILE_TYPE].comment_ml2)) == 0) &&
               (strnicmp(&buff_0[ii-1],hi_light[FILE_TYPE].comment_ml1,
                                strlen(hi_light[FILE_TYPE].comment_ml1)) != 0))
                        {
               is_comment = 0;   /* off */
               break;
                        }
         }
      }  /* for buf */
   }
   else
   {
      if ((is_string_character(buff_0, start_index, max_index) == 1) && (!inside_s2))
         inside_s1 = (inside_s1 + 1) & 0x01;    /* toggle each time */

      if ((is_string_character(buff_0, start_index, max_index) == 2) && (!inside_s1))
         inside_s2 = (inside_s2 + 1) & 0x01;    /* toggle each time */

      if ((inside_s1 == 0) && (inside_s2 == 0))
          {
         if (strnicmp(&buff_0 [start_index],  hi_light[FILE_TYPE].comment_ml1,
                                       strlen(hi_light[FILE_TYPE].comment_ml1)) == 0)
                 {
            is_comment = ((direction == 1) ? 1 : 0);
                 }

         if((strnicmp(&buff_0 [start_index],  hi_light[FILE_TYPE].comment_ml2,
                                       strlen(hi_light[FILE_TYPE].comment_ml2)) == 0) &&
            (strnicmp(&buff_0 [start_index-1],hi_light[FILE_TYPE].comment_ml1,
                                       strlen(hi_light[FILE_TYPE].comment_ml1)) != 0))
                 {
            is_comment = ((direction == 1) ? 0 : 1);
                 }
          }
   }

   return is_comment;
}  /* is_inside_comment_multi */

/* -FF-  */

static void disp_memory (char FA_HU * buff_0, long start_index,
                         long byte_anz, int left_col,
                         int start_row, int end_row)
{
int row;
int start_comment;    /* 2 : 1st line, comment: ON  */
                      /* 1 : 1st line, comment: OFF */
                      /* 0 : all other lines        */

/* anzeige bei macro execution nur, wenn gewuenscht */
   if (!get_video_active (0))
      return;     /* don't display */


#if (WITH_SYNTAX_HIGHLIGHTING)
   set_normal_mode ();

/* check backwards for begin of comment (invisible on actual screen) */
   if (is_comment_active ())
   {
      start_comment = is_inside_comment_multi(buff_0, start_index, byte_anz, 1, -1) + 1;
   }
#endif

   push_cursor ();

   for (row = start_row ; row <= end_row ; row++)
   {
      start_index = disp_1_line (buff_0, start_index, byte_anz,
                                 row, left_col, start_comment);
#if (DISPLAY_PAUSE)
      fflush(stdout);           /* NEW ! 19.04.03 */
#endif

      start_comment = 0;  /* from now on */
   }  /* for row */

   pop_cursor ();

#if (DISPLAY_PAUSE)
   fflush(stdout);              /* NEW ! 17.10.02 */
   sleep_msec(DISPLAY_PAUSE);   /* avoid, that display hangs */
#endif

#if (WITH_SYNTAX_HIGHLIGHTING)
   set_normal_mode ();
#endif

   return;
}  /* disp_memory */

/* -FF-  */

int has_single_quote_string (void)
{
int single_quote_string;

   /* Visual Basic uses single quote for comments, not strings */
   single_quote_string = 1;     /* default */

   if (hi_light[FILE_TYPE].comment_sl)
   {
      if (strnicmp("'",   hi_light[FILE_TYPE].comment_sl,
                   strlen(hi_light[FILE_TYPE].comment_sl)) == 0)
                  single_quote_string = 0;
   }

   return single_quote_string;
}  /* has_single_quote_string */

/* -FF-  */

static long disp_1_line (char FA_HU * buff_0, long start_index, long byte_anz,
                         int row, int left_col, int start_comment)
{
long index;
int  column, col_diff, tab_diff, char_cnt, sav_eol, mark_0_flag, eof_flag, ii;
int  cr_flag, is_string, inside_str, inside_1, inside_2, inside_keyword;
char ckey;
char FA_HU *buffer;

static char text [LIMIT_COLUMNS+1];

static int comment_type;   /* 0 : no comment */
                           /* 1 : c style    */
                           /* 2 : c++ style  */

#define REL_COL (column - left_col)

#if (WITH_SYNTAX_HIGHLIGHTING)
int len, comment_count_1, comment_count_2;
#endif

/* anzeige bei macro execution nur, wenn gewuenscht */
   if (!get_video_active (0))
      return (0L);              /* don't display */


   push_cursor ();

   buffer = &buff_0 [start_index];
   column = 0;
   cr_flag = 0;

   memset (text, 0, sizeof (text));
   memset (attr, 0, sizeof (attr));

   if (start_comment > 0)
      comment_type = start_comment - 1;


#if (WITH_SYNTAX_HIGHLIGHTING)
   if (start_comment == 2)     /* begin of comment ? */
   {
      if (is_comment_active ())
      {
         attr [min (max (REL_COL, 0), COLUMNS)] |=  BEG_COMMENT;
         attr [min (max (REL_COL, 0), COLUMNS)] &= ~END_COMMENT;
      /* comment_type = 1; */
      }
   }
   comment_count_1 = 0;
   comment_count_2 = 0;
   inside_keyword  = 0;
#endif


/* display all chars on this line */
   inside_str = 0;
   inside_1   = 0;
   inside_2   = 0;
   for (index = start_index ; index <= byte_anz ; index++)
   {
   /* line partially invers ? */
      if ((index >= fc->find[0]) &&
          (fc->find[0] != -1))
      {
         fc->find[0] = -1;
         attr [min (max (REL_COL, 0), COLUMNS)] |= BEG_INVERS;
      }

      if ((index >= fc->find[1]) &&
          (fc->find[1] != -1))
      {
         fc->find[1] = -1;
         attr [min (max (REL_COL, 0), COLUMNS)] |= END_INVERS;
      }


#if (WITH_SYNTAX_HIGHLIGHTING)
      if (!comment_type && !inside_keyword)
         is_string = is_string_character(buff_0, index, byte_anz);
      else
         is_string = 0;


      if (is_string)
      {
         if ((is_string == 1) && (!inside_2))
            inside_1 = (inside_1 + 1) & 0x01;    /* toggle each time */

         if ((is_string == 2) && (!inside_1))
            inside_2 = (inside_2 + 1) & 0x01;    /* toggle each time */

         inside_str = (inside_1 || inside_2);

         if (is_string_active() && inside_str)
            attr [min (max ( REL_COL   , 0), COLUMNS)] |= BEG_STRING;
         else
            attr [min (max ((REL_COL+1), 0), COLUMNS)] |= END_STRING;
      }
      else if (!comment_type && !inside_str && !inside_keyword)
      {
      /* check for keyword */
         if ((len = is_keyword (buffer, index, byte_anz)) != 0)
         {
                        if (is_keyword_active ())
                        {
               attr [min (max ( REL_COL     , 0), COLUMNS)] |= BEG_KEYWORD;
               attr [min (max ((REL_COL+len), 0), COLUMNS)] |= END_KEYWORD;
                        }
                        inside_keyword = len + 1;
         }
      }
#endif

   /* get character */
      ckey = *buffer;


#if (WITH_SYNTAX_HIGHLIGHTING)
          /* count down keyword length */
          if (inside_keyword)
          {
                 inside_keyword--;
          }


      if (!inside_str && !inside_keyword)
      {
      /* check for comments */

      /* end of comment ? */
         if (comment_type == 1)
         {
         /* count down */
            if (comment_count_2)
            {
               comment_count_2--;
               if (comment_count_2 == 0)
               {
                                  if (is_comment_active ())
                                  {
                     attr [min (max (REL_COL, 0), COLUMNS)] |=  END_COMMENT;
                     attr [min (max (REL_COL, 0), COLUMNS)] &= ~BEG_COMMENT;
                                  }
                  comment_type = 0;
               }
            }

         /* c style */
            if (comment_count_1)     /* bugfix 24.04.03 */  /*/ this is now a comment */
            {
               comment_count_1--;
            }

            if (comment_count_1 == 0)
            {
               if (hi_light[FILE_TYPE].comment_ml2)
               {
                  if (strnicmp(buffer,hi_light[FILE_TYPE].comment_ml2,
                               strlen(hi_light[FILE_TYPE].comment_ml2)) == 0)
                  {                  /* n characters from here */
                     comment_count_2 = strlen(hi_light[FILE_TYPE].comment_ml2);
                  }
               }
            }
         }

         if (comment_type == 2)
         {
         /* c++ style */
            if (ckey == EOLN_LOW)
            {
               if (is_comment_active ())
                           {
                  attr [min (max (REL_COL, 0), COLUMNS)] |=  END_COMMENT;
                  attr [min (max (REL_COL, 0), COLUMNS)] &= ~BEG_COMMENT;
                           }
               comment_type = 0;
            }
         }

      /* begin of comment ? */
         if (comment_type == 0)
         {
         /* c style */
            if (hi_light[FILE_TYPE].comment_ml1)
            {
               if (strnicmp(buffer,hi_light[FILE_TYPE].comment_ml1,
                            strlen(hi_light[FILE_TYPE].comment_ml1)) == 0)
               {
                  if (is_comment_active ())
                                  {
                     attr [min (max (REL_COL, 0), COLUMNS)] |=  BEG_COMMENT;
                     attr [min (max (REL_COL, 0), COLUMNS)] &= ~END_COMMENT;
                                  }
                  comment_type = 1;
                  comment_count_1 = strlen(hi_light[FILE_TYPE].comment_ml1);
               }
            }

         /* c++ style */
            if (hi_light[FILE_TYPE].comment_sl)
            {
               if (strnicmp(buffer,hi_light[FILE_TYPE].comment_sl,
                            strlen(hi_light[FILE_TYPE].comment_sl)) == 0)
               {
                  if (is_comment_active ())
                                  {
                     attr [min (max (REL_COL, 0), COLUMNS)] |=  BEG_COMMENT;
                     attr [min (max (REL_COL, 0), COLUMNS)] &= ~END_COMMENT;
                                  }
                  comment_type = 2;
               }
            }

         /* fortran style */
            if (hi_light[FILE_TYPE].comment_fc)
            {
               if (strnicmp(buffer,hi_light[FILE_TYPE].comment_fc,
                            strlen(hi_light[FILE_TYPE].comment_fc)) == 0)
                           {
                                  if (buffer == buff_0)
                                  {
                     if (is_comment_active ())
                                         {
                        attr [min (max (REL_COL, 0), COLUMNS)] |=  BEG_COMMENT;
                        attr [min (max (REL_COL, 0), COLUMNS)] &= ~END_COMMENT;
                                         }
                     comment_type = 2;
                                  }
                                  else if ((buffer[-1] == 0x0d) || (buffer[-1] == 0x0a))
                                  {
                     if (is_comment_active ())
                                         {
                        attr [min (max (REL_COL, 0), COLUMNS)] |=  BEG_COMMENT;
                        attr [min (max (REL_COL, 0), COLUMNS)] &= ~END_COMMENT;
                                         }
                     comment_type = 2;
                                  }
                           }
            }
         }
      }
#endif

      buffer++;

      if (EOLN_LEN_2)
      {
         if ((ckey == EOLN_HIGH) && (*buffer == EOLN_LOW))
         {
            ckey = ' ';    /* blank <cr> (only at end of line !) */
            cr_flag = 1;
         }
      }

      sav_eol = (ckey == EOLN_LOW);

   /* end of file ? */
      if (index >= byte_anz)
      {
         ckey = '|';   /* EOF */
         eof_flag = 1;
      }
      else
      {
         eof_flag = 0;
      }

   /* is this char '@' mark 0 for Buffer/Delete ? */
      if ((save_d.toggle) &&
          (index == save_d.index0))
         mark_0_flag = 1;
      else
         mark_0_flag = 0;

   /* end of line ? */
      if ((sav_eol) && (!mark_0_flag) && (!eof_flag)) break;

   /* <tab>: replace with n blanks */
      if (ckey == 0x09)
      {
         ckey = ' ';
         tab_diff = set.tabs - (column % set.tabs);
      }
      else
      {
         tab_diff = 1;
      }

   /* loop for display characters */
      for (char_cnt = 0 ; char_cnt < tab_diff ; char_cnt++)
      {
         if ((REL_COL >= 0) && (REL_COL < COLUMNS))   /* @@ vorher: -1 */
         {
         /* '@' mark for Buffer/Delete */
            if ((mark_0_flag) &&
                (char_cnt == 0))
            {
               text [REL_COL] = '@';        /* buffer, mark 0 */
            }
            else
            {
               if ((mb_isprint (ckey)) ||    /* normal printable */
                   (ckey & 0x80))            /* umlaute, usw */
                  text [REL_COL] = ckey;
               else
                  text [REL_COL] = '?';      /* control char */
            }
         }

         column++;
      }  /* for char_cnt */

   /* end of line ? */
      if (sav_eol)  break;

   }  /* for index */

/* drop <cr> at end of line */
   column -= cr_flag;

/* first position in line ? */
   if (left_col > 0)
      text [0] = '!';

/* last position in line ? */
   if (REL_COL > COLUMNS)     /* @@ vorher: >= */
      text [COLUMNS-1] = '!';

/* buffer, mark 1 ? */
   if ((save_d.toggle) &&
       (row == fc->lrow))
   {
      col_diff = fc->column - left_col;
      col_diff = max (0, min ((COLUMNS - 1), col_diff));
      text [col_diff] = '@';

   /* ggf. mit blanks auffuellen */
      if (col_diff > (int) strlen (text))
      {
         for (ii = strlen (text) ; ii < col_diff ; ii++)
         {
            text [ii] = ' ';
         }
      }
   }

/* string output */
   optimize_output (row, 0, text, attr, (start_comment != 0), 0);

   pop_cursor ();

   return (index + 1);

}  /* disp_1_line */

/* -FF-  */

long get_line_2_repeat (char *text, long old_value, int *key)
{
long new_value, help, return_value;
char l_text [80];

   sprintf (l_text, "%s %ld", text, old_value);
   show_status_line_2 (l_text, 0, -1, 0);

#if 0
#if (WITH_MOUSE)
   MouSetMoveArea (  0, 0,
                   255, 0,
                     3);
#endif

#if (ACT_SERVER == SERVER_VT_100)
   text_area++;
#endif
#endif

/* keep old value ! */
   new_value = old_value;
   return_value = -1;
   while (return_value == -1)
   {
      *key = get_1_key (1);

      if (mb_isdigit (*key))
      {
         help = 10 * new_value + (*key - '0');
         if (help >= 0)
            new_value = help;
         else
            beep ();
      }
      else
      {
         switch (*key)
         {
            case 0x1b:          /* <esc> */
            case 0x03:          /* ^C    */
               return_value = 0;          /* input aborted */
               break;

            case 0x08:          /* backspace */
            case 0x7f:          /* rubout */
               new_value /= 10;           /* letzte stelle wegnehmen */
               break;

            default:
               return_value = new_value;  /* input ready */
               break;
         }  /* switch *key */
      }

      sprintf (l_text, "%s %ld", text, new_value);
      show_status_line_2 (l_text, 0, -1, 0);
   }  /* while */

/* exit function */

#if 0
#if (WITH_MOUSE)
   MouSetMoveArea ( 0                , (byte) TOP_ROW,
                   (byte) (COLUMNS-1), (byte) MAX_ROW,
                    -1);
#endif

#if (ACT_SERVER == SERVER_VT_100)
   text_area--;
#endif
#endif

   return (return_value);
}  /* get_line_2_repeat */

/* -FF-  */

char *build_modified_string (char *str_buf, int index1,
                             int *index2, int *error)
{
/* erzeuge aus input-string "str_buf" den output-string "str_mod"  */
/* ersetze sonderzeichen durch ersatz-strings (z.B. 0x09--> "<tab>") */
/* index1: act. position in str_buf */
/* index2: act. position in str_mod */

#define R_NL   "<nl>"   /* mod. char for EOL  <cr><lf>    */
#define R_TAB  "<tab>"  /* mod. char for 0x09 <tab>       */
#define R_CTLC "\\03"   /* mod. char for 0x03 ^C          */
#define R_NPR  '?'      /* mod. char for <not printable>  */
#define RESERVE 5       /* max. laenge der ersatz-strings */

static char help [BUF_256];
char *str_mod, *str_hlp;
size_t new_len;
int ii, jj;


/* init */
   memset (help, 0, sizeof (help));
   *index2 = 0;   /* not defined */
   *error  = 0;
   new_len = 1;   /* for safety reasons */

/* copy old string, replace special chars */
   for (ii = 0          , jj = 0        , str_mod = help ;
        ;  /* abbruch durch abfrage am ende der schleife */
        ii++ , str_buf++, jj += new_len , str_mod += new_len)
   {
      if (index1 == ii) *index2 = jj;  /* index2 is now defined */

      if (jj >= (BUF_256 - RESERVE))
      {
         err_message (STRING_TOO_LONG);
         *error = 1;
         break;  /* for safety reasons */
      }

      if (perform_test_eol (str_buf, 0))
      {
      /* <cr>/<lf> */
         new_len = strlen (R_NL);
         memcpy (str_mod, R_NL, new_len);
         if (EOLN_LEN_2)
         {
            ii++;         /* 1 incr. */
            str_buf++;    /* das 2. incr in der for-loop */
         }
      }
      else
      {
         switch (*str_buf)
         {
            case 0x09:   /* <tab> */
               new_len = strlen (R_TAB);
               memcpy (str_mod, R_TAB, new_len);
               break;

            case 0x03:   /* ^C */
               new_len = strlen (R_CTLC);
               memcpy (str_mod, R_CTLC, new_len);
               break;

            case '\0':   /* end of string */
               new_len  = 1;
               *str_mod = *str_buf;
               break;

            default:
               if ((mb_isprint  (*str_buf)) ||
                   ((*str_buf) & 0x80))
               {
                  new_len  = 1;
                  *str_mod = *str_buf;
               }
               else
               {
                  str_hlp = key_2_string ((int) *str_buf);
                  new_len = strlen (str_hlp);
                  if (new_len <= 1)
                  {                     /* not found in table */
                     new_len  = 1;
                     *str_mod = R_NPR;
                  }
                  else
                  {
                     memcpy (str_mod, str_hlp, new_len);
                  }
               }
               break;
         }  /* switch */
      }

      if (*str_buf == '\0') break;     /* end of string selbst included */

   }  /* for */

/* forced end of string */
   help [BUF_256 - 1] = '\0';

   return help;

}  /* build_modified_string */

/* -FF-  */

int get_line_2_string (char *text, char *str_buf,
                       int end_char, enum HIST_ID id)
{
int  key, key_1, last_key, help, str_len_1, first, justify, return_val;

#define TEXT_RESERVE 80         /* max. zulaessige strlen(text) */
#define EXTRA_CHARS   2         /* die beiden \" im format string */
#define TILDE_7E     '~'        /* 0x7e */

int index1, index2, error, sav_index = 0;
static char tmp_buf [BUF_256];  /* temp. buffer */
static char sav_buf [BUF_256];  /* fuer ^A, ^X, ^Z, ^U */
static char l_text  [BUF_256 + TEXT_RESERVE];

char *str_mod;            /* for display */
char *str_hlp;            /* for conversion of special keys (macro.c) */
int  len_hlp, byte_num;
char *hist_adr;

/* build text line */
   index1 = 0;
/* index2 = 0; */
   first = 0;

#if (WITH_MOUSE)
   MouSetMoveArea (  0, 0,
                   255, 0,
                     3);
#endif

#if (ACT_SERVER == SERVER_VT_100)
   text_area++;
#endif

/* after selecting a filename from a wildcard input, we do one more run */
   return_val = -1;
   while (return_val == -1)
   {

   /* take original buffer in temp */
      memcpy (tmp_buf, str_buf, sizeof(tmp_buf));

   /* laenge von "text" ueberpruefen */
      str_len_1 = strlen (text);
      if (str_len_1 >= (TEXT_RESERVE - 1 - EXTRA_CHARS))
      {
         err_message (STRING_TOO_LONG);
         text [0] = '\0';    /* clear text string */
      }

   /* get new string */
      last_key = 0;
      for (/* hier nicht: index1 = 0 !! */ ;
           index1 < (BUF_256 - 1) ;
           /* hier nicht: index1++ !! */)
      {
      /* display actual buffer */
         str_mod = build_modified_string (tmp_buf, index1, &index2, &error);
         if (error)   /* buffer overflow */
         {
            index1 = 0;               /* clear current string up to here */
            tmp_buf [index1] = '\0';
            continue;
         }

         sprintf (l_text, "%s\"%s\"", text, str_mod);

         if (index1 == 0)
            justify = 2;
         else
            justify = 0;

         show_status_line_2 (l_text, justify,
                             (str_len_1 + EXTRA_CHARS + index2), 0);

      /* get command */
         key = get_1_key (1);

      /* abort function ? */
         if (key == 0x03)               /* ^C                           */
         {
            return_val = 0;             /* invalid, don't use result    */
            break;
         }

      /* input finished ? */
         if (key == 0x1b)               /* <esc> */
         {
            break;                      /* take whole line */
         }

         if ((key == end_char) &&
             (end_char == C_R))          /* <cr> */
         {
            tmp_buf [index1] = '\0';     /* take line up to cursor position */
            break;
         }

      /* keep old string ? */
         if (first == 0)
         {
            first = 1;
            if ((key != KEY_HOME)  &&
#if (!STRICTLY_AEDIT_COMPATIBLE)
                (key != KEY_END)   &&
#endif
                (key != KEY_LEFT)  &&
                (key != KEY_RIGHT) &&
                (key != KEY_UP)    &&
                (key != KEY_DOWN)  &&
                (key != KEY_DEL)   &&
                (key != KEY_DO_NOTHING) &&
#if (ACT_OP_SYSTEM == SCO_UNIX)
                (key != KEY_RUBOUT) &&        /* rubout */
#endif
                (key != 0x08))                /* <backspace> */
            {
               tmp_buf [0] = '\0';            /* delete old string */
               tmp_buf [1] = '\0';
            }
         }

      /* handle inputs */
         if ((key >= 0) &&
             (mb_isprint (key) || (key & 0x80)))
         {
            if ((key == TILDE_7E) && (set.tilde_home))
            {
               set_string_buff (HOME_DIR, strlen (HOME_DIR));
            }
            else
            {
               help = strlen (tmp_buf) - index1 + 1;
               memcpy_rev ((char FA_HU *)(&tmp_buf[index1+1]),
                           (char FA_HU *) &tmp_buf[index1],
                           (long)         help);
               tmp_buf [index1] = (char) key;
               index1++;
            }
         }
         else
         {
            switch (key)
            {
               case KEY_UP:
               case KEY_DOWN:
                  if ((hist_adr = get_history_buffer (id)) != NULL)
                  {
                     memcpy (tmp_buf, hist_adr, BUF_256);

                  /* forced end of string */
                     tmp_buf [BUF_256 - 1] = '\0';
                     index1 = strlen (tmp_buf);
                  }

               /* clean space of history window */
#if 0
                  perform_view ();
#else
                  refresh_whole_screen ();
#endif
                  break;

               case KEY_LEFT:
                  last_key = 1;
                  byte_num = 1;
                  if (EOLN_LEN_2)
                  {
                     if (perform_test_eol (&tmp_buf[index1], -2))
                        byte_num = 2;
                  }
                  if (index1 > (byte_num - 1))
                     index1 -= byte_num;
                  break;

               case KEY_RIGHT:
                  last_key = 2;
                  byte_num = 1;
                  if (EOLN_LEN_2)
                  {
                     if (perform_test_eol (&tmp_buf[index1], 0))
                        byte_num = 2;
                  }
                  if (index1 < ((int) strlen(tmp_buf) - byte_num + 1))
                     index1 += byte_num;
                  break;

#if (STRICTLY_AEDIT_COMPATIBLE)
               case KEY_HOME:
                  switch (last_key)
                  {
                     case 1 : index1 = 0;               break;
                     case 2 : index1 = strlen(tmp_buf); break;
                     default:                           break;
                  }
                  break;
#else
               case KEY_HOME:
                  index1 = 0;
                  break;

               case KEY_END:
                  index1 = strlen(tmp_buf);
                  break;
#endif

               case 0x04:          /* ^D    */
                  if (index1 > 0)
                  {
                     index1--;
                     comm_umlaut (&tmp_buf [index1]);
                     index1++;
                  }
                  break;

               case 0x08:          /* backspace */
#if (ACT_OP_SYSTEM != SCO_UNIX)
               case KEY_RUBOUT:    /* rubout */
#endif
                  byte_num = 1;
                  if (EOLN_LEN_2)
                  {
                     if (perform_test_eol (&tmp_buf[index1], -2))
                        byte_num = 2;
                  }
                  if (index1 > (byte_num - 1))
                  {
                     help = strlen (tmp_buf) - index1 + 1;
                     index1 -= byte_num;
                     memcpy ((&tmp_buf[index1]), &tmp_buf[index1+byte_num], help);
                  }
                  break;

               case 0x06:          /* ^F */
               case KEY_DEL:       /* delete */
#if (ACT_OP_SYSTEM == SCO_UNIX)
               case KEY_RUBOUT:    /* rubout */
#endif
                  byte_num = 1;
                  if (EOLN_LEN_2)
                  {
                     if (perform_test_eol (&tmp_buf[index1], 0))
                        byte_num = 2;
                  }
                  help = strlen (tmp_buf) - index1 - (byte_num - 1);
                  memcpy ((&tmp_buf[index1]), &tmp_buf[index1+byte_num], help);
                  break;

               case 0x18:          /* ^X */
                  memcpy (sav_buf, tmp_buf, BUF_256);
                  sav_index = index1;

                  help = strlen (tmp_buf) - index1 + 1;
                  memcpy ((&tmp_buf[0]), &tmp_buf[index1], help);
                  index1 = 0;
                  break;

               case 0x01:          /* ^A */
                  memcpy (sav_buf, tmp_buf, BUF_256);
                  sav_index = index1;

                  tmp_buf [index1] = '\0';
                  break;

               case 0x1a:          /* ^Z */
                  memcpy (sav_buf, tmp_buf, BUF_256);
                  sav_index = index1;

                  index1 = 0;
                  tmp_buf [index1] = '\0';
                  break;

               case 0x15:          /* ^U */
                  memcpy (tmp_buf, sav_buf, BUF_256);
                  index1 = sav_index;
                  break;

               case 0x0d0a:        /* <cr><lf> */
                  help = strlen (tmp_buf) - index1 + 1;
                  memcpy_rev ((char FA_HU *)(&tmp_buf[index1 + 2]),  /* 2 new */
                              (char FA_HU *) &tmp_buf[index1],
                              (long)         help);
                  tmp_buf [index1] = 0x0d;
                  index1++;
                  tmp_buf [index1] = 0x0a;
                  index1++;
                  break;

               case 0x09:          /* <tab> */
               case 0x0d:          /* <cr>  */
               case 0x0a:          /* <lf>  */
                  help = strlen (tmp_buf) - index1 + 1;
                  memcpy_rev ((char FA_HU *)(&tmp_buf[index1 + 1]),  /* 1 new */
                              (char FA_HU *) &tmp_buf[index1],
                              (long)         help);
                  tmp_buf [index1] = (char) key;
                  index1++;
                  break;

               case 0x12:          /* ^R */
                  key_1 = get_hex_value ();
                  if ((key_1 == TILDE_7E) && (set.tilde_home))
                  {
                     set_string_buff (HOME_DIR, strlen (HOME_DIR));
                  }
                  else
                  {
                     if (key_1 >= 0)
                     {
                        help = strlen (tmp_buf) - index1 + 1;
                        memcpy_rev ((char FA_HU *)(&tmp_buf[index1+1]),
                                    (char FA_HU *) &tmp_buf[index1],
                                    (long)         help);
                        tmp_buf [index1] = (char) key_1;
                        index1++;
                        if (EOLN_LEN_2)
                        {
                           if (perform_test_eol (&tmp_buf [index1], -1))
                              index1++;
                        }
                     }
                  }
                  break;

               case 0x0e:          /* ^N */
               case 0x13:          /* ^S */
               case 0x16:          /* ^V */
                  perform_special_keys (key, 0);
                  break;

               case KEY_DO_NOTHING:
               case SEQU_EM:          /* new ! 25.10.96 */
                  break;

               default:
                  str_hlp = key_2_string (key);
                  len_hlp = strlen (str_hlp);
                  if (len_hlp <= 1)
                  {
                     beep ();   /* not found in table */
                  }
                  else
                  {
                     block_insert ((char FA_HU *)tmp_buf, (long) index1,
                                   (long) strlen(tmp_buf),
                                   (long) BUF_256,  /* sizeof(tmp_buf) = 4 !! */
                                   (char FA_HU *)str_hlp, (long) len_hlp);
                     index1 += len_hlp;
                  }
                  break;
            }  /* switch key */
         }

      /* new end of string */
         help = strlen (tmp_buf);
         tmp_buf [help+1] = '\0';
      }  /* for index1 */

      if (return_val)
      {
      /* end of input or reached max. string length */

      /* copy temp buffer to original */
         memcpy (str_buf, tmp_buf, sizeof(tmp_buf));
         save_history_string (id, str_buf);

#if (!WILD_NAMES)
         return_val = 1;
#else
         if (id != ID_FILE)
         {
            return_val = 1;
         }
         else
         {
            if ((wildcard_filename (str_buf)) == 0)
               return_val = 1;

            index1 = strlen (str_buf);
         }
#endif
      }
   }  /* while */


/* exit function */

#if (WITH_MOUSE)
   MouSetMoveArea ( 0                , (byte) TOP_ROW,
                   (byte) (COLUMNS-1), (byte) MAX_ROW,
                    -1);
#endif

#if (ACT_SERVER == SERVER_VT_100)
   text_area--;
#endif

   return (return_val);
}  /* get_line_2_string */

/* -FF-  */

int get_hex_value (void)
{
/* ^R */
int value, ok_flag, ii, key_1 = 0;
int row, column;

   ok_flag = 1;

/* status line 1 missbrauchen */
   get_cursor_pos (&row, &column);
   show_status_line_1 (" <HEX> ", fc);
   set_cursor_to (row, column);

   value = 0;
   for (ii = 0 ; ii < 2 ; ii++)
   {
      key_1 = get_1_key (1);
      if (mb_isxdigit (key_1))
      {
         value *= 0x10;

         if (mb_isdigit (key_1))
            value += (key_1 - '0');                /* ziffer */
         else
            value += (toupper(key_1) - 'A' + 10);  /* buchstabe */
      }
      else
      {
         if (key_1 != 0x03)    /* ^C aborts without error */
            err_message (INVALID_HEX_VALUE);
         ok_flag = 0;
         break;
      }
   }

/* status line 1 restaurieren */
   get_cursor_pos (&row, &column);
   show_status_line_1 (fc->filename, fc);
   set_cursor_to (row, column);

   if (ok_flag)
   {
      return value;  /* o.k. */
   }
   else
   {
      if (key_1 == 0x03)
         return -3;   /* flag: ^C */
      else
         return -1;     /* error */
   }

}  /* get_hex_value */

/* -FF-  */


/*----------------------------------------------*/
/* subroutine for 'Calc': set error flag        */
/*----------------------------------------------*/

static void set_error (char *err_pos, int err_no)
  /* --  display message and echo expression up to error position */
{
/* dummy wg. compiler warnings */
   err_pos = err_pos;
   err_no  = err_no;

   return;
}  /* set_error */

/* -FF-  */

/*----------------------------------------------*/
/* Bei Insert/Exchange/get string : ^S/^V, ^N   */
/*----------------------------------------------*/

int perform_special_keys (int key_0, int mode_flag)
{
int key_1;
int ok_flag;
int row, column;

/* ^S/^V */
char *str_ptr = NULL;
size_t str_len = 0;

/* ^N */
long value;
CALC_RESULT calc_result;
char string [40];
int  temp_radix, ii, byte_1;


   ok_flag = 1;

   switch (key_0)
   {
      case 0x0e:   /* ^N */
      /* status line 1 missbrauchen */
         get_cursor_pos (&row, &column);
         show_status_line_1 (" <FETN> ", fc);
         set_cursor_to (row, column);

         key_1 = get_1_key (1);
         if (mb_isdigit (key_1))
         {
            sprintf (string, "n%c", key_1);
            evaluate (string, &calc_result, set_error);
            switch (calc_result.type)
            {
               case ERROR :
                  break;

               case VALUE :
                  value = calc_result.item.val;
                  if (mode_flag)
                  {                        /* insert / exchange */
                     temp_radix = set.radix;
                  }
                  else
                  {                        /* command */
                     temp_radix = 'D';
                     value = labs (value);
                  }

                  switch (temp_radix)
                  {
                     case 'A':
                        for (ii = 0 ; ii < 4 ; ii++)
                        {
                           byte_1 = (int) (value & 0xff);
                           if ((byte_1 == 0) && (ii > 0)) break;

                           if (mode_flag == 1)
                              perform_key_insert   (byte_1, 0);
                           else
                              perform_key_exchange (byte_1, 0);

                           value >>= 8;
                        }
                        fc->change_flag = 1;
                        return 1;

                     case 'B': ltoa (value, string,  2); break;
                     case 'D': ltoa (value, string, 10); break;
                     case 'H': ltoa (value, string, 16); break;
                     case 'O': ltoa (value, string,  8); break;

                     default:  break;
                  }
                  set_string_buff (string, strlen (string));
                  break;
            }
         }
         else
         {
            err_message (INVALID_VARIABLE_NAME);
            ok_flag = 0;
         }

      /* status line 1 restaurieren */
         get_cursor_pos (&row, &column);
         show_status_line_1 (get_line_1_text (), fc);
         set_cursor_to (row, column);

         break;


      case 0x13:   /* ^S */
      case 0x16:   /* ^V */
      /* status line 1 missbrauchen */
         get_cursor_pos (&row, &column);
         show_status_line_1 (" <FETS> ", fc);
         set_cursor_to (row, column);

         key_1 = get_1_key (1);
         key_1 = toupper (key_1);
         switch (key_1)
         {
            case 'B':    /* Block Buffer */
               str_ptr = get_save_buffer ();    /* in blocks.c */
               str_len = (size_t) (min (get_save_length (), (BUF_256 - 1)));
               break;

            case 'E':    /* Edit <filename> */
               str_ptr = fc->filename;
               str_len = strlen (str_ptr);
               break;

            case 'G':    /* Get <filename> */
               str_ptr = str_getf;
               str_len = strlen (str_ptr);
               break;

            case 'I':    /* Input <filename> */
               str_ptr = file_control [0].filename;
               str_len = strlen (str_ptr);
               break;

            case 'M':    /* Macro <filename> */
               str_ptr = get_macro_filename ();    /* in macro.c */
               str_len = strlen (str_ptr);
               break;

            case 'O':    /* Other <filename> */
               str_ptr = file_control [1].filename;
               str_len = strlen (str_ptr);
               break;

            case 'P':    /* Put <filename> */
               str_ptr = str_putf;
               str_len = strlen (str_ptr);
               break;

            case 'R':    /* Replace String */
               str_ptr = str_repl;
               str_len = strlen (str_ptr);
               break;

            case 'T':    /* Find String (T, nicht F !!, wieso eigentlich ?) */
               str_ptr = str_find;
               str_len = strlen (str_ptr);
               break;

            case 'W':    /* Write <filename> */
               str_ptr = str_q_wr;
               str_len = strlen (str_ptr);
               break;

            case 'Y':    /* sYntax highlighting ("mbedit.syn") */
               str_ptr = str_synt;
               str_len = strlen (str_ptr);
               break;

            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
               sprintf (string, "s%c", key_1);
               evaluate (string, &calc_result, set_error);
               switch (calc_result.type)
               {
                  case ERROR :
                     break;

                  case STRING :
                     str_ptr = calc_result.item.str;
                     str_len = strlen (str_ptr);
                     break;
               }
               break;

            default:
               str_ptr = "";
               str_len = 0;
               err_message (INVALID_VARIABLE_NAME);
               ok_flag = 0;
               break;
         }
         set_string_buff (str_ptr, str_len);

      /* status line 1 restaurieren */
         get_cursor_pos (&row, &column);
         show_status_line_1 (get_line_1_text (), fc);
         set_cursor_to (row, column);

         break;

      default:     /* do nothing */
         break;
   }

   return ok_flag;
}  /* perform_special_keys */

/* -FF-  */

/***************************************************************/
/* optimize screen output for speed                            */
/***************************************************************/

void clear_text_buffers (void)
{
/* aufruf von perform_view () */

#if (OUTPUT_OPTIMIZED)
   memset (text_buff, 0, sizeof (text_buff));
   memset (attr_buff, 0, sizeof (attr_buff));
#endif

   return;
}  /* clear_text_buffers */



static void optimize_output (int row, int column,
                             char *text, byte *attr,
                             int attr_mode, int show_cursor)
{
int ii, imax, rest_blanks;

#if (OUTPUT_OPTIMIZED)
int i1, i2, found, new_len, old_len, set_flag, clr_flag;
#define index row
#endif

static byte attribute;
static int attr_save;                           /* bugfix 1 - 06.08.02 */

/* attr_mode = 0 : do nothing        */
/*           = 1 : init attribute    */
/*           = 2 : ignore attributes */
   if (attr_mode)
   {
       attr_save = attr_mode;
       attribute = 0;
   }
   else
   {
           attribute &= ~(BEG_KEYWORD | BEG_STRING);    /* switch OFF some attributes */
   }

/* convert attr from slope indication to static flags */
   imax = strlen(text);

   for (ii = 0 ; ii <= imax ; ii++)
   {
#if 0
   /* reset with upper 4 bits */
      attribute &= ~((attr[ii] & 0xf0) >> 4);

   /* set with lower 4 bits */ /* sequence of set/reset exchanged, 15.03.95 */
      attribute |= (attr[ii] & 0x0f);
#else

#if 0
   /* reset / set status bits */    /* modified, 29.03.95 */
      attribute &= ~((attr[ii] & 0x30) >> 4);
      attribute |=  ( attr[ii] & 0x07);
      attribute &= ~((attr[ii] & 0x40) >> 4);
#else
   /* reset / set status bits */    /* modified, 30.04.03 */
      attribute |=  ( attr[ii] & 0x0f);
      attribute &= ~((attr[ii] & 0xf0) >> 4);
#endif

#endif

   /* store back as static mode */
      attr[ii] = attribute;
   }


#if (OUTPUT_OPTIMIZED)
/* compare old / new text */
   old_len = strlen (text_buff [index]);
   new_len = strlen (text);

   i1 = 0;
   i2 = new_len-1;
   found = 0;

/* modified content of text line ? */
   for (ii = 0 ; ii < new_len ; ii++)
   {
      if ((text_buff [index][ii] != text [ii]) ||     /* text unequal ? or */
          (attr_buff [index][ii] != attr [ii]) ||     /* attr unequal ? or */
          (ii >= old_len))               /* new string longer than old one */
      {
         i2 = ii;                /* index of last difference */

         if (found == 0)
         {
            found = 1;
            i1 = ii;             /* index of first difference */
         }
      }
   }  /* for ii */


/* found any difference ? */
   if (found)
   {                                         /* yes */
   /* move cursor to begin of modified area */
      set_cursor_to (row, (column + i1));

   /* save new string in buffer */
      strncpy (text_buff [index], text, sizeof (text_buff [index]));
      memcpy  (attr_buff [index], attr, sizeof (attr_buff [index]));

   /* set end of string */
      text [i2+1] = '\0';

   /* string output */
      out_string_attr (&text [i1], &attr [i1], attr_save);
      attr_save = attr_mode;

   /* restore end of string */
      text [i2+1] = text_buff [index][i2+1];
   }


/* save new end of string */
   text_buff [index][new_len] = '\0';


/* line not completely full ? */
   if ((new_len + column) < COLUMNS)
   {

   /* is cursor already at end of new text ? */
      set_flag = 0;
      if (((i2+1) != new_len) ||
          (!found))
         set_flag = 1;

   /* clear rest of line ? */
      clr_flag = 0;
      if ((new_len < old_len) ||
          (old_len == 0))
         clr_flag = 1;

   /* do it */
      if (set_flag && (show_cursor || clr_flag))
         set_cursor_to (row, (new_len + column));   /* cursor behind string */

      if (clr_flag)
      {
         rest_blanks = COLUMNS - (new_len + column) /* - (row >= ROWS-1) */ ;
         clear_to_eol (rest_blanks);
      }
   }

   return;

/* -FF-  */

#else      /* normal output, without optimize */

   show_cursor;  /* wg. compiler warnings */

   set_cursor_to (row, column);

#if (CLEAR_TO_EOL_BEFORE)
   rest_blanks = COLUMNS - column;
   if (rest_blanks)
      clear_to_eol (rest_blanks);
#endif

   out_string_attr (text, attr, attr_mode);

#if (!CLEAR_TO_EOL_BEFORE)
   rest_blanks = COLUMNS - ((int) strlen (text) + column) /* - (row >= ROWS-1)*/ ;
   if (rest_blanks)
      clear_to_eol (rest_blanks);
#endif

   return;

#endif

}   /* optimize_output */

/* -FF-  */

static int out_string_attr (char *text, byte *attr, int attr_mode)
{
/* string output with partial invers / colored text */
/* 0  ...   BEG_INVERS ... END_INVERS ... EOL */
/* | normal |   invers     |   normal     |   */

int  ii, imax;
byte loc_attr;
static byte old_attr;

/* attr_mode = 0 : do nothing        */
/*           = 1 : init attribute    */
/*           = 2 : ignore attributes */
   if (attr_mode)
      old_attr = 0;

/* does this line contain an invers / colored text ? */
   if (attr_mode == 2)
   {
      return out_string (text);
   }
   else
   {
      imax = strlen(text);

      for (ii = 0 ; ii <= imax ; ii++)
      {
      /* check for invers text, comments + keywords */
         loc_attr = attr[ii];

      /* any modifications ? */
         if (loc_attr != old_attr)
         {
         /* now which bits are set ? */
            if      (loc_attr & BEG_INVERS ) set_invers_mode  ();
#if (WITH_SYNTAX_HIGHLIGHTING)
            else if (loc_attr & BEG_COMMENT) set_comment_mode ();
            else if (loc_attr & BEG_KEYWORD) set_keyword_mode ();
            else if (loc_attr & BEG_STRING)  set_string_mode  ();
#endif
            else                             set_normal_mode  ();
         }
         old_attr = loc_attr;


      /* show 1 text character */
         if (ii < imax)
            out_1_char (text[ii], 0);
      }  /* for ii */

      return imax;
   }
}  /* out_string_attr */

/* -FF-  */

void refresh_display_window (int top, int left, int bot, int right)
{

#if (OUTPUT_OPTIMIZED)

int ii, jj;

/* loop for lines */
   for (ii = top ; ii <= bot ; ii++)
   {
   /* loop for columns */
      left = min (left, (int) strlen (text_buff [ii]));
      for (jj = left ; jj <= right ; jj++)
      {
         text_buff [ii][jj] = 0xff;   /* set to invalid */
         attr_buff [ii][jj] = 0x00;   /* set to default */
      }
   }

#else

   top;    /* wg. compiler warnings */
   left;
   bot;
   right;

#endif

   return;

}  /* refresh_display_window */

/* -FF-  */

void show_find_result (char *string, int find_count, int replace_count)
{
STATIC char line [BUF_256 + TEXT_RESERVE];
int  dummy;

   if (find_count == 0)
   {
      sprintf (line, "not found: \"%s\"",
                      build_modified_string (string, 0, &dummy, &dummy));
   }
   else
   {
      if (replace_count < 0)
         sprintf (line, "found: %d", find_count);
      else
         sprintf (line, "found: %d   replaced: %d",
                         find_count, replace_count);
   }
   line_2_flag = 2;
   show_status_line_2 (line, 1, -2, 0);

   return;
}  /* show_find_result */

/* -FF-  */

int show_find_display (int command, int all_flag, int lf_strings,
                       int first_call, int last_call, int find_ok)
{
static int local_row;
int ii, abort;
char empty_line [3];

/* reset abort flag */
   abort = 0;

/* first call ? */
   if (first_call)
      local_row = 0;

/* display full screen ? */
   if (((command == '?') && (!all_flag)) ||    /* ?Replace or */
       (last_call && first_call))              /* single call */
   {
      if (get_video_active (0))
         set_cursor_to (fc->lrow, fc->column);

      switch (toupper (command))
      {
         case 'F':      /* Find */
            if (fc->lrow >= MAX_ROW)
               perform_view ();
            else
               if (set.wildcards)
                  update_entire_window (fc->top_left);
            break;

         case '-':      /* -Find */
            if (fc->lrow <= MIN_ROW)
               perform_view ();
            else
               if (set.wildcards)
                  update_entire_window (fc->top_left);
            break;

         case '?':      /* ?Replace */
            show_status_line_1 (get_line_1_text (), fc);
            /* fall through */

         case 'R':      /* Replace */
            if ((lf_strings) || (set.wildcards))
               update_entire_window (fc->top_left);
            else
               update_this_line (fc->lin_left, fc->lrow);

            if (fc->lrow >= MAX_ROW)
               perform_view ();
            else
               perform_update (fc->buff_0, fc->byte_anz,
                               fc->left_col);
            break;

         default:
            break;
      }
   }
   else
   {
      if (set.showfind)
      {
      /* clear screen ? */
         if (local_row == 0)
         {
            for (ii = 0 ; ii <= (ROWS - STATUS_LINES - 1) ; ii++)
            {
               if (EOLN_LEN_1)
               {
                  empty_line [0] = (char)EOLN;
                  empty_line [1] = '\0';
               }
               else
               {
                  empty_line [0] = EOLN_HIGH;
                  empty_line [1] = EOLN_LOW;
                  empty_line [2] = '\0';
               }
               disp_1_line (empty_line, 0L, (long) COLUMNS, ii, 0, 0);
            }
         }

      /* show 1 line */
         if (find_ok)
         {
            disp_1_line (fc->buff_0, fc->lin_left, fc->byte_anz,
                         local_row, fc->left_col, 0);
            local_row++;
         }

      /* wait for user reaction */
         if ((local_row > MAX_ROW) ||
             ((local_row > 0) && last_call))
         {
            local_row = 0;
            show_status_line_1 (get_line_1_text (), fc);   /* NEU @@ 07.06.94 */

            if (get_hit_any_key () == 0x03)     /* ^C */
               abort = 1;
            else
               show_status_line_2 ("searching ...", 0, -2, 0);
         }
      }

      if (last_call)
      {
         view_or_update ();
      }
   }

   return abort;

}  /* show_find_display */

/* -FF-  */

int get_hit_any_key (void)
{
/* force display, even in macro execute */
   set.display |= 0x02;

   show_status_line_2 ("hit any key to continue", 0, -1, 1);
   line_2_flag = 1;

/* restore display mode */
   set.display &= ~0x02;

   return get_1_key (0);

}  /* get_hit_any_key */

/* -FF-  */

#if (WITH_HEX_VIEW)

#define START_ROW (MIN_ROW + 1)
#define HEX_ROWS  (MAX_ROW - MIN_ROW)
#define HEX_BYTES (HEX_ROWS << 4)

#define LINE_LEN INIT_COLUMNS
static char line [LINE_LEN+1];
static long start_ind;

void hex_one_line (long i1, long i2)
{
long ii;
int ind;
byte char1;


/* clear line */
   memset (line, ' ', LINE_LEN);
   line [LINE_LEN] = '\0';     /* end of string */

/* before end of file ? */
   if (i1 < i2)
   {
   /* adress */
      sprintf (&line[1], "%06lX", i1);
      line [7] = ' ';

   /* data */
      for (ii = i1 ; ii < min (i2, i1+16) ; ii++)
      {
      /* hex data */
         ind = (int) (10 + 3*(ii-i1) + ((ii-i1) >> 2));
         sprintf (&line[ind], "%02X", (((byte) fc->buff_0 [ii]) & 0xff));
         line [ind+2] = ' ';

      /* ascii data */
         ind = (int) (63 + ii-i1);
         char1 = (byte) (fc->buff_0 [ii] & 0xff);
         if ((char1 >= 0x20) &&
             (char1 != 0x7f))
            line [ind] = (char) fc->buff_0 [ii];
         else
            line [ind] = '_';
      }
   }

/* forced limitation of line */
   if (COLUMNS < LINE_LEN)
   {
      line [COLUMNS-1] = '!';
      line [COLUMNS]   = '\0';
   }

#if (CLEAR_TO_EOL_BEFORE)
   if (COLUMNS > 0)
      clear_to_eol (COLUMNS);
#endif

/* show line */
   out_string (line);

#if (!CLEAR_TO_EOL_BEFORE)
   if (COLUMNS > LINE_LEN)
      clear_to_eol (COLUMNS - LINE_LEN);
#endif

   return;
}  /* hex_one_line */


void hex_one_screen (long i1, long i2)
{
int row;

   push_cursor ();

/* headline */
   set_cursor_to (MIN_ROW, 0);
   set_invers_mode ();
/*               " 000000   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   0000000000000000 " */
   sprintf (line," Adress   ----------------------Hex Data--------------------   ---ASCII Data--- ");

/* forced limitation of line */
   if (COLUMNS < LINE_LEN)
   {
      line [COLUMNS-1] = '!';
      line [COLUMNS]   = '\0';
   }

#if (CLEAR_TO_EOL_BEFORE)
   if (COLUMNS > 0)
      clear_to_eol (COLUMNS);
#endif

   out_string (line);
   set_normal_mode ();

#if (!CLEAR_TO_EOL_BEFORE)
   if (COLUMNS > LINE_LEN)
      clear_to_eol (COLUMNS - LINE_LEN);
#endif

/* loop for lines */
   for (row = START_ROW ; row <= MAX_ROW ; row++)
   {
      set_cursor_to (row, 0);
      hex_one_line (i1 + ((row - START_ROW) << 4), i2);
#if (DISPLAY_PAUSE)
      fflush(stdout);           /* NEW ! 19.04.03 */
#endif
   }  /* for row */

   pop_cursor ();

#if (DISPLAY_PAUSE)
   fflush(stdout);              /* NEW ! 17.10.02 */
   sleep_msec(DISPLAY_PAUSE);   /* avoid, that display hangs */
#endif

   return;
}  /* hex_one_screen */

/* -FF-  */

void hex_view (void)
{
int key;
long old_start_ind;

#if (WITH_MOUSE)
   MouSetMoveArea (  0,   0,
                   255, 255,
                     4);
#endif

back_again:
   mode_flag = 3;
   line_2_flag = 1;

/* get actual cursor position */
   start_ind = fc->byte_index;
   old_start_ind = -1;

   for (;;)
   {
      if (line_2_flag == 1)
         show_status_line_2 (mode_text [mode_flag], 0, -2, 0);

      if (line_2_flag >= 1)
         line_2_flag--;


      push_cursor ();

   /* check limits */
      start_ind = min (start_ind, fc->byte_anz - HEX_BYTES);
      start_ind = max (start_ind, 0L);

   /* display status line 1 */
      if (!key_pressed())
      {
         perform_move (start_ind);
         show_status_line_1 (get_line_1_text (), fc);

      /* display screen new, if modified */
         if (start_ind != old_start_ind)
            hex_one_screen (start_ind, fc->byte_anz);
         old_start_ind = start_ind;

      /* cursor to position action_flag */
         set_cursor_to ((BOT_ROW - 1), 0);
      }
      pop_cursor ();

   /* get new command */
      key = toupper (get_1_key (1));
      switch (key)
      {
         case KEY_UP:
            start_ind -= 16;
            break;

         case KEY_DOWN:
            start_ind += 16;
            break;

         case KEY_RIGHT:
            start_ind++;
            break;

         case KEY_LEFT:
            start_ind--;
            break;

         case KEY_PGUP:
            start_ind -= HEX_BYTES;
            break;

         case KEY_PGDN:
            start_ind += HEX_BYTES;
            break;

         case KEY_HOME:
            start_ind = 0L;
            break;

         case KEY_END:
            start_ind = fc->byte_anz;
            break;

         case KEY_DO_NOTHING:
            break;

         default:
            beep ();
            break;

         case 0x1b:       /* <esc> */
         case 0x03:       /* ^C    */
            mode_flag = 0;
            perform_move (start_ind);
#if (WITH_MOUSE)
            MouSetMoveArea ( 0                , (byte) TOP_ROW,
                            (byte) (COLUMNS-1), (byte) MAX_ROW,
                             -1);
#endif
            line_2_flag = 1;  /* bugfix 25.09.99 */
            return;       /* abort loop */
            break;

         case 'E':
            if (fc->view_only)
               err_message(VIEW_ONLY);
            else
               hex_edit ();
            goto back_again;
            break;

         case 'O':
         /* get other work buffer */
            get_next_file_buffer (1);
            start_ind = fc->byte_index;
            old_start_ind = -1;
            break;

         case ALT_O:
         /* get other work buffer */
            get_next_file_buffer (-1);
            start_ind = fc->byte_index;
            old_start_ind = -1;
            break;

         case 'Y':    /* File Compare A/B */
            perform_file_compare ();
            line_2_flag = 2;
            start_ind = fc->byte_index;
            old_start_ind = -1;
            break;
      }  /* switch (key) */
   }  /* for (;;) */
}  /* hex_view */

/* -FF-  */

void hex_edit (void)
{
int key, key1, key2, char_modified;
long old_start_ind, act_ind;
int nibble;    /* 0 = left (MSN), 1 = right (LSN) */
int side;      /* 0 = hex side  , 1 = ASCII side  */
int delt_ind;  /* = act_ind-start_ind */
int help_ind;  /* = delt_ind & 0x0f */
int row = 0, col;  /* = f (delt_ind, nibble, side) */
byte value;

#if (WITH_MOUSE)
   MouSetMoveArea (  0,   0,
                   255, 255,
                     5);
#endif

   mode_flag = 4;
   show_status_line_2 (mode_text [mode_flag], 0, -2, 0);

/* get actual cursor position */
   start_ind = fc->byte_index;
   act_ind   = fc->byte_index;
   nibble    = 0;
   side      = 0;
   char_modified = 0;
   old_start_ind = -1;

   for (;;)
   {
      push_cursor ();

   /* check limits */
      start_ind = min (start_ind, fc->byte_anz - HEX_BYTES);
      start_ind = max (start_ind, 0L);

      act_ind = min (act_ind, fc->byte_anz-1);
      act_ind = max (act_ind, 0L);


   /* display status line 1 */
      if (char_modified)
      {
         fc->line_anz = get_total_lines (fc->buff_0, 0L, fc->byte_anz);
         init_file_control (fc, 0);
      }

      if (!key_pressed())
      {
         perform_move (act_ind);
         show_status_line_1 (get_line_1_text (), fc);

      /* display screen new, if modified */
#if 0
      /* das geht immer, ist aber zu langsam */
         hex_one_screen (start_ind, fc->byte_anz);
#else
         if (start_ind != old_start_ind)
         {
            hex_one_screen (start_ind, fc->byte_anz);
         }
         else
         {
            if (char_modified)
            {
               set_cursor_to (row, 0);
               hex_one_line (start_ind + ((row - START_ROW) << 4), fc->byte_anz);
            }
            char_modified = 0;
         }
#endif

         old_start_ind = start_ind;

      /* cursor to act_ind position */
         delt_ind = (int)(act_ind - start_ind);
         row = START_ROW + (delt_ind >> 4);

         help_ind = delt_ind & 0x0f;
         if (side)
            col = 63 + help_ind;                                 /* ASCII side */
         else
            col = 10 + 3*help_ind + (help_ind >> 2) + nibble;    /* hex side */
         set_cursor_to (row, col);
      }
      pop_cursor ();

   /* get new command */
      key1 = get_1_key (1);
      key = toupper (key1);
      switch (key)
      {
         case KEY_UP:
            act_ind -= 16;
            if (act_ind < start_ind)
               start_ind -= 16;
            break;

         case KEY_DOWN:
            act_ind += 16;
            if (act_ind >= start_ind + HEX_BYTES)
               start_ind += 16;
            break;

         case KEY_DO_NOTHING:
            break;

         default:
            if (side)                                      /* ASCII side */
            {
               if (valid_char (key1))
               {
                  fc->buff_0 [act_ind] = (char) key1;
                  fc->change_flag = 1;
                  char_modified   = 1;
               }
               else
               {
                  beep ();
                  break;
               }
            }
            else                                           /* hex side */
            {
               if (mb_isxdigit(key))
               {
                  value = fc->buff_0 [act_ind];   /* read old char */

               /* simple ASCII --> hex conversion */
                  if (key <= '9')
                     key2 = key - '0';
                  else
                     key2 = key - 'A' + 10;

                  if (nibble)                     /* set correct nibble */
                     value = (byte)((value & 0xf0) +  key2);        /* MSN */
                  else
                     value = (byte)((value & 0x0f) + (key2 << 4));  /* LSN */

                  fc->buff_0 [act_ind] = value;   /* write back new char */
                  fc->change_flag = 1;
                  char_modified   = 1;
               }
               else
               {
                  beep ();
                  break;
               }
            }
            /* fall through */

         case KEY_RIGHT:
            if (!side)
               nibble = (nibble + 1) & 0x01;

            if (act_ind >= fc->byte_anz-1)
               nibble = 1;

            if (side || !nibble)
            {
               act_ind++;
               if (act_ind >= start_ind + HEX_BYTES)
                  start_ind += 16;
            }
            break;

         case KEY_LEFT:
            if (!side)
               nibble = (nibble + 1) & 0x01;

            if (act_ind <= 0L)
               nibble = 0;

            if (side || nibble)
            {
               act_ind--;
               if (act_ind < start_ind)
                  start_ind -= 16;
            }
            break;

         case KEY_PGUP:
            start_ind -= HEX_BYTES;
            act_ind   -= HEX_BYTES;
            break;

         case KEY_PGDN:
            start_ind += HEX_BYTES;
            act_ind   += HEX_BYTES;
            break;

         case KEY_HOME:
            start_ind = 0L;
            act_ind   = 0L;
            break;

         case KEY_END:
            start_ind = fc->byte_anz;
            act_ind   = fc->byte_anz;
            break;

         case 0x09:       /* <tab> */
            side = (side + 1) & 0x01;
            nibble = 0;
            break;

         case 0x1b:       /* <esc> */
         case 0x03:       /* ^C    */
            mode_flag = 0;
            perform_move (act_ind);    /* start_ind also possible */
#if (WITH_MOUSE)
            MouSetMoveArea ( 0                , (byte) TOP_ROW,
                            (byte) (COLUMNS-1), (byte) MAX_ROW,
                             -1);
#endif
            return;       /* abort loop */
            break;
      }  /* switch (key) */
   }  /* for (;;) */
}  /* hex_edit */

/* -FF-  */

void hex_refresh_disp (void)
{
   hex_one_screen (start_ind, fc->byte_anz);
   return;
}  /* hex_refresh_disp */

#endif

/* -FF-  */

/* Modification History */
/* 23.11.92 - file erzeugt */
/* 24.11.92 - out_string () */
/* 27.11.92 - show_status_line_1 (), .._2 () aufgemotzt */
/* 28.11.92 - ausgabe speed-optimiert */
/* 29.11.92 - fehler in update_entire_screen () behoben */
/* 30.11.92 - get_line_2_string () */
/* 03.12.92 - show_status_line_1 () mit file_no */
/* 04.12.92 - get_line_2_string () : unterscheidung zwischen <esc> und <cr>. */
/* 04.12.92 - get_line_2_repeat () */
/* 07.12.92 - int get_line_2_string (); <F1> aborts; return value is valid flag */
/* 21.12.92 - EOL */
/* 05.01.93 - Umsetzung von CTRL_keys in '\'-sequenzen (macro.c) */
/* 24.03.93 - ^N: bei command mode: labs (value) */
/* 25.03.93 - show_find_display (..., find_ok) */
/* 18.06.93 - set_status_mode () */
/* 27.07.93 - status_line_1 (): A=filename (vorher A:filename) */
/* 01.08.93 - EOL --> EOLN */
/* 27.08.93 - eof_flag */
/* 28.08.93 - STATIC */
/* 30.08.93 - bypassed bug in DEC Ultrix compiler: n = sprintf(...) */
/* 09.09.93 - out_string_inv () */
/* 12.09.93 - get_video_active (ignore_batch) */
/* 12.09.93 - show_status_line_2 (..., ignore_batch) */
/* 14.09.93 - get_line_2_repeat: check for plausibility */
/* 14.09.93 - disp_status_line_1: fc->line_anz+1 */
/* 29.09.93 - update_rest_of_window(), ...entire_window() */
/* 30.09.93 - WINDOW_COMMAND */
/* 04.10.93 - refresh_whole_screen(), reihenfolge geaendert */
/* 10.10.93 - bugfix: S*Y, Find: "??" in zeilenende (mit 0x0d, ohne 0x0a) */
/* 19.10.93 - handling of single <lf>s */
/* 05.11.93 - LINE_1_DEBUG */
/* 06.11.93 - wildcard_filename */
/* 25.11.93 - Anzeige des '!' am Zeilenende um 1 spalte verschoben */
/* 27.11.93 - cr_flag: Anzeige des '!' bei <cr> am Zeilenende unterdrueckt */
/* 11.12.93 - VERSION_TEXT_1, _2, _3 */
/* 13.12.93 - get_line_2_string: with mouse control */
/* 15.12.93 - get_line_2_string: KEY_DO_NOTHING */
/* 15.12.93 - build_modified_string (..., int *error) */
/* 20.12.93 - text_area */
/* 19.02.94 - show_status_line_2 (): 1. char mit aktueller farbe setzen */
/* 10.05.94 - #include "microsft.h" */
/* 16.05.94 - VERSION_SCO, KEY_RUBOUT */
/* 17.05.94 - Unterscheidung UNIX-Varianten */
/* 17.05.94 - VERSION_SCO, KEY_RUBOUT does not kill defaults, HDS */
/* 20.05.94 - show_action_flag () */
/* 25.05.94 - update_entire_window (): kein min und max mehr */
/* 03.06.94 - limitation of status lines in length */
/* 07.06.94 - push_status_line_2 (), pop_status_line_2 () */
/* 07.06.94 - show_find_display (): show_status_line_1 for each page */
/* 29.06.94 - set.tilde_home */
/* 11.07.94 - TILDE --> TILDE_7E */
/* 21.09.94 - WITH_HEX_VIEW: hex_view () */
/* 22.09.94 - WITH_HEX_VIEW: hex_edit () */
/* 23.09.94 - perform_move (0L); --> init_file_control (fc, 0); */
/* 25.09.94 - hex_view (), hex_edit (): init_file_control (fc, 0) nur, */
/*                                      wenn char_modified */
/* 26.09.94 - hex_refresh_disp() */
/* 27.09.94 - hex_edit returns act_ind instead of start_ind */
/* 27.09.94 - type cast(s) wg. compiler warnings (microsoft c 6.0) */
/* 27.09.94 - WITH_SYNTAX_HIGHLIGHTING (begin of tests) */
/* 29.09.94 - WITH_SYNTAX_HIGHLIGHTING (implementation of comments) */
/* 30.09.94 - bugfix: invers find string */
/* 05.10.94 - detect keyword at EOF */
/* 14.10.94 - attr_flag entfaellt */
/* 14.10.94 - out_string_inv() --> out_string_attr() */
/* 21.02.95 - disp_1_line(): c++ style comments */
/* 26.02.95 - status line 2: <space>s until EOL */
/* 03.03.95 - hex_one_line(): clear_to_eol */
/* 09.03.95 - perform_update(): sequence of get_video_active/disp_memory */
/* 15.03.95 - bugfix: kommentar-ende und -anfang ohne zwischenraum */
/*            disp_1_line(): comment_count,                        */
/*            optimize_output(): sequence of set/reset exchanged   */
/* 29.03.95 - bugfix: optimize_output(): sequence of set/reset exchanged   */
/* 26.04.95 - hex_one_screen(): clear_to_eol() after headline */
/* 16.11.95 - bugfix WITH_SYNTAX_HIGHLIGHTING: */
/*            comments on lines with overlength */
/* 11.09.96 - hex_one_line(): 0x7f --> '_' */
/* 11.09.96 - perform_special_keys(): ^N: with Radix 'A': change_flag = 1 */
/* 25.10.96 - get_line_2_string(): case KEY_DO_NOTHING: or case SEQU_EM: */
/* 05.09.98 - EOLN_LEN_1 and EOLN_LEN_2: #if --> if */
/* 07.09.98 - EOLN_LEN_1: type cast --> (char) */
/* 31.07.98 - stoe: WITH_CPP_SYNTAX_HIGHLIGHTING cpp keywords added. */
/* 28.08.98 - stoe: WITH_CPP_SYNTAX_HIGHLIGHTING missing , added. */
/* 16.09.99 - 'H'ex 'View: 'O'ther */
/* 25.09.99 - 'H'ex 'View: bugfix line_2_flag */
/* 25.08.00 - comment_type static (bugfix by Raimund Spaeth) */
/* 06.08.02 - bugfix: OUTPUT_OPTIMIZED 1 --> 0 */
/* 17.10.02 - LINUX: DISPLAY_PAUSE 1 */
/* 29.03.03 - WITH_SYNTAX_HIGHLIGHTING: multi lamguage (file_type) support */
/* 30.03.03 - WITH_SYNTAX_HIGHLIGHTING: keywords with qsort */
/* 01.04.03 - WITH_SYNTAX_HIGHLIGHTING: more sphisticatec memory management */
/*            no limits any more (MAX_NUMBER_OF_FILETYPES, etc ...) */
/* 02.04.03 - bugfix: case hi_ligth_default[]: set num_file_types */
/* 04.04.03 - is_keyword(): bugfix malloc (num_keywords = 0) */
/* 24.04.03 - disp_1_line(): bugfix: overlapping start/end of comment */
/* 25.04.03 - is_comment_ml1(), is_comment_ml2(), is_comment_sl() */
/* 29.04.03 - get_line_2_string(): STRICTLY_AEDIT_COMPATIBLE 0 */
/* 30.04.03 - syntax highlighting for strings */
/* 30.04.03 - status_line_1 + _2 adapted to window size */
/* 01.05.03 - syntax highlighting for 'strings' with single quotes */
/* 07.05.03 - handle nested strings, e.g. "...'..." */
/* 10.05.03 - comment_fc (comment character 1st column, e.g. "C" for Fortran) */
/* 11.09.03 - bugfix: is_inside_comment_single() from start of line with <lf> */
/* 11.09.03 - disp_1_line(): no comments inside strings */
/* 28.10.03 - comment characters "//" replaced by "/*" */
/* 29.10.03 - show_status_line_2(): bugfix with extreme short/long lines */
/* 02.11.03 - Visual Basic uses single quote for comments, not strings */
/* 06.12.03 - mon_outp.c, kb_input.c: avoid_hanging_display() */
/* 07.12.03 - filenames without extension (e.g.: "makefile") */
/* 08.12.03 - filenames without extension, but leading pathname (e.g.: "./makefile") */
/* 14.02.04 - inside_keyword excludes comments and strings
   (e.g.: "$#" in shell scripts, the "#" doesn't mark the begin of a comment here) */
/* 14.02.04 - out_1_char (int key, int rectangle) */
/* 13.03.04 - modifications for CSS (dashes in keywords) */
/* 18.03.04 - bugfix comments inside strings */
/* 19.03.04 - disp_hnd.c: bugfix of previous bugfix */
/* 23.03.04 - disp_hnd.c: bugfix is_keyword (token isolated from delimiters) */
/* 24.03.04 - is_inside_string_or_comment(): backward direction and new line: handling like "first" */
