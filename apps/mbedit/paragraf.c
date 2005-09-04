/*      paragraf.c                                    19.12.93       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    ausgelagerte functions von mbedit.c
/
/     Paragraph Fill / Justify
/
*/


/************************/
/*  include files       */
/************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "paragraf.h"
#include "mbedit.h"
#include "perform.h"
#include "mbed_sub.h"
#include "commands.h"
#include "history.h"
#include "disp_hnd.h"


#if PARAGR_COMMAND

#define TEST_VIEW 0      /* <== */


/************************/
/* some defines         */
/************************/


/************************/
/* local structures     */
/************************/

struct BOUND
   {
      long start;
      long stop;
   };

static struct BOUND bound;
static size_t eins = 1;

/* -FF-  */

long search_slope (int slope_type, int direction)
{
int full_flag, old_flag;
long result;

/* actual line */
   full_flag = non_empty_line (fc->buff_0, fc->lin_left, fc->byte_anz);
   old_flag  = full_flag;


/* which direction */
   if (direction == 1)  /* forward */
   {
      result = -1;  /* default: nothing found */

      for (;;)
      {
         old_flag  = full_flag;
         full_flag = non_empty_line (fc->buff_0, fc->lin_left, fc->byte_anz);
   
         if ((full_flag != old_flag) &&
             (full_flag == slope_type))
         {
            result = fc->lin_left;
            break;
         }

         if (fc->line_index >= fc->line_anz)
            break;

         perform_key_down (0);
      }  /* for loop forward */
   }
   else                 /* backward */
   {
      result = 0;  /* default: begin of file */

      for (;;)
      {
         old_flag  = full_flag;
         full_flag = non_empty_line (fc->buff_0, fc->lin_left, fc->byte_anz);
   
         if ((full_flag != old_flag) &&
             (full_flag == slope_type))
         {
            perform_key_down (0);
            result = fc->lin_left;
            break;
         }

         if (fc->line_index <= 0)
            break;

         perform_key_up (0);
      }  /* for loop backward */
   }

   return result;   /* -1, if nothing found (e.g. at end of file) */
}  /* search_slope */

/* -FF-  */

int para_boundaries (void)
{
/* calculate start + stop index */

/* search for start */
   if (non_empty_line (fc->buff_0, fc->lin_left, fc->byte_anz))
      bound.start = search_slope (0, 0);    /* neg. slope, backward */
   else
      bound.start = search_slope (1, 1);    /* pos. slope, forward */

   bound.start += first_nonblank (fc->buff_0, fc->lin_left, fc->byte_anz);


/* search for stop (forward: slope non empty / empty) */
   bound.stop = search_slope (0, 1);        /* neg. slope, forward */

/* no EOLN at end of file ? */
   if (bound.start > bound.stop)
   {
      perform_move (fc->byte_anz);    /* move to eof */
      perform_insert_eol ();          /* insert new line */
      bound.stop = fc->byte_index;
   }

   return (bound.stop > 0);   /* 0, if nothing found (e.g. at end of file) */
}  /* para_boundaries */

/* -FF-  */

void para_set_spaces (void)
{
/* replace white spaces with blanks, */
/* and remove multiple blanks */

int space_flag;

   perform_move (bound.start);
   space_flag = 0;
   
   for ( ;
        fc->byte_index < bound.stop - 1 - (EOLN_LEN_2);
        perform_key_right (0, 1) )
   {
      if (perform_test_eol (fc->buffer, 0))
         fc->line_anz--;

#if TEST_VIEW
      view_or_update ();
#endif

      if ((*fc->buffer == 0x09) ||    /* <tab> */
          (*fc->buffer == 0x0d) ||    /* <cr>  */
          (*fc->buffer == 0x0a) ||    /* <lf>  */
          (*fc->buffer == 0x20))      /* <space> */
      {
         *fc->buffer = 0x20;          /* ==> <space> */
         if (space_flag)
         {
            perform_delete_left_char ();
            bound.stop--;
         }
         else
         {
            space_flag = 1;
         }
      }
      else
      {
         space_flag = 0;
      }
   }

   return;
}  /* para_set_spaces */

/* -FF-  */

void para_shift_line (int delta)
{
int ii;

   for (ii = 0 ; ii < abs(delta) ; ii++)
   {
      if (delta < 0)
         perform_delete_left_char ();      /* remove <space>s */
      else
         perform_key_insert (0x20, 0);     /* insert <space>s */
   }

   return;
}  /* para_shift_line */

/* -FF-  */

int para_fill (void)
{
int soll, ist, delta, save_indent;
long last_index, new_index, old_len, new_len;

   push_video_stack ();

/* NEU ! bugfix 19.12.93 */
   perform_begin_of_line (0);

/* save indent flag */
   save_indent = set.indent;
   set.indent = 0;

/* prepare fill action */
   if (!para_boundaries ())
   {
      set.indent = save_indent;  /* restore indent flag */
      pop_video_stack ();
      return -1;  /* error, nothing found (e.g. at end of file) */
   }

   para_set_spaces ();

/* move to start position */
/* init_file_control (fc, 0); @@ */
   perform_move (bound.start);

/* set indent */
   soll  = set.margin[0];
   ist   = fc->column;
   delta = soll - ist;
   bound.start += delta;
   bound.stop  += delta;
   para_shift_line (delta);

/* process this paragraph */
   last_index = -1;
   for ( ;
        fc->byte_index < bound.stop ;
        perform_key_right (0, 1) )
   {
      if ((*fc->buffer == 0x20) ||              /* <space> ? */
          (perform_test_eol (fc->buffer, 0)))   /* end of line ? */
         last_index = fc->byte_index;

      if (fc->column > set.margin[2])   /* line limit exceeded ? */
      {
      /* line with overlength (word > maxlen) ? */
         if (last_index < 0)
         {
         /* search next blank */
            new_index = comm_find (fc->buff_0, fc->byte_index,
                                   fc->byte_anz, " ", 1,
                                   0, 0, 1, &eins);
            if ((new_index >= bound.stop) ||
                (new_index < 0))
               break;

            new_index--;
         }
         else
         {
            new_index = last_index;       /* last slope from char to <space> */
         }

         perform_move (new_index);

         old_len = fc->byte_anz;
         perform_delete_right_char ();    /* remove 1 <space> */
         perform_insert_eol ();           /* insert new line */
         new_len = fc->byte_anz;
         bound.stop += (new_len - old_len);

      /* set indent */
         soll  = set.margin[1];
         ist   = fc->column;
         delta = soll - ist;
         bound.stop  += delta;
         para_shift_line (delta);

      /* new line */
         last_index = -1;
      }
   }  /* for fc->byte_index */

/* set cursor to begin of next paragraph */
   perform_begin_of_line (0);
   new_index = search_slope (1, 1);    /* pos. slope, forward */
   if (new_index > 0)
      perform_move (new_index);

/* restore indent flag */
   set.indent = save_indent;

   pop_video_stack ();
   return 0;  /* o.k. */
}  /* para_fill */

/* -FF-  */

int para_justify (void)
{
int result, left_col, soll, ist, delta, blank;
int x, y, dx, dy;
long new_index;

   push_video_stack ();

   result = para_fill ();

   if (result < 0)
   {
      pop_video_stack ();
      return -1;  /* error, nothing found (e.g. at end of file) */
   }
   else
   {
   /* shift end 1 line above */
   /* (the last line of each paragraph must not be justified) */
      perform_move (bound.stop);
      perform_key_up (0);
      bound.stop = fc->byte_index;

   /* move to start position */
      perform_move (bound.start);

   /* process this paragraph */
      for (left_col = set.margin[0] ;     /* first line */
           fc->byte_index < bound.stop ;
           left_col = set.margin[1] ,     /* other lines */
           perform_key_down (0))
      {
         soll  = set.margin[2] + 1;
         ist   = line_length (fc->buff_0, fc->byte_index, fc->byte_anz, 0);
         delta = soll - ist;  /* no of blanks to be inserted */
         if (delta <= 0)
            continue;

         blank = line_blanks (fc->buff_0, fc->byte_index, fc->byte_anz);
         blank -= left_col;   /* no of actual blanks */
         if (blank <= 0)
            continue;

      /* move to start position */
         perform_move (fc->lin_left + left_col);

#if TEST_VIEW
         view_or_update ();
#endif

      /* bresenham algorithmus */
         dx = blank;
         dy = delta;
         y  = dx/2;
         for (x = 0 ; x < dx ; x++)
         {
         /* search next blank */
            new_index = comm_find (fc->buff_0, fc->byte_index,
                                   fc->byte_anz, " ", 1,
                                   0, 0, 1, &eins);
            perform_move (new_index);

#if TEST_VIEW
         view_or_update ();
#endif

         /* insert n blanks */
            y += dy;
            while (y > dx)
            {
               y -= dx;
               perform_key_insert (0x20, 0);
               bound.stop++;

#if TEST_VIEW
               view_or_update ();
#endif
            }  /* while y */
         }  /* for x */
      }  /* for fc->byte_index */

   /* set cursor to begin of next paragraph */
      perform_begin_of_line (0);
      new_index = search_slope (1, 1);    /* pos. slope, forward */
      if (new_index > 0)
         perform_move (new_index);
      else
         perform_begin_of_line (0);


      pop_video_stack ();
      return 0;  /* o.k. */
   }

}  /* para_justify */

/* -FF-  */

#endif

/* Modification History */
/* 06.10.93 - file erzeugt */
/* 07.10.93 - search_slope */
/* 10.10.93 - Paragraph Justify */
/* 10.10.93 - init_file_control weggelassen */
/* 11.10.93 - push_ / pop_video_stack() */
/* 20.10.93 - bugfix: Cursor Position after 'P'aragraph 'J'ustify */
/* 12.12.93 - bugfix: Fill/Justify, if last line in paragraf has len = right */
/* 19.12.93 - bugfix: Fill didn't work proper, if cursor not at begin of line */
