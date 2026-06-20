-- CreateEnum
CREATE TYPE "ShopType" AS ENUM ('RESTAURANT', 'MARKET', 'WATER', 'FLOWER', 'OTHER');

-- AlterTable
ALTER TABLE "Merchant" ADD COLUMN     "agreedToTerms" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "businessPhone" TEXT NOT NULL DEFAULT '',
ADD COLUMN     "countryCode" TEXT NOT NULL DEFAULT 'TR',
ADD COLUMN     "hasHardware" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "identityNumber" TEXT,
ADD COLUMN     "merchantType" "ShopType" NOT NULL DEFAULT 'OTHER',
ADD COLUMN     "ownerFirstName" TEXT NOT NULL DEFAULT '',
ADD COLUMN     "ownerLastName" TEXT NOT NULL DEFAULT '',
ADD COLUMN     "ownerPhone" TEXT NOT NULL DEFAULT '',
ADD COLUMN     "subType" TEXT;

-- AlterTable
ALTER TABLE "Shop" ADD COLUMN     "type" "ShopType" NOT NULL DEFAULT 'OTHER';
