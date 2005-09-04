/*      kb_input.h                          24.02.95       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    header file for kb_input.c (function prototypes)
/
*/

#if 0

   Dieses Modul liest Daten von der Tastatur und generiert aus den
   unterschiedlichen Character-Sequenzen einen einheitlichen Output
   in Form eines einzelnen Integer-Wertes.

   "Normale" Tasten (ASCII 0x00 ... 0x7f) werden 1:1 weitergeleitet,
   Spezial-Tasten werden umgesetzt.

   Beispiel: Function Key "Insert"

             - PC MF-2 :  0x00 0x52    ==>  -174   (Formel: 2. Wert - 256)
             - VT 220  :  <esc> [ 2 ~  ==>  -174   (Umsetzung mit Tabelle)

   VT100/220-Tasten, die der PC nicht hat, werden als "invalid" gesendet.

#endif

/* -FF-  */
/*      EOF            -1       is already defined */
#define INVALID        -2    /* found unknown key */
#define KEY_DO_NOTHING -4    /* after eof in redirected file */
#define KEY_TIMEOUT    -5    /* for unix with slow vt-100-terminals */

#define KEY_RUBOUT     0x7f

#define COMM_STT 0x1001   /* avoid collision with KEY table in kb_input.h ! */
#define SEQU_MM  0x1002
#define SEQU_EM  0x1003



/* Bezeichnung     Wert        <esc> sequence (vt100/vt220) */

#define KEY_F1     -197          /*     --               */
#define KEY_F2     -196          /*     --               */
#define KEY_F3     -195          /*     --               */
#define KEY_F4     -194          /*     --               */
#define KEY_F5     -193          /*     --               */

#define KEY_F6     -192          /*    <esc> [ 1 7 ~     */
#define KEY_F7     -191          /*    <esc> [ 1 8 ~     */
#define KEY_F8     -190          /*    <esc> [ 1 9 ~     */
#define KEY_F9     -189          /*    <esc> [ 2 0 ~     */
#define KEY_F10    -188          /*    <esc> [ 2 1 ~     */

#if 0
#define KEY_F11    -123          /*    <esc> [ 2 3 ~  / bzw. <esc>  */
#else
#define KEY_F11    0x1b          /*    <F11> ==> <esc>   */
#endif

#define KEY_F12    -122          /*    <esc> [ 2 4 ~     */

#define SHIFT_F1   -172          /*     --               */
#define SHIFT_F2   -171          /*     --               */
#define SHIFT_F3   -170          /*     --               */
#define SHIFT_F4   -169          /*     --               */
#define SHIFT_F5   -168          /*     --               */
#define SHIFT_F6   -167          /*     --               */
#define SHIFT_F7   -166          /*     --               */
#define SHIFT_F8   -165          /*     --               */
#define SHIFT_F9   -164          /*     --               */
#define SHIFT_F10  -163          /*     --               */

#define CTRL_F1    -162          /*     --               */
#define CTRL_F2    -161          /*     --               */
#define CTRL_F3    -160          /*     --               */
#define CTRL_F4    -159          /*     --               */
#define CTRL_F5    -158          /*     --               */
#define CTRL_F6    -157          /*     --               */
#define CTRL_F7    -156          /*     --               */
#define CTRL_F8    -155          /*     --               */
#define CTRL_F9    -154          /*     --               */
#define CTRL_F10   -153          /*     --               */

#define ALT_F1     -152          /*     --               */
#define ALT_F2     -151          /*     --               */
#define ALT_F3     -150          /*     --               */
#define ALT_F4     -149          /*     --               */
#define ALT_F5     -148          /*     --               */
#define ALT_F6     -147          /*     --               */
#define ALT_F7     -146          /*     --               */
#define ALT_F8     -145          /*     --               */
#define ALT_F9     -144          /*     --               */
#define ALT_F10    -143          /*     --               */

#define CTRL_PGUP  -124          /*     --               */
#define CTRL_HOME  -137          /*     --               */
#define CTRL_PGDN  -138          /*     --               */
#define CTRL_END   -139          /*     --               */
#define CTRL_RIGHT -140          /*     --               */
#define CTRL_LEFT  -141          /*     --               */

#define KEY_UP     -184          /*    <esc> [ A         */
#define KEY_DOWN   -176          /*    <esc> [ B         */
#define KEY_RIGHT  -179          /*    <esc> [ C         */
#define KEY_LEFT   -181          /*    <esc> [ D         */

/* not in AEDIT */

#define CTRL_2     -253          /*     --               */

#define ALT_1      -136          /*     --               */
#define ALT_2      -135          /*     --               */
#define ALT_3      -134          /*     --               */
#define ALT_4      -133          /*     --               */
#define ALT_5      -132          /*     --               */
#define ALT_6      -131          /*     --               */
#define ALT_7      -130          /*     --               */
#define ALT_8      -129          /*     --               */
#define ALT_9      -128          /*     --               */
#define ALT_0      -127          /*     --               */
#define ALT_MIN    -126          /*     --               */
#define ALT_EQU    -125          /*     --               */

#define ALT_A      -226          /*     --               */
#define ALT_B      -208          /*     --               */
#define ALT_C      -210          /*     --               */
#define ALT_D      -224          /*     --               */
#define ALT_E      -238          /*     --               */
#define ALT_F      -223          /*     --               */
#define ALT_G      -222          /*     --               */
#define ALT_H      -221          /*     --               */
#define ALT_I      -233          /*     --               */
#define ALT_J      -220          /*     --               */
#define ALT_K      -219          /*     --               */
#define ALT_L      -218          /*     --               */
#define ALT_M      -206          /*     --               */
#define ALT_N      -207          /*     --               */
#define ALT_O      -232          /*     --               */
#define ALT_P      -231          /*     --               */
#define ALT_Q      -240          /*     --               */
#define ALT_R      -237          /*     --               */
#define ALT_S      -225          /*     --               */
#define ALT_T      -236          /*     --               */
#define ALT_U      -234          /*     --               */
#define ALT_V      -209          /*     --               */
#define ALT_W      -239          /*     --               */
#define ALT_X      -211          /*     --               */
#define ALT_Y      -235          /*     --               */
#define ALT_Z      -212          /*     --               */

/* not on VT 100 (but VT 220) */

#define KEY_HOME   -185          /*    <esc> [ 1 ~       */  /* FIND        */
#define KEY_INS    -174          /*    <esc> [ 2 ~       */  /* INSERT HERE */
#define KEY_DEL    -173          /*    <esc> [ 3 ~       */  /* REMOVE      */
#define KEY_END    -177          /*    <esc> [ 4 ~       */  /* SELECT      */
#define KEY_PGUP   -183          /*    <esc> [ 5 ~       */  /* PREV        */
#define KEY_PGDN   -175          /*    <esc> [ 6 ~       */  /* NEXT        */
/* #define KEY_END    -177 */    /*    <esc> [ 7 ~       */  /* END         */
/* #define KEY_HOME   -185 */    /*    <esc> [ 8 ~       */  /* HOME        */

/* not on pc-keyboards */

#define KEY_F13    CTRL_LEFT     /*    <esc> [ 2 5 ~     */
#define KEY_F14    CTRL_RIGHT    /*    <esc> [ 2 6 ~     */
#define KEY_HELP   KEY_F1        /*    <esc> [ 2 8 ~     */
#define KEY_DO     ALT_F1        /*    <esc> [ 2 9 ~     */

#define KEY_F17    INVALID       /*    <esc> [ 3 1 ~     */
#define KEY_F18    INVALID       /*    <esc> [ 3 2 ~     */
#define KEY_F19    INVALID       /*    <esc> [ 3 3 ~     */
#define KEY_F20    INVALID       /*    <esc> [ 3 4 ~     */

#define KEY_PF1    KEY_F3        /*    <esc> O P         */
#define KEY_PF2    KEY_F4        /*    <esc> O Q         */
#define KEY_PF3    KEY_F5        /*    <esc> O R         */
#define KEY_PF4    KEY_F6        /*    <esc> O S         */

/* -FF-  */

/* function prototypes */
typedef unsigned char uchar;

/* global */
extern int check_input_redirection (void);
extern void sleep_msec      (int delay_time);

extern void ctrlchandler    (int sig);
extern int  ctrlc_active    (void);

extern void set_key_fifo    (int key);
extern void set_string_buff (char *string, int str_len);

extern int  get_1_key       (int check_macro);
extern int  loc_get_1_key   (void);

extern int  key_pressed     (void);
extern int  loc_key_pressed (void);
extern void avoid_hanging_display(void);

extern void kb_echo_off     (void);
extern void kb_echo_on      (void);

/* local */
static int  get_1_byte (void);
static int  loc_get_1_int (void);
static int  get_1_byte_with_timeout  (int msec);
static void setraw (uchar c_num, uchar t_msec10);
static void setblock (int fd, int on );
static void key_brk (int sig);


/* -FF-  */

/* Modification History */
/* 20.11.92 - file erzeugt */
/* 04.12.92 - keyboard_echo on/off */
/* 22.12.92 - pause_msec () */
/* 30.12.92 - ALT_F1 - ALT_F10 */
/* 01.01.93 - loc_get_1_key () */
/* 02.01.93 - SHIFT_F1 - SHIFT_F10 */
/* 03.01.93 - loc_get_1_key () public (for mbedit.c) */
/* 05.01.93 - more CTRL_keys (Home, End, PgUp, PgDn, Leftm Right) */
/* 07.12.93 - ctrlchandler (int sig) */
/* 16.05.94 - KEY_RUBOUT */
/* 26.09.94 - <esc> [ 7 ~, <esc> [ 8 ~ */
/* 21.11.94 - WRAP_ON/WRAP_OFF */
/* 22.02.95 - WRAP_ON/WRAP_OFF in mon_outp.h */
/* 23.02.95 - KEY_F11 --> <esc> */
/* 24.02.95 - key_break (int sig) */
