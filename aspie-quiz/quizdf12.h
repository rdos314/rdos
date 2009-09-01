
struct TQuizRow
{
    long ID;
    long userid;
    int  BirthYear;
    int  BirthMonth;
	char Gender;
	int Country;
	int Ancestry;
	char Aspie;
	char ADHD;
	char OCD;
	char Social;
	char Referer[100];
	long AsResult;
	long NtResult;
	long EqResult;
	char Quiz[250];
	char GroupResult[ACTIVE_GROUP_COUNT];
	char DxResult[DX_COUNT];
};
