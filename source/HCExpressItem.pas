{*******************************************************}
{                                                       }
{               HCView V1.0  ���ߣ���ͨ                 }
{                                                       }
{      ��������ѭBSDЭ�飬����Լ���QQȺ 649023932      }
{            ����ȡ����ļ������� 2018-5-4              }
{                                                       }
{        �ĵ�ExpressItem(�����๫ʽ)����ʵ�ֵ�Ԫ        }
{                                                       }
{*******************************************************}

unit HCExpressItem;

interface

uses
  Windows, Classes, Controls, Graphics, HCStyle, HCItem, HCRectItem, HCCustomData,
  HCCommon, HCFractionItem;

type
  THCExperssItem = class(THCFractionItem)  // ��ʽ(�ϡ��¡������ı�����������)
  private
    FLeftText, FRightText: string;
    FLeftRect, FRightRect: TRect;
  protected
    procedure FormatToDrawItem(const ARichData: THCCustomData; const AItemNo: Integer); override;
    procedure DoPaint(const AStyle: THCStyle; const ADrawRect: TRect;
      const ADataDrawTop, ADataDrawBottom, ADataScreenTop, ADataScreenBottom: Integer;
      const ACanvas: TCanvas; const APaintInfo: TPaintInfo); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function GetExpressArea(const X, Y: Integer): TExpressArea; override;
    function InsertText(const AText: string): Boolean; override;
    procedure GetCaretInfo(var ACaretInfo: TCaretInfo); override;
    procedure SaveToStream(const AStream: TStream; const AStart, AEnd: Integer); override;
    procedure LoadFromStream(const AStream: TStream; const AStyle: THCStyle;
      const AFileVersion: Word); override;
  public
    constructor Create(const AOwnerData: THCCustomData;
      const ALeftText, ATopText, ARightText, ABottomText: string); virtual;

    property LeftRect: TRect read FLeftRect;
    property RightRect: TRect read FRightRect;
    property LeftText: string read FLeftText write FLeftText;
    property RightText: string read FRightText write FRightText;

    property TopText;
    property BottomText;
    property TopRect;
    property BottomRect;
  end;

implementation

uses
  SysUtils, System.Math;

{ THCExperssItem }

constructor THCExperssItem.Create(const AOwnerData: THCCustomData;
  const ALeftText, ATopText, ARightText, ABottomText: string);
begin
  inherited Create(AOwnerData, ATopText, ABottomText);
  Self.StyleNo := THCStyle.Express;

  FLeftText := ALeftText;
  FRightText := ARightText;
end;

procedure THCExperssItem.DoPaint(const AStyle: THCStyle; const ADrawRect: TRect;
  const ADataDrawTop, ADataDrawBottom, ADataScreenTop, ADataScreenBottom: Integer;
  const ACanvas: TCanvas; const APaintInfo: TPaintInfo);
var
  vFocusRect: TRect;
begin
  if Self.Active and (not APaintInfo.Print) then
  begin
    ACanvas.Brush.Color := clBtnFace;
    ACanvas.FillRect(ADrawRect);
  end;

  AStyle.TextStyles[TextStyleNo].ApplyStyle(ACanvas, APaintInfo.ScaleY / APaintInfo.Zoom);
  ACanvas.TextOut(ADrawRect.Left + FLeftRect.Left, ADrawRect.Top + FLeftRect.Top, FLeftText);
  ACanvas.TextOut(ADrawRect.Left + TopRect.Left, ADrawRect.Top + TopRect.Top, TopText);
  ACanvas.TextOut(ADrawRect.Left + FRightRect.Left, ADrawRect.Top + FRightRect.Top, FRightText);
  ACanvas.TextOut(ADrawRect.Left + BottomRect.Left, ADrawRect.Top + BottomRect.Top, BottomText);

  ACanvas.Pen.Color := clBlack;
  ACanvas.MoveTo(ADrawRect.Left + FLeftRect.Right + Padding, ADrawRect.Top + TopRect.Bottom + Padding);
  ACanvas.LineTo(ADrawRect.Left + FRightRect.Left - Padding, ADrawRect.Top + TopRect.Bottom + Padding);

  if not APaintInfo.Print then
  begin
    if FActiveArea <> ceaNone then
    begin
      case FActiveArea of
        ceaLeft: vFocusRect := FLeftRect;
        ceaTop: vFocusRect := TopRect;
        ceaRight: vFocusRect := FRightRect;
        ceaBottom: vFocusRect := BottomRect;
      end;

      vFocusRect.Offset(ADrawRect.Location);
      vFocusRect.Inflate(2, 2);
      ACanvas.Pen.Color := clBlue;
      ACanvas.Rectangle(vFocusRect);
    end;

    if (FMouseMoveArea <> ceaNone) and (FMouseMoveArea <> FActiveArea) then
    begin
      case FMouseMoveArea of
        ceaLeft: vFocusRect := FLeftRect;
        ceaTop: vFocusRect := TopRect;
        ceaRight: vFocusRect := FRightRect;
        ceaBottom: vFocusRect := BottomRect;
      end;

      vFocusRect.Offset(ADrawRect.Location);
      vFocusRect.Inflate(2, 2);
      ACanvas.Pen.Color := clMedGray;
      ACanvas.Rectangle(vFocusRect);
    end;
  end;
end;

procedure THCExperssItem.FormatToDrawItem(const ARichData: THCCustomData;
  const AItemNo: Integer);
var
  vH, vLeftW, vRightW, vTopW, vBottomW: Integer;
  vStyle: THCStyle;
begin
  vStyle := ARichData.Style;
  vStyle.TextStyles[TextStyleNo].ApplyStyle(vStyle.DefCanvas);
  vH := vStyle.DefCanvas.TextHeight('H');
  vLeftW := Max(vStyle.DefCanvas.TextWidth(FLeftText), Padding);
  vTopW := Max(vStyle.DefCanvas.TextWidth(TopText), Padding);
  vRightW := Max(vStyle.DefCanvas.TextWidth(FRightText), Padding);
  vBottomW := Max(vStyle.DefCanvas.TextWidth(BottomText), Padding);
  // ����ߴ�
  if vTopW > vBottomW then  // ����������
    Width := vLeftW + vTopW + vRightW + 6 * Padding
  else
    Width := vLeftW + vBottomW + vRightW + 6 * Padding;

  Height := vH * 2 + 4 * Padding;

  // ������ַ���λ��
  FLeftRect := Bounds(Padding, (Height - vH) div 2, vLeftW, vH);
  FRightRect := Bounds(Width - Padding - vRightW, (Height - vH) div 2, vRightW, vH);
  TopRect := Bounds(FLeftRect.Right + Padding + (FRightRect.Left - Padding - (FLeftRect.Right + Padding) - vTopW) div 2,
    Padding, vTopW, vH);
  BottomRect := Bounds(FLeftRect.Right + Padding + (FRightRect.Left - Padding - (FLeftRect.Right + Padding) - vBottomW) div 2,
    Height - Padding - vH, vBottomW, vH);
end;

procedure THCExperssItem.GetCaretInfo(var ACaretInfo: TCaretInfo);
begin
  if FActiveArea <> TExpressArea.ceaNone then
  begin
    OwnerData.Style.TextStyles[TextStyleNo].ApplyStyle(OwnerData.Style.DefCanvas);
    case FActiveArea of
      ceaLeft:
        begin
          ACaretInfo.Height := FLeftRect.Bottom - FLeftRect.Top;
          ACaretInfo.X := FLeftRect.Left + OwnerData.Style.DefCanvas.TextWidth(Copy(FLeftText, 1, FCaretOffset));
          ACaretInfo.Y := FLeftRect.Top;
        end;

      ceaTop:
        begin
          ACaretInfo.Height := TopRect.Bottom - TopRect.Top;
          ACaretInfo.X := TopRect.Left + OwnerData.Style.DefCanvas.TextWidth(Copy(TopText, 1, FCaretOffset));
          ACaretInfo.Y := TopRect.Top;
        end;

      ceaRight:
        begin
          ACaretInfo.Height := FRightRect.Bottom - FRightRect.Top;
          ACaretInfo.X := FRightRect.Left + OwnerData.Style.DefCanvas.TextWidth(Copy(FRightText, 1, FCaretOffset));
          ACaretInfo.Y := FRightRect.Top;
        end;

      ceaBottom:
        begin
          ACaretInfo.Height := BottomRect.Bottom - BottomRect.Top;
          ACaretInfo.X := BottomRect.Left + OwnerData.Style.DefCanvas.TextWidth(Copy(BottomText, 1, FCaretOffset));
          ACaretInfo.Y := BottomRect.Top;
        end;
    end;
  end
  else
    ACaretInfo.Visible := False;
end;

function THCExperssItem.GetExpressArea(const X, Y: Integer): TExpressArea;
var
  vPt: TPoint;
begin
  Result := inherited GetExpressArea(X, Y);
  if Result = TExpressArea.ceaNone then
  begin
    vPt := Point(X, Y);
    if PtInRect(FLeftRect, vPt) then
      Result := TExpressArea.ceaLeft
    else
    if PtInRect(FRightRect, vPt) then
      Result := TExpressArea.ceaRight;
  end;
end;

function THCExperssItem.InsertText(const AText: string): Boolean;
begin
  if FActiveArea <> ceaNone then
  begin
    case FActiveArea of
      ceaLeft:
        begin
          System.Insert(AText, FLeftText, FCaretOffset + 1);
          Inc(FCaretOffset, System.Length(AText));
          Self.SizeChanged := True;
        end;

      ceaRight:
        begin
          System.Insert(AText, FRightText, FCaretOffset + 1);
          Inc(FCaretOffset, System.Length(AText));
          Self.SizeChanged := True;
        end;

    else
      Result := inherited InsertText(AText);
    end;
  end;
end;

procedure THCExperssItem.KeyDown(var Key: Word; Shift: TShiftState);

  procedure BackspaceKeyDown;

    procedure BackDeleteChar(var S: string);
    begin
      if FCaretOffset > 0 then
      begin
        System.Delete(S, FCaretOffset, 1);
        Dec(FCaretOffset);
      end;
    end;

  begin
    if FActiveArea = ceaLeft then
      BackDeleteChar(FLeftText)
    else
      BackDeleteChar(FRightText);

    Self.SizeChanged := True;
  end;

  procedure LeftKeyDown;
  begin
    if FCaretOffset > 0 then
      Dec(FCaretOffset);
  end;

  procedure RightKeyDown;
  var
    vS: string;
  begin
    if FActiveArea = ceaLeft then
      vS := FLeftText
    else
      vS := FRightText;

    if FCaretOffset < System.Length(vS) then
      Inc(FCaretOffset);
  end;

  procedure DeleteKeyDown;

    procedure DeleteChar(var S: string);
    begin
      if FCaretOffset < System.Length(S) then
        System.Delete(S, FCaretOffset + 1, 1);
    end;

  begin
    if FActiveArea = ceaLeft then
      DeleteChar(FLeftText)
    else
      DeleteChar(FRightText);

    Self.SizeChanged := True;
  end;

  procedure HomeKeyDown;
  begin
    FCaretOffset := 0;
  end;

  procedure EndKeyDown;
  var
    vS: string;
  begin
    if FActiveArea = ceaLeft then
      vS := FLeftText
    else
      vS := FRightText;

    FCaretOffset := System.Length(vS);
  end;

begin
  if FActiveArea in [ceaLeft, ceaRight] then
  begin
    case Key of
      VK_BACK: BackspaceKeyDown;  // ��ɾ
      VK_LEFT: LeftKeyDown;       // �����
      VK_RIGHT: RightKeyDown;     // �ҷ����
      VK_DELETE: DeleteKeyDown;   // ɾ����
      VK_HOME: HomeKeyDown;       // Home��
      VK_END: EndKeyDown;         // End��
    end;
  end
  else
    inherited KeyDown(Key, Shift);
end;

procedure THCExperssItem.LoadFromStream(const AStream: TStream;
  const AStyle: THCStyle; const AFileVersion: Word);

  procedure LoadPartText(var S: string);
  var
    vSize: Word;
    vBuffer: TBytes;
  begin
    AStream.ReadBuffer(vSize, SizeOf(vSize));
    if vSize > 0 then
    begin
      SetLength(vBuffer, vSize);
      AStream.Read(vBuffer[0], vSize);
      S := StringOf(vBuffer);
    end
    else
      S := '';
  end;

begin
  inherited LoadFromStream(AStream, AStyle, AFileVersion);
  LoadPartText(FLeftText);
  LoadPartText(FRightText);
end;

procedure THCExperssItem.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  vS: string;
  vX: Integer;
  vOffset: Integer;
begin
  inherited;
  FMouseLBDowning := (Button = mbLeft) and (Shift = [ssLeft]);
  FOutSelectInto := False;

  if FMouseMoveArea <> FActiveArea then
  begin
    FActiveArea := FMouseMoveArea;
    OwnerData.Style.UpdateInfoReCaret;
  end;

  case FActiveArea of
    //ceaNone: ;
    ceaLeft:
      begin
        vS := FLeftText;
        vX := X - FLeftRect.Left;
      end;

    ceaTop:
      begin
        vS := TopText;
        vX := X - TopRect.Left;
      end;

    ceaRight:
      begin
        vS := FRightText;
        vX := X - FRightRect.Left;
      end;

    ceaBottom:
      begin
        vS := BottomText;
        vX := X - BottomRect.Left;
      end;
  end;

  if FActiveArea <> TExpressArea.ceaNone then
  begin
    OwnerData.Style.TextStyles[TextStyleNo].ApplyStyle(OwnerData.Style.DefCanvas);
    vOffset := GetCharOffsetByX(OwnerData.Style.DefCanvas, vS, vX)
  end
  else
    vOffset := -1;

  if vOffset <> FCaretOffset then
  begin
    FCaretOffset := vOffset;
    OwnerData.Style.UpdateInfoReCaret;
  end;
end;

procedure THCExperssItem.SaveToStream(const AStream: TStream; const AStart, AEnd: Integer);

  procedure SavePartText(const S: string);
  var
    vBuffer: TBytes;
    vSize: Word;
  begin
    vBuffer := BytesOf(S);
    if System.Length(vBuffer) > MAXWORD then
      raise Exception.Create(HCS_EXCEPTION_TEXTOVER);
    vSize := System.Length(vBuffer);
    AStream.WriteBuffer(vSize, SizeOf(vSize));
    if vSize > 0 then
      AStream.WriteBuffer(vBuffer[0], vSize);
  end;

begin
  inherited SaveToStream(AStream, AStart, AEnd);
  SavePartText(FLeftText);
  SavePartText(FRightText);
end;

end.