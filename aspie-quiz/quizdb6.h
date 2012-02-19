
struct TQuizRow
{
    long ID;
    long LsbTime;
    long MsbTime;
    int  BirthYear;
	char Gender;
	int Ancestry;
	char Hair;
	char Eye;
    char Lang;
	char Autism;
	char Aspie;
	char ADHD;
	char Schizophrenia;
	long AsResult;
	long NtResult;
	char Quiz[200];
	char GroupResult[ACTIVE_GROUP_COUNT];
};

