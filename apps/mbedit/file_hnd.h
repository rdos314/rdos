/*      file_hnd.h                          03.11.95       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for file_hnd.c (function prototypes)
/
*/

/* function prototypes */

/* local */
static int gen_backup_file   (char *name_inp, char *name_outp);
static char *create_bak_name (char *filename);

static int stat_2_modes (int inp_mode);
static int get_file_attributes (char *filename);
static int put_file_attributes (char *filename);
static int file_without_write_permission (char *filename);
static int set_write_permission (char *filename);


/* global */
extern int  delete_datafile (char *filename);
extern int rename_datafile (char *name_inp, char *name_outp);

extern long get_file_length (char *filename, int file_must_exist);

extern long read_datafile   (char *filename, char FA_HU *buff_0,
                             long max_len, int file_must_exist);

extern int  write_datafile  (char *filename, char FA_HU *buff_0,
                             long byte_anz , int overwrite_allowed,
                             int backup_file);



/* Modification History */
/* 20.11.92 - file erzeugt */
/* 30.11.92 - BUF_LEN */
/* 03.12.92 - loc_malloc (), loc_free () public gemacht */
/* 06.12.92 - write_datafile () : generate backup file */
/* 19.12.92 - FA_HU (far / huge) */
/* 28.08.93 - create_bak_name */
/* 29.08.93 - get- put_file_attributes () */
/* 02.09.93 - delete_datafile () */
/* 05.10.93 - rename_datafile() */
/* 03.11.95 - stat_2_modes(): for setting of file attributes in os_9 */
