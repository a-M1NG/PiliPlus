# AI Summary Settings - Manual Testing Guide

## Overview
This guide provides step-by-step instructions for manually testing the new AI Summary settings functionality.

## Prerequisites
- PiliPlus app installed and running
- Valid OpenAI-compatible API credentials (e.g., DeepSeek API key)
- Access to B站 video with comments

## Test Cases

### 1. Configuration UI Test

#### Test 1.1: Access Settings
1. Open PiliPlus app
2. Navigate to: Settings → Other Settings
3. Scroll to find "AI总结API配置"
4. Verify subtitle shows: "配置OpenAI兼容API（如DeepSeek、OpenAI等）用于评论总结"
5. Tap on "AI总结API配置"

**Expected:** Dialog opens with all input fields visible

#### Test 1.2: Verify All Input Fields Present
Check that the dialog contains:
- [ ] API Base URL field (default: https://api.deepseek.com/v1)
- [ ] API Key field (obscured text)
- [ ] 模型名称 field (default: deepseek-chat)
- [ ] 最大Token长度 field (default: 4000)
- [ ] 额外参数 field (multi-line, 3 lines)
- [ ] Prompt field (multi-line, 5 lines)
- [ ] 测试连接 button
- [ ] 取消 button
- [ ] 保存 button

**Expected:** All fields are present and properly labeled

### 2. Model Name Configuration Test

#### Test 2.1: Default Model
1. Open AI API configuration dialog
2. Check the 模型名称 field

**Expected:** Default value is "deepseek-chat"

#### Test 2.2: Change Model Name
1. Clear the 模型名称 field
2. Enter "gpt-4" (or another model name)
3. Click 保存

**Expected:** Settings saved successfully, toast shows "保存成功"

### 3. Max Tokens Configuration Test

#### Test 3.1: Default Max Tokens
1. Open AI API configuration dialog
2. Check the 最大Token长度 field

**Expected:** Default value is "4000"

#### Test 3.2: Change Max Tokens
1. Clear the 最大Token长度 field
2. Enter "2000"
3. Click 保存

**Expected:** Settings saved successfully

#### Test 3.3: Invalid Input (Non-numeric)
1. Try to enter letters in 最大Token长度 field

**Expected:** Only numeric input is accepted (enforced by input filter)

### 4. Extra Parameters Configuration Test

#### Test 4.1: Valid Extra Parameters (With Braces)
1. Open AI API configuration dialog
2. In 额外参数 field, enter:
   ```json
   {"temperature": 0.7, "top_p": 0.9, "frequency_penalty": 0.5}
   ```
3. Click 保存

**Expected:** Settings saved successfully

#### Test 4.2: Valid Extra Parameters (Without Braces)
1. Open AI API configuration dialog
2. In 额外参数 field, enter:
   ```
   "temperature": 1, "top_p": 1, "frequency_penalty": 0, "presence_penalty": 0
   ```
3. Click 保存

**Expected:** Settings saved successfully (braces added automatically)

#### Test 4.3: Invalid JSON
1. Open AI API configuration dialog
2. In 额外参数 field, enter invalid JSON:
   ```
   temperature: 1, invalid json
   ```
3. Click 测试连接

**Expected:** Test still proceeds (invalid params ignored, only base config tested)

#### Test 4.4: Critical Parameters Filtered
1. Open AI API configuration dialog
2. Try to include critical parameters:
   ```
   "model": "override-model", "max_tokens": 999999, "temperature": 0.7
   ```
3. Click 测试连接 or 保存

**Expected:** model and max_tokens are filtered out, only temperature is used

### 5. Test Connection Test

#### Test 5.1: Test Without API Key
1. Open AI API configuration dialog
2. Clear the API Key field
3. Click 测试连接

**Expected:** Toast shows "请先填写完整的配置信息"

#### Test 5.2: Test With Valid Configuration
1. Fill in:
   - API Base URL: https://api.deepseek.com/v1
   - API Key: sk-... (valid key)
   - 模型名称: deepseek-chat
   - 最大Token长度: 4000
   - 额外参数: "temperature": 0.7
2. Click 测试连接

**Expected:** 
- Button shows "测试中..." with loading indicator
- After success, toast shows "连接成功"
- Button returns to "测试连接"

#### Test 5.3: Test With Invalid API Key
1. Fill in invalid API key
2. Click 测试连接

**Expected:** Toast shows "连接失败: [error details]"

#### Test 5.4: Test With Invalid Base URL
1. Fill in invalid URL (e.g., "http://invalid-url")
2. Click 测试连接

**Expected:** Toast shows "连接失败: [error details]"

### 6. Token Truncation Test

#### Test 6.1: Normal Comment Thread
1. Configure API with maxTokens: 4000
2. Find a video with moderate comments (20-30 replies)
3. Long press on a comment and select "AI总结"

**Expected:** All replies are included in the summary

#### Test 6.2: Very Long Comment Thread
1. Configure API with maxTokens: 500 (very low)
2. Find a video with many replies (50+ replies)
3. Long press on a comment and select "AI总结"

**Expected:** 
- Only first few replies are included
- Summary still completes successfully
- No incomplete replies in the middle of CSV data

#### Test 6.3: Verify Truncation Logic
To verify the truncation is working correctly:
1. Set maxTokens to a very low value (e.g., 200)
2. Try summarizing a comment with many replies
3. Check that:
   - At least the root comment (楼主) is included
   - Replies are complete (not cut off mid-reply)
   - The process doesn't fail

### 7. End-to-End Integration Test

#### Test 7.1: Complete Workflow
1. Configure all settings:
   ```
   Base URL: https://api.deepseek.com/v1
   API Key: [valid key]
   模型名称: deepseek-chat
   最大Token长度: 3000
   额外参数: "temperature": 0.8, "top_p": 0.95
   Prompt: [custom prompt]
   ```
2. Click 测试连接 to verify

**Expected:** Connection successful

3. Save settings
4. Navigate to a video with comments
5. Long press on a comment with replies
6. Select "AI总结"

**Expected:**
- Progress indicator shows at avatar
- Progress bar updates 0-90% for fetching replies
- Progress bar updates 90-100% for AI processing
- Green checkmark appears when complete
- Click checkmark to view summary
- Summary shows analysis based on custom prompt

#### Test 7.2: Different Models
Repeat Test 7.1 with different model names:
- deepseek-chat
- gpt-4
- gpt-3.5-turbo
(depending on API provider)

**Expected:** Each model works according to its capabilities

### 8. Persistence Test

#### Test 8.1: Settings Persistence
1. Configure all settings with specific values
2. Click 保存
3. Close the dialog
4. Re-open the AI API configuration dialog

**Expected:** All previously saved values are still present

#### Test 8.2: App Restart Persistence
1. Configure all settings
2. Save settings
3. Close and restart the app
4. Open AI API configuration dialog

**Expected:** All settings persist across app restarts

### 9. Error Handling Test

#### Test 9.1: Network Error During Test
1. Disable network connection
2. Click 测试连接

**Expected:** Toast shows "连接失败: [network error]"

#### Test 9.2: API Error Response
1. Configure with valid URL but wrong API key
2. Try to summarize a comment

**Expected:** Toast shows appropriate error message

### 10. UI/UX Test

#### Test 10.1: Dialog Scrolling
1. Open AI API configuration dialog
2. Try to scroll through all fields

**Expected:** Dialog scrolls smoothly, all fields are accessible

#### Test 10.2: Multi-line Input Fields
1. Enter long text in 额外参数 field (3+ lines)
2. Enter long prompt in Prompt field (5+ lines)

**Expected:** 
- Text wraps properly
- Field expands to show multiple lines
- All text is visible

#### Test 10.3: Button States
1. Click 测试连接
2. Observe button during testing

**Expected:**
- Button is disabled during test
- Shows loading indicator
- Shows "测试中..." text
- Re-enables after test completes

### 11. Backward Compatibility Test

#### Test 11.1: Upgrade from Previous Version
If testing on an installation that had the old version:
1. Open AI API configuration

**Expected:**
- Old settings (baseUrl, apiKey, prompt) are preserved
- New settings show default values
- No errors or crashes

### 12. SmartDialog Toast Test

#### Test 12.1: All Messages Use SmartDialog
Verify that all user-facing messages use SmartDialog.showToast:
- [ ] "请先填写完整的配置信息"
- [ ] "连接成功"
- [ ] "连接失败: ..."
- [ ] "保存成功"
- [ ] "请先在设置中配置AI API"
- [ ] "正在总结中..."
- [ ] "已取消"
- [ ] "总结完成"
- [ ] "总结失败: ..."

**Expected:** All messages appear as toast notifications

## Common Issues and Resolutions

### Issue 1: Test Connection Always Fails
**Possible Causes:**
- Invalid API key format
- Incorrect base URL
- Network connectivity issues
- API rate limiting

**Resolution:**
- Verify API key starts with "sk-"
- Check base URL format (should end with /v1)
- Test network connectivity
- Wait and retry if rate limited

### Issue 2: Summary Truncated Too Much
**Possible Causes:**
- maxTokens set too low
- Very long prompt

**Resolution:**
- Increase maxTokens value
- Shorten the prompt
- The service reserves 500 tokens for response

### Issue 3: Extra Parameters Not Working
**Possible Causes:**
- Invalid JSON format
- Critical parameters being filtered

**Resolution:**
- Check JSON syntax (use online validator)
- Avoid using: model, messages, stream, max_tokens
- Use test connection to validate

## Test Result Template

```
Test Date: YYYY-MM-DD
Tester: [Name]
App Version: [Version]

Configuration UI Test: ✅/❌
Model Name Configuration: ✅/❌
Max Tokens Configuration: ✅/❌
Extra Parameters Configuration: ✅/❌
Test Connection: ✅/❌
Token Truncation: ✅/❌
End-to-End Integration: ✅/❌
Persistence: ✅/❌
Error Handling: ✅/❌
UI/UX: ✅/❌
SmartDialog Toast: ✅/❌

Notes:
[Add any observations, issues, or comments here]
```

## Success Criteria

All tests should pass with:
- ✅ All UI elements present and functional
- ✅ All settings save and persist correctly
- ✅ Test connection validates all parameters
- ✅ Token truncation works as expected
- ✅ Extra parameters are properly parsed and filtered
- ✅ Error messages are clear and helpful
- ✅ No crashes or unexpected behavior
