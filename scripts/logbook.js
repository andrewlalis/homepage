const LOGBOOK_URL = "https://logbook.andrewlalis.com";

const messagesContainer = document.getElementById("messages-container");
const form = document.getElementById("logbook-form");
const formMessageBox = document.getElementById("logbook-form-message-box");
form.onsubmit = async (e) => {
    e.preventDefault();
    const data = {
        name: document.getElementById("logbook-name-input").value,
        message: document.getElementById("logbook-message-input").value
    };
    formMessageBox.style.display = "block";
    formMessageBox.innerText = "Sending log entry...";
    try {
        const response = await fetch(LOGBOOK_URL, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Accept": "application/json"
            },
            body: JSON.stringify(data)
        });
        if (response.ok) {
            formMessageBox.innerText = "Log entry added!";
            form.style.display = "none"; // Hide the form.
            renderMessages(await fetchMessages());
        } else {
            formMessageBox.innerText = "Log entry rejected: " + response.status;
        }
    } catch (error) {
        formMessageBox.innerText = "An error occurred: " + error;
    }
}

// On startup, load the latest messages and show them.
const messagesPromise = fetchMessages();
messagesPromise.then(messages => renderMessages(messages));



async function fetchMessages() {
    const response = await fetch(LOGBOOK_URL);
    if (response.ok) {
        return await response.json();
    } else {
        console.error("Couldn't get log messages.", response.status);
        return [];
    }
}

function renderMessages(messages) {
    messagesContainer.innerHTML = "";
    messages.forEach(message => {
        const messageElement = document.createElement("div");
        messageElement.className = "logbook-message";
        
        const timestampElement = document.createElement("time");
        const date = Date(message.createdAt);
        timestampElement.dateTime = message.createdAt;
        timestampElement.innerText = date.toLocaleString();

        const authorElement = document.createElement("strong");
        authorElement.innerText = message.name;
        const saidElement = document.createElement("span");
        saidElement.innerText = " said: " + message.message;

        const messageBodyElement = document.createElement("p");
        messageBodyElement.appendChild(authorElement);
        messageBodyElement.appendChild(saidElement);
        
        messageElement.appendChild(timestampElement);
        messageElement.appendChild(messageBodyElement);
        messagesContainer.appendChild(messageElement);
    });
}

function escapeHtml(unsafe) {
    return unsafe
         .replace(/&/g, "&amp;")
         .replace(/</g, "&lt;")
         .replace(/>/g, "&gt;")
         .replace(/"/g, "&quot;")
         .replace(/'/g, "&#039;");
 }
