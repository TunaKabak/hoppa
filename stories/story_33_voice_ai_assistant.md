# Story #33: Voice AI Assistant (Hoppa Sesli Asistan)

## 1. Description & Context
This story introduces **Hoppa Sesli Asistan** (Voice AI Assistant), triggered by long-pressing the main Hoppa logo button in the bottom navigation bar. It enables consumers to interact with the application using natural Turkish voice commands.

The assistant will allow users to:
1. Search for products globally or within a shop.
2. Add products to the shopping cart.
3. Remove products from the cart.
4. Clear the cart.
5. Navigate to specific screens (Home, Search, Cart, Profile, Active Orders, Support Chat).
6. Proceed to Checkout.
7. Place/Confirm orders.

## 2. Architecture & Flow

### Backend
- **Endpoint**: `POST /api/consumer/support/voice-command`
- **Controller**: `SupportController.parseVoiceCommand`
- **Model**: Gemini 2.5 Flash
- **Logic**: Gemini is given system instructions to act as a structured function caller/parser. It translates free-text Turkish commands into a structured JSON payload:
  ```json
  {
    "action": "ADD_TO_CART" | "REMOVE_FROM_CART" | "CLEAR_CART" | "SEARCH_PRODUCT" | "NAVIGATE" | "CHECKOUT" | "CONFIRM_ORDER" | "UNKNOWN",
    "parameters": {
      "productName": "süt",
      "quantity": 2,
      "query": "lahmacun",
      "target": "cart"
    },
    "reply": "Kıbrıslı samimiyetiyle sesli geri bildirim metni."
  }
  ```

### Frontend (Flutter)
1. **Trigger**: Long-press on `AnimatedHoppaButton`.
2. **UI Overlay**: A modern semi-transparent fullscreen/bottom-sheet modal containing:
   - Wave animation or pulsing microphone showing voice activity.
   - Real-time text output of the recognized speech.
   - Assistant's spoken text feedback.
3. **Speech-to-Text**: Integrates the existing `speech_to_text` package to listen to user voice commands.
4. **Action Executer**: Processes the action JSON returned from the backend:
   - **ADD_TO_CART**: If a shop is active, searches the shop's product list for matches and adds to the cart. If no shop is active, guides the user.
   - **REMOVE_FROM_CART**: Finds the matching item in the current cart and decrements/removes it.
   - **CLEAR_CART**: Empties the cart.
   - **SEARCH_PRODUCT**: Navigates to SearchPage and applies the search filter.
   - **NAVIGATE**: Moves to selected tabs or pushes specific route pages.
   - **CHECKOUT**: Navigates to the checkout page.

---

## 3. Verification Plan
- **Backend Tests**: Verify that Gemini parses commands (e.g. "sepetimi boşalt", "bana 2 tane ekmek ekle", "arama kısmında lahmacun ara") into correct actions.
- **Frontend Integration**: Long-press the logo, speak commands, and verify visual cart updates and navigation switches.
