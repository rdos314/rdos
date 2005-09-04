/*      blocks.c                                  16.09.93       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    block_save, _restore, _remove, _insert
/
*/


/************************/
/*  include files       */
/************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "blocks.h"
#include "mbed_sub.h"
#include "memo_hnd.h"
#include "history.h"
#include "disp_hnd.h"
#include "file_hnd.h"


/************************/
/* some defines         */
/************************/



/************************/
/* local structures     */
/************************/


/************************/
/*  module definitions  */
/************************/

static long save_length;
static char FA_HU *save_buffer;

/* -FF-  */

/* for perform_special_keys () */

long get_save_length (void)
{
   return save_length;
}

char * get_save_buffer (void)
{
   return (char *) save_buffer;
}

/* -FF-  */

int block_save (char FA_HU *buff_0, long index1, long index2)
{
/* block in hilfsbuffer abspeichern (Commands 'D', 'B') */

char FA_HU *src;
long abs_delta;


/* calc buffer size */
   abs_delta = labs (index2 - index1);
   

/* do we need a new buffer ? */
   if (abs_delta != save_length)
   {
   /* free old buffer ? (not, if 1st call !) */
      if (save_buffer != NULL)
         loc_free (save_buffer);

   /* get new buffer */
		save_buffer = (char *)loc_malloc (max (abs_delta, 1));     /* mind. 1 byte, */
                                    /* denn (loc_malloc (0) liefert NULL) */
      if (save_buffer == NULL)
      {
         save_length = 0;
         return -1;   /* error */
      }
      else
      {
         save_length = abs_delta;
      }
   } 

/* jetzt geht's aber los */
   src = &buff_0 [min (index1, index2)];

/* save buffer */
   memcpy_rev (save_buffer, src, abs_delta);

   return 0;   /* o.k. */
}  /* block_save */

/* -FF-  */

long block_restore (struct FILE_CONTROL *fc0)
{
/* block aus hilfsbuffer zuruecklesen und einfuegen (Command 'G') */


/* buffer empty ? */
   if (save_length == 0)
      return 0;    /* nothing to do */


/* buffer available ? */
   if (save_buffer == NULL)
      return -2;   /* fatal error */


/* return value ist delta-index */
   if (check_and_increase_buffer (fc0, (fc0->byte_anz + save_length),
                                  FILE_RESERVE, 0) < 0)
      return -1;

   return block_insert (fc0->buff_0, fc0->byte_index,
                        fc0->byte_anz, fc0->buffer_size,
                        save_buffer, save_length);

}  /* block_restore */

/* -FF-  */

long block_remove (char FA_HU *buff_0, long index1, long index2, long byte_anz)
{
/* block aus dem speicher entfernen (Commands 'R', 'D') */

char FA_HU *src;
char FA_HU *dest;
long length;

   if (index2 >= index1)   /* manchmal nach 'D', immer nach 'R' */
   {
      src  = &buff_0 [index2];
      dest = &buff_0 [index1];
      length = byte_anz - index2 + 1;
   }
   else
   {
      src  = &buff_0 [index1];
      dest = &buff_0 [index2];
      length = byte_anz - index1 + 1;
   }

/* shift buffer */
   memcpy_rev (dest, src, length);

   return labs (index2 - index1);     /* delta byte_anz */
}  /* block_remove */

/* -FF-  */

long block_insert (char FA_HU *buff_0, long index1,
                   long byte_anz, long max_len,
                   char FA_HU *ins_buff, long len2)
{
/* block im speicher zwischenschieben (Commands 'G' und 'R') */

char FA_HU *src;
char FA_HU *dest;
long length;

   if ((byte_anz + len2) >= max_len)
   {
      return -1;  /* error */
   }
   else
   {
      src  = &buff_0 [index1];
      dest = &buff_0 [index1 + len2];
      length = byte_anz - index1 + 1;
   
   /* shift buffer */
      memcpy_rev (dest, src, length);

   /* insert buffer */
      memcpy_rev (src, ins_buff, len2);  /* reihenfolge stimmt (!) */

      return len2;    /* delta byte_index */
   }
}  /* block_insert */

/* -FF-  */

int check_and_increase_buffer (struct FILE_CONTROL *fc0, 
                               long new_size, long reserve,
                               int force_malloc)
{
char FA_HU * new_buffer;
char FA_HU * old_buff_0;
int write_flag, error_flag;
STATIC char tmp_filename [BUF_256 + FILENAME_LEN];

   error_flag = 0;  /* default */

/* check new size */
   if ((new_size + reserve) == fc0->buffer_size)
   {
      return 0;    /* alles o.k. */
   }

   if ((new_size < fc0->buffer_size) && 
       !(force_malloc))
   {
      return 0;    /* alles o.k. */
   }


/* build temp. filename */
   strcpy (tmp_filename, TEMP_DIR);
   strcat (tmp_filename, FILE_SEPARATOR);
   strcat (tmp_filename, TEMPO_FILENAME);

/* try to get new buffer */
   new_size += reserve;
   new_size = max (1L, new_size);  /* min. size = 1 Byte !! */
	new_buffer = (char *)loc_malloc (new_size);

   if (new_buffer != NULL)
   {
   /* alten buffer auf neuen kopieren */
      memcpy_rev (new_buffer, fc0->buff_0, min(new_size, fc0->buffer_size));
      old_buff_0 = fc0->buff_0;

   /* update file_control */
      fc0->buff_0      = new_buffer;
      fc0->buffer      = fc0->buff_0 + fc0->byte_index;
      fc0->buffer_size = new_size;

   /* put back old buffer to pool */
      loc_free (old_buff_0);
      return 1;        /* o.k. */
   }
   else
   {
   /* perhaps it is not possible, to keep old and new buffer    */
   /* simultaneously in memory. so try the following procedure: */

      push_video_stack ();   /* switch OFF display */

   /* save old buffer in temp directory */
      write_flag = write_datafile (tmp_filename,
                                   fc0->buff_0, fc0->byte_anz, 1, 0);
      if (write_flag != 0)
      {
         error_flag = -1;
      }
      else
      {
      /* put back old buffer to pool */
         loc_free (fc0->buff_0);
         fc0->malloc_flag = 0;

      /* try to get new buffer */
			new_buffer = (char *)loc_malloc (new_size);

         if (new_buffer != NULL)              /* o.k. */
         {
            fc0->malloc_flag = 1;

         /* read back old file */
            read_datafile (tmp_filename, new_buffer, new_size, 1);
            
         /* update file_control */
            fc0->buff_0      = new_buffer;
            fc0->buffer      = fc0->buff_0 + fc0->byte_index;
            fc0->buffer_size = new_size;

            error_flag = 1;  /* o.k. */
         }
         else                                 /* wasn't sufficient yet */
         {                                    /* try to get back old buffer */
            new_buffer = (char *)loc_malloc (fc0->buffer_size);
            if (new_buffer != NULL)
            {
               fc0->malloc_flag = 1;

            /* read back old file */
               read_datafile (tmp_filename, new_buffer,
                              fc0->buffer_size, 1);
            
            /* update file_control */
               fc0->buff_0      = new_buffer;
               fc0->buffer      = fc0->buff_0 + fc0->byte_index;

               error_flag = -2;  /* at least got back old buffer */
            }
            else
            {
               error_flag = -3;  /* got nothing, fatal error */
            }
         }
      }
      delete_datafile (tmp_filename);

      pop_video_stack ();   /* switch ON display */
      return error_flag;
   }

}  /* check_and_increase_buffer */

/* -FF-  */

/* Modification History */
/* 02.12.92 - file erzeugt */
/* 04.12.92 - block_restore (): save_length == 0 abfragen */
/* 20.12.92 - FA_HU */
/* 05.01.93 - check_and_increase_buffer () */
/* 06.01.93 - block_restore, block_insert: max_len */
/* 26.04.93 - Generierung temp. filename */
/* 28.08.93 - STATIC */
/* 02.09.93 - delete_datafile () */
/* 16.09.93 - check_and_increase_buffer(): if (new == old size) return 0 */
