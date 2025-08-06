const hideMenuBtn = document.getElementById('btn-hide-controls');
hideMenuBtn.addEventListener('click', (e) => {
    const topControls = document.querySelector('.top-show-controls');

    // Fade out current icon
    e.target.style.opacity = '0';

    setTimeout(() => {
        if (topControls.classList.contains('hide')) {
            topControls.classList.remove('hide');
            e.target.innerHTML = `<i class="material-icons">keyboard_double_arrow_left</i>`;
            hideMenuBtn.setAttribute('aria-label', 'Hide Controls');
        } else {
            topControls.classList.add('hide');
            e.target.innerHTML = `<i class="material-icons">keyboard_double_arrow_right</i>`;
            hideMenuBtn.setAttribute('aria-label', 'Show Controls');
        }

        // Fade in new icon
        e.target.style.opacity = '1';
    }, 400); // match the CSS transition duration
    
});

const articlesSection = document.getElementById('articlesSection');
const articleNames = articlesSection.dataset.articleNames.split(',').map(name => name.trim());
const thumbnailsContainer = document.getElementById('article-thumbnails'); // container for thumbnails
const articleContainer = document.getElementById('article'); // container for full article content
const articlesLoader = document.querySelector('.loading-articles');
const dotsSpan = document.querySelector('.loading-articles .dots');
const foundShower = document.querySelector('.found-articles');
const thumbnailsSideView = document.getElementById('thumbnailsSideView');

let dotCount = 0;
let foundArticles = 0;

// Animate loading dots
const dotsInterval = setInterval(() => {
  dotCount = (dotCount + 1) % 4;
  dotsSpan.textContent = '.'.repeat(dotCount);
}, 500);

const articlesPath = `/assets/articles`;

const fetchPromises = articleNames.map(article => {
  const url = `${articlesPath}/${encodeURIComponent(article)}`;
  console.log('Fetching:', url);

  return fetch(url)
    .then(response => {
      if (!response.ok) throw new Error(`File not found: ${article}`);
      foundArticles++;
      console.log(`Found: ${article} (Total found: ${foundArticles})`);

      if (foundShower) {
        foundShower.style.opacity = '1';
        const countElem = foundShower.querySelector('.article-count');
        if (countElem) countElem.textContent = foundArticles;
      }

      return response.text().then(html => ({ html, article }));
    })
    .catch(error => {
      console.error(error.message);
      return null;
    });
});

Promise.all(fetchPromises).then(results => {
  clearInterval(dotsInterval);
  if (articlesLoader) articlesLoader.style.display = 'none';

  const validResults = results.filter(r => r !== null);

  validResults.forEach(({ html, article }) => {
    // Create thumbnail element
    const thumb = document.createElement('div');
    const actualArticleName = article.replace(/\.[^/.]+$/, '').replace('_', ' ');
    thumb.className = 'article-thumbnail';
    thumb.textContent = actualArticleName; 
    
    // On click, show full article
    thumb.addEventListener('click', () => {
        showArticleContent(html, articleContainer, actualArticleName);
        thumbnailsContainer.style.display = 'none';
    });

    thumbnailsContainer.appendChild(thumb);
    thumbnailsSideView.appendChild(thumb);
  });

  console.log(`Thumbnails created: ${validResults.length}`);
});

function showArticleContent(articleHTML, articleContainer, actualArticleName) {
  const loadingArticleContent = document.querySelector('.loading-article-content');
  loadingArticleContent.style.display = 'block';
  loadingArticleContent.querySelector('.article-name').textContent = actualArticleName;

  try {
    const parser = new DOMParser();
    const doc = parser.parseFromString(articleHTML, 'text/html');
    const pageContent = doc.body; // or use a specific selector, e.g., doc.querySelector('#pff')

    if (pageContent) {
      // Insert content asynchronously to let browser update the UI (show loader)
      setTimeout(() => {
        articleContainer.innerHTML = pageContent.innerHTML;

        // Optionally wait for images/media to load here before hiding loader

        // Hide loader after content inserted
        loadingArticleContent.querySelector('.article-name').textContent = '';
        loadingArticleContent.style.display = 'none';
      }, 0);
    } else {
      articleContainer.innerHTML = `<p>Unable to extract ${actualArticleName} content.</p>`;
      loadingArticleContent.querySelector('.article-name').textContent = '';
      loadingArticleContent.style.display = 'none';
    }
  } catch (error) {
    articleContainer.innerHTML = `<p>Unable to extract ${actualArticleName} content.</p>`;
    loadingArticleContent.querySelector('.article-name').textContent = '';
    loadingArticleContent.style.display = 'none';
  }
}



