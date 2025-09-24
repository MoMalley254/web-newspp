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

  setInterval(flipImages, 2000);
  function flipImages() {
    const coverImages = document.querySelectorAll('.cover');
    // Create a copy of the current class names in the order they appear
  const currentClasses = Array.from(coverImages).map(img => {
    if (img.classList.contains('main')) return 'main';
    if (img.classList.contains('behind-1')) return 'behind-1';
    if (img.classList.contains('behind-2')) return 'behind-2';
  });

  // Rotate the class names: move the last to the front
  const newClasses = [currentClasses[2], currentClasses[0], currentClasses[1]];

  // Apply the rotated classes back to the elements
  coverImages.forEach((img, index) => {
    img.classList.remove('main', 'behind-1', 'behind-2');
    img.classList.add(newClasses[index]);
  });
  }
});
