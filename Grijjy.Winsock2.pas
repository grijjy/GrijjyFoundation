unit Grijjy.Winsock2;

{ Missing Winsock2 interfaces for IOCP and other things }

{$I Grijjy.inc}

interface

uses
  Winsock2,
  Windows,
  System.SysUtils;

const
  WINSOCK2_DLL = 'WS2_32.DLL';
  WSHIP6_DLL = 'WSHIP6.DLL';

const
  IPHLPAPI_DLL = 'IPHLPAPI.dll';

  { TCP states }
  TCP_STATES = 12;
  TCP_STATE: array[1..TCP_STATES] of String = (
    'CLOSED',
    'LISTEN',
    'SYN-SENT',
    'SYN-RECEIVED',
    'ESTABLISHED',
    'FIN-WAIT-1',
    'FIN-WAIT-2',
    'CLOSE-WAIT',
    'CLOSING',
    'LAST-ACK',
    'TIME-WAIT',
    'delete TCB');

const
  TF_DISCONNECT         = $01;
  TF_REUSE_SOCKET       = $02;
  TF_WRITE_BEHIND       = $04;
  TF_USE_DEFAULT_WORKER = $00;
  TF_USE_SYSTEM_THREAD  = $10;
  TF_USE_KERNEL_APC     = $20;

type
  PPAddrInfoW = ^PAddrInfoW;
  PAddrInfoW = ^ADDRINFOW;
  ADDRINFOW = record
    ai_flags: Integer;
    ai_family: Integer;
    ai_socktype: Integer;
    ai_protocol: Integer;
    ai_addrlen: size_t;
    ai_canonname: PWideChar;
    ai_addr: PSockAddr;
    ai_next: PAddrInfoW;
  end;
  TAddrInfoW = ADDRINFOW;
  LPADDRINFOW = PAddrInfoW;

type
  LPFN_BIND = function(const ASocket: TSocket; const AName: PSockAddr; const ANameLength: Integer): Integer; stdcall;
  LPFN_WSAIOCTL = function(const ASocket: TSocket; dwIoControlCode: DWORD; lpvInBuffer: Pointer; cbInBuffer: DWORD; lpvOutBuffer: Pointer; cbOutBuffer: DWORD;
    lpcbBytesReturned: LPDWORD; AOverlapped: Pointer; lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE): Integer; stdcall;
  LPFN_ACCEPTEX = function(AListenSocket, AAcceptSocket: TSocket; lpOutputBuffer: Pointer; dwReceiveDataLength, dwLocalAddressLength,
    dwRemoteAddressLength: DWORD; var lpdwBytesReceived: DWORD; lpOverlapped: POverlapped): BOOL; stdcall;
  LPFN_GETACCEPTEXSOCKADDRS = procedure(lpOutputBuffer: Pointer;
    dwReceiveDataLength, dwLocalAddressLength, dwRemoteAddressLength: DWORD;
    var LocalSockaddr: TSockAddr; var LocalSockaddrLength: Integer;
    var RemoteSockaddr: TSockAddr; var RemoteSockaddrLength: Integer); stdcall;
  LPFN_CONNECTEX = function(const ASocket: TSocket; const AName: PSockAddr; const ANameLength: Integer; lpSendBuffer: Pointer;
    dwSendDataLength: DWORD; var lpdwBytesSent: DWORD; lpOverlapped: LPWSAOVERLAPPED): BOOL; stdcall;
  LPFN_DISCONNECTEX = function(const ASocket: TSocket; AOverlapped: Pointer; const dwFlags: DWORD; const dwReserved: DWORD): BOOL; stdcall;

type
  LPFN_GETADDRINFOW = function(NodeName: PWideChar; ServiceName: PWideChar; Hints: PaddrinfoW; ppResult: PPAddrInfoW): Integer; stdcall;
  LPFN_GETNAMEINFOW = function(sa: PSockAddr; salen: DWORD; host: PWideChar; hostlen: DWORD; serv: PWideChar; servlen: DWORD; flags: Integer): Integer; stdcall;
  LPFN_FREEADDRINFOW = procedure(ai: PaddrinfoW); stdcall;

const
  WSAID_ACCEPTEX: TGuid = (D1:$b5367df1;D2:$cbac;D3:$11cf;D4:($95,$ca,$00,$80,$5f,$48,$a1,$92));
  WSAID_CONNECTEX: TGuid = (D1:$25a207b9;D2:$ddf3;D3:$4660;D4:($8e,$e9,$76,$e5,$8c,$74,$06,$3e));
  WSAID_DISCONNECTEX: TGuid = (D1:$7fda2e11;D2:$8630;D3:$436f;D4:($a0,$31,$f5,$36,$a6,$ee,$c1,$57));
  WSAID_GETACCEPTEXSOCKADDRS: TGuid = (D1:$b5367df2;D2:$cbac;D3:$11cf;D4:($95,$ca,$00,$80,$5f,$48,$a1,$92));

type
  TCP_TABLE_CLASS = Integer;

  TMibTcpRowOwnerPid = packed record
    dwState: DWORD;
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
    dwRemoteAddr: DWORD;
    dwRemotePort: DWORD;
    dwOwningPid: DWORD;
  end;
  PMibTcpRowOwnerPid = ^TMibTcpRowOwnerPid;

  PMIB_TCPTABLE_OWNER_PID = ^MIB_TCPTABLE_OWNER_PID;
  MIB_TCPTABLE_OWNER_PID = packed record
    dwNumEntries: DWORD;
    table: array [0..0] of TMibTcpRowOwnerPid;
  end;

type
  LPFN_GetExtendedTcpTable = function(pTcpTable: Pointer; dwSize: PDWORD; bOrder: BOOL; lAf: ULONG; TableClass: TCP_TABLE_CLASS; Reserved: ULONG): DWord; stdcall;

  { Missing Winsock2 }
  function Init_Winsock: DWORD;
  procedure Finalize_Winsock;

  { Helpers }
  function IPV4ToString(const AValue: Integer): String;

  { NetStat }
  function EnumerateTCPConnections(out ATcpTable: PMIB_TCPTABLE_OWNER_PID): Boolean;
  procedure grNetstat;

var
  bind: LPFN_BIND = nil;
  WSAIoctl: LPFN_WSAIOCTL = nil;
  AcceptEx: LPFN_ACCEPTEX = nil;
  GetAcceptExSockAddrs: LPFN_GETACCEPTEXSOCKADDRS = nil;
  ConnectEx: LPFN_CONNECTEX = nil;
  DisconnectEx: LPFN_DISCONNECTEX = nil;

var
  GetAddrInfo: LPFN_GETADDRINFOW = nil;
  GetNameInfo: LPFN_GETNAMEINFOW = nil;
  FreeAddrInfo: LPFN_FREEADDRINFOW = nil;

var
  HandleIPHLPAPI: THandle = 0;
  GetExtendedTcpTable: LPFN_GetExtendedTcpTable = nil;

implementation

var
  HandleWinsockDLL: THandle = 0;
  HandleWShipDLL: THandle = 0;

function GetAddress(const AName: String): Pointer; inline; overload;
begin
  Result := GetProcAddress(HandleWinsockDLL, PWideChar(AName));
end;

function GetAddress(ASocket: TSocket; const AName: String; const AGuid: TGUID): Pointer; inline; overload;
var
  BytesSend: DWORD;
begin
  if WSAIoctl(ASocket, SIO_GET_EXTENSION_FUNCTION_POINTER, @AGuid, DWORD(SizeOf(TGuid)),
    @Result, DWORD(SizeOf(FARPROC)), PDWORD(@BytesSend), nil, nil) <> 0 then
    Result := nil;
end;

function Overload_AcceptEx(AListenSocket, AAcceptSocket: TSocket;
  lpOutputBuffer: Pointer; dwReceiveDataLength, dwLocalAddressLength,
  dwRemoteAddressLength: DWORD; var lpdwBytesReceived: DWORD;
  lpOverlapped: POverlapped): BOOL; stdcall;
begin
  @GetAcceptExSockAddrs := GetAddress(AListenSocket, 'GetAcceptExSockaddrs', WSAID_GETACCEPTEXSOCKADDRS);
  @AcceptEx := GetAddress(AListenSocket, 'AcceptEx', WSAID_ACCEPTEX);
  if @AcceptEx <> nil then
    Result := AcceptEx(AListenSocket, AAcceptSocket, lpOutputBuffer, dwReceiveDataLength,
      dwLocalAddressLength, dwRemoteAddressLength, lpdwBytesReceived, lpOverlapped)
  else
    Result := False;
end;

function Overload_ConnectEx(const ASocket: TSocket; const AName: PSockAddr; const ANameLength: Integer; lpSendBuffer: Pointer;
  dwSendDataLength: DWORD; var lpdwBytesSent: DWORD; lpOverlapped: LPWSAOVERLAPPED): BOOL;  stdcall;
begin
  @ConnectEx := GetAddress(ASocket, 'ConnectEx', WSAID_CONNECTEX);
  if @ConnectEx <> nil then
    Result := ConnectEx(ASocket, AName, ANameLength, lpSendBuffer, dwSendDataLength, lpdwBytesSent, lpOverlapped)
  else
    Result := False;
end;

function Overload_DisconnectEx(const ASocket: TSocket; AOverlapped: Pointer; const dwFlags: DWord; const dwReserved: DWORD): BOOL;  stdcall;
begin
  @DisconnectEx := GetAddress(ASocket, 'DisconnectEx', WSAID_DISCONNECTEX);
  if @DisconnectEx <> nil then
    Result := DisconnectEx(ASocket, AOverlapped, dwFlags, dwReserved)
  else
    Result := False;
end;

procedure Init_Overloads;
begin
  bind := GetAddress('bind');
  AcceptEx := Overload_AcceptEx;
  ConnectEx := Overload_ConnectEx;
  DisconnectEx := Overload_DisconnectEx;
  WSAIoctl := GetAddress('WSAIoctl');
end;

procedure Init_AddrInfo;
var
  _GetAddrInfo: LPFN_GETADDRINFOW;
  _GetNameInfo: LPFN_GETNAMEINFOW;
  _FreeAddrInfo: LPFN_FREEADDRINFOW;
  Handle: THandle;
begin
  Handle := HandleWinsockDLL;
  _GetAddrInfo := GetProcAddress(Handle, 'GetAddrInfoW');
  if not Assigned(_GetAddrInfo) then
  begin
    HandleWShipDLL := SafeLoadLibrary(Wship6_dll);
    Handle := HandleWShipDLL;
    _GetAddrInfo := GetProcAddress(Handle, 'GetAddrInfoW');
  end;
  if Assigned(_GetAddrInfo) then
  begin
    _GetNameInfo := GetProcAddress(Handle, 'GetNameInfoW');
    _FreeAddrInfo := GetProcAddress(Handle, 'FreeAddrInfoW');
    if Assigned(_FreeAddrInfo) then
    begin
      GetAddrInfo := _GetAddrInfo;
      GetNameInfo := _GetNameInfo;
      FreeAddrInfo := _FreeAddrInfo;
    end;
  end;
end;

function Init_Winsock: DWORD;
var
  LData: TWSAData;
begin
  Result := 0;
  if HandleWinsockDLL = 0 then
  begin
    HandleWinsockDLL := LoadLibrary(WINSOCK2_DLL);
    if HandleWinsockDLL <> 0 then
    begin
      Init_Overloads;
      if WSAStartup($202, LData) = 0 then
      begin
        Init_AddrInfo;
        Exit;
      end
      else
      begin
        FreeLibrary(HandleWinsockDLL);
        HandleWinsockDLL := 0;
      end
    end
    else
  end;
  Result := GetLastError;
end;

procedure Finalize_Winsock;
begin
  if HandleWShipDLL <> 0 then
  begin
    FreeLibrary(HandleWShipDLL);
    HandleWShipDLL := 0;
  end;
  if HandleWinsockDLL <> 0 then
  begin
    WSACleanup;
    FreeLibrary(HandleWinsockDLL);
    HandleWinsockDLL := 0;
  end;
end;

function IPV4ToString(const AValue: Integer): String;
var
  x1, x2: Word;
  y1, y2: Byte;
begin
  Result := '';
  x1 := AValue shr 16;
  x2 := AValue and $FFFF;
  y1 := x2 mod $100;
  y2 := x2 div $100;
  Result := IntToStr(y1) + '.' + IntToStr(y2) + '.';
  y1 := x1 mod $100;
  y2 := x1 div $100;
  Result := Result + IntToStr(y1) + '.' + IntToStr(y2);
end;

function EnumerateTCPConnections(out ATcpTable: PMIB_TCPTABLE_OWNER_PID): Boolean;
const
  TCP_TABLE_OWNER_PID_ALL = 5;
var
  Size: DWORD;
  LastError: Integer;
begin
  Result := False;
  if @GetExtendedTcpTable = nil then
  begin
    HandleIPHLPAPI := LoadLibrary(IPHLPAPI_DLL);
    if HandleIPHLPAPI <> 0 then
      GetExtendedTcpTable := GetProcAddress(HandleIPHLPAPI, 'GetExtendedTcpTable');
  end;
  if @GetExtendedTcpTable <> nil then
  begin
    Size := 0;
    if GetExtendedTcpTable(nil, @Size, False, AF_INET, TCP_TABLE_OWNER_PID_ALL, 0) = ERROR_INSUFFICIENT_BUFFER then
    begin
      GetMem(ATcpTable, Size);
      if GetExtendedTcpTable(ATcpTable, @Size, TRUE, AF_INET, TCP_TABLE_OWNER_PID_ALL, 0) <> NO_ERROR then
      begin
        LastError := GetLastError;
        Writeln(Format('Error! GetExtendedTcpTable %d %s', [LastError, SysErrorMessage(LastError)]));
      end
      else
        Result := True;
    end;
  end
  else
  begin
    LastError := GetLastError;
    Writeln(Format('Error! GetProcAddress %d %s', [LastError, SysErrorMessage(LastError)]));
  end;
end;

procedure grNetstat;
var
  TcpTable: PMIB_TCPTABLE_OWNER_PID;
  I: Integer;
  Count: array[1..TCP_STATES] of Integer;
begin
  ZeroMemory(@Count, SizeOf(Count));
  if EnumerateTCPConnections(TcpTable) then
  begin
    try
      Writeln(Format('%-16s %-6s %-16s %-6s %s',['Local IP','Port','Remote IP','Port','Status']));
      for I := 0 to TcpTable.dwNumEntries - 1 do
      begin
        Writeln(Format('%-16s %-6d %-16s %-6d %s',[
          IPV4ToString(TcpTable.Table[I].dwLocalAddr),
          Swap(TcpTable.Table[I].dwLocalPort),
          IPV4ToString(TcpTable.Table[I].dwRemoteAddr),
          Swap(TcpTable.Table[I].dwRemotePort),
          TCP_STATE[TcpTable.Table[I].dwState]]));
        Inc(Count[TcpTable.Table[I].dwState]);
      end;
    finally
      FreeMem(TcpTable);
    end;
    Writeln;
    for I := 1 to TCP_STATES do
      Writeln(Format('%16s %s',[TCP_STATE[I] + ' = ',IntToStr(Count[I])]));
  end;
  Readln;
end;

initialization
  Init_Winsock;

finalization
  Finalize_Winsock;

end.
