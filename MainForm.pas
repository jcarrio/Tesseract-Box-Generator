unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls;

type
  TBoxRecord = record
    Character: Char;
    Left, Top, Right, Bottom: Integer;
    Page: Integer;
  end;

  TfrmMain = class(TForm)
    ScrollBox1: TScrollBox;
    Image1: TImage;
    Panel1: TPanel;
    Panel2: TPanel;
    Memo1: TMemo;
    ListBox1: TListBox;
    btnPasta: TButton;
    btnIncrease: TButton;
    btnDecrease: TButton;
    btnSaveBox: TButton;
    SaveDialog1: TSaveDialog;
    procedure btnSaveBoxClick(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnIncreaseClick(Sender: TObject);
    procedure btnDecreaseClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure btnPastaClick(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
  private
    Boxes: array of TBoxRecord;
    SelectedBox: Integer;
    IsDragging: Boolean;
    DragOffset: TPoint;
    FBufferBitmap: TBitmap;
    FOriginalBitmap: TBitmap;
    FolderPath: String;
    procedure DrawBoxes;
    procedure SaveBoxesToBox(const FileName: string);
    procedure DrawBoxesOnCanvas(ACanvas: TCanvas);
    procedure UpdateImageCanvas;
    procedure ShowBoxesInfo;
    procedure LoadBoxesFromBox(const FileName: string);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses FileCtrl, imageenio,
  StrUtils;

procedure TfrmMain.ShowBoxesInfo;
var
  i: Integer;
  imgHeight: Integer;
  line: string;
begin
  Memo1.Lines.Clear;
  imgHeight := Image1.Picture.Height;
  for i := 0 to High(Boxes) do
  begin
    // Converte coordenadas para o padrão Tesseract (origem inferior esquerda)
    line := Format('Char: %s | Left: %d | Bottom: %d | Right: %d | Top: %d | Page: %d',
      [Boxes[i].Character,
       Boxes[i].Left,
       imgHeight - Boxes[i].Bottom,
       Boxes[i].Right,
       imgHeight - Boxes[i].Top,
       Boxes[i].Page]);
    Memo1.Lines.Add(line);
  end;
end;

procedure SplitString(const S: string; const Delimiters: TSysCharSet; List: TStrings);
begin
  List.Clear;
  ExtractStrings(Delimiters, [], PChar(S), List);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  SelectedBox := -1;
  IsDragging := False;
  FBufferBitmap := TBitmap.Create;
  FOriginalBitmap := TBitmap.Create;
end;

procedure TfrmMain.LoadBoxesFromBox(const FileName: string);
var
  SL, Parts: TStringList;
  i: Integer;
  c: Char;
  l, b, r, t, p: Integer;
  imgHeight: Integer;
begin
  SL := TStringList.Create;
  Parts := TStringList.Create;
  try
    SL.LoadFromFile(FileName);
    if SL.Text = '' then
      exit;
    SetLength(Boxes, SL.Count);
    imgHeight := Image1.Picture.Height;

    for i := 0 to SL.Count - 1 do
    begin
      Parts.Clear;
      ExtractStrings([' '], [], PChar(SL[i]), Parts);
      if Parts.Count >= 6 then
      begin
        c := Parts[0][1];
        l := StrToIntDef(Parts[1], 0);
        b := StrToIntDef(Parts[2], 0);
        r := StrToIntDef(Parts[3], 0);
        t := StrToIntDef(Parts[4], 0);
        p := StrToIntDef(Parts[5], 0);

        Boxes[i].Character := c;
        Boxes[i].Left := l;
        Boxes[i].Top := imgHeight - t;
        Boxes[i].Right := r;
        Boxes[i].Bottom := imgHeight - b;
        Boxes[i].Page := p;
      end;
    end;
  finally
    SL.Free;
    Parts.Free;
  end;
end;

procedure TfrmMain.SaveBoxesToBox(const FileName: string);
var
  SL: TStringList;
  i: Integer;
  imgHeight: Integer;
begin
  SL := TStringList.Create;
  try
    imgHeight := Image1.Picture.Height;
    for i := 0 to High(Boxes) do
    begin
      // Inverte coordenadas Y para o formato box do Tesseract (origem no canto inferior esquerdo)
      SL.Add(Format('%s %d %d %d %d %d',
        [Boxes[i].Character,
         Boxes[i].Left,
         imgHeight - Boxes[i].Bottom,
         Boxes[i].Right,
         imgHeight - Boxes[i].Top,
         Boxes[i].Page]));
    end;
    SL.SaveToFile(ChangeFileExt(FileName, '.box'));
  finally
    SL.Free;
  end;
end;

procedure TfrmMain.btnSaveBoxClick(Sender: TObject);
var
  SelectedFile: string;
begin
  SelectedFile := copy(ListBox1.Items[ListBox1.ItemIndex],5,30);
  SaveDialog1.FileName := FolderPath + ChangeFileExt(SelectedFile, '.box');
  if SaveDialog1.Execute then
  begin
    SaveBoxesToBox(SaveDialog1.FileName);
    ShowMessage('Arquivo .box salvo com sucesso!');
  end;
end;

procedure TfrmMain.DrawBoxes;
var
  i: Integer;
  r: TRect;
begin
  if Image1.Picture.Bitmap = nil then Exit;

  Image1.Picture.Bitmap.Canvas.Pen.Color := clRed;
  Image1.Picture.Bitmap.Canvas.Pen.Width := 2;
  Image1.Picture.Bitmap.Canvas.Brush.Style := bsClear;

  for i := 0 to High(Boxes) do
  begin
    r := Rect(Boxes[i].Left, Boxes[i].Top, Boxes[i].Right, Boxes[i].Bottom);
    Image1.Picture.Bitmap.Canvas.Rectangle(r);
    Image1.Picture.Bitmap.Canvas.TextOut(Boxes[i].Left + 2, Boxes[i].Top + 2, Boxes[i].Character);
  end;
end;

procedure TfrmMain.DrawBoxesOnCanvas(ACanvas: TCanvas);
var
  i: Integer;
  r: TRect;
begin
  for i := 0 to High(Boxes) do
  begin
    r := Rect(Boxes[i].Left, Boxes[i].Top, Boxes[i].Right, Boxes[i].Bottom);
    if i = SelectedBox then
      ACanvas.Pen.Color := clBlue  // cor diferente para a caixa selecionada
    else
      ACanvas.Pen.Color := clRed;
    ACanvas.Pen.Width := 2;
    ACanvas.Brush.Style := bsClear;

    ACanvas.Rectangle(r);
    ACanvas.TextOut(Boxes[i].Left + 2, Boxes[i].Top + 2, Boxes[i].Character);
  end;
end;

procedure TfrmMain.UpdateImageCanvas;
begin
  if FOriginalBitmap = nil then Exit;

  FBufferBitmap.Width := FOriginalBitmap.Width;
  FBufferBitmap.Height := FOriginalBitmap.Height;
  FBufferBitmap.PixelFormat := pf24bit;

  // Copia a imagem original limpa para o buffer
  FBufferBitmap.Canvas.Draw(0, 0, FOriginalBitmap);

  // Desenha as caixas no buffer
  DrawBoxesOnCanvas(FBufferBitmap.Canvas);

  // Atualiza o Image1 com o bitmap buffer
  Image1.Picture.Bitmap.Assign(FBufferBitmap);
  Image1.Invalidate;
end;

procedure TfrmMain.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  FoundBox: Boolean;
begin
//  SelectedBox := -1;
  for i := High(Boxes) downto 0 do // do fim para o começo para pegar caixa superior
  begin
    if (X >= Boxes[i].Left) and (X <= Boxes[i].Right) and
       (Y >= Boxes[i].Top) and (Y <= Boxes[i].Bottom) then
    begin
      SelectedBox := i;
      DragOffset := Point(X - Boxes[i].Left, Y - Boxes[i].Top);
      IsDragging := True;
      FoundBox := True;
      Break;
    end;
  end;

  if not FoundBox then
  begin
    // Não remove a seleção aqui para permitir mover a caixa selecionada clicando fora dela
    // Se quiser desmarcar ao clicar fora, pode descomentar:
    // SelectedBox := -1;
    IsDragging := False;
  end;
end;

procedure TfrmMain.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if IsDragging and (SelectedBox > -1) then
  begin
    with Boxes[SelectedBox] do
    begin
      Right := Right - Left + (X - DragOffset.X);
      Bottom := Bottom - Top + (Y - DragOffset.Y);
      Left := X - DragOffset.X;
      Top := Y - DragOffset.Y;
    end;
    UpdateImageCanvas;  // redesenha tudo sem rastro
  end;
end;

procedure TfrmMain.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  IsDragging := False;
  ShowBoxesInfo;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FBufferBitmap.Free;
  FOriginalBitmap.Free;
end;

procedure TfrmMain.btnIncreaseClick(Sender: TObject);
begin
  if SelectedBox >= 0 then
  begin
    with Boxes[SelectedBox] do
    begin
      Right := Right + 5;
      Bottom := Bottom + 5;
    end;
    UpdateImageCanvas;
    ShowBoxesInfo;
  end;
end;

procedure TfrmMain.btnDecreaseClick(Sender: TObject);
begin
  if SelectedBox >= 0 then
  begin
    with Boxes[SelectedBox] do
    begin
      if (Right - Left) > 10 then
        Right := Right - 5;
      if (Bottom - Top) > 10 then
        Bottom := Bottom - 5;
    end;
    UpdateImageCanvas;
    ShowBoxesInfo;
  end;
end;

procedure TfrmMain.Image1Click(Sender: TObject);
var
  boxWidth, boxHeight: Integer;
  newLeft, newTop: Integer;
begin
  if SelectedBox < 0 then Exit; // nenhuma caixa selecionada

  with Boxes[SelectedBox] do
  begin
    boxWidth := Right - Left;
    boxHeight := Bottom - Top;

    // Centraliza a caixa na posição clicada
    newLeft := Image1.ScreenToClient(Mouse.CursorPos).X - boxWidth div 2;
    newTop := Image1.ScreenToClient(Mouse.CursorPos).Y - boxHeight div 2;

    // Ajusta coordenadas da caixa
    Left := newLeft;
    Top := newTop;
    Right := Left + boxWidth;
    Bottom := Top + boxHeight;
  end;

  UpdateImageCanvas;
  ShowBoxesInfo;
end;

procedure TfrmMain.btnPastaClick(Sender: TObject);
var
  SearchRec: TSearchRec;
  FileName: string;
  SelectedDirectory: string;
  numero: integer;

  function RemoveNonNumericChars(const s: string): integer;
  var
    resp: String;
    i: integer;
  begin
    resp := '';
    for i := 1 to Length(s) do
      if s[i] in ['0'..'9'] then
        resp := resp + s[i];
    result := StrToIntDef(resp,0);
  end;

begin
  if SelectDirectory('Selecione uma pasta', 'D:\Treinamento', SelectedDirectory) then
  begin
    FolderPath := IncludeTrailingPathDelimiter(SelectedDirectory);
    ListBox1.Items.Clear;

    if FindFirst(FolderPath + '*.tif', faAnyFile, SearchRec) = 0 then
    begin
      repeat
        FileName := SearchRec.Name;
        numero := RemoveNonNumericChars(FileName);
        ListBox1.Items.Add(Format('%3.3d',[Numero])+ ';' +FileName);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;

    if ListBox1.Items.Count = 0 then
      ShowMessage('Nenhum arquivo .tif encontrado na pasta selecionada.')
    else
      ListBox1.Sorted := True;
  end;
end;

procedure TfrmMain.ListBox1Click(Sender: TObject);
var
  SelectedFile, FullPath: string;

  arqgt,arqbox: string;
  ImageEnIO: TImageEnIO;

  SL: TStringList;
  i, x, y, boxWidth, boxHeight: Integer;
  c: Char;
  text: String;
begin
  if ListBox1.ItemIndex < 0 then Exit;
  Memo1.Clear;
  
  SelectedFile := copy(ListBox1.Items[ListBox1.ItemIndex],5,30);
  FullPath := FolderPath + SelectedFile;

  ImageEnIO := TImageEnIO.Create(nil);
  try
    ImageEnIO.LoadFromFile(FullPath);
    if Assigned(ImageEnIO.IEBitmap) then
      ImageEnIO.IEBitmap.CopyToTBitmap(Image1.Picture.Bitmap)
    else
      raise Exception.Create('Erro na tentativa de carregar a imagem!');
    Image1.Width := Image1.Picture.Width;
    Image1.Height := Image1.Picture.Height;

    FOriginalBitmap.Assign(Image1.Picture.Bitmap);

    ScrollBox1.HorzScrollBar.Range := Image1.Width;
    ScrollBox1.VertScrollBar.Range := Image1.Height;
    Boxes := nil; // limpa caixas ao carregar nova imagem
    Invalidate;
  finally
    ImageEnIO.Free;
  end;

  arqgt := ChangeFileExt(FullPath, '.gt.txt');
  if not FileExists(arqgt) then
    exit;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(arqgt);
    if SL.Text = '' then
      raise Exception.Create('Erro na tentativa de carregar o texto!');
    // Concatenar todas as linhas para uma única string de caracteres
    text := SL.Text;
    text := StringReplace(text, #13#10, '', [rfReplaceAll]);
    text := StringReplace(text, #10, '', [rfReplaceAll]);
    SetLength(Boxes, Length(text));

    // Definir tamanho padrão da caixa (ajuste conforme necessário)
    boxWidth := 75;
    boxHeight := 85;
    x := 1800; // margem inicial X
    y := 700; // margem inicial Y

    for i := 1 to Length(text) do
    begin
      c := text[i];
      Boxes[i-1].Character := c;
      Boxes[i-1].Left := x;
      Boxes[i-1].Top := y;
      Boxes[i-1].Right := x + boxWidth;
      Boxes[i-1].Bottom := y + boxHeight;
      Boxes[i-1].Page := 0;

      x := x + boxWidth + 5; // espaço entre caixas
      // Opcional: quebre linha se ultrapassar largura da imagem
      if x + boxWidth > Image1.Width then
      begin
        x := 10;
        y := y + boxHeight + 5;
      end;
    end;
  finally
    SL.Free;
  end;

  arqbox := ChangeFileExt(FullPath, '.box');
  if FileExists(arqbox) then
    LoadBoxesFromBox(arqbox); // substitui as caixas pelas do .box

  UpdateImageCanvas;
  ShowBoxesInfo; // opcional: mostrar lista de caixas

end;

end.

