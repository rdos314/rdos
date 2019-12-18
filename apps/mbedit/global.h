/*      global.h                               20.03.05       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 2004: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    global header file for mbedit.c (publics / externals)
/
*/


/************************/
/* often used macros    */
/************************/


/************************/
/* some defines         */
/************************/

#define VERSION_DATE    "20.03.05"     /* <= modify here !! */
#define VERSION_TEXT_3  "8.62"         /* <= modify here !! */

#define VERSION_TEXT_1  "mbedit "

#if (DEMO_VERSION == 0)
#define VERSION_TEXT_2  "V"     /* Version */
#endif

#if (DEMO_VERSION == 1)
#define VERSION_TEXT_2  "S"     /* Shareware */
#endif

#if (DEMO_VERSION == 2)
#define VERSION_TEXT_2  "D"     /* Demo */
#endif



#define LINE_OFFSET    1  /* mbedit counts rows, lines internally from 0, */
                          /* display starts from 1 */

#define CURSOR_STABIL  1  /* page up/down doesn't move the cursor position */
                          /* on the screen (except at begin and end of file) */

                          /* relation between cursor position in the memory */
                          /* and on the screen */
#define REL_COLUMN    (fc->column - fc->left_col)


/************************/
/*  structures          */
/************************/

struct FILE_CONTROL {
       /* bei init nicht anfassen ... */
          char filename [BUF_256];  /* name of datafile in work */
          char FA_HU * buff_0; /* pointer to start of edit-buffer */
          long buffer_size;    /* actual length of buffer */
          int  malloc_flag;    /* 1 = buffer is available */
          int  left_col;       /* left visible column on screen (default: 0) */

#if WINDOW_COMMAND
          int  wind_arow [3];  /* row index in both windows */
          long wind_index[3];  /* index of file in both windows */
#endif
          int  syntax_flag;    /* 0=OFF, 1=comments, 2=keywords, 3=both */
          int  eoln;           /* end of line (0x0a, 0x0d or 0x0d0a) */

       /* bei init definiert setzen */
          char FA_HU * buffer; /* pointer to actual byte in edit-buffer */
          long tag_index [4];  /* -1 = undefined */
          int  buff_no;        /* 0/1 (= act_buff_no [act_window]) */
          long find [2];       /* first and (last+1) char of find string */
          int  file_type;      /* index to buffer for syntax highlighting */
          int  highbit;        /* 0=No, 1=Yes */
          char *e_delimit;     /* pointer to hi_light->e_delimit */
 
       /* bei init loeschen ... */
          long byte_anz;       /* total no of bytes */
          long byte_index;     /* index of actual byte */
          long top_left;       /* index of upper left corner on screen */
          long lin_left;       /* index of left byte on actual line */
 
          long line_anz;       /* total no of lines in buffer */
          long line_index;     /* no of actual line */

          int  view_only;      /* 1 = file must not be modified */
          int  change_flag;    /* 1 = file has been modified */
          int  arow;           /* actual row    (0 ... 22) of cursor */
                               /* relative to begin of window */
          int  column;         /* actual column (0 ... 79) of cursor */
       };

#if (WITH_LAST_AGAIN)
struct MINI_CONTROL {
          char filename [BUF_256];  /* name of datafile in work */
          long byte_index;     /* index of actual byte */
          int  view_only;      /* 1 = file must not be modified */
       };
#endif

#define lrow   arow+MIN_ROW    /* relative to begin of screen */


/************************/
/*  public variables    */
/************************/

#undef pubext
#ifdef _GLOBAL_
#define pubext
#else
#define pubext extern
#endif


pubext char copyright_text []
#ifdef _GLOBAL_
        = {"Copyright (C) 1992 - 2005  /  Michael Braun"}
#endif
;

pubext char url_string []
#ifdef _GLOBAL_
        = {"http://www.braun-home.net/michael"}
#endif
;

/* structure for file control */
#if (ACT_OP_SYSTEM == MS_DOS)
#define MAX_FC_NUM 10     /* max. anzahl von edit-files */
#else
#define MAX_FC_NUM 26
#endif

pubext int act_window;       /* 0 : normal mode       */
                             /* 1 : window mode oben  */
                             /* 2 : window mode unten */
pubext int act_buff_no [3];  /* index: act_window */
pubext int same_buffer;      /* 1 = window 1 + 2 contain same buffer */

pubext int w_top [3]         /* window top */
#ifdef _GLOBAL_
   = { 0, 0, 0 } 
#endif
;

pubext int w_bot [3]         /* window bottom */
#ifdef _GLOBAL_
   = { INIT_ROWS-1, INIT_ROWS-1, INIT_ROWS-1 } 
#endif
;

pubext struct FILE_CONTROL file_control [MAX_FC_NUM];
pubext struct FILE_CONTROL *fc;        /* actual file control */

#if (WITH_LAST_AGAIN)
pubext int mini_file_num;
pubext struct MINI_CONTROL mini_control [MAX_FC_NUM];
#endif


/* operation mode */
pubext int  mode_flag;            /* 0 : command  */
                                  /* 1 : insert   */
                                  /* 2 : exchange */
                                  /* 3 : Hex View */
                                  /* 4 : Hex Edit */

#define MODE_TEXT_0 "mode: \"command\" - <F1>: Help Info"
#define MODE_TEXT_1 "mode: \"insert\" - leave with <esc>"
#define MODE_TEXT_2 "mode: \"exchange\" - leave with <esc>"
#define MODE_TEXT_3 "Hex View: cursor keys, <esc>, Other, Edit"
#define MODE_TEXT_4 "Hex Edit: cursor keys, <esc>, <tab>, value"

pubext char *mode_text []
#ifdef _GLOBAL_
                                /* mode_flag */
               = { MODE_TEXT_0      /* 0 */
                  ,MODE_TEXT_1      /* 1 */
                  ,MODE_TEXT_2      /* 2 */
#if (WITH_HEX_VIEW)
                  ,MODE_TEXT_3      /* 3 */
                  ,MODE_TEXT_4      /* 4 */
#endif
                 }
#endif
;

#if (ACT_SERVER == SERVER_VT_100)
pubext int text_area;          /* == 0: text area */
                               /* >= 1: status line or history window */
#endif


/* buffer for ^A, ^X, ^Z, ^U */
struct SAVE_U {int  anz;
             int  index;
             int  command;
             char buffer [BUF_256];
             };
pubext struct SAVE_U save_u;


/* buffer for exchange/backspace */
struct SAVE_X {int  index;
               char buffer [BUF_256];
               };
pubext struct SAVE_X save_x;

/* buffer for buffer/delete */
struct SAVE_D {int  toggle;
               long index0;
               long index1;
               };
pubext struct SAVE_D save_d;

/* settings */
struct SETTINGS {int  autonl;
                 int  bak_file;
                 int  c_case;
                 int  display;
                 int  go;
                 int  highbit_global;  /* 0=No, 1=Yes, 2=Auto */
                 int  indent;
                 int  file_num;
                 int  k_token;
                 int  margin [3];
                 int  notab;
                 int  radix;
                 int  showfind;
                 int  tabs;
                 int  viewrow;
                 int  warning;
                 int  wildcards;
                 int  tilde_home;
                 int  syntax_global;
                };


#define TOKEN_DELIMITERS "!\"#%&\'()*+,-./:;<=>?@[\\]^`{|}~"  /* default */

/* Wenn die String-Konstante direkt in die Struktur  */
/* eingetragen wird, meldet der Microsoft-c-Compiler */
/* im "nicht - _GLOBAL_ - Fall" hier:                */
/* warning: unescaped newline in nonactive code      */
/* ursache : das \"                                  */

pubext struct SETTINGS set
#ifdef _GLOBAL_
              = {                         /* X  implemented    */
                                     0,   /* X  Autonl         */
                                     1,   /* X  Bak_file       */
                                     0,   /* X  Case           */
                                     1,   /* X  Display        */
                                     0,   /* -  Go             */
                                     2,   /* X  Highbit Global */
                                     1,   /* X  Indent         */
                                     2,   /* X  File_num       */
                                     0,   /* X  K_token        */
                              4, 0, 76,   /* X  Margin         */
                                     1,   /* X  Notab          */
                                   'D',   /* X  Radix          */
                                     0,   /* X  Showfind       */
                                     8,   /* X  Tabs           */
                     (5 - LINE_OFFSET),   /* X  Viewrow        */
                                     2,   /* X  Warning        */
                                     0,   /* X  Wildcards      */
                                     0,   /* X  Tilde Home     */
                                     7,   /* X  Syntax Global  */
                }
#endif
;

pubext int line_2_flag;           /* 0 : line_2 unchanged, suppress display */
                                  /* 1 : line_2 modified, display mode_text */
                                  /* 2 : line_2 contains other text,        */
                                  /*     (e.g. an error message)            */
                                  /*     keep until next key is pressed     */

#if (ACT_OP_SYSTEM != MS_DOS) && (ACT_OP_SYSTEM != WIN_32) && (ACT_OP_SYSTEM != RDOS)
pubext int esc_waittime
#ifdef _GLOBAL_
            = { 
                ESC_WAITTIME
              }
#endif
;
#endif

/* -FF-  */

/* variable screen dimensions */

struct SCREEN { int rows;
                int columns;
              };

pubext struct SCREEN screen
#ifdef _GLOBAL_
            = { INIT_ROWS,
                INIT_COLUMNS
              }
#endif
;

#define ROWS           screen.rows
#define COLUMNS        screen.columns

#define STATUS_LINES   2
#define TOP_ROW        (w_top[act_window])
#define BOT_ROW        (w_bot[act_window])
#define MIN_ROW        (TOP_ROW)
#define MAX_ROW        (BOT_ROW - STATUS_LINES)

/* -FF-  */

/* fuer switches.c, disp_hnd.c */

pubext char str_calc [BUF_256];         /* for "Calc"                 */
pubext char str_syst [BUF_256];         /* for "!system" + "qh ..."   */
pubext char str_find [BUF_256];         /* for "Find", "Replace"      */
pubext char str_repl [BUF_256];         /* for "Find", "Replace"      */
pubext char str_numb [BUF_256];         /* for "Set Leftcol,..."      */
pubext char str_q_i1 [BUF_256];         /* for "Quit" "Init"          */
pubext char str_q_i2 [BUF_256];         /* for "Quit" "Init"          */
pubext char str_q_wr [BUF_256];         /* for "Quit" "Write"         */
pubext char str_getf [BUF_256];         /* for "Get"                  */
pubext char str_putf [BUF_256];         /* for "Put"                  */
pubext char str_macr [BUF_256];         /* for "Macro Create/Execute" */
pubext char str_getm [BUF_256];         /* for "Macro Get"            */
pubext char str_synt [BUF_256];         /* for "mbedit.syn"           */

/* -FF-  */

/* Modification History */
/* 24.11.92 - main_loop () */
/* 25.11.92 - perform_key_... () */
/* 26.11.92 - get_total_lines () */
/* 27.11.92 - insert, exchange */
/* 29.11.92 - valid_char () */
/* 30.11.92 - perform_view () */
/* 01.12.92 - perform_find () */
/* 04.12.92 - err_read_file () */
/* 07.12.92 - LINE_OFFSET */
/* 19.12.92 - FILE_CONTROL.filename [BUF_256]   (wg. "..\..\lib\<filename.ext>") */
/* 19.12.92 - FA_HU (far / huge) */
/* 20.12.92 - pubext other_fc (vorher static in mbedit.c) */
/* 21.12.92 - int mode_flag (vorher char) */
/* 03.01.93 - MACRO_NESTING_TO_DEEP */
/* 17.06.93 - Version 3.3: fore- and background-color from macro-file */
/* 18.06.93 - set.warning */
/* 08.09.93 - fc.find[2] */
/* 12.09.93 - DEMO_VERSION */
/* 03.10.93 - FILE_CONTROL.same_file, .other_row, .other_index */
/* 11.12.93 - VERSION_TEXT_1, _2, _3 */
/* 19.02.94 - Status Line 2 jetzt ueber volle laenge (disp_hnd.c, mon_outp.c) */
/*            versions-kennung jetzt mit 2 nachkommastellen */
/* 11.03.94 - siehe commands.c */
/* 06.05.94 - microsft.c: ltoa: sonderfall value = 0, bei radix 2 */
/* 09.05.94 - switches.c: 'P'aragraph: LOCK_WHEN_VIEW_ONLY */
/* 09.05.94 - macro.c, kb_input.c: esc_waittime */
/* 10.05.94 - div. modifications for hp-ux, */
/*            macro.c: reverse search for macro file */
/* 21.06.94 - macro.c: new entry in key_tab []: 0x7f */
/* 29.06.94 - set.tilde_home */
/* 31.08.94 - mbedit.c: take over new_lines + new_cols only, if != 0 */
/* 02.10.94 - fc.syntax_flag = f (WITH_SYNTAX_HIGHLIGHTING)*/
/* 06.10.94 - fc.syntax_flag always defined */
/* 19.10.95 - config.h, mbedit.c: WITH_WINCH 6 (OS_9) */
/* 20.10.95 - wildname.c: window-size dynamic = f (filename-length) */
/* 22.10.95 - wildname.c: WILD_MAX_LEN, WILD_MIN_LEN */
/* 03.11.95 - file_hnd.c: setting of file attributes in os_9 */
/* 16.11.95 - disp_hnd.c: bugfix WITH_SYNTAX_HIGHLIGHTING */
/* 24.11.95 - wildname.c: Quit Init "*.c vo" */
/* 27.11.95 - config.h: OS_9: TIMER_TICK is now dynamic */
/* 28.11.95 - kb_input.c: OS_9: TIMER_TICK --> f(CLOCKS_PER_SEC) */
/* 10.12.95 - file_hnd.c: FILE_SIZE_CHANGED */
/* 11.09.96 - switches.c: 'Q'uit 'I'nit 'Y'es ^C: change_flag is not affected */
/* 11.09.96 - disp_hnd.c: hex_one_line(): 0x7f --> '_' */
/* 11.09.96 - disp_hnd.c: perform_special_keys(): */
/*                        ^N: with Radix 'A': change_flag = 1 */
/* 25.10.96 - disp_hnd.c: get_line_2_string(): KEY_DO_NOTHING or SEQU_EM */
/* 25.10.96 - calcevar.c: SLx (string length x) */
/* 15.11.96 - wildname.c: bugfix, mask directory bit from st_mode */
/* 20.02.97 - global.h: MAX_FC_NUM 10 oder 26 */
/* 24.02.97 - config.h: HP_UX: WITH_SYNTAX_HIGHLIGHTING 1 */
/* 26.02.97 - file_hnd.c: os9: rename() with full path */
/* 05.09.98 - config.h: VAR_EOLN, var. Endekennung eoln */
/* 07.09.98 - perform.c, disp_hnd.c: bugfixes (compiler warnings removed) */
/* 31.01.99 - calc_var.c: tm_year % 100 (Y2K problem) */
/* 02.02.99 - mon_outp.c: CLEAR_WITH_BLANKS now defined in config.h */
/* 04.02.99 - file_hnd.c: get_ / put_file_attributes: with uid + gid */
/* 05.02.99 - mbedit.c: get_1_datafile(): check R_OK, W_OK */
/* 19.02.99 - mbedit.c: get_1_datafile(): check W_OK nicht bei os-9 */
/* 04.03.99 - wildname.c: directory sign 'd' replaced with '/' */
/* 04.03.99 - file_hnd.c: LONG_BAK_NAMES */
/* 04.03.99 - commands.c: corresponding brackets '<' and '>' (e.g. for HTML code) */
/* 07.03.99 - doc_html: Documentation in HTML Code */
/* 16.03.99 - kb_input.c: _os_gs_popt() and _os_ss_popt() */
/* 20.03.99 - kb_input.c: OS_9_PPC: scf_lu_opts (disable ^C, ^E) */
/* 22.06.99 - global.h: Copyright message */
/* 22.06.99 - commands.c: comm_find_byte(): bugfix (unsigned char) */
/* 16.09.99 - disp_hnd.c: hex_view(): 'O'ther */
/* 25.09.99 - disp_hnd.c: hex_view(): bugfix line_2_flag */
/* 25.08.00 - disp_hnd.c: disp_1_line(): bugfix comment_type */
/* 07.11.00 - config.h: OSF_1: CLEAR_WITH_BLANKS 1 */
/* 23.05.02 - global.h, help_opt.c: url_string */
/* 25.05.02 - help_opt.c: show_intro(): sleep_msec(1000) */
/* 08.06.02 - macro.c: bugfix in read_macro_file(): 'S'et 'T'abs: check_dirty_cursor() */
/* 06.08.02 - disp_hnd.c: bugfix: OUTPUT_OPTIMIZED 1 --> 0 */
/* 17.10.02 - disp_hnd.c: LINUX: DISPLAY_PAUSE */
/* 14.11.02 - commands.c: comm_ctrl_k(): #elif */
/* 27.03.03 - config.h: SUN_OS: WITH_SYNTAX_HIGHLIGHTING 1 */
/* 31.03.03 - disp_hnd.c, hi_light.h, mbedit.syn: new WITH_SYNTAX_HIGHLIGHTING */
/* 31.03.03 - str_synt */
/* 02.04.03 - disp_hnd.c: bugfix case hi_light_default[] */
/* 04.04.03 - disp_hnd.c: bugfix malloc (num_keywords = 0) */
/* 16.04.03 - commands.c: comm_ctrl_k(): ada: if, else, elsif, end if */
/* 16.04.03 - commands.c: comm_ctrl_k(): ada: loop, end loop */
/* 23.04.03 - macro.c: read_macro_file(): break reading line with 0x0a and 0x0d */
/* 24.04.03 - disp_hnd.c: disp_1_line(): bugfix: overlapping start/end of comment */
/* 24.04.03 - commands.c: comm_ctrl_k(): ada: xxxx, end xxxx (any string) */
/* 25.04.03 - config.h: SUN_OS: #define WITH_USEC_CLOCK 1 */
/* 25.04.03 - comm_ctrl_k(): ada: ^K: ignore token xxxx, if inside comment or string */
/* 28.04.03 - commands.c: comm_ctrl_k(): correct handling of comments and strings */
/* 25.04.03 - is_comment_ml1(), is_comment_ml2(), is_comment_sl() */
/* 29.04.03 - disp_hnd.c: get_line_2_string(): STRICTLY_AEDIT_COMPATIBLE 0 */
/* 30.04.03 - disp_hnd.c, mon_outp.c, macro.c: syntax highlighting for strings */
/* 01.05.03 - wildname.c: wildcard filename + "vo" in WIN_32 */
/* 01.05.03 - disp_hnd.c: syntax highlighting for 'strings' with single quotes */
/* 07.05.03 - handle nested strings, e.g. "this is a 'string' example" */
/* 07.05.03 - config2.hh: CYGWIN: New ! */
/* 08.05.03 - commands.c: disable Ada ticks, enable short strings */
/* 10.05.03 - disp_hnd.c: comment_fc (comment character 1st column, e.g. "C" for Fortran) */
/* 11.05.03 - commands.c: ^K: Ada identifier "xxxx" and "end xxxx" with white space */
/* 12.05.03 - commands.c: ^K: Ada identifier "xxxx" with delimiter before and behind */
/* 11.09.03 - commands.c: ^K: Ada "if, else, end if": with delimiter before and behind */
/* 11.09.03 - disp_hnd.c: bugfix: is_inside_comment_single() from start of line with <lf> */
/* 15.09.03 - commands.c: bugfix: ^K: Ada, nested "if, end if" */
/* 04.10.03 - switches.c: 'S' 'V': BOT_ROW --> MAX_ROW */
/* 29.10.03 - disp_hnd.c: show_status_line_2(): bugfix extreme long/short lines */
/* 02.11.03 - disp_hnd.c, commands.c: has_single_quote_string():
              Visual Basic uses single quote for comments, not strings */
/* 06.12.03 - kb_input.c, mon_outp.c: avoid_hanging_display() */
/* 07.12.03 - disp_hnd.c, mbedit.syn: filenames without extension (e.g.: "makefile") */
/* 08.12.03 - disp_hnd.c, mbedit.syn: filenames without extension,
              but leading pathname (e.g.: "./makefile") */
/* 05.02.04 - kb_input.c: loc_get_1_int(): return (key & 0xff); */
/* 07.02.04 - mbed_sub.c: bugfix: key <End> at begin of file with empty line
              leads to program crash (some OS) due to attempt to read buff[-1] */
/* 08.02.04 - window.c: scroll down text, if last line above bottom */
/* 11.02.04 - 'S'et 'H'ighbit 'A'uto */
/* 14.02.04 - disp_hnd.c: inside_keyword excludes comments and strings
   (e.g.: "$#" in shell scripts, the "#" doesn't mark the begin of a comment here) */
/* 13.03.04 - disp_hnd.c: modifications for CSS (dashes in keywords) */
/* 14.03.04 - disp_hnd.c: bugfix syntax highlighting */
/* 18.03.04 - disp_hnd.c: bugfix comments inside strings */
/* 19.03.04 - disp_hnd.c: bugfix of previous bugfix */
/* 23.03.04 - disp_hnd.c: bugfix is_keyword (token isolated from delimiters) */
/* 24.03.04 - mbedit.c: init_file_control(): Don't set fc->e_delimit */
/* 20.03.05 - new website */
