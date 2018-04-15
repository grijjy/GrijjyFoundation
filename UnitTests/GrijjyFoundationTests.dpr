program GrijjyFoundationTests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}

{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  Tests.Grijjy.Collections.Base in 'Tests\Tests.Grijjy.Collections.Base.pas',
  Tests.Grijjy.Collections.Sets in 'Tests\Tests.Grijjy.Collections.Sets.pas',
  Tests.Grijjy.Collections.RingBuffer in 'Tests\Tests.Grijjy.Collections.RingBuffer.pas',
  Tests.Grijjy.Collections.Lists in 'Tests\Tests.Grijjy.Collections.Lists.pas',
  Tests.Grijjy.Collections.Dictionaries in 'Tests\Tests.Grijjy.Collections.Dictionaries.pas',
  Tests.Grijjy.Bson in 'Tests\Tests.Grijjy.Bson.pas',
  Tests.Grijjy.Bson.IO in 'Tests\Tests.Grijjy.Bson.IO.pas',
  Tests.Grijjy.Bson.Serialization in 'Tests\Tests.Grijjy.Bson.Serialization.pas',
  Tests.Grijjy.ProtocolBuffers in 'Tests\Tests.Grijjy.ProtocolBuffers.pas',
  Tests.Grijjy.PropertyBag in 'Tests\Tests.Grijjy.PropertyBag.pas';

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  exit;
{$ENDIF}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //tell the runner how we will log things
    //Log to the console window
    logger := TDUnitXConsoleLogger.Create(true);
    runner.AddLogger(logger);

    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    runner.FailsOnNoAsserts := False; //When true, Assertions must be made during tests;

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
