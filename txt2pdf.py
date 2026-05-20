#! /usr/bin/env python3

# STD LIB IMPORTS

import argparse
import fileinput
import os
import os.path
import shutil
import sys
import tempfile
import unicodedata

from subprocess import run as run_cmd
from typing import Final as F

# PATHS TO SCRIPT DIR AND STUFF IN SCRIPT DIR

script_dir_path   : F[str] = os.path.dirname(__file__)
default_font_path : F[str] = os.path.join(script_dir_path,'cmuntt.otf')
tex_path          : F[str] = os.path.join(script_dir_path,'template.tex')

# PARSER

parser = argparse.ArgumentParser(
  description     = 'Convert Unicode to pdf.',
  formatter_class = argparse.ArgumentDefaultsHelpFormatter,
)
parser.add_argument(
  '--author',
  type    = str,
  default ='Anders E.V. Lundstedt',
  help    = 'author',
)
parser.add_argument(
  '--font',
  type    = str,
  default = default_font_path,
  help    = 'path to font file',
)
parser.add_argument(
  '--text-width',
  type    = int,
  default = 80,
  help    = 'number of characters per line',
)
parser.add_argument('--allow-line-overflow',  action='store_true',default=False)
parser.add_argument('--no-filename-in-header',action='store_true',default=False)
parser.add_argument('--no-datetime-in-header',action='store_true',default=False)
parser.add_argument('--no-author-in-header',  action='store_true',default=False)
parser.add_argument('--no-header',            action='store_true',default=False)
parser.add_argument('--no-page-numbers',      action='store_true',default=False)
parser.add_argument(
  '--title-page',
  action  = 'store_true',
  help    ='Start page numbering on 0 and no header nor footer on first page.',
  default = False,
)
parser.add_argument(
  '--JuliaMono',
  action  = 'store_true',
  help    ='Use font JuliaMono font. (Overrides --font.)',
  default = False,
)
parser.add_argument(
  '--do-not-remove-tmp-files',
  action  = 'store_true',
  default = False,
)
parser.add_argument('input',help='Input file.')

# PARSE INTO ARGS VARIABLE

args : F = parser.parse_args()

# STORE TEXT OF INPUT FILE AS A LIST OF ITS LINES (INCLUDING NEWLINE ENDINGS)

with open(args.input) as f:
    input_lines : F[list[str]]  = list(f.readlines())

# CHECK IF ANY INPUT LINE EXCEEDS THE TEXT WIDTH

if not args.allow_line_overflow:
  def get_displayed_line_length(line:str):
    return len([c for c in line.rstrip() if unicodedata.combining(c) == 0])
  for i,line in enumerate(input_lines,1):
    ## if get_displayed_line_length(line) > args.text_width+1: # why +1?
    if get_displayed_line_length(line) > args.text_width:
      print('Line',i,'exceeding',args.text_width,'characters!')
      sys.exit(1)

# COMPUTE FONT PATH

font_path : F[str] = (
  os.path.join(script_dir_path,'JuliaMono-Light.ttf')
  if args.JuliaMono else
  args.font
)


# COPY FILES TO A TMP DIR

tmp_dir_path   : F[str] = tempfile.mkdtemp()
tmp_tex_path   : F[str] =\
  shutil.copy(os.path.join(script_dir_path,'template.tex'),tmp_dir_path)

shutil.copy(
  args.input,
  os.path.join(tmp_dir_path,'input.txt')
)
shutil.copy(
  font_path,
  os.path.join(tmp_dir_path,'font'+os.path.splitext(args.font)[1])
)

# REPLACE STUFF IN THE TEX TEMPLATE ACCORDING TO ARGUMENTS PROVIDED

def replace(find:str,repl:str):
  with fileinput.FileInput(tmp_tex_path,inplace=True) as f:
    # inplace=True redirects stdout to f
    for line in f:
      print(line.replace(find,repl),end='')

if args.title_page:
  replace('%%% \\thispagestyle{empty}','\\thispagestyle{empty}')
  replace('%%% \\setcounter{page}{0}','\\setcounter{page}{0}')

if args.no_page_numbers:
  replace('%%% \\pagenumbering{gobble}','\\pagenumbering{gobble}')

if args.no_header:
  replace('{\\footnotesize FileNameHere (DateTimeHere)}','')
  replace('{\\footnotesize AuthorInHeaderHere}','')
else:
  if    args.no_filename_in_header and     args.no_datetime_in_header:
    replace('{\\footnotesize FileNameHere (DateTimeHere)}','')
  if    args.no_filename_in_header and not args.no_datetime_in_header:
    replace(
        '{\\footnotesize FileNameHere (DateTimeHere)}',
        '{\\footnotesize DateTimeHere}',
    )
  if not args.no_filename_in_header and args.no_datetime_in_header:
    replace(
        '{\\footnotesize FileNameHere (DateTimeHere)}',
        '{\\footnotesize FileNameHere}',
    )
  if args.no_author_in_header:
    replace('{\\footnotesize AuthorInHeaderHere}','')

filename  : F[str]        = os.path.basename(args.input)
date_cmd_std_out : F[str] =\
  run_cmd(['date','--rfc-3339=seconds'],capture_output=True,text=True).stdout
date_str  : F[str]        = date_cmd_std_out.strip()

replace('TitleHere',         filename)
replace('FileNameHere',      filename)
replace('DateTimeHere',      date_str)
replace('AuthorHere',        args.author)
replace('AuthorInHeaderHere',args.author)

if not args.JuliaMono:
  replace(' CharacterVariant=4, StylisticSet={4}, StylisticSet={10}','')

# PRINT TEX SOURCE

with open(tmp_tex_path) as input_file:
    for line in input_file:
        print(line,end='')

if args.do_not_remove_tmp_files:
  print('========================================')
  print('Path to source above {}:'.format(tmp_tex_path))
  print('========================================')

# RUN XELATEX ON TEX SOURCE

run_cmd(['xelatex','template.tex'],cwd=tmp_dir_path)

# MOVE GENERATED PDF TO OUTPUT PATH

shutil.move(
  os.path.join(tmp_dir_path,'template.pdf'),
  os.path.splitext(args.input)[0]+'.pdf',
)

# REMOVE TMP DIR

if not args.do_not_remove_tmp_files:
  run_cmd(['rm','-rf',tmp_dir_path])

# CHECK UNICODE-COVERAGE

print('========================================')
run_cmd(['check-unicode-coverage','--characters',args.input,font_path])
