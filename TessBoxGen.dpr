program TessBoxGen;

uses
  Forms,
  MainForm in 'MainForm.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Tesseract Box Gen';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
