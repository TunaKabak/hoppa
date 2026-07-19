import http from 'http';

const url = 'http://localhost:3000/api/consumer/shops?latitude=35.19746961129782&longitude=33.88196422919508';
http.get(url, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    try {
      const json = JSON.parse(data);
      console.log("=== API FILTER RESULT ===");
      console.log("Count:", json.data ? json.data.length : 0);
      for (const shop of json.data || []) {
        console.log({
          id: shop.id,
          name: shop.name,
          businessName: shop.merchant?.businessName,
          type: shop.type,
          latitude: shop.latitude,
          longitude: shop.longitude,
          deliveryRadiusKm: shop.deliveryRadiusKm
        });
      }
    } catch (e) {
      console.log("Parse error:", e);
    }
  });
});
