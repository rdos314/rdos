
struct TRadLog
{
	int valid;
	int t;
	int ref;
	int taux;
	int motor;
	int light;
};

struct TLog
{
	long LsbTime;
	long MsbTime;
	int light;
	int tout;
	int ttank;
	int tpanna;
	int epvalve;
	int vpvalve;
	int circvalve;
	int epon;
	int vpon;
	int circon;
	TRadLog rad[7];
};
