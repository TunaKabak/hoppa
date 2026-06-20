-- CreateTable
CREATE TABLE "GlobalProduct" (
    "id" TEXT NOT NULL,
    "barcode" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "brand" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "subCategory" TEXT,
    "imageUrl" TEXT NOT NULL,
    "isWeighted" BOOLEAN NOT NULL DEFAULT false,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "GlobalProduct_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "GlobalProduct_barcode_key" ON "GlobalProduct"("barcode");

-- CreateIndex
CREATE INDEX "GlobalProduct_name_idx" ON "GlobalProduct"("name");
