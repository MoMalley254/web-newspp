import express, { Request, Response } from 'express';
import adminRoutes from './routes/adminRoutes';
import frontendRoutes from './routes/frontendRoutes';
import dataRoutes from './routes/dataRoute';
import path from 'path';

const app = express();
app.use(express.json());
// Set the view engine to EJS
app.set('view engine', 'ejs');

// Optional: Set the directory for EJS templates
app.set('views', path.join(__dirname, 'views'));
// Serve files from the "public" folder
// app.use(express.static(path.join(__dirname, 'public')));
app.use('/admin/mag/public', express.static(path.join(__dirname, '..', 'public')));
app.use('/front/public', express.static(path.join(__dirname, '..', 'public')));
app.use('/front/view/public', express.static(path.join(__dirname, '..', 'public')));
app.use('/front/tag/public', express.static(path.join(__dirname, '..', 'public')));
app.use('/front/about/public', express.static(path.join(__dirname, '..', 'public')));

app.get('/', async (req: Request, res: Response) => {
    res.redirect('/front');
});

app.use('/front', frontendRoutes);
app.use('/admin', adminRoutes);
app.use('/data', dataRoutes);

const PORT = process.env.PORT || 3005;
app.listen(PORT, () => {
    console.log(`App running @ http://localhost:${PORT}`);
});
