#!/bin/bash
# Dependencies: texlive-basic texlive-latexextra

set -e
if [[ "$#" -lt 2 ]]; then
    echo "[?] Usage: $0 <color_image> <bw_image> [output.pdf]"
    exit 1
fi

COLOR_IMG="$1"
BW_IMG="$2"
OUTPUT_PDF="${3:-output.pdf}"

if [[ ! -f "$COLOR_IMG" || ! -f "$BW_IMG" ]]; then
    echo "[!] Error: One or both input images do not exist."
    exit 1
fi

TMP_DIR=$(mktemp -d)
TEX_FILE="$TMP_DIR/build.tex"
C_EXT="${COLOR_IMG##*.}"
B_EXT="${BW_IMG##*.}"

cp "$COLOR_IMG" "$TMP_DIR/color_img.$C_EXT"
cp "$BW_IMG" "$TMP_DIR/bw_img.$B_EXT"

echo "[*] Generating layout..."

cat <<EOF > "$TEX_FILE"
\documentclass[tikz]{standalone}
\usepackage{graphicx}
\usepackage{ocgx2}

\begin{document}
\begin{tikzpicture}[inner sep=0pt, outer sep=0pt]

  % Bottom: Black & White (no OCG)
  \node[anchor=south west] at (0,0) {%
      \includegraphics{bw_img.$B_EXT}%
  };

  % Top: Color (OCG layer => hides during printing)
  \node[anchor=south west] at (0,0) {%
    \begin{ocg}[printocg=never, listintoolbar=always]{Color Version}{color_layer}{on}%
      \includegraphics{color_img.$C_EXT}%
    \end{ocg}%
  };

\end{tikzpicture}
\end{document}
EOF

# Idk why the second pass is needed, it fixes the ocg layer not working correcly
echo "[*] [1/2 pass] Compiling PDF..."
pdflatex -interaction=batchmode -output-directory="$TMP_DIR" "$TEX_FILE" > /dev/null

echo "[*] [2/2 pass] Compiling PDF..."
pdflatex -interaction=batchmode -output-directory="$TMP_DIR" "$TEX_FILE" > /dev/null

cp "$TMP_DIR/build.pdf" "$OUTPUT_PDF"
rm -rf "$TMP_DIR"

echo "[+] Success: $OUTPUT_PDF"
