import express from 'express';

const router = express.Router();

router.get('/', async(req, res) => {
    console.log('Hit at front index');
    res.redirect('/front');
});

export default router;