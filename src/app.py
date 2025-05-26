from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def home():
    products = [
        {"id": 1, "name": "Laptop", "price": 999.99},
        {"id": 2, "name": "Smartphone", "price": 699.99},
        {"id": 3, "name": "Headphones", "price": 149.99}
    ]
    return render_template('index.html', products=products)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
