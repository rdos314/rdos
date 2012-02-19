
struct TQuizRow
{
    long ID;
    long LsbTime;
    long MsbTime;
    int  BirthYear;
    int  BirthMonth;
	char Gender;
    char Lang;
	char Autism;
	char Aspie;
	char ADHD;
	long AsResult;
	long NtResult;
	char Quiz[200];
	char GroupResult[ACTIVE_GROUP_COUNT];
};

