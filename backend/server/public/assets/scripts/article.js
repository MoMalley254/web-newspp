const articlesLoader = document.querySelector(".loading-article-content");
const dotsSpan = document.querySelector(".loader .dots");

let dotCount = 0;

const isMobile = detectDeviceType();

function detectDeviceType() {
  const ua = navigator.userAgent;

  if (/tablet|ipad|playbook|silk/i.test(ua)) {
    return false;
  }

  if (/Mobile|Android|iPhone|iPod|IEMobile|BlackBerry|Opera Mini/i.test(ua)) {
    return true;
  }

  return false;
}

// Animate loading dots
const dotsInterval = setInterval(() => {
  dotCount = (dotCount + 1) % 4;
  dotsSpan.textContent = ".".repeat(dotCount);
}, 500);