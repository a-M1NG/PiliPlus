# AI Summary Settings Implementation

## Overview
This document describes the implementation of enhanced AI summary settings for the PiliPlus application.

## Changes Made

### 1. Storage Keys (lib/utils/storage_key.dart)
Added three new storage keys for AI summary configuration:
- `aiSummaryModel`: Stores the model name (default: 'deepseek-chat')
- `aiSummaryMaxTokens`: Stores the maximum token limit (default: 4000)
- `aiSummaryExtraParams`: Stores additional API parameters as a string

### 2. Service Layer (lib/services/ai_summary_service.dart)

#### New Properties and Getters/Setters
- Added `model`, `maxTokens`, and `extraParams` properties with corresponding getters and setters
- All settings are persisted to storage automatically when set

#### Token Estimation
- Implemented `estimateTokens()` method that approximates token count
- Uses a ratio of 3 characters per token (average between English and Chinese)
- This is a simple approximation since no tokenizer library is available

#### Extra Parameters Parsing
- Implemented `parseExtraParams()` method to parse JSON-style parameter strings
- Supports formats like: `"temperature": 1, "top_p": 1, "frequency_penalty": 0`
- Automatically handles numeric values, booleans, and strings
- Flexible parsing that works with or without surrounding braces

#### Reply Truncation Logic
- Implemented `_truncateRepliesToTokenLimit()` method
- Calculates available tokens by subtracting:
  - Base prompt tokens
  - CSV header tokens
  - Response reserve (500 tokens)
- Iterates through replies and includes as many as possible without exceeding limit
- Ensures complete replies only - if reply_n fits but reply_n+1 doesn't, includes up to reply_n
- Uses CSV-escaped field values for accurate token estimation

#### API Request Updates
- `testConnection()` now uses configured model and includes extra parameters
- `summarizeReplies()` now uses configured model and includes extra parameters
- Both methods properly merge extra parameters into the request data

### 3. UI Layer (lib/pages/setting/models/extra_settings.dart)

#### Enhanced Configuration Dialog
Added new input fields to the AI API configuration dialog:
1. **Model Name** - Text input for specifying the AI model
   - Default: 'deepseek-chat'
   - Label: '模型名称'
   
2. **Max Tokens** - Number input for token limit
   - Default: 4000
   - Label: '最大Token长度'
   - Input validation: digits only
   
3. **Extra Parameters** - Multi-line text input for additional API parameters
   - Label: '额外参数'
   - Hint: `"temperature": 1, "top_p": 1, "frequency_penalty": 0`
   - Supports 3 lines of input

4. **Prompt** - Multi-line text input (expanded to 5 lines)
   - No longer obscured (was previously using obscureText)

#### Test Connection
- Updated to use `AiSummaryService.testConnection()` method
- Tests all configured parameters including model and extra params
- Provides feedback via `SmartDialog.showToast()`

## Usage Example

### Configuration
Users can configure the AI summary feature by:
1. Going to Settings → Other Settings → AI Summary API Configuration
2. Filling in:
   - API Base URL (e.g., https://api.deepseek.com/v1)
   - API Key (e.g., sk-...)
   - Model Name (e.g., deepseek-chat, gpt-4, etc.)
   - Max Tokens (e.g., 4000)
   - Extra Parameters (e.g., `"temperature": 0.7, "top_p": 0.9`)
   - Prompt (custom prompt for analysis)
3. Testing the connection to verify all parameters work correctly
4. Saving the configuration

### Extra Parameters Format
The extra parameters field accepts JSON-style key-value pairs:
```
"temperature": 1,
"top_p": 1,
"frequency_penalty": 0,
"presence_penalty": 0
```

These parameters will be merged into the API request data when making calls.

## Token Truncation Behavior

When the total token count (prompt + replies) exceeds the configured maximum:
1. The system estimates tokens for the base prompt
2. Calculates available tokens for replies (total - prompt - header - response reserve)
3. Iterates through replies in order, adding them until the limit would be exceeded
4. Returns all replies up to the last one that fits completely
5. This ensures maximum token utilization while maintaining data integrity

## Technical Notes

### Token Estimation Accuracy
- The token estimation is approximate (3 chars/token)
- Real tokenization may differ slightly depending on the model
- The 500-token response reserve provides a safety buffer
- Users should set maxTokens slightly lower than the model's actual limit if needed

### Extra Parameters
- Parameters are parsed flexibly to handle various formats
- Numeric values are automatically converted to numbers
- Boolean values ('true'/'false') are properly converted
- Invalid JSON won't crash the app - it will just be ignored

### Message Display
- All user-facing messages use `SmartDialog.showToast()` for consistency
- This includes connection tests, save confirmations, and error messages

## Files Modified
1. `lib/utils/storage_key.dart` - Added storage keys
2. `lib/services/ai_summary_service.dart` - Enhanced service with new features
3. `lib/pages/setting/models/extra_settings.dart` - Updated UI with new fields

## Backward Compatibility
- All new settings have sensible defaults
- Existing configurations will continue to work
- Missing settings will use default values automatically
