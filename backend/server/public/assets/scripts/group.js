const copySpan = document.getElementById("copy");
const articles = document.querySelectorAll('.article-thumbnail');

articles.forEach((thumb) => {
    thumb.addEventListener("click", () => {
    // showArticleContent(mag, actualArticleName);
    const articleId = thumb.getAttribute('data-identifier');
    window.location.href = `/front/view?article=${encodeURIComponent(
      articleId
    )}`;
  });
});

const year = new Date().getFullYear();
copySpan.textContent = year;
