-- CreateTable
CREATE TABLE "public"."MagzineReadingSession" (
    "id" TEXT NOT NULL,
    "fingerprint" TEXT NOT NULL,
    "location" TEXT,
    "deviceType" TEXT NOT NULL,
    "language" TEXT NOT NULL,
    "magazineId" TEXT NOT NULL,
    "startedAt" TIMESTAMP(3) NOT NULL,
    "endedAt" TIMESTAMP(3),
    "completed" BOOLEAN NOT NULL DEFAULT false,
    "pages" JSONB NOT NULL,

    CONSTRAINT "MagzineReadingSession_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "MagzineReadingSession_fingerprint_idx" ON "public"."MagzineReadingSession"("fingerprint");

-- CreateIndex
CREATE INDEX "MagzineReadingSession_magazineId_idx" ON "public"."MagzineReadingSession"("magazineId");
