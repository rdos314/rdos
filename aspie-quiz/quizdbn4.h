
struct TQuizRow
{
    long ID;
    long userid;
    int  BirthYear;
    int  BirthMonth;
	 char Gender;
	 int Country;
	 int Ancestry;
	 char Lang;
	char Aspie;
	char ADHD;
	char Dyslexia;
	char OCD;
	char Bipolar;
	char Social;
	int PredAs;
	int PredAdd;
	int PredDyslexia;
	int PredOcd;
	int PredSocial;
	char Referer[100];
	long AsResult;
	long NtResult;
	char Quiz[250];
	char GroupResult[ACTIVE_GROUP_COUNT];
	char DxResult[DX_COUNT];
};
