unit Grijjy.Hooking;

{ Cross-platform function hooking and VMT patching }

interface

{ Tries to hook the code at ACodeAddress and redirect it to AHookAddress.
  Returns True on success or False on failure.

  Example usage:
    HookCode(@TObject.NewInstance, @HookedNewInstance);

  This redirects all call to the TObject.NewInstance method and redirect them
  to the HookedNewInstance routine.

  This kind of hooking will likely succeed on Windows, macOS, iOS Simulator and
  Linux, but is not supported on ARM platforms like iOS and Android. On those
  platforms, use HookVMT instead, }
function HookCode(const ACodeAddress, AHookAddress: Pointer): Boolean;

{ Tries to hook entry AVMTEntry in a Virtual Method Table to point to the
  routine in AHookAddress.
  Returns True on success or False on failure.

  Example usage:
    var
      Entry: Pointer;
    begin
      Entry := Pointer(PByte(TObject) + vmtNewInstance);
      HookVMT(Entry, @HookedObjectNewInstance);
    end;

  Note that, unlike HookCode, you need to call this for EVERY class that you
  want to hook, since each each has its own Virtual Method Table.

  This kind of hooking wil likely succeed on Windows, iOS, Android and Linux,
  but fail on macOS and iOS Siumulator. On those platforms, use HookCode
  instead. }
function HookVMT(const AVMTEntry, AHookAddress: Pointer): Boolean;

implementation

uses
  {$IF Defined(MSWINDOWS)}
  Winapi.Windows;
  {$ELSE}
  Posix.SysMman,
  Posix.Unistd;
  {$ENDIF}

{$IF Defined(CPUX86) or Defined(CPUX64)}
const
  { Size of a "jmp <Displacement>" instruction on Intel platforms (1 byte for
    the instruction mnemonic and 4 bytes for the displacement) }
  SIZE_OF_JUMP = 5;

  { Mnemonic value for the "jmp <Displacement>" opcode. }
  JMP_RELATIVE = $E9;
{$ENDIF}

{$IFNDEF MSWINDOWS}
var
  { Will be set during initialization to the size of memory pages on Posix
    platforms. }
  GPageSize: Integer = 0;
{$ENDIF}

{$IF Defined(MSWINDOWS)}

// Windows

function HookCode(const ACodeAddress, AHookAddress: Pointer): Boolean;
var
  OldProtect: DWORD;
  P: PByte;
  Displacement: Integer;
begin
  { We want to replace the first 5 bytes at ACodeAddress with an assembly
    JMP instruction. We cannot just change executable code since it is located
    in read-only memory pages. We need to change the protection level at
    ACodeAddress so we can read, write and execute at that address.
    This should always succeed on Windows. }
  Result := VirtualProtect(ACodeAddress, SIZE_OF_JUMP, PAGE_EXECUTE_READWRITE, OldProtect);

  if (Result) then
  begin
    { Change the first byte at ACodeAddress with the opcode for a JMP instruction. }
    P := ACodeAddress;
    P^ := JMP_RELATIVE;
    Inc(P);

    { This kind of jump instruction requires a displacement value. That is the
      number of bytes to jump from the location AFTER the JMP instruction. We
      calculate this displacement by taking the difference between the address of
      our hooked function and the original code address (adjusted for the size of
      the jump itself). }
    Displacement := UIntPtr(AHookAddress) - (UIntPtr(ACodeAddress) + SIZE_OF_JUMP);
    PInteger(P)^ := Displacement;

    { Restore protection level. }
    VirtualProtect(ACodeAddress, SIZE_OF_JUMP, OldProtect, OldProtect);
  end;
end;

{$ELSEIF Defined(CPUX86) or Defined(CPUX64)}

// macOS, iOS Simulator, Linux

function HookCode(const ACodeAddress, AHookAddress: Pointer): Boolean;
var
  AlignedCodeAddress: UIntPtr;
  P: PByte;
  Displacement: Integer;
begin
  { This version is similar to HookCode on Windows, except that we need to use
    the "mprotect" API instead of "VirtualProtect". mprotect only works with
    while memory pages, so we must align ACodeAddress to the size of a memory
    page. This page size is retrieved during initialization using the
    "sysconf(_SC_PAGESIZE)" API. }
  AlignedCodeAddress := UIntPtr(ACodeAddress) and (not (GPageSize - 1));

  Result := (mprotect(Pointer(AlignedCodeAddress), GPageSize, PROT_READ or PROT_WRITE or PROT_EXEC) = 0);

  if (Result) then
  begin
    P := ACodeAddress;
    P^ := JMP_RELATIVE;
    Inc(P);

    Displacement := UIntPtr(AHookAddress) - (UIntPtr(ACodeAddress) + SIZE_OF_JUMP);
    PInteger(P)^ := Displacement;

    { There is no way to query the original protection level, so we cannot restore
      to that protection level as we do on Windows. }
  end;
end;

{$ELSE}

// iOS, Android

function HookCode(const ACodeAddress, AHookAddress: Pointer): Boolean;
begin
  { We are not allowed to change protection levels of executable memory pages
    on iOS and Android. }
  Result := False;
end;

{$ENDIF}

{$IF Defined(MSWINDOWS)}

// Windows

function HookVMT(const AVMTEntry, AHookAddress: Pointer): Boolean;
var
  OldProtect: DWORD;
begin
  { AVMT entry is located in a read-only memory page. We need to change the
    protection level, so we can change it. This should always succeed on
    Windows. }

  Result := VirtualProtect(AVMTEntry, SizeOf(Pointer), PAGE_READWRITE, OldProtect);

  if (Result) then
  begin
    { Change entry in VMT }
    PPointer(AVMTEntry)^ := AHookAddress;

    { Restore protection level }
    VirtualProtect(AVMTEntry, SizeOf(Pointer), OldProtect, OldProtect);
  end;
end;

{$ELSE}

// macOS, iOS (Simulator), Android, Linux

function HookVMT(const AVMTEntry, AHookAddress: Pointer): Boolean;
var
  AlignedCodeAddress: UIntPtr;
begin
  { This version is similar to HookVMT on Windows, except that we need to use
    the "mprotect" API instead of "VirtualProtect". mprotect only works with
    while memory pages, so we must align AVMTEntry to the size of a memory
    page. This page size is retrieved during initialization using the
    "sysconf(_SC_PAGESIZE)" API. }
  AlignedCodeAddress := UIntPtr(AVMTEntry) and (not (GPageSize - 1));

  Result := (mprotect(Pointer(AlignedCodeAddress), GPageSize, PROT_READ or PROT_WRITE) = 0);

  if (Result) then
    { Change entry in VMT }
    PPointer(AVMTEntry)^ := AHookAddress;
end;

{$ENDIF}

initialization
  {$IFNDEF MSWINDOWS}
  GPageSize := sysconf(_SC_PAGESIZE);
  {$ENDIF}

end.

