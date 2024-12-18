/*      mbedit.c                                  24.03.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 2004: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    editor main program
/
*/


/************************/
/*  include files       */
/************************/

#define _GLOBAL_
#include "config.h"
#include "global.h"
#include "standard.h"
#include "mbedit.h"
#include "calc_var.h"
#include "switches.h"
#include "perform.h"
#include "mbed_sub.h"
#include "commands.h"
#include "blocks.h"
#include "kb_input.h"
#include "mon_outp.h"
#include "memo_hnd.h"
#include "file_hnd.h"
#include "history.h"
#include "disp_hnd.h"
#include "macro.h"
#include "help_opt.h"
#include "err_mess.h"
#include "mb_ctype.h"
#include "mousec.h"
#include "vbios.h"
#include "ansi_out.h"


/************************/
/* some defines         */
/************************/

#if (DEMO_VERSION)
#include "demo/demo.h"
#endif

#define TEST_PRINT  0


/************************/
/* local structures     */
/************************/



/************************/
/*  module definitions  */
/************************/

static int mouse_moved;
static int mouse_status = 1;

#if WITH_MOUSE

static int mouse_driver_ok;

void set_mouse_moved (void)
{
   mouse_moved = 1;
   return;
}  /* set_mouse_moved */


void set_mouse_status (int stat)
{
   mouse_status = stat;
   return;
}  /* set_mouse_status */

#endif

/* -FF-  */

/* abspeichern des exe-filenames (bei MS_DOS, full path, sonst kommande.    */
/* falls der unbrauchbar ist (z.B. zu lang), wird der default-pfad benutzt. */

#define DEFAULT_PATH "."
static char save_path [BUF_256];


char *get_exe_path (void)
{
   return save_path;

}  /* get_exe_path */


void store_exe_path (char *pathname)
{
int ii, last_slash;
int name_len;

/* search last slash */
   last_slash = -1;  /* default: not found */

   name_len = strlen (pathname);
   if (name_len < sizeof (save_path))         /* not to long ? */
   {
      for (ii = name_len ; ii >= 0 ; ii--)    /* rueckwaerts */
      {
         if ((pathname[ii] == '/') ||     /* unix, os/9 */
             (pathname[ii] == '\\'))      /* ms/dos     */
         {
            last_slash = ii;
            break;
         }
      }
   }

   if (last_slash >= 0)                         /* found any slash ? */
   {
      strncpy (save_path, pathname, last_slash);
   }
   else
   {
      strcpy (save_path, DEFAULT_PATH);
   }

/* forced end of string */
   save_path [sizeof(save_path) - 1] = '\0';

   return;
}  /* store_exe_path */

/* -FF-  */

/*---------------------------------*/
/* exchange normal/other buffers   */
/*---------------------------------*/

void exchange_file_control (int file_num, int direction)
{
/* inkr. modulo */
   act_buff_no [act_window] = (act_buff_no [act_window] + file_num + direction)
                                                        % file_num;

   fc = &file_control [act_buff_no [act_window]];

   return;
}  /* exchange_file_control */

/* -FF-  */

/*---------------------------------*/
/* init structure for file control */
/*---------------------------------*/

void init_file_control (struct FILE_CONTROL *fcl, int clear_flag)
{
/* clear_flag = 0 : set to begin of file */
/*            = 1 : clear file buffer    */

   fcl->buffer        = fcl->buff_0;
   fcl->byte_index    = 0L;
   fcl->top_left      = 0L;
   fcl->lin_left      = 0L;

   fcl->line_index    = 0L;

   fcl->arow          = 0;  /* nicht MIN_ROW !! */
   fcl->column        = 0;


   if (clear_flag)
   {
      *fcl->buffer       = EOF;

      fcl->tag_index [0] = -1;
      fcl->tag_index [1] = -1;
      fcl->tag_index [2] = -1;
      fcl->tag_index [3] = -1;

      fcl->find [0]      = -1;
      fcl->find [1]      = -1;

      fcl->buff_no       = act_buff_no [act_window];

      fcl->byte_anz      = 0L;
      fcl->line_anz      = 0L;

      fcl->view_only     = 0;
      fcl->change_flag   = 0;

      fcl->e_delimit     = get_hi_light_delimiters(get_file_type(fc->filename));;
   }

   return;
}  /* init_file_control */

/* -FF- */

int get_next_file_buffer (int direction)
{
int init_flag;
struct FILE_CONTROL *next_fc;


/* get other work buffer */
   init_flag = 0;
   next_fc = &file_control
             [(act_buff_no [act_window] + set.file_num + direction)
                                        % set.file_num];

   if (next_fc->malloc_flag == 0)
   {
      next_fc->buff_0 = (char *)loc_malloc (INIT_FILESIZE);
      if (next_fc->buff_0 != NULL)
      {
         next_fc->malloc_flag = 1;
         next_fc->buffer_size = INIT_FILESIZE;
#if (VAR_EOLN)
         next_fc->eoln = EOLN_INIT;
#endif
         init_flag = 1;
      }
      else
      {
         err_message (OUT_OF_MEMORY);
      }
   }

/* exchange buffers */
   if (next_fc->malloc_flag == 1)
   {
      exchange_file_control (set.file_num, direction);
      if (init_flag)
         init_file_control (fc, 1);
      /* perform_view (); */
      return 1;    /* o.k. */
   }
   else
   {
      return -1;   /* error */
   }
}  /* get_next_file_buffer */

/* -FF- */

void set_highbit(void)
{
   if (get_file_type(fc->filename) > 0)
          fc->highbit = (set.highbit_global != 0);
   else
      fc->highbit = (set.highbit_global == 1);
}  /* set_highbit */

/* -FF- */

int get_1_datafile (void)
{
int ok_flag, file_type;
long file_length;

   ok_flag = 1;  /* default: o.k. */

/* check for read permission */
   if ((access (fc->filename, F_OK) == 0) &&
       (access (fc->filename, R_OK) != 0))
   {
      err_message (FILE_NOT_READABLE);
      fc->byte_anz = -1;
   }
   else
   {
#if (ACT_OP_SYSTEM != OS_9)
   /* Achtung ! Bei os-9 aendert "access(..,W_OK)" die Uhrzeit des Files */
   /* check for write permission */
      if ((access (fc->filename, F_OK) == 0) &&
          (access (fc->filename, W_OK) != 0))
      {
         fc->view_only = 1;
      }
#endif

   /* check buffer_size */
      file_length = get_file_length (fc->filename, fc->view_only);

      if (file_length >= 0)
      {
         if (fc->view_only)
            ok_flag = (check_and_increase_buffer (fc, file_length,
                                                  0L, 1) >= 0);
         else
            ok_flag = (check_and_increase_buffer (fc, file_length,
                                                  FILE_RESERVE, 1) >= 0);

      /* buffer large enough ? */
         if (ok_flag)
         {                /* read file */
            fc->byte_anz = read_datafile (fc->filename, fc->buff_0,
                                          file_length , fc->view_only);
         }
         else
         {
            err_message (FILE_TO_LARGE);
            fc->byte_anz = -1;
         }
      }
      else
      {
         fc->byte_anz = -1;
      }
   }

/* read file o.k. ? */
   if (fc->byte_anz < 0)
   {                        /* error, set buffer + filename to 'empty' */
      fc->byte_anz = 0;
      init_file_control (fc, 1);
      *fc->filename = '\0';
      ok_flag = 0;
   }
   fc->change_flag = 0;

#if (VAR_EOLN)
   fc->eoln     = get_var_eoln    (fc->buff_0, 0L, fc->byte_anz);
#endif
   fc->line_anz = get_total_lines (fc->buff_0, 0L, fc->byte_anz);


/* default */
   fc->syntax_flag = 0x00;


#if (WITH_SYNTAX_HIGHLIGHTING)
/* set syntax_flag = f (filename extension) */
/* files with name "*.c" or "*.h" are handled with c syntax ON */

   file_type = get_file_type(fc->filename);
   if (file_type > 0)
      fc->syntax_flag = 0x07 & set.syntax_global;
   else
      fc->syntax_flag = 0x00;


   fc->e_delimit = get_hi_light_delimiters(get_file_type(fc->filename));
#endif

   set_highbit();

   return ok_flag;

}  /* get_1_datafile */

/* -FF- */

/* ----------------------------------------------------------- */
/*  main program                                               */
/* ----------------------------------------------------------- */

int main (argc, argv)       /* hier bei main (und nur hier !): */
int argc;                   /* keine ANSI-Schreibweise, wegen  */
char *argv [];              /* des c-compiler unter ultrix     */
{
int ii, search_macro, read_macro, view_only_flag, ok_flag;
int no_of_options, no_of_files;
size_t  mk_len;
char *name_stt = NULL, *name_end;

#if (WITH_LAST_AGAIN)
int last_again;
#endif

#define MACRO_KENNUNG "macro("
struct MACRO *macro_ex;          /* for "Macro Execute" */

#if (DEMO_VERSION)
static int edit_version = 1;
#endif

/* init keyboard input */
   check_input_redirection ();

/* echo abschalten */
   kb_echo_off ();

/* video context saven */
   SaveVideoContext ();

/* Modify CTRL+C behavior. */
   if (signal (SIGINT, ctrlchandler) == SIG_ERR)
   {
      printf ("\015\012 Couldn't set SIGINT\015\012");
      kb_echo_on ();
      RestoreVideoContext ();
      exit (-1);
   }

/* init. display */
   if (init_mon_outp () < 0)
   {
      printf ("\015\012 error init video\015\012");  /* fatal error */
      kb_echo_on ();
      RestoreVideoContext ();
      signal (SIGINT, SIG_DFL);
      exit (-1);
   }

/* help command line options */
   if (argc >= 2)
   {
      if ((stricmp (argv[1], "-?")    == 0) ||
          (stricmp (argv[1], "-h")    == 0) ||
          (stricmp (argv[1], "-help") == 0))
      {
         printf ("\015\012 usage: mbedit [filenames] [options]\015\012");
         printf ("\015\012 - [filenames]: [<filename 1>] [<filename 2>] ... [<filename 10>]\015\012");

#if (WITH_LAST_AGAIN)
         printf ("\015\012 - [options]  : [- | last_again] [vo | viewonly] [batch]\015\012");
#else
         printf ("\015\012 - [options]  : [vo | viewonly] [batch]\015\012");
#endif
         printf ("\015\012                [nomacro] [macro(<macrofile>)]\015\012");

         kb_echo_on ();
         RestoreVideoContext ();
         signal (SIGINT, SIG_DFL);
         exit (-1);
      }
   }

#if (DEMO_VERSION == 2)
   edit_version = get_edit_status ();
#endif

/* get first work buffer */
   fc = &file_control [act_buff_no [act_window]];

   fc->buff_0 = (char *)loc_malloc (INIT_FILESIZE);
   if (fc->buff_0 != NULL)
   {
      fc->malloc_flag = 1;
      fc->buffer_size = INIT_FILESIZE;
#if (VAR_EOLN)
      fc->eoln = EOLN_INIT;
#endif
   }
   else
   {
      printf ("\015\012 malloc error buffer 0\015\012");  /* fatal error */
      kb_echo_on ();
      RestoreVideoContext ();
      signal (SIGINT, SIG_DFL);
      exit (-1);
   }


/* initialize */
   init_file_control (fc, 1);          /* file 'A' */

#if (MACRO_TUNING)
   init_sorted_tables ();
#endif


/* test_screen ();  Darstellung des VGA-Zeichensatzes (nur bei MS_DOS) */

/* vorsichtshalber vt-100-semi-grafik abschalten */
   set_grafik_off (0);


/* default settings */
   *fc->filename  = '\0';
   fc->byte_anz   = 0;

   view_only_flag = 0;    /* option "viewonly" | "vo"   --> 1 */
   search_macro  = 1;     /* option "nomacro"           --> 0 */
   read_macro    = 0;     /* option "macro(<filename>)" --> 1 */
#if (WITH_LAST_AGAIN)
   last_again    = 0;     /* option "-"                 --> 1 */
#endif


/* parse input line */
   no_of_options = 0;

   for (ii = 1 ; ii < argc ; ii++)
   {
   /* view only */
      if ((stricmp (argv[ii], "vo")       == 0) ||
          (stricmp (argv[ii], "viewonly") == 0))
      {
         no_of_options++;
         view_only_flag = 1;
      }

   /* batch mode */
      if (stricmp (argv[ii], "batch") == 0)
      {
         no_of_options++;
         set_batch_mode (1);
      }

#if (WITH_LAST_AGAIN)
   /* last files again */
      if ((stricmp (argv[ii], "-")          == 0) ||
          (stricmp (argv[ii], "last_again") == 0))
      {
         no_of_options++;
         last_again = 1;
      }
#endif

   /* nomacro */
      if (stricmp (argv[ii], "nomacro") == 0)
      {
         no_of_options++;
         search_macro = 0;
      }

   /* "macro(<filename>)"  ACHTUNG !! keine blanks im string !! */
      mk_len = strlen(MACRO_KENNUNG);
      if (strnicmp (argv[ii], MACRO_KENNUNG, mk_len) == 0)
      {
         no_of_options++;

         name_stt = &argv[ii][mk_len];  /* 1. char hinter '(' */
         name_end = &argv[ii][mk_len];
         while ((*name_end != ')') &&
                (*name_end != '\0'))
         {
            name_end++;
         }
         *name_end = '\0';

      /* build macro filename */
         read_macro = 1;
      }
   }

/* introduction */
   if (get_video_active (0))
   {
      show_intro ();
   /* sleep (1); */
   }

/* store path name of exe-file */
   store_exe_path (argv [0]);

#if (DEMO_VERSION == 2)
/* calculate checksum */
   if (!checksum_ok (argv [0]))
      edit_version = 2;
#endif


/* get history file */
   read_history_file ();


#if (WITH_SYNTAX_HIGHLIGHTING)
/* get file for syntax highlighting */
   search_syntax_file();
#endif


#if (WITH_LAST_AGAIN)
   read_status_file ();

/* option "-" invoked ? set list of filenames in argc, argv [] */
   if (last_again)
   {
   /* set virtual command line arguments */
      argc = mini_file_num + 1;
      no_of_options = 0;
   }  /* if last_again */
#endif


/* read all data files from command line */
/* "mbedit <file 1> <file 2> ... <file n> [option1] [option2] [option3]" */

   no_of_files = argc - no_of_options - 1;
   no_of_files = min (no_of_files, MAX_FC_NUM);      /* begrenzen */

   set.file_num = max (set.file_num, no_of_files);   /* ggf. erhoehen */

/* loop for arguments */
   for (ii = 1 ; ii <= no_of_files ; ii++)
   {
   /* filename extrahieren */
#if (WITH_LAST_AGAIN)
      if (last_again)
         strncpy (fc->filename, mini_control[ii-1].filename, sizeof (fc->filename));
      else
         strncpy (fc->filename, argv[ii], sizeof (fc->filename));
#else
      strncpy (fc->filename, argv[ii], sizeof (fc->filename));
#endif
   /* ^^^^^^^                                                   */
   /* ACHTUNG ! Hier nicht memcpy verwenden, sonst possible     */
   /* segmentation violation, da ueber das ende von argv[ii]    */
   /* hinaus gelesen wird. Ob das gut geht, haengt von der      */
   /* Umgebung ab (z.B. Aufruf von shell oder fids) !!          */

      fc->filename [sizeof(fc->filename)-1] = '\0';
      fc->view_only = view_only_flag;
      fc->byte_anz  = -1;

   /* read data file */
      ok_flag = get_1_datafile ();

   /* get next file buffer */
      if (no_of_files > 1)
      {
         ok_flag = get_next_file_buffer (1);

         if (ok_flag < 0)
            break;   /* no more buffer, abort loop */
      }
   }  /* for loop */


#if (WITH_LAST_AGAIN)
/* option "-" invoked ? set cursor position */
   if (last_again)
   {
      for (ii = 0 ; ii < no_of_files ; ii++)
      {
         perform_move (mini_control[ii].byte_index);
         fc->view_only = mini_control[ii].view_only;
         exchange_file_control (no_of_files, 1);
      }
   }  /* if last_again */
#endif


/* get macro file(s) */
   if (read_macro)
   {
      read_macro_file (name_stt, 1);
   }
   else
   {
      if (search_macro)
         search_macro_file ();
   }
   set.file_num = max (set.file_num, no_of_files);   /* ggf. erhoehen */



/* prepare macro "INIT" for later execution */
   macro_ex = get_macro_adress ("INIT");
   if (macro_ex != NULL)
   {
      push_macro_stack (macro_ex, MACRO_EXECUTE, 1L, mode_flag);
   }



/* activate mouse driver */
#if WITH_MOUSE
   if (mouse_status)
   {
      if (get_video_active(0))
         show_status_line_2 ("*** initializing mouse driver ***", 0, -2, 0);
      mouse_driver_ok = 1 - MouStartup (COLUMNS, (ROWS-STATUS_LINES));
   }
#endif


#if (WITH_WINCH)
   set_window_size ();
#endif


/* activate # of rows + columns from: */
/*   - set_window_size () or          */
/*   - read_macro_file ()             */
   if (get_video_active(0))
      resize_screen ();


/* call main loop */
#if (DEMO_VERSION)

#if (DEMO_VERSION == 2)
   show_edit_message (edit_version - 1);
   if (edit_version == 1)
      main_loop ();
   else
      delete_datafile (argv[0]);   /* executable program */
#else
   show_edit_message (2);
   main_loop ();
   show_edit_message (3);
#endif


#else
   main_loop ();
#endif

/* put back buffers */
   for (ii = 0 ; ii < MAX_FC_NUM ; ii++)
   {
      fc = &file_control [ii];
      if (fc->malloc_flag) loc_free (fc->buff_0);
   }

/* write back history file */
   write_history_file (1);

#if (WITH_LAST_AGAIN)
   write_status_file ();
#endif


/* stop mouse driver */
#if WITH_MOUSE
   if (mouse_driver_ok)
   {
      if (get_video_active(0))
         show_status_line_2 ("*** stopping mouse driver ***", 0, -2, 0);
      MouEnd ();
   }
#endif


/* end of program */
   push_attributes ();   /* restore old screen colors */
   if (get_video_active(0))
      clear_screen ();
   printf ("\015\012");


/* restore keyboard and signal status */
   kb_echo_on ();
   RestoreVideoContext ();
   signal (SIGINT, SIG_DFL);

   exit (0);
   return (0);
}  /* main */

/* -FF- */

/*-----------------*/
/* main loop       */
/*-----------------*/

char * get_line_1_text (void)
{
   if (get_macro_status () == MACRO_CREATE)
      return ("<MACRO Create>");
   else
      return fc->filename;

}  /* get_line_1_text */

/* mit einem langsamen vt-100-terminal ist das staendige updaten der */
/* status_line_1 zu aufwendig, hier wird statt dessen mit timeout    */
/* gearbeitet (nur unter unix).                                      */


#if (SLOW_TERMINAL)

static int jmpret;
static jmp_buf env;
#define OUT_TIME 1   /* sec. */


/* dummy routine fuer alarm handling */
static void key_time (void)
{
   longjmp (env, KEY_TIMEOUT);
}

#endif


/* -FF-  */

static int auto_shift;

void set_auto_shift (int flag)
{
/* call from macro.c */

   auto_shift = flag;

   return;
}  /* set_auto_shift */

/* -FF-  */

void resize_screen (void)
{
   clear_screen ();

#if (!WITH_HEX_VIEW)

   perform_view ();

#else

   if ((mode_flag < 3) || (act_window))
   {
      perform_view ();
   }

   if (mode_flag >= 3)
   {
      show_status_line_1 (get_line_1_text (), fc);
      show_status_line_2 (mode_text [mode_flag], 0, -2, 0);
      hex_refresh_disp ();
   }

#endif


#if WITH_MOUSE
   MouSetMoveArea ( 0                , (byte) TOP_ROW,
                   (byte) (COLUMNS-1), (byte) MAX_ROW,
                    0);
#endif

   return;
}  /* resize_screen */


void limit_windows (void)
{
int upper, total;

   upper = w_bot[1];    /* keep old ratio of windows */
   total = w_bot[0];

   w_bot[0] = ROWS - 1;
   w_bot[2] = w_bot[0];
/* w_bot[1] = min (w_bot[1], w_bot[0]); */
   w_bot[1] = (w_bot[0] * upper + total/2)     /* keep const. ratio      */
              / max (1, total);                /* avoid division by zero */
   w_top[2] = w_bot[1] + 1;

   return;
}  /* limit_windows */

/* -FF-  */

static void main_loop (void)
{

/*
/     Hauptschleife: Endlosschleife zur Tastatur-Eingabe und Aufruf von
/     switch_key_0 (in switches.c), von wo die notwendigen Aktionen
/     aufgerufen werden.
/     Steuerung der Funktionen 'Again' und 'Repeat' (repeat_count, repeat_max).
/
/     Bedeutung der Variablen "end_of_edit":
/        0 : Normalfall
/        1 : End of Edit (nach "Quit Exit" oder "Quit Abort")
/       -1 : Repeatschleife und alle Macro-Sequenzen werden abgebrochen,
/            wenn Operation erfolglos (z.B. nach "Find": not found)
/       -2 : Repeatschleife wird abgebrochen bei Funktionen, die keine sinn-
/            volle Repeat-Verwendung haben (z.B. "Quit", "Set", "Jump", usw...)
*/

static int key_0       = 0;
static int key_1       = 0;
static int last_key_0  = 0;
static int end_of_edit = 0;
static int macro_exit  = 0;
static enum MACRO_STATUS old_macro_status;
static int new_special, old_special;

struct MACRO *macro_ex;          /* for "Macro Execute" */
int  again_flag, abort_loop, delta;
long repeat_count, repeat_max;

#define INFINITE 0x7fffffff

/* sleep_msec(1000);  test behaviour of startup sequence (e.g. macro "INIT") */

#if 0
/* anzeige speicherinhalt */
   view_or_update ();
   perform_update (fc->buff_0, fc->byte_anz, fc->left_col);
   show_status_line_1 (fc->filename, fc);
#endif

   line_2_flag = 1;


/* nearly endless loop */
   while (end_of_edit != 1)
   {
      if (auto_shift)
      {
         delta = 0;

         if (REL_COLUMN > (COLUMNS-1))
            delta = REL_COLUMN - (COLUMNS-1);

         if (REL_COLUMN < 0)
            delta = REL_COLUMN;

         if (delta)
         {
            fc->left_col += delta;
            update_entire_window (fc->top_left);
         }
      }

   /* update display ? */
   /* ggf. display status line 1 */
      if (!key_pressed ())
      {
         perform_update (fc->buff_0, fc->byte_anz, fc->left_col);

#if (!SLOW_TERMINAL)
         show_status_line_1 (get_line_1_text (), fc);
#endif
      }


   /* ggf. display status line 2 */
#if 0
      if (old_macro_status != MACRO_EXECUTE)
#endif
      {
         if (save_d.toggle == 1)
         {
            line_2_flag = 2;
            show_status_line_2 ("Buffer Delete Find -find Jump Put", 0, -2, 0);
         }
         else
         {
               if (line_2_flag == 1)
               {
                  show_status_line_2 (mode_text [mode_flag], 0, -2, 0);
                  line_2_flag = 0;
               }
               if (line_2_flag > 1)
                  line_2_flag--;  /* ggf. dekr. */
         }
      }
      old_macro_status = get_macro_status ();

   /* set cursor */
      if (get_video_active (0))
         set_cursor_to (fc->lrow, REL_COLUMN);


#if (!SLOW_TERMINAL)

   /* get next command */
      key_0 = get_1_key (1);

#else

      signal (SIGALRM, key_time);     /* set signal handling       */
      alarm (OUT_TIME);               /* set timeout: LSB 1 sec !! */
      jmpret = setjmp (env);

   /* get next command */
      if (jmpret == 0)
         key_0 = get_1_key (1);
      else
         key_0 = jmpret;

      alarm (0);                     /* reset timeout */

      if (key_0 == KEY_TIMEOUT)
      {
         show_status_line_1 (get_line_1_text (), fc);
         set_cursor_to (fc->lrow, REL_COLUMN);

         key_0 = get_1_key (1);
      }

#endif


   /* wiederholfaktor zusammensetzen */
      repeat_max = 1;  /* default */
      if (mode_flag == 0)
      {
         if (key_0 == '/')
         {
            repeat_max = INFINITE;
            line_2_flag = 1;
            show_status_line_2 ("Repeat forever :", 0, -1, 0);
            key_0 = get_1_key (1);
         }
         else
         {
            if ((key_0 >= '0') && (key_0 <= '9'))
            {
               repeat_max = key_0 - '0';
               line_2_flag = 1;
               repeat_max = get_line_2_repeat ("Repeat n times :",
                                               repeat_max, &key_0);
            }
         }
      }

   /* ggf. cursor-position korrigieren */
      old_special = new_special;

      new_special = ((key_0 == KEY_UP)   ||
                     (key_0 == KEY_DOWN) ||
                     (key_0 == KEY_HOME) ||
                     (key_0 == KEY_PGUP) ||
                     (key_0 == KEY_PGDN) ||
                     (key_0 == KEY_TIMEOUT));

      if (((!new_special) && (old_special)) ||
          (mouse_moved))
         check_dirty_cursor ();
      mouse_moved = 0;

   /* Again ? */
      if ((mode_flag == 0) && (toupper(key_0) == 'A'))
      {
         key_0 = last_key_0;
         again_flag = 1;
      }
      else
      {
         again_flag = 0;
      }

   /* aufrufen */
      for (repeat_count = 0 ;
           repeat_count < max (1L, repeat_max) ;
           repeat_count++)
      {
         end_of_edit = switch_key_0 (key_0, max (repeat_count, again_flag),
                                                 repeat_max);

      /* total abort of editing ? */
         if (end_of_edit == 1)
         {
         /* is macro "EXIT" already executed ? */
            if (macro_exit)
            {
               return;   /* yes ! don't do it again */
            }

         /* no ! check for macro "EXIT" */
            macro_ex = get_macro_adress ("EXIT");
            if (macro_ex != NULL)
            {
               push_macro_stack (macro_ex, MACRO_EXECUTE, 1L, mode_flag);
               macro_exit  = 1;
               end_of_edit = -2;
            }
            else
            {
               return;   /* normal exit of function */
            }
         }

      /* end of macro "EXIT" ? */
         if ((macro_exit) && (get_macro_nesting_level () == 0))
         {
            return;
         }


      /* check, if abort for loop */
         abort_loop = 0;                  /* default */

         if (end_of_edit < 0)             /* last command not successfull */
            abort_loop = 1;

         if (ctrlc_active())              /* was ^C entered ? (ms/dos) */
         {
            abort_loop = 1;
            reset_macro_stack ();
         }

         if (loc_key_pressed())           /* or user break ? */
         {                                /* with <esc> ? */
            key_1 = loc_get_1_key();      /* from keyboard, not from macro */
            if ((key_1 == 0x1b) ||        /* <esc> */
                (key_1 == 0x03) ||        /* ^C (os/9, unix) */
                (key_1 == EOF))           /* end of file */
            {
               abort_loop = 1;
            }
            /* else  comment around "else" NEW !! 09.03.95                   */
            /*       Put back key in any case !                              */
            /*       <esc> in keyboard buffer is used for end of Find-String */
            {
               set_key_fifo (key_1);  /* back to input buffer !! */
            }
         }

         if (abort_loop)
         {
            if ((get_macro_status () == MACRO_EXECUTE) &&
                (end_of_edit != -2))   /* Setup "Macro Execute" */
            {
               if (repeat_max != INFINITE)
                  stop_this_macro ();
            }
            break;    /* leave for loop */
         }
      }  /* for repeat_count */

   /* fuer naechsten durchgang merken */
      if (key_0 != KEY_TIMEOUT)
         last_key_0 = key_0;


#if ((WITH_WINCH) && (ACT_OP_SYSTEM == WIN_32))
      if (set_window_size ())
          {
         perform_view ();
          }
#endif

   }  /* while end_of_edit */

   return;  /* hier kommt er nie hin ! */

}  /* main_loop */

/* -FF-  */

#if (WITH_WINCH == 2)

static int num_from_stream (FILE *fd, char *search_string, int *number)
{
int c1, result;
char *search;

   search = search_string;   /* set to begin of search string */
   result = 0;

   while ((c1 = fgetc (fd)) != EOF)         /* read 1 char */
   {
      if (c1 == *search)                    /* does it match ? */
      {                                        /* yes ! */
         search++;                             /* incr. pointer */
         if (*search == '\0')                  /* reached end of string ? */
         {
            result = fscanf (fd, "%d", number);  /* read number from stream */
            while ((c1 = fgetc (fd)) != EOF)     /* read stream until EOF */
            {
               ;  /* empty loop */
            }
            return (result);
         }
      }
      else
      {                                        /* no ! */
         search = search_string;               /* set back to begin */
      }
   }

   return result;    /* nothing found */

}  /* num_from_stream */

/* -FF-  */

static int mb_tput (char *arg_str, int *number)
{

/* calculate the number of lines and columns of active window */

static int value, fall, ii, result;
static FILE *fd;

#define STR_NUM 2
struct WINDOW {
                 char *arg;            /* command line argument */
                 char *str [STR_NUM];  /* search strings */
              };

static struct WINDOW window [] = {"lines", "li#", "LINES=",
                                  "cols" , "co#", "COLUMNS="};


#if (DOS_TEST)

#define FILENAME "tmp"
#define COMMAND_STRING "echo abcde:LINES=20:dhdhgfgf:co#80:dndnsdmn > tmp"

#else

#define TEST 0
#if TEST
#define COMMAND_STRING "cat /tmp/out"
#else
/* #define COMMAND_STRING "resize -u > /tmp/out; cat /tmp/out" */
#define COMMAND_STRING "resize -u"
#endif

#endif


/* default */
   fall = -1;   /* not defined */


/* which value is required ? */
   for (ii = 0 ; ii < lengthof (window) ; ii++)
   {
      if (strcmp (arg_str, window[ii].arg) == 0)
      {
         fall = ii;
         break;
      }
   }


/* fallunterscheidung */
   if (fall != -1)
   {
      for (ii = 0 ; ii < STR_NUM ; ii++)
      {
#if (DOS_TEST)
         system (COMMAND_STRING);
         fd = fopen (FILENAME, "r");
#else
         fd = popen (COMMAND_STRING, "r");
#endif
         if (fd)
         {
            result = num_from_stream (fd, window[fall].str[ii], &value);
            pclose (fd);
            if (result == 1)
            {
               *number = value;
               break;
            }
         }
      }
   }

   return (result);
}  /* mb_tput */

#endif

/* -FF-  */

#if (WITH_WINCH)

void cmd_winch (int sig_num)
{
#if (TEST_PRINT)
   printf ("\n>>> cmd_winch: sig_num = %d \n", sig_num);
#endif

#if 0
#if (UNIX)
   if ((signal(sig_num, SIG_IGN)) == SIG_ERR)     /* ignore now */
       syserr("signal sig_num, cmd_winch");
#endif
#endif

/* Now we have to set the number of lines and cols new ! */
   set_window_size ();
   resize_screen ();

#if (UNIX)
   if ((signal(sig_num, cmd_winch)) == SIG_ERR)     /* set it again */
       syserr("signal sig_num, cmd_winch");
#endif

   return;
}  /* cmd_winch */


int set_window_size (void)
{
int new_lines, new_cols, change_flag = 0;
FILE *fd = 0;
#define PATH_0   fileno(stdin)   /* standard input */

   fd;  /* wg. compiler warning */

#if (TEST_PRINT)
   printf ("\n>>> set_window_size: ROWS = %d, COLUMNS = %d \n",
                                ROWS, COLUMNS);
#endif


/* default values */
   new_lines = ROWS;
   new_cols  = COLUMNS;


/* get the new number of lines and columns, using different methods */

/* cooked mode, signal OFF */
   kb_echo_on ();


#if (WITH_WINCH == 1)                  /* use "tput" */
   fd = popen ("tput lines", "r");
   if (fd)
   {
      fscanf (fd, "%d", &new_lines);
      pclose (fd);
   }

   fd = popen ("tput cols", "r");
   if (fd)
   {
      fscanf (fd, "%d", &new_cols);
      pclose (fd);
   }
#endif  /* 1 */


#if (WITH_WINCH == 2)                  /* use "mb_tput" */
   mb_tput ("lines", &new_lines);
   mb_tput ("cols" , &new_cols );
#endif  /* 2 */


#if (WITH_WINCH == 3)                  /* use "ioctl" */
#ifdef TIOCGWINSZ
   {
        struct winsize win_size;

        if( ioctl( fileno(stdin), TIOCGWINSZ, &win_size ) != -1 )
        {
           if ((win_size.ws_row != 0) &&
               (win_size.ws_col != 0))
           {
              new_lines = (int)win_size.ws_row;    /* Rows, in characters    */
              new_cols  = (int)win_size.ws_col;    /* Columns, in characters */
#if 0
              win_size.ws_xpixel;     /* Horizontal size, in pixels */
              win_size.ws_ypixel;     /* Vertical size, in pixels   */
#endif
           }
        }
        else
        {
           new_lines = INIT_ROWS;               /* error:         */
           new_cols  = INIT_COLUMNS;            /* default values */
        }
   }
#endif
#endif  /* 3 */


#if (WITH_WINCH == 4)
   {
      static char X11_tput [] = "eval `resize -u`;tput lines;tput cols";
      static char Unix_tput [] = "tput lines;tput cols";
      char * tput_cmd = getenv ("DISPLAY") ? X11_tput : Unix_tput;

      fd = popen (tput_cmd, "r");
      if (fd)
      {
         fscanf (fd, "%d", &new_lines);
         fscanf (fd, "%d", &new_cols);
         pclose (fd);
      }
   }
#endif  /* 4 */


#if (WITH_WINCH == 5)
   vb_getvsize (&new_cols, &new_lines);
#endif  /* 5 */


#if (WITH_WINCH == 6)
   {
#if (ACT_OP_SYSTEM == OS_9)

   #ifndef fileno
      #define fileno(p)  ((p)->_fd)
   #endif

#endif

#define CODE     0

   static struct _sgs sgs;   /* buffer for window control */

      getstat (CODE, PATH_0, &sgs);
      new_lines = sgs._sgs_page;
   }
#endif  /* 6 */


#if (WITH_WINCH == 7)
   {
      static char WIN32_tput [] = "mode con";

      fd = _popen (WIN32_tput, "r");
      if (fd)
      {
         static char parse[255];

         while (fgets(parse, sizeof(parse), fd))
         {
           sscanf(parse, "Columns=%d", &new_cols);
           sscanf(parse, "Spalten:%d", &new_cols);
           sscanf(parse, "Spalten (COLS)=%d", &new_cols);

           sscanf(parse, "Lines=%d", &new_lines);
           sscanf(parse, "Zeilen:%d", &new_lines);
           sscanf(parse, "Zeilen (LINES)=%d", &new_lines);
         }
         _pclose (fd);
      }
   }
#endif  /* 7 */


#if (WITH_WINCH == 8)
   {
           get_screen_lin_col(&new_lines, &new_cols);
   }
#endif  /* 8 */


#if (WITH_WINCH == 9)   /* QNX6 */
   {
   int t_lines, t_cols;

      if (tcgetsize( PATH_0, &t_lines, &t_cols) == 0)
      {
         new_lines = t_lines;   /* take over rows */
         new_cols  = t_cols;    /* take over columns */
      }
   }
#endif  /* 9 */



/* raw mode, signal ON */
   kb_echo_off ();


#if (TEST_PRINT)
   printf ("\n>>> set_window_size: new_lines = %d, new_cols = %d \n",
                                new_lines, new_cols);
#endif

/* limit new values */
   new_lines = max (new_lines, STATUS_LINES + 1);
   new_lines = min (new_lines, LIMIT_ROWS);

   new_cols  = max (new_cols, 1);
   new_cols  = min (new_cols, LIMIT_COLUMNS);

/* settings changed ? */
   if ((COLUMNS != new_cols) ||
           (ROWS    != new_lines))
   {
           change_flag = 1;
   }

/* take over */
   COLUMNS  = new_cols;
   ROWS     = new_lines;
   limit_windows ();

   return change_flag;
}  /* set_window_size */

#endif

/* -FF-  */

/* Modification History */
/* 20.11.92 - file erzeugt */
/* 23.11.92 - CR_CRLF */
/* 24.11.92 - init_mon_outp */
/* 25.11.92 - perform_key_... () */
/* 26.11.92 - get_total_lines () */
/* 27.11.92 - insert/exchange-mode */
/* 28.11.92 - display-ansteuerung speed-optimiert */
/* 29.11.92 - view command */
/* 30.11.92 - get_line_2_string () */
/* 01.12.92 - macro ' ' */
/* 02.12.92 - Find, Replace */
/* 04.12.92 - err_message () */
/* 05.12.92 - Again */
/* 06.12.92 - mbedit.c war ueber 2000 zeilen lang,  */
/* 20.12.92 - loc_malloc other_fc erst bei command 'Other' (in switches.c) */
/* 21.12.92 - mbedit ohne <filename> */
/* 02.01.93 - show_status_line_2 ("Macro Create: End with 'M'", -2); */
/* 03.01.93 - Abort Macro Execution, if not successfull (e.g. at EOF) */
/* 05.01.93 - search_macro_file () */
/* 18.06.93 - execute macro "INIT" */
/* 21.07.93 - push_macro_stack (..., 1L, ...);  (vorher 1) */
/* 27.07.93 - get_next_file_buffer (int direction) */
/* 28.07.93 - EOL --> EOLN */
/* 09.09.93 - init_file_control: fcl->find [0...1] = -1 */
/* 12.09.93 - DEMO_VERSION */
/* 12.09.93 - show_status_line_2 (..., ignore_batch) */
/* 14.09.93 - stop_this_macro(), only if not INFINTE */
/* 14.09.93 - display status line 2 only if ! MACRO_EXECUTE */
/* 14.09.93 - read given macro file or default (or none), but not both ! */
/* 15.09.93 - help invocation */
/* 29.09.93 - update_rest_of_window(), ...entire_window() */
/* 02.10.93 - init_file_control (..., int clear_flag) */
/* 18.10.93 - aufruf-bedingung von check_dirty_cursor() */
/* 04.11.93 - TEST_EOLN entfaellt */
/* 04.11.93 - wildcard_filename */
/* 06.11.93 - wildcard_filename --> disp_hnd.c */
/* 26.11.93 - bugfix: segmentation violation */
/* 29.11.93 - mb_ctype.h */
/* 06.12.93 - GRAFIK_OFF --> mon_outp.c */
/* 07.12.93 - ctrlchandler (int sig) */
/* 08.12.93 - ctrlchandler auch bei os/9 */
/* 08.12.93 - WITH_MOUSE */
/* 09.12.93 - mouse_moved */
/* 09.12.93 - mouse_driver_ok */
/* 13.12.93 - set_mouse_status () */
/* 07.01.94 - auto_shift, set_auto_shift () */
/* 12.05.94 - MACRO_TUNING */
/* 20.05.94 - mbedit # | last_again */
/* 21.05.94 - write_status_file(), read_status_file() */
/* 24.05.94 - bugfix */
/* 03.06.94 - WITH_WINCH, cmd_winch () */
/* 04.06.94 - set_window_size (): check, if values changed */
/* 06.06.94 - end of program: SIGALRM + SIGWINCH --> SIG_DFL */
/* 06.06.94 - end of program: reset_macro_stack () */
/* 07.06.94 - end of program: reset_macro_stack () ueberfluessig */
/* 07.06.94 - WITH_WINCH = 1, 2, 3 for different unix systems */
/* 08.06.94 - num_from_stream () */
/* 08.06.94 - resize_screen () after read_macro_file () */
/* 09.06.94 - TEST_PRINT */
/* 14.06.94 - resize_screen: nicht bei batch mode */
/* 21.07.94 - set_window_size() mit ioctl */
/* 31.08.94 - mbedit.c: take over new_lines + new_cols only, if != 0 */
/* 26.09.94 - hex_refresh_disp() */
/* 30.09.94 - WITH_WINCH 4 for SCO_UNIX */
/* 02.10.94 - get_1_datafile(): set fc->syntax_flag = f(filename extension) */
/* 05.10.94 - get_1_datafile(): set + reset fc->syntax_flag */
/* 07.10.94 - set_grafik_off (0); */
/* 22.01.95 - WITH_WINCH 5 for VGA */
/* 09.03.95 - mainloop(): put back <esc> key in any case */
/* 19.10.95 - set_window_size(): WITH_WINCH 6 (OS_9) */
/* 17.11.95 - syntax_global */
/* 23.01.96 - printf ("\015\012") anstatt printf ("\r\n") */
/* 05.09.98 - VAR_EOLN (var. end of line char.) */
/* 05.09.98 - get_var_eoln() */
/* 05.02.99 - get_1_datafile(): check R_OK, W_OK */
/* 19.02.99 - get_1_datafile(): check W_OK nicht bei os-9 */
/* 29.03.03 - get_1_datafile(): get_file_type() */
/* 17.04.03 - WITH_WINCH 7 (WIN_32) */
/* 11.02.04 - 'S'et 'H'ighbit 'A'uto */
/* 15.02.04 - QNX6: New ! */
/* 13.03.04 - disp_hnd.c: modifications for CSS (dashes in keywords) */
/* 24.03.04 - init_file_control(): set fc->e_delimit only if clear_flag */
