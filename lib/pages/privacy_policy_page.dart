import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/api_service.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool _isLoading = true;
  String _content = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    try {
      final result = await ApiService().getPrivacyPolicy();
      if (result['code'] == 200) {
        setState(() {
          _content = result['data']['content'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? '获取隐私政策失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '获取隐私政策失败: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPrivacyPolicy,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPrivacyPolicy,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Html(
                            data: _content,
                            style: {
                              "body": Style(
                                fontSize: FontSize(16.0),
                                lineHeight: LineHeight(1.5),
                              ),
                              "h1": Style(
                                fontSize: FontSize(24.0),
                                fontWeight: FontWeight.bold,
                                margin: Margins.only(bottom: 16.0),
                              ),
                              "h2": Style(
                                fontSize: FontSize(20.0),
                                fontWeight: FontWeight.bold,
                                margin: Margins.only(bottom: 12.0, top: 24.0),
                              ),
                              "p": Style(
                                margin: Margins.only(bottom: 16.0),
                              ),
                              "ul": Style(
                                margin: Margins.only(bottom: 16.0, left: 20.0),
                              ),
                              "li": Style(
                                margin: Margins.only(bottom: 8.0),
                              ),
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
