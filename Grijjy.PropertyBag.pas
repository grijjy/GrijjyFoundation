unit Grijjy.PropertyBag;

interface

uses
  System.SysUtils;

type
  { A fast, lightweight and general purpose property bag. }
  TgoPropertyBag = class
  {$REGION 'Internal Declarations'}
  private const
    EMPTY_HASH = -1;
  private type
    TValueKind = (
      { Inline types (that fit into a 64-bit field) }
      vkBoolean, vkInteger, vkCardinal, vkSingle, vkPointer,
      vkInt64, vkUInt64, vkDouble,

      { Managed on ARC platforms }
      vkObject,

      { Managed and dynamically allocated types }
      vkString, vkInterface, vkDynArray, vkRecord,

      {$IFDEF AUTOREFCOUNT}
      vkManagedStart = vkObject
      {$ELSE}
      vkManagedStart = vkString
      {$ENDIF});
    TItem = record
      Hash: Integer;
      Name: Pointer;
      {$IFDEF DEBUG}
      TypeInfo: Pointer;
      {$ENDIF}
      case Kind: TValueKind of
        vkBoolean  : (AsBoolean: Boolean);
        vkInteger  : (AsInteger: Integer);
        vkCardinal : (AsCardinal: Cardinal);
        vkSingle   : (AsSingle: Single);
        vkPointer  : (AsPointer: Pointer);
        vkString   : (AsString: Pointer);
        vkObject   : (AsObject: Pointer);
        vkInterface: (AsInterface: Pointer);
        vkDynArray : (AsDynArray: Pointer);
        vkRecord   : (AsRecord: Pointer);
        vkInt64    : (AsInt64: Int64);
        vkUInt64   : (AsUInt64: UInt64);
        vkDouble   : (AsDouble: Double);
      end;
    PItem = ^TItem;
  private
    FItems: TArray<TItem>;
    FCount: Integer;
    FGrowThreshold: Integer;
  private
    function GetAsBoolean(const AName: String): Boolean; inline;
    procedure SetAsBoolean(const AName: String; const AValue: Boolean); inline;
    function GetAsInteger(const AName: String): Integer; inline;
    procedure SetAsInteger(const AName: String; const AValue: Integer); inline;
    function GetAsCardinal(const AName: String): Cardinal; inline;
    procedure SetAsCardinal(const AName: String; const AValue: Cardinal); inline;
    function GetAsInt64(const AName: String): Int64; inline;
    procedure SetAsInt64(const AName: String; const AValue: Int64); inline;
    function GetAsUInt64(const AName: String): UInt64;
    procedure SetAsUInt64(const AName: String; const AValue: UInt64);
    function GetAsSingle(const AName: String): Single; inline;
    procedure SetAsSingle(const AName: String; const AValue: Single); inline;
    function GetAsDouble(const AName: String): Double; inline;
    procedure SetAsDouble(const AName: String; const AValue: Double); inline;
    function GetAsPointer(const AName: String): Pointer; inline;
    procedure SetAsPointer(const AName: String; const AValue: Pointer); inline;
    function GetAsString(const AName: String): String; inline;
    procedure SetAsString(const AName, AValue: String); inline;
    function GetAsInterface(const AName: String): IInterface; inline;
    procedure SetAsInterface(const AName: String; const AValue: IInterface); inline;
    function GetAsObject(const AName: String): TObject; inline;
    procedure SetAsObject(const AName: String; const AValue: TObject); inline;
    function GetAsBytes(const AName: String): TBytes; inline;
    procedure SetAsBytes(const AName: String; const AValue: TBytes); inline;
  private
    function Get(const AName: String): PItem;
    function Add(const AName: String): PItem;
    procedure Cleanup(const AItem: PItem); inline;
    procedure Resize(ANewSize: Integer);
    procedure DoRemove(AIndex: Integer; const AMask: Integer);
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a new property bag. }
    constructor Create;

    { Destroys the property bag. }
    destructor Destroy; override;

    { Clears the property bag. }
    procedure Clear;

    { Removes an item with a given name from the property bag.

      Parameters:
        AName: the name of the property to remove (case-sensitive). }
    procedure Remove(const AName: String);

    { Retrieves a generic dynamic array from the property bag given a name.

      Parameters:
        AName: the name of the property to retrieve (case-sensitive).

      Returns:
        The generic dynamic array associated with AName, or nil in case the
        bag does not contain a property called AName, or the property is not
        of a dynamic array type.

      NOTE: only simple "unmanaged" array element types are supported (that is,
      T cannot be a managed type such as a String or Interface). This is checked
      with an assertion.

      NOTE: The type parameter <T> MUST be the same as uses when the property
      was added using SetAsArray. Calling SetAsArray<Byte>('foo', ...) followed
      by AsArray<String>('foo') leads to undefined behavior and a probably
      crash. When compiling in DEBUG mode, an assertion is raised when <T> is
      different from the call to SetAsArray<T>. }
    function AsArray<T: record>(const AName: String): TArray<T>;

    { Adds or replaces a generic dynamic array in the property bag.

      Parameters:
        AName: the name of the property to set (case-sensitive).
        AValue: the dynamic array to associate with AName.

      See AsArray<T> for important information about type safety. }
    procedure SetAsArray<T: record>(const AName: String; const AValue: TArray<T>);

    { Retrieves a record from the property bag given a name.

      Parameters:
        AName: the name of the property to retrieve (case-sensitive).

      Returns:
        The record associated with AName, or an empty record in case the bag
        does not contain a property called AName, or the property is not of a
        record type.

      NOTE: only simple "unmanaged" record types are supported (that is, records
      without managed types such as Strings and Interfaces). This is checked
      with an assertion.

      NOTE: The type parameter <T> MUST be the same as uses when the property
      was added using SetAsRecord. Calling SetAsRecord<TPoint>('foo', ...)
      followed by AsRecord<TRect>('foo') leads to undefined behavior and a
      probably crash. When compiling in DEBUG mode, an assertion is raised when
      <T> is different from the call to SetRecord<T>. }
    function AsRecord<T: record>(const AName: String): T;

    { Adds or replaces a record in the property bag.

      Parameters:
        AName: the name of the property to set (case-sensitive).
        AValue: the record to associate with AName.

      See AsRecord<T> for important information about type safety. }
    procedure SetAsRecord<T: record>(const AName: String; const AValue: T);

    { The following properties are used to set and retrieve values in from the
      property bag, using a given (property) name. They behave like this:

      On Getting a value: return the value associate with AName. If the bag does
        not contain a property called AName, or that property is not of the
        requested type, then the default value for the type is returned (eg. 0
        for numeric values, nil for objects and '' for strings. The type must
        be exact, meaning that if you used AsInteger to set the value, then you
        must use AsInteger as well to retrieve the value (eg. AsInt64 will not
        work).

      On Setting a value: if a property called AName does not yet exist in the
        bag, then it is added. Otherwise, the existing value is replaced. It is
        OK to replace a property with a different type (eg. calling
        AsInteger['foo'] := 42 followed by AsString['foo'] := 'bar' is legal).

      Property names are case-sensitive.

      The property bag keeps "strong" references to interfaces (and objects on
      ARC platforms) you add to the bag. The reference is released when the
      property bag is destroyed or cleared, or when a property is removed by
      calling Remove.

      On non-ARC platforms, the property bag does NOT become owner of any
      objects stored into it. It just keeps a reference to an existing object. }
    property AsBoolean[const AName: String]: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger[const AName: String]: Integer read GetAsInteger write SetAsInteger;
    property AsCardinal[const AName: String]: Cardinal read GetAsCardinal write SetAsCardinal;
    property AsInt64[const AName: String]: Int64 read GetAsInt64 write SetAsInt64;
    property AsUInt64[const AName: String]: UInt64 read GetAsUInt64 write SetAsUInt64;
    property AsSingle[const AName: String]: Single read GetAsSingle write SetAsSingle;
    property AsDouble[const AName: String]: Double read GetAsDouble write SetAsDouble;
    property AsPointer[const AName: String]: Pointer read GetAsPointer write SetAsPointer;
    property AsString[const AName: String]: String read GetAsString write SetAsString;
    property AsInterface[const AName: String]: IInterface read GetAsInterface write SetAsInterface;
    property AsObject[const AName: String]: TObject read GetAsObject write SetAsObject;
    property AsBytes[const AName: String]: TBytes read GetAsBytes write SetAsBytes;

    { Number of items in the property bag. }
    property Count: Integer read FCount;
  end;

implementation

uses
  System.Generics.Collections,
  Grijjy.SysUtils;

{ TgoPropertyBag }

function TgoPropertyBag.Add(const AName: String): PItem;
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount >= FGrowThreshold) then
    Resize(Length(FItems) * 2);

  HashCode := goMurmurHash2(AName[Low(String)], Length(AName) * SizeOf(Char));
  Mask := Length(FItems) - 1;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].Hash;
    if (HC = EMPTY_HASH) then
      Break;

    Assert((HC <> HashCode) or (AName <> String(FItems[Index].Name)));

    Index := (Index + 1) and Mask;
  end;

  Result := @FItems[Index];
  Result.Hash := HashCode;
  Assert(Result.Name = nil);
  String(Result.Name) := AName; { Increases ref count }

  Inc(FCount);
end;

function TgoPropertyBag.AsArray<T>(const AName: String): TArray<T>;
var
  Item: PItem;
begin
  Assert(not IsManagedType(T), 'Only unmanaged array element types are supported.');
  Item := Get(AName);
  if (Item <> nil) and (Item.Kind = vkDynArray) then
  begin
    {$IFDEF DEBUG}
    Assert(TypeInfo(T) = Item.TypeInfo, 'AsArray<T> called with invalid type <T>.');
    {$ENDIF}
    Result := TArray<T>(Item.AsDynArray)
  end
  else
    Result := nil;
end;

function TgoPropertyBag.AsRecord<T>(const AName: String): T;
var
  Item: PItem;
begin
  Assert(not IsManagedType(T), 'Only unmanaged record types are supported.');
  Item := Get(AName);
  if (Item <> nil) and (Item.Kind = vkRecord) then
  begin
    {$IFDEF DEBUG}
    Assert(TypeInfo(T) = Item.TypeInfo, 'AsRecord<T> called with invalid type <T>.');
    {$ENDIF}
    Result := T(Item.AsRecord^)
  end
  else
    Result := Default(T);
end;

procedure TgoPropertyBag.Cleanup(const AItem: PItem);
begin
  if (AItem.Kind >= vkManagedStart) then
  begin
    case AItem.Kind of
      vkString:
        String(AItem.AsString) := ''; { Decreases ref count }

      vkInterface:
        IInterface(AItem.AsInterface) := nil; { Decreases ref count }

      vkDynArray:
        TBytes(AItem.AsDynArray) := nil; { Decreases ref count }

      {$IFDEF AUTOREFCOUNT}
      vkObject:
        TObject(AItem.AsObject) := nil; { Decreases ref count }
      {$ENDIF}

      vkRecord:
        begin
          FreeMem(AItem.AsPointer);
          AItem.AsPointer := nil;
        end;
    else
      AItem.AsPointer := nil;
    end;
  end
  else
    AItem.AsPointer := nil;
end;

procedure TgoPropertyBag.Clear;
var
  I: Integer;
  Item: PItem;
begin
  if (FItems <> nil) then
  begin
    Item := @FItems[0];
    for I := 0 to Length(FItems) - 1 do
    begin
      if (Item.Hash <> EMPTY_HASH) then
      begin
        Cleanup(Item);
        String(Item.Name) := ''; { Decreases ref count }
      end;
      Inc(Item);
    end;
    FItems := nil;
  end;
  FCount := 0;
  FGrowThreshold := 0;
end;

constructor TgoPropertyBag.Create;
begin
  inherited;
end;

destructor TgoPropertyBag.Destroy;
begin
  Clear;
  inherited;
end;

procedure TgoPropertyBag.DoRemove(AIndex: Integer; const AMask: Integer);
var
  Gap, HC, Bucket: Integer;
begin
  Cleanup(@FItems[AIndex]);
  String(FItems[AIndex].Name) := ''; { Decreases ref count }
  FItems[AIndex].Hash := EMPTY_HASH;
  FItems[AIndex].AsPointer := nil;

  Gap := AIndex;
  while True do
  begin
    AIndex := (AIndex + 1) and AMask;

    HC := FItems[AIndex].Hash;
    if (HC = EMPTY_HASH) then
      Break;

    Bucket := HC and AMask;
    if (not InCircularRange(Gap, Bucket, AIndex)) then
    begin
      FItems[Gap] := FItems[AIndex];
      Gap := AIndex;
      FItems[Gap].Hash := EMPTY_HASH;
    end;
  end;

  FItems[Gap].Hash := EMPTY_HASH;

  Dec(FCount);
end;

function TgoPropertyBag.Get(const AName: String): PItem;
var
  Mask, HashCode, Index, HC: Integer;
begin
  if (FCount = 0) then
    Exit(nil);

  Mask := Length(FItems) - 1;
  HashCode := goMurmurHash2(AName[Low(String)], Length(AName) * SizeOf(Char));
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].Hash;
    if (HC = EMPTY_HASH) then
      Exit(nil);

    if (HC = HashCode) and (AName = String(FItems[Index].Name)) then
      Exit(@FItems[Index]);

    Index := (Index + 1) and Mask;
  end;
end;

function TgoPropertyBag.GetAsBoolean(const AName: String): Boolean;
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item <> nil) and (Item.Kind = vkBoolean) then
    Result := Item.AsBoolean
  else
    Result := False;
end;

function TgoPropertyBag.GetAsBytes(const AName: String): TBytes;
begin
  Result := AsArray<Byte>(AName);
end;

function TgoPropertyBag.GetAsCardinal(const AName: String): Cardinal;
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item <> nil) and (Item.Kind = vkCardinal) then
    Result := Item.AsCardinal
  else
    Result := 0;
end;

function TgoPropertyBag.GetAsDouble(const AName: String): Double;
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item <> nil) and (Item.Kind = vkDouble) then
    Result := Item.AsDouble
  else
    Result := 0;
end;

function TgoPropertyBag.GetAsInt64(const AName: String): Int64;
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item <> nil) and (Item.Kind = vkInt64) then
    Result := Item.AsInt64
  else
    Result := 0;
end;

function TgoPropertyBag.GetAsInteger(const AName: String): Integer;
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item <> nil) and (Item.Kind = vkInteger) then
    Result := Item.AsInteger
  else
    Result := 0;
end;

function TgoPropertyBag.GetAsInterface(const AName: String): IInterface;
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item <> nil) and (Item.Kind = vkInterface) then
    Result := IInterface(Item.AsInterface)
  else
    Result := nil;
end;

function TgoPropertyBag.GetAsObject(const AName: String): TObject;
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item <> nil) and (Item.Kind = vkObject) then
    Result := TObject(Item.AsObject)
  else
    Result := nil;
end;

function TgoPropertyBag.GetAsPointer(const AName: String): Pointer;
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item <> nil) and (Item.Kind = vkPointer) then
    Result := Item.AsPointer
  else
    Result := nil;
end;

function TgoPropertyBag.GetAsSingle(const AName: String): Single;
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item <> nil) and (Item.Kind = vkSingle) then
    Result := Item.AsSingle
  else
    Result := 0;
end;

function TgoPropertyBag.GetAsString(const AName: String): String;
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item <> nil) and (Item.Kind = vkString) then
    Result := String(Item.AsString)
  else
    Result := '';
end;

function TgoPropertyBag.GetAsUInt64(const AName: String): UInt64;
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item <> nil) and (Item.Kind = vkUInt64) then
    Result := Item.AsUInt64
  else
    Result := 0;
end;

procedure TgoPropertyBag.Remove(const AName: String);
var
  Mask, HashCode, Index, HC: Integer;
begin
  if (FCount = 0) then
    Exit;

  Mask := Length(FItems) - 1;
  HashCode := goMurmurHash2(AName[Low(String)], Length(AName) * SizeOf(Char));
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].Hash;
    if (HC = EMPTY_HASH) then
      Exit;

    if (HC = HashCode) and (AName = String(FItems[Index].Name)) then
    begin
      DoRemove(Index, Mask);
      Exit;
    end;

    Index := (Index + 1) and Mask;
  end;
end;

procedure TgoPropertyBag.Resize(ANewSize: Integer);
var
  NewMask, I, NewIndex: Integer;
  OldItems, NewItems: TArray<TItem>;
begin
  if (ANewSize < 4) then
    ANewSize := 4;
  NewMask := ANewSize - 1;
  SetLength(NewItems, ANewSize);
  for I := 0 to ANewSize - 1 do
    NewItems[I].Hash := EMPTY_HASH;
  OldItems := FItems;

  for I := 0 to Length(OldItems) - 1 do
  begin
    if (OldItems[I].Hash <> EMPTY_HASH) then
    begin
      NewIndex := OldItems[I].Hash and NewMask;
      while (NewItems[NewIndex].Hash <> EMPTY_HASH) do
        NewIndex := (NewIndex + 1) and NewMask;
      NewItems[NewIndex] := OldItems[I];
    end;
  end;

  FItems := NewItems;
  FGrowThreshold := (ANewSize * 3) shr 2;
end;

procedure TgoPropertyBag.SetAsArray<T>(const AName: String;
  const AValue: TArray<T>);
var
  Item: PItem;
begin
  Assert(not IsManagedType(T), 'Only unmanaged array element types are supported.');
  Item := Get(AName);
  if (Item = nil) then
    Item := Add(AName)
  else
    Cleanup(Item);

  Item.Kind := vkDynArray;
  {$IFDEF DEBUG}
  Item.TypeInfo := TypeInfo(T);
  {$ENDIF}
  Assert(Item.AsDynArray = nil);
  TArray<T>(Item.AsDynArray) := AValue; { Increases ref count }
end;

procedure TgoPropertyBag.SetAsBoolean(const AName: String; const AValue: Boolean);
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item = nil) then
    Item := Add(AName)
  else
    Cleanup(Item);

  Item.Kind := vkBoolean;
  Item.AsBoolean := AValue;
end;

procedure TgoPropertyBag.SetAsBytes(const AName: String; const AValue: TBytes);
begin
  SetAsArray<Byte>(AName, AValue);
end;

procedure TgoPropertyBag.SetAsCardinal(const AName: String;
  const AValue: Cardinal);
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item = nil) then
    Item := Add(AName)
  else
    Cleanup(Item);

  Item.Kind := vkCardinal;
  Item.AsCardinal := AValue;
end;

procedure TgoPropertyBag.SetAsDouble(const AName: String; const AValue: Double);
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item = nil) then
    Item := Add(AName)
  else
    Cleanup(Item);

  Item.Kind := vkDouble;
  Item.AsDouble := AValue;
end;

procedure TgoPropertyBag.SetAsInt64(const AName: String; const AValue: Int64);
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item = nil) then
    Item := Add(AName)
  else
    Cleanup(Item);

  Item.Kind := vkInt64;
  Item.AsInt64 := AValue;
end;

procedure TgoPropertyBag.SetAsInteger(const AName: String;
  const AValue: Integer);
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item = nil) then
    Item := Add(AName)
  else
    Cleanup(Item);

  Item.Kind := vkInteger;
  Item.AsInteger := AValue;
end;

procedure TgoPropertyBag.SetAsInterface(const AName: String;
  const AValue: IInterface);
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item = nil) then
    Item := Add(AName)
  else
    Cleanup(Item);

  Item.Kind := vkInterface;
  Assert(Item.AsInterface = nil);
  IInterface(Item.AsInterface) := AValue; { Increases ref count }
end;

procedure TgoPropertyBag.SetAsObject(const AName: String; const AValue: TObject);
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item = nil) then
    Item := Add(AName)
  else
    Cleanup(Item);

  Item.Kind := vkObject;
  {$IFDEF AUTOREFCOUNT}
  Assert(Item.AsObject = nil);
  TObject(Item.AsObject) := AValue; { Increases ref count }
  {$ELSE}
  Item.AsObject := AValue;
  {$ENDIF}
end;

procedure TgoPropertyBag.SetAsPointer(const AName: String; const AValue: Pointer);
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item = nil) then
    Item := Add(AName)
  else
    Cleanup(Item);

  Item.Kind := vkPointer;
  Item.AsPointer := AValue;
end;

procedure TgoPropertyBag.SetAsRecord<T>(const AName: String; const AValue: T);
var
  Item: PItem;
begin
  Assert(not IsManagedType(T), 'Only unmanaged record types are supported.');
  Item := Get(AName);
  if (Item = nil) then
    Item := Add(AName)
  else
    Cleanup(Item);

  Item.Kind := vkRecord;
  {$IFDEF DEBUG}
  Item.TypeInfo := TypeInfo(T);
  {$ENDIF}
  GetMem(Item.AsRecord, SizeOf(T));
  T(Item.AsRecord^) := AValue;
end;

procedure TgoPropertyBag.SetAsSingle(const AName: String; const AValue: Single);
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item = nil) then
    Item := Add(AName)
  else
    Cleanup(Item);

  Item.Kind := vkSingle;
  Item.AsSingle := AValue;
end;

procedure TgoPropertyBag.SetAsString(const AName, AValue: String);
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item = nil) then
    Item := Add(AName)
  else
    Cleanup(Item);

  Item.Kind := vkString;
  Assert(Item.AsString = nil);
  String(Item.AsString) := AValue; { Increases ref count }
end;

procedure TgoPropertyBag.SetAsUInt64(const AName: String; const AValue: UInt64);
var
  Item: PItem;
begin
  Item := Get(AName);
  if (Item = nil) then
    Item := Add(AName)
  else
    Cleanup(Item);

  Item.Kind := vkUInt64;
  Item.AsUInt64 := AValue;
end;

end.
