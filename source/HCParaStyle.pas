{*******************************************************}
{                                                       }
{               HCView V1.1  作者：荆通                 }
{                                                       }
{      本代码遵循BSD协议，你可以加入QQ群 649023932      }
{            来获取更多的技术交流 2018-5-4              }
{                                                       }
{                  文本段样式实现单元                   }
{                                                       }
{*******************************************************}

unit HCParaStyle;

interface

uses
  Classes, Graphics, HCXml;

type
  /// <summary> 段水平对齐方式：左、右、居中、两端、分散) </summary>
  TParaAlignHorz = (pahLeft, pahRight, pahCenter, pahJustify, pahScatter);

  /// <summary> 段垂直对齐方式：上、居中、下) </summary>
  TParaAlignVert = (pavTop, pavCenter, pavBottom);

  /// <summary> 首行缩进方式 </summary>
  TParaFirstLineIndent = (pfiNone, pfiIndented, pfiHanging);

  TParaLineSpaceMode = (pls100, pls115, pls150, pls200, plsFix);

  THCParaStyle = class(TPersistent)
  strict private
    FLineSpaceMode: TParaLineSpaceMode;

    FFirstIndentPix, // 首行缩进
    FLeftIndentPix,  // 左缩进
    FRightIndentPix  // 右缩进
      : Integer;     // 单位像素

    FFirstIndent,    // 首行缩进
    FLeftIndent,     // 左缩进
    FRightIndent     // 右缩进
      : Single;     // 单位毫米

    FBackColor: TColor;
    FAlignHorz: TParaAlignHorz;
    FAlignVert: TParaAlignVert;
  protected
    procedure SetFirstIndent(const Value: Single);
    procedure SetLeftIndent(const Value: Single);
    procedure SetRightIndent(const Value: Single);
  public
    CheckSaveUsed: Boolean;
    TempNo: Integer;
    constructor Create;
    function EqualsEx(const ASource: THCParaStyle): Boolean;
    procedure AssignEx(const ASource: THCParaStyle);
    procedure SaveToStream(const AStream: TStream);
    procedure LoadFromStream(const AStream: TStream; const AFileVersion: Word);
    function ToCSS: string;
    procedure ToXml(const ANode: IHCXmlNode);
    procedure ParseXml(const ANode: IHCXmlNode);
  published
    property LineSpaceMode: TParaLineSpaceMode read FLineSpaceMode write FLineSpaceMode;
    /// <summary> 首行缩进(毫米) </summary>
    property FirstIndent: Single read FFirstIndent write SetFirstIndent;
    /// <summary> 左缩进(毫米) </summary>
    property LeftIndent: Single read FLeftIndent write SetLeftIndent;
    /// <summary> 右缩进(毫米) </summary>
    property RightIndent: Single read FRightIndent write SetRightIndent;
    /// <summary> 首行缩进(像素) </summary>
    property FirstIndentPix: Integer read FFirstIndentPix;
    /// <summary> 左缩进(像素) </summary>
    property LeftIndentPix: Integer read FLeftIndentPix;
    /// <summary> 右缩进(像素) </summary>
    property RightIndentPix: Integer read FRightIndentPix;
    property BackColor: TColor read FBackColor write FBackColor;
    property AlignHorz: TParaAlignHorz read FAlignHorz write FAlignHorz;
    property AlignVert: TParaAlignVert read FAlignVert write FAlignVert;
  end;

implementation

uses
  SysUtils, HCCommon, HCUnitConversion;

{ THCParaStyle }

procedure THCParaStyle.AssignEx(const ASource: THCParaStyle);
begin
  FLineSpaceMode := ASource.LineSpaceMode;
  FirstIndent := ASource.FirstIndent;
  LeftIndent := ASource.LeftIndent;
  RightIndent := ASource.RightIndent;
  FBackColor := ASource.BackColor;
  FAlignHorz := ASource.AlignHorz;
  FAlignVert := ASource.AlignVert;
end;

constructor THCParaStyle.Create;
begin
  FirstIndent := 0;
  LeftIndent := 0;
  RightIndent := 0;
  FLineSpaceMode := TParaLineSpaceMode.pls100;
  FBackColor := clSilver;
  FAlignHorz := TParaAlignHorz.pahJustify;
  FAlignVert := TParaAlignVert.pavCenter;
end;

function THCParaStyle.EqualsEx(const ASource: THCParaStyle): Boolean;
begin
  Result :=
  //(Self.FLineSpace = ASource.LineSpace)
  (FLineSpaceMode = ASource.LineSpaceMode)
  and (FFirstIndent = ASource.FirstIndent)
  and (FLeftIndent = ASource.LeftIndent)
  and (FRightIndent = ASource.RightIndent)
  and (FBackColor = ASource.BackColor)
  and (FAlignHorz = ASource.AlignHorz)
  and (FAlignVert = ASource.AlignVert);
end;

procedure THCParaStyle.LoadFromStream(const AStream: TStream; const AFileVersion: Word);
var
  vLineSpace: Integer;
begin
  if AFileVersion < 15 then
    AStream.ReadBuffer(vLineSpace, SizeOf(vLineSpace));

  if AFileVersion > 16 then
    AStream.ReadBuffer(FLineSpaceMode, SizeOf(FLineSpaceMode));

  if AFileVersion < 22 then
  begin
    AStream.ReadBuffer(FFirstIndentPix, SizeOf(FFirstIndentPix));  // 首行缩进
    AStream.ReadBuffer(FLeftIndentPix, SizeOf(FLeftIndentPix));    // 左缩进
  end
  else
  begin
    AStream.ReadBuffer(FFirstIndent, SizeOf(FFirstIndent));  // 首行缩进
    FFirstIndentPix := MillimeterToPixX(FFirstIndent);
    AStream.ReadBuffer(FLeftIndent, SizeOf(FLeftIndent));    // 左缩进
    FLeftIndentPix := MillimeterToPixX(FLeftIndent);
    AStream.ReadBuffer(FRightIndent, SizeOf(FRightIndent));  // 右缩进
    FRightIndentPix := MillimeterToPixX(FRightIndent);
  end;

  if AFileVersion > 18 then
    HCLoadColorFromStream(AStream, FBackColor)
  else
    AStream.ReadBuffer(FBackColor, SizeOf(FBackColor));

  AStream.ReadBuffer(FAlignHorz, SizeOf(FAlignHorz));

  if AFileVersion > 17 then
    AStream.ReadBuffer(FAlignVert, SizeOf(FAlignVert));
end;

procedure THCParaStyle.ParseXml(const ANode: IHCXmlNode);

  procedure GetXMLLineSpaceMode_;
  begin
    if ANode.Attributes['spacemode'] = '100' then
      FLineSpaceMode := pls100
    else
    if ANode.Attributes['spacemode'] = '115' then
      FLineSpaceMode := pls115
    else
    if ANode.Attributes['spacemode'] = '150' then
      FLineSpaceMode := pls150
    else
    if ANode.Attributes['spacemode'] = '200' then
      FLineSpaceMode := pls200
    else
    if ANode.Attributes['spacemode'] = 'fix' then
      FLineSpaceMode := plsFix;
  end;

  procedure GetXMLHorz_;
  begin
    if ANode.Attributes['horz'] = 'left' then
      FAlignHorz := pahLeft
    else
    if ANode.Attributes['horz'] = 'right' then
      FAlignHorz := pahRight
    else
    if ANode.Attributes['horz'] = 'center' then
      FAlignHorz := pahCenter
    else
    if ANode.Attributes['horz'] = 'justify' then
      FAlignHorz := pahJustify
    else
    if ANode.Attributes['horz'] = 'scatter' then
      FAlignHorz := pahScatter;
  end;

  procedure GetXMLVert_;
  begin
    if ANode.Attributes['vert'] = 'top' then
      FAlignVert := pavTop
    else
    if ANode.Attributes['vert'] = 'center' then
      FAlignVert := pavCenter
    else
    if ANode.Attributes['vert'] = 'bottom' then
      FAlignVert := pavBottom;
  end;

begin
  FirstIndent := ANode.Attributes['firstindent'];
  LeftIndent := ANode.Attributes['leftindent'];
  RightIndent := ANode.Attributes['rightindent'];
  FBackColor := GetXmlRGBColor(ANode.Attributes['bkcolor']);
  GetXMLLineSpaceMode_;
  GetXMLHorz_;
  GetXMLVert_;
end;

procedure THCParaStyle.SaveToStream(const AStream: TStream);
begin
  AStream.WriteBuffer(FLineSpaceMode, SizeOf(FLineSpaceMode));
  AStream.WriteBuffer(FFirstIndent, SizeOf(FFirstIndent));  // 首行缩进
  AStream.WriteBuffer(FLeftIndent, SizeOf(FLeftIndent));  // 左缩进
  AStream.WriteBuffer(FRightIndent, SizeOf(FRightIndent));  // 右缩进
  HCSaveColorToStream(AStream, FBackColor);
  AStream.WriteBuffer(FAlignHorz, SizeOf(FAlignHorz));
  AStream.WriteBuffer(FAlignVert, SizeOf(FAlignVert));
end;

procedure THCParaStyle.SetFirstIndent(const Value: Single);
begin
  if FFirstIndent <> Value then
  begin
    FFirstIndent := Value;
    FFirstIndentPix := MillimeterToPixX(FFirstIndent);
  end;
end;

procedure THCParaStyle.SetLeftIndent(const Value: Single);
begin
  if FLeftIndent <> Value then
  begin
    FLeftIndent := Value;
    FLeftIndentPix := MillimeterToPixX(FLeftIndent);
  end;
end;

procedure THCParaStyle.SetRightIndent(const Value: Single);
begin
  if FRightIndent <> Value then
  begin
    FRightIndent := Value;
    FRightIndentPix := MillimeterToPixX(FRightIndent);
  end;
end;

function THCParaStyle.ToCSS: string;
begin
  Result := ' text-align: ';
  case FAlignHorz of
    pahLeft: Result := Result + 'left';
    pahRight: Result := Result + 'right';
    pahCenter: Result := Result + 'center';
    pahJustify, pahScatter: Result := Result + 'justify';
  end;

  case FLineSpaceMode of
    pls100: Result := Result + '; line-height: 100%';
    pls115: Result := Result + '; line-height: 115%';
    pls150: Result := Result + '; line-height: 150%';
    pls200: Result := Result + '; line-height: 200%';
    plsFix: Result := Result + '; line-height: 10px';
  end;
end;

procedure THCParaStyle.ToXml(const ANode: IHCXmlNode);

  function GetLineSpaceModeXML_: string;
  begin
    case FLineSpaceMode of
      pls100: Result := '100';
      pls115: Result := '115';
      pls150: Result := '150';
      pls200: Result := '200';
      plsFix: Result := 'fix';
    end;
  end;

  function GetHorzXML_: string;
  begin
    case FAlignHorz of
      pahLeft: Result := 'left';
      pahRight: Result := 'right';
      pahCenter: Result := 'center';
      pahJustify: Result := 'justify';
      pahScatter: Result := 'scatter';
    end;
  end;

  function GetVertXML_: string;
  begin
    case FAlignVert of
      pavTop: Result := 'top';
      pavCenter: Result := 'center';
      pavBottom: Result := 'bottom';
    end;
  end;

begin
  ANode.Attributes['firstindent'] := FFirstIndent;
  ANode.Attributes['leftindent'] := FLeftIndent;
  ANode.Attributes['rightindent'] := FRightIndent;
  ANode.Attributes['bkcolor'] := GetColorXmlRGB(FBackColor);
  ANode.Attributes['spacemode'] := GetLineSpaceModeXML_;
  ANode.Attributes['horz'] := GetHorzXML_;
  ANode.Attributes['vert'] := GetVertXML_;
end;

end.
