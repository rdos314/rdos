program Test;

uses Rdos;

var	Handle : longint;
	Msg : array [1..16] of char;
	i : integer;
	size : integer;
	ReplyBuf : array [1..16] of char;

begin
        asm
                int 3
        end;

        RdosWaitMilli(100);

		Msg := 'FPC TEST';
		handle := RdosGetLocalMailslot('ipctest');
		size := RdosSendMailslot(handle, @Msg, 8, @ReplyBuf, 16);
		RdosFreeMailslot(handle);

        RdosDefineMailslot('fpc', 16);
		size := RdosReceiveMailslot(@Msg);
		Msg := 'FPC TEST';
		RdosReplyMailslot(@Msg, 8);
end.
