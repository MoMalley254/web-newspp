-- AlterTable
ALTER TABLE "public"."Magazine" ADD COLUMN     "hasToc" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "public"."TableOfContents" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "subTitle" TEXT,
    "pages" TEXT NOT NULL,
    "magazineId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TableOfContents_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "public"."TableOfContents" ADD CONSTRAINT "TableOfContents_magazineId_fkey" FOREIGN KEY ("magazineId") REFERENCES "public"."Magazine"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
