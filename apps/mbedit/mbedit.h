/*      mbedit.h                               11.02.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 2004: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for mbedit.c (function prototypes)
/
*/


/************************/
/* often used macros    */
/************************/


/************************/
/* some defines         */
/************************/


/************************/
/* often used defines   */
/************************/


/************************/
/*  forward references  */
/************************/

/* file: mbedit.c */
extern int  main (int argc, char **argv);
extern void set_auto_shift (int flag);
extern void resize_screen  (void);
extern void limit_windows  (void);
static void main_loop      (void);

extern char * get_line_1_text  (void);
extern void init_file_control  (struct FILE_CONTROL *fcl, int clear_flag);
extern int  get_next_file_buffer (int direction);
extern void set_highbit(void);
extern int  get_1_datafile (void);
extern void exchange_file_control (int file_num, int direction);
extern char *get_exe_path (void);
extern void store_exe_path (char *pathname);
extern void set_mouse_moved (void);
extern void set_mouse_status (int stat);

static int num_from_stream (FILE *fd, char *search_string, int *number);
static int mb_tput (char *arg_str, int *number);

extern void cmd_winch (int sig_num);
extern int  set_window_size (void);

/************************/
/*  public variables    */
/************************/


/* Modification History */
/* 24.11.92 - main_loop () */
/* 25.11.92 - perform_key_... () */
/* 26.11.92 - get_total_lines () */
/* 27.11.92 - insert, exchange */
/* 29.11.92 - valid_char () */
/* 30.11.92 - perform_view () */
/* 01.12.92 - perform_find () */
/* 04.12.92 - err_read_file () */
/* 27.07.93 - get_next_file_buffer (int direction) */
/* 02.10.93 - init_file_control (..., int clear_flag) */
/* 09.12.93 - set_mouse_moved () */
/* 13.12.93 - set_mouse_status () */
/* 07.01.94 - set_auto_shift () */
/* 02.06.94 - cmd_winch () */
/* 03.06.94 - set_window_size () */
/* 04.06.94 - cmd_winch () + set_window_size (): without #ifdef */
/* 08.06.94 - num_from_stream () */
/* 16.02.95 - get_spec_file_buffer () */
/* 11.02.04 - 'S'et 'H'ighbit 'A'uto */
/* 24.03.04 - get_spec_file_buffer() removed */
