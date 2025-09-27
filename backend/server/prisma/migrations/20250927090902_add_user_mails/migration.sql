-- CreateTable
CREATE TABLE "public"."userMails" (
    "id" TEXT NOT NULL,
    "userMail" TEXT NOT NULL,

    CONSTRAINT "userMails_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "userMails_userMail_key" ON "public"."userMails"("userMail");
