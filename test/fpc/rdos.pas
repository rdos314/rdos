unit Rdos;

interface

procedure RdosWaitMilli(ms : Integer);

function RdosSetCurDrive(Drive : integer) : boolean;
function RdosGetCurDrive : integer;
function RdosSetCurDir(PathName : AnsiString) : boolean;
function RdosGetCurDir(Drive : Integer) : AnsiString;
function RdosMakeDir(PathName : AnsiString) : boolean;
function RdosRemoveDir(PathName : AnsiString) : boolean;
function RdosRenameFile(OldPath : AnsiString; NewPath : AnsiString) : boolean;
function RdosDeleteFile(PathName : AnsiString) : boolean;
function RdosGetFileAttribute(PathName : AnsiString; var Attribute : integer) : boolean;
function RdosSetFileAttribute(PathName : AnsiString; Attribute : integer) : boolean;
function RdosOpenDir(PathName : AnsiString) : longint;
procedure RdosCloseDir(Handle : longint);
function RdosReadDir(Handle : longint; Entry : integer; Name : AnsiString; var FileSize : longint; var Attribute : integer; var TimeDate : Int64) : boolean;

function RdosGetLocalMailslot(const MailslotName : AnsiString) : longint;
function RdosGetRemoteMailslot(Ip : longint; const MailslotName : AnsiString) : longint;
procedure RdosFreeMailslot(Handle : longint);
function RdosSendMailslot(Handle : longint; Msg : pointer; Size : integer; ReplyBuf : pointer; MaxReplySize : integer) : integer;
procedure RdosDefineMailslot(const MailslotName : AnsiString; MaxMsgSize : integer);
function RdosReceiveMailslot(Msg : pointer) : integer;
procedure RdosReplyMailslot(Msg : pointer; Size : integer);

implementation

const
	wait_milli_nr = 25;
	get_local_mailslot_nr = 37;
	get_remote_mailslot_nr = 38;
	free_mailslot_nr = 39;
	send_mailslot_nr = 40;
	define_mailslot_nr = 41;
	receive_mailslot_nr = 42;
	reply_mailslot_nr = 43;

const
	IPC_HANDLE_BIAS = $7B5A0000;

procedure RdosWaitMilli(ms : Integer); assembler;
asm
	mov eax,ms
	db 0Fh
	db 0Bh
	db 0D7h
	dd wait_milli_nr
	nop
end;

function RdosGetLocalMailslot(const MailslotName : AnsiString) : longint; assembler;
asm
	lea edi,MailslotName
	mov edi,[edi]
	or edi,edi
	jz @failed
	db 0Fh
	db 0Bh
	db 0D7h
	dd get_local_mailslot_nr
	nop
	jc @failed
	movzx eax,bx
	or eax,IPC_HANDLE_BIAS		
	jmp @done
@failed:
	xor eax,eax
@done:
end;

function RdosGetRemoteMailslot(Ip : longint; const MailslotName : AnsiString) : longint; assembler;
asm
	lea edi,MailslotName
	mov edi,[edi]
	or edi,edi
	jz @failed
	mov edx,Ip
	db 0Fh
	db 0Bh
	db 0D7h
	dd get_remote_mailslot_nr
	nop
	jc @failed
	movzx eax,bx
	or eax,IPC_HANDLE_BIAS		
	jmp @done
@failed:
	xor eax,eax
@done:
end;

procedure RdosFreeMailslot(Handle : longint); assembler;
asm
	mov eax,Handle
	mov ebx,eax
	and eax,0FFFF0000h
	cmp eax,IPC_HANDLE_BIAS
	jne @done
	db 0Fh
	db 0Bh
	db 0D7h
	dd free_mailslot_nr
	nop
@done:
end;

function RdosSendMailslot(Handle : longint; Msg : pointer; Size : integer; ReplyBuf : pointer; MaxReplySize : integer) : integer; assembler;
asm
	mov eax,Handle
	mov ebx,eax
	and eax,0FFFF0000h
	cmp eax,IPC_HANDLE_BIAS
	jne @fail
	mov esi,Msg
	mov ecx,Size
	mov edi,ReplyBuf
	mov eax,MaxReplySize
	db 0Fh
	db 0Bh
	db 0D7h
	dd send_mailslot_nr
	nop
	mov eax,ecx
	jmp @done
@fail:
	xor eax,eax
@done:
end;

procedure RdosDefineMailslot(const MailslotName : AnsiString; MaxMsgSize : integer); assembler;
asm
	lea edi,MailslotName
	mov edi,[edi]
	or edi,edi
	jz @failed
	mov ecx,MaxMsgSize
	db 0Fh
	db 0Bh
	db 0D7h
	dd define_mailslot_nr
	nop
@failed:
end;

function RdosReceiveMailslot(Msg : pointer) : integer; assembler;
asm
	mov edi,Msg
	db 0Fh
	db 0Bh
	db 0D7h
	dd receive_mailslot_nr
	nop
	mov eax,ecx
	jmp @done
@fail:
	xor eax,eax
@done:
end;

procedure RdosReplyMailslot(Msg : pointer; Size : integer); assembler;
asm
	mov edi,Msg
	mov ecx,Size
	db 0Fh
	db 0Bh
	db 0D7h
	dd reply_mailslot_nr
	nop
end;

end.
