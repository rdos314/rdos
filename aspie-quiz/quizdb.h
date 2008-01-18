#define DDX_AS       2
#define DDX_ADD      3
#define DDX_UNKNOWN  6
#define DDX_REFERER  7

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
	char GroupResult[ACTIVE_GROUP_COUNT];
};
