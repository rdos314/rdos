/*      window.c                                    08.02.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 2004: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    ausgelagerte functions von mbedit.c
/
/     Window, Kill_Window
/
*/


/************************/
/*  include files       */
/************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "window.h"
#include "mbedit.h"
#include "perform.h"
#include "history.h"
#include "disp_hnd.h"
#include "err_mess.h"
#include "mousec.h"
#include "kb_input.h"


/************************/
/* some defines         */
/************************/


/************************/
/* local structures     */
/************************/

#if WINDOW_COMMAND

static struct FILE_CONTROL *fc2 [3];


/************************/
/*  module definitions  */
/************************/

/* -FF-  */

static int window_split (void)
{
#define MIN_ROW_NUM (STATUS_LINES+3)   /* min. 3 text rows per window */
int  row;
long byte_index;


/* check row limits */
   if (fc->lrow > (ROWS-MIN_ROW_NUM))
   {                                   /* too big */
      err_message (WINDOW_TOO_SMALL);
      return 0;
   }
   else
   {
      if (fc->lrow < MIN_ROW_NUM)
      {                                /* too small */
         row = MIN_ROW_NUM;
         byte_index = fc->top_left;
      }
      else
      {                                /* normal case */
         row = fc->lrow;
         byte_index = fc->byte_index;
      }
   }


/* set new window limits */
   w_top[1] = w_top[0];
   w_bot[1] = row-1;

   w_top[2] = row;
   w_bot[2] = w_bot[0];


/* set flag */
   same_buffer   = 1;


/* window 1 */
   fc2[1] = fc;
   fc->wind_arow [1] = 0;
   fc->wind_index[1] = fc->top_left;

/* window 2 */
   fc2[2] = fc;
   fc->wind_arow [2] = 0;
   fc->wind_index[2] = byte_index;

/* initial window is 1 or 2 */
#define START_WINDOW 2      /* <== select here */

#if (START_WINDOW == 1)
   act_window = 1;
   fc->byte_index = fc->top_left;
#else
   act_window = 2;
   fc->top_left = fc->lin_left;
#endif

   fc->arow  = 0;
   act_buff_no [act_window] = fc->buff_no;

   return 1;

}  /* window_split */

/* -FF-  */

void set_file_indizes (void)
{
int old_arow;
int delta;
long help_index;

   old_arow   = fc->wind_arow [act_window];
   help_index = fc->wind_index[act_window];

   /* perform_file_reset (); */
   init_file_control (fc, 0);
   perform_move (help_index);
   delta = fc->arow - old_arow;
   perform_scroll_screen (delta);

   return;
}  /* set_file_indizes */

/* -FF-  */

int window_change (void)
{
int buff_no;

   if (act_window == 0)
      return 0;

/* save actual window */
   fc2[act_window] = fc;
   fc->wind_arow [act_window] = fc->arow;
   fc->wind_index[act_window] = fc->byte_index;

/* update window */
   perform_update (fc->buff_0, fc->byte_anz, fc->left_col);
   line_2_flag = 1;

/* toggle window */
   act_window++;
   if (act_window > 2)
      act_window = 1;

/* set new window */
   buff_no = fc2[act_window]->buff_no;
   fc = &file_control[buff_no];
   fc2[act_window] = fc;
   act_buff_no [act_window] = fc->buff_no;

/* move to position */
   fc->arow       = fc->wind_arow [act_window];
   fc->byte_index = fc->wind_index[act_window];
   same_buffer = (fc2[1] == fc2[2]);
   set_file_indizes ();

   window_adjust ();

   return 1;
}  /* window_change */

/* -FF-  */

int window_do (void)
{
int result;

   if (act_window == 0)
   {
      result = window_split ();
      if (result)
         refresh_whole_screen ();
   }
   else
   {
      result = window_change ();
      if (result)
         update_entire_window (fc->top_left);
   }

#if WITH_MOUSE
   MouSetMoveArea ( 0                , (byte) TOP_ROW,
                   (byte) (COLUMNS-1), (byte) MAX_ROW,
                    0);
#endif
  
   return result;
}  /* window_do */

/* -FF-  */

int window_kill (void)
{
   if (act_window == 0)
      return 0;

   act_window = 0;
   act_buff_no [act_window] = fc->buff_no;

   same_buffer = 0;

   perform_view ();

#if WITH_MOUSE
   MouSetMoveArea ( 0                , (byte) TOP_ROW,
                   (byte) (COLUMNS-1), (byte) MAX_ROW,
                    0);
#endif

   return 1;
}  /* window_kill */

/* -FF-  */

int window_set (int flag)
{
/* flag = 1 - call from : Other (before) / Quit Init */
/*        2 - call from : Other (after)              */

   if (act_window == 0)
      return 0;

   fc2[act_window] = fc;
   same_buffer = (fc2[1] == fc2[2]);

   if (flag == 1)
   {
      fc->wind_arow [act_window] = fc->arow;
      fc->wind_index[act_window] = fc->byte_index;
   }
   else
   {
      fc->arow       = fc->wind_arow [act_window];
      fc->byte_index = fc->wind_index[act_window];

      set_file_indizes ();
   }

   return 1;
}  /* window_set */

/* -FF-  */

int window_adjust (void)
{
int ii, delta, window_adjusted = 0;
int delta_line_file, last_line_window, line_gap_window;


   /* cursor outside (below) window ? */
   if (fc->lrow > MAX_ROW)
   {
      delta = fc->lrow - MAX_ROW;

      /* adjust cursor */
      for (ii = 0 ; ii < delta ; ii++)
      {
         perform_key_up (0);         
      }

      for (ii = 0 ; ii < delta ; ii++)
      {
         perform_key_down (0);         
      }

      window_adjusted = 1;
   }
   else
   {
      /* last line of file above end of window ? */
      delta_line_file  = fc->line_anz - fc->line_index;
      last_line_window = fc->lrow + delta_line_file;
      line_gap_window  = MAX_ROW - last_line_window;
      
      if (line_gap_window > 0)
      {
         delta = line_gap_window + fc->lrow;
         delta = min (delta, fc->line_index);
   
         /* adjust cursor */
         for (ii = 0 ; ii < delta ; ii++)
         {
            perform_key_up (0);         
         }
   
         for (ii = 0 ; ii < delta ; ii++)
         {
            perform_key_down (0);         
         }
   
         window_adjusted = 1;
      }
      else
      {
         window_adjusted = 0;
      }
   }

   return window_adjusted;
}  /* window_adjust */

/* -FF-  */

#endif

/* Modification History */
/* 28.09.93 - file erzeugt */
/* 30.09.93 - WINDOW_COMMAND */
/* 01.10.93 - window_adjust() */
/* 04.10.93 - window_change(): init_file_control anstatt perform_file_reset */
/* 10.12.93 - MouSetMoveArea () */
/* 12.12.93 - MouSetMoveArea (..., 0) */
/* 25.05.94 - window_change (): line_2_flag = 1 */
/* 25.05.94 - upper window 1+2 lines small (split screen with short files) */
/* 08.02.04 - window_adjust(): scroll down text, if last line above bottom */
