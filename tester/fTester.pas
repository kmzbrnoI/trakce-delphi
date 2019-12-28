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
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure B_LoadClick(Sender: TObject);
    procedure B_UnloadClick(Sender: TObject);
  private
    { Private declarations }
  public
    trakce: TTrakceIFace;

    procedure TrakceLog(Sender: TObject; logLevel:TTrkLogLevel; msg:string);
    procedure OnAppException(Sender: TObject; E: Exception);
  end;

var
  F_Tester: TF_Tester;

implementation

{$R *.dfm}

procedure TF_Tester.B_LoadClick(Sender: TObject);
begin
 trakce.LoadLib(Self.E_Path.Text);
end;

procedure TF_Tester.B_UnloadClick(Sender: TObject);
begin
 trakce.UnloadLib();
end;

procedure TF_Tester.FormCreate(Sender: TObject);
begin
 Application.OnException := Self.OnAppException;
 Self.trakce := TTrakceIFace.Create();
end;

procedure TF_Tester.FormDestroy(Sender: TObject);
begin
 Self.trakce.Free();
end;

procedure TF_Tester.TrakceLog(Sender: TObject; logLevel:TTrkLogLevel; msg:string);
begin
 Self.M_Log.Lines.Add(FormatDateTime('hh:nn:ss,zzz', Now) + ': ' +
                      trakce.LogLevelToString(logLevel) + ': ' + msg);
end;

procedure TF_Tester.OnAppException(Sender: TObject; E: Exception);
begin
 Self.TrakceLog(Self, llErrors, 'Exception: ' + E.Message);
end;

end.
