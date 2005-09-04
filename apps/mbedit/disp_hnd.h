/*      disp_hnd.h                          19.03.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 2004: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for disp_hnd.c (function prototypes)
/
*/


/* some defines */


/* some structures */
struct INVERS
{
    int flag;
    int row;
    int col;
};


/* function prototypes */
/* global */
int is_comment_ml1 (char *buf);
int is_comment_ml2 (char *buf);
int is_comment_sl  (char *buf);

int is_inside_string_or_comment (char FA_HU *buff, long start_index,
                                 long max_index, int first, int direction);
int get_file_type (char *pathname);
int is_inside_comment_multi (char FA_HU * buff_0, long start_index, long max_index, int first, int direction);
int is_inside_comment       (char FA_HU * buff_0, long start_index, int first, int direction);
int has_single_quote_string (void);
char *get_hi_light_delimiters (int file_index);

extern void update_this_line (long lin_left, int row);
extern void update_rest_of_window (long lin_left, int row);
extern void update_entire_window (long top_left);
extern void perform_update (char FA_HU * buff_0, long byte_anz,
                            int left_col);
extern void push_status_line_2 (void);
extern void pop_status_line_2  (int left_justified, int cursor_pos,
                                int ignore_batch);
extern void refresh_1_window     (void);
extern void refresh_whole_screen (void);

extern void set_batch_mode (int mode);
extern int  get_video_active (int ignore_batch);
extern void push_video_stack (void);
extern void pop_video_stack (void);

#if (WITH_ACTION_FLAG)
extern void show_action_flag   (char flag);
#endif

extern void show_status_line_1 (char * filename, struct FILE_CONTROL *fc0);
extern void show_status_line_2 (char *text, int left_justified,
                                int cursor_pos, int ignore_batch);
extern long get_line_2_repeat  (char *text, long old_value, int *key);

#if 0
extern int  get_line_2_dez     (char *text, long *value);
extern int  get_line_2_hex     (char *text, long *value);
#endif

extern char *build_modified_string (char *str_buf, int index1,
                                    int *index2, int *error);
extern int  get_line_2_string  (char *text, char *old_string,
                                int end_char, enum HIST_ID id);
extern int  get_hex_value      (void);
extern int  perform_special_keys (int key, int use_radix);
extern void clear_text_buffers (void);
extern void refresh_display_window (int top, int left, int bot, int right);

extern void show_find_result (char *string, int find_count, int replace_count);
extern int  show_find_display (int command, int all_flag, int lf_strings,
                               int first_call, int last_call, int find_ok);
extern int get_hit_any_key (void);
extern int read_syntax_file (char *filename);
extern int search_syntax_file (void);
extern int show_syntax_file (void);

#if (WITH_HEX_VIEW)
extern void hex_one_line (long i1, long i2);
extern void hex_one_screen (long i1, long i2);
extern void hex_view (void);
extern void hex_edit (void);
extern void hex_refresh_disp (void);
#endif

/* local */
static size_t is_keyword (char FA_HU * buf, long start_index, long end_index);
static void disp_memory (char FA_HU * buff_0, long start_index,
                         long byte_anz, int left_col,
                         int start_row, int end_row);
static long disp_1_line (char FA_HU * buff_0, long start_index, long byte_anz,
                         int row, int left_col, int start_comment);
static void set_error   (char *e, int no);

static void optimize_output (int line, int column,
                             char *text, byte *attr,
                             int attr_mode, int show_cursor);
static int out_string_attr  (char *text, byte *attr, int attr_mode);


/* Modification History */
/* 23.11.92 - file erzeugt */
/* 24.11.92 - disp_1_line () */
/* 26.11.92 - show_status_line_1 (): line_index + _anz */
/* 28.11.92 - ausgabe speed-optimiert */
/* 03.12.92 - show_status_line_1 () mit file_no */
/* 04.12.92 - get_line_2_repeat () */
/* 09.09.93 - struct INVERS */
/* 12.09.93 - get_video_active (ignore_batch) */
/* 29.09.93 - update_rest_of_window(), ...entire_window() */
/* 15.12.93 - build_modified_string (..., int *error) */
/* 20.05.94 - show_action_flag () */
/* 07.06.94 - push_status_line_2 (), pop_status_line_2 () */
/* 21.09.94 - WITH_HEX_VIEW: hex_view () */
/* 22.09.94 - WITH_HEX_VIEW: hex_edit () */
/* 26.09.94 - hex_refresh_disp() */
/* 27.09.94 - WITH_SYNTAX_HIGHLIGHTING */
/* 29.09.94 - byte *attr */
/* 05.10.94 - is_keyword (..., end_index) */
/* 14.10.94 - attr_flag entfaellt */
/* 14.10.94 - out_string_inv() --> out_string_attr() */
/* 29.03.03 - struct FILE_TYPE */
/* 25.04.03 - is_comment_ml1(), is_comment_ml2(), is_comment_sl() */
/* 13.03.04 - disp_hnd.c: modifications for CSS (dashes in keywords) */
/* 19.03.04 - disp_hnd.c: bugfix of previous bugfix */
