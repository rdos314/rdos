/*      mon_outp.h                          14.02.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for mon_outp.c (function prototypes)
/
*/

/*****************************************/
/*                                       */
/* static functions (for local use only) */
/*                                       */
/*****************************************/

static void loc_scroll_screen (void);
static void loc_carriage_return (void);
static void loc_line_feed (void);
static void loc_new_line (void);
static void loc_cursor_tab   (void);
static void loc_invert_cursor (int mode);

static int  loc_init_mon_outp (void);
static void loc_test_screen (void);
static void loc_set_attribute (byte attr);

static void loc_clear_screen (void);
static void loc_clear_to_eol (void);
static void loc_cursor_home  (void);
static void loc_set_cursor_to (int line, int column);
static void loc_cursor_left  (void);
static void loc_cursor_right (void);
static void loc_cursor_up    (void);
static void loc_cursor_down  (void);
static void loc_out_1_char (int key, int rectangle);
static int  loc_out_string (char *text);

static void translate_1 (int key);
static void translate_2 (int line, int column);
static int  translate_3 (char *text);


/*****************************************/
/*                                       */
/* public functions (for general use)    */
/*                                       */
/*****************************************/

extern int  push_cursor (void);
extern int  pop_cursor  (void);
extern void cursor_off  (void);
extern void cursor_on   (void);
extern void set_grafik_off (int mode);
extern void set_grafik_on  (int mode);

extern int  init_mon_outp (void);
extern void test_screen   (void);
extern void set_normal_mode (void);
extern void set_invers_mode (void);
extern void set_stat_1_mode (void);
extern void set_stat_2_mode (void);
extern void set_comment_mode(void);
extern void set_keyword_mode(void);
extern void set_string_mode (void);

extern void clear_screen (void);
extern void clear_to_eol (int rest_blanks);
extern void clear_line (void);
extern void cursor_home  (void);
extern void set_cursor_to  (int line, int column);
extern void get_cursor_pos (int *line, int *column);
extern void set_wrap_on  (void);
extern void set_wrap_off (void);
extern void cursor_left  (void);
extern void cursor_right (void);
extern void cursor_up    (void);
extern void cursor_down  (void);
extern void out_1_char (int key, int rectangle);
extern int  out_string (char *text);
extern void beep (void);

#if (ACT_SERVER == SERVER_VGA)
extern void set_default_attribute (byte attr);
extern void set_invers_attribute  (byte attr);
extern void set_stat_1_attribute  (byte attr);
extern void set_stat_2_attribute  (byte attr);
extern void set_comment_attribute (byte attr);
extern void set_keyword_attribute (byte attr);
extern void set_string_attribute  (byte attr);
#else
extern void set_default_attribute (char *esc_line);
extern void set_invers_attribute  (char *esc_line);
extern void set_stat_1_attribute  (char *esc_line);
extern void set_stat_2_attribute  (char *esc_line);
extern void set_comment_attribute (char *esc_line);
extern void set_keyword_attribute (char *esc_line);
extern void set_string_attribute  (char *esc_line);
#endif

extern void push_attributes (void);
extern void pop_attributes  (void);
extern int is_comment_active (void);
extern int is_keyword_active (void);
extern int is_string_active  (void);


/*-----------------*/
/* div. konstanten */
/*-----------------*/

#if (ACT_SERVER == SERVER_VGA)
/* hardware-adressen */
   #define VGA_MONO    0xb000    /* PC Raum 163 !! */
   #define VGA_COLOR   0xb800    /* Laptop      !! */
   
#if 0
   /* organisation bildwiederholspeicher */
   struct VGA_SCREEN {
            byte key;   /* LSB */
            byte flag;  /* MSB */
            } vga_screen [80][25];
   
   
      /* organisation of flag byte */
   
        Bit  |  Remark
       ------+---------------------------------------
         7   |  Blink Bit
        6-4  |  Background Colour
         3   |  Highligth Bit
        2-0  |  Foreground Colour (1, 9 = Underlined)
   
#endif
#endif
   
/* memory attributes */
#define UNDER_LINED        0x01
#define HIGH_LIGTHED       0x08
#define BLINKING           0x80

#define HALF_INTENSITY     0x07
#define FULL_INTENSITY     (HALF_INTENSITY + HIGH_LIGHTED)
#define INVERS_1           0x40
#define INVERS_2           0x7f

#define INIT_DEFAULT_ATTRIBUTE  HALF_INTENSITY
#define INIT_INVERS_ATTRIBUTE   (INIT_DEFAULT_ATTRIBUTE << 4)

/* -FF-  */

#if (ACT_SERVER == SERVER_VT_100)

/* some important <esc> sequences */

/* cursor keys */
#define ESC_CURSOR_UP    "\033[A"
#define ESC_CURSOR_DOWN  "\033[B"
#define ESC_CURSOR_RIGHT "\033[C"
#define ESC_CURSOR_LEFT  "\033[D"

/* line and screen commands */
#define ESC_CLEAR_SCREEN   "\033[2J"
#if (ACT_OP_SYSTEM == WIN_32) || (ACT_OP_SYSTEM == RDOS)
#define ESC_CLEAR_TO_EOL   "\033[0K"     /* must be !! */
#else
#define ESC_CLEAR_TO_EOL   "\033[K"      /* fids like  */
#endif
#define ESC_CLEAR_LINE     "\033[2K"
#define ESC_SET_CURSOR_TO  "\033[%d;%dH"
#define ESC_CURSOR_OFF     "\033[?25l"
#define ESC_CURSOR_ON      "\033[?25h"

/* semigraphic (for semigraphic character set,
                see file "history.c": table "semi_grafik" */
#define ESC_SET_GRAFIK_ON_VT100  "\033(0"
#define ESC_SET_GRAFIK_OFF_VT100 "\033(B"
#define ESC_SET_GRAFIK_ON_ANSI   "\033[12m"
#define ESC_SET_GRAFIK_OFF_ANSI  "\033[10m"

/* attributes */
#define ESC_ATTR_DEFAULT    "\033[0m"
#define ESC_ATTR_BOLD       "\033[1m"
#define ESC_ATTR_UNDERLINED "\033[4m"
#define ESC_ATTR_BLINKING   "\033[5m"
#define ESC_ATTR_INVERS     "\033[7m"
#define ESC_ATTR_HIDDEN     "\033[8m"

/* control */
#define ESC_WRAP_ON         "\033[?7h"
#define ESC_WRAP_OFF        "\033[?7l"

#endif

/* -FF-  */

/* Modification History */
/* 20.11.92 - file erzeugt */
/* 23.11.92 - more function prototypes */
/* 24.11.92 - set_top_of_screen () */
/* 27.11.92 - beep () */
/* 28.11.92 - clear_line () */
/* 30.11.92 - adresse vga-memory 0xb000 --> 0xa000 (PC Raum 062) */
/* 21.12.92 - VGA_MONO, VGA_COLOR */
/* 17.06.93 - attribute (vorder- hinter-grund) per macro-file ladbar */
/* 18.06.93 - set_status_mode () */
/* 06.12.93 - GRAFIK_OFF --> mon_outp.c */
/* 27.09.94 - set_comment_mode/_attribute, set_keyword_mode/_attribute */
/* 01.10.94 - is_comment_active(), is_keyword_active() */
/* 04.10.94 - <esc> sequences for vt100 */
/* 06.10.94 - set_grafik_on(mode), _off(mode) */
/* 09.10.94 - clear_to_eol(int rest_blanks) */
/* 14.10.94 - <esc> sequences as define constants in "mon_outp.h" */
/* 22.02.95 - ESC_WRAP_ON, ESC_WRAP_OFF */
/* 26.02.95 - set_wrap_on, _off */
/* 14.02.04 - out_1_char (int key, int rectangle) */
