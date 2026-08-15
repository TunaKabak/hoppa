import { merchantApiFetch } from './merchant-auth';

/**
 * Converts a File object to a Base64 string in the browser
 */
export const fileToBase64 = (file: File): Promise<string> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = (error) => reject(error);
  });
};

/**
 * High-reliability media uploader for merchant web panel.
 * 1. Converts file to Base64 and performs a direct JSON POST to `/media/upload` (via merchantApiFetch).
 * 2. If direct upload fails, falls back to presigned upload flow without problematic headers.
 * 
 * @returns Public URL of the uploaded image (e.g. https://... or /uploads/...)
 */
export const uploadMerchantMedia = async (file: File): Promise<string> => {
  if (file.size > 10 * 1024 * 1024) {
    throw new Error('Görsel boyutu maksimum 10MB olmalıdır.');
  }

  const mimeType = file.type || 'image/jpeg';
  const fileName = file.name || 'upload.jpg';

  // Method 1: Ultra-reliable Base64 Direct Upload (Zero CORS / Zero S3 Presign Preflight Issues)
  try {
    const base64Data = await fileToBase64(file);
    const directRes = await merchantApiFetch('/media/upload', {
      method: 'POST',
      body: JSON.stringify({
        fileName,
        mimeType,
        contentType: mimeType,
        fileData: base64Data,
      }),
    });

    if (directRes && !directRes.error && directRes.data?.publicUrl) {
      return directRes.data.publicUrl;
    }
  } catch (directErr) {
    console.warn('[uploadMerchantMedia] Direct upload failed, trying presign fallback:', directErr);
  }

  // Method 2: Presigned URL Flow (Fallback)
  const presignRes = await merchantApiFetch('/media/upload-url', {
    method: 'POST',
    body: JSON.stringify({
      fileName,
      mimeType,
      contentType: mimeType,
      fileSize: file.size,
    }),
  });

  if (!presignRes || presignRes.error || !presignRes.data?.uploadUrl) {
    throw new Error(presignRes?.message || 'Görsel yükleme adresi alınamadı.');
  }

  const { uploadUrl, fileKey, publicUrl } = presignRes.data;

  // IMPORTANT: Do NOT send custom Authorization header to S3/R2 presigned PUT URLs to avoid CORS preflight rejection
  const uploadRes = await fetch(uploadUrl, {
    method: 'PUT',
    headers: {
      'Content-Type': mimeType,
    },
    body: file,
  });

  if (!uploadRes.ok) {
    throw new Error(`Görsel sunucuya yüklenemedi (HTTP ${uploadRes.status}).`);
  }

  return publicUrl || `/uploads/${fileKey}`;
};
