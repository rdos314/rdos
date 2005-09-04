/*      wildname.h                                    23.10.95       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for wildname.c
/
*/


/* constants */

#if (ACT_OP_SYSTEM == MS_DOS)
#define MAX_FILENAME 13
#else
#define MAX_FILENAME 80
#endif

#define WILD_MIN_LEN  20

#if (ACT_OP_SYSTEM == MS_DOS)
#define WILD_MAX_LEN  60
#else
#define WILD_MAX_LEN 160
#endif


/* structures */

struct DIR_ENTRY
       {
          int dir_flag;    /* 1 = directory, 0 = file */
          char name [MAX_FILENAME];
       };


/* function prototypes */

/* local */
#if (QSORT_FUNC_ANSI)
static int comp_dirs  (const void *de1, const void *de2);
static int comp_names (const void *de1, const void *de2);
#else
static int comp_dirs  ();
static int comp_names ();
#endif

static struct DIR_ENTRY *get_directory_buffer (char *path  , char *filter,
                                               int *dir_num, int *total_num);
static void print_dir_line (char *string, int act_ind,
                            int select_flag, int modified);
static void plot_dir_content (struct DIR_ENTRY *de,
                              int top_ind, int row_ind,
                              int total_num, int plot_new);
static void plot_dir_window  (struct DIR_ENTRY *de, int total_num);
static void prepare_indizes (int delta, int total_num,
                             int *file_ind, int *row_ind, int *top_ind);
static void restore_window_background (int top, int left, int bot, int right);
static int  get_real_filename (char *pathname, int filename_index);

/* global */
extern int  wildcard_filename (char *pathname);

/* -FF-  */

/* Modification History */
/* 02.11.93 - file erzeugt */
/* 24.02.95 - QSORT_FUNC_ANSI */
/* 20.10.95 - window-size dynamic = f (filename-length) */
/* 22.10.95 - WILD_MAX_LEN, WILD_MIN_LEN */
/* 23.10.95 - bugfix */
