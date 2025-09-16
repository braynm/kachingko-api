import fitz  # pip install PyMuPDF
from collections import defaultdict
from erlport.erlang import Atom

def extract_all_tables(pdf_path, password, y_tol=2.0):
    """
    Extracts word-grouped table-like data from each page in a password-protected PDF.
    Designed for Elixir -> Python bridging via erlport.
    """
    try:
        pdf_path = pdf_path.decode("utf-8")
        password = password.decode("utf-8")

        doc = fitz.open(pdf_path)
        if doc.is_encrypted:
            if not doc.authenticate(password):
                return Atom(b"error"), "Incorrect password"

        all_tables = []

        for page_index in range(len(doc)):
            page = doc.load_page(page_index)
            words = page.get_text("words")

            rows = defaultdict(list)
            for x0, y0, x1, y1, word, *_ in words:
                key = round(y0 / y_tol) * y_tol
                rows[key].append((x0, word))

            table = []
            for y in sorted(rows):
                line = [w for x, w in sorted(rows[y], key=lambda t: t[0])]
                table.append(line)

            all_tables.append(table)

        return Atom(b"ok"), all_tables

    except Exception as e:
        return Atom(b"error"), str(e)

