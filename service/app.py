import os
import socket
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def root():
    response = {
        "app": os.getenv("APP_NAME", "unknown"),
        "version": os.getenv("VERSION", "unknown"),
        "pod": socket.gethostname()
    }
    return jsonify(response)

@app.route('/healthz')
def healthz():
    return '', 200

if __name__ == '__main__':
    # Default to port 8080 as many k8s containers expect this
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
