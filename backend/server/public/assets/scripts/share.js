const link = window.location.href;
const encodedLink = encodeURIComponent(link);
const encodedMessage = encodeURIComponent("Check out this magazine!");

// Set WhatsApp and SMS links
document.getElementById(
  "whatsapp-share"
).href = `https://wa.me/?text=${encodedMessage}%20${encodedLink}`;
document.getElementById(
  "sms-share"
).href = `sms:?body=${encodedMessage}%20${link}`;
document.getElementById("facebook-share").href = `https://www.facebook.com/sharer/sharer.php?u=${encodedLink}`;
  document.getElementById("twitter-share").href = `https://twitter.com/intent/tweet?url=${encodedLink}&text=${encodedMessage}`;
  document.getElementById("telegram-share").href = `https://t.me/share/url?url=${encodedLink}&text=${encodedMessage}`;

// Copy to clipboard
function copyLink() {
  navigator.clipboard
    .writeText(link)
    .then(() => alert("Link copied to clipboard!"))
    .catch((err) => console.error("Failed to copy:", err));
}

// Native Share
function shareNative() {
  if (navigator.share) {
    navigator
      .share({
        title: "Magazine Share",
        text: "Check out this magazine!",
        url: link,
      })
      .catch((err) => console.error("Share failed:", err));
  } else {
    alert("Native sharing not supported on this device.");
  }
}
