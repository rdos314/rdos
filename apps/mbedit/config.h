/*      config.h                            17.02.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 2003: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for all mbedit files
/
/    configuration of operating system, video server, ...
/
*/


/* the actual operating system is defined here */
#include "config2.hh"

#if 0

/* -FF-  */

   ==============================================================
     Einige Anmerkungen zur Portierung auf verschiedene Systeme
   ==============================================================

   In diesem header-file sind die zentralen Informationen zur
   Anpassung an die verschiedenen Betriebssysteme zusammengefasst.

   Zum Kompilieren des Programmpakets auf dem jeweiligen Betriebssystem
   muss die #define-Konstante ACT_OP_SYSTEM auf einen der moeglichen
   Werte gesetzt werden.

   Um ein hohes Mass an Portabilitaet zu erreichen (besonders der compiler
   unter ultrix hat hier Schwierigkeiten gemacht), sind beim Programmieren
   folgende Richtlinien zu beachten:

      - compiler-schalter (die dinger mit dem '#') muessen immer in der
        ganz linken Spalte stehen, einruecken ist nicht erlaubt.

      - Konstante Ausdruecke duerfen kein fuehrendes '+' enthalten,
        also:      ii =  1;
        anstatt:   ii = +1;   (erlaubt ist natuerlich:  ii = -1;)

      - Die function 'main' muss im K+R-Format stehen, nicht in ANSI.
        also:      int main (argc, argv)
                   int argc; char *argv[];
                   { ...
        anstatt:   int main (int argc, char *argv[])
                   { ...

      - Der ultrix-compiler kennt den type specifier 'const' nicht.
        Das laesst sich aber (siehe UNIX-Zweig) mit der Anweisung
        #define const   /* nix */               leicht beheben.

      - Der header-file 'ctype.h' und die darin enthaltenen Makros duerfen
        nicht verwendet werden, wenn deren Argumente negativ werden koennen.

        Dies ist bei einigen Programmen der Fall; z.B. die Tasten-Codes der 
        'special keys' (Funktions- und Cursor-Tasten, ALT-Kombinationen) 
        sind in der internen Darstellung als negative ints repraesentiert.
        
        Um diesen Problemen aus dem Wege zu gehen, wurden die benoetigten
        Programme (toupper, tolower, isdigit, isxdigit, isprint, ...)
        selbst neu geschrieben (siehe file 'mb_ctype.c').

        Wenn weitere dieser Macros verwendet werden sollen, muessen auch
        diese umgeschrieben werden (nur, wenn neg. Argumente vorkommen).

        Diese Problematik besteht uebrigens bei allen Systemen.

      - In microsft.c stehen einige Routinen, die sonst nur in der 
        Microsoft-Library existieren, aber kein ANSI-Standard sind
        (stricmp, strnicmp, strupr, _lrotl, _lrotr).

      - Ferner gibt es in memo_hnd.c eine function 'memcpy_rev', die wie memcpy
        funktioniert, aber auch mit Laengen > 64 k, und unabhaengig von der
        Schieberichtung (problematisch bei Ueberlappung von src und dest).

      - Der ultrix-compiler versteht Hex-Konstanten nur in character-
        Ausdruecken, nicht aber in strings. Dort muss die oktale Schreib-
        weise verwendet werden.
        also:      "\033"     <esc>
        anstatt:   "\x1b"     (erlaubt ist dagegen auch '\x1b' fuer '\033')

/* -FF-  */

#endif

/*---------------------------------*/
/* definition of screen server     */
/*---------------------------------*/

#define SERVER_VGA     1
#define SERVER_VT_100  2

#if (ACT_OP_SYSTEM == MS_DOS)
#define ACT_SERVER        SERVER_VGA
#else
#define ACT_SERVER        SERVER_VT_100
#endif

#if (ACT_SERVER == SERVER_VGA)
#define TEXT_VIDEO_SERVER "VGA"
#define CHANGE_LINES_DIRECT 1
#else
#define TEXT_VIDEO_SERVER "vt 100"
#define CHANGE_LINES_DIRECT 0
#endif


#if (ACT_OP_SYSTEM == UNIX_SVR4)
#define SLOW_TERMINAL      1           /* <== select here !! */
#define WITH_CURSOR_ON_OFF 1
#else
#define SLOW_TERMINAL      0
#define WITH_CURSOR_ON_OFF 0
#endif


/* display action_flag ('?' or '!') in status line 1 */
#define WITH_ACTION_FLAG   1           /* <== select here !! */


/*---------------------------------*/
/* some special filenames          */
/*---------------------------------*/

#define HISTO_FILENAME "mbedit.hst"     /* history             */
#define STATS_FILENAME "mbedit.sta"     /* status (last_again) */
#define MACRO_FILENAME "mbedit.mac"     /* macros              */
#define TEMPO_FILENAME "mbedit.tmp"     /* temp's              */
#define SYNTX_FILENAME "mbedit.syn"     /* syntax highlighting */

#define FILENAME_LEN      13            /* max. 1+8+1+3 = 13 */


/*---------------------------------*/
/* some special features           */
/*---------------------------------*/

                                        /* mbedit option "- | last_again"  */
#define WITH_LAST_AGAIN    1            /* 0: no  "mbedit.sta" at all      */
                                        /* 1: one "mbedit.sta" in home dir */
                                        /* 2: one "mbedit.sta" in every    */
                                        /*    current dir (emacs style)    */

#define WITH_ZULU          1            /* command 'Z'ulu: 'B'eep, 'P'ause */

#define WITH_E_DELIMIT     1            /* 0: Delimiters are all chars except
                                           letters, digits and underscore  */
                                        /* 1: Set E_delimit is available   */


/*---------------------------------*/
/* definition of some global       */
/* characters + strings            */
/*---------------------------------*/


/* function "automatic resize after window change"                */
/*                                                                */
/* WITH_WINCH : not def. or 0 : SIGWINCH not available or unknown */
/*                          1 : SIGWINCH with "tput"              */
/*                          2 : SIGWINCH with "mb_tput"           */
/*                          3 : SIGWINCH with "ioctl"      (unix) */
/*                          4 : SIGWINCH with "eval; tput"  (SCO) */
/*                          5 : SIGWINCH with "vb_getvsize" (DOS) */
/*                          6 : SIGWINCH with "getstat"    (OS_9) */
/*                          7 : SIGWINCH with "mode con"          */
/*                          8 : SIGWINCH with "GetConsoleScreenBufferInfo" (WIN_32) */
/*                          9 : SIGWINCH with "tcgetsize" (QNX6 ) */

/* function "short sleep in steps smaller than 1 sec"             */
/*                                                                */
/* WITH_USEC_CLOCK: n.d. or 0 : clock() not available or unknown, */
/*                              use sleep() istead                */
/*                          1 : clock() available,use it          */


#define WITH_SYNTAX_HIGHLIGHTING  1


#if (ACT_OP_SYSTEM == MS_DOS)
#define TEXT_OP_SYSTEM "MS/DOS (Microsoft)"
#define WITH_WINCH      5
#define WITH_USEC_CLOCK 0
#define QSORT_FUNC_ANSI 1
#define CLEAR_WITH_BLANKS 0

#define EOLA            0x0a      /* <lf> */
#define EOLN_INIT       0x0d0a    /* <cr><lf> */
#define HELP_COMMAND    "qh "
#define CONSOLE_NAME    "CON"
#define PATH_SEPARATOR  ';'
#define FILE_SEPARATOR  "\\"
#define HOME_DIR        (const char *) getenv(":HOME:")
#define TEMP_DIR        (const char *) getenv("TMP")
#define NULL_DEVICE     "NUL"
#endif

#if (ACT_OP_SYSTEM == WIN_32)
#define TEXT_OP_SYSTEM "Windows (Microsoft)"
#define WITH_WINCH      8  /* 0 / 7 */
#define WITH_USEC_CLOCK 0
#define QSORT_FUNC_ANSI 1
#define CLEAR_WITH_BLANKS 0

#define EOLA            0x0a      /* <lf> */
#define EOLN_INIT       0x0d0a    /* <cr><lf> */
#define HELP_COMMAND    "qh "
#define CONSOLE_NAME    "CON"
#define PATH_SEPARATOR  ';'
#define FILE_SEPARATOR  "\\"
#define HOME_DIR        (const char *) getenv(":HOME:")
#define TEMP_DIR        (const char *) getenv("TMP")
#define NULL_DEVICE     "NUL"
#endif

#if (ACT_OP_SYSTEM == RDOS)
#define TEXT_OP_SYSTEM "RDOS operating system"
#define WITH_WINCH      8  /* 0 / 7 */
#define WITH_USEC_CLOCK 0
#define QSORT_FUNC_ANSI 1
#define CLEAR_WITH_BLANKS 0

#define EOLA            0x0a      /* <lf> */
#define EOLN_INIT       0x0d0a    /* <cr><lf> */
#define HELP_COMMAND    "qh "
#define CONSOLE_NAME    "CON"
#define PATH_SEPARATOR  ';'
#define FILE_SEPARATOR  "\\"
#define HOME_DIR        (const char *) getenv("MBEDIT")
#define TEMP_DIR        (const char *) getenv("TMP")
#define NULL_DEVICE     "NUL"
#endif


#if (ACT_OP_SYSTEM == OS_9)

#if (OS_9_PPC)
#define TEXT_OP_SYSTEM "os-9000 (Motorola)"
#else
#define TEXT_OP_SYSTEM "os-9 (Microware)"
#endif

#define WITH_WINCH      6
#define WITH_USEC_CLOCK 0
#define QSORT_FUNC_ANSI 1
#define CLEAR_WITH_BLANKS 0

#define EOLA            0x0d      /* <cr> */
#define EOLN_INIT       0x0d      /* <cr> */
#define HELP_COMMAND    "help "
#define CONSOLE_NAME    (const char *) getenv("PORT")
#define PATH_SEPARATOR  ':'
#define FILE_SEPARATOR  "/"
#define HOME_DIR        (const char *) getenv("HOME")
#define TEMP_DIR        "/r0/tmp"
#define NULL_DEVICE     "/nil"
#endif

#if (UNIX)

#if (ACT_OP_SYSTEM == UNIX_SVR4)
#define TEXT_OP_SYSTEM "unix (System V Rel.4)"     /* max. 21 chars. */
#define WITH_WINCH      0
#define WITH_USEC_CLOCK 1
#define QSORT_FUNC_ANSI 1
#define CLEAR_WITH_BLANKS 0

#elif (ACT_OP_SYSTEM == DEC_ULTRIX)
#define TEXT_OP_SYSTEM "unix (DEC ultrix)"
#define WITH_WINCH      3
#define WITH_USEC_CLOCK 1
#define QSORT_FUNC_ANSI 1
#define CLEAR_WITH_BLANKS 1

#elif (ACT_OP_SYSTEM == SGI_IRIX)
#define TEXT_OP_SYSTEM "unix (SGI IRIX)"
#define WITH_WINCH      3
#define WITH_USEC_CLOCK 1
#define QSORT_FUNC_ANSI 1
#define CLEAR_WITH_BLANKS 1

#elif (ACT_OP_SYSTEM == SUN_OS)
#define TEXT_OP_SYSTEM "unix (sun OS)"
#define WITH_WINCH      3
#define WITH_USEC_CLOCK 1
#define QSORT_FUNC_ANSI 1
#define CLEAR_WITH_BLANKS 0

#elif (ACT_OP_SYSTEM == SCO_UNIX)
#define TEXT_OP_SYSTEM "unix (SCO)"
#define WITH_WINCH      4
#define WITH_USEC_CLOCK 1
#define QSORT_FUNC_ANSI 1
#define CLEAR_WITH_BLANKS 0

#elif (ACT_OP_SYSTEM == LINUX)
#if (LINUX_FOR_CYGWIN)
#define TEXT_OP_SYSTEM "unix (cygwin)"
#else
#define TEXT_OP_SYSTEM "unix (linux)"
#endif
#define WITH_WINCH      3
#define WITH_USEC_CLOCK 1
#define QSORT_FUNC_ANSI 0
#define CLEAR_WITH_BLANKS 0

#elif (ACT_OP_SYSTEM == OSF_1)
#define TEXT_OP_SYSTEM "unix (DEC OSF/1)"
#define WITH_WINCH      3
#define WITH_USEC_CLOCK 1
#define QSORT_FUNC_ANSI 1
#define CLEAR_WITH_BLANKS 1

#elif (ACT_OP_SYSTEM == HP_UX)
#define TEXT_OP_SYSTEM "unix (hp-ux)"
#define WITH_WINCH      3
#define WITH_USEC_CLOCK 0
#define QSORT_FUNC_ANSI 0
#define CLEAR_WITH_BLANKS 1

#elif (ACT_OP_SYSTEM == QNX)    /* QNX4 or QNX6 */
#if (OS_QNX6)
#define TEXT_OP_SYSTEM "unix (qnx6)"
#define WITH_WINCH      9
#else
#define TEXT_OP_SYSTEM "unix (qnx4)"
#define WITH_WINCH      3
#endif
#define WITH_USEC_CLOCK 1
#define QSORT_FUNC_ANSI 0
#define CLEAR_WITH_BLANKS 0

#else
#define TEXT_OP_SYSTEM "unix (unknown)"
#define WITH_WINCH      0
#define WITH_USEC_CLOCK 0
#define QSORT_FUNC_ANSI 1
#define CLEAR_WITH_BLANKS 1
#endif


#define EOLA            0x0a      /* <lf> */
#define EOLN_INIT       0x0a      /* <lf> */
#define HELP_COMMAND    "man "
#define CONSOLE_NAME    "/dev/tty"
#define PATH_SEPARATOR  ':'
#define FILE_SEPARATOR  "/"
#define HOME_DIR        (const char *) getenv("HOME")
#define TEMP_DIR        "/tmp"
#define NULL_DEVICE     "/dev/null"
#endif


/* variable Endekennung */
#define VAR_EOLN  1    /* 0 = konst. */
                       /* 1 = var.   */

#if VAR_EOLN

#define EOLN fc->eoln

#else

#define EOLN EOLN_INIT

#endif



/* TEST !! Abschalten Binary-Mode, zwecks testen der unix/os9-version */

#define BINARY_MODE 1      /* <==    1 : Standard Mode MS/DOS */
                           /*        0 : Test unix + os/9     */

#if BINARY_MODE

#define READ_FORMAT  "rb"
#define WRITE_FORMAT "wb"

#else

#define READ_FORMAT  "r"
#define WRITE_FORMAT "w"

#undef  EOLN
#define EOLN EOLA

#endif


/* perform_test_eol() is a function/macro ? */
#if VAR_EOLN
#define TEST_EOL_MACRO 0      /* always 0 !!              */
#else
#define TEST_EOL_MACRO 1      /* <==    1 : optimal speed */
                              /*        0 : shorter code  */
#endif

/* some useful defines */
#define EOLN_LEN_1 (EOLN <= 0xff)
#define EOLN_LEN_2 (EOLN >  0xff)

#define EOLN_LOW   ((char)(EOLN &  0xff))
#define EOLN_HIGH  ((char)(EOLN >> 8))

#define perform_test_eol1(a,b) (*a == EOLN_LOW)

#if TEST_EOL_MACRO
#if (EOLN_LEN_1)

#define perform_test_eol(a,b) (*a == EOLN)

#else

#define perform_test_eol(a,b) ((*(a+b) == (EOLN_HIGH)) && (*(a+b+1) == (EOLN_LOW)))

#endif
#endif

/* -FF-  */

/* NEU !! Das help_command (ALT F1) wird wieder als macro ausgefuehrt !! */
#define HELP_COMMAND_DIRECT 0    /* 0: <ALT F1> als macro */
                                 /* 1: <ALT F1> direct    */

#if !(HELP_COMMAND_DIRECT)
#undef HELP_COMMAND
#endif


/* NEU !! Insert Key is handled directly (instead of a macro) !! */
#define INSERT_KEY_DIRECT 1    /* 0: <INSERT> als macro */
                               /* 1: <INSERT> direct (toggle insert/exchange) */


/* the user home directory and the temp directory */
/* are handled equally since 10.09.93 !!          */

#undef  HOME_DIR
#undef  TEMP_DIR

#define HOME_DIR        get_home_dir()
#define TEMP_DIR        get_home_dir()

/* -FF-  */

/*---------------------------------*/
/* definition of screen size       */
/*---------------------------------*/

#define INIT_COLUMNS   80

#if (ACT_SERVER == SERVER_VGA)
#define INIT_ROWS      25
#else
#define INIT_ROWS      24
#endif

#if (ACT_OP_SYSTEM == MS_DOS)
#define LIMIT_ROWS     60   /* fuer MS_DOS muss das produkt < 32 k sein ! */
#define LIMIT_COLUMNS 100   /* (limit in DGROUP !) */
#else
#define LIMIT_ROWS    127
#define LIMIT_COLUMNS 255
#endif

/*---------------------------------*/
/* definition of keyboard driver   */
/*---------------------------------*/

#define ESC_WAITTIME 100      /* wait for 2. char after <esc>, LSB = 1 msec */

#if (UNIX)
#define TIMER_TICK  1000                  /* timer clock rate, LSB = 1 msec */
#endif

#if (ACT_OP_SYSTEM == OS_9)
/* #define TIMER_TICK (1000/CLOCKS_PER_SEC) */  /* timer clock rate, LSB = 1 msec */
/* TIMER_TICK not used any more, inaccurate, and risc of "divide by zero" ! */
#endif


/*---------------------------------*/
/* definition of memory management */
/*---------------------------------*/

#define BUF_256        256     /* help buffer for edit functions */
#define MACRO_SIZE    4096     /* max. buffer for each macro */
#define INIT_FILESIZE 1000L    /* bei Bedarf wird der Buffer vergroessert */
#define FILE_RESERVE  1000L    /* for reallocation of file buffer */

#define BUFF_DYNAMIC   1      /* malloc () / free ()   <  64 kB   */
#define BUFF_HUGE      2      /* halloc () / hfree ()  >= 64 kB   */

#if (ACT_OP_SYSTEM == MS_DOS)
#define BUFF_MALLOC BUFF_HUGE

#if (BUFF_MALLOC == BUFF_DYNAMIC)
#define FA_HU far
#endif

#if (BUFF_MALLOC == BUFF_HUGE)
#define FA_HU huge
#endif
#else

#define BUFF_MALLOC BUFF_DYNAMIC
#define FA_HU

#endif

/* some char buffer [BUF_256] should be static */
#if 0
#define STATIC          /* old status */
#else
#define STATIC static   /* new status (28.08.93) */
#endif


/* demo version for a limited time interval */
#if (ACT_OP_SYSTEM == MS_DOS)
#define DEMO_VERSION 0    /* <== 0 = regular version */
                          /*     1 = shareware version */
                          /*     2 = demo version, strictly time limited */
#else
#define DEMO_VERSION 0
#endif


/* Window Kill_Window */
#define WINDOW_COMMAND 1  /* <== 1 = mit  (wie AEDIT) */
                          /*     0 = ohne (alt)       */

/* Paragraph Fill / Justify */
#define PARAGR_COMMAND 1  /* <== 1 = mit  (wie AEDIT) */
                          /*     0 = ohne (alt)       */

/* Read Files with Wilcard-Filename */
#define WILD_NAMES     1  /* <== 1 = mit (z.B. "*.c") */
                          /*     0 = ohne (alt)       */

/* With Mouse Support (PC only !)*/
#if (ACT_OP_SYSTEM == MS_DOS) || (ACT_OP_SYSTEM == RDOS)
#define WITH_MOUSE     1  /* <== 1 = mit Maus         */
                          /*     0 = ohne             */
#else
#define WITH_MOUSE     0
#endif

/* Translation from <cr> --> <cr><lf> */
#define C_R EOLN

/* tuning read_macro_file */
#if (ACT_OP_SYSTEM == MS_DOS)
#define MACRO_TUNING   0  /* <== 0 = small code */
#else
#define MACRO_TUNING   1  /* <== 1 = high speed */
#endif

/* Hex-Editor */
#define WITH_HEX_VIEW  1

/* Hex Find */
#define WITH_HEX_FIND  1

/* -FF-  */

/* Modification History */
/* 01.12.92 - file erzeugt */
/* 05.12.92 - ESC_WAITTIME, TIMER_TICK */
/* 19.12.92 - BUFF_HUGE */
/* 21.12.92 - EOL */
/* 09.01.93 - INIT_FILE_SIZE klein gemacht */
/* 20.04.93 - more filenames fuer MS_DOS */
/* 26.04.93 - HOME_DIR, TEMP_DIR (MS/DOS) mit getenv */
/* 04.06.93 - HOME_DIR, TEMP_DIR (MS/DOS) mit (const char *) getenv */
/* 27.07.93 - WITH_SEMI_GRAPHIK */
/* 28.07.93 - HELP_COMMAND wieder als macro */
/* 03.08.93 - BINARY_MODE 1 */
/* 25.08.93 - SGI_IRIX */
/* 28.08.93 - STATIC */
/* 10.09.93 - get_home_dir() */
/* 12.09.93 - DEMO_VERSION */
/* 16.09.93 - TEST_EOL_MACRO */
/* 30.09.93 - WINDOW_COMMAND */
/* 30.09.93 - TEST_EOLN */
/* 19.10.93 - handling of single <lf>s */
/* 02.11.93 - get_1_datafile(): read file with wildcards */
/* 04.11.93 - TEST_EOLN entfaellt */
/* 06.11.93 - WILD_NAMES */
/* 29.11.93 - config2.hh */
/* 01.12.93 - GRAFIK_OFF */
/* 06.12.93 - GRAFIK_OFF --> mon_outp.c */
/* 07.12.93 - define const (nix) */
/* 08.12.93 - ESC_WAITTIME 50 -> 200 */
/* 08.12.93 - WITH_MOUSE */
/* 07.01.94 - INSERT_KEY_DIRECT */
/* 09.05.94 - WITH_USEC_CLOCK (quick <esc> handling) */
/* 12.05.94 - MACRO_TUNING */
/* 17.05.94 - Unterscheidung UNIX-Varianten */
/* 19.05.94 - ESC_wait_time 200 -> 100 */
/* 19.05.94 - EOL --> EOLA  */
/* 21.05.94 - STATS_FILENAME */
/* 02.06.94 - WITH_WINCH */
/* 05.06.94 - INIT_ROWS 24 or 25 */
/* 07.06.94 - WITH_WINCH = 0, 1, 2 for different unix systems */
/* 04.07.94 - WITH_E_DELIMIT */
/* 14.07.94 - WITH_USEC_CLOCK = f (ACT_OP_SYSTEM) */
/* 21.07.94 - WITH_WINCH = 3 (set_window_size with ioctl) */
/* 21.09.94 - WITH_HEX_VIEW */
/* 27.09.94 - HP_UX: #define WITH_USEC_CLOCK 0 */
/* 30.09.94 - WITH_WINCH 4 for SCO_UNIX */
/* 22.01.95 - WITH_WINCH 5 for VGA */
/* 24.02.95 - QSORT_FUNC_ANSI */
/* 27.02.95 - linux: WITH_USEC_CLOCK 1 */
/* 19.10.95 - WITH_WINCH 6 (OS_9) */
/* 17.11.95 - UNIX_SVR4: WITH_SYNTAX_HIGHLIGHTING 1 */
/* 25.11.95 - WITH_ACTION_FLAG always 1 */
/* 27.11.95 - OS_9: TIMER_TICK is now dynamic */
/* 28.11.95 - OS_9: TIMER_TICK --> f(CLOCKS_PER_SEC), see: kb_input.c */
/* 31.01.96 - WITH_HEX_FIND */
/* 24.02.97 - HP_UX: WITH_SYNTAX_HIGHLIGHTING 1 */
/* 31.07.98 - stoe: QNX: WITH_CPP_SYNTAX_HIGHLIGHTING 1 */
/* 05.09.98 - VAR_EOLN, var. Endekennung eoln   */
/* 07.09.98 - EOLN_LOW, EOLN_HIGH: type cast (char) */
/* 02.02.99 - CLEAR_WITH_BLANKS now defined here (before in mon_outp.c) */
/* 04.03.99 - OS_9000, OS_9_PPC */
/* 14.02.00 - SUN_OS: WITH_WINCH = 3 */
/* 07.11.00 - OSF_1: CLEAR_WITH_BLANKS 1 */
/* 17.10.02 - LINUX: WITH_CPP_SYNTAX_HIGHLIGHTING 1 */
/* 26.03.03 - SUN_OS: WITH_CPP_SYNTAX_HIGHLIGHTING 1 */
/* 29.03.03 - WITH_CPP_SYNTAX_HIGHLIGHTING cancelled, replaced by new algorithm */
/* 17.04.03 - WITH_WINCH 7 (WIN_32) */
/* 25.04.03 - SUN_OS: #define WITH_USEC_CLOCK 1 */
/* 07.05.03 - CYGWIN: New ! */
/* 17.02.04 - QNX6: New ! */
