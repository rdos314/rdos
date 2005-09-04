/*      perform.c                                  07.09.98       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    ausgelagerte functionen von mbedit.c
/
*/


/************************/
/*  include files       */
/************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "mbedit.h"
#include "history.h"
#include "perform.h"
#include "mbed_sub.h"
#include "commands.h"
#include "blocks.h"
#include "memo_hnd.h"
#include "disp_hnd.h"
#include "mon_outp.h"
#include "err_mess.h"
#include "window.h"
#include "mb_ctype.h"


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

long perform_find (int direction, char *string,
                   int show_remark, size_t *len1)
{
long new_index;

/* anzeige, dass 'aktiv' */
   if (show_remark)
      show_status_line_2 ("searching ...", 0, -2, 0);

/* string suchen */
   new_index = comm_find (fc->buff_0, fc->byte_index,
                          fc->byte_anz, string, direction,
                          set.c_case, set.k_token, set.wildcards, len1);

   return new_index;
}  /* perform_find */

/* -FF-  */

#if (WITH_HEX_FIND)

long perform_find_byte (char byte_1, char byte_2)
{
long new_index;

/* anzeige, dass 'aktiv' */
   show_status_line_2 ("searching ...", 0, -2, 0);

/* string suchen */
   new_index = comm_find_byte (fc->buff_0, fc->byte_index,
                               fc->byte_anz, byte_1, byte_2);

   return new_index;
}  /* perform_find_byte */

#endif

/* -FF-  */

void save_find_indizes (int direction, long new_index, size_t len1)
{

/* save 1st and last char of search string (for invers display) */
   if ((new_index >= 0) && (set.wildcards))
   {
      if (direction)
      {                                      /* forward */
         fc->find[0] = new_index - len1;
         fc->find[1] = new_index;
      }
      else
      {                                      /* backward */
         fc->find[0] = new_index;
         fc->find[1] = new_index + len1;
      }
   }
   else
   {
      fc->find[0] = -1;
      fc->find[1] = -1;
   }

   return;
}  /* save_find_indizes */

/* -FF-  */

long perform_lower_upper (int up_flag)
{
long new_index;

/* string suchen */
   new_index = comm_lower_upper (fc->buff_0, fc->byte_index,
                                 fc->byte_anz, up_flag);

/* gueltiger index ? */
   if (new_index < 0L)
   {
      line_2_flag = 2;
      show_status_line_2 ("*** <F5>,<F6> at end of file ***", 0, -2, 1);
   }

   return new_index;
}  /* perform_lower_upper */

/* -FF-  */

void perform_file_reset (void)
{
   init_file_control (fc, 0);

#if (WITH_HEX_VIEW)
   if (mode_flag <= 2)       /* not in hex editor ? */
#endif
      refresh_1_window ();

   return;
}  /* perform_file_reset */

/* -FF-  */

void perform_move (long new_index)
{
long ii, new_line, delta, abs_delta;
int direction, byte_num;

#define HIGH_SPEED_MOVE  1   /* 0 = short code, 1 = fast execution */

#if (HIGH_SPEED_MOVE)
long index_0;
char FA_HU *buff_1;
int  count;
#endif

#define DELTA_LIMIT 200       /* ca. doppelte zeilenlaenge plus reserve */
#define UPDATE_CURSOR 0


/* special case: begin of file */
   if (new_index == 0L)
   {
      perform_file_reset ();
      return;
   }

/* gueltiger index ? sonst begrenzen (frueher: FATAL_ERROR) */
   new_index = min (max (new_index, 0L), fc->byte_anz);

/* is the difference old/new pointer small ? */
   delta = new_index - fc->byte_index;
   abs_delta = labs (delta);

   if (abs_delta < DELTA_LIMIT)
   {                                 /* diff is small */
      if (UPDATE_CURSOR)
         set_cursor_to (fc->lrow, REL_COLUMN);

   /* richtung */
      if (delta >= 0)
         direction = 1;
      else
         direction = -1;

   /* schleife */
      for (ii = 0 ; ii < abs_delta ; ii++)
      {
         if (direction == -1)
            byte_num = perform_key_left  (UPDATE_CURSOR,
                                          ((abs_delta-ii) > 1));
         else
            byte_num = perform_key_right (UPDATE_CURSOR,
                                          ((abs_delta-ii) > 1));

         if (byte_num == 2) ii++;     /* skip 1 byte */
      }
   }                                 /* diff is small */
   else
   {                                 /* diff is large */      
   /* cursor an zeilen anfang */
      perform_begin_of_line (UPDATE_CURSOR);

   /* n-mal rauf / runter */
#if 0
      new_line  = get_total_lines (fc->buff_0, 0L, new_index);
      delta     = new_line - fc->line_index;
#else
      if (delta > 0)
         delta =   get_total_lines (fc->buff_0, fc->byte_index, new_index);
      else
         delta = - get_total_lines (fc->buff_0, new_index, fc->byte_index);
      new_line  = fc->line_index + delta;
#endif
      abs_delta = labs (delta);

   /* richtung */
      if (delta >= 0)
         direction = 1;
      else
         direction = -1;

#if (HIGH_SPEED_MOVE)
   /* fallunterscheidung */
      if (abs_delta <= ROWS)
      {
#endif
      /* schleife */
         for (ii = 0 ; ii < abs_delta ; ii++)
         {
            if (direction == -1)
               perform_key_up (UPDATE_CURSOR);
            else
               perform_key_down (UPDATE_CURSOR);
         }
#if (HIGH_SPEED_MOVE)
      }
      else
      {
      /* NEW ! set direct ! */
         fc->byte_index = new_index;
         fc->buffer     = &fc->buff_0 [new_index];
         fc->line_index = new_line;

      /* calc: lin_left */
      /* search backward for EOL */
         buff_1 = &fc->buff_0 [new_index - 1];
         for (index_0 = (new_index - 1) ; index_0 >= 0 ; index_0--)
         {
            if (perform_test_eol1 (buff_1, -1))
               break;
            buff_1--;
         }
         fc->lin_left = index_0 + 1;


      /* calc. top_left */
         if (direction == -1)
         {
            fc->arow = 0;
            fc->top_left = fc->lin_left;
         }
         else
         {
            fc->arow = MAX_ROW - MIN_ROW;

         /* search backward for n EOLs */
            buff_1 = &fc->buff_0 [fc->lin_left - 1];
            count = MAX_ROW - MIN_ROW + 1;
            for (index_0 = (fc->lin_left - 1) ; index_0 >= 0 ; index_0--)
            {
               if (perform_test_eol1 (buff_1, -1))
               {
                  count--;
                  if (count == 0)
                     break;
               }
               buff_1--;
            }
            fc->top_left = index_0 + 1;
         }
         update_entire_window (fc->top_left);
      }
#endif


   /* zeiger setzen */
      ii = new_index - fc->byte_index;
      fc->byte_index += ii;
      fc->buffer     += ii;

   /* cursor setzen */
      fc->column = act_column (fc->buff_0, new_index);
      if (UPDATE_CURSOR)
         set_cursor_to (fc->lrow, REL_COLUMN);
   }                                 /* diff is large */      

   return;
}  /* perform_move */

/* -FF-  */

void check_dirty_cursor (void)
{
int old_column;

   old_column = fc->column;
   fc->column = act_column (fc->buff_0, fc->byte_index);

   if (EOLN_LEN_2)
   {
      if (perform_test_eol (fc->buffer, -1))
      {
         fc->byte_index--;
         fc->buffer--;
         fc->column--;
      }
   }

   if ((fc->column != old_column) && (get_video_active (0)))
   {                            /* cursor outside line */
      set_cursor_to (fc->lrow, REL_COLUMN);
   }

   return;
}  /* check_dirty_cursor */

/* -FF-  */

void check_tag_index (long old_index, long delta)
{
/* bei verschiebungen des speicherinhalts, tags mit verschieben */
/* (aber nur, wenn sie hinter der akt. position liegen,         */
/*  und nicht vor old_index !)                                  */

int ii;
#if WINDOW_COMMAND
int other_window;
#endif

   for (ii = 0 ; ii < 4 ; ii++)
   {
      if (fc->tag_index [ii] >= old_index)
      {
         fc->tag_index [ii] += delta;
         fc->tag_index [ii] = max (fc->tag_index [ii], old_index);
      }
   }

#if WINDOW_COMMAND
   if (same_buffer)
   {
      other_window = act_window + 1;
      if (other_window > 2)
         other_window = 1;

      if (fc->wind_index[other_window] >= old_index)
      {
         fc->wind_index[other_window] += delta;
         fc->wind_index[other_window] = max (fc->wind_index[other_window],
                                             old_index);
      }
   }
#endif

   return;
}  /* check_tag_index */

/* -FF-  */

int perform_insert_eol (void)
{

   return perform_key_insert (EOLN, 0);

}  /* perform_insert_eol */


#if (!TEST_EOL_MACRO)

int perform_test_eol (char *buffer, int offset)
{

   if (EOLN_LEN_1)
   {
      return (*buffer == (char)EOLN);
   }
   else
   {
      return ((buffer [  offset] == (EOLN_HIGH)) &&
              (buffer [1+offset] == (EOLN_LOW)));
   }


}  /* perform_test_eol */

#endif

/* -FF-  */

int  perform_key_left (byte update_cursor, int skip_flag)
{
char old_char;
int llen, byte_num;

   byte_num = 1;

   if (fc->byte_index > 0)
   {
      old_char = *fc->buffer;

      fc->byte_index--;
      fc->buffer--;

      if (fc->column <= 0)
      {                     /* line up */
         fc->line_index--;

         if (EOLN_LEN_2)
         {
            if ((skip_flag) && (fc->buffer[-1] == EOLN_HIGH))
            {
               fc->byte_index--;
               fc->buffer--;
               byte_num = 2;
            }
         }

         llen = act_column (fc->buff_0, fc->byte_index);
         fc->column = llen;

         llen = line_length  (fc->buff_0, fc->byte_index, fc->byte_anz, 1);
         fc->lin_left -= llen;
 
         if (fc->lrow > MIN_ROW)
         {
            fc->arow--;
            if ((update_cursor) && (get_video_active (0)))
               set_cursor_to (fc->lrow, REL_COLUMN);
         }
         else  /* scroll down */
         {
            fc->top_left -= llen;
            update_entire_window (fc->top_left);
         }
      }
      else
      {
         if ((*fc->buffer == 0x09) || (old_char == 0x09))   /* <tab> ? */
         {
            fc->column = act_column (fc->buff_0, fc->byte_index);
            if ((update_cursor) && (get_video_active (0)))
               set_cursor_to (fc->lrow, REL_COLUMN);
         }
         else
         {
            fc->column--;
            if ((REL_COLUMN > 0) && (REL_COLUMN < (COLUMNS-1)))
            {
               if ((update_cursor) && (get_video_active (0)))
                  cursor_left();
            }
         }
      }
      return byte_num;
   }
   else
   {
      return 0;
   }
}  /* perform_key_left */

/* -FF-  */

int  perform_key_right (byte update_cursor, int skip_flag)
{
char *old_char;
int  llen, byte_num, ii;

   byte_num = 1;

   for (ii = 0 ; ii < byte_num ; ii++)
   {
      if (fc->byte_index < fc->byte_anz)
      {
         old_char = fc->buffer;
   
         fc->byte_index++;
         fc->buffer++;
   
         if (*old_char == (EOLN_LOW))      /* end of line ? @@ */
         {                     /* line down */
            fc->line_index++;
   
            llen = line_length (fc->buff_0, (fc->byte_index - 1 /* - (EOLN_LEN_2) */),
                                fc->byte_anz, 1);
            fc->lin_left += llen; 
   
            fc->column = 0;
            if (fc->lrow < MAX_ROW)
            {
               fc->arow++;
               if ((update_cursor) && (get_video_active (0)))
                  set_cursor_to (fc->lrow, REL_COLUMN);
            }
            else  /* scroll up */
            {
               llen = line_length (fc->buff_0, fc->top_left, fc->byte_anz, 1);
               fc->top_left += llen; 
               update_entire_window (fc->top_left);
            }
         }
         else
         {
            if (EOLN_LEN_2)
            {
               if ((skip_flag) &&
                   (perform_test_eol (fc->buffer, -1)))
               {
                  byte_num = 2;
                  continue;
               }
               else
               {
                  if (ii > 0)
                  {
                     fc->byte_index--;
                     fc->buffer--;
                  }
               }
            }
   
            if (*old_char == 0x09)   /* <tab> ? */
            {
               fc->column = act_column (fc->buff_0, fc->byte_index);
               if ((update_cursor) && (get_video_active (0)))
                  set_cursor_to (fc->lrow, REL_COLUMN);
            }
            else
            {
               fc->column++;
               if ((REL_COLUMN >= 0) && (REL_COLUMN < (COLUMNS-1)))
               {
                  if ((update_cursor) && (get_video_active (0)))
                     cursor_right();
               }
            }
         }
      }
      else
      {
         return ii;
      }
   }  /* for ii */

   return byte_num;
}  /* perform_key_right */

/* -FF-  */

int perform_key_up (byte update_cursor)
{
long new_index;
int llen, delta;

   if (fc->line_index > 0)
   {
   /* pointer auf zeile darueber */
      llen = line_length (fc->buff_0, (fc->lin_left - 1 /* - (EOLN_LEN_2) */),
                          fc->byte_anz, 1);
      fc->lin_left -= llen;

      new_index = act_index (fc->buff_0, fc->lin_left, fc->byte_anz, fc->column);
      delta = (int)(fc->byte_index - new_index);

      fc->byte_index -= delta;
      fc->buffer     -= delta;
   
      fc->line_index--;
   
      if (fc->lrow > MIN_ROW)
      {
         fc->arow--;
         if ((update_cursor) && (get_video_active (0)))
            set_cursor_to (fc->lrow, REL_COLUMN);
      }
      else  /* scroll down */
      {
         fc->top_left -= llen;
         update_entire_window (fc->top_left);
      }

      return 1;  /* we have moved */
   }
   else
   {
      return 0;  /* we didn't */
   }
}  /* perform_key_up */

/* -FF-  */

int perform_key_down (byte update_cursor)
{
long new_index;
int llen, delta;

   if ((fc->line_index) < fc->line_anz)
   {
      llen = line_length (fc->buff_0, fc->lin_left  , fc->byte_anz, 1);

      fc->lin_left += llen;

      new_index = act_index (fc->buff_0, fc->lin_left, fc->byte_anz, fc->column);
      delta = (int)(new_index - fc->byte_index);

      fc->byte_index += delta;
      fc->buffer     += delta;

      fc->line_index++;
         
      if (fc->lrow < MAX_ROW)
      {
         fc->arow++;
         if ((update_cursor) && (get_video_active (0)))
            set_cursor_to (fc->lrow, REL_COLUMN);
      }
      else  /* scroll up */
      {
         llen = line_length (fc->buff_0, fc->top_left, fc->byte_anz, 1);
         fc->top_left += llen; 
         update_entire_window (fc->top_left);
      }

      return 1;  /* we have moved */
   }
   else
   {
      return 0;  /* we didn't */
   }
}  /* perform_key_down */

/* -FF-  */

void perform_begin_of_line (byte update_cursor)
{
int delta;

   delta = (int) (fc->byte_index - fc->lin_left);

   if ((fc->byte_index - delta) >= 0)
   {
      fc->byte_index -= delta;  /* pointer auf anfang dieser zeile */
      fc->buffer     -= delta;
   }

   if (fc->column > 0)
   {
      fc->column = 0;
      if ((update_cursor) && (get_video_active (0)))
         set_cursor_to (fc->lrow, REL_COLUMN);
   }

   return;
}  /* perform_begin_of_line */


void perform_end_of_line (byte update_cursor)
{
int llen, delta;

   llen = line_length (fc->buff_0, fc->lin_left  , fc->byte_anz, 0);

   delta = llen - (int)(fc->byte_index - fc->lin_left);

   if ((fc->byte_index + delta) <= fc->byte_anz)
   {
      fc->byte_index += delta;     /* pointer auf ende dieser zeile */
      fc->buffer     += delta;

      fc->column = line_columns (fc->buff_0, fc->byte_index, fc->byte_anz);
      if ((update_cursor) && (get_video_active (0)))
         set_cursor_to (fc->lrow, REL_COLUMN);
   }

   return;
}  /* perform_end_of_line */

/* -FF-  */

int  perform_page_up (void)
{
int ii;

#if CURSOR_STABIL
int start_row, move_flag;

/* cursor auf obere zeile */
   start_row = fc->lrow;
   for (ii = MIN_ROW ; ii < start_row ; ii++)
   {
      perform_key_up (0);
   }
#endif

/* bildschirm scrollen */
   for (ii = MIN_ROW ; ii <= MAX_ROW ; ii++)
   {
      move_flag = perform_key_up (0);
      if (!move_flag) return 0;                   /* ready ! */
   }

#if CURSOR_STABIL
/* ggf. cursor zurueck auf alte zeile */
   for (ii = MIN_ROW ; ii < start_row ; ii++)
   {
      perform_key_down (0);
   }
#endif

   update_entire_window (fc->top_left);

   return 1;
}  /* perform_page_up */


int  perform_page_down (void)
{
int ii;

#if CURSOR_STABIL
int start_row, move_flag;

/* cursor auf untere zeile */
   start_row = fc->lrow;
   for (ii = start_row ; ii < MAX_ROW ; ii++)
   {
      perform_key_down (0);
   }
#endif

/* bildschirm scrollen */
   for (ii = MIN_ROW ; ii <= MAX_ROW ; ii++)
   {
      move_flag = perform_key_down (0);
      if (!move_flag) return 0;                   /* ready ! */
   }

#if CURSOR_STABIL
/* ggf. cursor zurueck auf alte zeile */
   for (ii = start_row ; ii < MAX_ROW ; ii++)
   {
      perform_key_up (0);
   }
#endif

   update_entire_window (fc->top_left);

   return 1;
}  /* perform_page_down */

/* -FF-  */

void view_or_update (void)
{
   if ((fc->lrow <= MIN_ROW) || (fc->lrow >= MAX_ROW))
      perform_view ();
   else
      update_entire_window (fc->top_left);

   return;
}  /* view_or_update */

/* -FF-  */

void perform_scroll_screen (int delta)
{
int ii, count;
int start_row, move_flag;
long save_byte_index;
char FA_HU *save_buffer;

   count = 0;
   start_row = fc->lrow;
   save_byte_index = fc->byte_index;
   save_buffer     = fc->buffer;

/* fallunterscheidung */
   if (delta < 0)
   {                    /* analog page up */
   /* cursor auf obere zeile */
      for (ii = MIN_ROW ; ii < start_row ; ii++)
      {
         perform_key_up (0);    /* geht immer */
         count++;
      }
   
   /* bildschirm scrollen */
      for (ii = 0 ; ii < -delta ; ii++)
      {
         move_flag = perform_key_up (0);
         if (move_flag)
            count++;
         else
            break;
      }
   
   /* cursor zurueck auf alte zeile */
      for (ii = 0 ; ii < count ; ii++)
      {
         perform_key_down (0);
      }
   }
   else
   {                    /* analog page down */
   /* cursor auf untere zeile */
      for (ii = start_row ; ii < MAX_ROW ; ii++)
      {
         move_flag = perform_key_down (0);   /* geht nur, wenn file mind. */
         if (move_flag)                      /* soviel zeilen wie screen  */
            count++;
         else
            break;
      }
   
   /* bildschirm scrollen */
      for (ii = 0 ; ii < delta ; ii++)
      {
         move_flag = perform_key_down (0);
         if (move_flag)
            count++;
         else
            break;
      }
   
   /* cursor zurueck auf alte zeile */
      for (ii = 0 ; ii < count ; ii++)
      {
         perform_key_up (0);
      }
   }

   fc->byte_index = save_byte_index;
   fc->buffer     = save_buffer;

   return;
}  /* perform_scroll_screen */

/* -FF-  */

void perform_view (void)
{
int delta;
int start_row;
int rel_viewrow;


#if WINDOW_COMMAND
/* ggf. cursor ins bild schieben */
   window_adjust ();
#endif


/* abstand aktuelle zeile / soll-zeile */
   start_row = fc->lrow;
   rel_viewrow = set.viewrow
                 * (w_bot[act_window] - w_top[act_window] - STATUS_LINES)
          / max(1, (w_bot[         0] - w_top[         0] - STATUS_LINES));
   delta = start_row - MIN_ROW - rel_viewrow;


/* shift image on screen */
   perform_scroll_screen (delta);


/* reset optimized output */
   clear_text_buffers ();

/* und endlich anzeigen */
   refresh_whole_screen ();

   return;
}  /* perform_view */

/* -FF-  */

void view_unconditionally (void)
{

/* display window, even if suppressed */
   if (!get_video_active (0))
   {
      set.display |= 0x02;
      perform_view ();
      set.display &= ~0x02;
   }

   return;
}  /* view_unconditionally */

/* -FF-  */

void perform_delete_left_char (void)
{
long last_la;
int  old_bytes, old_eoln;

/* save last values */
   last_la = fc->line_anz;

/* 1 or 2 bytes ? */
    old_bytes = 1;

    if (EOLN_LEN_2)
    {
       if ((perform_test_eol (fc->buffer, -2)) &&
           (fc->byte_index > 1))
          old_bytes = 2;
    }

   if (fc->byte_index > (old_bytes-1))
   {
      perform_key_left (1, 1);
   
      if (mode_flag == 2)
      {
      /* alten inhalt restaurieren */
         if (save_x.index > 0)
         {
            old_eoln = (*fc->buffer == (char) EOLN);

            save_x.index--;
            *fc->buffer = save_x.buffer [save_x.index];

         /* war vorher <cr><lf> ? */
            if (old_bytes == 2)
            {
               fc->byte_index++;
               fc->buffer++;
               perform_delete_right_char ();
               fc->byte_index--;
               fc->buffer--;
            }
            else
            {
               if (old_eoln)
                  fc->line_anz--;
            }

         /* war einfuegung am zeilen-ende / file-ende ? */
            if (*fc->buffer == '\0')
            {
               perform_delete_right_char ();
            }

         /* display new memory content */
            if (fc->line_anz != last_la)
               update_rest_of_window (fc->lin_left, fc->lrow);
            else
               update_this_line (fc->lin_left, fc->lrow);
         }
      }
      else
      {
         perform_delete_right_char ();
      }
   }

   return;
}  /* delete_left_char */


void perform_delete_right_char (void)
{
long last_la;
int  old_bytes, nl_flag;

/* save last values */
   last_la = fc->line_anz;

/* 1 or 2 bytes ? */
   old_bytes = 1;
   nl_flag = 0;

   if ((perform_test_eol (fc->buffer, 0)) &&
       (fc->byte_index < (fc->byte_anz-(EOLN_LEN_2))))
      nl_flag = 1;

   if (EOLN_LEN_2)
   {
      if (nl_flag)
         old_bytes = 2;
   }

   if (perform_test_eol1 (fc->buffer, 0))
      nl_flag = 1;

   if (nl_flag)                 /* old <new line> */
      fc->line_anz--;

   if (fc->byte_index < fc->byte_anz - (old_bytes-1))
   {
   /* delete 1/2 bytes (shift to left the rest of the memory) */
      memcpy_rev (fc->buffer, (fc->buffer + old_bytes),
                 (fc->byte_anz - fc->byte_index));
      fc->byte_anz -= old_bytes;
      check_tag_index (fc->byte_index, (long)(-old_bytes));

   /* display new memory content */
      if (fc->line_anz != last_la)
         update_rest_of_window (fc->lin_left, fc->lrow);
      else
         update_this_line (fc->lin_left, fc->lrow);
   }

   return;
}  /* delete_right_char */


void perform_delete_start_of_line (int save_flag)
{
int delta;

   delta = (int) (fc->byte_index - fc->lin_left);
   if (delta > sizeof(save_u.buffer))
   {
      delta = sizeof(save_u.buffer);     /* sicher ist sicher */
      err_message (LINE_TOO_LONG);
   }

/* save old buffer before delete */
   if (save_flag)
   {
      save_u.anz   = delta;
      save_u.index = delta;
      save_u.command = 'X';
      memcpy (save_u.buffer, (fc->buffer - delta), delta);
   }

/* delete n bytes (shift to left the rest of the memory) */
   memcpy_rev ((fc->buffer - delta), fc->buffer,
               (fc->byte_anz - fc->byte_index + 1));
   fc->byte_anz   -= delta;
   fc->buffer     -= delta;
   fc->byte_index -= delta;                          /* bugfix:         */
   check_tag_index (fc->byte_index, (long) -delta);  /* lines exchanged */

/* cursor to begin of line */
   fc->column = act_column (fc->buff_0, fc->byte_index);    /* bugfix */


/* display new memory content */
   update_this_line (fc->lin_left, fc->lrow);

   return;
}  /* perform_delete_start_of_line */


void perform_delete_rest_of_line (void)
{
int llen, aind, delta;

   llen = line_length (fc->buff_0, fc->lin_left  , fc->byte_anz, 0);

   aind = (int) (fc->byte_index - fc->lin_left);
   delta = max (0, (llen - aind));
   if (delta > sizeof(save_u.buffer))
   {
      delta = sizeof(save_u.buffer);     /* sicher ist sicher */
      err_message (LINE_TOO_LONG);
   }

/* save old buffer before delete */
   save_u.anz   = delta;
   save_u.index = 0;
   save_u.command = 'A';
   memcpy (save_u.buffer, fc->buffer, delta);

/* delete n bytes (shift to left the rest of the memory) */
   memcpy_rev (fc->buffer, (fc->buffer + delta), 
              (fc->byte_anz - fc->byte_index + 1 - delta));
   fc->byte_anz -= delta;
   check_tag_index (fc->byte_index, (long) -delta);

/* display new memory content */
   update_this_line (fc->lin_left, fc->lrow);

   return;
}  /* perform_delete_rest_of_line */


void perform_delete_whole_line (void)
{
int sav_ind;
int llen, delta;
long new_index;

   delta = (int) (fc->byte_index - fc->lin_left);
   sav_ind = delta;

   fc->byte_index -= delta;  /* pointer auf anfang dieser zeile */
   fc->buffer     -= delta;

/* laenge der zeile incl. <lf> */
   llen = line_length (fc->buff_0, fc->lin_left  , fc->byte_anz, 1);

   delta = llen;
   if (delta > sizeof(save_u.buffer))
   {
      delta = sizeof(save_u.buffer);     /* sicher ist sicher */
      err_message (LINE_TOO_LONG);
   }

/* save old buffer before delete */
   save_u.anz   = delta;
   save_u.index = sav_ind;
   save_u.command = 'Z';
   memcpy (save_u.buffer, fc->buffer, delta);

/* anzahl zeilen mitzaehlen (bugfix, nur wenn mit end of line: 14.06.94 @@) */
   if (perform_test_eol1 (&save_u.buffer [save_u.anz-1], -1))
      fc->line_anz--;  /* anzahl lines runterzaehlen */

/* delete n bytes (shift to left the rest of the memory) */
   memcpy_rev (fc->buffer, (fc->buffer + delta), 
              (fc->byte_anz - fc->byte_index + 1 - delta));
   fc->byte_anz -= delta;
   check_tag_index (fc->byte_index, (long) -delta);

/* old line below is now under cursor */
   new_index = act_index (fc->buff_0, fc->lin_left, fc->byte_anz, fc->column);
   delta = (int)(new_index - fc->byte_index);

   fc->byte_index += delta;
   fc->buffer     += delta;

/* display new memory content */
   update_rest_of_window (fc->lin_left, fc->lrow);

   return;
}  /* perform_delete_whole_line */


int perform_undo (void)
{
int  delta;

/* ist ueberhaupt was im buffer ? */
   if (save_u.anz == 0)        
   {                      /* nein ! */
      return 1;
   }

/* passt save_u.buffer noch mit rein ? */
   if (check_and_increase_buffer (fc, (fc->byte_anz + save_u.anz),
                                  FILE_RESERVE, 0) < 0)
   {                      /* nein ! */
      err_message (BUFFER_OVERFLOW);
      return 0;
   }

/* sonst ... */
/* war voriges kommando ^Z ? */
   if (save_u.command == 'Z')
   {
      if (perform_test_eol1 (&save_u.buffer [save_u.anz-1], -1))
         fc->line_anz++;  /* anzahl lines hochzaehlen */

      delta = (int) (fc->byte_index - fc->lin_left);
   
      fc->byte_index -= delta;
      fc->buffer     -= delta;
   
   /* cursor to begin of line */
      fc->column = 0;
   }

/* erstmal platz machen */
   memcpy_rev ((fc->buffer + save_u.anz), fc->buffer,
               (fc->byte_anz - fc->byte_index + 1));
   fc->byte_anz += save_u.anz;
   check_tag_index (fc->byte_index, (long) save_u.anz);

/* jetzt buffer holen */
   memcpy (fc->buffer, save_u.buffer, save_u.anz);

/* cursor auf alte position setzen */
   fc->byte_index += save_u.index;
   fc->buffer     += save_u.index;
   fc->column = act_column (fc->buff_0, fc->byte_index);

/* display new memory content */
   if (save_u.command == 'Z')
      update_rest_of_window (fc->lin_left, fc->lrow);
   else
      update_this_line (fc->lin_left, fc->lrow);

   return 1;
}  /* perform_undo */

/* -FF-  */

int valid_char (int key)
{
   if (((key >= 0x20) && ( key <= 0x7e)) ||    /* normal printable */
        (key == 0x09) ||                       /* <tab>     */
        (key == 0x0d) ||                       /* <cr>      */
        (key == 0x0a) ||                       /* <lf>      */
        (key == 0x0d0a) ||                     /* <cr><lf>  */
        (key >= 0x80))                         /* deutsches sonderzeichen */
      return 1;
   else
      return 0;
}  /* valid_char */


int perform_string_insert (char *string)
{
int flag, count;

   count = 0;
   while (*string)
   {
      flag = perform_key_insert (*string, 1);

      if (flag == 1)
      {
         string++;                     /* char was inserted */
         count++;
      }
      else
      {
         break;                        /* abort while loop */
      }
   }

   return count;
}  /* perform_string_insert */


void check_for_autonl (void)
{
long index_0, first_ind, last_ind, save_tag_a;
char FA_HU *buff_1;
int delta;

/* automatic insertion of <nl> ? */
   if ((mode_flag == 1) &&                  /* insert mode    ? */
       (set.autonl)     &&                  /* 'S'et 'A'utonl ? */
       (fc->column > (set.margin[2]) + 1))  /* line limit exceeded ? */
   {
   /* save last position */
      save_tag_a       = fc->tag_index[0];
      fc->tag_index[0] = fc->byte_index;

   /* this part of the screen must be refreshed */
      update_rest_of_window (fc->lin_left, fc->lrow);

   /* search backward for first + last white spaces (in one sequence) */
      first_ind = fc->lin_left;
      last_ind  = -1;

      for (index_0 = fc->byte_index-1 , buff_1 = fc->buffer-1 ;
           index_0 >= fc->lin_left ; 
           index_0--                  , buff_1--)
      {
         if (isspace(*buff_1) && (last_ind == -1))
         {
            last_ind = index_0 + 1;
         }

         if ((!isspace(*buff_1)) && (last_ind != -1))
         {
            first_ind = index_0 + 1;
            break;
         }
      }

   /* delete all white spaces, if found any */
      if (last_ind != -1)
      {
         delta = (int) (last_ind - first_ind);
         perform_move (last_ind);
      
      /* delete n bytes (shift to left the rest of the memory) */
         memcpy_rev ((fc->buffer - delta), fc->buffer,
                     (fc->byte_anz - fc->byte_index + 1));
         fc->byte_anz   -= delta;
         fc->buffer     -= delta;
         fc->byte_index -= delta;
         check_tag_index (fc->byte_index, (long) -delta);
      }

   /* insert <nl> */
      perform_key_insert (EOLN, 0);

   /* restore last position */
      perform_move (fc->tag_index[0]);
      fc->tag_index[0] = save_tag_a;
   }

   return;
}  /* check_for_autonl */


int perform_key_insert (int key, int check)
{
int new_bytes;

/* 1 or 2 bytes ? */
   new_bytes = 1;

   if (EOLN_LEN_2)
   {
      if (key == EOLN)
         new_bytes = 2;
   }

   if ((check) && (!valid_char (key)))
   {
      err_message (INVALID_CHARACTER);
      return 0;
   }

   if (check_and_increase_buffer (fc, (fc->byte_anz + new_bytes),
                                  FILE_RESERVE, 0) < 0)
   {
      err_message (BUFFER_OVERFLOW);
      return 0;
   }
   
/* buffer um 1/2 bytes nach hinten schieben */
   memcpy_rev ((fc->buffer + new_bytes), fc->buffer,
               (fc->byte_anz - fc->byte_index + 1));
   fc->byte_anz += new_bytes;
   check_tag_index (fc->byte_index, (long) new_bytes);


/* aktuelles zeichen loeschen,                    */
/* damit in ..._exchange die zeilen_bilanz stimmt */
   memset (fc->buffer, 0, new_bytes);

/* aktuelles zeichen ueberschreiben */
   return perform_key_exchange (key, check);
}  /* perform_key_insert */


int perform_key_exchange (int key, int check)
{
long last_la, last_left, new_index;
int  last_row, len;
int  new_bytes, old_bytes, shift, end_flag;

/* valid char ? */
   if ((check) && (!valid_char (key)))
   {
      err_message (INVALID_CHARACTER);
      return 0;
   }

/* save last values */
   last_la   = fc->line_anz;
   last_left = fc->lin_left;
   last_row  = fc->lrow;

/* 1 or 2 bytes ? */
   new_bytes = 1;
   old_bytes = 1;

   if (EOLN_LEN_2)
   {
      if (key == EOLN)
         new_bytes = 2;
   
      if (perform_test_eol (fc->buffer, 0))
         old_bytes = 2;
   }

/* at end of line / end of file ? */
   if ((perform_test_eol  (fc->buffer, 0)) ||
       (perform_test_eol1 (fc->buffer, 0)) ||
       (fc->byte_index == fc->byte_anz))
   {
      end_flag = 1;
      shift = new_bytes;
   }
   else
   {
      end_flag = 0;
      if (mode_flag == 2)     /* exchange mode */
         shift = new_bytes - old_bytes;     /* = 1, if <cr><lf> inside line */
      else
         shift = 0;
   }

   if (shift)
   {
      if (check_and_increase_buffer (fc, (fc->byte_anz + shift),
                                     FILE_RESERVE, 0) < 0)
      {
         err_message (BUFFER_OVERFLOW);
         return 0;
      }
      
   /* buffer um 1/2 byte nach hinten schieben */
      memcpy_rev ((fc->buffer + shift), fc->buffer,
                  (fc->byte_anz - fc->byte_index + 1));
      fc->byte_anz += shift;
      check_tag_index (fc->byte_index, (long) shift);
   }

/* aktuelles zeichen loeschen, */
/* als merker in save_x.buffer */
   if (end_flag)
      *fc->buffer = '\0';

/* save old data */
   if (save_x.index < sizeof(save_x.buffer))
   {
      save_x.buffer [save_x.index] = *fc->buffer;
      save_x.index++;
   }

/* overwrite char */
   if (new_bytes == 2)
   {
      *fc->buffer    = EOLN_HIGH;
      fc->buffer [1] = EOLN_LOW;
      fc->line_anz++;                          /* new <cr><lf> */
   }
   else
   {
      *fc->buffer = (char) key;                /* store new char */

      if (key == EOLN_LOW)
         fc->line_anz++;
   }

   perform_key_right (1, 1);
   
   /* indent during insertion ? */
   if ((key == EOLN) && (set.indent))
   {
      len = first_nonblank (fc->buff_0, last_left, fc->byte_anz);
      if (check_and_increase_buffer (fc, (fc->byte_anz + len),
                                     FILE_RESERVE, 0) < 0)
      {
         err_message (BUFFER_OVERFLOW);
         len = (int) (fc->buffer_size - fc->byte_anz) - 1;
      }
      block_insert (fc->buff_0, fc->byte_index,
                    fc->byte_anz, fc->buffer_size,
                    &fc->buff_0 [last_left], (long) len);

      fc->byte_anz += len;
      check_tag_index (fc->byte_index, (long) len);
      new_index = fc->byte_index + len;
      perform_move (new_index);

   /* was old line completely blank ? */
      if (len == line_length (fc->buff_0, last_left, fc->byte_anz, 0))
      {
         new_index = fc->byte_index - len;
         perform_key_up (0);
         perform_delete_start_of_line (0);
         perform_move (new_index);
      }
   }

/* display new memory content */
   if (fc->line_anz != last_la)
      update_rest_of_window (last_left, last_row);
   else
      update_this_line (fc->lin_left, fc->lrow);

   return 1;
}  /* perform_key_exchange */

/* -FF-  */

int perform_file_compare (void)
{
/* compare 2 files from actual cursor position, stop at 1st difference */

/* 1st case: screen with one single window: compare this  / other file */
/* 2nd case: split screen with two windows: compare upper / lower file */


char FA_HU *buffer_a, FA_HU *buffer_b;
long byte_anz_a, byte_index_a;
long byte_anz_b, byte_index_b;

struct RESULT {
                 int flag;
                 char *message;
              };

static struct RESULT result [] = {0, "file compare: running ...",
                                  0, "file compare: difference found",
                                 -1, "file compare: no difference",
                                 -1, "file compare: end of file"};
                     
enum COMP_STATUS
       {
          STAT_RUNNING,
          STAT_DIFF_FOUND,
          STAT_NO_DIFF,
          STAT_EOF
       } comp_status;


/* display activity */
   line_2_flag = 2;
   comp_status = STAT_RUNNING;
   show_status_line_2 (result[comp_status].message, 0, -2, 0);


/* prepare loop */

#if WINDOW_COMMAND
   if (act_window)
   {
   /* file a */
      buffer_a     = fc->buffer     + 1;
      byte_index_a = fc->byte_index + 1;
      byte_anz_a   = fc->byte_anz;
      window_change ();

   /* file b */
      buffer_b     = fc->buffer     + 1;
      byte_index_b = fc->byte_index + 1;
      byte_anz_b   = fc->byte_anz;
      window_change ();
   }
   else
#endif
   {
   /* file a */
      buffer_a     = fc->buffer     + 1;
      byte_index_a = fc->byte_index + 1;
      byte_anz_a   = fc->byte_anz;
      get_next_file_buffer (1);

   /* file b */
      buffer_b     = fc->buffer     + 1;
      byte_index_b = fc->byte_index + 1;
      byte_anz_b   = fc->byte_anz;
      get_next_file_buffer (-1);
   }

/* check for EOF */
   if ((byte_index_a >= byte_anz_a) ||
       (byte_index_b >= byte_anz_b))
   {
      comp_status = STAT_EOF;
   }
   else
   {
   /* default */
      comp_status = STAT_NO_DIFF;

   /* compare loop */
      for ( ;
           (byte_index_a < byte_anz_a) &&
           (byte_index_b < byte_anz_b) ;
            byte_index_a++, buffer_a++,
            byte_index_b++, buffer_b++)
      {
         if (*buffer_a != *buffer_b)
         {
            comp_status = STAT_DIFF_FOUND;
            break;
         }
      }  /* for byte_index */

   /* loop complete passed without any difference ? */
      if (comp_status == STAT_NO_DIFF)
      {
      /* only 1 EOF ? */
         if ((byte_anz_a - byte_index_a) !=
             (byte_anz_b - byte_index_b))
         {
            comp_status = STAT_DIFF_FOUND;
         }
      }
   }

/* show result */
   if (comp_status != STAT_NO_DIFF)
   {
#if WINDOW_COMMAND
      if (act_window)
      {
      /* file a */
         perform_move (byte_index_a);
         perform_view ();
         window_change ();
   
      /* file b */
         perform_move (byte_index_b);
         perform_view ();
         window_change ();
      }
      else
#endif
      {
      /* file a */
         perform_move (byte_index_a);
         get_next_file_buffer (1);
   
      /* file b */
         perform_move (byte_index_b);
         get_next_file_buffer (-1);
   
         perform_view ();
      }
   }

   line_2_flag = 2;
   show_status_line_2 (result[comp_status].message, 0, -2, 0);

   return result[comp_status].flag;  /* 0 = YES, -1 = NO */
}  /* perform_file_compare */

/* -FF-  */

/* Modification History */
/* 06.12.92 - file erzeugt */
/* 07.12.92 - perform_help_option () */
/* 20.12.92 - bei set.indent: buffer overflow abfangen ! */
/* 22.12.92 - perform_intro () */
/* 30.12.92 - help_option erweitert */
/* 02.01.93 - int perform_key_insert ()     (vorher void) */
/* 03.01.93 - MACRO_NESTING_TO_DEEP */
/* 06.01.93 - perform_special_keys () */
/* 08.01.93 - perform_find (..., repeat_count, repeat_max, replace_count) */
/* 02.08.93 - EOL --> EOLN */
/* 04.08.93 - Bug Fix for BINARY_MODE 0: exchange at end of line */
/* 05.08.93 - DELTA_LIMIT 200 (vorher 40) */
/* 12.08.93 - perform_test_eol: offset = offset; */
/* 25.08.93 - perform_view (): line_2_flag = 1   (update status line 2 !) */
/* 31.08.93 - delete_whole_line (): decr. line_anz conditionally */
/* 03.09.93 - Bug Fix: indent with old blank old line and <tab>s */
/* 03.09.93 - perform_delete_start_of_line (int save_flag) */
/* 05.09.93 - Find mit Wildcard: '?' */
/* 07.09.93 - perform_find (..., size_t *len1) */
/* 08.09.93 - save_find_indizes () */
/* 10.09.93 - perform_end_of_line (): special case last line in file */
/* 12.09.93 - get_video_active (ignore_batch) */
/* 16.09.93 - TEST_EOL_MACRO */
/* 29.09.93 - update_rest_of_window(), ...entire_window() */
/* 01.10.93 - window_adjust () */
/* 02.10.93 - init_file_control (fc, 0) */
/* 03.10.93 - perform_scroll_screen () */
/* 10.10.93 - bugfix: perform_move zwischen <cr> und <lf> */
/* 11.10.93 - perform_key_left() / right(.., skip_flag) */
/* 19.10.93 - handling of single <lf>s */
/* 05.11.93 - bugfix: single <lf> in one line */
/* 21.05.94 - perform_move(): limit new_index, statt FATAL_ERROR */
/* 03.06.94 - perform_view(): avoid division by zero */
/* 14.06.94 - perform_delete_whole_line: bugfix:                           */
/*            (no of lines in file was counted wrong, if line > 256 chars) */
/* 14.06.94 - err_message (LINE_TOO_LONG) */
/* 04.07.94 - perform_delete_start_of_line(): bugfix: <tab> ^X */
/* 06.07.94 - check_for_autonl() */
/* 09.07.94 - view_unconditionally() */
/* 21.09.94 - perform_file_reset(): refresh_1_window (), if not in hex edit */
/* 23.09.94 - perform_scroll_screen (): save_byte_index, save_buffer */
/*            (bugfix: vorher inkonsistenter Zustand moeglich,       */
/*            wenn cursor position hinter 0x0d, auf 0x0a)            */
/* 25.09.94 - perform_move (): HIGH_SPEED_MOVE */
/* 28.09.94 - bugfix: HIGH_SPEED_MOVE */
/* 16.02.95 - perform_file_compare() */
/* 20.02.95 - perform_file_compare(), bugfix: long ii (statt int) */
/* 22.02.95 - perform_file_compare(), schleifendurchlaeufe um 1 verringert */
/* 24.02.95 - perform_file_compare(), bugfix (EOF) */
/* 26.04.95 - perform_move(): speed up for "diff is large" */
/* 16.06.95 - check_for_autonl(): (fc->column > (set.margin[2]) + 1)      */
/*            'P'aragraph 'F'ill, und 'S'et 'A'utoinsert 'Y'es o.k. */
/* 26.01.96 - perform_find_byte() */
/* 31.01.96 - WITH_HEX_FIND */
/* 05.09.98 - EOLN_LEN_1 and EOLN_LEN_2: #if --> if */
/* 07.09.98 - EOLN_LEN_1: type cast --> (char) */
