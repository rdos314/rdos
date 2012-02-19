
struct TQuizRow
{
    long ID;
    long LsbTime;
    long MsbTime;
    int  BirthYear;
    char Gender;
    char Autism;
    char Aspie;
    char ADHD;
    char IQ;
    long AsResult;
    long NtResult;
    long DdResult;
    long IqResult;
    char IqArr[18];
    char Quiz[200];
	char GroupResult[ACTIVE_GROUP_COUNT];
};
