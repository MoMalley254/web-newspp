const hideMenuBtn = document.getElementById('btn-hide-controls');
const topControls = document.querySelector('.top-show-controls');
const content = document.querySelector('.content');

const fullScreenBtn = document.getElementById('btn-fullscreen');
const fullScreenContent = document.querySelector('.content-body');

const sectionsBtn = document.getElementById('btn-menu');
const blackOverlay = document.querySelector('.blackOverlay');

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
            flipbookContainer.style.marginLeft = isMobile ? '' : '5vw';
            // flipbook.turn('size', '80vw', '85vh');
        }
        

        // flipbookSpace.forEach((page) => {
        //     page.style.height = '85vh';  
        //     page.style.width = '80vw'; 
        // }) 
    } else {
        content.style.marginTop = isMobile ? '17vh' : '15vh';
        content.style.height = '80vh';

        if (flipbookContainer) {
            flipbookContainer.style.marginLeft = isMobile ? '' : '9vw';
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

fullScreenBtn.addEventListener('click', (e) => {
    if (fullScreenBtn.getAttribute('aria-label') === 'Full Screen') {
        if (fullScreenContent.requestFullscreen) {
            fullScreenContent.requestFullscreen();
        } else if (fullScreenContent.webkitRequestFullscreen) { // Safari
            fullScreenContent.webkitRequestFullscreen();
        } else if (fullScreenContent.msRequestFullscreen) { // IE11
            fullScreenContent.msRequestFullscreen();
        }

        fullScreenBtn.innerHTML = `<i class="material-icons">fullscreen_exit</i>`;
        fullScreenBtn.setAttribute('aria-label', 'Exit Full Screen');
    } else {
        if (document.exitFullscreen) {
            document.exitFullscreen();
        } else if (document.webkitExitFullscreen) { // Safari
            document.webkitExitFullscreen();
        } else if (document.msExitFullscreen) { // IE11
            document.msExitFullscreen();
        }

        fullScreenBtn.innerHTML = `<i class="material-icons">fullscreen</i>`;
        fullScreenBtn.setAttribute('aria-label', 'Full Screen');
    }    
});

document.addEventListener('fullscreenchange', () => {
    if (!document.fullscreenElement) {
        fullScreenBtn.innerHTML = `<i class="material-icons">fullscreen</i>`;
        fullScreenBtn.setAttribute('aria-label', 'Full Screen');
    }
});

sectionsBtn.addEventListener('click', (e) => {
    showThumbnails();
    
});

function showThumbnails() {
    if (thumbnailsSideView.classList.contains('hideThumbNails')) {
        thumbnailsSideView.classList.remove('hideThumbNails');
        blackOverlay.style.transform = 'translateX(calc(0vw))';
        sectionsBtn.innerHTML = `<i class="material-icons">close</i>`;
        sectionsBtn.setAttribute('aria-label', 'Hide Articles');
    } else {
        thumbnailsSideView.classList.add('hideThumbNails');
        blackOverlay.style.transform = 'translateX(calc(100vw))';
        sectionsBtn.innerHTML = `<i class="material-icons">segment</i>`;
        sectionsBtn.setAttribute('aria-label', 'Show Articles');
    }
}




