import dotenv from "dotenv";
dotenv.config();

import { PutObjectCommand } from "@aws-sdk/client-s3";
import { s3Client, R2_BUCKET_NAME, PUBLIC_CDN_URL } from "../src/config/r2.config";

async function test() {
  const url = "https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80&w=800";
  console.log("Fetching url:", url);
  try {
    const res = await fetch(url);
    console.log("Res ok:", res.ok, "status:", res.status);
    if (res.ok) {
      const arrayBuf = await res.arrayBuffer();
      const buf = Buffer.from(arrayBuf);
      console.log("Buffer size:", buf.length);
      const command = new PutObjectCommand({
        Bucket: R2_BUCKET_NAME,
        Key: "catalog/test_image.jpg",
        Body: buf,
        ContentType: "image/jpeg",
      });
      const uploadRes = await s3Client.send(command);
      console.log("Upload res:", uploadRes);
      console.log("Public URL:", `${PUBLIC_CDN_URL}/catalog/test_image.jpg`);
    }
  } catch (err: any) {
    console.error("Fetch error:", err);
  }
}
test();
