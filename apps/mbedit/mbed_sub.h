/*      mbed_sub.h                               05.09.98       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for mbed_sub.c (function prototypes)
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

/* file: mbed_sub.c */
extern int line_length    (char FA_HU *buff_0, long byte_index, long byte_anz,
                           int with_eol);
extern int line_blanks    (char FA_HU *buff_0, long byte_index, long byte_anz);
extern int first_nonblank (char FA_HU *buff_0, long byte_index, long byte_anz);
extern int line_columns   (char FA_HU *buff_0, long byte_index, long byte_anz);
extern int act_column     (char FA_HU *buff_0, long byte_index);
extern long act_index     (char FA_HU *buff_0, long byte_index, long byte_anz,
                           int  column);
extern int  get_left_chars (char FA_HU *buff_0, long byte_index);
extern int  get_var_eoln   (char FA_HU *buff_0, long byte_index, long byte_anz);
extern long get_total_lines(char FA_HU *buff_0, long byte_index, long byte_anz);
extern long line_to_index  (char FA_HU *buff_0, long byte_index, long byte_anz,
                            long line_no);
extern int line_contents_tabs (char FA_HU *buff, long index_1, long max_ind);
extern int non_empty_line     (char FA_HU *buff, long index_1, long max_ind);


/* Modification History */
/* 26.11.92 - file erzeugt */
/* 27.11.92 - line_columns () */
/* 02.12.92 - get_left_chars () */
/* 19.12.92 - FA_HU (far / huge) */
/* 10.09.93 - line_length (..., int with_eol) */
/* 07.10.93 - line_is_empty() */
/* 08.10.93 - line_blanks() */
/* 05.09.98 - get_var_eoln() */
