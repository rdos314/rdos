/*      switches.c                                  24.03.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 2004: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    ausgelagerte functions von mbedit.c
/
/     Verzweigung in die diversen Betriebsarten, Kommandomodes,
/     Macrosequenzen, usw..., je nach Eingabe-Key.
/     Zur Bedeutung der Variablen "end_of_edit" siehe mbedit.c !
/
*/


/************************/
/*  include files       */
/************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "mbedit.h"
#include "calc_var.h"
#include "switches.h"
#include "perform.h"
#include "err_mess.h"
#include "help_opt.h"
#include "mbed_sub.h"
#include "commands.h"
#include "blocks.h"
#include "kb_input.h"
#include "mon_outp.h"
#include "memo_hnd.h"
#include "file_hnd.h"
#include "history.h"
#include "disp_hnd.h"
#include "calc.h"
#include "macro.h"
#include "mb_ctype.h"
#include "window.h"
#include "paragraf.h"
#include "vbios.h"
#include "ansi_out.h"


/************************/
/* some defines         */
/************************/

                          /* most commands are locked, when Buffer/Delete   */
                          /* Command is invoked, especially those commands, */
                          /* which would modify the memory content.         */
#define LOCK_WHEN_BUFFER_ACTIVE    if (save_d.toggle == 1) {beep (); break;}

#define REFRESH_WHEN_BUFFER_ACTIVE if (save_d.toggle == 1) {update_this_line (fc->lin_left, fc->lrow);}

#define LOCK_WHEN_VIEW_ONLY if (fc->view_only) {err_message(VIEW_ONLY); break;}

#define BREAK_IF_REPEAT_0   if (repeat_max == 0) {break;}


/************************/
/* local structures     */
/************************/



/************************/
/*  module definitions  */
/************************/

/* for Find / Replace */
static int  find_ok;
static int  find_count, replace_count;

/* for "Macro Create"  */
static struct MACRO *macro_cr;

/* -FF-  */

void get_calc_vars_switches (struct CALC_VARS *cv)
{

/* set the calc flags for: Find, Replace */
   cv->cntfnd = find_count;
   cv->cntrep = replace_count;
   cv->lstfnd = -find_ok;

   return;
}  /* get_calc_vars_switches */

/* -FF-  */

int switch_key_0 (int key_0, long repeat_count, long repeat_max)
{
static int last_key;
long new_index;
int end_of_edit;
byte update_cursor;
int row, column, exe_flag;
struct MACRO *macro_ex;          /* for "Macro Execute" */

   REFRESH_WHEN_BUFFER_ACTIVE

   end_of_edit = 0;
   update_cursor = (byte)(repeat_max == 1);

   switch (key_0)
   {
      case KEY_PGUP:
         BREAK_IF_REPEAT_0
         end_of_edit = perform_page_up () - 1;
         save_x.index = 0;
         break;

      case KEY_PGDN:
         BREAK_IF_REPEAT_0
         end_of_edit = perform_page_down () - 1;
         save_x.index = 0;
         break;

      case KEY_END:
         end_of_edit = -2;
         BREAK_IF_REPEAT_0
         perform_end_of_line (1);
         save_x.index = 0;
         break;

      case KEY_LEFT:
         BREAK_IF_REPEAT_0
         end_of_edit = (perform_key_left (update_cursor, 1) != 0) - 1;
         save_x.index = 0;
         break;

      case KEY_RIGHT:
         BREAK_IF_REPEAT_0
         end_of_edit = (perform_key_right (update_cursor, 1) != 0) - 1;
         save_x.index = 0;
         break;

      case KEY_UP:
         BREAK_IF_REPEAT_0
         end_of_edit = perform_key_up (update_cursor) - 1;
         save_x.index = 0;
         break;

      case KEY_DOWN:
         BREAK_IF_REPEAT_0
         end_of_edit = perform_key_down (update_cursor) - 1;
         save_x.index = 0;
         break;

      case KEY_HOME:
         BREAK_IF_REPEAT_0
         key_0 = last_key;
         end_of_edit = switch_last_key (key_0);
         save_x.index = 0;
         break;

      case 0x08:             /* ^H, Backspace  */
#if (ACT_OP_SYSTEM != SCO_UNIX)
      case KEY_RUBOUT:       /* rubout */
#endif
         BREAK_IF_REPEAT_0
         end_of_edit = -2;
         LOCK_WHEN_BUFFER_ACTIVE   LOCK_WHEN_VIEW_ONLY
         perform_delete_left_char ();
         fc->change_flag = 1;
         break;

      case 0x06:             /* ^F */
      case KEY_DEL:
#if (ACT_OP_SYSTEM == SCO_UNIX)
      case KEY_RUBOUT:       /* rubout */
#endif
         LOCK_WHEN_BUFFER_ACTIVE   LOCK_WHEN_VIEW_ONLY
         BREAK_IF_REPEAT_0
         if (repeat_max > 32)
         {
            end_of_edit = -2;
            err_message (NOT_MORE_THAN_32);
            break;
         }
         perform_delete_right_char ();
         fc->change_flag = 1;
         save_x.index = 0;
         break;

      case 0x18:             /* ^X */
         end_of_edit = -2;
         LOCK_WHEN_BUFFER_ACTIVE   LOCK_WHEN_VIEW_ONLY
         BREAK_IF_REPEAT_0
         perform_delete_start_of_line (1);
         fc->change_flag = 1;
         save_x.index = 0;
         break;

      case 0x01:             /* ^A */
         end_of_edit = -2;
         LOCK_WHEN_BUFFER_ACTIVE   LOCK_WHEN_VIEW_ONLY
         BREAK_IF_REPEAT_0
         perform_delete_rest_of_line ();
         fc->change_flag = 1;
         save_x.index = 0;
         break;

      case 0x1a:             /* ^Z */
         end_of_edit = -2;
         LOCK_WHEN_BUFFER_ACTIVE   LOCK_WHEN_VIEW_ONLY
         BREAK_IF_REPEAT_0
         perform_delete_whole_line ();
         fc->change_flag = 1;
         save_x.index = 0;
         check_dirty_cursor ();
         break;

      case 0x15:             /* ^U */
         end_of_edit = -2;
         LOCK_WHEN_BUFFER_ACTIVE   LOCK_WHEN_VIEW_ONLY
         BREAK_IF_REPEAT_0
         end_of_edit = perform_undo () - 1;
         fc->change_flag = 1;
         save_x.index = 0;
         break;

      case 0x04:             /* ^D  (bei aedit ein macro) */
         end_of_edit = -2;
         LOCK_WHEN_BUFFER_ACTIVE   LOCK_WHEN_VIEW_ONLY
         BREAK_IF_REPEAT_0
         if (fc->byte_index > 0)
         {
            fc->buffer--;
            comm_umlaut (fc->buffer);
            fc->buffer++;
            update_this_line (fc->lin_left, fc->lrow);
            fc->change_flag = 1;
         }
         break;

      case 0x0b:             /* ^K  (bei aedit ein macro) */
         end_of_edit = -2;
         BREAK_IF_REPEAT_0
         new_index = comm_ctrl_k (fc->buff_0, fc->byte_index, fc->byte_anz);
         if (new_index >= 0L)
         {
         /* zeiger bewegen */
            perform_move (new_index);

         /* ggf. zeigen */
            if ((fc->lrow <= MIN_ROW) || (fc->lrow >= MAX_ROW))
              perform_view ();
         }
         save_x.index = 0;
         break;

      case KEY_F1:  /* help */
         end_of_edit = -2;
         BREAK_IF_REPEAT_0
         show_help_option ();
         clear_screen ();
         perform_view ();
         line_2_flag = 1;
         break;

      case KEY_F3:  /* convert single char to lower case */
         LOCK_WHEN_VIEW_ONLY
         BREAK_IF_REPEAT_0
         *fc->buffer = tolower_german (*fc->buffer);
         update_this_line (fc->lin_left, fc->lrow);
         end_of_edit = (perform_key_right (update_cursor, 1) != 0) - 1;
         save_x.index = 0;
         fc->change_flag = 1;
         break;

      case KEY_F4:  /* convert single char to upper case */
         LOCK_WHEN_VIEW_ONLY
         BREAK_IF_REPEAT_0
         *fc->buffer = toupper_german (*fc->buffer);
         update_this_line (fc->lin_left, fc->lrow);
         end_of_edit = (perform_key_right (update_cursor, 1) != 0) - 1;
         save_x.index = 0;
         fc->change_flag = 1;
         break;

      case KEY_F5:  /* convert string to lower case */
      case KEY_F6:  /* convert string to upper case */
         LOCK_WHEN_VIEW_ONLY
         BREAK_IF_REPEAT_0
         new_index = perform_lower_upper (key_0 == KEY_F6);
         if (new_index < 0L)
         {
            end_of_edit = -1;
         }
         else
         {
            fc->change_flag = 1;

         /* zeiger bewegen */
            perform_move (new_index);

         /* und zeigen */
            if (fc->lrow >= MAX_ROW)
            {
               perform_view ();
            }
            else
            {
               update_this_line (fc->lin_left, fc->lrow);
               perform_update (fc->buff_0, fc->byte_anz,
                               fc->left_col);
            }
         }
         save_x.index = 0;
         break;

#if HELP_COMMAND_DIRECT
      case ALT_F1:   /* system "qh/help/man <topic>" */
         end_of_edit = -2;
         BREAK_IF_REPEAT_0
         save_x.index = 0;

      /* build command string */
         strcpy (str_syst, HELP_COMMAND);
         get_current_string (fc->buff_0, fc->byte_index, fc->byte_anz,
                             &str_syst[strlen(HELP_COMMAND)]);

      /* perform command */
         clear_screen ();
         fflush (stdout);
         kb_echo_on ();
         system (str_syst);
         kb_echo_off ();

      /* return to mbedit */
         get_hit_any_key ();
         clear_screen ();
         perform_view ();
         break;
#endif

#if ((CHANGE_LINES_DIRECT) && (WITH_WINCH))
      case ALT_F9:
        vb_switch_lines ();
        set_window_size ();
        perform_view ();
        break;
#endif

#if INSERT_KEY_DIRECT
      case KEY_INS:
         end_of_edit = -2;
         LOCK_WHEN_BUFFER_ACTIVE   LOCK_WHEN_VIEW_ONLY
         BREAK_IF_REPEAT_0

         if (mode_flag == 1)   /* insert mode active ?  */
         {
            mode_flag = 2;     /* switch to exchange mode */
            save_x.index = 0;
         }
         else
         {
            mode_flag = 1;     /* switch to insert mode   */
         }

         line_2_flag = 1;

         break;
#endif

      case 0x05:     /* ^E <MEXEC> */
         LOCK_WHEN_BUFFER_ACTIVE

      /* status line 1 missbrauchen */
         get_cursor_pos (&row, &column);
         show_status_line_1 (" <MEXEC> ", fc);
         set_cursor_to (row, column);

      /* check, if macro with "single char name" */
         macro_ex = get_macro_adress (key_2_string (toupper (get_1_key (1))));

         BREAK_IF_REPEAT_0

         if (macro_ex == NULL)
         {
            end_of_edit = -1;
            err_message (ILLEGAL_COMMAND);
         }
         else
         {
            end_of_edit = -2;
            exe_flag = push_macro_stack (macro_ex, MACRO_EXECUTE,
                                         repeat_max, mode_flag);
            if (exe_flag == -1)
            {
               err_message (MACRO_EXEC_NESTING_TO_DEEP);
               reset_macro_stack ();
            }
         }

      /* status line 1 restaurieren */
         get_cursor_pos (&row, &column);
         show_status_line_1 (get_line_1_text (), fc);
         set_cursor_to (row, column);

         line_2_flag = 1;
         break;

      case SEQU_MM:    /* last key in macro sequence */
         mode_flag = get_save_mode_flag ();   /* restore mode_flag */
         /* fall through */

      case SEQU_EM:    /* last key in macro sequence */
         if (get_macro_nesting_level () == 0)
         {
            line_2_flag = 1 + (set.display != 0);
         }
         break;

      case KEY_DO_NOTHING:  /* after end of redirected file */
      case KEY_TIMEOUT:     /* after timeout user input     */
         break;

      case 0x03:  /* ^C */
      /* abort macro create ? */
         if (get_macro_status () == MACRO_CREATE)
         {
            pop_macro_stack (macro_cr, 0);
            free_current_macro (macro_cr);
         }
         /* fall through */

      default:
         end_of_edit = switch_mode_flag (key_0, repeat_count, repeat_max);
         break;

   }  /* switch key_0 */

/* fuer naechsten aufruf merken */
   last_key = key_0;

   REFRESH_WHEN_BUFFER_ACTIVE
   
   return end_of_edit;
}  /* switch_key_0 */

/* -FF-  */

static int switch_last_key (int loc_key)
{
int end_of_edit;

   end_of_edit = 0;

   switch (loc_key)
   {
      case KEY_LEFT:
         end_of_edit = -2;
         perform_begin_of_line (1);
         break;
   
      case KEY_RIGHT:
         end_of_edit = -2;
         perform_end_of_line (1);
         break;
   
      case KEY_UP:
         end_of_edit = perform_page_up () - 1;
         break;
   
      case KEY_DOWN:
         end_of_edit = perform_page_down () - 1;
         break;

      default:
         end_of_edit = -2;
         err_message (ILLEGAL_COMMAND);
         break;
   }
   
   return end_of_edit;
}  /* switch_last_key */

/* -FF-  */

static int check_for_macro (int key, long repeat_max)
{
static struct MACRO *macro_ex;          /* for "Macro Execute" */
int exe_flag;

   if (key >= 0x20)
   {
      return 0;   /* normal character, can't be a macro */
   }
   else           /* special char */
   {
      macro_ex = get_macro_adress (key_2_string (key));
      if (macro_ex == NULL)
      {
         return 0;     /* wasn't a macro */
      }
      else
      {
         exe_flag = push_macro_stack (macro_ex, MACRO_EXECUTE,
                                      repeat_max, mode_flag);
         if (exe_flag == -1)
         {
            err_message (MACRO_EXEC_NESTING_TO_DEEP);
            reset_macro_stack ();
         }
         return 1;     /* it was a macro */
      }
   }

}  /* check_for_macro */

/* -FF-  */

#define EXCHANGE_HEX_CHARS 0

#if (EXCHANGE_HEX_CHARS)

void exchange_chars (char *a, char *b)
{
char c;

    c = *a;
   *a = *b;
   *b =  c;

   return;
}  /* exchange_chars */

#endif

/* -FF-  */

static int switch_mode_flag (int key_0, long repeat_count, long repeat_max)
{
static int lf_strings;
static int first;
char string [80];   /* for "Calc", "Hex Output", usw ... */
STATIC char tmp_filename [BUF_256 + FILENAME_LEN];

static int  exe_flag;
static struct MACRO *macro_ex;          /* for "Macro Execute" */

static int key_1, key_2;

int delta, end_of_edit;
static int do_it;

/* for insert, exchange */
int ii, tab_diff;

/* for quit */
long read_anz, ind0, len, ok_flag;
int  write_flag, read_flag, quit_allowed, abort_flag, quit_mode;

/* for dez + hex input */
int  help_int, help_int2, help_int3, num;
long help_long;
char komma;

#if (WITH_HEX_FIND)
char c1, c2;
#endif

/* for Find/Replace */
long new_index, old_index, delt_bi;
size_t len1, len2;
int    replace_flag, direction;
static int all_flag, first_call, last_call, abort;
static char str_help [BUF_256];

/* for Jump */
static int  new_col;
static long new_line;

/* for Get */
char FA_HU *file_buf;
long file_length;

/* for Calc */
CALC_RESULT calc_result;


   end_of_edit = 0;

   switch (mode_flag)
   {
      case 1:    /* insert   */
         switch (key_0)
         {
            case 0x1b:   /* <esc> */
            case 0x03:   /* ^C    */
               mode_flag = 0;
               line_2_flag = 1;
               break;

            case 0x12:   /* ^R */
               key_1 = get_hex_value ();
               if (key_1 >= 0)
               {
                  perform_key_insert (key_1, 0);
                  fc->change_flag = 1;
               }

               if (key_1 == -3)  /* ^C entered */
               {
                  mode_flag = 0;
                  line_2_flag = 1;
               }
               break;

            case 0x0e:   /* ^N */
            case 0x13:   /* ^S */
            case 0x16:   /* ^V */
               perform_special_keys (key_0, mode_flag);
               break;

            default:
               if (!check_for_macro (key_0, repeat_max))
               {
                  if ((key_0 == 0x09) && (set.notab == 1))
                  {
                     tab_diff = set.tabs - (fc->column % set.tabs);
                     for (ii = 0 ; ii < tab_diff ; ii++)
                     {
                        perform_key_insert (' ', 0);
                     }
                  }
                  else
                  {
                     perform_key_insert (key_0, 1);
                  }
                  fc->change_flag = 1;

                  check_for_autonl ();
               }
               break;
         }
         break;

      case 2:    /* exchange */
         switch (key_0)
         {
            case 0x1b:   /* <esc> */
            case 0x03:   /* ^C    */
               mode_flag = 0;
               line_2_flag = 1;
               break;

            case 0x12:   /* ^R */
               key_1 = get_hex_value ();
               if (key_1 >= 0)
               {
                  perform_key_exchange (key_1, 0);
                  fc->change_flag = 1;
               }

               if (key_1 == -3)  /* ^C entered */
               {
                  mode_flag = 0;
                  line_2_flag = 1;
               }
               break;

            case 0x0e:   /* ^N */
            case 0x13:   /* ^S */
            case 0x16:   /* ^V */
               perform_special_keys (key_0, mode_flag);
               break;

            default:
               if (!check_for_macro (key_0, repeat_max))
               {
                  if ((key_0 == 0x09) && (set.notab == 1))
                  {
                     tab_diff = set.tabs - (fc->column % set.tabs);
                     for (ii = 0 ; ii < tab_diff ; ii++)
                     {
                        perform_key_exchange (' ', 0);
                     }
                  }
                  else
                  {
                     perform_key_exchange (key_0, 1);
                  }
                  fc->change_flag = 1;
               }
               break;
         }
         break;

      case 0:    /* command  */
         switch (toupper (key_0))    /* switch (toupper (key_0)) : KEY_F1 ==> error */
         {
            case 'H':    /* Hex Input, Output */
               LOCK_WHEN_BUFFER_ACTIVE
               line_2_flag = 1;

               if (repeat_count == 0)
               {
                  show_status_line_2 ("Hex: Input Output Stdout Find View Edit",
                                                                       0, -1, 0);
                  key_1 = toupper(get_1_key (1));
               }

#if (WITH_HEX_FIND)
               if (key_1 != 'F')
#endif
                  end_of_edit = -2;

               switch (key_1)
               {
                  case 'I':
                     LOCK_WHEN_VIEW_ONLY
                     str_numb [0] = '\0';
                     do_it = get_line_2_string ("Hex Input:",
                                                str_numb, C_R, ID_NUMB);
                     if (do_it)
                     {
                        if ((sscanf (str_numb, "%x", &help_int)) == 1)
                        {
                           perform_key_insert (help_int, 0);
                           fc->change_flag = 1;
                        }
                        else
                        {
                           err_message (INVALID_HEX_VALUE);
                        }
                     }
                     break;               

                  case 'O':
                     line_2_flag = 2;
                     sprintf (string, "Hex Output: 0x%02x",
                                       (((byte) *fc->buffer) & 0xff));
                     show_status_line_2 (string, 0, -2, 1);
                     break;

                  case 'S':
                     str_numb [0] = '\0';
                     do_it = get_line_2_string ("Hex as string to Stdout:",
                                                str_numb, C_R, ID_NUMB);
                     if (do_it)
                     {
                        ii = 0;
                        while ((sscanf (&str_numb[ii], "%2x", &help_int)) >= 1)
                        {
                           printf ("%c", (char) (help_int & 0xff));
                           ii += 2;
                           if (str_numb[ii] == ' ')
                             ii++;
                        }
                     }
                     break;               

#if (WITH_HEX_FIND)
                  case 'F':
                     if (repeat_count == 0)
                     {
                        do_it = get_line_2_string ("Hex Find (hexval_1 [hexval_2]):",
                                                   str_numb, C_R, ID_NUMB);
                        if (!do_it)
                        {
                           end_of_edit = -1;
                           break;
                        }
                     }
                     BREAK_IF_REPEAT_0
      
                     if ((repeat_count == 0) || (repeat_max == 1))
                     {
                        find_count = 0;
                        replace_count = -1;
                        first_call = 1;
                     }
                     else
                     {
                        first_call = 0;
                     }
      
                     if ((num = sscanf (str_numb, "%x %x",
                                        &help_int, &help_int2)) < 1)
                     {
                        err_message (INVALID_HEX_VALUE);
                        break;
                     }

                     c1 = (char) help_int;
                     if (num >= 2) c2 = (char) help_int2;
                              else c2 = c1;

#if (EXCHANGE_HEX_CHARS)
                     if (c1 > c2)
                        exchange_chars (&c1, &c2);
#endif

                     new_index = perform_find_byte (c1, c2);
                     save_find_indizes (1, new_index, 1);

                     if (new_index < 0L)
                     {
                        find_ok = 0;
                        replace_count = -1;
                        end_of_edit = -1;
                     }
                     else
                     {
                        find_ok = 1;
                        find_count++;
      
                     /* zeiger bewegen */
                        perform_move (new_index);
                     }
      
                  /* letzter durchlauf ? */
                     last_call = ((repeat_count >= (repeat_max - 1)) ||
                                  (find_ok == 0));
                     abort = show_find_display (key_1, 0, 0, 
                                                first_call, last_call, find_ok);
                     if (abort)
                        end_of_edit = -1;
      
                     if (last_call)
                        show_find_result (str_numb, find_count, replace_count);
                     break;               
#else
                  case 'F':
                     err_message (NOT_IMPLEMENTED);
                     break;               
#endif

#if (WITH_HEX_VIEW)
                  case 'V':
                     hex_view ();
                     perform_view ();
                     break;

                  case 'E':
                     LOCK_WHEN_VIEW_ONLY
                     hex_edit ();
                     perform_view ();
                     break;
#else
                  case 'V':
                  case 'E':
                     err_message (NOT_IMPLEMENTED);
                     break;
#endif
                  case 0x1b:  /* <esc> */
                  case 0x03:  /* ^C    */
                     break;   /* do nothing */

                  default:
                     err_message (ILLEGAL_COMMAND);
                     break;
               }
               break;

            case 'I':              /* Insert */
               end_of_edit = -2;
               LOCK_WHEN_BUFFER_ACTIVE   LOCK_WHEN_VIEW_ONLY
               mode_flag = 1;
               line_2_flag = 1;
               break;

            case 'X':              /* eXchange */
               end_of_edit = -2;
               LOCK_WHEN_BUFFER_ACTIVE   LOCK_WHEN_VIEW_ONLY
               mode_flag = 2;
               line_2_flag = 1;
               save_x.index = 0;
               break;

            case 'Q':              /* Quit */
               quit_mode = 1;
               while (quit_mode)
               {
                  end_of_edit = -2;
                  LOCK_WHEN_BUFFER_ACTIVE
                  line_2_flag = 1;

               /* display status line 1 + 2 */
                  show_status_line_1 (fc->filename, fc);
                  if (fc->view_only)
                     show_status_line_2 
                        ("Quit:Abort      Init        Write <esc>", 0, -1, 0);
                  else
                     show_status_line_2 
                        ("Quit:Abort Exit Init Update Write <esc>", 0, -1, 0);
   
                  key_1 = toupper(get_1_key (1));
                  switch (key_1)
                  {
                     case 'E':
                        LOCK_WHEN_VIEW_ONLY
                        if (fc->change_flag)
                        {
                           line_2_flag = 2;
                           write_flag = write_datafile (fc->filename,
                                                        fc->buff_0, fc->byte_anz,
                                                        1, set.bak_file);
                           if (write_flag == 0)    /* 0, if write ok */
                              fc->change_flag = 0;

                           if (write_flag == -10)  /* -10, if aborted with ^C */
                           {
                              quit_mode = 0;
                              line_2_flag = 1;
                              break;               /* --> */
                           }
                        }
                        else
                        {
                           write_flag = 0;
                        }
                        /* no break !! fall through to case 'A' */
   
                     case 'A':
                     /* before Abort, check all files for modifications */
                        quit_allowed = 1;
                        abort_flag = 0;
                        for (ii = 0 ; ii < MAX_FC_NUM ; ii++)
                        {
                           if (fc->change_flag)
                           {
                              err_message (MODIFIED_ABORT_ANYWAY);
                              key_2 = get_1_key (0);
                              switch (toupper (key_2))
                              {
                                 case 'W':
                                    line_2_flag = 2;
                                    write_flag = write_datafile (fc->filename,
                                                        fc->buff_0, fc->byte_anz,
                                                        1, set.bak_file);
                                    if (write_flag == 0)
                                       fc->change_flag = 0;  /* write o.k. */
                                    else
                                       quit_allowed = 0;     /* write error */

                                    line_2_flag = 1;
                                    break;
   
                                 case 'Y':
                                    fc->change_flag = 0;
                                    break;
   
                                 default:              /* wg. Peter Stoeckigt */
                                    ii = MAX_FC_NUM;   /* abort for loop */
                                    quit_allowed = 0;
                                    abort_flag = 1;
                                    break;
                              }
                           }
   
                        /* check next file */
                           if (!abort_flag)
                           {
                              exchange_file_control (MAX_FC_NUM, 1);
                              if (fc->change_flag)
                              {
                              /* display file buffer */
                                 perform_view ();

#if 0                         /* ueberfluessig */
                              /* display status line 1 */
                                 show_status_line_1 (fc->filename, fc);
#endif
                              }
                           }
                           
                        }  /* for ii */
   
                     /* all files o.k. ? */
                        if (quit_allowed)
                        {
                           end_of_edit = 1;
                        }
                        else
                        {
                        /* display file buffer */
                           perform_view ();

                        /* display status line 1 */
                           show_status_line_1 (fc->filename, fc);
                        }
                        quit_mode = 0;
                        break;
   
                     case 'I':
                     /* take over the actual filename */
                        if (first == 0)
                        {
                           first = 1;
                           memcpy (str_q_i1, fc->filename, sizeof (fc->filename));
                        }
   
                     /* test edit buffer */
                        read_flag = 1;
                        if (fc->change_flag)
                        {
                           err_message (MODIFIED_ABORT_ANYWAY);
                           key_2 = get_1_key (0);
                           read_flag = 0;
                           switch (toupper (key_2))
                           {
                              case 'W':
                                 line_2_flag = 1;
                                 write_flag = write_datafile (fc->filename,
                                                     fc->buff_0, fc->byte_anz,
                                                     1, set.bak_file);
   
                                 if (write_flag != 0)      /* 0, if write ok */
                                    break;
                                 else
                                    fc->change_flag = 0;
                                 /* fall through */

                              case 'Y':
                                 read_flag = 1;
                                 break;
   
                              default:
                                 /* read_flag = 0;   @@ ueberfluessig */
                                 break;
                           }
                        }
   
                        if (read_flag == 1)
                        {
                           do_it = get_line_2_string ("Read Filename:",
                                                      str_q_i1, C_R, ID_FILE);
                           if (!do_it)
                           {
                              quit_mode = 0;
                              break;
                           }
                           fc->change_flag = 0;
                           init_file_control (fc, 1);
   
                           memcpy (str_q_i2, str_q_i1, sizeof(str_q_i2));
   
                           fc->view_only = parse_input_string (str_q_i2);
   
                           memcpy (fc->filename, str_q_i2, sizeof(fc->filename));
                           fc->filename [sizeof(fc->filename)-1] = '\0';
   
                           if ((*fc->filename == ' ') ||
                               (*fc->filename == '\0'))
                           {
                              check_and_increase_buffer (fc, INIT_FILESIZE,
                                                         0L, 1);
                           }
                           else
                           {
                           /* read datafile */
                              ok_flag = get_1_datafile ();
                           }
                           update_entire_window (fc->top_left);
#if WINDOW_COMMAND
                           window_set (1);
#endif
                        }
                        quit_mode = 0;
                        break;
   
                     case 'W':
                        do_it = get_line_2_string ("Write Filename:",
                                                   str_q_wr, C_R, ID_FILE);
                        if (!do_it)
                        {
                           quit_mode = 0;
                           break;
                        }
                        line_2_flag = 2;
                        write_flag = write_datafile (str_q_wr, fc->buff_0,
                                                     fc->byte_anz, 0, 0);
                        if (write_flag == 0)    /* 0, if write ok */
                           fc->change_flag = 0;
                        break;
   
                     case 'U':
                        LOCK_WHEN_VIEW_ONLY
                        line_2_flag = 2;
                        write_flag = write_datafile (fc->filename,
                                                     fc->buff_0, fc->byte_anz,
                                                     1, set.bak_file);
                        if (write_flag == 0)    /* 0, if write ok */
                           fc->change_flag = 0;

                        if (write_flag == -10)  /* -10, if aborted with ^C */
                        {
                           quit_mode = 0;
                           line_2_flag = 1;
                        }
                        break;
   
                     case 0x1b:  /* <esc> */
                     case 0x03:  /* ^C    */
                        quit_mode = 0;
                        break;
   
                     default:
                        err_message (ILLEGAL_COMMAND);
                        break;
                  }
               }
               break;

            case 'S':             /* Set */
               end_of_edit = -2;
               LOCK_WHEN_BUFFER_ACTIVE
               line_2_flag = 1;
               show_status_line_2 ("Set: AB CD EF HI KL MN OR ST VW Y *~", 0, -1, 0);

               key_1 = toupper(get_1_key (1));
               switch (key_1)
               {
                  case 'A':
                     show_status_line_2 ("Insert <nl> automatically [Y/N]",
                                                                    0, -1, 0);
                     key_2 = get_1_key (1);
                     set.autonl = (toupper (key_2) == 'Y');
                     break;

                  case 'B':
                     show_status_line_2 ("Bak_file [Y/N]", 0, -1, 0);
                     key_2 = get_1_key (1);
                     set.bak_file = (toupper (key_2) == 'Y');
                     break;

                  case 'C':
                     show_status_line_2 ("Consider Case [Y/N]", 0, -1, 0);
                     key_2 = get_1_key (1);
                     set.c_case = (toupper (key_2) == 'Y');
                     break;

                  case 'D':
                     show_status_line_2 ("Display Macro Execution [Y/N]", 
                                          0, -1, 0);
                     key_2 = get_1_key (1);
                     set.display = (toupper (key_2) == 'Y');
                     break;

#if (WITH_E_DELIMIT)
                  case 'E':
                     do_it = get_line_2_string ("Delimiter Set:",
                                                fc->e_delimit, C_R, ID_DELI);
                     if (do_it)
                     {
                        normalize_delims ();
                        perform_view ();
                     }
                     break;
#endif

                  case 'F':
                     sprintf (str_numb, "%d", set.file_num);
                     do_it = get_line_2_string ("File number:",
                                                str_numb, C_R, ID_NUMB);
                     if (do_it)
                     {
                        if ((sscanf (str_numb, "%d", &help_int)) == 1)
                        {
                           set.file_num = help_int;
                           set.file_num = max (1,     /* minimum 1 file !! */
                                          min (MAX_FC_NUM, set.file_num));
                        }
                        else
                        {
                           err_message (INVALID_INPUT_VALUE);
                        }
                     }
                     break;

                  case 'H':
                     show_status_line_2 ("Display Highbit Characters as is [Y/N/A]",
                                                                    0, -1, 0);
                     key_2 = get_1_key (1);
 				     /* default */              set.highbit_global = 0;  /* No   */
                     if (toupper(key_2) == 'Y') set.highbit_global = 1;  /* Yes  */
                     if (toupper(key_2) == 'A') set.highbit_global = 2;  /* Auto */
					 set_highbit();
#if 0
                     update_entire_window (fc->top_left);
                     perform_update (fc->buff_0, fc->byte_anz,
                                     fc->left_col);
#else
                     perform_view ();
#endif
                     break;

                  case 'I':
                     show_status_line_2 ("Auto indent during insert [Y/N]",
                                                                    0, -1, 0);
                     key_2 = get_1_key (1);
                     set.indent = (toupper (key_2) == 'Y');
                     break;

                  case 'K':
                     show_status_line_2 ("Find only token strings [Y/N]",
                                                                  0, -1, 0);
                     key_2 = get_1_key (1);
                     set.k_token = (toupper (key_2) == 'Y');
                     break;

                  case 'L':
                     sprintf (str_numb, "%d", fc->left_col);
                     do_it = get_line_2_string ("Left column:",
                                                str_numb, C_R, ID_NUMB);
                     if (do_it)
                     {
                        if ((sscanf (str_numb, "%d", &help_int)) == 1)
                        {
                           if ((*str_numb == '+') || 
                               (*str_numb == '-'))
                              fc->left_col += help_int;
                           else
                              fc->left_col = help_int;
                        }
                        else
                        {
                           err_message (INVALID_INPUT_VALUE);
                        }
                     }
                     fc->left_col = max (0, fc->left_col);
                     update_entire_window (fc->top_left);
                     break;

                  case 'M':
                     sprintf (str_numb, "%d, %d, %d", set.margin[0],
                                                      set.margin[1],
                                                      set.margin[2] );
                     do_it = get_line_2_string ("Margin (Indent, Left, Right):",
                                                str_numb, C_R, ID_MARG);
                     if (do_it)
                     {
                        help_int  = set.margin[0];
                        help_int2 = set.margin[1];
                        help_int3 = set.margin[2];

                        num = sscanf (str_numb, "%d %c %d %c %d",
                                                            &help_int,
                                                            &komma,
                                                            &help_int2,
                                                            &komma,
                                                            &help_int3 );
                        if ((num < 1) ||
                            (help_int3 <= help_int) ||
                            (help_int3 <= help_int2))
                        {
                           err_message (INVALID_INPUT_VALUE);
                        }
                        else
                        {
                                         set.margin[0] = help_int;
                           if (num >= 2) set.margin[1] = help_int2;
                           if (num >= 3) set.margin[2] = help_int3;
                        } 
                     }
                     break;

                  case 'N':
                     show_status_line_2 ("Insert blanks for tabs [Y/N]",
                                                                 0, -1, 0);
                     key_2 = get_1_key (1);
                     set.notab = (toupper (key_2) == 'Y');
                     break;

                  case 'O':
                     show_status_line_2 ("set file to view Only [Y/N]",
                                                                 0, -1, 0);
                     key_2 = get_1_key (1);
                     fc->view_only = (toupper (key_2) == 'Y');
                     break;

                  case 'R':
                     show_status_line_2
                        ("Radix : Alpha Binary Decimal Hex Octal", 0, -1, 0);
                     key_2 = toupper (get_1_key (1));
                     switch (key_2)
                     {
                        case 'A':
                        case 'B':
                        case 'D':
                        case 'H':
                        case 'O':
                           set.radix = key_2;
                           break;

                        default:
                           err_message (INVALID_RADIX);
                           break;
                     }
                     break;

                  case 'S':
                     show_status_line_2 ("Show Find: [Y/N]", 0, -1, 0);
                     key_2 = get_1_key (1);
                     set.showfind = (toupper (key_2) == 'Y');
                     break;

                  case 'T':
                     sprintf (str_numb, "%d", set.tabs);
                     do_it = get_line_2_string ("Tabs:",
                                                str_numb, C_R, ID_NUMB);
                     if (do_it)
                     {
                        if ((sscanf (str_numb, "%d", &help_int)) == 1)
                        {
                           set.tabs = help_int;
                           set.tabs = max (1, min (COLUMNS, set.tabs));
                           update_entire_window (fc->top_left);
                           check_dirty_cursor ();
                        }
                        else
                        {
                           err_message (INVALID_INPUT_VALUE);
                        }
                     }
                     break;

                  case 'V':
                     sprintf (str_numb, "%d", (set.viewrow + LINE_OFFSET));
                     do_it = get_line_2_string ("View row:",
                                                str_numb, C_R, ID_NUMB);
                     if (do_it)
                     {
                        if ((sscanf (str_numb, "%d", &help_int)) == 1)
                        {
                           set.viewrow = help_int -  LINE_OFFSET;
                           set.viewrow = max (0, min (MAX_ROW, set.viewrow));
                           perform_view ();
                        }
                        else
                        {
                           err_message (INVALID_INPUT_VALUE);
                        }
                     }
                     break;

                  case 'W':
                     show_status_line_2 ("Warning beep level: [0-2]", 0, -1, 0);
                     key_2 = get_1_key (1);
                     set.warning = key_2 - '0';
                     set.warning = max (0, min (2, set.warning));
                     break;

                  case 'Y':
#if (WITH_SYNTAX_HIGHLIGHTING)
                     sprintf (str_numb, "%d,%d", fc->syntax_flag,
                                                 fc->file_type);
                     do_it = get_line_2_string ("sYntax highlighting: [0-7,filetype]",
                                                str_numb, C_R, ID_MARG);
                     if (do_it)
                     {
                        help_int  = fc->syntax_flag;
                        help_int2 = fc->file_type;

                        num = sscanf (str_numb, "%d %c %d", &help_int,
                                                            &komma,
                                                            &help_int2 );
                        if (num < 1)
                        {
                           err_message (INVALID_INPUT_VALUE);
                        }
                        else
                        {
                                         fc->syntax_flag = help_int;
                           if (num >= 2) fc->file_type   = help_int2;
                        } 
                     }
                     fc->syntax_flag &= 0x07;
			         fc->e_delimit = get_hi_light_delimiters(fc->file_type);
                     update_entire_window (fc->top_left);
#else
                     err_message (NOT_IMPLEMENTED);
#endif
                     break;

                  case '*':
                     show_status_line_2 ("Search with Wildcards (?*): [Y/N]",
                                                                      0, -1, 0);
                     key_2 = get_1_key (1);
                     set.wildcards = (toupper (key_2) == 'Y');
                     break;

                  case '~':
                     show_status_line_2 ("Replace \'~\' with HOME DIR: [Y/N]",
                                                                      0, -1, 0);
                     key_2 = get_1_key (1);
                     set.tilde_home = (toupper (key_2) == 'Y');
                     break;

                  case 0x1b:  /* <esc> */
                  case 0x03:  /* ^C    */
                     break;   /* do nothing */

                  default:
                     err_message (ILLEGAL_COMMAND);
                     break;
               }
               break;

            case 'F':             /* Find */
            case '-':             /* -find */
               line_2_flag = 1;

               if (repeat_count == 0)
               {
                  if (key_0 == '-')
                     do_it = get_line_2_string ("-Find:", str_find,
                                                -1, ID_FIND);
                  else
                     do_it = get_line_2_string ("Find:" , str_find,
                                                -1, ID_FIND);
                  if (!do_it)
                  {
                     end_of_edit = -1;
                     break;
                  }
               }
               BREAK_IF_REPEAT_0

               if ((repeat_count == 0) || (repeat_max == 1))
               {
                  find_count = 0;
                  replace_count = -1;
                  first_call = 1;
               }
               else
               {
                  first_call = 0;
               }

               direction = (toupper (key_0) == 'F');
               new_index = perform_find (direction,
                                         str_find, first_call, &len1);
               save_find_indizes (direction, new_index, len1);

               if (new_index < 0L)
               {
                  find_ok = 0;
                  end_of_edit = -1;
               }
               else
               {
                  find_ok = 1;
                  find_count++;

               /* zeiger bewegen */
                  perform_move (new_index);
               }

            /* letzter durchlauf ? */
               last_call = ((repeat_count >= (repeat_max - 1)) ||
                            (find_ok == 0));
               abort = show_find_display (key_0, 0, 0, 
                                          first_call, last_call, find_ok);
               if (abort)
                  end_of_edit = -1;

               if (last_call)
                  show_find_result (str_find, find_count, replace_count);
               break;

            case 'R':             /* Replace */
            case '?':
               LOCK_WHEN_BUFFER_ACTIVE   LOCK_WHEN_VIEW_ONLY
               line_2_flag = 1;

               if (repeat_count == 0)
               {
               /* str_help, damit auch 'R' "^SR" with "^ST" funktioniert : */
                  memcpy (str_help, str_find, sizeof(str_help));
               
                  if (key_0 == '?')
                     do_it = get_line_2_string ("?Replace:", str_help,
                                                -1, ID_FIND);
                  else
                     do_it = get_line_2_string ("Replace:", str_help,
                                                -1, ID_FIND);
                  if (!do_it)
                  {
                     end_of_edit = -1;
                     break;
                  }

                  do_it = get_line_2_string ("with   :", str_repl,
                                             -1, ID_REPL);
                  if (!do_it)
                  {
                     end_of_edit = -1;
                     break;
                  }

                  memcpy (str_find, str_help, sizeof(str_find));

               /* is there any <lf> in one of the strings ? */
                  lf_strings = string_with_eol (str_find) |
                               string_with_eol (str_repl);
               }
               BREAK_IF_REPEAT_0

            /* display auch bei macro execute aktivieren */
               if (key_0 == '?')
                  set.display |= 0x02;

               if ((repeat_count == 0) || (repeat_max == 1))
               {
                  find_count = 0;
                  replace_count = 0;
                  all_flag = 0;
                  first_call = 1;
               }
               else
               {
                  first_call = 0;
               }

               new_index = perform_find (1, str_find, 
                                        (first_call || (key_0 == '?')), &len1);

               save_find_indizes (1, new_index, len1);

#if 0
            /* ?Replace --> Replace (question has been switched off) */
               if (all_flag)
                  key_0 = 'R';
#endif

               if (new_index < 0L)
               {
                  find_ok = 0;
                  end_of_edit = -1;
               }
               else
               {
                  find_ok = 1;
                  find_count++;

               /* perform_replace */
               /* len1 = strlen (str_find); wird in comm_find bestimmt !! */
                  len2 = strlen (str_repl);
                  delta = len2 - len1;

               /* passt neuer string noch mit rein ? */
                  if (check_and_increase_buffer (fc,
                                                 (fc->byte_anz + delta),
                                                  FILE_RESERVE, 0) < 0)
                  {                      /* nein ! */
                     end_of_edit = -1;

                  /* zeiger bewegen */
                     perform_move (new_index);

                  /* ggf. zeigen */
                     if (fc->lrow >= MAX_ROW)
                        perform_view ();

                     err_message (BUFFER_OVERFLOW);
                  }
                  else
                  {
                  /* save old position */
                     old_index = fc->byte_index;
                        
                  /* ersetzen mit nachfrage ? */
                     if ((key_0 != '?') || (all_flag))
                     {
                        replace_flag = 1;
                     }
                     else
                     {
                     /* zeiger bewegen */
                        perform_move (new_index);

                     /* ggf. zeigen */
                        if (fc->lrow >= MAX_ROW)
                           perform_view ();
                        else
                           if (set.wildcards)
                           {
                              update_entire_window (fc->top_left);
                              perform_update (fc->buff_0, fc->byte_anz,
                                              fc->left_col);
                           }

                     /* abfragen, ob loeschen erlaubt */
                        show_status_line_1 (get_line_1_text (), fc);
                        show_status_line_2 ("Replace ? [Y/N/A]", 0, -1, 0);
                        set_cursor_to (fc->lrow, REL_COLUMN); /* stelle zeigen */

                        key_2 = get_1_key (0);

                        switch (toupper (key_2))
                        {
                           case 'A':
                              all_flag = 1;
                              /* fall through */

                           case 'Y':
                              replace_flag = 1;
                              break;

                           case 0x03:  /* ^C */
                              end_of_edit = -1;       /* Quit Replace Mode */
                              /* fall through */

                           default:
                              replace_flag = 0;
                              break;
                        }
                     }  /* if key_0 == '?'  */

                  /* jetzt aber wirklich ! */
                     if (replace_flag)
                     {
                     /* restore old position */
                        perform_move (old_index);

                        replace_count++;

                     /* new_index = zeiger hinter gef. string, */
                     /* setzen hinter ende des ersatz-strings  */
                        new_index += delta;
   
                     /* buffer um delta verschieben */
                        memcpy_rev (&fc->buff_0 [new_index],
                                    &fc->buff_0 [new_index - delta],
                                    (fc->byte_anz - (new_index - delta) + 1));

                        fc->byte_anz += delta;

                     /* ersatz-string einschieben */
                        { /* MS-C 6.00A ist zu doof fuer diesen befehl */ 
                          long help = new_index - len2;
                          
                          memcpy (&fc->buff_0 [help],
                                  str_repl, len2);
                        }

                     /* wg. kompatibilitaet zu AEDIT */
                        check_tag_index ((new_index - len2), -(long) len1);
                        check_tag_index ((new_index - len2),  (long) len2);
   
                     /* zeiger steht noch hinter ende des neuen strings */
                        perform_move (new_index);
      
                        save_find_indizes (1, new_index, len2);

                     /* anzahl lines wieder restaurieren */
                        fc->line_anz -= get_total_lines (
                                            (char FA_HU *) str_find,
                                             0L, (long) strlen (str_find));
                                                /* hier ^ nicht len1 !! */
                        fc->line_anz += get_total_lines (
                                            (char FA_HU *) str_repl,
                                             0L, (long) len2);
                        fc->change_flag = 1;
                     }  /* if replace_flag */
                  }  /* kein buffer overflow */
               }  /* if new_index >= 0L */

            /* letzter durchlauf ? */
               last_call = ((repeat_count >= (repeat_max - 1)) ||
                            (find_ok == 0));
               abort = show_find_display (key_0, all_flag, lf_strings,
                                          first_call, last_call, find_ok);
               if (abort)
                  end_of_edit = -1;

               if (last_call)
                  show_find_result (str_find, find_count, replace_count);

            /* display status restaurieren */
               set.display &= ~0x02;
               break;

            case 0x1b:   /* <esc> : switch off 'B'/'D', if active */
            case 0x03:   /* ^C    */
               end_of_edit = -2;
               line_2_flag = 1 + (get_macro_status () == MACRO_EXECUTE);
               if (save_d.toggle)
               {
                  save_d.toggle = 0;
                  view_or_update ();
               }
               break;

            case 'D':   /* Delete */
               LOCK_WHEN_VIEW_ONLY
               /* no break !! fall through to case 'B' */

            case 'B':   /* Buffer */
               end_of_edit = -2;
               line_2_flag = 1;

               if (save_d.toggle == 0)    /* 1. command */
               {
                  save_d.toggle = 1;
                  save_d.index0 = fc->byte_index;
                  update_this_line (fc->lin_left, fc->lrow);
               }
               else
               {
                  save_d.toggle = 0;

               /* save it */
                  save_d.index1 = fc->byte_index;
                  len  = labs (save_d.index0 - save_d.index1);
                  if (block_save (fc->buff_0, save_d.index0, save_d.index1))
                  {
                     end_of_edit = -1;
                     err_message (OUT_OF_MEMORY);
                  }
                  else
                  {
                     sprintf (string, "*** buffer saved (%ld Bytes) ***", len);
                     show_status_line_2 (string, 0, -2, 0);
                  }
                  line_2_flag = 2;

               /* delete ? */
                  if (toupper (key_0) == 'D')
                  {
                     new_index = min (save_d.index0, save_d.index1);
                     perform_move (new_index);

                  /* anzahl lines wieder restaurieren */
                     fc->line_anz -= get_total_lines (&fc->buff_0 [new_index],
                                                      0L, len);

                     delt_bi = block_remove (fc->buff_0,
                                             save_d.index0,
                                             save_d.index1,
                                             fc->byte_anz);
                     fc->byte_anz -= delt_bi;
                     check_tag_index (fc->byte_index, -delt_bi);

                     fc->change_flag = 1;
                  }
                  check_dirty_cursor ();

                  if (fc->line_index >= fc->line_anz)
                     view_or_update ();
                  else
                     update_entire_window (fc->top_left);
               }
               break;

            case 'G':   /* Get file or saved buffer */
               LOCK_WHEN_BUFFER_ACTIVE   LOCK_WHEN_VIEW_ONLY
               line_2_flag = 1;
               if (repeat_count == 0)
               {
                  do_it = get_line_2_string ("Get:<cr>,<filename>", str_getf,
                                             C_R, ID_FILE);
                  if (!do_it)
                  {
                     end_of_edit = -1;
                     break;
                  }
               }
               BREAK_IF_REPEAT_0

               if (*str_getf)
               {                          /* read from file */
                  file_length = get_file_length (str_getf, 1);
                  if (file_length > 0)
                  {
                     file_buf = loc_malloc (file_length);
                     if (file_buf == NULL)
                     {
                        end_of_edit = -1;
                        err_message (OUT_OF_MEMORY);
                     }
                     else
                     {
                        read_anz = read_datafile (str_getf, file_buf,
                                                  file_length, 1);
                        if (read_anz >= 0)
                        {
                        /* einfuegen in buffer */
                           if (check_and_increase_buffer (fc,
                                                         (fc->byte_anz + read_anz),
                                                          FILE_RESERVE, 0) < 0)
                           {                      /* nein ! */
                              end_of_edit = -1;
                              err_message (BUFFER_OVERFLOW);
                           }
                           else
                           {
                              delt_bi = block_insert (fc->buff_0, fc->byte_index,
                                                      fc->byte_anz, fc->buffer_size,
                                                      file_buf, (long) read_anz);
                              if (delt_bi < 0L)
                              {
                                 end_of_edit = -1;
                                 err_message (FATAL_ERROR);
                              }
                              else
                              {
                                 fc->byte_anz += read_anz;
                                 check_tag_index (fc->byte_index, read_anz);
      
                              /* anzahl lines wieder restaurieren */
                                 fc->line_anz = get_total_lines (fc->buff_0, 0L,
                                                                fc->byte_anz);
                                 fc->change_flag = 1;
                                 view_or_update ();
                              }
                           }
                        }
                     }
                     loc_free (file_buf);
                  }  /* file_buf != NULL */
               }
               else
               {                          /* read from buffer */
                  delt_bi = block_restore (fc);
                  if (delt_bi >= 0L)
                  {
                     fc->byte_anz += delt_bi;
                     check_tag_index (fc->byte_index, delt_bi);

                  /* anzahl lines wieder restaurieren */
                     fc->line_anz += get_total_lines (
                                            (char FA_HU *) get_save_buffer (),
                                                       0L, get_save_length ());
                  }
                  else
                  {
                     end_of_edit = -1;
                     err_message (BUFFER_OVERFLOW);
                  }

                  fc->change_flag = 1;
                  view_or_update ();
               }
               break;

            case 'V':   /* View */
               end_of_edit = -2;
               check_dirty_cursor ();

#if ((WITH_WINCH) && ((ACT_OP_SYSTEM == SCO_UNIX) || !(UNIX)))
               set_window_size ();
#endif
               perform_view ();
               break;

            case 'O':   /* Other forward */
               LOCK_WHEN_BUFFER_ACTIVE
               end_of_edit = -2;

#if WINDOW_COMMAND
               window_set (1);
#endif
            /* get other work buffer */
               if (get_next_file_buffer (1))
               {
 			      set_highbit();
                  check_dirty_cursor ();
#if WINDOW_COMMAND
                  window_set (2);
#endif
                  perform_view ();
               }
               break;

            case ALT_O: /* Other backward */
               LOCK_WHEN_BUFFER_ACTIVE
               end_of_edit = -2;

#if WINDOW_COMMAND
               window_set (1);
#endif
            /* get other work buffer */
               if (get_next_file_buffer (-1))
               {
			      set_highbit();
                  check_dirty_cursor ();
#if WINDOW_COMMAND
                  window_set (2);
#endif
                  perform_view ();
               }
               break;

            case 'J':   /* Jump */
               end_of_edit = -2;
               line_2_flag = 1;
               show_status_line_2 ("Jump:A B C D Start End Line Posit",
                                    0, -1, 0);

               key_1 = toupper(get_1_key (1));
               if ((key_1 >= 'A') && (key_1 <= 'D'))
               {
                  new_index = fc->tag_index [key_1 - 'A'];
                  if (new_index >= 0)
                  {
                     perform_move (new_index);
                     view_or_update ();
                  }
                  else
                  {
                     err_message (NO_SUCH_TAG);
                  }
               }
               else
               {
                  switch (key_1)
                  {
                     case 'S':
                        perform_move (0L);
                        break;
   
                     case 'E':
                        new_index = fc->byte_anz;
                        perform_move (new_index);
                        break;
   
                     case 'L':
                        sprintf (str_numb, "%ld", new_line + LINE_OFFSET);
                        do_it = get_line_2_string ("Line:",
                                                   str_numb, C_R, ID_NUMB);
                        if (do_it)
                        {
                           if ((sscanf (str_numb, "%ld", &help_long)) == 1)
                           {
                              new_line = help_long - LINE_OFFSET;
                              new_line = max (0L, min (fc->line_anz, new_line));
                              new_index= line_to_index (fc->buff_0, 0L,
                                           fc->byte_anz, new_line);
                              if (new_index < 0L)       /* behind EOF */
                                 new_index = fc->byte_anz;  /* set to EOF */
                              perform_move (new_index);
                              view_or_update ();
                           }
                           else
                           {
                              err_message (INVALID_INPUT_VALUE);
                           }
                        }
                        break;
   
                     case 'P':
                        sprintf (str_numb, "%d", new_col);
                        do_it = get_line_2_string ("Position:",
                                                   str_numb, C_R, ID_NUMB);
                        if (do_it)
                        {
                           if ((sscanf (str_numb, "%d", &help_int)) == 1)
                           {
                              new_col = help_int;
                              new_col = max (0, new_col);
                              new_index = act_index (fc->buff_0, fc->lin_left,
                                                     fc->byte_anz, new_col);
                              perform_move (new_index);
                              /* check_dirty_cursor (); */   /* @@ */
                           }
                           else
                           {
                              err_message (INVALID_INPUT_VALUE);
                           }
                        }
                        break;

                     case 0x1b:  /* <esc> */
                     case 0x03:  /* ^C    */
                        break;   /* do nothing */

                     default:
                        err_message (ILLEGAL_COMMAND);
                        break;
                  }
               }
               break;

            case 'P':   /* Paragraph or Put */
               if (save_d.toggle == 0)          /* Paragraph */
               {
#if PARAGR_COMMAND
                  LOCK_WHEN_VIEW_ONLY
                  BREAK_IF_REPEAT_0

                  line_2_flag = 1;

                  if (repeat_count == 0)
                  {
                     show_status_line_2 ("Paragraph: Fill Justify", 0, -1, 0);
                     key_1 = toupper(get_1_key (1));
                  }

                  switch (key_1)
                  {
                     case 'F':
                        end_of_edit = para_fill ();
                        fc->change_flag = 1;
                        view_or_update ();
                        break;
   
                     case 'J':
                        end_of_edit = para_justify ();
                        fc->change_flag = 1;
                        view_or_update ();
                        break;

                     case 0x1b:  /* <esc> */
                     case 0x03:  /* ^C    */
                        break;   /* do nothing */

                     default:
                        end_of_edit = -2;
                        err_message (ILLEGAL_COMMAND);
                        break;
                  }
#else
                  end_of_edit = -2;
                  err_message (NOT_IMPLEMENTED);
#endif
                  break;
               }
               else                             /* Put file */
               {
                  end_of_edit = -2;

                  save_d.toggle = 0;
                  line_2_flag = 1;
                  do_it = get_line_2_string ("Put Filename:", str_putf,
                                             C_R, ID_FILE);
                  if (do_it)
                  {                  
                     ind0 = min  (save_d.index0 , fc->byte_index);
                     len  = labs (save_d.index0 - fc->byte_index);
                     write_flag = write_datafile (str_putf, &fc->buff_0 [ind0],
                                                  len, 0, 0);
                     if (!write_flag)
                        line_2_flag = 2;
                  }

               /* fc->change_flag bleibt hier unveraendert !! */
                  view_or_update ();
               }
               break;

            case '!':   /* !system   */
            case '&':   /* !system without wait */
               end_of_edit = -2;

            /* get command string */
               do_it = get_line_2_string ("System command:", str_syst,
                                          C_R, ID_SYST);
               line_2_flag = 1;
               if (!do_it) break;

            /* perform command */
               clear_screen ();
               cursor_home ();
               puts (str_syst);     /* anzeige */
               puts ("\015\012\n");
               fflush (stdout);
               kb_echo_on ();
               system (str_syst);   /* aufruf */
               kb_echo_off ();

            /* return to mbedit */
               if (key_0 == '!')
                  get_hit_any_key ();
               clear_screen ();
#if (WITH_WINCH)
               set_window_size ();  /* NEW ! 09.03.95 */
#endif
               perform_view ();
               break;

            case 'C':   /* Calc      */
               end_of_edit = -2;
               do_it = get_line_2_string ("Calc:", str_calc,
                                          C_R, ID_CALC);
               line_2_flag = 1;
               if (!do_it) break;

               switch (evaluate (str_calc, &calc_result, show_error)->type)
               {
                  case ERROR :
                     /* invalid expression */
                     break;
                    
                  case VALUE :
                     if (mb_isprint ((int) calc_result.item.val))
                        sprintf (string, "Calc: %11ld = 0x%08lx = \'%c\'",
                                                     calc_result.item.val, 
                                                     calc_result.item.val, 
                                                     calc_result.item.val);
                     else
                        sprintf (string, "Calc: %11ld = 0x%08lx",
                                                      calc_result.item.val,
                                                      calc_result.item.val);
                     line_2_flag = 2;
                     show_status_line_2 (string, 0, -2, 1);
                     break;

                  case STRING :
                     sprintf (string, "Calc: \"%s\" ",
                                          calc_result.item.str);
                     line_2_flag = 2;
                     show_status_line_2 (string, 0, -2, 1);
                     break;
               }
               break;

            case 'T':   /* Tag       */
               end_of_edit = -2;
               line_2_flag = 1;
               show_status_line_2 ("Tag: A B C D", 0, -1, 0);

               key_1 = toupper(get_1_key (1));
               if ((key_1 >= 'A') && (key_1 <= 'D'))
                  fc->tag_index [key_1 - 'A'] = fc->byte_index;
               else
                  err_message (INVALID_INPUT_VALUE);
               break;

#if (VAR_EOLN)
            case 0x0d:    /* <cr>     */
            case 0x0a:    /* <lf>     */
            case 0x0d0a:  /* <cr><lf> */
#else
            case EOLN:   /* <enter> */
#endif
               end_of_edit = perform_key_down (0) - 1;
               check_dirty_cursor ();
               new_index = first_nonblank (fc->buff_0, fc->lin_left,
                                           fc->byte_anz) + fc->lin_left;
               perform_move (new_index);
               if (fc->lrow >= MAX_ROW)
                  perform_view ();
               break;

            case 'W':   /* Window    */
               end_of_edit = -2;

#if WINDOW_COMMAND
               window_do ();
#else
               err_message (NOT_IMPLEMENTED);
#endif
               break;

            case 'K':   /* Kill_wnd  */
               end_of_edit = -2;

#if WINDOW_COMMAND
               window_kill ();
#else
               err_message (NOT_IMPLEMENTED);
#endif
               break;

            case 'M':   /* Macro     */
               end_of_edit = -2;
               LOCK_WHEN_BUFFER_ACTIVE
               line_2_flag = 1;

            /* end of create ? */
               if (get_macro_status () == MACRO_CREATE)
               {
                  delete_last_macro_key ();    /* 'M' for End Macro */
                  macro_cr = chain_macro (macro_cr, 0);
                  pop_macro_stack (macro_cr, 0);
                  break;      /* ready */
               }

            /* macro handling */
               show_status_line_2 ("Create Delete Get Insert List Save ",
                                                                   0, -1, 0);
               key_1 = toupper(get_1_key (1));
               switch (key_1)
               {
                  case 'C':
                     do_it = get_line_2_string ("Macro name: ", str_macr,
                                                C_R, ID_MACR);
                     if (do_it)
                     {
                     /* initialize macro */
                        macro_cr = init_macro (str_macr);
                        if (macro_cr == NULL)
                           err_message (OUT_OF_MEMORY);
                     }
                     break;

                  case 'D':
                     do_it = get_line_2_string ("Macro name: ", str_macr,
                                                C_R, ID_MACR);
                     if (do_it)
                     {
                     /* delete macro, if it exists */
                        if (!unchain_macro (str_macr))
                           err_message (NO_SUCH_MACRO);
                     }
                     break;

                  case 'G':
                     do_it = get_line_2_string ("<cr>,Macro file: ", str_getm,
                                                C_R, ID_FILE);
                     if (do_it)
                     {
                        if (!*str_getm)     /* <cr> only ? */
                        {                   /* read from buffer */
                        /* build temp. filename */
                           strcpy (tmp_filename, TEMP_DIR);
                           strcat (tmp_filename, FILE_SEPARATOR);
                           strcat (tmp_filename, TEMPO_FILENAME);

                           write_flag = write_datafile
                                           (tmp_filename,
                                            fc->buff_0, fc->byte_anz,
                                            1, 0);
                           read_macro_file (tmp_filename, 0);
                           
                           delete_datafile (tmp_filename);
                        }
                        else
                        {                   /* read from file */
                           read_macro_file (str_getm, 1);
                        }
                        resize_screen ();
                     }
                     break;

                  case 'I':
                     LOCK_WHEN_VIEW_ONLY
                     if (insert_macro ())
                        fc->change_flag = 1;
                     break;

                  case 'L':
                     clear_screen ();
                     list_macros ();
                     perform_view ();
                     break;

                  case 'S':
                     LOCK_WHEN_VIEW_ONLY
                     do_it = get_line_2_string ("Macro name: ", str_macr,
                                                C_R, ID_MACR);
                     if (do_it)
                     {
                        if (save_macro (str_macr) == -1)
                        {
                           err_message (NO_SUCH_MACRO);
                        }
                        else
                        {
                           fc->change_flag = 1;
                           view_or_update ();   /* display */
                        }
                     }
                     break;

                  case 0x1b:   /* <esc>: do nothing */
                  case 0x03:   /* ^C   : do nothing */
                     break;

                  default:
                     err_message (ILLEGAL_COMMAND);
                     break;
               }
               break;

            case 'E':   /* Execute   */
               end_of_edit = -2;
               LOCK_WHEN_BUFFER_ACTIVE
               line_2_flag = 1;
               do_it = get_line_2_string ("Macro name: ", str_macr,
                                          C_R, ID_MACR);
               BREAK_IF_REPEAT_0

               if (do_it)
               {
                  macro_ex = get_macro_adress (str_macr);
                  if (macro_ex == NULL)
                  {
                     err_message (NO_SUCH_MACRO);
                  }
                  else
                  {
                     exe_flag = push_macro_stack (macro_ex, MACRO_EXECUTE,
                                                  repeat_max, mode_flag);
                     if (exe_flag == -1)
                     {
                        err_message (MACRO_EXEC_NESTING_TO_DEEP);
                        reset_macro_stack ();
                     }
                  }
               }
               break;

            case 0x0e:   /* ^N  (hier nicht ^S, ^V !!) */  
               perform_special_keys (key_0, mode_flag);
               break;

#if (WITH_ZULU)
            case 'Z':    /* 'Z'ulu */
               line_2_flag = 2;
               if (repeat_count == 0)
               {
                  push_status_line_2 ();
                  show_status_line_2 ("Zulu: Beep Pause", 0, -1, 0);

                  key_1 = toupper(get_1_key (1));
                  pop_status_line_2 (0, -1, 0);
               }
               BREAK_IF_REPEAT_0

               switch (key_1)
               {
                  case 'B':
                     beep ();
                     break;               

                  case 'P':
                     sleep_msec (1000);
                     break;

                  case 0x1b:  /* <esc> */
                  case 0x03:  /* ^C    */
                     break;   /* do nothing */

                  default:
                     err_message (ILLEGAL_COMMAND);
                     break;
               }
               break;
#endif

            case 'Y':    /* File Compare A/B */  
               LOCK_WHEN_BUFFER_ACTIVE
               end_of_edit = perform_file_compare ();
               break;

            default:
               LOCK_WHEN_BUFFER_ACTIVE
               BREAK_IF_REPEAT_0
               
            /* check, if macro with "single char name" */
               macro_ex = get_macro_adress (key_2_string (key_0));

               if (macro_ex == NULL)
               {
                  end_of_edit = -1;
                  err_message (ILLEGAL_COMMAND);
               }
               else
               {
                  end_of_edit = -2;
                  exe_flag = push_macro_stack (macro_ex, MACRO_EXECUTE,
                                               repeat_max, mode_flag);
                  if (exe_flag == -1)
                  {
                     err_message (MACRO_EXEC_NESTING_TO_DEEP);
                     reset_macro_stack ();
                  }
               }
               break;
         }  /* switch key_0 */
         break;

      default:   /* sonst (hier darf er nie hinkommen !) */
         end_of_edit = -1;
         err_message (FATAL_ERROR);
         break;
   }  /* switch mode_flag */

   return end_of_edit;
}  /* switch_mode_flag */

/* -FF-  */

/*----------------------------------------------*/
/* subroutine for 'Calc': display error message */
/*----------------------------------------------*/

static void show_error (char *err_pos, int err_no)
  /* --  display message and echo expression up to error position */
{
char text [81];
int ii, txt_ind;


/* show error text + beep + pause */  
   sprintf (text, "%s", calc_errors[err_no]);
   show_status_line_2 (text, 0, -2, 1);
   beep ();
   fflush (stdout);
   sleep_msec (1000);


/* show input text up to error position */
/* bei ueberlangen strings: anfang unterdruecken */
   txt_ind = max (0, (int)(strlen (str_calc) - (sizeof (text) - 1)));

   for (ii = 0 ; ii < sizeof(text) - 1 ; ii++)
   {
      text [ii] = str_calc [txt_ind+ii];
      if (&str_calc [txt_ind+ii] >= err_pos)
      {
         text [ii+1] = '\0';  /* end of string */
         break;
      }
   }
   line_2_flag = 2;
   show_status_line_2 (text, 0, -2, 1);


   return;
}  /* show_error */

/* -FF-  */

/* Modification History */
/* 06.12.92 - file erzeugt */
/* 19.12.92 - FA_HU (far / huge) */
/* 20.12.92 - Get: end_of_edit = -1; wenn buffer_overflow */
/* 20.12.92 - loc_malloc other_fc erst bei command 'Other' */
/* 21.12.92 - EOL */
/* 29.12.92 - Calc von H.-D. Sander eingebaut */
/* 30.12.92 - ALT_F1 */
/* 01.01.93 - macros */
/* 04.01.93 - <F3> und <F4> */
/* 05.01.93 - key_2_string () */
/* 08.01.93 - get_hex_value () */
/* 25.03.93 - KEY_F1 unabhaengig von mode_flag */
/* 25.03.93 - show_find_display (..., find_ok) */
/* 26.04.93 - Generierung temp. filename */
/* 06.05.93 - 'O'ther: LOCK_WHEN_BUFFER_ACTIVE */
/* 04.06.93 - not more than 32 (>= 32 --> > 32) */
/* 18.06.93 - 'Q'uit, 'A'bort: ^C oder <esc> */
/* 27.07.93 - ALT_O: Other backward */
/* 27.07.93 - set.warning: 0-2 */
/* 27.07.93 - ^D: fc->change_flag = 1 (echte macke) */
/* 28.07.93 - HELP_COMMAND wieder als macro */
/* 28.07.93 - EOL --> EOLN */
/* 02.08.93 - perform_key_left / -right, return value = 0/1/2 */
/* 04.08.93 - 'D'...'D': ggf. view_or_update () */
/* 12.08.93 - 'M'acro 'D'elete */
/* 13.08.93 - 'Q'uit 'E'exit bzw. 'A'bort bricht bei != 'W' oder 'Y' ab */
/* 31.08.93 - 'Q'uit: display <esc> in status line 2 */
/* 02.09.93 - delete_datafile () */
/* 03.09.93 - perform_delete_start_of_line (1) */
/* 05.09.93 - Find mit Wildcard: '?' */
/* 07.09.93 - perform_find (..., &len1) */
/* 08.09.93 - Find mit Wildcards: '?*' */
/* 08.09.93 - save_find_indizes () */
/* 09.09.93 - old_index (for ?replace) */
/* 12.09.93 - show_status_line_2 (..., ignore_batch) */
/* 28.09.93 - window_split(), ..._change(), ..._kill() */
/* 30.09.93 - window_set() */
/* 30.09.93 - WINDOW_COMMAND */
/* 06.10.93 - PARAGR_COMMAND */
/* 07.10.93 - paragraph fill mit end_of_edit */
/* 07.10.93 - Set Margin */
/* 10.10.93 - ID_FILE */
/* 11.10.93 - perform_key_left() / right(.., skip_flag) */
/* 20.10.93 - 'S'et 'M'argin: check bad values */
/* 04.11.93 - wildcard_filename */
/* 06.11.93 - wildcard_filename --> disp_hnd.c */
/* 08.12.93 - 'J', 'P': check_dirty_cursor () */
/* 09.12.93 - kein check_dirty_cursor (), siehe mbed_sub.c: act_index () */
/* 13.12.93 - 'S','M': Aedit Format */
/* 07.01.94 - INSERT_KEY_DIRECT */
/* 09.02.94 - ^Z: check_dirty_cursor () */
/* 16.02.94 - EOLN + 'V'iew: check_dirty_cursor () */
/* 17.02.94 - read_macro_file (..., store_filename) */
/* 23.02.94 - handling of ^C in 'Q'uit command */
/* 14.03.94 - 'H'ex 'S'tdout */
/* 09.05.94 - 'P'aragraph: LOCK_WHEN_VIEW_ONLY */
/* 16.05.94 - VERSION_SCO, KEY_RUBOUT */
/* 17.05.94 - Unterscheidung UNIX-Varianten */
/* 18.05.94 - bei MACRO_EXECUTE: line_2_flag = 2 */
/* 07.06.94 - 'Z'ulu: 'B'eep + 'P'ause */
/* 08.06.94 - resize_screen () after read_macro_file () */
/* 29.06.94 - set.tilde_home */
/* 04.07.94 - WITH_E_DELIMIT */
/* 06.07.94 - 'S'et 'A'utonl */
/* 08.07.94 - 'Q'uit 'A'bort + 'I'nit: set.display |= 0x02 bzw. &= ~0x02 */
/* 09.07.94 - set.display handling in err_mess.c */
/* 21.07.94 - 'S'et view'O'nly */
/* 21.09.94 - WITH_HEX_VIEW */
/* 22.09.94 - WITH_HEX_VIEW: hex_view (int edit_allowed) */
/* 27.09.94 - command '&' (like '!' without wait) */
/* 02.10.94 - 'S''Y'n: Set sYntax highlighting */
/* 05.10.94 - Text modified: "c sYntax" */
/* 16.02.95 - 'Y': File Compare A/B */
/* 09.03.95 - 'V': set_window_size */
/* 02.06.95 - 'O', ALT 'O': check_dirty_cursor() */
/* 27.11.95 - MACRO_EXEC_NESTING_TO_DEEP */
/* 23.01.96 - printf ("\015\012") anstatt printf ("\r\n") */
/* 26.01.96 - 'H'ex 'F'ind */
/* 31.01.96 - 'H'ex 'F'ind verbessert */
/* 11.09.96 - bugfix: 'Q'uit 'I'nit 'Y'es ^C: change_flag is not affected */
/* 05.09.98 - VAR_EOLN */
/* 05.09.98 - eoln_tab */
/* 29.03.03 - 'S' 'Y': Set syntax_flag + file_type */
/* 04.10.03 - 'S' 'V': BOT_ROW --> MAX_ROW */
/* 11.02.04 - 'S'et 'H'ighbit 'A'uto */
/* 13.03.04 - disp_hnd.c: modifications for CSS (dashes in keywords) */
/* 24.03.04 - handling of fc->e_delimit assigment instead of strcpy */
