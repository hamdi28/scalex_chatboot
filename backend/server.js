// ScaleX Chatbot Backend API
// Node.js + Express + AI APIs

const express = require('express');
const cors = require('cors');
const axios = require('axios');

// Load .env with graceful fallback
let dotenvLoaded = false;
try {
  require('dotenv').config();
  dotenvLoaded = true;
} catch (error) {
  console.warn('⚠️  .env file not found or invalid. Using defaults/mocks. Add API keys for full functionality.');
}

// Validate required env vars
if (dotenvLoaded) {
  if (!process.env.OPENAI_API_KEY) console.warn('⚠️  OPENAI_API_KEY missing. OpenAI calls will fail.');
  if (!process.env.ANTHROPIC_API_KEY) console.warn('⚠️  ANTHROPIC_API_KEY missing. Claude calls will fail.');
  if (!process.env.GROQ_API_KEY) console.warn('⚠️  GROQ_API_KEY missing. Groq calls will fail.');
}

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb', strict: false })); // More lenient JSON parsing for dev

// Global error handler for JSON parse errors
app.use((error, req, res, next) => {
  if (error instanceof SyntaxError && error.status === 400 && 'body' in error) {
    return res.status(400).json({ error: 'Invalid JSON in request body. Check your formatting.' });
  }
  next(error);
});

// In-memory storage (replace with database in production)
const users = new Map();
const chatHistories = new Map();

// ============== ROOT & HEALTH CHECK ==============
app.get('/api', (req, res) => {
  res.json({
    status: 'ScaleX Chatbot API',
    version: '1.0.0',
    message: 'Welcome! Use the endpoints below.',
    endpoints: [
      'GET /api/health – Server status',
      'POST /api/auth/signup – Create user',
      'POST /api/auth/login – Authenticate user',
      'POST /api/chat – Send message to AI',
      'GET /api/history/:email – Fetch chat history',
      'POST /api/history – Save chat message',
      'POST /api/summary – Generate AI summary',
      'POST /api/translate – Translate text'
    ]
  });
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'ScaleX Chatbot API is running',
    timestamp: new Date().toISOString(),
    models: {
      groq: process.env.GROQ_API_KEY ? 'Available' : 'Not configured',
      openai: process.env.OPENAI_API_KEY ? 'Available' : 'Not configured',
      anthropic: process.env.ANTHROPIC_API_KEY ? 'Available' : 'Not configured'
    }
  });
});

// ============== AUTH ENDPOINTS ==============

// Helper: Validate email/password
function validateAuthInput(email, password) {
  if (!email || !password) return { valid: false, error: 'Email and password required' };
  if (typeof email !== 'string' || typeof password !== 'string') return { valid: false, error: 'Email and password must be strings' };
  if (!email.includes('@')) return { valid: false, error: 'Invalid email format' };
  if (password.length < 6) return { valid: false, error: 'Password must be at least 6 characters' };
  return { valid: true };
}

// Sign Up
app.post('/api/auth/signup', async (req, res) => {
  try {
    console.log(`📝 Signup attempt for: ${req.body.email}`);
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const validation = validateAuthInput(email, password);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }

    if (users.has(email)) {
      return res.status(400).json({ error: 'User already exists' });
    }

    users.set(email, {
      email,
      password,
      createdAt: new Date().toISOString(),
      lastLogin: null
    });
    chatHistories.set(email, []);

    console.log(`✅ New user created: ${email}`);
    res.status(201).json({
      success: true,
      message: 'User created successfully',
      user: { email, createdAt: new Date().toISOString() }
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    console.log(`🔑 Login attempt for: ${req.body.email}`);
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const validation = validateAuthInput(email, password);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }

    const user = users.get(email);
    if (!user || user.password !== password) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Update last login
    user.lastLogin = new Date().toISOString();
    users.set(email, user);

    console.log(`✅ Login successful for: ${email}`);
    res.json({
      success: true,
      message: 'Login successful',
      user: {
        email,
        lastLogin: user.lastLogin
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============== CHAT ENDPOINTS ==============

// Send message to AI
app.post('/api/chat', async (req, res) => {
  try {
    console.log(`💬 Chat request for model: ${req.body.model || 'gpt'}`);
    const { message, model = 'groq', language = 'en', email } = req.body;

    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'Message is required and must be a string' });
    }

    if (message.trim().length === 0) {
      return res.status(400).json({ error: 'Message cannot be empty' });
    }

    let aiResponse;
    const startTime = Date.now();

    switch (model.toLowerCase()) {
      case 'gpt':
        aiResponse = await callOpenAI(message, language);
        break;
      case 'claude':
        aiResponse = await callClaude(message, language);
        break;
      case 'grok':
        aiResponse = await callGrok(message, language);
        break;
      case 'groq':
        aiResponse = await callGroq(message, language);
        break;
      default:
        aiResponse = await callGroq(message, language); // Default to Groq
    }

    const responseTime = Date.now() - startTime;

    // Save to history if email provided
    if (email && users.has(email)) {
      if (!chatHistories.has(email)) {
        chatHistories.set(email, []);
      }

      const historyEntry = {
        userMessage: message,
        aiResponse: aiResponse,
        model: model,
        language: language,
        timestamp: new Date().toISOString(),
        responseTime: responseTime
      };

      chatHistories.get(email).push(historyEntry);
    }

    res.json({
      message: aiResponse,
      model,
      language,
      timestamp: new Date().toISOString(),
      responseTime: `${responseTime}ms`
    });
  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({
      error: 'Failed to get AI response',
      details: process.env.NODE_ENV === 'development' ? error.message : 'Try again later.'
    });
  }
});

// Get chat history
app.get('/api/history/:email', (req, res) => {
  try {
    const { email } = req.params;
    console.log(`📚 Fetching history for: ${email}`);

    if (!users.has(email)) {
      return res.status(404).json({ error: 'User not found' });
    }

    const history = chatHistories.get(email) || [];

    res.json({
      history,
      count: history.length,
      user: email
    });
  } catch (error) {
    console.error('History fetch error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Save chat message
app.post('/api/history', (req, res) => {
  try {
    const { email, userMessage, aiResponse, model = 'groq', language = 'en' } = req.body;

    if (!email || !userMessage || !aiResponse) {
      return res.status(400).json({ error: 'Email, userMessage, and aiResponse are required' });
    }

    if (!users.has(email)) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (!chatHistories.has(email)) {
      chatHistories.set(email, []);
    }

    const historyEntry = {
      userMessage,
      aiResponse,
      model,
      language,
      savedAt: new Date().toISOString()
    };

    chatHistories.get(email).push(historyEntry);

    console.log(`💾 Saved message for: ${email}`);
    res.json({
      success: true,
      message: 'Chat history saved',
      entry: historyEntry
    });
  } catch (error) {
    console.error('History save error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get user summary (AI-generated)
app.post('/api/summary', async (req, res) => {
  try {
    const { email, messages } = req.body;

    if (!email && !messages) {
      return res.status(400).json({ error: 'Either email or messages array is required' });
    }

    let chatMessages = messages;

    // If email provided, get messages from history
    if (email && !messages) {
      if (!users.has(email)) {
        return res.status(404).json({ error: 'User not found' });
      }
      const history = chatHistories.get(email) || [];
      chatMessages = history.map(entry => `${entry.userMessage} -> ${entry.aiResponse}`);
    }

    if (!chatMessages || !Array.isArray(chatMessages) || chatMessages.length === 0) {
      return res.json({
        summary: 'No chat history available yet.',
        messageCount: 0
      });
    }

    // Generate summary using AI (prefer Groq for speed)
    const recentMessages = chatMessages.slice(-20).map(m => typeof m === 'string' ? m : JSON.stringify(m)).join('\n');
    const summaryPrompt = `Analyze these user messages and provide a brief, friendly summary of their interests and common topics in 2-3 sentences. Be concise and insightful.\n\nMessages:\n${recentMessages}`;

    let summary;
    try {
      summary = await callGroq(summaryPrompt, 'en');
    } catch (error) {
      // Fallback to OpenAI if Groq fails
      summary = await callOpenAI(summaryPrompt, 'en');
    }

    res.json({
      summary,
      messageCount: chatMessages.length,
      generatedAt: new Date().toISOString(),
      model: 'groq' // or whichever was used
    });
  } catch (error) {
    console.error('Summary error:', error);
    res.status(500).json({ error: 'Failed to generate summary' });
  }
});

// ============== AI MODEL FUNCTIONS ==============

async function callOpenAI(message, language) {
  if (!process.env.OPENAI_API_KEY) {
    return getMockResponse(message, language, 'OpenAI not configured');
  }

  try {
    const systemPrompt = language === 'ar'
      ? 'You are a helpful assistant. Respond in Arabic with clear, proper language.'
      : 'You are a helpful assistant. Provide clear, concise responses.';

    const response = await axios.post(
      'https://api.openai.com/v1/chat/completions',
      {
        model: 'gpt-3.5-turbo',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: message }
        ],
        max_tokens: 500,
        temperature: 0.7
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
          'Content-Type': 'application/json'
        },
        timeout: 30000
      }
    );

    return response.data.choices[0].message.content.trim();
  } catch (error) {
    console.error('OpenAI API Error:', error.response?.data || error.message);
    throw new Error(`OpenAI: ${error.response?.data?.error?.message || error.message}`);
  }
}

async function callClaude(message, language) {
  if (!process.env.ANTHROPIC_API_KEY) {
    return getMockResponse(message, language, 'Claude not configured');
  }

  try {
    const systemPrompt = language === 'ar'
      ? 'You are a helpful assistant. Respond in Arabic with clear, proper language.'
      : 'You are a helpful assistant. Provide clear, concise responses.';

    const response = await axios.post(
      'https://api.anthropic.com/v1/messages',
      {
        model: 'claude-3-haiku-20240307', // Using cheaper model for demo
        max_tokens: 500,
        system: systemPrompt,
        messages: [{ role: 'user', content: message }]
      },
      {
        headers: {
          'x-api-key': process.env.ANTHROPIC_API_KEY,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json'
        },
        timeout: 30000
      }
    );

    return response.data.content[0].text.trim();
  } catch (error) {
    console.error('Claude API Error:', error.response?.data || error.message);
    throw new Error(`Claude: ${error.response?.data?.error?.message || error.message}`);
  }
}

async function callGrok(message, language) {
  // Mock (real xAI API TBA)
  return getMockResponse(message, language, 'Grok API not yet available');
}

async function callGroq(message, language) {
  if (!process.env.GROQ_API_KEY) {
    return getMockResponse(message, language, 'Groq not configured');
  }

  try {
    const systemPrompt = language === 'ar'
      ? 'You are a helpful assistant. Respond in Arabic with clear, proper language. Keep responses concise and helpful.'
      : 'You are a helpful assistant. Provide clear, concise, and helpful responses.';

    const response = await axios.post(
      'https://api.groq.com/openai/v1/chat/completions',
      {
        model: 'llama-3.1-8b-instant', // Fast and free-tier friendly
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: message }
        ],
        max_tokens: 1024, // Groq allows more tokens
        temperature: 0.7,
        stream: false
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.GROQ_API_KEY}`,
          'Content-Type': 'application/json'
        },
        timeout: 30000 // 30 second timeout
      }
    );

    if (!response.data.choices || !response.data.choices[0]) {
      throw new Error('Invalid response format from Groq API');
    }

    return response.data.choices[0].message.content.trim();
  } catch (error) {
    console.error('Groq API Error:', error.response?.data || error.message);

    // Provide more specific error messages
    if (error.response?.status === 401) {
      throw new Error('Groq: Invalid API key');
    } else if (error.response?.status === 429) {
      throw new Error('Groq: Rate limit exceeded');
    } else if (error.code === 'ECONNABORTED') {
      throw new Error('Groq: Request timeout');
    } else {
      throw new Error(`Groq: ${error.response?.data?.error?.message || error.message}`);
    }
  }
}

// Helper: Friendly mock responses
function getMockResponse(message, language, reason) {
  const baseMock = `[Mock AI - ${reason}] I understand you said: "${message.substring(0, 100)}${message.length > 100 ? '...' : ''}". Configure API keys for real AI responses! ✨`;

  if (language === 'ar') {
    return `[رد تجريبي - ${reason}] لقد فهمت أنك قلت: "${message.substring(0, 100)}${message.length > 100 ? '...' : ''}". قم بإعداد مفاتيح API للحصول على ردود الذكاء الاصطناعي الحقيقية! ✨`;
  }

  return baseMock;
}

// ============== TRANSLATION ENDPOINT ==============

app.post('/api/translate', async (req, res) => {
  try {
    const { text, from = 'auto', to = 'ar' } = req.body;

    if (!text || typeof text !== 'string') {
      return res.status(400).json({ error: 'Text is required and must be a string' });
    }

    if (text.trim().length === 0) {
      return res.status(400).json({ error: 'Text cannot be empty' });
    }

    // Use Groq for translation if available
    let translated;
    try {
      const translationPrompt = `Translate the following text from ${from} to ${to}. Only provide the translation, no additional text:\n\n"${text}"`;
      translated = await callGroq(translationPrompt, to);
    } catch (error) {
      // Fallback to mock translation
      translated = `[Translation: ${from} → ${to}] ${text}`;
    }

    console.log(`🌐 Translation: ${from} → ${to}`);
    res.json({
      original: text,
      translated_text: translated,
      from,
      to,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Translate error:', error);
    res.status(500).json({ error: 'Translation service unavailable' });
  }
});

// ============== ADDITIONAL UTILITY ENDPOINTS ==============

// Clear user history (for testing)
app.delete('/api/history/:email', (req, res) => {
  try {
    const { email } = req.params;

    if (!users.has(email)) {
      return res.status(404).json({ error: 'User not found' });
    }

    chatHistories.set(email, []);
    console.log(`🗑️  Cleared history for: ${email}`);

    res.json({
      success: true,
      message: 'Chat history cleared'
    });
  } catch (error) {
    console.error('Clear history error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get available models
app.get('/api/models', (req, res) => {
  res.json({
    available_models: [
      { id: 'groq', name: 'Groq (Llama 3.1)', status: process.env.GROQ_API_KEY ? 'available' : 'not configured' },
      { id: 'gpt', name: 'OpenAI GPT-3.5', status: process.env.OPENAI_API_KEY ? 'available' : 'not configured' },
      { id: 'claude', name: 'Claude Haiku', status: process.env.ANTHROPIC_API_KEY ? 'available' : 'not configured' },
      { id: 'grok', name: 'Grok', status: 'coming soon' }
    ],
    default: 'groq'
  });
});

// Global error handler (catch-all)
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Something went wrong!',
    details: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    message: `Route ${req.originalUrl} does not exist. Check /api for available endpoints.`
  });
});

// ============== START SERVER ==============

app.listen(PORT, () => {
  console.log(`\n🚀 ScaleX Chatbot API running on port ${PORT}`);
  console.log(`📍 Base URL: http://localhost:${PORT}/api`);
  console.log(`   Visit /api for endpoint list`);
  console.log(`\n⚠️  API Keys: ${dotenvLoaded ? 'Loaded ✅' : 'Missing – mocks active'}`);
  console.log(`   Groq API: ${process.env.GROQ_API_KEY ? 'Configured ✅' : 'Missing ❌'}`);
  console.log(`\n🔧 Ready for testing! Use curl/Postman.\n`);
});