/*      commands.h                               08.05.03       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for commands.c (function prototypes)
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


static char unchanged_char   (char byte1);
static int  get_part_strings (char *text, int wild_cards);
static int  is_visible_token (char FA_HU *buff, long start_index, long max_index, int first, int direction);

int is_inside_string    (char FA_HU *buff, long start_index, long max_index, int first);
int is_string_character (char FA_HU *buff, long index, long max_index);
int  is_german          (char byte1);
void comm_umlaut        (char *buffer);
void lower_upper_umlaut (char *buffer, int up_flag);
char toupper_german     (char byte1);
char tolower_german     (char byte1);
int  is_delimiter       (char byte1);

long comm_find          (char FA_HU *buff, long index_1,
                         long max_ind, char *such_string,
                         int direction, int consider_case, int k_token,
                         int wildcards, size_t *len1);

long comm_find_byte     (char FA_HU *buff, long index_1,
                         long max_ind, char byte_1, char byte_2);

long comm_lower_upper   (char FA_HU *buff, long index_1,
                         long max_ind, int up_flag);

long comm_ctrl_k        (char FA_HU *buff, long index_1, long max_ind);

int parse_input_string  (char *string);

int string_with_eol     (char *string);

int get_current_string (char FA_HU *buff_0, long byte_index,
                        long byte_anz, char *buffer);

/* Modification History */
/* 29.11.92 - file erzeugt */
/* 01.12.92 - comm_find () */
/* 02.12.92 - comm_ctrl_k */
/* 09.12.92 - string_with_lf () */
/* 10.12.92 - is_umlaut (), lower_upper_umlaut () */
/* 19.12.92 - FA_HU (far / huge) */
/* 30.12.92 - get_current_string () */
/* 04.01.93 - tolower_german () */
/* 05.09.93 - Find mit Wildcard: '?' */
/* 07.09.93 - unchanged_char () */
/* 09.09.93 - get_part_strings () */
/* 26.01.96 - comm_find_byte() */
