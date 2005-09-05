/*      mouser.h                                 12.12.93       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for mousec.c (function prototypes)
/
*/


/************************/
/* often used macros    */
/************************/


/************************/
/* often used defines   */
/************************/


/************************/
/*  enums / structs     */
/************************/

struct MOUSE_STAT
   {
      int EvFlags;
      int ButState;
      int x_pix;
      int y_pix;
      int col;     /* = x_pix / 8 */
      int row;     /* = y_pix / 8 */
   };


/************************/
/*  forward references  */
/************************/

extern int  MouStartup   (int columns, int rows);
extern void MouEnd       (void);
extern void MouSetMoveArea (char x1, char y1, char x2, char y2, int window_flag);
extern void MouShowMouse (void);
extern void MouHideMouse (void);

extern void update_mouse(void);
extern int mouse_event (void);
extern int mouse_event_handler_c (int repeat);


/* local */
static void MouMovePtr(int col, int row );


/************************/
/*  public variables    */
/************************/


/* Modification History */
/* 08.12.93 - file erzeugt */
/* 10.12.93 - struct MOUSE_STAT */
