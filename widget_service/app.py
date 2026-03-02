import os

from flask import Flask, send_file

app = Flask(__name__)


@app.route("/")
def serve_widget():
    return send_file("widget.html", mimetype="text/html")


@app.route("/health")
def health():
    return {"status": "healthy", "service": "askphi-widget"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
