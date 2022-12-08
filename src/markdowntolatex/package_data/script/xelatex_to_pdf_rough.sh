folder=$(pwd)
folder_pdf=$folder/output/pdf
folder_xelatex=$folder/output/xelatex
mkdir $folder_pdf
cd $folder_xelatex
xelatex DM.tex
cp DM.pdf $folder_pdf/DM.pdf
cd $folder
echo "Compilation worked! DM.pdf was created from LaTeX source code \
then copied in output/source/pdf.\nMarkdownToLaTeX: End."