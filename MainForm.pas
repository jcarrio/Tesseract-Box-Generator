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
    tbApply: TToolButton;
    ImageList2: TImageList;
    tbUndo: TToolButton;
    tbRedo: TToolButton;
    ToolButton3: TToolButton;
    TrackBarRotate: TTrackBar;
    LabelRotateValue: TLabel;
    TrackBarThreshold: TTrackBar;
    LabelThresholdValue: TLabel;
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
    procedure tbSaveClick(Sender: TObject);
    procedure tbWidthPlusClick(Sender: TObject);
    procedure tbWidthMinusClick(Sender: TObject);
    procedure StringGrid1SetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: String);
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure tbHeightPlusClick(Sender: TObject);
    procedure tbHeightMinusClick(Sender: TObject);
    procedure tbUndoClick(Sender: TObject);
    procedure tbRedoClick(Sender: TObject);
    procedure tbApplyClick(Sender: TObject);
    procedure tbBinaryClick(Sender: TObject);
    procedure tbRotateClick(Sender: TObject);
    procedure TrackBarThresholdChange(Sender: TObject);
    procedure TrackBarRotateChange(Sender: TObject);
  private
    Boxes: array of TBoxRecord;
    SelectedBox: Integer;
    IsDragging: Boolean;
    DragOffset: TPoint;
    FBufferBitmap: TBitmap;
    FOriginalBitmap: TBitmap;
    FModifiedBmp: TBitmap;
    FolderPath: String;
    Processando: Boolean;
    Clicando: Boolean;

    FUndoList: array of TBitmap;
    FRedoList: array of TBitmap;
    MaxUndoSteps: Integer;
    procedure PushUndoState;
    procedure ClearRedoStates;
    procedure Undo;
    procedure Redo;
    procedure ClearUndoStates;

    procedure DrawBoxes;
    procedure SaveBoxesToBox(const FileName: string);
    procedure DrawBoxesOnCanvas(ACanvas: TCanvas);
    procedure UpdateImageCanvas;
    procedure LoadBoxesFromBox(const FileName: string);
    procedure AtualizaTela;
    procedure SetupToolBar;
    procedure UpdateToolBarState;
    procedure ShowBoxesInGrid;
    procedure DisableOtherButtons(ActiveButton: TToolButton);
    procedure EnableAllButtons;
    procedure MostraThreshold(pEstado: Boolean);
    procedure MostraRotate(pEstado: Boolean);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses FileCtrl, imageenio, StrUtils, Math, imageenproc, hyieutils;

var
  Proc: TImageEnProc;

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

  tbUndo.Caption := 'Desfazer';
  tbUndo.Hint := 'Desfazer alteração da imagem';
  tbUndo.ImageIndex := 1;
  tbUndo.ShowHint := True;

  tbRedo.Caption := 'Refazer';
  tbRedo.Hint := 'Refazer alteração na imagem';
  tbRedo.ImageIndex := 2;
  tbRedo.ShowHint := True;

  // tbGrayscale
  tbGrayscale.Caption := 'Cinza';
  tbGrayscale.Hint := 'Converter para escala de cinza';
  tbGrayscale.ImageIndex := 3;
  tbGrayscale.ShowHint := True;

  // tbBinary
  tbBinary.Caption := 'Binário';
  tbBinary.Hint := 'Converter para preto e branco';
  tbBinary.ImageIndex := 4;
  tbBinary.ShowHint := True;
  tbBinary.Style := tbsCheck;

  // tbRotate
  tbRotate.Caption := 'Rotação';
  tbRotate.Hint := 'Rotacionar imagem';
  tbRotate.ImageIndex := 5;
  tbRotate.ShowHint := True;
  tbRotate.Style := tbsCheck;

  // Separador 2
  tbSeparator2.Style := tbsSeparator;

  // tbSave
  tbSave.Caption := 'Salvar';
  tbSave.Hint := 'Salvar imagem processada (Ctrl+S)';
  tbSave.ImageIndex := 6;
  tbSave.ShowHint := True;
  tbSave.Enabled := False;

  // Separador 3
  tbSeparator3.Style := tbsSeparator;

  // tbWidthPlus
  tbWidthPlus.Caption := 'Largura +';
  tbWidthPlus.Hint := 'Aumentar largura (+)';
  tbWidthPlus.ImageIndex := 7;
  tbWidthPlus.ShowHint := True;

  // tbWidthMinus
  tbWidthMinus.Caption := 'Largura -';
  tbWidthMinus.Hint := 'Diminuir largura (-)';
  tbWidthMinus.ImageIndex := 8;
  tbWidthMinus.ShowHint := True;

  // tbHeightPlus
  tbHeightPlus.Caption := 'Altura +';
  tbHeightPlus.Hint := 'Aumentar altura (+)';
  tbHeightPlus.ImageIndex := 9;
  tbHeightPlus.ShowHint := True;

  // tbHeightMinus
  tbHeightMinus.Caption := 'Altura -';
  tbHeightMinus.Hint := 'Diminuir altura (-)';
  tbHeightMinus.ImageIndex := 10;
  tbHeightMinus.ShowHint := True;

  // Atualizar estado inicial
  UpdateToolBarState;
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
  Clicando := False;
  FBufferBitmap := TBitmap.Create;
  FOriginalBitmap := TBitmap.Create;
  FModifiedBmp := TBitmap.Create;

  StringGrid1.ColCount := 6;
  StringGrid1.Cells[0, 0] := 'Caractere';
  StringGrid1.Cells[1, 0] := 'Esquerda';
  StringGrid1.Cells[2, 0] := 'Topo';
  StringGrid1.Cells[3, 0] := 'Direita';
  StringGrid1.Cells[4, 0] := 'Fundo';
  StringGrid1.Cells[5, 0] := 'Página';

  SetupToolBar;

  MaxUndoSteps := 5;
  SetLength(FUndoList, 0);
  SetLength(FRedoList, 0);

  tbBinary.Down := False;
  tbRotate.Down := False;

  TrackBarThreshold.Visible := False;
  LabelThresholdValue.Visible := False;
  TrackBarRotate.Visible := False;
  LabelRotateValue.Visible := False;

  EnableAllButtons;

  // Configurar botões Undo e Redo
  tbUndo.Enabled := False;
  tbRedo.Enabled := False;
 
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
  if FModifiedBmp = nil then Exit;

  FBufferBitmap.Width := FModifiedBmp.Width;
  FBufferBitmap.Height := FModifiedBmp.Height;
//  FBufferBitmap.PixelFormat := FModifiedBmp.PixelFormat;

  // Copia a imagem original limpa para o buffer
  FBufferBitmap.Canvas.Draw(0, 0, FModifiedBmp);

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
  end else if (i <> -1) and (StringGrid1.Row <> i+1) then begin
    Clicando := True;
    StringGrid1.Row := i+1;
    Clicando := False;
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
  if tbUndo.Enabled then
    ShowMessage('Descartando alterações anteriores...');

  if ListBox1.ItemIndex < 0 then Exit;

  // Limpar estados Undo e Redo
  ClearUndoStates;  // Limpa e libera memória dos bitmaps da lista Undo
  ClearRedoStates;  // Limpa e libera memória dos bitmaps da lista Redo

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
    FModifiedBmp.Assign(FOriginalBitmap);

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

  // Salvar o estado inicial da imagem carregada no Undo
  PushUndoState;

  UpdateImageCanvas;
//  ShowBoxesInfo; // opcional: mostrar lista de caixas
  ShowBoxesInGrid;

  UpdateToolBarState;

  Processando := False;
end;

procedure TfrmMain.AtualizaTela;
begin
  FBufferBitmap.Width := FModifiedBmp.Width;
  FBufferBitmap.Height := FModifiedBmp.Height;

  // Copia a imagem original limpa para o buffer
  FBufferBitmap.Canvas.Draw(0, 0, FModifiedBmp);

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
begin
  if ListBox1.ItemIndex < 0 then exit;

  Proc := TImageEnProc.Create(nil);
  try
    // Carrega a imagem no ImageEnProc
    Proc.CreateFromBitmap(FModifiedBmp);

    // Converte para escala de cinza
    Proc.ConvertToGray;
  finally
    FreeAndNil(Proc);
  end;

  AtualizaTela;

  PushUndoState; // Salvar estado para Undo

  UpdateToolBarState;
end;

procedure TfrmMain.tbSaveClick(Sender: TObject);
var
  SelectedFile, FullPath: string;
  ImageEnIO: TImageEnIO;
begin
  if ListBox1.ItemIndex < 0 then exit;

  SelectedFile := copy(ListBox1.Items[ListBox1.ItemIndex],5,30);
  FullPath := FolderPath + SelectedFile;

  RenameFile(FullPath, ChangeFileExt(FullPath,'.bak'));

  ImageEnIO := TImageEnIO.Create(nil);
  try
    // Salva o bitmap modificado em TIFF
    ImageEnIO.CreateFromBitmap(FModifiedBmp);
    ImageEnIO.SaveToFile(FullPath);
  finally
    ImageEnIO.Free;
  end;

  FOriginalBitmap.Assign(FModifiedBmp);
  
  // Limpar estados Undo e Redo
  ClearUndoStates;  // Limpa e libera memória dos bitmaps da lista Undo
  ClearRedoStates;  // Limpa e libera memória dos bitmaps da lista Redo

  UpdateToolBarState;
end;

procedure TfrmMain.UpdateToolBarState;
begin
  tbUndo.Enabled := Length(FUndoList) > 1;
  tbRedo.Enabled := Length(FRedoList) > 0;

  tbSave.Enabled := tbUndo.Enabled;
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
  if Clicando then exit;
  
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

procedure TfrmMain.ClearRedoStates;
var
  i: Integer;
begin
  for i := 0 to High(FRedoList) do
    FRedoList[i].Free;
  SetLength(FRedoList, 0);
end;

procedure TfrmMain.PushUndoState;
var
  bmp: TBitmap;
begin
  // Limitar tamanho da lista Undo a MaxUndoSteps
  if Length(FUndoList) = MaxUndoSteps then
  begin
    // Remove o estado mais antigo (posição 0)
    FUndoList[0].Free;
    Move(FUndoList[1], FUndoList[0], (MaxUndoSteps - 1) * SizeOf(TBitmap));
    SetLength(FUndoList, MaxUndoSteps - 1);
  end;

  // Criar uma cópia do bitmap atual modificado
  bmp := TBitmap.Create;
  if Length(FUndoList) = 0 then
    bmp.Assign(FOriginalBitmap)
  else
    bmp.Assign(FModifiedBmp);

  // Adicionar ao final da lista Undo
  SetLength(FUndoList, Length(FUndoList) + 1);
  FUndoList[High(FUndoList)] := bmp;

  // Sempre que um novo estado é salvo, limpar a lista Redo
  ClearRedoStates;

  // Atualizar botões
  tbUndo.Enabled := Length(FUndoList) > 1;  // Pode desfazer se houver mais de 1 estado
  tbRedo.Enabled := False;
end;

procedure TfrmMain.Redo;
var
  bmp: TBitmap;
begin
  if Length(FRedoList) = 0 then Exit; // Nada para refazer

  // Recuperar o último estado do Redo para FModifiedBmp
  FModifiedBmp.Assign(FRedoList[High(FRedoList)]);

  // Mover o estado do Redo para Undo
  bmp := TBitmap.Create;
  bmp.Assign(FRedoList[High(FRedoList)]);
  SetLength(FUndoList, Length(FUndoList) + 1);
  FUndoList[High(FUndoList)] := bmp;

  // Remover o estado do Redo
  FRedoList[High(FRedoList)].Free;
  SetLength(FRedoList, Length(FRedoList) - 1);

  // Atualizar a tela
  AtualizaTela;

  // Atualizar botões
  tbUndo.Enabled := Length(FUndoList) > 1;
  tbRedo.Enabled := Length(FRedoList) > 0;
end;

procedure TfrmMain.Undo;
var
  bmp: TBitmap;
begin
  if Length(FUndoList) <= 1 then Exit; // Nada para desfazer

  // Mover o estado atual para Redo
  bmp := TBitmap.Create;
  bmp.Assign(FUndoList[High(FUndoList)]);
  SetLength(FRedoList, Length(FRedoList) + 1);
  FRedoList[High(FRedoList)] := bmp;

  // Remover o estado atual de Undo
  FUndoList[High(FUndoList)].Free;
  SetLength(FUndoList, Length(FUndoList) - 1);

  // Recuperar o último estado do Undo para FModifiedBmp
  FModifiedBmp.Assign(FUndoList[High(FUndoList)]);

  // Atualizar a tela com o estado recuperado
  AtualizaTela;

  // Atualizar botões
  tbUndo.Enabled := Length(FUndoList) > 1;
  tbRedo.Enabled := Length(FRedoList) > 0;
end;

procedure TfrmMain.tbUndoClick(Sender: TObject);
begin
  Undo;

  UpdateToolBarState;
end;

procedure TfrmMain.tbRedoClick(Sender: TObject);
begin
  Redo;

  UpdateToolBarState;
end;

procedure TfrmMain.ClearUndoStates;
var
  i: Integer;
begin
  for i := 0 to High(FUndoList) do
    FUndoList[i].Free;
  SetLength(FUndoList, 0);
end;

procedure TfrmMain.tbApplyClick(Sender: TObject);
//var
//  Proc: TImageEnProc;
begin
  FreeAndNil(Proc);

  AtualizaTela;

  PushUndoState; // Salvar estado para Undo

  // Após aplicar, desativa botões e oculta controles
  tbBinary.Down := False;
  tbRotate.Down := False;

  MostraThreshold(False);
  MostraRotate(False);

  EnableAllButtons;

  UpdateToolBarState;

end;

procedure TfrmMain.MostraThreshold(pEstado: Boolean);
begin
  // Ativa controle de threshold e botão aplicar
  TrackBarThreshold.Visible := pEstado;
  LabelThresholdValue.Visible := pEstado;
  tbApply.Visible := pEstado;
end;

procedure TfrmMain.tbBinaryClick(Sender: TObject);
begin
  if ListBox1.ItemIndex < 0 then exit;

  MostraThreshold(tbBinary.Down);
  if tbBinary.Down then
  begin
    Proc := TImageEnProc.Create(nil);

    // Carrega a imagem no ImageEnProc
    Proc.CreateFromBitmap(FModifiedBmp);
    Proc.SaveUndo;

    Processando := True;
    TrackBarThreshold.Position := 128;
    LabelThresholdValue.Caption := IntToStr(TrackBarThreshold.Position);
    Processando := False;

    TrackBarThresholdChange(Sender);

    // Desativa outros botões, exceto tbBinary e tbApply
    DisableOtherButtons(tbBinary);
  end
  else
  begin
    // Recarrega imagem para descartar alterações
    if Proc.CanUndo then
      Proc.Undo();

    FreeAndNil(Proc);

    AtualizaTela;

    // Reabilita todos os botões
    EnableAllButtons;

    UpdateToolBarState;
  end;
end;

procedure TfrmMain.MostraRotate(pEstado: Boolean);
begin
  // Ativa controle de rotação e botão aplicar
  TrackBarRotate.Visible := pEstado;
  LabelRotateValue.Visible := pEstado;
  tbApply.Visible := pEstado;
end;

procedure TfrmMain.tbRotateClick(Sender: TObject);
begin
  if ListBox1.ItemIndex < 0 then exit;

  MostraRotate(tbRotate.Down);
  if tbRotate.Down then
  begin
    Proc := TImageEnProc.Create(nil);

    // Carrega a imagem no ImageEnProc
    Proc.CreateFromBitmap(FModifiedBmp);
    Proc.SaveUndo;

    TrackBarRotate.Position := 0;
    LabelRotateValue.Caption := IntToStr(TrackBarRotate.Position);

    // Desativa outros botões, exceto tbRotate e tbApply
    DisableOtherButtons(tbRotate);
  end
  else
  begin
    // Recarrega imagem para descartar alterações
    if Proc.CanUndo then
      Proc.Undo();

    FreeAndNil(Proc);

    AtualizaTela;
      
    // Reabilita todos os botões
    EnableAllButtons;

    UpdateToolBarState;
  end;
end;

procedure TfrmMain.DisableOtherButtons(ActiveButton: TToolButton);
var
  i: Integer;
begin
  for i := 0 to ToolBar1.ButtonCount - 1 do
  begin
    if ToolBar1.Buttons[i] <> ActiveButton then
      ToolBar1.Buttons[i].Enabled := False;
  end;
  ActiveButton.Enabled := True;
  tbApply.Enabled := True;
  tbApply.Visible := True;

  StringGrid1.Enabled := False;
  btnSaveBox.Enabled := False;
  ListBox1.Enabled := False;
end;

procedure TfrmMain.EnableAllButtons;
var
  i: Integer;
begin
  for i := 0 to ToolBar1.ButtonCount - 1 do
    ToolBar1.Buttons[i].Enabled := True;
  tbApply.Visible := False;

  StringGrid1.Enabled := True;
  btnSaveBox.Enabled := True;
  ListBox1.Enabled := True;
end;

procedure TfrmMain.TrackBarThresholdChange(Sender: TObject);
begin
  if Processando then exit;

  Processando := True;

  LabelThresholdValue.Caption := IntToStr(TrackBarThreshold.Position);

  if Proc.CanUndo then
    Proc.Undo();

  // Converte para binário (preto e branco)
  Proc.ConvertToBWThreshold(TrackBarThreshold.Position);

  AtualizaTela;

  Processando := False;
end;

procedure TfrmMain.TrackBarRotateChange(Sender: TObject);
begin
  if Processando then exit;

  Processando := True;

  LabelRotateValue.Caption := IntToStr(TrackBarRotate.Position);

  if Proc.CanUndo then
    Proc.Undo();

  // Rotaciona com suavização bilinear
  Proc.Rotate(TrackBarRotate.Position, true, ierBilinear);

  AtualizaTela;

  Processando := False;
end;

end.

