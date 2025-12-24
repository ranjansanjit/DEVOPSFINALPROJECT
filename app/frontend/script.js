const API_URL = "http://192.168.56.19:5000/contacts";

// Load contacts
$(document).ready(function () {
    loadContacts();
});

// Fetch all
function loadContacts() {
    $.get(API_URL, function (data) {
        $("#contactTable").html("");

        data.forEach(c => {
            $("#contactTable").append(`
                <tr>
                    <td>${c.id}</td>
                    <td>${c.name}</td>
                    <td>${c.email}</td>
                    <td>${c.phone}</td>
                    <td>
                        <button class="btn btn-warning btn-sm me-1"
                            onclick="openEdit(${c.id}, '${c.name}', '${c.email}', '${c.phone}')">
                            Edit
                        </button>
                        <button class="btn btn-danger btn-sm"
                            onclick="deleteContact(${c.id})">
                            Delete
                        </button>
                    </td>
                </tr>
            `);
        });
    });
}

// Add contact
$("#contactForm").submit(function (e) {
    e.preventDefault();

    $.ajax({
        url: API_URL,
        method: "POST",
        contentType: "application/json",
        data: JSON.stringify({
            name: $("#name").val(),
            email: $("#email").val(),
            phone: $("#phone").val()
        }),
        success: function () {
            $("#contactForm")[0].reset();
            loadContacts();
        }
    });
});

// Open edit modal
function openEdit(id, name, email, phone) {
    $("#editId").val(id);
    $("#editName").val(name);
    $("#editEmail").val(email);
    $("#editPhone").val(phone);

    $("#editModal").modal("show"); // ✅ jQuery modal
}

// Update contact
function updateContact() {
    const id = $("#editId").val();

    $.ajax({
        url: `${API_URL}/${id}`,
        method: "PUT",
        contentType: "application/json",
        data: JSON.stringify({
            name: $("#editName").val(),
            email: $("#editEmail").val(),
            phone: $("#editPhone").val()
        }),
        success: function () {
            $("#editModal").modal("hide");
            loadContacts();
        }
    });
}

// Delete
function deleteContact(id) {
    $.ajax({
        url: `${API_URL}/${id}`,
        method: "DELETE",
        success: loadContacts
    });
}
