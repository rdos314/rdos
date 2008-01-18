
struct TQuizRow
{
    long ID;
    int  BirthYear;
    char Gender;
    char Autism;
    char Aspie;
    char ADHD;
    char IQ;
    char Referer[100];
    long AsResult;
    long NtResult;
    long DdResult;
    long IqResult;
    char IqArr[18];
    char Quiz[200];
	char GroupResult[ACTIVE_GROUP_COUNT];
};
