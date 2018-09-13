{*******************************************************}
{                                                       }
{               HCView V1.0  ���ߣ���ͨ                 }
{                                                       }
{      ��������ѭBSDЭ�飬����Լ���QQȺ 649023932      }
{            ����ȡ����ļ������� 2018-5-4              }
{                                                       }
{                 �ı�������ʽʵ�ֵ�Ԫ                  }
{                                                       }
{*******************************************************}

unit HCTextStyle;

interface

uses
  Windows, Classes, Graphics, SysUtils;

type
  TFontStyleEx = (tsBold, tsItalic, tsUnderline, tsStrikeOut, tsSuperscript,
    tsSubscript);

  TFontStyleExs = set of TFontStyleEx;

  THCTextStyle = class(TPersistent)
  private const
    DefaultFontSize: Single = 10.5;  // ���
    DefaultFontFamily = '����';
    MaxFontSize: Single = 512;
  strict private
    FSize: Single;
    FFamily: TFontName;
    FFontStyle: TFontStyleExs;
    FColor: TColor;  // ������ɫ
    FBackColor: TColor;
  protected
    procedure SetFamily(const Value: TFontName);
    procedure SetSize(const Value: Single);
    procedure SetFontStyle(const Value: TFontStyleExs);
  public
    CheckSaveUsed: Boolean;
    TempNo: Integer;
    constructor Create;
    destructor Destroy; override;
    function IsSizeStored: Boolean;
    function IsFamilyStored: Boolean;
    procedure ApplyStyle(const ACanvas: TCanvas; const AScale: Single = 1);
    function EqualsEx(const ASource: THCTextStyle): Boolean;
    procedure AssignEx(const ASource: THCTextStyle);
    procedure SaveToStream(const AStream: TStream);
    procedure LoadFromStream(const AStream: TStream; const AFileVersion: Word);
  published
    property Family: TFontName read FFamily write SetFamily stored IsFamilyStored;
    property Size: Single read FSize write SetSize stored IsSizeStored nodefault;
    property FontStyle: TFontStyleExs read FFontStyle write SetFontStyle default [];
    property Color: TColor read FColor write FColor default clBlack;
    property BackColor: TColor read FBackColor write FBackColor default clWhite;
  end;

implementation

{ THCTextStyle }

procedure THCTextStyle.ApplyStyle(const ACanvas: TCanvas; const AScale: Single = 1);
var
  vFont: TFont;
  vLogFont: TLogFont;
begin
  with ACanvas do
  begin
    if FBackColor = clNone then
      Brush.Style := bsClear
    else
    begin
      Brush.Style := bsSolid;
      Brush.Color := FBackColor;
    end;
    Font.Color := FColor;
    Font.Name := FFamily;
    Font.Size := Round(FSize);
    if tsBold in FFontStyle then
      Font.Style := Font.Style + [TFontStyle.fsBold]
    else
      Font.Style := Font.Style - [TFontStyle.fsBold];

    if tsItalic in FFontStyle then
      Font.Style := Font.Style + [TFontStyle.fsItalic]
    else
      Font.Style := Font.Style - [TFontStyle.fsItalic];

    if tsUnderline in FFontStyle then
      Font.Style := Font.Style + [TFontStyle.fsUnderline]
    else
      Font.Style := Font.Style - [TFontStyle.fsUnderline];

    if tsStrikeOut in FFontStyle then
      Font.Style := Font.Style + [TFontStyle.fsStrikeOut]
    else
      Font.Style := Font.Style - [TFontStyle.fsStrikeOut];

    //if AScale <> 1 then
    begin
      vFont := TFont.Create;
      try
        vFont.Assign(ACanvas.Font);
        GetObject(vFont.Handle, SizeOf(vLogFont), @vLogFont);

        if (tsSuperscript in FFontStyle) or (tsSubscript in FFontStyle) then
          vLogFont.lfHeight := -Round(FSize / 2 * GetDeviceCaps(ACanvas.Handle, LOGPIXELSY) / 72 / AScale)
        else
          vLogFont.lfHeight := -Round(FSize * GetDeviceCaps(ACanvas.Handle, LOGPIXELSY) / 72 / AScale);

        vFont.Handle := CreateFontIndirect(vLogFont);
        ACanvas.Font.Assign(vFont);
      finally
        vFont.Free;
      end;
    end;
  end;
end;

procedure THCTextStyle.AssignEx(const ASource: THCTextStyle);
begin
  Self.FSize := ASource.Size;
  Self.FFontStyle := ASource.FontStyle;
  Self.FFamily := ASource.Family;
  Self.FColor := ASource.Color;
  Self.FBackColor := ASource.BackColor;
end;

constructor THCTextStyle.Create;
begin
  FSize := DefaultFontSize;
  FFamily := DefaultFontFamily;
  FFontStyle := [];
  FColor := clBlack;
  FBackColor := clNone;
end;

destructor THCTextStyle.Destroy;
begin

  inherited;
end;

function THCTextStyle.EqualsEx(const ASource: THCTextStyle): Boolean;
begin
  Result :=
    (Self.FSize = ASource.Size)
    and (Self.FFontStyle = ASource.FontStyle)
    and (Self.FFamily = ASource.Family)
    and (Self.FColor = ASource.Color)
    and (Self.FBackColor = ASource.BackColor);
end;

function THCTextStyle.IsFamilyStored: Boolean;
begin
  Result := FFamily <> DefaultFontFamily;
end;

function THCTextStyle.IsSizeStored: Boolean;
begin
  Result := FSize = DefaultFontSize;
end;

procedure THCTextStyle.LoadFromStream(const AStream: TStream; const AFileVersion: Word);
var
  vOldSize: Integer;
  vSize: Word;
  vBuffer: TBytes;
begin
  if AFileVersion < 12 then
  begin
    AStream.ReadBuffer(vOldSize, SizeOf(vOldSize));  // �ֺ�
    FSize := vOldSize;
  end
  else
    AStream.ReadBuffer(FSize, SizeOf(FSize));  // �ֺ�

  // ����
  AStream.ReadBuffer(vSize, SizeOf(vSize));
  if vSize > 0 then
  begin
    SetLength(vBuffer, vSize);
    AStream.Read(vBuffer[0], vSize);
    FFamily := StringOf(vBuffer);
  end;

  AStream.ReadBuffer(FFontStyle, SizeOf(FFontStyle));
  AStream.ReadBuffer(FColor, SizeOf(FColor));
  AStream.ReadBuffer(FBackColor, SizeOf(FBackColor));
end;

procedure THCTextStyle.SaveToStream(const AStream: TStream);
var
  vBuffer: TBytes;
  vSize: Word;
begin
  AStream.WriteBuffer(FSize, SizeOf(FSize));

  vBuffer := BytesOf(FFamily);
  vSize := System.Length(vBuffer);
  AStream.WriteBuffer(vSize, SizeOf(vSize));
  if vSize > 0 then
    AStream.WriteBuffer(vBuffer[0], vSize);

  AStream.WriteBuffer(FFontStyle, SizeOf(FFontStyle));
  AStream.WriteBuffer(FColor, SizeOf(FColor));
  AStream.WriteBuffer(FBackColor, SizeOf(FBackColor));
end;

procedure THCTextStyle.SetFamily(const Value: TFontName);
begin
  if FFamily <> Value then
    FFamily := Value;
end;

procedure THCTextStyle.SetSize(const Value: Single);
begin
  if FSize <> Value then
    FSize := Value;
end;

procedure THCTextStyle.SetFontStyle(const Value: TFontStyleExs);
begin
  if FFontStyle <> Value then
    FFontStyle := Value;
end;

end.