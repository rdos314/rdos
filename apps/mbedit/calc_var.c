/*      calc_var.c                                     13.03.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    calc_var handler fuer mbedit.c
/
*/


/************************/
/*  include files       */
/************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "calc_var.h"
#include "blocks.h"
#include "macro.h"
#include "commands.h"
#include "switches.h"
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

void get_calc_variables (struct CALC_VARS * cv)
{
time_t act_time;
struct tm * tm0;
static char string [BUF_256];

/* begin / end of file */
   cv->bof = -(fc->byte_index == 0L);
   cv->eof = -(fc->byte_index == fc->byte_anz);

/* current / next character / word */
   cv->curch = 0;
   cv->curwd = 0;
   cv->nxtch = 0;
   cv->nxtwd = 0;

   if (fc->byte_index < fc->byte_anz)
      cv->curch = *fc->buffer;

   if (fc->byte_index < (fc->byte_anz-1))
   {
      cv->nxtch = fc->buffer[1];
      cv->curwd = (word)(fc->buffer[0] + (fc->buffer[1] << 8));
   }

   if (fc->byte_index < (fc->byte_anz-3))
      cv->nxtwd = (word)(fc->buffer[2] + (fc->buffer[3] << 8));

   cv->lowch = (byte) tolower (cv->curch);
   cv->upch  = (byte) toupper (cv->curch);

/* next tab */
   cv->nxttab = ((fc->column / set.tabs) + 1) * set.tabs;

/* is delimiter */
   cv->isdel = -is_delimiter (*fc->buffer);

/* is white space */
   cv->iswhte = -isspace(*fc->buffer);

/* values from switches.c (Find/Replace) */
   get_calc_vars_switches (cv);

/* row / column */
   cv->row = fc->lrow;
   cv->col = fc->column;

/* diverse file informations */
   cv->curpos = fc->byte_index;
   cv->inothr = fc->buff_no;

/* div. strings */
   strncpy (string, get_save_buffer (),
            (size_t) min (get_save_length (), (sizeof(string) - 1)));
   string [sizeof(string) - 1] = '\0';    /* forced end of string */
   cv->sb = string;

   cv->sd = fc->e_delimit;
   cv->se = fc->filename;
   cv->sg = str_getf;
   cv->si = file_control [0].filename;
   cv->sm = get_macro_filename ();
   cv->so = file_control [1].filename;
   cv->sp = str_putf;
   cv->sr = str_repl;
   cv->st = str_find; 
   cv->sw = str_q_wr;
   cv->sy = str_synt;

/* Tags */
   cv->taga = max (0L, fc->tag_index [0]);  /* aedit-kompatibel */
   cv->tagb = max (0L, fc->tag_index [1]);
   cv->tagc = max (0L, fc->tag_index [2]);
   cv->tagd = max (0L, fc->tag_index [3]);

/* date / time */
   act_time = time (NULL);
   tm0 = localtime (&act_time);
   cv->date = ((tm0->tm_mon + 1)*100L + tm0->tm_mday)*100L + (tm0->tm_year % 100);
   cv->time = ((tm0->tm_hour   )*100L + tm0->tm_min )*100L +  tm0->tm_sec;    

/* margins */
   cv->imargn = set.margin [0];   /* z.Z. fix values */
   cv->lmargn = set.margin [1];
   cv->rmargn = set.margin [2];

/* macros */
   cv->nstlvl = get_macro_nesting_level ();
   cv->cntexe = get_macro_cntexe ();
   cv->cntmac = get_macro_cntmac ();

/* lines */
   cv->linact = fc->line_index;
   cv->lintot = fc->line_anz;

   return;

}  /* get_calc_variables */

/* -FF-  */

/* Modification History */
/* 24.01.93 - file erzeugt */
/* 29.11.93 - mb_ctype.h */
/* 04.07.94 - isspace() */
/* 23.05.96 - lineact, linetot */
/* 19.08.97 - SD (string delimiter) */
/* 31.01.99 - tm_year % 100 (Y2K problem) */
/* 31.03.03 - str_synt */
/* 13.03.04 - disp_hnd.c: modifications for CSS (dashes in keywords) */
