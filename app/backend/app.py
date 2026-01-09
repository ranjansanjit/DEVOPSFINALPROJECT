from flask import Flask, request, jsonify
from config import Config
from models import db, Contact
from db_init import create_database
from flask_cors import CORS

app = Flask(__name__)
app.config.from_object(Config)

app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
CORS(app)

create_database()

db.init_app(app)
with app.app_context():
    db.create_all()


@app.route("/contacts", methods=["POST"])
def create_contact():
    data = request.json

    new_contact = Contact(
        name=data["name"],
        email=data["email"],
        phone=data["phone"]
    )

    db.session.add(new_contact)
    db.session.commit()

    return jsonify({"message": "Contact created"}), 201


@app.route("/contacts", methods=["GET"])
def get_contacts():
    contacts = Contact.query.all()
    return jsonify([c.to_dict() for c in contacts])


@app.route("/contacts/<int:id>", methods=["GET"])
def get_contact(id):
    contact = Contact.query.get_or_404(id)
    return jsonify(contact.to_dict())


@app.route("/contacts/<int:id>", methods=["PUT"])
def update_contact(id):
    contact = Contact.query.get_or_404(id)
    data = request.json

    contact.name = data.get("name", contact.name)
    contact.email = data.get("email", contact.email)
    contact.phone = data.get("phone", contact.phone)

    db.session.commit()
    return jsonify({"message": "Contact updated"})


@app.route("/contacts/<int:id>", methods=["DELETE"])
def delete_contact(id):
    contact = Contact.query.get_or_404(id)
    db.session.delete(contact)
    db.session.commit()

    return jsonify({"message": "Contact deleted"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
