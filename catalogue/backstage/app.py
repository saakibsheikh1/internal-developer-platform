from pathlib import Path

import markdown
import yaml
from flask import Flask, render_template, render_template_string

app = Flask(__name__)

BASE_DIR = Path(__file__).resolve().parent


def load_catalogue():
    services = []

    for catalog_file in BASE_DIR.glob("*/catalog-info.yaml"):
        with catalog_file.open("r", encoding="utf-8") as file:
            data = yaml.safe_load(file)

        metadata = data.get("metadata", {})
        spec = data.get("spec", {})
        annotations = metadata.get("annotations", {})
        links = metadata.get("links", [])

        services.append({
            "name": metadata.get("name", catalog_file.parent.name),
            "description": metadata.get("description", ""),
            "tags": metadata.get("tags", []),
            "owner": spec.get("owner", "unknown"),
            "type": spec.get("type", "unknown"),
            "lifecycle": spec.get("lifecycle", "unknown"),
            "status": annotations.get(
                "idp.io/deployment-status",
                "unknown"
            ),
            "techdocs": annotations.get(
                "idp.io/techdocs"
            ),
            "links": links,
        })

    return sorted(services, key=lambda service: service["name"])


@app.route("/")
def catalogue():
    services = load_catalogue()

    return render_template(
        "index.html",
        services=services
    )


@app.route("/docs/payment-api")
def payment_api_docs():
    docs_file = BASE_DIR.parent.parent / "docs" / "payment-api" / "index.md"

    markdown_content = docs_file.read_text(
        encoding="utf-8"
    )

    html_content = markdown.markdown(
        markdown_content,
        extensions=["tables", "fenced_code"]
    )

    return render_template_string(
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport"
                    content="width=device-width, initial-scale=1.0">
            <title>Payment API - TechDocs</title>

            <style>
                body {
                    font-family: Arial, sans-serif;
                    background: #f4f6f8;
                    color: #17202a;
                    margin: 0;
                }

                header {
                    background: #1f2937;
                    color: white;
                    padding: 25px 40px;
                }

                main {
                    max-width: 950px;
                    margin: 35px auto;
                    background: white;
                    padding: 40px;
                    border-radius: 10px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.08);
                }

                h1, h2, h3 {
                    color: #1f2937;
                }

                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 20px 0;
                }

                th, td {
                    border: 1px solid #ddd;
                    padding: 10px;
                    text-align: left;
                }

                th {
                    background: #f3f4f6;
                }

                code {
                    background: #f1f1f1;
                    padding: 2px 5px;
                    border-radius: 4px;
                }

                a {
                    color: #2563eb;
                }
            </style>
        </head>

        <body>

        <header>
            <strong>Internal Developer Platform</strong>
            <div>Payment API — TechDocs</div>
        </header>

        <main>

            <p>
                <a href="/">? Back to Service Catalogue</a>
            </p>

            {{ content|safe }}

        </main>

        </body>
        </html>
        """,
        content=html_content
    )


if __name__ == "__main__":
    app.run(
        host="127.0.0.1",
        port=5000,
        debug=True
    )

