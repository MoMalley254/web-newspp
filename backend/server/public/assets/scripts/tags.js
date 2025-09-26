const copySpan = document.getElementById("copy");
const tags = document.querySelectorAll('.tag-thumbnail');

tags.forEach((thumb) => {
    thumb.addEventListener("click", () => {
    // showArticleContent(mag, actualArticleName);
    const tagId = thumb.getAttribute('data-identifier');
    window.location.href = `/front/tag?tag=${encodeURIComponent(
      tagId
    )}`;
  });
});

const year = new Date().getFullYear();
copySpan.textContent = year;
