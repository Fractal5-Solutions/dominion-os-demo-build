from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({
        'service': 'Dominion BIMS',
        'status': 'operational',
        'version': '1.0.0',
        'description': 'Business Information Management System',
        'environment': os.getenv('ENVIRONMENT', 'development')
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'bims'})

@app.route('/api/integrations')
def integrations():
    return jsonify({
        'integrations': ['gmail', 'google-drive', 'dropbox'],
        'message': 'BIMS service operational - All integrations ready'
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
