/*      perform.h                               26.01.96       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for perform.c (function prototypes)
/
*/


/************************/
/* often used macros    */
/************************/


/************************/
/* often used defines   */
/************************/


/************************/
/*  forward references  */
/************************/

/* file: perform.c */
extern long perform_find        (int direction, char *string,
                                 int show_remark, size_t *len1);
extern long perform_find_byte   (char byte_1, char byte_2);
extern void save_find_indizes   (int direction, long new_index, size_t len1);
extern long perform_lower_upper (int up_flag);
extern void perform_file_reset  (void);
extern void perform_move        (long new_index);
extern void check_dirty_cursor  (void);
extern void check_tag_index     (long old_index, long delta);

extern int  perform_insert_eol (void);

#if (!TEST_EOL_MACRO)
extern int  perform_test_eol (char *buffer, int offset);
#endif

extern int  perform_key_left    (byte update_cursor, int skip_flag);
extern int  perform_key_right   (byte update_cursor, int skip_flag);
extern int  perform_key_up      (byte update_cursor);
extern int  perform_key_down    (byte update_cursor);

extern void perform_begin_of_line (byte update_cursor);
extern void perform_end_of_line   (byte update_cursor);
extern int  perform_page_up       (void);
extern int  perform_page_down     (void);
extern void view_or_update        (void);
extern void perform_scroll_screen (int delta);
extern void perform_view          (void);
extern void view_unconditionally  (void);

extern void perform_delete_left_char     (void);
extern void perform_delete_right_char    (void);
extern void perform_delete_start_of_line (int save_flag);
extern void perform_delete_rest_of_line  (void);
extern void perform_delete_whole_line    (void);
extern int  perform_undo                 (void);

extern int  valid_char            (int key);
extern int  perform_string_insert (char *string);
extern void check_for_autonl      (void);
extern int  perform_key_insert    (int key, int check);
extern int  perform_key_exchange  (int key, int check);

extern int  perform_file_compare  (void);


/************************/
/*  public variables    */
/************************/


/* Modification History */
/* 06.12.92 - file erzeugt */
/* 07.12.92 - perform_help_option () */
/* 22.12.92 - perform_intro () */
/* 30.12.92 - perform_string_insert () */
/* 02.01.93 - int perform_key_insert ()     (vorher void) */
/* 28.07.93 - int perform_insert_eol () */
/* 03.09.93 - perform_delete_start_of_line (int save_flag) */
/* 07.09.93 - perform_find (..., size_t *len1) */
/* 08.09.93 - save_find_indizes () */
/* 16.09.93 - TEST_EOL_MACRO */
/* 03.10.93 - perform_scroll_screen () */
/* 11.10.93 - perform_key_left() / right(.., skip_flag) */
/* 06.07.94 - check_for_autonl() */
/* 09.07.94 - view_unconditionally() */
/* 16.02.95 - perform_file_compare() */
/* 26.01.96 - perform_find_byte() */
