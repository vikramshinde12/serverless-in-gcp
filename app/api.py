import os
from flask import Flask, jsonify
from google.cloud import datastore

app = Flask(__name__)


@app.route('/id/<id>')
def get_employee(id):
    client = datastore.Client()
    key = client.key("employee", id)
    entity = client.get(key)

    if entity:
        return jsonify(entity)
    else:
        return jsonify("Not Found")


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))