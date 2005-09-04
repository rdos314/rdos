/*      blocks.h                               18.05.94       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for blocks.c (function prototypes)
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

/* file: blocks.c */
extern long get_save_length (void);
extern char * get_save_buffer (void);
extern int  block_save    (char FA_HU *buff_0, long index1, long index2);
extern long block_restore (struct FILE_CONTROL *fc0);
extern long block_remove  (char FA_HU *buff_0, long index1,
                           long index2, long byte_anz);
extern long block_insert  (char FA_HU *buff_0, long index1,
                           long byte_anz, long max_len,
                           char FA_HU *ins_buff, long len2);
extern int check_and_increase_buffer (struct FILE_CONTROL *fc0, 
                                      long new_size, long reserve,
                                      int force_malloc);


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
/* 02.12.92 - remove_block (), insert_block () */
/* 20.12.92 - FA_HU */
/* 06.01.93 - block_restore, block_insert: max_len */
/* 18.05.94 - macro lengthof nur in standard.h */
