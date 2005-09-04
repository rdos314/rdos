/*      mbed_sub.c                                07.02.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 2004: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    some general functions
/
*/


/************************/
/*  include files       */
/************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "mbed_sub.h"
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

/* -FF- */

int line_length (char FA_HU *buff, long index_1, long max_ind, int with_eol)
{
/* no of chars in this line (with / without EOLN) */

#if 0
   examples:                          with_eol 
                   text               0      1
                  ---------------------------- 
                  "123456\r\n",       6      8 
                  "123456\n"  ,       6      7 
                  "123456|"   ,       6      6 
                         ^
                        EOF
#endif

long index_0, index_2, start;
int  len;
char FA_HU *buff_1;

/* search backward */
   buff_1 = &buff [index_1 - 1];
   for (index_0 = (index_1 - 1) ; index_0 >= 0 ; index_0--)
   {
      if (perform_test_eol1 (buff_1, -1))
         break;
      buff_1--;
   }
   start = index_0 + 1;

/* search forward */
   buff_1 = &buff [start];
   len = 0;
   for (index_2 = start ; index_2 < max_ind ; index_2++)
   {
      if (*buff_1 == EOLN_LOW)
      {
         if (with_eol)
         {
            len++;
         }
         else
         {
            if ((EOLN_LEN_2) && (index_1 > 0))
            {
               if (buff_1[-1] == EOLN_HIGH)
                  len--;
            }
         }
         break;
      }
      buff_1++;
      len++;
   }

   return (len);
}  /* line_length */

/* -FF- */

int line_blanks (char FA_HU *buff, long index_1, long max_ind)
{
/* no of blanks in this line */

long index_0, index_2, start;
int  blanks;
char FA_HU *buff_1;

/* search backward */
   buff_1 = &buff [index_1 - 1];
   for (index_0 = (index_1 - 1) ; index_0 >= 0 ; index_0--)
   {
      if (perform_test_eol1 (buff_1, -1))
         break;
      buff_1--;
   }
   start = index_0 + 1;

/* search forward */
   buff_1 = &buff [start];
   blanks = 0;
   for (index_2 = start ; index_2 < max_ind ; index_2++)
   {
      if (*buff_1 == 0x20)
         blanks++;

      if (perform_test_eol1 (buff_1, 0))
         break;

      buff_1++;
   }

   return (blanks);
}  /* line_blanks */

/* -FF- */

int first_nonblank (char FA_HU *buff, long index_1, long max_ind)
{

/* no of bytes from index_1 to first nonblank character (no space or <tab>) */
long index_0, index_2;
char FA_HU *buff_1;

/* search backward */
   buff_1 = &buff [index_1 - 1];
   for (index_0 = (index_1 - 1) ; index_0 >= 0 ; index_0--)
   {
      if (perform_test_eol1 (buff_1, -1))
         break;
      buff_1--;
   }

/* search forward */
   buff_1 = &buff [index_1];
   for (index_2 =  index_1 ; index_2 < max_ind ; index_2++)
   {
      if (perform_test_eol1 (buff_1, 0))
         break;
      if ((*buff_1 != ' ') && (*buff_1 != 0x09))
         break;
      buff_1++;
   }

/* differenz der indizes minus 1 ist gleich der gesuchten anzahl */
   return (int)(index_2 - index_0 - 1);
}  /* first_nonblank */

/* -FF- */

int line_columns (char FA_HU *buff, long index_1, long max_ind)
{

/* no of columns in this line (without <cr>) */
/* attention ! <tab>s are expanded here !!   */

long index_0, index_2;
char FA_HU *buff_1;
int column, tab_diff;

/* search backward */
   buff_1 = &buff [index_1 - 1];
   for (index_0 = (index_1 - 1) ; index_0 >= 0 ; index_0--)
   {
      if (perform_test_eol1 (buff_1, -1))
         break;
      buff_1--;
   }
   buff_1++;    /* 1. char on actual line */
   index_0++;

/* search forward */
   column = 0; 
   for (index_2 = index_0 ; index_2 < max_ind ; index_2++)
   {
      if (perform_test_eol1 (buff_1, 0))
      {
         if ((EOLN_LEN_2) && (index_1 > 0))    /* bugfix 07.02.04 */
         {
            if (buff_1[-1] == EOLN_HIGH)
               column--;
         }
         break;
      }

      if (*buff_1 == 0x09)    /* <tab> ? */
      {
         tab_diff = set.tabs - (column % set.tabs);
         column  += tab_diff;
      }
      else
      {
         column++;
      }

      buff_1++;
   }

/* anzahl der spalten mit expandierten <tab>s */
   return column;
}  /* line_columns */

/* -FF- */

int act_column (char FA_HU *buff, long index_1)
{

/* column (cursor position) = f (index) */
/* attention ! <tab>s are expanded here !!   */

long index_0, index_2;
char FA_HU *buff_1;
int column, tab_diff;

/* search backward */
   buff_1 = &buff [index_1 - 1];
   for (index_0 = (index_1 - 1) ; index_0 >= 0 ; index_0--)
   {
      if (perform_test_eol1 (buff_1, -1))
         break;
      buff_1--;
   }
   buff_1++;    /* 1. char on actual line */
   index_0++;

/* search forward */
   column   = 0;
   tab_diff = 0; 
   for (index_2 = index_0 ; index_2 <= index_1 ; index_2++)
   {
      column += tab_diff;

#if 0
      if (perform_test_eol1 (buff_1, 0))
#else
      if (*buff_1 == (EOLN_LOW))
#endif
         break;

      if (*buff_1 == 0x09)    /* <tab> ? */
         tab_diff = set.tabs - (column % set.tabs);
      else
         tab_diff = 1;

      buff_1++;
   }

/* anzahl der spalten mit expandierten <tab>s */
   return column;
}  /* act_column */

/* -FF- */

long act_index (char FA_HU *buff, long index_1, long max_index, int column_1)
{

/* line index = f (column) */
/* attention ! <tab>s are expanded here !!   */

long index_0, index_2;
char FA_HU *buff_1;
int column, tab_diff;

/* search backward */
   buff_1 = &buff [index_1 - 1];
   for (index_0 = (index_1 - 1) ; index_0 >= 0 ; index_0--)
   {
      if (perform_test_eol1 (buff_1, -1))
         break;
      buff_1--;
   }
   buff_1++;    /* 1. char on actual line */
   index_0++;

/* search forward */
   column = 0; 
   for (index_2 = index_0 ; index_2 <= max_index ; index_2++)
   {
#if 0
      if (perform_test_eol1  (buff_1, 0))      /* old version     */
      if (perform_test_eol   (buff_1, 0))      /* bugfix 09.12.93 */
#else
      if ((perform_test_eol  (buff_1, 0)) ||   /* bugfix 08.06.95 */
          (perform_test_eol1 (buff_1, 0)))
#endif
         break;

      if (column >= column_1)
         break;

      if (*buff_1 == 0x09)    /* <tab> ? */
      {
         tab_diff = set.tabs - (column % set.tabs);
         column  += tab_diff;
      }
      else
      {
         column++;
      }

      buff_1++;
   }

/* index_2 begrenzen (wg. end of file mit "dirty_flag") */
   index_2 = min (index_2, max_index);

/* anzahl der indizes mit expandierten <tab>s */
   if (column > column_1)
      return index_2 - 1;
   else
      return index_2;
}  /* act_index */

/* -FF- */

int get_left_chars (char FA_HU *buff, long index_1)
{

/* no of chars left of act. pointer in this line (without <cr>) */

long index_0;
char FA_HU *buff_1;

/* search backward */
   buff_1 = &buff [index_1 - 1];
   for (index_0 = (index_1 - 1) ; index_0 >= 0 ; index_0--)
   {
      if (perform_test_eol1 (buff_1, -1))
         break;
      buff_1--;
   }

/* differenz der indizes minus 1 ist gleich der zeilenlaenge */
   return (int)(index_1 - index_0 - 1);
}  /* get_left_chars */

/* -FF- */

#if (VAR_EOLN)

int get_var_eoln (char FA_HU *buff, long index_1, long max_ind)
{

/* get first eoln in file (0x0a, 0x0d or 0x0d0a) */

long index_0;
int  eoln;

   eoln = EOLN_INIT;   /* default */

   for (index_0 = index_1 ; index_0 < max_ind ; index_0++)
   {
      if (buff[index_0] == 0x0a)
      {
         eoln = 0x0a;
         break;
      }

      if (buff[index_0] == 0x0d)
      {
         eoln = 0x0d;
         if (index_0 < (max_ind - 1))
         {
            if (buff[index_0 + 1] == 0x0a)
            eoln = 0x0d0a;
         }
         break;
      }
   }

   return eoln;
}  /* get_var_eoln */

#endif

/* -FF- */

long get_total_lines (char FA_HU *buff, long index_1, long max_ind)
{

/* count no of <lf>'s in this buffer */

long index_0;
char FA_HU *buff_1;
long count;

   count = 0;
   buff_1 = &buff [index_1];
   for (index_0 = index_1 ; index_0 < max_ind ; index_0++)
   {
      if (perform_test_eol1 (buff_1, 0))
         count++;
      buff_1++;
   }

   return count;
}  /* get_total_lines */

/* -FF- */

long line_to_index (char FA_HU *buff, long index_1, long max_ind, long line_no)
{

/* count no of bytes in this buffer up to line_no */

long index_0;
char FA_HU *buff_1;
long count;

   count = 0;
   buff_1 = buff;
   for (index_0 = index_1 ; index_0 < max_ind ; index_0++)
   {
      if (count == line_no)     /* o.k. found line_no */
         return index_0;   

      if (perform_test_eol1 (buff_1, 0))
         count++;

      buff_1++;
   }

   return -1;    /* error, line_no to big !! */
}  /* line_to_index */

/* -FF- */

#if 0

int line_contents_tabs (char FA_HU *buff, long index_1, long max_ind)
{

/* test, if there are any <tab>s in this line */

long index_0;
char FA_HU *buff_1;

   buff_1 = &buff [index_1];
   for (index_0 = index_1 ; index_0 < max_ind ; index_0++)
   {
      if (perform_test_eol1 (buff_1, 0))
         return 0;   /* no tabs in this line */

      if (*buff_1 == 0x09)
         return 1;   /* at least one tab */

      buff_1++;                        /* keep on searching ... */
   }

   return 0;     /* reached eof */
}  /* line_contents_tabs */

#endif

/* -FF- */

int non_empty_line (char FA_HU *buff, long index_1, long max_ind)
{
/* test, if there are only white <space>s in this line */

long index_0;
char FA_HU *buff_1;

   buff_1 = &buff [index_1];
   for (index_0 = index_1 ; index_0 < max_ind ; index_0++)
   {
      if (perform_test_eol1 (buff_1, 0))
         return 0;   /* nothing in this line */

      if ((*buff_1 != 0x20) &&     /* <space> */
          (*buff_1 != 0x09) &&     /* <tab> */
          (*buff_1 != 0x0d) &&     /* <cr>  */
          (*buff_1 != 0x0a))       /* <lf>  */
         return 1;   /* at least one printable char */

      buff_1++;                        /* keep on searching ... */
   }

   return 0;     /* reached eof */
}  /* non_empty_line */

/* -FF-  */

/* Modification History */
/* 26.11.92 - file erzeugt */
/* 27.11.92 - memcpy_rev beschleunigt */
/* 28.11.92 - fehler in act_index behoben */
/* 02.12.92 - get_left_chars () */
/* 19.12.92 - FA_HU (far / huge) */
/* 20.12.92 - memcpy_rev: length > 64 KByte */
/* 21.12.92 - EOL */
/* 30.07.93 - EOL --> EOLN */
/* 31.08.93 - get_line_length: bug-fix, length at end of file */
/* 10.09.93 - line_length1 (), line_length2 () */
/* 07.10.93 - line_is_empty() */
/* 08.10.93 - line_blanks() */
/* 12.10.93 - bugfix: line_to_index() */
/* 09.12.93 - bugfix: act_index() */
/* 26.04.95 - get_total_lines(): bug fix */
/* 08.06.95 - act_index(): bugfix */
/* 05.09.98 - EOLN_LEN_1 and EOLN_LEN_2: #if --> if */
/* 05.09.98 - get_var_eoln() */
/* 07.02.04 - line_columns(): bugfix: key <End> at begin of file with empty line
              leads to program crash (some OS) due to attempt to read buff[-1] */
