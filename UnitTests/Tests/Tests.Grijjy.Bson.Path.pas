unit Tests.Grijjy.Bson.Path;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Grijjy.Bson,
  Grijjy.Bson.Path;

type
  TestBsonPathErrors = class
  private
    procedure TestFail(const AExpression: String);
  public
    [Test] procedure TestInvalidRoot;
    [Test] procedure TestInvalidOperator;
    [Test] procedure TestMissingMember;
    [Test] procedure TestMissingWildcardQuote;
    [Test] procedure TestWildcardQuoteMismatch;
    [Test] procedure TestWildcardMissingCloseBracket;
    [Test] procedure TestWildcardMissingCloseBracket2;
    [Test] procedure TestMissingNameQuote;
    [Test] procedure TestNameQuoteMismatch;
    [Test] procedure TestNameMissingCloseBracket;
    [Test] procedure TestEmptyName;
    [Test] procedure TestIndexMissingCloseBracket;
    [Test] procedure TestNegativeIndex;
    [Test] procedure TestNegativeListIndex;
    [Test] procedure TestTooManySliceArguments;
    [Test] procedure TestInvalidSliceStart;
    [Test] procedure TestInvalidSliceEnd;
    [Test] procedure TestInvalidSliceStep;
    [Test] procedure TestInvalidBracketOperator;
    [Test] procedure TestInvalidIndex;
    [Test] procedure TestInvalidIndexDelimiter;
    [Test] procedure TestSliceMissingCloseBracket;
    [Test] procedure TestIndicesMissingCloseBracket;
    [Test] procedure TestInvalidRecursiveDescent;
  end;

type
  TestBsonPathBase = class
  protected
    FDoc: TgoBsonValue;
    procedure Test(const AExpression: String;
      const AExpected: array of String);
  end;

type
  TestBsonPathExamples = class(TestBsonPathBase)
  public
    [Setup] procedure Setup;
    [Teardown] procedure Teardown;
    [Test] procedure TestMatchRoot;
    [Test] procedure TestMatchTitleOfFirstBookDot;
    [Test] procedure TestMatchTitleOfFirstBookBracket;
    [Test] procedure TestMatchAllAuthors;
    [Test] procedure TestMatchAuthorsFromAllBooks;
    [Test] procedure TestMatchAllThingsInStore;
    [Test] procedure TestMatchPriceOfAllThingsInStore;
    [Test] procedure TestMatchThirdBook;
    [Test] procedure TestMatchLastBook;
    [Test] procedure TestMatchFirstTwoBooksUsingSlice;
    [Test] procedure TestMatchFirstTwoBooksUsingList;
    [Test] procedure TestMatchAllBooks;
    [Test] procedure TestSingleMatch;
  end;

type
  TesBJsonPath = class(TestBsonPathBase)
  public
    [Test] procedure Test1;
    [Test] procedure Test2;
    [Test] procedure Test3;
  end;

implementation

const
  JSON =
    '{ "store": {'#10+
    '    "book": [ '#10+
    '      { "category": "reference",'#10+
    '        "author": "Nigel Rees",'#10+
    '        "title": "Sayings of the Century",'#10+
    '        "price": 8.95'#10+
    '      },'#10+
    '      { "category": "fiction",'#10+
    '        "author": "Evelyn Waugh",'#10+
    '        "title": "Sword of Honour",'#10+
    '        "price": 12.99'#10+
    '      },'#10+
    '      { "category": "fiction",'#10+
    '        "author": "Herman Melville",'#10+
    '        "title": "Moby Dick",'#10+
    '        "isbn": "0-553-21311-3",'#10+
    '        "price": 8.99'#10+
    '      },'#10+
    '      { "category": "fiction",'#10+
    '        "author": "J. R. R. Tolkien",'#10+
    '        "title": "The Lord of the Rings",'#10+
    '        "isbn": "0-395-19395-8",'#10+
    '        "price": 22.99'#10+
    '      }'#10+
    '    ],'#10+
    '    "bicycle": {'#10+
    '      "color": "red",'#10+
    '      "price": 19.95'#10+
    '    }'#10+
    '  }'#10+
    '}';

{ TestBsonPathErrors }

procedure TestBsonPathErrors.TestEmptyName;
begin
  TestFail('$[""]');
end;

procedure TestBsonPathErrors.TestFail(const AExpression: String);
begin
  Assert.WillRaise(
    procedure
    begin
      TgoBsonPath.Create(AExpression);
    end, EgoBsonPathError);
end;

procedure TestBsonPathErrors.TestIndexMissingCloseBracket;
begin
  TestFail('$[1');
end;

procedure TestBsonPathErrors.TestIndicesMissingCloseBracket;
begin
  TestFail('$[1,2,3');
end;

procedure TestBsonPathErrors.TestInvalidBracketOperator;
begin
  TestFail('$[store]');
end;

procedure TestBsonPathErrors.TestInvalidIndex;
begin
  TestFail('$[1,2,a,4]');
end;

procedure TestBsonPathErrors.TestInvalidIndexDelimiter;
begin
  TestFail('$[1,2;4]');
end;

procedure TestBsonPathErrors.TestInvalidOperator;
begin
  TestFail('$store');
end;

procedure TestBsonPathErrors.TestInvalidRecursiveDescent;
begin
  TestFail('$..');
end;

procedure TestBsonPathErrors.TestInvalidRoot;
begin
  TestFail('.store.*');
end;

procedure TestBsonPathErrors.TestInvalidSliceEnd;
begin
  TestFail('$[1:a:3]');
end;

procedure TestBsonPathErrors.TestInvalidSliceStart;
begin
  TestFail('$[a:2:3]');
end;

procedure TestBsonPathErrors.TestInvalidSliceStep;
begin
  TestFail('$[1:2:a]');
end;

procedure TestBsonPathErrors.TestMissingMember;
begin
  TestFail('$.store.');
end;

procedure TestBsonPathErrors.TestMissingNameQuote;
begin
  TestFail('$["store]');
end;

procedure TestBsonPathErrors.TestMissingWildcardQuote;
begin
  TestFail('$["*]');
end;

procedure TestBsonPathErrors.TestNameMissingCloseBracket;
begin
  TestFail('$["store"');
end;

procedure TestBsonPathErrors.TestNameQuoteMismatch;
begin
  TestFail('$[''store"]');
end;

procedure TestBsonPathErrors.TestNegativeIndex;
begin
  TestFail('$[-1]');
end;

procedure TestBsonPathErrors.TestNegativeListIndex;
begin
  TestFail('$[1,-2,3]');
end;

procedure TestBsonPathErrors.TestSliceMissingCloseBracket;
begin
  TestFail('$[1:2:3');
end;

procedure TestBsonPathErrors.TestTooManySliceArguments;
begin
  TestFail('$[1:2:3:4]');
end;

procedure TestBsonPathErrors.TestWildcardMissingCloseBracket;
begin
  TestFail('$["*"');
end;

procedure TestBsonPathErrors.TestWildcardMissingCloseBracket2;
begin
  TestFail('$[*');
end;

procedure TestBsonPathErrors.TestWildcardQuoteMismatch;
begin
  TestFail('$[''*"]');
end;

{ TestBsonPathBase }

procedure TestBsonPathBase.Test(const AExpression: String;
  const AExpected: array of String);
var
  Matches: TArray<TgoBsonValue>;
  I: Integer;
begin
  Matches := TgoBsonPath.Match(FDoc, AExpression);
  Assert.AreEqual(Length(AExpected), Length(Matches));

  for I := 0 to Length(Matches) - 1 do
    Assert.AreEqual(AExpected[I], Matches[I].ToJson);
end;

{ TestBsonPathExamples }

procedure TestBsonPathExamples.Setup;
begin
  FDoc := TgoBsonValue.Parse(JSON);
end;

procedure TestBsonPathExamples.Teardown;
begin
  FDoc := nil;
end;

procedure TestBsonPathExamples.TestMatchAllAuthors;
begin
  Test('$..author', ['"Nigel Rees"', '"Evelyn Waugh"', '"Herman Melville"',
    '"J. R. R. Tolkien"']);
end;

procedure TestBsonPathExamples.TestMatchAllBooks;
begin
  Test('$.store.book[*]', [
    '{ "category" : "reference", "author" : "Nigel Rees", "title" : "Sayings of the Century", "price" : 8.95 }',
    '{ "category" : "fiction", "author" : "Evelyn Waugh", "title" : "Sword of Honour", "price" : 12.99 }',
    '{ "category" : "fiction", "author" : "Herman Melville", "title" : "Moby Dick", "isbn" : "0-553-21311-3", "price" : 8.99 }',
    '{ "category" : "fiction", "author" : "J. R. R. Tolkien", "title" : "The Lord of the Rings", "isbn" : "0-395-19395-8", "price" : 22.99 }']);
end;

procedure TestBsonPathExamples.TestMatchAllThingsInStore;
var
  Matches: TArray<TgoBsonValue>;
begin
  Matches := TgoBsonPath.Match(FDoc, '$.store.*');
  Assert.AreEqual(2, Length(Matches));

  // First match is array of 4 books
  Assert.IsTrue(Matches[0].IsBsonArray);
  Assert.AreEqual(4, Matches[0].AsBsonArray.Count);

  // Second match is single dictionary with red bicycle
  Assert.IsTrue(Matches[1].IsBsonDocument);
  Assert.AreEqual<String>('red', Matches[1].AsBsonDocument['color'].ToString);
end;

procedure TestBsonPathExamples.TestMatchAuthorsFromAllBooks;
begin
  Test('$.store.book[*].author', ['"Nigel Rees"', '"Evelyn Waugh"',
    '"Herman Melville"', '"J. R. R. Tolkien"']);
end;

procedure TestBsonPathExamples.TestMatchFirstTwoBooksUsingList;
begin
  Test('$..book[0,1]', [
    '{ "category" : "reference", "author" : "Nigel Rees", "title" : "Sayings of the Century", "price" : 8.95 }',
    '{ "category" : "fiction", "author" : "Evelyn Waugh", "title" : "Sword of Honour", "price" : 12.99 }']);
end;

procedure TestBsonPathExamples.TestMatchFirstTwoBooksUsingSlice;
begin
  Test('$..book[:2]', [
    '{ "category" : "reference", "author" : "Nigel Rees", "title" : "Sayings of the Century", "price" : 8.95 }',
    '{ "category" : "fiction", "author" : "Evelyn Waugh", "title" : "Sword of Honour", "price" : 12.99 }']);
end;

procedure TestBsonPathExamples.TestMatchLastBook;
begin
  Test('$..book[-1:]', ['{ "category" : "fiction", "author" : "J. R. R. Tolkien", "title" : "The Lord of the Rings", "isbn" : "0-395-19395-8", "price" : 22.99 }']);
end;

procedure TestBsonPathExamples.TestMatchPriceOfAllThingsInStore;
begin
  Test('$.store..price', ['8.95', '12.99', '8.99', '22.99', '19.95']);
end;

procedure TestBsonPathExamples.TestMatchRoot;
var
  Matches: TArray<TgoBsonValue>;
begin
  Matches := TgoBsonPath.Match(FDoc, '$');
  Assert.AreEqual(1, Length(Matches));
  Assert.IsTrue(Matches[0] = FDoc);
end;

procedure TestBsonPathExamples.TestMatchThirdBook;
begin
  Test('$..book[2]', ['{ "category" : "fiction", "author" : "Herman Melville", "title" : "Moby Dick", "isbn" : "0-553-21311-3", "price" : 8.99 }']);
end;

procedure TestBsonPathExamples.TestMatchTitleOfFirstBookBracket;
begin
  Test('$["store"][''book''][0]["title"]', ['"Sayings of the Century"']);
end;

procedure TestBsonPathExamples.TestMatchTitleOfFirstBookDot;
begin
  Test('$.store.book[0].title', ['"Sayings of the Century"']);
end;

procedure TestBsonPathExamples.TestSingleMatch;
var
  Match: TgoBsonValue;
begin
  Assert.IsTrue(TgoBsonPath.MatchSingle(FDoc, '$.store.bicycle', Match));
  Assert.AreEqual<String>('{ "color" : "red", "price" : 19.95 }', Match.ToJson);

  Assert.IsTrue(TgoBsonPath.MatchSingle(FDoc, '$.store.bicycle.*', Match));
  Assert.AreEqual<String>('"red"', Match.ToJson);
end;

{ TesBJsonPath }

{ Tests from the original JSONPath package. }

procedure TesBJsonPath.Test1;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create;
  Doc.Add('a', 'a');
  Doc.Add('b', 'b');
  Doc.Add('c d', 'e');
  FDoc := Doc;

  Test('$.a', ['"a"']);
  Test('$[''a'']', ['"a"']);
  Test('$["a"]', ['"a"']);
  Test('$["c d"]', ['"e"']);
//  Test('$."c d"', ['"e"']); // We don't support this syntax
  Test('$.*', ['"a"', '"b"', '"e"']);
  Test('$["*"]', ['"a"', '"b"', '"e"']);
  Test('$[*]', ['"a"', '"b"', '"e"']);
end;

procedure TesBJsonPath.Test2;
var
  Arr: TgoBsonArray;
begin
  Arr := TgoBsonArray.Create;
  Arr.Add(1);
  Arr.Add('2');
  Arr.Add(3.14);
  Arr.Add(True);
  Arr.Add(TgoBsonNull.Value);
  FDoc := Arr;

  Test('$[0]', ['1']);
  Test('$[4]', ['null']);
  Test('$[*]', ['1', '"2"', '3.14', 'true', 'null']);
  Test('$[-1:]', ['null']);
end;

procedure TesBJsonPath.Test3;
var
  Doc: TgoBsonDocument;
  Arr: TgoBsonArray;
begin
  Doc := TgoBsonDocument.Create;
  FDoc := Doc;

  Arr := TgoBsonArray.Create;
  Doc.Add('points', Arr);

  Doc := TgoBsonDocument.Create;
  Arr.Add(Doc);
  Doc.Add('id', 'i1');
  Doc.Add('x', 4);
  Doc.Add('y', -5);

  Doc := TgoBsonDocument.Create;
  Arr.Add(Doc);
  Doc.Add('id', 'i2');
  Doc.Add('x', -2);
  Doc.Add('y', 2);
  Doc.Add('z', 1);

  Doc := TgoBsonDocument.Create;
  Arr.Add(Doc);
  Doc.Add('id', 'i3');
  Doc.Add('x', 8);
  Doc.Add('y', 3);

  Doc := TgoBsonDocument.Create;
  Arr.Add(Doc);
  Doc.Add('id', 'i4');
  Doc.Add('x', -6);
  Doc.Add('y', -1);

  Doc := TgoBsonDocument.Create;
  Arr.Add(Doc);
  Doc.Add('id', 'i5');
  Doc.Add('x', 0);
  Doc.Add('y', 2);
  Doc.Add('z', 1);

  Doc := TgoBsonDocument.Create;
  Arr.Add(Doc);
  Doc.Add('id', 'i6');
  Doc.Add('x', 1);
  Doc.Add('y', 4);

  Test('$.points[1]', ['{ "id" : "i2", "x" : -2, "y" : 2, "z" : 1 }']);
  Test('$.points[4].x', ['0']);
  Test('$.points[*].x', ['4', '-2', '8', '-6', '0', '1']);
end;

initialization
  TDUnitX.RegisterTestFixture(TestBsonPathErrors);
  TDUnitX.RegisterTestFixture(TestBsonPathExamples);
  TDUnitX.RegisterTestFixture(TesBJsonPath);

end.
