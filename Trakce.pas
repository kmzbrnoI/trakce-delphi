////////////////////////////////////////////////////////////////////////////////
// RCS.pas
// Interface to Railroad Control System (e.g. MTB, simulator, possibly DCC).
// (c) Jan Horacek, Michal Petrilak 2017-2019
// jan.horacek@kmz-brno.cz, engineercz@gmail.com
// license: Apache license v2.0
////////////////////////////////////////////////////////////////////////////////

{
   LICENSE:

   Copyright 2017-2019 Jan Horacek, Michal Petrilak

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
  limitations under the License.
}

{
  TRCSIFace class allows its parent to load dll library with railroad control
  system and simply use its functions.
}

{
  WARNING:
   It is required to check whether functions in this class are really mapped to
   dll functions (the do not have to exist)
}

unit Trakce;

interface

uses
  SysUtils, Classes, Windows, TrakceErrors, Generics.Collections;

const
  _TRK_API_SUPPORTED_VERSIONS : array[0..0] of Cardinal = (
    $0001 // v1.0
  );

type
  TTrkLogLevel = (
    llNo = 0,
    llErrors = 1,
    llWarnings = 2,
    llInfo = 3,
    llCommands = 4,
    llRawCommands = 5,
    llDebug = 6
  );

  TTrkStatus = (
  	tsUnknown = 0,
  	tsOff = 1,
  	tsOn = 2,
  	tsProgramming = 3
  );

  TTrkLocoInfo = record
  	addr: Word;
  	direction: Boolean;
  	speed: Byte;
  	maxSpeed: Byte;
  	functions: Cardinal;
  end;

  TCommandCallbackFunc = procedure (Sender:TObject; Data:Pointer) of object;
  TCommandCallback = record
    callback: TCommandCallbackFunc;
    data: Pointer;
  end;
  TCb = TCommandCallback;


  ///////////////////////////////////////////////////////////////////////////
  // Events called from library to TTrakceIFace:

  TTrkStdNotifyEvent = procedure (Sender: TObject; data: Pointer); stdcall;
  TTrkLogEvent = procedure (Sender: TObject; data: Pointer; logLevel: Integer; msg: PChar); stdcall;
  TTrkStatusChangedEv = procedure (Sender: TObject; data: Pointer; trkStatus: Integer);
  TTrkLocoEv = procedure (Sender: TObject; data: Pointer; addr: Word);

  ///////////////////////////////////////////////////////////////////////////
  // Events called from TTrakceIFace to parent:

  TLogEvent = procedure (Sender: TObject; logLevel:TTrkLogLevel; msg:string) of object;
  TStatusChangedEv = procedure (Sender: TObject; trkStatus: TTrkStatus) of object;
  TLocoEv = procedure (Sender: TObject; addr: Word) of object;

  ///////////////////////////////////////////////////////////////////////////
  // Prototypes of functions called to library:

  TDllPGeneral = procedure(); stdcall;
  TDllFGeneral = function():Integer; stdcall;
  TDllFCard = function():Cardinal; stdcall;
  TDllBoolGetter = function():boolean; stdcall;

  TDllApiVersionAsker = function(version:Integer):Boolean; stdcall;
  TDllApiVersionSetter = function(version:Integer):Integer; stdcall;

  TDllLocoAcquiredCallback = procedure(Sender: TObject; LocoInfo:TTrkLocoInfo);

  // TODO

  TDllStdNotifyBind = procedure(event:TTrkStdNotifyEvent; data:Pointer); stdcall;
  TDllLogBind = procedure(event:TTrkLogEvent; data:Pointer); stdcall;

  ///////////////////////////////////////////////////////////////////////////

  TTrakceIFace = class
  private
    dllName: string;
    dllHandle: Cardinal;
    mApiVersion: Cardinal;

    // ------------------------------------------------------------------
    // Functions called to library:

    // API
    dllFuncApiSupportsVersion : TDllApiVersionAsker;
    dllFuncApiSetVersion : TDllApiVersionSetter;
    dllFuncFeatures : TDllFCard;

    // dialogs
    dllFuncShowConfigDialog : TDllPGeneral;

    // connect/disconnect
    dllFuncConnect : TDllFGeneral;
    dllFuncDisconnect : TDllFGeneral;
    dllFuncConnected : TDllBoolGetter;

    // ------------------------------------------------------------------
    // Events from TTrakceIFace

    eBeforeOpen : TNotifyEvent;
    eAfterOpen : TNotifyEvent;
    eBeforeClose : TNotifyEvent;
    eAfterClose : TNotifyEvent;

    eOnLog : TLogEvent;

     procedure Reset();
     procedure PickApiVersion();

  public

    // list of unbound functions
    unbound: TList<string>;

     constructor Create();
     destructor Destroy(); override;

     procedure LoadLib(path:string; configFn:string);
     procedure UnloadLib();

     ////////////////////////////////////////////////////////////////////

     // dialogs
     procedure ShowConfigDialog();
     function HasDialog():boolean;

     // device open/close
     procedure Connect();
     procedure Disconnect();
     function Connected():boolean;

     function TrackStatus():TTrkStatus;
     procedure SetTrackStatus(status: TTrkStatus; ok: TCb; err: TCb);

     procedure LocoAcquire(addr: Word; callback: TDllLocoAcquiredCallback; err: TCb);
     procedure LocoRelease(addr: Word; ok: TCb);

     procedure LocoSetSpeed(addr: Word; speed: Integer; direction: Integer; ok: TCb; err: TCb);
     procedure LocoSetFunc(addr: Word; funcMask: Cardinal; funcState: Cardinal; ok: TCb; err: TCb);
     procedure LocoSetSingleFunc(addr: Word; func: Integer; state: Boolean);
     procedure LocoEmergencyStop(addr: Word; ok: TCb; err: TCb);

     // versions
     class function IsApiVersionSupport(version:Cardinal):Boolean;
     class function Callback(callback:TCommandCallbackFunc = nil; data:Pointer = nil):TCommandCallback;

     property BeforeOpen:TNotifyEvent read eBeforeOpen write eBeforeOpen;
     property AfterOpen:TNotifyEvent read eAfterOpen write eAfterOpen;
     property BeforeClose:TNotifyEvent read eBeforeClose write eBeforeClose;
     property AfterClose:TNotifyEvent read eAfterClose write eAfterClose;

     property OnLog:TLogEvent read eOnLog write eOnLog;

     property Lib: string read dllName;
     property apiVersion: Cardinal read mApiVersion;

  end;


implementation

////////////////////////////////////////////////////////////////////////////////

constructor TTrakceIFace.Create();
 begin
  inherited;
  Self.unbound := TList<string>.Create();
  Self.Reset();
 end;

destructor TTrakceIFace.Destroy();
 begin
  if (Self.dllHandle <> 0) then Self.UnloadLib();
  Self.unbound.Free();
  inherited;
 end;

////////////////////////////////////////////////////////////////////////////////

procedure TTrakceIFace.Reset();
 begin
  Self.mApiVersion := _TRK_API_SUPPORTED_VERSIONS[High(_TRK_API_SUPPORTED_VERSIONS)];

  dllFuncApiSupportsVersion := nil;
  dllFuncApiSetVersion := nil;
  dllFuncFeatures := nil;

  dllFuncShowConfigDialog := nil;

  dllFuncConnect := nil;
  dllFuncDisconnect := nil;
  dllFuncConnected := nil;
 end;

////////////////////////////////////////////////////////////////////////////////
// Events from dll library, these evetns must be declared as functions
// (not as functions of objects)

procedure dllBeforeOpen(Sender:TObject; data:Pointer); stdcall;
 begin
  if (Assigned(TTrakceIFace(data).BeforeOpen)) then
    TTrakceIFace(data).BeforeOpen(TTrakceIFace(data));
 end;

procedure dllAfterOpen(Sender:TObject; data:Pointer); stdcall;
 begin
  if (Assigned(TTrakceIFace(data).AfterOpen)) then
    TTrakceIFace(data).AfterOpen(TTrakceIFace(data));
 end;

procedure dllBeforeClose(Sender:TObject; data:Pointer); stdcall;
 begin
  if (Assigned(TTrakceIFace(data).BeforeClose)) then
    TTrakceIFace(data).BeforeClose(TTrakceIFace(data));
 end;

procedure dllAfterClose(Sender:TObject; data:Pointer); stdcall;
 begin
  if (Assigned(TTrakceIFace(data).AfterClose)) then
    TTrakceIFace(data).AfterClose(TTrakceIFace(data));
 end;

procedure dllOnLog(Sender: TObject; data:Pointer; logLevel:Integer; msg:PChar); stdcall;
 begin
  if (Assigned(TTrakceIFace(data).OnLog)) then
    TTrakceIFace(data).OnLog(TTrakceIFace(data), TTrkLogLevel(logLevel), msg);
 end;

////////////////////////////////////////////////////////////////////////////////
// Load dll library

procedure TTrakceIFace.LoadLib(path:string; configFn:string);
var dllFuncStdNotifyBind: TDllStdNotifyBind;
    dllFuncOnLogBind: TDllLogBind;
 begin
  Self.unbound.Clear();

  if (dllHandle <> 0) then Self.UnloadLib();

  dllName := path;
  dllHandle := LoadLibrary(PChar(dllName));
  if (dllHandle = 0) then
    raise ETrkCannotLoadLib.Create('Cannot load library!');

  // library API version
  dllFuncApiSupportsVersion := TDllApiVersionAsker(GetProcAddress(dllHandle, 'ApiSupportsVersion'));
  dllFuncApiSetVersion := TDllApiVersionSetter(GetProcAddress(dllHandle, 'ApiSetVersion'));
  if ((not Assigned(dllFuncApiSupportsVersion)) or (not Assigned(dllFuncApiSetVersion))) then
   begin
    Self.UnloadLib();
    raise ETrkUnsupportedApiVersion.Create('Library does not implement version getters!');
   end;

  try
    Self.PickApiVersion(); // will pick right version or raise exception
  except
    Self.UnloadLib();
    raise;
  end;

  // one of te supported versions picked here

  // dialogs
  dllFuncShowConfigDialog := TDllPGeneral(GetProcAddress(dllHandle, 'showConfigDialog'));

  // connect/disconnect
  dllFuncConnect := TDllFGeneral(GetProcAddress(dllHandle, 'connect'));
  if (not Assigned(dllFuncConnect)) then unbound.Add('connect');
  dllFuncDisconnect := TDllFGeneral(GetProcAddress(dllHandle, 'disconnect'));
  if (not Assigned(dllFuncDisconnect)) then unbound.Add('disconnect');
  dllFuncConnected := TDllBoolGetter(GetProcAddress(dllHandle, 'connected'));
  if (not Assigned(dllFuncConnected)) then unbound.Add('connected');

  // events
  dllFuncStdNotifyBind := TDllStdNotifyBind(GetProcAddress(dllHandle, 'bindBeforeOpen'));
  if (Assigned(dllFuncStdNotifyBind)) then dllFuncStdNotifyBind(@dllBeforeOpen, self)
  else unbound.Add('BindBeforeOpen');

  dllFuncStdNotifyBind := TDllStdNotifyBind(GetProcAddress(dllHandle, 'bindAfterOpen'));
  if (Assigned(dllFuncStdNotifyBind)) then dllFuncStdNotifyBind(@dllAfterOpen, self)
  else unbound.Add('BindAfterOpen');

  dllFuncStdNotifyBind := TDllStdNotifyBind(GetProcAddress(dllHandle, 'bindBeforeClose'));
  if (Assigned(dllFuncStdNotifyBind)) then dllFuncStdNotifyBind(@dllBeforeClose, self)
  else unbound.Add('BindBeforeClose');

  dllFuncStdNotifyBind := TDllStdNotifyBind(GetProcAddress(dllHandle, 'bindAfterClose'));
  if (Assigned(dllFuncStdNotifyBind)) then dllFuncStdNotifyBind(@dllAfterClose, self)
  else unbound.Add('BindAfterClose');

  // other events
  dllFuncOnLogBind := TDllLogBind(GetProcAddress(dllHandle, 'bindOnLog'));
  if (Assigned(dllFuncOnLogBind)) then dllFuncOnLogBind(@dllOnLog, self)
  else unbound.Add('bindOnLog');
 end;

procedure TTrakceIFace.UnloadLib();
 begin
  if (Self.dllHandle = 0) then
    raise ETrkNoLibLoaded.Create('No library loaded, cannot unload!');

  FreeLibrary(Self.dllHandle);
  Self.Reset();
 end;

////////////////////////////////////////////////////////////////////////////////
// Parent should call these methods:
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// dialogs:

procedure TTrakceIFace.ShowConfigDialog();
 begin
  if (Assigned(dllFuncShowConfigDialog)) then
    dllFuncShowConfigDialog()
  else
    raise ETrkFuncNotAssigned.Create('FFuncShowConfigDialog not assigned');
 end;

function TTrakceIFace.HasDialog():boolean;
begin
 Result := Assigned(Self.dllFuncShowConfigDialog);
end;

////////////////////////////////////////////////////////////////////////////////
// open/close:

procedure TTrakceIFace.Connect();
var res:Integer;
 begin
  if (not Assigned(dllFuncConnect)) then
    raise ETrkFuncNotAssigned.Create('FFuncOpen not assigned');

  res := dllFuncConnect();

  if (res = TRK_ALREADY_OPENNED) then
    raise ETrkAlreadyOpened.Create('Device already opened!')
  else if (res = TRK_CANNOT_OPEN_PORT) then
    raise ETrkCannotOpenPort.Create('Cannot open this port!')
  else if (res <> 0) then
    raise ETrkGeneralException.Create('General exception in Trakce library!');
 end;

procedure TTrakceIFace.Disconnect();
var res:Integer;
 begin
  if (not Assigned(dllFuncDisconnect)) then
    raise ETrkFuncNotAssigned.Create('FFuncClose not assigned');

  res := dllFuncDisconnect();

  if (res = TRK_NOT_OPENED) then
    raise ETrkNotOpened.Create('Device not opened!')
  else if (res <> 0) then
    raise ETrkGeneralException.Create('General exception in Trakce library!');
 end;

function TTrakceIFace.Connected():boolean;
 begin
  if (not Assigned(dllFuncConnected)) then
    raise ETrkFuncNotAssigned.Create('dllFuncConnected not assigned')
  else
    Result := dllFuncConnected();
 end;

////////////////////////////////////////////////////////////////////////////////

function TTrakceIFace.TrackStatus():TTrkStatus;
begin

end;

procedure TTrakceIFace.SetTrackStatus(status: TTrkStatus; ok: TCb; err: TCb);
begin

end;

////////////////////////////////////////////////////////////////////////////////

procedure TTrakceIFace.LocoAcquire(addr: Word; callback: TDllLocoAcquiredCallback; err: TCb);
begin

end;

procedure TTrakceIFace.LocoRelease(addr: Word; ok: TCb);
begin

end;

////////////////////////////////////////////////////////////////////////////////

procedure TTrakceIFace.LocoEmergencyStop(addr: Word; ok: TCb; err: TCb);
begin

end;

procedure TTrakceIFace.LocoSetSpeed(addr: Word; speed: Integer; direction: Integer; ok: TCb; err: TCb);
begin

end;

procedure TTrakceIFace.LocoSetFunc(addr: Word; funcMask: Cardinal; funcState: Cardinal; ok: TCb; err: TCb);
begin

end;

procedure TTrakceIFace.LocoSetSingleFunc(addr: Word; func: Integer; state: Boolean);
begin

end;

////////////////////////////////////////////////////////////////////////////////

class function TTrakceIFace.IsApiVersionSupport(version:Cardinal):Boolean;
var i:Integer;
begin
 for i := Low(_TRK_API_SUPPORTED_VERSIONS) to High(_TRK_API_SUPPORTED_VERSIONS) do
   if (_TRK_API_SUPPORTED_VERSIONS[i] = version) then
     Exit(true);
 Result := false;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TTrakceIFace.PickApiVersion();
var i:Integer;
begin
 for i := High(_TRK_API_SUPPORTED_VERSIONS) downto Low(_TRK_API_SUPPORTED_VERSIONS) do
  begin
   if (Self.dllFuncApiSupportsVersion(_TRK_API_SUPPORTED_VERSIONS[i])) then
    begin
     Self.mApiVersion := _TRK_API_SUPPORTED_VERSIONS[i];
     if (Self.dllFuncApiSetVersion(Self.mApiVersion) <> 0) then
       raise ETrkCannotLoadLib.Create('ApiSetVersion returned nonzero result!');
     Exit();
    end;
  end;

 raise ETrkUnsupportedApiVersion.Create('Library does not support any of the supported versions');
end;

////////////////////////////////////////////////////////////////////////////////

class function TTrakceIFace.Callback(callback:TCommandCallbackFunc = nil; data:Pointer = nil):TCommandCallback;
begin
 Result.callback := callback;
 Result.data := data;
end;

////////////////////////////////////////////////////////////////////////////////

end.//unit

