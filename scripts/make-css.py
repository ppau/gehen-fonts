#!/usr/bin/env python
from __future__ import print_function, unicode_literals
import sys
import string
from subprocess import Popen, PIPE
from collections import defaultdict

html = """<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<link rel="stylesheet" type="text/css" href="webfonts.css">
	<title>{family}</title>
	<style>
	div {
		font-family: '{family}';
	}
	.caption {
		position: absolute;
		top: 0;
		left: 0;
	}
	</style>
</head>
<body>
{demos}
</body>
</html>
"""

div = '\t<div style="position: relative; font-size: {pt}pt"><div style="caption">{pt}pt</div>{test_text}</div>'

script = """
i = 1
while ( i < $argc )
  Open($argv[i], 1)
  Print($argv[i] + ":" + $familyname + ":" + $weight + ":" + ToString($italicangle))
  Close()
  i++
endloop
"""

fontface = """@font-face {{
    font-family: '{font_family}';
    src: url('{eot}');
    src: url('{eot}?#iefix') format('embedded-opentype'),
         url('{woff}') format('woff'),
         url('{ttf}') format('truetype'),
         url('{svg}#{font_family}') format('svg');
    font-weight: {weight};
    font-style: {style};
}}
"""

def isBold(x):
	if x.lower() == "bold":
		return "bold"
	return "normal"

def isItalic(x):
	if x != '0':
		return "italic"
	return "normal"

def make_css(args):
	p = Popen(['fontforge', '-c', script] + args, stdout=PIPE, stderr=PIPE, close_fds=True)
	out, err = p.communicate()#[0].decode()
	out = out.decode()
	err = err.decode()
	files = defaultdict(list)

	for line in out.split('\n'):
		if line.strip() == "":
			continue
		fn, family, bold, italic = line.split(":")
		files[family.replace(" ", "")].append((isBold(bold), isItalic(italic), fn.strip()))

	css = []
	for family, opts in files.items():
		for opt in opts:
			bold, italic, fn = opt
			ttf = fn.rsplit('.', 1)[0].rsplit("/", 1)[-1] + ".ttf"
			eot = fn.rsplit('.', 1)[0].rsplit("/", 1)[-1] + ".eot"
			woff = fn.rsplit('.', 1)[0].rsplit("/", 1)[-1] + ".woff"
			svg = fn.rsplit('.', 1)[0].rsplit("/", 1)[-1] + ".svg"
		
			css.append(fontface.format(
				font_family=family,
				ttf=ttf,
				eot=eot,
				woff=woff,
				svg=svg,
				weight=bold,
				style=italic
			))
	print("\n".join(css))

if __name__ == "__main__":
	if len(sys.argv) < 2:
		print("Usage:", sys.argv[0], 'files')
		sys.exit()
	make_css(sys.argv[1:])
