unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls,
  ToolWin,
  ImgList,
  Menus,
  Grids;

type
  TBoxRecord = record
    Character: Char;
    Left, Top, Right, Bottom: Integer;
    Page: Integer;
  end;

  TImageState = (is24Bit, is8Bit, is1Bit, isRotated);

  TfrmMain = class(TForm)
    ScrollBox1: TScrollBox;
    Image1: TImage;
    Panel1: TPanel;
    ListBox1: TListBox;
    ToolBar1: TToolBar;
    tbOpen: TToolButton;
    tbSeparator1: TToolButton;
    tbWidthPlus: TToolButton;
    tbWidthMinus: TToolButton;
    tbSeparator2: TToolButton;
    tbGrayscale: TToolButton;
    tbBinary: TToolButton;
    tbRotate: TToolButton;
    tbSeparator3: TToolButton;
    tbSave: TToolButton;
    Panel2: TPanel;
    btnSaveBox: TButton;
    PopupMenu1: TPopupMenu;
    Rotacionar901: TMenuItem;
    Rotacionar902: TMenuItem;
    Rotacionar1801: TMenuItem;
    N1: TMenuItem;
    Rotaopersonalizada1: TMenuItem;
    StatusBar1: TStatusBar;
    ImageList1: TImageList;
    StringGrid1: TStringGrid;
    tbHeightPlus: TToolButton;
    tbHeightMinus: TToolButton;
    procedure btnSaveBoxClick(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure edtInclinacaoKeyPress(Sender: TObject; var Key: Char);
    procedure tbOpenClick(Sender: TObject);
    procedure tbGrayscaleClick(Sender: TObject);
    procedure tbBinaryClick(Sender: TObject);
    procedure tbSaveClick(Sender: TObject);
    procedure Rotacionar901Click(Sender: TObject);
    procedure Rotacionar902Click(Sender: TObject);
    procedure Rotacionar1801Click(Sender: TObject);
    procedure Rotaopersonalizada1Click(Sender: TObject);
    procedure tbWidthPlusClick(Sender: TObject);
    procedure tbWidthMinusClick(Sender: TObject);
    procedure StringGrid1SetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: String);
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure tbHeightPlusClick(Sender: TObject);
    procedure tbHeightMinusClick(Sender: TObject);
  private
    Boxes: array of TBoxRecord;
    SelectedBox: Integer;
    IsDragging: Boolean;
    DragOffset: TPoint;
    FBufferBitmap: TBitmap;
    FOriginalBitmap: TBitmap;
    FModifiedBmp: TBitmap;
    FRotatedBmp: TBitmap;
    FolderPath: String;
    Processando: Boolean;
    Estado: TImageState;
    procedure DrawBoxes;
    procedure SaveBoxesToBox(const FileName: string);
    procedure DrawBoxesOnCanvas(ACanvas: TCanvas);
    procedure UpdateImageCanvas;
//    procedure ShowBoxesInfo;
    procedure LoadBoxesFromBox(const FileName: string);
    procedure AtualizaTela(pRotacao: Boolean = false);
    procedure Rotacionar(pAngle: Integer);
    procedure SetupToolBar;
    procedure UpdateToolBarState;
    procedure ShowBoxesInGrid;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses FileCtrl, imageenio, StrUtils, Math, imageenproc, hyieutils;

function GetStateDescription(State: TImageState): string;
begin
  case State of
    is24Bit: Result := 'Colorida';
    is8Bit: Result := 'Escala de Cinza';
    is1Bit: Result := 'Binária';
    isRotated: Result := 'Rotacionada';
  end;
end;

procedure RotateBitmap(const Src: TBitmap; Angle: Single; var Dest: TBitmap);
var
  Proc: TImageEnProc;
begin
  Proc := TImageEnProc.Create(nil);
  try
    Dest.Assign(Src);

    // Carrega a imagem no ImageEnProc
    Proc.CreateFromBitmap(Dest);

    // Rotaciona 30 graus com suavização bilinear
    Proc.Rotate(Angle, true, ierBilinear);
  finally
    Proc.Free;
  end;
end;

procedure TfrmMain.Rotacionar(pAngle: Integer);
begin
  Processando := True;

  RotateBitmap(FModifiedBmp, pAngle, FRotatedBmp);

  Estado := isRotated;

  AtualizaTela(true);

  Processando := False;

  // Atualizar estado
  tbSave.Enabled := True;
  UpdateToolBarState;
end;

// Configuração da ToolBar via Designer
procedure TfrmMain.SetupToolBar;
begin
  // Configurações gerais da ToolBar
  ToolBar1.ShowCaptions := True;  // Mostrar texto nos botões
  ToolBar1.ButtonHeight := 32;
  ToolBar1.ButtonWidth := 32;
  ToolBar1.Height := 41;
  ToolBar1.Images := ImageList1;  // Associar ImageList
  ToolBar1.Flat := True;          // Visual moderno
  ToolBar1.Transparent := True;
  ToolBar1.Wrapable := True;      // Quebrar linha se necessário
  
  // Configurar botões individuais
  // tbOpen
  tbOpen.Caption := 'Pasta';
  tbOpen.Hint := 'Selecionar pasta com imagens (Ctrl+O)';
  tbOpen.ImageIndex := 0;  // Índice no ImageList
  tbOpen.ShowHint := True;
  
  // Separador 1
  tbSeparator1.Style := tbsSeparator;
  tbSeparator1.Width := 8;
  
  // tbGrayscale
  tbGrayscale.Caption := 'Cinza';
  tbGrayscale.Hint := 'Converter para escala de cinza';
  tbGrayscale.ImageIndex := 1;
  tbGrayscale.ShowHint := True;
  tbGrayscale.Style := tbsCheck;  // Botão toggle

  // tbBinary
  tbBinary.Caption := 'Binário';
  tbBinary.Hint := 'Converter para preto e branco';
  tbBinary.ImageIndex := 2;
  tbBinary.ShowHint := True;
  tbBinary.Enabled := False;  // Inicialmente desabilitado

  // tbRotate
  tbRotate.Caption := 'Rotação';
  tbRotate.Hint := 'Rotacionar imagem';
  tbRotate.ImageIndex := 3;
  tbRotate.ShowHint := True;
  tbRotate.Style := tbsDropDown;  // Com dropdown

  // Separador 2
  tbSeparator2.Style := tbsSeparator;

  // tbSave
  tbSave.Caption := 'Salvar';
  tbSave.Hint := 'Salvar imagem processada (Ctrl+S)';
  tbSave.ImageIndex := 4;
  tbSave.ShowHint := True;
  tbSave.Enabled := False;

  // Separador 3
  tbSeparator3.Style := tbsSeparator;

  // tbWidthPlus
  tbWidthPlus.Caption := 'Largura +';
  tbWidthPlus.Hint := 'Aumentar largura (+)';
  tbWidthPlus.ImageIndex := 5;
  tbWidthPlus.ShowHint := True;

  // tbWidthMinus
  tbWidthMinus.Caption := 'Largura -';
  tbWidthMinus.Hint := 'Diminuir largura (-)';
  tbWidthMinus.ImageIndex := 6;
  tbWidthMinus.ShowHint := True;

  // tbHeightPlus
  tbHeightPlus.Caption := 'Altura +';
  tbHeightPlus.Hint := 'Aumentar altura (+)';
  tbHeightPlus.ImageIndex := 7;
  tbHeightPlus.ShowHint := True;

  // tbHeightMinus
  tbHeightMinus.Caption := 'Altura -';
  tbHeightMinus.Hint := 'Diminuir altura (-)';
  tbHeightMinus.ImageIndex := 8;
  tbHeightMinus.ShowHint := True;

  // Atualizar estado inicial
  UpdateToolBarState;
end;
{
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
}
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
  FModifiedBmp := TBitmap.Create;
  FRotatedBmp := TBitmap.Create;
  Processando := False;

  StringGrid1.ColCount := 6;
  StringGrid1.Cells[0, 0] := 'Caractere';
  StringGrid1.Cells[1, 0] := 'Esquerda';
  StringGrid1.Cells[2, 0] := 'Topo';
  StringGrid1.Cells[3, 0] := 'Direita';
  StringGrid1.Cells[4, 0] := 'Fundo';
  StringGrid1.Cells[5, 0] := 'Página';

  SetupToolBar;
end;

procedure TfrmMain.ShowBoxesInGrid;
var
  i: Integer;
begin
  StringGrid1.RowCount := Length(Boxes) + 1; // +1 para o header
  for i := 0 to High(Boxes) do
  begin
    StringGrid1.Cells[0, i+1] := Boxes[i].Character;
    StringGrid1.Cells[1, i+1] := IntToStr(Boxes[i].Left);
    StringGrid1.Cells[2, i+1] := IntToStr(Boxes[i].Top);
    StringGrid1.Cells[3, i+1] := IntToStr(Boxes[i].Right);
    StringGrid1.Cells[4, i+1] := IntToStr(Boxes[i].Bottom);
    StringGrid1.Cells[5, i+1] := IntToStr(Boxes[i].Page);
  end;
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
  SelectedFile, FullPath: string;
begin
  if ListBox1.ItemIndex < 0 then exit;
  SelectedFile := copy(ListBox1.Items[ListBox1.ItemIndex],5,30);
  FullPath := FolderPath + ChangeFileExt(SelectedFile, '.box');;

  SaveBoxesToBox(FullPath);
  ShowMessage('Arquivo .box salvo com sucesso!');
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
  FBufferBitmap.PixelFormat := FOriginalBitmap.PixelFormat;

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
  //ShowBoxesInfo;
  ShowBoxesInGrid;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FRotatedBmp.Free;
  FModifiedBmp.Free;
  FBufferBitmap.Free;
  FOriginalBitmap.Free;
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
  //ShowBoxesInfo;
  ShowBoxesInGrid;
end;

procedure TfrmMain.ListBox1Click(Sender: TObject);
var
  SelectedFile, FullPath: string;

  arqgt,arqbox: string;
  ImageEnIO: TImageEnIO;

  SL: TStringList;
  i, x, y, boxWidth, boxHeight: Integer;
  c: Char;
  texto: String;
  f: TextFile;
begin
  if ListBox1.ItemIndex < 0 then Exit;
//  Memo1.Clear;
  
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
    case Image1.Picture.Bitmap.PixelFormat of
      pf1bit          : Estado := is1Bit;
      pf8bit          : Estado := is8Bit;
      pf16bit,pf24bit : Estado := is24Bit;
    end;                                  

    FOriginalBitmap.Assign(Image1.Picture.Bitmap);

    ScrollBox1.HorzScrollBar.Range := Image1.Width;
    ScrollBox1.VertScrollBar.Range := Image1.Height;
    Boxes := nil; // limpa caixas ao carregar nova imagem
    Invalidate;
  finally
    ImageEnIO.Free;
  end;

  arqgt := ChangeFileExt(FullPath, '.gt.txt');
  if not FileExists(arqgt) then begin
    texto := InputBox('Texto gt.txt','Informe o texto que aparece na imagem','');
    if texto = '' then
      exit;
    AssignFile(f, arqgt);
    Rewrite(f);
    Writeln(f, texto);
    CloseFile(f);
  end;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(arqgt);
    if SL.Text = '' then
      raise Exception.Create('Erro na tentativa de carregar o texto!');
    // Concatenar todas as linhas para uma única string de caracteres
    texto := SL.Text;
    texto := StringReplace(texto, #13#10, '', [rfReplaceAll]);
    texto := StringReplace(texto, #10, '', [rfReplaceAll]);
    SetLength(Boxes, Length(texto));

    // Definir tamanho padrão da caixa (ajuste conforme necessário)
    boxWidth := 75;
    boxHeight := 85;
    x := 10; // margem inicial X
    y := 10; // margem inicial Y

    for i := 1 to Length(texto) do
    begin
      c := texto[i];
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
//  ShowBoxesInfo; // opcional: mostrar lista de caixas
  ShowBoxesInGrid;

  UpdateToolBarState;
end;

procedure TfrmMain.AtualizaTela(pRotacao: Boolean = false);
begin
  if pRotacao then begin
    FBufferBitmap.Width := FRotatedBmp.Width;
    FBufferBitmap.Height := FRotatedBmp.Height;

    // Copia a imagem original limpa para o buffer
    FBufferBitmap.Canvas.Draw(0, 0, FRotatedBmp);
  end else begin
    FBufferBitmap.Width := FModifiedBmp.Width;
    FBufferBitmap.Height := FModifiedBmp.Height;

    // Copia a imagem original limpa para o buffer
    FBufferBitmap.Canvas.Draw(0, 0, FModifiedBmp);
  end;

// Desconsiderar PixelFormat. Se for pf1bit provoca erro.
// FBufferBitmap.PixelFormat := FModifiedBmp.PixelFormat;

  // Desenha as caixas no buffer
  DrawBoxesOnCanvas(FBufferBitmap.Canvas);

  // Atualiza o Image1 com o bitmap buffer
  Image1.Picture.Bitmap.Assign(FBufferBitmap);
  Image1.Invalidate;
end;

procedure TfrmMain.edtInclinacaoKeyPress(Sender: TObject; var Key: Char);
const
  chars = ['0'..'9','-',#8];
begin
  if not (Key in chars) then
    Key := #0;
end;

procedure TfrmMain.tbOpenClick(Sender: TObject);
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

  // Atualizar estado da toolbar após carregar
  UpdateToolBarState;
end;

procedure TfrmMain.tbGrayscaleClick(Sender: TObject);
var
  Proc: TImageEnProc;
begin
  Proc := TImageEnProc.Create(nil);
  try
    FModifiedBmp.Assign(FOriginalBitmap);

    // Carrega a imagem no ImageEnProc
    Proc.CreateFromBitmap(FModifiedBmp);
//    Proc.DoPreviews()

    // Converte para escala de cinza
    Proc.ConvertToGray;
  finally
    Proc.Free;
  end;

  Estado := is8Bit;

  AtualizaTela;

  // Atualizar estado - habilitar próximo passo
  tbBinary.Enabled := True;
  tbGrayscale.Down := True;  // Marcar como pressionado

  UpdateToolBarState;
end;

procedure TfrmMain.tbBinaryClick(Sender: TObject);
var
  Proc: TImageEnProc;
begin
  Proc := TImageEnProc.Create(nil);
  try
    // Carrega a imagem no ImageEnProc
    Proc.CreateFromBitmap(FModifiedBmp);

    // Converte para binário (preto e branco)
    Proc.ConvertToBWThreshold();
  finally
    Proc.Free;
  end;

  Estado := is1Bit;

  AtualizaTela;

  // Atualizar estado
  tbRotate.Enabled := True;
  UpdateToolBarState;
end;

procedure TfrmMain.tbSaveClick(Sender: TObject);
var
  SelectedFile, FullPath: string;
  ImageEnIO: TImageEnIO;
begin

  SelectedFile := copy(ListBox1.Items[ListBox1.ItemIndex],5,30);
  FullPath := FolderPath + SelectedFile;

  RenameFile(FullPath, ChangeFileExt(FullPath,'.bak'));

  ImageEnIO := TImageEnIO.Create(nil);
  try
    // Salva o bitmap rotacionado em TIFF
    if Estado = isRotated then
      ImageEnIO.CreateFromBitmap(FRotatedBmp)
    else
      ImageEnIO.CreateFromBitmap(FModifiedBmp);
    ImageEnIO.SaveToFile(FullPath);
  finally
    ImageEnIO.Free;
  end;

  if Estado = isRotated then
    FOriginalBitmap.Assign(FRotatedBmp)
  else
    FOriginalBitmap.Assign(FModifiedBmp);

  UpdateToolBarState;
end;

procedure TfrmMain.UpdateToolBarState;
begin
  // Baseado no seu enum TImageState
  case Estado of
    is24Bit:
    begin
      tbGrayscale.Enabled := True;
      tbBinary.Enabled := False;
      tbRotate.Enabled := False;
      tbSave.Enabled := False;
    end;
    
    is8Bit:
    begin
      tbGrayscale.Enabled := False;
      tbGrayscale.Down := True;
      tbBinary.Enabled := True;
      tbRotate.Enabled := False;
      tbSave.Enabled := False;
    end;
    
    is1Bit:
    begin
      tbGrayscale.Down := True;
      tbBinary.Enabled := False;
      tbRotate.Enabled := True;
      tbSave.Enabled := False;
    end;
    
    isRotated:
    begin
      tbSave.Enabled := True;
    end;
  end;

  // Atualizar StatusBar com informações
  if Assigned(StatusBar1) then
  begin
    StatusBar1.Panels[0].Text := Format('Estado: %s', [GetStateDescription(Estado)]);
    StatusBar1.Panels[1].Text := Format('Imagem: %d x %d', [Image1.Width, Image1.Height]);
  end;
end;

procedure TfrmMain.Rotacionar901Click(Sender: TObject);
begin
  if ListBox1.ItemIndex < 0 then exit;
  
  Rotacionar(-90);
end;

procedure TfrmMain.Rotacionar902Click(Sender: TObject);
begin
  if ListBox1.ItemIndex < 0 then exit;

  Rotacionar(90);
end;

procedure TfrmMain.Rotacionar1801Click(Sender: TObject);
begin
  if ListBox1.ItemIndex < 0 then exit;

  Rotacionar(180);
end;

procedure TfrmMain.Rotaopersonalizada1Click(Sender: TObject);
var
  Angle: string;
begin
  if ListBox1.ItemIndex < 0 then exit;

  Angle := InputBox('Rotação Personalizada', 'Digite o ângulo (-360 a 360):', '0');
  if (Angle = '') or (StrToIntDef(Angle, 999) = 999) then
    exit;

  if (StrToInt(Angle) < -360)or(StrToInt(Angle) > 360) then
  begin
    ShowMessage('Valor de grau de inclinação inválido!');
    exit;
  end;

  Rotacionar(StrToInt(Angle));
end;

procedure TfrmMain.tbWidthPlusClick(Sender: TObject);
begin
  if SelectedBox >= 0 then
  begin
    with Boxes[SelectedBox] do
      Right := Right + 5;
    UpdateImageCanvas;
//    ShowBoxesInfo;
    ShowBoxesInGrid;
  end;
end;

procedure TfrmMain.tbWidthMinusClick(Sender: TObject);
begin
  if SelectedBox >= 0 then
  begin
    with Boxes[SelectedBox] do
      if (Right - Left) > 10 then
        Right := Right - 5;
    UpdateImageCanvas;
//    ShowBoxesInfo;
    ShowBoxesInGrid;
  end;
end;

procedure TfrmMain.StringGrid1SetEditText(Sender: TObject; ACol,
  ARow: Integer; const Value: String);
var
  idx: Integer;
begin
  idx := ARow - 1; // porque a linha 0 é header
  if (idx < 0) or (idx > High(Boxes)) then Exit;

  case ACol of
    0: Boxes[idx].Character := Value[1];
    1: Boxes[idx].Left := StrToIntDef(Value, Boxes[idx].Left);
    2: Boxes[idx].Top := StrToIntDef(Value, Boxes[idx].Top);
    3: Boxes[idx].Right := StrToIntDef(Value, Boxes[idx].Right);
    4: Boxes[idx].Bottom := StrToIntDef(Value, Boxes[idx].Bottom);
    5: Boxes[idx].Page := StrToIntDef(Value, Boxes[idx].Page);
  end;
  UpdateImageCanvas; // redesenha as caixas com os novos valores
end;

procedure TfrmMain.StringGrid1SelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
begin
  // Verifica se não é o header (linha 0)
  if ARow > 0 then
  begin
    SelectedBox := ARow - 1; // Supondo que SelectedBox é o índice no array Boxes
    // Atualize a interface ou faça outras ações necessárias
    // Por exemplo, redesenhar a seleção ou mostrar detalhes do box selecionado
    UpdateImageCanvas; // redesenha as caixas com os novos valores
  end;
end;

procedure TfrmMain.tbHeightPlusClick(Sender: TObject);
begin
  if SelectedBox >= 0 then
  begin
    with Boxes[SelectedBox] do
      Bottom := Bottom + 5;
    UpdateImageCanvas;
//    ShowBoxesInfo;
    ShowBoxesInGrid;
  end;
end;

procedure TfrmMain.tbHeightMinusClick(Sender: TObject);
begin
  if SelectedBox >= 0 then
  begin
    with Boxes[SelectedBox] do
      if (Bottom - Top) > 10 then
        Bottom := Bottom - 5;
    UpdateImageCanvas;
//    ShowBoxesInfo;
    ShowBoxesInGrid;
  end;
end;

end.

