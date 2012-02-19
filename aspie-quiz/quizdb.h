
struct TQuizRow
{
    long ID;
    long LsbTime;
    long MsbTime;
    char Diagnos;
    char Age;
    char Gender;
    long ResultNow;
    long ResultBefore;
    char Before[100];
    char Now[100];
	char GroupResult[ACTIVE_GROUP_COUNT];
};
