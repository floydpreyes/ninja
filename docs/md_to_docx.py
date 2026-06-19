import markdown
from htmldocx import HtmlToDocx
from docx import Document
import sys, os

def md_to_docx(md_path):
    with open(md_path, 'r', encoding='utf-8') as f:
        md_text = f.read()
    
    html = markdown.markdown(md_text, extensions=['tables', 'sane_lists'])
    
    doc = Document()
    parser = HtmlToDocx()
    parser.add_html_to_document(html, doc)
    
    docx_path = os.path.splitext(md_path)[0] + '.docx'
    doc.save(docx_path)
    print(f"Saved: {docx_path}")

# Convert all .md files in the folder
for f in sys.argv[1:]:
    md_to_docx(f)