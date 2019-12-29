unit fTester;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Trakce, Spin;

type
  TF_Tester = class(TForm)
    M_Log: TMemo;
    E_Path: TEdit;
    B_Load: TButton;
    B_Unload: TButton;
    B_DCC_Go: TButton;
    B_DCC_Stop: TButton;
    B_Show_Config: TButton;
    B_Open: TButton;
    B_Close: TButton;
    Label1: TLabel;
    CB_Loglevel: TComboBox;
    SE_Loco_Addr: TSpinEdit;
    Label2: TLabel;
    B_Loco_Acquire: TButton;
    B_Loco_Release: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure B_LoadClick(Sender: TObject);
    procedure B_UnloadClick(Sender: TObject);
    procedure M_LogDblClick(Sender: TObject);
    procedure B_Show_ConfigClick(Sender: TObject);
    procedure B_DCC_GoClick(Sender: TObject);
    procedure B_DCC_StopClick(Sender: TObject);
    procedure B_OpenClick(Sender: TObject);
    procedure B_CloseClick(Sender: TObject);
    procedure B_Loco_AcquireClick(Sender: TObject);
    procedure B_Loco_ReleaseClick(Sender: TObject);
  private
    { Private declarations }
  public
    trakce: TTrakceIFace;

    procedure Log(Sender: TObject; logLevel:TTrkLogLevel; msg:string);
    procedure OnAppException(Sender: TObject; E: Exception);
    procedure OnTrackStatusChanged(Sender: TObject; status: TTrkStatus);
    procedure OnLocoStolen(Sender: TObject; addr: Word);
    procedure OnTrkSetOk(Sender: TObject; data: Pointer);
    procedure OnTrkSetError(Sender: TObject; data: Pointer);

    procedure OnTrkBeforeOpen(Sender: TObject);
    procedure OnTrkAfterOpen(Sender: TObject);
    procedure OnTrkBeforeClose(Sender: TObject);
    procedure OnTrkAfterClose(Sender: TObject);
  end;

var
  F_Tester: TF_Tester;

implementation

{$R *.dfm}

procedure TF_Tester.B_CloseClick(Sender: TObject);
begin
 trakce.Disconnect();
end;

procedure TF_Tester.B_DCC_GoClick(Sender: TObject);
begin
 trakce.SetTrackStatus(TTrkStatus.tsOn, TTrakceIFace.Callback(Self.OnTrkSetOk),
                       TTrakceIFace.Callback(Self.OnTrkSetError));
end;

procedure TF_Tester.B_DCC_StopClick(Sender: TObject);
begin
 trakce.SetTrackStatus(TTrkStatus.tsOff, TTrakceIFace.Callback(Self.OnTrkSetOk),
                       TTrakceIFace.Callback(Self.OnTrkSetError));
end;

procedure TF_Tester.B_LoadClick(Sender: TObject);
var unbound, lib: string;
begin
 Self.Log(Self, llInfo, 'Loading library...');
 trakce.LoadLib(Self.E_Path.Text);
 Self.Log(Self, llInfo, 'Library loaded');

 unbound := '';
 for lib in trakce.unbound do
   unbound := unbound + lib + ', ';
 if (unbound <> '') then
   Self.Log(Self, llErrors, 'Unbound: ' + unbound);
end;

procedure TF_Tester.B_Loco_AcquireClick(Sender: TObject);
begin
 trakce.LocoAcquire(Self.SE_Loco_Addr.Value, nil, TTrakceIFace.Callback(Self.OnTrkSetError));
end;

procedure TF_Tester.B_Loco_ReleaseClick(Sender: TObject);
begin
 trakce.LocoRelease(Self.SE_Loco_Addr.Value, TTrakceIFace.Callback(Self.OnTrkSetOk));
end;

procedure TF_Tester.B_OpenClick(Sender: TObject);
begin
 trakce.Connect();
end;

procedure TF_Tester.B_Show_ConfigClick(Sender: TObject);
begin
 trakce.ShowConfigDialog();
end;

procedure TF_Tester.B_UnloadClick(Sender: TObject);
begin
 Self.Log(Self, llInfo, 'Unloading library...');
 trakce.UnloadLib();
 Self.Log(Self, llInfo, 'Library unloaded');
end;

procedure TF_Tester.FormCreate(Sender: TObject);
begin
 Application.OnException := Self.OnAppException;
 Self.trakce := TTrakceIFace.Create();
 Self.trakce.OnLog := Self.Log;
 Self.trakce.OnTrackStatusChanged := Self.OnTrackStatusChanged;
 Self.trakce.OnLocoStolen := Self.OnLocoStolen;
 Self.trakce.BeforeOpen := Self.OnTrkBeforeOpen;
 Self.trakce.AfterOpen := Self.OnTrkAfterOpen;
 Self.trakce.BeforeClose := Self.OnTrkBeforeClose;
 Self.trakce.AfterClose := Self.OnTrkAfterClose;
end;

procedure TF_Tester.FormDestroy(Sender: TObject);
begin
 Self.trakce.Free();
end;

procedure TF_Tester.M_LogDblClick(Sender: TObject);
begin
 Self.M_Log.Clear();
end;

procedure TF_Tester.Log(Sender: TObject; logLevel:TTrkLogLevel; msg:string);
begin
 if (Integer(logLevel) <= Self.CB_Loglevel.ItemIndex) then
   Self.M_Log.Lines.Insert(0, FormatDateTime('hh:nn:ss,zzz', Now) + ': ' +
                           trakce.LogLevelToString(logLevel) + ': ' + msg);
end;

procedure TF_Tester.OnAppException(Sender: TObject; E: Exception);
begin
 Self.Log(Self, llErrors, 'Exception: ' + E.Message);
end;

procedure TF_Tester.OnTrackStatusChanged(Sender: TObject; status: TTrkStatus);
begin
 case (status) of
  tsUnknown: Self.Log(Self, llInfo, 'Track status changed: UNKNOWN');
  tsOff: Self.Log(Self, llInfo, 'Track status changed: OFF');
  tsOn: Self.Log(Self, llInfo, 'Track status changed: ON');
  tsProgramming: Self.Log(Self, llInfo, 'Track status changed: PROGRAMMING');
 end;
end;

procedure TF_Tester.OnLocoStolen(Sender: TObject; addr: Word);
begin
 Self.Log(Self, llInfo, 'Loco stolen: ' + IntToStr(addr));
end;

procedure TF_Tester.OnTrkSetOk(Sender: TObject; data: Pointer);
begin
 Self.Log(Self, llInfo, 'OK, data: ' + IntToStr(Integer(data)));
end;

procedure TF_Tester.OnTrkSetError(Sender: TObject; data: Pointer);
begin
 Self.Log(Self, llErrors, 'ERR, data: ' + IntToStr(Integer(data)));
end;

procedure TF_Tester.OnTrkBeforeOpen(Sender: TObject);
begin
 Self.Log(Self, llInfo, 'BeforeOpen');
end;

procedure TF_Tester.OnTrkAfterOpen(Sender: TObject);
begin
 Self.Log(Self, llInfo, 'AfterOpen');
end;

procedure TF_Tester.OnTrkBeforeClose(Sender: TObject);
begin
 Self.Log(Self, llInfo, 'BeforeClose');
end;

procedure TF_Tester.OnTrkAfterClose(Sender: TObject);
begin
 Self.Log(Self, llInfo, 'AfterClose');
end;

end.
