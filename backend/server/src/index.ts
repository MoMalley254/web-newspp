import express, { Request, Response } from 'express';
import adminRoutes from './routes/adminRoutes';
import frontendRoutes from './routes/frontendRoutes';

const app = express();
app.use(express.json());

app.get('/', async (req: Request, res: Response) => {
    res.redirect('/front');
});

app.use('/front', frontendRoutes);
app.use('/admin', adminRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`App running @ http://localhost:${PORT}`);
});
