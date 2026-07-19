import http from 'http';

http.get('http://localhost:3000/api/consumer/shops', (res) => {
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    try {
      const json = JSON.parse(data);
      console.log("Success! Shops count:", json.data ? json.data.length : "no data");
      if (json.data && json.data.length > 0) {
        console.log("First shop:", {
          name: json.data[0].name,
          latitude: json.data[0].latitude,
          longitude: json.data[0].longitude,
          type: json.data[0].type
        });
      }
    } catch (e) {
      console.log("Error parsing response:", e);
      console.log("Response text:", data.slice(0, 200));
    }
  });
}).on('error', (err) => {
  console.log("Server not running or error:", err.message);
});
