
struct TQuizRow
{
    long ID;
    long LsbTime;
    long MsbTime;
    int  BirthYear;
	char Gender;
	char Hair;
	char Eye;
    char Lang;
	char Autism;
	char Aspie;
	char ADHD;
	char HnSimilar;
	char HnGender;
	long AsResult;
	long NtResult;
	char Quiz[200];
	char GroupResult[ACTIVE_GROUP_COUNT];
	char Stim[50][3];
};

