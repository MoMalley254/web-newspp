-- CreateEnum
CREATE TYPE "public"."Role" AS ENUM ('ADMIN', 'EDITOR', 'VIEWER');

-- AlterTable
ALTER TABLE "public"."Admin" ADD COLUMN     "role" "public"."Role" NOT NULL DEFAULT 'EDITOR';
