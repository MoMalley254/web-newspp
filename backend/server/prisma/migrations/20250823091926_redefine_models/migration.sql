/*
  Warnings:

  - You are about to drop the `Author` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `MagazineIssues` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `_AuthorMagazines` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `_IssueTags` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `htmlPath` to the `Magazine` table without a default value. This is not possible if the table is not empty.
  - Added the required column `issueNumber` to the `Magazine` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "public"."MagazineIssues" DROP CONSTRAINT "MagazineIssues_magazineId_fkey";

-- DropForeignKey
ALTER TABLE "public"."_AuthorMagazines" DROP CONSTRAINT "_AuthorMagazines_A_fkey";

-- DropForeignKey
ALTER TABLE "public"."_AuthorMagazines" DROP CONSTRAINT "_AuthorMagazines_B_fkey";

-- DropForeignKey
ALTER TABLE "public"."_IssueTags" DROP CONSTRAINT "_IssueTags_A_fkey";

-- DropForeignKey
ALTER TABLE "public"."_IssueTags" DROP CONSTRAINT "_IssueTags_B_fkey";

-- AlterTable
ALTER TABLE "public"."Magazine" ADD COLUMN     "credits" JSONB,
ADD COLUMN     "htmlPath" TEXT NOT NULL,
ADD COLUMN     "issueNumber" INTEGER NOT NULL,
ADD COLUMN     "publishDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- DropTable
DROP TABLE "public"."Author";

-- DropTable
DROP TABLE "public"."MagazineIssues";

-- DropTable
DROP TABLE "public"."_AuthorMagazines";

-- DropTable
DROP TABLE "public"."_IssueTags";
