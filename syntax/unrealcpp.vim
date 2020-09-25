" Vim syntax file
" Language:	C++ with Unreal extensions
" Maintainer:	Ludovic Chabant <https://ludovic.chabant.com>

if exists("b:current_syntax")
  finish
endif

" Read the C++ syntax to start with
runtime! syntax/cpp.vim
unlet b:current_syntax


" Highlight Class and Function names
syn match    cCustomParen    "(" contains=cParen,cCppParen
syn match    cCustomFunc     "\w\+\s*(" contains=cCustomParen
syn match    cCustomScope    "::"
syn match    cCustomClass    "\w\+\s*::" contains=cCustomScope

hi def link cCustomFunc  Function
hi def link cCustomClass Function

