/*      macro.h                                  27.11.95       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for macro.c (function prototypes)
/
*/


/************************/
/* structures           */
/************************/

struct MACRO {
                struct MACRO * next_macro;  /* thread pointer */
                int  * i_ptr;               /* sequence pointer */
                int  length;                /* total macro length in Bytes */
                int  mode;                  /* 0 = MM, 1 = EM */
                char name     [40];         /* name length is limited ! */
                int  sequence [1];          /* [1] ist platzhalter */
             };

enum MACRO_STATUS { NORMAL_MODE,       /* 0 */
                    MACRO_EXECUTE,     /* 1 */
                    MACRO_CREATE       /* 2 */
                  };

struct MACRO_STACK {long              repeat;
                    long              cntexe;
                    long              cntmac;
                    struct MACRO *    macro;
                    int               save_mode_flag;
                    enum MACRO_STATUS status;    /* 0, 1, 2 */
                   };

#define MAX_STACK_NUM   10    /* macro execution    nesting level */

#if (ACT_OP_SYSTEM != MS_DOS)
#define MAX_INCLUDE_NUM 10    /* macro include file nesting level */
#else
#define MAX_INCLUDE_NUM  4    /* wg. speicherplatz */
#endif

/************************/
/* often used macros    */
/************************/


/************************/
/* often used defines   */
/************************/


/************************/
/*  forward references  */
/************************/

/* file: macro.c */

#if (MACRO_TUNING)
static void drop_double_entries (void);
static void test_tables (void);
extern void init_sorted_tables (void);

#if (QSORT_FUNC_ANSI)
static int comp_keys    (const void *kt1, const void *kt2);
static int comp_strings (const void *kt1, const void *kt2);
#else
static int comp_keys    ();
static int comp_strings ();
#endif

#endif

extern int start_index (int len);
extern char * key_2_string (int key);
extern int string_2_key (char **string);

extern struct MACRO *init_macro (char *macro_name);
extern struct MACRO *get_macro_adress (char *macro_name);
extern size_t mac_len (struct MACRO *macro);
extern int free_current_macro (struct MACRO *macro);
extern int unchain_macro (char *macro_name);
extern struct MACRO *chain_macro (struct MACRO *macro_adress, int mode);

extern int get_macro_aborted (void);
extern void reset_macro_stack (void);
extern void stop_this_macro (void);
extern int push_macro_stack (struct MACRO *macro, enum MACRO_STATUS status,
                             long repeat, int save_mode_flag);
extern long pop_macro_stack (struct MACRO *macro, int dekr_repeat);
extern enum MACRO_STATUS get_macro_status (void);

extern int  get_macro_nesting_level (void);
extern int  get_save_mode_flag      (void);
extern long get_macro_cntexe (void);
extern long get_macro_cntmac (void);

extern int get_macro_key (void);
extern int put_macro_key (int key);
extern int delete_last_macro_key (void);

extern int save_macro (char *macro_name);
extern int insert_macro (void);
extern int list_macros  (void);

extern char *get_macro_filename (void);

#if (WITH_E_DELIMIT)

#if (QSORT_FUNC_ANSI)
static int comp_chars (const void *ch1, const void *ch2);
#else
static int comp_chars ();
#endif

static void drop_double_chars (char *string, size_t num);
extern void normalize_delims (void);
#endif

extern int read_macro_file (char *filename, int store_filename);
extern int search_macro_file (void);


/************************/
/*  public variables    */
/************************/


/* Modification History */
/* 30.12.92 - file erzeugt */
/* 01.01.93 - macro_stack */
/* 02.01.93 - struct MACRO ohne char_M (vor name) */
/* 03.01.93 - struct MACRO : int repeat */
/* 05.01.93 - search_macro_file () */
/* 17.02.94 - read_macro_file (..., store_filename) */
/* 12.05.94 - MACRO_TUNING */
/* 04.07.94 - WITH_E_DELIMIT */
/* 30.09.94 - start_index () global */
/* 24.02.95 - QSORT_FUNC_ANSI */
/* 27.11.95 - MAX_INCLUDE_NUM */
