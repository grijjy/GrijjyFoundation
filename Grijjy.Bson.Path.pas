unit Grijjy.Bson.Path;
(*< XPath-like query language for JSON. There is no official JSONPath
  specification, but the most widely used version seems to be one developed by
  Stefan Goessner:

    http://goessner.net/articles/JsonPath/

  @bold(About JSONPath)

  A JSONPath looks like:

    $.store.book[0].title

  or

    $['store']['book'][0]['title']

  Both representations are identical: you can use either dot (.) or bracket ([])
  notation to denote children of a dictionary. Brackets can also be used with
  numerical indices to denote children of an array by index.

  NOTE: JSONPath only uses single quotes (') within brackets. We also allow for
  double quotes (") since these are easier to use in Delphi strings.

  * Every path starts with a $ indicating the root, followed by zero or more
    child operators (. or []). A $ by itself matches the entire document.
  * A child name can be an identifier string or the asterisk (* or '*') wildcard
    to match all children. For example,
      $.store.book[*].author
    matches the authors of all books in the store.
  * In addition to a single dot (.), a double dot (..) can be used to search for
    any descendants instead of immediate children. For example,
      $..author
    matches all authors, regardless of depth. This is called recursive descent.
  * Children can also be accessed by one or more indices between brackets. These
    indices are 0-based and are only used with arrays. You can separate multiple
    indices with comma's. For example,
      $.store.book[0,2,3]
    matches the first, third and fourth books.
  * You can use the slice notation [Start:End:Step] to match a slice (range)
    of children. This matches all children from index Start up to (but not
    including) End, using a given Step size (usually 1). All are optional, but
    at least one value (and colon) must be given:
    * If Start is omitted, it is implied to be 0. A negative value indicates
      an offset from the end of the array.
    * If End is omitted, the slice extracts through the end of the array. A
      negative value indicates and offset from the end of the array.
    * If Step is omitted, is is implied to be 1.
    * Examples:
      * List[2:] matches the third and all following elements.
      * List[-2:] matches the last two elements.
      * List[:2] matches the first two elements.
      * List[:-2] matches all but the last two elements.
      * List[2:-2] matches all elements but the first two and last two.
      * List[-4:-2] matches the 3rd and 4rd elements from the end.
      * List[::2] matches all elements with an even index.

  NOTE: JSONPath also has an @ operator to allow custom script expressions. We
  do not support this operator.

  @Bold(Examples)

  Example document:

    { "store": {
        "book": [
          { "category": "reference",
            "author": "Nigel Rees",
            "title": "Sayings of the Century",
            "price": 8.95
          },
          { "category": "fiction",
            "author": "J. R. R. Tolkien",
            "title": "The Lord of the Rings",
            "isbn": "0-395-19395-8",
            "price": 22.99
          }
        ],
        "bicycle": {
          "color": "red",
          "price": 19.95
        }
      }
    }

  Example paths:

  $                       Matches the root document (a single value)
  $..*                    Matches all members in the document (lots of values)
  $.store.book[*].author  The authors of all books in the store
  $..author               All authors
  $.store.*               All things in store (2 books and a bicycle)
  $.store..price          The price of everything in the store
  $..book[2]              The third book
  $..book[-1:]            The last book in order
  $..book[:2]             The first two books

  @bold(JSONPath in Delphi)

  The JSONPath API is short and simple. It consists of a TgoBsonPath record with
  only a couple of methods.

  For one-off matching, use the static Match method:

    <source>
    var
      Doc: TgoBsonValue;
      Matches: TArray<TgoBsonValue>;
    begin
      Doc := TgoBsonValue.LoadFromJsonFile(...);
      Matches := TgoBsonPath.Match(Doc, '$.store.book[*].author');
    end;
    </source>

  If you plan to use the same path on multiple (sub)documents, then it is faster
  to parse the path once, and then apply it multiple times:

    <source>
    var
      Doc1, Doc2: TgoBsonValue;
      Path: TgoBsonPath;
      Matches1, Matches2: TArray<TgoBsonValue>;
    begin
      Doc1 := TgoBsonValue.Parse(...);
      Doc2 := TgoBsonValue.Parse(...);

      Path := TgoBsonPath.Create('$.store.book[*].author');

      Matches1 := Path.Match(Doc1);
      Matches2 := Path.Match(Doc2);
    end;
    </source>

  You can also run the path on sub-trees:

    <source>
    var
      Doc: TgoBsonDocument;
      Store: TgoBsonValue;
      Matches: TArray<TgoBsonValue>;
    begin
      Doc := TgoBsonDocument.LoadFromJsonFile(...);
      Store := Doc['store'];
      Matches := TgoBsonPath.Match(Store, '$.book[*].author');
    end;
    </source>

  If you are only interested in a single (or the first) match, then you can use
  MatchSingle instead:

    <source>
    var
      Doc, Match: TgoBsonValue;
    begin
      Doc := TgoBsonValue.Parse(...);
      if (TgoBsonPath.MatchSingle(Store, '$.book[*]', Match)) then
        ...
    end;
    </source> *)

{$INCLUDE 'Grijjy.inc'}

interface

uses
  System.SysUtils,
  Grijjy.Bson;

type
  { Exception type that is raised for invalid JSONPath expressions. }
  EgoBsonPathError = class(Exception);

type
  { Creating and executing JSONPath expressions. }
  TgoBsonPath = record
  {$REGION 'Internal Declarations'}
  private type
    TOperatorType = (
      ChildName,        // Name of a child element (as in .store or ['store'])
      ChildIndex,       // Index of a child element (as in [3])
      RecursiveDescent, // .. operator
      Wildcard,         // * operator
      IndexList,        // [a,b,c,...]
      Slice);           // [start:end:step]
  private type
    POperator = ^TOperator;
    TOperator = record
    public
      procedure Init(const AType: TOperatorType);
    public
      OperatorType: TOperatorType;
      Next: POperator;
      Name: String;                      // For ChildName
      Indices: TArray<Integer>;          // For IndexList
      case Byte of
        0: (Index: Integer);             // For ChildIndex
        1: (Start, Stop, Step: Integer); // For Slice
    end;
  private
    FOperators: TArray<TOperator>;
    FOperatorCount: Integer;
    FMatches: TArray<TgoBsonValue>;
    FMatchCount: Integer;
    FSingleMatch: Boolean;
  private
    class procedure SkipWhitespace(var ACur: PChar); inline; static;
    class function ParseInteger(var ACur: PChar; out AValue: Integer): Boolean; static;
    class function IsQuote(const AChar: Char): Boolean; inline; static;
  private
    procedure AddOperator(const AOperator: TOperator);
    procedure AddMatch(const AMatch: TgoBsonValue);
    procedure ParseDotOperator(var ACur: PChar);
    procedure ParseBracketOperator(var ACur: PChar);
    function Match(const ARoot: TgoBsonValue;
      const AMatchSingle: Boolean): TArray<TgoBsonValue>; overload;
    procedure VisitOperator(const AOp: POperator; const ARoot: TgoBsonValue);
  {$ENDREGION 'Internal Declarations'}
  public
    { Parses a JSONPath expression that can be used for matching later.

      Parameters:
        AExpression: the JSONPath expression to parse.

      Raises:
        EgoBsonPathError if AExpression is invalid.

      If you plan to use the same JSONPath expression multiple times, then it
      is faster to parse it just once using this constructor, and execute it
      multiple times using one of the (non-static) Match* methods. }
    constructor Create(const AExpression: String);

    { Executes this JSONPath expression on a JSON value.

      Parameters:
        ARoot: the root TgoBsonValue to use this JSONPath on.

      Returns:
        An array of JSON values that match this JSONPath expression. }
    function Match(const ARoot: TgoBsonValue): TArray<TgoBsonValue>; overload; inline;

    { Executes this JSONPath expression on a JSON value and returns the first
      match.

      Parameters:
        ARoot: the root TgoBsonValue to use this JSONPath on.
        AMatch: is set to the first match found, or a Null value if no match
          is found.

      Returns:
        True if a match is found or False otherwise. }
    function MatchSingle(const ARoot: TgoBsonValue; out AMatch: TgoBsonValue): Boolean; overload; inline;

    { Executes a JSONPath expression on JSON value.

      Parameters:
        ARoot: the root TgoBsonValue to use the expression on.
        AExpression: the JSONPath expression to run.

      Returns:
        An array of JSON values that match this JSONPath expression.

      Raises:
        EgoBsonPathError if AExpression is invalid.

      If you plan to use the same expression multiple times, then it is faster
      to parse it just once using the constructor, and execute it multiple times
      using one of the (non-static) Match* methods. }
    class function Match(const ARoot: TgoBsonValue;
      const AExpression: String): TArray<TgoBsonValue>; overload; static;

    { Executes a JSONPath expression on a JSON value and returns the first match.

      Parameters:
        ARoot: the root TgoBsonValue to use the expression on.
        AExpression: the JSONPath expression to run.
        AMatch: is set to the first match found, or a Null value if no match
          is found.

      Returns:
        True if a match is found or False otherwise.

      Raises:
        EgoBsonPathError if AExpression is invalid.

      If you plan to use the same expression multiple times, then it is faster
      to parse it just once using the constructor, and execute it multiple times
      using one of the (non-static) Match* methods. }
    class function MatchSingle(const ARoot: TgoBsonValue;
      const AExpression: String; out AMatch: TgoBsonValue): Boolean; overload; static;
  end;

resourcestring
  RS_BSON_PATH_INVALID_ROOT = 'A JSON path must start with a root ($) operator.';
  RS_BSON_PATH_DUPLICATE_ROOT = 'Multiple root operators ($) in JSON path.';
  RS_BSON_PATH_INVALID_OPERATOR = 'Operator in JSON path must start with dot (.) or bracket ([).';
  RS_BSON_PATH_MISSING_MEMBER_NAME = 'Child operator in JSON path is missing a member name.';
  RS_BSON_PATH_QUOTE_EXPECTED = 'Missing end quote in JSON path.';
  RS_BSON_PATH_QUOTE_MISMATCH = 'Quote mismatch in JSON path.';
  RS_BSON_PATH_MISSING_CLOSE_BRACKET = 'Missing close bracket (]) in JSON path.';
  RS_BSON_PATH_TOO_MANY_SLICE_ARGUMENTS = 'Too many slice arguments in JSON path.';
  RS_BSON_PATH_INVALID_SLICE_END = 'Invalid slice end value in JSON path.';
  RS_BSON_PATH_INVALID_SLICE_STEP = 'Invalid slice step value in JSON path.';
  RS_BSON_PATH_INVALID_BRACKET_OPERATOR = 'Invalid text between brackets in JSON path.';
  RS_BSON_PATH_INVALID_INDEX = 'Invalid index in JSON path.';
  RS_BSON_PATH_NEGATIVE_ARRAY_INDEX = 'Negative array index in JSON path not allowed.';
  RS_BSON_PATH_INVALID_RECURSIVE_DESCENT = 'Recursive descent operator (..) in JSON path must be followed by another operator.';

implementation

{ TgoBsonPath }

procedure TgoBsonPath.AddMatch(const AMatch: TgoBsonValue);
begin
  if (FMatchCount >= Length(FMatches)) then
  begin
    if (FMatchCount = 0) then
      SetLength(FMatches, 4)
    else
      SetLength(FMatches, FMatchCount * 2);
  end;
  FMatches[FMatchCount] := AMatch;
  Inc(FMatchCount);
end;

procedure TgoBsonPath.AddOperator(const AOperator: TOperator);
var
  I: Integer;
begin
  if (FOperatorCount >= Length(FOperators)) then
  begin
    if (FOperatorCount = 0) then
      SetLength(FOperators, 4)
    else
    begin
      SetLength(FOperators, FOperatorCount * 2);
      for I := 0 to FOperatorCount - 1 do
        FOperators[I].Next := @FOperators[I + 1];
    end;
  end;
  FOperators[FOperatorCount] := AOperator;

  if (FOperatorCount > 0) then
    FOperators[FOperatorCount - 1].Next := @FOperators[FOperatorCount];

  Inc(FOperatorCount);
end;

constructor TgoBsonPath.Create(const AExpression: String);
var
  P: PChar;
begin
  FOperators := nil;
  FOperatorCount := 0;

  if (AExpression = '') then
    raise EgoBsonPathError.Create(RS_BSON_PATH_INVALID_ROOT);

  P := PChar(AExpression);
  SkipWhitespace(P);
  if (P^ <> '$') then
    raise EgoBsonPathError.Create(RS_BSON_PATH_INVALID_ROOT);
  Inc(P);

  while (P^ <> #0) do
  begin
    SkipWhitespace(P);
    if (P^ = '.') then
      ParseDotOperator(P)
    else if (P^ = '[') then
      ParseBracketOperator(P)
    else if (P^ = '$') then
      raise EgoBsonPathError.Create(RS_BSON_PATH_DUPLICATE_ROOT)
    else
      raise EgoBsonPathError.Create(RS_BSON_PATH_INVALID_OPERATOR);
  end;

  if (FOperatorCount > 0)
    and (FOperators[FOperatorCount - 1].OperatorType = TOperatorType.RecursiveDescent)
  then
    raise EgoBsonPathError.Create(RS_BSON_PATH_INVALID_RECURSIVE_DESCENT);
end;

class function TgoBsonPath.IsQuote(const AChar: Char): Boolean;
begin
  Result := (AChar = '''') or (AChar = '"');
end;

function TgoBsonPath.Match(const ARoot: TgoBsonValue): TArray<TgoBsonValue>;
begin
  Result := Match(ARoot, False);
end;

class function TgoBsonPath.Match(const ARoot: TgoBsonValue;
  const AExpression: String): TArray<TgoBsonValue>;
var
  Path: TgoBsonPath;
begin
  if (AExpression = '') then
    Exit;

  Path := TgoBsonPath.Create(AExpression);
  Result := Path.Match(ARoot, False);
end;

function TgoBsonPath.Match(const ARoot: TgoBsonValue;
  const AMatchSingle: Boolean): TArray<TgoBsonValue>;
begin
  if (FOperatorCount = 0) then
    Exit(TArray<TgoBsonValue>.Create(ARoot));

  FMatches := nil;
  FMatchCount := 0;
  FSingleMatch := AMatchSingle;

  VisitOperator(@FOperators[0], ARoot);

  SetLength(FMatches, FMatchCount);
  Result := FMatches;
end;

function TgoBsonPath.MatchSingle(const ARoot: TgoBsonValue;
  out AMatch: TgoBsonValue): Boolean;
var
  Matches: TArray<TgoBsonValue>;
begin
  Matches := Match(ARoot, True);
  if (Matches = nil) then
  begin
    AMatch := TgoBsonNull.Value;
    Exit(False);
  end;

  AMatch := Matches[0];
  Result := True;
end;

class function TgoBsonPath.MatchSingle(const ARoot: TgoBsonValue;
  const AExpression: String; out AMatch: TgoBsonValue): Boolean;
var
  Path: TgoBsonPath;
begin
  if (AExpression = '') then
  begin
    AMatch := TgoBsonNull.Value;
    Exit(False);
  end;

  Path := TgoBsonPath.Create(AExpression);
  Result := Path.MatchSingle(ARoot, AMatch);
end;

procedure TgoBsonPath.ParseBracketOperator(var ACur: PChar);
var
  P, Start, Stop: PChar;
  QuoteChar: Char;
  Op: TOperator;
  I, Count: Integer;
begin
  // Initial '[' has already been parsed
  Assert(ACur^ = '[');
  P := ACur + 1;
  SkipWhitespace(P);

  if IsQuote(P^) then
  begin
    // ['ident'] or ["ident"]
    QuoteChar := P^;
    Inc(P);
    if (P^ = '*') then
    begin
      // ['*'] or ["*"]
      if (not IsQuote(P[1])) then
        raise EgoBsonPathError.Create(RS_BSON_PATH_QUOTE_EXPECTED);

      if (P[1] <> QuoteChar) then
        raise EgoBsonPathError.Create(RS_BSON_PATH_QUOTE_MISMATCH);

      Inc(P, 2);
      SkipWhitespace(P);
      if (P^ <> ']') then
        raise EgoBsonPathError.Create(RS_BSON_PATH_MISSING_CLOSE_BRACKET);

      Op.Init(TOperatorType.Wildcard);
      AddOperator(Op);
      Inc(P);
    end
    else
    begin
      // ['ident'] or ["ident"]
      Start := P;

      // Scan for end quote
      while (P^ <> #0) and (not IsQuote(P^)) do
        Inc(P);

      if (P^ = #0) then
        raise EgoBsonPathError.Create(RS_BSON_PATH_QUOTE_EXPECTED);

      if (P = Start) then
        raise EgoBsonPathError.Create(RS_BSON_PATH_MISSING_MEMBER_NAME);

      if (P^ <> QuoteChar) then
        raise EgoBsonPathError.Create(RS_BSON_PATH_QUOTE_MISMATCH);

      Stop := P;
      Inc(P);
      SkipWhitespace(P);
      if (P^ <> ']') then
        raise EgoBsonPathError.Create(RS_BSON_PATH_MISSING_CLOSE_BRACKET);

      Op.Init(TOperatorType.ChildName);
      SetString(Op.Name, Start, Stop - Start);
      AddOperator(Op);
      Inc(P);
    end;
  end
  else if (P^ = '*') then
  begin
    // [*]
    Inc(P);
    SkipWhitespace(P);
    if (P^ <> ']') then
      raise EgoBsonPathError.Create(RS_BSON_PATH_MISSING_CLOSE_BRACKET);

    Op.Init(TOperatorType.Wildcard);
    AddOperator(Op);
    Inc(P);
  end
  else
  begin
    // [index]
    // [index, index, ...]
    // [start:end:step]
    Op.Init(TOperatorType.Wildcard); // Temporary
    if (not ParseInteger(P, I)) then
    begin
      // [:end:step]
      SkipWhitespace(P);
      if (P^ <> ':') then
        raise EgoBsonPathError.Create(RS_BSON_PATH_INVALID_BRACKET_OPERATOR);

      Op.Init(TOperatorType.Slice);
    end
    else
    begin
      // [index]
      // [index, index, ...]
      SkipWhitespace(P);
      if (P^ = ']') then
      begin
        // [index]
        if (I < 0) then
          raise EgoBsonPathError.Create(RS_BSON_PATH_NEGATIVE_ARRAY_INDEX);
        Op.Init(TOperatorType.ChildIndex);
        Op.Index := I;
      end
      else if (P^ = ',') then
      begin
        // [index, index, ...]
        if (I < 0) then
          raise EgoBsonPathError.Create(RS_BSON_PATH_NEGATIVE_ARRAY_INDEX);
        Op.Init(TOperatorType.IndexList);
        SetLength(Op.Indices, 4);
        Op.Indices[0] := I;
        Count := 1;

        while True do
        begin
          Inc(P);
          SkipWhitespace(P);
          if (not ParseInteger(P, I)) then
            raise EgoBsonPathError.Create(RS_BSON_PATH_INVALID_INDEX);

          if (I < 0) then
            raise EgoBsonPathError.Create(RS_BSON_PATH_NEGATIVE_ARRAY_INDEX);

          if (Count >= Length(Op.Indices)) then
            SetLength(Op.Indices, Count * 2);
          Op.Indices[Count] := I;
          Inc(Count);

          if (P^ = ']') then
            Break;

          if (P^ <> ',') then
            raise EgoBsonPathError.Create(RS_BSON_PATH_INVALID_INDEX);
        end;
        SetLength(Op.Indices, Count);
      end
      else
      begin
        if (P^ <> ':') then
          raise EgoBsonPathError.Create(RS_BSON_PATH_INVALID_BRACKET_OPERATOR);

        // [start:end:step]
        Op.Init(TOperatorType.Slice);
        Op.Start := I;
      end;
    end;

    if (Op.OperatorType = TOperatorType.Slice) and (P^ = ':') then
    begin
      // Parse :end part of slice
      Inc(P);
      SkipWhitespace(P);
      if (not ParseInteger(P, I)) then
      begin
        if (P^ <> ':') and (P^ <> ']') then
          raise EgoBsonPathError.Create(RS_BSON_PATH_INVALID_SLICE_END);
      end
      else
        Op.Stop := I;

      Op.Step := 1;
      if (P^ = ':') then
      begin
        // Parse :step part of slice
        Inc(P);
        SkipWhitespace(P);
        if (not ParseInteger(P, I)) and (P^ <> ']') then
          raise EgoBsonPathError.Create(RS_BSON_PATH_INVALID_SLICE_STEP);

        Op.Step := I;
      end;

      if (P^ = ':') then
        raise EgoBsonPathError.Create(RS_BSON_PATH_TOO_MANY_SLICE_ARGUMENTS);

      if (P^ <> ']') then
        raise EgoBsonPathError.Create(RS_BSON_PATH_MISSING_CLOSE_BRACKET);
    end;

    AddOperator(Op);
    Inc(P);
  end;

  ACur := P;
end;

procedure TgoBsonPath.ParseDotOperator(var ACur: PChar);
var
  P, Start: PChar;
  Op: TOperator;
begin
  // Initial '.' has already been parsed
  Assert(ACur^ = '.');
  P := ACur + 1;

  if (P^ = '.') then
  begin
    // ..
    Op.Init(TOperatorType.RecursiveDescent);
    AddOperator(Op);
  end
  else if (P^ = '*') then
  begin
    // .*
    Op.Init(TOperatorType.Wildcard);
    AddOperator(Op);
    Inc(P);
  end
  else
  begin
    // .ident
    Start := P;

    // Scan for start of next operator
    while (P^ <> #0) and (P^ <> '.') and (P^ <> '[') do
      Inc(P);

    if (P = Start) then
      raise EgoBsonPathError.Create(RS_BSON_PATH_MISSING_MEMBER_NAME);

    Op.Init(TOperatorType.ChildName);
    SetString(Op.Name, Start, P - Start);
    AddOperator(Op);
  end;

  ACur := P;
end;

class function TgoBsonPath.ParseInteger(var ACur: PChar;
  out AValue: Integer): Boolean;
var
  P: PChar;
  C: Char;
  IsNegative: Boolean;
  Value: Integer;
begin
  P := ACur;
  SkipWhitespace(P);

  IsNegative := False;
  if (P^ = '-') then
  begin
    IsNegative := True;
    Inc(P);
  end;

  C := P^;
  if (C < '0') or (C > '9') then
    Exit(False);

  Value := Ord(C) - Ord('0');
  Inc(P);

  while True do
  begin
    C := P^;
    if (C < '0') or (C > '9') then
      Break;

    Value := (Value * 10) + (Ord(C) - Ord('0'));
    Inc(P);
  end;

  if IsNegative then
    Value := -Value;

  SkipWhitespace(P);
  ACur := P;
  AValue := Value;
  Result := True;
end;

class procedure TgoBsonPath.SkipWhitespace(var ACur: PChar);
begin
  while (ACur^ <= ' ') and (ACur^ <> #0) do
    Inc(ACur);
end;

procedure TgoBsonPath.VisitOperator(const AOp: POperator; const ARoot: TgoBsonValue);
var
  I, Index, Start, Stop: Integer;
  Value: TgoBsonValue;
  Arr: TgoBsonArray;
  Doc: TgoBsonDocument;
  Element: TgoBsonElement;
  NextOp: POperator;
begin
  Assert(Assigned(AOp));
  if (FSingleMatch) and (FMatchCount <> 0) then
    Exit;

  case AOp.OperatorType of
    TOperatorType.ChildName:
      if ARoot.IsBsonDocument and ARoot.AsBsonDocument.TryGetValue(AOp.Name, Value) then
      begin
        if (AOp.Next = nil) then
          AddMatch(Value)
        else
          VisitOperator(AOp.Next, Value);
      end;

    TOperatorType.ChildIndex:
      if ARoot.IsBsonArray then
      begin
        Assert(AOp.Index >= 0);
        Arr := ARoot.AsBsonArray;
        if (AOp.Index < Arr.Count) then
        begin
          Value := Arr[AOp.Index];
          if (AOp.Next = nil) then
            AddMatch(Value)
          else
            VisitOperator(AOp.Next, Value);
        end;
      end;

    TOperatorType.RecursiveDescent:
      begin
        NextOp := AOp.Next;
        Assert(Assigned(NextOp));
        case ARoot.BsonType of
          TgoBsonType.&Array:
            begin
              Arr := ARoot.AsBsonArray;
              for I := 0 to Arr.Count - 1 do
              begin
                if (NextOp.OperatorType = TOperatorType.ChildIndex)
                  and (NextOp.Index = I)
                then
                  VisitOperator(NextOp, ARoot)
                else
                  VisitOperator(AOp, Arr[I]);
              end;
            end;

          TgoBsonType.Document:
            begin
              Doc := ARoot.AsBsonDocument;
              for I := 0 to Doc.Count - 1 do
              begin
                Element := Doc.Elements[I];
                if(NextOp.OperatorType = TOperatorType.ChildName)
                  and (NextOp.Name = Element.Name)
                then
                  VisitOperator(NextOp, ARoot)
                else
                  VisitOperator(AOp, Element.Value);
              end;
            end;
        end;
      end;

    TOperatorType.Wildcard:
      case ARoot.BsonType of
        TgoBsonType.&Array:
          begin
            Arr := ARoot.AsBsonArray;
            for I := 0 to Arr.Count - 1 do
            begin
              Value := Arr[I];
              if (AOp.Next = nil) then
                AddMatch(Value)
              else
                VisitOperator(AOp.Next, Value);
            end;
          end;

        TgoBsonType.Document:
          begin
            Doc := ARoot.AsBsonDocument;
            for I := 0 to Doc.Count - 1 do
            begin
              Element := Doc.Elements[I];
              if (AOp.Next = nil) then
                AddMatch(Element.Value)
              else
                VisitOperator(AOp.Next, Element.Value);
            end;
          end;
      end;

    TOperatorType.IndexList:
      if ARoot.IsBsonArray then
      begin
        Arr := ARoot.AsBsonArray;
        for I := 0 to Length(AOp.Indices) - 1 do
        begin
          Index := AOp.Indices[I];
          Assert(Index >= 0);
          if (Index < Arr.Count) then
          begin
            Value := Arr[Index];
            if (AOp.Next = nil) then
              AddMatch(Value)
            else
              VisitOperator(AOp.Next, Value);
          end;
        end;
      end;

    TOperatorType.Slice:
      if ARoot.IsBsonArray then
      begin
        Arr := ARoot.AsBsonArray;
        if (AOp.Start < 0) then
        begin
          Start := Arr.Count + AOp.Start;
          Stop := Arr.Count + AOp.Stop;
        end
        else
        begin
          Start := AOp.Start;
          Stop := AOp.Stop;
        end;

        if (Stop > Arr.Count) then
          Stop := Arr.Count;

        I := Start;
        Assert(AOp.Step > 0);
        while (I < Stop) do
        begin
          Value := Arr[I];
          if (AOp.Next = nil) then
            AddMatch(Value)
          else
            VisitOperator(AOp.Next, Value);

          Inc(I, AOp.Step);
        end;
      end
  else
    Assert(False);
  end;
end;

{ TgoBsonPath.TOperator }

procedure TgoBsonPath.TOperator.Init(const AType: TOperatorType);
begin
  OperatorType := AType;
  Next := nil;
  Name := '';
  Indices := [];
  Start := 0;
  Stop := 0;
  Step := 0;
end;

end.
