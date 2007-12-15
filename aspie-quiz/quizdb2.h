
#define DX_AS       1
#define DX_TS       2
#define DX_ADD      3
#define SELF_AS     4
#define SELF_TS     5
#define SELF_ADD    6
#define NO_DX       7

struct TQuizRow
{
    long ID;
    char Diagnos;
    int  BirthYear;
    char Gender;
    char Referer[100];
    long AsResult;
    long NtResult;
    char Quiz[100];
	int GroupResult[14];
};
