/*      err_mess.c                                  30.03.03       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    error messages for mbedit
/
*/


/************************/
/*  include files       */
/************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "err_mess.h"
#include "history.h"
#include "disp_hnd.h"
#include "mon_outp.h"
#include "kb_input.h"
#include "perform.h"


/************************/
/* some defines         */
/************************/



/************************/
/* local structures     */
/************************/



/************************/
/*  module definitions  */
/************************/

/* -FF-  */

static int display_err_message (enum ERR_TYPE err_type, char * comment)
{
static char *message [] = {"*** buffer overflow ***",
                           "*** illegal command ***",
                           "*** not more than 32 ***",
                           "*** invalid character ***",
                           "*** invalid input value ***",
                           "*** no such tag ***",
                           "*** not implemented ***",
                           "*** fatal error ***",
                           "*** out of memory ***",
                           "*** error read file ***",
                           "*** error write file ***",
                           "modified: abort anyway ? [Y/N/W]",
                           "*** file is view only ***",
                           "*** file doesn't exist ***",
                           "file exists, overwrite ? [Y/N]",
                           "*** no such macro ***",
                           "*** macro exec nesting to deep ***",
                           "*** macro include nesting to deep ***",
                           "*** invalid variable name ***",
                           "*** invalid hex value ***",
                           "*** string too long ***",
                           "*** line too long - truncated ***",
                           "*** invalid history entry ***",
                           "*** EOF in redirected input ***",
                           "*** invalid radix ***",
                           "*** invalid macro entry ***",
                           "*** invalid syntax entry ***",
                           "*** too many file types ***",
                           "*** too many file extensions ***",
                           "*** too many keywords ***",
                           "*** invalid null name ***",
                           "*** file to large ***",
                           "*** error backup file ***",
                           "*** keyboard fifo overflow ***",
                           "*** error create file ***",
                           "file is read only ! set to write ? [Y/N]",
                           "*** couldn't set access rights ***",
                           "*** window too small ***",
                           "*** invalid path name ***",
                           "*** no corresponding bracket ***",
#if (ACT_SERVER == SERVER_VT_100)
                           "*** <esc> sequence error ***",
#endif
                           "*** invalid status entry ***",
                           "*** file size changed during read ***",
                           "*** file not readable ***",
                           "*** unknown error ***"
                           };
char text [80];

/* ------------------------------------------------------------------------- */

/* NEU ! bei Bediener-Abfagen: Bildschirm anzeigen */

struct INTERACTIVE_ERROR
   {
      enum ERR_TYPE no;
   };


/* This is the list of interactive errors, must be extended eventually !! */

static struct INTERACTIVE_ERROR int_err [] =
   {
      MODIFIED_ABORT_ANYWAY,
      FILE_EXISTS_OVERWRITE,
      FILE_IS_READ_ONLY          
                                 /* <== add new entries here ! */
   };

int ii;


/* check, if act. err_type is in list of special errors */
   for (ii = 0 ; ii < lengthof(int_err) ; ii++)
   {
      if (int_err[ii].no == err_type)
      {
         view_unconditionally ();
         break;
      }
   }

/* ------------------------------------------------------------------------- */

/* error display auch bei macro execute aktivieren */
   set.display |= 0x02;

/* index begrenzen */
   err_type = min (err_type, (lengthof(message) - 1));

   line_2_flag = 1;

/* text zusammensetzen */
   strcpy (text, message [err_type]);
   strcat (text, comment);
   show_status_line_2 (text, 0, -2, 1);

   if (set.warning >= 2)
      beep ();

   fflush (stdout);

   sleep_msec (1000);   /* short delay */

/* display status restaurieren */
   set.display &= ~0x02;

   return line_2_flag;
}  /* display_err_message */

/* -FF-  */

int err_message (enum ERR_TYPE err_type)
{
   return display_err_message (err_type, "");
}  /* err_message */


int err_message_1 (enum ERR_TYPE err_type, char * comment)
{
   return display_err_message (err_type, comment);
}  /* err_message */

/* -FF-  */

/* Modification History */
/* 15.01.93 - file erzeugt */
/* 18.06.93 - set.warning */
/* 27.07.93 - set.warning: 0-2 */
/* 29.08.93 - FILE_IS_READ_ONLY */
/* 30.08.93 - COULDN_T_SET_ACCESS_RIGHTS */
/* 12.09.93 - show_status_line_2 (..., ignore_batch) */
/* 28.09.93 - window too small */
/* 07.11.93 - invalid path name */
/* 07.11.93 - no corresponding bracket */
/* 15.12.93 - Rechtschreibfehler korrigiert */
/* 20.12.93 - escape sequence error */
/* 10.05.94 - <esc> sequence error (AE=xx msec) */
/* 19.05.94 - pause 500 --> 1000 msec */
/* 21.05.94 - invalid status entry */
/* 14.06.94 - line too long */
/* 09.07.94 - view_unconditionally() */
/* 02.10.94 - NOT_IMPLEMENTED */
/* 27.11.95 - MACRO_INCLUDE_NESTING_TO_DEEP */
/* 10.12.95 - FILE_SIZE_CHANGED */
/* 04.02.99 - FILE_NOT_READABLE */
/* 30.03.03 - error messages for syntax highlighting */
