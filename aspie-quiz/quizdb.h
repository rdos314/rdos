#define DX_AS       2
#define DX_ADD      3
#define DX_UNKNOWN  6
#define DX_REFERER  7

struct TQuizRow
{
    long ID;
    long LsbTime;
    long MsbTime;
    char Diagnos;
    char Age;
    char Gender;
    char Referer[100];
    long ResultNow;
    long ResultBefore;
    char Before[100];
    char Now[100];
	int GroupResult[8];
};
