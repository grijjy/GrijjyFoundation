unit Grijjy.MemoryPool;

{ A reusable memory pooling class }

{$I Grijjy.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections;

const
  MAX_BLOCKS_QUEUED = 1024;

type
  TgoMemoryPool = class(TObject)
  private
    FBlockSize: Integer;
    FMaxBlocksQueued: Integer;
    FBlocks: TQueue<Pointer>;
    FLock: TCriticalSection;
    function GetCount: Integer;
    function GetSize: Integer;
    procedure Clear;
  public
    constructor Create(const ABlockSize: Integer; const AMaxBlocksQueued: Integer = MAX_BLOCKS_QUEUED);
    destructor Destroy; override;
  public
    function RequestMem: Pointer; overload;
    function RequestMem(const AName: String): Pointer; overload;
    procedure ReleaseMem(P: Pointer); overload;
    procedure ReleaseMem(P: Pointer; const AName: String); overload;
  public
    property BlockSize: Integer read FBlockSize;
    property Count: Integer read GetCount;
    property Size: Integer read GetSize;
  end;

implementation

{ TgoMemoryPool }

constructor TgoMemoryPool.Create(const ABlockSize: Integer; const AMaxBlocksQueued: Integer = MAX_BLOCKS_QUEUED);
begin
  FBlockSize := ABlockSize;
  FMaxBlocksQueued := AMaxBlocksQueued;
  FBlocks := TQueue<Pointer>.Create;
  FLock := TCriticalSection.Create;
end;

destructor TgoMemoryPool.Destroy;
begin
  Clear;
  FLock.Enter;
  try
    FBlocks.Free;
  finally
    FLock.Leave;
  end;
  FLock.Free;
  inherited Destroy;
end;

function TgoMemoryPool.RequestMem: Pointer;
begin
  Result := nil;
  FLock.Enter;
  try
    if FBlocks.Count > 0 then
      Result := FBlocks.Dequeue;
  finally
    FLock.Leave;
  end;
  if Result = nil then
  begin
    GetMem(Result, FBlockSize);
    if Result <> nil then
      FillChar(Result^, FBlockSize, 0);
  end;
end;

function TgoMemoryPool.RequestMem(const AName: String): Pointer;
begin
  Result := nil;
  FLock.Enter;
  try
    if FBlocks.Count > 0 then
      Result := FBlocks.Dequeue;
  finally
    FLock.Leave;
  end;
  if Result = nil then
  begin
    GetMem(Result, FBlockSize);
    if Result <> nil then
      FillChar(Result^, FBlockSize, 0);
  end;
end;

procedure TgoMemoryPool.ReleaseMem(P: Pointer);
begin
  if P <> nil then
  begin
    FLock.Enter;
    try
      if FBlocks.Count < FMaxBlocksQueued then
      begin
        FBlocks.Enqueue(P);
        Exit;
      end;
    finally
      FLock.Leave;
    end;
    FreeMem(P);
  end;
end;

procedure TgoMemoryPool.ReleaseMem(P: Pointer; const AName: String);
begin
  if P <> nil then
  begin
    FLock.Enter;
    try
      if FBlocks.Count < FMaxBlocksQueued then
      begin
        FBlocks.Enqueue(P);
        Exit;
      end;
    finally
      FLock.Leave;
    end;
    FreeMem(P);
  end;
end;

procedure TgoMemoryPool.Clear;
begin
  FLock.Enter;
  try
    while FBlocks.Count > 0 do
      FreeMem(FBlocks.Dequeue);
  finally
    FLock.Leave;
  end;
end;

function TgoMemoryPool.GetCount: Integer;
begin
  Result := FBlocks.Count;
end;

function TgoMemoryPool.GetSize: Integer;
begin
  Result := FBlocks.Count * FBlockSize;
end;

end.