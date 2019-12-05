unit Grijjy.CodeBlocks;
{ Code block helper class for macOS and iOS to simplify the usage of ObjC code blocks}

{ 1.  To create a call a code block
      TObjCBlock.CreateBlockWithProcedure(
        procedure(p1: NSInteger; p2: Pointer)
        begin
          grLog('OnTimer');

        end));

  2.  You may need to define a new TProc<> for your block if no suitable one
      exists with the correct parameters. }

{ Note: This class is based on TamoSoft implementation,

  Copyright(c) 2017 TamoSoft Limited
  https://habr.com/post/325204/ 
  
LICENSE:

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

You may not use the Software in any projects published under viral licenses,
including, but not limited to, GNU GPL.

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE }  

{$I Grijjy.inc}

interface

uses
  System.SysUtils,
  {$IFDEF IOS}
  iOSapi.CocoaTypes,
  iOSapi.Foundation,
  {$ELSE}
    {$IFDEF MACOS}
    Macapi.Foundation,
    Macapi.CocoaTypes,
    {$ENDIF}
  {$ENDIF}
  Macapi.ObjectiveC,
  Macapi.Helpers,
  Macapi.ObjCRuntime;

type
  TProc1 = TProc;
  TProc2 = TProc<Pointer>;
  TProc3 = TProc<Pointer, Pointer>;
  TProc4 = TProc<Pointer, Pointer, Pointer>;
  TProc5 = TProc<Pointer, Pointer, Pointer, Pointer>;
  TProc6 = TProc<NSInteger>;
  TProc7 = TFunc<NSRect, Boolean>;
  TProc8 = TProc<NSInteger, Pointer>;

  TProcType = (ptNone, pt1, pt2, pt3, pt4, pt5, pt6, pt7, pt8);

  TObjCBlock = record
   private
     class procedure SelfTest; static;
     class function CreateBlockWithCFunc(const ATProc: TProc; const AType: TProcType): Pointer; static;
   public
     class function CreateBlockWithProcedure(const AProc: TProc1): Pointer; overload; static;
     class function CreateBlockWithProcedure(const AProc: TProc2): Pointer; overload; static;
     class function CreateBlockWithProcedure(const AProc: TProc3): Pointer; overload; static;
     class function CreateBlockWithProcedure(const AProc: TProc4): Pointer; overload; static;
     class function CreateBlockWithProcedure(const AProc: TProc5): Pointer; overload; static;
     class function CreateBlockWithProcedure(const AProc: TProc6): Pointer; overload; static;
     class function CreateBlockWithProcedure(const AProc: TProc7): Pointer; overload; static;
     class function CreateBlockWithProcedure(const AProc: TProc8): Pointer; overload; static;
  end;

implementation

  function imp_implementationWithBlock(block: Pointer): Pointer;
    cdecl; external libobjc name _PU + 'imp_implementationWithBlock';
  function imp_removeBlock(anImp: Pointer): integer;
    cdecl; external libobjc name _PU + 'imp_removeBlock';

type
  Block_Descriptor = packed record
    Reserved: NativeUint;
    Size: NativeUint;
    copy_helper: Pointer;
    dispose_helper: Pointer;
  end;
  PBlock_Descriptor = ^Block_Descriptor;

  Block_Literal = packed record
    Isa: Pointer;
    Flags: integer;
    Reserved: integer;
    Invoke: Pointer;
    Descriptor: PBlock_Descriptor;
  end;
  PBlock_Literal = ^Block_Literal;

  TBlockInfo = packed record
     BlockStructure: Block_Literal;
     LocProc: TProc;
     ProcType: TProcType;
  end;
  PBlockInfo = ^TBlockInfo;

  TObjCBlockList = class (TObject)
  private
    FBlockList: TArray<TBlockInfo>;
    procedure ClearAllBlocks;
  public
    constructor Create;
    destructor Destroy; override;
    function AddNewBlock(const ATProc: TProc; const AType: TProcType): Pointer;
    function FindMatchingBlock(const ACurrBlock: Pointer): integer;
    procedure ClearBlock(const AIdx: integer);
    property BlockList: TArray<TBlockInfo> read FBlockList ;
  end;

var
  BlockObj: TObjCBlockList;

function InvokeCallback(aNSBlock, p1, p2, p3, p4: Pointer): Pointer; cdecl;
var
  I: integer;
  Rect: NSRect;
begin
  Result := nil;
  if Assigned(BlockObj) then
  begin
    TMonitor.Enter(BlockObj);
    try
      I:= BlockObj.FindMatchingBlock(aNSBlock);
      if I >= 0 then
      begin
        case  BlockObj.BlockList[I].ProcType of
          TProcType.pt1: TProc1(BlockObj.BlockList[I].LocProc)();
          TProcType.pt2: TProc2(BlockObj.BlockList[I].LocProc)(p1);
          TProcType.pt3: TProc3(BlockObj.BlockList[I].LocProc)(p1, p2);
          TProcType.pt4: TProc4(BlockObj.BlockList[I].LocProc)(p1, p2, p3);
          TProcType.pt5: TProc5(BlockObj.BlockList[I].LocProc)(p1, p2, p3, p4);
          TProcType.pt6: TProc6(BlockObj.BlockList[I].LocProc)(NSinteger(p1));
          TProcType.pt7:
          begin
            Rect.origin.x   := CGFloat(p1);
            Rect.origin.y   := CGFloat(p2);
            Rect.size.width := CGFloat(p3);
            Rect.size.height:= CGFloat(p4);
            Result := Pointer(TProc7(BlockObj.BlockList[I].LocProc)(Rect));
          end;
          TProcType.pt8: TProc8(BlockObj.BlockList[I].LocProc)(NSinteger(p1), p2);
        end;
      end;
    finally
      TMonitor.Exit(BlockObj);
    end;
  end;
end;

procedure DisposeCallback(ANSBlock: Pointer) cdecl;
var
  I: integer;
begin
  if Assigned(BlockObj) then
  begin
    TMonitor.Enter(BlockObj);
    try
      I:= BlockObj.FindMatchingBlock(ANSBlock);
      if I >= 0
        then BlockObj.ClearBlock(I);
    finally
      TMonitor.Exit(BlockObj);
    end;
  end;
  TNSObject.Wrap(ANSBlock).release;
end;

procedure CopyCallback(ASource, ADest: Pointer) cdecl;
begin
 //
end;

class function TObjCBlock.CreateBlockWithProcedure(const AProc: TProc1): Pointer;
begin
  Result := CreateBlockWithCFunc(TProc(AProc), TProcType.pt1);
end;

class function TObjCBlock.CreateBlockWithProcedure(const AProc: TProc2): Pointer;
begin
  Result := CreateBlockWithCFunc(TProc(AProc), TProcType.pt2);
end;

class function TObjCBlock.CreateBlockWithProcedure(const AProc: TProc3): Pointer;
begin
  Result := CreateBlockWithCFunc(TProc(AProc), TProcType.pt3);
end;

class function TObjCBlock.CreateBlockWithProcedure(const AProc: TProc4): Pointer;
begin
  Result := CreateBlockWithCFunc(TProc(AProc), TProcType.pt4);
end;

class function TObjCBlock.CreateBlockWithProcedure(const AProc: TProc5): Pointer;
begin
  Result := CreateBlockWithCFunc(TProc(AProc), TProcType.pt5);
end;

class function TObjCBlock.CreateBlockWithProcedure(const AProc: TProc6): Pointer;
begin
  Result := CreateBlockWithCFunc(TProc(AProc), TProcType.pt6);
end;

class function TObjCBlock.CreateBlockWithProcedure(const AProc: TProc7): Pointer;
begin
  Result := CreateBlockWithCFunc(TProc(AProc), TProcType.pt7);
end;

class function TObjCBlock.CreateBlockWithProcedure(const AProc: TProc8): Pointer;
begin
  Result := CreateBlockWithCFunc(TProc(AProc), TProcType.pt8);
end;

class function TObjCBlock.CreateBlockWithCFunc(const ATProc: TProc; const AType: TProcType): Pointer;
begin
  Result := nil;
  if Assigned(BlockObj) then
  begin
    TMonitor.Enter(BlockObj);
    try
      Result := BlockObj.AddNewBlock(ATProc, AType);
    finally
      TMonitor.Exit(BlockObj);
    end;
  end;
end;

class procedure TObjCBlock.SelfTest;
var
  P: Pointer;
  Test: NativeUint;
  // _cmd is ignored
  func : procedure ( p1, _cmd, p2, p3, p4: Pointer); cdecl;
begin
  Test:= 0;
  P:= TObjCBlock.CreateBlockWithProcedure(
    procedure (p1, p2, p3, p4: Pointer)
    begin
      Test:= NativeUint(p1) + NativeUint(p2) +
             NativeUint(p3) + NativeUint(p4);
    end);
  @func := imp_implementationWithBlock(P);
  // _cmd is ignored
  func(Pointer(1), nil, Pointer(2),  Pointer(3),  Pointer(4));
  imp_removeBlock(@func);
  if Test <> (1 + 2 + 3 + 4)
    then raise Exception.Create('Objective-C code block self-test failed!');
end;

{ TObjCBlockList }

constructor TObjCBlockList.Create;
begin
  inherited;
end;

destructor TObjCBlockList.Destroy;
begin
  TMonitor.Enter(Self);
  try
    ClearAllBlocks;
  finally
    TMonitor.Exit(Self);
  end;
  inherited Destroy;
end;

procedure TObjCBlockList.ClearBlock(const AIdx: integer);
begin
  Dispose(FBlockList[AIdx].BlockStructure.Descriptor);
  FBlockList[AIdx].BlockStructure.isa:= nil;
  FBlockList[AIdx].LocProc:= nil;
  Delete(FBlockList, AIdx, 1);
end;

function TObjCBlockList.AddNewBlock(const ATProc: TProc; const AType: TProcType): Pointer;
var
  aDesc:  PBlock_Descriptor;
const
  BLOCK_HAS_COPY_DISPOSE = 1 shl 25;
begin
  SetLength(FBlockList, Length(FBlockList) + 1);
  FillChar(FBlockList[High(FBlockList)], SizeOf(TBlockInfo), 0);

  FBlockList[High(FBlockList)].BlockStructure.Isa    := NSClassFromString ((StrToNSStr('NSBlock') as ILocalobject).GetObjectID);
  FBlockList[High(FBlockList)].BlockStructure.Invoke := @InvokeCallback;
  FBlockList[High(FBlockList)].BlockStructure.Flags  := BLOCK_HAS_COPY_DISPOSE;
  FBlockList[High(FBlockList)].ProcType              := AType;
  FBlockList[High(FBlockList)].LocProc               := ATProc;

  New(aDesc);
  aDesc.Reserved       := 0;
  aDesc.Size           := SizeOf(Block_Literal);
  aDesc.copy_helper    := @CopyCallback;
  aDesc.dispose_helper := @DisposeCallback;
  FBlockList[High(FBlockList)].BlockStructure.Descriptor := aDesc;

  Result := @FBlockList[High(FBlockList)].BlockStructure;
end;

procedure TObjCBlockList.ClearAllBlocks;
var
  I: integer;
begin
  for I := High(FBlockList) downto Low(FBlockList) do
    ClearBlock(I);
end;

function TObjCBlockList.FindMatchingBlock(const ACurrBlock: Pointer): integer;
var
  I: integer;
begin
  Result := -1;
  if ACurrBlock <> nil then
  begin
    for I:= Low(FBlockList) to High(FBlockList) do
    begin
      if FBlockList[I].BlockStructure.Descriptor = PBlock_Literal(ACurrBlock).Descriptor
        then Exit(I);
    end;
  end;
end;

initialization
  BlockObj:=TObjCBlockList.Create;
  TObjCBlock.SelfTest;

finalization
  FreeAndNil(BlockObj);

end.
