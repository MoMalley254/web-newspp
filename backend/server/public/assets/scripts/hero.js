document.addEventListener("DOMContentLoaded", () => {
  const scrollToArticlesBtns = document.querySelectorAll(".scrollToArticles");
  scrollToArticlesBtns.forEach((scrollBtn) => {
    scrollBtn.addEventListener("click", (e) => {
      e.preventDefault();
      window.scrollBy({
        top: window.innerHeight * 0.8, // 80vh in pixels
        left: 0,
        behavior: "smooth",
      });
    });
  });
});
