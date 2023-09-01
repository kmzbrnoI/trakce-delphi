////////////////////////////////////////////////////////////////////////////////
// Trakce.pas: Interface to Trakce (e.g. XpressNET, LocoNET, Simulator).
////////////////////////////////////////////////////////////////////////////////

{
   LICENSE:

   Copyright 2019-2020 Jan Horacek

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
  TTrakceIFace class allows its parent to load dll library with Trakce and
  simply use its functions.
}

unit Trakce;

interface

uses
  SysUtils, Classes, Windows, TrakceErrors, Generics.Collections;

const
  // Highest-priority version last
  _TRK_API_SUPPORTED_VERSIONS : array[0..2] of Cardinal = (
    $0001, $0100, $0101 // v0.1, v1.0, v1.1
  );

  _LOCO_DIR_FORWARD = false;
  _LOCO_DIR_BACKWARD = true;

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
  	step: Byte;
  	maxSpeed: Byte;
  	functions: Cardinal;

    class operator Equal(a, b: TTrkLocoInfo): Boolean;
    class operator NotEqual(a, b: TTrkLocoInfo): Boolean;
  end;

  TDllCommandCallbackFunc = procedure (Sender: TObject; Data: Pointer); stdcall;
  TDllCommandCallback = record
    callback: TDllCommandCallbackFunc;
    data: Pointer;
  end;
  TDllCb = TDllCommandCallback;

  TCommandCallbackFunc = procedure (Sender: TObject; Data: Pointer) of object;
  TCommandCallback = record
    callback: TCommandCallbackFunc;
    data: Pointer;
    other: ^TCommandCallback;
  end;
  TCb = TCommandCallback;
  PTCb = ^TCb;

  ///////////////////////////////////////////////////////////////////////////
  // Events called from library to TTrakceIFace:

  TTrkStdNotifyEvent = procedure (Sender: TObject; data: Pointer); stdcall;
  TTrkLogEvent = procedure (Sender: TObject; data: Pointer; logLevel: Integer; msg: PChar); stdcall;
  TTrkMsgEvent = procedure (Sender: TObject; msg: PChar); stdcall;
  TTrkStatusChangedEv = procedure (Sender: TObject; data: Pointer; trkStatus: Integer); stdcall;
  TTrkLocoEv = procedure (Sender: TObject; data: Pointer; addr: Word); stdcall;
  TDllLocoAcquiredCallback = procedure(Sender: TObject; LocoInfo: TTrkLocoInfo); stdcall;

  ///////////////////////////////////////////////////////////////////////////
  // Events called from TTrakceIFace to parent:

  TErrorEvent = procedure(Sender: TObject; errMsg: string) of object;
  TLogEvent = procedure (Sender: TObject; logLevel: TTrkLogLevel; msg: string) of object;
  TMsgEvent = procedure (Sender: TObject; msg: string) of object;
  TStatusChangedEv = procedure (Sender: TObject; trkStatus: TTrkStatus) of object;
  TLocoEv = procedure (Sender: TObject; addr: Word) of object;
  TLocoAcquiredCallback = procedure(Sender: TObject; LocoInfo: TTrkLocoInfo) of object;

  ///////////////////////////////////////////////////////////////////////////
  // Prototypes of functions called to library:

  TDllPGeneral = procedure(); stdcall;
  TDllFGeneral = function(): Integer; stdcall;
  TDllFCard = function(): Cardinal; stdcall;
  TDllBoolGetter = function(): Boolean; stdcall;
  TDllPCallback = procedure(ok: TDllCb; err: TDllCb); stdcall;

  TDllFileIOFunc = function(filename: PChar): Integer; stdcall;

  TDllApiVersionAsker = function(version: Cardinal): Boolean; stdcall;
  TDllApiVersionSetter = function(version: Cardinal): Integer; stdcall;

  TDllFSetTrackStatus = procedure(trkStatus: Cardinal; ok: TDllCb; err: TDllCb); stdcall;

  TDllFLocoAcquire = procedure(addr: Word; acquired: TDllLocoAcquiredCallback; err: TDllCb); stdcall;
  TDllFLocoRelease = procedure(addr: Word; ok: TDllCb); stdcall;
  TDllFLocoCallback = procedure(addr: Word; ok: TDllCb; err: TDllCb); stdcall;
  TDllFLocoSetSpeed = procedure(addr: Word; speed: Integer; direction: Boolean; ok: TDllCb; err: TDllCb); stdcall;
  TDllFLocoSetFunc = procedure(addr: Word; funcMask: Cardinal; funcState: Cardinal; ok: TDllCb; err: TDllCb); stdcall;

  TDllFPomWriteCv = procedure(addr: Word; cv: Word; value: Byte; ok: TDllCb; err: TDllCb); stdcall;

  TDllStdNotifyBind = procedure(event: TTrkStdNotifyEvent; data: Pointer); stdcall;
  TDllLogBind = procedure(event: TTrkLogEvent; data: Pointer); stdcall;
  TDllMsgBind = procedure(event: TTrkMsgEvent; data: Pointer); stdcall;
  TDllTrackStatusChangedBind = procedure(event: TTrkStatusChangedEv; data: Pointer); stdcall;
  TDllLocoEventBind = procedure(event: TTrkLocoEv; data: Pointer); stdcall;

  ///////////////////////////////////////////////////////////////////////////

  TTrakceIFace = class
  private const
   _Default_Cb : TCb = (
     callback: nil;
     data: nil;
   );

  private
    dllName: string;
    dllHandle: NativeUInt;
    mApiVersion: Cardinal;
    fOpening: Boolean;
    openErrors: string;

    // ------------------------------------------------------------------
    // Functions called to library:

    // API
    dllFuncApiSupportsVersion : TDllApiVersionAsker;
    dllFuncApiSetVersion : TDllApiVersionSetter;
    dllFuncFeatures : TDllFCard;

    // load & save config
    dllFuncLoadConfig : TDllFileIOFunc;
    dllFuncSaveConfig : TDllFileIOFunc;

    // dialogs
    dllFuncShowConfigDialog : TDllPGeneral;

    // connect/disconnect
    dllFuncConnect : TDllFGeneral;
    dllFuncDisconnect : TDllFGeneral;
    dllFuncConnected : TDllBoolGetter;

    dllFuncTrackStatus : TDllFCard;
    dllFuncSetTrackStatus : TDllFSetTrackStatus;

    dllFuncLocoAcquire : TDllFLocoAcquire;
    dllFuncLocoRelease : TDllFLocoRelease;

    dllFuncEmergencyStop : TDllPCallback;
    dllFuncLocoEmergencyStop : TDllFLocoCallback;
    dllFuncLocoSetSpeed : TDllFLocoSetSpeed;
    dllFuncLocoSetFunc : TDllFLocoSetFunc;

    dllFuncPomWriteCv : TDllFPomWriteCv;

    // ------------------------------------------------------------------
    // Events from TTrakceIFace

    eBeforeOpen : TNotifyEvent;
    eAfterOpen : TNotifyEvent;
    eBeforeClose : TNotifyEvent;
    eAfterClose : TNotifyEvent;

    eOnLog : TLogEvent;
    eOnOpenError : TMsgEvent;
    eOnTrackStatusChanged : TStatusChangedEv;
    eOnLocoStolen : TLocoEv;

     procedure Reset();
     procedure PickApiVersion();

     class function CallbackDll(const cb: TCb): TDllCb;
     class procedure CallbackDllReferOther(var dllCb: TDllCb; const other: TDllCb);
     class procedure CallbackDllReferEachOther(var first: TDllCb; var second: TDllCb);
     class procedure CallbacksDll(const ok: TCb; const err: TCb; var dllOk: TDllCb; var dllErr: TDllCb);

  public

    // list of unbound functions
    unbound: TList<string>;

     constructor Create();
     destructor Destroy(); override;

     procedure LoadLib(path: string; configFn: string);
     procedure UnloadLib();

     class function LogLevelToString(ll: TTrkLogLevel): string;

     ////////////////////////////////////////////////////////////////////

     // file I/O
     procedure LoadConfig(fn: string);
     procedure SaveConfig(fn: string);

     // dialogs
     procedure ShowConfigDialog();
     function HasDialog(): Boolean;

     // device open/close
     procedure Connect();
     procedure Disconnect();
     function Connected(): Boolean;
     function ConnectedSafe(): Boolean;

     function TrackStatus(): TTrkStatus;
     function TrackStatusSafe(): TTrkStatus;
     procedure SetTrackStatus(status: TTrkStatus; ok: TCb; err: TCb);

     procedure EmergencyStop(); overload;
     procedure EmergencyStop(ok: TCb; err: TCb); overload;

     procedure LocoAcquire(addr: Word; callback: TLocoAcquiredCallback; err: TCb);
     procedure LocoRelease(addr: Word; ok: TCb);

     procedure LocoSetSpeed(addr: Word; speed: Integer; direction: Boolean; ok: TCb; err: TCb);
     procedure LocoSetFunc(addr: Word; funcMask: Cardinal; funcState: Cardinal; ok: TCb; err: TCb);
     procedure LocoSetSingleFunc(addr: Word; func: Integer; funcState: Cardinal; ok: TCb; err: TCb);
     procedure LocoEmergencyStop(addr: Word; ok: TCb; err: TCb);

     procedure PomWriteCv(addr: Word; cv: Word; value: Byte; ok: TCb; err: TCb);

     function apiVersionStr(): string;

     class function IsApiVersionSupport(version: Cardinal): Boolean;

     class function Callback(callback: TCommandCallbackFunc = nil; data: Pointer = nil): TCommandCallback;
     class procedure Callbacks(const ok: TCb; const err: TCb; var pOk: PTCb; var pErr: PTCb);

     property BeforeOpen: TNotifyEvent read eBeforeOpen write eBeforeOpen;
     property AfterOpen: TNotifyEvent read eAfterOpen write eAfterOpen;
     property BeforeClose: TNotifyEvent read eBeforeClose write eBeforeClose;
     property AfterClose: TNotifyEvent read eAfterClose write eAfterClose;
     property OnOpenError: TMsgEvent read eOnOpenError write eOnOpenError;

     property OnLog: TLogEvent read eOnLog write eOnLog;
     property OnTrackStatusChanged: TStatusChangedEv read eOnTrackStatusChanged write eOnTrackStatusChanged;
     property OnLocoStolen: TLocoEv read eOnLocoStolen write eOnLocoStolen;

     property Lib: string read dllName;
     property apiVersion: Cardinal read mApiVersion;
     property opening: Boolean read fOpening write fOpening;

  end;

var
    acquiredCallbacks: TDictionary<Word, TLocoAcquiredCallback>;

implementation

////////////////////////////////////////////////////////////////////////////////

function GetLastOsError(_ErrCode: integer; out _Error: string; const _Format: string = ''): DWORD; overload;
var
  s: string;
begin
  Result := _ErrCode;
  if (Result <> ERROR_SUCCESS) then
    s := SysErrorMessage(Result)
  else
    s := 'unknown OS error';

  if (_Format <> '') then
  begin
    try
      _Error := Format(_Format, [Result, s]);
    except
      _Error := s;
    end;
  end else begin
    _Error := s;
  end;
end;

function GetLastOsError(out _Error: string; const _Format: string = ''): DWORD; overload;
begin
  Result := GetLastOsError(GetLastError, _Error, _Format);
end;

////////////////////////////////////////////////////////////////////////////////

constructor TTrakceIFace.Create();
begin
  inherited;
  Self.unbound := TList<string>.Create();
  Self.Reset();
end;

destructor TTrakceIFace.Destroy();
begin
  try
    if (Self.dllHandle <> 0) then Self.UnloadLib();
    Self.unbound.Free();
  finally

  end;
  inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TTrakceIFace.Reset();
begin
  Self.dllHandle := 0;
  Self.mApiVersion := _TRK_API_SUPPORTED_VERSIONS[High(_TRK_API_SUPPORTED_VERSIONS)];
  Self.fOpening := False;
  Self.mEmergency := False;
  Self.disconnectAllowed := False;

  Self.dllFuncApiSupportsVersion := nil;
  Self.dllFuncApiSetVersion := nil;
  Self.dllFuncFeatures := nil;

  Self.dllFuncLoadConfig := nil;
  Self.dllFuncSaveConfig := nil;

  Self.dllFuncShowConfigDialog := nil;

  Self.dllFuncConnect := nil;
  Self.dllFuncDisconnect := nil;
  Self.dllFuncConnected := nil;

  Self.dllFuncTrackStatus := nil;
  Self.dllFuncSetTrackStatus := nil;

  Self.dllFuncLocoAcquire := nil;
  Self.dllFuncLocoRelease := nil;

  Self.dllFuncEmergencyStop := nil;
  Self.dllFuncLocoEmergencyStop := nil;
  Self.dllFuncLocoSetSpeed := nil;
  Self.dllFuncLocoSetFunc := nil;

  Self.dllFuncPomWriteCv := nil;
end;

////////////////////////////////////////////////////////////////////////////////
// Events from dll library, these evetns must be declared as functions
// (not as functions of objects)

procedure dllBeforeOpen(Sender: TObject; data: Pointer); stdcall;
begin
  try
    if (Assigned(TTrakceIFace(data).BeforeOpen)) then
      TTrakceIFace(data).BeforeOpen(TTrakceIFace(data));
  except

  end;
end;

procedure dllAfterOpen(Sender: TObject; data: Pointer); stdcall;
begin
  try
    TTrakceIFace(data).opening := false;
    if (Assigned(TTrakceIFace(data).AfterOpen)) then
      TTrakceIFace(data).AfterOpen(TTrakceIFace(data));
  except

  end;
end;

procedure dllBeforeClose(Sender: TObject; data: Pointer); stdcall;
begin
  try
    if (Assigned(TTrakceIFace(data).BeforeClose)) then
      TTrakceIFace(data).BeforeClose(TTrakceIFace(data));
  except

  end;
end;

procedure dllAfterClose(Sender: TObject; data: Pointer); stdcall;
begin
  try
    TTrakceIFace(data).opening := false;
    if (Assigned(TTrakceIFace(data).AfterClose)) then
      TTrakceIFace(data).AfterClose(TTrakceIFace(data));
  except

  end;
end;

procedure dllOnLog(Sender: TObject; data: Pointer; logLevel: Integer; msg: PChar); stdcall;
begin
  try
    if (Assigned(TTrakceIFace(data).OnLog)) then
      TTrakceIFace(data).OnLog(TTrakceIFace(data), TTrkLogLevel(logLevel), msg);
  except

  end;
end;

procedure dllOnOpenError(Sender: TObject; data: Pointer; msg: PChar); stdcall;
begin
  try
    TTrakceIFace(data).opening := false;
    if (Assigned(TTrakceIFace(data).OnOpenError)) then
      TTrakceIFace(data).OnOpenError(TTrakceIFace(data), msg);
  except

  end;
end;

procedure dllOnTrackStatusChanged(Sender: TObject; data: Pointer; trkStatus: Integer); stdcall;
begin
  try
    if (Assigned(TTrakceIFace(data).OnTrackStatusChanged)) then
      TTrakceIFace(data).OnTrackStatusChanged(TTrakceIFace(data), TTrkStatus(trkStatus));
  except

  end;
end;

procedure dllOnLocoStolen(Sender: TObject; data: Pointer; addr: Word); stdcall;
begin
  try
    if (Assigned(TTrakceIFace(data).OnLocoStolen)) then
      TTrakceIFace(data).OnLocoStolen(TTrakceIFace(data), addr);
  except

  end;
end;

procedure dllCallback(Sender: TObject; data: Pointer); stdcall;
var pcb: ^TCb;
    cb: TCb;
begin
  try
    pcb := data;
    cb := pcb^;
    if (cb.other <> nil) then
      FreeMem(cb.other);
    FreeMem(pcb);
    if (Assigned(cb.callback)) then
      cb.callback(Sender, cb.data);
  except

  end;
end;

procedure dllLocoAcquiredCallback(Sender: TObject; LocoInfo: TTrkLocoInfo); stdcall;
begin
  try
    if ((acquiredCallbacks.ContainsKey(LocoInfo.addr)) and (Assigned(acquiredCallbacks[LocoInfo.addr]))) then
     begin
      var callback: TLocoAcquiredCallback := acquiredCallbacks[LocoInfo.addr];
      acquiredCallbacks.Remove(LocoInfo.addr);
      callback(Sender, LocoInfo);
     end;
  except

  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Load dll library

procedure TTrakceIFace.LoadLib(path: string; configFn: string);
begin
  Self.unbound.Clear();

  if (dllHandle <> 0) then Self.UnloadLib();

  dllName := path;
  dllHandle := LoadLibrary(PChar(dllName));
  if (dllHandle = 0) then
   begin
    var errorStr: string;
    var errorCode := GetLastOsError(errorStr);
    raise ETrkCannotLoadLib.Create('Cannot load library: error '+IntToStr(errorCode)+': '+errorStr+'!');
   end;

  // library API version
  dllFuncApiSupportsVersion := TDllApiVersionAsker(GetProcAddress(dllHandle, 'apiSupportsVersion'));
  dllFuncApiSetVersion := TDllApiVersionSetter(GetProcAddress(dllHandle, 'apiSetVersion'));
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

  // one of the supported versions is surely picked
  dllFuncLoadConfig := TDllFileIOFunc(GetProcAddress(dllHandle, 'loadConfig'));
  if (not Assigned(dllFuncLoadConfig)) then unbound.Add('loadConfig');
  dllFuncSaveConfig := TDllFileIOFunc(GetProcAddress(dllHandle, 'saveConfig'));
  if (not Assigned(dllFuncSaveConfig)) then unbound.Add('saveConfig');


  // dialogs
  dllFuncShowConfigDialog := TDllPGeneral(GetProcAddress(dllHandle, 'showConfigDialog'));

  // connect/disconnect
  dllFuncConnect := TDllFGeneral(GetProcAddress(dllHandle, 'connect'));
  if (not Assigned(dllFuncConnect)) then unbound.Add('connect');
  dllFuncDisconnect := TDllFGeneral(GetProcAddress(dllHandle, 'disconnect'));
  if (not Assigned(dllFuncDisconnect)) then unbound.Add('disconnect');
  dllFuncConnected := TDllBoolGetter(GetProcAddress(dllHandle, 'connected'));
  if (not Assigned(dllFuncConnected)) then unbound.Add('connected');

  // track status getting & setting
  dllFuncTrackStatus := TDllFCard(GetProcAddress(dllHandle, 'trackStatus'));
  if (not Assigned(dllFuncTrackStatus)) then unbound.Add('trackStatus');
  dllFuncSetTrackStatus := TDllFSetTrackStatus(GetProcAddress(dllHandle, 'setTrackStatus'));
  if (not Assigned(dllFuncSetTrackStatus)) then unbound.Add('setTrackStatus');

  // loco acquire/release
  dllFuncLocoAcquire := TDllFLocoAcquire(GetProcAddress(dllHandle, 'locoAcquire'));
  if (not Assigned(dllFuncLocoAcquire)) then unbound.Add('locoAcquire');
  dllFuncLocoRelease := TDllFLocoRelease(GetProcAddress(dllHandle, 'locoRelease'));
  if (not Assigned(dllFuncLocoRelease)) then unbound.Add('locoRelease');

  // loco
  dllFuncEmergencyStop := TDllPCallback(GetProcAddress(dllHandle, 'emergencyStop'));
  if (not Assigned(dllFuncEmergencyStop)) then unbound.Add('emergencyStop');
  dllFuncLocoEmergencyStop := TDllFLocoCallback(GetProcAddress(dllHandle, 'locoEmergencyStop'));
  if (not Assigned(dllFuncLocoEmergencyStop)) then unbound.Add('locoEmergencyStop');
  dllFuncLocoSetSpeed := TDllFLocoSetSpeed(GetProcAddress(dllHandle, 'locoSetSpeed'));
  if (not Assigned(dllFuncLocoSetSpeed)) then unbound.Add('locoSetSpeed');
  dllFuncLocoSetFunc := TDllFLocoSetFunc(GetProcAddress(dllHandle, 'locoSetFunc'));
  if (not Assigned(dllFuncLocoSetFunc)) then unbound.Add('locoSetFunc');

  // pom
  dllFuncPomWriteCv := TDllFPomWriteCv(GetProcAddress(dllHandle, 'pomWriteCv'));
  if (not Assigned(dllFuncPomWriteCv)) then unbound.Add('pomWriteCv');

  // events
  begin
    var dllFuncStdNotifyBind: TDllStdNotifyBind;

    dllFuncStdNotifyBind := TDllStdNotifyBind(GetProcAddress(dllHandle, 'bindBeforeOpen'));
    if (Assigned(dllFuncStdNotifyBind)) then dllFuncStdNotifyBind(@dllBeforeOpen, self)
    else unbound.Add('bindBeforeOpen');

    dllFuncStdNotifyBind := TDllStdNotifyBind(GetProcAddress(dllHandle, 'bindAfterOpen'));
    if (Assigned(dllFuncStdNotifyBind)) then dllFuncStdNotifyBind(@dllAfterOpen, self)
    else unbound.Add('bindAfterOpen');

    dllFuncStdNotifyBind := TDllStdNotifyBind(GetProcAddress(dllHandle, 'bindBeforeClose'));
    if (Assigned(dllFuncStdNotifyBind)) then dllFuncStdNotifyBind(@dllBeforeClose, self)
    else unbound.Add('bindBeforeClose');

    dllFuncStdNotifyBind := TDllStdNotifyBind(GetProcAddress(dllHandle, 'bindAfterClose'));
    if (Assigned(dllFuncStdNotifyBind)) then dllFuncStdNotifyBind(@dllAfterClose, self)
    else unbound.Add('bindAfterClose');
  end;

  // other events
  begin
    var dllFuncOnTrackStatusChanged: TDllTrackStatusChangedBind := TDllTrackStatusChangedBind(GetProcAddress(dllHandle, 'bindOnTrackStatusChange'));
    if (Assigned(dllFuncOnTrackStatusChanged)) then dllFuncOnTrackStatusChanged(@dllOnTrackStatusChanged, self)
    else unbound.Add('bindOnTrackStatusChange');
  end;

  begin
    var dllFuncOnLogBind: TDllLogBind := TDllLogBind(GetProcAddress(dllHandle, 'bindOnLog'));
    if (Assigned(dllFuncOnLogBind)) then dllFuncOnLogBind(@dllOnLog, self)
    else unbound.Add('bindOnLog');
  end;

  if (Self.apiVersion >= $0101) then
  begin
    var dllFuncMsgBind: TDllMsgBind := TDllMsgBind(GetProcAddress(dllHandle, 'bindOnOpenError'));
    if (Assigned(dllFuncMsgBind)) then dllFuncMsgBind(@dllOnOpenError, self)
    else unbound.Add('bindOnOpenError');
  end;

  begin
    var dllLocoEventBind: TDllLocoEventBind := TDllLocoEventBind(GetProcAddress(dllHandle, 'bindOnLocoStolen'));
    if (Assigned(dllLocoEventBind)) then dllLocoEventBind(@dllOnLocoStolen, self)
    else unbound.Add('bindOnLocoStolen');
  end;

  if (Assigned(dllFuncLoadConfig)) then
    Self.LoadConfig(configFn);
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
// file I/O

procedure TTrakceIFace.LoadConfig(fn: string);
begin
  if (not Assigned(dllFuncLoadConfig)) then
    raise ETrkFuncNotAssigned.Create('loadConfig not assigned');

  var res := dllFuncLoadConfig(PChar(fn));

  if (res = TRK_FILE_CANNOT_ACCESS) then
    raise ETrkCannotAccessFile.Create('Cannot read file '+fn+'!');
  if (res = TRK_FILE_DEVICE_OPENED) then
    raise ETrkDeviceOpened.Create('Cannot reload config, device opened!');
  if (res <> 0) then
    raise ETrkGeneralException.Create();
end;

procedure TTrakceIFace.SaveConfig(fn: string);
begin
  if (not Assigned(dllFuncSaveConfig)) then
    raise ETrkFuncNotAssigned.Create('saveConfig not assigned');

  var res := dllFuncSaveConfig(PChar(fn));

  if (res = TRK_FILE_CANNOT_ACCESS) then
    raise ETrkCannotAccessFile.Create('Cannot write to file '+fn+'!');
  if (res <> 0) then
    raise ETrkGeneralException.Create();
end;


////////////////////////////////////////////////////////////////////////////////
// dialogs:

procedure TTrakceIFace.ShowConfigDialog();
begin
  if (not Assigned(dllFuncShowConfigDialog)) then
    raise ETrkFuncNotAssigned.Create('showConfigDialog not assigned');
  dllFuncShowConfigDialog();
end;

function TTrakceIFace.HasDialog(): Boolean;
begin
  Result := Assigned(Self.dllFuncShowConfigDialog);
end;

////////////////////////////////////////////////////////////////////////////////
// open/close:

procedure TTrakceIFace.Connect();
begin
  if (not Assigned(dllFuncConnect)) then
    raise ETrkFuncNotAssigned.Create('connect not assigned');

  Self.opening := true;
  Self.openErrors := '';
  var res := dllFuncConnect();

  if (res = TRK_ALREADY_OPENNED) then
    raise ETrkAlreadyOpened.Create('Device already opened!');
  if (res = TRK_CANNOT_OPEN_PORT) then
    raise ETrkCannotOpenPort.Create('Cannot open this port!');
  if (res <> 0) then
    raise ETrkGeneralException.Create();
end;

procedure TTrakceIFace.Disconnect();
 begin
  if (not Assigned(dllFuncDisconnect)) then
    raise ETrkFuncNotAssigned.Create('disconnect not assigned');

  Self.disconnectAllowed := True;
  var res := dllFuncDisconnect();

  if (res = TRK_NOT_OPENED) then
    raise ETrkNotOpened.Create('Device not opened!');
  if (res <> 0) then
    raise ETrkGeneralException.Create();
end;

function TTrakceIFace.Connected(): Boolean;
begin
  if (not Assigned(dllFuncConnected)) then
    raise ETrkFuncNotAssigned.Create('connected not assigned');
  Result := dllFuncConnected();
end;

function TTrakceIFace.ConnectedSafe(): Boolean;
begin
  if (not Assigned(dllFuncConnected)) then
    Result := false
  else
    Result := dllFuncConnected();
end;


////////////////////////////////////////////////////////////////////////////////

function TTrakceIFace.TrackStatus(): TTrkStatus;
begin
  if (not Self.ConnectedSafe()) then
    Exit(TTrkStatus.tsUnknown);

  if (not Assigned(dllFuncTrackStatus)) then
    raise ETrkFuncNotAssigned.Create('trackStatus not assigned');
  Result := TTrkStatus(dllFuncTrackStatus());
end;

function TTrakceIFace.TrackStatusSafe(): TTrkStatus;
begin
  if (not Self.ConnectedSafe()) then
    Exit(TTrkStatus.tsUnknown);

  if (Assigned(dllFuncTrackStatus)) then
    Result := TTrkStatus(dllFuncTrackStatus())
  else
    Result := TTrkStatus.tsUnknown;
end;

procedure TTrakceIFace.SetTrackStatus(status: TTrkStatus; ok: TCb; err: TCb);
var dllOk, dllErr: TDllCb;
begin
  if (not Assigned(dllFuncSetTrackStatus)) then
    raise ETrkFuncNotAssigned.Create('setTrackStatus not assigned');
  CallbacksDll(ok, err, dllOk, dllErr);
  dllFuncSetTrackStatus(Integer(status), dllOk, dllErr);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TTrakceIFace.EmergencyStop(ok: TCb; err: TCb);
var dllOk, dllErr: TDllCb;
begin
  if (not Assigned(dllFuncEmergencyStop)) then
    raise ETrkFuncNotAssigned.Create('emergencyStop not assigned');
  CallbacksDll(ok, err, dllOk, dllErr);
  dllFuncEmergencyStop(dllOk, dllErr);
end;

procedure TTrakceIFace.EmergencyStop();
begin
  Self.EmergencyStop(Callback(), Callback());
end;

////////////////////////////////////////////////////////////////////////////////

procedure TTrakceIFace.LocoAcquire(addr: Word; callback: TLocoAcquiredCallback; err: TCb);
begin
  if (not Assigned(dllFuncLocoAcquire)) then
    raise ETrkFuncNotAssigned.Create('locoAcquire not assigned');
  acquiredCallbacks.AddOrSetValue(addr, callback);
  dllFuncLocoAcquire(addr, dllLocoAcquiredCallback, CallbackDll(err));
end;

procedure TTrakceIFace.LocoRelease(addr: Word; ok: TCb);
begin
  if (not Assigned(dllFuncLocoRelease)) then
    raise ETrkFuncNotAssigned.Create('locoRelease not assigned');
  dllFuncLocoRelease(addr, CallbackDll(ok));
end;

////////////////////////////////////////////////////////////////////////////////

procedure TTrakceIFace.LocoEmergencyStop(addr: Word; ok: TCb; err: TCb);
var dllOk, dllErr: TDllCb;
begin
  if (not Assigned(dllFuncLocoEmergencyStop)) then
    raise ETrkFuncNotAssigned.Create('locoEmergencyStop not assigned');
  CallbacksDll(ok, err, dllOk, dllErr);
  dllFuncLocoEmergencyStop(addr, dllOk, dllErr);
end;

procedure TTrakceIFace.LocoSetSpeed(addr: Word; speed: Integer; direction: Boolean; ok: TCb; err: TCb);
var dllOk, dllErr: TDllCb;
begin
  if (not Assigned(dllFuncLocoSetSpeed)) then
    raise ETrkFuncNotAssigned.Create('locoSetSpeed not assigned');
  CallbacksDll(ok, err, dllOk, dllErr);
  dllFuncLocoSetSpeed(addr, speed, direction, dllOk, dllErr);
end;

procedure TTrakceIFace.LocoSetFunc(addr: Word; funcMask: Cardinal; funcState: Cardinal; ok: TCb; err: TCb);
var dllOk, dllErr: TDllCb;
begin
  if (not Assigned(dllFuncLocoSetFunc)) then
    raise ETrkFuncNotAssigned.Create('locoSetFunc not assigned');
  CallbacksDll(ok, err, dllOk, dllErr);
  dllFuncLocoSetFunc(addr, funcMask, funcState, dllOk, dllErr);
end;

procedure TTrakceIFace.LocoSetSingleFunc(addr: Word; func: Integer; funcState: Cardinal; ok: TCb; err: TCb);
var fMask: Cardinal;
begin
  fMask := 1 shl func;
  Self.LocoSetFunc(addr, fMask, funcState, ok, err);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TTrakceIFace.PomWriteCv(addr: Word; cv: Word; value: Byte; ok: TCb; err: TCb);
var dllOk, dllErr: TDllCb;
begin
  if (not Assigned(dllFuncPomWriteCv)) then
    raise ETrkFuncNotAssigned.Create('pomWriteCv not assigned');
  CallbacksDll(ok, err, dllOk, dllErr);
  dllFuncPomWriteCv(addr, cv, value, dllOk, dllErr);
end;

////////////////////////////////////////////////////////////////////////////////

class function TTrakceIFace.IsApiVersionSupport(version: Cardinal): Boolean;
begin
  for var i: Integer := Low(_TRK_API_SUPPORTED_VERSIONS) to High(_TRK_API_SUPPORTED_VERSIONS) do
    if (_TRK_API_SUPPORTED_VERSIONS[i] = version) then
      Exit(true);
  Result := false;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TTrakceIFace.PickApiVersion();
begin
  for var i: Integer := High(_TRK_API_SUPPORTED_VERSIONS) downto Low(_TRK_API_SUPPORTED_VERSIONS) do
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

class function TTrakceIFace.Callback(callback: TCommandCallbackFunc = nil; data: Pointer = nil): TCommandCallback;
begin
  Result.callback := callback;
  Result.data := data;
end;

class procedure TTrakceIFace.Callbacks(const ok: TCb; const err: TCb; var pOk: PTCb; var pErr: PTCb);
begin
  GetMem(pOk, sizeof(TCb));
  GetMem(pErr, sizeof(TCb));

  pOk^ := ok;
  pErr^ := err;
  pOk^.other := Pointer(pErr);
  pErr^.other := Pointer(pOk);
end;

////////////////////////////////////////////////////////////////////////////////

class function TTrakceIFace.LogLevelToString(ll: TTrkLogLevel): string;
begin
  case (ll) of
    llNo: Result := 'No';
    llErrors: Result := 'Err';
    llWarnings: Result := 'Warn';
    llInfo: Result := 'Info';
    llCommands: Result := 'Cmd';
    llRawCommands: Result := 'Raw';
    llDebug: Result := 'Debug';
  else
    Result := '?';
  end;
end;

////////////////////////////////////////////////////////////////////////////////

class function TTrakceIFace.CallbackDll(const cb: TCb): TDllCb;
var pcb: ^TCb;
begin
  GetMem(pcb, sizeof(TCb));
  pcb^.callback := cb.callback;
  pcb^.data := cb.data;
  pcb^.other := nil;
  Result.data := pcb;
  Result.callback := dllCallback;
end;

////////////////////////////////////////////////////////////////////////////////

class procedure TTrakceIFace.CallbackDllReferOther(var dllCb: TDllCb; const other: TDllCb);
var pcb: ^TCb;
begin
  pcb := dllCb.data;
  pcb^.other := other.data;
end;

class procedure TTrakceIFace.CallbackDllReferEachOther(var first: TDllCb; var second: TDllCb);
begin
  TTrakceIFace.CallbackDllReferOther(first, second);
  TTrakceIFace.CallbackDllReferOther(second, first);
end;

class procedure TTrakceIFace.CallbacksDll(const ok: TCb; const err: TCb; var dllOk: TDllCb; var dllErr: TDllCb);
begin
  dllOk := CallbackDll(ok);
  dllErr := CallbackDll(err);
  CallbackDllReferEachOther(dllOk, dllErr);
end;

////////////////////////////////////////////////////////////////////////////////

function TTrakceIFace.apiVersionStr(): string;
begin
  Result := IntToStr((Self.apiVersion shr 8) and $FF) + '.' + IntToStr(Self.apiVersion and $FF);
 end;

////////////////////////////////////////////////////////////////////////////////

class operator TTrkLocoInfo.Equal(a, b: TTrkLocoInfo): Boolean;
begin
  Result := (a.addr = b.addr) and (a.direction = b.direction) and (a.step = b.step) and
            (a.maxSpeed = b.maxSpeed) and (a.functions = b.functions);
end;

class operator TTrkLocoInfo.NotEqual(a, b: TTrkLocoInfo): Boolean;
begin
  Result := not (a = b);
end;

////////////////////////////////////////////////////////////////////////////////

initialization
  acquiredCallbacks := TDictionary<Word, TLocoAcquiredCallback>.Create();

finalization
  acquiredCallbacks.Free();

end. //unit

