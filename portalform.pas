unit PortalForm;


{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,shlobj,base64;
const
     cae='ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz0123456789!#$%&()[<=?@]^_|0123456789!#$%&()[<=?@]^_|' ;
     flag='CH';
     Private_key=69;
type

  { TForm2 }

  TForm2 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    ListBox1: TListBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure SavePortal;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form2: TForm2;
  AppDataPath: Array[0..MaxPathLen] of Char;
  temp:Tstringlist;
implementation

{$R *.lfm}

function ranEncode(x:String):ansistring;//Own algorithm to encrypt data
Var
   temp:ansistring;
   i,j:longint;
   k:byte;
begin

     temp:='';
     x:=encodeStringBase64(x);
     for i:=length(x) downto 1 do
         temp:=temp+x[i];
     for i:=1 to Private_key do
         begin
              temp:=flag+temp;
              k:=random(25)+1;
              for j:=1 to length(temp) do
                  begin
                       temp[j]:=cae[pos(temp[j],cae)+k];
                  end;
         end;
     x:='';
     for i:=length(temp) downto 1 do
         x:=x+temp[i];
     temp:='';
     ranencode:=x;
end;

function ranDecode(x:String):ansistring;//Own algorithm to decrypt data
var
   st,temp:ansistring;
   i,j:longint;
   k:byte;
begin
     temp:='';
     for i:=length(x) downto 1 do
         temp:=temp+x[i];
     x:=temp;
     temp:='';
     for i:=1 to Private_key do
         begin
         for k:=1 to 25 do
                       begin
                            temp:=x;
                            for j:=1 to length(temp) do
                            temp[j]:=cae[pos(temp[j],cae)+k];
                            st:=copy(temp,1,length(FLAG));
                            if st=FLAG then begin x:=copy(temp,length(FLAG)+1,length(temp)-length(FLAG));break; end;
                       end;
         end;
     temp:='';
     for i:=length(x) downto 1 do
         temp:=temp+x[i];
     randecode:=decodeStringBase64(temp);
end;

procedure getAppDatapath;
begin
     AppDataPath:='';
     SHGetSpecialFolderPath(0,AppDataPath,CSIDL_LOCAL_APPDATA,false);
end;

{ TForm2 }
procedure TForm2.SavePortal;
var
   i:integer;
begin
    temp:=TStringlist.create;

    for i:=0 to ListBox1.items.Count-1 do
      begin
          temp.Add(RanEncode((ListBox1.items.Strings[i])));
      end;
    temp.savetofile(AppDataPath+'\fptudomlogger\.portal');
    temp.free;
    if FileExists(AppDataPath+'\fptudomlogger\.portal') then
       ListBox1.items.loadfromfile(AppDataPath+'\fptudomlogger\.portal');
  for i:=0 to ListBox1.items.Count-1 do
      begin
          ListBox1.items.Strings[i]:=ranDecode(ListBox1.items.Strings[i]);
      end;
end;

procedure TForm2.FormCreate(Sender: TObject);
var
   i:integer;
begin
  //Load the portal list
  getAppDatapath;

  if FileExists(AppDataPath+'\fptudomlogger\.portal') then
       ListBox1.items.loadfromfile(AppDataPath+'\fptudomlogger\.portal');
  for i:=0 to ListBox1.items.Count-1 do
      begin
          ListBox1.items.Strings[i]:=ranDecode(ListBox1.items.Strings[i]);
      end;
end;

procedure TForm2.FormResize(Sender: TObject);
begin
//prevent resize the window
  Form2.height:=410;
  Form2.width:=402;
end;

procedure TForm2.Button1Click(Sender: TObject);//add portal
begin
if edit1.text<> '' then
     listbox1.items.Add(Edit1.text);
  Form2.SavePortal();
end;

procedure TForm2.Button2Click(Sender: TObject);//delete selected portal
var
  i: Integer;
begin
  if ListBox1.SelCount > 0 then
    for i:=ListBox1.Items.Count - 1 downto 0 do
      if ListBox1.Selected[i] then
        ListBox1.Items.Delete(i);
  Form2.saveportal;
end;

end.

