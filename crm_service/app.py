from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({
        'service': 'Dominion CRM',
        'status': 'operational',
        'version': '1.0.0',
        'environment': os.getenv('ENVIRONMENT', 'development')
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'crm'})

@app.route('/api/contacts')
def contacts():
    return jsonify({
        'contacts': [],
        'message': 'CRM service operational - Apollo integration ready'
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
