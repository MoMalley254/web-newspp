import express, { Request, Response } from 'express';
import adminRoutes from './routes/adminRoutes';
import frontendRoutes from './routes/frontendRoutes';
import path from 'path';

const app = express();
app.use(express.json());
// Serve files from the "public" folder
app.use('/admin/mag/public', express.static(path.join(__dirname, '..', 'public')));

app.get('/', async (req: Request, res: Response) => {
    res.redirect('/front');
});

app.use('/front', frontendRoutes);
app.use('/admin', adminRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`App running @ http://localhost:${PORT}`);
});
