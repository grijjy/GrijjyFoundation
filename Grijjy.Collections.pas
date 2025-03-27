unit Grijjy.Collections;

{$INCLUDE 'Grijjy.inc'}

interface

uses
  System.Generics.Defaults,
  System.Generics.Collections;

type
  { Various utilities that operate on generic dynamic arrays. Mostly used
    internally by various generic collections. }
  TgoArray<T> = class // static
  public
    { Moves items within an array.

      Parameters:
        AArray: the array
        AFromIndex: the source index into AArray
        AToIndex: the destination index into AArray
        ACount: the number of elements to move.

      You should use this utility instead of System.Move since it correctly
      handles elements with [weak] references.

      @bold(Note): no range checking is performed on the arguments. }
    class procedure Move(var AArray: TArray<T>; const AFromIndex, AToIndex,
      ACount: Integer); overload; static;

    { Moves items from one array to another.

      Parameters:
        AFromArray: the source array
        AFromIndex: the source index into AFromArray
        AToArray: the destination array
        AToIndex: the destination index into AToArray
        ACount: the number of elements to move.

      You should use this utility instead of System.Move since it correctly
      handles elements with [weak] references.

      @bold(Note): no range checking is performed on the arguments. }
    class procedure Move(const AFromArray: TArray<T>; const AFromIndex: Integer;
      var AToArray: TArray<T>; const AToIndex, ACount: Integer); overload; static;

    { Finalizes an element in an array.

      Parameters:
        AArray: the array containing the element to finalize.
        AIndex: the index of the element to finalize.

      You should call this utility to mark an element in an array as "unused".
      This prevents memory problems when the array contains elements that are
      reference counted or contain [weak] references. In those cases, the
      element will be set to all zero's. If the array contains "regular"
      elements, then this method does nothing.

      @bold(Note): no range checking is performed on the arguments. }
    class procedure Finalize(var AArray: TArray<T>;
      const AIndex: Integer); overload; static; inline;

    { Finalizes a range ofelements in an array.

      Parameters:
        AArray: the array containing the elements to finalize.
        AIndex: the index of the first element to finalize.
        ACount: the number of elements to finalize.

      You should call this utility to mark an element in an array as "unused".
      This prevents memory problems when the array contains elements that are
      reference counted or contain [weak] references. In those cases, the
      element will be set to all zero's. If the array contains "regular"
      elements, then this method does nothing.

      @bold(Note): no range checking is performed on the arguments. }
    class procedure Finalize(var AArray: TArray<T>; const AIndex,
      ACount: Integer); overload; static; inline;
  end;

type
  { Generic read-only set. Provides a read-only view of a TgoSet<T> }
  TgoReadOnlySet<T> = class(TEnumerable<T>)
  {$REGION 'Internal Declarations'}
  private const
    EMPTY_HASH = -1;
  private type
    TItem = record
      HashCode: Integer;
      Item: T;
    end;
  private type
    TEnumerator = class(TEnumerator<T>)
    {$REGION 'Internal Declarations'}
    private
      FItems: TArray<TItem>;
      FIndex: Integer;
      FHigh: Integer;
    protected
      { TEnumerator<T> }
      function DoGetCurrent: T; override;
      function DoMoveNext: Boolean; override;
    {$ENDREGION 'Internal Declarations'}
    public
      constructor Create(const AItems: TArray<TItem>);
    end;
  private
    FItems: TArray<TItem>;
    FCount: Integer;
    FComparer: IEqualityComparer<T>;
  {$ENDREGION 'Internal Declarations'}
  public
    { TEnumerable<T> }

    { Copies the items in the set to a dynamic array }
    function ToArray: TArray<T>; override; final;

    { Allow <tt>for..in</tt> enumeration of the items in the set. }
    function DoGetEnumerator: TEnumerator<T>; override;
  public
    { Creates a read-only set using a default comparer. }
    constructor Create; overload;

    { Creates a read-only set using a custom comparer.

      Parameters:
        AComparer: the comparer to use to check for item equality.
          Pass nil to use the default comparer. }
    constructor Create(const AComparer: IEqualityComparer<T>); overload;

    { Checks if the set contains a given item.
      This is an O(1) operation that uses the set's comparer to check for
      equality.

      Parameters:
        AItem: the item to check.

      Returns:
        True if the set contains AItem, False if not. }
    function Contains(const AItem: T): Boolean;

    { The number of items in the set }
    property Count: Integer read FCount;
  end;

type
  { A generic unordered set of values. Is similar to TList<T> in that it
    contains a list of items, but the items are not in any specific order. It
    uses a hash table to quickly lookup items in the set.

    This class is also similar to TDictionary<TKey, TValue>, but with only
    keys and no values.

    This class is typically used when you need to quickly find items in a
    collection, but don't need any specific ordering.

    See also TgoObjectSet<T> for a set that owns its items }
  TgoSet<T> = class(TgoReadOnlySet<T>)
  {$REGION 'Internal Declarations'}
  private
    FGrowThreshold: Integer;
  private
    procedure Resize(ANewSize: Integer);
  protected
    procedure DoRemove(AIndex: Integer; const AMask: Integer); virtual;
  {$ENDREGION 'Internal Declarations'}
  public
    { Adds an item to the set, raising an exception if the set already contains
      the item.

      Parameters:
        AItem: the item to add. }
    procedure Add(const AItem: T);

    { Adds an item to the set if it doesn't exist yet. If the set already
      contains the item, then nothing happens.

      Parameters:
        AItem: the item to add. }
    procedure AddOrSet(const AItem: T);

    { Removes an item from the set. Does nothing if the set does not contain the
      item.

      Parameters:
        AItem: the item to remove. }
    procedure Remove(const AItem: T);

    { Clears the set. }
    procedure Clear; virtual;
  end;

type
  { A specialized TgoSet<T> that can only hold objects.

    This set owns the items in it, meaning it will automatically free any item
    that is removed, unless Extract is used. }
  TgoObjectSet<T: class> = class(TgoSet<T>)
  {$REGION 'Internal Declarations'}
  protected
    procedure DoRemove(AIndex: Integer; const AMask: Integer); override;
  {$ENDREGION 'Internal Declarations'}
  public
    { The destructor will free all items in the set }
    destructor Destroy; override;

    { Clears the set and frees the items in it. }
    procedure Clear; override;

    { Removes and returns an item in the set, @bold(without) freeing it.

      Parameters:
        AItem: the item to extract and remove.

      Returns:
        AItem if the item is in the set, or Default(T) otherwise. }
    function Extract(const AItem: T): T;
  end;

type
  { A ring buffer (aka "circular buffer"). This is a fixed-size buffer as if it
    were connected end-to-end. Lends itself for buffering data streams.

    This is a generic implementation that you can use to buffer any value type
    (such as integers, bytes, floats and records). It does @bold(not) work with
    reference types (such as strings, objects and interfaces).

    All "Count"s used in this class refer the a number of elements (of type T),
    and @bold(not) to a number of bytes (unless T is an 8-bit value). }
  TgoRingBuffer<T: record> = class
  {$REGION 'Internal Declarations'}
  private
    FBuffer: TArray<T>;
    FCapacity: Integer;
    FCount: Integer;
    FReadIndex: Integer;
    FWriteIndex: Integer;
    function GetAvailable: Integer;
  private
    function DoWrite(const AData; const ACount: Integer): Integer;
    function DoTryWrite(const AData; const ACount: Integer): Boolean;
    function DoRead(var AData; const ACount: Integer): Integer;
    function DoTryRead(var AData; const ACount: Integer): Boolean;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a ring buffer of a given size.

      Parameters:
        ACapacity: the number of elements (of type T) that the buffer will hold. }
    constructor Create(const ACapacity: Integer);

    { Writes a data array to the buffer.

      Parameters:
        AData: the data to write to the buffer.

      Returns:
        The number of elements written to the buffer. This may be less than the
        length of AData in case the buffer has become full. }
    function Write(const AData: TArray<T>): Integer; overload;
    function Write(const AData: array of T): Integer; overload;

    { Writes a segment of a data array to the buffer.

      Parameters:
        AData: array containing the data to write to the buffer.
        AIndex: start index into AData.
        ACount: number of elements in AData to write to the buffer, starting at
          AIndex.

      Returns:
        The number of elements written to the buffer. This may be less than
        ACount in case the buffer has become full.

      AIndex and ACount must point to a valid segment in the array. }
    function Write(const AData: TArray<T>; const AIndex, ACount: Integer): Integer; overload;
    function Write(const AData: array of T; const AIndex, ACount: Integer): Integer; overload;

    { Tries to write a data array to the buffer. Either the entire operation
      will succeed or fail. Unlike Write, no data will be written if this
      operation would lead to an overflow.

      Parameters:
        AData: the data to write to the buffer.

      Returns:
        True if the data was successfully written, or False in case the buffer
        would overflow if the data would be written. In that case, no data is
        written to the buffer at all. }
    function TryWrite(const AData: TArray<T>): Boolean; overload;
    function TryWrite(const AData: array of T): Boolean; overload;

    { Tries to write a segment of a data array to the buffer. Either the entire
      operation will succeed or fail. Unlike Write, no data will be written if
      this operation would lead to an overflow.

      Parameters:
        AData: array containing the data to write to the buffer.
        AIndex: start index into AData.
        ACount: number of elements in AData to write to the buffer, starting at
          AIndex.

      Returns:
        True if the data was successfully written, or False in case the buffer
        would overflow if the data would be written. In that case, no data is
        written to the buffer at all.

      AIndex and ACount must point to a valid segment in the array. }
    function TryWrite(const AData: TArray<T>; const AIndex, ACount: Integer): Boolean; overload;
    function TryWrite(const AData: array of T; const AIndex, ACount: Integer): Boolean; overload;

    { Reads to a data array from the buffer.

      Parameters:
        AData: the data array that will be filled with data read from the
          buffer. It will try to read Length(AData) elements to fill the entire
          array.

      Returns:
        The number of elements read from buffer. This may be less than the
        length of AData in case the buffer did not have enough data available. }
    function Read(var AData: TArray<T>): Integer; overload;
    function Read(var AData: array of T): Integer; overload;

    { Reads to a segment of a data array from the buffer.

      Parameters:
        AData: the data array that will be filled with data read from the
          buffer.
        AIndex: start index into AData.
        ACount: the number of elements to read into AData, starting at AIndex.

      Returns:
        The number of elements read from buffer. This may be less than ACount
        in case the buffer did not have enough data available.

      AIndex and ACount must point to a valid segment in the array. }
    function Read(var AData: TArray<T>; const AIndex, ACount: Integer): Integer; overload;
    function Read(var AData: array of T; const AIndex, ACount: Integer): Integer; overload;

    { Tries to read to a data array from the buffer. Either the entire operation
      will succeed or fail. Unlike Read, no data will be read if the buffer does
      not have enough data available.

      Parameters:
        AData: the data array that will be filled with data read from the
          buffer. It will try to read Length(AData) elements to fill the entire
          array.

      Returns:
        True if the data was successfully read, or False if the buffer does not
        have enough data available to read the requested amount. In that case,
        no data is read from the buffer at all. }
    function TryRead(var AData: TArray<T>): Boolean; overload;
    function TryRead(var AData: array of T): Boolean; overload;

    { Tries to read to a segment of a data array from the buffer. Either the
      entire operation will succeed or fail. Unlike Read, no data will be read
      if the buffer does not have enough data available.

      Parameters:
        AData: the data array that will be filled with data read from the
          buffer.
        AIndex: start index into AData.
        ACount: the number of elements to read into AData, starting at AIndex.

      Returns:
        True if the data was successfully read, or False if the buffer does not
        have enough data available to read the requested amount. In that case,
        no data is read from the buffer at all.

      AIndex and ACount must point to a valid segment in the array. }
    function TryRead(var AData: TArray<T>; const AIndex, ACount: Integer): Boolean; overload;
    function TryRead(var AData: array of T; const AIndex, ACount: Integer): Boolean; overload;

    { The capacity of the ring buffer (in number of elements), as passed to the
      constructor. }
    property Capacity: Integer read FCapacity;

    { The number of elements currently in the buffer (available for reading). }
    property Count: Integer read FCount;

    { The number of elements available for writing (= Capacity - Count). }
    property Available: Integer read GetAvailable;
  end;

type
  { Generic record used to define a pointer to a value type. For example, you
    can declare:

    <source>
    var
      FooPtr: TgoPtr<TFoo>.P;
    </source>

    which is internally equivalent to:

    <source>
    var
      FooPtr: ^TFoo;
    </source>

    However, this generic record makes it easier to work with value-type
    collections such as TgoValueList and TgoValueDictionary. Without this
    record type, you would have to write something like:

    <source>
    var
      FooPtr: TgoValueDictionary<Integer, TFoo>.P;
    </source> }
  TgoPtr<T{$IF (RTLVersion < 36)}: record{$ENDIF}> = record
  public type
    P = ^T;
  end;

type
  { A light-weight list of value types (primitive types and records). Differs
    from TList<T> in the following regards:
    * You cannot store reference types (objects, interfaces, strings or dynamic
      arrays) in the list.
    * It is more light-weight since it doesn't support noticications,
      comparers and only checks bounds with assertions (which can be turned off).
    * When requesting an item (using Items, First, Last etc.), it returns a
      @bold(Pointer) to the type instead of the actual type. This can be both
      more efficient, and it allows you to directly modify the item in the list.
    * It grows in increments of 16 instead of doubling its size.

    The pointer is of type TgoPtr<T>.P. It may be easier to declare your
    own pointer type as in <code>PFoo = TgoPtr<TFoo>.P</code>.

    Note that you should not cache these pointers for long-term use as they
    become invalid when you modify the list (add or remove items). }
  TgoValueList<T{$IF (RTLVersion < 36)}: record{$ENDIF}> = class
  public type
    { The pointer type for referencing items in this list. }
    P = TgoPtr<T>.P;
  {$REGION 'Internal Declarations'}
  private type
    TEnumerator = class(TEnumerator<P>)
    {$REGION 'Internal Declarations'}
    private
      FItems: TArray<T>;
      FHigh: Integer;
      FIndex: Integer;
    protected
      { TEnumerator<P> }
      function DoGetCurrent: P; override;
      function DoMoveNext: Boolean; override;
    {$ENDREGION 'Internal Declarations'}
    public
      constructor Create(const AItems: TArray<T>; const ACount: Integer);
    end;
  private
    FItems: TArray<T>;
    FCount: Integer;
    function GetItem(const AIndex: Integer): P;
    procedure SetCount(const Value: Integer);
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a new list. The list is initially emtpy and will grow in
      increments of 16 items. }
    constructor Create;

    { Clears the list. }
    procedure Clear;

    { Adds an item to the end of the list.

      Parameters:
        AValue: the item to add.

      Returns:
        The index of the added item }
    function Add(const AValue: T): Integer;

    { Inserts an item at a given index into the list.

      Parameters:
        AIndex: the location to insert the item. An assertion is used when the
          index is out of bounds.
        AValue: the item to add. }
    procedure Insert(const AIndex: Integer; const AValue: T);

    { Deletes an item from the list.

      Parameters:
        AIndex: the index of the item to delete. An assertion is used when the
          index is out of bounds.}
    procedure Delete(const AIndex: Integer);

    { Deletes a range of items from the list.

      Parameters:
        AIndex: the index of the first item to delete
        ACount: the number of items to delete }
    procedure DeleteRange(const AIndex, ACount: Integer);

    { Returns a pointer to the first item in the list.
      An assertion is used when the list is empty.

      @bold(Note): You should not cache the returned pointer for long-term use
      as it is only valid as long as you don't modify the list. }
    function First: P;

    { Returns a pointer to the last item in the list.
      An assertion is used when the list is empty.

      @bold(Note): You should not cache the returned pointer for long-term use
      as it is only valid as long as you don't modify the list. }
    function Last: P;

    { Allows for <code>for..in</code> enumeration of the list.
      Since the enumerator returns pointers to the items, you use it like this:

      <source>
      var
        Items: TgoValueList<TFoo>;
        Item: TgoPtr<TFoo>.P;
      begin
        // Initialize Items
        for Item in Items do...
      end;
      </source> }
    function GetEnumerator: TEnumerator;

    { The number of items in the list }
    property Count: Integer read FCount write SetCount;

    { The items in the list. Returns a pointer to the requested item.

      Parameters:
        Index: the index of the requested item. An assertion is used when the
          index is out of bounds.

      @bold(Note): You should not cache the returned pointer for long-term use
      as it is only valid as long as you don't modify the list. }
    property Items[const AIndex: Integer]: P read GetItem; default;
  end;

type
  { A light-weight dictionary where the values are of value types (primitive
    types and records). Differs from TDictionary<TKey, TValue> in the
    following regards:
    * The values in the dictionary cannot be reference types (objects,
      interfaces, strings or dynamic arrays).
    * It is more light-weight since it doesn't support noticications and has
      better optimized code.
    * When requesting a value (using TryGetValue or Items), it returns a
      @bold(Pointer) to the type instead of the actual type. This can be both
      more efficient, and it allows you to directly modify the value in the
      dictionary.

    The pointer is of type TgoPtr<TValue>.P. It may be easier to declare your
    own pointer type as in <code>PFoo = TgoPtr<TFoo>.P</code>.

    Note that you should not cache these pointers for long-term use as they
    become invalid when you modify the dictionary (add or remove items). }
  TgoValueDictionary<TKey; TValue{$IF (RTLVersion < 36)}: record{$ENDIF}> = class
  public type
    { The pointer type for referencing values in this dictionary. }
    PValue = TgoPtr<TValue>.P;
  {$REGION 'Internal Declarations'}
  private const
    EMPTY_HASH = -1;
  private type
    TEnumerator = class
    {$REGION 'Internal Declarations'}
    private type
      PValue = TgoPtr<TValue>.P;
    private
      FDictionary: TgoValueDictionary<TKey, TValue>;
      FIndex: Integer;
      FHigh: Integer;
      function GetCurrent: TPair<TKey, PValue>;
    {$ENDREGION 'Internal Declarations'}
    public
      constructor Create(const ADictionary: TgoValueDictionary<TKey, TValue>);
      function MoveNext: Boolean;

      property Current: TPair<TKey, PValue> read GetCurrent;
    end;
  private type
    TKeyEnumerator = class
    {$REGION 'Internal Declarations'}
    private
      FDictionary: TgoValueDictionary<TKey, TValue>;
      FIndex: Integer;
      FHigh: Integer;
      function GetCurrent: TKey;
    {$ENDREGION 'Internal Declarations'}
    public
      constructor Create(const ADictionary: TgoValueDictionary<TKey, TValue>);
      function MoveNext: Boolean;

      property Current: TKey read GetCurrent;
    end;
  private type
    TKeyCollection = class
    {$REGION 'Internal Declarations'}
    private
      [weak] FDictionary: TgoValueDictionary<TKey, TValue>;
    {$ENDREGION 'Internal Declarations'}
    public
      constructor Create(const ADictionary: TgoValueDictionary<TKey, TValue>);
      function GetEnumerator: TKeyEnumerator;
      function ToArray: TArray<TKey>;
    end;
  private type
    TValueEnumerator = class
    {$REGION 'Internal Declarations'}
    public type
      PValue = TgoPtr<TValue>.P;
    private
      FDictionary: TgoValueDictionary<TKey, TValue>;
      FIndex: Integer;
      FHigh: Integer;
      function GetCurrent: PValue;
    {$ENDREGION 'Internal Declarations'}
    public
      constructor Create(const ADictionary: TgoValueDictionary<TKey, TValue>);
      function MoveNext: Boolean;

      property Current: PValue read GetCurrent;
    end;
  private type
    TValueCollection = class
    {$REGION 'Internal Declarations'}
    private
      [weak] FDictionary: TgoValueDictionary<TKey, TValue>;
    {$ENDREGION 'Internal Declarations'}
    public
      constructor Create(const ADictionary: TgoValueDictionary<TKey, TValue>);
      function GetEnumerator: TValueEnumerator;
      function ToArray: TArray<TValue>;
    end;
  private type
    TItem = record
      HashCode: Integer;
      Key: TKey;
      Value: TValue;
    end;
  private
    FItems: TArray<TItem>;
    FCount: Integer;
    FComparer: IEqualityComparer<TKey>;
    FGrowThreshold: Integer;
    FKeys: TKeyCollection;
    FValues: TValueCollection;
  private
    function GetItem(const AKey: TKey): PValue;
    function GetKeys: TKeyCollection;
    function GetValues: TValueCollection;
  private
    procedure Resize(ANewSize: Integer);
    procedure DoRemove(AIndex, AMask: Integer);
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a dictionary using a default comparer}
    constructor Create; overload;

    { Creates a dictionary using a custom comparer.

      Parameters:
        AComparer: the comparer to use to check for item equality.
          Pass nil to use the default comparer. }
    constructor Create(const AComparer: IEqualityComparer<TKey>); overload;

    { Destructor }
    destructor Destroy; override;

    { Add a value to the dictionary for a specified key.

      Parameters:
        AKey: the key
        AValue: the value to add for the key

      Raises:
        EListError if the dictionary already contains the given Key.
        Use AddOrSetValue to overwrite an existing key with a new value. }
    procedure Add(const AKey: TKey; const AValue: TValue);

    { Adds or sets a value in the dictionary for a specified key.

      Parameters:
        AKey: the key
        AValue: the value to set or replace for the key

      If the dictionary already contains a value for the given key, then that
      value is replaced. Otherwise, the value is added to the dictionary. }
    procedure AddOrSetValue(const AKey: TKey; const AValue: TValue);

    { Removes the value for a specified key from the dictionary.

      Parameters:
        AKey: the key to remove

      Returns:
        True if the key was removed, or False if the dictionary does not contain
        the given key. }
    function Remove(const AKey: TKey): Boolean;

    { Clears the dictionary }
    procedure Clear;

    { Tries to get a value for the given key.

      Parameters:
        AKey: the key to search for
        AValue: is set to a pointer to the value associated with the given key,
          or nil if the dictionary does not contain the key.

      Returns:
        True if the dictionary contains the given key. In that case, AValue is
        set to a pointer to the value associated with the key.
        False if the dictionary does not contain the given key. In that case,
        AValue is set to nil.

      @bold(Note): You should not cache the pointer returned in AValue for
      long-term use as it is only valid as long as you don't modify the
      dictionary. }
    function TryGetValue(const AKey: TKey; out AValue: PValue): Boolean;

    { Checks if the dictionary contains a given key.

      Parameters:
        AKey: the key to check.

      Returns:
        True if the dictionary contains AKey, False if not. }
    function ContainsKey(const AKey: TKey): Boolean;

    { Allows for <code>for..in</code> enumeration of pairs in the dictionary.
      The value in each pair is a pointer to the actual value, so you would use
      the enumerator like this:

      <source>
      var
        Dictionary: TgrValueDictionary<String, TFoo>;
        Pair: TPair<String, TgrPtr<TFoo>.P>;
      begin
        // Initialize Dictionary
        for Pair in Dictionary do...
      end;
      </source> }
    function GetEnumerator: TEnumerator;

    { Copies the pairs in the dictionary to a dynamic array }
    function ToArray: TArray<TPair<TKey, TValue>>;

    { Returns the value for a given key, raising an exception if the dictionary
      does not contain the key.

      Parameters:
        AKey: the key to check.

      Returns:
        A pointer to the value for the given key.

      Raises:
        EListError if the dictionary doesn't contain AKey

      @bold(Note): You should not cache the returned pointer for long-term use
      as it is only valid as long as you don't modify the dictionary. }
    property Items[const AKey: TKey]: PValue read GetItem; default;

    { All keys in the dictionary. You can enumerate all keys like this:

      <source>
      var
        Dictionary: TgrValueDictionary<String, TFoo>;
        Key: String;
      begin
        // Initialize Dictionary
        for Key in Dictionary.Keys do...
      end;
      </source> }
    property Keys: TKeyCollection read GetKeys;

    { All values in the dictionary. You can enumerate @bold(pointers) to all
      values like this:

      <source>
      var
        Dictionary: TgrValueDictionary<String, TFoo>;
        Value: TgrPtr<TFoo>.P;
      begin
        // Initialize Dictionary
        for Value in Dictionary.Values do...
      end;
      </source> }
    property Values: TValueCollection read GetValues;

    { The number of items in the dictionary }
    property Count: Integer read FCount;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  System.RTLConsts;

{ TgoArray<T> }

class procedure TgoArray<T>.Finalize(var AArray: TArray<T>; const AIndex,
  ACount: Integer);
begin
  {$IF Defined(WEAKREF)}
  if System.HasWeakRef(T) then
  begin
    System.Finalize(AArray[AIndex], ACount);
    FillChar(AArray[AIndex], ACount * SizeOf(T), 0);
  end
  else
  {$ENDIF}
  if IsManagedType(T) then
    FillChar(AArray[AIndex], ACount * SizeOf(T), 0);
end;

class procedure TgoArray<T>.Finalize(var AArray: TArray<T>;
  const AIndex: Integer);
begin
  {$IF Defined(WEAKREF)}
  if System.HasWeakRef(T) then
  begin
    System.Finalize(AArray[AIndex], 1);
    FillChar(AArray[AIndex], SizeOf(T), 0);
  end
  else
  {$ENDIF}
  if IsManagedType(T) then
    FillChar(AArray[AIndex], SizeOf(T), 0);
end;

class procedure TgoArray<T>.Move(const AFromArray: TArray<T>;
  const AFromIndex: Integer; var AToArray: TArray<T>; const AToIndex,
  ACount: Integer);
{$IFDEF WEAKREF}
var
  I: Integer;
{$ENDIF}
begin
  {$IFDEF WEAKREF}
  if System.HasWeakRef(T) then
  begin
    for I := 0 to ACount - 1 do
      AToArray[AToIndex + I] := AFromArray[AFromIndex + I];
  end
  else
  {$ENDIF}
    System.Move(AFromArray[AFromIndex], AToArray[AToIndex], ACount * SizeOf(T));
end;

class procedure TgoArray<T>.Move(var AArray: TArray<T>; const AFromIndex,
  AToIndex, ACount: Integer);
{$IFDEF WEAKREF}
var
  I: Integer;
{$ENDIF}
begin
  {$IFDEF WEAKREF}
  if System.HasWeakRef(T) then
  begin
    if (ACount > 0) then
    begin
      if (AFromIndex < AToIndex) then
      begin
        for I := ACount - 1 downto 0 do
          AArray[AToIndex + I] := AArray[AFromIndex + I]
      end
      else if (AFromIndex > AToIndex) then
      begin
        for I := 0 to ACount - 1 do
          AArray[AToIndex + I] := AArray[AFromIndex + I];
      end;
    end;
  end
  else
  {$ENDIF}
    System.Move(AArray[AFromIndex], AArray[AToIndex], ACount * SizeOf(T));
end;

{ TgoReadOnlySet<T> }

function TgoReadOnlySet<T>.Contains(const AItem: T): Boolean;
var
  Mask, Index, HashCode, HC: Integer;
begin
  Result := False;
  if (FCount = 0) then
    Exit;

  HashCode := FComparer.GetHashCode(AItem) and $7FFFFFFF;
  Mask := Length(FItems) - 1;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Exit(False);

    if (HC = HashCode) and FComparer.Equals(FItems[Index].Item, AItem) then
      Exit(True);

    Index := (Index + 1) and Mask;
  end;
end;

constructor TgoReadOnlySet<T>.Create;
begin
  Create(nil);
end;

constructor TgoReadOnlySet<T>.Create(const AComparer: IEqualityComparer<T>);
begin
  inherited Create;
  FComparer := AComparer;
  if (FComparer = nil) then
    FComparer := TEqualityComparer<T>.Default;
end;

function TgoReadOnlySet<T>.DoGetEnumerator: TEnumerator<T>;
begin
  Result := TEnumerator.Create(FItems);
end;

function TgoReadOnlySet<T>.ToArray: TArray<T>;
var
  I, Count: Integer;
begin
  SetLength(Result, FCount);
  Count := 0;
  for I := 0 to Length(FItems) - 1 do
  begin
    if (FItems[I].HashCode <> EMPTY_HASH) then
    begin
      Result[Count] := FItems[I].Item;
      Inc(Count);
    end;
  end;
  Assert(Count = FCount);
end;

{ TgoReadOnlySet<T>.TEnumerator }

constructor TgoReadOnlySet<T>.TEnumerator.Create(
  const AItems: TArray<TItem>);
begin
  inherited Create;
  FItems := AItems;
  FHigh := Length(AItems) - 1;
  FIndex := -1;
end;

function TgoReadOnlySet<T>.TEnumerator.DoGetCurrent: T;
begin
  Result := FItems[FIndex].Item;
end;

function TgoReadOnlySet<T>.TEnumerator.DoMoveNext: Boolean;
begin
  while (FIndex < FHigh) do
  begin
    Inc(FIndex);
    if (FItems[FIndex].HashCode <> EMPTY_HASH) then
      Exit(True);
  end;
  Result := False;
end;

{ TgoSet<T> }

procedure TgoSet<T>.Add(const AItem: T);
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount >= FGrowThreshold) then
    Resize(Length(FItems) * 2);

  HashCode := FComparer.GetHashCode(AItem) and $7FFFFFFF;
  Mask := Length(FItems) - 1;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Break;

    if (HC = HashCode) and FComparer.Equals(FItems[Index].Item, AItem) then
      raise EListError.CreateRes(@SGenericDuplicateItem);

    Index := (Index + 1) and Mask;
  end;

  FItems[Index].HashCode := HashCode;
  FItems[Index].Item := AItem;
  Inc(FCount);
end;

procedure TgoSet<T>.AddOrSet(const AItem: T);
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount >= FGrowThreshold) then
    { NOTE: Resizing operation may not be needed if key is already in list.
      But this simplifies the code and makes it faster. }
    Resize(Length(FItems) * 2);

  HashCode := FComparer.GetHashCode(AItem) and $7FFFFFFF;
  Mask := Length(FItems) - 1;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Break;

    if (HC = HashCode) and FComparer.Equals(FItems[Index].Item, AItem) then
      Exit;

    Index := (Index + 1) and Mask;
  end;

  FItems[Index].HashCode := HashCode;
  FItems[Index].Item := AItem;
  Inc(FCount);
end;

procedure TgoSet<T>.Clear;
begin
  FItems := nil;
  FCount := 0;
  FGrowThreshold := 0;
end;

procedure TgoSet<T>.DoRemove(AIndex: Integer; const AMask: Integer);
var
  Gap, HC, Bucket: Integer;
begin
  FItems[AIndex].HashCode := EMPTY_HASH;

  Gap := AIndex;
  while True do
  begin
    AIndex := (AIndex + 1) and AMask;

    HC := FItems[AIndex].HashCode;
    if (HC = EMPTY_HASH) then
      Break;

    Bucket := HC and AMask;
    if (not InCircularRange(Gap, Bucket, AIndex)) then
    begin
      FItems[Gap] := FItems[AIndex];
      Gap := AIndex;
      FItems[Gap].HashCode := EMPTY_HASH;
    end;
  end;

  FItems[Gap].HashCode := EMPTY_HASH;

  if IsManagedType(T) then
    FItems[Gap].Item := Default(T);

  Dec(FCount);
end;

procedure TgoSet<T>.Remove(const AItem: T);
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount = 0) then
    Exit;

  HashCode := FComparer.GetHashCode(AItem) and $7FFFFFFF;
  Mask := Length(FItems) - 1;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Break;

    if (HC = HashCode) and FComparer.Equals(FItems[Index].Item, AItem) then
    begin
      DoRemove(Index, Mask);
      Exit;
    end;

    Index := (Index + 1) and Mask;
  end;
end;

procedure TgoSet<T>.Resize(ANewSize: Integer);
var
  NewMask, I, NewIndex: Integer;
  OldItems, NewItems: TArray<TItem>;
begin
  if (ANewSize < 4) then
    ANewSize := 4;
  NewMask := ANewSize - 1;
  SetLength(NewItems, ANewSize);
  for I := 0 to ANewSize - 1 do
    NewItems[I].HashCode := EMPTY_HASH;
  OldItems := FItems;

  for I := 0 to Length(OldItems) - 1 do
  begin
    if (OldItems[I].HashCode <> EMPTY_HASH) then
    begin
      NewIndex := OldItems[I].HashCode and NewMask;
      while (NewItems[NewIndex].HashCode <> EMPTY_HASH) do
        NewIndex := (NewIndex + 1) and NewMask;
      NewItems[NewIndex] := OldItems[I];
    end;
  end;

  FItems := NewItems;
  FGrowThreshold := (ANewSize * 3) shr 2; // 75%
end;

{ TgoObjectSet<T> }

procedure TgoObjectSet<T>.Clear;
var
  I: Integer;
  Item: T;
begin
  for I := 0 to Length(FItems) - 1 do
  begin
    if (FItems[I].HashCode <> EMPTY_HASH) then
    begin
      Item := FItems[I].Item;
      PObject(@Item)^.Free;
    end;
  end;
  inherited;
end;

destructor TgoObjectSet<T>.Destroy;
begin
  Clear;
  inherited;
end;

procedure TgoObjectSet<T>.DoRemove(AIndex: Integer; const AMask: Integer);
var
  Gap, HC, Bucket: Integer;
  Item: T;
begin
  FItems[AIndex].HashCode := EMPTY_HASH;
  Item := FItems[AIndex].Item;

  Gap := AIndex;
  while True do
  begin
    AIndex := (AIndex + 1) and AMask;

    HC := FItems[AIndex].HashCode;
    if (HC = EMPTY_HASH) then
      Break;

    Bucket := HC and AMask;
    if (not InCircularRange(Gap, Bucket, AIndex)) then
    begin
      FItems[Gap] := FItems[AIndex];
      Gap := AIndex;
      FItems[Gap].HashCode := EMPTY_HASH;
    end;
  end;

  FItems[Gap].HashCode := EMPTY_HASH;

  if IsManagedType(T) then
    FItems[Gap].Item := Default(T);

  PObject(@Item)^.Free;

  Dec(FCount);
end;

function TgoObjectSet<T>.Extract(const AItem: T): T;
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount = 0) then
  begin
    Result := Default(T);
    Exit;
  end;

  Mask := Length(FItems) - 1;
  HashCode := FComparer.GetHashCode(AItem) and $7FFFFFFF;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].HashCode;
    if (HC = EMPTY_HASH) then
    begin
      Result := Default(T);
      Exit;
    end;

    if (HC = HashCode) and FComparer.Equals(FItems[Index].Item, AItem) then
    begin
      Result := AItem;
      inherited DoRemove(Index, Mask); { Inherited version doesn't free item }
      Exit;
    end;

    Index := (Index + 1) and Mask;
  end;
end;

{ TgoRingBuffer<T> }

constructor TgoRingBuffer<T>.Create(const ACapacity: Integer);
begin
  Assert(not IsManagedType(T));
  inherited Create;
  FCapacity := ACapacity;
  SetLength(FBuffer, ACapacity);
end;

function TgoRingBuffer<T>.DoRead(var AData; const ACount: Integer): Integer;
var
  ElementsRemaining, ElementsInFirstSegment: Integer;
  Target: PByte;
begin
  { We can read at most FCount elements. }
  ElementsRemaining := Min(ACount, FCount);
  Result := ElementsRemaining;
  Target := @AData;
  if (ElementsRemaining > 0) then
  begin
    Dec(FCount, ElementsRemaining);

    { We may have to wrap around the buffer and read two segments }
    ElementsInFirstSegment := Min(ElementsRemaining, FCapacity - FReadIndex);
    if (ElementsInFirstSegment > 0) then
    begin
      { Read first segment }
      Move(FBuffer[FReadIndex], Target^, ElementsInFirstSegment * SizeOf(T));
      Inc(Target, ElementsInFirstSegment * SizeOf(T));
      Inc(FReadIndex, ElementsInFirstSegment);
      Dec(ElementsRemaining, ElementsInFirstSegment);
    end;

    if (ElementsRemaining > 0) then
    begin
      { Read second segment }
      Move(FBuffer[0], Target^, ElementsRemaining * SizeOf(T));
      FReadIndex := ElementsRemaining;
    end;
  end;
end;

function TgoRingBuffer<T>.DoTryRead(var AData; const ACount: Integer): Boolean;
begin
  Result := (ACount <= FCount);
  if (Result) then
    DoRead(AData, ACount);
end;

function TgoRingBuffer<T>.DoTryWrite(const AData; const ACount: Integer): Boolean;
begin
  Result := (ACount <= (FCapacity - FCount));
  if (Result) then
    DoWrite(AData, ACount);
end;

function TgoRingBuffer<T>.DoWrite(const AData; const ACount: Integer): Integer;
var
  ElementsRemaining, ElementsInFirstSegment: Integer;
  Source: PByte;
begin
  { We can write at most (FCapacity - FCount) elements. }
  ElementsRemaining := Min(ACount, FCapacity - FCount);
  Result := ElementsRemaining;
  Source := @AData;
  if (ElementsRemaining > 0) then
  begin
    Inc(FCount, ElementsRemaining);

    { We may have to wrap around the buffer and write two segments }
    ElementsInFirstSegment := Min(ElementsRemaining, FCapacity - FWriteIndex);
    if (ElementsInFirstSegment > 0) then
    begin
      { Write first segment }
      Move(Source^, FBuffer[FWriteIndex], ElementsInFirstSegment * SizeOf(T));
      Inc(Source, ElementsInFirstSegment * SizeOf(T));
      Inc(FWriteIndex, ElementsInFirstSegment);
      Dec(ElementsRemaining, ElementsInFirstSegment);
    end;

    if (ElementsRemaining > 0) then
    begin
      { Write second segment }
      Move(Source^, FBuffer[0], ElementsRemaining * SizeOf(T));
      FWriteIndex := ElementsRemaining;
    end;
  end;
end;

function TgoRingBuffer<T>.GetAvailable: Integer;
begin
  Result := FCapacity - FCount;
end;

function TgoRingBuffer<T>.Read(var AData: TArray<T>; const AIndex,
  ACount: Integer): Integer;
begin
  Assert((AIndex >= 0) and (AIndex < Length(AData)));
  Assert((ACount >= 0) and ((AIndex + ACount) <= Length(AData)));
  Result := DoRead(AData[AIndex], ACount);
end;

function TgoRingBuffer<T>.Read(var AData: TArray<T>): Integer;
begin
  Result := DoRead(AData[0], Length(AData));
end;

function TgoRingBuffer<T>.Read(var AData: array of T; const AIndex,
  ACount: Integer): Integer;
begin
  Assert((AIndex >= 0) and (AIndex < Length(AData)));
  Assert((ACount >= 0) and ((AIndex + ACount) <= Length(AData)));
  Result := DoRead(AData[AIndex], ACount);
end;

function TgoRingBuffer<T>.Read(var AData: array of T): Integer;
begin
  Result := DoRead(AData[0], Length(AData));
end;

function TgoRingBuffer<T>.TryRead(var AData: array of T): Boolean;
begin
  Result := DoTryRead(AData[0], Length(AData));
end;

function TgoRingBuffer<T>.TryRead(var AData: TArray<T>): Boolean;
begin
  Result := DoTryRead(AData[0], Length(AData));
end;

function TgoRingBuffer<T>.TryRead(var AData: TArray<T>; const AIndex,
  ACount: Integer): Boolean;
begin
  Assert((AIndex >= 0) and (AIndex < Length(AData)));
  Assert((ACount >= 0) and ((AIndex + ACount) <= Length(AData)));
  Result := DoTryRead(AData[AIndex], ACount);
end;

function TgoRingBuffer<T>.TryRead(var AData: array of T; const AIndex,
  ACount: Integer): Boolean;
begin
  Assert((AIndex >= 0) and (AIndex < Length(AData)));
  Assert((ACount >= 0) and ((AIndex + ACount) <= Length(AData)));
  Result := DoTryRead(AData[AIndex], ACount);
end;

function TgoRingBuffer<T>.TryWrite(const AData: array of T; const AIndex,
  ACount: Integer): Boolean;
begin
  Assert((AIndex >= 0) and (AIndex < Length(AData)));
  Assert((ACount >= 0) and ((AIndex + ACount) <= Length(AData)));
  Result := DoTryWrite(AData[AIndex], ACount);
end;

function TgoRingBuffer<T>.TryWrite(const AData: TArray<T>): Boolean;
begin
  Result := DoTryWrite(AData[0], Length(AData));
end;

function TgoRingBuffer<T>.TryWrite(const AData: TArray<T>; const AIndex,
  ACount: Integer): Boolean;
begin
  Assert((AIndex >= 0) and (AIndex < Length(AData)));
  Assert((ACount >= 0) and ((AIndex + ACount) <= Length(AData)));
  Result := DoTryWrite(AData[AIndex], ACount);
end;

function TgoRingBuffer<T>.TryWrite(const AData: array of T): Boolean;
begin
  Result := DoTryWrite(AData[0], Length(AData));
end;

function TgoRingBuffer<T>.Write(const AData: array of T; const AIndex,
  ACount: Integer): Integer;
begin
  Assert((AIndex >= 0) and (AIndex < Length(AData)));
  Assert((ACount >= 0) and ((AIndex + ACount) <= Length(AData)));
  Result := DoWrite(AData[AIndex], ACount);
end;

function TgoRingBuffer<T>.Write(const AData: TArray<T>; const AIndex,
  ACount: Integer): Integer;
begin
  Assert((AIndex >= 0) and (AIndex < Length(AData)));
  Assert((ACount >= 0) and ((AIndex + ACount) <= Length(AData)));
  Result := DoWrite(AData[AIndex], ACount);
end;

function TgoRingBuffer<T>.Write(const AData: TArray<T>): Integer;
begin
  Result := DoWrite(AData[0], Length(AData));
end;

function TgoRingBuffer<T>.Write(const AData: array of T): Integer;
begin
  Result := DoWrite(AData[0], Length(AData));
end;

{ TgoValueList<T> }

function TgoValueList<T>.Add(const AValue: T): Integer;
begin
  if (FCount = Length(FItems)) then
    SetLength(FItems, Length(FItems) + 16);
  FItems[FCount] := AValue;
  Result := FCount;
  Inc(FCount);
end;

procedure TgoValueList<T>.Clear;
begin
  FItems := nil;
  FCount := 0;
end;

constructor TgoValueList<T>.Create;
begin
  inherited;
end;

procedure TgoValueList<T>.Delete(const AIndex: Integer);
begin
  Assert((AIndex >= 0) and (AIndex < FCount));
  if IsManagedType(T) then
    FItems[AIndex] := Default(T);

  Dec(FCount);
  if (AIndex < FCount) then
  begin
    TgoArray<T>.Move(FItems, AIndex + 1, AIndex, FCount - AIndex);
    TgoArray<T>.Finalize(FItems, FCount);
  end;
end;

procedure TgoValueList<T>.DeleteRange(const AIndex, ACount: Integer);
var
  TailCount, I: Integer;
begin
  {$IFNDEF NO_RANGE_CHECKS}
  if (AIndex < 0) or (ACount < 0) or (AIndex + ACount > FCount)
    or (AIndex + ACount < 0)
  then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  {$ENDIF}

  if (ACount = 0) then
    Exit;

  if IsManagedType(T) then
    for I := AIndex to AIndex + ACount - 1 do
      FItems[I] := Default(T);

  TailCount := FCount - (AIndex + ACount);
  if (TailCount > 0) then
  begin
    TgoArray<T>.Move(FItems, AIndex + ACount, AIndex, TailCount);
    TgoArray<T>.Finalize(FItems, FCount - ACount, ACount);
  end
  else
    TgoArray<T>.Finalize(FItems, AIndex, ACount);

  Dec(FCount, ACount);
end;

function TgoValueList<T>.First: P;
begin
  Assert(FCount > 0);
  Result := @FItems[0];
end;

function TgoValueList<T>.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(FItems, FCount);
end;

function TgoValueList<T>.GetItem(const AIndex: Integer): P;
begin
  Assert((AIndex >= 0) and (AIndex < FCount));
  Result := @FItems[AIndex];
end;

procedure TgoValueList<T>.Insert(const AIndex: Integer; const AValue: T);
begin
  Assert((AIndex >= 0) and (AIndex <= FCount));
  if (FCount = Length(FItems)) then
    SetLength(FItems, Length(FItems) + 16);

  if (AIndex < FCount) then
  begin
    Move(FItems[AIndex], FItems[AIndex + 1], (FCount - AIndex) * SizeOf(T));
    FillChar(FItems[AIndex], SizeOf(T), 0);
  end;

  FItems[AIndex] := AValue;
  Inc(FCount);
end;

function TgoValueList<T>.Last: P;
begin
  Assert(FCount > 0);
  Result := @FItems[FCount - 1];
end;

procedure TgoValueList<T>.SetCount(const Value: Integer);
begin
  {$IFNDEF NO_RANGE_CHECKS}
  if (Value < 0) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  {$ENDIF}

  if (Value > Length(FItems)) then
    SetLength(FItems, Value);

  if (Value < Count) then
    DeleteRange(Value, Count - Value);

  FCount := Value;
end;

{ TgoValueList<T>.TEnumerator }

constructor TgoValueList<T>.TEnumerator.Create(const AItems: TArray<T>;
  const ACount: Integer);
begin
  inherited Create;
  FItems := AItems;
  FHigh := ACount - 1;
  FIndex := -1;
end;

function TgoValueList<T>.TEnumerator.DoGetCurrent: P;
begin
  Result := @FItems[FIndex];
end;

function TgoValueList<T>.TEnumerator.DoMoveNext: Boolean;
begin
  Result := (FIndex < FHigh);
  if Result then
    Inc(FIndex);
end;

{ TgoValueDictionary<TKey, TValue>.TEnumerator }

constructor TgoValueDictionary<TKey, TValue>.TEnumerator.Create(
  const ADictionary: TgoValueDictionary<TKey, TValue>);
begin
  inherited Create;
  FDictionary := ADictionary;
  FHigh := Length(ADictionary.FItems) - 1;
  FIndex := -1;
end;

function TgoValueDictionary<TKey, TValue>.TEnumerator.GetCurrent: TPair<TKey, PValue>;
begin
  Result.Key := FDictionary.FItems[FIndex].Key;
  Result.Value := @FDictionary.FItems[FIndex].Value;
end;

function TgoValueDictionary<TKey, TValue>.TEnumerator.MoveNext: Boolean;
begin
  while (FIndex < FHigh) do
  begin
    Inc(FIndex);
    if (FDictionary.FItems[FIndex].HashCode <> EMPTY_HASH) then
      Exit(True);
  end;
  Result := False;
end;

{ TgoValueDictionary<TKey, TValue>.TKeyEnumerator }

constructor TgoValueDictionary<TKey, TValue>.TKeyEnumerator.Create(
  const ADictionary: TgoValueDictionary<TKey, TValue>);
begin
  inherited Create;
  FDictionary := ADictionary;
  FHigh := Length(ADictionary.FItems) - 1;
  FIndex := -1;
end;

function TgoValueDictionary<TKey, TValue>.TKeyEnumerator.GetCurrent: TKey;
begin
  Result := FDictionary.FItems[FIndex].Key;
end;

function TgoValueDictionary<TKey, TValue>.TKeyEnumerator.MoveNext: Boolean;
begin
  while (FIndex < FHigh) do
  begin
    Inc(FIndex);
    if (FDictionary.FItems[FIndex].HashCode <> EMPTY_HASH) then
      Exit(True);
  end;
  Result := False;
end;

{ TgoValueDictionary<TKey, TValue>.TKeyCollection }

constructor TgoValueDictionary<TKey, TValue>.TKeyCollection.Create(
  const ADictionary: TgoValueDictionary<TKey, TValue>);
begin
  inherited Create;
  FDictionary := ADictionary;
end;

function TgoValueDictionary<TKey, TValue>.TKeyCollection.GetEnumerator: TKeyEnumerator;
begin
  Result := TKeyEnumerator.Create(FDictionary);
end;

function TgoValueDictionary<TKey, TValue>.TKeyCollection.ToArray: TArray<TKey>;
var
  I, Count: Integer;
begin
  SetLength(Result, FDictionary.FCount);
  Count := 0;
  for I := 0 to Length(FDictionary.FItems) - 1 do
  begin
    if (FDictionary.FItems[I].HashCode <> EMPTY_HASH) then
    begin
      Result[Count] := FDictionary.FItems[I].Key;
      Inc(Count);
    end;
  end;
  Assert(Count = FDictionary.FCount);
end;

{ TgoValueDictionary<TKey, TValue>.TValueEnumerator }

constructor TgoValueDictionary<TKey, TValue>.TValueEnumerator.Create(
  const ADictionary: TgoValueDictionary<TKey, TValue>);
begin
  inherited Create;
  FDictionary := ADictionary;
  FHigh := Length(ADictionary.FItems) - 1;
  FIndex := -1;
end;

function TgoValueDictionary<TKey, TValue>.TValueEnumerator.GetCurrent: PValue;
begin
  Result := @FDictionary.FItems[FIndex].Value;
end;

function TgoValueDictionary<TKey, TValue>.TValueEnumerator.MoveNext: Boolean;
begin
  while (FIndex < FHigh) do
  begin
    Inc(FIndex);
    if (FDictionary.FItems[FIndex].HashCode <> EMPTY_HASH) then
      Exit(True);
  end;
  Result := False;
end;

{ TgoValueDictionary<TKey, TValue>.TValueCollection }

constructor TgoValueDictionary<TKey, TValue>.TValueCollection.Create(
  const ADictionary: TgoValueDictionary<TKey, TValue>);
begin
  inherited Create;
  FDictionary := ADictionary;
end;

function TgoValueDictionary<TKey, TValue>.TValueCollection.GetEnumerator: TValueEnumerator;
begin
  Result := TValueEnumerator.Create(FDictionary);
end;

function TgoValueDictionary<TKey, TValue>.TValueCollection.ToArray: TArray<TValue>;
var
  I, Count: Integer;
begin
  SetLength(Result, FDictionary.FCount);
  Count := 0;
  for I := 0 to Length(FDictionary.FItems) - 1 do
  begin
    if (FDictionary.FItems[I].HashCode <> EMPTY_HASH) then
    begin
      Result[Count] := FDictionary.FItems[I].Value;
      Inc(Count);
    end;
  end;
  Assert(Count = FDictionary.FCount);
end;

{ TgoValueDictionary<TKey, TValue> }

procedure TgoValueDictionary<TKey, TValue>.Add(const AKey: TKey;
  const AValue: TValue);
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount >= FGrowThreshold) then
    Resize(Length(FItems) * 2);

  HashCode := FComparer.GetHashCode(AKey) and $7FFFFFFF;
  Mask := Length(FItems) - 1;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Break;

    if (HC = HashCode) and FComparer.Equals(FItems[Index].Key, AKey) then
      raise EListError.CreateRes(@SGenericDuplicateItem);

    Index := (Index + 1) and Mask;
  end;

  FItems[Index].HashCode := HashCode;
  FItems[Index].Key := AKey;
  FItems[Index].Value := AValue;
  Inc(FCount);
end;

procedure TgoValueDictionary<TKey, TValue>.AddOrSetValue(const AKey: TKey;
  const AValue: TValue);
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount >= FGrowThreshold) then
    { NOTE: Resizing operation may not be needed if key is already in list.
      But this simplifies the code and makes it faster. }
    Resize(Length(FItems) * 2);

  HashCode := FComparer.GetHashCode(AKey) and $7FFFFFFF;
  Mask := Length(FItems) - 1;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Break;

    if (HC = HashCode) and FComparer.Equals(FItems[Index].Key, AKey) then
    begin
      FItems[Index].Value := AValue;
      Exit;
    end;

    Index := (Index + 1) and Mask;
  end;

  FItems[Index].HashCode := HashCode;
  FItems[Index].Key := AKey;
  FItems[Index].Value := AValue;
  Inc(FCount);
end;

procedure TgoValueDictionary<TKey, TValue>.Clear;
begin
  FItems := nil;
  FCount := 0;
  FGrowThreshold := 0;
end;

function TgoValueDictionary<TKey, TValue>.ContainsKey(
  const AKey: TKey): Boolean;
var
  Mask, Index, HashCode, HC: Integer;
begin
  Result := False;
  if (FCount = 0) then
    Exit;

  HashCode := FComparer.GetHashCode(AKey) and $7FFFFFFF;
  Mask := Length(FItems) - 1;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Exit(False);

    if (HC = HashCode) and FComparer.Equals(FItems[Index].Key, AKey) then
      Exit(True);

    Index := (Index + 1) and Mask;
  end;
end;

constructor TgoValueDictionary<TKey, TValue>.Create(
  const AComparer: IEqualityComparer<TKey>);
begin
  inherited Create;
  FComparer := AComparer;
  if (FComparer = nil) then
    FComparer := TEqualityComparer<TKey>.Default;
end;

constructor TgoValueDictionary<TKey, TValue>.Create;
begin
  Create(nil);
end;

destructor TgoValueDictionary<TKey, TValue>.Destroy;
begin
  FKeys.Free;
  FValues.Free;
  inherited;
end;

procedure TgoValueDictionary<TKey, TValue>.DoRemove(AIndex, AMask: Integer);
var
  Gap, HC, Bucket: Integer;
begin
  FItems[AIndex].HashCode := EMPTY_HASH;

  Gap := AIndex;
  while True do
  begin
    AIndex := (AIndex + 1) and AMask;

    HC := FItems[AIndex].HashCode;
    if (HC = EMPTY_HASH) then
      Break;

    Bucket := HC and AMask;
    if (not InCircularRange(Gap, Bucket, AIndex)) then
    begin
      FItems[Gap] := FItems[AIndex];
      Gap := AIndex;
      FItems[Gap].HashCode := EMPTY_HASH;
    end;
  end;

  FItems[Gap].HashCode := EMPTY_HASH;

  if IsManagedType(TKey) then
    FItems[Gap].Key := Default(TKey);

  Dec(FCount);
end;

function TgoValueDictionary<TKey, TValue>.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(Self);
end;

function TgoValueDictionary<TKey, TValue>.GetItem(const AKey: TKey): PValue;
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount = 0) then
    raise EListError.CreateRes(@SGenericItemNotFound);

  HashCode := FComparer.GetHashCode(AKey) and $7FFFFFFF;
  Mask := Length(FItems) - 1;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Break;

    if (HC = HashCode) and FComparer.Equals(FItems[Index].Key, AKey) then
      Exit(@FItems[Index].Value);

    Index := (Index + 1) and Mask;
  end;

  raise EListError.CreateRes(@SGenericItemNotFound);
end;

function TgoValueDictionary<TKey, TValue>.GetKeys: TKeyCollection;
begin
  if (FKeys = nil) then
    FKeys := TKeyCollection.Create(Self);
  Result := FKeys;
end;

function TgoValueDictionary<TKey, TValue>.GetValues: TValueCollection;
begin
  if (FValues = nil) then
    FValues := TValueCollection.Create(Self);
  Result := FValues;
end;

function TgoValueDictionary<TKey, TValue>.Remove(const AKey: TKey): Boolean;
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount = 0) then
    Exit(False);

  HashCode := FComparer.GetHashCode(AKey) and $7FFFFFFF;
  Mask := Length(FItems) - 1;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Break;

    if (HC = HashCode) and FComparer.Equals(FItems[Index].Key, AKey) then
    begin
      DoRemove(Index, Mask);
      Exit(True);
    end;

    Index := (Index + 1) and Mask;
  end;
  Result := False;
end;

procedure TgoValueDictionary<TKey, TValue>.Resize(ANewSize: Integer);
var
  NewMask, I, NewIndex: Integer;
  OldItems, NewItems: TArray<TItem>;
begin
  if (ANewSize < 4) then
    ANewSize := 4;
  NewMask := ANewSize - 1;
  SetLength(NewItems, ANewSize);
  for I := 0 to ANewSize - 1 do
    NewItems[I].HashCode := EMPTY_HASH;
  OldItems := FItems;

  for I := 0 to Length(OldItems) - 1 do
  begin
    if (OldItems[I].HashCode <> EMPTY_HASH) then
    begin
      NewIndex := OldItems[I].HashCode and NewMask;
      while (NewItems[NewIndex].HashCode <> EMPTY_HASH) do
        NewIndex := (NewIndex + 1) and NewMask;
      NewItems[NewIndex] := OldItems[I];
    end;
  end;

  FItems := NewItems;
  FGrowThreshold := (ANewSize * 3) shr 2; // 75%
end;

function TgoValueDictionary<TKey, TValue>.ToArray: TArray<TPair<TKey, TValue>>;
var
  I, Count: Integer;
begin
  SetLength(Result, FCount);
  Count := 0;
  for I := 0 to Length(FItems) - 1 do
  begin
    if (FItems[I].HashCode <> EMPTY_HASH) then
    begin
      Result[Count].Key := FItems[I].Key;
      Result[Count].Value := FItems[I].Value;
      Inc(Count);
    end;
  end;
  Assert(Count = FCount);
end;

function TgoValueDictionary<TKey, TValue>.TryGetValue(const AKey: TKey;
  out AValue: PValue): Boolean;
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount = 0) then
    Exit(False);

  Mask := Length(FItems) - 1;
  HashCode := FComparer.GetHashCode(AKey) and $7FFFFFFF;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FItems[Index].HashCode;
    if (HC = EMPTY_HASH) then
    begin
      AValue := nil;
      Exit(False);
    end;

    if (HC = HashCode) and FComparer.Equals(FItems[Index].Key, AKey) then
    begin
      AValue := @FItems[Index].Value;
      Exit(True);
    end;

    Index := (Index + 1) and Mask;
  end;
end;

end.
