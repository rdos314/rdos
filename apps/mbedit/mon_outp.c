/*      mon_outp.c                           14.02.04       */
/*!
/  --------------------------------------------------------------
/  Copyright (C) 2004: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/     Umsetzung von generellen Terminal-Steuerkommandos in die
/     zugeschnittenen Kommandos fuer den jeweiligen Terminal-Server
/     (z.B. PC, VT-100, ...)
/                                                                             
*/

/****************************************************************
*                                                               *
*  BENUTZTE UNTERPROGRAMME (C LIBRARY)                          *
*                                                               *
****************************************************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "mon_outp.h"
#include "kb_input.h"
#include "vbios.h"
#include "commands.h"
#include "ansi_out.h"


/****************************************************************
*                                                               *
*  BENUTZTE UNTERPROGRAMME / GLOBALE VARIABLEN                  *
*                                                               *
****************************************************************/

#define TEST_DELAY 0   /* LSB = 1 msec */
#define HIGH_SPEED 1   /* 0 = old, 1 = new */


static int  row    = 0;
static int  column = 0;

enum ATTR_TYPE
     {
        TYPE_DEFAULT,   /* 0 */
        TYPE_INVERS,    /* 1 */
        TYPE_STAT_1,    /* 2 */
        TYPE_STAT_2,    /* 3 */
#if (WITH_SYNTAX_HIGHLIGHTING)
        TYPE_COMMENT,   /* 4 */
        TYPE_KEYWORD,   /* 5 */
        TYPE_STRING,    /* 6 */
#endif
        TYPE_NUMBER     /* 4 or 7 */
     };

static enum ATTR_TYPE status_flag = TYPE_DEFAULT;

static int comment_is_set, keyword_is_set, string_is_set;


/* fallunterscheidung */

#if (ACT_SERVER == SERVER_VGA)

/*****************************************/
/*                                       */
/*          VGA - Graphic                */
/*                                       */
/*****************************************/

static int wrap_flag = 1;

static word far * top_of_screen = _F_PTR (VGA_COLOR, 0);
static word far * act_ptr       = _F_PTR (VGA_COLOR, 0);

static word attribute = (INIT_DEFAULT_ATTRIBUTE << 8);

static byte act_attr [TYPE_NUMBER] = 
            {
               INIT_DEFAULT_ATTRIBUTE,
               INIT_INVERS_ATTRIBUTE,
               INIT_DEFAULT_ATTRIBUTE,
               INIT_INVERS_ATTRIBUTE,
#if (WITH_SYNTAX_HIGHLIGHTING)
               INIT_DEFAULT_ATTRIBUTE,
               INIT_DEFAULT_ATTRIBUTE,
               INIT_DEFAULT_ATTRIBUTE
#endif
            };

static byte save_attr [TYPE_NUMBER] = 
            {
               INIT_DEFAULT_ATTRIBUTE,
               INIT_INVERS_ATTRIBUTE,
               INIT_DEFAULT_ATTRIBUTE,
               INIT_INVERS_ATTRIBUTE,
#if (WITH_SYNTAX_HIGHLIGHTING)
               INIT_DEFAULT_ATTRIBUTE,
               INIT_DEFAULT_ATTRIBUTE,
               INIT_DEFAULT_ATTRIBUTE
#endif
            };

#define default_attribute act_attr[TYPE_DEFAULT]
#define invers_attribute  act_attr[TYPE_INVERS]
#define stat_1_attribute  act_attr[TYPE_STAT_1]
#define stat_2_attribute  act_attr[TYPE_STAT_2]
#if (WITH_SYNTAX_HIGHLIGHTING)
#define comment_attribute act_attr[TYPE_COMMENT]
#define keyword_attribute act_attr[TYPE_KEYWORD]
#define string_attribute  act_attr[TYPE_STRING]
#endif


/****************************************************************
*                                                               *
*  ENDE DER DEKLARATIONEN                                       *
*                                                               *
****************************************************************/

/*****************************************/
/*                                       */
/* static functions (for local use only) */
/*                                       */
/*****************************************/

static void loc_scroll_screen (void)
{
word one_blank;
word far *act_ind;

   row--;              /* scroll */
   act_ptr -= COLUMNS;

/* scroll line (1...n) --> (0...n-1) */
   memcpy (top_of_screen,
           top_of_screen + COLUMNS,
          (sizeof(word) * (ROWS-1) * COLUMNS));


/* blank last line */
   one_blank = (default_attribute << 8) | ' ';

/* blank loop */
   for (act_ind = top_of_screen + ((ROWS-1) * COLUMNS) ;
        act_ind < top_of_screen +  (ROWS    * COLUMNS) ;
        act_ind++)
   {
      *act_ind = one_blank;
   }

   return;
}  /* loc_scroll_screen */


static void loc_carriage_return (void)
{
   act_ptr -= column;
   column = 0;

   return;  
}


static void loc_line_feed (void)
{
   row++;
   act_ptr += COLUMNS;

   if (row >= ROWS)       /* end of screen ? */
   {
      loc_scroll_screen ();
   }

   return;  
}


static void loc_new_line (void)
{
   loc_carriage_return ();
   loc_line_feed ();

   return;  
}  /* new_line */



static void loc_cursor_tab (void)
{
byte tab_diff;

   tab_diff = (byte)((set.tabs-1) - (column % set.tabs));
   column  += tab_diff;
   act_ptr += tab_diff;
   loc_cursor_right ();

   return;
}

/* -FF-  */

/* zur beschleunigung der ausgabe wird das setzen des cursors waehrend */
/* laengerer ausgabe-sequenzen (z.B. disp_hnd, history) unterdrueckt.  */

static int cursor_stack;

int push_cursor (void)
{
   cursor_stack++;
   return cursor_stack;
}  /* push_cursor */


int pop_cursor (void)
{
   if (cursor_stack > 0)   /* for safety reasons */
   {
      cursor_stack--;
      if (cursor_stack == 0)
         loc_invert_cursor (1);
   }
   
   return cursor_stack;
}  /* pop_cursor */

/* -FF-  */

static void loc_invert_cursor (int mode)
{
/* mode : 0 = Cursor OFF, 1 = Cursor ON */

#define VGA_CURSOR 1     /* 0: Own Cursor (by inverting actual char) */
                         /* 1: Cursor of VGA-Graphik-Hardware,       */
                         /*    (nicht so doll, weil der alte cursor  */
                         /*    in der ecke oben links stehenbleibt.) */

#if VGA_CURSOR

   if ((cursor_stack == 0) && (mode))
      vb_ctoxy (column, row);

#else

word act_attr;
byte fore_colour, back_colour;

/* wg. compiler warning */
   mode = mode;

/* get fore and background colour */
   act_attr = (*act_ptr >> 8);

/* exchange them */
   fore_colour = (byte) (act_attr & 0x07);
   back_colour = (byte) (act_attr & 0x70);
   act_attr = (act_attr & 0x88)  |
              (fore_colour << 4) |
              (back_colour >> 4);

/* and store back attributes */
   *act_ptr = (*act_ptr & 0x00ff) | (act_attr << 8);
#endif

   return;
}  /* loc_invert_cursor */

/* -FF-  */

static int loc_init_mon_outp (void)
{

/* bestimmt die basis-adresse des vga-memorys */

/* video mode      start adress                        */
/*    7  (b/w)      0xb000:0    (z.B.: compaq deskpro) */
/*    3  (color)    0xb800:0    (z.B.: compaq laptop ) */
int vmode;


/* call video bios functions */
   vmode = vb_getvmode ();

/* now check actual mode */
   switch (vmode)
   {
      case 7:
         top_of_screen = _F_PTR (VGA_MONO, 0);
         act_ptr       = _F_PTR (VGA_MONO, 0);
         break;

      default:
      /* may fail if graphic modes active */
         top_of_screen = _F_PTR (VGA_COLOR, 0);
         act_ptr       = _F_PTR (VGA_COLOR, 0);
         break;
   }

/* set all the rest */
   attribute = (default_attribute << 8);
   row    = 0;
   column = 0;
   status_flag = TYPE_DEFAULT;

   return (0);  /* o.k. */
}  /* loc_init_mon_outp */

/* -FF-  */

static void loc_test_screen (void)
{

#if 0

word xx;

/* bildschirm loeschen */
   loc_clear_screen ();


/* display character set */
   act_ptr = top_of_screen;
   for (xx = 0 ; xx < 0x100 ; xx++)
   {
      *act_ptr = attribute | xx;   /* hier: direct output !! */
      act_ptr++;

   /* cursor to next line */
      if ((xx & 63) == 63)
      {
         act_ptr += 16;
      }
   }


/* display available attributes */
   for (xx = 0 ; xx < 0x100 ; xx++)
   {
      loc_set_attribute ((byte) xx);

      loc_out_1_char ('A', 0);

   /* cursor to next line */
      if ((xx & 63) == 63)
      {
         loc_out_1_char (0x0d, 0);
         loc_out_1_char (0x0a, 0);
      }
   }


/* wait for key_pressed */
   get_1_key (0);

   loc_clear_screen ();

   loc_set_attribute (default_attribute);
#endif

   return;

}  /* test_screen */


static void loc_set_attribute (byte attr)
{

   attribute = (attr << 8);

   return;

}  /* loc_set_attribute */

/* -FF-  */

static void loc_clear_screen (void)
{
word one_blank;
word far *act_ind;

/* 1.) clear phys. screen */

   if ((ROWS    != INIT_ROWS) ||
       (COLUMNS != INIT_COLUMNS))
      system ("cls");


/* 2.) clear log. screen */

   one_blank = (default_attribute << 8) | ' ';

/* blank loop */
   for (act_ind = top_of_screen ;
        act_ind < top_of_screen + (ROWS * COLUMNS) ;
        act_ind++)
   {
      *act_ind = one_blank;
   }


/* set cursor to top of screen */
   act_ptr = top_of_screen;
   loc_cursor_home ();

   return;

}  /* loc_clear_screen */



static void loc_clear_to_eol (void)
{
word one_blank;
word far *act_ind;
int l_col;

   one_blank = attribute | ' ';

   act_ind = act_ptr;
   for (l_col = column ; l_col < COLUMNS ; l_col++)
   {
      *act_ind = one_blank;
      act_ind++;
   }
   
   return;
}


static void loc_cursor_home (void)
{

   loc_set_cursor_to (0, 0);
   return;

}  /* loc_cursor_home */



static void loc_set_cursor_to (int l_row, int l_column)
{
   row     = max (0, min (l_row   , (ROWS-1)));
   column  = max (0, min (l_column, (COLUMNS-1)));
   act_ptr = top_of_screen + ((COLUMNS * row) + column);

   return;

}  /* loc_set_cursor_to */



static void loc_cursor_left (void)
{
   if (column > 0)
   {
      column--;
      act_ptr--;
   }
   else
   {
      if (row > 0)
      {
         column += (COLUMNS-1);
         row--;         
         act_ptr--;
      }
   }

   return;
}  /* loc_cursor_left */


static void loc_cursor_right (void)
{
   if (wrap_flag)
   {
      column++;
      act_ptr++;

      if (column >= COLUMNS)    /* end of line ? */
      {
         loc_new_line ();
      }
   }
   else
   {
      if (column < (COLUMNS-1))
      {
         column++;
         act_ptr++;
      }
   }

   return;

}  /* loc_cursor_right */


static void loc_cursor_up (void)
{
   if (row > 0)
   {
      row--;         
      act_ptr -= COLUMNS;
   }

   return;
}


static void loc_cursor_down (void)
{
   if (row < (ROWS-1))
      loc_line_feed ();

   return;
}

/* -FF-  */

static void loc_out_1_char (int key, int rectangle)
{

/* check for highbit characters */
   if ((key & 0x80) && (!fc->highbit) && (!rectangle))
      key = '?';

#if (HIGH_SPEED)

   *act_ptr = attribute | ((byte) key);   /* write 1 character */
   loc_cursor_right ();

#else

/* fallunterscheidung */
   switch (key)
   {
      case 0x01:          /* ^A */
         loc_clear_to_eol ();
         break;

      case 0x07:          /* ^G, Bell */
         putchar (0x07);
         break;

      case 0x08:          /* ^H */
      case KEY_LEFT:
         loc_cursor_left ();
         break;

      case 0x09:          /* ^I, <tab> --> n Spaces */
         loc_cursor_tab ();
         break;

      case 0x0a:          /* ^J, <lf> */
         loc_line_feed ();
         break;

      case KEY_DOWN:
         loc_cursor_down ();  /* = line feed */
         break;

      case 0x0b:          /* ^K */
      case KEY_UP:
         loc_cursor_up ();
         break;

      case 0x0c:          /* ^L */
      case KEY_RIGHT:
         loc_cursor_right ();
         break;

      case 0x0d:          /* ^M, <cr> */
         loc_carriage_return ();
         break;

      case 0x17:          /* ^W */
         loc_clear_screen ();
         break;

      case 0x1e:          /* ^^ */
      case KEY_HOME:
         loc_cursor_home ();
         break;

      case 0x7f:          /* Rubout, Delete */
      case KEY_DEL:
         loc_cursor_left ();
         *act_ptr = attribute | ' ';   /* write 1 Blank */
         break;

      default:
         *act_ptr = attribute | ((byte) key);   /* write 1 character */
         loc_cursor_right ();
         break;
   }  /* switch key */

#endif


#if TEST_DELAY
   sleep_msec (TEST_DELAY);
#endif

   return;

}  /* loc_out_1_char */


static int loc_out_string (char *text)
{
int count;

/* string output */
   count = 0;
   while (*text)
   {
      loc_out_1_char (*text, 0);
      text++;
      count++;
   }

   return count;  /* no of written bytes */

}  /* loc_out_string */

/* -FF-  */

/* umsetzung public in local functions */
/* hier nur functionen, die den cursor an- und abschalten) */

#if (!HIGH_SPEED)

static void translate_1 (int key, rectangle)
{
   loc_invert_cursor (0);
   loc_out_1_char (key, rectangle);
   loc_invert_cursor (1);
}


static void translate_2 (int l_line, int l_column)
{
   loc_invert_cursor (0);
   loc_set_cursor_to (l_line, l_column);
   loc_invert_cursor (1);
}


static int  translate_3 (char *text)
{
int count;

   push_cursor ();
   loc_invert_cursor (0);
   count = loc_out_string (text);
   loc_invert_cursor (1);
   pop_cursor ();

   return count;
}

#endif

/* -FF-  */

/*****************************************/
/*                                       */
/*  public functions (for general use)   */
/*                                       */
/*           PC - VGA-Graphik            */
/*                                       */
/*****************************************/


int init_mon_outp (void)
{
   return loc_init_mon_outp ();
}


void test_screen (void)
{
   loc_test_screen ();
}


void set_normal_mode (void)
{
   loc_set_attribute (default_attribute);
   status_flag = TYPE_DEFAULT;
}


void set_invers_mode (void)
{
   loc_set_attribute (invers_attribute);
   status_flag = TYPE_INVERS;
}


void set_stat_1_mode (void)
{
   loc_set_attribute (stat_1_attribute);
   status_flag = TYPE_STAT_1;
}


void set_stat_2_mode (void)
{
   loc_set_attribute (stat_2_attribute);
   status_flag = TYPE_STAT_2;
}

#if (WITH_SYNTAX_HIGHLIGHTING)

void set_comment_mode (void)
{
   loc_set_attribute (comment_attribute);
   status_flag = TYPE_COMMENT;
}


void set_keyword_mode (void)
{
   loc_set_attribute (keyword_attribute);
   status_flag = TYPE_KEYWORD;
}


void set_string_mode (void)
{
   loc_set_attribute (string_attribute);
   status_flag = TYPE_STRING;
}

#endif

void clear_screen (void)
{
   loc_clear_screen ();
}


void clear_to_eol (int rest_blanks)
{
   rest_blanks;  /* wg. compiler warnings */
   loc_clear_to_eol ();
}


void clear_line (void)
{
   loc_carriage_return ();
   loc_clear_to_eol ();
}

void cursor_home  (void)
{
   loc_cursor_home ();
}


void set_cursor_to (int line, int column)
{
#if (HIGH_SPEED)
   loc_set_cursor_to (line, column);
   loc_invert_cursor (1);
#else
   translate_2 (line, column);
#endif
}


void get_cursor_pos (int *lin, int *col)
{
/* 
   im vga-mode steht in row/column jederzeit die aktuelle cursorposition.
   siehe auch vt-100-mode.
*/

   *lin = row;
   *col = column;
   return;
}


void set_wrap_on  (void)
{
   wrap_flag = 1;
}


void set_wrap_off (void)
{
   wrap_flag = 0;
}


void cursor_left  (void)
{
   loc_cursor_left ();
}


void cursor_right (void)
{
   loc_cursor_right ();
}


void cursor_up    (void)
{
   loc_cursor_up ();
}


void cursor_down  (void)
{
   loc_cursor_down ();
}


void out_1_char (int key, int rectangle)
{
#if (HIGH_SPEED)
   loc_out_1_char (key, rectangle);
#else
   translate_1 (key, rectangle); 
#endif
}


int  out_string (char *text)
{
#if (HIGH_SPEED)
   return loc_out_string (text);
#else
   return translate_3 (text);
#endif
}


void beep (void)
{
   if (set.warning >= 1)
      putchar (0x07);
}


void set_grafik_off (int mode)
{
   mode;     /* wg. compiler warnings */
   return;   /* dummy entry */
}


void set_grafik_on (int mode)
{
   mode;     /* wg. compiler warnings */
   return;   /* dummy entry */
}

#else

/*****************************************/
/*                                       */
/*       VT 220 - Terminal               */
/*                                       */
/*****************************************/

#define LEN_16  16

static char esc_sequ_vt100 [TYPE_NUMBER][LEN_16] =
            {
               ESC_ATTR_DEFAULT
              ,ESC_ATTR_INVERS
              ,ESC_ATTR_DEFAULT
              ,ESC_ATTR_INVERS
#if (WITH_SYNTAX_HIGHLIGHTING)
              ,ESC_ATTR_DEFAULT
              ,ESC_ATTR_DEFAULT
              ,ESC_ATTR_DEFAULT
#endif
            };

static char save_esc_sequ [LEN_16] =
            {
               ESC_ATTR_DEFAULT
            };


int init_mon_outp (void)
{
   return 0;
}


void test_screen (void)
{
   return;
}

/* -FF-  */

void set_normal_mode (void)
{
   status_flag = TYPE_DEFAULT;
   printf ("%s", esc_sequ_vt100 [status_flag]);
}


void set_invers_mode (void)
{
   status_flag = TYPE_INVERS;
   printf ("%s", esc_sequ_vt100 [status_flag]);
}


void set_stat_1_mode (void)
{
   status_flag = TYPE_STAT_1;
   printf ("%s", esc_sequ_vt100 [status_flag]);
}


void set_stat_2_mode (void)
{
   status_flag = TYPE_STAT_2;
   printf ("%s", esc_sequ_vt100 [status_flag]);
}

#if (WITH_SYNTAX_HIGHLIGHTING)

void set_comment_mode (void)
{
   status_flag = TYPE_COMMENT;
   printf ("%s", esc_sequ_vt100 [status_flag]);
}


void set_keyword_mode (void)
{
   status_flag = TYPE_KEYWORD;
   printf ("%s", esc_sequ_vt100 [status_flag]);
}


void set_string_mode (void)
{
   status_flag = TYPE_STRING;
   printf ("%s", esc_sequ_vt100 [status_flag]);
}

#endif

/* -FF-  */

void clear_screen (void)
{
   printf (ESC_CLEAR_SCREEN);
}


void clear_to_eol (int rest_blanks)
{

#if 0     /* CLEAR_WITH_BLANKS now defined in config.h */

#if ((ACT_OP_SYSTEM == DEC_ULTRIX) || (ACT_OP_SYSTEM == LINUX))
#define CLEAR_WITH_BLANKS 1
#else
#define CLEAR_WITH_BLANKS 0
#endif

#endif


#if (CLEAR_WITH_BLANKS)
                /* TEST Mode : clear to end of line with single <space>s */
                /*             (to avoid different background colors)    */

int ii;
   for (ii = 0 ; ii < rest_blanks ; ii++)
   {
      out_1_char (' ', 0);
   }

#else
                /* clear with escape sequence */

   printf (ESC_CLEAR_TO_EOL);

#endif

#if (UNIX)
   avoid_hanging_display();
#endif
}


void clear_line (void)
{
   printf (ESC_CLEAR_LINE);
}

void cursor_home  (void)
{
   set_cursor_to (0, 0);                          /* linke obere ecke ist */
                                                  /* bei mbedit= (0,0) !! */
}


void set_cursor_to (int line, int col)
{
/* position begrenzen */
   row    = max (0, min (line, (ROWS   -1)));
   column = max (0, min (col , (COLUMNS-1)));
   printf (ESC_SET_CURSOR_TO, (row+1), (column+1));  /* linke obere ecke ist */
                                                     /* bei vt100 = (1,1) !! */
}


void get_cursor_pos (int *lin, int *col)
{
/*
   ACHTUNG ! die cursor position wird nur von set_cursor_to gesetzt !
   fuer diese anwendung (restaurieren des cursors bei get_hex_value und
   perform_special_keys, siehe switches.c + disp_hnd.c) ist das o.k.

   wenn in zukunft andere programme die aktuelle cursorposition
   zwischendurch brauchen, koennte eine ausfuehrlichere bearbeitung
   notwendig werden. siehe auch vga-mode !
*/

   *lin = row;
   *col = column;
   return;
}

/* -FF-  */

/* zur vermeidung von bildschirmflimmern wird der cursor waehrend     */
/* laengerer ausgabe-sequenzen (z.B. disp_hnd, history) abgeschaltet. */

static int cursor_stack;

int push_cursor (void)
{
   if (cursor_stack == 0) cursor_off ();
   cursor_stack++;
   return cursor_stack;
}  /* push_cursor */


int pop_cursor (void)
{
   if (cursor_stack > 0)   /* for safety reasons */
   {
      cursor_stack--;
      if (cursor_stack == 0) cursor_on ();
   }
   
   return cursor_stack;
}  /* pop_cursor */


void cursor_off (void)
{
#if WITH_CURSOR_ON_OFF
   printf (ESC_CURSOR_OFF);   /* capname 'civis' */
#endif
   fflush (stdout);
}


void cursor_on (void)
{
#if WITH_CURSOR_ON_OFF
   printf (ESC_CURSOR_ON);   /* capname 'cvvis' */
#endif
   fflush (stdout);
}


void set_grafik_off (int mode)
{
   if (mode)
      printf (ESC_SET_GRAFIK_OFF_ANSI);     /* ANSI  */
   else
      printf (ESC_SET_GRAFIK_OFF_VT100);    /* VT100 */

   fflush (stdout);
}


void set_grafik_on (int mode)
{
   if (mode)
      printf (ESC_SET_GRAFIK_ON_ANSI);      /* ANSI  */
   else
      printf (ESC_SET_GRAFIK_ON_VT100);     /* VT100 */

   fflush (stdout);
}

/* -FF-  */

void set_wrap_on  (void)
{
   printf (ESC_WRAP_ON);
}


void set_wrap_off (void)
{
   printf (ESC_WRAP_OFF);
}


void cursor_left  (void)
{
   printf (ESC_CURSOR_LEFT);
}


void cursor_right (void)
{
   printf (ESC_CURSOR_RIGHT);
}


void cursor_up    (void)
{
   printf (ESC_CURSOR_UP);
}


void cursor_down  (void)
{
   printf (ESC_CURSOR_DOWN);
}


#define TRANSLATE_GERMAN 1

void out_1_char (int key, int rectangle)
{
#if TRANSLATE_GERMAN

   if ((key & 0x80) && (!fc->highbit) && (!rectangle))
      putchar ('?');
   else
      putchar (key);

#else

   putchar (key);

#endif
}


int  out_string (char *text)
{
int count;

   push_cursor ();

#if TRANSLATE_GERMAN

/* string output */
   count = 0;
   while (*text)
   {
      out_1_char (*text, 0);
      text++;
      count++;
   }

#else

   count = printf ("%s", text);

#endif

   pop_cursor ();

   return count;  /* no of written bytes */
}


void beep (void)
{
   if (set.warning >= 1)
      putchar (0x07);
}

#endif

/* -FF-  */

static void set_actual_mode (void)
{
   switch (status_flag)
   {
      case TYPE_DEFAULT: set_normal_mode  (); break;
      case TYPE_INVERS : set_invers_mode  (); break;
      case TYPE_STAT_1 : set_stat_1_mode  (); break;
      case TYPE_STAT_2 : set_stat_2_mode  (); break;
#if (WITH_SYNTAX_HIGHLIGHTING)
      case TYPE_COMMENT: set_comment_mode (); break;
      case TYPE_KEYWORD: set_keyword_mode (); break;
      case TYPE_STRING:  set_string_mode  (); break;
#endif
      default: break;
   }

   return;
}  /* set_actual_mode */

#if (ACT_SERVER == SERVER_VGA)

void push_attributes (void)
{
   memcpy (save_attr, act_attr, sizeof (save_attr));

   default_attribute = INIT_DEFAULT_ATTRIBUTE;
   invers_attribute  = INIT_INVERS_ATTRIBUTE;
   stat_1_attribute  = INIT_DEFAULT_ATTRIBUTE;
   stat_2_attribute  = INIT_INVERS_ATTRIBUTE;
#if (WITH_SYNTAX_HIGHLIGHTING)
   comment_attribute = INIT_DEFAULT_ATTRIBUTE;
   keyword_attribute = INIT_DEFAULT_ATTRIBUTE;
#endif

   set_actual_mode ();
   
   return;
}  /* push_attributes */


void pop_attributes (void)
{
   memcpy (act_attr, save_attr, sizeof (save_attr));

   set_actual_mode ();
   
   return;
}  /* pop_attributes */

#else

void push_attributes (void)
{
   memcpy (save_esc_sequ, esc_sequ_vt100 [status_flag], LEN_16);

   strcpy (esc_sequ_vt100 [status_flag], ESC_ATTR_DEFAULT);

   set_actual_mode ();
   
   return;
}  /* push_attributes */


void pop_attributes (void)
{
   memcpy (esc_sequ_vt100 [status_flag], save_esc_sequ, LEN_16);

   set_actual_mode ();
   
   return;
}  /* pop_attributes */

#endif

/* -FF-  */

#if (ACT_SERVER == SERVER_VGA)

void set_default_attribute (byte attr)
{
   default_attribute = attr;

   set_actual_mode ();
   
   return;
}  /* set_default_attribute */


void set_invers_attribute  (byte attr)
{
   invers_attribute = attr;

   set_actual_mode ();
   
   return;
}  /* set_invers_attribute */


void set_stat_1_attribute  (byte attr)
{
   stat_1_attribute = attr;

   set_actual_mode ();
   
   return;
}  /* set_stat_1_attribute */


void set_stat_2_attribute  (byte attr)
{
   stat_2_attribute = attr;

   set_actual_mode ();
   
   return;
}  /* set_stat_2_attribute */

#if (WITH_SYNTAX_HIGHLIGHTING)

void set_comment_attribute  (byte attr)
{
   comment_attribute = attr;
   comment_is_set = 1;

   set_actual_mode ();
   
   return;
}  /* set_comment_attribute */


void set_keyword_attribute  (byte attr)
{
   keyword_attribute = attr;
   keyword_is_set = 1;

   set_actual_mode ();
   
   return;
}  /* set_keyword_attribute */


void set_string_attribute  (byte attr)
{
   string_attribute = attr;
   string_is_set = 1;

   set_actual_mode ();
   
   return;
}  /* set_string_attribute */

#endif

#else

void set_default_attribute (char *esc_line)
{
   strncpy (esc_sequ_vt100 [TYPE_DEFAULT], esc_line, (LEN_16-1));

   set_actual_mode ();
   
   return;
}  /* set_default_attribute */


void set_invers_attribute  (char *esc_line)
{
   strncpy (esc_sequ_vt100 [TYPE_INVERS], esc_line, (LEN_16-1));

   set_actual_mode ();
   
   return;
}  /* set_invers_attribute */


void set_stat_1_attribute  (char *esc_line)
{
   strncpy (esc_sequ_vt100 [TYPE_STAT_1], esc_line, (LEN_16-1));

   set_actual_mode ();
   
   return;
}  /* set_stat_1_attribute */


void set_stat_2_attribute  (char *esc_line)
{
   strncpy (esc_sequ_vt100 [TYPE_STAT_2], esc_line, (LEN_16-1));

   set_actual_mode ();
   
   return;
}  /* set_stat_2_attribute */

#if (WITH_SYNTAX_HIGHLIGHTING)

void set_comment_attribute  (char *esc_line)
{
   strncpy (esc_sequ_vt100 [TYPE_COMMENT], esc_line, (LEN_16-1));
   comment_is_set = 1;

   set_actual_mode ();
   
   return;
}  /* set_comment_attribute */


void set_keyword_attribute  (char *esc_line)
{
   strncpy (esc_sequ_vt100 [TYPE_KEYWORD], esc_line, (LEN_16-1));
   keyword_is_set = 1;

   set_actual_mode ();
   
   return;
}  /* set_keyword_attribute */


void set_string_attribute  (char *esc_line)
{
   strncpy (esc_sequ_vt100 [TYPE_STRING], esc_line, (LEN_16-1));
   string_is_set = 1;

   set_actual_mode ();
   
   return;
}  /* set_string_attribute */

#endif

#endif

/* -FF-  */

#if (WITH_SYNTAX_HIGHLIGHTING)

int is_comment_active (void)
{
   return ((comment_is_set) &&
           (fc->syntax_flag & 0x01) &&
#if (ACT_SERVER == SERVER_VGA)
           (default_attribute != comment_attribute)
#else
           (strncmp(esc_sequ_vt100 [TYPE_DEFAULT],
                    esc_sequ_vt100 [TYPE_COMMENT], LEN_16) != 0)
#endif
          );
}  /* is_comment_active */


int is_keyword_active (void)
{
   return ((keyword_is_set) &&
           (fc->syntax_flag & 0x02) &&
#if (ACT_SERVER == SERVER_VGA)
           (default_attribute != keyword_attribute)
#else
           (strncmp(esc_sequ_vt100 [TYPE_DEFAULT],
                    esc_sequ_vt100 [TYPE_KEYWORD], LEN_16) != 0)
#endif
          );
}  /* is_keyword_active */


int is_string_active (void)
{
   return ((string_is_set) &&
           (fc->syntax_flag & 0x04) &&
#if (ACT_SERVER == SERVER_VGA)
           (default_attribute != string_attribute)
#else
           (strncmp(esc_sequ_vt100 [TYPE_DEFAULT],
                    esc_sequ_vt100 [TYPE_STRING ], LEN_16) != 0)
#endif
          );
}  /* is_string_active */

#endif

/* -FF-  */

/* Modification History */
/* 21.10.92 - file erzeugt */
/* 23.11.92 - more special keys */
/* 24.11.92 - set_top_of_screen () */
/* 25.11.92 - loc_init_mon_outp (): system ("cls"); */
/* 27.11.92 - beep () */
/* 28.11.92 - clear_line () */
/* 30.11.92 - fehler in loc_invert_cursor behoben () */
/* 01.12.92 - vt100 ansteuerung  */
/* 21.12.92 - vb_getvmode () zur best. der start-adresse des video-memory */
/* 17.06.93 - attribute (vorder- hinter-grund) per macro-file ladbar */
/* 18.06.93 - Attribute AFSV (Status Line 1) */
/* 27.07.93 - set.warning: 0-2 */
/* 08.11.93 - WITH_CURSOR_ON_OFF, nicht bei ultrix */
/*            1.: ursache fuer absturz (memory fault - core dumped) */
/*            2.: <esc>-sequenzen bei sco-unix nicht bekannt */
/* 29.11.93 - WITH_CURSOR_ON_OFF --> config.h */
/* 06.12.93 - GRAFIK_OFF --> mon_outp.c */
/* 19.02.94 - loc_clear_to_eol (): attribute anstatt default_attribute: */
/*            damit wird auch rechte untere ecke auf richtige farbe gesetzt */
/* 08.07.94 - clear_to_eol(): delay for OSF_1 */
/* 08.07.94 - " hat leider nicht funktioniert */
/* 27.09.94 - type cast(s) wg. compiler warnings (microsoft c 6.0) */
/* 27.09.94 - comment_attribute, keyword_attribute */
/* 01.10.94 - is_comment_active(), is_keyword_active() */
/* 02.10.94 - comment_is_set, keyword_is_set */
/* 02.10.94 - WITH_SYNTAX_HIGHLIGHTING */
/* 04.10.94 - <esc> sequences for vt100 */
/* 05.10.94 - set_vt_100_mode() entfaellt */
/* 06.10.94 - set_grafik_on(mode), _off(mode) */
/* 09.10.94 - clear_to_eol(int rest_blanks) */
/* 14.10.94 - <esc> sequences as define constants in "mon_outp.h" */
/* 22.01.95 - VGA modes */
/* 26.02.95 - set_wrap_on, _off */
/* 02.02.99 - CLEAR_WITH_BLANKS now defined in config.h */
/* 30.04.03 - syntax highlighting for strings */
/* 06.12.03 - avoid_hanging_display() */
/* 11.02.04 - 'S'et 'H'ighbit 'A'uto */
/* 14.02.04 - out_1_char (int key, int rectangle) */
