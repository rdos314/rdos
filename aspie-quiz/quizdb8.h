
struct TQuizRow
{
    long ID;
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
	char Referer[100];
	long AsResult;
	long NtResult;
	char Quiz[200];
	char GroupResult[ACTIVE_GROUP_COUNT];
	char Stim[50][3];
};

