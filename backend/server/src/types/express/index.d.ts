import { JwtPayload } from "../admin/adminTypes";

declare global {
    namespace Express {
        interface Request {
            user?: JwtPayload
        }
    }
}