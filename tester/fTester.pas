unit fTester;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Trakce;

type
  TF_Tester = class(TForm)
    M_Log: TMemo;
    E_Path: TEdit;
    B_Load: TButton;
    B_Unload: TButton;
    B_DCC_Go: TButton;
    B_DCC_Stop: TButton;
    B_Show_Config: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure B_LoadClick(Sender: TObject);
    procedure B_UnloadClick(Sender: TObject);
    procedure M_LogDblClick(Sender: TObject);
    procedure B_Show_ConfigClick(Sender: TObject);
    procedure B_DCC_GoClick(Sender: TObject);
    procedure B_DCC_StopClick(Sender: TObject);
  private
    { Private declarations }
  public
    trakce: TTrakceIFace;

    procedure Log(Sender: TObject; logLevel:TTrkLogLevel; msg:string);
    procedure OnAppException(Sender: TObject; E: Exception);
  end;

var
  F_Tester: TF_Tester;

implementation

{$R *.dfm}

procedure TF_Tester.B_DCC_GoClick(Sender: TObject);
begin
 trakce.SetTrackStatus(TTrkStatus.tsOn, TTrakceIFace.Callback(), TTrakceIFace.Callback());
end;

procedure TF_Tester.B_DCC_StopClick(Sender: TObject);
begin
 trakce.SetTrackStatus(TTrkStatus.tsOff, TTrakceIFace.Callback(), TTrakceIFace.Callback());
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
 Self.M_Log.Lines.Insert(0, FormatDateTime('hh:nn:ss,zzz', Now) + ': ' +
                         trakce.LogLevelToString(logLevel) + ': ' + msg);
end;

procedure TF_Tester.OnAppException(Sender: TObject; E: Exception);
begin
 Self.Log(Self, llErrors, 'Exception: ' + E.Message);
end;

end.
