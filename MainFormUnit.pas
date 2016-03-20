{******************************************************************************}
{                                                                              }
{ ObjectMgr sample program to demonstrate the object namespace                 }
{                                                                              }
{ MainFormUnit.pas    - Unit for the main form comprised of the list of object }
{                       names and object directories as well as the pipes and  }
{                       mailslots.                                             }
{                                                                              }
{ Copyright (C) 2005 Marcel van Brakel (brakelm)                               }
{ Copyright (C) 2005 Oliver Schneider (assarbad)                               }
{                                                                              }
{ The contents of this file are used with permission, subject to the Mozilla   }
{ Public License Version 1.1 (the "License"); you may not use this file except }
{ in compliance with the License. You may obtain a copy of the License at      }
{ http://www.mozilla.org/MPL/MPL-1.1.html                                      }
{                                                                              }
{ Software distributed under the License is distributed on an "AS IS" basis,   }
{ WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for }
{ the specific language governing rights and limitations under the License.    }
{                                                                              }
{ Alternatively, the contents of this file may be used under the terms of the  }
{ GNU Lesser General Public License (the  "LGPL License"), in which case the   }
{ provisions of the LGPL License are applicable instead of those above.        }
{ If you wish to allow use of your version of this file only under the terms   }
{ of the LGPL License and not to allow others to use your version of this file }
{ under the MPL, indicate your decision by deleting  the provisions above and  }
{ replace them with the notice and other provisions required by the LGPL       }
{ License. If you do not delete the provisions above, a recipient may use      }
{ your version of this file under either the MPL or the LGPL License.          }
{                                                                              }
{ For more information about the LGPL: http://www.gnu.org/copyleft/lesser.html }
{                                                                              }
{******************************************************************************}

unit MainFormUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, ExtCtrls, Menus, ObjectMgrHelper, ImgList, StdCtrls,
  JwaNative, JwaWinType, JwaWinNT, JwaNtStatus, UnicodeString, AboutUnit;


type
  ObjectSortType = (
    DefaultSort,
    SortbyName,
    SortbyType
    );

  TMainForm = class(TForm)
    StatusBar1: TStatusBar;
    MainMenu: TMainMenu;
    MainMenuFile: TMenuItem;
    MainMenuHelp: TMenuItem;
    MainMenuFileExit: TMenuItem;
    MainMenuHelpAbout: TMenuItem;
    TreeViewImgList: TImageList;
    PageControl1: TPageControl;
    TSObjectNamespace: TTabSheet;
    TSMailslotsPipes: TTabSheet;
    DirectoryList: TTreeView;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Panel1: TPanel;
    LVMailslots: TListView;
    LVPipes: TListView;
    StaticText1: TStaticText;
    Panel2: TPanel;
    StaticText2: TStaticText;
    ObjectList: TListView;
    procedure FormCreate(Sender: TObject);
    procedure DirectoryListChange(Sender: TObject; Node: TTreeNode);
    procedure MainMenuFileExitClick(Sender: TObject);
    procedure DirectoryListKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ObjectListCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure ObjectListDblClick(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure LVMailslotsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MainMenuHelpAboutClick(Sender: TObject);
    procedure PageControl1Changing(Sender: TObject; var AllowChange: Boolean);
    procedure FormDestroy(Sender: TObject);
  private
    FObjectList: TObjMgrListItem;
    FPipes: TMailslotAndPipeCollection;
    FMailslots: TMailslotAndPipeCollection;
    procedure FillTreeViewRescursively(Node: TTreeNode; CurrentItem: TObjMgrListItem);
    procedure FillTreeView;
    procedure FillListViewFromNode(Node: TTreeNode);
    procedure FillMailslotsAndPipesList;
    function GetImageIdx(TypeName: string): Integer;
    function FindTreeNode(Path: string): TTreeNode;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.DFM}

resourcestring
  RsDirectorySelected = 'Object directory "%s" selected from tree';
  RsDirectoryChanges = 'Changed into directory "%s"';
  RsSymLinkFollowed = 'Followed symlink "%s" to directory "%s"';
  RsNoTargetInNamespace = 'No such target "%s" in object namespace';

procedure TMainForm.FillTreeViewRescursively(Node: TTreeNode; CurrentItem: TObjMgrListItem);
var
  I: Integer;
  NextItem: TObjMgrListItem;
  NextNode: TTreeNode;
begin
  // the object item is associated with the treenode through the Data property
  Node.Data := CurrentItem;
  // set image for this node
  if CurrentItem.IsNamespaceRoot then
  begin
    Node.ImageIndex := 11;
    Node.SelectedIndex := 11;
  end
  else
  begin
    Node.ImageIndex := 0;
    Node.SelectedIndex := 1;
  end;
  // enumerate child items
  if CurrentItem.IsObjectDirectory then
  begin
    for I := 0 to CurrentItem.ItemList.Count - 1 do
    begin
      NextItem := TObjMgrListItem(CurrentItem.ItemList[I]);
      if NextItem.IsObjectDirectory then
      begin
        NextNode := DirectoryList.Items.AddChild(Node, NextItem.ObjectName);
        FillTreeViewRescursively(NextNode, NextItem);
      end;
    end;
  end;
end;

procedure TMainForm.FillTreeView;
var
  RootNode: TTreeNode;
begin
  DirectoryList.Items.BeginUpdate;
  try
    DirectoryList.Items.Clear;
    RootNode := DirectoryList.Items.Add(nil, '\');
    FillTreeViewRescursively(RootNode, FObjectList);
    RootNode.Expand(False);
    RootNode.Selected := True;
  finally
    DirectoryList.Items.EndUpdate;
  end;
end;

procedure TMainForm.FillListViewFromNode(Node: TTreeNode);
var
  CurrentItem, NextItem: TObjMgrListItem;
  ListItem: TListItem;
  I: Integer;
begin
  if Assigned(Node.Data) then
  begin
    ObjectList.Items.BeginUpdate;
    try
      ObjectList.Items.Clear;
      CurrentItem := TObjMgrListItem(Node.Data);
      if CurrentItem.IsObjectDirectory then
      begin
        for I := 0 to CurrentItem.ItemList.Count - 1 do
        begin
          if Assigned(CurrentItem.ItemList[I]) then
          begin
            NextItem := TObjMgrListItem(CurrentItem.ItemList[I]);
            if Assigned(NextItem) then
            begin
              ListItem := ObjectList.Items.Add;
              ListItem.Data := NextItem;
              ListItem.Caption := NextItem.ObjectName;
              ListItem.ImageIndex := GetImageIdx(NextItem.ObjectTypeName);
              ListItem.SubItems.Append(NextItem.ObjectTypeName);
              ListItem.SubItems.Append(NextItem.LinkTarget);
            end;
          end;
        end;
      end;
    finally
      ObjectList.Items.EndUpdate;
    end;
  end;
end;

procedure TMainForm.DirectoryListChange(Sender: TObject; Node: TTreeNode);
var
  S: string;
  N: TTreeNode;
begin
  FillListViewFromNode(Node);
  N := Node.Parent;
  S := Node.Text;
  while Assigned(N) do
  begin
    if (N.Text <> '\') then
      S := N.Text + '\' + S
    else
      S := N.Text + S;
    N := N.Parent;
  end;
  StatusBar1.Panels[0].Text := Format(RsDirectorySelected, [S]);
end;

procedure TMainForm.DirectoryListKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F5 then
  begin
    FObjectList.RefreshList;
    FillTreeView;
  end;
end;

procedure TMainForm.LVMailslotsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F5 then
  begin
    FPipes.RefreshList;
    FMailslots.RefreshList;
    FillMailslotsAndPipesList;
  end;
end;

procedure TMainForm.FillMailslotsAndPipesList;
var
  I, J: Integer;
  ListItem: TListItem;
  ListView: TListView;
  Collection: TMailslotAndPipeCollection;
begin
  for J := 0 to 1 do
  begin
    if J = 0 then
    begin
      ListView := LVPipes;
      Collection := FPipes;
    end
    else
    begin
      ListView := LVMailslots;
      Collection := FMailslots;
    end;
    Collection.ItemList.Pack;
    ListView.Items.BeginUpdate;
    try
      ListView.Items.Clear;
      for I := 0 to Collection.ItemList.Count - 1 do
      begin
        ListItem := ListView.Items.Add;
        ListItem.Caption := PMailslotAndPipeItem(Collection.ItemList[i])^.ItemName.AsWideString;
        ListItem.SubItems.Add(Format('%d', [PMailslotAndPipeItem(Collection.ItemList[i])^.Instances]));
        ListItem.SubItems.Add(Format('%d', [PMailslotAndPipeItem(Collection.ItemList[i])^.MaxInstances]));
      end;
    finally
      ListView.Items.EndUpdate;
    end;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FObjectList := TObjMgrListItem.Create(nil, nil, nil);
  FillTreeView;
  FPipes := TMailslotAndPipeCollection.Create(etPipes);
  FMailslots := TMailslotAndPipeCollection.Create(etMailslots);
  FillMailslotsAndPipesList;
  // Size the view for mailslots and pipes evenly
  Panel1.Width := (TSMailslotsPipes.Width - Splitter2.Width) div 2;
end;

// Convert the known types into indexes of the image list

function TMainForm.GetImageIdx(TypeName: string): Integer;
begin
  if (TypeName = 'Directory') then result := 0
  else if (TypeName = 'SymbolicLink') then result := 2
  else if (TypeName = 'Event') then result := 5
  else if (TypeName = 'Mutant') then result := 6
  else if (TypeName = 'Driver') then result := 7
  else if (TypeName = 'WindowStation') then result := 8
  else if (TypeName = 'Section') then result := 9
  else if (TypeName = 'Semaphore') then result := 10
  else if (TypeName = 'Timer') then result := 12
  else if (TypeName = 'Device') then result := 13
  else if (TypeName = 'Type') then result := 16
  else if (TypeName = 'Key') then result := 17
  else if (TypeName = 'Callback') then result := 18
  else if (TypeName = 'Port') then result := 19
  else if (TypeName = 'WaitablePort') then result := 19
  else result := 3; // Unknown

end;

procedure TMainForm.ObjectListCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
var
  I1, I2: Integer;
begin
  if Assigned(Item1.Data) and Assigned(Item2.Data) then
  begin
    I1 := GetImageIdx(TObjMgrListItem(Item1.Data).ObjectTypeName);
    I2 := GetImageIdx(TObjMgrListItem(Item2.Data).ObjectTypeName);
    // Sort first according to the type, directories and symlinks first
    if (I1 <= 2) and (I2 <= 2) then
    begin
      Compare := StrComp(@Item1.Caption[1], @Item2.Caption[1]);
      Exit;
    end;
    // Directory/symlink is higher than the rest
    if (I1 <= 2) and (I2 > 2) then
    begin
      Compare := -1;
      Exit;
    end;
    if (I2 <= 2) and (I1 > 2) then
    begin
      Compare := 1;
      Exit;
    end;
    // if neither is a directory/symlink then sort by name
    Compare := StrComp(@Item1.Caption[1], @Item2.Caption[1]);
  end;
end;

function TMainForm.FindTreeNode(Path: string): TTreeNode;
var
  I: Integer;
begin
  for I := 0 to DirectoryList.Items.Count - 1 do
  begin
    if Assigned(DirectoryList.Items[I].Data) then
      if TObjMgrListItem(DirectoryList.Items[I].Data).FullPath = Path then
      begin
        Result := DirectoryList.Items[I];
        Exit;
      end;
  end;
  Result := nil;
end;

procedure TMainForm.ObjectListDblClick(Sender: TObject);
var
  Node: TTreeNode;
  S: string;
  I: Integer;
  Item: TObjMgrListItem;
begin
  if Assigned(ObjectList.Selected.Data) then
  begin
    Item := TObjMgrListItem(ObjectList.Selected.Data);
    S := Item.FullPath;
    case GetImageIdx(Item.ObjectTypeName) of
      0: { directory }
        begin
          Node := FindTreeNode(S);
          if Assigned(Node) then
          begin
            Node.Selected := True;
            StatusBar1.Panels[0].Text := Format(RsDirectoryChanges, [S]);
            //Exit;
          end;
        end;
      2: { symbolic link }
        if Item.LinkTarget <> '' then
        begin
          S := Item.LinkTarget;
          Node := FindTreeNode(S);
          if Assigned(Node) then
          begin
            Node.Selected := True;
            StatusBar1.Panels[0].Text := Format(RsSymLinkFollowed, [string(Item.FullPath()), S]);
            //Exit;
          end
          else
          begin
            I := Length(S);
            while I > 1 do
            begin
              for I := Length(S) downto 1 do if S[I] = '\' then Break;
              S := Copy(S, 1, I - 1);
              Node := FindTreeNode(S);
              if Assigned(Node) then
              begin
                Node.Selected := True;
                StatusBar1.Panels[0].Text := Format(RsSymLinkFollowed, [string(Item.FullPath), S]);
                Exit;
              end;
            end;
          end;
          // No target could be found ...
          StatusBar1.Panels[0].Text := Format(RsNoTargetInNamespace, [string(Item.LinkTarget)]);
          //Exit;
        end;
    end;
    // At this point we could show properties of all objects except directories and symlinks
  end;
end;

procedure TMainForm.PageControl1Changing(Sender: TObject; var AllowChange: Boolean);
begin
  if PageControl1.ActivePage = TSObjectNamespace then
    FObjectList.RefreshList
  else
    if PageControl1.ActivePage = TSMailslotsPipes then
    begin
      FPipes.RefreshList;
    end;
end;

procedure TMainForm.PageControl1Change(Sender: TObject);
begin
  StatusBar1.Panels[0].Text := '';
  if PageControl1.ActivePage = TSObjectNamespace then
  begin
    FillTreeView;
  end
  else
    if PageControl1.ActivePage = TSMailslotsPipes then
    begin
      FillMailslotsAndPipesList;
    end;
end;

procedure TMainForm.MainMenuFileExitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.MainMenuHelpAboutClick(Sender: TObject);
var
  About: TAboutForm;
begin
  About := TAboutForm.Create(Self);
  try
    About.ShowModal;
  finally
    About.Free;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Assigned(FObjectList) then FObjectList.Free;
  if Assigned(FPipes) then FPipes.Free;
  if Assigned(FMailslots) then FMailslots.Free;
end;

end.

