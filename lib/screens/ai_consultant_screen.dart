import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../managers/user_manager.dart';

class AiConsultantScreen extends StatefulWidget {
  const AiConsultantScreen({super.key});

  @override
  State<AiConsultantScreen> createState() => _AiConsultantScreenState();
}

class _AiConsultantScreenState extends State<AiConsultantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  String? _lastTopic; // Context tracking

  final List<String> _suggestions = [
    'Hair Fall Problem',
    'Pet ki samasya',
    'Weight Loss Tips',
    'Skin Glow',
    'Order kab aayega?',
    'Ashwagandha benefits',
    'Stress management'
  ];

  @override
  void initState() {
    super.initState();
    _addInitialGreeting();
  }

  void _addInitialGreeting() {
    final String name = UserManager().userName?.split(' ')[0] ?? 'Friend';
    _messages.add({
      'text': 'Namaste $name! 🙏 Main Kosmico AI Consultant hoon. Main aapki wellness journey mein kaise madad kar sakta hoon? (How can I help you today?)',
      'isMe': false,
      'time': DateTime.now(),
    });
  }

  void _sendMessage([String? text]) {
    final messageText = text ?? _controller.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _messages.add({
        'text': messageText,
        'isMe': true,
        'time': DateTime.now(),
      });
      _isTyping = true;
    });
    
    if (text == null) _controller.clear();
    _scrollToBottom();

    // Simulate AI delay and response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'text': _getAiResponse(messageText),
            'isMe': false,
            'time': DateTime.now(),
          });
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Because ListView is reversed
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getAiResponse(String message) {
    message = message.toLowerCase();
    
    // 1. Digestion & Stomach Issues (Pet ki samasya)
    if (message.contains('pet') || message.contains('stomach') || message.contains('pait') || 
        message.contains('digestion') || message.contains('gas') || message.contains('acidity') || 
        message.contains('constipation') || message.contains('kabz') || message.contains('pachan')) {
      return 'Pet ki samasyaon (Digestion) ke liye hamara "Digestion Care" range best hai. Acidity aur gas ke liye hamara Triphala Churan ya Liver Care Syrup try karein. Ye natural tarike se pet saaf rakhta hai aur bhukh badhata hai.';
    }

    // 2. Hair Care (Baalo ki dekhbhal)
    if (message.contains('hair') || message.contains('baal') || message.contains('bal') || 
        message.contains('kesh') || message.contains('oil') || message.contains('jhadna') || 
        message.contains('dandruff') || message.contains('fall')) {
      return 'Baalo ke jhadne (Hair fall) ya dandruff ke liye hamara Ayurvedic Hair Oil aur Onion Shampoo kaafi effective hai. Isme Bhringraj aur Amla hai jo jadon ko mazboot banata hai. Kya aapko dandruff ki bhi samasya hai?';
    }

    // 3. Skin, Face & Glow
    if (message.contains('skin') || message.contains('twacha') || message.contains('chehra') || 
        message.contains('glow') || message.contains('face') || message.contains('pimple') || 
        message.contains('daag') || message.contains('dark spot')) {
      return 'Skin glow ke liye hamara Kumkumadi Tailam aur Vitamin C Face Serum recommend kiye jaate hain. Ye pimples aur dark spots kam karne mein madad karte hain. Hamare products 100% chemical-free hain.';
    }

    // 4. Joint & Muscle Pain (Dard)
    if (message.contains('dard') || message.contains('pain') || message.contains('joint') || 
        message.contains('ghutna') || message.contains('back') || message.contains('peeth') || message.contains('muscle')) {
      return 'Joint ya muscle pain ke liye hamara "Orthovedic Oil" bahut prabhavi hai. Ye ghutno aur peeth ke dard mein turant rahat deta hai. Kya aapko dard purana hai ya chot lagi hai?';
    }

    // 5. Energy, Stress, Sleep & Vitality
    if (message.contains('neend') || message.contains('sleep') || message.contains('stress') || 
        message.contains('tension') || message.contains('thakavat') || message.contains('energy') || 
        message.contains('kamzori') || message.contains('stamina') || message.contains('vigour') || message.contains('ashwagandha')) {
      return 'Ashwagandha aur Shilajit Gold capsules stress kam karne aur stamina badhane mein bahut madadgar hain. Ye energy level sudharte hain aur acchi neend lane mein madad karte hain. Hamara Ashwagandha 100% organic hai.';
    }

    // 6. Immunity & Seasonal Health (Sardi-Khansi)
    if (message.contains('sardi') || message.contains('cold') || message.contains('khansi') || 
        message.contains('cough') || message.contains('immunity') || message.contains('bukhaar') || 
        message.contains('fever') || message.contains('gala')) {
      return 'Immunity badhane ke liye hamara Giloy juice aur Tulsi drops lijiye. Agar gala kharab hai ya khansi hai toh hamara Ayurvedic Cough Syrup (Honey-based) turant rahat dega.';
    }

    // 7. Diabetes & Sugar Management
    if (message.contains('sugar') || message.contains('diabetes') || message.contains('madhumeh') || message.contains('meetha')) {
      return 'Sugar control karne ke liye hamara "DiabeCare" juice aur capsules hain. Isme Jamun, Karela aur Gurmar ke extracts hain jo natural tarike se glucose level maintain karte hain.';
    }

    // 8. Weight Management (Vajan)
    if (message.contains('weight') || message.contains('vajan') || message.contains('fat') || 
        message.contains('motapa') || message.contains('lose') || message.contains('slim')) {
      return 'Vajan ghatane ke liye hamara "Slim Detox" powder aur Apple Cider Vinegar (ACV) kaafi asardaar hai. Ye metabolism badhata hai. Kya aap morning walk ya yoga karte hain?';
    }

    // 9. Detox & Liver Health
    if (message.contains('liver') || message.contains('detox') || message.contains('sharab') || message.contains('pait saaf')) {
      return 'Liver detox ke liye hamara "Livo-Clean" syrup sabse accha hai. Ye liver function ko improve karta hai aur toxins ko sharir se bahar nikalta hai.';
    }

    // 10. Pricing, Offers & Discount
    if (message.contains('price') || message.contains('keemat') || message.contains('daam') || 
        message.contains('cost') || message.contains('sasta')) {
      return 'Hamare products ki keemat (price) unki quantity aur type par depend karti hai. Aap "Products" tab mein jaakar sabhi items ke rate aur current offers dekh sakte hain. Kya aap kisi specific product ka price jaanna chahte hain?';
    }

    // 11. Order, Tracking & Delivery
    if (message.contains('order') || message.contains('track') || message.contains('saman') || 
        message.contains('delivered') || message.contains('kab aayega') || message.contains('ship') || 
        message.contains('status') || message.contains('pohnchega')) {
      return 'Aap apna order "Profile" > "My Orders" par jaakar live track kar sakte hain. Order dispatch hone ke baad saadharan taur par 3-5 business days mein mil jata hai.';
    }

    // 12. Offers & Coupons
    if (message.contains('offer') || message.contains('discount') || message.contains('coupon') || message.contains('chooth')) {
      return 'Ji haan! Hum aksar naye offers nikaalte rehte hain. Aap "Profile" mein "Coupons" section check karein, wahan aapko extra discount mil sakta hai.';
    }

    // 13. About Kosmico Wellness
    if (message.contains('kosmico') || message.contains('company') || message.contains('brand') || message.contains('kya hai')) {
      return 'Kosmico Wellness ek premium Ayurvedic brand hai jo ancient wisdom aur modern science ko mila kar 100% natural products banata hai. Hamara maksad har ghar tak shuddh ayurveda pahunchana hai.';
    }

    // 13. Greetings (Universal)
    final List<String> greetings = ['hello', 'namaste', 'namaskar', 'hey', 'kaise ho', 'good morning', 'hi', 'hola'];
    if (greetings.any((g) => message.contains(g)) || RegExp(r'\bhi\b').hasMatch(message)) {
      return 'Namaste! Main Kosmico AI Consultant hoon. Main aapki health, products aur orders se jude har sawal ka jawab de sakta hoon. Bataiye, aaj main aapki kya seva kar sakta hoon?';
    }

    // Default Fallback (Smart)
    return 'Main aapki baat puri tarah samajh nahi paaya. Kya aap is baare mein thoda sa aur vistaar (detail) se batayenge? Taki main aapko sahi jaankari de sakoon.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('AI Consultant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Online', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addInitialGreeting();
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF1A1A1A), const Color(0xFF2C2C2C)]
              : [
                  colorScheme.primary.withValues(alpha: 0.08),
                  colorScheme.surface,
                  colorScheme.secondary.withValues(alpha: 0.05),
                ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: true, // Show latest messages at bottom
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[_messages.length - 1 - index];
                    return _buildMessageBubble(msg, colorScheme);
                  },
                ),
              ),
              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 30, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text('Kosmico AI is thinking...', style: TextStyle(fontSize: 12, color: colorScheme.primary, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              _buildSuggestions(colorScheme),
              _buildInputArea(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions(ColorScheme colorScheme) {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(_suggestions[index], style: const TextStyle(fontSize: 12)),
              backgroundColor: colorScheme.surface.withValues(alpha: 0.7),
              onPressed: () => _sendMessage(_suggestions[index]),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.1)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, ColorScheme colorScheme) {
    final bool isMe = msg['isMe'];
    final timeStr = DateFormat('hh:mm a').format(msg['time']);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.assistant, size: 16, color: colorScheme.primary),
                ),
              if (!isMe) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? colorScheme.primary : colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg['text'],
                    style: TextStyle(
                      color: isMe ? Colors.white : colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 8),
              if (isMe)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.secondary.withValues(alpha: 0.1),
                  child: Icon(Icons.person, size: 16, color: colorScheme.secondary),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
            child: Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type your wellness query...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(),
            child: CircleAvatar(
              backgroundColor: colorScheme.primary,
              radius: 24,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
