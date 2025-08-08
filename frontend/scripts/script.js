const hideMenuBtn = document.getElementById('btn-hide-controls');
const topControls = document.querySelector('.top-show-controls');
const content = document.querySelector('.content');

hideMenuBtn.addEventListener('click', (e) => {

    // Fade out current icon
    e.target.style.opacity = '0';

    setTimeout(() => {
        if (topControls.classList.contains('hide')) {
            topControls.classList.remove('hide');

            enlarge(false);
            
            e.target.innerHTML = `<i class="material-icons">keyboard_double_arrow_up</i>`;
            hideMenuBtn.setAttribute('aria-label', 'Hide Controls');
        } else {
            topControls.classList.add('hide');

            enlarge(true);
            
            e.target.innerHTML = `<i class="material-icons">keyboard_double_arrow_down</i>`;
            hideMenuBtn.setAttribute('aria-label', 'Show Controls');
        }

        // Fade in new icon
        e.target.style.opacity = '1';
    }, 400); // match the CSS transition duration
    
});

function enlarge(state) {
    const flipbookContainer = document.querySelector('#flipbook');
    const flipbook = $('#flipbook');
    if (state) {
        content.style.marginTop = '10vh';
        content.style.height = '85vh';

        if (flipbookContainer) {
            flipbookContainer.style.marginLeft = '15vw';
            // flipbook.turn('size', '80vw', '85vh');
        }
        

        // flipbookSpace.forEach((page) => {
        //     page.style.height = '85vh';  
        //     page.style.width = '80vw'; 
        // }) 
    } else {
        content.style.marginTop = '15vh';
        content.style.height = '80vh';

        if (flipbookContainer) {
            flipbookContainer.style.marginLeft = '20vw';
            // flipbook.turn('size', '70vw', '75vh');
        }
        

        // flipbookSpace.forEach((page) => {
        //     page.style.height = '75vh';  
        //     page.style.width = '70vw';
        // })
    }
    // Resize Turn.js
    // const width = flipbook.width();
    // const height = flipbook.height();

    
}





