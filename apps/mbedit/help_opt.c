/*      help_opt.c                                  13.03.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 2003: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    help option (appears on function key <F1> )
/
*/


/************************/
/*  include files       */
/************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "help_opt.h"
#include "mon_outp.h"
#include "kb_input.h"
#include "ansi_out.h"


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

void show_header (void)
{
#define LEFT_1  5
#define LEFT_2 40

/* begin of code */
   clear_screen ();
   
   
/* die ueberschrift soll invers dargestellt werden, */
/* deshalb out_string anstelle von printf !         */
   
   set_invers_mode ();
   set_cursor_to (1, LEFT_1);
   out_string (" +----------------------------+ ");
   
/*** printf (" |   %s - %s   | ", VERSION_TEXT, VERSION_DATE); ***/
   set_cursor_to (2, LEFT_1);
   out_string (" |  ");
   out_string (VERSION_TEXT_1);
   out_string (VERSION_TEXT_2);
   out_string (VERSION_TEXT_3);
   out_string (" - ");
   out_string (VERSION_DATE);
   out_string ("   | ");
   
   set_cursor_to (3, LEFT_1);
   out_string (" +----------------------------+ ");
   set_normal_mode ();
   
   
/* der rest in normal-darstellung, hier kann printf benutzt werden */
   
/* some config-data */
   set_cursor_to (1, LEFT_2);
   printf ("operating system : %s", TEXT_OP_SYSTEM);
   set_cursor_to (2, LEFT_2);
   printf ("video server     : %s", TEXT_VIDEO_SERVER);
   set_cursor_to (3, LEFT_2);
   printf ("Rows * Columns   : %d * %d", ROWS, COLUMNS);
#if (ACT_OP_SYSTEM != MS_DOS) && (ACT_OP_SYSTEM != WIN_32) && (ACT_OP_SYSTEM != RDOS)
   set_cursor_to (4, LEFT_2);
   printf ("<esc> wait time  : %d msec", esc_waittime);
#endif
   
/* dit un' dat */
   set_cursor_to (5, LEFT_1);
   out_string (copyright_text);

   set_cursor_to (6, LEFT_1);
   out_string ("For detailed operating instructions, see Homepage:");

   set_cursor_to (7, LEFT_1);
   set_invers_mode ();
   out_string (url_string);
   set_normal_mode ();

   set_cursor_to (8, LEFT_1);

   return;
}  /* show_header */

/* -FF-  */

void show_intro (void)
{
/* gemeinsamer kopf */
   show_header ();

/* some 'animation' */
   printf ("\015\012");
   printf ("\015\012                               *                     *   ");
   printf ("\015\012                               ***                   *** ");
   printf ("\015\012             ******   ******   ***          ******   *** ");
   printf ("\015\012             ******   ******   ***          ******   *** ");
   printf ("\015\012             ***      ***      ***                   *** ");
   printf ("\015\012             ***      ***      ***          ******   *** ");
   printf ("\015\012             ***      ***      ***          ******   *** ");
   printf ("\015\012             ***      ***                            *** ");
   printf ("\015\012          ******   ******   **************************** ");
   printf ("\015\012             ***      ***      ************************* ");
   printf ("\015\012");

   sleep_msec (1000);

   return;
}  /* show_intro */

/* -FF-  */

void show_help_option (void)
{
static const char ny [2] = {'N','Y'};  /* No / Yes */

/* format strings */
#define FS_1 "\015\012     +-- Autonl    [%c]  Bak_file [%c]  Case    [%c]  sYntax hl [%d,%d] Display  [%c]"
#define FS_2 "\015\012         E_delimit [%s]  var.eoln [0x0%x]"
#define FS_3 "\015\012         File_num  [%d]  Highbit  [%c]  Indent  [%c]  K_token    [%c]  Leftcol  [%d]" 
#define FS_4 "\015\012         Margin    [%d, %d, %d]\t      Notab   [%c]  Radix      [%c]  Showfind [%c]"
#define FS_5 "\015\012         Tabs      [%d]  Viewrow  [%d]  Warning [%d]  *Wildcards [%c]  ~HomeDir [%c]"

/* parameter lists */
#define PL_1 ny[set.autonl], ny[set.bak_file], ny[set.c_case], fc->syntax_flag  , fc->file_type, ny[set.display]
#define PL_2 fc->e_delimit , fc->eoln
#define PL_3 set.file_num  , ny[fc->highbit] , ny[set.indent], ny[set.k_token]  , fc->left_col
#define PL_4 set.margin[0] , set.margin[1]   , set.margin[2] , ny[set.notab]    , set.radix    , ny[set.showfind]
#define PL_5 set.tabs      , (set.viewrow +1), set.warning   , ny[set.wildcards], ny[set.tilde_home]

push_attributes ();

/* gemeinsamer kopf */
show_header ();

#if 0
printf ("\015\012   actual size of file buffer = %ld Bytes ( = 0x%lx)",
                                   fc->buffer_size, fc->buffer_size);
printf ("\015\012");
#endif

/* display options + settings */
printf ("\015\012   commands:");
printf ("\015\012     Again  Block Calc     Delete  Execute  Find      -find  Get      Hex");
printf ("\015\012     Insert Jump  Kill_wnd Macro   Other    Paragraph Quit   Replace  ?replace");
printf ("\015\012     Set    Tag   View     Window  Xchange  YFileComp Zulu   !&system");
printf ("\015\012     |");

/* settings */
printf (FS_1, PL_1);
#if (WITH_E_DELIMIT)
printf (FS_2, PL_2);
#endif
printf (FS_3, PL_3);
printf (FS_4, PL_4);
printf (FS_5, PL_5);

#if (!WITH_E_DELIMIT)
printf ("\015\012");
#endif

/* sonstiges */         
printf ("\015\012   controls:");
printf ("\015\012     Cursor up/down/right/left/home, Page up/down");
printf ("\015\012     ^A, ^X, ^Z, ^U, ^E, ^S/^V, ^N, ^R, Backspace/Rubout, ^F/Delete");
printf ("\015\012   built-in macros:");

#if (ACT_OP_SYSTEM == MS_DOS) || (ACT_OP_SYSTEM == WIN_32) || (ACT_OP_SYSTEM == RDOS)
printf ("\015\012     ^D, ^K, <F1>, <F3>, <F4>, <F5>, <F6>");
#else
printf ("\015\012     ^D, ^K, <HELP>, <PF1>, <PF2>, <PF3>, <PF4>");
#endif

get_1_key (0);

pop_attributes ();

return;
}  /* show_help_option */

/* -FF-  */

/* Modification History */
/* 15.01.93 - file erzeugt */
/* 17.06.93 - push_, pop_attributes () */
/* 18.06.93 - set.warning */
/* 27.07.93 - set.warning: 0-2 */
/* 08.08.93 - built-in macros: ALT <F1> weggelassen */
/* 05.09.93 - Find mit Wildcard: '?' */
/* 05.09.93 - Find mit Wildcard: '*' */
/* 11.09.93 - copyright_text */
/* 09.10.93 - Window, Kill_wnd, Paragraph, Set Margin */
/* 11.12.93 - VERSION_TEXT_1, _2, _3 */
/* 19.02.94 - VERSION_TEXT_3 ist jetzt 1 stelle laenger */
/* 11.05.94 - display esc_waittime */
/* 18.05.94 - LEFT_2 45 --> 40 */
/* 07.06.94 - Execute, Macro, Zulu */
/* 29.06.94 - set.tilde_home */
/* 04.07.94 - WITH_E_DELIMIT */
/* 06.07.94 - 'S'et 'A'utonl */
/* 27.09.94 - text "!&system" */
/* 05.10.94 - Text modified: "c sYntax" */
/* 23.01.96 - printf ("\015\012") anstatt printf ("\r\n") */
/* 05.09.98 - var.eoln */
/* 23.05.02 - show_header(): url_string */
/* 25.05.02 - show_intro(): sleep_msec(1000) */
/* 29.03.03 - show_help_option(): print file_type */
/* 11.02.04 - 'S'et 'H'ighbit 'A'uto */
/* 13.03.04 - disp_hnd.c: modifications for CSS (dashes in keywords) */
