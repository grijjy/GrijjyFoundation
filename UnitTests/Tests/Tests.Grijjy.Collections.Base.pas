unit Tests.Grijjy.Collections.Base;

interface

uses
  System.TypInfo,
  System.SysUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  DUnitX.TestFramework;

type
  TTestCollectionBase<T> = class abstract
  private
    FTypeInfo: PTypeInfo;
    FTypeData: PTypeData;
    FAllocatedValues: TList<T>;
    FComparer: IEqualityComparer<T>;
  private
    procedure ReleaseValue(const AValue: T);
  protected
    procedure SetUp;
    procedure TearDown;
    function CreateValue(const AValue: Integer): T;
    function CreateValues(const ACount: Integer): TArray<T>; overload;
    function CreateValues(const AValues: array of Integer): TArray<T>; overload;
    procedure TestEquals(const AExpected, AActual: T);
  end;

{$REGION 'Different sample types for testing generic collections'}
type
  TDigit = (Zero, One, Two, Three, Four, Five, Six, Seven, Eight, Nine);
  TDigits = set of TDigit;
  TTestProc = procedure(const AParam: Integer);

{$IFNDEF NEXTGEN}
type
  {$IF (RTLVersion = 33)}
  // For some reason, Delphi 10.3 Rio raises AVs with short string of length 1
  TStr1 = String[2];
  {$ELSE}
  TStr1 = String[1];
  {$ENDIF}
  TStr2 = String[2];
  TStr3 = String[3];
{$ENDIF}

type
  TSimpleRecord = record
    A: Integer;
    B: Single;
    C: Double;
    D: Word;
  end;

type
  TManagedRecord = record
    A: Integer;
    B: TBytes;
    C: String;
  end;

type
  TBar = class;

  TFoo = class
  public class var
    InstanceCount: Integer;
  private
    FValue: Integer;
    FBar: TBar;
  public
    constructor Create(const AValue: Integer);
    destructor Destroy; override;

    property Value: Integer read FValue;
    property Bar: TBar read FBar write FBar;
  end;
  TFooClass = class of TFoo;

  TBar = class
  public class var
    InstanceCount: Integer;
  private
    FValue: Integer;
    [weak] FFoo: TFoo;
  public
    constructor Create(const AValue: Integer);
    destructor Destroy; override;
    function Equals(Obj: TObject): Boolean; override;
    function GetHashCode: Integer; override;

    property Value: Integer read FValue;
    property Foo: TFoo read FFoo write FFoo;
  end;

type
  IBaz = interface
  ['{A6B59548-5982-4D6A-90CA-46134A514802}']
    function GetValue: Integer;

    property Value: Integer read GetValue;
  end;

type
  TBaz = class(TInterfacedObject, IBaz)
  private
    FValue: Integer;
  private
    function GetValue: Integer;
  public
    constructor Create(const AValue: Integer);
  end;

type
  TFooBarRecord = record
    Foo: TFoo;
    Bar: TBar;
  end;

type
  TTestArray = array [0..2] of Integer;
  TManagedArray = TArray<UnicodeString>;
  TFooBarArray = TArray<TFooBarRecord>;
{$ENDREGION 'Different sample types for testing generic collections'}

implementation

{ TFoo }

constructor TFoo.Create(const AValue: Integer);
begin
  inherited Create;
  FValue := AValue;
  Inc(InstanceCount);
end;

destructor TFoo.Destroy;
begin
  Dec(InstanceCount);
  inherited;
end;

{ TBar }

constructor TBar.Create(const AValue: Integer);
begin
  inherited Create;
  FValue := AValue;
  Inc(InstanceCount);
end;

destructor TBar.Destroy;
begin
  Dec(InstanceCount);
  inherited;
end;

function TBar.Equals(Obj: TObject): Boolean;
begin
  if (Obj = Self) then
    Exit(True);

  if (Obj = nil) then
    Exit(False);

  if (Obj is TBar) then
    Result := (FValue = TBar(Obj).FValue)
  else
    Result := False;
end;

function TBar.GetHashCode: Integer;
begin
  Result := FValue;
end;

{ TBaz }

constructor TBaz.Create(const AValue: Integer);
begin
  inherited Create;
  FValue := AValue;
end;

function TBaz.GetValue: Integer;
begin
  Result := FValue;
end;

{ TTestCollectionBase<T> }

function TTestCollectionBase<T>.CreateValue(const AValue: Integer): T;
var
  I1: Int8 absolute Result;
  U1: UInt8 absolute Result;
  I2: Int16 absolute Result;
  U2: UInt16 absolute Result;
  I4: Int32 absolute Result;
  U4: UInt32 absolute Result;
  I8: Int64 absolute Result;
  R4: Single absolute Result;
  R8: Double absolute Result;
  R10: Extended absolute Result;
  RI8: Comp absolute Result;
  RC8: Currency absolute Result;
  Obj: TObject absolute Result;
  Cls: TClass absolute Result;
  Intf: IInterface absolute Result;
  Ptr: Pointer absolute Result;
  Proc: TProcedure absolute Result;
  Method: TMethod absolute Result;
  UnicodeStr: UnicodeString absolute Result;
  V: Variant absolute Result;
  Bytes: TBytes absolute Result;
  WC: WideChar absolute Result;
  Arr: TTestArray absolute Result;
  SR: TSimpleRecord absolute Result;
  MR: TManagedRecord absolute Result;
  FB: TFooBarRecord absolute Result;
  MA: TManagedArray absolute Result;
  FBA: TFooBarArray absolute Result;
  Foo: TFoo;
  Bar: TBar;
  {$IFNDEF NEXTGEN}
  Str1: TStr1 absolute Result;
  Str2: TStr2 absolute Result;
  Str3: TStr3 absolute Result;
  StrN: ShortString absolute Result;
  AnsiStr: AnsiString absolute Result;
  WideStr: WideString absolute Result;
  AC: AnsiChar absolute Result;
  {$ENDIF}
begin
  case FTypeInfo.Kind of
    tkInteger,
    tkEnumeration:
      begin
        case FTypeData.OrdType of
          otSByte: I1 := Int8(AValue);
          otUByte: U1 := UInt8(AValue);
          otSWord: I2 := Int16(AValue);
          otUWord: U2 := UInt16(AValue);
          otSLong: I4 := AValue;
          otULong: U4 := UInt32(AValue);
        else
          System.Assert(False);
        end;
      end;

    tkFloat:
      begin
        case FTypeData.FloatType of
          ftSingle  : R4 := AValue;
          ftDouble  : R8 := AValue;
          ftExtended: R10 := AValue;
          ftComp    : RI8 := AValue;
          ftCurr    : RC8 := AValue;
        else
          System.Assert(False);
        end;
      end;

    tkClass:
      begin
        System.Assert(TypeInfo(T) = TypeInfo(TFoo));
        Obj := TFoo.Create(AValue);
      end;

    tkClassRef:
      Cls := TFoo;

    tkInterface:
      Intf := TBaz.Create(AValue);

    tkPointer:
      Ptr := Pointer(AValue);

    tkProcedure:
      Proc := Pointer(AValue);

    tkMethod:
      begin
        Method.Code := Pointer(AValue shr 4);
        Method.Data := Pointer(AValue and $0F);
      end;

    {$IFNDEF NEXTGEN}
    tkString:
      case SizeOf(T) of
        2: begin Str1[0] := #1; Str1[1] := AnsiChar(AValue); end;
        3: begin Str2[0] := #2; Str2[1] := AnsiChar(AValue); Str2[2] := AnsiChar(AValue shr 8) end;
        4: begin Str3[0] := #3; Str3[1] := AnsiChar(AValue); Str3[2] := AnsiChar(AValue shr 8); Str3[3] := AnsiChar(AValue shr 16) end;
      else
        StrN := ShortString(IntToStr(AValue));
      end;

    tkLString:
      AnsiStr := AnsiString(IntToStr(AValue));

    tkWString:
      WideStr := WideString(IntToStr(AValue));
    {$ENDIF}

    tkUString:
      UnicodeStr := UnicodeString(IntToStr(AValue));

    tkVariant:
      V := AValue;

    tkInt64:
      I8 := AValue;

    tkDynArray:
      case FTypeData.DynArrElType^^.Kind of
        tkInteger:
          begin
            SetLength(Bytes, 2);
            Bytes[0] := AValue;
            Bytes[1] := AValue * 2;
          end;

        tkUString:
          begin
            SetLength(MA, 2);
            MA[0] := UnicodeString(IntToStr(AValue));
            MA[1] := UnicodeString(IntToStr(AValue * 2));
          end;

        tkRecord:
          begin
            SetLength(FBA, 2);
            FBA[0].Foo := TFoo.Create(AValue);
            FBA[0].Bar := TBar.Create(AValue * 2);
            FBA[0].Foo.Bar := FBA[0].Bar;
            FBA[0].Bar.Foo := FBA[0].Foo;

            FBA[1].Foo := TFoo.Create(AValue * 3);
            FBA[1].Bar := TBar.Create(AValue * 4);
            FBA[1].Foo.Bar := FBA[1].Bar;
            FBA[1].Bar.Foo := FBA[1].Foo;
          end
      else
        System.Assert(False);
      end;

    {$IFNDEF NEXTGEN}
    tkChar:
      AC := AnsiChar(AValue);
    {$ENDIF}

    tkWChar:
      WC := Char(AValue);

    tkSet:
      begin
        case SizeOf(T) of
          1: U1 := AValue;
          2: U2 := AValue;
          4: U4 := AValue;
        else
          System.Assert(False);
        end;
      end;

    tkArray:
      begin
        Arr[0] := AValue;
        Arr[1] := AValue * 2;
        Arr[2] := AValue * 3;
      end;

    tkRecord:
      begin
        if (FTypeInfo.NameFld.ToString = 'TSimpleRecord') then
        begin
          SR.A := AValue;
          SR.B := AValue;
          SR.C := AValue;
          SR.D := AValue;
        end
        else if (FTypeInfo.NameFld.ToString = 'TManagedRecord') then
        begin
          MR.A := AValue;
          SetLength(MR.B, 1);
          MR.B[0] := Byte(AValue);
          MR.C := IntToStr(AValue);
        end
        else if (FTypeInfo.NameFld.ToString = 'TFooBarRecord') then
        begin
          Foo := TFoo.Create(AValue);
          Bar := TBar.Create(AValue * 2);

          { Create circular reference }
          Foo.Bar := Bar;
          Bar.Foo := Foo;
          FB.Foo := Foo;
          FB.Bar := Bar;
        end
        else
          System.Assert(False);
      end;
  else
    System.Assert(False);
  end;

  FAllocatedValues.Add(Result);
end;

function TTestCollectionBase<T>.CreateValues(const ACount: Integer): TArray<T>;
var
  I: Integer;
begin
  SetLength(Result, ACount);
  for I := 0 to ACount - 1 do
    Result[I] := CreateValue(I);
end;

function TTestCollectionBase<T>.CreateValues(
  const AValues: array of Integer): TArray<T>;
var
  I: Integer;
begin
  SetLength(Result, Length(AValues));
  for I := 0 to Length(AValues) - 1 do
    Result[I] := CreateValue(AValues[I]);
end;

procedure TTestCollectionBase<T>.ReleaseValue(const AValue: T);
var
  Obj: TObject absolute AValue;
  FB: TFooBarRecord absolute AValue;
  FBA: TFooBarArray absolute AValue;
  I: Integer;
begin
  case FTypeInfo.Kind of
    tkClass:
      Obj.DisposeOf;

    tkRecord:
      if (FTypeInfo.NameFld.ToString = 'TFooBarRecord') then
      begin
        FB.Foo.DisposeOf;
        FB.Bar.DisposeOf;
      end;

    tkDynArray:
      begin
        if (FTypeData.DynArrElType^^.Kind = tkRecord) then
        begin
          for I := 0 to Length(FBA) - 1 do
          begin
            FBA[I].Foo.Free;
            FBA[I].Bar.Free;
          end;
        end;
      end;
  end;
end;

procedure TTestCollectionBase<T>.SetUp;
begin
  FTypeInfo := System.TypeInfo(T);
  System.Assert(Assigned(FTypeInfo));
  FTypeData := GetTypeData(FTypeInfo);
  System.Assert(Assigned(FTypeData));
  FAllocatedValues := TList<T>.Create;
  FComparer := TEqualityComparer<T>.Default;
  TFoo.InstanceCount := 0;
  TBar.InstanceCount := 0;
end;

procedure TTestCollectionBase<T>.TearDown;
var
  Value: T;
begin
  if Assigned(FAllocatedValues) then
  begin
    for Value in FAllocatedValues do
      ReleaseValue(Value);
  end;
  FAllocatedValues.Free;

  { For checking cycles between TFoo and TBar }
  Assert.AreEqual(0, TBar.InstanceCount, 'TBar leaks');
  Assert.AreEqual(0, TFoo.InstanceCount, 'TFoo leaks');
end;

procedure TTestCollectionBase<T>.TestEquals(const AExpected, AActual: T);
begin
  if (not FComparer.Equals(AExpected, AActual)) then
    Assert.Fail('Values not equal');
end;

initialization
  ReportMemoryLeaksOnShutdown := True;

end.
