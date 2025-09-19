import io
from collections import defaultdict
import pikepdf
import pdfplumber
from erlport.erlang import Atom

def extract_all_tables(pdf_path, password, y_tol=2.0):
    """
    Extracts word-grouped table-like data from each page in a password-protected PDF.
    Uses PikePDF + pdfplumber.
    Compatible with Elixir -> Python via erlport.

    Merges words with nearly identical vertical positions to prevent row splitting.
    """
    try:
        # Decode if bytes
        if isinstance(pdf_path, bytes):
            pdf_path = pdf_path.decode("utf-8")
        if isinstance(password, bytes):
            password = password.decode("utf-8")

        # Open PDF with password
        try:
            with pikepdf.open(pdf_path, password=password) as pdf:
                buf = io.BytesIO()
                pdf.save(buf)
                buf.seek(0)
        except Exception as e:
            msg = str(e)
            if "invalid password" in msg.lower():
                return Atom(b"error"), "Incorrect password"
            return Atom(b"error"), msg


        all_tables = []

        with pdfplumber.open(buf) as plumber_pdf:
            for page in plumber_pdf.pages:
                words = page.extract_words() or []

                # Group words by approximate y position
                rows = defaultdict(list)
                for word in words:
                    y0 = word["top"]
                    x0 = word["x0"]
                    text = word["text"]
                    key = round(y0 / y_tol) * y_tol
                    rows[key].append((x0, text))

                # Merge rows that are very close vertically
                merged_rows = []
                sorted_y = sorted(rows.keys())
                current_row = []
                last_y = None

                for y in sorted_y:
                    if last_y is None or abs(y - last_y) <= y_tol:
                        current_row.extend(rows[y])
                    else:
                        merged_rows.append(sorted(current_row, key=lambda t: t[0]))
                        current_row = rows[y]
                    last_y = y

                if current_row:
                    merged_rows.append(sorted(current_row, key=lambda t: t[0]))

                # Extract only text for each row
                table = [[w for x, w in row] for row in merged_rows]
                all_tables.append(table)

        return Atom(b"ok"), all_tables

    except Exception as e:
        return Atom(b"error"), str(e)

