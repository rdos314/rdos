/*      err_mess.h                               30.03.03       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for err_mess.c (function prototypes)
/
*/


/************************/
/* often used macros    */
/************************/


/************************/
/* often used defines   */
/************************/


/************************/
/*  enums               */
/************************/

/* error message types */
enum ERR_TYPE {BUFFER_OVERFLOW,
               ILLEGAL_COMMAND,
               NOT_MORE_THAN_32,
               INVALID_CHARACTER,
               INVALID_INPUT_VALUE,
               NO_SUCH_TAG,
               NOT_IMPLEMENTED,
               FATAL_ERROR,
               OUT_OF_MEMORY,
               ERROR_READ_FILE,
               ERROR_WRITE_FILE,
               MODIFIED_ABORT_ANYWAY,
               VIEW_ONLY,
               FILE_DOESN_T_EXIST,
               FILE_EXISTS_OVERWRITE,
               NO_SUCH_MACRO,
               MACRO_EXEC_NESTING_TO_DEEP,
               MACRO_INCLUDE_NESTING_TO_DEEP,
               INVALID_VARIABLE_NAME,
               INVALID_HEX_VALUE,
               STRING_TOO_LONG,
               LINE_TOO_LONG,
               INVALID_HISTORY_ENTRY,
               EOF_IN_REDIRECTED_INPUT,
               INVALID_RADIX,
               INVALID_MACRO_ENTRY,
               INVALID_SYNTAX_ENTRY,
               TOO_MANY_FILETYPES,
               TOO_MANY_FILE_EXTS,
               TOO_MANY_KEYWORDS,
               INVALID_NULL_NAME,
               FILE_TO_LARGE,
               ERROR_BACKUP_FILE,
               KEYBOARD_FIFO_OVERFLOW,
               ERROR_CREATE_FILE,
               FILE_IS_READ_ONLY,
               COULDN_T_SET_ACCESS_RIGHTS,
               WINDOW_TOO_SMALL,
               INVALID_PATH_NAME,
               NO_CORRESPONDING_BRACKET,
#if (ACT_SERVER == SERVER_VT_100)
               ESCAPE_SEQUENCE_ERROR,
#endif
               INVALID_STATUS_ENTRY,
               FILE_SIZE_CHANGED,
               FILE_NOT_READABLE,
               UNKNOWN_ERROR
              };


/************************/
/*  forward references  */
/************************/

static int display_err_message (enum ERR_TYPE err_type, char *comment);
extern int err_message         (enum ERR_TYPE err_type);
extern int err_message_1       (enum ERR_TYPE err_type, char *comment);


/************************/
/*  public variables    */
/************************/


/* Modification History */
/* 15.01.93 - file erzeugt */
/* 27.07.93 - err_message_1 () */
/* 29.08.93 - FILE_IS_READ_ONLY */
/* 30.08.93 - COULDN_T_SET_ACCESS_RIGHTS */
/* 28.09.93 - WINDOW_TO_SMALL */
/* 07.11.93 - INVALID_PATH_NAME */
/* 15.12.93 - Rechtschreibfehler korrigiert */
/* 20.12.93 - ESCAPE_SEQUENCE_ERROR */
/* 21.05.94 - INVALID_STATUS_ENTRY */
/* 14.06.94 - LINE_TOO_LONG */
/* 02.10.94 - NOT_IMPLEMENTED */
/* 27.11.95 - MACRO_INCLUDE_NESTING_TO_DEEP */
/* 10.12.95 - FILE_SIZE_CHANGED */
/* 04.02.99 - FILE_NOT_READABLE */
/* 30.03.03 - error messages for syntax highlighting */
