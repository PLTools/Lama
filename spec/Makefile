all: metagen
	pdflatex lama-spec.tex
	bibtex lama-spec
	pdflatex lama-spec.tex

metagen:
	git rev-parse --verify HEAD | LC_TIME=en_US.UTF-8 git show --no-patch --no-notes --pretty='%cd' --date=format:"%B, %e, %Y" > commitdate.tex

clean:
	rm -Rf *~ *.log *.aux *.toc *.bbl *.blg *.out *.bak *.pdf

