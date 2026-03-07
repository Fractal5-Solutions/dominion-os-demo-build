from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({
        'service': 'Dominion Relationships API',
        'status': 'operational',
        'version': '1.0.0',
        'description': 'Unified relationship management across CRM and BIMS',
        'environment': os.getenv('ENVIRONMENT', 'development')
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'relationships'})

@app.route('/api/relationships')
def relationships():
    return jsonify({
        'relationships': [],
        'sources': ['crm', 'bims', 'apollo'],
        'message': 'Relationships API operational'
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
