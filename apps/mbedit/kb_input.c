/*      kb_input.c                                       17.02.04 */
/*!
/  --------------------------------------------------------------
/  Copyright (C) 2004: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/  keyboard input subroutines, operating system dependant
/
*/

/****************************************************************
*                                                               *
*  BENUTZTE UNTERPROGRAMME (C LIBRARY)                          *
*                                                               *
****************************************************************/

#include "config.h"

#if (ACT_OP_SYSTEM == WIN_32)
#include <windows.h>
#endif

#if (ACT_OP_SYSTEM == RDOS)
#include "rdos.h"
#include "mousec.h"
#endif

#include "standard.h"
#include "global.h"
#include "kb_input.h"
#include "mon_outp.h"
#include "history.h"
#include "disp_hnd.h"
#include "err_mess.h"
#include "macro.h"
#include "perform.h"
#if (ACT_OP_SYSTEM == MS_DOS)
#include "mousec.h"
#endif
#include "mbedit.h"
#include "ansi_out.h"


#if (ACT_OP_SYSTEM == RDOS)

int wait_dev = 0;

#endif

/****************************************************************
*                                                               *
*  BENUTZTE UNTERPROGRAMME / GLOBALE VARIABLEN                  *
*                                                               *
****************************************************************/


#if (ACT_OP_SYSTEM == OS_9)

   #ifndef fileno
      #define fileno(p)       ((p)->_fd)
   #endif

#endif


#define PATH_0   fileno(stdin)   /* standard input */

#define TEST_PRINT  0


/****************************************************************
*                                                               *
*  ENDE DER DEKLARATIONEN                                       *
*                                                               *
****************************************************************/

/* -FF-  */

#if 0

arrangement of functions (overview 09.05.94)

(COMMON)
int check_input_redirection (void)
int ctrlc_active (void)
void set_key_fifo (int key_back)
void set_string_buff (char *string, int str_len)
int key_pressed (void)
int loc_get_1_key (void)
int get_1_key (int check_macro)
void ctrlchandler (int sig)
int check_end_of_file (int key)

(MS_DOS)
void sleep_msec (int time_delay)
int loc_key_pressed (void)
static int loc_get_1_int (void)
void kb_echo_off (void)
void kb_echo_on (void)

(OS_9)
void sleep_msec (int msec)
int loc_key_pressed (void)
static int get_1_byte (void)
static int get_1_byte_with_timeout (int wait_time)
void kb_echo_off (void)
void kb_echo_on (void)

(UNIX)
void syserr (char *text)
void sleep_msec (int msec)
static void setblock (int fd, int on)
int loc_key_pressed (void)
static int get_1_byte (void)
static int get_1_byte_with_timeout (int wait_time)
void kb_echo_off (void)
static void setraw (uchar c_num, uchar t_msec10)
void kb_echo_on (void)

#endif

/* -FF-  */

/*****************************************/
/*                                       */
/*  operating system independant region  */
/*                                       */
/*****************************************/

/* flag, that shows, if input is redirected */
static int input_redirected = 0;

int check_input_redirection (void)
{
/* call once at program start */

   if (isatty(PATH_0))
      input_redirected = 0;     /* normal tty */
   else
      input_redirected = 1;     /* redirected to file */

#if (TEST_PRINT)
   printf ("\n>>> check_input_redirection: input_redirected = %d \n",
                                        input_redirected);
#endif

   return input_redirected;

}  /* check_input_redirection */

/* -FF-  */

#if 0

We have 2 buffers for keyboard-data:

  - int  key_fifo    [] : is used as int buffer for keyboard keys,
                          (special keys too). new entries are always
                          stored at the end of the queue.

  - char string_buff [] : buffer for complete strings (special functions
                          like ^S, ^N, ^R), only one string at the time.

#endif

static int  key_fifo    [100];      /* type ahead buffer for keyboard keys */
static char string_buff [BUF_256];  /* string buffer for normal chars */


int ctrlc_active (void)
{
   return (*key_fifo == 0x03);    /* fuer check auf ^C */
}


void set_key_fifo (int key_back)
{
int ii, buf_len, index, overflow;
static int old_overflow;

/* put back 1 int key to fifo (^C: begin, any other char: end) */

   index = 0;    /* set to begin of queue */

   if (key_back != 0x03)     /* not ^C ? */
   {                         /* search end of queue */
      buf_len = lengthof(key_fifo) - 1;   /* last entry must always be 0 ! */
      
      for (ii = 0 ; ii < buf_len ; ii++)
      {
         if ((key_fifo [ii] == 0) ||   /* end of queue */
             (ii == (buf_len - 1)))    /* end of buffer */
         {
            index = ii;

            overflow = (ii == (buf_len - 1));
            if (overflow && (!old_overflow))    /* pos. slope ? */
               err_message (KEYBOARD_FIFO_OVERFLOW);
            old_overflow = overflow;

            break;
         }
      }
   }
   else
   {
      reset_macro_stack ();
   }

   key_fifo [index  ] = key_back;  /* store it */
   key_fifo [index+1] = 0;         /* new end of queue */

   return;
}  /* set_key_fifo */

/* -FF-  */

void set_string_buff (char *string, int str_len)
{

/* set 1 char string */
   str_len = min (str_len, (sizeof(string_buff) - 1));
   strncpy (string_buff, string, str_len);      /* copy string */
   string_buff [str_len] = '\0';       /* forced end of string */

   return;
}  /* set_string_buff */

/* -FF-  */

int key_pressed (void)
{

   if (*string_buff)       return 1;
   if (*key_fifo)          return 1;
   if (loc_key_pressed ()) return 1;

   return 0;   /* nothing found */

}   /* key_pressed */

/* -FF-  */

int loc_get_1_key (void)
{
int key;

#if (WITH_ACTION_FLAG)
int do_it;

   do_it = !(loc_key_pressed ());
   if (do_it)
      show_action_flag ('?');
#endif

   key = loc_get_1_int ();

#if (WITH_ACTION_FLAG)
   if (do_it)
      show_action_flag ('!');
#endif


   if (key == 0x0d) key = EOLN;
   return key;

}  /* loc_get_1_key */

/* -FF-  */

int get_1_key (int check_macro)
{
int key;

/*
  Diese Routine liefert einen Tastendruck zurueck, der von verschiedenen
  Quellen herruehren kann :
    - key_fifo (^C wurde gedrueckt ?)
    - string_buff (special keys, von bediener oder macro ausgeloest)
    - macro execution (ablauf eines macros)
    - key_fifo (1 wert, der getestet und zurueckgeschrieben wurde)
    - normal keyboard (bediener-eingabe)

  Die Quellen werden in dieser Reihenfolge abgecheckt, und bei Vorliegen
  eines "Tastendrucks" wird dieser ans rufende Programm zurueckgeliefert
  und ggf. im Buffer geloescht.
*/


/* 1.) ^C gedrueckt ? */
   if (*key_fifo == 0x03)
   {
      *key_fifo = 0;     /* clear input queue */
      reset_macro_stack ();
      return 0x03;
   }


/* 2.) test string buffer */
   if (*string_buff)
   {
      key = (int) (*string_buff & 0xff);      /* take LSB */
      strcpy (string_buff, &string_buff[1]);  /* shift buffer left */
      if (key == 0x03) reset_macro_stack ();
      return key;                             /* ==> */
   }


/* 3.) macro execute ? */
   if (check_macro)
   {
      if (get_macro_status () == MACRO_EXECUTE)
      {
         return get_macro_key ();   /* ==> */
      }
   }


/* 4.) test int buffer */
   if (*key_fifo)
   {
      key = *key_fifo;                        /* take it */
                                              /* shift buffer 1 entry left */
      memcpy (key_fifo, &key_fifo[1],
             (sizeof(key_fifo) - sizeof(key_fifo[0])));
      if (key == 0x03) reset_macro_stack ();
      return key;                             /* ==> */
   }


/* 5.) read 1 key by user input */
   key = loc_get_1_key ();
   if (key == 0x03) reset_macro_stack ();

/* macro create ? */
   if (check_macro)
   {
      if (get_macro_status () == MACRO_CREATE)
      {
         put_macro_key (key);
      }
   }

   return key;    /* ==> */

}  /* get_1_key */


/* Handles SIGINT (CTRL+C) interrupt. */
void ctrlchandler (int sig)
{

/* wg. compiler warning */
   sig = sig;

/* Disallow CTRL+C during handler. */
   signal (SIGINT, SIG_DFL);

/* handling of ^C */
   key_fifo [0] = 0x03;    /* store ^C in keyboard input queue */
   key_fifo [1] = '\0';    /* new end of queue */

   reset_macro_stack ();


/* The CTRL+C interrupt must be reset to our handler since by
 * default it is reset to the system handler.
 */
   signal (SIGINT, ctrlchandler);

}  /* ctrlchandler */

/* -FF-  */

int check_end_of_file (int key)
{
#if (TEST_PRINT)
char help;

   if (mb_isprint (key))
      help = (char) key;
   else
      help = ' ';
      
   printf ("\n>>> check_end_of_file: input_redirected = %d, key =%4d = 0x%02x = \'%c\' \n",
                                  input_redirected, key, key, help);
#endif

   if ((input_redirected) && (key == EOF))
   {
   /* input redirection to console */

      fclose (stdin);
      if ((fopen (CONSOLE_NAME, "r")) != NULL)
         input_redirected = 0;   /* abschalten */

      kb_echo_off ();          /* keyboard input klarmachen */

      set_batch_mode (0);      /* batch mode abschalten */

      err_message (EOF_IN_REDIRECTED_INPUT);

      return KEY_DO_NOTHING;   /* do nothing */
   }
   else
   {
      return key;
   }

}   /* check_end_of_file */

/* -FF-  */

/* fallunterscheidung */

#if (ACT_OP_SYSTEM == MS_DOS)

/*****************************************/
/*                                       */
/*           PC - MF2-Keyboard           */
/*                                       */
/*****************************************/

/*****************************************/
/*                                       */
/*           MS_DOS region               */
/*                                       */
/*****************************************/

/************************/
/*  n msec's delay      */
/************************/

void sleep_msec (int time_delay)  /* MS_DOS */
{

#if 0   /* LSB = 1 sec */

time_t time_start,time_act;

   time_delay /= 1000;    /* LSB: msec --> sec */

   for ( time(&time_start) , time(&time_act) ;
         (int)(time_act - time_start) < time_delay  ;
         time(&time_act))
   {
   }

#else   /* LSB = 10 msec */

struct dostime_t time_start, time_act;
int msec10_start, msec10_act;

   time_delay /= 10;    /* LSB: msec --> msec10 */

   _dos_gettime (&time_start);
   msec10_start = (int) time_start.second * 100 +
                  (int) time_start.hsecond;
   for (;;)
   {
      _dos_gettime(&time_act);
      msec10_act = (int) time_act.second * 100 +
                   (int) time_act.hsecond;
   
      if ((((msec10_act - msec10_start) + 6000) % 6000) >= time_delay)
         break;     
   }

#endif

   return;
}  /* sleep_msec (MS_DOS) */


/************************/
/*  is key pressed ?    */
/************************/

#define INPUT_VIA_BIOS 1  /* muss auf 1 stehen, wenn input redirection */

int loc_key_pressed (void)
{
/* return true, if key is pressed, else false */

   if (input_redirected) return 0;

#if (INPUT_VIA_BIOS)
   return _bios_keybrd(_KEYBRD_READY);
#else
   return kbhit ();
#endif
}

/* -FF-  */

/************************/
/*  get 1 key stroke    */
/************************/

static int loc_get_1_int (void)
{
/* This functions returns special keys (function, cursor keys, ...) */
/* in one (modified) int.   */

int key;

#if (WITH_MOUSE)
int call_handler;
#endif


   if (input_redirected)
   {                          /* input from file (stdin) */
      key = getchar ();

      return check_end_of_file (key);
   }
   else
   {                          /* input from keyboard direct */
   
#if (INPUT_VIA_BIOS)

#if (WITH_MOUSE)
   /* poll keyboard and mouse alternating */
      for (;;)
      {
      /* is key pressed ? */
         if (_bios_keybrd(_KEYBRD_READY))
         {
            MouHideMouse ();
            break;
         }

      /* mouse event ? */
         call_handler = -1;       /* don't call */
         if (mouse_event())
         {
            call_handler = 0;     /* call because event */
         }
         else
         {
            if (mouse_get_left_button ())
               call_handler = 1;  /* call because repetition */
         }

         if (call_handler >= 0)
         {
            key = mouse_event_handler_c (call_handler);
            if (key)           /* return value != 0 means: */
            {
               MouHideMouse ();
               return (key);   /* mouse simulated key stroke */
                               /* e.g.: left mouse key = <cr> */
            }

         /* make mouse visible */
            MouHideMouse ();
            MouShowMouse ();
         }
      }
#endif

   
   /* special keys are transferred as MSB            */
   /* in return value of _bios_keybrd, with LSB = 0. */
   
      key = _bios_keybrd(_KEYBRD_READ);
   
      if ((key & 0xff) != 0)
         return (key & 0xff);       /* normal key, return LSB direct (positiv) */
      else
         return (((key >> 8) & 0xff) - 256);  /* special key,
                                                 return MSB modified (negativ) */
   
#else
   
   /* special keys (function, cursor keys, ...) are transferred as */
   /* a sequence of two ints (with the first int = 0).             */
   
      key = getch();
   
      if (key != 0)
         return key;              /* normal key, return direct (positiv) */
      else
         return (getch() - 256);  /* special key, return modified (negativ) */
   
#endif
   }

}  /* loc_get_1_int */

/* -FF-  */

/************************/
/*  echo on / off       */
/************************/


void kb_echo_off (void)
{
#if (TEST_PRINT)
   printf ("\n>>> kb_echo_off: input_redirected = %d \n", input_redirected);
#endif

   set_wrap_off ();

   return;
}  /* kb_echo_off */


void kb_echo_on (void)
{
#if (TEST_PRINT)
   printf ("\n>>> kb_echo_on: input_redirected = %d \n", input_redirected);
#endif

   set_wrap_on ();

   return;
}  /* kb_echo_on */

#elif (ACT_OP_SYSTEM == WIN_32) /*  */

/*****************************************/
/*                                       */
/*           WIN_32 region               */
/*                                       */
/*****************************************/

/************************/
/*  n msec's delay      */
/************************/

void sleep_msec( int wait )
{
   Sleep(wait);
}


/************************/
/*  is key pressed ?    */
/************************/

int loc_key_pressed (void)
{
/* return true, if key is pressed, else false */

   if (input_redirected) return 0;

   return kbhit ();
}

/************************/
/*  get 1 key stroke    */
/************************/

static int loc_get_1_int (void)
{
/* This functions returns special keys (function, cursor keys, ...) */
/* in one (modified) int.   */

int key;

   if (input_redirected)
   {                          /* input from file (stdin) */
      key = getchar ();

      return check_end_of_file (key);
   }
   else
   {                          /* input from keyboard direct */
   

   /* special keys (function, cursor keys, ...) are transferred as */
   /* a sequence of two ints (with the first int = 0 or = 0xE0).   */
   
      key = getch();
   
      if ((key != 0) && (key != 0xE0))
         return key;              /* normal key, return direct (positiv) */
      else
         return (getch() - 256);  /* special key, return modified (negativ) */
   
   }

}  /* loc_get_1_int */

/* -FF-  */

/************************/
/*  echo on / off       */
/************************/


void kb_echo_off (void)
{
#if (TEST_PRINT)
   printf ("\n>>> kb_echo_off: input_redirected = %d \n", input_redirected);
#endif

   set_wrap_off ();

   return;
}  /* kb_echo_off */


void kb_echo_on (void)
{
#if (TEST_PRINT)
   printf ("\n>>> kb_echo_on: input_redirected = %d \n", input_redirected);
#endif

   set_wrap_on ();

   return;
}  /* kb_echo_on */


#elif (ACT_OP_SYSTEM == RDOS) /*  */

/*****************************************/
/*                                       */
/*           RDOS region               */
/*                                       */
/*****************************************/

/************************/
/*  n msec's delay      */
/************************/

void sleep_msec( int wait )
{
   RdosWaitMilli(wait);
}

/************************/
/*  is key pressed ?    */
/************************/

int loc_key_pressed (void)
{
/* return true, if key is pressed, else false */

   if (input_redirected) return 0;

   return RdosPollKeyboard();
}

/************************/
/*  get 1 key stroke    */
/************************/

static int loc_get_1_int (void)
{
/* This functions returns special keys (function, cursor keys, ...) */
/* in one (modified) int.   */

    int key;
    int call_handler;

    if (!wait_dev)
    {
        wait_dev = RdosCreateWait();
        RdosAddWaitForKeyboard(wait_dev, 0);
        RdosAddWaitForMouse(wait_dev, 0);
    }

    if (input_redirected)
    {                          /* input from file (stdin) */
        key = getchar ();
        return check_end_of_file (key);
    }
    else
    {                          /* input from keyboard direct */        
        /* poll keyboard and mouse alternating */
        for (;;)
        {
            RdosWaitForever(wait_dev);
            update_mouse();

            /* is key pressed ? */
            if (RdosPollKeyboard())
            {
                MouHideMouse();
                break;
            }

            /* mouse event ? */
            call_handler = -1;       /* don't call */
            if (mouse_event())
            {
                call_handler = 0;     /* call because event */
            }
            else
            {
                if (RdosGetLeftButton())
                    call_handler = 1;  /* call because repetition */
            }

            if (call_handler >= 0)
            {
                key = mouse_event_handler_c (call_handler);
                if (key)           /* return value != 0 means: */
                {
                    MouHideMouse();
                    return (key);   /* mouse simulated key stroke */
                               /* e.g.: left mouse key = <cr> */
                }

             /* make mouse visible */
                MouHideMouse();
                MouShowMouse();
            }
        }
           
        /* special keys are transferred as MSB            */
        /* in return value of _bios_keybrd, with LSB = 0. */

        key = RdosReadKeyboard();
   
        if ((key & 0xff) != 0)
            return (key & 0xff);       /* normal key, return LSB direct (positiv) */
        else
				return (((key >> 8) & 0xff) - 256);
    }
}  /* loc_get_1_int */

/* -FF-  */

/************************/
/*  echo on / off       */
/************************/


void kb_echo_off (void)
{

   set_wrap_off ();

   return;
}  /* kb_echo_off */


void kb_echo_on (void)
{

   set_wrap_on ();

   return;
}  /* kb_echo_on */


#elif (ACT_OP_SYSTEM == QNX)

/* -FF-  */

/*****************************************/
/*                                       */
/*    QNX pterm ansi                     */
/*                                       */
/*****************************************/


/************************/
/*  get 1 key stroke    */
/************************/

static int loc_get_1_int (void)
{
/* translation from <esc> sequences in one single (negativ) int */

/* special keys (function, cursor keys, ...) are transferred as */
/* <esc> sequence with variable no of chars.                    */
/* This functions returns special keys in one (modified) int.   */

#define ALLOW_SLOW_CONNECTIONS 1   /* to surround problems with <ESC>s */
                                   /* @@ implement time survey !! */

int ii, last_key, result, value;

static int key;
static int esc_buff;   /* if a single <esc> is followed by a sequence,  */
                       /* this event must be handled in special manner. */ 

static int old_mode_flag, old_text_area, old_toggle;
static time_t act_time, esc_time, delta_time;
#define MAX_ESC_TIME 5   /* LSB = 1 Sec. */
char err_text [20];

/* NEU !! */
   last_key = key;

/* NEU ! output buffer leerraeumen */
   fflush (stdout);

/* is there still a char in the queue ? */
   if (esc_buff)
   {
      key = esc_buff;        /* take it */
      esc_buff = 0;          /* clear buffer */
   }
   else
   {
      key = get_1_byte ();   /* get new byte from stdin */
   }


/* EOF bei input redirection ? */
   key = check_end_of_file (key);


/* input from file ? */
   if (input_redirected)
      return key;


/* <esc> handling */
#if (!ALLOW_SLOW_CONNECTIONS)
   if (key == 0x1b)            /* is it <esc> ? */
#else
   if ((key == 0x1b) ||
       ((key == '[') && (last_key == 0x1b)))
#endif
   {
   /* are there characters following immediately ? */
      if (key == 0x1b)
      {
         esc_time = time (NULL);
         result = get_1_byte_with_timeout (esc_waittime);
      }
      else
      {
      /* sequence: <esc> '[' (until now) */

      /* check time since <esc> */
         act_time = time (NULL);
         delta_time = act_time - esc_time;

         if (delta_time > MAX_ESC_TIME)
         {
            result = -1;   /* absolute timeout */
         }
         else
         {
            result = key;   /* '[' */
            if (old_mode_flag || old_text_area || old_toggle)
            {                             /* gimme just a little more time */
               esc_waittime = max (esc_waittime, 50);    /* min. 50 msec   */
               esc_waittime = (esc_waittime * 16) / 10;  /* factor 1.6     */
               esc_waittime = min (esc_waittime, 1000);  /* max. 1000 msec */
               sprintf (err_text, " (AE=%d msec)", esc_waittime);
               err_message_1 (ESCAPE_SEQUENCE_ERROR, err_text);
            }
         }
      }
                                       /* != 0, if in:                   */
      old_mode_flag = mode_flag;       /* insert / exchange mode         */
      old_text_area = text_area;       /* status line 2 / history window */
      old_toggle    = save_d.toggle;   /* 'B'uffer / 'D'elete            */


      if (result < 0)           /* timeout ? */
      {                         /* yes : single <esc> */
         return key;            /* send it ! */
      }
      else                      /* no : <esc> sequence */
      {
/* search tag: qnx ansi */

         key = result;          /* get following byte */
         switch (key)
         {
            case '[':
               key = get_1_byte ();
               switch (key)
               {
                  case 'A': return KEY_UP   ; break;   /* cursor keys */
                  case 'B': return KEY_DOWN ; break;
                  case 'C': return KEY_RIGHT; break;
                  case 'D': return KEY_LEFT ; break;

                  case 'H': return KEY_HOME ; break;
                  case '@': return KEY_INS  ; break;
                  case 'P': return KEY_DEL  ; break;
                  case 'Y': return KEY_END  ; break;
                  case 'V': return KEY_PGUP ; break;
                  case 'U': return KEY_PGDN ; break;

                  case 'a': return KEY_UP   ; break;   /* CTRL_UP */
                  case 'b': return KEY_DOWN ; break;   /* CTRL_DOWN */
                  case 'c': return CTRL_RIGHT; break;
                  case 'd': return CTRL_LEFT ; break;

                  case 'h': return CTRL_HOME ; break;
                  case '`': return KEY_INS  ; break;   /* CTRL_INS */
                  case 'p': return KEY_DEL  ; break;   /* CTRL_DEL */
                  case 'y': return CTRL_END  ; break;
                  case 'v': return CTRL_PGUP ; break;
                  case 'u': return CTRL_PGDN ; break;

                  case '1':
                  case '2':
                  case '3':
                  case '4':
                  case '5':
                  case '6':
                  case '7':
                  case '8':
                     value = key - '0';    /* build a 1- or 2-digit-number */
                     for (ii = 0 ; ii < 2 ; ii++)  /* read next bytes */
                     {
                        key = get_1_byte ();
                        if (key == '~') break;     /* last char in sequence */
                        value = 10 * value + (key - '0');
                     }

                     switch (value)
                     {
                        case 1: return CTRL_F1   ; break;
                        case 2: return CTRL_F2   ; break;
                        case 3: return CTRL_F3   ; break;
                        case 4: return CTRL_F4   ; break;
                        case 5: return CTRL_F5   ; break;
                        case 6: return CTRL_F6   ; break;
                        case 7: return CTRL_F7   ; break;
                        case 8: return CTRL_F8   ; break;
                        case 9: return CTRL_F9   ; break;
                        case 10: return CTRL_F10   ; break;

                        case 17: return ALT_F1   ; break;
                        case 18: return ALT_F2   ; break;
                        case 19: return ALT_F3   ; break;
                        case 20: return ALT_F4   ; break;
                        case 21: return ALT_F5   ; break;
                        case 22: return ALT_F6   ; break;
                        case 23: return ALT_F7   ; break;
                        case 24: return ALT_F8   ; break;
                        case 25: return ALT_F9   ; break;
                        case 26: return ALT_F10   ; break;

                        default: return INVALID  ; break;
                     }

                  default:
                     return INVALID;
                     break;                  
               }
               break;

            case 'O':           /* <PF> keys */
               key = get_1_byte ();
               switch (key)
               {
                  case 'P': return KEY_F1; break;
                  case 'Q': return KEY_F2; break;
                  case 'R': return KEY_F3; break;
                  case 'S': return KEY_F4; break;

                  case 'T': return KEY_F5; break;
                  case 'U': return KEY_F6; break;
                  case 'V': return KEY_F7; break;
                  case 'W': return KEY_F8; break;

                  case 'X': return KEY_F9; break;
                  case 'Y': return KEY_F10; break;
                  case 'Z': return KEY_F11; break;
                  case 'A': return KEY_F12; break;

                  case 'p': return SHIFT_F1; break;
                  case 'q': return SHIFT_F2; break;
                  case 'r': return SHIFT_F3; break;
                  case 's': return SHIFT_F4; break;

                  case 't': return SHIFT_F5; break;
                  case 'u': return SHIFT_F6; break;
                  case 'v': return SHIFT_F7; break;
                  case 'w': return SHIFT_F8; break;

                  case 'x': return SHIFT_F9; break;
                  case 'y': return SHIFT_F10; break;

                  default:  return INVALID; break;
               }
               break;

            case 'N':           /* ALT keys */
               key = get_1_byte ();
               switch (key)
               {
                  case 'a': return ALT_A; break;
                  case 'b': return ALT_B; break;
                  case 'c': return ALT_C; break;
                  case 'd': return ALT_D; break;
                  case 'e': return ALT_E; break;
                  case 'f': return ALT_F; break;
                  case 'g': return ALT_G; break;
                  case 'h': return ALT_H; break;
                  case 'i': return ALT_I; break;
                  case 'j': return ALT_J; break;
                  case 'k': return ALT_K; break;
                  case 'l': return ALT_L; break;
                  case 'm': return ALT_M; break;
                  case 'n': return ALT_N; break;
                  case 'o': return ALT_O; break;
                  case 'p': return ALT_P; break;
                  case 'q': return ALT_Q; break;
                  case 'r': return ALT_R; break;
                  case 's': return ALT_S; break;
                  case 't': return ALT_T; break;
                  case 'u': return ALT_U; break;
                  case 'v': return ALT_V; break;
                  case 'w': return ALT_W; break;
                  case 'x': return ALT_X; break;
                  case 'y': return ALT_Y; break;
                  case 'z': return ALT_Z; break;

                  default:  return INVALID; break;
               }
               break;

            default:                  /* <esc> followed by any other char */
               esc_buff = key;        /* may also be a new <esc> sequence */
               return 0x1b;
               break;
         }  /* switch (key) */
      }  /* <esc> sequence */
   }  /* check for <esc> sequence */
   else
   {               
      return key;              /* send directly */ 
   }

}  /* loc_get_1_int */

#else   /* QNX pterm ansi */

/* -FF-  */

/*****************************************/
/*                                       */
/*    VT 100 / VT 220 - Terminal         */
/*                                       */
/*****************************************/


/************************/
/*  get 1 key stroke    */
/************************/

static int loc_get_1_int (void)
{
/* translation from <esc> sequences in one single (negativ) int */

/* special keys (function, cursor keys, ...) are transferred as */
/* <esc> sequence with variable no of chars.                    */
/* This functions returns special keys in one (modified) int.   */

#define ALLOW_SLOW_CONNECTIONS 1   /* to surround problems with <ESC>s */
                                   /* @@ implement time survey !! */

int ii, last_key, result, value;

static int key;
static int esc_buff;   /* if a single <esc> is followed by a sequence,  */
                       /* this event must be handled in special manner. */ 

static int old_mode_flag, old_text_area, old_toggle;
static time_t act_time, esc_time, delta_time;
#define MAX_ESC_TIME 5   /* LSB = 1 Sec. */
char err_text [20];

#define ANSI_TERMINAL 1       /* <== 1 for SCO-Unix */
#define HP7_XTERM     1       /* <== 1 for hp 700   */


/* NEU !! */
   last_key = key;


/* NEU ! output buffer leerraeumen */
   fflush (stdout);


/* is there still a char in the queue ? */
   if (esc_buff)
   {
      key = esc_buff;        /* take it */
      esc_buff = 0;          /* clear buffer */
   }
   else
   {
      key = get_1_byte ();   /* get new byte from stdin */
   }


/* EOF bei input redirection ? */
   key = check_end_of_file (key);


/* input from file ? */
   if (input_redirected)
      return key;


/* <esc> handling */
#if (!ALLOW_SLOW_CONNECTIONS)
   if (key == 0x1b)            /* is it <esc> ? */
#else
   if ((key == 0x1b) ||
       ((key == '[') && (last_key == 0x1b)))
#endif
   {
   /* are there characters following immediately ? */
      if (key == 0x1b)
      {
         esc_time = time (NULL);
         result = get_1_byte_with_timeout (esc_waittime);
      }
      else
      {
      /* sequence: <esc> '[' (until now) */

      /* check time since <esc> */
         act_time = time (NULL);
         delta_time = act_time - esc_time;

         if (delta_time > MAX_ESC_TIME)
         {
            result = -1;   /* absolute timeout */
         }
         else
         {
            result = key;   /* '[' */
            if (old_mode_flag || old_text_area || old_toggle)
            {                             /* gimme just a little more time */
               esc_waittime = max (esc_waittime, 50);    /* min. 50 msec   */
               esc_waittime = (esc_waittime * 16) / 10;  /* factor 1.6     */
               esc_waittime = min (esc_waittime, 1000);  /* max. 1000 msec */
               sprintf (err_text, " (AE=%d msec)", esc_waittime);
               err_message_1 (ESCAPE_SEQUENCE_ERROR, err_text);
            }
         }
      }
                                       /* != 0, if in:                   */
      old_mode_flag = mode_flag;       /* insert / exchange mode         */
      old_text_area = text_area;       /* status line 2 / history window */
      old_toggle    = save_d.toggle;   /* 'B'uffer / 'D'elete            */


      if (result < 0)           /* timeout ? */
      {                         /* yes : single <esc> */
         return key;            /* send it ! */
      }
      else                      /* no : <esc> sequence */
      {
         key = result;          /* get following byte */
         switch (key)
         {
            case '[':
               key = get_1_byte ();
               switch (key)
               {
                  case 'A': return KEY_UP   ; break;   /* cursor keys */
                  case 'B': return KEY_DOWN ; break;
                  case 'C': return KEY_RIGHT; break;
                  case 'D': return KEY_LEFT ; break;

                  case '1':
                  case '2':
                  case '3':
                  case '4':
                  case '5':
                  case '6':
                  case '7':
                  case '8':
                     value = key - '0';    /* build a 1- or 2-digit-number */
                     for (ii = 0 ; ii < 2 ; ii++)  /* read next bytes */
                     {
                        key = get_1_byte ();
                        if (key == '~') break;     /* last char in sequence */
                        value = 10 * value + (key - '0');
                     }

                     switch (value)
                     {
                        case  1: return KEY_HOME ; break;
                        case  2: return KEY_INS  ; break;
                        case  3: return KEY_DEL  ; break;
                        case  4: return KEY_END  ; break;
                        case  5: return KEY_PGUP ; break;
                        case  6: return KEY_PGDN ; break;
                        case  7: return KEY_END  ; break;  /* hp / SCO */
                        case  8: return KEY_HOME ; break;  /* hp / SCO */

#if (HP7_XTERM)
                        case 11: return KEY_F1   ; break; /* HP7 XTERM F1 */
                        case 12: return KEY_F2   ; break; /* HP7 XTERM F2 */
                        case 13: return KEY_F3   ; break; /* HP7 XTERM F3 */
                        case 14: return KEY_F4   ; break; /* HP7 XTERM F4 */
                        case 15: return KEY_F5   ; break; /* HP7 XTERM F5 */
#endif

                        case 17: return KEY_F6   ; break;
                        case 18: return KEY_F7   ; break;
                        case 19: return KEY_F8   ; break;
                        case 20: return KEY_F9   ; break;
                        case 21: return KEY_F10  ; break;
                        case 23: return KEY_F11  ; break;
                        case 24: return KEY_F12  ; break;
                        
                        case 25: return KEY_F13  ; break;
                        case 26: return KEY_F14  ; break;
                        case 28: return KEY_HELP ; break;
                        case 29: return KEY_DO   ; break;
                        
                        case 31: return KEY_F17  ; break;
                        case 32: return KEY_F18  ; break;
                        case 33: return KEY_F19  ; break;
                        case 34: return KEY_F20  ; break;

#if (HP7_XTERM)
                        case 50: return CTRL_PGUP  ; break; /* HP7 */
                        case 51: return CTRL_HOME  ; break; /* w/ customized */
                        case 52: return CTRL_PGDN  ; break; /* xterm */
                        case 53: return CTRL_END   ; break; /* */
                        case 54: return CTRL_RIGHT ; break; /* */
                        case 55: return CTRL_LEFT  ; break; /* */

                        case 60: return ALT_F1     ; break; /* HP7 */
                        case 61: return ALT_F2     ; break; /* w/ customized */
                        case 62: return ALT_F3     ; break; /* xterm */
                        case 63: return ALT_F4     ; break; /* */
                        case 64: return ALT_F5     ; break; /* */
                        case 65: return ALT_F6     ; break; /* */
                        case 66: return ALT_F7     ; break; /* HP7 */
                        case 67: return ALT_F8     ; break; /* w/ customized */
                        case 68: return ALT_F9     ; break; /* xterm */
                        case 69: return ALT_F10    ; break; /* */
#endif

                        default: return INVALID  ; break;
                     }

#if (ANSI_TERMINAL)
                  case 'H': return KEY_HOME ; break;
                  case 'L': return KEY_INS  ; break;
                  case 'F': return KEY_END  ; break;
                  case 'I': return KEY_PGUP ; break;
                  case 'G': return KEY_PGDN ; break;

                  case 'M': return KEY_F1   ; break;
                  case 'N': return KEY_F2   ; break;
                  case 'O': return KEY_F3   ; break;
                  case 'P': return KEY_F4   ; break;
                  case 'Q': return KEY_F5   ; break;
                  case 'R': return KEY_F6   ; break;
                  case 'S': return KEY_F7   ; break;
                  case 'T': return KEY_F8   ; break;
                  case 'U': return KEY_F9   ; break;
                  case 'V': return KEY_F10  ; break;
                  case 'W': return KEY_F11  ; break;
                  case 'X': return KEY_F12  ; break;

                  case 'Y': return SHIFT_F1 ; break;
                  case 'Z': return SHIFT_F2 ; break;
                  case 'a': return SHIFT_F3 ; break;
                  case 'b': return SHIFT_F4 ; break;
                  case 'c': return SHIFT_F5 ; break;
                  case 'd': return SHIFT_F6 ; break;
                  case 'e': return SHIFT_F7 ; break;
                  case 'f': return SHIFT_F8 ; break;
                  case 'g': return SHIFT_F9 ; break;
                  case 'h': return SHIFT_F10; break;
                  case 'i': return INVALID  ; break;
                  case 'j': return INVALID  ; break;

                  case 'k': return CTRL_F1  ; break;
                  case 'l': return CTRL_F2  ; break;
                  case 'm': return CTRL_F3  ; break;
                  case 'n': return CTRL_F4  ; break;
                  case 'o': return CTRL_F5  ; break;
                  case 'p': return CTRL_F6  ; break;
                  case 'q': return CTRL_F7  ; break;
                  case 'r': return CTRL_F8  ; break;
                  case 's': return CTRL_F9  ; break;
                  case 't': return CTRL_F10 ; break;
                  case 'u': return INVALID  ; break;
                  case 'v': return INVALID  ; break;
#endif

                  default:
                     return INVALID;
                     break;                  
               }
               break;

            case 'O':           /* <PF> keys */
               key = get_1_byte ();
               switch (key)
               {
                  case 'P': return KEY_PF1; break;
                  case 'Q': return KEY_PF2; break;
                  case 'R': return KEY_PF3; break;
                  case 'S': return KEY_PF4; break;

                  default:  return INVALID; break;
               }
               break;

            default:                  /* <esc> followed by any other char */
               esc_buff = key;        /* may also be a new <esc> sequence */
               return 0x1b;
               break;
         }  /* switch (key) */
      }  /* <esc> sequence */
   }  /* check for <esc> sequence */
   else
   {
      key = key & 0xff;        /* special characters >= 0x80 are not negative ! */
      return key;              /* send directly */ 
   }

}  /* loc_get_1_int */

#endif

/* -FF-  */

/*****************************************/
/*                                       */
/*    Other Operating Systems            */
/*                                       */
/*  This is the region, to adapt the     */
/*  keyboard driver to a new operating   */
/*  system. Only some small functions    */
/*  have to be modified:                 */
/*                                       */
/*****************************************/

#if 0

|                |                kb_input.c                    |
|                |                                              |
|  application   |   translate vt220   |   op-system specific   |
|                |       (fix)         |    (to be adapted)     |

               ---------------------------> kb_echo_off ()
               ---------------------------> kb_echo_on  ()
                                       
               <-----> get_1_key () <--+--> get_1_byte  ()
                                       |
                                       +--> get_1_byte_with_timeout ()
                                       |
               <-------------------->  +--> loc_key_pressed ()

global functions :
   kb_echo_off ()
   kb_echo_on  ()
   key_pressed     ()
   loc_key_pressed ()
   get_1_key     ()
   loc_get_1_int ()

local functions :
   get_1_byte ()
   get_1_byte_with_timeout ()

#endif                                                        

/*****************************************/
/*                                       */
/*           OS_9 region                 */
/*                                       */
/*****************************************/

#if (ACT_OP_SYSTEM == OS_9)

/* for OS-9000: simulate getstat + setstat */

#if (OS_9_PPC)

static scf_path_opts spo;
static scf_lu_opts   slo;
static u_int32 size;

int getstat (int code, int path, struct _sgs *sgs)
{
int error, err1, err2;

   size = sizeof(spo);
   err1 = _os_gs_popt  (path, &size, &spo);

   size = sizeof(slo);
   err2 = _os_gs_luopt (path, &size, &slo);


   sgs->_sgs_class;                   /* file manager class code */
   sgs->_sgs_case   = spo.pd_case;    /* 0 = upper and lower cases  1 = upper case only */
   sgs->_sgs_backsp = spo.pd_backsp;  /* 0 = BSE  1 = BSE-SP-BSE */
   sgs->_sgs_delete = spo.pd_delete;  /* delete sequence */
   sgs->_sgs_echo   = spo.pd_echo;    /* 0 = no echo */
   sgs->_sgs_alf    = spo.pd_alf;     /* 0 = no auto line feed */
   sgs->_sgs_nulls  = spo.pd_nulls;   /* end of line null count */
   sgs->_sgs_pause  = spo.pd_pause;   /* 0 = no end of page pause */
   sgs->_sgs_page   = spo.pd_page;    /* lines per page */
   sgs->_sgs_bspch  = spo.pd_bspch;   /* backspace character */
   sgs->_sgs_dlnch;                   /* delete line character */
   sgs->_sgs_eorch  = spo.pd_eorch;   /* end of record character */
   sgs->_sgs_eofch  = spo.pd_eofch;   /* end of file character */
   sgs->_sgs_rlnch;                   /* reprint line character */
   sgs->_sgs_dulnch;                  /* duplicate last line character */
   sgs->_sgs_psch   = slo.v_psch;     /* pause character */
   sgs->_sgs_kbich  = slo.v_intr;     /* keyboard interrupt character */
   sgs->_sgs_kbach  = slo.v_quit;     /* keyboard abort character */
   sgs->_sgs_bsech;                   /* backspace echo character */
   sgs->_sgs_bellch = spo.pd_bellch;  /* line overflow character (bell) */
   sgs->_sgs_parity = slo.v_parity;   /* device initialization (parity) */
   sgs->_sgs_baud   = slo.v_baud;     /* baud rate */
   sgs->_sgs_d2p;                     /* offset to second device name string */
   sgs->_sgs_xon    = slo.v_xon;      /* x-on char */
   sgs->_sgs_xoff   = slo.v_xoff;     /* x-off char */
   sgs->_sgs_tabcr  = spo.pd_tabch;   /* tab character */
   sgs->_sgs_tabsiz = spo.pd_tabsiz;  /* tab size */
   sgs->_sgs_tbl;                     /* Device table address (copy) */
   sgs->_sgs_col    = spo.pd_col;     /* Current column number */
   sgs->_sgs_err    = spo.pd_err;     /* most recent error status */

             error = 0;
   if (err1) error = err1;
   if (err2) error = err2;
   
   return error;
}  /* getstat */

int setstat (int code, int path, struct _sgs *sgs)
{
int error, err1, err2;

   spo.pd_optsize;                       /* path options table size */
   spo.pd_extra;                         /* maintain long allignment */
   spo.pd_inmap[32];                     /* Input control character mapping table */
   spo.pd_eorch    = sgs->_sgs_eorch;    /* end of record character (read only) */
   spo.pd_eofch    = sgs->_sgs_eofch;    /* end of file character */
   spo.pd_tabch    = sgs->_sgs_tabcr;    /* Tab character */
   spo.pd_bellch   = sgs->_sgs_bellch;   /* bell (line overflow) */
   spo.pd_bspch    = sgs->_sgs_bspch;    /* backspace echo character */
   spo.pd_case     = sgs->_sgs_case;     /* case             0 = both */
   spo.pd_backsp   = sgs->_sgs_backsp;   /* backspace        0 = backspace */
   spo.pd_delete   = sgs->_sgs_delete;   /* delete           0 = carriage return, line feed */
   spo.pd_echo     = sgs->_sgs_echo;     /* echo             0 = no echo */
   spo.pd_alf      = sgs->_sgs_alf;      /* auto-linefeed    0 = no auto line feed */
   spo.pd_pause    = sgs->_sgs_pause;    /* pause            0 = no end of page pause */
   spo.pd_insm;                          /* insert mode      0 = type over */
   spo.pd_nulls    = sgs->_sgs_nulls;    /* end of line null count */
   spo.pd_page     = sgs->_sgs_page;     /* lines per page */
   spo.pd_tabsiz   = sgs->_sgs_tabsiz;   /* tab field size */
   spo.pd_err      = sgs->_sgs_err;      /* most recent I/O error status */
   spo.pd_rsvd[2];                       /* reserved */
   spo.pd_col      = sgs->_sgs_col;      /* current column number */
   spo.pd_time;                          /* time out value for unblocked reads */
   spo.pd_deventry;                      /* Device table address (copy) */


   slo.v_optsize;                        /* options section size */
   slo.v_class;                          /* device type; 0 = SCF */
   slo.v_err;                            /* accumulated errors */
   slo.v_pause;                          /* immediate pause request */
   slo.v_line;                           /* lines left until end of page */
   slo.v_intr      = sgs->_sgs_kbich;    /* keyboard interrupt character */
   slo.v_quit      = sgs->_sgs_kbach;    /* keyboard quit character */
   slo.v_psch      = sgs->_sgs_psch;     /* keyboard pause character */
   slo.v_xon       = sgs->_sgs_xon;      /* x-on character */
   slo.v_xoff      = sgs->_sgs_xoff;     /* x-off character */
   slo.v_baud      = sgs->_sgs_baud;     /* Baud rate */
   slo.v_parity    = sgs->_sgs_parity;   /* Parity */
   slo.v_stopbits;                       /* Stop bits */
   slo.v_wordsize;                       /* Word size */
   slo.v_rtsstate;                       /* RTS state: disable = 0; enable = non-zero */
   slo.v_dcdstate;                       /* current state of DCD line */
   slo.v_reserved[9];                    /* reserved for future use */


   size = sizeof(spo);
   err1 = _os_ss_popt  (path, size, &spo);

   size = sizeof(slo);
   err2 = _os_ss_luopt (path, size, &slo);

             error = 0;
   if (err1) error = err1;
   if (err2) error = err2;
   
   return error;
}  /* setstat */
#endif


#define CODE     0                 /* for getstat, setstat       */

static struct _sgs old;   /* buffers for echo on/off */
static struct _sgs new;


/************************/
/*  n msec's delay      */
/************************/

void sleep_msec (int msec)  /* OS_9 */
{                         /* scale: msec --> timer ticks (LSB = 1 sec) */
   /* msec /= TIMER_TICK; */   /* not any more */
   msec = (int)(((long) msec * CLOCKS_PER_SEC) / 1000);
   msec = max (2, msec);  /* os/9: minimal 2 ticks */
   tsleep (msec);         /* do it */

   return;
}  /* sleep_msec (OS_9) */


/************************/
/*  is key pressed ?    */
/************************/

int loc_key_pressed (void)
{
/* return true, if key is pressed, else false */

   if (input_redirected) return 0;

   if (_gs_rdy (PATH_0) >= 0)
      return 1;
   else
      return 0;
}


/************************/
/*  get 1 single byte   */
/************************/

static int get_1_byte (void)
{
char byte1;
int  num;

   num = read (PATH_0, &byte1, 1);

   if ((input_redirected) && (num == 0))
      return EOF;
   else
      return byte1;

}  /* get_1_byte */


/************************/
/*  get with timeout    */
/************************/

static int get_1_byte_with_timeout (int wait_time)
{
/* if key is pressed before wait_time elapsed, key is returned, else -1 */
/* wait_time : LSB = 1 msec */
/* special cases: wait_time = 0 : no wait */
/*                wait_time < 0 : wait forever */

int time;
#define SLEEP_GRANULARITY 10        /* resolution sleep_msec(), LSB = 1 msec */


/* wait forever ? */
   if (wait_time < 0)  return get_1_byte ();

/* is key already there ? */
   if (loc_key_pressed ()) return get_1_byte ();
   
/* wait given time */
   for (time = 0 ; time < wait_time ; time += SLEEP_GRANULARITY)
   {
      sleep_msec (SLEEP_GRANULARITY);
      if (loc_key_pressed ()) return get_1_byte ();
   }

   return -1;  /* timeout */
}  /* get_1_byte_with_timeout */

/* -FF-  */

/************************/
/*  echo on / off       */
/************************/

static int on_off;

void kb_echo_off (void)
{
#if (TEST_PRINT)
   printf ("\n>>> kb_echo_off: input_redirected = %d, on_off = %d \n",
                            input_redirected, on_off);
#endif

   if (input_redirected) return;

   if (on_off == 0)
   {
   /* get current settings */
      getstat (CODE, PATH_0, &old);          /* saved  in old */
      memcpy (&new, &old, sizeof (new));     /* copied to new */
   
   /* set options */
      new._sgs_echo  = 0;
      new._sgs_pause = 0;
      new._sgs_eorch = 0;
      new._sgs_eofch = 0;

      new._sgs_alf   = 0;     /* no auto <lf> */

      new._sgs_kbich = 0;     /* ^C */
      new._sgs_kbach = 0;     /* ^E */
      new._sgs_xon   = 0;     /* ^S */
      new._sgs_xoff  = 0;     /* ^Q */

   /* write back new settings */
      if (setstat (CODE, PATH_0, &new) != -1)
         on_off = 1;  /* o.k. */
   }
   set_wrap_off();

   return;
}  /* kb_echo_off */


void kb_echo_on (void)
{
#if (TEST_PRINT)
   printf ("\n>>> kb_echo_on: input_redirected = %d, on_off = %d \n",
                           input_redirected, on_off);
#endif

   if (input_redirected) return;

   if (on_off == 1)
   {
   /* write back old settings */
      if (setstat (CODE, PATH_0, &old) != -1)
         on_off = 0;
   }
   set_wrap_on();

   return;
}  /* kb_echo_on */

#endif  /* OS_9 */

/* -FF-  */

/*****************************************/
/*                                       */
/*           UNIX region                 */
/*                                       */
/*****************************************/

#if (UNIX)

static struct termio tbufsave;
static struct termio tbuf;

/* -FF-  */

/* error display in status line (given text + errno) */

void syserr (char *text)
{
char ges_line [81];
char err_disp [30];

/* build complete line */
   strncpy (ges_line, text, (sizeof(ges_line) - 1));
   sprintf (err_disp, ", errno = %d", errno);

/* check for buffer overflow */
   if ((strlen(ges_line) + strlen(err_disp)) < sizeof(ges_line))
      strcat (ges_line, err_disp);

/* display */
   line_2_flag = 1;
   show_status_line_2 (ges_line, 0, -2, 1);
   beep ();
   fflush (stdout);

   sleep_msec (1000);   /* 1 sec. pause */

   return;
}  /* syserr */

/* -FF-  */


/************************/
/*  n msec's delay      */
/************************/

void sleep_msec (int msec)  /* UNIX */
{
#if (WITH_USEC_CLOCK)

long goal, limit;

/* the behaviour of clock () is different in every system:              */
/* System V Rel 4 (C): ..., 0x7fffffff, 0x80000000, 0x80000001, ...     */
/* OSF/1          (C): ..., 0x7fffffff, 0x80000000, 0x80000001, ...     */
/* SGI IRIX       (T): ..., 0x7fffffff, 0x80000000, 0x80000001, ...     */
/* ultrix 4.2     (C): ..., 0x7fffffff, 0xffffffff, 0xffffffff, ... !!! */
/* others            : ??                                               */

/* By the way, another difference is the measured value:       */
/* Some operating systems measure the expired time (T),        */
/* some the actual used cpu time (C) !!                        */
/* SO THIS "clock()" STUFF IS NOTHING EXACTLY !!               */
/*                                                             */
/* The other possibility to measure times in the msec range is */
/* the function ftime(), but this is not available everywhere. */


/* check for abnormal behaviour */
   if (((long) clock() == -1L) ||    /* overflow ? e.g. ultrix ! */
       (msec >= TIMER_TICK))         /* or big pause ?           */
   {                         /* compromise:                      */
                             /* fall back to old fashioned style */
      msec /= TIMER_TICK;    /* scale: msec --> timer ticks (LSB = 1 sec) */
      msec = max (1, msec);  /* unix: minimal 1 tick */
      sleep (msec);          /* do it */
   }
   else
   {
      goal = (long) msec * CLOCKS_PER_SEC / 1000L + clock();   /* LSB = msec --> usec */
   
   /* loop: waste of time */
   /* limit prevents endless loop */
      for (limit = 0 ; limit < 1000000L ; limit++)
      {           /* this handling prevents modulo problems, if 31 bit clock */
         if (((clock() - goal) & 0x7fffffff) <= 0x40000000)
            break;     /* normal exit */
      }
   }

#else

   msec /= TIMER_TICK;    /* scale: msec --> timer ticks (LSB = 1 sec) */
   msec = max (1, msec);  /* unix: minimal 1 tick */
   sleep (msec);          /* do it */

#endif

   return;
}  /* sleep_msec (UNIX) */


/************************************************************************/
/* set the terminal I/O blocking on and off                             */
/************************************************************************/

static void setblock (int fd, int on)
{
   static int blockf, nonblockf;
   static int first = 1;
   int flags;

   if (first)
   {
      first = 0;
      if ((flags = fcntl(fd, F_GETFL, 0)) == -1)
         syserr("fcntl");

#if (ACT_OP_SYSTEM == QNX)
      blockf    = flags & ~O_NONBLOCK;     /* O_NDELAY off */
      nonblockf = flags |  O_NONBLOCK;     /* O_NDELAY on  */
#else
      blockf    = flags & ~O_NDELAY;       /* O_NDELAY off */
      nonblockf = flags |  O_NDELAY;       /* O_NDELAY on  */
#endif
   }

   if (fcntl(fd, F_SETFL, on ? blockf : nonblockf) == -1)
      syserr("fcntl2");
}  /* setblock */


/*************************/
/* avoid hanging display */
/*************************/

void avoid_hanging_display(void)
{
   setblock (PATH_0, 0);
   setblock (PATH_0, 1);
}


/************************/
/*  is key pressed ?    */
/************************/

#define EMPTY '\0'
static char cbuf[16] = "\0";

int loc_key_pressed (void)
{
/* return true, if key is pressed, else false */

   if (input_redirected) return 0;

   if (*cbuf != EMPTY)
      return (1);

   setblock (PATH_0, 0);
   switch (read (PATH_0, cbuf, 1))
   {
      case -1:
         errno = 0;
         return (EMPTY);

      case  0:
         return (EMPTY);          /* could be EOF too */

      default:
         cbuf[1]=EMPTY;
         return 1;
   }
}  /* loc_key_pressed */


/************************/
/*  get 1 single byte   */
/************************/

static int get_1_byte (void)
{
int num;
char c;

   if (*cbuf != EMPTY)
   {
       c = *cbuf;
       strcpy(cbuf,&cbuf[1]);  /* shift buffer 1 charact. down */
       return(c);
   }

   setblock (PATH_0, 1);
   num = read (PATH_0, &c, 1);
   switch (num)
   {
      case -1: 
         if (errno == EINTR)
         {
            errno = 0;
            return (KEY_DO_NOTHING);   /* NEU !! wg. SIGWINCH, vorher : -1 */
         }
         else
         {
            syserr("read 1 stdin");
         }
         /* fall through */
         
      case 0:
         return (-1);             /* must be EOF  */
         
      default:
         return (c);
   }

}  /* get_1_byte */

/* -FF-  */

/************************/
/*  get with timeout    */
/************************/

#if (WITH_USEC_CLOCK)

#define TIMER_TICK_10 10

static int get_1_byte_with_timeout (int wait_time)
{
/* if key is pressed before wait_time elapsed, key is returned, else -1 */
/* wait_time : LSB = 1 msec */
/* special cases: wait_time = 0 : no wait */
/*                wait_time < 0 : wait forever */

int time;

/* wait forever ? */
   if (wait_time < 0)  return get_1_byte ();

/* is key already there ? */
   if (loc_key_pressed ()) return get_1_byte ();
   
/* wait given time */
   for (time = 0 ; time < wait_time ; time += TIMER_TICK_10)
   {
      sleep_msec (TIMER_TICK_10);
      if (loc_key_pressed ()) return get_1_byte ();
   }

   return -1;  /* timeout */
}  /* get_1_byte_with_timeout */

#else

static jmp_buf env;

static int get_1_byte_with_timeout (int w_time)
{
char c;
int nr, tms, jmpret;

   tms = max(1, ((w_time + (TIMER_TICK-1)) / TIMER_TICK));

   if (w_time < 0 )
       return (get_1_byte());

   if (*cbuf != EMPTY)
   {
       c = *cbuf;
       strcpy (cbuf, &cbuf[1]);  /* shift buffer 1 charact. down */
       return(c);
   }

   setblock (PATH_0, 1);          /* das fehlen dieser anweisung verursachte */
                                  /* die probleme unter unix svr4 !!         */

   signal (SIGALRM, key_brk);     /* set signal handling       */

   alarm (tms);                   /* set timeout: LSB 1 sec !! */
   jmpret = setjmp (env);

   if (jmpret == 0)                  /* auf unix svr4 ueberfluessig, da bei */
      nr = read (PATH_0, cbuf, 2);   /* SIGALRM die read function abgebro-  */
   else                              /* chen wird (-1), bei ultrix nicht !! */
      nr = jmpret;

   alarm (0);                     /* reset timeout */

   switch (nr)
   {
      case -1:
         return (-1);
          
      case 0:
         return (-1);           /* EOF */
 
      default:
         cbuf[nr] = EMPTY;
         c = *cbuf;
         strcpy( cbuf, &cbuf[1] );  /* shift buffer */
         return(c);
   }
}  /* get_1_byte_with_timeout */


/* dummy routine fuer alarm handling */
static void key_brk (int sig)
{
   sig;
   longjmp (env, -1);
}

#endif

/* -FF-  */

/************************/
/*  echo on / off       */
/************************/

static int on_off;

void kb_echo_off (void)
{
#if (TEST_PRINT)
   printf ("\n>>> kb_echo_off: input_redirected = %d, on_off = %d \n",
                            input_redirected, on_off);
#endif


#if (WITH_WINCH)
   if ((signal(SIGWINCH, cmd_winch)) == SIG_ERR)
      syserr("signal SIGWINCH, cmd_winch");
#endif


   if (input_redirected) return;

   if (on_off == 0)
   {
      on_off = 1;

#if (OS_QNX6)
      if (tcgetattr(PATH_0, &tbuf) == -1)
#else
      if (ioctl (PATH_0, TCGETA, &tbuf) == -1)
#endif
         syserr("ioctl get termio");

#if 0
      tbufsave = tbuf;                        /* save the old structure */
#else
      memcpy (&tbufsave, &tbuf, sizeof (tbufsave));
#endif

      setraw (1, 1);
   }
   set_wrap_off();

   return;

}  /* kb_echo_off */

static void setraw (uchar c_num, uchar t_msec10)
{

/* INLCR : map (not map) NL to CR                               */
/* ICRNL : map (not map) CR to NL                               */
/* IUCLC : map (not map) upper case to lower case on input      */
/* ISTRIP: strip (not)   input characters to seven bits         */

#if (ACT_OP_SYSTEM == QNX)
   tbuf.c_iflag &= ~(INLCR | ICRNL | ISTRIP | BRKINT);
#else
   tbuf.c_iflag &= ~(INLCR | ICRNL | IUCLC | ISTRIP | BRKINT);
#endif

#if 0
   tbuf.c_iflag |=  (IXON | IXOFF);    /* handshake in both (!) directions */
#else
   tbuf.c_iflag &= ~(IXON | IXOFF);    /* ^S / ^Q available for application */
#endif

   tbuf.c_oflag &= ~OPOST;
   tbuf.c_lflag &= ~(ICANON | ISIG | ECHO);
   tbuf.c_cc[4] = c_num;          /* MIN */
   tbuf.c_cc[5] = t_msec10;       /* TIME */

#if (OS_QNX6)
   if (tcsetattr(PATH_0, TCSADRAIN, &tbuf) == -1)
#else
   if (ioctl (PATH_0, TCSETA, &tbuf) == -1)
#endif
         syserr("ioctl set termio");

   return;
}  /* setraw */


void kb_echo_on (void)
{
#if (TEST_PRINT)
   printf ("\n>>> kb_echo_on: input_redirected = %d, on_off = %d \n",
                           input_redirected, on_off);
#endif


#if (WITH_WINCH)
   if ((signal(SIGWINCH, SIG_IGN)) == SIG_ERR)
      syserr("signal SIGWINCH, SIG_IGN");
#endif


   if (input_redirected) return;
   
   if (on_off == 1)
   {
      on_off = 0;

#if (OS_QNX6)
      if (tcsetattr(PATH_0, TCSADRAIN, &tbufsave) == -1)
#else
      if (ioctl (PATH_0, TCSETA, &tbufsave) == -1)   /* vorher: TCSETAF */
#endif
         syserr("ioctl reset term");
   }
   set_wrap_on();

   return;
}  /* kb_echo_on */

#endif  /* UNIX */

/* -FF-  */

/* Modification History */
/* 21.10.92 - file erzeugt */
/* 01.12.92 - vt100 ansteuerung  */
/* 04.12.92 - keyboard_echo on/off */
/* 05.12.92 - pause_msec () */
/* 21.12.92 - get_1_key (): fflush (stdout); bei VT_100 */
/* 01.01.93 - loc_get_1_key () */
/* 03.01.93 - loc_get_1_key () public (for mbedit.c) */
/* 15.08.93 - loc_key_pressed: #if INPUT_VIA_BIOS */
/* 12.09.93 - show_status_line_2 (..., ignore_batch) */
/* 14.09.93 - get_1_key(), special case <cr><lf> */
/* 30.09.93 - TEST_EOLN */
/* 08.10.93 - loc_get_1_key() --> loc_get_1_int() */
/* 04.11.93 - TEST_EOLN entfaellt */
/* 07.12.93 - ctrlchandler (int sig) */
/* 08.12.93 - ctrlchandler auch bei os/9 */
/* 08.12.93 - os/9: tsleep min. 2 ticks */
/* 10.12.93 - keyboard and mouse polling */
/* 15.12.93 - KEYBOARD_FIFO_OVERFLOW: only for the 1st occurance */
/* 15.12.93 - get_1_key: key = (int) (*string_buff & 0xff); only LSB */
/* 15.12.93 - ALLOW_SLOW_CONNECTIONS */
/* 20.12.93 - ESCAPE_SEQUENCE_ERROR */
/* 22.12.93 - old_toggle */
/* 09.05.94 - WITH_USEC_CLOCK (quick <esc> handling) */
/* 09.05.94 - variable esc_waittime */
/* 10.05.94 - HP7_XTERM */
/* 11.05.94 - increase of esc_waittime in case of <esc> sequence error */
/* 17.05.94 - sleep_msec (UNIX), prevent endless loop */
/* 18.05.94 - sleep_msec (UNIX), bugfix */
/* 19.05.94 - sleep_msec (UNIX), msec >= 1000: old function */
/* 20.05.94 - action_flag */
/* 03.06.94 - get_1_byte (): case -1: return KEY_DO_NOTHING (vorher: -1) */
/* 09.06.94 - kb_echo_off (UNIX): "memcpy" anstatt "struct 1 = struct 2" */
/* 09.06.94 - TEST_PRINT */
/* 15.06.94 - kb_echo_on (): TCSETAF --> TCSETA */
/* 15.06.94 - 6-mal neu: reset_macro_stack() */
/* 23.09.94 - setraw(): tbuf.c_iflag &= ~(IXON | IXOFF); */
/* 26.09.94 - <esc> [ 7 ~, <esc> [ 8 ~ */
/* 21.11.94 - WRAP_ON / WRAP_OFF bei SCO_UNIX */
/* 22.02.95 - ESC_WRAP_ON / ESC_WRAP_OFF immer */
/* 24.02.95 - key_break (int sig) */
/* 26.02.95 - set_wrap_on, _off */
/* 27.02.95 - sleep_msec(): CLOCKS_PER_SEC (unix) */
/* 28.11.95 - sleep_msec(): CLOCKS_PER_SEC (os/9) */
/* 09.09.98 - code for QNX */
/* 04.03.99 - OS-9000: simulate getstat + setstat */
/* 07.03.99 - OS_9_PPC: simulate getstat + setstat */
/* 16.03.99 - OS_9_PPC: simulate getstat/setstat with _os_gs_popt/_os_ss_popt */
/* 20.03.99 - OS_9_PPC: bugfix (missing 4 end of comment in setstat) */
/* 20.03.99 - OS_9_PPC: scf_lu_opts (disable ^C, ^E) */
/* 06.12.03 - avoid_hanging_display() */
/* 05.02.04 - loc_get_1_int(): return (key & 0xff); */
/* 17.02.04 - QNX6: New ! */
