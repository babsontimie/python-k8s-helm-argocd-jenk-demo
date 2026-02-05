from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.get("/healthz")
def healthz():
    return "ok", 200

@app.get("/readyz")
def readyz():
    return "ready", 200

@app.get("/")
def root():
    return jsonify(
        service="python-k8s-demo",
        version=os.getenv("APP_VERSION", "dev"),
        env=os.getenv("APP_ENV", "dev")
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
