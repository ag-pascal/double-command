// +----------------------------------------------------------------------+
// |    chsdet - Charset Detector Library                                 |
// +----------------------------------------------------------------------+
// | Copyright (C) 2006, Nick Yakowlew     http://chsdet.sourceforge.net  |
// +----------------------------------------------------------------------+
// | Based on Mozilla sources     http://www.mozilla.org/projects/intl/   |
// +----------------------------------------------------------------------+
// | This library is free software; you can redistribute it and/or modify |
// | it under the terms of the GNU General Public License as published by |
// | the Free Software Foundation; either version 2 of the License, or    |
// | (at your option) any later version.                                  |
// | This library is distributed in the hope that it will be useful       |
// | but WITHOUT ANY WARRANTY; without even the implied warranty of       |
// | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                 |
// | See the GNU Lesser General Public License for more details.          |
// | http://www.opensource.org/licenses/lgpl-license.php                  |
// +----------------------------------------------------------------------+
//
// $Id: chsdet.lpr,v 1.1 2009/03/20 17:40:22 ya_nick Exp $

library chsdet;

uses
  chsdIntf in 'chsdIntf.pas',
  LangBulgarianModel in 'sbseq/LangBulgarianModel.pas',
  LangCyrillicModel in 'sbseq/LangCyrillicModel.pas',
  LangGreekModel in 'sbseq/LangGreekModel.pas',
  LangHebrewModel in 'sbseq/LangHebrewModel.pas' ;

exports
	csd_Reset,
  csd_HandleData,
  csd_Done,
  csd_DataEnd,
  csd_GetDetectedCharset,
  csd_GetKnownCharsets,
  csd_GetAbout;
{.chsdet$R *.res}

{.chsdet$R chsdet.res}

begin
end.

