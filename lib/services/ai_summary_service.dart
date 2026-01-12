import 'dart:async';

import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:dio/dio.dart';
import 'package:fixnum/fixnum.dart';

class AiSummaryService {
  static String? _baseUrl;
  static String? _apiKey;
  static String? _prompt;

  static String get baseUrl =>
      _baseUrl ??
      GStorage.setting.get(SettingBoxKey.aiSummaryBaseUrl, defaultValue: '');

  static String get apiKey =>
      _apiKey ??
      GStorage.setting.get(SettingBoxKey.aiSummaryApiKey, defaultValue: '');

  static String get prompt =>
      _prompt ??
      GStorage.setting.get(SettingBoxKey.aiSummaryPrompt, defaultValue: '');

  static set baseUrl(String value) {
    _baseUrl = value;
    GStorage.setting.put(SettingBoxKey.aiSummaryBaseUrl, value);
  }

  static set apiKey(String value) {
    _apiKey = value;
    GStorage.setting.put(SettingBoxKey.aiSummaryApiKey, value);
  }

  static set prompt(String value) {
    _prompt = value;
    GStorage.setting.put(SettingBoxKey.aiSummaryPrompt, value);
  }

  static bool get isConfigured =>
      baseUrl.isNotEmpty && apiKey.isNotEmpty && apiKey.startsWith('sk-');

  /// Test API connection and configuration
  static Future<(bool, String)> testConnection() async {
    if (!isConfigured) {
      return (false, '请先配置 API Base URL 和 API Key');
    }

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await dio.post(
        '$baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': 'Hello'},
          ],
          'max_tokens': 10,
        },
      );

      if (response.statusCode == 200) {
        return (true, '连接成功');
      } else {
        return (false, '连接失败: ${response.statusCode}');
      }
    } catch (e) {
      return (false, '连接失败: $e');
    }
  }

  /// Fetch all sub-replies for a given reply
  static Future<List<Map<String, dynamic>>> fetchAllSubReplies({
    required int type,
    required Int64 oid,
    required Int64 rootRpid,
    required Function(double) onProgress,
  }) async {
    final List<Map<String, dynamic>> allData = [];
    int page = 1;
    const int pageSize = 20;
    int totalCount = 0;

    while (true) {
      try {
        final response = await Request().get(
          'https://api.bilibili.com/x/v2/reply/reply',
          queryParameters: {
            'type': type,
            'oid': oid.toInt(),
            'root': rootRpid.toInt(),
            'ps': pageSize,
            'pn': page,
          },
        );

        if (response.data['code'] != 0) {
          break;
        }

        final data = response.data['data'];

        // First page: extract root comment
        if (page == 1 && data['root'] != null) {
          final root = data['root'];
          allData.add({
            'user': '【楼主】${root['member']['uname']}',
            'content': root['content']['message']
                .toString()
                .replaceAll('\n', ' ')
                .trim(),
            'likes': root['like'],
          });
          totalCount = data['page']['count'] + 1;
        }

        if (data['replies'] == null || (data['replies'] as List).isEmpty) {
          break;
        }

        final replies = data['replies'] as List;
        for (final r in replies) {
          final content = r['content']['message']
              .toString()
              .replaceAll('\n', ' ')
              .trim();
          if (content.isEmpty) continue;

          allData.add({
            'user': r['member']['uname'],
            'content': content,
            'likes': r['like'],
          });
        }

        // Update progress (0-90%)
        if (totalCount > 0) {
          final progress = (allData.length / totalCount * 0.9).clamp(0.0, 0.9);
          onProgress(progress);
        }

        if (page == 1 && data['page'] != null) {
          totalCount = data['page']['count'] + 1;
        }

        if (allData.length >= totalCount) {
          break;
        }

        page++;
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        break;
      }
    }

    return allData;
  }

  /// Convert replies to CSV format
  static String repliesToCsv(List<Map<String, dynamic>> replies) {
    final buffer = StringBuffer();
    buffer.writeln('user,content,likes');

    for (final reply in replies) {
      final user = _escapeCsvField(reply['user'].toString());
      final content = _escapeCsvField(reply['content'].toString());
      final likes = reply['likes'].toString();
      buffer.writeln('$user,$content,$likes');
    }

    return buffer.toString();
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Send summary request to AI API
  static Future<(bool, String)> summarizeReplies(
    String csvData,
    Function(double) onProgress,
  ) async {
    if (!isConfigured) {
      return (false, '请先配置 API Base URL 和 API Key');
    }

    try {
      onProgress(0.9); // Start AI processing phase

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      prompt +=
          '''
      数据内容：
      $csvData
      ''';

      final response = await dio.post(
        '$baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'stream': false,
        },
      );

      onProgress(1.0); // Complete

      if (response.statusCode == 200) {
        final result = response.data['choices'][0]['message']['content'];
        return (true, result.toString());
      } else {
        return (false, '请求失败: ${response.statusCode}');
      }
    } catch (e) {
      return (false, '请求失败: $e');
    }
  }

  /// Complete summary workflow
  static Future<(bool, String)> summarizeReply({
    required int type,
    required Int64 oid,
    required Int64 rootRpid,
    required Function(double) onProgress,
  }) async {
    try {
      // Step 1: Fetch replies (0-90%)
      final replies = await fetchAllSubReplies(
        type: type,
        oid: oid,
        rootRpid: rootRpid,
        onProgress: onProgress,
      );

      if (replies.isEmpty) {
        return (false, '没有获取到回复数据');
      }

      // Step 2: Convert to CSV
      final csvData = repliesToCsv(replies);

      // Step 3: Send to AI (90-100%)
      final (success, result) = await summarizeReplies(csvData, onProgress);

      return (success, result);
    } catch (e) {
      return (false, '总结失败: $e');
    }
  }
}
