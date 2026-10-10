import json
import os
import socket

from flask import Flask, Response

app = Flask(__name__)


@app.route("/")
def root():
    payload = {
        "app": os.environ["APP_NAME"] if "APP_NAME" in os.environ else "unknown",
        "version": os.environ["VERSION"] if "VERSION" in os.environ else "unknown",
        "pod": socket.gethostname(),
    }
    body = json.dumps(payload, separators=(",", ":"))
    return Response(body, status=200, mimetype="application/json")


@app.route("/healthz")
def healthz():
    return Response("ok", status=200, mimetype="text/plain")


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
