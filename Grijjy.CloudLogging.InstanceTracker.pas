unit Grijjy.CloudLogging.InstanceTracker;

{ When using this unit with TRACK_MEMORY defined, instances of most classes will
  be tracked for reporting to the Grijjy Log Viewer.

  For most accurate results, it is recommended to put this unit at the top of
  the uses-clause of the project (.dpr) file.

  When TRACK_MEMORY is *not* defined, this unit does nothing and has no impact
  on the application whatsoever.

  Note that using this unit with TRACK_MEMORY defined may slow down the
  application a bit and consume extra memory. }

interface

implementation

{$IFDEF TRACK_MEMORY}

uses
  System.Rtti,
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.Messaging,
  System.Generics.Collections,
  Grijjy.Hooking,
  Grijjy.Collections,
  Grijjy.CloudLogging,
  Grijjy.CloudLogging.Protocol;

type
  { These "class opener" types give us access to the protected FRefCount
    fields of TObject and TInterfacedObject. }
  TObjectOpener = class(TObject);
  TInterfacedObjectOpener = class(TInterfacedObject);

type
  TMessageListener = class
  private
    class function InstanceToString(const AInstance: TObject): String; static;
  private
    procedure HandleGetInstances(const Sender: TObject; const M: TMessage);
  public
    constructor Create;
    destructor Destroy; override;
  end;

var
  { This set keeps track of all allocated objects. Note that it is a set of
    pointers instead of TObject's, since storing objects in the set would
    create a strong reference and prevent destruction of all objects! }
  GInstances: TgoSet<Pointer> = nil;

  { Lock to make GInstanceCounts thread-safe. }
  GLock: TCriticalSection = nil;

  { Listens for TgoGetInstancesMessage to provide a list of live instances. }
  GListener: TMessageListener = nil;

procedure TrackInstance(const AInstance: TObject);
begin
  if Assigned(AInstance) and Assigned(GLock) then
  begin
    GLock.Acquire;
    try
      if Assigned(GInstances) then
        GInstances.AddOrSet(AInstance);
    finally
      GLock.Release;
    end;
  end;
end;

procedure UntrackInstance(const AInstance: TObject);
begin
  if Assigned(AInstance) and Assigned(GLock) then
  begin
    GLock.Acquire;
    try
      if Assigned(GInstances) then
        GInstances.Remove(AInstance);
    finally
      GLock.Release;
    end;
  end;
end;

{ The following 3 routines implement the hooks for TObject.NewInstance,
  TInterfacedObject.NewInstance and TObject.FreeInstance.

  The implementation of these routines is identical to the original NewInstance
  and FreeInstance methods, but in addition it tracks (or untracks) an
  instance. }

function HookedObjectNewInstance(const Self: TClass): TObject {$IFDEF AUTOREFCOUNT} unsafe {$ENDIF};
var
  Instance: Pointer;
begin
  { This is the hook for TObject.NewInstance. Since this method is a
    (non-static) class method, it has an implicit Self parameter. But since it
    is a class method, this Self parameter represents a class, not an object.

    We start by mimicking the original source code for TObject.NewInstance: }
  GetMem(Instance, Self.InstanceSize);
  Result := Self.InitInstance(Instance);
  {$IFDEF AUTOREFCOUNT}
  { On ARC platforms, each object has a FRefCount field that must be
    initialized to 1. }
  TObjectOpener(Result).FRefCount := 1;
  {$ENDIF}

  { Now we can keep track of this instance. }
  TrackInstance(Result);
end;

function HookedInterfacedObjectNewInstance(const Self: TClass): TObject {$IFDEF AUTOREFCOUNT} unsafe {$ENDIF};
var
  Instance: Pointer;
begin
  { This is the hook for TInterfacedObject.NewInstance. This method is mostly
    similar to TObject.NewInstance, with the exception that interfaced objects
    also have a FRefCount field on non-ARC platforms. }
  GetMem(Instance, Self.InstanceSize);
  Result := Self.InitInstance(Instance);
  TInterfacedObjectOpener(Result).FRefCount := 1;

  { Now we can keep track of this instance. }
  TrackInstance(Result);
end;

procedure HookedObjectFreeInstance(const Self: TObject);
begin
  { This is the hook for TObject.FreeInstance. Since this is a (regular) method,
    it has an implicit Self parameter containing the instance. We first stop
    tracking this instance... }
  UntrackInstance(Self);

  { ...and then execute the original code in TObject.FreeInstance: }
  Self.CleanupInstance;
  FreeMem(Pointer(Self));
end;

function InitializeCodeHooks: Boolean;
begin
  { This function tries HookCode to hook the implementations of the
    TObject.NewInstance and TObject.FreeInstance methods. This will most likely
    only succeed on Windows, macOS, iOS Simulator and Linux. }
  Result := HookCode(@TObject.NewInstance, @HookedObjectNewInstance)
        and HookCode(@TObject.FreeInstance, @HookedObjectFreeInstance);
end;

{ We are using the vmtNewInstance and vmtFreeInstance constants, which have been
  deprecated for a long time, but are still available. Turn off warnings for
  these. }
{$WARN SYMBOL_DEPRECATED OFF}

procedure InitializeVMTHooks;
var
  Rtti: TRttiContext;
  RttiType: TRttiType;
  InstanceType: TRttiInstanceType;
  VMTEntryNewInstance, VMTEntryFreeInstance: PPointer;
  ObjectNewInstance, ObjectFreeInstance, InterfacedObjectNewInstance: Pointer;
begin
  { This version uses HookVMT instead of HookCode to hook the
    TObject.NewInstance and TObject.FreeInstance methods.

    Each Delphi class has its own Virtual Method Table. This means that we need
    to hook the VMT's for all classes we care about. In this case, we use
    TRttiContext.GetTypes to get a list of all Delphi classes (and other types)
    linked into the application. We then change the VMT entries of each class
    in that list.

    The problem with this kind of hooking is that some classes may have
    overridden the NewInstance and/or FreeInstance methods. Changing the VMT of
    those classes would ignore any customizations those classes made to those
    methods, and we don't want that. Fortunately, there are very few classes
    that have overridden these methods.

    So we only change the VMT's of those classes that have not overridden
    NewInstance or FreeInstance. This single exception is the TInterfacedObject
    class, which is so common that we want to support it. This class has
    overridden the NewInstance method, so we need a separate hook for this
    version.

    First, we retrieve the code addresses of the original NewInstance and
    FreeInstance methods. We use these to check if they are overridden by a
    certain class. }
  ObjectNewInstance := @TObject.NewInstance;
  ObjectFreeInstance := @TObject.FreeInstance;
  InterfacedObjectNewInstance := @TInterfacedObject.NewInstance;

  { Get a list of all Delphi types in the application with RTTI support. }
  Rtti := TRttiContext.Create;
  for RttiType in Rtti.GetTypes do
  begin
    { Check if the type is a class type. }
    if (RttiType.TypeKind = tkClass) then
    begin
      { We can now safely typecase to TRttiInstanceType }
      InstanceType := TRttiInstanceType(RttiType);

      { Retrieve the entry in the VMT of the FreeInstance method for this class. }
      VMTEntryFreeInstance := PPointer(PByte(InstanceType.MetaclassType) + vmtFreeInstance);

      { Only track classes that didn't override TObject.FreeInstance. }
      if (VMTEntryFreeInstance^ = ObjectFreeInstance) then
      begin
        { Retrieve the entry in the VMT of the NewInstance method for this class. }
        VMTEntryNewInstance := PPointer(PByte(InstanceType.MetaclassType) + vmtNewInstance);

        { Only track classes that didn't override TObject.NewInstance or
          TInterfacedObject.NewInstance. }
        if (VMTEntryNewInstance^ = ObjectNewInstance) then
        begin
          { This class uses NewInstance and FreeInstance from TObject.
            Hook those VMT entries. }
          HookVMT(VMTEntryNewInstance, @HookedObjectNewInstance);
          HookVMT(VMTEntryFreeInstance, @HookedObjectFreeInstance);
        end
        else if (VMTEntryNewInstance^ = InterfacedObjectNewInstance) then
        begin
          { This class is (ultimately) derived from TInterfacedObject, so
            we need to hook to a separate version of NewInstance. }
          HookVMT(VMTEntryNewInstance, @HookedInterfacedObjectNewInstance);
          HookVMT(VMTEntryFreeInstance, @HookedObjectFreeInstance);
        end;
      end;
    end;
  end;
end;

{$WARN SYMBOL_DEPRECATED ON}

procedure InitializeGlobals;
begin
  { These globals are used to keep track of instances. }
  GLock := TCriticalSection.Create;
  GInstances := TgoSet<Pointer>.Create;
  GListener := TMessageListener.Create;
end;

procedure FinalizeGlobals;
begin
  FreeAndNil(GLock);
  FreeAndNil(GInstances);
  FreeAndNil(GListener);
end;

{ TMessageListener }

constructor TMessageListener.Create;
begin
  inherited Create;
  TMessageManager.DefaultManager.SubscribeToMessage(TgoGetInstancesMessage,
    HandleGetInstances)
end;

destructor TMessageListener.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TgoGetInstancesMessage,
    HandleGetInstances);
  inherited;
end;

procedure TMessageListener.HandleGetInstances(const Sender: TObject;
  const M: TMessage);
type
  TInstances = TList<TgoLogMemoryUsageProtocol.TInstance>;
var
  Msg: TgoGetInstancesMessage absolute M;
  Instances: TArray<Pointer>;
  Instance: Pointer;
  Counts: TDictionary<TClass, Integer>;
  Pair: TPair<TClass, Integer>;
  DetailClasses: TObjectDictionary<TClass, TInstances>;
  DetailInstances: TInstances;
  DetailInstance: TgoLogMemoryUsageProtocol.TInstance;
  Obj: TObject;
  ObjClass: TClass;
  Component: TComponent absolute Obj;
  Count: Integer;
begin
  Assert(M is TgoGetInstancesMessage);
  if (GLock = nil) then
    Exit;

  GLock.Acquire;
  try
    if (GInstances = nil) then
      Exit;

    Instances := GInstances.ToArray;
    if (Instances = nil) then
      Exit;

    DetailClasses := nil;
    Counts := TDictionary<TClass, Integer>.Create;
    try
      DetailClasses := TObjectDictionary<TClass, TInstances>.Create([doOwnsValues]);
      for Count := 0 to Length(Msg.Classes) - 1 do
        DetailClasses.AddOrSetValue(Msg.Classes[Count], nil);

      for Instance in Instances do
      begin
        Obj := TObject(Instance);
        ObjClass := Obj.ClassType;
        if (Counts.TryGetValue(ObjClass, Count)) then
          Counts[ObjClass] := Count + 1
        else
          Counts.Add(ObjClass, 1);

        if (DetailClasses.TryGetValue(ObjClass, DetailInstances)) then
        begin
          { Details are requested for this class. }
          if (DetailInstances = nil) then
          begin
            DetailInstances := TInstances.Create;
            DetailClasses[ObjClass] := DetailInstances;
          end;

          if (DetailInstances.Count < GrijjyLog.MaxInstancesPerClass) then
          begin
            { Add string respresentation of this instance to details for the
              class. }
            if (Obj is TComponent) then
            begin
              DetailInstance.Caption := '';
              if Assigned(Component.Owner) and (Component.Owner.Name <> '') then
                DetailInstance.Caption := Component.Owner.Name + '.';
              if (Component.Name = '') then
                DetailInstance.Caption := DetailInstance.Caption + InstanceToString(Component)
              else
                DetailInstance.Caption := DetailInstance.Caption + Component.Name;
            end
            else
              DetailInstance.Caption := InstanceToString(Obj);

            DetailInstances.Add(DetailInstance);
          end;
        end;
      end;

      SetLength(Msg.Protocol.Entries, Counts.Count);
      Count := 0;
      for Pair in Counts do
      begin
        Assert(Count < Length(Msg.Protocol.Entries));
        if Assigned(Pair.Key) then
        begin
          Msg.Protocol.Entries[Count].ClassName := Pair.Key.ClassName;
          Msg.Protocol.Entries[Count].ClassHandle := THandle(Pair.Key);
        end;
        Msg.Protocol.Entries[Count].InstanceCount := Pair.Value;

        if (DetailClasses.TryGetValue(Pair.Key, DetailInstances)) then
          Msg.Protocol.Entries[Count].Instances := DetailInstances.ToArray;

        Inc(Count);
      end;
    finally
      DetailClasses.Free;
      Counts.Free;
    end;
  finally
    GLock.Release;
  end;
end;

class function TMessageListener.InstanceToString(
  const AInstance: TObject): String;
begin
  Result := AInstance.ToString;
  if (Result = AInstance.ClassName) then
    { The instance did not override the ToString method }
    Result := Result + Format(' @ %p', [Pointer(AInstance)]);
end;

initialization
  { First we try code hooking to hook into the NewInstance and FreeInstance
    methods. This is fastest and tracks all classes. }
  if (not InitializeCodeHooks) then
    { If the first method fails, try VMT hooking instead. This hooks the
      NewInstance and FreeInstance entries in the Virtual Method Tables of all
      classes that have RTTI. }
    InitializeVMTHooks;

  { Initialize some global variables. }
  InitializeGlobals;

finalization
  FinalizeGlobals;

{$ENDIF !TRACK_MEMORY}
end.
