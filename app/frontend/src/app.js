const btn = document.getElementById("surpriseBtn");
const message = document.getElementById("message");

btn.addEventListener("click", () => {
  const nameInput = document.getElementById("name").value || "skr";

  // Show message
  message.textContent = `🎉 Happy Birthday, ${nameInput}! 🎂 Wishing you a day full of joy!`;

  // Add confetti
  message.innerHTML += "<br/>";
  for (let i = 0; i < 20; i++) {
    const span = document.createElement("span");
    span.className = `confetti-piece c-${i % 6}`;
    message.appendChild(span);
  }
});
