{******************************************************************************}
{                                                                              }
{ ObjectMgr sample program to demonstrate the object namespace                 }
{                                                                              }
{ ObjectMgr.dpr       - Main project file                                      }
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

program ObjectMgr;

uses
  Forms,
  SysUtils,
  JwaNative,
  MainFormUnit in 'MainFormUnit.pas' {MainForm},
  ObjectMgrHelper in 'ObjectMgrHelper.pas',
  AboutUnit in 'AboutUnit.pas' {AboutForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Object Namespace Viewer';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

