/*      history.h                          04.07.94       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for history.c (function prototypes)
/
*/


/************************/
/*  enums               */
/************************/

/* history types */
enum HIST_ID {ID_FILE,   /*  0 */
              ID_MARG,   /*  1 */
              ID_NUMB,   /*  2 */
              ID_FIND,   /*  3 */
              ID_REPL,   /*  4 */
              ID_SYST,   /*  5 */
              ID_CALC,   /*  6 */
              ID_MACR,   /*  7 */
#if (WITH_E_DELIMIT)
              ID_DELI,   /*  8 */
#endif
              HIST_NUM   /*  9  last entry in enum table */
                         /*     = no of history types    */
             };


/* some constants */

#define HIST_SIZE     16   /* Anzahl Eintraege pro History Buffer */
#define HIST_MIN_LEN  10   /* min. Fensterbreite ( < max. length !!) */ 

#if (ACT_OP_SYSTEM == MS_DOS)
#define HIST_MAX_LEN  60   /* max. Fensterbreite ( < save length !!) */ 
#else
#define HIST_MAX_LEN 160
#endif

#define INVERT_WHOLE_LINE 0   /* 1 = balken volle laenge */
                              /* 0 = nur text invers     */
/* vor-/nachteile der beiden modi:                           */
/* 1 ist xtree-kompatibel                                    */
/* 0 ist schneller (wichtig bei vt100-terminals),            */
/*   und man kann ggf. die blanks am ende des strings sehen. */

/* -FF-  */

/* function prototypes */

/* global */
extern void set_grafik_status   (int flag);
extern char *get_history_buffer (enum HIST_ID id);
extern int  read_history_file   (void);
extern int  write_history_file  (int status);
extern int  read_status_file    (void);
extern int  write_status_file   (void);
extern void save_history_string (enum HIST_ID id, char *string);
extern char *get_home_dir       (void);
extern void plot_rectangle      (int top, int left, int bot, int rigth);

/* local */
static void plot_content (enum HIST_ID id, int select_line);
static void plot_history_window (enum HIST_ID id);
static void print_history_line (enum HIST_ID id, int line,
                                int select_flag, int modified);
static void limit_at_1st_blank (char *string);


/* Modification History */
/* 08.01.93 - file erzeugt */
/* 10.06.93 - GRAF_ON, _OFF auch bei nicht VT-100 */
/* 11.06.93 - Xterm gestrichen */
/* 10.09.93 - get_home_dir() */
/* 10.10.93 - ID_FILE */
/* 04.11.93 - plot_rectangle: static --> extern */
/* 06.11.93 - plot_content: ohne modified */
/* 29.11.93 - semigrafik abschaltbar */
/* 09.02.94 - limit_at_1st_blank () */
/* 21.05.94 - write_status_file(), read_status_file() */
/* 04.07.94 - ID_DELI (for Set E_delimit) */
