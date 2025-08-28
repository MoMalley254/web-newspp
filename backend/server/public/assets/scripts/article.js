const articlesLoader = document.querySelector(".loading-article-content");
const dotsSpan = document.querySelector(".loader .dots");
const flipContainer = document.getElementById('flipContainer');

let dotCount = 0;
const isMobile = detectDeviceType();

document.addEventListener('DOMContentLoaded', async function() {
    prepareFlipBook();  
});

function showErrorDiv(parentContainer, errorMessage) {
    const div = document.createElement('div');
    div.innerHTML = `
        <div
        class="alert alert-danger d-flex justify-content-between align-items-center"
        role="alert"
      >
        <div>
          <strong>Error:</strong> <br />
          ${errorMessage}
        </div>
        <br />
        <div>
          <button
            class="btn btn-outline-success btn-sm me-2"
            onclick="location.reload()"
          >
            Reload
          </button>
        </div>
      </div>
    `;
    parentContainer.innerHTML = div;
}


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

async function prepareFlipBook() {
    try {
        const resourceUrl = flipContainer.getAttribute('data-resource-url');
        console.log(`Resource url ${resourceUrl}`);
    } catch (error) {
        console.error(`Prepare flipbook error ${error}`);
        showErrorDiv(flipContainer, error);
    }
}